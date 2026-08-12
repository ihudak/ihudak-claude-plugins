# 2026-08-12 — choice-gate sweep (Task 9, Half 1)

Sweep for `choices:` lists whose *written default* is the vacuous-confirmation shape `/idea` Phase 1
had before Task 5 fixed it — a full choice list presented for a question whose answer is already
determined, per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` ("When a choice list fires").
The goal is not to label all ~188 `choices:` lists in the plugin; Task 1's rule already supplies the
default for those. This sweep looks only for the ones that got the default wrong.

## Detector (brief Step 1, verbatim)

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in commands/*.md; do
  grep -n -B4 'choices:' "$f" \
    | grep -iE 'confirm|confirmation' \
    | grep -viE '\bif\b|\bwhen\b|\bunless\b|\bon [A-Za-z_`]' \
    | sed "s|^|${f}: |"
done
```

Raw output: 21 lines, spanning 9 files (`create-ard.md`, `design.md`, `docs-profile.md`,
`document.md`, `epics.md`, `ready.md`, `specify.md`, `statusline.md`, `update-vi.md`). Several raw
lines are `-B4` context belonging to the *same* `choices:` gate (e.g. `design.md` lines 182/183/184 are
all context+match for one gate), so the table below groups them into 16 distinct gates (plus 2 lines
that turned out to attach to no `choices:` list at all — noted as such).

### Reconciliation (fix round 1) — mechanical, not eyeballed

Fix round 1 found that the first pass of this record dropped one raw hit (`design.md:185`) without
classifying it or marking it a false positive. To make that failure mode checkable without re-reading
the whole file by eye, the detector's raw output and the table's `Line(s)` column are reconciled with a
script: extract every `file:line` from the raw detector output, expand every `Line(s)` cell in the table
(ranges and comma lists, ignoring parentheticals) into its own `file:line` set, and diff. A later reader
re-runs this to confirm the record is still complete:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in commands/*.md; do
  grep -n -B4 'choices:' "$f" \
    | grep -iE 'confirm|confirmation' \
    | grep -viE '\bif\b|\bwhen\b|\bunless\b|\bon [A-Za-z_`]' \
    | sed "s|^|${f}: |"
done | sed -E 's/^([^:]+): ([0-9]+)[:-].*/\1:\2/' | sort -u > /tmp/raw-filelines.txt

python3 - <<'PYEOF'
import re
rows = []
with open("/workspace/ihudak-claude-plugins/docs/superpowers/plans/2026-08-12-choice-gate-sweep.md") as f:
    for line in f:
        m = re.match(r'^\| (\d+) \| `([^`]+)` \| ([^|]+) \|', line)
        if m:
            rows.append((m.group(2), m.group(3).strip()))
covered = set()
for fname, lines_field in rows:
    core = re.sub(r'\([^)]*\)', '', lines_field).strip()
    for p in [p.strip() for p in core.split(',') if p.strip()]:
        rm = re.match(r'^(\d+)[–-](\d+)$', p)
        if rm:
            for n in range(int(rm.group(1)), int(rm.group(2)) + 1):
                covered.add((fname, n))
        elif re.match(r'^\d+$', p):
            covered.add((fname, int(p)))
with open("/tmp/raw-filelines.txt") as f:
    raw = [tuple(l.strip().rsplit(':', 1)) for l in f if l.strip()]
raw = [(fn, int(ln)) for fn, ln in raw]
missing = [r for r in raw if r not in covered]
print("raw hits:", len(raw), "| unaccounted:", len(missing), missing)
PYEOF
```

Expected: `raw hits: 21 | unaccounted: 0`.

## Findings

| # | File | Line(s) | Gate | Verdict | Reasoning |
|---|------|---------|------|---------|-----------|
| 1 | `commands/create-ard.md` | 37 (no attached `choices:`) | Phase 1 item 1, "Confirm the scope (VI-level vs Epic-level) and the feature folder" | n/a (false positive) | This line has no `choices:` array of its own — it is descriptive text preceding items 2–4's own (correctly conditioned/varying) lists. The detector's `-B4` window pulled it in as pre-context for a neighbouring gate. Not a defect to fix. |
| 2 | `commands/create-ard.md` | 83–84 | Phase 3 step 3, "Missing repo → consolidated mount-or-descope gate" | varies | Already conditioned by its own heading ("Missing repo →"); fires only when a themed requirement maps to no mounted repo. Mount / skip-and-record / specify-path / cancel are all genuinely live outcomes. |
| 3 | `commands/design.md` | 110–111 | Phase 1 item 1, "Feature folder. Confirm the path resolved in Phase 0" | varies | Phase 0's folder resolution is a title-derived kebab-case slug with a tolerant existing-dir match; it can genuinely land on the wrong folder (naming drift, a differently-slugged pre-existing dir) in ways a closed-form classifier cannot. Unlike `/idea`'s old regex-based type classification (which was airtight over its own precedence rules), this is an external-state-dependent guess with real corrective value in "Use a different path". |
| 4 | `commands/design.md` | 182–184 | Phase 3 step 2, "Confirm the complete set — the developer owns it" | varies | Explicitly a developer-owned scope decision; add/remove repos is a routine, real outcome, not a formality. |
| 5 | `commands/design.md` | 185–188 | Phase 3 step 3, "Resolve each confirmed repo against the map" | varies | Dropped from the record in the first pass — added in fix round 1. Conditioned by its own sentence ("Ambiguous or zero matches escalate…"); fires only when repo-slug resolution is ambiguous or empty, same shape as the correctly-classified `create-ard.md:83–84` row. Its choices (skip / clone-and-wait / cancel / specify a different absolute path / other) are genuinely different outcomes depending on why the match failed — not a foregone conclusion. |
| 6 | `commands/design.md` | 189, 192 | Phase 3 step 4, "STRICT mounted gate — hard-stop" | varies | Already conditioned ("Any repo in the confirmed set that is not mounted…"); remount / remove-from-scope / cancel are all real outcomes. |
| 7 | `commands/docs-profile.md` | 41 | Phase 0 step 3, "0 signals present → ask before continuing" | varies | Already conditioned by the enclosing "If 0 signals are present" branch (line 38); Proceed vs Cancel differ by how confident the user is this really is a docs repo. |
| 8 | `commands/docs-profile.md` | 150 (choices at 153) | Phase "Idempotent refresh", "Exists → show diff and confirm" | varies | Already conditioned by the "Exists" branch (vs "Absent" → bootstrap silently); Apply / Keep / Edit-fields are meaningfully different per-run outcomes depending on the field diff shown. |
| 9 | `commands/docs-profile.md` | 174 (choices at 176) | Phase 5 step 1, "Always confirm the final name (initials/slugs are subjective)" | varies | The text itself names why this varies — initials/slug generation is subjective, so real disagreement is expected, not a formality. |
| 10 | `commands/document.md` | 68 | Phase 0 step 2(c), "Ask" fallback for `docs_repo_path` | varies | Reached only after cases (a), (a.5), (b) all fail to resolve a docs repo (an else-cascade); "Use cwd anyway" vs "Enter the docs repo path" vs "Cancel" are real, different outcomes depending on why detection failed. |
| 11 | `commands/document.md` | 368–369 | Phase 4.5, "Confirm with the user" applicable space(s) | varies | Already conditioned by "If `space_constraint` is `none`" (line 361); which of saas/managed/both is right varies genuinely per VI, and the auto-detection is explicitly heuristic ("best-guess"). |
| 12 | `commands/epics.md` | 254 (choices at 252) | Phase 3.5, refinement-mode gate | varies | Already conditioned — runs only when `focus_key` is set OR `refinement_candidates` is non-empty (line 243), and this specific list only in the "no focus key, candidates non-empty" branch (the "focus key set" branch skips the question entirely at line 245). refine/generate/both/adjust are real, different outcomes. |
| 13 | `commands/ready.md` | 85–86 | Phase 1 item 1, "Confirm the resolved scope" | varies | Same shape and same reasoning as `design.md`/`specify.md`'s feature-folder confirm (row 3): the auto-resolved VI/Epic scope can genuinely be wrong; "Use a different path" is a real corrective action, not a formality. |
| 14 | `commands/specify.md` | 98, 100 | Phase 1 item 1, "Feature folder. Confirm the path resolved in Phase 0" | varies | Same as row 3. |
| 15 | `commands/statusline.md` | 49, 51–52 | Phase 4, "Merge the settings block (confirm first)" | varies | Always fires (installs into the user's global `settings.json`), but Install vs Cancel is a real, consequential yes/no — not a foregone conclusion. |
| 16 | `commands/update-vi.md` | 36 (no attached `choices:`) | Phase 1 item 1, "Confirm the feature folder; the resolved Jira-import base…" | n/a (false positive) | Same shape as row 1 — no `choices:` array attaches to this line; it is descriptive text ahead of item 2's own list ("Scope of the update"), which already varies correctly (Refresh vs Re-do vs Cancel) and was not itself flagged as a confirm-shaped hit. |

## Outcome

**The sweep found nothing beyond `/idea`.** Of the 16 distinct gates the detector's raw hits resolve
to, 2 are false positives (no `choices:` list is actually attached to the flagged line) and the
remaining 14 are all correctly gated already — either explicitly conditioned in their own heading/intro
sentence, or a genuine developer/user decision whose outcome varies run to run. None reproduces the
`/idea` Phase 1 defect shape: an exhaustive, closed-form classification re-confirmed via a full choice
list even in branches where no alternative outcome was ever plausible. No file in this table was
modified as a result of Half 1. The reconciliation script above confirms all 21 raw hits are accounted
for (0 unaccounted).

This is an honest, expected result per the task brief: Task 1's "When a choice list fires" rule still
has a live consumer in `/idea` Phase 1 (fixed in Task 5), so the rule is not a dead gate — it simply had
only the one true instance to fix, and this sweep confirms there is no second one hiding elsewhere in
the plugin.

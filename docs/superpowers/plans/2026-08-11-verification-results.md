# Task 8 — cross-repo verification results

Plan: `docs/superpowers/plans/2026-08-11-printed-output-correctness.md`
Repos verified, all on branch `iv-gu/printed-output-correctness`:

- Canonical: `/workspace/ihudak-claude-plugins` (dev-workflows 2.46.0)
- mgd: `/workspace/mgd-claude-plugins` (dev-workflows 2.46.0, content-verbatim except six identity files)
- Copilot: `/workspace/ihudak-copilot-plugins` (dev-workflows 2.16.0, `<name>:` dialect, own version track)

This task writes no plugin content. Every FAIL below carries the exact command and output; nothing was adjusted to make a number pass.

## Evidence table

| ID | Check | Expected | Observed | Verdict |
|----|-------|----------|----------|---------|
| V1 | rule 6 present, correct dialect | 1 per edition | canonical 1, mgd 1, copilot **2** | **FAIL (copilot)** — see below |
| V2 | surface i bare names | 0 per edition | canonical 0, mgd 0, copilot 0 | PASS |
| V3 | surface ii bare names | 4 canonical/mgd (D-2), 0 copilot | canonical 4, mgd 4, copilot 0 | PASS |
| V4 | `next-phase-offer.md` bare names, exact residue | 3 canonical/mgd = `/release-notes /statusline /upgrade`; 4 copilot = adds `/feedback` | canonical 3 (`` `/release-notes `/statusline `/upgrade ``), mgd 3 (same), copilot 4 (`` `/feedback `/release-notes `/statusline `/upgrade ``) | PASS |
| V6 | `/update-vi` in each routing graph | ≥1 per edition | canonical 1, mgd 1, copilot 1 | PASS |
| V7 | `/update-vi` node in each README mermaid | ≥1 (canonical/mgd expect 2) | canonical 2, mgd 2, copilot 2 | PASS |
| V9 | mgd root `CLAUDE.md` doc-structure-conventions paragraph | 1, byte-identical to canonical | canonical 1 occurrence, mgd 1 occurrence, `diff` of the two lines empty (byte-identical) | PASS |
| V10 | copilot `create-vi/SKILL.md` cites `epics:` Phase 6.2, zero 6.1 in that context | 1 citation; 0 for 6.1 | `skills/create-vi/SKILL.md:136`: `` (mirrors `epics:` Phase 6.2). ``; zero `6.1` hits anywhere in the file | PASS |
| V12 | mgd parity — exactly six identity files (plugins/ + repo root) | 6 | 4 under `plugins/dev-workflows` (`.claude-plugin/plugin.json`, `LICENSE`, `README.md`, `references/dependencies.md`) + 2 at repo root (`CLAUDE.md`, `.claude-plugin/marketplace.json`) = 6 | PASS |
| V13 | CHANGELOGs monotonic; both `marketplace.json` catalogs (canonical, mgd) bumped and parsing | pass | canonical CHANGELOG head `2.46.0, 2.45.0, 2.44.1`; mgd same; copilot CHANGELOG head `2.16.0, 2.15.0, 2.14.1` — all monotonic decreasing. Both `.claude-plugin/marketplace.json` parse OK and carry `"version": "2.46.0"` for the `dev-workflows` entry | PASS (see Findings for an out-of-scope catalog note on copilot) |
| V14 | R2 re-check — printed sites outside `commands/` | 0 real | 2 raw hits: `agents/vuln-research.md:38` (path false positive, the brief's own anticipated example) and `references/escalation-rules.md:34` (a **second, unanticipated** false-positive type — prose citation, not a printed site) | PASS (0 real; see Findings) |
| V15 | R3 re-check — slashless names in surfaces i/ii | 0 | 0 | PASS |
| V16 | R1 — no site defers to rule 6 at runtime | 0 | 0 | PASS |
| V17 | surface vi (D-3) — no QUALIFY site left bare | 0 | vi-a: 0 bare; vi-b: 2 bare, both are the documented LEAVE sites (`create-ard.md:14`, `:15` — calling-forms documentation, never QUALIFY) | PASS |
| V18 | surface vii (D-4) — vii-a/vii-b return no unclassified printed invocation site | 0 | vii-a: 1 line (`implement.md:55`, documented LEAVE — self-referential); vii-b: 28 lines, all documented LEAVE/split-verdict-bare-halves (`implement.md:387`, `:445`, five `*_NEEDS_JIRA` messages, 14 subagent-handoff `Command run: /X` templates, 3 split-verdict self-referential halves, 3 comparison/self-referential prose lines). No unclassified site | PASS |

## V1 detail — copilot rule-6 count mismatch

Command:
```
grep -c 'when printed\|this edition' /workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/next-phase-offer.md
```
Output: `2` (expected `1`).

Root cause, confirmed by reading `next-phase-offer.md:29-34`: rule 6 is a single rule, but its explanatory text uses the phrase "this edition" **twice** in two consecutive sentences —

```
29:6. **Printed in this edition's invocation idiom** — every skill name the run PRINTS for the user to
...
33:   form is NEVER printed. Prose that describes the pipeline to a reader of this edition's source
```

This is not a duplicate or contradictory rule 6 — there is exactly one rule 6, correctly stated, in the correct `<name>:` dialect, with the correct built-in-collision citations (verified separately by V4). The `grep -c` count is a **line**-count, and rule 6's own prose happens to use the trigger phrase twice across two lines. Reporting this plainly per instructions: the expected value in the brief (1) does not match what the stated command produces for copilot (2). It is a counting-methodology artifact, not a content defect — but it is reported as a mismatch, not silently adjusted.

## V14 detail — a second false-positive type, not anticipated by the brief

Command:
```
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -rnEi "(surface|report|recommend|offer|next step|suggest)[^.]{0,100}/($CMDS)\b" agents/ references/ | grep -v 'next-phase-offer.md'
```
Output:
```
agents/vuln-research.md:38:6. **Assemble output** — Produce one report entry per CVE (see `${CLAUDE_PLUGIN_ROOT}/references/handoff/vuln-research.md` output format).
references/escalation-rules.md:34:is recommended, unconditionally, and is honoured verbatim like any other marker (`/document`
```

The brief states "V14 hits must all be path false positives (e.g. `.../handoff/vuln-research.md`)". The first hit matches that exact anticipated shape (`/vuln` inside the file-path component `vuln-research.md`). The second hit is **not** a path false positive — it is prose in `references/escalation-rules.md` citing `/document` Phase 5 and `/epics` Phase 1 as examples of commands that already use the `(Recommended — <why>)` marker pattern. Investigation:

- The sentence appears nowhere else in the repo (`grep -rn 'honoured verbatim like any other marker' .` → 1 hit, the source line itself) — it is not echoed or pasted verbatim into any command's printed output.
- `escalation-rules.md` is consulted by 10 commands/agents as an internal authoring reference, never rendered to the end user as-is.
- The shape is the same class as the already-accepted D-2 exceptions (`implement.md:387`/`:445`, "Phase 5 of the inherited `/implement` workflow") — a prose citation naming a workflow by way of precedent, not an invocation instruction.

Conclusion: **not a real defect** (V14 = 0 real printed sites, as expected), but the brief's claim that hits "must all be path false positives" is itself slightly incomplete — a second, non-path false-positive class exists and was not pre-cleared. Recorded here rather than silently folded in, per the residue-audit instruction.

## Residual audit (requested: "look at the residual bare command names ... ask whether any is a printed invocation target every detector missed")

Ran a full bare-name sweep (`grep -noE "(^|[^:a-z-])/($CMDS)\b" *.md`) across canonical `commands/*.md`, plus targeted re-runs of vi-a/vi-b/vii-a/vii-b and a blockquote scan (`^>` lines, since that is the exact shape that already caught the "Command run: /X" surface). mgd's `commands/` is byte-identical to canonical (confirmed under V12), so the canonical sweep covers mgd. Copilot was independently re-checked with all four detectors (vi-a, vi-b, vii-a, vii-b) plus the blockquote scan.

Findings:

- Canonical: five additional blockquote lines beyond the already-classified `Command run: /X` sites — `epics.md:520`, `ready.md:446`, `document.md:1025`, `document.md:1559`, `document.md:1560` (all `Test result: N/A (no tests in /X...)` or `Review verdict: N/A (no review gate in /X...)`). Read in context: every one sits inside the same `impl-maintenance` Agent-4 subagent-handoff prompt block as the already-classified `> - Command run: /X` lines (e.g. `epics.md:511-522`, `document.md:1017-1026`) — literal prompt text sent to a subagent, never shown to the end user. Same LEAVE class already established; not a new surface.
- Copilot: vi-a, vi-b, vii-a, vii-b, and the blockquote scan all return **zero** hits — independently confirms task-7's claim that copilot needed zero conversions (already in `<name>:` idiom pre-release).
- No eighth printed surface found. This matches Task 3's own fix-round conclusion ("Nothing was found outside the two detectors. No eighth axis to report.").

## Additional finding — out of the V-table's literal scope

While verifying V13, copilot's own marketplace catalog was inspected for completeness (the brief's Step 3 script checks only canonical's and mgd's `.claude-plugin/marketplace.json`, so this is not a V13 FAIL, but is reported per the standing instruction to report anything found):

```
python3 -c "import json;d=json.load(open('/workspace/ihudak-copilot-plugins/dev-workflows/.plugin/plugin.json'));print(d['version'])"
# → 2.16.0
python3 -c "
import json
d=json.load(open('/workspace/ihudak-copilot-plugins/.github/plugin/marketplace.json'))
print([p['version'] for p in d['plugins'] if p['name']=='dev-workflows'])
"
# → ['2.15.0']
```

Copilot's `dev-workflows/.plugin/plugin.json` (2.16.0) and `CHANGELOG.md` head (`## [2.16.0]`) agree, but the marketplace catalog entry at `.github/plugin/marketplace.json` still records `"version": "2.15.0"` — one release behind. This is a real staleness in the copilot repo's own catalog, outside this task's write authority (no plugin content is written by this task) and outside the literal V13 script's scope (which only checks the two `.claude-plugin/marketplace.json` files). Flagged for the maintainer; not fixed here.

## Summary

15 of 18 checks PASS outright; V14 PASSES on substance (0 real defects) but surfaces an unanticipated false-positive type worth noting; V1 shows a literal count mismatch for copilot (2 vs. expected 1) that traces to the counting method, not to rule 6's content, and is reported per instructions rather than silently reconciled. One out-of-scope staleness item (copilot marketplace catalog version) is flagged for the maintainer. No new (eighth) printed-output surface was found in the residual audit.

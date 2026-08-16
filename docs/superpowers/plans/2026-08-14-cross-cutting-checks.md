---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-08-14
---

# Sub-project J, Task 14 — cross-cutting proof tables (consent, ordering, dead gate, optionality)

Recorded proof tables rather than assurances, for Tasks 6–13's phase-handoff-gates commands. Baseline for every discrimination proof: `bca4191` unless a section says otherwise. This file is the evidence Task 20's verification record cites for R20, R30, Risk 2, and Risk 8 (`2026-08-14-phase-handoff-gates.md` Step 3 table).

**Fix round 1 of 5 (this revision).** A reviewer, re-running this file's own commands against the committed tree (`666d97c`), found that Step 2a's own edit at `epics.md:126` made the bare-word R30 pattern used in Step 2 match a prose exception note rather than the real gate, so the recorded `/epics` gate line (180) stopped reproducing — right when captured, stale by the next edit in the same task. Fixed by anchoring the pattern on the imperative dispatch form (see Step 2). Also fixed: a hard-wrapped bullet this task's own edit touched in `specs-repo-git.md` §4.1 (Step 2b), and a genuine gap in `phase-handoff.md` §3.4's delegation table — no row for `/specify`'s VI gate — that fix round 0 had flagged but left unfixed (Step 4).

## Step 1 — R20: the consent choice is verbatim in all eight producers

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in idea create-vi update-vi create-ard specify design implement ready; do
  printf "%-12s %s\n" "$f" "$(grep -c 'Branch + commit + push + open PR to main (Recommended)' commands/$f.md)"
done
for f in idea create-vi update-vi create-ard specify design implement ready; do
  printf "%-12s consequence=%s\n" "$f" "$(grep -c "the next phase will stop until this is on main" commands/$f.md)"
done
```

| Producer | Consent-choice count | Consequence-clause count |
|---|---|---|
| `/idea` | 1 | 1 |
| `/create-vi` | 1 | 1 |
| `/update-vi` | 1 | 1 |
| `/create-ard` | 1 | 1 |
| `/specify` | 1 | 1 |
| `/design` | 1 | 1 |
| `/implement` | 1 | 1 |
| `/ready` | 1 | 1 |

All 16 counts are exactly 1. R20 met — no fix required.

## Step 2 — R30: every gate precedes the first expensive operation

Dispatch form, not the bare word: `subagent_type: "dev-workflows:<agent>"`.

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in create-vi create-ard specify design implement epics ready; do
  G=$(grep -n 'require-on-main' commands/$f.md | head -1 | cut -d: -f1)
  X=$(grep -nE 'subagent_type: "dev-workflows:(code-scanner|docs-grounder|jira-reader)"' commands/$f.md | head -1 | cut -d: -f1)
  P=$(grep -nE '^## Phase .*[Gg]rill' commands/$f.md | head -1 | cut -d: -f1)
  X=$(printf '%s\n%s\n' "${X:-999999}" "${P:-999999}" | sort -n | head -1)
  printf "%-12s gate=%-7s first-expensive=%-7s %s\n" "$f" "${G:-NONE}" "$X" \
    "$( [ -n "$G" ] && [ "$G" -lt "$X" ] && echo YES || echo CHECK )"
done
```

**As first measured, before Step 2a's contract-fix edits landed:**

| Consumer | gate line | first-expensive line | Verdict |
|---|---|---|---|
| `/create-vi` | 29 | 121 | YES |
| `/create-ard` | 33 | 69 | YES |
| `/specify` | 90 | 175 | YES |
| `/design` | 50 | 185 | YES |
| `/implement` | 99 | 200 | YES |
| `/epics` | 180 | 206 | YES |
| `/ready` | 18 | 136 | YES |

**This table went stale within this same task, by this task's own later edit — the exact staleness class this task exists to catch.** Step 2a's `epics.md:126` exception note (added after this table was captured) itself contains the literal substring `require-on-main` inside prose ("… ahead of the new Phase 2.5/2.6's `require-on-main`/`ard-resolution.md` gates …"), and line 126 precedes line 180 in the file, so `grep -n 'require-on-main' | head -1` now returns the note instead of the real gate. A fresh re-run of the brief's own script against the post-Step-2a tree therefore returns `gate=126` for `/epics`, not `180` — the recorded row above does not reproduce. Substance is unaffected (126 < 206 either way, still `YES`), but the *claim* that the table "already reflects the post-fix state" (an earlier draft of this file asserted exactly that) was false: a bare-word pattern cannot survive an edit to the same file that happens to mention the gate's name in passing.

**Fix — anchor on the imperative dispatch form, not the bare name.** `require-on-main`'s real gate call is always phrased `[Ee]xecute \`require-on-main\``; matching on the substring `xecute \`require-on-main\`` (case-insensitive without a character class) hits every real gate and does not hit the prose note, because the note never precedes the phrase with "execute":

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in create-vi create-ard specify design implement epics ready; do
  G=$(grep -n 'xecute `require-on-main`' commands/$f.md | head -1 | cut -d: -f1)
  X=$(grep -nE 'subagent_type: "dev-workflows:(code-scanner|docs-grounder|jira-reader)"' commands/$f.md | head -1 | cut -d: -f1)
  P=$(grep -nE '^## Phase .*[Gg]rill' commands/$f.md | head -1 | cut -d: -f1)
  X=$(printf '%s\n%s\n' "${X:-999999}" "${P:-999999}" | sort -n | head -1)
  printf "%-12s gate=%-7s first-expensive=%-7s %s\n" "$f" "${G:-NONE}" "$X" \
    "$( [ -n "$G" ] && [ "$G" -lt "$X" ] && echo YES || echo CHECK )"
done
```

**Reproducible table, current tree (post Step 2a and this fix round):**

| Consumer | gate line | first-expensive line | Verdict |
|---|---|---|---|
| `/create-vi` | 29 | 121 | YES |
| `/create-ard` | 33 | 69 | YES |
| `/specify` | 90 | 175 | YES |
| `/design` | 50 | 185 | YES |
| `/implement` | 99 | 200 | YES |
| `/epics` | 180 | 206 | YES |
| `/ready` | 86 | 136 | YES |

`/ready`'s gate line also changed under the anchored pattern (18 → 86): line 18 was itself a bare-word prose match (the command's own "Key distinction from every other consumer of … `require-on-main` …" scene-setting sentence), not the dispatch — the same imprecision as `/epics`' stale match, just one that happened not to flip the verdict. The anchored pattern fixes both.

**Two-direction proof that the anchored pattern discriminates the exact failure it fixes:**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n 'xecute `require-on-main`' commands/epics.md    # expect: only line 180
sed -n '126p' commands/epics.md | grep -c 'xecute `require-on-main`'   # expect: 0
sed -n '180p' commands/epics.md | grep -c 'xecute `require-on-main`'   # expect: 1
```

Result: the anchored pattern's only match in `epics.md` is line 180; the stale line 126 scores 0; the real gate line 180 scores 1.

**Dispatch-vs-prose control** (why the dispatch form matters for the *first-expensive* side too, not the bare word — matches the brief's measured baseline for the prose mention alone): bare `code-scanner` mention vs. real dispatch, current tree —

| File | bare mention line | dispatch line |
|---|---|---|
| `create-ard` | 43 | 89 |
| `specify` | 113 | 315 |
| `design` | 94 | 185 |
| `implement` | 160 | 218 |
| `epics` | 84 | 302 |

A check keyed on the bare word would have passed every row on coincidence (the prose mention always precedes the real dispatch); the dispatch-form pattern above is what the R30 table actually measures on the first-expensive side, and the newly anchored `xecute \`require-on-main\`` pattern is the same discipline applied to the gate side.

**Can-fail proof** — same anchored-pattern script, gate pattern replaced with `Final report` (a string that appears only near the end of a file):

| Consumer | gate line (`Final report`) | first-expensive line | Verdict |
|---|---|---|---|
| `/create-vi` | 201 | 121 | CHECK |
| `/create-ard` | 145 | 69 | CHECK |
| `/specify` | 420 | 175 | CHECK |
| `/design` | 289 | 185 | CHECK |
| `/implement` | NONE | 200 | CHECK |
| `/epics` | NONE | 206 | CHECK |
| `/ready` | NONE | 136 | CHECK |

All seven flip to `CHECK` — the check discriminates. R30 met on the real, anchored pattern — no behavioural fix required for R30 itself; see Step 2a for the three ordering defects the *audit* (a distinct check, over gate-sentence semantics rather than line position) found in `/epics`, `/design`, and `/implement`.

## Step 2a — `absent` is overloaded: disambiguate the contract, then audit every consumer

**Root cause.** `phase-handoff.md` §3.3's first column read `absent` for rows D, E, and F alike — a statement about the *repository* (nothing on `origin/<default>`). §3.7 separately uses `absent` as the **return value** of row F alone. Rows D and E are stopping rows (`stopped: true`) whose `on_main` field can equally read `absent`, since the artifact genuinely is not on the default branch — the only field that disambiguates D/E from F is `stopped`. A consumer that branches on `on_main == "absent"` before checking `stopped` cannot tell "authored but never handed off" (D/E — must stop) from "never happened" (F — the caller's pre-existing optional-input behaviour applies, §3.4). Task 13's implementer misread exactly this in its own first draft.

**Contract fix** (`plugins/dev-workflows/references/phase-handoff.md`):

- §3.3 rows D/E/F: first column changed from `absent` to `not on ref`, plus a new note distinguishing the column (repository state) from §3.7's `absent` (return value, row F only).
- §3.7: added an explicit ordering rule — *"A caller tests `stopped` before `on_main`. `on_main: absent` is returned only by row F; every stopping row returns `stopped: true` regardless of what `on_main` reads."*

Discrimination proof (baseline `bca4191` vs. current):

| Pattern | baseline count | current count |
|---|---|---|
| `not on ref` | 0 | 4 |
| `tests \`stopped\` before` | 0 | 1 |

**Audit — all seven consumers**, gate sentence quoted, verdict on ordering (either "names stopping states/keys on `stopped` before `absent`" is correct; anything else is a defect):

| Consumer | Gate sentence (key clause) | Verdict |
|---|---|---|
| `/create-vi` (:29) | "On `pass`/`pass_amending`, use it … On a stopping state, stop per §4.4. On `absent`, fall through to rung 2 …" | Correct — stopping-first |
| `/create-ard` (:33) | "On `pass`/`pass_amending`, read the authored VI … On a stopping state, stop per §4.4. On `absent`, the existing `jira-reader` fallback applies …" | Correct — stopping-first |
| `/specify` (:90) | "On `pass`/`pass_amending`, proceed … On a stopping state, stop per §4.4. On `absent`, `/specify`'s existing Jira-export behaviour is unaffected …" | Correct — stopping-first |
| `/design` (:50) | *before fix:* "`pass` → proceed; `pass_amending` → proceed …; `absent` → stop, wording unchanged …; `unmanaged` → behave …; any other stopping state → stop per §4.4." | **Defect** — `absent` listed before the catch-all stopping clause. Message-fidelity risk: a D/E case reaching the `absent` branch would print row F's generic wording instead of naming the branch/PR per §4.4. **Fixed** — now maps by `stopped` first (see below). |
| `/implement` (:99) | *before fix:* "`pass`/`pass_amending` → proceed …; `absent` → … do not stop; behave exactly as before …; `unmanaged` → behave …; Any other (stopping) state → stop per §4.4 …" | **Defect, Critical-shaped** — same absent-before-stopping ordering, but `/implement`'s absent branch *proceeds* rather than stops; a D/E case reaching it would silently proceed on an unmerged spec/design. **Fixed** — now maps by `stopped` first. |
| `/epics` (:180, unchanged by the reordering edit) | *before fix:* "On `absent`, **skip** … On `unmanaged`, behave … On `pass`/`pass_amending`, proceed … On any other (stopping) state, stop per §4.4 …" | **Defect, Critical** — matches the brief's own measured example; `absent`-first with a *skip* consequence means a VI-level spec that exists only on an unmerged branch would be silently treated as absent (`vi_spec_present: false`) instead of stopping. **Fixed** — now maps by `stopped` first. |
| `/ready` (:86) | "map its §3.7 return value by `stopped` first, never by `on_main` alone" | Correct — the one consumer that already said so explicitly (per the brief) |

**Correction (fix round 1):** the sentence that stood here first claimed line numbers shifted for all three edited files' gate line and that Step 2's re-run already reflected the post-fix state. Neither half was true. `design.md:50` and `implement.md:99` did **not** move — both edits were single-line, in-place text replacements (a clause reordered within the existing line), identical before and after in line position. `epics.md`'s gate line also did not move (still :180) — what changed was that Step 2a's *own* exception note at `epics.md:126` began matching the bare-word R30 pattern, which is documented as its own staleness finding in Step 2 above, not here. The accurate statement: none of the three edited files' gate lines shifted; Step 2's anchored-pattern re-run (added in this fix round) is what reproduces `YES` for all seven post-fix.

Discrimination proof for the three reordering fixes:

| File | `by \`stopped\` first, never by \`on_main\` alone` — baseline | current |
|---|---|---|
| `design.md` | 0 | 1 |
| `implement.md` | 0 | 1 |
| `epics.md` | 0 | 1 |

**Extra item (not in the brief, surfaced by Task 12's review): `epics.md:126`'s docs-grounding placement.** `resolve-docs-grounding epics` runs in Phase 2 (before the plan is shown), ahead of the new Phase 2.5 (`ard-resolution.md`)/2.6 (`require-on-main`) gates — earlier than `phase-handoff.md` §5 rule 2 places a consumer gate ("before its first subagent dispatch, code scan, docs-grounding retrieval, or grill question"). Confirmed byte-identical to baseline (predates this sub-project). **Decision: keep the placement, documented rather than moved.** Sibling consumers `/create-ard` and `/specify` both place `resolve-docs-grounding` *after* their own gates, which was tempting evidence to move `/epics` to match — but the two cases are not equivalent: `resolve-docs-grounding`'s only genuinely expensive step (an index build/refresh, `docs-grounding.md` §3.5) is itself behind its own consent prompt, so nothing is spent without the user's separate say-so at that moment; and unlike a `code-scanner`/`jira-reader` dispatch (per-run, ephemeral, wasted if the run later stops), a built index is a durable artifact that benefits this run's retry and every future run regardless of whether this run later stops at 2.5/2.6. Moving it would also require restructuring Phase 2's plan-approval display (which shows the resolved `docs grounding:` line as part of the unified plan), a materially larger change than this cross-cutting task's mandate. Documented inline at `commands/epics.md:126` with the citation to `phase-handoff.md` §5 rule 2 and the rationale, so the exception is visible at the site rather than only in this record.

## Step 2b — the producer list that only becomes wrong once the producers exist

`references/specs-repo-git.md` §4.1's parenthetical named five producers (`/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`) — true when Task 4 wrote it, false once Tasks 6/11/13 made `/idea`, `/implement`, and `/ready` producers too. Fixed to name all eight.

```bash
awk '/command that opened a specs-repo branch at handoff/,/^- \*\*The same command/' references/specs-repo-git.md \
  | grep -oE '`/[a-z-]+`' | sort -u | tr '\n' ' '; echo
```

| | baseline (`bca4191`) | current |
|---|---|---|
| Producer list | `/create-ard` `/create-vi` `/design` `/specify` `/update-vi` (5) | `/create-ard` `/create-vi` `/design` `/idea` `/implement` `/ready` `/specify` `/update-vi` (8) |

Matches the brief's expected set exactly, count 8.

**Fix round 1 (Minor, in scope because the edit touched the line): reflow the hard-wrapped bullet.** The producer-list edit above preserved the bullet's pre-existing multi-line wrap (three physical lines for one list item). The repo convention is one paragraph, one unbroken line, and an edit that touches a line owns its formatting. Reflowed:

```bash
grep -c '^- \*\*A command that opened a specs-repo branch at handoff\*\* (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `/implement`, `/ready`)' references/specs-repo-git.md
```

| | baseline (previous commit `666d97c`) | current |
|---|---|---|
| Bullet opens and names all 8 producers on one line | 0 (wrapped across 3 physical lines) | 1 (single unbroken line) |

## Step 2c — the Final-report git clause, across all eight producers

```bash
grep -rn "PR URL (if opened)" commands/ | sed -E 's/^([^:]+:[0-9]+).*/\1/'
```

Result: **no output** — zero remaining sites. `/create-vi` was the one site this pattern ever existed at in this file set; it was already fixed in Task 7 (commit `d005e32`, "name unmanaged, fix stale PR-URL clause"). Discrimination proof that the check is non-vacuous: the pattern existed (count 1) at `d005e32~1` (immediately before Task 7's fix), was reduced to 0 by that commit, and remains 0 at `bca4191` and now.

Assert every producer reports the handoff outcome (`Phase handoff:` literal or `§4.1` citation — both acceptable):

```bash
for f in idea create-vi update-vi create-ard specify design implement ready; do
  printf "%-12s %s\n" "$f" "$(grep -Fc 'Phase handoff:' commands/$f.md)$(grep -Fc '§4.1' commands/$f.md)"
done
```

| Producer | `Phase handoff:` count | `§4.1` count | Combined (non-`00`?) |
|---|---|---|---|
| `/idea` | 0 | 2 | 02 — pass |
| `/create-vi` | 1 | 3 | 13 — pass |
| `/update-vi` | 1 | 3 | 13 — pass |
| `/create-ard` | 1 | 3 | 13 — pass |
| `/specify` | 1 | 3 | 13 — pass |
| `/design` | 0 | 2 | 02 — pass |
| `/implement` | 1 | 2 | 12 — pass |
| `/ready` | 1 | 2 | 12 — pass |

All eight non-`00`. No fix required beyond what Task 7 already did.

## Step 3 — Risk 2: `unmerged` is not a dead gate (five `ard-resolution.md` callers)

Per caller: the line that RECEIVES the status (the `ard-resolution.md` citation/dispatch) and the line that ACTS on it (the `status: unmerged` branch).

```bash
for f in specify design implement epics ready; do
  echo "=== /$f ==="
  grep -n "unmerged" commands/$f.md
done
```

| Caller | Receiving line | Acting line | Action |
|---|---|---|---|
| `/specify` | `commands/specify.md:269` (same line — the citation and the `On status: unmerged` clause are in one paragraph) | `commands/specify.md:269` | stop, naming `branch`/`pr` |
| `/design` | `commands/design.md:151` (same line) | `commands/design.md:151` | stop, naming `branch`/`pr` |
| `/implement` | `commands/implement.md:236` (same line) | `commands/implement.md:236` | stop, naming `branch`/`pr` + `$SPECS_PATH` |
| `/epics` | `commands/epics.md:153–155` ("Resolve any VI-level ARD … by citing `ard-resolution.md`") | `commands/epics.md:159` ("On `status: unmerged` → stop, naming the returned `branch` and any `pr`") | stop |
| `/ready` | `commands/ready.md:161` ("Resolve any applicable ARD by citing `ard-resolution.md`") | `commands/ready.md:172` ("`status: unmerged` → never stop … Carry the returned `branch`/`pr` forward as a readiness finding") | finding (caps verdict at `PARTIAL`), never a stop — `/ready`'s defining exemption |

Five pairs, all with a receiving line and a distinct or co-located acting line. No dead gate found — R29/Risk 2 met.

## Step 4 — Risk 8: no optional input became a prerequisite (one row per `phase-handoff.md` §3.4 delegation)

**Fix round 1: `phase-handoff.md` §3.4 gained an eighth row.** The first pass of this task found that `/specify` gates a VI (`require-on-main` at `commands/specify.md:90`, behaviourally identical in shape to `/create-ard`'s VI gate — falls back to the Jira export, reported, never stops) but §3.4's table had no row for it, and left this flagged rather than fixed, reasoning it was a table-completeness gap rather than a behavioural defect. On review this was decided in scope: §3.4 **is** Risk 8's mitigation (an incomplete table is a weaker proof that no optional input became a prerequisite), and the file was already being edited. Added the row (`references/phase-handoff.md`, between the `/create-ard` VI row and the five-caller ARD row):

```bash
grep -c '^| `/specify` | the VI |' references/phase-handoff.md
```

| | baseline (previous commit `666d97c`) | current |
|---|---|---|
| `/specify` VI row present in §3.4 | 0 | 1 |

Table now has 8 rows (was 7): `/create-vi` (idea.md), `/create-ard` (VI), `/specify` (VI, new), five-callers (ARD), `/epics` (VI-level spec), `/implement` (spec/design), `/design` (specification.md), `/ready` (ARD/spec/design).

| Caller | Input | `absent` reaches | Proof (file:line) |
|---|---|---|---|
| `/create-vi` | `idea.md` | the idea ladder, ending at grill-from-scratch | `commands/create-vi.md:29` (rung 1, "On `absent`, fall through to rung 2"), `:33` (rung 5, "last resort — proceed with no idea and grill the VI from scratch"), `:105` (the actual grill trigger: "If there is no idea (Phase 0 ladder exhausted), grill the VI from scratch") |
| `/create-ard` | the VI | the reported `jira-reader` fallback | `commands/create-ard.md:33` ("On `absent`, the existing `jira-reader` fallback applies — but report it …") |
| `/specify` | the VI | `jira-reader` (already the primary read path) is unaffected; the merged-VI grounding confirmation is skipped — reported | `commands/specify.md:90` ("On `absent`, `/specify`'s existing Jira-export behaviour is unaffected — but report it …") |
| five callers | the ARD | `status: none` + the no-regression rule | `commands/specify.md:269`, `commands/design.md:151`, `commands/implement.md:236`, `commands/epics.md:157`, `commands/ready.md:164` — each "On `status: none`, skip/inactive and proceed exactly as before" |
| `/epics` | VI-level spec | `vi_spec_present: false` silent skip | `commands/epics.md:180` ("On `absent`, **skip** (set `vi_spec_present: false`); the run proceeds byte-identically to today") |
| `/implement` | spec/design | in-scope only; direct mode unaffected | `commands/implement.md:99` ("`absent` → **only an in-scope spec is gated at all** — a direct-prompt run resolves none of these `specs` entries and is entirely unaffected, so do not stop") |
| `/design` | `specification.md` | today's stop, wording unchanged | `commands/design.md:50` ("`absent` (row F) → stop, wording unchanged: `spec not handed off — run /dev-workflows:specify for this item and merge it to the specs repo main first.`") |
| `/ready` | ARD/spec/design | missing in the coverage roll-up | `commands/ready.md:86` (spec/design: "`stopped: false` with `on_main: absent` → **missing**, exactly as before this feature"); `commands/ready.md:164` (ARD: "`status: none` … the ARD dimension is **inactive** for this run") |

All eight cells filled with a concrete `file:line` proof each. **Critical check: does an absent input stop any command except `/design`?** No — every row above shows the absent case reaching non-stopping, pre-existing behaviour (fall-through, fallback, skip, inactive, missing-in-roll-up); only `/design`'s row F stops, which is `/design`'s own pre-existing, unchanged behaviour per §3.4's own text ("stops — but that stop already exists; this reference only makes its test correct"). No Critical found.

## Fix round 1 — no behavioural regression

None of this round's three fixes (R30's anchored gate pattern, the `specs-repo-git.md` §4.1 reflow, the new `phase-handoff.md` §3.4 row) touch the ordering logic inside `commands/{design,implement,epics}.md` that Step 2a's original audit fixed. Re-verified directly:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in design implement epics; do
  printf "%-10s %s\n" "$f" "$(grep -c "by .stopped. first, never by .on_main. alone" commands/$f.md)"
done
for f in create-vi create-ard specify design implement epics ready; do
  echo "── /$f"; grep -h "xecute \`require-on-main\`" commands/$f.md | head -1 | cut -c1-200; echo
done
```

| File | ordering-fix sentence count |
|---|---|
| `design.md` | 1 |
| `implement.md` | 1 |
| `epics.md` | 1 |

All three still carry exactly one "maps by `stopped` first, never by `on_main` alone" (or its `/design`/`/implement` phrasing) sentence, unchanged from Step 2a. Gate-sentence spot check confirms all seven consumers still test `stopped` before `absent`/`on_main`: `/create-vi`, `/create-ard`, `/specify` still name "a stopping state, stop per §4.4" ahead of their `absent` clause; `/design`, `/implement`, `/epics` still open with "…mapping its §3.7 return value by `stopped` first, never by `on_main` alone"; `/ready` still states the same rule explicitly. No regression.

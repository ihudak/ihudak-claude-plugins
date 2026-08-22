# dev-workflows docs restructure — defects found during verification

**Context:** `plugins/dev-workflows/docs/` restructure (34 pages) and README rewrite (379 lines to 46), branch `iv-gu/docs-restructure`. This file records every defect the restructure's verification surfaced, whether the restructure fixed it, and — for the two still open — what a human needs to decide.

---

## D1 — Commands table documented 19 of 21 commands

**Claimed:** the old README's Commands table was a complete list of the plugin's slash commands.

**True:** it listed 19. `/vuln` and `/upgrade` existed as shipped commands (`plugins/dev-workflows/commands/vuln.md`, `plugins/dev-workflows/commands/upgrade.md`) but were orphaned in an unlabeled "Additionally:" table nested under the `/implement` workflow section instead of the Commands table itself, so a reader scanning the Commands table alone would not learn either command exists.

**Found:** by cross-checking the README's Commands table against `plugins/dev-workflows/commands/*.md` — the census a documentation restructure has to do anyway to know what it is moving.

**Disposition:** **Fixed** in Task 14. All 21 commands are now documented in two places: `plugins/dev-workflows/README.md`'s role table (a table, grouped by role), and `plugins/dev-workflows/docs/README.md`'s `## Commands` list (a bulleted list, not a table, one entry per command). `check-docs.sh` check 4 now defends the count going forward.

---

## D2 — `cost-emission.md` §7 omitted `/update-vi`

**Claimed:** `references/cost-emission.md` §7 introduces its table as "Fixed per-command labels" — implying it is the complete attribution authority for every command that emits a fixed `phase`/`role` pair to `emit-cost`.

**True:** the table listed ten commands and did not include `/update-vi`, yet `commands/update-vi.md:131` calls `emit-cost` with `phase: vi-update`, `role: pm`, and line 4 of `cost-emission.md` itself names `/update-vi` among the commands that run the Session cost phase. `vi-update` was therefore a phase value emitted by a shipped command and enumerated in no authority — the table contradicted the file it lives in.

**Found:** by grounding the role/phase model against the commands that actually call `emit-cost`, rather than reading `cost-emission.md` in isolation — the same class of check as D1, run against a different table. Step 1 of this task re-confirmed the defect still held (table had ten rows, no `/update-vi` row, `update-vi.md:131` passing `phase: vi-update, role: pm`) before the fix was applied.

**Disposition:** **Fixed** in this task. One row inserted — `| \`/update-vi\` | vi-update | pm |` — immediately after `/create-vi`, preserving the table's lifecycle-stage row order rather than alphabetizing. The table now has eleven rows. Verified complete by a bidirectional check (Step 3 of this task: every command that passes a fixed `phase`/`role` to `emit-cost` has a §7 row, and every §7 row names a real command) — both loops produced no output on the fixed table, and the first loop is the one that would have caught D2 the moment `/update-vi`'s row was first omitted, had it existed then. That check ran once, as inline bash in this task — it is **not** part of `scripts/check-docs.sh` and **not** wired into CI (`grep -c cost-emission scripts/check-docs.sh .github/workflows/validate-catalog.yml` both return 0), unlike D4's and D5's dispositions below, which cite real, CI-enforced checks. So the fix is verified complete but **not defended by any persisted gate**: a future command added with a fixed `phase`/`role` and no §7 row would be caught by nothing. Adding this bidirectional check to `check-docs.sh` is the natural follow-up if that defense is wanted going forward.

---

## D3 — `/ready`'s role: `team` in §7, `QA` in the old README

**Claimed:** the old README's role table filed `/ready` under `QA`; the new `docs/workflow.md` Mermaid diagram, produced by this restructure, carried that same label forward verbatim as the subgraph `QA["QA — verification & gates"]` (`docs/workflow.md:25`).

**True:** `references/cost-emission.md` §7 gives `/ready` the role `team` — that is what `commands/ready.md` actually passes to `emit-cost`, i.e. what the shipped artifact records. The old README no longer exists (retired by this restructure), so there is no live document asserting `QA` to reconcile against. Searching the current authority, `CLAUDE.md`, for "QA" returns zero occurrences — nothing in the surviving instruction set calls `/ready`'s role `QA`, which makes `team` the sole surviving authority on this specific question. The Mermaid diagram's own *structure* was never wrong: it already gives `dev` (its `DEV` subgraph — `/design`, `/implement`, `/document`) and the fifth role (its `QA` subgraph — `/ready` alone) separate subgraphs, matching §7's five-role split exactly. Only the fifth subgraph's label text was stale — a stale label on an already-correct split, not the structural collapse D6 describes (see D6).

**Found:** by comparing the emitted role in `references/cost-emission.md` §7 against the role label the (now-deleted) README used for the same command, during the audit that produced D1. The Mermaid carrier was found later, while triaging what first looked like a fourth carrier for D6, and reclassified here once its structure showed it was this defect's shape, not D6's.

**Disposition:** **Mixed.** The broader question — whether `/ready`'s role should conceptually be called `team` or `QA` — is **reported, not resolved**: both labels may have been intentional at different times, `team` could be a later rename of `QA`, or the two could reflect a genuine disagreement about which function `/ready` belongs to; that is a product decision outside a documentation restructure's authority, flagged for Ivan's decision. The one concrete instance inside this restructure's own scope — `docs/workflow.md`'s Mermaid label — is **fixed** in this task: changed from `QA — verification & gates` to `Team — verification & gates`, bringing it into agreement with `docs/roles-and-phases.md` and `plugins/dev-workflows/README.md`, both already correct and both written by this same restructure. Only the label text changed; the diagram's structure, nodes, edges, and subgraph membership are unchanged.

---

## D4 — Environment prerequisites gave a proper entry to one of six variables

**Claimed:** the old README's `## Environment prerequisites` section documented the plugin's settable environment variables.

**True:** of six variables the plugin actually reads, only one got a proper entry; `DEV_WORKFLOWS_COST_PRICES` — a real, user-overridable path used by session-cost reporting to price against a non-default per-model table — was documented as a settable variable nowhere in the repository.

**Found:** by enumerating every `$DEV_WORKFLOWS_*`-shaped read in the plugin's commands, agents, and hooks, and diffing that set against the README's prerequisites section.

**Disposition:** **Fixed** by Tasks 3 and 4. `docs/reference/environment.md` now documents all six variables, including `DEV_WORKFLOWS_COST_PRICES`. Defended going forward by `check-docs.sh` check 5, whose exclusion list now fails on a seventh user-settable variable appearing undocumented rather than passing silently — the same shape of gap that let D4 through originally.

---

## D5 — `references/` holds 98 files against 93 markdown

**Claimed (implicit):** a reference-file inventory built by counting `references/*.md` was complete.

**True:** `references/` holds 98 files, of which 93 are markdown; the remaining 5 include `cost-prices.yaml` — the default per-model token-price table, directly user-overridable via `$DEV_WORKFLOWS_COST_PRICES` (see D4) — which is user-facing and belongs in a reference inventory even though it is not markdown.

**Found:** by comparing a `find references -type f | wc -l` count against a `find references -type f -name '*.md' | wc -l` count while auditing what the restructure needed to account for; the five-file gap included `cost-prices.yaml` plus four other non-markdown reference assets (`dynatrace-docs/managed-owners.txt`, `dynatrace-docs/docs-profile.default.yml`, `guidelines/check_guidelines.py`, `api-guidelines/template/openapi-template.yaml`).

**Disposition:** **Fixed** by Task 5. `docs/reference/references.md` now inventories reference *files*, not just reference *markdown*, and explicitly documents `cost-prices.yaml` as user-overridable. Defended by `check-docs.sh` check 4, which counts the same way (`find ... -type f`, not `-name '*.md'`) so a future non-markdown reference file added without a corresponding doc entry will drift the count and fail the gate.

---

## D6 (new) — a live, contradictory role vocabulary in three references

**Claimed:** `references/next-phase-offer.md`, `references/session-hygiene.md`, and `references/workflow-states.md` each describe the plugin's roles as a four-way split — "PM / PA / PE / Team" (`next-phase-offer.md:12`), "PM / PA / PE / Team" (`session-hygiene.md:71`), "PM/PA/PE/Team" (`workflow-states.md:6`).

**True:** `references/cost-emission.md` §7 — the authority for every command's emitted role — uses **five** roles, not four: `pm`, `pa`, `pe`, `dev`, and `team`. What the older three-file vocabulary lumps together as "Team" is actually split in the shipped attribution table between `dev` (`/design`, `/implement`, `/document`) and `team` (`/ready` alone). This is not merely a vocabulary shorthand: `workflow-states.md:21-22` genuinely performs the collapse — its VI status ladder assigns the **Implementation** row's driving command `/implement` the role `Team`, where `cost-emission.md` §7 gives `/implement` the role `dev`. The adjacent **Ready for Implementation** row (line 21) shows the same collapse, labeling its `/epics`/`/specify`/`/design` commands `PE→Team` where §7 gives them `pe`/`pe`/`dev`.

**Found:** while investigating D3 (`/ready`'s role), which surfaced that `references/cost-emission.md` §7 uses a role vocabulary broader than "Team" — checking where else that broader vocabulary should have propagated found three references still asserting the older, narrower four-role split. A fourth candidate was investigated and ruled out: `docs/workflow.md`'s Mermaid subgraph label `QA["QA — verification & gates"]` looked like the same carrier, but the diagram's *structure* already gives `dev` and the fifth role separate subgraphs (`DEV` and `QA`), matching §7's five-role split — only the `QA` subgraph's label text was stale, which is a different defect shape (a stale label on an already-correct split, D3's shape) from this one (a structural collapse). Moved to D3 and fixed there; this entry's carrier count is three, not four.

**Disposition:** **Reported, not resolved.** Per `references/instruction-file-maintenance.md`, two live contradictory instructions is a defect in its own right, independent of which one is correct. Resolving it means deciding whether `next-phase-offer.md`, `session-hygiene.md`, and `workflow-states.md` — the three references carrying the older four-role vocabulary, including `workflow-states.md`'s outright `/implement` → `Team` misassignment — should be updated to the five-role vocabulary (`pm`/`pa`/`pe`/`dev`/`team`) that `cost-emission.md` §7 actually implements, or whether the split is a documentation-only distinction those three files may legitimately elide. That decision spans shipped plugin content beyond a documentation-restructure's scope — all three files are outside `docs/` and the README — and is left for Ivan.

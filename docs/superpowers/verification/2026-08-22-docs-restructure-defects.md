# dev-workflows docs restructure — defects found during verification

**Context:** `plugins/dev-workflows/docs/` restructure (34 pages) and README rewrite (379 lines to 46), branch `iv-gu/docs-restructure`. This file records every defect the restructure's verification surfaced, whether the restructure fixed it, and — for the two still open — what a human needs to decide.

---

## D1 — Commands table documented 19 of 21 commands

**Claimed:** the old README's Commands table was a complete list of the plugin's slash commands.

**True:** it listed 19. `/vuln` and `/upgrade` existed as shipped commands (`plugins/dev-workflows/commands/vuln.md`, `plugins/dev-workflows/commands/upgrade.md`) but were orphaned in an unlabeled "Additionally:" table nested under the `/implement` workflow section instead of the Commands table itself, so a reader scanning the Commands table alone would not learn either command exists.

**Found:** by cross-checking the README's Commands table against `plugins/dev-workflows/commands/*.md` — the census a documentation restructure has to do anyway to know what it is moving.

**Disposition:** **Fixed** in Task 14. The new `docs/reference/commands.md` lists all 21 commands in one table; `check-docs.sh` check 4 now defends the count going forward.

---

## D2 — `cost-emission.md` §7 omitted `/update-vi`

**Claimed:** `references/cost-emission.md` §7 introduces its table as "Fixed per-command labels" — implying it is the complete attribution authority for every command that emits a fixed `phase`/`role` pair to `emit-cost`.

**True:** the table listed ten commands and did not include `/update-vi`, yet `commands/update-vi.md:131` calls `emit-cost` with `phase: vi-update`, `role: pm`, and line 4 of `cost-emission.md` itself names `/update-vi` among the commands that run the Session cost phase. `vi-update` was therefore a phase value emitted by a shipped command and enumerated in no authority — the table contradicted the file it lives in.

**Found:** by grounding the role/phase model against the commands that actually call `emit-cost`, rather than reading `cost-emission.md` in isolation — the same class of check as D1, run against a different table. Step 1 of this task re-confirmed the defect still held (table had ten rows, no `/update-vi` row, `update-vi.md:131` passing `phase: vi-update, role: pm`) before the fix was applied.

**Disposition:** **Fixed** in this task. One row inserted — `| \`/update-vi\` | vi-update | pm |` — immediately after `/create-vi`, preserving the table's lifecycle-stage row order rather than alphabetizing. The table now has eleven rows. Defended going forward by the bidirectional check below (Step 3): every command that passes a fixed `phase`/`role` to `emit-cost` has a §7 row, and every §7 row names a real command. Both loops produced no output on the fixed table; the first loop is the one that would have caught D2 the moment `/update-vi`'s row was first omitted, had it existed then.

---

## D3 — `/ready`'s role: `team` in §7, `QA` in the old README

**Claimed:** the old README's role table filed `/ready` under `QA`.

**True:** `references/cost-emission.md` §7 gives `/ready` the role `team` — that is what `commands/ready.md` actually passes to `emit-cost`, i.e. what the shipped artifact records. The old README no longer exists (retired by this restructure), so there is no live document asserting `QA` to reconcile against. Searching the current authority, `CLAUDE.md`, for "QA" returns zero occurrences — nothing in the surviving instruction set calls `/ready`'s role `QA`, which makes `team` the sole surviving authority on this specific question.

**Found:** by comparing the emitted role in `references/cost-emission.md` §7 against the role label the (now-deleted) README used for the same command, during the audit that produced D1.

**Disposition:** **Reported, not resolved.** Both labels may have been intentional at different times — `team` could be a later rename of `QA`, or the two could reflect a genuine disagreement about which function `/ready` belongs to. Docs now consistently say `team` because that is what the shipped code emits; whether `/ready` *should* be filed under `QA` conceptually is a product decision outside a documentation restructure's authority. Flagged for Ivan's decision; see also D6, which finds the same `QA`/`team` split live in un-restructured plugin content.

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

## D6 (new) — two live, contradictory role vocabularies

**Claimed:** `references/next-phase-offer.md`, `references/session-hygiene.md`, and `references/workflow-states.md` each describe the plugin's roles as a four-way split — "PM / PA / PE / Team" (`next-phase-offer.md:12`), "PM / PA / PE / Team" (`session-hygiene.md:71`), "PM/PA/PE/Team" (`workflow-states.md:6`).

**True:** `references/cost-emission.md` §7 — the authority for every command's emitted role — uses **five** roles, not four: `pm`, `pa`, `pe`, `dev`, and `team`. What the older three-file vocabulary lumps together as "Team" is actually split in the shipped attribution table between `dev` (`/design`, `/implement`, `/document`) and `team` (`/ready` alone). A fourth carrier of the old four-role vocabulary is `docs/workflow.md`'s Mermaid subgraph label `QA["QA — verification & gates"]` (`docs/workflow.md:25`), moved verbatim from the old README during this restructure rather than reconciled against §7's `dev`/`team` split — and rather than against `role: team`, the same code fact underlying D3.

**Found:** while investigating D3 (`/ready`'s role), which surfaced that `references/cost-emission.md` §7 uses a role vocabulary broader than "Team" — checking where else that broader vocabulary should have propagated found three references still asserting the older, narrower four-role split, plus the Mermaid diagram this restructure itself produced from README content carrying the same stale split forward.

**Disposition:** **Reported, not resolved.** Per `references/instruction-file-maintenance.md`, two live contradictory instructions is a defect in its own right, independent of which one is correct. Resolving it means deciding whether `next-phase-offer.md`, `session-hygiene.md`, and `workflow-states.md` should be updated to the five-role vocabulary (`pm`/`pa`/`pe`/`dev`/`team`) that `cost-emission.md` §7 actually implements, or whether the split is a documentation-only distinction that those three files may legitimately elide. That decision spans shipped plugin content beyond a documentation-restructure's scope — `next-phase-offer.md`, `session-hygiene.md`, and `workflow-states.md` are all outside `docs/` and the README — and is left for Ivan.

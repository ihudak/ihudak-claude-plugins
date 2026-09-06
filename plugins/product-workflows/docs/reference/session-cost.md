# Session cost

Cost attribution is one of the subsystems the companion `workflows-core` plugin holds: its `cost-emission` reference and the price table beside it are what every plugin in the family reads, and its `session-cost.py` script does the arithmetic. This page documents the subsystem from the side that invokes it — what a command here declares, and what the twelve commands *in this plugin* charge to.

## What a command declares

Every cost-emitting command passes a `phase` and a `role` label at the point it calls the shared entry point, and `workflows-core:cost-emission` §7 carries one attribution row per command. Twelve commands emit a cost entry here — all of them, and all with a fixed pair rather than an inferred one:

| Command(s) | Phase | Role |
|---|---|---|
| `/idea`, `/create-prd` | `prd-creation` | `pm` |
| `/update-prd` | `prd-update` | `pm` |
| `/brd-intake`, `/brd-split`, `/brd-interview`, `/brd-package`, `/brd-reconcile` | `brd-to-prd` | `pm` |
| `/brd-ground` | `brd-to-prd` | `pa` |
| `/create-ard` | `architecture` | `pa` |
| `/epics` | `epic-refinement` | `pe` |
| `/specify` | `specification` | `pe` |

`brd-to-prd` is the one phase shared across two roles: every command of the BRD-to-PRD route runs as PM except `/brd-ground`, which is PM-initiated but PA/Dev-executed, and both roles tag their cost line `brd-to-prd`. [Roles and phases](../roles-and-phases.md) defines what each phase means and what a run in it is accountable for; this page states only what each command passes.

## Where cost files land

Cost writes to a `cost/` subdirectory with one file per session — `<PRD-dir>/dev-workflows/cost/<sid8>.md`, named after the first eight characters of the session id — so no two engineers' commands can collide in one file. That folder name is a fixed, family-wide constant shared by every plugin's cost, feedback, and resume bookkeeping, not a `product-workflows`-specific path; the sibling `docs-workflows` plugin's own commands write into the identical folder name. Where no folder resolves, the entry goes to a pending file under `$SPECS_PATH` and is offered for relocation once a real key is known; where nothing resolves at all, it stays in the run's printed output. The plugin never writes into your current working directory.

None of this touches git directly — the entry is committed and pushed later, once, by the run's terminal `commit-artifacts` step, bounded to the session-artifact paths inside `$SPECS_PATH`.

## How cost is computed and what a figure covers

The script reads the assistant-turn `usage` and `model` fields already present in the session's main transcript, plus every subagent transcript dispatched during the window being measured, sums token counts per model, and multiplies by the price table in effect. Claude Code stores no dollar figure of its own in the transcript, so cost is always **computed** rather than read, and it drifts from Claude Code's own accounting by exactly the accuracy of that table. Override the bundled table with `$DEV_WORKFLOWS_COST_PRICES`, a variable the companion `workflows-core` plugin reads and documents — the name is the same family-wide constant as the cost folder itself, not a `product-workflows`-specific setting.

The window is **chained, not fixed**: a small local checkpoint file, keyed by session id and never committed, records where the last cost phase left off, and the next one picks up exactly there. A session that runs `/create-prd` and then hands off to `/create-ard` produces two entries whose windows are contiguous — and the replaying run may be in another plugin, which after the marketplace split it often is. The full mechanics, the entry format, and the §7 attribution table itself live in `workflows-core:cost-emission`, which this page describes rather than restates.

# Session cost

Cost attribution is one of the subsystems the companion `workflows-core` plugin holds: its `cost-emission` reference and the price table beside it are what every plugin in the family reads, and its `session-cost.py` script does the arithmetic. This page documents the subsystem from the side that invokes it — what a command here declares, and what the commands *in this plugin* charge to.

## What a command declares

Every cost-emitting command passes a `phase` and a `role` label at the point it calls the shared entry point, and `workflows-core:cost-emission` §7 carries one attribution row per command. A command that cannot label itself in advance passes `phase: inferred, role: inferred` and lets the cost phase resolve the real values from the run's own context.

Two commands emit a cost entry here: `/document` — in both its keyed and its direct mode, against a single attribution row — and `/release-notes`. `/document` passes a fixed `documenting`/`dev` pair, because a documentation run is dev-phase work regardless of which mode wrote it. `/release-notes` is the one of the two that infers: it passes `phase: inferred, role: inferred` and lets the cost phase decide by checking whether a `specification.md` or a `design.md` already exists under the PRD's specs directory — neither present means the PRD was only just created, so the entry is attributed to the PM's early run (`prd-creation`/`pm`); either one present means engineering work is underway, so it is attributed to the dev's later documenting run (`documenting`/`dev`). Epic presence is deliberately excluded from that check, since a PRD can have drafted Epics while still entirely in product hands.

Both phases belong to the pipeline the companion `dev-workflows` plugin drives, which is the point: a documentation run's spend lands against the same PRD as the specification and implementation runs that preceded it, in the same per-session cost file, so the total for a Product Requirements Document stays one number rather than one per plugin.

**`/docs-profile` emits nothing.** It is a one-shot setup utility with no PRD to attribute spend to — it profiles a documentation repository so that later `/document` runs have something to read.

## Where cost files land

Cost writes to a `cost/` subdirectory with one file per session — `<PRD-dir>/dev-workflows/cost/<sid8>.md`, named after the first eight characters of the session id — so no two engineers' commands can collide in one file. Where no folder resolves, the entry goes to a pending file under `$SPECS_PATH` and is offered for relocation once a real key is known; where nothing resolves at all, it stays in the run's printed output. The plugin never writes into your current working directory, since on a `/document` run that is a docs repository.

None of this touches git directly — the entry is committed and pushed later, once, by the run's terminal `commit-artifacts` step, bounded to the session-artifact paths inside `$SPECS_PATH`.

## How cost is computed and what a figure covers

The script reads the assistant-turn `usage` and `model` fields already present in the session's main transcript, plus every subagent transcript dispatched during the window being measured — which for a keyed `/document` run is a large set, since the diff summarizers, the planner, the writer and the reviewer are all separate agents — sums token counts per model, and multiplies by the price table in effect. Claude Code stores no dollar figure of its own in the transcript, so cost is always **computed** rather than read, and it drifts from Claude Code's own accounting by exactly the accuracy of that table. Override the bundled table with `$DEV_WORKFLOWS_COST_PRICES`, a variable the companion plugin reads and documents.

The window is **chained, not fixed**: a small local checkpoint file, keyed by session id and never committed, records where the last cost phase left off, and the next one picks up exactly there. A session that runs `/implement` and then `/document` produces two entries whose windows are contiguous — and the replaying run may be in another plugin, which after the split it usually is.

**A claim only resolves onto a command of this family.** The deferred claim is matched against a manifest of the family's own `<plugin>:<command>` names, so a command from another marketplace ends the open window — its spend is its own — without ever being claimable. A claim it interrupts is reported as unmatched and dropped, never quietly attached to it. `workflows-core:cost-emission` §13 owns the rule. The full mechanics, the entry format, and the §7 attribution table itself live in `workflows-core:cost-emission`, which this page describes rather than restates.

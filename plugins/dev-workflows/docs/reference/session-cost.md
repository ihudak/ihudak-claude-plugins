# Session cost

Every VI-lifecycle command tags its own run with a dollar figure and appends it to a per-VI, per-session cost file, so the plugin maintainer can later add up what a Value Increment cost across every engineer and team who touched it. Claude Code stores no dollar figure of its own anywhere in the transcript — cost is always **computed** from token usage against a price table, never read off some authoritative source, which makes it an estimate that drifts from Claude Code's own accounting by exactly the accuracy of that price table. This is an accepted trade: cost accuracy is explicitly secondary to code and doc quality, and the "Session cost" phase always runs and always writes something, even when the something is only a line in the run's own printed output.

## Where cost files land

Cost writes to a **`cost/` subdirectory with one file per session**, not one file per VI the way feedback and follow-ups do — `<VI-dir>/dev-workflows/cost/<sid8>.md`, named after the first eight characters of the session id. That per-session split is deliberate merge-safety: the largest VI to date was worked by 23 teams, and giving every session its own file means no two engineers' commands can ever collide in the same file. A single session that runs several dev-workflows commands in a row — `/idea` then `/create-vi` then `/specify`, say — appends one entry per command invocation to that same session file, never deduplicated, because each invocation is a distinct dollar measurement; `/design Epic1` followed by `/design Epic2` in one session produces two separate entries. No entry carries a user name anywhere — the git commit author, once the file is committed and pushed, is the only identity layer this feature relies on.

The write target is resolved by a specs-first ladder, walked top-down, stopping at the first tier that applies:

1. `$SPECS_PATH` is writable and the VI directory can be matched → `<VI-dir>/dev-workflows/cost/<sid8>.md`. This is the primary case and the one the whole feature exists for.
2. `$SPECS_PATH` is writable but no VI directory matches (a keyless run, such as early idea refinement) → the entry goes to a **pending** file instead, at `$SPECS_PATH/dev-workflows-cost/pending-<date>-<sid8>.md`. The next time any command in the same or a later session resolves a real VI key, it lists the pending files it finds and offers to relocate their entries into the now-known VI's cost directory — same-session files are pre-selected as the likely match. A confirmed relocation moves the entries and deletes the pending file so it never resurfaces; a declined one is simply left in place and may be offered again later.
3. No `$SPECS_PATH`, but `$VAULT_PATH` is set and writable → `$VAULT_PATH/dev-workflows/cost/<sid8>.md`, with a loud warning that this location will not auto-aggregate to the maintainer.
4. The run's source is an imported Jira directory with neither specs nor vault available → the file lands beside that imported directory.
5. Nothing resolvable → **report-only**: the entry stays only in the run's printed output. The plugin never writes into your current working directory, since it may be a code repository.

None of this touches git — the cost entry is committed and pushed later, once, by the run's terminal `commit-artifacts` step, the same as every other session artifact this plugin writes into `$SPECS_PATH`.

## How cost is computed

The shipped `session-cost.py` script does the actual arithmetic: it reads the assistant-turn `usage` and `model` fields already present in the session's main transcript, plus every subagent transcript dispatched during the window being measured, sums token counts per model, and multiplies by the price table in effect for that run (below). An unknown model — one absent from the price table entirely — is still recorded with its token counts, priced `cost_usd: null`, and tagged `note: unpriced-model`; the run never fails on this, but if that unpriced model turns out to hold the largest token share of any model in the entry, the command prints a visible warning naming it, so a cost figure that is silently a lower bound doesn't go unnoticed.

**The window a command's cost figure covers is chained, not fixed.** A small local checkpoint file, keyed by session id and never committed, records where the last dev-workflows cost phase left off — a transcript line offset and a timestamp. The next cost phase in the same session picks up exactly there, so a session running three dev-workflows commands back to back produces three entries whose windows are contiguous: activity between one command's end and the next command's start rolls into the next command's bucket, and only the time before the first command and after the last is left unattributed. The checkpoint advances after every computation, including in the pending and report-only tiers above, so the next command's window is always correct regardless of where this one's entry ended up.

**The price table** lives at `${CLAUDE_PLUGIN_ROOT}/references/cost-prices.yaml`, keyed by model id, giving USD-per-million-token rates for `input`, `output`, `cache_read`, `cache_write_5m`, and `cache_write_1h`. Rates are the standard, permanent first-party API prices — never a promotional or introductory rate — so cost stays comparable across VIs over time rather than making identical work look artificially cheap today and dearer once a promotion ends. Cache tokens follow Anthropic's standard multipliers (a cache read prices at roughly a tenth of the input rate; a 5-minute cache write at 1.25x; a 1-hour write at 2x), and model lookup falls back from an exact model-id match to the longest matching undated prefix, so a dated transcript model id like `claude-sonnet-5-20250930` still prices correctly against an undated `claude-sonnet-5` table entry.

**An optional cross-check ("Option B")** is available once the plugin's status line is installed: the status line snapshots Claude Code's own `total_cost_usd` on every render, and the cost phase reads the delta between the current snapshot and the one recorded at the previous checkpoint, surfacing it as `cost_statusline_usd` alongside the computed figure. It is emitted only once both a current snapshot and a prior baseline exist — the very first cost phase in a session always omits it, even with the status line installed, since there is no baseline yet to diff against.

## How a run is attributed

Every cost-emitting command passes a `phase` and a `role` label to the cost phase at the point it calls the shared entry point — this is what lets the maintainer later group spend by where in the lifecycle it was spent and who was doing the spending. [Roles and phases](../roles-and-phases.md) is the place that vocabulary actually lives — the nine cost-attribution phases and the four roles, and which command emits each — so this page does not restate it. What belongs here is the mechanics of the assignment itself, not what the labels mean once assigned.

Eleven commands emit a cost entry: `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/epics`, `/design`, `/implement`, `/ready`, `/document` (both its Jira and direct modes), and `/release-notes`. Ten of those pass a fixed `phase`/`role` pair baked into the command itself. `/release-notes` is the one exception: it passes `phase: inferred, role: inferred` and lets the cost phase resolve the real values by checking whether a `specification.md` or a `design.md` already exists under the VI's specs directory — neither present means the VI itself was only just created, so the entry is attributed to the PM's early run (`vi-creation` / `pm`); either one present means engineering work is already underway, so the entry is attributed to the dev's later documenting run (`documenting` / `dev`). Epic presence is deliberately excluded from that check, since a VI can have drafted Epics while still entirely in product hands.

**`/vuln` and `/upgrade` emit no cost attribution at all.** Neither has a Value Increment to attribute spend to, and neither calls the cost entry point — `references/cost-emission.md` never mentions them. Both commands do pass a field also named `phase` to their own fixer/executor subagents (`full`, `verify-resume`, `regression-resume`), but that is a completely different vocabulary belonging to the model-routing resume protocol, saying how much of a single command's own work must be re-executed after a review or a failed test — not where a run sits in the product lifecycle. The two vocabularies share nothing but the field name; see the closing note on [Roles and phases](../roles-and-phases.md#cost-attribution-phases) for the fuller distinction.

Every attributed entry also carries the run's resolved keys: `vi` is always present, and `epic` is present only when an Epic key was in scope for that run.

The dollar figure attached to a phase depends on which price table priced it — override the bundled default with `$DEV_WORKFLOWS_COST_PRICES`, a path to your own `models:`-keyed price file; see [Environment](environment.md#dev_workflows_cost_prices) for the exact resolution order and file shape. Setting it is never required — the shipped table covers every model the routing policy can reach.

## Reading a cost file

Here is one persisted entry, copied verbatim from the shared reference this page is derived from:

````markdown
## 2026-07-09T14:22:33Z — /implement — implementation

```yaml
id: PRODUCT-14902-15001-implement-2026-07-09T14:22:33Z   # timestamp => unique
date: 2026-07-09T14:22:33Z
command: /implement
phase: implementation
role: dev
vi: PRODUCT-14902
epic: PRODUCT-15001            # present only when an Epic key is in scope
plugin_version: 2.10.0
duration_s: 1284
cost_computed_usd: 3.4821
cost_statusline_usd: 3.5102   # present only when the plugin statusline is installed
models:
  - {model: claude-opus-5, cost_usd: 2.9114, input_tokens: 12043, output_tokens: 88210, cache_read_tokens: 2109887, cache_write_tokens: 145002}
  - {model: claude-sonnet-5, cost_usd: 0.5707, input_tokens: 45120, output_tokens: 210334, cache_read_tokens: 880122, cache_write_tokens: 42011}
```
````

Walking it field by field: `id` is stable and timestamp-suffixed, so a re-run never double-logs against it. `date` is when this entry's window ended, and `command`/`phase`/`role`/`vi`/`epic` are the attribution fields from the section above. `plugin_version` pins which release of the plugin produced this entry. `duration_s` is wall-clock seconds, not token-processing time — it is the gap between when this command's window started (the previous dev-workflows command's checkpoint in this session, or the session's own start if this was the first) and when it ended; a large `duration_s` on a small `cost_computed_usd` usually just means a long-idle session, not an expensive one.

`cost_computed_usd` and `cost_statusline_usd` measure the same run through two different lenses and are expected to differ by a few cents, not agree exactly. `cost_computed_usd` is built by re-deriving cost from the transcript's own token counts against the price table, so it stays complete right up to the very last turn but is only as accurate as that price table. `cost_statusline_usd` is a delta against Claude Code's own status-line cost figure, so it is authoritative on price, but the status line renders after the final turn completes, which means it can lag slightly at the tail of a run. Neither one is simply "the one to trust" over the other — a small, stable gap between them is the plugin's own calibration signal, and a gap that grows noticeably is the cue to refresh the price table, not evidence that one figure is broken.

`models` holds one row **per model actually used**, not one row per agent that used it. The window being measured spans the main session transcript plus every subagent transcript dispatched during it, and token usage from all of them is summed together by model id before pricing runs — so if both the orchestrating session and three different subagents all happened to run on `claude-sonnet-5`, that is still exactly one row, because the price table only cares which model billed the tokens, never which agent asked for them.

Finally, `cache_read_tokens` running far larger than `input_tokens` — as it does in both rows above — is a healthy sign, not a red flag: it means most of what this run "read" was already-cached context (prior conversation, tool definitions, repeated system prompt) rather than freshly billed input, and a cache read prices at roughly a tenth of the input rate. A run with a huge `cache_read_tokens` figure and a comparatively small `cost_usd` is exactly what efficient reuse of context looks like; the raw token count is not the number to be alarmed by, `cost_usd` is.

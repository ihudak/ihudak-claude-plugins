# Session Cost Emission — Shared Reference

Single source of truth for the dev-workflows session-cost subsystem. The terminal
"Session cost" phase of every cost-emitting command cites this file and executes
its steps inline through the single `emit-cost` entry point (§11).

**Which commands those are is §7's attribution table, and nothing else.** A command
emits a cost entry if and only if §7 gives it a row, so no roster and no total is
restated here: the PRD-lifecycle commands have rows there, so do the `/brd-*`
commands of the BRD-to-PRD route, and so do the four feedback
commands, which are not PRD-lifecycle and infer their labels rather than carrying
fixed ones. Read the
table for the set; a second copy of it in this preamble is what went stale before —
the list this sentence replaces named the PRD-lifecycle commands only, and had
already omitted every `/brd-*` emitter.

The orchestrator owns every prompt; this reference owns session-artifact resolution,
the chained-checkpoint model, the transcript-window computation, the price table,
the report format, the persistence ladder, pending/reconciliation, and the
optional statusline augmentation.

**Purpose.** Know how many **dollars** a Product Requirements Document (PRD) cost across its
whole lifecycle, broken down by **phase**, **role**, and **model** — persisted
per-PRD into the specs repo so the maintainer can aggregate spend across every
engineer and team. A PRD's cost is the sum of per-command cost lines contributed
by every session that worked on it; summing is a read-time concern for the
maintainer — the plugin only ever appends immutable per-invocation measurements.

**Cost is computed, never read.** Claude Code stores no dollar figure in the
transcript. Every assistant message carries `.message.usage` + `.message.model`;
`${CLAUDE_PLUGIN_ROOT}/scripts/session-cost.py` sums tokens per model and multiplies by a price table
(§4). Dollars are therefore an estimate that drifts from Claude Code's own figure
by the accuracy of the price table — an accepted trade (cost accuracy is
explicitly secondary to code/doc quality).

**Relationship to siblings.** Shares the `<PRD-dir>/dev-workflows/` per-PRD home
with `feedback-emission.md` / `followup-emission.md` and the self-contained
emitter pattern, but diverges deliberately: a **`cost/` subdir with per-session
files** (merge-safety under massive team fan-out — the largest PRD to date was
worked by 23 teams) and **no dedup / no prose** (pure measurement, append-only).
No dedup or cross-reference between the three. This subsystem does NOT use the
`impl-maintenance` agent.

**Cost ALWAYS runs.** Unlike feedback (which writes nothing when there is no
plugin signal), the cost phase always computes and always advances the checkpoint
(§3) — even when it can only report-only. A silent write with no interaction is
the norm; the sole interactive moment is pending reconciliation (§9), and only
when pending files exist.

## 1. Session-artifact resolution

Derive from `cwd` and the current session (Claude Code's project-slug rule):

- **`<cwd-slug>`** — the absolute `cwd` with every `/` and `.` replaced by `-`
  (e.g. `/workspace/docs` -> `-workspace-docs`).
- **Main transcript** — the newest `*.jsonl` directly under
  `~/.claude/projects/<cwd-slug>/`. Its basename minus `.jsonl` is `session_id`.
- **`<sid8>`** — the first 8 characters of `session_id`.
- **Subagents dir** — `~/.claude/projects/<cwd-slug>/<session_id>/subagents/`
  (holds `agent-*.jsonl` with their own Sonnet/other `usage` + `model`).

## 2. Cost computation (`session-cost.py`)

Invoke the shipped helper (stdlib-only, pure computation, no specs-repo writes):

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/session-cost.py" \
  --transcript    <main transcript .jsonl (§1)> \
  --subagents-dir <subagents dir (§1)> \
  --prices        <resolved price table (§4)> \
  --checkpoint    ~/.claude/dev-workflows/cost-state/<session_id>.json \
  --snapshot      ~/.claude/dev-workflows/cost-snapshots/<session_id>.json \
  --now-ts        <current UTC ISO8601>
```

The helper reads the main transcript **from the checkpoint's line offset
forward, skipping JSON-parsing of every line before that offset** — I/O still
scans the whole file (the transcript can be tens of MB), but the offset saves
re-parsing lines already processed by a prior command — plus every
`subagents/agent-*.jsonl` entry with `timestamp` in `(last_ts, now]`, groups
`usage` by `model`, applies the price table, and prints JSON to stdout:

```json
{
  "models": [
    {"model": "...", "cost_usd": 0.0, "input_tokens": 0, "output_tokens": 0,
     "cache_read_tokens": 0, "cache_write_tokens": 0}
  ],
  "cost_computed_usd": 0.0,
  "cost_statusline_usd": null,
  "duration_s": 0,
  "new_checkpoint": {"line_offset": 0, "last_ts": "...Z", "last_snapshot_cost": null}
}
```

An unknown model (absent from the table) is recorded with its tokens,
`cost_usd: null`, and `note: unpriced-model` — the run never fails. `emit-cost`
formats `models` + `cost_computed_usd` + `cost_statusline_usd` + `duration_s`
into the entry (§6) and writes `new_checkpoint` back (§3).

## 3. Chained-checkpoint model

Single touchpoint per command; a command's window START is the previous
dev-workflows command's END in the same session.

- **Checkpoint file:** `~/.claude/dev-workflows/cost-state/<session_id>.json` —
  per-user, per-session, **transient/local, NEVER committed** (safe to delete).
- **Contents:** `{line_offset, last_ts, last_snapshot_cost}` captured at the END
  of the last cost phase.
- **First command in a session:** no checkpoint -> `line_offset: 0`,
  `last_ts: null` -> the window starts at the session origin (start = $0).
- **Advance ALWAYS.** After computing, write `session-cost.py`'s `new_checkpoint`
  back to the checkpoint file — **even in the pending / report-only tiers (§8),
  so the next command's window is correct.** The write is a plain overwrite of
  the transient local file (no git, no specs repo).
- **A command that cedes the session advances the checkpoint late, not never**
  (§13): its window is closed retroactively by the next cost-emitting run, at the
  transcript boundary where that run began.
- **Semantics (for users):** the whole session's spend is attributed to the PRD;
  activity between commands rolls into the next command's bucket; the
  pre-first-command and post-last-command tails are unattributed (~0 for a clean
  per-PRD container session). Per-command costs therefore sum to the session total
  minus those tails.

## 4. Price table

`${CLAUDE_PLUGIN_ROOT}/references/cost-prices.yaml` requires a top-level **`models:`** map keyed by
model id, **USD per million tokens** (`input`, `output`, `cache_read`,
`cache_write_5m`, `cache_write_1h`), plus a top-level `default: null`:

```yaml
models:
  <model-id>:
    input: <usd-per-million>
    output: <usd-per-million>
    cache_read: <usd-per-million>
    cache_write_5m: <usd-per-million>
    cache_write_1h: <usd-per-million>
default: null
```

Model lookup is exact-first, then longest-prefix: an undated base key (e.g.
`claude-sonnet-5`) prices a dated transcript model id (e.g.
`claude-sonnet-5-20250930`) when no exact key matches.

The `models:` wrapper is **required** — `price_model()` reads
`prices.get("models")`, so model ids placed at the top level (as siblings of
`default`, instead of nested under `models:`) are never found and every model
prices as unpriced / `$0`. An override supplied via `$DEV_WORKFLOWS_COST_PRICES`
(below) is read by this same `price_model()`, so it must use this identical
nested shape.

**`default: null` is documentary only** — `price_model()` never consults it as a
fallback rate map. Any model id absent from `models:` is always priced
`cost_usd: null` with `note: unpriced-model` (§6), regardless of what `default`
is set to.

Cache multipliers follow Anthropic's standard model (read 0.1x, 5m write 1.25x,
1h write 2x); the transcript's `ephemeral_5m` / `ephemeral_1h` split lets cache
pricing be exact, and a message without the split prices
`cache_creation_input_tokens` at the 5m rate.

**Resolution order (first found wins):** `$DEV_WORKFLOWS_COST_PRICES` (a path) ->
a repo-local `cost-prices.yaml` -> the shipped
`${CLAUDE_PLUGIN_ROOT}/references/cost-prices.yaml`. The shipped rates are the
standard first-party Claude API prices (from Anthropic's pricing page) for every
model the routing policy can reach — the Opus chain and the Sonnet chain —
**plus Haiku, priced as a harmless defensive entry even though no routing path
in `classification.md` currently reaches it**; a maintainer refreshes them when
Anthropic's prices change. **Permanent standard
rates are used deliberately — never promotional/introductory rates** — so cost
stays comparable across PRDs over time (a temporary promo would make identical
work look cheaper now and dearer later, distorting efficiency comparisons).

## 5. Statusline augmentation (optional — "Option B")

An authoritative cross-check, available only when the plugin statusline is
installed (via `/dev-workflows:statusline`):

- The shipped statusline writes a snapshot each render:
  `~/.claude/dev-workflows/cost-snapshots/<session_id>.json = { ts, cost_usd }`
  from its stdin `.cost.total_cost_usd` (an overwrite of a single object each
  render — bounded size).
- `emit-cost` passes `--snapshot`; `session-cost.py` sets `cost_statusline_usd` =
  (current snapshot `cost_usd`) - (the `last_snapshot_cost` stored in the
  checkpoint) — a **per-invocation delta on this entry only**, chained
  identically to Option A. **Never an aggregate, never a shared source of truth**
  -> immune to the merge concern.
- **Auto-detect:** the field is emitted only when BOTH the current snapshot file
  exists AND a prior checkpoint baseline (`last_snapshot_cost`) is already
  recorded; otherwise it is `null` and simply omitted from the entry. No
  configuration. In practice, the **first** cost phase in a session always omits
  the field — even with the statusline installed, there is no baseline yet — and
  the **second and later** commands emit the delta against it.
- **Boundary caveat:** B is authoritative on price but lags at the tail (the
  statusline renders *after* the final turn); A reads the per-turn transcript so
  it is more complete at the boundary. The two differing by cents is the intended
  calibration signal (drift => refresh the price table).
- Pending a one-line implementation check that `.cost.total_cost_usd` is present
  on the statusline stdin in the target Claude Code version; if absent, B is
  simply unavailable and A stands alone.

## 6. Report artifact & entry format

**Location (merge-safe by construction):** one file per session under the PRD's
shared area — `<PRD-dir>/dev-workflows/cost/<sid8>.md`. No two sessions share a
file -> no merge conflicts across many teams or one person's N sessions. **No
user name anywhere in the file** (§10).

File-level frontmatter (written once on creation):

```yaml
---
type: dev-workflows-cost
prd: PRODUCT-1234
session: <sid8>
---
```

One appended entry per command invocation (append-only, **never deduped** — each
invocation is a distinct measurement, so `/design Epic1` then `/design Epic2` in
one session are two lines):

````markdown
## 2026-07-09T14:22:33Z — /implement — implementation

```yaml
id: PRODUCT-1234-98760-implement-2026-07-09T14:22:33Z   # timestamp => unique
date: 2026-07-09T14:22:33Z
command: /implement
phase: implementation
role: dev
prd: PRODUCT-1234
epic: EPIC-98760            # present only when an Epic key is in scope
plugin_version: 2.10.0
duration_s: 1284
cost_computed_usd: 3.4821
cost_statusline_usd: 3.5102   # present only when the plugin statusline is installed
models:
  - {model: claude-opus-5, cost_usd: 2.9114, input_tokens: 12043, output_tokens: 88210, cache_read_tokens: 2109887, cache_write_tokens: 145002}
  - {model: claude-sonnet-5, cost_usd: 0.5707, input_tokens: 45120, output_tokens: 210334, cache_read_tokens: 880122, cache_write_tokens: 42011}
```
````

Machine-friendly YAML so the maintainer can filter/sum with Claude Code. No prose
block (unlike feedback). `cost_statusline_usd` is omitted when Option B is
unavailable; a model priced `null` carries `note: unpriced-model`.

### 6.1 Unpriced-model dominance warning

`note: unpriced-model` (above) is an inline field inside the persisted YAML
entry — easy to miss when nobody opens the cost file. When the run's tokens
are actually **dominated** by an unpriced model, that has to be visible where
the user is already looking: the run output.

**Trigger.** Among the entry's `models` array (§6), some model carries
`note: unpriced-model` **and** its token total
(`input_tokens + output_tokens + cache_read_tokens + cache_write_tokens`) is
the largest of any model in the array — i.e. the model the price table cannot
price is the single biggest contributor to this run, not a minor stray call.

**Action.** `emit-cost` prints one visible warning line to the run output —
not just the inline YAML note — in every persistence tier, including
report-only (§8 tier 5), naming the model id and stating that the figure is a
lower bound:

```
⚠ Cost estimate is a lower bound — <model-id> is unpriced (absent from
cost-prices.yaml) and accounts for the most tokens in this run; its cost is
recorded as null and excluded from cost_computed_usd. See the maintainer
checklist (§12) to price it.
```

Print-only — no extra file write, no interactivity, and it never blocks or
alters the entry that gets persisted (§6 still writes `cost_usd: null` for
that model exactly as before).

## 7. Attribution (phase / role / keys)

Fixed per-command labels, with five inferred exceptions:

| Command | phase | role |
|---------|-------|------|
| `/specify` | specification | pe |
| `/epics` | epic-refinement | pe |
| `/design` | planning | dev |
| `/implement` | implementation | dev |
| `/ready` | readiness | dev |
| `/document` | documenting | dev |
| `/release-notes` | **inferred** | **inferred** |
| `/idea` | prd-creation | pm |
| `/create-prd` | prd-creation | pm |
| `/update-prd` | prd-update | pm |
| `/create-ard` | architecture | pa |
| `/brd-intake` | brd-to-prd | pm |
| `/brd-ground` | brd-to-prd | pa |
| `/brd-split` | brd-to-prd | pm |
| `/brd-interview` | brd-to-prd | pm |
| `/brd-package` | brd-to-prd | pm |
| `/brd-reconcile` | brd-to-prd | pm |
| `/prompt` | **inferred** | **inferred** |
| `/feedback` | **inferred** | **inferred** |
| `/prompt-brainstorm` | **inferred** | **inferred** |
| `/prompt-grill-me` | **inferred** | **inferred** |

**`/release-notes` inference (PM PRD-run vs. dev documenting-run).** The
discriminator is the presence of **downstream engineering artifacts** — any
`specification.md` or `design.md` under the PRD's specs dir:

- **None present -> `phase: prd-creation`, `role: pm`** (the PM's early run: the PRD
  exists but no engineering work has started — Epics may or may not exist yet,
  which is fine, since a freshly created PRD with no Epics is exactly the PM case).
- **Either present -> `phase: documenting`, `role: dev`** (the dev re-run, when
  PRD + Epics + specs + design + code all exist).

**`/prompt`, `/feedback`, `/prompt-brainstorm` and `/prompt-grill-me` inference
(inherit the corrected command's labels).**
The discriminator is **`target_command`**, passed in by the caller per §11 — the
command whose output is being corrected or remarked on, or `n/a`. Unlike
`/release-notes`'s discriminator, this one is **not** re-derivable from disk: it
lives in the run's own context, so the caller must supply it and `emit-cost` must
not attempt to infer it from anything else.

- **Target has a fixed `phase`/`role` in the table above -> inherit both.** A
  `/prompt` correcting a `/specify` output is `specification`/`pe` spend; one
  correcting a `/design` output is `planning`/`dev`. This is the point of the
  rule: the cost of fixing a phase's output belongs to that phase, so "what did
  specifying cost" includes the cost of making the spec right.
- **Target is `/release-notes` -> resolve ITS inference first**, then inherit the
  result. One level only; `/release-notes` never resolves to another inferred row.
  **If no PRD dir resolves** — a keyless run, which both callers explicitly support —
  its discriminator cannot be evaluated at all, so do **not** fall through to its
  "none present" branch: that would attribute a keyless plugin correction to
  `prd-creation`/`pm`, which is exactly the guess `role: n/a` exists to forbid.
  Treat it as the `n/a` case below.
- **Target is `n/a`, or a command with no row above -> `phase: plugin-feedback`,
  `role: n/a`.** The second case covers `/vuln`, `/upgrade`, `/docs-profile`,
  `/statusline`, and the two guideline reviewers, none of which emits cost and so
  has nothing to inherit.
- **Target is `/feedback`, `/prompt`, `/prompt-brainstorm` or `/prompt-grill-me` -> treat as `n/a`.**
  A correction to a correction has no lifecycle phase of its own, and inheriting
  from an inferred row would regress without a base case. This is the one rule the
  two deferring commands share with the two immediate ones: what a run inherits is
  decided by its `target_command`, never by which of the four is asking.

`role: n/a` is **not a fifth role** — it is the absence of one, recorded rather
than guessed, and aggregation should treat it as unattributed rather than folding
it into `dev`.

**`/vuln`, `/upgrade`, `/docs-profile` and the two reviewer commands emit no cost entry, and that is
a decision about what the number is for.** A cost entry measures **AI investment in a product
increment**, and the rule is: *a cost entry attaches to a run that advances a PRD- or BRD-scoped
artifact.* A CVE remediation, a library version bump, a docs-profile refresh and a standalone
guideline review advance none — they are noise against a PRD or a BRD, and a metric that averages
the two answers a question nobody asked.

**This is restated here because it lived only on the command pages.** `docs/commands/vuln.md` and
`docs/commands/upgrade.md` have carried the reason all along — *"runs outside the PRD pipeline: no
cost-attribution phase and no role"* — but this file, which is the runtime authority, said nothing,
and an audit reading it found two commands emitting nothing and reported a defect. **Adding emission
to them would be the defect.** Note also what is *not* the reason: both run `specs-preflight` and
`commit-artifacts` and do write into `$SPECS_PATH`, with a `NOISSUE …` commit message where no key
resolved — so "nowhere to write it" was never true either.

**Session feedback is a different question with a different answer.** `/vuln` and `/upgrade` do emit
it, and should: `emit-auto` records that *this plugin* lacked a capability the run needed
(`references/feedback-emission.md` §6), which is how the plugin learns about its own gaps. A
vulnerability run surfaces one as readily as a PRD run does, and the size of the work has nothing to
do with it.

**`/prompt-brainstorm` and `/prompt-grill-me` cannot measure their own spend, so
they defer it (§13).** Both cede the session at their Phase 3 — a hand-off to
another skill, or a long interactive grill — so there is no later point at which
the command still controls execution: a cost phase placed there would never run,
and one placed before the hand-off would price the logging prologue alone. The
same constraint already puts their `commit-artifacts` step before the hand-off
rather than at the end (`specs-repo-git.md` §4).

**What the deferral fixes.** Before §13 existed, neither command advanced the §3
checkpoint, so its spend was **not lost but misattributed**: per §3's semantics
activity between commands rolls into the next command's bucket, and a long grill
followed by `/implement` was priced as `implementation`/`dev` — a *larger* error
than a small one would have been, since a grill is expensive. §13 closes that by
splitting the next command's window at the transcript's own record of where each
run began, so the grill is attributed to the phase whose output it corrected and
`/implement` carries only its own work. Both commands therefore have rows in the
table above: they produce a cost entry, written on their behalf by a later run.
**What remains unmeasured** is a session in which no cost-emitting command ever
follows the grill — there the spend stays in §3's ordinary post-last-command
tail, unattributed, exactly as it is for every other command.

**Epic presence is deliberately NOT part of `/release-notes`'s signal** — a PRD can have drafted
Epics while still in PM/PE hands, so keying on Epics would misattribute the PM
run. Cheap to check; matches the real workflow. Still a heuristic —
reattributable at aggregation time (cost < quality).

**Keys.** Reuse the run's own resolution — `resolve-address`
(`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3) plus the specs-dir matching feedback and
follow-ups already use. Record `prd` always and `epic` when the resolved kind is `epic`.

## 8. Persistence ladder (specs-first; never cwd)

Reuse `feedback-emission.md`'s specs-first ladder, targeting the **`cost/`**
subdir. Walk top-down; stop at the first tier that applies:

1. `$SPECS_PATH` writable **and** the PRD dir exists (matched by
   `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…`) ->
   `<PRD-dir>/dev-workflows/cost/<sid8>.md`. *[primary]*
2. `$SPECS_PATH` writable but no PRD dir (or no key resolved) -> **pending** (§9).
3. `source = directory` (a passed directory, no `$SPECS_PATH`) -> beside that
   directory.
4. Nothing resolvable -> **report-only** in the run output. **NEVER write into the
   current working directory** — it may be a code repo.

The run never fails, and **the checkpoint (§3) still advances in every tier** so
the next command's window is correct. A write that fails mid-write (read-only
mount / permission) drops to the next tier with the same notice.

## 9. Pending & reconciliation (keyless runs)

When no PRD key resolves (idea refinement, pre-PRD work), write the entry to a
pending file:

```
$SPECS_PATH/dev-workflows-cost/pending-<date>-<sid8>.md
```

(same `type: dev-workflows-cost` format; `prd: n/a`).

**Opportunistic suggest-and-confirm reconciliation.** Whenever any command
resolves a PRD key **and** pending files exist, the cost phase lists them (each
summarized by date / session / commands / total) and offers to relocate their
entries into `<PRD-dir>/dev-workflows/cost/<sid8>.md`:

- **Same-session `<sid8>` match is pre-selected** as the likely one -> the
  create-in-markdown -> keyed-command flow becomes
  effectively one tap.
- New-session pending files are listed for the user to pick.
- No match -> leave for manual relocation, or accept the partial loss.
- **Relocation moves, then DELETES.** On a confirmed relocation the pending
  file's entries are appended into `<PRD-dir>/dev-workflows/cost/<sid8>.md` and the
  **pending file is deleted** (move, not copy) so it never re-surfaces. Each
  pending file is relocated atomically; a failed/partial move leaves the file in
  place for a safe retry. Pending files the user *declines* are left in place and
  may be offered again next time (expected — the user chose not to file them).

This is the **only** interactive moment in the cost subsystem, and only when
pending files exist; the cost write itself is always silent.

## 10. Privacy

No user name is written to any cost file — filenames use `<sid8>`, not identity;
entries carry no author. The git commit author remains the only identity layer,
once the engineer commits and pushes the specs — outside this feature's control
and acceptable.

## 11. Caller contract — `emit-cost`

One entry point. Every caller supplies `command`, `phase`, `role` (or the
`inferred` marker — `/release-notes` and the four feedback commands), `key` (or
`null`), `source`, and `plugin_version`; the four feedback commands additionally
supply `target_command` — `/prompt` and `/feedback` directly, `/prompt-brainstorm`
and `/prompt-grill-me` through the §13 record a replay reads it from. `emit-cost` does the rest; it NEVER commits, NEVER writes
into a docs/code repo or the current working directory, and NEVER fails the
run. The cost entry is committed later, once, by the run's terminal
`commit-artifacts` step (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`
§4). Cost ALWAYS runs.

Inputs:
- `command` — the exact slash-command name (e.g. `/implement`,
  `/document (keyed mode)`, `/document (direct mode)`).
- `phase`, `role` — the §7 labels, or the `inferred` marker for the five
  commands §7 resolves. They resolve from **different** data, and each must
  therefore be given it:
  - `/release-notes` — resolved from `specification.md` / `design.md` presence
    under the PRD's specs dir. `emit-cost` reads that itself; nothing is passed.
  - The four feedback commands — resolved from `target_command`, which **cannot**
    be re-derived from disk (it lives in the run's own context). It is passed in:
    directly by `/prompt` and `/feedback`, and out of the §13.1 record for the two
    that deferred.
- `target_command` — **required when `command` is `/prompt` or `/feedback`.** The
  §7 **row name** of the command whose output is being corrected or remarked on, or
  `n/a`. Note this is the bare row name (`/document`), not the mode-qualified form
  the `command` field above uses (`/document (keyed mode)`) — a qualified value
  matches no row and would silently degrade to `plugin-feedback`/`n/a`. This is the same value the run writes as the feedback entry's `command:`
  field, so the two never disagree. Omitting it is a caller error: §7 has no other
  source for it, and the entry would silently fall back to
  `plugin-feedback`/`n/a`, quietly mis-attributing every correction.
- `key` (or `null`), `source` (`specs | directory | none`).
- `plugin_version` — read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
  (`python3 -c "import json;print(json.load(open('<path>'))['version'])"`).

Behavior:
1. Resolve session artifacts (§1) and the price table (§4).
2. Read the §13.1 deferred file, if any. Run `session-cost.py` (§2) with the
   checkpoint (§3), the snapshot (§5) when present, `--commands-dir`, and **one
   `--claim` per deferred record, oldest first**. With no deferred file this is
   the call it has always been and every step below is unchanged.
3. If `unmatched_claims` comes back non-empty, take §13.4 before writing
   anything.
4. Apply attribution (§7) to **this run**, whose spend is the returned remainder;
   build the per-invocation entry (§6); evaluate the §6.1 dominance trigger
   against the built entry and print its warning to the run output if it holds.
5. Resolve the target via the ladder (§8); on a keyless run write pending and run
   opportunistic reconciliation (§9).
6. Append the entry (create the file with frontmatter on first write), then
   append one entry per **matched claim** as §13.3 describes.
7. **Write `new_checkpoint` back (§3) in EVERY tier**, including pending /
   report-only, and delete the deferred file.
8. Return the persisted path (or the report-only notice) as the phase's output.

## 12. Maintainer checklist — onboarding a new model generation

A new model generation (e.g. a hypothetical Opus 4.9, or a new Sonnet minor)
touches **two** files that must change together. Skipping one is exactly the
omission that produced the stale "Opus 4.5-4.8" chain comment this reference
and `cost-prices.yaml:22` both used to carry:

1. `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §2 — add
   the new model id to the correct fallback chain (Opus / Sonnet), in
   priority order, ahead of the model(s) it supersedes.
2. `${CLAUDE_PLUGIN_ROOT}/references/cost-prices.yaml` — add a matching
   `models:` entry (`input`, `output`, `cache_read`, `cache_write_5m`,
   `cache_write_1h`, USD per million tokens, **permanent/standard rate only**
   — §4) keyed by the same undated model id, and update the chain-summary
   comment above the relevant block (e.g. "Opus 5 and Opus 4.6-4.8 all bill at
   $5 / $25") so it still lists every model actually in the chain.

Do (1) without (2) and the new model routes but prices as `unpriced-model`
every run — silently at first, loudly once §6.1's dominance warning fires. Do
(2) without (1) and the price table carries a dead key nothing ever routes to.
After editing either file, `grep` both for the new model id to confirm the
other was updated too.

## 13. Deferred attribution (a command that cedes the session)

Two commands — `/prompt-brainstorm` and `/prompt-grill-me` — hand control to
something else at their Phase 3 and never get it back. Neither can run a cost
phase after its own expensive work, because there is no "after" it controls.
This section is how their spend is measured anyway: **the run that cedes records
what it would have claimed; the next cost-emitting run in the session claims it
on that run's behalf.**

### 13.1 The intent file

A ceding command writes one record in its **Phase 2.5**, after Phase 2's
`commit-artifacts` and immediately before ceding:

```
~/.claude/dev-workflows/cost-state/deferred-<session_id>.json
```

A JSON array, appended to (a session may cede more than once), oldest first:

```json
{"command": "/prompt-grill-me", "phase": "inferred", "role": "inferred",
 "target_command": "/document", "key": "PRODUCT-1234", "source": "specs",
 "plugin_version": "3.16.0", "ceded_at": "2026-09-01T10:04:00Z"}
```

Every field has a consumer, and none is a measurement: `command` and
`plugin_version` build the entry (§6); `phase`/`role` are the `inferred` marker
§11 takes, resolved from `target_command` through §7 at replay time; `key` and
`source` choose the §8 tier; `ceded_at` becomes the replayed entry's `date` and
the timestamp in its `id`, which is what keeps two records replayed by one run
from colliding on §6's uniqueness rule.

Same home, lifetime and status as the §3 checkpoint beside it — **per-user,
per-session, transient, local, NEVER committed, and safe to delete.**

### 13.2 Where the window is cut

The boundary is not guessed and is not recorded by the ceding run: it is read out
of the transcript, which marks every slash-command invocation.
`session-cost.py --commands-dir <plugin>/commands` reports them as
`command_boundaries`. Three disciplines make that safe, and each exists because
its absence was a live defect:

- **Anchored to the envelope, not to one tag.** Claude Code writes the envelope
  in two orders — built-ins name-first (`<command-name>…`), plugin commands
  message-first (`<command-message>…<command-name>…`) — so a match anchored on
  `<command-name>` alone sees **no plugin command at all** and the feature is
  silently inert. Anchoring on either opener keeps the property that matters: the
  envelope must *start* the message, so the same marker text quoted inside prose
  or a pasted file is not an invocation.
- **Namespace resolved, never discarded.** A marker records what the user typed,
  bare (`/implement`) or namespaced (`/dev-workflows:implement`). The namespace is
  checked against this plugin's declared name from its own `plugin.json`; another
  installed plugin's `/superpowers:implement` is **not** a boundary. Stripping the
  namespace instead would invent one under a name this plugin never ran. This is
  `specs-repo-git.md` §3.5's `branch-key` discipline applied to a transcript.
- **Matched by name, never by position.** See §13.3.

`session-cost.py --selftest` covers each, paired with the broken implementation it
exists to catch.

### 13.3 The replay

`emit-cost` step 2 (§11). **No deferred file ⇒ nothing changes**; the nineteen
commands that measure themselves never take this path.

Otherwise the run passes one `--claim <command>` per deferred record, oldest
first, and the script partitions the window:

- Each claim is matched to a boundary **by name**, scanning forward. It gets
  exactly the segment from its own boundary to the **next boundary of any kind**.
- Everything else — including whole segments belonging to commands that emit no
  cost entry — stays in the **remainder**, which is this run's own spend, exactly
  as it would have been without any of this.

**Matching by name is the whole point, and positional pairing is the trap.** A
window routinely holds boundaries no claim corresponds to: `/vuln`, `/upgrade`,
`/docs-profile`, `/statusline` and the two guideline reviewers are real commands
that emit no cost entry, and an interrupted run leaves a boundary too. Pair the
k-th claim with the k-th boundary and a single `/vuln` in the window shifts every
claim by one — filing a security run's spend under a PRD lifecycle phase, which
is the exact misattribution this section exists to remove.

For each matched claim, build the entry (§6) from its segment, taking
`phase`/`role` by resolving that record's own `target_command` through §7, and
dating it `ceded_at` (§13.1). Append it through the §8 ladder using the record's
own `key` and `source` — which may differ from this run's.

**A deferred entry is committed by the run that replays it**, through that run's
own terminal `commit-artifacts`. The ceding run's `commit-artifacts` has long
since finished, which is why it could never have committed its own.

### 13.4 What this does not do

- **It never invents a boundary.** A claim matching no boundary comes back in
  `unmatched_claims`. Its entry is **not written** — nothing is guessed onto a
  neighbouring boundary — and its spend simply stays in the remainder, where it
  would have been anyway. The run reports one line naming the command whose
  attribution was lost, and the deferred file is still deleted: the checkpoint has
  advanced past that boundary, so no later run could ever match it, and leaving
  the file would re-print the same line every run for the rest of the session.
  Nothing is lost that was not already lost; only the attribution is.
- **It does not split Option B.** The statusline cross-check (§5) measures whole
  renders and cannot be apportioned, so a window carrying any claim omits
  `cost_statusline_usd` rather than over-reporting it against the remainder.
- **It does not rescue a session that ends there.** With no later cost-emitting
  command the spend stays in §3's post-last-command tail, unattributed — the same
  tail every command already has. A resumed session that starts a new transcript
  is this case: the new session has its own `deferred-<session_id>.json`, so the
  old record is never read again and is safe to delete.
- **It is not a general mechanism for skipping the cost phase.** A command that
  *can* measure itself must; deferral exists only for a run that provably cannot,
  and adding a third deferring command means showing that its Phase 3 cedes the
  session too.

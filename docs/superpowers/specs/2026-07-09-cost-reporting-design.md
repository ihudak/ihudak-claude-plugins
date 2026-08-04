---
tags: tasks-exclude
---

# Session Cost Reporting — Design

**Effort:** dev-workflows plugin — session cost reporting (+ `/statusline` installer)
**Target release:** v2.10.0
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Date:** 2026-07-09
**Status:** Shipped in dev-workflows v2.10.0 — pre-implementation design snapshot, kept as authored.

---

## 1. Goal

Know how many **dollars** a Value Increment (VI) cost across its whole lifecycle,
broken down by **phase**, **role**, and **model** — persisted per-VI into the
specs repo so the plugin maintainer can aggregate spend across every engineer and
team with Claude Code, the same way feedback is aggregated.

A VI's cost is the **sum of per-command cost lines** contributed by every session
that worked on it. Summing is a read-time concern for the maintainer; the plugin
only ever appends immutable per-invocation measurements.

## 2. Motivating workflow

A VI moves through owners and phases:

| Phase | Owner (role) | Commands |
|-------|--------------|----------|
| VI creation / refinement | PM | (future idea-refine, create-VI) + initial `/release-notes` on a bare VI |
| Spec / Epic refinement | PE | `/specify`, `/epics` |
| Planning | dev team | `/design` |
| Implementation | dev team | `/implement` |
| Documenting | dev team | `/document`, `/release-notes` |

Realities that shape the design:

- **Massive fan-out.** The largest VI to date was worked by **23 teams**. Many
  people, many sessions, all contributing cost lines to the same VI — under git,
  in the shared specs repo. **Merge-safety is a hard requirement**, or merges
  silently drop cost lines.
- **`/release-notes` runs twice, by two roles.** Jira refuses to mark a VI
  "ready" without release notes, so a PM runs `/release-notes` on a **bare VI**
  (no Epics/specs/design/code — even a placeholder note satisfies Jira) during VI
  creation; later a dev re-runs it with full context to produce real notes. Both
  are legitimate; cost must attribute each to the right phase/role.
- **Containers start clean.** The plugin is used mostly from AI containers whose
  working directory is the VI being worked. A session is not expected to mix VIs
  or unrelated chatter, so "the whole session's cost belongs to this VI" is a safe
  and useful simplification.

## 3. Data source & feasibility (verified)

Claude Code does **not** expose a dollar figure to a slash command. Verified
against a live 43 MB transcript:

- **No `costUSD` / `total_cost_usd` in the transcript.** The `$` a user sees in
  the statusline comes from Claude Code handing `.cost.total_cost_usd` on the
  **statusline script's stdin** — which a slash command cannot read.
- **Every assistant message carries `usage`** (`input_tokens`, `output_tokens`,
  `cache_read_input_tokens`, `cache_creation_input_tokens`, with a
  `cache_creation` split into `ephemeral_5m_input_tokens` /
  `ephemeral_1h_input_tokens`) **and its `model`**, plus a `timestamp`.
- **Subagent turns live in a sibling directory**, not the main transcript:

  ```
  ~/.claude/projects/<cwd-slug>/<session_id>.jsonl            ← orchestrator
  ~/.claude/projects/<cwd-slug>/<session_id>/subagents/agent-*.jsonl  ← subagents
  ```

  The `agent-*.jsonl` files carry Sonnet/other `usage` + `model`. Summing the
  main transcript **plus** the session's `subagents/*.jsonl` gives a complete,
  no-undercount cost and a clean per-model split for free.

**Conclusion.** Cost is **computed** from token usage × a price table. This is
self-contained (no statusline/hook dependency), captures subagents, and yields
the model-split and duration natively. Dollars are therefore an **estimate** that
can drift from Claude Code's own figure by the accuracy of the price table — an
accepted trade (cost accuracy is explicitly secondary to code/doc quality).

## 4. Architecture

Mirrors the existing self-contained emitter pattern
(`references/feedback-emission.md`, `references/followup-emission.md`):

- **`references/cost-emission.md`** — the single source of truth. Owns the
  chained-checkpoint model, the transcript-window computation, the price table
  reference, the report format, the persistence ladder, pending/reconciliation,
  and the optional statusline augmentation. Every command's cost phase cites this
  file and executes its steps inline.
- **`references/cost-prices.yaml`** (shipped, overridable) — per-model price
  table.
- **`scripts/session-cost.py`** — a deterministic helper the cost phase invokes:
  given a checkpoint (or none) it reads the transcripts, computes the delta by
  model, applies the price table, and returns a structured result. Pure
  computation; no writes to the specs repo.
- **One terminal cost phase per pipeline command** (single touchpoint, like
  feedback). No Phase-0 wiring, no change to any command's actual behavior.
- **`commands/statusline.md`** + a shipped copy of the statusline script — the
  `/statusline` installer (§13), whose shipped script also writes the snapshot
  that enables Option B.

## 5. Cost computation (primary — "Option A")

At a command's terminal cost phase:

1. **Resolve session artifacts.** Derive the `<cwd-slug>` from `cwd` per Claude
   Code's project-slug rule; the current session transcript is the
   newest `*.jsonl` under `~/.claude/projects/<cwd-slug>/`; its basename (minus
   `.jsonl`) is `session_id`; subagents are under
   `~/.claude/projects/<cwd-slug>/<session_id>/subagents/`.
2. **Load the checkpoint** for this `session_id` (§7). If none, the window starts
   at the session origin (start = $0).
3. **Compute the delta.** Read the main transcript **from the checkpoint's line
   offset forward** (O(command), not O(session) — the transcript is already tens
   of MB) plus every `subagents/agent-*.jsonl` entry with `timestamp` in
   `(checkpoint_ts, now]`. Group `usage` by `model`; apply the price table (§6).
4. **Duration** = `now_ts − checkpoint_ts` (seconds).
5. **Write the entry** (§9) and **advance the checkpoint** (§7).

Per-model output for each model touched in the window:
`cost_usd`, `input_tokens`, `output_tokens`, `cache_read_tokens`,
`cache_write_tokens` (5m + 1h combined for display; priced separately, §6).
`cost_computed_usd` = sum of per-model `cost_usd`.

Unknown model (not in the price table): record its tokens, set its `cost_usd:
null`, and add a `note: unpriced-model` — never fail the run.

## 6. Price table

`references/cost-prices.yaml`, keyed by model id, USD **per million tokens**:

```yaml
# Verify against current Anthropic pricing at implementation; override locally.
models:
  claude-opus-4-8:
    input: <verify>
    output: <verify>
    cache_read: <input * 0.1>
    cache_write_5m: <input * 1.25>
    cache_write_1h: <input * 2.0>
  claude-sonnet-5: { ... }
  claude-haiku-4-5-20251001: { ... }
default: null   # unknown model → unpriced (tokens recorded, cost null)
```

- Cache multipliers follow Anthropic's standard model (read 0.1×, 5m write 1.25×,
  1h write 2×); the transcript's `ephemeral_5m` / `ephemeral_1h` split lets cache
  pricing be exact.
- **Override:** `$DEV_WORKFLOWS_COST_PRICES` (path) or a repo-local
  `cost-prices.yaml`, else the shipped file. Exact dollar values are confirmed at
  implementation, not asserted here.

## 7. Chained-checkpoint model

Single touchpoint per command; a command's start = the previous dev-workflows
command's end in the same session.

- **Checkpoint file:** `~/.claude/dev-workflows/cost-state/<session_id>.json`
  (per-user, per-session, **transient/local — never committed**; safe to delete).
- **Contents:** cumulative token totals per model, the main-transcript line
  offset, `last_ts`, and the last statusline-snapshot value (for §8) — all
  captured at the *end* of the last cost phase.
- **First command in a session:** no checkpoint → start = session origin, cost
  counted from $0.
- **Semantics (documented for users):** the whole session's spend is attributed
  to the VI. Activity *between* commands rolls into the next command's bucket.
  The pre-first-command and post-last-command tails are unattributed (≈0 for a
  clean per-VI container session). Per-command costs therefore **sum to the
  session total** minus those tails.

## 8. Statusline augmentation (optional — "Option B")

Authoritative cross-check, available only when the plugin statusline is installed
(via `/statusline`, §13):

- The **shipped statusline writes a snapshot** each render:
  `~/.claude/dev-workflows/cost-snapshots/<session_id>.json` =
  `{ ts, cost_usd }` from its stdin `.cost.total_cost_usd`. (Two extra lines in
  the script; no visible change.)
- The cost phase records `cost_statusline_usd` = (current snapshot value) −
  (the snapshot value stored in the checkpoint) — a **per-invocation delta on
  this entry only**, chained identically to Option A. **Never an aggregate, never
  a shared source of truth** → immune to the merge concern.
- **Auto-detect:** if a snapshot file exists for the session, the field is
  emitted; otherwise it is simply absent. No configuration.
- **Boundary caveat (documented):** B is authoritative on price but lags at the
  tail (the statusline renders *after* the final turn); A reads the per-turn
  transcript so it is more complete at the boundary. The two differing by cents is
  the intended calibration signal (drift ⇒ refresh the price table).
- Pending a one-line implementation check that `.cost.total_cost_usd` is present
  on the statusline stdin in the target Claude Code version; if absent, B degrades
  to unavailable and A stands alone.

## 9. Report artifact & entry format

**Location (merge-safe by construction):** one file per session under the VI's
shared area:

```
<VI-dir>/dev-workflows/cost/<sid8>.md
```

`<sid8>` = first 8 chars of `session_id`. No two sessions share a file → no merge
conflicts across 23 teams or one person's N sessions. **No user name anywhere in
the file** (the git commit author is a separate, unavoidable layer — the file
content stays anonymous).

File-level frontmatter (written once):

```yaml
---
type: dev-workflows-cost
vi: PRODUCT-14902
session: <sid8>
---
```

One appended entry per command invocation (append-only, **never deduped** — each
invocation is a distinct measurement, so `/design Epic1` then `/design Epic2` in
one session are two lines):

````markdown
## 2026-07-09T14:22:33Z — /implement — implementation

```yaml
id: PRODUCT-14902-15001-implement-2026-07-09T14:22:33Z   # timestamp ⇒ unique
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
  - {model: claude-opus-4-8, cost_usd: 2.9114, input_tokens: 12043, output_tokens: 88210, cache_read_tokens: 2109887, cache_write_tokens: 145002}
  - {model: claude-sonnet-5, cost_usd: 0.5707, input_tokens: 45120, output_tokens: 210334, cache_read_tokens: 880122, cache_write_tokens: 42011}
```
````

Machine-friendly YAML so the maintainer can filter/sum with Claude Code. No prose
block (unlike feedback).

## 10. Attribution (phase / role / keys)

Fixed per-command labels, with one inferred exception:

| Command | phase | role |
|---------|-------|------|
| `/specify` | specification | pe |
| `/epics` | epic-refinement | pe |
| `/design` | planning | dev |
| `/implement` | implementation | dev |
| `/document` | documenting | dev |
| `/release-notes` | **inferred** | **inferred** |
| future idea-refine / create-VI | vi-creation | pm |

**`/release-notes` inference (PM VI-run vs. dev documenting-run):** the
discriminator is the presence of **downstream engineering artifacts** — any
`specification.md` or `design.md` under the VI's specs dir. **None present →
`phase: vi-creation`, `role: pm`** (the PM's early run: the VI exists but no
engineering work has started — Epics may or may not exist yet, which is fine,
since a freshly created VI with no Epics is exactly the PM case). **Present →
`phase: documenting`, `role: dev`** (the dev re-run, when VI + Epics + specs +
design + code all exist). **Epic presence is deliberately NOT part of the
signal** — a VI can have drafted Epics while still in PM/PE hands, so keying on
Epics would misattribute the PM run. Cheap to check; matches the real workflow.
Still a heuristic — reattributable at aggregation time (cost < quality).

**Keys:** reuse the existing VI-dir resolution (the two-key `<VI> <Epic>` grammar
+ specs-dir matching already used by feedback/followups). Record `vi` always and
`epic` when an Epic key is in scope.

## 11. Persistence ladder (specs-first; never cwd)

Reuse `feedback-emission.md`'s specs-first ladder, targeting the **cost/** subdir:

1. `$SPECS_PATH` writable + VI dir exists → `<VI-dir>/dev-workflows/cost/<sid8>.md`.
   *[primary]*
2. `$SPECS_PATH` writable, no VI dir (or no key) → **pending** (§12).
3. No `$SPECS_PATH`, vault writable → `$VAULT_PATH/dev-workflows/cost/<sid8>.md`
   with the loud "won't auto-aggregate" notice.
4. `source = directory` → beside the imported Jira dir.
5. Nothing resolvable → report-only in the run output. **Never write into cwd**
   (it may be a code repo). Never fail the run; the checkpoint still advances so
   the next command's window is correct.

## 12. Pending & reconciliation (keyless runs)

When no VI key resolves (idea refinement, pre-VI work), the entry is written to a
**pending file**:

```
$SPECS_PATH/dev-workflows-cost/pending-<date>-<sid8>.md
```

(same `type: dev-workflows-cost` format; `vi: n/a`).

**Opportunistic suggest-and-confirm reconciliation:** whenever any command
resolves a VI key **and** pending files exist, the cost phase lists them (each
summarized by date / session / commands / total) and offers to relocate their
entries into `<VI-dir>/dev-workflows/cost/<sid8>.md`:

- **Same-session `sid8` match is pre-selected** as the likely one → the
  create-in-markdown → create-in-Jira → import → keyed-command flow becomes
  effectively one tap.
- New-session pending files are listed for the user to pick.
- No match → leave for manual relocation, or accept the partial loss.
- **Relocation moves, then deletes.** On a confirmed relocation the pending
  file's entries are appended into `<VI-dir>/dev-workflows/cost/<sid8>.md` and the
  **pending file is deleted** (move, not copy) so it never re-surfaces. Each
  pending file is relocated atomically; a failed/partial move leaves the file in
  place for a safe retry. Pending files the user *declines* are left in place and
  may be offered again next time (expected — the user chose not to file them).

This is the **only** interactive moment in the cost subsystem, and only when
pending files exist; the cost write itself is always silent.

## 13. `/statusline` installer

Ship the user's statusline and make it one-command installable:

- **Resource:** vendor the script as
  `${CLAUDE_PLUGIN_ROOT}/scripts/statusline-command.sh` (includes the §8 snapshot
  write).
- **`commands/statusline.md`:** copy the script to a stable per-user path and
  write/merge the `statusLine` block into `~/.claude/settings.json`
  (`{ "type": "command", "command": "bash <path>" }`). **Idempotent**; **back up**
  any existing `statusLine` and existing script before overwriting; confirm before
  changing settings.
- Installing it **auto-enables Option B** (the snapshot write). Architecturally
  independent of cost reporting but shipped together (small, thematically linked).

## 14. Command wiring & scope

- **Terminal cost phase added to the 6 VI-lifecycle commands:** `/specify`,
  `/epics`, `/design`, `/implement`, `/document`, `/release-notes`. These map to
  the phases/roles in §10 and always resolve (or intend to resolve) a VI.
- **`/vuln` and `/upgrade` are out of scope.** They are CVE / dependency-upgrade
  sessions, not VI-lifecycle phases, so they have no VI to attribute cost to;
  wiring them would only produce keyless pending noise. The mechanism generalizes
  if VI-attributable cost for them is ever wanted.
- **Future commands** (idea-refine, create-VI) adopt the same terminal phase and
  the `pm / vi-creation` labels.
- **No behavior change** to any command; the cost phase is additive and never
  fails the run.
- **Untouched:** the `impl-maintenance` agent, `jira-reader`, reviewers,
  format references, and the sibling plugins (`dt-style-guide` 0.2.2,
  `obsidian-llm-wiki` 0.3.1).

## 15. Privacy

No user name is written to any cost file (filenames use `sid8`, not identity;
entries carry no author). The git commit author remains the only identity layer,
and only once the engineer commits the specs — outside this feature's control and
acceptable.

## 16. Non-goals

- Exact-to-the-cent billing (figures are price-table estimates).
- A real-time dashboard or live cost UI.
- Model-split for Option B (B is a single authoritative scalar).
- Deduplication of cost entries (every invocation is a distinct measurement).
- Aggregation/rollup logic in the plugin (summing is the maintainer's read-time
  job, done with Claude Code).
- Re-deriving cost when the price table is unknown for a model (record tokens,
  leave cost null).

## 17. Relationship to siblings

- **`feedback-emission.md` / `followup-emission.md`:** same `<VI-dir>/dev-workflows/`
  home and self-contained pattern. Cost diverges deliberately in two ways: a
  **`cost/` subdir with per-session files** (merge-safety under 23-team fan-out;
  feedback/followups stay single-file, being low-volume), and **no dedup / no
  prose** (pure measurement). No dedup or cross-reference between the three.
- **Latent merge risk in feedback/followups (out of scope, recorded).** They
  share the append-to-shared-file structure and carry the same conflict risk *in
  principle*, but at far lower volume (feedback is deduped and only on a
  plugin-facing signal; followups only on out-of-scope findings). Not worth
  rewriting two shipped subsystems here. If conflicts ever bite, two cheap fixes
  that do **not** touch them: (a) a specs-repo `.gitattributes` entry
  `dev-workflows/**/*.md merge=union` (append-friendly merges — a maintainer ops
  change, not a plugin change); (b) migrate them to per-session files in a small
  separate follow-up.
- **`impl-maintenance`:** untouched; cost does not use it.

## 18. Resolved decisions

- **D1 — cost source:** Option A (compute from transcript) is primary and
  universal; Option B (statusline snapshot) is an auto-detected per-invocation
  augmentation field. Both on the same entry; B is never an aggregate.
- **D2 — home:** reuse VI-dir resolution; `cost/<sid8>.md` under it.
- **D3 — phase/role:** fixed per-command map (§10).
- **D4 — `/release-notes`:** already VI-level (no command change); phase/role
  inferred from artifact presence.
- **D5 — keyless:** pending dir + opportunistic suggest-and-confirm reconciliation
  (same-session pre-selected).
- **D6 — format:** append-only YAML entries, never dedup, no user name.
- **D7 — `/statusline`:** shipped installer; enables B.
- **Refinement 1 (23 teams):** per-session files → merge-safe; every field
  per-invocation, totals computed at read time.
- **Refinement 2 (first = $0):** chained checkpoint, single touchpoint; whole
  session attributed to the VI.

## 19. Release surfaces (v2.10.0)

- `plugins/dev-workflows/.claude-plugin/plugin.json` → `2.10.0`.
- Root `.claude-plugin/marketplace.json` dev-workflows entry → `2.10.0` +
  description (new `/statusline` command; command count updated). Siblings
  byte-identical.
- `CHANGELOG.md` → `## [2.10.0] — 2026-07-09` prepended (history preserved).
- `plugins/dev-workflows/README.md` → new "Session cost reporting" + "Statusline"
  sections; reference the new files.
- Root README untouched.

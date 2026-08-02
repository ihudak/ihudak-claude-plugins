---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# dev-workflows — Monotonic phase renumber (Effort B1b) (design)

## Context

The command-surface redesign (B1, v2.0.0) left one deferred cleanup: the
`document.md` Jira-mode (Mode A) phase cluster is non-monotonic **and** its
physical order doesn't match execution order. Physical order today:

`5.9 → 6.2 (CDN) → 6 (Write) → 6.5 (Branch setup) → 6.7 (Style) → 6.8 (Render) → 7`

Two compounding problems: (1) numerically non-monotonic (`6.2` before `6` before
`6.5`); (2) **Branch setup (`6.5`) sits physically after Write (`6`) but executes
before it** — papered over by an "execution order with Phase 6.5" note in Write.

This effort makes **physical = numeric = execution** by moving the Branch-setup
block before Write and renumbering the cluster monotonically, then deletes the
apology note. It also tidies the one odd number in `epics.md`. Purely cosmetic —
**no behavior change** (identical steps, only renumbered/reordered for
readability).

Plugin `main` at `2331622` (v2.0.0). Release: **PATCH `v2.0.1`**.

## Goals

- `document.md` Mode A: reorder + renumber the 6.x cluster to execution order;
  delete the redundant execution-order note.
- `epics.md`: renumber the leftover `6.7` style phase → `6.1` (cosmetic; epics is
  not inverted, so no reorder).
- Sweep every cross-reference to a renumbered phase (in `document.md`, `epics.md`,
  the agents, and the references) — **per-site**, because bare "Phase 6" is
  ambiguous.
- PATCH release `v2.0.1`.

## Non-goals

- **Effort B2** (the shared JiraID-or-directory discovery front-end).
- Any behavior change — the phases' content is untouched; only headings/order/
  cross-refs change.
- Touching Mode B (direct edit) phases, or `/implement`/`/vuln`/`/upgrade` phases
  (no inversion there).

## Design

### A. `document.md` Mode A — reorder + renumber

Target (execution order):

| Phase | Old → New |
|-------|-----------|
| CDN image handoff | `6.2` → **`6.1`** |
| Branch setup *(move the block to before Write)* | `6.5` → **`6.2`** |
| Write documentation | `6` → **`6.3`** |
| Style check | `6.7` → **`6.4`** |
| Render verification | `6.8` → **`6.5`** |

- Phases `0`–`5.9`, `7`, `8`, `8.5`, `9` are **unchanged**.
- Physically relocate the entire `## Phase 6.5 — Branch setup (conditional)`
  section (a self-contained block) to sit **between** CDN (new `6.1`) and Write
  (new `6.3`) — i.e. immediately before `## Phase 6.3 — Write documentation`.
- **Delete the execution-order apology note** at the top of Write (the
  "Phase 6.5 runs *before* this phase / follow execution order not numeric order"
  paragraph) — physical = numeric = execution makes it redundant. Keep the actual
  branch/commit semantics (orchestrator commits the writer's output) intact, just
  without the ordering caveat.

### B. `epics.md` — tidy

Renumber `## Phase 6.7 — Dynatrace style check` → **`## Phase 6.1 — Dynatrace
style check`**. epics' order (`6` Write → `6.1` Style → `7` Review) is already
monotonic + execution-ordered; this only removes the odd `6.7` leftover. No
reorder. **epics' Phase 6 (Write) stays `6`** — it is not part of the docs
cluster.

### C. Cross-reference sweep (per-site)

Phase-number references to renumbered phases live across the plugin. Procedure:

1. **Enumerate first:** `grep -rnE 'Phase [0-9]' plugins/dev-workflows` — the full
   site list (commands, agents, references). Known reference carriers: the
   `document.md` Phase 9 report section + invariants; the agents `doc-writer` /
   `epic-writer` / `doc-reviewer` / `docs-style-checker` (name Phase 6.5/6.7/6.8/
   3.5/etc.); the references `multi-space-writing.md` / `render-verification.md`
   (Phase 6.8) / `finish-and-handoff.md` (Phase 6.5/8.5).
2. **Map per-site** with the §A table. **"Phase 6" bare is ambiguous** — in
   `document.md`/docs context it is the Write phase → `6.3`; in `epics.md` context
   it is epics' Write phase and **stays `6`**. Never blind-replace "Phase 6".
   `Phase 6.2`→`6.1`, `Phase 6.5`→`6.2`, `Phase 6.7`(docs)→`6.4`, `Phase 6.8`→`6.5`;
   `Phase 6.7`(epics)→`6.1`. All `Phase 5.x`, `Phase 7/8/8.5/9`, and Mode-B/`/epics`
   non-cluster phases are **unchanged**.
3. **Completion gate (clean, objective):** `Phase 6.7` and `Phase 6.8` are
   **fully retired** by this renumber (6.7 → 6.4 docs / 6.1 epics; 6.8 → 6.5), so
   `grep -rn 'Phase 6\.7\|Phase 6\.8' plugins/dev-workflows` must return **EMPTY**.
   That is the unambiguous gate. The reused numbers `Phase 6.2` (now Branch) and
   `Phase 6.5` (now Render) and bare `Phase 6` (docs Write → 6.3, but epics Write
   legitimately **stays** 6) cannot gate to empty — the implementer reads each of
   those surviving hits to confirm it carries the NEW meaning (or epics-Write).

### D. Release

PATCH **`v2.0.1`** — `plugin.json` top-level `version`; `marketplace.json`
`plugins[0].version`; `CHANGELOG.md` `## [2.0.1]` entry (em-dash date) noting the
internal phase renumber (no behavior change).

## Touch list

- `commands/document.md` — reorder the Branch-setup block, renumber the 5
  cluster phases + their in-file cross-refs, delete the execution-order note.
- `commands/epics.md` — `6.7`→`6.1` + any in-file ref.
- Agents that name renumbered phases (`doc-writer`, `epic-writer`, `doc-reviewer`,
  `docs-style-checker`, others surfaced by the enumerate grep).
- References that name renumbered phases (`multi-space-writing.md`,
  `render-verification.md`, `finish-and-handoff.md`, others surfaced).
- Manifests + CHANGELOG (`v2.0.1`).

~3 plan tasks (structural verification): (1) document.md reorder+renumber+note;
(2) the per-site cross-ref sweep across epics/agents/references; (3) release.

## Risks & mitigations

- **Per-site cross-ref sweep** (bare "Phase 6" ambiguity; docs vs epics). The
  dominant risk. Mitigation: enumerate-first + per-site mapping (never blind
  replace) + the completion re-grep with a human read of each surviving hit.
- **Block move** of Branch-setup. Well-bounded (a self-contained `## Phase`
  section); verify the moved block is intact + sits between CDN and Write, and
  that the orchestrator-commits-after-writer semantics still read correctly in the
  new order.
- **Behavior:** none — the steps are byte-identical, only headings/order/refs
  change. The render/commit/review gates are untouched.

## Invariants preserved

- Zero behavior change; zero external API; the v2.0.0 command surface, the writer
  subagents, model routing (§9), and escalation-rules are all untouched.
- Mode B, `/implement`, `/vuln`, `/upgrade`, and all non-cluster phases keep their
  numbers.

## Open items (confirm during spec review)

- None — the reorder+renumber (full fix), the target map, the epics tidy, and the
  per-site sweep are settled. (B2 — the discovery front-end — remains deferred.)

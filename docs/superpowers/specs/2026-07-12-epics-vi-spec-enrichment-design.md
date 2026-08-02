---
tags:
  - tasks-exclude
---

# `/epics` VI-level-spec requirement enrichment — design (v2.23.0)

**Status:** approved-for-planning
**Date:** 2026-07-12
**Plugin:** dev-workflows (repo `/workspace/ihudak-claude-plugins`)
**Version:** 2.22.0 → **2.23.0** (minor; feature, no new command/agent)
**Counts:** unchanged — Nineteen slash commands / Twenty-nine reusable subagents

## 1. Goal

Close the last v2.21.0 follow-up (**Cluster B, #4**): when a VI-level
`specification.md` exists at `/epics` time, fold its `[Uxx]`/`[ACxx]`
requirements into the `/epics` coverage inventory as extra, clearly-tagged rows,
so the coverage matrix reflects the richer spec-level requirements when a team
has authored a VI-level broad spec. Strictly additive and **zero-cost when
absent** (the common case).

## 2. Motivation & grounding

- The v2.21.0 coverage matrix builds its inventory from `jira-reader`'s
  `requirements[]` (the VI's native `US-N`/`AC-N`/`SM-N`/`FR-N`/`UC-N`). A
  VI-level `specification.md` (authored by `/specify <VI>`) is a richer,
  EARS-patterned source that may capture requirements the raw VI omitted.
- **Grounding that shaped the reframe** (from `references/specification-format.md`):
  - `[TCxx]` test-case numbering **restarts per AC** → not globally unique, and
    below Epic-partition granularity. **Excluded** — we fold only the
    story/AC-level items.
  - The spec's IDs (`[Uxx]`/`[ACxx]`) differ from the VI's (`US-N`/`AC-N`); the
    spec elaborates the VI, so some rows overlap in meaning.
  - A VI-level spec **rarely exists at `/epics` time** (`/specify` usually runs
    per-Epic *after* `/epics`), so this enrichment seldom fires — harmless when
    absent, useful when present.
- `/epics` already resolves the VI dir (`$SPECS_PATH/specifications/<VI>-<vslug>/`)
  for the ARD Phase 2.5 (v2.21.0) — so detecting `specification.md` needs no new
  plumbing beyond the same one-line key-number match.

## 3. Scope

### In scope
1. New **Phase 2.6 — VI-level spec enrichment (optional)** in `commands/epics.md`.
2. Merge of the spec's `[Uxx]`/`[ACxx]` into the carried `requirements[]`
   (Phase 3), tagged `type: spec-story` / `spec-criterion`.
3. One-line `epic-writer` touch: note "+ VI-level spec" on the `_coverage.md`
   `_source:` line when any `spec-*` row is present.
4. One-line `epic-reviewer` clarification: its requirement-coverage dimension
   may see `spec-story`/`spec-criterion` rows sourced from a VI-level spec — it
   treats them identically to VI requirements (disambiguation, not a behavior
   change).
5. Manifest version bump + CHANGELOG.

### Out of scope
- `[TCxx]` test cases (per-AC, non-unique, below Epic granularity).
- Any `jira-reader` change (stays jira-products-only).
- Any `vi-reviewer` change (that's `/create-vi`'s reviewer; irrelevant here).
- Any `epic-reviewer` behavior change — spec rows are handled by its existing
  requirement-coverage dimension.
- Fuzzy dedup between the spec's `[Uxx]`/`[ACxx]` and the VI's `US-N`/`AC-N`
  (expensive/unreliable; both appear, distinguished by `type`).

## 4. Detection & parse (new Phase 2.6)

Insert **`## Phase 2.6 — VI-level spec enrichment (optional)`** immediately after
Phase 2.5 (ARD).

- **Resolve the VI dir:** `$SPECS_PATH/specifications/<VI>-<vslug>/`, matched by
  key-number, tolerating a stray `-`/`_` and a human-adjusted slug (the same rule
  `ard-resolution.md` step 1 uses). If `$SPECS_PATH` is unset/unresolvable → skip.
- **Detect:** if `<VI-dir>/specification.md` does not exist → skip (set
  `vi_spec_present: false`; the run proceeds byte-identically to today).
- **Parse (orchestrator, inline — one file, simple heading scan):** extract the
  spec's user stories `[Uxx]` (title/text) and their nested acceptance criteria
  `[ACxx]` (text) into `vi_spec_requirements[]`:
  ```yaml
  vi_spec_requirements:
    - id:   <Uxx | ACxx>          # the spec's own id, preserved verbatim
      type: spec-story | spec-criterion
      text: <requirement text>
  ```
  **Skip `[TCxx]`** and the prose sections (Problem/Scope). Set
  `vi_spec_present: true` and record the resolved `specification.md` path for the
  Phase 9 report.

## 5. Merge (Phase 3)

After `jira-reader` returns `requirements[]` (carried in Phase 3), **append**
`vi_spec_requirements[]` to it. The VI's own rows are unchanged; the appended
rows carry `type: spec-story` / `spec-criterion`, which visually separates them
from the VI's `story`/`criterion` rows. The merged `requirements[]` then flows
through the **existing** Phase 6 handoff and Phase 7 reviewer brief with no
shape change — both already receive `requirements[]`.

When `vi_spec_present: false`, `requirements[]` is exactly what `jira-reader`
returned — no change.

## 6. Rendering (`epic-writer` `_coverage.md`)

The v2.21.0 `_coverage.md` table already has a `Type` column populated from each
requirement's `type`, so the `spec-story` / `spec-criterion` rows render in the
existing table with no new column and no structural change.

**One-line writer touch:** when any `spec-*` row is present in the handoff
`requirements[]`, append `+ VI-level spec` to the `_source:` line, e.g.
`_source: native + VI-level spec_`. When none are present, the line is unchanged
(`_source: native_` / `_source: derived_`).

The roll-up verdict + coverage % count **all** rows (VI + spec) uniformly.

## 7. Coverage review (`epic-reviewer`) — one-line clarification

`epic-reviewer`'s requirement-coverage dimension already checks every row in the
passed `requirements[]` and flags an uncovered requirement as **MAJOR**. A
`spec-*` row is just another row — an uncovered spec requirement is a MAJOR gap,
same as a VI requirement. No severity or method change.

The dimension's v2.21.0 wording ("every **VI** requirement") could be
misread as excluding the new rows, so add **one clarifying clause**: the
requirement-coverage dimension states that `requirements[]` may include
`spec-story` / `spec-criterion` rows sourced from a VI-level spec and are
checked identically. This is disambiguation only — the operational check
(every `requirements[]` row / every `❌ gap` in `_coverage.md`) is unchanged.

## 8. No-regression

- No `$SPECS_PATH` / no VI dir / no `specification.md` (the normal case) ⇒
  Phase 2.6 is a silent no-op, `requirements[]` unchanged ⇒ byte-identical run.
- The `epic-writer` `_source:` touch only fires when a `spec-*` row exists; with
  none, `_coverage.md` is byte-identical to v2.21.0.
- `jira-reader`, `vi-reviewer`, `/vuln`, `/upgrade`, and both sibling plugins
  (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched; `epic-reviewer`
  gets only the one-line coverage-dimension clarification (behavior unchanged).
  Command/agent counts unchanged (19/29); marketplace description strings
  byte-identical.
- `/epics` still never branches, never commits, never writes into
  `jira-products/`, `jira_export_root`, or the cwd.

## 9. Verification (structural — no test framework)

- `python3 -c json.load` parses both manifests; version `2.23.0` in
  `plugin.json` + the `dev-workflows` `marketplace.json` entry.
- grep anchors in `epics.md`: `Phase 2.6 — VI-level spec enrichment`,
  `vi_spec_requirements`, `spec-story`, `spec-criterion`, `vi_spec_present`,
  the append-to-`requirements[]` merge step, the Phase 9 report line naming the
  resolved `specification.md` path.
- grep anchor in `epic-writer.md`: the `+ VI-level spec` `_source:` clause.
- grep anchor in `epic-reviewer.md`: the `spec-story` / `spec-criterion`
  coverage-dimension clarification clause.
- `git diff --stat main` shows only: `commands/epics.md`, `agents/epic-writer.md`,
  `agents/epic-reviewer.md`, `plugin.json`, `marketplace.json`, `CHANGELOG.md`.
  `agents/jira-reader.md`, `agents/vi-reviewer.md`, `/vuln`, `/upgrade`, and both
  sibling plugins show **no** diff.
- CHANGELOG prepends `## [2.23.0] — 2026-07-12`.

## 10. Files changed

- `commands/epics.md` — new Phase 2.6; the Phase 3 merge; a Phase 9 report line.
- `agents/epic-writer.md` — the one-line `_source:` "+ VI-level spec" clause.
- `agents/epic-reviewer.md` — the one-line coverage-dimension clarification.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — 2.23.0.
- `CHANGELOG.md` — 2.23.0 entry.

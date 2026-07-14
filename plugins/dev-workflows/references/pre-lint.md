# Structural pre-lint (embedded — shared reference)

Deterministic, grep-expressible structural checks the reviewer-gated commands run against a
just-authored artifact **before** dispatching their Opus reviewer — so an Opus review pass is not
consumed BLOCKing on mechanical structure. **Advisory:** surface findings, inline-fix the mechanical
ones, leave content gaps for the author, then proceed to the reviewer. Pre-lint **never hard-stops**
on its own; the reviewer remains the gate.

Each caller cites this file, states its **artifact type** and the **file(s)** to check, runs the
Universal checks plus its artifact-specific block, and surfaces the findings. Severities: **BLOCKER**
(missing required section, duplicate ID, stray generic placeholder), **MAJOR** (a structural rule
broken), **MINOR** (ID gap, informational count). Inline-fix only the mechanical (renumber a duplicate
ID, delete a stray placeholder token); anything needing content goes back to the author/grill.

## Universal checks (every artifact)

1. **Placeholder scan** — `grep -nE '\b(TBD|TODO|FIXME|XXX)\b|<[a-z][a-z0-9 _./-]*>' <file>`. Any hit →
   BLOCKER (a shipped artifact carries no placeholder). Does NOT flag `[NEEDS CLARIFICATION]` or
   `- [ ]` open questions — those are counted per-artifact below.
2. **Identifier integrity** — for each ID series the artifact uses (below), the numbers form a
   contiguous run from the scheme's base with no duplicates. A duplicate → BLOCKER; a gap → MINOR.
3. **Required-section presence** — every mandatory heading listed for the artifact is present
   (`grep -nF '## <heading>' <file>`). A missing required heading → BLOCKER.

## VI — `<KEY>_ValueIncrement.md` (`/create-vi`; format `vi-format.md`)

- Required headings: `## Problem`, `## Goal`, `## Target audience`, `## User Stories`,
  `## Acceptance Criteria`, `## Scope`, `## Success Metrics`.
- ID series: `[US-N]` (in `### [US-N]:` headings), `[AC-N]`, `[SM-N]` — each contiguous from 1.
- Report the count of `[NEEDS CLARIFICATION]` (a relentless-grilled VI should converge to 0; >0 → MINOR).

## ARD — `*_ARD.md` (`/create-ard`; format `ard-format.md`)

- Required headings: `## Context`, `## Grounding findings (architecture as-is)`,
  `## Architecture decisions`, `## Cross-repo / component approach`, `## Stack & invariants`,
  `## Edge cases & risks`, `## Open questions`, `## Deferred`.
- ID series: `[AD-N]` (in `### [AD-N]:` headings) — contiguous, no dupes.
- Each `### [AD-N]` block carries all three sub-fields `**Binds:**`, `**Prevents:**`, `**Rule:**`
  (a missing one → MAJOR).

## spec — `specification.md` (`/specify`; format `specification-format.md`)

- Required headings: `## Problem statement`, `## Scope`, `## User stories`; header fields
  `- **Published**:` and `- **Open questions**:`.
- ID series: `[Uxx]` (in `### [Uxx]:`) contiguous document-wide; `[ACxx]` (in `#### [ACxx]:`)
  contiguous within each story; `[TCxx]` (in `**[TCxx]:`) contiguous within each AC.
- **Open-questions header consistency:** the integer in `- **Open questions**: N` must equal the
  count of `- [ ]` items in the file (`grep -cE '^[[:space:]]*- \[ \]' <file>`). Mismatch → MAJOR.

## Epic — per-Epic file (`/epics`; template in `${CLAUDE_PLUGIN_ROOT}/agents/epic-writer.md`, NOT a `*-format.md` doc)

- Required headings per Epic file: `## Goal`, `## Business value`, `## Scope`, `### In scope`,
  `### Out of scope`, `## Acceptance criteria`, `## Independent Test`, `## Dependencies`, `## Covers`,
  `## Suggested stories`, `## References`.
- Acceptance criteria are Given/When/Then bullets (`grep -nE '^- Given .*, when .*, then ' <file>`;
  a `## Acceptance criteria` section with zero G/W/T bullets → MAJOR).
- `[NEEDS CLARIFICATION]` count ≤ 3 per Epic (epic-writer cap; >3 → MAJOR).
- `## Covers` references parent-VI IDs (`US-N`/`AC-N`/`SM-N`); Epics do not mint their own criterion IDs.
- A `_coverage.md` file is present in the output dir.
- Refined Epic files (keyed `<EPIC-KEY>.md`, from `/epics` refinement mode) carry a `**Team:**` line
  (`grep -nE '^\*\*Team:\*\*' <file>`) and a `## Scope` with real in/out bullets (not just the summary).

## design — `design.md` (`/design`; format `design-format.md`)

- Required (core) headings: `## Context & problem`, `## Requirements coverage`,
  `## Architecture & components`, `## Interfaces / contracts`, `## Test strategy`, `## Out of scope`,
  `## Open questions`; header field `- **Open questions**:`.
- Scaled sections `## Seams`, `## Data flow`, `## Error handling & edge cases`, `## Risks & mitigations`,
  `## Migration / rollout / backward-compatibility` are present for MODERATE+ **or** replaced by a
  one-line `_N/A — <why>_`; a MODERATE+ design missing `## Seams` with no `_N/A_` → MAJOR.
- Report the `- [ ]` count under `## Open questions` (design-format requires 0 to hand off — the
  design-reviewer enforces the hard block; pre-lint only reports it).

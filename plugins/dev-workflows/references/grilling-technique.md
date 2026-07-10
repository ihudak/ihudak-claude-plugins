# Grilling technique (embedded — shared reference)

The interview technique the authoring commands (`/idea`, `/create-vi`, `/specify`, `/design`) use to
refine an artifact one decision at a time. Embedded here so callers have **no runtime dependency**;
technique adapted from mattpocock grill-me/grilling. Each caller cites this file and states its own
**depth** and **stage list**; this reference owns only the mechanics.

## Mechanics

- Ask exactly **ONE** question at a time; wait for the answer before the next. Never batch — a firehose is bewildering.
- For every question, give your **recommended answer**, so the user reacts to a proposal, not a blank prompt.
- **Fact-vs-decision split:** if a question can be answered from the artifact, code, or context, explore and answer it yourself; put only genuine **decisions** to the user.
- **Walk the design tree in dependency order** — resolve a parent decision before the choices that depend on it.
- Continue until you and the user reach a **shared understanding** for the current section, then write that section.

## Depth (the caller chooses)

- **Bounded** — a capped set of the highest Impact×Uncertainty questions, then stop; unresolved high-impact gaps are recorded (e.g. `[NEEDS CLARIFICATION]`). Used by `/idea` (≤5; `--deep` switches to relentless).
- **Relentless** — keep walking the tree until convergence, no cap. Used by `/create-vi`, `/specify`, `/design`.

If `mattpocock-skills` `/grilling` is installed the user may invoke it directly (see
`${CLAUDE_PLUGIN_ROOT}/references/dependencies.md`); it is **not** a runtime dependency.

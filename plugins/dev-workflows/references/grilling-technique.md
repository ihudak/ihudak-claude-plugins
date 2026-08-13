# Grilling technique (embedded — shared reference)

The interview technique the authoring commands (`/idea`, `/create-vi`, `/specify`, `/design`) use to
refine an artifact one decision at a time. Embedded here so callers have **no runtime dependency**;
technique adapted from mattpocock grill-me/grilling. Each caller cites this file and states its own
**depth** and **stage list**; this reference owns only the mechanics.

## Mechanics

- Ask exactly **ONE** question at a time; wait for the answer before the next. Never batch — a firehose is bewildering.
- For every question, give your **recommended answer**, so the user reacts to a proposal, not a blank prompt.
- **Fact-vs-decision split:** if a question can be answered from the artifact, code, or context, explore and answer it yourself; put only genuine **decisions** to the user.
- **Force terminology precision.** When a term is overloaded or fuzzy (e.g. "user" vs. "buyer" vs. "payer"; "enable" vs. "install"), name the ambiguity and make the user pick a precise meaning before building on it.
- **Walk the decision tree in dependency order** — resolve a parent decision before the choices that depend on it.
- Continue until you and the user reach a **shared understanding** for the current section, then write that section.

## Autonomous / background invocation

When the command runs with **no human turn available** to answer (autonomous or background
invocation), do NOT fabricate answers to genuine **decision** questions. The fact-vs-decision split
still holds — facts you resolve yourself — but a genuine decision that would otherwise go to the user
is **recorded as an open question** (`[NEEDS CLARIFICATION]` for bounded callers, `- [ ]` for relentless
callers) rather than self-answered. Never grill yourself into a fabricated decision.

## Depth (the caller chooses)

- **Bounded** — a capped set of the highest Impact×Uncertainty questions, then stop; unresolved high-impact gaps are recorded (e.g. `[NEEDS CLARIFICATION]`). Used by `/idea` (≤10; `--deep` switches to relentless) and `/prompt-grill-me` (≤5).
- **Relentless** — keep walking the tree until convergence, no cap. Used by `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`.

## Ambiguity taxonomy (gap-categories, altitude-aware)

Categories the grill scans to *find* gaps — they feed the existing **Impact × Uncertainty** ranking of what to ask. This is **not** a user-facing menu and adds **no** mandatory questions: bounded callers still cap at ≤10; relentless callers still stop at convergence. Scale the categories to the caller's altitude:

- **All altitudes:** overloaded/fuzzy **terminology**; **pre-mortem / assumption audit** (which unstated assumption, if wrong, breaks this?); **second-order effects** (what does this change downstream?).
- **Product altitude** (`/idea`, `/create-vi`): unstated **quality expectations** (implied latency, scale, availability, or compliance expectations) framed as product outcomes — not engineering NFRs.
- **Engineering altitude** (`/specify`, `/design`): the full **NFR** set (performance, scalability, reliability, observability, security/compliance); **integration / external-dependency** gaps; **implicit enum branch** (a field with N values where only some are specified — the rest are an untested branch).

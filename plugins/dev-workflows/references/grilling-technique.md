# Grilling technique (embedded — shared reference)

The interview technique the authoring commands (`/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/design`), `/brd-split` and `/prompt-grill-me` use to
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

## Relationship to the upstream technique it was adapted from

**This file is a fork, not a copy, and the fork is deliberate.** The technique is adapted from
mattpocock's `grill-me` / `grilling`, which now ships as a skill in the official marketplace
(`mattpocock-skills:grilling`). **It is not a drop-in replacement for this file**, and a future
reader who notices it there should read this section before proposing the swap.

**Where the two diverge, and which way to jump:**

| | Upstream | Here |
|---|---|---|
| Question cadence | **Batched**: computes a *frontier* of decisions whose prerequisites are settled and asks the whole frontier in one numbered round | **One at a time**, never batched (Mechanics, above) |
| Depth | Relentless by construction — done when the frontier is empty | **Two depths, caller-declared** (below), three of eight callers bounded |
| No human turn available | Not addressed — the model assumes somebody answering rounds | Recorded as an open question, never self-answered (above) |
| Altitude | One conversation, one altitude | Gap categories scale to the caller's altitude (below) |

**The three rows below the first are why this file exists**, and they are not improvements on the
technique — they are **caller management** upstream has no reason to carry. This plugin invokes the
same technique from eight commands at three depths, one of which may run with no human turn
available at all. A single-context skill has nothing to say about a `≤5` cap, about what to write
when nobody is there to answer, or about the difference between a product-altitude quality
expectation and an engineering NFR.

**The first row is a genuine disagreement, and upstream may well have the better of it** for the
relentless callers: numbering the round and attaching a recommended answer to each question answers
this file's own "a firehose is bewildering" objection, and it costs fewer round-trips on a long
grill. It is not adopted because `commands/brd-split.md`'s ledger walk — the one caller that is both
a grilling caller and a never-batch caller — presents rows one at a time by its own rule, and
because a cadence that differs by caller is worse than one that is merely debatable.

**Adopting it wholesale would also cost the plugin its self-containment.**
`references/dependencies.md` states that no command hard-requires another plugin, because
`plugin.json` cannot express a dependency; a missing companion must degrade a feature, never break a
run. Grilling is **mid-run in eight commands**, which is a different risk from
`/prompt-brainstorm`'s single terminal hand-off to `superpowers:brainstorming`.

**Read upstream for ideas, not for parity.** Where it is sharper — its *frontier* framing for
dependency order, its rendered question format, its rule that a fact is fetched rather than asked —
port the idea into this file deliberately and record it here. Do not cite it at runtime.

## Depth (the caller chooses)

- **Bounded** — a capped set of the highest Impact×Uncertainty questions, then stop; unresolved high-impact gaps are recorded (e.g. `[NEEDS CLARIFICATION]`). Used by `/idea` (≤10; `--deep` switches to relentless), `/prompt-grill-me` (≤5) and `/brd-split` (≤5, and only when given a slicing instruction).
  **A bounded caller states what its cap costs, because that is what sizes it.** For `/idea` an unresolved gap becomes a marker inside the shipped artifact, so a low cap leaves a hole and ≤10 earns its length. For `/brd-split` an unplaced row simply reaches its own ledger walk without a recommendation, in a walk that visits every row anyway — the residue has a free fallback, so its cap is lower and its questions carry a further gate of the caller's own (`commands/brd-split.md` Phase 1.5: ask only where one answer places more than one row). Neither the extra gate nor the differing numbers are this file's to fix; what this file fixes is that a caller declaring **bounded** owes a stated cap rather than an open-ended interview called capped.
- **Relentless** — keep walking the tree until convergence, no cap. Used by `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/design`.

## Ambiguity taxonomy (gap-categories, altitude-aware)

Categories the grill scans to *find* gaps — they feed the existing **Impact × Uncertainty** ranking of what to ask. This is **not** a user-facing menu and adds **no** mandatory questions: bounded callers still cap at their stated bound; relentless callers still stop at convergence. Scale the categories to the caller's altitude:

- **All altitudes:** overloaded/fuzzy **terminology**; **pre-mortem / assumption audit** (which unstated assumption, if wrong, breaks this?); **second-order effects** (what does this change downstream?).
- **Product altitude** (`/idea`, `/create-prd`): unstated **quality expectations** (implied latency, scale, availability, or compliance expectations) framed as product outcomes — not engineering NFRs.
- **Engineering altitude** (`/specify`, `/design`): the full **NFR** set (performance, scalability, reliability, observability, security/compliance); **integration / external-dependency** gaps; **implicit enum branch** (a field with N values where only some are specified — the rest are an untested branch).

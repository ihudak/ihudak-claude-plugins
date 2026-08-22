# Design format (embedded authority)

The canonical structure and per-section rules for an engineering `design.md`. `/design` authors
against this file; `design-reviewer` reviews against it, and `/ready` reads its `- **Repos**:` header. **Net-new — authored for the dev-workflows
plugin, no import source** (unlike `specification-format.md`, which is a snapshot from
`mgd-specifications`).

## Principle — decision-dense, scalable

A `design.md` records **engineering decisions**, not prose. Include a section only when it carries a
real decision for this change; omit a section that does not apply and replace it with a one-line
`_N/A — <why>_`. Never pad. The classification (`SIMPLE` → `HIGH-RISK`) scales how many sections appear
and how deep each goes — a `SIMPLE` design is a few decisions; a `HIGH-RISK` design is thorough across
every section.

**Natural-language prose is the default medium; a decision-encoding snippet is the exception.** Where
a snippet — a state machine, reducer, schema, or type shape — encodes a decision *more precisely than
prose can*, inline it (note it if it came from a prototype) and trim it to the decision-rich parts.
Never paste a whole prototype; the snippet earns its place only by pinning down a decision prose would
leave ambiguous.

## Header

```
# Design

- **Feature name**: <human-readable name>
- **Spec**: <specification.md path, or the Epic key it designs>
- **Classification**: SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK
- **Version**: 1
- **Created**: <YYYY-MM-DD>
- **Author**: <whoami>
- **Repos**: <the confirmed implementation repos this design spans>
- **Open questions**: 0
```

Rules: **`Open questions` MUST be 0 to hand off.** A `design.md` is the last gate before code, so any
unresolved `- [ ]` under its `## Open questions` hard-blocks (`design-reviewer` BLOCKER; Phase 7
refuses; `/implement` refuses). This is the opposite of `specification.md`, where open questions are
tolerated. `Classification` matches the Phase 1.5 result and governs section inclusion below.

## Sections (in order)

Each section header is `## <name>`. Inclusion: **core** = always present (even `SIMPLE`); **scaled** =
present for `MODERATE`+ or whenever the change touches that concern, else a one-line `_N/A — why_`.

1. **## Context & problem** (core) — 2–5 sentences from the spec: who is affected, what the change
   delivers. Reference, don't restate, the spec.
2. **## Requirements coverage** (core) — a table/list tracing every in-scope spec item / user story
   (`[Uxx]`) / acceptance criterion (`[ACxx]`) to how this design addresses it, with a **challenge
   note** per row where the design questioned or refined the spec (`validated` / `questioned` /
   `proposed-change`). Every in-scope requirement is addressed or explicitly deferred with a reason.
   This is where the "challenge the spec" track lands in the design.
3. **## Architecture & components** (core) — the components changed/added and their responsibilities;
   a diagram or bullet decomposition. Name real modules/files where the code scan revealed them.
   Favor **deep modules** (small interface, substantial implementation — see `## Seams` for the
   depth / deletion-test / two-adapters vocabulary).
   **Record at least one rejected alternative, and why** — as a short `### Alternatives considered`
   block inside this section. This is **unconditional**: it applies to every design, whether or not the
   Phase 5 interface fan-out ran. `risk-planner` already demands the same of plans ("Name at least one
   alternative that was rejected and the reason"); a design is the weaker artifact if it does not. When
   the fan-out ran, the losing takes fill this with real trade-offs and are named as such (take,
   constraint, why it lost); otherwise the author names alternatives by hand. An "alternative" that was
   never plausible ("we considered not having an interface") is theatre — see `design-reviewer`.
4. **## Interfaces / contracts** (core) — exact signatures, API shapes, schemas, events, config keys
   the change introduces or alters. Concrete types, not prose promises.
5. **## Seams** (scaled) — where the change is exercised under test; prefer the **highest** seam that
   still isolates the change. Name the seam per component. Judge seam/module quality by: **deep module**
   (a small interface over substantial implementation — prefer depth over many shallow pass-throughs);
   the **deletion test** (would removing this module concentrate complexity meaningfully, or merely
   relocate it? if only relocate, it may not earn its keep); the **two-adapters heuristic** (one
   hypothetical consumer = a *speculative* seam — do not introduce it yet; introduce a seam when a
   second real consumer exists — YAGNI for seams).
6. **## Data flow** (scaled) — how data moves through the changed path; state transitions; persistence.
7. **## Error handling & edge cases** (scaled) — failure modes, boundaries, and the defined behaviour
   for each.
8. **## Test strategy** (core) — what is tested and how (unit / integration / e2e), keyed to the seams;
   cite existing test prior art in the scanned repos.
9. **## Risks & mitigations** (scaled) — engineering risks (performance, concurrency, data-loss, blast
   radius) and the mitigation or explicit acceptance for each.
10. **## Migration / rollout / backward-compatibility** (scaled) — schema/data migration, feature
    flags, rollout order, compat guarantees. `_N/A — why_` when the change is additive and
    self-contained.
11. **## Out of scope** (core) — what this design deliberately does not cover (bounds the
    implementation).
12. **## Open questions** (core; MUST be empty to hand off) — genuinely unresolved engineering items as
    `- [ ]`. Any present blocks handoff; resolve them in the grill, or push a genuinely undecidable one
    onto the `specification.md` as a spec-level `- [ ]` for the PM (the design then waits on it).

## Traceability & identifiers

- Every in-scope spec item and user story (`[Uxx]`) appears in **Requirements coverage** (addressed or
  explicitly deferred).
- Reference spec IDs (`[Uxx]` / `[ACxx]` / `[TCxx]`) rather than restating them; a design section that
  duplicates a `specification.md` section **verbatim** should reference it instead (both docs live in
  the same per-Epic folder).
- Where the design proposes changing an AC/TC, it does **not** rewrite the spec's IDs — it records the
  proposal in the spec's `## Engineering review` section (see the command) and references it here.

## Engineering-review edits to the specification

`/design` records spec challenges **into `specification.md`** (not only here): an `## Engineering
review` section plus new `- [ ]` open questions on the spec. When the spec is `Published: yes`,
annotate only — never mutate existing `[Uxx]` / `[ACxx]` / `[TCxx]` IDs (those route through the specs
repo's human change-management). This design doc's **Requirements coverage** cross-references those
spec edits.

## Provenance

Net-new, authored for the dev-workflows plugin — no upstream import source. The grilling technique
`/design` uses to author against this format is embedded in `commands/design.md` (adapted from
mattpocock grill-me/grilling), so `/design` has no runtime plugin dependency.

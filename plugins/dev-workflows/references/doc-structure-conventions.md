# Doc structure conventions (shared)

Single source of truth for how a written page is **structured** and what it may **contain**,
independent of any single docs repo. This reference is repo-agnostic: it governs the shape of prose,
callouts, and reusable components for whatever docs repo `/document` writes into. Repo-specific
conventions — frontmatter fields, changelog format, terminology lists, component syntax — live under
`${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/`, not here.

Consumed by `doc-writer`, `doc-planner`, and `doc-reviewer`.

---

## 1. The traceability boundary

**The rendered page carries no source provenance.** Jira keys, PR URLs, and `<!-- KEY: … -->` HTML
comments belong in the commit message and in the run's handoff — never in body prose, never in a
changelog entry, never as a comment in the markdown.

| Where | Carries |
|---|---|
| Rendered page | The customer-facing claim only. |
| Commit message | The Jira key and the summary (`profile.commit_convention`). |
| Run handoff / final report | Per-claim attribution to Jira keys and PR URLs. |

This is the general form of the changelog rule already stated in several places in this plugin — a
changelog entry is reader-visible "what changed on this page" prose, and a Jira key never belongs in
it. Every place that says so (`doc-writer.md`, `doc-planner.md`, `commands/document.md`) is stating an
instance of this rule, not a competing one. This section is their authority; when in doubt, this is
the rule those statements cite.

**One exception.** `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.6 defines an
`<!-- intentional-discrepancy: … -->` HTML comment that IS written into the rendered page, and its
text does cite a Jira key. It is not provenance in the sense this rule bans: it is not there to
attribute the change's origin. It is a deliberate, user-decided flag recording *why* the page states
the spec's intended phrasing instead of the code's current behavior — a `document-as-spec` decision
made explicit for the reader and for `doc-reviewer`'s Source-code accuracy dimension, which continues
to check for it. Do not remove this marker as a stray provenance comment; see
`${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.6 for its exact format.

## 2. Callout scope and adjacency

A callout that qualifies one member of a set is placed **with that member**, never as a trailing
block after the set:

1. **With-the-member placement.** When a step or section presents mutually exclusive options, each
   option owns its callouts, placed immediately beneath it.
2. **Whole-set callouts in the lead-in.** A callout that applies to the whole set goes in the lead-in,
   **before** the options — never after them, where position alone reads as "and finally, this
   applies to everything above".
3. **Explicit scope naming.** Where placement alone could still mislead, the callout names its own
   scope in its first clause — for example, *"This applies only to the Private Container Registry
   option."*

**Worked example.** Illustrative only — the syntax below (`{{#callout}}`) is one repo's component; the
rule does not require it. A four-option list presents ways to configure a registry — a built-in
*cluster* registry, a customer-owned private registry, and two public registries. A callout describing
an ARM (multi-architecture image) limitation specific to the built-in cluster registry is placed after
all four options, as a single trailing block. Positioned there, it reads as a constraint on all four
options, including the customer-owned private registry — where it is false, since the customer
controls that registry's contents and can hold multi-arch images. The fix is not rewording; it is
placement — move the callout under the one option it actually describes, or, if it must stay adjacent
to the set, open it with *"This applies only to the built-in cluster registry."*

**Reviewer severity: MAJOR.** A callout whose position admits a broader reading than intended changes
what the customer believes is required or prohibited — a correctness failure, not a stylistic one.

## 3. Component-pattern fidelity

Before writing a content shape that recurs across a docs area — mutually exclusive options,
collapsible detail, tabular reference, and so on — sample the surrounding content area and reuse the
dominant component for a matching shape. Never invent an ad-hoc structure where a sibling pattern
already exists for that shape.

The evidence takes this block shape:

```yaml
component_patterns:
  - shape: mutually-exclusive-options
    component: "{{#tabgroup}} / {{#tab title='…'}}"
    evidence: "guides/container-registries/use-public-registry.md:176"
    count: 4
```

`{{#tabgroup}}` above is a worked example from one docs repo's own component syntax, shown only to
illustrate the block shape — it is not a required or default component.

`shape` is an **open vocabulary**, not a closed enum: the planner names what it observes in the
sampled pages. Mutually-exclusive option sets, collapsible detail, and tabular reference are seed
examples for this rule, not the permitted set — a repo may have area-specific shapes (a comparison
matrix, a decision tree, a step sequence with per-step prerequisites) that belong in `component_patterns`
just the same.

**No component list is vendored.** This rule carries no catalog of components to choose from for any
repo, including a dynatrace-docs one. The evidence comes from whatever repo is in front of the run —
the sampled sibling pages, not a reference table in this plugin. A repo's own authoring guidance may
separately document that a component exists (e.g. a `CLAUDE.md` line naming `{{#tabgroup}}`); what
that guidance typically does not state is which shape it is idiomatic for — that convention is read
off the sibling pages themselves.

**Reviewer severity: MINOR.** A divergence from an established sibling pattern still renders — this is
a consistency and scannability finding, not a correctness one.

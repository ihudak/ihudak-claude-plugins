# Release-note destinations & shapes — source of truth

Consulted by `release-notes-writer` to decide **where a release note lands and what shape it must
take**. This file is the single authority for the destination map, the per-destination draft shape,
the per-destination prose rules, the deprecation-note rule, and Change Type sourcing. The
`/release-notes` command cites this file for its own invariants (§1/§3 for the draft shape, §4 for
the documentation-link rule) but never re-derives the writer's decision; the agent applies it and returns a proposed
destination plus any gaps.

The Change Type is a **Jira dropdown the PM sets on the ticket**. It is never written into the draft
and never collected as a field — the agent resolves it only to pick the destination and the shape.

## 1. The destination map

The Jira release-notes automation routes each note into one of three generated snippet files under
`<space>/_snippets/release-notes/<product>/<sprint>/`. The Change Type selects the file:

| Jira Change Type | Destination | Draft shape |
|---|---|---|
| `Breaking change` | `breaking-changes.md` | `{{#context}}` label + `### title` + prose |
| `New technology support` | `feature-updates.md` | `{{#context}}` label + `### title` + prose |
| `Bug fix` | `fixes.md` | one self-contained sentence — **no label, no title** |
| `not applicable` | — | no note is authored; the command's Phase 2 gate stops the run |

`spotlight.md` also exists in the generated output, but it is curated by the docs team — a Value
Increment never routes there.

## 2. Classification order

Determine the destination by the nature of the change, not by how the source frames it. Take the
first match, in this order:

1. **Breaking change** — the change forces customers to act to avoid disruption.
2. **Bug fix** — the change is a completed correction restoring intended behavior.
3. **New technology support** — anything else that adds or enhances a capability. **For a Value
   Increment this is the overwhelmingly common case**; do not reach for `Bug fix` because a VI
   mentions fixing something.

Tie-breakers:
- A change that both improves something and forces customer action → **Breaking change**.
- A change that both corrects expected behavior and is delivered automatically → **Bug fix**.
- **A change that deprecates anything is NEVER a `Bug fix`.** A deprecation forces customers to act
  before its end-of-life date, so it is never a completed correction. It classifies as `Breaking
  change` when the customer must act now, else `New technology support` when a new capability
  supersedes the old one. **A deprecation therefore never routes to `fixes`** — which is what leaves
  the §5 deprecation note room to live in a titled Summary.

Emit the classification with a confidence signal. When confidence is low (the source supports two
destinations roughly equally), record a `gaps[]` entry (`field: change_type`,
`recommended_action: "ask user"`) carrying the proposed value. The command confirms it by
**consequence** — the shape and the destination file — never by presenting the bare enum labels.

## 3. Draft shape per destination

The **Summary** is the customer-facing body the PM pastes into the Jira release-notes field — the
thing this file's rules shape. There is exactly one per run (§6). Its structure depends on the
destination:

### `feature-updates.md` and `breaking-changes.md`

Render exactly:

```handlebars
{{#context}}<Solution | Capability>{{/context}}

### <feature title>

<prose>
```

Omit the `{{#context}}` line entirely when no Solution label is available (§7).

### `fixes.md`

Render **one self-contained sentence** — no `{{#context}}` line, no `###` title, and no Jira key (the
automation appends the key when it publishes). A shipped entry looks like:

```markdown
Fixed an issue where the **GET account audits** endpoint of the Account Management API would return a `500` error instead of a `504` error in case of a timeout.
```

## 4. Prose rules per destination

### Breaking change
- **Present tense.** State plainly what is breaking — the reader is scanning for impact, so do not
  bury it behind a benefit statement.
- **Include directions or a link to remediate** (the Action plan). Mandatory whenever the customer
  must act; omit only when no action is needed.
- Voice: write "you"/"your"; start with verbs.

### Feature update
- Lead with **customer value**, present tense; mention a previous limitation only as a subordinate
  clause or a later sentence.
- **Link to documentation only on a dev-phase run.** `/release-notes` runs twice in a VI's life, and
  the two runs have different link realities:
  - **PM phase** — no `specification.md` and no `design.md` under the VI's specs dir. The feature is
    not built and the documentation does not exist yet. **Omit the link entirely**; do not ask for one.
  - **Dev phase** — either file is present (the same signal
    `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` §7 uses to infer `phase`/`role`). The author
    can supply a redirect short link that will later point at the page `/document` publishes.
  **Never invent a URL** at either phase.
- Editorial hierarchy — lead with the new or recommended path; demote a deprecated, legacy, or
  manual-only option to a trailing sentence or a `> Note:` line, never an equal peer.
- Enumeration or comparison → a short intro sentence + a bulleted list, **bolding** each option's name.
- **Bold** UI element / screen / field names; inline `code` for filenames, identifiers, flags, and
  config keys.
- State the concrete benefit, not hedged prose.

### Fixes
- **Past tense**, one sentence: symptom + resolution.
- Include the conditions necessary for the problem to occur when they fit the sentence (what action,
  what environment, what input).
- **No hedging** (`could`, `sometimes`, `might`) — except when describing a potential security
  exposure, which must not be stated as fact.
- **No internal jargon, variable names, or code references.** Customer-facing API details (endpoints,
  status codes, response shapes) are fine.
- **No internal workflow terms** — never `ported from`, `merged from`, or `backported`.

## 5. Deprecation note (orthogonal to the destination)

A deprecating change is never a `Bug fix` (§2's third tie-breaker), so it always lands in a **titled**
destination and the note always has room. Which titled destination is independent: a
`New technology support` note can announce that a new capability deprecates an old one, and a
`Breaking change` may itself be a deprecation.

**Trigger** — one or more of:
- The VI deprecates a capability, or a new capability supersedes/deprecates an old one.
- The whole VI is a deprecation.

**When triggered**, the Summary carries a **deprecation note** — a trailing `> Note:` line or a short
labeled sentence — stating:
- what is deprecated,
- the **end-of-life date** — **required**,
- the **end-of-support date** — optional.

**Dates** — never invent them. Derive a date from the source only when the source states it. If a
required end-of-life date is not available, record a `gaps[]` entry (`field: deprecation_eol`,
`recommended_action: "ask user"`) and place a `<!-- TODO: end-of-life date -->` placeholder in the
draft prose. Format dates per the dt-style-guide (e.g. `November 30, 2026`).

Not every VI deprecates something. Raise this only on the trigger above, and ask only for what the VI
does not already state.

## 6. General rules (all destinations)

- **No release version anywhere, and exactly one Summary.** The release version is a separate Jira
  field the PM sets, and it is obvious to customers. Never write "Starting with version 1.305…", "in
  344", etc. Emit **one** Summary for the note — never one block per declared release version.
- **The Change Type never appears as text in the draft.** It selects the destination and the shape;
  the PM sets the dropdown in Jira.
- Translate the technical change into customer-value language (product and UI terms).
- Assert only what the source supports; preserve the facts the source supports.
- These rules complement, and do not duplicate, the dt-style-guide checks run in the command's
  style-gate phase.

## 7. Sourcing the Change Type and the `{{#context}}` label

**Change Type — two rungs:**

1. **Imported VI frontmatter** — `change_type` from the re-imported Jira VI (surfaced by
   `jira-reader`). Authoritative: when present, no confirmation prompt fires.

   Two imported values are **not routable** and fall through to rung 2 (§2 inference): `not applicable`
   (§1 maps it to no destination — the command's relevance gate, not this ladder, is what stops such a
   run), and `Bug fix` on a change that trips §5's deprecation trigger (§2's third tie-breaker bars a
   deprecation from `fixes`, and §5's required end-of-life note has nowhere to live there).
2. **Infer** — classify per §2. When confidence is low, record the `field: change_type` gap so the
   command can confirm the shape.

**`{{#context}}` label — one rung.** It is the Dynatrace Solution taxonomy (e.g. `Platform`,
`Application Observability | Distributed Tracing`, `Infrastructure Observability | Kubernetes`) and it
is exactly the VI's `release_notes_category`:

1. **Imported VI frontmatter** — `release_notes_category` from the re-imported Jira VI. Use it
   verbatim as the label.
2. **Absent → omit the `{{#context}}` line.** Never infer it, never guess it, never ask for it.

Both are Jira dropdowns the PM sets on the ticket; neither is authored in the VI (see
`${CLAUDE_PLUGIN_ROOT}/references/vi-format.md`).

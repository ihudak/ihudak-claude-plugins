# Release-note types — source of truth

Consulted by `release-notes-writer` to classify a Jira release note and shape its
Summary. This file is the single authority for the Change Type taxonomy, the
classification order, the per-type Summary shaping rules, and the deprecation-note
rule. The `/release-notes` command never re-reads this file; the agent applies it and
returns a proposed `change_type` plus any gaps.

## 1. Change Type taxonomy

Every release note carries exactly one **Change Type** — a Jira dropdown value the PM
sets. The four values:

1. **Breaking change** — removes or alters existing behavior so customers must act to
   avoid disruption; usually announced before it ships.
2. **Bug fix** — a completed correction (bug fix, vulnerability fix, patch, or routine
   maintenance) that restores intended behavior.
3. **New technology support** — the release-note-worthy catch-all: adds or enhances a
   capability, or adds new integration / region / technology / platform support, while
   staying compatible with previous releases.
4. **not applicable** — the change is not release-note-worthy. Corresponds to the
   command's worthiness check (`relevant_for_release_notes != "Yes"`); a note is
   normally not authored for this value.

## 2. Classification order

Determine the type by the nature of the change, not how the source frames it. Take the
first type that matches, in this order:

1. **Breaking change** — the change forces customers to act to avoid disruption.
2. **Bug fix** — the change is a completed correction restoring intended behavior.
3. **New technology support** — anything else that adds or enhances a capability.

Tie-breakers:
- A change that both improves something and forces customer action → **Breaking change**.
- A change that both corrects expected behavior and is delivered automatically → **Bug fix**.

Emit the classification with a confidence signal. When confidence is low (the source
supports two types roughly equally), record a `gaps[]` entry (`field: change_type`,
`recommended_action: "ask user"`) carrying the proposed value.

## 3. Per-type Summary shaping

Apply the shaping rules for the classified type together with the general rules in §5.

### Breaking change
- Lead with the customer benefit, not what breaks.
- State what changes or improves, and what will break or behave differently.
- Include an **Action plan** — the specific steps the customer must take — whenever the
  customer must act; omit it only when no action is needed.
- Voice: write "you"/"your"; start with verbs ("Visualize…", "Streamline…").

### Bug fix
- Past tense; lead with the resolution, not the problem.
- Describe the symptom and resolution in plain language the reader can match against
  their own problem; add further detail only if the customer needs it.
- Include the conditions necessary for the problem to occur (what action, what
  environment, what input).
- **No hedging** (`could`, `sometimes`, `might`) — except when describing a potential
  security exposure, which must not be stated as fact.
- **No jargon or code** — no internal jargon, variable names, or code references.
  Customer-facing API details (endpoints, status codes, response shapes) are fine.
- **No internal workflow terms** — never mention `ported from`, `merged from`, or
  `backported`.

### New technology support
Use the benefit-led editorial shaping (the writer's default):
- Lead with the customer value; mention any previous limitation only as a subordinate
  clause or a later sentence.
- Editorial hierarchy — lead with the new/recommended path; demote deprecated or legacy
  options to a trailing sentence or a `> Note:` line.
- Enumeration/comparison → a short intro sentence + a bulleted list, bolding each
  option's name.
- Bold UI element / screen / field names; inline `code` for filenames, identifiers,
  flags, and config keys.
- State the concrete benefit, not hedged prose.

## 4. Deprecation note (orthogonal to Change Type)

Any Change Type may also carry a deprecation note. This is independent of the type — a
`New technology support` note can announce that a new capability deprecates an old one,
and a `Breaking change` may itself be a deprecation.

**Trigger** — one or more of:
- The VI deprecates a capability, or a new capability supersedes/deprecates an old one.
- The whole VI is a deprecation.
- The `change_type_hint` mentions deprecation (e.g. "new feature + deprecation").

**When triggered**, the Summary carries a **deprecation note** — a trailing `> Note:`
line or a short labeled sentence — stating:
- what is deprecated,
- the **end-of-life date** — **required**,
- the **end-of-support date** — optional.

**Dates** — never invent them. Derive a date from the source only when the source
states it. If a required end-of-life date is not available (or a deprecation-signaling
`change_type_hint` leaves the dates unclear), record a `gaps[]` entry
(`field: deprecation_eol`, `recommended_action: "ask user"`) and place a
`<!-- TODO: end-of-life date -->` placeholder in the draft prose. Format dates per the
dt-style-guide (e.g. `November 30, 2026`).

## 5. General rules (all types)

- **No release version in the title or Summary.** The release version is a separate
  Jira field the PM sets manually from the epics'/VI's fixVersions, and it is obvious to
  customers. Never write "Starting with version 1.305…", "in 344", etc. The writer still
  emits one Summary block per declared release version, but the prose never names the
  version.
- Translate the technical change into customer-value language (product and UI terms).
- Assert only what the source supports; preserve the facts the source supports.
- The Change Type label appears **only** on the draft's separate `Change type:` line —
  **never** inside the pipeline-consumed Summary body.
- These rules complement, and do not duplicate, the dt-style-guide checks run in the
  command's style-gate phase.

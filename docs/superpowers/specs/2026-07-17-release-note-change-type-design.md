# Design — Release-note Change Type + type-aware Summary (and dt-style-guide terminology sync)

- **Date:** 2026-07-17
- **Branch:** `feat/release-note-change-type`
- **Status:** Approved (design phase)
- **Author:** brainstormed with Ivan Gudak

## Background

The `$SPECS_PATH` repo (`Dynatrace-Internal/mgd-specifications`) overhauled its
`.claude/` agents and skills on 2026-07-17 (commit `e09c2ba`). The release-note
tooling that our `dev-workflows` plugin was modeled on now classifies every note as
`new feature` / `bugfix` / `breaking change`, each with its own template and rules,
and the content-style skill was split into a curated `writing-style.md` +
`terminology.md`.

Our `/release-notes` command + `release-notes-writer` agent produce a single
feature-update-shaped draft (`{{#context}}` label + `### title` + prose) with **no
notion of release-note type** and no deprecation handling. This design closes that
gap for the Dynatrace workflow, and separately refreshes the `dt-style-guide`
terminology from the upstream curated digest.

### Domain facts (from the product owner)

- A Jira release note is three things the PM fills in and pastes: **Title**, **Change
  Type**, **Summary**. The existing Jira → dynatrace-docs pipeline consumes these; **it
  is out of scope and must not change.**
- **Change Type** is a Jira field with values: `Breaking change` /
  `New technology support` / `Bug fix` / `not applicable`.
- Change Type is **not** present in the exported VI frontmatter today (confirmed across
  all exports under `$VAULT_PATH/jira-products`; `vi-format.md` only defines
  `relevant_for_release_notes` and `release_versions`). The command must therefore
  **determine** the type itself (infer + let the user confirm/override), not read it.
- A **breaking change** needs extra attention in the Summary (what breaks + an action
  plan).
- **Deprecation is orthogonal to type.** When a change deprecates a capability,
  supersedes an old one, or the whole VI is a deprecation, the Summary must carry a
  **deprecation note** with an **end-of-life date (required)** and an **end-of-support
  date (optional)**.
- `not applicable` corresponds to the command's existing worthiness check
  (`relevant_for_release_notes != "Yes"`).

## Goals

1. `/release-notes` output leads with a `Change type: <one of the four values>` line
   the PM uses to set the Jira dropdown; the pipeline-consumed Summary body is
   unchanged in structure.
2. The Summary is shaped per the classified type (breaking / bug fix / new-tech).
3. Deprecation notes (EOL required, end-of-support optional) are produced when the
   change deprecates something; missing dates are surfaced to the user.
4. `dt-style-guide` terminology is enriched from the upstream curated digest.

## Non-goals

- No change to the Jira → dynatrace-docs rendering pipeline or its macros.
- No change to the export tooling or VI frontmatter schema (`change_type` is inferred,
  not added to `vi-format.md` in this iteration — noted as a possible future
  extension).
- No new review gate, tests, branch, or commit behavior for `/release-notes` (it stays
  a light-gate command).

## Chosen approach — Hybrid (writer proposes, command confirms, reference is truth)

Mirrors the plugin's established pattern (`source-truth.md` + `model-routing` as
single-source-of-truth references consulted by agents; agents propose, commands
confirm via the existing `gaps[]` → ask-the-user flow).

### Component 1 — New reference `plugins/dev-workflows/references/release-note-types.md`

Single authority, consulted by `release-notes-writer` only. Sections:

- **Taxonomy** — the four Jira Change Type values with definitions:
  - `Breaking change` — removes or alters existing behavior so customers must act to
    avoid disruption; usually announced before it ships.
  - `New technology support` — the release-note-worthy catch-all: adds or enhances a
    capability, adds a new integration / region / technology, staying compatible with
    previous releases.
  - `Bug fix` — a completed correction (bug fix, vulnerability fix, patch, or routine
    maintenance) that restores intended behavior.
  - `not applicable` — not release-note-worthy; ties to the worthiness check.
- **Classification order + tie-breakers** — first match wins: `Breaking change` →
  `Bug fix` → `New technology support`. Tie-breakers: an improvement that also forces
  customer action → `Breaking change`; a correction delivered automatically → `Bug
  fix`.
- **Per-type Summary shaping rules:**
  - **Breaking change** — lead with the customer benefit (not what breaks); state what
    changes/improves and what will break or behave differently; include an **Action
    plan** whenever the customer must act (omit only when no action is needed). Voice:
    "you"/"your", verb-led. **Do not** state the release version — see the general rule
    below.
  - **Bug fix** — past tense; lead with the resolution, not the problem; describe
    symptom + resolution in plain language; include the conditions that trigger the
    problem; **no hedging** (`could`/`sometimes`/`might`) except when describing a
    potential security exposure; **no jargon or code** (customer-facing API details like
    endpoints/status codes are fine); **no internal workflow terms**
    (`ported from`/`merged from`/`backported`).
  - **New technology support** — the existing benefit-led editorial shaping in
    `release-notes-writer` step 3 (kept verbatim): lead with the benefit, editorial
    hierarchy, bold UI names, enumeration → bulleted list, concrete benefit not hedged
    prose.
- **Deprecation note rule (orthogonal to type):**
  - Trigger — the VI deprecates a capability, a new capability supersedes/deprecates an
    old one, or the whole VI is a deprecation. Signals: the VI's `## What` /
    "Current vs Target State" / explicit "deprecat*" wording, **or** a
    `change_type_hint` that mentions deprecation.
  - When triggered, the Summary carries a **deprecation note** (a trailing `> Note:`
    line or short labeled sentence) stating what is deprecated, the **end-of-life date
    (required)**, and the **end-of-support date (optional)**.
  - If a required EOL date is not derivable from the source (or the deprecation-signaling
    `change_type_hint` leaves the dates unclear), emit a `gaps[]` entry
    (`field: deprecation_eol`, `recommended_action: "ask user"`) and place a
    `<!-- TODO: end-of-life date -->` placeholder in the draft prose.
- **General rule (all types) — no release version in the title or Summary.** The
  release version is a separate Jira field the PM sets manually from the epics'/VI's
  fixVersions, and it is obvious to customers. The title and Summary must never state
  it (no "Starting with version 1.305…", no "in 344", etc.). Note: this refines the
  existing per-`release_versions` entry rendering — the writer still emits one Summary
  block per declared release version, but the prose itself never names the version.
- **Interaction note** — these per-type prose rules complement, and do not duplicate,
  the `dt-style-guide` checks that still run in Phase 7.

Register this reference in `CLAUDE.md`'s source-truth section.

### Component 2 — `plugins/dev-workflows/agents/release-notes-writer.md`

- **Input contract:** add optional `change_type_hint` (a user-supplied type and/or
  deprecation signal; `null` otherwise).
- **Process additions/changes:**
  1. **Classify** — determine `change_type` using `change_type_hint` when provided, else
     infer per `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md`. Record
     confidence.
  2. **Detect deprecation** — scan the VI content (and honor a deprecation-signaling
     `change_type_hint`) per the reference's deprecation rule.
  3. **Shape the Summary** — apply the classified type's shaping rules from the
     reference. The existing step-3 editorial rules become the `New technology support`
     branch; add the `Breaking change` and `Bug fix` branches.
  4. **Render** — when deprecation applies, render the deprecation note into the Summary
     body (trailing `> Note:` with EOL + optional end-of-support date, or the TODO
     placeholder).
- **Output (handoff) changes:**
  - `change_type` is a **top-level field of `release_notes_block`** (one per note, not
    per release version).
  - `combined_rendered` leads with a single `Change type: <value>` line, then a short
    human-facing divider (`--- Summary (paste into release-notes field) ---`, matching
    the approved preview — a copy guide, not part of the paste), then the unchanged
    per-version Summary blocks.
  - New `gaps[]` reasons: `field: change_type` (low-confidence classification) and
    `field: deprecation_eol` (missing required EOL date).
- **Hard rules:**
  - The type label appears **only** on the separate `Change type:` line — **never**
    inside the pipeline-consumed Summary body.
  - Never invent an EOL / end-of-support date; record a gap instead.
  - Existing hard rules (no Jira IDs, no PR links, no `{{#internal-note}}`, no invented
    behavior) unchanged.

### Component 3 — `plugins/dev-workflows/commands/release-notes.md`

- **Phase 6 (Render):** pass `change_type_hint` (null unless the user supplied one).
  Handle the two new gaps through the **existing** gaps → ask-the-user flow:
  - `field: change_type` (low-confidence) → present the proposed type plus the four
    values for the user to confirm/override.
  - `field: deprecation_eol` → ask for the end-of-life date (required) and end-of-support
    date (optional), or accept the `<!-- TODO -->` marker.
- **Phase 8 (Report):** add `- Change type: <value>` and, when deprecating,
  `- Deprecation: EOL <date> (end-of-support <date | —>)`.
- **Invariants block:** add — "the draft leads with a `Change type:` line (one of the
  four Jira values) and a type-aware Summary; a deprecation note carries EOL (required)
  + end-of-support (optional); the pipeline-consumed Summary body is otherwise
  unchanged." Existing no-Jira-ID / no-PR-link / no-`{{#internal-note}}` invariants stay
  (the `Change type:` line is a plain English label, not a Jira ID).

### Component 4 — `CLAUDE.md`

- Register `references/release-note-types.md` in the source-truth reference list.
- Update the `/release-notes` key-invariants list and the workflow-map line to mention
  type classification + deprecation.

### Component 5 — `dt-style-guide` terminology sync (workstream B)

- Additively fold the upstream curated entries from
  `$SPECS_PATH/.claude/skills/dynatrace-content-style/assets/terminology.md` into
  `plugins/dt-style-guide/references/` (`word-list.md` / `terminology.md`).
- Confirmed-missing so far: `timeframe selector`, `Strato Design System`, "around the
  clock" (vs `24/7` / `24x7`). Do a full reconcile pass against the upstream
  `terminology.md` to catch the rest; keep all existing scraped entries.
- Bump `plugins/dt-style-guide/.claude-plugin/plugin.json` version and add a
  `CHANGELOG.md` entry.

## Data flow (happy path)

```
/release-notes <KEY>
  → Phase 3 jira-reader handoff (VI content, release_versions)
  → Phase 6 release-notes-writer:
        classify change_type (hint | infer via release-note-types.md)
        detect deprecation → EOL/EOS (or gap)
        shape Summary per type
        emit: change_type, per-version Summary blocks, gaps[]
  → command resolves gaps via existing ask-the-user flow
  → Phase 7 dt-style-checker (unchanged)
  → Phase 8 draft:
        "Change type: <value>"
        "--- Summary (paste into release-notes field) ---"   (copy guide, not pasted)
        <unchanged {{#context}} + ### title + type-aware prose (+ deprecation note)>
     report adds: Change type, Deprecation (when applicable)
```

## Verification

No runtime tests — the deliverables are agent prompts and reference docs. Per the
repo's Surgical-Changes guardrail:

1. **No dangling references** — every new field (`change_type`, `change_type_hint`,
   gap reasons `change_type` and `deprecation_eol`) is declared in the handoff format
   **and** consumed in the command **and** reflected in `CLAUDE.md`.
2. **No contradiction** — the `release-note-types.md` reference and the
   `release-notes-writer` hard rules agree that the type label lives only on the
   `Change type:` line, never in the Summary body.
3. **Dry-run walkthrough** — trace `PRODUCT-14900` (AWS Lambda in GovCloud US):
   classify as `New technology support`, detect the "classic layers … deprecated"
   signal, confirm the flow asks for the EOL date, and confirm the rendered draft leads
   with `Change type: New technology support` followed by the unchanged Summary body
   plus a deprecation `> Note:`.

## Affected files

- **New:** `plugins/dev-workflows/references/release-note-types.md`
- **Edit:** `plugins/dev-workflows/agents/release-notes-writer.md`
- **Edit:** `plugins/dev-workflows/references/handoff/release-notes-writer.md`
- **Edit:** `plugins/dev-workflows/commands/release-notes.md`
- **Edit:** `CLAUDE.md`
- **Edit:** `plugins/dt-style-guide/references/word-list.md` (and `terminology.md` if
  needed)
- **Edit:** `plugins/dt-style-guide/CHANGELOG.md` + `.claude-plugin/plugin.json`

## Future extensions (out of scope)

- Add an optional `change_type` / deprecation frontmatter block to `vi-format.md` so
  `/create-vi` can capture the intended type at authoring time and future exports can
  carry it (letting `release-notes-writer` read rather than infer).

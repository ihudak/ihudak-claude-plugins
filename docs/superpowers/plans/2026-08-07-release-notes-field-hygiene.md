# Release-notes field hygiene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop `/create-vi` and `/release-notes` from asking for three Jira dropdown values, and make `release-note-types.md` the authority for a note's *destination and shape* rather than its label.

**Architecture:** Pure prompt-and-reference content editing across three plugin editions. `release_versions`, `change_type`, and `release_notes_category` move from the PM-authorable frontmatter class to the Jira-mirror class in `vi-format.md`; `/release-notes` sources them from the Jira import or omits what depends on them. One question survives — a low-confidence *shape* confirmation framed by consequence, not by enum label.

**Tech Stack:** Markdown only. No code, no test framework, no build. Verification is targeted `grep` plus read-back.

**Spec:** `docs/superpowers/specs/2026-08-07-release-notes-field-hygiene-design.md`

## Global Constraints

- **No test framework exists for prompt content.** Each task's TDD cycle is: write the verification `grep`, run it and confirm it FAILS against current content, make the edit, re-run and confirm it PASSES.
- **Three editions, canonical first.** `/workspace/ihudak-claude-plugins` (canonical) → `/workspace/mgd-claude-plugins` (byte-identical copy) → `/workspace/ihudak-copilot-plugins` (adapted layout). Never edit the ports before the canonical repo is complete and committed.
- **Copilot substitutions** are exactly three, applied to canonical content: `${CLAUDE_PLUGIN_ROOT}/references/` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/`; `/release-notes` → `release-notes:` (and likewise for other command names); the word "command" → "skill" in prose describing a command.
- **Copilot layout:** commands are `dev-workflows/skills/<name>/SKILL.md`; references are `dev-workflows/skills/_shared/<ref>.md`; agents are `dev-workflows/agents/<name>.md` (same as canonical).
- **The four Jira Change Type values are unchanged** and must be reproduced exactly where they still appear: `Breaking change`, `New technology support`, `Bug fix`, `not applicable`.
- **The three generated destinations** are exactly `breaking-changes.md`, `feature-updates.md`, `fixes.md`. `spotlight.md` exists but a VI never routes there.
- **Version bump:** `2.41.0` → `2.42.0` in the canonical and mgd editions. The Copilot edition has its own independent version line — read its current value and bump the minor.
- Work on a branch. The canonical branch `iv-gu/release-notes-field-hygiene` already exists and carries the spec commits.

## File structure

| File (relative to the edition's plugin root) | Responsibility after this change |
|---|---|
| `references/vi-format.md` | Declares which frontmatter fields a PM authors. Loses three fields to the Jira-mirror class. |
| `references/release-note-types.md` | **Rewritten.** Destination map + per-destination draft shape + per-destination prose rules + deprecation + two-rung sourcing. |
| `references/handoff/release-notes-writer.md` | The writer's input/output contract. Loses three inputs and three gap kinds; gains the conditional `fixes` shape. |
| `agents/release-notes-writer.md` | The writer's own instructions. Sources the `{{#context}}` label instead of guessing it; emits one entry; shapes by destination. |
| `agents/vi-reviewer.md` | Stops requiring/validating the three fields. |
| `commands/create-vi.md` | Stops asking for the three fields. |
| `commands/release-notes.md` | Real worthiness gate; no field questions except the §4 shape confirmation. |
| `README.md`, `CLAUDE.md` (repo root), `CHANGELOG.md`, `.claude-plugin/plugin.json` | Docs + version. |

Unchanged on purpose:

- `agents/jira-reader.md` and `references/handoff/jira-reader.md` already surface all three imported fields verbatim, which is exactly what the new design consumes.
- `references/vi-source-resolution.md` keeps its generic step 5 (secondary grounding for the grill); only `/release-notes`' use of it to read these three fields goes.
- `commands/update-vi.md` authors against `references/vi-format.md` and carries no field-specific prose, so it inherits Task 1 with no edit. **Verify this** rather than assuming it: `grep -n "release_versions\|change_type\|release_notes_category" commands/update-vi.md` must return nothing. If it matches, apply the same Task 1 Step 5 treatment to it.

---

### Task 1: Reclassify the three fields (authoring side)

Moves `release_versions`, `change_type`, `release_notes_category` out of the PM-authorable class, and stops `/create-vi` asking and `vi-reviewer` validating.

**Files:**
- Modify: `plugins/dev-workflows/references/vi-format.md:26-29` and `:41-42`
- Modify: `plugins/dev-workflows/agents/vi-reviewer.md:23`
- Modify: `plugins/dev-workflows/commands/create-vi.md:118`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the rule that later tasks cite — *the three fields are Jira-mirror fields, read from the import, never authored*. Task 2 §7 and Task 4's Phase 3 both depend on this being stated in `vi-format.md`.

- [ ] **Step 1: Write the failing verification**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# Must find NOTHING once the task is done:
grep -n "^release_versions:\|^change_type:\|^release_notes_category:" references/vi-format.md
grep -n "change_type. must be one of" agents/vi-reviewer.md
grep -n "Ask for .change_type. / .release_notes_category." commands/create-vi.md
```

- [ ] **Step 2: Run it to verify it currently fails**

Run the three greps above.
Expected: each returns matching lines — `vi-format.md:27,28,29`, `vi-reviewer.md:23`, `create-vi.md:118`. That is the "red" state.

- [ ] **Step 3: Edit `references/vi-format.md`**

Replace lines 26-29:

```yaml
relevant_for_release_notes: <yes | no>
release_versions: "<e.g. Managed (344), SaaS (344)>"
change_type: <Breaking change | New technology support | Bug fix | not applicable>   # optional; authored-then-mirrored, like release_versions
release_notes_category: <Dynatrace Solution, e.g. Application Observability>          # optional
```

with:

```yaml
relevant_for_release_notes: <yes | no>
```

Then replace the paragraph at `:41-42`:

```
The pure Jira-mirror fields (`statusCategory`, `reporter`, `url`, `updated`, `synced`, …) are
regenerated by the importer on the round-trip and are NOT authored here.
```

with:

```
The pure Jira-mirror fields (`statusCategory`, `reporter`, `url`, `updated`, `synced`, …) are
regenerated by the importer on the round-trip and are NOT authored here. `release_versions`,
`change_type`, and `release_notes_category` belong to the same class: each is a Jira dropdown the PM
sets on the ticket, each returns on the re-import, and `/release-notes` reads them from there. Never
author them and never ask for them — deciding a dropdown value in a chat window costs exactly what
deciding it in Jira costs, so the question buys nothing.
```

- [ ] **Step 4: Edit `agents/vi-reviewer.md:23`**

Replace:

```
2. Verify frontmatter: `issue_type: ValueIncrement`; `jira_key` matches `^[A-Z][A-Z0-9_]*-\d+$`; the downstream-contract fields `relevant_for_release_notes` + `release_versions` present; `sources` carries real provenance (not the literal `idea.md` path). When present, `change_type` must be one of `Breaking change` / `New technology support` / `Bug fix` / `not applicable` (`MAJOR` if it is some other value); when `relevant_for_release_notes: yes` and `change_type` is absent, raise a `MINOR` (recommended, not required). `release_notes_category`, when present, is free text — no format check.
```

with:

```
2. Verify frontmatter: `issue_type: ValueIncrement`; `jira_key` matches `^[A-Z][A-Z0-9_]*-\d+$`; the downstream-contract field `relevant_for_release_notes` present; `sources` carries real provenance (not the literal `idea.md` path). `release_versions`, `change_type`, and `release_notes_category` are Jira-mirror fields per `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md` — they are not authored in the VI, so their absence is NEVER a finding and their presence is not validated.
```

- [ ] **Step 5: Edit `commands/create-vi.md:118`**

Replace:

```
1. Frontmatter — incl. `release_versions` + `relevant_for_release_notes`, and (when `relevant_for_release_notes: yes`) the optional `change_type` (one of `Breaking change` / `New technology support` / `Bug fix` / `not applicable`) + `release_notes_category` (the Dynatrace Solution); `sources` (propagated), `derived_from`, `seeded_from_vi` (only when `--from-vi` was used), `jira_key`. Ask for `change_type` / `release_notes_category` only when the note is release-notes-relevant; leave them out otherwise (dates/deprecation stay out of frontmatter — they belong in the release-notes Summary).
```

with:

```
1. Frontmatter — `relevant_for_release_notes` (defaults to `yes`; ask only to confirm a `no`); `sources` (propagated), `derived_from`, `seeded_from_vi` (only when `--from-vi` was used), `jira_key`. Do NOT ask for `release_versions`, `change_type`, or `release_notes_category` — they are Jira dropdowns the PM sets on the ticket and the importer returns on the round-trip (`${CLAUDE_PLUGIN_ROOT}/references/vi-format.md`); `/release-notes` reads them from the import. Dates and deprecation details also stay out of frontmatter — they belong in the release-notes Summary.
```

- [ ] **Step 6: Run the verification to confirm it passes**

Run the three greps from Step 1.
Expected: all three return no output (exit status 1).

Then confirm nothing else in the plugin still asks for these fields during authoring:

```bash
grep -rn "release_versions" commands/ agents/vi-reviewer.md references/vi-format.md
```
Expected: no output.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/vi-format.md \
        plugins/dev-workflows/agents/vi-reviewer.md \
        plugins/dev-workflows/commands/create-vi.md
git commit -m "feat(dev-workflows): reclassify release-notes fields as Jira-mirror

release_versions, change_type, and release_notes_category are Jira dropdowns
the PM sets on the ticket and the importer returns on the round-trip. Move
them out of the PM-authorable frontmatter class so /create-vi stops asking
and vi-reviewer stops requiring and validating them."
```

---

### Task 2: Rewrite `release-note-types.md` as a destination + shape authority

**Files:**
- Modify (full rewrite): `plugins/dev-workflows/references/release-note-types.md`

**Interfaces:**
- Consumes: Task 1's Jira-mirror rule.
- Produces: the section numbers Tasks 3 and 4 cite — **§1** destination map, **§2** classification order, **§3** draft shape per destination, **§4** prose rules per destination, **§5** deprecation note, **§6** general rules, **§7** sourcing. Task 3 replaces `agents/release-notes-writer.md`'s citations of the old `§1–§2`, `§3`, `§4`, `§5`, `§6` with these.

- [ ] **Step 1: Write the failing verification**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# Must ALL be present once the task is done:
grep -c "feature-updates.md" references/release-note-types.md   # expect exactly 2 (the §1 map row + the §3 shape heading)
grep -n "^## 7. Sourcing the Change Type" references/release-note-types.md
grep -n "no label, no title" references/release-note-types.md
# Must be ABSENT once done:
grep -n "change_type_hint" references/release-note-types.md
grep -n "Authored specs-draft VI" references/release-note-types.md
```

- [ ] **Step 2: Run it to verify it currently fails**

Expected: the first three return `0` / no matches; the last two DO match (`:87`, `:97`, `:121`, `:125`). That is the "red" state.

- [ ] **Step 3: Replace the whole file with this content**

````markdown
# Release-note destinations & shapes — source of truth

Consulted by `release-notes-writer` to decide **where a release note lands and what shape it must
take**. This file is the single authority for the destination map, the per-destination draft shape,
the per-destination prose rules, the deprecation-note rule, and Change Type sourcing. The
`/release-notes` command never re-reads this file; the agent applies it and returns a proposed
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
````

- [ ] **Step 4: Run the verification to confirm it passes**

Run the five greps from Step 1.
Expected: `grep -c "feature-updates.md"` returns ≥ 3; the `## 7.` and `no label, no title` greps match; the `change_type_hint` and `Authored specs-draft VI` greps return no output.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/release-note-types.md
git commit -m "feat(dev-workflows): release-note-types.md becomes a destination + shape authority

The Change Type is never rendered in a generated release note — it routes the
note to breaking-changes.md, feature-updates.md, or fixes.md, and fixes.md
publishes a bare sentence rather than label+title+prose. Rewrite the reference
around destination and shape, adopt the docs team's own per-type prose rules,
and collapse sourcing to two rungs (import, else infer)."
```

---

### Task 3: Update the writer agent and its handoff contract

**Files:**
- Modify: `plugins/dev-workflows/agents/release-notes-writer.md`
- Modify: `plugins/dev-workflows/references/handoff/release-notes-writer.md`

**Interfaces:**
- Consumes: Task 2's section numbers (§1–§7).
- Produces: the input field set Task 4's Phase 6 dispatch must match — `jira_reader_handoff`, `diff_summaries`, `imported_change_type`, `imported_release_notes_category`, `model_routing`, `code_repos`, `docs_grounding`. And the output gap kinds Task 4 handles — `change_type`, `deprecation_eol`, `prose`, `feature_title`.
- **Safe to flatten:** this task removes the output schema's `entries[]` list (one Summary ⇒ no list). Verified that nothing outside the writer reads it — `commands/release-notes.md` consumes only `combined_rendered` (Phase 7 `:218`, Phase 8 `:228`) and `gaps[]` (`:182`, `:200`). Re-confirm before editing with: `grep -n "entries" commands/release-notes.md` (the only hits should be prose uses of the English word, not `release_notes_block.entries`).

- [ ] **Step 1: Write the failing verification**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# Must be ABSENT once done:
grep -n "context_label_hint\|change_type_hint\|authored_vi_fields\|change_type_divergence" \
  agents/release-notes-writer.md references/handoff/release-notes-writer.md
grep -n "release_versions" agents/release-notes-writer.md references/handoff/release-notes-writer.md
grep -n "never the {{#context}} label" agents/release-notes-writer.md
# Must be PRESENT once done:
grep -n "destination" references/handoff/release-notes-writer.md
```

- [ ] **Step 2: Run it to verify it currently fails**

Expected: the first three greps match many lines; the last returns nothing. That is the "red" state.

- [ ] **Step 3: Edit `agents/release-notes-writer.md` — frontmatter `description`**

Replace the `description:` value with:

```
Renders a dynatrace-docs release-notes draft (the authored body only) for a Jira VI/ticket from the jira-reader handoff and optional PR-diff summaries. Emits exactly ONE Summary. Resolves the note's destination (breaking-changes / feature-updates / fixes) to pick the draft's shape — a {{#context}} label + H3 title + prose, or a single bare sentence for fixes — and never writes the Change Type as text. Sources the {{#context}} label from the imported release_notes_category and omits it when absent. Emits NO Jira IDs, NO PR links, and NO {{#internal-note}} block (the docs automation adds those). Does NOT write files. Model tier assigned by the caller per the model-routing policy (no fixed pin).
```

- [ ] **Step 4: Edit `agents/release-notes-writer.md` — the `## Inputs` block**

Replace lines 17-29 (the whole ```yaml block) with:

```yaml
jira_reader_handoff: <full YAML from jira-reader>
diff_summaries:      <optional array of diff-summarizer outputs; omit when diff-grounding is off>
imported_change_type:            <change_type from the imported VI frontmatter (jira-reader handoff); null otherwise>
imported_release_notes_category: <release_notes_category from the imported VI frontmatter; null otherwise>
run_phase:           <pm | dev — which of the two /release-notes runs this is; gates the §4 documentation-link rule>
model_routing:       <standard block>
code_repos:          <optional array of {slug, path}; provided when diff-grounding is on>
docs_grounding:      <optional docs-grounder digest (docs_references + docs_challenges); omit when docs grounding was OFF/EMPTY>
```

Add this paragraph to the `## Inputs` prose, immediately after the block:

```
`run_phase` distinguishes the PM-phase run (the feature is not built and no documentation exists) from
the dev-phase run (implementation and docs are underway). It gates only the §4 documentation-link rule
for the `feature-updates` destination; nothing else reads it. **It arrives pre-resolved — trust it.**
`release-note-types.md` §4 states the condition concretely ("no `specification.md` and no `design.md`
under the VI's specs dir") because it was written before this field existed, but you have no knowledge
of `$SPECS_PATH` or the VI's specs dir, so NEVER glob or otherwise check the filesystem for those
files. The command resolves the phase and hands it to you; a self-check would silently produce the
wrong answer.
```

- [ ] **Step 5: Edit `agents/release-notes-writer.md` — Process steps 1, 2, 5, 6, 7**

Replace Process step 1 with:

```
1. **Resolve the destination.** Per `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` §7:
   `imported_change_type` → infer per §2. Set `release_notes_block.change_type` to one of
   `Breaking change` / `New technology support` / `Bug fix`, and `release_notes_block.destination` to
   the matching file from §1. Only when the value had to be **inferred** and is low-confidence, emit
   `gaps[]` (`field: change_type`, `recommended_action: "ask user"`) carrying the proposed value —
   the command confirms it by shape and destination, not by enum label. The Change Type is NEVER
   written as text into the draft.
```

Replace Process step 2 with:

```
2. **Resolve the `{{#context}}` label.** Per §7, set `release_notes_block.context_label` =
   `imported_release_notes_category`, used verbatim. When it is null, set `context_label: null` and
   **omit the `{{#context}}` line** from the rendered body. Never infer it, never guess it, never
   raise a gap for it.
```

Replace Process step 5 with:

```
5. **Emit exactly one Summary.** Per §6, the draft carries ONE Summary regardless of how many release
   versions the ticket declares — the prose may never name a version, so per-version blocks would be
   identical. There is no `release_version` field and no `release_version` gap.
```

Replace Process step 6's opening bullet list header and its **Context label** bullet with:

```
6. **Build the authored body, shaped by the destination (§3, §4):**
   - **`fixes`** — render **one self-contained past-tense sentence**: symptom + resolution, per §4
     Fixes. NO `{{#context}}` line, NO `###` title, NO Jira key. Skip the remaining bullets in this
     step; they apply only to the titled shapes.
   - **Context label** (titled shapes only) — the value resolved in step 2, rendered verbatim. When it
     is null, omit the line.
```

Leave the existing **Feature title**, **Body**, and the New-technology-support shaping sub-bullets in place, but replace the sentence `**Body** — customer-facing content shaped by the classified Change Type per ${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md §3.` with:

```
     - **Body** — customer-facing content shaped by the destination per
       `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` §4.
```

- [ ] **Step 6: Edit `agents/release-notes-writer.md` — Process step 7 (Render)**

Replace the whole of Process step 7 with:

````
7. **Render.** For a **titled** destination (`breaking-changes`, `feature-updates`), render the
   Summary body as exactly:

   ```handlebars
   {{#context}}<context_label>{{/context}}

   ### <feature_title>

   <prose>
   ```

   Omit the `{{#context}}` line (and the blank line after it) when `context_label` is null.

   For the **`fixes`** destination, render the Summary body as the bare sentence alone — no label, no
   heading.

   Set `combined_rendered` to that Summary body verbatim. It carries NO `Change type:` line, NO
   `Release-notes category:` line, and NO `--- Summary ---` divider — the whole output is the text the
   PM pastes into the Jira release-notes field.
````

- [ ] **Step 7: Edit `agents/release-notes-writer.md` — Hard rules**

Replace the four rules currently at `:144-152` (the `ALWAYS set … change_type`, `NEVER place the Change Type label`, the `release_notes_category is surfaced metadata only` rule, and `NEVER name the release version`) with:

```
- ALWAYS set `release_notes_block.change_type` to one of `Breaking change` / `New technology
  support` / `Bug fix`, and `release_notes_block.destination` to the matching file per
  `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` §1; when the value was inferred with low
  confidence, still set it and record a `field: change_type` gap.
- NEVER write the Change Type as text anywhere in the draft. It selects the destination and the shape
  only; the PM sets the Jira dropdown.
- The `{{#context}}` label IS the imported `release_notes_category`, used verbatim. When the import
  does not carry one, omit the `{{#context}}` line — never infer, guess, or ask for a label.
- NEVER name the release version in any `feature_title` or `prose`, and NEVER emit more than one
  Summary.
```

Replace the last hard rule (`ALWAYS produce one entry per release_versions item…`) with:

```
- ALWAYS produce exactly ONE Summary per run.
```

- [ ] **Step 8: Edit `references/handoff/release-notes-writer.md` — Input block**

Replace lines 9-15 with:

```yaml
imported_change_type:            <change_type from the imported VI frontmatter (jira-reader handoff); null otherwise>
imported_release_notes_category: <release_notes_category from the imported VI frontmatter; null otherwise — used verbatim as the {{#context}} label>
run_phase:                       <"pm" | "dev" — inferred by the command from whether specification.md / design.md exist under the VI's specs dir; gates the release-note-types.md §4 documentation-link rule only>
```

Replace line 27 with:

```
Refuse to run without `jira_reader_handoff`. Emit exactly one Summary per run.
```

- [ ] **Step 9: Edit `references/handoff/release-notes-writer.md` — Output block**

Replace the `release_notes_block:` block and its `entries:` list with:

````yaml
release_notes_block:
  target_format: dynatrace-docs-release-notes-v1
  change_type:  <one of: "Breaking change" | "New technology support" | "Bug fix">   # selects the destination + shape; NEVER rendered as text
  destination:  <one of: "breaking-changes.md" | "feature-updates.md" | "fixes.md">  # per release-note-types.md §1
  context_label: <the imported release_notes_category verbatim, e.g. "Platform | Settings"; null when the import carries none — the {{#context}} line is then omitted>
  feature_title: <5–10 word headline; sentence case; no leading "New feature:"; no trailing period. null for the fixes destination.>
  prose: |
    <shaped customer-facing body; no Jira IDs; no PR links; no release version. For the titled
    destinations: a 2–4 sentence paragraph, or a short intro sentence + a bulleted list when the
    feature enumerates discrete options. For the fixes destination: ONE self-contained past-tense
    sentence. See release-note-types.md §3 (shape) and §4 (prose rules).>
  combined_rendered: |
    <the exact text the PM pastes into the Jira release-notes field. For a titled destination:
    "{{#context}}<context_label>{{/context}}", a blank line, "### <feature_title>", a blank line,
    then <prose> — with the {{#context}} line omitted entirely when context_label is null. For the
    fixes destination: <prose> alone. NEVER a "Change type:" line, a "Release-notes category:" line,
    or a "--- Summary ---" divider.>
````

Replace the `gaps:` `field:` enum line and the two divergence-only lines with:

```yaml
gaps:
  - field:              <feature_title | prose | change_type | deprecation_eol>
    reason:             <why this is low-confidence or missing. For change_type: the destination was inferred and the source supports two destinations roughly equally; the proposed value is still set on release_notes_block. For deprecation_eol: a deprecation was detected but the required end-of-life date is not derivable from the source.>
    recommended_action: "ask user" | "mark TODO in draft" | "note in report"
    jira_phrasing:      <only for source-truth discrepancies — the draft's current (Jira-derived) phrasing>
    source_phrasing:    <only for source-truth discrepancies — what the source code actually shows>
    source_location:    <only for source-truth discrepancies — file:line the source_phrasing was verified against>
```

Replace the `PARTIAL` status-table row with:

```
| `PARTIAL` | Draft rendered but at least one gap needs the user (low-confidence destination, missing end-of-life date, or an unverifiable claim). |
```

- [ ] **Step 9b: Repair staleness Task 2's renumbering and this task's flattening created**

Four repairs to text the earlier steps leave behind. All four are in the two files this task already owns.

1. **Three stale section citations in `agents/release-notes-writer.md`.** Task 2 renumbered `release-note-types.md`, so citations written against the old numbering now point at the wrong sections. Repair each in place:
   - the Bug-fix rules citation — `§3 Bug fix rules` → `§4 Fixes rules`
   - the Breaking-change rules citation — `§3 Breaking change rules` → `§4 Breaking change rules`
   - the release-version rule — `Never name the release version in the prose (§5)` → `(§6)`

   Then audit **every** remaining `§N` in both files against the actual headings of `plugins/dev-workflows/references/release-note-types.md` (§1 destination map, §2 classification order, §3 draft shape, §4 prose rules, §5 deprecation, §6 general rules, §7 sourcing) and repair any other mismatch.

2. **Dead `rendered` field name.** In the agent's Hard rules, the Jira-ID prohibition lists `context_label`, `feature_title`, `prose`, or `rendered`. The per-entry `rendered` field no longer exists — Step 9 flattened the schema to `combined_rendered`. Change that one name.

3. **Stale `entries` wording in the handoff status table.** The `OK` row reads "Draft rendered; every entry has a confident context label and prose." Replace with: `Draft rendered; the Summary has its prose and, when the import supplied one, its context label.`

4. **Missing `docs_grounding` in the handoff Input block.** The agent lists `docs_grounding` as an input but the handoff contract never did. Add it to the contract's Input block so the two files agree:

```yaml
docs_grounding:      <optional docs-grounder digest (docs_references + docs_challenges); omit when docs grounding was OFF/EMPTY>
```

- [ ] **Step 10: Run the verification to confirm it passes**

Run the four greps from Step 1, then the staleness checks:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n '§3 Bug fix\|§3 Breaking change\|release version in the prose (§5)' agents/release-notes-writer.md   # expect none
grep -n 'or `rendered`' agents/release-notes-writer.md                                                       # expect none
grep -n 'every entry' references/handoff/release-notes-writer.md                                             # expect none
grep -n 'docs_grounding' references/handoff/release-notes-writer.md                                          # expect 1
```
Expected: the first three return no output; the `destination` grep matches; and of the staleness checks the first three are empty and the last matches once.

- [ ] **Step 11: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/release-notes-writer.md \
        plugins/dev-workflows/references/handoff/release-notes-writer.md
git commit -m "feat(dev-workflows): writer sources the context label and shapes by destination

The {{#context}} label IS the imported release_notes_category — drop the rule
that forbade using it, source it verbatim, and omit the line when the import
carries none. Resolve a destination instead of a label: fixes renders one bare
sentence, the titled destinations render label+title+prose. One Summary per
run, and no Change type: line in the draft."
```

---

### Task 4: Update the `/release-notes` command

**Files:**
- Modify: `plugins/dev-workflows/commands/release-notes.md` — Phase 2 (`:100`), Phase 3 (`:130-140`), Phase 6 (`:167-189`), Phase 8 report (`:236-245`, `:261-262`), Invariants (`:362-363`)

**Interfaces:**
- Consumes: Task 3's input field set and gap kinds; Task 2's §1/§7.
- Produces: the user-visible behavior the spec's verification checks 4–7 assert.

- [ ] **Step 1: Write the failing verification**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# Must be ABSENT once done:
grep -n "context_label_hint\|change_type_hint\|authored_vi_fields\|change_type_divergence" commands/release-notes.md
grep -n "Change-type source:" commands/release-notes.md
grep -n '"Breaking change", "New technology support", "Bug fix", "not applicable"' commands/release-notes.md
# Must be PRESENT once done:
grep -n "RELEASE_NOTES_NOT_RELEVANT" commands/release-notes.md
grep -n "Shaped as:" commands/release-notes.md
```

- [ ] **Step 2: Run it to verify it currently fails**

Expected: the first three match (`:174-178`, `:184-189`, `:241`, `:261`); the last two return nothing. **Corrected 2026-08-13**: the citation was garbled — it does not correspond to any one grep's real output. Re-derived at `fb64314` (the tree state right before this task's own implementation commit `ddc1fb2`): grep 1 (`context_label_hint\|change_type_hint\|authored_vi_fields\|change_type_divergence`) matches `:139-140`, `:174`, `:175`, `:178`, `:241`, `:261`, `:363` (8 lines); grep 2 (`Change-type source:`) matches `:241`, `:262`; grep 3 (the literal enum quote) matches `:187`. The last two greps (`RELEASE_NOTES_NOT_RELEVANT`, `Shaped as:`) do correctly return nothing, confirming the "red" state.

- [ ] **Step 3: Replace Phase 2 step 1 (the worthiness gate)**

Replace:

```
1. **Worthiness.** After Phase 3 reads the ticket (or by reading the VI frontmatter now), check `relevant_for_release_notes` and `release_versions`. If `relevant_for_release_notes != "Yes"` AND `release_versions` is empty/absent, warn and ask:
   ```
   choices: ["Proceed anyway (Recommended)", "Cancel", "Other… (describe)"]
   ```
```

with:

````
1. **Worthiness gate.** Read `relevant_for_release_notes` from the **imported VI frontmatter** under
   `jira_export_root` — either from Phase 3's `jira-reader` handoff or by reading the frontmatter
   directly here. NEVER read it from the authored specs draft.
   - **`false` / `no`** → stop:
     `RELEASE_NOTES_NOT_RELEVANT: <jira_key> is flagged not relevant for release notes; Jira's status rule does not require one.`
     Offer an override for drafting ahead of the flag:
     ```
     choices: ["Cancel — nothing to draft (Recommended)", "Draft anyway — I'll set the flag later", "Other… (describe)"]
     ```
   - **`true` / `yes`** → proceed.
   - **absent** → **proceed silently.** The field defaults to true; absent is not false.

   `release_versions` plays no part in this gate.
````

- [ ] **Step 4: Replace the Phase 3 tail (parse + authored-VI resolution)**

Replace everything from `If \`status: NOT_FOUND\` / \`EMPTY\`…` through the end of the
`**Resolve the authored specs-draft VI (secondary grounding).**` paragraph with:

```
If `status: NOT_FOUND` / `EMPTY`, surface `["Re-enter key", "Cancel"]`.

On `OK`, capture `imported_change_type` and `imported_release_notes_category` from the jira-reader
handoff's `value_increment` block (null when absent). Do NOT parse `release_versions` — the draft
carries one Summary and never names a version. Do NOT read the authored specs-draft VI for these
fields: they are Jira-mirror fields (`${CLAUDE_PLUGIN_ROOT}/references/vi-format.md`), so an authored
VI never carries them.
```

- [ ] **Step 5: Replace the Phase 6 dispatch input list**

Replace the dispatch prompt's input lines with:

```
  > jira_reader_handoff: [the Phase 3 handoff — scoped to the focus Epic's subtree when focus_key is set]
  > diff_summaries:      [the Phase 5 array, or omit when diff grounding was off]
  > docs_grounding:      [the Phase 5.5 digest, or omit when OFF/EMPTY]
  > imported_change_type:            [from Phase 3, else null]
  > imported_release_notes_category: [from Phase 3, else null]
  > run_phase:           [pm | dev — resolved immediately above, in this phase]
  > model_routing:       [the block from Phase 1.5]
  > code_repos:          [the Phase-4 resolved {slug, path} map when diff grounding is on; omit otherwise]
```

Then add this paragraph immediately before the dispatch block, so `run_phase` is resolved before it is passed:

````
**Resolve `run_phase`.** `/release-notes` runs at two points in a VI's life, and the
`release-note-types.md` §4 documentation-link rule depends on which. Reuse the existing signal from
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` §7 — glob the VI's specs dir
(`$SPECS_PATH/specifications/<jira_key>-*/`) for `specification.md` and `design.md`:

- **neither present** → `run_phase: pm`. The feature is not built and its documentation does not
  exist yet, so the note carries no documentation link and the command never asks for one.
- **either present** → `run_phase: dev`. The author may supply a redirect short link that will later
  point at the page `/document` publishes.
- **`$SPECS_PATH` unset or the dir missing** → `run_phase: pm` (the safe default — it only suppresses
  a link, never fabricates one).

This is the same inference `emit-cost` already applies in Phase 11; do not add a question for it.
````

- [ ] **Step 6: Replace the `change_type` gap prompt with the consequence-framed confirmation**

Replace:

```
For a `field: change_type` gap (low-confidence classification), present the writer's
proposed value and let the user confirm or override:
```
```
choices: ["<proposed value> (Recommended)", "Breaking change", "New technology support", "Bug fix", "not applicable", "Other… (describe)"]
```
```
Apply the chosen value to `release_notes_block.change_type` (and thus the draft's leading `Change type:` line).
```

with:

````
For a `field: change_type` gap, the destination was inferred with low confidence — and the
destination decides the draft's whole shape. Confirm it by **consequence**, never by enum label.
This fires ONLY when `imported_change_type` was null; when the Jira dropdown is already set, no
prompt appears.

State the inference, then ask:

> This note reads like a `<proposed type>`, so the draft is shaped as `<shape>` and lands in
> `<destination>`.

```
choices: ["<proposed type> — <its shape>, in <its destination> (Recommended)", "Feature update — titled section with a docs link, in feature-updates.md", "Breaking change — titled section with remediation steps, in breaking-changes.md", "Fix — one self-contained sentence, in fixes.md", "Other… (describe)"]
```

Drop the option that duplicates the recommended one. Apply the choice to
`release_notes_block.change_type` + `destination` and **re-render** the draft in the chosen shape —
switching between `fixes` and a titled destination changes the body structure, not just a label. The
chosen value never becomes text in the draft; the PM still sets the Jira dropdown.
````

- [ ] **Step 7: Replace the Phase 8 report lines**

Replace the four report lines `- Release versions:`, `- Change type:`, `- Release-notes category:`, and `- Change-type source:` with:

```
   - Shaped as: <Feature update | Breaking change | Fix> → <destination file>  (source: <imported | inferred>)
   - Context label: <the {{#context}} value | none — omitted from the draft>
```

Then delete the paragraph:

```
   Handle a `change_type_divergence` gap by printing the divergence note in the
   `Change-type source:` line above (non-blocking; no user prompt).
```

- [ ] **Step 8: Replace the two Invariants**

Replace:

```
- The draft LEADS with a `Change type:` line (one of `Breaking change` / `New technology support` / `Bug fix` / `not applicable`) above a type-aware Summary; when the change deprecates something the Summary carries a deprecation note (end-of-life date required, end-of-support optional). The Change Type label never appears inside the Summary body, and no title or Summary prose names the release version. The pipeline-consumed Summary body is otherwise unchanged.
- Change Type + `release_notes_category` are **sourced** — `change_type_hint` → imported VI frontmatter (jira-reader) → authored specs-draft VI (secondary grounding per `vi-source-resolution.md` §5) → infer; import wins over authored on divergence (non-blocking note). The category is surfaced only, never the `{{#context}}` label.
```

with:

```
- The draft is EXACTLY one Summary, shaped by its destination per `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` §1/§3 — a `{{#context}}` label + `### title` + prose for `breaking-changes` / `feature-updates`, or ONE bare past-tense sentence for `fixes`. It carries NO `Change type:` line, NO `Release-notes category:` line, and no title or prose that names the release version. When the change deprecates something the Summary carries a deprecation note (end-of-life date required, end-of-support optional).
- The `{{#context}}` label IS the imported `release_notes_category`, used verbatim; when the import carries none the line is OMITTED. Change Type is sourced `imported_change_type` → infer, and is confirmed with the user ONLY when it was inferred with low confidence — by shape and destination, never by enum label. Neither field is ever asked for as a Jira dropdown value.
- The run is GATED on the imported `relevant_for_release_notes`: an explicit `false` stops with `RELEASE_NOTES_NOT_RELEVANT` (overridable); absent proceeds silently.
```

- [ ] **Step 9: Run the verification to confirm it passes**

Run the five greps from Step 1.
Expected: the first three return no output; `RELEASE_NOTES_NOT_RELEVANT` and `Shaped as:` both match.

Then confirm no field question survives:

```bash
grep -n 'choices:' commands/release-notes.md | grep -i "breaking change"
```
Expected: exactly one line — the Step 6 confirmation — and every option in it names a shape and a destination file.

- [ ] **Step 10: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/release-notes.md
git commit -m "feat(dev-workflows): /release-notes gates on relevance and stops asking for dropdowns

Phase 2 becomes a real gate on the imported relevant_for_release_notes (absent
is not false). The context-label and Change Type questions go; the only survivor
is a low-confidence shape confirmation whose options name a shape and a
destination file instead of the opaque Jira enum values."
```

---

### Task 5: Canonical docs and version bump

**Files:**
- Modify: `plugins/dev-workflows/README.md:15`, `:17`
- Modify: `CLAUDE.md:112`, `:128`, `:213`, `:215-216`, `:230`
- Modify: `plugins/dev-workflows/CHANGELOG.md` (new entry at top)
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (`version`)

**Interfaces:**
- Consumes: the behavior established in Tasks 1–4.
- Produces: the version string `2.42.0` that Tasks 6 and 7 mirror.

- [ ] **Step 1: Write the failing verification**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '"version": "2.42.0"' plugins/dev-workflows/.claude-plugin/plugin.json
grep -n "^## \\[2.42.0\\]" plugins/dev-workflows/CHANGELOG.md
grep -c "change_type" CLAUDE.md   # WRONG-TARGET (corrected 2026-08-13): unsatisfiable on any tree — Tasks 5/6's own design keeps "change_type" as a legitimate Jira-mirror field name in CLAUDE.md's invariants (an "imported_change_type" substring hit, plus a "does NOT capture ... change_type ..." sentence); re-derived at 4720e28, actual count is 2, both legitimate
```

- [ ] **Step 2: Run it to verify it currently fails**

Expected: the first two return nothing; the third returns a non-zero count.

- [ ] **Step 3: Edit `plugins/dev-workflows/README.md`**

In the `/create-vi` row (`:17`), delete this sentence entirely:

```
When the VI is release-notes-relevant, the grill also captures optional `change_type` (`Breaking change` / `New technology support` / `Bug fix` / `not applicable`) and `release_notes_category` (the Dynatrace Solution) frontmatter, validated by `vi-reviewer` and later consumed by `/release-notes`'s sourcing ladder.
```

and replace it with:

```
Release-notes fields (`release_versions`, `change_type`, `release_notes_category`) are NOT captured — they are Jira dropdowns the PM sets on the ticket and the importer returns on the round-trip.
```

In the `/release-notes` row (`:15`), delete these two sentences (they run from "Reads the ticket," to "…import wins on divergence (non-blocking note)."):

```
Reads the ticket, optionally grounds in merged PR diffs, renders the dynatrace-docs authored release-notes body — a leading `Change type:` line (`Breaking change` / `New technology support` / `Bug fix` / `not applicable`, per `references/release-note-types.md`) above a **type-aware Summary** (Breaking change: benefit-led + Action plan; Bug fix: past-tense, symptom-first, no hedging; New technology support: benefit-led/enumeration shaping), plus an orthogonal deprecation note (end-of-life required, end-of-support optional) when triggered, then title + prose; no IDs, no `{{#internal-note}}`. The Change Type is **sourced**, not just inferred — `change_type_hint` → the re-imported Jira VI frontmatter (via `jira-reader`) → the authored `$SPECS_PATH` draft VI (secondary grounding) → inferred from content; import wins on divergence (non-blocking note).
```

and replace them with:

```
Reads the ticket, optionally grounds in merged PR diffs, and renders **exactly one** dynatrace-docs release-notes Summary, shaped by the destination it routes to (per `references/release-note-types.md`) — a `{{#context}}` label + `### title` + prose for `feature-updates` / `breaking-changes`, or one bare past-tense sentence for `fixes` — plus an orthogonal deprecation note (end-of-life required, end-of-support optional) when triggered; no IDs, no `Change type:` line, no `{{#internal-note}}`. The `{{#context}}` label is the imported `release_notes_category` used verbatim, and the line is omitted when the import carries none. The Change Type is sourced from the import, else inferred, and is confirmed with you only on a low-confidence inference — by shape and destination, never by enum label. The run is gated on the imported `relevant_for_release_notes`.
```

The following sentence ("Runs a light `dt-style-checker` gate, and always writes a persistent draft **file**…") is unchanged.

- [ ] **Step 4: Edit the repo-root `CLAUDE.md`**

At `:112`, replace the `release-note-types.md` description with:

```
`plugins/dev-workflows/references/release-note-types.md` is the **single source of truth** for the release-note **destination map** (`breaking-changes.md` / `feature-updates.md` / `fixes.md`), the per-destination **draft shape** (label + title + prose, vs one bare sentence for `fixes`), the per-destination prose rules, the deprecation-note rule (end-of-life date required, end-of-support optional), and Change Type sourcing (import → infer). It is consulted by `release-notes-writer`; the Change Type is never rendered as text.
```

At `:128`, replace the `/release-notes` workflow line's writer bracket with:

```
[release-notes-writer: resolve destination + shape per destination + source the {{#context}} label + detect deprecation]
```

At `:213`, replace the draft-content invariant with:

```
- The draft is the **authored body only** — for a titled destination a `{{#context}}` label, `### title`, and customer-facing prose; for `fixes` ONE bare past-tense sentence. NEVER a Jira ID/key, a PR link, a `Change type:` line, or a `{{#internal-note}}` block (the docs automation adds the metadata wrapper)
```

Replace the two invariants at `:215-216` with:

```
- The `{{#context}}` label IS the imported `release_notes_category`, used verbatim; absent ⇒ the line is omitted. Change Type is sourced `imported_change_type` → infer, drives destination + shape only, and is confirmed with the user only on a low-confidence inference — by shape and destination, never by enum label
- The Summary is shaped per its destination (breaking → present tense, what breaks, remediation; feature update → benefit-led + a docs/blog link; fixes → one past-tense sentence, no hedging, no internal terms); exactly ONE Summary per run, and no title or prose names the release version
- The run is gated on the imported `relevant_for_release_notes` — an explicit `false` stops with `RELEASE_NOTES_NOT_RELEVANT` (overridable); absent proceeds silently
```

Replace `:230` with:

```
- `/create-vi` does NOT capture `release_versions` / `change_type` / `release_notes_category` — they are Jira-mirror fields per `references/vi-format.md`, set as Jira dropdowns and returned by the importer; `vi-reviewer` neither requires nor validates them
```

- [ ] **Step 5: Add the CHANGELOG entry**

Insert at the top of the entries in `plugins/dev-workflows/CHANGELOG.md`, matching the file's existing heading style:

```markdown
## 2.42.0

- **Release-notes field hygiene — `/create-vi` and `/release-notes` stop asking for Jira dropdowns.** `release_versions`, `change_type`, and `release_notes_category` were filed as PM-authorable VI frontmatter; they are Jira dropdowns the PM sets on the ticket and the importer returns on the round-trip, so they move to the Jira-mirror class in `references/vi-format.md`. `/create-vi` no longer asks for any of them and `vi-reviewer` no longer requires or validates them. A dropdown question earns its place only when the answer changes what the plugin generates — deciding it in a chat window costs exactly what deciding it in Jira costs.
- **`references/release-note-types.md` rewritten as a destination + shape authority.** Evidence from the shipped `dynatrace-docs` corpus: across 852 `{{#context}}` lines in generated release-note snippets, none carries a change type — the Change Type instead routes the note to `breaking-changes.md`, `feature-updates.md`, or `fixes.md`. And `fixes.md` publishes one bare sentence (1 `{{#context}}` line across 57 files) rather than label + title + prose, so classifying a VI as `Bug fix` used to emit an unpublishable shape. The reference now maps Change Type → destination → draft shape, and adopts the docs team's own per-destination prose rules (breaking: present tense + remediation link; feature update: benefit-led + a docs/blog link; fixes: one past-tense sentence).
- **The `{{#context}}` label is now sourced, not guessed.** It is exactly the Dynatrace Solution taxonomy the VI already carries as `release_notes_category` — yet `release-notes-writer` was explicitly forbidden from using it, so it guessed and then asked. The prohibition is gone: the label is the imported `release_notes_category` used verbatim, and the line is omitted when the import carries none.
- **Exactly one Summary per run.** `release_versions` used to emit one Summary block per declared version, but the prose may never name a version — so the blocks were identical. The `(unspecified)` fallback and the `release_version` gap are gone.
- **`/release-notes` is gated on `relevant_for_release_notes`.** An explicit `false` in the *imported* frontmatter stops the run with `RELEASE_NOTES_NOT_RELEVANT` (overridable); an absent value proceeds silently, since the field defaults to true. Previously the check ANDed the flag with `release_versions`, so a VI correctly flagged not-relevant still proceeded whenever a version happened to be set.
- **One question survives, reframed.** A low-confidence *destination* inference is still confirmed — but only when the Jira dropdown is unset, and the options now name each choice's shape and destination file instead of the four opaque enum values.
```

- [ ] **Step 6: Bump the version and correct the marketplace description**

In `plugins/dev-workflows/.claude-plugin/plugin.json`:

1. Change `"version": "2.41.0"` to `"version": "2.42.0"`.
2. In the `description` field, replace this clause:

```
/release-notes classifies a Change Type (Breaking change / New technology support / Bug fix / not applicable), shapes the Summary per type, and sources the type from the imported/authored VI.
```

with:

```
/release-notes routes each note to its destination (breaking-changes / feature-updates / fixes), shapes the Summary per destination, and sources the {{#context}} label from the imported VI.
```

The old text advertises the authored-VI sourcing rung that Task 3 removed, and describes a Change Type label the draft no longer carries. This is the marketplace-facing blurb — the sentence someone reads when deciding whether to install.

- [ ] **Step 6b: Fix the README subagent-table row for `release-notes-writer`**

`plugins/dev-workflows/README.md` has a Sub-agents reference table whose `release-notes-writer` row still describes the old per-version, label-and-title-always behavior. Replace this cell text:

```
Renders the dynatrace-docs authored release-notes body for a Jira VI or ticket: a `{{#context}}` label, `### title`, and customer-facing prose — one entry per declared release version.
```

with:

```
Renders the dynatrace-docs authored release-notes body for a Jira VI or ticket — exactly ONE Summary per run, shaped by the destination it routes to: a `{{#context}}` label + `### title` + prose for `feature-updates` / `breaking-changes`, or one bare past-tense sentence for `fixes`.
```

The rest of the row (no Jira IDs, no PR links, no `{{#internal-note}}`, does not write files, used by `/release-notes`) is unchanged and correct.

- [ ] **Step 7: Run the verification to confirm it passes**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '"version": "2.42.0"' plugins/dev-workflows/.claude-plugin/plugin.json
grep -n "^## \\[2.42.0\\]" plugins/dev-workflows/CHANGELOG.md
grep -n "change_type" CLAUDE.md | grep -v "Jira-mirror\|sourced .imported_change_type"
```
Expected: the first two match; the third returns no output.

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/README.md CLAUDE.md \
        plugins/dev-workflows/CHANGELOG.md \
        plugins/dev-workflows/.claude-plugin/plugin.json
git commit -m "docs(dev-workflows): 2.42.0 — release-notes field hygiene"
```

---

### Task 6: Port to `mgd-claude-plugins` (copy the content files, hand-edit the identity files)

**The two Claude editions are identical in content but NOT byte-identical.** Five files carry edition identity and must never be blind-copied:

| File | What differs |
|---|---|
| `.claude-plugin/plugin.json` | author `Dynatrace Managed` vs `Ivan Gudak`; `homepage` / `repository` point at `Dynatrace-Internal/mgd-claude-plugins` |
| `README.md` | marketplace name `mgd-plugins` vs `ihudak-plugins`; AI-container repo `Dynatrace-Internal/mgd-ai-containers` |
| `LICENSE` | copyright `Dynatrace LLC` vs `Ivan Gudak` |
| `references/dependencies.md` | marketplace name `mgd-plugins` |
| `CHANGELOG.md` | mgd entries carry "(ported from `ihudak-claude-plugins`)" annotations and edition-specific phrasing |

`LICENSE` and `references/dependencies.md` are untouched by this change. The other three need **hand-edits that mirror the canonical content change while preserving mgd identity** — never `cp`.

**Files:**
- Modify in `/workspace/mgd-claude-plugins`: the eight plugin files changed in Tasks 1–5, plus `CLAUDE.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: the finished canonical files from Tasks 1–5.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Confirm the drift is only the known identity set plus this change**

```bash
cd /workspace/mgd-claude-plugins && git status --short
diff -rq /workspace/mgd-claude-plugins/plugins/dev-workflows \
         /workspace/ihudak-claude-plugins/plugins/dev-workflows
```
Expected: the mgd tree is clean, and `diff -rq` reports differences ONLY in

- the five known identity files (`.claude-plugin/plugin.json`, `README.md`, `LICENSE`, `references/dependencies.md`, `CHANGELOG.md`), **and**
- the content files Tasks 1–4 touched (`references/vi-format.md`, `references/release-note-types.md`, `references/handoff/release-notes-writer.md`, `agents/release-notes-writer.md`, `agents/vi-reviewer.md`, `commands/create-vi.md`, `commands/release-notes.md`).

Any *other* difference means the editions drifted in content — stop and report it rather than copying over it.

**Corrected 2026-08-13 (R40, fix round 1):** the "five identity + seven content" expectation (12 total) is **WRONG**. Re-derived at the correct ship pair — canonical `4720e28` (this sub-project's own final fix-wave commit) vs mgd's true pre-port state `f64a69b` (mgd's prior release, immediately before the port commit `2a34a54`; the reviewer's premise for this pairing has been independently confirmed) — a real `git worktree` checkout of both, followed by `diff -rq`, reports **54** differing items, not 12: the 5 identity files + 7 content files (12, as claimed) plus **42** pre-existing files under `references/guidelines/*` and `references/api-guidelines/**` that differ only because canonical's blobs carry CRLF line endings and mgd's carry LF — the same drift class as R38 item 5 and R39 item 7. **Method note:** this 42-file CRLF split is present under both raw-blob comparison (`git show <commit>:<path>`) and an actual on-disk checkout `diff -rq` at this historical commit pair — there is no comparison method at ship time that returns 12; it only disappears if the check is run against **today's** live working trees, where mgd's CRLF has since been brought in line with canonical by unrelated later commits. Consistent with R38 item 5 and R39 item 7, which report the equivalent post-port count as 47 (54 minus the 7 content files this Step-1 baseline still expects as differences, since mgd has not yet received them).

- [ ] **Step 2: Create the branch**

```bash
cd /workspace/mgd-claude-plugins
git checkout -b iv-gu/release-notes-field-hygiene
```

- [ ] **Step 3: Copy the seven content files (safe — no identity in any of them)**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in references/vi-format.md \
         references/release-note-types.md \
         references/handoff/release-notes-writer.md \
         agents/release-notes-writer.md \
         agents/vi-reviewer.md \
         commands/create-vi.md \
         commands/release-notes.md; do
  cp "$f" "/workspace/mgd-claude-plugins/plugins/dev-workflows/$f"
done
```

- [ ] **Step 4: Hand-edit the three identity-bearing files**

Do **not** `cp` these. Apply the same content change while preserving mgd identity:

1. **`plugins/dev-workflows/README.md`** — apply the Task 5 Step 3 replacements (the `/create-vi` row sentence and the two `/release-notes` row sentences). Leave every `mgd-plugins` / `mgd-ai-containers` reference untouched.
2. **`plugins/dev-workflows/CHANGELOG.md`** — add the Task 5 Step 5 entry, but append `(ported from `ihudak-claude-plugins`)` to the first bullet's bolded lead, matching the annotation style of mgd's existing 2.40.0 / 2.41.0 entries.
3. **`plugins/dev-workflows/.claude-plugin/plugin.json`** — change only `"version": "2.41.0"` → `"2.42.0"`. Leave `author`, `homepage`, and `repository` alone.

- [ ] **Step 5: Apply the same `CLAUDE.md` edits**

The mgd repo's root `CLAUDE.md` carries the same invariants. Apply the Task 5 Step 4 replacements to `/workspace/mgd-claude-plugins/CLAUDE.md`. Do **not** copy the canonical `CLAUDE.md` wholesale — it names the canonical repo and marketplace.

- [ ] **Step 6: Verify**

```bash
diff -rq /workspace/mgd-claude-plugins/plugins/dev-workflows \
         /workspace/ihudak-claude-plugins/plugins/dev-workflows
```
Expected: differences in exactly the five known identity files and nothing else. In particular `commands/`, `agents/`, and `references/` (other than `dependencies.md`) must report no differences.

**Corrected 2026-08-13 (R40, fix round 1):** "exactly the five known identity files" is **WRONG**. Re-derived at the ship pair — canonical `4720e28`, mgd `d404a75` (mgd's own final fix-wave commit, same commit message as canonical's — the reviewer's correction to this task's original `2a34a54`, which was mgd's pre-fix-wave port commit, is confirmed correct) — a real `git worktree` checkout of both, followed by `diff -rq`, reports **47** differing items, not 5: the 5 genuine identity files plus the same **42** pre-existing `references/guidelines/*` / `references/api-guidelines/**` CRLF-vs-LF files identified in the Step 1 correction above. `commands/`, `agents/`, and `references/` (other than `dependencies.md` and the CRLF-affected `guidelines`/`api-guidelines` subtrees) genuinely report no differences — the port's content correctness is unaffected. **Method note:** consistent with R38 item 5 (canonical `c7bdac2` / mgd `fce902f` → 47) and R39 item 7 (canonical `25b3628` / mgd `8bc8862` → 47) — all three sub-projects' mgd-parity checks now report the same value under the same method (an actual on-disk `diff -rq` at the ship-commit pair, verified to match raw-blob comparison). None of the three normalizes to a smaller number at ship time; only a same-day diff of today's live working trees would, because mgd's CRLF has since converged with canonical's.

```bash
cd /workspace/mgd-claude-plugins
grep -n "change_type" CLAUDE.md | grep -v "Jira-mirror\|sourced .imported_change_type"
grep -c "mgd-plugins" plugins/dev-workflows/README.md          # must stay > 0
grep -n '"name": "Dynatrace Managed"' plugins/dev-workflows/.claude-plugin/plugin.json
grep -n '"version": "2.42.0"' plugins/dev-workflows/.claude-plugin/plugin.json
```
Expected: the first returns nothing; the last three all match.

- [ ] **Step 6: Commit**

```bash
cd /workspace/mgd-claude-plugins
git add plugins/dev-workflows CLAUDE.md
git commit -m "feat(dev-workflows): 2.42.0 — release-notes field hygiene

Port of ihudak-claude-plugins 2.42.0. /create-vi and /release-notes stop
asking for release_versions, change_type, and release_notes_category;
release-note-types.md becomes a destination + shape authority; the
{{#context}} label is sourced from the imported release_notes_category."
```

---

### Task 7: Port to `ihudak-copilot-plugins` (adapted)

Same content, different layout and trigger syntax. **Do not copy files** — apply the same edits to the Copilot files, then translate.

**Files:**
- Modify: `dev-workflows/skills/_shared/vi-format.md`
- Modify: `dev-workflows/skills/_shared/release-note-types.md`
- Modify: `dev-workflows/skills/_shared/handoff/release-notes-writer.md`
- Modify: `dev-workflows/agents/release-notes-writer.md`
- Modify: `dev-workflows/agents/vi-reviewer.md`
- Modify: `dev-workflows/skills/create-vi/SKILL.md`
- Modify: `dev-workflows/skills/release-notes/SKILL.md`
- Modify: `dev-workflows/README.md`, `dev-workflows/CHANGELOG.md`, `dev-workflows/.plugin/` version file

**Interfaces:**
- Consumes: the finished canonical content from Tasks 1–5.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Record the pre-existing drift**

The Copilot edition is NOT a pure path-substitution of canonical — it carries two real defects in `skills/_shared/handoff/release-notes-writer.md` that the rewrite happens to fix. Confirm them first so the fix is deliberate, not accidental:

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows
grep -n 'release_notes_category: <one of: "Breaking change"' skills/_shared/handoff/release-notes-writer.md
grep -n 'recommended_action: "ask user" | "mark TODO in draft"$' skills/_shared/handoff/release-notes-writer.md
```
Expected: both match. Defect 1 types `release_notes_category` with the `change_type` enum; defect 2 drops the `"note in report"` action. Task 3's Step 9 rewrite replaces both blocks, so both are corrected — note this in the commit message.

- [ ] **Step 2: Create the branch and read the current version**

```bash
cd /workspace/ihudak-copilot-plugins
git checkout -b iv-gu/release-notes-field-hygiene
grep -rn '"version"' dev-workflows/.plugin/ 2>/dev/null || find dev-workflows -maxdepth 2 -name '*.json' | head
```
Record the current version; the bump is a minor increment of *that* line, not `2.42.0`.

- [ ] **Step 3: Apply Tasks 1–5 content to the Copilot files, with three substitutions**

**Read the canonical result from disk, not from this plan.** Tasks 1–5 are committed, so the authoritative content is the canonical files themselves. Print the exact diff to work from:

```bash
git -C /workspace/ihudak-claude-plugins diff main...iv-gu/release-notes-field-hygiene \
  -- plugins/dev-workflows/
```

Then, for each canonical file, open its Copilot counterpart from the Files list above and apply the same content with these substitutions:

| Canonical | Copilot |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/` | `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/` |
| `/release-notes`, `/create-vi` (as command names) | `release-notes:`, `create-vi:` |
| "the command" / "the `/release-notes` command" (prose) | "the skill" / "the `release-notes:` skill" |

Everything else — the destination map, the shape rules, the prose rules, the gate, the confirmation prompt — is identical text.

- [ ] **Step 4: Verify the substitutions left no canonical artifacts**

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows
grep -rn 'CLAUDE_PLUGIN_ROOT' skills/_shared/release-note-types.md skills/_shared/vi-format.md \
        skills/create-vi/SKILL.md skills/release-notes/SKILL.md
grep -rn '/release-notes\b' skills/release-notes/SKILL.md skills/_shared/release-note-types.md
```
Expected: both return no output. **Corrected 2026-08-13**: the first does; the second does not — re-derived at copilot `4d31a8f`, it returns one line, `skills/_shared/release-note-types.md:15`, a path false positive (`.../_snippets/release-notes/<product>/<sprint>/`, not a canonical `/release-notes` command reference). Not a real leak; the check's pattern is over-broad for that one line.

- [ ] **Step 5: Verify the content changes landed**

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows
grep -rn "context_label_hint\|change_type_hint\|authored_vi_fields\|change_type_divergence" \
  skills/ agents/release-notes-writer.md
grep -n "RELEASE_NOTES_NOT_RELEVANT" skills/release-notes/SKILL.md
grep -n "no label, no title" skills/_shared/release-note-types.md
```
Expected: the first returns no output; the last two match.

- [ ] **Step 6: Bump the version and add the CHANGELOG entry**

Use the Task 5 Step 5 CHANGELOG text with the same three substitutions applied, plus one extra bullet:

```markdown
- **Two long-standing contract defects corrected.** `skills/_shared/handoff/release-notes-writer.md` typed `release_notes_category` with the `change_type` enum (it is a free-text Dynatrace Solution name) and omitted `"note in report"` from `recommended_action`. Both blocks were rewritten by this change.
```

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add dev-workflows
git commit -m "feat(dev-workflows): release-notes field hygiene

Copilot port of ihudak-claude-plugins 2.42.0. create-vi: and release-notes:
stop asking for release_versions, change_type, and release_notes_category;
release-note-types.md becomes a destination + shape authority; the
{{#context}} label is sourced from the imported release_notes_category.

Also corrects two pre-existing contract defects in the writer handoff:
release_notes_category was typed with the change_type enum, and
recommended_action was missing \"note in report\"."
```

---

## Final verification (all three editions)

Run after Task 7. These are the spec's verification checks 1–4; checks 5–7 are end-to-end runs that need a real VI export and are exercised manually.

- [ ] **Check 1 — no dead inputs anywhere**

```bash
for r in /workspace/ihudak-claude-plugins/plugins/dev-workflows \
         /workspace/mgd-claude-plugins/plugins/dev-workflows \
         /workspace/ihudak-copilot-plugins/dev-workflows; do
  echo "== $r"
  grep -rn "context_label_hint\|change_type_hint\|authored_vi_fields\|change_type_divergence" "$r" \
    --include=*.md | grep -v CHANGELOG
done
```
Expected: no matches in any edition.

- [ ] **Check 2 — `release_versions` survives only as a Jira-mirror mention**

```bash
for r in /workspace/ihudak-claude-plugins/plugins/dev-workflows \
         /workspace/mgd-claude-plugins/plugins/dev-workflows \
         /workspace/ihudak-copilot-plugins/dev-workflows; do
  echo "== $r"
  grep -rn "release_versions" "$r" --include=*.md | grep -v CHANGELOG
done
```
Expected: matches only in `vi-format.md`'s Jira-mirror paragraph and `README.md`'s "are NOT captured" sentence. **Corrected 2026-08-13**: this undercounted. Re-derived at canonical `4720e28` (mgd `2a34a54`, copilot `4d31a8f`): canonical has 6 legitimate matches — `README.md:17`, `commands/create-vi.md:118`, `commands/release-notes.md:114`, `commands/release-notes.md:144`, `references/vi-format.md:39`, `agents/vi-reviewer.md:23` — all Jira-mirror/"NOT captured"/"plays no part"/"do NOT parse" statements, none a dead field reference; mgd and copilot carry the same set (copilot's `agents/vi-reviewer.md` and `skills/` counterparts). No fix needed to plugin content — the check's stated expectation was too narrow, not the shipped result.

- [ ] **Check 3 — the label prohibition is gone**

```bash
grep -rn "never the {{#context}} label\|NEVER as the" \
  /workspace/*/plugins/dev-workflows /workspace/ihudak-copilot-plugins/dev-workflows \
  --include=*.md 2>/dev/null | grep -v CHANGELOG
```
Expected: no matches.

- [ ] **Check 4 — the only change-type prompt is consequence-framed**

```bash
for f in /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/release-notes.md \
         /workspace/mgd-claude-plugins/plugins/dev-workflows/commands/release-notes.md \
         /workspace/ihudak-copilot-plugins/dev-workflows/skills/release-notes/SKILL.md; do
  echo "== $f"; grep -n 'choices:' "$f" | grep -i "breaking change"
done
```
Expected: exactly one line per file, and every option in it names a shape and a destination file.

- [ ] **Check 5 — push the three branches**

```bash
for r in /workspace/ihudak-claude-plugins /workspace/mgd-claude-plugins /workspace/ihudak-copilot-plugins; do
  git -C "$r" push -u origin iv-gu/release-notes-field-hygiene
done
```

Then open a PR per repo. Reinstall to pick the change up locally:

```bash
claude plugin reinstall dev-workflows@ihudak-plugins
```

# Release-note Change Type + type-aware Summary — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `/release-notes` a Change Type (Breaking change / New technology support / Bug fix / not applicable), a type-aware Summary, and deprecation notes (EOL required, end-of-support optional); and refresh `dt-style-guide` terminology from the upstream curated digest.

**Architecture:** A new source-of-truth reference (`release-note-types.md`) holds the taxonomy + shaping + deprecation rules. `release-notes-writer` consults it, proposes a `change_type`, shapes the Summary, detects deprecation, and returns gaps for low-confidence type / missing EOL date. The `/release-notes` command resolves those gaps through its existing gaps→ask-the-user flow and renders a draft that leads with a `Change type:` line above the unchanged Summary body. Terminology sync is an independent additive edit to `dt-style-guide`.

**Tech Stack:** Markdown agent prompts, reference docs, and slash-command specs for the Claude Code `dev-workflows` and `dt-style-guide` plugins. No runtime code; verification is grep-based cross-reference checks + dry-run walkthroughs.

## Global Constraints

- **Design source of truth:** `docs/superpowers/specs/2026-07-17-release-note-change-type-design.md`. Copy rules verbatim from it.
- **The four Change Type values (exact strings):** `Breaking change`, `New technology support`, `Bug fix`, `not applicable`.
- **The type label appears ONLY on the draft's separate `Change type:` line — never inside the `{{#context}}` Summary body.**
- **No release version in any title or Summary prose** ("Starting with version 1.305…", "in 344", etc. are forbidden); the writer still emits one Summary block per declared release version, but the prose never names the version.
- **Never invent EOL / end-of-support dates** — record a `gaps[]` entry and place a `<!-- TODO: end-of-life date -->` placeholder instead.
- **Pipeline untouched:** no change to the Jira → dynatrace-docs rendering, macros, or export/frontmatter schema. Existing no-Jira-ID / no-PR-link / no-`{{#internal-note}}` invariants stay.
- **New field names (use verbatim across all files):** input `change_type_hint`; output top-level `change_type` on `release_notes_block`; gap reasons `field: change_type` and `field: deprecation_eol`.
- **Plugin-file reference convention:** inside agent/reference bodies use `${CLAUDE_PLUGIN_ROOT}/...`; never hardcode cache paths.
- **Commits:** this repo commits only on explicit user request. All work is on branch `feat/release-note-change-type`. If the user has NOT authorized commits, do every edit + verification step and **skip the commit step** (hold the changes on the branch). Each task's commit step below is written for the authorized case.

---

### Task 1: Create the `release-note-types.md` source-of-truth reference

**Files:**
- Create: `plugins/dev-workflows/references/release-note-types.md`

**Interfaces:**
- Consumes: nothing (foundation).
- Produces: the taxonomy, classification order, per-type shaping rules, deprecation rule, and general rules that `release-notes-writer` (Task 3) cites via `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md`. Establishes the gap reasons `change_type` and `deprecation_eol` and the `<!-- TODO: end-of-life date -->` placeholder token.

- [ ] **Step 1: Write the reference file** with exactly this content:

````markdown
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
````

- [ ] **Step 2: Verify the file exists and the four exact type strings are present**

Run: `grep -c -E 'Breaking change|New technology support|Bug fix|not applicable' plugins/dev-workflows/references/release-note-types.md`
Expected: a count ≥ 4 (all four values present).

- [ ] **Step 3: Verify the gap-reason tokens and placeholder are present**

Run: `grep -nE 'field: change_type|field: deprecation_eol|end-of-life date -->' plugins/dev-workflows/references/release-note-types.md`
Expected: all three tokens appear.

- [ ] **Step 4: Commit** (only if commits authorized — see Global Constraints)

```bash
git add plugins/dev-workflows/references/release-note-types.md
git commit -m "feat(dev-workflows): add release-note-types source-of-truth reference"
```

---

### Task 2: Extend the `release-notes-writer` handoff contract

**Files:**
- Modify: `plugins/dev-workflows/references/handoff/release-notes-writer.md`

**Interfaces:**
- Consumes: the field names from Task 1 / Global Constraints.
- Produces: the input field `change_type_hint`; the output top-level `change_type` on `release_notes_block`; the two new `gaps[]` reasons. Task 3 (agent) and Task 4 (command) both rely on this contract.

- [ ] **Step 1: Add `change_type_hint` to the Input block.** Replace:

```yaml
context_label_hint:  <optional 1–2 short category labels the user suggested; null otherwise>
```

with:

```yaml
context_label_hint:  <optional 1–2 short category labels the user suggested; null otherwise>
change_type_hint:    <optional; a user-supplied Change Type and/or deprecation signal
                      (e.g. "Breaking change", "new feature + deprecation"); null otherwise>
```

- [ ] **Step 2: Add `change_type` as a top-level field of `release_notes_block`.** Replace:

```yaml
release_notes_block:
  target_format: dynatrace-docs-release-notes-v1
  entries:
```

with:

```yaml
release_notes_block:
  target_format: dynatrace-docs-release-notes-v1
  change_type: <one of: "Breaking change" | "New technology support" | "Bug fix" | "not applicable">   # the note's Change Type (per note, not per release version); classified by the agent via references/release-note-types.md
  entries:
```

- [ ] **Step 3: Document the `change_type` and `deprecation_eol` gap reasons.** Replace:

```yaml
gaps:
  - field:              <context_label | feature_title | prose | release_version>
    reason:             <why this is low-confidence or missing>
    recommended_action: "ask user" | "mark TODO in draft"
```

with:

```yaml
gaps:
  - field:              <context_label | feature_title | prose | release_version | change_type | deprecation_eol>
    reason:             <why this is low-confidence or missing. For change_type: the classification is low-confidence (source supports two types); the proposed value is still set on release_notes_block.change_type. For deprecation_eol: a deprecation was detected but the required end-of-life date is not derivable from the source (or a deprecation-signaling change_type_hint left the dates unclear).>
    recommended_action: "ask user" | "mark TODO in draft"
```

- [ ] **Step 4: Note that `combined_rendered` leads with the `Change type:` line.** Replace:

```yaml
  combined_rendered: |
    <all entries' `rendered` blocks concatenated, separated by one blank line>
```

with:

```yaml
  combined_rendered: |
    <a leading "Change type: <release_notes_block.change_type>" line, then a
    "--- Summary (paste into release-notes field) ---" divider (a human copy guide, not
    pasted), then all entries' `rendered` blocks concatenated, separated by one blank
    line. The Change Type label appears ONLY on this leading line, never inside an
    entry's rendered Summary body.>
```

- [ ] **Step 5: Verify the contract is internally consistent**

Run: `grep -nE 'change_type_hint|change_type:|deprecation_eol|Change type:' plugins/dev-workflows/references/handoff/release-notes-writer.md`
Expected: `change_type_hint` (input), `change_type:` (output block), `deprecation_eol` (gaps), and `Change type:` (combined_rendered) all present.

- [ ] **Step 6: Commit** (only if commits authorized)

```bash
git add plugins/dev-workflows/references/handoff/release-notes-writer.md
git commit -m "feat(dev-workflows): add change_type + deprecation_eol to release-notes-writer handoff"
```

---

### Task 3: Teach `release-notes-writer` to classify, shape, and detect deprecation

**Files:**
- Modify: `plugins/dev-workflows/agents/release-notes-writer.md`

**Interfaces:**
- Consumes: `references/release-note-types.md` (Task 1); the handoff contract (Task 2) — `change_type_hint` in, `change_type` + gaps out.
- Produces: an agent that emits `release_notes_block.change_type`, a type-shaped `prose`, an optional deprecation note, a `combined_rendered` leading with `Change type:`, and the two new gaps. The command (Task 4) consumes these.

- [ ] **Step 1: Add `change_type_hint` to the Inputs block.** In the `## Inputs` YAML, replace:

```yaml
context_label_hint:  <optional category labels; null otherwise>
```

with:

```yaml
context_label_hint:  <optional category labels; null otherwise>
change_type_hint:    <optional user-supplied Change Type and/or deprecation signal; null otherwise>
```

- [ ] **Step 2: Insert a Classify + Detect-deprecation step at the top of `## Process`.** Immediately after the `## Process` heading and before the current `1. **Gather substance.**`, insert a new numbered step and renumber is NOT required (insert as step 1, shifting the rest by hand in Step 3 below). Insert:

```markdown
1. **Classify the Change Type.** Determine the note's Change Type per
   `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` §1–§2: use `change_type_hint`
   when provided, otherwise infer from the VI/ticket content. Set
   `release_notes_block.change_type` to one of `Breaking change` /
   `New technology support` / `Bug fix` / `not applicable`. When the classification is
   low-confidence (the source supports two types roughly equally), still set the proposed
   value and add a `gaps[]` entry (`field: change_type`, `recommended_action: "ask
   user"`).

2. **Detect deprecation.** Apply the §4 deprecation trigger: scan the VI content
   (`## What`, "Current vs Target State", explicit "deprecat*" wording) and honor a
   deprecation-signaling `change_type_hint`. When triggered, the Summary must carry a
   deprecation note with a **required end-of-life date** and an **optional
   end-of-support date**. Never invent a date: when the required end-of-life date is not
   derivable, add a `gaps[]` entry (`field: deprecation_eol`, `recommended_action: "ask
   user"`) and use a `<!-- TODO: end-of-life date -->` placeholder in the prose.
```

- [ ] **Step 3: Renumber the existing Process steps.** The steps currently numbered `1.`–`5.` (`Gather substance` … `Source-truth check`) become `3.`–`7.`. Update the leading digits only; keep the step bodies unchanged except Step 4 below.

- [ ] **Step 4: Make the body-building step type-aware.** In the (now step 5) `**Per entry, build the authored body:**` block, replace the `- **Body** — customer-facing content:` bullet's opening sentence:

```markdown
   - **Body** — customer-facing content: what users can now do and why it matters.
     Do NOT stop at a faithful summary — apply light **editorial shaping** so the
     entry is scannable and the important path stands out. Choose the shape from the
     content:
```

with:

```markdown
   - **Body** — customer-facing content shaped by the classified Change Type per
     `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` §3. For a **Bug fix**, use
     the §3 Bug fix rules (past tense, lead with the resolution, include triggering
     conditions, no hedging, no jargon/code, no internal workflow terms). For a
     **Breaking change**, use the §3 Breaking change rules (lead with the benefit, state
     what changes and what breaks, add an **Action plan** when the customer must act).
     For **New technology support**, use the benefit-led editorial shaping below. When a
     deprecation was detected (Process step 2), append the deprecation note (what is
     deprecated + end-of-life date, optional end-of-support date, or the `<!-- TODO:
     end-of-life date -->` placeholder). Never name the release version in the prose
     (§5). Choose the New-technology-support shape from the content:
```

- [ ] **Step 5: Update the Render step to emit the `Change type:` line + divider.** Replace the `4. **Render** each entry as exactly:` block and its `Concatenate entries…` sentence:

```markdown
4. **Render** each entry as exactly:

   ```handlebars
   {{#context}}<context_label>{{/context}}

   ### <feature_title>

   <prose>
   ```

   Concatenate entries (blank-line separated) into `combined_rendered`.
```

with (note the step number becomes `6.` after renumbering in Step 3):

```markdown
6. **Render.** Render each entry's Summary body as exactly:

   ```handlebars
   {{#context}}<context_label>{{/context}}

   ### <feature_title>

   <prose>
   ```

   Build `combined_rendered` as: a leading `Change type: <change_type>` line, then a
   `--- Summary (paste into release-notes field) ---` divider (a human copy guide, not
   pasted), then the entries' Summary bodies concatenated (blank-line separated). The
   Change Type label appears ONLY on the leading line — NEVER inside an entry's Summary
   body.
```

- [ ] **Step 6: Add hard rules for the type line and dates.** In `## Hard rules`, after the `- When code_repos is provided, NEVER silently emit a claim the source contradicts…` bullet, add:

```markdown
- ALWAYS set `release_notes_block.change_type` to one of the four exact values; when
  low-confidence, still set the proposed value and record a `field: change_type` gap.
- NEVER place the Change Type label inside a `{{#context}}` Summary body — it belongs
  only on the leading `Change type:` line of `combined_rendered`.
- NEVER name the release version in any `feature_title` or `prose` (it is a separate
  Jira field the PM sets).
- NEVER invent an end-of-life or end-of-support date; record a `field: deprecation_eol`
  gap and use the `<!-- TODO: end-of-life date -->` placeholder instead.
```

- [ ] **Step 7: Update the frontmatter description** to mention the type line. Replace the description's ending `Emits NO Jira IDs, NO PR links, and NO {{#internal-note}} block (the docs automation adds that).` with:

```
Leads the draft with a Change type: line (Breaking change / New technology support / Bug fix / not applicable) above a type-aware Summary, and adds a deprecation note (end-of-life date required, end-of-support optional) when the change deprecates something. Emits NO Jira IDs, NO PR links, and NO {{#internal-note}} block (the docs automation adds that).
```

- [ ] **Step 8: Verify the agent references the reference doc and defines the new fields/rules**

Run: `grep -nE 'release-note-types\.md|change_type_hint|change_type|deprecation_eol|Change type:' plugins/dev-workflows/agents/release-notes-writer.md`
Expected: the reference path, `change_type_hint`, `change_type`, `deprecation_eol`, and `Change type:` all appear.

Run: `grep -nE '^[0-9]+\. \*\*' plugins/dev-workflows/agents/release-notes-writer.md | head`
Expected: Process steps numbered 1–7 with no duplicate/skip.

- [ ] **Step 9: Commit** (only if commits authorized)

```bash
git add plugins/dev-workflows/agents/release-notes-writer.md
git commit -m "feat(dev-workflows): classify Change Type, shape per type, detect deprecation in release-notes-writer"
```

---

### Task 4: Wire the `/release-notes` command to the new type + deprecation flow

**Files:**
- Modify: `plugins/dev-workflows/commands/release-notes.md`

**Interfaces:**
- Consumes: the agent output from Task 3 (`change_type`, gaps `change_type` / `deprecation_eol`, the `combined_rendered` leading with `Change type:`).
- Produces: user-facing gap resolution for type + EOL dates, a report that states the Change Type and any deprecation, and a new invariant.

- [ ] **Step 1: Pass `change_type_hint` in the Phase 6 render brief.** In the `→ Agent (subagent_type: "dev-workflows:release-notes-writer")` brief, after the `context_label_hint:  [user hint if any, else null]` line add:

```
  > change_type_hint:   [user-supplied Change Type and/or deprecation signal if any, else null]
```

- [ ] **Step 2: Add change_type + deprecation gap handling in Phase 6.** Immediately after the sentence `If \`status: PARTIAL\`, surface each \`gaps\` entry with \`recommended_action: "ask user"\` and let the user supply the label/prose or accept a \`<!-- TODO -->\` marker.` insert:

```markdown

For a `field: change_type` gap (low-confidence classification), present the writer's
proposed value and let the user confirm or override:
```
choices: ["<proposed value> (Recommended)", "Breaking change", "New technology support", "Bug fix", "not applicable", "Other… (describe)"]
```
Apply the chosen value to `release_notes_block.change_type` (and thus the draft's leading `Change type:` line).

For a `field: deprecation_eol` gap (a deprecation was detected but the required
end-of-life date is unclear), ask the user:
```
choices: ["Enter the end-of-life date (you'll be prompted; end-of-support optional)", "Leave the <!-- TODO: end-of-life date --> marker in the draft", "This isn't a deprecation — drop the note", "Other… (describe)"]
```
On a supplied date, replace the `<!-- TODO: end-of-life date -->` placeholder with the
end-of-life date (and end-of-support date when given), formatted per the dt-style-guide
(e.g. `November 30, 2026`).
```

- [ ] **Step 3: Report the Change Type and deprecation in Phase 8.** In the `## Release-notes draft — <jira_key>` report block, after the `- Release versions: <list, or "none declared">` line add:

```markdown
   - Change type: <Breaking change | New technology support | Bug fix | not applicable>
   - Deprecation: <EOL <date> (end-of-support <date | —>) | none>
```

- [ ] **Step 4: Add the invariant.** In `## Invariants (always enforced)`, after the `- The draft contains NO Jira IDs/keys, NO PR links, and NO \`{{#internal-note}}\` block.` line add:

```markdown
- The draft LEADS with a `Change type:` line (one of `Breaking change` / `New technology support` / `Bug fix` / `not applicable`) above a type-aware Summary; when the change deprecates something the Summary carries a deprecation note (end-of-life date required, end-of-support optional). The Change Type label never appears inside the Summary body, and no title or Summary prose names the release version. The pipeline-consumed Summary body is otherwise unchanged.
```

- [ ] **Step 5: Verify the command wires every new field**

Run: `grep -nE 'change_type_hint|Change type:|deprecation_eol|end-of-life date' plugins/dev-workflows/commands/release-notes.md`
Expected: `change_type_hint` (Phase 6 brief), `Change type:` (report + invariant), `deprecation_eol` (gap handling), `end-of-life date` (gap prompt) all present.

- [ ] **Step 6: Commit** (only if commits authorized)

```bash
git add plugins/dev-workflows/commands/release-notes.md
git commit -m "feat(dev-workflows): surface Change Type + deprecation in /release-notes flow"
```

---

### Task 5: Register the reference and invariants in `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: the reference path and behavior from Tasks 1–4.
- Produces: repo documentation that keeps the Surgical-Changes guardrail satisfied (no dangling references).

- [ ] **Step 1: Register the new reference.** In the `## Source-truth reference` section, after the existing `source-truth.md` paragraph, add:

```markdown
`plugins/dev-workflows/references/release-note-types.md` is the **single source of truth** for the release-note Change Type taxonomy (`Breaking change` / `New technology support` / `Bug fix` / `not applicable`), the classification order, the per-type Summary shaping rules, and the deprecation-note rule (end-of-life date required, end-of-support optional). It is consulted by `release-notes-writer`; the `/release-notes` command applies its decisions through the writer's gaps.
```

- [ ] **Step 2: Update the `/release-notes` workflow-map line.** In the ```dev-workflows workflow relationships``` block, replace:

```
/release-notes       → jira-reader → [diff-summarizer×N (parallel, optional)] → [release-notes-writer] → [dt-style-checker → dt-doc-fixer (optional)] → write draft (paste into Jira)
```

with:

```
/release-notes       → jira-reader → [diff-summarizer×N (parallel, optional)] → [release-notes-writer: classify Change Type + shape per type + detect deprecation] → [dt-style-checker → dt-doc-fixer (optional)] → write draft (Change type: line + Summary; paste into Jira)
```

- [ ] **Step 3: Add release-notes invariants.** In the `Key invariants for \`/release-notes\`:` list, after the bullet beginning `- The draft is the **authored body only**` add:

```markdown
- The draft LEADS with a `Change type:` line — one of `Breaking change` / `New technology support` / `Bug fix` / `not applicable` — classified by `release-notes-writer` via `references/release-note-types.md`; the label never appears inside the Summary body
- The Summary is shaped per the Change Type (breaking → benefit-led + action plan; bug fix → past-tense, no hedging, no internal terms; new-tech → benefit-led editorial shaping); no title or Summary prose names the release version
- A deprecation carries a deprecation note in the Summary — end-of-life date (required) + end-of-support date (optional); a missing required date becomes a `deprecation_eol` gap the command asks about (never invented)
```

- [ ] **Step 4: Verify CLAUDE.md references resolve**

Run: `grep -nE 'release-note-types\.md|Change type:|deprecation' CLAUDE.md`
Expected: the reference path appears in the source-truth section and the invariants; workflow-map line updated.

Run: `test -f plugins/dev-workflows/references/release-note-types.md && echo OK`
Expected: `OK` (the registered reference actually exists).

- [ ] **Step 5: Commit** (only if commits authorized)

```bash
git add CLAUDE.md
git commit -m "docs: register release-note-types reference and /release-notes Change Type invariants"
```

---

### Task 6: Sync `dt-style-guide` terminology from the upstream curated digest

**Files:**
- Modify: `plugins/dt-style-guide/references/word-list.md` (and `terminology.md` if the entry belongs there)
- Modify: `plugins/dt-style-guide/CHANGELOG.md`
- Modify: `plugins/dt-style-guide/.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: the upstream digest at `/workspace/specs/.claude/skills/dynatrace-content-style/assets/terminology.md`.
- Produces: enriched terminology references (additive) + a version bump. Independent of Tasks 1–5.

- [ ] **Step 1: Read both sides to plan the diff.**

Run: `sed -n '1,200p' plugins/dt-style-guide/references/word-list.md`
Run: `sed -n '1,200p' /workspace/specs/.claude/skills/dynatrace-content-style/assets/terminology.md`
Identify upstream entries absent from our references. Confirmed-missing baseline: `timeframe selector`, `Strato Design System`, "around the clock" (as the replacement for `24/7` / `24x7`).

- [ ] **Step 2: Add the missing entries additively** to `word-list.md` (preferred-term table) and/or `terminology.md`, matching the existing table/section format of the target file. Do NOT remove or rewrite existing scraped entries. At minimum add: `timeframe selector` (avoid: global time picker / time picker), `Strato Design System` (capitalize both words; avoid: design system), and `around the clock` / "avoid 24/7 and 24x7". Fold in any further upstream-only entries found in Step 1.

- [ ] **Step 3: Add a CHANGELOG entry.** Prepend an entry under a new version heading in `plugins/dt-style-guide/CHANGELOG.md` describing "Synced curated terminology from mgd-specifications dynatrace-content-style digest (timeframe selector, Strato Design System, around the clock, …)".

- [ ] **Step 4: Bump the version.** In `plugins/dt-style-guide/.claude-plugin/plugin.json`, bump `"version": "0.2.2"` to `"0.2.3"` (match the CHANGELOG heading).

- [ ] **Step 5: Verify the entries and version bump landed**

Run: `grep -niE 'timeframe selector|Strato Design System|around the clock' plugins/dt-style-guide/references/*.md`
Expected: all three now present.

Run: `grep -n '"version"' plugins/dt-style-guide/.claude-plugin/plugin.json && grep -n '0.2.3' plugins/dt-style-guide/CHANGELOG.md`
Expected: version is `0.2.3` and the CHANGELOG has a matching heading.

- [ ] **Step 6: Commit** (only if commits authorized)

```bash
git add plugins/dt-style-guide/references/ plugins/dt-style-guide/CHANGELOG.md plugins/dt-style-guide/.claude-plugin/plugin.json
git commit -m "feat(dt-style-guide): sync curated terminology from mgd-specifications digest; bump to 0.2.3"
```

---

### Task 7: Final cross-reference verification + dry-run

**Files:** none (verification only).

- [ ] **Step 1: No dangling field references.** Confirm every new field is declared AND consumed.

Run: `grep -rnE 'change_type_hint|deprecation_eol' plugins/dev-workflows/`
Expected: `change_type_hint` appears in the handoff (input), the agent (Inputs + Process), and the command (Phase 6 brief). `deprecation_eol` appears in the reference, the handoff (gaps), the agent (Process + hard rules), and the command (gap handling).

- [ ] **Step 2: Type-label-in-body contradiction check.** Confirm the "type label only on the `Change type:` line" rule is stated consistently and not contradicted.

Run: `grep -rnE 'Change type:|never inside|NEVER place the Change Type' plugins/dev-workflows/`
Expected: the reference (§5), the agent (hard rules + render step), the command (invariant), and the handoff all agree the label is only on the leading line.

- [ ] **Step 3: Dry-run the PRODUCT-14900 example (mental trace, no execution).** Read `plugins/dev-workflows/references/release-note-types.md` and `plugins/dev-workflows/agents/release-notes-writer.md` and confirm, for the AWS-Lambda-in-GovCloud VI (adds GovCloud region support; "classic layers … subject to being deprecated"):
  - classification → `New technology support`;
  - deprecation trigger fires on "deprecated"; required EOL date not in source → `deprecation_eol` gap + `<!-- TODO -->` placeholder;
  - `combined_rendered` leads with `Change type: New technology support`, then the divider, then the `{{#context}}` Summary with a deprecation `> Note:`;
  - no release version named in the prose.
  Write a 4–6 line confirmation of this trace as the task output.

- [ ] **Step 4: Reinstall note (manual, informational).** Record in the final summary that the user should run `claude plugin reinstall dev-workflows@ihudak-plugins` and `claude plugin reinstall dt-style-guide@ihudak-plugins` after merge to pick up the changes.

---

## Self-Review (completed by plan author)

**1. Spec coverage:** Spec Component 1 → Task 1; Component 2 (agent) → Task 3; Component 2 handoff → Task 2; Component 3 (command) → Task 4; Component 4 (CLAUDE.md) → Task 5; Component 5 (terminology) → Task 6; Verification section → grep steps per task + Task 7. The `change_type_hint` deprecation-signal refinement is covered in Task 1 §4, Task 3 Step 2, and Task 4 Step 2. No uncovered spec requirement.

**2. Placeholder scan:** No "TBD/TODO/implement later" as plan instructions. The literal `<!-- TODO: end-of-life date -->` is an intended product artifact (a draft placeholder token), not a plan gap.

**3. Type consistency:** Field names are identical everywhere — `change_type_hint` (input), `change_type` (output block field), gap reasons `change_type` / `deprecation_eol`, placeholder `<!-- TODO: end-of-life date -->`, and the four exact Change Type strings. The `Change type:` leading line is spelled consistently across handoff, agent, command, and CLAUDE.md.

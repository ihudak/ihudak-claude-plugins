---
tags:
  - tasks-exclude
---
# /epics Quality Uplift Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/epics` Epic decomposition auditable (requirement→Epic coverage + gap-detection), honest about unknowns (`[NEEDS CLARIFICATION]` markers), independently-shippable (no-forward-dependency check), and architecture-consistent (ARD wiring), by folding in BMAD + SpecKit-validated ideas.

**Architecture:** Pure markdown/prompt-engineering change to the dev-workflows plugin — four agent/command files + one shared reference + manifests + CHANGELOG. No new agent, no new command. Data flows through a shared requirement inventory (`jira-reader` → `epic-writer` + `epic-reviewer` + `epics.md`) so the reviewer independently verifies coverage. ARD wiring mirrors the existing `/specify` Phase 2.5 pattern.

**Tech Stack:** Markdown command/agent definitions; JSON manifests. **No test framework, no husky/prettier hook** — verification is STRUCTURAL (grep anchors, `python3 -c json.load`, `git diff --stat`, byte-diff).

## Global Constraints

- **Version:** `2.20.0` → `2.21.0` in BOTH `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of root `.claude-plugin/marketplace.json` — lock-step.
- **Counts unchanged:** 19 commands / 29 agents. The marketplace description strings `Nineteen slash commands` and `Twenty-nine reusable subagents` stay byte-identical.
- **Siblings byte-identical:** `dt-style-guide` (0.2.2) + `obsidian-llm-wiki` (0.3.1) — never touched.
- **Untouched:** `commands/vuln.md`, `commands/upgrade.md`, `commands/document.md`, and every `agents/*` file except `jira-reader.md`, `epic-writer.md`, `epic-reviewer.md`.
- **No-regression:** ARD steps additive, guarded on `status: found` — a run with no ARD / no clarification markers is byte-identical in behavior to today.
- **Commit named files only — NEVER `git add -A`.** Commit trailer EXACTLY:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Branch:** `ivgu/NOISSUE-epics-quality-uplift` off `main` (currently `670626d`). Never commit on `main`.
- `/epics` still **never branches, never commits**, never writes into `jira-products/`, `jira_export_root`, or the cwd.
- **Push only when the user asks.** The vault plan/spec are auto-backed-up by Obsidian Git — do NOT hand-commit them.
- No husky hook installed in this repo; commits need no `--no-verify`.

---

## Task 0: Branch

- [ ] **Step 1: Create the feature branch off main**

```bash
cd /workspace/ihudak-claude-plugins
git checkout main && git pull --ff-only
git checkout -b ivgu/NOISSUE-epics-quality-uplift
git rev-parse --abbrev-ref HEAD   # expect: ivgu/NOISSUE-epics-quality-uplift
```

No commit in this task.

---

## Task 1: `jira-reader` emits `requirements[]`

**Files:**
- Modify: `plugins/dev-workflows/agents/jira-reader.md`

**Interfaces:**
- Produces (consumed by Tasks 2, 3, 4): two new top-level fields in the `jira-reader` output YAML —
  - `requirements_source: native | derived`
  - `requirements: [{ id, type, text }]` where `id` is the VI's native id (`US-N`/`AC-N`/`SM-N`/`FR-N`/`UC-N`) or synthetic `R1..Rn`; `type ∈ story | criterion | metric | functional | usecase | derived`.
- Additive only — `/document` and `/specify` ignore these fields; their behavior is unchanged.

- [ ] **Step 1: Add the extraction process step.**

In `plugins/dev-workflows/agents/jira-reader.md`, find the end of the `## Process` section's step `3. **Extract capability themes.**` block (the paragraph ending "…callers that need richer themes should request `vi-plus-epics` or `full`."). Immediately AFTER that paragraph, insert a new step 4:

```markdown
4. **Extract the requirement inventory.** From the VI's own file
   (`<EXPORT_ROOT>/<jira_key>/<jira_key>.md`, read at every depth), parse the
   VI's native requirement IDs into `requirements[]` and set
   `requirements_source: native`:
   - `## User Stories` → each `### [US-N]: <title>` → `{id: US-N, type: story, text: <title + the As-a/I-want/so-that line>}`.
   - `## Acceptance Criteria` → each `[AC-N]` bullet → `{id: AC-N, type: criterion, text: <bullet>}`.
   - `## Success Metrics` → each `[SM-N]` bullet → `{id: SM-N, type: metric, text: <bullet>}`.
   - `## Functional requirements` (full profile only, when present) → each `FR-N` → `{id: FR-N, type: functional, text: <text>}`.
   - `## Use cases & user journey` (hybrid/full, when present) → each `UC-N` → `{id: UC-N, type: usecase, text: <text>}`.
   Preserve the VI's own IDs verbatim — do not renumber.
   **Fallback (`requirements_source: derived`):** if the VI body contains NONE
   of those structured sections (a legacy VI, or a Description pasted as prose),
   decompose `value_increment.goal` + `themes` into 3–6 synthetic requirements
   `{id: R1.., type: derived, text: <one requirement per line>}`. Never fabricate
   requirements not grounded in the VI text.
```

- [ ] **Step 2: Add the output fields.**

In the same file, in the `## Output` YAML block, find the `value_increment:` block (the lines `key/summary/status/goal`). Immediately AFTER the `goal:` line and BEFORE `linked_items:`, insert:

```yaml
requirements_source: native | derived
requirements:
  - id:   <US-N | AC-N | SM-N | FR-N | UC-N | R1..>   # native VI id, else synthetic
    type: story | criterion | metric | functional | usecase | derived
    text: <requirement text>
```

- [ ] **Step 3: Reinforce the no-fabrication rule.**

In the `## Hard rules` section, find the bullet beginning `- NEVER fabricate items not present in the index or in the linked \`.md\` files.` Append to that same bullet:
` The same rule applies to \`requirements[]\` — extract only IDs/text present in the VI body; the \`derived\` fallback decomposes the VI's own goal/themes, never invents scope.`

- [ ] **Step 4: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
grep -c "requirements_source" plugins/dev-workflows/agents/jira-reader.md   # expect >= 2 (process + output)
grep -c "Extract the requirement inventory" plugins/dev-workflows/agents/jira-reader.md  # expect 1
grep -c "requirements_source: derived" plugins/dev-workflows/agents/jira-reader.md  # expect >= 1
git diff --stat   # expect only agents/jira-reader.md changed
```
Expected: all counts as noted; only `jira-reader.md` in the diff.

- [ ] **Step 5: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/jira-reader.md
git commit -m "$(cat <<'EOF'
NOISSUE feat(epics): jira-reader emits requirement inventory

Add additive requirements[] + requirements_source output fields — parse the
VI's native US/AC/SM/FR/UC IDs, with a goal+themes 'derived' fallback for
degraded VIs. Consumed by epic-writer + epic-reviewer for coverage.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `epic-writer` — template, markers, coverage, ARD-respect

**Files:**
- Modify: `plugins/dev-workflows/agents/epic-writer.md`

**Interfaces:**
- Consumes (from Task 1, passed via the Task-4 handoff file): `requirements[]`, `requirements_source`, `applicable_ard` (or absent), `existing_epic_themes`.
- Produces (consumed by Tasks 3, 4):
  - Each Epic file gains `## Independent Test`, `## Covers` (requirement IDs), Given/When/Then ACs, `[Source: path#Section]` citations, and inline `[NEEDS CLARIFICATION: …]` markers.
  - `output_dir/_coverage.md` (the matrix; format in Task 2 Step 4).
  - Return fields: `clarifications_needed: [{epic, section, question, suggested_answer}]` (empty when none) and `coverage_file: <abs path>`.

- [ ] **Step 1: Add the new inputs to the Inputs section.**

In `plugins/dev-workflows/agents/epic-writer.md`, in `## Inputs`, find the bullet list under "It contains:" ending `- \`vi_goal\`, \`jira_key\``. Append these bullets:

```markdown
- `requirements` + `requirements_source` — the VI requirement inventory (from jira-reader); the coverage ground truth.
- `applicable_ard` — the VI-level ARD `invariants` (AD-N) + `guidance_summary`, or absent when no ARD resolved.
- `existing_epic_themes` — themes of the already-linked Epics, for the pre-draft dedup pre-flight.
```

- [ ] **Step 2: Add the pre-draft dedup + sizing pre-flight.**

In the same file, immediately BEFORE the `## Write mechanics` heading, insert:

```markdown
## Pre-flight (before drafting)

1. **Dedup enumeration.** For each Epic you are about to draft, compare its theme
   against `existing_epic_themes`. If it overlaps an existing Epic, do NOT draft a
   near-duplicate — record in `notes`: `theme <X> already covered by <KEY> → skip | merge`.
2. **Sizing / sequencing.** Prefer fewer, larger Epics when the VI direction is
   already validated; split only at a genuine risk or feedback-loop boundary.
   Order the Epics so that none depends on a later one (supports the reviewer's
   independence check).
```

- [ ] **Step 3: Extend the Epic template.**

In `## Write mechanics`, replace the fenced markdown template block. Find the current block that starts with `# <Epic title>` and ends with the `## References` list (the block ending with `- ...` after the `Parent VI` line). Replace the entire fenced block with:

````markdown
```markdown
# <Epic title>

## Goal
<one sentence, tied concretely to the parent VI's outcome — NOT a technical milestone>

## Business value
<1–2 sentences linking the Epic to the VI's outcome; concrete, not boilerplate>

## Scope

### In scope
- <concretely delimited features/behaviours/surfaces>
- ...

### Out of scope
- <concrete — not "anything else" or "future work">
- ...

## Acceptance criteria
- Given <context>, when <action>, then <observable result>.
- ...

## Independent Test
<one line: this Epic is verifiable standalone by <observable test> and delivers <value> without any not-yet-built Epic>

## Dependencies
- <other Epics under this VI or elsewhere, repos, teams, external systems — named>
- ...

## Covers
- <VI requirement IDs this Epic satisfies, e.g. US-2, AC-4, AC-5, SM-1>

## Suggested stories
- <high-level breakdown; each story plausibly pickup-ready without further scoping>
- ...

## References
- Parent VI: [[<JIRA_KEY>]]
- [Source: <path>#<Section>] — <code anchor from code-scanner evidence, when relevant>
- ...
```
````

- [ ] **Step 4: Add the clarification-marker, coverage-file, and ARD rules.**

In the same file, immediately AFTER the `## Write mechanics` section's final paragraph (the "Traceability:" paragraph ending "…Do not invent content the sources don't contain.") and BEFORE `## Output`, insert:

````markdown
## Uncertainty markers

Where you genuinely cannot infer a detail from the VI or code-scanner sources,
insert an inline `[NEEDS CLARIFICATION: <specific question>]` at that point in
the draft INSTEAD of silently guessing. Rules:

- **Cap 3 per Epic.** More than 3 genuine unknowns signals an under-specified
  Epic — say so in `notes` rather than over-marking.
- **Priority:** dependencies > acceptance criteria > scope. **Never** mark Goal
  or Business value (those must be inferable — an un-inferable goal is a broken
  VI, out of your remit).
- Record every marker in the return field `clarifications_needed[]` as
  `{epic, section, question, suggested_answer}` — always propose your best-guess
  `suggested_answer` so the orchestrator's clarification gate can offer it.

## Coverage matrix (`_coverage.md`)

Write ONE file `_coverage.md` into `output_dir` (never a Jira Epic — the leading
underscore keeps it sorted above the Epic files and out of the paste-to-Jira set):

```markdown
# Requirement coverage — <JIRA_KEY>

_source: native | derived_
**Roll-up: READY | NEEDS WORK | NOT READY — N/M requirements covered (P%), K gaps**

| Req  | Type      | Text (short) | Covered by                           | Status |
|------|-----------|--------------|--------------------------------------|--------|
| US-1 | story     | …            | Epic: <slug-a> (new); <KEY> (exist)  | ✅     |
| AC-3 | criterion | …            | —                                    | ❌ gap |
```

- Rows = the handoff `requirements[]`. "Covered by" counts BOTH existing linked
  Epics AND the new drafts. `_source:` echoes `requirements_source`.
- Roll-up: `READY` (0 gaps) · `NEEDS WORK` (≥1 gap, none fundamental) ·
  `NOT READY` (gaps you judge fundamental). `P% = covered/total`.
- **Focus mode:** when the handoff `scope` targets a single focus Epic, still
  recompute `_coverage.md` VI-holistically (all existing Epics + the re-drafted
  focus Epic) — never a single-Epic view.

## ARD conformance (only when `applicable_ard` is present)

Keep each Epic's scope + acceptance criteria consistent with the VI-level `AD-N`
invariants and `guidance_summary`. When an Epic MUST deviate from an `AD-N`,
record — in that Epic draft, NEVER in the ARD — a line:
`- ARD deviation: [<AD-N id>] — <what deviates> — <why> — flag: architect`
When `applicable_ard` is absent, do nothing here.
````

- [ ] **Step 5: Update the Output contract.**

In `## Output`, replace the return list. Find the block:
```
- `status: DONE | BLOCKED`
- `files_written: [absolute paths of every Epic file written]`
- `notes: [non-duplication notes, any Epic skipped as duplicate]`
```
Replace it with:
```markdown
- `status: DONE | BLOCKED`
- `files_written: [absolute paths of every Epic file written]`
- `coverage_file: <absolute path of _coverage.md>`
- `clarifications_needed: [{epic, section, question, suggested_answer}]`  # empty list when none
- `notes: [dedup notes, any Epic skipped/merged as duplicate, coverage roll-up, requirements_source]`
```

- [ ] **Step 6: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
for a in "Independent Test" "## Covers" "NEEDS CLARIFICATION" "Given <context>, when <action>" "ARD deviation" "_coverage.md" "clarifications_needed" "Pre-flight (before drafting)" "Source: <path>#<Section>"; do
  printf '%s -> ' "$a"; grep -c "$a" plugins/dev-workflows/agents/epic-writer.md
done
git diff --stat   # expect only agents/epic-writer.md
```
Expected: every count ≥ 1; only `epic-writer.md` in the diff.

- [ ] **Step 7: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/epic-writer.md
git commit -m "$(cat <<'EOF'
NOISSUE feat(epics): epic-writer coverage, markers, ARD-respect

Extend the Epic template (Given/When/Then ACs, Independent Test, Covers,
source-anchored citations); add [NEEDS CLARIFICATION] markers (cap 3), a
pre-draft dedup + sizing pre-flight, ARD deviation-record respect, and the
_coverage.md matrix. New return fields: coverage_file, clarifications_needed.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `epic-reviewer` — coverage, independence, drift, markers, ARD

**Files:**
- Modify: `plugins/dev-workflows/agents/epic-reviewer.md`

**Interfaces:**
- Consumes (from Tasks 1, 2, 4 brief): `requirements[]`, the `_coverage.md` path, `applicable_ard` (or omitted).
- Produces: verdict + findings in the existing severity schema across the existing + new dimensions. No output-shape change (still `## Epic Review` / Verdict / Summary / Findings / Recommended next step).

- [ ] **Step 1: Add the new inputs.**

In `plugins/dev-workflows/agents/epic-reviewer.md`, in `## Inputs` under "The caller passes a structured brief:", append after the `code-scanner output` bullet:

```markdown
- **`requirements[]`** — the VI requirement inventory (from jira-reader). The coverage ground truth.
- **`_coverage.md` path** — the coverage matrix the writer produced. Verify it against `requirements[]`.
- **`applicable_ard`** — the VI-level ARD `invariants` (AD-N), or omitted. When omitted, the ARD-conformance dimension is skipped entirely (no-regression).
```

- [ ] **Step 2: Add review-method steps.**

In `## Review method`, after the current step `3.` (the code-scanner cross-check), insert new steps (renumbering the trailing derive-verdict step accordingly — keep it last):

```markdown
4. Read `_coverage.md`. Cross-check every row against the passed `requirements[]`: a requirement no existing-or-new Epic covers (`❌ gap`) is a MAJOR coverage finding; a `## Covers` id absent from `requirements[]` is a MINOR stale reference.
5. Check epic independence: an Epic whose value cannot be delivered without a not-yet-existing Epic (read `## Independent Test` + `## Dependencies`) is a MAJOR finding.
6. Check internal terminology consistency: the same concept named differently across the batch is a MINOR/NIT finding (corporate terminology vs the style guide is dt-style-checker's job — out of scope here).
7. Flag any unresolved `[NEEDS CLARIFICATION]` marker as a BLOCKER.
8. When `applicable_ard` is present, check each Epic against the `AD-N` invariants: a violating Epic WITHOUT a matching `- ARD deviation: … flag: architect` line is a BLOCKER; WITH one it is allowed-but-flagged. When absent, skip this dimension.
```

- [ ] **Step 3: Add the new dimensions to the dimensions table.**

In `## Review dimensions`, append these rows to the table (after `Structural integrity`):

```markdown
| Requirement coverage | Every VI requirement in `requirements[]` is covered by an existing or new Epic; `❌ gap` rows in `_coverage.md` → MAJOR. A `Covers` id not in `requirements[]` → MINOR. |
| Epic independence | Each Epic delivers its value without any not-yet-built Epic (no forward dependency). A forward dependency → MAJOR (resequence/merge). |
| Terminology drift (internal) | The same concept is named consistently across all Epics in the batch. Inconsistency → MINOR/NIT. Corporate terminology is dt-style-checker's job, not this dimension. |
| ARD conformance (conditional) | Only when `applicable_ard` is present: an Epic violating a VI-level `AD-N` without a matching `- ARD deviation: … flag: architect` line → BLOCKER; with one → allowed-but-flagged. Absent → dimension skipped. |
```

- [ ] **Step 4: Add anti-pattern + filler guidance to the Goal-clarity dimension.**

In the `## Review dimensions` table, find the `Goal clarity` row. Replace its Check cell text with:

```markdown
One-sentence goal; unambiguous; tied concretely to the parent VI's outcome. It expresses USER VALUE, not a technical milestone — titles like "Database Setup", "API Development", "Infrastructure Setup" are anti-patterns (findings), vs a user-value title (correct). Also flag "theater": boilerplate business-value or vague untestable ACs ("improve performance", "be reliable") that look like content but aren't.
```

- [ ] **Step 5: Add the Findings output sub-headings.**

In `## Output`, in the `### Findings` template, after the `#### Structural integrity` block, insert:

```markdown
#### Requirement coverage
- ...

#### Epic independence
- ...

#### Terminology drift
- ...

#### ARD conformance
- _"N/A — no applicable ARD"_ when `applicable_ard` was omitted, else findings.
```

- [ ] **Step 6: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
for a in "Requirement coverage" "Epic independence" "Terminology drift" "ARD conformance" "applicable_ard" "_coverage.md" "Database Setup" "theater"; do
  printf '%s -> ' "$a"; grep -c "$a" plugins/dev-workflows/agents/epic-reviewer.md
done
git diff --stat   # expect only agents/epic-reviewer.md
```
Expected: every count ≥ 1; only `epic-reviewer.md` in the diff.

- [ ] **Step 7: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/epic-reviewer.md
git commit -m "$(cat <<'EOF'
NOISSUE feat(epics): epic-reviewer coverage/independence/ARD dimensions

Add requirement-coverage (gap=MAJOR), epic-independence (MAJOR), internal
terminology-drift (MINOR), unresolved-marker (BLOCKER), and conditional
ARD-conformance (BLOCKER w/o deviation) dimensions; add anti-pattern + filler
detection to goal clarity. Output shape unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `epics.md` wiring + `ard-resolution.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md`
- Modify: `plugins/dev-workflows/references/ard-resolution.md`

**Interfaces:**
- Consumes: everything from Tasks 1–3 (the `requirements[]` field, the writer return contract, the reviewer brief inputs).
- Produces: the orchestrated flow — Phase 2.5 (ARD), Phase 3 carry, Phase 6 handoff, Phase 6.2 gate, Phase 6.1 emphasis, Phase 7 brief, Phase 9 report, invariants.

- [ ] **Step 1: Add Phase 2.5 (ARD resolution) to epics.md.**

In `plugins/dev-workflows/commands/epics.md`, immediately AFTER the `## Phase 2 — Plan + approval` section (i.e. before `## Phase 3 — Read Jira hierarchy`), insert:

```markdown
---

## Phase 2.5 — Resolve applicable ARD (optional)

Resolve any VI-level ARD for this VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `vi = jira_key`,
**`epic: null`** (Epics do not exist yet — VI-level ARD only), and `$SPECS_PATH`.

- On `status: none` (including `$SPECS_PATH` unset/unresolvable) → **skip and
  proceed exactly as before.** No prompt, no extra output.
- On `status: found` → carry `invariants` + `guidance_summary` forward: pass them
  to `epic-writer` (Phase 6 handoff, as `applicable_ard`) so drafts stay
  consistent with the `AD-N`, and to `epic-reviewer` (Phase 7, as `applicable_ard`)
  which then activates its ARD-conformance dimension. A necessary deviation is
  recorded by the writer in the Epic draft (`- ARD deviation: … flag: architect`)
  and surfaced in the Phase 9 report — never edit the ARD.
```

- [ ] **Step 2: Carry `requirements[]` in Phase 3.**

In `## Phase 3 — Read Jira hierarchy`, find the sentence "On `OK`, identify the Epics already linked to the VI…". Immediately before it, insert:

```markdown
On `OK`, carry the handoff `requirements[]` and `requirements_source` forward —
they are the coverage ground truth for Phases 6–7.
```

- [ ] **Step 3: Extend the Phase 6 handoff.**

In `## Phase 6 — Write Epics`, find step `1. **Write the handoff file.**`. In its list of handoff contents (the sentence "…containing the `epic-writer` input contract: `jira_reader_handoff`, `code_scanner_outputs` … `vi_goal`, `jira_key`."), extend that list to end with:
`, \`requirements\` + \`requirements_source\` (from Phase 3), \`applicable_ard\` (the Phase 2.5 invariants + guidance_summary, or omit when status was none), and \`existing_epic_themes\` (themes of the already-linked Epics).`

Then find step `3. **Handle the return.**` and append after its existing text:
```markdown
Also record `coverage_file` (the `_coverage.md` path) and `clarifications_needed[]` for Phases 6.2 and 7.
```

- [ ] **Step 4: Insert Phase 6.2 (clarification gate).**

Immediately AFTER `## Phase 6 — Write Epics` and BEFORE `## Phase 6.1 — Dynatrace style check`, insert:

```markdown
---

## Phase 6.2 — Resolve clarifications

If the writer returned a non-empty `clarifications_needed[]`, resolve it BEFORE
the style check and review (so no review cycle is spent on known unknowns).
Present ONE batched prompt listing every marker grouped by Epic; for each:
```
choices: ["Use the writer's suggested answer", "I'll answer (you'll be prompted)", "Leave unresolved", "Other… (describe)"]
```
Fold each resolved answer into the affected Epic draft (Edit the file inline, or
re-dispatch `epic-writer` once with the resolutions). Markers the user chooses to
**leave unresolved** stay visible in the draft and become `epic-reviewer`
BLOCKERs in Phase 7. If `clarifications_needed[]` is empty, this phase is a
**silent no-op** (byte-identical to a run without it).
```

- [ ] **Step 5: Sharpen the Phase 6.1 dt-style brief.**

In `## Phase 6.1 — Dynatrace style check`, find the agent dispatch block containing `doc_type: epic`. Replace that dispatch's prompt lines with:

```markdown
  > "Run the style check for this brief:
  >
  > files:    [absolute paths of every Epic file written in Phase 6]
  > doc_type: epic
  > emphasis: terminology and customer-facing captions, labels, messages, and text"
```

- [ ] **Step 6: Extend the Phase 7 reviewer brief.**

In `## Phase 7 — Epic review gate`, find the `epic-reviewer` dispatch prompt (the block with `Task description:` … `code-scanner output:`). Append these lines to that prompt block, before the closing quote:

```markdown
  > requirements:        [paste the requirements[] array from Phase 3]
  > _coverage.md path:    [absolute path of the coverage file from Phase 6]
  > applicable_ard:       [the Phase 2.5 invariants, or omit if status was none]"
```

- [ ] **Step 7: Add Phase 9 report sections.**

In `## Phase 9 — Final Report`, inside the fenced report template, insert after the `### Epic review verdict` block (and before `### Dynatrace style check (Phase 6.1)`):

```markdown
### Requirement coverage
[Roll-up verdict + N/M covered (P%); list each ❌ gap requirement ID; _coverage.md path] — _or_ "derived (coarse) — VI had no structured requirements"

### Clarifications
[Resolved: <n>; Deferred (left unresolved → became blockers): <n>] — _or_ "none raised"

### ARD conformance
[verdict + any `- ARD deviation:` lines recorded] — _omit this whole section when Phase 2.5 status was none_
```

- [ ] **Step 8: Add invariants.**

In `## Invariants (always enforced)`, append these bullets:

```markdown
- ALWAYS have `epic-writer` write `_coverage.md` to `output_dir` (VI-holistic, even in focus mode); it is NOT a Jira Epic and is never pasted to Jira
- ALWAYS run the Phase 6.2 clarification gate when the writer returns clarifications; unresolved-by-choice markers become `epic-reviewer` BLOCKERs
- ARD steps (Phase 2.5, writer/reviewer `applicable_ard`, the Phase 9 ARD section) are ADDITIVE and guarded on `status: found` — a run with no ARD is byte-identical to before
- ALWAYS pass `requirements[]`, the `_coverage.md` path, and `applicable_ard` (when found) to `epic-reviewer`
```

- [ ] **Step 9: Wire `/epics` into `ard-resolution.md` (additive).**

In `plugins/dev-workflows/references/ard-resolution.md`:
- Line ~5, find `Cited by \`/design\`, \`/implement\`,` and `and \`/specify\` so the resolution logic`. Change the list to include `/epics`: `Cited by \`/design\`, \`/implement\`, \`/specify\`, and \`/epics\` so the resolution logic`.
- In the `## Consumers (informative)` list, after the `- \`/specify\`` bullet, add:
```markdown
- `/epics` — VI-level only (`epic: null`, Epics do not exist yet); `AD-N` = inherited invariants the drafted Epics must respect; deviations → a `- ARD deviation: …` line in the Epic draft + the Phase 9 report.
```

- [ ] **Step 10: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
for a in "Phase 2.5 — Resolve applicable ARD" "Phase 6.2 — Resolve clarifications" "### Requirement coverage" "### Clarifications" "### ARD conformance" "emphasis: terminology and customer-facing" "requirements:        \[paste"; do
  printf '%s -> ' "$a"; grep -c "$a" plugins/dev-workflows/commands/epics.md
done
grep -c "epics" plugins/dev-workflows/references/ard-resolution.md   # expect >= 2 (citing line + consumer bullet)
git diff --stat   # expect only commands/epics.md + references/ard-resolution.md
# no-regression: /specify's ARD wiring untouched
git diff --stat main -- plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md   # expect EMPTY
```
Expected: every epics.md count ≥ 1; ard-resolution ≥ 2; diff only the two files; the no-regression diff empty.

- [ ] **Step 11: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/epics.md plugins/dev-workflows/references/ard-resolution.md
git commit -m "$(cat <<'EOF'
NOISSUE feat(epics): wire coverage, clarification gate, ARD into /epics

Add Phase 2.5 (VI-level ARD, additive), Phase 6.2 clarification gate, carry
requirements[] to writer+reviewer, sharpen Phase 6.1 dt-style emphasis, and add
coverage/clarification/ARD sections to the Phase 9 report + invariants. Wire
/epics into references/ard-resolution.md.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Version bump + CHANGELOG

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:** none (release plumbing).

- [ ] **Step 1: Bump plugin.json.**

Edit `plugins/dev-workflows/.claude-plugin/plugin.json`: change `"version": "2.20.0"` → `"version": "2.21.0"`.

- [ ] **Step 2: Bump the marketplace dev-workflows entry.**

Edit `.claude-plugin/marketplace.json`: in the `dev-workflows` entry, change its `"version": "2.20.0"` → `"version": "2.21.0"`. Do NOT touch the description strings, or any sibling entry.

- [ ] **Step 3: Prepend the CHANGELOG entry.**

At the top of `plugins/dev-workflows/CHANGELOG.md` (above the current newest entry), prepend:

```markdown
## [2.21.0] — 2026-07-12

### Added

- `/epics`: requirement→Epic **coverage matrix** with gap-detection — `jira-reader` now emits a `requirements[]` inventory (native VI `US/AC/SM/FR/UC` IDs, with a goal+themes `derived` fallback); `epic-writer` writes `_coverage.md` (VI-holistic, roll-up verdict + coverage %); `epic-reviewer` verifies it (uncovered requirement = MAJOR).
- `/epics`: `[NEEDS CLARIFICATION]` markers (cap 3/Epic; deps > AC > scope) + a Phase 6.2 batched resolution gate; unresolved-by-choice markers become reviewer BLOCKERs.
- `/epics`: Given/When/Then acceptance criteria + an `## Independent Test` line; source-anchored `[Source: path#Section]` citations; a pre-draft dedup pre-flight + a sizing/sequencing heuristic.
- `/epics`: new `epic-reviewer` dimensions — epic-independence (no-forward-dependency, MAJOR), internal terminology-drift (MINOR), anti-pattern + filler/"theater" detection under goal clarity.
- `/epics`: **ARD wiring** — new optional Phase 2.5 resolves the VI-level ARD (mirrors `/specify`); writer respects `AD-N` + records deviations; reviewer gains a conditional ARD-conformance dimension (BLOCKER without a deviation record). Additive, guarded on `status: found`. `/epics` added to `references/ard-resolution.md` consumers.
- `/epics`: Phase 6.1 `dt-style-checker` brief now emphasizes terminology + customer-facing captions/labels/messages/text.

### Notes

- No new command or agent — counts unchanged (19 commands / 29 agents). No-regression: a run with no ARD and no clarification markers behaves as before; `/vuln`, `/upgrade`, `/document`, and the sibling plugins are untouched.
```

- [ ] **Step 4: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print('plugin', json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"   # expect 2.21.0
python3 -c "import json;d=[p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins'] if p['name']=='dev-workflows'][0];print('marketplace', d['version'])"   # expect 2.21.0
head -3 plugins/dev-workflows/CHANGELOG.md | grep "2.21.0"   # expect the new heading
# counts + description strings unchanged
ls -1 plugins/dev-workflows/commands/*.md | wc -l   # expect 19
ls -1 plugins/dev-workflows/agents/*.md | wc -l     # expect 29
grep -c "Nineteen slash commands" .claude-plugin/marketplace.json   # expect 1
grep -c "Twenty-nine reusable subagents" .claude-plugin/marketplace.json   # expect 1
# siblings byte-identical to main
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki   # expect EMPTY
```
Expected: both versions 2.21.0; CHANGELOG heading present; counts 19/29; description strings present; sibling diff empty.

- [ ] **Step 5: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
NOISSUE chore(epics): bump dev-workflows to 2.21.0 + CHANGELOG

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final whole-branch verification (before finish-branch)

```bash
cd /workspace/ihudak-claude-plugins
git diff --stat main   # expect EXACTLY: jira-reader.md, epic-writer.md, epic-reviewer.md, epics.md, ard-resolution.md, plugin.json, marketplace.json, CHANGELOG.md
# hard no-regression gates (all must be EMPTY):
git diff main -- plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/commands/document.md
git diff main -- plugins/dt-style-guide plugins/obsidian-llm-wiki
# manifests parse:
python3 -c "import json;json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));json.load(open('.claude-plugin/marketplace.json'));print('manifests OK')"
```
Expected: exactly 8 files changed; the three no-regression diffs empty; manifests parse.

Then hand off to **superpowers:finishing-a-development-branch** (there is no test suite — structural verification above IS the gate; present the merge/PR options and let the user choose; push only when asked).

---

## Self-Review

**Spec coverage:** §4 inventory → Task 1. §5 template/markers/dedup/ARD/sizing + §6 `_coverage.md` → Task 2. §7 reviewer dimensions → Task 3. §8 command wiring + §9 ard-resolution → Task 4. §3.9 manifests/CHANGELOG → Task 5. §10 no-regression → verification steps in Tasks 4–5 + final gate. §11 verification → per-task + final gate. All spec sections mapped.

**Placeholder scan:** No TBD/TODO. Every edit shows the exact anchor + the exact markdown to insert. Verification steps give exact commands + expected output.

**Type consistency:** Field names are consistent across tasks — `requirements` / `requirements_source` (Task 1 → 2,3,4), `coverage_file` / `clarifications_needed` (Task 2 → 4), `applicable_ard` (Task 4 → 2,3), `_coverage.md` (Task 2 → 3,4). Phase names (2.5, 6.2, 6.1, 7, 9) consistent. Roll-up verdict vocab (READY/NEEDS WORK/NOT READY) consistent between §6 and Task 2/Task 4.

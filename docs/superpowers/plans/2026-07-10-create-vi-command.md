---
tags:
  - tasks-exclude
---

# `/create-vi` command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `/create-vi` command (dev-workflows v2.16.0) — turns a refined `idea.md` + a user-supplied `JIRA-KEY` into a product-level Value Increment (spine + adapt-in profiles), gated by an Opus `vi-reviewer`, written to `$SPECS_PATH` and published to Jira; plus a grilling-technique SSOT that `/idea`/`/specify`/`/design` are retrofitted to cite.

**Architecture:** Additive to dev-workflows (markdown commands/agents/references + JSON manifests). New orchestrator `commands/create-vi.md` authors inline (Opus grill) against a new `references/vi-format.md`, gated by a new Opus `agents/vi-reviewer.md`; a new `references/grilling-technique.md` SSOT DRYs the embedded grill across four commands.

**Tech Stack:** Markdown command/agent/reference files; JSON plugin manifests; `python3` (stdlib) for JSON validation. NO test framework, NO husky/prettier hook — verification is **structural** (grep anchors, `python3 json.load`, byte-diff).

## Global Constraints

- **Additive only.** No behavior change to existing commands except the grilling retrofit (citation swap, depth/stage preserved) and the count/enumeration reconciliations named below.
- **Version lock-step 2.16.0** in `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of the repo-root `.claude-plugin/marketplace.json`; the two `description` strings stay **byte-identical**.
- **Siblings untouched & byte-identical:** `dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1.
- **Commit named files only — NEVER `git add -A`.** Branch `ivgu/NOISSUE-create-vi-command`. Trailer EXACTLY: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Push only when the user asks** (pause at finish-branch).
- **VI is product-level** — no implementation detail; no code scan; no repos required.
- **Never write to cwd.** Relocate `idea.md` by copy/move, never symlink.
- Watch for lima read-after-write git flakiness on commit: `git fsck --full` first, `git update-ref` the dangling commit if a ref-write fails, verify HEAD after each write.

---

## File Structure

**New (4):** `references/grilling-technique.md` (grill SSOT), `references/vi-format.md` (VI artifact contract), `agents/vi-reviewer.md` (Opus VI reviewer), `commands/create-vi.md` (orchestrator).
**Modified (10):** `commands/idea.md` + `commands/specify.md` + `commands/design.md` (grilling retrofit), `references/feedback-emission.md` (nine→ten), `references/cost-emission.md` (enum + promote `/create-vi` row), `references/dependencies.md` (grilling list), `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` (v2.16.0 + counts), `CHANGELOG.md`, `README.md`.

All paths relative to repo root `/workspace/ihudak-claude-plugins`.

---

### Task 1: `references/grilling-technique.md` (grill SSOT)

**Files:** Create `plugins/dev-workflows/references/grilling-technique.md`
**Interfaces:** Produces the shared technique cited by Task 2 (retrofit) and Task 5 (`create-vi` Phase 3).

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
# Grilling technique (embedded — shared reference)

The interview technique the authoring commands (`/idea`, `/create-vi`, `/specify`, `/design`) use to
refine an artifact one decision at a time. Embedded here so callers have **no runtime dependency**;
technique adapted from mattpocock grill-me/grilling. Each caller cites this file and states its own
**depth** and **stage list**; this reference owns only the mechanics.

## Mechanics

- Ask exactly **ONE** question at a time; wait for the answer before the next. Never batch — a firehose is bewildering.
- For every question, give your **recommended answer**, so the user reacts to a proposal, not a blank prompt.
- **Fact-vs-decision split:** if a question can be answered from the artifact, code, or context, explore and answer it yourself; put only genuine **decisions** to the user.
- **Walk the design tree in dependency order** — resolve a parent decision before the choices that depend on it.
- Continue until you and the user reach a **shared understanding** for the current section, then write that section.

## Depth (the caller chooses)

- **Bounded** — a capped set of the highest Impact×Uncertainty questions, then stop; unresolved high-impact gaps are recorded (e.g. `[NEEDS CLARIFICATION]`). Used by `/idea` (≤5; `--deep` switches to relentless).
- **Relentless** — keep walking the tree until convergence, no cap. Used by `/create-vi`, `/specify`, `/design`.

If `mattpocock-skills` `/grilling` is installed the user may invoke it directly (see
`${CLAUDE_PLUGIN_ROOT}/references/dependencies.md`); it is **not** a runtime dependency.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/references/grilling-technique.md
grep -q "^# Grilling technique" "$f" && grep -q "ONE.* question at a time" "$f" \
  && grep -q "Fact-vs-decision split" "$f" && grep -q "Bounded" "$f" && grep -q "Relentless" "$f" \
  && grep -q "no.*runtime dependency" "$f" && echo "OK grilling-technique"
```
Expected: `OK grilling-technique`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/grilling-technique.md
git commit -m "feat(grill): add shared grilling-technique reference (SSOT)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Grilling retrofit — `/idea`, `/specify`, `/design` cite the SSOT

**Files:** Modify `commands/idea.md`, `commands/specify.md`, `commands/design.md`
**Interfaces:** Consumes Task 1. Each command keeps its own depth + stage list; only the duplicated technique block is replaced by a citation.

- [ ] **Step 1: `commands/idea.md`** — replace the technique block (bounded/`--deep` paragraph that follows is preserved). Replace exactly:

```
**Interview technique (grilling — embedded; no runtime plugin dependency).**

- Ask exactly ONE question at a time; wait for the answer before the next. Never batch — a firehose is bewildering.
- For every question, give your recommended answer, so the user reacts to a proposal, not a blank prompt.
- If a question can be answered from the `idea-reader` digest or the vault, explore and answer it yourself instead of asking (fact-vs-decision split — look up facts, only put decisions to the user).
- Walk the design tree in dependency order — resolve a parent decision before dependents.

(Technique adapted from mattpocock grill-me/grilling; embedded here so `/idea` has no runtime dependency. If `mattpocock-skills` `/grilling` is installed the user may invoke it directly — see `${CLAUDE_PLUGIN_ROOT}/references/dependencies.md`.)
```

with:

```
**Interview technique (grilling — embedded; no runtime dependency).** Follow the shared technique in `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the `idea-reader` digest / vault, put only decisions to the user), walk the design tree in dependency order. **Depth: bounded by default (below); `--deep` = relentless.**
```

- [ ] **Step 2: `commands/specify.md`** — replace exactly:

```
**Interview technique (grilling — embedded; no runtime plugin dependency).** Conduct each stage as a relentless interview:

- Ask exactly ONE question at a time; wait for the answer before the next. Never batch questions — a firehose is bewildering.
- For every question, give your recommended answer, so the user reacts to a proposal, not a blank prompt.
- If a question can be answered from the Phase 4 code scan or the Jira content, explore and answer it yourself instead of asking.
- Walk the design tree in dependency order — resolve a parent decision before the choices that depend on it.
- Continue until you and the user reach a shared understanding for the stage, then write that stage's section.

(Technique adapted from mattpocock grill-me/grilling; embedded here so `/specify` has no runtime dependency.)
```

with:

```
**Interview technique (grilling — embedded; no runtime dependency).** Conduct each stage as a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 4 code scan / Jira content to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write that stage's section.
```

- [ ] **Step 3: `commands/design.md`** — replace exactly:

```
**Interview technique (grilling — embedded; no runtime plugin dependency).** Conduct the design as a
relentless interview:
- Ask exactly ONE question at a time; wait for the answer before the next. Never batch questions — a
  firehose is bewildering.
- For every question, give your recommended answer, so the developer reacts to a proposal.
- If a question can be answered from the Phase 4 code scan or the spec, explore and answer it yourself
  instead of asking.
- Walk the design tree in dependency order — resolve a parent decision before dependent ones.
- Continue until you and the developer reach a shared understanding for the section, then write it.

(Technique adapted from mattpocock grill-me/grilling; embedded here so `/design` has no runtime
dependency.)
```

with:

```
**Interview technique (grilling — embedded; no runtime dependency).** Conduct the design as a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 4 code scan / spec to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write the section.
```

- [ ] **Step 4: Verify** (SSOT cited by all three; each still has its grill phase + depth preserved)

```bash
cd /workspace/ihudak-claude-plugins
for c in idea specify design; do grep -q "references/grilling-technique.md" plugins/dev-workflows/commands/$c.md || { echo "MISSING cite: $c"; exit 1; }; done
grep -q -- "--deep\` = relentless" plugins/dev-workflows/commands/idea.md \
  && grep -q "Conduct each stage as a \*\*relentless\*\*" plugins/dev-workflows/commands/specify.md \
  && grep -q "Conduct the design as a \*\*relentless\*\*" plugins/dev-workflows/commands/design.md \
  && ! grep -q "no runtime plugin dependency" plugins/dev-workflows/commands/idea.md \
  && ! grep -q "no runtime plugin dependency" plugins/dev-workflows/commands/specify.md \
  && ! grep -q "no runtime plugin dependency" plugins/dev-workflows/commands/design.md \
  && echo "OK retrofit"
```
Expected: `OK retrofit`

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md
git commit -m "refactor(grill): cite grilling-technique SSOT from idea/specify/design

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `references/vi-format.md` (VI artifact contract)

**Files:** Create `plugins/dev-workflows/references/vi-format.md`
**Interfaces:** Produces the frontmatter keys + spine headings + adapt-in menu + profiles that Task 4 (`vi-reviewer`) and Task 5 (`create-vi` Phase 3) rely on.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
# Value Increment format (embedded authority)

The canonical structure and per-section rules for a `<KEY>_ValueIncrement.md`. `/create-vi` authors
against this file; `vi-reviewer` reviews against it. The VI is **product-level** (a PRD): what / why /
for-whom, **not** how — no implementation detail. A mandatory **spine** (always present) plus an
**adapt-in menu** whose clusters are pulled only when the idea warrants them (never an empty section).

## Profiles

- **`--lean`** — spine only.
- **`--hybrid`** (default) — spine + the hybrid adapt-in clusters.
- **`--full`** — spine + the full adapt-in menu.

## Frontmatter (PM-authorable subset)

```yaml
---
title: <human-readable VI title>
summary: <one-line>
issue_type: ValueIncrement
status: <e.g. draft>
owning_program: <program>
tracking_programs: [ ... ]
priority: <e.g. Major>
labels: [ ... ]
relevant_for_release_notes: <yes | no>
release_versions: "<e.g. Managed (344), SaaS (344)>"
sources:                     # PROPAGATED from idea.md's recorded provenance — not the literal idea.md
  - provenance: rfe | community-post | prompt | markdown
    ref: <RFE key | post URL | ...>
derived_from: <path to the idea.md this VI was built from>
jira_key: <KEY>
---
```

The pure Jira-mirror fields (`statusCategory`, `reporter`, `url`, `updated`, `synced`, …) are
regenerated by the importer on the round-trip and are NOT authored here.

## Spine (always, every profile)

- `## Problem` — who is affected and why the current situation is insufficient; why now. Solution-free; no implementation detail.
- `## Goal` — a crisp 2–3 sentence statement of the outcome (feeds `jira-reader`'s goal extraction and every downstream consumer).
- `## Target audience` — the personas/roles served (specific roles, not "everyone").
- `## User Stories` — `### [US-N]: <title>`, `As a [role], I want [capability], so that [benefit].` Contiguous IDs.
- `## Acceptance Criteria` — `[AC-N]` under each story; externally-observable pass/fail (no "be reliable"/"improve performance").
- `## Scope` — **In scope** (concrete delivered behaviours) / **Out of scope** (concrete confusable exclusions; never "anything else"/"future work").
- `## Success Metrics` — `[SM-N]`; measurable, technology-agnostic outcomes.

## Adapt-in menu (pulled only when warranted)

| Cluster | hybrid | full |
|---|:-:|:-:|
| `## Use cases & user journey` (UC-N narrative) | ✓ | ✓ |
| `## Non-functional requirements` | ✓ | ✓ |
| `## Assumptions & open questions` (hybrid: light list; full: Contradictions Log table — Item/Source/Impact/Resolution/Owner) | ✓ | ✓ |
| `## Why now / differentiation` | ✓ | ✓ |
| `## References / linked issues` | ✓ | ✓ |
| `## Documentation impact` | ✓ | ✓ |
| `## Short Abstract / Blogline` (Internal + External) | | ✓ |
| `## Customer Zero` | | ✓ |
| `## Competitive snapshot` (1–3 competitors × Approach / Differentiation / Pricing) | | ✓ |
| `## Functional requirements` (FR-N *Implements: UC-n / US-n*) | | ✓ |
| `## E2E Demo` (per-delivery pass/fail acceptance) | | ✓ |
| `## UX prototype / UI mockups` | | ✓ |
| `## API specification` | | ✓ |
| `## Key deliverable & plan` | | ✓ |
| `## Enablement` (launch / preview) | | ✓ |
| `## Cost analysis` | | ✓ |

## Quality rules

- **No implementation detail** anywhere — the VI is product-level (algorithms, data structures, code paths, internal APIs belong to the ARD / spec / design).
- **FR / UC must not restate US** — reference by ID; each adds capability/behaviour, not a paraphrase.
- Acceptance criteria and success metrics are **externally observable**.
- Consolidate shared data dependencies rather than repeating them.
- Detailed **Test Cases are NOT authored here** — they are `/specify`'s `specification.md` (`[TCxx]`).
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/references/vi-format.md
grep -q "^# Value Increment format" "$f" \
  && for h in "## Problem" "## Goal" "## Target audience" "## User Stories" "## Acceptance Criteria" "## Scope" "## Success Metrics"; do grep -qF "$h" "$f" || { echo "MISSING spine: $h"; exit 1; }; done \
  && grep -q "issue_type: ValueIncrement" "$f" && grep -q "relevant_for_release_notes" "$f" && grep -q "release_versions" "$f" \
  && grep -q "PROPAGATED from idea.md" "$f" && grep -q "No implementation detail" "$f" \
  && grep -q "Test Cases are NOT authored here" "$f" && echo "OK vi-format"
```
Expected: `OK vi-format`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/vi-format.md
git commit -m "feat(create-vi): add VI format reference (spine + adapt-in profiles)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `agents/vi-reviewer.md` (Opus VI reviewer)

**Files:** Create `plugins/dev-workflows/agents/vi-reviewer.md`
**Interfaces:** Consumes `references/vi-format.md` (Task 3). Produces the reviewer dispatched by Task 5 Phase 4 (input: VI path + profile; output: findings + PASS/PASS WITH RECOMMENDATIONS/BLOCK).

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
---
name: vi-reviewer
description: Reviews a Value Increment (<KEY>_ValueIncrement.md) authored by /create-vi for goal crispness, user-story/acceptance-criteria testability, scope concreteness, measurable metrics, product-level purity (no implementation detail), downstream-contract frontmatter, and profile completeness. Read-only; returns findings + a PASS / PASS WITH RECOMMENDATIONS / BLOCK verdict. Uses Claude Opus.
model: opus
tools: ["Read", "Glob", "Grep", "LS"]
---

Read-only whole-VI reviewer for drafts produced by `/create-vi`. Uses the strongest available reasoning
model (Claude Opus). Reads the **whole** `<KEY>_ValueIncrement.md` and checks it against the per-section
rules in `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md` plus the checks below. Never edits the VI.

Invoked from `/create-vi` Phase 4 after authoring. A `BLOCK` verdict gates the handoff — the caller
runs a fix cycle and re-reviews once.

## Input contract

- **VI path** — absolute path to `<KEY>_ValueIncrement.md`. Required; if absent, stop and report.
- **Profile** — `lean | hybrid | full`. Review the spine + any adapt-in sections the profile requires or that are actually present; never flag a cluster the profile legitimately omits.

## Review method

1. Read the VI end-to-end before judging.
2. Verify frontmatter: `issue_type: ValueIncrement`; `jira_key` matches `^[A-Z][A-Z0-9_]*-\d+$`; the downstream-contract fields `relevant_for_release_notes` + `release_versions` present; `sources` carries real provenance (not the literal `idea.md` path).
3. Apply every spine rule from `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md`; for each adapt-in section present, apply its rule.
4. Apply the dimension checks below.
5. Record each finding in the severity schema; route gaps needing product knowledge to **needs product input**; never fabricate a fix.

## Dimensions

- **Goal crispness (BLOCKER if vague):** a 2–3 sentence outcome a downstream reader can act on — it feeds `jira-reader` and every consumer. Empty, a restatement of the title, or unfalsifiable → `BLOCKER`.
- **User Stories:** `### [US-N]` + `As a [role], I want …, so that …`; specific role (not "the user"/"everyone"); verifiable benefit; contiguous IDs. Vague role/benefit → `MAJOR`.
- **Acceptance Criteria:** `[AC-N]` per story, externally-observable pass/fail; "be reliable"/"improve performance"/"fast" → `MAJOR`.
- **Scope:** In concrete (≥1 delivered behaviour); Out concrete + confusable; "anything else"/"future work" as an Out item → `MAJOR`.
- **Success Metrics:** `[SM-N]` measurable + technology-agnostic; a metric leaking implementation (e.g. "API < 200ms") when an outcome metric is meant → `MINOR`.
- **Product-level purity (BLOCKER):** no implementation detail (algorithms, data structures, code paths, internal APIs) — that belongs to the ARD / spec / design.
- **No restatement:** any FR/UC present must not merely paraphrase a US (reference by ID) → `MAJOR`.
- **Profile completeness:** every spine section present; each adapt-in section that IS present is substantive, not theater (empty/boilerplate Competitive Snapshot, personas, or metrics → `MAJOR`, "substance over theater"). Never flag an omitted adapt-in cluster the profile doesn't require.
- **Identifier integrity:** `[US-N]`/`[AC-N]`/`[SM-N]` unique + contiguous; cross-references point at existing IDs.

## Output contract

Return only findings, no preamble, ordered `BLOCKER` → `MAJOR` → `MINOR` → `NIT`:

```
[BLOCKER|MAJOR|MINOR|NIT] — <Section or US-N/AC-N/SM-N>
Violation: <what rule is broken and where>
Fix: <concrete recommendation, or "needs product input">
```

Then a final verdict line:
- `PASS` — no findings above MINOR.
- `PASS WITH RECOMMENDATIONS` — MAJOR/MINOR/NIT only, no BLOCKER.
- `BLOCK` — at least one BLOCKER.

If nothing is actionable, say so and state the profile reviewed.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/agents/vi-reviewer.md
grep -q "^name: vi-reviewer" "$f" && grep -q "^model: opus" "$f" && grep -q '"Read", "Glob", "Grep", "LS"' "$f" \
  && grep -q "Goal crispness (BLOCKER" "$f" && grep -q "Product-level purity (BLOCKER)" "$f" \
  && grep -q "PASS WITH RECOMMENDATIONS" "$f" && grep -q "BLOCK" "$f" && echo "OK vi-reviewer"
```
Expected: `OK vi-reviewer`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/vi-reviewer.md
git commit -m "feat(create-vi): add Opus vi-reviewer agent

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: `commands/create-vi.md` (orchestrator)

**Files:** Create `plugins/dev-workflows/commands/create-vi.md`
**Interfaces:** Consumes `references/grilling-technique.md` (T1), `references/vi-format.md` (T3), `agents/vi-reviewer.md` (T4), `references/feedback-emission.md` (`emit-auto`/`emit-block`), `references/cost-emission.md` (`emit-cost`), the `dev-workflows:model-routing` skill.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
---
name: create-vi
description: VI-creation workflow (PM phase, sub-project 2 of the VI-creation flow). Turns a refined idea.md + a user-supplied JIRA-KEY into a high-quality Value Increment document (spine + adapt-in profiles: --lean|--hybrid|--full), authored via a relentless grill against references/vi-format.md, gated by the Opus vi-reviewer, written to $SPECS_PATH/specifications/<KEY>-<slug>/ and published to Jira by paste + re-import. Product-level (no code scan). Offers /release-notes and /create-ard as next steps.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Author a Value Increment for the Jira item: $ARGUMENTS

`/create-vi` is **sub-project 2 of the VI-creation flow** (PM phase) — it consumes the `idea.md` from
`/idea` and a **user-supplied `JIRA-KEY`** (an empty Jira workitem the user created to get the ID) and
authors a high-quality **Value Increment** that feeds the downstream pipeline. The VI is **product-level**
(a PRD): what / why / for-whom, not how. Zero Jira API — the VI is authored as markdown in the specs
repo and published to Jira by paste + re-import.

Usage: `/create-vi <JIRA-KEY> [@idea.md] [--lean|--hybrid|--full]` (default `--hybrid`).

---

## Phase 0 — Resolve inputs

1. **`JIRA-KEY` (mandatory).** Parse the first non-flag token; validate `^[A-Z][A-Z0-9_]*-\d+$`. If absent or malformed, **stop gracefully**: `CREATE_VI_NEEDS_KEY: /create-vi needs a Jira key — create an empty Jira workitem first to get the ID, then re-run '/create-vi <KEY> @<idea.md>'.` (Format only — zero Jira API, so existence is not verified.)
2. **Profile.** `--lean | --hybrid | --full`; default `--hybrid`.
3. **Resolve `idea.md` (ladder — stop at first hit):**
   1. explicit `@path` argument;
   2. **same-session** — if `/idea` ran earlier in this session, use its recorded output path (confirm with the user);
   3. **discover** — `find "$VAULT_PATH/Projects" -type f -name idea.md` (recent first); if any, present a picker;
   4. prompt for a path, or — last resort — proceed with **no idea** and grill the VI from scratch.
4. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
5. **Feature folder.** `<SPECS_PATH>/specifications/<KEY>-<slug>/` — `<slug>` from the idea title (else a kebab of the VI summary). Honor an existing dir matched by key-number (tolerate a stray `-`/`_` and a human-adjusted slug). Auto-created by the first write (Phase 5).
6. **Prior VI.** If `<KEY>_ValueIncrement.md` exists in the folder, Phase 1 offers refine-vs-fresh.

`/create-vi` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

---

## Phase 1 — Configure

Use `choices` arrays; the last choice is always `"Other… (describe)"`.

1. **Confirm** the feature folder, the profile, and the resolved `idea.md` (or "none — grill from scratch").
2. **Refine vs fresh** (only if a prior `<KEY>_ValueIncrement.md` exists):
   ```
   choices: ["Refine the existing VI (Recommended)", "Start fresh — overwrite", "Cancel", "Other… (describe)"]
   ```
3. **Relocate `idea.md`.** If it is outside the feature folder, **copy/move** it to `<feature-folder>/idea.md` (**never a symlink** — a cross-root link between `$VAULT_PATH` and `$SPECS_PATH` would break). Record its original path for `derived_from`.
4. **Draft idea → warn-and-fold.** If `idea.md` is `status: draft` (open `[NEEDS CLARIFICATION]`), note that the grill resolves those items — do **not** hard-block.

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT for large/cross-cutting VIs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # impl-maintenance
  review_model:    <§2 Opus chain>     # vi-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + VI authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (the §2 Opus chain — interactive judgment, not a delegated subagent). If no Opus resolves, **degrade to best-available + record** in `notes` and the final report — do not hard-block.

---

## Phase 2 — Read the seed

Read the resolved `idea.md` **directly** (it is the plugin's own format — `idea-reader` is for arbitrary external sources and is not used here). Extract Problem / Who / desired outcome & value / rough scope / signals & evidence / candidate success signal, plus any open `[NEEDS CLARIFICATION]`. Carry the idea's `sources[]` forward to **propagate** into the VI frontmatter (the real provenance — RFE key / community-post URL / prompt), and record `derived_from` = the idea's original path.

Optionally ground in the idea's cited sources and any strategy/vision docs the user points to. **No code scan; no repos.**

If there is no idea (Phase 0 ladder exhausted), grill the VI from scratch.

---

## Phase 3 — Author via grill

**Interview technique (grilling — embedded; no runtime dependency).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the idea/sources; put only decisions to the user), walk the design tree in dependency order, continue to shared understanding then write each section.

Author `<KEY>_ValueIncrement.md` live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md` for the selected profile. Walk the **spine** in dependency order:

1. Frontmatter — incl. `release_versions` + `relevant_for_release_notes`, `sources` (propagated), `derived_from`, `jira_key`.
2. **Problem**
3. **Goal** (crisp 2–3 sentences)
4. **Target audience** (personas)
5. **User Stories** (`[US-N]`)
6. **Acceptance Criteria** (`[AC-N]` per story)
7. **Scope** (In / Out)
8. **Success Metrics** (`[SM-N]`)

Then author the profile's **adapt-in clusters**, each **pulled only when the idea warrants it** (never an empty section). Fold the idea's open `[NEEDS CLARIFICATION]` into the grill; resolve to zero where possible, leaving genuinely-unresolvable ones under `## Assumptions & open questions` (hybrid/full). Keep the VI **product-level** — no implementation detail.

---

## Phase 4 — Review gate

Dispatch `vi-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:vi-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the Value Increment:
  >
  > VI path: [absolute path to <KEY>_ValueIncrement.md]
  > Profile: [lean | hybrid | full]"

Act on the verdict (mirrors `/specify`):
- **`BLOCK`** — fix the BLOCKER findings inline (the orchestrator/grill edits the VI — no delegated writer) and re-review **once**. If still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER (`choices: ["Provide manual fix notes", "Defer to a follow-up issue", "Override and accept", "Cancel", "Other… (describe)"]`).
- **`PASS` / `PASS WITH RECOMMENDATIONS`** — proceed. Cap: one fix cycle + one re-review.

---

## Phase 5 — Handoff

Write the feature folder: `<KEY>_ValueIncrement.md` + the relocated `idea.md`. Then **offer** (commit-when-asked — never automatic):

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git", "Cancel"]
```

On the first choice, in the specs repo (`$SPECS_PATH`): create branch `vi/<KEY>-<slug>`; commit **only** the feature folder (never `git add -A`); push; open a PR targeting `main`. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

### Jira round-trip (document to the user — they will otherwise miss it)

1. **Paste** the VI body (below the frontmatter) into the Jira workitem `<KEY>`.
2. **Re-import** the VI to `$VAULT_PATH/jira-products/<KEY>` (via `https://github.com/ivan-gudak/jira-workitem-import`) so the downstream pipeline sees it.

Without these steps the pipeline cannot read the VI.

---

## Phase 6 — Next steps (two, parallel)

Offer **both** — clearly labeling the role handoff:

```
choices: ["Draft the initial release note now — /release-notes <KEY> (PM)", "Hand off to a Product Architect — /create-ard <KEY> (PA)", "Stop here", "Other… (describe)"]
```

- **`/release-notes <KEY>`** — the PM can draft the customer-facing release note now (the cost model's `pm`/`vi-creation` inferred case: no spec/design yet).
- **`/create-ard <KEY>`** — a **different role/session** (Product Architect) authors the grounded architecture document (`/create-ard` is sub-project 3).

Guidance only — this never auto-invokes another command.

---

## Phase 7 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 6, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (missing key, unset `$SPECS_PATH`, cancellation) or a work-quality review BLOCK.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-vi`; what was authored (VI + profile); key events (source-ladder friction, unresolved clarifications, BLOCK reviews — or 'none'); workarounds; the `vi-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the Lessons Learned report, `command: /create-vi`, the run's `jira_key`, `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-vi`, `phase: vi-creation`, `role: pm`, the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in Phase 5), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the VI path + profile; US/AC/SM counts + which adapt-in clusters were included; open-question count; the `vi-reviewer` verdict; the PR URL (if opened); the Jira round-trip reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; and the two next-step recommendations.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/commands/create-vi.md
grep -q "^name: create-vi" "$f" && grep -q "allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS" "$f" \
  && for h in "## Phase 0 — Resolve inputs" "## Phase 1 — Configure" "## Phase 2 — Read the seed" "## Phase 3 — Author via grill" "## Phase 4 — Review gate" "## Phase 5 — Handoff" "## Phase 6 — Next steps" "## Phase 7 — Session maintenance, feedback & cost"; do grep -qF "$h" "$f" || { echo "MISSING: $h"; exit 1; }; done \
  && grep -q "CREATE_VI_NEEDS_KEY" "$f" && grep -q 'skill: "dev-workflows:model-routing"' "$f" \
  && grep -q "references/grilling-technique.md" "$f" && grep -q "references/vi-format.md" "$f" \
  && grep -q 'subagent_type: "dev-workflows:vi-reviewer"' "$f" \
  && grep -q "phase: vi-creation" "$f" && grep -q "role: pm" "$f" && grep -q "emit-auto" "$f" && grep -q "Capture-at-block invariant" "$f" \
  && grep -q "/release-notes <KEY>" "$f" && grep -q "/create-ard <KEY>" "$f" \
  && grep -q "never a symlink" "$f" && echo "OK create-vi"
```
Expected: `OK create-vi`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/create-vi.md
git commit -m "feat(create-vi): add /create-vi orchestrator command

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Subsystem wiring (feedback + cost + dependencies)

**Files:** Modify `references/feedback-emission.md`, `references/cost-emission.md`, `references/dependencies.md`

- [ ] **Step 1: feedback-emission.md — nine → ten (both spots)**
  - `all nine workflow` → `all ten workflow`
  - `the nine commands'` → `the ten commands'`

- [ ] **Step 2: cost-emission.md — enum + promote the reserved row**
  - Header: `every VI-lifecycle command (`/idea`, `/specify`, `/epics`,` → `every VI-lifecycle command (`/idea`, `/create-vi`, `/specify`, `/epics`,`
  - §7 table: replace `| future `/create-vi` | vi-creation | pm |` with `| `/create-vi` | vi-creation | pm |`

- [ ] **Step 3: dependencies.md — add `/create-vi` to the grilling list**
  - `the embedded grilling technique in `/idea`, `/specify`, `/design`` → `the embedded grilling technique in `/idea`, `/create-vi`, `/specify`, `/design``

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
fe=plugins/dev-workflows/references/feedback-emission.md
ce=plugins/dev-workflows/references/cost-emission.md
de=plugins/dev-workflows/references/dependencies.md
grep -q "all ten workflow" "$fe" && grep -q "the ten commands'" "$fe" && ! grep -q "all nine workflow" "$fe" \
  && grep -qF 'every VI-lifecycle command (`/idea`, `/create-vi`, `/specify`' "$ce" \
  && grep -qF '| `/create-vi` | vi-creation | pm |' "$ce" && ! grep -qF '| future `/create-vi` | vi-creation | pm |' "$ce" \
  && grep -qF 'in `/idea`, `/create-vi`, `/specify`, `/design`' "$de" \
  && echo "OK wiring"
```
Expected: `OK wiring`

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/feedback-emission.md plugins/dev-workflows/references/cost-emission.md plugins/dev-workflows/references/dependencies.md
git commit -m "chore(create-vi): wire /create-vi into feedback + cost + dependencies

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Version + manifests + CHANGELOG

**Files:** Modify `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/dev-workflows/CHANGELOG.md`

- [ ] **Step 1: plugin.json** — four edits:
  - `"version": "2.15.0"` → `"version": "2.16.0"`
  - `Seventeen slash commands` → `Eighteen slash commands`
  - `/guideline-reviewer, /idea, /specify, /design,` → `/guideline-reviewer, /idea, /create-vi, /specify, /design,`
  - `spec-reviewer, design-reviewer)` → `spec-reviewer, design-reviewer, vi-reviewer)`
  - `Twenty-seven reusable subagents` → `Twenty-eight reusable subagents`

- [ ] **Step 2: marketplace.json** — in the `dev-workflows` entry ONLY (do not touch `dt-style-guide` 0.2.2 / `obsidian-llm-wiki` 0.3.1): apply the exact same five edits (version + the four description substrings) so its `description` stays **byte-identical** to plugin.json.

- [ ] **Step 3: CHANGELOG.md** — insert directly above `## [2.15.0] — 2026-07-10`:

```markdown
## [2.16.0] — 2026-07-10

### Added

- **New `/create-vi` command — sub-project 2 of the VI-creation flow (PM phase).** `/create-vi <JIRA-KEY> [@idea.md] [--lean|--hybrid|--full]` turns a refined `idea.md` + a user-supplied Jira key (an empty workitem the user created for the ID; mandatory — graceful fail without it) into a product-level **Value Increment**. A new `references/vi-format.md` defines a mandatory **spine** (Problem · Goal · Target audience · User Stories `[US-N]` · Acceptance Criteria `[AC-N]` · Scope · Success Metrics `[SM-N]`) plus an **adapt-in menu** (union of Mike's + Alex's sections) selected by profile and pulled only when the idea warrants it. Authored inline via a relentless grill, gated by a new Opus **`vi-reviewer`**, written to `$SPECS_PATH/specifications/<KEY>-<slug>/<KEY>_ValueIncrement.md` (the relocated `idea.md` co-located; `sources` propagated from the idea's real provenance, not the literal `idea.md`), with a branch+PR offer and a documented paste-into-Jira + re-import round-trip. Product-level: **no code scan, no repos required** (`/specify` does the light code grounding + Test Cases downstream). Phase 6 offers **both** next steps — `/release-notes` (PM, now) and `/create-ard` (Product Architect handoff). Wired into the terminal tail: `impl-maintenance` + `emit-auto` + `emit-cost` (`vi-creation`/`pm`) + capture-at-block.

### Changed

- **Grilling technique consolidated into `references/grilling-technique.md` (SSOT).** `/idea`, `/specify`, and `/design` now cite it instead of each embedding the ~5-line technique (DRY; each keeps its own depth — bounded/`--deep` for `/idea`, relentless for the others — and stage list). Still no runtime dependency. `references/feedback-emission.md` (nine → ten commands) and `references/cost-emission.md` (VI-lifecycle enum + the promoted `/create-vi` attribution row) reconciled. Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched.
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print(json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])" | grep -qx 2.16.0
python3 -c "import json;m={p['name']:p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']};a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));assert m['dev-workflows']['version']=='2.16.0';assert m['dt-style-guide']['version']=='0.2.2';assert m['obsidian-llm-wiki']['version']=='0.3.1';assert m['dev-workflows']['description']==a['description'],'descriptions differ';print('json+lockstep OK')"
grep -q "Eighteen slash commands" plugins/dev-workflows/.claude-plugin/plugin.json && grep -q "Twenty-eight reusable subagents" plugins/dev-workflows/.claude-plugin/plugin.json
grep -q "/idea, /create-vi, /specify" plugins/dev-workflows/.claude-plugin/plugin.json && grep -q "design-reviewer, vi-reviewer)" plugins/dev-workflows/.claude-plugin/plugin.json
head -14 plugins/dev-workflows/CHANGELOG.md | grep -q "## \[2.16.0\] — 2026-07-10"
echo "OK manifests+changelog"
```
Expected: `json+lockstep OK` then `OK manifests+changelog`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(release): dev-workflows 2.16.0 (/create-vi command)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: README updates

**Files:** Modify `plugins/dev-workflows/README.md`

- [ ] **Step 1: Read the current anchors** (capture exact strings before editing):

```bash
cd /workspace/ihudak-claude-plugins
grep -n "Ten workflow slash commands" plugins/dev-workflows/README.md
grep -n "VI-lifecycle commands" plugins/dev-workflows/README.md
grep -n "projects the plugin-facing slice" plugins/dev-workflows/README.md
grep -n "| \`/idea <prompt" plugins/dev-workflows/README.md
```

- [ ] **Step 2: Lead sentence** — `Ten workflow slash commands for idea refinement, structured implementation,` → `Eleven workflow slash commands for idea refinement, VI authoring, structured implementation,`

- [ ] **Step 3: Command table — insert a `/create-vi` row** immediately **after** the `/idea` row (the row matched in Step 1). Insert this single line:

```
| `/create-vi <JIRA-KEY> [@idea.md] [--lean\|--hybrid\|--full]` | VI authoring (PM phase, sub-project 2 of the VI-creation flow). Turns a refined `idea.md` + a **user-supplied Jira key** (empty workitem created first; mandatory) into a product-level **Value Increment** — a mandatory spine (Problem · Goal · Target audience · User Stories · Acceptance Criteria · Scope · Success Metrics) plus an adapt-in menu selected by `--lean\|--hybrid\|--full` and pulled only when the idea warrants it. Authored via a relentless grill against `references/vi-format.md`, gated by the Opus `vi-reviewer`, written to `$SPECS_PATH/specifications/<KEY>-<slug>/<KEY>_ValueIncrement.md` (relocated `idea.md` co-located; `sources` propagated from the idea's real provenance), branch+PR offer, and a documented paste-into-Jira + re-import round-trip. Product-level: no code scan, no repos. Offers `/release-notes` and `/create-ard` as next steps. |
```

- [ ] **Step 4: Cost-phase count** — `on the seven VI-lifecycle commands (\`/idea\`, \`/specify\`,` → `on the eight VI-lifecycle commands (\`/idea\`, \`/create-vi\`, \`/specify\`,` (the `- **Terminal cost phase**` line).

- [ ] **Step 5: Reference-list cost line** — `the terminal cost phase of the seven VI-lifecycle commands` → `the terminal cost phase of the eight VI-lifecycle commands`.

- [ ] **Step 6: Feedback list** — `all nine workflow commands` → `all ten workflow commands`; and add `/create-vi` to the enumeration: `\`/specify\`, \`/design\`, \`/idea\`) projects` → `\`/specify\`, \`/design\`, \`/idea\`, \`/create-vi\`) projects`.

- [ ] **Step 7: Verify**

```bash
cd /workspace/ihudak-claude-plugins
r=plugins/dev-workflows/README.md
grep -q "Eleven workflow slash commands for idea refinement, VI authoring" "$r" \
  && grep -q "| \`/create-vi <JIRA-KEY>" "$r" \
  && grep -qF "eight VI-lifecycle commands (\`/idea\`, \`/create-vi\`" "$r" \
  && grep -q "terminal cost phase of the eight VI-lifecycle commands" "$r" \
  && grep -q "all ten workflow commands" "$r" \
  && grep -qF "\`/idea\`, \`/create-vi\`) projects" "$r" \
  && ! grep -q "Ten workflow slash commands" "$r" \
  && echo "OK readme"
```
Expected: `OK readme`

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/README.md
git commit -m "docs(readme): document /create-vi command

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Whole-branch verification (after all tasks)

```bash
cd /workspace/ihudak-claude-plugins
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki   # expect: no output (siblings untouched)
python3 -c "import json;a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));m={p['name']:p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']};assert a['version']=='2.16.0'==m['dev-workflows']['version'];assert a['description']==m['dev-workflows']['description'];print('lockstep OK')"
git diff --stat main    # expect: 4 new + 10 modified = 14 files
```
Expected: no sibling diff; `lockstep OK`; 14 files changed.

Then finish via **superpowers:finishing-a-development-branch** (no tests — structural verification above is the gate): present merge/PR/keep/discard; **push only when the user asks**.

---

## Self-Review (against the spec)

**Spec coverage:** VI shape / one-format-3-profiles / inline authoring / Opus reviewer (T3+T4+T5) ✓; spine incl. US-N+AC-N (T3) ✓; adapt-in menu = Mike∪Alex, pulled-when-warranted (T3) ✓; `$SPECS_PATH` home + relocate-not-symlink + branch/PR + Jira round-trip (T5) ✓; product-level/no-code/no-repos (T5) ✓; grilling SSOT + retrofit (T1+T2) ✓; JIRA-KEY mandatory + graceful fail + auto-create dir (T5) ✓; idea.md ladder (T5) ✓; `sources` propagation + `derived_from` (T3+T5) ✓; both next steps `/release-notes`+`/create-ard` (T5) ✓; cost `vi-creation`/`pm` + feedback + emit-block (T5+T6) ✓; no HTML render (out of scope, not built) ✓; counts + lock-step + byte-identical + siblings untouched (T6+T7+T8) ✓. Carry-forward to `/create-ard` and the two follow-ups (next-phase-offer-everywhere, `.obsidian` revisit) recorded in the spec — not built here.

**Placeholder scan:** none — full content for all 4 new files; exact old→new for every edit.

**Type consistency:** `vi-reviewer` input (VI path + profile) matches Task 5's Phase 4 dispatch; `vi-format.md` frontmatter/spine names match Phase 3 authoring + the reviewer's checks; `phase: vi-creation`/`role: pm` match `cost-emission.md` §7 (promoted row); the retrofit citation path `references/grilling-technique.md` matches Task 1's filename.

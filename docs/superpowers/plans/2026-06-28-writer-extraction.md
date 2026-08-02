---
tags:
  - tasks-exclude
---

# Writer Extraction (docs + epics) + epics routing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the two inline Phase 6 writers (`/impl:jira:docs`, `/impl:jira:epics`) into write-only model-pinned subagents (`doc-writer`→Opus, `epic-writer`→Sonnet) fed by a structured handoff file, and fold in the deferred epics per-step routing.

**Architecture:** Two new write-only agents own the "how to write" mechanics; the orchestrators become thin (write a temp handoff file → dispatch the writer with its path → docs orchestrator commits, epics commits nothing). The shared per-step policy (`classification.md §9`) gains a delegated-writer row + two clarifications. Output contract is unchanged, so Phases 6.7/6.8/7 and the `doc-reviewer` backstop are untouched.

**Tech Stack:** Markdown command/agent/reference files in the `dev-workflows` plugin. No code, **no test framework** — verification is structural (`grep`/`awk`/`python3` YAML/JSON parse).

## Global Constraints

- Repo: `/workspace/ihudak-claude-plugins`; plugin under `plugins/dev-workflows/`. Plugin `main` @ `9a4cb85`, v1.15.0.
- Release is **MINOR `v1.16.0`**.
- **No test framework** — every "test" step is a structural check. No pytest/npm.
- **Match by anchor text, not line number** — moving large blocks shifts line numbers; identify blocks by their heading/anchor text.
- **`model:` override syntax** mirrors the existing dispatches: `→ Agent (subagent_type: "…", model: \`<chain note>\`):`.
- **Writers are write-only**: tools `["Read", "Glob", "Grep", "LS", "Write", "Edit"]` — **no Bash, no git**. `Write` auto-creates parent dirs.
- **Handoff file is a temp file** (`mktemp` under `$TMPDIR`/`/tmp`) — *never* the vault, *never* the docs repo; never committed; decoupled from `$VAULT_PATH`.
- **doc-writer → §2 Opus chain; epic-writer → §2.1 Sonnet chain** (escalate epic-writer to §2 only if the run is SIGNIFICANT/HIGH-RISK).
- **docs**: orchestrator commits the writer's output (branch from Phase 6.5, squash at 8.5). **epics**: NEVER branches/commits (per its invariants — vault git is the user's).
- `epic-reviewer` / `doc-reviewer` keep their frontmatter Opus pins (no dispatch override).
- marketplace.json version is at `plugins[0].version` (NOT top-level).
- Stage **explicit paths** only — never `git add -A`; never `.superpowers/`.
- Commit trailer on every commit: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Output contract of both writers is **unchanged** (same files/locations/markers/traceability).

---

### Task 1: classification.md §9 — delegated-writer policy + two clarifications

**Files:**
- Modify: `plugins/dev-workflows/references/model-routing/classification.md` (§9.1, §9.2, §9.4)

**Interfaces:**
- Produces: the §9.2 role rows + §9.1 gate + §9.4 refinement that docs.md/epics.md cite.

- [ ] **Step 1: §9.1 — gate the advisory on classification**

Find the §9.1 third bullet (the "Orchestrator-executed" bullet, beginning `- **Orchestrator-executed** judgment steps`). Append this sentence to the end of that bullet:

```
 This advisory applies when the task is SIGNIFICANT/HIGH-RISK; for SIMPLE/MODERATE the writer runs on its detection pin without a relaunch advisory (per §3.1).
```

- [ ] **Step 2: §9.2 — split the inline-writer row into delegated-writer + orchestrator rows**

In the §9.2 role→chain table, find the row:

```
| Inline writer + interactive gates (the orchestrator itself) | session model → §9.1 advisory |
```

Replace it with these two rows:

```
| Delegated writer (`doc-writer` / `epic-writer`) | §2 reasoning (Opus) for SIGNIFICANT/judgment writing; §2.1 detection (Sonnet) for MODERATE writing |
| Coordination + interactive gates (the orchestrator itself) | session model; narrowed window advisory for large non-Opus runs (§9.1) |
```

- [ ] **Step 3: §9.4 — code-scanner-no-synthesis refinement**

At the end of the §9.4 paragraph (after the sentence ending `…governed by §8.3 when invoked under the large-input fan-out trigger.`), append:

```
 Refinement: `code-scanner` inherits under §8.3 **only when a powerful-chain synthesis step consumes its output**; in an authoring pipeline with no such step (e.g. `/impl:jira:epics`, where the writer is a detection/reasoning-pinned subagent and there is no risk-planner synthesis), pin `code-scanner` to the detection chain.
```

- [ ] **Step 4: Verify**

Run: `grep -nE 'Delegated writer|Coordination \+ interactive|only when a powerful-chain|relaunch advisory \(per §3.1\)' plugins/dev-workflows/references/model-routing/classification.md`
Expected: 4 matches — the two new table rows, the §9.4 refinement, and the §9.1 gate sentence.

Run: `grep -c 'Inline writer + interactive gates (the orchestrator itself) | session model → §9.1 advisory' plugins/dev-workflows/references/model-routing/classification.md`
Expected: **0** (the old single row is gone).

Run: `awk 'BEGIN{c=0} /^```/{c++} END{print c}' plugins/dev-workflows/references/model-routing/classification.md`
Expected: even (no fence change).

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/model-routing/classification.md
git commit -m "PRODUCT model-routing: §9 delegated-writer rows + advisory gate + code-scanner refinement

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: doc-writer agent (new)

**Files:**
- Create: `plugins/dev-workflows/agents/doc-writer.md`
- Reference (read-only, to relocate from): `plugins/dev-workflows/commands/impl/jira/docs.md` Phase 6 write mechanics

**Interfaces:**
- Produces: agent `dev-workflows:doc-writer`, consuming a handoff-file path; returns `status: DONE | BLOCKED` + `files_written[]` + `notes`.

- [ ] **Step 1: Create the agent with frontmatter + Inputs + validation (verbatim)**

Create `plugins/dev-workflows/agents/doc-writer.md` with this content:

````markdown
---
name: doc-writer
description: Writes product documentation for /impl:jira:docs from a structured handoff file — applies the doc-planner checklist, the approved per-page write strategies (conditional / override-copy / plain), discrepancy decisions, snippets, screenshots, frontmatter, and internal links. Write-only (no git). Returns the list of files written. The orchestrator pins it to the §2 Opus reasoning chain.
tools: ["Read", "Glob", "Grep", "LS", "Write", "Edit"]
---

Product-documentation writer for `/impl:jira:docs` Phase 6. The orchestrator has already resolved every decision (Phases 3–6.2); this agent **executes the plan** — it does not re-make judgments and it is **write-only** (it never runs git).

## Inputs

The orchestrator writes a single **handoff file** (a temp file) and passes its absolute path. Read it first. It contains:

- `jira_reader_handoff`, `diff_summaries`
- `write_targets` — the confirmed write-target list (Phase 5.5)
- `doc_planner_checklist` — the Phase 5.7 checklist + gap dispositions (TODO markers)
- `discrepancy_decisions[]` — Phase 5.8 `{number, claim, jira_phrasing, spec_phrasing, source_phrasing, source_location, decision, rationale}`
- `write_strategies[]` — Phase 5.9 `{target_path, strategy ∈ {conditional, override-copy, plain}, target_space, rationale}`
- `cdn_handoff_decision` ∈ {upload-now, defer}, `cdn_urls{}`, `screenshot_staging_dir`, `screenshots[]`
- `target_spaces`, `profile`, `docs_repo_path`
- `bug_report_destination` (for `document-as-spec`/`skip-and-report` gaps)

Multi-space mechanics are governed by `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md` and discrepancy application by `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.4–§7.6 — read them; this agent carries the data, those carry the logic.

## Entry validation (BLOCKED, never guess)

Before writing, validate the handoff. Return `status: BLOCKED` with the specific gap — do **not** invent output — when any of these holds:

- the handoff file is missing/unreadable, or `write_targets` is empty;
- a target's `write_strategy.strategy` is `override-copy` or `conditional` but `target_space` is absent;
- a target's home space (matched against `profile.spaces[].content_root`/`snippet_root`) is **not** in `target_spaces` and the target is not an `override-copy` destination;
- a screenshot has `image_policy: cdn_upload_required`, `cdn_handoff_decision: upload-now`, but no `cdn_urls[<image>]`.

## Write mechanics

<!-- TASK 2 STEP 2: the relocated docs.md Phase 6 steps 0–9 go here -->

## Output

Write/modify files only — **never commit**. Return:

- `status: DONE | BLOCKED`
- `files_written: [absolute paths of every file created or modified]`
- `notes: [TODO/placeholder markers emitted, staged screenshots, intentional-discrepancy markers + the implementation-gaps draft path — for the Phase 9 report]`
- on `BLOCKED`: the specific missing/inconsistent input.
````

- [ ] **Step 2: Relocate the write mechanics from docs.md into the agent**

Open `plugins/dev-workflows/commands/impl/jira/docs.md`. Copy the Phase 6 write-mechanics block — from the line beginning `Multi-space safety is governed by` through the end of **step 9** (`Token-correctness validation … do not defer them to Phase 6.7.`) — into `doc-writer.md`, replacing the `<!-- TASK 2 STEP 2: … -->` placeholder. Paste it **verbatim**, then make exactly these adjustments so it reads as agent instructions consuming the handoff (not orchestrator phases):

- The routing-error line "**A target whose home space is not in `target_spaces` is a routing error — stop and surface it**" → change "stop and surface it" to "**return `status: BLOCKED`** naming the target (per Entry validation)".
- Any "(from Phase 5.9 `write_strategies[]`; absent ⇒ `plain`)" → "(from the handoff `write_strategies`; absent ⇒ `plain`)".
- "Apply discrepancy decisions (from Phase 5.8)" → "Apply discrepancy decisions (from the handoff `discrepancy_decisions`)".
- "the Phase 6.2 `cdn_handoff_decision`" → "the handoff `cdn_handoff_decision`".
- "`<screenshot_staging_dir>` … resolved in Phase 1" → "`screenshot_staging_dir` (from the handoff)".
- "`<bug_report_destination>`" stays (it's a handoff field).
- Do **not** copy the line `Write to the resolved docs_repo_path (Phase 0). Branch and commit policy is governed by…` or the write-context table — those stay in the orchestrator (Task 3). The agent writes under the handoff's `docs_repo_path` and never commits.

- [ ] **Step 3: Verify the agent**

Run: `grep -nE '^name: doc-writer|^tools:|## Inputs|## Entry validation|## Write mechanics|## Output' plugins/dev-workflows/agents/doc-writer.md`
Expected: name, tools, and all four `##` sections present.

Run: `grep -c 'TASK 2 STEP 2' plugins/dev-workflows/agents/doc-writer.md`
Expected: **0** (the placeholder was replaced).

Run: `grep -nE 'override-copy|conditional|\{\{#if project|managed/docstack.jsonc|Token-correctness' plugins/dev-workflows/agents/doc-writer.md`
Expected: ≥4 matches (the relocated strategy mechanics + token step landed).

Run: `grep -n 'no Bash\|Bash' plugins/dev-workflows/agents/doc-writer.md; python3 -c "import re;t=open('plugins/dev-workflows/agents/doc-writer.md').read();import sys;print('tools-ok' if '\"Bash\"' not in t else 'BASH-PRESENT')"`
Expected: `tools-ok` (no Bash in the tools list).

Run: `awk 'BEGIN{c=0} /^```/{c++} END{print c}' plugins/dev-workflows/agents/doc-writer.md`
Expected: even.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/doc-writer.md
git commit -m "PRODUCT impl:jira:docs: add doc-writer agent (write-only, handoff-file fed)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: docs.md — extract Phase 6 to doc-writer; narrow the advisory

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md` (Phase 6 body, Phase 1.5 advisory, model_routing block)

**Interfaces:**
- Consumes: `dev-workflows:doc-writer` (Task 2), §9 (Task 1).

- [ ] **Step 1: Replace the Phase 6 inline mechanics with the thin orchestration**

In `docs.md` Phase 6, the relocated block (everything from `Multi-space safety is governed by` through step 9 `…do not defer them to Phase 6.7.`) was copied into `doc-writer.md` in Task 2. Now **delete that block from docs.md** and replace the paragraph at `The main command writes the markdown following the doc-planner checklist. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5.7 already loaded.` plus the deleted mechanics with:

````markdown
The writing is delegated to the **`doc-writer`** subagent (pinned to the §2 Opus reasoning chain — see `classification.md` §9.2). The orchestrator prepares a structured handoff and dispatches; it does not write pages itself.

1. **Write the handoff file.** Create a temp file (`mktemp`, e.g. `$(mktemp -t dw-<JIRA_KEY>-XXXX.yml)` — never the vault, never the docs repo) containing the `doc-writer` input contract: `jira_reader_handoff`, `diff_summaries`, `write_targets`, `doc_planner_checklist` (+ gap dispositions), `discrepancy_decisions` (Phase 5.8), `write_strategies` (Phase 5.9), `cdn_handoff_decision` + `cdn_urls` + `screenshot_staging_dir` + `screenshots` (Phase 6.2), `target_spaces`, `profile`, `docs_repo_path`, and `bug_report_destination`. Record its absolute path.

2. **Dispatch the writer:**

→ Agent (subagent_type: "dev-workflows:doc-writer", model: `<planning_model — §9 / §2 Opus chain>`):
  > "Write the product documentation for this brief.
  >
  > handoff_file: [absolute path of the temp handoff file from step 1]"

3. **Handle the return.**
   - **`status: DONE`** — record `files_written` + `notes` for Phases 6.7 / 6.8 / 7 / 8. Then **commit** per the branch/commit policy below.
   - **`status: BLOCKED`** — surface the named gap to the user:
     ```
     choices: ["Provide the missing input (you'll be prompted)", "Cancel"]
     ```
     On a provided value, rewrite the handoff file and re-dispatch once.

Write context governs branch/commit (Phase 0 step 7); **the orchestrator commits the writer's output** (the writer never commits):

| Write context | Branch | Commit |
|---|---|---|
| `obsidian` | NEVER | NEVER |
| `docs_repo` | YES (opt-in confirmed at plan approval) — see Phase 6.5 | YES (orchestrator commits doc-writer's `files_written`) |
| `non_docs_repo` | Phase 0 step 3 already asked user to confirm; if confirmed, behave as `docs_repo` | YES (if user confirmed at Phase 0) |
| `plain_dir` | NEVER | NEVER |
````

Keep the existing **"Execution order with Phase 6.5"** note at the top of Phase 6 unchanged (it still applies — 6.5 creates the branch before this phase; the orchestrator now commits the writer's output rather than its own).

- [ ] **Step 2: Narrow the Phase 1.5 advisory**

In `docs.md` Phase 1.5, find the advisory block (the three-branch logic added in v1.15.0, beginning `**Writer / orchestration advisory.**`). Replace its body with:

````markdown
**Orchestration advisory (window-focused).** `doc-planner` (5.7) and `doc-writer` (6) run on the §2 Opus chain regardless of session; only coordination + the interactive gates (4.5, 5.8 decision, 5.9, 6.2) run on `current_model`. So:

- **`current_model` is on the §2 chain** → no advisory.
- **`current_model` is NOT on the §2 chain and `opus_available: true`** → the heavy synthesis + writing are already on Opus; the residual risk is the orchestrator's **context window** on a **large multi-repo ticket**. Offer relaunch **only** in that case:
  ```
  choices: ["Relaunch /impl:jira:docs under Opus — I'll restart (Recommended for large multi-repo tickets)", "Proceed on <current_model>", "Cancel"]
  ```
  Otherwise proceed without prompting.
- **`current_model` is NOT on the §2 chain and `opus_available: false`** → `planning_model`, `review_model`, and the **doc-writer** all fall to the Sonnet floor; record the degradation in `notes` and the Phase 9 report; proceed.
````

- [ ] **Step 3: Update the model_routing block's `implementation_model`**

In `docs.md` Phase 1.5 `model_routing` block, change the `implementation_model` line from `implementation_model: <= current_model>  # the INLINE writer (Phase 6) + discrepancy framing (5.8); not overridable` to:

```
  implementation_model: <= planning_model>  # the doc-writer subagent (Phase 6) — now a delegated, Opus-pinned writer
```

- [ ] **Step 4: Verify**

Run: `grep -c 'doc-writer' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: ≥3 (the dispatch + the advisory mention + the implementation_model comment / commit-table).

Run: `grep -c 'The writer is NOT a separate subagent' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: **0** (the inline-writer paragraph is gone).

Run: `grep -c 'Token-correctness validation' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: **0** (the write mechanics were relocated to the agent in Task 2/3).

Run: `grep -nE 'subagent_type: "dev-workflows:doc-writer", model: `<planning_model|implementation_model: <= planning_model>|Orchestration advisory \(window-focused\)' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: 3 matches.

Run: `awk 'BEGIN{c=0} /^```/{c++} END{print c}' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: even.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "PRODUCT impl:jira:docs: delegate Phase 6 to doc-writer; narrow Phase 1.5 advisory

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: epic-writer agent (new)

**Files:**
- Create: `plugins/dev-workflows/agents/epic-writer.md`
- Reference (read-only, to relocate from): `plugins/dev-workflows/commands/impl/jira/epics.md` Phase 6 template

**Interfaces:**
- Produces: agent `dev-workflows:epic-writer`, consuming a handoff-file path; returns `status: DONE | BLOCKED` + `files_written[]`.

- [ ] **Step 1: Create the agent with frontmatter + Inputs + validation + output (verbatim)**

Create `plugins/dev-workflows/agents/epic-writer.md` with this content:

````markdown
---
name: epic-writer
description: Writes child Epic-definition files for /impl:jira:epics from a structured handoff file — one file per Epic, following the Epic template, traceable to the jira-reader handoff and code-scanner evidence. Write-only (vault content; never commits). Returns the list of Epic files written. The orchestrator pins it to the §2.1 Sonnet detection chain for MODERATE runs (§2 Opus only if SIGNIFICANT/HIGH-RISK).
tools: ["Read", "Glob", "Grep", "LS", "Write", "Edit"]
---

Epic-definition writer for `/impl:jira:epics` Phase 6. The orchestrator resolved scope and inputs in Phases 2–5; this agent **executes** — write-only, and it **never** creates a branch or commits (vault git is the user's responsibility).

## Inputs

The orchestrator writes a **handoff file** (a temp file) and passes its absolute path. Read it first. It contains:

- `jira_reader_handoff`
- `code_scanner_outputs` (when code scan ran; else empty)
- `scope` — the Phase 2 in-scope / out-of-scope decisions
- `existing_epics` — for non-duplication
- `output_dir` — the resolved output directory (default `$VAULT_PATH/jira-drafts/<JIRA_KEY>/`)
- `vi_goal`, `jira_key`

## Entry validation (BLOCKED, never guess)

Return `status: BLOCKED` with the specific gap when: the handoff file is missing/unreadable; `output_dir` is absent; or there are no Epics to write (empty scope + no derived Epics).

## Write mechanics

<!-- TASK 4 STEP 2: the relocated epics.md Phase 6 template + rules go here -->

## Output

Write Epic files only — **never branch, never commit**. Return:

- `status: DONE | BLOCKED`
- `files_written: [absolute paths of every Epic file written]`
- `notes: [non-duplication notes, any Epic skipped as duplicate]`
````

- [ ] **Step 2: Relocate the template + write rules from epics.md into the agent**

Open `plugins/dev-workflows/commands/impl/jira/epics.md` Phase 6. Copy — **verbatim** — the block from `For each new Epic, emit a markdown file under the resolved output directory` through the **Write restrictions** list (ending `- ALWAYS write inside the resolved output directory from Phase 1 (default jira-drafts/<VI-KEY>/).`), including the full ```markdown Epic template```, the `Create the output directory if missing` line, and the Traceability paragraph. Paste it into `epic-writer.md`, replacing the `<!-- TASK 4 STEP 2: … -->` placeholder, with these adjustments:

- "Create the output directory if missing (`mkdir -p`)." → "Create the output directory if missing — your `Write` tool auto-creates parent directories (no shell)."
- "default `$VAULT_PATH/jira-drafts/<JIRA_KEY>/`" and "from Phase 1" references → "the handoff `output_dir`".
- "the `jira-reader` handoff" / "`code-scanner` outputs" → "the handoff `jira_reader_handoff` / `code_scanner_outputs`".

- [ ] **Step 3: Verify the agent**

Run: `grep -nE '^name: epic-writer|^tools:|## Inputs|## Entry validation|## Write mechanics|## Output' plugins/dev-workflows/agents/epic-writer.md`
Expected: name, tools, all four `##` sections present.

Run: `grep -c 'TASK 4 STEP 2' plugins/dev-workflows/agents/epic-writer.md`
Expected: **0**.

Run: `grep -nE '## Goal|## Acceptance criteria|## Scope|Suggested stories' plugins/dev-workflows/agents/epic-writer.md`
Expected: ≥4 (the relocated Epic template landed).

Run: `python3 -c "t=open('plugins/dev-workflows/agents/epic-writer.md').read();print('tools-ok' if '\"Bash\"' not in t else 'BASH-PRESENT')"`
Expected: `tools-ok`.

Run: `awk 'BEGIN{c=0} /^```/{c++} END{print c}' plugins/dev-workflows/agents/epic-writer.md`
Expected: even.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/epic-writer.md
git commit -m "PRODUCT impl:jira:epics: add epic-writer agent (write-only, handoff-file fed)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: epics.md — extract Phase 6; wire per-step routing

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/epics.md` (Phase 6, Phase 1.5, dispatches, Phase 9, invariants)

**Interfaces:**
- Consumes: `dev-workflows:epic-writer` (Task 4), §9 (Task 1).

- [ ] **Step 1: Replace the Phase 6 inline writing with an epic-writer dispatch**

In `epics.md` Phase 6, replace the paragraph `The main command drafts child Epic definitions — one file per Epic — following the jira-reader handoff and (when code scan ran) the code-scanner outputs. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5 already loaded.` **and** the relocated template/rules block (moved to the agent in Task 4) with:

````markdown
The drafting is delegated to the **`epic-writer`** subagent (pinned to the §2.1 Sonnet detection chain for MODERATE; §2 Opus only if the run is SIGNIFICANT/HIGH-RISK — see `classification.md` §9.2). The orchestrator prepares a handoff and dispatches; it does not write Epics itself, and **nothing commits** (epics never branches/commits — vault git is the user's responsibility).

1. **Write the handoff file.** Create a temp file (`mktemp` — never the vault, never a repo) containing the `epic-writer` input contract: `jira_reader_handoff`, `code_scanner_outputs` (empty if no scan), `scope` (Phase 2 in/out of scope), `existing_epics` (non-duplication), `output_dir` (resolved Phase 1 dir), `vi_goal`, `jira_key`. Record its absolute path.

2. **Dispatch the writer:**

→ Agent (subagent_type: "dev-workflows:epic-writer", model: `<detection_model — §9 / §2.1 Sonnet chain; planning_model (§2 Opus) only if classification is SIGNIFICANT/HIGH-RISK>`):
  > "Write the child Epic definitions for this brief.
  >
  > handoff_file: [absolute path of the temp handoff file from step 1]"

3. **Handle the return.** `status: DONE` → record `files_written` for Phase 6.7 onward. `status: BLOCKED` → surface the named gap:
   ```
   choices: ["Provide the missing input (you'll be prompted)", "Cancel"]
   ```
   On a provided value, rewrite the handoff and re-dispatch once. Nothing is committed (vault git is the user's responsibility).
````

- [ ] **Step 2: Add `model:` overrides to the detection dispatches**

Add `, model: \`<detection_model — §9 / §2.1 Sonnet chain>\`` before the closing `):` of each of these dispatches (match by anchor text):

| Find | Add model |
|------|-----------|
| `→ Agent (subagent_type: "dev-workflows:jira-reader"):` | detection |
| `→ Agent (subagent_type: "dev-workflows:code-scanner"):` | detection |
| `→ Agent (subagent_type: "dt-style-guide:dt-style-checker"):` | detection |
| `→ Agent (subagent_type: "dev-workflows:doc-fixer"):` (×2 — replace-all; note any indentation) | detection |

Leave `→ Agent (subagent_type: "dev-workflows:epic-reviewer"):` **unchanged** (frontmatter Opus governs).

- [ ] **Step 3: Phase 1.5 — model_routing block + reword**

In `epics.md` Phase 1.5, after the classify paragraph, add a `model_routing` block and reword. Replace the line `MODERATE → no Opus planning; `epic-reviewer` gate is mandatory.` with:

````markdown
MODERATE → no separate Opus planner; the `epic-reviewer` gate (Opus, frontmatter-pinned) is mandatory. Resolve the per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-4-6, fallback claude-sonnet-4-5>   # jira-reader, code-scanner, dt-style-checker, doc-fixer, epic-writer (MODERATE)
  review_model:    <§2 Opus chain>     # epic-reviewer (frontmatter-pinned; recorded, no override)
  implementation_model: <= detection_model>   # the epic-writer subagent (Phase 6); planning_model if SIGNIFICANT/HIGH-RISK
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

Each subagent dispatch below cites its chain (§9 role→chain map). **No relaunch advisory** for MODERATE — the writer runs on its detection pin and the gates run on `current_model`, which §3.1 allows (if a run is classified SIGNIFICANT/HIGH-RISK, the §9.1 advisory applies and `epic-writer` escalates to the §2 chain). If no Opus is available, `epic-reviewer` falls to the Sonnet floor — record the degradation in `notes` and the Phase 9 report.
````

- [ ] **Step 4: Phase 9 — add the Model Routing section**

In `epics.md` Phase 9, find `### Classification` (its line + the value line under it) and insert immediately after that value line:

```
### Model Routing
- Session model (current_model): [model]
- epic-writer (implementation_model): [model] — detection (MODERATE) | reasoning (SIGNIFICANT)
- Detection steps — jira-reader, code-scanner, dt-style-checker, doc-fixer (detection_model): [model]
- epic-reviewer (review_model): [model]
- Opus available: [yes | no]
```

- [ ] **Step 5: Add the routing invariant**

In `epics.md` `## Invariants (always enforced)`, after the line `- ALWAYS invoke `epic-reviewer` before Phase 8 maintenance`, add:

```
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin each subagent dispatch to its §9 chain via `model:` — the mechanical steps (`jira-reader`, `code-scanner`, `dt-style-checker`, `doc-fixer`) and `epic-writer` (MODERATE) to the §2.1 Sonnet chain; `epic-reviewer` keeps its frontmatter Opus pin (no override); coordination + interactive gates run on `current_model`
- ALWAYS delegate Phase 6 writing to the `epic-writer` subagent (write-only); the orchestrator never writes Epics itself and never commits (vault git is the user's responsibility)
```

- [ ] **Step 6: Verify**

Run: `grep -c 'epic-writer' plugins/dev-workflows/commands/impl/jira/epics.md`
Expected: ≥4 (dispatch + 1.5 mention + 2 invariants / Phase 9).

Run: `grep -c 'The writer is NOT a separate subagent' plugins/dev-workflows/commands/impl/jira/epics.md`
Expected: **0**.

Run: `grep -c '## Goal' plugins/dev-workflows/commands/impl/jira/epics.md`
Expected: **0** (the Epic template was relocated to the agent).

Run: `grep -c '<detection_model' plugins/dev-workflows/commands/impl/jira/epics.md`
Expected: **6** — the 5 mechanical dispatch overrides (`jira-reader`, `code-scanner`, `dt-style-checker`, `doc-fixer` ×2) **plus** the `epic-writer` dispatch's `model:` note (it cites `<detection_model …` for the MODERATE case). The `model_routing` block uses `detection_model:` and `<= detection_model` (neither matches the `<detection_model` pattern), so they do not count. If you get 5, a mechanical override was missed; if 7, an extra crept in.

Run: `grep -n 'subagent_type: "dev-workflows:epic-reviewer"' plugins/dev-workflows/commands/impl/jira/epics.md`
Expected: the epic-reviewer dispatch has **no** `model:` (confirm visually).

Run: `grep -nE '^### Model Routing|model_routing:|ALWAYS resolve the .model_routing|ALWAYS delegate Phase 6' plugins/dev-workflows/commands/impl/jira/epics.md`
Expected: 4 matches.

Run: `awk 'BEGIN{c=0} /^```/{c++} END{print c}' plugins/dev-workflows/commands/impl/jira/epics.md`
Expected: even.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/epics.md
git commit -m "PRODUCT impl:jira:epics: delegate Phase 6 to epic-writer; per-step model routing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Release v1.16.0

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/dev-workflows/CHANGELOG.md`

- [ ] **Step 1: Confirm current versions**

Run: `grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json; python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])"`
Expected: both `1.15.0`.

- [ ] **Step 2: Bump plugin.json** — top-level `"version": "1.15.0",` → `"version": "1.16.0",`.

- [ ] **Step 3: Bump marketplace.json** — `plugins[0].version` `1.15.0` → `1.16.0`.

- [ ] **Step 4: CHANGELOG entry** — add above `## [1.14.2]`/`## [1.15.0]` (match the em-dash house style):

```markdown
## [1.16.0] — 2026-06-28

### Changed
- `/impl:jira:docs` and `/impl:jira:epics`: the Phase 6 writers are extracted into dedicated write-only subagents (`doc-writer`, `epic-writer`) fed by a structured temp handoff file. `doc-writer` is pinned to the Opus reasoning chain (closes the docs writer gap on non-Opus sessions); `epic-writer` is pinned to the Sonnet detection chain for MODERATE runs (stops MODERATE Epic writing from running on an Opus session). Orchestrators commit (docs) or never commit (epics) as before; output is unchanged.
- `/impl:jira:docs` Phase 1.5 advisory narrowed to a context-window note (the synthesis and writing now run on Opus regardless of session).

### Added
- `/impl:jira:epics`: per-step model routing — `jira-reader`, `code-scanner`, `dt-style-checker`, `doc-fixer` pinned to the Sonnet detection chain; `epic-reviewer` keeps its Opus pin; a `model_routing` block + Phase 9 `### Model Routing` section.
- `classification.md` §9: delegated-writer routing rows, the advisory classification gate, and the code-scanner-no-synthesis refinement.
```

- [ ] **Step 5: Verify**

Run: `grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json; python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])"; grep -n '## \[1.16.0\]' plugins/dev-workflows/CHANGELOG.md`
Expected: plugin.json → `1.16.0`; marketplace → `1.16.0`; CHANGELOG `[1.16.0]` heading present.

Run: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('JSON OK')"`
Expected: `JSON OK`.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "PRODUCT dev-workflows v1.16.0: extract Phase 6 writers to subagents; epics routing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Notes for the executor

- Branch off `origin/main` (`9a4cb85`): e.g. `ivgu/NOISSUE-writer-extraction`. Do not implement on `main`.
- Tasks 2→3 (doc-writer agent, then docs.md wiring) and 4→5 (epic-writer agent, then epics.md wiring) are ordered: the agent must exist before the command that dispatches it, and Task 2/4 relocate the mechanics that Task 3/5 then delete from the command.
- After all tasks + reviews, run the whole-branch Opus review, then finishing-a-development-branch (user merges ff to plugin `main` + pushes origin + deletes branch).
- The dynatrace-docs CLAUDE.md prettier/husky note does NOT apply to this plugin repo — N/A.

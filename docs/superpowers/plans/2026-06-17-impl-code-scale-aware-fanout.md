# Scale-aware fan-out scanning for `/impl:code` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teach `/impl:code` to accept multi-source input (spec files, Jira ticket folders, spec folders, multiple repos) and, when input shape signals scale, run a parallel fan-out scan whose synthesis routes to Opus — expressed as a shared policy all scanning agents can cite.

**Architecture:** A new input-shape trigger in `classification.md` floors large-input tasks at SIGNIFICANT (reusing the existing Opus planning + review gates). `/impl:code` gains multi-`@path` parsing, an input-scale assessment, and a new Phase 1.7 that fans out `jira-reader` + per-repo `code-scanner` (cap 4 concurrent) and synthesizes their reports into the planner's codebase summary. Small-input invocations keep the current single-explorer path unchanged.

**Tech Stack:** Markdown command/agent/reference files in the `dev-workflows` Claude Code plugin. No compiled code, no unit-test framework — verification is cross-reference integrity (grep/read) and the plugin's "no stale cross-references" invariant from `CLAUDE.md`.

## Global Constraints

- Reference bundled files from **agent/skill** bodies via `${CLAUDE_PLUGIN_ROOT}/...`; **commands** must not (they use the `model-routing` skill). Verbatim from `CLAUDE.md`.
- Never hardcode `~/.claude/plugins/data/...@.../` paths.
- Agent `.md` files must start with YAML frontmatter containing at minimum `name` and `description`.
- Surgical changes only: if a phase, field, or workflow edge is added or removed, every cross-reference to it (in commands, agents, `classification.md`, `README.md`, `CLAUDE.md`) must be updated in the same change.
- `classification.md` is the single source of truth for model routing; the new fan-out policy lives there, and `/impl:code` cites it rather than restating rules.
- Concurrency cap for parallel scanners is **4**, matching `/impl:jira:epics`.
- Scanning agents (`jira-reader`, `code-scanner`) are read-only and inherit the session model unless a single slice is explicitly escalated.
- LF line endings; match surrounding markdown style.

**Source spec:** `docs/superpowers/specs/2026-06-17-impl-code-scale-aware-fanout-design.md`

**Branch:** all work lands on `docs/impl-code-scale-fanout-spec` (already created; the spec commit is its first commit) — or a fresh `feat/impl-code-scale-fanout` branch if the executor prefers to separate spec from implementation. Pick one and stay on it.

---

### Task 1: Shared fan-out policy in `classification.md`

This is the source of truth; it must land first so later tasks can cite it.

**Files:**
- Modify: `plugins/dev-workflows/references/model-routing/classification.md` (§1.1 list; append new §8)

**Interfaces:**
- Produces: §1.1 trigger phrase *"Multi-source input"* and a new section heading **`## 8. Large-input scan fan-out`** that `code.md`, `README.md`, and `CLAUDE.md` reference by number/name.

- [ ] **Step 1: Add the §1.1 trigger bullet**

In §1.1 (the "Classify as SIGNIFICANT or HIGH-RISK if any of the following apply" list), add a new bullet immediately after the "Changes touching more than 3–5 non-test files." bullet:

```markdown
- **Multi-source input** — `/impl:code` was given more than one code repository, or any directory input (an exported Jira ticket folder, or a spec/design folder). Large multi-source briefs are cross-cutting by nature; this floors the task at `SIGNIFICANT`. See §8 for the fan-out scan this triggers. The floor is overridable at plan approval if the user judges the work genuinely smaller than its input footprint.
```

- [ ] **Step 2: Append the new §8 section**

After §7 (Reporting), append:

```markdown
---

## 8. Large-input scan fan-out

When a scanning step must digest more than a single working tree, a single
explorer subagent on a weak session model comprehends it poorly. This section
is the shared policy for that case. It is consulted by `/impl:code` and
generalizes the pattern `/impl:jira:epics` already uses.

### 8.1 Trigger (input shape, not measured volume)

Fan out when **any** of these structural facts hold for the invocation:

- more than one code repository is referenced;
- an exported Jira ticket folder is supplied;
- a spec/design folder is supplied.

Counting files or bytes is explicitly **not** used — the trigger is the shape
of the input, which is cheap to detect and easy to explain. A single repo with
inline/`@file` text only does **not** trigger fan-out; the caller keeps its
normal single-explorer path.

### 8.2 The fan-out pattern

1. `jira-reader` reads each ticket folder (read-only) → themes, PR references
   (identifiers only), linked items.
2. Spec/design folders are read inline and folded into the themes.
3. `code-scanner` is fanned out **one instance per repository, in a single
   response, capped at 4 concurrent**. Each instance receives the themes and
   its own repo path; it returns capabilities, gaps, and relevant files.
4. The orchestrator synthesizes the `jira-reader` output, all scanner reports,
   and the spec into one codebase summary that feeds the Opus planner.

### 8.3 Model routing inside the fan-out

- `jira-reader` and `code-scanner` **inherit the session model** — each handles
  a bounded slice, so even a Sonnet-pinned session copes.
- Because the trigger floors the task at `SIGNIFICANT` (§1.1), synthesis and
  planning run on the strongest available reasoning model via `risk-planner`
  (§2 chain). That is where the "more powerful model for the scan/plan step"
  requirement is satisfied — no separate synthesis-model knob is introduced.
- **Optional escalation:** if a single repo slice is itself oversized, the
  orchestrator MAY pin that one `code-scanner` to Opus via the `task` tool
  `model:` override. This is optional and judgment-based, not threshold-driven.

### 8.4 Honesty

A referenced directory that is missing, or is neither a recognized folder type
nor a git repository, MUST be surfaced to the user — never silently skipped
(mirrors the `REFRESH_BLOCKED` honesty rule used by the `/impl:jira:*` flows).
```

- [ ] **Step 3: Verify the section wiring**

Run: `grep -n "Multi-source input\|## 8. Large-input scan fan-out\|^### 8\." plugins/dev-workflows/references/model-routing/classification.md`
Expected: the §1.1 bullet line, the `## 8.` heading, and `### 8.1`/`### 8.2`/`### 8.3`/`### 8.4` subheadings all present.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/references/model-routing/classification.md
git commit -m "feat(dev-workflows): add large-input scan fan-out policy to classification.md"
```

---

### Task 2: Generalize `code-scanner` to non-Epic callers

`code-scanner` currently names `/impl:jira:epics` as its only caller and frames themes as Epic-scoped. `/impl:code` will call it with spec-derived themes. Keep the agent's behavior; broaden its framing.

**Files:**
- Modify: `plugins/dev-workflows/agents/code-scanner.md` (frontmatter `description`, intro line, `context` input doc)

**Interfaces:**
- Consumes: nothing new.
- Produces: an agent that accepts `capability_themes` derived from an implementation spec, callable by `/impl:code` as well as `/impl:jira:epics`. Input contract (`repo_path`, `capability_themes`, `context`, `search_hints`, `refresh`) is unchanged.

- [ ] **Step 1: Broaden the frontmatter description**

Replace the description value so it no longer says Epic-only. New value:

```yaml
description: Scans a single code repository for existing capabilities and gaps relative to a set of themes. Themes may come from a Value Increment / Epic (Epic writing) or from an implementation spec (/impl:code multi-source scanning). Pure filesystem search; no HTTPS. Designed for parallel invocation (one instance per repo, capped at 4 concurrent by the caller). Inherits the session's model.
```

- [ ] **Step 2: Broaden the intro line**

Replace the intro sentence (currently naming only `/impl:jira:epics`):

```markdown
Scan a single code repo for existing capabilities and gaps relative to a set of themes. One instance per repo; the caller — `/impl:jira:epics` (Epic scoping) or `/impl:code` (multi-source implementation scoping) — spawns up to 4 concurrent instances per batch.
```

- [ ] **Step 3: Broaden the `context` input doc**

In the `## Inputs` YAML block, change the `context` comment so it is not VI/Epic-specific:

```yaml
context: |
  <3–5 sentences: the goal being scoped. For Epic writing, the VI goal and what
  the Epic-set must achieve. For /impl:code, the implementation goal from the
  spec and what the change must accomplish.>
```

- [ ] **Step 4: Verify no remaining Epic-only framing in caller-facing text**

Run: `grep -n "only.*epics\|Epic writing where" plugins/dev-workflows/agents/code-scanner.md`
Expected: no match for an exclusive "only epics" caller claim. (The "Distinction from diff-summarizer" paragraph mentioning Epic *scoping* may remain — it is illustrative, not an exclusivity claim.)

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/code-scanner.md
git commit -m "feat(dev-workflows): generalize code-scanner for /impl:code callers"
```

---

### Task 3: Multi-input parsing + scale assessment in `code.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/code.md` (Phase 0; new Pre-Phase 2 step after Phase 1.5)

**Interfaces:**
- Consumes: `classification.md` §8 (Task 1) and the §1.1 trigger.
- Produces: parsed input facts (`repo_count`, `has_ticket_folder`, `has_spec_folder`, classified `@paths`) and a `fan_out` boolean that Task 4's Phase 1.7 consumes.

- [ ] **Step 1: Rewrite Phase 0 to parse multiple `@paths`**

Replace the current Phase 0 body (the "If `@file` syntax…" paragraph) with:

```markdown
## Phase 0 — Load and classify inputs

`$ARGUMENTS` may contain free-text prose plus **zero or more `@path` tokens** (today's single-`@file` form is a subset). Resolve each `@path` relative to the current working directory. Classify each `@path` — and the current working directory — **by inspection, not by matching the path string**:

| Detected as | Recognition rule | Handling |
|---|---|---|
| **Spec file** | a single `.md` file | read fully; use as the description/spec |
| **Spec folder** | a directory containing `prompt.md` and/or a `*-design.md` | read all `.md` specs within; fold into the description |
| **Jira ticket folder** | a directory containing a `*-index.md`, or ticket-key subdirectories each containing a `KEY.md` | hand to `jira-reader` in Phase 1.7 |
| **Code repo** | a directory where `git -C <path> rev-parse --is-inside-work-tree` succeeds (includes the cwd) | scan target in Phase 1.7 |

Rules:
- The **primary description** is: the spec file if one was given → else the spec-folder design doc → else the inline prose. Echo `📄 Reading prompt from <file>…` (or `from inline text`) and confirm `"Loaded prompt (N lines)."`.
- Multiple inputs of the same kind are allowed.
- A referenced `@dir` that is missing, or is neither a recognized folder type nor a git repo, MUST be surfaced to the user immediately (do not silently skip) — then ask whether to continue without it or stop. This mirrors `classification.md` §8.4.
- Note any embedded images as "referenced image: <path>".
- If a single `@file` cannot be read, stop and report the error immediately.
```

- [ ] **Step 2: Add the Pre-Phase 2 "Input scale assessment" step**

Immediately after Phase 1.5 (Classify task complexity) and before Phase 2A/2B, insert:

```markdown
## Pre-Phase 2 — Input scale assessment

From the Phase 0 classification, compute:
- `repo_count` = number of code repos (cwd + referenced git-repo dirs)
- `has_ticket_folder` = any Jira ticket folder present
- `has_spec_folder` = any spec/design folder present

Set `fan_out = (repo_count > 1) OR has_ticket_folder OR has_spec_folder`.

- **`fan_out = true`** → the input is multi-source. Per `classification.md` §1.1 this floors the classification at **SIGNIFICANT** (raise it now if Phase 1.5 chose SIMPLE/MODERATE). Announce: `"Multi-source input detected (<facts>) — flooring at SIGNIFICANT; this is overridable at plan approval."` Then run **Phase 1.7** (fan-out scan) and continue on the SIGNIFICANT/HIGH-RISK branch (Phase 2B).
- **`fan_out = false`** → unchanged behavior; skip Phase 1.7 and proceed to Phase 2A or 2B exactly as the Phase 1.5 classification directs (the single-explorer path).
```

- [ ] **Step 3: Verify ordering and references**

Run: `grep -n "## Phase 0\|## Phase 1.5\|## Pre-Phase 2\|fan_out\|§8\|classification.md §1.1\|SIGNIFICANT" plugins/dev-workflows/commands/impl/code.md | head -30`
Expected: `Pre-Phase 2` appears after `Phase 1.5` and before any `Phase 2A`; `fan_out` defined; the §1.1 floor cited.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/commands/impl/code.md
git commit -m "feat(dev-workflows): /impl:code parses multi-source input and assesses scale"
```

---

### Task 4: Phase 1.7 fan-out + Phase 2B wiring + invariants in `code.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/code.md` (new Phase 1.7 after Pre-Phase 2; Phase 2B exploration wiring; Invariants block)

**Interfaces:**
- Consumes: `fan_out`, classified inputs (Task 3); `classification.md` §8 (Task 1); generalized `code-scanner` (Task 2).
- Produces: a synthesized "multi-source codebase summary" string consumed by the Phase 2B `risk-planner` invocation in place of the single Explore summary.

- [ ] **Step 1: Insert Phase 1.7 (fan-out scan)**

After Pre-Phase 2 and before Phase 2A:

```markdown
## Phase 1.7 — Multi-source exploration (only when `fan_out = true`)

Runs after Pre-Phase 2 and replaces the single Phase 2B exploration subagent for multi-source input. Follows `classification.md` §8.

1. **Read Jira ticket folders.** For each Jira ticket folder, invoke `jira-reader` (read-only):

   → Agent (subagent_type: "dev-workflows:jira-reader"):
     > "Read the exported Jira hierarchy at <ticket-folder absolute path> and return the structured handoff: linked items, PR URLs (identifiers only — no fetching), and capability themes."

   Run multiple `jira-reader` calls sequentially (it is fast and read-only). Collect the themes and PR references.

2. **Read spec/design folders inline.** Read each spec-folder `.md` and fold its content into the themes and primary description.

3. **Fan out `code-scanner` — one per repo, single response, cap 4 concurrent.** Spawn all repo scanners in **one** message (batch in groups of 4 if there are more than 4 repos). For each code repo:

   → Agent (subagent_type: "dev-workflows:code-scanner"):
     > "repo_path: <absolute repo path>
     >  capability_themes: <themes from steps 1–2 + the implementation spec>
     >  context: <3–5 sentences: the implementation goal and what the change must accomplish>
     >  search_hints: <symbols/paths/keywords derived from the spec, if any>"

   Wait for all scanners in the batch to return. A scanner returning `DIRTY_TREE`/`REFRESH_BLOCKED` is surfaced, not hidden.

4. **Synthesize.** Combine the `jira-reader` output, all `code-scanner` reports, and the spec into a single **multi-source codebase summary** (per-repo: relevant files, existing capabilities, gaps; plus the cross-repo picture and the Jira themes/PR references). This summary is the codebase context for Phase 2B — do **not** also run the single Explore subagent.
```

- [ ] **Step 2: Wire Phase 2B to accept the fan-out summary**

In Phase 2B's "Codebase exploration" paragraph, replace the unconditional "same exploration subagent call as Phase 2A" instruction with:

```markdown
**Codebase exploration** — If Phase 1.7 ran (`fan_out = true`), use its **multi-source codebase summary** as the codebase context and skip the single Explore subagent. Otherwise, run the same exploration subagent call as Phase 2A (same prompt, same fallback rule).
```

Then, in the `risk-planner` invocation prompt, change the `Codebase summary:` line to:

```markdown
  > Codebase summary: [paste the Phase 1.7 multi-source summary if fan_out, else the Explore agent's output]
```

- [ ] **Step 3: Add invariants**

Append to the "Invariants (always enforced)" block:

```markdown
- ALWAYS classify each `@path` input by inspection (Phase 0) — never by matching the path string
- WHEN `fan_out` is true (multi-repo or any directory input): floor classification at SIGNIFICANT (overridable at plan approval), run Phase 1.7, and feed its synthesized summary to the planner instead of the single Explore subagent
- ALWAYS fan out `code-scanner` one-per-repo in a single response, capped at 4 concurrent — never sequentially
- NEVER silently skip a referenced `@dir` that is missing or unrecognized — surface it and ask (classification.md §8.4)
- Scanning agents (`jira-reader`, `code-scanner`) inherit the session model; escalate a single scanner to Opus only when one repo slice is oversized
```

- [ ] **Step 4: Verify cross-references and ordering**

Run: `grep -n "## Phase 1.7\|fan_out\|code-scanner\|jira-reader\|multi-source\|cap.*4\|concurrent" plugins/dev-workflows/commands/impl/code.md | head -30`
Expected: Phase 1.7 present after Pre-Phase 2; `code-scanner`/`jira-reader` referenced; Phase 2B's `risk-planner` prompt references the multi-source summary; the four new invariants present.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/impl/code.md
git commit -m "feat(dev-workflows): /impl:code Phase 1.7 fan-out scan + planner wiring"
```

---

### Task 5: Update `dev-workflows/README.md` (table, mermaid, agents)

**Files:**
- Modify: `plugins/dev-workflows/README.md` (command table row ~line 10; `## /impl:code workflow` mermaid block lines 26–101; Agents table)

**Interfaces:**
- Consumes: the phase names and behavior from Tasks 3–4.
- Produces: docs consistent with the implemented workflow.

- [ ] **Step 1: Broaden the `/impl:code` command-table row**

Update the row so the description mentions multi-source input. Replace the cell text with:

```markdown
| `/impl:code <description \| @paths>` | Structured code implementation: load + classify multi-source input (spec file/folder, Jira ticket folder, one or more repos) → classify risk → fan-out scan when multi-source → plan (Opus for SIGNIFICANT / HIGH-RISK) → branch → capture test baseline → implement → write and verify tests → Opus review → verify baseline → document. |
```

- [ ] **Step 2: Update the mermaid diagram**

Edit the `flowchart TD` block:

(a) Broaden the Phase 0 node:
```
    H --> P0["Phase 0: Load + classify inputs<br/>inline text, @file, spec/Jira folders, repos"]
```

(b) After the Phase 1.5 classify node `C`, insert a scale-assessment decision and the fan-out branch. Add these nodes/edges (place after the existing `C` definition, before the `C -->|SIMPLE / MODERATE|` edge):
```
    C --> SCALE{"Pre-Phase 2:<br/>Multi-source input?<br/>(multi-repo or any folder)"}
    SCALE -->|No| C2["Use Phase 1.5 class"]
    SCALE -->|Yes| FLOOR["Floor at SIGNIFICANT<br/>(overridable at approval)"]
    FLOOR --> F17["Phase 1.7: fan-out scan<br/>jira-reader + code-scanner xN (cap 4)<br/>→ synthesize summary"]
    F17 --> E2
```
Change the two existing classification edges to originate from `C2` instead of `C`:
```
    C2 -->|SIMPLE / MODERATE| E1["Explore codebase<br/>read-only subagent"]
    C2 -->|SIGNIFICANT / HIGH-RISK| E2["Explore codebase<br/>read-only subagent"]
```
And broaden `E2` so it reflects the fan-out feeding it (the fan-out summary replaces the single explorer when present):
```
    E2["Explore codebase (read-only)<br/>or use Phase 1.7 fan-out summary"]
```

(c) Leave all downstream nodes (`RP`, branch, baseline, implement, review, tests, Phase 4/5) unchanged.

- [ ] **Step 3: Update the Agents table**

In the `## Agents` table, update the `jira-reader` and `code-scanner` rows (add them if absent) so their "used by" text includes `/impl:code`. For `code-scanner`, the description should read along the lines of:

```markdown
| `code-scanner` | inherits | Scans one repo for existing capabilities and gaps relative to themes (from an Epic or an implementation spec). Fanned out one-per-repo, cap 4 concurrent. Used by `/impl:jira:epics` and `/impl:code` (multi-source fan-out). |
```

For `jira-reader`, append `and /impl:code (multi-source input)` to its "used by" clause.

- [ ] **Step 4: Verify**

Run: `grep -n "Phase 1.7\|fan-out\|multi-source\|SCALE\|FLOOR\|F17\|code-scanner.*impl:code\|impl:code.*folder" plugins/dev-workflows/README.md`
Expected: the new Phase 0 wording, the SCALE/FLOOR/F17 mermaid nodes, and the updated agent rows all present.
Run: a mermaid syntax sanity check by reading the diagram block start/end — confirm it still opens with ```` ```mermaid ```` and closes with ```` ``` ````.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/README.md
git commit -m "docs(dev-workflows): document /impl:code multi-source fan-out in README + diagram"
```

---

### Task 6: Update root `README.md` and `CLAUDE.md`

**Files:**
- Modify: `README.md` (repo root, line ~9 dev-workflows summary row)
- Modify: `CLAUDE.md` (the `/impl:code` workflow-map line; the `/impl:code` invariants block; the source-truth note)

**Interfaces:**
- Consumes: all prior tasks.
- Produces: top-level docs consistent with the workflow; no dangling references.

- [ ] **Step 1: Root README summary**

The root README row already lists `/impl:code` generically ("Opus-backed planning, code review, …"). Add a brief multi-source mention so it is not misleading. Append to that cell's clause:

```markdown
 — `/impl:code` accepts multi-source input (spec files, Jira ticket folders, multiple repos) and fans out a parallel scan for large briefs
```

(If the executor judges the root row is intentionally high-level and a per-command detail does not belong there, skip this step and note it in the final report — this is the one optional edit in the plan.)

- [ ] **Step 2: Update the `CLAUDE.md` workflow-map line**

Replace the `/impl:code` line in the "`dev-workflows` workflow relationships" diagram with one that shows the fan-out branch:

```markdown
/impl:code           → /impl → [Pre-Phase 2 scale assessment] → (multi-source? → [jira-reader → code-scanner×N (parallel, cap 4)] → synthesis) → [risk-planner@Opus plan critique] → [code-review@Opus] → review-fixer → test-writer → tests → impl-maintenance
```

And in the agents fan-out list below it, add a note that `code-scanner` and `jira-reader` are now shared with `/impl:code`:

```markdown
                      └── code-scanner       (used by /impl:jira:epics and /impl:code multi-source fan-out)
                      └── jira-reader        (used by /impl:jira:* and /impl:code multi-source fan-out)
```

- [ ] **Step 3: Add `/impl:code` invariants in `CLAUDE.md`**

In the "Key invariants for `/impl:code` specifically" block, append:

```markdown
- Multi-source input (more than one repo, or any directory input — Jira ticket folder or spec folder) floors classification at SIGNIFICANT (overridable at plan approval) and triggers the Phase 1.7 fan-out scan
- The fan-out runs `jira-reader` + per-repo `code-scanner` (single response, cap 4 concurrent); its synthesized summary feeds the planner instead of the single Explore subagent
- A referenced directory that is missing or unrecognized is surfaced, never silently skipped
```

- [ ] **Step 4: Update the source-truth note in `CLAUDE.md`**

In the "Model routing reference" section that lists what `classification.md` is the source of truth for, add a bullet:

```markdown
- The large-input scan fan-out policy (§8): the input-shape trigger, the `jira-reader → parallel code-scanner (cap 4) → Opus synthesis` pattern, and the SIGNIFICANT floor it imposes
```

- [ ] **Step 5: Verify no dangling references**

Run: `grep -rn "Phase 1.7\|fan-out\|fan_out\|scale assessment\|§8\|Large-input scan" plugins/dev-workflows/ CLAUDE.md README.md`
Expected: consistent terminology across `code.md`, `classification.md`, both READMEs, and `CLAUDE.md`; no reference to a phase or section that does not exist.
Run: `grep -rn "single.*@file\|only.*inline text\|inline text or a single" plugins/dev-workflows/commands/impl/code.md`
Expected: no surviving claim that input is limited to a single file / inline text only.

- [ ] **Step 6: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: document /impl:code multi-source fan-out in root README and CLAUDE.md"
```

---

### Task 7: End-to-end consistency pass + reinstall note

**Files:**
- No edits expected; this task is verification. Fix-forward into the relevant prior file if a gap is found.

- [ ] **Step 1: Cross-reference integrity sweep**

Run: `grep -rn "Pre-Phase 2\|Phase 1.7" plugins/dev-workflows/`
Expected: every mention resolves — `code.md` defines them; `README.md`/`CLAUDE.md` reference them by the same names.

- [ ] **Step 2: Confirm small-input path is untouched**

Read Phase 2A and the `fan_out = false` branch in `code.md`. Confirm a plain `dev-workflows:impl:code "fix typo"` invocation still flows Phase 0 → 1 → 1.5 → Pre-Phase 2 (fan_out false) → 2A with the single explorer, exactly as before.

- [ ] **Step 3: Confirm the cap-4 and read-only invariants are stated wherever fan-out is described**

Run: `grep -rn "cap 4\|capped at 4\|4 concurrent" plugins/dev-workflows/commands/impl/code.md plugins/dev-workflows/references/model-routing/classification.md plugins/dev-workflows/README.md CLAUDE.md`
Expected: the cap-4 rule appears in `classification.md` §8, `code.md` Phase 1.7 + invariants, and the README diagram.

- [ ] **Step 4: Final commit (if any fix-forward edits were made)**

```bash
git add -A
git commit -m "docs(dev-workflows): consistency fixes for /impl:code fan-out"
```

- [ ] **Step 5: Report the reinstall reminder**

The plan does not run it (it is environment-mutating), but the final report MUST remind the user:

```bash
claude plugin reinstall dev-workflows@ihudak-plugins
```

so the edited command/agent/reference content is picked up.

---

## Self-Review

**Spec coverage:**
- Design §1 (multi-input handling) → Task 3 Step 1. ✓
- Design §2 (scale assessment trigger) → Task 3 Step 2. ✓
- Design §3 (classification coupling / SIGNIFICANT floor) → Task 1 Step 1 + Task 3 Step 2. ✓
- Design §4 (Phase 1.7 fan-out) → Task 4 Step 1. ✓
- Design §5 (model routing inside fan-out) → Task 1 Step 2 (§8.3) + Task 4 invariants. ✓
- Design §6 (shared policy §8) → Task 1 Step 2. ✓
- Design §7 (unchanged downstream) → Task 7 Step 2 (verification). ✓
- Affected files: `code.md` (Tasks 3–4), `classification.md` (Task 1), dev-workflows `README.md` (Task 5), root `README.md` (Task 6), `CLAUDE.md` (Task 6). ✓
- Risk: `code-scanner` wording → Task 2. ✓
- Risk: cwd as both scan + impl target → covered in Task 4 Step 1 (cwd is a scan target; impl writes per plan) and Task 7 Step 2. ✓

**Placeholder scan:** No "TBD"/"handle edge cases"/"similar to Task N" — all edit content is shown verbatim. The single optional edit (Task 6 Step 1) is explicitly flagged as optional with a decision rule, not a placeholder.

**Type/name consistency:** `fan_out` (boolean), `repo_count`, `has_ticket_folder`, `has_spec_folder`, "multi-source codebase summary", "Phase 1.7", "Pre-Phase 2", "§8" — used identically across Tasks 1, 3, 4, 5, 6, 7. `code-scanner` cap is 4 everywhere. `jira-reader` is read-only everywhere.

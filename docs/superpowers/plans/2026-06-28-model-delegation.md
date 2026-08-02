---
tags:
  - tasks-exclude
---

# Per-step Model Delegation for /impl:jira:docs — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/impl:jira:docs` route each step to the right model — force Opus on `doc-planner`, de-escalate the mechanical fan-out to Sonnet, and advise relaunching on Opus for the inline-writer/orchestration steps that can't be delegated — and extract the reusable policy into `classification.md` §9.

**Architecture:** Follow the `profile.md` pattern: resolve a `model_routing` block once at Phase 1.5, then add a `task model:` override to each subagent dispatch citing the §9 chain. The cross-command reviewer frontmatter pins stay untouched (`doc-reviewer` gets no override). The inline writer (Phase 6) + interactive gates stay on the session model with a Phase 1.5 advisory. The shared policy lives in a new `classification.md` §9 so `docs.md` references it rather than re-deriving it.

**Tech Stack:** Markdown command/reference files in the `dev-workflows` Claude Code plugin. No code, no test framework — **verification is structural** (grep anchors, fence parity, `python3` YAML/JSON parse).

## Global Constraints

- Repo: `/workspace/ihudak-claude-plugins`; plugin under `plugins/dev-workflows/`. Plugin `main` @ `0666cf6`, v1.14.2.
- Release is **MINOR `v1.15.0`** (adds delegation behavior; no breaking change).
- **No test framework** — every "test" step is a structural check (grep / fence-parity / YAML parse). No `pytest`/`npm test`.
- **Match dispatches by anchor text, not line number** — the Phase 1.5 block insertion shifts every later line; the dispatches are uniquely identified by their `subagent_type` + phase.
- **`model:` override syntax** mirrors `profile.md`: `→ Agent (subagent_type: "…", model: \`<chain note>\`):`.
- **`doc-reviewer` (Phase 7) gets NO `model:` override** — its frontmatter `model: opus` governs; the block records it as `review_model`.
- **Frontmatter Opus pins are untouched** (`doc-reviewer`, `code-review`, `epic-reviewer`, `risk-planner`).
- **`epics.md` is out of scope** (scoped follow-up).
- marketplace.json version is at `plugins[0].version` (NOT top-level).
- Stage **explicit paths** only — never `git add -A`; never stage `.superpowers/` or `.docstack`.
- Commit trailer on every commit: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Commit only as each task's final step (this is local branch work; push is a separate finishing step the user runs).
- Zero-external-API invariant preserved (routing is local model selection only).

---

### Task 1: classification.md §9 — shared per-step routing policy

**Files:**
- Modify: `plugins/dev-workflows/references/model-routing/classification.md` (append a new `## 9.` section at end of file, after the current §8)

**Interfaces:**
- Produces: the `§9` section (with subsections `9.1`–`9.4`) that `docs.md` Phase 1.5 and every `docs.md` dispatch will cite. Key anchors later tasks rely on: the heading text `## 9. Per-step routing for multi-phase authoring pipelines`, the role→chain map, and the §8.3 reconciliation note.

- [ ] **Step 1: Confirm the insertion point**

Run: `grep -n '^## 8\.' plugins/dev-workflows/references/model-routing/classification.md`
Expected: one match (`## 8. Large-input scan fan-out`). §9 goes at the end of the file, after all of §8's content.

- [ ] **Step 2: Append §9**

Append to the end of `plugins/dev-workflows/references/model-routing/classification.md`:

```markdown

---

## 9. Per-step routing for multi-phase authoring pipelines

The `/impl:jira:*` authoring pipelines (`commands/impl/jira/docs.md` now;
`commands/impl/jira/epics.md` later) run a long sequence of phases — some
judgment-heavy, some mechanical. They MUST NOT let every step inherit the
session model. Apply this policy, resolving each model against the §2 (Opus)
and §2.1 (Sonnet) fallback chains.

### 9.1 Principle

- **Judgment-heavy authoring / synthesis** steps run on the §2 reasoning (Opus)
  chain — escalate to Opus even when the session is Sonnet.
- **Mechanical detection / throughput / fix** steps run on the §2.1 detection
  (Sonnet) chain — de-escalate off the session model even when the session is
  Opus (otherwise an Opus session burns Opus on cheap work).
- **Orchestrator-executed** judgment steps — the inline prose writing and the
  interactive gates, plus the orchestration itself — run on the session model
  and CANNOT be overridden from inside a running command. Handle them with an
  **advisory** (recommend relaunching on the §2 chain), never an override.

### 9.2 Role → chain map

| Role | Chain |
|------|-------|
| Synthesis / planner (e.g. `doc-planner`) | §2 reasoning (Opus) |
| Reader / summarizer / locator / style-checker / fixer / maintenance (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, maintenance agents) | §2.1 detection (Sonnet) |
| Domain reviewer (`doc-reviewer`, `epic-reviewer`) | §2 review (Opus) — usually already frontmatter-pinned; the orchestrator records it and adds **no** override |
| Inline writer + interactive gates (the orchestrator itself) | session model → §9.1 advisory |

### 9.3 No-Opus degradation

When no Opus model is available (per §2), run the reasoning / review roles on the
Sonnet floor, **skip** the relaunch advisory (there is nothing to relaunch onto),
and announce the degradation in the `model_routing` record and the final report —
the same rule as §2.

### 9.4 Reconciliation with §8.3

§8.3's "`jira-reader` / `code-scanner` inherit the session model" is the
conservative default for the `/impl:code` large-input **fan-out**. Authoring
pipelines that route per this section pin **`jira-reader`** to the detection
chain (reading pre-exported markdown is mechanical — an Opus session should not
pay for it). `code-scanner` remains governed by §8.3 when invoked under the
large-input fan-out trigger.
```

- [ ] **Step 3: Verify the section landed and is well-formed**

Run: `grep -nE '^## 9\.|^### 9\.[1-4]' plugins/dev-workflows/references/model-routing/classification.md`
Expected: 5 lines — `## 9. Per-step routing…`, `### 9.1 Principle`, `### 9.2 Role → chain map`, `### 9.3 No-Opus degradation`, `### 9.4 Reconciliation with §8.3`.

Run: `awk 'BEGIN{c=0} /^```/{c++} END{print c}' plugins/dev-workflows/references/model-routing/classification.md`
Expected: an **even** number (all code fences balanced — §9 adds no fences, so the count is unchanged from before; even either way).

Run: `grep -c 'jira-reader' plugins/dev-workflows/references/model-routing/classification.md`
Expected: ≥ 2 (the existing §8.3 mention plus the new §9.2/§9.4 mentions).

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/model-routing/classification.md
git commit -m "PRODUCT model-routing: add §9 per-step routing for authoring pipelines

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: docs.md — wire the per-step routing

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md` (Phase 1.5 body; 7 `→ Agent` dispatches; 4 Phase 8 maintenance-agent headers; Phase 9 report; Invariants list)

**Interfaces:**
- Consumes: `classification.md` §9 (Task 1) — the role→chain map and the no-Opus rule.
- Produces: the resolved `model_routing` block at Phase 1.5 (field names `current_model`, `detection_model`, `planning_model`, `review_model`, `implementation_model`, `fixes_model`, `opus_available`, `notes`) that the dispatch overrides and the Phase 9 report reference.

- [ ] **Step 1: Replace the Phase 1.5 body**

Find this exact block:

```markdown
## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of: `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK`. Jira-driven feature docs are typically **SIGNIFICANT** (large blast radius if wrong — published documentation). State the classification and a one-sentence reason.

SIGNIFICANT → no Opus planning (the Jira hierarchy + diff summaries *are* the plan); `doc-reviewer` gate is mandatory.

---
```

Replace it with:

````markdown
## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of: `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK`. Jira-driven feature docs are typically **SIGNIFICANT** (large blast radius if wrong — published documentation). State the classification and a one-sentence reason.

SIGNIFICANT → no separate Opus **risk-planner** for the high-level plan (the Jira hierarchy + diff summaries *are* the plan), **but `doc-planner` (Phase 5.7) is pinned to the §2 Opus reasoning chain**; the `doc-reviewer` gate (Opus) is mandatory.

**Resolve the per-step routing.** Following `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9, record a `model_routing` block (reusing the §4 field names) resolving each model against the fallback chains:

```yaml
model_routing:
  classification: SIGNIFICANT
  reason: <one-line>
  current_model: <the model this orchestrator is running under>   # = the inline writer + Phase 5.8 framing
  detection_model: <§2.1 mid-tier Sonnet chain: claude-sonnet-4-6, fallback claude-sonnet-4-5>
  planning_model:  <§2 powerful chain: claude-opus-4-8 … fallback Sonnet per §2>   # doc-planner (5.7)
  review_model:    <§2 powerful chain>     # doc-reviewer (frontmatter-pinned; recorded here, no override added)
  implementation_model: <= current_model>  # the INLINE writer (Phase 6) + discrepancy framing (5.8); not overridable
  fixes_model: <= detection_model>         # doc-fixer (6.7 / 7) runs on the detection chain
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2 / §2.1 fallback or degradation>
```

Each subagent dispatch below cites which chain it uses (the §9 role→chain map): `doc-planner` → `planning_model`; `jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, and the Phase 8 maintenance agents → `detection_model`; `doc-reviewer` keeps its own frontmatter Opus pin (recorded as `review_model`, no override added).

**Writer / orchestration advisory.** The Phase 0–9 coordination, the discrepancy (5.8) and write-strategy (5.9) gates, and the prose writing (Phase 6) run on `current_model` and cannot be delegated. So:

- **`current_model` is on the §2 Opus chain** → no advisory; the detection steps still de-escalate to Sonnet via their overrides.
- **`current_model` is NOT on the §2 chain and `opus_available: true`** → advise relaunching on Opus:
  ```
  ⚠ This run is on <current_model>. /impl:jira:docs is a long, judgment-heavy, context-heavy orchestration: the Phase 0–9 coordination, the discrepancy (5.8) and write-strategy (5.9) gates, and the prose writing (Phase 6) all run on the session model and cannot be delegated. Opus is recommended for the whole run — better reasoning on the gates and the prose, plus a 1M context window that removes window pressure on large multi-repo tickets. doc-planner (5.7) is escalated to Opus regardless of this choice.

  choices: ["Relaunch /impl:jira:docs under Opus — I'll restart (Recommended)", "Proceed on <current_model> — record the degradation in the report", "Cancel"]
  ```
  "Relaunch" → stop cleanly with the relaunch instruction (a running command cannot change its own session model). "Proceed" → set a degradation flag carried into the Phase 9 report. "Cancel" → stop.
- **`current_model` is NOT on the §2 chain and `opus_available: false`** → skip the relaunch offer; set `planning_model` and `review_model` to the Sonnet floor; record in `notes` and the Phase 9 report that `doc-planner`, `doc-reviewer`, **and** the writer all ran degraded (per §9.3 / §2); proceed.

---
````

- [ ] **Step 2: Add `model:` to the `doc-planner` dispatch (the escalation — §2 Opus)**

Find: `→ Agent (subagent_type: "dev-workflows:doc-planner"):`
Replace with: ``→ Agent (subagent_type: "dev-workflows:doc-planner", model: `<planning_model — §9 / §2 Opus chain>`):``

- [ ] **Step 3: Add `model:` to the five detection-chain `→ Agent` dispatches (§2.1 Sonnet)**

For each of the following, append `, model: \`<detection_model — §9 / §2.1 Sonnet chain>\`` before the closing `):`. **Indentation:** the four `→ Agent` lines for `jira-reader`/`diff-summarizer`/`doc-location-finder`/`docs-style-checker` are at column 0; the **two `doc-fixer` lines are indented 2 spaces** (nested under the Phase 6.7 `VIOLATIONS_FOUND` bullet and the Phase 7 `PASS WITH RECOMMENDATIONS` bullet). Preserve the exact leading indentation in both the find and replace text; for `doc-fixer` the two lines are identical, so use `replace_all` with the 2-space-indented string.

| Find | Replace with |
|------|--------------|
| `→ Agent (subagent_type: "dev-workflows:jira-reader"):` | ``→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |
| `→ Agent (subagent_type: "dev-workflows:diff-summarizer"):` | ``→ Agent (subagent_type: "dev-workflows:diff-summarizer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |
| `→ Agent (subagent_type: "dev-workflows:doc-location-finder"):` | ``→ Agent (subagent_type: "dev-workflows:doc-location-finder", model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |
| `→ Agent (subagent_type: "dev-workflows:docs-style-checker"):` | ``→ Agent (subagent_type: "dev-workflows:docs-style-checker", model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |
| `→ Agent (subagent_type: "dev-workflows:doc-fixer"):` (×2 — use replace-all) | ``→ Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |

Leave `→ Agent (subagent_type: "dev-workflows:doc-reviewer"):` **unchanged** (frontmatter governs).

- [ ] **Step 4: Add `model:` to the four Phase 8 maintenance-agent headers (§2.1 Sonnet)**

| Find | Replace with |
|------|--------------|
| `**Agent 1 — Documentation** (general-purpose):` | ``**Agent 1 — Documentation** (general-purpose, model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |
| `**Agent 2 — Knowledge base** (general-purpose):` | ``**Agent 2 — Knowledge base** (general-purpose, model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |
| `**Agent 3 — Instructions** (general-purpose):` | ``**Agent 3 — Instructions** (general-purpose, model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |
| `**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance):` | ``**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance, model: `<detection_model — §9 / §2.1 Sonnet chain>`):`` |

- [ ] **Step 5: Annotate the Phase 7 `doc-reviewer` line (record-only, no override)**

Find: `Invoke `doc-reviewer` (Opus). The reviewer is **product-docs-only**; Epic drafts go through `epic-reviewer` in `/impl:jira:epics`.`
Replace with: `Invoke `doc-reviewer` (Opus — pinned by its own frontmatter; recorded as `review_model`, no dispatch override added). The reviewer is **product-docs-only**; Epic drafts go through `epic-reviewer` in `/impl:jira:epics`.`

- [ ] **Step 6: Add the Phase 9 `### Model Routing` report section**

Find this block (inside the Phase 9 fenced report):

```
### Classification
SIGNIFICANT — Jira-driven feature documentation has large blast radius if wrong

### Jira hierarchy summary
```

Replace with:

```
### Classification
SIGNIFICANT — Jira-driven feature documentation has large blast radius if wrong

### Model Routing
- Session / writer model (current_model): [model] — [if it ran degraded: "Sonnet; user proceeded past the Phase 1.5 advisory" | "Sonnet; no Opus available" | "on §2 chain — no degradation"]
- doc-planner synthesis (planning_model): [model]
- Detection steps — jira-reader, diff-summarizer, doc-location-finder, docs-style-checker, doc-fixer, maintenance (detection_model): [model]
- doc-reviewer (review_model): [model]
- Opus available: [yes | no]

### Jira hierarchy summary
```

- [ ] **Step 7: Add the routing invariant**

Find: `- ALWAYS invoke `doc-reviewer` before Phase 8 maintenance`
Replace with:
```
- ALWAYS invoke `doc-reviewer` before Phase 8 maintenance
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin each subagent dispatch to its §9 chain via `model:` — `doc-planner` to the §2 Opus chain, the mechanical steps (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, maintenance) to the §2.1 Sonnet chain; `doc-reviewer` keeps its frontmatter Opus pin (no override); the inline writer + gates run on `current_model` (advisory only)
```

- [ ] **Step 8: Structural verification**

The dispatch-override notes are the **only** places where an angle-bracket
immediately precedes `detection_model` / `planning_model` (the YAML block uses
`detection_model:`/`planning_model:` with no leading `<`; the report uses
`(detection_model)`/`(planning_model)`). So these counts are exact:

Run: `grep -c '<planning_model' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: **1** (the `doc-planner` Opus-chain override — Step 2).

Run: `grep -c '<detection_model' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: **10** — the 6 detection `→ Agent` dispatch lines (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, and `doc-fixer` **twice**) + the 4 Phase 8 maintenance headers. If you get 9, a `doc-fixer` occurrence was missed; if 8, a `→ Agent` line was missed.

Run: `grep -n 'subagent_type: "dev-workflows:doc-reviewer"' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: the `→ Agent (subagent_type: "dev-workflows:doc-reviewer"):` line has **no** `model:` — confirm visually it was left unchanged.

Run: `grep -nE '^### Model Routing|^## Phase 1.5 |review_model|opus_available' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: the `## Phase 1.5` heading is present; `### Model Routing` is present (Phase 9); `review_model` and `opus_available` each appear ≥ twice (the Phase 1.5 block + the report).

Run: `awk 'BEGIN{c=0} /^```/{c++} END{print c}' plugins/dev-workflows/commands/impl/jira/docs.md`
Expected: an **even** number (all fences balanced — Step 1 adds one ` ```yaml ` block and one ` ``` ` choices block = 2 fences, both balanced).

(No YAML parse: the `model_routing` block contains `<placeholder>` tokens by design — it is a template the command fills at runtime, not valid YAML. The fence-parity check covers it.)

- [ ] **Step 9: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "PRODUCT impl:jira:docs: per-step model routing (Opus doc-planner, Sonnet fan-out, writer advisory)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Release v1.15.0

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (top-level `version`)
- Modify: `.claude-plugin/marketplace.json` (`plugins[0].version`)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (new `[1.15.0]` entry)

**Interfaces:**
- Consumes: Tasks 1–2 (the feature being released).

- [ ] **Step 1: Confirm current versions**

Run: `grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json; python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])"`
Expected: both print `1.14.2`.

- [ ] **Step 2: Bump `plugin.json`**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, change the top-level `"version": "1.14.2",` to `"version": "1.15.0",`.

- [ ] **Step 3: Bump `marketplace.json`**

In `.claude-plugin/marketplace.json`, change `plugins[0].version` from `1.14.2` to `1.15.0` (the `dev-workflows` entry — confirm it is `plugins[0]`).

- [ ] **Step 4: Add the CHANGELOG entry**

Read the existing top entry to match format: `grep -n '## \[1.14.2\]' plugins/dev-workflows/CHANGELOG.md`. Add a new entry above it, dated 2026-06-28:

```markdown
## [1.15.0] - 2026-06-28

### Added
- `/impl:jira:docs`: per-step model delegation. A `model_routing` block resolved at Phase 1.5 pins `doc-planner` (Phase 5.7) to the §2 Opus chain and the mechanical steps (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, Phase 8 maintenance) to the §2.1 Sonnet chain. `doc-reviewer` keeps its frontmatter Opus pin.
- A Phase 1.5 advisory recommends relaunching the whole run on Opus (orchestration + the 5.8/5.9 gates + the inline writer + a 1M context window) when the session is not on the Opus chain; a no-Opus-available path records the degradation.
- `references/model-routing/classification.md` §9 — the reusable per-step routing policy for multi-phase authoring pipelines (role→chain map, no-Opus rule, §8.3 reconciliation).
```

- [ ] **Step 5: Verify the bump**

Run: `grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json; python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])"; grep -n '## \[1.15.0\]' plugins/dev-workflows/CHANGELOG.md`
Expected: `plugin.json` → `1.15.0`; marketplace → `1.15.0`; CHANGELOG has the `[1.15.0]` heading.

Run: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('JSON OK')"`
Expected: `JSON OK` (both files still parse).

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "PRODUCT dev-workflows v1.15.0: per-step model delegation for /impl:jira:docs

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Notes for the executor

- Branch off `origin/main` of `/workspace/ihudak-claude-plugins` before Task 1 (e.g. `ivgu/PRODUCT-model-delegation` or `ivgu/NOISSUE-model-delegation`). Confirm the branch with the user if unsure — do not implement on `main`.
- After all three tasks + reviews are clean, run the whole-branch Opus review, then the finishing-a-development-branch flow (the user's pattern: merge ff to plugin `main` + push origin + delete the feature branch). The user runs the merge/push.
- The dynatrace-docs CLAUDE.md prettier/husky note does **not** apply to this plugin repo (no husky/prettier gate here) — N/A, as in prior efforts.

---
tags:
  - tasks-exclude
---
# `/ready` — status-anchored readiness gate — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `/ready <VI> [<Epic>]` command (dev-workflows v2.24.0) that reads the Jira workflow status and verifies the ARD/spec/design artifacts justify it, returning SUPPORTED / PARTIAL / NOT-SUPPORTED + a coverage roll-up.

**Architecture:** One new command (`commands/ready.md`), one new Opus reviewer (`agents/readiness-reviewer.md`), one new rubric reference (`references/workflow-states.md`); two additive wiring touches (`commands/implement.md` soft pre-flight, `references/next-phase-offer.md` node); manifest + CHANGELOG bump. All markdown/JSON — no code, no test framework. Verification is structural (grep anchors, `python3 -c json.load`, `git diff --stat`, recomputed counts, byte-diff on untouched files).

**Tech Stack:** Claude Code plugin (markdown commands/agents/references + JSON manifests). Spec: `/workspace/obsidian/Projects/AI-First/dev-workflows - docs automation/spec/2026-07-12-ready-readiness-gate-design.md`.

## Global Constraints

- **Target repo:** `/workspace/ihudak-claude-plugins`; plugin dir `plugins/dev-workflows/`. Branch off `main` as `ivgu/NOISSUE-ready-readiness-gate` before Task 1 (never implement on `main`).
- **Version lock-step:** bump `2.23.0` → `2.24.0` in BOTH `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of `.claude-plugin/marketplace.json` (repo root) — identical `description` strings in both.
- **Counts:** 19 → **20** slash commands, 29 → **30** reusable subagents. Description word-strings become **"Twenty slash commands"** and **"Thirty reusable subagents"** (exact transforms in Task 6). Recompute from the repo (`ls commands/*.md | wc -l` = 20; `ls agents/*.md | wc -l` = 30) — never assert.
- **Byte-identical (must show NO diff):** both sibling plugins (`plugins/dt-style-guide` 0.2.2, `plugins/obsidian-llm-wiki` 0.3.1), `commands/vuln.md`, `commands/upgrade.md`, `agents/jira-reader.md`.
- **Verdict tokens (exact, used verbatim across all files):** `SUPPORTED`, `PARTIAL`, `NOT-SUPPORTED`.
- **Status ladders (verbatim):** VI = `Open → Problem Stated → Use cases defined → Ready for Implementation → Implementation → Release Preparation → Post GA`; Epic = `Open → In Preparation → Refined → In Progress → In Review → Closed`. Readiness target: VI **Ready for Implementation**, Epic **Refined**.
- **Git hygiene:** commit per task on the feature branch (SDD standard); NEVER `git add -A` — stage only the files named in the task; push/merge to `main` only at finish-branch with the user's explicit choice. Commit trailer EXACTLY: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **No pre-commit hook** in this repo (no husky/prettier) — plain `git commit` works.
- **cwd gotcha:** the Bash tool resets cwd to `/workspace/docs` between calls. Every command must `cd /workspace/ihudak-claude-plugins/...` (or use absolute paths) in the same invocation.
- **`/ready` behavioral invariants (carry into ready.md):** read-only on all analyzed artifacts; NEVER writes Jira / `jira-products/` / vault; NEVER branches; NEVER auto-commits `_readiness.md`; doc-only (no code scanning — repo check is presence-only).

---

### Task 1: `references/workflow-states.md` (the status↔command↔role↔artifact rubric)

**Files:**
- Create: `plugins/dev-workflows/references/workflow-states.md`

**Interfaces:**
- Produces: the rubric that Task 2 (`readiness-reviewer`) and Task 3 (`ready.md` Phase 3) consume. Downstream tasks rely on these anchor strings existing: the two ladder lines verbatim (above), the phrase `expected artifacts`, and the four illustrative rows (`Use cases defined`, `Ready for Implementation`, `Refined`, `In Progress`).

- [ ] **Step 1: Author the reference.** Create the file with this exact structure (author the prose; keep the headings + anchor strings verbatim):

  ```markdown
  # Workflow states (embedded — shared reference)

  Maps each Jira **workflow status** on the VI and Epic ladders to (a) its owning role,
  (b) the pipeline command that drives the transition into it, and (c) the **expected artifacts**
  that should exist at that status. This is the rubric `readiness-reviewer` applies and the
  source for the readiness verdict; it also feeds the PM/PA/PE/Team workflow graph.

  Jira is the **source of truth** for status (imported into `jira-products/`, emitted by `jira-reader`
  as `value_increment.status` + `linked_items[].status`). This reference NEVER stores status —
  it only interprets it.

  ## VI status ladder

  `Open → Problem Stated → Use cases defined → Ready for Implementation → Implementation → Release Preparation → Post GA`

  | Status | Role | Transition command | Expected artifacts |
  |---|---|---|---|
  | Open | PM | — | VI stub |
  | Problem Stated | PM | /idea, /create-vi | VI with Problem/Goal |
  | Use cases defined | PM | /create-vi (+ optional /specify <VI>) | VI with user stories / use cases; optional VI-level specification.md |
  | Ready for Implementation | PE→Team | /epics, /specify, /design | Epics defined; each in-scope Epic Refined+ with specification.md AND design.md; coverage complete; ARD (if any) respected; no cross-artifact contradictions |
  | Implementation | Team | /implement | code in progress (past the readiness gate) |
  | Release Preparation | Team/PM | /document, /release-notes | docs + release notes |
  | Post GA | PM | — | shipped |

  ## Epic status ladder

  `Open → In Preparation → Refined → In Progress → In Review → Closed`

  | Status | Role | Transition command | Expected artifacts |
  |---|---|---|---|
  | Open | PE | /epics | Epic draft |
  | In Preparation | PE | /specify | specification.md being authored |
  | Refined | PE→Team | /specify, /design | specification.md AND design.md present; coverage complete; ARD (if any) respected — **the Epic-level readiness gate** |
  | In Progress | Team | /implement | code in progress (past the gate) |
  | In Review | Team | /implement | PRs in review (past the gate) |
  | Closed | Team | — | merged/done |

  ## Readiness targets (for `/ready`)

  - **VI** — "ready for AI-driven development" = the artifacts support the transition into **Ready for Implementation**.
  - **Epic** — = the artifacts support the transition into **Refined** (spec **and** design present). **In Progress / In Review / Closed** are *past* the gate — `/ready` reports the gate is moot.

  The rubric is advisory: an org may skip an optional artifact (e.g. no ARD) — that downgrades to CONCERN, never a hard block on its own.
  ```

- [ ] **Step 2: Verify structure.**

  Run:
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && \
  grep -c "Ready for Implementation" references/workflow-states.md && \
  grep -c "Refined" references/workflow-states.md && \
  grep -c "expected artifacts" references/workflow-states.md && \
  grep -q "Problem Stated → Use cases defined" references/workflow-states.md && \
  grep -q "In Preparation → Refined → In Progress" references/workflow-states.md && echo "ANCHORS_OK"
  ```
  Expected: two non-zero counts, `expected artifacts` count ≥ 1, and `ANCHORS_OK`.

- [ ] **Step 3: Commit.**

  ```bash
  cd /workspace/ihudak-claude-plugins && git add plugins/dev-workflows/references/workflow-states.md && \
  git commit -m "feat(dev-workflows): add workflow-states rubric (status↔command↔role↔artifact)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 2: `agents/readiness-reviewer.md` (Opus cross-artifact reviewer)

**Files:**
- Create: `plugins/dev-workflows/agents/readiness-reviewer.md`
- Read first (template to mirror): `plugins/dev-workflows/agents/epic-reviewer.md` (frontmatter, Inputs, Review method, dimensions table, Output shape, Hard rules).

**Interfaces:**
- Consumes: `references/workflow-states.md` (Task 1) as its rubric.
- Produces: the reviewer Task 3 dispatches in `ready.md` Phase 4. `ready.md` relies on: frontmatter `model: opus`; the seven dimension names; the exact verdict tokens `SUPPORTED` / `PARTIAL` / `NOT-SUPPORTED`; a `## Readiness Review` output block.

- [ ] **Step 1: Author the agent.** Mirror `epic-reviewer.md`'s structure. Frontmatter EXACTLY:

  ```markdown
  ---
  name: readiness-reviewer
  description: Cross-artifact readiness verifier for /ready. Reads the Jira workflow status and checks the ARD/spec/design artifacts justify it and the next transition. Returns SUPPORTED / PARTIAL / NOT-SUPPORTED. Uses Claude Opus. The only reviewer that does joint cross-artifact analysis; per-artifact quality is reviewed by vi/ard/epic/spec/design-reviewer.
  model: opus
  tools: ["Read", "Glob", "Grep", "LS"]
  ---
  ```

  Body sections (author prose; keep headings + the seven dimension names + verdict tokens verbatim):
  - Intro: post-status-declaration verifier invoked from `/ready` Phase 4; status is a *human claim*, this reviewer verifies it against the artifacts.
  - `## Inputs`: `requirements[]` inventory; the Phase 3 coverage + status-expectation + repo-availability skeleton; artifact texts (VI/ARD/spec/design) with paths; declared Jira statuses (VI + each Epic); `applicable_ard` (or omitted → dim 4 skipped); the `workflow-states.md` rubric. Refuse without the declared status + at least the requirement inventory.
  - `## Review method`: read all artifacts end-to-end; apply the rubric; per-dimension findings in the shared severity schema `BLOCKER` / `MAJOR` / `MINOR` / `NIT` with `file:section` evidence; derive one verdict.
  - `## Review dimensions` — a table with exactly these seven rows:
    1. **Status consistency** — do the artifacts justify the *declared* status and support the *next* transition (per the rubric)? The headline dimension.
    2. **Coverage chain** — every VI requirement → ≥1 Epic → a spec → a design (to the depth that exists). VI requirement with no Epic = MAJOR; in-scope Epic missing a spec/design its status implies = MAJOR; absent optional artifact = MINOR/CONCERN.
    3. **Cross-artifact alignment** — terminology drift + contradictions across VI↔ARD↔spec↔design.
    4. **ARD conformance (conditional)** — only when `applicable_ard` present: an artifact violating an `AD-N` without a matching `- ARD deviation: … flag: architect` line = BLOCKER; with one = allowed-but-flagged; absent → dimension skipped.
    5. **Scope integrity** — spec/design items with no upstream VI/Epic parent = scope creep (flag).
    6. **Identifier integrity** — IDs consistent + unique across the chain.
    7. **Repo availability (best-effort)** — the Phase 3 repo-availability result: a needed-but-unmounted repo = MAJOR (hard-stops `/design`/`/implement`); list not derivable pre-implementation = reported, not blocking; complementary to those commands' strict run-time gates.
  - `## Output` — exact block:
    ```markdown
    ## Readiness Review

    ### Verdict
    [SUPPORTED | PARTIAL | NOT-SUPPORTED]

    ### Declared status
    [VI: <status>; Epics: <key>=<status>, …]

    ### Summary
    [2–4 sentences]

    ### Findings
    #### Status consistency
    - [severity] `path:section` — [observation]  Suggestion: [fix]
    - _or_ "no findings"
    #### Coverage chain
    #### Cross-artifact alignment
    #### ARD conformance
    - _"N/A — no applicable ARD"_ when omitted
    #### Scope integrity
    #### Identifier integrity
    #### Repo availability
    ### Recommended next step
    - SUPPORTED → "artifacts support the status; proceed."
    - PARTIAL → "advance with the named gaps acknowledged."
    - NOT-SUPPORTED → "resolve the named blockers before advancing the Jira status."
    ```
  - `## Hard rules`: NEVER modify files; NEVER writes status anywhere; NEVER return SUPPORTED with a BLOCKER finding; NEVER skip a dimension silently (say `N/A — reason`); a missing artifact is a finding, not an error; do not recommend running tests.

- [ ] **Step 2: Verify frontmatter + anchors.**

  Run:
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && \
  python3 -c "import sys,yaml; f=open('agents/readiness-reviewer.md').read().split('---')[1]; d=yaml.safe_load(f); assert d['name']=='readiness-reviewer' and d['model']=='opus', d; print('FM_OK')" && \
  for a in "Status consistency" "Coverage chain" "Cross-artifact alignment" "ARD conformance" "Scope integrity" "Identifier integrity" "Repo availability" "SUPPORTED" "PARTIAL" "NOT-SUPPORTED"; do grep -q "$a" agents/readiness-reviewer.md || { echo "MISSING: $a"; exit 1; }; done && echo "ANCHORS_OK"
  ```
  Expected: `FM_OK` then `ANCHORS_OK`. (If `python3`/`yaml` unavailable, fall back to `grep -q "model: opus"` + `grep -q "name: readiness-reviewer"`.)

- [ ] **Step 3: Commit** (stage only this file; same trailer as Task 1).

  ```bash
  cd /workspace/ihudak-claude-plugins && git add plugins/dev-workflows/agents/readiness-reviewer.md && \
  git commit -m "feat(dev-workflows): add readiness-reviewer (Opus cross-artifact verifier)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 3: `commands/ready.md` (the command)

**Files:**
- Create: `plugins/dev-workflows/commands/ready.md`
- Read first (templates): `plugins/dev-workflows/commands/epics.md` (Phase 0 input resolution, Phase 1.5 model-routing, Phase 8 maintenance+`emit-auto`, Phase 10 followup, Phase 11 cost, Invariants); `plugins/dev-workflows/commands/design.md` lines 22–70 (two-key grammar, `$SPECS_PATH` requirement, read-from-main, per-Epic dir resolution); `references/ard-resolution.md`; `references/next-phase-offer.md`.

**Interfaces:**
- Consumes: `readiness-reviewer` (Task 2), `references/workflow-states.md` (Task 1), `jira-reader` (unchanged), `ard-resolution.md`, the emission references.
- Produces: `_readiness.md` in `$SPECS_PATH`; the terminal report. `implement.md` (Task 4) relies on the `_readiness.md` filename + its verdict tokens.

- [ ] **Step 1: Author the command.** Frontmatter EXACTLY:

  ```markdown
  ---
  name: ready
  description: Status-anchored readiness gate. Reads the Jira workflow status of a VI/Epic and verifies the ARD/spec/design artifacts justify it and the next transition; returns SUPPORTED / PARTIAL / NOT-SUPPORTED with a coverage roll-up. Read-only — never sets Jira status, never commits. Gates on the Opus readiness-reviewer.
  allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
  ---

  Verify readiness for AI-driven development for the Jira item: $ARGUMENTS
  ```

  Phases (author prose; keep the `## Phase N —` headings + anchor strings verbatim). Mirror the cited templates:
  - `## Phase 0 — Resolve input` — via `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`; jira-driven only (`mode: direct` → stop `READY_NEEDS_JIRA: /ready needs a Jira key or an imported-Jira directory.`). Two-key grammar `<VI>` = `jira_key`, `<EPIC>` = `focus_key` (may be null). Require `$SPECS_PATH` (stop naming `SPECS_PATH` if unset, like `/design`). Read artifacts from the specs-repo **main** (clean, never a branch).
  - `## Phase 1 — Clarify + artifact inventory` — resolve the VI dir `$SPECS_PATH/specifications/<VI>-<vslug>/` (+ Epic subdir when `focus_key` set) by the key-number tolerance rule; enumerate which of `<VI>_ARD.md` / `specification.md` / per-Epic `{<EPIC>_ARD.md, specification.md, design.md}` exist vs absent; display resolved paths + the declared Jira statuses.
  - `## Phase 1.5 — Classify` — MODERATE; `model_routing` block per `epics.md` Phase 1.5; `readiness-reviewer` frontmatter-pinned Opus; `jira-reader` on the §2.1 Sonnet chain.
  - `## Phase 2 — Read ground truth` — `jira-reader` (`depth: vi-plus-epics`) → `value_increment.status`, `linked_items[].status`, `requirements[]`.
  - `## Phase 2.5 — Resolve ARD` — cite `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md`; `status: none` → the ARD dimension is inactive (no-regression).
  - `## Phase 3 — Deterministic skeleton` — mechanically build (a) coverage map (requirement IDs → artifacts by ID/section), (b) status-expectation checklist (expected artifacts for the declared status present/absent, per `workflow-states.md`), (c) best-effort repo-availability presence-check (derive repos from Epic `## Pull Requests` / `design.md` / ARD; build the slug→clone map under `${REPOS_PATH:-/workspace}` exactly as `epics.md` Phase 4 does — `git -C <dir> remote get-url origin`; presence only, no scanning; if no repo list derivable → record `repos: not-yet-determinable`).
  - `## Phase 4 — Readiness review` — dispatch `readiness-reviewer` (Opus) with the skeleton + artifact paths/texts + declared statuses + `applicable_ard` (omit if none) + a pointer to `workflow-states.md`. Carry back the verdict + findings.
  - `## Phase 5 — Write report` — write `_readiness.md` to the VI dir (VI-level) or Epic subdir (Epic-level), **overwriting**; include a header stamping the run timestamp, the specs-repo git rev (`git -C $SPECS_PATH rev-parse --short HEAD`), the checked Jira status(es), the verdict, the coverage roll-up, and the findings. Then emit the terminal report to stdout (below). **NEVER commit** `_readiness.md`; the report reminds the user to commit it to share. **NEVER** write to Jira / `jira-products/` / vault.
  - `## Phase 6 — Post-run maintenance & feedback` — mirror `epics.md` Phase 8: the four maintenance agents in ONE Agent message (change summary block with `Change type: docs`, `Command run: /ready`), then **persist plugin feedback** via `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` `emit-auto` (§6) with `command: /ready`.
  - `## Phase 7 — Emit follow-up tasks` — mirror `epics.md` Phase 10: cite `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md`; qualifying follow-ups = the named readiness gaps to resolve + a "update the Jira status" reminder.
  - `## Phase 8 — Session cost` — mirror `epics.md` Phase 11: cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` `emit-cost` with `command: /ready`, `phase: readiness`, `role: team`, `jira_key` (or null), `source`, `plugin_version`.
  - Final report `### Next step` — per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`: SUPPORTED → `/implement <VI> [<Epic>]`; PARTIAL / NOT-SUPPORTED → resolve the named gaps + update the Jira status, then re-run `/ready`.
  - `## Invariants (always enforced)` — include verbatim: `NEVER set or write Jira status`, `NEVER write inside jira-products/ or the vault`, `NEVER branch`, `NEVER auto-commit _readiness.md (git is the user's responsibility)`, `doc-only — repo check is presence-only, no scanning`, `ALWAYS end with a ### Next step per next-phase-offer.md`, `ALWAYS emit-block before escalating a plugin-gap halt` (per feedback-emission.md), the `emit-cost ALWAYS runs` note.

- [ ] **Step 2: Verify phases + invariants.**

  Run:
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && \
  for a in "Phase 0 — Resolve input" "Phase 1 — Clarify" "Phase 1.5 — Classify" "Phase 2 — Read ground truth" "Phase 2.5 — Resolve ARD" "Phase 3 — Deterministic skeleton" "Phase 4 — Readiness review" "Phase 5 — Write report" "Phase 6 — Post-run maintenance" "Phase 7 — Emit follow-up" "Phase 8 — Session cost" "readiness-reviewer" "workflow-states.md" "SUPPORTED" "NOT-SUPPORTED" "_readiness.md" "NEVER auto-commit" "emit-cost" "emit-auto" "next-phase-offer.md"; do grep -q "$a" commands/ready.md || { echo "MISSING: $a"; exit 1; }; done && echo "ANCHORS_OK"
  ```
  Expected: `ANCHORS_OK`.

- [ ] **Step 3: Commit** (stage only `commands/ready.md`; same trailer).

---

### Task 4: `commands/implement.md` — Phase 0.5 readiness pre-flight (Jira mode only)

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (insert a new phase between Phase 0 at line 11 and Phase 1 at line 90 — place it immediately before the `## Phase 1 — Clarification` heading, after the Phase 0 block ends at line 88's `---`).

**Interfaces:**
- Consumes: `mode` / `jira_key` / `focus_key` resolved in Phase 0; the declared status (`linked_items[].status` from the Phase 0 picker read, or a cheap `<jira_export_root>/<key>-index.md` Status-column read); optional `_readiness.md` under `$SPECS_PATH`.

- [ ] **Step 1: Insert the phase.** Add exactly this block immediately before `## Phase 1 — Clarification` (line 90):

  ```markdown
  ## Phase 0.5 — Readiness pre-flight (jira-driven only; advisory)

  **Jira mode only.** When `mode: direct` this phase is a **no-op** — skip it entirely
  (direct-mode runs are byte-identical to before).

  When `mode: jira-driven`, read the resolved item's declared Jira status (reuse the
  Phase 0 `vi-plus-epics` read if it ran, else a cheap Status-column read of
  `<jira_export_root>/<jira_key>-index.md`). Also, if `$SPECS_PATH` is set, check for a
  co-located `_readiness.md` in the item's specs dir.

  Surface a **one-line, non-blocking** recommendation to run `/ready <VI> [<Epic>]` first when
  EITHER: the status is below the readiness bar (VI below **Ready for Implementation**; Epic below
  **Refined**), OR a `_readiness.md` records **NOT-SUPPORTED** / **PARTIAL**. This NEVER blocks —
  proceed regardless; it is guidance only. If neither condition holds, say nothing and continue.
  ```

- [ ] **Step 2: Verify insertion + no collateral change.**

  Run:
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && \
  grep -q "Phase 0.5 — Readiness pre-flight" commands/implement.md && \
  grep -q "mode: direct.*no-op\|no-op.*skip it entirely" commands/implement.md && \
  grep -q "This NEVER blocks" commands/implement.md && echo "INSERT_OK" && \
  cd /workspace/ihudak-claude-plugins && git diff --stat plugins/dev-workflows/commands/implement.md
  ```
  Expected: `INSERT_OK`; the diff stat shows only `implement.md` with a small insertion (≈15 lines added, 0 removed).

- [ ] **Step 3: Commit** (stage only `commands/implement.md`; same trailer).

---

### Task 5: `references/next-phase-offer.md` — add the `/ready` node

**Files:**
- Modify: `plugins/dev-workflows/references/next-phase-offer.md` (the **Team/Dev — build** section, lines 60–68).

**Interfaces:**
- Consumes: the routing-graph format already in the file.

- [ ] **Step 1: Edit the Team/Dev section.** Change the `/design` line and add a `/ready` line so the graph reads (keep the surrounding bullets intact):

  - `/design <VI> <Epic>` → optionally `/ready <VI> <Epic>` (verify readiness) → `/implement <VI> <Epic>`.
  - `/ready <VI> [<Epic>]` → **SUPPORTED** → `/implement <VI> [<Epic>]`; **PARTIAL / NOT-SUPPORTED** → resolve the named gaps + update the Jira status, then re-run `/ready`. *(Read-only verifier; not itself a linear pipeline node — an optional gate before build.)*

  Do NOT add `/ready` to the "Not pipeline nodes" list (it is an optional gate, cited above).

- [ ] **Step 2: Verify.**

  Run:
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && \
  grep -q "/ready" references/next-phase-offer.md && \
  grep -q "optionally .*/ready" references/next-phase-offer.md && echo "OFFER_OK" && \
  cd /workspace/ihudak-claude-plugins && git diff --stat plugins/dev-workflows/references/next-phase-offer.md
  ```
  Expected: `OFFER_OK`; diff stat shows only `next-phase-offer.md`.

- [ ] **Step 3: Commit** (stage only `next-phase-offer.md`; same trailer).

---

### Task 6: manifests + CHANGELOG (version, counts, description strings)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (repo root — the `dev-workflows` entry only)
- Modify: `plugins/dev-workflows/CHANGELOG.md`

- [ ] **Step 1: Bump version** in both manifests: `"version": "2.23.0"` → `"version": "2.24.0"`. (In `marketplace.json`, change ONLY the `dev-workflows` entry — leave `dt-style-guide` 0.2.2 and `obsidian-llm-wiki` 0.3.1 untouched.)

- [ ] **Step 2: Update the command clause** in BOTH `description` strings. Replace:
  `Nineteen slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /idea, /create-vi, /create-ard, /specify, /design, /feedback, /prompt, /prompt-brainstorm, /prompt-grill-me, and /statusline —`
  with:
  `Twenty slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /idea, /create-vi, /create-ard, /specify, /design, /feedback, /prompt, /prompt-brainstorm, /prompt-grill-me, /statusline, and /ready —`

- [ ] **Step 3: Update the subagent clause** in BOTH `description` strings. Replace:
  `Twenty-nine reusable subagents (risk-planner, code-review, doc-reviewer, epic-reviewer, test-baseliner, test-writer, review-fixer, doc-fixer, docs-style-checker, doc-planner, doc-location-finder, jira-reader, idea-reader, release-notes-writer, diff-summarizer, code-scanner, impl-maintenance, guideline-reviewer, api-guideline-reviewer, upgrade-planner, upgrade-executor, vuln-research, vuln-fixer, doc-writer, epic-writer, spec-reviewer, design-reviewer, vi-reviewer, ard-reviewer)`
  with:
  `Thirty reusable subagents (risk-planner, code-review, doc-reviewer, epic-reviewer, test-baseliner, test-writer, review-fixer, doc-fixer, docs-style-checker, doc-planner, doc-location-finder, jira-reader, idea-reader, release-notes-writer, diff-summarizer, code-scanner, impl-maintenance, guideline-reviewer, api-guideline-reviewer, upgrade-planner, upgrade-executor, vuln-research, vuln-fixer, doc-writer, epic-writer, spec-reviewer, design-reviewer, vi-reviewer, ard-reviewer, readiness-reviewer)`

- [ ] **Step 4: Prepend the CHANGELOG entry** above `## [2.23.0] — 2026-07-12`:

  ```markdown
  ## [2.24.0] — 2026-07-12

  ### Added

  - **`/ready <VI> [<Epic>]`** — new status-anchored readiness gate. Reads the Jira workflow status (already emitted by `jira-reader` — no importer/reader change) and verifies the ARD/spec/design artifacts justify it and the next transition; returns **SUPPORTED / PARTIAL / NOT-SUPPORTED** with a coverage roll-up and cross-artifact findings. Read-only: never sets Jira status, never branches, never auto-commits. Writes a `_readiness.md` evidence snapshot to `$SPECS_PATH` for team visibility. Doc-only, with a best-effort repo-availability presence check.
  - **`readiness-reviewer`** — new Opus subagent; the only reviewer doing joint cross-artifact analysis (status consistency, coverage chain, alignment, ARD conformance, scope integrity, identifier integrity, repo availability).
  - **`references/workflow-states.md`** — new rubric mapping VI/Epic Jira status ladders ↔ pipeline command ↔ owning role ↔ expected artifacts.
  - `/implement`: additive Jira-mode **Phase 0.5 readiness pre-flight** (advisory, non-blocking; direct mode byte-identical). `next-phase-offer.md`: `/ready` added as an optional Team/Dev gate.

  ### Notes

  - Flagship borrow from the BMAD + SpecKit + Superpowers + grill-me analysis (AI-First line 85). New command + agent — counts 19 → **20** commands / 29 → **30** subagents. No-regression: `jira-reader`, `/vuln`, `/upgrade`, and the sibling plugins are untouched; `/implement` direct mode is byte-identical.
  ```

- [ ] **Step 5: Verify manifests + counts.**

  Run:
  ```bash
  cd /workspace/ihudak-claude-plugins && \
  python3 -c "import json; d=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); assert d['version']=='2.24.0'; assert 'Twenty slash commands' in d['description'] and '/ready' in d['description'] and 'Thirty reusable subagents' in d['description'] and 'readiness-reviewer' in d['description']; print('PLUGIN_OK')" && \
  python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); dw=[p for p in m['plugins'] if p['name']=='dev-workflows'][0]; assert dw['version']=='2.24.0' and 'Twenty slash commands' in dw['description'] and 'readiness-reviewer' in dw['description']; sib={p['name']:p['version'] for p in m['plugins']}; assert sib['dt-style-guide']=='0.2.2' and sib['obsidian-llm-wiki']=='0.3.1'; print('MARKET_OK')" && \
  echo "commands=$(ls plugins/dev-workflows/commands/*.md | wc -l) agents=$(ls plugins/dev-workflows/agents/*.md | wc -l)"
  ```
  Expected: `PLUGIN_OK`, `MARKET_OK`, and `commands=20 agents=30`.

- [ ] **Step 6: Commit** (stage only the three files; same trailer).

  ```bash
  cd /workspace/ihudak-claude-plugins && \
  git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md && \
  git commit -m "chore(dev-workflows): v2.24.0 — /ready + readiness-reviewer (counts 20/30)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

## Whole-branch verification (after all tasks)

Run from `/workspace/ihudak-claude-plugins`:
```bash
git diff --stat main   # expect ONLY: commands/ready.md (new), agents/readiness-reviewer.md (new), references/workflow-states.md (new), commands/implement.md, references/next-phase-offer.md, plugins/dev-workflows/.claude-plugin/plugin.json, .claude-plugin/marketplace.json, plugins/dev-workflows/CHANGELOG.md
git diff main -- plugins/dt-style-guide plugins/obsidian-llm-wiki plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/agents/jira-reader.md   # expect EMPTY
```
Both manifests parse; `commands=20 agents=30`; all Task grep anchors present.

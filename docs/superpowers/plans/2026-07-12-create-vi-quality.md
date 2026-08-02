---
tags:
  - tasks-exclude
---
# /create-vi VI-authoring quality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Dynatrace style check to `/create-vi` (Phase 3.5) and nudge complex VIs toward the richer `FR-N`/`UC-N` requirement clusters, improving VI quality and downstream `/epics` coverage granularity.

**Architecture:** Pure markdown/prompt change to one command file (`commands/create-vi.md`) plus manifests + CHANGELOG. The style check mirrors `/epics` Phase 6.1 but applies fixes inline (matching `/create-vi`'s no-delegated-writer authoring model). The nudge is authoring-side only (Phase 1.5 profile suggestion + Phase 3 active-pull) — `vi-reviewer` is deliberately unchanged.

**Tech Stack:** Markdown command definitions; JSON manifests. **No test framework, no build, no lint hook** — verification is STRUCTURAL (grep anchors, `python3 -c json.load`, `git diff --stat`).

## Global Constraints

- **Version:** `2.21.0` → `2.22.0` in BOTH `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of root `.claude-plugin/marketplace.json` — lock-step.
- **Counts unchanged:** 19 commands / 29 agents. Marketplace description strings `Nineteen slash commands` and `Twenty-nine reusable subagents` stay byte-identical.
- **Siblings byte-identical:** `dt-style-guide` (0.2.2) + `obsidian-llm-wiki` (0.3.1) — never touched.
- **Untouched:** `agents/vi-reviewer.md`, `commands/vuln.md`, `commands/upgrade.md`, all other command/agent files.
- **No-regression:** the profile nudge is guarded on `classification == SIGNIFICANT`; Phase 3.5 skips gracefully when `dt-style-checker` is unavailable — a SIMPLE/MODERATE run without `dt-style-guide` installed behaves byte-identically to today.
- **Commit named files only — NEVER `git add -A`.** Commit trailer EXACTLY:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Branch:** `ivgu/NOISSUE-create-vi-quality` off `main` (currently `5d672af`). Never commit on `main`.
- **Push only when the user asks.** The vault plan/spec are auto-backed-up by Obsidian Git — do NOT hand-commit them.

---

## Task 0: Branch

- [ ] **Step 1: Create the feature branch off main**

```bash
cd /workspace/ihudak-claude-plugins
git checkout main && git pull --ff-only
git checkout -b ivgu/NOISSUE-create-vi-quality
git rev-parse --abbrev-ref HEAD   # expect: ivgu/NOISSUE-create-vi-quality
```

No commit in this task.

---

## Task 1: Feature #5 — Phase 3.5 Dynatrace style check

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: a new `## Phase 3.5 — Dynatrace style check` section (invokes `dt-style-guide:dt-style-checker`, non-gating, inline fixes) + a final-report line naming the style-check outcome.

- [ ] **Step 1: Insert the Phase 3.5 section.**

In `plugins/dev-workflows/commands/create-vi.md`, find the line `## Phase 4 — Review gate` (and the `---` separator immediately above it). Insert the following BLOCK immediately BEFORE that `---`/`## Phase 4` (i.e. right after the end of Phase 3's content, which ends with the paragraph "...Keep the VI **product-level** — no implementation detail."):

````markdown
---

## Phase 3.5 — Dynatrace style check

Run a corporate style check on the authored VI **before** the review gate. This
is a **quality enhancement, not a gate** — it never blocks the handoff.
`vi-reviewer` (Phase 4) judges content; style / terminology is checked here
(mirrors `/epics` Phase 6.1).

→ Agent (subagent_type: "dt-style-guide:dt-style-checker", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > files:    [absolute path to <KEY>_ValueIncrement.md]
  > doc_type: vi
  > emphasis: terminology and customer-facing captions, labels, messages, and text"

Act on the return:
- **`OK`** — proceed to Phase 4.
- **`VIOLATIONS_FOUND`** — the orchestrator/grill applies the **MAJOR** fixes
  **inline** (no delegated writer — consistent with Phase 4's inline-fix model),
  then re-runs `dt-style-checker` **once**. Remaining MINOR/NIT are recorded in
  the final report.
- **`ERROR`** — surface the reason and proceed to Phase 4 (non-gating).

If `dt-style-checker` is unavailable (agent not found — the `dt-style-guide`
plugin is not installed), **skip this phase gracefully** and note
`SKIPPED (dt-style-checker unavailable)` in the final report.
````

- [ ] **Step 2: Add the style-check outcome to the final report.**

In the `## Final report` section (the single `Report:` paragraph), find `the \`vi-reviewer\` verdict;` and insert immediately after it (same sentence):
` the Dynatrace style-check outcome (\`OK\` | \`N fixed, M remaining\` | \`SKIPPED\`);`

- [ ] **Step 3: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
for a in "## Phase 3.5 — Dynatrace style check" "dt-style-guide:dt-style-checker" "doc_type: vi" "emphasis: terminology and customer-facing" "SKIPPED (dt-style-checker unavailable)" "Dynatrace style-check outcome"; do
  printf '%s -> ' "$a"; grep -c "$a" plugins/dev-workflows/commands/create-vi.md
done
# ordering: 3.5 must sit between Phase 3 and Phase 4
grep -n "^## Phase 3 —\|^## Phase 3.5 —\|^## Phase 4 —" plugins/dev-workflows/commands/create-vi.md
git diff --stat   # expect only commands/create-vi.md
```
Expected: every count ≥ 1; the grep shows Phase 3 → Phase 3.5 → Phase 4 in that order; diff only `create-vi.md`.

- [ ] **Step 4: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/create-vi.md
git commit -m "$(cat <<'EOF'
NOISSUE feat(create-vi): Phase 3.5 Dynatrace style check for VIs

Add an advisory dt-style-checker pass on the authored VI before the vi-reviewer
gate (emphasis: terminology + customer-facing text), fixes applied inline,
graceful skip when dt-style-guide is absent. Mirrors /epics Phase 6.1.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Feature #1 — FR-N/UC-N nudge for complex VIs

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md`

**Interfaces:**
- Consumes: the `model_routing.classification` value produced in Phase 1.5.
- Produces: a Phase 1.5 non-blocking profile nudge (guarded on `SIGNIFICANT`) + strengthened Phase 3 active-pull guidance. No `vi-reviewer` change.

- [ ] **Step 1: Add the Phase 1.5 profile nudge.**

In `plugins/dev-workflows/commands/create-vi.md`, in `## Phase 1.5 — Classify + model routing`, find the paragraph that ends "...do not hard-block." (the sentence beginning "The grill + authoring run inline on `current_model`..."). Insert immediately AFTER that paragraph:

```markdown
**Profile nudge (complex VIs).** If `classification` is **SIGNIFICANT** (a
complex / cross-cutting VI) and the chosen profile is `--lean` or `--hybrid`
(so `FR-N` is unavailable — it is full-only), surface a one-line **non-blocking**
recommendation before Phase 2:
> "This VI classifies SIGNIFICANT — consider `--full` so Functional Requirements
> (`FR-N`) and richer Use Cases (`UC-N`) are available for stronger, more
> traceable downstream Epic coverage."

Offer `choices: ["Switch to --full", "Keep <profile>", "Other… (describe)"]`. On
"Keep", proceed unchanged. For a SIMPLE / MODERATE classification, or when the
profile is already `--full`, this nudge does **not** fire.
```

- [ ] **Step 2: Strengthen the Phase 3 adapt-in guidance (active pull).**

In `## Phase 3 — Author via grill`, find the sentence:
`Then author the profile's **adapt-in clusters**, each **pulled only when the idea warrants it** (never an empty section).`
Replace it with:
`Then author the profile's **adapt-in clusters**, each **pulled only when the idea warrants it** (never an empty section). **For a complex VI (`classification` SIGNIFICANT), actively author the `FR-N` (full) and `UC-N` (hybrid/full) clusters** within the chosen profile — lower the bar for pulling them in, because ID'd functional requirements and use cases feed a finer downstream `/epics` `_coverage.md` (traceability to `FR-N`/`UC-N`, not only `US`/`AC`/`SM`); still never an empty section.`

- [ ] **Step 3: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
for a in "Profile nudge (complex VIs)" "consider \`--full\`" "Switch to --full" "actively author the \`FR-N\` (full) and \`UC-N\`"; do
  printf '%s -> ' "$a"; grep -c "$a" plugins/dev-workflows/commands/create-vi.md
done
# vi-reviewer must be untouched by this whole branch
git diff --stat main -- plugins/dev-workflows/agents/vi-reviewer.md   # expect EMPTY
git diff --stat   # expect only commands/create-vi.md
```
Expected: every count ≥ 1; the vi-reviewer diff EMPTY; diff only `create-vi.md`.

- [ ] **Step 4: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/create-vi.md
git commit -m "$(cat <<'EOF'
NOISSUE feat(create-vi): nudge complex VIs toward FR-N/UC-N

Phase 1.5 non-blocking profile nudge (SIGNIFICANT + lean/hybrid -> suggest
--full) and Phase 3 active-pull of FR-N/UC-N for complex VIs, for finer
downstream /epics coverage. vi-reviewer unchanged (authoring-side only).

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Version bump + CHANGELOG

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:** none (release plumbing).

- [ ] **Step 1: Bump plugin.json.**

Edit `plugins/dev-workflows/.claude-plugin/plugin.json`: change `"version": "2.21.0"` → `"version": "2.22.0"`.

- [ ] **Step 2: Bump the marketplace dev-workflows entry.**

Edit `.claude-plugin/marketplace.json`: in the `dev-workflows` entry, change its `"version": "2.21.0"` → `"version": "2.22.0"`. Do NOT touch the description strings or any sibling entry.

- [ ] **Step 3: Prepend the CHANGELOG entry.**

At the top of `plugins/dev-workflows/CHANGELOG.md` (above the current newest entry), prepend:

```markdown
## [2.22.0] — 2026-07-12

### Added

- `/create-vi`: new **Phase 3.5 Dynatrace style check** — runs `dt-style-checker` on the authored VI before the `vi-reviewer` gate (emphasis: terminology + customer-facing captions/labels/messages/text), fixes applied inline, graceful skip when `dt-style-guide` is not installed. Advisory (non-gating); mirrors `/epics` Phase 6.1. VIs previously got no style check.
- `/create-vi`: **nudge toward richer requirements for complex VIs** — a Phase 1.5 non-blocking profile suggestion (SIGNIFICANT + `--lean`/`--hybrid` → consider `--full` for `FR-N`/`UC-N`) and Phase 3 active-pull of the `FR-N`/`UC-N` clusters, for finer downstream `/epics` coverage traceability. `vi-reviewer` unchanged (authoring-side only).

### Notes

- Closes two recorded follow-ups from v2.21.0. No new command or agent — counts unchanged (19 / 29). No-regression: a SIMPLE/MODERATE VI (or one run without `dt-style-guide`) behaves as before; `/vuln`, `/upgrade`, `agents/vi-reviewer.md`, and the sibling plugins are untouched. The two marginal v2.21.0 follow-ups (graded reviewer rubric; cross-iteration regression tracking) were dropped.
```

- [ ] **Step 4: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print('plugin', json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"   # expect 2.22.0
python3 -c "import json;d=[p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins'] if p['name']=='dev-workflows'][0];print('marketplace', d['version'])"   # expect 2.22.0
head -3 plugins/dev-workflows/CHANGELOG.md | grep "2.22.0"   # expect the new heading
ls -1 plugins/dev-workflows/commands/*.md | wc -l   # expect 19
ls -1 plugins/dev-workflows/agents/*.md | wc -l     # expect 29
grep -c "Nineteen slash commands" .claude-plugin/marketplace.json   # expect 1
grep -c "Twenty-nine reusable subagents" .claude-plugin/marketplace.json   # expect 1
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki   # expect EMPTY
```
Expected: both versions 2.22.0; CHANGELOG heading present; counts 19/29; description strings present; sibling diff empty.

- [ ] **Step 5: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
NOISSUE chore(create-vi): bump dev-workflows to 2.22.0 + CHANGELOG

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final whole-branch verification (before finish-branch)

```bash
cd /workspace/ihudak-claude-plugins
git diff --stat main   # expect EXACTLY: create-vi.md, plugin.json, marketplace.json, CHANGELOG.md
# hard no-regression gates (all must be EMPTY):
git diff main -- plugins/dev-workflows/agents/vi-reviewer.md plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md
git diff main -- plugins/dt-style-guide plugins/obsidian-llm-wiki
# manifests parse:
python3 -c "import json;json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));json.load(open('.claude-plugin/marketplace.json'));print('manifests OK')"
```
Expected: exactly 4 files changed; the two no-regression diffs empty; manifests parse.

Then hand off to **superpowers:finishing-a-development-branch** (no test suite — the structural verification above IS the gate; present the merge/PR options and let the user choose; push only when asked).

---

## Self-Review

**Spec coverage:** §4 (Phase 3.5 style check) → Task 1. §5 (Phase 1.5 nudge + Phase 3 active-pull) → Task 2. §3 in-scope item 3 + §7 (manifests/CHANGELOG/verification) → Task 3 + the per-task + final gates. §6 no-regression → the guarded nudge (Task 2), graceful skip (Task 1), and the vi-reviewer/sibling/vuln/upgrade empty-diff checks (Tasks 2–3 + final). All spec sections mapped.

**Placeholder scan:** No TBD/TODO. Every edit shows the exact anchor + the exact markdown to insert/replace; verification steps give exact commands + expected output.

**Type consistency:** `classification` (Phase 1.5 `model_routing.classification`) is the single value both the Task 2 nudge and the Phase 3 active-pull key off — consistent. `doc_type: vi` and the `dt-style-guide:dt-style-checker` subagent name match the spec §4. Phase names (3.5, 1.5, 3, 4) consistent with the existing file. Version `2.22.0` consistent across Task 3.

---
tags:
  - tasks-exclude
---
# /epics VI-level-spec requirement enrichment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a VI-level `specification.md` exists at `/epics` time, fold its `[Uxx]`/`[ACxx]` requirements into the coverage inventory as tagged `spec-story`/`spec-criterion` rows — additive, zero-cost when absent.

**Architecture:** All detection + parse + merge happens in `/epics` (which already resolves the `$SPECS_PATH` VI dir via ARD Phase 2.5). A new optional Phase 2.6 produces `vi_spec_requirements[]`; Phase 3 appends them to the `requirements[]` carried from `jira-reader`; the merged list flows unchanged through the existing handoff/reviewer paths. `epic-writer` renders the rows (existing `Type` column) plus a one-line `_source:` note; `epic-reviewer` gets a one-line disambiguation. `jira-reader` and `vi-reviewer` are untouched.

**Tech Stack:** Markdown command/agent definitions; JSON manifests. **No test framework, no build, no lint hook** — verification is STRUCTURAL (grep anchors, `python3 -c json.load`, `git diff --stat`).

## Global Constraints

- **Version:** `2.22.0` → `2.23.0` in BOTH `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of root `.claude-plugin/marketplace.json` — lock-step.
- **Counts unchanged:** 19 commands / 29 agents. Marketplace description strings `Nineteen slash commands` and `Twenty-nine reusable subagents` stay byte-identical.
- **Siblings byte-identical:** `dt-style-guide` (0.2.2) + `obsidian-llm-wiki` (0.3.1) — never touched.
- **Untouched:** `agents/jira-reader.md`, `agents/vi-reviewer.md`, `commands/vuln.md`, `commands/upgrade.md`.
- **No-regression:** Phase 2.6 is a silent no-op when `$SPECS_PATH` is unset, no VI dir matches, or no `specification.md` exists (the common case) — the run is byte-identical to v2.22.0. The `epic-writer` `_source:` suffix only appears when a `spec-*` row is present.
- **`[TCxx]` excluded** — per-AC, non-unique, below Epic granularity. Only the spec's `[Uxx]`/`[ACxx]` are folded in.
- **Commit named files only — NEVER `git add -A`.** Commit trailer EXACTLY:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Branch:** `ivgu/NOISSUE-epics-vi-spec-enrichment` off `main` (currently `121e6d6`). Never commit on `main`.
- **Push only when the user asks.** The vault plan/spec are auto-backed-up by Obsidian Git — do NOT hand-commit them.

---

## Task 0: Branch

- [ ] **Step 1: Create the feature branch off main**

```bash
cd /workspace/ihudak-claude-plugins
git checkout main && git pull --ff-only
git checkout -b ivgu/NOISSUE-epics-vi-spec-enrichment
git rev-parse --abbrev-ref HEAD   # expect: ivgu/NOISSUE-epics-vi-spec-enrichment
```

No commit in this task.

---

## Task 1: `/epics` — Phase 2.6 detect/parse + Phase 3 merge + report line

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md`

**Interfaces:**
- Produces (consumed by Task 2): the merged `requirements[]` may include rows with `type: spec-story` / `spec-criterion` (ids are the spec's own `Uxx`/`ACxx`), and a `vi_spec_present` boolean.

- [ ] **Step 1: Insert Phase 2.6 after Phase 2.5.**

In `plugins/dev-workflows/commands/epics.md`, find `## Phase 3 — Read Jira hierarchy` (and the `---` separator immediately above it). Insert the following BLOCK immediately BEFORE that `---`/`## Phase 3` (i.e. right after Phase 2.5's content):

````markdown
---

## Phase 2.6 — VI-level spec enrichment (optional)

If a VI-level specification exists, fold its requirements into the coverage
inventory. **Additive, zero-cost when absent** — the common case, since
`/specify` usually runs per-Epic *after* `/epics`.

1. **Resolve the VI dir:** `$SPECS_PATH/specifications/<VI>-<vslug>/`, matched by
   key-number, tolerating a stray `-`/`_` and a human-adjusted slug (the same
   rule `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` step 1 uses). If
   `$SPECS_PATH` is unset/unresolvable, or no VI dir matches → **skip** (set
   `vi_spec_present: false`).
2. **Detect:** if `<VI-dir>/specification.md` does not exist → **skip** (set
   `vi_spec_present: false`); the run proceeds byte-identically to today.
3. **Parse** `<VI-dir>/specification.md` directly (Read it — one file, a simple
   heading scan): extract its user stories `[Uxx]` and their nested acceptance
   criteria `[ACxx]` into `vi_spec_requirements[]`. **Skip `[TCxx]` test cases**
   (per-AC, non-unique, below Epic granularity) and the prose sections
   (Problem/Scope):

   ```yaml
   vi_spec_requirements:
     - id:   <Uxx | ACxx>          # the spec's own id, preserved verbatim
       type: spec-story | spec-criterion
       text: <requirement text>
   ```

   Set `vi_spec_present: true` and record the resolved `specification.md` path
   for the Phase 9 report.
````

- [ ] **Step 2: Add the Phase 3 merge.**

In `## Phase 3 — Read Jira hierarchy`, find the sentence that ends `they are the coverage ground truth for Phases 6–7.` Insert immediately AFTER it (new paragraph):

```markdown
When Phase 2.6 set `vi_spec_present: true`, **append** its
`vi_spec_requirements[]` to this `requirements[]` — the VI's own rows are
unchanged; the appended rows carry `type: spec-story` / `spec-criterion`, which
separates them from the VI's `story`/`criterion` rows. The merged list flows
unchanged into the Phase 6 handoff and the Phase 7 reviewer brief. When
`vi_spec_present: false`, `requirements[]` is exactly what `jira-reader` returned.
```

- [ ] **Step 3: Add the Phase 9 report note.**

In `## Phase 9 — Final Report`, find the `### Requirement coverage` block's content line (it begins `[Roll-up verdict + N/M covered (P%)`). Append this sentence to that same line, before the ` — _or_ ` clause:
` If Phase 2.6 enriched the inventory, also name the VI-level \`specification.md\` path and the count of \`spec-*\` rows added.`

- [ ] **Step 4: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
for a in "## Phase 2.6 — VI-level spec enrichment" "vi_spec_requirements" "spec-story | spec-criterion" "vi_spec_present" "append\*\* its" "spec-\* rows added"; do
  printf '%s -> ' "$a"; grep -c "$a" plugins/dev-workflows/commands/epics.md
done
# phase order: 2.5 -> 2.6 -> 3
grep -n "^## Phase 2.5 —\|^## Phase 2.6 —\|^## Phase 3 —" plugins/dev-workflows/commands/epics.md
git diff --stat   # expect only commands/epics.md
```
Expected: every count ≥ 1; phase order 2.5 → 2.6 → 3; diff only `epics.md`.

- [ ] **Step 5: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/epics.md
git commit -m "$(cat <<'EOF'
NOISSUE feat(epics): Phase 2.6 VI-level spec requirement enrichment

Detect an optional VI-level specification.md (via the VI dir /epics already
resolves), parse its [Uxx]/[ACxx] into spec-story/spec-criterion rows, and merge
them into the coverage requirements[]. Skips [TCxx]. Silent no-op when no spec.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: agent touches — `epic-writer` `_source:` + `epic-reviewer` clarification

**Files:**
- Modify: `plugins/dev-workflows/agents/epic-writer.md`
- Modify: `plugins/dev-workflows/agents/epic-reviewer.md`

**Interfaces:**
- Consumes (from Task 1): `requirements[]` rows may carry `type: spec-story` / `spec-criterion`.
- Produces: no new interface — the `_coverage.md` `_source:` line gains a `+ VI-level spec` suffix when such rows exist; the reviewer's coverage dimension explicitly covers them.

- [ ] **Step 1: epic-writer — extend the `_source:` rule.**

In `plugins/dev-workflows/agents/epic-writer.md`, find the bullet:
`- Rows = the handoff \`requirements[]\`. "Covered by" counts BOTH existing linked`
… whose sub-sentence reads `\`_source:\` echoes \`requirements_source\`.` Replace that sentence (`\`_source:\` echoes \`requirements_source\`.`) with:
`` `_source:` echoes `requirements_source`; when any `spec-story`/`spec-criterion` row is present (a VI-level spec was folded in by `/epics` Phase 2.6), append ` + VI-level spec` to it (e.g. `_source: native + VI-level spec_`). ``

- [ ] **Step 2: epic-reviewer — clarify the coverage dimension.**

In `plugins/dev-workflows/agents/epic-reviewer.md`, find the dimensions-table row that begins `| Requirement coverage | Every VI requirement in \`requirements[]\``. Append to that row's Check cell (before the closing `|`):
` `requirements[]` may also include `spec-story`/`spec-criterion` rows sourced from a VI-level spec (via `/epics` Phase 2.6) — treat them identically to VI requirements (uncovered → MAJOR).`

- [ ] **Step 3: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
grep -c "+ VI-level spec" plugins/dev-workflows/agents/epic-writer.md          # expect >= 1
grep -c "spec-story\`/\`spec-criterion\` rows sourced from a VI-level spec" plugins/dev-workflows/agents/epic-reviewer.md  # expect 1
# no-regression: jira-reader + vi-reviewer untouched by the whole branch
git diff --stat main -- plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/agents/vi-reviewer.md   # expect EMPTY
git diff --stat   # expect only the two agent files
```
Expected: both grep counts ≥ 1; the jira-reader/vi-reviewer diff EMPTY; diff only the two agent files.

- [ ] **Step 4: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/epic-writer.md plugins/dev-workflows/agents/epic-reviewer.md
git commit -m "$(cat <<'EOF'
NOISSUE feat(epics): render + review VI-level-spec requirement rows

epic-writer notes '+ VI-level spec' on the _coverage.md _source: line when
spec-* rows are present; epic-reviewer's coverage dimension states spec-story/
spec-criterion rows are checked identically to VI requirements.

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

- [ ] **Step 1: Bump plugin.json.** Change `"version": "2.22.0"` → `"version": "2.23.0"` in `plugins/dev-workflows/.claude-plugin/plugin.json`.

- [ ] **Step 2: Bump the marketplace dev-workflows entry.** In `.claude-plugin/marketplace.json`, in the `dev-workflows` entry, change its `"version": "2.22.0"` → `"2.23.0"`. Do NOT touch description strings or any sibling entry.

- [ ] **Step 3: Prepend the CHANGELOG entry.** At the top of `plugins/dev-workflows/CHANGELOG.md`, prepend:

```markdown
## [2.23.0] — 2026-07-12

### Added

- `/epics`: new optional **Phase 2.6 VI-level spec enrichment** — when a VI-level `specification.md` exists (detected via the VI dir `/epics` already resolves), its `[Uxx]`/`[ACxx]` requirements are folded into the coverage inventory as `spec-story`/`spec-criterion` rows, so the `_coverage.md` matrix reflects the richer spec-level requirements. Test cases (`[TCxx]`) are excluded (per-AC, non-unique, below Epic granularity). `epic-writer` notes `+ VI-level spec` on the `_source:` line; `epic-reviewer` checks the spec rows identically (uncovered → MAJOR).

### Notes

- Closes the last v2.21.0 follow-up (Cluster B / #4). Strictly additive: a run with no VI-level spec (the common case) is byte-identical to v2.22.0. No new command or agent — counts unchanged (19 / 29). `jira-reader`, `vi-reviewer`, `/vuln`, `/upgrade`, and the sibling plugins are untouched.
```

- [ ] **Step 4: Structural verification.**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print('plugin', json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"   # expect 2.23.0
python3 -c "import json;d=[p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins'] if p['name']=='dev-workflows'][0];print('marketplace', d['version'])"   # expect 2.23.0
head -3 plugins/dev-workflows/CHANGELOG.md | grep "2.23.0"   # expect the new heading
ls -1 plugins/dev-workflows/commands/*.md | wc -l   # expect 19
ls -1 plugins/dev-workflows/agents/*.md | wc -l     # expect 29
grep -c "Nineteen slash commands" .claude-plugin/marketplace.json   # expect 1
grep -c "Twenty-nine reusable subagents" .claude-plugin/marketplace.json   # expect 1
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki   # expect EMPTY
```
Expected: both versions 2.23.0; CHANGELOG heading present; counts 19/29; description strings present; sibling diff empty.

- [ ] **Step 5: Commit.**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
NOISSUE chore(epics): bump dev-workflows to 2.23.0 + CHANGELOG

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final whole-branch verification (before finish-branch)

```bash
cd /workspace/ihudak-claude-plugins
git diff --stat main   # expect EXACTLY: epics.md, epic-writer.md, epic-reviewer.md, plugin.json, marketplace.json, CHANGELOG.md
# hard no-regression gates (all must be EMPTY):
git diff main -- plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/agents/vi-reviewer.md plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md
git diff main -- plugins/dt-style-guide plugins/obsidian-llm-wiki
# manifests parse:
python3 -c "import json;json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));json.load(open('.claude-plugin/marketplace.json'));print('manifests OK')"
```
Expected: exactly 6 files changed; the two no-regression diffs empty; manifests parse.

Then hand off to **superpowers:finishing-a-development-branch** (no test suite — the structural verification above IS the gate; present the merge/PR options and let the user choose; push only when asked).

---

## Self-Review

**Spec coverage:** §4 (Phase 2.6 detect/parse) → Task 1 Step 1. §5 (Phase 3 merge) → Task 1 Step 2. §6 (epic-writer `_source:` touch) → Task 2 Step 1. §7 (epic-reviewer clarification) → Task 2 Step 2. §3 in-scope item 5 + §9 (manifests/CHANGELOG/verification) → Task 3 + gates. §8 no-regression → the skip guards (Task 1) + the jira-reader/vi-reviewer/sibling empty-diff checks (Tasks 2–3 + final). All spec sections mapped; the Phase 9 report line (§4 last sentence) → Task 1 Step 3.

**Placeholder scan:** No TBD/TODO. Every edit shows the exact anchor + exact markdown; verification steps give exact commands + expected output.

**Type consistency:** `vi_spec_requirements[]` (Task 1) with `type: spec-story`/`spec-criterion` is the exact shape Task 2's agent touches reference; `vi_spec_present` is the guard flag named consistently across Task 1 Steps 1–2. `_source:` / `requirements_source` match the v2.21.0 `epic-writer` names. Version `2.23.0` consistent across Task 3.

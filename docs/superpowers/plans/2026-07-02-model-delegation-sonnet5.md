---
tags:
  - tasks-exclude
---

# model-delegation + Sonnet 5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend per-step model routing to `/implement`, `/vuln`, `/upgrade` (mechanical steps → Sonnet, judgment gates → Opus) and make Sonnet 5 the Sonnet-tier primary across the routing SSOT, releasing as MINOR v2.3.0.

**Architecture:** One shared SSOT (`references/model-routing/classification.md`) defines the §2 Opus and §2.1 Sonnet chains; adopting commands build a §4 `model_routing` block at classification time and pin each subagent dispatch to a tier via `model:`. `/epics` and `/document` are the reference pattern. This effort applies that pattern to three more commands and bumps the Sonnet tier to Sonnet 5.

**Tech Stack:** Markdown command/reference files, JSON manifests. Structural verification only (grep + `python3 -c json.load`) — the plugin repo has NO test framework and NO husky/prettier hook.

## Global Constraints

- Base repo `/workspace/ihudak-claude-plugins`, branch off `main` @ `6f54238` (v2.2.1).
- **Sonnet chain order:** `claude-sonnet-5 → claude-sonnet-4-6 → claude-sonnet-4-5` (5 primary; 4.6/4.5 fallbacks).
- **Opus primaries unchanged** (`claude-opus-4-8 → 4-7 → 4-6`). **Keep Opus on every judgment gate** — `code-review`, `risk-planner`, `doc-reviewer`, `epic-reviewer`: NO `model:` override on their dispatches, NO change to their frontmatter. They are *recorded* in the routing block (as `review_model`/`planning_model`) but never overridden.
- **vuln/upgrade = shallow:** pin only the coordinator dispatches in `vuln.md`/`upgrade.md`. Do NOT edit any `agents/*.md` file.
- **Uniform scan routing (added 2026-07-02):** route by step nature, NOT by session/pipeline. `jira-reader`/`code-scanner` run on §2.1 Sonnet in every command (no "inherit the session model", no per-command exception), even when feeding an Opus synthesis; only carve-out = oversized-slice→Opus. This required a doctrine fix to `classification.md` §8.3/§9.4 + `implement.md`'s Invariant — see the Task 2 fix addendum.
- Version bump is **lock-step**: `plugin.json` `version`, `marketplace.json` **`plugins[0].version`** (NOT top-level), and a new `CHANGELOG.md` block all read `2.3.0`. Siblings dt-style-guide `0.2.2` / obsidian-llm-wiki `0.3.1` stay untouched.
- CHANGELOG: prepend above `## [2.2.1]`; em-dash (`—`) in the heading date; preserve all history. **Do NOT touch `CHANGELOG.md:132`** (historical model-ID example).
- Never `git add -A`; stage only the touched files. Never stage `.superpowers/` or `.docstack`.
- Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Reference pattern to mirror (read these, don't re-derive): `commands/epics.md:97-146` (Phase 1.5 `model_routing` block + dispatch-pin syntax) and `commands/document.md:176-190`.

---

### Task 1: SSOT chains + literal-ID example blocks → Sonnet 5

**Files:**
- Modify: `plugins/dev-workflows/references/model-routing/classification.md`
- Modify: `plugins/dev-workflows/commands/document.md`
- Modify: `plugins/dev-workflows/commands/epics.md`
- Modify: `plugins/dev-workflows/commands/docs-profile.md`

**Interfaces:**
- Produces: the §2.1 detection chain and §2 Opus-chain Sonnet fallback now lead with `claude-sonnet-5`. Tasks 2–4 reference the chain symbolically (`<§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>`), so their `detection_model` reminders must use that exact string.

- [ ] **Step 1: Create the feature branch**

```bash
cd /workspace/ihudak-claude-plugins
git checkout main
git checkout -b ivgu/NOISSUE-model-delegation-sonnet5
```

- [ ] **Step 2: Update §2 Opus-chain Sonnet fallback tail (classification.md)**

Old:
```
4. `claude-sonnet-4-6` (fallback only — note in the report that no Opus was available)
5. `claude-sonnet-4-5` (further fallback — note "no Opus or Sonnet 4.6 available")
```
New:
```
4. `claude-sonnet-5` (fallback only — note in the report that no Opus was available)
5. `claude-sonnet-4-6` (further fallback)
6. `claude-sonnet-4-5` (further fallback — note "no Opus or Sonnet 5/4.6 available")
```

- [ ] **Step 3: Update §2.1 Sonnet detection chain (classification.md)**

Old:
```
1. `claude-sonnet-4-6` (latest Sonnet)
2. `claude-sonnet-4-5` (fallback — note the degradation in the report)
```
New:
```
1. `claude-sonnet-5` (latest Sonnet)
2. `claude-sonnet-4-6` (fallback)
3. `claude-sonnet-4-5` (further fallback — note the degradation in the report)
```

- [ ] **Step 4: Update the `document.md` example block (line 183)**

Old: `  detection_model: <§2.1 mid-tier Sonnet chain: claude-sonnet-4-6, fallback claude-sonnet-4-5>`
New: `  detection_model: <§2.1 mid-tier Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>`

- [ ] **Step 5: Update the `epics.md` example block (line 104)**

Old: `  detection_model: <§2.1 Sonnet chain: claude-sonnet-4-6, fallback claude-sonnet-4-5>   # jira-reader, code-scanner, dt-style-checker, doc-fixer, epic-writer (MODERATE)`
New: `  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader, code-scanner, dt-style-checker, doc-fixer, epic-writer (MODERATE)`

- [ ] **Step 6: Update the `docs-profile.md` example block + prose (lines 60, 61, 64, 73, 75)**

6a — line 60:
Old: `  detection_model: <§2.1 mid-tier Sonnet chain: claude-sonnet-4-6, fallback claude-sonnet-4-5>`
New: `  detection_model: <§2.1 mid-tier Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>`

6b — line 61 (added for consistency with 6c — same §2 Sonnet-fallback illustration):
Old: `  planning_model: <§2 powerful chain: claude-opus-4-8 … fallback Sonnet 4.6/4.5>`
New: `  planning_model: <§2 powerful chain: claude-opus-4-8 … fallback Sonnet 5/4.6/4.5>`

6c — line 64:
Old: `  notes: <any §2.1/§2 degradation, e.g. "Opus unavailable; synthesis fell back to claude-sonnet-4-6">`
New: `  notes: <any §2.1/§2 degradation, e.g. "Opus unavailable; synthesis fell back to claude-sonnet-5">`

6d — line 73 (substring within the prose paragraph):
Old: ``override — `claude-sonnet-4-6`, fallback `claude-sonnet-4-5`; record``
New: ``override — `claude-sonnet-5`, fallback `claude-sonnet-4-6`/`claude-sonnet-4-5`; record``

6e — line 75:
Old: ``→ Agent (subagent_type: "general-purpose", model: `<detection_model — §2.1: claude-sonnet-4-6, fallback claude-sonnet-4-5>`):``
New: ``→ Agent (subagent_type: "general-purpose", model: `<detection_model — §2.1: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>`):``

- [ ] **Step 7: Verify Task 1**

```bash
cd /workspace/ihudak-claude-plugins
echo -n "sonnet-5 in classification.md (expect >=2) -> "; grep -c "claude-sonnet-5" plugins/dev-workflows/references/model-routing/classification.md
echo -n "sonnet-5 in the 3 example files (expect 3, one each) -> "; grep -rl "claude-sonnet-5" plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/docs-profile.md | wc -l
echo -n "stale lead 'detection_model:...4-6, fallback' (expect 0) -> "; grep -rc "detection_model: <§2.1[^>]*claude-sonnet-4-6, fallback" plugins/dev-workflows/commands/ | grep -v ':0' | wc -l
echo -n "fallbacks preserved: 4-6 in classification (expect >=2) -> "; grep -c "claude-sonnet-4-6" plugins/dev-workflows/references/model-routing/classification.md
```
Expected: `>=2`; `3`; `0`; `>=2`.

- [ ] **Step 8: Commit Task 1**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/model-routing/classification.md plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/docs-profile.md
git commit -m "Adopt Sonnet 5 as the Sonnet-tier primary in the routing SSOT + example blocks

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `/implement` — full per-step routing

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md`

**Interfaces:**
- Consumes: the §2.1 Sonnet chain string from Task 1.
- Reference pattern: `commands/epics.md:97-146` and `commands/document.md:176-190` — read these first for the block form + the `model: \`<...>\`` dispatch-pin syntax used in this repo.

- [ ] **Step 1: Read `implement.md` and the reference pattern.** Confirm the Phase 1.5 classification step and every dispatch site (`jira-reader`, `code-scanner`, Phase 2A `general-purpose` exploration, `risk-planner`, `test-writer`, `test-baseliner`, `code-review`, `review-fixer`). Locate dispatches by their `subagent_type` string, not by line number.

- [ ] **Step 2: Add the `model_routing` block to Phase 1.5**

Immediately after the classification statement in Phase 1.5, insert (matching the surrounding markdown/YAML fence style):

```yaml
model_routing:
  classification: <SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK>
  reason: <one-line>
  current_model: <the model this orchestrator is running under>   # = the inline implementation coding
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader, code-scanner, Phase 2A exploration, test-writer, test-baseliner, review-fixer
  planning_model: <§2 Opus chain>   # risk-planner (Phase 2B; SIGNIFICANT/HIGH-RISK only; frontmatter-pinned, recorded, no override)
  review_model:  <§2 Opus chain>    # code-review (Phase 3B; frontmatter-pinned, recorded, no override)
  implementation_model: <= current_model>   # coding done inline by the orchestrator
  fixes_model: <= detection_model>          # review-fixer (Phase 3B)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2 / §2.1 fallback or degradation>
```

Add one sentence after the block: "Each subagent dispatch below cites its chain (§9 role→chain map); mechanical steps pin `detection_model` via `model:`, and the frontmatter-Opus gates (`risk-planner`, `code-review`) are recorded but never overridden."

- [ ] **Step 3: Pin the mechanical dispatches**

For each of these dispatches, add a `model:` argument in the file's existing dispatch syntax, value ``model: `<detection_model — §2.1 Sonnet chain>` ``:
- `jira-reader` (Phase 1.7)
- `code-scanner` (Phase 1.7)
- Phase 2A `general-purpose` exploration
- `test-writer` (Phase 3.5 and Phase 3B — both dispatches)
- `test-baseliner` (Phase 3.5)
- `review-fixer` (Phase 3B) — use ``model: `<fixes_model — = detection_model, §2.1 Sonnet chain>` ``

- [ ] **Step 4: Confirm the gates stay Opus (no override)**

`risk-planner` (Phase 2B) and `code-review` (Phase 3B): do NOT add a `model:` override. Add/keep a one-clause citation on each dispatch noting it is frontmatter-Opus-pinned (recorded in `model_routing`, no override) — matching the `epic-reviewer`/`doc-reviewer` style in the reference files.

- [ ] **Step 5: Verify Task 2**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/implement.md
echo -n "model_routing block present (expect >=1) -> "; grep -c "model_routing:" $F
echo -n "detection_model reminder w/ sonnet-5 (expect >=1) -> "; grep -c "detection_model:.*claude-sonnet-5" $F
echo -n "mechanical dispatches pinned (expect >=5 model: refs) -> "; grep -c "model: \`<detection_model\|model: \`<fixes_model" $F
echo "-- gates must have NO model: on their dispatch lines (manual: risk-planner, code-review) --"; grep -nE "risk-planner|code-review" $F
```
Expected: `model_routing:` ≥1; sonnet-5 detection reminder ≥1; ≥5 mechanical pins; and the `risk-planner`/`code-review` dispatch lines carry no `model:` override.

- [ ] **Step 6: Commit Task 2**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/implement.md
git commit -m "/implement: adopt full per-step model routing (Sonnet detection, Opus gates)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

#### Task 2 fix addendum (post-review, 2026-07-02)

T2's original commit (`d427f35`) correctly pinned `jira-reader`/`code-scanner`/Phase 2A to Sonnet, but that contradicted the SSOT's stale "inherit the session model" text. A follow-up **fix commit** on the same branch resolves it (uniform routing, user-approved):
- `classification.md` §8.3 — rewrite "`jira-reader`/`code-scanner` **inherit the session model**" → "pinned to the §2.1 detection (Sonnet) chain … must not inherit the session model"; keep the size-driven oversized-slice→Opus escalation.
- `classification.md` §9.4 — retitle "Reconciliation with §8.3" → "One rule across commands (`/implement` included)"; state that scan tier is by step nature, downstream Opus consumers don't change it, no per-command exception.
- `implement.md` Invariant (~line 539) — "…inherit the session model" → "pinned to the §2.1 detection (Sonnet) chain like every mechanical step (never inherit the session model)…".
- `implement.md` Pre-Phase 3.5 capture-mode `test-baseliner` — add `model: \`<detection_model — §2.1 Sonnet chain>\`` (the verify-mode call was already pinned; both now Sonnet).
- Verify: `grep -c "inherit the session model" classification.md` → 0; both `test-baseliner` dispatches pinned. The T2 re-review covers `6b37fb3..<fix-head>`.

---

### Task 3: `/vuln` — complete shallow routing

**Files:**
- Modify: `plugins/dev-workflows/commands/vuln.md`

**Interfaces:**
- Consumes: §2.1 Sonnet chain string (Task 1). Reference: `epics.md:97-146`.
- Shallow only — do NOT edit `agents/vuln-research.md` or `agents/vuln-fixer.md`.

- [ ] **Step 1: Read `vuln.md`.** Find Step 0 (classification) and every dispatch: `vuln-research`, `vuln-fixer` (both the SIMPLE/MODERATE and the SIGNIFICANT/HIGH-RISK paths), `code-review`, `review-fixer`. These dispatch via `task()` calls that already carry a partial `model_routing:` block.

- [ ] **Step 2: Extend the `model_routing` block(s) to the full §4 schema**

Wherever a `model_routing:` block appears in a `vuln-research` / `vuln-fixer` dispatch, extend it to:

```yaml
model_routing:
  classification: <SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK>   # per CVE
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # vuln-research; vuln-fixer (SIMPLE/MODERATE); review-fixer
  planning_model: <§2 Opus chain>   # vuln-fixer escalates here only if HIGH-RISK
  review_model:  <§2 Opus chain>    # code-review (frontmatter-pinned; recorded, no override)
  opus_available: <true if a §2 Opus model resolved, else false>
  gate_tests_on_review: <true for SIGNIFICANT/HIGH-RISK, false otherwise>
  notes: <any §2 / §2.1 fallback or degradation>
```

Preserve any existing `gate_tests_on_review` value already set on a given path.

- [ ] **Step 3: Pin the coordinator dispatches**

- `vuln-research`: add ``model: `<detection_model — §2.1 Sonnet chain>` ``.
- `vuln-fixer` (SIMPLE/MODERATE path): ``model: `<detection_model — §2.1 Sonnet chain>` ``.
- `vuln-fixer` (SIGNIFICANT/HIGH-RISK path): ``model: `<detection_model for SIGNIFICANT; planning_model (§2 Opus chain) only if HIGH-RISK>` ``.
- `review-fixer`: ``model: `<detection_model — §2.1 Sonnet chain>` ``.
- `code-review`: NO override (frontmatter Opus; add the recorded-not-overridden citation).

- [ ] **Step 4: Verify Task 3**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/vuln.md
echo -n "detection_model w/ sonnet-5 (expect >=1) -> "; grep -c "detection_model:.*claude-sonnet-5" $F
echo -n "full schema fields present (expect >=1 each) -> "; for k in planning_model review_model opus_available; do echo -n "$k="; grep -c "$k" $F; done
echo -n "coordinator model: pins (expect >=3) -> "; grep -c "model: \`<detection_model\|model: \`<detection_model for SIGNIFICANT" $F
echo "-- code-review must have NO model: override (manual) --"; grep -n "code-review" $F
```
Expected: sonnet-5 detection ≥1; each schema field ≥1; ≥3 coordinator pins; `code-review` unpinned.

- [ ] **Step 5: Commit Task 3**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/vuln.md
git commit -m "/vuln: complete shallow per-step routing (full model_routing block + coordinator pins)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `/upgrade` — complete shallow routing

**Files:**
- Modify: `plugins/dev-workflows/commands/upgrade.md`

**Interfaces:**
- Consumes: §2.1 Sonnet chain string (Task 1). Reference: `epics.md:97-146`.
- Shallow only — do NOT edit `agents/upgrade-planner.md` or `agents/upgrade-executor.md`.

- [ ] **Step 1: Read `upgrade.md`.** Find Phase 1.5 (classification) and every dispatch: `upgrade-planner`, `risk-planner`, `test-baseliner`, `upgrade-executor`, `code-review`, `review-fixer`.

- [ ] **Step 2: Extend the `model_routing` block(s) to the full §4 schema**

Wherever a `model_routing:` block appears in an `upgrade-planner` / `upgrade-executor` dispatch, extend it to:

```yaml
model_routing:
  classification: <SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK>   # per component
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # upgrade-planner, test-baseliner; upgrade-executor (SIMPLE/MODERATE); review-fixer
  planning_model: <§2 Opus chain>   # risk-planner (SIGNIFICANT/HIGH-RISK; frontmatter-pinned, recorded, no override); upgrade-executor escalates here only if HIGH-RISK
  review_model:  <§2 Opus chain>    # code-review (frontmatter-pinned; recorded, no override)
  opus_available: <true if a §2 Opus model resolved, else false>
  gate_tests_on_review: <true for SIGNIFICANT/HIGH-RISK, false otherwise>
  notes: <any §2 / §2.1 fallback or degradation>
```

Preserve any existing `gate_tests_on_review` value.

- [ ] **Step 3: Pin the dispatches**

- `upgrade-planner`: ``model: `<detection_model — §2.1 Sonnet chain>` ``.
- `test-baseliner`: ``model: `<detection_model — §2.1 Sonnet chain>` ``.
- `upgrade-executor` (SIMPLE/MODERATE): ``model: `<detection_model — §2.1 Sonnet chain>` ``; (HIGH-RISK): ``model: `<planning_model — §2 Opus chain>` ``.
- `review-fixer`: ``model: `<detection_model — §2.1 Sonnet chain>` ``.
- `risk-planner`, `code-review`: NO override (frontmatter Opus; add recorded-not-overridden citation).

- [ ] **Step 4: Verify Task 4**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/upgrade.md
echo -n "detection_model w/ sonnet-5 (expect >=1) -> "; grep -c "detection_model:.*claude-sonnet-5" $F
echo -n "full schema fields (expect >=1 each) -> "; for k in planning_model review_model opus_available; do echo -n "$k="; grep -c "$k" $F; done
echo -n "dispatch model: pins (expect >=4) -> "; grep -c "model: \`<detection_model\|model: \`<planning_model" $F
echo "-- risk-planner & code-review must have NO model: override (manual) --"; grep -nE "risk-planner|code-review" $F
```
Expected: sonnet-5 detection ≥1; each schema field ≥1; ≥4 pins; `risk-planner`/`code-review` unpinned.

- [ ] **Step 5: Commit Task 4**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/upgrade.md
git commit -m "/upgrade: complete shallow per-step routing (full model_routing block + dispatch pins)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Packaging → v2.3.0

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

- [ ] **Step 1: Bump plugin.json**

Old: `  "version": "2.2.1",`
New: `  "version": "2.3.0",`

- [ ] **Step 2: Bump marketplace.json dev-workflows entry**

Old: `      "version": "2.2.1",`
New: `      "version": "2.3.0",`

(Only one `2.2.1` in the file; siblings are `0.2.2`/`0.3.1` — leave them.)

- [ ] **Step 3: Prepend the CHANGELOG block**

Old: `## [2.2.1] — 2026-07-02`
New:
```
## [2.3.0] — 2026-07-02

### Added

- **Per-step model routing for `/implement`, `/vuln`, `/upgrade`.** These commands now build the full §4 `model_routing` block at classification time and pin each subagent dispatch to a tier: mechanical steps (readers, scanners, `test-writer`/`test-baseliner`, `review-fixer`, and the `/vuln`/`/upgrade` coordinators) run on the §2.1 Sonnet chain, while judgment gates (`risk-planner`, `code-review`) keep their frontmatter Opus pins. `/vuln` and `/upgrade` pin at the orchestrator level; their coordinators' internal leaves inherit the pinned tier.

### Changed

- **Sonnet 5 is the Sonnet-tier primary.** The §2.1 detection chain and the §2 Opus-chain Sonnet fallback now lead with `claude-sonnet-5` (then `claude-sonnet-4-6` → `claude-sonnet-4-5`). Opus primaries (`claude-opus-4-8` …) and all review/planning-gate Opus pins are unchanged.

## [2.2.1] — 2026-07-02
```

- [ ] **Step 4: Verify + commit Task 5**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print('plugin',json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"
python3 -c "import json;m=json.load(open('.claude-plugin/marketplace.json'));print([(p['name'],p['version']) for p in m['plugins']])"
grep -nE "^## \[" plugins/dev-workflows/CHANGELOG.md | head -3
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "Release v2.3.0 — model-delegation for /implement, /vuln, /upgrade + Sonnet 5

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: `plugin 2.3.0`; marketplace `('dev-workflows','2.3.0')`, `('dt-style-guide','0.2.2')`, `('obsidian-llm-wiki','0.3.1')`; CHANGELOG `[2.3.0]` then `[2.2.1]` then `[2.1.0]`.

---

## Finishing

After Task 5, dispatch the whole-branch code review (Opus) per subagent-driven-development, then use **superpowers:finishing-a-development-branch**. No test suite — structural verification above stands in. Base branch: `main`. Do not push unless the user asks.

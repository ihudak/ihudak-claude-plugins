---
tags:
  - tasks-exclude
---

# Two-key `<VI> <Epic>` grammar + Epic picker — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the dev-workflows Jira-driven commands a correct input grammar for a VI or one Epic (robust to the flat/unslugged vault + VI-keyed specs repo), a per-Epic output convention, and a progress-aware Epic picker — and fix `/specify` to use them. Additive; other commands keep working.

**Architecture:** One additive change to the shared front-end `references/jira-input-resolution.md` (VI-selector grammar that is key-or-directory + optional focus Epic; a new nullable `focus_key` output field; Fallbacks D/E; a documented picker pattern), then `/specify` consumes it (Phase 0 resolution + output path; Phases 2/2.5 picker + Epic-scoped read; Phase 7 branch name), then the version bump. Design authority: vault `spec/2026-07-07-two-key-grammar-foundation-design.md`.

**Tech Stack:** Markdown command/reference files + JSON manifests in `/workspace/ihudak-claude-plugins/plugins/dev-workflows`. No test framework, no husky/prettier hook — **verification is STRUCTURAL** (grep anchors, `python3 -c json.load`, byte-diff review).

## Global Constraints

- **Additive-only to the shared reference.** Single-key resolution and every existing `## Output contract` field stay byte-for-byte; `focus_key` is the only new field and is nullable. `/implement`/`/document`/`/epics`/`/release-notes` must behave exactly as today.
- **Delimiter = hyphen** everywhere the effort writes paths (`<VI>-<slug>`, `<EPIC>-<eslug>`); resolving an *existing* dir matches by key-number and tolerates a stray delimiter.
- **No `jira-reader` change** (agents/jira-reader.md untouched). Epic-scoping is orchestrator-side.
- **No new external API**; no network in command/reference logic.
- **Version lock-step:** `plugin.json` `version` **and** `marketplace.json` `plugins[0].version` → `2.5.0`; `CHANGELOG.md` prepend a `[2.5.0]` entry preserving all prior history; sibling plugins `dt-style-guide`/`obsidian-llm-wiki` untouched (top-level marketplace version is NOT the field to edit).
- **Commit trailer:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Never `git add -A`; never stage `.superpowers/` or `.docstack`. Feature branch: `ivgu/NOISSUE-two-key-grammar-foundation`.
- **Vault files** (this plan + the design doc) are NOT committed — vault git is the user's.

---

## File structure

- `references/jira-input-resolution.md` — the shared grammar + Output contract + fallbacks + picker pattern. **Task 1.**
- `commands/specify.md` — Phase 0 (resolution + output path) **Task 2**; Phases 2/2.5/7 (picker + scoped read + branch) **Task 3**.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`, READMEs — version + docs. **Task 4.**

Ordering 1→2→3→4: Task 1 defines the contract Tasks 2–3 consume; Task 4 finalizes.

---

## Task 1: Shared reference — VI-selector grammar + `focus_key` + Fallbacks D/E + picker pattern

**Files:**
- Modify: `references/jira-input-resolution.md`

**Interfaces:**
- Produces: the `focus_key` output field (consumed by Task 2/3); the "progress-aware Epic-picker pattern" subsection (consumed by Task 3, and by future commands).

- [ ] **Step 1: Extend the Resolution section with the VI-selector + focus-Epic grammar.**
  Under `## Resolution`, keep the existing `jira-driven — JiraID token` and `jira-driven — directory token` subsections intact, and add a new subsection describing the VI selector (a VI JiraID **or** a jira-export directory) plus an optional focus Epic. Insert this content (from design §3):

  ```markdown
  ### VI selector + optional focus Epic (two-key grammar)

  The first positional is a **VI selector** — either a **VI JiraID** (resolved under
  `$VAULT_PATH/jira-products/<VI-Key>`, a bare key with **no slug**; requires `$VAULT_PATH`) or a
  **jira-export directory** (content-classified as a jira-export; used directly as `jira_export_root`;
  **no `$VAULT_PATH` needed**). An optional **focus Epic** (a JiraID) may follow either form.

  - **Single VI JiraID** — classify against `jira-products/`: a **top-level dir** → a VI or stand-alone
    item (`jira_export_root = jira-products/<KEY>`, `source = vault`, `focus_key = null`); **not a
    top-level dir** → a **nested Epic**: auto-resolve its parent VI by scanning `jira-products/*/` for a
    child dir named `<KEY>` containing `<KEY>.md` (one parent → that VI is `jira_export_root`,
    `focus_key = <KEY>`; zero → Fallback D; ≥2 → Fallback E).
  - **jira-export directory** — `jira_export_root` = the dir, `source = directory`, no `$VAULT_PATH`.
    This is what Fallback A already points users to.
  - **Optional focus Epic** (second positional JiraID) — binds to whichever root resolved: validate
    `<root>/<Epic>/<Epic>.md` → `focus_key = <Epic>`; missing → Fallback D.

  | Input | Root | `$VAULT_PATH`? | `focus_key` |
  |---|---|---|---|
  | `<VI-Key>` | `jira-products/<VI-Key>` | required | null |
  | `<Epic-Key>` | parent VI (auto-resolved) | required | the Epic |
  | `<VI-Key> <Epic-Key>` | `jira-products/<VI-Key>` | required | the Epic |
  | `<dir>` | `<dir>` | not needed | null |
  | `<dir> <Epic-Key>` | `<dir>` | not needed | the Epic |

  Directory tokens stay **content-classified** (jira-export vs spec-folder), so `<dir> <Epic-Key>` never
  collides with the existing `<VI-Key> @spec-folder` form (a spec-folder feeds `specs`, not the root).
  ```

- [ ] **Step 2: Add `focus_key` to the Output contract.**
  In the `## Output contract` fenced block, add one line (leave every existing line unchanged):
  ```
  focus_key:        <EPIC key> | null    # Epic to center on within jira_export_root; null for a bare VI/stand-alone/dir
  ```

- [ ] **Step 3: Add Fallbacks D and E.**
  Under `## Fallback prompts (orchestrator-owned)`, append:
  ```markdown
  - **D — Epic key given but not found** (single-key: no parent VI contains it; two-key/dir:
    `<root>/<Epic>/` missing): `choices: ["Re-enter the Epic key", "Pass <VI> <Epic> explicitly", "Cancel"]`
  - **E — nested Epic key found under multiple VIs:** list the candidate VIs;
    `choices: ["<first> (Recommended)", "<other VIs…>", "Cancel"]`
  ```

- [ ] **Step 4: Add the progress-aware Epic-picker pattern subsection.**
  Add a new top-level section documenting the reusable pattern (design §5); each command supplies its own done-predicate:
  ```markdown
  ## Progress-aware Epic picker (opt-in per command)

  For an **Epic-unit** command given a top-level key with `focus_key = null`, first determine the item's
  type from a cheap `jira-reader depth: vi-plus-epics` read, then:

  - **The item is itself an Epic** (stand-alone/top-level) → no picker; proceed for it directly.
  - **VI with exactly 1 Epic** → no picker; auto-proceed for that Epic.
  - **VI with ≥2 Epics** → render a status-aware picker. Status comes from the command's own output
    artifact (its **done-predicate**), one row per Epic:
    - **○ not started** — no artifact → selectable.
    - **◐ in progress** — a resume file exists but no final artifact → selectable as resume.
    - **● done** — artifact exists → shown greyed, not default-selectable; selecting offers revise.
    Default cursor = first actionable (in-progress before not-started). Include an explicit
    "Author one broad VI-level artifact instead" choice. After finishing one, offer
    "Next Epic? [picker] / Stop here". Resume stacks across sessions (VI picker + the command's own
    per-item resume file).
  - **VI with 0 Epics** → the command's no-Epics policy (e.g. split with `/epics` first, or a broad
    VI-level artifact).

  This pattern is **policy-neutral in the resolver** — it is invoked by Epic-unit commands only; VI-level
  commands (`/epics`, `/document`, `/release-notes`) never use it and must keep working for un-split VIs.
  ```

- [ ] **Step 5: Verify — additive + anchors present.**
  Run:
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
  grep -c "focus_key" references/jira-input-resolution.md            # expect >=2
  grep -q "VI selector + optional focus Epic" references/jira-input-resolution.md && echo OK-grammar
  grep -q "Fallback D\|— Epic key given but not found" references/jira-input-resolution.md && echo OK-D
  grep -q "found under multiple VIs" references/jira-input-resolution.md && echo OK-E
  grep -q "Progress-aware Epic picker" references/jira-input-resolution.md && echo OK-picker
  grep -q "done-predicate" references/jira-input-resolution.md && echo OK-predicate
  # Additive guard — existing single-key anchors still present:
  grep -q "jira-driven — JiraID token" references/jira-input-resolution.md && echo OK-jiraid-intact
  grep -q "jira-driven — directory token" references/jira-input-resolution.md && echo OK-dir-intact
  ```
  Expected: `OK-*` for each and the count `>= 2`. Byte-diff review confirms only additions (no edits to existing single-key prose or existing Output-contract lines).

- [ ] **Step 6: Commit.**
  ```bash
  git add references/jira-input-resolution.md
  git commit -m "$(printf 'feat(jira-input): add VI-selector two-key grammar + focus_key + Epic-picker pattern\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

## Task 2: `/specify` Phase 0 — input resolution + per-Epic output path

**Files:**
- Modify: `commands/specify.md` (Phase 0 steps 1–3; the cwd-agnostic line; Phase 1 display line)

**Interfaces:**
- Consumes: `focus_key`, `jira_key`, `jira_export_root`, `source` from Task 1's contract.
- Produces: the resolved **feature folder** convention (per-Epic / VI-level / stand-alone-top-level-Epic) consumed by Task 3's picker and by Phases 5–7.

- [ ] **Step 1: Rewrite Phase 0 step 1 to consume `focus_key`.**
  Replace the "Carry `jira_key` and `jira_export_root` forward. Downstream, `<KEY>` denotes this `jira_key`." wording with text that carries **`jira_key` (the resolved top-level key — the VI when a focus Epic is present), `jira_export_root`, `source`, and `focus_key`**. Note the front-end now owns Fallbacks A/B **and D/E** and the VI-selector (key-or-directory) + focus-Epic grammar. Define: `<VI>` = `jira_key`; `<EPIC>` = `focus_key` (may be null).

- [ ] **Step 2: Rewrite Phase 0 steps 2–3 for the per-Epic output layout.**
  Replace the `$SPECS_PATH/specifications/<KEY>_<slug>/` (underscore, VI-colliding) target with this resolution (design §7), keeping the `$SPECS_PATH`-unset hard stop:
  - Resolve/derive the **VI dir**: `specifications/<VI>-<vslug>/` where `<vslug>` = kebab of the VI title; **honor an existing dir matched by key-number** (a human may have set the slug), else create `<VI>-<vslug>`.
  - **Feature folder** by case:
    - `focus_key` set (Epic under a VI) → `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` (`<eslug>` = kebab of the Epic title).
    - `focus_key` null **and** the item is a **VI**, broad-VI-spec chosen → `specifications/<VI>-<vslug>/specification.md` (flat at VI level).
    - `focus_key` null **and** the item is a **stand-alone top-level Epic** (no parent VI) → `specifications/<EPIC>-<eslug>/` (top-level, keyed by the Epic).
  - All delimiters are hyphens; matching an existing dir tolerates a stray `-`/`_`.
  - Keep step 4 (prior-run `_session.md` detection) and the cwd-agnostic note, updating any `<KEY>_<slug>` reference to the new convention.

- [ ] **Step 3: Update the Phase 1 display line.**
  In Phase 1's "Also display" line, show the resolved **`jira_key` (VI)** and **`focus_key` (Epic, or 'none — VI-level')** alongside the existing values.

- [ ] **Step 4: Verify.**
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
  grep -q "focus_key" commands/specify.md && echo OK-focus
  grep -q "<VI>-<vslug>/<EPIC>-<eslug>" commands/specify.md && echo OK-perepic
  grep -q "honor an existing dir\|honor an existing folder" commands/specify.md && echo OK-honor
  # old buggy target gone:
  ! grep -q "specifications/<KEY>_<slug>" commands/specify.md && echo OK-old-removed
  ```
  Expected: `OK-focus`, `OK-perepic`, `OK-honor`, `OK-old-removed`. Byte-diff review.

- [ ] **Step 5: Commit.**
  ```bash
  git add commands/specify.md
  git commit -m "$(printf 'fix(specify): resolve nested Epics + write per-Epic hyphen path (Phase 0)\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

## Task 3: `/specify` — picker + type-detection + Epic-scoped read + branch name

**Files:**
- Modify: `commands/specify.md` (Phase 2, Phase 2.5, Phase 7)

**Interfaces:**
- Consumes: `focus_key` and the feature-folder convention from Task 2; the picker pattern from Task 1.

- [ ] **Step 1: Restructure so type-detection/picker runs BEFORE the full read.**
  Today Phase 2 does the expensive `depth: full` read, then Phase 2.5 checks granularity. Flip this so a null `focus_key` is resolved cheaply first. Rewrite Phase 2.5 → **Phase 2 (granularity + picker)** running when `focus_key` is null: dispatch `jira-reader depth: vi-plus-epics` (cheap) to determine the item's type and enumerate child Epics, then branch per the design §5 / the shared picker pattern:
  - **stand-alone top-level Epic** → set `focus_key` = the item; proceed.
  - **VI, 1 Epic** → set `focus_key` = that Epic; one-line notice; proceed.
  - **VI, ≥2 Epics** → render the **progress-aware picker**. Done-predicate = `specification.md` exists in that Epic's feature folder (`specifications/<VI>-<vslug>/<EPIC>-<eslug>/specification.md`); in-progress = a `_session.md` there without `specification.md`. States ○ / ◐ / ● (done greyed, not default-selectable → revise). Include "Author one broad VI-level spec instead". On selection, set `focus_key`. After Phase 7 for one Epic, offer "Next Epic? / Stop here" (re-render the picker minus the completed one).
  - **VI, 0 Epics** → the existing without-Epics choices (split with `/epics` + round-trip, or broad VI-level spec).
  When `focus_key` is already set on entry (any two-token form or `<Epic-Key>`), skip the picker entirely.

- [ ] **Step 2: Make the full read Epic-scoped.**
  Keep the `depth: full` dispatch (now after granularity is settled). Add: **when `focus_key` is set, scope the returned hierarchy to `focus_key`'s subtree** (the Epic + its linked Stories/Sub-tasks) before feeding Phase 5 — `jira-reader` returns the linked-item hierarchy, so filter in-orchestrator. `jira-reader` itself is unchanged. When `focus_key` is null (broad VI-level spec), use the whole VI subtree as today.

- [ ] **Step 3: Update the Phase 7 branch name.**
  Replace `spec/<KEY>_<slug>` with `spec/<EPIC>-<eslug>` for a per-Epic (or stand-alone-Epic) spec, and `spec/<VI>-<vslug>` for a VI-level spec (hyphen; Epic keys are globally unique). Commit ONLY the feature folder; PR to protected `main` as before.

- [ ] **Step 4: Verify.**
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
  grep -q "vi-plus-epics" commands/specify.md && echo OK-cheap-enum
  grep -q "Next Epic" commands/specify.md && echo OK-next
  grep -Eq "○|not started" commands/specify.md && grep -Eq "◐|in progress" commands/specify.md && grep -Eq "●|done" commands/specify.md && echo OK-states
  grep -q "scope the returned hierarchy\|scope .* to .*focus_key\|focus_key.* subtree" commands/specify.md && echo OK-scope
  grep -q "spec/<EPIC>-<eslug>" commands/specify.md && echo OK-branch
  ! grep -q "spec/<KEY>_<slug>" commands/specify.md && echo OK-oldbranch-removed
  ```
  Expected: all `OK-*`. Confirm Phase 2's `depth: full` dispatch still present (`grep -q "depth: full" commands/specify.md`). Byte-diff review.

- [ ] **Step 5: Commit.**
  ```bash
  git add commands/specify.md
  git commit -m "$(printf 'feat(specify): progress-aware Epic picker + Epic-scoped read + per-Epic branch\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

## Task 4: Version bump (v2.5.0) + CHANGELOG + READMEs

**Files:**
- Modify: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`, `README.md`, `plugins/dev-workflows/README.md` (repo-root vs plugin READMEs — update whichever documents `/specify`'s input).

- [ ] **Step 1: Bump versions (lock-step).**
  Set `version` in `plugin.json` and `plugins[0].version` in `marketplace.json` to `2.5.0`. Do NOT touch the marketplace top-level version or the sibling plugins.

- [ ] **Step 2: Prepend the CHANGELOG entry.**
  Add a `## [2.5.0] - 2026-07-08` section above `[2.4.0]`, preserving all prior entries. Summarize: VI-selector two-key grammar (`<VI> <Epic>`, `<dir> <Epic>`, nested-Epic auto-resolve) + `focus_key` in the shared front-end; `/specify` fixes (resolves nested Epics; per-Epic hyphen output path replacing the VI-colliding `<KEY>_<slug>`) + progress-aware Epic picker. Note it's additive (other Jira-driven commands unchanged).

- [ ] **Step 3: Touch the READMEs if they document `/specify`'s input.**
  If a README shows `/specify`'s usage/input, update it to mention `<VI> <Epic>` / `<dir> <Epic>` and the Epic picker. If neither README documents `/specify` input beyond the command name, leave them (record "no README input change needed" in the report). Do NOT change command/agent counts (none added).

- [ ] **Step 4: Verify.**
  ```bash
  cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
  python3 -c "import json; json.load(open('.claude-plugin/plugin.json')); print('plugin.json OK')"
  python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); print('marketplace OK', d['plugins'][0]['version'])"
  grep -q '"version": "2.5.0"' .claude-plugin/plugin.json && echo OK-plugin-ver
  python3 -c "import json; assert json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version']=='2.5.0'; print('OK-mkt-ver')"
  grep -q "\[2.5.0\]" CHANGELOG.md && grep -q "\[2.4.0\]" CHANGELOG.md && echo OK-changelog-history
  ```
  Expected: both JSON files load; `OK-plugin-ver`, `OK-mkt-ver`, `OK-changelog-history`.

- [ ] **Step 5: Commit.**
  ```bash
  git add .claude-plugin/plugin.json .claude-plugin/marketplace.json CHANGELOG.md README.md plugins/dev-workflows/README.md
  git commit -m "$(printf 'chore(release): dev-workflows v2.5.0 (two-key grammar + Epic picker)\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

## Self-review

- **Spec coverage:** design §3 grammar → Task 1 Steps 1–3; §3 `focus_key` → Task 1 Step 2 + Task 2 Step 1; §4 policy-neutral / VI-level exemption → Task 1 Step 4 note; §5 picker → Task 1 Step 4 + Task 3 Step 1; §6 no-jira-reader-change scoping → Task 3 Step 2; §7 output layout (incl. stand-alone-top-level-Epic) → Task 2 Step 2; §8 branch name → Task 3 Step 3; §9 additive/backward-compat → Task 1 Step 5 additive guard + Global Constraints; §10 verification → each Task's verify step; §11 version → Task 4.
- **Placeholder scan:** none — every step names exact files, content blocks, and commands.
- **Consistency:** `<VI>`/`<vslug>`/`<EPIC>`/`<eslug>` and hyphen delimiter used uniformly; `focus_key` defined in Task 1, consumed in 2–3; the "run picker before the full read" restructure is stated once (Task 3 Step 1) and the full read is confirmed still present (Task 3 Step 4).
- **Scope:** single subsystem (the shared front-end + `/specify`); other commands explicitly out (Global Constraints + tracked follow-up).

## Execution handoff

Plan complete. Recommended: **Subagent-Driven Development** — fresh implementer per task + task review, with model scaled to each task (Tasks 1–3 are prose transcription/placement from provided blocks → a cheaper tier; Task 4 is mechanical). Structural verification replaces a test suite; the whole-branch review runs on the most capable model. Base branch: `main`; feature branch `ivgu/NOISSUE-two-key-grammar-foundation`.

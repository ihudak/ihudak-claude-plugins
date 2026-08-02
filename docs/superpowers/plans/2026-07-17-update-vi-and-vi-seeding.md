---
tags:
  - tasks-exclude
---
# VI update (`/update-vi`), cross-VI seeding (`/create-vi --from-vi`), and a self-contradiction check — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/update-vi` command, `/create-vi --from-vi` seeding, a `vi-reviewer` self-contradiction dimension, a Jira-import-first VI-resolution rule, and standardize the VI filename to `<KEY>_<slug>.md` — all in the `dev-workflows` plugin.

**Architecture:** This plugin is authored in **markdown command/agent/reference files + JSON manifests** — there is no compiled code and no unit-test harness. Each task's deliverable is an edited or new markdown/JSON file; "tests" are deterministic **`grep` / `python3 -c 'json.load'` / count-consistency** assertions run from the plugin repo root. Changes are additive and follow the plugin's existing command conventions (mirroring `/create-vi`).

**Tech Stack:** Markdown (Claude Code slash-command + agent + reference files), JSON manifests (`plugin.json`, `marketplace.json`), `grep`/`bash`/`python3` for verification.

## Global Constraints

- **Repo root (all paths below are relative to it):** `/home/ivan.gudak/.claude/plugins/marketplaces/mgd-plugins` — the git-backed marketplace checkout (`origin = Dynatrace-Internal/mgd-claude-plugins`). The plugin lives at `plugins/dev-workflows/`.
- **Plugin altitude — product-level:** `/create-vi` and `/update-vi` mount **no repos** and run **no code scan**. Never add code-grounding to them.
- **Command conventions (mirror `/create-vi`):** every `choices:` array's **last** entry is `"Other… (describe)"`; a `## Phase 1.5 — Classify + model routing` block invoking `dev-workflows:model-routing`; terminal `impl-maintenance` + `emit-auto` (feedback) + `emit-cost` phases; git is **offered, never automatic**.
- **Git discipline:** `main` is protected — never commit to it directly; branch first, commit **only** the intended files (never `git add -A`), open a PR. Commit trailer on every commit: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Canonical VI filename:** `<KEY>_<slug>.md` (where `<slug>` = the `<KEY>-<slug>/` feature-folder slug). VI **detection** is frontmatter-based: glob `<KEY>_*.md` and confirm `issue_type: ValueIncrement` (robust to slug drift).
- **Jira-import-first:** the authoritative VI text is the re-imported `$VAULT_PATH/jira-products/<KEY>` tree, not the frozen `$SPECS_PATH` draft. Freshness threshold: **3 days** (import mtime older → offer re-import).
- **Version bump:** minor, `2.33.0` → `2.34.0`, in **both** `plugins/dev-workflows/.claude-plugin/plugin.json` and the marketplace-root `.claude-plugin/marketplace.json`.
- **Design source of truth:** `plugins/dev-workflows/docs/specs/2026-07-17-update-vi-and-vi-seeding-design.md`.

---

## File Structure

| File | Responsibility | Task |
|------|----------------|------|
| `commands/update-vi.md` | **New** — the `/update-vi` workflow | 7 |
| `references/vi-source-resolution.md` | **New** — Jira-import-first + 3-day freshness rule (shared by `/update-vi` and `/create-vi --from-vi`) | 5 |
| `agents/vi-reviewer.md` | **Modify** — add the non-contradiction dimension; filename wording | 1, 2 |
| `references/vi-format.md` | **Modify** — internal-consistency quality rule; `seeded_from_vi` frontmatter; filename wording | 1, 3 |
| `references/pre-lint.md` | **Modify** — VI-block filename wording | 1 |
| `references/ard-format.md` | **Modify** — `derived_from` VI-pointer filename | 1 |
| `commands/create-vi.md` | **Modify** — filename + frontmatter detection (1); grill nudge (4); `--from-vi` + `seeded_from_vi` + grammar/redirect (6) | 1, 4, 6 |
| `commands/create-ard.md` | **Modify** — Phase 2 VI read → glob + frontmatter | 1 |
| `README.md` | **Modify** — `/update-vi` row; `--from-vi` on create-vi row; PM role row; filename wording | 8 |
| `.claude-plugin/plugin.json` | **Modify** — version, command count, `/update-vi`, keywords | 8 |
| `.claude-plugin/marketplace.json` (repo root) | **Modify** — version, command count, `/update-vi` | 8 |
| `CHANGELOG.md` | **Modify** — one new entry (history not rewritten) | 8 |

---

## Task 1: Canonical VI filename standardization + frontmatter-based detection

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md` (lines 30, 41, 96, 121, 142, 155, 166)
- Modify: `plugins/dev-workflows/commands/create-ard.md` (line 62)
- Modify: `plugins/dev-workflows/agents/vi-reviewer.md` (lines 3, 9, 17)
- Modify: `plugins/dev-workflows/references/vi-format.md` (line 3)
- Modify: `plugins/dev-workflows/references/pre-lint.md` (line 25)
- Modify: `plugins/dev-workflows/references/ard-format.md` (line 28)

**Interfaces:**
- Produces: the canonical VI filename token `<KEY>_<slug>.md` (used by Tasks 6, 7) and the detection idiom "glob `<KEY>_*.md`, confirm `issue_type: ValueIncrement`" (used by Tasks 6, 7).

- [ ] **Step 1: Baseline — confirm the old references exist**

Run (from repo root):
```bash
cd /home/ivan.gudak/.claude/plugins/marketplaces/mgd-plugins
grep -rn "ValueIncrement\.md" plugins/dev-workflows --include="*.md" | grep -v "/docs/" | grep -v CHANGELOG.md
```
Expected: 14 hits across `create-vi.md` (7), `create-ard.md` (1), `vi-reviewer.md` (3), `vi-format.md` (1), `pre-lint.md` (1), `ard-format.md` (1).

- [ ] **Step 2: Rewrite the purely-descriptive/authoring references (`<KEY>` form)**

In `references/vi-format.md` line 3, `references/pre-lint.md` line 25, and `agents/vi-reviewer.md` lines 3/9/17, replace every `<KEY>_ValueIncrement.md` with `<KEY>_<slug>.md`. Exact edits:

`references/vi-format.md`:
```
old: The canonical structure and per-section rules for a `<KEY>_ValueIncrement.md`. `/create-vi` authors
new: The canonical structure and per-section rules for a `<KEY>_<slug>.md` VI file (frontmatter `issue_type: ValueIncrement`). `/create-vi` authors
```

`references/pre-lint.md`:
```
old: ## VI — `<KEY>_ValueIncrement.md` (`/create-vi`; format `vi-format.md`)
new: ## VI — `<KEY>_<slug>.md` (`/create-vi`; format `vi-format.md`)
```

`agents/vi-reviewer.md` (3 occurrences — use replace-all for the exact token):
```
old token: <KEY>_ValueIncrement.md
new token: <KEY>_<slug>.md
```

- [ ] **Step 3: Rewrite the `create-vi.md` write/describe references (`<KEY>` form)**

In `commands/create-vi.md`, replace `<KEY>_ValueIncrement.md` with `<KEY>_<slug>.md` at lines 96, 121, 142, 155, 166 (the authoring, style-check path, pre-lint, vi-reviewer VI path, and Phase-5 write). Use replace-all for the token `<KEY>_ValueIncrement.md` → `<KEY>_<slug>.md`. This also updates the detection lines 30 and 41 — which Step 4 then rewrites to be frontmatter-based, so the intermediate token there is temporary.

- [ ] **Step 4: Make prior-VI detection frontmatter-based in `create-vi.md`**

Replace `commands/create-vi.md` line 30 (Phase 0 step 6):
```
old: 6. **Prior VI.** If `<KEY>_<slug>.md` exists in the folder, Phase 1 offers refine-vs-fresh.
new: 6. **Prior VI (frontmatter-based).** Glob `<feature-folder>/<KEY>_*.md` and confirm frontmatter `issue_type: ValueIncrement` (tolerant of any slug). If a VI is found, this is an **existing VI** — `/create-vi` is greenfield-only, so **redirect** (see Phase 1) to `/update-vi <KEY>` unless `--from-vi` is present (Task 6).
```
Replace line 41 (Phase 1 step 2) heading text `only if a prior `<KEY>_<slug>.md` exists` with `only if a prior VI file (frontmatter `issue_type: ValueIncrement`) exists`.

- [ ] **Step 5: Make `create-ard.md` Phase 2 read the VI by glob + frontmatter**

Replace `commands/create-ard.md` line 62:
```
old: Read the VI from `$SPECS_PATH/specifications/<VI>-<vslug>/<VI>_ValueIncrement.md` when present (authored source); else dispatch `jira-reader` to read it from the export:
new: Read the VI from `$SPECS_PATH/specifications/<VI>-<vslug>/` — glob `<VI>_*.md` and use the file whose frontmatter is `issue_type: ValueIncrement` (canonical `<VI>_<slug>.md`) when present (authored source); else dispatch `jira-reader` to read it from the export:
```

- [ ] **Step 6: Update the ARD `derived_from` VI pointer**

Replace `references/ard-format.md` line 28:
```
old: derived_from: <path to <VI>_ValueIncrement.md>
new: derived_from: <path to the VI file, canonical <VI>_<slug>.md>
```

- [ ] **Step 7: Verify — no stale filename outside history**

Run:
```bash
grep -rn "ValueIncrement\.md" plugins/dev-workflows --include="*.md" | grep -v "/docs/" | grep -v CHANGELOG.md
```
Expected: **no output** (all descriptive/authoring/detect references now use `<KEY>_<slug>.md` or the glob idiom). Then confirm the detection idiom landed:
```bash
grep -rn "issue_type: ValueIncrement" plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/create-ard.md
```
Expected: at least one hit in each file.

- [ ] **Step 8: Commit**

```bash
git checkout -b vi/update-vi-and-seeding
git add plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/create-ard.md plugins/dev-workflows/agents/vi-reviewer.md plugins/dev-workflows/references/vi-format.md plugins/dev-workflows/references/pre-lint.md plugins/dev-workflows/references/ard-format.md
git commit -m "refactor(dev-workflows): standardize VI filename to <KEY>_<slug>.md + frontmatter-based detection

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `vi-reviewer` self-contradiction dimension (Scope A — reviewer side)

**Files:**
- Modify: `plugins/dev-workflows/agents/vi-reviewer.md` (Dimensions list, after the `Identifier integrity` bullet ~line 39; description frontmatter line 3)

**Interfaces:**
- Produces: a `vi-reviewer` dimension named "Internal consistency / non-contradiction" that both `/create-vi` and `/update-vi` rely on at their review gate.

- [ ] **Step 1: Baseline — confirm the dimension is absent**

Run:
```bash
grep -in "non-contradiction\|internal consistency" plugins/dev-workflows/agents/vi-reviewer.md
```
Expected: **no output**.

- [ ] **Step 2: Add the dimension**

In `agents/vi-reviewer.md`, insert this bullet into the `## Dimensions` list immediately after the `- **Identifier integrity:** …` line:
```markdown
- **Internal consistency / non-contradiction (MAJOR; BLOCKER for a hard Goal-vs-Scope contradiction):** the VI must not contradict itself. Flag an `[AC-N]` that delivers a `## Scope` **Out-of-scope** behaviour; a `## Goal` asserting a different scope than `## Scope`; two `[US-N]` in direct conflict; an `[SM-N]` contradicting scope. This is a product-level self-consistency check only — NOT a feasibility or code check. An unresolved contradiction the author chose to keep must appear under `## Assumptions & open questions`, not silently in a requirement.
```

- [ ] **Step 3: Reflect it in the reviewer description**

Replace in `agents/vi-reviewer.md` frontmatter `description:` the phrase `scope concreteness, measurable metrics,` with `scope concreteness, internal consistency (no self-contradiction), measurable metrics,`.

- [ ] **Step 4: Verify**

Run:
```bash
grep -in "Internal consistency / non-contradiction" plugins/dev-workflows/agents/vi-reviewer.md
grep -c "^- \*\*" plugins/dev-workflows/agents/vi-reviewer.md
```
Expected: the first grep returns 1 hit (the new dimension); the second shows the Dimensions list grew by one bullet.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/vi-reviewer.md
git commit -m "feat(dev-workflows): add non-contradiction dimension to vi-reviewer

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: `vi-format.md` — internal-consistency rule + `seeded_from_vi` field (Scope A + D — format side)

**Files:**
- Modify: `plugins/dev-workflows/references/vi-format.md` (Frontmatter block ~line 31; Quality rules ~line 72)

**Interfaces:**
- Consumes: the canonical filename from Task 1.
- Produces: the `seeded_from_vi` frontmatter field (authored by Task 6) and a documented internal-consistency rule (enforced by Task 2's reviewer, applied by Task 4's grill).

- [ ] **Step 1: Baseline**

Run:
```bash
grep -n "seeded_from_vi\|self-contradict\|internally consistent" plugins/dev-workflows/references/vi-format.md
```
Expected: **no output**.

- [ ] **Step 2: Add `seeded_from_vi` to the frontmatter block**

In `references/vi-format.md`, insert after the `derived_from: …` line (line 31):
```yaml
seeded_from_vi: <VI key or path when this VI was seeded from another VI via `/create-vi --from-vi`; omit otherwise>
```

- [ ] **Step 3: Add the internal-consistency quality rule**

In `references/vi-format.md`, add to the `## Quality rules` list (after the "No implementation detail" bullet):
```markdown
- **Internally consistent** — no requirement contradicts another or the scope: no `[AC-N]` delivering an Out-of-scope behaviour, no `## Goal` asserting a scope the `## Scope` section contradicts, no conflicting `[US-N]`. A deliberately-kept tension is recorded under `## Assumptions & open questions`, never left implicit in a requirement.
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -n "seeded_from_vi" plugins/dev-workflows/references/vi-format.md
grep -in "Internally consistent" plugins/dev-workflows/references/vi-format.md
```
Expected: one hit each.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/vi-format.md
git commit -m "feat(dev-workflows): vi-format internal-consistency rule + seeded_from_vi field

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: `/create-vi` grill self-contradiction nudge (Scope A — command side)

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md` (Phase 3, after the spine-walk paragraph ~line 107)

**Interfaces:**
- Consumes: the internal-consistency rule from Task 3; the reviewer dimension from Task 2.

- [ ] **Step 1: Baseline**

Run:
```bash
grep -in "contradict" plugins/dev-workflows/commands/create-vi.md
```
Expected: **no output**.

- [ ] **Step 2: Add the nudge to Phase 3**

In `commands/create-vi.md`, append this sentence to the end of the Phase 3 authoring paragraph (the paragraph ending "…Keep the VI **product-level** — no implementation detail."):
```markdown
 **Self-consistency check:** before writing each section, check it against the already-settled sections — a new `[AC-N]` must not deliver an Out-of-scope behaviour, the `## Goal` must not assert a scope the `## Scope` contradicts, and `[US-N]`s must not conflict. Resolve any contradiction inline with the user, or record it under `## Assumptions & open questions` — never leave it implicit (the Opus `vi-reviewer` flags a silently-baked contradiction).
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -in "Self-consistency check" plugins/dev-workflows/commands/create-vi.md
```
Expected: 1 hit.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/commands/create-vi.md
git commit -m "feat(dev-workflows): create-vi grill self-consistency nudge

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: New reference — `references/vi-source-resolution.md` (Jira-import-first + 3-day freshness)

**Files:**
- Create: `plugins/dev-workflows/references/vi-source-resolution.md`

**Interfaces:**
- Produces: a `Resolve an existing VI` procedure cited by `/create-vi --from-vi` (Task 6) and `/update-vi` (Task 7). Output for a given `<KEY>`: the authoritative VI markdown path/text + comments, or a stop-and-import escalation.

- [ ] **Step 1: Write the reference file (complete content)**

Create `plugins/dev-workflows/references/vi-source-resolution.md`:
````markdown
# Resolving an existing VI (Jira-import-first — shared reference)

The authoritative text of an **existing** Value Increment lives in **Jira**, not in the `$SPECS_PATH`
markdown. `/create-vi` writes the VI to `$SPECS_PATH` as the *initial* draft; once it is pasted into
Jira it is edited by people (and gains comments) there, while the specs draft stays frozen. Any workflow
that consumes an existing VI — `/update-vi` (its base) and `/create-vi --from-vi` (its seed) — MUST read
the re-imported Jira VI first.

This is an **adjacent** policy to `references/source-truth.md` (which governs code-vs-docs verification):
this file governs *which artifact holds the current VI text*, not code truth. Do not conflate them.

## Procedure — `resolve-existing-vi <KEY>`

1. **Validate** `<KEY>` against `^[A-Z][A-Z0-9_]*-\d+$`. Malformed → stop and report.
2. **Jira import first.** Look for `$VAULT_PATH/jira-products/<KEY>/**/<KEY>.md` and its sibling
   `<KEY>-comments.md`. Confirm the frontmatter is `issue_type: ValueIncrement`. This import (body +
   comments) is the **authoritative base**.
3. **Not imported →** STOP. Ask the user to import it, then re-run:
   `choices: ["Import <KEY> now with the workitem-importer, then I'll re-run (Recommended)", "Cancel", "Other… (describe)"]`.
   Cite the importer: `https://github.com/ivan-gudak/jira-workitem-import`. Never fall back to the frozen
   specs draft as the base.
4. **Imported but stale →** if the import file's mtime is older than **3 days**
   (`find "$VAULT_PATH/jira-products/<KEY>" -name "<KEY>.md" -mtime +3`), show the import date and offer:
   `choices: ["Re-import <KEY> now — I'll wait (Recommended)", "Proceed with the current import", "Cancel", "Other… (describe)"]`.
5. **Secondary grounding (read-only; never the base):** the frozen `$SPECS_PATH` specs draft (glob
   `<KEY>_*.md`, `issue_type: ValueIncrement`), any `*_ARD.md`, `specification.md`, and — for
   `/update-vi` — a user-supplied `@transcript` / notes path. These enrich the grill; they never override
   the Jira import.

Product-level only — this reads markdown/comments; it mounts no repos and runs no code scan.
````

- [ ] **Step 2: Verify the file exists and carries the required anchors**

Run:
```bash
test -f plugins/dev-workflows/references/vi-source-resolution.md && echo EXISTS
grep -c "resolve-existing-vi\|3 days\|Jira import first\|workitem-importer" plugins/dev-workflows/references/vi-source-resolution.md
```
Expected: `EXISTS`, and a count ≥ 4.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/vi-source-resolution.md
git commit -m "feat(dev-workflows): add vi-source-resolution reference (Jira-import-first, 3-day freshness)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: `/create-vi --from-vi` + `seeded_from_vi` + grammar/redirect (Scope D)

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md` (Phase 0 flag parse ~line 22; Phase 1 redirect ~line 41; Phase 2 seed read ~line 84; Phase 3 frontmatter list line 98; usage line 15)

**Interfaces:**
- Consumes: `resolve-existing-vi` (Task 5); `seeded_from_vi` field (Task 3); frontmatter detection (Task 1).

- [ ] **Step 1: Baseline**

Run:
```bash
grep -in "from-vi\|seeded_from_vi\|redirect" plugins/dev-workflows/commands/create-vi.md
```
Expected: **no output**.

- [ ] **Step 2: Update the usage line**

Replace `commands/create-vi.md` line 15:
```
old: Usage: `/create-vi <JIRA-KEY> [@idea.md] [--lean|--hybrid|--full]` (default `--hybrid`).
new: Usage: `/create-vi <JIRA-KEY> [@idea.md] [--from-vi <VI-KEY|path>] [--lean|--hybrid|--full]` (default `--hybrid`).
```

- [ ] **Step 3: Parse `--from-vi` and resolve the seed in Phase 0**

In `commands/create-vi.md` Phase 0, add a new numbered item after item 2 (Profile):
```markdown
2a. **`--from-vi <VI-KEY|path>` (optional seed).** When present, this run authors a **new** VI (the
    positional `<JIRA-KEY>`) seeded read-only by another VI. Resolve the seed via
    `${CLAUDE_PLUGIN_ROOT}/references/vi-source-resolution.md` (`resolve-existing-vi` — Jira-import-first,
    3-day freshness) for a key, or read the given path directly. The seed is **grounding, not content**
    (Phase 3 adapts it; it is never copied wholesale).
```

- [ ] **Step 4: Add the redirect + conflict handling in Phase 1**

In `commands/create-vi.md` Phase 1, replace item 2 (the refine-vs-fresh block) with:
```markdown
2. **Existing-VI handling** (only if Phase 0 step 6 found a VI for `<KEY>`):
   - **No `--from-vi`** → `/create-vi` is greenfield-only; **redirect**:
     ```
     choices: ["Switch to /update-vi <KEY> to refresh it (Recommended)", "Overwrite as a fresh VI (archives the current one)", "Cancel", "Other… (describe)"]
     ```
   - **`--from-vi` present** → "create new (seeded)" conflicts with "a VI already exists here":
     ```
     choices: ["Update the existing <KEY> instead — /update-vi <KEY> (seed ignored) (Recommended)", "Overwrite <KEY> as a new seeded VI (archive the current one)", "Cancel", "Other… (describe)"]
     ```
```

- [ ] **Step 5: Feed the seed into Phase 2 and record provenance in Phase 3**

In `commands/create-vi.md` Phase 2 (after the `idea.md` read paragraph), add:
```markdown
If `--from-vi` was resolved (Phase 0 step 2a), also read the **seed VI** (body + comments) as read-only
grounding — structure, personas, scope shape, and metrics to *adapt* (never copy) to the new VI.
```
In Phase 3, extend the Frontmatter spine item (line 98) to end with `, seeded_from_vi (when --from-vi was used)`:
```
old: 1. Frontmatter — incl. `release_versions` + `relevant_for_release_notes`, `sources` (propagated), `derived_from`, `jira_key`.
new: 1. Frontmatter — incl. `release_versions` + `relevant_for_release_notes`, `sources` (propagated), `derived_from`, `seeded_from_vi` (only when `--from-vi` was used), `jira_key`.
```

- [ ] **Step 6: Verify**

Run:
```bash
grep -in "from-vi" plugins/dev-workflows/commands/create-vi.md | head
grep -in "seeded_from_vi\|/update-vi <KEY>" plugins/dev-workflows/commands/create-vi.md
```
Expected: `--from-vi` appears in usage + Phase 0 + Phase 1; `seeded_from_vi` in Phase 3; the redirect to `/update-vi <KEY>` present.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/commands/create-vi.md
git commit -m "feat(dev-workflows): create-vi --from-vi seeding, seeded_from_vi, existing-VI redirect

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: New command — `/update-vi`

**Files:**
- Create: `plugins/dev-workflows/commands/update-vi.md`

**Interfaces:**
- Consumes: `resolve-existing-vi` (Task 5), `vi-format.md` (Task 3), `vi-reviewer` (Task 2), the canonical filename (Task 1).

- [ ] **Step 1: Write the command file (complete content)**

Create `plugins/dev-workflows/commands/update-vi.md`:
````markdown
---
name: update-vi
description: VI-update workflow (PM phase) — refresh/re-do an existing Value Increment. Resolves the VI Jira-import-first (source of truth) with a 3-day freshness gate, grounds on the VI + comments + any ARD/spec/transcript, updates it via a relentless grill against references/vi-format.md, gated by the Opus vi-reviewer, and writes canonical + archived revisions to $SPECS_PATH/specifications/<KEY>-<slug>/. Product-level (no code scan).
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch LS
---

Update the Value Increment for the Jira item: $ARGUMENTS

`/update-vi` refreshes an **existing** Value Increment (PM phase). It covers routine refreshes (new
information, scope tweaks, wording) and the rare obstacle-driven re-do (a human read an ARD/spec finding,
discussed it in Jira, and decided the VI must change). The VI is **product-level** — what / why /
for-whom, not how. Zero code scan; no repos.

Usage: `/update-vi <KEY> [@transcript-or-notes ...]`.

---

## Phase 0 — Resolve inputs

1. **`KEY` (mandatory).** Parse the first non-flag token; validate `^[A-Z][A-Z0-9_]*-\d+$`. If absent or malformed, stop: `UPDATE_VI_NEEDS_KEY: /update-vi needs the VI's Jira key — '/update-vi <KEY>'.`
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Feature folder.** `<SPECS_PATH>/specifications/<KEY>-<slug>/` — honor an existing dir matched by key-number (tolerate a stray `-`/`_` and a human-adjusted slug).
4. **Resolve the base VI — Jira-import-first.** Execute `${CLAUDE_PLUGIN_ROOT}/references/vi-source-resolution.md` (`resolve-existing-vi <KEY>`): the re-imported `$VAULT_PATH/jira-products/<KEY>` VI (body + `-comments.md`) is the **authoritative base**; not imported → stop and ask to import; stale (>3 days) → offer re-import.
5. **Secondary grounding (read-only).** Discover in the feature folder: the frozen specs draft (glob `<KEY>_*.md`, `issue_type: ValueIncrement`), any `*_ARD.md`, `specification.md`; plus any `@transcript` / notes path(s) passed in `$ARGUMENTS`.

`/update-vi` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

---

## Phase 1 — Configure

Use `choices` arrays; the last choice is always `"Other… (describe)"`.

1. **Confirm** the feature folder; the resolved Jira-import base **with its import date**; and the secondary artifacts discovered (specs draft / ARD / spec / transcript).
2. **Scope of the update.** `choices: ["Refresh (incorporate new info / comments / transcript) (Recommended)", "Re-do (substantive re-scope driven by an ARD/spec obstacle)", "Cancel", "Other… (describe)"]`.

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record the `model_routing` block exactly as `/create-vi` does (`classification`, `reason`, `current_model`, `detection_model` §2.1 Sonnet chain, `review_model` §2 Opus chain for `vi-reviewer` (frontmatter-pinned), `authoring_model` = current_model, `opus_available`, `notes`). The grill + authoring run inline on `current_model`; if no Opus resolves, degrade to best-available + record in `notes`.

---

## Phase 2 — Read the base + grounding

Read the Jira-import VI **body + `-comments.md`** (the authoritative base and the signal for *what to change*), then the secondary artifacts (specs draft, ARD, spec, transcript). Do NOT treat the frozen specs draft as authoritative where it disagrees with the Jira import — the import wins; surface a notable divergence to the user.

---

## Phase 3 — Update via grill

**Interview technique (grilling — embedded).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split, dependency order.

Update the VI live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md`, **diffing against the base** rather than authoring from blank: surface what changed and why (drawing on comments / ARD / spec / transcript), resolve open questions, keep the VI product-level. Apply the **self-consistency check** — no `[AC-N]` delivering an Out-of-scope behaviour, no `## Goal` vs `## Scope` contradiction, no conflicting `[US-N]`; record a deliberately-kept tension under `## Assumptions & open questions`. Preserve the frontmatter provenance fields (`sources`, `derived_from`, `seeded_from_vi` if present).

---

## Phase 3.5 — Dynatrace style check

Run the corporate style check on the updated VI **before** the review gate (quality enhancement, never a gate) — mirror `/create-vi` Phase 3.5 (Agent `dt-style-guide:dt-style-checker`, `doc_type: vi`, `detection_model`); apply MAJOR fixes inline and re-run once; skip gracefully if the agent is unavailable.

---

## Phase 3.6 — Structural pre-lint

Run the deterministic checks in `${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` (Universal + **VI** block) against the updated file; inline-fix mechanical findings; leave content gaps for the grill. Advisory — never blocks; `vi-reviewer` remains the gate.

---

## Phase 4 — Review gate

Dispatch `vi-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:vi-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the Value Increment:
  >
  > VI path: [absolute path to the updated <KEY>_<slug>.md]
  > Profile: [lean | hybrid | full — infer from the sections present]"

Act on the verdict as `/create-vi` Phase 4 does: on `BLOCK`, fix the BLOCKER findings inline and re-review once; if still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. Cap: one fix cycle + one re-review.

---

## Phase 5 — Handoff (canonical + archive) + Jira round-trip

1. **Archive the current canonical VI** (if one exists) to `<feature-folder>/revisions/<KEY>_<slug>_<YYYYMMDD>.md` before overwrite (same-day second revision → suffix `-2`, `-3`, …).
2. **Write the refreshed VI** to the **canonical** path `<feature-folder>/<KEY>_<slug>.md`. Record `revision_of: <archived snapshot path>` and the Jira-import date the update was built from in the frontmatter.
3. **Offer git** (commit-when-asked — never automatic): `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git", "Cancel"]`. On the first choice, in `$SPECS_PATH`: branch `vi/<KEY>-<slug>-update`; commit **only** the feature folder (never `git add -A`); push; PR to `main`. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

### Jira round-trip (document to the user — they will otherwise miss it)

1. **Paste** the updated VI body (below the frontmatter) back into the Jira workitem `<KEY>`.
2. **Re-import** the VI to `$VAULT_PATH/jira-products/<KEY>` (via `https://github.com/ivan-gudak/jira-workitem-import`) so the downstream pipeline and the next `/update-vi` see the current text.

Without these steps the update silently diverges from Jira again.

---

## Phase 6 — Next steps

Offer (guidance only — never auto-invoke), per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`:
```
choices: ["Re-draft the release note — /release-notes <KEY> (PM)", "Re-run architecture — /create-ard <KEY> (PA, if one exists)", "Re-run the spec — /specify <KEY> (PE, if one exists)", "Stop here", "Other… (describe)"]
```

### Context hygiene

Write/overwrite the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then: continuing as PM → `/compact`; handing to PA/PE → `/clear`. Guidance only.

---

## Phase 7 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 6, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin/skill/command/reference gap, `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment/user halt (missing key, unset `$SPECS_PATH`, not-imported, cancellation) or a work-quality review BLOCK.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/update-vi`; what was updated (which sections changed + why); key events (import/freshness friction, BLOCK reviews, unresolved clarifications — or 'none'); workarounds; the `vi-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call `emit-auto` (§6) with the report, `command: /update-vi`, the run's `jira_key`, `source`, and `plugin_version` (from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call `emit-cost` with `command: /update-vi`, `phase: vi-update`, `role: pm`, the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in Phase 5), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the canonical VI path + the archived snapshot path; which sections changed; the Jira-import date the update was built from; open-question count; the `vi-reviewer` verdict; the Dynatrace style-check outcome; the PR URL (if opened); the Jira round-trip reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; and the next-step recommendations.
````

- [ ] **Step 2: Verify structure**

Run:
```bash
test -f plugins/dev-workflows/commands/update-vi.md && echo EXISTS
grep -cE "^## Phase " plugins/dev-workflows/commands/update-vi.md
grep -c "vi-source-resolution.md\|vi-reviewer\|vi-format.md\|3-day\|canonical\|revisions/" plugins/dev-workflows/commands/update-vi.md
grep -n "name: update-vi" plugins/dev-workflows/commands/update-vi.md
```
Expected: `EXISTS`; **11** `## Phase` headings (0, 1, 1.5, 2, 3, 3.5, 3.6, 4, 5, 6, 7); the reference/agent/format citations present; the `name: update-vi` frontmatter line present.

- [ ] **Step 3: Confirm it mounts no repos (altitude guard)**

Run (checks for actual code-grounding *behaviour*, not the prose "no code scan"):
```bash
grep -in 'code-scanner\|batches of up to 4\|\$REPOS_PATH\|switch_to_default_branch' plugins/dev-workflows/commands/update-vi.md
```
Expected: **no output** (no code-grounding dispatch — the descriptive "no code scan / no repos" prose is fine and is not matched here).

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/commands/update-vi.md
git commit -m "feat(dev-workflows): add /update-vi command (Jira-import-first VI refresh)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Manifests, README, CHANGELOG, version bump

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (repo root)
- Modify: `plugins/dev-workflows/README.md` (command table ~line 17; PM role row ~line 85)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend a new entry)

**Interfaces:**
- Consumes: the `/update-vi` command file (Task 7) and `--from-vi` (Task 6) — this task documents them.

- [ ] **Step 1: Baseline — count command files and confirm current wording**

Run:
```bash
ls plugins/dev-workflows/commands/*.md | wc -l
grep -c "Twenty slash commands" plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
```
Expected: `21` command files (20 pre-existing + `update-vi`); each manifest has 1 "Twenty slash commands" hit.

- [ ] **Step 2: Update `plugin.json`**

In `plugins/dev-workflows/.claude-plugin/plugin.json`:
- `version`: `"2.33.0"` → `"2.34.0"`.
- In `description`: `"Twenty slash commands — /implement, …, /statusline, and /ready —"` → `"Twenty-one slash commands — /implement, …, /statusline, /ready, and /update-vi —"` (insert `/update-vi` into the enumerated list and change "Twenty" → "Twenty-one" and the trailing "and /ready" → "/ready, and /update-vi").
- `keywords`: add `"value-increment"` (and optionally `"update-vi"`).

- [ ] **Step 3: Update the marketplace manifest**

In `.claude-plugin/marketplace.json`, the `dev-workflows` entry: apply the **same** `version` bump to `"2.34.0"` and the **same** "Twenty" → "Twenty-one" + `/update-vi` description change as Step 2.

- [ ] **Step 4: Validate JSON**

Run:
```bash
python3 -c "import json;json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));json.load(open('.claude-plugin/marketplace.json'));print('JSON OK')"
grep -o "Twenty-one slash commands" plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
grep -c "/update-vi" plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
```
Expected: `JSON OK`; both manifests show "Twenty-one slash commands" and contain `/update-vi`.

- [ ] **Step 5: Add the `/update-vi` row + `--from-vi` to README**

In `plugins/dev-workflows/README.md`:
- On the `/create-vi` command-table row (line 17), change the signature cell `/create-vi <JIRA-KEY> [@idea.md] [--lean\|--hybrid\|--full]` to `/create-vi <JIRA-KEY> [@idea.md] [--from-vi <VI-KEY\|path>] [--lean\|--hybrid\|--full]`, and append to the description: `An existing-VI call is redirected to /update-vi; --from-vi <VI> seeds a new VI from a sibling (read-only, recorded in seeded_from_vi).`
- Insert a new command-table row immediately after the `/create-vi` row:
```markdown
| `/update-vi <KEY> [@transcript ...]` | VI update/refresh (PM phase). Refreshes an **existing** Value Increment — routine refresh or an obstacle-driven re-do. Resolves the VI **Jira-import-first** (`$VAULT_PATH/jira-products/<KEY>`, the source of truth; 3-day freshness gate — the frozen `$SPECS_PATH` draft is secondary), grounds on the VI + comments + any ARD/spec/`@transcript`, updates it via a relentless grill against `references/vi-format.md`, gated by the Opus `vi-reviewer`. Writes **canonical + archived** revisions to `$SPECS_PATH/specifications/<KEY>-<slug>/` (`<KEY>_<slug>.md` latest; prior snapshot under `revisions/`), branch+PR offer, and a documented paste-into-Jira + re-import round-trip. Product-level: no code scan, no repos. |
```
- Update the **PM role** row (line 85): change `/idea, /create-vi <KEY>, /release-notes <VI>` to `/idea, /create-vi <KEY>, /update-vi <KEY>, /release-notes <VI>`, and the `<KEY>_ValueIncrement.md` output token to `<KEY>_<slug>.md`.

- [ ] **Step 6: Prepend the CHANGELOG entry**

At the top of `plugins/dev-workflows/CHANGELOG.md` (below the title/header, above the newest existing entry), add:
```markdown
## 2.34.0

- **New `/update-vi` command (PM VI refresh).** Refreshes an existing Value Increment — routine refresh or an obstacle-driven re-do. Resolves the VI **Jira-import-first** (a new `references/vi-source-resolution.md`: the re-imported `$VAULT_PATH/jira-products/<KEY>` is the source of truth, 3-day freshness gate; the `$SPECS_PATH` draft is secondary), grounds on VI + comments + any ARD/spec/`@transcript`, updates via the grill against `references/vi-format.md`, gated by the Opus `vi-reviewer`, and writes **canonical + archived** revisions (`<KEY>_<slug>.md` latest; prior snapshot under `revisions/`). Product-level (no code scan).
- **`/create-vi --from-vi <VI-KEY|path>` seeding.** Author a new VI seeded read-only from a sibling VI (the techFit family pattern), recorded in a new `seeded_from_vi` frontmatter field; resolved Jira-import-first. A bare `/create-vi <existing-VI>` now redirects to `/update-vi`.
- **`vi-reviewer` non-contradiction dimension + `vi-format` internal-consistency rule + `/create-vi` grill self-consistency nudge** — flags a VI that contradicts itself (AC vs Out-of-scope, Goal vs Scope, conflicting US) at product altitude.
- **VI filename standardized to `<KEY>_<slug>.md`** (frontmatter-based detection: `issue_type: ValueIncrement`), replacing the documented `<KEY>_ValueIncrement.md` across `create-vi`, `create-ard`, `vi-reviewer`, `vi-format`, `pre-lint`, and `ard-format`.
```

- [ ] **Step 7: Verify consistency (command count ↔ description)**

Run:
```bash
python3 -c "import json;print(json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"
grep -c "update-vi" plugins/dev-workflows/README.md
grep -n "^## 2.34.0" plugins/dev-workflows/CHANGELOG.md
grep -rn "ValueIncrement\.md" plugins/dev-workflows --include="*.md" | grep -v "/docs/" | grep -v CHANGELOG.md
```
Expected: version `2.34.0`; README has ≥ 2 `update-vi` mentions (command row + PM role row); the CHANGELOG entry present; the last grep prints **nothing** (no stray old filename outside history/docs).

- [ ] **Step 8: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/README.md plugins/dev-workflows/CHANGELOG.md
git commit -m "docs(dev-workflows): document /update-vi + --from-vi; bump to 2.34.0

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Final verification (whole feature)

- [ ] **Run the full consistency sweep**

```bash
cd /home/ivan.gudak/.claude/plugins/marketplaces/mgd-plugins
# 1. No stale VI filename outside history/design docs:
grep -rn "ValueIncrement\.md" plugins/dev-workflows --include="*.md" | grep -v "/docs/" | grep -v CHANGELOG.md || echo "filename OK"
# 2. JSON valid + version aligned in both manifests:
python3 -c "import json;a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));m=json.load(open('.claude-plugin/marketplace.json'));dv=[p for p in m['plugins'] if p['name']=='dev-workflows'][0]['version'];assert a['version']==dv=='2.34.0',(a['version'],dv);print('versions OK', a['version'])"
# 3. New files present:
for f in plugins/dev-workflows/commands/update-vi.md plugins/dev-workflows/references/vi-source-resolution.md; do test -f "$f" && echo "present: $f"; done
# 4. Command count matches wording:
echo "command files: $(ls plugins/dev-workflows/commands/*.md | wc -l)"; grep -o "Twenty-one slash commands" plugins/dev-workflows/.claude-plugin/plugin.json
# 5. Cross-references resolve (cited references exist):
for r in vi-source-resolution vi-format pre-lint grilling-technique next-phase-offer feedback-emission cost-emission escalation-rules; do test -f "plugins/dev-workflows/references/$r.md" && echo "ref ok: $r"; done
```
Expected: `filename OK`; `versions OK 2.34.0`; both new files present; `21` command files + "Twenty-one slash commands"; every cited reference resolves.

---

## Self-Review notes (author)

- **Spec coverage:** A (`vi-reviewer` dim T2 + `vi-format` rule T3 + grill nudge T4); B — intentionally **not** built (design §7, out of scope); C (`/update-vi` T7 + Jira-import-first T5 + canonical/archive T7 §Phase 5); D (`--from-vi` + `seeded_from_vi` T6); Jira-import-first + 3-day (T5); filename standardization + ripple (T1); manifests/docs/version (T8). All design §5 files are covered.
- **§6.4 (reference placement) resolved:** standalone `references/vi-source-resolution.md` (Task 5) — reused by two commands.
- **No placeholders:** every edit shows exact old→new text or full file content; every verification is a runnable command with an expected result.

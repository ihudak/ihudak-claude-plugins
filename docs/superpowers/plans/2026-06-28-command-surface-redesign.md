---
tags:
  - tasks-exclude
---

# Command-Surface Redesign (Effort B1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the `/impl:*` commands to top-level verbs, fold `/impl:docs` into `/document` as a second mode, remove the `/impl` dispatcher, sweep every `/impl…` reference, update the context hook + `plugin.json`, add `references/escalation-rules.md`, and ship MAJOR `v2.0.0`.

**Architecture:** The command folder layout *is* the namespace, so renaming = `git mv` + `name:` frontmatter edits. `/document` becomes a Phase-0 mode-dispatcher (JiraID → the verbatim Jira pipeline; free-text/`@file` → the folded one-shot editor). A pervasive reference sweep + two functional-file rewrites (hook, plugin.json) complete the surface. The monotonic phase renumber is **split to Effort B1b** (not here).

**Tech Stack:** Markdown command/agent/reference files + one bash hook + JSON manifests in the `dev-workflows` plugin. **No test framework** — verification is structural (`grep`/`awk`/`bash -n`/`python3` JSON parse) plus a functional hook test.

## Global Constraints

- Repo: `/workspace/ihudak-claude-plugins`; plugin under `plugins/dev-workflows/`. Plugin `main` @ `9a50ada`, v1.16.0.
- Release is **MAJOR `v2.0.0`** (breaking: command names change; `/impl:docs` + `/impl` removed).
- **No test framework** — structural checks + a functional hook test are the verification.
- **Verb mapping** (apply everywhere): `/impl:code`→`/implement`; `/impl:jira:docs`→`/document`; `/impl:docs`→`/document` (folded, Mode B); `/impl:jira:epics`→`/epics`; `/impl:jira:release-notes`→`/release-notes`; `/impl:docs:profile`→`/docs-profile`; `/impl`→removed.
- **Use `git mv`** for renames (preserve history).
- **Preserve CHANGELOG history** — never rewrite `[1.x]` entries; only add `[2.0.0]`.
- **Robust completion gate:** `grep -rnE '/impl:|/impl\b' plugins/dev-workflows | grep -v '/implement' | grep -v 'CHANGELOG.md'` must be **empty** (the naive `[:/ ]` pattern is insufficient — do not use it).
- Stage **explicit paths**; never `git add -A`; never `.superpowers/`.
- Commit trailer on every commit: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- marketplace.json version is at `plugins[0].version`.
- **Out of scope:** the phase renumber (B1b); `/implement <JiraID>` discovery (B2); `/upgrade`, `/vuln`, the guideline reviewers.

---

### Task 1: Move command files to top-level verbs; remove the dispatcher

**Files:**
- `git mv` (5): `commands/impl/code.md`→`commands/implement.md`; `commands/impl/jira/docs.md`→`commands/document.md`; `commands/impl/jira/epics.md`→`commands/epics.md`; `commands/impl/jira/release-notes.md`→`commands/release-notes.md`; `commands/impl/docs/profile.md`→`commands/docs-profile.md`.
- Delete: `commands/impl.md`.
- Leave in place (folded in Task 2): `commands/impl/docs.md`.

**Interfaces:** Produces the five top-level command files with updated `name:`. `commands/impl/docs.md` still exists for Task 2.

- [ ] **Step 1: Move the five files + delete the dispatcher**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
git mv commands/impl/code.md commands/implement.md
git mv commands/impl/jira/docs.md commands/document.md
git mv commands/impl/jira/epics.md commands/epics.md
git mv commands/impl/jira/release-notes.md commands/release-notes.md
git mv commands/impl/docs/profile.md commands/docs-profile.md
git rm commands/impl.md
```

- [ ] **Step 2: Update each moved file's `name:` frontmatter**

Edit the `name:` line (line 2) in each:
- `commands/implement.md` → `name: implement`
- `commands/document.md` → `name: document`
- `commands/epics.md` → `name: epics`
- `commands/release-notes.md` → `name: release-notes`
- `commands/docs-profile.md` → `name: docs-profile`

(Do NOT touch `description:` or body `/impl…` refs yet — the sweep in Task 3 handles those. `commands/impl/docs.md` keeps `name: impl:docs` for now; Task 2 folds it.)

- [ ] **Step 3: Verify**

Run: `ls commands/*.md` → shows `implement.md document.md epics.md release-notes.md docs-profile.md` (+ any pre-existing top-level commands like `upgrade.md vuln.md guideline-reviewer.md api-guideline-reviewer.md`).
Run: `test ! -e commands/impl.md && echo "dispatcher gone"` → `dispatcher gone`.
Run: `grep -h '^name:' commands/implement.md commands/document.md commands/epics.md commands/release-notes.md commands/docs-profile.md` → the five new names.
Run: `ls commands/impl/docs.md` → still present (for Task 2).

- [ ] **Step 4: Commit**

```bash
# git mv + git rm (Step 1) already staged the renames + dispatcher deletion.
# Stage the name: edits on the 5 moved files (explicit paths — never -A):
git add commands/implement.md commands/document.md commands/epics.md commands/release-notes.md commands/docs-profile.md
git status --short   # expect: 5 renamed files (R, with content edits) + impl.md deletion (D); nothing else
git commit -m "PRODUCT v2.0.0: move /impl:* commands to top-level verbs; remove /impl dispatcher

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Fold `/impl:docs` into `/document` as Mode B

**Files:**
- Modify: `commands/document.md` (add Phase 0 mode-dispatch; wrap existing content as Mode A; append Mode B).
- Delete: `commands/impl/docs.md` (after relocating its flow) + the now-empty `commands/impl/` tree.

**Interfaces:** Consumes Task 1 (document.md exists). Produces the unified two-mode `/document`.

- [ ] **Step 1: Read both files** — `commands/document.md` (the moved Jira pipeline) and `commands/impl/docs.md` (the one-shot editor to fold in).

- [ ] **Step 2: Insert the Phase 0 mode-dispatch at the top of document.md**

Immediately after document.md's frontmatter + its opening `Implement…`/intro line, insert (before its current Phase 0):

````markdown
## Mode detection

`/document` has **two modes**, selected by the first argument token:

- **Jira mode** — the first token matches a JiraID (`^[A-Z][A-Z0-9]+-[0-9]+`), optionally followed by `saas` | `managed`. Run **Mode A** below. If the token is JiraID-shaped but no ticket folder exists under `$VAULT_PATH/jira-products/<KEY>`, ask: `choices: ["Re-enter the Jira key", "Treat the text as a direct edit instead", "Cancel"]`.
- **Direct mode** — anything else (a leading `@file` token, or free-text prose). Run **Mode B** below.

Echo the detected mode, then proceed to that mode's phases. The two modes share the same `docs-style-checker` / `doc-reviewer` / `doc-fixer` agents and the Phase 9 report shape.

---

# Mode A — Jira-driven documentation (JiraID argument)
````

Then ensure the *existing* document.md pipeline (its current `## Phase 0 …` through `## Phase 9 …`) follows under that `# Mode A` banner, **unchanged**. The dispatcher above is `## Mode detection` (not a numbered phase), so Mode A keeps its `Phase 0…9` and Mode B keeps its own phases with no "Phase 0" collision — each set is scoped under its `# Mode A` / `# Mode B` banner.

- [ ] **Step 3: Append Mode B (relocate the `/impl:docs` flow)**

After the end of Mode A (after its Phase 9), append:

````markdown
---

# Mode B — direct documentation edit (`@file` / free-text)

<!-- TASK 2 STEP 3: relocate the body of commands/impl/docs.md here -->
````

Relocate the **body** of `commands/impl/docs.md` (everything after its frontmatter — its intro + Phase 0 "Load the description" through its final report phase) into that placeholder, **verbatim except**:
- Drop its standalone frontmatter (Mode B lives inside document.md).
- Its phase headings become `## Mode B — Phase N — …` (or keep `## Phase N` under the `# Mode B` banner — choose one and be consistent) so they don't collide with Mode A's phase numbers.
- Leave its `/impl…` self-references intact for now — Task 3's sweep converts them (e.g. its "For net-new documentation … use /impl:jira:docs" line becomes "… use Jira mode (above)").

- [ ] **Step 4: Delete the folded file + empty dirs**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
git rm commands/impl/docs.md
# remove now-empty impl/ subtree (jira/, docs/ are empty after Task 1's moves)
find commands/impl -type d -empty -delete 2>/dev/null; rmdir commands/impl 2>/dev/null || true
```

- [ ] **Step 5: Verify**

Run: `grep -nE '^## Mode detection|^# Mode A —|^# Mode B —' commands/document.md` → 3 matches (dispatcher + both banners).
Run: `grep -c 'TASK 2 STEP 3' commands/document.md` → `0` (placeholder replaced).
Run: `test ! -e commands/impl/docs.md && test ! -d commands/impl && echo "folded + impl/ gone"` → `folded + impl/ gone`.
Run: `grep -nE 'docs-style-checker|doc-reviewer' commands/document.md | wc -l` → ≥2 (gates present, reachable by both modes).
Run: `awk 'BEGIN{c=0} /^```/{c++} END{print c}' commands/document.md` → even.

- [ ] **Step 6: Commit**

```bash
# Step 4's `git rm` already staged the impl/docs.md deletion. Stage the fold edits:
git add commands/document.md
git status --short   # expect: document.md modified (M) + impl/docs.md deleted (D); nothing else
git commit -m "PRODUCT v2.0.0: fold /impl:docs into /document as Mode B (direct edit)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Mechanical reference sweep (docs)

**Files:** Modify — all `agents/*.md`, all `references/*.md`, `README.md`, `skills/model-routing/SKILL.md`, and the command bodies (`commands/*.md`) — replacing every `/impl…` reference per the mapping. (The hook + `plugin.json` are Tasks 4–5; `§15` is Task 6; CHANGELOG history is preserved.)

**Interfaces:** Consumes Tasks 1–2 (files at new paths). Produces a doc-clean tree (the global gate runs in Task 7 after the hook + plugin.json are also done).

- [ ] **Step 1: Enumerate the sweep surface**

Run: `grep -rln '/impl' agents references README.md skills commands` → the file list to edit.

- [ ] **Step 2: Apply the mapping per file**

For each file, replace per the mapping (longest-match first to avoid partial hits): `/impl:jira:docs`→`/document`; `/impl:jira:epics`→`/epics`; `/impl:jira:release-notes`→`/release-notes`; `/impl:docs:profile`→`/docs-profile`; `/impl:code`→`/implement`; `/impl:docs`→`/document` (see context cases); bare `/impl`→reword (no dispatcher: "the /impl workflows"→"the dev-workflows commands"). Context-sensitive rewordings:
- `docs-style-checker.md` "files written by /impl:jira:docs Phase 6 (or /impl:docs Phase 3.5)" → "files written by `/document` (Jira mode, or direct mode)".
- `doc-fixer.md` "Shared between /impl:jira:docs and /impl:jira:epics" → "Shared between `/document` and `/epics`".
- `SKILL.md` description "Invoked by /impl:code, /vuln, /upgrade, /impl:jira:docs, and /impl:jira:epics" → "Invoked by `/implement`, `/vuln`, `/upgrade`, `/document` (Jira mode), and `/epics`".
- `document.md` inline "on-demand /impl:docs:profile" → "on-demand `/docs-profile`"; cross-links to `/impl:jira:epics` → `/epics`; the folded Mode-B "use /impl:jira:docs" → "use Jira mode (above)".
- `classification.md` `/impl:code`→`/implement`, `/impl:jira:docs`→`/document`, `/impl:jira:epics`→`/epics`, bare `/impl`→reword.

- [ ] **Step 3: Verify (sweep scope — doc files only)**

Run: `grep -rnE '/impl:|/impl\b' agents references README.md skills commands | grep -v '/implement'` → **empty** (all doc-file refs converted; `commands/` bodies included).
Run: `grep -rn '/document\|/implement\|/epics\|/release-notes\|/docs-profile' agents | head` → confirm the new verbs now appear where old ones were.

- [ ] **Step 4: Commit**

```bash
git add agents references README.md skills commands/document.md commands/implement.md commands/epics.md commands/release-notes.md commands/docs-profile.md
git status --short
git commit -m "PRODUCT v2.0.0: sweep /impl:* references to top-level verbs (docs/agents/refs/README)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Update the context hook (`preload-context.sh`)

**Files:** Modify `hooks/preload-context.sh` (header comment, regex, `case`, add a Jira-context helper).

**Interfaces:** Consumes the mapping. The only runtime-behavior change.

- [ ] **Step 1: Rewrite the header comment** (lines ~2–13) to describe the new surface: matches `/implement, /document, /epics, /release-notes, /vuln, /upgrade`; routing — `/implement, /vuln, /upgrade` → full; `/document` → Jira context **iff** the arg is a JiraID, else silent; `/epics, /release-notes` → Jira context; `/docs-profile` → not matched (no context).

- [ ] **Step 2: Replace the regex** (line ~37)

From:
```bash
if [[ ! "$prompt" =~ ^/(impl(:(code|docs|jira(:(docs|epics|release-notes))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-] ]]; then
```
To:
```bash
if [[ ! "$prompt" =~ ^/(implement|document|epics|release-notes|vuln|upgrade)[[:space:]]+[^[:space:]-] ]]; then
```

- [ ] **Step 3: Add a Jira-context helper** (beside the other `emit_*` helpers)

```bash
emit_jira_context() {
    echo "=== Auto-injected project context (Jira workflow) ==="
    if [[ -n "${VAULT_PATH:-}" ]]; then
        echo "VAULT_PATH: $VAULT_PATH"
    else
        echo "VAULT_PATH: (not set — the command will ask in Phase 1)"
    fi
    echo "repos_path: ${REPOS_PATH:-/workspace} (default — the command will confirm or ask)"
    emit_git_branch_if_repo
}
```

- [ ] **Step 4: Replace the `case`** (lines ~79–113)

```bash
case "$cmd" in
    implement|vuln|upgrade)
        # Full — code / security / upgrade benefit from full git context + model-routing.
        echo "=== Auto-injected project context ==="
        emit_model_routing
        emit_git_full
        emit_dir_listing_if_small
        ;;
    document)
        # Mode-aware: a JiraID argument → Jira context; free-text / @file → silent
        # (direct-edit mode owns its own git hygiene and never invokes Opus).
        if [[ "$prompt" =~ ^/document[[:space:]]+[A-Z][A-Z0-9]+-[0-9]+ ]]; then
            emit_jira_context
        fi
        ;;
    epics|release-notes)
        # Jira-driven, vault + repos context.
        emit_jira_context
        ;;
    *)
        # Unreachable given the regex; exit silently if the regex is ever widened.
        exit 0
        ;;
esac
```

- [ ] **Step 5: Verify (parse + functional test)**

Run: `bash -n hooks/preload-context.sh` → no syntax errors. (`shellcheck hooks/preload-context.sh` if available.)
Run the functional test — pipe sample prompts and assert routing:
```bash
h=hooks/preload-context.sh
echo '{"prompt":"/implement add a feature"}'    | bash "$h"   # expect: "Auto-injected project context" + "Model routing"
echo '{"prompt":"/document PRODUCT-14902 saas"}' | bash "$h"   # expect: "Jira workflow" + VAULT_PATH/repos_path
echo '{"prompt":"/document fix a typo on page X"}'| bash "$h"  # expect: NOTHING (silent)
echo '{"prompt":"/epics PRODUCT-100"}'           | bash "$h"   # expect: "Jira workflow"
echo '{"prompt":"/release-notes PRODUCT-7"}'     | bash "$h"   # expect: "Jira workflow"
echo '{"prompt":"/docs-profile"}'                | bash "$h"   # expect: NOTHING (unmatched: no trailing arg anyway)
echo '{"prompt":"/document"}'                    | bash "$h"   # expect: NOTHING (no arg)
```
Confirm each line's output matches its `# expect` comment.
Run: `grep -c 'impl' hooks/preload-context.sh` → `0` (no `impl` token remains, in regex/case/comments).

- [ ] **Step 6: Commit**

```bash
git add hooks/preload-context.sh
git commit -m "PRODUCT v2.0.0: context hook — match new verbs; /document mode-aware routing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Rewrite `plugin.json` description + keywords

**Files:** Modify `.claude-plugin/plugin.json` (`description`, `keywords`).

- [ ] **Step 1: Read** `.claude-plugin/plugin.json`.

- [ ] **Step 2: Rewrite `description`** — replace the command list + counts:
- Lead: **"Nine slash commands — `/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/api-guideline-reviewer`, and `/guideline-reviewer`"**.
- The "/impl:jira:docs Phase 0 preflight-discovers …" sentence → "`/document` (Jira mode) preflight-discovers the docs repo + profile (in-repo → built-in dynatrace-docs default → on-demand `/docs-profile`) …".
- Subagent count: **"Twenty-four reusable subagents"** and add `doc-writer`, `epic-writer` to the list (verify they aren't already there).
- Remove every `/impl…` token.

- [ ] **Step 3: Update `keywords`** — replace `"impl"` with `"implement"`; add `"document"`.

- [ ] **Step 4: Verify**

Run: `python3 -c "import json; d=json.load(open('.claude-plugin/plugin.json')); print('JSON OK'); assert 'impl:' not in d['description'] and '/impl' not in d['description']; assert 'Nine slash commands' in d['description']; assert 'doc-writer' in d['description'] and 'epic-writer' in d['description']; print('description OK')"` → `JSON OK` / `description OK`.
Run: `grep -c '"impl"' .claude-plugin/plugin.json` → `0`.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "PRODUCT v2.0.0: rewrite plugin.json description + keywords for the new command surface

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Extract `references/escalation-rules.md`; repoint `§15`

**Files:** Create `references/escalation-rules.md`; modify `commands/document.md`, `commands/epics.md`, `agents/jira-reader.md` (repoint `§15` / "Section 15" refs).

- [ ] **Step 1: Find the dangling refs**

Run: `grep -rn '§15\|Section 15' commands references agents` → the sites to repoint.

- [ ] **Step 2: Create `references/escalation-rules.md`**

Collect the canonical escalation `choices:` patterns these refs were meant to point to — they appear inline across the commands. Create the file with one section per scenario, each giving the trigger + the `choices:` array (copy the canonical arrays from the existing inline uses in `document.md`/`epics.md`):

```markdown
# Escalation rules (shared)

Canonical `choices:` arrays the `/impl:jira:*`-era "§15" references point to. Every decision point uses a `choices:` array whose **last** entry is `"Other… (describe)"`.

## Jira key dir not found
`choices: ["Re-enter key", "Cancel"]`

## Repo unresolved (zero matches)
`choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]`

## Repo missing (after resolution)
`choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]`

## Dirty working tree
`choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel", "Other… (describe)"]`

## Refresh blocked
`choices: ["Continue with current local state", "Skip this repo", "Cancel", "Other… (describe)"]`

## Review verdict BLOCK (unresolved after one fix cycle)
`choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in the report)", "Override and accept the finding", "Cancel the whole run"]`
```

(If a scenario's canonical array differs in the live command body, copy the live one verbatim — the command body is authoritative.)

- [ ] **Step 3: Repoint the refs** — replace each `§15` / "Section 15" reference with: `the <scenario> rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`` (name the matching scenario).

- [ ] **Step 4: Verify**

Run: `grep -rn '§15\|Section 15' commands references agents` → **empty**.
Run: `grep -c 'escalation-rules.md' commands/document.md commands/epics.md agents/jira-reader.md` → ≥1 each (where a §15 ref existed).
Run: `test -f references/escalation-rules.md && echo created`.

- [ ] **Step 5: Commit**

```bash
git add references/escalation-rules.md commands/document.md commands/epics.md agents/jira-reader.md
git commit -m "PRODUCT v2.0.0: add references/escalation-rules.md; resolve dangling §15 references

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Global gate + release v2.0.0

**Files:** Modify `.claude-plugin/plugin.json` (version), `.claude-plugin/marketplace.json` (repo root: `plugins[0].version` + any `/impl` in its dev-workflows entry), `plugins/dev-workflows/CHANGELOG.md`.

- [ ] **Step 1: Run the GLOBAL completion gate** (all prior tasks must be done)

Run: `grep -rnE '/impl:|/impl\b' plugins/dev-workflows | grep -v '/implement' | grep -v 'CHANGELOG.md'`
Expected: **empty**. If anything prints, fix that ref before releasing.
Run (repo root marketplace.json — outside the plugin dir, so not covered above): `grep -n '/impl\|impl:' .claude-plugin/marketplace.json` → if the dev-workflows entry's description mentions old command names, update them to the new verbs in this task.

- [ ] **Step 2: Bump versions** — `plugins/dev-workflows/.claude-plugin/plugin.json` top-level `"version"` `1.16.0`→`2.0.0`; `.claude-plugin/marketplace.json` `plugins[0].version` `1.16.0`→`2.0.0`.

- [ ] **Step 3: CHANGELOG `[2.0.0]` entry** (above `## [1.16.0]`, em-dash date):

```markdown
## [2.0.0] — 2026-06-28

### Changed (BREAKING)
- Renamed all `/impl:*` commands to top-level verbs: `/impl:code` → `/implement`; `/impl:jira:docs` → `/document`; `/impl:jira:epics` → `/epics`; `/impl:jira:release-notes` → `/release-notes`; `/impl:docs:profile` → `/docs-profile`.
- `/impl:docs` (one-shot doc editor) is **folded into `/document`** as direct mode — `/document <JiraID> [saas|managed]` runs the Jira pipeline; `/document @file` or `/document <free-text>` runs the one-shot edit. The standalone `/impl:docs` command is removed.
- The `/impl` dispatcher command is removed (no namespace left to dispatch).
- The context hook now matches the new verbs and routes `/document` by argument (JiraID → vault/repos context; free-text → silent).

### Added
- `references/escalation-rules.md` — the shared escalation `choices:` rules, resolving the previously-dangling "§15" references.
```

- [ ] **Step 4: Verify**

Run: `grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json; python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])"; grep -n '## \[2.0.0\]' plugins/dev-workflows/CHANGELOG.md` → both `2.0.0`; CHANGELOG heading present.
Run: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('JSON OK')"` → `JSON OK`.
Run the global gate again (Step 1) → still empty.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "PRODUCT dev-workflows v2.0.0: top-level command verbs; /document fold; /impl removed

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Notes for the executor

- Branch off `origin/main` (`9a50ada`): e.g. `ivgu/NOISSUE-command-surface-redesign`. Do not implement on `main`.
- Task order is dependency-driven: 1 (moves) → 2 (fold) before 3 (sweep, which edits the moved bodies); 4–6 independent of each other but after 1–2; 7 (global gate + release) last.
- The **global completion gate** (Task 7 Step 1) is the real safety net for the sweep — it must be empty across the whole plugin before release.
- The **hook functional test** (Task 4 Step 5) is mandatory — reading the regex is not enough.
- Phase renumber is **B1b** (not here); `/implement <JiraID>` discovery is **B2** (not here).
- The dynatrace-docs CLAUDE.md prettier/husky note does NOT apply to this plugin repo — N/A.

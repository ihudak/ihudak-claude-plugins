---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-07-01
---

# Jira-input front-end adoption for `/epics` + `/release-notes` (Effort B3) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire `/epics` and `/release-notes` onto the shared
`references/jira-input-resolution.md` front-end so all four Jira-driven commands
share one input grammar (JiraID | imported-Jira directory), enabling the
directory / undefined-`$VAULT_PATH` case and closing the literal `jira-products`
read-consumer class in these two commands.

**Architecture:** The front-end resolves **input only** (`jira_key`,
`jira_export_root`); each command keeps its **output** resolution command-local.
`$VAULT_PATH`-set behavior is **byte-unchanged**; the no-vault directory path is a
new additive branch. Mirrors the B2 `/document` adoption exactly.

**Tech Stack:** Markdown command/agent/reference files + a bash `UserPromptSubmit`
hook + JSON manifests. **No test framework** — verification is **structural**:
`grep` anchors, byte-unchanged diff inspection, `bash -n`, a functional hook
test, `python3 -c json.load`, and `git diff` review. Adapt the TDD rhythm to
**edit → verify → commit** (there is no failing-test-first step in this domain).

**Spec:** `spec/2026-07-01-jira-input-adoption-epics-release-notes-b3-design.md`

## Global Constraints

- Plugin repo: `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`. Plugin
  `main` at `39be608` (= origin/main, v2.1.0). Branch off it:
  `ivgu/NOISSUE-jira-input-adoption`.
- Release is **MINOR `v2.2.0`** — purely additive. Every existing JiraID +
  `$VAULT_PATH`-set invocation must still work **byte-for-byte**.
- Both commands are **jira-driven only**: they consume
  `{mode, source, jira_key, jira_export_root}`, ignore `specs`/`direct_prompt`/
  `direct_files`, and **reject** `mode: direct` with a clear error.
- **Output is always a file** — no print-only default (console-pasted markdown
  loses formatting in Jira). Projects/Products stays the **output** home,
  decoupled from input only.
- `/epics` becomes **cwd-agnostic** — the cwd-in-vault gate is dropped.
- `<VI-KEY>` = `<JIRA_KEY>` = the front-end's `jira_key` = the **input Value
  Increment key** (not a new-Epic key; drafted Epics are slug-named files).
- `jira-reader` is invoked with the **additive `jira_export_root` + `jira_key`**
  form (shipped in B2; `jira-reader` derives `EXPORT_ROOT` from it). Its legacy
  `vault_path` + `jira_key` form still works for any un-migrated caller — do
  **not** change `jira-reader` itself.
- `marketplace.json` version lives at **`plugins[0].version`** (NOT top-level).
  Siblings `dt-style-guide` `0.2.2` / `obsidian-llm-wiki` `0.3.1` stay untouched.
- Preserve all CHANGELOG history; new entry uses an **em-dash** (`—`).
- Zero external API calls added. `/epics` never branches/commits; `/release-notes`
  never commits.
- Commit trailer on every commit:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Never `git add -A`; never stage `.superpowers/` or `.docstack`. Stage only the
  files each task names. The plugin repo has **no** husky/prettier hook — commits
  run clean (no `--no-verify` needed).

**Out of scope (do not touch):** `jira-reader`'s reading logic; either command's
downstream pipeline (code-scan, `epic-writer`, `release-notes-writer`, review/
style gates) beyond input/output plumbing; the B4 follow-up-tasks capability;
resumable `/epics` drafting; the repo-root `README.md` staleness (line 9 still
lists pre-v2.0.0 `/impl:*` names — a pre-existing B1 miss, **flag but do not fix
here**).

## File structure

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/references/jira-input-resolution.md` | Generalize intro to 4 commands + add jira-driven-only clause | T1 |
| `plugins/dev-workflows/commands/epics.md` | Phase 0 front-end citation, drop cwd gate, output resolution, `jira-reader` re-root, literal-consumer + project-root rewire | T2 |
| `plugins/dev-workflows/commands/release-notes.md` | Phase 0 front-end citation, never-print-only output, gaps fallback, `jira-reader` re-root, literal-consumer rewire | T3 |
| `plugins/dev-workflows/hooks/preload-context.sh` | Comment refresh only (no functional change) | T4 |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/dev-workflows/README.md`, `plugins/dev-workflows/CHANGELOG.md` | Release v2.2.0 | T4 |

**Suggested models (subagent-driven):** T1 Opus (semantic keystone), T2 Opus
(multi-site semantic), T3 Opus (semantic), T4 Sonnet (mechanical).

---

### Task 1: Reference generalization + branch setup

**Files:**
- Modify: `plugins/dev-workflows/references/jira-input-resolution.md:1-8`

**Interfaces:**
- Produces: the reference now declares `/epics` and `/release-notes` as
  jira-driven-only adopters — T2/T3 cite this file.

- [ ] **Step 1: Create the branch**

```bash
cd /workspace/ihudak-claude-plugins
git switch main && git switch -c ivgu/NOISSUE-jira-input-adoption
git rev-parse --short HEAD   # expect 39be608
```

- [ ] **Step 2: Generalize the reference intro**

In `plugins/dev-workflows/references/jira-input-resolution.md`, replace the
intro paragraph (lines 3-8) — exact old text:

```
Shared input-resolution mechanics for `/implement` and `/document`. The command's
Phase 0 **cites this file and executes these steps inline** — the orchestrator
owns every prompt. Both commands parse `$ARGUMENTS` identically and consume the
normalized output contract (§ Output contract); each then layers its own
downstream work. `/epics` and `/release-notes` do **not** use this yet (the
reference is written to be adoptable by them later).
```

with:

```
Shared input-resolution mechanics for the Jira-driven commands `/implement`,
`/document`, `/epics`, and `/release-notes`. The command's Phase 0 **cites this
file and executes these steps inline** — the orchestrator owns every prompt. The
commands parse `$ARGUMENTS` identically and consume the normalized output
contract (§ Output contract); each then layers its own downstream work. `/epics`
and `/release-notes` are **jira-driven only**: they consume
`{mode, source, jira_key, jira_export_root}`, ignore `specs` / `direct_prompt` /
`direct_files`, and **reject** `mode: direct` (they have no non-Jira behavior —
stop with a clear error).
```

- [ ] **Step 3: Verify (structural)**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "do \*\*not\*\* use this yet" references/jira-input-resolution.md   # expect 0
grep -n "jira-driven only" references/jira-input-resolution.md              # expect 1 hit
grep -n "/implement\`, \`/document\`, \`/epics\`, and \`/release-notes\`" references/jira-input-resolution.md  # expect 1
git -C /workspace/ihudak-claude-plugins diff --stat                          # only this file, ~ +8/-6
```

Expected: the "adoptable later" note is gone; the four-command intro and
jira-driven-only clause are present; the grammar / mode / resolution / fallback /
output-contract sections are untouched.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/jira-input-resolution.md
git commit -m "$(cat <<'EOF'
B3: generalize jira-input-resolution front-end to /epics + /release-notes

Broaden the intro to the four Jira-driven commands and record that /epics and
/release-notes are jira-driven-only adopters (reject mode: direct, ignore
specs/direct_*). No change to the grammar, resolution, fallbacks, or contract.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `/epics` adoption

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md` — Phase 0 (17-31), Phase 1
  output (43-46) + display (66-71), Phase 2 echo (102), Phase 3 dispatch
  (124-128), project-root sites (238, 276, 291, 351)

**Interfaces:**
- Consumes: the front-end (T1) — `{mode, jira_key, jira_export_root}`.
- Produces: `/epics` resolves input via the front-end, is cwd-agnostic, and
  writes to a resolved absolute `output_dir` with a `project_root` for the
  style/git-diff briefs.

- [ ] **Step 1: Replace Phase 0 (front-end citation, drop cwd gate)**

Replace `epics.md` lines 17-31 (the `## Phase 0 — Load` heading through step 3,
i.e. the three steps `Resolve $VAULT_PATH` / `Require vault context` / `Resolve
<JIRA_KEY>`) with:

```
## Phase 0 — Load

1. **Resolve the Jira input via the shared front-end.** Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against
   `$ARGUMENTS`. `/epics` is **jira-driven only**: expect `mode: jira-driven`
   with `jira_key` (the input Value Increment key), `jira_export_root` (the VI
   export dir — `$VAULT_PATH/jira-products/<KEY>` for a JiraID, or the passed
   directory), and `source`. The front-end owns the `$VAULT_PATH` /
   `jira-products` validation and Fallbacks A/B. Carry `jira_key` and
   `jira_export_root` forward. Downstream, `<JIRA_KEY>` and `<VI-KEY>` both
   denote this `jira_key`.

   If the front-end returns `mode: direct` (no Jira input), stop with
   `EPICS_NEEDS_JIRA: /epics needs a Jira key or an imported-Jira directory.` —
   `/epics` has no direct-prompt behavior.

`/epics` is **cwd-agnostic**: it writes Epic drafts to an absolute output
directory (resolved in Phase 1), so it does **not** require cwd to be inside the
vault.
```

- [ ] **Step 2: Rewrite the Phase 1 output-directory bullet**

Replace `epics.md` lines 43-46 (the `- **Output directory** …` bullet and its
`choices` block) with:

```
- **Output directory.** One `.md` file per Epic, filename `<NEW-EPIC-SLUG>.md`
  (drafted Epics have no Jira ID yet, so they are slug-named files inside the
  VI-keyed folder). The default depends on `$VAULT_PATH`:
  - **`$VAULT_PATH` set** → `$VAULT_PATH/jira-drafts/<jira_key>/`. This lives
    **outside** `jira-products/` by design — `jira-products/` is re-created on
    every Jira import, so drafts written there would be lost; `jira-drafts/` is a
    sibling reserved for PM/PO work-in-progress that survives re-imports.
  - **`$VAULT_PATH` unset** (directory input) →
    `<parent-of-jira_export_root>/epic-drafts/<jira_key>/`. **Path-safety
    guard:** warn and offer another path if this dir would fall *inside*
    `jira_export_root` (wiped and regenerated on every import). A pre-existing
    dir that already holds drafts is normal — **not** a warning.
  The directory is auto-created if missing. Record `output_dir`, and record
  `project_root` = `$VAULT_PATH` when set, else `output_dir`. Ask:
  ```
  choices: ["Use <output_dir> (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
```

- [ ] **Step 3: Update the Phase 1 display line**

In `epics.md` (the "Also display" list, ~line 66-71), replace the line
`- Resolved \`$VAULT_PATH\` and \`<JIRA_KEY>\`` with:

```
- Resolved `jira_export_root` and `jira_key` (plus `$VAULT_PATH` when set)
```

- [ ] **Step 4: Rewire the Phase 2 plan echo (literal consumer)**

In `epics.md` (Phase 2, line 102), replace:

```
- Resolved `<JIRA_KEY>` and the `$VAULT_PATH/jira-products/<JIRA_KEY>/` path
```

with:

```
- Resolved `jira_key` and the `jira_export_root` path
```

- [ ] **Step 5: Re-root the Phase 3 `jira-reader` dispatch**

In `epics.md` (Phase 3 dispatch, ~line 127-128), replace the line
`  > vault_path: [resolved $VAULT_PATH]` with
`  > jira_export_root: [resolved jira_export_root]`, and change
`  > jira_key:   [resolved <JIRA_KEY>]` to
`  > jira_key:         [resolved jira_key]`. Leave the `depth: vi-plus-epics`
prose (line 122) unchanged.

- [ ] **Step 6: Swap the four `$VAULT_PATH`-as-project-root sites onto `project_root`**

In `epics.md`, replace each `> Project root: [resolved $VAULT_PATH]` (lines 238,
276, 351) with `> Project root: [resolved project_root]`. And in Phase 8 (line
291) replace:

```
a. The vault is the "project root" for this run. Run `git diff --stat` from `$VAULT_PATH` if the vault is a git repo; otherwise list the written files manually. This command never commits — just report what changed.
```

with:

```
a. `project_root` (the vault when `$VAULT_PATH` is set, else the resolved output directory) is the "project root" for this run. Run `git diff --stat` from `project_root` if it is a git repo; otherwise list the written files manually. This command never commits — just report what changed.
```

- [ ] **Step 7: Verify (structural)**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n "jira-input-resolution" commands/epics.md            # cites front-end
grep -c "Require vault context" commands/epics.md            # expect 0 (gate dropped)
grep -c "Verify cwd is inside" commands/epics.md             # expect 0
grep -n "EPICS_NEEDS_JIRA" commands/epics.md                 # direct-mode reject
grep -c "jira-products/<JIRA_KEY>" commands/epics.md         # expect 0 (all read-consumers rewired)
grep -n "jira_export_root" commands/epics.md                 # Phase 3 + Phase 0/1
grep -c "\[resolved \$VAULT_PATH\]" commands/epics.md        # expect 0 (project-root sites swapped)
grep -c "project_root" commands/epics.md                     # >= 5 (definition + 4 sites)
grep -n "NEVER write inside \`jira-products/\`" commands/epics.md  # invariant KEPT (line ~428)
```

Then **manually inspect** `git -C /workspace/ihudak-claude-plugins diff
commands/epics.md`: confirm Phases 3–9 logic is unchanged **except** the
`jira_export_root` / `project_root` / `jira_key` swaps, and that the vault-set
output default (`$VAULT_PATH/jira-drafts/<jira_key>/`) is behaviorally identical
to the old `$VAULT_PATH/jira-drafts/<VI-KEY>/`.

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/epics.md
git commit -m "$(cat <<'EOF'
B3: /epics adopts the shared Jira-input front-end

Phase 0 now cites references/jira-input-resolution.md (JiraID | imported-Jira
directory), drops the cwd-in-vault gate (cwd-agnostic), rejects mode: direct,
and resolves an absolute output_dir + project_root. $VAULT_PATH set →
jira-drafts/<VI-KEY>/ (byte-unchanged); unset → <import-parent>/epic-drafts/
<VI-KEY>/. jira-reader re-rooted onto jira_export_root; the Phase 2 literal
jira-products echo and the four project-root briefs rewired.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `/release-notes` adoption

**Files:**
- Modify: `plugins/dev-workflows/commands/release-notes.md` — Phase 0 (24-32),
  Phase 1 output destination (57-65) + display (72), Phase 3 dispatch (100-105),
  Phase 6 gaps (148)

**Interfaces:**
- Consumes: the front-end (T1) — `{mode, jira_key, jira_export_root}`.
- Produces: `/release-notes` resolves input via the front-end and always writes
  a **file** (vault Projects folder when set; derived path when unset).

- [ ] **Step 1: Replace Phase 0 (front-end citation)**

Replace `release-notes.md` lines 24-32 (the `## Phase 0 — Load` heading through
step 2) with:

```
## Phase 0 — Load

1. **Resolve the Jira input via the shared front-end.** Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against
   `$ARGUMENTS`. `/release-notes` is **jira-driven only**: expect
   `mode: jira-driven` with `jira_key`, `jira_export_root` (the ticket export
   dir — `$VAULT_PATH/jira-products/<KEY>` for a JiraID, or the passed
   directory), and `source`. The front-end owns the `$VAULT_PATH` /
   `jira-products` validation and Fallbacks A/B. Carry `jira_key` and
   `jira_export_root` forward (downstream `<JIRA_KEY>` denotes `jira_key`).

   If the front-end returns `mode: direct` (no Jira input), stop with
   `RELEASE_NOTES_NEEDS_JIRA: /release-notes needs a Jira key or an imported-Jira directory.` —
   this command has no direct-prompt behavior.
```

- [ ] **Step 2: Rewrite the Phase 1 output-destination bullet (never print-only default)**

Replace `release-notes.md` lines 57-65 (the `- **Output destination.** …` bullet
through the "NEVER offer or accept…" sentence, including the `find` block and the
`choices` block) with:

```
- **Output destination.** Always write to a **file** (console-pasted markdown
  loses formatting in Jira). Resolve the default by `$VAULT_PATH`:
  - **`$VAULT_PATH` set** → resolve the ticket's persistent Obsidian project
    folder (the durable home — NOT `jira-products/`, regenerated on every
    import):
    ```bash
    find "$VAULT_PATH/Projects" -maxdepth 5 -type d -name "<jira_key>*" 2>/dev/null | head -1
    ```
    Default = `<project-dir>/<jira_key>-release-notes.md`. If no project folder
    is found (e.g. a non-`PRODUCT-` ticket), use the derived default below.
  - **`$VAULT_PATH` unset** (directory input) → default
    `<parent-of-jira_export_root>/<jira_key>-release-notes.md`.
  Then ask (the Recommended choice is always the resolved file):
  ```
  choices: ["Write to <default file> (Recommended)", "Write to a different absolute path (you'll be prompted)", "Print to screen only", "Skip writing", "Other… (describe)"]
  ```
  Print-to-screen and Skip remain available but are **never** the default. The
  default is persistent (host-mounted; survives container restart, unlike
  `/tmp`). NEVER offer or accept a path inside a docs repo or under
  `jira-products/`.
```

- [ ] **Step 3: Update the Phase 1 display line**

In `release-notes.md` line 72, replace:

```
Also display: resolved `$VAULT_PATH`, `<JIRA_KEY>`, `$REPOS_PATH` (or "N/A — Jira-only"), and the resolved destination.
```

with:

```
Also display: resolved `jira_export_root`, `jira_key` (plus `$VAULT_PATH` when set), `$REPOS_PATH` (or "N/A — Jira-only"), and the resolved destination.
```

- [ ] **Step 4: Re-root the Phase 3 `jira-reader` dispatch**

Replace `release-notes.md` lines 103-104:

```
  > vault_path: [resolved $VAULT_PATH]
  > jira_key:   [resolved <JIRA_KEY>]
```

with:

```
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
```

- [ ] **Step 5: Add the vault-unset gaps fallback**

In `release-notes.md` Phase 6 (line 148), replace:

```
4. For `document-as-spec` or `skip-and-report`: resolve `bug_report_destination` using `find "$VAULT_PATH/Projects" -maxdepth 5 -type d -name "<JIRA_KEY>*"` (same as the release-notes destination resolution). Write/append `<bug_report_destination>/<JIRA_KEY>-implementation-gaps.md` using the §7.5 format from `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md`, setting `Spec phrasing:` to `(no spec)` (this flow has no spec).
```

with:

```
4. For `document-as-spec` or `skip-and-report`: resolve `bug_report_destination` the same way as the release-notes destination — `$VAULT_PATH` set → the `find "$VAULT_PATH/Projects" -maxdepth 5 -type d -name "<jira_key>*"` project folder; `$VAULT_PATH` unset → `<parent-of-jira_export_root>/`. Write/append `<bug_report_destination>/<jira_key>-implementation-gaps.md` using the §7.5 format from `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md`, setting `Spec phrasing:` to `(no spec)` (this flow has no spec).
```

- [ ] **Step 6: Verify (structural)**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n "jira-input-resolution" commands/release-notes.md    # cites front-end
grep -n "RELEASE_NOTES_NEEDS_JIRA" commands/release-notes.md # direct-mode reject
grep -c "jira-products/<JIRA_KEY>" commands/release-notes.md # expect 0 (read-consumers rewired)
grep -n "jira_export_root" commands/release-notes.md         # Phase 0/1/3/6
grep -n "Write to <default file> (Recommended)" commands/release-notes.md  # file is the default
grep -c "Print to screen only" commands/release-notes.md     # expect 1 (kept as secondary)
```

Then **manually inspect** the diff: the vault-set path (Projects folder resolve +
`<jira_key>-release-notes.md`) is behaviorally identical to before; only the
vault-unset branch and the `jira_export_root`/`jira_key` swaps are new; Phases
2/4/5/7/8 are untouched.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/release-notes.md
git commit -m "$(cat <<'EOF'
B3: /release-notes adopts the shared Jira-input front-end

Phase 0 now cites references/jira-input-resolution.md (JiraID | imported-Jira
directory) and rejects mode: direct. Output is always a file — vault Projects
folder when $VAULT_PATH is set (byte-unchanged), else a derived
<import-parent>/<KEY>-release-notes.md; print-to-screen demoted to a secondary
option. Gaps get the same vault-unset fallback; jira-reader re-rooted onto
jira_export_root.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Hook comment + release v2.2.0

**Files:**
- Modify: `plugins/dev-workflows/hooks/preload-context.sh:15-18` (comment only)
- Modify: `.claude-plugin/plugin.json:3` (version)
- Modify: `.claude-plugin/marketplace.json:12` (`plugins[0].version`)
- Modify: `plugins/dev-workflows/README.md:13-14` (command rows)
- Modify: `plugins/dev-workflows/CHANGELOG.md:7` (prepend `[2.2.0]`)

**Interfaces:**
- Consumes: T1–T3 (the adopted commands). Produces: the shippable v2.2.0.

- [ ] **Step 1: Refresh the hook comment (no functional change)**

In `hooks/preload-context.sh`, replace the `/epics, /release-notes` comment
block (lines 15-18):

```
#   • /epics, /release-notes            → $VAULT_PATH + $REPOS_PATH default
#                                         + git branch only if cwd is inside
#                                         a git repo (no model-routing,
#                                         no full status/log, no directory listing)
```

with:

```
#   • /epics, /release-notes            → $VAULT_PATH + $REPOS_PATH default
#                                         + git branch only if cwd is inside
#                                         a git repo (no model-routing, no full
#                                         status/log, no directory listing). Both
#                                         accept a JiraID or an imported-Jira
#                                         directory via the shared front-end.
```

Do **not** change any executable line.

- [ ] **Step 2: Bump `plugin.json` version**

In `.claude-plugin/plugin.json`, change `"version": "2.1.0",` → `"version": "2.2.0",`.

- [ ] **Step 3: Bump `marketplace.json` `plugins[0].version`**

In `.claude-plugin/marketplace.json`, change the `dev-workflows` entry's
`"version": "2.1.0",` (line 12) → `"version": "2.2.0",`. Leave the sibling
entries (`dt-style-guide` `0.2.2`, `obsidian-llm-wiki` `0.3.1`) untouched.

- [ ] **Step 4: Update the two README command rows**

In `plugins/dev-workflows/README.md`, replace line 13:

```
| `/epics <VI-KEY>` | Jira-driven Epic drafting. Reads the Value Increment + its existing Epics, optionally scans code repos for reusable capabilities and gaps, drafts one markdown file per new Epic under the vault, gated by Opus `epic-reviewer`. Never branches or commits. |
```

with:

```
| `/epics <VI-KEY \| jira-export-dir>` | Jira-driven Epic drafting. Accepts the shared Jira-input grammar — a **VI key** (discovered under `$VAULT_PATH/jira-products/`) or an **imported-Jira directory** (works when `$VAULT_PATH` is unset). Reads the Value Increment + its existing Epics, optionally scans code repos for reusable capabilities and gaps, drafts one markdown file per new Epic under the vault (`jira-drafts/<VI-KEY>/`, or an `epic-drafts/<VI-KEY>/` dir beside the import when `$VAULT_PATH` is unset), gated by Opus `epic-reviewer`. cwd-agnostic; never branches or commits. |
```

and replace line 14:

```
| `/release-notes <KEY>` | Jira-driven release-notes drafting. Reads the ticket from the vault, optionally grounds in merged PR diffs, renders the dynatrace-docs authored release-notes body (`{{#context}}` + title + prose; no IDs, no `{{#internal-note}}`), runs a light `dt-style-checker` gate, and writes a persistent draft to paste into Jira. Never branches, commits, or writes into the docs repo. |
```

with:

```
| `/release-notes <KEY \| jira-export-dir>` | Jira-driven release-notes drafting. Accepts the shared Jira-input grammar — a **ticket key** or an **imported-Jira directory** (works when `$VAULT_PATH` is unset). Reads the ticket, optionally grounds in merged PR diffs, renders the dynatrace-docs authored release-notes body (`{{#context}}` + title + prose; no IDs, no `{{#internal-note}}`), runs a light `dt-style-checker` gate, and always writes a persistent draft **file** (the vault project folder when `$VAULT_PATH` is set, else beside the import) to paste into Jira. Never branches, commits, or writes into the docs repo. |
```

- [ ] **Step 5: Prepend the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, insert **above** the `## [2.1.0] — 2026-06-29`
line (keep all existing history):

```
## [2.2.0] — 2026-07-02

### Added

- **`/epics` and `/release-notes` adopt the shared Jira-input front-end.** Both commands now accept the same grammar as `/implement` and `/document`: a **JiraID** (discovered under `$VAULT_PATH/jira-products/`) **or** an **imported-Jira directory** (the same exporter output rooted anywhere — works when `$VAULT_PATH` is unset). Input is resolved via `references/jira-input-resolution.md`, and `jira-reader` is invoked with `jira_export_root`.

### Changed

- **`/epics` is now cwd-agnostic** — it no longer requires the working directory to be inside `$VAULT_PATH`. Epic drafts are written to an absolute output directory: `$VAULT_PATH/jira-drafts/<VI-KEY>/`, or `<import-parent>/epic-drafts/<VI-KEY>/` when `$VAULT_PATH` is unset.
- **`/release-notes` always writes a file** — the draft (and any implementation-gaps report) goes to the vault project folder when `$VAULT_PATH` is set, or beside the imported directory when it is unset. Print-to-screen is a secondary option, never the default.

```

- [ ] **Step 6: Verify (structural)**

```bash
cd /workspace/ihudak-claude-plugins
bash -n plugins/dev-workflows/hooks/preload-context.sh    # syntax OK
# functional hook test (no regression — routing unchanged):
printf '{"prompt":"/epics /some/imported/dir"}' | bash plugins/dev-workflows/hooks/preload-context.sh
printf '{"prompt":"/release-notes PRODUCT-14902"}' | bash plugins/dev-workflows/hooks/preload-context.sh
# both should print "=== Auto-injected project context (Jira workflow) ===" and exit 0
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"
grep '"version"' .claude-plugin/plugin.json                                    # 2.2.0
python3 -c "import json;print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])"  # 2.2.0
python3 -c "import json;print([p['version'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']])"  # 2.2.0, 0.2.2, 0.3.1
grep -n "jira-export-dir" plugins/dev-workflows/README.md                      # 2 rows
grep -n "## \[2.2.0\]" plugins/dev-workflows/CHANGELOG.md                       # new entry
grep -n "## \[2.1.0\]" plugins/dev-workflows/CHANGELOG.md                       # history preserved
```

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/hooks/preload-context.sh .claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/README.md plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
B3: release v2.2.0 — /epics + /release-notes front-end adoption

Bump plugin.json + marketplace.json plugins[0].version to 2.2.0 (siblings
untouched), refresh the preload hook comment (no functional change), document
directory input + no-vault behavior in the two README rows, and add the [2.2.0]
CHANGELOG entry.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Spec coverage:**
- §A reference generalization → T1. ✅
- §B `/epics` (Phase 0 cite, drop cwd gate, output resolution, jira-reader,
  literal-consumer + project-root rewire, label consistency) → T2 steps 1-6. ✅
- §C `/release-notes` (Phase 0 cite, never-print-only, gaps fallback,
  jira-reader, literal-consumer rewire) → T3 steps 1-5. ✅
- §D Projects/Products kept for output → embodied (no removal; T3 preserves the
  Projects resolution when vault set). ✅
- §E per-command contract consumption + reject direct → T1 clause + T2/T3 direct
  rejection. ✅
- §F hook (no functional change / comment refresh) → T4 step 1. ✅
- §G manifests/README/CHANGELOG v2.2.0 → T4 steps 2-5. ✅
- Verification section → each task's structural-verify step + T4 gates. ✅

**2. Placeholder scan:** No TBD/TODO. Every edit shows exact old→new text.
`<default file>`, `<output_dir>`, `<jira_key>`, `<parent-of-jira_export_root>`
are runtime-resolved tokens inside command prose (the command's own placeholder
convention), not plan placeholders.

**3. Consistency:** `jira_export_root` + `jira_key` used identically across
T2/T3 dispatches and match the front-end contract (§E of the spec). `project_root`
defined once in T2 step 2 and consumed in T2 step 6. `<VI-KEY>` / `<JIRA_KEY>` /
`jira_key` reconciled in T2 step 1. Version `2.2.0` consistent across T4.
CHANGELOG date `2026-07-02` = release date (spec drafted 2026-07-01).

No gaps found.

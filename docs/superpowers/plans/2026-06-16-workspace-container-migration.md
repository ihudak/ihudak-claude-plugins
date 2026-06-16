# /workspace Container Layout Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded `/repos` mount assumption in the Claude marketplace's live plugin content with `$REPOS_PATH`-based repo discovery (default `/workspace`), porting the validated Copilot-sibling design, and deliver a PRODUCT-14902 verification report.

**Architecture:** Repo discovery moves from a fixed `<repos_base>/<slug>` directory lookup to a scan rooted at `$REPOS_PATH` (default `/workspace`, colon-separated list supported) that maps each PR's repo-URL slug to an absolute local clone by matching `git remote get-url origin`. Sub-agents receive an absolute `repo_path` plus an optional `repo_url_slug` for an upstream cross-check. All edits are to markdown/shell plugin content — there is no compiled code and no unit-test framework, so each task is verified by `grep` assertions and (for the hook) a `bash` stdin harness.

**Tech Stack:** Markdown plugin content, one Bash hook (`preload-context.sh`), JSON manifests. Verification via `grep` and `bash`.

---

## File Structure

Files touched, grouped by responsibility:

- **Hook** — `plugins/dev-workflows/hooks/preload-context.sh` (env-var rename + default)
- **Sub-agent contracts** — `plugins/dev-workflows/agents/diff-summarizer.md`, `agents/code-scanner.md`, and their mirrors `references/handoff/diff-summarizer.md`, `references/handoff/code-scanner.md` (absolute `repo_path` + `repo_url_slug`)
- **Orchestrator commands** — `plugins/dev-workflows/commands/impl/jira/docs.md`, `commands/impl/jira/epics.md` (Phase-1 question + Phase-4 resolution + invocation blocks + display lines)
- **Docs** — `plugins/dev-workflows/README.md`, `plugins/dt-style-guide/README.md`, `plugins/dt-style-guide/commands/dt-review-pr.md`, root `CLAUDE.md`
- **Release bookkeeping** — `plugins/dev-workflows/CHANGELOG.md`, `plugins/dt-style-guide/CHANGELOG.md`, the two `plugin.json` files, `.claude-plugin/marketplace.json`
- **New deliverable** — `docs/superpowers/verification/2026-06-16-product-14902-dry-run.md`

Each task produces a self-contained, committable change.

---

## Task 1: Hook — `preload-context.sh` env-var rename

**Files:**
- Modify: `plugins/dev-workflows/hooks/preload-context.sh:6-7` (header comment) and `:97` (emit line)

- [ ] **Step 1: Update the header comment**

Replace (lines 6-8):

```
#   • /impl:jira:docs, /impl:jira:epics → $VAULT_PATH + <repos_base> default
#                                         + git branch only if cwd is inside
#                                         a git repo (no model-routing,
```

with:

```
#   • /impl:jira:docs, /impl:jira:epics → $VAULT_PATH + $REPOS_PATH default
#                                         + git branch only if cwd is inside
#                                         a git repo (no model-routing,
```

- [ ] **Step 2: Update the emit line**

Replace (line ~97):

```
        echo "repos_base: ${REPOS_BASE:-/repos} (default — the command will confirm or ask)"
```

with:

```
        echo "repos_path: ${REPOS_PATH:-/workspace} (default — the command will confirm or ask)"
```

- [ ] **Step 3: Update the inline comment near the jira branch**

Replace (line ~93, inside the `impl:jira*)` case):

```
        # the same vault/repos_base context.
```

with:

```
        # the same vault/repos_path context.
```

- [ ] **Step 4: Verify the hook still routes correctly with a stdin harness**

Run:

```bash
cd /workspace/ihudak-claude-plugins
HOOK=plugins/dev-workflows/hooks/preload-context.sh
# jira branch emits repos_path default /workspace when REPOS_PATH unset
out=$(env -u REPOS_PATH printf '{"prompt":"/impl:jira:docs PRODUCT-14902"}' | bash "$HOOK")
echo "$out" | grep -q "repos_path: /workspace" && echo "PASS: default /workspace" || echo "FAIL"
# honours REPOS_PATH override
out=$(REPOS_PATH=/repos printf '{"prompt":"/impl:jira:epics FOO-1"}' | bash "$HOOK")
echo "$out" | grep -q "repos_path: /repos" && echo "PASS: override honoured" || echo "FAIL"
# no stale REPOS_BASE / /repos default remains
grep -nE "REPOS_BASE|repos_base|:-/repos" "$HOOK" && echo "FAIL: stale ref" || echo "PASS: no stale refs"
# hook always exits 0
printf '{"prompt":"/impl:jira:docs X"}' | bash "$HOOK" >/dev/null; echo "exit=$?"
```

Expected: three `PASS` lines and `exit=0`.

> Note: the harness reads `prompt` from stdin JSON. If the hook reads the prompt differently (it uses `python3` per line 19), confirm the field name by reading lines 20-60 first and adjust the `printf` JSON accordingly. The assertions on `repos_path` output and absence of `REPOS_BASE` are what matter.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/hooks/preload-context.sh
git commit -m "fix(dev-workflows): preload hook uses \$REPOS_PATH (default /workspace)"
```

---

## Task 2: Sub-agent contract — `diff-summarizer`

**Files:**
- Modify: `plugins/dev-workflows/agents/diff-summarizer.md:12`
- Modify: `plugins/dev-workflows/references/handoff/diff-summarizer.md:6`

- [ ] **Step 1: Make `repo_path` absolute and add `repo_url_slug` in the agent body**

In `agents/diff-summarizer.md`, replace line 12:

```
repo_path:   <absolute, e.g. /repos/<repo-name>>
```

with:

```
repo_path:   <absolute path to a local clone, e.g. /workspace/<repo-name>>
repo_url_slug: <repo slug from the PR URL, e.g. "cluster"; optional>
```

- [ ] **Step 2: Add a cross-check rule to the agent body**

In `agents/diff-summarizer.md`, immediately after the closing ``` of the Inputs block (after line 30's block ends), add a new paragraph:

```
When `repo_url_slug` is provided, before summarising run
`git -C <repo_path> remote get-url origin`, strip a trailing `.git`, and compare
the URL's last path segment to `repo_url_slug`. On mismatch, return
`status: REPO_MISSING` with a note naming both slugs — do NOT summarise the wrong
repository. When `repo_url_slug` is absent, trust `repo_path` as given.
```

- [ ] **Step 3: Mirror the change in the handoff reference**

In `references/handoff/diff-summarizer.md`, replace line 6:

```
repo_path: /repos/<repo-name>
```

with:

```
repo_path: <absolute, e.g. /workspace/<repo-name>>
repo_url_slug: <repo slug from PR URL; optional, enables upstream cross-check>
```

- [ ] **Step 4: Verify**

Run:

```bash
cd /workspace/ihudak-claude-plugins
grep -n "repo_url_slug" plugins/dev-workflows/agents/diff-summarizer.md plugins/dev-workflows/references/handoff/diff-summarizer.md
grep -n "/repos/" plugins/dev-workflows/agents/diff-summarizer.md plugins/dev-workflows/references/handoff/diff-summarizer.md && echo "FAIL: stale /repos" || echo "PASS: no /repos"
```

Expected: `repo_url_slug` appears in both files; `PASS: no /repos`.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/diff-summarizer.md plugins/dev-workflows/references/handoff/diff-summarizer.md
git commit -m "fix(dev-workflows): diff-summarizer takes absolute repo_path + repo_url_slug cross-check"
```

---

## Task 3: Sub-agent contract — `code-scanner`

**Files:**
- Modify: `plugins/dev-workflows/agents/code-scanner.md:14`
- Modify: `plugins/dev-workflows/references/handoff/code-scanner.md:6`

- [ ] **Step 1: Make `repo_path` absolute and add `repo_url_slug` in the agent body**

In `agents/code-scanner.md`, replace line 14:

```
repo_path:   <absolute, e.g. /repos/<repo-name>>
```

with:

```
repo_path:   <absolute path to a local clone, e.g. /workspace/<repo-name>>
repo_url_slug: <repo slug from the source URL, e.g. "cluster"; optional>
```

- [ ] **Step 2: Add a cross-check rule to the agent body**

In `agents/code-scanner.md`, replace the line at ~30:

```
Refuse to run without `repo_path`, at least one entry in `capability_themes`, and a `context`.
```

with:

```
Refuse to run without `repo_path`, at least one entry in `capability_themes`, and a `context`.

When `repo_url_slug` is provided, before scanning run
`git -C <repo_path> remote get-url origin`, strip a trailing `.git`, and compare
the URL's last path segment to `repo_url_slug`. On mismatch, return
`status: REPO_MISSING` with a note naming both slugs. When `repo_url_slug` is
absent, trust `repo_path` as given.
```

- [ ] **Step 3: Mirror the change in the handoff reference**

In `references/handoff/code-scanner.md`, replace line 6:

```
repo_path: /repos/<repo-name>
```

with:

```
repo_path: <absolute, e.g. /workspace/<repo-name>>
repo_url_slug: <repo slug from source URL; optional, enables upstream cross-check>
```

- [ ] **Step 4: Verify**

Run:

```bash
cd /workspace/ihudak-claude-plugins
grep -n "repo_url_slug" plugins/dev-workflows/agents/code-scanner.md plugins/dev-workflows/references/handoff/code-scanner.md
grep -n "/repos/" plugins/dev-workflows/agents/code-scanner.md plugins/dev-workflows/references/handoff/code-scanner.md && echo "FAIL: stale /repos" || echo "PASS: no /repos"
```

Expected: `repo_url_slug` appears in both files; `PASS: no /repos`.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/code-scanner.md plugins/dev-workflows/references/handoff/code-scanner.md
git commit -m "fix(dev-workflows): code-scanner takes absolute repo_path + repo_url_slug cross-check"
```

---

## Task 4: Orchestrator — `commands/impl/jira/docs.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md` — lines 66-70 (Phase-1 question), 81 & 100 (display), 135-144 (Phase-4 resolution), 160 (invocation), 482 (report)

- [ ] **Step 1: Replace the Phase-1 "Repos base path" question (lines 66-70)**

Replace:

```
- **Repos base path**. Detect `/repos` first (`[ -d /repos ]`). Ask:
  ```
  choices: ["Use /repos (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input and validate that at least one directory exists under it. Record the resolved path as `<repos_base>`.
```

with:

```
- **Repos search base (`$REPOS_PATH`)**. Read `${REPOS_PATH:-/workspace}` (the container mounts every repo under `/workspace`). `$REPOS_PATH` may be a single directory or a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input (single dir or colon-separated list) and validate that at least one directory exists under it. Record the resolved value as `$REPOS_PATH`. Individual clones are located in Phase 4 by matching their `git remote` against each PR's repo slug — not by assuming a `<base>/<slug>` directory name.
```

- [ ] **Step 2: Update the Phase-1 display line (line ~81)**

Replace:

```
- Resolved `<repos_base>`
```

with:

```
- Resolved `$REPOS_PATH`
```

- [ ] **Step 3: Update the plan-approval display line (line ~100)**

Replace:

```
- `<repos_base>` and the repos that will be examined (inferred from the `jira-reader` output in Phase 3; if Phase 3 hasn't run yet, list "TBD — resolved after Jira read")
```

with:

```
- `$REPOS_PATH` and the slug→clone resolution for the repos that will be examined (inferred from the `jira-reader` output in Phase 3; if Phase 3 hasn't run yet, list "TBD — resolved after Jira read")
```

- [ ] **Step 4: Rewrite the Phase-4 repo-resolution steps (lines 135-144)**

Replace steps 3-4:

```
3. For each unique `repo`, check that `<repos_base>/<repo>` exists as a directory.
4. If any repos are missing, escalate using the §15 rules:
   ```
   choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Use different /repos path"]
   ```
   List the missing repos explicitly. "Skip" removes that repo's PRs from scope; "I'll clone it — wait" pauses the run until the user confirms the clone is done, then re-checks existence; "Use different /repos path" re-prompts for `<repos_base>` and re-validates.
```

with:

```
3. Build a slug→clone map. For each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote` call fails/times out. Result: `<slug> → [<absolute path>, ...]`.
4. Resolve each unique in-scope `repo` slug against the map:
   - **One match** — use that absolute path as `repo_path`.
   - **Multiple matches** (e.g. `cluster` and `cluster-repo`, both pointing at the same upstream) — auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last; show all candidates at plan approval so the user can override.
   - **Zero matches** — escalate using the §15 rules:
     ```
     choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]
     ```
     List the unresolved slugs explicitly. "Skip" removes that repo's PRs from scope; "I'll clone it — wait" pauses until the user confirms the clone is present under `$REPOS_PATH`, then re-runs step 3; "Specify a different absolute path" records the path directly as `repo_path` for that slug.
   Record the resolution as `repo_slug → repo_path` for Phase 5.
```

- [ ] **Step 5: Update the `diff-summarizer` invocation block (line ~160)**

Replace:

```
  > repo_path:   <repos_base>/<repo>
```

with:

```
  > repo_path:     <resolved absolute path for this repo from Phase 4>
  > repo_url_slug: <repo slug, e.g. "cluster">
```

- [ ] **Step 6: Update the Phase-9 report line (line ~482)**

Replace:

```
- <repos_base>/<repo-1> — [N PRs in scope, M resolved, K unresolved]
```

with:

```
- <repo-1> (<resolved repo_path>) — [N PRs in scope, M resolved, K unresolved]
```

- [ ] **Step 7: Verify**

Run:

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/impl/jira/docs.md
grep -nE "repos_base|/repos\b|\[ -d /repos \]" "$F" && echo "FAIL: stale ref" || echo "PASS: no stale refs"
grep -q "REPOS_PATH" "$F" && echo "PASS: REPOS_PATH present" || echo "FAIL"
grep -q "repo_url_slug" "$F" && echo "PASS: slug passed to agent" || echo "FAIL"
```

Expected: `PASS: no stale refs`, `PASS: REPOS_PATH present`, `PASS: slug passed to agent`.

- [ ] **Step 8: Commit**

```bash
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "fix(dev-workflows): /impl:jira:docs resolves repos via \$REPOS_PATH + git-remote slug match"
```

---

## Task 5: Orchestrator — `commands/impl/jira/epics.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/epics.md` — lines 48 (scan question), 60-64 (Phase-1 question), 69 (display), 129 & 131-133 (Phase-4), 154 (invocation), 401 (report)

- [ ] **Step 1: Update the code-scan repo question (line 48)**

Replace:

```
- **Code examination on/off** (default ON). If ON, ask which repos under `<repos_base>` to scan:
```

with:

```
- **Code examination on/off** (default ON). If ON, ask which repos under `$REPOS_PATH` to scan:
```

- [ ] **Step 2: Replace the Phase-1 "Repos base path" question (lines 60-64)**

Replace:

```
- **Repos base path** (only if code scan is ON). Detect `/repos` first. Ask:
  ```
  choices: ["Use /repos (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input and validate that at least one directory exists under it. Record the resolved path as `<repos_base>`.
```

with:

```
- **Repos search base (`$REPOS_PATH`)** (only if code scan is ON). Read `${REPOS_PATH:-/workspace}` (the container mounts every repo under `/workspace`). `$REPOS_PATH` may be a single directory or a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input (single dir or colon-separated list) and validate that at least one directory exists under it. Record the resolved value as `$REPOS_PATH`. Individual clones are located in Phase 4 by matching their `git remote` against each repo slug — not by assuming a `<base>/<slug>` directory name.
```

- [ ] **Step 3: Update the Phase-1 display line (line ~69)**

Replace:

```
- Resolved `<repos_base>` (or "N/A — code scan off")
```

with:

```
- Resolved `$REPOS_PATH` (or "N/A — code scan off")
```

- [ ] **Step 4: Update the manual-list validation line (line ~129)**

Replace:

```
   - **Manual list** — prompt for a free-text list of repo short names (one per line or space-separated). Validate each is a directory under `<repos_base>`.
```

with:

```
   - **Manual list** — prompt for a free-text list of repo short names (one per line or space-separated). Resolve each against the `$REPOS_PATH` slug→clone map built in step 2 below.
```

- [ ] **Step 5: Rewrite the Phase-4 repo-resolution step (line ~131-133)**

Replace:

```
2. For each resolved repo, check `<repos_base>/<repo>` exists. Escalate missing repos per §15:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Use different /repos path", "Other… (describe)"]
   ```
```

with:

```
2. Build a slug→clone map. For each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote` call fails/times out. Resolve each in-scope repo slug against the map: one match → use it; multiple matches → auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last (show candidates at plan approval); zero matches → escalate per §15:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
   ```
```

- [ ] **Step 6: Update the `code-scanner` invocation block (line ~154)**

Replace:

```
  > repo_path:   <repos_base>/<repo>
```

with:

```
  > repo_path:     <resolved absolute path for this repo from Phase 4>
  > repo_url_slug: <repo slug, e.g. "cluster">
```

- [ ] **Step 7: Update the Phase report line (line ~401)**

Replace:

```
- <repos_base>/<repo-1> — [status: OK | PARTIAL | EMPTY | DIRTY_TREE | REFRESH_BLOCKED; N themes classified present, M partial, K absent, E error]
```

with:

```
- <repo-1> (<resolved repo_path>) — [status: OK | PARTIAL | EMPTY | DIRTY_TREE | REFRESH_BLOCKED; N themes classified present, M partial, K absent, E error]
```

- [ ] **Step 8: Verify**

Run:

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/impl/jira/epics.md
grep -nE "repos_base|/repos\b" "$F" && echo "FAIL: stale ref" || echo "PASS: no stale refs"
grep -q "REPOS_PATH" "$F" && echo "PASS: REPOS_PATH present" || echo "FAIL"
grep -q "repo_url_slug" "$F" && echo "PASS: slug passed to agent" || echo "FAIL"
```

Expected: `PASS: no stale refs`, `PASS: REPOS_PATH present`, `PASS: slug passed to agent`.

- [ ] **Step 9: Commit**

```bash
git add plugins/dev-workflows/commands/impl/jira/epics.md
git commit -m "fix(dev-workflows): /impl:jira:epics resolves repos via \$REPOS_PATH + git-remote slug match"
```

---

## Task 6: `dev-workflows/README.md` — container guidance

**Files:**
- Modify: `plugins/dev-workflows/README.md:157-162`

- [ ] **Step 1: Update the AI Container bullet block**

Replace lines 157-162:

```
- **Recommended environment: [ihudak/ai-containers](https://github.com/ihudak/ai-containers).** The commands work best inside the AI Container, which:
  - Mounts `/repos` with the relevant code repositories already cloned, so the default `<repos_base>` just works.
  - Installs `gh` automatically.
  - Mounts `~/.config/gh` from the host, so `gh auth login` on the host is sufficient — no re-auth inside the container.

  Outside the AI Container the commands still function; the user manages `<repos_base>`, `gh` installation, and `gh auth login` themselves.
```

with:

```
- **Recommended environment: [ihudak/ai-containers](https://github.com/ihudak/ai-containers).** The commands work best inside the AI Container, which:
  - Mounts every repository and the Obsidian vault under a single `/workspace` umbrella (`/workspace/<repo>`, vault at `/workspace/obsidian`), so the default `$REPOS_PATH` (`/workspace`) and exported `VAULT_PATH` just work. Repos are located by matching each PR's slug against `git remote get-url origin`, so a clone's directory name need not equal the slug.
  - Installs `gh` automatically.
  - Mounts `~/.config/gh` from the host, so `gh auth login` on the host is sufficient — no re-auth inside the container.

  Outside the AI Container the commands still function; set `$REPOS_PATH` (single dir or colon-separated list) to wherever your clones live, and manage `gh` installation and `gh auth login` yourself.
```

- [ ] **Step 2: Verify**

Run:

```bash
cd /workspace/ihudak-claude-plugins
grep -nE "repos_base|Mounts \`/repos\`" plugins/dev-workflows/README.md && echo "FAIL" || echo "PASS: no stale refs"
grep -q "REPOS_PATH" plugins/dev-workflows/README.md && echo "PASS: REPOS_PATH documented" || echo "FAIL"
```

Expected: `PASS: no stale refs`, `PASS: REPOS_PATH documented`.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/README.md
git commit -m "docs(dev-workflows): README documents /workspace layout + \$REPOS_PATH discovery"
```

---

## Task 7: `dt-style-guide` — `/repos/dynatrace-docs` examples

**Files:**
- Modify: `plugins/dt-style-guide/commands/dt-review-pr.md:25,28`
- Modify: `plugins/dt-style-guide/README.md:36`

- [ ] **Step 1: Update the command's `--repo` example rows**

In `commands/dt-review-pr.md`, replace line 25:

```
| `--repo <path>` | `--repo /repos/dynatrace-docs` | Override the repo path (default: current working directory) |
```

with:

```
| `--repo <path>` | `--repo /workspace/dynatrace-docs` | Override the repo path (default: current working directory) |
```

And replace line 28:

```
Arguments can be combined: `9089 --repo /repos/dynatrace-docs`.
```

with:

```
Arguments can be combined: `9089 --repo /workspace/dynatrace-docs`.
```

- [ ] **Step 2: Update the README usage example**

In `README.md`, replace line 36:

```
/dt-review-pr 9089 --repo /repos/dynatrace-docs
```

with:

```
/dt-review-pr 9089 --repo /workspace/dynatrace-docs
```

- [ ] **Step 3: Verify**

Run:

```bash
cd /workspace/ihudak-claude-plugins
grep -rn "/repos/dynatrace-docs" plugins/dt-style-guide/ && echo "FAIL: stale ref" || echo "PASS: no stale refs"
```

Expected: `PASS: no stale refs`.

- [ ] **Step 4: Commit**

```bash
git add plugins/dt-style-guide/commands/dt-review-pr.md plugins/dt-style-guide/README.md
git commit -m "docs(dt-style-guide): update --repo examples to /workspace/dynatrace-docs"
```

---

## Task 8: Root `CLAUDE.md` — invariant + path-convention note

**Files:**
- Modify: `CLAUDE.md:158` (the `/impl:jira` zero-API invariant)

- [ ] **Step 1: Update the invariant line**

Replace line 158:

```
- **Zero external API calls** — PR URLs from Jira exports are identifiers only; no `gh`, no Bitbucket REST API, no HTTPS fetch to Bitbucket; all resolution is local `git` against clones under `/repos/`
```

with:

```
- **Zero external API calls** — PR URLs from Jira exports are identifiers only; no `gh`, no Bitbucket REST API, no HTTPS fetch to Bitbucket; all resolution is local `git` against clones discovered under `$REPOS_PATH` (default `/workspace`), matched by `git remote get-url origin` slug
```

- [ ] **Step 2: Verify**

Run:

```bash
cd /workspace/ihudak-claude-plugins
grep -n "clones under \`/repos/\`" CLAUDE.md && echo "FAIL: stale ref" || echo "PASS: no stale refs"
grep -q "REPOS_PATH" CLAUDE.md && echo "PASS: REPOS_PATH documented" || echo "FAIL"
```

Expected: `PASS: no stale refs`, `PASS: REPOS_PATH documented`.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: CLAUDE.md /impl:jira invariant references \$REPOS_PATH discovery"
```

---

## Task 9: CHANGELOGs + version bumps

**Files:**
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend 1.5.0 entry)
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (`1.4.0` → `1.5.0`)
- Modify: `plugins/dt-style-guide/CHANGELOG.md` (prepend 0.2.2 entry)
- Modify: `plugins/dt-style-guide/.claude-plugin/plugin.json` (`0.2.1` → `0.2.2`)
- Modify: `.claude-plugin/marketplace.json` (`dev-workflows` 1.4.0→1.5.0, `dt-style-guide` 0.2.1→0.2.2)

- [ ] **Step 1: Prepend the dev-workflows 1.5.0 entry**

Insert directly after the header block (before `## [1.4.0] — 2026-06-15`):

```
## [1.5.0] — 2026-06-16

### Changed (breaking for orchestrators that hardcode `/repos/`)
- **`/impl:jira:*` repo discovery is now `$REPOS_PATH`-based.** The old fixed
  `<repos_base>/<slug>` directory lookup (default `/repos`) is replaced by a scan
  rooted at `$REPOS_PATH` (default `/workspace`; colon-separated list supported)
  that maps each PR's repo-URL slug to an absolute local clone by matching
  `git remote get-url origin`. Multiple clones of one upstream are disambiguated
  by the preference order `<slug>-repo` > `<slug>_repo` > `<slug>_fast` >
  alphabetically last. This matches the container's `/workspace` umbrella layout
  (every repo and the Obsidian vault mounted under `/workspace`).
- **`diff-summarizer` / `code-scanner` inputs.** `repo_path` is now any absolute
  path (no longer assumed `/repos/<name>`), and a new optional `repo_url_slug`
  enables an upstream cross-check — on mismatch the agent returns `REPO_MISSING`
  instead of summarising the wrong repo.
- **`preload-context.sh`.** Emits `repos_path: ${REPOS_PATH:-/workspace}`
  (previously `repos_base: ${REPOS_BASE:-/repos}`).

### Migration notes
- If your clones still live under `/repos`, set `REPOS_PATH=/repos` to preserve
  the old base. The slug→clone match by `git remote` works regardless of base.

```

- [ ] **Step 2: Bump dev-workflows plugin.json**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, replace `"version": "1.4.0",` with `"version": "1.5.0",`.

- [ ] **Step 3: Prepend the dt-style-guide 0.2.2 entry**

Insert directly after the `# Changelog` header (before `## 0.2.1`):

```
## 0.2.2

- Updated `/dt-review-pr` `--repo` examples from `/repos/dynatrace-docs` to
  `/workspace/dynatrace-docs` to match the AI container's single-umbrella mount
  layout.

```

- [ ] **Step 4: Bump dt-style-guide plugin.json**

In `plugins/dt-style-guide/.claude-plugin/plugin.json`, replace `"version": "0.2.1",` with `"version": "0.2.2",`.

- [ ] **Step 5: Update marketplace.json version pins**

In `.claude-plugin/marketplace.json`, change the `dev-workflows` entry `"version": "1.4.0"` → `"1.5.0"` and the `dt-style-guide` entry `"version": "0.2.1"` → `"0.2.2"`. Leave `obsidian-llm-wiki` (`0.3.1`) unchanged.

- [ ] **Step 6: Verify versions are consistent**

Run:

```bash
cd /workspace/ihudak-claude-plugins
grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json   # expect 1.5.0
grep '"version"' plugins/dt-style-guide/.claude-plugin/plugin.json  # expect 0.2.2
grep -A1 '"name": "dev-workflows"' .claude-plugin/marketplace.json   # expect 1.5.0
grep -A1 '"name": "dt-style-guide"' .claude-plugin/marketplace.json  # expect 0.2.2
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); print('marketplace.json valid JSON')"
python3 -c "import json; json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); json.load(open('plugins/dt-style-guide/.claude-plugin/plugin.json')); print('plugin.json files valid')"
```

Expected: versions match; both JSON validity lines print.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/.claude-plugin/plugin.json \
        plugins/dt-style-guide/CHANGELOG.md plugins/dt-style-guide/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json
git commit -m "release: dev-workflows 1.5.0, dt-style-guide 0.2.2 (/workspace migration)"
```

---

## Task 10: PRODUCT-14902 verification report + final sweep

**Files:**
- Create: `docs/superpowers/verification/2026-06-16-product-14902-dry-run.md`

- [ ] **Step 1: Re-confirm the live findings against the container**

Run (these reproduce the data the report cites):

```bash
cd /workspace/ihudak-claude-plugins
echo "VAULT_PATH=$VAULT_PATH"
for slug in cluster dynatrace-docs appfw-spec semantic-dictionary oneagent-protocols installer-activegate guidelines; do
  found=""
  for d in /workspace/*/; do
    url=$(git -C "$d" remote get-url origin 2>/dev/null)
    [ "$(basename "${url%.git}")" = "$slug" ] && found="$found $(basename "$d")"
  done
  printf "%-22s -> %s\n" "$slug" "${found:- NOT MOUNTED}"
done
```

Expected: `cluster -> cluster`, `dynatrace-docs -> dynatrace-docs`; the other five `NOT MOUNTED`. If reality differs, update the report's tables to match before writing.

- [ ] **Step 2: Write the verification report**

Create `docs/superpowers/verification/2026-06-16-product-14902-dry-run.md` with:

```markdown
# PRODUCT-14902 Dry-Run Verification — /workspace container layout

**Date:** 2026-06-16
**Container:** repos + Obsidian vault mounted under `/workspace`; `VAULT_PATH=/workspace/obsidian`; `REPOS_PATH` unset (default `/workspace` applies).

## Scope

Confirms that, after the `/workspace` migration (dev-workflows 1.5.0), the
`/impl:jira:docs` and `/impl` workflows find the pieces needed to document /
implement PRODUCT-14902 ("Environment ActiveGate update windows"). No docs were
written; this is a trace, not an execution.

## Repo resolution (git-remote slug match)

| Repo slug (from PR URLs) | Mounted clone | Resolves? |
|---|---|---|
| `cluster` (65 PR refs) | `/workspace/cluster` (`rx/cluster.git`) | ✓ |
| `dynatrace-docs` (write target) | `/workspace/dynatrace-docs` (`sus/dynatrace-docs.git`) | ✓ |
| `appfw-spec` | — | not mounted → PRs skipped |
| `semantic-dictionary` | — | not mounted → PRs skipped |
| `oneagent-protocols` | — | not mounted → PRs skipped |
| `installer-activegate` | — | not mounted → PRs skipped |
| `guidelines` | — | not mounted → PRs skipped |

## `/impl:jira:docs` trace

- **Phase 1** — `$VAULT_PATH=/workspace/obsidian` resolves; the VI export exists
  at `$VAULT_PATH/jira-products/PRODUCT-14902/`. `$REPOS_PATH` defaults to
  `/workspace`.
- **Phase 3** — `jira-reader` parses the VI hierarchy (index + linked items
  MGD-789, MGD-7522, etc.) and the `## Pull Requests` sections.
- **Phase 4** — slug→clone map built from `/workspace`; `cluster` (the dominant
  repo) resolves; the five unmounted repos hit the zero-match escalation and are
  skipped per the user's choice. The `dynatrace-docs` write target resolves and
  carries docs signals (`.docstack`, `.vale.ini`, `.vale`), so
  `doc-location-finder` has a real target.
- **Phases 5-9** — `diff-summarizer` runs against `/workspace/cluster` with
  `repo_url_slug: cluster`; style-check uses the docs repo's Vale config; the
  Opus `doc-reviewer` gate applies.
- **Verdict:** Works. The dominant implementation surface (`cluster`) and the
  docs write target (`dynatrace-docs`) are both present. The five secondary
  repos are out of this container's scope; mounting them (via `REPOS`/
  `EXTRA_MOUNTS`) would fold their PRs in.

## `/impl` (code) trace

- `/impl:code` operates on the **current working directory's** repo, not a
  `$REPOS_PATH` scan. To implement PRODUCT-14902, run it from
  `/workspace/cluster`. No `/repos` dependency exists in that workflow.
- **Verdict:** Works in the new layout unchanged; the implementation surface is
  present at `/workspace/cluster`.

## Other plugins

- **`dt-style-guide`** — `/dt-review-pr` defaults to cwd; the documented
  `--repo` example now points at `/workspace/dynatrace-docs`. Works.
- **`obsidian-llm-wiki`** — consumes `VAULT_PATH` (set to `/workspace/obsidian`);
  the `~/obsidian_vault` default is only a fallback. Works.

## Residual gaps (environment, not plugin)

- Five secondary repos referenced by PRODUCT-14902 are not mounted in this
  container; their PRs are skipped. Mount them if their diffs are needed.
```

- [ ] **Step 3: Final repo-wide stale-reference sweep**

Run:

```bash
cd /workspace/ihudak-claude-plugins
# Live plugin content must have no /repos default or REPOS_BASE.
# Excludes: legit external URLs, historical specs/plans, this report's table, .ai-containers.
grep -rnE "/repos\b|REPOS_BASE|repos_base" \
  --include="*.md" --include="*.json" --include="*.sh" \
  plugins/ CLAUDE.md \
  | grep -vE "api\.github\.com/repos|hub\.docker|bitbucket\.lab|projects/[A-Za-z]+/repos/|repos\.conf" \
  && echo "REVIEW the hits above" || echo "PASS: no stale repo refs in live content"
```

Expected: `PASS: no stale repo refs in live content`. If any hit appears, confirm it is a legitimate external URL (leave) or fix it.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/verification/2026-06-16-product-14902-dry-run.md
git commit -m "docs: PRODUCT-14902 dry-run verification for /workspace migration"
```

---

## Post-implementation

- [ ] Reinstall the edited plugins so the running environment picks up the changes:
  ```bash
  claude plugin reinstall dev-workflows@ihudak-plugins
  claude plugin reinstall dt-style-guide@ihudak-plugins
  ```
- [ ] Offer to push the branch / open a PR (do not push without the user's go-ahead).

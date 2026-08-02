---
tags:
  - tasks-exclude
---

# Setup README Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repo-root `README.md` a complete setup guide (prerequisites, env-vars + directory structures, first command), point the three plugin READMEs at it, and refresh the stale command list in `CLAUDE.md`.

**Architecture:** Three tasks — (1) rewrite repo-root `README.md` to add Prerequisites / env-var + first-command install steps / Directory structure; (2) add a one-line setup-guide pointer to the 3 plugin READMEs; (3) refresh the stale command list in `CLAUDE.md`. Documentation only; no runtime code, no test framework.

**Tech Stack:** Markdown. Verification is structural: `grep`, `git diff --stat`, `ls`, link-target existence, `python3 -c json.load` for the untouched-manifests check.

## Global Constraints

- **Commit/push only when asked.** Work on branch `ivgu/NOISSUE-setup-readme` off `main`. Per-task commits on that branch; pushing is gated to the finish-branch menu.
- **Never `git add -A`.** Stage only the named files per commit.
- **Commit trailer** (last line, exact): `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Verify with `git log -1 --format=%B` first.
- **Docs-only — NO version bumps, NO CHANGELOG.** Do NOT edit any `plugin.json`, `marketplace.json`, or `CHANGELOG.md`. Plugin versions stay `dev-workflows 2.26.0` / `dt-style-guide 0.2.2` / `obsidian-llm-wiki 0.3.1`.
- **Only verified URLs.** Use exactly these external links and no others: `https://github.com/ivan-gudak/jira-workitem-import` and `https://github.com/ihudak/ai-containers`. Reference `superpowers` and `vale` by name only (no fabricated URLs).
- **Relative link to root README** from any `plugins/<name>/README.md` is `../../README.md`.
- **No collateral:** `commands/`, `agents/`, `references/`, `scripts/`, and all `.claude-plugin/` manifests → 0-line diff.
- Your shell cwd resets to `/workspace/docs` between bash calls — use absolute paths / `cd` inline.
- The vault holding this plan is auto-backed-up by Obsidian Git — do NOT hand-commit vault files.

---

## Task 1: Rewrite repo-root `README.md` (setup guide)

**Files:**
- Modify (full rewrite): `/workspace/ihudak-claude-plugins/README.md`

**Interfaces:**
- Produces: the canonical setup guide the plugin-README pointers (Task 2) link to (`../../README.md`).
- Note: this rewrite also refreshes the stale Plugins-table `dev-workflows` row (it listed 11 of the 20 commands) — unavoidable when rewriting the file, and consistent with the accuracy intent.

- [ ] **Step 1: Overwrite `README.md`** with exactly this content (use the Write tool):

````markdown
# ihudak-claude-plugins

Ivan Gudak's private Claude Code plugin marketplace.

## Plugins

| Plugin | Description |
|--------|-------------|
| [dev-workflows](plugins/dev-workflows/) | Twenty slash commands for the PM → PA → PE → Dev workflow — idea refinement, VI / ARD authoring, Epic drafting, specification and engineering-design authoring, structured implementation, feature documentation, release notes, vulnerability remediation, dependency upgrades, API / UI guideline compliance, and a status-anchored readiness gate — with Opus-backed planning, code review, and doc / Epic / design review gates. |
| [dt-style-guide](plugins/dt-style-guide/) | Dynatrace corporate style guide enforcement: `/dt-review-pr`, `/dt-review-docs`, `/dt-style-refresh`, and sub-agents used by `dev-workflows` for style checking Epics and feature docs. |
| [obsidian-llm-wiki](plugins/obsidian-llm-wiki/) | Ten slash commands for compiling Obsidian vault knowledge into a persistent, cross-referenced wiki with task management; supports Claude Code and GitHub Copilot. |

## Prerequisites

- **Claude Code** — the plugins install into Claude Code (some `obsidian-llm-wiki` commands also support GitHub Copilot).
- **`superpowers`** *(recommended)* — the Claude Code plugin `dev-workflows` leans on for `/prompt-brainstorm` and its brainstorm → plan → subagent-driven-development flow. No hard dependency; commands degrade gracefully without it.
- **[`jira-workitem-import`](https://github.com/ivan-gudak/jira-workitem-import)** *(required for Jira-driven commands)* — imports Jira tickets into `$VAULT_PATH/jira-products/<KEY>/` in the exact structure the plugins expect. Every Jira-driven command (`/idea` from an RFE, `/create-vi`, `/epics`, `/specify`, `/design`, `/implement`, `/document`, `/release-notes`, `/ready`) consumes this tree.
- **`gh` + `gh auth login`** *(recommended)* — enables reading GitHub PR diffs (`/document`, `/release-notes`); without it those commands fall back to local-git strategies.
- **`vale`** *(optional)* — a prose linter for docs; `dev-workflows` falls back to a repo lint script, then the `dt-style-guide` plugin, when `vale` is absent.
- **Recommended environment: [`ihudak/ai-containers`](https://github.com/ihudak/ai-containers)** — mounts every repository and your Obsidian vault under one `/workspace` umbrella (repos at `/workspace/<repo>`, vault at `/workspace/obsidian`), so the default `$REPOS_PATH` (`/workspace`) and an exported `VAULT_PATH` just work; it also installs `gh` and mounts the host `gh` auth. Outside a container the commands still work — set `$REPOS_PATH` yourself and manage `gh` login.

## Installation

### 1. Add this marketplace to Claude Code (once)

```bash
claude plugin marketplace add ihudak/ihudak-claude-plugins
```

### 2. Install plugins

```bash
claude plugin install dev-workflows@ihudak-plugins
claude plugin install dt-style-guide@ihudak-plugins
claude plugin install obsidian-llm-wiki@ihudak-plugins
```

### 3. Configure environment variables

`dev-workflows` resolves its inputs and outputs through three environment variables. Export them in your shell profile (or rely on the AI-Container defaults):

```bash
export VAULT_PATH="$HOME/obsidian"     # personal store: Jira imports + idea/project files
export SPECS_PATH="/workspace/specs"   # shared store: specifications, designs, ARDs
export REPOS_PATH="/workspace"         # where your code clones live (default: /workspace)
```

- **`VAULT_PATH`** — your personal store. Holds `jira-products/<KEY>/` (produced by `jira-workitem-import`) and `Projects/<area>/<slug>/` (idea and project files).
- **`SPECS_PATH`** — the shared, team-visible store for a ticket's `specification.md` / `design.md` / ARD under `specifications/<KEY>-<slug>/…`. Required by `/implement`; additive for `/document`.
- **`REPOS_PATH`** — where code clones live; a single directory or a colon-separated list. Defaults to `/workspace`. Repos are matched by their `git remote get-url origin` slug, not by directory name.

### 4. Run `/statusline` first

After installing, run `/statusline` once. It installs the `dev-workflows` multi-line status line (session identity, git, context, cost, tokens, rate limits) into `~/.claude/settings.json` and enables the Option-B snapshot used by session-cost reporting. It is idempotent and backs up anything it would overwrite, and it changes no workflow-command behavior.

```
/statusline
```

### 5. Update after new releases

```bash
claude plugin marketplace update ihudak-plugins
```

## Directory structure

The three environment variables expect these layouts:

```
$VAULT_PATH/                      # personal store (e.g. an Obsidian vault)
  jira-products/<KEY>/            # Jira hierarchy from jira-workitem-import (input; regenerated each import)
  Projects/<area>/<slug>/         # idea.md and project working files

$SPECS_PATH/                      # shared, team-visible store
  specifications/<KEY>-<slug>/    # specification.md, design.md, ARD (+ per-Epic subfolders)

$REPOS_PATH/                      # code clones (default /workspace)
  <repo>/                         # matched by git remote slug, not directory name
```

## Adding new plugins

1. Create a subdirectory under `plugins/` with the plugin name.
2. Add `.claude-plugin/plugin.json` (name, description, author).
3. Add `commands/`, `agents/`, `hooks/`, and/or `skills/` as needed.
4. For hooks, add a `hooks/hooks.json` declaring the registrations.
5. Register the plugin in `.claude-plugin/marketplace.json`.
6. Commit and push to `main`.

## License

MIT — see [LICENSE](LICENSE).
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '## Prerequisites' README.md
grep -n '### 3. Configure environment variables' README.md
grep -n '### 4. Run `/statusline` first' README.md
grep -n '## Directory structure' README.md
# original install commands still present + correct
grep -c 'claude plugin marketplace add ihudak/ihudak-claude-plugins' README.md   # 1
grep -c 'claude plugin install dev-workflows@ihudak-plugins' README.md            # 1
grep -c 'claude plugin marketplace update ihudak-plugins' README.md               # 1
# only the two verified URLs are present as external links
grep -oE 'https?://[^ )]+' README.md | sort -u
# expect exactly: https://github.com/ihudak/ai-containers , https://github.com/ivan-gudak/jira-workitem-import
```
Expected: each new heading found once; the three install commands present; the URL list contains ONLY the two verified GitHub URLs.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add README.md
git commit -m "$(cat <<'EOF'
docs: expand repo-root README into a full setup guide

Add Prerequisites (superpowers, jira-workitem-import, gh, vale, AI-Containers),
env-var configuration + directory structures ($VAULT_PATH/$SPECS_PATH/$REPOS_PATH),
and a "run /statusline first" step. Also refresh the stale dev-workflows row in
the Plugins table (it listed 11 of the 20 commands).

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Setup-guide pointers in the 3 plugin READMEs

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/plugins/dt-style-guide/README.md`
- Modify: `/workspace/ihudak-claude-plugins/plugins/obsidian-llm-wiki/README.md`
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/README.md`

**Interfaces:**
- Consumes: the root setup guide from Task 1 (`../../README.md`).
- Each is one Edit adding a pointer line; no other content changed. (The `dev-workflows` README intro count "Twelve" is knowingly left as-is — a prose refresh is out of this effort's scope.)

- [ ] **Step 1: `dt-style-guide/README.md` — add pointer to the Installation section**

`old_string`:
```markdown
## Installation

This plugin is part of the `ihudak-plugins` marketplace. Install via Claude Code's
plugin system — it will be available alongside `dev-workflows`.
```
`new_string`:
```markdown
## Installation

This plugin is part of the `ihudak-plugins` marketplace. Install via Claude Code's
plugin system — it will be available alongside `dev-workflows`.

For marketplace install and prerequisites, see the [repo-root setup guide](../../README.md).
```

- [ ] **Step 2: `obsidian-llm-wiki/README.md` — add pointer to the Installation intro**

`old_string`:
```markdown
Complete installation has three parts: (A) install the plugin into your agent, (B)
configure your vault path if it differs from the default, (C) integrate the wiki layer
into your vault's instruction files (one-time, commit to the vault repo).
```
`new_string`:
```markdown
Complete installation has three parts: (A) install the plugin into your agent, (B)
configure your vault path if it differs from the default, (C) integrate the wiki layer
into your vault's instruction files (one-time, commit to the vault repo).

For the marketplace install shared across the `ihudak-plugins` plugins, see the [repo-root setup guide](../../README.md); the vault-specific steps below are unique to this plugin.
```

- [ ] **Step 3: `dev-workflows/README.md` — add pointer just before `## Commands`**

`old_string`:
```markdown
## Commands
```
`new_string`:
```markdown
> Part of the `ihudak-plugins` marketplace — see the [repo-root setup guide](../../README.md) for marketplace install + prerequisites (env vars, `jira-workitem-import`, AI-Containers, first command).

## Commands
```

- [ ] **Step 4: Verify all 3 pointers + link targets**

```bash
cd /workspace/ihudak-claude-plugins
grep -l 'repo-root setup guide' plugins/dt-style-guide/README.md plugins/obsidian-llm-wiki/README.md plugins/dev-workflows/README.md
grep -c '(../../README.md)' plugins/dt-style-guide/README.md plugins/obsidian-llm-wiki/README.md plugins/dev-workflows/README.md
test -f README.md && echo "link target README.md EXISTS"
```
Expected: all 3 filenames listed; each shows `1`; link target exists.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dt-style-guide/README.md plugins/obsidian-llm-wiki/README.md plugins/dev-workflows/README.md
git commit -m "$(cat <<'EOF'
docs: point plugin READMEs at the repo-root setup guide

Add a one-line pointer to the repo-root setup guide from each plugin README's
install section, so there is one canonical marketplace-install + prerequisites source.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Refresh the stale command list in `CLAUDE.md`

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/CLAUDE.md` (the "Active plugin: dev-workflows" description, ~lines 30-35)

**Interfaces:**
- Independent of Tasks 1-2. Only the stale command/count description changes; the rest of `CLAUDE.md` is untouched.

- [ ] **Step 1: Replace the stale description**

`old_string`:
```markdown
`plugins/dev-workflows/` contains three commands (`/impl`, `/vuln`, `/upgrade`) plus a growing set of `/impl:*` subcommands (including `/impl:docs:profile`),
five agents, four hooks, and reference docs.

That count reflects the original bootstrap layout. The live `dev-workflows`
workflow now relies on a larger set of helper agents and workflow roles; see
the taxonomy and workflow map below.
```
`new_string`:
```markdown
`plugins/dev-workflows/` provides twenty slash commands — `/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/api-guideline-reviewer`, `/guideline-reviewer`, `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`, `/statusline`, and `/ready` — plus thirty reusable subagents, four hooks, and reference docs.

The live `dev-workflows` workflow relies on a larger set of helper agents and
workflow roles; see the taxonomy and workflow map below.
```

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -c '/impl:docs:profile' CLAUDE.md            # expect 0 (stale ref gone)
grep -c 'twenty slash commands' CLAUDE.md          # expect 1
grep -c '/ready' CLAUDE.md                          # expect >=1
grep -c '/create-ard' CLAUDE.md                     # expect >=1
```
Expected: `0`, `1`, `>=1`, `>=1`.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: refresh the stale dev-workflows command list in CLAUDE.md

Replace the original-bootstrap description (/impl, /vuln, /upgrade, /impl:docs:profile,
five agents) with the current 20-command / 30-subagent surface.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final structural verification (before finish-branch)

```bash
cd /workspace/ihudak-claude-plugins
echo "=== files changed vs main (expect 5: README + 3 plugin READMEs + CLAUDE.md) ==="
git diff --stat main...HEAD
echo "=== manifests/CHANGELOGs untouched (expect empty) ==="
git diff --stat main...HEAD -- '**/plugin.json' '.claude-plugin/marketplace.json' '**/CHANGELOG.md'
echo "=== no collateral (expect empty) ==="
git diff --stat main...HEAD -- plugins/dev-workflows/commands plugins/dev-workflows/agents plugins/dev-workflows/references plugins/dev-workflows/scripts
echo "=== versions unchanged ==="
python3 -c "
import json
mp=json.load(open('.claude-plugin/marketplace.json'))
def walk(o):
    if isinstance(o,list):
        for x in o: yield from walk(x)
    elif isinstance(o,dict):
        if 'name' in o and 'version' in o: yield o
        for v in o.values(): yield from walk(v)
v={p['name']:p['version'] for p in walk(mp)}
assert v.get('dev-workflows')=='2.26.0' and v.get('dt-style-guide')=='0.2.2' and v.get('obsidian-llm-wiki')=='0.3.1', v
print('OK versions unchanged:', v)
"
```
Expected: exactly 5 files changed (`README.md`, `plugins/dt-style-guide/README.md`, `plugins/obsidian-llm-wiki/README.md`, `plugins/dev-workflows/README.md`, `CLAUDE.md`); manifest/CHANGELOG and collateral diffs empty; versions unchanged.

Then hand off to **superpowers:finishing-a-development-branch** for the merge/PR choice (no test suite; structural verification above is the gate).

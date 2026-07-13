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
- **`SPECS_PATH`** — the shared, team-visible store for a ticket's `specification.md` / `design.md` / ARD under `specifications/<KEY>-<slug>/…`. Required by the specs-authoring commands (`/create-vi`, `/create-ard`, `/specify`, `/design`, `/ready`); advisory for `/implement`; additive for `/document`.
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

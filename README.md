# ihudak-claude-plugins

Ivan Gudak's private Claude Code plugin marketplace.

## Plugins

| Plugin | Description |
|--------|-------------|
| [dev-workflows](plugins/dev-workflows/) | `/impl` (dispatcher), `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`, `/api-guideline-reviewer`, `/guideline-reviewer` — Opus-backed planning, code review, product-docs review, Epic review, vulnerability remediation, dependency upgrades, API and UI guideline compliance |
| [dt-style-guide](plugins/dt-style-guide/) | Dynatrace corporate style guide enforcement: `/dt-review-pr`, `/dt-review-docs`, `/dt-style-refresh`, and sub-agents used by `dev-workflows` for style checking Epics and feature docs |
| [obsidian-llm-wiki](plugins/obsidian-llm-wiki/) | Ten slash commands for compiling Obsidian vault knowledge into a persistent, cross-referenced wiki with task management; supports Claude Code and GitHub Copilot |

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

### 3. Update after new releases

```bash
claude plugin marketplace update ihudak-plugins
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

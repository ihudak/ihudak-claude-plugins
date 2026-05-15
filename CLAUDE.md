# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

A private Claude Code plugin marketplace hosted at `github.com/ihudak/ihudak-claude-plugins`.
Registered in `~/.claude/plugins/known_marketplaces.json` as `ihudak-plugins`.

## Structure

```
.claude-plugin/marketplace.json   ← plugin catalog (do not reformat; Claude Code parses it)
plugins/
  <plugin-name>/
    .claude-plugin/plugin.json    ← required: name, description, author
    README.md
    LICENSE
    commands/                     ← slash commands (.md files)
    agents/                       ← subagent system prompts (.md files, YAML frontmatter required)
    hooks/
      hooks.json                  ← hook declarations; use ${CLAUDE_PLUGIN_ROOT} for paths
      *.sh                        ← hook scripts
    skills/                       ← skills (.md files), if any
    references/                   ← vendored reference docs the commands consult
```

## Active plugin: dev-workflows

`plugins/dev-workflows/` contains three commands (`/impl`, `/vuln`, `/upgrade`),
five agents, three hooks, and reference docs.

**Internal path convention:** all paths inside command/agent/hook files use
`~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/` as the root prefix.
This is where Claude Code installs the plugin's content.

**When editing `dev-workflows`:** update the files in `plugins/dev-workflows/` directly.
Do NOT edit `~/.claude/claude-config/` — that repo is retired and will be deleted.

## Adding a new plugin

1. Create `plugins/<name>/` with `.claude-plugin/plugin.json`.
2. Add content directories (`commands/`, `agents/`, `hooks/`, etc.).
3. For hooks: create `hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}` for all paths.
4. Register in `.claude-plugin/marketplace.json` with `"source": "./plugins/<name>"`.
5. Commit and push to `main`. Claude Code picks up changes on next sync/reinstall.

## Conventions

- Agent `.md` files must start with YAML frontmatter (`---`) containing at minimum `name` and `description`.
- Hook scripts must exit 0 — they must never block Claude.
- `hooks.json` `matcher` field (for PostToolUse) goes at the entry level, not inside the hook object.
- All paths in plugin content use `~/.claude/plugins/data/<plugin>@ihudak-claude-plugins/` — never hardcode `~/.claude/` subdirectories directly.
- MIT license applies to all plugins unless a plugin directory has its own LICENSE file.

## Git

- `origin` → `git@github-ig.com:ihudak/ihudak-claude-plugins.git`
- Default branch: `main`

# obsidian-llm-wiki — GitHub Copilot Instructions

LLM Wiki pattern for an active Obsidian vault. Compiles knowledge from meetings,
projects, daily notes, and raw sources into a persistent, cross-referenced wiki at
`wiki/`. Supports both Claude Code and GitHub Copilot as first-class agents. Wiki
sessions from both agents accumulate into the same wiki — switching between them
mid-project is seamless.

---

## Vault Path

Default vault: `~/obsidian_vault` (Linux/Mac). WSL users with vault on Windows side must set
`VAULT_PATH=/mnt/c/Users/<name>/obsidian_vault`. Override with the `VAULT_PATH` env var.

All file paths in skill instructions are relative to the vault root unless they start
with `skills/` (which are relative to this plugin's installation directory).

---

## Hot Cache — Automatic via Hooks

`wiki/hot.md` is managed automatically by plugin hooks:
- **SessionStart** — hot.md is read silently and injected as context
- **Stop** — the agent is prompted to update hot.md before ending the session

No manual steps needed. Note: Claude Code also re-injects hot.md after context
compaction (PostCompact hook); Copilot CLI has no equivalent — hot cache context
may be lost during automatic compaction.
To force a hot cache refresh mid-session, run `/wiki-hot`.

---

## Wiki Schema

Before any wiki operation, read `skills/wiki-schema/SKILL.md` for the full vault
conventions: three-layer source model, page types, frontmatter schemas, tag rules,
cross-linking rules, and file formats.

---

## Commands

| Slash command | Description |
|---------------|-------------|
| `/wiki-ingest @filepath` | Ingest one source file into the wiki |
| `/wiki-scan [directory]` | Scan directory for unprocessed files, batch-ingest new/changed |
| `/wiki-query <question>` | Answer from the compiled wiki with citations |
| `/wiki-save` | Save current conversation as a wiki page |
| `/wiki-lint` | Run wiki health check, produce lint report |
| `/wiki-hot` | Manually refresh the hot cache |
| `/wiki-tags-refresh` | Sync wiki tags with vault's tag-index.md |
| `/wiki-task <description>` | Create a single task from natural language (effort, tags, priority, dates) |
| `/wiki-tasks-extract [wiki-path]` | Batch-extract tasks from wiki content after ingest |
| `/wiki-init` | Initialize or re-initialize vault integration (first run or after plugin update) |

Both Copilot and Claude Code use the same `/wiki-*` slash commands with identical
behaviour. No agent-specific forms are needed.

When the user types any of these commands, read the corresponding skill file fully
before executing. Skill files are at `skills/<skill-name>/SKILL.md` relative to the
plugin installation directory.

---

## Boundary Rules

Wiki operations MUST NEVER write to or delete files from:
`Meetings/`, `Daily/`, `Projects/`, `Customers/`, `People/`, `Clippings/`, `Research/`

The wiki layer reads these directories. It never modifies them.

The only directory wiki may clean up is `.raw/` — by moving processed files to
`.raw/_processed/YYYY-MM/` after successful ingest.

Two commands — `/wiki-task` and `/wiki-tasks-extract` — intentionally write outside
the wiki directory (to `Projects/` files and `Tasks.md`). These are the only wiki
commands allowed to modify files outside `wiki/` and `.raw/`.

---

## Tags

Only use tags from `.obsidian/copilot/tag-index.md`. Never invent new tags. If a
concept needs a tag that does not exist, flag it with `tag-needed: <proposed>` in the
log entry and let the user approve it via `/wiki-tags-refresh`.

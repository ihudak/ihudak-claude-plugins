# Changelog

All notable changes to the **obsidian-llm-wiki** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [0.4.0]

### Changed
- `wiki-tags-refresh` now scans the entire vault by default (excludes `.obsidian/`)
  instead of only `wiki/`, and accepts an optional `[directory]` argument to scope
  the scan. The stale-tag removal check always re-verifies vault-wide usage before
  suggesting removal, excluding only `tag-index.md` itself (not all of `.obsidian/`)
  so genuine uses elsewhere in `.obsidian/` still protect a tag from removal.
  Ported from the `ihudak-copilot-plugins` sibling repo; updated `wiki-schema` and
  the `wiki-init` vault-doc templates to match.

### Fixed
- `wiki-tags-refresh`'s file-collection scan no longer breaks on vault filenames
  containing spaces (`find | xargs awk` now uses `-print0`/`xargs -0`).
- `wiki-tags-refresh`'s inline-tag collection actually returns results now — the
  previous `grep -v "^#"` filter discarded every match, since `grep -oh` only ever
  emits strings that already start with `#` (pre-existing bug, now fixed).
- `wiki-tags-refresh`'s stale-tag check now uses an exact tag match instead of an
  unanchored substring match, so `#api` no longer false-matches `#api/rest`.
- Grep flags in `wiki-tags-refresh` are now placed before the pattern/path operands
  for portability to non-GNU (BSD/macOS) grep.

## [0.3.1]

### Fixed
- Corrected README/CHANGELOG install-path references to point at the actual
  `~/.claude/plugins/cache/<marketplace>/...` location (was the non-resolving
  `~/.claude/plugins/data/...@.../` form).

## [0.3.0]

### Added
- **wiki-task** command & skill — create individual tasks from natural language
  with effort estimation, tagging, and Jira linking in Obsidian Tasks format.
- **wiki-tasks-extract** command & skill — batch-extract tasks from wiki content
  after ingest.

## [0.2.0]

### Changed
- Ported from standalone Claude Code config to marketplace plugin format.
- Skills use SKILL.md with YAML frontmatter.
- Orchestrator skills declare `allowed-tools:` in frontmatter.
- Path references use `${CLAUDE_PLUGIN_ROOT}/` (agents/skills/hooks) or `~/.claude/plugins/cache/<marketplace>/obsidian-llm-wiki/<version>/` (installed content).
- Hooks: `SessionStart`, `PostCompact`, and `Stop` via `hooks.json`.

## [0.1.0]

### Added
- Initial release with nine commands & skills: wiki-init, wiki-ingest, wiki-scan,
  wiki-query, wiki-save, wiki-lint, wiki-hot, wiki-tags-refresh, wiki-schema.
- Hooks: `SessionStart` and `Stop` via `hooks.json`.
- AGENTS.md for GitHub Copilot compatibility.
- CLAUDE.md with vault-path configuration and command reference.

# Changelog

## [0.2.3] - 2026-07-17

- Synced curated terminology from the `mgd-specifications` `dynatrace-content-style`
  digest (additive; no existing entries changed): `timeframe selector`, `Strato Design
  System`, `around the clock` (replaces `24/7` / `24x7`), `Dynatrace Operator`,
  `Hosts page`, `Synthetic Monitoring` vs. `Digital Experience Management`,
  `network zone`, `Full-Stack Monitoring`, `Premium High Availability add-on`,
  `Dynatrace web UI` vs. `interface`.

## 0.2.2

- Updated `/dt-review-pr` `--repo` examples from `/repos/dynatrace-docs` to
  `/workspace/dynatrace-docs` to match the AI container's single-umbrella mount
  layout.

## 0.2.1

- Fixed agent/skill/command references to use `${CLAUDE_PLUGIN_ROOT}` instead of the
  non-resolving `~/.claude/plugins/data/...@.../` path convention; `dt-style-checker`
  is now invoked by `subagent_type` where called cross-plugin.

## 0.2.0

- Added `/dt-review-pr` command — reviews doc changes from a pull request
- Added `/dt-review-docs` command — reviews files/directories with optional `--fix`
- Added `dt-doc-fixer` agent — applies safe mechanical fixes for style violations
- Added `checker_source` field to `dt-style-checker` output for cross-plugin disambiguation
- Documented integration with `dev-workflows` (`docs-style-checker` fallback + Epic primary)

## 0.1.0

- Initial release
- `dt-style-checker` agent — LLM-based Dynatrace style guide checker
- `dt-style-rules` skill — writing aid for agents producing Dynatrace content
- `/dt-style-refresh` command — updates vendored references from styleguide.dynatrace.com
- 8 vendored reference docs (terminology, word-list, voice-and-tone, grammar, formatting, ui-interactions, accessibility, top-10-tips)

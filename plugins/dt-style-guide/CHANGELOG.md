# Changelog

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

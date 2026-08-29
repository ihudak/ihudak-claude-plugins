# Changelog

## 0.3.0

### BREAKING

The plugin, its commands, and its agents have been renamed, and the vendored corporate
style guide has been replaced by a vendor-neutral baseline with a pluggable overlay.
**Every old name is gone — there are no aliases and no deprecation period.** Update any
caller before upgrading.

| Old name | New name |
|---|---|
| plugin `dt-style-guide` | plugin `prose-style` |
| agent `dt-style-checker` | agent `prose-style-checker` |
| agent `dt-doc-fixer` | agent `prose-fixer` |
| command `/dt-review-pr` | command `/prose-review-pr` |
| command `/dt-review-docs` | command `/prose-review-docs` |
| command `/dt-style-refresh` | command `/prose-style-refresh` |
| skill `dt-style-rules` | skill `prose-style-rules` |
| rule prefix `DT.*` | rule prefix `Prose.*` |
| output `checker: dt-style-guide` | output `checker: prose-style` |
| output `checker_source: dt-style-checker` | output `checker_source: prose-style-checker` |

Individual rule identifiers changed with the prefix, and several were renamed for
neutrality — `DT.WordList.BannedWord` is now `Prose.WordList.ExcludedWord`,
`DT.WordList.BritishSpelling` is now `Prose.WordList.SpellingVariant`, and
`DT.Accessibility.RacistTerm` is now `Prose.Accessibility.ExcludedTerm`. Anything
matching on rule strings needs updating.

### Added

- **Overlay mechanism.** The plugin now resolves an organization's own style guide on
  top of the shipped baseline. Resolution order, first hit wins: the `rules_path` input
  (`--rules <path>` on the review commands) → `<repo-root>/.prose-style/rules/` →
  `$PROSE_STYLE_PATH` → no overlay. The baseline at `${CLAUDE_PLUGIN_ROOT}/references/`
  is always loaded underneath.
- **Documented precedence.** The overlay augments and overrides the baseline per file
  name: both are in force, the overlay wins on conflict, an `## Allowed` section
  suppresses a baseline rule, a file whose first line is `<!-- prose-style: replace -->`
  supersedes its baseline counterpart outright, and a file with an unmatched name is an
  additional rule source.
- **Silent fallback as a hard rule.** Every resolution miss — missing directory, unset
  variable, unreadable path, no markdown inside — falls through without an error,
  warning, or prompt. The overlay is never a gate. Only a missing baseline *and* no
  overlay is an error.
- **`rules_source` output field** on `prose-style-checker` (`baseline` or
  `overlay:<path>`), surfaced as a one-line `Rules:` entry in both review commands.
- **`--rules <path>`** on `/prose-review-pr` and `/prose-review-docs`, for a one-off
  overlay override.
- **Entry schemas** in `references/word-list.md` and `references/terminology.md`, so an
  organization can declare its own terms, product names, trademarks, deprecated terms,
  severity overrides, and allowed exceptions in tables the checker reads structurally.
- **Prose-accessibility rules** grounded in WCAG 2.2 — alt text (1.1.1), link text
  (2.4.4, 2.4.9), sensory-only instructions (1.3.3), color-only signals (1.4.1), heading
  structure (1.3.1, 2.4.6), abbreviations (3.1.4) — with the matching
  `Prose.Accessibility.*` rules.

### Changed

- **The eight reference docs were rewritten from scratch as a vendor-neutral baseline**,
  grounded in public authorities named in each file: the Microsoft Writing Style Guide,
  the Google developer documentation style guide, the Apple Style Guide, The Chicago
  Manual of Style and AP, the Conscious Style Guide, plainlanguage.gov, and W3C WCAG 2.2.
  Where two authorities disagree — the serial comma, spaced em dashes, "click" vs.
  "select", US vs. non-US spelling — the baseline picks one, names the split, and marks
  it as an overlay point.
- **`/prose-style-refresh` refreshes from your configured source**, declared in
  `<overlay>/source.yml` (web URLs, a git repository, or a local directory) or passed as
  `--source` / `--from`. It carries no hardcoded style-guide URL: with nothing
  configured it asks. It writes into the overlay directory and **never** into the shipped
  baseline, which fixes the old command's central flaw — refreshed rules used to land in
  the plugin's install directory and vanish on the next reinstall.
- `prose-fixer` now applies the `suggestion` it is handed and never re-derives a rule, so
  an overlay override reaches the fix unchanged. It also skips text inside bolded UI
  labels, which are quotations of the product.
- Severity calibration gained rows for prose accessibility and for vague/inflated
  language, and the trademark row now never fires when the active rule set declares no
  marks.
- `README.md` rewritten around the overlay, with a worked example.

### Removed

- All Dynatrace product, solution, app, SKU, and license terminology, and the
  Dynatrace-specific pitfall table. The baseline ships **no** organization-specific
  terms by design; `terminology.md` now holds naming rules plus the schema for
  declaring your own.
- The registered-trademark inventory. Trademark handling is still enforced, but only
  against marks the active rule set declares.
- The hardcoded `styleguide.dynatrace.com` URL map in the refresh command.
- Entries with no defensible neutral equivalent: "around the clock" for 24/7, and
  `timeframe` as one word (standard English is two).

## 0.2.4

### Fixed

- **Stale `dev-workflows` command names and phase numbers.** `README.md` "How it fits with
  dev-workflows" and `agents/dt-style-checker.md` "When to invoke" still referenced the retired
  `/impl:jira:docs` / `/impl:jira:epics` / `/impl` names and a non-existent "Phase 6.7". Corrected to
  `/document` (Jira mode) **Phase 6.4** and `/epics` **Phase 6.2**, and the `/document` mechanism
  restated accurately: `docs-style-checker` runs the primary linter **and** `dt-style-checker` as a
  complementary pass internally, merging both finding sets — `/document` never invokes
  `dt-style-checker` separately, and `NOT_CONFIGURED` means neither was available. Also names the other
  direct callers (`/create-vi`, `/update-vi`, `/release-notes`).

## 0.2.3

- Synced curated terminology from the `mgd-specifications` `dynatrace-content-style`
  digest: `timeframe selector`, `Strato Design System`, `around the clock` (replaces
  `24/7` / `24x7`), `Dynatrace Operator`, `Hosts page`, `Synthetic Monitoring` vs.
  `Digital Experience Management`, `network zone`, `Full-Stack Monitoring`,
  `Premium High Availability add-on`, `Dynatrace web UI` vs. `interface`,
  `Health overview`.
- Corrected `timeframe` to one word (was listed as `time frame` in `word-list.md`),
  matching the curated digest, current Dynatrace product usage, and the added
  `timeframe selector` term — resolves a prior word-list-vs-digest contradiction.

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

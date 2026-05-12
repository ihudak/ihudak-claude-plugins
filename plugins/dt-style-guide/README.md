# dt-style-guide

Dynatrace corporate style guide plugin for Claude Code.

## What it does

Enforces Dynatrace terminology, trademarks, voice/tone, grammar, and formatting
rules when writing planning and product documents — Epics, PRDs, ARDs, product
documentation, and any other content that should follow the
[Dynatrace Style Guide](https://styleguide.dynatrace.com/).

## Components

| Component | Type | Purpose |
|---|---|---|
| 8 reference docs | `references/` | Vendored, distilled rules from styleguide.dynatrace.com |
| `dt-style-checker` | agent | Checks files against rules; outputs violations in the `docs-style-checker` schema |
| `dt-style-rules` | skill | Writing aid — loadable by any agent producing Dynatrace content |
| `/dt-style-refresh` | command | Updates vendored references from styleguide.dynatrace.com |

## How it fits with dev-workflows

This plugin is a **fallback** for the `docs-style-checker` agent in `dev-workflows`:

- **`/impl:jira:docs`** Phase 6.7 invokes `docs-style-checker` first (wraps the repo's
  own Vale/markdownlint). If that returns `NOT_CONFIGURED`, it falls back to
  `dt-style-checker` from this plugin.
- **`/impl:jira:epics`** Phase 6.7 invokes `dt-style-checker` directly (Epic drafts
  are vault-internal and have no repo linter).
- **Future PRD/ARD commands** can invoke `dt-style-checker` and/or load
  `dt-style-rules` without depending on `dev-workflows`.

## Reference docs

The `references/` directory contains distilled, actionable rules — not verbatim copies —
from the Dynatrace style guide. Each file covers one topic:

| File | Source pages |
|---|---|
| `terminology.md` | Dynatrace terminology, trademarks |
| `word-list.md` | Word list, words to avoid |
| `voice-and-tone.md` | Voice and tone |
| `grammar.md` | Grammar |
| `formatting.md` | Numbers, punctuation, lists, titles/headings, acronyms, dates |
| `ui-interactions.md` | UI interactions |
| `accessibility.md` | Inclusive language, internationalization |
| `top-10-tips.md` | Top 10 tips (quick checklist) |

## Keeping references current

Run `/dt-style-refresh` to fetch the latest content from `styleguide.dynatrace.com`
and update the vendored references. The refresh command shows a diff of what changed.

## Violation schema

`dt-style-checker` outputs violations identical to `docs-style-checker`, so `doc-fixer`
can process them:

```yaml
file:       <absolute path>
line:       <line number>
rule:       DT.<Category>.<RuleName>
severity:   BLOCKER | MAJOR | MINOR | NIT
message:    <human-readable description>
suggestion: <proposed fix>
```

Rule prefixes: `DT.Terminology`, `DT.WordList`, `DT.VoiceTone`, `DT.Grammar`,
`DT.Formatting`, `DT.UI`, `DT.Accessibility`.

## Installation

This plugin is part of the `ihudak-plugins` marketplace. Install via Claude Code's
plugin system — it will be available alongside `dev-workflows`.

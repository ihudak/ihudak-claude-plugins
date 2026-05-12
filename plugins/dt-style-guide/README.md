# dt-style-guide

Dynatrace corporate style guide plugin for Claude Code.

## What it does

Enforces Dynatrace terminology, trademarks, voice/tone, grammar, and formatting
rules when writing and reviewing product documentation, planning documents
(Epics, PRDs, ARDs), and any other content that should follow the
[Dynatrace Style Guide](https://styleguide.dynatrace.com/).

## Components

| Component | Type | Purpose |
|---|---|---|
| 8 reference docs | `references/` | Vendored, distilled rules from styleguide.dynatrace.com |
| `dt-style-checker` | agent | Checks files against rules; outputs violations in the `docs-style-checker` schema |
| `dt-doc-fixer` | agent | Applies safe, mechanical fixes for violations found by dt-style-checker |
| `dt-style-rules` | skill | Writing aid — loadable by any agent producing Dynatrace content |
| `/dt-review-pr` | command | Reviews doc changes from a pull request (by PR ID or branch name) |
| `/dt-review-docs` | command | Reviews markdown files at a path; supports `--fix` for auto-correction |
| `/dt-style-refresh` | command | Updates vendored references from styleguide.dynatrace.com |

## Commands

### `/dt-review-pr` — Review PR documentation changes

Reviews the markdown files changed in a pull request against the Dynatrace
style guide. Works with Bitbucket-style merge commits (finds PRs by number in
`git log`) and also accepts source branch names directly.

**Usage:**

```
/dt-review-pr 9089
/dt-review-pr 9089 --repo /repos/dynatrace-docs
/dt-review-pr alexander-huetter/noissue-improve-managed-docs
/dt-review-pr my-branch --doc-type product-docs
```

**Arguments:**

| Argument | Description |
|---|---|
| `<PR number>` | Finds the merge commit or remote branch for that PR |
| `<branch name>` | Diffs the branch against `main` |
| `--repo <path>` | Override the repo path (default: current working directory) |
| `--doc-type <type>` | Severity calibration: `product-docs` (default), `epic`, `prd`, `ard`, `general` |

**What it does:**
1. Finds changed `.md` files from the PR diff.
2. Runs `dt-style-checker` on those files.
3. Runs Vale if `.vale.ini` is present in the repo and Vale is installed.
4. Reports violations with file, line, severity, and suggested fix.
5. Shows violations in diff context so you see what changed alongside what violated.
6. Offers to auto-fix via `dt-doc-fixer`.

### `/dt-review-docs` — Review documentation files or directories

Reviews one or more markdown files (or a whole directory tree) against the
Dynatrace style guide. Optionally applies safe automatic fixes.

**Usage:**

```
/dt-review-docs docs/get-started/
/dt-review-docs docs/get-started/index.md
/dt-review-docs docs/setup/ docs/config/auth.md
/dt-review-docs docs/ --fix
/dt-review-docs docs/ --severity MINOR
/dt-review-docs docs/ --doc-type product-docs --fix
```

**Arguments:**

| Argument | Description |
|---|---|
| `<path>` | File or directory path (multiple allowed; directories are recursive) |
| `--fix` | After reviewing, apply safe mechanical fixes via `dt-doc-fixer` |
| `--doc-type <type>` | Severity calibration (default: `product-docs`) |
| `--severity <level>` | Only report violations at this level or above (default: show all) |

**What it does:**
1. Recursively finds all `.md` files in the specified path(s).
2. Runs `dt-style-checker` on those files.
3. Runs Vale if available.
4. Reports violations grouped by file.
5. With `--fix`: applies safe fixes via `dt-doc-fixer`, then re-checks to verify.

### `/dt-style-refresh` — Update vendored references

Fetches the latest rules from `styleguide.dynatrace.com` and updates the
vendored reference docs. Run when the style guide has been updated.

> **Note:** `/dt-style-refresh` updates the **runtime** copy at
> `~/.claude/plugins/data/dt-style-guide@ihudak-claude-plugins/references/`.
> These changes are lost on the next plugin reinstall. To persist updates,
> copy the refreshed files back into the plugin source at
> `plugins/dt-style-guide/references/` and commit.

## How it fits with dev-workflows

This plugin is a **fallback** for the `docs-style-checker` agent in `dev-workflows`:

- **`/impl:jira:docs`** Phase 6.7 invokes `docs-style-checker` first (wraps the repo's
  own Vale/markdownlint). If that returns `NOT_CONFIGURED`, it falls back to
  `dt-style-checker` from this plugin.
- **`/impl:jira:epics`** Phase 6.7 invokes `dt-style-checker` directly (Epic drafts
  are vault-internal and have no repo linter).
- **`/dt-review-pr` and `/dt-review-docs`** are standalone — invoke them directly
  without going through the `/impl` pipeline.

## Agents

### `dt-style-checker`

Read-only checker. Takes a list of file paths and a doc type, returns violations
in the standard schema. Never modifies files.

### `dt-doc-fixer`

Fix agent. Takes violations from `dt-style-checker` and applies safe, mechanical
fixes — terminology swaps, banned-word replacements, British→American spelling,
UI interaction terms. Skips anything ambiguous (voice/tone rewrites, heading
changes, serial commas). Reports what was fixed and what was left for manual review.

**Fixable categories:** terminology, deprecated terms, banned words, British
spelling, wrong compounds, ableist/racist terms, banned contractions, number
formatting, UI interaction terms (click→select, navigate→go to, log in→sign in).

**Unfixable (skipped):** passive voice, hedge words, patronising language, heading
text changes, serial commas, registered trademark symbols.

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

## Violation schema

Both `dt-style-checker` and `dt-doc-fixer` use this schema (compatible with
`docs-style-checker` from dev-workflows):

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

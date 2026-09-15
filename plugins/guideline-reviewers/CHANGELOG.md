# Changelog

All notable changes to the **guideline-reviewers** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.0.1] — 2026-09-15

### Fixed — the overlay variables are written with one `$`

Both agents' rule-overlay tables named their third rung `$$UI_GUIDELINES_PATH` and `$$API_GUIDELINES_PATH`, and both command pages copied it. Run by bash, `$$` is the shell's own process id, so the rung an agent transcribed literally tested a directory named like `188847UI_GUIDELINES_PATH`, which never exists — and a miss at that rung falls through silently to the bundled baseline, which is what the rung is designed to do, so an overlay set through either variable was never read and nothing said so. All four sites now read `$UI_GUIDELINES_PATH` and `$API_GUIDELINES_PATH`, as the commands and `docs/reference/environment.md` already did.

### Fixed — each linter runs in the reviewed project, not in the session's directory

Both agents ran their linter bare — `npx --no-install eslint`, or the repository's lint script, and `spectral` / `npx --no-install @stoplight/spectral-cli` — and a subagent's Bash tool starts every call in the session's directory, which need not be the reviewed repository. `npx --no-install` resolves its tool from the directory it runs in, so from anywhere else it printed *"npx canceled due to missing packages"* and the lint was skipped as a missing binary — a silent `a11y_check: none` or `lint_source: none` — or it ran under another repository's configuration. A monorepo whose packages keep their own linter was skipped even with the session at its top level. Each agent now partitions the files it reviews and runs each partition's probes and its one lint from that partition's directory, each as one `(cd "<dir>" && …)` subshell, merging the findings, each keyed by its file, so files reviewed together from two packages are each linted in their own; the report carries one `a11y_check` or `lint_source` line per partition where the files span more than one, each naming its directory.

- **`guideline-reviewer`** partitions by each file's nearest package directory — the nearest directory at or above it, up to its repository's git top level, that holds a `package.json`, else the top level — which is where Node resolves the project's ESLint, and lets ESLint find its own configuration, looking upward from there. Whether `eslint-plugin-jsx-a11y` applies is read from the configuration ESLint resolves for the files (`eslint --print-config`), never from one directory's `package.json` or config file: a `package.json` that merely declares ESLint is not a configuration, and a package config that `extends` a shared one need never name the plugin. The runtime-harness check reads every `package.json` from the partition's directory up to the top level.
- **`api-guideline-reviewer`** partitions by the nearest directory holding a Spectral ruleset or a `package.json` declaring the CLI, else the top level — the rule `docs-workflows`' `docs-style-checker` and `prose-style`'s `/prose-review-pr` and `/prose-review-docs` already follow for Vale — and its ruleset is the nearest `.spectral.*` up to the top level, no longer only one at the repository's root. Spectral lints each partition's specs in one run, where it ran once per spec.

A repository that keeps its linter configuration only at its top level, reviewed with the session standing in it, gets the same findings as before.

## [1.0.0] — 2026-09-02

### Added — extracted from `dev-workflows` 3.25.0

`/api-guideline-reviewer` and `/guideline-reviewer`, their two agents, and the 38 reference files they read shipped as part of `dev-workflows` through its 3.25.0 release. This plugin carries all of it forward unchanged: both commands behave exactly as they did there — same flags, same resolution order, same bundled guidance corpora, same overlay mechanism (`$UI_GUIDELINES_PATH` / `$API_GUIDELINES_PATH`, still overlaid at `<repo-root>/.dev-workflows/{ui,api}-guidelines/`, unchanged so an existing overlay keeps resolving). Only the install location and the command prefix moved: `/dev-workflows:guideline-reviewer` is gone, and the bare command names keep working once this plugin is installed alongside or instead of `dev-workflows`.

This is the first increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md`. See `dev-workflows`'s own `CHANGELOG.md` 3.25.0 entry for what stayed behind and why these two commands were the right thing to extract first.

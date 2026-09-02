# Changelog

All notable changes to the **guideline-reviewers** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.0.0] — 2026-09-02

### Added — extracted from `dev-workflows` 3.25.0

`/api-guideline-reviewer` and `/guideline-reviewer`, their two agents, and the 38 reference files they read shipped as part of `dev-workflows` through its 3.25.0 release. This plugin carries all of it forward unchanged: both commands behave exactly as they did there — same flags, same resolution order, same bundled guidance corpora, same overlay mechanism (`$UI_GUIDELINES_PATH` / `$API_GUIDELINES_PATH`, still overlaid at `<repo-root>/.dev-workflows/{ui,api}-guidelines/`, unchanged so an existing overlay keeps resolving). Only the install location and the command prefix moved: `/dev-workflows:guideline-reviewer` is gone, and the bare command names keep working once this plugin is installed alongside or instead of `dev-workflows`.

This is the first increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md`. See `dev-workflows`'s own `CHANGELOG.md` 3.25.0 entry for what stayed behind and why these two commands were the right thing to extract first.

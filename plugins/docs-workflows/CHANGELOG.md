# Changelog

All notable changes to the **docs-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.0.0] — 2026-09-05

### Added — registered as an empty, gate-green skeleton

This is Task 1 of the third increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md` (the first increment extracted `guideline-reviewers`, the second `workflows-core`). It creates `docs-workflows`, registers it in the marketplace catalog, and ships it installable like any other plugin here — but empty by design: 0 slash commands, 0 agents, 0 reference files, 0 bundled skills. That proves the documentation and catalog gates pass on the plugin before any content is at stake.

Later tasks in this increment move `/document`, `/docs-profile` and `/release-notes` into it, along with their seven agents and fourteen reference files, unchanged — citations to the shared `workflows-core` corpus are rewritten as each file moves, not afterwards. `dev-workflows`'s own `CHANGELOG.md` records the corresponding move from its side once those tasks land.

# Changelog

All notable changes to the **workflows-core** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.0.0] — 2026-09-02

### Added — registered as an empty, gate-green skeleton

This is Task 1 of the second increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md` (the first increment extracted `guideline-reviewers`). It creates `workflows-core`, registers it in the marketplace catalog, and ships it installable like any other plugin here — but empty by design: 0 slash commands, 0 agents, 0 reference files, 0 bundled skills. That proves the documentation and catalog gates pass on the plugin before any content is at stake.

Later tasks in this increment move the shared foundation of the `dev-workflows` plugin family into it unchanged — the addressing grammar, specs-repo git entry points, phase handoff, model routing, escalation and finding-triage rules, cost/feedback/follow-up emission, the reference loader skill, and the family-meta utility commands (`/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`, `/statusline`, and `/frames`) — with no behavior change to any of them. `dev-workflows`'s own `CHANGELOG.md` records the corresponding move from its side once those tasks land.

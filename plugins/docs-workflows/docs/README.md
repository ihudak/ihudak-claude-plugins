# docs-workflows documentation

| I want to… | Go to |
|---|---|
| install this and set it up | [Getting started](getting-started.md) |
| see how the three commands fit together | [Workflow overview](workflow.md) |
| document a feature from its PRD and its shipped diffs | [`/document`](commands/document.md) |
| make a one-off prose edit in a docs repo | [`/document`](commands/document.md) — direct mode |
| teach this plugin what a docs repository looks like | [`/docs-profile`](commands/docs-profile.md) |
| draft the note that announces a change | [`/release-notes`](commands/release-notes.md) |
| understand what a run cost | [Session cost](reference/session-cost.md) |

Two pages orient you before you touch a command: [Getting started](getting-started.md) installs the plugin and sets the environment variables it reads, and [Workflow overview](workflow.md) shows the three commands as one diagram, including the two modes of `/document`. Every other page below documents one command, one shared subsystem, or one whole inventory.

## Commands

- [`/docs-profile`](commands/docs-profile.md) — scan a documentation repository and write or refresh the machine-readable profile `/document` consumes, as a reviewable pull request.
- [`/document`](commands/document.md) — write or update product documentation: a one-shot direct edit, or the full keyed feature-documentation workflow.
- [`/release-notes`](commands/release-notes.md) — draft a release-notes Summary for a resolved PRD, shaped by the destination it resolves to.

## Reference

- [Agents](reference/agents.md) — the subagent inventory: what each of the seven agents does and which command dispatches it.
- [References](reference/references.md) — the reference-doc inventory under `references/`, grouped by concern.
- [Skills](reference/references.md#skills) — the one bundled skills entry, `docs-frontmatter`: what it is for, and whether it is user-invocable.
- [Environment](reference/environment.md) — every environment variable the plugin reads, and what it configures.
- [Hooks](reference/hooks.md) — the two bundled hooks and what each one does.
- [Session cost](reference/session-cost.md) — which commands here emit a cost entry, what they charge to, and where the file lands.

## Where the rest lives

This plugin is the documentation half of a family. Three sibling plugins matter to it — two it declares as dependencies, and one whose output it reads without depending on:

- **`workflows-core`** — the shared reference corpus every command here loads through the `reference` skill (addressing, the specs-repo git and phase-handoff entry points, model routing, escalation and finding triage, cost/feedback/follow-up emission, docs grounding, doc-structure conventions, the PRD format), plus the `doc-fixer` and `impl-maintenance` agents these commands dispatch. It is a declared dependency, so installing this plugin installs it.
- **`prose-style`** — the complementary semantic prose pass `docs-style-checker` runs alongside the repo's own linter, and the fallback linter when a repo configures none. Also a declared dependency.
- **`dev-workflows`** — the pipeline that produces what `/document` reads: the idea, the PRD, the Epics, the specification, the design, and the implementation whose diffs a keyed run summarises. It is *not* a dependency in either direction; this plugin installs and runs without it, against a specs tree someone else filled in.

## Status

This plugin ships 3 slash commands, 7 agents, 14 reference files and 2 hooks — and it ships one bundled skills entry, `docs-frontmatter`. All of it moved here unchanged from `dev-workflows` in the third increment of the marketplace split: the commands behave exactly as they did, and only the namespace they answer to and the way they reach the shared corpus have changed. The `preload-context` hook is the one thing that was split rather than moved, because `dev-workflows` still needs its half.

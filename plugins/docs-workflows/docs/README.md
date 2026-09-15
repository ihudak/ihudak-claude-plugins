# docs-workflows documentation

| I want to… | Go to |
|---|---|
| install this and set it up | [Getting started](getting-started.md) |
| see how the six commands fit together | [Workflow overview](workflow.md) |
| start documenting a project that has no docs | [`/docs-init`](commands/docs-init.md) |
| document a feature from its PRD and its shipped diffs | [`/document`](commands/document.md) |
| make a one-off prose edit in a docs repo | [`/document`](commands/document.md) — direct mode |
| teach this plugin what a docs repository looks like | [`/docs-profile`](commands/docs-profile.md) |
| pick up a logo and brand colours from the product's own code | [`/docs-brand`](commands/docs-brand.md) |
| serve the docs and get a URL to open in a browser | [`/docs-serve`](commands/docs-serve.md) |
| draft the note that announces a change | [`/release-notes`](commands/release-notes.md) |
| keep internal pages out of a published documentation site | [Documentation visibility](reference/docs-visibility.md) |
| understand what a run cost | [Session cost](reference/session-cost.md) |

Two pages orient you before you touch a command: [Getting started](getting-started.md) installs the plugin and sets the environment variables it reads, and [Workflow overview](workflow.md) shows the six commands as one diagram, including the two modes of `/document`. Every other page below documents one command, one shared subsystem, or one whole inventory.

## Commands

- [`/docs-init`](commands/docs-init.md) — scaffold a documentation repository for a project that has none: a product-shaped page skeleton with a stub in every section, two builds over one content root, Vale, a CI workflow with the visibility gates, and the profile `/docs-serve`, `/document` and `/docs-brand` read.
- [`/docs-profile`](commands/docs-profile.md) — scan a documentation repository and write or refresh the machine-readable profile `/document` consumes, as a reviewable pull request.
- [`/docs-brand`](commands/docs-brand.md) — extract a logo and a rough primary/accent colour pair from a product's own code and apply them to the docs site, standalone or `--inline` from `/docs-init`.
- [`/docs-serve`](commands/docs-serve.md) — start, stop, or check a profiled repo's dev server, and report a URL that actually opens from the host.
- [`/document`](commands/document.md) — write or update product documentation: a one-shot direct edit, or the full keyed feature-documentation workflow.
- [`/release-notes`](commands/release-notes.md) — draft a release-notes Summary for a resolved PRD, shaped by the destination it resolves to.

## Reference

- [Agents](reference/agents.md) — the subagent inventory: what each of the eight agents does and which command dispatches it.
- [References](reference/references.md) — the reference-doc inventory under `references/`, grouped by concern.
- [Skills](reference/references.md#skills) — the one bundled skills entry, `docs-frontmatter`: what it is for, and whether it is user-invocable.
- [Environment](reference/environment.md) — every environment variable the plugin reads, and what it configures.
- [Hooks](reference/hooks.md) — the two bundled hooks and what each one does.
- [Documentation visibility](reference/docs-visibility.md) — the two-build public/internal model a scaffolded portal uses, the two traps that make the obvious checks useless, and the CI gates that assert on built output instead.
- [Session cost](reference/session-cost.md) — which commands here emit a cost entry, what they charge to, and where the file lands.

## Where the rest lives

This plugin is the documentation half of a family. Three sibling plugins matter to it — two it declares as dependencies, and one whose output it reads without depending on:

- **`workflows-core`** — the shared reference corpus every command here loads through the `reference` skill (addressing, the specs-repo git and phase-handoff entry points, model routing, escalation and finding triage, cost/feedback/follow-up emission, docs grounding, doc-structure conventions, the PRD format), plus the `doc-fixer` and `impl-maintenance` agents these commands dispatch. It is a declared dependency, so installing this plugin installs it.
- **`prose-style`** — the complementary semantic prose pass `docs-style-checker` runs alongside the repo's own linter, and the fallback linter when a repo configures none. Also a declared dependency.
- **`dev-workflows`** — the pipeline that produces what `/document` reads: the idea, the PRD, the Epics, the specification, the design, and the implementation whose diffs a keyed run summarises. It is *not* a dependency in either direction; this plugin installs and runs without it, against a specs tree someone else filled in.

## Status

This plugin ships 6 slash commands, 8 agents, 18 reference files and 2 hooks — and it ships one bundled skills entry, `docs-frontmatter`. Most of it moved here from `dev-workflows` in the third increment of the marketplace split, and behaves as it did there but for one deliberate change: `prose-style` is now a declared dependency, so the branches that used to skip or degrade the style check when it was absent are gone. Otherwise only the namespace these commands answer to and the way they reach the shared corpus have changed. The `preload-context` hook is the one thing that was split rather than moved, because `dev-workflows` still needs its half.

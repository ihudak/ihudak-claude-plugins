# docs-workflows

Three slash commands for the documentation half of the `dev-workflows` pipeline: `/document` synthesises product documentation from a resolved PRD's implementation diffs (or makes a one-shot prose edit in direct mode), `/docs-profile` bootstraps and refreshes the machine-readable profile `/document` consumes, and `/release-notes` drafts a destination-shaped release-notes entry from the same PRD folder. It depends on the shared `workflows-core` foundation and on `prose-style` for its style-check gate.

> Part of the `ihudak-plugins` marketplace — see the [repo-root setup guide](../../README.md) for marketplace install + prerequisites.

## What it does

| Role | Command | What it does |
|------|---------|--------------|
| Dev | [`/document`](docs/commands/document.md) | Document a feature from its PRD and the diffs that shipped it, gated on a style check and an Opus review — or make a one-shot prose edit in direct mode, style-checked only. |
| PM / Dev | [`/release-notes`](docs/commands/release-notes.md) | Draft the one Summary that announces a change, shaped by the destination it resolves to: breaking change, feature update, or fix. |
| Anytime — setup | [`/docs-profile`](docs/commands/docs-profile.md) | Scan a documentation repository once and write the reusable profile plus `CLAUDE.md` guidance `/document` reads, as a reviewable pull request. |

Seven agents and 14 reference files carry the docs-repo discovery, PR-diff summarising, doc planning, doc writing and doc review these three commands share, plus the `docs-frontmatter` skill `/docs-profile` points a repository at and two advisory hooks — one injecting specs context on a `/document` or `/release-notes` prompt, one reminding about a docs page's changelog and owners frontmatter.

## Documentation

| Page | What's there |
|------|--------------|
| [Documentation index](docs/README.md) | The full "I want to…" lookup table, plus the command, agent, and reference inventories. |
| [Getting started](docs/getting-started.md) | Install, environment variables, your first `/docs-profile` and `/document` runs. |
| [Workflow overview](docs/workflow.md) | The three commands as one diagram, and the two modes of `/document`. |
| [Agents](docs/reference/agents.md) | The subagent inventory the commands dispatch internally. |
| [References](docs/reference/references.md) | The reference-doc inventory under `references/`, and the one bundled skill. |
| [Environment](docs/reference/environment.md) | Every environment variable the plugin reads. |
| [Hooks](docs/reference/hooks.md) | The two bundled hooks, what each injects or reminds about, and why neither blocks Claude. |
| [Session cost](docs/reference/session-cost.md) | Which commands emit a cost entry, what they charge to, and where it lands. |

## Recommended environment

Mount every repository, your docs clone and your specs repo under one `/workspace`, matching this plugin's defaults, with [`ihudak/ai-containers`](https://github.com/ihudak/ai-containers). Outside a container the commands still work — set `$REPOS_PATH`, `$DOCS_PATH` and `$SPECS_PATH` yourself; see [Environment](docs/reference/environment.md).

## License

MIT — see [LICENSE](LICENSE).

# dev-workflows

A role-based pipeline of twenty-one slash commands — idea refinement through Value Increment authoring, architecture, specification, design, implementation, and documentation, plus CVE remediation and dependency upgrades — with Opus-backed risk planning, code review, and doc/design review gates across the pipeline.

> Part of the `ihudak-plugins` marketplace — see the [repo-root setup guide](../../README.md) for marketplace install + prerequisites.

## What it does

Every command owns one role's step in the pipeline and hands a concrete artifact to the next. See [Workflow overview](docs/workflow.md) for the diagram and [Roles and phases](docs/roles-and-phases.md) for what each role is accountable for.

| Role | Commands | What it does |
|------|----------|--------------|
| PM | [`/idea`](docs/commands/idea.md), [`/create-vi`](docs/commands/create-vi.md), [`/update-vi`](docs/commands/update-vi.md), [`/release-notes`](docs/commands/release-notes.md) *(early run)* | Refine a raw idea, author or refresh the Value Increment, and draft an early release-notes note. |
| PA *(optional)* | [`/create-ard`](docs/commands/create-ard.md) | Ground an architecture decision in the mounted implementation code. |
| PE | [`/epics`](docs/commands/epics.md), [`/specify`](docs/commands/specify.md) | Break a VI into Epics, then author an org-standard specification through a grill. |
| Dev | [`/design`](docs/commands/design.md), [`/implement`](docs/commands/implement.md), [`/document`](docs/commands/document.md), [`/release-notes`](docs/commands/release-notes.md) | Design against the spec, implement — code-review traces in-scope `[Uxx]`/`[ACxx]`/`[TCxx]` against the diff — document, and draft release notes. |
| Team | [`/ready`](docs/commands/ready.md) | Verify a Jira status against the ARD, spec, and design record; read-only. |
| Anytime — maintenance | [`/vuln`](docs/commands/vuln.md), [`/upgrade`](docs/commands/upgrade.md), [`/docs-profile`](docs/commands/docs-profile.md), [`/statusline`](docs/commands/statusline.md) | Remediate a CVE, upgrade a dependency, profile a docs repo, or install the status line. |
| Anytime — guideline review | [`/api-guideline-reviewer`](docs/commands/api-guideline-reviewer.md), [`/guideline-reviewer`](docs/commands/guideline-reviewer.md) | Review an OpenAPI spec or app UI against Dynatrace guidelines. |
| Anytime — plugin feedback | [`/feedback`](docs/commands/feedback.md), [`/prompt`](docs/commands/prompt.md), [`/prompt-brainstorm`](docs/commands/prompt-brainstorm.md), [`/prompt-grill-me`](docs/commands/prompt-grill-me.md) | Log friction about the plugin itself, or capture and act on a correction. |

## Documentation

| Page | What's there |
|------|--------------|
| [Documentation index](docs/README.md) | The full "I want to…" lookup table, plus the command and reference inventories. |
| [Getting started](docs/getting-started.md) | Install, environment variables, status line, your first `/idea` run. |
| [Workflow overview](docs/workflow.md) | The whole pipeline as one diagram. |
| [Roles and phases](docs/roles-and-phases.md) | What each role owns and hands off. |
| [Agents](docs/reference/agents.md) | The subagent inventory the commands dispatch internally. |
| [References](docs/reference/references.md) | The reference-doc inventory under `references/`. |
| [Environment](docs/reference/environment.md) | Every environment variable the plugin reads. |
| [Hooks](docs/reference/hooks.md) | The bundled hooks and what each does. |
| [Model routing](docs/reference/model-routing.md) | Task-complexity classification and the model fallback chain. |
| [Session cost](docs/reference/session-cost.md) | How a run's dollar cost is computed, attributed, and persisted. |
| [Session feedback](docs/reference/session-feedback.md) | How `/feedback` and `/prompt*` capture friction about the plugin. |
| [Follow-ups](docs/reference/follow-ups.md) | How a command emits follow-up tasks into your vault. |
| [Resume and checkpoints](docs/reference/resume-and-checkpoints.md) | Session hygiene for a long-running command. |

## Recommended environment

Mount every repository and your vault under one `/workspace`, matching this plugin's defaults, with [`ihudak/ai-containers`](https://github.com/ihudak/ai-containers). Outside a container the commands still work — set `$REPOS_PATH` and `$VAULT_PATH` yourself; see [Environment](docs/reference/environment.md).

## License

MIT — see [LICENSE](LICENSE).

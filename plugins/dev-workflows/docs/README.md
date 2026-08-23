# dev-workflows documentation

| I want to… | Go to |
|---|---|
| install this and set it up | [Getting started](getting-started.md) |
| understand the whole pipeline first | [Workflow overview](workflow.md) |
| know what my role is responsible for | [Roles and phases](roles-and-phases.md) |
| turn a raw idea into something actionable | [`/idea`](commands/idea.md) |
| write or refresh a Value Increment | [`/create-vi`](commands/create-vi.md), [`/update-vi`](commands/update-vi.md) |
| record an architecture decision | [`/create-ard`](commands/create-ard.md) |
| break a VI into Epics | [`/epics`](commands/epics.md) |
| write a specification, then a design | [`/specify`](commands/specify.md), [`/design`](commands/design.md) |
| build the thing | [`/implement`](commands/implement.md) |
| document it, then announce it | [`/document`](commands/document.md), [`/release-notes`](commands/release-notes.md) |
| check whether a ticket is really ready | [`/ready`](commands/ready.md) |
| fix a CVE or upgrade a dependency | [`/vuln`](commands/vuln.md), [`/upgrade`](commands/upgrade.md) |
| tell the plugin it got something wrong | [`/feedback`](commands/feedback.md), [`/prompt`](commands/prompt.md) |
| review an API spec or a UI against guidelines | [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md), [`/guideline-reviewer`](commands/guideline-reviewer.md) |
| see live cost and context while you work | [`/statusline`](commands/statusline.md) — **run this first** |
| understand what a run cost | [Session cost](reference/session-cost.md), [`/statusline`](commands/statusline.md) |

Three pages orient you before you touch a command: [Getting started](getting-started.md) installs the plugin and sets your environment variables; [Workflow overview](workflow.md) shows the whole pipeline as one diagram; [Roles and phases](roles-and-phases.md) says what each role owns and hands off. Every other page below documents one command, one shared subsystem, or — for [Agents](reference/agents.md) and [References](reference/references.md) — one whole inventory.

## Commands

- [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md) — review an OpenAPI spec against the bundled REST API and IAM permission naming guidelines.
- [`/create-ard`](commands/create-ard.md) — author an Architecture Requirements/Decision Document for a VI, or for one Epic inside it, grounded on the mounted code.
- [`/create-vi`](commands/create-vi.md) — turn a refined idea plus a Jira key into a reviewed Value Increment.
- [`/design`](commands/design.md) — take over a merged specification and author a reviewed engineering design, grounded strictly in the mounted code.
- [`/docs-profile`](commands/docs-profile.md) — scan a docs repository and write or refresh the machine-readable profile `/document` consumes.
- [`/document`](commands/document.md) — write or update product documentation: a one-shot direct edit, or the full Jira-driven feature-documentation workflow.
- [`/epics`](commands/epics.md) — break a Value Increment into reviewed child Epic drafts.
- [`/feedback`](commands/feedback.md) — log a note about the plugin itself, for the maintainer to aggregate.
- [`/guideline-reviewer`](commands/guideline-reviewer.md) — review app code and UI against the bundled Experience Standards.
- [`/idea`](commands/idea.md) — refine a raw prompt, file, community post, or existing VI into a one-page idea brief.
- [`/implement`](commands/implement.md) — classify, plan, implement, test, and review a code change end to end.
- [`/prompt`](commands/prompt.md) — log a correction you just made to a command's output, then apply the fix directly.
- [`/prompt-brainstorm`](commands/prompt-brainstorm.md) — log a correction, then hand off to `superpowers:brainstorming` to redesign it together.
- [`/prompt-grill-me`](commands/prompt-grill-me.md) — log a correction, then grill the fix inline with a bounded interrogation.
- [`/ready`](commands/ready.md) — verify a Jira status against the ARD/spec/design record, without changing it.
- [`/release-notes`](commands/release-notes.md) — draft a release-notes Summary for a ticket, shaped by the destination it resolves to.
- [`/specify`](commands/specify.md) — author an org-standard specification for one Jira item through a relentless grill.
- [`/statusline`](commands/statusline.md) — install the plugin's multi-line status line into your Claude Code settings.
- [`/update-vi`](commands/update-vi.md) — refresh an existing Value Increment against its Jira source.
- [`/upgrade`](commands/upgrade.md) — plan and execute a library, framework, runtime, or build-tool upgrade.
- [`/vuln`](commands/vuln.md) — research and fix a CVE, one dependency or code change at a time.

## Reference

- [Agents](reference/agents.md) — the subagent inventory: what each helper agent does and which command calls it.
- [References](reference/references.md) — the reference-doc inventory under `references/`, grouped by subtree.
- [Skills](reference/references.md#skills) — the two bundled skills: what each is for, and which is user-invocable.
- [Environment](reference/environment.md) — every environment variable the plugin reads, and what it configures.
- [Hooks](reference/hooks.md) — the bundled hooks and what each one does.
- [Model routing](reference/model-routing.md) — the task-complexity classification and model fallback chain commands apply before acting.
- [Session cost](reference/session-cost.md) — how a run's dollar cost is computed, attributed, and persisted.
- [Session feedback](reference/session-feedback.md) — two different signals about the plugin itself: `/feedback` logs what you tell it, while `/prompt*` captures a bad result, your correction, and the good result that came out of it.
- [Follow-ups](reference/follow-ups.md) — how a command emits follow-up tasks into your vault.
- [Resume and checkpoints](reference/resume-and-checkpoints.md) — session hygiene: checkpointing state and resuming a long-running command.

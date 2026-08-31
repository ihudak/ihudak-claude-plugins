# dev-workflows documentation

| I want to… | Go to |
|---|---|
| install this and set it up | [Getting started](getting-started.md) |
| understand the whole pipeline first | [Workflow overview](workflow.md) |
| know what my role is responsible for | [Roles and phases](roles-and-phases.md) |
| see all six commands of the BRD-to-PRD route as one diagram, plus the three `--from-brd` edges it hands over on, with a parameter table | [BRD workflow](brd-workflow.md) |
| turn a customer BRD into a grounded inventory with every requirement allocated | [`/brd-intake`](commands/brd-intake.md), [`/brd-ground`](commands/brd-ground.md), [`/brd-split`](commands/brd-split.md) |
| decide an allocated BRD's open questions without asking the wrong party | [`/brd-interview`](commands/brd-interview.md) |
| package a decided BRD for a customer whose reviewer has nothing installed | [`/brd-package`](commands/brd-package.md) |
| freeze a returned customer review into decisions and sweep what it overturned | [`/brd-reconcile`](commands/brd-reconcile.md) |
| turn a raw idea into something actionable | [`/idea`](commands/idea.md) |
| write or refresh a Product Requirements Document | [`/create-prd`](commands/create-prd.md), [`/update-prd`](commands/update-prd.md) |
| record an architecture decision | [`/create-ard`](commands/create-ard.md) |
| break a PRD into Epics | [`/epics`](commands/epics.md) |
| write a specification, then a design | [`/specify`](commands/specify.md), [`/design`](commands/design.md) |
| build the thing | [`/implement`](commands/implement.md) |
| document it, then announce it | [`/document`](commands/document.md), [`/release-notes`](commands/release-notes.md) |
| check whether a ticket is really ready | [`/ready`](commands/ready.md) |
| fix a CVE or upgrade a dependency | [`/vuln`](commands/vuln.md), [`/upgrade`](commands/upgrade.md) |
| tell the plugin it got something wrong | [`/feedback`](commands/feedback.md), [`/prompt`](commands/prompt.md) |
| review an API spec or a UI against guidelines | [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md), [`/guideline-reviewer`](commands/guideline-reviewer.md) |
| see live cost and context while you work | [`/statusline`](commands/statusline.md) — **run this first** |
| understand what a run cost | [Session cost](reference/session-cost.md), [`/statusline`](commands/statusline.md) |

Four pages orient you before you touch a command: [Getting started](getting-started.md) installs the plugin and sets your environment variables; [Workflow overview](workflow.md) shows the whole pipeline as one diagram; [BRD workflow](brd-workflow.md) shows the second route into a PRD — from a customer-supplied BRD to a grounded, allocated, decided inventory, back out through a customer review the plugin waits on, and on into the PRD pipeline through `--from-brd` — as its own diagram; [Roles and phases](roles-and-phases.md) says what each role owns and hands off. Every other page below documents one command, one shared subsystem, or — for [Agents](reference/agents.md) and [References](reference/references.md) — one whole inventory.

## Commands

- [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md) — review an OpenAPI spec against the bundled REST API and IAM permission naming guidelines.
- [`/brd-ground`](commands/brd-ground.md) — pin every mounted repository, ground the BRD's requirements against code and design, and independently re-derive every finding on Opus.
- [`/brd-intake`](commands/brd-intake.md) — intake a customer BRD verbatim, extract its requirement inventory, and write a coverage ledger with every row unallocated.
- [`/brd-interview`](commands/brd-interview.md) — tag every open question `[G]`/`[V]`/`[C]` before it is asked, answer the `[G]`s from the findings, and record the delivery team's decisions.
- [`/brd-package`](commands/brd-package.md) — attack the decided package, then render a plugin-free customer prompt and a de-Obsidianised bundle for a reviewer with nothing installed.
- [`/brd-reconcile`](commands/brd-reconcile.md) — freeze the customer's returned answers as `[CD#n]` once an operator confirms each one, then sweep every dependent BRD and every stale cross-reference.
- [`/brd-split`](commands/brd-split.md) — propose and key slices from the grounded picture, then walk every ledger row to a recorded fate.
- [`/create-ard`](commands/create-ard.md) — author an Architecture Requirements/Decision Document for a PRD, or for one Epic inside it, grounded on the mounted code.
- [`/create-prd`](commands/create-prd.md) — turn a refined idea plus a Jira key into a reviewed Product Requirements Document.
- [`/design`](commands/design.md) — take over a merged specification and author a reviewed engineering design, grounded strictly in the mounted code.
- [`/docs-profile`](commands/docs-profile.md) — scan a docs repository and write or refresh the machine-readable profile `/document` consumes.
- [`/document`](commands/document.md) — write or update product documentation: a one-shot direct edit, or the full Jira-driven feature-documentation workflow.
- [`/epics`](commands/epics.md) — break a Product Requirements Document into reviewed child Epic drafts.
- [`/feedback`](commands/feedback.md) — log a note about the plugin itself, for the maintainer to aggregate.
- [`/guideline-reviewer`](commands/guideline-reviewer.md) — review app code and UI against the bundled UI design-system and accessibility guidelines.
- [`/idea`](commands/idea.md) — refine a raw prompt, file, community post, or existing PRD into a one-page idea brief.
- [`/implement`](commands/implement.md) — classify, plan, implement, test, and review a code change end to end.
- [`/prompt`](commands/prompt.md) — log a correction you just made to a command's output, then apply the fix directly.
- [`/prompt-brainstorm`](commands/prompt-brainstorm.md) — log a correction, then hand off to `superpowers:brainstorming` to redesign it together.
- [`/prompt-grill-me`](commands/prompt-grill-me.md) — log a correction, then grill the fix inline with a bounded interrogation.
- [`/ready`](commands/ready.md) — verify a Jira status against the ARD/spec/design record, without changing it.
- [`/release-notes`](commands/release-notes.md) — draft a release-notes Summary for a ticket, shaped by the destination it resolves to.
- [`/specify`](commands/specify.md) — author an org-standard specification for one Jira item through a relentless grill.
- [`/statusline`](commands/statusline.md) — install the plugin's multi-line status line into your Claude Code settings.
- [`/update-prd`](commands/update-prd.md) — refresh an existing Product Requirements Document against its Jira source.
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

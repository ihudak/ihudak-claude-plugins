# guideline-reviewers documentation

| I want to… | Go to |
|---|---|
| install this and set it up | [Getting started](getting-started.md) |
| see the two commands and how they relate | [Workflow](workflow.md) |
| review an OpenAPI spec against REST API and IAM permission-naming guidance | [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md) |
| review app code or a UI against design-system and accessibility guidance | [`/guideline-reviewer`](commands/guideline-reviewer.md) |

## Commands

- [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md) — review an OpenAPI spec against the bundled REST API and IAM permission-naming guidelines.
- [`/guideline-reviewer`](commands/guideline-reviewer.md) — review app code and UI against the bundled UI design-system and accessibility guidelines.

## Reference

- [Agents](reference/agents.md) — the two agents, one per command, that carry out the review.
- [References](reference/references.md) — the bundled guidance corpora under `references/`, grouped by subtree.
- [Environment](reference/environment.md) — `$API_GUIDELINES_PATH` and `$UI_GUIDELINES_PATH`, what each overlays, and what happens when it is unset.

## Status

This plugin ships two slash commands and the two agents each one dispatches, plus the 38 reference files they review against — it ships 0 bundled skills. It is standalone: neither command consumes a workflow artifact or produces one, both are exempt from the model-routing classification the sibling `dev-workflows` plugin's pipeline commands apply, and neither reads or writes `$SPECS_PATH`.

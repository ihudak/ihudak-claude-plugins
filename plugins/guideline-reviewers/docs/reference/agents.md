# Agents

This plugin bundles two agents, dispatched by the command of the same name via `subagent_type: "guideline-reviewers:<name>"`. Neither is a user entry point.

| Agent | Dispatched by | What it does |
|-------|---------------|--------------|
| `api-guideline-reviewer` | [`/api-guideline-reviewer`](../commands/api-guideline-reviewer.md) | Reads an OpenAPI specification and reports where it departs from the bundled REST API and IAM permission-naming guidance. |
| `guideline-reviewer` | [`/guideline-reviewer`](../commands/guideline-reviewer.md) | Reads application code or a UI description and reports where it departs from the bundled design-system and accessibility standards. |

Each of the two agents above is dispatched by exactly the command sharing its name — there is no cross-dispatch, and neither is called from a third command.

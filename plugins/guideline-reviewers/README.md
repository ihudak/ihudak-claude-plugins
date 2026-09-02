# guideline-reviewers

Two standalone review commands, and the guidance they review against: an OpenAPI specification against bundled REST API and IAM permission-naming guidance, and application code or UI against bundled public design-system and accessibility standards. Neither command consumes a workflow artefact or produces one.

This plugin ships two slash commands, [`/api-guideline-reviewer`](docs/commands/api-guideline-reviewer.md) and [`/guideline-reviewer`](docs/commands/guideline-reviewer.md), each dispatching its own agent against the guidance bundled under `references/`.

See [the documentation index](docs/README.md) for the full command, agent, and reference inventory.

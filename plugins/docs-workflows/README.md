# docs-workflows

Three commands for the documentation half of the `dev-workflows` pipeline: `/document` synthesises product documentation from a resolved PRD's implementation diffs, `/docs-profile` bootstraps and refreshes the machine-readable profile `/document` consumes, and `/release-notes` drafts a destination-shaped release-notes entry from the same PRD folder. It depends on the shared `workflows-core` foundation and on `prose-style` for its style-check gate.

This is the extraction target for that documentation pipeline, created as an empty, gate-green skeleton ahead of the content later tasks in the marketplace split move into it. At this point it ships 0 slash commands, 0 agents, and 0 reference files.

See [the documentation index](docs/README.md) for the full command, agent, and reference inventory as it grows.

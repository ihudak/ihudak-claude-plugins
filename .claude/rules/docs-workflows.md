---
paths:
  - "plugins/docs-workflows/**"
  - "plugins/product-workflows/commands/epics.md"
  - "plugins/product-workflows/agents/epic-*.md"
  - "plugins/product-workflows/docs/commands/epics.md"
  - "plugins/workflows-core/references/docs-grounding.md"
---

# docs-workflows — invariants, workflow map, agent callers

Loaded when a file under `plugins/docs-workflows/` is read, or `/epics`'s command, agent or docs page, or `workflows-core:docs-grounding`. Repo-wide rules are in `CLAUDE.md`; evidence is in `docs/maintainers/rationale.md`.

Ruling, recorded in the ledger: this file carries the `/epics` and `docs-grounding` globs. The base's *"Key invariants for `/document` (keyed mode) and `/epics`"* section states shared bullets for both commands, and the spec's table puts docs-grounding invariants in this file. Splitting shared bullets into two files would create two copies of one rule, which spec §4 forbids.

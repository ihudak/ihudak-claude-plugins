---
name: alpha
description: A fixture command reading $SPECS_PATH.
---

Call `emit-cost` with `command: /alpha`, `phase: fixture-phase`, `role: pm`,
and the run's plugin version.

On the first choice, execute `handoff-to-main` with `deliverable_paths` = `alpha-deliverable.md`,
and `title: fixture handoff`.

```
choices: ["Run the gated consumer — /dev-workflows:omega <KEY> (Recommended) <merge-clause>", "Stop here"]
```

The gamma reference is cited in the bare backticked form: `references/gamma.md`.
The handoff contracts are cited by plugin-root path: `${CLAUDE_PLUGIN_ROOT}/references/handoff/one.md`
and `${CLAUDE_PLUGIN_ROOT}/references/handoff/two.md`.
Routing comes from `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md`.

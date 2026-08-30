---
name: alpha
description: A fixture command reading $SPECS_PATH.
---

Call `emit-cost` with `command: /alpha`, `phase: fixture-phase`, `role: pm`,
and the run's plugin version.

On the first choice, execute `handoff-to-main` with `deliverable_paths` = `alpha-deliverable.md`,
and `title: fixture handoff`.

```
choices: ["Run the gated consumer — /dev-workflows:omega <KEY> (Recommended) <merge-clause>", "Stop here", "Other… (describe)"]
```

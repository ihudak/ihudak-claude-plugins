---
name: alpha-two
description: A second fixture command in the same offer family as alpha.
---

A fixture command. It exists so the family this repo's `<merge-clause>` rule binds has more
than one member, which is what makes a per-command coverage assertion provable.

On the first choice, execute `handoff-to-main` with `deliverable_paths` = `alpha-two-out.md`,
and `title: fixture second handoff`.

```
choices: ["Run the second gated consumer — /dev-workflows:tau <KEY> (Recommended) <merge-clause>", "Stop here"]
```

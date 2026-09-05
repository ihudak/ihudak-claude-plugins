# Workflow

`workflows-core` runs no pipeline of its own. It is the shared foundation the `dev-workflows` plugin family draws on — the reference corpus, the `model-routing` skill, and five agents — plus six commands that sit beside a pipeline rather than inside one.

```mermaid
flowchart TD
    subgraph CORPUS["What every sibling plugin reads"]
        refs["references/ — addressing, git + phase handoff, escalation, triage, emission"]
        loader["skills/reference — the loader a sibling reads the corpus through"]
        skill["skills/model-routing"]
        agents["agents/ — code-scanner · doc-fixer · docs-grounder · frame-describer · impl-maintenance"]
    end
    subgraph CROSS["Cross-cutting commands"]
        setup["/workflows-core:statusline — install the status line"]
        repair["/frames — (re)build a design/ frame-set index"]
        improve["/feedback · /prompt · /prompt-brainstorm · /prompt-grill-me"]
    end
    pipeline["a sibling plugin's pipeline command"]

    refs --> loader
    loader --> pipeline
    skill --> pipeline
    agents --> pipeline
    pipeline -->|a bad result you corrected| improve
    setup -.->|cost cross-check| pipeline
    repair -.->|a readable frame-set index| pipeline
```

The three dashed and solid edges into `a sibling plugin's pipeline command` are the whole point of this plugin: a command in `dev-workflows` or `docs-workflows` reads a reference here, loads the routing skill here, and dispatches an agent here, so the same rules bind every plugin in the family rather than being copied into each.

**`skills/reference` is why the corpus edge goes through a node instead of straight across**, and it is the mechanism the whole split turns on. `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, so a sibling cannot open a file in `references/` by path — its own plugin root names itself. It calls `Skill(skill: "workflows-core:reference", args: "<name>")` instead, and the skill resolves the path on the caller's behalf. `skills/model-routing` is the same trick applied to one specific reference, kept separate because a slash-command body cannot expand the variable even inside its own plugin. Both are listed in [References and skills](reference/references.md#skills).

## Cross-cutting commands

These run outside any role pipeline, at any time:

- **Plugin improvement.** `/feedback` logs a note about the plugin itself; `/prompt`, `/prompt-brainstorm`, and `/prompt-grill-me` turn a correction you just made into logged feedback plus a fix — applied directly, redesigned with `superpowers:brainstorming`, or grilled inline.
- **Setup.** `/statusline` installs the family's multi-line status line. It collides with a Claude Code built-in of the same name, so type the qualified `/workflows-core:statusline`.
- **Specs-tree repair.** [`/frames`](commands/frames.md) (re)builds the frame-set index of any folder holding exported design frames — a BRD, PRD, or Epic folder alike — so a set somebody dropped in by hand becomes readable. It advances no phase and grounds nothing.

None of the six advances a pipeline phase. What they do share with the pipeline is the cost ledger: each is charged to the phase of the command it is correcting or the folder it is acting on — see [Roles and phases](roles-and-phases.md).

See the [documentation index](README.md) for everything else.

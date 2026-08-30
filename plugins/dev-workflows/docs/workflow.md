# Workflow overview

This is the dev-workflows pipeline top to bottom — every command shown here, in the order the roles typically hand work to each other. `/idea → /create-prd` opens a Product Requirements Document; `/document` and `/release-notes` close it out. A second route into a PRD exists alongside it: `/brd-intake → /brd-ground → /brd-split → /brd-interview → /brd-package → /brd-reconcile` turns a customer-supplied BRD into a grounded, allocated, decided and customer-reviewed requirement inventory instead of a PM-authored idea — see [BRD workflow](brd-workflow.md) for its own diagram and parameter table.

```mermaid
flowchart TD
    subgraph PM["PM — ideation & framing"]
        idea["/idea"] --> createvi["/create-prd"]
        createvi --> rnpm["/dev-workflows:release-notes (early draft)"]
        createvi -.->|PRD exists| updatevi["/update-prd"]
        updatevi --> rnpm
    end
    subgraph BRD["PM/PA/Dev — BRD-to-PRD route (alt. entry)"]
        brdintake["/brd-intake"] --> brdground["/brd-ground"] --> brdsplit["/brd-split"]
        brdsplit -.->|new child BRD| brdground
        brdsplit --> brdinterview["/brd-interview"] --> brdpackage["/brd-package"]
        brdreconcile["/brd-reconcile"]
    end
    subgraph CUST["Off-platform — the customer, nothing installed"]
        brdreview["the customer reviews the bundle"]
    end
    subgraph PA["PA — architecture (optional)"]
        createard["/create-ard"]
    end
    subgraph PE["PE — breakdown & specification"]
        epics["/epics"]
        specify["/specify"]
    end
    subgraph DEV["Dev — build, verify & deliver"]
        design["/design"] --> implement["/implement"]
        implement --> document["/document"]
        document --> rndev["/dev-workflows:release-notes (final)"]
        ready["/ready"]
    end
    subgraph ANY["Anytime — improve the plugin & utilities"]
        improve["/feedback · /prompt · /prompt-brainstorm · /prompt-grill-me"]
        maint["/vuln · /dev-workflows:upgrade"]
        tooling["/dev-workflows:statusline · /docs-profile · /api-guideline-reviewer · /guideline-reviewer"]
    end

    createvi -->|PRD| createard
    createvi -->|PRD| epics
    createard -->|ARD| epics
    epics -->|Epic drafts| specify
    createvi -->|PRD-level spec| specify
    specify -->|specification.md| design
    ready -. verifies ARD/spec/design .-> implement
    brdpackage -->|bundle sent| brdreview
    brdreview -->|answers come back as one file| brdreconcile
    brdreconcile -.->|a decision reopened, or a question askable again| brdinterview
    brdreconcile -.->|questions still held for the customer| brdpackage
```

The diagram draws the ARD reaching `/epics`, but that is one of five consumers: `/epics`, `/specify`, `/design`, `/implement`, and `/ready` all resolve the applicable ARD once it exists. The edge is drawn once to keep the diagram readable, not because the others do not consult it.

The BRD-to-PRD subgraph carries no edge into `/create-prd`: that connection is undrawn because `--from-brd` has not shipped yet, not because the two routes are unrelated. The same goes for `--from-brd` on `/create-ard` and `/specify`. `/brd-reconcile` is where that route ends today.

The `Off-platform` box is the one node in this diagram no command runs. It is the customer reviewing the bundle with a vanilla agent and nothing installed, and the route waits there — which is why `/brd-reconcile` takes the returned review as an argument rather than looking for it.

The two dashed edges leaving `/brd-reconcile` go to different commands on purpose, and are drawn separately rather than merged under one label: a decision the review reopened is settled by another interview round, while a question the customer left unanswered goes back out in the next package. They are the same two edges [BRD workflow](brd-workflow.md) draws, with the same labels — this diagram summarises that one and never disagrees with it.

The diagram above shows where each command sits in the pipeline; [Roles and phases](roles-and-phases.md) says what each role is accountable for and what it hands over at each seam.

**Three command names collide with a Claude Code built-in of the same name: `/release-notes`, `/upgrade`, and `/statusline`.** Typing the bare form reaches Claude Code's own command instead of the plugin's, so use the qualified form — `/dev-workflows:release-notes`, `/dev-workflows:upgrade`, `/dev-workflows:statusline` — for those three. No other command in this plugin is known to collide today, so the rest work either way, and the diagram above spells out the qualified form only where it is required.

## Roles

| Role | Runs | Produces → lands at |
|---|---|---|
| **PM** | `/idea`, `/create-prd`, `/update-prd`, and an early `/release-notes` | `idea.md` in `$VAULT_PATH`, then the PRD in `$SPECS_PATH/specifications/<KEY>-<slug>/` |
| **PA** | `/create-ard` (optional) | the ARD, in the same specs feature folder as the PRD |
| **PE** | `/epics`, `/specify` | Epic drafts in `$VAULT_PATH/jira-drafts/<PRD-KEY>/`; `specification.md` on the specs repo's default branch |
| **Dev** | `/design`, `/implement`, `/document`, `/ready`, and a final `/release-notes` | `design.md` on the specs repo's default branch; code on a branch in `$REPOS_PATH`, left uncommitted; product docs in the docs repo; a read-only readiness verdict that sets no status |

See [Roles and phases](roles-and-phases.md) for what each role owns, consumes, and hands off — this table only shows where the commands sit.

## Artifact homes

- **`$SPECS_PATH/specifications/<KEY>-<slug>/`** — the shared, team-visible home for the PRD, the ARD, `specification.md`, and `design.md`. Each authoring command lands its file here, then hands it onto the specs repo's default branch for the next command to find.
- **`$VAULT_PATH`** — the personal store: `idea.md` before a Jira key exists, the imported `jira-products/<KEY>/` tree, `jira-drafts/<PRD-KEY>/` Epic drafts, and release-notes drafts.
- **`$REPOS_PATH`** — the mounted code clones. `/implement` and, outside the PRD pipeline, `/upgrade` work here on a feature branch but leave changes uncommitted; `/vuln`, also outside the PRD pipeline, is the one that commits and opens a pull request, per fixed CVE. Product documentation itself is written into the external docs repo, not here.
- **Plugin bookkeeping** — feedback and session-cost files — lives under `<PRD-dir>/dev-workflows/` inside `$SPECS_PATH`, committed and pushed alongside the specs artifacts it describes. Follow-up tasks are the one exception: they land in your vault first and reach this directory only when no vault is available — see [Follow-ups](reference/follow-ups.md) for the full ladder.

## Sources of truth

- **Jira** is the source of truth for workflow *status* — [`workflow-states.md`](../references/workflow-states.md), which owns the PRD and Epic status ladders, says so outright and stores no status of its own, only interprets one. An external import tool pulls the ticket tree into `$VAULT_PATH/jira-products/<KEY>/`, every command reads the status from there, and none writes it back. `/ready` is the command that looks most like an exception and is not one: it verifies a declared status against the ARD/spec/design record and reports, rather than changing it.
- **The specs repo's default branch** is the source of truth for whether a phase's deliverable is actually *done*. A producing command lands its artifact there; the next command in the chain refuses to start expensive work until it finds the artifact on that branch, not merely written to disk. See [Roles and phases](roles-and-phases.md) for what happens when the artifact is on an unmerged branch instead, or missing entirely.

## Cross-cutting commands

These run outside the role pipeline above, at any time:

- **Plugin improvement.** `/feedback` logs a note about the plugin itself; `/prompt`, `/prompt-brainstorm`, and `/prompt-grill-me` turn a correction you just made into logged feedback plus a fix.
- **Standalone maintenance.** `/vuln` (CVE remediation) and `/upgrade` (dependency / runtime upgrades) run on their own, outside the PRD pipeline.
- **Setup and review utilities.** `/statusline` (install the status line — run this first), `/docs-profile` (bootstrap a docs repo's profile), `/api-guideline-reviewer` and `/guideline-reviewer` (API / UI compliance reviews).

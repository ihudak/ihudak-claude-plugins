# Workflow overview

This is the dev-workflows pipeline top to bottom — every command shown here, in the order the roles typically hand work to each other. `/idea → /create-prd` opens a Product Requirements Document; `/document` and `/release-notes` close it out. A second route into a PRD exists alongside it: `/brd-intake → /brd-ground → /brd-split → /brd-interview → /brd-package → /brd-reconcile` turns a customer-supplied BRD into a grounded, allocated, decided and customer-reviewed requirement inventory instead of a PM-authored idea, then hands over to `/create-prd`, `/create-ard` or `/specify` on the BRD route — see [BRD workflow](brd-workflow.md) for its own diagram and parameter table.

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
        brdsplit -.->|new slice, a PRD- folder| brdground
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
    brdreconcile -->|BRD key + the BRD route — nothing left to re-enter for, fully allocated, one row covered-here| createvi
    brdreconcile -->|BRD key + the BRD route — nothing left to re-enter for| createard
    brdreconcile -->|BRD key + the BRD route — nothing left to re-enter for| specify
```

The diagram draws the ARD reaching `/epics`, but that is one of five consumers: `/epics`, `/specify`, `/design`, `/implement`, and `/ready` all resolve the applicable ARD once it exists. The edge is drawn once to keep the diagram readable, not because the others do not consult it.

The BRD-to-PRD route hands over at `/brd-reconcile`, and the diagram draws that handover as **three** edges rather than one, because the BRD route ships on `/create-prd`, `/create-ard` and `/specify` and `/brd-reconcile`'s next-step phase offers all three against the same BRD key **on a run that left nothing to re-enter for** — a reopened decision, a customer question still held, a finding left to re-derive, or a dependent it could only sweep on paper each drop all three, because a reopened record may not be consumed downstream and all three consume the register. On an advancing run only the first carries a further condition: `/create-prd <BRD-KEY>` is offered where the reconciled ledger leaves no row `unallocated` and at least one `covered-here`, which are the two refusals its own Phase 0 raises. Both are read over the BRD's **own ledger rows**; `brd-link.md`'s `claims:` narrows that set only on a slice, since a BRD owning its source document carries no such field. `/create-ard <BRD-KEY>` and `/specify <BRD-KEY>` add none of their own, since neither reads a resolved folder, gates a PRD, or reads the ledger — which is also why neither refuses an unsettled register, and why that judgement sits with `/brd-reconcile` alone. The three are alternatives, not a sequence — neither of the other two waits on the PRD — so `/brd-reconcile` is where the route hands over, not where it ends.

The `Off-platform` box is the one node in this diagram no command runs. It is the customer reviewing the bundle with a vanilla agent and nothing installed, and the route waits there — which is why `/brd-reconcile` takes the returned review as an argument rather than looking for it.

The two dashed edges leaving `/brd-reconcile` go to different commands on purpose, and are drawn separately rather than merged under one label: a decision the review reopened is settled by another interview round, while a question the customer left unanswered goes back out in the next package. They are the same two edges [BRD workflow](brd-workflow.md) draws, with the same labels — as are the three handover edges above them, and every other BRD edge here: all twelve edges that page draws appear in this diagram unchanged, in style and in label, so this diagram summarises that one and never disagrees with it.

The diagram above shows where each command sits in the pipeline; [Roles and phases](roles-and-phases.md) says what each role is accountable for and what it hands over at each seam.

**Three command names collide with a Claude Code built-in of the same name: `/release-notes`, `/upgrade`, and `/statusline`.** Typing the bare form reaches Claude Code's own command instead of the plugin's, so use the qualified form — `/dev-workflows:release-notes`, `/dev-workflows:upgrade`, `/dev-workflows:statusline` — for those three. No other command in this plugin is known to collide today, so the rest work either way, and the diagram above spells out the qualified form only where it is required.

## Parameters at the BRD-to-PRD handoff

The three edges leaving `/brd-reconcile` into the PRD pipeline, as each command's own argument parsing defines them. [BRD workflow](brd-workflow.md#parameters) carries the same table for the six `/brd-*` commands upstream of them.

| Command | Required | Optional | Offered from `/brd-reconcile` |
|---|---|---|---|
| `/create-prd` | `<BRD-KEY>` | `--lean`/`--hybrid`/`--full` (defaults to `--full` here), `--no-docs` | Only where no ledger row is `unallocated` and at least one is `covered-here` |
| `/create-ard` | `<BRD-KEY>` | `--no-docs` | Unconditionally — the run gates no PRD, reads no PRD, and reads no ledger |
| `/specify` | `<BRD-KEY>` | `--no-docs` | Unconditionally, on exactly the same terms as `/create-ard` |

the BRD route is a **switch, not a path** on all three rows: the positional key already identifies the BRD folder, so the optional `<dir>` is only ever for a BRD folder outside the normal layout. On `/create-prd` it is additionally mutually exclusive with `--from-prd`, which is a second seed for the same PRD.

`<BRD-KEY>` is `^[A-Z][A-Z0-9_]*(-\d+)+$` — **two segments or three**, so the slice `EPIC-008-01` is as valid as `EPIC-008`, and all three commands resolve a BRD folder at either level. It is checked for shape only and never against a tracker: a BRD is a markdown file under `$SPECS_PATH`, not a ticket. Each of the three takes exactly **one** key; `/create-ard` and `/specify` stop on a second positional key, because a BRD has no Epics yet.

## Roles

| Role | Runs | Produces → lands at |
|---|---|---|
| **PM** | `/idea`, `/create-prd`, `/update-prd`, and an early `/release-notes` | `idea.md` in the PRD folder, then the PRD in `$SPECS_PATH/specifications/<KEY>-<slug>/` |
| **PA** | `/create-ard` (optional) | the ARD, in the same specs feature folder as the PRD |
| **PE** | `/epics`, `/specify` | `epic.md` per `EPIC-` folder under the PRD folder; `specification.md` on the specs repo's default branch |
| **Dev** | `/design`, `/implement`, `/document`, `/ready`, and a final `/release-notes` | `design.md` on the specs repo's default branch; code on a branch in `$REPOS_PATH`, handed over behind a consent choice; product docs in the docs repo; a read-only readiness verdict that sets no status |

See [Roles and phases](roles-and-phases.md) for what each role owns, consumes, and hands off — this table only shows where the commands sit.

## Artifact homes

- **`$SPECS_PATH/specifications/<KEY>-<slug>/`** — the shared, team-visible home for the PRD, the ARD, `specification.md`, and `design.md`. Each authoring command lands its file here, then hands it onto the specs repo's default branch for the next command to find.
- **`$REPOS_PATH`** — the mounted code clones. `/implement` and, outside the PRD pipeline, `/upgrade` work here on a feature branch and hand the result over behind a consent choice (commit + push + PR, or less); `/vuln` commits and opens a PR as part of its own fix contract.
- **Plugin bookkeeping** — feedback and session-cost files — lives under `<PRD-dir>/dev-workflows/` inside `$SPECS_PATH`, committed and pushed alongside the specs artifacts it describes. Follow-up tasks are the one exception: they land in your vault first and reach this directory only when no vault is available — see [Follow-ups](reference/follow-ups.md) for the full ladder.

## Sources of truth

- **The artifacts** are the source of truth for workflow *status* — [`workflow-states.md`](../references/workflow-states.md) is read in the direction its *expected artifacts* column supports, and `/ready` derives the phase from what is on disk. An operator who keeps a tracker can still check a declared status against it with `/ready --claimed "<status>"`.
- **The specs repo's default branch** is the source of truth for whether a phase's deliverable is actually *done*. A producing command lands its artifact there; the next command in the chain refuses to start expensive work until it finds the artifact on that branch, not merely written to disk. See [Roles and phases](roles-and-phases.md) for what happens when the artifact is on an unmerged branch instead, or missing entirely.

## Cross-cutting commands

These run outside the role pipeline above, at any time:

- **Plugin improvement.** `/feedback` logs a note about the plugin itself; `/prompt`, `/prompt-brainstorm`, and `/prompt-grill-me` turn a correction you just made into logged feedback plus a fix.
- **Standalone maintenance.** `/vuln` (CVE remediation) and `/upgrade` (dependency / runtime upgrades) run on their own, outside the PRD pipeline.
- **Setup and review utilities.** `/statusline` (install the status line — run this first), `/docs-profile` (bootstrap a docs repo's profile), `/api-guideline-reviewer` and `/guideline-reviewer` (API / UI compliance reviews).

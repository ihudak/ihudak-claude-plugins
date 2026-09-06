# Workflow overview

`docs-workflows` carries the documentation tail of the pipeline the companion `dev-workflows` plugin drives. Every command it ships is shown below. The spine is short: once a Product Requirements Document's Epics are implemented, `/docs-workflows:document` writes the product documentation and `/docs-workflows:release-notes` drafts the note that announces it. `/docs-workflows:docs-profile` sits outside that spine — it is the setup utility that teaches `/document` what a given documentation repository looks like.

```mermaid
flowchart TD
    subgraph UP["Upstream — in the product-workflows and dev-workflows plugins"]
        implement["/dev-workflows:implement"]
        createprd["/product-workflows:create-prd"]
    end
    subgraph DOCS["Dev — documentation & release notes"]
        document["/docs-workflows:document"]
        rndev["/docs-workflows:release-notes (final)"]
        document --> rndev
    end
    subgraph SETUP["Anytime — setup utility"]
        profile["/docs-workflows:docs-profile"]
    end

    implement -->|every Epic implemented| document
    createprd -.->|early draft, before any spec or design| rndev
    profile -.->|.dev-workflows/docs-profile.yml| document
```

Two nodes are drawn for continuity and are not this plugin's commands: `/dev-workflows:implement` and `/product-workflows:create-prd` ship in the companion pipeline plugin and are documented there.

**One command name here collides with a Claude Code built-in of the same name: `/release-notes`.** Typing the bare form reaches Claude Code's own command instead of this one, so use the qualified `/docs-workflows:release-notes`. `/document` and `/docs-profile` are not known to collide today, so the rest work either way, and the diagram above spells out the qualified form throughout because that form always works.

## The two modes of `/document`

`/document` is one command with two modes, selected by its first argument token, and the difference between them is the whole shape of the run.

| Mode | Selected by | What it does | Gates |
|---|---|---|---|
| Keyed | a positional address — a key, or `@<path>` naming a folder in the specs tree | Reads the resolved PRD folder, resolves PR URLs to local clones, summarises the diffs in parallel, locates write targets, plans, writes | Style check, then an Opus `doc-reviewer` review |
| Direct | no positional address — an `@file`, free text, or a plain directory | A one-shot prose edit on whatever the argument names | Style check only — no reviewer, and Phase 3 creates no branch and no commit of the edit |

A change that touches both code and docs is `/dev-workflows:implement`'s, not either mode of this command.

## Where each command writes

- **A documentation repository** — `/document` writes pages there and, in keyed mode, finishes on a branch with an opt-in push and a copy-paste pull-request draft. `/docs-profile` writes `.dev-workflows/docs-profile.yml` and complementary `CLAUDE.md` guidance there, as a reviewable pull request; it never pushes or auto-merges.
- **`$SPECS_PATH`** — session bookkeeping only: the cost, feedback and follow-up entries `/document` and `/release-notes` emit, committed by the terminal step bounded to those paths. `/docs-profile` runs no specs-preflight and no terminal commit, so it writes nothing here at all. None of the three writes a pipeline artifact there.
- **Wherever you keep drafts** — `/release-notes` writes its draft to a persistent destination you choose and commits nothing in a docs or code repository. The draft is the authored body only; the metadata wrapper is the docs automation's.

## Sources of truth

- **The PRD folder** is what a keyed run reads: the Product Requirements Document itself, plus the implementation record and commit scan that name the diffs to summarise. See [Getting started](getting-started.md) for what has to be in place before a keyed run works at all.
- **The resolved docs profile** is what tells `/document` where a page belongs, what frontmatter it carries, and how to verify the render. In-repo first, then the bundled default, then on-demand profiling.

See the [documentation index](README.md) for the per-command pages and the agent, reference and environment inventories.

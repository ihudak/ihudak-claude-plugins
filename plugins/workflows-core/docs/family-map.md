# Family map

This page shows the whole plugin family on one diagram: every slash command of `product-workflows`, `dev-workflows`, `docs-workflows` and `workflows-core`, from the two ways work enters — `/idea` and `/brd-intake` — to shipped code, its documentation and its release notes. Each lane is a **role**. Each command is **coloured by the plugin that ships it**. Each labelled arrow is the **deliverable** one command hands to the next: the file the next command reads, not merely the step it tends to follow.

```mermaid
flowchart TD
    subgraph KEY["Plugin"]
        kprod["product-workflows"]:::prod
        kdev["dev-workflows"]:::dev
        kdocs["docs-workflows"]:::docs
        kcore["workflows-core"]:::core
    end

    subgraph BRDR["PM — BRD route (entry for a customer's requirements document)"]
        brdintake["/brd-intake"]:::prod
        splitroot["/brd-split (root)"]:::prod
        splitslice["/brd-split (slice)"]:::prod
        brdinterview["/brd-interview"]:::prod
        brdpackage["/brd-package"]:::prod
        brdreconcile["/brd-reconcile"]:::prod
    end
    subgraph CUST["Customer — off-platform, nothing installed"]
        review["reviews the bundle"]:::cust
    end
    subgraph PMR["PM — idea route and the PRD"]
        idea["/idea"]:::prod
        createprd["/create-prd"]:::prod
        updateprd["/update-prd"]:::prod
        rnearly["/release-notes (early draft)"]:::docs
    end
    subgraph EST["PM — effort proposals (gate nothing)"]
        prdproposal["/prd-proposal"]:::prod
        brdproposal["/brd-proposal"]:::prod
    end
    subgraph PA["PA — grounding and architecture"]
        prdground["/prd-ground"]:::prod
        createard["/create-ard"]:::prod
    end
    subgraph PE["PE — breakdown and specification"]
        epics["/epics"]:::prod
        specify["/specify"]:::prod
    end
    subgraph DEV["Dev — build and verify"]
        design["/design"]:::dev
        ready["/ready"]:::dev
        implement["/implement"]:::dev
    end
    subgraph DOC["Dev — documentation and release notes"]
        document["/document"]:::docs
        rnfinal["/release-notes (final)"]:::docs
    end
    subgraph PORTAL["Dev — documentation portal, off the spine"]
        docsinit["/docs-init"]:::docs
        docsbrand["/docs-brand"]:::docs
        docsprofile["/docs-profile"]:::docs
        docsserve["/docs-serve"]:::docs
        docsaudit["/docs-audit"]:::docs
    end
    subgraph ANY["Anytime"]
        frames["/frames"]:::core
        improve["/feedback · /prompt · /prompt-brainstorm · /prompt-grill-me"]:::core
        statusline["/statusline"]:::core
        maint["/vuln · /upgrade"]:::dev
    end

    brdintake -->|"inventory + ledger"| splitroot
    splitroot -->|"a PRD- slice folder"| prdground
    prdground -->|"verified [CG#n]/[DG#n]"| splitslice
    splitslice -->|"allocated ledger"| brdinterview
    brdinterview -->|"decisions.md + held [C] questions"| brdpackage
    brdpackage -->|"review bundle"| review
    review -->|"the returned review"| brdreconcile
    brdreconcile -->|"frozen decisions.md"| createprd
    brdreconcile -->|"frozen decisions.md"| createard
    brdreconcile -->|"frozen decisions.md"| specify
    brdinterview -.->|"decisions.md — no customer review needed"| createprd

    idea -->|"idea.md"| createprd
    createprd -.->|"prd.md — optional grounding"| prdground
    prdground -.->|"findings — a claim CONFIRMED"| updateprd
    prdground -.->|"findings"| createard
    prdground -.->|"findings"| specify
    createprd -->|"prd.md"| createard
    createprd -->|"prd.md"| epics
    createprd -->|"prd.md"| specify
    createprd -.->|"prd.md"| rnearly
    createprd -.->|"prd.md"| prdproposal
    prdproposal -->|"each slice's proposal.md"| brdproposal
    createard -.->|"ard.md"| epics
    epics -->|"epic.md"| specify

    specify -->|"specification.md"| design
    design -->|"design.md"| implement
    design -.->|"design.md + specification.md"| ready
    ready -.->|"_readiness.md — advisory"| implement
    implement -->|"code + implementation.md"| document
    implement -.->|"implementation.md — diff grounding on"| rnfinal

    docsinit -.->|"a new docs repo + profile"| document
    docsinit -->|"inline"| docsbrand
    docsprofile -.->|"docs profile"| document
    createard -.->|"ard.md"| docsaudit
    rnfinal -.->|"release-notes.md"| docsaudit
    docsaudit -.->|"a backlog you work through"| document
    frames -.->|"design/ frame-set index"| prdground

    classDef prod fill:#dbeafe,stroke:#1d4ed8,color:#1e3a8a
    classDef dev fill:#dcfce7,stroke:#15803d,color:#14532d
    classDef docs fill:#fef3c7,stroke:#b45309,color:#78350f
    classDef core fill:#ede9fe,stroke:#6d28d9,color:#4c1d95
    classDef cust fill:#f3f4f6,stroke:#6b7280,color:#1f2937
```

## Reading it

- **Solid arrows are the main line**: the deliverable the next command is built to consume. **Dashed arrows** are the rest — an input the next command reads where it exists, an optional branch you may skip (grounding an idea-route PRD, pricing it, drafting early release notes), advice (`/ready`'s verdict), or a list a person works through (`/docs-audit`'s backlog, which `/document` never reads). Whether a command also waits for its input to be merged is a per-command gate, described on its own page.
- **The BRD route joins the PRD ladder at the slice folder**, not at an `idea.md`. The three authoring commands are alternatives, not a sequence, and each gates the slice's `decisions.md`. `/brd-reconcile` offers them once the customer's answers are frozen. `/brd-interview` offers them directly when every question was settled from the findings, so the slice needs no customer review — `/create-prd` there, as after a reconciliation, only where a row the slice claims is `covered-here`.
- **`/release-notes` is drawn twice** because it runs at two moments: early, from `prd.md`, and again after implementation. The final run reads nothing `/document` writes, so the two documentation commands are independent.
- **`/ready` sits beside the spine, not on it.** Its verdict is advice `/implement` reads; it blocks nothing.
- **The Anytime lane hands no deliverable to the pipeline** except `/frames`' frame-set index, which `/prd-ground`'s design grounding needs. The portal lane prepares the documentation repository `/document` writes into, and `/docs-serve` only previews it.

## The detail, per plugin

Each plugin's own workflow page draws its commands in full, with the loops and conditions this map leaves out:

- `product-workflows` — its Workflow overview page, and its BRD workflow page for the six-command route with its re-entry loops.
- `dev-workflows` — its Workflow overview page.
- `docs-workflows` — its Workflow overview page, and its docs workflow page for the portal procedure.
- `workflows-core` — [Workflow](workflow.md), for what this plugin gives the other three.

The roles are described on each plugin's Roles and phases page; this plugin's own is [Roles and phases](roles-and-phases.md).

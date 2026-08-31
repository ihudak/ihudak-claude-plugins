# Product Requirements Document format (embedded authority)

The canonical structure and per-section rules for a `prd.md` PRD file — one per PRD folder, its identity carried by the folder rather than by its own name (`references/addressing.md` §2, §4). `/create-prd` and `/update-prd` author
against this file; `prd-reviewer` reviews against it, and `/release-notes` reads its Jira-mirror fields. The PRD is **product-level** (a PRD): what / why /
for-whom, **not** how — no implementation detail. A mandatory **spine** (always present) plus an
**adapt-in menu** whose clusters are pulled only when the idea warrants them (never an empty section).

## Profiles

- **`--lean`** — spine only.
- **`--hybrid`** (default) — spine + the hybrid adapt-in clusters.
- **`--full`** — spine + the full adapt-in menu.

## Frontmatter (PM-authorable subset)

```yaml
---
kind: prd                    # what this document is
key: <KEY>                   # this folder's key — must match the folder name
title: <human-readable PRD title>
summary: <one-line>
issue_type: ValueIncrement
status: <e.g. draft>
owning_program: <program>
tracking_programs: [ ... ]
priority: <e.g. Major>
labels: [ ... ]
relevant_for_release_notes: <yes | no>
sources:                     # PROPAGATED from idea.md's recorded provenance — not the literal idea.md
  - provenance: rfe | prd | community-post | prompt | markdown
    ref: <RFE key | post URL | ...>
derived_from: <path to the idea.md this PRD was built from>
seeded_from_prd: <PRD key or path when this PRD was seeded from another PRD via `/create-prd --from-prd`; omit otherwise>
brd_key: <the BRD key this PRD was authored from via `/create-prd --from-brd`; omit otherwise>
brd_parent: <that BRD's own parent key, from its brd-link.md; omit when it owns its source document, and omit outside the BRD route>
depends_on: [ ... ]           # prerequisite BRD keys, from that brd-link.md's depends-on; omit when empty or outside the BRD route
revision_of: <path to the archived prior PRD snapshot; written by `/update-prd` on refresh; omit otherwise>
built_from_import: <YYYY-MM-DD of the Jira import the `/update-prd` refresh was built from; omit otherwise>
jira_key: <the tracker key; omit until the Jira round-trip mints one — see below>
---
```

`brd_key`, `brd_parent` and `depends_on` are written only by `/create-prd --from-brd`, from the BRD's
own `brd-link.md`, and are never asked of the PM. **`/update-prd` preserves all three and authors
none of them** — on a PRD that carries them it copies each through the refresh unchanged, and on a
PRD that does not it writes none — so the *written only by* rule above still reads exactly as it
says: carrying an existing value forward mints no new one, and `/update-prd` reads no BRD tree it
could mint one from. They record, on the PRD itself, the BRD identity and the prerequisites the
customer committed to — and **no command consumes them yet.** Neither `/epics` nor `/ready` reads any
of the three; `brd_parent` and `depends_on` have no reader anywhere in the plugin; and the one field
that is read at all is `brd_key`, read only for its **presence** — `references/prd-source-resolution.md`
step 2 treats a `brd_key` beside an absent `jira_key` as the statement that no tracker identity exists
yet. **Nothing consumes the prerequisites these fields record.** Wiring a consumer is new behaviour on
commands used heavily by non-BRD routes and belongs in its own increment with its own review. They are
written, and preserved through a refresh, because provenance recorded at authoring time is the
precondition for any future consumer: re-deriving it later would mean re-reading a BRD tree that may
have moved on. A `brd_key` may carry a third numeric segment
(`references/addressing.md` §1 fixes no depth), so a PRD authored inside a BRD slice is filed
under a key the two-segment form would reject — validate **that folder-side key**, and the
folder name built from it, against §1's grammar rather than a narrower one. This never
extends to `jira_key`, which is two-segment everywhere (below).

**`brd_key` and `jira_key` are two keys with two uses and are never interchangeable.** `brd_key` is a
folder name in `$SPECS_PATH`, validated for shape and never looked up on a tracker
(`references/addressing.md` §1); `jira_key` is what the tracker minted, and it is the only key
`jira-products/` resolves and the only one `jira-reader` accepts (`^[A-Z][A-Z0-9_]*-\d+$`). On the
`/idea` route `jira_key` is authored with the PRD, because the PM supplied a key they had already
minted. On the `--from-brd` route it is **omitted at authoring time and written by the Jira
round-trip** (`commands/create-prd.md`), the step that creates the workitem and learns its key: an
absent `jira_key` beside a present `brd_key` is the readable statement that no tracker identity
exists yet, and consumers depend on being able to make it — writing the BRD key in would make an
un-minted address indistinguishable from a minted key.

The pure Jira-mirror fields (`statusCategory`, `reporter`, `url`, `updated`, `synced`, …) are
regenerated by the importer on the round-trip and are NOT authored here. `release_versions`,
`change_type`, and `release_notes_category` belong to the same class: each is a Jira dropdown the PM
sets on the ticket, each returns on the re-import, and `/release-notes` reads them from there. Never
author them and never ask for them — deciding a dropdown value in a chat window costs exactly what
deciding it in Jira costs, so the question buys nothing.

## Spine (always, every profile)

- `## Problem` — who is affected and why the current situation is insufficient; why now. Solution-free; no implementation detail.
- `## Goal` — a crisp 2–3 sentence statement of the outcome (feeds `jira-reader`'s goal extraction and every downstream consumer).
- `## Target audience` — the personas/roles served (specific roles, not "everyone").
- `## User Stories` — `### [US#N]: <title>`, `As a [role], I want [capability], so that [benefit].` Contiguous IDs.
- `## Acceptance Criteria` — `[AC#N]` under each story; externally-observable pass/fail (no "be reliable"/"improve performance").
- `## Scope` — **In scope** (concrete delivered behaviours) / **Out of scope** (concrete confusable exclusions; never "anything else"/"future work").
- `## Success Metrics` — `[SM#N]`; measurable, technology-agnostic outcomes. Optionally add **counter-metrics** (`[SMC#1]`, `[SMC#2]`…) — a metric explicitly named as *not* to be optimized or gamed, counterbalancing a Primary SM (e.g. "throughput up, but `[SMC#1]` error-rate must not rise").

## Adapt-in menu (pulled only when warranted)

| Cluster | hybrid | full |
|---|:-:|:-:|
| `## Use cases & user journey` (`[UC#N]` narrative) | ✓ | ✓ |
| `## Non-functional requirements` | ✓ | ✓ |
| `## Assumptions & open questions` (hybrid: light list; full: Contradictions Log table — Item/Source/Impact/Resolution/Owner) | ✓ | ✓ |
| `## Why now / differentiation` | ✓ | ✓ |
| `## References / linked issues` | ✓ | ✓ |
| `## Documentation impact` | ✓ | ✓ |
| `## Short Abstract / Blogline` (Internal + External) | | ✓ |
| `## Customer Zero` | | ✓ |
| `## Competitive snapshot` (1–3 competitors × Approach / Differentiation / Pricing) | | ✓ |
| `## Functional requirements` (`[FR#N]` *Implements: `[UC#n]` / `[US#n]`*) | | ✓ |
| `## E2E Demo` (per-delivery pass/fail acceptance) | | ✓ |
| `## UX prototype / UI mockups` | | ✓ |
| `## API specification` | | ✓ |
| `## Key deliverable & plan` | | ✓ |
| `## Enablement` (launch / preview) | | ✓ |
| `## Cost analysis` | | ✓ |

## Quality rules

- **No implementation detail** anywhere — the PRD is product-level (algorithms, data structures, code paths, internal APIs belong to the ARD / spec / design).
- **Internally consistent** — no requirement contradicts another or the scope: no `[AC#N]` delivering an Out-of-scope behaviour, no `## Goal` asserting a scope the `## Scope` section contradicts, no conflicting `[US#N]`. A deliberately-kept tension is recorded under `## Assumptions & open questions`, never left implicit in a requirement.
- **FR / UC must not restate US** — reference by ID; each adds capability/behaviour, not a paraphrase.
- Acceptance criteria and success metrics are **externally observable**.
- Consolidate shared data dependencies rather than repeating them.
- Detailed **Test Cases are NOT authored here** — they are `/specify`'s `specification.md` (`[TCxx]`).

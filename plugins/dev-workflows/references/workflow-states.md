# Workflow states (embedded — shared reference)

Maps each **workflow phase** on the PRD and Epic ladders to (a) its owning role,
(b) the pipeline command that drives the transition into it, and (c) the **expected artifacts**
that should exist at that status. This is the rubric `readiness-reviewer` applies and the
source for the readiness verdict; it also feeds the PM/PA/PE/Dev workflow graph.

**Nothing outside this tree declares a status, so the artifacts are the source of truth.** The ladder
below is read in the direction its *expected artifacts* column already supports: a phase is what the
artifacts present imply, and `/ready` reports that. This reference still NEVER stores status — it
interprets what is on disk.

**An operator who keeps a tracker can still have the divergence check** the old reading gave them, by
passing what it says to `/ready --claimed "<status>"`. What is genuinely lost without that flag is
the ability to catch a *wrong* declaration: a derived phase cannot contradict itself. That is the
stated cost of removing the mirror, not an oversight.

## PRD status ladder

`Open → Problem stated → Usecases defined → Ready for Implementation → Implementation → Release Preparation → Post GA`

| Status | Role | Transition command | Expected artifacts |
|---|---|---|---|
| Open | PM | — | PRD stub |
| Problem stated | PM | /idea, /create-prd | PRD with Problem/Goal |
| Usecases defined | PM | /create-prd | PRD with user stories / use cases |
| Ready for Implementation | PE→Dev | /epics, /specify, /design | Epics defined; each in-scope Epic Refined+ with specification.md AND design.md; coverage complete; ARD (if any) respected; no cross-artifact contradictions |
| Implementation | Dev | /implement | code in progress (past the readiness gate) |
| Release Preparation | Dev/PM | /document, /release-notes | docs + release notes |
| Post GA | PM | — | shipped |

## Epic status ladder

`Open → In Preparation → Refined → In Progress → In Review → Closed`

| Status | Role | Transition command | Expected artifacts |
|---|---|---|---|
| Open | PE | /epics | Epic draft |
| In Preparation | PE | /specify | specification.md being authored |
| Refined | PE→Dev | /specify, /design | specification.md AND design.md present; coverage complete; ARD (if any) respected — **the Epic-level readiness gate** |
| In Progress | Dev | /implement | code in progress (past the gate) |
| In Review | Dev | /implement | PRs in review (past the gate) |
| Closed | Dev | — | merged/done |

> **Refine — two ways in, one mode.** `/epics` re-refines an Epic that already exists rather than
> partitioning the PRD again, and it reaches that mode from either end. **Named:** address the
> `EPIC-` folder itself (`/epics <EPIC-KEY>`) and the run re-grounds and sharpens that one Epic's
> `epic.md` in place. **Detected:** run `/epics <PRD>` where Epics under that PRD carry
> `refinement_candidate: true` — near-empty drafts left as placeholders — and the run offers
> to fill them in and partition the PRD's scope across them, instead of drafting net-new; the offer
> is confirmable, and declining it gives the ordinary net-new run. Either way it is the same
> `Open → Epic draft` transition and the same `EPIC-<PRD-KEY>-NN-<eslug>/epic.md` shape: refine
> iterates on a draft this command wrote, since **`/epics` is the only command that creates an
> `EPIC-` folder** (D6) and every one of them sits under a PRD folder. There is no `<EPIC-KEY>.md`
> file at either end — the folder carries the key, the filename carries the kind.

## Readiness targets (for `/ready`)

- **PRD** — "ready for AI-driven development" = the artifacts support the transition into **Ready for Implementation**.
- **Epic** — = the artifacts support the transition into **Refined** (spec **and** design present). **In Progress / In Review / Closed** are *past* the gate — `/ready` reports the gate is moot.

The rubric is advisory: an org may skip an optional artifact (e.g. no ARD) — that downgrades to a MINOR finding, never a hard block on its own.

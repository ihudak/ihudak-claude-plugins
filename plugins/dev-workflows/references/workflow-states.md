# Workflow states (embedded — shared reference)

Maps each Jira **workflow status** on the PRD and Epic ladders to (a) its owning role,
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

> When the PE has pre-created empty Epic shells in Jira (one per team), `/epics <PRD>` detects and **refines** them in place — partitioning the PRD scope across teams — instead of generating net-new Epics. Same `Open → Epic draft` transition; the refined drafts are keyed `<EPIC-KEY>.md` and carry a `**Team:**` line.

## Readiness targets (for `/ready`)

- **PRD** — "ready for AI-driven development" = the artifacts support the transition into **Ready for Implementation**.
- **Epic** — = the artifacts support the transition into **Refined** (spec **and** design present). **In Progress / In Review / Closed** are *past* the gate — `/ready` reports the gate is moot.

The rubric is advisory: an org may skip an optional artifact (e.g. no ARD) — that downgrades to a MINOR finding, never a hard block on its own.

# Workflow states (embedded — shared reference)

Maps each Jira **workflow status** on the VI and Epic ladders to (a) its owning role,
(b) the pipeline command that drives the transition into it, and (c) the **expected artifacts**
that should exist at that status. This is the rubric `readiness-reviewer` applies and the
source for the readiness verdict; it also feeds the PM/PA/PE/Team workflow graph.

Jira is the **source of truth** for status (imported into `jira-products/`, emitted by `jira-reader`
as `value_increment.status` + `linked_items[].status`). This reference NEVER stores status —
it only interprets it.

## VI status ladder

`Open → Problem stated → Usecases defined → Ready for Implementation → Implementation → Release Preparation → Post GA`

| Status | Role | Transition command | Expected artifacts |
|---|---|---|---|
| Open | PM | — | VI stub |
| Problem stated | PM | /idea, /create-vi | VI with Problem/Goal |
| Usecases defined | PM | /create-vi | VI with user stories / use cases |
| Ready for Implementation | PE→Team | /epics, /specify, /design | Epics defined; each in-scope Epic Refined+ with specification.md AND design.md; coverage complete; ARD (if any) respected; no cross-artifact contradictions |
| Implementation | Team | /implement | code in progress (past the readiness gate) |
| Release Preparation | Team/PM | /document, /release-notes | docs + release notes |
| Post GA | PM | — | shipped |

## Epic status ladder

`Open → In Preparation → Refined → In Progress → In Review → Closed`

| Status | Role | Transition command | Expected artifacts |
|---|---|---|---|
| Open | PE | /epics | Epic draft |
| In Preparation | PE | /specify | specification.md being authored |
| Refined | PE→Team | /specify, /design | specification.md AND design.md present; coverage complete; ARD (if any) respected — **the Epic-level readiness gate** |
| In Progress | Team | /implement | code in progress (past the gate) |
| In Review | Team | /implement | PRs in review (past the gate) |
| Closed | Team | — | merged/done |

> When the PE has pre-created empty Epic shells in Jira (one per team), `/epics <VI>` detects and **refines** them in place — partitioning the VI scope across teams — instead of generating net-new Epics. Same `Open → Epic draft` transition; the refined drafts are keyed `<EPIC-KEY>.md` and carry a `**Team:**` line.

## Readiness targets (for `/ready`)

- **VI** — "ready for AI-driven development" = the artifacts support the transition into **Ready for Implementation**.
- **Epic** — = the artifacts support the transition into **Refined** (spec **and** design present). **In Progress / In Review / Closed** are *past* the gate — `/ready` reports the gate is moot.

The rubric is advisory: an org may skip an optional artifact (e.g. no ARD) — that downgrades to a MINOR finding, never a hard block on its own.

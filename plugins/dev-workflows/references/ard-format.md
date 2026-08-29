# Architecture Requirements/Decision Document (ARD) format (embedded authority)

The canonical structure and rules for an ARD authored by `/create-ard`. `ard-reviewer` reviews against
this file, and `/ready` reads its `grounded_repos:` frontmatter. The ARD is **architecture** — invariants, grounded as-is findings, and cross-cutting
decisions — NOT product requirements (that is the PRD) and NOT a per-Epic implementation plan (that is
`/design`). One shape; **depth scales with altitude**: a PRD-level ARD stays at invariants + frame; an
Epic-level ARD goes deeper on that Epic's repos/areas.

## Altitude & scope

- **PRD-level** (`/create-ard <PRD-KEY>`) — cross-cutting invariants + broad-but-shallow grounding across the affected repos.
- **Epic-level** (`/create-ard <PRD-KEY> <Epic-KEY>`) — deeper grounding on the Epic's repos/areas; **inherits the PRD-level ARD's `AD#N` read-only** and must not contradict them.
- **Per-area** — a big Epic spanning separable areas in one repo (e.g. backend `server/` + frontend `ui/`) may split into `<EPIC>-<area>_ARD.md` (grill-decided).

## Frontmatter

```yaml
---
title: <PRD or Epic title> — ARD
scope: prd | epic
prd: <PRD-KEY>
epic: <EPIC-KEY | null>
area: <name | null>
status: draft | reviewed
grounded_repos:
  - <repo-slug @ absolute path>
inherits: <path to <PRD>_ARD.md | null>
derived_from: <path to the PRD file, canonical <PRD>_<slug>.md>
---
```

## Sections

- `## Context` — the problem/goal frame from the PRD (Epic-level adds the Epic's scope).
- `## Grounding findings (architecture as-is)` — what exists today, each claim citing a real `file:line` in a `grounded_repos` entry. An unmounted/descoped repo appears only under Open questions — NEVER as an invented "as-is" claim.
- `## Architecture decisions` — `### [AD#N]: <title>`, each with **Binds:** (what it constrains) · **Prevents:** (the divergence it stops) · **Rule:** (a single testable statement). Epic-level lists inherited PRD-level ADs read-only under "Inherited invariants".
- `## Cross-repo / component approach` — the Capability→Architecture map (which capability lands in which repo/component).
- `## Stack & invariants` — pinned versions / conventions that must hold.
- `## Edge cases & risks`.
- `## Open questions` — incl. ungrounded/descoped repos.
- `## Deferred` — PRD-level → per-Epic `/create-ard` / `/design`; Epic-level → `/design` / `/implement`.

## Quality rules

- Every "as-is" claim cites a grounded `file:line`; no fabricated/uncited architecture.
- `AD#N` are **testable** and non-overlapping (Binds/Prevents/Rule each populated).
- An `AD#N` earns its place only when the decision is **hard to reverse** AND **surprising without context** AND the result of a **real trade-off**; a decision missing any of the three is an ordinary implementation choice (leave it to `/design`), not an architecture decision.
- **PRD-level carries NO per-repo detailed solutions** — that is `/design`'s job.
- An Epic-level ARD may go deeper but stays architecture, not an implementation plan.
- Grounding is **architect-driven** (repos confirmed by the architect), never derived from PRs (which do not exist at ARD time).

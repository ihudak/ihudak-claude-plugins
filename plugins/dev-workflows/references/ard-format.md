# Architecture Requirements/Decision Document (ARD) format (embedded authority)

The canonical structure and rules for an ARD authored by `/create-ard`. `ard-reviewer` reviews against
this file, and `/ready` reads its `grounded_repos:` frontmatter. The ARD is **architecture** — invariants, grounded as-is findings, and cross-cutting
decisions — NOT product requirements (that is the PRD) and NOT a per-Epic implementation plan (that is
`/design`). One shape; **depth scales with altitude**: a PRD-level ARD stays at invariants + frame; an
Epic-level ARD goes deeper on that Epic's repos/areas.

## Altitude & scope

- **PRD-level** (`/create-ard <PRD-KEY>`) — cross-cutting invariants + broad-but-shallow grounding across the affected repos.
- **Epic-level** (`/create-ard <PRD-KEY> <Epic-KEY>`) — deeper grounding on the Epic's repos/areas; **inherits the PRD-level ARD's `AD#N` read-only** and must not contradict them.
- **Per-area** — a big Epic spanning separable areas in one repo (e.g. backend `server/` + frontend `ui/`) may split into `ard-<area>.md` beside the folder's `ard.md` (grill-decided).

## Frontmatter

```yaml
---
kind: ard                    # what this document is
key: <KEY>                   # this folder's key — must match the folder name
title: <PRD or Epic title> — ARD
scope: prd | epic
prd: <PRD-KEY — or, on the BRD route, a BRD key: the BRD's own when it owns its source document, its parent's when it is a slice>
epic: <EPIC-KEY | null — on the BRD route, the slice's own BRD key, or null for a source-owning BRD>
area: <name | null>
status: draft | reviewed
grounded_repos:
  - <repo-slug @ absolute path>
inherits: <path to the PRD folder's ard.md | null — on the BRD route, the parent BRD folder's ard.md>
derived_from: <path to the PRD file, canonical prd.md — or, in a BRD folder that holds no PRD, that folder's ard-seed.md>
---
```

**Unknown frontmatter keys are preserved.** Every command that rewrites this file keeps fields it does not recognise, in place and unmodified — the same rule `references/prd-format.md` states for a PRD, and for the same reason: a user's own field must survive a run that did not author it. `workitem_key` is the documented example, and it is reserved rather than special-cased.

**`prd`, `epic` and `derived_from` are widened for the BRD route, and the widening is confined to
them.** Under `/create-ard` on the BRD route the run holds a **BRD key**, which addresses a folder under
`$SPECS_PATH` and may carry a third numeric segment (`references/addressing.md` §1 fixes no
depth), so `prd` and `epic` are validated against that grammar — `^[A-Z][A-Z0-9_]*(-\d+)+$` — rather
than the two-segment form; `ard-reviewer` applies exactly this and `commands/create-ard.md` writes
exactly this, from one resolution rather than two. `scope` follows the same pairing it always did: a
source-owning BRD is `prd`, a slice is `epic`, because a slice sits where an Epic sits — one level
down, inheriting its parent's `AD#N` read-only. `derived_from` names the PRD file when the folder
holds one (the ordinary case, since this route is normally reached from
`/create-prd` on the BRD route's own next-step offer) and the folder's `ard-seed.md` when it does not: the
field records provenance, and naming a PRD path in a folder that holds no PRD would name a file that
does not exist. No widening here reaches a **tracker** key — none of these fields is one.

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

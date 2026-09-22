# The backlog format — `.dev-workflows/docs-backlog.yml`

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

Single source of truth for the file a documentation audit writes and every later command of this family reads: the schema in full (§1), why surfaces and units are two tables rather than one (§2), the unit status lifecycle and which of its transitions have a writer today (§3), what `blocked_by` carries (§4), what a `coverage` fraction counts (§5), where the file lives (§6), and the one invariant that is a relationship between two fields rather than a property of either (§7).

Consumed by `/docs-audit` and by the agents it dispatches — `docs-auditor`, `ia-planner` and `docs-audit-reviewer` — and, as they ship, by Spec 2's `/docs-write` and `/docs-verify` and Spec 3's `/docs-drift`, each of which names the section it is executing rather than restating it.

The vocabulary this file is written in is not defined here. **A surface kind, the page-`type` vocabulary, the four prioritisation signals, the five entry paths and the definition of done are all `${CLAUDE_PLUGIN_ROOT}/references/docs-audit/coverage-model.md`'s** — §2, §3, §5, §6 and §7 respectively. This file says what the *file* looks like; that one says what the words in it mean. Restating either half in the other is the drift this pair of files exists to prevent.

Its entry points, so a command can say which part it is executing: **the schema** (§1), **the lifecycle** (§3), **the coverage definition** (§5), **the file's location** (§6), and **the visibility invariant** (§7).

---

## 1. The schema

```yaml
schema_version: 1
generated_at: 2026-08-29
generated_by: docs-audit
sources:                              # every repo scanned, at the ref scanned
  - { repo: example-webapp, path: /workspace/example-webapp, ref: <sha>, scanned_at: <iso8601> }
  - { repo: example-api,     path: /workspace/example-api,     ref: <sha>, scanned_at: <iso8601> }
surfaces:                             # the denominator, enumerated once
  - id: order-placement
    kind: task                        # role|task|concept|reference|service|decision|release
    title: "Place an order"
    roles: [customer, admin]
    evidence:
      - { repo: example-webapp, path: src/routes/orders/new.tsx }
      - { repo: example-api,     path: app/controllers/api/v2/orders_controller.rb }
    volatility: high                  # high|medium|low, from git log density
units:                                # what gets written; many units per surface
  - id: U-001
    surface: order-placement
    title: "Place an order"
    audience: user                    # user|engineering
    visibility: public                # public|internal — defaults from audience, set independently
    type: how-to                      # user: tutorial|how-to|reference|explanation
                                      # engineering: architecture|decision|runbook|api-reference
    roles: [customer]
    priority: 1
    priority_reason: "blocks primary journey; 2 roles; evidence available"
    churn_adapted: false
    status: missing                   # missing|drafted|verified|published|stale
    page_path: docs/guides/place-an-order.md   # assigned when written
    walkthrough: null                 # W-001 once composed
    blocked_by: []
tutorial_candidates:                  # ia-planner proposes; a human picks by editing this block
  - role: customer
    journey: [order-placement, payment, order-tracking]   # surface ids, in order
    rationale: "shortest path through the three highest-priority customer tasks"
    picked: false                     # a human sets this true; /docs-audit --refresh then mints its unit
    unit: null                        # the id of the unit that mint produced; null until it has run
coverage:
  user:        { tutorial: "0/2", how-to: "3/14", reference: "0/6", explanation: "1/5" }
  engineering: { architecture: "0/3", decision: "2/2", runbook: "0/4", api-reference: "0/1" }
threshold: 2                          # "done" = every unit with priority <= threshold is published
```

`surfaces[].kind` takes the seven values `coverage-model.md` §2 fixes; `units[].type` takes the eight `coverage-model.md` §3 fixes, four legal under each `audience`. Neither list is restated here, and a run that needs one loads that file rather than reading this block's comments as the authority — a comment is an illustration of the schema, not a definition of its vocabulary.

**`tutorial_candidates[]` is the one block a run proposes and never decides.** Which journey a role should learn first is the judgement `coverage-model.md` §4 states no scan can make, so `ia-planner` writes candidates and a human picks by setting `picked: true`. Two rules keep that act from being undone by the next run. A `--refresh` run **preserves every candidate entry already in the file, verbatim**, and appends only candidates for a role that has none — regenerating the block would silently discard a human's `picked: true`, which is the one authority this quadrant has. Where it would have proposed a different journey for a role that already carries a candidate, it **says so in its report and changes nothing**: the block is the human's, and a better idea is worth telling them about and not worth overwriting them with. And a picked candidate is minted into a unit **once**: the mint writes the new unit's id into that entry's `unit:`, and an entry whose `unit:` is already set is never minted again. Without that recorded id, every later `--refresh` would mint a second tutorial unit for the same journey, each with a fresh id and none of them colliding with anything — a duplicate the collision rule in §8 cannot see, because nothing was reused.

---

## 2. Why surfaces and units are separate tables

One surface spawns several units across quadrants, and **drift is detected per surface and then fans out to that surface's units** — one detection, many consequences. A single flat list would do one of two things, both worse: duplicate the evidence on every unit, so that the same file path is recorded four times and can disagree with itself; or keep one row per surface and lose the fan-out, so that a change to a route has no way of reaching the three pages written about it.

`sources[].ref` is what makes drift computable at all. A backlog that recorded only *what* was scanned could tell you that a page exists; one that records the ref it was scanned at can tell you that the code has moved since. It is the same idea as `prep.scanned_ref` in `workflows-core:read-only-repos`, and for the same reason: a claim about a repository is only checkable against the exact commit it was made from.

---

## 3. The unit status lifecycle

`status` takes one of five values — `missing`, `drafted`, `verified`, `published`, `stale` — and moves along the transitions below and no others.

| From | To | What moves it | Which command writes it |
|---|---|---|---|
| *(none)* | `missing` | `/docs-audit` mints the unit | **`/docs-audit`, in this increment** |
| `missing` | `drafted` | a page is written for the unit | Spec 2's `/docs-write` |
| `drafted` | `verified` | the page's claims are resolved | Spec 2's `/docs-verify` |
| `verified` | `published` | the page ships | **None, in any spec** — see below |
| `published` | `stale` | the code under the page moved | Spec 3's `/docs-drift` |
| `stale` | `drafted` | the unit is re-queued for rewriting | Spec 3's `/docs-drift` |
| `missing` | `published` | `--refresh` finds a page carrying this unit id | **`/docs-audit --refresh`, in this increment** |

**Only `missing` and `published` have a command writing them in this increment**, and both writers are `/docs-audit`: the initial run mints units as `missing`, and a `--refresh` run marks `published` where a page already carries the unit id (`coverage-model.md` §6, entry path 2). Every other row names a command that does not ship yet, or none at all. **Until Specs 2 and 3 ship, a human moves a unit by editing this file** — which is the same authority `coverage-model.md` §6's entry path 5 already gives them over the file's contents, exercised on one field. That is the shipped truth and not a gap to be worked around: nothing in this increment writes `drafted`, `verified` or `stale`, and a run that reports otherwise is reporting a state nothing produced.

**One row says *None, in any spec*, and it is the row that matters most.** `verified → published` is the page shipping — a branch merged and a site deployed — which is an act in the repository and not a command of this family: `/docs-write` writes the page, `/docs-verify` resolves its claims and moves it to `verified`, and neither of them claims this edge. So **a person moves a unit to `published` on the ordinary route, in this increment and after Specs 2 and 3 ship**, and the only automated write of that value anywhere is the `--refresh` reconciliation two rows below. Stating it here is the point: the state §5's coverage fraction counts is the one state no command of this family assigns on the route pages actually take. **A page can be merged at any status, and that is not this edge** — a page carrying marked claims ships with them showing (`evidence-contract.md` §3) while its unit stays where it was. What the edge records is the unit being done, which is why it starts at `verified` and at nothing else.

**`drafted → published` is not a transition, and its absence is a mechanism rather than an oversight.** `drafted` is the state of a page this family wrote and knows it has not walked: the writing pass leaves marked claims behind precisely because it could not resolve them (`evidence-contract.md` §3). An edge from there to `published` would let the family certify its own prose on the strength of having written it, and because §5's coverage fraction counts `published` units, the grid would then go green over exactly the pages nobody checked. The only route from `drafted` to `published` runs through `verified`.

**`missing → published` is not that same edge wearing a different name, and the difference is who is asserting what.** It fires only where a page exists carrying this unit's id in its `unit:` frontmatter key while the unit is still `missing` — which means a person wrote that page and wrote that id onto it, outside anything this family ran. The transition records **a human's assertion that the page is done**, which is the same authority that lets a human edit this file at all; `drafted → published` would be the family's assertion about output it knows to be unwalked. The residual is worth stating rather than leaving to be discovered: a coverage figure raised this way rests on that person's tag and on no walkthrough, and what catches it later is the page's own `review_by` date and the evidence contract the next command to touch it applies.

---

## 4. `blocked_by`

`blocked_by` is an **open list** of short tokens naming what is stopping this unit, empty on a unit nothing is stopping. It is open because the reasons a page cannot be written are not enumerable in advance — an unavailable environment, an undecided product question, a dependency on another unit — and a closed enum would force every one of them into a wrong bucket or out of the file.

**`[surface-removed]` is the one value this increment writes.** A `--refresh` run that no longer finds a unit's surface in the scan adds it and reports the unit; the unit's `status` is not changed, because nothing about the page has moved. **A unit is never silently deleted, and never deleted at all by a run.** A surface disappearing from a scan is as likely to be a scan that failed or a repository that was not mounted as it is a feature that was genuinely removed, and a run cannot tell those apart — so it records what it observed and leaves the judgement to the person reading the report, who can delete the unit by hand if the removal was real.

---

## 5. What `coverage` counts

**Per `(audience, type)` cell, `coverage` reports the fraction of that cell's units which have reached `published`** — the numerator is that cell's units whose `status` is `published`, the denominator is every unit in that cell whatever its status. `coverage-model.md` §7 states the same definition, and the two are to be kept word for word identical: two files disagreeing about what a coverage fraction counts is how a grid comes to report done over prose nobody checked.

**It is not the number of units whose page exists.** A unit can have a `page_path`, a written page and a `status` of `drafted` and contribute **nothing** to its cell's numerator, and that is the whole point of the fraction: §3's missing `drafted → published` edge is the mechanism, and this definition is what makes the mechanism visible in a number somebody reads. A coverage figure derived from "has a `page_path`" would be green the moment prose existed.

Every figure in `coverage` is derived from the `units[]` table **in the same run that writes it**. A fraction carried forward from a previous run, or adjusted by hand, describes a backlog that is no longer the one in the file.

`threshold` is the priority at or above which `coverage-model.md` §7's definition of done applies — every unit whose `priority` is less than or equal to it must be `published`. It is a number the operator sets; nothing derives it.

---

## 6. Where the file lives

`docs-backlog.yml` lives at **`<top>/.dev-workflows/docs-backlog.yml`**, where `<top>` is the **git work-tree top level of the resolved docs repository** — what `git -C <resolved> rev-parse --show-toplevel` prints, or the resolved directory itself where it is in no git work tree. That is the one home `references/docs-profiles/docs-profile-schema.md` already pins for `docs-profile.yml` and for `/docs-serve`'s `docs-serve.state.json`, and this file joins them there rather than inventing a second rule.

**The distinction matters exactly where the resolved directory is not the top level** — a `site/` beside the code, a `website/` in a monorepo. The backlog is at the top level in both cases, never beside the content root: **one repository has one backlog, however many content roots it publishes**, because the denominator is the product's surfaces and a product does not acquire a second set of them by publishing two sites.

**The file is tracked, and reviewed in a pull request.** The scaffold's `.gitignore` block ignores `/.dev-workflows/docs-serve.state.json` by name and deliberately not the directory, because that directory also holds the committed `docs-profile.yml` (`references/docs-workflow/scaffold-tree.md`, *`.gitignore`*) — so a backlog written there is committed like the profile beside it. That is what makes `coverage-model.md` §6's entry path 5 a sanctioned act rather than a workaround: a human editing the backlog is proposing a change through the same review everything else in the repository goes through.

---

## 7. `visibility` and `page_path` are not independent

`visibility` and `page_path` look like two free fields on a unit and are not. **The shipped two-build split decides by path**: a page is internal because it sits under `docs/internal/`, which is what `exclude_docs` drops from the public build (`references/docs-workflow/visibility.md` §1, and `references/docs-profiles/frontmatter-guidelines.md` says so outright of the frontmatter key). Nothing in either build reads a `visibility` value.

**So the invariant is: `visibility: internal` ⇒ `page_path` under the internal tree.** A unit marked `visibility: internal` whose `page_path` falls outside `docs/internal/` describes a page that **ships publicly**, and no build objects — gate 1 passes, because nothing links across a boundary; gate 2 passes, because the page carries no internal marker to find. The field says internal, the artefact is public, and the two agree with each other nowhere.

This is `docs-audit-reviewer`'s to check, because it is a relationship between two fields and no single-field validation can see it: `visibility: internal` is a legal value, `docs/guides/x.md` is a legal path, and only the pair is wrong.

**The invariant is stated one way round on purpose, and the direction is the one where the cost lands.** `visibility: internal` on a public path is a **leak** — content somebody marked internal, published, with both build gates green. The other pairing, `visibility: public` on a path under `docs/internal/`, is a disagreement too, and it **fails safe**: the page simply does not ship, and a missing page is noticed far sooner than an extra one. Report both; only the first is an invariant, because only the first is a leak.

---

## 8. Hard rules

- NEVER delete a unit. A run records `blocked_by: [surface-removed]` and reports it; deletion is a human's act (§4).
- NEVER write a `coverage` figure that was not derived from the `units[]` table in the same run (§5).
- NEVER count a unit toward `coverage` on the strength of its page existing. The numerator is `published` units and nothing else (§5).
- NEVER mint a unit id that collides with one already in the file, and never mint a second unit for a `tutorial_candidates[]` entry whose `unit:` is already set (§1).
- NEVER write a `page_path` for a page that does not exist.
- NEVER write a `page_path` that contradicts the unit's `visibility` (§7).
- NEVER move a unit to `published` from `drafted`. The route runs through `verified` (§3).
- NEVER re-derive the surface kinds, the type vocabulary, the prioritisation signals or the definition of done here. They are `coverage-model.md`'s, cited by section.

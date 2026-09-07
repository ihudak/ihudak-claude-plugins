# The sibling re-cut — design

**Status:** approved in brainstorming, not yet implemented. Second of three sequenced release gates; the first shipped as `product-workflows` 2.0.0. Blocks the release under S18.

**Supersedes:** §8 of `docs/superpowers/specs/2026-09-06-slice-first-grounding-design.md`, which recorded the recommendation this design settles.

## 1. The problem

Slice-first grounding carves a slice before it is ground, so "this slice is larger than one deliverable" is a normal discovery. The route's only answer is deferral: the slice's own walk sends the rows it will not build to `deferred-to: <itself>`, and they stay its live obligation.

That is enough for "build less now" and not enough for "two independently deliverable slices". The blocker is on the **parent**: its ledger row for a delegated `[BR#n]` reads `covered-by: <SLICE-A>`, `/brd-split` walks only `unallocated` rows, and no command returns a row to `unallocated`. So a future sibling can never claim it. The "defer now, carve later" story an operator would naturally reach for does not work.

**Two mechanisms already exist for splitting work, and the line between them is not size.** `/epics` carves a PRD into `EPIC-` folders, and `/design`, `/specify` and `/ready` all work per Epic — but Epics sit downstream of the customer loop, which runs at slice level before `/create-prd`. An Epic split is invisible to the customer; a slice split is visible to them. **That is the line.** A slice too large for one delivery is an Epics problem. A slice whose split must reach the customer — a separate package, a separate conversation — is this design's problem.

## 2. Decision

**Where slice A's own ledger records a row `deferred-to: <A>`, the parent's walk may re-point its `covered-by: <A>` row to `covered-by: <B>`, for a sibling B under the same parent that has not been interviewed.** A's own row moves to `covered-by: <B>` in the same step. B's ledger seeds the row `unallocated`, B's walk takes it to `covered-here`, and B grounds it.

**The precondition carries the design.** `deferred-to: <A>` is A stating in its own ledger that it is not building this. The parent re-points against that written refusal, never over a live commitment. This is why the mechanism does not distinguish when the operator noticed: early it is a technical call from the findings, late a commercial one from the customer, and in both the movable state is identical — a row its owner has recorded it will not build.

## 3. What this takes from the existing format rather than inventing

- **A's row leaves A's interview by itself.** `/brd-interview` takes rows dispositioned `covered-here`, `deferred-to`, `rejected` or `superseded-by`; a row `covered-by: <OTHER-KEY>` is out of scope as a subject. The re-point removes the row from A's conversation with no new rule.
- **The invariant that matters is untouched.** No row returns to `unallocated`, so no satisfied gate reopens. What relaxes is the weaker "`/brd-split` never re-allocates a row that already carries a fate", and only against the owner's own recorded refusal.
- **`covered-by: <SIBLING-KEY>` gains its real producer.** `coverage-ledger-format.md` §3 already defines that disposition for a slice — a sibling under the same parent, or that parent — and its only writer today is the orphan row, a record of a claim the parent's walk withdrew. This is the case the vocabulary was shaped for.
- **The one-level nesting cap is untouched.** This carves a sibling, never a child.

## 4. A's attached history does not move

**Findings stay with A, and B re-derives.** A ground the row before deferring it, so A's `grounding/code-grounding.md` holds findings whose `claim` cites a `[BR#n]` A no longer owns. They cannot move: a finding's `id` is contiguous within its prefix and is assigned once and never renumbered. They cannot be inherited either — `workflows-core:grounding-format` §8 holds that findings carried from an earlier run are unverified by definition and must be re-derived against the commit they are pinned to. So B grounds its own inventory, at the cost of one row's re-derivation against the same pins.

**The left-behind findings need no new marker.** A's unconsumed-item report excludes findings whose claim's row A's own ledger now shows as `covered-by`, which is testable from state that already exists and mirrors the exclusion baseline findings already carry.

**Decisions stay, and stay true.** The interview covers `deferred-to` rows, so A may hold a `[VD#n]` — or a frozen `[CD#n]` — about the consequence of deferring the row. Moving the row falsifies none of it: those decisions record *A's refusal to build it*, which remains the case. The re-cut **reports** any decision in A whose `evidence` touches the moved row, so the operator sees what was said. It never edits one.

**A sibling that has been interviewed cannot receive a row.** `product-workflows:decision-register-format` §4 admits exactly two causes for reopening a decision — a new finding, or a customer decision. Adding scope is neither, so a register that exists and holds decisions is closed to this.

## 5. Edges

**B removed as empty.** `/brd-split`'s Phase 4.5 resolves a standing empty child by removal or by keeping it against a recorded reason. Where a re-pointed row's receiving sibling is removed, the row takes `deferred-to: <parent>` — kept as a live obligation of the parent, not built now. Not back to A, which refused it; not `unallocated`, which is forbidden.

**Bulk answers.** Phase 4's Step 1 uniform-answer offer already writes one disposition across a set and names any row held back. The re-cut reuses it rather than adding a second bulk mechanism.

## 6. Invocation — no new flag

On a fully-allocated parent, `/brd-split` takes the Phase-4.5-only path, and Phase 1.5 is skipped: it places unallocated rows and there are none. That phase already **notices an instruction supplied on that path and reports it unused, naming which path swallowed it** — so the argument is parsed, carried, and currently means nothing there.

`/brd-split <PARENT-KEY> "<what to peel off>"` on a fully-allocated parent therefore has an unambiguous free meaning, and this design gives it one: the re-cut. That reuses the argument the route already made mandatory for carving a root, instead of adding `--recut`.

## 7. Out of scope, stated so a reader does not reintroduce them

- No transfer of findings or decisions between slices.
- No receiving sibling that has been interviewed.
- No subdivision of a slice — the nesting cap stands, and "carve a sibling for part of a slice" is the only reachable shape.
- Epics are not touched. A slice too large for one delivery, whose split need not reach the customer, is an Epics problem and stays one.

## 8. Risks

**The re-cut relaxes a rule every `/brd-*` command reads.** No count is kept here — derive the consumers with `grep -c 'unallocated' plugins/product-workflows/commands/brd-*.md`, which returns a hit in all six, and read each. `/brd-split` owns the rule and is the only writer of `covered-here` and `covered-by`; `/brd-reconcile` writes the other three dispositions and never allocates. The relaxation is bounded to a row whose owner recorded `deferred-to`, but every consumer wants re-reading during implementation rather than trusting this paragraph. An earlier draft asserted "three commands" without deriving it; the number was wrong.

**A re-derived finding can disagree with the one left behind.** B grounds the row against the same pins, so the answers should match — but if the repository moved between A's run and B's, they will not, and A's stale finding stays on file as a record of what A saw. That is the correct outcome and it will look like a contradiction to a reader comparing two slices' grounding files.

**The reported decisions are advisory.** The re-cut surfaces what A decided about a row it is giving up, and the operator judges whether the move is still right. Nothing enforces that judgement.

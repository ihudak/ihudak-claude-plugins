# BRD-route follow-ups, from a live engagement

Reported by the operator after running the BRD route against a real customer engagement, on a **pre-split** version of the plugin. Triaged against the tree at `b774016`; each entry records whether it still reproduces. Ordered as reported — by what it cost that day.

Per **S18**, nothing releases while any of these is open.

**Status, 2026-09-06.** BRD-1, BRD-2, BRD-3, BRD-4 and BRD-6 are **closed** — see each entry. BRD-5 and the feature request are open and merged into one brainstorm, on the operator's ruling below.

## BRD-1 — `/brd-split` passes silently when a BRD has indexed frame sets and no design grounding

**CLOSED 2026-09-06** — two presence relations now run ahead of the count in `/brd-split` Phase 0 step 7, each failing when its own side comes up empty: `code-grounding.md` on main recording no `[CG#n]` (`BRD_SPLIT_NO_FINDINGS`), and a `design/` subdirectory covered by no entry in `design-grounding.md`'s frame-set list (`BRD_SPLIT_DESIGN_NOT_GROUND`, which names `/brd-ground <KEY> --no-code` as the repair). `/brd-ground` Phase 8 now writes that list — every subdirectory on disk, covered or not — which is what makes the relation checkable rather than inferred. A set explicitly skipped with `--no-design` passes and is recorded in `slices.md` as a limit on what the split could check. The gate executes `require-on-main` against `design-grounding.md` rather than reading the worktree: `--no-code` hands that file off in its own commit, so the "one commit stages them all" implication `/brd-split` inherits from its code gate does not reach it — without the gate, the repair the stop recommends could satisfy the stop with an unmerged file. `/brd-interview` carried the identical vacuous count and was fixed with it; the first pass fixed only `/brd-split`. The gate executes `require-on-main` against `design-grounding.md` rather than reading the worktree: `--no-code` hands that file off in its own commit, so the "one commit stages them all" implication `/brd-split` inherits from its code gate does not reach it — without the gate, the repair the stop recommends could satisfy the stop with an unmerged file.

**Originally reported:** The gate counts findings on file and asks whether each carries a verifier outcome — so **zero findings means zero missing outcomes** and the gate is vacuously satisfied. `EPIC-008` had two indexed frame sets and no `grounding/design-grounding.md`, and the split sailed through. A slice can reach build with its designs never reconciled.

**The gate is the wrong shape, not merely too weak.** It tests a property of the findings that exist; the failure is findings that do not. The fix is a presence relation, not a stricter count: **`design/` holding an indexed frame set while `grounding/design-grounding.md` does not exist is itself the defect.** That is the same "a relation that comes up empty must fail rather than pass" rule `check-docs.sh` states for its own checks — applied here to a runtime gate rather than a build gate.

## BRD-2 — `/brd-ground` has no `--no-code`, so BRD-1's fix is unreachable without risking the code grounding

**CLOSED 2026-09-06** — `--no-code` ships as a run mode: `grounding/code-grounding.md` is read-only for the whole run, no `[CG#n]` is produced, and every finding on file keeps its verdict, evidence and verifier outcome, un-renumbered, un-re-verified, un-rewritten. Repositories are still resolved and pinned, because a class-4 `[DG#n]` is pinned to the commit of the `[CG#n]` it cites. Documentation grounding and the derivation matrix are off under it (both write into the read-only file), and it is refused alongside `--no-design`, `--rebaseline`, an explicit `--derivation-matrix`, or against a BRD with no verified code grounding to build on.

**Originally reported:** `--no-design` appears 4 times in `brd-ground.md`; `--no-code` appears **0**. The inverse flag was never built.

The cost is concrete: on finding BRD-1, re-running `/brd-ground` to add the missing design grounding would have re-derived code grounding and put **278 verified findings** at risk. A flag that exists in one direction and not the other is not a symmetry gap — it is the difference between a fixable state and an unfixable one.

## BRD-3 — `/brd-reconcile` gates on `/brd-package`, so an out-of-band customer review can never be reconciled

**CLOSED 2026-09-06** — `--sent <path>` (repeatable) names what the customer was actually sent; each path is copied verbatim into `customer-sent-<YYYYMMDD>/` and committed beside the review before anything reads either. What the gate protects is that a quotation is checkable against a committed copy of its source document; `--sent` supplies that copy from the other direction, so the invariant holds and only its provenance changes. It replaces the package gate and nothing else, is refused where a handed-off package already exists, and the run records which of the two it worked from. The description's "from anywhere" — which meant *at any path* and was read as *of any provenance* — now says the former outright.

**Originally reported:** Its own description (`brd-reconcile.md:3`) says it takes the returned review **"from anywhere"**. Phase 0 raises `BRD_RECONCILE_NEEDS_PACKAGE` — *"no customer package on file … run `/product-workflows:brd-package` first"* — and `BRD_RECONCILE_PACKAGE_NOT_HANDED_OFF` when one exists but was never merged.

Two real customer reviews **predating the plugin** cannot become `[CD#n]` by any route. Two live contradictory instructions in one file is a defect in its own right (`workflows-core:instruction-file-maintenance`); here it also blocks the work.

## BRD-4 — a class-1 design finding is structurally unverifiable as dispatched

**CLOSED 2026-09-06** — `grounding-verifier` now requires `inventory` for every `[DG#n]`, and `/brd-ground` Phase 7 passes it: the Phase 0 step 8 claim list, unchanged, exactly as `design-grounder` was handed it. A `[DG#n]` is a reconciliation between the frame set and the inventory, and the dispatch had been supplying one side of it. It is required on classes 2, 3 and 4 as well as on class 1, because `design-grounder` already refuses to produce any `[DG#n]` without the inventory — so a caller holding a finding necessarily holds the list — and a per-class conditional is one more thing to get wrong in the direction that table exists to prevent.

**Originally reported:**

A class-1 finding asserts *"the frame shows X and no requirement asks for X"* — a **negative over the whole inventory**. `grounding-verifier`'s design-only row does not supply the inventory, so the verifier **correctly** returned `NOT-PROVABLE` and said why.

The verifier is behaving properly; the dispatch is short an input. It needs the inventory alongside the frames. Worth noting the good half: the agent reported *why* it could not prove the claim rather than guessing — the failure surfaced because the contract worked.

## BRD-5 — grounding a slice re-derives what the parent already established

A slice's inventory is a **byte-copy** of the parent's rows against the same pins, so **258 of 281 findings** would have come back identical. The route says a slice is ground exactly as its parent is, and there is no sanctioned inheritance path — so the operator took a **documented deviation** instead, which is the right move and should not have been necessary.

**Operator ruling, 2026-09-06 — this is not an inheritance problem.** The slice is the *primary* grounding site, not the derived one: slice grounding is far more detailed than the BRD's, so where the two disagree the slice wins. And the BRD-level pass is frequently not run at all — a customer asks for everything up front and then cuts scope to cut cost, so grounding and the customer interview happen **per slice only**, with nothing ever ground or interviewed at the BRD level. That is the normal case, not a degraded one.

So the question to settle is not "what may a slice inherit" but **"what is the BRD level still for once the slice carries the work"** — and the two open items below fall out of it rather than standing alone:

- **The route's own gates assume the BRD level ran.** `/brd-split` and `/brd-interview` each `require-on-main: grounding/code-grounding.md`, and `/brd-package` gates on `decisions.md`. Under the ruling those are gates on an artifact that legitimately never exists, which makes the normal path the blocked one. Whatever replaces them is the substance of this item.
- **Inheritance survives as the smaller half.** Where a BRD-level pass *was* run, re-deriving 258 identical findings is still waste — but it is now an optimisation over an optional input, not the mechanism the route depends on.

**Merged with the feature request below**, which is the same reframing seen from the customer side: per-slice interview packages are the valuable form and the BRD-level round becomes optional. One brainstorm settles both.

## BRD-6 — the `[CG#n]` id key is written two ways in one file

**CLOSED 2026-09-06** — `workflows-core:grounding-format` gains §2.1, which fixes the on-disk serialisation (one space after every colon, never alignment padding, keys in §2's order, an inapplicable field omitted rather than empty) and states the reading rule that outlives the fix: resolve an id against the finding set you parsed, never by column, and report a disagreeing count as a parse failure rather than an absence. `/brd-ground` Phase 8 cites it as the writer's contract — **and so do both grounder agents**, whose Output templates taught the column-aligned spelling the section forbids and were what the model producing the findings actually copied. Fixing only the file's writer left the defect intact one hop upstream; a review caught it.

**Originally reported:** Aligned in section 1 (`- id:       [CG#1]`), single-space in section 2. A `^  - id: \[CG#` regex silently matches only one of them. **Cost a false "140 phantom gaps" report earlier in the same engagement.**

This is this repo's own "resolve against a known set, never parse out of free text" rule meeting an emitted artifact: the *writer* is inconsistent, so every reader that pattern-matches is wrong in a way that looks like data. Fix the writer, and say which spelling is canonical.

## Filed elsewhere, recorded here so the set is complete
- **#71** — `/frames` never converges on an unreadable frame.
- **#73** — blind verification. Still only drafted in the operator's scratchpad.

## Feature request — customer interview packages per slice

Today the customer loop is BRD-level. The request, in priority order:

1. **Per-slice packages are the valuable form.** With many slices, a customer sees fewer questions per package, so answers are more accurate and worth more.
2. **BRD-level should become optional**, or at least **question-capped**, since the follow-ups will arrive on the slices anyway.
3. Ideally both levels exist and the operator chooses.

Not a defect. Recorded here because it changes `/brd-package` and `/brd-interview`'s addressing model — a slice is already a first-class folder, so the addressing exists; what does not is the decision about where a round lives and how the two levels compose.

**This is BRD-5 seen from the customer side**, and the operator's ruling there settles the priority question here: the slice level is primary and the BRD level optional, in grounding and in the customer loop alike. Brainstorm the two together.

---

# Review ledger — opened 2026-09-06 by the whole-diff review of the ledger-closing commits

Three Opus reviewers ran over `7b47f23..ed4334c` on orthogonal dimensions — claims against the tree, contradictions and text the change falsified, and class completeness. They returned **54 raw findings, ~35 distinct**. Everything attributable to that diff is fixed in the commit that carries this section. What follows is what the review surfaced that the diff did **not** introduce — pre-existing defects the review found while checking it.

Per **S18** these gate the release exactly as the BRD-route defects did. None is script-visible: all seven build gates were green with every one of them in the tree.

## R-1 — `/ready` has no non-emptiness guard on `requirements[]`, where `/epics` has exactly that guard

`/epics` refuses an empty ground truth outright, naming the reason: proceeding "would let every Epic pass coverage vacuously". `/ready` builds the same `requirements[]` ground truth from the same PRD and has no such test; `readiness-reviewer` refuses only on the field being *absent*, not empty. A PRD stating no requirement IDs yields a 0/0 = 100% coverage roll-up and can return **SUPPORTED** — the verdict `/implement` is offered on. Same class as BRD-1, same shape as the `/brd-split` and `/brd-interview` gates fixed this week, in two commands that read one file and disagree.

## R-2 — `/brd-reconcile` never gates on a reader digest that yielded nothing

`BRD_RECONCILE_UNCONFIRMED`, `UNDISPOSED_CORRECTION` and `UNSWEPT` all count *undisposed* items, so a `customer-review-reader` return with zero decisions, zero `required_changes` and zero challenges satisfies all three vacuously: the run freezes zero `[CD#n]`, sweeps nothing, writes a reconciliation record and reports success. The presence half already exists and is unused — the digest records each of the twelve sections as `present`, `stated-none` or `absent`, "two facts that are never merged", and nothing branches on it.

## R-3 — `/brd-package` step 7 is vacuous on zero round files

*"Stop unless every question in every round carries either a terminal disposition or the holding state"* is vacuously true with no round files. Largely covered by step 8's `BRD_PACKAGE_NOTHING_TO_REVIEW`, which does test presence — the live hole is a `decisions.md` carrying `[VD#n]` whose round records never merged. Note this rests on the same "one commit stages the siblings" assumption `--no-code` falsified for `/brd-split`; `/brd-reconcile` carries an explicit paragraph qualifying it and `/brd-package` does not.

## R-4 — `--docs <path>` is declared by the shared reference for nine consumers and parsed by one

`workflows-core:docs-grounding` §1's *Flags first* rung declares `--docs <path>` for all nine of its consumers. **Only `/idea` parses it.** The other eight take `--no-docs` and nothing else, and several then classify `$ARGUMENTS` "minus every recognised flag" — so `--docs` and its path argument fall through into the address classification. This is BRD-2's shape and slightly worse: the off switch exists everywhere, the point-it-elsewhere switch exists once, and the shared reference documents it as though it existed in all nine. An operator whose docs are not at `$DOCS_PATH` can only turn grounding off.

## R-5 — `phase-handoff.md` §4.0's register classifies 13 artifacts against a `deliverable_paths` universe of ~30

§4.0 now says outright that it classifies the artifacts whose class a producer has had to resolve, rather than everything the family hands off, and that an unlisted path is unclassified rather than unread — so a producer is no longer misled. But the gap itself stands: `interview/round-<N>.md`, `brd/brd-inventory.md`, `brd-link.md`, `grounding/baselines.md`, the three altitude seeds, `interview/customer-questions.md`, the `/brd-package` outputs, `reconciliation-<D>.md`, `slices.md`, `/specify`'s and `/design`'s session and glossary files, and `/update-prd`'s archived revision all lack a row, and several have readers that **stop**. Most ride in a set that already contains a gated path and are carried by the strongest-class rule, which is why nothing has misbehaved yet — `/brd-ground --no-code` was the first set containing no classified path at all, and it is what exposed this.

## Recorded, not counted as defects

- The three reviewers each independently confirmed the `/frames` consent-array contradiction, which is the strongest signal in the set that the dimensions were genuinely orthogonal rather than three passes at the same reading.
- `grounding-verifier` gained `STALE_INDEX` rather than having the claim deleted from three files: `/brd-ground` Phase 7 already handled that status with a well-reasoned remedy the agent could never trigger, so the contract was the half that was wrong.

# BRD-route follow-ups, from a live engagement

Reported by the operator after running the BRD route against a real customer engagement, on a **pre-split** version of the plugin. Triaged against the tree at `b774016`; each entry records whether it still reproduces. Ordered as reported — by what it cost that day.

Per **S18**, nothing releases while any of these is open.

## BRD-1 — `/brd-split` passes silently when a BRD has indexed frame sets and no design grounding

**Still present.** The gate counts findings on file and asks whether each carries a verifier outcome — so **zero findings means zero missing outcomes** and the gate is vacuously satisfied. `EPIC-008` had two indexed frame sets and no `grounding/design-grounding.md`, and the split sailed through. A slice can reach build with its designs never reconciled.

**The gate is the wrong shape, not merely too weak.** It tests a property of the findings that exist; the failure is findings that do not. The fix is a presence relation, not a stricter count: **`design/` holding an indexed frame set while `grounding/design-grounding.md` does not exist is itself the defect.** That is the same "a relation that comes up empty must fail rather than pass" rule `check-docs.sh` states for its own checks — applied here to a runtime gate rather than a build gate.

## BRD-2 — `/brd-ground` has no `--no-code`, so BRD-1's fix is unreachable without risking the code grounding

**Still present, verified:** `--no-design` appears 4 times in `brd-ground.md`; `--no-code` appears **0**. The inverse flag was never built.

The cost is concrete: on finding BRD-1, re-running `/brd-ground` to add the missing design grounding would have re-derived code grounding and put **278 verified findings** at risk. A flag that exists in one direction and not the other is not a symmetry gap — it is the difference between a fixable state and an unfixable one.

## BRD-3 — `/brd-reconcile` gates on `/brd-package`, so an out-of-band customer review can never be reconciled

**Still present, and the command contradicts itself.** Its own description (`brd-reconcile.md:3`) says it takes the returned review **"from anywhere"**. Phase 0 raises `BRD_RECONCILE_NEEDS_PACKAGE` — *"no customer package on file … run `/product-workflows:brd-package` first"* — and `BRD_RECONCILE_PACKAGE_NOT_HANDED_OFF` when one exists but was never merged.

Two real customer reviews **predating the plugin** cannot become `[CD#n]` by any route. Two live contradictory instructions in one file is a defect in its own right (`workflows-core:instruction-file-maintenance`); here it also blocks the work.

## BRD-4 — a class-1 design finding is structurally unverifiable as dispatched

A class-1 finding asserts *"the frame shows X and no requirement asks for X"* — a **negative over the whole inventory**. `grounding-verifier`'s design-only row does not supply the inventory, so the verifier **correctly** returned `NOT-PROVABLE` and said why.

The verifier is behaving properly; the dispatch is short an input. It needs the inventory alongside the frames. Worth noting the good half: the agent reported *why* it could not prove the claim rather than guessing — the failure surfaced because the contract worked.

## BRD-5 — grounding a slice re-derives what the parent already established

A slice's inventory is a **byte-copy** of the parent's rows against the same pins, so **258 of 281 findings** would have come back identical. The route says a slice is ground exactly as its parent is, and there is no sanctioned inheritance path — so the operator took a **documented deviation** instead, which is the right move and should not have been necessary.

Needs a real decision, not a shortcut: what makes a parent finding safely inheritable by a slice (same pin, same row, unchanged since), and what forces re-derivation.

## BRD-6 — the `[CG#n]` id key is written two ways in one file

Aligned in section 1 (`- id:       [CG#1]`), single-space in section 2. A `^  - id: \[CG#` regex silently matches only one of them. **Cost a false "140 phantom gaps" report earlier in the same engagement.**

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

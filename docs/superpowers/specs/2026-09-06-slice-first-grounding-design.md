# Slice-first grounding and interviewing — design

**Status:** approved in brainstorming, not yet implemented.
**Supersedes:** the BRD-5 entry and the per-slice-interview-packages feature request in `docs/superpowers/brd-route-follow-ups.md`. Both are closed by this design rather than by a patch.

## 1. The problem, restated correctly

BRD-5 was filed as *"grounding a slice re-derives what the parent already established"*, with a proposed fix along the lines of an inheritance mechanism: work out which parent findings a slice may safely adopt. Triage against the tree found that framing wrong in two ways.

**The four later commands already work slice-first.** `/brd-ground`, `/brd-interview`, `/brd-package` and `/brd-reconcile` each accept either level a `<BRD-KEY>` can name and each gates the **resolved** folder's own artifacts. A slice holds its own findings, its own ledger, its own register and its own `[C]` question set. The ledger entry claimed three gates "assume the BRD level ran"; they do not.

**One gate forces the parent pass.** `/brd-split` on a root executes `require-on-main` against that root's `grounding/code-grounding.md`. So no slice can exist until the root is ground — and every slice then re-derives the same rows against the same pins. On the reporting engagement that was 258 of 281 findings.

**What the parent pass actually buys is a capability the operator does not use.** `/brd-split` Phase 2 reads each unallocated requirement's `verdict` and `horizon` and clusters into buildable / needs-reconsidering / blocked / depends-on candidate slices. Phase 4's allocation walk reads no findings at all. The operator supplies the grouping through `/brd-split <KEY> <instruction>` in both of their working modes — a customer prioritising one urgent slice, or their own development-sequencing cut — so the clustering is paid for and unused.

## 2. Decision

**Grounding and the customer interview happen at the slice and nowhere else.** The root BRD keeps intake and the coverage ledger; it gives up grounding and interviewing entirely.

This is a protocol, not a menu. The root level is not left *capable* of grounding for a rare case: a small BRD is a one-slice BRD, and the route's guarantees about quality, speed and cost hold only if one path is followed. So the four commands **refuse** a root rather than merely not requiring one.

Three reasons carried the decision:

- **Grounding cost scales with the document; its value scales with what gets built.** A row that `deferred-to` marks as a live obligation may never be built, and grounding it is speculative work at full price — paid twice, once in delivery time and once in the customer interview attention it consumes.
- **The capability the root gate protects is unused**, and keeping a gate to defend an uninvoked capability is what YAGNI is for.
- **The engagement-level record already exists without findings.** The root's `coverage-ledger.md` carries every `[BR#n]` with a terminal fate. That is what the customer's whole document maps onto, and it needs no grounding to be complete.

## 3. The protocol

```
1. /brd-intake    <BRD> @<file>        inventory + ledger; every row unallocated
2. /brd-split     <BRD> <instruction>  carve slice(s); allocate root rows;
                                       seed each slice's rows unallocated
3. /brd-ground    <SLICE>              the slice's findings
4. /brd-split     <SLICE>              the slice's own commitment, row by row
5. /brd-interview <SLICE>              the slice's register
6. /brd-package   <SLICE>              the slice's bundle
7. /brd-reconcile <SLICE>              the slice's reconciliation
8. /create-prd    <SLICE> → /create-ard → /specify → /epics → /design → /ready
```

**Why `/brd-split` appears twice, and why grounding sits between the two.** The root's walk decides where a row *goes*: it writes the slice's `claims:` entry, copies the inventory row across, and seeds one `unallocated` ledger row per claimed `[BR#n]` on the slice. The slice's own walk then decides whether the slice *builds* it — `covered-here`, or `covered-by` a sibling or the parent, or `deferred-to`, `rejected` or `superseded-by`. Those are two different decisions and the second is the slice's to make.

The ordering is not incidental and it is already enforced: `/brd-split` gates the **resolved** folder's `grounding/code-grounding.md`, which on a slice run is the slice's own, so step 3 must precede step 4. The consequence is the reason to prefer this design rather than a cost of it — the operator commits row by row **with the findings in hand**, so a requirement grounding shows to be blocked takes `deferred-to` or `rejected` at the moment of commitment, before anything downstream reads it. A brainstorming objection that a mis-cut slice could not be corrected was raised against this design and retracted on that ground.

Where the instruction named exactly the rows to be built, every row lands `covered-here` and step 4 is one confirmation rather than N: Phase 4's Step 1 uniform-answer offer writes one disposition across the set and names any row held back.

## 4. Changes

### 4.1 `/brd-split` — the grounding gates become slice-only

On `split_mode: allocate-only` every existing Phase 0 gate stands unchanged, including the three-test step 7: code grounding non-empty, design grounding on main covering every `design/` frame set, every finding carrying a verifier outcome. That is the correct home for all three — a slice is where designs live and where the findings are.

On `split_mode: full` the grounding gates do not run at all. There is no root grounding to gate, in this protocol or ever. The `coverage-ledger.md` gate stays: the root's ledger is `/brd-intake`'s deliverable and the walk reads it.

### 4.2 `/brd-split` — the instruction becomes required on a root

Phase 2's clustering by `verdict` and `horizon` is unreachable without findings, so it is replaced rather than degraded: on a root split the grouping comes from the instruction, and a root run invoked without one stops. Phase 1.5 already reads an instruction in both modes and seeds both the grouping and the walk's recommendations, so this promotes an existing input rather than adding a mechanism.

This is the design's one new hard requirement, and it was confirmed explicitly in brainstorming rather than inferred.

### 4.3 Four commands refuse a root

`/brd-ground`, `/brd-interview`, `/brd-package` and `/brd-reconcile` each currently state that they refuse neither level and behave identically at both. Each instead refuses a resolved root and names the way forward — `/brd-split <ROOT-KEY> <instruction>` to carve a slice, then the same command against the slice.

The refusal tests the **directory prefix**, not the folder's asserted kind. A slice is a `PRD-` folder asserting `kind: brd`, and an asserted-kind test would refuse every slice and accept nothing. `workflows-core:addressing` and `product-workflows:coverage-ledger-format` are the authorities on that contradiction being load-bearing; this design adds no new kind rule.

On a folder resolved through the legacy unprefixed fallback there is no prefix to test, so the root question is answered by positive evidence that the folder *is* a root — a ledger or inventory present with no `brd-link.md` naming a `parent:` — never by the absence of a file, which would refuse a legacy idea-route folder.

### 4.4 Documentation and the shared reference

`phase-handoff` §3.4's rows for these commands narrow to the slice level. `brd-workflow.md`'s route map and folder-layout tree, `CLAUDE.md`'s workflow map and BRD-route paragraph, and the five affected command pages under `product-workflows/docs/` all describe a two-level model that this design retires.

## 5. What this closes, and what it does not

**Closed by construction.** The per-slice customer interview package request needs nothing built: packages are per-slice because that is the only level, and its "BRD-level should become optional or question-capped" half dissolves. BRD-5's inheritance half likewise disappears — with no root pass there is nothing to inherit, and the operator confirmed they would not return to ground a root after grounding a slice.

**Out of scope, and worth its own spec.** Extending verified grounding to the idea route — so that a PRD folder authored from an idea gets the same `[CG#n]` foundation a slice gets — was raised in the same brainstorming and deliberately excluded. `/brd-ground` builds its claim list from `brd/brd-inventory.md`'s `[BR#n]` rows, and an idea-route folder has none; giving that route grounding means choosing a new claim source, which is a design decision rather than a clause. The two routes are today unequal in exactly this way and it is worth fixing next.

## 6. Risks

**The root ledger can stay partly unallocated indefinitely, and that is intended.** Where a customer prioritises one slice and never commissions another, the remaining rows take `deferred-to: <this BRD>` — "kept as a live obligation of this BRD, not built now". The vocabulary already says this; no disposition is added.

**A root split now depends on the operator's instruction being good.** Nothing derived checks the cut. That is the trade accepted in §2: the clustering that would have checked it required grounding the whole document. The slice's own walk, run after slice grounding, is where a bad cut surfaces.

**The refusals are a breaking change to a shipped route.** The six `/brd-*` commands existed in `dev-workflows` at tag `v3.24.1`, which is an ancestor of `HEAD` and is contained in remote branches, so the two-level model has been in users' hands. An earlier draft of this section asserted the opposite — that nothing had shipped, so no migration was owed — on the strength of this session's commits being unpushed. That was a generalisation from the current branch to the route's history and it was wrong.

So a root BRD may already carry root-level `grounding/code-grounding.md`, `decisions.md`, round records and a package built under the old model, and after this change no command will read them. **The disposition for that state is an open decision** (§7).


## 7. Open decision — what happens to a BRD already ground at root level

The route shipped with the two-level model, so engagements exist whose root BRD carries grounding, a register and possibly a sent package. Three dispositions, and this design does not pick one:

- **Declare it breaking and let those engagements finish on the older plugin version.** Cleanest against §2's protocol decision; costs any in-flight engagement a version pin.
- **Refuse, but name the state.** The four stops detect root-level artifacts where they exist and say the level moved, rather than reporting the key as wrong. The operator re-enters through `/brd-split` and the root's findings are abandoned in place — never deleted, since they are a record of work done.
- **Read-only compatibility.** Root-level artifacts already on disk stay readable by the commands that consume them, while no command ever produces new ones. Gentlest for in-flight work, and the one option in tension with §2: it keeps a second level alive in the reading direction.

The second is the recommendation. It honours the protocol without silently orphaning an operator's committed work, and it costs one detection test per refusal rather than a compatibility path through four commands.

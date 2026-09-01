# Specs-Native Pipeline — Increment E: the BRD is a container

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce D5 and D6 — a BRD is a container that is never implementable, and an Epic comes only from a PRD — then make the BRD route and the idea route genuinely identical downstream, and clear the residue the tracker cut left behind.

**Architecture:** D5 and D6 were decided in the design and are *partly* built. `/brd-split` already creates `PRD-<CHILD-KEY>-<slug>/` folders (increment A), and 3.5.0 already removed `covered-here` from the parent picker. What is missing is the **refusal**: nothing stops a root BRD from reaching a PRD, and `/create-prd` still argues in prose that it should. This increment closes the gap structurally rather than by data inspection, retires the last Epic-without-a-PRD paths, and removes the "round-trip" that no command performs.

**Tech Stack:** Markdown only. No test framework. Failing grep assertion → edit → assertion passes → three repository gates.

**Spec:** `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` — D5, D6, D4, D7, §4.1, §6.3. Amend the spec with an R-row where this increment changes a decision's consequences, as R18/R24 already do in the BRD design.

**Predecessors:** A (3.5.0), B (3.6.0), C (3.7.0), code-handoff (3.8.0), D (3.9.0), the ports (3.10.0–3.12.0), and the whole-design review round 1 (3.13.0) — all merged.

## The thing this increment is really fixing

**The plugin currently argues *for* the behaviour the design forbids.** `commands/create-prd.md` (search `Neither is what an unsliced BRD reaches`) states that a BRD walked entirely to `covered-here` without carving a slice "is the route's ordinary shape" and "passes both refusals", citing "§4 — the walk's escape valve exists precisely so an unsplit BRD can complete."

That escape valve was **deleted in 3.5.0** (`commands/brd-split.md`, search `the escape valve it used to be is gone with it`). So the paragraph justifies current behaviour with a mechanism that no longer exists — and the gate above it still implements that behaviour: for a root BRD the gate set is "every row of its `coverage-ledger.md`", and §5's `covered-here` test is then applied **with no level check**.

The same passage argues that reading `claims:` at root level "would … refuse the ordinary never-split BRD that is this route's primary case." Under D5 that refusal is the *correct* outcome. The code defends against the behaviour we want.

**So this is not a stale-sentence sweep.** The prose, the gate, and the design disagree three ways, and the prose is the only one anybody would read.

## What makes the fix small

**The check is structural, not data-shaped.** Kind prefixes shipped in increment A, so `/create-prd` can refuse a `BRD-` folder before reading a single ledger row. The eligibility machinery — no row `unallocated`, at least one `covered-here`, narrowed by `claims:` on a slice — exists to decide whether a *root* may hold a PRD. Once a root never may, most of that question disappears, and with it the class of defect where a command and its format authority disagree about which rows count.

**No migration is needed.** No PRDs have been authored from a root BRD in any live specs repo, confirmed with the maintainer. The stranded-BRD risk that would otherwise gate this increment does not exist. Do **not** build a migration path or a legacy carve-out.

## Global Constraints

- **Every constraint from A, B, C and D still binds.**
- **Refuse by kind, not by data.** A `BRD-` folder stops before its ledger is read. Do not express D5 as a new disposition rule.
- **A slice folder is `PRD-`-prefixed but asserts `kind: brd`.** `commands/brd-split.md` writes `brd-link.md` with `kind: brd` into the `PRD-` folder, and `references/addressing.md` reads kind off the first artifact carrying both fields. **Any kind gate must test `prd.md`'s own `kind: prd`, never the folder's asserted kind.** This is the single most likely way to get E2 wrong.
- **Line numbers drift.** 3.13.0 moved 64 files. Anchor every edit on quoted text, not on a line number from this plan.
- **A count and the thing it counts change in the same commit.**
- **No stop or offer may name a command, path, artifact or argument form that cannot resolve in the state it reports.** The BRD work has produced fifteen defects of this one anatomy; three consecutive fix rounds of one earlier task each *introduced* one while fixing one.
- **Vendor-neutral.** No customer or company name anywhere.
- **Branch first**, `iv-gu/specs-native-increment-e`.

## Repository Gates — run after every task

```bash
cd /workspace/ihudak-claude-plugins
./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && python3 scripts/validate-catalog.py
```

Counts to hold unless a task deliberately moves one: **27 commands / 37 agents / 105 reference files.**

## Assertion discipline

Every task states a grep that **fails before the edit and passes after**. Write the assertion first, watch it fail, then edit. An assertion that passes before the work is not an assertion.

---

### Task E1: `/create-prd` refuses a BRD container

**The rule.** A `BRD-` folder is never a valid `/create-prd` target. Only a `PRD-` folder is — whether it came from `/brd-split` (carrying `brd-link.md`) or from `/idea`.

- [ ] Add a **level refusal** to `commands/create-prd.md` Phase 0, ahead of both existing data refusals, with its own error code (`CREATE_PRD_BRD_NOT_SLICED` or similar). It fires on a resolved `BRD-` folder and names `/brd-split <BRD-KEY>` as the remedy. It must fire **before** any ledger row is read.
- [ ] Verify the remedy resolves from the refusing state: `/brd-split` on that BRD must actually be runnable. If the ledger is already fully allocated, `/brd-split` is a no-op — say what the operator does then, or the refusal is a dead end.
- [ ] Delete the `Neither is what an unsliced BRD reaches` paragraph entirely. It asserts a retired mechanism as current.
- [ ] Collapse the gate set logic: refusal 1 (`CREATE_PRD_BRD_UNALLOCATED`) and refusal 2 (`CREATE_PRD_BRD_NOT_ELIGIBLE`) become **slice-only**. Rewrite the root branch of the gate-set paragraph — including the argument that reading `claims:` at root level "would refuse the ordinary never-split BRD", which is now the desired behaviour.
- [ ] Rework refusal 2's diagnostic table. Its root-reachable rows move into the new refusal; the remainder become slice-only.
- [ ] `references/coverage-ledger-format.md` §5: state PRD-eligibility as **a check the consumer performs** (read `brd-link.md` for `parent:`), not as an inference from what the walk offers. Add the root case to §5's consumer table: every root row ends `covered-by`, `deferred-to`, `rejected` or `superseded-by`.
- [ ] Move the namespace argument into §5 — a BRD that could be split *and* hold a PRD would carry PRD folders and Epic folders as siblings, which `references/addressing.md` invariant 2 forbids. It is currently argued only in `commands/brd-split.md`, while §5 is the authority the refusals cite.
- [ ] `brd_parent` is now **always present** on the BRD route. Update `references/prd-format.md` and `commands/create-prd.md`, which document it as "omitted when it owns its source document", and `commands/update-prd.md`, which repeats it.
- [ ] `agents/prd-reviewer.md` currently ratifies the omission — "`brd_parent` and `depends_on` are each legitimately omitted when the BRD has no parent" — so it would **pass an illegal root PRD**. An absent `brd_parent` beside a present `brd_key` becomes a finding.
- [ ] **`/create-ard` accepts a `BRD-` folder too, and must stop doing so.** `commands/create-ard.md` Phase 0 routes "a `BRD-` folder, **or** a `PRD-` folder holding a `brd-link.md`" to the BRD route. But §4.1's tree places `ard.md` only inside a PRD folder — a `BRD-` folder holds `brd/`, `grounding/`, `interview/`, `coverage-ledger.md`, `decisions.md` and `slices.md`, and no ARD. So `/create-ard <ROOT-BRD>` authors an artifact the tree has no place for. Narrow the BRD route to **a `PRD-` folder carrying `brd-link.md`** — which is what a slice is — and refuse a `BRD-` folder with the same remedy as E1's `/create-prd` refusal.
- [ ] Check `/specify` for the same acceptance and apply the same narrowing.
- [ ] `commands/brd-reconcile.md`: the `/create-prd` offer's conditions, in both the prose menu and the `choices:` array.
- [ ] `references/next-phase-offer.md`: the `/brd-reconcile` advance condition.
- [ ] `commands/brd-intake.md`: "once this BRD is PRD-eligible", said of the root BRD it just created.
- [ ] `references/addressing.md`: "a BRD-route PRD sits inside its BRD" must say inside the `PRD-` slice folder, not inside the `BRD-` folder.
- [ ] Docs: `docs/brd-workflow.md`, `docs/workflow.md`, `docs/commands/brd-reconcile.md`, `docs/commands/create-prd.md` — edge labels, condition columns, refusal lists. The two diagrams must still agree edge for edge; verify by extracting `(source, style, label, target)` tuples and diffing the sets, not by eye.
- [ ] Amend `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md`, whose §4.1 and picker section still describe the five-choice parent picker and `--from-brd`, unamended since 3.5.0. Add an R-row.

**Assertion:**
```bash
# fails before, passes after
! grep -q "unsliced BRD" plugins/dev-workflows/commands/create-prd.md
grep -q "CREATE_PRD_BRD_NOT_SLICED" plugins/dev-workflows/commands/create-prd.md
```

**Walk both shapes and record the verdict for each:** a root `BRD-` folder with one `covered-here` row (must now refuse, naming a reachable remedy), and a `PRD-` slice folder with one `covered-here` row (must still proceed). A fix proved only on the failing case is not proved.

---

### Task E2: Epics come from a PRD only — and `/epics <EPIC>` re-refines

**The rule.** `/epics` accepts a `PRD-` folder (draft new Epics) or an `EPIC-` folder **that has a PRD above it** (re-refine that Epic). A stand-alone `EPIC-` folder refuses. Nothing else creates an Epic folder.

- [ ] `commands/epics.md` calls `resolve-address` with **no `<KIND>` argument**, so a `BRD-` folder, an `EPIC-` folder or a slice all resolve and the run proceeds. Add the kind gate — and gate on **`prd.md`'s `kind: prd`**, not the folder's asserted kind, because a slice folder asserts `kind: brd` (see Global Constraints).
- [ ] Revive the dead refine path rather than writing a new one. `/epics` still parses `focus_key` from an explicit `<PRD> <Epic>` pair but never sets it, so refine-by-focus is currently unreachable and an `EPIC-` address is silently treated as a PRD. Derive `focus_key` from a resolved `EPIC-` folder the way `commands/specify.md` already does.
- [ ] Refuse a stand-alone `EPIC-` folder — one with no PRD above it — with a stop that says why and names no command it cannot reach.
- [ ] Retire the stand-alone top-level Epic case: `commands/specify.md` (which defines "a stand-alone top-level Epic (no parent PRD)"), `commands/design.md`, `docs/commands/specify.md`, `docs/commands/design.md`, `docs/commands/implement.md`.
- [ ] `commands/create-ard.md` and `commands/specify.md` each **auto-create an absent `EPIC-` folder** on first write. Both must refuse instead: an Epic folder is minted by `/epics` and by nothing else.
- [ ] Confirm no offer anywhere names `/epics` from a non-PRD artifact. This was clean at 3.12.0 — re-verify, do not assume.

**Assertion:**
```bash
# fails before, passes after
grep -q "kind: prd" plugins/dev-workflows/commands/epics.md
! grep -q "stand-alone top-level Epic" plugins/dev-workflows/commands/specify.md
```

**Walk four addresses:** a `PRD-` folder (drafts), an `EPIC-` folder under a PRD (re-refines), a stand-alone `EPIC-` folder (refuses), a `BRD-` folder (refuses). Name the file and step at each gate.

---

### Task E3: the round-trip that no command performs

**Bug-first. This is residue from cutting the tracker, and it is live today.**

- [ ] Six sites defer work to "the round-trip": `commands/create-prd.md` defers the PRD's `key` to "the round-trip's step 1"; `agents/prd-reviewer.md` excuses an absent `key` because "the round-trip has since written it"; `commands/specify.md`'s stop text says a BRD "completes its round-trip". `references/followup-emission.md` states plainly that **no command performs a round-trip**. A BRD-route PRD's `key` is therefore never written by anything, permanently. Decide where `key` is written now — most likely by `/create-prd` on both routes — and make every site say it.
- [ ] `commands/create-prd.md` also says `release_versions`, `change_type` and `release_notes_category` come back via "the importer … on the round-trip" and that `/release-notes` "reads them from the import". `references/prd-format.md` reversed this: they are authored fields. Stale on both routes.
- [ ] Two-key offer forms violate D4 and cannot resolve: `commands/create-ard.md` and `references/next-phase-offer.md` still offer `/specify <PRD> <Epic>`, `/design <PRD> <Epic>` and `/create-ard <PRD> <Epic>`, while each of those commands now takes a **single** positional address. Six sites.
- [ ] `/idea` violates D7 in its own description: `commands/idea.md` says it "relocates `idea.md`", and `references/addressing.md` lists `/idea` as adopting resolution at "Phase 5 relocation" — but `/idea` writes in place and never relocates.

**Assertion:**
```bash
# fails before, passes after
! grep -rn "round-trip" plugins/dev-workflows/commands/ plugins/dev-workflows/agents/ \
  | grep -v "CHANGELOG"
```

---

### Task E4: the two routes become identical

**The rule.** From the PRD onward, behaviour does not depend on whether a BRD is behind it. Divergence is allowed only where the BRD genuinely carries something extra — a decision register, grounding findings, a coverage ledger.

`/epics`, `/design`, `/implement`, `/ready`, `/release-notes` and `/document` already contain **zero** BRD branches. The asymmetries are confined to two commands.

**Read E1's `/create-ard` narrowing first — it resolves most of this task.** Once the BRD route means "a `PRD-` folder carrying `brd-link.md`", the route is a *PRD folder in every case*, and the asymmetries below stop being judgement calls.

- [ ] `commands/create-ard.md`: the PRD `require-on-main` gate is skipped on the BRD route, and the rationale is **internally coherent as written** — "the PRD … may not exist at all, since `/create-prd` on the BRD route is not a prerequisite for this one". Do not simply delete it. After E1, the route resolves a PRD folder, so the gate can run on both routes and its existing `absent` branch already handles "PRD not yet authored in this slice" gracefully — it reports and architects from the folder. Make the gate unconditional and let `absent` do the work it was built for.
- [ ] `commands/create-ard.md`: with the gate running, the authored `prd.md` in the resolved folder is read on both routes. Today it is never read on the BRD route.
- [ ] `commands/create-ard.md`: the optionality advisory is gauged off seed counts on the BRD route and off PRD user stories on the idea route. One rule — and where a slice has both, say which wins.
- [ ] `commands/specify.md`: `SPECIFY_BRD_NO_EPIC` refuses a second key because "a BRD has no Epics yet" — false once `/epics` has minted `EPIC-` folders under the slice. Under D4 the second key is going away anyway (Task E3); make this stop consistent with that.
- [ ] `commands/specify.md`: no PRD is read and no PRD gate runs on the BRD route; the spec is written flat rather than into a per-Epic subfolder. Both follow from the stop above.
- [ ] `agents/prd-reviewer.md`: an absent `key` beside `brd_key` is "NEVER a finding" — a stand-alone PRD is held to a rule a BRD PRD is exempt from. Once E3 settles who writes `key`, this rule applies to both routes equally.
- [ ] `references/specs-repo-git.md`: the idea route is treated as "structurally keyless" in the run key set while the BRD route is not, so branch recognition differs by route. 3.13.0 softened the wording to "once described as" — finish it.
- [ ] `references/grounding-format.md`: `design/` is read on the BRD route only, so an idea-route PRD folder may hold one and nothing looks. §4.1 of the spec defines the location as a property of any folder. **Defining the location is not wiring a consumer** — the spec is explicit that giving the idea route design grounding is a capability decided on its own. Make the *location* uniform; do not wire `design-grounder` into `/idea` here.

**Assertion:**
```bash
# fails before, passes after
! grep -q "On the BRD route the PRD gate does not run" \
    plugins/dev-workflows/commands/create-ard.md
```
`grep -q "prd.md" create-ard.md` is **not** a valid assertion here — it already passes, because the idea route reads `prd.md` today. Anchor on the branch that must disappear, not on a string that is present for another reason.

For each divergence removed, state in the task report whether it was an **asymmetry** or **legitimate**, and leave the legitimate ones documented as such.

---

### Task E5: `/brd-split` resolves in bulk

**Why this is in the increment and not deferred.** E1 makes slicing mandatory, so the single-slice case becomes the common path rather than a corner. Today every row is answered **twice** — once on the parent (which slice covers it) and once on the slice (`covered-here`) — because Phase 4 presents rows "exactly one at a time, never batched". A single slice claiming everything costs 2N prompts, two commands and two pull requests. Shipping E1 without E5 makes the product measurably worse on its most frequent case.

- [ ] Add a bulk resolution to `/brd-split` Phase 4: assign all remaining `unallocated` rows to one named slice in a single confirmation, instead of N sequential prompts.
- [ ] Add the mirror on a slice: mark every claimed row `covered-here` in one confirmation, for a slice that claims rows precisely so a PRD can be written for them.
- [ ] **Preserve the one-at-a-time walk as the default.** It exists because per-row judgement is the point. Bulk is an offered shortcut for the case where the answer is uniform by construction, not a new default.
- [ ] The bulk offer must state exactly what it will write, and must be refusable per row — an operator who wants three exceptions out of forty should not be forced back into forty prompts.
- [ ] `references/coverage-ledger-format.md`: the walk is described as one-at-a-time in the authority as well as the command. Both change together.
- [ ] Docs: `docs/commands/brd-split.md`, and any diagram or parameter table that describes the walk.

**Assertion:** state the prompt count for a 40-row BRD resolved to a single slice, before and after. The before figure is 80 plus two commands.

---

### Task E6: audit, changelog, and the whole-design review

- [ ] Sweep for surviving contradictions of D5 and D6 across `commands/`, `references/`, `agents/` and `docs/`. Enumerate with `grep -rinE` and **not** with a `^`-anchored pattern — headings indented inside fenced report templates are missed by `^`, which got an offer count wrong four times on the BRD branch.
- [ ] Changelog entry and version bump; `plugin.json` and `marketplace.json` move together.
- [ ] `CLAUDE.md`: record the two traps this increment turns on — that a slice folder is `PRD-`-prefixed but asserts `kind: brd`, and that eligibility is now a folder-kind question rather than a ledger question.
- [ ] **End-to-end route walk**, as a user, not as a diff review. Eleven of the BRD branch's twelve defects were found this way and none by per-task review, because every task was individually correct and the breakage lived between them. Name any state a user can enter and not leave.
- [ ] Walk the **ordinary** input, not only the interesting one. Increment 3's critical defect survived four review passes because every walk used a slice key and nobody walked the plain two-segment case.

---

## Self-Review

Before opening the PR:

1. **Does a root `BRD-` folder refuse, and does its refusal name a remedy that runs?**
2. **Does a `PRD-` slice still proceed unchanged?** The verdict that must *not* move is the one worth checking.
3. **Does `/epics` accept exactly three shapes and refuse the fourth** — PRD drafts, Epic-under-PRD re-refines, stand-alone Epic refuses, BRD refuses?
4. **Is `key` written by something, on both routes?** If the answer is still "the round-trip", E3 is not done.
5. **Does any offer name a two-key form?** D4 retired them.
6. **Do the two workflow diagrams agree edge for edge**, verified mechanically?
7. **Counts:** 27 / 37 / 105, or a deliberate move with the count and its subject in one commit.
8. **Is there any state a user can enter and not leave?**

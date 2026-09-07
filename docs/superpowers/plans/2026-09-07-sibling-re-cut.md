# The sibling re-cut — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On a fully-allocated parent BRD, `/brd-split <PARENT-KEY> "<instruction>"` re-points a row the parent delegated to slice A — and that A's own ledger records `deferred-to: <A>` — onto a sibling B under the same parent, so a slice grounding shows is too big can hand work to a new sibling instead of holding it deferred forever.

**Architecture:** No new command, no new flag, and no new artifact. The re-cut is a fourth path through `/brd-split`, taken in Phase 0 step 10 when the ledger has no `unallocated` row, an instruction was given, and at least one row is re-cuttable. The re-cuttable rows join the run's **placeable set** in memory — they are never written `unallocated`, so the invariant that no row returns to `unallocated` is untouched — and Phases 1.5, 2 and 3 then place, cluster and key them exactly as they place unallocated rows today. A new Phase 4 step (Step 2R) walks them with a two-option picker and writes the two ledger rows the re-cut consists of. Phase 4.5 gains the repair for the one dangling state the re-cut makes reachable for the first time.

**Tech Stack:** Markdown command bodies and reference files under `plugins/product-workflows/`; `scripts/check-docs.sh`, `scripts/check-id-grammar.sh` and `scripts/validate-catalog.py` are the gates. No source code, no test framework — verification is the seven CI gates plus the per-task greps each task names.

**Spec:** `docs/superpowers/specs/2026-09-07-sibling-re-cut-design.md` — read it in full before Task 1. It is the binding authority; this plan argues from it.

## Global Constraints

Every task's requirements implicitly include all of these.

- **`${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin.** A reference in another plugin is reached only through `Skill(skill: "workflows-core:reference", args: "<name>")`, never by path. A reference inside `product-workflows` is cited from a `product-workflows` file as `${CLAUDE_PLUGIN_ROOT}/references/<name>.md`. `check-docs.sh` check 16 gates this in both directions.
- **`git add -A` is never issued at repository scope.** Stage explicit paths on every commit.
- **Every commit ends with these two trailer lines, in this order:**
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
  ```
- **Nothing is pushed.** No task pushes, opens a pull request, or merges. The branch is handed back at the end.
- **`.claude-plugin/marketplace.json` must not be reformatted** — Claude Code parses it. Change only the values a task names.
- **Every `choices:` array is an `AskUserQuestion` call**: 2–4 options, and **no authored "Other"** — the harness supplies the free-text escape itself. `check-docs.sh` check 12 gates this by a bracket-matched, quote-aware parser.
- **A `choices:` option that names a downstream command must carry the `<merge-clause>` placeholder** where this run writes the artifact that command's `require-on-main` gate targets (`check-docs.sh` check 11). A picker that names no command carries none.
- **Requirement IDs are the bracketed form only** — `[BR#n]`, `[CG#n]`, `[DG#n]`, `[VD#n]`, `[CD#n]`, `[DEF#n]`. Never the dash-separated form. `check-id-grammar.sh` gates it.
- **A row never returns to `unallocated`.** This plan does not relax that and no task may. What relaxes is the weaker rule that `/brd-split` never re-allocates a row already carrying a fate — and only against a row whose owner recorded `deferred-to`.
- **Resolve an identifier against a known set; never parse one out of free text.** A `[BR#n]`, a child key or a parent key is matched against the set the run already holds.
- **Never state a count you did not derive.** Where a number is wanted, cite the recipe that produces it instead. The spec's §8 makes this explicit for the consumer sweep.
- **No hard-wrapped prose.** Each paragraph is one unbroken line in these files (`workflows-core:prose-formatting`); match the surrounding file, which already does this.
- **A sentence saying a thing does not ship is a claim with an expiry date.** When this feature lands, the sentences that said it would not are defects. Task 6 is that sweep and it is not optional.
- **The seven CI gates, run from the repo root, are the acceptance test for every task that touches a gated surface:**
  ```
  python3 scripts/validate-catalog.py --selftest
  python3 scripts/validate-catalog.py .
  ./scripts/check-id-grammar.sh --selftest
  ./scripts/check-id-grammar.sh --root .
  ./scripts/check-docs.sh --selftest        # ~2 minutes
  ./scripts/check-docs.sh --root .
  python3 scripts/session-cost.py --selftest
  ```

---

## File structure

| File | Responsibility in this change |
|---|---|
| `plugins/product-workflows/references/coverage-ledger-format.md` | **The authority.** Gains §3.2, which defines the re-cut: its precondition, its two writes, receiver eligibility, and the removal edge. §3's "the slice form exists for exactly one state" paragraph is corrected to two. Every other file cites this rather than restating it. |
| `plugins/product-workflows/commands/brd-split.md` | The whole mechanism. Phase 0 (candidate set + path selection), Phase 1.5/2/3 (placement, clustering, keying), Phase 4 (the re-cut walk and the reconcile it feeds), Phase 4.5 (the repair), Phases 5–7 and the final report. |
| `plugins/product-workflows/references/decision-register-format.md` | One paragraph in §4 naming the re-cut as a case the two-causes rule decides — an interviewed sibling cannot receive. |
| `plugins/product-workflows/commands/brd-interview.md`, `brd-ground.md`, `brd-package.md`, `brd-reconcile.md`, `brd-intake.md` | The §8 sweep. Each asserts, in a stop message or in prose, that allocation is terminal. Each is re-read and each false sentence rewritten. |
| `plugins/product-workflows/docs/commands/brd-split.md`, `docs/commands/brd-ground.md`, `docs/brd-workflow.md` | Human-facing pages. `check-docs.sh` gates their inventories, links and index membership. |
| `CLAUDE.md` | The `/brd-split` line of the workflow map, and the coverage-ledger invariant bullets. |
| `plugins/product-workflows/CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Release record and version. |

## Ruling recorded before execution: the version is 2.1.0

Nothing that worked stops working. The path this feature changes — `/brd-split <PARENT-KEY> "<instruction>"` on a fully-allocated parent — today parses the instruction, reports it unused, and does nothing with it; that is what spec §6 calls its "unambiguous free meaning". A new capability on a path that previously did nothing is a minor version. This is not the 2.0.0 case, where a run that worked against a root began to stop at the first gate. Set `2.1.0` in both manifests. If an implementer finds a run whose *outcome* changes rather than a run that gains one, stop and say so — that finding would move this to 3.0.0.

## Ruling recorded before execution: the re-cut fires only on a fully-allocated parent

Spec §6's argument for reusing the instruction argument rests on the argument being *free* on that path — currently parsed and discarded. On an ordinary run the instruction already means "group the rows still `unallocated`", so firing the re-cut there would make one argument mean two things in one run. The bound is therefore derived from §6, not chosen for convenience, and it is stated in the command so a later edit does not "generalise" it away. A parent with rows still to place allocates them first and re-runs.

## Vocabulary this plan uses, fixed here so every task uses the same words

- **A** — the **donor**: the child whose ledger records `deferred-to: <A>` for the row, and whom the parent's ledger currently names `covered-by: <A>`.
- **B** — the **receiver**: a sibling under the same parent that has not been interviewed. Either newly keyed by Phase 3 this run, or a child Phase 0 step 9 enumerated.
- **The re-cut candidate set** — the `[BR#n]` rows for which a donor exists. Built in Phase 0 step 9a, carried in memory, never written to any file as a disposition.
- **`recut_mode: true`** — the run-scoped flag Phase 0 step 10 sets when it selects the re-cut path. Every phase branches on this flag by name.

---

### Task 1: The format authority — `coverage-ledger-format.md` §3.2

**Files:**
- Modify: `plugins/product-workflows/references/coverage-ledger-format.md` — the §3 paragraph beginning `**The slice form exists for exactly one state`, and a new `### 3.2` section inserted after `### 3.1 What covered-by means downstream — the row leaves this BRD's scope` and before `## 4. The allocation gate`.

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the section number **`§3.2`** and the section title **`The re-cut — a sibling takes a row its owner deferred`**. Tasks 2–7 cite it by that number and title. The disposition spellings every later task writes: on the parent's ledger `covered-by: <B-KEY>`; on the donor's ledger `covered-by: <B-KEY>`; on the receiver's ledger `unallocated` (seeded, by Phase 3, as today); after a receiver's removal, `deferred-to: <PARENT-KEY>` on the parent's row and `covered-by: <PARENT-KEY>` on the donor's row.

- [ ] **Step 1: Read the spec and the section you are about to change**

Read `docs/superpowers/specs/2026-09-07-sibling-re-cut-design.md` in full. Then read `plugins/product-workflows/references/coverage-ledger-format.md` lines 74–255 — §3, §3.1 and the opening of §4. You are adding to a file that already argues carefully; match its voice.

- [ ] **Step 2: Correct §3's "exactly one state" paragraph**

The paragraph currently opens:

```
**The slice form exists for exactly one state — an orphan row (§2) — and for no other.** A slice's
`covered-by` row is a provisional claim the parent's walk withdrew, and the key it carries is
whichever BRD that same walk allocated the requirement to:
```

Rewrite the opening sentence so it names **two** producing states — the orphan row it already describes, and the re-cut of §3.2 — and forward-references §3.2 for the second. Leave the table below it and every following paragraph of §3 exactly as they stand: the orphan-row mapping is unchanged and the re-cut does not touch it. Do not renumber anything.

The sentence immediately below the table, `**This is not a general-purpose delegation, and a slice's own walk never writes it.**`, stays **true and unchanged** — the re-cut is written by the parent's walk, not the slice's. Verify that by reading it; do not edit it.

- [ ] **Step 3: Verify the invariant sentence you must not touch**

Run:

```bash
grep -n 'no command ever moves a row back to' plugins/product-workflows/references/coverage-ledger-format.md
```

Expected: one hit, in §3. Read it. It says a row never returns to `unallocated`. **That sentence is unchanged by this whole plan.** The sentence two lines above it — `/brd-split` "walks every `unallocated` row to a terminal disposition (§4), and it is the only command that may write `covered-here` or `covered-by`" — is also still true; the re-cut is that same command writing that same disposition. Add nothing to either.

- [ ] **Step 4: Write §3.2**

Insert a new `### 3.2 The re-cut — a sibling takes a row its owner deferred` between §3.1 and `## 4. The allocation gate`. It must state, each with its reason, in the file's own voice:

1. **The precondition, and that it is the whole of the design.** A row is re-cuttable only where the parent's ledger reads `covered-by: <A>` **and** A's own ledger reads `deferred-to: <A>` for that same `[BR#n]`. `deferred-to: <A>` is A stating in its own ledger that it is not building this; the parent re-points against that written refusal and never over a live commitment. Both halves are read from the `disposition` column — the parent's and the child's — never from `claims:` and never from an inventory.
2. **The two writes, and their order.** The parent's row takes `covered-by: <B-KEY>`; A's row takes `covered-by: <B-KEY>` in the same step. **The parent's row is written first**, and the reason is the interrupted state: parent-first leaves the parent pointing one hop at B, whose seeded row is `unallocated` and therefore counted unresolved by §6.1 and §6.2 — an accurate, benign reading — and leaves A exactly as it was. Child-first would leave the parent naming A while A names B, putting a **second hop** under the roll-up §6.1 requires to terminate in one. State that reason, because a later edit will otherwise reorder these two writes as a tidy-up.
3. **What A keeps.** A's `claims:` entry and its copied inventory row are withdrawn together, exactly as for any row a walk moves off `covered-by: <A>` — that is `commands/brd-split.md` Phase 4 Step 3's existing behaviour and needs no new rule. A's ledger row is **never deleted** (§2). A's grounding findings and its decision register are **not touched**: a finding's id is contiguous within its prefix and assigned once, and `workflows-core:grounding-format` §8 holds that a finding carried from an earlier run is unverified by definition, so B re-derives against the same pins rather than inheriting.
4. **Receiver eligibility.** B is a sibling under the same parent that **has not been interviewed** — no `decisions.md` holding a `[VD#n]` or `[CD#n]` record, and no `interview/round-*.md` on disk. `references/decision-register-format.md` §4 admits exactly two causes for reopening a decision — a new grounding finding, or an incoming customer decision — and adding scope is neither, so a register that exists and holds decisions is closed to this. **This eligibility test is the re-cut's alone**; it does not narrow which children an ordinary walk may write `covered-by` against, and widening it there is out of scope (spec §7).
5. **The removal edge.** Where a receiver is later removed as a standing empty child, the parent's row takes `deferred-to: <PARENT-KEY>` — kept as a live obligation of the parent, not built now — and every other child whose ledger reads `covered-by: <that removed child>` for the same `[BR#n]` takes `covered-by: <PARENT-KEY>`. Both come straight from §3's own orphan table row *"`deferred-to: <this BRD>` — a live obligation of the parent" → `covered-by: <this BRD's key>`*; neither is a new mapping. The row goes **not** back to A, which refused it, and **not** to `unallocated`, which is forbidden.
6. **What this does not relax.** No row returns to `unallocated`; §4's gate is never reopened; the one-level nesting cap is untouched — this carves a sibling, never a child; and no `covered-by` key written here names a child of a slice.

- [ ] **Step 5: Verify no identifier grammar or reference-loader violation**

```bash
./scripts/check-id-grammar.sh --root .
./scripts/check-docs.sh --root .
```

Expected: both PASS. If check 16 fires, you cited a `workflows-core` reference by path instead of through the loader — fix the citation, do not disable the check.

- [ ] **Step 6: Verify the section is reachable and the numbers did not move**

```bash
grep -n '^## 4\. The allocation gate\|^### 3\.1 \|^### 3\.2 ' plugins/product-workflows/references/coverage-ledger-format.md
```

Expected: `### 3.1`, then `### 3.2`, then `## 4. The allocation gate`, in that order, and §4 still titled exactly `The allocation gate`.

- [ ] **Step 7: Commit**

```bash
git add plugins/product-workflows/references/coverage-ledger-format.md
git commit -m "feat(ledger-format): define the sibling re-cut in section 3.2

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

### Task 2: `/brd-split` Phase 0 — the candidate set and the fourth path

**Files:**
- Modify: `plugins/product-workflows/commands/brd-split.md` — insert a new step **9a** after step 9 and before step 10; add a third branch to step 10; add one sentence to step 11.

**Interfaces:**
- Consumes: `coverage-ledger-format.md` **§3.2** from Task 1 — cite it as `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3.2.
- Produces, for Tasks 3, 4 and 5, by these exact names:
  - `recut_mode: true` — the run-scoped flag, set in step 10.
  - **the re-cut candidate set** — a list of `{ [BR#n], donor key, the donor's ledger row }`, built in step 9a.
  - **the eligible receiver set** — the children from step 9 that pass §3.2's not-interviewed test, plus every child Phase 3 keys this run.
  - Stop id `BRD_SPLIT_RECUT_NO_RECEIVER` — **pointed at** from step 9a and **defined** by Task 4 in Step 2R, which is the only phase that can reach the state it names.

- [ ] **Step 1: Read what you are inserting between**

Read `plugins/product-workflows/commands/brd-split.md` lines 214–290 — steps 8, 9, 10 and 11 of Phase 0. Note three things you must not break: step 9 is `split_mode: full` only; step 10 is deliberately mode-independent and its reasoning says why; step 11 fires only on step 10's ordinary run.

- [ ] **Step 2: Write step 9a — build the re-cut candidate set**

Insert after step 9 and before step 10, numbered `9a`, matching the numbering style step `1a` already uses in this phase.

It runs only when **all three** hold, and it says so in its first sentence: `split_mode: full`; step 1a parsed an instruction; and step 8 set `unallocated_zero: true`. On any other run it does not run and the set is empty. State the bound and its reason — the ruling above, derived from spec §6: on a run with rows still `unallocated` the instruction already means "group those rows", and one argument may not mean two things in one run.

What it does, for each child enumerated in step 9:

- Read that child's `coverage-ledger.md` from the worktree and take every row whose `disposition` is `deferred-to: <that child's key>`.
- Take the parent's own rows whose `disposition` is `covered-by: <that child's key>`.
- Intersect the two by `[BR#n]`. Each row in the intersection joins the candidate set, carrying the donor's key.
- **Read the `disposition` column at both levels.** Not `claims:`, not either inventory — §3.1 already names that trap for the interview's scope test and it is the same trap here.
- **A child whose ledger cannot be read is not a donor**, and that is reported rather than skipped silently: an unreadable ledger is `unresolved`, never `covered` (`coverage-ledger-format.md` §6.2). Name the child and the read failure; do not infer an empty set from it.

Then compute the **eligible receiver set** from the step 9 children: a child is eligible unless it has been interviewed — §3.2's test, which this step executes rather than restates: a `decisions.md` in the child's folder holding at least one `[VD#n]` or `[CD#n]` record, **or** any `interview/round-*.md` on disk, makes it ineligible. Read the worktree, not a ref: an interview that happened is an interview that happened whether or not its record merged. **A donor is not disqualified from being a donor by having been interviewed** — spec §4 says so explicitly, and A holding a `[VD#n]` about deferring the row is the ordinary case.

Report the set before anything else runs: how many rows are re-cuttable, from which donors, and — where the candidate set is empty while children exist — say **why** it is empty (no child holds a `deferred-to` row of its own, or every such row is one the parent did not delegate to that child). An operator who typed an instruction on a fully-allocated parent and got a no-op needs to see which of those it was.

- [ ] **Step 3: Add step 10's third branch**

Step 10 currently has three bullets: no-op, Phase-4.5-only, and otherwise-ordinary. Insert a new bullet **before** the no-op bullet, so it is tested first:

- `unallocated_zero` **and** the re-cut candidate set from step 9a is non-empty → **the re-cut run**. Set `recut_mode: true` and carry it for the whole run. Phase 1.5 runs over the candidate set, Phase 2 proposes from that placement, Phase 3 keys what it confirms, Phase 4 runs its Step 2R re-cut walk in place of Step 2, and Phases 4.5, 5, 6 and 7 run as usual. State that this is the path spec §6 gives the instruction its meaning on, and that a standing empty child alongside it changes nothing — Phase 4.5 runs on this path as it runs on the ordinary one.

Then amend the **existing** no-op bullet, whose current text reads in part `**A slicing instruction does not make this run not-a-no-op**`. That sentence is now false as written. Rewrite it to say what is now true: an instruction makes this run not-a-no-op exactly where step 9a found a re-cuttable row, and where it did not, the run is still a no-op and Phase 1.5 still reports the instruction unused — now naming *which* of the two reasons applies.

Amend the Phase-4.5-only bullet the same way if it repeats the claim; read it and check rather than assuming.

- [ ] **Step 4: Add step 11's carve-out**

Step 11 stops a `full` run given no instruction, and fires only on step 10's ordinary run. That is still correct — the re-cut path requires an instruction by construction, so it can never reach step 11 without one. Add one sentence to step 11's closing paragraph (the one beginning `On step 10's other two paths`) making it *three* other paths and naming the re-cut as the third: it always has an instruction, so this stop cannot fire on it.

- [ ] **Step 5: Add the no-receiver stop**

At the end of step 9a, after the eligible receiver set is computed: where the candidate set is non-empty but **no** child is eligible and the operator would therefore have nowhere to send a row except a slice Phase 3 creates — that is fine and not a stop, because Phase 3 can create one. The stop is narrower and belongs here so it is taken before any prompt: where the candidate set is non-empty, no child is eligible, **and** the parent's folder cannot take a new child. Since a parent can always take a new child, this state is unreachable today; write no stop for it. **Instead** define `BRD_SPLIT_RECUT_NO_RECEIVER` for the state that *is* reachable and is Phase 3's to hit: every proposed receiver was declined and no eligible child stands, so the walk has nothing to offer. Note in step 9a that Phase 4's Step 2R owns that stop, and define it there in Task 4 rather than here. **Write nothing in this step but that pointer** — do not invent a Phase 0 stop for a state Phase 0 cannot be in.

- [ ] **Step 6: Verify the choice arrays and the gates**

You added no `choices:` array in this task. Confirm that:

```bash
grep -c 'choices:' plugins/product-workflows/commands/brd-split.md
```

Expected: the same count as before your edit. Record what it was before you started; if it moved, you added an array this task did not ask for. Then:

```bash
./scripts/check-docs.sh --root .
./scripts/check-id-grammar.sh --root .
```

Expected: both PASS.

- [ ] **Step 7: Verify the path is decidable from the file alone**

```bash
grep -n 'recut_mode' plugins/product-workflows/commands/brd-split.md
```

Expected: at least two hits — step 10 sets it, step 9a or step 10 names what reads it. A reader must be able to find the flag's producer and its consumers by that one grep; that is why every phase branches on it by name.

- [ ] **Step 8: Commit**

```bash
git add plugins/product-workflows/commands/brd-split.md
git commit -m "feat(brd-split): build the re-cut candidate set and select the re-cut path

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

### Task 3: `/brd-split` Phases 1.5, 2 and 3 — the candidate set joins the placeable set

**Files:**
- Modify: `plugins/product-workflows/commands/brd-split.md` — Phase 1.5's opening and Steps A and B; Phase 2's clustering paragraph and the prose beside its existing `choices:` array; Phase 3 step 3's "provisional" paragraph.

**Interfaces:**
- Consumes: `recut_mode`, **the re-cut candidate set**, and **the eligible receiver set** from Task 2, by those names; `coverage-ledger-format.md` §3.2 from Task 1.
- Produces, for Task 4: **the placement** — for each candidate row, either a group Phase 2 keyed into a child (which fixes that row's `<B-KEY>`), or nothing. A candidate the placement leaves unplaced is **not walked** in Step 2R and is reported instead.

- [ ] **Step 1: Read the three phases end to end**

Read `plugins/product-workflows/commands/brd-split.md` lines 321–535 — Phase 1.5 in full, Phase 2 in full, Phase 3 in full. Phase 1.5's second paragraph currently says it is *"Also skipped where no row is `unallocated`, whatever Phase 0 step 10 decided"*. That is the sentence this task makes conditional.

- [ ] **Step 2: Make Phase 1.5 run on the re-cut path**

Rewrite the *"Also skipped where no row is `unallocated`"* paragraph. It must now say: skipped where no row is `unallocated` **and** `recut_mode` is false — the no-op path and the Phase-4.5-only path both still reach here with nothing to place and still report the instruction unused, naming which path swallowed it. On the re-cut path the phase **runs**, over the re-cut candidate set in place of the unallocated set. Keep the existing reason for the report — an instruction typed and silently discarded is indistinguishable from one the command failed to parse — and extend it: on the re-cut path the operator has *more* reason to expect the instruction did something, since it is the argument that selected the path.

Then amend the paragraph immediately below it, the one beginning `This phase produces one thing: a **placement**`, so the set it produces a placement over is named as "every row still `unallocated`, **or**, on the re-cut path, every row in the re-cut candidate set". The rest of that paragraph — everything downstream reads the placement and never re-reads the instruction — is unchanged and still true.

- [ ] **Step 3: Extend Step A and Step B to the candidate set**

**Step A** reads each unallocated row's `text` and `source_anchor` from `brd/brd-inventory.md`. On the re-cut path it reads the same two fields for each candidate row from the same file — the parent's inventory holds every `[BR#n]`, delegated or not (`coverage-ledger-format.md` §3.1 says so explicitly), so no new read is needed and no child inventory is consulted. Say that, because the obvious wrong implementation is to read the donor's copied inventory.

Add one sentence to Step A: an instruction that is a **set operation over the ledger** resolves here on the re-cut path too, against the candidate set rather than the unallocated set — *"peel off everything PRD-X deferred"* is exactly that shape and is the instruction this path most expects.

**Step B**'s value test and its hard cap of five are unchanged and apply as written. Add one sentence naming why the cap still sizes correctly here: an unplaced candidate reaches Step 2R and is **left with its donor and reported**, which is a resolution rather than a hole in a deliverable — the same free-fallback argument the phase already makes for the ordinary path.

Amend the closing paragraph *"A row still unplaced when this phase ends is left unclustered"* so it states the re-cut path's version: an unplaced candidate is not walked at all, because it already carries a fate and there is no picker that could leave it where it is more cheaply than not showing it. It stays `covered-by: <A>`, and Phase 5 records it.

- [ ] **Step 4: Make Phase 2 cluster candidates and name each donor**

Phase 2's clustering paragraph currently reads `group every [BR#n] still unallocated by what the instruction placed it into`. Extend it: on the re-cut path, group every row in the re-cut candidate set the same way.

Then add the requirement that makes the proposal honest — **the candidate presentation names the donor per row**. The existing text says each candidate slice is presented with "a short working name, its `[BR#n]` rows, and the one-line rationale". On the re-cut path each `[BR#n]` also carries **the donor's key and the fact that the donor's own ledger records `deferred-to`**, so the operator sees which slice is giving each row up before confirming anything. A proposal that hides the donor asks the operator to approve a transfer they cannot see.

The `choices:` array in Phase 2 is **unchanged** — do not touch it. Its four options all still apply. But amend the prose below it: *"Make this whole BRD one slice"* is meaningless on the re-cut path (the BRD is already sliced), so state that on the re-cut path that option means *"put every re-cuttable row into one new sibling"*, which is a real and likely answer. Do not add a fifth option; check 12 caps the array at four.

Also amend the paragraph beginning `**Zero confirmed slices is not an outcome this phase can reach.**` On the re-cut path zero confirmed slices **is** reachable and is not a failure: an operator can look at the proposal and decide the rows should stay where they are. Say what happens — the run continues to Phase 4, Step 2R has no `<B-KEY>` to offer for any row, every candidate is reported left with its donor, and Phases 4.5 onward run as usual. That is a real outcome of a real run, not a degenerate one.

Finally, extend the existing exception paragraph about a parent that already has children: on the re-cut path the eligible receiver set is exactly which of those children may receive, and the ineligible ones are **named with the reason** — they have been interviewed — rather than silently dropped from the target list. An operator who expected to send a row to a slice that no longer accepts it must be told why (`coverage-ledger-format.md` §3.2, `references/decision-register-format.md` §4).

- [ ] **Step 5: Amend Phase 3 step 3's provisional paragraph**

Phase 3 step 3 says a `claims:` list is provisional because "Phase 4's walk is the step that actually moves a row's disposition". On the re-cut path that is still exactly true — Step 2R is that step. Add one sentence saying so, and one saying what does **not** change: Phase 3 still seeds one `unallocated` ledger row per claim (step 5), and that row is `unallocated` because it is a **new** row on a **new** ledger, not a row returned to `unallocated`. That distinction is the one a reader will get wrong, and it is the whole reason the invariant survives this feature.

Everything else in Phase 3 is unchanged. Do not touch steps 1, 2, 4 or 5.

- [ ] **Step 6: Verify no array changed and the gates hold**

```bash
grep -c 'choices:' plugins/product-workflows/commands/brd-split.md
./scripts/check-docs.sh --root .
./scripts/check-id-grammar.sh --root .
```

Expected: the count is unchanged from Task 2's recorded value; both scripts PASS.

- [ ] **Step 7: Verify the placement contract is stated once**

```bash
grep -n 'placement' plugins/product-workflows/commands/brd-split.md | head -20
```

Read the hits. Phase 1.5 must be the only phase that *produces* a placement; Phases 2 and 4 must only read it. If any edit you made has Phase 2 re-reading the instruction, remove it — "an instruction is interpreted exactly once" is a stated invariant of Phase 1.5.

- [ ] **Step 8: Commit**

```bash
git add plugins/product-workflows/commands/brd-split.md
git commit -m "feat(brd-split): place, cluster and key the re-cut candidate set

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

### Task 4: `/brd-split` Phase 4 — Step 2R, the re-cut walk

**Files:**
- Modify: `plugins/product-workflows/commands/brd-split.md` — Phase 4's three-steps opening paragraph; Step 1's firing table; a new **Step 2R** inserted after Step 2 and before Step 3; Step 3's precondition sentence.

**Interfaces:**
- Consumes: `recut_mode`, the re-cut candidate set and the eligible receiver set (Task 2); **the placement** (Task 3); `coverage-ledger-format.md` §3.2 (Task 1).
- Produces, for Task 5: the **re-cut record** — per candidate row, the `[BR#n]`, the donor, the receiver or "left with donor", and the decisions reported. Phase 5 writes it into `slices.md`. Stop id `BRD_SPLIT_RECUT_NO_RECEIVER`.

- [ ] **Step 1: Read Phase 4 end to end**

Read `plugins/product-workflows/commands/brd-split.md` lines 535–887 — Phase 4's opening, Step 1, Step 2 and Step 3. Note Step 2's `<recommended>` placeholder table and the rule that placeholders are substituted while the array is presented verbatim; Step 2R uses the same mechanism.

- [ ] **Step 2: Amend Phase 4's opening**

The opening says *"Three steps, in this order"*. Make it four, naming Step 2R between Step 2 and Step 3, with its one-line condition (`recut_mode` only) and its one-line purpose. Say plainly that Step 2 and Step 2R never both run: Step 2 walks rows that are `unallocated`, and on the re-cut path there are none.

- [ ] **Step 3: Extend Step 1's firing table to the re-cut path**

Spec §5 requires the bulk offer be reused rather than duplicated. Add a third row to Step 1's `Mode | Fires when` table for `full` + `recut_mode`: fires when **exactly one** receiver stands eligible — the union of the children Phase 3 keyed this run and the eligible children Phase 0 step 9a marked is a single folder — **and** two or more rows are in the re-cut candidate set with a placement.

Then add the `choices:` array for it, three options, matching the shape of the two already there:

```
choices: ["Re-point all <N> rows to <B-KEY> now — each was deferred by the slice that holds it", "Re-point all but the rows I name — I'll walk those one at a time", "Walk every candidate one at a time — decide each row"]
```

**No `(Recommended)` marker on any option**, and say why beside the list in the file's own voice: this run knows which sibling a re-pointed row would go to, not whether this row is one to move — the same *When no option is safe to recommend* reasoning the `full` offer already carries, and the same reason. The array names no command, so it carries no `<merge-clause>`.

Extend Step 1's *"What the offer states before anything is written"* numbered list with a re-cut item: for each row in the set, **the donor's key** and **the decisions in the donor's register whose `evidence` touches the row** — the report spec §4 requires, made once here instead of per row. Extend its *"Its vocabulary is two dispositions"* paragraph to three, naming the re-point, and keep the existing reason for why the other three dispositions cannot be bulk-written.

Option 2's naming prompt, the validation, the single re-prompt, and the fall-through rule are all unchanged and apply as written. Add one sentence confirming the fall-through direction on this path is **the walk**, for the same reason: no answer this step cannot read may take the maximal write.

- [ ] **Step 4: Write Step 2R**

Insert `### Step 2R — the re-cut walk` after Step 2 and before Step 3.

**Condition and set.** Runs only when `recut_mode` is true. Its set is every row in the re-cut candidate set that the Phase 1.5/Phase 2 placement put into a child Phase 3 keyed or an eligible existing child — minus any row Step 1's offer already wrote. A candidate the placement left unplaced is **not** in this set: it stays `covered-by: <its donor>` and is reported. Say why, so no later edit "completes" the walk: a row that already carries a fate has nothing a blank picker could resolve it to, and showing one would be a prompt whose only answer is "leave it".

**Per row, one `AskUserQuestion`**, never batched, quoting: the row's `id` and `text` from the parent's inventory; **the donor's key**, and that the donor's own ledger records `deferred-to` for it — which is the precondition, quoted rather than asserted; and **every decision in the donor's `decisions.md` whose `evidence` list touches this row**, by id and `statement`. That last one is spec §4's report and it is **advisory**: the re-cut surfaces what the donor decided about a row it is giving up and the operator judges whether the move is still right. State in the file that **nothing here edits a decision** — the decisions record the donor's refusal to build the row, which remains the case after the move, and `references/decision-register-format.md` §4 admits only two causes for reopening one.

**The picker**, two options, inside check 12's cap, no authored "Other":

```
choices: ["Re-point to <B-KEY> — <A-KEY> deferred it and <B-KEY> will build it<recommended>", "Leave it with <A-KEY> — its deferred-to stands"]
```

`<A-KEY>` is the donor, `<B-KEY>` the receiver the placement fixed for this row, and `<recommended>` resolves exactly as Step 2's table's first row already defines it — ` (Recommended — <what in the instruction placed it>)` on the re-point option and the empty string on the other. State that these are placeholders substituted per row, so the array is still presented verbatim (`workflows-core:escalation-rules`, *Choice lists are presented verbatim*) — the same sentence Step 2 already makes for its own.

**A free-text or unusable answer falls to the second option** — leave it with the donor. State the direction and the reason: the fall-through must always be the answer that writes least, which is the rule Step 1 already applies at both of its prompts.

**The writes, in this order, per row, once the operator chooses to re-point:**

1. The **parent's** ledger row → `disposition: covered-by: <B-KEY>`.
2. The **donor's** ledger row → `disposition: covered-by: <B-KEY>`.

Write the order's reason inline, from §3.2 — parent-first keeps §6.1's one-hop roll-up intact if the run is interrupted between the two, and child-first would put a second hop under a roll-up that must terminate in one. Nothing else about either row changes; ids are the parent's throughout. Cite `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3.2 as the authority for both writes rather than restating the precondition here.

**What Step 2R does not write.** It does not touch the donor's `claims:` list or its copied inventory row — Step 3 withdraws those, exactly as it does for any row this walk moved off `covered-by: <that child>`. It does not touch the receiver's `claims:` list — Step 3 adds it. It does not touch any grounding file or any register. Say all three, because each is somewhere an implementer would reasonably reach.

**The stop.** Where the walk opens with a non-empty candidate set and **no** receiver stands — Phase 2 confirmed no slice and no eligible child exists — stop:

```
BRD_SPLIT_RECUT_NO_RECEIVER: <PARENT-KEY> has <N> re-cuttable rows and no sibling that can receive them — no slice was confirmed this run, and every existing child has been interviewed, which closes it to new scope (references/decision-register-format.md §4). Re-run '/product-workflows:brd-split <PARENT-KEY> "<what to peel off>"' and accept a new slice for them, or leave them deferred where they are.
```

State that this stop is an allocation outcome rather than a plugin gap, so it does not fire `emit-block` — the same sentence `/brd-interview`'s `BRD_INTERVIEW_ALL_DELEGATED` carries, for the same reason.

- [ ] **Step 5: Amend Step 3's precondition**

Step 3 currently contains: *"This walk visits only rows that were `unallocated` when Phase 0 step 8 read the ledger, so the rows a pre-existing child was already given by an earlier run are not revisited here and must not be dropped"*. That sentence is now false on the re-cut path. Rewrite it so it names both sets — rows that were `unallocated`, and, on the re-cut path, rows Step 2R re-pointed — while keeping the conclusion it exists to support, which is unchanged: a child's ending set is the union of what it already claimed and what this walk newly resolved to it, minus only what this walk moved off `covered-by: <that child>`, and a rebuild from this walk's resolutions alone would strip every earlier claim.

Then add one sentence to Step 3's closing paragraph, which currently ends *"The orphan rows it writes are only ever rows this run seeded `unallocated` in Phase 3 step 5 moments earlier, so the two rules never collide."* On the re-cut path the donor's ledger row was already written by Step 2R, so Step 3 **leaves it** and its work for the donor is the `claims:` entry and the copied inventory row only. Say that, and say that this is what keeps Step 3's "never rewrites a disposition another run recorded" rule intact — the disposition was written by *this* run, one step earlier.

- [ ] **Step 6: Verify the arrays**

```bash
./scripts/check-docs.sh --root .
```

Expected: PASS. Check 12 counts your two new arrays: Step 1's re-cut offer (3 options) and Step 2R's picker (2 options), neither authoring an "Other". Check 11 is satisfied because neither names a command — confirm that by reading them; if you named a command in an option, it needs `<merge-clause>` and you should instead reword to not name one.

```bash
./scripts/check-id-grammar.sh --root .
```

Expected: PASS.

- [ ] **Step 7: Verify the two writes are stated exactly once and in order**

```bash
grep -n 'covered-by: <B-KEY>' plugins/product-workflows/commands/brd-split.md
```

Expected: hits inside Step 2R only, and the parent's write must appear above the donor's. If the order is reversed anywhere, fix it — the ordering carries a reason and a reader who meets them out of order will implement them out of order.

- [ ] **Step 8: Commit**

```bash
git add plugins/product-workflows/commands/brd-split.md
git commit -m "feat(brd-split): add Step 2R, the re-cut walk

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

### Task 5: `/brd-split` Phase 4.5's repair, and Phases 5, 6, 7 and the final report

**Files:**
- Modify: `plugins/product-workflows/commands/brd-split.md` — Phase 4.5's `**Removing one can never leave a covered-by key pointing at nothing**` paragraph and its `**What this phase cannot do**` paragraph; Phase 5's block list; Phase 7's `full`-mode prose; the Final Report section.

**Interfaces:**
- Consumes: the **re-cut record** from Task 4; `recut_mode` from Task 2; `coverage-ledger-format.md` §3.2's removal edge from Task 1.
- Produces: nothing later tasks consume.

- [ ] **Step 1: Read Phase 4.5, Phase 5, Phase 7 and the Final Report**

Read `plugins/product-workflows/commands/brd-split.md` lines 887–1000 and lines 1038–1226.

- [ ] **Step 2: Fix Phase 4.5's dangling-`covered-by` claim, which the re-cut falsifies**

Phase 4.5 asserts: *"**Removing one can never leave a `covered-by` key pointing at nothing**, at either level: a child this walk gave a row to claims that row and is therefore not in this phase's set, so no ledger anywhere names a child this phase can remove."*

**That reasoning held only because no row could ever be moved off a terminal disposition.** The re-cut makes the state reachable: a receiver takes a row in one run, its own later walk defers it, a later re-cut moves it onward and empties the receiver's `claims:` list, and the receiver is then a standing empty child that some ledger still names. Rewrite the paragraph to say exactly that — naming the re-cut as the route that made it reachable, so a reader does not have to reconstruct it — and replace the assertion with the repair, which is §3.2's removal edge executed here:

Before removing a child, read the parent's `coverage-ledger.md` for rows `covered-by: <that child's key>`, and read every **other** child's ledger for rows carrying the same key. Where any exist:

- Name them in the removal confirmation, **before** the removal — the operator is being told that removing this folder changes rows on other ledgers, which the existing two pickers do not currently imply.
- On removal, write `deferred-to: <PARENT-KEY>` on each such row of the parent's ledger, and `covered-by: <PARENT-KEY>` on each such row of another child's ledger. Both mappings come from §3's own orphan table; cite it rather than restating it. Not back to the original donor, which refused the row; not `unallocated`, which is forbidden.
- Where none exist, the paragraph's original claim still holds for that removal and nothing extra is written. Say so, so the repair does not read as unconditional.

The two `choices:` arrays in Phase 4.5 are **unchanged** — do not touch them. The naming happens in the prose beside the list, which is where the recorded `reason:` is already printed.

- [ ] **Step 3: Fix Phase 4.5's "what this phase cannot do" paragraph**

It currently reads: *"`covered-by: <child>` is assigned in Phase 4's walk and only against a row that is `unallocated` on this BRD's ledger, and this command never re-allocates a row that already carries a fate. So on a parent whose ledger has no `unallocated` row left, removal — or keeping it, knowingly — is the whole of what this phase offers, and the three stops that name it say exactly that."*

Both sentences are now false. Rewrite: `covered-by: <child>` is assigned by Phase 4's Step 2 against an `unallocated` row **and** by Step 2R against a row whose owner recorded `deferred-to` (§3.2). On a fully-allocated parent, removal is no longer the whole of what a run offers — the re-cut is the other thing — so state what this **phase** offers (removal, or keeping knowingly) without claiming it is all the **run** can do. Then check the three stops that name this phase and note for Task 6 that they say the same false thing; do not edit them here.

- [ ] **Step 4: Add Phase 5's re-cut block**

Phase 5 writes `slices.md` as a list of blocks. Add one: **one block for the re-cut, when `recut_mode` was true** — carrying, per candidate row, the `[BR#n]`, the donor, the receiver or the fact that it was left with the donor and why (declined at the picker, or left unplaced by Phase 1.5), and the decisions in the donor's register that were reported for it, by id. Give the reason the file's other blocks give for existing: the ledger cannot say it — a re-pointed row and a row allocated to that same slice on the first pass read identically — and a later reader needs to know a requirement changed hands and what its previous owner had already decided about it.

The existing instruction block already records the instruction verbatim and how it was read; on the re-cut path that block records the same thing over the candidate set. Add one sentence saying so rather than a second instruction block.

Amend the closing paragraph *"Skipped entirely on the no-op path step 10 decides"*: the re-cut path is not the no-op path and `slices.md` is written on it in full.

- [ ] **Step 5: Amend Phase 7's next step**

Phase 7's `full`-mode branch offers grounding for every child Phase 3 created that still claims a row. On the re-cut path that is the right offer for a **new** receiver and the wrong one for an **existing** receiver, which is already ground: it gained a row, so its grounding no longer covers everything it claims, and the honest next step for it is `/brd-ground <B-KEY>` again — a re-run that re-derives, which is `workflows-core:grounding-format` §8's rule working rather than an inconvenience.

Add a paragraph saying that, and make the existing array's first option cover both by naming its set as "each child that gained a row this run" rather than only "each non-empty child created above". Do not add a fifth option and do not add an array. The `<merge-clause>` placeholder on that option is unchanged and still required.

Also amend the closing paragraph *"**This BRD's own next step is nothing.**"* — it lists the dispositions the walk resolves and reasons that all are terminal. Still true after a re-cut, and for the same reason; add one clause naming the re-cut's own outcome (`covered-by`, a named sibling's to decide) so a reader does not think it was overlooked.

- [ ] **Step 6: Extend the Final Report**

Add to the Final Report, on the re-cut path only: how many rows were re-cuttable and from which donors; how many were re-pointed and to which receivers; how many were left with their donor and why each; every decision reported, by id, with the note that they were reported and not touched; and any child whose ledger could not be read in step 9a. Where step 9a found no candidate at all, the report says which of its two causes applied — that is the sentence an operator who typed an instruction and got a no-op needs.

- [ ] **Step 7: Verify the arrays did not grow and the gates hold**

```bash
grep -c 'choices:' plugins/product-workflows/commands/brd-split.md
./scripts/check-docs.sh --root .
./scripts/check-id-grammar.sh --root .
python3 scripts/validate-catalog.py .
```

Expected: the count is Task 2's recorded value **plus 2** (Task 4 added two arrays and this task added none); all three scripts PASS.

- [ ] **Step 8: Verify no phase still asserts the falsified rule**

```bash
grep -n 're-allocat\|already carries a fate' plugins/product-workflows/commands/brd-split.md
```

Read every hit. Each must now either be true as written or name the re-cut as the exception. A hit that still says the rule is absolute is a defect this task owns; the hits in *other* files belong to Task 6.

- [ ] **Step 9: Commit**

```bash
git add plugins/product-workflows/commands/brd-split.md
git commit -m "feat(brd-split): repair a removed receiver, and record the re-cut

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

### Task 6: The consumer sweep — spec §8's risk — and the downstream reports

**Files:**
- Modify: `plugins/product-workflows/commands/brd-interview.md`, `brd-ground.md`, `brd-package.md`, `brd-reconcile.md`, `brd-intake.md` — every sentence each carries that the re-cut falsifies.
- Modify: `plugins/product-workflows/references/decision-register-format.md` — one paragraph in §4.
- Modify: `plugins/product-workflows/commands/create-prd.md:674`, `create-ard.md:706`, `specify.md:949` — one exclusion clause each in the unconsumed-item report (spec §4).

**Interfaces:**
- Consumes: everything Tasks 1–5 shipped. **Read what actually shipped in `brd-split.md`, not this plan's description of it** — that is the whole point of this task.
- Produces: nothing later tasks consume.

- [ ] **Step 1: Derive the consumer list rather than trusting it**

The spec's §8 is explicit that no count is kept and that an earlier draft asserted a wrong one. Run:

```bash
grep -c 'unallocated' plugins/product-workflows/commands/brd-*.md
```

Expected: a hit in all six files. **Read all six.** Then run the narrower sweep for the sentences most likely to be false:

```bash
grep -rn 're-allocat\|reallocat\|already carries a fate\|Un-delegating\|un-delegat\|allocation is this walk' plugins/product-workflows/ --include=*.md | grep -v CHANGELOG
```

Every hit is a candidate. A hit is a **defect** only if the re-cut as shipped makes it false — verify each against `brd-split.md`, at the phase that now does the thing, not against this plan.

- [ ] **Step 2: Fix `/brd-interview`'s `BRD_INTERVIEW_ALL_DELEGATED`**

That stop currently ends: *"…the row that should have stayed here is moved by re-running '/product-workflows:brd-split <BRD-KEY>' — which will report a no-op, because no command re-allocates a row that already carries a fate. Un-delegating is a decision taken with the customer, not a command."*

Three problems, and the fix is not a deletion. First, the key is wrong for the new capability — the re-cut runs on the **parent**, and this stop fires on a BRD all of whose rows are `covered-by`, which is a parent. Second, "will report a no-op" is now conditional on there being no re-cuttable row. Third, "un-delegating is a decision taken with the customer" was the *reason* the offer did not exist, and the re-cut does not make it false: a re-cut still requires a donor that recorded `deferred-to`, which is that decision written down. Rewrite so all three are true: the bare re-run still reports a no-op; `'/product-workflows:brd-split <BRD-KEY> "<what to peel off>"'` re-points a row **only** where the slice holding it recorded `deferred-to` for it; and un-delegating a row a slice is still committed to remains a conversation, not a command.

- [ ] **Step 3: Fix the two `EMPTY_INVENTORY` stops that say removal is the only thing**

`brd-split.md`'s `BRD_SPLIT_EMPTY_INVENTORY (split_mode: allocate-only)` and `brd-interview.md`'s `BRD_INTERVIEW_EMPTY_INVENTORY` both end: *"Where no row is left unallocated, the bare '/product-workflows:brd-split <PARENT-KEY>' is the run, and removal is the only thing that can change this slice's state — /brd-split never re-allocates a row that already carries a fate."*

Both are now false in the same way, and both are about a slice claiming **nothing** — which cannot be a donor (it holds no row) and can be a **receiver** only if it has not been interviewed. That is the accurate replacement: removal is no longer the only thing, because on a fully-allocated parent an instruction can re-point a sibling's deferred row **into** this slice, which is the one way it stops claiming nothing without being removed. Fix both, with the same correction, and check `brd-ground.md`'s `BRD_GROUND_EMPTY_INVENTORY` for the same sentence — read it, do not assume.

- [ ] **Step 4: Read the remaining consumers for claims the sweep's greps do not match**

`/brd-package` and `/brd-reconcile` each hit on `unallocated`. Read those hits in context and check whether either states, in prose rather than in the matched phrase, that a delegated row's owner is fixed. `/brd-intake`'s `--sort-existing` path re-allocates every child's `claims:` — read it and confirm the re-cut does not interact with it (it should not: `--sort-existing` builds a tree from scratch and the re-cut moves a row inside one that exists). Record what you checked and what you found, including "nothing" where that is the answer — a sweep that reports only its hits is indistinguishable from one that did not run.

- [ ] **Step 5: Exclude the moved row's findings from the donor's unconsumed-item report**

Spec §4 requires this and nothing else in the plan builds it: **the donor's unconsumed-item report excludes findings whose claim's row the donor's own ledger now shows as `covered-by`.** Without it, every re-cut leaves the donor reporting an open item forever for a requirement it no longer owns and cannot consume — the finding was verified, nothing downstream will ever draw on it, and its `consumed_by: none` is therefore not a gap.

The report is written at three sites, one per altitude, and each already carries an exclusion of exactly this shape for the baseline `[CG#n]` findings. **Read `plugins/product-workflows/commands/specify.md` around line 949 first** — its clause is the pattern:

```
every implementation-altitude item still `consumed_by: none`, by id, per the design's *Consumption
tracking* section (§7.3) — **excluding the baseline `[CG#n]` findings**, which are never
`consumed_by` anything and whose `none` therefore reports no gap
(`workflows-core:grounding-format` §4.1); say that they are excluded, so a reader can tell an empty
list from an unrun check
```

Add a second exclusion beside it, at all three sites — `create-prd.md:674`, `create-ard.md:706`, `specify.md:949` — matching each file's own altitude wording:

- **What is excluded:** every `[CG#n]`/`[DG#n]` whose `claim` cites a `[BR#n]` this slice's own `coverage-ledger.md` now shows as `covered-by`.
- **Why:** §3.1 says the named BRD *owns* that requirement, so nothing this run authors can consume a finding about it; the `none` reports no gap. Cite `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3.1 and §3.2.
- **Say that they are excluded, and how many** — the same reason the baseline clause gives: a reader must be able to tell an empty list from an unrun check.
- **Read the `disposition` column**, never `claims:` and never the inventory — the trap §3.1 already names, and the reason the exclusion is testable from state that already exists rather than needing a marker.

**This is a report exclusion only.** No finding is edited, renumbered, moved, or marked, and no `consumed_by` value changes anywhere. If an implementation of this step writes to a grounding file, it is wrong.

- [ ] **Step 6: Add the `decision-register-format.md` §4 paragraph**

§4 ends with *"Bounding reopening to two external causes is what makes 'decided' a claim about the world rather than about the moment."* Add one paragraph after it: a worked consequence, naming the re-cut. A sibling whose register holds decisions cannot receive a re-pointed row, because giving it new scope would put a requirement in front of a register that decided its scope without it — and neither of the two causes has arrived. Cite `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3.2, which executes the rule. Keep it to one paragraph: this file states the rule, `coverage-ledger-format.md` owns the mechanism.

- [ ] **Step 7: Verify**

```bash
./scripts/check-docs.sh --root .
./scripts/check-id-grammar.sh --root .
python3 scripts/validate-catalog.py .
```

Expected: all PASS. Then re-run Step 1's two greps and read every remaining hit: each must now be true as written.

- [ ] **Step 8: Commit**

```bash
git add plugins/product-workflows/commands/brd-interview.md plugins/product-workflows/commands/brd-ground.md plugins/product-workflows/commands/brd-package.md plugins/product-workflows/commands/brd-reconcile.md plugins/product-workflows/commands/brd-intake.md plugins/product-workflows/commands/brd-split.md plugins/product-workflows/references/decision-register-format.md
git commit -m "fix(brd-route): retire the sentences the re-cut falsifies

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

Then commit Step 5 separately — it is a different file set and a different claim:

```bash
git add plugins/product-workflows/commands/create-prd.md plugins/product-workflows/commands/create-ard.md plugins/product-workflows/commands/specify.md
git commit -m "fix(brd-route): exclude a re-cut row's findings from the donor's gap report

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

Stage only the files you actually changed — drop any path from either list you did not edit.

---

### Task 7: Documentation, `CLAUDE.md`, the changelog and the version

**Files:**
- Modify: `plugins/product-workflows/docs/commands/brd-split.md` — the `What an instruction does`, `How it runs` and `Gates` sections.
- Modify: `plugins/product-workflows/docs/commands/brd-ground.md:108` — the falsified sentence.
- Modify: `plugins/product-workflows/docs/brd-workflow.md` — `The six commands, and where they hand over`.
- Modify: `CLAUDE.md` — the `/brd-split` line of the workflow map and the coverage-ledger invariant bullets.
- Modify: `plugins/product-workflows/CHANGELOG.md`, `plugins/product-workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.

**Interfaces:**
- Consumes: everything Tasks 1–6 shipped. **Every claim on a documentation page is derived from the thing that runs it** — read `brd-split.md`'s phases and write what they do, never what this plan said they would do. That rule found six defects when these trees were first built.
- Produces: nothing.

- [ ] **Step 1: Update the `/brd-split` documentation page**

Read `plugins/product-workflows/docs/commands/brd-split.md` in full, then read `plugins/product-workflows/commands/brd-split.md`'s Phase 0 step 9a, step 10, Phase 4 Step 2R and Phase 4.5 as shipped.

- `## What an instruction does` — today it describes the instruction on a run with rows to place. Add the re-cut: on a fully-allocated parent the same argument names what to peel off a sibling, and the precondition is that the sibling's own ledger deferred it.
- `## How it runs` — it describes the paths a run can take. Add the fourth.
- `## Gates` — add `BRD_SPLIT_RECUT_NO_RECEIVER` with its condition and its remedy, in the shape the other stops on that page already take.

Do not add a page. `check-docs.sh` check 15 requires every **command** to appear in `docs/README.md`, the plugin README and `docs/workflow.md`'s mermaid diagram; `/brd-split` already does and this change adds no command.

- [ ] **Step 2: Fix the `/brd-ground` documentation page's falsified sentence**

```bash
sed -n '100,115p' plugins/product-workflows/docs/commands/brd-ground.md
```

The sentence ending `re-allocates a row that already carries a fate.` is the docs copy of the stop Task 6 fixed in the command. Rewrite it to match what the command now says — read the command, do not copy this plan.

- [ ] **Step 3: Update `brd-workflow.md`**

Read `plugins/product-workflows/docs/brd-workflow.md`'s `## The six commands, and where they hand over`. It describes `/brd-split` running twice, with grounding between. The re-cut is a **third** occasion the command runs on a parent, after a slice has been ground and found too big. Add it where the route is described, and say what distinguishes it from an Epic split — spec §1's line, which is the one a reader will otherwise ask about: an Epic split is invisible to the customer, a slice split reaches them.

If the page carries a mermaid diagram, check whether it needs a node. If it does not — the re-cut is a re-run of a command already in the diagram, not a new command — say nothing rather than adding a node for it.

- [ ] **Step 4: Update `CLAUDE.md`**

Two places, both derived from the tree rather than described:

- The `/brd-split` line of the workflow map. It currently ends with the parenthetical describing `allocate-only`. Add the re-cut to the bracketed sequence, in the same compressed style, naming its precondition.
- The **Key invariants** bullets that state the ledger rules. Find them:
  ```bash
  grep -n 'unallocated\|covered-by\|covered-here' CLAUDE.md
  ```
  Read every hit. Any that asserts allocation is terminal needs the re-cut's exception. The bullet stating that a row never returns to `unallocated` is **unchanged** and must stay — that invariant survives, and a reader needs to see that it survived.

**Do not add a count to `CLAUDE.md`.** That file states its own rule: nothing gates any number written in it, and a count here goes stale in the commit that improves the thing counted. Cite the recipe.

- [ ] **Step 5: Write the changelog entry and bump the version**

Add a `## [2.1.0] — 2026-09-07` section at the top of `plugins/product-workflows/CHANGELOG.md`, above `## [2.0.0]`, following that entry's shape: an `### Added` heading naming the capability, then prose that says what changed, what it does **not** relax, and why the number is 2.1.0 rather than 3.0.0 — nothing that worked stops working; the path this lands on previously parsed the instruction and discarded it.

Then set the version in **both** manifests:

```bash
grep -n '"version"' plugins/product-workflows/.claude-plugin/plugin.json
grep -n 'product-workflows' -A4 .claude-plugin/marketplace.json | grep -n 'version'
```

Change `2.0.0` to `2.1.0` in each. **Do not reformat `marketplace.json`** — change the value and nothing else. **Do not touch either `description`** — this is a capability *refinement* of a command the blurb already names, so no wording changes; and if you conclude it does need changing, the change **replaces** wording and never appends, under a 1024-character hard cap that fails the whole catalogue when exceeded.

- [ ] **Step 6: Run all seven gates**

```bash
python3 scripts/validate-catalog.py --selftest
python3 scripts/validate-catalog.py .
./scripts/check-id-grammar.sh --selftest
./scripts/check-id-grammar.sh --root .
./scripts/check-docs.sh --selftest
./scripts/check-docs.sh --root .
python3 scripts/session-cost.py --selftest
```

Expected: all seven PASS. `check-docs.sh --selftest` takes about two minutes. If check 9 fires, a prose count in a gated page disagrees with the tree — re-derive it rather than adjusting it.

- [ ] **Step 7: Commit**

```bash
git add plugins/product-workflows/docs/commands/brd-split.md plugins/product-workflows/docs/commands/brd-ground.md plugins/product-workflows/docs/brd-workflow.md CLAUDE.md plugins/product-workflows/CHANGELOG.md plugins/product-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "docs(brd-route): document the sibling re-cut, and release 2.1.0

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

Stage only the files you actually changed.

- [ ] **Step 8: Update the release ledger**

Edit `docs/superpowers/brd-route-follow-ups.md`'s header. Gate 2's line currently reads *"Own spec, after (1) ships."* — replace it with the shipped marker gate 1 carries, naming `product-workflows` 2.1.0 and the spec path `docs/superpowers/specs/2026-09-07-sibling-re-cut-design.md`. Gate 3 stays open. Do not claim the release is unblocked: gate 3 still blocks it under S18.

```bash
git add docs/superpowers/brd-route-follow-ups.md
git commit -m "docs(ledger): mark release gate 2 shipped

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

## Notes for the executor

**The failure mode this plan is shaped against.** Gate 1 shipped after nine fix rounds, and its most expensive defects were not caught by any gate: a command offering a next step that always refuses, an array that could drop below two options at runtime, a `<merge-clause>` promising a merge-wait that no longer existed. All three were **prose asserting behaviour that a sibling edit had falsified**. Task 6 exists for exactly that class here, and it is the task most likely to be under-done, because its output is often "I checked and this one is fine".

**What the gates cannot see, and review therefore must.** Check 12 counts literal `choices:` options and cannot see an array built at runtime — Step 2R's picker is literal and two-option, which is why the receiver is a placeholder rather than one option per candidate receiver. Check 11 gates the *presence* of `<merge-clause>` and never which row a run resolves it to. No check reads a stop message's claim about another command's behaviour; that is the whole reason CLAUDE.md records that a stop-routing check was designed and rejected on evidence.

**Where a task's text and the shipped tree disagree, the tree wins** and the disagreement is a finding to report, not a discrepancy to smooth over. This plan was written against `fccb906`.

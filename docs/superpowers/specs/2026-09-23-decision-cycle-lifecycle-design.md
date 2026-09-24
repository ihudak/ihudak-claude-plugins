# Decision-cycle lifecycle: design for deferred items (ii)–(xii)

**Status:** approved in conversation on 2026-09-23. This file is its written form.
**Branch:** `iv-gu/decision-cycle`, forked from `main` at `2998b4df`. That commit is the CLAUDE.md split, merged locally and not yet pushed.
**Release gate:** under the zero-known-bugs rule, `main` does not push until every item here is fixed. That includes the siblings research found. The push carries both the CLAUDE.md split and this pass.

## 1. Purpose

Round 3 of the exclusivity probe deferred eleven decision-cycle defects to a design pass of their own. They are listed in `docs/superpowers/verification/2026-09-23-exclusivity-probe-wider-vocabulary.md`, Round 3, under "Deferred by user decision". Tracing them turned up six more defects of the same kind (N1–N6 in §3), and implementation found fifteen more (N7–N21). This spec fixes all thirty-two.

It covers:
- `/brd-interview`, `/brd-reconcile`, `/prd-ground`, `/brd-split`, `/create-prd`, `/document` and `/release-notes`;
- the shared references `workflows-core:grounding-format` and `product-workflows:decision-register-format`.

Prose is executed, so each fix is a text change. It is complete only when every statement of the rule it changes, docs pages included, says the same thing (CLAUDE.md, *Editing discipline*, claim-expiry sweep refinements 4–8).

Abbreviations: `BI` = `plugins/product-workflows/commands/brd-interview.md`, `BR` = `brd-reconcile.md`, `PG` = `prd-ground.md`, `BS` = `brd-split.md`, `BP` = `brd-package.md`, `CP` = `create-prd.md` (all four under the same directory), `DRF` = `plugins/product-workflows/references/decision-register-format.md`, `GF` = `plugins/workflows-core/references/grounding-format.md`. The line numbers are those at `2998b4df`. They are finding aids only. Implementers match by phrase.

## 2. User decisions (2026-09-23)

| # | Question | Decision |
|---|---|---|
| D1 | (x) A corrected resend re-answers a question whose `[CD#n]` is `decided` | **Skip if identical, otherwise supersede** |
| D2 | (vii) A verifier `contradict`s an on-file finding | **Supersede the on-file finding**; own-run findings keep the in-place rewrite |
| D3 | (v) A `prd.md` with no `kind: prd` | **Counts as found**, plus a Phase 5 pre-write guard |
| D4 | "Session cost (ALWAYS runs)" in 23 command files | First decided "reword in this pass". **Revised the same day: dropped, not a defect** (§9) |
| D5 | Execution order | CLAUDE.md split first (done), then this pass; push both once known bugs = 0 |

## 3. Scope: the defect list

| Id | Unit | Defect |
|---|---|---|
| ii | A | A BI Phase 8 Cancel, an abort, or an interruption between Phase 7 and Phase 9 leaves held `[C]` entries and defect-line appends in `customer-questions.md` that no round record names |
| iii | A | A record reopened by BR step 3 or by the propagation sweep has no BI question source, so it stays `reopened` for good, and BR keeps offering a dead-end "Work another round" |
| iv | A | BI Phase 12's key events list "a cancelled `[V]` queue", but no path that cancels reaches Phase 12 |
| xii | A | BI's legacy-anchor fallback `git log -1 -- <record>` sees only history reachable from HEAD |
| N1 | A | A deferred re-put `[V]` question has no structured record id in the round record. Only `[C]` entries carry `- **Re-puts:**` |
| N2 | A | `docs/commands/brd-interview.md` says a Phase 8 Cancel "writes nothing", which is false today. Fixing ii makes it true |
| N3 | A | xii's squash-merge variant: `log -1` returns a squash commit whose grounding files already include later changes |
| x | B | BR step 3 has no disposition when a later review answers a `decided` or `decided`+`conditional_on` record's question the same way with no `- **Re-puts:**` line |
| N4 | B | BR's section-7 matching table (BR:630) describes a `[C]` match as "held for the customer". Read as a filter, that makes the corrected-resend branch dead, so it contradicts BR:1045–1052 |
| vii | C | A PG Phase 7 `contradict` rewrites an on-file finding's verdict in place. Nothing reopens, and a later `prior_verdict` records the rewritten verdict |
| viii | C | PG Phase 8's closed field list omits `prerequisite` |
| ix | D | PG Phase 0 step 6 does not state whether the ledger gate or the inventory gate resolves first, and the order changes the stop printed |
| xi | D | BS's write order is untraced. An interrupted carve and a declined handoff look identical, and `PRD_GROUND_NOT_HANDED_OFF` tells the operator that a re-run which would resume the walk "is a no-op" |
| N5 | D | xi's silent variant: a slice whose `claims:` names a `[BR#n]` its inventory does not hold passes every gate, and that row is never grounded |
| N7 | D | A resumed `/brd-split` run reconciles (Phase 4 Step 3) only the children its own walk touched, so a stale provisional claim from an interrupted run survives on a slice. And once the parent is fully allocated, a bare re-run is a no-op, so no command repairs an out-of-step slice. Found by Task 1's implementer |
| N8 | D | An ordinary `/brd-split` walk can assign a row to a child that already holds a terminal orphan row for that `[BR#n]` (reachable after a `/brd-intake` re-run over the parent). The child then claims the row while its own ledger names another owner, and no command resolves it. Found by Task 1's implementer |
| N9 | D | Rows 2–3 of `/prd-ground`'s `PRD_GROUND_NO_INVENTORY` remedy table (no ledger in the folder) are unreachable under D1's gate order except where the ledger is on a ref but deleted from the worktree, and there their "no command has committed this slice's folder" is false. Found by Task 1's implementer |
| N10 | C | `/prd-ground` Phase 8 lists `consumed_by: none` among the fields every written block carries, which read literally resets an on-file finding's `consumed_by` stamps on a re-run. Found by Task 2's implementer |
| N11 | C | `/brd-interview`'s successor test 4 places a `[DG#n]` by the frame its evidence cites. A design finding whose evidence cites no frame can never have a successor, so a decision resting on one cannot be observed as confirmed or moved when it is superseded. Found by Task 2's implementer; reachability to be judged in review |
| N12 | C | `/brd-interview`'s *A decision the re-grounding moved* takes a record only once **every** `evidence` finding reads `SUPERSEDED`, while `decision-register-format` §4 cause 1 fires on any superseding finding. So a decision resting on several findings, some of them superseded, reopens nothing. The `contradict` route (C1) makes this the common case. Found by Task 2's review |
| N13 | C | On a plain `/prd-ground` re-run the design pass receives no code findings, so it writes no class-4 `[DG#n]`. The frame-set supersession rule still retires the old class-4 findings of every re-grounded frame set, and nothing regenerates them. Found by Task 2's implementer |
| N14 | C | Phase 6 overwrites the `horizon` of an on-file finding it does not supersede, the same in-place class of defect as vii. Found by Task 2's implementer |
| N15 | C | Design findings rewritten in place before R16 cite code only, so they can never be placed in a frame set. Found by Task 2's implementer |
| N16 | A | After a declined handoff, `/brd-package` step 6 assumes `customer-questions.md` merged along with `decisions.md`, inferring one artifact's merged-ness from a sibling's gate (`workflows-core:phase-handoff` §4.0 forbids this). Found by Task 3's implementer. Ruling R26: step 6 executes `require-on-main` against each file it ships |
| N17 | B | A resend with the same `chosen` and `reason: not stated` goes to the missing-reason picker. Its "freeze open" option supersedes a `decided` record with an `open` one that nothing chases, and step 1's "stays held for the customer" is then false. Found by Task 6's implementer |
| N18 | B | A resend answering a question whose record was superseded through a `Re-puts` line, or withdrawn, freezes a second `decided` answer to that question. Found by Task 6's implementer |
| N19 | B | The reader's "an open `[AS#n]`" filters the same way N4 did, and step 2 has no rule for re-answering an `[AS#n]` that is already superseded. Found by Task 6's implementer |
| N20 | B | `/brd-reconcile`'s reader receives only the most recent self-review, so a review of an earlier package has its `[SR#n]` matched against the wrong file's text. Found by Task 6's implementer |
| N21 | B | A self-review finding re-escalated under a new `[SR#n]` in a later package is frozen beside its earlier answer. Nothing ties the two ids together. Found by Task 6's implementer |
| v | E | CP step 6 does not say whether a `prd.md` with no `kind: prd` counts as found |
| N6 | E | CP Phase 5 writes `prd.md` with no existence guard. Under the strict reading of v, a keyless `prd.md` is overwritten with no archive |
| vi | E | `/document` and `/release-notes` stop on a found-but-unplaced folder, a BRD container, or a folder holding no PRD, using the "key dir not found" rule and `["Re-enter key", "Cancel"]`. That happens at two sites in each command |

Out of scope: any change to what an abort or Cancel does, and any structural "carve in progress" marker in `/brd-split` (Unit D's gate closes N5 without one).

## 4. Unit A: `/brd-interview` lifecycle

### A1. Hold `[C]` entries in memory until Phase 9 (ii, N2)

- The Phase 7 step headed *Hold every `[C]`* stops writing `interview/customer-questions.md` and builds each entry in memory. Each entry still carries every field it carries today, and the heading `## Round <N>, question <position>`.
- *One question per row*'s defect-line append (`- **Requirement defect:**` on a held entry, during *Resolve the round*) is held in memory the same way.
- Phase 9 (*Write the register and the round record*) becomes the only writer of every interview deliverable. It writes in this order:
  1. `customer-questions.md`
  2. `round-<N>.md`
  3. `decisions.md`
- **Idempotency.** An entry is written only where no entry headed `## Round <N>, question <position>` is already in the file. A defect-line append is written only where that entry does not already carry that `[DEF#n]`.
  - The case this covers: a crash between writes 1 and 2 leaves entries with no round record. The next run's regeneration of round N then replaces them in place and does not duplicate them.
  - That replacement is an explicit rule: where round N has no `round-<N>.md`, entries headed with round N are this run's to rewrite.
- **Legacy strays.** The Phase 0 step that reads `customer-questions.md` reports every entry whose heading names a round that has no `interview/round-<N>.md`. The report names each one. The run does not delete them, because an earlier version wrote them and the operator decides what happens to them.
  - Where the current run opens that same round N, the idempotency rule applies and those entries are rewritten.
- **Delete** the "already on disk and stay" caveats at BI:1255–1264 and BI:1386–1395. Replace each with a statement that Cancel or abort writes nothing to the BRD folder.
- **Readers.** The *asked* test (BI:802–808), BP step 7's round derivation, BP part 7 and BR matching need no change, because under A1 no new stray can arise. Their premise, that every entry has a round record, is now true for any entry written after this change. The legacy detector covers entries written before it.
- **Sweep.** `docs/commands/brd-interview.md` (≈397–399) is now true as written; re-read it. Re-read BI:352–357, 615–627, 1320–1337, 1545–1547 and 1600–1602 against the new write timing.

### A1a. Rulings from Task 3 (revise A1)

A1 as first written did not recover from a crash between Phase 9 writes. The regenerated round need not hold a `[C]` at the same positions. The *asked* test counts a stray entry's defect line, and every reader of an entry trusts it. A crash between the round record and the register also silently lost decisions.

- **R23, write order.** Phase 9 writes `decisions.md`, then `code-defect-log.md`, then `customer-questions.md`, then `round-<N>.md` **last**. The round record is the commit point: a round's deliverables count only once its record names them.
- **R24, torn writes.** A register record, `[CDF#n]` or `customer-questions.md` entry stamped with round N is a **torn write** where `interview/round-<N>.md` does not exist, or does not name it. The definition is stated once, in `decision-register-format.md`, and every reader cites it and never counts a torn item. The readers are:
  - BI's *asked* test and question generation;
  - BP step 7's round derivation and part 7;
  - BR's matching;
  - every consumer of the register that the implementer's sweep finds.

  BI Phase 0 reports torn items. BI Phase 9 removes them in the same writes, before appending its own. That is the only deletion a run makes, and nothing ever counted those items. The idempotency rule of A1 is replaced by this.
- **R25, pre-Phase-9 writes.** The `--round` re-open append and the round-1 test's appended questions are held in memory until Phase 9, like the `[C]` entries. "Phase 9 is the only writer" is scoped to a round's deliverables within `/brd-interview`. `/brd-reconcile` writes the same files by its own rules, and the no-new-round path's register header is a completed run's write, not a round's. A Cancel or an abort then writes nothing.

- **R27 (amends R23).** The order is `code-defect-log.md`, then `decisions.md`, then `customer-questions.md`, then `round-<N>.md`. A counted decision never cites a `[CDF#n]` that is on no file, and a crash can never let a later raise reuse that id.
- **R28.** Where the round record being written, or resumed, carries no `code defects:` line (or requirement-defect line), Phase 9 first appends a baseline line naming the known set, before any new entry. So the legacy fallback ("a record without that line names every `[CDF#n]` of its round") never counts a torn entry.
- **R29.** A `[CDF#n]` re-disposition is applied as a fifth write, after the round record. BI Phase 0 re-applies it idempotently from a counted record's `code defects: re-dispositioned … <old> → <new>` line. DRF §8 no longer lists a re-disposition among the in-place changes that stand.
- **R30.** The no-new-round path also removes torn writes, since it completes a run. It reports what it removed.

### A2. Question source for a reopened record (iii) and a structured re-puts marker (N1)

- **N1 marker.** Every question in a round record that re-puts an existing record carries a structured line `- **Re-puts:** [VD#n]` (or `[CD#n]`, or `[AS#n]` where applicable), whatever its tag. The spelling is the one `[C]` entries already use, so there is one noun across the family. This covers:
  - the case-A reopen BI already performs;
  - a held record re-put after its evidence was superseded;
  - the new source below.

  Every reader that resolves a re-put `[V]` to its record reads that line. None parses prose.
- **New source, "A decision reopened elsewhere."** For every `[VD#n]` or `[CD#n]` reading `status: reopened`:
  1. The record is **in flight** exactly where a question in any round record carries `- **Re-puts:**` naming it and that question has no terminal disposition. Terminal means *answered*, or for a `[C]`, *answered by the customer*.
  2. Where the record is not in flight, this source puts its question again, in the round the run opens, under the record's own tag (`[V]` for `[VD#n]`, `[C]` for `[CD#n]`). The question is phrased against the current findings. Every `Reopened <date>: …` paragraph on the record is quoted as context, and the question carries the `- **Re-puts:**` line.
  3. A reopened record that is not in flight is a change that makes a new round askable. The *Every round is closed* branch (BI:514–520) and Phase 11's `nothing-to-review` (BI:1701–1706) stop saying that such a move "raises nothing". Their text changes to: a record moved to `reopened` raises its question through this source, and a record moved to `superseded` raises nothing.
- **Answer side.** No change is needed. BI Phase 6's re-decision rule and BR step 3's `reopened` Re-puts bullet already re-decide a record in place when an answer carries its `- **Re-puts:**`. The implementer confirms that both key on the structured line.
- **Timing.** A record reopened while a round is open waits and is reported, as a changed finding does today (BI:930–935).
- **Sweep.** DRF:287–288 ("or by a later one") becomes true, so re-read it. Re-read and keep BR:2119, 2165 and 2179, `docs/workflow.md:70`, the edge in `docs/brd-workflow.md:46`, `docs/commands/brd-reconcile.md` (12–13, 108, 531–532), `create-ard.md:289` and `specify.md:334`. Rewrite every copy of "raises nothing by that move alone". Update `docs/commands/brd-interview.md`'s description of question sources to list the new source.

### A2a. Rulings from Task 4's review

- **R31.** A resumed re-put `[V]` written by a released version carries no `- **Re-puts:**` line. For it, `/brd-interview` asks the operator which record it re-puts, or none. The choices come from the known set of `reopened` records and held records that fit its question, using the overflow rule for more than four. Phase 9 writes the line. No prose is parsed, and a `CHANGELOG.md` upgrade note names the case.
- **R32.** `/brd-reconcile` offers *Work another round* only where every round is closed, per its own rule against offering a run that reports nothing new. BI's matching `yes` label follows. This overrides A2's "re-read and keep BR:2119".
- **R33.** Only one round is open at a time. `--round <highest+1>` while a lower round is open stops and names the open round, unless the implementer finds text that deliberately allows concurrent open rounds. In that case the finding goes back to the controller.

- **R34 (replaces R33).** Concurrent open rounds are deliberate: Phase 11's `defects-unasked` and a `--round 1` re-open. What is ruled out is narrower. `--round <highest+1>` while a lower round holds a question with no terminal disposition stops and names that round. The no-flag path would resume the open round, so that request has no branch to mirror.
- **R35.** From this change on, every `[V]` question in a round record carries a `- **Re-puts:**` line, reading `none` where it re-puts nothing. A `[V]` with no line is therefore exactly one written by a released version, and R31's picker fires only for those questions.

### A3. Delete the dead key event (iv)

- Remove "a cancelled `[V]` queue" from BI Phase 12's key-events list (BI:1797–1799).
- The list keeps only events that reach Phase 12.
- The *Session cost* heading beside it is handled in Unit F.

### A4. Anchor lookup across every ref, matched on content (xii, N3)

Replace the legacy-record anchor at BI:499–504 as follows:

1. `blob = git -C "$SPECS_PATH" hash-object -- <record>`.
2. `candidates = git -C "$SPECS_PATH" log --all --format=%H -- <record>`.
3. The anchor is the **earliest** candidate whose `git -C "$SPECS_PATH" rev-parse <sha>:./<record-path>` equals `blob`. The round record is append-only, so that commit is where its current content was first written. The rule resolves the anchor against the candidate set and does not trust log order alone.
4. Where no candidate matches, read every finding as unchanged and print *no commit on any ref holds round `<N>`'s record as it stands on disk, so no finding change could be detected*.
5. Where the matched commit's grounding files may already include later changes, name the residual on the report line: *compared at `<short-sha>`, a commit that may postdate the record's write*. A squash commit that is the only holder is the case this covers. The condition must be an observable test, never a judgement. The fallback test is that the matched commit itself changed a file under `grounding/`.

Apply the same change to BI:526–528, BI:1004–1008 and BI:1517–1518, and to `docs/commands/brd-interview.md:35–37`.

## 5. Unit B: `/brd-reconcile`

### B1. A same-way re-answer (x, D1)

- **Phase 4 skip rule** (BR:792–806, extended). The target is a `[C]` question whose current record is `decided`, including `decided` with `conditional_on`. Where a candidate's `chosen` equals the record's `chosen`, and its quoted reason is byte-equal to the record's quoted reason after whitespace collapse, the candidate is skipped. It is reported as *already reconciled, re-affirmed by <review file>*. The skip:
  - mints no `[CD#n]`;
  - appends no *answered by the customer*;
  - adds nothing to the propagation sweep's changed-id set.
- **Step 3 "replaces"** (BR:1054–1062). This is redefined as *the new answer answers the record's own question again, whatever it chooses*. That makes it `superseded`, and it matches the Re-puts path (BR:1086–1092) and the rule for the three non-`decided` statuses (BR:1065–1075).
  - The "contradicts or constrains without replacing → `reopened`" bullet keeps its meaning: an answer that bears on the record's question **without answering that question**.
  - With this redefinition, a same-way answer with a different reason supersedes the old record. The identical case never reaches step 3.
- **Sweep.** Re-read BR:1125–1129, BR:450–456 and 1045–1052, DRF:223–238, and `docs/commands/brd-reconcile.md` 161–173 and 301–325.

### B2. The section-7 matching descriptor (N4)

- Reword BR:630's third column so it describes the question the entry holds, whatever that question's state.
- A question that is already *answered by the customer* still matches. The corrected-resend branch depends on it matching, and B1's skip rule then disposes of it.
- Check `agents/customer-review-reader.md` (≈150–156) for the same wording.

### B3. Rulings from Task 6

- **R37 (N17).** A candidate that repeats the target record's `chosen` and states no reason re-affirms the record: it is skipped, as B1's skip is. A missing reason is not a different reason, and the recorded reason stands. Only a different `chosen`, or a different stated reason, supersedes.
- **R38 (N18).** An answer's target resolves to the question's **live** record, following supersession (`Re-puts` included) to its successor, and B1 compares against that record. An answer to a question whose live record is `withdrawn` freezes nothing, and is listed under "what still needs a human".
- **R39 (N19).** The reader's `[AS#n]` row describes the record without filtering it. A re-answer to an `[AS#n]` that is already superseded resolves to its successor, as R38 does.
- **R42 (narrows R40).** An `[SR#n]` target resolves through the self-review file of the package the review answers, never by `[SR#n]` alone, because every package restarts that numbering. Where that file cannot be determined from the review and the package on file, no skip applies: the answer is frozen as it would be without B1.
- **R43.** The skip compares the **confirmed** option. It runs only once Phase 5's answer→option mapping is confirmed. In free-text mode a `reason: not stated` is also confirmed. An unconfirmed mapping never skips.
- **R44.** A review's candidate is skipped as already reconciled wherever its target's chain holds a record **this same review** froze, whatever that record's status is now. So re-running an earlier review never supersedes a later review's answer.
- **R45.** A held entry frozen `open` for want of its reason is a live record: the chain starts at it. Against it:
  - the same `chosen` with a stated reason completes the record;
  - the same `chosen` with no reason is skipped (R41);
  - a different `chosen` supersedes it (D1).

  A held `Re-puts` entry whose live record is `withdrawn` closes with a terminal disposition naming the withdrawal, so its round can close.
- **R46 (N20).** The reader receives the self-review file of the package the review answers, resolved as in R42. Where that cannot be determined, every `[SR#n]` answer in the review is `unmatched` and listed under "what still needs a human". It is never matched against another package's file.
- **R47 (N21).** When `/brd-package`'s self-review re-escalates a finding an earlier package already escalated, it writes a structured `- **Re-escalates:** <earlier self-review file> [SR#n]` line on the new entry. `/brd-reconcile` follows that line when it resolves the chain (R38), so the new answer is judged against the earlier answer's live record. Entries written before this change carry no line and are frozen fresh, which is the safe direction. The CHANGELOG says so.
- **R48 (refines R46).** Where the review's section 1 does not determine the package, `/brd-reconcile` Phase 3 asks the operator to pick one from the dated `customer-review-prompt-*.md` files on file. `/brd-package` prints a labelled "Package reviewed" line into the prompt, and `customer-review-schema.md` §4 requires section 1 to repeat it, so the package is determinable from then on.
- **R49 (refines R47).** `/brd-package`'s disposition gate shows the earlier finding's words beside the new one. It writes the `Re-escalates` line only where the operator confirms the two are the same finding, and otherwise writes no line. BR states that the line is operator-confirmed.
- **R40.** B1's skip also covers `[AS#n]` and `[SR#n]` targets, so an identical re-answer never supersedes needlessly.

## 6. Unit C: grounding supersession

### C1. A `contradict` on an on-file finding becomes a supersession (vii, D2)

Change PG Phase 7 (≈1038–1048) and GF §8:

- **Own-run finding.** This invocation produced the finding and it is not yet on file. It keeps today's in-place rewrite under the same id, because nothing cites it yet.
- **On-file finding.** The finding is inherited or being re-checked, and it is already written under `grounding/`.
  - The on-file block takes `verdict: SUPERSEDED`, and `prior_verdict` holds its on-file verdict, which is the verdict any decision was taken on. A note names the successor.
  - A new finding is appended with the next id in its prefix. It carries:
    - the same `claim`, `commit`, `altitude`, `horizon` and `prerequisite`;
    - the verifier's `own_verdict`, `own_evidence` and `control`;
    - `outcome: contradict`;
    - a note naming the id it supersedes.
  - The new finding meets BI's successor tests 1–4 (BI:854–870), so BI's *A decision the re-grounding moved* observes the change unmodified. The implementer confirms each test holds for this successor.
- **Cascades.** The class-4 `[DG#n]` handling moves from the in-place trigger (PG:1050–1054) to Phase 8's existing rule that superseding a `[CG#n]` supersedes every class-4 `[DG#n]` citing it. The coverage ledger's `evidence` column and the `consumed_by` stamps get the same treatment `--rebaseline` already gives a superseded id. The implementer traces both and cites the lines.
- **GF edits.**
  - §2.1 (≈117–121) narrows "§8's `contradict` handling has already replaced `verdict`" to own-run findings.
  - §6.3 (≈722–724) names both routes.
  - §8's outcome table gets the on-file branch.
  - GF:48 and GF:63–68, the definition and rationale of `prior_verdict`, are re-read. They become true unmodified.
- **DRF §4 cause 1** (≈199–202). Add: *a verifier `contradict` on an on-file finding is recorded as a supersession (`workflows-core:grounding-format` §8), so it reaches this cause like any other*.
- **Sweep.** `docs/commands/prd-ground.md:361–362`, `docs/brd-workflow.md:183–189`, `docs/commands/brd-interview.md:345–353`, and PG:1150–1156. Narrow "the id never changes, so every existing citation into it still resolves" to own-run findings everywhere it appears.
- `workflows-core` changes. Fold them into its unpublished `1.7.6` CHANGELOG section. Do not bump again.

### C1a. Rulings from Task 2's review

- **R15 (N12).** *A decision the re-grounding moved* takes a record where **any** of its `evidence` findings reads `SUPERSEDED`. That aligns it with DRF §4 cause 1.
  - The confirmation test runs per superseded finding: its successors must confirm against its `prior_verdict`.
  - The record is confirmed only where every superseded finding confirms. Otherwise it is reopened and re-put.
  - Unsuperseded evidence stands as cited.
  - Every copy of the "every … reads `SUPERSEDED`" premise is swept.
- **R16 (N11).** A `[DG#n]`'s in-place rewrite, and any `[DG#n]` successor, keeps the frame citations of the evidence it replaces, alongside the verifier's `own_evidence`. A design finding therefore always cites a frame and can always be placed in a frame set.
- **R17 (N13).** PG Phase 8's frame-set rule retires a prior class-4 `[DG#n]` only where this run re-ground the repository its cited `[CG#n]` is pinned to, or under `--no-code`. Otherwise the finding stands, and only the cascade retires it. The cascade's first bullet reads "where the frame-set rule supersedes it".
- **R18 (N14).** Phase 6 never edits an on-file finding's `horizon` or `prerequisite` in place. It supersedes the block and appends a successor carrying the same verdict, evidence and control, and the new horizon. That successor is own-run, so Phase 7 verifies it. GF §5 states the rule.
- **R19 (N15).** In BI's held-record bullet, where a superseded finding's source cannot be decided (as opposed to having no successor yet), the held record is put again rather than waiting, and the question names that finding. No migration.
- **R20.** A design re-run that does not re-emit an unchanged divergence reopens the decisions citing it. That is DRF §4 cause 1 by contract, and it is not dampened. Damping would leave a divergence that changed frames resolved still live, which is worse than an extra question.
- **R21.** Phase 6's second exception: an on-file `[DG#n]` that cannot be placed in a frame set is superseded with no successor. Its note names the horizon Phase 6 would have written and why no successor can be placed. A stale horizon is never left for downstream to consume.
- **N10.** `consumed_by: none` is written only on a block this run appends. An on-file block keeps its stamps. The on-file block's `outcome` rule is stated once, without contradiction.

### C2. `prerequisite` in Phase 8's field list (viii)

- In PG Phase 8's parenthetical (≈1144–1149), add `` `prerequisite` on every finding reading `horizon: will-change` `` beside the other conditional clauses.
- A grep confirms that no other file re-enumerates the list.

## 7. Unit D: `/prd-ground` gates

### D1. Gate order (ix)

- Step 6 states the order: `coverage-ledger.md`'s `require-on-main` resolves first, including whether the file is in the folder at all on row F. Only then is `brd/brd-inventory.md`'s gate evaluated and its stop printed.
- The step also states why: the ledger's row-F branch (a) disposes of an inventory the carve left behind (PG:238).
- Where both gates stop, the ledger's stop is the one printed.

### D2. An unfinished carve, and slices out of step with their parent (xi, N5, N7). Revised 2026-09-23 by controller rulings R3–R6

The first draft of this section, a clause appended to `PRD_GROUND_NOT_HANDED_OFF` and a gate comparing `claims:` with the inventory, failed under implementation. Four reasons:
- Phase 3's provisional files agree with each other by construction, so a carve cancelled and then committed passed both gates and was grounded.
- The appended clause contradicted its own stop's "Commit …".
- It named the bare `/brd-split` form, which stops with `BRD_SPLIT_NEEDS_INSTRUCTION` while any row is `unallocated`.
- Its remedy could be a no-op.

The revised design:

- **R4, a new stop `PRD_GROUND_CARVE_UNFINISHED`.** On ledger row F branch (b), before `PRD_GROUND_NOT_HANDED_OFF`'s text, read `<PARENT-KEY>`'s own `coverage-ledger.md`.
  - **It holds any `unallocated` row:** this stop fires in place of `PRD_GROUND_NOT_HANDED_OFF`. The wording is cause-neutral: say what the ledger shows (its carve is not finished) and never why. A `/brd-intake` re-run also resets rows. The stop names the instructed form `'/product-workflows:brd-split <PARENT-KEY> "<how to cut it>"'`, and says nothing here is to be committed until that run completes.
  - **It holds no `unallocated` row:** `PRD_GROUND_NOT_HANDED_OFF` stands. Its "claims nothing" clause is unchanged.
  - **The ledger is unreadable or absent:** use the file's existing idiom. Report it by path, name no `/brd-split` form, and assert neither state.
- **R3, a reconciliation gate `PRD_GROUND_SLICE_UNRECONCILED`,** which replaces the draft's `PRD_GROUND_CLAIMS_INVENTORY_MISMATCH`. On `route: brd`, after both `require-on-main` gates pass, compare three sets, resolving ids and parsing no prose:
  - (a) the `[BR#n]` in the slice's `brd-link.md` `claims:`;
  - (b) the `[BR#n]` in `brd/brd-inventory.md`;
  - (c) the rows of `<PARENT-KEY>`'s `coverage-ledger.md` reading `covered-by: <SLICE-KEY>`.

  Where they are not all equal, stop. Name each id by which set lacks it. This catches:
  - a carve cancelled and then committed (the parent reads `unallocated`, so the row is absent from (c));
  - IP4 and IP5;
  - N7's stale claim.

  The implementer must first prove that (a) = (b) = (c) holds on every completed-run path: an ordinary carve, a re-cut (§3.2), a removal's key repair, and a child's own `deferred-to`. Any legitimate completed state that breaks it goes back to the controller.
  - **Remedy:** where the parent holds an `unallocated` row, name the instructed form. Otherwise name the bare `'/product-workflows:brd-split <PARENT-KEY>'`, which R5 makes a live reconcile run.
  - **Unreadable parent ledger:** as in R4.
- **R5 (N7), `/brd-split` reconciles every child against the parent.** Phase 4 Step 3's selector widens to every child standing under this BRD, found by Phase 0 step 9's positive test. It reconciles each child's three files to the parent's `covered-by: <CHILD-KEY>` rows. Where they already agree, the step writes nothing for that child.
  - Phase 0 step 10's branches gain a live path. On a fully-allocated parent with no instruction and no standing empty child, a bare run is **no longer a no-op where some child is out of step** (the same (a) = (b) = (c) test). It runs Step 3 reconcile only, then its usual close.
  - Every statement of "re-running is a no-op" is swept: the command's `description:` frontmatter (whose budget is checked by `validate-catalog.py`), the docs page, and `coverage-ledger-format.md`.
- **R6.** The draft's "Re-run it: it resumes the walk" wording is withdrawn everywhere.
- **R11 (N8, supersedes the controller's first N8 ruling R10).** Apply §3.2's per-row receiver exclusion to the ordinary walk as well: a child already holding any row for a `[BR#n]` (an orphan row, or its own decision row) is not offered that `[BR#n]`, and the walk names why. `coverage-ledger-format.md` §3's "no row of a slice's ever moves back" stands. The row still takes a terminal disposition on the parent: another slice (existing or newly keyed), deferred, rejected, or superseded. §2's and §5.2's sentences are reworded to match (§5.2's "never `covered-here`" is false as written).
- **R12 (narrows R11).** The exclusion bars a child only where it holds a row for a `[BR#n]` that it does **not** currently claim (an orphan row, §2). A child that still claims the `[BR#n]` is offered it, whatever its own row reads, because re-assigning it breaks no invariant and moves no row back. Its existing row stands, and Step 3 writes nothing for it. This keeps N8's fix, and stops a `/brd-intake` re-run from stripping every settled claim from every slice. Any third orphan route R11 created is re-derived: if R12 removes it, §2 returns to two routes. Otherwise every copy is swept, and a slice's §6 line counts such a row through the parent's current disposition, never through the child's own overruled one.
- **R7 (revises R5).** Step 3's widened reconcile also runs on the Phase 4.5-only path, ahead of Phase 4.5, and R5's live path drops its "no standing empty child" condition. Otherwise a `Cancel` mid-Step-2R, followed by a bare run that keeps an uninterviewed empty child B, leaves the parent reading `covered-by: B` while B claims nothing, and the gate's remedy loops (`brd-split.md`, the Step 2R cancel note). Phase 4.5 already recomputes emptiness "as Step 3 left it", so B regains its claim and is never offered for removal.
- **BS `Cancel` paragraph.** Append: each slice's three files stay provisional until Step 3 reconciles them against the parent, and `/prd-ground` refuses the slice until then (`PRD_GROUND_CARVE_UNFINISHED` / `PRD_GROUND_SLICE_UNRECONCILED`).
- **Sweep.** `docs/commands/prd-ground.md`, `docs/commands/brd-split.md`, `coverage-ledger-format.md` §3, §5.1 and §6, and the `/brd-split` line in `.claude/rules/brd-route.md`.

## 8. Unit E: `/create-prd` and the unplaced-folder stops

### E1. A keyless `prd.md` counts as found (v, N6, D3)

- CP step 6 (≈218) states it outright: any file at `<feature-folder>/prd.md` counts as found, whatever its frontmatter, and that matches `/update-prd`. Replace "`kind: prd` identifies the draft inside it", which reads as a gate, with a sentence saying `kind:` does not decide presence here.
- Name the contrast with `workflows-core:addressing` §5's three kind-gating commands. They gate on `kind: prd` because they consume a PRD's content, and `/create-prd` gates on presence because it must not overwrite one.
- **Phase 5 guard** (≈708). Immediately before writing `prd.md`, test whether the file exists. Where it does and the run did not reach Phase 1's archive-and-overwrite, archive it first, as Phase 1 step 2's overwrite does (`revisions/`, same naming), and report the archive path. Nothing is ever overwritten unarchived.
- **Sweep.** `docs/commands/create-prd.md` gets one sentence on the keyless case. Re-read `addressing.md:337–341` and keep it. It names only the three kind-gating commands, and that list stays true.

### E2. Named stops for found-but-unplaced folders (vi)

In `plugins/docs-workflows/commands/document.md` (Phase 0 step 1, ≈64–66, and Phase 3, ≈364) and `release-notes.md` (≈61–66 and ≈237), replace the reuse of the "key dir not found" rule with named stops. They follow `/ready`'s `READY_BRD_NOT_SLICED` and `/specify`'s split (`specify.md:467–476`):

| Stop | When | Message names | Choices |
|---|---|---|---|
| `DOCUMENT_BRD_NOT_SLICED` / `RELEASE_NOTES_BRD_NOT_SLICED` | §4.1 places the folder as a BRD container | the folder, and each slice under it found by §4.1's positive test | `["Enter a slice key", "Cancel"]` |
| `DOCUMENT_FOLDER_NOT_PLACED` / `RELEASE_NOTES_FOLDER_NOT_PLACED` | §4.1 places the folder at no level | the folder, what it carries, and the remedy: give it a carrier (`workflows-core:addressing` §5), or where it holds an `idea.md` and no `prd.md`, run `/product-workflows:create-prd <KEY>` | a plain stop naming the remedy. It is not a `choices:` array, because nothing the run can offer fixes the folder |
| `DOCUMENT_NO_PRD` / `RELEASE_NOTES_NO_PRD` | the second site: a PRD-level folder that holds no PRD | the folder, and `/product-workflows:create-prd <KEY>` | a plain stop |

- "Enter a slice key" re-enters address resolution with the key typed. The choices array obeys check 12: 2–4 options and no "Other".
- The implementer confirms each stop's message wording against `workflows-core:escalation-rules`' conventions for named stops.
- **Sweep.** `docs/commands/document.md` and `docs/commands/release-notes.md` document the three stops. `escalation-rules.md:175` keeps "key dir not found" for a folder that really is absent. Its description is re-read so that it no longer implies these cases.
- `epics.md:420–421`, which says an empty PRD is "the `key dir not found` case", has the same mislabel. It gets `EPICS_NO_PRD`'s existing stop or a named sibling. The implementer checks whether `EPICS_NO_PRD` already covers it.

## 9. Unit F: dropped (D4, revised)

The research flagged "Session cost (ALWAYS runs)" as false, because an abort or a Cancel stops a run before its cost step. Planning re-read it in context, and it is true there.
- It heads step 3 of a command's terminal phase.
- It follows step 2, the feedback step, which persists nothing when there is no plugin signal.
- `workflows-core:cost-emission` §0 states the same contrast: "Unlike feedback … the cost phase always computes."

"ALWAYS" therefore contrasts cost with feedback inside the phase. It makes no claim about runs that never reach the phase, and an aborted run skips feedback and cost alike. The user decided to drop the unit. No file changes for it.

## 10. Releases

| Plugin | Now | After | Why |
|---|---|---|---|
| `workflows-core` | 1.7.6 (unpublished) | 1.7.6 | Unit C's GF edits. Folded into the dated 1.7.6 section |
| `product-workflows` | 3.8.2 | 3.8.3 | Units A–E |
| `docs-workflows` | 1.3.3 | 1.3.4 | E2 |

- Each version is bumped in `plugin.json` and in `marketplace.json`.
- Every new CHANGELOG section is dated before it reaches `main` (check 18).
- Descriptions are not touched.

## 11. Verification

- The nine CI gates, run as one `&&` chain whose exit code is printed. `scripts/validate-catalog.py` runs on Python 3.11 (`uv run --python 3.11`).
- For every rewritten claim, a refinement-7 literal-string count across the sweep scope, taken before and after the edit and recorded with its command.
- The per-item trace: each failure scenario in §3 is walked step by step against the new text, and the step where it now resolves is cited by file and phrase.
- An exclusivity probe over the diff, covering new "only", "never" and "every" claims introduced by this pass.
- The verification record `docs/superpowers/verification/2026-09-23-decision-cycle-lifecycle.md` is written last, after the final fix wave. It closes each §3 row as FIXED with the commit that fixed it. Only once all thirty-two rows read FIXED is the known-bug count 0.
- Every row of the round-3 "Deferred by user decision" list gets a one-line pointer to this record.

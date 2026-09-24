# Decision-cycle lifecycle — verification record

Branch `iv-gu/decision-cycle`, base `2998b4df` (the CLAUDE.md split, merged locally and unpushed), tree verified at `669eccfc`. Spec `docs/superpowers/specs/2026-09-23-decision-cycle-lifecycle-design.md`, plan `docs/superpowers/plans/2026-09-23-decision-cycle-lifecycle.md`, ledger `.superpowers/sdd/2026-09-23-decision-cycle-lifecycle/progress.md` (a finding aid, not evidence). Written last, on 2026-09-24, after the final whole-branch review and its fix wave (five rounds, ending at `669eccfc`), per `CLAUDE.md` § Editing discipline. Every expected value below was re-derived against the tree by the command named beside it; none is copied from the plan, the brief or the ledger.

**Status: every spec §3 defect FIXED; no defect found by the exclusivity probe.** The 42 rows of spec §3 (11 deferred items and N1–N31) each resolve at the text quoted in *Defect table*. The gate chain exits 0. The probe over this branch's added lines found 153 exclusivity or tree-universal hits and no DEFECT among them.

Line numbers in this record are at `669eccfc` and are finding aids only; each row is matched by its quoted phrase. Abbreviations follow spec §1: `BI` `brd-interview.md`, `BR` `brd-reconcile.md`, `PG` `prd-ground.md`, `BS` `brd-split.md`, `BP` `brd-package.md`, `CP` `create-prd.md` (all under `plugins/product-workflows/commands/`); `DRF` `plugins/product-workflows/references/decision-register-format.md`; `CLF` `plugins/product-workflows/references/coverage-ledger-format.md`; `CDLF` `plugins/product-workflows/references/code-defect-log-format.md`; `GF` `plugins/workflows-core/references/grounding-format.md`; `ER` `plugins/workflows-core/references/escalation-rules.md`; `UP` `plugins/product-workflows/commands/update-prd.md`; `EP` `plugins/product-workflows/commands/epics.md`; `DOC` and `RN` `plugins/docs-workflows/commands/document.md` and `release-notes.md`; `RD` `plugins/dev-workflows/commands/ready.md`; `CRR` `plugins/product-workflows/agents/customer-review-reader.md`.

## Scope and decisions

Round 3 of the exclusivity probe (`docs/superpowers/verification/2026-09-23-exclusivity-probe-wider-vocabulary.md`, *Deferred by user decision*) deferred eleven decision-cycle defects to their own design pass, as an explicit exception to the zero-known-bugs rule. Tracing them found N1–N6; implementation and review found N7–N31. The spec fixes all 42. Its eleven back-pointers (one per deferred item) cite this file.

User decisions (spec §2, 2026-09-23):

| # | Question | Decision |
|---|---|---|
| D1 | (x) A corrected resend re-answers a question whose `[CD#n]` is `decided` | Skip if identical, otherwise supersede |
| D2 | (vii) A verifier `contradict`s an on-file finding | Supersede the on-file finding; an own-run finding keeps the in-place rewrite |
| D3 | (v) A `prd.md` with no `kind: prd` | Counts as found, plus a pre-write guard (revised by R50 and R52 into an archive before the run's first write) |
| D4 | "Session cost (ALWAYS runs)" in 23 command files | First "reword in this pass"; **revised the same day: dropped as not a defect** |
| D5 | Execution order | CLAUDE.md split first, then this pass; push both once known bugs = 0 |

**The D4 revision (Unit F dropped, commit `e21db9f5`).** Research had flagged "Session cost (ALWAYS runs)" as false because an abort or a *Cancel* stops a run before its cost step. Planning re-read it in context and found it scoped-true: the heading is step 3 of a command's terminal phase, it follows step 2 (feedback, which persists nothing where there is no plugin signal), and `workflows-core:cost-emission` §0 states the same contrast — "Unlike feedback … the cost phase always computes". "ALWAYS" contrasts cost with feedback inside that phase and says nothing about runs that never reach it; an aborted run skips feedback and cost alike. The user dropped the unit, and no file changed for it (spec §9). The same reason stops `iv`'s Phase 12 edit at the key-events list (spec A3).

## Defect table

Commits are found with `git log --oneline 2998b4df..HEAD` and confirmed per row with `git log --reverse --format=%h -S'<governing phrase>' 2998b4df..HEAD -- <file>`, which names the commit that introduced the phrase quoted in the last column. The first commit listed is the one that fixed the defect; the rest are the fix rounds that reshaped the same text, each ruling in brackets. Every row is FIXED.

### Unit A — `/brd-interview` lifecycle

| Id | Status | Commits | Where it now resolves (file:line, governing text) |
|---|---|---|---|
| ii | FIXED | `d0e63360`; `266c5841` (R24), `58dd41a1` (R26–R30), `d3ed8a8c` | BI:1629 Phase 7 *Hold every `[C]`*: "and it writes nothing either: it builds each entry and holds it for the *Write the register and the round record* phase". BI:1788 "**The round record is the commit point**"; DRF:547 §8 defines the **torn write** once. |
| N2 | FIXED | `d0e63360`, `d3ed8a8c` | `plugins/product-workflows/docs/commands/brd-interview.md`:356 "a `Cancel`, an abort or an interruption before Phase 9 writes nothing the run decided into the BRD folder"; BI:1754 "**`Cancel` writes nothing this run decided into the BRD folder**". |
| iii | FIXED | `64c7c3e0`; `d1f9bc87` (R31), `d44f201a` (R34, R35), `893356d1`, `2c31f6cb`, `017e1aa9` (R62, R63) | BI:1187 "**A decision reopened elsewhere is put again.**"; BI:1199 "this source takes **every `[VD#n]` and `[CD#n]` reading `status: reopened` that is not in flight**"; BI:598 "A record moved to `reopened` raises its question through *A decision reopened elsewhere*, and one moved to `superseded` raises nothing." |
| N1 | FIXED | `64c7c3e0`; `d44f201a` (R35), `017e1aa9` (R62) | BI:1885 "on every question that puts an existing record again, that record on a line of its own labelled exactly `- **Re-puts:** [VD#n]` or `- **Re-puts:** [CD#n]` … **and on every other `[V]` the same line reading `- **Re-puts:** none`**". |
| iv | FIXED | `d0e63360` | BI:2303 Phase 12 key events: "a re-opened round and its cause, a question that needed grounding, a will-change resolution, the torn writes an interrupted run left and this run removed, the no-new-round path". "a cancelled `[V]` queue" is gone from every file but `plugins/product-workflows/CHANGELOG.md`:27, which records its removal. |
| xii | FIXED | `c3c9a518`, `a0da3a1c`, `25aea2cd` | BI:556 "the anchor is the **earliest commit on any ref that holds the record exactly as it stands on disk**"; BI:559–561 `hash-object` and `git -C "$SPECS_PATH" log --all --date-order --format=%H`; docs page `brd-interview.md`:42 "the earliest commit on any ref, any branch included". |
| N3 | FIXED | `c3c9a518`, `a0da3a1c` | BI:609 on an observable test, `diff-tree --root -m --relative … <sha>` returning a path beginning `grounding/`: "add *compared at `<short-sha>`, a commit that may postdate the record's write*". R36 records the one undetectable residual, which the report line discloses. |
| N16 | FIXED | `58dd41a1` (R26) | BP:230 step 6 "Its presence on `origin/<default>` implies nothing about any other file this package ships, and each of those is gated in its own right"; BP:270 step 6b "**Gate the question set and the code-defect log on main, each where it is in the folder.**" |
| N31 | FIXED | `c51a138e` (R75); `41bbafce`, `c058be40` (R80) | BI:1047 "**One with a superseded finding no successor will come to is put again instead**"; BI:1056 the second case, "**the run that retired it re-ground its source**" … "carries the note `superseded: frame set <frame-set> re-ground`". |

### Unit B — `/brd-reconcile`

| Id | Status | Commits | Where it now resolves (file:line, governing text) |
|---|---|---|---|
| x | FIXED | `3c1db88d`; `74ac986c` (R37–R40), `8030212f` (R42–R45) | BR:930 "**A different review re-affirming a live answer freezes nothing, and the test runs on the row the operator confirmed.**"; BR:946 byte-equal reason "once every run of whitespace on either side is collapsed to one space"; BR:963 "it mints no `[CD#n]`, appends no *answered by the customer*, and adds nothing to the propagation sweep's changed-id set"; BR:1291 step 3 "the new answer **replaces** it — it answers the record's own question again, whatever it chooses → `superseded`". |
| N4 | FIXED | `3c1db88d` | BR:679 section-7 matching table: "the round record's entry for that question, whatever state it holds now"; CRR:155 "a `[C]` question by its round and position, whatever state its entry now holds". |
| N17 | FIXED | `74ac986c` (R37, R41), `8030212f` (R45) | BR:950 "the candidate's `chosen` equals the record's `chosen` and it states no reason at all. A missing reason is not a different reason". |
| N18 | FIXED | `74ac986c` (R38), `8030212f` | BR:981 "**A live record reading `withdrawn` takes no answer at all.**"; BR:1287 "the chain is followed to its successor". |
| N19 | FIXED | `74ac986c` (R39) | CRR:155 "an `[AS#n]`, whatever its status — the package put it while it was open, and a corrected resend answers it again after an earlier review settled it, which the caller resolves". |
| N20 | FIXED | `58e8b1e0` (R46), `4731bd60` (R48) | CRR:160 "where no `self_review` was supplied, every `[SR#n]` answer is `unmatched`, never matched against another package's file"; BR:598 "**The `Package reviewed: <BRD-KEY> <YYYYMMDD>` line**"; BR:895 "It resolves through the self-review file of the package this review answers". |
| N21 | FIXED | `58e8b1e0` (R47), `4731bd60` (R49) | BP:718 "**A finding escalated to the customer again carries a `- **Re-escalates:**` line**"; BR:901 "file carries a `- **Re-escalates:** <earlier self-review file> [SR#k]` line". |

### Unit C — grounding supersession

| Id | Status | Commits | Where it now resolves (file:line, governing text) |
|---|---|---|---|
| vii | FIXED | `4f83c048` (R14); `49924c09`, `6e40d3c4`, `7d20d350`, `34901d88`, `df0215d8` (R68, R72) | GF:808 "**What a `contradict` writes turns on whether the finding is already on file.**"; GF:815 "The caller supersedes it instead: the block takes `verdict: SUPERSEDED` with its on-file verdict as `prior_verdict`"; PG:1266 own-run and on-file findings defined, "**No finding is both**". |
| N10 | FIXED | `49924c09` | PG:1420 "`consumed_by` — `none` on a block this run appends, while a block already on file keeps the value it holds". |
| N11 | FIXED | `49924c09` (R16) | GF:822 "**On a `[DG#n]`, either write keeps every frame citation the replaced evidence carried beside the re-derived evidence**". |
| N12 | FIXED | `49924c09` (R15) | BI:966 "**any one of whose `evidence` findings reads `SUPERSEDED`**"; BI:969 "**Any, not every**". |
| N13 | FIXED | `6e40d3c4` (R17); `df0215d8` (R65, R66), `c51a138e` | PG:1558 "**A prior class-4 finding is among them only where this run re-ground its claim against the repository its cited `[CG#n]` is pinned to.**" … "**Or under `--no-code`**". |
| N14 | FIXED | `6e40d3c4` (R18), `7d20d350` (R21) | PG:1026 "**This phase never moves an on-file finding's `horizon` or `prerequisite` in place**". |
| N15 | FIXED | `6e40d3c4` (R19); `c51a138e`, `41bbafce` | BI:1051 "**it cannot be matched to one** — its own source cannot be decided …, so test 4 can pass nothing against it", one of the two cases BI:1047 puts again. |
| N30 | FIXED | `c51a138e` (R74) | PG:786 "**This phase writes nothing to that file.** A pin is recorded together with the findings it pins, in Phase 8, and never before them". |
| viii | FIXED | `5da33fc1` | PG:1420 Phase 8's field list: "`prerequisite` on every finding reading `horizon: will-change`". |

### Unit D — `/prd-ground` gates and `/brd-split` reconciliation

| Id | Status | Commits | Where it now resolves (file:line, governing text) |
|---|---|---|---|
| ix | FIXED | `5da33fc1`; `ccd49b3e` | PG:218 "**The two gates below resolve in a fixed order: the ledger's first, the inventory's second.**" … "Where both returns stop, the ledger's stop is the one printed, **with one exception**". |
| xi | FIXED | `5da33fc1` (R4), `6a744744` (R5–R7); `e0a82a11` | PG:364 `PRD_GROUND_CARVE_UNFINISHED: … the carve of <PARENT-KEY> is not finished`; BS:988 "stay provisional until a run of this command reaches Step 3 and reconciles them against this BRD's ledger, and `/product-workflows:prd-ground` refuses such a slice until then". The draft's "it resumes the walk" wording is withdrawn (R6). |
| N5 | FIXED | `5da33fc1` (R3), `6a744744` | PG:440 step 6a's three sets (a) `claims:`, (b) the inventory, (c) the parent's `covered-by: <BRD-KEY>` rows; PG:465 `PRD_GROUND_SLICE_UNRECONCILED: <BRD-KEY> is out of step with its parent`. |
| N7 | FIXED | `6a744744` (R5, R7) | BS:1131 "**The selector reaches every standing child**"; BS:392 "`unallocated_zero` **but at least one standing empty child or at least one child out of step** … → **the reconcile path, not a no-op**". |
| N8 | FIXED | `d099138d` (R11), `18852d25` (R12), `8a5709b4`, `aede7c80` | CLF:91 "no walk of the parent offers a child a `[BR#n]` it holds an orphan row for (§3.2)"; BS:1009 the ordinary walk's exclusion of a child "whose own `coverage-ledger.md` holds an orphan row for this `[BR#n]`". |
| N9 | FIXED | `ccd49b3e` | PG:282, `PRD_GROUND_NO_INVENTORY`'s remedy row "reached only through `require-on-main`'s row B above — the ledger on the default branch and missing from this working tree". The false "no command has committed this slice's folder" is no longer in that table; the phrase that remains (PG:334) is `PRD_GROUND_NEEDS_SPLIT`'s, where the carve stopped before its handoff and commit. |

### Unit E — `/create-prd`, `/update-prd`, `/epics` and the unplaced-folder stops

| Id | Status | Commits | Where it now resolves (file:line, governing text) |
|---|---|---|---|
| v | FIXED | `bca2f6ac` | CP:221 "**The test for "found" is presence: any file at `<feature-folder>/prd.md` counts as found, whatever its frontmatter**" … "**`kind:` does not decide presence here**". |
| N6 | FIXED | `bca2f6ac`; `9a63fe97` (R52) | CP:525 "**Pre-write archive — before this run's first write to `prd.md`.**" … "archive it first, **on every route, with no exemption**". |
| N22 | FIXED | `bca2f6ac` (R50); `9a63fe97` (R54), `4dd15b49`, `4c9bc959` | CP:534 "This is the archive Phase 1 step 2's Overwrite options name"; the three labels at CP:381–389 read "(archives the current one)". `CREATE_PRD_PRIOR_UNREADABLE` (CP:372) stops before any write. |
| N23 | FIXED | `9a63fe97` (R51), `4c9bc959` | UP:117 "use the first name not taken of that name with `-2`, `-3`, and so on inserted before `.md`". |
| N24 | FIXED | `9a63fe97` (R53), `4dd15b49` | UP:117 "**Archive the base before the first write.** Immediately before this run's first write to `<feature-folder>/prd.md`"; `UPDATE_PRD_ARCHIVE_FAILED` at UP:119. |
| N25 | FIXED | `0354f0c7` (R57) | RD:34 "`invalid` → stop with `READY_NEEDS_KEY` below"; RN:47 "`invalid` → stop with `RELEASE_NOTES_NEEDS_KEY` below". ER:177 now reads "Used when the address resolved to no folder"; the grammar-failure clause present at `2998b4df` is deleted. |
| N26 | FIXED | `eee743fe`; `fe4ae52c` | EP:265 "**Refuse a PRD that states no requirements**, once step 1b's table has accepted the run — so after the preflight … — and before Phase 1 asks anything". |
| N27 | FIXED | `74777342`; `fe4ae52c` | EP:47 "**Then settle the specs checkout, before step 1a or 1b reads anything.**" |
| N28 | FIXED | `74777342`; `fe4ae52c` | DOC:28–34 the run key set includes, on an Epic-level folder, "the key its parent's carrier asserts (§4), which is the `<PRD>` Mode A Phase 0 step 1 carries. Without it, §3.5 would resolve a `prd/<PRD-KEY>-…` branch to no key and switch away from it." |
| N29 | FIXED | `fe4ae52c` | EP:59 "1a. **Refuse a `BRD-` container**, right after step 1's specs-repo preflight and ahead of every other read this command makes." |
| vi | FIXED | `2e33f24d`; `0354f0c7` (R55, R56), `eee743fe`, `0c51ab01` | DOC:85, 106, 128 and RN:84, 105, 127: `*_BRD_NOT_SLICED`, `*_FOLDER_NOT_PLACED`, `*_NO_PRD`, each a named stop; `choices: ["Enter a slice key", "Cancel"]` at DOC:86 and RN:85. ER:179 "**A folder that is there is never this case, whatever it holds**". |

**Literal counts of the fixed spellings.** Refinement 7's wrap-insensitive count over refinement 4's scope (`plugins/` with every `CHANGELOG.md`, root `README.md`, `CLAUDE.md`, `.claude/rules/`, `docs/maintainers/`), the script in `global-constraints.md` § Tools reduced to its total, run on `git archive 2998b4df` and on `669eccfc`:

| String | At `2998b4df` | At `669eccfc` |
|---|---:|---:|
| `- **Re-puts:**` | 25 | 71 |
| `A decision reopened elsewhere` | 0 | 28 |
| `torn write` | 0 | 93 |
| `PRD_GROUND_CARVE_UNFINISHED` | 0 | 7 |
| `PRD_GROUND_SLICE_UNRECONCILED` | 0 | 16 |
| `PRD_GROUND_CLAIMS_INVENTORY_MISMATCH` | 0 | 0 (the draft's name, replaced by `PRD_GROUND_SLICE_UNRECONCILED` under R3 before it was written) |
| `DOCUMENT_BRD_NOT_SLICED` / `RELEASE_NOTES_BRD_NOT_SLICED` | 0 / 0 | 6 / 6 |
| `DOCUMENT_FOLDER_NOT_PLACED` / `RELEASE_NOTES_FOLDER_NOT_PLACED` | 0 / 0 | 5 / 5 |
| `DOCUMENT_NO_PRD` / `RELEASE_NOTES_NO_PRD` | 0 / 0 | 8 / 8 |
| `READY_NEEDS_KEY` / `RELEASE_NOTES_NEEDS_KEY` | 2 / 8 | 4 / 10 |
| `EPICS_PRD_NO_REQUIREMENTS` | 0 | 5 |
| `CREATE_PRD_PRIOR_UNREADABLE` | 0 | 5 |
| `UPDATE_PRD_BASE_UNREADABLE` / `UPDATE_PRD_ARCHIVE_FAILED` | 0 / 0 | 5 / 4 |
| `Re-escalates:**` | 0 | 8 |
| `Package reviewed` | 0 | 10 |
| ``a cancelled `[V]` queue`` | 1 | 1 (the `CHANGELOG.md` entry recording its removal) |
| `raises nothing by that move alone` | 3 | 1 (`plugins/product-workflows/CHANGELOG.md`:75, the 3.8.2 section, history) |

## Rulings

Every ruling the ledger records, in ledger order, with the ledger's own statement of its cost if wrong. R74 and R75 are recorded as `New N30 … → R74` and `New N31 … → R75` rather than as `Ruling` lines. **There is no R8**: the ledger goes from R7 to R9, and neither the spec nor the plan uses the number. "R51 extended" is a ledger line of its own. There is no unnumbered ruling. Where the ledger states no cost, the cell says so.

| Id | Decision | Cost if wrong |
|---|---|---|
| R1 | Task 9 steps 1–4 run before the final review; step 5 (this record) after its fix wave | one extra dispatch |
| R2 | Research files stay in the session scratchpad as finding aids; the spec is the authority | implementer re-derives scenarios from the spec |
| R3 | N5's gate becomes `PRD_GROUND_SLICE_UNRECONCILED`: `claims:` = inventory = parent's `covered-by:<SLICE>` rows, invariant proven first | a legitimate state stops `/prd-ground` |
| R4 | An unfinished carve gets its own cause-neutral stop `PRD_GROUND_CARVE_UNFINISHED` | one more stop name |
| R5 | N7: `/brd-split` Step 3 reconciles every standing child; a bare run on a fully-allocated parent is live where a child is out of step | Step 3 touches children with committed work; guarded by writing nothing where they agree |
| R6 | The draft's "resumes the walk" wording is withdrawn; spec §7 D2 rewritten | not stated |
| R7 | Step 3 also runs on the Phase 4.5-only path, ahead of 4.5; R5's live path drops its no-empty-child condition | Step 3 runs on a path it never did |
| R9 | Minors that are false or contradictory executed prose enter the fix loop | more fix-round churn |
| R10 | (superseded by R11) N8 via re-assignment turning an orphan row back into a claimed row | re-assignment semantics differ from the format's intent |
| R11 | N8: the ordinary walk does not offer a child a `[BR#n]` it holds any row for, and says why | an operator cannot give a row back to a child that gave it up |
| R12 | Narrows R11 to rows the child does not currently claim; third route swept; §6 counts via the parent's disposition | N8's case must still be caught |
| R13 | Fix round 4 resumes the same implementer: the loop is converging | one more round |
| R14 | Retire the unreachable on-file half of the class-4 sweep; move its reasoning onto Phase 8's cascade | reasoning a future path needs is lost |
| R15 | N12: a record is taken where **any** evidence finding is `SUPERSEDED`; per-finding confirmation | more reopen questions |
| R16 | N11: a `[DG#n]` rewrite or successor keeps the prior frame citations | evidence lists grow |
| R17 | N13: the frame-set rule retires a prior class-4 only where this run re-ground the pinned repository, or under `--no-code` | stale class-4 findings linger until the cascade |
| R18 | N14: a horizon or prerequisite move on an on-file finding is a supersession with an own-run successor | more supersessions and reopens |
| R19 | N15: a held record whose superseded finding's source cannot be decided is put again; no migration | an extra question on legacy trees |
| R20 | No damping for an unchanged divergence a re-run does not re-emit | extra reopen questions on grounder false negatives |
| R21 | An unplaceable on-file `[DG#n]` is superseded with no successor, its note naming the would-be horizon | an extra reopen on legacy findings |
| R22 | Keep Phase 6's class-4 copy citing the old `[CG#n]` (born `SUPERSEDED`) | class-4 findings retired until a `--no-code` run |
| R23 | Phase 9 write order with the round record last as the commit point (amended by R27) | a different torn-state shape |
| R24 | Torn write defined once in DRF §8; every reader cites it and ignores it; Phase 0 reports, Phase 9 removes | reader changes in BP and BR |
| R25 | `--round` appends and round-1 questions held until Phase 9; "only writer" scoped to a round's deliverables | none significant |
| R26 | N16: BP step 6 runs `require-on-main` per shipped file | extra gate calls |
| R27 | Order: log → register → questions → round record | an orphaned log entry (harmless: torn) |
| R28 | A baseline `code defects` / `requirement defects` line before new entries | an extra line per legacy round |
| R29 | A `[CDF#n]` re-disposition is a fifth write after the round record; Phase 0 re-applies it | delayed re-disposition on a crash |
| R30 | The no-new-round path's torn-write removal is accepted; it reports it | not stated |
| R31 | A legacy line-less re-put `[V]` is tied by an operator picker; Phase 9 writes the line; upgrade note | one extra question per legacy re-put |
| R32 | BR offers *Work another round* only when every round is closed | the operator waits for held `[C]` answers |
| R33 | (replaced by R34) One open round at a time | blocks a relied-on workflow |
| R34 | Only `--round <highest+1>` while a lower round holds an undisposed question stops | the operator finishes the lower round first |
| R35 | Every `[V]` carries a `Re-puts` line, `none` where it re-puts nothing; the picker fires only for line-less ones | one more line per question |
| R36 | A late-committed legacy record's anchor is an undetectable case, disclosed by the report line | a missed change on legacy last rounds, disclosed |
| R37 | N17: same `chosen` and no stated reason re-affirms (skip) | a silent reason change is not recorded (none was stated) |
| R38 | N18: a target resolves to its live record; `withdrawn` freezes nothing and goes to a human | an extra human-review item |
| R39 | N19: the reader's `[AS#n]` row describes, not filters; a superseded `[AS#n]` resolves to its successor | none significant |
| R40 | B1's skip extends to `[AS#n]` and `[SR#n]` targets | not stated |
| R41 | R37 also covers a live record reading `open` | an open record's missing-reason picker is skipped on identical no-reason resends |
| R42 | `[SR#n]` resolves through the answered package's self-review file; undeterminable → no skip | a redundant supersession |
| R43 | The skip runs only on a confirmed option mapping | an extra confirmation step |
| R44 | A candidate is skipped where its target's chain holds a record this same review froze, any status | none significant |
| R45 | An open-for-reason record is live: same + reason completes, same + none skips, different supersedes | none significant |
| R46 | N20: the reader gets the answered package's self-review; undeterminable → `[SR#n]` answers unmatched | more human-review items |
| R47 | N21: `/brd-package` writes a `Re-escalates` line; BR chains through it; legacy frozen fresh | a new structured line in self-review files |
| R48 | Undeterminable package → operator picks from dated prompts; the `Package reviewed` line is printed and required | one extra question |
| R49 | The `Re-escalates` line only on operator-confirmed sameness | one extra confirmation per re-escalation |
| R50 | N6/N22: archive on every route, `revisions/` naming, `-2`/`-3` on collision, failed copy stops | an extra archive on greenfield-over-keyless runs |
| R51 | N23: the first-free `-2`/`-3` rule for `/update-prd` | none |
| R51 extended | Suffix position, `revision_of` records the actual name, `proposal-format` takes the rule, registers updated | not stated |
| R52 | The archive is taken immediately before the run's first write to `prd.md`, once per run | none significant |
| R53 | N24: the same rule for `/update-prd` | not stated |
| R54 | An unreadable `prd.md` is a named stop at Phase 1 step 2; a failed copy is a named stop | not stated |
| R55 | `*_NO_PRD` moves to Phase 0 step 1 | none |
| R56 | `*_NO_PRD`'s remedy is qualified by the slice's ledger, mirroring `EPICS_NO_PRD` | none |
| R57 | N25: `/release-notes` and `/ready` stop on `status: invalid`; the orphan grammar clause is deleted | another stop name each |
| R58 | Address resolution reading the tree before the preflight is inherent, not a defect | none |
| R59 | Task 9's task review is folded into the final whole-branch review | CHANGELOG defects surface one stage later |
| R60 | The final review is split into three parallel area reviewers | cross-area defects at the A/B/C seams |
| R61 | One final fix wave, three area fixers in sequence (A → B → C), then scoped re-reviews | more dispatches |
| R62 | The `Re-puts` line is written whenever a question becomes `[V]`, at re-tag too | not stated |
| R63 | A reopened record reverted by a sweep while its re-put `[V]` is deferred is superseded by the answer | not stated |
| R64 | (revised by R70) Remove BR's false "drop / take it as `[V]`"; a withdrawn re-put entry is never re-packaged | not stated |
| R65 | "Re-ground the repository" is defined against a known set: the repositories this run produced code findings for | not stated |
| R66 | The frame-set rule fires for every frame set this run's design pass covered | not stated |
| R67 | Successor test 3 for a frame-only class-1 claim matches on the frame set (refined by R73, replaced for matching by R80) | not stated |
| R68 | A `contradict` lacking an owed `own_control` writes no outcome onto an on-file block; reported unverified | not stated |
| R69 | `/ready`, `/design`, `/implement`, `/create-ard`, `/specify`, `/update-prd` run the preflight before any refusal that reads the tree beyond resolution | not stated |
| R70 | A withdrawn re-put entry closes on the first review that answers it; BP renders only held entries | one customer question about a withdrawn record |
| R71 | `PRD_GROUND_NEEDS_SPLIT` made true; an unreconcilable child is never offered, taken or given | an operator restores a lost file by hand |
| R72 | An own-run `contradict` lacking an owed `own_control` stops with `PRD_GROUND_VERIFY_INCOMPLETE` | an extra stop |
| R73 | A frame-only successor must cite the same frames within the set | not stated |
| R74 | N30: the new pin is recorded only in Phase 8's write, with the findings it pins | not stated |
| R75 | N31: a held record on a retired divergence is put again, as R19 | not stated |
| R76 | A second final fix round runs despite the one-wave rule: zero known bugs outranks it | extra dispatches |
| R77 | `PRD_GROUND_CARVE_INTERRUPTED` only on an empty folder; a non-empty folder gets a restore remedy, never delete | not stated |
| R78 | (replaced by R80) Class-1 successor match undecidable where one frame carries more than one class-1 finding | not stated |
| R79 | `CLAUDE.md` and `specs-repo-git` state preflight placement "once the run's key set is known"; §3.5 gains the re-run/switch-back rule | not stated |
| R80 | `design-grounder` writes a field token in a frame-only class-1 claim; test 3 matches token + same frames; legacy tokenless findings take the safe direction | a one-time reopen on legacy class-1 decisions |
| R81 | `/release-notes` follows its siblings; `/prd-proposal` and `/brd-proposal` resolve, state their key set, then preflight; `/frames` preflights at the end of step 1 | none significant |

## Gate output

The full chain from `global-constraints.md` § Tools (the CI list, in order), run unpiped from the worktree root on the tree carrying this record, untracked, at `669eccfc`, its output captured to a file. Each gate's result line, in chain order, then the chain's last lines:

```
0 error(s), 0 warning(s) across 1 repo(s).
PASS: no dash-form requirement IDs under .
SELFTEST PASS
  check 9 cost-emitting-commands assertion not applicable: plugins/guideline-reviewers ships no docs/reference/session-cost.md
PASS: docs are consistent with the plugin(s) under plugins/dev-workflows plugins/guideline-reviewers plugins/workflows-core plugins/docs-workflows plugins/product-workflows
SELFTEST PASS
PASS: all 34 mermaid blocks in 416 tracked markdown files parse (mermaid 11.17.2, marked 16.4.2)
ok    a claim whose ceding run ships from a DIFFERENT plugin than the run replaying it matches (2000)
ok    ...and that replaying run keeps exactly its own 1000
SELFTEST PASS
EXIT=0
```

The first line is `validate-catalog.py` on Python 3.11. The mermaid count excludes this record, which is untracked and holds no diagram. Check 19 reads this record through `git ls-files -co`; check 13 and the id-grammar gate do not reach `docs/superpowers/`.

## Exclusivity probe over this branch's diff

**Method.** `git diff -U0 2998b4df..HEAD -- plugins/ CLAUDE.md .claude/rules/`, added lines only (3,558 lines, every `CHANGELOG.md` under `plugins/` included). Each hit is one form on one added line. A hit is marked **carried** where the collapsed text 25 characters either side of it is already in the same file at `2998b4df` — a line this branch rewrapped or re-edited around a claim it did not write — and **new** otherwise; every hit, carried or new, was re-read in its paragraph at `669eccfc`, since a carried claim can change meaning under new text around it. Three passes:

1. **Refinement 3's vocabulary**: `only when`, `is the only`, `nothing else`, `and no other`, `only ever`, `the only <noun>` (no preceding `is`), `the sole`, `only writer`, `only caller`, `only consumer`, `no other command`, `the one command`, `the only place`. **70 hits** (40 new, 30 carried). `the sole`, `only writer`, `only caller` and `only consumer` had none.
2. **Generalised from the claims' own wording**, per refinement 3: `no command`, `no other command`, `only command`, `any other command|run|reader|writer`, `the one writer|reader|place|deletion|exception|path|run|route|way|case`, `only path|route|reader|writer|place|way|exception`. **56 hits** (30 new, 26 carried).
3. **`never`, `every`, `always`, `all`**: 832 line-hits. Kept as tree-universal claims are the **27** whose 80-character window quantifies over the tree's own population — a command, reader, writer, consumer, caller, copy, plugin, agent, reference or stop (`every command`, `no command`, `every reader`, `by any rule of any run`, `the family`, and so on); 18 new, 9 carried. The other 805 quantify over what one run handles — rows, findings, records, questions, phases — and are run behaviour, which the task reviews and the final review read; they are not dispositioned here.

**Result: 153 hits, 0 DEFECT.** Four pass-2 hits repeat a pass-1 hit's text (the three `no other command` hits and GF:48's `only place`), so there are 149 distinct claims: 5 SCOPED-TRUE and 144 TRUE.

### SCOPED-TRUE hits

| Hit | Claim | Scope that makes it true |
|---|---|---|
| `plugins/product-workflows/CHANGELOG.md`:21 | "Phase 9 is now the only phase that writes a round's deliverables" | The phases of `/brd-interview` that decide something. The same bullet names the one earlier write, "the next run's Phase 0 completes one a stopped run left", a completion of a move a counted round record already names; `/brd-reconcile` writes the same files by its own rules (BI:1792). |
| BI:1777 | "This phase is the one writer of a round's deliverables in this command" | Scoped "in this command"; the same paragraph (BI:1787) names Phase 0's completion of a re-disposition as "the one earlier write … which decides nothing". |
| DRF:603 | "`commands/brd-interview.md` removes torn writes, and nothing else does" | The family's runs: the next sentence reads "That removal is the one deletion any run makes". BR:371 agrees ("removing a torn write is `/product-workflows:brd-interview`'s alone"). `BRD_PACKAGE_TORN_WRITES` (BP:223) tells an operator to delete them by hand on an all-delegated slice, which `/brd-interview` refuses; a hand edit is not a run. |
| DRF:560 | "every reader cites it and none restates it" | "Restates" is the definition, §8's per-item table. Readers carry a one-line gloss of the usual cause and read "through §8 there" for the test (CP:458, `create-ard.md`:407, `specify.md`:617, PG:818). |
| CP:221 (carried) | "the only canonical PRD name this plugin writes" | "Canonical": the same parenthetical excludes the archived copies under `revisions/` — this pass's pre-write archive included — which are "never read as a PRD". |

### TRUE hits that assert something about the tree

Each claim below quantifies over the tree, and was checked against it.

| Hit(s) | Claim | Evidence |
|---|---|---|
| `plugins/product-workflows/CHANGELOG.md`:21 (`every`, `never`) | Every reader of a torn write cites §8 and never counts one, followed by the list | `grep -rln -i 'torn write' plugins/*/commands plugins/*/agents` returns exactly the eleven listed: `brd-interview`, `brd-package`, `brd-reconcile`, `brd-split`, `prd-ground`, `create-prd`, `create-ard`, `specify`, `prd-proposal`, `brd-package-reviewer`, `proposal-reviewer`. The other files naming `decisions.md` count nothing in it (`brd-proposal` compares modification times; `update-prd` does not read it). `customer-review-reader` is covered through its caller, as the bullet says. |
| CDLF:21 | "Every reader, whichever route it reaches the log by, never counts an entry … §8 calls a torn write" | `grep -rln code-defect-log plugins/*/commands plugins/*/agents` returns BI, BP, BR, PG, `brd-proposal`, `brd-package-reviewer` and `proposal-reviewer`. Those that count entries cite §8. PG:293 and `brd-proposal`:414 name the log without reading it. |
| `plugins/product-workflows/CHANGELOG.md`:24 (`never`), BI:1131, BI:1430, BI:1911–1912 | Every reader ties a re-put to its record through the `- **Re-puts:**` line, never through prose | R35 puts the line on every `[V]` (BI:1888); a line-less `[V]` from a released version is tied by the operator's picker (R31, BI:1448), not parsed. |
| DRF:606, BI:1813, docs page `brd-interview.md`:366 | The torn-write removal is "the one deletion any run makes inside a register, a question set or a log it leaves standing" | BR:371 removes none; BP only reports; BS Phase 4.5 removes a whole child folder, which it does not leave standing; no other command deletes an entry in these files (`grep -n -i 'delet\|removes' plugins/product-workflows/commands/*.md`, filtered to register, entry and record lines). |
| GF:48 (`never`, `every`, `the only place`) | A `SUPERSEDED` finding "is never marked again, by any rule of any run" | PG:1031 (Phase 6), PG:1425 (`--rebaseline`), PG:1468 (the cascade), each "never on a block already reading `SUPERSEDED`"; Phase 7 dispatches no `SUPERSEDED` finding. |
| BS:3 (`only command`), docs page `brd-split.md`:240 | `/brd-split` is the one command that can remove or keep a standing empty child | Phase 4.5 of BS; `phase-handoff.md`:216 names a folder's removal by hand only. |
| docs page `brd-split.md`:241, PG:193 (carried) | `/brd-split` is the one command that writes a slice's claims | PG:193 "`/brd-split` is the only writer of a `brd-link.md` naming a `parent:` inside a `PRD-` folder; this command's own Phase 4 writes `depends-on:` into one but never introduces a `parent:`". No other command's body writes `brd-link.md`. |
| docs page `brd-split.md`:181 | the first two routes are "the only two that write `covered-by`" | CLF:91: the third route "never rewrites a disposition another run recorded". |
| BS:400 | The reconcile path is "the one path on which Step 3 and Phase 4.5 run without a walk in front of them" | BS:386–396: the no-op skips both; the ordinary and re-cut runs walk first. |
| BS:1239 | An unreconcilable child is "the only way this BRD's own row can still name a child this phase offers to remove" | BS:1131, Step 3 reconciles every other standing child. |
| BS:1171 | "The orphan rows it writes are only ever rows still `unallocated`" | Step 3 writes a disposition only onto an `unallocated` row; the finished withdrawal (BS:1137) and the third route leave the row as it stands. |
| docs page `prd-ground.md`:242 | `/brd-split` reconciles a slice's files "only when the walk completes" | Step 3 follows the walk, or on the reconcile path runs where no row is `unallocated` (BS:392); a mid-walk *Cancel* stops before it (BS:986). |
| PG:250 | "the only pass that leaves no ledger in the folder is `require-on-main`'s row B" | The row-B wording itself: on the default branch, missing from a reused branch's worktree; every other passing row reads the file in the folder. |
| PG:282, PG:283 (`never`), and carried PG:284, 334, 336, 337 | "No command re-creates the inventory" / "no command re-creates the rows it held" / "no command has committed this slice's folder" | BS's reconcile step "writes nothing into a slice with a file missing" (quoted in the same cells); PG:334's "no command has committed" is `PRD_GROUND_NEEDS_SPLIT`'s case — a carve stopped before its handoff and commit — and names a hand commit separately. |
| PG:787 (`never`, `every`) | A pin is recorded in Phase 8 "and never before them: every stop between here and Phase 8" leaves the old pin | PG:786 "This phase writes nothing to that file". |
| UP:70 | "This table is the only reason `/update-prd` ever opens a coverage ledger" | `grep -n coverage-ledger` over UP: only lines 46–70, this table and step 3a's use of it. |
| DRF:593 | The only shape in which §6 lets a `[VD#n]` stand `open` | DRF §6's resolution table: "Defer it until the prerequisite ships" is the only row recording `status: open`. |
| DRF:574 | "Nothing else is ever a torn write" | Definitional: closes §8's table. |
| DRF:654, DRF:77, CDLF:58, `plugins/product-workflows/CHANGELOG.md`:21 (`the one exception`) | A removed torn write is the one break in id contiguity and the one exception to never reusing an id | DRF:77, DRF:455 and CDLF:58 agree. |
| `plugins/dev-workflows/CHANGELOG.md`:14 (`the only`, `no command`) | The deleted grammar-failure clause "no command then uses" | ER at `2998b4df` carried the clause; at `669eccfc` it does not, and RD:34 and RN:47 route `invalid` to `*_NEEDS_KEY`. |
| `plugins/product-workflows/docs/commands/epics.md`:17 | "every refusal of a resolved folder below is taken after the specs-repo preflight" | EP:47 "before step 1a or 1b reads anything"; EP:265 the requirements test "after the preflight". |
| `CLAUDE.md`:126 (carried subject, text edited under R79) | "Every command that writes into `$SPECS_PATH` runs `specs-preflight` at run start, once its run key set is known" | `workflows-core:specs-repo-git` §3 and §7 item 1 (`669eccfc`); the area-C re-reviews of rounds 2–5 checked the command set against it (R79, R81, N-C5). |
| `plugins/product-workflows/CHANGELOG.md`:24 (`every`) | The new source "puts every `reopened` record whose question no round still holds unanswered" | BI:1199, the source takes "every `[VD#n]` and `[CD#n]` reading `status: reopened` that is not in flight". |
| RD:34, DOC:23, RN:47 (carried), EP:987 (carried), docs page `epics.md`:17 (carried, two forms) | An `EPIC-` folder comes from `/epics` "and from no other command"; an `EPIC-` folder with no `epic.md` is one "no command writes" | Unchanged by this pass; no command gained an `EPIC-` creator, and `/epics` writes `epic.md` with its folder. |
| `plugins/product-workflows/docs/reference/references.md`:13 (carried) | `/brd-reconcile` is the only command that mints `[CD#n]` | Unchanged by this pass; BI:1276 restates it ("this command only reopens one"). |

### TRUE hits that are local rules

These hits define a step's own test, output shape or branch condition, and are true by construction. Listed by file, with the form.

- **CHANGELOGs**: `plugins/product-workflows/CHANGELOG.md`:17 (`the only`: a lookup-order branch), :30 (`only when`: the base defect N12 described), :37 (`no command`: the false base phrase N9 fixed, quoted as history); `plugins/docs-workflows/CHANGELOG.md`:18 (`no command`: the stop's shape); `plugins/workflows-core/CHANGELOG.md`:16 (`never`: history), :22 (`no command`: history).
- **BI**: 396 (carried), 677 ("Nothing else here forbids two open rounds": R34's stop is the one prohibition, and the deliberate concurrency is named), 920, 1075, 1212, 1276, 1808, 1849.
- **BR**: 603, 2111 and docs page `brd-reconcile.md`:236 ("the only package on file": a branch condition); 736 and 991 (Reject's one exception, consistent with each other); 1237 and docs page :380 (carried); 2114 (R42, R46); 2181 (carried, two forms); docs page :165 (carried).
- **BS**: 360, 1099 (carried), 1137, 1283 (three forms: "not the only path" and "the only durable record"), 1337 (two forms, one carried), 1376 (three forms, carried), 385 and 1014 (carried), the description's "the one case" and "the only grouping signal" (carried); docs page `brd-split.md`:169 (carried).
- **"Reports zero delegated only when its parent withdrew none of its claims"**, carried in BI:2389, BP:1732, BR:2614, BS:1592 and PG:1966: §6.1 counts through the parent's current disposition (R12), so the five copies agree.
- **PG**: 186, 1147, 1287, 1349 (carried), 1423 (carried: §2.1's closed field set), 1495 (carried); docs page `prd-ground.md`:208 (the gate order's one exception, PG:222).
- **Named stop shapes** ("name no command" where the ledger cannot be read or no row is `covered-here`): DOC:124, 150; RN:123, 149; docs pages `document.md`:18 and `release-notes.md`:66; EP:211; `idea.md`:78; `prd-proposal.md`:200; UP:61; docs pages `epics.md`:19, `idea.md`:134, `update-prd.md`:52 and :78 (carried).
- **Other files**: `brd-package-reviewer.md`:178 (output format); BP:1053 (carried); UP:33 and docs page `update-prd.md`:42 (carried: "the only current copy"); CLF:259 (carried) and CLF:641; DRF:590; `plugins/workflows-core/commands/frames.md`:71; GF:827 (§2.2); `phase-handoff.md`:216 and :295 (carried); `.claude/rules/release-notes.md`:31 (carried); `plugins/docs-workflows/docs/commands/release-notes.md`:66 (carried: a retired flag's history); docs page `brd-workflow.md`:191 ("is not the only run", a negative).

## Release summary

Versions per spec §10, re-read from each `plugin.json` and `.claude-plugin/marketplace.json` (`validate-catalog.py` asserts that they agree):

| Plugin | At `2998b4df` | At `669eccfc` | CHANGELOG section |
|---|---|---|---|
| `workflows-core` | 1.7.6 (unpublished) | 1.7.6 | `## [1.7.6] — 2026-09-23`, extended in place, 14 lines added: `grounding-format` supersession (vii), pin timing (R74) and the class-1 claim form (R80); `phase-handoff` §3.4 and §4.0 rows (xi, N7, N16); the `addressing` `revisions/` register (N22); `escalation-rules`' re-scope (vi, N25); `specs-repo-git` preflight placement (R69, R79); `/frames` (R81); `next-phase-offer` (R32) |
| `product-workflows` | 3.8.2 | 3.8.3 | `## [3.8.3] — 2026-09-24` (Units A–E) |
| `docs-workflows` | 1.3.3 | 1.3.4 | `## [1.3.4] — 2026-09-24` (vi, N25, N28, R81) |
| `dev-workflows` | 4.2.3 | 4.2.4 | `## [4.2.4] — 2026-09-24` (N25's `/ready` stop, N-C5's `/vuln` key set, R69's preflight order) |

Every section is dated, so check 18 has nothing to fire on. No plugin description changed. The push carries the CLAUDE.md split (`2998b4df`) and this pass together (spec D5).

After the push, on each machine, update the four plugins this pass changed, then restart:

```bash
claude plugin update workflows-core@ihudak-plugins
claude plugin update product-workflows@ihudak-plugins
claude plugin update docs-workflows@ihudak-plugins
claude plugin update dev-workflows@ihudak-plugins
```

Known bugs: 0

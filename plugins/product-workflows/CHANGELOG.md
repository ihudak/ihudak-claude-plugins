# Changelog

All notable changes to the **product-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [3.3.2] — 2026-09-08

### Removed

- **`/create-prd` no longer captures `relevant_for_release_notes`**, and no longer asks to confirm a `no`.
  It asked a question with one answer — every PRD is relevant for release notes — so the only value it
  could carry that changed anything was one nobody should write.

## [3.3.1] — 2026-09-08

### Fixed

- **`/create-ard` and `/specify` no longer fall back to a key-globbed PRD filename at the `require-on-main`
  gate.** The fallback matched nothing on a current tree, and on the pre-rename tree it was written for it
  also matched that tree's ARD (`<KEY>_ARD.md`), so the PRD gate could gate the wrong artifact. Both now
  gate `prd.md`, the only name the plugin writes — correct on a current tree, and `absent` on a pre-rename
  one, which is what `workflows-core:addressing` §5 now tells that operator to fix.
- **`/create-prd` step 6 no longer claims a pre-rename `<KEY>_<slug>.md` is identified by `kind: prd`.**
  That field arrived in the same change as the rename, so no pre-rename file can carry it and the branch
  could never recognise the file it had found.

## [3.3.0] — 2026-09-08

### Added — `code-defect-log.md`, a route-local register for what `/prd-ground` finds broken in the code

`/prd-ground` spends its whole effort reading code at pinned commits, and routinely establishes that the code is broken — an active regression, a missing index the code assumes, a write path that never sets a column — and the route had nowhere to put that. `references/brd-format.md` §4's `[DEF#n]` log is for **requirement** defects only, so the fact landed in a decision's `argumentation`, and two instances in one shipped register asserted a defect *"is recorded"* while nothing held one, surviving drafting, the round record, and a first adversarial review.

The new `references/code-defect-log-format.md` fixes the `[CDF#n]` record: `id`, `statement`, `behaviour` (exactly one **verified** `[CG#n]` in this BRD's own `grounding/code-grounding.md`), `intent`, `intent_basis` (a `file:line`/document pointer, or the literal `operator-judgment` followed by the reasoning), `disposition`, and `blocked_on` (required only when `disposition: conditional`). Five dispositions, mirroring `decision-register-format` §3: `open`, `in-scope`, `out-of-scope`, `conditional`, `withdrawn`. **There is no `fixed` disposition** — nothing on the BRD-to-PRD route builds anything and no command can observe a repair; `withdrawn` means the intent basis turned out to be wrong, not that the bug got fixed, and using it for a repaired defect would put a false statement in the log.

`/brd-interview` is the **only** writer, at two points that already exist — Phase 6 raises an entry, held for the register phase exactly as a `[VD#n]` is; Phase 9 writes `code-defect-log.md` alongside `decisions.md` and the round record; Phase 10 adds the path to `deliverable_paths`. `/prd-ground`, which does the actual code reading, is deliberately **not** a writer, for a cost reason rather than a preference: its Phase 7 verifies every finding through `grounding-verifier`, and a defect entry emitted there would need its own verification contract and a change to the `code-grounder` agent; an entry raised at interview time cites a finding that is already verified and adds only the intent basis, which is the operator's judgment either way.

### Added — `defects:`, a twelfth field on the decision register

`decision-register-format.md` §1 gains `defects:`, listing the `[CDF#n]` ids a `[VD#n]`, `[CD#n]` or `[AS#n]` turns on, omitted when absent. It is deliberately **not** `evidence`: §6's will-change rule inspects the `evidence` list alone, firing when every finding in it carries `horizon: will-change`, and a `[CDF#n]` mixed into that list would silently change what the rule fires on. §7's per-field accounting grows from eleven rows to twelve to match, so a twelfth field is never one an author has to settle for themselves.

### Added — the log ships in the customer bundle

`bundle-packaging.md` §1.1's allow-list gains `code-defect-log.md`, and three dispositions map onto three prompt parts that already exist — `in-scope` to part 6 *Review scope*, because a defect disposed `in-scope` **is** the delivery boundary: the repair has to happen inside this PRD's scope or the feature cannot be delivered; `conditional` to part 8 *What could still move*, beside the `conditional_on` positions that part already carries; `out-of-scope` to part 11 *What this session cannot settle*. Shipping it also buys §3's evidence rule a mechanical check for free: `behaviour: [CG#12]` now sits in a bundle document, so it resolves against the partition's own shipped `grounding/code-grounding.md`, and an entry citing a finding that does not exist stops the packaging run with `BRD_PACKAGE_DEAD_CITATION`. Every entry ships, including `out-of-scope` and `withdrawn` ones — but seeing is not deciding: the operator settles every disposition exactly as before, a code defect never becomes an `interview-tagging.md` `[V]` or `[C]` question, and a customer who disagrees with one pushes back through the returned review, which `/brd-reconcile` already reads.

### Added — `brd-package-reviewer`'s sixth hunt class

Class 6, *"an argumentation that asserts a defect nothing holds"*: for every `[VD#n]`, `[CD#n]` and `[AS#n]`, the reviewer reads `argumentation` for a claim that a code defect is recorded, raised, or known, and checks the record's own `defects` list — a claim with nothing behind it is a finding. This is the class that catches the exact failure the design started from. It stands in for the prose-trigger check the design's §8 considered and **deliberately did not build**: the tree carries no corpus of real registers to measure a phrase-matching check against — the two `argumentation:` examples in the whole tree are both illustrative, both inside `decision-register-format.md` itself — so an unmeasurable pattern was left to the reviewer's judgment instead of shipped as a static check. What did ship at write time is a structural offer rather than a pattern: `/brd-interview` Phase 6 offers to raise a `[CDF#n]` exactly when a decision's `evidence` holds a `REWRITTEN`, `AMENDED` or `FALSE-FRIEND` finding — the three verdicts meaning grounding found the code does something other than claimed — reading the trigger off the record rather than out of prose.

## [3.2.0] — 2026-09-08

### Fixed — the package told every reviewer to extract an archive, including the ones who pull the repository

`bundle-packaging.md` §5 has always said the committed bundle serves **both** delivery routes — a customer with repository access pulls it, everyone else gets an archive command. Nothing recorded which route a given package was taking, so every other site assumed the archive — across the command, the reference and the documentation. Two of them were not statements about delivery at all but *justifications* that happened to name an attachment: rule 4's argument for filenames over paths, and the delivery note's 200-word ceiling. Both rules are right on either route; only their reasons were half-stated, and rule 4's mattered — naming only the archive case read as though a committed bundle could safely be addressed by path, which is the one reading that breaks rule 1 for the route now recommended.

The sharpest was in the customer's own prompt. Part 1's input table listed *the archive command* among what the prompt is filled from, and its OS note opened *"extract the archive to a real folder before pointing anything at it"* — so a customer who pulled the specs repository received a shell command for an archive nobody sent them, and an instruction naming a file they did not have, in the one document whose entire job is to be followable by somebody with no context and no plugin. That is the failure the de-Obsidianising pass exists to prevent — an instruction that looks actionable, is not, and gives the reader no way to tell which — reached by a different route.

**The prompt now names no delivery route at all, and the delivery note names the actual one.** The two have different readers, and that is what settles which may assume anything. The note is a covering letter to a named customer whose situation the operator knows; the prompt is handed on — to a colleague, to an agent, to whoever actually does the review — so a prompt that names a route is wrong for some of its readers about the first thing it tells them. The archive command is gone from the prompt entirely: assembling an archive is a delivery-team action, and a reviewer who was sent one has already had it done for them.

**The route is settled once, at the delivery note, and half of it is derived rather than asked.** The repository route exists only where the *Handoff* phase's consent choice was accepted — a bundle on no ref is a bundle nobody can pull — so where the handoff was declined the run takes the archive route without asking and says why. Where it was accepted the run asks, recommending the repository route. On that route no archive command is produced, and the note carries the repository, the committed `bundle-<YYYYMMDD>/` directory by path, and the instruction to open the prompt there and paste it.

**One constraint that survives the change and is worth stating, because it looks like an inconsistency:** even on the repository route the *prompt* must not name the specs-repo path. `bundle-packaging.md`'s own rule 1 holds that a path is correct exactly once, in the directory layout one machine had — so the note carries the path and the prompt carries filename search. The note tells the reviewer where to stand; the prompt works once they are standing there.

The Final report now names the route and why, on both branches, so a reader cannot mistake an absent archive command for a step that failed.

## [3.1.0] — 2026-09-08

### Added — `bundle-packaging.md` §6, a citation-resolution check over the assembled bundle

The plugin-free scan (§1) deliberately exempts identifiers — `[BR#n]`, `[CG#n]`, `[DG#n]`,
`[VD#n]`, `[AS#n]` and `[SR#n]` are how a returned review cites the package's own claims without
minting identifiers of its own — but nothing then checked that they land. `/brd-package` Phase 8
now runs a second pass over every document in the finished bundle, testing three relations: every
identifier reference resolves inside its own source package's corpus for its class, unless it
carries the owning BRD key at the point of use — in the prose form `<BRD-KEY> [CG#7]`, or inside a
structured field whose format another authority fixes and which that authority defines to name
another BRD's record, such as the register's own `conditional_on: <BRD-KEY>/<decision-id>`; those
fields are derived from the authorities that own them, not listed in §6, and the check reads them
rather than refusing them; a class-4 `[DG#n]`'s `cites` resolves within the
same partition and names the same requirement as the citing finding's own `claim` (the correctness
half of `workflows-core:grounding-format` §6.3's rule, added there in 1.3.2); and a bare
`<name>.md` token names a document actually present in the bundle.

Two exemptions, both principled rather than convenient. `[SR#n]` is exempt entirely — the
self-review file it would resolve against is excluded from the bundle by rule, and the `[SR#n]`
content a customer may see reaches them filtered through the prompt, never through the file
itself, so without this exemption the check would fire on every package the command ever builds.
And a hit inside the customer's own source document reports rather than stops, for the identical
reason the plugin-free scan already treats that file that way: it is copied byte for byte and
immutable by rule, so a hard stop would make that BRD permanently unpackageable.

Three stops: `BRD_PACKAGE_DEAD_CITATION` for a reference that resolves to nothing;
`BRD_PACKAGE_CITATION_MISMATCH` for one that resolves, but to a finding about the wrong
requirement; and `BRD_PACKAGE_CORPUS_UNREADABLE` for a corpus file that holds record-shaped
content and still parses to zero ids of its class, so a parse failure is never reported as an
absence. A corpus holding no record-shaped content is a legitimately **empty** corpus and passes —
a `design-grounding.md` written as a short note because design grounding was skipped, and a defect
log whose walk confirmed nothing, are both ordinary and neither is a parse failure.

**The honest consequence: relation 2 will refuse bundles that ship today.** A parent BRD's
verified findings, hand-narrowed onto a slice, is common enough that the first run against an
existing slice may stop on a mismatched `[CG#n]` citation. The repair is by hand, because the
plugin has no supported mechanism for narrowing a parent's findings to a slice's claimed subset —
that gap is a separate, already-tracked item, and this check catches a broken citation regardless
of how it got there, which is the point of checking at delivery rather than at authoring.

**One limit the design accepted.** An unkeyed bundle document — one that reached the bundle
without the `<BRD-KEY>`-carrying filename `commands/brd-package.md` rule 1 requires — is reported
rather than guessed at: §6 has no partition to place it in, so it names the document and stops
with `BRD_PACKAGE_DEAD_CITATION` rather than assigning it to a corpus by inference.

This is a minor bump, not a patch: the check can refuse a bundle a 3.0.0 run would have shipped,
which is a behaviour change a user will meet.

## [3.0.0] — 2026-09-08

### Changed (breaking) — `/brd-ground` renamed to `/prd-ground`

Every fully-qualified invocation, docs page, and cross-plugin citation must use
`/product-workflows:prd-ground`; `/brd-ground` no longer exists. The rename is taken now because
nothing has published — `product-workflows` does not exist on `origin/main` at all — so it costs
installed users nothing extra, and after a release it would have been a breaking change against a
name people had learned. It is called out as breaking anyway: a removed command name is breaking
however unpublished the plugin is, and the version is the one place a reader looks to find out.

**The rule that bounds it, so a future reader does not rename three more commands on the slice
argument.** `brd-` names the **route**, not the folder kind. Four of the six route commands refuse a
root — `/prd-ground` (`PRD_GROUND_ROOT_LEVEL`), `/brd-interview`, `/brd-package` and
`/brd-reconcile`, each with its own `*_ROOT_LEVEL` stop — so "runs on a slice" is the wrong test for
which one renames: `/brd-intake` and `/brd-split` are route commands that genuinely run at root, and
interviewing, packaging and reconciling exist only because a customer handed over a BRD — the slice
they run on is a slice *of* one, and none of them will ever run anywhere else. `/prd-ground` is the
only one of the six that **leaves the route**: after this release it runs on an idea-route PRD folder
with no BRD anywhere in its ancestry, where `brd-` was not merely imprecise but false. That is what
earns it the new name, and nothing else in the six-command route is touched — `code-grounder`,
`design-grounder`, `grounding-verifier`, `grounding/`, `code-grounding.md`, `design-grounding.md`,
`baselines.md`, `brd-link.md`, `coverage-ledger.md`, `slices.md`, `brd/` and `brd-reader` all keep
their names, the first six because they were already route-neutral and the rest because they *are*
BRD-route artifacts.

### Added — `/prd-ground` now serves the idea route too, optionally and ungated

Idea-route grounding runs after `/create-prd`, once merged, on the same PRD folder — never on a
root, and never on a resolved `EPIC-` folder (`PRD_GROUND_EPIC_LEVEL`, new). The route is detected
from the resolved folder, never declared: a `PRD-` folder carrying `brd-link.md` is still the BRD
route; a `PRD-` folder without one is the idea route. The claim list is built from the PRD's own
`[AC#n]` and `[FR#n]` rows, plus a `[US#n]` whose story carries neither — `[UC#n]`, `[SM#n]` and
`[SMC#n]` are excluded, and the run reports the count and the excluded prefixes both before the repo
prompt and in the Final report, so a clean run is never read as a fully-ground PRD. A PRD with no
resulting claim stops with `PRD_GROUND_NO_CLAIMS`, naming `/update-prd` as the fix and never
`/create-prd`, which would rewrite the PRD rather than add acceptance criteria to it. `--depends-on`
is refused outright on this route (`PRD_GROUND_NO_PREREQUISITES`): a `will-change` horizon needs a
decision register to freeze a prerequisite's decision in, and the idea route has none, so every
finding on it is `current`. Five new stops altogether: `PRD_GROUND_EPIC_LEVEL`,
`PRD_GROUND_NEEDS_PRD`, `PRD_GROUND_PRD_NOT_HANDED_OFF`, `PRD_GROUND_NO_CLAIMS`, and
`PRD_GROUND_NO_PREREQUISITES`. The branch prefix on this route is `prd/`, shared with `/create-prd`
and `/update-prd`; the next-step offer names `/create-ard` and `/specify`, with `/update-prd` named
first, marked `(Recommended)`, wherever a claim came back `SUPPORTED`. Grounding stays optional here
and nothing gates on it — the run's own Final report says outright when every claim came back a
verified absence, so a PRD that is greenfield against the resolved repositories reads as one finding
rather than a wall of absences, and a second run over the same folder is exactly what that headline
exists to make unnecessary.

### Added — design grounding ships on the idea route in the same release

A class 1, 2 or 3 `[DG#n]` is settled from the frame set and the requirement text alone; a class 4
cites a `[CG#n]` and inherits its commit. The frames are `/idea`'s own source images, vendored into
`design/idea-sources/` with their mandatory index — a class-1 finding here reads *this mockup shows a
screen no `[AC#n]` asks for*, a reconciliation available before `/create-ard` and on no other route.
A folder with no `design/` at all is the common case, and `grounding/design-grounding.md` is still
written on every run, carrying the `## Frame sets covered` census — absent always means the file is
not there, never that the pass was declined.

### Changed — `/create-ard` and `/specify` read grounding wherever the resolved folder holds it, and seed their scans from it

Both commands already knew how to read `grounding/code-grounding.md` and `grounding/design-grounding.md`
and to stamp `consumed_by` back onto what they drew on — that reading was gated on `brd-link.md`
being present. The gate is gone: wherever the resolved folder holds either file, on either route, its
findings are read, stamped `consumed_by: ARD` or `consumed_by: specification`, and — new in this
release — used to **seed** each command's own theme extraction before it falls back to the
PRD/Epic-derived themes it always used. A `[CG#n]`/`[DG#n]` whose verdict says a capability is absent
is a theme worth scanning; one whose verdict says it is present names the code that already
implements it, directing the scan at it instead of searching blind. Neither command's own
`code-scanner` fan-out is replaced, made conditional, or put behind a flag — the two answer different
questions, and a folder with no grounding derives its themes exactly as before this release.

### Added — `/update-prd` reads grounding and gives `consumed_by: PRD` its first writer onto a grounding finding

`/update-prd` now discovers `grounding/code-grounding.md` and `grounding/design-grounding.md` in the
resolved folder (all optional, read-only, never gating — the same posture as its existing `ard.md`
and `specification.md` reads) and carries their findings into the grill with the same **grill-rank**
consumption the documentation digest already uses. Where it draws on a finding to change the PRD, it
sets `consumed_by: PRD` on that finding — the same write `/create-ard` and `/specify` already make at
their own altitudes. This is the **first time `PRD` has been written onto a grounding finding
record**: `/create-prd` already writes `consumed_by: PRD`, but only onto a `decisions.md` decision
record on the BRD route, never inside a grounding file, since it reads no `grounding/` file on either
route.

## [2.2.0] — 2026-09-07

### Fixed — `/brd-ground` never checked a verifier's outcome against the verdict it re-derived

Phase 7 now reconciles the two before acting on either. `grounding-verifier` returns `own_verdict` on every outcome, and an `agree` or `extend` carrying a verdict that differs from the finding's is a return contradicting itself — the outcome is normalised to `contradict`, the finding is rewritten to the re-derivation as that branch already does, and the normalisation is recorded and reported in the Final report's verifier tally, with an explicit "none" where nothing was normalised so a clean run reads as checked rather than as unchecked. `unprovable` is never normalised.

### Fixed — Phase 8 could write the verifier's return fields into the finding record

Phase 8 now writes §2's fields plus `outcome` and `notes` **and nothing else**, per `workflows-core:grounding-format` §2.1's newly-closed field set. `own_verdict`, `own_evidence` and the verifier's re-derivation `commit` are return fields Phase 7 has already acted on; a block carrying `own_verdict` beside `verdict` states two verdicts at once and every downstream reader is free to quote whichever half suits.

### Added — `/brd-split` and `/brd-interview` refuse a malformed finding block

A fourth test in `/brd-split` Phase 0 step 7 (`BRD_SPLIT_MALFORMED_FINDING`) and a third in `/brd-interview` Phase 0 step 7 (`BRD_INTERVIEW_MALFORMED_FINDING`): every `[CG#n]`/`[DG#n]` block's keys are tested against the closed field set, and any other key stops the run naming the finding, the key, and the hand repair. **The existing outcome test cannot see this** — such a block carries an `outcome`, so it passes on presence while the disagreement travels into a slice's allocation, or into a `[VD#n]` frozen against whichever half the run read and then put in front of a customer. That is the same "a relation testing a property of what exists cannot catch what should not exist" shape as BRD-1, and the reason this is a relation of its own rather than a stricter count.

The stop names the hand edit rather than `--rebaseline`, which would re-derive an entire verified corpus to delete a line no command should have written. `/brd-package` gains nothing: it has no findings gate at all, and a `--rebaseline` that moves the findings forces a new interview round through the check above.

## [2.1.0] — 2026-09-07

### Added — the sibling re-cut: a slice may hand a row it has refused to build to a sibling

Slice-first grounding carves a slice before it is ground, so *"this slice is larger than one deliverable"* is a normal discovery. The route's only answer was deferral: the slice's own walk sent the rows it would not build to `deferred-to: <itself>`, where they stayed its live obligation. That was enough for *build less now* and not enough for *two independently deliverable slices*, because the blocker sat on the **parent** — its row for the delegated requirement read `covered-by: <that slice>`, `/brd-split` walked only `unallocated` rows, and no command returns a row to `unallocated`. A future sibling could never claim it.

`/brd-split` on a fully-allocated **root** carrying an `<instruction>` now performs the re-cut. Phase 0 step 9a builds a **re-cut candidate set** — every `[BR#n]` whose row on this ledger reads `covered-by: <A>` while A's own ledger reads `deferred-to: <A>`, two ledgers already agreeing that nobody is building it — and computes the eligible receivers; step 10 tests that set **before** the no-op, so a run that can move a row is no longer swallowed by the no-op it otherwise looks identical to. Phase 1.5 reads the instruction over that set instead of over an empty unallocated one, Phase 2 proposes groups and **fixes a receiver per group**, and Phase 4's new **Step 2R** offers each move one row at a time — showing the donor, both dispositions quoted from the two ledgers, the receiver, and every decision in the donor's register whose evidence touches the row. Accepting writes `covered-by: <B-KEY>` on the parent's row and then on the donor's, in that order. Phase 4's bulk offer gained a third firing condition for the uniform case; Step 3's reconcile widened its input set so the donor's claim and copied inventory row are withdrawn and the receiver's three files are written; Phase 4.5 now recomputes emptiness *after* the walk and repairs any `covered-by` key left pointing at a folder it removes; and `slices.md` gained a re-cut block and a removal block, because the ledger records neither.

**The precondition is the design, not a guard on it.** `deferred-to: <A>` is A stating in its own ledger that it is not building this, so the parent re-points against a refusal the row's owner wrote down and never over a live commitment. A row A still intends to build reads `covered-here` and cannot be moved. The receiver must be a sibling under the same parent that has **not been interviewed** — no `decisions.md` holding a `[VD#n]` or `[CD#n]`, no `interview/round-*.md` — because a register that exists and holds decisions is closed to added scope; a slice the run carves itself qualifies by construction. Nothing travels with the row: the donor's findings and decisions stay where they are and are never edited, and the receiver re-derives against the same pins, since a finding carried in from an earlier run is unverified by definition.

**What this does not relax.** No row returns to `unallocated` — every write replaces one terminal disposition with another — so the allocation gate is never reopened, and a receiver removed later takes the row to `deferred-to: <PARENT-KEY>` rather than back to the donor or back to `unallocated`. The one-level nesting cap is untouched: a re-cut carves a **sibling**, never a child. What relaxes is only the weaker rule that `/brd-split` never re-allocates a row already carrying a fate, and it relaxes against the owner's own recorded refusal and against nothing else. `references/coverage-ledger-format.md` §3.2 is the authority for all of it.

**Minor version, not a major one.** Nothing that worked before stops working. There is no new flag and no new argument: the re-cut reuses the `<instruction>` the route already made mandatory for carving a root, on the one run where it was otherwise free — and on that exact run the previous behaviour was to parse it, discard it and report it unused, naming the path that swallowed it. A bare `/brd-split <PARENT-KEY>` on a fully-allocated parent is still the same no-op; the ordinary walk, the `allocate-only` walk, the four resolutions at each level and every existing stop are unchanged. The one behaviour a user could have depended on — that an instruction there did nothing — is one nobody could have depended on for anything.

**A stop was designed for this and then retired, which a reader tracking the design will look for.** `BRD_SPLIT_RECUT_NO_RECEIVER` was to fire where a non-empty candidate set met no receiver. It does not exist and no code path reaches it: Phase 3 can always key a new slice, so the state in which nothing could *ever* receive a row is unreachable — and the state that *is* reachable, every proposed target declined with no eligible child standing, is an operator's answer rather than an error. This route already refuses to call one a failure. Step 2R simply has nothing to offer, every candidate is reported left with its donor, and the run finishes normally.

## [2.0.0] — 2026-09-07

### Changed — grounding, the interview, packaging and reconciliation move to the slice; a root now refuses all four

`/brd-ground`, `/brd-interview`, `/brd-package` and `/brd-reconcile` used to accept a BRD key at either level. They now refuse a resolved root outright, in Phase 0 before any other gate — `BRD_GROUND_ROOT_LEVEL`, `BRD_INTERVIEW_ROOT_LEVEL`, `BRD_PACKAGE_ROOT_LEVEL`, `BRD_RECONCILE_ROOT_LEVEL` — each naming `/brd-split <BRD-KEY> "<how to cut it>"` as the remedy.

**This breaks the route for anyone running it at root level.** The six `/brd-*` commands carried this two-level model since they shipped in `dev-workflows` at `v3.24.1`, an ancestor of this release, so the model has been in users' hands the whole time the route has existed; a run that worked against a root in 1.1.0 now stops at the first gate. The design's decision was to refuse and detect rather than offer a compatibility path: where root-level grounding, decisions, interview records, package artifacts or a reconciliation record already exist from the earlier model, the refusal names their exact paths and says plainly that they are **left in place and read by nothing** — nothing migrates them and nothing deletes them.

**Major version, not another minor one.** `product-workflows` 1.0.0 and 1.1.0 both shipped this route as an installable plugin someone could pin against, unlike an internal step of a multi-part split — so unlike a case where no intermediate version was ever separately consumed, a run that worked against a root in either of those versions is exactly what this stops. Semver's own contract is that an incompatible change is a major version, not a minor one carrying a bold warning in its own prose; `2.0.0` is the number that tells an installer what this entry would otherwise have to say by hand.

Twelve documentation files, including both of the route's mermaid diagrams, were brought into line with the same fact, and the level-conditional branches only a refused root could still reach — "at either level," offers that fanned a root out into its slices, a next-step offer recommending a command that would now refuse the key it was handed — were removed rather than left as dead prose a future reader would have to re-verify is dead.

### Changed — `/brd-split` on a root now requires a slicing instruction

A root is never ground, so nothing exists yet to cluster candidate slices from. The `<instruction>` argument, previously optional at both levels, is now **mandatory on a root whose ledger still holds an `unallocated` row** — `BRD_SPLIT_NEEDS_INSTRUCTION` if absent — and stays optional on a slice, where it only seeds the allocation walk's per-row recommendation. The stop is taken late in Phase 0, once the ledger has been read, so a root run that proposes nothing still runs without one: that is the run three other stops on this route name as the way to resolve a child left standing while claiming nothing, and it carves no slice.

The route now runs intake → split (root, instruction required) → ground (slice) → split (the same slice, `allocate-only`) → interview → package → reconcile. `/brd-split` runs twice, with grounding sitting between the two runs rather than before the first. Route ordinals ("the second command...") were removed from all six command bodies and from the surrounding documentation, since counting a fixed position stopped meaning anything once a command occupies two different steps of its own route.

### Fixed — the PRD-eligibility test's consumer list undercounted itself by half

`coverage-ledger-format.md` §5.1's positive test for "this unprefixed folder is a BRD container" is the same test `/create-prd`, `/create-ard`, `/specify` and `/epics` already shared. The four newly-refusing `/brd-*` commands cite it too now, rather than each restating the rule inline — which is what keeps a fifth divergent copy from shipping the way a fourth once did. §5.1's own consumer list grew from four to eight to say so.

## [1.1.0] — 2026-09-06

### Fixed — three more gates that a count could satisfy with nothing

`/brd-reconcile` froze zero `[CD#n]`, swept nothing and reported success on a digest the reader had failed to parse: its three gates all count *undisposed* items, so an empty digest satisfied them vacuously. `BRD_RECONCILE_EMPTY_DIGEST` reads the verdict written in section 2, which the schema fixes to three values: `approved` beside three empty sets is a customer who agreed and is recorded as the approval it is; any other verdict, or a section 2 that is absent or gives none, is a review contradicting itself or a parse that failed.

`/brd-package` step 7's *"every question in every round"* is a universal, true over no rounds at all. The rounds a BRD has are now **derived from `decisions.md`'s `round` fields** rather than from the `interview/` listing, and each one is gated with `require-on-main`; any on no ref stop together with `BRD_PACKAGE_ROUNDS_NOT_ON_MAIN`. Deriving the set is what makes a partial merge visible — enumerating the directory finds the rounds that landed and never learns a third was owed, which is the case the gate exists for. Step 8 gained `BRD_PACKAGE_NOT_INTERVIEWED`: it had reported a BRD with no `[VD#n]` as **finished**, which is right for one that was interviewed and settled and wrong for one that never was.

`--docs <path>` was declared by `workflows-core:docs-grounding` for all nine of its consumers and parsed by `/idea` alone; the other eight took `--no-docs` and nothing else, so an operator whose documentation is not at `$DOCS_PATH` could only turn grounding off. Implemented in all eight, each stripping the flag and its value together before anything counts positional tokens.

**`/create-ard` and `/specify` needed a flag-parsing step before they could accept either flag**, and finding that out is the more useful half: neither had one, and both refuse a second positional token outright — so the `--no-docs` both of them have documented since they shipped would have tripped `CREATE_ARD_ONE_ADDRESS` / `SPECIFY_ONE_ADDRESS` and stopped the run. The flag was named in two Usage lines and parsed nowhere.

`/epics` gained the `--no-docs` / `--docs` parsing step it had never declared, and its "Provide manual fix notes" escalation option gained the resolution instruction it never had — every other option in that array had one.

### Added — `/brd-ground --no-code`, so a missing design pass can be added without re-deriving the code findings

`--no-code` is a run mode, not a step skip: `grounding/code-grounding.md` is read-only for the whole run, the run produces no `[CG#n]`, and every finding already on file keeps its verdict, evidence and verifier outcome — never renumbered, never re-verified, never rewritten. Repositories are still resolved and pinned, because a class-4 `[DG#n]` is pinned to the commit of the `[CG#n]` it cites.

It exists because there was no way to reach the state without it. A BRD found to have exported frame sets and no design grounding could only be repaired by a full re-run, which on the engagement that reported this would have put **278 verified findings** back through derivation. `--no-design` had existed since the route shipped; `--no-code` never had.

Documentation grounding and the derivation matrix are off under this mode — both are written into the file it holds read-only — and the run refuses it outright alongside `--no-design`, alongside `--rebaseline`, alongside an explicit `--derivation-matrix`, or against a BRD with no verified code grounding to build on.

### Added — `/brd-reconcile --sent`, so an out-of-band customer review can be reconciled at all

The reconcile gate required a `customer-review-prompt-<YYYYMMDD>.md` that `/brd-package` had built and handed off. A review answering a package authored by hand, or sent before the route existed, could therefore never become a `[CD#n]` by any route — and no re-run of `/brd-package` could produce the missing artifact, since it will not rewrite a dated bundle and a fresh one is a *different* document from the one the customer answered.

What that gate protects is that a quotation can be checked against a committed copy of the document it came from. `--sent <path>` supplies that copy from the other direction: the operator names what was actually sent, each path is copied verbatim into `customer-sent-<YYYYMMDD>/` and committed beside the review before anything reads either. The invariant holds; only its provenance changes, and the run records which of the two it worked from in the reconciliation record and the final report. It replaces the package gate and nothing else, and is refused where a handed-off package already exists.

### Fixed — `/brd-split` passed a BRD whose designs had never been ground

The gate counted findings carrying no verifier outcome, so **zero findings satisfied it vacuously**: a BRD with two indexed frame sets and no `grounding/design-grounding.md` at all sailed through, and its slices could reach build with their designs never reconciled. A count tests a property of the records that exist; what was wrong was the records that did not.

Two presence relations now run before the count, each failing when its own side comes up empty. A `code-grounding.md` on main recording no `[CG#n]` stops with `BRD_SPLIT_NO_FINDINGS`. A **design/** subdirectory covered by no entry in `design-grounding.md`'s new frame-set list stops with `BRD_SPLIT_DESIGN_NOT_GROUND`, which names `/brd-ground <KEY> --no-code` as the repair. A set the operator explicitly skipped with `--no-design` passes and is recorded in `slices.md` as a limit on what the split could check. The design test executes `require-on-main` against `design-grounding.md` rather than reading the worktree — `--no-code` hands that file off in its own commit, so the single-commit implication the code gate relies on does not reach it, and without the gate the repair this very stop recommends could satisfy it with an unmerged file. A BRD ground before this release has no frame-set census and is passed with a recorded note rather than sent into a re-derivation it does not need.

**`/brd-interview` carried the identical vacuous count and is fixed with it** — `BRD_INTERVIEW_NO_FINDINGS`. It matters more there than in `/brd-split`: with zero findings that command answers every `[G]` from an empty evidence set and freezes `[VD#n]` against nothing. It takes no design relation, deliberately — a frame set with no `[DG#n]` yields no question to answer wrongly, and `/brd-split` gates the same BRD before any slice reaches build. `/brd-ground` Phase 8 now writes that frame-set list — every subdirectory on disk, covered or not — which is what makes the relation checkable rather than inferred.

### Fixed — `/epics` dispatched `doc-fixer` without its plugin namespace

The **BLOCK** branch said "invoke `doc-fixer`" with no `subagent_type`. `doc-fixer` ships from `workflows-core`, so the unqualified name resolves to nothing. Every other dispatch in the file was already qualified; this branch was the one that carried its instruction in prose rather than in a dispatch block.

## [1.0.0] — 2026-09-06

### Added — the product-definition half of `dev-workflows`, extracted into its own plugin

Install it with `claude plugin install product-workflows@ihudak-plugins`. Updating the marketplace alone does **not** install it: `dev-workflows` does not declare it, because no `dev-workflows` run loads anything from it.

Twelve commands move here from `dev-workflows` 3.27.0, and each keeps its bare name once this plugin is installed — only the namespaced form changes, from `/dev-workflows:<command>` to `/product-workflows:<command>`:

- the idea → PRD → ARD → specification ladder: `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`
- the Epic breakdown: `/epics`
- the six-command BRD-to-PRD route: `/brd-intake`, `/brd-ground`, `/brd-split`, `/brd-interview`, `/brd-package`, `/brd-reconcile`

Twelve agents and nine reference files move with them. The partition is exact: no agent and no reference is shared with the commands that stayed, so every `${CLAUDE_PLUGIN_ROOT}` citation among the moved files points at a file that moved alongside it.

### Dependencies

Two, both declared, both host-resolved at install:

- **`workflows-core`** — the shared reference corpus every command here loads in its first phase. An unsatisfied dependency disables the plugin rather than letting it half-run, which is the intended behaviour: there is no degraded mode to fall back to.
- **`prose-style`** — `prose-style-checker` is `/epics`'s primary style checker, not a fallback. Declaring it removes the absent case entirely; the "skipped gracefully when not installed" branches that shipped while it was an optional companion are retired, because for `/epics` "skipped gracefully" meant no style check at all.

`dev-workflows` is **not** a dependency in either direction. This plugin's spine hands `specification.md` to `/dev-workflows:design`, but it installs and runs without it, against a specs tree someone else's engineering work will eventually fill in.

### Hooks

One `UserPromptSubmit` hook, which preloads `$SPECS_PATH` and `$REPOS_PATH` context for `/epics`. It matches both the bare and the plugin-qualified form; the family's three preload hooks accept only their own plugin's prefix and cover disjoint command sets, so no single prompt can match two.

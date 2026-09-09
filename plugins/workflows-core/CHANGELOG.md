# Changelog

All notable changes to the **workflows-core** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.4.0] — 2026-09-08

### Added — the `proposal` cost phase, and its two `cost-emission` §7 rows

`product-workflows`'s `/prd-proposal` and `/brd-proposal` each take a fixed `phase: proposal`,
`role: pm` row in §7's attribution table, bringing that table to twenty-four rows.

**`proposal` is its own phase rather than a second `brd-to-prd` one**, and §7 records why:
`/prd-proposal` runs on the idea route as readily as on the BRD route, so filing its spend under
`brd-to-prd` would attribute idea-route spend to a route that run never touched — and an effort
proposal is a commercial activity over a requirement set rather than a step that advances one.

The counts that ride on §7 moved with it: the file's own opening sentence now reads twenty-two of
the twenty-four rows, and §11's and §13.3's *"commands that measure themselves"* both read
twenty-two. `scripts/command-namespaces.json` gains both command names under `product-workflows`,
which is what lets §13.2 cut a deferred run's window at either of them.

### Added — two `phase-handoff.md` §3.4 row-F rows, and one §4.0 classification

- **`/prd-proposal` on `prd.md`** — **stops**, splitting row F into `PRD_PROPOSAL_NEEDS_PRD` (never
  produced) and `PRD_PROPOSAL_PRD_NOT_HANDED_OFF` (produced, handoff declined). Never optional:
  there is nothing to estimate without it, and the command ships with no pre-gate behaviour to fall
  back to, which is the §3.4 test a stop has to pass.
- **`/brd-proposal` on each included slice's `proposal.md`** — **stops** with
  `BRD_PROPOSAL_SLICE_NOT_HANDED_OFF`, naming every included slice that came back row F in one stop
  rather than one run per slice. **It is the only row in that table that inverts the level rule**:
  the four callers above it refuse a root and their rows describe a slice run, while this one refuses
  a slice and gates a file in each of several **child** folders from the root.
- §4.0 classifies a slice's `proposal.md` as **gated** (conditionally gated is still gated, the same
  call `grounding/design-grounding.md`'s row makes), and an umbrella's `proposal.md`,
  `proposal-brief.md` at either level and the archived `revisions/` snapshots as **unread** — looked
  for, and none found. The §2.9 `prefix` row records that `prd` is now shared by `/prd-proposal`
  alongside `/create-prd`, `/update-prd` and idea-route `/prd-ground`, and `brd` by `/brd-proposal`
  alongside the route's six; the eight prefixes §1 rule 3 fixes are **not** extended.

### Added — both routing-graph nodes in `next-phase-offer.md`

A *PM — effort proposals* section: `/prd-proposal` offers depth (`/brd-proposal`, where the folder
has a parent BRD), breadth (the next unpriced sibling slice) and, below tier 4, the command that
would raise the tier; `/brd-proposal` offers no forward advance at all, because the umbrella is the
end of that branch rather than a phase in the build ladder.

**The `<merge-clause>` rule reaches the pair through the globs the scope paragraph already names** —
`` `/product-workflows:brd-*` `` and `` `/product-workflows:prd-*` `` — so both are inside the rule
by name rather than by adoption, and `check-docs.sh` check 11 gates them without being widened.
**The placeholder appears in exactly one option across the pair**: `/prd-proposal`'s offer of
`/brd-proposal`, whose `require-on-main` gate targets the `proposal.md` that same run has just
written. Every other option in the pair names a command gating on `prd.md`, which neither proposal
command writes, or names the offering command itself.

The scope paragraph also states the property most likely to be misread: neither command is a
prerequisite for the build ladder, none of `/create-ard`, `/specify`, `/epics`, `/design`,
`/implement` or `/ready` reads a proposal, and the pair's one internal read —
`/brd-proposal`'s gate on a slice's `proposal.md` — stays inside the pair and never reaches into the
pipeline above it.

### Changed — counts and enumerations the new commands moved

- `specs-repo-git.md`: twenty-six `commit-artifacts` callers, and §4.1's branch-opening list is
  seventeen, still matching `phase-handoff.md`'s producer count, with `/prd-proposal` named and
  `/brd-proposal` reached by the `/brd-*` glob.
- `feedback-emission.md`: twenty-one of the twenty-six callers ship from a sibling plugin.
- `escalation-rules.md`: both commands cite the *Required path environment variable unset* rule, and
  the clause that used to read "for the last four" now names its commands — counting from the end of
  a list is how it silently came to describe a different set.
- `addressing.md`: `/prd-proposal` joins the commands that are **not** in §7's adopter table because
  each resolves its own single positional address with `resolve-address` (§3). §7's two totals are
  unchanged at twelve files and twelve commands, re-derived rather than adjusted. The two places that
  counted the `/brd-*` consumers now say six, since `/brd-proposal` matches that glob and addresses
  the same parent containers §3's disambiguation step exists to keep addressable.
- `cost-emission.md`'s preamble sketch of who has a §7 row names the effort-proposal pair. The
  paragraph already refuses to be a roster — read the table — but an omitted class is what went stale
  there once before.
- `docs/roles-and-phases.md`: twelve phases exist, nine of them reachable from this plugin only by
  inheritance.

## [1.3.6] — 2026-09-08

### Fixed

- **`grounding-format` §1 reads as it was meant to.** The sentence defining what a finding answers put
  an em-dash clause immediately after a closing parenthesis, so *checked against a pinned revision*
  appeared to qualify the parenthetical rather than the clause it belongs to. The requirement-row list
  is now bracketed by a matched pair of em-dashes and the design-grounding case is its own sentence.
  No rule moved.

## [1.3.5] — 2026-09-08

### Removed

- **`relevant_for_release_notes` is retired from `prd-format`'s frontmatter.**
  It asked a question with one answer — every PRD is relevant for release notes — so the only value it
  could carry that changed anything was one nobody should write. A value left in an existing PRD is read by
  nothing, and the file records the retirement so the field is not reintroduced.

## [1.3.4] — 2026-09-08

### Changed

- **`addressing` §5's legacy fallback is stated as covering the folder name and nothing inside it.** The
  paragraph previously said the fallback meant a user "need never" rename, unqualified, and that claim
  covered artifact filenames it never reached. A tree written before the artifact filenames lost their
  keys still renames its own `<KEY>_<slug>.md` to `prd.md` and `<KEY>_ARD.md` to `ard.md`; no command
  resolves those for it. Recorded as a narrowing rather than a clarification: a resolver for the legacy
  artifact names is derivable from the unqualified claim, and was derived in full before the population
  it would serve was measured.

## [1.3.3] — 2026-09-08

### Added — `phase-handoff.md` §4.0 classifies `code-defect-log.md`

`product-workflows`'s `/brd-interview` now declares `<BRD-dir>/code-defect-log.md` in its
`deliverable_paths`, and §4.0 states four times over that the class table is derived from the tree's
`deliverable_paths` declarations, that an unlisted path is **unclassified rather than unread**, and
that *"a producer adding a deliverable adds its row here in the same change"*. This is that row.

The class is **advisory**: two commands read the file and neither gates on it — `/brd-package`
Phase 0 step 10 reads every `[CDF#n]` in it with its `disposition`, `statement`, `intent` and
`blocked_on`, and `product-workflows:brd-package-reviewer`'s sixth hunt class reads it to settle
whether an `argumentation` claiming a recorded defect actually has one. §3.4 names no `require-on-main`
gate on it, which rules out **gated**, and a named reader rules out **unread** — the two halves §4.0
requires before an array is picked. The row also records that the file's absence is an ordinary state
rather than a declined handoff, since `/brd-interview` writes it only where a round raised an entry.

### Changed — `addressing.md`'s slice-inheritance sentence says *which* defect log it means

§6's nesting-cap rationale said a slice *"inherits `brd/source/` and its defect log"* from its BRD. That
was unambiguous while the route had one defect log; it now has two, and only one of them inherits — the
requirement log is the parent's, the code-defect log is the slice's own. The sentence is qualified, and
names the other so a reader does not conclude the wrong one is reached one hop up. No rule changes.

## [1.3.2] — 2026-09-08

### Changed — `grounding-format.md` §6.3's class-4 reconciliation rule gained a correctness half

A class-4 `[DG#n]` already had to carry a `[CG#n]` citation — completeness was checked, correctness
was not. §6.3 now also requires that the cited finding's `claim` name the same requirement id as
the citing `[DG#n]`'s own `claim`: an absent citation is visibly incomplete and a reader stops, but
a citation that resolves sends the reader to a real finding about a different requirement, which
they have no way to detect by reading — the worse of the two failures. The rule is route-neutral,
like the rest of §6: it reads `claim` off both records the same way whether the requirement id in
front of it is a BRD's `[BR#n]` or a PRD's `[AC#n]`/`[FR#n]`/`[US#n]`, so it needs no route-specific
branch.

`product-workflows:bundle-packaging` §6 is the first enforcer, added in the same release
(`product-workflows` 3.1.0): its citation-resolution check's relation 2 traces this rule over an
assembled bundle's copied corpus files. This release adds the rule and its record shape only —
`grounding-format.md` states no way to run the check itself, since it has no bundle of its own to
check.

This is a patch, not a change of behaviour on its own: §6.3 already required a class-4 finding to
carry a `[CG#n]`; this widens what "carry" requires without altering `design-grounder`'s output
template or any field the format did not already mandate be present.

## [1.3.1] — 2026-09-08

### Fixed — `phase-handoff.md` §3.4's PRD rows named their gate target in prose, so `check-docs.sh` check 11 could not see it

Check 11 gates the `<merge-clause>` placeholder by intersecting an offering run's declared `deliverable_paths` with the offered command's `require-on-main` target, and it reads that target out of §3.4's row-F table — specifically, the backticked `*.md` in the Input column. The `/create-ard` and `/specify` rows both read simply *"the PRD"*, so the extractor found no filename, skipped both rows, and the relation never fired for either command anywhere in the tree. Nothing shipped was wrong; those offers were held by review alone.

Both rows now read ``the PRD (`prd.md`)``. That is the name `/create-ard`'s own Phase 0 resolves on the ref — falling back to the legacy `<KEY>_*.md` form — rather than one inferred from convention, because the row states what the gate targets and a row-F cell that misnames it would be worse than one that says nothing.

**The widening was measured before it was taken, and fires on nothing**: the writer set was extracted afresh for all six commands inside check 11's family globs and none declares `prd.md`. That measurement corrected an earlier estimate — that naming the file would "newly gate every offer of `/create-ard` and `/specify` across the tree" — which had been the reason for parking this. Check 11 only ever examines in-family commands, so `/create-prd` and `/update-prd` were never reachable by it.

Three rows of that table still name their target in prose and are deliberately unchanged: the ARD row and the `/ready` row. Both measured zero-fire too, but an ARD may be split per area and `/ready`'s row covers three artifacts with three resolution rules, so naming a single filename in either would assert something the gate does not.

## [1.3.0] — 2026-09-08

### Changed — `grounding-format.md`'s finding contract widened to a route-neutral claim, not only a `[BR#n]`

`product-workflows` shipped idea-route grounding: `/prd-ground` now takes its claim list from a
PRD's own `[AC#n]`/`[FR#n]`/`[US#n]` rows as readily as from a BRD's `[BR#n]` inventory. §1's finding
definition, §2's finding-record fields, and §6's design-grounding reconciliation classes now speak
of "a requirement id and its text, as the caller supplies them" rather than assuming `[BR#n]` — the
BRD-6 lesson applied one level up: a contract that still names one prefix in its own prose is a
contract whose worked examples keep reproducing it, however route-neutral the field shapes
underneath already were. `code-grounder`, `design-grounder` and `grounding-verifier` resolve an id
against the list the caller handed them, on either route, and their own output templates moved to
match — the same lesson again, since a template the model copies has to change too, not just the
prose around it.

### Fixed — §6.1's foreclosures asserted an absence this release makes false

Two paragraphs said a `/idea`-route `design/` folder reconciling into evidence was "a known and
deliberate state, not a gap" and that the capability "remains deliberately unbuilt on every other
route." Both are now false: `/prd-ground` reads a `design/` frame set as evidence on both routes in
this release. §6.1 is rewritten against what ships — a class-1/2/3 finding settled from the frame set
and the requirement text alone, a class-4 citing a `[CG#n]` and inheriting its commit, either route —
and its writer-versus-consumer paragraph, which forecloses nothing itself but fixes what "consuming"
a frame set means, is read alongside the correction rather than left to imply the old foreclosure
still holds. A cosmetic fix travels with it: §1's requirement-identifier clause had an em-dash-bounded
aside butting straight against a pre-existing parenthetical; the two are now nested rather than
stacked.

### Changed — `next-phase-offer.md`'s scope paragraph, and `check-docs.sh` check 11, now read a second family glob

`/product-workflows:prd-ground` left the `` `/product-workflows:brd-*` `` family the day its own
rename shipped — the rename made it stop matching. It still prints an offer naming a downstream
command whose `require-on-main` gate this same run feeds, exactly as the other five route commands
do, so it carries the `<merge-clause>` convention too, now under its own glob,
`` `/product-workflows:prd-*` ``, named in the scope paragraph on the same line as the first. Check
11's family derivation reads every glob the scope paragraph names rather than only the first, so the
rename does not silently drop `/prd-ground`'s offers out of the gate it was already subject to — a
risk this feature's own design flagged as the one item a sweep cannot fix, because it has to be
designed.

### Fixed — `phase-handoff.md` §2.9 named only two commands sharing the `prd` branch prefix

`/prd-ground` now uses `prefix: prd` on the idea route, which the parenthetical did not name. Fixed
to read "shared by `/create-prd`, `/update-prd` and, on the idea route, `/prd-ground`."

### Fixed — `specs-repo-git.md` §4.1's branch-opener enumeration silently dropped `/prd-ground` after the rename

`/prd-ground` still opens on the shared `brd` prefix on the BRD route, exactly as `/brd-ground` did
before it — but "every `/brd-*` command" stopped matching it the day the rename shipped, and a sweep
that greps for the literal string `/brd-ground` cannot catch this: the sentence never contained it.
The enumeration named nine commands plus "every `/brd-*`" and totalled fifteen only while the glob
still reached the command that is now `/prd-ground`; after the rename the glob matches five, so the
sentence silently named fourteen producers where `phase-handoff.md` still recorded fifteen. Added
`/prd-ground` back in by name, restated the total, and explained why it is named separately from the
glob rather than folded back into it — it left the `/brd-*` glob, not the branch-opening behavior, and
on the idea route it opens on the shared `prd` prefix instead. This is the defect class the rest of
this fix round exists to name: a command that leaves a `/brd-*`-shaped glob without leaving the route
it still serves, invisible to any sweep keyed on the old command name.

### Changed — renamed citations swept through the shared reference corpus

`docs-grounding.md`'s consumer list, `phase-handoff.md`'s branch-prefix and producer/consumer tables,
`feedback-emission.md`, and `workflows-core:frames`'s own command and docs page all cited
`/brd-ground` by its old name. Every citation now reads `/prd-ground`, and `phase-handoff.md`'s
six-consumer / fifteen-producer counts are unchanged — the rename moved a name, not a relationship.

## [1.2.0] — 2026-09-07

### Fixed — a verifier could disagree with a finding and nothing noticed

`grounding-verifier` returns its own re-derived verdict alongside **every** outcome. §8 defines `agree` as reaching *the same* verdict and `extend` as the claim *holding*, so either arriving with a differing `own_verdict` is a return whose two halves contradict each other — and nothing reconciled them. §8 now states the rule: such an outcome is **normalised to `contradict`** and the caller acts on the branch that believes the re-derivation, recorded rather than silent. **`unprovable` is never normalised** — its verdict is `NOT-PROVABLE` and differs from the finding's by definition, while the outcome means only that the verifier's own search settled nothing, so normalising it would rewrite every inconclusive finding into a contradiction nobody reached.

### Fixed — the finding record's field set was open, so a second verdict could be written beside the first

§2.1 fixed the *bytes* of a finding block and left its *field set* unstated. A writer holding the verifier's return therefore had nothing forbidding it from transcribing `own_verdict` into the record, producing a block that states two verdicts at once while `verdict` is what every downstream consumer reads — so a decision citing that finding could quote whichever half suited. Three corpora from a live engagement were counted by hand in this state. §2.1 now names the field set **closed** — §2's fields plus `outcome` and `notes`, and nothing else — and `product-workflows:grounding-verifier` says the same from the emitting end, because fixing the file's writer without fixing the agent whose output the model copies leaves the defect one hop upstream. That is BRD-6's lesson, and this is the same family met at the field set rather than at the bytes.

**Why the existing handling did not cover it.** §8's `contradict` branch has rewritten the finding to the verifier's verdict since `/brd-ground` first shipped. The gap was never that branch — it was that `agree` and `extend` never reached it, and that nothing bounded what a writer could add to the block.

## [1.1.1] — 2026-09-07

### Fixed — two shared authorities carried claims `product-workflows` 2.1.0 falsified

`product-workflows` 2.1.0 shipped the **sibling re-cut**: on a fully-allocated parent BRD, a row the parent delegated to one slice — and that slice's own ledger records `deferred-to: <itself>` for — can be re-pointed onto a sibling that has not been interviewed. Two sentences here described the world before it.

`next-phase-offer.md`'s `/brd-split` row offered grounding *"once per **non-empty** child the run created"* and described a child emptied *"by withdrawing every **provisional** claim"*. Both are now wrong in both directions: the offered set is every child that **gained a row this run**, so the old wording would offer a re-run for a non-empty child that gained nothing — the re-derivation `/brd-split` Phase 7 explicitly forbids — and would omit a standing receiver, the child whose grounding demonstrably no longer covers what it claims; and a re-cut empties a donor by withdrawing a **committed** claim, the eighth site of an appositive whose seven siblings were widened with the feature.

`phase-handoff.md` §3.4's `BRD_GROUND_NOT_HANDED_OFF` row said `/brd-split` is never a way out *"on a fully-allocated parent"*. It is, when that run is **instructed**: the re-cut stages the receiving slice's three files. The row now says **bare**, matching the qualification `/brd-ground` carries at every other site of the same claim.

**Why they were missed.** The feature's own consumer sweep was scoped to `plugins/product-workflows/commands/brd-*.md`, and nothing in this plugin was touched by that branch — so the recipe that found the seven other sites could not see either of these, even though `CLAUDE.md` names this plugin's `next-phase-offer.md` as the authority for the whole `/brd-*` offer convention and for `check-docs.sh` check 11's family derivation. A rule relaxed in one plugin is a claim re-opened in every plugin that documents it.

## [1.1.0] — 2026-09-06

### Fixed — a reader that stops on an artifact now gates it, and the class register is derived rather than remembered

`phase-handoff.md` §4.0 states the rule two increments kept re-deriving: **a stop is only as reliable as the ref it reads.** A command that refuses a state it found in the worktree can be satisfied by a file nobody else can see, so the refusal protects the operator who ran the producer and no one else. Found twice, in `/brd-split`'s design gate and `/brd-package`'s round gate, both of which had inherited a sibling's `require-on-main` through a "one handoff, one commit" implication that `/brd-ground --no-code` had already falsified. Both now gate what they stop on, and both have §3.4 rows.

The register itself is now derived from the tree's `deliverable_paths` declarations instead of from memory, and carries every artifact they name — including the four with no reader found, listed rather than omitted so that absence from the table means *unclassified* and never *unread*. It had twelve rows against roughly thirty declared paths; the gap cost nothing only because most unlisted artifacts rode in a set that already held a gated path, and `--no-code` produced the first set with no classified path in it at all.

`feedback-emission.md` §4's persist predicate said "the dev-workflows plugin itself" — one plugin of four, read literally dropping every signal about the other three — and reached for `${CLAUDE_PLUGIN_ROOT}/references/**` two paragraphs below the note explaining why that variable resolves to the wrong tree here. `/feedback` said the same thing three times in user-facing text.

### Added — the two session-wide hooks, and a serialisation the grounding artifacts never fixed

`notify-done` and `test-notify` now ship here. Both are session-wide rather than command-scoped, and every plugin in the family declares `workflows-core`, so one copy serves all of them instead of a copy per plugin (I4-3). Install or update `workflows-core` and both hooks arrive with it.

`grounding-format.md` gains §2.1, which fixes how a `[CG#n]`/`[DG#n]` finding is written to disk — one space after every key's colon, never alignment padding, keys in §2's order, an inapplicable field omitted rather than left empty. Nothing had fixed it, so a writer aligned one section of a `code-grounding.md` and not the next; a scan of that file then reported **140 findings as missing that were on the page**. §2.1 also states the reading rule that outlives the fix: resolve an id against the finding set you parsed, never by matching a column, and report a disagreeing count as a parse failure rather than as an absence.

### Fixed — a frame-set index is read, and every producer had been told it was not

`phase-handoff.md` §4.0's class register said a frame-set `index.md` was **unread**. It is not: `product-workflows:design-grounder` refuses to run on a frame set holding no index, and `grounding-verifier` returns `NO_INDEX`/`STALE_INDEX` on one. The index is **advisory** — read from the working tree, gated by nothing — and `/frames` now presents the advisory consent array. Until this fix it presented the unread array, telling the operator that nothing downstream reads a file `/brd-ground` refuses a frame set without, three lines above its own paragraph saying the set stays `NO_INDEX` for everybody else.

The register was verified against the tree rather than carried forward, which is how this surfaced: the gated row is a two-way match with §3.4's Input column, and each advisory row was re-derived by opening the reader it names. The **unread** class now has no member *in the register*, which is not the same as no artifact being unread — `slices.md` is handed off and no reader was found for it. §4.0 now says outright that it classifies the artifacts whose class a producer has had to resolve rather than everything the family hands off, and that an unlisted path is unclassified rather than unread.

### Fixed — the rest of the release-gating ledger

- **PS1** — an unwritable `.git` and a `$SPECS_PATH` that is not a repository are different states. The first is a silent no-op; the second now emits a named notice. Neither is ever fatal.
- **PS2** — `/frames` adopts a frame-set index kept under another name instead of refusing the set.
- **PS3** — the cost-boundary detector's *cut* test is now separate from its *claim* test. A command from outside this marketplace ends the open window without being claimable; before the split its spend was absorbed into somebody else's claim.
- **I4-6 / I4-7** — `<default-ref>` is resolved by probing for an `origin` remote and is owned by `specs-repo-git.md` §3.2, which `phase-handoff.md` now cites rather than redefining. Three git calls outside `require-on-main` had hardcoded `origin/<default>` too.
- **"this plugin" named the wrong plugin** in `cost-emission.md`, `feedback-emission.md` and `phase-handoff.md` §3.4. Each now names `workflows-core` outright, or says "the family" where the referent is family-wide — §3.4's row-F paragraph in particular, where the gate routinely runs across a plugin boundary and a one-plugin reading would stop the route at each one.

## [1.0.0] — 2026-09-03

### Added — the shared foundation of the `dev-workflows` plugin family

`workflows-core` is the second increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md` (the first extracted `guideline-reviewers`). It carries what more than one plugin in this family reads, so that a family member can be installed without dragging the rest of the pipeline along with it.

**Twenty-nine reference files**, moved from `dev-workflows` with their rules intact — what changed in the move is how they are *cited*, not what they say: the addressing grammar, the specs-repo git entry points and phase handoff, model routing, escalation, finding triage, grounding and grilling technique, the PRD format, cost / feedback / follow-up emission, and the price table they cost against.

**Six commands** — `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`, `/statusline` and `/frames`. The first five are family-meta: they log friction about the plugin family itself or drive its status line. `/frames` indexes a design frame set, which every phase of the pipeline may hold.

**Five agents** — `code-scanner`, `doc-fixer`, `docs-grounder`, `frame-describer` and `impl-maintenance` — each dispatched by commands in more than one plugin, as `workflows-core:<agent>`.

**Two skills.** `model-routing` is the one that moved. `reference` is new, and it is the mechanism the whole split turns on: `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, so a dependent plugin cannot read a shared reference by path. `Skill(skill: "workflows-core:reference", args: "<name>")` reads one reference by name; an optional second argument names an entry point within it to execute inline. One argument-taking skill serves the whole corpus, rather than one wrapper per reference.

**The cost helper**, `scripts/session-cost.py`, and the status-line script beside it. New alongside them is `scripts/command-namespaces.json` — namespace to that plugin's own command names, one entry per plugin of this marketplace that ships commands — which is what command boundaries now resolve against.

`dev-workflows` 3.26.0 declares `workflows-core` as a dependency, so installing it installs this. The two changes below are stated against the same machinery as it shipped inside `dev-workflows` up to 3.25.0, because that is where it ran until now.

### Removed — `session-cost.py --commands-dir`, a breaking change for direct callers

**The flag is gone, not deprecated.** Anyone invoking `scripts/session-cost.py` by hand or from their own tooling and passing `--commands-dir` gets an unknown-argument error and must drop it. That failure is loud on purpose — an unrecognised flag is an error, never a silently ignored one — but it is real, so it is stated here rather than left to be discovered.

Nothing replaces it. The flag existed to hand the script one plugin's `commands/` directory as the set of names a slash-command boundary could be drawn from, and that is precisely the assumption the split had to abandon: a family that spans several plugins has no single such directory. Boundaries now resolve against `scripts/command-namespaces.json`, shipped beside the script and read with no flag and no path assumption. `--namespaces <path>` overrides that manifest and exists to be pointed at a test fixture; where it resolves to nothing, boundary detection is off and every claim is reported unmatched and dropped, rather than guessed at.

### Fixed — a replayed cost claim could absorb a sibling plugin's spend

A command that cedes the session (`/prompt-brainstorm`, `/prompt-grill-me`) cannot write its own cost entry, so it records its labels and the next cost-emitting run writes the entry on its behalf, splitting its window at the transcript's record of where that run began. The boundary used to be accepted only as `<this plugin>:<this plugin's own command>` — resolved against whichever single plugin supplied the command set. Once the family spanned more than one plugin, an intervening command **from a sibling plugin** was not recognised as a boundary at all, and a claim is given the segment up to the next boundary of any kind. The claim therefore swallowed the sibling's run whole.

Nothing was ever double-billed and no entry already written on disk was corrupted. What went wrong is attribution *between two entries of the same replay*: the deferred command's entry was charged for work it did not do, and the replaying run's own remainder was short by exactly that amount. Reproduced at 9000 tokens claimed where 5000 was correct.

Both halves of a boundary now resolve against the manifest — the namespace must be a key of it and the name must appear in *that key's* list — which is why widening the accepted namespaces alone would not have been enough, and why the fix still rejects a bare built-in whose name a plugin here happens to share, and still rejects another marketplace's identically-named command. `session-cost.py --selftest` pins each of those properties against the broken implementation it exists to catch, including the half-fix that widens namespaces without widening the per-namespace name sets.

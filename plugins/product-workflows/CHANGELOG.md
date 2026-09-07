# Changelog

All notable changes to the **product-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [2.0.0] — 2026-09-07

### Changed — grounding, the interview, packaging and reconciliation move to the slice; a root now refuses all four

`/brd-ground`, `/brd-interview`, `/brd-package` and `/brd-reconcile` used to accept a BRD key at either level. They now refuse a resolved root outright, in Phase 0 before any other gate — `BRD_GROUND_ROOT_LEVEL`, `BRD_INTERVIEW_ROOT_LEVEL`, `BRD_PACKAGE_ROOT_LEVEL`, `BRD_RECONCILE_ROOT_LEVEL` — each naming `/brd-split <BRD-KEY> "<how to cut it>"` as the remedy.

**This breaks the route for anyone running it at root level.** The six `/brd-*` commands carried this two-level model since they shipped in `dev-workflows` at `v3.24.1`, an ancestor of this release, so the model has been in users' hands the whole time the route has existed; a run that worked against a root in 1.1.0 now stops at the first gate. The design's decision was to refuse and detect rather than offer a compatibility path: where root-level grounding, decisions, interview records, package artifacts or a reconciliation record already exist from the earlier model, the refusal names their exact paths and says plainly that they are **left in place and read by nothing** — nothing migrates them and nothing deletes them.

**Major version, not another minor one.** `product-workflows` 1.0.0 and 1.1.0 both shipped this route as an installable plugin someone could pin against, unlike an internal step of a multi-part split — so unlike a case where no intermediate version was ever separately consumed, a run that worked against a root in either of those versions is exactly what this stops. Semver's own contract is that an incompatible change is a major version, not a minor one carrying a bold warning in its own prose; `2.0.0` is the number that tells an installer what this entry would otherwise have to say by hand.

Twelve documentation files, including both of the route's mermaid diagrams, were brought into line with the same fact, and the level-conditional branches only a refused root could still reach — "at either level," offers that fanned a root out into its slices, a next-step offer recommending a command that would now refuse the key it was handed — were removed rather than left as dead prose a future reader would have to re-verify is dead.

### Changed — `/brd-split` on a root now requires a slicing instruction

A root is never ground, so nothing exists yet to cluster candidate slices from. The `<instruction>` argument, previously optional at both levels, is now **mandatory on a root** — `BRD_SPLIT_NEEDS_INSTRUCTION` if absent — and stays optional on a slice, where it only seeds the allocation walk's per-row recommendation.

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

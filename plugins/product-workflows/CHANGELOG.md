# Changelog

All notable changes to the **product-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.1.0] — 2026-09-06

### Added — `/brd-ground --no-code`, so a missing design pass can be added without re-deriving the code findings

`--no-code` is a run mode, not a step skip: `grounding/code-grounding.md` is read-only for the whole run, the run produces no `[CG#n]`, and every finding already on file keeps its verdict, evidence and verifier outcome — never renumbered, never re-verified, never rewritten. Repositories are still resolved and pinned, because a class-4 `[DG#n]` is pinned to the commit of the `[CG#n]` it cites.

It exists because there was no way to reach the state without it. A BRD found to have exported frame sets and no design grounding could only be repaired by a full re-run, which on the engagement that reported this would have put **278 verified findings** back through derivation. `--no-design` had existed since the route shipped; `--no-code` never had.

Documentation grounding and the derivation matrix are off under this mode — both are written into the file it holds read-only — and the run refuses it outright alongside `--no-design`, alongside `--rebaseline`, alongside an explicit `--derivation-matrix`, or against a BRD with no verified code grounding to build on.

### Added — `/brd-reconcile --sent`, so an out-of-band customer review can be reconciled at all

The reconcile gate required a `customer-review-prompt-<YYYYMMDD>.md` that `/brd-package` had built and handed off. A review answering a package authored by hand, or sent before the route existed, could therefore never become a `[CD#n]` by any route — and no re-run of `/brd-package` could produce the missing artifact, since it will not rewrite a dated bundle and a fresh one is a *different* document from the one the customer answered.

What that gate protects is that a quotation can be checked against a committed copy of the document it came from. `--sent <path>` supplies that copy from the other direction: the operator names what was actually sent, each path is copied verbatim into `customer-sent-<YYYYMMDD>/` and committed beside the review before anything reads either. The invariant holds; only its provenance changes, and the run records which of the two it worked from in the reconciliation record and the final report. It replaces the package gate and nothing else, and is refused where a handed-off package already exists.

### Fixed — `/brd-split` passed a BRD whose designs had never been ground

The gate counted findings carrying no verifier outcome, so **zero findings satisfied it vacuously**: a BRD with two indexed frame sets and no `grounding/design-grounding.md` at all sailed through, and its slices could reach build with their designs never reconciled. A count tests a property of the records that exist; what was wrong was the records that did not.

Two presence relations now run before the count, each failing when its own side comes up empty. A `code-grounding.md` on main recording no `[CG#n]` stops with `BRD_SPLIT_NO_FINDINGS`. A **design/** subdirectory covered by no entry in `design-grounding.md`'s new frame-set list stops with `BRD_SPLIT_DESIGN_NOT_GROUND`, which names `/brd-ground <KEY> --no-code` as the repair. A set the operator explicitly skipped with `--no-design` passes and is recorded in `slices.md` as a limit on what the split could check. `/brd-ground` Phase 8 now writes that frame-set list — every subdirectory on disk, covered or not — which is what makes the relation checkable rather than inferred.

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

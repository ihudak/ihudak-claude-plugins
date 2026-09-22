# Verification: the exclusivity probe, run whole-tree

**Date:** 2026-09-22 · **Branch:** `iv-gu/housekeeping`, merged `5a7ba9c9` · **Fixes:** `3cec57e3`

The probe `CLAUDE.md` prescribes, run for the first time as its **own axis over the whole tree**
rather than as a sweep attached to a change. Scope was `plugins/` plus the repo-root `README.md` and
`CLAUDE.md`, as that file requires.

## Method

Six slices, one agent each, read-only: changelogs; `product-workflows` commands; the other three
plugins' commands; every reference file; every agent and bundled skill; every `docs/` page plus the
two root files. Each was given a wrap-insensitive probe (collapse whitespace across file *and*
pattern, match, map the offset back to a source line) because `commands/` and `references/` are
hard-wrapped and a line-based `grep` misses any phrase straddling a break.

**The triage rule, which is what made the population tractable:** a finding is a claim *about this
repository's contents* that today's tree falsifies, with a counterexample nameable by file and line.
Ordinary conditional or contractual prose — "correct only when the repository could not settle it" —
describes a *run's* behaviour and has nothing in the tree to check against. Each surviving claim was
then verified on **both** sides before any edit; a grep hit is a lead, not a finding.

## Population

**853 raw matches across 186 files.** 24 were falsified claims. The rest split between run-behaviour
prose (the large majority) and claims verified sound (below).

## What was checked and found SOUND

Recorded so a later pass does not re-derive it. Each was opened on both sides.

**Sole-writer / sole-creator claims.** `/epics` is the only creator of an `EPIC-` folder and the only
writer of `epic.md` (`specify.md`, `create-ard.md`, `ready.md`, `release-notes.md` all refuse rather
than mint; `create-prd.md` does auto-create `PRD-<KEY>-<slug>/` on first write, which is a different
folder kind). `/brd-interview` is the only writer of `code-defect-log.md`; `/brd-reconcile` says so
itself. `/brd-reconcile` is the only minter of `[CD#n]`, and the only producer calling
`handoff-to-main` twice. `/brd-intake` is the only stager of `brd/source/**`. `covered-here` /
`covered-by` are written only by `/brd-split`. `/brd-split` is the only writer of a `brd-link.md`
naming a `parent:`. `--sort-existing` is the only writer of the three altitude seed files. The qmd
index is built or refreshed only in `resolve-docs-grounding` step 3.5.

**Caller and consumer lists.** `branch-naming` (7 commands), `ard-resolution` ("all six consumers"),
`finding-triage` (15 citers), `doc-structure-conventions` (5), `docs-grounding` (9 — the extra citers
are all "resolves no docs grounding" statements), `escalation-rules` (9 files, matching its own stated
recipe), `classification` §8.5 (`/idea`, `/implement`, `/docs-audit` — current), `phase-handoff`'s 17
producers and 14 consumers, `cost-emission` §7's 27 cost-emitting commands, `addressing`'s
eleven-in-the-table count. Agent caller lists: `risk-planner`, `figure-reader`, `frame-describer`,
`design-grounder`, `code-scanner` (already current with `/docs-audit`), `vuln-fixer`'s
`baseline_tests` and `AWAITING_REVIEW` claims, `idea-reader`'s source enum.

**Claims that survive on a distinction the file itself draws.** `addressing` §1's "the only place
`<KIND>` narrows anything" — line 84 distinguishes *narrows* from *refuses a mismatch*.
`workflows-core/docs/reference/environment.md`'s "only read anywhere in this plugin" — `docs-grounder`'s
`$DOCS_PATH` mentions gloss an **input**, not a read of the variable. `/prd-ground` as the one command
flooring on its input — the other floors are output-shaped, and `/idea --ground-code` says outright it
does not floor. `docs-audit-reviewer`'s id claim — `backlog-format` prohibits *minting* a colliding id
rather than detecting one.

**Other verified-correct:** `refs[]` as the only element list `diff-summarizer` takes; `--no-commit`
as `/implement`'s only flag; `/document` direct mode's "writes these and nothing else" list;
`statusline`'s single settings change; `/docs-serve` as the only one of the four docs commands without
a gate; `release_versions` acted on by no command; `test-baseliner`'s "no consumer parses a test
identifier"; `/docs-audit`'s stop-route claim (every site says so); `$REPOS_PATH` as read/scan base
only.

## What is NOT verified

1. **The probe's five phrases are not the exclusivity vocabulary.** Four of six slices reported this
   independently: `the only <noun>` with no preceding `is`, and `the sole`, `only writer`, `only
   caller`, `no other command`, match none of them. Supplementary probes returned **44** further
   matches in one slice and **29** in another. Two of this pass's confirmed defects were reachable
   only past the five. `CLAUDE.md` now records that with the numbers — but **the wider vocabulary has
   not itself been run to exhaustion over the whole tree.** That is the obvious next pass.
2. **Run-behaviour prose was triaged out, not checked.** The large majority of the 853. A false claim
   about what a *run* does, with no tree-side counterexample, is invisible to this axis by
   construction.
3. **No command body was executed.** Every finding is a claim-versus-tree comparison.
4. **`docs/superpowers/` was out of scope** — the probe covered `plugins/` plus the two root files, as
   `CLAUDE.md` scopes it. The archive's 204 plans and specs were swept separately and only for
   *superseded status*, not for exclusivity claims.
5. **Two borderline omissions were judged not reportable** and are recorded rather than fixed:
   `toolchain-preflight`'s consumer list does not name `docs-style-checker` / `docs-scaffold-reviewer`,
   which cite its §2 source 2 for Vale config names; `read-only-repos`' does not name `docs-auditor`,
   which cites it only for reading at `prep.scanned_ref`.

## Method defects found in the dispatch briefs

Worth more than the tree findings, because they recur. All were reported by the agents themselves.

- **A binary asserted over a three-member space — in the reporting schema, not the prose.** I asked for
  `CONFIRMED` or `PLAUSIBLE`; **four of six** slices independently said the honest third member is
  *scoped-true / literally false* — falsified by a named line, but rescued by a scope a sibling
  sentence supplies, so nothing misexecutes and the defect is that two live sentences disagree. One
  agent noted it would have reported a **non**-defect had it been forced to choose. A severity scale is
  an enumeration like any other.
- **A stated inventory narrower than the glob beside it.** "84 pages across four plugins" where the
  glob resolved to 92 across five — and the file settling one finding sat in the omitted plugin.
  Likewise "four READMEs" where `plugins/*/README.md` is eight.
- **A derivation recipe scoped to two of four content directories.** `commands/` and `agents/` only;
  consumers also live in `skills/` and `hooks/`, and one reference names both of its consumers there.
  The prescribed grep would have produced a *false* finding had the agent not widened it.

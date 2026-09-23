# CLAUDE.md split — design

**Date:** 2026-09-22 · **Status:** approved by the user 2026-09-23 (design and written spec) · **Implements on:** the tree after exclusivity-probe round 3 lands (both edit `CLAUDE.md`); the block inventory in §5 is re-taken on that base.

## 1. Problem, measured

`CLAUDE.md` is **186,894 characters / 445 lines** (`wc -c`, 2026-09-22, `e22a6ee4`). It loads into every session in this repository and into every non-fork subagent those sessions dispatch — and this repository's work is dispatch-heavy (the last three increments ran 7–8 subagents per pass). Claude Code's own guidance is *"target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence"* (code.claude.com/docs/en/memory). It grew by accretion: each lesson appended a sentence of evidence to the rule it refined, and nothing bounded it.

Where the size is (bytes, by section): Conventions 62,990 (two bullets alone: the "nothing gates any number" gate bullet 20,788 and the sweep-refinements bullet 15,651); Key invariants 37,023; the workflow map 33,291; the per-reference "single source of truth" paragraphs 23,169; Active plugins 9,736; Test-writing requirement 7,331; Updating installed plugins 4,361; the rest 10,995.

**Most of it is evidence, not rule**: measured cases, refused widenings, "this file previously claimed…" history. An agent needs the rule and one line of why to follow it; the evidence exists so a rule is not re-litigated, and is needed only when someone proposes to change that rule.

## 2. Loading facts this design rests on

From code.claude.com/docs/en/memory and /sub-agents (fetched 2026-09-22):

- `.claude/rules/*.md` **with** a `paths:` frontmatter list of globs load **when Claude reads a file matching a pattern**, not at session start. Without `paths:` they load at launch like `CLAUDE.md`.
- Project `CLAUDE.md` and `.claude/rules/` load into every non-fork subagent; the built-in Explore and Plan agents skip them.
- `@path` imports are expanded **eagerly** at launch — they save nothing, and are not used here.
- A subdirectory `CLAUDE.md` loads when Claude reads files in that subtree (not chosen: see §9).

## 3. Decisions (made with the user, 2026-09-22)

1. **Target:** `CLAUDE.md` under 40,000 characters.
2. **Mechanism:** path-scoped rules in `.claude/rules/` — the loading trigger is mechanical (reading a matching file), which is what `workflows-core:instruction-file-maintenance` asks of a pointer: an observable trigger, never one the agent must judge.
3. **Evidence:** three tiers (§4); evidence moves, it is not deleted.
4. **Regrowth:** a gate fails the build above 40,000 characters (§7).

## 4. The three tiers

**Tier 1 — `CLAUDE.md`, always loaded, target 28–32k, hard cap 40k.** Every rule that applies across the repository, each stated once, with at most one sentence of why and a link to its evidence. Contents:
- What the repo is, structure, adding a plugin (as today).
- One paragraph per plugin: what it ships and what it depends on — no per-command prose (that is each plugin's `docs/` and tier 2).
- The internal reference convention (agents by `subagent_type`; shared references through `workflows-core:reference`; `${CLAUDE_PLUGIN_ROOT}` behaviour; no hardcoded cache paths).
- **Editing discipline** — the rules that bind every edit anywhere: prose is executed; the claim-expiry rule and its sweep (the eight refinements as one line each); the sentence-context rule (extent and pointer faces); measure the population before designing a fix; resolve an identifier against a known set; re-measure in one place and cite it everywhere else; a recipe that returns a wrong answer is worse than none; the drift-risk rule; a verification record is written last.
- **Hard constraints**, one line each with its gate: description budget (1024); `[PREFIX#N]` ID grammar; vendor neutrality and its marker; identity quarantine; `choices:` arity 2–4 and no authored Other; mermaid label quoting.
- How to run the gates (the chain, read the printed exit code) — the gate list itself is `.github/workflows/validate-catalog.yml`'s.
- Taxonomy (commands orchestrate, agents execute, skills inform) and the model-routing pointer.
- An **index of shared authorities**: one line per reference that is a single source of truth, naming what it owns — replacing the 17 paragraphs, whose contracts each reference file already states.
- Git rules (verify branch before commit; worktree, never checkout; never bare stash) and a condensed *Updating installed plugins*.

**Tier 2 — `.claude/rules/<area>.md`, loaded by `paths:`.** Rules that matter only while editing that area:

| File | `paths:` | Holds |
|---|---|---|
| `gates.md` | `scripts/**`, `.github/**` | What each `check-docs.sh` check gates and cannot see (checks 1–18), the mermaid gate, the id-grammar selftest design, `validate-catalog.py`, check-11/12/13/16/17/18 scope decisions *as rules*. |
| `product-workflows.md` | `plugins/product-workflows/**` | PRD-creation-flow and BRD-route invariants (slice kind, PRD eligibility, the sibling re-cut, route detection, addressing §7 counts), those commands' workflow-map lines and agent callers. |
| `dev-workflows.md` | `plugins/dev-workflows/**` | Code-command and `/implement` invariants, the test-writing requirement, those commands' map lines. |
| `docs-workflows.md` | `plugins/docs-workflows/**` | `/document` (both modes), `/release-notes`, docs-grounding invariants, the docs-family map lines (including `/docs-serve`'s). |
| `workflows-core.md` | `plugins/workflows-core/**` | specs-repo-git and phase-handoff invariants, model-routing detail, the shared agents' caller lists, `/frames`. |

A rule that belongs to two areas goes in tier 1, not in both files — two copies is how two lists come to disagree.

**Tier 3 — `docs/maintainers/rationale.md`, never auto-loaded.** The evidence, one anchored section per rule (`## <rule-slug>`), each rule in tier 1 or 2 ending in `([why](docs/maintainers/rationale.md#<rule-slug>))`. Evidence is moved verbatim where it is still true; where it cites a line number or a count that has since moved, it is marked *as of <commit>* rather than silently re-derived.

## 5. Moving text: the rules

1. **Every block moves; nothing is dropped silently.** The implementation takes a block inventory of `CLAUDE.md` on its base commit (a *block* = one paragraph, one list item, one fenced block; 186 at `e22a6ee4`) and gives **every block exactly one row** in a move table: `block id | lead words | destination tier/file | split? | notes`. A block split between tiers (rule to tier 1, evidence to tier 3) says which sentences went where.
2. **A narrowing is a deletion** (`workflows-core:instruction-file-maintenance`). Compressing a rule to one line must keep every clause that constrains behaviour; a clause that is dropped is listed in the move table as a deletion with its ground. "It looks derivable" is not a ground.
3. **Rule text is not paraphrased where it is load-bearing.** A rule's operative sentence moves as written; compression removes evidence, history and repetition around it.
4. **Stale is not moved.** A sentence found false while moving is fixed on the way (and listed), never carried into a new file.
5. **Inbound citations follow the text.** Every file that cites a `CLAUDE.md` section by name or quotes it (scripts' comments, plugin files, `docs/superpowers/` records that are live) is re-pointed; the plan measures that set first. Historical records are left as history.

## 6. What changes outside the three files

- `check-docs.sh` **check 13** scans `CLAUDE.md` for unmarked tracker names; its scope gains `.claude/rules/*.md` and `docs/maintainers/*.md`, or moved text escapes the gate. Its marker census recipe (`grep -rn --exclude=CHANGELOG.md vendor-token-ok: plugins CLAUDE.md`) widens with it. Selftest: a red/green pair for each new surface.
- `check-id-grammar.sh` already recurses every `*.md` under the root; the plan verifies `.claude/rules/` and `docs/maintainers/` are inside its scan and not in an exclusion.
- Check 14 (identity quarantine) already covers the whole repository.
- The mermaid gate covers tracked markdown; any diagram moved stays gated.

## 7. The size gate

A new check — in `scripts/validate-catalog.py`, beside the description budget it already enforces, with `--selftest` cases — **fails** when `CLAUDE.md` exceeds **40,000 characters** and **warns** above **36,000**; **warns** when any `.claude/rules/*.md` exceeds **20,000**. Characters, not bytes or lines: the budget is about context, and line count is meaningless in a file of unwrapped paragraphs. The failure message names the file, the size, and where overflow belongs (tier 2 or tier 3). `CLAUDE.md`'s own sentence about the gate says the number once.

## 8. Verification

- The move table accounts for every block on the base inventory (count rows = count blocks).
- A **rule census**: every bold-led rule sentence of the base `CLAUDE.md` is found, wrap-insensitively, in tier 1 or tier 2, or is listed as a deletion with a ground.
- All gates green, including the new size check and the widened check 13, each with selftest cases proving the new surface fires.
- A **loading probe**: a fresh subagent told only to read `plugins/product-workflows/commands/brd-split.md` and then quote the sibling re-cut invariant can do so; one told to read only `README.md` cannot (proves the scoping, both directions).
- `wc -c CLAUDE.md` recorded before and after in the verification record, written last.

## 9. Alternatives rejected

- **Nested `plugins/<name>/CLAUDE.md`:** rules spanning plugins have no home, and the files would ship inside public plugin directories.
- **Maintainer docs behind pointers only:** nothing loads them; adherence rests on the agent choosing to read.
- **Evidence kept beside each rule in tier 2:** most work reads `plugins/**`, so the heavy files would load on nearly every task.
- **Dropping evidence:** contradicts the itemised-deletion rule, and the evidence is what stops re-litigation.

## 10. Known risks

- **Trigger gap:** a path rule loads when Claude *reads* a matching file. A session that only runs `git diff` or `grep` through Bash does not load it. Mitigated by keeping every repo-wide rule in tier 1; tier 2 holds only rules needed while editing that area, where the file is read before it is edited.
- **Drift between tiers:** a rule restated in tier 1 and tier 2 would drift. Forbidden by §4's placement rule; the rule census (§8) checks for duplicates as well as losses.
- **Anchor rot:** tier-3 anchors are slugs, not line numbers; the plan adds a link check over `CLAUDE.md` and `.claude/rules/` if `check-docs.sh`'s link checker does not already reach them.

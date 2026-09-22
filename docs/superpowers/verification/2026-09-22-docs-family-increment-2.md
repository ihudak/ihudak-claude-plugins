# Verification record — documentation-workflow family, increment 2 (`/docs-audit`)

Branch `iv-gu/docs-audit`, cut from `main` at `9e6764ee`. Releases **docs-workflows 1.3.0** and **workflows-core 1.7.2**.

Written **after** the final fix wave, per `CLAUDE.md` — three of the 2026-08-07 round's records went stale because they were written first, and one was falsified by its own sub-project's next commit seventeen minutes later.

---

## What was verified, and how

Eight tasks, each implemented by a subagent working from an extracted brief, each followed by an independent review with no access to the implementer's reasoning. **Five of the eight reviews returned `BLOCK`.** Every blocker is recorded below with what it would have cost, because a record that lists only the outcome teaches nothing about whether the method was worth its price.

The verification instrument here is **not** a test suite — this repository has none. It is:

1. **The nine CI gates**, run as one `&&` chain whose own printed status is read. Baseline at branch start: `GATES_EXIT=0`, 198 `ok`, 5 `SELFTEST PASS`, 36 mermaid blocks in 579 tracked files. At release: **`GATES_EXIT=0`, 199 `ok`, 5 `SELFTEST PASS`, 40 mermaid blocks in 594 tracked files.** The `ok` moved by exactly one — Task 5's fixture-growing case — and the mermaid blocks by four, the diagrams this increment added.
2. **Adversarial review per task**, against the design section that task implements, with the reviewer told to hunt specifically for *reachable states the prose does not dispose of*. **Four of the five blockers were in that category.**
3. **Re-derivation of every count by the orchestrator**, never taken on an implementer's report.

---

## The five blockers, and what each would have cost

| # | Task | The defect | What it would have cost |
|---|---|---|---|
| 1 | Coverage model | A hard rule forbade an unverified page from being an `exists` cell, while the same file fixed the vocabulary at `exists \| missing \| stale` and defined `missing` as *asserting a page does not exist*. | An existing-but-unverified page was **no state at all**, in the file six later tasks read as the vocabulary root. The command would have had to invent a fourth state or mark a written page `missing`, after which the writing step re-writes a page that is already there. |
| 2 | Backlog schema | The evidence contract guaranteed a marked page's unit cannot reach `published`; the schema's own `missing → published` refresh edge fired with **no marker test**. | A person writes a page by hand, leaves a `[NEEDS CLARIFICATION]` in it — the docs page *teaches* that marker — tags it with the unit id, and the next refresh publishes it. **Coverage goes green over prose nobody checked**, by a command shipping in this increment. |
| 3 | The two agents | `ia-planner`'s third prioritisation signal read `gap_summary`, a field that exists only on `docs-auditor`'s *input* and in its `notes` — and `notes` is not an `ia-planner` input. | One of the four signals the reviewer agent checks **every** `priority_reason` against could not be evaluated at all. Every unit's reason would have asserted the same thing or cited an invented value. |
| 4 | The command | Five of seven stop paths ended the run before the emitter tail, while Phase 9 asserted cost *always* runs and named two of those five. | No cost entry, no feedback entry, and **no `commit-artifacts`** — breaking the family invariant binding every command that writes into `$SPECS_PATH`. |
| 5 | The route page | Step 5 sent every screenshot to `images.root`, one step after step 4 taught the reader to put internal pages under `docs/internal/`. | **A content leak.** `visibility.md`: *"A file under `images.root` is copied into both builds whether or not any page references it: MkDocs copies the content tree, it does not trace references."* An internal screenshot ships publicly, and **neither CI gate fires** — gate 1 finds no cross-link, gate 2 greps for a marker and an image carries none. |

The route page carried a **second** blocker of the same shape: it correctly said a surviving marker *"stays marked and ships marked"*, then unconditionally, in the next sentence, told the reader to set the unit `verified` and then `published` — against the schema's *"NEVER mark a unit `published` on a page carrying a marked claim"*.

**Blockers 5 and its sibling are reachable only by a person following prose, and catchable by no gate in this repository.** That is the argument for having reviewed the human-facing page as hard as the executable ones.

---

## What the design itself got wrong, found by building against it

The 2026-08-29 design was not a reliable description of the tree it now targets. Five defects in it were found and disposed of:

- **`code-scanner` confirms themes; it does not discover them.** It refuses to run without `capability_themes` and returns a classification per *supplied* theme. A literal reading of §11 Phase 2 dispatches a scanner with nothing to look for. Resolved by making the seven **surface kinds** the seed themes — §5.1's *derived from* column is already written as the phrase a scanner needs.
- **§11 has no phase that reads `$SPECS_PATH`**, yet two of §5.1's seven surface kinds come from there, and the shipped `scaffold-tree.md` had *already* committed this command to that read. Added as Phase 2.5.
- **§8.6 calls `visibility` "the key the two-build split reads". It is not** — the shipped split decides by **path**. So a unit marked internal whose `page_path` falls outside `docs/internal/` ships publicly with no build objecting. Now an invariant in the schema and a reviewer dimension.
- **The design contradicts itself on the unit status enum** — five values in its frozen-contracts section, six in its own process-capture lifecycle (`captured`). This increment follows the five and adds the rule that makes the eventual addition cheap: an unrecognised `status` is a later spec's addition, reported and left alone, never called corruption.
- **`classification` §8.5 is opt-in**, with a consumer list naming two other commands — and three further paragraphs inside it are caller-scoped and each enumerated exactly two callers. A `§`-existence check passes here, because the section exists and says something true *about somebody else*.

---

## What is NOT verified

Stated plainly rather than papered over. This is the half of a verification record that has value.

1. **No command body was executed.** Nothing in this environment can run `/docs-audit`, dispatch its agents, or exercise `/docs-brand`'s changed rung. Every behavioural claim in this increment is **specified and reviewed, never run.** The first real invocation is the first execution.
2. **The gates prove structure, not behaviour.** They check inventories, counts, link resolution, table widths, `choices:` arity, the loader contract and mermaid parsing. **No gate reads a command body for sense.** Every defect in the table above passed every gate.
3. **Check 9 gates only the first matching phrase per file** (`head -1`), so a count below another match in the same file has never been checked. The obvious fix — fail on a second match — was measured and **refused**: eight files on a clean tree already carry more than one, so it would fire only on correct content. Recorded as an authoring rule in the check's own comment. A hunt across every `docs/` page in this plugin found the surviving second counts correct, but **this is a gap in the gate, not a clean bill for the repository.**
4. **`/docs-brand` rung 2's new behaviour is specified, not exercised.** Task 3 made a `/docs-init`-written profile carry `source_repos[]`, which stops that rung being a pass-through; the command body was corrected to match. Nothing here can prove the corrected body behaves as written.
5. **The pre-existing `— Unreleased` 1.2.2 changelog section was swept for this increment's three subjects but not re-read end to end** against today's tree. It concerns `/document` and `/release-notes`, neither of which this increment touched.
6. **The `prep`-dispatcher count of nine is derived for the relation its sentence states**; the provenance of the "eight" it replaced was not reconstructed, and a naive dispatch grep returns seven. The number is right for the stated relation; the old one's derivation is unknown.

---

## Method notes worth carrying to the next increment

- **Every one of the eight implementers found a real defect in its own brief.** Six were the same shape — **a binary asserted over a state space with three or more members** (two report arms where a cancellation gives three; `classification` has four values, not two; `images.policy` has three policies, not one; §8.5 is four sites, not one). Naming the pattern in later briefs made implementers hunt for it and they kept finding it.
- **One brief defect was a different and worse shape: describing a file from a *plan* that said what would be built, rather than from the file.** The plugin README was asserted to carry a three-command mermaid diagram and a sentence about later stages; it had **zero** mermaid blocks and that sentence appears nowhere in its history. The implementer took the intent, built it, and declined to write false provenance into the commit.
- **Four fix rounds caught a neighbour-falsifying claim in their own output before committing** — the shape `CLAUDE.md` warns is likeliest exactly when someone is being careful about a rule they have just been shown to have got wrong.
- **Two agents in one worktree makes a green gate chain unprovable.** One fix round's first chain ran green over a *mixed* tree; the implementer noticed, re-ran in a throwaway worktree detached at its own commit, and staged by explicit path rather than `git add plugins/`. Scheduling error on the orchestrator's part; the final task ran alone.
- **Three defects older than this increment were found and fixed in passing**: `docs-scaffold-reviewer`'s verdict rule was not a partition (a lone MINOR satisfied both `PASS` and `PASS WITH RECOMMENDATIONS`); check 17's header denominator had rotted 40 → 44; and a `dev-workflows` page asserted a stale agent count about `docs-workflows`.

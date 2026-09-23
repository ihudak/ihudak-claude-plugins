# Decision-Cycle Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the seventeen decision-cycle defects in the spec's §3, so that `main` reaches zero known bugs and can be pushed together with the CLAUDE.md split.

**Architecture:** Every fix is a text change to executed prose: command, reference and agent bodies, plus their `docs/` pages. There is no program code. Tasks are grouped by the file they mostly edit, so no two tasks edit the same passage, and they run in order.

**Tech Stack:** Markdown prose, executed by Claude Code agents. Gates are bash, Python 3.11 and Node scripts under `scripts/`.

**Spec:** `docs/superpowers/specs/2026-09-23-decision-cycle-lifecycle-design.md` (commits `9095ad34` and `e21db9f5`). Read the section your task names. The spec is the authority, and this plan argues from it.

## Global Constraints

- Work only in the worktree `/home/ihudak/dev/ai-tools/ihudak-claude-plugins/.worktrees/decision-cycle`, on branch `iv-gu/decision-cycle`.
  - **Read the worktree's `CLAUDE.md`, not the one in your context.** A subagent's context carries the main checkout's copy.
  - Before editing in an area, open one file there with the **Read tool**. Only the Read tool loads the path-scoped `.claude/rules/*.md`. The areas are `plugins/product-workflows/**`, `plugins/workflows-core/**` and `plugins/docs-workflows/**`.
- **Prove the defect before you fix it.** Quote the current text (file:line) and show it is literally false, or that two live sentences contradict each other.
  - If the sentence turns out to be true in its context (scoped-true: a neighbouring sentence or the file's own vocabulary supplies the scope), **stop and report `NEEDS_CONTEXT`** with the evidence. Do not "improve" it.
  - One unit of this pass has already been dropped for exactly this reason.
- **Match by phrase, never by line number.** Spec line numbers are finding aids, taken at `2998b4df`.
- Claim-expiry sweep (`CLAUDE.md` *Editing discipline*, refinements 1–8), over the scope in refinement 4:
  - `plugins/`, every `CHANGELOG.md` included (read only; history is never rewritten);
  - the repo-root `README.md`, `CLAUDE.md`, `.claude/rules/` and `docs/maintainers/`.
- **Refinement 7 count, for every string you change.** Count it before and after the edit, wrap-insensitively, with the script in *Tools* below, and record both counts and the command in your report.
- One noun across every copy of a claim. The spellings fixed by this plan:
  - `- **Re-puts:**`
  - `PRD_GROUND_CLAIMS_INVENTORY_MISMATCH`
  - `DOCUMENT_BRD_NOT_SLICED`, `DOCUMENT_FOLDER_NOT_PLACED`, `DOCUMENT_NO_PRD`
  - `RELEASE_NOTES_BRD_NOT_SLICED`, `RELEASE_NOTES_FOLDER_NOT_PLACED`, `RELEASE_NOTES_NO_PRD`
- **Every `choices:` array has 2–4 options and no "Other"** (check 12). Present choices verbatim.
- Never write a literal `](` inside backticks. Check 1's link checker does not skip code spans.
- Vendor neutrality: name no tracker (check 13). Use `[PREFIX#N]` IDs only (check-id-grammar).
- Wrap prose the way the file you edit wraps it. Command bodies are hard-wrapped at about 100 columns, and some docs pages are not wrapped.
- No new files, except the verification record in Task 9.
- **Commits:**
  - Run `git branch --show-current` immediately before each commit and expect `iv-gu/decision-cycle`.
  - Write the message to a file and use `git commit -F <file>`.
  - End the message with these two lines, verbatim:
    ```
    Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
    Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
    ```
- **Never bare `git stash`.** Never `git checkout` in the main checkout.
- **Implementers never dispatch subagents.**
- **Brief-defect warning.** In an earlier increment, every implementer found a defect in its brief, and most were one shape: a binary asserted over a state space with three or more members. Hunt for it in your task. For every "or" and every enumeration, ask what the third member is.

## Tools

The gate chain. It is the CI list, in order. Run it unpiped and read the printed exit code:

```bash
cd /home/ihudak/dev/ai-tools/ihudak-claude-plugins/.worktrees/decision-cycle && \
npm ci --prefix scripts/mermaid --ignore-scripts --no-audit --no-fund >/dev/null && \
python3 scripts/validate-catalog.py --selftest && \
uv run --python 3.11 python scripts/validate-catalog.py && \
./scripts/check-id-grammar.sh --selftest && \
./scripts/check-id-grammar.sh --root . && \
./scripts/check-docs.sh --selftest && \
./scripts/check-docs.sh --root . && \
node scripts/mermaid/check-mermaid.mjs --selftest && \
node scripts/mermaid/check-mermaid.mjs --root . && \
python3 "$(find plugins -type f -name session-cost.py)" --selftest; echo "EXIT=$?"
```

Expected: `EXIT=0`. `npm ci` is a setup step and is not one of the nine gates.

The wrap-insensitive literal count (refinement 7). It collapses whitespace in both the files and the needle, and prints the hits per file with a source line for each:

```bash
python3 - "$NEEDLE" <<'EOF'
import sys, re, pathlib
needle = re.sub(r'\s+', ' ', sys.argv[1]).strip()
roots = ['plugins', 'README.md', 'CLAUDE.md', '.claude/rules', 'docs/maintainers']
total = 0
for r in roots:
    p = pathlib.Path(r)
    files = [p] if p.is_file() else sorted(p.rglob('*.md')) if p.exists() else []
    for f in files:
        raw = f.read_text(encoding='utf-8')
        idx, flat, pos = [], [], 0
        for m in re.finditer(r'\s+|\S+', raw):
            t = ' ' if m.group().isspace() else m.group()
            for ch in t: flat.append(ch); idx.append(m.start())
        s = ''.join(flat); k = s.find(needle)
        while k != -1:
            total += 1
            print(f"{f}:{raw.count(chr(10), 0, idx[k]) + 1}")
            k = s.find(needle, k + 1)
print("TOTAL", total)
EOF
```

Run it from the worktree root with `NEEDLE='<exact string>'`.

## Review Focus

These are the inputs most likely to bite an operator, and no gate exercises them. Each is pinned to the task that owns it, as a scenario trace in that task's report.

1. **A crash between Phase 9's first write and its second** leaves `customer-questions.md` entries with no round record. The next run must replace them, never duplicate them (Task 3).
2. **A reopened record whose re-put question is itself deferred, then resumed in a later run.** It must not be re-put a second time while in flight (Task 4).
3. **A corrected resend that repeats an answer but changes only its reason.** It must supersede, never skip (Task 6).
4. **`/prd-ground` on a slice whose parent carve was cancelled mid-walk, after the operator committed the slice's files anyway.** It must stop, never ground (Task 1).
5. **`/create-prd` on a folder whose `prd.md` has frontmatter but no `kind:`, reached with `--from-prd` or on the BRD route**, which bypasses Phase 1's redirect. The Phase 5 guard must still archive it (Task 7).

---

### Task 1: `/prd-ground` gates and field list (spec §6 C2, §7 D1–D2; items viii, ix, xi, N5)

**Files:**
- Modify: `plugins/product-workflows/commands/prd-ground.md`, with three edits:
  - Phase 0 step 6, the gate order, near the text "gate this BRD's own inventory and ledger on main";
  - the `PRD_GROUND_NOT_HANDED_OFF` clause, near "the parent's ledger fully allocated";
  - Phase 8's closed field list, near "and nothing else".
- Modify: `plugins/product-workflows/commands/brd-split.md`: one sentence in Phase 4 Step 2's `Cancel` paragraph, near "stops the run naming how many rows remain".
- Modify: `plugins/product-workflows/docs/commands/prd-ground.md`.

**Interfaces:**
- Produces: the stop name `PRD_GROUND_CLAIMS_INVENTORY_MISMATCH`. Task 9 cites it in the CHANGELOG.

- [ ] **Step 1: Prove each defect.**
  - Quote Phase 8's parenthetical and `grounding-format.md` §2's `prerequisite` row (viii).
  - Quote step 6's two `require-on-main` calls and the "Where the folder holds no `coverage-ledger.md`, do not print this stop" cross-reference (ix).
  - Quote the "parent's ledger fully allocated" clause and BS's `Cancel` paragraph (xi).
  - Show that nothing in PG compares `claims:` with the inventory. Run `grep -n "claims:" plugins/product-workflows/commands/prd-ground.md` and read every hit (N5).
- [ ] **Step 2: Count before editing.** Run the literal count for each of these needles:
  - `and the parent's ledger fully allocated`
  - `` plus `prior_verdict` on every finding reading `SUPERSEDED` ``
  - `PRD_GROUND_CLAIMS_INVENTORY_MISMATCH` (expect `TOTAL 0`)
- [ ] **Step 3 (viii).** In Phase 8's parenthetical, insert this clause directly after the `prior_verdict` clause:
  `` `prerequisite` on every finding reading `horizon: will-change`, ``
  Then run `` grep -rn "`id`, `claim`, `verdict`" plugins/ `` and confirm this is the only re-enumeration of the list.
- [ ] **Step 4 (ix).** At the start of step 6's gate text, state the order in the file's idiom. It must carry four points:
  - `coverage-ledger.md`'s `require-on-main` resolves first, including, on its row F, whether the file is in the folder at all;
  - `brd/brd-inventory.md`'s gate is evaluated, and its stop printed, only after that;
  - where both gate returns stop, the ledger's stop is the one printed;
  - the reason: the ledger's row-F branch (a) disposes of an inventory an interrupted carve left behind.

  Keep the existing "Where the folder holds no `coverage-ledger.md`" cross-reference, and make it cite the new order sentence.
- [ ] **Step 5 (xi).** In `PRD_GROUND_NOT_HANDED_OFF`, before the branch on the slice's own `claims:`, add a read of `<PARENT-KEY>`'s `coverage-ledger.md` from the worktree. Reuse the phrasing this file already uses where another remedy reads the parent's ledger; find it with `grep -n "parent's .coverage-ledger" plugins/product-workflows/commands/prd-ground.md`.
  - **Any row reading `unallocated`:** a new first clause fires in place of both existing clauses. Its message text:
    `The parent <PARENT-KEY>'s carve is incomplete: its ledger still holds unallocated rows, so /product-workflows:brd-split <PARENT-KEY> was interrupted before it finished. Re-run it — it resumes the walk and may still change this slice's files — and commit nothing here until that run completes.`
  - **No row reading `unallocated`:** today's two clauses stand unchanged.
  - **Hunt the third member:** the parent's `coverage-ledger.md` may be unreadable or absent in the worktree. Decide what the clause says then, state it, and justify the choice in your report.
- [ ] **Step 6 (N5).** On `route: brd`, add a consistency gate that runs after both `require-on-main` gates pass. It compares two sets:
  - the `[BR#n]` ids in the slice's `brd-link.md` `claims:`;
  - the `[BR#n]` ids in the rows of `brd/brd-inventory.md`.

  Where the sets differ, stop with:
  `PRD_GROUND_CLAIMS_INVENTORY_MISMATCH: <SLICE-KEY>'s brd-link.md claims [ids] that its brd/brd-inventory.md does not hold, and its inventory holds [ids] it does not claim. /product-workflows:brd-split <PARENT-KEY> reconciles the three files when its walk completes (Phase 4 Step 3); run it to completion and re-run this command.`
  - Print only the half that is non-empty.
  - The gate must resolve ids against the two sets. It never parses prose.
  - Decide whether a non-`route: brd` run can reach it. It must not.
- [ ] **Step 7 (BS).** In BS Phase 4 Step 2's `Cancel` paragraph, append one sentence: each slice's `brd-link.md`, `brd/brd-inventory.md` and `coverage-ledger.md` stay provisional until Step 3 reconciles them, and `/product-workflows:prd-ground` refuses a slice until then.
- [ ] **Step 8: docs page.** Document the gate order, the incomplete-carve clause and the new stop in `docs/commands/prd-ground.md`, where that page lists stops. Derive from the command you just edited.
- [ ] **Step 9: Count after editing.**
  - `PRD_GROUND_CLAIMS_INVENTORY_MISMATCH`: expect 1 hit in the command and 1 on the docs page, TOTAL 2.
  - `and the parent's ledger fully allocated`: expect the same count as before, since the clause stands for the no-`unallocated` case.
  - Record every count.
- [ ] **Step 10: Scenario traces**, in the report. Walk the research's interruption points IP1–IP6 against the new text and cite the clause that fires for each:
  - IP1–IP2: branch (a);
  - IP3–IP4: the new incomplete-carve clause;
  - IP5: `PRD_GROUND_CLAIMS_INVENTORY_MISMATCH`;
  - IP6: today's clause.

  The IP table is in `/tmp/claude-1000/-home-ihudak-dev-ai-tools-ihudak-claude-plugins/eca918d8-f7c1-43c4-b7da-5479c07b5d88/scratchpad/research-ground-split.md`, section (xi)(b). Also walk Review Focus item 4.
- [ ] **Step 11: Gates.** Run the gate chain. Expect `EXIT=0`.
- [ ] **Step 12: Commit.** Message: `prd-ground: gate order, incomplete-carve clause, claims/inventory gate, prerequisite field (viii, ix, xi, N5)`.

### Task 2: A `contradict` on an on-file finding becomes a supersession (spec §6 C1; item vii)

**Files:**
- Modify: `plugins/workflows-core/references/grounding-format.md`: §2.1, §6.3 and §8.
- Modify: `plugins/product-workflows/commands/prd-ground.md`: Phase 7's `contradict` handling, the class-4 trigger, and Phase 8's SUPERSEDED writing.
- Modify: `plugins/product-workflows/references/decision-register-format.md`: §4, cause 1.
- Modify, where the sweep finds copies: `plugins/product-workflows/docs/commands/prd-ground.md`, `plugins/product-workflows/docs/brd-workflow.md` and `plugins/product-workflows/docs/commands/brd-interview.md`.

**Interfaces:**
- Consumes: Task 1's edits to `prd-ground.md`. Different passages; rebase nothing.
- Produces: the term **on-file finding**, meaning a finding already written under the slice's `grounding/` before this invocation. Its opposite is an **own-run finding**. Use these two nouns everywhere.

- [ ] **Step 1: Prove it.**
  - Quote PG's rewrite rule ("the finding is rewritten, and the rewrite retains the same id").
  - Quote PG's inherited-finding verification scope ("any pre-existing ones a `--rebaseline` pass is re-checking" and the `inherited` bullet).
  - Quote DRF §4 cause 1 and GF's `prior_verdict` definition.
  - Walk the research's scenarios A, B and C (`research-lifecycle.md`, item vii (b)) against the current text, in the scratchpad path above.
- [ ] **Step 2: Enumerate every statement of the claim** "a `contradict` rewrites in place / the id never changes, so every existing citation into it still resolves". Record each site:
  - by subject: `grep -rn -i "contradict" plugins/ --include=*.md`, then read every hit;
  - by the literal needle `The id never changes` with the counter.
- [ ] **Step 3: PG Phase 7.** Split the `contradict` handling in two:
  - **Own-run finding:** today's in-place rewrite stands.
  - **On-file finding:** the on-file block takes `verdict: SUPERSEDED`, keeps the on-file verdict as `prior_verdict`, and gains a note naming the successor. A new finding is appended with the next free id in its prefix. It carries:
    - `claim`, `commit`, `altitude`, `horizon`, and `prerequisite` where present, all copied from the on-file block;
    - the verifier's `own_verdict` as `verdict` and `own_evidence` as `evidence`;
    - `control` where the verifier returns one;
    - `outcome: contradict`;
    - a note `supersedes [CG#n]` (or `[DG#n]`).
  - Narrow "the id never changes, so every existing citation into it still resolves" to own-run findings.
  - **Hunt the third member:** a finding that is on file *and* re-produced by this invocation. Read PG's `inherited` and reproduction rules and state which branch it takes.
- [ ] **Step 4: Cascades.**
  - Move the class-4 `[DG#n]` handling for an on-file `contradict` onto Phase 8's existing rule, under which superseding a `[CG#n]` supersedes every class-4 `[DG#n]` citing it. Keep the in-place class-4 trigger for own-run findings only.
  - Trace how `--rebaseline` treats the coverage ledger's `evidence` column and the `consumed_by` stamps for a superseded id, and apply the same treatment. Cite the lines in your report.
- [ ] **Step 5: GF.**
  - In §2.1, narrow "§8's `contradict` handling has already replaced `verdict`" to own-run findings.
  - In §6.3, name both routes by which a cited finding's verdict changes: an in-place `contradict` on an own-run finding, and supersession (by `--rebaseline`, or by `contradict` on an on-file finding).
  - In §8, add the on-file branch to the outcome table and the text.
  - Re-read GF's `prior_verdict` definition and its rationale paragraph. Both should now be true unchanged; confirm it.
- [ ] **Step 6: DRF §4 cause 1.** Append:
  `` A verifier's `contradict` on an on-file finding is recorded as a supersession (`workflows-core:grounding-format` §8), so it reaches this cause like any other supersession. ``
- [ ] **Step 7: BI observation check (read only).** Confirm that BI's successor tests 1–4 (near "A decision the re-grounding moved") accept the new successor: same prefix, same claim, same pin, higher id. Confirm that its plain-record test compares against `prior_verdict`. Cite the lines. If any test fails for this successor, stop and report `NEEDS_CONTEXT`.
- [ ] **Step 8: Sweep.** Rewrite every site from Step 2 against the new rule. Docs pages say "in place" only for own-run findings.
- [ ] **Step 9: Count after editing.** Re-run the Step 2 needle. Every remaining hit must be scoped to own-run findings; list each. Count `on-file finding` and report where it appears.
- [ ] **Step 10: Scenario traces.** Walk scenarios A, B and C against the new text, and cite the rule where each now resolves: A reopens, B is not duplicated, C compares against the original verdict.
- [ ] **Step 11: Gates.** Expect `EXIT=0`.
- [ ] **Step 12: Commit.** Message: `grounding: contradict on an on-file finding supersedes it (vii)`.

### Task 3: `/brd-interview` writes nothing before Phase 9 (spec §4 A1, A3; items ii, N2, iv)

**Files:**
- Modify: `plugins/product-workflows/commands/brd-interview.md`, in these places:
  - the Phase 7 step headed *Hold every `[C]`*;
  - *One question per row*'s defect-line append;
  - Phase 6's abort paragraph;
  - Phase 8's `Cancel` paragraph;
  - Phase 9's write list;
  - the Phase 0 step that reads `customer-questions.md`;
  - Phase 12's key events.
- Modify: `plugins/product-workflows/docs/commands/brd-interview.md`: re-read it, and edit only where the sweep requires.

**Interfaces:**
- Produces:
  - Phase 9 as the only writer of `interview/customer-questions.md`, `interview/round-<N>.md` and `decisions.md`, in that order;
  - the idempotency rule keyed on the heading `## Round <N>, question <position>`.

  Tasks 4 and 5 edit other BI passages and must not re-introduce a pre-Phase-9 write.

- [ ] **Step 1: Prove it.**
  - Quote Phase 7's write.
  - Quote Phase 8 `Cancel`'s "Two things are already on disk by then and stay".
  - Quote Phase 6's abort caveat.
  - Quote the docs page's "Cancel on this picker writes nothing".
  - Quote Phase 12's "a cancelled `[V]` queue" and the `[V]` picker's "There is no listed `Cancel`".
- [ ] **Step 2: Count before editing.** Needles:
  - `already on disk`
  - `` a cancelled `[V]` queue ``
  - `writes nothing`
- [ ] **Step 3 (ii).**
  - Phase 7 builds each held `[C]` entry in memory. It keeps the same fields and the same heading, and writes nothing.
  - *One question per row*'s defect-line append is held in memory the same way.
  - Phase 9 writes `customer-questions.md`, then `round-<N>.md`, then `decisions.md`.
  - Idempotency: an entry is written only where no entry with its heading exists, except that where round N has no `interview/round-<N>.md`, entries headed with round N are this run's to rewrite in place. A defect line is appended only where the entry does not already carry that `[DEF#n]`.
  - Delete the two "already on disk and stay" caveats. Say instead that a Cancel or an abort writes nothing into the BRD folder.
  - **Hunt the third member:** a *resumed* round, whose `round-<N>.md` already exists and which gains a newly re-tagged `[C]`. State what Phase 9 writes for it.
- [ ] **Step 4: Legacy strays.** In the Phase 0 step that reads `customer-questions.md`, report every entry whose heading names a round with no `interview/round-<N>.md`. Name each one, delete nothing, and say that a run opening that round rewrites them.
- [ ] **Step 5 (iv).** Delete "a cancelled `[V]` queue, " from Phase 12's key events. Leave the *Session cost* heading alone: the spec's Unit F was dropped.
- [ ] **Step 6: Sweep.** Re-read BI's other statements of the write timing against Phase 9 as the only writer, and fix any that say Phase 7 writes. Find them with `grep -n "customer-questions" plugins/product-workflows/commands/brd-interview.md` and read every hit. They include the "An addition is not a rewrite" clause, the "this run holds, `/brd-package` carries" paragraph, Phase 9's deliverable list, and Phase 10's `deliverable_paths`. Re-read the docs page's Cancel sentence and confirm it is now true.
- [ ] **Step 7: Count after editing.**
  - `already on disk`: expect only hits unrelated to `customer-questions.md`, each listed and justified.
  - `` a cancelled `[V]` queue ``: expect TOTAL 0 outside `CHANGELOG.md`.
- [ ] **Step 8: Scenario traces.** Walk research item ii (b)'s five wrong states and Review Focus item 1, and cite where each now resolves.
- [ ] **Step 9: Gates.** Expect `EXIT=0`.
- [ ] **Step 10: Commit.** Message: `brd-interview: hold [C] entries until Phase 9; drop dead key event (ii, N2, iv)`.

### Task 4: A question source for a reopened record, and the structured re-puts marker (spec §4 A2; items iii, N1)

**Files:**
- Modify: `plugins/product-workflows/commands/brd-interview.md`, in these places:
  - Phase 2's question sources;
  - the *Every round is closed* branch;
  - the round-record question format;
  - Phase 6's re-decision rule;
  - Phase 11's `nothing-to-review`.
- Modify: `plugins/product-workflows/references/decision-register-format.md`, where it describes re-decision ("or by a later one"); re-read it.
- Modify where the sweep finds copies:
  - `plugins/product-workflows/docs/commands/brd-interview.md`;
  - `plugins/product-workflows/docs/commands/brd-reconcile.md`;
  - `plugins/product-workflows/docs/workflow.md`;
  - `plugins/product-workflows/docs/brd-workflow.md`;
  - `plugins/product-workflows/commands/brd-reconcile.md`, re-read only unless a claim is false;
  - `plugins/product-workflows/commands/create-ard.md` and `specify.md`, re-read only.

**Interfaces:**
- Consumes: Task 3's rule that Phase 9 is the only writer.
- Produces:
  - the line `- **Re-puts:** [VD#n]` (or `[CD#n]`) on every question in a round record that re-puts an existing record;
  - the **in flight** test.

  Task 6 relies on BR reading `- **Re-puts:**` from `[C]` entries, which is unchanged.

- [ ] **Step 1: Prove it.**
  - Quote BI's "raises nothing by that move alone" (both sites).
  - Quote BR step 3's `reopened` write, the sweep's `reopened` row, and BR's "Work another round" option.
  - Quote DRF's "or by a later one".
  - Quote where `[C]` entries carry `- **Re-puts:**` today, and show that no `[V]` question in a round record carries a structured record id. Use `grep -n "Re-puts" plugins/product-workflows/commands/brd-interview.md`.
- [ ] **Step 2: Enumerate every statement** of "a reopened decision is settled by another interview round" and of "raises nothing by that move alone", by subject (`reopened`) across refinement 4's scope. Research item iii (d) lists the candidates; verify each and look for more. Count the needle `raises nothing by that move alone`.
- [ ] **Step 3 (N1).** In the round-record question format, every question that re-puts an existing record carries `- **Re-puts:** [VD#n]` (or `[CD#n]`), whatever its tag. This covers the case-A reopen and a held record re-put after supersession. Any BI reader that ties a deferred or resumed re-put `[V]` to its record reads this line and parses no prose. Grep for every such reader and fix each.
- [ ] **Step 4 (iii): the new source.** Add it among Phase 2's sources, in the file's idiom, as *A decision reopened elsewhere*:
  - It takes every `[VD#n]` and `[CD#n]` reading `status: reopened` that is not **in flight**. A record is in flight where some round record holds a question carrying `- **Re-puts:**` naming it, and that question has no terminal disposition.
  - It puts that record's question in the round this run opens, under the record's own tag. The question is phrased against the current findings, quotes every `Reopened <date>: …` paragraph as context, and carries `- **Re-puts:**`.
  - Such a record makes a new round askable.
  - A record reopened while a round is open waits and is reported, as a changed finding is.
  - **Hunt the third member.** List every terminal disposition a question can reach. The research's question-state diagram (research item 0.2) has `[G]`, `[V]` and `[C]` outcomes. Say which ones end "in flight". A *deferred* `[V]` is not terminal.
- [ ] **Step 5.** Rewrite both "raises nothing by that move alone" sites to say: a record moved to `reopened` raises its question through *A decision reopened elsewhere*, and one moved to `superseded` raises nothing.
- [ ] **Step 6: Answer side (read only).** Confirm that Phase 6's re-decision rule and BR step 3's `reopened` Re-puts bullet each re-decide in place from `- **Re-puts:**`. If Phase 6 keys on something else for a `[V]`, make it key on the line.
- [ ] **Step 7: Sweep.** Re-read every site from Step 2. Each is now true and stays, or is rewritten. `docs/commands/brd-interview.md` gains the new source in its list of question sources.
- [ ] **Step 8: Count after editing.** `raises nothing by that move alone`: expect TOTAL 0 outside `CHANGELOG.md`. Count `A decision reopened elsewhere` and list the sites.
- [ ] **Step 9: Scenario traces.**
  - Research item iii (b), for both a `[VD#n]` and a `[CD#n]`.
  - Review Focus item 2: a re-put `[V]` deferred and resumed in a later run is not re-put again.
- [ ] **Step 10: Gates.** Expect `EXIT=0`.
- [ ] **Step 11: Commit.** Message: `brd-interview: question source for reopened records; structured Re-puts on every re-put (iii, N1)`.

### Task 5: The legacy anchor, looked up across every ref and matched on content (spec §4 A4; items xii, N3)

**Files:**
- Modify: `plugins/product-workflows/commands/brd-interview.md`, at the legacy-anchor fallback. Find the sites with `grep -n "log -1" plugins/product-workflows/commands/brd-interview.md` and with the phrase "no commit carries".
- Modify: `plugins/product-workflows/docs/commands/brd-interview.md`, at "compared at its last commit".

- [ ] **Step 1: Prove it.** Quote every `git log -1` fallback site and every "no commit carries" line. Explain why HEAD-only is insufficient, and describe the squash-merge variant (research item xii (b)).
- [ ] **Step 2: Count before editing.** Needles: `no commit carries` and `log -1`.
- [ ] **Step 3.** Replace the anchor rule with this recipe, verbatim in its commands:
  ```bash
  blob=$(git -C "$SPECS_PATH" hash-object -- <record>)
  git -C "$SPECS_PATH" log --all --format=%H -- <record>        # candidates, newest first
  git -C "$SPECS_PATH" rev-parse <sha>:./<record-path>           # compare each to $blob
  ```
  The anchor is the **earliest** candidate whose blob equals `$blob`: the last candidate in log order that matches. The record is append-only, so that commit is where its current content was first written.
  - **No candidate matches:** read every finding as unchanged and print
    *no commit on any ref holds round `<N>`'s record as it stands on disk, so no finding change could be detected*.
  - **The matched commit's grounding files may postdate the record's write**, as when a squash commit is the only holder. Print *compared at `<short-sha>`, a commit that may postdate the record's write*.
    - Define that condition by an observable test, `git -C "$SPECS_PATH" rev-list --count <sha>^@ 2>/dev/null` together with the candidate set, and state it. Do not rest on a judgement.
    - If no observable test separates a squash commit from an ordinary one, say so in your report, and print the caveat whenever the matched commit also changed any grounding file (`git -C "$SPECS_PATH" diff-tree --no-commit-id --name-only -r <sha>`, intersected with `grounding/`). That is observable.
  - Each file is still read at the anchor with `git -C "$SPECS_PATH" show <sha>:./<path>`, unchanged.
- [ ] **Step 4: Sweep.** Every site from Step 1, and the docs page.
- [ ] **Step 5: Count after editing.** `no commit carries`: expect TOTAL 0 outside `CHANGELOG.md`. `log -1`: expect 0 in BI.
- [ ] **Step 6: Scenario trace.** Walk three cases through the new rule:
  - the record committed only on another branch;
  - a squash commit as the only holder;
  - an ordinary merge.
- [ ] **Step 7: Gates.** Expect `EXIT=0`.
- [ ] **Step 8: Commit.** Message: `brd-interview: legacy anchor looked up across every ref, matched on content (xii, N3)`.

### Task 6: `/brd-reconcile`: a same-way re-answer, and the matching descriptor (spec §5; items x, N4)

**Files:**
- Modify: `plugins/product-workflows/commands/brd-reconcile.md`, in three places:
  - Phase 4's skip rule, near "from an earlier pass over this same review";
  - step 3's dispositions, near "the customer decided the same question differently";
  - the section-7 matching table, near "whose holding state is *held for the customer*".
- Check: `plugins/product-workflows/agents/customer-review-reader.md`, for the same holding-state wording.
- Modify: `plugins/product-workflows/docs/commands/brd-reconcile.md`.
- Re-read: `plugins/product-workflows/references/decision-register-format.md` §4.

- [ ] **Step 1: Prove it.**
  - Quote step 3's `replaces` and `contradicts or constrains without replacing` bullets.
  - Quote the rule for the three non-`decided` statuses, and the Re-puts bullet's "even where the customer chose the same option again".
  - Walk research item x (b).
  - For N4, quote the matching table and the corrected-resend paragraph ("Two reviews of one date, or a corrected file weeks later").
    - Show that `customer-review-reader` matches an already-answered question.
    - If the table is scoped-true, for instance because a neighbouring sentence says it describes rather than filters, stop and report `NEEDS_CONTEXT`.
- [ ] **Step 2: Count before editing.** Needles:
  - `decided the same question differently`
  - `whose holding state is *held for the customer*`
- [ ] **Step 3 (x): the skip rule.**
  - **Skip when:** the target `[C]`'s current record is `decided`, with or without `conditional_on`, and the candidate's `chosen` equals the record's `chosen`, and its quoted reason is byte-equal to the record's quoted reason after collapsing whitespace.
  - **What a skip does:** it is reported as *already reconciled, re-affirmed by <review file>*. It mints nothing, appends no *answered by the customer*, and adds nothing to the sweep's changed-id set.
  - **Hunt the third member:** the record's current status may be `open`, `reopened`, `superseded` or `withdrawn`. Each has an existing rule; say which, and confirm that the skip does not apply to them.
- [ ] **Step 4 (x): step 3.** Rewrite the `replaces` bullet as *the new answer answers the record's own question again, whatever it chooses → `superseded`*.
  - The `reopened` bullet keeps its meaning: an answer that bears on the question without answering it again.
  - Re-read the "the one that replaces it decides it" sentence and DRF §4's `[CD#m]` supersession wording against the new definition.
- [ ] **Step 5 (N4).** Reword the matching table's third column so that it describes the question the entry holds, whatever its state. Apply the same fix to `customer-review-reader.md` if it carries the filter reading.
- [ ] **Step 6: Sweep.** Update the docs page's corrected-resend and Phase 4 bullets.
- [ ] **Step 7: Count after editing.**
  - `decided the same question differently`: expect TOTAL 0 outside `CHANGELOG.md`.
  - The holding-state needle: expect 0.
  - Count `re-affirmed by` and list the sites.
- [ ] **Step 8: Scenario traces.**
  - Research item x (b), with the same reason: skipped.
  - Review Focus item 3, with a changed reason: supersedes.
  - `decided` with `conditional_on`.
- [ ] **Step 9: Gates.** Expect `EXIT=0`.
- [ ] **Step 10: Commit.** Message: `brd-reconcile: same-way re-answer skipped or supersedes; matching table describes, not filters (x, N4)`.

### Task 7: `/create-prd`: a keyless `prd.md` counts as found, and a pre-write guard (spec §8 E1; items v, N6)

**Files:**
- Modify: `plugins/product-workflows/commands/create-prd.md`:
  - Phase 0 step 6, near "`kind: prd` identifies the draft inside it";
  - Phase 5's write, near "Write the feature folder: `prd.md`";
  - Phase 1 step 2's archive naming, read only.
- Modify: `plugins/product-workflows/docs/commands/create-prd.md`.
- Re-read: `plugins/workflows-core/references/addressing.md` §5's kind-gating list, and confirm it stays true.

- [ ] **Step 1: Prove it.**
  - Quote step 6, and show that it never states the test for "found".
  - Quote Phase 5's write, and show that it has no existence check.
  - Quote Phase 1 step 2's archive rule and `/update-prd`'s "authoritative without a test".
- [ ] **Step 2: Count before editing.** Needle: `` `kind: prd` identifies the draft inside it ``.
- [ ] **Step 3 (v).** Rewrite step 6's test in the file's idiom, keeping three points:
  - any file at `<feature-folder>/prd.md` counts as found, whatever its frontmatter;
  - `kind:` does not decide presence here, and this matches `/product-workflows:update-prd`;
  - the three commands `workflows-core:addressing` §5 names gate on `kind: prd` because they consume a PRD's content, while `/create-prd` gates on presence because it must not overwrite one.

  The `<KEY>_<slug>.md` legacy sentence stays.
- [ ] **Step 4 (N6).** In Phase 5, immediately before writing `prd.md`: where `<feature-folder>/prd.md` exists and this run did not already archive it in Phase 1's overwrite, archive it first, exactly as Phase 1 step 2 archives (same `revisions/` location and naming, copied from Phase 1's text), and report the archive path.
  - **Hunt the third member:** the routes into Phase 5 are greenfield, `--from-prd`, the BRD route, and Phase 1's overwrite. State that the guard covers every route except the one that already archived.
- [ ] **Step 5: Docs page.** One sentence on the keyless case and the guard.
- [ ] **Step 6: Count after editing.** The needle: expect TOTAL 0.
- [ ] **Step 7: Scenario traces.** Walk research item v (b) and Review Focus item 5.
- [ ] **Step 8: Gates.** Expect `EXIT=0`.
- [ ] **Step 9: Commit.** Message: `create-prd: any prd.md counts as found; archive before every write (v, N6)`.

### Task 8: Named stops for found-but-unplaced folders (spec §8 E2; item vi)

**Files:**
- Modify: `plugins/docs-workflows/commands/document.md`: Phase 0 step 1's place-the-folder paragraph, and Phase 3's "If the PRD folder holds no PRD". Pick the right `# Mode` section before slicing, per refinement 4.
- Modify: `plugins/docs-workflows/commands/release-notes.md`, at the same two sites.
- Modify: `plugins/docs-workflows/docs/commands/document.md` and `plugins/docs-workflows/docs/commands/release-notes.md`.
- Check: `plugins/product-workflows/commands/epics.md`, near "is the `key dir not found` case".
- Re-read: `plugins/workflows-core/references/escalation-rules.md`'s `key dir not found` rule.

**Interfaces:**
- Produces:
  - `DOCUMENT_BRD_NOT_SLICED`, `DOCUMENT_FOLDER_NOT_PLACED`, `DOCUMENT_NO_PRD`;
  - `RELEASE_NOTES_BRD_NOT_SLICED`, `RELEASE_NOTES_FOLDER_NOT_PLACED`, `RELEASE_NOTES_NO_PRD`.

  Task 9 cites them.

- [ ] **Step 1: Prove it.**
  - Quote each of the four sites.
  - Quote `escalation-rules.md`'s rule and its choices.
  - Quote `/ready`'s `READY_BRD_NOT_SLICED` and `/specify`'s "A missing folder and a folder holding no `prd.md` are two different states" as the pattern to follow.
  - Read how `/document` and `/release-notes` spell their existing named stops, for example `RELEASE_NOTES_NEEDS_KEY`, and match that spelling.
- [ ] **Step 2: Count before editing.** Needles: `key dir not found` and `Re-enter key`. Record the per-file hits.
- [ ] **Step 3.** At the place-the-folder site in each command, split the stop. The `<CMD>` prefix is `DOCUMENT` or `RELEASE_NOTES`.
  - **`<CMD>_BRD_NOT_SLICED`**, where §4.1 places the folder as a BRD container:
    - message: `<CMD>_BRD_NOT_SLICED: <KEY> resolves to a BRD container at <path>, which holds no PRD — its PRDs are authored in its PRD- slices: <each slice key, found by workflows-core:addressing §4.1's positive test>.`
    - choices: `["Enter a slice key", "Cancel"]`. "Enter a slice key" re-enters address resolution with the key the operator types.
  - **`<CMD>_FOLDER_NOT_PLACED`**, where §4.1 places the folder at no level:
    - message: `<CMD>_FOLDER_NOT_PLACED: <KEY> resolves to <path>, which carries <what it carries> and nothing workflows-core:addressing §4.1 places at any level.`
    - The message continues with the remedy: give the folder a carrier per `workflows-core:addressing` §5, or, where it holds an `idea.md` and no `prd.md`, run `/product-workflows:create-prd <KEY>`.
    - It is a plain stop, with no `choices:`.
  - **Hunt the third member:** can §4.1 place the folder at Epic level? `/document` and `/release-notes` each have an existing Epic path; confirm that path is untouched.
- [ ] **Step 4.** At the "holds no PRD" site in each command, replace the `key dir not found` reuse with a plain stop:
  `<CMD>_NO_PRD: <KEY>'s folder <path> holds no prd.md. Run /product-workflows:create-prd <KEY> first.`
  Check whether `/specify`'s pattern, which does not stop, is the right one here. `/document` and `/release-notes` need `prd.md`'s content, so a stop is correct; say so in the report.
- [ ] **Step 5: `epics.md`.** Check whether "An empty PRD folder, or one whose `prd.md` states no requirements, is the `key dir not found` case" is still reachable after `/epics`' Phase 0 `EPICS_NO_PRD` gate.
  - If the empty-folder half is unreachable, narrow the sentence to what is reachable.
  - Whatever remains must not route to `Re-enter key` for a key that resolved. Use `EPICS_NO_PRD`'s stop, or a named sibling if its remedy differs, and justify the choice.
- [ ] **Step 6: `escalation-rules.md`.** Re-read the `key dir not found` rule's description. It stays for a folder that really is absent. Remove any wording that implies these cases.
- [ ] **Step 7: Docs pages.** Document the three stops on each command's page, derived from the command.
- [ ] **Step 8: Count after editing.**
  - `key dir not found` and `Re-enter key`: list every remaining hit, each justified as a genuinely-absent folder or a grammar failure.
  - Each new stop name: expect 1 or more hits in its command and 1 on its docs page.
- [ ] **Step 9: Scenario trace.** Walk research item vi (b) for each command, and the BRD-container case.
- [ ] **Step 10: Gates.** Expect `EXIT=0`. Check 12 covers the new choices array.
- [ ] **Step 11: Commit.** Message: `document, release-notes: named stops for BRD containers, unplaced folders and missing PRDs (vi)`.

### Task 9: Releases and back-pointers (spec §10; the controller runs this after the final review)

**Files:**
- Modify: `plugins/product-workflows/.claude-plugin/plugin.json` (3.8.2 → 3.8.3).
- Modify: `plugins/docs-workflows/.claude-plugin/plugin.json` (1.3.3 → 1.3.4).
- Modify: `.claude-plugin/marketplace.json`, both versions.
- Modify: `plugins/product-workflows/CHANGELOG.md` and `plugins/docs-workflows/CHANGELOG.md`: new sections dated `2026-09-23`.
- Modify: `plugins/workflows-core/CHANGELOG.md`: fold Task 2's GF change into the existing 1.7.6 section, keeping its date. `plugin.json` stays at 1.7.6.
- Modify: `docs/superpowers/verification/2026-09-23-exclusivity-probe-wider-vocabulary.md`: under "Deferred by user decision", add one line per item: `Fixed: see docs/superpowers/verification/2026-09-23-decision-cycle-lifecycle.md`.
- Create: `docs/superpowers/verification/2026-09-23-decision-cycle-lifecycle.md`, **last**, after the final fix wave.

- [ ] **Step 1.** Bump the versions. Write CHANGELOG entries in each file's existing style, one bullet per defect id, naming the new stop names and the `- **Re-puts:**` marker. Leave plugin descriptions untouched.
- [ ] **Step 2.** Add the back-pointers.
- [ ] **Step 3.** Run the gate chain. Expect `EXIT=0`. `validate-catalog` checks that each `plugin.json` agrees with `marketplace.json`.
- [ ] **Step 4.** Commit, with message `Release product-workflows 3.8.3, docs-workflows 1.3.4; workflows-core 1.7.6 gains grounding supersession`.
- [ ] **Step 5.** Write the verification record, after the final whole-branch review and its fix wave. It holds:
  - one row per spec §3 defect: id, FIXED, commit, the cited text where it now resolves, and the before and after literal counts;
  - the gate-chain output;
  - an exclusivity probe over `git diff 2998b4df..HEAD -- plugins/` covering the new "only", "never", "every" and "no other" claims, with each hit dispositioned;
  - the D4 revision and its reason;
  - a known-bug count line: `Known bugs: 0`.

  Re-derive every expected value against the tree. Copy none from this plan. Commit it.

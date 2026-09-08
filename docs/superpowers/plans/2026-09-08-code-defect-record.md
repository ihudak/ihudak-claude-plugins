# Code-defect record for the BRD-to-PRD route — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the BRD-to-PRD route a place to record a defect in the code, so a decision that rests on one cites a record instead of asserting one in prose.

**Architecture:** A new `product-workflows` reference defines `<BRD-dir>/code-defect-log.md`, holding `[CDF#n]` entries that each cite the verified `[CG#n]` establishing the behaviour and name their intent basis separately. `/brd-interview` is the only writer. A decision reaches its entries through a new `defects:` field — the twelfth on the register record. The log ships in the customer's review package, which is what makes that field resolve and what makes a scope-bearing defect visible to the party agreeing to the scope.

**Tech Stack:** Markdown instruction files only. No code, no runtime. The repository's seven CI gates are the test harness.

**Spec:** `docs/superpowers/specs/2026-09-08-code-defect-record-design.md`

**Ledger:** `docs/superpowers/brd-route-follow-ups.md` § E-3. Closing this entry closes both E-3a and E-3b.

## Global Constraints

- **Every requirement ID written anywhere is the bracketed `[PREFIX#N]` form**, never dash-separated. `./scripts/check-id-grammar.sh --root .` enforces it and must pass after every task. `[CDF#n]` is deliberately **not** added to that script's `PATTERN` — `BR`, `CG`, `DG`, `DEF`, `VD`, `CD`, `AS` and `SR` are all already outside it, so this is consistent, not an omission. Do not "fix" it.
- **Match the wrap of the file you are editing.** These files are hard-wrapped at ~100 columns in their source; `workflows-core:prose-formatting` governs the prose a *run* writes, not this repository's own instruction files. Wrap new paragraphs exactly as their neighbours do.
- **`brd-` names the route, not the folder kind.** `/brd-interview` and `/brd-package` both refuse a resolved root (`BRD_INTERVIEW_ROOT_LEVEL`, `BRD_PACKAGE_ROOT_LEVEL`); every rule written here describes a **slice** run.
- **Never restate a rule another file owns — cite it.** The new reference cites `workflows-core:grounding-format` §1 for what grounding does and does not adjudicate, `workflows-core:source-truth` §7.5 as the family's sibling precedent, and `references/decision-register-format.md` §2 for the argumentation standard its prose is held to.
- **A `[CDF#n]` entry is customer-visible prose.** The log ships. `statement`, `intent` and an `operator-judgment` reasoning are written to the standard `decision-register-format.md` §2 already sets — naming the constraint, never the internal preference, and never internal disagreement about the package.
- **Every entry names exactly one verified `[CG#n]`.** There is no entry without one, and no second evidence field: the finding carries `commit`, the repository and the `file:line` evidence already.
- **`blocked_on` has exactly two spellings** — the qualified `<BRD-KEY>/<decision-id>`, or prose naming **no** bracketed identifier. The reference is the authority that declares the field, which is what puts it inside `bundle-packaging.md` §6.2 relation 1's discharge rule.
- **Plugin `description` hard cap 1024 characters**, warning at 900. A capability change **replaces** wording; it never appends. `.claude-plugin/marketplace.json` is edited in place and **never reformatted** — change only the `version` and `description` values of the `product-workflows` entry.
- **`workflows-core` is not touched.** Its references are cited, never edited. Only `product-workflows` gets a version bump.
- Commit trailer on every commit:
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
  ```
- **Nothing is pushed.** No task opens a pull request or runs `git push`.
- **`git add -A` is never issued at repository scope.** Stage explicit paths.

**The seven gates**, run from the repository root, all of which must pass before any task commits:

```bash
python3 scripts/validate-catalog.py --selftest
python3 scripts/validate-catalog.py .
./scripts/check-id-grammar.sh --selftest
./scripts/check-id-grammar.sh --root .
./scripts/check-docs.sh --selftest          # ~2 minutes
./scripts/check-docs.sh --root .
python3 plugins/workflows-core/scripts/session-cost.py --selftest
```

**`validate-catalog.py .` currently reports `0 error(s), 2 warning(s)`**, and both warnings are the same 988-character `product-workflows` blurb in its two editions (`plugin.json` and the `marketplace.json` entry) — ledger G3-4. Two warnings is the expected baseline for Tasks 1–5. **Task 6 takes it to `0 error(s), 0 warning(s)`**, which is the assertable outcome of the blurb trim.

---

## File Structure

| File | Responsibility in this change |
|---|---|
| `plugins/product-workflows/references/code-defect-log-format.md` | **NEW.** The `[CDF#n]` record and its eight fields, the five dispositions, `blocked_on`'s two spellings, the customer-visible-prose rule, and the citation of `workflows-core:source-truth` §7.5 as the family's sibling precedent |
| `plugins/product-workflows/docs/reference/references.md` | New row under *BRD-to-PRD route formats*; preamble count `nine files` → `ten files` (check 9) |
| `plugins/product-workflows/references/decision-register-format.md` | §1's YAML example and field table gain `defects:`; §7's account goes from eleven fields to twelve |
| `plugins/product-workflows/commands/brd-interview.md` | Phase 6 gains the structural offer; Phase 9 writes `code-defect-log.md`; Phase 10 adds it to `deliverable_paths` and `body_facts` |
| `plugins/product-workflows/docs/commands/brd-interview.md` | Opening summary and outputs list gain the log |
| `plugins/product-workflows/docs/brd-workflow.md` | The folder-tree diagram gains the log |
| `plugins/product-workflows/references/bundle-packaging.md` | §1.1's allow-list table gains a row; §6.1's corpus table gains the `[CDF#n]` class |
| `plugins/product-workflows/commands/brd-package.md` | Phase 0 step 10 reads the log; the eleven-part table's rows 6, 8 and 11 gain a source; parts 6, 8 and 11 gain their rule |
| `plugins/product-workflows/docs/commands/brd-package.md` | The allow-list prose gains the log |
| `plugins/product-workflows/agents/brd-package-reviewer.md` | `Inputs` gains an optional `defects` path; a **sixth** hunt class; the "five classes" sentence |
| `plugins/product-workflows/README.md` | `Nine reference pages` → `Ten` |
| `plugins/product-workflows/.claude-plugin/plugin.json` | version 3.3.0; blurb trimmed and count corrected |
| `.claude-plugin/marketplace.json` | the `product-workflows` entry's `version` and `description` |
| `plugins/product-workflows/CHANGELOG.md` | 3.3.0 entry |
| `CLAUDE.md` | two `nine reference` sites; the workflow map's `/brd-interview` line |

**Task order is forced by citation direction, and by the gates.** Task 2 cites Task 1's record. Task 3 writes what Tasks 1 and 2 define. Task 4 ships what Task 3 writes. Task 5 reviews what Task 4 ships. Task 6 documents all five. **Task 1 must carry its own `references.md` row and count bump**, because check 4 and check 9 both go red the moment the reference file exists without them — a task that commits red breaks the constraint above. Do not reorder.

---

### Task 1: The `[CDF#n]` record — a new reference, and the two gates it trips

**Files:**
- Create: `plugins/product-workflows/references/code-defect-log-format.md`
- Modify: `plugins/product-workflows/docs/reference/references.md` (row under `## BRD-to-PRD route formats`; preamble line 3)

**Interfaces:**
- Consumes: nothing. This is the first task and cites only files that already exist.
- Produces: the `[CDF#n]` id prefix; the artifact path `<BRD-dir>/code-defect-log.md`; the eight field names `id`, `statement`, `behaviour`, `intent`, `intent_basis`, `disposition`, `blocked_on`, `round`; the five disposition values `open`, `in-scope`, `out-of-scope`, `conditional`, `withdrawn`. Tasks 2–6 use these exact spellings.

- [ ] **Step 1: Write the failing test — create the reference file and watch the gates go red**

Create `plugins/product-workflows/references/code-defect-log-format.md`. It opens with the core-references preamble every `product-workflows` reference carries (copy the two-line block verbatim from the top of `references/decision-register-format.md`), then:

```markdown
# Code-defect log format (embedded authority)

The canonical shape of the BRD-to-PRD route's **code-defect log**: the record every `[CDF#n]`
carries, the five dispositions one can hold, the rule that every entry cites a verified `[CG#n]`
for the behaviour and names its intent basis separately, and the two spellings `blocked_on` takes.
Design authority: `docs/superpowers/specs/2026-09-08-code-defect-record-design.md`.

**Written by `commands/brd-interview.md`**, which is the only writer; **read by
`agents/brd-package-reviewer.md`**, which raises a finding where an `argumentation` asserts a
recorded defect that no `defects:` field names; and **shipped to the customer** by
`commands/brd-package.md`, per `references/bundle-packaging.md` §1.1.

## 1. Why this is not a grounding finding

`workflows-core:grounding-format` §1 fixes grounding's question as *"is this specific claim true of
this specific commit?"* and states that grounding **adjudicates, it does not scope**. A `REWRITTEN`
verdict says the code does X. It says nothing about whether X is intended.

Calling X a defect is a claim about the code's **own intent**, which grounding has no authority over
and no field for. A finding with an opinion attached is not a record. So every entry here splits the
two halves: the `[CG#n]` supplies the behaviour, and this record supplies the intent and what says
so.

**The family's sibling precedent is `workflows-core:source-truth` §7.5**, which writes
`implementation-gaps.md` on the documentation route. That artifact is a draft to file elsewhere
rather than a register — no bracketed id, no status, no disposition — and its fields are
documentation-run specific. It is named here so that a reader looking for a code-defect record finds
the two that exist rather than building a third.

## 2. The record

Each `[CDF#n]` carries:

```yaml
id: [CDF#1]
statement: <one sentence — what is wrong>
behaviour: [CG#12]
intent: <one sentence — what the code is supposed to do instead>
intent_basis: <a file:line or document path | `operator-judgment` — <why>>
disposition: open | in-scope | out-of-scope | conditional | withdrawn
blocked_on: <what would settle the scope question>   # required when `conditional`, omitted otherwise
round: 2
```

| Field | Notes |
|---|---|
| `id` | `[CDF#1]`, `[CDF#2]`, … — contiguous, assigned once, **never renumbered and never reused**, with no terminal-status qualifier: unlike a decision, this record has no state a later run may reopen. A re-run continues from the highest id on file |
| `statement` | one sentence stating what is wrong, not the investigation that found it |
| `behaviour` | exactly one **verified** `[CG#n]` in this BRD's own `grounding/code-grounding.md`. There is no entry without one |
| `intent` | one sentence stating what the code is supposed to do instead |
| `intent_basis` | what says so — §3 |
| `disposition` | one of the five in §4 |
| `blocked_on` | **required when `disposition` is `conditional`, omitted otherwise** — §5 |
| `round` | the interview round the defect was raised in, per `references/interview-tagging.md` §5 |

**Four fields are absent, and each absence is a rule.** There is no `commit`, no `repo` and no
`evidence`: the cited `[CG#n]` carries all three, already verified, and restating them is the drift
`workflows-core:followup-emission` §1 forbids as *"link, never restate"* — a defect whose location
the finding's evidence does not cover is a defect that finding did not establish. There is no
`altitude`: a code defect is always implementation altitude, and a field with one legal value is
noise that invites an author to fill it wrong. There is no `consumed_by`: nothing downstream draws
on a defect, so the workflow's altitude routing has nothing to route.

**Every field here is customer-visible prose.** The log ships in the review package
(`references/bundle-packaging.md` §1.1), so `statement`, `intent` and an `operator-judgment`
reasoning are written to the standard `references/decision-register-format.md` §2 sets for
`argumentation`: name the constraint, never the internal preference, and never internal disagreement
about the package. This is not a new discipline — it is the one every other shipping record in the
folder is already held to.

## 3. `intent_basis` has exactly two shapes

Either a pointer into a repository or a document that says what the code should do — a `file:line`,
a schema, a test, a sibling code path, a documentation page — or the literal `operator-judgment`
followed by the reasoning.

That split is the field's whole purpose: it makes *"is there something that says so, or is this a
person's call?"* a property of the record rather than a matter of prose tone. Both are legitimate.
Only one of them is checkable, and the record has to say which it is.

## 4. Dispositions

Exactly five.

| Disposition | Meaning |
|---|---|
| `open` | Raised, not yet dispositioned |
| `in-scope` | The repair is part of the work this route is scoping |
| `out-of-scope` | Recorded, and deliberately not this engagement's work |
| `conditional` | Cannot be settled until something else is; carries `blocked_on` (§5) |
| `withdrawn` | The intent basis turned out to be wrong; it is not a defect |

**A code defect never resolves itself on this route, and `withdrawn` is not the back door.** There is
no `fixed` disposition, because nothing on the BRD-to-PRD route builds anything and no command can
observe a repair. `withdrawn` means one thing only — the intent basis turned out to be wrong, so
there was never a defect — and using it for a defect that was fixed would put a false statement in a
document the customer reads. A repaired defect keeps whatever disposition it had: this log records
what was true of the pinned commit, exactly as the finding it cites does.

## 5. `blocked_on` has exactly two spellings, and that is this file's to fix

`conditional` exists for the scope question that cannot be settled yet — *"whether the new surface
renders this is a property of code nobody has written"*. That is not a decision in anyone's
register, so a field accepting only `<BRD-KEY>/<decision-id>` would force an author to invent one,
or to assert the repair is in scope and contradict their own stated boundary.

So `blocked_on` takes either: the qualified `<BRD-KEY>/<decision-id>` naming one specific decision in
a named prerequisite's own register, exactly as `references/decision-register-format.md` §5's
`conditional_on` does; or **prose naming no bracketed identifier.**

**The second constraint is not stylistic.** The log ships, so `blocked_on` reaches the bundle, where
`references/bundle-packaging.md` §6.2 relation 1 discharges *"a structured field whose format another
authority fixes"* and says that a new such field *"is that authority's to declare"*. This file is
that authority, and fixing both spellings is what keeps `blocked_on` out of the state §6.2 has to
handle for `workflows-core:grounding-format` §5's `prerequisite` — which fixes no spelling, so an
unqualified value there has to be **reported** rather than resolved, because a silent pick lands on a
real record of the wrong package and the check goes green.

## 6. Non-goals

- **A code defect is never a customer question.** The customer sees every entry, because the log
  ships; the operator settles every disposition. A defect does not become a `[C]` and never reaches
  `interview/customer-questions.md`. A customer who disagrees says so in the returned review, which
  `commands/brd-reconcile.md` already reads.
- **This log holds no requirement defects.** Those are `[DEF#n]`, in `brd/brd-defect-log.md`, owned
  by the BRD that owns the source document and reached one hop up from a slice
  (`references/brd-format.md` §4). This log is **slice-owned** and there is no hop: a code defect
  belongs to the slice's own grounding, and grounding is slice-only.
```

- [ ] **Step 2: Run the gates and verify two of them fail**

Run:

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -E 'check 4|check 9'
```

Expected: **FAIL** on both —

```
check 4: reference file 'code-defect-log-format.md' has no row/entry in reference/references.md (a prose mention is not one)
check 9: reference files: plugins/product-workflows/docs/reference/references.md says nine (9), tree has 10
```

That pair is the point of this step: check 4 proves the inventory relation is live in the forward direction, and check 9 proves the count sentence is actually being compared rather than merely present.

- [ ] **Step 3: Add the `references.md` row and fix the count**

In `plugins/product-workflows/docs/reference/references.md`, change the preamble's first sentence from `bundles nine files under` to `bundles ten files under`, and add this row to the `## BRD-to-PRD route formats` list, immediately after the `decision-register-format.md` row:

```markdown
- `code-defect-log-format.md` — the code-defect log's record shape: the `[CDF#n]` entry, the rule that every one of them cites a verified `[CG#n]` for the behaviour and names its intent basis separately because grounding adjudicates a claim and has no authority over the code's own intent, the two shapes an `intent_basis` takes (a pointer into a repository or document, or an explicit `operator-judgment` with its reasoning), the five dispositions and why there is no `fixed` one on a route that builds nothing, and the two spellings `blocked_on` fixes so a scope condition that cannot be settled yet does not have to be invented as a decision; `/brd-interview` is its only writer, `brd-package-reviewer` reads it, and `/brd-package` ships it to the customer because a defect disposed `in-scope` is the delivery boundary rather than delivery-side bookkeeping.
```

- [ ] **Step 4: Run the full gate set and verify green**

Run all seven gates from the Global Constraints block. Expected: every one passes, and `validate-catalog.py .` still reports `0 error(s), 2 warning(s)`.

- [ ] **Step 5: Commit**

```bash
git add plugins/product-workflows/references/code-defect-log-format.md \
        plugins/product-workflows/docs/reference/references.md
git commit -m "feat(product-workflows): define the [CDF#n] code-defect log format"
```

---

### Task 2: `defects:` — the twelfth field on the decision register

**Files:**
- Modify: `plugins/product-workflows/references/decision-register-format.md` (§1's YAML block and field table; §7's preamble and table)

**Interfaces:**
- Consumes: Task 1's `[CDF#n]` prefix and the reference filename `code-defect-log-format.md`.
- Produces: the field name `defects:` on a `[VD#n]`, `[CD#n]` and `[AS#n]` record. Tasks 3, 4 and 5 write and read that exact spelling.

- [ ] **Step 1: Add the field to §1's YAML example**

In the `## 1. Record shape` fenced block, insert one line immediately after the `evidence:` line:

```yaml
defects: [[CDF#2]]                        # omitted unless the decision turns on a recorded code defect
```

- [ ] **Step 2: Add the field to §1's table**

Insert one row immediately after the `evidence` row:

```markdown
| `defects` | the `[CDF#n]` code-defect entries this record turns on, per `references/code-defect-log-format.md`; omitted when absent. **Never in `evidence`** — §6's will-change rule inspects that list, and a non-finding id in it would silently change what D19 fires on |
```

- [ ] **Step 3: State the separation in prose, under §1's table**

Add this paragraph immediately after the paragraph beginning *"Which prefix a decision gets is fixed by the tag of the question it answers"*:

```markdown
**`defects` is not `evidence`, and the separation is load-bearing rather than tidy.** `evidence`
holds `[CG#n]`/`[DG#n]` findings and §6 **inspects that list** — the will-change rule fires when
every finding in it carries `horizon: will-change`. A `[CDF#n]` placed there would change what D19
fires on, in the one rule whose whole purpose is that a decision resting on ground that is about to
move says so. The two fields also answer different questions: `evidence` says what established the
premise, and `defects` says what has to be repaired before the position can be delivered.
```

- [ ] **Step 4: Grow §7's accounting from eleven fields to twelve**

This is the step most likely to be skipped, and skipping it is invisible to any search for `defects` or `[CDF#n]`, because the omission is a table row that is not there. §7 exists because *"which fields apply is not a detail an author may settle for themselves"*.

In §7's preamble, change `It uses the same eleven fields as §1` to `It uses the same twelve fields as §1`, and change `All eleven are accounted for here.` to `All twelve are accounted for here.` Then change the table's header cell from `| §1 field | On an `[AS#n]` |` — leave it as-is — and insert one row immediately after the `conditional_on` row:

```markdown
| `defects` | **As-is**, and omitted when absent: an assumption can turn on a known code defect exactly as a position can, and the customer who reads the assumption needs the same access to what would have to be repaired |
```

- [ ] **Step 5: Run the full gate set and verify green**

Run all seven gates. Expected: every one passes; `validate-catalog.py .` still reports `0 error(s), 2 warning(s)`.

- [ ] **Step 6: Verify by hand that §7's own arithmetic is right**

Run:

```bash
grep -c '^| `' plugins/product-workflows/references/decision-register-format.md
awk '/^## 7\./,0' plugins/product-workflows/references/decision-register-format.md | grep -c '^| `'
```

Expected: the second number is **12** — one row per §1 field on an `[AS#n]`. If it is 11, step 4 did not land.

- [ ] **Step 7: Commit**

```bash
git add plugins/product-workflows/references/decision-register-format.md
git commit -m "feat(product-workflows): add defects: to the decision register, and account for it on an [AS#n]"
```

---

### Task 3: `/brd-interview` writes the log

**Files:**
- Modify: `plugins/product-workflows/commands/brd-interview.md` (Phase 6, Phase 9, Phase 10)
- Modify: `plugins/product-workflows/docs/commands/brd-interview.md` (opening summary; the outputs list)
- Modify: `plugins/product-workflows/docs/brd-workflow.md` (the folder-tree diagram)

**Interfaces:**
- Consumes: Task 1's record shape and field names; Task 2's `defects:` field.
- Produces: the artifact at `<BRD-dir>/code-defect-log.md`, written in Phase 9 and handed off in Phase 10. Tasks 4 and 5 read that path.

- [ ] **Step 1: Add the structural offer to Phase 6**

In `commands/brd-interview.md`, immediately after the paragraph beginning **"Then take the argumentation, and refuse the record without it."**, insert:

```markdown
**Then, on exactly one condition, offer to record a code defect.** Where this decision's `evidence`
list holds at least one finding whose `verdict` is `REWRITTEN`, `AMENDED` or `FALSE-FRIEND` — the
three verdicts that mean grounding established the code does something other than what was claimed
(`workflows-core:grounding-format` §3) — ask the operator whether the position turns on a defect in
the code, and where it does, take a `[CDF#n]` against
`${CLAUDE_PLUGIN_ROOT}/references/code-defect-log-format.md` §2 and put its id in this decision's
`defects` list. **The trigger is read off the record, never out of prose**: there is no phrase this
command matches, and none is wanted — the tree carries no corpus of real registers to measure a
candidate pattern against, which is the evidence this repository requires before a prose proxy ships.

```
choices: ["No — this position does not turn on a code defect (Recommended)", "Yes — record a defect and cite it here"]
```

**The offer is a convenience, not the gate.** An operator may raise a `[CDF#n]` at any point in this
phase without being asked, and a decision whose evidence holds only `CONFIRMED` findings gets no
offer and may still need one. What catches the residue is `agents/brd-package-reviewer.md`, which
raises a finding where an `argumentation` asserts a recorded defect that no `defects` field names.

**A `[CDF#n]` is customer-visible.** The log ships in the review package
(`${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md` §1.1), so take `statement`, `intent` and any
`operator-judgment` reasoning to the same standard this phase already applies to `argumentation`, and
refuse an entry that does not meet it.
```

- [ ] **Step 2: Add the file to Phase 9**

In `commands/brd-interview.md` Phase 9, immediately after the `**<BRD-dir>/interview/customer-questions.md**` paragraph, insert:

```markdown
**`<BRD-dir>/code-defect-log.md`** — every `[CDF#n]` this round raised, appended after any already on
file, each carrying every field `${CLAUDE_PLUGIN_ROOT}/references/code-defect-log-format.md` §2
defines. Ids are contiguous, assigned once, never renumbered and never reused: a re-run continues the
sequence from the highest id on file. **A round that raised none writes nothing** — the file is
absent until there is an entry, and its absence is an ordinary state that no later gate reads as a
failure. Every entry's `behaviour` names a `[CG#n]` that is on file in this BRD's own
`grounding/code-grounding.md` and carries a verifier outcome; an entry citing anything else is not
written, because the packaging run will refuse the bundle over it
(`${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md` §6.2 relation 1).
```

- [ ] **Step 3: Add the path to Phase 10's handoff**

In Phase 10, change the `deliverable_paths` clause from:

```
`deliverable_paths` = every file this run wrote or updated under `<BRD-dir>` (`decisions.md`, `interview/round-<N>.md`, and
`interview/customer-questions.md` when this round held a `[C]`)
```

to:

```
`deliverable_paths` = every file this run wrote or updated under `<BRD-dir>` (`decisions.md`, `interview/round-<N>.md`,
`interview/customer-questions.md` when this round held a `[C]`, and `code-defect-log.md` when this round raised a `[CDF#n]`)
```

and in the same sentence's `body_facts` list, change `the `[VD#n]` and `[AS#n]` ids written` to `the `[VD#n]`, `[AS#n]` and `[CDF#n]` ids written`.

- [ ] **Step 4: Update the two documentation pages**

In `plugins/product-workflows/docs/commands/brd-interview.md`, change the opening summary's last sentence from `It writes `decisions.md`, the round's own record, and the `[C]` question set.` to `It writes `decisions.md`, the round's own record, the `[C]` question set, and — where a decision turns on a defect in the code — the code-defect log.`

Then add this entry to the outputs list, immediately after the `interview/customer-questions.md` entry:

```markdown
- `code-defect-log.md` — the code-defect log: one `[CDF#n]` per defect in the code that a decision
  turns on, each citing the verified `[CG#n]` that established the behaviour and naming separately
  what the code is supposed to do and what says so. Written only where a round raised one, and
  shipped to the customer in the review package, because a defect disposed `in-scope` is part of the
  delivery boundary rather than delivery-side bookkeeping. Format:
  [`code-defect-log-format.md`](../../references/code-defect-log-format.md).
```

In `plugins/product-workflows/docs/brd-workflow.md`, add one line to the folder-tree diagram immediately after the `decisions.md` line, matching the surrounding alignment:

```
├── code-defect-log.md           # [CDF#n] code defects a decision turns on, from /brd-interview
```

- [ ] **Step 5: Run the full gate set and verify green**

Run all seven gates. Expected: every one passes; `validate-catalog.py .` still reports `0 error(s), 2 warning(s)`.

Then verify the cross-links resolve, since check 1 gates them:

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -iE 'link|anchor' || echo "no link failures"
```

Expected: `no link failures`.

- [ ] **Step 6: Commit**

```bash
git add plugins/product-workflows/commands/brd-interview.md \
        plugins/product-workflows/docs/commands/brd-interview.md \
        plugins/product-workflows/docs/brd-workflow.md
git commit -m "feat(brd-interview): raise and write [CDF#n] code defects"
```

---

### Task 4: The log ships — allow-list, corpus, and three prompt parts

**Files:**
- Modify: `plugins/product-workflows/references/bundle-packaging.md` (§1.1's table; §6.1's corpus table and the §6 preamble's class list)
- Modify: `plugins/product-workflows/commands/brd-package.md` (Phase 0 step 10; the eleven-part table; parts 6, 8 and 11)
- Modify: `plugins/product-workflows/docs/commands/brd-package.md` (the allow-list prose)

**Interfaces:**
- Consumes: Task 1's record and dispositions; Task 3's artifact path `<BRD-dir>/code-defect-log.md`.
- Produces: `code-defect-log.md` as a bundle document, and `[CDF#n]` as a ninth citation class with `code-defect-log.md` as its corpus. Task 5 reads the same path.

- [ ] **Step 1: Add the allow-list row**

In `references/bundle-packaging.md` §1.1's `| In the bundle | Which prompt part sends the reviewer to it |` table, insert one row immediately after the `coverage-ledger.md` row:

```markdown
| `code-defect-log.md`, when the folder holds one | *Review scope*, *what could still move*, and *what this session cannot settle* — a defect disposed `in-scope` **is** the delivery boundary |
```

Then add this paragraph immediately after the table's `Plain markdown and images` sentence:

```markdown
**The code-defect log ships, and the reason is scope rather than disclosure.** A `[CDF#n]` disposed
`in-scope` names a repair that has to happen inside this PRD's scope or the feature cannot be
delivered (`references/code-defect-log-format.md` §4). A `[VD#n]` whose real basis is such a repair
is a decision the customer cannot evaluate without it — which is exactly the failure
`references/decision-register-format.md` §2 exists to prevent, displaced out of `argumentation` and
into a file nobody sends them. Withholding it would also have been **concealed but reachable**: a
customer who pulls the specs repository rather than taking the archive can open every file in the
folder, so the rule would have held on one delivery route and failed silently on the other.
```

- [ ] **Step 2: Add the corpus row and update §6's class list**

In §6's preamble, change `the eight classes §6.1's table covers, `[BR#n]`, `[DEF#n]`, `[CG#n]`, `[DG#n]`, `[VD#n]`, `[CD#n]`, `[AS#n]` and `[SR#n]`` to `the nine classes §6.1's table covers, `[BR#n]`, `[DEF#n]`, `[CG#n]`, `[DG#n]`, `[VD#n]`, `[CD#n]`, `[AS#n]`, `[CDF#n]` and `[SR#n]``.

In §6.1's `| Class | Corpus file, within the partition |` table, insert one row immediately after the `[VD#n]`, `[CD#n]`, `[AS#n]` row:

```markdown
| `[CDF#n]` | `code-defect-log.md` (`references/code-defect-log-format.md` §2) — **absent where the folder holds no entry**, which is an empty corpus and passes |
```

Then add this paragraph immediately after the paragraph beginning **"A corpus that yields zero ids is one of two states"**:

```markdown
**A `[CDF#n]` corpus that is absent altogether is the third ordinary state, and it is not the
unreadable one.** `commands/brd-interview.md` writes `code-defect-log.md` only where a round raised
an entry, so a package whose decisions turn on no code defect ships no log at all — and §1.1's row
for it is conditional for that reason. An absent corpus file is not a corpus holding record-shaped
content that parsed to zero, so it never reaches `BRD_PACKAGE_CORPUS_UNREADABLE`; a `defects` field
naming a `[CDF#n]` with no log in the bundle fails relation 1 as an ordinary dead citation, which is
the correct outcome and needs no stop of its own.
```

- [ ] **Step 3: Read the log in Phase 0 step 10**

In `commands/brd-package.md` Phase 0's step 10 (**"Read the inputs the rest of the run works from"**), add `code-defect-log.md` to the enumerated input list, marked as read **where present** — the file is absent on a package whose decisions turn on no defect, and its absence is never a gate.

- [ ] **Step 4: Update the eleven-part table's three source cells**

In the `| # | Part | Filled from |` table, change three cells in the third column:

- row 6: `` `coverage-ledger.md` dispositions and `brd/brd-inventory.md` `` → `` `coverage-ledger.md` dispositions, `brd/brd-inventory.md`, and every `in-scope` `[CDF#n]` ``
- row 8: `` the prerequisites resolved above, and every `conditional_on` position (D20) `` → `` the prerequisites resolved above, every `conditional_on` position (D20), and every `conditional` `[CDF#n]` ``
- row 11: `` the ledger, the prerequisites, and the review's own limits `` → `` the ledger, the prerequisites, every `out-of-scope` `[CDF#n]`, and the review's own limits ``

**The eleven parts stay eleven.** No part is added, renumbered or merged; three of them gain a source.

- [ ] **Step 5: Write the three parts' rules**

Append to **Part 6 — Review scope**:

```markdown
**And every `[CDF#n]` disposed `in-scope`**, named by id with its `statement` and its `intent`, under
one line saying plainly that repairing it is inside this package's scope and that the requirements
above depend on it. A defect the delivery team has undertaken to fix is scope, and a scope section
that omits it understates what the customer is agreeing to.
```

Append to **Part 8 — what could still move (D20)**:

```markdown
**And every `[CDF#n]` disposed `conditional`**, named by id with its `statement` and its `blocked_on`.
An unsettled scope condition on a repair is exactly what this part is for: say what would have to be
settled before the delivery team can say whether the repair is in scope, and — as with an unreviewed
prerequisite — tell the customer's reviewer to mark the affected approvals contingent rather than
listing them as blockers.
```

Append to **Part 11 — what this session cannot settle**:

```markdown
**And every `[CDF#n]` disposed `out-of-scope`**, named by id with its `statement`, under one line
saying the defect is recorded and this engagement will not repair it. A known defect the package will
not fix is a limit on what the package can promise, and a customer who meets it here can argue about
it while the scope is still open — which is cheaper for both sides than meeting it after delivery.
```

- [ ] **Step 6: Update the allow-list prose on the documentation page**

In `plugins/product-workflows/docs/commands/brd-package.md`, in the sentence beginning `What the bundle *does* hold is an allow-list`, add `the code-defect log where the folder holds one;` to the enumeration, immediately after `the decision register;`.

- [ ] **Step 7: Run the full gate set and verify green**

Run all seven gates. Expected: every one passes; `validate-catalog.py .` still reports `0 error(s), 2 warning(s)`.

- [ ] **Step 8: Commit**

```bash
git add plugins/product-workflows/references/bundle-packaging.md \
        plugins/product-workflows/commands/brd-package.md \
        plugins/product-workflows/docs/commands/brd-package.md
git commit -m "feat(brd-package): ship the code-defect log, and resolve [CDF#n] citations"
```

---

### Task 5: `brd-package-reviewer` — the sixth hunt class

**Files:**
- Modify: `plugins/product-workflows/agents/brd-package-reviewer.md` (`## Inputs`; `## What you are hunting`)

**Interfaces:**
- Consumes: Task 1's record, Task 2's `defects:` field, Task 3's artifact path.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Add the optional input**

In the `## Inputs` YAML block, add one line to `package:`, immediately after the `ledger:` line:

```yaml
  defects:          <path to code-defect-log.md, when the folder holds one>
```

Then add this sentence to the paragraph that begins **"Presence is the right test here, and an emptiness test would be wrong"**:

```markdown
**`package.defects` is optional and its absence is never `INPUT_MISSING`.** `commands/brd-interview.md`
writes the log only where a round raised a `[CDF#n]`, so a package whose decisions turn on no code
defect legitimately has none — and class 6 below is precisely the check that a package which *claims*
one has it, which an input gate could not perform.
```

- [ ] **Step 2: Add the sixth class**

In `## What you are hunting`, change `These five classes are.` to `These six classes are.` Then append, after class 5:

```markdown
6. **An argumentation that asserts a defect nothing holds.** For every `[VD#n]`, `[CD#n]` and
   `[AS#n]`, read the `argumentation` for a claim that a defect in the code **is recorded**, has been
   **raised**, or is **known** — and then check the record's own `defects` list. Where the prose
   makes such a claim and `defects` is empty, or names a `[CDF#n]` that is not in
   `code-defect-log.md`, that is a finding. **This is a claim about the package's own artifacts
   rather than about the code**, which is what separates it from class 4: the prose is not asserting
   more than a finding establishes, it is asserting that a record exists. The characteristic damage
   is that the register then reads as handled — a reader who meets *"the defect is recorded against
   it"* stops looking, and the defect reaches the customer as a settled matter with nothing behind
   it. Two live instances in one shipped register survived drafting, the round record and a first
   adversarial review, which is why this class is here rather than left to a pattern: the judgment
   is yours, and no static check in this repository can make it.
```

- [ ] **Step 3: Run the full gate set and verify green**

Run all seven gates. Expected: every one passes; `validate-catalog.py .` still reports `0 error(s), 2 warning(s)`.

- [ ] **Step 4: Verify the class count by hand**

Run:

```bash
awk '/^## What you are hunting/,/^## Process/' plugins/product-workflows/agents/brd-package-reviewer.md | grep -cE '^[0-9]+\. \*\*'
```

Expected: **6**. The prose sentence and the numbered list must agree, and nothing gates that.

- [ ] **Step 5: Commit**

```bash
git add plugins/product-workflows/agents/brd-package-reviewer.md
git commit -m "feat(brd-package-reviewer): hunt an argumentation asserting a defect nothing holds"
```

---

### Task 6: Counts, the blurb, versions and the changelog

**Files:**
- Modify: `plugins/product-workflows/README.md`
- Modify: `plugins/product-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/product-workflows/CHANGELOG.md`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: everything Tasks 1–5 shipped.
- Produces: `product-workflows` 3.3.0.

- [ ] **Step 1: Re-derive the count census rather than trusting this plan**

Run:

```bash
grep -rniI 'nine reference' plugins/product-workflows/ CLAUDE.md .claude-plugin/marketplace.json | grep -v CHANGELOG
find plugins/product-workflows/references -type f | wc -l
```

Expected: **six** hits and a file count of **10**. Five of the six are sites to change — `plugins/product-workflows/README.md`, `plugins/product-workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `CLAUDE.md` twice (its `product-workflows` paragraph, and the plugin-update section's *"their twelve agents or their nine references"*, which a per-paragraph edit would walk past). `CHANGELOG.md` carries a seventh, historical, and is **left alone**.

**The sixth hit is a decoy and changing it is a defect.** `CLAUDE.md`'s `workflows-core` paragraph reads *"twenty-nine reference files"*, which contains `nine reference` as a substring and belongs to a different plugin whose count this change does not touch. **Never run an unanchored substitution over these hits.** A blind `nine reference` → `ten reference` produces `twenty-ten reference files`, and nothing in the gate set would catch it — this repository's own `CLAUDE.md` records the identical failure in check 10, where an unanchored match produced 38 failures on correct pages. Edit each site by hand, reading the sentence around it first.

**Two of the five need different replacement text.** Four read `Nine`/`nine reference pages` or `nine reference files` and become `Ten`/`ten`; `CLAUDE.md`'s plugin-update sentence reads `their nine references` — plural — and becomes `their ten references`.

**Fix every site the grep returns, not the ones this plan lists.** The census was measured on 2026-09-08 and the tree may have moved.

- [ ] **Step 2: Trim and correct the blurb, in both editions**

The `product-workflows` `description` is at 988 of 1024 characters and both editions warn. Make exactly two changes to the text, identically in `plugins/product-workflows/.claude-plugin/plugin.json` and in the `product-workflows` entry of `.claude-plugin/marketplace.json`:

1. Change `Nine reference pages define the BRD, decision-register, coverage-ledger, customer-review, idea, ARD and specification artifact formats.` to `Ten reference pages define the BRD, code-defect-log, decision-register, coverage-ledger, customer-review, idea, ARD and specification artifact formats.`
2. **Delete** the closing sentence entirely: `Depends on workflows-core for its shared foundation and phase handoff, and on prose-style, whose prose-style-checker is /epics's primary style checker.` — it restates `plugin.json`'s machine-readable `dependencies` field, which is where a host actually reads it.

**Do not reformat `marketplace.json`.** Change only that entry's `description` and `version` values; leave every byte of surrounding structure as it is.

- [ ] **Step 3: Bump the version in both editions**

`3.2.0` → `3.3.0` in `plugins/product-workflows/.claude-plugin/plugin.json` and in the `product-workflows` entry of `.claude-plugin/marketplace.json`. They must match or `validate-catalog.py` fails.

- [ ] **Step 4: Verify the blurb arithmetic**

Run:

```bash
python3 -c "
import json
a=json.load(open('plugins/product-workflows/.claude-plugin/plugin.json'))['description']
d=json.load(open('.claude-plugin/marketplace.json'))
b=[p['description'] for p in d['plugins'] if p['name']=='product-workflows'][0]
print('plugin.json:', len(a)); print('marketplace:', len(b)); print('identical:', a==b)
"
python3 scripts/validate-catalog.py . 2>&1 | tail -3
```

Expected: both lengths **under 900**, `identical: True`, and `0 error(s), 0 warning(s)`. **Zero warnings is the assertion** — it is the outcome that closes G3-4's warning half, and two warnings means the trim did not land in both editions.

- [ ] **Step 5: Fix `README.md` and `CLAUDE.md`**

In `plugins/product-workflows/README.md`, change `Nine reference pages` to `Ten reference pages` and add `code-defect-log` to the format enumeration in the same sentence.

In `CLAUDE.md`, change the two `product-workflows` sites found in step 1 — the plugin paragraph's `nine reference files` → `ten reference files`, and the plugin-update section's `their nine references` → `their ten references`. **Leave the `workflows-core` paragraph's `twenty-nine reference files` exactly as it is**; it is step 1's decoy. Then update the workflow map's `/brd-interview` line to name the new artifact, changing `write decisions.md + interview/round-N.md + interview/customer-questions.md` to `write decisions.md + interview/round-N.md + interview/customer-questions.md + code-defect-log.md (where a decision turns on a [CDF#n])`.

- [ ] **Step 6: Write the changelog entry**

Add a `## 3.3.0` entry at the top of `plugins/product-workflows/CHANGELOG.md`, matching the file's existing entry shape. It must carry: the new `[CDF#n]` record and its reference; `/brd-interview` as its only writer and why `/prd-ground` is not; the `defects:` field and why it is not `evidence`; the log shipping in the bundle and why (a defect disposed `in-scope` is the delivery boundary); the reviewer's sixth class; and — from the spec's §10 — that a code defect never becomes a customer question, that there is no `fixed` disposition, and that the prose-trigger check the ledger anticipated was **not** built because the tree carries no corpus to measure it against.

- [ ] **Step 7: Run the full gate set and verify green**

Run all seven gates. Expected: every one passes, and `validate-catalog.py .` reports `0 error(s), 0 warning(s)`.

- [ ] **Step 8: Commit**

```bash
git add plugins/product-workflows/README.md \
        plugins/product-workflows/.claude-plugin/plugin.json \
        plugins/product-workflows/CHANGELOG.md \
        .claude-plugin/marketplace.json \
        CLAUDE.md
git commit -m "chore(product-workflows): 3.3.0 — counts, blurb trim, changelog"
```

---

## Whole-branch sweep, before the final review

Run this after Task 6 and before dispatching the whole-branch review. It is not optional: every increment on this route has found defects here that the per-task reviews walked past, and all of them were of the same class — prose deriving an obligation from an enumeration this change grew.

- [ ] **Sweep 1 — the "nowhere to record it" claims.** Scoped to `plugins/`, never to one plugin:

```bash
grep -rniE 'nowhere to record|no code-defect|only home|no place to record' plugins/ --include=*.md | grep -v CHANGELOG
```

Rewrite each hit against what the shipped record actually holds, read out of `code-defect-log-format.md` rather than assumed. **A phrase hit dispositions the whole paragraph, not the matched sentence.**

- [ ] **Sweep 2 — the exclusivity probe, as its own axis.** This is where a falsified claim hides when it names none of the vocabulary this change introduced:

```bash
grep -rniE 'only when|is the only|nothing else|and no other|only ever' plugins/product-workflows/ --include=*.md | grep -v CHANGELOG
```

Read each against the change. The likely casualties: a sentence claiming a defect log is always the parent's; a sentence enumerating what `/brd-interview` writes; a sentence enumerating what the bundle contains.

- [ ] **Sweep 3 — the two censuses, re-derived rather than trusted:**

```bash
grep -rn 'nine reference\|Nine reference' plugins/ CLAUDE.md | grep -v CHANGELOG   # expect: nothing
grep -rn 'allow-list' plugins/product-workflows/                                    # every site that enumerates bundle contents
grep -rn 'eight classes' plugins/product-workflows/                                 # expect: nothing
grep -rn 'five classes' plugins/product-workflows/agents/                           # expect: nothing
```

- [ ] **Sweep 4 — end-to-end reads, not greps.** The two most expensive misses on the sibling branch contained none of the swept phrases. Read in sequence, whole: `commands/brd-interview.md` Phases 6, 9 and 10; `commands/brd-package.md` Phase 0 step 10 and the eleven-part section; `references/bundle-packaging.md` §1.1, §6.1 and §6.2; `references/decision-register-format.md` §1, §6 and §7.

- [ ] **Sweep 5 — the deliverable-paths relation.** `/brd-interview` Phase 10 enumerates what the run wrote. Confirm `code-defect-log.md` is in it, conditionally, and that its `body_facts` names `[CDF#n]`. This is the glob-coverage class and it is invisible to a search for anything this change introduced.

---

## Self-review

**Spec coverage.** §1 → Task 1 step 1 (§1 of the new reference). §2's decision → Tasks 1–5; §2's two rejected alternatives → Task 1's §1 sibling-precedent paragraph and Task 6's changelog. §3 the record → Task 1 step 1 (§2, §3). §4 dispositions and the scope condition → Task 1 step 1 (§4, §5). §5 the writer → Task 3 steps 1–3; the `/prd-ground` exclusion → Task 6's changelog. §6 the register field → Task 2, all steps. §7 the bundle → Task 4 steps 1–6. §8 E-3b → Task 3 step 1 (the structural offer) and Task 5 (the reviewer class); the retirement of the prose trigger → Task 3 step 1's own paragraph and Task 6's changelog. §9 sweep, counts and version → Task 1 step 3, Task 6, and the whole-branch sweep. §10 out-of-scope → Task 1's §6 Non-goals and Task 6's changelog. §11 risks → Task 3 step 1's "the offer is a convenience, not the gate", Task 1's `intent_basis` §3, and Task 4 step 1's ship rationale.

**Placeholder scan.** No `TBD`, no `TODO`, no "add appropriate error handling", no "similar to Task N". Every step that edits a file quotes the text to insert. Task 6 step 6 describes the changelog entry's required content rather than quoting it, which is deliberate: a changelog entry is prose about what shipped, and quoting it here would freeze a summary that the five preceding tasks may legitimately have moved.

**Name consistency.** The reference file is `code-defect-log-format.md` and the artifact is `code-defect-log.md` in every task — the format/artifact pair follows `coverage-ledger-format.md`/`coverage-ledger.md` and `decision-register-format.md`/`decisions.md`. The field is `defects` in the table and `defects:` in YAML, consistently. The prefix is `[CDF#n]` throughout. The five dispositions are spelled `open`, `in-scope`, `out-of-scope`, `conditional`, `withdrawn` in Tasks 1, 4 and 5 alike.

**One gap deliberately left.** No task adds a `check-docs.sh` case, because nothing this change ships is statically checkable beyond the inventories checks 4 and 9 already gate. The spec's §8 states why, and the whole-branch sweep is what stands in for it.

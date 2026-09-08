# `/prd-proposal` and `/brd-proposal` — effort proposals — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `product-workflows` two commands that author a customer-facing effort proposal — work packages, hours by package and role, ranged by per-package confidence, every cost driver citing a record that exists on disk — for one `PRD-` slice and for a `BRD-` container's roll-up.

**Architecture:** One new reference fixes the document (`proposal-format.md`). Two new commands author against it — `/prd-proposal` for a slice, `/brd-proposal` for the umbrella — each writing `proposal.md` plus a derived `proposal-brief.md` from one resolved data set, so the two cannot disagree. One new Opus agent, `proposal-reviewer`, checks the arithmetic and the evidence chain before either document reaches a customer. The commands **grade rather than gate**: a four-tier readiness grade caps per-package confidence, and nothing downstream reads a proposal or requires one.

**Tech Stack:** Markdown instruction files only. No code, no runtime. The repository's seven CI gates are the test harness.

**Spec:** `docs/superpowers/specs/2026-09-08-proposal-commands-design.md`

**Ledger:** none. This is a new capability rather than a repair, and it opens no entry in `docs/superpowers/brd-route-follow-ups.md`.

## Global Constraints

- **Vendor neutrality is a hard constraint on this work, not a style preference** (spec §13). The design was reverse-engineered from real customer-facing proposals. **No organisation name, product name, customer name, personal name, repository name, requirement identifier or monetary or hours figure originating in those documents may appear anywhere in the plugin** — not in a command, an agent, a reference, a README, a docs page, an example or a fixture. Where an example is needed, invent one. The repository is public and the marketplace is installed by third parties.
- **No money for human hours, anywhere** (spec §9). No rate, no currency symbol, no monetary total appears in the profile, in either artifact, in either command, in the reference or on any docs page, at any tier, under any flag. The USD figures `workflows-core:cost-emission` emits are model spend and are a different quantity; no file written here may conflate the two.
- **Every requirement ID a plugin file *teaches* is the bracketed `[PREFIX#N]` form.** `./scripts/check-id-grammar.sh --root .` scans `plugins/**` including `plugins/*/docs/`, and its `PATTERN` covers `US|AC|SM|SMC|UC|FR|AD` with `NUM='[NnXx0-9]'`. **Writing `FR-843`, `AC-n` or `US-N` anywhere in a new file turns that gate red.** Spec §10's rule — that a proposal cites a requirement in the form the *source artifact* carries — is a rule about the document a **run** writes, and it is stated in the plugin without ever spelling a dash-form example of a covered prefix. Where an illustration is unavoidable, use a prefix outside the pattern (`REQ-12` is safe) and say so.
- `[WP#n]` and `[ED#n]` are **not** added to `check-id-grammar.sh`'s `PATTERN`, and that is deliberate (spec §12.3): nothing pastes a work-package label into a tracker, and the family's eight other bracketed namespaces are outside it for the same reason. Do not "fix" it.
- **Match the wrap of the file you are editing.** These files are hard-wrapped at ~100 columns in their source; `workflows-core:prose-formatting` governs the prose a *run* writes, not this repository's own instruction files. Wrap new paragraphs exactly as their neighbours do.
- **Never restate a rule another file owns — cite it.** Both commands cite `workflows-core:addressing` §3 for resolution, `workflows-core:phase-handoff` §2/§3 for the handoff and the gate, `workflows-core:specs-repo-git` §3/§4 for preflight and commit, `workflows-core:escalation-rules` §0 for every choices array, `workflows-core:grounding-format` for what makes a finding evidence, and `product-workflows:coverage-ledger-format` §5.1 for the legacy-folder container test.
- **The container test is the directory prefix, never the folder's asserted `kind:`.** `/brd-split` writes `kind: brd` into a `brd-link.md` inside a `PRD-` slice folder, so a slice asserts `brd` while being exactly the folder a proposal belongs in. An asserted-kind gate would refuse every slice and accept nothing.
- **Neither command gates anything downstream** (spec §3, §15). No other command reads `proposal.md`, requires one, or changes behaviour when one exists. No file written here may say or imply that work waits on a proposal, and no tier may withhold permission to build.
- **Every `choices:` array carries 2–4 options and never an authored "Other"** (`workflows-core:escalation-rules` §0; `check-docs.sh` check 12). The harness supplies the free-text escape itself.
- **A Phase 0 refusal is a prose stop block in a fenced code span, never a `choices:` array.** This matches every existing `*_NOT_SLICED` refusal in the family, and it also keeps the refusal out of check 11's offer scanner, where a mid-run redirect naming a command it feeds would demand a `<merge-clause>` that has no `Phase handoff:` line to resolve from.
- **No refusal in either command calls `emit-block`.** Both commands' stops report the state of the operator's own tree, not a capability the plugin lacks — the same class as `CREATE_PRD_BRD_NOT_SLICED` (`workflows-core:feedback-emission`).
- **Plugin `description` hard cap 1024 characters, warning at 900.** A capability change **replaces** wording; it never appends. `.claude-plugin/marketplace.json` is edited in place and **never reformatted** — change only the `version` and `description` values of the entries named.
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

**Measured baseline on the branch tip before Task 1: `validate-catalog.py .` reports `0 error(s), 0 warning(s)`, and every other gate passes.** Zero warnings is the expected outcome of every task including Task 6 — the re-worded blurb must land **at or under 900 characters**, not merely under 1024, or the baseline regresses.

## Rulings this plan makes, so no task has to guess

Four questions the spec deliberately left to derivation. Each is settled here once, and every task uses the settled value.

1. **The cost-attribution pair is `phase: proposal`, `role: pm` for both commands.** Spec §12.3 names `brd-to-prd`/`pm` as *natural* and instructs deriving rather than copying. Deriving refuses it: `/prd-proposal` runs on the idea route too (spec §3), where filing its spend under a BRD-route phase would be wrong, and an effort proposal is its own lifecycle activity rather than a step of that route. `proposal` is a new phase value; nothing enumerates phase names in code — `session-cost.py` groups by whatever it reads — so the only consequences are documentation ones, and they are itemised in Tasks 2 and 4.
2. **The archive convention is `/update-prd`'s, applied to these two filenames** (spec §10 defers to it): the prior canonical is moved to `<folder>/revisions/<KEY>_proposal_<YYYYMMDD>.md`, and the prior brief to `<folder>/revisions/<KEY>_proposal-brief_<YYYYMMDD>.md`, before the new one is written. A second revision on the same day takes the suffix `-2`, `-3`, … exactly as `/update-prd` Phase 5 step 1 defines it.
3. **Each command's `phase-handoff.md` §3.4 row-F row ships in the task that adds the command**, not in Task 5. Spec §17 lists both check-11 declarations under Task 5, while spec §12.3 — the later and more considered statement — makes a per-command surface ship with its command and names `deliverable_paths` as one. A row-F row is a per-command surface by exactly that test, it cannot be written before the command it describes exists, and `/prd-proposal`'s offer of `/brd-proposal` only becomes clause-*required* once `/brd-proposal`'s own row lands with `/brd-proposal` in Task 4. Task 5 keeps what is genuinely cross-command: the offers **into** the new commands, both routing-graph nodes, the scope-paragraph prose, and the verification that check 11's relation actually binds.
4. **`docs/brd-workflow.md` is not edited.** It draws the six-command BRD-to-PRD route. `/brd-proposal` is an umbrella over that route's output, offers no forward advance and is not a route step (spec §8); adding it would make that page disagree with its own opening sentence. Check 15 does not reach that page. Recorded so it is not "fixed" later.

## Two things every task must know about the gates

**Check 9's word list is not complete, and the wrong word makes the gate report *"the wording drifted"* rather than a wrong number.** Its reference-file alternation runs `one|…|ten|twenty-one|thirty-four|ninety-eight|[0-9]+` — **`eleven` is not in it**. Every plugin in this tree above ten uses the numeral for that sentence (`15 files`, `29 files`, `38 files`), and this plan follows that: the references page says **`11 files`**, never `eleven files`. The commands alternation is missing `eleven`…`fourteen` too, so `plugins/product-workflows/README.md` keeps its existing numeral form (`13 slash commands`, then `14 slash commands`). The cost-emitting alternation **does** carry `thirteen` and `fourteen`, so `docs/reference/session-cost.md` keeps its word form.

**Check 15 asserts three index surfaces per command, and one of them is the mermaid diagram itself.** A command added without a node in `docs/workflow.md`'s ` ```mermaid ` block fails, and prose below the diagram does not count. Both new commands therefore reach `docs/README.md`, `plugins/product-workflows/README.md` **and** the diagram in the task that adds them — which is why spec §17's Task 6 list, which puts the diagram last, is followed for the *narrative* parts of those pages and not for the per-command entries.

---

## File Structure

| File | Responsibility in this change |
|---|---|
| `plugins/product-workflows/references/proposal-format.md` | **NEW.** The section set of both artifacts, the `[WP#n]`/`[ED#n]` namespaces, the tier→ceiling and grade→band tables, the band-deviation rule and its severity tiering, the three evidence classes, the brief's full content, the identifier-form rule, and the risk disclosure |
| `plugins/product-workflows/commands/prd-proposal.md` | **NEW.** The slice command: resolution, the two refusals, the `prd.md` gate, the profile grill, grading, work packages, drivers, hours, both artifacts, the review gate, handoff, offers |
| `plugins/product-workflows/commands/brd-proposal.md` | **NEW.** The umbrella: slice enumeration, the readiness walk, the roll-up and its three adjustments, coverage from the root ledger |
| `plugins/product-workflows/agents/proposal-reviewer.md` | **NEW.** Opus, read-only, adversarial; eleven checks; returns findings plus PASS / PASS WITH RECOMMENDATIONS / BLOCK |
| `plugins/product-workflows/docs/commands/prd-proposal.md` | **NEW.** Per-command page in the house shape |
| `plugins/product-workflows/docs/commands/brd-proposal.md` | **NEW.** Per-command page in the house shape |
| `plugins/product-workflows/docs/reference/references.md` | Row for `proposal-format.md`; the two `ten files` counts → `11 files` |
| `plugins/product-workflows/docs/reference/agents.md` | Row for `proposal-reviewer`; `12` → `13` (three sites); `Six carry a model: opus` → `Seven`; `all 12 commands` → `13`, then `14` |
| `plugins/product-workflows/docs/reference/session-cost.md` | Two table rows; `Twelve commands emit` → `Thirteen`, then `Fourteen`; the intro's `twelve commands` |
| `plugins/product-workflows/docs/reference/model-routing.md` | The `All twelve commands` sentence and its enumerated list |
| `plugins/product-workflows/docs/reference/environment.md` | `these twelve commands` |
| `plugins/product-workflows/docs/reference/session-feedback.md` | Two `all twelve` sites |
| `plugins/product-workflows/docs/reference/resume-and-checkpoints.md` | Two `twelve commands` sites |
| `plugins/product-workflows/docs/roles-and-phases.md` | New `### proposal` phase section; `Six phases … twelve commands`; the `plugin-feedback` paragraph's `twelve commands` |
| `plugins/product-workflows/docs/README.md` | Two "I want to…" rows; two `## Commands` entries |
| `plugins/product-workflows/docs/workflow.md` | Two diagram nodes and their edges; the `twelve commands` collision sentence |
| `plugins/product-workflows/README.md` | Role-table rows; `12 slash commands` (check 9); `Twelve agents`; `Ten reference pages`; `The twelve commands as one diagram` |
| `plugins/workflows-core/references/cost-emission.md` | §7 attribution table gains one row per command |
| `plugins/workflows-core/references/phase-handoff.md` | §3.4 row-F table gains one row per command |
| `plugins/workflows-core/references/next-phase-offer.md` | Routing graph gains both nodes; the scope paragraph's `five /product-workflows:brd-* commands` prose |
| `plugins/workflows-core/references/specs-repo-git.md` | The `twenty-four callers` count |
| `plugins/workflows-core/references/feedback-emission.md` | The `nineteen of the twenty-four callers` count |
| `plugins/workflows-core/scripts/command-namespaces.json` | Two entries under `product-workflows` |
| `plugins/product-workflows/commands/brd-reconcile.md`, `create-ard.md`, `specify.md` | One offer of `/product-workflows:prd-proposal` each |
| `plugins/product-workflows/.claude-plugin/plugin.json` | version `3.4.0`; blurb re-worded |
| `plugins/workflows-core/.claude-plugin/plugin.json` | version `1.4.0` |
| `.claude-plugin/marketplace.json` | the two entries' `version`, and `product-workflows`'s `description` |
| `plugins/product-workflows/CHANGELOG.md`, `plugins/workflows-core/CHANGELOG.md` | One entry each |
| `CLAUDE.md` | The workflow map, the plugin paragraph, the docs-page total, four shared-reference counts, the model-routing list |

**Task order is forced by citation direction and by the gates.** Task 2 authors against Task 1's format. Task 3 checks the shape Task 2 actually emits. Task 4 reads the `proposal.md` files Task 2's command writes and de-duplicates on the driver citations it produces. Task 5 wires edges that need both commands to exist. Task 6 documents all five. **Each task carries its own gated surfaces** — the docs page, the count sentences, the cost row, the manifest entry, the index membership — because `check-docs.sh` gates every inventory in both directions and a task that commits red makes the next task's verification unable to distinguish its own breakage from the previous task's debt. Do not reorder and do not defer a count.

**One incompleteness is deliberate and must not be "fixed" by reordering.** Task 2 ships a command whose review phase dispatches `product-workflows:proposal-reviewer`, which Task 3 creates. Between those two tasks the capability is incomplete and the build is green; nothing merges until the branch is finished. Spec §17 argues this at length: *"the reviewer is not a later increment"* is about the **release unit**, not the task unit, and the reviewer cannot be specified against a command that does not exist. No gate asserts that a dispatched `subagent_type` resolves.

---

### Task 1: `proposal-format.md` — the document contract, and the two gates it trips

**Files:**
- Create: `plugins/product-workflows/references/proposal-format.md`
- Modify: `plugins/product-workflows/docs/reference/references.md` (new group after `## PRD-ladder formats`; the two count sentences on lines 3 and 27)
- Modify: `plugins/product-workflows/README.md` (line 18, `Ten reference pages` → `Eleven reference pages`, and the sentence's list of what the references define)

**Interfaces:**
- Consumes: nothing. This is the first task and cites only files that already exist.
- Produces — every later task uses these exact spellings:
  - **Section numbers** in `proposal-format.md`: §1 scope and the two quantities · §2 artifacts, paths and archiving · §3 the namespaces · §4 `proposal.md`'s section set · §5 tiers and the confidence ceiling · §6 grades, default bands and the deviation rule · §7 work packages · §8 the estimate · §9 the range's own exclusions · §10 `proposal-brief.md`'s section set · §11 identifier form · §12 the changelog section · §13 the residual risk.
  - **Identifier prefixes** `[WP#n]` and `[ED#n]`.
  - **Artifact paths** `proposal.md`, `proposal-brief.md`, and the archived `revisions/<KEY>_proposal_<YYYYMMDD>.md` / `revisions/<KEY>_proposal-brief_<YYYYMMDD>.md`.
  - **Tier names** `1 · Indicative`, `2 · Grounded`, `3 · Architected`, `4 · Specified`.
  - **Grade names** `High`, `Medium`, `Low`.
  - **Evidence class names** `verified grounding finding`, `frozen decision`, `confirmed code defect`.

- [ ] **Step 1: Write the failing test — create the file and watch two gates go red**

Create `plugins/product-workflows/references/proposal-format.md`. Open with the core-references preamble every `product-workflows` reference carries (copy the two-line block verbatim from the top of `references/decision-register-format.md` — check 16 requires it in any file that cites a `workflows-core:` reference, and this one cites several), then write the thirteen sections below. Prose is hard-wrapped at ~100 columns to match its neighbours.

````markdown
# Effort-proposal format (embedded authority)

The canonical shape of the two artifacts `/prd-proposal` and `/brd-proposal` write: the section set
each carries, the two identifier namespaces they mint, the readiness tiers that cap confidence, the
confidence grades that fix the range, the closed set of evidence classes a cost driver may cite, and
the rules a reviewer checks. Design authority:
`docs/superpowers/specs/2026-09-08-proposal-commands-design.md`.

**Written by `commands/prd-proposal.md` and `commands/brd-proposal.md`; reviewed against by
`agents/proposal-reviewer.md`.** Nothing else reads a proposal.

## 1. What this format governs, and the two quantities it must never conflate

An effort proposal states **what human delivery time a requirement set will take, in hours** — by
work package, by role, as a range, with an argument for the number that resolves to records on disk.

**The family already measures a different quantity called "cost".** `workflows-core:cost-emission`
records **model spend in USD** for a run of a command. The two are unrelated, and no sentence in
either artifact, in either command, or in this file may let a reader take one for the other.

**Neither artifact carries money at all** — no rate, no currency symbol, no monetary total for human
hours, at any tier, under any flag. Rates are contractual and belong in a document this pipeline does
not produce, and a git-committed rate card is a disclosure waiting to happen.

**A proposal gates nothing.** No command requires one, reads one, or behaves differently because one
exists, and no grade in this file withholds permission to begin work. A proposal is a document a
vendor sends a customer; it is not a phase and never a prerequisite.

## 2. The two artifacts, where they live, and how a revision is archived

| Artifact | Path | Rendered when |
|---|---|---|
| the proposal | `<folder>/proposal.md` | always |
| the rationale brief | `<folder>/proposal-brief.md` | tier ≥ 2 **and** `--no-brief` not given (§5) |

`<folder>` is the resolved folder itself — the `PRD-` slice for `/prd-proposal`, the `BRD-` container
for `/brd-proposal` — so the traceability section is relative links that resolve rather than names a
reader must go and find.

**Both artifacts open with a header block carrying the readiness tier beside the date.** A reader is
never handed a number without being told what grade of evidence stands behind it.

**A revision archives its predecessor before overwriting it**, following the canonical-plus-archived
convention `commands/update-prd.md` Phase 5 already establishes: the prior `proposal.md` moves to
`<folder>/revisions/<KEY>_proposal_<YYYYMMDD>.md` and the prior `proposal-brief.md` to
`<folder>/revisions/<KEY>_proposal-brief_<YYYYMMDD>.md`, a second revision on the same day taking the
suffix `-2`, `-3`, and so on. The new canonical records `revision_of:` naming the archived snapshot.

## 3. Two identifier namespaces, and deliberately only two

`[WP#n]` names a work package. `[ED#n]` names an estimate driver. Every hours figure, confidence
grade, schedule row, acceptance clause and scope lever attaches to a `[WP#n]`; every driver row to an
`[ED#n]`. Ids are contiguous, assigned once, and never renumbered within a revision chain.

**A re-estimate gate is a property of its `[WP#n]`, not a namespace of its own.** The family already
carries fifteen bracketed namespaces, and a sixteenth earning its keep is a higher bar than a
seventeenth being conceivable.

**Both stay in the bracketed form** even though the requirements they cite do not (§11): they are the
plugin's own identifiers, and nothing pastes a work-package label into a tracker. A mnemonic label for
a package is carried as the package's **title**, never as its identifier.

## 4. `proposal.md` — the section set

In this order. Two sections are conditional and are marked; every other section renders at every
tier, and a section with nothing to say says so rather than being omitted.

| # | Section | Notes |
|---|---|---|
| 1 | Header block | tier, date, `revision_of` where one exists, the engagement model from the profile |
| 2 | Scope | what is being estimated, in the customer's own terms |
| 3 | The naive baseline | §8 — mandatory at every tier, and printed before the drivers |
| 4 | Cost drivers | the `[ED#n]` table; at tier 1 an explicit statement that the drivers are **not known** |
| 5 | Work packages | the `[WP#n]` set — §7 |
| 6 | Hours by package and role | the `[WP#n]` × role grid, carrying an **Expected**, a **Low** and a **High** total column per package plus a totals row and a totals column — the shape the arithmetic check reconciles in both directions |
| 7 | Confidence and range | per package, with a stated reason; §6 |
| 8 | Re-estimate gates | one row per `[WP#n]` carrying one, with its trigger event |
| 9 | Delivery approach | how the packages sequence into deliverable increments |
| 10 | Team composition | roles and counts, from the profile |
| 11 | Indicative schedule | with peak concurrency, never a sum of FTEs |
| 12 | Assumptions | |
| 13 | Dependencies | including everything §8's open-items sweep produced |
| 14 | Risks | |
| 15 | What the range does **not** cover | §9 — a different list from section 18 |
| 16 | Change control | shaped by `engagement_model` |
| 17 | Acceptance | per package, which is why a package must be independently acceptable |
| 18 | Exclusions from scope | |
| 19 | Traceability | requirement identifiers → `[WP#n]`, in the form §11 fixes |
| 20 | Reconciliation to a prior estimate | **conditional** — renders only under `--baseline`; absent is not a gap and is never apologised for |
| 21 | Changelog | **conditional** — renders only on a revision; §12 |

## 5. Readiness tiers, and the ceiling each puts on confidence

The tier is **graded, never gated**. The only hard refusal on readiness is the absence of `prd.md`,
which the caller's `require-on-main` already performs.

| Tier | Reached when the resolved folder holds | What the tier changes |
|---|---|---|
| **1 · Indicative** | `prd.md` | the driver section states outright that the drivers are not known; standing banner in the header |
| **2 · Grounded** | \+ verified grounding, \+ a settled decision register | drivers carry evidence; **the floor for a document that goes to a customer** |
| **3 · Architected** | \+ `ard.md` | discovery becomes translation of an existing architecture rather than authoring one |
| **4 · Specified** | \+ `specification.md` | QA is sized from the authored test-case count; the definition of done is built from the acceptance criteria |

**Both tier conditions reuse rules that already exist.** *Verified grounding* means every finding
carries a verifier outcome — `workflows-core:grounding-format`'s rule that a finding without an
outcome is not evidence. *A settled register* means every interview round is settled, the test
`commands/brd-package.md` already applies.

**The tier caps confidence; it never sets it.** Range width is computed bottom-up from per-package
confidence (§6). The tier is a ceiling: evidence can only push a package lower.

| Tier | Highest grade any package may carry |
|---|---|
| **1 · Indicative** | **Low** |
| **2 · Grounded** | **Medium** |
| **3 · Architected** | **High** for a package an `[AD#n]` covers; **Medium** for one it does not |
| **4 · Specified** | **High** |

**At tier 1 the document carries one document-level re-estimate gate** — grounding the slice is its
trigger — rather than a per-package commitment against triggers nobody has scheduled. The grade stays
Low because Low is honest. **What does not ride on it is a prohibition** (§8).

**The brief does not render below tier 2**, irrespective of the flag: its spine is the driver
argument, and below tier 2 that spine does not exist. A two-page pre-read explaining why a number is
large, written when the reasons are unknown, is the one artifact this format must not produce.

**An idea-route PRD caps at tier 1 today, and that is a truthful grade rather than a defect.**
Verified grounding and a settled register are produced by the BRD-to-PRD route and by nothing else. A
code scan discovers capability; grounding asks whether a specific claim is true of a specific commit,
and only the second can carry a driver. A tier-1 proposal is still a real document — scope, packages,
team, schedule, a ranged number, every assumption and dependency. What it does not carry is the
argument for why the number is what it is.

## 6. Confidence grades, the default band, and what a deviation costs

| Confidence | Band about the expected figure |
|---|---|
| **High** | −15 % / +30 % |
| **Medium** | −20 % / +40 % |
| **Low** | −45 % / +80 %, and a declared re-estimate gate (§8) is **mandatory**, not optional |

**The band is the default the command computes, and any deviation from it — in either direction —
carries a stated reason in the confidence section.** Widening and narrowing are treated alike: an
earlier draft allowed free widening, and measured against the document this format is derived from it
failed three of that document's ten packages, all of them narrower than their grade's default on at
least one side. One of the three had been downgraded a grade between revisions and had kept the band
of the grade it left, which is drift no author notices and no reader can see.

**Severity, because a deviation is not one thing:**

- a deviation with **no stated reason** is a **recommendation**;
- a band **narrower than the default of the grade one step above** is a **BLOCKER** — a Medium
  package priced tighter than any High package claims precision its own grade denies, and no reason
  rescues that.

**Both comparisons carry a one-percentage-point tolerance.** Whole-hour rounding moves a band by up to
a point, and without the tolerance the rule fires on arithmetic rather than on judgement.

**Confidence is stated per package with a reason, and the document says in as many words that the low
and high figures describe a credible range rather than best and worst cases.**

## 7. Work packages

Requirements cluster by **delivery seam** — what can be built, tested and accepted independently. That
property is load-bearing: sections 9 and 17 of §4 both rest on it, and a package that cannot be
accepted on its own makes both of them false.

**Two packages are always present:** a discovery-and-design package first, and a test/UAT/release
package last. Where `EPIC-` folders exist under the resolved folder they seed the clustering of the
middle packages; where they do not, nothing is missing and the document says nothing about it. Epics
are never required.

**A defect-remediation package is created automatically, and it is never a scope lever.** Where the
folder holds an unrepaired code defect, its repair is its own `[WP#n]`. Asking a customer to authorise
deferring a defect the vendor's own work found returns that deferral carrying the customer's authority
on a question the vendor's policy has already answered.

**Three sources are swept and unioned**, because the obvious single source is necessary and nowhere
near sufficient — `code-defect-log.md` has one writer and it records only defects a decision turned on:

1. **`code-defect-log.md`** — every `[CDF#n]` not recorded as resolved. Needs no confirmation: a
   standing `[CDF#n]` is a defect somebody already adjudicated.
2. **A verified grounding finding whose own text records a defect** rather than a capability.
   **Operator confirmation required.**
3. **An `[SR#n]` self-review finding** in the packaged bundle, where one exists, naming a code defect
   and not recorded as resolved. **Operator confirmation required.**

Sources 2 and 3 need confirmation because neither is a defect *register*: a finding may already be
repaired, or may not be the vendor's to repair. A confirmed defect from any source is identical
downstream — same package, same exclusion from the lever table.

**A defect-remediation package never renders into the scope-lever table or the priced-options table.**
Where it cannot fit the delivery window, that is disclosed as a schedule fact, not tendered as an
option.

## 8. The estimate

**The naive baseline is computed and printed first**, at every tier: what the requirement would cost
if read at face value, with no correctness, completeness or enforcement obligation. It is the anchor
that makes the real number legible — without it the driver table has no subject.

**Every driver cites evidence from a closed set of three classes**, each resolving to something on
disk an independent reader can open:

1. a **verified grounding finding** — `[CG#n]` or `[DG#n]`, carrying the verifier outcome without
   which `workflows-core:grounding-format` says it is not evidence, cited with the `file:line` the
   finding itself records;
2. a **frozen decision** — `[VD#n]` or `[CD#n]` in the register, for the driver class that is *scope
   the customer added after the baseline*;
3. a **confirmed code defect** — `[CDF#n]`, or a §7-confirmed finding from either other source.

**A driver citing nothing from that set does not render at all.** The value of the rule is that it is
mechanically checkable rather than a matter of authorial care.

**The narrowing is per-driver, not global: a driver making a claim about the code cites class 1**,
because a decision cannot evidence a statement about a repository. Restricting the whole set to
grounding was the first draft of this rule and it was wrong — in the source engagement a driver worth
roughly a tenth of the estimate cited four decisions and no code, and was the single row the customer
was most likely to recognise as theirs.

**Hours per package and role** are derived from the requirement count and kind inside the package, the
drivers touching it, and the profile's productivity basis and hours-per-developer-day. **QA effort is
sized from the authored test-case count at tier 4 and from a stated ratio below it, and the document
says which of the two it used** — a ratio silently replaced by a count is a change of basis a reader
is entitled to see.

**A package graded Low carries a declared re-estimate gate naming its trigger event** — a profiling
result, an arriving decision, a load measurement. A wide range with a dated gate is an honest artifact;
a narrow range over unprofiled work is not.

**The no-hours commitment belongs to a gate, not to a grade.** An earlier draft attached *"no
implementation hours inside this package are incurred before the gate"* to the Low grade itself, which
composed with §5's tier-1 ceiling to make the ordinary output of this format a document forbidding any
work from starting. **The commitment is a property the operator attaches to a particular declared
gate**, where delivery genuinely should not begin before a trigger fires. Declaring the gate is
mandatory at Low; making the commitment is not, and a gate without one is a re-estimate promise rather
than a stop.

**Open items become dependencies automatically.** Open assumption records, unanswered customer
questions from the interview round, and any code defect recorded as blocking render into section 13
and into the brief's *what is needed before week 1* list. Derived from the register, never authored —
so a question raised of the customer and not yet answered cannot vanish between the review package and
the proposal.

**The stability rule, which is what makes a re-run safe.** A re-run always re-derives its inputs, but
the prior revision is an **anchor**: a package's expected hours carry forward unchanged unless
something feeding them changed, and where a figure moves the changelog (§12) names the cause. A figure
that moved with no cited cause is a defect. `--redo` discards the anchor deliberately, for when the
prior estimate is known to be wrong.

## 9. The range carries its own exclusions, and they are not the document's exclusions

Section 15 of §4 is a **short block stating what the low-to-high band does not cover** — a reversal of
a settled decision, a discovery that materially more of the system is live than the evidence records,
customer-side delay on a named dependency, a decision resolved in the direction that widens scope.

**This is a different list from section 18, exclusions from scope**, and conflating them is how a
reader concludes the high figure is a ceiling. It is not: it is the top of a band computed under stated
conditions, and this block is the conditions. They are two sections rather than one for that reason.

## 10. `proposal-brief.md` — the section set

The brief is a short pre-read, derived from the same resolved data set as the proposal and never
re-authored from it. **Its spine is the driver argument** — the naive baseline, why the number is not
that, and what the largest single share of the estimate is owed to.

**The spine is not the whole brief.** It also carries, in the customer's own terms and each derived
rather than written fresh:

| # | Section | Derived from |
|---|---|---|
| 1 | The driver argument | §8's baseline and `[ED#n]` table |
| 2 | Corrections this revision owes the customer | §12's correction rows |
| 3 | Reconciliation to their prior estimate | §4 section 20, where `--baseline` was given |
| 4 | Each deliberately-unpriced item, with the gate that will price it | §8's re-estimate gates |
| 5 | What is needed before week 1 | §8's open-items sweep |
| 6 | Any requirement where the vendor's architecture and the customer's own text still contradict each other | the register and the grounding findings |

**Every figure the brief repeats matches the proposal**, and every item in rows 2–6 that the proposal
carries reaches the brief. A spine-only brief is a defect, not a shorter brief: the brief is the
document that gets read first.

## 11. Which form a requirement is cited in

**A proposal cites a requirement in the form the source artifact carries it.** Every other artifact the
plugin writes is read by the operator or pasted into a tracker; a proposal is read by the **customer**,
who wrote those identifiers in their own document in their own form. Rendering the plugin's bracketed
form to a reader who has never seen it makes the traceability section unusable to its only reader.

**The two artifacts sit outside `workflows-core:pre-lint`'s *Auto-link collision* check, which is
scoped to PRD, ARD and Epic files, and that exclusion is deliberate rather than an oversight.** That
check is an auto-link detector for documents that get pasted into a tracker, and these two are not —
they are sent to a customer, as a document. Everything else `pre-lint` performs — its universal checks,
identifier integrity, required-section presence — does run.

**The `[WP#n]` and `[ED#n]` namespaces the proposal mints are the plugin's own and stay bracketed**
(§3). **A conversion in either direction is the defect** the reviewer looks for: an identifier read from
a source artifact keeps that artifact's form, and one the proposal minted keeps the bracketed form.

## 12. The changelog section, and the classification that is its whole value

Rendered on a revision only. One row per moved figure or changed section, each with a direction and a
pointer to the section that now carries it, generated by diffing against the anchor.

**Each row is classified, and the classification is computed rather than written:**

- a change that **withdraws or contradicts a statement the previous revision made to the customer** is
  a **correction**;
- a figure that moved is a **re-estimate**.

**Corrections are listed first, are stated in the customer's own terms, and are never folded into a net
total.** A revision that quietly nets a withdrawn claim against a re-estimate is precisely the artifact
this rule exists to prevent.

## 13. The risk this format cannot remove, stated to the operator who sends the document

**A plausible number with a defensible-looking argument is more dangerous than an obviously rough one.**
The tier in the header, the mandatory naive baseline, the citation rule that prevents a driver rendering
without evidence, and per-package confidence are the mitigations. The residual risk is real, and the
person sending the document is the one carrying it.

**Two limits of the checks, stated rather than left to be discovered.** The de-duplication check in an
umbrella run detects shared work only where two slices cite the **same** finding identifier; genuinely
shared work described from two different findings is not detected and the umbrella overstates. And a
productivity basis captured once and never revisited silently mis-scales every later proposal, which is
why the profile is shown back for confirmation on every run rather than read silently.
````

- [ ] **Step 2: Run the two gates that must now be red, and confirm they are red for the right reason**

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -E "check (4|9)" || echo "NOT RED"
```

Expected: a check 4 failure naming `proposal-format.md` as a reference file with no entry in `reference/references.md`, and a check 9 failure saying `docs/reference/references.md says ten (10), tree has 11`. If either is missing, the file was not created where the gate looks.

- [ ] **Step 3: Add the references-page entry and move both counts**

In `plugins/product-workflows/docs/reference/references.md`, change line 3 from `bundles ten files` to `bundles 11 files` — **the numeral, not the word**: check 9's reference-file alternation does not carry `eleven`, so the word makes the gate report that the wording drifted rather than that the number is wrong (every plugin in this tree above ten uses the numeral for this sentence).

Add a new group after the `## PRD-ladder formats` group's last bullet:

```markdown
## Effort-proposal format

The canonical structure of the two customer-facing estimate artifacts, and the rules a reviewer checks them against.

- `proposal-format.md` — the section set of `proposal.md` and its derived `proposal-brief.md`, the `[WP#n]` work-package and `[ED#n]` estimate-driver namespaces, the four readiness tiers and the ceiling each puts on per-package confidence, the three confidence grades with their default ranges and the tiered severity of a deviation from one, the closed three-class set of evidence a cost driver may cite, the rule that a defect-remediation package is never a scope lever, the range's own exclusions as a section distinct from exclusions-from-scope, the rule that a requirement is cited in the form its source artifact carries it — and why that puts these two artifacts deliberately outside `workflows-core:pre-lint`'s auto-link collision check — and the correction-versus-re-estimate classification a revision's changelog computes. `/prd-proposal` and `/brd-proposal` author against it and `proposal-reviewer` reviews against it.
```

Then change line 27 from `Every one of the ten files above` to `Every one of the 11 files above`.

- [ ] **Step 4: Move the plugin README's reference count**

In `plugins/product-workflows/README.md` line 18, change `Ten reference pages (see [References](docs/reference/references.md)) define the BRD, code-defect-log, decision-register, coverage-ledger, customer-review, idea, ARD and specification artifact formats.` to `Eleven reference pages (see [References](docs/reference/references.md)) define the BRD, code-defect-log, decision-register, coverage-ledger, customer-review, idea, ARD, specification and effort-proposal artifact formats.`

This sentence is not gated by check 9 — that assertion reads `docs/reference/references.md` — but a count left standing beside a tree that moved is its own defect.

- [ ] **Step 5: Run the full gate set and verify green**

Run all seven gates. Expected: every one passes, and `validate-catalog.py .` reports `0 error(s), 0 warning(s)`.

Then confirm the new file is reachable and its links resolve, since check 3 and check 1 gate those:

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -iE 'orphan|link|anchor' || echo "no link or orphan failures"
```

Expected: `no link or orphan failures`.

- [ ] **Step 6: Commit**

```bash
git add plugins/product-workflows/references/proposal-format.md \
        plugins/product-workflows/docs/reference/references.md \
        plugins/product-workflows/README.md
git commit -m "feat(product-workflows): add the effort-proposal format reference"
```

---

### Task 2: `/prd-proposal` — the slice command, with every per-command surface it moves

**Files:**
- Create: `plugins/product-workflows/commands/prd-proposal.md`
- Create: `plugins/product-workflows/docs/commands/prd-proposal.md`
- Modify: `plugins/workflows-core/references/cost-emission.md` (§7 table)
- Modify: `plugins/workflows-core/references/phase-handoff.md` (§3.4 row-F table)
- Modify: `plugins/workflows-core/scripts/command-namespaces.json`
- Modify: `plugins/product-workflows/docs/README.md`, `plugins/product-workflows/README.md`, `plugins/product-workflows/docs/workflow.md`
- Modify: `plugins/product-workflows/docs/roles-and-phases.md`, `docs/reference/session-cost.md`, `docs/reference/model-routing.md`, `docs/reference/environment.md`, `docs/reference/session-feedback.md`, `docs/reference/resume-and-checkpoints.md`, `docs/reference/agents.md`

**Interfaces:**
- Consumes: every section number, namespace and tier name Task 1 produced.
- Produces — Tasks 3, 4 and 5 use these exact spellings:
  - the command file's phase headings, listed in Step 1;
  - the two stop ids `PRD_PROPOSAL_BRD_NOT_SLICED` and `PRD_PROPOSAL_NEEDS_PROFILE`, and the two row-F stop ids `PRD_PROPOSAL_NEEDS_PRD` / `PRD_PROPOSAL_PRD_NOT_HANDED_OFF`;
  - the profile path `$SPECS_PATH/.dev-workflows/proposal-profile.yml` and its six top-level keys `vendor`, `client`, `engagement_model`, `roles`, `productivity`, `calendar`;
  - the cost pair `phase: proposal`, `role: pm`;
  - the declared writer set `proposal.md`, `proposal-brief.md`, `<KEY>_proposal_<YYYYMMDD>.md`, `<KEY>_proposal-brief_<YYYYMMDD>.md`;
  - the branch prefix `prd`;
  - the output shape Task 3's reviewer asserts over: the `[WP#n]`-by-role hours table with **Expected**, **Low** and **High** columns, one row per package and one column per role, plus a totals row and a totals column.

- [ ] **Step 1: Write the command file**

Create `plugins/product-workflows/commands/prd-proposal.md`. Model its structure on `commands/create-ard.md` (an authoring command with a reviewer gate) and its Phase 0 discipline on `commands/brd-package.md`. Frontmatter first:

```yaml
---
name: prd-proposal
description: Effort-proposal workflow (PM phase, optional and ungated on both routes) — author a customer-facing effort proposal for one PRD- folder. Grades the folder against four readiness tiers rather than gating on an ARD or a specification, and the tier caps how confident any work package may be. Derives work packages by delivery seam, hours by package and role, and a range computed bottom-up from per-package confidence; every cost driver cites a verified grounding finding, a frozen decision or a confirmed code defect, and a driver citing none of the three does not render. Creates a defect-remediation package automatically from three defect sources and never offers it as a scope lever. Writes proposal.md and a derived proposal-brief.md from one resolved data set, archives the prior revision, and gates on the Opus proposal-reviewer. Carries no money for human hours at any tier. Nothing downstream reads a proposal or waits on one.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---
```

Then the body, in this order. **The phase headings are an interface** — Tasks 3 and 5 cite them:

| Heading | What it does |
|---|---|
| `## Phase 0 — Resolve the address, preflight, and gate the PRD` | `specs-preflight`; `resolve-address`; the container refusal; `require-on-main` on `prd.md` |
| `## Phase 1 — Classify + model routing` | SIGNIFICANT, with the reason |
| `## Phase 2 — The proposal profile` | read, show back, or grill (§9 of the design) |
| `## Phase 3 — Grade the readiness tier` | the four tests, the printed tier, the ceiling it sets |
| `## Phase 4 — Derive the work packages` | delivery seams, the two fixed packages, the three-source defect sweep |
| `## Phase 5 — Derive the cost drivers` | the closed three-class evidence set, per-driver narrowing |
| `## Phase 6 — Hours, confidence and the range` | the anchor rule, the default bands, deviations with reasons |
| `## Phase 7 — Author `proposal.md`` | §4's section set |
| `## Phase 8 — Author `proposal-brief.md`` | §10's section set; skipped below tier 2 or under `--no-brief` |
| `## Phase 9 — Pre-lint, review and triage` | `pre-lint`, then `proposal-reviewer`, then `workflows-core:finding-triage` |
| `## Phase 10 — Handoff` | `handoff-to-main`, `prefix: prd` |
| `## Phase 11 — Next steps` | the offer arrays below |
| `## Phase 12 — Session maintenance, feedback & cost` | `impl-maintenance` → `emit-auto` → `emit-cost` → `followup-emission` → `resume.md` → `commit-artifacts` |
| `## Final report` | the report line list, in the house shape |

**Open the body with the loader preamble, verbatim** (check 16 requires it, and this command cites many core references):

```markdown
**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.
```

Then the usage line and the standing rules:

```markdown
Usage: `/prd-proposal <ADDRESS> [--no-brief] [--profile] [--baseline <path>] [--redo]`

`<ADDRESS>` resolves through `workflows-core:addressing` §3 `resolve-address`, taken **after**
`$SPECS_PATH` is settled — a resolution taken before the variable is known returns `absent` for a
folder that exists, which is the ordering `/create-prd` and `/create-ard` state for the same reason.

**This command gates nothing downstream and nothing downstream waits on it.** It gates its own input
and nothing beyond it. No other command reads `proposal.md`, requires one to exist, or changes
behaviour because one does; running this is optional at every tier, in the same sense `/prd-ground`
is optional and ungated on the idea route. A proposal is a document a vendor sends a customer — not a
phase, not a prerequisite, and never a reason implementation cannot start.

**`/prd-proposal` is not BRD-route-only.** A `PRD-` folder is a `PRD-` folder. An idea-route PRD
carrying no `brd-link.md`, no `decisions.md` and no `grounding/` estimates fine — it grades at tier 1
(`${CLAUDE_PLUGIN_ROOT}/references/proposal-format.md` §5), and the document says outright that its
drivers are unknown.

**No money for human hours, at any tier, under any flag** — no rate, no currency symbol, no monetary
total, in either artifact or in the profile
(`${CLAUDE_PLUGIN_ROOT}/references/proposal-format.md` §1). The USD figures this run emits at the end
are model spend and are a different quantity.

**Both artifacts are prose, and prose is never hard-wrapped** — one unbroken line per paragraph,
per `workflows-core:prose-formatting`, so a straight copy-paste into a review tool or a message needs
no cleanup. This governs what the *run* writes; this command file itself stays wrapped like its
neighbours.

**There is no writer agent, and that is deliberate.** The proposal is authored inline by this command,
as `prd.md`, `ard.md` and `specification.md` are: the authoring *is* the command's purpose, and a
handoff to a writer would only add a place for the resolved data set to be lost between derivation and
rendering.

**This command takes no `--no-docs` and does no documentation grounding at all. That is a decision,
not an omission.** `docs-grounder` retrieves shipped product-documentation pages, which bear on how a
feature is described and not at all on what it costs to build. The inputs to an estimate are the
specs tree and the profile. There is no flag to turn off, no `resolve-docs-grounding` call, and no
`docs grounding:` line in this command's report.
```

**Phase 0 carries four things in this order**, and the flag parsing precedes all of them so that a flag is never read as the positional address:

1. `specs-preflight` (`workflows-core:specs-repo-git` §3), as early as `$SPECS_PATH` is known; carry any `specs_git: blocked` for the whole run.
2. `resolve-address`.
3. **The container refusal**, taken structurally on the **directory prefix** before any file inside the folder is read, and printed as prose:

````markdown
```
PRD_PROPOSAL_BRD_NOT_SLICED: <ADDRESS> resolves to a BRD- container at <path>, and an effort proposal for a container is the umbrella rather than a slice's own estimate.

  For the umbrella:            /product-workflows:brd-proposal <BRD-KEY>
  For each slice beneath it:   /product-workflows:prd-proposal <SLICE-KEY>   (one run per slice)

  Slices, by the positive test /brd-split Phase 0 uses — an immediate subdirectory carrying a brd-link.md whose parent: names this BRD:
  <enumerated slice keys, or "none — run /product-workflows:brd-split <BRD-KEY> \"<how to cut it>\" to carve them">
```
````

  **The test is the directory prefix, never the folder's asserted `kind:`** — a `PRD-` slice asserts `kind: brd` in its own `brd-link.md`, so an asserted-kind gate would refuse every slice and accept nothing. Where the folder resolved through `workflows-core:addressing` §5's legacy unprefixed fallback and carries no prefix, take the positive-evidence test in `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5.1 — the shared authority the family's four other container refusals already cite. Cite it; do not restate it.

4. **`require-on-main` on `prd.md`** (`workflows-core:phase-handoff` §3), resolving the file's actual name on the ref first — the keyless `prd.md` on a current tree, a `<KEY>_*.md` entry only through the legacy fallback. **Map `stopped` before `on_main`**, per §3's own rule: `on_main: absent` is returned by row F alone, and a caller that branches on `absent` first cannot tell row F from rows D/E. Row F splits into two stops on a test the gate cannot make, exactly as `/prd-ground`'s idea-route row does:

````markdown
```
PRD_PROPOSAL_NEEDS_PRD: no prd.md on any ref for <KEY>, and none in <path> either — there is nothing to estimate yet.
  Author one first: /product-workflows:create-prd <KEY>
```
```
PRD_PROPOSAL_PRD_NOT_HANDED_OFF: <path>/prd.md exists but is on no ref — it was written and its handoff was declined.
  Land the file that is already on disk; re-running /product-workflows:create-prd would author a second PRD rather than land this one.
```
````

**Nothing gates on `ard.md` or `specification.md`.** That is what grading replaces, and it is the whole answer to the question of when a requirement set becomes estimable.

**`--baseline <path>` may sit outside `$SPECS_PATH` and is read strictly read-only.** Nothing is copied, committed or rewritten; the reconciliation section cites it by the path the operator gave. **An unreadable path is a stop naming that path**, never a silently omitted section. Absent, the reconciliation section does not exist, is not a gap, and the document does not apologise for it.

**Phase 2 owns the profile.** It lives at `$SPECS_PATH/.dev-workflows/proposal-profile.yml`, borrowing the shape and directory name `/docs-workflows:docs-profile` established for `.dev-workflows/docs-profile.yml` but not its location — that file lives in the docs repository because that is what writes it, and this one lives in the specs repository for the same reason. Render the template into the command verbatim:

```yaml
vendor:
  name: ""                      # no default ships with the plugin
  footer_note: ""
client:
  name: ""
engagement_model: time-and-material   # or fixed-price
roles:
  - { id: tl, title: "Tech Lead / Architect", part_time: true }
  - { id: be, title: "Backend Engineer",       count: 2 }
  # ...the operator's own team shape; the plugin ships generic titles only
productivity:
  hours_per_developer_day: 8
  basis: ""                     # e.g. "two engineers working with AI assistants"
calendar:
  hours_per_week: 40
```

It is **grilled on the first run that needs it** (`workflows-core:grilling-technique`), **shown back for confirmation on every later run** — never read silently, because a productivity basis captured once and never revisited mis-scales every later proposal — and re-grilled under `--profile`. `engagement_model` restructures the engagement-governance, change-control and priced-options sections wholesale and is asked rather than assumed. A run that cannot obtain a profile at all stops with `PRD_PROPOSAL_NEEDS_PROFILE`. **No rates, no currency, no money in this file.**

**Phases 3 to 8 are the format's, and cite it rather than restating it.** Each names the section of `${CLAUDE_PLUGIN_ROOT}/references/proposal-format.md` it executes: Phase 3 → §5; Phase 4 → §7, including the three-source defect sweep and its operator confirmation for sources 2 and 3; Phase 5 → §8's evidence classes; Phase 6 → §6's bands and §8's anchor rule; Phase 7 → §4; Phase 8 → §10, skipped below tier 2 irrespective of `--no-brief`. **Every one of these phases states its output and cites its rule; none of them re-expresses a rule the format owns.**

**Phase 9 runs the cheap pass before the expensive one.** `workflows-core:pre-lint` first, as `/create-prd` runs it — **its universal checks, identifier integrity and required-section presence apply; its *Auto-link collision* check does not**, that section being scoped to PRD, ARD and Epic files, and `${CLAUDE_PLUGIN_ROOT}/references/proposal-format.md` §11 records why that exclusion is deliberate here rather than an oversight to be corrected. Then dispatch `subagent_type: "product-workflows:proposal-reviewer"` with both artifact paths, the profile, the resolved tier and the anchor revision where one exists. Triage its findings under `workflows-core:finding-triage` — each verified at the location it names, every dismissal recorded with a reason that disposes of that finding's own claim — before anything is edited.

**Phase 10's handoff paragraph must carry the writer declaration in the exact form check 11's extractor reads** — backticked filenames inside the `deliverable_paths` = … `title:` span, never prose. Write it as:

````markdown
Invoke `Skill(skill: "workflows-core:reference", args: "phase-handoff")` and present its §4.3 choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`Skill(skill: "workflows-core:reference", args: "phase-handoff handoff-to-main")`, §2) with `prefix: prd` (§2.9's table — the proposal opens on the shared `prd` prefix rather than a ninth of its own; the eight prefixes §1 rule 3 fixes are not extended, and nothing about a proposal makes it a ninth phase), `feature_folder` as resolved in Phase 0, `deliverable_paths` = `proposal.md`, `proposal-brief.md` where this run rendered one, and, on a revision, the archived prior under `revisions/` — `<KEY>_proposal_<YYYYMMDD>.md`, and `<KEY>_proposal-brief_<YYYYMMDD>.md` where a brief was archived beside it, `title: <KEY> Effort proposal <YYYYMMDD>`, and `body_facts` = the readiness tier and what capped it; the `[WP#n]` count and the total expected hours with its range; the count of packages graded Low and how many carry a declared re-estimate gate; the `proposal-reviewer` verdict; and whether a rationale brief was rendered. Emit its §4.1 outcome line in the final report.
````

**Phase 11 carries three literal offer arrays, one per tier branch.** Every printed command name is fully qualified (`workflows-core:next-phase-offer` rule 6), and each array prints exactly one positional address (rule 7):

```
choices: ["Stop here — the proposal is written and, if you handed it off, committed", "Roll it into the programme umbrella — /product-workflows:brd-proposal <BRD-KEY> <merge-clause>", "Price the next sibling slice — /product-workflows:prd-proposal <SIBLING-SLICE-KEY>", "Re-derive it from scratch once the inputs move — /product-workflows:prd-proposal <KEY> --redo"]
```

```
choices: ["Stop here — the proposal is written and, if you handed it off, committed", "Roll it into the programme umbrella — /product-workflows:brd-proposal <BRD-KEY> <merge-clause>", "Raise the tier first — /product-workflows:create-ard <KEY>, then re-run this command to narrow the range", "Price the next sibling slice — /product-workflows:prd-proposal <SIBLING-SLICE-KEY>"]
```

```
choices: ["Stop here — the proposal is written and, if you handed it off, committed", "Roll it into the programme umbrella — /product-workflows:brd-proposal <BRD-KEY> <merge-clause>", "Raise the tier first — /product-workflows:specify <KEY>, then re-run this command to narrow the range", "Price the next sibling slice — /product-workflows:prd-proposal <SIBLING-SLICE-KEY>"]
```

State the selection and drop rules beside them, in the command:

```markdown
The **first** array is presented at tier 1 and at tier 4 — at tier 1 because nothing available raises
the tier from a `PRD-` folder alone, at tier 4 because there is no tier above it. The **second** is
presented at tier 2 and the **third** at tier 3: those are the two runs where a named command actually
moves the grade, and telling the operator the document they just received is improvable is worth more
than a forward pointer.

**Drop an option whose subject does not exist on this run** — the umbrella option where the folder has
no parent BRD, the sibling option where no sibling holds a stale proposal or none exists. **Where
dropping would leave fewer than two options, add** `"Re-derive it from scratch once the inputs move —
/product-workflows:prd-proposal <KEY> --redo"`, which is available on every run, so the array never
falls below the two options `AskUserQuestion` requires. Nothing is ever added beyond that, and no
option's wording is adjusted: `<merge-clause>`, `<BRD-KEY>`, `<KEY>` and `<SIBLING-SLICE-KEY>` are
substitutions, not rewordings (`workflows-core:escalation-rules`, *Choice lists are presented
verbatim*).

**`<merge-clause>` is resolved from the `Phase handoff:` line this run actually emitted**, per
`workflows-core:next-phase-offer`'s resolution table — only two of its rows name a branch, and a
declined handoff opened no pull request. `/product-workflows:brd-proposal` runs `require-on-main`
against the `proposal.md` this run has just written, which is why that one option carries the
placeholder and the two tier-raising options do not: both of those gate on `prd.md`, which this run
does not write.
```

Close Phase 11 with a `### Context hygiene` block per `workflows-core:session-hygiene` — re-pricing the same slice → `/compact`; moving to another slice → `/clear`; guidance only.

**Phase 12 is the emitter tail in the canonical order.** The `emit-cost` step must be written in exactly this form — check 8's extractor matches the three backticked labels as one phrase, and a reworded one drops this command out of the gate:

```markdown
3. **Session cost (ALWAYS runs).** Invoke `Skill(skill: "workflows-core:reference", args: "cost-emission emit-cost")` and call its `emit-cost` entry point with `command: /prd-proposal`, `phase: proposal`, `role: pm`, the run's `key`, `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or the report-only notice). **This entry records model spend in USD and has no relationship whatever to the human hours the artifacts contain.**
```

- [ ] **Step 2: Run the gates and confirm exactly which ones go red**

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -E "check (4|8|9|15)" || echo "NOT RED"
```

Expected, and each one is a surface Step 3 closes: check 4 — the command has no docs page, and the namespace manifest does not name it; check 8 — `/prd-proposal` emits a fixed `phase`/`role` pair with no `cost-emission` §7 row; check 9 — the commands count and the cost-emitting count; check 15 — the command is in none of the three index surfaces.

- [ ] **Step 3: Close the four gated surfaces**

**a. The `cost-emission` §7 row.** In `plugins/workflows-core/references/cost-emission.md`, add to the §7 table immediately after the `/brd-reconcile` row:

```
| `/prd-proposal` | proposal | pm |
```

Add a sentence below the table's inference notes recording why the pair is not `brd-to-prd`:

```markdown
**`proposal` is its own phase rather than a second `brd-to-prd` one.** `/prd-proposal` runs on the idea route as readily as on the BRD route, so attributing its spend to the BRD-to-PRD route would file idea-route spend under a route that run never touched; and an effort proposal is a commercial activity over a requirement set rather than a step that advances one. Both proposal commands tag it, at the `pm` role.
```

**b. The namespace manifest.** In `plugins/workflows-core/scripts/command-namespaces.json`, add `"prd-proposal",` to the `product-workflows` array, keeping the file's existing ordering and indentation. Do not reformat anything else.

**c. The docs page.** Create `plugins/product-workflows/docs/commands/prd-proposal.md` in the house shape — the headings `docs/commands/create-ard.md` uses: `# /prd-proposal`, `## Who runs it`, `## Synopsis`, `## How it runs`, `## What it needs`, `## What it produces`, `## Gates`, `## What it does not do`, `## Example`, `## See also`. Four things it must carry, because they are the page's whole job:

- **`## What it needs`** — a `PRD-` folder with a `prd.md` on the default branch, and a proposal profile. Nothing else is required; the readiness tier is a grade, not a gate.
- **`## What it produces`** — `proposal.md` always, `proposal-brief.md` at tier ≥ 2 unless suppressed, and the archived prior revision on a re-run. Link the format page as [`proposal-format.md`](../../references/proposal-format.md).
- **`## Gates`** — the `prd.md` gate, and the `proposal-reviewer` Opus review. Link the inventory page as [Agents](../reference/agents.md), which already exists; **the reviewer's own row in it lands in Task 3**, so do not claim here that the page describes it yet.
- **`## What it does not do`** — it gates nothing downstream, prices nothing in money, requires no ARD or specification, and does no documentation grounding.

Keep every table cell under 200 characters (check 6 reads this tree).

**d. The three index surfaces (check 15).** In `plugins/product-workflows/docs/README.md`, add a row to the "I want to…" table after the `/specify` row:

```
| price a requirement set — work packages, hours by role, a range with its evidence | [`/prd-proposal`](commands/prd-proposal.md) |
```

and an entry to the `## Commands` list, in the list's alphabetical position:

```markdown
- [`/prd-proposal`](commands/prd-proposal.md) — author an effort proposal for one PRD folder: work packages, hours by package and role, and a range whose width comes from per-package confidence, with every cost driver citing a record on disk.
```

In `plugins/product-workflows/README.md`, add a role-table row after the PE row:

```
| PM *(effort proposal — optional, gates nothing)* | [`/prd-proposal`](docs/commands/prd-proposal.md) | Price one PRD folder: work packages, hours by role, a range from per-package confidence, every driver evidenced. Graded by readiness rather than gated on an ARD or a specification. |
```

In `plugins/product-workflows/docs/workflow.md`, add a subgraph to the mermaid block after the `PE` subgraph and one edge below the existing edge list:

```
    subgraph EST["PM — effort proposals (optional, gates nothing)"]
        prdproposal["/prd-proposal"]
    end
```
```
    createvi -.->|optional — priced from whatever readiness the folder has reached| prdproposal
```

**The diagram edit is not optional and does not belong in Task 6.** Check 15 asserts diagram membership separately from the page, because prose below a diagram is where a command lands when someone adds it in a hurry.

- [ ] **Step 4: Move every count that names the plugin's command total from twelve to thirteen**

Derive the sites rather than trusting a list:

```bash
grep -rn "twelve\|Twelve\|\b12\b" plugins/product-workflows/README.md plugins/product-workflows/docs/
```

**Move only the counts that are the plugin's command total.** The sites, with the gated one marked:

| File | Change |
|---|---|
| `README.md` line 3 | `12 slash commands` → `13 slash commands` — **gated by check 9**, and the numeral form is required: its alternation carries no `thirteen` |
| `README.md` line 26 | `The twelve commands as one diagram.` → `The thirteen commands as one diagram.` |
| `docs/reference/environment.md` | `these twelve commands` → `these thirteen commands` |
| `docs/reference/agents.md` line 38 | `dispatched by all 12 commands` → `all 13 commands` |
| `docs/reference/session-feedback.md` | both `all twelve of` sites → `all thirteen of` |
| `docs/reference/resume-and-checkpoints.md` | both `twelve commands` sites → `thirteen commands` |
| `docs/reference/session-cost.md` line 3 | `the twelve commands *in this plugin*` → `the thirteen commands` |
| `docs/reference/session-cost.md` line 7 | `Twelve commands emit a cost entry here` → `Thirteen commands emit a cost entry here` — **gated by check 9**; the word form is correct here, its alternation carries `thirteen` |
| `docs/reference/model-routing.md` line 14 | `All twelve commands` → `All thirteen commands`, and add `/prd-proposal` to the enumerated list |
| `docs/workflow.md` line 70 | `this plugin's own twelve commands` → `thirteen commands` |
| `docs/roles-and-phases.md` line 49 | `Six phases are reached by this plugin's twelve commands` → `Seven phases are reached by this plugin's thirteen commands`, and `Each of the six below` → `Each of the seven below` |
| `docs/roles-and-phases.md` line 77 | `none of this plugin's twelve commands emits it directly` → `thirteen commands` |

**Four `twelve`s in this tree are not the command total and must not be touched:** the twelve sections of the customer-review schema (`docs/reference/references.md`, `docs/commands/brd-package.md`, `docs/commands/brd-reconcile.md`), the twelve fields of a decision-register record (`docs/commands/brd-interview.md`), `/idea`'s twelve-file traversal cap (`docs/commands/idea.md`, three sites), and the `Phase 12` labels in two command-page diagrams.

- [ ] **Step 5: Add the new cost phase to the two pages that document phases**

In `plugins/product-workflows/docs/reference/session-cost.md`, add a row to the phase table after the `/specify` row:

```
| `/prd-proposal` | `proposal` | `pm` |
```

In `plugins/product-workflows/docs/roles-and-phases.md`, add a section after `### specification` (keeping the file's existing section order, which follows the lifecycle):

```markdown
### proposal

Emitted by `/prd-proposal`, role `pm`. Being in this phase means a requirement set is being **priced**
rather than advanced — work packages, hours by role, and a range with its evidence — for a document a
vendor sends a customer. It is the one phase here that no other phase waits on and that gates nothing:
a proposal is optional at every readiness tier, and no command reads one. It is its own phase rather
than part of `brd-to-prd` because the command runs on the idea route as readily as on the BRD route.
```

- [ ] **Step 6: Add the `phase-handoff.md` §3.4 row-F row**

In `plugins/workflows-core/references/phase-handoff.md`, add a row to §3.4's table after the `/prd-ground` **(idea route)** row:

```
| `/prd-proposal` | `prd.md` | **stops**, and **splits row F on a test this gate cannot make** — no `prd.md` on any ref and none in the folder either is `PRD_PROPOSAL_NEEDS_PRD` (never produced); one in the folder and on no ref is `PRD_PROPOSAL_PRD_NOT_HANDED_OFF` (produced, handoff declined), whose action is to land the file already on disk and which never names `/create-prd`, since re-running it would author a second PRD rather than land the one written. Never optional: there is nothing to estimate without it, and this command ships with no pre-gate behaviour to fall back to |
```

**The backticked filename in column 2 is what check 11 reads as this command's gate target**, by basename. A target named only in prose makes the relation cover nothing and report green.

- [ ] **Step 7: Run the full gate set and verify green**

Run all seven gates. Expected: every one passes, and `validate-catalog.py .` reports `0 error(s), 0 warning(s)`.

Then assert the two relations this task exists to establish, since a green run alone does not show they are non-vacuous:

```bash
# check 8 sees the new pair
grep -n '`/prd-proposal` | proposal | pm' plugins/workflows-core/references/cost-emission.md
# check 11 can read this command's writer set
awk '/`deliverable_paths`[[:space:]]*=/{s=1;k=0} s{l=$0; while(match(l,/`[^`]*\.md`/)){t=substr(l,RSTART+1,RLENGTH-2); sub(/.*\//,"",t); print t; l=substr(l,RSTART+RLENGTH)} if($0~/`title:/ || ++k>20) s=0}' \
  plugins/product-workflows/commands/prd-proposal.md | sort -u
```

Expected: the first prints the row; the second prints `<KEY>_proposal-brief_<YYYYMMDD>.md`, `<KEY>_proposal_<YYYYMMDD>.md`, `proposal-brief.md`, `proposal.md`. **An empty second output is a check-11 failure waiting for Task 4** — the extractor reads only backticked `*.md` tokens between `deliverable_paths` = and `title:`.

- [ ] **Step 8: Commit**

```bash
git add plugins/product-workflows/commands/prd-proposal.md \
        plugins/product-workflows/docs/commands/prd-proposal.md \
        plugins/product-workflows/docs/README.md \
        plugins/product-workflows/docs/workflow.md \
        plugins/product-workflows/docs/roles-and-phases.md \
        plugins/product-workflows/docs/reference/ \
        plugins/product-workflows/README.md \
        plugins/workflows-core/references/cost-emission.md \
        plugins/workflows-core/references/phase-handoff.md \
        plugins/workflows-core/scripts/command-namespaces.json
git commit -m "feat(prd-proposal): author an effort proposal for one PRD folder"
```

---

### Task 3: `proposal-reviewer` — the eleven checks

**Files:**
- Create: `plugins/product-workflows/agents/proposal-reviewer.md`
- Modify: `plugins/product-workflows/docs/reference/agents.md` (a row, and three counts)
- Modify: `plugins/product-workflows/README.md` (`Twelve agents` → `Thirteen agents`)

**Interfaces:**
- Consumes: every section number from Task 1, and **Task 2's actual output shape** — the `[WP#n]`-by-role hours table with Expected / Low / High columns, the confidence section's per-package rows, the `[ED#n]` driver table, the re-estimate-gate section, the range-exclusions block, and the brief's six sections. This dependency is an interface, not an assumption: the arithmetic check asserts relations over tables the command emits, so open `commands/prd-proposal.md` Phase 7 and read the section set it actually writes before writing a single check.
- Produces: the verdict vocabulary `PASS` / `PASS WITH RECOMMENDATIONS` / `BLOCK`, and the finding severities `BLOCKER` and `RECOMMENDATION`. Task 4's command dispatches the same agent unchanged.

- [ ] **Step 1: Write the agent**

Create `plugins/product-workflows/agents/proposal-reviewer.md`, modelled on `agents/brd-package-reviewer.md` — adversarial, read-only, Opus-pinned, and dispositioning nothing itself.

```yaml
---
name: proposal-reviewer
description: Adversarially reviews an effort proposal and its rationale brief before either reaches a customer — re-adds the arithmetic, resolves every cost driver's citation against the record that owns its class, and checks the tier claimed against the evidence on disk. Read-only. Uses Claude Opus.
model: opus
tools: ["Read", "Glob", "Grep", "Skill"]
---
```

Open with the same loader preamble Task 2's command carries, then the first instruction:

```markdown
**First instruction, before anything else: re-derive, do not read.** Your highest-yield check is
arithmetic, and arithmetic cannot be reviewed by reading a table — it is reviewed by adding the table
up yourself and comparing. A model-authored grid of ten packages by seven roles is exactly where a
silent addition error survives to a customer, and it survives because every reader who "checked" it
read it. **Add the columns. Add the rows. Multiply the units back.**

Every finding names a location and states what is wrong with it. **This agent never disposes of a
finding** — the caller triages under `workflows-core:finding-triage`.
```

Then the eleven checks, each as its own `##` section so a finding can cite one. Write them in this order and with these exact subjects (spec §11):

| # | Check | What it asserts |
|---|---|---|
| 1 | **Evidence** | every driver cites at least one identifier from `proposal-format.md` §8's closed three-class set; every citation resolves to a record that exists — a grounding finding carrying a verifier outcome, a frozen decision, a confirmed defect; and **every driver making a claim about the code cites class 1 specifically** |
| 2 | **Arithmetic** | package-by-role totals reconcile to the role totals and to the grand total; **the Low and High columns each sum to the stated total range**, which is a separate relation from the expected column and the one a reader is least likely to re-add; every range brackets its expected value; every band deviating from its grade's default (§6) carries a stated reason — no reason is a **recommendation**, narrower than the next grade up's default is a **BLOCKER**, both under the one-percentage-point tolerance; FTE reconciles to hours ÷ weeks ÷ hours-per-week; **any section arguing in a different unit reconciles to the row it feeds** — a unit change is exactly where an unchecked figure hides |
| 3 | **Stability** | no figure has moved from the anchor without a cause named in the changelog section |
| 4 | **Policy** | no defect-remediation package appears in the scope-lever or priced-options tables |
| 5 | **Money** | no rate, currency symbol or monetary total for human hours appears anywhere in either artifact |
| 6 | **Tier honesty** | the tier claimed in the header is the tier the evidence on disk supports, and the brief is absent below tier 2 |
| 7 | **Brief agreement, in both directions** | every figure the brief repeats matches the proposal — **and** every correction, every unpriced item with its gate, every week-1 dependency and every unresolved requirement contradiction the proposal carries reaches the brief. A spine-only brief is a finding |
| 8 | **Completeness of obligations** | every open assumption record, unanswered customer question and blocking code defect reaches the dependencies section |
| 9 | **Coverage** | *(umbrella runs only)* the coverage statement reconciles to the root ledger, and every excluded slice's requirements are enumerated by identifier |
| 10 | **Identifier form** | every requirement identifier in either artifact carries the form the artifact it was read from uses, with no silent conversion in either direction, and no `[WP#n]` or `[ED#n]` rendered in any form but the bracketed one |
| 11 | **Range exclusions** | the band's own exclusions block is present and is **distinct** from the exclusions-from-scope section rather than a restatement of it |

Two rules to state in the agent body, because both are places a reviewer goes wrong:

```markdown
**Check 2 is the reason this agent exists, and it is the one check that cannot be delegated to
judgement.** Re-add every column. Re-add every row. Where a section argues in a different unit —
developer-days against an hours row, weeks against an FTE — multiply it out and compare. A figure that
only *looks* consistent has not been checked.

**Check 10 asserts a direction, not a form.** A proposal cites a requirement in the form the source
artifact carries it (`${CLAUDE_PLUGIN_ROOT}/references/proposal-format.md` §11), so the finding is a
**conversion**, in either direction — never the mere presence of a form. Do not raise a finding
against an identifier for looking unlike the plugin's own.
```

**Vendor neutrality binds this file as it binds every other:** any example inside it is invented, and no figure, identifier, organisation, product or repository name from a real proposal appears.

- [ ] **Step 2: Run the gates and confirm check 4 and check 9 go red**

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -E "check (4|9)" || echo "NOT RED"
```

Expected: check 4 — `agent 'proposal-reviewer' has no row in reference/agents.md`; check 9 — `agents: … says 12, tree has 13`.

- [ ] **Step 3: Add the agents-page row and move the three counts**

In `plugins/product-workflows/docs/reference/agents.md`, add a row to the `## Reviewers and planners` table in alphabetical position, immediately after `grounding-verifier`:

```
| `proposal-reviewer` | opus | Read, Glob, Grep, Skill | Attacks an effort proposal before a customer sees it — re-adds every hours column, resolves every cost driver's citation against the record owning its class, checks the tier against the evidence and the brief against the proposal in both directions; returns PASS / PASS WITH RECOMMENDATIONS / BLOCK. | `/prd-proposal` |
```

Then three counts in the same file:

- line 3: `bundles 12 reusable subagents` → `bundles 13 reusable subagents`, and `Six carry a `model: opus` frontmatter pin` → `Seven carry a `model: opus` frontmatter pin` (13 = 7 opus + 1 sonnet + 5 unpinned; the "remaining five" is unchanged);
- line 38: `Every one of the 12 agents above` → `Every one of the 13 agents above` — **gated by check 9**.

In `plugins/product-workflows/README.md` line 18, `Twelve agents (see [Agents](docs/reference/agents.md)) carry the BRD grounding and reconciliation, PRD/ARD/spec review, and Epic writing and review these commands share.` → `Thirteen agents (see [Agents](docs/reference/agents.md)) carry the BRD grounding and reconciliation, PRD/ARD/spec/proposal review, and Epic writing and review these commands share.`

- [ ] **Step 4: Point the command's docs page at the row that now exists**

In `plugins/product-workflows/docs/commands/prd-proposal.md`'s `## Gates` section, replace the sentence Task 2 left — which names the reviewer without claiming the inventory describes it — with one that sends the reader to the row: the agent, its model pin, its tools and what it returns are now all on [Agents](../reference/agents.md).

- [ ] **Step 5: Run the full gate set and verify green**

Run all seven gates. Expected: every one passes, and `validate-catalog.py .` reports `0 error(s), 0 warning(s)`.

Then assert check 17's precondition is not newly relevant — this agent is granted no `Task` tool, so it must **not** carry the NEVER-dispatch anchor sentence:

```bash
grep -c "That one dispatch is your entire \`Task\` authority" plugins/product-workflows/agents/proposal-reviewer.md
```

Expected: `0`. An agent carrying the rule without `Task` declares an authority the harness would refuse, and check 17 asserts that direction too.

- [ ] **Step 6: Commit**

```bash
git add plugins/product-workflows/agents/proposal-reviewer.md \
        plugins/product-workflows/docs/reference/agents.md \
        plugins/product-workflows/docs/commands/prd-proposal.md \
        plugins/product-workflows/README.md
git commit -m "feat(product-workflows): add the proposal-reviewer agent"
```

---

### Task 4: `/brd-proposal` — the umbrella, with every per-command surface it moves

**Files:**
- Create: `plugins/product-workflows/commands/brd-proposal.md`
- Create: `plugins/product-workflows/docs/commands/brd-proposal.md`
- Modify: `plugins/workflows-core/references/cost-emission.md`, `phase-handoff.md`, `scripts/command-namespaces.json`
- Modify: `plugins/product-workflows/docs/README.md`, `README.md`, `docs/workflow.md`, `docs/roles-and-phases.md`, and the five `docs/reference/` pages carrying a command count

**Interfaces:**
- Consumes: Task 1's format sections; Task 2's artifact paths, driver-citation shape and profile keys; Task 3's reviewer and its verdict vocabulary.
- Produces: the stop ids `BRD_PROPOSAL_NOT_A_CONTAINER`, `BRD_PROPOSAL_NO_SLICES` and `BRD_PROPOSAL_SLICE_NOT_HANDED_OFF`; the branch prefix `brd`; the cost pair `phase: proposal`, `role: pm`.

- [ ] **Step 1: Write the command file**

Create `plugins/product-workflows/commands/brd-proposal.md`, with the same loader preamble, the same money and no-gating standing rules, and the same no-documentation-grounding decision Task 2's command states. Frontmatter:

```yaml
---
name: brd-proposal
description: Programme effort-proposal workflow (PM phase, BRD-route only, optional and ungated) — author the umbrella proposal for a BRD- container by rolling up its slices' own proposals. Enumerates slices by the positive brd-link.md parent test, walks each to a computed recommendation (stop and price it, exclude and disclose it, or re-run a stale one), and gates on each included slice's proposal.md being on the default branch. The roll-up is not a sum: cross-slice effort that exists in no slice is added and named, work two slices priced from the same verified finding is flagged for the operator rather than counted twice, and peak concurrency is computed from the programme schedule instead of summing FTE. Computes coverage from the root coverage ledger and enumerates the remainder by identifier. Carries no money for human hours. Nothing downstream reads a proposal or waits on one.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---
```

Phase headings, mirroring Task 2's so the pair reads as one capability:

| Heading | What it does |
|---|---|
| `## Phase 0 — Resolve the address, preflight, and refuse a slice` | `specs-preflight`; `resolve-address`; the `BRD_PROPOSAL_NOT_A_CONTAINER` refusal |
| `## Phase 1 — Classify + model routing` | SIGNIFICANT |
| `## Phase 2 — Enumerate the slices` | the positive `brd-link.md` `parent:` test; `BRD_PROPOSAL_NO_SLICES` |
| `## Phase 3 — The readiness walk` | three states, a computed recommendation, the operator's decision |
| `## Phase 4 — Gate the included slices` | `require-on-main` on each included slice's `proposal.md` |
| `## Phase 5 — The proposal profile` | the same file and the same show-back as `/prd-proposal` |
| `## Phase 6 — The roll-up and its three adjustments` | umbrella effort, de-duplication, sequencing |
| `## Phase 7 — Coverage from the root ledger` | classify every root row; enumerate the remainder |
| `## Phase 8 — Author `proposal.md`` | §4's section set, at umbrella altitude |
| `## Phase 9 — Author `proposal-brief.md`` | §10; skipped below tier 2 or under `--no-brief` |
| `## Phase 10 — Pre-lint, review and triage` | `pre-lint`, `proposal-reviewer` (check 9 applies here), `finding-triage` |
| `## Phase 11 — Handoff` | `handoff-to-main`, `prefix: brd` |
| `## Phase 12 — Next steps` | the offer array below |
| `## Phase 13 — Session maintenance, feedback & cost` | the emitter tail |
| `## Final report` | the house shape |

Usage and the altitude inversion:

```markdown
Usage: `/brd-proposal <ADDRESS> [--no-brief] [--profile] [--redo]`

**`/brd-proposal`'s natural altitude is the root**, joining `/brd-intake` and `/brd-split` — the seven
other BRD-route commands refuse a container and demand a slice, and this one inverts that. It takes no
`--baseline`: a prior estimate reconciles against the slice that was estimated, not against the
umbrella over it.
```

The refusal, as prose, on the **directory prefix**:

````markdown
```
BRD_PROPOSAL_NOT_A_CONTAINER: <ADDRESS> resolves to a PRD- folder at <path>, and the umbrella aggregates slices rather than pricing one.

  For this slice:              /product-workflows:prd-proposal <SLICE-KEY>
  For the programme above it:  /product-workflows:brd-proposal <PARENT-KEY>   (read from brd-link.md's parent:, or absent where this folder has none)
```
````

**Phase 2's enumeration is the positive test and nothing else** — an immediate subdirectory carrying a `brd-link.md` whose `parent:` names this BRD, exactly as `/brd-split` Phase 0 defines it. **A name match is not the test.** Zero slices stops:

````markdown
```
BRD_PROPOSAL_NO_SLICES: <BRD-KEY> at <path> has no slices — nothing has been carved from it, so there is nothing to roll up.
  Carve them first: /product-workflows:brd-split <BRD-KEY> "<how to cut it>"
```
````

**Phase 3's readiness walk carries a computed recommendation for every slice, and the decision stays the operator's:**

| Slice state | Recommendation |
|---|---|
| no `proposal.md`, and the slice grades tier ≥ 2 | **Stop.** Run `/product-workflows:prd-proposal <SLICE-KEY>` first — the slice is estimable, and excluding it understates the programme |
| no `proposal.md`, and the slice grades tier 1 or holds no `prd.md` | **Exclude, and disclose.** Nothing better is available today, and stopping buys nothing |
| `proposal.md` present but older than the slice's own `prd.md`, `decisions.md` or grounding files | **Re-run it.** The common case, and the easiest to miss |

Present the per-slice decision as a two-option array — `choices: ["Include it as it stands", "Exclude it, and disclose the exclusion in the coverage statement"]` for a stale or tier-1 slice — and print the computed recommendation beside the array rather than folding it into an option's wording.

**Phase 4 gates only the slices the walk included:**

````markdown
```
BRD_PROPOSAL_SLICE_NOT_HANDED_OFF: these included slices have a proposal.md on disk that is on no ref — <keys> — so the umbrella would roll up numbers no later reader can reproduce.
  Land each one, or re-run this command and exclude it.
```
````

**Phase 6's roll-up is not a sum, and each adjustment is named in the document** rather than absorbed into a total:

```markdown
- **Umbrella effort that exists in no slice** — programme management across slices, cross-slice
  integration, one release and one acceptance campaign rather than one per slice. Its own `[WP#n]`s.
- **De-duplication, which is mechanically detectable.** Two slices that priced the same discovery
  activity or the same shared component **cite the same verified finding identifier** in their driver
  tables. Flag every finding claimed by more than one included slice and ask the operator whether it
  is genuinely two pieces of work. **Disclose the limit of the check in the document**: shared work
  described from two different findings is not detected, and the umbrella then overstates.
- **Sequencing.** Slices sharing a team do not add their FTE figures; peak concurrency is computed
  from the programme schedule. Slice order comes from `depends_on` in each slice's PRD frontmatter,
  which `/create-prd` already writes.

**Detail stays in the slice proposals.** The umbrella carries one row per slice — hours, range, tier,
confidence — plus aggregated roles, one team, one schedule, the cross-slice dependency graph and the
coverage statement. It does not restate driver tables and it never re-derives a slice's hours.

**The umbrella's tier is the minimum of its included slices' tiers, and it prints the mix.** A
programme cannot claim to be specified because three of its five slices are.

**Ranges are summed, and stated as summed**, carrying the same caveat that low and high are not
simultaneous outcomes. A statistical roll-up would be narrower and unexplainable in the meeting this
document exists to survive; that trade is refused here and recorded so it is not proposed later.
```

**Phase 7 computes coverage from the root ledger and never asserts it.** Classify every root row — `covered-by` an included slice; `covered-by` an **excluded** slice, disclosed by requirement identifier; still `unallocated`, meaning never sliced and therefore never estimated; or terminal (`deferred-to`, `rejected`, `superseded-by`), disclosed with the reason the ledger records. The umbrella states what proportion of the BRD's requirements it covers **and enumerates the remainder by identifier**, recomputed on every run so it cannot go stale.

**Phase 11's handoff declares the writer set in the same extractor-readable form**, with `prefix: brd` (the shared prefix every `/brd-*` command uses) and `deliverable_paths` = `proposal.md`, `proposal-brief.md` where one was rendered, and on a revision the archived prior under `revisions/` — `<KEY>_proposal_<YYYYMMDD>.md` and `<KEY>_proposal-brief_<YYYYMMDD>.md` — followed by `title: <BRD-KEY> Programme effort proposal <YYYYMMDD>` within the same span.

**Phase 12 carries one literal array:**

```
choices: ["Stop here — the umbrella is written and, if you handed it off, committed", "Re-price a slice the readiness walk flagged — /product-workflows:prd-proposal <SLICE-KEY>", "Re-run the umbrella once those land — /product-workflows:brd-proposal <BRD-KEY>"]
```

State beside it that **no option carries `<merge-clause>` and that this is derived rather than forgotten**: `/product-workflows:prd-proposal` runs `require-on-main` against `prd.md`, which this run does not write, so no downstream gate here reads anything this run produced. **The umbrella offers no forward advance** — it is the end of this branch, not a phase in the build ladder.

Close Phase 12 with a `### Context hygiene` block per `workflows-core:session-hygiene`, as
`/prd-proposal` does — re-running the umbrella after a slice lands → `/compact`; moving to another BRD
→ `/clear`; guidance only.

**Phase 13's `emit-cost` step is written in the same exact form as Task 2's**, with `command: /brd-proposal`, `phase: proposal`, `role: pm`. The rest of the tail is the canonical order unchanged: `impl-maintenance` → `emit-auto` → `emit-cost` → `followup-emission` → `resume.md` → `commit-artifacts`, skipped on `specs_git: blocked`.

**Both artifacts are prose and are never hard-wrapped** (`workflows-core:prose-formatting`), and **there is no writer agent** — the umbrella is authored inline, exactly as `/prd-proposal` authors the slice proposal.

- [ ] **Step 2: Run the gates and confirm which go red**

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -E "check (4|8|9|11|15)" || echo "NOT RED"
```

Expected: check 4 (no docs page, no manifest entry), check 8 (no §7 row), check 9 (the two command counts), check 15 (three index surfaces). **Check 11 must NOT fire** — `/prd-proposal`'s offer already carries `<merge-clause>`, and this task is what makes that requirement bind.

- [ ] **Step 3: Close the gated surfaces**

**a.** `plugins/workflows-core/references/cost-emission.md` §7, immediately after the `/prd-proposal` row: `| `/brd-proposal` | proposal | pm |`

**b.** `plugins/workflows-core/scripts/command-namespaces.json`: add `"brd-proposal",` to the `product-workflows` array.

**c.** `plugins/workflows-core/references/phase-handoff.md` §3.4, after the `/prd-proposal` row:

```
| `/brd-proposal` | each **included** slice's `proposal.md` | **stops** — `BRD_PROPOSAL_SLICE_NOT_HANDED_OFF`, naming every included slice whose proposal came back row F, because the umbrella would otherwise roll up figures no later reader can reproduce. A slice with **no** proposal at all never reaches this row: the readiness walk decides whether to stop or exclude it first. Never optional: an umbrella rolls up slice proposals and cannot roll up one it cannot read on a ref |
```

**d.** Create `plugins/product-workflows/docs/commands/brd-proposal.md` in the same house shape as Task 2's page. Its `## Gates` section names the `proposal.md` gate on each included slice and the `proposal-reviewer` review, sending the reader to [Agents](../reference/agents.md) — the row is there from Task 3. Its `## What it does not do` says outright that the umbrella offers no forward advance, prices nothing in money, and gates nothing downstream.

**e.** The three index surfaces. `docs/README.md` gains an "I want to…" row and a `## Commands` entry; `README.md` gains a role-table row beside `/prd-proposal`'s; `docs/workflow.md`'s `EST` subgraph gains a second node and one edge:

```
        prdproposal["/prd-proposal"] --> brdproposal["/brd-proposal"]
```

with the edge labelled where the diagram's style calls for it — the umbrella reads each included slice's `proposal.md`.

Then add `proposal-reviewer`'s **Used by** column entry in `docs/reference/agents.md`: `/prd-proposal`, `/brd-proposal`.

- [ ] **Step 4: Move every command count from thirteen to fourteen**

The same site list as Task 2 Step 4, one increment further. **`plugins/product-workflows/README.md` line 3 must read `14 slash commands`** (check 9, numeral required) and **`docs/reference/session-cost.md` line 7 must read `Fourteen commands emit a cost entry here`** (check 9, word form correct — its alternation carries `fourteen`). `docs/roles-and-phases.md` line 49 becomes `Seven phases are reached by this plugin's fourteen commands`. Add `/brd-proposal` to `docs/reference/model-routing.md`'s enumerated list and to `docs/reference/session-cost.md`'s phase table row for `proposal` (that row becomes `| `/prd-proposal`, `/brd-proposal` | `proposal` | `pm` |`), and to the `### proposal` section in `docs/roles-and-phases.md`.

Re-derive rather than trusting the list:

```bash
grep -rn "thirteen\|Thirteen\|\b13\b" plugins/product-workflows/README.md plugins/product-workflows/docs/
```

Every hit that is the plugin's command total moves; the agents count (`13`) stays.

- [ ] **Step 5: Run the full gate set and verify green, then prove check 11 now binds**

Run all seven gates. Expected: all pass, `0 error(s), 0 warning(s)`.

Then prove the relation is live rather than vacuous — this is the assertion Task 2 could not make:

```bash
# Remove the placeholder and the gate must fail; restore it and it must pass.
sed -i 's| <merge-clause>", "Raise the tier| ", "Raise the tier|' plugins/product-workflows/commands/prd-proposal.md
./scripts/check-docs.sh --root . 2>&1 | grep "check 11" || echo "MUTATION NOT CAUGHT — the relation is vacuous"
git checkout -- plugins/product-workflows/commands/prd-proposal.md
./scripts/check-docs.sh --root . >/dev/null && echo "restored, green"
```

Expected: the mutation prints a check 11 failure naming `commands/prd-proposal.md` and `proposal.md`; the restore prints `restored, green`. **If the mutation is not caught, stop** — either the row-F row's filename is not backticked, or the `deliverable_paths` span is not extractor-readable, and every offer this command makes has silently stopped being checked. The `sed` above targets the tier-2 array; adjust it to whichever array carries the umbrella option if the wording moved, and always `git checkout --` the file afterwards.

- [ ] **Step 6: Commit**

```bash
git add plugins/product-workflows/commands/brd-proposal.md \
        plugins/product-workflows/docs/commands/brd-proposal.md \
        plugins/product-workflows/docs/README.md \
        plugins/product-workflows/docs/workflow.md \
        plugins/product-workflows/docs/roles-and-phases.md \
        plugins/product-workflows/docs/reference/ \
        plugins/product-workflows/README.md \
        plugins/workflows-core/references/cost-emission.md \
        plugins/workflows-core/references/phase-handoff.md \
        plugins/workflows-core/scripts/command-namespaces.json
git commit -m "feat(brd-proposal): roll a BRD's slice proposals into one programme umbrella"
```

---

### Task 5: The workflow edges — offers in, and both nodes on the routing graph

**Files:**
- Modify: `plugins/product-workflows/commands/brd-reconcile.md`, `create-ard.md`, `specify.md` (one offer each)
- Modify: `plugins/workflows-core/references/next-phase-offer.md` (the routing graph; the scope paragraph)

**Interfaces:**
- Consumes: both commands' names and addresses, and the tier vocabulary from Task 1 §5.
- Produces: nothing later tasks depend on. Task 6 documents what this task wires.

**A ruling this task makes, with its reason.** *"Adding a command adds edges to the routing graph, and a node nothing offers is a node nobody finds"* (spec §12.2) — but the three incoming offers are added **as prose in each command's next-step section, not as new `choices:` options**, for three reasons that hold together: `/brd-reconcile`'s advance array already carries **four** options and `AskUserQuestion` accepts no fifth, so an option there would have to displace one of the route's actual handovers; a proposal is optional and gates nothing, so displacing a pipeline advance for it would be exactly backwards; and prose is `workflows-core:next-phase-offer`'s own **universal minimum** surface, which the array supplements rather than replaces. **The consequence is stated rather than discovered: check 11 cannot see a prose offer, so these three are outside its coverage — and none of them needs a clause anyway**, which is derived, not assumed: `/prd-proposal`'s `require-on-main` target is `prd.md`, and none of `/brd-reconcile`, `/create-ard` or `/specify` declares `prd.md` in its `deliverable_paths`.

- [ ] **Step 1: Verify the no-clause claim before writing a single offer**

```bash
for c in brd-reconcile create-ard specify; do
  printf '%s: ' "$c"
  awk '/`deliverable_paths`[[:space:]]*=/{s=1;k=0} s{l=$0; while(match(l,/`[^`]*\.md`/)){t=substr(l,RSTART+1,RLENGTH-2); sub(/.*\//,"",t); printf "%s ", t; l=substr(l,RSTART+RLENGTH)} if($0~/`title:/ || ++k>20) s=0}' \
    "plugins/product-workflows/commands/$c.md" | tr ' ' '\n' | sort -u | tr '\n' ' '
  echo
done
```

Expected: **no line contains `prd.md`**. If one does, that command's offer must carry `<merge-clause>` and must therefore be a `choices:` option rather than prose, because check 11 reads options only — stop and re-plan that one offer rather than shipping an unchecked clause.

- [ ] **Step 2: Add the offer to `/brd-reconcile`**

In `plugins/product-workflows/commands/brd-reconcile.md`, immediately below the four-option advance array (the one offering `/create-prd`, `/create-ard` and `/specify` off the reconciled slice key), add:

```markdown
**And, in prose beside the array, the one thing this run has just made possible commercially.** The
register settling is what takes this slice from tier 1 to tier 2 — the point at which an effort
proposal stops being indicative and becomes a document that can go to a customer
(`${CLAUDE_PLUGIN_ROOT}/references/proposal-format.md` §5). So name it: **`/product-workflows:prd-proposal
<SLICE-KEY>` prices this slice, and this run is what made it sendable.** It is offered in prose rather
than as a fifth option because the array is full at four (`workflows-core:escalation-rules` §0) and the
three advance options are the route's actual handover, which an optional, ungated document must not
displace. It carries no merge wait: `/product-workflows:prd-proposal` gates on `prd.md`, which this run
does not write.
```

- [ ] **Step 3: Add the offer to `/create-ard`**

In `plugins/product-workflows/commands/create-ard.md`, in the *Next-step offer (adaptive)* phase, below the branch arrays, add:

```markdown
**The commercial step this run just unlocked, named in prose.** An ARD takes a folder to tier 3, where
architecture-bearing work packages become eligible for High confidence
(`${CLAUDE_PLUGIN_ROOT}/references/proposal-format.md` §5): **`/product-workflows:prd-proposal <KEY>`
now prices this folder against a settled architecture rather than an assumed one, and re-running it
after this ARD narrows the range.** Optional and ungated — nothing waits on a proposal, and no arrays
above change. No merge wait: that command gates on `prd.md`, which this run does not write.
```

- [ ] **Step 4: Add the offer to `/specify`**

In `plugins/product-workflows/commands/specify.md`, in its `### Next step` section, add the same shape one tier up:

```markdown
**And the commercial step, in prose.** A specification takes a folder to tier 4, the top tier, where QA
effort is sized from the authored test-case count rather than a ratio and the definition of done is
built from the acceptance criteria (`${CLAUDE_PLUGIN_ROOT}/references/proposal-format.md` §5):
**`/product-workflows:prd-proposal <KEY>` prices it at the tightest range the format allows.** Optional
and ungated. No merge wait: that command gates on `prd.md`, which this run does not write.
```

- [ ] **Step 5: Put both nodes on the routing graph**

In `plugins/workflows-core/references/next-phase-offer.md`, add a role block to `## The routing graph (role-aware)`, placed after the **PM / PA — the BRD-to-PRD route** block:

```markdown
**PM — effort proposals (optional, and they gate nothing)**

- `/product-workflows:prd-proposal <PRD-KEY>` — **depth** → `/product-workflows:brd-proposal <BRD-KEY>`
  (PM), where the folder has a parent BRD, **carrying `<merge-clause>`**: that command runs
  `require-on-main` against the very `proposal.md` this run wrote. **Breadth** →
  `/product-workflows:prd-proposal <SIBLING-SLICE-KEY>` (PM), for the next sibling holding no current
  proposal. And, below tier 4, **the command that would raise the tier** —
  `/product-workflows:create-ard <KEY>` at tier 2, `/product-workflows:specify <KEY>` at tier 3 — named
  together with the plain statement that re-running the proposal afterwards narrows the range. Neither
  of those two carries a clause: both gate on `prd.md`, which a proposal run does not write.
- `/product-workflows:brd-proposal <BRD-KEY>` — **no forward advance.** The umbrella is the end of this
  branch, not a phase in the build ladder. It offers re-runs: `/product-workflows:prd-proposal
  <SLICE-KEY>` for each slice its readiness walk found stale or excluded, and itself once those land.
- **Neither is a prerequisite for anything.** No command reads `proposal.md`, requires one, or behaves
  differently because one exists, and no readiness tier withholds permission to begin work. These two
  are offered *from* the pipeline and never gate *into* it.
```

- [ ] **Step 6: Extend the scope paragraph without touching either glob**

The `**Where this rule applies:` line is the **only** place check 11 reads the family from, and it reads it with `grep -oE "/product-workflows:[a-z][a-z0-9-]*\*"`. **Do not reword, split, wrap or re-punctuate the two glob tokens `` `/product-workflows:brd-*` `` and `` `/product-workflows:prd-*` ``** — an emptied glob fails the build loudly, and a *changed* one silently narrows the check. Leave the existing "five … commands" count alone: it counts the BRD-to-PRD **route**, which is still five commands. Append to that same line:

```markdown
**Two further commands match those globs and are inside the rule by name rather than by adoption.** `/product-workflows:prd-proposal` and `/product-workflows:brd-proposal` author effort proposals, and both are covered by the two globs already named — there is no version of that work in which they sit outside this gate. The placeholder appears in exactly one option across the pair: `/prd-proposal`'s offer of `/brd-proposal`, whose `require-on-main` gate targets the `proposal.md` that same run has just written. Every other option either names a command gating on `prd.md`, which neither proposal command writes, or names the offering command itself.
```

- [ ] **Step 7: Run the full gate set and verify green**

Run all seven gates. Expected: all pass, `0 error(s), 0 warning(s)`.

Then prove the scope line still yields both globs — a wording change that emptied it would fail check 11 loudly, but one that *narrowed* it would not:

```bash
grep '^\*\*Where this rule applies:' plugins/workflows-core/references/next-phase-offer.md \
  | grep -oE "/product-workflows:[a-z][a-z0-9-]*\*" | sort -u
```

Expected exactly: `/product-workflows:brd-*` and `/product-workflows:prd-*`.

- [ ] **Step 8: Commit**

```bash
git add plugins/product-workflows/commands/brd-reconcile.md \
        plugins/product-workflows/commands/create-ard.md \
        plugins/product-workflows/commands/specify.md \
        plugins/workflows-core/references/next-phase-offer.md
git commit -m "feat(product-workflows): wire the proposal commands into the routing graph"
```

---

### Task 6: Cross-cutting documentation, counts, versions and the catalogue

**Files:**
- Modify: `CLAUDE.md`
- Modify: `plugins/workflows-core/references/specs-repo-git.md`, `feedback-emission.md`
- Modify: `plugins/product-workflows/.claude-plugin/plugin.json`, `plugins/workflows-core/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Modify: `plugins/product-workflows/CHANGELOG.md`, `plugins/workflows-core/CHANGELOG.md`

**Interfaces:**
- Consumes: everything Tasks 1–5 shipped.
- Produces: nothing. This is the last task.

- [ ] **Step 1: Move the two shared-reference caller counts**

Both are counts of commands that write into `$SPECS_PATH`, and both new commands do. Derive the new value rather than adding two:

```bash
grep -l commit-artifacts plugins/*/commands/*.md | wc -l
```

Expected: `26`. Then:

- `plugins/workflows-core/references/specs-repo-git.md` line 71: `any of the twenty-four callers` → `any of the twenty-six callers`.
- `plugins/workflows-core/references/feedback-emission.md` line 131: `nineteen of the twenty-four callers ship from a sibling` → `twenty-one of the twenty-six callers ship from a sibling` (both new commands ship from `product-workflows`, a sibling of the plugin that owns the reference).

- [ ] **Step 2: Update `CLAUDE.md` — the workflow map first**

Add two lines to the workflow map's command block, after the `/brd-reconcile` line and before the `BRD route (tail)` line:

```
/prd-proposal        → [require-on-main: prd.md] → [resolve or grill the proposal profile] → grade the readiness tier (1–4) → derive work packages by delivery seam (+ a defect-remediation package from three sources, never a scope lever) → derive [ED#n] drivers, each citing a verified grounding finding, a frozen decision or a confirmed defect → hours by [WP#n] and role, ranged bottom-up from per-package confidence under the tier's ceiling → write proposal.md + proposal-brief.md (tier ≥ 2) → [pre-lint, minus its auto-link collision check] → [proposal-reviewer@Opus] → [triage: verify each finding] → [handoff-to-main: both artifacts + the archived prior] → impl-maintenance → commit-artifacts   (gates nothing downstream; no command reads a proposal)
/brd-proposal        → [resolve a BRD- container; a PRD- folder is refused] → enumerate slices by the positive brd-link.md parent test → the readiness walk (stop / exclude-and-disclose / re-run, recommendation computed, decision the operator's) → [require-on-main: each included slice's proposal.md] → roll up, naming all three adjustments (umbrella effort, de-duplication on shared finding ids, peak concurrency rather than summed FTE) → coverage computed from the root ledger, remainder enumerated by identifier → write proposal.md + proposal-brief.md → [proposal-reviewer@Opus] → [triage] → [handoff-to-main] → impl-maintenance → commit-artifacts   (the umbrella is the end of this branch, not a phase in the build ladder)
```

Add one line to the agent list at the foot of the map, in its existing position among the `product-workflows` agents:

```
                      └── proposal-reviewer (product-workflows)      (used by /prd-proposal, /brd-proposal)
```

and change `impl-maintenance`'s parenthetical from `used by 20 of the 26 commands — all but /docs-profile, /statusline, /feedback, /prompt, /prompt-brainstorm and /prompt-grill-me` to `used by 22 of the 28 commands — all but /docs-profile, /statusline, /feedback, /prompt, /prompt-brainstorm and /prompt-grill-me`.

Also change the map's preamble sentence, which enumerates the twelve product-definition commands, so it names fourteen and lists both new names.

- [ ] **Step 3: Update `CLAUDE.md`'s counts — every one of them derived, not adjusted**

| Site | Change |
|---|---|
| the `plugins/product-workflows/` paragraph | `twelve slash commands` → `fourteen`; the enumerated command list gains both names; `twelve subagents` → `thirteen`; `ten reference files` → `eleven` |
| the documentation-tree paragraph | `product-workflows` carries `25` → **`28`**, and its breakdown `12 command` → `14 command`, `8 reference` → `9 reference` (5 top-level + 14 + 9). Re-derive it: `find plugins/product-workflows/docs -type f \| wc -l` |
| the `specs-repo-git.md` paragraph | `the twenty-four commands that write into $SPECS_PATH` → `twenty-six`; `every one of the family's twenty-six` → `twenty-eight`; `all twelve of product-workflows's` → `all fourteen of` |
| the `specs-repo-git` invariant bullet | `twelve of the twenty-four callers` → `twelve of the twenty-six callers`; `Twelve is all twenty-four minus the twelve that touch no implementation repository at all` → `all twenty-six minus the fourteen`, adding `/prd-proposal` and `/brd-proposal` to that enumerated list — **neither opens a code repository**, which is why the numerator stays twelve |
| the `All twenty-four in-scope commands` sentence | → `All twenty-six in-scope commands` |
| the `phase-handoff.md` paragraph | `Fifteen producers call handoff-to-main` → `Seventeen`, adding both names; `twelve consumers call require-on-main` → `fourteen`, adding both names |
| the model-routing paragraph | `Twenty-one commands invoke the workflows-core:model-routing skill` → `Twenty-three`; `all twelve of product-workflows's` → `all fourteen of`, listing both new names |
| the `docs-grounding.md` paragraph | add `/brd-proposal` and `/prd-proposal` to the enumerated list of commands that deliberately resolve no docs grounding, with the reason: an estimate's inputs are the specs tree and the profile, and a documentation page bears on how a feature is described rather than on what it costs to build |

**Re-derive every one of these against the tree rather than adding two to the digit.** This file's own rule says so, and its own history is the reason: the counts here are held by hand, nothing gates them, and the last two increments moved them by amounts a decrement would not have guessed.

- [ ] **Step 4: Bump both plugin versions and re-word the one blurb**

`plugins/product-workflows/.claude-plugin/plugin.json` → `"version": "3.4.0"`. A new capability, additively.

`plugins/workflows-core/.claude-plugin/plugin.json` → `"version": "1.4.0"`. Its two shared authority tables (`cost-emission` §7, `phase-handoff` §3.4) and its routing graph gained rows for a new pipeline node; that is additive and visible to every dependent plugin.

Replace the `product-workflows` description — **in both `plugin.json` and the `marketplace.json` entry, byte-identical** — with this. It is 877 characters, inside the 1024 hard cap and under the 900-character warning threshold, so the catalogue stays at `0 warnings`. A capability change **replaces** wording; it never appends:

```
Fourteen slash commands for the product-definition half of the dev-workflows pipeline: a six-command BRD-to-PRD route (/brd-intake → /brd-split → /prd-ground → /brd-split → /brd-interview → /brd-package → /brd-reconcile) that grounds a customer's requirements document, settles it with them, and seeds the PRD, ARD and specification; the idea→PRD→ARD→specification ladder (/idea → /create-prd → /update-prd → /create-ard → /specify), with /prd-ground optionally grounding the PRD itself; /epics, deriving Epics from a PRD; and /prd-proposal and /brd-proposal, pricing a graded requirement set in human hours — never money — with every cost driver citing a record on disk and gating nothing. Thirteen agents carry the grounding, reconciliation, PRD/ARD/spec/Epic/proposal review and Epic writing. Eleven reference pages define the artifact formats these commands author against.
```

In `.claude-plugin/marketplace.json`, change **only** the two entries' `version` values and `product-workflows`'s `description` value. **Never reformat the file** — Claude Code parses it.

- [ ] **Step 5: Write both changelog entries**

`plugins/product-workflows/CHANGELOG.md`, a new `## [3.4.0] — 2026-09-08` section above `## [3.3.3]`, under `### Added`, covering: the two commands and what each does; the readiness grading that replaces gating on an ARD or a specification, and its ceiling on per-package confidence; the closed three-class evidence set and the rule that a driver citing none of them does not render; the automatic defect-remediation package and its exclusion from the lever table; the derived rationale brief and why it is withheld below tier 2; `proposal-reviewer` and its arithmetic check; the no-money rule; and — stated plainly, because it is the property most likely to be misread — **that neither command gates anything and that no other command reads a proposal**.

`plugins/workflows-core/CHANGELOG.md`, a new `## [1.4.0] — 2026-09-08` section, under `### Added`, covering the `proposal` cost phase and its two `cost-emission` §7 rows, the two `phase-handoff` §3.4 row-F rows, and both routing-graph nodes — noting that the `<merge-clause>` rule reaches the pair by the globs the scope paragraph already names, and that exactly one option in the pair carries the placeholder.

- [ ] **Step 6: Run the full gate set one last time, and check the whole branch**

Run all seven gates. Expected: every one passes, and `validate-catalog.py .` reports **`0 error(s), 0 warning(s)`** — the same baseline the branch started from.

Then re-derive the three hand-held numbers this task wrote into `CLAUDE.md`, against the tree rather than against the plan:

```bash
ls plugins/product-workflows/commands/*.md | wc -l      # expect 14
ls plugins/product-workflows/agents/*.md   | wc -l      # expect 13
ls plugins/product-workflows/references/*.md | wc -l    # expect 11
find plugins/product-workflows/docs -type f | wc -l     # expect 28
grep -l commit-artifacts plugins/*/commands/*.md | wc -l # expect 26
ls plugins/*/commands/*.md | wc -l                       # expect 28
```

Any disagreement between one of these and what `CLAUDE.md` now says is a defect in this task, not in the tree.

Finally, sweep for claims the branch falsified — by phrase, never by line number, and across `plugins/` rather than one plugin, because the family's shared authorities live in `workflows-core`:

```bash
grep -rn "does not ship\|is not shipped\|no command\b.*estimate\|nothing.*prices\|no proposal" plugins/ CLAUDE.md --include=*.md | grep -v CHANGELOG
grep -rn "only when\|is the only\|nothing else\|and no other\|only ever" plugins/product-workflows/docs plugins/workflows-core/references --include=*.md | grep -iE "command|offer|phase|reference" | head -40
```

The second is the **exclusivity probe**, run as its own axis: it is where a falsified claim hides when it names none of the vocabulary this branch introduced. Read each hit against what the branch actually shipped; a sentence that named an absence as its *reason* for an offer needs a new reason, not a deletion.

- [ ] **Step 7: Commit**

```bash
git add CLAUDE.md \
        plugins/workflows-core/references/specs-repo-git.md \
        plugins/workflows-core/references/feedback-emission.md \
        plugins/product-workflows/.claude-plugin/plugin.json \
        plugins/workflows-core/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json \
        plugins/product-workflows/CHANGELOG.md \
        plugins/workflows-core/CHANGELOG.md
git commit -m "docs: document the proposal commands across the family, and bump both plugins"
```

---

## After the last task

The branch now carries a complete capability: the format, both commands, the reviewer, the edges and the documentation. **Nothing has been pushed and no pull request is open** — that decision is the operator's, through `superpowers:finishing-a-development-branch`.

**A useful first live exercise**, from spec §17: run `/prd-proposal` at tier 4 against a folder that already holds a PRD, an ARD, a specification, a settled register and verified grounding. It exercises every branch that matters, and the lower tiers are subtractions from it rather than separate paths.

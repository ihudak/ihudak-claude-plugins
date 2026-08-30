---
name: brd-package
description: BRD customer-package workflow (PM phase, fifth command of the BRD-to-PRD route). Gates on the BRD's decisions being merged and on every interview question carrying a terminal disposition or the held-for-the-customer holding state, then runs an adversarial self-review through brd-package-reviewer and refuses to build a bundle while any [SR#n] is undisposed. Renders a self-contained customer prompt in the fixed eleven-part order with the customer-review schema inlined from section 2 onward at build time, surfaces every open [AS#n] and every accepted-risk [SR#n] under "where to attack us hardest" and every not-yet-customer-reviewed prerequisite under "what could still move", renders a delivery note under a 200-word ceiling, and assembles a de-Obsidianised bundle of plain markdown plus images with any dependency package copied in and marked not for re-review. Assigns the degradation tier from what was shippable, scans the rendered prompt for anything plugin-internal, and emits the repo-to-SHA table. Takes no --no-docs and does no documentation grounding.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Turn the decided BRD into a package a customer can actually review: $ARGUMENTS

`/brd-package` is the **fifth command of the BRD-to-PRD flow** (PM phase) — it takes the register
`/brd-interview` wrote and the `[C]` questions it held, attacks the package before the customer
does, and renders a bundle for a reviewer with **a vanilla agent and nothing installed**. Its whole
discipline is one rule: **everything this command emits is read by somebody outside the delivery
organisation who cannot ask what a path means**
(`${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md` §1, D12). This command exists to make that
happen, not to restate it.

Usage: `/brd-package <BRD-KEY> [--depends-on <BRD-KEY>…]`

Runs at either of the two levels `<BRD-KEY>` can name
(`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §3) — a BRD that owns its source document, or
one of its slices. It refuses neither and behaves identically at both: a slice holds its own
register, its own `[C]` question set and its own findings, and it is packaged from those and no
others. The bundle this run builds is the bundle of the BRD it was given.

**Standing rule, binding on every phase below.** Nothing that names this plugin, this repository or
this harness may appear in the rendered prompt, the delivery note, or any document inside the
bundle. Not a path rooted at the plugin's install directory, not a `references/…` citation, not a
slash command, not an agent or skill name, not a `§` section reference
(`${CLAUDE_PLUGIN_ROOT}/references/customer-review-schema.md` §1). The section *How nothing
plugin-internal reaches the customer* below states the ordering and the scan that make that
structural rather than aspirational.

**This command takes no `--no-docs`, and it does no documentation grounding at all. That is a
decision, not an omission.** `/brd-intake` and `/brd-ground` already ground this BRD against the
shipped product documentation when `$DOCS_PATH` resolves (D22,
`${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`), and `/brd-interview` deliberately does none
for the same reason this command does none: it works on **decisions already taken**. This command
goes one step further — it establishes no claim of its own at all. It renders what other commands
recorded, and a documentation page cannot change a decision that is already in the register or a
finding that is already verified; consulting one here could only introduce an ungrounded sentence
into a bundle whose whole value is that every sentence in it is traceable. So there is no flag to
turn off, no `resolve-docs-grounding` call, and no `docs grounding:` line in this command's report.
The sentence is written here because leaving it unwritten is exactly how the gap it forecloses gets
shipped.

**No repository is opened, at any point.** Every commit this package cites was pinned and proven
clean by `/brd-ground`, and the repo→SHA table is read from that run's `grounding/baselines.md`. So
there is no baseline gate here, no dirty-tree stop, and no `$REPOS_PATH` requirement. The three
`baseline-integrity` commands are not re-run by this command — they are **handed to the customer's
reviewer**, written out with the repository and the commit substituted, so the customer re-derives
the pin against their own checkout rather than taking the package's word for it
(`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §4).

---

## How nothing plugin-internal reaches the customer

Five properties, and every one of them is a property of the **order and the inputs of the phases
below**, not an instruction to be careful. Together they are the guarantee; individually none of
them is.

1. **The schema is rendered from its own file, from the boundary that file declares, and never in
   full.** `customer-review-schema.md` separates a preamble addressed to the delivery team from a
   body addressed to the customer, and states where the boundary falls. The *Render the customer
   prompt* phase reads the boundary statement out of the file before it renders, and stops if it is
   no longer there. Rendering the whole file would put that file's own `references/…` citations in
   front of a reader with no plugin — the exact failure D12 exists to prevent — and the citations
   are collected in the preamble precisely so that the boundary has something to protect.

2. **The prompt is assembled, never hand-written.** Every one of its eleven parts is filled from a
   named artifact — the register, the findings, the ledger, the `[C]` question set, the self-review,
   `baselines.md`, `brd-link.md`. A part with no source is an empty part that says so, not a part
   somebody writes from memory. Prose written fresh into a customer prompt is prose nothing
   verified, and it is where an in-house reference gets explained rather than removed.

3. **The de-Obsidianising pass renders a copy and never edits a source.** The bundle is produced on
   the way out; the working documents keep their wikilinks (`bundle-packaging.md` §2). A pass that
   edits the source is a data-loss bug wearing a formatting fix, and it also destroys the only clean
   copy from which a later package could be rendered correctly.

4. **The plugin-free scan runs over the finished text, not over the templates.** It is the last
   thing the *Render the customer prompt*, *Render the delivery note* and *Assemble the bundle*
   phases each do, and it inspects what will actually be sent. A scan over the templates would pass
   on a prompt whose leak arrived through an interpolated document title.

5. **A scan hit stops the run; it never sanitises.** The command does not strip the offending token
   and continue. A citation that reached the prompt reached it because some part of the package
   assumed a reader who has this plugin, and deleting the four characters that reveal that leaves
   the assumption in place and the sentence unfollowable. What is reported is the token, the part it
   landed in, and the artifact it came from.

The failure all five exist to prevent is stated once, in `bundle-packaging.md` §1, and is not
restated here: a bundle that assumes anything about the machine it lands on is a bundle the customer
cannot review, and they will not tell you that — they will review it anyway, badly.

---

## Phase 0 — Resolve inputs and gate the decided BRD

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate with `brd-key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §1). If absent or invalid, stop:
   `BRD_PACKAGE_NEEDS_KEY: /brd-package needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/dev-workflows:brd-package <KEY>'.`
2. **`--depends-on <BRD-KEY>`.** Repeatable, each consuming the next token; validate each with
   `brd-key-valid` and drop (warn, do not stop the run) any that fail shape — the same handling
   `/brd-ground` Phase 0 gives the same flag, because the flag means the same thing here and a
   mistyped prerequisite must not cost the operator the whole run. Any key at any level is
   admissible (D17), so a slice depending on another BRD and a BRD depending on a sibling express
   identically. What the flag then does is the *Resolve prerequisites and their packages* phase's
   business.
3. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`, per the
   `Required path environment variable unset` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Set SPECS_PATH (enter the path)", "Cancel"]
   ```
4. **Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute
   its `specs-preflight` entry point (§3) inline, **before** the gate below — `require-on-main`
   performs no fetch of its own (`phase-handoff.md` §3.2) and relies on this step's best-effort one,
   the same ordering `/brd-interview` uses and for the same reason. Prompt-free and silent when the
   specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
   `specs_git: blocked` (§3.3 G0), carry that flag for the whole run.
5. **Resolve the BRD folder.** `resolve-brd <BRD-KEY>` (`brd-addressing.md` §2), which searches
   `specifications/` and exactly one level below it — the two levels a BRD folder can occupy. Absent
   → stop, without asserting which command would have created it:
   `BRD_PACKAGE_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
6. **Gate the decision register on main.** This command **consumes** a `$SPECS_PATH` deliverable it
   did not write, so per `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 2 it executes
   `require-on-main` (§3) here, before anything else reads a file. Execute it against the resolved
   folder's `decisions.md`. Every deliverable one `handoff-to-main` run stages lands in a single
   commit (§2.3), so its presence on `origin/<default>` implies the round records and
   `interview/customer-questions.md` merged with it — the three files `/brd-interview`'s handoff
   stages together. Map the §3.7 return by `stopped` first: any stopping row → stop, naming the
   concrete branch/PR state it reports; `pass` → proceed; `pass_amending` → proceed, printing the
   §3.3 row-B message; `unmanaged` → proceed as before this feature; `absent` (row F — no interview
   has ever run for this BRD) → stop:
   `BRD_PACKAGE_NEEDS_INTERVIEW: no decision register on file for <BRD-KEY> — run /dev-workflows:brd-interview <BRD-KEY> first.`
7. **Gate on the interview's rounds — and read the precondition the only way that is not a
   deadlock.** Read every `interview/round-<N>.md`. Stop unless **every question in every round
   carries either a terminal disposition or the holding state *held for the customer*** — the
   vocabulary `/brd-interview`'s *Resolve the round* phase fixes. Any question in the *deferred*,
   *needs grounding* or *untagged* holding state → stop, naming each one, its round, its holding
   state and the concrete fix:
   `BRD_PACKAGE_ROUND_UNSETTLED: N questions in <BRD-KEY>'s rounds are still deferred, needs-grounding or untagged — run /dev-workflows:brd-interview <BRD-KEY> (a needs-grounding question is answered by /dev-workflows:brd-ground <BRD-KEY> first).`

   **Why *held for the customer* is admitted and the other three are not.** The design's
   precondition for this command is that the interview's open rounds are closed, and read literally
   that is a deadlock: a round holding a `[C]` stays open **until the answer comes back through the
   package** (`${CLAUDE_PLUGIN_ROOT}/references/interview-tagging.md` §5), and the package is what
   this command builds. So the only reading under which the route can run at all is the one taken
   here — everything the delivery team can settle is settled, and what remains is exactly the set
   this package is being built to carry. The other three holding states are the opposite case: each
   names work that is still ours, and packaging around one asks the customer to approve a position
   the delivery team has not finished taking.

8. **Gate on there being something to review.** A package with **no** `[C]` question, **no** open
   `[AS#n]`, and **no** `[VD#n]` in the register has nothing for a customer to confirm, correct or
   attack. Stop rather than sending it:
   `BRD_PACKAGE_NOTHING_TO_REVIEW: <BRD-KEY> holds no [C] question, no open [AS#n] and no [VD#n] — there is nothing for a customer to decide. Run /dev-workflows:brd-interview <BRD-KEY> first.`
   Note what this gate does **not** require: a package with `[VD#n]` decisions and no `[C]` question
   at all is legitimate and is packaged. Positions the delivery team took and argued are exactly the
   thing a customer review is for (`interview-tagging.md` §1 — a `[V]` may be *shown* as a position,
   it is merely never *handed over* as a question), and a review that only confirms scope,
   traceability and grounding is a review worth having.
9. **Do not re-gate allocation.** Read `coverage-ledger.md` for the review-scope part of the prompt
   and for the final report's ledger line, but do not gate on it: `/brd-interview` already refused to
   run against an unallocated ledger, and `decisions.md` cannot exist on main without that gate
   having passed. Re-gating here would add a second, differently-worded copy of a rule
   `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6.1 already owns, and the two would
   eventually disagree. Where the ledger is read at all, the **dispositions in the file** are read
   and never the ledger line, for the reason that section gives.
10. **Read the inputs the rest of the run works from**, all from the gated folder: `decisions.md`
    (every `[VD#n]` and `[AS#n]` with its `status`, `evidence`, `argumentation`, `conditional_on`,
    `altitude` and `round`); every verified `[CG#n]`/`[DG#n]` with its `verdict`, `evidence`,
    `horizon` and verifier `outcome`; `grounding/baselines.md`; `brd/brd-inventory.md`'s `[BR#n]`
    rows; `coverage-ledger.md`; `brd-link.md`; `interview/customer-questions.md`; every
    `interview/round-<N>.md`; and, when this is a re-package, every earlier
    `self-review-<YYYYMMDD>.md`. A previous package's artifacts are inputs, never scratch: nothing
    below deletes, renames or rewrites a dated artifact another run wrote.
11. **Fix the run's date.** One `<YYYYMMDD>` stamp, taken once, used for every artifact this run
    writes. If `bundle-<YYYYMMDD>/` already exists in the BRD folder, stop:
    `BRD_PACKAGE_BUNDLE_EXISTS: <BRD-dir>/bundle-<YYYYMMDD>/ already exists — a dated bundle is never rewritten. Move or rename the existing directory if it was never sent, or package on the next date.`
    **A dated bundle is never rewritten** (`bundle-packaging.md` §5): rewriting it destroys the only
    evidence of what the reviewer of that date was looking at, and every claim in their returned
    review then silently re-points at a document they never saw. This command cannot tell whether
    the existing directory was already sent, and the party who can is the operator, so it stops and
    says so rather than guessing either way.

---

## Phase 1 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: SIGNIFICANT     # floors here — the self-review is adversarial and its output
                                  # gates the run, and the rendered prompt leaves the organisation
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # impl-maintenance only
  review_model:    <§2 Opus chain>     # brd-package-reviewer (frontmatter-pinned; recorded, no override)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`brd-package-reviewer` keeps its frontmatter Opus pin regardless of classification, the same way
`grounding-verifier` does in `/brd-ground` — `review_model` is recorded, never used to override the
pin. **The classification floors at `SIGNIFICANT`** because of what this run produces rather than how
much of it there is: a self-review that finds nothing is a rubber stamp, and a rendered prompt is
the one artifact in this plugin that a person outside the organisation reads without anyone
present to correct it. If no Opus resolves, degrade to best-available, record it in `notes`, in the
self-review's own header and in the final report — a package whose adversarial pass ran on a weaker
model is still a package, and the customer's own reviewer is the second pass, but the operator must
know which they got. Never hard-block.

---

## Phase 2 — Resolve prerequisites and their packages

Persist every `--depends-on` key the *Resolve inputs and gate the decided BRD* phase accepted into
`<BRD-dir>/brd-link.md` under a `depends-on:` list —
**additive only**: merge into whatever the file already carries (including a `parent:` or `claims:`
field another command wrote), never drop an existing prerequisite, and never touch any field but
`depends-on:`. This is the same additive merge `/brd-ground` Phase 4 performs on the same field, and
it is additive for the same reason: the file is also edited by hand between runs, and a run that
replaced the list would silently drop a prerequisite nobody re-declared.

For every declared prerequisite (this run's plus any already on file):

1. `resolve-brd <PREREQ-KEY>`. Absent → record `<PREREQ-KEY> — BRD not found`, carry it into *what
   could still move* as a prerequisite whose state is unknown, and do not stop: a prerequisite the
   delivery team cannot resolve is exactly the kind of thing the customer should be told about.
2. Found → determine **whether its decisions have been customer-reviewed**. They have been if and
   only if that folder's `decisions.md` holds at least one `[CD#n]` — a customer decision enters the
   register only once the customer answered and an operator confirmed it (D14,
   `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1), so a `[CD#n]` on file is the
   only evidence a review actually came back. Anything less — an open round, a package that was sent
   and not answered, a folder with `[VD#n]` records only — is **not** customer-reviewed.
3. Found → look for its own most recent `bundle-<YYYYMMDD>/`. Present → it is copied into this
   bundle by the *Assemble the bundle* phase and marked **not for re-review**. Absent → record
   `<PREREQ-KEY> — no package on file; nothing to copy in`, and say so in the prompt's part naming
   what each package in the bundle is for, rather than referring the customer to a package they were
   not given.

**Step 2's test is written against the register, never against a run's history.** `/brd-reconcile`
is the one command that writes a `[CD#n]`, and it writes one only once an operator has confirmed a
returned answer (D14, `decision-register-format.md` §1) — so a `[CD#n]` on file is evidence that a
review actually came back *and* was confirmed, which is exactly the question step 2 asks. A
prerequisite that was packaged and sent, or whose review is sitting unreconciled in somebody's
inbox, reads *not customer-reviewed* here, correctly: nothing about it is frozen yet, and every
position resting on it can still move.

Carry, for each prerequisite: its key, whether it resolved, whether its decisions are
customer-reviewed, whether a package of its own was found, and **every decision in this BRD's
register carrying `conditional_on: <PREREQ-KEY>/<decision-id>`** (`decision-register-format.md` §5).
Those are the positions D20 obliges the prompt and the delivery note to name, and they are found
mechanically by the field rather than by reading — which is the whole point of the field existing.

---

## Phase 3 — The adversarial self-review

Dispatch `brd-package-reviewer` once, over the whole package, pinned to the Opus chain
(`review_model`, frontmatter-pinned, no override):

→ Agent (subagent_type: "dev-workflows:brd-package-reviewer", model: `<review_model>`):
  > "brd_key:    [the BRD key]
  > brd_dir:    [absolute path to the resolved BRD folder]
  > package:
  >   decisions:      [path to decisions.md]
  >   grounding:      [paths to grounding/code-grounding.md and grounding/design-grounding.md]
  >   seeds:          [paths to prd-seed.md / ard-seed.md / spec-seed.md, as they exist]
  >   ledger:         [path to coverage-ledger.md]
  >   questions:      [path to interview/customer-questions.md]
  >   prior_reviews:  [paths to every earlier self-review-<YYYYMMDD>.md, or omit when none]"

Supply the package **exactly as the agent's own Inputs contract declares it**, and supply all of it:
that agent refuses to run without `brd_dir`, `package.decisions` and `package.grounding`, returning
`status: INPUT_MISSING`. Map that return to a stop naming the field it named — it is a defect in
this dispatch, not in the package, and proceeding past it would build a bundle on a review of
nothing.

**One dispatch, not one per document.** The five classes that agent works are cross-document by
construction — a decision read against the finding it cites, a `[C]` question read against the test
that says who may answer it — and an agent handed one document at a time can only find things about
sentences.

**This command does not dispose of anything here, and it does not read a verdict.** The agent
returns `status`, a `findings` list of `[SR#n]` records each carrying `disposition: undisposed`, a
per-class `passes` account, and optional `notes`. **There is no PASS/BLOCK verdict, deliberately**,
and nothing below waits for one: the gate is the next phase, and a run that looked for a verdict
would sit forever on an agent designed never to emit one.

**An empty findings list is accepted only with its account.** The agent owes a per-pass statement of
what each of the five passes examined; an empty list arriving without it is the same output an agent
produces when it read nothing. Missing account → re-dispatch once, naming the omission; still
missing → stop rather than package against a review that may not have happened:
`BRD_PACKAGE_REVIEW_UNACCOUNTED: brd-package-reviewer returned no findings and no per-pass account — the review cannot be distinguished from a run that read nothing.`

Write `<BRD-dir>/self-review-<YYYYMMDD>.md` now, before any disposition is taken, holding the
agent's findings verbatim with their classes, targets, attacks, `rests_on` lists and
`what_would_settle_it` statements, plus the per-pass account, the model the pass actually ran on,
and — when this is a re-package — which prior `[SR#n]` each finding restates.

**The dated review owns the numbering, not the dispatch.** `[SR#n]` is scoped to one BRD *per dated
review* (D21's namespace table), and the agent numbers from `SR#1` in **every** dispatch, so the id
this command writes into the review is assigned as the finding is recorded, continuing from the
highest already in that file, with the agent's own pass-local number kept beside it so the mapping
is visible. An id once written into a dated review is never renumbered and never reused; a
re-package is a *new* dated review and starts from `[SR#1]` again, naming the prior review's id
inside each record rather than continuing a sequence across dates.

---

## Phase 4 — The disposition gate

**No bundle is built while any `[SR#n]` is undisposed.** Present each finding to the operator, one
at a time, never batched, with its class, its target, its attack and its `what_would_settle_it`
statement, and take exactly one disposition:

```
choices: ["Fixed — the package has been corrected; say what changed", "Accepted risk — ship it, and show this finding to the customer", "Escalated to the customer — turn it into something the package asks them", "Rejected with reason — the attack does not hold; say why", "Cancel"]
```

**This is not an escalation choice list**, and it is not one of the arrays
`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` owns: its four options are the four
disposition values `agents/brd-package-reviewer.md` fixes, drawn from that agent's own contract the
same way `/brd-interview`'s will-change picker draws its three resolutions from
`decision-register-format.md` §6. It carries **no** `"Other… (describe)"` entry, and that omission is
required rather than merely permitted: the disposition vocabulary is exactly four values, and a
fifth would be a disposition nothing downstream can read — which is why `escalation-rules.md` names
this picker in its *The permitted adjustment does not reach these arrays* section rather than leaving
its own "one permitted adjustment" sentence to overrule the command. `Cancel` stops the run with every
disposition already taken still written, so nobody is trapped and nothing is lost.

Each disposition carries a recorded reason, and each has a consequence the later phases execute:

| Disposition | What it obliges |
|---|---|
| `fixed` | The named artifact is corrected **before** the prompt is rendered, and the correction is recorded against the finding. A `fixed` disposition whose artifact is unchanged is not `fixed` |
| `accepted-risk` | The finding is listed to the customer under *where to attack us hardest*, in the reviewer's own words. There is no drawer this puts it in |
| `escalated-to-customer` | The finding is put to the customer in the prompt's *decisions the customer must make* part, carried by its own `[SR#n]`. Admissible **only** where `interview-tagging.md` §2's test says so — what would settle it is an authority only the customer holds. Where a delivery-side trade-off would settle it, this is the wrong disposition and the finding takes another |
| `rejected-with-reason` | The reason is recorded in the self-review and stays inside the delivery organisation. Nothing rejected reaches the customer |

**The gate is keyed on every finding carrying a non-`undisposed` value, and on nothing else.** Not
on a count, not on a severity, not on a verdict — the agent emits no severity and no verdict by
design, and `[SR#n]` disposition is the only gate there is. Any finding still `undisposed` when this
phase would end → stop:
`BRD_PACKAGE_UNDISPOSED: N [SR#n] findings are still undisposed — every finding takes one of fixed | accepted-risk | escalated-to-customer | rejected-with-reason before a bundle is built.`

**A `fixed` disposition re-opens the self-review, exactly once.** Correcting a decision, a seed or a
`[C]` question changes the package the review was written against, so after every `fixed` correction
has been applied, re-dispatch `brd-package-reviewer` once over the corrected package, with this
run's `self-review-<YYYYMMDD>.md` in `prior_reviews` — that agent reads `prior_reviews` last, after
its own passes are complete, which is exactly the ordering wanted here. Findings from that second
pass are appended to the same dated review under ids continuing from the highest already in it, and
take dispositions through this same phase. **Once, not until clean**: an unbounded loop trades the customer's review for the delivery
team's, and the second pass exists to catch what a correction broke, not to reach an empty list. A
finding from the second pass may itself be disposed `accepted-risk`, and it then travels to the
customer like any other.

`rejected-with-reason` is a real option and is meant to be used. The agent is told to state what
would have to be true for the target to stand precisely so that a rejection has something to argue
against, and a package that disposes every finding `fixed` has either been extraordinarily lucky or
has stopped reading the attacks.

---

## Phase 5 — Assign the degradation tier

The tier records **what the reviewer was actually able to be given**, it is a fact about the bundle
established here, and it is written into the prompt along with the sentence the reviewer's own
evidence-limitations section must then carry (`bundle-packaging.md` §3).

Read `grounding/baselines.md` for the repositories this package cites and the commit each is pinned
to. Then:

- **No repository in `baselines.md` at all** → the tier is **Documents only**, and the answer is
  determined, so no list is presented. Use the inline-confirmation form the
  `When a choice list fires` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` defines,
  and proceed: `Shipping at the documents-only tier — this package cites no repository, so there is nothing to pin. Say so if the customer can in fact be given one.`
- **Otherwise** → ask, once, for the whole bundle:

  ```
  choices: ["Full — the customer gets the repositories pinned to the commits this package cites", "Partial — the customer gets the repositories, but not pinned (an archive of a moving branch)", "Documents only — the customer gets no repositories", "Cancel"]
  ```

  **Not an escalation array either**: the three options are the three rows of `bundle-packaging.md`
  §3's own table, in that table's order. No `(Recommended)` marker, and the reason is stated beside
  the list per the `When no option is safe to recommend` guidance in `escalation-rules.md`: which
  tier is right is not a judgement at all, it is a fact about what this customer can be given, and a
  marker would invite the run to ship at Full because Full is better.

**The tier is never promoted, and this command never assumes one.** A bundle is not quietly shipped
at Full because the repositories were *probably* at the right commit — an unpinned archive is
Partial, and it says so. A reviewer cannot promote themselves to Full by being thorough either, and
the prompt says that too. **A tier is not a quality grade**: a documents-only review that states its
tier is more useful than a full-tier review that does not, because the first can be weighed
correctly and the second cannot be weighed at all.

Carry the tier, and carry the sentence §3's table obliges the reviewer's own section 1 to state. The
prompt renders that sentence verbatim rather than paraphrasing it, so the reviewer is told what to
write rather than left to invent an equivalent.

---

## Phase 6 — Render the customer prompt

Write `<BRD-dir>/customer-review-prompt-<YYYYMMDD>.md`, assembled from the package, **never
hand-written**, in this fixed order. The eleven parts are the design's, and they are not
re-ordered, merged or renumbered for a package that happens to have little to put in one of them —
a part with nothing in it says `none` and says why, for the same reason the review's own sections
do.

| # | Part | Filled from |
|---|---|---|
| 1 | Setup | the tier; the archive command; the fixed capability line and OS note below |
| 2 | What each package in the bundle is for | this BRD, plus each prerequisite package copied in, marked *not for re-review* |
| 3 | Documents to review | the bundle manifest, by filename |
| 4 | Code baselines and the verification procedure | `grounding/baselines.md`, with the three commands written out |
| 5 | The single most important claim to verify first | the register and the findings, by the rule below |
| 6 | Review scope | `coverage-ledger.md` dispositions and `brd/brd-inventory.md` |
| 7 | The decisions the customer must make | `interview/customer-questions.md`, every open `[AS#n]`, and every `escalated-to-customer` `[SR#n]` |
| 8 | What could still move | the prerequisites resolved above, and every `conditional_on` position (D20) |
| 9 | Where to attack us hardest | every open `[AS#n]`, and every `accepted-risk` `[SR#n]` |
| 10 | The required output file, its name, and the inlined schema | the D13 rule, and `render-schema` below |
| 11 | What this session cannot settle | the ledger, the prerequisites, and the review's own limits |

**Part 1 — Setup.** States, in this order: the one-line capability set the prompt assumes — *this
prompt assumes an agent that can read files in a folder and search for a file by name; the pin check
in part 4 additionally needs a terminal, and a reviewer whose tool has none says so in their section
1 and skips it*; what to put on the machine (the extracted bundle, and the repositories if the tier
gives them any); **the OS note** — *extract the archive to a real folder before pointing anything at
it: a file browser will show you the contents of a `.zip` without extracting it and a tool that
opens files by name will find nothing there, macOS puts the documents one level down inside a folder
of the same name, and filenames contain spaces, so quote them*; what to do if the repositories
cannot be obtained after all — *review the documents and record in your section 1 that no code claim
was independently verified; do not skip the review*; and, once, the rule that governs the whole
session: **read the bundle, write exactly one new file, and modify nothing in the package** (D13).

**Part 4 — Code baselines and the verification procedure.** One row per repository: the repository,
the commit it is pinned to, and how that pin was verified. Then the three `baseline-integrity`
commands, **written out with the repository and the commit substituted**, as an instruction to run
rather than a reference to follow — `grounding-format.md` §4 is the authority for them and is not
citable in the customer's copy, which is exactly why they are inlined:

```
git -C "<repo>" rev-parse HEAD                      # must print <the commit this package cites>
git -C "<repo>" diff --ignore-cr-at-eol --stat      # must be empty
git -C "<repo>" status --porcelain                  # any entry needs a line-count comparison
```

State what each is for and what a mismatch means, and ask for the result in the review's section 1.
At the Partial and Documents-only tiers the block is still printed, marked as unrunnable at this
tier and why — a reviewer who is told the procedure exists and that they cannot run it writes a
better section 1 than one who is told nothing.

**Part 5 — the single most important claim to verify first.** Exactly one, chosen mechanically:
the `[CG#n]`/`[DG#n]` finding cited in the `evidence` list of the greatest number of `[VD#n]`
records; ties broken in favour of the finding whose falsity would reopen the most `[BR#n]` rows, and
then by lowest id so the choice is reproducible. Where the register cites no finding at all, the
most-depended-on open `[AS#n]` takes the slot, marked as an assumption rather than a finding. **One,
because a list of five is not a first**: the purpose of the part is to spend the reviewer's freshest
attention on the claim carrying the most weight, and a list spends it on choosing.

**Part 7's three sources, and why the third is admissible.** The design fixes that every item here is
traceable to a `[C]` question or an open `[AS#n]`. An `escalated-to-customer` `[SR#n]` is traceable in
the same way — to a recorded, identified finding in this run's own self-review, which the customer
can cite back — and part 7 is the only part that asks the customer to decide anything, so a
disposition whose whole meaning is *ask them* has nowhere else to go. **This command mints no `[C]`
identifier and writes nothing into the interview's question set**: tagging a question is
`/brd-interview`'s discipline, and a package that raised `[C]` questions of its own would put a
question to the customer that never went through the tag test — the failure `interview-tagging.md`
§2 exists to prevent, arriving one command later. The escalated finding travels under its `[SR#n]`,
and the answer comes back in the review's section 7 like any other.

**Part 7 and part 9 both carry every open `[AS#n]`, and that duplication is deliberate.** They ask
for different things. Part 7 asks the customer to **decide** — an assumption is corrected in one
sentence while it is still an assumption, and that is the cheapest correction in the whole loop.
Part 9 invites them to **attack** it. Removing either copy as redundant loses one of the two, and
the one that gets lost is always the attack. **Every** open `[AS#n]` appears — not the ones that
seem material, not the ones somebody remembered — because the selection step is where this rule
would fail (`decision-register-format.md` §7). Each carries its `statement`, its `evidence` field's
account of why no evidence exists, and its `argumentation`.

**Part 8 — what could still move (D20).** Every declared prerequisite whose decisions are **not yet
customer-reviewed**, named, with what is unsettled about it; and every position in this package
carrying `conditional_on` one of them, named by its `[VD#n]` and its `statement`. A package may ship
while a prerequisite is unreviewed — **loudly**, which is what this part is. Say in one line what
the customer's own review should then do about it: mark the affected approvals in their section 3 as
contingent, and **not** list the prerequisite in their section 10 as a blocker, because it is not
blocking, it is unsettled, and the two get very different treatment on the delivery side. A package
with no prerequisite at all says so explicitly — a reviewer who was told nothing could move writes
no contingent rows, and their absence then means what it says.

**Part 9 — where to attack us hardest.** Every open `[AS#n]`, and every `[SR#n]` this run disposed
`accepted-risk`, each in the reviewer agent's own words rather than re-summarised — that agent
writes its findings knowing they may end up here. Nothing disposed `fixed` appears (it is no longer
true of the package), and nothing disposed `rejected-with-reason` appears (the rejection is ours to
own, and shipping an attack the team has already argued against invites the customer to referee an
internal disagreement). **A package that names its own weak points gets a review worth having; one
that does not gets a rubber stamp** — which is the entire reason this part is assembled rather than
written.

**Part 10 — the output file and the inlined schema.** The output filename, exact:
`<BRD-KEY> Customer Review <YYYYMMDD>.md` — for the synthetic BRD `EPIC-008` packaged on 15 April
2026, `EPIC-008 Customer Review 20260415.md`. One line saying it is the only file to send back. The
D13 rule stated **again** here, having already been stated in part 1, because an agent asked to
review documents will otherwise helpfully edit them. Then the schema, inlined by `render-schema`
below.

### Entry point: `render-schema`

1. Read `${CLAUDE_PLUGIN_ROOT}/references/customer-review-schema.md`.
2. **Confirm the file still declares its own render boundary.** Its preamble states that the
   rendered body is everything from section 2 onward, and that the preamble and section 1 are
   addressed to the delivery team. Absent or reworded → stop:
   `BRD_PACKAGE_SCHEMA_BOUNDARY: customer-review-schema.md no longer declares which part of it is rendered — a render that guesses the boundary is exactly the leak D12 exists to prevent.`
   The boundary is read out of the file rather than hard-coded here so that the file and its renderer
   cannot drift apart, which is the same reason the schema is inlined rather than quoted.
3. Take everything from the first `## 2.` heading to the end of the file. **Never the whole file.**
   Everything above that heading is the preamble and section 1, and the preamble is where that file
   deliberately collects its `references/…` citations, its design-spec path and its decision-row
   references — every one of which is unresolvable to a reader with no plugin.
4. **Renumber the body's own headings so the customer's copy runs from 1** — `## 2.` becomes `## 1.`
   and so on through `## 6.` becoming `## 5.` — so the pasted prompt does not visibly begin at
   section 2 and invite the reader to hunt for a section 1 they were never given. This is safe
   because that file refers to its own sections **by name** and never by number, so nothing inside
   the extracted body cross-references a heading by its pre-render number. Verify it rather than
   trusting it: the extracted body must contain **no `§` character**, which is this plugin's own
   notation for a numbered cross-reference. Any `§` in the body → stop under the scan below rather
   than renumber around it. Every plain "section N" that remains inside the body is a section of the
   **review being written**, numbered 1 to 12, which is the schema's own rule and the reason a bare
   number there is never ambiguous to the reader who matters.
5. Render the result under a heading of the prompt's own, introduced in one line as the rules the
   returned review must satisfy.

### The plugin-free scan

The last thing this phase does, over the **finished** prompt text — not over the templates, and not
over the schema alone. Stop the run on any hit, naming the token, the part it landed in, and the
artifact it was interpolated from:

| Class | Examples |
|---|---|
| A path rooted at the plugin's install directory | the plugin-root variable, in any form |
| A reference-file citation | `references/…`, `docs/superpowers/…` |
| A numbered cross-reference in this plugin's notation | any `§` |
| A slash command | `/brd-…`, `/dev-workflows:…`, any leading-slash command name |
| An agent, subagent type or skill name | `subagent_type`, any `dev-workflows:` prefix, any agent filename |
| A decision-row reference | `D12`, `D13`, `D18`, `D20`, or any other bare `D<n>` row id |

`BRD_PACKAGE_PROMPT_LEAK: the rendered prompt carries <token> in part <n>, interpolated from <artifact> — the prompt is read by somebody with no plugin, and a token they cannot resolve is not fixed by deleting it.`

**The scan stops; it never sanitises.** A citation that reached the prompt reached it because some
sentence in the package assumed a reader who has this plugin, and stripping the citation leaves that
sentence unfollowable while making it look fine.

Identifiers are **not** in the scan's classes and are meant to travel: `[BR#n]`, `[CG#n]`, `[DG#n]`,
`[VD#n]`, `[AS#n]` and `[SR#n]` are how the returned review cites the package's own claims without
minting identifiers of its own, and a prompt that hid them would get back a review nothing could be
matched to.

---

## Phase 7 — Render the delivery note

Write `<BRD-dir>/customer-delivery-note-<YYYYMMDD>.md` — the covering letter that goes in the email
body. **It is not part of the bundle** (`bundle-packaging.md` §4): it is the email, not a package
document, and a copy of it inside the bundle would be a second, divergent statement of what was
sent. The *Assemble the bundle* phase does not copy it in, and the manifest does not list it.

It states only: which BRD this is; what is attached; which repositories, at which commits; **which
file is the prompt** — the one file to paste; **which file comes back** — the one file to send,
named exactly; any prerequisite whose decisions are still provisional and that positions resting on
it could move (D20); and anything else that must not sit buried inside a document. The two bolded
items are bolded in the rendered note too, because the single most common failure of this loop is a
reviewer who reads the documents, forms a view, and writes it into an email of their own devising —
having been told, in the first thirty seconds, neither that there was a prompt to paste nor that
there was a named file to return.

**Hard length rule: 200 words. Not a target, a ceiling.** Count the rendered note's words and refuse
to ship one over it — shorten and re-render rather than trimming the two bolded facts, which are the
last things to go. Past roughly that length the note stops being a covering letter and becomes a
document, and a document is precisely what nobody reads before clicking into the attachment, which
puts the two facts that must not be missed back inside the thing they were lifted out of.

**It is not a per-file table.** The manifest inside the bundle covers per-file detail, and
duplicating it here guarantees the two disagree after the first correction.

Run the plugin-free scan over the finished note, exactly as over the prompt, and stop on any hit —
the note is read by the same reader, on the same footing, before they open anything.

Print the note **in full** in the final report, so it can be pasted into an email without opening a
file.

---

## Phase 8 — Assemble the bundle

Write `<BRD-dir>/bundle-<YYYYMMDD>/`. The bundle is a **rendered copy**, produced on the way out;
the working documents keep their wikilinks and are never rewritten in place
(`bundle-packaging.md` §2).

**What goes in:** this package's own documents; the prompt; every prerequisite package resolved
above, copied in and marked **not for re-review**; every image those documents reference; and a
manifest. Plain markdown and images, and nothing else. **What does not go in:** the delivery note,
and anything a reader outside a vault cannot see.

1. **Name every bundle document distinctively.** Documents are located by **filename search, never
   by path**, because a path is correct exactly once — in the directory layout this machine had —
   and the bundle will be extracted, renamed, re-zipped and mailed on. So each document's bundle
   filename carries the `<BRD-KEY>` and is unique within the bundle, and every reference from one
   bundle document to another, and every instruction in the prompt that sends the reviewer to a
   document, names that filename and tells them to search for it.
2. **De-Obsidianise every copied document.** Rewrite wikilinks to plain filename references, and get
   the three cases `bundle-packaging.md` §2 names right: an **aliased** link keeps the alias as the
   visible text *and* names the file; an **embedded image** becomes an ordinary markdown image
   reference to the image copied in beside it, or — when the image is not copied — a plain sentence
   saying what was there and that it is not included; and a link whose **target is not in the
   bundle** is never rewritten into a bare filename, but becomes a plain description of the target
   and an explicit statement that it is not included. A filename that is not in the bundle is the
   failure the whole pass exists to prevent: it looks resolvable, the reviewer searches, finds
   nothing, and cannot tell whether the file was forgotten, withheld or renamed.
3. **Keep callouts.** A callout block degrades to an ordinary blockquote in any reader — the label's
   styling is lost and every word is kept. Nothing that survives untranslated is worth translating.
4. **Remove anything that renders in exactly one tool** — canvas or database-view files, query or
   dataview blocks, plugin-specific embed syntax, frontmatter that means nothing outside the vault —
   converting it to something that renders everywhere, or removing it **with a note saying what
   stood there**. A block that silently renders as nothing is the same defect as a dead wikilink:
   the reviewer cannot see that they are missing something.
5. **Copy each prerequisite package in, marked *not for re-review*.** The marking is on the
   documents' own front matter line in the bundle and in the manifest, and the prompt's part 2 says
   what each is for. A prerequisite package is context for the positions this package took on top of
   it — it is not a second package to review, and a reviewer who reviews it anyway spends their
   effort on decisions another review already settled or will settle.
6. **Write the manifest**, listing documents **by filename** — the same reason rule 1 names them
   that way — with one line each saying what the document is and whether it is for review or *not
   for re-review*. The manifest is a bundle document; the delivery note is not.
7. **Run the plugin-free scan over every document in the finished bundle**, and stop on any hit. The
   scan runs here as well as over the prompt because a leak can arrive through a copied document as
   easily as through a rendered part, and this is the last point at which anything is still ours.

**The bundle is committed** (D18), through the handoff below. That serves both delivery routes with
one artifact: a customer with repository access pulls it and needs nothing else, and everybody else
gets **one archive command**, printed at the end of the run with an absolute path:

```
cd "<BRD-dir>" && zip -r "<BRD-KEY>-bundle-<YYYYMMDD>.zip" "bundle-<YYYYMMDD>"
```

One command, in a format that opens on any desktop without installing anything, because the
population that cannot pull the repository is exactly the population that will not assemble an
archive command themselves.

**The committed copy is the permanent record of exactly what was sent.** It is what makes the
byte-identical property behind the one-new-file rule checkable months later: when a returned review
quotes a sentence, there is a committed copy of the document that sentence came from, at the version
the customer actually received — not a reconstruction from working documents that have moved on. The
acknowledged cost is a derived duplicate in the repository, and it is deliberate.

---

## Phase 9 — Handoff

Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`phase-handoff.md` §2) with `prefix: brd` (§2.9's
table, where `brd` is the prefix every `/brd-*` command shares), `feature_folder` as resolved in the
*Resolve inputs and gate the decided BRD* phase, `deliverable_paths` = every file this run wrote
under `<BRD-dir>` (`self-review-<YYYYMMDD>.md`, `customer-review-prompt-<YYYYMMDD>.md`,
`customer-delivery-note-<YYYYMMDD>.md`, every file under `bundle-<YYYYMMDD>/`, and `brd-link.md`
when this run added a prerequisite to it), `title: <BRD-KEY> Package for customer review
<YYYYMMDD>`, and `body_facts` = the degradation tier; the `[SR#n]` counts by disposition; the count
of `[C]` questions and open `[AS#n]` the prompt carries; every prerequisite named under *what could
still move*; and the repo→SHA table. Emit its §4.1 outcome line in the final report.

---

## Phase 10 — Next steps

The BRD-to-PRD route's next command is `/brd-reconcile`, which takes the returned review and turns
each confirmed answer into a `[CD#n]` — and it is offered, named for what it needs, because it
cannot run until a review actually comes back. `--from-brd` on `/create-prd`, which would carry a
decided, reconciled BRD into a PRD, **does not exist yet** and is not offered: offering a command the
plugin does not ship would be worse than offering nothing. So the honest offer is the state this run
actually leaves behind:

```
choices: ["Stop here — the package is written and, if you handed it off, committed", "Send it — the delivery note is printed above and the archive command is in the report", "Reconcile the review once it comes back — /dev-workflows:brd-reconcile <BRD-KEY> @<review-file>", "Package another BRD or slice", "Other… (describe)"]
```

**No option carries a `(Recommended)` marker, and that omission is deliberate**, per the
`When no option is safe to recommend` guidance in
`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`: whether to send is a delivery judgement this
command has no basis for — a package shipped at the documents-only tier with three `accepted-risk`
findings may be exactly right to send today or exactly right to hold, and only the operator knows
which. The reason is stated here, beside the list, rather than folded into a conditional marker the
orchestrator would then have to evaluate.

Say plainly what remains, per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — names only,
never behaviour a command of its own owns: the round holding each `[C]` stays open until the
customer's answer comes back and `/dev-workflows:brd-reconcile` records it, and what happens between
this run and that one is not the plugin's to do — the package has to reach a customer and the
customer has to answer.

### Context hygiene

The resume pointer is written in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Re-packaging the same BRD after a
correction? → run **`/compact`**. Moving to a different BRD or slice? → run **`/clear`**. Guidance
only — nothing is auto-run.

---

## Phase 11 — Session maintenance, feedback & cost

Terminal phase — runs after *Next steps*, and NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin / skill / command / reference
gap, `emit-block` (`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) fires at that halt before
escalating. Two of this command's stops **do** qualify and are the reason the invariant is named
here: `BRD_PACKAGE_SCHEMA_BOUNDARY` and `BRD_PACKAGE_PROMPT_LEAK` are both reference-integrity gaps —
a rendered authority whose boundary moved, and a package artifact carrying a citation that should
never have been written into it. None of the others do: a missing or malformed key, an unresolved
BRD, an ungated or absent register, an unsettled round, a bundle directory that already exists, and
an unset `$SPECS_PATH` are environment or sequencing halts. `BRD_PACKAGE_UNDISPOSED` is not one
either — it is the gate working.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-package`; what was produced (the
   self-review, the prompt, the delivery note, the bundle); key events (the tier assigned and why,
   the `[SR#n]` dispositions, a re-dispatch after a `fixed` correction, a prompt-leak stop, a
   prerequisite with no package on file — or "none"); workarounds; test result N/A; project root =
   the BRD folder.
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-package`, the run's `jira_key` (the `<BRD-KEY>`),
   `source`, and `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no
   plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call
   its `emit-cost` entry point with `command: /brd-package`, `phase: brd-to-prd`, `role: pm`, the
   run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and
   write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry, before the commit
   step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry
   point (§4) inline — the LAST action of the run. Stages ONLY the §2.1 bounded artifact paths inside
   `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-package)` with no
   `Co-Authored-By` trailer, and pushes to the branch the handoff phase created. NEVER touches a code
   repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the
   run; skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice.
   Hold its §6 outcome line for the final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is
offered only in the handoff phase), and NEVER writes into a code/docs repo, the vault, or the current
working directory; no user name is ever written.

---

## Final report

Report: the BRD folder and which of the two levels it sits at; the classification and model routing
(+ any Opus degradation, named again here because a self-review that ran on a weaker model is a
weaker gate); **the degradation tier**, and the sentence it obliges the customer's own review to
carry; **every `[SR#n]` with its disposition**, grouped by disposition, with the `accepted-risk` ones
listed in full because those are the ones the customer will read; whether a second reviewer pass ran
after a `fixed` correction and what it added; the counts the prompt carries — `[C]` questions, open
`[AS#n]`, `escalated-to-customer` findings; **every prerequisite named under *what could still
move***, with whether it resolved, whether its decisions are customer-reviewed, and whether a
package of its own was copied in; the four artifacts written, by path; **the delivery note, printed
in full**; the archive command, with an absolute path; the feedback + cost paths; the
`Phase handoff:` outcome line (`phase-handoff.md` §4.1); the `Specs repo:` outcome line
(`specs-repo-git.md` §6); the next-step recommendation; and — before the ledger line — the
**repo→SHA table**:

```
baselines: <repo> @ <commit> (<how it was verified>)
           <repo> @ <commit> (<how it was verified>)
```

One row per repository in `grounding/baselines.md`, printed here as well as in the prompt because it
is what a reader of this run's own output needs in order to answer "what was this package pinned
to?" without opening the bundle. No repository on file → one line saying so, and naming the
documents-only tier it forced.

End with the ledger line, read fresh from the (unmodified-by-this-run) `coverage-ledger.md`, exactly
per `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

`/brd-package` never changes a ledger disposition — the line simply reports where allocation stands.
**Reporting it reads one child ledger per `covered-by` row**, one hop, from the working tree via
`resolve-brd` (`brd-addressing.md` §2), per `coverage-ledger-format.md` §6.1; a child that cannot be
read there contributes `unresolved`, never `covered` (§6.2). A slice reaches this with nothing to
resolve, since `covered-by` is unavailable on one (`coverage-ledger-format.md` §3), so its line
always reports zero delegated.

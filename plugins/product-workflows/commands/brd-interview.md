---
name: brd-interview
description: BRD decision workflow (PM phase, the BRD-to-PRD route's decision step, run once per slice once `/prd-ground` and `/brd-split` have both run on it). Gates on the BRD's grounding being merged, every finding carrying a verifier outcome, and its coverage ledger fully allocated, then generates the round's question set and tags every question [G]/[V]/[C] before a single one is asked. Answers every [G] from the grounding findings and never puts one to a human; puts each [V] to the operator one at a time via AskUserQuestion with mandatory argumentation; holds every [C] for the customer. Re-tags a [G] only against a named NOT-PROVABLE finding, splits any question carrying more than one tag, and refuses to close a decision resting solely on a will-change finding. Writes decisions.md ([VD#n] and [AS#n]), the round record, and the [C] question set, plus the code-defect log where a decision turns on one. --round N resumes an open round or re-opens a closed one, recorded with its cause. Takes no --no-docs and does no documentation grounding.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Turn the grounded BRD into a decided one, one round at a time: $ARGUMENTS

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

`/brd-interview` is the **BRD-to-PRD route's decision step** (PM phase) — it takes the verified
findings `/prd-ground` produced and the fully-allocated ledger `/brd-split` left behind, and works
the BRD's open questions to recorded decisions. Its whole discipline is one rule: **every question
is tagged before it is asked, and the tag decides who may answer it**
(`${CLAUDE_PLUGIN_ROOT}/references/interview-tagging.md` §1). This command exists to make that
happen, not to restate it.

Usage: `/brd-interview <BRD-KEY> [--round N]`

`<BRD-KEY>` still resolves through either of the two levels `resolve-address` searches
(`workflows-core:addressing` §3) — a BRD that owns its source document, or one of its slices —
because a root must be resolved before Phase 0 step 5a can refuse it by name. **Only a slice is
interviewed: a root BRD is refused, and deciding happens at the slice and nowhere else** — a slice
holds its own findings, its own ledger, and its own register, and it reaches its decisions exactly
as its parent does. The register this run writes is the register of the BRD it was given, and no
other.

**Standing rule, binding on every phase below.** A `[G]` is answered from the grounding findings and
is **never put to a human** — not the customer, not the delivery team, not the operator watching the
run (`interview-tagging.md` §1, D8). A `[V]` is put to the operator with recorded argumentation and
is **never routed to the customer** as a business question (§1, D9). A `[C]` is held. The section
*How no `[G]` reaches a human* below states the ordering that makes the first of those structural
rather than aspirational.

**This command takes no `--no-docs`, and it does no documentation grounding at all. That is a
decision, not an omission.** `/brd-intake` and `/prd-ground` already ground this BRD against the
shipped product documentation when `$DOCS_PATH` resolves (D22,
`workflows-core:docs-grounding`), and their run is the one that had the
requirement text and the code in front of it. This command operates on **decisions** — on findings
that have already been verified and on choices the delivery team and the customer own — and a
documentation page settles none of those: it is a claim *about* behaviour, not the behaviour, which
is why `/prd-ground` already forbids one as evidence for a `[CG#n]`. So there is no flag to turn
off, no `resolve-docs-grounding` call, and no `docs grounding:` line in this command's report. The
sentence is written here because leaving it unwritten is exactly how the gap it forecloses gets
shipped.

**No repository is opened, at any point.** Every `file:line` this command reads has already been
pinned and verified by `/prd-ground`, so there is no baseline gate here, no dirty-tree stop, and no
`$REPOS_PATH` requirement. A question that would need a repository opened to answer it is a question
this command cannot settle, and the *Answer every `[G]` from the findings* phase says what happens
to it — which is never "ask somebody instead".

---

## How no `[G]` reaches a human

Five properties, and every one of them is a property of the **order and the inputs of the phases
below**, not an instruction to be careful. Together they are the guarantee; individually none of
them is.

1. **Tagging precedes asking, for the whole set at once.** The *Tag every question* phase runs to
   completion over the entire round before the *Put each `[V]` to the operator* phase opens. A
   question with no tag, or with more than one, does not reach an asking phase at all — it is split
   or rewritten where it stands.
2. **The phase that answers `[G]` questions raises no prompt of any kind.** It reads findings and
   writes answers. It has no `AskUserQuestion` call, no free-text prompt, and no "just to confirm"
   path, and it runs to completion before any operator prompt is opened.
3. **The operator queue is whatever the tagging phase has fixed, and nothing else ever reaches it.**
   The *Put each `[V]` to the operator* phase takes the `[V]` set that phase produced — including
   anything the `[G]` phase re-tagged into `[V]`, which re-enters at tagging and is re-tested there
   before it joins the set (property 4). What the queue is never appended to is a question that
   **has not been through the tagging phase**: no phase adds to it directly, and once this phase
   opens, nothing is added to it at all. Stating it as "the `[V]` list alone, never appended to from
   another tag" would be false — a re-tagged `[G]` is a question from another tag, and it is
   supposed to arrive — and a guarantee that is false in its own ordinary case is one nobody can
   check the interesting case against.
4. **A `[G]` leaves the `[G]` set only by re-tagging, and re-tagging re-enters at the tagging
   phase.** It never enters the operator queue directly. And a re-tag is admissible only against a
   named `NOT-PROVABLE` finding or an `unprovable` verifier outcome (`interview-tagging.md` §3):
   **a re-tag with no finding to name is not a re-tag**, so "the code did not tell us, so let us ask
   someone" has no route through this command.
5. **Every prompt this command raises is enumerated, and only one of them carries a question from
   the question set.** They are: the `SPECS_PATH` escalation in *Resolve inputs and gate the grounded
   BRD*; the round re-open cause prompt in *Resolve the round*; the `[V]` queue and the argumentation
   prompt that follows each of its answers; the code-defect offer that follows it; the will-change
   resolution picker; the handoff choice; and the next-step offer. Only the third carries a question
   from the set — and the argumentation prompt inside it asks why the answer just given was given,
   never a question of its own.

   **Two further prompts can appear, raised inside shared entry points this command executes rather
   than by the command itself, and neither can carry a question from the set** — because neither
   entry point is ever handed one: `require-on-main`'s row-C repair offer (`workflows-core:phase-handoff` §3.3),
   which asks whether to switch the specs repo to its default branch, and `emit-cost`'s pending-file
   relocation confirmation (`workflows-core:cost-emission` §9), which asks where a cost entry should land. They
   are named so that "every prompt is enumerated" stays a checkable claim rather than one that
   quietly excludes whatever a cited entry point does.

The failure all five exist to prevent is stated once, in `interview-tagging.md` §2, and is not
restated here: a `[G]` put to a person returns their belief about the system rather than the system,
and nothing downstream can tell the difference afterwards.

---

## Phase 0 — Resolve inputs and gate the grounded BRD

1. **`<BRD-KEY>` (mandatory).** Parse the first token that is neither a flag nor a flag's value — `--round` each consume the token after them (step 2), and a value skipped as "non-flag" would be read as the key; validate with `key-valid`
   (`workflows-core:addressing` §1). If absent or invalid, stop:
   `BRD_INTERVIEW_NEEDS_KEY: /brd-interview needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/product-workflows:brd-interview <KEY>'.`
2. **`--round N`.** Optional, consuming the next token, which must be a positive integer. Malformed
   or absent value → stop, rather than silently falling back to the no-flag behaviour, which would
   run a different round from the one that was asked for:
   `BRD_INTERVIEW_BAD_ROUND: --round takes a positive integer round number — re-run '/product-workflows:brd-interview <KEY> --round <N>', or omit the flag to continue at the first round still holding a question without a terminal disposition.`
   What the flag then does is the *Resolve the round* phase's business.
3. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`, per the
   `Required path environment variable unset` rule in
   `workflows-core:escalation-rules`:
   ```
   choices: ["Set SPECS_PATH (enter the path)", "Cancel"]
   ```
4. **Specs-repo preflight.** Invoke `Skill(skill: "workflows-core:reference", args: "specs-repo-git specs-preflight")` and execute its `specs-preflight` entry point (§3) inline, **before** the gate below — `require-on-main`
   performs no fetch of its own (`workflows-core:phase-handoff` §3.2) and relies on this step's best-effort one,
   the same ordering `/prd-ground` uses and for the same reason. Prompt-free and silent when the
   specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
   `specs_git: blocked` (§3.3 G0), carry that flag for the whole run.
5. **Resolve the BRD folder.** `resolve-address <BRD-KEY>` (`Skill(skill: "workflows-core:reference", args: "addressing resolve-address")`, §3), which searches
   `specifications/` and the levels below it that `resolve-address` searches (three, per `workflows-core:addressing` §3) — either level a `<BRD-KEY>` can name — a BRD folder directly under `specifications/`, or the `PRD-` folder of a slice inside it. Absent
   → stop, without asserting which command would have created it, because nothing on disk says
   whether this key names a BRD with a source document or a slice of one:
   `BRD_INTERVIEW_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /product-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /product-workflows:brd-split on its parent.`
5a. **The root refusal — deciding happens at the slice and nowhere else.** Take this the moment
    step 5 returns a resolved folder, before step 6 opens anything — the level question is answered
    before any gate that follows it. Test the **resolved directory's prefix**: `BRD-` is a root,
    `PRD-` is a slice — the kind-prefix convention `workflows-core:addressing` §2 fixes, read off
    the resolved folder's own name. **Never test the folder's asserted `kind:`** — `/brd-split`
    writes `kind: brd` into the `brd-link.md` it places inside the `PRD-` slice folder it carves
    (`commands/brd-split.md` Phase 3), so a slice **asserts** `brd` while being exactly the folder
    this refusal must accept; a gate on the asserted kind would refuse every slice and accept
    nothing.

    **Where the folder resolved through `workflows-core:addressing` §5's legacy unprefixed
    fallback, there is no prefix to test.** Answer the root question by **positive evidence, never
    by the absence of a file** — `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5.1,
    the shared authority every consumer of this test takes it from, and not restated here.

    On a root, look for the root-level artifacts this run would have produced under the retired
    two-level model — `decisions.md`, `interview/` — and name whichever exist in the stop, so an
    operator whose BRD was interviewed under that model is told the level moved rather than that
    their key is wrong. Never delete them; they record work done, and nothing in this run reads
    them.

    Stop:
    `BRD_INTERVIEW_ROOT_LEVEL: <BRD-KEY> is a root BRD, and deciding happens at the slice. Carve one with '/product-workflows:brd-split <BRD-KEY> "<how to cut it>"', then run '/product-workflows:brd-interview <SLICE-KEY>'.<where root-level artifacts exist, append:> This BRD carries root-level decisions and interview records at <paths> from the earlier two-level model; it is left in place and nothing reads it.`
6. **Gate the grounding deliverable on main.** This command **consumes** a `$SPECS_PATH` deliverable
   it did not write, so per `workflows-core:phase-handoff` §5 rule 2 it executes
   `require-on-main` (§3) here, before anything else reads a file. Execute it against the resolved
   folder's `grounding/code-grounding.md` — the same file `/brd-split` gates, and for the same reason:
   every deliverable one `handoff-to-main` run stages lands in a single commit (§2.3), so its presence
   on `origin/<default>` implies `grounding/design-grounding.md` and `brd-link.md` merged with it — **That implication holds for a full `/prd-ground` run and not for a `--no-code` one**, whose `deliverable_paths` is `grounding/design-grounding.md` alone and lands in its own later commit — so a BRD can legitimately have `code-grounding.md` merged and `design-grounding.md` on no ref at all. Anything reading the design findings gates them separately rather than inheriting this sentence. And
   `/prd-ground`'s own gate on `coverage-ledger.md` had already run before those findings existed at
   all. Map the §3.7 return by `stopped` first: any stopping row → stop, naming the concrete branch/PR
   state it reports; `pass` → proceed; `pass_amending` → proceed, printing the §3.3 row-B message;
   `unmanaged` → proceed as before this feature; `absent` (row F — grounding findings are on no ref at
   all) → **split it before stopping, on a test row F cannot make**, the way `/brd-reconcile` splits
   its own row F. Row F covers two states here, and the message for the second one must not name a
   command that stops on the same emptiness. Read `<BRD-dir>/brd/brd-inventory.md` from the worktree
   and count its `[BR#n]` rows:
   - **One or more rows** — grounding simply has not run yet, and running it is the fix:
     `BRD_INTERVIEW_NEEDS_GROUNDING: no grounding findings on file for <BRD-KEY> — run /product-workflows:prd-ground <BRD-KEY> first.`
   - **Zero rows** — there is nothing to ground, so `/prd-ground` stops with
     `PRD_GROUND_EMPTY_INVENTORY` rather than producing the findings this gate wants, and naming it
     here would be the loop. The fix is upstream, so read the resolved folder's `brd-link.md` and
     branch on its `parent:` field: this read is a bare worktree read with no gate ahead of it, and
     an absent `brd/brd-inventory.md` counts as zero rows here just as a present-but-empty one
     does — 5a's own legacy-fallback test lets a folder carrying **neither**
     `coverage-ledger.md` **nor** `brd/brd-inventory.md` through unrefused
     (`coverage-ledger-format.md` §5.1), so a folder reaching this branch is not always the slice
     step 5a would otherwise guarantee — it may be a legacy root BRD whose intake was interrupted
     before the inventory was ever written:
     - **No `brd-link.md`, or one with no `parent:`** —
       `BRD_INTERVIEW_EMPTY_INVENTORY: <BRD-KEY>'s inventory holds no [BR#n] row, so there is nothing to ground and no question this command could ask about it — do not run /product-workflows:prd-ground, which stops on the same emptiness. Re-run '/product-workflows:brd-intake <BRD-KEY> @<brd-file>' over this same folder with a source whose requirements brd-reader can identify, and merge that pull request; if the source genuinely states no requirement, this BRD has nothing for the route to carry.`
     - **`parent: <PARENT-KEY>` present** — this is a slice:
       `BRD_INTERVIEW_EMPTY_INVENTORY: <BRD-KEY> is a slice of <PARENT-KEY> and its inventory holds no [BR#n] row — it claims nothing, so there is nothing to ground and nothing to decide. Do not run /product-workflows:prd-ground, and do not run /product-workflows:brd-intake on a slice; it has no source document of its own. Re-run /product-workflows:brd-split on <PARENT-KEY>: either way it resolves every standing empty child, so it will offer to remove this slice or to keep it against its recorded reason. Which form to type depends on that parent's own ledger. Where it still holds an unallocated row, the run walks it too and will offer covered-by against this slice — and a run with rows still to place needs a slicing instruction to group them, so type '/product-workflows:brd-split <PARENT-KEY> "<how to cut it>"'. Where no row is left unallocated, the bare '/product-workflows:brd-split <PARENT-KEY>' is the run, and removing this slice or keeping it against a recorded reason is the whole of what it offers here. Adding an instruction to that same run, '/product-workflows:brd-split <PARENT-KEY> "<what to peel off>"', can additionally re-cut onto this slice a row the parent delegated to a sibling that has since recorded it will not build it — the one case in which /brd-split re-allocates a row already carrying a fate, and the only third thing that can change this slice's state. That third one is not guaranteed to be on offer: it needs such a row to exist, and it needs this slice never to have been interviewed, so a slice emptied after its own interview can only be removed or kept.`
7. **Gate on verification — and on there being grounding to verify.** Three tests, in this order,
   because **the second is a count and a count is vacuously satisfied by an empty set**. This gate
   shipped as the count alone, exactly as `/brd-split`'s did: zero findings on file means zero
   findings missing an outcome, so a BRD with no grounding at all passed it. **It matters more here
   than there**, by this step's own reasoning below: with zero findings the run answers every `[G]`
   from an empty evidence set and freezes `[VD#n]` against nothing, which is strictly worse than the
   unverified case the count does catch. And the state is reachable without anyone being careless —
   a slice whose ledger rows the parent's `/brd-split` set to `covered-here` passes step 8 without
   `/brd-split` ever having run **on the slice**, so the slice never meets that command's own
   presence relations.

   a. **There is code grounding.** Read `<BRD-dir>/grounding/code-grounding.md` from the worktree —
      step 6 already proved it is on `origin/<default>` — and count its `[CG#n]` blocks, parsed per
      `workflows-core:grounding-format` §2.1. Zero → stop. Step 6's row-F branch catches the file
      being on no ref; nothing until now caught it being on main and holding nothing:
      `BRD_INTERVIEW_NO_FINDINGS: <BRD-KEY>'s grounding/code-grounding.md is on main but records no [CG#n] finding — re-run '/product-workflows:prd-ground <BRD-KEY>' and merge its handoff before interviewing. Every [G] is answered from the findings and from nothing else.`
   b. **Every finding carries a verifier outcome.** Read every `[CG#n]` and `[DG#n]` on file and
      count those carrying no recorded verifier `outcome` (one of the four in
      `workflows-core:grounding-format` §8). Any count `N` greater than zero →
      stop: `BRD_INTERVIEW_UNVERIFIED: N findings have no verifier verdict — run /product-workflows:prd-ground first.`
   c. **No finding block carries a field the record's format does not define.** Parse every
      `[CG#n]`/`[DG#n]` block per `workflows-core:grounding-format` §2.1 and test each key against
      that section's **closed** field set — §2's fields, plus `outcome` and `notes`. Any other key
      fails. The test is derived from that section, never from a list here, which is what admits a
      field §2 gains — `control` (§2.2) is one — without this gate being touched. **The keys that
      actually occur are the verifier's own return fields**, and `own_verdict` above all: transcribed
      into the record it leaves the block stating two verdicts at once. `control_outcome` is the same
      mistake with a different consequence — it is one verifier's judgement about whether that
      finding's control fired, so a block carrying it asserts as a property of the finding something
      only a re-derivation establishes. **Test b. cannot see** either: the block carries an `outcome`, so it passes on presence. This gate matters more here
      than anywhere else on the route — every `[G]` question is answered from the findings and from
      nothing else, so a finding with two verdicts is a `[VD#n]` frozen against whichever half the
      run happened to read, and `/brd-package` puts that decision in front of the customer.
      stop: `BRD_INTERVIEW_MALFORMED_FINDING: N finding blocks carry a key workflows-core:grounding-format §2.1 does not define (<finding-id>: <key>, …) — the record's field set is closed to §2's fields plus outcome and notes. A block carrying own_verdict beside verdict states two verdicts at once, and every [G] answered from it is answered from whichever half was read. Remove the offending key from each block by hand in <path>, leaving every other key untouched, and re-run. Do not re-run '/product-workflows:prd-ground <BRD-KEY> --rebaseline' for this: it re-derives every finding against current commits to delete a line no command should have written.`

   **No design-presence relation here, and that is deliberate rather than an omission.**
   `/brd-split`'s third test exists because allocating a requirement to a slice that will be built
   commits to a design nobody reconciled. This command answers questions from findings; a frame set
   with no `[DG#n]` yields no `[G]` to answer wrongly, and `/brd-split` gates the same BRD before any
   slice reaches build. Adding it here would refuse an interview that is not the thing at risk.

   This gate is not borrowed ceremony. A finding without an outcome "is not evidence"
   (`workflows-core:grounding-format` §8), and a decision's `evidence` list is a list of findings
   (`${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1) — so a `[G]` answered from an
   unverified finding, or a `[VD#n]` resting on one, would put an unchecked claim behind a recorded
   decision, which is worse than an open question.
8. **Gate on allocation.** Read `<BRD-dir>/coverage-ledger.md` and count the rows whose
   `disposition` is `unallocated` **as written on this ledger**. Any such row → stop:
   `BRD_INTERVIEW_UNALLOCATED: N coverage-ledger rows are still unallocated for <BRD-KEY> — run /product-workflows:brd-split <BRD-KEY> first.`
   Interviewing a BRD whose requirements have no recorded fate would take positions on requirements
   nobody has yet decided this BRD is building.

   **Read the dispositions in the file; never the ledger line.** The line's `unallocated` term is a
   *resolved* count that follows every `covered-by` row one hop into the BRD it names, so a
   fully-allocated parent routinely reports a non-zero term for rows a child has not walked yet
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6.1, which states outright that a
   consumer testing the gate reads the dispositions and never the line). Gating on the line would
   refuse to interview a BRD that is completely allocated, for work that belongs to a different BRD's
   walk.
9. **Read the inputs the rest of the run works from**, from the gated folder: every verified
   `[CG#n]`/`[DG#n]` with its `verdict`, `evidence`, `control` where it carries one, `horizon` and
   verifier `outcome` (`workflows-core:grounding-format` §2, §2.2, §3, §5); `brd/brd-inventory.md`'s `[BR#n]` rows; `coverage-ledger.md`;
   `brd-link.md` (its `parent:` and any `depends-on:`); and, when they already exist, `decisions.md`,
   every `interview/round-<N>.md`, and `code-defect-log.md`. **Three more come from the parent's
   folder, one hop** (`brd-format.md` §2.1, §4), because the requirement-defect question source
   (*Round 1 is generated from the grounding*) reads them: `brd/brd-defect-log.md`,
   `brd/brd-inventory.md` and `coverage-ledger.md` — and, from there, the `coverage-ledger.md` of each
   sibling slice that ledger records `covered-by` against a row an open requirement defect lists,
   which is how that source tells a live row from a settled one, and the
   `interview/customer-questions.md` of every slice under the parent (the positive `brd-link.md`
   parent test, `commands/brd-split.md` Phase 0), which is how it tells a defect already asked from
   one that is not — an absent one holds no entry. A previous run's register, round records and
   code-defect log are inputs, never scratch: nothing below deletes, renumbers or rewrites a record
   another run wrote. **Exactly one field is the admitted exception, and naming it
   here is what keeps this sentence and the re-disposition rule below from having to be refereed by a
   reader**: a `[CDF#n]`'s `disposition` — with `blocked_on` added or dropped as the new disposition
   requires — may be re-taken by the *Put each `[V]` to the operator* phase and written by the *Write
   the register and the round record* phase, because `open` and `conditional` are holding states that
   would otherwise have no exit at all. Nothing else on that record moves, and no other record here
   carries an exception. **An addition is not a rewrite, and one is made to another run's entry**:
   the `- **Requirement defect:**` line *Resolve the round* appends to a held `[C]` entry in
   `interview/customer-questions.md` (*One question per row*), which changes nothing already written
   in it.

---

## Phase 1 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "workflows-core:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # SIGNIFICANT for an unusually large question set, a first round
                                  # over a long inventory, or a re-open that reopens decisions
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # impl-maintenance only — no other agent runs in this command
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`/brd-interview` dispatches no grounding or review agent of its own — every finding it reads was
already independently re-derived by `/prd-ground`'s `grounding-verifier` pass, and re-deriving it
here would be a second unverified opinion, not a second check. `detection_model` therefore exists
only for the terminal `impl-maintenance` dispatch. If no Opus resolves for `current_model`, degrade
to best-available, record it in `notes` and in the final report, and never hard-block.

---

## Phase 2 — Resolve the round

Rounds are numbered, permanent, contiguous, and resumable, and every decision records the round that
produced it (`interview-tagging.md` §5). This phase decides which round this run is working, and it
is the only phase that may create or re-open one.

Read every `interview/round-<N>.md` already on file.

### Terminal dispositions and holding states — the vocabulary every closure and resume rule uses

`interview-tagging.md` §5 is explicit that a disposition is **what happened to the question**, not
merely that somebody looked at it, and it names them: answered from findings (`[G]`), decided by the
delivery team with argumentation (`[V]`), answered by the customer through the review package
(`[C]`), re-tagged under §3, or split under §4. **Those five are terminal**, and this command calls
them **terminal dispositions**:

| Terminal disposition | Reached when |
|---|---|
| *answered from findings* | a verified finding settled a `[G]` |
| *decided* | a `[V]` produced a `[VD#n]` with its argumentation |
| *answered by the customer* | a `[C]`'s answer came back and an operator confirmed it (D14) |
| *re-tagged* | a `[G]` grounding could not settle changed tag, naming its cause; the re-tagged question then carries its own disposition |
| *split* | the question became parts, named; the parts carry their own dispositions |

**Everything else this command records against a question is a holding state, never a disposition**,
and a holding state keeps the round open:

| Holding state | Meaning |
|---|---|
| *held for the customer* | a `[C]` is written and waiting; **holding it is not the customer answering it** |
| *deferred* | recorded as not answerable yet, with why; it stays in this round and is returned to |
| *needs grounding* | no finding bears on a `[G]` yet; only a `/prd-ground` run can move it |
| *untagged* | the §2 test could not resolve it into exactly one tag; what is wrong with it is recorded and it is rewritten before it is asked |

**Why the distinction is load-bearing rather than tidy.** Both rules that read a question's state —
this phase's resume rule and the *Write the register and the round record* phase's closure rule —
are stated in this one vocabulary, so they cannot drift apart. Were a holding state counted as a
disposition, a round whose remainder sat in any holding state — *deferred* or *needs grounding*,
say — would close, and the resume rule would then skip past the very question this run promised to
return to. §5 sides with the
holding states: *"A round with an outstanding `[C]` stays open until that answer comes back through
the package — the customer's turnaround is not a reason to declare the round finished around them."*

A round is **open** while any question in it lacks a **terminal** disposition, and **closed** once
every one has one.

**No `--round` flag:**

- **Some round is open** → work the lowest-numbered open round. Resume at its first question
  carrying **no terminal disposition** — which is exactly the question a holding state is holding —
  do not restart the round, and do not re-ask a question that already carries a terminal
  disposition. Re-asking a `[C]` is the case §5 singles out, and the register is the reason: two customer answers to one
  question is a contradiction one `[CD#n]` record has no way to hold.
- **No round record exists at all** → **generate round 1's questions first, then decide.** The change
  test below does not apply here: it reads "since the last round closed", and no round has closed, so
  it has no referent. Run *Round 1 is generated from the grounding* (below) and branch on what it
  produced:
  - **At least one question** → open round 1 and work it, exactly as ever.
  - **No question at all** — no finding whose verdict leaves the premise open (the first two
    sources: a premise that moved, and one the repository could not settle), no `will-change`
    horizon, no `[DG#n]` divergence, no `rejected` row not already settled, no `deferred-to` row
    whose consequence is unstated, no open requirement defect this BRD asks, and nothing the
    package must assert without evidence.
    **The test is the generation's own output, never a gloss on the verdicts**: `SUPERSEDED` raises
    no question and is neither `CONFIRMED` nor a reason to ask one, so a rule phrased over verdicts
    and a rule phrased over questions would disagree on a re-grounded corpus. Zero questions is the
    branch key. →
    **First run the in-scope scoping the generation depends on**, and where it empties the set take
    `BRD_INTERVIEW_ALL_DELEGATED` and stop: a BRD that kept none of its requirements has nothing of
    its own to decide, that stop forbids a round record outright, and it is reached *instead of* this
    branch rather than after it. Otherwise → **write `interview/round-1.md` recording the walk and
    what it found nothing of, and close the round in the same write** — it holds no question, so
    there is none to leave hanging, and a round left open would trap every later run on the resume
    rule and make the change test unreachable forever. Then carry on through the rest of the run —
    the register phase (which writes no record — no `[VD#n]`, no `[AS#n]`, no `[C]` — and so writes
    the register's header alone where none is on file), the handoff, and the next-step offer. **This
    is a completed run, not a stop**: it produced a deliverable, so it stages and hands off like any
    other, and the offer it ends on is whichever *Next steps* selects from the `/brd-package` gates
    it checks — step 6's register, which this path has just written, and steps 7 and 8. With an open
    `[AS#n]` on file the packaging step is offered; with an empty register the run reports the BRD
    decided. The round record this path writes is also what step 8's interview test reads, so
    `BRD_PACKAGE_NOT_INTERVIEWED` bears on neither.

  **That record is not the empty round record the all-delegated stop forbids, and the difference is
  the whole of why one is written here and not there.** That rule refuses a record that *"would sit
  on file forever recording that nothing was asked, which reads indistinguishably from a round nobody
  finished"* — and it is right, about an **empty** file. This record is not empty: it names each of
  the seven question sources and states what the walk found under it, so a reader meets an account of a
  completed walk rather than a silence they have to interpret. The two also never compete, and the branch above is
  what makes that true rather than an assertion resting on it: the scoping check runs **first**, so
  an all-delegated BRD takes its own stop and never reaches the write.

  **Why the record is written rather than the run simply reporting and exiting.** The operator cannot
  know whether this BRD has anything to ask until this command has run, so the run is the discovery
  step and its result is worth keeping. It is also what `/product-workflows:brd-package` reads: that
  command refuses a BRD with no round record, and it must not re-derive the seven sources above to
  decide whether the refusal is fair — a second copy of this rule in another command is how the two
  drift apart, and the first question source added to one and not the other ships a package over a
  question nobody walked. It tests for the record; this branch is what makes an honest one exist.
- **Every round is closed** → a new round is proposed **only if findings or decisions have changed,
  or a requirement defect became this BRD's to ask, since the last round closed**. Concretely: a
  `[CG#n]`/`[DG#n]` added or superseded since that round's record was written, a verifier outcome
  changed, or a decision in `decisions.md` moved to `reopened` or `superseded` — or a requirement
  defect this BRD owns, that is open and that is not asked (*Round 1 is generated from the
  grounding* fixes all three tests), where round 1's record carries the requirement-defect account
  line: the round-1 walk did not raise it, and a new round is exactly where it belongs (the round-1
  test below). Nothing changed → there is nothing a new round could ask that the last one did not
  already have in front of it; report that plainly, run the round-1 test below — every round being
  closed, all it can do here is report — and, **where no `decisions.md` is on file, write it as its
  header line alone** (*Write the register and the round record*): a BRD interviewed before this
  command wrote the register on every round, over rounds that recorded no decision, holds none, and
  `/product-workflows:brd-package` refuses the folder without one. Then skip to the handoff phase —
  with nothing to commit where the register was already on file, and with `decisions.md` alone where
  this path wrote it — and end on the ledger line. Something changed → open round `<highest + 1>`
  (round 1 when none exists), naming in its record exactly what changed and made it askable.

**`--round N` given:**

- **Round `N` is open** → resume it, exactly as the no-flag path resumes it. The flag is not needed
  for this case; it is honoured for it so that naming a round is never a way to accidentally do
  something else.
- **Round `N` is closed** → **re-open it, and record the re-open with its cause.** Prompt for the
  cause and refuse to proceed without one. This is the same rule that governs reopening a decision
  (`decision-register-format.md` §4): a re-open whose cause is unnamed is indistinguishable from
  somebody changing their mind, and once one of those exists nobody can trust that the rest were
  caused either. Append the re-open to `interview/round-<N>.md` — never overwrite the record of what
  the round originally asked and how it was disposed of. Any decision this re-opened round then
  changes is itself reopened under §4, against one of the two causes that rule admits, and never
  merely because this round is open again.
  **The cause *requirement defects became a question source* is admissible on round 1 only, and
  only while round 1's record carries no account line** — once it carries one, a defect this source
  would raise belongs in a new round (the round-1 test below), so refuse that cause at the prompt
  and name the bare `/product-workflows:brd-interview <BRD-KEY>`. The re-open raises nothing itself:
  round 1 is open once it is taken, and the round-1 test below appends a question to round 1 for
  each requirement defect this BRD owns, that is open and that is **not asked** — one any slice has
  asked is never raised again, because two customer answers to one question is the contradiction §5
  exists to prevent — and writes round 1's account line. On an open round 1 no re-open is needed:
  the same test appends them as the run resumes it.
- **Round `N` does not exist** → stop rather than creating it out of order, which would break the
  contiguity §5 depends on:
  `BRD_INTERVIEW_NO_SUCH_ROUND: <BRD-KEY> has no round N — rounds on file: <list, or "none">. Omit --round to continue at the first round still holding a question without a terminal disposition.`
  The one exception: `N` is exactly `<highest + 1>` (or `1` when none exists), which is a request to
  open the next round, and takes **whichever branch the no-flag path would take for that same
  request** — the change test where rounds are on file, and the generate-then-branch rule where none
  is, including its nothing-askable outcome. The two branches of *Resolve the round* differ, and a
  flag must not reach a different answer than the bare command would. Naming a round is never a way
  to accidentally do something else, and that cuts both ways: it must also never be a way to
  accidentally do *less*.

**Then the round-1 test, on every run, whichever branch above resolved the round and with or
without `--round`.** No branch skips it: one that sends the run on to the handoff phase runs this
test first. Read round 1's record for the requirement-defect account line (*Write the
register and the round record*). **That line alone decides which round a requirement defect this BRD
owns, that is open and that is not asked belongs in**; nothing else decides it:

- **No round record exists** → round 1 is being generated now, from every source, so each such
  defect is raised in it and its record carries the line.
- **Round 1's record carries the line** → round 1's walk ran this source, so each such defect was not
  in front of it: confirmed since, by an intake re-run over a revised source, or withheld then and
  this BRD's to ask since. It belongs in a **new round**, and it is one of the changes that make one
  askable (the *Every round is closed* bullet above). While some round is still open it waits, as a
  changed finding does — **and it is reported, never silent**: name each waiting `[DEF#n]`, *asked
  in round `<highest + 1>`, once round `<open>` closes*, in the final report and beside the *Next
  steps* list, and withhold it in this run's account line with the cause `waits — round <open>
  still open`, since a package built meanwhile goes out without it.
- **Round 1's record carries no line** → this slice was interviewed before the requirement-defect
  source existed, so every such defect belongs in **round 1** — a question round 1 could have asked
  stays in round 1, never in a new round (*Generate the round's question set*: a later round holds
  only what became askable once the previous round was answered):
  - **Round 1 is open** → no re-open is needed. Where this run works round 1 — the bare path always
    does, round 1 being the lowest-numbered open round, and so does a run that has just re-opened
    it — append a question for each to round 1 now, numbered after its last question and never
    renumbering one, and write round 1's account line when its record is written. A `--round N` run
    working another open round leaves them for the next run that works round 1.
  - **Round 1 is closed** → open no round for them. Report each `[DEF#n]` and name the re-open that
    asks them: `/product-workflows:brd-interview <BRD-KEY> --round 1`, with the cause *requirement
    defects became a question source*. A round this run opens or resumes for any other cause
    proceeds without them, and the *Next steps* phase offers the re-open.

**One question per row, whichever branch above places the defect.** A defect this BRD owns as its
carrier (*Round 1 is generated from the grounding*) is asked on its rejected row's question, never
beside it. So where some round already holds that row's question — the
`interview/customer-questions.md` entry whose `- **Rejected row:**` line names it, or, on an entry
written before 3.7.0, which carries no such line, the one held entry whose question names that row's
`[BR#n]` and asks about its rejection — and that question is still *held for the customer*, the
defect is asked by **appending its `- **Requirement defect:** [DEF#n]` line to that entry**, not by
a question of its own. The question text is not rewritten; the line is an addition, and it is what
makes the defect **asked** and lets `/brd-reconcile` settle it from the answer. The run that works
the round holding the entry makes the addition and records the defect asked in that round's account
line; a run working another round leaves it for that one, and reports it as waiting on that round.
Where no held entry is the row's — none names it, more than one could be it, or its question was
already answered — a question is raised in the round the branches above place it in, and the final
report names any candidates it could not choose between. **An earlier answer does not settle it**:
`/brd-reconcile` copies `settles` from the entry's labelled line when it freezes the answer, and an
answer frozen before the line existed carried none, so the defect is asked anew — its question
states what the defect records and names that earlier `[CD#n]` as context, so the customer sees what
they already said about the row.

Carry the resolved round number for the whole run. Every decision, assumption and question this run
records is stamped with it.

---

## Phase 3 — Generate the round's question set

Write the round's questions **before tagging any of them**, so the set is generated by what the BRD
needs settled rather than by what would be convenient to route.

**Where *Resolve the round* has already generated round 1, this phase works that set and generates
nothing again.** That phase's no-round-record branch runs the scoping below and *Round 1 is
generated from the grounding* to learn whether there is a round to open at all, so both have run
once already, and a second pass would write a second copy of the same questions. Everything else
this phase fixes — how a question is numbered and addressed, and which round a question belongs in —
binds that set exactly as it binds one generated here.

**Scope the set to the rows this BRD is answerable for, before generating anything.** Read
`<BRD-dir>/coverage-ledger.md` and take the rows whose `disposition` is `covered-here`,
`deferred-to`, `rejected` or `superseded-by`. **A row `covered-by: <OTHER-KEY>` is out of scope as a
subject**: §3 of `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` says that BRD *owns*
the requirement, and §3.1 there is the authority for what that means here — the owning BRD's own
round asks about it, and a question raised at both levels reaches the customer twice, which
`${CLAUDE_PLUGIN_ROOT}/references/interview-tagging.md` §5 names as an invitation to two
contradictory answers one `[CD#n]` cannot hold.

**Read the `disposition` column, not the inventory and not `claims:`.** This slice's own inventory
already excludes every orphan row `/brd-split`'s parent walk withdrew — the `claims:` entry and the
copied inventory row are withdrawn together (`coverage-ledger-format.md` §2) — so reading the
`disposition` column is what keeps that true rather than assuming it: a stale inventory or a
`claims:` list edited out of step with the ledger would otherwise put a withdrawn row back in scope.
Report the scope in the
round record and the final report — how many rows this round covers and how many were left to the
BRDs that own them, named — so a short round reads as scoped rather than as thin.

**A delegated row is still readable as context.** What this BRD keeps may turn on what it gave away,
and a question about a `covered-here` row may cite a delegated one to make sense. What is forbidden
is the delegated row being the thing asked about; the test is whose answer would settle it.

**An empty in-scope set is a finished state, and scoping is what makes it reachable.** A BRD whose
every ledger row reads `covered-by` — one that delegated all of its requirements to children and kept
none — has nothing of its own to decide, and this is the state that gate could not see before, since
its inventory is not empty and the *Resolve inputs and gate the grounded BRD* phase's
`BRD_INTERVIEW_EMPTY_INVENTORY` therefore never fires on it. Do not open a round for it and do not
write an empty round record: a round record is append-only and permanent (`interview-tagging.md` §5),
and an empty one would sit on file forever recording that nothing was asked, which reads
indistinguishably from a round nobody finished. Report it and stop gracefully:
`BRD_INTERVIEW_ALL_DELEGATED: every row of <BRD-KEY>'s coverage-ledger.md is covered-by another BRD, so this BRD is answerable for no requirement and has nothing to decide — its questions belong to <the named BRDs>, and each is interviewed on its own key. This is a finished state, not a missing step: a BRD that kept nothing also holds no PRD of its own (coverage-ledger-format.md §5). If that is not what was intended, re-running the bare '/product-workflows:brd-split <BRD-KEY>' moves nothing: it walks only unallocated rows, and this ledger has none. Adding an instruction, '/product-workflows:brd-split <BRD-KEY> "<what to peel off>"', can re-point a delegated row onto another child of <BRD-KEY> that has not been interviewed — one already standing, or a slice that same run carves for it — but only where the child now holding it has recorded deferred-to against it in its own ledger, which is that child writing down that it will not build it. A row its holder is still committed to is moved by no command: un-delegating that one is a decision taken with the customer.`
This stop is an allocation outcome, never a plugin gap, so it does not fire `emit-block`.

**Round 1 is generated from the grounding.** Work the verified findings and the in-scope rows
together — and, for requirement defects, the parent's defect log, inventory and ledger and the
sibling slices' ledgers and question sets that decide who asks one (*Resolve inputs and gate the
grounded BRD*, step 9) — and raise a question wherever they leave something unsettled that a PRD
would have to state:

- a `[BR#n]` whose findings are `AMENDED`, `REWRITTEN` or `FALSE-FRIEND` — the premise moved, so what
  the requirement now asks for is open (`workflows-core:grounding-format` §3);
- a `[BR#n]` whose findings are `NOT-PROVABLE` — the repository could not settle it, and somebody
  must now choose;
- a finding carrying `horizon: will-change` — what this BRD does while the naming prerequisite
  decision is unbuilt is open by construction (`workflows-core:grounding-format` §5);
- a `[DG#n]` reconciliation the design and the requirement disagree about (§6's classes);
- an in-scope ledger row resolved `rejected`, unless its rejection is already settled. **Nothing on
  the route records why a row was rejected** — `/brd-split` collects a rationale for a `deferred-to`
  row only, into `slices.md` (its Phase 5) — so a rejection's consequence for the rest of the BRD is
  unstated by construction, and whether the customer accepts not getting what they asked for is
  theirs to say: the question is `[C]` (`interview-tagging.md` §1). A `rejected` row is **already
  settled**, and raises nothing, where it reads `rejected: <SLICE-KEY>/[CD#n]` — the customer's own
  decision withdrew it (`coverage-ledger-format.md` §3) — or where the `[DEF#n]` it cites is no
  longer `open` in the log, is **asked** (the next bullet's test), or is another slice's to ask: that
  slice owns it and the next bullet raises it there, naming this row as context, or it is the
  defect's carrier, below. **A row `rejected: [DEF#n]` carries that defect** on its question's
  `- **Requirement defect:**` line (*Hold every `[C]`*) where this BRD is the defect's **carrier**:
  no row the defect lists is live (the next bullet's test), and of the listed rows a slice records
  `rejected` citing it, this BRD holds the lowest-numbered — which makes this BRD its owner. The
  question then states what the defect records, exactly as the next bullet's question does, counts
  as asking it, and `/brd-reconcile` settles it, `resolved-by: <SLICE-KEY>/[CD#n]`, on the
  customer's answer. One question, never two: the next bullet raises no second one for a defect this
  row carries. Where the next bullet's undecidable states hold, the row is withheld with its defect,
  for the reason that bullet gives. **A `deferred-to` row raises no question where its consequence
  is stated** — in the `slices.md` block `/brd-split` writes for each row it defers, or in the
  `[CD#n]` whose customer deferred it; one carrying neither raises a question, tagged by the *Tag
  every question* phase's test like any other;
- an **open requirement defect** — a `[DEF#n]` in `brd/brd-defect-log.md` (the parent's on a slice,
  one hop — `brd-format.md` §4) whose resolution is `open` and whose class grounding cannot settle:
  `ambiguity`, `conflict`, `duplicate`, `untestable` or `scope-leak`. `unsourced` is not in the
  list: grounding settles it, and a finding that could not is already a question under the
  `NOT-PROVABLE` bullet above. **Which BRD asks is read off the inventory and the ledgers, never off
  the log**, whose entry does not say which rows list it: the defect's rows are the rows whose
  `defects` column lists it in the log-owning BRD's inventory (the parent's, on a slice).
  **Ownership is decided over the live ones only.** A listed row is **live** where the parent's
  `coverage-ledger.md` records it `covered-by` a slice and that slice records it `covered-here` or
  `deferred-to` in its own ledger — read one hop, from each such slice under the same parent, this
  one included. The defect is **owned** by the slice holding the **lowest-numbered live row**. A row
  the parent never delegated (no `covered-by`), or whose owning slice records it `rejected` or
  `superseded-by`, is not live. **Where no listed row is live, the defect's carrier owns it** — the
  slice holding the lowest-numbered listed row it records `rejected: [DEF#n]` citing this defect —
  and asks it on that row's question (the bullet above), carrying it on the labelled line; this
  bullet raises no second question for it, in whichever round it is asked. Where there is no carrier
  either — every listed row `superseded-by`, never delegated, or rejected citing something else —
  nobody owns it, because the rows' fates have settled it, and the account line withholds it as
  `no live row`, naming each listed row and its disposition. **This BRD raises the defect only where
  it owns it, it is open, and it is not asked.** A `[DEF#n]` is **asked** exactly where some slice
  under the same parent — found by the positive `brd-link.md` parent test (`commands/brd-split.md`
  Phase 0), this one included — has an `interview/customer-questions.md` entry whose
  `- **Requirement defect:**` line carries it, the line the *Hold every `[C]`* phase writes or *One
  question per row* appends, and no other mention in the entry. That is a structured fact read
  across the slices, never a search of round records for the id, so a defect asked once is never
  asked again, whichever slice asked it and whoever owns it now. **Three states make the answer
  undecidable, and each withholds the defect**: a listed row still `unallocated` — in the parent's
  ledger, or in the ledger of the slice the parent names — which may become live later and take it;
  a sibling ledger that cannot be read; and a sibling `customer-questions.md` that exists and cannot
  be read — an absent one holds no entry. This BRD raises nothing about such a defect and reports it
  with the row or the sibling named — never a guess, because a guess asks the customer twice or not
  at all. **Which round a raised defect goes into is *Resolve the round*'s to decide**, by round 1's
  account line alone. Every other row the defect lists, and every counterpart a `conflict` or
  `duplicate` names, is context for the question. **The question states what the defect records** —
  the two readings, the two requirements that cannot both hold, the missing observable outcome —
  and, where the row is drawn from an image (`brd-format.md` §2), names the image's path, which the
  customer holds in the bundle. **It cites a passage of the customer's by its captured path and
  locator** — `source/<basename> › § 4.2`, never a bare `§ 4.2`, which `/brd-package`'s plugin-free
  scan stops on and whose path form `${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md`
  §6.3 rule 1 exempts. It is `[C]` (`interview-tagging.md` §1);
- anything the package will have to **assert without evidence** — that is not a question at all but
  an `[AS#n]`, and the *Write the register and the round record* phase records it as one
  (`decision-register-format.md` §7).

**A later round holds only what became askable once the previous round was answered.** A question
that could have been asked in round 1 and was not is not "moved" to round 2; it stays in round 1,
carrying a holding state, and the resumption in *Resolve the round* is what returns to it. This
matters for the record: a decision from round 1 was taken without anything round 2 discovered, and
saying so later requires the round number to still mean what it says (§5).

**Questions carry no minted identifier.** The workflow's identifier namespaces are fixed (D21) and
none of them denotes a question, so nothing here invents a `[Q#n]`-style prefix. A question is
addressed by its round and its position in that round's record — questions are numbered in the order
they were written and **never renumbered**, and a split question keeps its number while its parts are
lettered beneath it (`5a`, `5b`, `5c`). Its durable handle, once it produces one, is the
`[VD#n]`, `[CD#n]` or `[AS#n]` it becomes.

---

## Phase 4 — Tag every question, before anything is asked

**Tag the entire round's set. Nothing below this line asks anybody anything until this phase has
finished.**

Apply the test in `interview-tagging.md` §2 — *what kind of thing would settle it* — to each
question in turn, and record the tag on the question in the round record. Three outcomes, and only
three:

- **Exactly one tag** → the question is ready. It joins that tag's set.
- **More than one tag** → **a defect in the question, not a gap in the taxonomy** (§4). Split it
  until each part carries exactly one tag, record the original's disposition as *split* naming the
  parts it became (§5), and put the parts through this same phase. The worked split is in §4 and is
  not reproduced here. Note the ordering that section fixes: the `[G]` part is answered first,
  because its answer routinely changes what the `[C]` part should ask.
- **No tag anybody can defend** → the question is **under-specified, not untaggable** (§4). Rewrite
  it until the test has something to bite on. It is not filed with a guessed tag in the meantime,
  and it is not asked while it carries one: guessing a tag to unblock a round is precisely how a
  `[V]` reaches a customer.

**The invariant this phase exists to establish**, and which every later phase depends on: when this
phase ends, every question in the round carries exactly one tag, and the three sets — `[G]`, `[V]`,
`[C]` — are fixed for this round. A question that could not be resolved into one of the three is
left in the round in the *untagged* holding state, with what is wrong with it recorded, and the
round stays open. It is never asked in that state, of anybody.

A question re-tagged later (the *Answer every `[G]` from the findings* phase) re-enters **here**, is
re-tested against §2, and joins whichever set it now belongs to. It never enters an asking phase by
any other route.

---

## Phase 5 — Answer every `[G]` from the findings

**This phase raises no prompt.** It reads findings and writes answers, and it runs to completion
before any operator queue opens.

For each `[G]` in the round, search the verified findings for one whose `claim` settles it. Only a
finding carrying a verifier `outcome` counts (the *Resolve inputs and gate the grounded BRD* phase
already refused the run if any lacked one). Three outcomes:

1. **A finding settles it.** Record the answer in the round record, quoting the finding's verdict
   and naming every `[CG#n]`/`[DG#n]` it rests on, and mark the question **terminally disposed** as
   *answered from findings*. The finding ids recorded here are what a decision drawing on this answer later
   puts in its own `evidence` list.
2. **A finding exists and cannot settle it** — its verdict is `NOT-PROVABLE`, or the verifier
   returned `unprovable`. This is a complete and legitimate terminal answer, not a shortfall
   (`workflows-core:grounding-format` §3). The question is then **re-tagged**, usually to `[V]`, and the re-tag
   **names that finding as its cause** (`interview-tagging.md` §3). Re-tagging to `[C]` is the
   exception and is correct only when what the repository could not settle turns out to have been a
   business question mistaken for a technical one — "the code does not tell us" is never on its own a
   reason to ask the customer. The original question is terminally disposed as *re-tagged*, naming
   the finding, and the re-tagged question goes back to the *Tag every question* phase to earn a
   terminal disposition of its own.
3. **No finding bears on it at all.** Then grounding has not been asked this question yet, and **the
   answer is a grounding pass, not a person.** Record the **holding state** *needs grounding*, which
   is not a disposition and so keeps the round open, and name it in the final report with the concrete fix — a
   `/product-workflows:prd-ground <BRD-KEY>` run (with `--rebaseline` when the repository has moved since
   the pin) to produce the finding, after which this round resumes at exactly this question. **It is
   not re-tagged**: a re-tag needs a finding to name, and there is none, so promoting it to `[V]`
   here would manufacture the missing trail rather than record its absence. And it is not asked: this
   command writes no findings — only `/prd-ground` does, and only through the independent
   re-derivation `workflows-core:grounding-format` §8 requires — so there is no route by which this run could
   turn its own guess into evidence.

---

## Phase 6 — Put each `[V]` to the operator

The queue is the `[V]` set the *Tag every question* phase fixed, plus anything the previous phase
re-tagged into it and which passed back through tagging. Nothing else, and nothing added after this
phase begins.

Present each question **exactly one at a time, never batched**, via `AskUserQuestion`, quoting the
question, the findings that bear on it with their verdicts and horizons, and — when it got here by a
re-tag — the `NOT-PROVABLE` finding that caused the re-tag, so the operator can see that the
repository was consulted first and came back empty.

The options presented are that question's own `options_considered`
(`decision-register-format.md` §1), generated per question rather than drawn from a fixed list, with
one trailing entry for an option the operator supplies themselves and the two standing exits:

```
choices: [<up to two entries per option considered, in the order they were weighed>, "Defer this question — record why it is not answerable yet", "Another option from the list above — name it"]
```

**The array is capped at four, like every other array in the plugin** (`workflows-core:escalation-rules` §0): `AskUserQuestion` renders `maxItems: 4`, so an uncapped `one entry per option considered` prompt cannot be presented at all once three options were weighed — and this phase is required to present its array verbatim. **List every option considered as prose above the prompt**, in the order they were weighed and with the argumentation each carries, then let the array offer the two strongest plus the defer entry plus a free-text route to the rest, which the run resolves against **the options it just listed**. Where two or fewer were weighed, every one of them fits and the last entry is dropped.

**There is no listed `Cancel`.** The harness always supplies a free-text option, so an abort is reachable without spending one of four slots; say what an aborted round costs where the round is introduced, not in an option.

This is **not** an escalation choice list, and it is not one of the arrays
`workflows-core:escalation-rules` owns: its options are the decision's own, the
same way `/brd-split`'s ledger walk draws its picker from `coverage-ledger-format.md` §3's
dispositions rather than from an escalation array. The harness's free-text option returns an option the
operator names; that option joins `options_considered` and may then be `chosen`, so the record still
shows what was actually on the table.

**Then take the argumentation, and refuse the record without it.** After a choice is made, prompt for
why, and do not write a `[VD#n]` until something is supplied that is not a restatement of the
`statement`, not "to be filled in later", and not the name of whoever decided it.
`argumentation` is mandatory (`decision-register-format.md` §2), and the test for sufficiency is that
section's: **adequate when a reader who was not in the room can say what would have to change for the
answer to change.** A reason that survives being read back a month later names the constraint, not
the preference.

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

**A later round may re-disposition an entry already on file, and this is the only exit `open` and
`conditional` have.** Where an entry read in from `code-defect-log.md` still carries `open`, or
carries `conditional` on a `blocked_on` this round has settled, put its disposition to the operator
once, against the same five values
`${CLAUDE_PLUGIN_ROOT}/references/code-defect-log-format.md` §4 fixes for a first raise. Two things
bound it, and neither is a matter of taste. **What may move is `disposition`, and `blocked_on` with
it** — added when the new disposition is `conditional`, dropped when it is not (§2). **What may not
move is `id`, `statement`, `behaviour`, `intent` and `intent_basis`**: those record what was true of
the pinned commit the cited `[CG#n]` names, and rewriting them would make the log report that an
earlier round found something it did not. `round` does not move either — §2 defines it as the round
that **raised** the defect, not the round that last touched it, and the re-disposition is reported in
this run's round record instead.

**This is the one carve-out from the standing rule that a previous run's records are inputs, never
scratch** (*Resolve inputs and gate the grounded BRD*, step 9, which states the rule and names this
exception beside it). The two are not in tension: a re-disposition writes one field of one record
and deletes, renumbers and rewrites nothing. **There is still no `fixed` disposition** — nothing on
this route builds anything and no command here can observe a repair, so a defect that was fixed
keeps whatever disposition it had (§4).

Record each answered question as **terminally disposed** *decided*, with a `[VD#n]` held for the
register phase, carrying every field `decision-register-format.md` §1 defines — including `evidence`
(the findings this position rests on, written `evidence: []` where it rests on none, never omitted —
§1), `options_considered` (`["yes", "no"]` for a question put as yes or no — §1), `altitude`,
`round` (this run's), `consumed_by: none`, and `conditional_on` **written now by whoever takes the
decision, never reconstructed later** (§5), when the position is correct only while a named decision
of a named prerequisite BRD holds — for instance `conditional_on: EPIC-008/[VD#3]`, naming one
specific decision in that BRD's register and never the BRD as a whole. Which prefix a decision gets
is fixed by the tag of the question it answers, never by who typed it (§1): a question tagged `[V]`
produces a `[VD#n]`, and it does not become a `[CD#n]` because the customer later nods at it.

**Deferring is a recorded holding state, not a disposition and not a skip.** It records the reason
the question is not answerable yet, keeps the round **open**, and never converts the question to
another tag on the way out. It does **not** move the question into a later round: the question stays
where it was raised (the *Generate the round's question set* phase fixes that), and the resume rule
in *Resolve the round* returns to it. A round whose remaining questions are all deferred is an open
round with work left, and is reported as one. **`Cancel` stops the run** naming how many `[V]` questions
remain, and every decision already taken this pass stays written — nothing already decided is rolled
back.

---

## Phase 7 — Hold every `[C]`

A `[C]` is a genuine business decision and reaches the customer **only via the review package**
(`interview-tagging.md` §1) — never through this command, never through a side channel, and never
through the operator standing in for them. This phase therefore asks nobody anything. It writes.

For each `[C]` in the round, write an entry to `<BRD-dir>/interview/customer-questions.md` carrying:
the question as it will be put; its round and position; the findings that bear on it, so the customer
is asked against what is known rather than in the abstract; **its altitude, on a line of its own
labelled exactly `- **Altitude:**`** — `product`, `architecture` or `implementation`, decided by the
test `decision-register-format.md` §1 gives a record's `altitude`, the level the answer will sit at
and so the downstream artifact it must reach, because the `[CD#n]` that answers the question copies
it (`/brd-reconcile`, *Freeze the customer decisions*) and a customer answer has no other source for
it; **for a `rejected` row's question, that row, on a line of its own labelled exactly
`- **Rejected row:** [BR#n]`**, which is how a later run finds the row's question rather than
raising a second one (*One question per row*, in *Resolve the round*); **for a question the
requirement-defect source raised, or a `rejected` row's question carrying the defect it cites, the
`[DEF#n]` it asks about, on a line of its own labelled exactly
`- **Requirement defect:** [DEF#n]`**, and, where the defect sits on a row drawn from an image, that
image's path relative to `brd/`. **That labelled line is the one both readers read, and nothing else
in the entry**, whose context may name other `[DEF#n]`s: `/brd-reconcile` copies its id into the
answering `[CD#n]`'s `settles` field, and every slice under the parent reads it to know the defect is
**asked** (*Round 1 is generated from the grounding*); and, where a
`[G]` part of the same original question was answered first, that answer — because the business
question it leaves is materially different from the one that would have been asked without it (§4).

Each `[C]` is recorded in the round with the **holding state** *held for the customer*. **Holding a
question is not an answer to it**: the terminal disposition *answered by the customer* is reached
only when the answer comes back and an operator confirms it, so a round holding a `[C]` stays open
until `/brd-reconcile` closes it with the customer's answer, as the paragraph after next says.

**No `[CD#n]` is written here, and none may be.** A customer decision enters the register only when
the customer has actually answered and an operator has confirmed the answer (D14,
`decision-register-format.md` §1) — the customer answering and the register recording an answer are
two separate acts, and normalising prose into a decision is inference, not authority.

**This command sends the file nowhere; `/brd-package` is what carries it.** That command builds the
review package the `[C]` questions travel in, and it is a separate, consented run — writing the file
here is not sending it. A `[C]` this run holds stays held until a package goes out and an answer
comes back, and the round that contains it stays open throughout (`interview-tagging.md` §5) until
`/brd-reconcile` ingests that answer and an operator confirms it — that command writes the terminal
disposition *answered by the customer*, and it is the only thing that closes such a round. Report
that as the plain sequence it is: this run holds, `/brd-package` carries, the customer answers, and
`/brd-reconcile` records.

---

## Phase 8 — The will-change rule

Before any `[VD#n]` this run took is written as `decided`, test its `evidence` list against
`decision-register-format.md` §6 (D19): **a decision may not rest solely on a `will-change`
finding.** The test fires when *every* finding in the list carries `horizon: will-change`
(`workflows-core:grounding-format` §5). It does **not** fire on a decision resting on one `current` finding and
two `will-change` ones — the `current` finding is ground that holds — nor on `evidence: []`, which
rests on no `will-change` finding either (§6).

Where it fires, the decision may not be closed. Offer the three resolutions §6 defines — exactly
three, drawn from that section's own table the way the `[V]` picker draws its options from §1:

```
choices: ["Re-base it on a current finding — the decision's evidence list changes", "Make it explicitly conditional on the prerequisite — conditional_on: <BRD-KEY>/<decision-id>", "Defer it until the prerequisite ships — status: open, with the blocking prerequisite named", "Cancel"]
```

Record the outcome as that table prescribes: a changed `evidence` list, a `conditional_on` naming one
specific decision of the prerequisite (`EPIC-008/[VD#3]`, never `EPIC-008` alone — §5), or
`status: open` with the blocking prerequisite named.

**This picker's vocabulary is closed, and holding it closed is required here rather than merely
permitted.** `workflows-core:escalation-rules` names this picker among the six
whose free-text answer is normalised into their own vocabulary rather than written through — the
harness supplies that option on every array and no picker can decline it, so the discipline is in
what the run does with the answer, not in the array's shape. The rule being applied admits
**exactly three** resolutions and says so — "Three resolutions, and exactly three"
(`decision-register-format.md` §6). An open-ended fourth entry would invite a resolution the rule
does not have, and the two most likely things an operator would write into it are precisely the two
evasions §6 and §7 already refuse (below). `Cancel` remains, so nobody is trapped: it stops the run
with the decision still `open`, which is itself one of the three.

**Two things this picker deliberately does not offer.** It does not offer to **remove** the
`will-change` finding from the `evidence` list: a decision whose evidence was thinned until the rule
stopped firing rests on exactly what it rested on before, minus the record of it (§6). And it does
not offer to **re-file the position as an `[AS#n]`**: an assumption is a record with no findings
behind it at all, and calling a position with findings an assumption to escape this rule is the same
evidence-thinning under a different name (§7).

`[AS#n]` records are outside this phase entirely — §6 cannot fire on one, because the rule tests the
horizons of findings in an `evidence` list and an assumption's list holds none.

---

## Phase 9 — Write the register and the round record

**`<BRD-dir>/decisions.md`** — one block per `[VD#n]` and per `[AS#n]`, each carrying every field
`decision-register-format.md` §1 defines, with §7's account of which of the thirteen apply differently
on an assumption. Ids are contiguous within their own prefix, assigned once, **never renumbered and
never reused after a terminal status** (§1) — a re-run continues the sequence from the highest id on
file and never restarts it. A run that reopens a decision writes `status: reopened` with its cause
named (§4), against the original record's id; it never mints a new id for the same question.

**The register is written on every run that reaches this phase, whether or not the round produced a
record.** Where no register is on file, this run creates it, and its first line is the header —
`# Decision register: <BRD-KEY>`, this BRD's key (§1) — whether or not the round recorded anything.
Where the round recorded no `[VD#n]` or `[AS#n]` — a round of nothing but `[C]` questions and
questions answered from findings, or one that raised no question — that line is the whole file.
Without the file, `/product-workflows:brd-package` Phase 0 step 6 stops with
`BRD_PACKAGE_NEEDS_INTERVIEW` as though no interview had written one, and a further run of this
command would resume the same round and again record nothing — a loop. A register already on file is
never rewritten to its header: this run's records are added after those on file.

Every `[AS#n]` this round recorded carries the two fields §7 gives a different meaning: `evidence`
holding the explicit statement of **why no evidence exists** — what was searched and why it fell
short — and `argumentation` saying **why the package proceeds on the assumption rather than stopping
to establish it**. A bare sentence with no account of its own groundlessness is a claim, not an
assumption record.

**`<BRD-dir>/interview/round-<N>.md`** — the round's own record, append-only. **A round that raised
no question at all records the walk instead of the questions**: each of the seven sources *Round 1
is generated from the grounding* names, and what this BRD held under each — **written from what the
walk found, never from a rule over verdicts**: no finding whose verdict left its premise open (the
first two sources: a premise that moved, and one the repository could not settle), none carrying a
`will-change` horizon, no design divergence, no `rejected` row not already settled and no
`deferred-to` row whose consequence is unstated, no open requirement defect this BRD asks, nothing
asserted without evidence. Naming the verdicts instead would put a false sentence in the record on
any corpus holding a `SUPERSEDED` finding, which raises no question and is not `CONFIRMED` either.
That is a complete record of a completed walk, which is exactly what the all-delegated stop's
prohibition on an *empty* record is protecting against. Otherwise: every question in the order it
was written, its tag, every re-tag with the finding that caused it, every split with the parts it
became, and each question's state in the vocabulary the *Resolve the round* phase fixes — either a
**terminal disposition** (*answered from findings*, *decided* naming the `[VD#n]`, *answered by the
customer*, *re-tagged* naming its cause, or *split* naming its parts) or a **holding state** (*held
for the customer*, *deferred*, *needs grounding*, or *untagged*) — **all four**, exactly as the
*Resolve the round* table names them, because a file schema that lists three is a schema under which
the fourth cannot be written down. Plus, when this run re-opened the round, the re-open and its
cause. This file is what makes the round resumable: resumability is a property of the record, not of
the session (`interview-tagging.md` §5), and an interrupted run resumes at the first question here
carrying no terminal disposition — the same test, in the same words, that *Resolve the round*
resumes on.

**Every write of a round record ends with one `Status:` line, and the round's state is its last
one.** The line reads `Status: open — waiting on <each holding state a question in it is in>` or
`Status: closed <YYYYMMDD> — <why>`, dated the day of the write; which of the two is the closure
rule's to say (below), never a separate judgement. The record is append-only, so a write that
changes the round's state appends a new line and never edits the one before it: an earlier `Status:`
line is history, and a reader takes the last. **`/product-workflows:brd-reconcile` is the one other
writer**: it appends `Status: closed <YYYYMMDD> — <why>` when it closes the round's last held `[C]`
question, and no line when it answers fewer, because the round was open, stays open, and its last
line already names what it waits on. A record written before 3.7.0 carries no `Status:` line; its
state is read off its questions' dispositions by the same closure rule, and the next write of it
adds the first line.

**Every round record this command writes carries one line accounting for the requirement-defect
source**, whether or not the round raised a question. It accounts for every open requirement defect
of a class grounding cannot settle that is listed on a row of this BRD's in-scope set and that no
slice had asked before this round (*Round 1 is generated from the grounding* fixes each test): this
round either asked it or withheld it, with the cause —

```
requirement defects: [DEF#n], … asked; [DEF#m] withheld — <cause>
```

— where `<cause>` is `not owned here` (another slice owns it — holds its lowest-numbered live row,
or, none being live, is its carrier — and asks it),
`no live row — <each listed row and its disposition>` (no row it lists is live and no slice carries
it — each is `superseded-by`, never delegated, or rejected citing something else — so nobody owns it
and no slice will ask it), `undecidable — <why>` (the unallocated row, or the sibling whose ledger
or question set could not be read, named), `belongs to round 1 — re-open named`, or
`waits — round <open> still open` (a defect for a new round that cannot open yet). Either half is
left out where it is empty, and where there is no such defect at all the line reads
`requirement defects: none this BRD asks`. **Never `none open in this BRD's scope`**: that is false
wherever an in-scope row carries a defect a sibling asks. *Resolve the round* reads round 1's line
and no other — whether round 1's record carries it is what tells a slice interviewed before this
source existed from one interviewed after.

**`<BRD-dir>/interview/customer-questions.md`** — written by the *Hold every `[C]`* phase, and
appended to by *Resolve the round* where a defect's line joins a held entry (*One question per
row*); listed here because it is one of this run's deliverables.

**`<BRD-dir>/code-defect-log.md`** — every `[CDF#n]` this round raised, appended after any already on
file, each carrying every field `${CLAUDE_PLUGIN_ROOT}/references/code-defect-log-format.md` §2
defines. Ids are contiguous, assigned once, never renumbered and never reused: a re-run continues the
sequence from the highest id on file. **The file is written where this round raised an entry or
re-dispositioned one already on file, and is absent only where it did neither** — that absence is
an ordinary state that no later gate reads as a failure. Every entry's `behaviour` names a `[CG#n]`
that is on file in this BRD's own `grounding/code-grounding.md` and carries a verifier outcome; an
entry citing anything else is not written, because the packaging run will refuse the bundle over it
(`${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md` §6.2 relation 1).

**Plus every re-disposition the *Put each `[V]` to the operator* phase took on an entry already on
file.** That entry is rewritten **in place, in its own position**, never appended as a second record
and never renumbered: `disposition` takes the new value, and `blocked_on` is added or dropped as that
value requires (§2). Every other field of it is written back byte for byte — `id`, `statement`,
`behaviour`, `intent`, `intent_basis` and `round` — so the log continues to say what the round that
raised the entry established. A re-disposition changes the entry count not at all, which is what
distinguishes it in the round record from a raise.

**Round closure is decided here, and only by the record.** The round closes when every question in
it carries a **terminal** disposition, and not before. **Any** of the four holding states keeps it
open — so a round is not closed because the interesting questions are answered, because the
remainder was *deferred*, because a `[G]` is *needs grounding* and waiting on a grounding pass,
because a question is still *untagged* and has not been rewritten yet, or because a `[C]` is *held
for the customer* whose turnaround is slow. Report the round as open or closed accordingly, and when
open, name which holding state it is waiting on — in the final report, and in the `Status:` line
that ends this write of the round record (above).

---

## Phase 10 — Handoff

Invoke `Skill(skill: "workflows-core:reference", args: "phase-handoff")` and present its §4.3 choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`Skill(skill: "workflows-core:reference", args:
"phase-handoff handoff-to-main")`, §2) with `prefix: brd` (§2.9's table, where `brd` is the prefix
the `/brd-*` commands share), `feature_folder` as resolved in the *Resolve inputs and gate the
grounded BRD* phase, `deliverable_paths` = every file this run wrote or updated under `<BRD-dir>`
(`decisions.md`, `interview/round-<N>.md`, `interview/customer-questions.md` when this round held a
`[C]` or appended a defect line to a held entry already on file, and `code-defect-log.md` when this
round raised a `[CDF#n]` **or re-dispositioned one already on file** — a run that only
re-dispositioned still wrote the file, and leaving it out of the set would hand off a register
naming a disposition no ref carries), `title: <BRD-KEY> Record round <N> interview decisions`, and
`body_facts` = the round number and whether it opened, resumed or re-opened; the question counts by
tag; the `[G]` answers and the re-tags with their causes; the `[VD#n]`, `[AS#n]` and `[CDF#n]` ids
written and every `[CDF#n]` re-dispositioned, each with its old and new disposition; the `[C]` count
held, and every defect line appended to a held entry; and every will-change resolution taken. Emit
its §4.1 outcome line in the final report.

The no-new-round path in *Resolve the round* — every round closed and nothing changed — reaches this
phase with nothing staged where the register was already on file, so it reports the
`nothing to commit` line rather than opening a pull request; where that path wrote the register's
header line, `decisions.md` is the one path it hands off. **The nothing-askable first run is not
that path and does stage**: it wrote `interview/round-1.md`, and `decisions.md` with it (the header
alone, where none was on file), and both are deliverables handed off with the rest.

---

## Phase 11 — Next steps

The BRD-to-PRD route's next command is `/brd-package`, which builds the review package the `[C]`
questions travel in, and it is offered **only where this run's own state says `/brd-package` would
accept the BRD** — the clause and the list must agree, or an operator is handed a run that stops on
its Phase 0 gate. `/brd-reconcile` is the command after that one and is not offered here: it ingests
a review that has not been asked for yet, and offering it now would name a step out of order. So the
honest offer is the state this run actually leaves behind.

**Compute the gate before printing the list, and compute every step of it.** `/brd-package` gates
on the register in its Phase 0 step 6 and on content in steps 7 and 8, and an offer that evaluates
some of them still hands the operator a run that stops on another. Apply each, **exactly as those
steps state them**, over the whole BRD's rounds and register rather than over this round alone,
because that is what `/brd-package` reads:

- `commands/brd-package.md` Phase 0 step 6 (*Gate the decision register on main*) — the register in
  the folder, and on the default branch. Its merge half is what the offer's `<merge-clause>` names;
  its presence half is established below, before either content gate.
- `commands/brd-package.md` Phase 0 step 7 (*Gate on the interview's rounds — and read the
  precondition the only way that is not a deadlock*) — which holding state it admits and which three
  it refuses is stated there.
- `commands/brd-package.md` Phase 0 step 8 (*Gate on there being something to review — and report it
  as a finished state, not a missing step*) — what a package must carry for a customer to have
  anything to confirm, correct or attack is stated there.

None of the three is restated here, deliberately: `/brd-package` is the command that actually
refuses the run, so a second copy of any of its preconditions sitting in this phase would drift, and
the run that reads the drifted copy is this one. The register present and both content gates pass →
`package_offerable: yes`. Step 7 fails →
`package_offerable: rounds-unsettled`, and every question that gate named is named beside the list
with its round and its holding state. **Before either gate is consulted: where this run's round-1
test (*Resolve the round*) reported requirement defects that belong to a closed round 1 →
`package_offerable: defects-unasked`, whatever the two gates would say.** The gates cannot see those
defects, because no round holds a question for them: a BRD holding nothing else passes step 7 and
fails step 8, and would be called decided while this run's own report names questions its customer
has never been asked; one holding an open `[AS#n]` passes both, and would be offered a package that
leaves those questions out and needs a second package to carry them. **Step 6's presence half, and
step 8's test for an `interview/` round record, need no value of their own: every path that reaches
this phase has left a register and a round record on file** — *Write the register and the round
record* writes both on every run that reaches that phase, and the no-new-round path writes the
register where none was and found every round already recorded — and every run that stops before
writing them, the all-delegated stop among them, never reaches this phase. So no offer made here
meets `/brd-package`'s `BRD_PACKAGE_NOT_INTERVIEWED`, which fires where `interview/` holds no round
record whatever the register holds, and there is no `not-interviewed` value to compute. Otherwise,
step 7 passes and step 8 fails →
`package_offerable: nothing-to-review`, which is not a defect in this run: every question was
settled from verified findings and the delivery team owes the customer no decision. **Whatever the
state, name beside its list every requirement defect the round-1 test left waiting on an open
round** (*Resolve the round*), with the round it will be asked in: a package offered now goes out
without it, and the next one carries it.

**`package_offerable: yes`:**

```
choices: ["Stop here — this round's decisions are recorded", "Package this BRD for customer review — /product-workflows:brd-package <BRD-KEY> <merge-clause>", "Work another round now — /product-workflows:brd-interview <BRD-KEY> (only if findings or decisions have changed, or a requirement defect became this BRD's to ask)", "Interview another BRD or slice"]
```

**`package_offerable: rounds-unsettled` — `/brd-package` is left out rather than offered and
refused:**

```
choices: ["Stop here — this round's decisions are recorded", "Work another round now — /product-workflows:brd-interview <BRD-KEY> (the questions named above are still in a holding state the packaging step refuses)", "Re-ground a question no finding bears on yet — /product-workflows:prd-ground <BRD-KEY>", "Interview another BRD or slice"]
```

**`package_offerable: defects-unasked` — name every `[DEF#n]` the *Resolve the round* phase
reported, and offer the re-open that asks them.** Do not call this BRD decided and do not offer the
packaging step: each of those defects is a business question only the customer can settle
(`interview-tagging.md` §1), no round holds a question for it yet, and a package built now would go
out without it. The re-open is `--round 1` with the cause *requirement defects became a question
source*: it re-opens round 1, and the round-1 test appends them there (*Resolve the round*). Where
step 7 fails as well — a later round this run opened or resumed holds a question in a holding state
the packaging step refuses — name those questions beside the list too, exactly as
`rounds-unsettled` does.

```
choices: ["Re-open round 1 to ask the requirement defects — /product-workflows:brd-interview <BRD-KEY> --round 1, cause: requirement defects became a question source (Recommended)", "Stop here — the requirement defects named above stay unasked", "Interview another BRD or slice"]
```

**`package_offerable: nothing-to-review` — say plainly that this BRD is decided, and do not offer
either the packaging step or another round of this command.** Both would stop or report a no-op: the
packaging step on its step-8 gate, and this command because it opens a new round only where the
findings or the decisions have changed, or a requirement defect became this BRD's to ask, since the
last round closed — which nothing here has done. Of those, only the findings can be moved from here:
a decision reopens on a new finding or a customer's answer (`decision-register-format.md` §4), and a
requirement defect becomes this BRD's to ask through events outside this command — for instance
`/product-workflows:brd-intake` re-run over a revised source the customer sends, an allocation or a
re-cut elsewhere under the parent, a sibling's `/product-workflows:brd-reconcile` moving its row to
`rejected` or `superseded-by`, or a sibling file that could not be read becoming readable. So a fresh
grounding pass is what the list carries:

```
choices: ["Stop here — every question was settled from the findings and this BRD needs no customer review", "Re-derive the findings against current commits — /product-workflows:prd-ground <BRD-KEY> --rebaseline (a changed finding is what makes a new round askable)", "Interview another BRD or slice"]
```

**Three of the four lists carry no `(Recommended)` marker, and that omission is deliberate**, per
the `When no option is safe to recommend` guidance in
`Skill(skill: "workflows-core:reference", args: "escalation-rules")`: on `yes`, `rounds-unsettled`
and `nothing-to-review`, which one is right depends entirely on what this round left behind.
**`defects-unasked` is the exception and is well-formed rather than an inconsistency**: its list is
shown only in its own state, and in it the marked step is the single one every path out goes through
— the re-open that asks questions only the customer can answer — which is precisely the first bullet
of that reference's `The (Recommended) marker is unconditional` section, where the condition gates
the prompt and the marker is therefore a plain one. What the gate above decides is only **whether
`/brd-package` appears at all**; it never promotes an option to recommended. A BRD both cited gates
pass is ready to package; one either gate refuses is not — which is why it is not shown the option
rather than shown it with a caveat. The `nothing-to-review` list carries no marker for the same
reason and one of its own: stopping there is a legitimate, finished outcome, and marking a grounding
pass "recommended" would imply this BRD is unfinished when it is not.

`<merge-clause>` in that list is the placeholder `workflows-core:next-phase-offer` resolves from
this run's own `Phase handoff:` outcome line; it is never written as an unconditional "once the pull
request above is merged", because the no-new-round path reaches the handoff with nothing to commit
wherever the register was already on file, and then opens no pull request. **The two lists that name
`/product-workflows:prd-ground <BRD-KEY>` — `rounds-unsettled` and `nothing-to-review` — carry no
clause at all, and that asymmetry is deliberate:** that command gates on `coverage-ledger.md`
(`commands/prd-ground.md` Phase 0 step 6), which this run never writes, so no handoff of this run's
can hold it up and there is no wait to state. **The `defects-unasked` re-open carries none for the
same reason**: this command gates on `grounding/code-grounding.md` (*Resolve inputs and gate the
grounded BRD*, step 6), which this run never writes either.

Say plainly what remains, per `Skill(skill: "workflows-core:reference", args: "next-phase-offer")` — names only,
never behaviour a command of its own owns: a round still holding a `[C]` stays open, because the
answer arrives through a package and is recorded by `/product-workflows:brd-reconcile` once it comes
back. A
question in the *needs grounding* holding state — the one the *Resolve the round* phase defines as
movable only by a grounding run — is answered by re-running `/product-workflows:prd-ground <BRD-KEY>`
and returning to this round, which is a real next step and is named as one. A requirement defect this
run withheld as undecidable is named with what decides it — the listed row still `unallocated`, with
the BRD whose `/product-workflows:brd-split` run allocates it, or the sibling whose ledger or question
set could not be read — because until that changes no slice can tell whether to ask it.

### Context hygiene

The resume pointer is written in the terminal cost phase, per
`workflows-core:session-hygiene` §1. Working another round of the same BRD, or
going on to `/product-workflows:brd-package <BRD-KEY>`? Both stay in the PM lane
(§2's *Same role* bullet) → run **`/compact`**. Moving to a different BRD or slice? → run **`/clear`**. Guidance only — nothing is
auto-run.

---

## Phase 12 — Session maintenance, feedback & cost

Terminal phase — runs after *Next steps*, NEVER interrupts an earlier phase, and runs on the
no-new-round path exactly as on any other.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin / skill / command / reference
gap, `emit-block` (`workflows-core:feedback-emission`) fires at that halt before
escalating. None of the *Resolve inputs and gate the grounded BRD* stops qualify — a missing or
malformed key, an unresolved BRD, a resolved root BRD, an ungated or absent grounding deliverable,
an inventory carrying no claim at all (`BRD_INTERVIEW_EMPTY_INVENTORY` — a fact about what the
parent allocated to this slice, or about an interrupted intake's own source document, never about
this plugin), unverified findings, an unallocated
ledger, and an unset `$SPECS_PATH` are environment / sequencing halts, never a plugin capability
gap. `BRD_INTERVIEW_NO_SUCH_ROUND` is not one either: it is an argument naming a round
that does not exist, and neither is `BRD_INTERVIEW_ALL_DELEGATED` — a BRD that kept no requirement of
its own is an allocation outcome this command reports correctly, not a capability it lacks.

1. **Invoke `impl-maintenance`** (subagent_type: "workflows-core:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-interview`; what was produced (the round
   worked, the register entries written, the code-defect log when this round raised or
   re-dispositioned an entry, the `[C]` set held); key events (a re-opened round and its
   cause, a question that needed grounding, a will-change resolution, a cancelled `[V]` queue, the
   no-new-round path — or "none"); workarounds; test result N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Invoke `Skill(skill: "workflows-core:reference", args: "feedback-emission emit-auto")` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-interview`, the run's `key` (the
   `<BRD-KEY>`), `source`, and `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no
   plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Invoke `Skill(skill: "workflows-core:reference", args: "cost-emission emit-cost")` and call its `emit-cost` entry point with `command: /brd-interview`, `phase: brd-to-prd`, `role: pm`, the
   run's `key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Invoke `Skill(skill: "workflows-core:reference", args: "session-hygiene")` and, per its §1, write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry, before the commit
   step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Invoke `Skill(skill: "workflows-core:reference", args: "specs-repo-git commit-artifacts")` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. Stages ONLY the §2.1 bounded artifact paths inside
   `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-interview)` with no
   `Co-Authored-By` trailer, and pushes to the branch the handoff phase created. NEVER touches a code
   repo, a docs repo or the current working directory, where it is not the specs repository; NEVER force-pushes; NEVER fails the
   run; skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice.
   Hold its §6 outcome line for the final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is
offered only in the handoff phase), and NEVER writes into a code/docs repo, or the current
working directory, where it is not the specs repository; no user name is ever written.

---

## Final report

Report: the BRD folder and which level it sits at; the classification and model routing
(+ any Opus degradation); **the round** — its number, and whether this run opened it, resumed it, or
re-opened it with the cause recorded; **the question counts by tag**, `[G]` / `[V]` / `[C]`, and
every split, with the parts each original became; the `[G]` answers, each naming the
`[CG#n]`/`[DG#n]` that settled it; **every re-tag, with the `NOT-PROVABLE` finding that caused it** —
never a re-tag reported without its cause; every question recorded *needs grounding*, named, with
`/product-workflows:prd-ground <BRD-KEY>` as the fix; the round's requirement-defect account line,
and every defect withheld, with its cause — one that belongs to a closed round 1 with its re-open,
and one waiting on an open round with the round it will be asked in; every defect asked by a line
appended to its rejected row's held question, naming that question, and every one raised as a
question of its own because the held entry could not be chosen, naming the candidates;
the `[VD#n]` decided this run and any deferred; the `[AS#n]` recorded; the `[CDF#n]` raised this
round and the `[CDF#n]` re-dispositioned, each with its old and new disposition, when any; the `[C]` count held and the file
holding them, stated together with the fact that
`/product-workflows:brd-package` is the command that carries them to the customer and
`/product-workflows:brd-reconcile` the one that records the answer; every will-change resolution taken and how it was
recorded; the count of decisions and assumptions still `consumed_by: none`
(`decision-register-format.md` §1); whether the round closed or stays open, and what it is waiting on;
the feedback + cost paths; the `Phase handoff:` outcome line (`workflows-core:phase-handoff` §4.1); the
`Specs repo:` outcome line (`workflows-core:specs-repo-git` §6); the next-step recommendation; and end with the
ledger line, read fresh from the (unmodified-by-this-run) `coverage-ledger.md`, exactly per
`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

`/brd-interview` never changes a ledger disposition — the line simply reports where allocation
stands. **Reporting it reads one ledger per `covered-by` row**, one hop, from the working tree
via `resolve-address` (`Skill(skill: "workflows-core:reference", args: "addressing resolve-address")`, §3), per `coverage-ledger-format.md` §6.1 — this run always stands on a slice
(step 6 already confirmed `grounding/code-grounding.md` is on main, and that file is written
exclusively by `/prd-ground`, which itself refuses to run on a root), so that is always a sibling or
the parent (§3); a ledger that cannot
be read there contributes `unresolved`, never `covered` (§6.2). This adds no precondition and no
gate: the allocation gate in *Resolve inputs and gate the grounded BRD* is decided on this BRD's own
rows before any of this, and a non-zero `unallocated` term in the line — a row this BRD delegated to
a child that has not walked it yet — is that resolution working, never this run having failed. A slice does **not** always reach this with
nothing to resolve. `covered-by` is legal on a slice (`coverage-ledger-format.md` §3), where it
names a sibling under the same parent or that parent and marks an **orphan row** — a ledger row for a `[BR#n]` this slice no longer claims, reached by either of §2's two routes: the parent's walk withdrawing a claim that was never more than provisional, or a re-cut moving a claim the slice had committed to and then recorded it would not build (§3.2). Those rows are resolved one hop exactly like a parent's
delegated rows, so a slice reports zero delegated only when its parent withdrew none of its
claims.

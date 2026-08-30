---
name: brd-interview
description: BRD decision workflow (PM phase, fourth command of the BRD-to-PRD route). Gates on the BRD's grounding being merged, every finding carrying a verifier outcome, and its coverage ledger fully allocated, then generates the round's question set and tags every question [G]/[V]/[C] before a single one is asked. Answers every [G] from the grounding findings and never puts one to a human; puts each [V] to the operator one at a time via AskUserQuestion with mandatory argumentation; holds every [C] for the customer. Re-tags a [G] only against a named NOT-PROVABLE finding, splits any question carrying more than one tag, and refuses to close a decision resting solely on a will-change finding. Writes decisions.md ([VD#n] and [AS#n]), the round record, and the [C] question set. --round N resumes an open round or re-opens a closed one, recorded with its cause. Takes no --no-docs and does no documentation grounding.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Turn the grounded BRD into a decided one, one round at a time: $ARGUMENTS

`/brd-interview` is the **fourth command of the BRD-to-PRD flow** (PM phase) — it takes the verified
findings `/brd-ground` produced and the fully-allocated ledger `/brd-split` left behind, and works
the BRD's open questions to recorded decisions. Its whole discipline is one rule: **every question
is tagged before it is asked, and the tag decides who may answer it**
(`${CLAUDE_PLUGIN_ROOT}/references/interview-tagging.md` §1). This command exists to make that
happen, not to restate it.

Usage: `/brd-interview <BRD-KEY> [--round N]`

Runs at either of the two levels `<BRD-KEY>` can name
(`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §3) — a BRD that owns its source document, or
one of its slices. It refuses neither and behaves identically at both: a slice holds its own
findings, its own ledger, and its own register, and it reaches its decisions exactly as its parent
does. The register this run writes is the register of the BRD it was given, and no other.

**Standing rule, binding on every phase below.** A `[G]` is answered from the grounding findings and
is **never put to a human** — not the customer, not the delivery team, not the operator watching the
run (`interview-tagging.md` §1, D8). A `[V]` is put to the operator with recorded argumentation and
is **never routed to the customer** as a business question (§1, D9). A `[C]` is held. The section
*How no `[G]` reaches a human* below states the ordering that makes the first of those structural
rather than aspirational.

**This command takes no `--no-docs`, and it does no documentation grounding at all. That is a
decision, not an omission.** `/brd-intake` and `/brd-ground` already ground this BRD against the
shipped product documentation when `$DOCS_PATH` resolves (D22,
`${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`), and their run is the one that had the
requirement text and the code in front of it. This command operates on **decisions** — on findings
that have already been verified and on choices the delivery team and the customer own — and a
documentation page settles none of those: it is a claim *about* behaviour, not the behaviour, which
is why `/brd-ground` already forbids one as evidence for a `[CG#n]`. So there is no flag to turn
off, no `resolve-docs-grounding` call, and no `docs grounding:` line in this command's report. The
sentence is written here because leaving it unwritten is exactly how the gap it forecloses gets
shipped.

**No repository is opened, at any point.** Every `file:line` this command reads has already been
pinned and verified by `/brd-ground`, so there is no baseline gate here, no dirty-tree stop, and no
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
3. **The operator queue is built once, from the `[V]` list alone.** The *Put each `[V]` to the
   operator* phase takes the `[V]` set the tagging phase produced and nothing else. It is never
   appended to mid-round from another tag, and no phase after it may add a question to it.
4. **A `[G]` leaves the `[G]` set only by re-tagging, and re-tagging re-enters at the tagging
   phase.** It never enters the operator queue directly. And a re-tag is admissible only against a
   named `NOT-PROVABLE` finding or an `unprovable` verifier outcome (`interview-tagging.md` §3):
   **a re-tag with no finding to name is not a re-tag**, so "the code did not tell us, so let us ask
   someone" has no route through this command.
5. **Every prompt this command raises is enumerated, and only one of them carries a question from
   the question set.** They are: the `SPECS_PATH` escalation in *Resolve inputs and gate the grounded
   BRD*; the round re-open cause prompt in *Resolve the round*; the `[V]` queue and the argumentation
   prompt that follows each of its answers; the will-change resolution picker; the handoff choice;
   and the next-step offer. Only the third carries a question from the set — and the argumentation
   prompt inside it asks why the answer just given was given, never a question of its own.

   **Two further prompts can appear, raised inside shared entry points this command executes rather
   than by the command itself, and neither can carry a question from the set** — because neither
   entry point is ever handed one: `require-on-main`'s row-C repair offer (`phase-handoff.md` §3.3),
   which asks whether to switch the specs repo to its default branch, and `emit-cost`'s pending-file
   relocation confirmation (`cost-emission.md` §9), which asks where a cost entry should land. They
   are named so that "every prompt is enumerated" stays a checkable claim rather than one that
   quietly excludes whatever a cited entry point does.

The failure all five exist to prevent is stated once, in `interview-tagging.md` §2, and is not
restated here: a `[G]` put to a person returns their belief about the system rather than the system,
and nothing downstream can tell the difference afterwards.

---

## Phase 0 — Resolve inputs and gate the grounded BRD

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate with `brd-key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §1). If absent or invalid, stop:
   `BRD_INTERVIEW_NEEDS_KEY: /brd-interview needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/dev-workflows:brd-interview <KEY>'.`
2. **`--round N`.** Optional, consuming the next token, which must be a positive integer. Malformed
   or absent value → stop, rather than silently falling back to the no-flag behaviour, which would
   run a different round from the one that was asked for:
   `BRD_INTERVIEW_BAD_ROUND: --round takes a positive integer round number — re-run '/dev-workflows:brd-interview <KEY> --round <N>', or omit the flag to continue at the first round still holding a question without a terminal disposition.`
   What the flag then does is the *Resolve the round* phase's business.
3. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`, per the
   `Required path environment variable unset` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Set SPECS_PATH (enter the path)", "Cancel"]
   ```
4. **Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute
   its `specs-preflight` entry point (§3) inline, **before** the gate below — `require-on-main`
   performs no fetch of its own (`phase-handoff.md` §3.2) and relies on this step's best-effort one,
   the same ordering `/brd-ground` uses and for the same reason. Prompt-free and silent when the
   specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
   `specs_git: blocked` (§3.3 G0), carry that flag for the whole run.
5. **Resolve the BRD folder.** `resolve-brd <BRD-KEY>` (`brd-addressing.md` §2), which searches
   `specifications/` and exactly one level below it — the two levels a BRD folder can occupy. Absent
   → stop, without asserting which command would have created it, because nothing on disk says
   whether this key names a BRD with a source document or a slice of one:
   `BRD_INTERVIEW_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
6. **Gate the grounding deliverable on main.** This command **consumes** a `$SPECS_PATH` deliverable
   it did not write, so per `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 2 it executes
   `require-on-main` (§3) here, before anything else reads a file. Execute it against the resolved
   folder's `grounding/code-grounding.md` — the same file `/brd-split` gates, and for the same reason:
   every deliverable one `handoff-to-main` run stages lands in a single commit (§2.3), so its presence
   on `origin/<default>` implies `grounding/design-grounding.md` and `brd-link.md` merged with it, and
   `/brd-ground`'s own gate on `coverage-ledger.md` had already run before those findings existed at
   all. Map the §3.7 return by `stopped` first: any stopping row → stop, naming the concrete branch/PR
   state it reports; `pass` → proceed; `pass_amending` → proceed, printing the §3.3 row-B message;
   `unmanaged` → proceed as before this feature; `absent` (row F — grounding findings are on no ref at
   all) → **split it before stopping, on a test row F cannot make**, the way `/brd-reconcile` splits
   its own row F. Row F covers two states here, and the message for the second one must not name a
   command that stops on the same emptiness. Read `<BRD-dir>/brd/brd-inventory.md` from the worktree
   and count its `[BR#n]` rows:
   - **One or more rows** — grounding simply has not run yet, and running it is the fix:
     `BRD_INTERVIEW_NEEDS_GROUNDING: no grounding findings on file for <BRD-KEY> — run /dev-workflows:brd-ground <BRD-KEY> first.`
   - **Zero rows** — there is nothing to ground, so `/brd-ground` stops with
     `BRD_GROUND_EMPTY_INVENTORY` rather than producing the findings this gate wants, and naming it
     here would be the loop. The fix is upstream and differs by level, so read the resolved folder's
     `brd-link.md` from the worktree and branch on its `parent:` field, exactly as the grounding and
     split gates do:
     `BRD_INTERVIEW_EMPTY_INVENTORY: <BRD-KEY>'s inventory holds no [BR#n] row, so there is nothing to ground and no question this command could ask about it — do not run /dev-workflows:brd-ground, which stops on the same emptiness. Re-run '/dev-workflows:brd-intake <BRD-KEY> @<brd-file>' over this same folder with a source whose requirements brd-reader can identify, and merge that pull request; if the source genuinely states no requirement, this BRD has nothing for the route to carry.`
     `BRD_INTERVIEW_EMPTY_INVENTORY: <BRD-KEY> is a slice of <PARENT-KEY> and its inventory holds no [BR#n] row — it claims nothing, so there is nothing to ground and nothing to decide. Do not run /dev-workflows:brd-ground, and do not run /dev-workflows:brd-intake on a slice; it has no source document of its own. Re-run '/dev-workflows:brd-split <PARENT-KEY>': it resolves every standing empty child, so it will offer to remove this slice or to keep it against its recorded reason, and it will offer covered-by against it for any row on the parent's ledger that is still unallocated. If the parent's ledger has no unallocated row left, removal is the only thing that can change this slice's state — /brd-split never re-allocates a row that already carries a fate.`
7. **Gate on verification.** Read every `[CG#n]` and `[DG#n]` on file and count those carrying no
   recorded verifier `outcome` (one of the four in
   `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §8). Any count `N` greater than zero →
   stop: `BRD_INTERVIEW_UNVERIFIED: N findings have no verifier verdict — run /dev-workflows:brd-ground first.`
   This gate is not borrowed ceremony. A finding without an outcome "is not evidence"
   (`grounding-format.md` §8), and a decision's `evidence` list is a list of findings
   (`${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1) — so a `[G]` answered from an
   unverified finding, or a `[VD#n]` resting on one, would put an unchecked claim behind a recorded
   decision, which is worse than an open question.
8. **Gate on allocation.** Read `<BRD-dir>/coverage-ledger.md` and count the rows whose
   `disposition` is `unallocated` **as written on this ledger**. Any such row → stop:
   `BRD_INTERVIEW_UNALLOCATED: N coverage-ledger rows are still unallocated for <BRD-KEY> — run /dev-workflows:brd-split <BRD-KEY> first.`
   Interviewing a BRD whose requirements have no recorded fate would take positions on requirements
   nobody has yet decided this BRD is building.

   **Read the dispositions in the file; never the ledger line.** The line's `unallocated` term is a
   *resolved* count that follows every `covered-by` row one hop into its child, so a fully-allocated
   parent routinely reports a non-zero term for rows a child has not walked yet
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6.1, which states outright that a
   consumer testing the gate reads the dispositions and never the line). Gating on the line would
   refuse to interview a BRD that is completely allocated, for work that belongs to a different BRD's
   walk.
9. **Read the inputs the rest of the run works from**, all from the gated folder: every verified
   `[CG#n]`/`[DG#n]` with its `verdict`, `evidence`, `horizon` and verifier `outcome`
   (`grounding-format.md` §2, §3, §5); `brd/brd-inventory.md`'s `[BR#n]` rows; `coverage-ledger.md`;
   `brd-link.md` (its `parent:` and any `depends-on:`); and, when they already exist, `decisions.md`
   and every `interview/round-<N>.md`. A previous run's register and round records are inputs, never
   scratch: nothing below deletes, renumbers or rewrites a record another run wrote.

---

## Phase 1 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

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
already independently re-derived by `/brd-ground`'s `grounding-verifier` pass, and re-deriving it
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
| *needs grounding* | no finding bears on a `[G]` yet; only a `/brd-ground` run can move it |
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
- **Every round is closed, or none exists yet** → a new round is proposed **only if findings or
  decisions have changed since the last round closed**. Concretely: a `[CG#n]`/`[DG#n]` added or
  superseded since that round's record was written, a verifier outcome changed, or a decision in
  `decisions.md` moved to `reopened` or `superseded`. Nothing changed → there is nothing a new round
  could ask that the last one did not already have in front of it; report that plainly, skip to the
  handoff phase with nothing to commit, and end on the ledger line. Something changed → open round
  `<highest + 1>` (round 1 when none exists), naming in its record exactly what changed and made it
  askable.

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
- **Round `N` does not exist** → stop rather than creating it out of order, which would break the
  contiguity §5 depends on:
  `BRD_INTERVIEW_NO_SUCH_ROUND: <BRD-KEY> has no round N — rounds on file: <list, or "none">. Omit --round to continue at the first round still holding a question without a terminal disposition.`
  The one exception: `N` is exactly `<highest + 1>` (or `1` when none exists), which is a request to
  open the next round, and is granted on the same changed-findings-or-decisions test as the no-flag
  path.

Carry the resolved round number for the whole run. Every decision, assumption and question this run
records is stamped with it.

---

## Phase 3 — Generate the round's question set

Write the round's questions **before tagging any of them**, so the set is generated by what the BRD
needs settled rather than by what would be convenient to route.

**Round 1 is generated from the grounding.** Work the verified findings and the inventory together,
and raise a question wherever the pair leaves something unsettled that a PRD would have to state:

- a `[BR#n]` whose findings are `AMENDED`, `REWRITTEN` or `FALSE-FRIEND` — the premise moved, so what
  the requirement now asks for is open (`grounding-format.md` §3);
- a `[BR#n]` whose findings are `NOT-PROVABLE` — the repository could not settle it, and somebody
  must now choose;
- a finding carrying `horizon: will-change` — what this BRD does while the naming prerequisite
  decision is unbuilt is open by construction (`grounding-format.md` §5);
- a `[DG#n]` reconciliation the design and the requirement disagree about (§6's classes);
- a ledger row resolved `deferred-to` or `rejected` whose consequence for the rest of the BRD is
  unstated;
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
   (`grounding-format.md` §3). The question is then **re-tagged**, usually to `[V]`, and the re-tag
   **names that finding as its cause** (`interview-tagging.md` §3). Re-tagging to `[C]` is the
   exception and is correct only when what the repository could not settle turns out to have been a
   business question mistaken for a technical one — "the code does not tell us" is never on its own a
   reason to ask the customer. The original question is terminally disposed as *re-tagged*, naming
   the finding, and the re-tagged question goes back to the *Tag every question* phase to earn a
   terminal disposition of its own.
3. **No finding bears on it at all.** Then grounding has not been asked this question yet, and **the
   answer is a grounding pass, not a person.** Record the **holding state** *needs grounding*, which
   is not a disposition and so keeps the round open, and name it in the final report with the concrete fix — a
   `/dev-workflows:brd-ground <BRD-KEY>` run (with `--rebaseline` when the repository has moved since
   the pin) to produce the finding, after which this round resumes at exactly this question. **It is
   not re-tagged**: a re-tag needs a finding to name, and there is none, so promoting it to `[V]`
   here would manufacture the missing trail rather than record its absence. And it is not asked: this
   command writes no findings — only `/brd-ground` does, and only through the independent
   re-derivation `grounding-format.md` §8 requires — so there is no route by which this run could
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
choices: [<one entry per option considered, in the order they were weighed>, "Defer this question — record why it is not answerable yet", "Cancel", "Other… (describe)"]
```

This is **not** an escalation choice list, and it is not one of the arrays
`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` owns: its options are the decision's own, the
same way `/brd-split`'s ledger walk draws its picker from `coverage-ledger-format.md` §3's
dispositions rather than from an escalation array. `"Other… (describe)"` returns an option the
operator names; that option joins `options_considered` and may then be `chosen`, so the record still
shows what was actually on the table.

**Then take the argumentation, and refuse the record without it.** After a choice is made, prompt for
why, and do not write a `[VD#n]` until something is supplied that is not a restatement of the
`statement`, not "to be filled in later", and not the name of whoever decided it.
`argumentation` is mandatory (`decision-register-format.md` §2), and the test for sufficiency is that
section's: **adequate when a reader who was not in the room can say what would have to change for the
answer to change.** A reason that survives being read back a month later names the constraint, not
the preference.

Record each answered question as **terminally disposed** *decided*, with a `[VD#n]` held for the
register phase, carrying every field
`decision-register-format.md` §1 defines — including `evidence` (the findings this position rests
on), `altitude`, `round` (this run's), `consumed_by: none`, and `conditional_on` **written now by
whoever takes the decision, never reconstructed later** (§5), when the position is correct only while
a named decision of a named prerequisite BRD holds — for instance `conditional_on: EPIC-008/[VD#3]`,
naming one specific decision in that BRD's register and never the BRD as a whole. Which prefix a
decision gets is fixed by the tag of the question it answers, never by who typed it (§1): a question
tagged `[V]` produces a `[VD#n]`, and it does not become a `[CD#n]` because the customer later nods
at it.

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
is asked against what is known rather than in the abstract; and, where a `[G]` part of the same
original question was answered first, that answer — because the business question it leaves is
materially different from the one that would have been asked without it (§4).

Each `[C]` is recorded in the round with the **holding state** *held for the customer*. **Holding a
question is not an answer to it**: the terminal disposition *answered by the customer* is reached
only when the answer comes back and an operator confirms it, so a round holding a `[C]` stays open —
which, today, means indefinitely, for the reason two paragraphs below.

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
(`grounding-format.md` §5). It does **not** fire on a decision resting on one `current` finding and
two `will-change` ones — the `current` finding is ground that holds.

Where it fires, the decision may not be closed. Offer the three resolutions §6 defines — exactly
three, drawn from that section's own table the way the `[V]` picker draws its options from §1:

```
choices: ["Re-base it on a current finding — the decision's evidence list changes", "Make it explicitly conditional on the prerequisite — conditional_on: <BRD-KEY>/<decision-id>", "Defer it until the prerequisite ships — status: open, with the blocking prerequisite named", "Cancel"]
```

Record the outcome as that table prescribes: a changed `evidence` list, a `conditional_on` naming one
specific decision of the prerequisite (`EPIC-008/[VD#3]`, never `EPIC-008` alone — §5), or
`status: open` with the blocking prerequisite named.

**This picker carries no `"Other… (describe)"` entry, and that omission is required here rather than
merely permitted.** `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` names this picker in its
*The permitted adjustment does not reach these arrays* section for exactly that reason; it otherwise
calls adding the trailing entry "the one permitted adjustment", not a mandatory one; and the rule
being applied admits
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
`decision-register-format.md` §1 defines, with §7's account of which of the eleven apply differently
on an assumption. Ids are contiguous within their own prefix, assigned once, **never renumbered and
never reused after a terminal status** (§1) — a re-run continues the sequence from the highest id on
file and never restarts it. A run that reopens a decision writes `status: reopened` with its cause
named (§4), against the original record's id; it never mints a new id for the same question.

Every `[AS#n]` this round recorded carries the two fields §7 gives a different meaning: `evidence`
holding the explicit statement of **why no evidence exists** — what was searched and why it fell
short — and `argumentation` saying **why the package proceeds on the assumption rather than stopping
to establish it**. A bare sentence with no account of its own groundlessness is a claim, not an
assumption record.

**`<BRD-dir>/interview/round-<N>.md`** — the round's own record, append-only: every question in the
order it was written, its tag, every re-tag with the finding that caused it, every split with the
parts it became, and each question's state in the vocabulary the *Resolve the round* phase fixes —
either a **terminal disposition** (*answered from findings*, *decided* naming the `[VD#n]`,
*answered by the customer*, *re-tagged* naming its cause, or *split* naming its parts) or a
**holding state** (*held for the customer*, *deferred*, *needs grounding*, or *untagged*) — **all
four**, exactly as the *Resolve the round* table names them, because a file schema that lists three
is a schema under which the fourth cannot be written down. Plus, when this run re-opened the round,
the re-open and its cause. This file is what makes the round resumable:
resumability is a property of the record, not of the session (`interview-tagging.md` §5), and an
interrupted run resumes at the first question here carrying no terminal disposition — the same test,
in the same words, that *Resolve the round* resumes on.

**`<BRD-dir>/interview/customer-questions.md`** — written by the *Hold every `[C]`* phase; listed
here because it is one of this run's deliverables.

**Round closure is decided here, and only by the record.** The round closes when every question in
it carries a **terminal** disposition, and not before. **Any** of the four holding states keeps it
open — so a round is not closed because the interesting questions are answered, because the
remainder was *deferred*, because a `[G]` is *needs grounding* and waiting on a grounding pass,
because a question is still *untagged* and has not been rewritten yet, or because a `[C]` is *held
for the customer* whose turnaround is slow. Report the round as open or closed accordingly, and when
open, name which holding state it is waiting on.

---

## Phase 10 — Handoff

Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`phase-handoff.md` §2) with `prefix: brd` (§2.9's
table, where `brd` is the prefix the `/brd-*` commands share), `feature_folder` as resolved in the
*Resolve inputs and gate the grounded BRD* phase, `deliverable_paths` = every file this run wrote or
updated under `<BRD-dir>` (`decisions.md`, `interview/round-<N>.md`, and
`interview/customer-questions.md` when this round held a `[C]`), `title: <BRD-KEY> Record round <N>
interview decisions`, and `body_facts` = the round number and whether it opened, resumed or re-opened;
the question counts by tag; the `[G]` answers and the re-tags with their causes; the `[VD#n]` and
`[AS#n]` ids written; the `[C]` count held; and every will-change resolution taken. Emit its §4.1
outcome line in the final report.

The no-new-round path in *Resolve the round* reaches this phase with nothing staged, so it reports
the `nothing to commit` line rather than opening a pull request.

---

## Phase 11 — Next steps

The BRD-to-PRD route's next command is `/brd-package`, which builds the review package the `[C]`
questions travel in, and it is offered **only where this run's own state says `/brd-package` would
accept the BRD** — the clause and the list must agree, or an operator is handed a run that stops on
its Phase 0 gate. `/brd-reconcile` is the command after that one and is not offered here: it ingests
a review that has not been asked for yet, and offering it now would name a step out of order. So the
honest offer is the state this run actually leaves behind.

**Compute the gate before printing the list, and compute BOTH halves of it.** `/brd-package` has
two content gates in its Phase 0, and an offer that evaluates one of them still hands the operator a
run that stops on the other. Apply both, **exactly as those steps state them**, over the whole BRD's
rounds and register rather than over this round alone, because that is what `/brd-package` reads:

- `commands/brd-package.md` Phase 0 step 7 (*Gate on the interview's rounds — and read the
  precondition the only way that is not a deadlock*) — which holding state it admits and which three
  it refuses is stated there.
- `commands/brd-package.md` Phase 0 step 8 (*Gate on there being something to review — and report it
  as a finished state, not a missing step*) — what a package must carry for a customer to have
  anything to confirm, correct or attack is stated there.

Neither test is restated here, deliberately: `/brd-package` is the command that actually refuses the
run, so a second copy of either precondition sitting in this phase would drift, and the run that
reads the drifted copy is this one. Both gates pass → `package_offerable: yes`. Step 7 fails →
`package_offerable: rounds-unsettled`, and every question that gate named is named beside the list
with its round and its holding state. Step 7 passes and step 8 fails → `package_offerable: nothing-to-review`,
which is not a defect in this run: every question was settled from verified findings and the
delivery team owes the customer no decision.

**`package_offerable: yes`:**

```
choices: ["Stop here — this round's decisions are recorded", "Package this BRD for customer review — /dev-workflows:brd-package <BRD-KEY> <merge-clause>", "Work another round now — /dev-workflows:brd-interview <BRD-KEY> (only if findings or decisions have changed)", "Interview another BRD or slice", "Other… (describe)"]
```

**`package_offerable: rounds-unsettled` — `/brd-package` is left out rather than offered and
refused:**

```
choices: ["Stop here — this round's decisions are recorded", "Work another round now — /dev-workflows:brd-interview <BRD-KEY> (the questions named above are still in a holding state the packaging step refuses)", "Re-ground a question no finding bears on yet — /dev-workflows:brd-ground <BRD-KEY>", "Interview another BRD or slice", "Other… (describe)"]
```

**`package_offerable: nothing-to-review` — say plainly that this BRD is decided, and do not offer
either the packaging step or another round of this command.** Both would stop or report a no-op: the
packaging step on its step-8 gate, and this command because it opens a new round only where the
findings or the decisions have moved, which nothing here has done. What can move them is a fresh
grounding pass, so that is what the list carries:

```
choices: ["Stop here — every question was settled from the findings and this BRD needs no customer review", "Re-derive the findings against current commits — /dev-workflows:brd-ground <BRD-KEY> --rebaseline (a changed finding is what makes a new round askable)", "Interview another BRD or slice", "Other… (describe)"]
```

**No option carries a `(Recommended)` marker, and that omission is deliberate**, per the
`When no option is safe to recommend` guidance in
`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`: which one is right depends entirely on what
this round left behind. What the gate above decides is only **whether `/brd-package` appears at
all**; it never promotes an option to recommended. A BRD both cited gates pass is ready to package;
one either gate refuses is not — which is why it is not shown the option rather than shown it with a
caveat. The `nothing-to-review` list carries no marker for the same reason and one of its own:
stopping there is a legitimate, finished outcome, and marking a grounding pass "recommended" would
imply this BRD is unfinished when it is not.

`<merge-clause>` in that list is the placeholder `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`
resolves from this run's own `Phase handoff:` outcome line; it is never written as an unconditional
"once the pull request above is merged", because the no-new-round path reaches the handoff with
nothing to commit and opens no pull request.

Say plainly what remains, per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — names only,
never behaviour a command of its own owns: a round still holding a `[C]` stays open, because the
answer arrives through a package and is recorded by `/dev-workflows:brd-reconcile` once it comes
back. A
question in the *needs grounding* holding state — the one the *Resolve the round* phase defines as
movable only by a grounding run — is answered by re-running `/dev-workflows:brd-ground <BRD-KEY>`
and returning to this round, which is a real next step and is named as one.

### Context hygiene

The resume pointer is written in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Working another round of the same BRD, or
going on to `/dev-workflows:brd-package <BRD-KEY>`? Both stay in the PM lane
(§2's *Same role* bullet) → run **`/compact`**. Moving to a different BRD or slice? → run **`/clear`**. Guidance only — nothing is
auto-run.

---

## Phase 12 — Session maintenance, feedback & cost

Terminal phase — runs after *Next steps*, NEVER interrupts an earlier phase, and runs on the
no-new-round path exactly as on any other.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin / skill / command / reference
gap, `emit-block` (`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) fires at that halt before
escalating. None of the *Resolve inputs and gate the grounded BRD* stops qualify — a missing or
malformed key, an unresolved BRD, an ungated or absent grounding deliverable, an inventory carrying
no claim at all (`BRD_INTERVIEW_EMPTY_INVENTORY`, at either level — a fact about the customer's
document or about what the parent allocated, never about this plugin), unverified findings, an
unallocated ledger, and an unset `$SPECS_PATH` are environment / sequencing halts, never a plugin
capability gap. `BRD_INTERVIEW_NO_SUCH_ROUND` is not one either: it is an argument naming a round
that does not exist.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-interview`; what was produced (the round
   worked, the register entries written, the `[C]` set held); key events (a re-opened round and its
   cause, a question that needed grounding, a will-change resolution, a cancelled `[V]` queue, the
   no-new-round path — or "none"); workarounds; test result N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-interview`, the run's `jira_key` (the
   `<BRD-KEY>`), `source`, and `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no
   plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call
   its `emit-cost` entry point with `command: /brd-interview`, `phase: brd-to-prd`, `role: pm`, the
   run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and
   write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry, before the commit
   step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry
   point (§4) inline — the LAST action of the run. Stages ONLY the §2.1 bounded artifact paths inside
   `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-interview)` with no
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
(+ any Opus degradation); **the round** — its number, and whether this run opened it, resumed it, or
re-opened it with the cause recorded; **the question counts by tag**, `[G]` / `[V]` / `[C]`, and
every split, with the parts each original became; the `[G]` answers, each naming the
`[CG#n]`/`[DG#n]` that settled it; **every re-tag, with the `NOT-PROVABLE` finding that caused it** —
never a re-tag reported without its cause; every question recorded *needs grounding*, named, with
`/dev-workflows:brd-ground <BRD-KEY>` as the fix; the `[VD#n]` decided this run and any deferred; the
`[AS#n]` recorded; the `[C]` count held and the file holding them, stated together with the fact that
`/dev-workflows:brd-package` is the command that carries them to the customer and
`/dev-workflows:brd-reconcile` the one that records the answer; every will-change resolution taken and how it was
recorded; the count of decisions and assumptions still `consumed_by: none`
(`decision-register-format.md` §1); whether the round closed or stays open, and what it is waiting on;
the feedback + cost paths; the `Phase handoff:` outcome line (`phase-handoff.md` §4.1); the
`Specs repo:` outcome line (`specs-repo-git.md` §6); the next-step recommendation; and end with the
ledger line, read fresh from the (unmodified-by-this-run) `coverage-ledger.md`, exactly per
`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

`/brd-interview` never changes a ledger disposition — the line simply reports where allocation
stands. **Reporting it reads one child ledger per `covered-by` row**, one hop, from the working tree
via `resolve-brd` (`brd-addressing.md` §2), per `coverage-ledger-format.md` §6.1; a child that cannot
be read there contributes `unresolved`, never `covered` (§6.2). This adds no precondition and no
gate: the allocation gate in *Resolve inputs and gate the grounded BRD* is decided on this BRD's own
rows before any of this, and a non-zero `unallocated` term in the line — a row this BRD delegated to
a child that has not walked it yet — is that resolution working, never this run having failed. A
slice reaches this with nothing to resolve, since `covered-by` is unavailable on one
(`coverage-ledger-format.md` §3), so its line always reports zero delegated.

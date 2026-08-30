---
name: brd-reconcile
description: BRD reconciliation workflow (PM phase, sixth and last command of the BRD-to-PRD route). Takes the customer's returned review from anywhere, copies it into the BRD folder under the canonical name and commits it before anything reads it, then dispatches customer-review-reader in schema or free-text mode. Confirms every free-text candidate with the operator one at a time against its verbatim quotation before it can become a [CD#n], and never widens the reader's mode. Freezes the confirmed answers as [CD#n], closes each [C] question with the terminal disposition answered by the customer, applies the review's required corrections, banners superseded dated snapshots instead of rewriting them, writes customer-amended and withdrawn resolutions to the defect log, and moves coverage-ledger rows without touching allocation. Then sweeps every dependent BRD — conditional_on positions first — to inherited-unchanged, reverted, reopened or withdrawn, and sweeps every artifact under the parent for the changed ids and for prose still asserting a superseded position. Writes reconciliation-<YYYYMMDD>.md. Takes no --no-docs and does no documentation grounding.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Turn the customer's returned review into frozen decisions, and leave nothing in the tree still
asserting a position it overturned: $ARGUMENTS

`/brd-reconcile` is the **sixth and last command of the BRD-to-PRD flow** (PM phase) — it takes the
file that came back from the package `/brd-package` sent, freezes what the customer actually decided,
and then goes looking for everything the delivery organisation still believes that their answer has
made false. Its whole discipline is one rule: **a customer decision enters the register only when
the customer answered and an operator confirmed the answer** (D14,
`${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1). This command exists to make that
happen, not to restate it.

Usage: `/brd-reconcile <BRD-KEY> @<review-file>`

Runs at either of the two levels `<BRD-KEY>` can name
(`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §3) — a BRD that owns its source document, or
one of its slices. It refuses neither and behaves identically at both: a slice holds its own
register, its own `[C]` question set and its own ledger, and it is reconciled from those and no
others. Two things a slice does differently are named where they arise, and both follow from
inheritance rather than from level: its defect resolutions land in its **parent's** defect log
(`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1), and the stale cross-reference sweep's root
is the **parent's** folder, so a sibling slice still asserting a superseded position is reached.

**Standing rule, binding on every phase below.** Nothing this command reads out of a returned review
becomes a `[CD#n]` on its own. Schema mode parses; free-text mode infers; **both hand the result to
an operator before a single register record is written**, and the operator sees the customer's own
words beside every row they are asked to confirm. The section *How no inferred decision becomes a
`[CD#n]`* below states the ordering that makes this structural rather than aspirational.

**This command takes no `--no-docs`, and it does no documentation grounding at all. That is a
decision, not an omission.** `/brd-intake` and `/brd-ground` already ground this BRD against the
shipped product documentation when `$DOCS_PATH` resolves (D22,
`${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`), and `/brd-interview` and `/brd-package`
deliberately do none for the same reason this command does none: it works on **decisions already
taken** — here, on decisions taken by the customer. This command goes one step further than either.
A documentation page is a claim *about* behaviour written by the delivery organisation, and the
whole content of this run is what the **customer** said; consulting a page here could only produce a
sentence that contradicts the one party whose authority this command is recording, and then quietly
lose the argument to it. So there is no flag to turn off, no `resolve-docs-grounding` call, and no
`docs grounding:` line in this command's report. The sentence is written here because leaving it
unwritten is exactly how the gap it forecloses gets shipped.

**No repository is opened, at any point.** Every finding this run reads was pinned, written and
independently re-derived by `/brd-ground`, so there is no baseline gate here, no dirty-tree stop, and
no `$REPOS_PATH` requirement. That has one consequence this command states rather than works around:
a customer challenge in the review's section 5 or 6, and a `will-change` finding whose named
prerequisite decision this run has just frozen, are both **named as needing a grounding pass** and
are never re-adjudicated here. A finding is not evidence until independently re-derived by a
different agent (`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §8), and this command
re-derives nothing — a finding it wrote would be an unverified opinion wearing a `[CG#n]`.

---

## How no inferred decision becomes a `[CD#n]`

Five properties, and every one of them is a property of the **order and the inputs of the phases
below**, not an instruction to be careful. Together they are the guarantee; individually none of
them is.

1. **One agent reads the review, and it cannot mint.** `customer-review-reader` returns every
   free-text decision as a `candidate` carrying `confirmed: false`, and its hard rules forbid it
   minting any identifier in the delivery side's namespaces at all. So there is no route by which a
   `[CD#n]` arrives from the dispatch — the *Freeze the customer decisions* phase is the only writer
   of that prefix in this plugin, and it reads only what the phase before it confirmed.
2. **This command never widens the reader's mode.** It passes `auto`, or `free-text` where the
   operator has told it the file is prose, and it **never passes `schema`**. That agent fails closed
   to free text on a partial match by its own rule, and a caller that forced a parse would convert
   exactly the material the rule was protecting. There is also no re-dispatch to get a different
   answer: one dispatch, and the mode it reports is the mode the run works in.
3. **Confirmation runs to completion, over the whole candidate set, before the freeze phase opens.**
   The *Freeze the customer decisions* phase reads the confirmed set and nothing else, and no phase
   after it may add to that set. A candidate that never reached the operator is not a decision that
   was skipped; it is a run that stopped, and the *Confirm every candidate* phase's gate says so.
4. **Every candidate is put one at a time, with its verbatim quotation, and there is no bulk
   confirmation.** The picker carries no "confirm the rest" entry, and that omission is required
   rather than merely permitted: batching is what turns a confirmation into a formality, and the
   quotation is the entire mechanism — it is what lets a human check the agent's reading in one
   glance against the customer's own sentence.
5. **A reason nobody gave is never supplied.** `argumentation` is mandatory
   (`decision-register-format.md` §2) and on a `[CD#n]` it is the **customer's** reason. A candidate
   returned with `reason: not stated` cannot be frozen as `decided` by anybody in this run, and the
   two resolutions the *Confirm every candidate* phase offers both leave the reason where it belongs
   — with the customer.

The failure all five exist to prevent is stated once, in `agents/customer-review-reader.md`, and is
not restated here: **normalising prose into a register row *is* inference**, a `[CD#n]` reads
downstream as frozen customer authority, and nothing on the page would record that a sentence of
prose was read into it. Of everything this workflow does, that is the single way it could fabricate
the customer's own voice.

---

## The cross-BRD write guard

**Three phases below write outside the BRD folder this run was given, and all three take the same
guard.** They are:

| Phase | What it writes, and where |
|---|---|
| *Resolve the defects the review settled* | `customer-amended` and `withdrawn` rows into the **parent's** `brd/brd-defect-log.md`, when this run stands on a slice |
| *The propagation sweep* | sweep dispositions into a **dependent BRD's** `decisions.md` |
| *The stale cross-reference sweep* | `updated` corrections into any artifact under the parent, including a **sibling slice's** |

**The rule, once, for all three.** Before writing into an artifact that belongs to a BRD other than
the one this run was given, execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md`
§3) against that artifact. Any **stopping** row → **record, never write**: the intended change, the
artifact, and the concrete branch/PR state the gate reported all go into the reconciliation record
and the final report, and the file is left exactly as it was. Row F (`absent` — the artifact is on no
ref at all) is treated the same way and for the same reason: an artifact nobody has handed off is an
artifact somebody is still working on. `pass`, `pass_amending` and `unmanaged` → write.

**None of this ever stops the run.** The reconciliation is the *prerequisite's* customer loop, and
letting a dependent's open pull request block it would let any downstream BRD stall the BRD its own
positions rest on — the D20 failure, arriving from the other direction.

**Why the guard is one rule and not three.** Writing over a register, a defect log or a value
document that is sitting on somebody else's branch silently overwrites an in-flight run, and the
person whose work is lost finds out at their next `git status`, not here. That failure does not care
which of the three paths reached it, so neither does the guard: a rule written once for the
propagation sweep alone would have left the other two paths open, which is exactly how the second and
third came to exist.

**What is *not* covered, deliberately:** every artifact inside the BRD folder this run was given.
Those are gated once, in the *Resolve inputs and gate the sent package* phase, and re-gating each
write would re-ask a question already answered.

---

## Phase 0 — Resolve inputs and gate the sent package

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate with `brd-key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §1). If absent or invalid, stop:
   `BRD_RECONCILE_NEEDS_KEY: /brd-reconcile needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) and a returned review — re-run '/dev-workflows:brd-reconcile <KEY> @<review-file>'.`
2. **`@<review-file>` (mandatory).** The file the customer sent back, **at whatever path it arrived
   on** — a downloads directory, a mail attachment saved anywhere, a shared drive. It is not
   required to be inside `$SPECS_PATH`, and it is never searched for: the operator says which file
   is the review, because a file this command picked is a file nobody submitted as the customer's
   answer. Absent, or not a readable file → stop:
   `BRD_RECONCILE_NEEDS_REVIEW: /brd-reconcile needs the returned review file — re-run '/dev-workflows:brd-reconcile <KEY> @<review-file>' with the path the customer's file actually sits at.`
3. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`, per the
   `Required path environment variable unset` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Set SPECS_PATH (enter the path)", "Cancel"]
   ```
4. **Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute
   its `specs-preflight` entry point (§3) inline, **before** the gate below — `require-on-main`
   performs no fetch of its own (`phase-handoff.md` §3.2) and relies on this step's best-effort one,
   the same ordering `/brd-package` uses and for the same reason. Prompt-free and silent when the
   specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
   `specs_git: blocked` (§3.3 G0), carry that flag for the whole run.
5. **Resolve the BRD folder.** `resolve-brd <BRD-KEY>` (`brd-addressing.md` §2), which searches
   `specifications/` and exactly one level below it — the two levels a BRD folder can occupy. Absent
   → stop, without asserting which command would have created it:
   `BRD_RECONCILE_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
6. **Gate the sent package on main.** This command **consumes** `$SPECS_PATH` deliverables it did not
   write, so per `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 2 it executes
   `require-on-main` (§3) here, before anything else reads a file. Execute it against the resolved
   folder's **most recent `customer-review-prompt-<YYYYMMDD>.md`** — the artifact whose presence
   proves a package was actually built and handed off. Every deliverable one `handoff-to-main` run
   stages lands in a single commit (§2.3), so on that path its presence on `origin/<default>` implies
   `self-review-<YYYYMMDD>.md`, `customer-delivery-note-<YYYYMMDD>.md` and the whole
   `bundle-<YYYYMMDD>/` merged with it — the artifacts `/brd-package`'s handoff stages together —
   and `/brd-package`'s own gate on `decisions.md` had already run before any of them existed.

   **That implication holds for the `handoff-to-main` path and for no other**, which matters because
   this command's own second stop below sends an operator down a hand-committed one: files landed by
   hand can land in any grouping, or partially. So once the gate passes, **verify the siblings rather
   than inferring them** — check that `self-review-<YYYYMMDD>.md` and `bundle-<YYYYMMDD>/` of the same
   date are present, and report by name any that are not. A missing sibling never stops the run — the
   customer's answer is still their answer — but it is carried into the reconciliation record and the
   final report as a limit on what this run could check the review against, because a returned
   quotation with no committed bundle behind it cannot be matched to the document it came from
   (D13, D18). Inferring the siblings from one file's presence is exactly the assumption the
   hand-committed path breaks. Map
   the §3.7 return by `stopped` first: any stopping row → stop, naming the concrete branch/PR state
   it reports; `pass` → proceed; `pass_amending` → proceed, printing the §3.3 row-B message;
   `unmanaged` → proceed as before this feature; `absent` (row F) → **split it before stopping**, on
   a test row F cannot make. Row F means the prompt is on no ref at all, which covers two different
   states, and sending the wrong message for the second one walks the operator into a wall:

   - **No `customer-review-prompt-<YYYYMMDD>.md` in the folder at all** — no package was ever built.
     `BRD_RECONCILE_NEEDS_PACKAGE: no customer package on file for <BRD-KEY> — run /dev-workflows:brd-package <BRD-KEY> first, and reconcile the review that comes back from it.`
   - **A prompt is in the folder, and on no ref** — the package was built and its handoff was
     declined. **Do not send the operator back to `/brd-package`**: that command refuses to rewrite a
     dated bundle, so re-running it today stops outright and re-running it on another date builds a
     *different* package from the one the customer was actually sent. What is needed is the package
     already on disk, landed:
     `BRD_RECONCILE_PACKAGE_NOT_HANDED_OFF: <BRD-KEY>'s package is written at <path> but is on no branch — its handoff was declined. Commit and merge the package's files to the specs repo's default branch, then re-run; do not re-run /dev-workflows:brd-package, which will not rewrite a dated bundle.`

   **Why the gate is the prompt and not the register.** The committed package is what makes a
   returned review checkable at all: when the review quotes a sentence, there has to be a committed
   copy of the document that sentence came from, at the version the customer actually received (D18,
   `${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md` §5). Reconciling against a package that
   exists only in somebody's working tree would freeze customer authority against a document nobody
   can produce later.
7. **Do not re-gate allocation, and do not re-gate the rounds.** Read `coverage-ledger.md` for the
   rows this run may move and for the final report's ledger line, but do not gate on it:
   `/brd-interview` already refused to run against an unallocated ledger, `/brd-package` refused to
   build against an unsettled round, and neither the register nor the package could be on main
   without both gates having passed. Re-gating here would add a second, differently-worded copy of
   rules `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6.1 and
   `${CLAUDE_PLUGIN_ROOT}/references/interview-tagging.md` §5 already own, and the copies would
   eventually disagree. Where the ledger is read at all, the **dispositions in the file** are read
   and never the ledger line, for the reason that section gives.
8. **Read the inputs the rest of the run works from**, all from the gated folder: `decisions.md`
   (every `[VD#n]` and `[AS#n]` with its `status`, `evidence`, `argumentation`, `conditional_on`,
   `altitude` and `round`); `interview/customer-questions.md` and every `interview/round-<N>.md`, so
   each `[C]` is addressed by the round and position that identify it
   (`interview-tagging.md` §5 — a question mints no identifier of its own); the most recent
   `self-review-<YYYYMMDD>.md`, for the `[SR#n]` ids an `escalated-to-customer` disposition put in
   front of the customer; `customer-review-prompt-<YYYYMMDD>.md` and the manifest of
   `bundle-<YYYYMMDD>/`, so a review's document reference resolves to what was actually sent;
   `brd/brd-inventory.md`'s `[BR#n]` rows; `coverage-ledger.md`; `brd-link.md`; every verified
   `[CG#n]`/`[DG#n]` with its `horizon`; and, when this is not the first reconciliation, every
   earlier `reconciliation-<YYYYMMDD>.md` and every earlier canonicalised review. Every one of those
   is an input, never scratch: nothing below deletes, renames or rewrites a dated artifact another
   run wrote.
9. **Fix the run's date.** One `<YYYYMMDD>` stamp, taken once, used for the reconciliation record
   this run writes. It is **not** the stamp on the canonicalised review, which carries the
   customer's date — the *Canonicalise the returned review* phase says why.

---

## Phase 1 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: SIGNIFICANT     # floors here — this run freezes customer authority into the
                                  # register and writes dispositions into other BRDs' registers
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # customer-review-reader, impl-maintenance
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

**The classification floors at `SIGNIFICANT`** because of what this run changes rather than how much
of it there is: a `[CD#n]` is the only record in this workflow that carries authority the delivery
organisation cannot re-take on its own, and the propagation sweep writes into registers belonging to
BRDs this run was not pointed at. If no Opus resolves for `current_model`, degrade to best-available,
record it in `notes` and in the final report, and never hard-block.

`customer-review-reader` runs at `detection_model` and carries no frontmatter pin, and that is safe
for a reason worth stating rather than assuming: **nothing that agent returns is authority.** Every
free-text decision comes back an unconfirmed candidate and every schema row is confirmed against the
file before it is frozen, so a weaker model's worst outcome is a decision it *missed* — which
surfaces as an unanswered `[C]` that stays open and gets re-asked — and never a decision it
*invented*, which the confirmation phase would have to catch. The recoverable failure is the one the
routing is allowed to risk.

---

## Phase 2 — Canonicalise the returned review, and commit it before anything reads it

**The order is the point.** The review is copied into the BRD folder under a canonical name and
handed off **before a single phase below reads it**, because a run that dies halfway through an
ingest must not be the reason the customer's own document cannot be found again. It arrived on a
path nobody else can reproduce; the copy is the record.

1. **Derive the review's date**, in this order, and stop at the first that answers: a `<YYYYMMDD>`
   in the supplied filename (the schema's output name is `<BRD-KEY> Customer Review <YYYYMMDD>.md`,
   so a file that came back unrenamed carries it); a review date stated in the review's own section
   1; otherwise prompt the operator for it, in plain text, naming what it is for. **The date is the
   customer's, not this run's.** Naming the copy by today's date would record when the delivery team
   got round to ingesting the review rather than when it was written, and every claim in it is dated
   against the package it answers.
2. **Resolve the canonical name**, which is the date plus, where the date alone is taken, a
   disambiguating suffix:

   ```
   <BRD-dir>/customer-review-<YYYYMMDD>.md              # the ordinary case
   <BRD-dir>/customer-review-<YYYYMMDD>-<suffix>.md     # a second review carrying the same date
   ```

   The base name follows the BRD folder's own convention — the same `<artifact>-<YYYYMMDD>.md` shape
   as the prompt, the delivery note and the self-review it sits beside — rather than the spaced
   filename the customer was asked to send, which was chosen to be legible in a mail client and is
   not how this folder addresses anything.

   Resolve it as follows, and **never overwrite a differing file**:

   - **Nothing at the base name** → use the base name.
   - **The base name exists and is byte-identical to the source** → this is a resumed run. Use it,
     and say so.
   - **The base name exists and differs** → this is a **second review carrying the same date**, and
     it is an ordinary state, not an error: a customer sends a corrected resend the same afternoon,
     or two reviewers on their side each return a file. **Prompt for a disambiguating suffix** — the
     same plain-text prompt step 1 already owns, asking for a short lowercase slug of
     `[a-z0-9-]`, 1–24 characters, naming what tells this review apart (`corrected`, `second-reviewer`).
     Then resolve the suffixed name by these same three tests, re-prompting where the suffixed name
     is itself taken by something different, naming what is already there so the operator can pick a
     suffix that is free.

   **A date cannot be the disambiguator, which is why a suffix exists.** Where both files were
   genuinely written on the same day, step 1 derives the same date from either, and there is nothing
   truthful to change it to — telling the operator to rename the incoming file would be telling them
   to record a date the review does not carry, and refusing to ingest it would make the second review
   permanently unreadable by this command. The suffix is what lets the folder hold two reviews of one
   date without either of them lying about when it was written. The *Write the reconciliation record*
   phase already anticipates the same state from the other end — two reviews ingested on one day are
   two events, and that record appends rather than overwriting — and this is the affordance that
   makes reaching it possible.

   **A returned review is never overwritten**, whatever the name resolves to. It is the customer's
   document and the counterpart of the immutable source `/brd-intake` copies in (D11): two different
   reviews under one name leaves nobody able to say which one a `[CD#n]` was frozen from. The
   byte-identical case is admitted deliberately, and it is what keeps a run that failed after the copy
   from being unresumable.

   Only one thing here stops the run, and it is the operator declining to name a suffix at all:
   `BRD_RECONCILE_REVIEW_EXISTS: <BRD-dir>/customer-review-<YYYYMMDD>.md already exists and differs from the file supplied, and no disambiguating suffix was given — a returned review is never overwritten. Re-run and supply a suffix, or reconcile the review already on file.`
3. **Copy the source to the resolved canonical name**, byte for byte. Everything below reads that
   copy, cites that copy, and names that copy — including the suffix, where one was taken, so a
   `[CD#n]` frozen from the corrected resend is never mistaken for one frozen from the file it
   replaced.
4. **Hand it off.** Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array
   verbatim:
   ```
   choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
   ```
   On the first choice, execute `handoff-to-main` (`phase-handoff.md` §2) with `prefix: brd` (§2.9's
   table, where `brd` is the prefix every `/brd-*` command shares), `feature_folder` as resolved in
   the *Resolve inputs and gate the sent package* phase, `deliverable_paths` = the canonicalised
   review alone, at the name step 2 resolved, and
   `title: <BRD-KEY> Record the returned customer review <YYYYMMDD>`. Emit its
   §4.1 outcome line in the final report, labelled as the review's handoff so it is not confused with
   the run's own.

   **This is the first of two `handoff-to-main` calls in this run, and they are two different
   questions.** This one hands off **the customer's document**; the *Handoff* phase near the end
   hands off **what this run decided about it**. The second reuses the branch this one created —
   §2.2's rule 3 resolves an in-progress branch of the caller's own prefix by reusing it rather than
   colliding with it, and §3.3's row B names a branch "created earlier in the same invocation via
   this caller's own `handoff-to-main`" as an anticipated state.

   **Declining does not stop the ingest.** Options 2 and 3 both decline the handoff (§4.3), the copy
   stays written, and the run proceeds — the copy-before-ingest ordering this phase exists for is
   satisfied by the copy, and what a decline costs is the push, which the run's own handoff offers
   again with this file still first in `deliverable_paths`. Refusing to ingest here would leave an
   operator holding a review this plugin will not process until they run git themselves, which is
   precisely the wrong place to put a wall in a workflow whose whole shape is a human in the loop.

**Everything below reads the canonicalised copy and never the supplied path.** The agent is given
the copy, the register cites the copy, and the reconciliation record names the copy. The original is
mentioned once, in the record, as where it came from.

---

## Phase 3 — Ingest the review

Dispatch `customer-review-reader` **once**, at `detection_model`:

→ Agent (subagent_type: "dev-workflows:customer-review-reader", model: `<detection_model>`):
  > "brd_key:     [the BRD key]
  > review_path: [absolute path to the canonicalised copy, at the name the *Canonicalise the returned review* phase resolved — customer-review-<YYYYMMDD>.md, or the suffixed form where it took one]
  > package:
  >   questions:   [path to interview/customer-questions.md]
  >   assumptions: [path to decisions.md]
  > mode: auto"

Supply the inputs **exactly as that agent's own Inputs contract declares them**. It refuses to run
without `review_path`, returning `status: INPUT_MISSING`, and returns `status: REVIEW_MISSING` when
the path does not resolve. Map either to a stop naming the field or the path it named — both are
defects in this dispatch rather than in the review, and proceeding past one would reconcile against
nothing:
`BRD_RECONCILE_READER_CONTRACT: customer-review-reader returned <status> — the dispatch, not the review, is at fault; the canonicalised copy is at <path>.`

**`mode: auto`, and never `mode: schema`.** That agent treats anything short of a positive,
in-order, twelve-section match with a row-shaped section 7 as free text, by its own fail-closed rule,
and a caller that overrode it to `schema` would be asking for the one conversion this whole command
is built to prevent. The only override this command may pass is `free-text`, and only where the
operator has said outright that the file is prose — a narrowing, never a widening. **There is no
second dispatch.** Re-dispatching a review that came back free-text, hoping for a parse, is the same
override taken slowly.

**Record what the digest says, before working it.** The mode and its `mode_evidence`; the twelve
sections with each marked `present`, `stated-none` or `absent` — two facts that are never merged;
`evidence_limitations`, including a `stated: false` that says the review's evidentiary basis is
unknown; the decisions with their provenance; `unanswered_questions`; `challenges`;
`required_changes`; `anomalies`; and `notes`.

**Present every anomaly to the operator now, before any candidate is confirmed, and repair none.**
The agent reports departures from the schema rather than resolving them, and this command does the
same: a section missing rather than present and saying `none`, a section out of order, a verdict
outside the three values, a verdict its own later sections contradict, an identifier the review
appears to have minted. Each of those changes how section 7 should be read — a verdict of `approved`
sitting next to an unresolved blocker means the review is not saying what its verdict says — and an
operator who meets them after confirming twelve candidates has already confirmed them against the
wrong reading. Nothing here is a stop: an anomalous review is still the customer's answer, and the
anomalies travel into the reconciliation record and into the final report.

**Section 7 of a returned review carries three id shapes, and the matcher accepts all three.** The
review's decision log answers what the package's part *the decisions the customer must make* put to
it, and `/brd-package` fills that part from three sources:

| What the review's section 7 may cite | Where it came from | What it matches against |
|---|---|---|
| a `[C]` question, by its round and position | `interview/customer-questions.md` | the round record's entry for that question, whose holding state is *held for the customer* |
| an `[AS#n]` | every open assumption in the register (`decision-register-format.md` §7) | the `[AS#n]` record itself |
| an `[SR#n]` | a self-review finding disposed `escalated-to-customer` | that finding's record in `self-review-<YYYYMMDD>.md` |

**The third is not an oversight to be narrowed away.** `/brd-package` puts an escalated self-review
finding to the customer under its own `[SR#n]` rather than minting a `[C]` for it, precisely because
minting one would put a question to the customer that never went through the tag test
(`interview-tagging.md` §2). A parser that accepted only the first two would silently drop every
answer to a finding the delivery team escalated on purpose, and the drop would look like customer
silence. A row citing none of the three is `unmatched` and is carried as such — a customer may
legitimately decide something nobody asked, and forcing it onto the nearest question loses both the
answer and the question.

---

## Phase 4 — Confirm every candidate (D14)

**No `[CD#n]` is written while any decision the digest returned is unconfirmed.** Present each one to
the operator, **one at a time, never batched**, with:

- the statement as it would be registered, and the answer;
- the **verbatim quotation** from the review it rests on — always, in both modes;
- what it appears to answer, in one of the three id shapes above, or `unmatched`;
- the reason the customer gave, or `not stated` as the plain fact it is;
- in free-text mode, the agent's own `confidence`, and every `conflict` flag naming the other
  candidate this one pulls against.

```
choices: ["Confirm — this is what the customer decided; freeze it", "Correct it — the row does not match the quotation; supply the row that does, and freeze that", "Reject — this is not a customer decision at all; record why", "Ask the customer — the answer is not clear enough to freeze; the question stays open", "Cancel"]
```

**This is not an escalation choice list** — its four options are the four fates a candidate can take
in this command, the same way `/brd-package`'s disposition picker draws its four from its reviewer
agent's contract and `/brd-interview`'s will-change picker draws its three from
`decision-register-format.md` §6. It carries **no `"Other… (describe)"` entry and no bulk
confirmation**, and both omissions are required rather than merely permitted. A free-text fifth
option in a picker about customer authority is an invitation to write something that is neither the
customer's decision nor a refusal of it; and a "confirm the rest" entry would return the whole
mechanism to the state D14 exists to end, in one keystroke.

**That requirement is enforceable only because the shared reference carves this array out by name.**
`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` otherwise calls adding the trailing
`"Other… (describe)"` entry "the one permitted adjustment" — which would **authorise** an agent to
open the exact hole D14 closes, on the authority of the file this command is bound by. Its
*The permitted adjustment does not reach these arrays* section therefore names this picker, the
missing-reason picker below and the propagation sweep's, and gives that reason. A rule contradicted
by its own authority is not a rule, so it is stated in both places or in neither.

**`Cancel` stops the run with nothing frozen, and that is the honest description.** No `[CD#n]`
exists until the *Freeze the customer decisions* phase runs, so a cancelled walk has written nothing
to the register and the confirmations taken in it are lost with the session. What survives is what
was on disk before: the canonicalised review, committed if its handoff was accepted. A re-run reads
it again and re-offers every candidate — which is exactly why the resume rule below keys on the
`[CD#n]` records **on file** rather than on anything this phase held in memory.

**Both modes go through this phase, and they are not the same act.** In schema mode the rows come
back `parsed` — provenance, not promotion — and what the operator is confirming is that the register
row about to be written says what the customer's own row says. In free-text mode the rows come back
`candidate`, and what the operator is confirming is **an agent's reading of prose**. The second is
where a mandate could be manufactured, so the free-text walk states, per candidate, that the row is
an inference and that the quotation beside it is the only thing the customer actually wrote.

**Rejecting and asking are real options and are meant to be used.** *Reject* is the answer for
context, scheduling, thanks and apology that an agent shaped like a decision — a candidate minted
from one is noise a human must now refute rather than confirm. *Ask the customer* is the answer for
a conflict flag, a low confidence the quotation does not carry, and an answer that arrived about a
question nobody put. Both are recorded with their reason; **nothing is silently dropped**, because a
candidate that vanishes is indistinguishable from one nobody looked at.

**A candidate whose reason is `not stated` cannot be frozen as `decided`, by anyone in this run.**
`argumentation` is mandatory (`decision-register-format.md` §2) and on a `[CD#n]` it is the
customer's own reason for their own decision. Where *Confirm* is chosen on such a candidate, exactly
two resolutions follow:

```
choices: ["Ask the customer for the reason — nothing is frozen; the [C] stays held for the customer and the round stays open", "Freeze the answer as [CD#n] with status: open, naming the absent reason — nothing downstream may consume it until the reason arrives", "Cancel"]
```

The second is not a workaround: `open` means raised and not yet settled, and a decision may not be
consumed downstream while it is open (`decision-register-format.md` §3), so the answer is on the
record and unusable until the customer supplies what makes it defensible. What this picker does not
offer is the operator writing the reason themselves. A supplied reason is the delivery team's
argument recorded as the customer's, and it will be defended later as theirs — the exact failure the
mandatory field exists to prevent, arriving through the one door the field cannot close.

**A re-run never re-asks what an earlier pass already froze.** Every earlier
`reconciliation-<YYYYMMDD>.md` was read in the *Resolve inputs and gate the sent package* phase.
A candidate whose target already carries a **`decided`** `[CD#n]` from an earlier pass over **this
same review** is skipped and reported as already reconciled — never re-offered. Without that rule a
run cancelled halfway and restarted would mint a second `[CD#n]` for one question, and **two customer
answers to one question is a contradiction one record has no way to hold**
(`interview-tagging.md` §5, `decision-register-format.md` §1). A target carrying an **`open`**
`[CD#n]` is the exception and **is** re-offered: that record is waiting for the reason that would
close it.

**Completing an `open` record is not minting a new one.** Where a later review supplies the reason a
`[CD#n]` was frozen `open` for, the missing `argumentation` is written onto **that record**, which
moves to `decided`. Ids are assigned once and never reused (§1), and one record holds one `chosen` —
a second id for the same question would leave two answers on the page with nothing to adjudicate
between them.

**The gate.** Any decision in the digest still unconfirmed when this phase would end → stop:
`BRD_RECONCILE_UNCONFIRMED: N decisions from the returned review are still unconfirmed — every one takes confirm | correct | reject | ask-the-customer before a [CD#n] is written.`

---

## Phase 5 — Freeze the customer decisions as `[CD#n]`

Write one `[CD#n]` per confirmed candidate **that is not completing a record that already exists**.
The *Confirm every candidate* phase's rule is the carve-out and it is repeated here because the mint
and the exception live in two different phases, which is precisely where this would regress: a
candidate confirmed against a target already carrying an **`open`** `[CD#n]` **mints nothing** — its
reason is written as the `argumentation` of that record, which moves to `decided`. Ids are assigned
once and never reused (§1), and one record holds one `chosen`. Everything else in this phase is
about a genuinely new record, and each carries every field `decision-register-format.md` §1 defines:

| Field | On a `[CD#n]` this phase writes |
|---|---|
| `id` | `[CD#n]`, contiguous within its own prefix, continuing from the highest `[CD#n]` on file, **never renumbered and never reused** — a re-run continues the sequence and never restarts it |
| `statement` | the decision, one sentence, as confirmed |
| `options_considered` | what the package actually put in front of the customer, taken from the `[C]` question, the `[AS#n]`, or the escalated `[SR#n]` — never reconstructed from the answer |
| `chosen` | the customer's answer, one member of `options_considered` |
| `argumentation` | **the customer's own reason, quoted**, never paraphrased and never supplied |
| `evidence` | the `[CG#n]`/`[DG#n]` the question was put against, as the question set recorded them |
| `altitude` | the altitude the question carried |
| `conditional_on` | written only where the customer's answer is itself correct only while a named prerequisite decision holds, and named as `<BRD-KEY>/<decision-id>` (§5) — for instance `conditional_on: EPIC-014/[CD#2]` |
| `status` | `decided`, or `open` where the reason is absent and the *Confirm every candidate* phase took that resolution |
| `consumed_by` | `none` |
| `round` | the round that raised the question this answers |

**What "frozen" means, exactly.** A `[CD#n]` written `decided` leaves that status only through
§4's two admitted causes — a new grounding finding, or a later incoming customer decision that
contradicts or constrains it — each recorded with its cause. This command is one of those causes for
*other* decisions and is never a cause for the record it has just written: a run does not reopen its
own freeze.

Then, in the same phase and from the same confirmed set:

1. **Close each `[C]` in the round record.** A question whose answer this run froze moves from the
   holding state *held for the customer* to the terminal disposition **answered by the customer**,
   naming the `[CD#n]` it produced. Append it; never rewrite what the round originally asked. **This
   is the only thing that can close such a round**, and it is why the round stays open from the
   moment `/brd-interview` holds a `[C]` until this command runs: holding a question is not the
   customer answering it, and the customer answering it is not the register recording an answer
   (`interview-tagging.md` §5, `decision-register-format.md` §1). Mark the same question answered in
   `interview/customer-questions.md`, naming the `[CD#n]`.

   **A question whose `[CD#n]` is `open` is not answered, and its holding state does not move.** The
   terminal disposition is reached when the answer came back *and* an operator confirmed it, and a
   record that cannot be consumed downstream has not been confirmed into anything usable. So it stays
   *held for the customer*, the round stays open, and the next package puts it to the customer again
   — which is precisely how the missing reason gets chased. Closing the round here would retire the
   only mechanism that would ever ask for it.
2. **Supersede the assumptions the customer settled.** An `[AS#n]` the customer confirms does not
   silently become a fact and an `[AS#n]` they contradict does not silently disappear: both are
   `superseded` by the `[CD#n]` that answers them, which the record names
   (`decision-register-format.md` §7). An assumption whose row said `cannot-say` is **not**
   superseded — cannot-say is a real answer and not a settlement — and it stays open and travels
   into the next package.
3. **Reopen what the answer overturned, here.** Every `[VD#n]` in **this** BRD's register that the
   frozen answer contradicts or constrains takes `status: reopened`, naming that `[CD#n]` as its
   cause — an incoming customer decision is precisely one of the two causes §4 admits, and a
   reopening whose cause is unnamed is indistinguishable from somebody changing their mind. The same
   test applied to **other** BRDs is the propagation sweep's, and it is deliberately not run here:
   this BRD's own register is the one this phase is already holding open.
4. **Record an answered `[SR#n]`.** A finding disposed `escalated-to-customer` and answered in
   section 7 produces a `[CD#n]` like any other, whose record names the `[SR#n]` it answers. That is
   not this command minting a `[C]`: it mints no question at all, and records an answer to one the
   package already put. The dated self-review holding that `[SR#n]` is **bannered, never rewritten**
   — the next phase but one.

**No `[VD#n]` and no `[AS#n]` is created by this command, ever.** A delivery-team position is
`/brd-interview`'s to take, with its own argumentation prompt, and a customer answer does not become
a `[VD#n]` because it was inconvenient to freeze — which prefix a decision gets is fixed by the tag
of the question it answers, never by who typed it (§1).

---

## Phase 6 — Apply the required corrections

The review's section 12 is **the only channel a returned review has for changing a package
document** (D13, `${CLAUDE_PLUGIN_ROOT}/references/customer-review-schema.md` §3): the one-new-file
rule closes every other one, so each row is an *instruction to edit* naming the document by filename,
the section or identifier inside it, and what must change. This phase is where those instructions are
carried out — or refused, on the record.

**Every row takes exactly one disposition, and the phase gates on it:**

| Disposition | What it obliges |
|---|---|
| `applied` | The named artifact is corrected, and the correction is recorded against the review row that asked for it. A row marked `applied` whose artifact is unchanged is not applied |
| `applied-with-deviation` | The change is made differently from the way the row describes; what was done and why it differs is recorded, so the customer can see it in the next package rather than discover it |
| `refused-with-reason` | The reason is recorded and travels into the reconciliation record. A refusal the customer never sees is a refusal they will re-request next round |
| `deferred-to-next-round` | The change is real and cannot be made now; what blocks it is named, and the row is carried into the reconciliation record's *what still needs a human* |

Any row still undisposed when this phase would end → stop:
`BRD_RECONCILE_UNDISPOSED_CORRECTION: N required changes from the review are still undisposed — every row takes applied | applied-with-deviation | refused-with-reason | deferred-to-next-round.`

**Three classes of target, and they are not treated alike:**

1. **A live working document** — `decisions.md`, `coverage-ledger.md`, `brd/brd-inventory.md`,
   `slices.md`, `brd-link.md`, a seed file. Corrected in place. These are the documents the route
   works on, and they are supposed to move.
2. **A dated snapshot** — `self-review-<YYYYMMDD>.md`, `customer-review-prompt-<YYYYMMDD>.md`,
   `customer-delivery-note-<YYYYMMDD>.md`, `interview/round-<N>.md`, anything under
   `bundle-<YYYYMMDD>/`, an earlier `reconciliation-<YYYYMMDD>.md`. **Never rewritten.** The next
   phase says what happens instead and why.
3. **`brd/source/`** — the customer's own document. **Never touched at all** (D11). A correction to
   the source is a defect resolution beside it, which the *Resolve the defects the review settled*
   phase writes. Editing the customer's document destroys the ability to say precisely what they gave
   us and what we changed, and a review row asking for it is asking for something this workflow does
   not do — refuse it with that reason, and say where the amendment is held instead.

**A correction that would change a `[CG#n]` or a `[DG#n]` is not applied here.** The review's
sections 5 and 6 challenge code and design claims, and the delivery side re-adjudicates them
(`customer-review-schema.md` §5) — but re-adjudication means an independent re-derivation, which only
`/brd-ground` performs. Every such challenge is recorded verbatim, in the reviewer's own words, and
named in the reconciliation record with the concrete next step: a
`/dev-workflows:brd-ground <BRD-KEY>` run, with `--rebaseline` where the repository has moved since
the pin.

---

## Phase 7 — Banner the superseded dated snapshots (D10)

**A dated snapshot is bannered, never rewritten.** A banner is a block prepended above the file's
first line, stating: the date the file records; what has superseded it, by identifier; which of this
run's changes did the superseding; and where the current position is now recorded. **Nothing beneath
the banner changes, byte for byte.** A second reconciliation adds a second banner beneath the first;
a banner is never edited and never replaced.

The reason is D10's and it survives being read in isolation: **a dated self-review or review prompt
is the record of what was asked on the day, and the customer's review responds to that text.**
Rewriting it to match a later position falsifies the record their review answers — and then every
quotation in the returned review points at a sentence that no longer exists, so nothing the customer
said can be checked against what they were actually sent. The delivery team is left holding a review
of a document it has quietly replaced, and nobody can tell which sentences moved.

**Which files this phase banners:** the folder-level `customer-review-prompt-<YYYYMMDD>.md`,
`customer-delivery-note-<YYYYMMDD>.md` and `self-review-<YYYYMMDD>.md` whose content this run's
`[CD#n]`, corrections or sweep dispositions have overturned, and any earlier
`reconciliation-<YYYYMMDD>.md` a later pass has superseded.

**And the one place a banner is refused: inside `bundle-<YYYYMMDD>/`.** That directory is the
permanent record of exactly what was sent, and its whole value is that it is **byte-identical to the
customer's copy** — which is what makes D13's property checkable months later (D18,
`bundle-packaging.md` §5). A banner is a modification like any other, so bannering the bundle would
break the one property the bundle exists to hold. D10 and D13 partition cleanly and neither is
weakened: D10 governs the dated artifacts the delivery team keeps beside the bundle, D13 governs the
bundle itself. The overturned bundle document is named in the reconciliation record instead, and the
banner on the folder-level prompt says outright that the bundle's own copy is the unbannered
original and is the one to quote from.

**The round records are bannered too, not corrected.** `interview/round-<N>.md` is append-only by
`/brd-interview`'s own rule, and the terminal disposition this run appends to it is an addition, not
a rewrite — the questions and tags it recorded stand exactly as they were asked.

---

## Phase 8 — Resolve the defects the review settled

`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §4 fixes exactly four resolutions a
`brd/brd-defect-log.md` entry can carry. **This command writes two of them, and only those:**

| Resolution | Written when |
|---|---|
| `customer-amended <date>` | the review supplies corrected text for the requirement the defect was raised against. The `<date>` is the **review's**, not this run's — the amendment is the customer's act |
| `withdrawn` | the customer withdrew the requirement the defect was raised against |

`resolved-by: [CG#n]` is a grounding outcome and this command produces no finding, so it is never
written here. `open` is the state a defect is already in and is never written *back* over a
resolution — a resolution recorded is not un-recorded by a later reading of it.

**The amendment is held beside the original and never written into `brd/source/`** (D11,
`brd-format.md` §4). A resolution changes the log entry's status only: it never touches the source,
and it never assigns the requirement a disposition — the disposition vocabulary belongs to the
coverage ledger, which the next phase updates.

**On a slice, these rows land in the parent's log — and that is a cross-BRD write.** A slice holds no
`brd/brd-defect-log.md` of its own and inherits its parent's (`brd-format.md` §2.1), and that lookup
is **exactly one hop** because nesting is capped at one level — a slice's parent always owns the
source document and the log. The parent's log therefore joins this run's `deliverable_paths`, and the
reconciliation record names it by path so nobody looks for a resolution in the folder the command was
pointed at.

Because the log belongs to another BRD, **the cross-BRD write guard applies here in full**: run
`require-on-main` against the parent's `brd/brd-defect-log.md` first, and on any stopping row record
the resolutions rather than writing them, naming the parent's branch/PR state. A parent whose defect
log is mid-review is a parent somebody is editing, and a resolution written over it is a defect
classification lost without trace. On a source-owning BRD the log is this run's own and the guard does
not fire.

---

## Phase 9 — Update the coverage ledger

**A returned review never sets a disposition** (`customer-review-schema.md` §5 — the review does not
set the delivery team's coverage bookkeeping). What moves a row here is a **frozen `[CD#n]`**, and
this phase is the translation between the two.

**Three of the six dispositions are available to this command**
(`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3):

| Disposition | Written when |
|---|---|
| `deferred-to: <this BRD>` | a `[CD#n]` defers the requirement — a live obligation, not built now |
| `rejected: [DEF#n]` | a `[CD#n]` withdrew it, citing the defect-log entry the previous phase resolved `withdrawn` |
| `superseded-by: [BR#n]` | a `[CD#n]` replaced it with another requirement this inventory already holds |

**`covered-here` and `covered-by` are not.** Allocation — which BRD builds a requirement — is
`/brd-split`'s walk and nothing else's (`coverage-ledger-format.md` §4), and a customer decision is
not a statement about which BRD in the delivery organisation owns the work. A row this run would
otherwise want to allocate is named in the reconciliation record with
`/dev-workflows:brd-split <BRD-KEY>` as the fix. And **no row ever returns to `unallocated`**: that
is the initial state, and moving a row back into it would reopen a gate that has already been
satisfied and cannot be re-satisfied by anything this command does.

**A requirement the customer asked for that no `[BR#n]` covers is not minted here.** The review's
section 4 is about intent, and a requirement the package missed entirely is its highest-value row —
but the inventory is extracted from an immutable source by `/brd-intake`, and a `[BR#n]` this command
invented would be a requirement with no anchor into the document the customer actually signed. It is
recorded in *what still needs a human*, naming the two real routes: an amendment logged against the
defect log, or a fresh source document through `/dev-workflows:brd-intake`.

**The roll-up, and what this phase must not do with it** (D23, `coverage-ledger-format.md` §6.1).
The ledger line resolves every `covered-by: <CHILD-KEY>` row **one hop** through the named child's
own ledger, and every term in it is a *resolved* count rather than a census of what the file says.
Two consequences bind this phase:

- **Decisions about this ledger read the dispositions written in this file, never the line.** The
  line's `unallocated` term does not track the allocation gate — a fully-allocated parent routinely
  reports a non-zero term for rows a child has not walked yet — so a phase that keyed anything off
  it would act on another BRD's unfinished walk.
- **This command never writes into a child's ledger.** A `covered-by` row whose obligation the
  customer has just withdrawn is a fact about the parent's row; what the child does about it belongs
  to the child's own reconciliation, and the propagation sweep is what names it there. Reaching one
  hop down to write would make the parent's line report a fate the child never recorded, which is
  the failure the roll-up exists to surface rather than a shortcut past it.

---

## Phase 10 — The propagation sweep

**Fix the changed-id set first, once, and sweep for nothing until it is fixed.** It is: every
`[CD#n]` frozen this run; every `[VD#n]` this run reopened; every `[AS#n]` superseded; every `[SR#n]`
answered; every `[BR#n]` whose ledger row moved; and every `[DEF#n]` that gained a resolution. A set
that grows while the sweep runs makes the sweep's own coverage unknowable — some items were checked
against three ids and some against six, and afterwards nobody can say which.

**Find every dependent BRD.** A dependent is any BRD whose `brd-link.md` declares `depends-on:`
carrying this run's `<BRD-KEY>`, at **either** of the two levels a BRD folder can occupy — so the
search scans `specifications/` and exactly one level below it, the same bound `resolve-brd` uses and
for the same reason (`brd-addressing.md` §2, §3). This is the reverse of key resolution and is a
scan, not a lookup: a dependency is declared by the dependent, and nothing in this BRD's own folder
lists who depends on it. Any key at any level may declare it (D17), so a slice depending on a
source-owning BRD and a BRD depending on a sibling are both found by the same scan.

**`conditional_on` positions are swept first, and they are swept whether or not they cite a changed
id.** Every `[VD#n]`, `[CD#n]` and `[AS#n]` in a dependent BRD carrying
`conditional_on: <this BRD-KEY>/<decision-id>` is the sweep's opening pass. **That is what the field
is for** (`decision-register-format.md` §5): a position built on a prerequisite is not wrong, it is
*invisible* — nothing in its own text says it should be re-examined when the prerequisite moves — and
`conditional_on` is what makes it reachable mechanically instead of by somebody remembering.

The order is load-bearing rather than tidy. The `conditional_on` pass is the **complete** one: it
finds every position that declared its dependency, exhaustively, by a field. The citation pass that
follows is the **incomplete** one: it finds positions that happen to name a changed id in text. A
sweep that ran the incomplete pass first and then "also checked" `conditional_on` has made the
mechanical, complete pass an afterthought to the textual one, and the first time the two disagree the
afterthought is what gets skipped.

**Then the citation pass:** every decision and every `[AS#n]` in every dependent BRD whose
`statement`, `argumentation`, `evidence` or `conditional_on` names an id in the changed set, plus
every finding those decisions rest on.

**Every item the sweep reaches is forced to exactly one disposition.** Present each one at a time,
with the item, the changed id that reached it, and what changed about that id:

```
choices: ["Inherited unchanged — the change does not move this position; say why", "Reverted — the position returns to what it stood at before the prerequisite moved it", "Reopened — this must be decided again; status: reopened, naming this cause", "Withdrawn — the question this answered has stopped applying", "Cancel"]
```

**Not an escalation array either**: the four options are the four dispositions the design fixes for
this sweep, in that order, and a fifth would be a disposition nothing downstream can read — which is
why `escalation-rules.md`'s *The permitted adjustment does not reach these arrays* section names this
picker among the five that never take a trailing `"Other… (describe)"` entry. No `(Recommended)`
marker, and the reason is stated beside the list per the
`When no option is safe to recommend` guidance in `escalation-rules.md`: which one is right is a
judgement about a position in another BRD, taken by whoever owns it, and a marker would invite the
run to inherit-unchanged its way through a sweep whose whole purpose is to find what did move.

| Disposition | Recorded as |
|---|---|
| `inherited-unchanged` | the record is unchanged; the sweep row names the changed id that was considered and why it does not move the position. **The row is written even so** — an item checked and found unaffected and an item never reached are different facts |
| `reverted` | the record's `chosen` and `argumentation` return to the position that stood before the prerequisite moved it, recorded against the changed id |
| `reopened` | `status: reopened` on that record, naming this run's `[CD#n]` as its cause — an incoming customer decision is exactly one of the two causes §4 admits |
| `withdrawn` | `status: withdrawn` — the question stopped applying rather than being answered differently. It is **not** a tidier spelling of `superseded` (§3), and it is what stops a request from reappearing in the next customer package after the customer has already dealt with it |

**A dependent BRD whose register is in flight is recorded, never written.** This is the *cross-BRD
write guard* above, applied to each dependent's `decisions.md`: `require-on-main` first, and on any
stopping row the dependent is named in the reconciliation record and in the final report with its
concrete branch/PR state and the dispositions this run would have written, with **nothing written
into it**. It is never a stop of the whole run, for the reason that section gives.

**Findings are named, not superseded.** A `[CG#n]` or `[DG#n]` carrying `horizon: will-change` whose
named prerequisite decision this run has just frozen is exactly the shape the horizon exists to make
visible (`grounding-format.md` §5) — but a `will-change` finding is never deleted and is superseded
only by a *later finding at a later commit*, which only a `/brd-ground` run produces. Every one the
sweep reaches is recorded with the concrete fix — `/dev-workflows:brd-ground <BRD-KEY> --rebaseline`
— and carried into *what still needs a human*. A finding this command marked `SUPERSEDED` would be a
supersession with nothing on the other side of it.

**A re-run re-sweeps what was recorded and not written, and only that.** An item an earlier pass
over this same review **disposed and wrote** is skipped and reported as already swept. A dependent
BRD that pass could only **record** — its register was in flight — is swept again in full, because
nothing was ever written into it. Collapsing the two would make the recorded-not-written state
permanent: the operator merges the dependent's pull request exactly so the sweep can land, and a
re-run that skipped it would silently refuse to.

**The gate.** Any swept item still undisposed when this phase would end → stop:
`BRD_RECONCILE_UNSWEPT: N positions in dependent BRDs are still undisposed — every one takes inherited-unchanged | reverted | reopened | withdrawn.`

---

## Phase 11 — The stale cross-reference sweep

**The sweep is not optional, and it is not a grep.** Its root is the **parent's** folder — the
source-owning BRD's directory and every slice inside it — so that when this run stands on a slice, a
*sibling* slice still asserting a superseded position is reached. Standing on a source-owning BRD,
the root is that BRD's own folder, which is the same set. Every markdown file under it is in scope:
the seeds, `slices.md`, the inventory, the ledger, the grounding files, every register, every round
record, and every dated snapshot.

**Two searches, and the second is the one that matters.**

1. **The changed ids, literally.** Every id in the set the previous phase fixed, searched as text,
   **whitespace-tolerantly** — an identifier is routinely broken across a line wrap in prose, and a
   search that only matched it on one line would report a clean tree over an artifact that names it
   twice.
2. **Prose asserting a now-superseded position, with no id in it at all.** For each position this run
   changed, search for the *claim the old position made*, in the words these artifacts use for it,
   and read every hit. This half cannot be reduced to a pattern, and skipping it is what the sweep
   exists to prevent: **updating a register while a value document still states the old position is
   the characteristic failure of this step.** The register is the only place anybody looks to check
   a decision, so the contradiction is invisible from there — and the package ends up internally
   contradicting itself in front of the customer who caused the change, which is the worst possible
   audience for it.

**Each hit takes one of three outcomes**, and every hit gets one:

| Outcome | Meaning |
|---|---|
| `updated` | the sentence is corrected, naming the `[CD#n]` that changed it. **Where the artifact belongs to another BRD** — the parent's own, or a sibling slice's — the *cross-BRD write guard* applies: `require-on-main` first, and on a stopping row the hit becomes `needs-a-human` naming that state, never `updated` |
| `still-true` | the sentence survives the change; **why** it survives is recorded, because "I looked and it was fine" and "I did not look" leave the same trace otherwise |
| `needs-a-human` | the correction is a judgement this run cannot take, or the hit is inside a dated snapshot; it travels into *what still needs a human* |

**The guard is why this sweep's root being the parent's folder is safe.** Reaching a sibling slice is
the whole point of rooting it there — a superseded position asserted in a sibling's seed is invisible
from this BRD's own folder — but reaching it and *writing* into it are two different acts, and the
second is a cross-BRD write like any other. Without the guard this sweep would be the widest
unguarded write path in the command: it touches every markdown file under the parent, most of which
belong to some other BRD.

**A hit inside a dated snapshot is never edited.** It is bannered by the *Banner the superseded dated
snapshots* phase where that phase's rules reach it, and inside `bundle-<YYYYMMDD>/` it is neither
edited nor bannered — it is recorded, for the byte-identical reason that phase gives.

---

## Phase 12 — Write the reconciliation record

Write `<BRD-dir>/reconciliation-<YYYYMMDD>.md`, stamped with **this run's** date. It says what
changed, why, which ids, and what still needs a human:

- **The review** — the canonicalised copy by path, the original path it arrived on, the mode the
  reader worked in and what decided it, the verdict, the readiness statement **quoted verbatim** (it
  is one sentence long precisely so it can be quoted without being softened), the twelve sections'
  states, the evidence limitations as stated — or the plain fact that they were not stated — and
  every anomaly, unrepaired.
- **What changed** — every `[CD#n]` frozen, with its quotation, what it answers, and how it was
  confirmed; every candidate rejected or sent back to the customer, with its reason; every `[AS#n]`
  superseded; every `[VD#n]` reopened here; every correction with its disposition; every banner
  added; every defect resolution, with the log's path; every ledger row moved.
- **The sweeps** — the changed-id set as fixed; per dependent BRD, every `conditional_on` position
  and every citing item with its disposition and reason, and every dependent recorded-not-written
  with its state; per stale-reference hit, the file, what was found, and its outcome.
- **What still needs a human** — every question the review did not answer, in **all three** of the
  id shapes the package put to it, so an escalated `[SR#n]` the customer passed over is not lost
  behind the `[C]` questions that were; every candidate not frozen;
  every correction deferred or refused; every code and design challenge, with `/brd-ground` as the
  fix; every `will-change` finding needing a rebaseline; every dependent recorded-not-written; every
  `needs-a-human` prose hit; and every requirement the customer asked for that no `[BR#n]` covers.

**A second reconciliation on the same day appends, and never overwrites.** Where
`reconciliation-<YYYYMMDD>.md` already exists, this run adds a new pass beneath what is there, under
its own heading naming the review file that caused it. Two reviews ingested on one day are two
events, and this file is the record of both — stopping instead would leave an operator holding a
second review with no way to process it until tomorrow.

---

## Phase 13 — Handoff

Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`phase-handoff.md` §2) with `prefix: brd` (§2.9's
table), `feature_folder` as resolved in the *Resolve inputs and gate the sent package* phase,
`deliverable_paths` = the canonicalised review at its resolved name (still listed, so a run whose
first handoff was declined lands it here), `decisions.md`, `interview/round-<N>.md` and
`interview/customer-questions.md`, `coverage-ledger.md`, the defect log's path (**the parent's**, on
a slice), every dated artifact this run bannered, `reconciliation-<YYYYMMDD>.md`, every dependent
BRD's `decisions.md` the sweep wrote, and every artifact the stale-reference sweep updated;
`title: <BRD-KEY> Reconcile the returned customer review <YYYYMMDD>`; and `body_facts` = the mode the
review was read in; the `[CD#n]` ids frozen and the count of candidates rejected or sent back; the
`[C]` questions closed and any still open; the corrections by disposition; the banners added; the
defect resolutions; the ledger rows moved; every dependent BRD swept, with its dispositions and any
recorded-not-written state; and the count of stale-reference hits by outcome. Emit its §4.1 outcome
line in the final report, beside the *Canonicalise the returned review* phase's.

This handoff **reuses the branch that phase created** (§2.2 rule 3), so both commits land on one
branch and one pull request — the customer's document first, then what was decided about it, in the
order they happened.

---

## Phase 14 — Next steps

This run leaves a **reconciled** BRD: customer decisions frozen, dependents swept, and every artifact
under the parent checked for a position the answer overturned. The BRD-to-PRD route's next step would
be `/create-prd --from-brd`, which would carry that BRD into a Product Requirements Document — **and
it does not exist yet**, so it is not offered. Neither is `--from-brd` on `/create-ard` or
`/specify`. Offering a command the plugin does not ship would be worse than offering nothing, so the
honest offer is the state this run actually leaves behind:

```
choices: ["Stop here — the decisions are frozen and both sweeps are recorded", "Work another round — /dev-workflows:brd-interview <BRD-KEY>, where this run reopened a decision or left a question askable", "Package again — /dev-workflows:brd-package <BRD-KEY> <merge-clause>, where questions remain for the customer", "Re-ground a moved claim — /dev-workflows:brd-ground <BRD-KEY> --rebaseline <merge-clause>", "Reconcile another BRD or slice", "Other… (describe)"]
```

**No option carries a `(Recommended)` marker, and that omission is deliberate**, per the
`When no option is safe to recommend` guidance in
`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`: which one is right depends entirely on what
this reconciliation left behind, and the reason is stated here, beside the list, rather than folded
into a conditional marker the orchestrator would then have to evaluate. **Each option carries its own
condition in its own text**, which is what keeps the list honourable verbatim: an operator whose run
reopened nothing reads the second option and sees that it does not apply, rather than being offered a
run that would report there is nothing new to ask.

Say plainly what remains, per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — names only,
never behaviour a command of its own owns: a `[C]` the review did not answer keeps its round open and
travels in the next package; a decision this run reopened is settled by another interview round; a
challenged code claim is settled by a grounding pass and by nothing here; and a dependent BRD
recorded-not-written stays unswept until its own register is on the default branch.

### Context hygiene

The resume pointer is written in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Reconciling a second review for the same
BRD, or working another round of it? → run **`/compact`**. Moving to a different BRD or slice? → run
**`/clear`**. Guidance only — nothing is auto-run.

---

## Phase 15 — Session maintenance, feedback & cost

Terminal phase — runs after *Next steps*, and NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin / skill / command / reference
gap, `emit-block` (`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) fires at that halt before
escalating. One of this command's stops qualifies and is the reason the invariant is named here:
`BRD_RECONCILE_READER_CONTRACT` is an agent-contract gap — a dispatch this command owns that its own
agent refused. None of the others do: a missing or malformed key, an unreadable review, an unresolved
BRD, an ungated or absent package, a review file that already exists under a different content, and
an unset `$SPECS_PATH` are environment or sequencing halts. `BRD_RECONCILE_UNCONFIRMED`,
`BRD_RECONCILE_UNDISPOSED_CORRECTION` and `BRD_RECONCILE_UNSWEPT` are not either — they are the gates
working.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-reconcile`; what was produced (the
   canonicalised review, the frozen `[CD#n]`, the banners, the reconciliation record); key events
   (the mode the review arrived in, a candidate sent back to the customer, a reason left `not
   stated`, a refused correction, a dependent recorded-not-written, a stale-reference hit needing a
   human — or "none"); workarounds; test result N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-reconcile`, the run's `jira_key` (the
   `<BRD-KEY>`), `source`, and `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no
   plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call
   its `emit-cost` entry point with `command: /brd-reconcile`, `phase: brd-to-prd`, `role: pm`, the
   run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and
   write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry, before the commit
   step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry
   point (§4) inline — the LAST action of the run. Stages ONLY the §2.1 bounded artifact paths inside
   `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-reconcile)` with no
   `Co-Authored-By` trailer, and pushes to the branch the handoff phases created. NEVER touches a code
   repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the
   run; skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice.
   Hold its §6 outcome line for the final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is
offered only in the two handoff phases), and NEVER writes into a code/docs repo, the vault, or the
current working directory; no user name is ever written.

---

## Final report

Report: the BRD folder and which of the two levels it sits at; the classification and model routing
(+ any Opus degradation); **the review** — the canonicalised path, the original path, the mode and
what decided it, the verdict, the readiness statement quoted verbatim, and the evidence limitations
as stated or the fact that they were not; **every anomaly**, unrepaired, because each one changes how
the rest of the review should be read; **every `[CD#n]` frozen**, with what it answers and its
status, and every candidate rejected or sent back to the customer with its reason; the `[C]`
questions closed and every one still open, with the round each sits in; every `[AS#n]` superseded and
every `[VD#n]` reopened here; the corrections grouped by disposition, with every refusal's reason
stated in full; every dated artifact bannered, and every overturned bundle document named rather than
bannered; the defect resolutions with the log's path; the ledger rows moved; **the propagation
sweep** — per dependent BRD, the `conditional_on` positions first, then the citing items, each with
its disposition, plus every dependent recorded-not-written with its concrete state; **the
stale cross-reference sweep** — the hit counts by outcome and every `needs-a-human` hit named;
**what still needs a human**, in full; the artifacts written, by path; the feedback + cost paths;
**both** `Phase handoff:` outcome lines (`phase-handoff.md` §4.1), labelled — the review's and the
run's; the `Specs repo:` outcome line (`specs-repo-git.md` §6); the next-step recommendation; and end
with the ledger line, read fresh from `coverage-ledger.md` **as this run left it**, exactly per
`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

**Reporting it reads one child ledger per `covered-by` row**, one hop, from the working tree via
`resolve-brd` (`brd-addressing.md` §2), per `coverage-ledger-format.md` §6.1; a child that cannot be
read there contributes `unresolved`, never `covered` (§6.2). Every term is a **resolved** count, and
the `unallocated` term does not track the allocation gate — a non-zero one here is a row this BRD
delegated to a child that has not walked it yet, which is the resolution working and never this run
having left something undone. A slice reaches this with nothing to resolve, since `covered-by` is
unavailable on one (`coverage-ledger-format.md` §3), so its line always reports zero delegated.

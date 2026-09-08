# A code-defect record for the BRD-to-PRD route — design

**Status:** approved in brainstorming 2026-09-08, not yet implemented. Ledger item **E-3**, sequenced after gate 3 and after E-2 and E-4. Blocks the release under S18.

**Ledger:** `docs/superpowers/brd-route-follow-ups.md` § E-3.

**Scope:** E-3a (the capability gap) and E-3b (the correctness bug) together. The narrowing gap recorded beside E-2 — no supported way to narrow a parent's verified findings to a slice's claimed subset — is **not** in scope and stays its own dormant entry: it is a repair path for bundles authored on a pre-split tree, it shares no vocabulary, writer or consumer with this design, and slice-first grounding removed the need for the operation it describes.

## 1. The problem

`/prd-ground` spends its whole effort reading code at pinned commits, and routinely establishes that the code is broken — an active regression, a missing index the code assumes, a write path that never sets a column. The route has nowhere to put that.

`references/brd-format.md` §4's `[DEF#n]` log is for **requirement** defects: all six classes in §3 are tests "a reader applies to a single `[BR#n]`", and all four resolutions in §4 are about the requirement or the customer's document (`customer-amended`, `withdrawn`, `resolved-by: [CG#n]`, `open`). `/prd-ground`'s *Write findings* phase writes findings, a documentation-divergence section and a derivation matrix, none of which is a defect record. A grep for any code-defect record across `plugins/product-workflows/` returns nothing.

So the fact lands in a decision's `argumentation`, which `references/decision-register-format.md` §2 makes mandatory free prose — exactly where something goes when there is nowhere else. **Two instances in one shipped register asserted that a defect *"is recorded"* while nothing held one**, and both survived drafting, the round record and a first adversarial review. That is E-3b, and it is the half that can reach a customer: `decisions.md` ships in the bundle.

**Why a grounding finding is not already the record, and this is the load-bearing distinction in the whole design.** `workflows-core:grounding-format` §1 fixes grounding's question as *"is this specific claim true of this specific commit?"* and states that grounding **adjudicates, it does not scope**. A `REWRITTEN` verdict says the code does X; it says nothing about whether X is intended. Calling X a defect is a claim about the code's **own intent**, which grounding has no authority over and no field for. A finding plus an opinion is not a record — it is the same unevidenced assertion E-3b is about, one level down.

## 2. Decision

**A new route-local register**, defined by a new `product-workflows` reference and written to `<BRD-dir>/code-defect-log.md`, holding `[CDF#n]` entries. Each entry cites the verified `[CG#n]` that established the behaviour and names its **intent basis separately**. `/brd-interview` is its only writer. A decision reaches its entries through a new `defects:` field on the register record. `bundle-packaging` §6 gains one class row and one two-part rule so the log's exclusion from the bundle is enforced rather than assumed.

**Two alternatives were considered and rejected on evidence, recorded so neither is re-proposed.**

**Widening `[DEF#n]`** fails on ownership before it fails on vocabulary. `brd-format` §4 puts exactly one defect log per *source document*, held by the BRD that owns that document, which a slice reaches one hop up. A code defect belongs to the slice's own grounding — and grounding is slice-only — so this would store it at the wrong owner and make every slice's code defects the parent's. Separately, it would put two disjoint class and resolution vocabularies inside one log.

**Generalising `workflows-core:source-truth` §7.5** — the family's existing code-defect artifact, `implementation-gaps.md`, written by `/document` — fails on shape and on blast radius. That file is a **draft you file elsewhere**, not a register: no bracketed id, no status, no disposition, and fields that are documentation-run specific (`PRD phrasing`, `Docs status`, `User decision in docs`). It is consumed by five agents across two other plugins, so reshaping it for a route problem is the unmeasured widening `CLAUDE.md` records refusing twice. **The disciplined half of that instinct is kept**: the new reference cites §7.5 as its sibling precedent, so the next reader finds it instead of building a third one.

## 3. The record

```yaml
id: [CDF#1]
statement: <one sentence — what is wrong>
behaviour: [CG#12]
intent: <one sentence — what the code is supposed to do instead>
intent_basis: <a file:line or document path | `operator-judgment` — <why>>
disposition: open | in-scope | out-of-scope | conditional | withdrawn
blocked_on: <what would settle the scope question>   # required when disposition is `conditional`, omitted otherwise
round: 2
```

`id` follows the family rule without variation: contiguous within its own prefix, assigned once, never renumbered, **never reused** — flatly, with no terminal-status qualifier, because unlike a decision this record has no state a later run may reopen. A re-run continues from the highest id on file.

`behaviour` names exactly one **verified** `[CG#n]` in this BRD's own `grounding/code-grounding.md`. There is no entry without one. This mirrors the rule `/prd-ground`'s *Write findings* phase already applies to a documentation divergence — *"no entry may exist without naming a verified `[CG#n]`"* — and for the same reason: it is what keeps an unevidenced code claim out of an artifact the route treats as established.

**`intent_basis` has exactly two shapes, and the split is the field's whole purpose.** Either a pointer into a repository or a document that says what the code should do — a `file:line`, a schema, a test, a sibling code path, a documentation page — or the literal `operator-judgment` followed by the reasoning. That makes *"is there something that says so, or is this a person's call?"* a property of the record rather than a matter of prose tone. Both are legitimate; only one of them is checkable, and the record has to say which it is.

**Four fields are deliberately absent, and each absence is a rule rather than an oversight.**

- **No `commit`, no `repo`, no `evidence`.** The cited `[CG#n]` carries all three, already verified. Restating them is the drift `workflows-core:followup-emission` §1 forbids as *"link, never restate"*, and a defect whose location the finding's evidence does not cover is a defect that finding did not establish.
- **No `altitude`.** A code defect is always implementation altitude. A field with one legal value is noise that invites an author to fill it wrong.
- **No `consumed_by`.** Nothing downstream draws on a defect: it is delivery-side work, never input to the PRD, ARD or specification. The spec's §7 altitude routing has nothing to route.

## 4. The disposition vocabulary and the scope condition

Exactly five, mirroring `decision-register-format` §3's five statuses:

| Disposition | Meaning |
|---|---|
| `open` | Raised, not yet dispositioned |
| `in-scope` | The repair is part of the work this route is scoping |
| `out-of-scope` | Recorded, and deliberately not this engagement's work |
| `conditional` | Cannot be settled until something else is; carries `blocked_on` |
| `withdrawn` | The intent basis turned out to be wrong; it is not a defect |

**`conditional` is the field the report required, and it deliberately does not reuse `conditional_on`'s shape.** The reported case was *"whether the new surface renders this is a property of code nobody has written"* — that is not a decision in anyone's register, so a field accepting only `<BRD-KEY>/<decision-id>` would force the operator to invent one, or to assert the repair is in scope and contradict their own stated boundary, which is what actually happened. `blocked_on` takes either shape: a decision address where one would settle it, or one sentence naming what has to exist first.

**An unqualified `blocked_on` is safe here in a way `grounding-format` §5's `prerequisite` is not.** `bundle-packaging` §6.2 has to *report* an unqualified `prerequisite` rather than resolve it, because a silent pick lands on a real record of the wrong package and the check goes green. Nothing ever resolves `blocked_on`, because this log never reaches a bundle (§7). Stating that here is what stops a later reader from "fixing" the asymmetry.

**A code defect never resolves itself on this route, and `withdrawn` is not the back door.** There is no `fixed` disposition, because nothing on the BRD-to-PRD route builds anything and no command can observe a repair. `withdrawn` means one thing only — the intent basis turned out to be wrong, so there was never a defect — and using it for a defect that was fixed would put a false statement in the log. A repaired defect keeps whatever disposition it had; the log records what was true of the pinned commit, exactly as the finding it cites does.

## 5. The writer, and where the log lives

**`<BRD-dir>/code-defect-log.md`, at the slice root beside `decisions.md`.**

**It is slice-owned, not parent-owned — the opposite of `brd/brd-defect-log.md`, and the asymmetry is stated because §1.1 trains a reader to reach one hop up for anything called a defect log.** A requirement defect belongs to the customer's source document, of which there is exactly one per parent. A code defect belongs to the slice's own grounding, and grounding is slice-only (`/prd-ground` stops a resolved root with `PRD_GROUND_ROOT_LEVEL`). There is no hop.

**`/brd-interview` is the only writer**, at two points that already exist:

- **Phase 6** *raises* an entry, held for the register phase exactly as a `[VD#n]` is.
- **Phase 9** *writes* the file, alongside `decisions.md` and the round record.
- **Phase 10** adds the path to `deliverable_paths`. This is the glob-coverage regression class: the handoff enumerates what the run wrote, and a new artifact missing from that enumeration is invisible to any search for `[CDF#n]`.

**`/prd-ground` is deliberately not a writer, and the reason is a cost asymmetry rather than a preference.** Its Phase 7 verifies every finding through `grounding-verifier`; a defect entry emitted there would raise *"is a defect claim itself verified?"*, needing an answer, a change to the `code-grounder` agent contract, and a second writer's worth of surface in the route's largest command. An entry written at interview time cites a finding that is **already** verified and adds only the intent basis, which is the operator's judgment either way. Nothing is lost that the route has authority over: the behaviour half is in the finding's verdict and evidence, and the intent half was never grounding's to give.

## 6. The register field

**`defects:` is a twelfth field on the `decision-register-format` §1 record**, listing the `[CDF#n]` ids this decision or assumption turns on, omitted when absent. It is what the original report meant by *"one register field removes that pressure"*.

**It is not `evidence`, and that distinction is load-bearing.** §1 defines `evidence` as the `[CG#n]`/`[DG#n]` findings a decision rests on, and §6's will-change rule (D19) **inspects that list** — it fires when every finding in it carries `horizon: will-change`. A `[CDF#n]` in `evidence` would silently change what D19 fires on, in a rule whose whole point is that a decision resting on ground that is about to move says so.

**The link runs one way only.** The `[CDF#n]` record carries no back-pointer. Two directions of one relation is a relation that drifts, and this is the direction maintained naturally: Phase 6 takes the argumentation and writes the `[VD#n]` in the same breath as raising the defect. A defect that bears on no decision is an ordinary entry with nothing pointing at it.

**§7's accounting goes from eleven fields to twelve, and that table is the likeliest thing this increment silently breaks.** §7 exists because *"which fields apply is not a detail an author may settle for themselves"*, and it discharges that by accounting for all eleven §1 fields on an `[AS#n]` one by one. A twelfth field added to §1 and not to §7 leaves a field an author must settle for themselves in the one place the file promises they never have to — and no search for `[CDF#n]` or for `defects:` would find the omission, because the gap is a row that is not there. `defects:` on an `[AS#n]` is **as-is**: an assumption can turn on a known defect exactly as a position can, omitted when absent.

## 7. The bundle — one exemption and its inverse

`code-defect-log.md` is **not** a bundle document. It reaches the customer through nothing: no part of the rendered prompt sends a reviewer to it, so `bundle-packaging` §1.1's allow-list withholds it by construction. It is nonetheless added to §1.1's **named** exclusions, beside `self-review-<YYYYMMDD>.md`, because that list exists for exactly the documents that are *"indistinguishable from a package document by filename alone"* and a file named `code-defect-log.md` sitting beside a `brd-defect-log.md` that **does** ship is precisely that.

**`decisions.md` does ship, so a `[CDF#n]` does reach the bundle.** §6.1's table enumerates eight identifier classes; an id of a ninth is not scanned at all, so a stray `[CDF#n]` would pass silently today. §6 therefore gains:

- **A `[CDF#n]` row in §6.1's table**, corpus **none**.
- **A third exemption in §6.3, in two parts.** A `[CDF#n]` **in `decisions.md`** is exempt: it names a delivery-side record the allow-list excludes, exactly as `[SR#n]` names one. A `[CDF#n]` **in any other bundle document** stops the run with `BRD_PACKAGE_DEAD_CITATION`.

**The second half is narrower than `[SR#n]`'s exemption on purpose.** `[SR#n]` is exempt *everywhere* because the rendered prompt cites it deliberately, in parts 7 and 9, as filtered content the customer may see. A `[CDF#n]` has exactly one sanctioned site, so everywhere else is a leak — into the prompt, the inventory, the ledger or a grounding file — and worth catching. **It fires on nothing today**, which is this repository's own measured criterion for taking a widening.

**The cost is stated rather than glossed: the customer will see an id they cannot resolve.** That is the acceptable side of §1.1's own asymmetry — *"a document wrongly withheld produces a reviewer question, and a document wrongly shipped cannot be recalled"* — and the rendered prompt never cites a `[CDF#n]`.

## 8. E-3b, and why the prose trigger is retired

The ledger anticipated a check on the trigger phrase — *"recorded as a defect against it"* against *"recorded as such"* — and required it be **measured against the tree first**, as this repository requires of any widening.

**That measurement is not available, and the finding is the reason the check is not built.** The tree holds **two** `argumentation:` examples in total, both illustrative, both in `decision-register-format`. There is no corpus of real registers anywhere in this repository, because the prose lives in customer artifacts. The evidence that justified shipping checks 8, 11, 15 and 16 — a pattern run over the live tree, firing on nothing or firing only on defects — cannot be produced here, and an unmeasurable prose proxy is the class `CLAUDE.md` records rejecting for stop routing. **Do not re-propose it without a corpus to measure against.**

What ships instead is two things, neither of which is a pattern:

**At write time — a structural offer.** `/brd-interview` Phase 6 offers to raise a `[CDF#n]` when, and only when, the decision's `evidence` holds a finding whose verdict is `REWRITTEN`, `AMENDED` or `FALSE-FRIEND` — the three verdicts that mean grounding established the code does something other than what was claimed. The trigger is read off the record, never out of prose. This is the half that actually fixes E-3b: it removes the pressure at the point where the prose was written.

**At package time — a reviewer dimension.** `brd-package-reviewer` is adversarial and already reads the register: an `argumentation` asserting that a defect is recorded, on a record whose `defects:` field is empty, is a finding it raises. Judgment about prose belongs to a reviewer, and the measurement problem does not apply to one.

## 9. The sweep, the counts and the version

**A new reference file has a fixed set of consequences, and one of them is not what it looks like.** `product-workflows` documents its reference files as **rows inside `docs/reference/references.md`**, not as one page each — that directory's eight pages are categories (`agents`, `environment`, `hooks`, `model-routing`, `references`, `resume-and-checkpoints`, `session-cost`, `session-feedback`), and nine reference files already share the one page. So the work is: a row in `references.md` (check 4 asserts the inventory in **both** directions), that page's own preamble count, an entry wherever `docs/README.md` reachability requires it (check 3), and check 9's prose counts. The new **artifact** — not the reference file — is documented on `docs/commands/brd-interview.md`, in both its opening summary and its outputs list, and on `docs/brd-workflow.md`.

**The count census, measured rather than assumed.** *"Nine reference"* appears at **six live sites**: `plugin.json`'s `description`, the `marketplace.json` entry's copy of it, `README.md`, `docs/reference/references.md`'s preamble, and `CLAUDE.md` twice (the `product-workflows` paragraph, and the plugin-update section's *"their twelve agents or their nine references"* — which a per-paragraph edit would miss). `CHANGELOG.md` carries a seventh and is history: leave it. Re-derive with `grep -rn 'nine reference' plugins/product-workflows/ CLAUDE.md` rather than trusting this list.

**The blurb, with the arithmetic done.** `product-workflows`'s `description` stands at 988 of 1024 and warns above 900 (ledger G3-4). The forced change is small — *"Nine"* to *"Ten"* is one character — so the trim the ledger anticipated is **not** forced by the count alone. It is forced by the sentence that follows it: the description names the formats its reference pages define, and adding `code-defect` to that list takes the blurb to roughly 1003, leaving about twenty characters of headroom, which is not a state to ship. **So the trim goes in, now with a measured reason.** Out comes the closing sentence — *"Depends on workflows-core for its shared foundation and phase handoff, and on prose-style, whose prose-style-checker is /epics's primary style checker"* — roughly 150 characters restating `plugin.json`'s machine-readable `dependencies` field, which is where a host actually reads it. That lands the blurb near 850 and clears G3-4's warning for this plugin as a side effect. **Both editions move together** — `plugin.json` and the `marketplace.json` entry — or `validate-catalog.py` fails on the mismatch; `marketplace.json` is edited in place and never reformatted.

**`CLAUDE.md`** takes the two count edits above plus the workflow map's `/brd-interview` line, which names what that command writes.

**The phrase sweep is scoped to `plugins/`, never to the plugin the capability ships from** — the family's shared authorities live in `workflows-core`, and a per-plugin recipe is structurally blind to them. Sweep for sentences asserting that the route has nowhere to record a code defect, that a finding is the only home for a code-level observation, or that a defect log is always the parent's. Run the **exclusivity probe** as its own axis — `only when`, `is the only`, `nothing else`, `and no other`, `only ever` — which is where a falsified claim hides when it names none of the vocabulary this change introduces. Back the phrase sweep with an end-to-end read of every phase this change touches: `/brd-interview` Phases 6, 9 and 10, `/brd-package` Phase 8, and `bundle-packaging` §1.1, §6.1 and §6.3.

**Versions.** `product-workflows` **3.3.0** — a new capability with a new artifact. `workflows-core` is untouched: `grounding-format` and `source-truth` are **cited** by the new reference, never edited.

**`check-id-grammar.sh` needs no change, and saying so is the point.** Its `PATTERN` polices the dash-separated form of `US|AC|SM|SMC|UC|FR|AD` only. `BR`, `CG`, `DG`, `DEF`, `VD`, `CD`, `AS` and `SR` are all already outside it, so `[CDF#n]` stays outside too. That is consistent, not an omission — do not "fix" it.

## 10. Out of scope, stated so a reader does not reintroduce them

- **The narrowing gap** recorded beside E-2. Its own entry, dormant, no shared vocabulary or consumer.
- **`/prd-ground` as a writer.** §5 states the cost asymmetry that decided it.
- **A `fixed` disposition, or any resolution the route cannot observe.** §4.
- **Generalising `source-truth` §7.5** into a shared code-defect record for `/document` and the route. §2 states the measurement that would have to come first.
- **A prose-trigger check on `argumentation`.** §8, and it does not return without a corpus.
- **Escalating a code defect into the interview as a `[V]` or `[C]` question.** A defect is a delivery-side work record settled by the operator; making it a customer question would need a §1.1 allow-list row, a prompt part that sends the reviewer to it, and `interview-tagging` integration.

## 11. Risks

**The offer's trigger is a proxy, and a defect can be found without one.** A decision whose evidence holds only `CONFIRMED` findings gets no offer, and an operator who knows about a defect can still write prose. The reviewer dimension is the backstop, and raising an entry is never gated on the offer — an operator may write one at any point in Phase 6.

**`intent_basis: operator-judgment` is the escape hatch, and it is meant to be one.** It is honest by construction — the record says a person decided — but nothing checks the reasoning behind it. That is the same standing `argumentation` has, and the same test applies: adequate when a reader who was not in the room can say what would have to change for the answer to change.

**A twelfth field on a record that ships is a permanent widening.** `defects:` reaches the customer's copy of `decisions.md` forever, as an id resolving to nothing in their hands. §7 argues that is acceptable; if it proves not to be, the repair is a rendering rule in `/brd-package`, not a retraction of the field.

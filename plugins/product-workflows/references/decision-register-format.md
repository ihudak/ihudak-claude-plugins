# Decision register format (embedded authority)

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

The canonical shape of the BRD→PRD workflow's **decision register**: the record every `[VD#n]`
(delivery-team decision) and `[CD#n]` (customer decision) carries, the five statuses one can hold,
the rule that makes `argumentation` mandatory, the rule that makes reopening explicit, what
`conditional_on` means and what it buys, the prohibition on a decision resting solely on a
`will-change` finding, and the `[AS#n]` assumption record that must reach the customer. Design
authority: `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §6.2 and decision rows
D14 and D19 in §3.

Three neighbouring rules are owned elsewhere and cited, not restated: the `horizon` a grounding
finding carries and the `[CG#n]`/`[DG#n]` finding record itself belong to
`workflows-core:grounding-format` (§5 and §2); the `[G]`/`[V]`/`[C]` tag that decides which register
a question's answer lands in, and the rounds a decision is stamped with, belong to
`references/interview-tagging.md` (§1 and §5); the `<BRD-KEY>` grammar a `conditional_on` uses
belongs to `workflows-core:addressing` §1.

**Consumed by `commands/brd-interview.md`**, which writes `[VD#n]` and `[AS#n]` records against this
shape and enforces §6; by `commands/create-prd.md`, which writes an `[AS#n]` — and only an `[AS#n]` —
for a customer-authority gap that only PRD authoring could surface (§7); by `agents/brd-package-reviewer.md`, which reads them; and by
`commands/brd-package.md`, which surfaces every open `[AS#n]` in the customer prompt (§7) and finds
every position resting on a prerequisite by its `conditional_on` field (§5); and by
`commands/brd-reconcile.md`, which writes the `[CD#n]` records — the only command that does —
supersedes the `[AS#n]` each one settles, reopens what an incoming customer decision overturns under
§4, and runs the propagation sweep §5 exists to serve.

## 1. Record shape

Each `[VD#n]` and `[CD#n]` carries:

```yaml
id: [VD#7]
statement: <the decision, one sentence>
options_considered: [<option>, <option>, ...]
chosen: <option>
argumentation: |
  <why — mandatory>
evidence: [[CG#12], [DG#3]]
defects: [[CDF#2]]                        # omitted unless the decision turns on a recorded code defect
altitude: product | architecture | implementation
conditional_on: <BRD-KEY>/<decision-id>   # omitted unless the decision depends on a prerequisite
status: open | decided | reopened | superseded | withdrawn
consumed_by: PRD | ARD | specification | none
round: 2
```

| Field | Notes |
|---|---|
| `id` | `[VD#n]` or `[CD#n]` — contiguous within its own prefix, assigned once, never renumbered, never reused after a terminal status |
| `statement` | one sentence, stating the decision itself and not the discussion that produced it |
| `options_considered` | what was actually on the table, including the one chosen |
| `chosen` | exactly one member of `options_considered` |
| `argumentation` | why — **mandatory**, §2 |
| `evidence` | the `[CG#n]`/`[DG#n]` findings the decision rests on, per `workflows-core:grounding-format` §2; the list is what §6 inspects |
| `defects` | the `[CDF#n]` code-defect entries this record turns on, per `references/code-defect-log-format.md`; omitted when absent. **Never in `evidence`** — §6's will-change rule inspects that list, and a non-finding id in it would silently change what D19 fires on |
| `altitude` | which level the decision sits at, so the spec's §7 altitude routing can send it to the right downstream artifact |
| `conditional_on` | omitted unless the decision depends on a prerequisite — §5 |
| `status` | one of the five in §3 |
| `consumed_by` | the same field, values, and starting-at-`none` rule as `workflows-core:grounding-format` §2, applied to a decision instead of a finding |
| `round` | the interview round that produced the decision, per `references/interview-tagging.md` §5 |

**Which prefix a decision gets is fixed by the tag of the question it answers, not by who typed it.**
A question tagged `[V]` produces a `[VD#n]`; a question tagged `[C]` produces a `[CD#n]`
(`references/interview-tagging.md` §1). A delivery-team position does not become a `[CD#n]` because
the customer later nodded at it, and a customer answer captured in free text does not become a
`[CD#n]` at all until an operator confirms it (D14) — the register records confirmed decisions, and
normalising prose into one is inference, not authority.

**`defects` is not `evidence`, and the separation is load-bearing rather than tidy.** `evidence`
holds `[CG#n]`/`[DG#n]` findings and §6 **inspects that list** — the will-change rule fires when
every finding in it carries `horizon: will-change`. A `[CDF#n]` placed there would change what D19
fires on, in the one rule whose whole purpose is that a decision resting on ground that is about to
move says so. The two fields also answer different questions: `evidence` says what established the
premise, and `defects` says what has to be repaired before the position can be delivered.

`options_considered` and `chosen` do not apply to an `[AS#n]`, which is not a choice; §7 accounts
for all twelve of these fields on an assumption record, one by one.

## 2. `argumentation` is mandatory

There is no valid record with an empty `argumentation`. Not "to be filled in later", not a restated
`statement`, not the name of whoever decided it.

**A decision without a recorded reason cannot be defended when the customer challenges it weeks
later.** The challenge arrives long after the context has evaporated: the constraint that made the
chosen option the only workable one, the option that looked better until a finding ruled it out,
the cost the rejected alternative would have carried. Without that written down, the delivery team
is defending a position it can no longer explain, in front of the party that has to live with it.
What is actually on the page — "we chose B" — reads as arbitrary, and a position that reads as
arbitrary loses whether or not it was right.

**And it cannot be safely reopened.** Reopening a decision means deciding whether the new
information changes the answer, which is impossible without knowing what the old answer turned on.
A reopening that cannot see the original reasoning is not a reopening; it is a fresh decision
wearing the old one's identifier, and it will silently drop whatever constraint the first pass
respected and the second pass never learned about.

The test for sufficiency is the one implied by both failures: **argumentation is adequate when a
reader who was not in the room can say what would have to change for the answer to change.** A
reason that survives being read back a month later names the constraint, not the preference.

## 3. Statuses

Exactly five.

| Status | Meaning |
|---|---|
| `open` | Raised, not yet settled. A decision may not be consumed downstream while it is open |
| `decided` | Settled, with `chosen` and `argumentation` filled in |
| `reopened` | Was `decided`, and a cause under §4 has reopened it |
| `superseded` | Replaced by a later decision, which the record names; the identifier is retained, never reused |
| `withdrawn` | No longer asked for at all — the question stopped applying rather than being answered |

**`withdrawn` is first-class, and it is not a tidier spelling of `superseded`.** A superseded
decision was answered and then answered differently; a withdrawn one stopped being a question. The
case that earns it the status: the delivery team records a request — say, an amendment to the source
BRD — and the customer's answer to some *other* question makes that request unnecessary. Nothing
replaced it, and nothing about it is still true, so `superseded` would be a lie and leaving it
`open` would be worse.

Worse, specifically, in the customer's copy. **A request that is still `open` keeps appearing in
customer-facing text**, because that is what open requests are for. So the customer receives, in the
next package, a request they already dealt with — which reads either as the delivery team not having
read their answer, or as a second bite at something they thought was closed. `withdrawn` is the
status that stops the asking without falsifying the record: the request is still there, still
identified, still carrying the reason it was withdrawn, and it is no longer requested of anybody.

`superseded` and `withdrawn` are terminal. `decided` is not: §4 is the one route out of it.

## 4. Reopening is explicit

**Only two things may reopen a decision:**

1. **A new grounding finding** that bears on it — including a finding that supersedes one already in
   the decision's `evidence` list (`workflows-core:grounding-format` §3).
2. **An incoming customer decision** that contradicts or constrains it.

Nothing else. Not a later reader's discomfort, not a fresh idea, not a review pass that would have
decided differently. A decision the register holds as `decided` is settled until one of those two
arrives.

**The reopening records its cause**, naming the finding or the customer decision that triggered it.
A `reopened` record whose cause is unnamed is indistinguishable from someone simply changing their
mind, and once one of those exists nobody can trust that the rest were caused either. The cause is
also what the eventual re-decision is argued against under §2: it names what changed, so the new
`argumentation` can say why that change moves the answer — or, just as legitimately, why it does not
and the original `chosen` stands.

The rule's purpose is not ceremony. A register that can be reopened freely is a register whose
`decided` status means nothing, and a customer who signed off on a set of decisions signed off on
something that can drift underneath them. Bounding reopening to two external causes is what makes
"decided" a claim about the world rather than about the moment.

**A worked consequence — a sibling that holds decisions cannot receive a re-pointed row.** `references/coverage-ledger-format.md` §3.2 lets a parent's walk move a requirement its owner recorded `deferred-to` against onto a sibling BRD that has not been interviewed, and *has not been interviewed* is this rule read from the other end: giving that sibling new scope would put a requirement in front of a register that decided its scope without it, and neither cause above has arrived — no new grounding finding, and no incoming customer decision. So a folder holding a `decisions.md` with a `[VD#n]` or `[CD#n]` in it is closed to a re-cut. **The converse does not follow and is not stated here**: §3.2's eligibility test is broader than this clause — it also refuses a folder holding an `interview/round-*.md`, which is a customer conversation that has started whether or not it froze a record — so eligibility is never inferred from the absence of a decision record alone. This file states the rule; §3.2 executes it, and the test a run actually applies is that section's to fix.

## 5. `conditional_on`

`conditional_on: <BRD-KEY>/<decision-id>` records that **this decision is correct only while a named
decision of a named prerequisite BRD holds.** The key follows the grammar in
`workflows-core:addressing` §1; the second half names one specific decision in that BRD's own
register, never the BRD as a whole — a prerequisite carries many decisions and only one of them is
the one this position rests on.

The field is omitted entirely when the decision depends on no prerequisite. An empty or
placeholder `conditional_on` is worse than an absent one: it looks like a dependency somebody
forgot to finish naming.

**What it buys is findability.** A position built on a prerequisite is not wrong — often it is the
only sensible position available while the prerequisite is still in flight. What makes it dangerous
is that it is *invisible*: when the prerequisite's decision changes, nothing about this decision's
own text says it should be re-examined, and the drift is discovered by whoever eventually notices
that two BRDs disagree. `conditional_on` is what makes `/brd-reconcile`'s propagation sweep able to
find this decision mechanically when that prerequisite's decisions change, instead of relying on
somebody remembering — which is why that sweep takes the `conditional_on` positions first, before it
looks for anything citing a changed id in prose. A conditional decision that does not say so is exactly
the decision a sweep cannot reach.

It follows that `conditional_on` is written by whoever takes the decision, at the moment they take
it, and not reconstructed later. The person who knows the position rests on a prerequisite is the
person taking it; a sweep cannot infer the dependency from a `statement` that never mentions it.

## 6. The will-change rule (D19)

**A decision may not rest solely on a `will-change` finding.** Where *every* finding in a decision's
`evidence` list carries `horizon: will-change` (`workflows-core:grounding-format` §5), the decision
may not be closed as `decided`, and `/brd-interview` refuses to close it.

The reason is the one D19 states: a finding is true of a pinned commit, and a `will-change` finding
is one an approved-but-unbuilt prerequisite is going to make false. A decision resting on nothing
else is standing on ground that is about to move — correct today, wrong the moment the prerequisite
ships, and nothing in the record would say so.

Three resolutions, and exactly three:

| Resolution | Recorded as |
|---|---|
| Re-base it on a `current` finding | the decision's `evidence` list changes |
| Make it explicitly conditional on the prerequisite | `conditional_on: <BRD-KEY>/<decision-id>` |
| Defer it until the prerequisite ships | `status: open`, with the blocking prerequisite named |

Two things the rule does not say. It does **not** forbid a `will-change` finding in an `evidence`
list — a decision resting on one `current` finding and two `will-change` ones is not caught, because
the `current` finding is ground that holds. And it is **not** satisfied by deleting the
`will-change` finding from the list: a decision whose evidence was thinned until the rule stopped
firing rests on exactly what it rested on before, minus the record of it.

## 7. Assumptions — `[AS#n]`

An `[AS#n]` records **something the package asserts without evidence.** It is not a decision: nothing
was chosen, so nothing was weighed. It uses the same twelve fields as §1, and because `/brd-package`
puts every open one of them in front of the customer (below), which fields apply is not a
detail an author may settle for themselves. All twelve are accounted for here.

| §1 field | On an `[AS#n]` |
|---|---|
| `id` | **As-is**, under its own prefix: `[AS#1]`, `[AS#2]`, … contiguous within that prefix, assigned once, never renumbered or reused |
| `statement` | **As-is**: one sentence, saying what is assumed — the assumption itself, never the reason for it and never the reason it is unevidenced |
| `options_considered` | **Not applicable.** An assumption is an assertion, not a choice between options; a record that weighs options is a decision and takes a `[VD#n]` or `[CD#n]` |
| `chosen` | **Not applicable**, for the same reason: there is nothing to choose from |
| `argumentation` | **Different meaning**, still mandatory: for a decision it says why this option beat the others (§2); here it says **why the package is proceeding on the assumption rather than stopping to establish it** — what establishing it would cost, and what depends on not waiting |
| `evidence` | **Different meaning**, still never blank: it holds **no** `[CG#n]`/`[DG#n]` ids, and instead carries the explicit statement of **why no evidence exists** — see below |
| `altitude` | **As-is**: an assumption sits at a level like anything else, and the spec's §7 routing needs it for the same reason |
| `conditional_on` | **As-is**, and omitted when absent: an assumption can rest on a prerequisite's decision exactly as a position can, and §5's sweep must be able to reach it for exactly the same reason |
| `defects` | **As-is**, and omitted when absent: an assumption can turn on a known code defect exactly as a position can, and the customer who reads the assumption needs the same access to what would have to be repaired |
| `status` | **Narrowed vocabulary**, from §3's five: an `[AS#n]` reaches `open`, `superseded` and `withdrawn` only. `decided` cannot apply — an assumption is never settled by being chosen; when the customer confirms it, the confirmation is a `[CD#n]` and the assumption is `superseded` by it (below). `reopened` follows `decided`, so it is unreachable too |
| `consumed_by` | **As-is**, with the same starting-at-`none` rule |
| `round` | **As-is where there is one, and omitted where there is not.** An assumption recorded in an interview round carries that round. One recorded outside any round — `/create-prd` writing a customer-authority gap at PRD authoring (below) — **omits the field entirely**, per §2.1's rule that a field which does not apply is omitted rather than written empty. It is not given the last closed round's number, which would claim it was in front of whoever answered that round, and not given an invented value, which `/brd-package` would read as a round and demand a round record for |

**`evidence` is the field that carries the why-no-evidence explanation.** This is the same
discipline `workflows-core:grounding-format` §2 applies to a finding asserting an absence — an
explicit statement of what was searched and why it fell short, rather than an empty field — applied
to the record whose whole content is an absence. It does not go in `statement`, which holds the
assumption and nothing else, and it does not go in `argumentation`, which answers a different
question: `argumentation` says why we are proceeding anyway, `evidence` says why we cannot do
better. A reader who confuses the two ends up with a record that argues for the assumption while
never admitting it is one.

A worked `[AS#n]` against a synthetic BRD `EPIC-008`:

```yaml
id: [AS#4]
statement: The upstream feed emits one record per transaction, not one record per batch.
argumentation: |
  Every read path this package describes assumes per-transaction grain. Establishing the
  grain needs a sample the customer has not sent; waiting for one blocks the whole package,
  and proceeding on a stated assumption the customer can correct in one sentence is cheaper
  than stalling.
evidence: |
  No evidence exists. Nothing in the pinned commit reads this feed — searched the ingestion
  paths at the pinned commit and found no reader — so the repository cannot settle the grain
  either way, and no [CG#n] was produced for it.
altitude: implementation
status: open
consumed_by: none
round: 1
```

A bare sentence with no account of its own groundlessness is a claim, not an assumption record.

**§6 cannot fire on an `[AS#n]`.** The will-change rule tests the horizons of the findings in an
`evidence` list, and an assumption's list holds none. That is not a loophole to route a shaky
position through: a record with findings behind it is not an assumption, and calling one an
assumption to escape §6 is the evidence-thinning §6 already refuses.

**Every open `[AS#n]` is surfaced in the customer prompt.** Not the ones that seem material, not the
ones somebody remembered — every open one, automatically, because the selection step is where this
rule would fail. `/brd-package` does the surfacing, twice over — once where the customer is asked to
decide, and once where they are invited to attack; this file fixes that no assumption is exempt.

**An assumption that never reaches the customer is a liability disguised as a fact.** It was written
down as an assumption by someone who knew it was one, and every reader after that meets it as a flat
statement in a package full of grounded findings. Nothing in the sentence distinguishes it from the
findings around it, so it is read as settled, built on, and argued from. The customer is the one
party who could have said "no, it does not work like that" in a single sentence — and they are the
one party who was never shown it. Surfacing every open assumption is what converts the cheapest
possible correction into one the customer can actually make.

**`/brd-interview` is not the only writer, and the second one is why this record exists at all.**
An assumption is recorded wherever the delivery team first has to assert something without evidence,
and that is not always during an interview: `/create-prd` authoring a slice's PRD reaches questions
**only PRD authoring surfaces** — a scope boundary the requirement text never drew, a rule the
acceptance criteria need and nobody stated — and some of them are settled by an authority only the
customer holds (`interview-tagging.md` §2). Written into the PRD's `## Assumptions & open questions`
alone, such a question reaches nobody: the customer never receives `prd.md`. Written as an `[AS#n]`,
it reaches them automatically, because `/brd-package` surfaces every open one. **That is the whole
route back, and it needs no new machinery** — which is the answer to the objection that a PRD-stage
question has missed the interview: the assumption record was always the mechanism for a thing
asserted without evidence, and when it was written matters less than that the customer sees it.

**Such a record carries no `round` at all, and the omission is the whole of the mechanism.** An
assumption recorded at PRD authoring belongs to no interview round. Giving it the last closed round's
number would claim it was in front of whoever answered that round; giving it any *invented* value is
worse, because **`round` is read, not just displayed** — `/brd-package` derives the set of rounds a
BRD has from the distinct `round` values across its `[VD#n]` and `[AS#n]` records, and then requires
an `interview/round-<N>.md` for each. A record carrying a value no round record answers to makes the
BRD permanently unpackageable, which is the precise opposite of why this record exists. Omitting the
field leaves that derivation reading exactly the rounds that happened, and `[AS#n]` records with no
round contribute nothing to it — which is correct, because they came from no round.

An `[AS#n]` that the customer confirms does not silently become a fact: their confirmation is a
customer decision, entering the register as a `[CD#n]` under §1's confirmation rule (D14), with the
assumption recorded as `superseded` by it. An `[AS#n]` the customer contradicts is `superseded` the
same way, by the decision that contradicts it, and everything that was built on it is reopened under
§4 — the incoming customer decision is precisely one of the two causes that rule admits.

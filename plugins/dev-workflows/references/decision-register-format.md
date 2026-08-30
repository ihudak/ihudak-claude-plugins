# Decision register format (embedded authority)

The canonical shape of the BRD→PRD workflow's **decision register**: the record every `[VD#n]`
(delivery-team decision) and `[CD#n]` (customer decision) carries, the five statuses one can hold,
the rule that makes `argumentation` mandatory, the rule that makes reopening explicit, what
`conditional_on` means and what it buys, the prohibition on a decision resting solely on a
`will-change` finding, and the `[AS#n]` assumption record that must reach the customer. Design
authority: `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §6.2 and decision rows
D14 and D19 in §3.

Three neighbouring rules are owned elsewhere and cited, not restated: the `horizon` a grounding
finding carries and the `[CG#n]`/`[DG#n]` finding record itself belong to
`references/grounding-format.md` (§5 and §2); the `[G]`/`[V]`/`[C]` tag that decides which register
a question's answer lands in, and the rounds a decision is stamped with, belong to
`references/interview-tagging.md` (§1 and §5); the `<BRD-KEY>` grammar a `conditional_on` uses
belongs to `references/brd-addressing.md` §1.

**Consumed by nothing yet.** `/brd-interview` will write `[VD#n]` and `[AS#n]` records against this
shape and enforce §6; `/brd-package` will surface every open `[AS#n]` in the customer prompt (§7);
`/brd-reconcile` will write `[CD#n]` records from a returned review and run the propagation sweep
that §5 exists to serve. None of those commands exists, and no shipped command or agent reads this
file today.

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
| `evidence` | the `[CG#n]`/`[DG#n]` findings the decision rests on, per `references/grounding-format.md` §2; the list is what §6 inspects |
| `altitude` | which level the decision sits at, so the spec's §7 altitude routing can send it to the right downstream artifact |
| `conditional_on` | omitted unless the decision depends on a prerequisite — §5 |
| `status` | one of the five in §3 |
| `consumed_by` | the same field, values, and starting-at-`none` rule as `references/grounding-format.md` §2, applied to a decision instead of a finding |
| `round` | the interview round that produced the decision, per `references/interview-tagging.md` §5 |

**Which prefix a decision gets is fixed by the tag of the question it answers, not by who typed it.**
A question tagged `[V]` produces a `[VD#n]`; a question tagged `[C]` produces a `[CD#n]`
(`references/interview-tagging.md` §1). A delivery-team position does not become a `[CD#n]` because
the customer later nodded at it, and a customer answer captured in free text does not become a
`[CD#n]` at all until an operator confirms it (D14) — the register records confirmed decisions, and
normalising prose into one is inference, not authority.

`options_considered` and `chosen` do not apply to an `[AS#n]`, which is not a choice; see §7 for
what an assumption record carries instead.

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
   the decision's `evidence` list (`references/grounding-format.md` §3).
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

## 5. `conditional_on`

`conditional_on: <BRD-KEY>/<decision-id>` records that **this decision is correct only while a named
decision of a named prerequisite BRD holds.** The key follows the grammar in
`references/brd-addressing.md` §1; the second half names one specific decision in that BRD's own
register, never the BRD as a whole — a prerequisite carries many decisions and only one of them is
the one this position rests on.

The field is omitted entirely when the decision depends on no prerequisite. An empty or
placeholder `conditional_on` is worse than an absent one: it looks like a dependency somebody
forgot to finish naming.

**What it buys is findability.** A position built on a prerequisite is not wrong — often it is the
only sensible position available while the prerequisite is still in flight. What makes it dangerous
is that it is *invisible*: when the prerequisite's decision changes, nothing about this decision's
own text says it should be re-examined, and the drift is discovered by whoever eventually notices
that two BRDs disagree. `conditional_on` is what makes the propagation sweep `/brd-reconcile` will
run (spec §8.7) able to find this decision mechanically when that prerequisite's decisions change,
instead of relying on somebody remembering. A conditional decision that does not say so is exactly
the decision a sweep cannot reach.

It follows that `conditional_on` is written by whoever takes the decision, at the moment they take
it, and not reconstructed later. The person who knows the position rests on a prerequisite is the
person taking it; a sweep cannot infer the dependency from a `statement` that never mentions it.

## 6. The will-change rule (D19)

**A decision may not rest solely on a `will-change` finding.** Where *every* finding in a decision's
`evidence` list carries `horizon: will-change` (`references/grounding-format.md` §5), the decision
may not be closed as `decided`, and `/brd-interview` will refuse to close it once that command
exists.

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

An `[AS#n]` records **something the package asserts without evidence.** It is not a decision and
carries no `options_considered` and no `chosen`; it reuses §1's `id`, `statement`, `status`, `round`
and `consumed_by`, and its `evidence` list is empty by definition — an assumption with evidence is a
finding, and a choice between assumptions is a decision.

What replaces `evidence` is the same discipline `references/grounding-format.md` §2 applies to a
finding that asserts an absence: **the record says why no evidence exists** — what was assumed, and
what would have to be true for it to hold. "Assumed: the source system emits one record per
transaction; nothing in the pinned commit reads that feed, so nothing here can confirm it" is an
assumption record. A bare sentence with no account of its own groundlessness is a claim.

**Every open `[AS#n]` is surfaced in the customer prompt.** Not the ones that seem material, not the
ones somebody remembered — every open one, automatically, because the selection step is where this
rule would fail. `/brd-package` will do the surfacing once it exists; this file fixes that no
assumption is exempt.

**An assumption that never reaches the customer is a liability disguised as a fact.** It was written
down as an assumption by someone who knew it was one, and every reader after that meets it as a flat
statement in a package full of grounded findings. Nothing in the sentence distinguishes it from the
findings around it, so it is read as settled, built on, and argued from. The customer is the one
party who could have said "no, it does not work like that" in a single sentence — and they are the
one party who was never shown it. Surfacing every open assumption is what converts the cheapest
possible correction into one the customer can actually make.

An `[AS#n]` that the customer confirms does not silently become a fact: their confirmation is a
customer decision, entering the register as a `[CD#n]` under §1's confirmation rule (D14), with the
assumption recorded as `superseded` by it. An `[AS#n]` the customer contradicts is `superseded` the
same way, by the decision that contradicts it, and everything that was built on it is reopened under
§4 — the incoming customer decision is precisely one of the two causes that rule admits.

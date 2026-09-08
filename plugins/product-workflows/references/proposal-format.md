# Effort-proposal format (embedded authority)

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

The canonical shape of the two artifacts `/prd-proposal` and `/brd-proposal` write: the section set
each carries, the two identifier namespaces they mint, the readiness tiers that cap confidence, the
confidence grades that fix the range, the closed set of evidence classes a cost driver may cite, and
the rules a reviewer checks. Design authority:
`docs/superpowers/specs/2026-09-08-proposal-commands-design.md`.

**Written by `commands/prd-proposal.md` and `commands/brd-proposal.md`; reviewed against by
`agents/proposal-reviewer.md`.** The one command that reads a proposal is `commands/brd-proposal.md`,
which rolls each slice's into the umbrella; nothing else in the family opens one.

## 1. What this format governs, and the two quantities it must never conflate

An effort proposal states **what human delivery time a requirement set will take, in hours** — by
work package, by role, as a range, with an argument for the number that resolves to records on disk.

**The family already measures a different quantity called "cost".** `workflows-core:cost-emission`
records **model spend in USD** for a run of a command. The two are unrelated, and no sentence in
either artifact, in either command, or in this file may let a reader take one for the other.

**Neither artifact carries money at all** — no rate, no currency symbol, no monetary total for human
hours, at any tier, under any flag. Rates are contractual and belong in a document this pipeline does
not produce, and a git-committed rate card is a disclosure waiting to happen.

**A proposal gates nothing on the build ladder.** `/create-ard`, `/specify`, `/epics`, `/design`,
`/implement` and `/ready` each resolve the same folder and neither know nor care whether it holds a
proposal: none requires one, reads one, or behaves differently because one exists, and no grade in this
file withholds permission to begin work. The one command that does read a proposal is `/brd-proposal`,
which gates on a slice's in order to roll it into the umbrella — a second proposal rather than a phase
of the build. A proposal is a document a vendor sends a customer; it is not a phase and never a
prerequisite for building anything.

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
| 15 | What the range does **not** cover | §9 — a different list from section 20 |
| 16 | Engagement governance | shaped by `engagement_model` — cadence, reporting, who accepts on each side, and what each model makes of all three |
| 17 | Change control | shaped by `engagement_model` |
| 18 | Scope levers and priced options | shaped by `engagement_model` — the `[WP#n]`s that may be dropped, deferred or taken up, and what each does to the range. **This is the priced-options table §7's defect-package prohibition names**, and a defect-remediation package never renders in it |
| 19 | Acceptance | per package, which is why a package must be independently acceptable |
| 20 | Exclusions from scope | |
| 21 | Traceability | requirement identifiers → `[WP#n]`, in the form §11 fixes |
| 22 | Reconciliation to a prior estimate | **conditional** — renders only under `--baseline`; absent is not a gap and is never apologised for |
| 23 | Changelog | **conditional** — renders only on a revision; §12 |

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
property is load-bearing: sections 9 and 19 of §4 both rest on it, and a package that cannot be
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

**This is a different list from section 20, exclusions from scope**, and conflating them is how a
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
| 3 | Reconciliation to their prior estimate | §4 section 22, where `--baseline` was given |
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

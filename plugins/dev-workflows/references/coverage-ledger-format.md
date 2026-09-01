# Coverage ledger format (embedded authority)

The canonical shape of the **coverage ledger** (`coverage-ledger.md`): the row a BRD (business
requirements document) keeps per requirement, the states that row can carry, and the rule that
blocks a split until every row has one. Design authority:
`docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §4, §4.1. Requirement and defect
identifiers (`[BR#n]`, `[DEF#n]`) are defined once in `references/brd-format.md` — cited here, not
restated; key grammar and folder resolution are defined once in `references/addressing.md`.

## 1. Purpose

The coverage ledger is **the only place a requirement's fate is recorded.** Every other BRD
artifact — the inventory, the defect log, the grounding findings, the decisions — describes what a
requirement says or what is known about it. Only the ledger says what happened to it: built here,
owned by another named BRD, deferred, rejected, or superseded.

This matters most on the failure a long BRD invites: one BRD is split into several children, each
child looks at the same requirement, and each one — independently, reasonably — decides it is
somebody else's problem to build. No single child did anything wrong; nothing built the
requirement anyway, and nothing noticed, because nowhere recorded that every child had waved it
past. The ledger exists to make that failure visible: a row left `unallocated` (§3), or a set of
rows that resolve to nothing but `covered-by` pointing at each other's children, is a fact the
ledger states plainly rather than a gap that only a careful re-read of every child would surface.

**The ledger line is where that promise is kept.** A `covered-by` row records which BRD owns a
requirement, not that any BRD built it, so §6 resolves every one of them one hop through the named
BRD's own ledger before it counts anything — the named child on a source-owning BRD, the named
sibling or parent on a slice (§3): a requirement that BRD deferred, rejected or never allocated is
reported as exactly that, and the line names how many were delegated and then not built. Counting
`covered-by` as covered on its own word is what would let the failure above pass this file's own
arithmetic unremarked.

One ledger exists per BRD, at either level a `<BRD-KEY>` can name — a BRD that owns its source
document, or a slice one level inside it (`references/addressing.md` §6 caps nesting there). **What
its rows are is not the same at both levels**, and §3's creator table is the authority: a
source-owning BRD gets one row per `[BR#n]` in the inventory `/brd-intake` extracted, while a slice
gets one row per `[BR#n]` its `brd-link.md` claims **at the moment `/brd-split` creates it**. That
is a floor, not a ceiling: a slice's ledger can later hold a row `claims:` no longer names, and §2
says why. Only a slice has a `claims:` field — `/brd-split` writes it, and only into a child — so a
consumer that defines a BRD's requirement set over `claims:` at both levels reads an empty set on
every source-owning BRD, which is every parent.

## 2. Row shape

| Field | Meaning |
|---|---|
| `id` | `[BR#n]` — the requirement this row tracks, per `brd-format.md` §2 |
| `text` | the requirement, verbatim, or its first sentence plus a source anchor, same convention as the inventory row it mirrors |
| `disposition` | exactly one of the six values in §3 |
| `defects` | a `[DEF#n]` list — the defects (`brd-format.md` §3) raised against this requirement, empty when it carries none |
| `evidence` | a `[CG#n]` / `[DG#n]` list — the grounding findings that bear on this requirement, empty until grounding has run |

A row's `id` is permanent for the same reason its inventory counterpart is (`brd-format.md` §2):
once a ledger row exists for a `[BR#n]`, it is never deleted and never renumbered, even after the
row reaches a terminal disposition.

**On a slice, `claims:` may therefore name fewer rows than the ledger holds.** `/brd-split` Phase 3
writes a child's `claims:` list **provisionally** and seeds one `unallocated` ledger row per claimed
`[BR#n]`; Phase 4's walk on the **parent's** ledger is what actually allocates, and it may settle a
provisionally-claimed `[BR#n]` somewhere other than that child. When it does, the `claims:` entry
and the copied `brd/brd-inventory.md` row are withdrawn together — a slice's inventory is defined
over `claims:` (`brd-format.md` §2.1) — and **the ledger row stays**, because the rule above admits
no exception and because deleting it would erase the one record that a claim was made and
withdrawn. Such a row is called an **orphan row** below.

An orphan row is never left `unallocated`: the same step that withdraws the claim writes it to the
terminal disposition that walk settled (§3), so it never blocks §4 and the slice can still complete
its own split. Its `text` and `defects` are the ones already copied into it, which is why it stays
readable with no inventory row beside it; its `evidence` stays empty, because `/brd-ground` grounds
a slice's *inventory* and an orphan row is not in one.

## 3. Dispositions

Exactly six. Only the last one blocks the gate in §4.

| Disposition | Meaning |
|---|---|
| `covered-here` | This folder builds it; a `PRD-` slice folder carrying one is therefore PRD-eligible (§5). Never written on a root: a container builds nothing itself |
| `covered-by: <BRD-KEY>` | A named BRD owns it. On a BRD that owns its source document the key is a **child**; on a slice it is a **sibling under the same parent, or that parent** — never a child, because none can exist below a slice (see below) |
| `deferred-to: <this BRD>` | Kept as a live obligation of this BRD, not built now |
| `rejected: [DEF#n]` | Not built, citing the `[DEF#n]` that justifies rejecting it |
| `superseded-by: [BR#n]` | Replaced by another requirement, named by its `[BR#n]` |
| `unallocated` | The initial state; the only one of the six that blocks §4 |

**`unallocated` is the state every row is written in when its ledger is first built** — no row
starts in any other disposition.

**Two commands create a ledger, one per level, and both seed every row `unallocated`:**

| Level | Creator | Rows |
|---|---|---|
| A BRD with a source document of its own | `/brd-intake` (`commands/brd-intake.md` Phase 5) | one per `[BR#n]` in the inventory it just extracted |
| A slice — nested in its parent's folder as a `PRD-` folder | `/brd-split` (`commands/brd-split.md` Phase 3) | one per `[BR#n]` the slice's `brd-link.md` claims |

`/brd-intake` never runs on a slice — a slice has no document to intake (`brd-format.md` §2.1) — so
if `/brd-split` did not write the slice's ledger at the moment it created the slice's folder,
nothing ever would, and the slice could never be ground in its own right: `/brd-ground` Phase 0
gates on that ledger. `/brd-split` is also the only command holding both the parent's rows and the
allocation that says which of them the slice claims.

**Two commands write a disposition once the ledger exists, and they write different subsets.**
`/brd-split` walks every `unallocated` row to a terminal disposition (§4), and it is the only command
that may write `covered-here` or `covered-by`: allocation — which BRD builds a requirement — is that
walk and nothing else. `commands/brd-reconcile.md` moves a row to `deferred-to`, `rejected` or
`superseded-by` when a frozen `[CD#n]` settles the requirement's fate differently; it never
allocates, because a customer decision is not a statement about which BRD in the delivery
organisation owns the work, and **no command ever moves a row back to `unallocated`** — that is the
initial state, and returning a row to it would reopen a gate that has already been satisfied.

**A slice's ledger is walked by `/brd-split` like any other.** The one-level cap stops that run
from creating children below the slice; it does not stop it from allocating the slice's own rows
(`commands/brd-split.md` Phase 0 step 5 — a notice, not a stop). Otherwise every row of every slice
would stay `unallocated` forever and no slice could ever satisfy §5, which is the same allocation
deadlock §1 exists to prevent, reached from the other direction. The same requirement therefore
carries a fate twice, at two levels, and the two say different things: `covered-by: <CHILD-KEY>` on
the parent's ledger records **which** BRD owns it, and the slice's own row records **what that BRD
decided to do with it**. A requirement whose provisional claim was withdrawn carries it a third
time, on the slice that no longer claims it — an **orphan row** (§2), which records neither of
those but the fact that this slice claimed it and does not any more, naming the BRD that took it.

**`covered-by` is the one disposition whose meaning depends on level, and the only one with a
different writer at each.** On a BRD that owns its source document it names a **child** and is
written by that BRD's own Phase 4 walk. On a slice it names a **sibling under the same parent, or
that parent**, and is written by the **parent's** Phase 4 walk — never by the slice's own. It is
never a child at either level below the root: nesting is capped at one level
(`references/addressing.md` §6), so **no child can exist below a slice** and no key a slice
writes could name one.

**The slice form exists for exactly one state — an orphan row (§2) — and for no other.** A slice's
`covered-by` row is a provisional claim the parent's walk withdrew, and the key it carries is
whichever BRD that same walk allocated the requirement to:

| The parent's walk settled the provisionally-claimed row | The withdrawn slice's orphan row reads |
|---|---|
| `covered-by: <SIBLING-KEY>` — another child builds it | `covered-by: <SIBLING-KEY>` |
| `covered-here` — the parent builds it | `covered-by: <PARENT-KEY>` |
| `deferred-to: <the parent>` — a live obligation of the parent | `covered-by: <PARENT-KEY>` |
| `rejected: [DEF#n]` | `rejected: [DEF#n]` |
| `superseded-by: [BR#n]` | `superseded-by: [BR#n]` |

The last two carry across unchanged because they say the same thing at either level. Each cites an
id that is the **parent's** — the `[DEF#n]` in the parent's defect log, the `[BR#n]` in the parent's
inventory — and a slice resolves both one hop up, exactly as it already resolves the `[DEF#n]` on a
row it claims (`brd-format.md` §2.1, §4). So the replacing `[BR#n]` on an orphan row need not be one
this slice claims or holds a row for; §6.3 excludes that row from this slice's counts either way and
says where a reader follows the obligation.

The first three all say *another BRD owns this*, which is what `covered-by` means and what none of
the other five can say: `deferred-to: <this BRD>` would falsely book it as the slice's own live obligation,
and `superseded-by` names a requirement, not a BRD. Both keys resolve: `resolve-address` finds a
sibling one level under `specifications/` and the parent at the top level
(`references/addressing.md` §3), so neither form names a folder that does not exist.

**This is not a general-purpose delegation, and a slice's own walk never writes it.** Every row a
slice's walk visits is a row that slice `claims:` — a row the parent's ledger allocated *here*.
Delegating one onward from inside the slice would contradict the parent's ledger about which BRD
owns it, and would point at a sibling whose own inventory holds no row for that `[BR#n]` at all. So
the slice form is confined to rows the parent withdrew, which the parent writes at the moment it
withdraws them (`commands/brd-split.md` Phase 4) and which are therefore never `unallocated` when
the slice's walk runs. §4's disclaimer about the command owning its own interaction flow is
unchanged: which resolutions a picker offers stays `commands/brd-split.md`'s to state.

### 3.1 What `covered-by` means downstream — the row leaves this BRD's scope

**A `covered-by` row's requirement is not this BRD's to question, to decide, or to put to a
customer.** §3 says the named BRD *owns* it; ownership is the whole content of the disposition, and
a BRD that owns nothing about a requirement has nothing to ask about it. Every consumer that puts a
requirement in front of a human therefore reads it over the rows this BRD is answerable for —
`covered-here`, `deferred-to`, `rejected` and `superseded-by` — and **never over a `covered-by`
row.**

**Which consumers, and why each needs saying.** `commands/brd-interview.md` generates its round from
the findings and the inventory; `commands/brd-package.md` states the review's scope to the customer
from the ledger and the inventory. **The inventory is the wrong set at one of the two levels**, and
that asymmetry is the whole reason this section exists: a slice's inventory is exactly the rows it
claims (`references/brd-format.md` §2.1), so a slice is correctly scoped by reading it — while a
source-owning BRD's inventory holds **every** `[BR#n]`, including the ones its own walk delegated. A
consumer that reads the inventory alone is therefore right on a slice and wrong on a split parent,
which is the shape a defect hides in longest: it is invisible on the level most runs exercise.

**The failure it prevents is a customer asked the same question twice.** The parent raises a
question about a delegated `[BR#n]`; the child, ground and interviewed on its copied row for that
same id, raises it again; both reach a package, and the customer answers one requirement in two
reviews. `references/interview-tagging.md` §5 names that outcome for the within-a-BRD case — "asking
a customer the same question twice is not an inefficiency, it is an invitation to a different
answer, and two customer answers to one question is a contradiction the decision register has no way
to resolve" — and the cross-level case is the same failure, reached by a different route. It costs
two `[VD#n]` records in two registers that can disagree about one requirement with nothing linking
them.

**In scope as context, out of scope as subject.** A delegated row is not struck from the reader's
view: what this BRD keeps may genuinely turn on what it gave away, and a question about a
`covered-here` row may need to *cite* a delegated one to make sense. What the rule forbids is the
delegated row being the thing asked about. The test is whose answer would settle it — if it is the
BRD that owns the row, the question belongs to that BRD's own round.

**A source-owning BRD carries no `claims:` field, so this is read off the `disposition` column and
never off `claims:`** — the same trap `references/coverage-ledger-format.md` §5 and
`commands/create-prd.md`'s gate set already spell out. Intersecting with `claims:` here would read an
empty set on every source-owning BRD and put *nothing* in scope.

**Deferring is itself an allocation.**
`deferred-to: <this BRD>` discharges the gate exactly as the other four terminal dispositions do;
the ledger's job is to record a requirement's fate, not to force every requirement to be built.

## 4. The allocation gate

`/brd-split` cannot complete while any row in this BRD's ledger is `unallocated`.
It opens the gate by walking every remaining `unallocated` row one at a time and offering a path
off `unallocated` into a terminal disposition — and **the paths available are not the same set at
both levels**. The difference is no longer a disposition §3 withholds from a slice: §3 makes
`covered-by` legal at both. It is a difference of **writer and of row**. The slice form of
`covered-by` records an orphan row (§2) and is written by the *parent's* walk at the moment that
walk withdraws the claim, so it is already terminal before a slice's own walk ever reads the
ledger — a slice's walk never stands on a row it could write, and therefore never offers it.
**No number is written here**, for the same reason the paragraph below refuses to re-enumerate the
picker: a level-general count is wrong at one of the two levels the moment it is written, and a
level-specific pair drifts the next time either §3 or the picker changes. §3 is where a
disposition's meaning and its writer are decided;
`commands/brd-split.md` Phase 4 is where the paths a walk offers are decided — read each off the
file that owns it, and never take one as the count of the other. Re-running `/brd-split` on a
BRD whose ledger is already fully allocated changes **nothing this file owns**: no row moves, and
the command still reports the ledger line (§6). **Whether that makes the whole run a no-op is not
this file's to say, and it is no longer only about the ledger** — that command also resolves a child
left standing while claiming nothing, which no ledger records and which this file therefore cannot
see. Read the no-op test off `commands/brd-split.md` Phase 0, the same way the picker's shape is
read off its Phase 4; a run that "changes no disposition" and a run that "does nothing" stopped
being the same run once that resolution existed.

**The set of resolutions the command offers, how each one writes its row, and how a row ever
reaches `covered-here` are `/brd-split`'s own behavior** — see `commands/brd-split.md` Phase 4 —
**not this reference's.** This file fixes the disposition
vocabulary (§3) and the one rule every caller must honor: no row may stay `unallocated` past this
gate. It does not fix, and does not re-enumerate, the command's interaction flow — the picker's
shape is the command's to own, and a count of it recorded here would only drift the next time that
picker changes.

## 5. PRD eligibility

**A folder is PRD-eligible if and only if it is a `PRD-` slice folder *and* at least one of its
ledger rows is `covered-here`.** Two tests, and the first one is about the **folder**, not about any
row.

**The level test is a check the consumer performs, and it comes first.** A BRD is a container and is
never the folder a PRD is authored in, so a consumer handed a `BRD-` folder refuses it **before
opening `coverage-ledger.md` at all** — on the resolved folder's own kind, never on what its rows
say. The check is: the `BRD-` prefix `references/addressing.md` §2 fixes, read off the resolved
folder's name; and, for a folder resolved through that file's §5 legacy fallback and carrying no
prefix, `brd-link.md`'s **`parent:`** — absent, or no `brd-link.md` at all, is a root container;
present is a slice.

**Never the folder's asserted `kind:`.** `/brd-split` writes `kind: brd` into the `brd-link.md` it
places inside a `PRD-` slice folder, so a slice **asserts `brd` while being exactly the folder a PRD
belongs in**: a consumer gating on the asserted kind would refuse every slice and accept nothing.

**Stating it this way rather than as an inference from the walk is deliberate.** It was previously
argued that a parent cannot be eligible because `covered-here` "is not a resolution its walk is
offered" (`commands/brd-split.md` Phase 4). That is true, and it is the wrong load-bearing
sentence: it makes a structural rule depend on a picker's current shape, so a ledger written before
that picker changed — or edited by hand — reads as eligible at root and no consumer catches it. The
rule is structural. Eligibility is a property of the `PRD-` folder a split produces, which is the
folder the PRD is authored in; and since a split always produces at least one, the requirements
always have somewhere eligible to land.

**Why a container, rather than letting a BRD hold its own PRD.** A BRD that could be split *and* be
PRD-eligible itself would hold PRD folders and its own Epic folders as siblings — two kinds in one
namespace, which `references/addressing.md` §2's second invariant forbids, and which `/brd-split`
Phase 0 step 9's child enumeration would then have to tell apart. One slice always existing means the
requirements always land somewhere a PRD can be written, and that somewhere is always one level down.
This argument is stated **here**, in the authority the refusals cite, rather than only in the command
that carves the slices.

- **Eligible.** At least one `covered-here` row exists. The folder may go on to author its own
  `prd.md`, which is what `/create-prd` on the BRD route runs against it to write.
- **Not eligible.** No row is `covered-here`. Every row therefore resolves to one of the other four
  terminal dispositions — `covered-by: <BRD-KEY>`, `deferred-to: <this BRD>`, `rejected: [DEF#n]`
  or `superseded-by: [BR#n]` — in any mix, and **all four reach this case equally**: eligibility is
  the presence of a `covered-here` row and nothing else, so a disposition bears on it exactly by not
  being `covered-here`. A folder whose every row is `rejected` is ineligible owing nobody
  anything, and one whose every row was `superseded-by` another `[BR#n]` is ineligible too, even
  though §6.3 excludes those rows from the ledger line's counts — a line the eligibility check never
  reads anyway (see the paragraph below on reading dispositions off the file). **Every parent BRD
  reaches this case**, by construction rather than by outcome, and that is not a failure state: it
  is what "a BRD is a container" means, and its consumer is told where the requirements went. This
  folder holds no PRD of its own. A consumer that reaches this state must refuse to author a PRD here and
  say **where the requirements went**, rather than producing an empty or placeholder document.

  **What there is to say depends on how the state was reached, and the first way is settled on the
  folder rather than on any row:**

  | How every row left `covered-here` | What the consumer says |
  |---|---|
  | **The folder is a `BRD-` container** — decided on the folder, before a row is read | Every row of a root's ledger ends `covered-by`, `deferred-to`, `rejected` or `superseded-by`; `covered-here` is not among them, and a root row carrying one is a ledger written before a BRD became a container, or edited by hand. Refuse on the level and name the `PRD-` slices under the container, one PRD each — enumerated by `/brd-split` Phase 0 step 9's positive test (an immediate subdirectory whose `brd-link.md` `parent:` names this BRD), never by a name match. Where the container holds no slice at all, the run that carves one is `/brd-split` on it — which is a **no-op** on a ledger with no `unallocated` row (§4), so a consumer naming it must say what the operator does then rather than leaving the offer to fail silently |
  | Some rows are `covered-by: <SLICE-KEY>` — the ordinary shape on a parent | Name those slices — and, per §6.1, which of them did not build the row delegated to it. A slice that deferred, rejected or has not allocated it is not somewhere to send the reader |
  | No row is `covered-by` | Name no slice, because none holds one of these rows — and say what the rows *did* resolve to rather than calling them all obligations. The three remaining dispositions say different things: a `deferred-to` row is a live obligation of this folder, a `rejected` one is an obligation of nobody and cites the `[DEF#n]` justifying it, and a `superseded-by` one was absorbed into the `[BR#n]` that replaced it. This is also the only shape a **slice** reaches, for the reason the paragraph below gives: no row of the set eligibility is read over on a slice can be `covered-by`. On a slice, add that a PRD needs one row resolved `covered-here` first |

  "Name the slices that do" is right in the first two rows only. In the third there is nothing to
  name, and a consumer that goes looking for a slice to point at finds none and must not invent
  one — the honest report is what each row actually resolved to, and, for the deferred ones, by whom.
  "The requirements are deferred" is the common shape of that case, not the whole of it:
  a folder whose every row is `rejected` reaches it owing nobody anything, and
  saying it deferred them would be false.

**A slice reaches eligibility by exactly this rule**, through the same Phase 4 walk on its own
ledger. The one difference is which rows the rule is read over, and it is why a slice still reaches
the "not eligible" case entirely through `deferred-to`, `rejected` and `superseded-by`, in any mix,
and never through a row pointing at another BRD. A slice's `covered-by` rows exist (§3) but are
exactly its **orphan rows** (§2) — provisional claims the parent's walk withdrew — and `claims:`
names none of them, so none is in the set eligibility is read over. Every row that *is* in that set
is a row this slice claims, and a claimed row is settled by this slice's own walk, which never
writes `covered-by`. There is still no child below a slice for any row to point at.

**Eligibility is read over the rows this ledger holds, which §1 and §3 fix per level and which
`claims:` narrows only on a slice.** A source-owning BRD carries no `claims:` field, so a consumer
that intersects with one there tests an empty set and finds no `covered-here` row in it — which on a
parent is the right answer for the wrong reason, and on the day someone reuses that consumer against
a slice it is simply wrong. Read the ledger's own rows. On a slice the narrowing does real work
rather than coinciding with the ledger, and
it is safe in both directions: **an orphan row can neither create eligibility nor withhold it.** It
is never `covered-here` — §3's table gives it `covered-by`, `rejected` or `superseded-by` and
nothing else, and only the parent's walk writes it — so it cannot make an ineligible slice look
eligible; and it is never `unallocated`, so it cannot make an eligible one look unallocated.

This is **read from the ledger, not decided in advance.** Slicing a BRD entirely and slicing it
only partially are both ordinary, supported outcomes; the ledger is what tells a later consumer
which one happened, without the operator having declared which they were doing at the time. A row
still `unallocated` **as written on this BRD's own ledger** when eligibility is checked means the
gate in §4 was never satisfied — a consumer must treat that as a hard refusal, never as an implicit
`covered-here` or `deferred-to` in either direction.

**Read that from the ledger file, never from the §6 line.** Since §6.1 resolves a delegated row
through the BRD that owns it, the line's `unallocated` term also counts rows this BRD wrote
`covered-by` and that BRD has not walked yet — rows whose fate this BRD *has* recorded. A consumer
keying the refusal off that term would hard-refuse a BRD whose own gate is fully satisfied. The
refusal is about this ledger's own written dispositions, and about nothing else.

## 6. The ledger line

Every `/brd-*` command's final report ends with exactly one line, so the ledger's state is visible
without opening the file or running anything else:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

### 6.1 A `covered-by` row is counted through the BRD it names

Delegating a requirement records **which** BRD owns it (§3); it does not record that the BRD built
it. So before any count below is taken, every `covered-by: <BRD-KEY>` row is resolved **one hop** —
read that BRD's own `coverage-ledger.md`, take the disposition of its row for the same `[BR#n]` —
and this row is counted as whatever that BRD decided. **The hop is the same operation at both
levels**, and only the key differs: on a source-owning BRD it lands in the named **child**, and on
a slice it lands in the named **sibling or parent** (§3). Nothing below is level-specific, so a
slice's line resolves its orphan rows exactly as a parent resolves its delegated ones:

| The named BRD's row for that `[BR#n]` | This `covered-by` row counts as |
|---|---|
| `covered-here` | `covered` |
| `deferred-to` | `deferred` |
| `rejected` | `rejected` |
| `unallocated` | `unallocated` |
| `superseded-by` | excluded from every count and from the total (§6.3) |
| unreadable | `unresolved` (§6.2) |

**One hop is exhaustive**, and it stays exhaustive now that a slice's row may carry `covered-by`
(§3). The argument is no longer that a slice cannot delegate; it is that a hop can never land on a
row that does:

- **A parent's hop lands on a row the child `claims:`.** The parent wrote `covered-by: <CHILD-KEY>`
  precisely because it allocated that `[BR#n]` to that child, so the child claims it — and a
  claimed row is settled by the child's own walk, which never writes `covered-by` (§3, §4). A child
  row that nevertheless carries `covered-by` for a row its parent delegated to it is malformed; it
  is counted `unresolved` rather than followed.
- **A slice's own `covered-by` rows are exactly the rows its parent did *not* delegate to it** —
  orphan rows, withdrawn claims (§2) — so no parent's hop ever lands on one.
- **A slice's hop lands on a sibling that claims the row, or on the parent.** The sibling case is
  the first bullet one level across. The parent case lands on a row the parent resolved
  `covered-here` or `deferred-to` (§3's orphan table), never on another `covered-by`: a parent row
  reading `covered-by: <SIBLING-KEY>` is what produces the sibling form instead of the parent one.

Nesting is capped at one level throughout (`references/addressing.md` §6), so there is no third
level for a chain to reach even if one were somehow written.

This is the arithmetic §1 promises. The failure §1 names — every child independently deciding the
same requirement is somebody else's problem — stays invisible while a parent row reading
`covered-by` counts as covered on its own say-so. Resolved through the child, each such row is
reported as the `deferred`, `rejected` or `unallocated` it actually is, and the trailing figures
say how many requirements this BRD handed to a child that the child is not building.

`covered` therefore sums `covered-here` rows and the delegated rows that resolved to `covered`.
`deferred`, `rejected`, and `unallocated` each sum their own matching disposition on this ledger
plus the delegated rows that resolved to it. `unresolved` counts nothing but delegated rows whose
named BRD could not be read.

**"Delegated" means every `covered-by` row this ledger holds**, which on a slice includes its
orphan rows (§2). That is deliberate and is the audit trail §1 exists for: a requirement a slice
once claimed and no longer does still appears in that slice's own arithmetic, resolved through the
BRD that took it, so no report can say it was lost. It is counted there and on the parent's ledger
under two different questions — the parent's line asks which BRD owns it, this one asks what became
of a claim this slice made — and neither is a second count of the same obligation at the same
level.

**Every term in this line is a resolved count, not a census of what the file says**, and the term
that most visibly differs is `unallocated`. **The line's `unallocated` term does not track §4's
gate.** §4 is satisfied when no row **as written on this ledger** is `unallocated`; a delegated row
is written `covered-by` and stays written `covered-by` whatever the child does with it. The very run
that satisfies the gate seeds each child it creates with rows the child has not walked yet (§3's
creator table), so a completed `/brd-split` routinely reports a non-zero `unallocated` term for rows
whose fate this BRD has fully recorded — that is the resolution working, not a gate left open.
**A consumer testing the gate reads the dispositions in the ledger file; it never reads this line.**

### 6.2 A ledger that cannot be read is `unresolved`, never `covered`

Resolution reads the named BRD's `coverage-ledger.md` **from the working tree**, through
`resolve-address` (`references/addressing.md` §3) — not from git, because this line reports what
the run can actually see. A delegated row is `unresolved` when no folder resolves for the
`<BRD-KEY>` it names; when that folder holds no `coverage-ledger.md`; when the tree the run is
standing in does not carry that BRD at all, because the split that created it has not merged; or
when its ledger holds no readable row for that `[BR#n]`.

It gets its own term rather than joining one of the four:

- **Not `covered`** — an absent answer is not a positive one, and counting it as covered is exactly
  the defect this section exists to remove.
- **Not `unallocated`** — this row **is** allocated: it carries `covered-by`, a terminal
  disposition (§3). Reporting an unreadable BRD under the one disposition this row demonstrably
  does not have would also put a BRD nobody could read in the same bucket as one that *was*
  read and has simply not walked its ledger yet — two different facts, and the second is the one a
  reader can act on.
- **Not dropped** — dropping the row would shrink the total and hide the requirement altogether,
  which is §1's failure in a new costume.

**`unresolved` is a reporting state, not a disposition.** §3's six are unchanged, no row is ever
written `unresolved`, it is never offered by any picker, and it never blocks §4. A non-zero
`unresolved` is a prompt to look at the named BRD, not a defect in this BRD's allocation.

**The line mixes two provenances, and a reader should know which term came from where.** The ledger
being reported on is gated wherever a gate exists — `/brd-ground` and `/brd-split` each run
`require-on-main` over it in their Phase 0 step 6 — while the ledgers resolved into it are
read from the working tree and gated by nothing. So a `covered` this line reports for a delegated row can rest
on another BRD's decision that has not merged and could still change, and an `unresolved` can mean nothing
worse than a pull request still open. That asymmetry is the price of reporting what the run can
actually see instead of reporting nothing, and it is why this line is a report and not an input to
any gate.

### 6.3 `superseded-by` is excluded from every count and from the total

A superseded row's obligation was absorbed into the `[BR#n]` that replaced it; counting it again
anywhere in this line would double-count the same requirement under two ids. That holds at both
levels: a row this ledger itself marks `superseded-by`, and a delegated row the named BRD resolved
`superseded-by`, are both dropped before anything else is computed.

A supersession the named BRD recorded is **not** "delegated and then not built". That BRD may only
supersede a `[BR#n]` its own inventory holds, and every id in that inventory is the source-owning
BRD's, copied row for row (`commands/brd-split.md` Phase 3 step 4) — so the replacing requirement
is a row of the **source-owning BRD's** ledger, carrying its own fate and its own contribution to
that BRD's line. Supersession moves an obligation; it does not drop one.

**On a parent's line the replacing row is a row of *this* ledger too**, so the move is visible in
the same line the drop happened in. **On a slice's line an orphan row (§2) breaks that**, in either
of the two ways one can be superseded: the row may carry `superseded-by: [BR#n]` verbatim, written
by the parent's walk and naming a `[BR#n]` of the parent's inventory this slice never claimed; or it
may be a `covered-by` row whose named sibling superseded it into one. The obligation is still not
lost — it is on the parent's ledger, where every id lives and where this section's guarantee holds
in full — but a reader who wants to see where a slice's orphan row went after a supersession reads
the parent's ledger, not this line.

### 6.4 The two trailing figures

`<delegated>` counts the `covered-by` rows that survive the §6.3 exclusion. `<not-built>` counts
those among them the named BRD deferred, rejected, or left `unallocated`.

Every delegated row lands in exactly one of three places, so
`<delegated>` = the delegated rows the named BRD covers + `<not-built>` + `<unresolved>`.

**Both figures are printed even when both are zero**, and so is a zero `unresolved`: an omitted
clause is indistinguishable from a check that never ran, and the whole point of §6.1 is that this
resolution is visible rather than assumed. A BRD with no `covered-by` row at all reports
`0 unresolved (0 delegated, 0 not built)` and says so plainly. That is the ordinary shape of a BRD
nobody split, and of a slice whose parent's walk withdrew none of its provisional claims — but it
is **not** a property of being a slice. A slice holding orphan rows (§2) reports them as delegated,
resolved one hop through the sibling or parent each names, exactly as §6.1 resolves any other
`covered-by` row.

### 6.5 Worked example

A synthetic BRD `EPIC-008` holds seventeen ledger rows, seven of them delegated to its one child
`EPIC-008-01`:

| This BRD's disposition | Rows |
|---|---|
| `covered-here` | 4 |
| `covered-by: EPIC-008-01` | 7 |
| `deferred-to: <this BRD>` | 2 |
| `rejected: [DEF#n]` | 1 |
| `superseded-by: [BR#n]` | 2 |
| `unallocated` | 1 |

Resolving those seven one hop into `EPIC-008-01`'s own ledger:

| What `EPIC-008-01` did with it | Rows | Counts on `EPIC-008` as |
|---|---|---|
| `covered-here` | 2 | `covered` |
| `deferred-to` | 1 | `deferred` |
| `rejected` | 1 | `rejected` |
| `unallocated` | 1 | `unallocated` |
| `superseded-by` | 1 | excluded (§6.3) |
| no row for that `[BR#n]` | 1 | `unresolved` (§6.2) |

Three rows are dropped before anything is computed: this BRD's own two `superseded-by` rows, plus
the one delegated row the child superseded. 17 − 3 = 14 requirements. Six delegated rows survive
that exclusion; of those, the child covers 2, is not building 3 (1 deferred + 1 rejected +
1 `unallocated`), and 1 could not be resolved.

- covered = 4 `covered-here` + 2 delegated-and-covered = 6
- deferred = 2 here + 1 delegated = 3
- rejected = 1 here + 1 delegated = 2
- unallocated = 1 here + 1 delegated = 2
- unresolved = 1

6 + 3 + 2 + 2 + 1 = 14, and 6 delegated = 2 covered + 3 not built + 1 unresolved:

```
ledger: 14 requirements — 6 covered, 3 deferred, 2 rejected, 2 unallocated, 1 unresolved (6 delegated, 3 not built)
```

**What the unconditional rule reported instead.** Counting every `covered-by` row as covered on its
own word, the same ledger read `15 requirements — 11 covered, 2 deferred, 1 rejected, 1 unallocated`:
three requirements nobody is building were reported as covered, one delegated requirement nobody
could account for was reported as covered, and a row the child had already superseded was still
counted as a live requirement. That line is what §1 says the ledger exists to prevent.

### 6.6 Worked example — a slice's line, with an orphan row

A second synthetic tree, separate from §6.5's: `EPIC-009` with two slices, `EPIC-009-01` and
`EPIC-009-02`. Splitting `EPIC-009`, Phase 3 provisionally gave `EPIC-009-01` four rows —
`[BR#3]`, `[BR#4]`, `[BR#5]`, `[BR#6]` — and seeded four `unallocated` ledger rows in it. Phase 4's
walk on `EPIC-009`'s own ledger then allocated the first three `covered-by: EPIC-009-01` and the
fourth `covered-by: EPIC-009-02`. So `[BR#6]`'s `claims:` entry and its copied inventory row were
withdrawn from `EPIC-009-01`, and its ledger row stayed, written `covered-by: EPIC-009-02` (§2, §3).

`/brd-split EPIC-009-01` then walks the three rows still `unallocated` — the ones it claims — and
resolves `[BR#3]` and `[BR#4]` `covered-here` and `[BR#5]` `deferred-to: EPIC-009-01`. It never
stands on `[BR#6]`: that row was terminal before this run opened the file.

| `EPIC-009-01`'s row | Disposition | Counts as |
|---|---|---|
| `[BR#3]` | `covered-here` | `covered` |
| `[BR#4]` | `covered-here` | `covered` |
| `[BR#5]` | `deferred-to: EPIC-009-01` | `deferred` |
| `[BR#6]` — orphan | `covered-by: EPIC-009-02` | resolved one hop (§6.1) into `EPIC-009-02`, which built it: `covered` |

Nothing is excluded by §6.3, so the total is 4. One row is delegated, and the sibling covers it:

```
ledger: 4 requirements — 3 covered, 1 deferred, 0 rejected, 0 unallocated, 0 unresolved (1 delegated, 0 not built)
```

3 + 1 + 0 + 0 + 0 = 4, and 1 delegated = 1 covered + 0 not built + 0 unresolved.

**Three things this line settles.** §4 is satisfied — no row is `unallocated` as written, so
`/brd-split EPIC-009-01` completes. §5 is satisfied — `[BR#3]` and `[BR#4]` are `covered-here` and
both are rows `claims:` names, so the slice is PRD-eligible on its own remaining rows. And `[BR#6]`
is reported, not lost: here as a delegated row resolved through the sibling that built it, and on
`EPIC-009`'s own line as `covered-by: EPIC-009-02` resolved through the same sibling. Two lines
answer two different questions about it; neither is silent.

**The ordinary case is unchanged.** Had the parent's walk settled `[BR#6]` `rejected: [DEF#4]`
instead, the orphan row would read `rejected: [DEF#4]` — the disposition carries across unchanged
(§3) — count in `rejected`, contribute nothing to `delegated`, and the line would read
`4 requirements — 2 covered, 1 deferred, 1 rejected, 0 unallocated, 0 unresolved (0 delegated, 0 not built)`.
That is exactly what this file said before the orphan row was kept, except that the row is now
there to be counted at all.

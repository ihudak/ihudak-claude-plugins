# Coverage ledger format (embedded authority)

The canonical shape of the **coverage ledger** (`coverage-ledger.md`): the row a BRD (business
requirements document) keeps per requirement, the states that row can carry, and the rule that
blocks a split until every row has one. Design authority:
`docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §4, §4.1. Requirement and defect
identifiers (`[BR#n]`, `[DEF#n]`) are defined once in `references/brd-format.md` — cited here, not
restated; key grammar and folder resolution are defined once in `references/brd-addressing.md`.

## 1. Purpose

The coverage ledger is **the only place a requirement's fate is recorded.** Every other BRD
artifact — the inventory, the defect log, the grounding findings, the decisions — describes what a
requirement says or what is known about it. Only the ledger says what happened to it: built here,
built by a child, deferred, rejected, or superseded.

This matters most on the failure a long BRD invites: one BRD is split into several children, each
child looks at the same requirement, and each one — independently, reasonably — decides it is
somebody else's problem to build. No single child did anything wrong; nothing built the
requirement anyway, and nothing noticed, because nowhere recorded that every child had waved it
past. The ledger exists to make that failure visible: a row left `unallocated` (§3), or a set of
rows that resolve to nothing but `covered-by` pointing at each other's children, is a fact the
ledger states plainly rather than a gap that only a careful re-read of every child would surface.

**The ledger line is where that promise is kept.** A `covered-by` row records which BRD owns a
requirement, not that any BRD built it, so §6 resolves every one of them one hop through the named
child's own ledger before it counts anything: a requirement a child deferred, rejected or never
allocated is reported as exactly that, and the line names how many were delegated and then not
built. Counting `covered-by` as covered on its own word is what would let the failure above pass
this file's own arithmetic unremarked.

One ledger exists per BRD, at either of the two levels a BRD can sit — a BRD that owns its source
document, or a slice one level inside it (`references/brd-addressing.md` §3 caps nesting there). **What
its rows are is not the same at both levels**, and §3's creator table is the authority: a
source-owning BRD gets one row per `[BR#n]` in the inventory `/brd-intake` extracted, while a slice
gets one row per `[BR#n]` its `brd-link.md` claims. Only a slice has a `claims:` field — `/brd-split`
writes it, and only into a child — so a consumer that defines a BRD's requirement set over `claims:`
at both levels reads an empty set on every BRD that was never split.

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

## 3. Dispositions

Exactly six. Only the last one blocks the gate in §4.

| Disposition | Meaning |
|---|---|
| `covered-here` | This BRD builds it; the BRD is therefore PRD-eligible (§5) |
| `covered-by: <CHILD-KEY>` | A named child BRD builds it — **available only on a BRD that owns its source document**, never on a slice (see below) |
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
| A slice — a child BRD nested in its parent's folder | `/brd-split` (`commands/brd-split.md` Phase 3) | one per `[BR#n]` the slice's `brd-link.md` claims |

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
decided to do with it**.

**`covered-by` is the one disposition whose availability depends on level.** It names a child BRD
that builds the row, and nesting is capped at one level
(`references/brd-addressing.md` §3), so **no child can exist below a slice** — on a slice the
disposition has nothing it could name. A slice's ledger therefore resolves through the other five:
four terminal ones plus `unallocated`. This belongs here rather than only in the command because it
is a property of the vocabulary this section owns — where a disposition is meaningful at all — not
of the picker that offers it; §4's disclaimer about the command owning its own interaction flow is
unchanged, and how the four are presented stays `commands/brd-split.md`'s.

**Deferring is itself an allocation.**
`deferred-to: <this BRD>` discharges the gate exactly as the other four terminal dispositions do;
the ledger's job is to record a requirement's fate, not to force every requirement to be built.

## 4. The allocation gate

`/brd-split` cannot complete while any row in this BRD's ledger is `unallocated`.
It opens the gate by walking every remaining `unallocated` row one at a time and offering a path
off `unallocated` into a terminal disposition — whichever ones §3 makes available at the level this
BRD sits at, which is not the same set at both: `covered-by` is parent-only, so a slice's walk
resolves through fewer than a source-owning BRD's. **No number is written here**, for the same
reason the paragraph below refuses to re-enumerate the picker: a level-general count is wrong at
one of the two levels the moment it is written, and a level-specific pair drifts the next time §3
changes. §3 is where availability is decided; read the count off it. Re-running `/brd-split` on a
BRD whose ledger is already fully allocated is a no-op: nothing changes, and the command still
reports the ledger line (§6).

**The set of resolutions the command offers, how each one writes its row, and how a row ever
reaches `covered-here` are `/brd-split`'s own behavior** — see `commands/brd-split.md` Phase 4 —
**not this reference's.** This file fixes the disposition
vocabulary (§3) and the one rule every caller must honor: no row may stay `unallocated` past this
gate. It does not fix, and does not re-enumerate, the command's interaction flow — the picker's
shape is the command's to own, and a count of it recorded here would only drift the next time that
picker changes.

## 5. PRD eligibility

**A BRD is PRD-eligible if and only if at least one of its ledger rows is `covered-here`.**

- **Eligible.** At least one `covered-here` row exists. The BRD may go on to author its own
  `<BRD-KEY>_<slug>.md`, which is what `/create-prd --from-brd` runs against this BRD to write.
- **Not eligible.** No row is `covered-here`. Every row therefore resolves to one of the other four
  terminal dispositions — `covered-by: <CHILD-KEY>`, `deferred-to: <this BRD>`, `rejected: [DEF#n]`
  or `superseded-by: [BR#n]` — in any mix, and **all four reach this case equally**: eligibility is
  the presence of a `covered-here` row and nothing else, so a disposition bears on it exactly by not
  being `covered-here`. A BRD whose every row is `rejected` is ineligible owing nobody
  anything, and one whose every row was `superseded-by` another `[BR#n]` is ineligible too, even
  though §6.3 excludes those rows from the ledger line's counts — a line the eligibility check never
  reads anyway (see the paragraph below on reading dispositions off the file). This BRD
  holds no PRD of its own. A consumer that reaches this state must refuse to author a PRD here and
  say **where the requirements went**, rather than producing an empty or placeholder document.

  **What there is to say depends on how the state was reached, and one of the three ways names no
  child at all:**

  | How every row left `covered-here` | What the consumer says |
  |---|---|
  | Some rows are `covered-by: <CHILD-KEY>` | Name those children — and, per §6.1, which of them did not build the row delegated to it. A child that deferred, rejected or has not allocated it is not somewhere to send the reader |
  | No row is `covered-by`: the BRD was never split | Name no child, because none exists — and say what the rows *did* resolve to rather than calling them all obligations. The three remaining dispositions say different things: a `deferred-to` row is a live obligation of this BRD, a `rejected` one is an obligation of nobody and cites the `[DEF#n]` justifying it, and a `superseded-by` one was absorbed into the `[BR#n]` that replaced it. Then say a PRD needs one row resolved `covered-here` first |
  | No row is `covered-by` because this is a **slice** | The same breakdown, for the reason the paragraph below gives |

  "Name the children that do" is right only in the first row. In the other two there is nothing to
  name, and a consumer that goes looking for a child to point at finds none and must not invent
  one — the honest report is what each row actually resolved to, and, for the deferred ones, by whom.
  "The requirements are deferred" is the common shape of those two cases, not the whole of them:
  a BRD whose every row is `rejected` reaches this same case owing nobody anything, and
  saying it deferred them would be false.

**A slice reaches eligibility by exactly this rule**, through the same Phase 4 walk on its own
ledger. The one difference follows from `covered-by` being parent-only (§3): on a slice, the
"not eligible" case is reached entirely through the three remaining terminal dispositions —
`deferred-to`, `rejected` and `superseded-by`, in any mix — never by rows pointing at children,
because no child can exist below a slice for a row to point at.

**Eligibility is read over the rows this ledger holds, which §1 and §3 fix per level and which
`claims:` narrows only on a slice.** A source-owning BRD carries no `claims:` field, so a consumer
that intersects with one there tests an empty set, finds no `covered-here` row in it, and refuses
the never-split BRD this route most often reaches — the very case §4's escape valve exists to let
complete.

This is **read from the ledger, not decided in advance.** Slicing a BRD entirely and slicing it
only partially are both ordinary, supported outcomes; the ledger is what tells a later consumer
which one happened, without the operator having declared which they were doing at the time. A row
still `unallocated` **as written on this BRD's own ledger** when eligibility is checked means the
gate in §4 was never satisfied — a consumer must treat that as a hard refusal, never as an implicit
`covered-here` or `deferred-to` in either direction.

**Read that from the ledger file, never from the §6 line.** Since §6.1 resolves a delegated row
through the child that owns it, the line's `unallocated` term also counts rows this BRD wrote
`covered-by` and a child has not walked yet — rows whose fate this BRD *has* recorded. A consumer
keying the refusal off that term would hard-refuse a BRD whose own gate is fully satisfied. The
refusal is about this ledger's own written dispositions, and about nothing else.

## 6. The ledger line

Every `/brd-*` command's final report ends with exactly one line, so the ledger's state is visible
without opening the file or running anything else:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

### 6.1 A `covered-by` row is counted through the child it names

Delegating a requirement records **which** BRD owns it (§3); it does not record that the BRD built
it. So before any count below is taken, every `covered-by: <CHILD-KEY>` row is resolved **one hop** —
read that child's own `coverage-ledger.md`, take the disposition of its row for the same `[BR#n]` —
and the parent's row is counted as whatever the child decided:

| The child's row for that `[BR#n]` | The parent's `covered-by` row counts as |
|---|---|
| `covered-here` | `covered` |
| `deferred-to` | `deferred` |
| `rejected` | `rejected` |
| `unallocated` | `unallocated` |
| `superseded-by` | excluded from every count and from the total (§6.3) |
| unreadable | `unresolved` (§6.2) |

**One hop is exhaustive.** `covered-by` is unavailable on a slice (§3), so a child's row can never
delegate onward, and nesting is capped at one level anyway
(`references/brd-addressing.md` §3). A child row that nevertheless carries `covered-by` is
malformed; it is counted `unresolved` rather than followed.

This is the arithmetic §1 promises. The failure §1 names — every child independently deciding the
same requirement is somebody else's problem — stays invisible while a parent row reading
`covered-by` counts as covered on its own say-so. Resolved through the child, each such row is
reported as the `deferred`, `rejected` or `unallocated` it actually is, and the trailing figures
say how many requirements this BRD handed to a child that the child is not building.

`covered` therefore sums `covered-here` rows and the delegated rows that resolved to `covered`.
`deferred`, `rejected`, and `unallocated` each sum their own matching disposition on this ledger
plus the delegated rows that resolved to it. `unresolved` counts nothing but delegated rows whose
child could not be read.

**Every term in this line is a resolved count, not a census of what the file says**, and the term
that most visibly differs is `unallocated`. **The line's `unallocated` term does not track §4's
gate.** §4 is satisfied when no row **as written on this ledger** is `unallocated`; a delegated row
is written `covered-by` and stays written `covered-by` whatever the child does with it. The very run
that satisfies the gate seeds each child it creates with rows the child has not walked yet (§3's
creator table), so a completed `/brd-split` routinely reports a non-zero `unallocated` term for rows
whose fate this BRD has fully recorded — that is the resolution working, not a gate left open.
**A consumer testing the gate reads the dispositions in the ledger file; it never reads this line.**

### 6.2 A child ledger that cannot be read is `unresolved`, never `covered`

Resolution reads the child's `coverage-ledger.md` **from the working tree**, through
`resolve-brd` (`references/brd-addressing.md` §2) — not from git, because this line reports what
the run can actually see. A delegated row is `unresolved` when no folder resolves for
`<CHILD-KEY>`; when that folder holds no `coverage-ledger.md`; when the tree the run is standing in
does not carry the child at all, because the split that created it has not merged; or when the
child's ledger holds no readable row for that `[BR#n]`.

It gets its own term rather than joining one of the four:

- **Not `covered`** — an absent answer is not a positive one, and counting it as covered is exactly
  the defect this section exists to remove.
- **Not `unallocated`** — the parent's row **is** allocated: it carries `covered-by`, a terminal
  disposition (§3). Reporting an unreadable child under the one disposition this row demonstrably
  does not have would also put a child nobody could read in the same bucket as a child that *was*
  read and has simply not walked its ledger yet — two different facts, and the second is the one a
  reader can act on.
- **Not dropped** — dropping the row would shrink the total and hide the requirement altogether,
  which is §1's failure in a new costume.

**`unresolved` is a reporting state, not a disposition.** §3's six are unchanged, no row is ever
written `unresolved`, it is never offered by any picker, and it never blocks §4. A non-zero
`unresolved` is a prompt to look at the named child, not a defect in this BRD's allocation.

**The line mixes two provenances, and a reader should know which term came from where.** The ledger
being reported on is gated wherever a gate exists — `/brd-ground` and `/brd-split` each run
`require-on-main` over it in their Phase 0 step 6 — while the child ledgers resolved into it are
read from the working tree and gated by nothing. So a `covered` this line reports for a delegated row can rest
on a child decision that has not merged and could still change, and an `unresolved` can mean nothing
worse than a pull request still open. That asymmetry is the price of reporting what the run can
actually see instead of reporting nothing, and it is why this line is a report and not an input to
any gate.

### 6.3 `superseded-by` is excluded from every count and from the total

A superseded row's obligation was absorbed into the `[BR#n]` that replaced it; counting it again
anywhere in this line would double-count the same requirement under two ids. That holds at both
levels: a row this ledger itself marks `superseded-by`, and a delegated row the child resolved
`superseded-by`, are both dropped before anything else is computed.

A child's supersession is **not** "delegated and then not built". A child may only supersede a
`[BR#n]` its own inventory holds, and every id in that inventory is the parent's, copied row for
row (`commands/brd-split.md` Phase 3 step 4) — so the replacing requirement is a row of *this*
ledger too, carrying its own fate and its own contribution to this line. Supersession moves an
obligation; it does not drop one.

### 6.4 The two trailing figures

`<delegated>` counts the `covered-by` rows that survive the §6.3 exclusion. `<not-built>` counts
those among them the child deferred, rejected, or left `unallocated`.

Every delegated row lands in exactly one of three places, so
`<delegated>` = the delegated rows the child covers + `<not-built>` + `<unresolved>`.

**Both figures are printed even when both are zero**, and so is a zero `unresolved`: an omitted
clause is indistinguishable from a check that never ran, and the whole point of §6.1 is that this
resolution is visible rather than assumed. A BRD with no `covered-by` row at all — never split, or
a slice, where `covered-by` is unavailable (§3) — reports `0 unresolved (0 delegated, 0 not built)`
and says so plainly.

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

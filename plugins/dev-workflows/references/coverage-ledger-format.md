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

One ledger exists per BRD, at whatever level that BRD sits (a parent or a slice, §4 of the design),
with one row per `[BR#n]` that BRD's `brd-link.md` claims.

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
| `covered-by: <CHILD-KEY>` | A named child BRD builds it |
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
nothing ever would, and the slice could never be ground or split in its own right. `/brd-split` is
also the only command holding both the parent's rows and the allocation that says which of them the
slice claims.

**Deferring is itself an allocation.**
`deferred-to: <this BRD>` discharges the gate exactly as the other four terminal dispositions do;
the ledger's job is to record a requirement's fate, not to force every requirement to be built.

## 4. The allocation gate

`/brd-split` cannot complete while any row in this BRD's ledger is `unallocated`.
It opens the gate by walking every remaining `unallocated` row one at a time and offering a path
off `unallocated` into one of the five terminal dispositions in §3. Re-running `/brd-split` on a
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
  `<BRD-KEY>_<slug>.md` once `/create-prd --from-brd` (increment 3) runs against it.
- **Not eligible.** No row is `covered-here` — every row resolves to `covered-by: <CHILD-KEY>` or
  `deferred-to: <this BRD>` (with `rejected` and `superseded-by` rows outside the question
  entirely, per §6). The BRD was fully sliced and holds no PRD of its own. A consumer that reaches
  this state must refuse to author a PRD here and name the children that do, rather than producing
  an empty or placeholder document.

This is **read from the ledger, not decided in advance.** Slicing a BRD entirely and slicing it
only partially are both ordinary, supported outcomes; the ledger is what tells a later consumer
which one happened, without the operator having declared which they were doing at the time. A row
still `unallocated` when eligibility is checked means the gate in §4 was never satisfied — a
consumer must treat that as a hard refusal, never as an implicit `covered-here` or `deferred-to` in
either direction.

## 6. The ledger line

Every `/brd-*` command's final report ends with exactly one line, so the ledger's state is visible
without opening the file or running anything else:

```
ledger: 47 requirements — 31 covered, 12 deferred, 2 rejected, 2 unallocated
```

`covered` sums `covered-here` and `covered-by` rows — the line does not distinguish which produced
a given count, only that the requirement is spoken for. `deferred`, `rejected`, and `unallocated`
each count their one matching disposition.

**`superseded-by` rows are excluded from all four counts and from the total.** A superseded row's
obligation was absorbed into the `[BR#n]` that replaced it; counting it again anywhere in this line
would double-count the same requirement under two ids.

**Worked example.** A synthetic BRD's ledger holds fourteen rows:

| Disposition | Rows |
|---|---|
| `covered-here` | 5 |
| `covered-by: <CHILD-KEY>` | 3 |
| `deferred-to: <this BRD>` | 2 |
| `rejected: [DEF#n]` | 1 |
| `superseded-by: [BR#n]` | 2 |
| `unallocated` | 1 |

Fourteen rows exist on disk, but the two `superseded-by` rows are dropped before anything else is
computed, leaving twelve: 5 `covered-here` + 3 `covered-by` = 8 covered, 2 deferred, 1 rejected, 1
unallocated — 8 + 2 + 1 + 1 = 12 requirements:

```
ledger: 12 requirements — 8 covered, 2 deferred, 1 rejected, 1 unallocated
```

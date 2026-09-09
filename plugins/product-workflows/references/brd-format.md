# BRD format (embedded authority)

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

The canonical structure for a **BRD** (business requirements document): what it is, how its
requirements are inventoried into `[BR#n]` rows, and how defects found in it are classified. Design
authority: `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §4, D11, D21. Key
grammar and folder resolution are defined once in `workflows-core:addressing` §1 — cited here,
not restated.

## 1. What a BRD is here

A BRD is a **customer-supplied statement of what they are paying for** — the document a customer
hands the delivery team, typically long, typically internally contradictory, and not implementable
as written. It is not authored by the delivery team and it is not a PRD.

Once intaken, the source is **immutable** (D11): nothing under `brd/source/` is ever edited,
reworded, or reformatted after intake, no matter how badly worded a requirement inside it is. Every
`[BR#n]` anchors into this text by `source_anchor` (§2); if the source moved, every anchor in the
inventory would silently point at the wrong place. Defects found in it are logged beside it (§3,
§4), never corrected in it — that is the only way to say precisely what the customer gave the
delivery team and what changed afterward.

The source is **markdown only**. A BRD arriving as a PDF, a Word document, or a slide deck is
converted to markdown before intake, and that conversion is never a bare mechanical pass taken on
faith: an unchecked machine conversion must not become the record a `[BR#n]` anchors into, because
a conversion artifact (a dropped clause, a misplaced heading, a table read out of row order) then
becomes an invisible edit to an otherwise-immutable document.

## 2. The inventory

The inventory (`brd/source/`'s companion `brd-inventory.md`) holds **one row per requirement**:

| Field | Meaning |
|---|---|
| `id` | `[BR#1]`, `[BR#2]`, … — contiguous, assigned once, never renumbered |
| `text` | the requirement, verbatim, or its first sentence plus a `source_anchor` when quoting it whole would be unwieldy |
| `source_anchor` | a heading path or line range locating the requirement inside `brd/source/` |
| `defects` | a `[DEF#n]` list (§3) — empty when the requirement carries none |

**A requirement carrying more than one obligation is split.** When one numbered item in the source
binds the delivery team to two or more separable obligations, each obligation becomes its own
`[BR#n]` rather than being inventoried as one row with a compound `text`. The split itself is
recorded as a `[DEF#n]` of class `duplicate` (§3) naming the sibling rows it produced — the
inventory does not silently multiply one source requirement into several without a defect marking
that it did.

`[BR#n]` numbers are never reused and never renumbered, including across a split: once assigned, an
id is permanent even if the row it names is later split, superseded, or found defective.

### 2.2 The inventory's coverage of its source is checkable from the inventory alone

**A section the read skipped and a section that genuinely holds no obligation come out of an
inventory identically — as a section with no row — so the difference cannot be read off the
artifact.** It is made visible at intake instead, and the whole of it is derivable from `source_anchor`
and the source document: **nothing new is stored, and no agent returns a new field.** A first design
had the reader account for every heading it passed; measured against real intakes that is fifty-odd
accounts of "this section holds context", which buries the one case worth seeing.

Two relations, both over the **top-level section**:

1. **Every `source_anchor` resolves to a section the source actually has.** An anchor naming a
   section the document does not hold is a row nobody can trace back, in the artifact whose whole
   job is traceability.
2. **Every top-level section of the source either holds a row or is accounted for.** A section is
   held where any anchor names it or names a section beneath it. One with none is not a defect and is
   not a stop — only a person can say whether a section binds the delivery team to anything — so
   `/brd-intake` names each with what the source has under it and asks.

**The granularity is the finding, not a detail.** Real BRDs run to fifty or sixty headings under
fourteen or fifteen top-level sections, and on a careful intake nine of those fifteen legitimately
hold nothing — the alternatives considered, the personas, the journeys, the decisions log. At section
granularity the operator answers nine questions instead of fifty, and the two that matter stand out:
on a real package the sections carrying no row included the **user stories** and the **acceptance
tests**, which is exactly the pair a reader would expect to have been inventoried and exactly the
question worth putting to a human.

**Both relations resolve against the anchor's own leading section reference**, which is the form
every anchor carries — a section number, its title, a locator within the section, and the line. That
one form makes the line-number half of an anchor an aid rather than an ambiguity: an anchor is
resolved by its section, and the line locates the row inside it. **Where no anchor parses at all,
that is a read failure and is reported as one** — never as a document with no coverage
(`workflows-core:grounding-format` §2.1).

### 2.1 A slice's inventory

A **slice** — a BRD in every respect but its folder name, nested inside its parent's folder as the `PRD-` folder its PRD is authored in (`workflows-core:addressing` §6) —
has no source document of its own: the customer supplied one document, and the slice is a partition
of that document's requirements, not a second document. So a slice holds **no `brd/source/` and no
`brd/brd-defect-log.md` of its own; it inherits both from its parent**, resolved through the
`parent:` key in its `brd-link.md`. A slice's `[BR#n]` and `[DEF#n]` ids are its parent's ids,
unchanged — the identity of a requirement belongs to the BRD that owns the source text, and a slice
cites it rather than minting its own.

A slice **does** hold its own `brd/brd-inventory.md`: the subset of its parent's rows its
`brd-link.md` claims, copied row-for-row with `id`, `text`, `source_anchor`, and `defects` verbatim
from the parent's inventory. **"Its parent" is literal and unambiguous**: nesting is capped at one
level (`workflows-core:addressing` §6), so a slice's parent is always the BRD that owns the
source document — there is no chain to walk and no case in which the named parent holds neither.
The file opens with the two facts a reader needs to follow an anchor out of it:

```
kind: brd
key: <this folder's key — must match the folder name>
parent: <PARENT-KEY>
source: <the parent's brd/source/<basename>, relative to the parent's folder>
```

**`kind:` and `key:` open every inventory, a slice's and a source-owning BRD's alike** — a
source-owning BRD's inventory carries the two and no `parent:`/`source:` pair, because it *is* the
source owner. They are how the folder asserts its own identity (`workflows-core:addressing` §4); the
`brd/source/` document itself carries neither and never will, because it is the customer's and is
immutable (§1).

**Every `source_anchor` in a slice's inventory resolves against that path, never against anything
inside the slice's own folder** — the slice has no `brd/source/` to resolve into, which is exactly
why the header names the parent's. A slice inventory is never re-extracted from the source by
`brd-reader` and never renumbered; copying is the only way it is ever produced, because
re-extraction would mint a second set of ids for text that already has them.

**`/brd-split` writes a slice's inventory**, at the moment it creates the slice's folder — it is
the only command holding both the parent's inventory and the allocation that says which rows the
slice claims. `/brd-intake` never runs on a slice: there is no document to intake.

## 3. Defect classes

Exactly six. Each fires on a one-line test a reader applies to a single `[BR#n]` (or, for
`conflict` and `duplicate`, to a pair):

| Class | Fires when |
|---|---|
| `ambiguity` | Two competent readers can implement it differently and both be right |
| `conflict` | It cannot hold at the same time as another `[BR#n]`, which it names |
| `untestable` | No externally observable outcome would distinguish success from failure |
| `unsourced` | It asserts system behaviour that grounding must confirm before it can be built on |
| `duplicate` | It restates, or is a part of, another `[BR#n]`, which it names |
| `scope-leak` | It specifies implementation rather than the outcome required |

`conflict` and `duplicate` always name the other `[BR#n]` involved — a defect of either class
naming no counterpart is incomplete. `unsourced` is a pointer forward: it flags a requirement whose
truth grounding must settle, not a requirement grounding has already checked and found wanting.

A single `[BR#n]` may carry more than one defect (a requirement can be both `ambiguity` and
`scope-leak` at once); a defect entry is never split across two classes to force a single-class
read.

## 4. Defect resolution

A defect is **never fixed in the source** (§1). Its `brd-defect-log.md` entry carries exactly one
of these resolutions:

| Resolution | Meaning |
|---|---|
| `customer-amended <date>` | the customer supplied corrected text; the amendment is held in the ledger beside the original, never written back into `brd/source/` |
| `withdrawn` | the customer withdrew the requirement the defect was raised against |
| `resolved-by: [CG#n]` | a code- or design-grounding finding settled the defect (typically closing an `unsourced` entry) |
| `open` | none of the above has happened yet |

There is exactly one **requirement** defect log per source document, held by the BRD that owns that
document; a slice reads its parent's rather than keeping one of its own (§2.1). That is a statement
about `brd/brd-defect-log.md` and about `[DEF#n]` only: the route's **code**-defect log,
`code-defect-log.md`, is a different register with a different owner —
`references/code-defect-log-format.md` §6 — and a slice keeps its own, because a code defect belongs
to the slice's own grounding and grounding is slice-only. A consumer that must reach a
`[DEF#n]` while standing on a slice — `/brd-split`'s `rejected: [DEF#n]` resolution when it walks a
slice's ledger (`commands/brd-split.md` Phase 4), `/brd-reconcile` writing the `customer-amended` and
`withdrawn` resolutions a returned customer review settles
(`commands/brd-reconcile.md`), or any reader following the `defects` column of the slice's copied
inventory row — therefore looks it up in, and writes it to, the parent's log. That lookup is always
**exactly one hop**: nesting is capped at one level (`workflows-core:addressing` §6), so a
slice's parent always owns the source document and the log, and there is no chain to walk.

A resolution changes the defect log entry's status only. It never touches `brd/source/`, and it
never assigns the requirement a disposition — the disposition vocabulary and the artifact that
carries it belong to `references/coverage-ledger-format.md`, not to this file.

## 5. Non-goals

This reference does not describe a PRD. `workflows-core:prd-format` is the sole authority for what a Product
Requirements Document contains and how it is authored; nothing here substitutes for it, and a BRD
inventory row is never treated as PRD content in its own right.

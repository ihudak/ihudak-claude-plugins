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

### 1.1 What `brd/source/` holds, and what it could not hold

`brd/source/` holds the customer's document at its own basename **and every file that document links
from its own directory**, each at its own path relative to that directory and each copied
byte-for-byte, whatever its type. That is what makes the copy a record rather than a transcript: a
customer's BRD routinely carries screenshots, diagrams and appendices beside it, and a link the copy
did not follow resolves to nothing afterwards — no later command of the route captures it, and
`brd/source/` is never edited (§1), so no command closes the gap short of intaking the whole document
again. `/brd-intake` Phase 2 is the only writer; how a link is found and resolved is
`references/linked-sources.md`'s, and what Phase 2 copies where is stated in `commands/brd-intake.md`
Phase 2. **The markdown-only
rule above is about the *document*** — the text
a `[BR#n]` anchors into, and the one thing an unchecked conversion could silently rewrite; a file it
links is captured as it stands, whatever its type. **The intake run reads the document, every
markdown file Phase 2 copied, and every image Phase 2 copied** (`commands/brd-intake.md` Phases
2.5 and 3); a linked file of any other kind is captured, named to the operator before anything is
copied, and not read. On a re-run the copy is additive, as the document's own re-copy is: a file
an earlier intake captured and the revised document no longer links stays where it is, because
nothing under `brd/source/` is ever removed either — so the log's counts describe the run that
wrote them rather than the directory's contents.

**Whatever the copy could not capture is named in `brd/brd-link-log.md`**, never dropped in silence:
a URL, a file that could not be read, a wikilink matching more than one file in the vault — and, where
the operator chose to capture only the document's own folder, a link above that folder or an absolute
path. That log is the **plugin's** record rather than the customer's, which is why it sits in
`brd/` beside `brd-inventory.md` and `brd-defect-log.md` and never under `brd/source/`, where every
byte is the customer's own and a plugin-written file would read as part of the document they handed
over. It opens by naming the source document's basename, carries the run's counts — links found,
files copied, links not copied — and then one row per uncopied link: the target as written, the
copied file the link sits in, and the reason. **The three counts do not add up, and that is
arithmetic rather than a slip**: two documents linking the same file are two links found and one
file copied, so the first count is of links and the second of files. **It is written on every run,
including one that captured everything**, so its counts are the positive record that the capture
ran; an absent log and an empty one are not (§2.2 makes the same call for the inventory's coverage
of its source).

**The log also maps every captured link that does not resolve as written.** Its second table,
*Captured links that do not resolve as written*, carries one row per **link** whose copy cannot be
reached by reading the target as a path relative to the file it sits in — including: every link to a
file copied into `brd/source-external/`; every `[[wikilink]]`, which names a file rather than a path;
an absolute path to a file inside the document's own folder; and a link inside a `source-external/`
file whose target lies inside the document's own folder — with the target as written, the file the
link sits in, and the copy's path relative to `brd/`. **It is the only way any reader resolves such a
link**: nothing rewrites the verbatim document to point at its copy.

**`brd/source-external/` holds what the document links from outside its own directory**, where the
operator chose to capture it (`commands/brd-intake.md` Phase 1). Each file sits at its **basename** —
never at a path mirroring where it came from, which for an absolute link would write the operator's
own directory layout, home directory included, into the specs repository — with a `_NN` suffix on the
original basename where two collide, and byte-identical content reused rather than copied twice. It is
**immutable exactly as `brd/source/` is**, written only by `/brd-intake` Phase 2, and never removed
from; it sits beside `brd/source/` rather than inside it so that this section's first sentence stays
true — `brd/source/` holds what the document links *from its own directory* — and so that no folder
the customer's own tree happens to contain can collide with it.

**Which file under `brd/source/` is the customer's document is read, never guessed.** The directory
can hold several markdown files, since the document may link one beside it, so a reader that needs
the document's own name takes it from `brd/brd-link-log.md`'s opening line. A BRD intaken before that
log existed holds exactly one file under `brd/source/`, and that file is it.

### 1.2 `brd/brd-figures.md` — what the plugin read in the customer's images

`/brd-intake` Phase 2.5 has `product-workflows:figure-reader` transcribe every image Phase 2
copied, and writes what it returns here. **A transcription is the plugin's reading of the
customer's image, not the customer's words** — which is why a requirement drawn from an image
anchors on the *image* (§2), never on this file, and why `/brd-intake` Phase 4's human and the
customer's own review both check a row drawn from an image against the picture. It is the
plugin's record, so it sits in `brd/` beside `brd-link-log.md` and never under `brd/source/`.

```markdown
---
kind: brd-figures
key: <the run's <BRD-KEY> as Phase 0 validated it — never parsed from the folder name>
source: <the document's basename, as brd/brd-link-log.md names it>
written_by: brd-intake
---

# Figures: <BRD-KEY>

Images captured <n> · read <n> · reused from an earlier run <n> · not read <n>

## source/images/report.png

- **Linked from:** `source/appendix/notes.md` › Reporting
- **Read:** yes
- **Content hash:** sha256:<hex>
- **Appearance:** screenshot · **Depicts:** <one sentence>
- **Rows:** yields [BR#14], [BR#15]; illustrates [BR#6]

### Text

<verbatim, as figure-reader returned it>

### Annotations

| Says | Points at |
|---|---|
| "add a filter here" | the column header row |

### Flow

<diagrams only; otherwise "none">

### Illegible

none
```

- **One section per image `/brd-intake` Phase 2 copied**, in capture order, headed by the image's path
  **relative to `brd/`** — `source/…` or `source-external/…`. Every path in this file is relative to
  `brd/`, so one form names a file under either directory.
- **Linked from** names every file that links the image, each relative to `brd/`, with the heading
  path of the passage that links it.
- **Read** is `yes`, or `no — <reason>` with `figure-reader`'s reason (`missing`, `not_an_image`,
  `unreadable`); an image not read carries no transcription sections, only its header lines.
- **Content hash** is the SHA-256 of the image's bytes. A later intake run keeps the section's
  **transcription** — Read, Content hash, Appearance, Depicts, and the Text/Annotations/Flow/Illegible
  subsections — verbatim wherever the hash still matches the file, and does not read that image
  again; a hash that no longer matches is re-read and its transcription replaced. *Linked from* and
  *Rows* are recomputed by the run every time, including where the image is no longer linked (below).
- **Rows** is completed by `/brd-intake` Phase 5, once the inventory is final: `yields` the rows
  anchored on this image, `illustrates` the rows whose prose the image restates, or
  `accounted for — <the operator's account>` where it does neither. **It names requirements of the BRD
  that owns this file — on a slice, the parent's, one hop (§2.1)**, which is how
  `references/bundle-packaging.md` §6.2 relation 1 reads it.
- **A section is never deleted.** An image the revised document no longer links keeps its section,
  with a line `- **No longer linked by the current source.**` under its header. Its *Linked from*
  becomes `— (no longer linked)`, and its *Rows* becomes `yields [BR#n], …` for any preserved row
  still anchored on it, else `none — no longer linked` — an inventory row the re-run preserved may
  still anchor on it. §2.2 relation 3 covers only the images the current document's capture holds,
  so it does not ask about a no-longer-linked image either way.

## 2. The inventory

The inventory (`brd/source/`'s companion `brd-inventory.md`) holds **one row per requirement**:

| Field | Meaning |
|---|---|
| `id` | `[BR#1]`, `[BR#2]`, … — contiguous, assigned once, never renumbered |
| `text` | the requirement, verbatim, or its first sentence plus a `source_anchor` when quoting it whole would be unwieldy; for a row anchored on an image, the obligation in words, quoting the transcribed element verbatim — the plugin's words, told apart from the customer's by the row's image anchor |
| `source_anchor` | where the requirement is stated — in the document, an appendix, or an image, in one of the three forms below |
| `defects` | a `[DEF#n]` list (§3) — empty when the requirement carries none |

**A requirement carrying more than one obligation is split.** When one numbered item in the source
binds the delivery team to two or more separable obligations, each obligation becomes its own
`[BR#n]` rather than being inventoried as one row with a compound `text`. The split itself is
recorded as a `[DEF#n]` of class `duplicate` (§3) naming the sibling rows it produced — the
inventory does not silently multiply one source requirement into several without a defect marking
that it did.

`[BR#n]` numbers are never reused and never renumbered, including across a split: once assigned, an
id is permanent even if the row it names is later split, superseded, or found defective.

**`source_anchor` takes one of three forms**, by where the requirement is stated:

- **In the document** — a heading path or a line range inside it, as it always has.
- **In a linked markdown file** — `<path relative to brd/> › <heading path or line range>`, for
  instance `source/appendix/fields.md › Report columns` or `source-external/glossary.md › L12-L18`.
- **In an image** — `<path relative to brd/> › "<element>"`, the element a string quoted verbatim from
  the image's transcription (`source/images/report.png › "Net total" column`), or
  `<path relative to brd/> › annotation <n>`, the n-th annotation in its §1.2 section.

**A reader tells the three forms apart by the anchor's text before ` › `**: text beginning `source/`
or `source-external/` names a linked-markdown or image anchor — which of the two, by the linked
file's extension — and any other anchor is a document anchor.

**Rows are numbered in reading order across all three**: the document's first, in source order; then
each linked markdown file's, in the order `/brd-intake` Phase 2 captured it; and a row drawn from an
image at the passage that links the image — its first link, where several do.

### 2.2 The inventory's coverage of its source is checkable from the inventory alone

**A section the read skipped and a section that genuinely holds no obligation come out of an
inventory identically — as a section with no row — so the difference cannot be read off the
artifact.** It is made visible at intake instead, and nothing is stored to do it: the sections are checked
from `source_anchor`, the document and its linked markdown, and the images from `brd/brd-figures.md`
and the `illustrates` list `brd-reader` returns beside its rows. A first design
had the reader account for every heading it passed; measured against real intakes that is fifty-odd
accounts of "this section holds context", which buries the one case worth seeing.

Three relations — the first two over the **top-level section** of the document and of every
linked markdown file Phase 2 copied, the third over the images:

1. **Every `source_anchor` resolves — in whichever of §2's three forms it takes.** A document or
   linked-markdown anchor resolves to a section that file actually has; an image anchor resolves
   by its own rule, below. Whichever form it takes, an anchor that does not resolve is a row
   nobody can trace back, in the artifact whose whole job is traceability.
2. **Every top-level section of the document and of each linked markdown file Phase 2 copied (a
   linked file with no heading at all is one section, the whole file — branch 3 below) either
   holds a row or is accounted for.** A section is held where any anchor names it, names a
   section beneath it, or links an image that yields a row (§1.2 *Linked from*). One with none is
   not a defect and is not a stop — only a person can say whether a section binds the delivery
   team to anything — so `/brd-intake` names each with what the source has under it and asks.
3. **Every image the current document's capture holds yields a row, illustrates one, or is
   accounted for.** It *yields* a row where any anchor names it, and *illustrates* one where
   `brd-reader` returned that row in the image's `illustrates`. An image that does neither — a
   logo, a decorative banner, a screenshot whose content no obligation bears on, or an image that
   could not be read — is named with its `Depicts` sentence or its reason, in the same question
   relation 2 asks.

**The granularity is the finding, not a detail.** Real BRDs run to fifty or sixty headings under
fourteen or fifteen top-level sections, and on a careful intake nine of those fifteen legitimately
hold nothing — the alternatives considered, the personas, the journeys, the decisions log. At section
granularity the operator answers nine questions instead of fifty, and the two that matter stand out:
on a real package the sections carrying no row included the **user stories** and the **acceptance
tests**, which is exactly the pair a reader would expect to have been inventoried and exactly the
question worth putting to a human.

**Relations 1 and 2 resolve a document or linked-markdown anchor against the right file first:
the document itself for a document anchor, or, for a linked-markdown anchor, the file
`/brd-intake` Phase 2 copied at the path before ` › ` — only the part after it is then tested
below (a path naming no file Phase 2 copied does not resolve). §2's anchor into that file is a
heading path *or* a line range, so both forms resolve there — in this order** (an image anchor
never reaches this test; it resolves by the rule below):

1. **A leading section reference** — `§` and a section number — resolves directly. This is the
   form every anchor carried across the corpora this rule was measured on, which is why it is
   tried first and not why it is the only branch.
2. **A heading path naming no `§` number** — written, for a nested path, with ` › ` between
   headings after the file's own path in the two path-prefixed forms (`source/appendix/fields.md
   › Reports › Columns` names the file, then the heading path `Reports › Columns`) — resolves
   only where it matches **exactly one** heading in the file, together with its named ancestors,
   each in order beneath the one before it, compared as text, to the section of the last one
   named. A path matching more than one heading falls to branch 4, whose remedy the operator can
   actually carry out: correct the anchor by hand, naming a parent heading to disambiguate it.
   Appendices and Obsidian notes rarely number their headings, and §2's own example,
   `source/appendix/fields.md › Report columns`, is exactly this form.
3. **Otherwise, the line the anchor names** resolves it: a line in the file's body falls inside
   exactly one section, so a line-range anchor is section-resolvable without the writer having
   named a section at all — and where the file has no heading at all, its whole body, after any
   frontmatter block, is that one section (Obsidian notes routinely have none, the title being
   the filename), so any line there resolves here. A line **above the first heading**, in a file
   that has one — frontmatter, a title block — is inside no section, and an anchor naming only
   such a line falls to branch 4 rather than resolving to the first section by proximity.
4. **Neither** — no section reference, no heading-path match, and no line that lands in a section
   — and the anchor does not resolve. It may be perfectly well formed; what it is, is
   unresolvable against *this* file, which is what relation 1 reports it as, per row.

**The ordering matters more than it looks.** An earlier draft of this section asserted that a leading
section reference is *the* form an anchor carries. It is what every measured anchor happened to have,
and §2 above plus `product-workflows:brd-reader` both sanction the line-range form — so the assertion
promoted an observation about one corpus into a rule the producers do not follow, and would have
stopped a correct intake as a read failure on the first anchor written the other way.

**An image anchor resolves where** its path names an image `brd/brd-figures.md` records as read,
and the quoted element appears verbatim in that image's *Text*, an annotation's *Says*, or its
*Flow* — or, for `annotation <n>`, where the image has an n-th annotation. An anchor naming an
image `brd/brd-figures.md` does not record, an image recorded as *not* read, or whose quoted
element or annotation number is absent, does not resolve — relation 1's, not relation 3's, to
report.

**Where no anchor in the whole inventory resolves, that is a read failure and is reported as one** —
never as a document with no coverage (`workflows-core:grounding-format` §2.1).

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

**`source:` names the parent's document itself, and §1.1 says which file in `brd/source/` that is** —
the directory holds the files that document links as well, so the writer of this header reads the
name off the parent's `brd/brd-link-log.md` rather than taking whatever it finds there.

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

**The same one hop reaches `brd/source-external/`, `brd/brd-figures.md` and `brd/brd-link-log.md`.** A
slice holds none of them: an appendix or image anchor in its inventory resolves against the parent's
files, exactly as a document anchor resolves against the parent's `brd/source/`.

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

**A requirement drawn from an image is tested the same way, and two rules follow from where it came
from.** An obligation an image states and **no prose anywhere in the document or its linked markdown**
states carries an `ambiguity` — *"stated only in `<image>` — binding force unknown"* — because one
competent reader builds what is drawn and another does not, and both are defensible; **unless** the
passage linking the image makes it binding by its own words (*"must match the attached"*, *"as shown
in figure 3"*, *"according to the diagram"*). An illustrative or current-state framing (*"for
example"*, *"today the screen looks like"*) does not. And a row drawn from an image that cannot hold
at the same time as a prose row is an ordinary `conflict`, naming that row — both are `[BR#n]`s, so
the rule above that every `conflict` names its counterpart needs no exception. **The classes stay
six.**

## 4. Defect resolution

A defect is **never fixed in the source** (§1). Its `brd-defect-log.md` entry carries exactly one
of these resolutions:

| Resolution | Meaning |
|---|---|
| `customer-amended <date>` | the customer supplied corrected text; the amendment is held in the ledger beside the original, never written back into `brd/source/` |
| `withdrawn` | the customer withdrew the requirement the defect was raised against |
| `resolved-by: [CG#n]` · `resolved-by: [CD#n]` | a code- or design-grounding finding settled the defect (typically closing an `unsourced` entry), or a customer decision did — the answer to the question the defect raised (`commands/brd-interview.md`, the requirement-defect question source), frozen by `/brd-reconcile` |
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

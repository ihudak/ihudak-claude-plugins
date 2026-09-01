# Idea format (embedded authority)

The canonical structure and per-section rules for a refined `idea.md`. `/idea` is the only caller — it authors against this file. `/create-prd` consumes the resulting `idea.md` **artifact**, not this format doc, and never cites it. A lean one-page brief — the seed a Product Requirements Document is built
from, NOT a mini-PRD.

## Frontmatter

```yaml
---
kind: prd
key: <the key the run was invoked with>
title: <candidate human-readable title>
slug: <candidate-kebab-slug>
sources:
  - provenance: rfe | prd | markdown | community-post | prompt | doc-grounding
    ref: <path | KEY | url>
    vendored: <PRD-folder-relative path of the copy>   # present IFF this source was vendored
created: <YYYY-MM-DD>
status: draft | refined        # refined IFF zero open [NEEDS CLARIFICATION] remain
---
```

**`kind` and `key` are required, and they are why the folder is resolvable at all.** `/idea` is the command that *creates* `PRD-<KEY>-<slug>/`, and `idea.md` is usually its only file — so until `/create-prd` writes `prd.md`, this is the one artifact carrying the pair that `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4 resolves a folder's identity from. §4 forbids recovering either from the directory name ("a key re-derived by pattern is a key nothing in the tree ever asserted"), and states as its own invariant that a folder is never keyless, "not even between its creation and its first document". A frontmatter without them leaves every later `resolve-address` on that key unable to fill `kind` and `key`. `kind: prd` is correct here even though the file is an idea: the folder is a PRD folder, and `kind` names the folder's altitude rather than this file's genre.

Rules: `status` is `refined` only when the **Open questions & assumptions** section carries zero
`[NEEDS CLARIFICATION]` markers; otherwise `draft`. `sources` lists every ingested source with its
provenance (re-running `/idea` for the same `slug` refines the existing file and appends a source).

**`ref` is never rewritten; `vendored` is what a later reader follows.** `ref` answers how the idea
arrived, and a path that resolves on nobody else's machine is still the true answer to that question.
`vendored` — written only where **Vendored sources** below actually copied that source — answers where
it can be read now. Carrying both is what lets one entry answer both questions without either of them
lying; see that section for the copy set and the rewriting rule.

## Section 1 — Problem

`## Problem` — the pain today, solution-free. Who is affected and why the current situation is
insufficient. No proposed solution, no technology detail.

## Section 2 — Who

`## Who` — the target users / personas affected. Specific roles, not "everyone".

## Section 3 — Desired outcome & value

`## Desired outcome & value` — the value hypothesis: what "better" looks like and why it matters now.

## Section 4 — Rough scope

`## Rough scope` — **In:** initial in-scope bullets; **Out:** initial guardrails. *What*, not *how*.

## Section 5 — Signals & evidence

`## Signals & evidence` — demand evidence grounding the idea: RFE reference, community-post
requesters/upvotes, wikilinked docs, and image references. Cite sources; never fabricate.

**A linked image is cited by path, and what it shows is described only where the grill settled it.**
`idea-reader` reads the images an idea source links and returns a short description of each frame, but
that description is **context, not evidence** — it says what somebody drew, not what anything does. So
an image bullet names the file and, at most, what the operator confirmed about it during the grill;
never write a frame's contents here as an established fact, and never describe an image the reader
reported it did not read. An image is also never the sole support for a bullet in this section:
demand is shown by who asked, not by a mockup existing.

**The path a bullet cites is the vendored copy's, wherever one exists.** Phase 4.5 rewrites this
section's links onto `attachments/` and `design/idea-sources/` per **Vendored sources** below; a
source that was not copied — past a cap, broken, unreadable, or not text/markdown/an image — keeps
the path it was written with, because a link is only ever repointed at a copy that exists.

**Code findings never go here.** This section is *demand* evidence only. Feasibility findings from a
`--ground-code` run — what the code already does, what is missing, and any reframing they force —
belong in **Feasibility grounding** (Section 7).

## Section 6 — Prior art (optional)

`## Prior art` — an existing PRD the operator supplied that this idea covers, continues, parallels, or
rewrites. **Write it when the source is a `prd` the user supplied; omit it entirely
otherwise.** One bullet per entry, in one of two shapes.

**Discovered** — the finder matched the item, so every slot has a source:

```
- [[<work doc>]] (<KEY>, <status>) — <relation>: <one line>
```

**Supplied only** — a `prd` source the finder did not match (the operator supplied it directly). The `tracked` block carries `key`, `status`, and `summary` and nothing else — no
`relation`, no `match_reason`, no path — so the bullet omits the wikilink and the relation
rather than inventing either:

```
- <KEY> (<status>) — supplied source: <summary>
```

Never promote a supplied-only entry into the discovered shape by guessing a `relation`; the closed
vocabulary is the finder's output, not the author's choice.

Every slot is **transcribed from what the user supplied, never invented**:
`<KEY>` and `<status>` from its `key` / `tracked_status`, `<relation>` verbatim from its
`relation` field, and `<one line>` a plain-language rendering of
that entry's `match_reason` — why this initiative bears on the idea.

The **key is the durable identifier**; a path is a convenience that dangles once a folder is renamed, so both are carried and a later reader re-resolves by key. An entry with no key carries
only the wikilink, and that is accepted. Never fabricate a key or a status — an unresolved status is
written as `status unknown`. A `prd` source appears here **and** in `sources:`: `sources` answers how the
idea arrived, `## Prior art` answers what it must stay consistent with.

## Section 7 — Feasibility grounding (optional)

`## Feasibility grounding` — what the code says today about whether this idea is needed and how large it
is. **Write it when code grounding ran *and* returned at least one finding; omit it entirely
otherwise** — a grounded run that found nothing writes no empty section and no "nothing found" line.

The section opens with what its claims were true of: a single line naming every grounded repo as
`<repo>@<scanned_ref>`, taken from `code-scanner`'s `prep.scanned_ref`. Code moves; a finding with no ref
is unfalsifiable a month later.

Then up to three slots, each optional and each omitted when empty:

- **What exists** — capability present in the code today.
- **What's missing** — the gap, characterised.
- **Reframing** — ONE line, written only when a finding contradicted the idea's premise: the framing the
  source implied, and the framing the code supports.

Every bullet carries a repo-qualified citation `<repo>/<path>:<line>` — the **first** entry of that
evidence's `lines` — or `<repo>/<path>` when the evidence entry has no `lines`. **A bullet with no
citation is not written**: a feasibility claim with no anchor is exactly what this section exists to
prevent.

Nothing speculative goes here. A theme the scan could not resolve is a `[NEEDS CLARIFICATION]` in
**Open questions & assumptions** (Section 8), never a hedged bullet here.

## Section 8 — Open questions & assumptions

`## Open questions & assumptions` — unresolved decisions as `- [NEEDS CLARIFICATION: <question>]`
(**capped at 3** — the highest-impact only); reasonable defaults recorded as
`- **Assumption:** <text>`.

## Section 9 — Candidate success signal

`## Candidate success signal` — how we'd know it worked (rough, outcome-oriented, technology-agnostic).

## Vendored sources — `attachments/` and `design/<frame-set>/`

`$SPECS_PATH` is the system of record. A brief whose links point at wherever the operator's source
happened to live is a provenance document nobody else can follow, so **`/idea` copies the sources it
actually read into the PRD folder and rewrites `idea.md`'s links onto the copies.** This is a rule
about the *folder* rather than a section of `idea.md`, stated here because the links it repairs are
this file's; `/idea` Phase 4.5 is its only caller and executes it inline.

**Brief quality is not what this protects.** `idea-reader` had already distilled every source into
`raw_context` and the grill had already consumed it, so a run that vendored nothing would author the
same brief. What breaks without this is the *record*.

### The two destinations

| What `idea-reader` reports it read | Where the copy lands |
|---|---|
| a text or markdown file — the source itself, and every `wikilinks_followed[]` page | `<PRD-folder>/attachments/<name>` |
| an image carrying `read: true` | `<PRD-folder>/design/idea-sources/<name>` |

**Nothing else is ever copied** — no PDF, no archive, no other binary. A linked file that is neither
text/markdown nor an image is left where it sits, its link in `idea.md` is left exactly as written,
and it is reported (below).

`design/` is not a name this file invents: it is the reserved frame-set subdirectory
`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.1 already fixes for **any** folder under
`specifications/`, reused rather than duplicated. `attachments/` is reserved the same way, and both are
listed as reserved names in `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §2. **`idea-sources` is the
frame-set name, and there is one per PRD folder rather than one per run** — a later `/idea` run over the
same folder adds to that set and rewrites its index, because a frame set per run would scatter one
idea's mockups across directories no single index could relate.

### Only what was actually read is copied

The copy set is exactly the digest's positive reads. It inherits `idea-reader`'s caps — 12 files in
total, 6 images — and adds none of its own, because a file the reader never opened is a file this rule
has nothing to copy:

- the source file itself, unless `provenance: prompt` (there is no file);
- every `wikilinks_followed[]` entry;
- every `images[]` entry carrying `read: true`.

**Four sets are deliberately not copied, and every one of them is reported rather than dropped.** A
truncation the operator is not told about is indistinguishable from a source that said less:

| Digest field | Why nothing is copied | What the run reports |
|---|---|---|
| `wikilinks_not_followed[]` | the traversal never reached it | the target, the file that linked it, and its `cap`/`depth` reason |
| `wikilinks_broken[]` | it resolves to nothing | the target as written |
| `images[]` with `read: false` | it was never opened | the path and its `cap`/`unreadable`/`not_an_image` reason |
| `links_other[]` | it resolves to a file that is neither text/markdown nor an image | the path and its extension |

**None of the four is fatal**, and none of them has its link rewritten: a link is repointed only at a
copy that exists.

**A file already inside the PRD folder is not copied.** It is vendored already, and its link is left
as written. This is the re-refinement case — `/idea <KEY> @<that folder>/idea.md` would otherwise copy
the brief into its own `attachments/`.

**Nothing empty is created.** `attachments/` is created only when a file is about to land in it, and
`design/idea-sources/` with its index only when an image is. A bare-prompt run creates neither
directory and writes no index.

### The index is mandatory, and the descriptions are what it is written from

`grounding-format.md` §6.1: `design-grounder` returns `NO_INDEX` rather than reading a frame set that
has no index, because *a filename is not a reliable statement of what a frame shows*. Writing images
into `design/idea-sources/` **without** an index would therefore create a frame set that is
permanently unreadable — worse than not vendoring the images at all. The material an index needs is
already in hand: `idea-reader` returns a `description` per read image, and an image it did not read
carries none, is not copied, and contributes no row.

`<PRD-folder>/design/idea-sources/index.md`:

```markdown
---
kind: frame-set-index
key: <the key the run was invoked with>
frame_set: idea-sources
written_by: /idea
---

# Frame set: idea-sources

Frames this `/idea` run vendored from the source(s) it read. Each description is `idea-reader`'s own
account of what the frame shows — **context, not evidence**: what somebody drew, not what anything does.

| Frame | Linked from | What the frame shows |
|---|---|---|
| `toggle-01.png` | `notes/dark-mode.md` | <the reader's description, verbatim> |
```

`Linked from` is the digest's `linked_from` — the original path of the `.md` that carried the link,
kept as the frame's provenance and never repointed at the copy. A description is transcribed verbatim
and **never** invented; §6.1's index rule exists to forbid exactly the inference a filename invites.

**Writing this index does not mean `/idea` design grounding has shipped.** Nothing on this route
dispatches `design-grounder`, produces a `[DG#n]`, or reaches `grounding-verifier` — the index makes
the frame set *readable*, not reconciled. That capability remains deliberately unbuilt and is a
decision of its own; `grounding-format.md` §6.1 says so, and this section keeps it true.

### The collision rule

Two linked files may share a basename from different directories, and a re-run meets its own earlier
copies. The destination name is the source's basename; where that name is already taken:

1. **Identical content is not a collision.** Compare the bytes. A destination file already holding
   exactly this content is reused — nothing is copied, no suffix is minted, and the link points at it.
   This is what makes a re-run over the same source idempotent, and what stops one file linked twice
   from landing twice.
2. **Otherwise append `_NN`** before the extension — `notes_01.md`, `notes_02.md`, `notes_03.md` — the
   lowest free integer starting at `01`, zero-padded to two digits and tested against the destination
   directory as it actually stands.
3. **A suffix is never compounded.** The stem a suffix is appended to is always the **original**
   basename, never a name that already carries one, so the third collision is `notes_03.md` and never
   `notes_01_01.md`. Derive the number from the directory; never derive it from the last name minted.

The same rule, with the same counter semantics, applies in **both** destinations.

### Link rewriting

Rewrite a link in `idea.md` **only** where its target was actually copied. Every other link — broken,
past a cap, an unreadable image, a PDF, an external URL, a file already in the PRD folder — is left
byte-for-byte as it stands.

The rule is: **replace the target; preserve the syntax and the display text.**

| Written as | Becomes |
|---|---|
| `[[notes]]` | `[[attachments/notes.md\|notes]]` |
| `[[notes\|see this]]` | `[[attachments/notes.md\|see this]]` |
| `![[toggle-01.png]]` | `![[design/idea-sources/toggle-01.png]]` |
| `[the note](../vault/notes.md)` | `[the note](attachments/notes.md)` |
| `![the toggle](/home/x/img/toggle-01.png)` | `![the toggle](design/idea-sources/toggle-01.png)` |

Both link syntaxes are rewritten, and absolute and relative targets alike: what decides a rewrite is
the file the target **resolved to**, never the shape of the string. A bare `[[name]]` gains an alias
equal to its original target text so that what the page renders does not change. A new target is
written relative to the PRD folder — `idea.md` sits at its root — and a space in a name is
percent-encoded in the markdown form (`%20`) and written literally in the wikilink form.

**The copies themselves are never edited.** A copy is a verbatim record of what was read, and
rewriting the links *inside* one would falsify that record. A copied page's own wikilinks therefore
still point at the tree it came from; that is correct, and it is not a defect to repair.

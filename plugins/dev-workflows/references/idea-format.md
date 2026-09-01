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
`design/idea-sources/` only when an image is. A bare-prompt run creates neither directory and writes no
index. **Creating a directory and writing its index are not the same act**: the index is written
whenever that directory holds at least one frame, including on a run that copied no image into a set an
earlier run had already populated — see *The index is mandatory*, below.

### The index is mandatory, and it describes the frame set as it stands

`grounding-format.md` §6.1: `design-grounder` returns `NO_INDEX` rather than reading a frame set that
has no index, because *a filename is not a reliable statement of what a frame shows*. Writing images
into `design/idea-sources/` **without** an index would therefore create a frame set that is
permanently unreadable — worse than not vendoring the images at all. The material a **new** row needs is
already in hand: `idea-reader` returns a `description` per read image, and an image it did not read
carries none, is not copied, and contributes no row.

**The index is rebuilt from the frame set as it stands on disk, never from the list of images this run
copied.** The set is one per PRD folder rather than one per run, so from the second run onward "what this
run copied" and "what the set holds" are different sets — and writing the smaller one leaves every
earlier frame sitting in an indexed directory that identifies none of them: §6.1's own failure at row
granularity, and silent. There is no recovering it from the inputs, either, because this run's digest
holds no `description` for a frame an earlier run vendored. It is worse again under *identical content is
not a collision* (below): an idempotent re-run copies nothing at all, so an index written from "each
image copied" would resolve to no rows.

The procedure runs **after the copies land**, and is a directory listing reconciled against the index
already there:

1. **List the images actually in `design/idea-sources/`** — every file carrying one of the image
   extensions. `index.md` is not a frame and is never a row.
2. **Preserve every existing row whose image is still in that listing, verbatim** — the frame, its
   `Linked from`, and its description exactly as they stand. This run cannot reproduce a description it
   never received, so a row it cannot reproduce is a row it must not rewrite.
3. **Append one row per image this run copied**, in copy order, after the rows already present, built from
   that image's `description` and `linked_from` in the digest — transcribed verbatim, never invented. An
   image the collision rule *reused* (byte-identical content already at the destination) is not a new
   frame and gets no second row; the row already describing it stands.
4. **An image present in the listing with no row and no `description` in this run's digest still gets a
   row** — `—` in `Linked from`, and the literal `_no description on record_` in the last column. Something
   other than an `/idea` run put a frame in this set; omitting it would rebuild the exact defect this
   procedure exists to prevent, and inventing a description for it is the inference §6.1 forbids. Report it.
5. **A row whose image is no longer in the listing is dropped**, and reported. The index states what the
   set holds, and a row naming a frame that is not there is a promise `design-grounder` would resolve to
   nothing. Nothing is restored and nothing is re-copied: this step reconciles an index with a directory,
   it never manages the directory.
6. **Write the index whenever that listing is non-empty** — not only when this run copied something. A
   re-run that copied nothing writes it too, and, with every row preserved and none appended, writes back
   exactly the file that was there. Where the listing is empty, or the directory does not exist, write
   nothing and create nothing.

`<PRD-folder>/design/idea-sources/index.md`:

```markdown
---
kind: frame-set-index
key: <the key the run was invoked with>
frame_set: idea-sources
written_by: /idea
---

# Frame set: idea-sources

Every frame this set holds, in the order it was vendored. The set is one per PRD folder and accumulates
across `/idea` runs over that folder, so a row may well predate the run that last wrote this file. Each
description is `idea-reader`'s own account of what the frame shows — **context, not evidence**: what
somebody drew, not what anything does.

| Frame | Linked from | What the frame shows |
|---|---|---|
| `toggle-01.png` | `notes/dark-mode.md` | <the reader's description, verbatim> |
```

`Linked from` is the digest's `linked_from` — the original path of the `.md` that carried the link,
kept as the frame's provenance and never repointed at the copy; a frame no run's digest accounts for
carries `—` there per step 4. A description is transcribed verbatim and **never** invented; §6.1's index
rule exists to forbid exactly the inference a filename invites, and that prohibition is why step 2
preserves an older run's row rather than regenerating it.

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
byte-for-byte as it stands, **syntax included, and deliberately so**: a wikilink that still reads
`[[rollout]]` is the visible signal that the cap bit and nothing was copied for it, which is precisely
what the author needs in order to vendor that file by hand. Converting an uncopied link to markdown
would give it the shape of a repaired link while leaving it as dead as it was.

The rule is: **replace the target, preserve the display text, and write the result as standard
markdown.**

**A rewritten link is always standard markdown, never a wikilink — and that is the point of the
rewrite.** `$SPECS_PATH` is a git repository, read on a forge's web view and in ordinary editors; it is
not an Obsidian vault. Nothing there resolves `[[name]]`, and a forge renders it as literal text. So a
link repointed *into* the repo precisely so that it would resolve, but left in wikilink syntax, still
resolves nowhere the repo is actually read — the copy lands and the record stays unfollowable, which is
the whole failure this section exists to fix. Standard markdown resolves on the forge, in editors **and**
in Obsidian, so converting loses nothing and gains the capability.

**The map this decision runs on, and where both halves come from.** Deciding on the resolved file means
holding, per copied entry, the target **as written** *and* the destination its copy landed at. The digest
carries the written form on every link array — `images[].target` beside its `path` and `linked_from`,
`wikilinks_followed[].target` beside its `from` and `path`, and the same field on
`wikilinks_not_followed[]`, `wikilinks_broken[]` and `links_other[]` — and the copy step knows the name the
collision rule minted. Pair them:

| Key | Value |
|---|---|
| the `target` as written, together with the `linked_from`/`from` it was written in | the path of that entry's copy, relative to the PRD folder |

**Nothing here re-resolves a link.** This rule opens no path of its own; the map is the whole of what it
knows, so a written form that is not a key is a link nothing copied. Match each link in `idea.md` on its
target string:

1. **Exactly one key carries that written target** — rewrite it to that key's copy. The ordinary case, and
   it is decided on the resolved file: the key exists only because that entry resolved and was copied.
2. **No key carries it** — leave it byte-for-byte, per the paragraph above.
3. **Two or more keys carry the same written target and resolved to different files** — leave **every**
   occurrence byte-for-byte, and report the ambiguity: the target, each source path it resolved to, and
   each copy it landed at. Two directories may each hold `toggle-01.png`, each linked by bare name from
   its own page; the copies are then `toggle-01.png` and `toggle-01_01.png`, and `idea.md` carries nothing
   per occurrence that says which is which. **A link left as written is one nobody else can follow; a link
   repointed at the wrong frame reads as authoritative and is false.** The second is the worse record, so
   this rule takes the first and names it rather than guessing. Targets written *differently* —
   `mockups/settings/toggle-01.png` and `mockups/onboarding/toggle-01.png`, which render identically and
   differ only in a prefix a reader skims past — are two distinct keys, and rule 1 sends each to its own
   copy. That is what keying on the written form buys, and exactly what matching on the basename would
   get wrong.

| Written as | Becomes | Note |
|---|---|---|
| `[[notes]]` | `[notes](attachments/notes.md)` | the target text becomes the link text |
| `[[notes\|see this]]` | `[see this](attachments/notes.md)` | the alias is the link text |
| `![[toggle-01.png]]` | `![toggle-01](design/idea-sources/toggle-01.png)` | embed → image; alt from the original basename |
| `![[notes]]` (a `.md` transclusion) | `[notes](attachments/notes.md)` | embed → **link**; see below |
| `[the note](../vault/notes.md)` | `[the note](attachments/notes.md)` | already standard; target only |
| `![the toggle](/home/x/img/toggle-01.png)` | `![the toggle](design/idea-sources/toggle-01.png)` | already standard; target only |

Both link syntaxes are read, and absolute and relative targets alike; only one is ever written. **What
decides a rewrite is the file the target resolved to; what identifies the link is the target as written,
and both halves are load-bearing.** Deciding on the shape of the string alone points two same-named
frames at one copy; holding the resolved path alone leaves no way back from a link in `idea.md` to the
copy it belongs to except resolving it a second time, which this rule does not do.

**Display text is preserved, never dropped and never invented.** An aliased wikilink keeps its alias; a
bare `[[name]]` takes `name` as its link text, so what the page renders does not change; a markdown link
keeps the text it already had; and a bare `![[note]]` transclusion takes its link text exactly the way a
bare `[[note]]` does — the target as written. A bare image embed has no text at all, so its alt is derived from the
**original** basename with its extension dropped — `![[toggle-01.png]]` gives `![toggle-01](…)`. Derive
it from what the author wrote, never from the name the collision rule minted, so a `_NN` suffix never
surfaces as alt text. A new target is written relative to the PRD folder — `idea.md` sits at its root —
and a space in it is percent-encoded (`%20`), which is the only form left once every rewritten link is
markdown.

**`![[note]]` on a markdown file becomes a plain link, and that is a deliberate semantic change.**
Obsidian transcludes the page's content inline; standard markdown has no equivalent, and `![…](…)`
pointed at a `.md` file renders as a broken image rather than as the page. The embed renders nothing on
a forge or in an editor either way, so *preserving* it preserves only the appearance of meaning, while
`[note](attachments/note.md)` resolves and opens the copy everywhere — including in Obsidian, where only
the inline transclusion is lost and the destination still resolves. We take the trade: a link the reader
must follow beats an embed nobody's reader expands. It is written down here so nobody restores the embed
believing the conversion was an oversight.

**The copies themselves are never edited.** A copy is a verbatim record of what was read, and
rewriting the links *inside* one would falsify that record. A copied page's own wikilinks therefore
still point at the tree it came from; that is correct, and it is not a defect to repair.

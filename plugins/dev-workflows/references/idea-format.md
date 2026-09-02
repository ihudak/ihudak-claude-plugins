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
requesters/upvotes, linked docs, and image references. Cite sources; never fabricate.

**A linked image is cited by path, and what it shows is described only where the grill settled it.**
`idea-reader` reads the images an idea source links and returns a short description of each frame, but
that description is **context, not evidence** — it says what somebody drew, not what anything does. So
an image bullet names the file and, at most, what the operator confirmed about it during the grill;
never write a frame's contents here as an established fact, and never describe an image the reader
reported it did not read. An image is also never the sole support for a bullet in this section:
demand is shown by who asked, not by a mockup existing.

**The path a bullet cites is the vendored copy's, wherever one exists.** Phase 4.5 rewrites this
section's links onto `attachments/` and `design/idea-sources/` per **Vendored sources** below; a
source that was not copied — past a cap, broken, unreadable, or not markdown/an image — keeps
the path it was written with, because a link is only ever repointed at a copy that exists.

**Cite a source in one of the two forms the digest carries — its `target` as the author wrote it, or
its resolved `path`.** Both are keys of the rewrite map below, so either is repointed at the copy.
This is the one thing this section owes that phase: the rewrite opens no path of its own and matches
on strings alone, so a bullet citing a source in a *third* form — a path tidied, shortened, or
reconstructed while writing — is a link nothing can match, and it survives into the record pointing
at the operator's own disk.

**Code findings never go here.** This section is *demand* evidence only. Feasibility findings from a
`--ground-code` run — what the code already does, what is missing, and any reframing they force —
belong in **Feasibility grounding** (Section 7).

## Section 6 — Prior art (optional)

`## Prior art` — an existing PRD the operator supplied that this idea covers, continues, parallels, or
rewrites. **Write it when the source is a `prd` the user supplied; omit it entirely
otherwise.** One bullet per entry, in one of two shapes.

**There is one shape, because there is one producer.** Nothing discovers prior art: the operator
hands over a PRD as the source, `idea-reader` tags it `provenance: prd` off its own `kind: prd`
frontmatter, and its `tracked` block carries `key`, `status` and `summary` and nothing else. So the
bullet names those three and invents no relation:

```
- <KEY> (<status>) — supplied source: <summary>
```

A **discovered** shape — a wikilinked work doc with a `relation` and a `match_reason` — belonged to a
prior-art finder this plugin no longer has. Do not write one: there is no field to transcribe a
relation from, so every such bullet would be the author guessing, and a guessed relation reads as
authoritative. (It would also put a `[[wikilink]]` into a file whose links are rewritten to standard
markdown — see *Link rewriting* below.)

Every slot is **transcribed from what the user supplied, never invented**: `<KEY>` from `tracked.key`,
`<status>` from `tracked.status`, and `<summary>` from `tracked.summary`. The **key is the durable
identifier** — a path is a convenience that dangles once a folder is renamed — so a later reader
re-resolves by key. Never fabricate a key or a status: a source whose frontmatter carries none is
written as `status unknown`. A `prd` source appears here **and** in `sources:`: `sources` answers how
the idea arrived, `## Prior art` answers what it must stay consistent with.

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
| a markdown file — the source itself, and every `wikilinks_followed[]` page | `<PRD-folder>/attachments/<name>` |
| an image carrying `read: true` | `<PRD-folder>/design/idea-sources/<name>` |

**Nothing else is ever copied** — no PDF, no archive, no other binary. A linked file the reader does
not open is left where it sits, its link in `idea.md` is left exactly as written, and it is reported
(below).

**The copy set is markdown and images because that is all `idea-reader` opens.** The traversal follows
links to `.md` pages and the image pass reads image extensions; everything else is enumerated into
`links_other[]` and never opened. So a linked `.txt` is not copied — not because it is not text, but
because nothing read it — and the run must report it in those terms. `attachments/` is the reserved
name for the text and markdown a folder vendors; what reaches it *today* is markdown.

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
| `links_other[]` | it resolves to a file the reader does not open — not markdown, not an image | the path and its extension |

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

### The index is mandatory, and its format is not this file's

`grounding-format.md` §6.1: `design-grounder` returns `NO_INDEX` rather than reading a frame set that
has no index, because *a filename is not a reliable statement of what a frame shows*. Writing images
into `design/idea-sources/` **without** an index would therefore create a frame set that is
permanently unreadable — worse than not vendoring the images at all.

**The index format and its reconciliation contract are
`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.2's, and this file restates none of it.**
That section owns the filename, the frontmatter, the table shape, the `Linked from` semantics, and
every one of the six reconciliation steps — read them there, because a reader who learns the list
from a second place learns whichever copy went stale first. It lived here while `/idea` was the
index's only writer; `/frames` is a second writer, and one format with two authorities is a format
that drifts.

**What `/idea` contributes is one row of §6.2's writer table.** The frames it accounts for are the
images it copied into `design/idea-sources/` this run; a new row's description is `idea-reader`'s
per-image `description`, transcribed verbatim and never invented, and its `Linked from` is that
image's `from` in the digest. An image the reader did not read carries no `description`, is not
copied, and is accounted for nowhere — so a frame an earlier run vendored, or something other than an
`/idea` run dropped in, lands on §6.2 step 4 and is reported rather than described. `written_by` is
`/idea`; `frame_set` is `idea-sources`; `key` is the key the run was invoked with, which is the
resolved folder's own.

**`idea-sources` is one frame set per PRD folder, not one per run** — see *The two destinations* above —
which is exactly why §6.2 rebuilds from the directory rather than from what a run copied: an idempotent
re-run copies nothing at all, and an index written from "each image copied" would resolve to no rows.

**Writing this index does not mean `/idea` design grounding has shipped.** Nothing on this route
dispatches `design-grounder`, produces a `[DG#n]`, or reaches `grounding-verifier` — the index makes
the frame set *readable*, not reconciled. That capability remains deliberately unbuilt and is a
decision of its own; `grounding-format.md` §6.1 says so, and this section keeps it true.

### The collision rule

Two linked files may share a basename from different directories, and a re-run meets its own earlier
copies. The destination name is the source's basename; where that name is already taken:

1. **Identical content is not a collision.** Compare the bytes **against every file already in the
   destination directory**, not only against the candidate name. A file already holding exactly this
   content is reused — nothing is copied, no suffix is minted, and the link points at it. Scoping the
   comparison to the candidate name instead would mint `notes_02.md` as a byte-identical twin of
   `notes_01.md` on the next run, and again on the one after: unbounded growth from a rule written to
   prevent it. This is what makes a re-run over the same source idempotent, and what stops one file
   linked twice from landing twice.
2. **Otherwise append `_NN`** before the extension — `notes_01.md`, `notes_02.md`, `notes_03.md` — the
   lowest free integer starting at `01`, zero-padded to two digits and tested against the destination
   directory as it actually stands.
3. **A suffix is never compounded.** The stem a suffix is appended to is always the **original**
   basename, never a name that already carries one, so the third collision is `notes_03.md` and never
   `notes_01_01.md`. Derive the number from the directory; never derive it from the last name minted.

4. **An edited source refreshes the copy it wrote before; it does not mint a version.** Where the
   candidate name is taken, the content differs, **and `idea.md` currently carries a link whose target
   is that destination-relative path**, the copy is *overwritten* and no suffix is minted. That third
   condition is the whole test: the only thing that writes such a link is an earlier `/idea` run
   vendoring this same source into this same folder, so what is at that name is this source's own
   stale mirror. A vendored copy mirrors a source; it is not a version history, and git already holds
   the previous bytes. Without this, editing a linked page and re-running leaves `attachments/note_01.md`
   committed and unreferenced while `idea.md` still points at the stale `attachments/note.md` — an
   orphan and a lie, repeated on every subsequent run. Report every refresh, like every substitution.

   Where the name is taken by something `idea.md` does **not** link, rule 2 applies unchanged: that is
   a genuine second file that happens to share a basename.

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
carries the written form on every link array — `images[].target` beside its `path` and `from`,
`wikilinks_followed[].target` beside its `from` and `path`, and the same field on
`wikilinks_not_followed[]`, `wikilinks_broken[]` and `links_other[]` — and the copy step knows the name the
collision rule minted. Pair them:

| Key | Value |
|---|---|
| the `target` as written, together with the `from` it was written in | the path of that entry's copy, relative to the PRD folder |
| that same entry's resolved absolute `path` | the same copy |

**Two key forms, because a brief may cite either.** Section 5 tells the author to cite a source as the
digest carries it — the written `target`, or the resolved `path` — and both come out of the same digest
entry, so both map to the same copy. Keying on the written form alone would leave every path-cited
bullet unrewritten while the copy sat beside it, which is the whole failure this rule exists to prevent;
the digest already holds both halves, so admitting both costs nothing and re-resolves nothing.

**An anchor is not part of the key.** Split a trailing `#…` off a link's target before matching, and
re-append it verbatim to the rewritten target: `[[notes#Rollout]]` becomes
`[notes#Rollout](attachments/notes.md#Rollout)`. The anchor addresses a place *inside* the file, so it
survives the repointing untouched; folding it into the key would match nothing and leave the link on the
operator's disk, and dropping it would silently lose the only part of the link that said where to look.

**Nothing here re-resolves a link.** This rule opens no path of its own; the map is the whole of what it
knows, so a form that is neither key is a link nothing copied. Match each link in `idea.md` on its
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
   get wrong. **A resolved `path` names exactly one file**, so a bullet that cited a source by path is
   never ambiguous: rule 3 can fire only on a written target.

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
and the three characters that break a markdown target are percent-encoded in it — a space as `%20`,
`(` as `%28`, `)` as `%29`. A space is the common one; the parentheses are the silent one, because
`![Screenshot (1)](design/idea-sources/Screenshot%20(1).png)` terminates at the first `)` and resolves
to nothing, in a rewrite whose entire purpose is a link that resolves.

**`![[note]]` on a markdown file becomes a plain link, and that is a deliberate semantic change.**
Obsidian transcludes the page's content inline; standard markdown has no equivalent, and `![…](…)`
pointed at a `.md` file renders as a broken image rather than as the page. The embed renders nothing on
a forge or in an editor either way, so *preserving* it preserves only the appearance of meaning, while
`[note](attachments/note.md)` resolves and opens the copy everywhere — including in Obsidian, where only
the inline transclusion is lost and the destination still resolves. We take the trade: a link the reader
must follow beats an embed nobody's reader expands. It is written down here so nobody restores the embed
believing the conversion was an oversight.

**The copies themselves are never edited.** A copy is a verbatim record of what was read, and
rewriting the links *inside* one would falsify that record. A copied page's own links therefore
still point at the tree it came from; that is correct, and it is not a defect to repair.

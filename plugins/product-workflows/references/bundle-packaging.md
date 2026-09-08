# Bundle packaging (embedded authority)

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

How the customer-facing bundle for a BRD→PRD package is built, what it may and may not contain, the
three degradation tiers a bundle can ship at and what each obliges the reviewer to state, the
delivery note's hard length rule, and where the rendered bundle lands and why it is committed.
Design authority: `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §8.1, §8.3 and
§8.5, and decision rows D12, D13, D18 and D20 in §3.

Neighbouring rules are owned elsewhere and cited, not restated: the twelve sections a returned
review carries, and the constraint that governs the one file rendered verbatim into the customer's
prompt, belong to `references/customer-review-schema.md`; the finding record and the
`baseline-integrity` procedure whose three commands the prompt hands the reviewer to re-run belong
to `workflows-core:grounding-format` §2 and §4, and its reading rule and its class-4
citation-correctness rule, both of which §6 cites rather than restates, belong to §2.1 and §6.3 of
the same file; the `[CD#n]`/`[AS#n]` record shape, `conditional_on`, and the rule that every open
`[AS#n]` reaches the customer belong to `references/decision-register-format.md` §1, §5 and §7; the
coverage ledger's dispositions belong to `references/coverage-ledger-format.md` §3; the `<BRD-KEY>`
grammar and BRD-folder resolution belong to `workflows-core:addressing` §1 and §3; the commit entry
point every bookkeeping write into the specs repo runs through belongs to
`workflows-core:specs-repo-git`.

**Consumed by `commands/brd-package.md`**, which builds a bundle against this contract — its
plugin-free rules, its §1.1 content allow-list, its de-Obsidianising pass, its degradation tiers,
its delivery-note ceiling, its committed dated directory and its §6 citation-resolution check — and
cited by `agents/brd-package-reviewer.md` for what the customer will actually be able to open.
`commands/brd-reconcile.md` reads a review returned against a bundle built this way, and cites §5
for why nothing inside that committed directory is ever bannered or rewritten afterwards.

## 1. Plugin-free by construction (D12)

The bundle must work for a reviewer with a vanilla agent and **nothing installed** — no plugin, no
skills, no MCP server. That is not a nice-to-have: no customer can be required to install anything
in order to review what was sent to them. Four rules follow, and every one of them is about what the
bundle may assume of the machine it lands on.

1. **The prompt is self-contained.** No path rooted at the plugin's install directory, no slash
   commands, no skill invocations, no MCP assumptions. The review schema is **inlined in full** —
   rendered from `references/customer-review-schema.md` at build time rather than quoted,
   summarised, or linked, so the shipped prompt and the authority cannot drift apart. That file
   carries its own plugin-free constraint and states which part of it is rendered; nothing here
   overrides it.
2. **No harness-specific instructions.** The prompt is written in the vocabulary any agent has —
   *read the file named X*, *search this bundle for a file whose name contains Y*, *run this in a
   terminal*. It states its assumed capability set in one line at the top, so a reviewer on a weaker
   tool learns immediately what they cannot do, rather than discovering it four sections in.
3. **The bundle is de-Obsidianised.** §2.
4. **Documents are located by filename search, not by path.** Every reference from one bundle
   document to another, and every instruction in the prompt that sends the reviewer to a document,
   names a **filename** and tells the reviewer to search for it.

**Why filenames and not paths.** Paths drift the moment a bundle is extracted and renamed — and it
will be renamed, because it arrives as an attachment and lands in whatever directory the reviewer
keeps attachments in. A path is correct exactly once, in the directory layout the packaging machine
had; a filename survives extraction, renaming, re-zipping, being mailed on to a colleague, and being
dropped into a different tool. The cost is that filenames must then be distinctive enough to search
for, which is a constraint on how bundle documents are named, not a reason to fall back to paths.

### 1.1 What the bundle contains — an allow-list, and why it is not a deny-list

**A document reaches the bundle only where a part of the rendered prompt sends the reviewer to it.**
That is the whole rule, and it is stated as an **allow-list** rather than as "the package's
documents, minus the following" for one reason: a deny-list is silent about every artifact nobody
thought of, and the BRD folder accumulates artifacts. Under a deny-list a new working record ships
by default and is caught only if somebody remembers to exclude it; under the allow-list it stays by
default and ships only once a prompt part actually cites it. The failure mode is not symmetric — a
document wrongly withheld produces a reviewer question, and a document wrongly shipped cannot be
recalled — so the default belongs on the side of withholding.

Exactly this, and nothing else:

| In the bundle | Which prompt part sends the reviewer to it |
|---|---|
| the rendered customer prompt | it is the entry point |
| the customer's own source document — `brd/source/<basename>`, **the parent's on a slice** (`references/brd-format.md` §2.1) | requirement traceability: the review's own section 4 asks whether the package read the customer's document correctly, which is unanswerable without that document |
| `brd/brd-inventory.md` | *Review scope* |
| `brd/brd-defect-log.md` — **the parent's on a slice**, one hop, exactly as an inherited `[DEF#n]` already resolves (`references/brd-format.md` §4) | *Review scope*: a ledger row reading `rejected: [DEF#n]` cites an id the reviewer must be able to resolve |
| `coverage-ledger.md` | *Review scope*, and *what this session cannot settle* |
| `grounding/code-grounding.md` and `grounding/design-grounding.md` | *the single most important claim to verify first* |
| `grounding/baselines.md` | *code baselines and the verification procedure* |
| `decisions.md` | *the single most important claim to verify first*, *the decisions the customer must make*, *what could still move* |
| `interview/customer-questions.md` | *the decisions the customer must make* |
| every prerequisite package copied in, marked *not for re-review* | *what each package in the bundle is for* |
| every image the documents above reference | they are embedded in them (§2) |
| the manifest | *documents to review* |

Plain markdown and images — nothing else (§2). The manifest lists documents by filename, for the
same reason rule 4 does.

**What the bundle does not contain**, each named because each is a document sitting in the same
folder under the same `<BRD-KEY>`-and-date naming, indistinguishable from a package document by
filename alone:

- **The delivery note** (§4). It is the covering letter, not a package document.
- **`self-review-<YYYYMMDD>.md`.** This is the one exclusion that is a *rule* rather than a
  consequence of the allow-list, and it is load-bearing: that file holds every `[SR#n]` the
  adversarial pass raised, including the ones disposed `rejected-with-reason`, whose reason
  "stays inside the delivery organisation. Nothing rejected reaches the customer"
  (`commands/brd-package.md`, *The disposition gate*). The `[SR#n]` content the customer may see is
  carried into the prompt **filtered** — `accepted-risk` findings under *where to attack us hardest*
  and `escalated-to-customer` findings under *the decisions the customer must make* — so shipping
  the file itself would defeat that filter and hand the customer an internal disagreement to
  referee. It also carries the model the pass actually ran on, which is delivery-side bookkeeping.
- **Every other working record in the BRD folder** — `slices.md`, `brd-link.md`, the three seed
  files, `interview/round-<N>.md`, earlier `reconciliation-<YYYYMMDD>.md`, earlier
  `customer-review-<YYYYMMDD>.md`, and `dev-workflows/`. No prompt part sends the reviewer to any of
  them.

**The plugin-free scan does not cover this.** It hunts plugin-internal tokens (§1 rules 1–2), and
every document above is free of them whether or not it belongs in a customer's hands. Nothing
mechanical stands behind this allow-list, which is why it is written out rather than left to
"the package's own documents".

## 2. De-Obsidianising

The working documents live in a vault and use its syntax. The bundle is a **rendered copy**,
produced on the way out; the working documents keep their wikilinks and are never rewritten in
place. A de-Obsidianising pass that edits the source is a data-loss bug wearing a formatting fix.

**Wikilinks are rewritten to plain filename references.** `[[Some Document]]` resolves to nothing
outside the vault: in every other reader it is literal text with brackets around it, and a reviewer
who clicks it, searches it, or asks an agent to open it gets nothing. It is worse than a missing
link, because it looks like a link. The rewrite names the target file as the reviewer will actually
see it, so it can be searched for.

Three cases the rewrite has to get right:

- **An aliased link** (`[[Some Document|the ingest contract]]`) keeps the alias as the visible text
  **and** names the file. The alias alone names nothing the reviewer can search for; the filename
  alone loses the phrasing the sentence depends on.
- **An embedded image** becomes an ordinary markdown image reference to the image file copied into
  the bundle beside it. An image that is not copied has no reference left behind pointing at it —
  the embed is replaced by a plain sentence saying what was there and that it is not included.
- **A link whose target is not in the bundle** is **never** rewritten into a bare filename. A
  filename that is not in the bundle is the failure mode this whole section exists to prevent: it
  looks resolvable, the reviewer searches for it, finds nothing, and cannot tell whether the file
  was forgotten, withheld, or renamed. Such a link becomes a plain description of the target and an
  explicit statement that it is not included.

**The three cases above are about rewritten links, and the rule does not stop there.** A bundle
document that names a file **in prose** — not as a link — makes the identical promise to the
reviewer and breaks it the same way. That is not hypothetical: a shipped bundle named
`self-review-<YYYYMMDD>.md`, which §1.1 excludes by rule, in ordinary prose, and named three
grounding files by their working filenames after this pass had renamed them. Both survived
everything, because a rewrite rule inspects links. §6's relation 3 covers prose and links alike.

### 2.1 The customer's own source document is copied byte for byte, never rendered

**The one file in the bundle the de-Obsidianising pass does not touch is `brd/source/<basename>`**
(§1.1; the parent's, on a slice). It goes in as the bytes `/brd-intake` copied, unrewritten,
unreflowed, and with nothing removed — even where it carries something that renders in exactly one
tool. Three reasons, and each is fatal on its own:

- **Every `[BR#n]` anchors into it by `source_anchor` — a heading path or a line range**
  (`references/brd-format.md` §2). A rendered copy moves lines and can rewrite headings, so a
  requirement's anchor stops resolving in precisely the copy the customer was given to check
  traceability against. Requirement traceability is the *reason* the file is in the bundle at all;
  a pass that breaks it defeats the inclusion.
- **It is immutable by rule** (`brd-format.md` §1): nothing under `brd/source/` is ever edited,
  reworded or reformatted, "no matter how badly worded a requirement inside it is". A bundle copy
  that has been tidied is an edit the rule forbids, made where nobody looks for one.
- **It is the customer's own writing, handed back to them.** §3's one-new-file rule exists so that
  "nobody can otherwise tell what was sent from what was changed"; returning their document
  reformatted is that failure committed by the delivery team first.

Where that leaves something a plain reader cannot open — an embedded image, a one-tool block — the
fix is **beside the file, never inside it**: copy the image in as §2 already requires, and say in the
manifest what the reader may not be able to see. The manifest is prose this package wrote and may
say anything; the source document is not.

**Callouts are kept.** A `> [!note]` block degrades to an ordinary blockquote in any markdown reader
— the reader loses the label's styling and keeps every word. Nothing that survives untranslated is
worth translating.

**Plain markdown plus images, and nothing else.** No canvas or database-view files, no query or
dataview blocks that render as an empty region in any other tool, no plugin-specific embed syntax,
no frontmatter that means nothing to a reader outside the vault. Anything that renders in exactly
one tool is either converted to something that renders everywhere or removed with a note saying what
stood there. A block that silently renders as nothing is the same defect as the dead wikilink: the
reviewer cannot see that they are missing something.

## 3. Degradation tiers

A bundle ships at one of three tiers. The tier records **what the reviewer was actually able to be
given**, and the prompt states it explicitly along with the sentence the reviewer's own
evidence-limitations section must then carry.

| Tier | The reviewer has | What their review must state about its own evidence |
|---|---|---|
| Full | The documents, plus repositories pinned to the commits the package cites | That code claims were independently verifiable, and what the pin-verification procedure returned when they ran it |
| Partial | The documents, plus repositories that are not pinned — an archive of a moving branch | That every code claim they confirm is true of **an unidentified snapshot**, because nothing ties what they read to the commit the package cites |
| Documents only | The documents, and no repositories | That **no code claim in the package was independently verified** by this review |

**The tier is assigned from what was shippable, not chosen by the reviewer.** It is a fact about the
bundle, established when the bundle is built and written into the prompt. A reviewer cannot promote
themselves to Full by being thorough, and the bundle is never quietly shipped at Full because the
repositories were *probably* at the right commit — an unpinned archive is Partial, and it says so.

**A tier is not a quality grade.** A documents-only review that states its tier is more useful than
a full-tier review that does not: the first can be weighed correctly, the second cannot be weighed
at all. This is the whole purpose of the tier reaching the customer — it is what makes a returned
review honest about its own limits, and therefore readable.

**The failure this prevents** is a package built on confirmations whose evidentiary weight nobody
recorded. Months later the review is the record, and a confirmation that was in fact an unverified
reading of a document is indistinguishable from one checked against a pinned commit — unless the
review said which it was, at the top, before the confirmations.

## 4. The delivery note

The covering letter that goes in the email body. It is written to a file in the BRD folder and
printed in full at the end of the packaging run, so it can be pasted without opening anything. **It
is not part of the bundle** — it is the email, not a package document, and a copy of it inside the
bundle would be a second, divergent statement of what was sent.

**Hard length rule: 200 words.** Not a target, a ceiling. Past roughly that length the note stops
being a covering letter and becomes a document, and a document is precisely what nobody reads before
clicking into the attachment — which puts the two facts that must not be missed back inside the
thing they were lifted out of.

It states only:

- which BRD this is
- what is attached
- which repositories, at which commits
- **which file is the prompt** — the one file to paste
- **which file comes back** — the one file to send, named exactly
- any prerequisite whose decisions are still provisional, and that positions resting on it could
  move (D20)
- anything else that must not sit buried inside a document

**It is not a per-file table.** The manifest inside the bundle covers per-file detail, and
duplicating it in the note guarantees the two disagree after the first correction. The note answers
what the reader needs before they open anything; everything else is inside.

**Why the two bolded items are bolded.** The single most common failure of this loop is a reviewer
who reads the documents, forms a view, and writes it into an email or a document of their own
devising — because nothing they read in the first thirty seconds told them there was a prompt to
paste and a named file to return. Both facts are one line each, in the covering letter, where they
cannot be missed.

## 5. Where the bundle lands

The rendered bundle is written to **`bundle-<YYYYMMDD>/` inside the BRD folder** — resolved per
`workflows-core:addressing` §3 — and **committed to the specs repo** (D18), as a **deliverable**:
through `handoff-to-main` (`workflows-core:phase-handoff` §2), behind that reference's §4.3 consent
choice, with every file under the dated directory in the calling command's `deliverable_paths`.

**Not through `workflows-core:specs-repo-git`, and the difference is not pedantry.** That reference
owns the plugin's *bookkeeping* commit, and its §2.1 bounds staging to three path shapes, all of them
under `dev-workflows/**` — a bundle is under none of them, so `commit-artifacts` cannot stage one and
was never meant to. A reader sent to the wrong entry point finds the bundle missing from §2.1 and
reaches for the plausible repair, which is to widen those path shapes; that would let the prompt-free
bookkeeping step commit a customer-facing deliverable with no consent choice in front of it, which is
exactly the boundary the two references were split to hold (`workflows-core:phase-handoff` §1 rule 7).

**"Committed" therefore means "committed where the operator accepted the handoff".** Declining §4.3's
choice leaves the bundle written and uncommitted, and the run says so — D18 is what the accepted path
achieves, not something this file can assert of every run.

For a synthetic BRD `EPIC-008` packaged on 15 April 2026, that is `bundle-20260415/` beside the
package's other dated artifacts.

**Committing it serves both delivery routes with one artifact.** A customer with access to the
repository pulls the bundle directly and needs nothing else. Everyone else gets **one archive
command** — printed at the end of the run with an absolute path, producing a single archive of the
whole dated directory, in a format the customer can open without installing anything. One command,
because the population that cannot pull the repository is exactly the population that will not
assemble an archive command themselves.

**The committed copy is the permanent record of exactly what was sent.** This is the point of D18
and the reason the cost is worth paying: it is what makes the byte-identical property behind the
one-new-file rule checkable months later. When a returned review quotes a sentence, there is a
committed copy of the document that sentence came from, at the version the customer actually
received — not a reconstruction from the working documents, which have moved on.

**A dated bundle is never rewritten.** A second package for the same BRD is a new dated directory
beside the first, not an edit of it. Rewriting `bundle-20260415/` destroys the only evidence of what
the reviewer of that date was looking at, and every claim in their returned review silently
re-points at a document they never saw.

**The acknowledged cost** is a derived duplicate in the repository: the bundle's documents are
rendered copies of documents the repository already holds, and each package adds another dated
directory. That is deliberate. A derived duplicate that is never rewritten is a cheap price for a
record that is still true when somebody re-opens the argument a year later.

## 6. Citation resolution

**`citation-resolution`** is a check over the assembled bundle that the plugin-free scan (§1) does
not perform. That scan deliberately exempts identifiers — `[BR#n]`, `[CG#n]`, `[DG#n]`, `[VD#n]`,
`[AS#n]` and `[SR#n]` are how a returned review cites the package's own claims without minting
identifiers of its own, and a prompt that hid them would get back a review nothing could be matched
to. **Nothing then checks that they land.** Three failures were observed in shipped bundles: a
class-4 design finding whose `[CG#n]` citation resolved, inside the customer's own bundle, to a
real finding about a different requirement; a reference naming an id above the highest its own
corpus contains — one of them the sole `evidence` on a decision record; and a reference, in prose
rather than a link, to a document §1.1 excludes by rule or has already renamed on the way in. Design
authority: `docs/superpowers/specs/2026-09-08-bundle-citation-resolution-design.md` §3–§7.

### 6.1 The corpus is built per source package, and never crossed

A prerequisite package is copied into the bundle wholesale (§1.1), carrying its own grounding
files, its own inventory and its own register — each numbered from 1 in its own corpus. So one
bundle can hold two different `[CG#7]`s. Bundle documents therefore **partition by provenance**:
this package's own documents, and each copied prerequisite package's subtree. Each partition parses
its own corpus from its own files:

| Class | Corpus file, within the partition |
|---|---|
| `[BR#n]` | `brd/brd-inventory.md` |
| `[DEF#n]` | `brd/brd-defect-log.md` (the parent's on a slice, one hop — `references/brd-format.md` §4) |
| `[CG#n]`, `[DG#n]` | `grounding/code-grounding.md`, `grounding/design-grounding.md` |
| `[VD#n]`, `[CD#n]`, `[AS#n]` | `decisions.md` (`references/decision-register-format.md` §1 and §7) |
| `[SR#n]` | **none — exempt entirely, §6.3** |

**Every corpus is parsed, never assumed.** An identifier reference is resolved against the set of
ids actually parsed out of its corpus file, never by matching a fixed column or a fixed run of
leading spaces (`workflows-core:grounding-format` §2.1). That section's own precedent is why: a
column-anchored scan once reported 140 findings as missing that were on the page, because one block
in a `code-grounding.md` padded its `id:` colon for alignment and the next did not. The identical
scan run here, over a bundle's copied corpus files, would report every reference in the bundle as
dead. A corpus file that is present and non-empty but parses to zero ids is not read as an absence
either — it stops the run with `BRD_PACKAGE_CORPUS_UNREADABLE`, naming the file and the partition,
because a scan that cannot read a block has learned nothing about whether the ids it names exist.

### 6.2 The three relations

**Relation 1 — every identifier reference resolves inside its own partition's corpus for that
class, unless it carries the owning BRD key at the point of use.** The qualified form is
`<BRD-KEY> [CG#7]` — the key immediately before the bracketed id — and it is **one spelling only**:
`workflows-core:grounding-format` §2.1's whole argument is that a writer free to choose between two
renderings produces an artifact whose readers are wrong in a way that looks like data, and a
qualified citation is exactly such a rendering choice. This also repairs a live ambiguity the check
merely surfaces: today a reviewer reading a copied prerequisite's grounding file meets `[CG#7]` with
nothing telling them whose numbering it is.

**Relation 2 — for every `[DG#n]` whose `class` is 4, its `cites` resolves within the same
partition, and the cited `[CG#n]`'s `claim` names the same requirement id as the citing finding's
`claim`.** The rule itself belongs to `workflows-core:grounding-format` §6.3, which requires the
citation and requires it correct; §6 is its first enforcer. **The test is that the claim names the
id, not that it opens with it:** §2.1's own canonical example does open with the id —
`claim: [BR#7] — the nightly export runs at 02:00 UTC` — but that same section sanctions a
hand-edited artifact everywhere else on this route, so a claim reading "the nightly export, per
`[BR#7]`, runs at 02:00" is correct content that a position test would refuse. **Where a claim names
more than one requirement id, §6 reports the ambiguity rather than picking one** — a silent pick is
a guess.

**Relation 3 — a bare `<name>.md` token, carrying no path separator, must name a document that is
in the bundle, and only when it is one of two shapes.** Either it carries the `<BRD-KEY>-` prefix
that `commands/brd-package.md`'s *Assemble the bundle* rule 1 gives every bundle document, or it
exactly matches the **working** filename of a document §1.1 admits or excludes by name — **derived
from §1.1's own table each time this relation runs, never copied into a second list here**, because
a document added to §1.1 without a matching entry here would be invisible to exactly the check that
exists to catch it. The scoping is what keeps the relation off correct content: a grounding
finding's `evidence` field is a repository `file:line` list, and a repository that documents itself
in markdown puts a bare `docs/api.md:12` into a finding that is entirely correct — an unscoped rule
would refuse the whole bundle over it.

Relations 1 and 3 fail the same way — a reference that resolves to nothing — and stop the run with
`BRD_PACKAGE_DEAD_CITATION`, naming the id or filename, the document it sits in, and the corpus or
bundle it failed to resolve against; the remedy is to fix or qualify the reference. Relation 2 fails
differently — the reference resolves, to a finding about a different requirement — and stops with
`BRD_PACKAGE_CITATION_MISMATCH`, naming both `claim`s; the remedy is to re-derive the finding, and
the reference itself may be untouched. The two stay separate codes because the two remedies repair
different things.

### 6.3 Two exemptions

**`[SR#n]` is exempt entirely.** `self-review-<YYYYMMDD>.md` is excluded from the bundle by §1.1's
one exclusion that is a *rule* rather than a consequence of the allow-list, while the `[SR#n]`
content the customer may see reaches them **filtered** — through the prompt's parts 7 and 9, cited
by id, never the file itself. So an `[SR#n]` reference is correct content that resolves to nothing
in the bundle, **by design**, and a check without this exemption fires on every package. The
distinction a reader needs: naming the self-review *file* is dead — relation 3 catches it — while
naming an `[SR#n]` id is the filter working as intended, and relation 1 must not catch it.

**`brd/source/<basename>` reports rather than stops.** The customer's own document is copied byte
for byte and is immutable by rule (§2.1, `references/brd-format.md` §1). It inherits the
plugin-free scan's existing treatment verbatim, and for the identical reason: stopping outright
would make that BRD permanently unpackageable, since the one repair the rule allows is not editing
the file. Every other document's hit stays a hard stop.

### 6.4 What §6 cannot see

Stated because a green check here is otherwise read as a clean bundle:

- **A reference that *describes* a bundle document where rule 1 requires it to *name* one.** No
  pattern separates a deliberate description from a missing filename.
- **A citation that resolves to the right id and is wrong in a way relation 2 does not test** — a
  `[CG#n]` about the right requirement but the wrong claim within it.
- **An identifier class shipping without a row in §6.1's table.** The table is a closed list; the
  reverse case — a row whose file is not in the bundle — is `BRD_PACKAGE_CORPUS_UNREADABLE`, never
  a silent skip.

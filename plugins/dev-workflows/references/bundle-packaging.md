# Bundle packaging (embedded authority)

How the customer-facing bundle for a BRD→PRD package is built, what it may and may not contain, the
three degradation tiers a bundle can ship at and what each obliges the reviewer to state, the
delivery note's hard length rule, and where the rendered bundle lands and why it is committed.
Design authority: `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §8.1, §8.3 and
§8.5, and decision rows D12, D13, D18 and D20 in §3.

Neighbouring rules are owned elsewhere and cited, not restated: the twelve sections a returned
review carries, and the constraint that governs the one file rendered verbatim into the customer's
prompt, belong to `references/customer-review-schema.md`; the finding record and the
`baseline-integrity` procedure whose three commands the prompt hands the reviewer to re-run belong
to `references/grounding-format.md` §2 and §4; the `[CD#n]`/`[AS#n]` record shape, `conditional_on`,
and the rule that every open `[AS#n]` reaches the customer belong to
`references/decision-register-format.md` §1, §5 and §7; the coverage ledger's dispositions belong to
`references/coverage-ledger-format.md` §3; the `<BRD-KEY>` grammar and BRD-folder resolution belong
to `references/brd-addressing.md` §1 and §2; the commit entry point every bookkeeping write into the
specs repo runs through belongs to `references/specs-repo-git.md`.

**Consumed by `commands/brd-package.md`**, which builds a bundle against this contract — its
plugin-free rules, its de-Obsidianising pass, its degradation tiers, its delivery-note ceiling and
its committed dated directory — and cited by `agents/brd-package-reviewer.md` for what the customer
will actually be able to open. `commands/brd-reconcile.md` reads a review returned against a bundle
built this way, and cites §5 for why nothing inside that committed directory is ever bannered or
rewritten afterwards.

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

**What the bundle contains:** the package's own documents, the prompt, any dependency package copied
in and marked *not for re-review*, the images those documents reference, and a manifest. Plain
markdown and images — nothing else (§2). The manifest lists documents by filename, for the same
reason rule 4 does.

**What the bundle does not contain: the delivery note** (§4). It is the covering letter, not a
package document.

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
`references/brd-addressing.md` §2 — and **committed to the specs repo** (D18), through the commit
entry point `references/specs-repo-git.md` owns.

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

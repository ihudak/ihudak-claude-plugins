# Bundle citation resolution — design

**Status:** approved in brainstorming 2026-09-08, not yet implemented. Ledger item **E-2**, sequenced after gate 3. Blocks the release under S18.

**Ledger:** `docs/superpowers/brd-route-follow-ups.md` § E-2.

## 1. The problem

`/brd-package` renders a customer prompt and assembles a bundle, then runs two passes over the result: the **plugin-free scan** (Phase 6's `The plugin-free scan`, re-run over the delivery note in Phase 7 and over every bundle document in Phase 8 step 7) and the **de-Obsidianising pass** (Phase 8 step 2, `bundle-packaging.md` §2).

Both are correct and neither checks what this design adds. The scan deliberately exempts identifiers — `[BR#n]`, `[CG#n]`, `[DG#n]`, `[VD#n]`, `[AS#n]` and `[SR#n]` are how a returned review cites the package's own claims without minting identifiers of its own, and a prompt that hid them would get back a review nothing could be matched to. **Nothing then checks that they land.**

Three failures were observed in shipped bundles:

1. **A citation that resolves to the wrong requirement.** `workflows-core:grounding-format` §6.3 makes the citation the entire content of a class-4 design finding — *"This class always cites a `[CG#n]` … A `[DG#n]` of this class carrying no `[CG#n]` citation is incomplete."* §6.3 requires the citation to be **present**; nothing requires it to be **correct**. In the observed corpus, 16 of 17 class-4 citations resolved, inside the customer's own bundle, to a finding about a different requirement. The one that was right was right by coincidence — the two numberings happen to coincide for the first row or two. **This is worse than an absent citation, because it resolves**: a reviewer follows it, lands on a real finding in their own bundle, and cannot tell it is the wrong one.
2. **References above the corpus.** 11 references named ids higher than the highest the corpus contains, belonging to a different BRD's corpus. Three were unattributed, and one of those was the sole evidence for a question being put to the customer — a decision record's `evidence` field, which `product-workflows:decision-register-format` §1 fills with `[CG#n]`/`[DG#n]` ids.
3. **A guaranteed dead reference.** `bundle-packaging.md` §1.1 excludes `self-review-<YYYYMMDD>.md` from the bundle while bundle documents name it in prose. §2's rewrite rule governs **links**, not prose, so it survives both passes — as did three references to grounding files by their *working* filenames after the bundle renamed them, which Phase 8's rule 1 already forbids and nothing verifies.

**Severity correction, carried from the ledger.** The mechanism that produced failure 1 is retired. That corpus had a slice carrying its **parent's** design findings, which requires the parent to have been ground; slice-first grounding removed root grounding entirely, and the sibling re-cut moves no findings. It came from the documented hand deviation recorded as BRD-5, on a pre-split tree. **The defect stays real** — existing bundles carry it, and a bundle check must catch a broken citation however it got there — but it is not a live regression source.

## 2. Decision

**A new check runs beside the plugin-free scan, over the assembled bundle, and stops the run the same way.** Its rules live in `product-workflows:bundle-packaging` as a new **§6**, the same embedded authority that owns the plugin-free rule (§1) and the de-Obsidianising rule (§2); `/brd-package` Phase 8 executes it as a new **step 8**, immediately after step 7.

**The seam is forced, not chosen.** Both inputs the check needs — the identifier corpus and the set of bundle filenames — are facts about the *assembled* bundle. Phase 6's scan runs before assembly and cannot see either. The rendered prompt is still covered, because the prompt is itself a bundle document.

## 3. The corpus is built per source package, and never crossed

**A prerequisite package is copied into the bundle wholesale** (Phase 2 step 3, Phase 8 rule 5, `bundle-packaging.md` §1.1), carrying its own grounding files, its own inventory and its own register — each numbered from 1 in its own corpus. So one bundle can hold two different `[CG#7]`s.

Bundle documents therefore **partition by the `<BRD-KEY>` each one's own filename carries**. `commands/brd-package.md`'s *Assemble the bundle* rule 1 gives every bundle document a filename carrying its `<BRD-KEY>`, unique within the bundle, precisely so documents can be located by **filename search, never by path** — and that same guarantee is what draws the partition boundary.

**Amended after the whole-branch review: the key in a document's filename is its own package's key, never this run's applied uniformly.** A prerequisite package copied in arrives already named from the packaging run that built it and keeps those names, so rule 1's `<BRD-KEY>` means *the key of the package the document belongs to*. Read the other way, every document takes this run's key, the bundle yields one partition, and a prerequisite's `[CG#7]` resolves against this package's `[CG#7]` — the wrong finding, and the check goes green: the flattened-bundle silent pass this partition was chosen to remove, one level down. The partition key is resolved against the key set the run already holds — this run's key plus every prerequisite key Phase 2 carried — never parsed out of a filename. **Vacuity guard:** a bundle into which a prerequisite package was copied and which nonetheless partitions to one is a collapsed bundle, not a clean one, so a prerequisite key answering to no partition is a `BRD_PACKAGE_DEAD_CITATION` — a relation that comes up empty fails rather than passes.

**An earlier draft partitioned "by subtree", and that was wrong twice over.** It told an executor to use a path inside a bundle whose entire addressing convention is path-free (§1 rule 4), and it made the boundary a property of where a file sits rather than of what it says — so a future change that flattened the bundle would silently resolve every id against one corpus, **and would then pass**. Partitioning on the key in the filename removes that failure mode rather than mitigating it: a flattened bundle partitions identically, because the discriminator travels in the name.

Each partition parses its own corpus, and **each corpus file is located by filename search within the partition, never at the working path named below**. The working names identify *which* document each corpus is; inside the bundle that document carries its `<BRD-KEY>-` prefixed name:

| Class | Corpus file, within the partition |
|---|---|
| `[BR#n]` | `brd/brd-inventory.md` |
| `[DEF#n]` | `brd/brd-defect-log.md` (the parent's on a slice, one hop — `brd-format.md` §4) |
| `[CG#n]`, `[DG#n]` | `grounding/code-grounding.md`, `grounding/design-grounding.md` |
| `[VD#n]`, `[CD#n]`, `[AS#n]` | `decisions.md` (`decision-register-format` §1 and §7) |
| `[SR#n]` | **none — exempt by rule, see §5** |

**Every corpus is parsed, never assumed.** `workflows-core:grounding-format` §2.1's reading rule binds here: an id is resolved **against the set actually parsed**, never by matching a fixed column or a fixed run of leading spaces. That rule exists because a live run wrote `- id:       [CG#1]` in one section and `- id: [CG#12]` in the next, and a column-anchored scan reported **140 findings as missing that were on the page** — a false absence, which is the one class of wrong answer this check must never produce, since it would report every reference in the bundle as dead.

## 4. Three relations

**Relation 1 — every identifier reference resolves inside its own partition.** For each partition, every identifier reference appearing in its documents must be in that partition's corpus for that class, **unless it carries the owning BRD key at the point of use**.

**The qualified form is `<BRD-KEY> [CG#7]` — the owning key immediately before the bracketed id, and exactly one spelling.** A second rendering is not a convenience: §2.1's whole argument is that a writer free to choose between two spellings produces an artifact whose readers are wrong in a way that looks like data. The key precedes the id because that is how the sentence reads aloud, and because it gives the scan a single left-anchored token pair rather than a trailing parenthetical that a line break can separate.

This is also the repair for a live ambiguity the check merely exposes: today a reviewer reading a copied prerequisite's grounding file sees `[CG#7]` with nothing telling them whose numbering it is.

**Amended after the whole-branch review: a second qualified form already ships, and relation 1 reads it rather than refusing it.** `decision-register-format.md` §5 fixes `conditional_on: <BRD-KEY>/<decision-id>`, written by whoever takes the decision, naming a decision in a prerequisite's own register — and `decisions.md` is a bundle document, so the field reaches the bundle verbatim. As first written this section stopped the run on correct content the operator could not legally repair, because §5 owns that field's format; and the prerequisite may not be in the bundle at all, so no partition could ever hold the id. Relation 1 therefore treats `<BRD-KEY>/<decision-id>` as qualified wherever the register's own field carries it, discharging it exactly as the prose form does. **The one-spelling rule survives unchanged and applies to the prose form only:** a structured field another authority owns is not a rendering a writer chose, and a check reads what the tree writes.

**Relation 2 — a class-4 design finding cites a finding about the same requirement.** For every `[DG#n]` whose `class` is 4: its `cites` must resolve within the same partition, **and** the cited `[CG#n]`'s `claim` must **name** the same requirement id as the citing `[DG#n]`'s `claim`. Both values are already in the records being copied, which is what makes this the cheapest of the three and the one that catches the entire carried-findings class.

**An earlier draft of this section said "open with" rather than "name", and that was wrong.** §2.1's canonical example does open with the id — `claim: [BR#7] — the nightly export runs at 02:00 UTC` — but the same section explicitly sanctions hand-edited artifacts on this route, and a hand-written claim reading *"the nightly export, per `[BR#7]`, runs at 02:00"* is correct content that a position test refuses. Firing on correct content is this repository's own criterion for refusing a check, and it applies to a check's wording as readily as to its scope.

**Where a claim names more than one requirement id, §6 reports the ambiguity rather than picking one.** A claim is "the requirement premise under test", singular, so more than one id in it is unusual — and a relation that silently took the first would be guessing, which is the failure `workflows-core:addressing`'s resolve-against-a-known-set rule exists to prevent.

**The rule is stated in `workflows-core:grounding-format` §6.3, route-neutrally, and enforced here.** §6.3 is where the class-4 citation requirement already lives, so the correctness half belongs beside the presence half rather than only in a consumer. **Route-neutral matters:** gate 3 made §6 speak of "a BRD's `[BR#n]` rows, or a PRD's `[AC#n]`/`[FR#n]`/`[US#n]` rows", so the rule says *the same requirement id*, never *the same `[BR#n]`*. `/brd-package` is slice-only and will only ever see `[BR#n]`, but §6.3 is read by the idea route too.

**Relation 3 — every markdown filename token that refers to a bundle document names one that is in the bundle.** For each bundle document, a bare `<name>.md` token — no path separator — must exactly equal the bundle filename of a document in the bundle **when it is one of two shapes**:

- it carries the `<BRD-KEY>-` prefix that Phase 8 rule 1 gives every bundle document, or
- it exactly matches the **working** filename of a bundle-eligible document: `brd-inventory.md`, `brd-defect-log.md`, `coverage-ledger.md`, `code-grounding.md`, `design-grounding.md`, `baselines.md`, `decisions.md`, `customer-questions.md`, and the two §1.1 excludes by name — `self-review-<YYYYMMDD>.md` and `customer-delivery-note-<YYYYMMDD>.md`.

**The scoping is derived, not defensive, and an earlier draft of this section got it wrong.** That draft said *every* `<name>.md` token, which fires on correct content: a grounding finding's `evidence` is a repository `file:line` list, and a repository that documents itself in markdown puts `docs/api.md:12` — or a bare `README.md` — into a finding that is entirely correct. The two shapes above are exactly the tokens that *claim to be a bundle reference*: the first is the naming convention Phase 8 rule 1 imposes, and the second is the closed set of documents §1.1 admits or names, which is where both observed instances of failure 3 sat. A repository path matches neither.

**This is the report's checks 3 and 4 as one relation, and the collapse is deliberate.** Check 3 asked for the dead-filename rule to extend from links to prose; check 4 asked that references name the *bundle* filename rather than the working one. A single exact-match relation against the bundle's own filename set satisfies both — a working filename is not in the bundle, so it fails the same test a dead one does — and one mechanism cannot drift from itself the way two can.

`bundle-packaging.md` §2 gains a sentence saying the rule now covers prose. Without it a reader meets §2's three cases, all about rewritten links, and concludes links are the boundary — which is exactly the reading under which failure 3 shipped.

## 5. Two exemptions, and why each is principled rather than convenient

**`[SR#n]` is exempt entirely.** `self-review-<YYYYMMDD>.md` is excluded from the bundle by a rule that `bundle-packaging.md` §1.1 calls the one exclusion that is a *rule* rather than a consequence of the allow-list — while the `[SR#n]` content the customer may see reaches them **filtered**, through the prompt's parts 7 and 9, cited by id. So an `[SR#n]` reference is correct content that resolves to nothing in the bundle, by design. **A check without this exemption fires on every package.**

It is worth naming that this is failure 3's own shape — an excluded document referenced from a bundle document — and that the two are nonetheless different: naming the *file* is dead, naming an `[SR#n]` is the filtered citation working as intended. Relation 3 catches the first; relation 1 must not catch the second.

**`brd/source/<basename>` reports rather than stops.** The customer's own document is copied byte for byte and is immutable by rule (`bundle-packaging.md` §2.1, `brd-format.md` §1). It inherits the plugin-free scan's existing treatment verbatim and for the identical reason: stopping outright would make that BRD permanently unpackageable, since the one repair the rule allows is not editing the file. Report it, name the file and the token, and let the operator decide whether to ship. Every other document's hit stays a hard stop.

## 6. Three stops, because the remedies differ

| Stop | Fires on | Why it is its own code |
|---|---|---|
| `BRD_PACKAGE_DEAD_CITATION` | relations 1 and 3 — a reference that resolves to nothing | the remedy is to fix or qualify the reference |
| `BRD_PACKAGE_CITATION_MISMATCH` | relation 2 — resolves, to a finding about a different requirement | the remedy is to re-derive the finding, and the reference itself may be untouched |
| `BRD_PACKAGE_CORPUS_UNREADABLE` | a corpus file holding record-shaped content that parses to zero ids of its class | `grounding-format` §2.1: *"A count that disagrees with the file is reported as a parse failure, never as an absence."* Without this the check reports every reference dead and the operator repairs the wrong thing |

Each names the id or filename, the bundle document it sits in, and what it failed to resolve against — the shape `BRD_PACKAGE_PROMPT_LEAK` already sets.

**Amended after the whole-branch review: "present and non-empty" was the wrong trigger, and it fired on correct packages.** `/prd-ground` writes `design-grounding.md` as every `[DG#n]` *or a short note when design grounding was skipped*, and a defect walk that confirmed nothing leaves an entryless `brd-defect-log.md` — both present, both non-empty, both correctly holding no ids. The distinction that separates the two states is **record-shaped content**: a file holding at least one block the format would recognise as a record and still yielding zero ids is a parse failure; a file holding none is a legitimately **empty corpus** and passes. It is drawn there because the failure §2.1 warns about is a *reader* that cannot see records that are there, and record-shaped content is the evidence that there was something to see. A reference into an empty corpus fails relation 1 as an ordinary dead citation, which needs no stop of its own.

## 7. What §6 will state that it cannot see

Stated in the reference, because a green gate here is otherwise read as a clean bundle:

- **A reference that *describes* a bundle document where Phase 8's rule 1 requires it to *name* one.** That is the unmechanisable half of the report's check 4: "the grounding file" is prose, and no pattern distinguishes a deliberate description from a missing filename.
- **A citation that resolves to the right id and is wrong in a way relation 2 does not test** — a `[CG#n]` about the right requirement but the wrong claim within it.
- **An identifier class shipping without a corpus row.** The §3 table is a closed list, so a future class is invisible to relation 1 until it has a row. **Amended after the whole-branch review:** the reverse case — a row whose corpus file is *absent* from the bundle — is **not** a `BRD_PACKAGE_CORPUS_UNREADABLE`, since that stop is defined on a file that is there and holds record-shaped content, and its message would assert the presence of a file that is missing. An absent corpus is an empty one, and a reference into it is an ordinary dead citation.
- **The delivery note**, added after the whole-branch review. Its whole job is to name a bundle file exactly — which file is the prompt, which file comes back — and §4/§1.1 keep it out of the bundle, so a check that runs over bundle documents never sees it. A wrong filename there stops the reviewer before they open anything. Widening the check to reach it is a scope decision rather than a wording one: the note names files, and the bundle's filename set exists by the time the check runs.

## 8. Out of scope, stated so a reader does not reintroduce them

- **No narrowing mechanism.** The plugin has no supported way to narrow a parent's verified findings to a slice's claimed subset; under slice-first that operation should no longer be needed, and it stays its own ledger entry. The bundle check catches a broken citation regardless of how it got there — that is the whole point of checking at delivery.
- **No sanitising.** The check stops, exactly as the plugin-free scan stops. A citation that reached the bundle reached it because some sentence assumed a resolvable id, and rewriting the id leaves the sentence asserting something nobody checked.
- **No delivery-route change.** Ledger item **E-4** — the package telling every reviewer to extract an archive — was raised alongside this work and is deliberately not folded in: it needs an input the run does not have, and choosing how it gets one is a design decision, not a check.

## 9. Risks

**Relation 2 will refuse bundles that ship today.** That is the intent — the observed corpus had 16 of 17 class-4 citations wrong — but the first run against an existing hand-narrowed BRD may stop, and the repair is by hand, because §8's narrowing gap is real. The stop must therefore say what disagrees, not merely that something does.

**Relation 3's second shape is a closed list, and a closed list goes stale.** It enumerates the working filenames §1.1 admits or excludes by name. A document added to §1.1 without a corresponding entry here is invisible to relation 3 when it is named by its working filename — the exact defect the relation exists to catch. The implementation therefore derives the list from §1.1's own table rather than restating it, and §6 says so where someone editing §1.1 will meet it.

**The partition depends on rule 1 holding.** The boundary is the `<BRD-KEY>` in each document's filename, so it survives flattening, renaming and re-archiving — but a bundle document that reached the bundle *without* its key-carrying name has no partition, and relation 1 cannot place it. That is a rule-1 violation before it is a §6 problem, and §6 reports it as one rather than guessing a partition: an unkeyed bundle document stops the run with `BRD_PACKAGE_DEAD_CITATION` naming the document, because every id in it is unresolvable by construction.

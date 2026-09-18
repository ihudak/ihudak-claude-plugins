---
name: brd-intake
description: BRD-intake workflow (PM phase, entry point of the BRD-to-PRD flow). Walks every link a customer-supplied business requirements document makes — wikilinks included — read-only, shows the operator the list and asks before capturing anything outside the document's folder or anything it cannot read, then copies the document and every file it takes into the specs repo byte-for-byte, naming in brd/brd-link-log.md each link it did not copy and why. figure-reader transcribes every linked image into brd/brd-figures.md, and brd-reader extracts a [BR#n] requirement inventory from the document, its linked markdown and those transcriptions; its defect candidates are confirmed interactively against the six brd-format.md classes, and a coverage-ledger.md is written with every row unallocated. Rejects a non-markdown source rather than converting it. Grounds on the shipped product documentation when $DOCS_PATH resolves (--no-docs off), consumed grill-rank over the defect walk. Optional --sort-existing migrates an already-hand-written package into seed files. Offers /brd-split as the next step.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Intake the customer-supplied business requirements document: $ARGUMENTS

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

`/brd-intake` is the **entry point of the BRD-to-PRD flow** (PM phase) — the first of the
route's commands, which between them turn a long, often internally
contradictory customer BRD into requirements a PRD can be built from. It copies the customer's
source into the specs repo **verbatim and immutably**, extracts a `[BR#n]` requirement inventory
via the `brd-reader` agent, classifies the document's defects **with a human** rather than on the
agent's say-so alone, and writes a coverage ledger in which every requirement starts life
`unallocated` — the state `/brd-split`, the route's allocation step, cannot complete past until each
row has been given a fate.

Usage: `/brd-intake <BRD-KEY> @<brd-file> [--sort-existing <dir>] [--no-docs] [--docs <path>]`

---

## Phase 0 — Resolve inputs

1. **`<BRD-KEY>` (mandatory).** Parse the first token that is neither a flag nor a flag's value — `--sort-existing` and `--docs` each consume the token after them (step 4), and a value skipped as "non-flag" would be read as the key; validate it with `key-valid`
   (`workflows-core:addressing` §1's `key-valid` — shape only,
   never checked against a tracker). If absent or invalid, **stop gracefully**:
   `BRD_INTAKE_NEEDS_KEY: /brd-intake needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. ACME-001) — pick a short stable identifier for this business requirements document, then re-run '/product-workflows:brd-intake <KEY> @<brd-file>'.`
2. **`@<brd-file>` (mandatory).** The customer's source file argument. If absent, **stop**:
   `BRD_INTAKE_NEEDS_SOURCE: /brd-intake needs the customer's source as an @-argument — re-run '/product-workflows:brd-intake <KEY> @<path-to-brd>'.`
3. **Reject a PDF — do not convert it.** If the resolved source does not end in `.md`/`.markdown`
   (a PDF, a Word document, a slide deck, any non-markdown source), **stop**:
   `BRD_INTAKE_NEEDS_MARKDOWN: the source must be markdown — convert it first, and check the conversion. It becomes the immutable record every [BR#n] anchors into.`
   The reason this is a hard stop rather than a best-effort conversion: once intaken, `brd/source/`
   is never edited again (`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §1), and every `[BR#n]`
   locates itself inside that text by `source_anchor`. An unchecked machine conversion — a dropped
   clause, a misplaced heading, a table read out of row order — would silently become the record of
   what the customer asked for, with no later step positioned to catch it. Converting is the
   operator's own step, done where they can eyeball the result against the original before handing
   it back to this command.
4. **Optional flags.** `--sort-existing <dir>` — if present, validate `<dir>` exists and carry it
   forward to Phase 6. `--docs <path>` — points documentation grounding at that root for this run instead of `${DOCS_PATH:-/workspace/docs}`; **strip the flag and its value together** before any remaining-argument classification, or the path is read as part of the address. Declared for every consumer by `workflows-core:docs-grounding` §1's *Flags first* rung, which resolves it; this command only has to recognise it and pass the invocation through. `--no-docs` — boolean; turns documentation grounding off for this run,
   carried to Phase 1's `resolve-docs-grounding` call. **None of the three changes anything else about Phase 0:**
   the BRD source is still required and still gated by step 3.
5. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`, per the
   `Required path environment variable unset` rule in `workflows-core:escalation-rules`:
   ```
   choices: ["Set SPECS_PATH (enter the path)", "Cancel"]
   ```
6. **Specs-repo preflight.** Invoke `Skill(skill: "workflows-core:reference", args: "specs-repo-git specs-preflight")` and execute its `specs-preflight` entry point (§3) inline. Prompt-free and silent when the specs repo is
   clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
   `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal
   `commit-artifacts` step skips on it.
7. **Resolve or derive the BRD folder** via `resolve-address <BRD-KEY>` (`Skill(skill: "workflows-core:reference", args: "addressing resolve-address")`, §3). Found → this is an existing BRD folder
   and this invocation is a re-run over it; use it. **A slice is never a legitimate target here** —
   it has no source document of its own to intake, and its inventory and ledger are the parent's
   `/brd-split` to write (`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1,
   `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3) — so a resolved folder whose
   `brd-link.md` carries a `parent:` field is a mis-keyed invocation: say so and confirm before
   Phase 2 copies anything into it. Absent → this is a
   brand-new BRD: derive `<slug>` from the source file's first heading (kebab-cased), falling back
   to a kebab of the source filename when no heading is found, and prepare to create
   `specifications/BRD-<BRD-KEY>-<slug>/` — **the `BRD-` kind prefix is part of the name**
   (`workflows-core:addressing` §2), never optional and never derived from the
   key. The directory is not actually created until Phase 2's first write.

   **Writing it unprefixed is the pre-prefix shape §5 exists to tolerate, never to produce**, and
   the cost is not cosmetic. A folder created without the prefix misses `workflows-core:addressing` §3's
   `*-<KEY>-*` glob by construction, so every downstream run resolves it through §5's legacy
   fallback and reports it `legacy: true` — deprecated, once per run — on a tree this command wrote
   minutes earlier. Worse, the container refusals `/product-workflows:create-prd`,
   `/product-workflows:create-ard`, `/product-workflows:specify` and `/product-workflows:epics` each read
   the `BRD-` prefix off the resolved folder's **own name**, falling through to
   `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5.1's positive test only for a
   folder that has none — so an unprefixed root BRD moves all four refusals onto the legacy branch
   they hold for repositories written before increment A. And `/product-workflows:brd-split` Phase 3
   step 2 creates its slice at `specifications/BRD-<PARENT-KEY>-<parent-slug>/PRD-…`, a path that
   would not exist. `workflows-core:addressing` §5 keeps resolving the folders
   a pre-prefix repo already holds; this command does not add to them.


   **A re-run over an existing folder rewrites every ledger disposition, and the confirmation for
   that is taken here — before Phase 2's first write.** Where the folder resolved above already
   holds a `coverage-ledger.md` with any row not `unallocated`, read it and state, before anything
   is copied: how many rows carry each terminal disposition and which `[BR#n]`s they are —
   `covered-by`, `deferred-to`, `rejected`, `superseded-by`, and any illegal root `covered-here`
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5) — and that Phase 5 replaces
   **every one of them** with `unallocated`. Name what that destroys rather than calling it a
   rewrite: each `deferred-to`, `rejected` and `superseded-by` decision `/product-workflows:brd-split`'s
   walk took is discarded and has to be re-taken, a `rejected` row re-cited against its `[DEF#n]`,
   and every child's `claims:` re-allocated. Then ask:
   ```
   choices: ["Re-run: re-extract the inventory and rewrite the ledger, discarding the <n> recorded dispositions above", "Cancel — leave this BRD as it stands"]
   ```
   **Here and not in Phase 5, because declining is free only until Phase 2's first write.** By
   Phase 5 the source has been re-copied and the inventory re-extracted, so a decline there would
   leave the folder holding an inventory its standing ledger no longer matches — a worse state than
   either answer to this question. On `Cancel` nothing is written at all. Where the folder holds no
   ledger, or every row of it is still `unallocated`, there is nothing to discard and this
   confirmation is skipped silently.

   **A single illegal root `covered-here` row does not need this run**, and the offer says so rather
   than letting a re-run be taken for the only exit: `coverage-ledger-format.md` §5 names the
   one-row hand repair that leaves every other disposition standing, and the four container refusals
   in `/product-workflows:create-prd`, `/product-workflows:create-ard`, `/product-workflows:specify` and
   `/product-workflows:epics` offer that repair first and this re-run second.

`/brd-intake` is the **first command of the BRD-to-PRD route** — unlike every downstream `/brd-*`
command, it consumes no prior phase's deliverable, so it runs no `require-on-main` gate here. It is
cwd-agnostic and needs no repos mounted (no `$REPOS_PATH`); grounding against code and design is
`/prd-ground`'s job, not this one's.

---

## Phase 1 — Confirm

Show, and confirm before writing anything:

- The BRD folder (existing, or the derived `BRD-<BRD-KEY>-<slug>` to be created — the `BRD-`
  prefix included, per `workflows-core:addressing` §2).
- The resolved absolute path to `@<brd-file>`, **and its own directory**. **Run the walk
  `${CLAUDE_PLUGIN_ROOT}/references/linked-sources.md` §4 defines, from the document, now** — it is
  read-only: it copies nothing, writes nothing and dispatches nothing. Show what it found: how many
  linked files of each kind — **markdown**, **image**, **other** — inside the document's own directory
  and outside it, and every target it could not resolve, with its reason (`url`, `unreadable`, or
  `ambiguous` with every candidate). Name by path every file outside the directory and every *other*
  file. This is the list Phase 2 copies from, so the operator consents to exactly what is about to be
  copied out of their filesystem.
- Whether `--sort-existing <dir>` is in play, and its resolved directory.
- The `docs grounding:` line in the form `workflows-core:docs-grounding`
  resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build,
  staleness, or shadowing clause it carries (off switch: --no-docs). Run
  `resolve-docs-grounding brd-intake` per `Skill(skill: "workflows-core:reference", args: "docs-grounding resolve-docs-grounding")` to obtain it; it runs **exactly once per
  run**, here, and Phase 3.5 consumes the cached result rather than re-resolving.

**The `/epics` consent-ordering exception does not apply to this command.** `/epics` resolves docs
grounding ahead of its `require-on-main` gates because a later stop would sit after the run's only
consent-bearing step (`commands/epics.md` Phase 2). `/brd-intake` runs no `require-on-main` gate at
all — it is the route's first command and consumes no prior phase's deliverable (Phase 0) — so
resolving here, in the ordinary confirmation step, already puts the one consent-bearing step ahead
of every write and every dispatch.

**Where the walk reached any file outside the document's own directory, ask first** — the answer
decides the set the next question is asked over:

```
choices: ["Capture all <n> (Recommended)", "Only the document's own folder — capture nothing outside it", "Stop"]
```

*Capture all* takes every file the walk reached — `<n>` is how many distinct files that is, the
document itself not counted — and Phase 2 copies the outside ones into `brd/source-external/`.
*Only the document's own folder* takes the files inside the directory that a chain of taken markdown
files reaches from the document, and leaves everything else `excluded` (`linked-sources.md` §7):
every outside file, and **an inside file reachable only through an outside one, which this answer
drops** — it is neither copied nor logged. Name each such file by path beside the question, because
the operator is otherwise never told. Phase 2 then logs each link a copied file makes to an excluded
file, with its one reason — `absolute path` where the target as written begins with `/`,
`outside the source directory` otherwise; by `linked-sources.md` §7 those are exactly a copied
file's links to files outside the directory. A link sitting inside an excluded file is not logged,
because the file holding it is not copied. *Stop* ends the run with nothing written. Where nothing
lies outside the directory, this question is not asked, and every file the walk reached is taken.

**Where the taken set holds an *other* file — neither markdown nor an image — ask next:**

```
choices: ["Stop and convert them first — nothing has been written (Recommended)", "Proceed — none of them carries an obligation (recorded)", "Use a different key or path (you'll be prompted)"]
```

*Stop and convert* ends the run with nothing written:
`BRD_INTAKE_UNREAD_ATTACHMENTS: <k> linked file(s) are neither markdown nor an image and would be copied but never read: <paths>. Convert each (markdown for a document, PNG for a picture), check the conversion against the original, replace the link to the original, in the file that links it, with a link to the converted file, and re-run '/product-workflows:brd-intake <BRD-KEY> @<brd-file>'.`
It is an operator halt, not a plugin gap, so `emit-block` does not fire — Phase 9 makes the same call
for every Phase 0 stop. **Converting is the operator's checked step for the same reason Phase 0 step 3
refuses to convert the document**: an unchecked conversion would silently become part of the record.
*Proceed* copies them, reads none of them, and records the operator's account in the final report,
exactly as Phase 3's *"They hold no obligation"* answer is recorded. Where the taken set holds no
*other* file, this question is not asked.

**Then, in every case**, confirm the run:

```
choices: ["Proceed with <folder> (Recommended)", "Use a different key or path (you'll be prompted)", "Cancel"]
```

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "workflows-core:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT for an unusually long or heavily-conflicting BRD
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # docs-grounder (Phase 3.5)
  extraction_model: <§2 Opus chain>   # figure-reader (Phase 2.5) and brd-reader (Phase 3) — both frontmatter-pinned to opus; recorded, no override
  authoring_model: <= current_model>   # Phase 1's confirmation and Phase 4's interactive defect classification (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`figure-reader` and `brd-reader` run on Opus regardless of `classification`, per their own frontmatter
pins. A misread label, a missed annotation or an unproposed conflict yields no candidate, so Phase 4's
human never sees it — the tier is bought where a miss is silent. If no Opus resolves, **degrade to
best-available + record** in `notes` and the final report — do not hard-block.

**Collect `figure-reader`'s and `brd-reader`'s own `notes` too, and report them** — an image too low in resolution for its small text, an unusually structured source, a passage that could not be confidently split. The inventory is the spine every later command walks, so a `[BR#n]` split out of a passage the reader was unsure of must not read as confidently extracted.

---

## Phase 2 — Copy the source

Copy `@<brd-file>` **verbatim, byte-for-byte** into `<BRD-dir>/brd/source/<basename>` (creating the
BRD folder now, if Phase 0 derived a new one, and `brd/source/` inside it). Per
`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §1, nothing under
`brd/source/` is ever edited, reworded, or reformatted after this point, no matter how badly worded
a requirement inside it is — defects found in it are logged beside it (Phase 4), never corrected in
it.

**Then copy the files the source document links, byte-for-byte too** — this phase captures both, and
`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §1.1 is the authority on what the result holds. A
customer's BRD routinely carries screenshots, diagrams and appendices beside it, and `brd/source/`,
with `brd/source-external/`, is the immutable record every `[BR#n]` anchors into: whatever this phase
does not capture is outside that record permanently, because nothing under either is ever written
again. Copying the text alone leaves every one of those links resolving to nothing while the run
reports a faithful verbatim copy.

**The links were found, resolved and walked in Phase 1**, by `linked-sources.md` — this phase copies
what Phase 1 took and never walks again. The walk's record says, per target, what kind of file it
reached and whether it lies inside the document's own directory; Phase 1's answers say which are taken.

**Where each taken file lands.**

- **Inside the document's own directory** → at **its path relative to that directory** under
  `<BRD-dir>/brd/source/`, creating intermediate directories as needed. The copied document sits at
  `brd/source/<basename>` and the copy mirrors the source tree's own layout beneath it, so every
  relative link to a file inside the directory resolves from the copy exactly as it did from the
  customer's original — **with no edit to the copied text**. `../images/flow.png` written in
  `appendix/notes.md` resolves inside the directory and is copied like any other; a syntactic `..`
  test would have refused a file in scope.
- **Outside it** — taken only on Phase 1's *Capture all* → into `<BRD-dir>/brd/source-external/`, at its
  **basename**, never at a path mirroring where it came from;
  `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §1.1 says why. Where that name is already taken,
  apply `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` *The collision rule*, rules 1–3, with
  `brd/source-external/` as the destination directory. Its rule 4 never applies here: nothing under
  `brd/source-external/` is overwritten, and no link is rewritten — the mapping table below names the
  copy.

Copy each file **byte-for-byte, whatever its type** — an image, a PDF, a spreadsheet — never opened
as text, never re-encoded, never resized. Phase 0 step 3's markdown-only rule is about the *document*
the inventory anchors into; a file it links is captured as it stands. **What is read, and by whom, is
Phase 2.5's and Phase 3's** — this phase copies and reads nothing.

**Every link in a copied file whose target was not copied is named, never dropped in silence.** Write
`<BRD-dir>/brd/brd-link-log.md` in the shape `brd-format.md` §1.1 fixes — the source document's
basename, the counts, and one row per such link carrying the target as written, the copied file the
link sits in, and exactly one of these reasons. A link sitting inside a file that was not copied has
no row (Phase 1):

| Reason | Fires when |
|---|---|
| `outside the source directory` | Phase 1's answer was *Only the document's own folder*, the walk record reads `inside: false`, and the target as written does not begin with `/` |
| `absolute path` | Phase 1's answer was *Only the document's own folder*, the walk record reads `inside: false`, and the target as written begins with `/` |
| `url` | the target carries a URI scheme |
| `unreadable` | the target resolves to no readable file (`linked-sources.md` §3) |
| `ambiguous` | a `[[wikilink]]` matched more than one file in the vault; the row names every candidate |

**Then map every captured link that does not resolve as written**, in the log's second table,
*Captured links that do not resolve as written* — columns `Target as written | Linked from | Copy` —
one row per link whose copy cannot be reached by reading its target as a path relative to the file it
sits in — the rule and its cases are `brd-format.md` §1.1's (a link to a file copied into
`source-external/`, a `[[wikilink]]`, an absolute path, a link inside a `source-external/` file whose
target lies inside the document's own folder). `Copy` is the copy's path relative to `brd/`. The
table is written, with a header and no rows, even where nothing needs mapping.

**Write the log on every run, including one that captured everything** — its counts are then the
positive record that the capture ran, which an absent log and an empty one are not. Report the same
counts and the same list, each entry with its reason, in the final report.

---

## Phase 2.5 — Read the figures

**Every image Phase 2 copied is read here, and there is no cap on how many.** A cap would leave an
image's obligations outside the record exactly as not reading it did (`brd-format.md` §1.2).

1. **Re-use before reading.** Compute each copied image's SHA-256. Where
   `<BRD-dir>/brd/brd-figures.md` already holds a section for that image whose *Content hash* matches,
   keep that section's transcription — the lines `brd-format.md` §1.2 names — **verbatim** and do not
   dispatch the image — a writer preserves what it did not produce, as
   `workflows-core:grounding-format` §6.2 has an index writer do with a row. On a first intake there
   is no file and nothing is re-used.
2. **Dispatch `figure-reader` over the rest**, at most 10 images per dispatch and at most 4 dispatches
   in a single response, in further waves until none remain:

   → Agent (subagent_type: "product-workflows:figure-reader", model: `<extraction_model — frontmatter-pinned to opus>`):
     > "figures: [absolute path of each image in this batch, in Phase 2's capture order]"

   An `INPUT_MISSING` return is this run's defect — it sent an empty batch — and is fixed and
   re-dispatched, never recorded as an unread image.
3. **Write `<BRD-dir>/brd/brd-figures.md`** per `brd-format.md` §1.2: one section per image Phase 2
   copied, in capture order — re-used transcriptions verbatim, new ones from the agent's return, an
   image returned `read: false` with its reason and no transcription. Write *Linked from* afresh for
   every image Phase 2 copied, re-used or not, from the copied files Phase 1's walk found linking
   it. A section already on file for an image the current document no longer links stays, marked
   as §1.2 says. Leave every *Rows* line empty; Phase 5 completes them.

Where Phase 2 copied no image, this phase dispatches nothing, writes no file, and says so in the
final report.

---

## Phase 3 — Extract the inventory

Dispatch `brd-reader`:

→ Agent (subagent_type: "product-workflows:brd-reader", model: `<extraction_model — frontmatter-pinned to opus>`):
  > "source_path: [absolute path to the copied document at `<BRD-dir>/brd/source/<basename>`]
  >  appendices:  [absolute path of every linked markdown file Phase 2 copied — under `brd/source/` or `brd/source-external/` — in Phase 2's capture order; `[]` when none]
  >  figures_path: [absolute path to `<BRD-dir>/brd/brd-figures.md`; omit when Phase 2.5 wrote none]"

Act on `status`:
- **`OK`** — write `<BRD-dir>/brd/brd-inventory.md` per `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md`
  §2: one row per returned `[BR#n]` (`id`, `text`, `source_anchor`).

  **On a first intake, number exactly as returned. On a re-run over a folder that already holds an
  inventory, RECONCILE — this is the id coordination `brd-reader` delegates and nothing else performs.**
  The agent numbers in source order from `BR#1` on every read, so a BRD v2 with one requirement inserted
  early returns a set in which every later id has shifted by one. Writing that straight through
  renumbers text that already has an id, which `references/brd-format.md` forbids outright (*"assigned
  once, never renumbered"*, and *"re-extraction would mint a second set of ids for text that already has
  them"*). Nothing downstream would notice: every `[CG#n]` premise, every `[DEF#n]` target, every
  child's copied inventory and `claims:` list cites `[BR#n]` **by id**, and `/brd-split`'s reconcile
  unions claimed rows by id too — so a shift silently re-attaches each claim to a different requirement,
  and no gate reads a `[BR#n]` against the text it names.

  So: read the existing `brd/brd-inventory.md` first. For each returned row, match it to an existing
  row by `source_anchor`, else by its `text`; **a matched row keeps the id it already has**, whatever
  the agent returned for it. Only text that matches nothing existing is new, and it takes the next id
  after the highest already in use — never a gap-filling reuse of a retired one. Report the
  reconciliation: how many ids were preserved, how many minted, and any existing row this source no
  longer contains (which keeps its id and is reported, never renumbered away).

  **Map every id the agent returned through that reconciliation, not only the row ids** — each
  candidate's `names`, and each `figures` entry's `illustrates`. The agent numbers its own read from
  `BR#1`; a `conflict` naming its `BR#7`, or an image said to illustrate its `BR#7`, means whatever row
  the reconciliation matched to that `BR#7`, and writing the agent's number through would attach the
  candidate or the image to a different requirement.

  Leave each row's `defects` column empty for now — it is filled in Phase 4, once a candidate is
  actually confirmed into a `[DEF#n]`, never before. Carry every returned `defect_candidates` entry
  forward into Phase 4; nothing here treats a candidate as a decision.

  **Then check the inventory's coverage of its own source**, per
  `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.2, before anything downstream treats the
  inventory as the spine it is. The three relations read the anchors already written, the copied
  document and linked markdown, `brd/brd-figures.md`, and the `figures` list the agent returned;
  nothing else is stored and the agent is not re-dispatched.

  1. **Every `source_anchor` resolves**, in whichever of `brd-format.md` §2's three forms it takes —
     by the rules `brd-format.md` §2.2 fixes for each form, which this command applies and does not
     restate. **Except the rows the reconciliation above deliberately kept**: a re-run over a
     revised source preserves any existing row *"this source no longer contains"*, id retained and
     reported, and such a row's anchor points into a section the new document may well have dropped.
     That is a recorded state, not an untraceable one, and stopping on it would hard-stop a
     supported path — a customer sending a revised BRD — with a remedy nobody can perform, since
     correcting the anchor by hand is impossible when the content it named is gone. Exclude them by
     the reconciliation's own list and name them in the report instead.

     Any **other** unresolvable anchor is named with its `[BR#n]`, and the run stops — a row nobody
     can trace back is a defect in the artifact whose job is traceability:
     `BRD_INTAKE_DANGLING_ANCHOR: <N> inventory row(s) carry a source_anchor that resolves to nothing in the copied source under brd/ (<BR-id>: <anchor>, …), and none of them is a row this run preserved as no longer present. The row cannot be traced back to the customer's document, which is the one thing the anchor exists for. Correct the anchors by hand in <path> and re-run; do not re-run brd-reader over the whole document, which would renumber every row.`
  2. **Every top-level section — of the document and of each linked markdown file Phase 2 copied —
     either holds a row or is accounted for** (`brd-format.md` §2.2 fixes what holds one, including
     a section that links an image yielding a row, and a linked file with no heading as one
     section). Name each section that holds none, with what the source has under it.
  3. **Every image Phase 2 copied yields a row, illustrates one, or is accounted for**
     (`brd-format.md` §2.2). Name each image that does neither — with its *Depicts* sentence from
     `brd/brd-figures.md`, or its reason where it was not read.

  Ask about relations 2 and 3 together — one question for the whole set, not one per section or image:

```
choices: ["Re-read the named sections — re-dispatch brd-reader over the whole document and reconcile ids (Recommended)", "They hold no obligation — record that and continue", "Cancel"]
```

  **The first option re-reads the whole document and reconciles**, because `brd-reader` takes the
  whole set — the document, every linked markdown file Phase 2 copied, and the figures file — and
  still numbers from `BR#1` on every read: there is no narrower re-dispatch, so it is re-dispatched
  with the same three inputs, and the reconciliation, id mapping included, is the one the re-run
  branch above already performs. The second records the operator's account in the final report.
  **Report the outcome either way, including "every top-level section and every image accounted
  for"** — an unreported clean result is indistinguishable from an unrun check. **Where no anchor
  parses at all, say that and stop**: that is a read failure, not a document with no coverage.
- **`EMPTY`** — report that the source contained no identifiable requirement. Skip Phase 4 (nothing
  to classify) and write an empty `brd/brd-inventory.md` and `coverage-ledger.md` in Phase 5; the
  final report's ledger line reads
  `ledger: 0 requirements — 0 covered, 0 deferred, 0 rejected, 0 unallocated, 0 unresolved (0 delegated, 0 not built)`.
  **Say plainly, here and in the final report, that the route stops on this BRD until the inventory
  has a row.** `/prd-ground` has nothing to ground, and it stops with `PRD_GROUND_EMPTY_INVENTORY`
  rather than reporting a quiet success; `/brd-split` and `/brd-interview` stop the same way. Phase 8
  offers the one thing that changes it — re-running this command over this same folder with a source
  whose requirements `brd-reader` can identify — and does **not** offer grounding, because offering a
  command that would refuse this BRD is worse than offering nothing. Carry the `EMPTY` result forward
  to Phase 8 as the flag that picks its choice list.
- **`NOT_FOUND`** — surface the agent's exact message and stop; this should not occur (Phase 0
  confirmed the document is markdown, Phase 1's walk classified every appendix as markdown, and
  every path handed over is a file Phase 2 copied or Phase 2.5 wrote), so treat its appearance as
  worth investigating rather than retrying blindly.

---

## Phase 3.5 — Documentation grounding (optional)

Consume the `resolve-docs-grounding brd-intake` result cached in Phase 1 — never re-run it. When
`docs_grounding: OFF`, skip silently and say so once in the final report. When `docs_grounding: ON`,
`dispatch-docs-grounder` (`workflows-core:docs-grounding`) with
`feature_summary` = two to four sentences drawn from the Phase 3 inventory (what this BRD asks the
product to do, in the operator's own product terms), `key` = `<BRD-KEY>`, and `themes` = the
capability themes the inventory rows cluster into. This runs after Phase 3 because the inventory is
what the summary is built from, and before Phase 4 because Phase 4 is where the digest is consumed.

**Consumption is grill-rank (`workflows-core:docs-grounding`), against the Phase 4 defect walk — and a
`[DEF#n]` is the only thing documentation can ever put on a `[BR#n]` row.** Two effects, both of
them landing on the row only through Phase 4's existing human confirmation:

- **Ranking.** Rank each `docs_challenges` entry into the order Phase 4 puts candidates to the
  operator, so a candidate a shipped page bears on is asked earlier. Ranking never adds a question
  and never removes one — the walk still visits every candidate `brd-reader` returned.
- **Raising.** A `docs_challenges` entry may be *raised* as an additional defect candidate, but only
  in the two classes documentation can actually speak to
  (`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §3): `unsourced`, when the requirement asserts
  current system behaviour a shipped page corroborates or contradicts — the page is what makes the
  assertion worth grounding, never what settles it; and `ambiguity`, when the BRD uses a term the
  shipped documentation uses for something else, so two competent readers would implement it
  differently. A raised candidate is walked, confirmed, and numbered exactly like one `brd-reader`
  returned, and a rejected one is dropped the same way.

**`docs_references` — what the product already ships and documents — is reported, never written.**
It is genuinely useful here: a requirement the
docs describe as already shipped is one `/prd-ground` should check against code first. But it is
not a defect and it has no field on an inventory or ledger row, so it goes into the final report and
nowhere else. Nothing docs-derived is ever written into `evidence` — that column stays empty until
grounding runs (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §2), and grounding
does not accept a document as evidence either (`commands/prd-ground.md` Phase 4.5).

---

## Phase 4 — Confirm defects

**This is the human-in-the-loop step `brd-reader` cannot do itself.** Every `defect_candidates`
entry the agent returned is a hypothesis, never a decision (`agents/brd-reader.md`) — confirming or
rejecting each one, against the customer or the delivery team, is this phase's job alone.

Group the carried-forward candidates by class — `brd-reader`'s, plus any Phase 3.5 raised from
documentation, which are walked identically and marked in the report as docs-raised — and walk them
**one class at a time**, in the fixed order
`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §3 lists its six classes. Within a class,
confirm each candidate individually via `AskUserQuestion`:

```
choices: ["Confirm as written (Recommended)", "Confirm with an edited reason", "Reject — not a defect", "Cancel"]
```

**A candidate on a row drawn from an image is put with its picture.** Show the image's path relative to
`brd/` and its transcription from `brd/brd-figures.md` beside the candidate, and tell the operator to
open the image before answering: the transcription is the plugin's reading of the customer's picture
(`brd-format.md` §1.2), and the picture is what the candidate is about.

On confirmation, assign the next `[DEF#n]` id contiguously across the whole document (ids are never
reused or renumbered, per `brd-format.md` §3–§4) and record it against every `[BR#n]` it was raised
on. A `conflict` or `duplicate` entry always names its counterpart `[BR#n]`, carried straight from
the candidate. On rejection, the candidate is simply dropped — it never becomes a `[DEF#n]`, so
nothing further records that it was proposed.

When every class has been walked, write `<BRD-dir>/brd/brd-defect-log.md`: one entry per confirmed
`[DEF#n]`, each carrying resolution `open` (`brd-format.md` §4 — none of the other three
resolutions has happened yet at intake time). Then update `brd/brd-inventory.md`'s `defects` column
for every affected row with its confirmed `[DEF#n]` ids.

---

## Phase 5 — Write the coverage ledger

Write `<BRD-dir>/coverage-ledger.md` per `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md`
§2: one row per `[BR#n]` from the (now defect-annotated) inventory — `id`, `text`, `defects`
mirrored from the inventory, `evidence` empty (grounding has not run yet — that is `/prd-ground`'s
job), and **`disposition: unallocated` on every row**, per §3: "the initial state; the only one of
the six that blocks §4." No row is ever written in any other disposition here.

**Then complete `brd/brd-figures.md`'s *Rows* line for every image**, from the final inventory — after
Phase 3's reconciliation mapping, never from the agent's own numbering: `yields` every row whose
`source_anchor` names the image, `illustrates` every row the agent returned for it, or
`accounted for — <the operator's Phase 3 account>` where it does neither. A section marked *No longer
linked by the current source* gets no agent entry and no Phase 3 account: its *Linked from* and *Rows*
take the values `brd-format.md` §1.2 fixes for such a section. A run that wrote no figures file skips
this.

**On a re-run this phase rewrites every disposition, and it does so unconditionally by design.**
Where Phase 0 step 7 resolved an **existing** folder, the ledger that folder holds is replaced row
for row: every `covered-by`, `deferred-to`, `rejected` and `superseded-by` `/product-workflows:brd-split`'s
walk wrote is gone, and so is any illegal root `covered-here`. **The warning and the confirmation
for that are step 7's**, taken before Phase 2 copied anything, because by the time this phase runs
the source has been re-copied and the inventory re-extracted and there is no state left to decline
into. What this phase owes is the restatement: report which dispositions this write discarded, how
many of each, and that they must be re-taken in `/product-workflows:brd-split`'s walk. A rewrite the
operator consented to at step 7 is still a rewrite the run has to name.

---

## Phase 6 — Migrate existing work (`--sort-existing <dir>`, optional)

Only when `--sort-existing <dir>` was given (Phase 0/1). Read the hand-written package at `<dir>`
and sort its sections **by altitude** — product-level content (what / why / for-whom) into
`<BRD-dir>/prd-seed.md`, architecture-level content into `<BRD-dir>/ard-seed.md`, and
implementation-level content into `<BRD-dir>/spec-seed.md`.

**These land on the BRD root, and every consumer resolves a slice — so say where they are.** `<BRD-dir>`
is always a root `BRD-` container (Phase 0 step 7 calls a slice a mis-keyed invocation), while
`/create-prd`, `/create-ard` and `/specify` each read their seed out of the resolved `PRD-` slice and
each refuse a `BRD-` container before reading anything. Slices do not exist yet at intake time, so the
seeds cannot be written into them here, and this run must not pretend otherwise: **name the three paths
in the run's output and state that a later slice consumer reads them from this folder, one level up
from itself.** Without that the migration's whole output sits where nothing looks — written, committed,
and never read by any command.

State plainly in the run's output that
this is **the migration path for work already done by hand**, before this workflow existed — and
that it **writes seeds only, never findings**: no `[CG#n]`/`[DG#n]` grounding, no ledger
disposition, comes out of this phase. Those are `/prd-ground`'s and `/brd-split`'s to produce, once
grounding has actually run. When `--sort-existing` was not given, this phase is skipped silently.

---

## Phase 7 — Handoff

Invoke `Skill(skill: "workflows-core:reference", args: "phase-handoff")` and present its §4.3 choice array verbatim — the **advisory** array: `/product-workflows:brd-split` on a root reads this
handoff's artifacts with a plain worktree read at its own step 8, never a `require-on-main` gate
(steps 6 and 7 run only in `split_mode: allocate-only`), so nothing downstream gates any of them any
more:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (no command stops on this; what reads it reads your working copy)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`Skill(skill: "workflows-core:reference", args: "phase-handoff handoff-to-main")`, §2) with `prefix: brd`, `feature_folder` as resolved in Phase 0, `deliverable_paths` = every file
this run wrote under `<BRD-dir>` — **enumerated, one literal repo-relative path each: never a glob and never a directory**, because §2.3 stages neither, so a declaration that looks complete ships nothing — §2.3 step 4 names each in §4.1's *declaration unaccounted for* clause, so the failure is reported rather than silent, but nothing it names lands. That is each file this run actually copied into `brd/source/` or `brd/source-external/` — the customer's document **and every file it links** (Phase 2) — named individually (the copy step knows them; neither `brd/source/**` nor `brd/source-external/**` is a path), plus `brd/brd-inventory.md`, `brd/brd-defect-log.md`, `brd/brd-link-log.md`, `brd/brd-figures.md` when Phase 2.5 wrote it,
`coverage-ledger.md`, and — only when Phase 6 ran — `prd-seed.md`, `ard-seed.md`, `spec-seed.md`),
`title: <BRD-KEY> Intake BRD source and requirement inventory`, and `body_facts` = the requirement
count, the confirmed-defect count by class, and whether Phase 6 wrote seeds; emit its §4.1 outcome
line in the final report.

`brd` is the branch prefix `workflows-core:phase-handoff` §2.9 lists as shared by every `/brd-*`
command (the way `prd` is shared by `/create-prd` and `/update-prd`) — a BRD is neither a PRD nor
any of the other five prefixes, and reusing `prd` would collide with the `prd/<SLICE-KEY>-<slug>`
branch `/create-prd` on the BRD route opens once a slice of this BRD is PRD-eligible. **That
switch ships**, so the collision is live rather than hypothetical: that command's handoff derives
`prd/<SLICE-KEY>-<slug>` from a slice folder nested inside the very folder this run wrote into,
exactly as `/product-workflows:create-ard` on the BRD route derives `ard/<SLICE-KEY>-<slug>` and
`/product-workflows:specify` on the BRD route derives `spec/<SLICE-KEY>-<slug>` from it. Keeping `brd`
separate is what lets all four branches exist on one key without either family renaming anything —
and this command's own `<BRD-KEY>` never carries the other three, because **the folder it creates is
a container**: a PRD, an ARD and a specification are authored in the `PRD-` slices under it, one
each, and all three commands refuse the container itself
(`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5).

---

## Phase 8 — Next steps

**Branch on Phase 3's result.** A BRD whose inventory holds no `[BR#n]` row is refused by every
downstream command on the route, so offering one here would name a run that stops on its own Phase 0
— the offer `workflows-core:next-phase-offer` exists to prevent.

**One or more `[BR#n]` rows — the ordinary case:**

```
choices: ["Carve slices — /product-workflows:brd-split <BRD-KEY> \"<how to cut it>\" (Recommended)", "Stop here"]
```

**Zero `[BR#n]` rows (a Phase 3 `EMPTY` read) — `/product-workflows:brd-split` is left out rather than
offered and refused:**

```
choices: ["Re-run this intake with a corrected source — /product-workflows:brd-intake <BRD-KEY> @<brd-file> (this folder is a re-run, not a refusal)", "Stop here — this document states no requirement the route can carry"]
```

Neither option on that second list carries a `(Recommended)` marker, and the omission is deliberate
per the `When no option is safe to recommend` guidance in
`Skill(skill: "workflows-core:reference", args: "escalation-rules")`: whether the source was mis-converted, was
the wrong file, or genuinely states no requirement is a judgement about the customer's document, and
only the operator who has read it can take it. Say beside the list which conversion or file this run
actually read, so that judgement has something to stand on.

`/product-workflows:brd-split <BRD-KEY>` refuses this same emptiness on a root —
`BRD_SPLIT_EMPTY_INVENTORY (split_mode: full)` — which is why it is left out here rather than offered
and refused. `<BRD-KEY>` here is always a root: this command never writes a slice, and
`/product-workflows:prd-ground <BRD-KEY>` is never the fix for one — it refuses any root BRD
outright, at its own Phase 0 step 5a, with `PRD_GROUND_ROOT_LEVEL`, before it ever reaches a
merge-state gate; grounding now happens only at the slice `/brd-split` carves. **The offer above
carries no `<merge-clause>`**, and that is derived, not an oversight: `/brd-split` on a root reads
this handoff's artifacts with a plain worktree read at its own step 8, gating none of them, so there
is no wait to state. Guidance only — never auto-invokes another command.
Per `workflows-core:next-phase-offer`.

### Context hygiene

Per `workflows-core:session-hygiene`, the resume pointer is written in the
terminal cost phase (Phase 9), after the cost entry and before the commit step. Continuing this
route into `/product-workflows:brd-split <BRD-KEY>` — both PM — keeps the context relevant → run
**`/compact`**. Guidance only — nothing is auto-run.

---

## Phase 9 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 8, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command /
reference gap**, `emit-block` (per `workflows-core:feedback-emission`) at that
halt **before** escalating. None of Phase 0's stops qualify — a missing key, a missing source, a
non-markdown source, and an unset `$SPECS_PATH` are all environment / user halts, never a plugin
capability gap, so `emit-block` never fires from this command's own Phase 0. Nor does Phase 1's
`BRD_INTAKE_UNREAD_ATTACHMENTS`: linked files the operator must convert first are an operator halt,
as Phase 1 says where it stops.

1. **Invoke `impl-maintenance`** (subagent_type: "workflows-core:impl-maintenance", model:
   `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/brd-intake`; what was
   produced (the copied source and the files it links, the figures transcriptions, the inventory,
   the confirmed defect log, the link log, the ledger skeleton); key events (a rejected PDF, an
   *other* file the operator accounted for, an `EMPTY` read, a link the copy could not capture, an
   `ambiguous` wikilink, an image not read, unresolved candidates left `open`, docs grounding OFF or
   a docs-raised defect — or "none"); workarounds; test result N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Invoke `Skill(skill: "workflows-core:reference", args: "feedback-emission emit-auto")` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-intake`, the run's `key` (the `<BRD-KEY>`),
   `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
   Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Invoke `Skill(skill: "workflows-core:reference", args: "cost-emission emit-cost")` and call its `emit-cost` entry point with `command: /brd-intake`, `phase: brd-to-prd`, `role: pm`, the
   run's `key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Invoke `Skill(skill: "workflows-core:reference", args: "session-hygiene")` and, per its §1, write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry above, and before
   the commit step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Invoke `Skill(skill: "workflows-core:reference", args: "specs-repo-git commit-artifacts")` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths
   inside `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-intake)` with
   no `Co-Authored-By` trailer, and pushes to the branch Phase 7's handoff created. It NEVER touches
   a code repo, a docs repo, or the current working directory, where it is not the specs repository; NEVER force-pushes; NEVER
   fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting
   that notice. Hold its §6 outcome line for the final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is
offered only in Phase 7), and NEVER writes into a code/docs repo or the current working directory, where it is not the specs repository;
no user name is ever written.

---

## Final report

Report: the BRD folder + source path; how many files were copied beside the source — inside its
directory and into `brd/source-external/` — and, per `brd/brd-link-log.md`, every link the copy
could not capture with its reason (Phase 2), with Phase 1's answers and any *other* file the
operator accounted for; how many images were transcribed, re-used and not read, with each reason
(Phase 2.5); how many linked markdown files were read beside the document (Phase 3); the coverage
outcome for sections and images; the requirement count; the confirmed-defect count by class
(and how many candidates were rejected, and how many of the confirmed ones were raised from
documentation rather than by `brd-reader`); the `docs grounding:` line from Phase 1 verbatim, and —
when it was ON — the `docs_references` list of requirements the shipped documentation describes as
already built, flagged for `/prd-ground` to check against code; whether Phase 6 wrote seeds and
which; resolved model routing (+ any Opus degradation); the feedback + cost paths; the `Phase handoff:` outcome line from
`handoff-to-main` (`workflows-core:phase-handoff` §4.1), including the `brd`
prefix note; the `Specs repo:` outcome line from `commit-artifacts`
(`workflows-core:specs-repo-git` §6); the next-step recommendation; and end with
the ledger line, exactly per `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

Since `/brd-intake` writes every row `unallocated`, this run's own line always reads
`ledger: <N> requirements — 0 covered, 0 deferred, 0 rejected, <N> unallocated, 0 unresolved (0 delegated, 0 not built)`
(or the Phase 3 `EMPTY` line above) — the non-zero counts appear only once `/brd-split` has run.
The `covered-by` resolution §6 requires reads no child ledger here and never can: no row this
command writes is `covered-by`, so the delegated figures are zero by construction rather than by
omission, and this command gains no precondition from it.

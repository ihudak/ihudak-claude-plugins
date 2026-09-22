# `/brd-intake` reads what it captures — figures, appendices, and the defect questions nobody asked — design

**Status:** approved in brainstorming 2026-09-18, amended the same day (§14 — the shared link walk, which widens the scope to `/idea`), not yet implemented. Opens no ledger item; it closes two shipped defects (§1.3, and §14.1's silently dropped wikilinks) and adds a capability (§1.1, §1.2, §14).

**Plugin:** `product-workflows` only, unless the §9 sweep of `workflows-core:grounding-format` §6.1 changes that file. One new agent, `product-workflows/agents/figure-reader.md`, shared by `/brd-intake` and `/idea` (§14.4). One new reference file, `product-workflows/references/linked-sources.md` (§14.2). One new plugin-written artifact per BRD, `brd/brd-figures.md`, whose format is a new §1.2 of `product-workflows:brd-format`, and one new BRD directory, `brd/source-external/` (§14.3). No new command, hook, skill or environment variable.

**Where §14 and an earlier section disagree, §14 governs** — the earlier sections are the design as first approved, and §14 records what the amendment changed in them rather than rewriting their reasoning.

**Derivation.** Every decision below traces to an answer the operator gave in brainstorming, recorded in §2 with the question that produced it. Where the design goes past an answer it says so and why.

## 1. The problem

### 1.1 The route captures a customer's images and nothing ever reads them

`/brd-intake` Phase 2 copies every file the customer's document links from its own directory into `brd/source/`, byte-for-byte, and says of them: *"nothing in this run reads its content"*. `brd-reader` reads only `source_path`. The copied images are not in a `design/<frame-set>/`, so `/frames` never indexes them and `design-grounder` never reconciles them (`workflows-core:grounding-format` §6.1 — both read `design/*/` only). Grounding is slice-only and a slice holds no `brd/source/`, so even that layer sits one level below where the images are. No command moves them.

Net effect: an image survives as a record and informs nothing. The operator reports that their customers' BRDs carry 10–30 linked images each, of four kinds that all turn up regularly: annotated screenshots of the current product ("add a column here", "this total is wrong"), mockups of what they want, example outputs the result must match (reports, exports, formats), and diagrams (process flows, approval chains, integrations). Three of those four carry obligations by construction.

### 1.2 Linked markdown appendices are captured and never read either

Same mechanism, same line. A requirement stated in `appendix/report-fields.md` yields no `[BR#n]`, and `brd-format` §2.2's coverage check cannot see the loss: it reads the document's own top-level sections, is written on the premise that a linked file *"carries no section and holds no `[BR#n]`"* (`commands/brd-intake.md` Phase 3), and its only remedy re-dispatches `brd-reader` over the same document. At best it flags the section that says "see appendix"; where that section also holds another row, it flags nothing.

### 1.3 A shipped defect: an open requirement defect is never put to the customer

An `ambiguity`, `conflict`, `duplicate`, `untestable` or `scope-leak` `[DEF#n]` confirmed at intake is designed to be settled by the customer — `brd-format` §4's `customer-amended` and `withdrawn` resolutions, which `/brd-reconcile` Phase 8 writes. Nothing asks them:

- `/brd-interview` Phase 3 generates round 1 from grounding findings, horizons, `[DG#n]` reconciliations, ledger dispositions and assertions-without-evidence. The strings `[DEF#` and `brd-defect-log` occur in that file zero times.
- `/brd-package` ships `brd/brd-defect-log.md` in the bundle so citations resolve, and its step 10 states *"nothing in this run reads their content"*.
- `customer-review-schema` §4's twelve sections carry no defect section. Section 4 (requirement traceability) confirms the package's *reading* of a requirement; it does not ask which of two readings the customer meant.

So an open ambiguity reaches the customer only if they happen to read the defect log and happen to comment on it. This is on `main` and published. Under the standing release rule it blocks the next release, and it is fixed here because §1.1's images depend on it: an image-only obligation "has to be asked" (§2, D2), and asking is exactly what the route does not do.

## 2. Decisions

| # | Decision | Why — the answer or the evidence behind it |
|---|---|---|
| D1 | Customer images are **part of the customer's statement**, read at intake — not design evidence reconciled at grounding | All four image kinds turn up (question *"what do the linked images mostly show?"*); three of the four carry obligations. A requirement-bearing picture belongs beside the prose the inventory is extracted from |
| D2 | An obligation stated **only** in an image becomes a proposed `[BR#n]` carrying an automatic `ambiguity` candidate, unless the linking prose makes the image binding | Question *"when an image shows something the prose doesn't, what do they usually mean?"* — answer: **varies; it has to be asked**. `brd-format` §3's `ambiguity` test fits exactly: one reader builds what is drawn, another does not, both defensible. The six classes stay six |
| D3 | Scope is **images and appendices**, plus the §1.3 fix | Scope question — answer: *images + appendices*. Both gaps are the one line "`brd-reader` reads only the document"; §1.3 is a precondition for D2 |
| D4 | **Transcribe first, then extract**: a new agent transcribes images in parallel; `brd-reader` then extracts from document + appendices + transcriptions in one text pass | Approach question — answer: **B**. Separates seeing from judging; scales by fan-out; the extractor keeps the whole document in view, so prose elsewhere that already states an image's content is seen, and a false image-only candidate is not raised |
| D5 | **Both agents pinned `model: opus`** | Operator challenge to a Sonnet pin, then the operator's own extension to `brd-reader`: *"these documents can be long and complicated with human mistakes, ambiguities"*. A misread transcription or a missed conflict yields no candidate, so Phase 4's human never sees it — the failure is silent in the direction that matters. `brd-reader`'s own justification for Sonnet (*"extraction is mechanical"*) is false for its defect-candidate half. **Unmeasured**: no tier comparison was run (§11) |
| D6 | **No total cap on images read**; batches of ≤10 per dispatch, ≤4 dispatches concurrent, in waves | A cap would recreate §1.1's loss. Volume answer: 10–30 per BRD, one wave |
| D7 | Unreadable attachments (PDF, spreadsheet, anything neither markdown nor an image) are **named at Phase 1 and the operator converts them**; nothing converts them for the operator | `brd-format` §1's markdown-only rule applied to attachments: conversion is the operator's checked step. At Phase 1 nothing has been written or spent, so declining is free |
| D8 | Questions generated from a requirement defect are **always `[C]`** | The defect is in the customer's own statement; only the customer can say what they meant |
| D9 | The answer's link back to its defect is a **structured field** (`settles`) on the decision record, never parsed from prose | `CLAUDE.md`: resolve against a known set; never parse an identifier out of free text |

## 3. `/brd-intake`, phase by phase

**Phase 1 — Confirm.** Before consent, enumerate the capture **in place, read-only**: run Phase 2's link walk (same link forms, same target test, same transitive pass over linked markdown) against the customer's directory without copying anything. Show the counts by kind — **appendix** (markdown), **image** (`workflows-core:grounding-format` §6.2 step 1's extensions: `.png .jpg .jpeg .gif .svg .webp`, case-insensitive), **other** — and name every *other* file. This makes Phase 1's existing sentence (*"so the operator sees what is about to be copied out of their filesystem before consenting to it"*) literally true, where today it describes a directory rather than a list. Where no *other* file is linked, the existing array stands. Where one or more is:

```
choices: ["Stop and convert them first — nothing has been written (Recommended)", "Proceed — none of them carries an obligation (recorded)", "Use a different key or path (you'll be prompted)"]
```

*Stop* ends the run with nothing written: `BRD_INTAKE_UNREAD_ATTACHMENTS: <n> linked file(s) are neither markdown nor an image and would be copied but never read: <list>. Convert each (markdown for a document, PNG for a picture), link the converted file from the BRD, check the conversion, and re-run.` It is an operator halt, not a plugin gap, so `emit-block` does not fire — the same call Phase 9 makes for every Phase 0 stop. *Proceed* records the operator's account in the final report, exactly as Phase 3's *"They hold no obligation"* answer is recorded today.

**Phase 1.5 — Classify + model routing.** Both agents are `model: opus`; the YAML comment and the paragraph *"`brd-reader` runs on Sonnet regardless of `classification`"* are rewritten. An Opus that does not resolve degrades per `workflows-core:model-routing` §2 and is recorded in `notes` and the final report, as the command already does for its own tier.

**Phase 2 — Copy.** Unchanged, plus: each copied file carries its kind from Phase 1's enumeration.

**Phase 2.5 — Read the figures (new).** Dispatch `product-workflows:figure-reader` over every copied image, ≤10 per dispatch, ≤4 dispatches in a single response, further waves until none remain. **Re-use before reading**: where `brd/brd-figures.md` already holds a section for an image whose content hash matches, that section is kept verbatim and the image is not dispatched — the preserve-what-you-did-not-produce rule `grounding-format` §6.2 applies to an index row. Write `brd/brd-figures.md` (§5). An image the agent could not read gets its section with the reason and no transcription.

**Phase 3 — Extract.** Dispatch `brd-reader` (§6) with the document, the copied appendices in Phase 2's capture order, and `brd/brd-figures.md`. The reconciliation on a re-run is unchanged — match by `source_anchor`, else by `text` — and is applied to **every** id the agent returns: row ids, every `names` entry, and every `illustrates` entry (§6). A mapping applied to row ids alone would leave a candidate or a figure pointing at the agent's numbering rather than the inventory's.

**Phase 3 — coverage check (`brd-format` §2.2), widened.** Relation 1 resolves all three anchor forms (§7). Relation 2 runs over the top-level sections of the document **and of each appendix**. A third relation: every image is **read and yields a row**, **read and illustrates a row**, or is **accounted for** — read and bearing on no obligation (a logo, a decorative banner), or not read, with its reason. One question for the whole set, as today; the options are unchanged.

**Phase 4 — Confirm defects.** A candidate on an image-derived row is shown with the image path and its transcription, and the operator is told to open the image before confirming. Nothing else changes: the same classes in the same order, the same array.

**Phase 5 — Ledger.** Unchanged, plus: complete `brd/brd-figures.md`'s *Rows* line for each image from the final inventory (after the reconciliation mapping).

**Phase 7 — Handoff.** `deliverable_paths` gains `brd/brd-figures.md` whenever the run wrote it.

**Phase 9 and the final report.** The `impl-maintenance` handoff and the final report gain: images read / reused / not read with reasons, appendices read, any *other* file and the operator's Phase 1 account, and the figure-coverage outcome.

## 4. The new agent — `product-workflows:figure-reader`

**Job:** state exactly what is written and drawn in each image. Never what it obliges.

**It never reads the BRD.** It receives images and nothing else, so a transcription cannot be bent toward what the prose says — which is what lets `brd-reader` see an image contradict the prose rather than having the contradiction smoothed away one step earlier.

**Frontmatter:** `model: opus`, `tools: ["Read"]`.

**Inputs**

```yaml
source_dir: <absolute path to <BRD-dir>/brd/source/>
figures:                          # ≤10, in the order to read them
  - path: images/report.png       # relative to source_dir, exactly as Phase 2 copied it
```

Refuses to run without `source_dir` or with an empty `figures` list (`status: INPUT_MISSING`). A path that normalises outside `source_dir` is returned `read: false, reason: outside_source` and never opened.

**Output**

```yaml
status: OK | INPUT_MISSING
figures:
  - path: images/report.png
    read: true | false
    reason: missing | not_an_image | unreadable | outside_source   # iff read: false
    appearance: screenshot | wireframe | document | diagram | photo | other
    depicts: <one sentence — the screen, report, form or flow>
    text: |
      <verbatim, region by region, in reading order: titles, labels, column headers, field
       names, legends, captions; for repeated data rows, the header, one representative row,
       and "N rows shown">
    annotations:
      - says: "<verbatim; empty for an unlabelled arrow, box or highlight>"
        points_at: <the element the mark sits on or points to>
    flow:                          # diagrams only
      - "<node> → <node> [<edge label>]"
    illegible: <what could not be read, or "none">
notes: <anything the caller should know, or nothing>
```

`appearance` is the only classification it makes, because appearance is observable; it cannot reliably tell a current-product screenshot from a polished mockup and does not try — that call is `brd-reader`'s, from the prose around the link. Every entry handed in is returned once, in order.

**Hard rules.** Reads only the listed files. Never infers anything from a filename. Never translates or corrects text — typos are kept, as `brd-reader` keeps them. Never emits an id, a candidate, an obligation or a judgement — *must*, *required* and *missing* are not its words. Every unreadable part is named in `illegible`, so a partial transcription is never silent. An `.svg` arrives as text; its `<text>` elements are what is transcribed. Never edits anything.

**Distinctions its body states**, as the family's image readers each do: `frame-describer` writes one to three sentences for an index; `idea-reader` returns an idea digest; this agent transcribes, in full, what a customer wrote and drew.

## 5. `brd/brd-figures.md`

The **plugin's** record of what it read in the customer's images — beside `brd-link-log.md` in `brd/`, never under `brd/source/`, whose every byte is the customer's (`brd-format` §1.1 makes the same call for the link log). One section per image, because transcriptions run to many lines and a table cell cannot hold one.

```markdown
---
kind: brd-figures
key: <the run's <BRD-KEY> as Phase 0 validated it — never parsed from the folder name>
source: <the document's basename, as brd/brd-link-log.md names it>
written_by: brd-intake
---

# Figures: <BRD-KEY>

Images captured <n> · read <n> · reused from an earlier run <n> · not read <n>

## images/report.png

- **Linked from:** `appendix/notes.md` › Reporting
- **Read:** yes                                   ← or: no — <reason>
- **Content hash:** sha256:<hex>
- **Appearance:** screenshot · **Depicts:** <one sentence>
- **Rows:** yields [BR#14], [BR#15]; illustrates [BR#6]   ← or: accounted for — <the operator's account>

### Text
<verbatim>

### Annotations
| Says | Points at |
|---|---|

### Flow
<diagrams only>

### Illegible
none
```

**Re-runs.** `brd/source/` is additive (`brd-format` §1.1), so this file is too: an image the revised document no longer links keeps its section, marked *no longer linked by the current source* — it has to, because an inventory row the reconciliation preserved may anchor on it. A section whose hash no longer matches its file is re-read and replaced. A section is never deleted.

## 6. `brd-reader`

**Frontmatter:** `model: opus`. The description's *"Uses Claude Sonnet. Extraction is mechanical"* is replaced; the body's step 1 (*"reads only `source_path`"*) and the `Glob` rule are rewritten for the new inputs.

**Inputs**

```yaml
source_path: <the document under brd/source/>
appendices:                      # the copied markdown files, in Phase 2's capture order; may be empty
  - <absolute path>
figures_path: <absolute path to brd/brd-figures.md, or omitted when the BRD links no image>
```

It reads exactly those files and discovers nothing. `NOT_FOUND` covers a missing appendix or figures file as it covers a missing document.

**Numbering.** The document first, in source order; then each appendix in the order given; a row drawn from an image sits at the passage that links the image (first link wins).

**Image rules** (the text of `brd-format` §3's new paragraph, §7, applied):

- An obligation the image states and **no prose anywhere** in the document or its appendices states → a row anchored on the image, carrying an `ambiguity` candidate whose reason is *"stated only in `<image>` — binding force unknown"* — **unless** the passage linking the image makes it binding (it states the image as what must be matched or followed: *"must match the attached"*, *"as shown in figure 3"*, *"according to the diagram"*). An illustrative or current-state framing (*"for example"*, *"today the screen looks like"*) does not.
- An image that cannot hold together with a prose row → the image-derived row and a `conflict` candidate naming the prose row, as §3 requires of every `conflict`.
- An image that restates the prose → no row; the prose rows it restates are returned under `illustrates`.
- **An image-derived row's `text` states the obligation in words, quoting the transcribed element verbatim** — every downstream reader (`code-grounder`, `/brd-interview`, the customer) reads the text, and none of them reads the picture.
- A candidate grounding must settle keeps its usual class: an annotation asserting current behaviour (*"this total is wrong"*) is `unsourced` as well as whatever else it is.

**Output gains**

```yaml
figures:                           # one entry per read image in figures_path
  - path: images/report.png
    illustrates: [BR#6]            # prose rows the image restates; empty when none
    note: <optional — e.g. "company logo; bears on no obligation">
```

The rows an image *yields* are derivable from their anchors and are not returned twice.

## 7. `product-workflows:brd-format`

- **§1.1** — *"the intake run reads only the document"* is replaced: intake reads the document, its linked markdown and its linked images; a file of any other kind is captured, named at Phase 1, and not read.
- **§1.2 (new) — `brd/brd-figures.md`.** Its format (§5 above), its writer (`/brd-intake` Phase 2.5 and Phase 5, the only one), and its standing: **a transcription is the plugin's reading of the customer's image, not the customer's words**, which is why a row drawn from an image anchors on the image and never on the transcription, and why Phase 4's human and the customer both check it against the picture.
- **§2 — `source_anchor`** takes three forms: in the document, a heading path or line range (as today); in an appendix, `<appendix path> › <heading path or line range>`; in an image, `<image path> › <element>`, the element a double-quoted string from the transcription (`› "Net total" column`) or `annotation <n>`. Numbering per §6 above.
- **§2.1** — a slice resolves an image anchor through the **parent's** `brd/brd-figures.md`, one hop, exactly as it resolves every other anchor through the parent's `brd/source/`.
- **§2.2** — relation 1 resolves each form: an appendix anchor to a section of that appendix, by the same three-branch order; an image anchor to a *read* image whose transcription (text or annotations) contains the quoted element verbatim, or whose `annotation <n>` exists. Relation 2 covers each appendix's top-level sections. Relation 3 (new): every image yields, illustrates, or is accounted for. *"Nothing new is stored, and no agent returns a new field"* is no longer true of relation 3 and is rewritten — it reads the figures file and `brd-reader`'s `illustrates`.
- **§3** — the table keeps six rows. A paragraph below it states the image rules of §6 above: the automatic `ambiguity` on an image-only obligation and its binding-prose exception, and that a conflict between an image-derived row and a prose row is an ordinary `conflict` naming its counterpart.
- **§4** — `resolved-by: [CG#n]` becomes `resolved-by: [CG#n] | [CD#n]`, still four resolutions. `[CD#n]`: the customer said which reading they meant (§8).

## 8. From an open defect to the customer and back

**The seventh question source** (`/brd-interview` Phase 3). Every `[DEF#n]` in `brd/brd-defect-log.md` — the **parent's** on a slice, one hop — that is `open` and whose class grounding cannot settle: `ambiguity`, `conflict`, `duplicate`, `untestable`, `scope-leak`. **`unsourced` is excluded**: it is a pointer for grounding, settled by `resolved-by: [CG#n]`, and a finding that cannot settle it is already a question under the existing `NOT-PROVABLE` source.

**Which slice asks is resolved against the inventory, never against the log.** The defect-log entry carries no row field — `brd-format` §4 fixes only its resolution, and `/brd-intake` Phase 4 records a `[DEF#n]` *"against every `[BR#n]` it was raised on"*, which may be several. The structured relation is the inventory's `defects` column (`brd-format` §2). A defect's rows are the rows whose `defects` column lists it; it is asked **once**, by the slice whose scope holds the **lowest-numbered** of those rows, and every other row it lists — and every counterpart a `conflict` or `duplicate` names — is context. Two slices asking the customer the same thing is what `interview-tagging` §5 names as an invitation to two contradictory answers one `[CD#n]` cannot hold. **Scope** is the existing `disposition`-column scoping narrowed to the rows still to be built: `covered-here` and `deferred-to`. A row already `rejected` or `superseded-by` has its fate, and asking which reading its customer meant is moot — the existing *"a row resolved `deferred-to` or `rejected` whose consequence is unstated"* source already covers what the customer needs to hear about it. A defect whose lowest-numbered row no slice holds in that scope is not asked until one does. The plan confirms what `/brd-intake` Phase 4 actually writes into a log entry before relying on this, and states the entry's fields in `brd-format` §4 if the answer is "whatever the run chose". Every sentence that counts the sources — the no-question round record *"names each of the six question sources"*, and `/brd-package`'s reliance on that record — is re-counted, never decremented or incremented by hand.

**Tagging** (`interview-tagging` §1, new rule). A question generated from a requirement defect is `[C]`: the defect is in the customer's own statement. Where the delivery team has a preferred reading, the question carries it, so the customer confirms rather than authors. §4's split rule still applies to a question with a `[G]` part.

**The held question carries its defect** (`/brd-interview` Phase 7). The `customer-questions.md` entry gains the `[DEF#n]` it was generated from and, for a defect on an image-derived row, the image path — the customer holds the image in the bundle.

**The decision record gains `settles`** (`decision-register-format` §1): an optional list of `[DEF#n]`, omitted when absent, written by `/brd-reconcile` onto the `[CD#n]` that answers a question whose held entry names a defect — resolved from that entry, never parsed from the customer's prose. It is not `evidence` and not `defects`, for the reason §1 already gives `defects`: a non-finding id in `evidence` would silently change what the will-change rule inspects.

**`/brd-reconcile` Phase 8 writes a third resolution.** For each `[DEF#n]` a frozen `[CD#n]` `settles`: `withdrawn` where that decision drops the requirement (Phase 9's existing rule then writes `rejected: [DEF#n]`), `customer-amended <date>` where the review supplied corrected text, otherwise `resolved-by: [CD#n]`. *"This command writes two of them, and only those"* is rewritten. A `conflict` the customer settles in favour of one row flows through Phase 9's existing `superseded-by` row; nothing new is needed there. **"It was just a sketch"** — an image-only row the customer disowns — therefore ends `rejected: [DEF#n]` with no new machinery.

**The bundle ships `brd/brd-figures.md`** (`bundle-packaging` §1.1, a new allow-list row — the parent's on a slice, one hop, as the defect log is), sent there by the requirement-traceability prompt part. `customer-review-schema` §4 row 4 names the transcriptions of the customer's images as part of *"the package's reading"* the section confirms or corrects. The customer is the one participant certain to catch a misreading of their own screenshot. **Interaction to settle in the plan:** `bundle-packaging` §6's citation-resolution check will scan this file's *Rows* lines; on a slice those name the parent's `[BR#n]`s, not all of which are in the slice's inventory. §6.2 relation 1 already discharges a parent-level `[BR#n]` as a qualified cross-package reference; the plan confirms that clause reaches this file or states the rule that does.

**Existing slices.**

- **A defect confirmed after a slice's last round closed** makes a new round askable: `/brd-interview` Phase 2's *every round closed* change test gains *"a `[DEF#n]` in scope confirmed since that round closed"* beside its finding and decision triggers.
- **A defect open all along on a slice interviewed before this ships** belongs in round 1 — *"a question that could have been asked in round 1 and was not … stays in round 1"*. The remedy is the existing `--round 1` re-open with the cause *"requirement defects became a question source"*; the spec for Phase 2 states that a re-open with this cause generates that source's questions into the re-opened round, appended after its last question and never renumbered. **Population unmeasured** — the operator did not say whether such slices exist. If none do, this clause shrinks to a changelog sentence.

## 9. Surfaces

Swept by subject and by phrase per `CLAUDE.md`'s refinements (scope `plugins/` plus the two root files, changelogs included; wrap-insensitive before/after counts per changed string; exclusivity probe as its own axis). The known list, which the sweep extends rather than bounds:

| Surface | Change |
|---|---|
| `product-workflows/agents/figure-reader.md` | new (§4) |
| `product-workflows/agents/brd-reader.md` | inputs, step 1, numbering, image rules, output, hard rules, `model: opus`, description (§6) |
| `product-workflows/commands/brd-intake.md` | frontmatter description; Phases 1, 1.5, 2, 2.5 (new), 3, 4, 5, 7, 9; final report (§3) |
| `product-workflows/commands/brd-interview.md` | Phase 2 change test and re-open cause; Phase 3 seventh source; Phase 4 tagging; Phase 7 entry; every count of the sources |
| `product-workflows/commands/brd-reconcile.md` | Phase 8's third resolution; `settles` on the frozen `[CD#n]` |
| `product-workflows/commands/brd-package.md` | resolve `brd-figures.md` one hop beside the defect log; any restated source count |
| `product-workflows/references/brd-format.md` | §1.1, §1.2 (new), §2, §2.1, §2.2, §3, §4 (§7) |
| `product-workflows/references/interview-tagging.md` | §1 rule for defect-derived questions |
| `product-workflows/references/decision-register-format.md` | §1 `settles` |
| `product-workflows/references/bundle-packaging.md` | §1.1 row; §6 interaction (§8) |
| `product-workflows/references/customer-review-schema.md` | §4 row 4 |
| `workflows-core/references/grounding-format.md` | §6.1's paragraph naming the agents that read pictures — sweep for an exclusivity claim; change only if false |
| `workflows-core/references/docs-grounding.md` | names `brd-reader`; check |
| `product-workflows/docs/**` | agents page (new row, count, `brd-reader`'s tier), `brd-intake`/`brd-interview`/`brd-reconcile`/`brd-package` pages, `brd-workflow.md`, references page |
| `dev-workflows/docs/reference/agents.md` | names `brd-reader`; check |
| `product-workflows/README.md`, `plugin.json`, `.claude-plugin/marketplace.json` | agent count where stated; version 3.7.0; description only if it names what changed, and replaced rather than appended (1024-char budget) |
| `CLAUDE.md` | *thirteen subagents* (twice) → fourteen; the `/brd-intake` map line; the agent tree gains `figure-reader`; the `/brd-interview` map line if it lists sources |
| `product-workflows/CHANGELOG.md` | 3.7.0 entry, including the §1.3 fix stated as a fix |

## 10. Non-goals — each with its reason, so it is not re-proposed without new evidence

- **Design grounding of the customer's images.** They are not copied into `design/`, and no `[DG#n]` is minted from one. `design-grounder`'s four classes are written for a design team's frames: class 1 (*a frame shows a field no requirement asks for*) fires on every column of a current-product screenshot. The obligations reach grounding as `[BR#n]` text instead. `brd/brd-figures.md` is the index a later increment would start from, if one is ever wanted.
- **Reading PDFs and spreadsheets.** Named at Phase 1 and converted by the operator (D7).
- **URLs.** Logged as today; not fetched and not read. (Absolute paths and targets outside the source directory were in this list as first approved; §14.3 now captures them behind the operator's consent.)
- **`/frames` and `frame-describer`.** Unchanged: `/frames` indexes a design team's frames, a different job. (`/idea` was in this list as first approved; §14.5 changes it.)
- **A per-row `figures` column in the inventory.** The image-to-row relation lives in `brd-figures.md`'s *Rows* line so the inventory's row shape, which a dozen commands read, does not move.

## 11. Verification

1. **The nine gates, on the branch and again on the merged tree**, as one `&&` chain with its status read. Expected movement: check 5 and check 9 on `product-workflows`'s agent inventory (a fourteenth agent, its docs row, every counted sentence); check 12 on Phase 1's new three-option array.
2. **A mutation control on every gate touched** — revert → green; an injected control that *violates* (the new agent's docs row deleted; the count sentence left at thirteen) → red, naming the check.
3. **A dry run over a hand-built fixture, expected inventory derived before the run.** A short BRD; one appendix holding a field list; four images — an annotated screenshot (*"add a filter here"*), a mockup with one field the prose never mentions, a sample report whose column contradicts the prose, an approval-flow diagram the prose calls binding; one linked PDF. A subagent executes the worktree's `/brd-intake` prose with both agents on Opus. Expected: Phase 1 names the PDF and *Stop* writes nothing; on *Proceed* — rows from the appendix anchored `appendix/… › …`; an image-only row with an `ambiguity` candidate for the mockup's extra field; a `conflict` naming the prose row for the report; the annotation as a row; **no** `ambiguity` on the diagram; `brd-figures.md` in §5's shape with *Rows* completed; the coverage check accounting for every file. A second run over the unchanged fixture re-reads no image (hash re-use). The fixture's images are clean renders, so this proves the pipeline and not transcription quality; D5 stays recorded as unmeasured.
4. **The §8 path by construction**: a fixture slice with an open `ambiguity` `[DEF#n]` on an in-scope row; `/brd-interview`'s Phase 3 prose, executed, generates a `[C]` question naming it; a fixture review answering it, run through `/brd-reconcile`'s Phase 8 prose, writes `settles` and `resolved-by: [CD#n]`; a second fixture answer dropping the requirement ends `withdrawn` → `rejected: [DEF#n]`.
5. **Sweeps** per §9, each changed string counted before and after.
6. **Adversarial review passes on frozen snapshot worktrees** to zero known bugs; local merge; push only on the operator's explicit go-ahead.

## 12. Release

`product-workflows` 3.6.1 → **3.7.0** — minor: a new agent and new behaviour, and the §1.3 defect's fix ships inside it. `workflows-core` is bumped only if §9's sweep changes `grounding-format`. The changelog states the §1.3 fix as a fix and names its population: every BRD intaken with a confirmed non-`unsourced` defect.

## 13. Recorded as unmeasured

- **D5's tier.** Opus for both agents is a default taken on an asymmetric-cost argument, not a comparison. A comparison on real customer screenshots, hand-checked, would settle it.
- **Transcription fidelity on real images** — low resolution, scribbled mark-up, where an arrow lands. Caught, when it is caught, by Phase 4's human and by the customer's review of `brd-figures.md`.
- **§8's existing-slice population.** Unknown; the remedy is cheap either way.

## 14. Amendment — the shared link walk

Approved in brainstorming 2026-09-18, after the operator's note that *"idea and BRD may also link other markdowns, and they should also be a part of the BRD / idea"*. Where this section and an earlier one disagree, this section governs.

### 14.1 What prompted it

- **`/brd-intake` recognises no `[[wikilink]]` — a shipped defect.** Phase 2's link forms are the inline link or image, the reference-style definition and the HTML `<img src>`; `[[` occurs in neither `commands/brd-intake.md` nor `references/brd-format.md`. A wikilink is therefore not copied, not read and **not logged**, which breaks Phase 2's own rule that *"every link not copied is named, never dropped in silence"*. It is the likeliest shape to meet: Obsidian writes a pasted image as `![[Pasted image ….png]]` and saves it to the vault's attachment folder, usually outside the note's own folder — so an operator who converts a Word BRD in Obsidian produces a BRD whose every screenshot the route loses silently.
- **`idea-reader` recognises wikilinks but never states how `[[name]]` resolves** — a bare name carries no path, so two runs can resolve it differently. Its *"Total files read — 12"* label also reads as counting images, where line 164 calls it *"the twelve-file text budget"* with the six-image budget *"beside it"*.
- **The operator chose three widenings**: capture BRD files linked from outside the document's folder; lift `/idea`'s 12-file / 2-level cap; lift its 6-image cap.

| # | Decision | Why |
|---|---|---|
| D10 | **One link walk, defined once**, in a new `product-workflows:linked-sources` reference both commands cite | `/brd-intake` Phase 2 defines the link forms today and `idea-reader` restates them *"unchanged and restated in full here"* — two copies of one rule, which is how copies drift |
| D11 | **A wikilink resolves relative to its file, then by filename across the vault; an ambiguous match is reported, never guessed** | Obsidian's own resolution, bounded by `CLAUDE.md`'s rule to resolve against a known set and never guess |
| D12 | **The bound is the operator's consent over an enumerated list, asked only where an old bound would have cut** | A walk with no bound reaches a whole vault the moment one note links a hub; a numeric cap is what the operator asked to remove. A run inside the old bounds sees no new prompt |
| D13 | **BRD files from outside the folder go to `brd/source-external/`**, by basename with `/idea`'s `_NN` collision rule, mapped in `brd-link-log.md` | Keeps `brd-format` §1.1's definition of `brd/source/` true; cannot collide with a folder the customer's tree contains; never writes the operator's absolute path — their home directory — into the specs repo |
| D14 | **One figure reader for both commands, `figure-reader`**, still `model: opus` | One job, one agent. Its rule generalises from "never reads the BRD" to "never reads the document that links the image" |
| D15 | **`idea-reader` stays on its caller-routed Sonnet tier** | Unlike a BRD extraction, everything it returns passes through a grill with the operator before `idea.md` states any of it, so a miss is not silent there |

### 14.2 `product-workflows:linked-sources` (new reference)

The one authority for how a document's links are found, resolved and walked. `/brd-intake` Phase 1–2 and `/idea` Phase 1.5 execute it; `idea-reader` and `brd-reader` cite it and restate nothing.

- **Link forms** — the three `/brd-intake` Phase 2 fixes today (the inline image or link, the reference-style definition, the HTML `<img src>`), plus the `[[wikilink]]`: bare, aliased (`[[notes|see this]]`) and embedded (`![[shot.png]]`) — four in all.
- **Target normalisation** — drop `#fragment` and `?query`, percent-decode; for a wikilink, drop the alias half and any `#heading` or `^block` suffix. A target empty after that is an in-document jump: neither followed nor logged.
- **Resolution, in order:** a target carrying a URI scheme is a `url` and is not followed. Otherwise resolve it against the directory of the file the link sits in, normalised as text with `..` collapsed and symlinks never resolved; an absolute path resolves as itself. A wikilink that resolved to nothing — trying `<name>.md` where the name carries no extension — is looked up in the **vault**, the nearest ancestor of the **starting document** holding `.obsidian/`: a name carrying a `/` resolves against the vault root, a bare name by filename anywhere under it. **Exactly one match resolves; several are `ambiguous`**, reported with every candidate and never chosen between; none is `unreadable`. With no vault, the vault step is skipped.
- **The walk** — breadth-first, in document order within each file; a visited set of resolved absolute paths, the starting document first; transitive through every markdown file reached, inside the starting folder or out of it; each reached file sorted into **markdown** (`.md`, `.markdown`), **image** (`workflows-core:grounding-format` §6.2 step 1's extensions) or **other**. Every reached target records the target as written, the file it sits in, its resolved path, its kind, its depth, and whether it lies **inside** the starting document's own directory. It terminates on any tree, cycles included, because a file is visited once.
- **Read-only and first.** The walk reads markdown to find links and nothing else; it copies nothing, dispatches nothing, and runs before any agent is handed a file — which is what lets an operator decline for free.
- **Not-taken reasons**, shared: `url`, `unreadable`, `ambiguous`, and `excluded` (the operator's consent answer left it out).

### 14.3 `/brd-intake` under the amendment

- **Phase 1** runs the walk. Where it reached anything outside the document's folder, it names every such file and asks, **before** the §3 gate on *other* files, which it precedes because it decides the set that gate is asked over:

  ```
  choices: ["Capture all <n> (Recommended)", "Only the document's own folder — log the rest, as today", "Stop"]
  ```

  *Only the document's own folder* reproduces today's behaviour exactly, each outside target logged with the reason it carries today (`outside the source directory`, `absolute path`). *Stop* writes nothing.
- **Phase 2** copies inside files as today and outside files into `<BRD-dir>/brd/source-external/<basename>`, with `/idea`'s collision rule (`_NN` on the original basename, byte-identical content reused). `brd-link-log.md` gains a table, *Captured from outside the document's folder*: the target as written, the file it sits in, and the copy's path. `ambiguous` joins the log's reasons.
- **`brd-format` §1.1** defines `brd/source-external/`: the customer's material the document linked from outside its own directory, immutable exactly as `brd/source/` is, written only by `/brd-intake` Phase 2, and resolved **only through the link log's mapping** — a link in the verbatim document that points outside does not resolve on disk from the copy, and nothing rewrites it.
- **Every path in `brd/brd-figures.md` and in §7's two new anchor forms is relative to `brd/`** — `source/appendix/fields.md`, `source-external/glossary.md`, `source/images/report.png` — superseding the `brd/source/`-relative examples in §5 and §7, so one form names a file under either directory.
- **§2.1's one-hop resolution** covers `source-external/` exactly as it covers `source/`.
- **Phase 7's `deliverable_paths`** names each file copied into `source-external/` individually.
- **The bundle** — an outside image the verbatim document references cannot resolve from the bundle's copy either; `bundle-packaging`'s existing *fix it beside the file, never inside it* rule is what carries it, and the plan confirms that rule reaches a file resolved through the mapping.

### 14.4 `figure-reader`

The §4 agent under its shared name. **Inputs change**: `figures` carries absolute paths, ≤10, and there is no `source_dir` — `/idea` reads images where they stand, before anything is vendored, and the caller's list is the whole of what the agent may open, exactly as `frame-describer`'s `frames` list is. `outside_source` is dropped from the `read: false` reasons; `missing`, `not_an_image` and `unreadable` remain. Everything else in §4 stands, including `model: opus` for both callers.

### 14.5 `/idea` under the amendment

- **Phase 1.5 (new) — Walk the links.** For a markdown source only (a prompt has no links), run §14.2's walk from the source. Where it reached past what the old bounds allowed — deeper than 2 levels, more than 12 markdown files counting the source, or more than 6 images — name what lies past them and ask:

  ```
  choices: ["Read all <n> (Recommended)", "Only what the source links directly", "Stop"]
  ```

  *Only what the source links directly* takes depth 1 — the source's own links, markdown and images — and marks the rest `excluded`. Inside the old bounds the phase is silent.
- **Phase 2** dispatches `figure-reader` over the taken images (≤10 per dispatch, ≤4 concurrent, in waves) and then `idea-reader`, handing it the taken markdown pages and the transcriptions explicitly. `idea-reader` **discovers nothing**: its traversal, its `## Bounding` section and its `cap` and `depth` reasons are removed; its link-form list is replaced by a citation of `linked-sources`; it reads every page it is handed and treats a transcription as it treats a linked page. Its digest keeps its field names — `wikilinks_followed` is the taken markdown, `wikilinks_not_followed` the `excluded`, `wikilinks_broken` the `unreadable` and `ambiguous`, `links_other` the *other* kind — and `images[].description` becomes `figure-reader`'s `depicts`, the 60-word rule with it.
- **Phase 4.5**'s copy set is everything the walk took, `excluded` aside; `idea-format`'s *"inherits `idea-reader`'s caps — 12 files in total, 6 images"* is rewritten. The frame-set index row for an image is its `depicts` sentence; `/idea` writes no figures file — its images are grill context, and the grill confirms what the brief states.

### 14.6 Surfaces, counts and verification the amendment adds

| Surface | Change |
|---|---|
| `product-workflows/references/linked-sources.md` | new (§14.2) |
| `product-workflows/agents/figure-reader.md` | the §4 agent under its shared name, with §14.4's inputs |
| `product-workflows/commands/brd-intake.md` | Phase 1's walk and consent; Phase 2's link forms replaced by a citation; `source-external/`; the link log's mapping table and `ambiguous` reason; Phase 7 |
| `product-workflows/references/brd-format.md` | §1.1 `source-external/`; §2 and §5 paths relative to `brd/` |
| `product-workflows/commands/idea.md` | frontmatter description; Phase 1.5 (new); Phase 2 (lines ~100–148); Phase 4.5 (line ~281) |
| `product-workflows/agents/idea-reader.md` | inputs; link forms → citation; traversal and `## Bounding` removed; output; hard rules (lines ~246–247); description |
| `product-workflows/references/idea-format.md` | the copy-set sentence (line ~189) |
| `product-workflows/docs/commands/idea.md` | lines ~45, 47, 76, 164 — the depth, the cap and the "only what was read" claims |
| `product-workflows/docs/reference/agents.md` | `idea-reader`'s row; `figure-reader`'s row |
| `product-workflows/docs/reference/references.md` | `linked-sources`'s row |
| `product-workflows/references/bundle-packaging.md` | §14.3's outside-image interaction, if the plan finds the existing rule does not reach it |

**Counts:** `product-workflows` goes to **fourteen agents** and **twelve reference files**; every counted sentence moves, `CLAUDE.md`'s *"eleven reference files"* and *"their eleven references"* among them. **Sweep strings** beyond §9's: `12 files`, `twelve`, `6 images`, `six images`, `two levels`, `Total files read`, `reason: cap`, `reason: depth`, `restated in full here`, `outside the source directory`.

**Verification additions** to §11's fixture: a `.obsidian/` at the fixture root and a vault attachment folder outside the BRD's folder holding a `![[Pasted image ….png]]` target — captured under *Capture all* into `source-external/` with its mapping row, logged under *own folder only*; two notes sharing one name, linked bare — reported `ambiguous` with both candidates, neither chosen; a hub note linking a dozen more — the Phase 1 consent fires. An `/idea` fixture of 14 linked notes reaching depth 3 and 8 images: Phase 1.5 fires; *Read all* reads and vendors all 14 and all 8; *Only what the source links directly* reads depth 1 and reports the rest `excluded`; a fixture inside the old bounds prompts nothing.

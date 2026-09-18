# BRD figures, appendices, defect questions and the shared link walk — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/brd-intake` read every file a customer's BRD links — appendices and images — and `/idea` read every file its source links, through one shared, vault-aware link walk bounded by the operator's consent rather than by caps; and make an open requirement defect reach the customer as a question.

**Architecture:** A new `product-workflows:linked-sources` reference defines the link walk once; `/brd-intake` Phase 1 and `/idea` Phase 1.5 run it read-only before anything is copied, and ask the operator only where an old bound would have cut. A new Opus agent, `figure-reader`, transcribes images in parallel for both commands; `brd-reader` (now Opus) extracts rows from the document, its appendices and the transcriptions in one text pass, and `/brd-intake` records the transcriptions in `brd/brd-figures.md`. `/brd-interview` gains a seventh question source for open `[DEF#n]`s, always `[C]`, and `/brd-reconcile` settles them back through a structured `settles` field and a `resolved-by: [CD#n]` resolution.

**Tech Stack:** Markdown instruction files only — commands, agents, references and documentation pages of a Claude Code plugin marketplace. No code, no runtime. The nine CI gates are the test harness; a fixture dry run executes the changed prose.

**Spec:** `docs/superpowers/specs/2026-09-18-brd-figures-and-appendices-design.md` — read §14 first: where it and an earlier section disagree, §14 governs.

## Global Constraints

- **Every requirement ID is the bracketed `[PREFIX#N]` form**, never dash-separated. `./scripts/check-id-grammar.sh --root .` must pass after every task.
- **Match the wrap of the file you are editing.** `commands/`, `agents/` and `references/` are hard-wrapped at ~100 columns; `docs/` pages mostly are not — wrap each new paragraph exactly as its neighbours are wrapped.
- **Never restate a rule another file owns — cite it.** The link forms, resolution and walk live in `references/linked-sources.md` and nowhere else after Task 1; the `brd/brd-figures.md` format lives in `references/brd-format.md` §1.2 and nowhere else after Task 3.
- **`brd-` names the route, not the folder kind.** `/brd-interview`, `/brd-package` and `/brd-reconcile` refuse a root; every rule written for them describes a **slice** run, whose `brd/source/`, `brd/source-external/`, `brd/brd-figures.md`, `brd/brd-link-log.md` and `brd/brd-defect-log.md` are the **parent's**, one hop (`references/brd-format.md` §2.1).
- **Nothing under `brd/source/` or `brd/source-external/` is ever written after `/brd-intake` Phase 2**, and no link in the customer's document is ever rewritten.
- **Model tiers are fixed:** `figure-reader` and `brd-reader` carry `model: opus` in frontmatter; `idea-reader` stays unpinned (caller-routed, Sonnet). Spec D5, D15.
- **Resolve an identifier against a known set; never parse one out of prose** (`CLAUDE.md`). `settles` is copied from the held question's record, never inferred from the customer's answer.
- **Plugin `description` hard cap 1024 characters, warning above 900.** `validate-catalog.py .` reports `0 error(s), 0 warning(s)` today; it must still do so after Task 10. A capability change **replaces** wording, never appends. `.claude-plugin/marketplace.json` is edited in place and never reformatted.
- **`workflows-core` is edited in exactly one file**, `references/grounding-format.md` (Task 10 Step 1), because §6.1 names `idea-reader` as the agent reading an idea source's images and Task 9 moves that to `figure-reader`; `workflows-core` is bumped to **1.7.1**. No other `workflows-core` file changes.
- **Sweeps follow `CLAUDE.md`'s seventh refinement:** each string you change is counted **wrap-insensitively** (collapse whitespace in file and pattern, match, map back to a line) across `plugins/`, the repo-root `README.md` and `CLAUDE.md`, **changelogs included**, immediately before and after your edit; the after-count must equal the number you intended. A line-based `grep -c` under-counts a hard-wrapped phrase and is not a sweep.
- **Commit trailer on every commit:**
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
  ```
- **Run `git branch --show-current` immediately before every commit; it must print `iv-gu/brd-figures`.** Stage explicit paths only — never `git add -A` or `git add .`. Nothing is pushed; no pull request is opened.
- **Implementers dispatch no subagents.** Task 11 is run by the controller, not by an implementer, because it must dispatch the agents it exercises.
- **Reading this plan:** a `<body…>` line in a commit step is the commit body you write — three to five lines of prose on what changed and why — not a placeholder in shipped content. Where a quoted old or new string contains `\``, the backslash only escapes a literal backtick inside an inline-code span; the file itself carries no backslash.

**The nine gates**, run from the worktree root as **one `&&` chain**, the chain's own status printed on the next line and read from that line — never from the wrapping invocation's exit code (`CLAUDE.md`, *Run the gates as one `&&` chain*). The mermaid gate needs its pinned dependencies installed once per checkout: `npm ci --prefix scripts/mermaid --ignore-scripts --no-audit --no-fund`.

```bash
( python3 scripts/validate-catalog.py --selftest && python3 scripts/validate-catalog.py . && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . && node scripts/mermaid/check-mermaid.mjs --selftest && node scripts/mermaid/check-mermaid.mjs --root . && python3 plugins/workflows-core/scripts/session-cost.py --selftest ) > /tmp/claude-1000/-home-ihudak-dev-ai-tools-ihudak-claude-plugins/eca918d8-f7c1-43c4-b7da-5479c07b5d88/scratchpad/gates.log 2>&1
echo "GATES_EXIT=$?"; grep -c '^ok' /tmp/claude-1000/-home-ihudak-dev-ai-tools-ihudak-claude-plugins/eca918d8-f7c1-43c4-b7da-5479c07b5d88/scratchpad/gates.log; grep -c 'SELFTEST PASS' /tmp/claude-1000/-home-ihudak-dev-ai-tools-ihudak-claude-plugins/eca918d8-f7c1-43c4-b7da-5479c07b5d88/scratchpad/gates.log
```

**Green baseline at the plan's base commit:** `GATES_EXIT=0`, **198** `ok` lines, **5** `SELFTEST PASS`. No task changes a selftest, so the two counts stay 198 and 5 on every green run.

---

## File Structure

| File | Task | Responsibility |
|---|---|---|
| `plugins/product-workflows/references/linked-sources.md` | 1 (create) | The one authority for link forms, resolution (vault-aware wikilinks), the walk, its record, and taking a subset |
| `plugins/product-workflows/agents/figure-reader.md` | 2 (create) | Transcribes images verbatim; reads nothing else; Opus |
| `plugins/product-workflows/references/brd-format.md` | 3 | `brd/source-external/`, the `brd/brd-figures.md` format (§1.2), three anchor forms, three coverage relations, image rules in §3, `resolved-by: [CD#n]` in §4 |
| `plugins/product-workflows/agents/brd-reader.md` | 4 (rewrite) | Extracts rows from document + appendices + transcriptions; Opus |
| `plugins/product-workflows/commands/brd-intake.md` | 5, 6 | Phase 1 walk and consent; Phase 2 capture; Phase 2.5 figures; Phase 3 extraction and coverage; Phases 4, 5, 7, 9, report |
| `plugins/product-workflows/references/interview-tagging.md` | 7 | §1: a defect-raised question is `[C]` |
| `plugins/product-workflows/commands/brd-interview.md` | 7 | Seventh question source; round-record account line; change test; re-open cause |
| `plugins/product-workflows/references/decision-register-format.md` | 7 | `settles`, the thirteenth field |
| `plugins/product-workflows/commands/brd-reconcile.md` | 7 | Writes `settles`; third resolution |
| `plugins/product-workflows/references/bundle-packaging.md` | 8 | `brd-figures.md` ships; external images; two relation-1 fields |
| `plugins/product-workflows/references/customer-review-schema.md` | 8 | Section 4 row covers the transcriptions |
| `plugins/product-workflows/commands/brd-package.md` | 8 | Resolves `brd-figures.md` one hop |
| `plugins/product-workflows/commands/idea.md` | 9 | Phase 1.5 walk and consent; Phase 2 dispatches; Phase 4.5 and report |
| `plugins/product-workflows/agents/idea-reader.md` | 9 | Reads what it is handed; maps the walk onto its digest arrays |
| `plugins/product-workflows/references/idea-format.md` | 9 | Copy-set rule without caps |
| `plugins/workflows-core/references/grounding-format.md` | 10 | §6.1 and §6.2 name `figure-reader` where they named `idea-reader`'s image reading |
| `plugins/product-workflows/docs/**`, `README.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, the four plugins' `CHANGELOG.md`, repo `CLAUDE.md` | 1, 2, 4–10 | Inventory rows, counts, pages, release, and dating what today's push published |

## Shared contracts — the names every task uses

A task's implementer sees only their own task. These are the exact names and shapes neighbouring tasks rely on; copy them, never re-derive them.

**`linked-sources.md` section map** (Task 1 produces; Tasks 5, 6, 9 cite by these numbers): §1 The link forms · §2 Normalising a target · §3 Resolving a target · §4 The walk · §5 The walk record · §6 Not-taken reasons · §7 Taking a subset.

**The walk record** (one entry per link found, `linked-sources.md` §5):

```yaml
- target:     <the link target exactly as written, alias half dropped>
  from:       <absolute path of the file the link sits in>
  path:       <resolved absolute path — absent when reason is set>
  kind:       markdown | image | other     # absent when reason is set
  depth:      <1 for the starting document's own links, 2 for theirs, …>
  inside:     true | false                 # resolved path lies within the starting document's own directory; absent when reason is set
  reason:     url | unreadable | ambiguous # present iff the target resolved to no single file
  candidates: [<absolute path>, …]         # present iff reason: ambiguous
```

Callers add one field after consent: `taken: true | false`, with `reason: excluded` on an entry the operator's answer left out (`linked-sources.md` §6, §7).

**`figure-reader` I/O** (Task 2 produces; Tasks 6, 9 dispatch):

```yaml
# input
figures:                           # 1–10 absolute paths, in the order to read them
  - <absolute path>
# output
status: OK | INPUT_MISSING
figures:
  - path: <absolute path, exactly as received>
    read: true | false
    reason: missing | not_an_image | unreadable      # iff read: false
    appearance: screenshot | wireframe | document | diagram | photo | other
    depicts: <one sentence>
    text: |
      <verbatim, region by region, in reading order>
    annotations:
      - says: "<verbatim; empty string for an unlabelled mark>"
        points_at: <the element the mark sits on or points to>
    flow:
      - "<node> → <node> [<edge label>]"             # diagrams only; [] otherwise
    illegible: <what could not be read, or "none">
notes: <string, may be empty>
```

**Consent arrays, verbatim** (Tasks 5, 9):

- `/brd-intake` outside-folder: `["Capture all <n> (Recommended)", "Only the document's own folder — log the rest, as today", "Stop"]`
- `/brd-intake` other-file: `["Stop and convert them first — nothing has been written (Recommended)", "Proceed — none of them carries an obligation (recorded)", "Use a different key or path (you'll be prompted)"]`
- `/idea` past-the-old-bounds: `["Read all <n> (Recommended)", "Only what the source links directly", "Stop"]`

**Paths in the BRD's new artifacts are relative to `brd/`**: `source/appendix/fields.md`, `source-external/glossary.md`, `source/images/report.png`.

**The three `source_anchor` forms** (Task 3 defines; Tasks 4, 6 use): document — a heading path or line range, as today; appendix — `<path relative to brd/> › <heading path or line range>`; image — `<path relative to brd/> › "<element quoted verbatim from the transcription>"` or `<path relative to brd/> › annotation <n>`.

**`brd-reader` output additions** (Task 4 produces; Task 6 consumes): `figures: [{path: <relative to brd/>, illustrates: [BR#n, …], note: <optional>}]` — one entry per read image.

**`brd/brd-link-log.md` additions** (Task 5): reason `ambiguous`; a second table titled exactly *Captured links that do not resolve as written*, columns `Target as written | Linked from | Copy`.

**`settles`** (Task 7): `settles: [[DEF#4]]` on a `[CD#n]` only; omitted when absent.

**Stop id** (Task 5): `BRD_INTAKE_UNREAD_ATTACHMENTS`.

---

### Task 1: `linked-sources` — the one link walk

**Files:**
- Create: `plugins/product-workflows/references/linked-sources.md`
- Modify: `plugins/product-workflows/docs/reference/references.md` (lines 3, 33, and a new section)
- Modify: `plugins/product-workflows/README.md:20` (the reference count only — Task 2 changes the agent count in the same sentence)

**Interfaces:**
- Consumes: nothing.
- Produces: the section map and walk record in *Shared contracts*. Tasks 5, 6 and 9 cite `${CLAUDE_PLUGIN_ROOT}/references/linked-sources.md` §N by those numbers.

- [ ] **Step 1: Write the failing test — create the reference and watch the inventory gates go red**

Create `plugins/product-workflows/references/linked-sources.md` with exactly this content:

````markdown
# Linked sources (embedded authority)

How a markdown document's links are found, resolved and walked, stated once. **`/brd-intake` Phase 1
runs the walk** from a customer's BRD, and **`/idea` Phase 1.5 runs it** from an idea source; each
decides afterwards, with the operator, which of the files it reached to take (§7). `brd-reader`,
`idea-reader` and `figure-reader` read what their caller hands them and walk nothing.

Before this file existed `/brd-intake` Phase 2 defined the link forms and `idea-reader` restated them
in full, which is two copies of one rule — and they had already drifted: the command did not
recognise a `[[wikilink]]` at all, and the agent recognised one but never said how a bare name
resolves. Design authority: `docs/superpowers/specs/2026-09-18-brd-figures-and-appendices-design.md`
§14.

## 1. The link forms

Four forms, and a markdown document uses all of them:

- a `[[wikilink]]` — bare (`[[notes]]`), aliased (`[[notes|see this]]`), or embedded (`![[shot.png]]`);
- a markdown inline image or link — `![alt](<target>)` and `[text](<target>)`, angle-bracketed
  (`[text](<my file.png>)`) or not, with any title after the target ignored;
- a reference-style definition — `[label]: <target>`, wherever in the document the definition sits;
- an HTML `<img src="<target>">`.

The embedded wikilink is the form a converted BRD most often carries: Obsidian writes a pasted image
as `![[Pasted image ….png]]` and saves the file to the vault's attachment folder, usually outside the
note's own directory.

**The form says only that something is a link; the extension of what it resolves to decides its
kind** (§4). An image embedded as `<img src>` is an image exactly as `![alt](…)` is, and a page
reached only through a reference-style definition is a page exactly as one reached by `[text](…)` is.

## 2. Normalising a target

Drop any `#fragment` and `?query`, then percent-decode. For a wikilink, also drop the alias half
(`|…`) and any `#heading` or `^block` suffix. **A target empty after that is an in-document jump** —
`[[#Scope]]`, `[see below](#scope)` — and is neither followed nor recorded.

The record keeps the target **as written** (§5), alias half aside: normalising is how a target is
resolved, never how it is reported, because every caller that maps a link back to its copy compares
written forms.

## 3. Resolving a target

In this order, stopping at the first that applies:

1. **A target carrying a URI scheme** (`https:`, `http:`, `mailto:`, `data:`, …) is a `url`. It is
   recorded and never followed, fetched or read.
2. **Resolve it against the directory of the file the link sits in**, normalised **as text** — `..`
   segments collapsed, symlinks never resolved. An absolute path resolves as itself. Where it names a
   readable existing file, that is the target.
3. **A wikilink that step 2 did not resolve is looked up in the vault.** Where the name carries no
   extension, try it with `.md` too, as Obsidian does. The **vault** is the nearest ancestor of the
   **starting document** — the one the walk began from, not the file this link sits in — that holds a
   `.obsidian/` directory. A name carrying a `/` resolves against the vault root; a bare name is matched
   by filename anywhere under it.
   - **Exactly one match** — that is the target.
   - **More than one** — the target is `ambiguous`. Record every candidate and **choose none**: two
     notes sharing a name are two different files, and a walk that picked one would report a file the
     author may never have meant as though they had linked it.
   - **None** — the target is `unreadable`.

   Where no ancestor holds `.obsidian/`, there is no vault and this step is skipped: the target is
   `unreadable`.
4. **Anything else step 2 did not resolve** is `unreadable` — a path naming no file, or naming one
   that cannot be read.

## 4. The walk

**Breadth-first, in document order within each file**: the starting document's links in the order
they appear, then each linked markdown file's links the same way, and so on. The order is
deterministic, so two walks over one tree reach the same files in the same order.

**Transitive through every markdown file reached**, inside the starting document's own directory or
outside it. **A visited set** of resolved absolute paths, the starting document first, makes every
file visited once — a cycle is a silent skip, not an error — so the walk terminates on any tree.

**Every resolved file has a kind**, read off its extension, case-insensitively: **markdown**
(`.md`, `.markdown`), **image** (`workflows-core:grounding-format` §6.2 step 1's set: `.png`, `.jpg`,
`.jpeg`, `.gif`, `.svg`, `.webp`), or **other** — anything else. Only a markdown file is opened, and
only to find its links.

**Read-only, and first.** The walk copies nothing, writes nothing, dispatches nothing and reads no
image or *other* file. It runs before a caller copies or hands anything to an agent, which is what
lets an operator decline for free.

## 5. The walk record

One entry per link found, including a second link to a file already visited (the record is of links;
the visited set is of files):

```yaml
- target:     <the link target exactly as written, alias half dropped>
  from:       <absolute path of the file the link sits in>
  path:       <resolved absolute path — absent when reason is set>
  kind:       markdown | image | other     # absent when reason is set
  depth:      <1 for the starting document's own links, 2 for theirs, …>
  inside:     true | false                 # resolved path lies within the starting document's own directory; absent when reason is set
  reason:     url | unreadable | ambiguous # present iff the target resolved to no single file
  candidates: [<absolute path>, …]         # present iff reason: ambiguous
```

`depth` is the depth at which the file was **first** reached. `inside` compares the resolved `path`
with the starting document's own directory by normalised text, exactly as step 2 of §3 resolves.

## 6. Not-taken reasons

The shared vocabulary for a link whose file is not taken — by the walk, or by the caller after the
operator's answer:

| Reason | Set by | Fires when |
|---|---|---|
| `url` | the walk | the target carries a URI scheme (§3 step 1) |
| `unreadable` | the walk | the target resolved to no readable file (§3 steps 3–4) |
| `ambiguous` | the walk | a wikilink matched more than one file in the vault (§3 step 3); every candidate is recorded |
| `excluded` | the caller | the operator's consent answer left the file out (§7) |

A caller may keep reasons of its own beside these — `/brd-intake`'s link log keeps
`outside the source directory` and `absolute path` for the answer that reproduces its earlier
behaviour — but never redefines one of these four.

## 7. Taking a subset

A caller asks the operator, where it asks at all, which of the reached files to take. **Whatever
subset the answer names, a file is taken only where a chain of taken markdown files reaches it from
the starting document.** A file reached only *through* a file the answer left out is left out too,
with reason `excluded`, even where it would otherwise qualify: its link exists only inside something
nobody is going to read. Callers add `taken: true | false` to each entry; the walk itself takes
nothing.

**This file never decides when to ask.** Each caller states its own trigger and its own choice array,
because the bound it replaces is its own: `/brd-intake`'s was its source document's directory, and
`/idea`'s was a count and a depth.
````

- [ ] **Step 2: Run the gates and verify the inventory checks fail**

Run the nine-gate chain. Expected: `GATES_EXIT=1`, with `check-docs.sh --root .` reporting the new file as missing from `docs/reference/references.md` (check 5) and the count sentence `11 files` disagreeing with the 12 on disk (check 9). If it passes, the gate did not see the file — stop and investigate before going on.

- [ ] **Step 3: Add the references-page section and fix both counts**

In `plugins/product-workflows/docs/reference/references.md`:
- line 3: `bundles 11 files under` → `bundles 12 files under`
- line 33: `Every one of the 11 files above` → `Every one of the 12 files above`
- insert, immediately before the line `## PRD-ladder formats`:

```markdown
## Shared by both routes

The one rule the BRD route and the idea ladder both execute.

- `linked-sources.md` — how a markdown document's links are found, resolved and walked, once for `/brd-intake` and `/idea`: the four link forms (the `[[wikilink]]` among them), the vault-aware resolution that reports an ambiguous wikilink rather than guessing between two files, the read-only breadth-first walk and the record it produces, and the rule that a file is taken only where a chain of taken markdown reaches it.

```

In `plugins/product-workflows/README.md` line 20, change `Eleven reference pages (see [References](docs/reference/references.md)) define the BRD, code-defect-log, decision-register, coverage-ledger, customer-review, idea, ARD, specification and effort-proposal artifact formats.` to `Twelve reference pages (see [References](docs/reference/references.md)) define the BRD, code-defect-log, decision-register, coverage-ledger, customer-review, idea, ARD, specification and effort-proposal artifact formats, and the link walk `/brd-intake` and `/idea` share.`

- [ ] **Step 4: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5.

- [ ] **Step 5: Mutation control**

Delete the new `- \`linked-sources.md\`` bullet from `references.md`, run `./scripts/check-docs.sh --root .`, and confirm it fails naming check 5. Restore the bullet (`git diff` must show it back exactly), and rerun the full chain green.

- [ ] **Step 6: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/references/linked-sources.md plugins/product-workflows/docs/reference/references.md plugins/product-workflows/README.md
git commit -m "feat(product-workflows): linked-sources — one link walk for /brd-intake and /idea

<body: what the reference fixes, the vault rule, the subset rule>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

Write the body as three to five lines of prose in place of the `<body: …>` line; it is a commit message, not a placeholder in shipped content.

---

### Task 2: `figure-reader` — transcribe, never judge

**Files:**
- Create: `plugins/product-workflows/agents/figure-reader.md`
- Modify: `plugins/product-workflows/docs/reference/agents.md` (lines 3, 39, the *Readers and scanners* table)
- Modify: `plugins/product-workflows/README.md:20` (the agent count)

**Interfaces:**
- Consumes: nothing.
- Produces: `product-workflows:figure-reader` with the I/O in *Shared contracts*. Task 6 (`/brd-intake` Phase 2.5) and Task 9 (`/idea` Phase 2) dispatch it.

- [ ] **Step 1: Create the agent file**

Create `plugins/product-workflows/agents/figure-reader.md` with exactly this content:

````markdown
---
name: figure-reader
description: Transcribes the images a customer's BRD or an idea source links — every legible label, header, field, legend and annotation verbatim, what each annotation points at, and a diagram's flow — plus one sentence on what each image depicts. Reads only the images it is handed and never the document that links them, so a transcription cannot be bent toward the prose. Produces no requirement, candidate or judgement. Read-only. Uses Claude Opus — a misread label or a missed annotation yields no candidate for any human to catch.
model: opus
tools: ["Read"]
---

State exactly what is written and drawn in each image you are handed. Never what it obliges.

Your callers are `/brd-intake` Phase 2.5, which records what you return in `brd/brd-figures.md`
(`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §1.2) for `brd-reader` to extract requirements
from, and `/idea` Phase 2, which hands what you return to `idea-reader` as grill context. Neither
shows you the document that links the image, and you must not go looking for it.

**You never read the document that links an image.** That is what makes a transcription independent
of the prose: where a customer's mockup shows a field their text never mentions, or a sample report
whose column contradicts their text, the difference survives to the agent that compares them —
instead of being smoothed over here, one step earlier, by a transcription that read what it expected.

**Distinctions**, because three agents in this family look at pictures. `frame-describer` writes one
to three sentences for a frame-set index. `idea-reader` returns a digest of an idea source. **This
agent transcribes, in full, what someone wrote and drew**, and returns nothing else.

## Inputs

```yaml
figures:                           # 1–10 absolute paths, in the order to read them
  - <absolute path>
```

**Refuse to run with no `figures` or with an empty list** — return `status: INPUT_MISSING`, naming
what was absent. **The list is the whole of what you may open.** Never enumerate a directory, never
follow a path you find inside an image or beside it, and never read a file that is not on the list.

## Process

For each entry, in order:

1. **Read the image.** Where it resolves to nothing, return it `read: false`, `reason: missing`; where
   the file is not an image despite its extension, `not_an_image`; where it will not open or is too
   large to read, `unreadable`. An `.svg` arrives as text: its `<text>` elements are what you
   transcribe, and its drawing is what you describe.
2. **`appearance`** — what the image looks like, and only that: `screenshot`, `wireframe`, `document`,
   `diagram`, `photo`, or `other`. **Never classify its purpose.** You cannot reliably tell a
   screenshot of today's product from a polished mockup of tomorrow's, and the caller's extractor
   decides that from the prose around the link.
3. **`depicts`** — one sentence: the screen, report, form, dialog or flow, and any state it is plainly
   in (empty, error, filtered, a selected row).
4. **`text`** — every legible string, **verbatim**, region by region in reading order: titles, labels,
   column headers, field names, button captions, legends, footnotes. **For repeated data rows**,
   transcribe the header, one representative row, and a line saying how many rows are shown — the
   values of a sample report are rarely the obligation and would bury the ones that are.
5. **`annotations`** — every mark someone added on top of the picture: an arrow, a box, a highlight,
   a circled region, a typed or handwritten note. For each, `says` is its text verbatim (the empty
   string for an unlabelled mark) and `points_at` is the element it sits on or points to, named as
   the image labels it — *"the `Net total` column header"*, never *"the total"*.
6. **`flow`** — for a diagram, each edge as `<node> → <node>`, with the edge's label in brackets where
   it carries one. `[]` for anything that is not a diagram.
7. **`illegible`** — everything you could not read, named by where it is. `"none"` only when nothing
   was illegible. A partial transcription is never silent.

## Output

Return exactly this YAML (no preamble):

```yaml
status: OK | INPUT_MISSING
figures:
  - path: <absolute path, exactly as received>
    read: true | false
    reason: missing | not_an_image | unreadable      # iff read: false
    appearance: screenshot | wireframe | document | diagram | photo | other
    depicts: <one sentence>
    text: |
      <verbatim, region by region, in reading order>
    annotations:
      - says: "<verbatim; empty string for an unlabelled mark>"
        points_at: <the element the mark sits on or points to>
    flow:
      - "<node> → <node> [<edge label>]"
    illegible: <what could not be read, or "none">
notes: <anything the caller should know — an image that is plainly several unrelated screens, a
        resolution too low for small text — or empty>
```

Return every entry you were handed, once, in the order received — a dropped entry becomes an image
nobody transcribed and nobody was told about. An entry with `read: false` carries `path`, `read` and
`reason` and nothing else.

## Hard rules

- NEVER read the document that links an image, any other markdown, or any file not on the list.
- NEVER infer anything from a filename or a path. A file you could not read has no transcription.
- NEVER translate, correct, complete or tidy a string. Typos stay; a truncated label stays truncated
  and is named in `illegible`.
- NEVER emit an identifier, a requirement, a defect candidate, a verdict or a judgement. *Must*,
  *required*, *missing*, *wrong* and *should* are not your words — an annotation that says *"this total
  is wrong"* is transcribed as `says: "this total is wrong"` and nothing more.
- NEVER edit, create or delete a file.
````

- [ ] **Step 2: Run the gates and verify the agent inventory fails**

Expected: `GATES_EXIT=1` — check 5 reports `figure-reader` missing from `docs/reference/agents.md`, and check 9 the count 13 against 14 on disk.

- [ ] **Step 3: Add the agents-page row and fix the counts**

In `plugins/product-workflows/docs/reference/agents.md`:
- line 3: `bundles 13 reusable subagents` → `bundles 14 reusable subagents`; `Nine carry a \`model: opus\` frontmatter pin` → `Ten carry a \`model: opus\` frontmatter pin`. (Task 4 moves this to eleven and removes the Sonnet clause.)
- line 39: `Every one of the 13 agents above` → `Every one of the 14 agents above`.
- in the *Readers and scanners* table, insert immediately after the `design-grounder` row:

```markdown
| `figure-reader` | opus | Read | Transcribes the images a BRD or an idea source links — every label, header and annotation verbatim, what each annotation points at, a diagram's flow — without ever reading the document that links them; produces no requirement or judgement. | `/brd-intake`, `/idea` |
```

In `plugins/product-workflows/README.md` line 20, change `Thirteen agents` to `Fourteen agents`.

- [ ] **Step 4: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5.

- [ ] **Step 5: Mutation control**

Change the row's first cell to `` `figure-readr` ``, run `./scripts/check-docs.sh --root .`, and confirm it fails naming check 5. Restore it and rerun the chain green.

- [ ] **Step 6: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/agents/figure-reader.md plugins/product-workflows/docs/reference/agents.md plugins/product-workflows/README.md
git commit -m "feat(product-workflows): figure-reader — transcribe a linked image, never judge it

<body: independence from the prose; Opus; shared by /brd-intake and /idea>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---
### Task 3: `brd-format` — the record the new reading writes

**Files:**
- Modify: `plugins/product-workflows/references/brd-format.md` (§1.1 lines 36–64; new §1.2 before line 66; §2 line 74 and a new paragraph; §2.2 lines 87–136; §2.1 lines 172–176; §3 after line 202; §4 line 213)

**Interfaces:**
- Consumes: `linked-sources.md` §3, §4 (Task 1) by citation.
- Produces: `brd-format.md` §1.2 — the `brd/brd-figures.md` format, which Task 6 writes and Task 8 ships; the three anchor forms, which Task 4's agent emits and Task 6's coverage check resolves; the `resolved-by: [CD#n]` resolution, which Task 7 writes. **Every later task cites these by section number; do not renumber §1.1, §2, §2.1, §2.2, §3 or §4.** The new §1.2 is inserted after §1.1 and before `## 2. The inventory`.

Wrap every new paragraph at ~100 columns, as the file is wrapped. Where a step names a sentence to change, it may straddle a line break in the file: match on its content.

- [ ] **Step 1: §1.1 — what the intake reads, and where the link rules live**

(a) Replace the sentence *"`/brd-intake` Phase 2 is the only writer, and the link forms it covers and the test it applies to each target are stated there."* (lines 38–39) with:

```markdown
`/brd-intake` Phase 2 is the only writer; how a link is found and resolved is
`references/linked-sources.md`'s, and what Phase 2 copies where is stated there.
```

(b) Replace *"a file it links is captured as it stands, whatever its type, and the intake run reads only the document."* (lines 40–41) with:

```markdown
a file it links is captured as it stands, whatever its type. **The intake run reads the document, every
markdown file it links, and every image it links** (`commands/brd-intake.md` Phases 2.5 and 3); a linked
file of any other kind is captured, named to the operator before anything is copied, and not read.
```

(c) Replace the sentence *"**Whatever the copy could not capture is named in `brd/brd-link-log.md`**, never dropped in silence: a link above the source document's own directory, an absolute path, a URL, or a file that could not be read."* (lines 47–49) with:

```markdown
**Whatever the copy could not capture is named in `brd/brd-link-log.md`**, never dropped in silence:
a URL, a file that could not be read, a wikilink matching more than one file in the vault — and, where
the operator chose to capture only the document's own folder, a link above that folder or an absolute
path.
```

(d) Immediately before the paragraph beginning **"Which file under `brd/source/` is the customer's document is read, never guessed."**, insert:

```markdown
**The log also maps every captured link that does not resolve as written.** Its second table,
*Captured links that do not resolve as written*, carries one row per link whose copy cannot be reached
by reading the target as a path relative to the file it sits in — every file copied into
`brd/source-external/`, and every `[[wikilink]]`, which names a file rather than a path — with the
target as written, the file the link sits in, and the copy's path relative to `brd/`. **It is the only
way any reader resolves such a link**: nothing rewrites the verbatim document to point at its copy.

**`brd/source-external/` holds what the document links from outside its own directory**, where the
operator chose to capture it (`commands/brd-intake.md` Phase 1). Each file sits at its **basename** —
never at a path mirroring where it came from, which for an absolute link would write the operator's
own directory layout, home directory included, into the specs repository — with a `_NN` suffix on the
original basename where two collide, and byte-identical content reused rather than copied twice. It is
**immutable exactly as `brd/source/` is**, written only by `/brd-intake` Phase 2, and never removed
from; it sits beside `brd/source/` rather than inside it so that this section's first sentence stays
true — `brd/source/` holds what the document links *from its own directory* — and so that no folder
the customer's own tree happens to contain can collide with it.
```

- [ ] **Step 2: Insert §1.2 — `brd/brd-figures.md`**

Immediately before the line `## 2. The inventory`, insert:

````markdown
### 1.2 `brd/brd-figures.md` — what the plugin read in the customer's images

`/brd-intake` Phase 2.5 has `product-workflows:figure-reader` transcribe every image the document links,
and writes what it returns here. **A transcription is the plugin's reading of the customer's image, not
the customer's words** — which is why a requirement drawn from an image anchors on the *image* (§2),
never on this file, and why `/brd-intake` Phase 4's human and the customer's own review both check a
row drawn from an image against the picture. It is the plugin's record, so it sits in `brd/` beside
`brd-link-log.md` and never under `brd/source/`.

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
- **Content hash** is the SHA-256 of the image's bytes. A later intake run keeps a section whose hash
  still matches its file **verbatim** and does not read that image again; one whose hash no longer
  matches is re-read and replaced.
- **Rows** is completed by `/brd-intake` Phase 5, once the inventory is final: `yields` the rows
  anchored on this image, `illustrates` the rows whose prose the image restates, or
  `accounted for — <the operator's account>` where it does neither. **It names requirements of the BRD
  that owns this file — on a slice, the parent's, one hop (§2.1)**, which is how
  `references/bundle-packaging.md` §6.2 relation 1 reads it.
- **A section is never deleted.** An image the revised document no longer links keeps its section,
  with a line `- **No longer linked by the current source.**` under its header: an inventory row the
  re-run preserved may anchor on it.

````

- [ ] **Step 3: §2 — three anchor forms and the numbering**

(a) In the §2 table, change the `source_anchor` row's meaning cell from `a heading path or line range locating the requirement inside \`brd/source/\`` to `where the requirement is stated — in the document, an appendix, or an image, in one of the three forms below`.

(b) Immediately after the paragraph ending *"`[BR#n]` numbers are never reused and never renumbered, including across a split: once assigned, an id is permanent even if the row it names is later split, superseded, or found defective."*, insert:

```markdown
**`source_anchor` takes one of three forms**, by where the requirement is stated:

- **In the document** — a heading path or a line range inside it, as it always has.
- **In a linked markdown file** — `<path relative to brd/> › <heading path or line range>`, for
  instance `source/appendix/fields.md › Report columns` or `source-external/glossary.md › L12-L18`.
- **In an image** — `<path relative to brd/> › "<element>"`, the element a string quoted verbatim from
  the image's transcription (`source/images/report.png › "Net total" column`), or
  `<path relative to brd/> › annotation <n>`, the n-th annotation in its §1.2 section.

**Rows are numbered in reading order across all three**: the document's first, in source order; then
each linked markdown file's, in the order `/brd-intake` Phase 2 captured it; and a row drawn from an
image at the passage that links the image — its first link, where several do.
```

- [ ] **Step 4: §2.1 — one hop reaches the new files too**

Immediately after the paragraph beginning **"Every `source_anchor` in a slice's inventory resolves against that path"** (ends *"…would mint a second set of ids for text that already has them."*), insert:

```markdown
**The same one hop reaches `brd/source-external/`, `brd/brd-figures.md` and `brd/brd-link-log.md`.** A
slice holds none of them: an appendix or image anchor in its inventory resolves against the parent's
files, exactly as a document anchor resolves against the parent's `brd/source/`.
```

- [ ] **Step 5: §2.2 — three relations**

(a) Replace *"It is made visible at intake instead, and the whole of it is derivable from `source_anchor` and the source document: **nothing new is stored, and no agent returns a new field.**"* (lines 90–92) with:

```markdown
It is made visible at intake instead, and nothing is stored to do it: the sections are checked
from `source_anchor`, the document and its linked markdown, and the images from `brd/brd-figures.md`
and the `illustrates` list `brd-reader` returns beside its rows.
```

(b) Replace the line *"Two relations, both over the **top-level section**:"* with:

```markdown
Three relations — the first two over the **top-level section** of the document and of every linked
markdown file, the third over the images:
```

(c) In relation 2, change *"**Every top-level section of the source either holds a row or is accounted for.**"* to *"**Every top-level section of the document and of each linked markdown file either holds a row or is accounted for.**"*.

(d) Immediately after relation 2's paragraph (ending *"…`/brd-intake` names each with what the source has under it and asks."*), insert:

```markdown
3. **Every image yields a row, illustrates one, or is accounted for.** It *yields* a row where any
   anchor names it, and *illustrates* one where `brd-reader` returned it in that row's `illustrates`.
   An image that does neither — a logo, a decorative banner, a screenshot whose content no
   obligation bears on, or an image that could not be read — is named with its `Depicts` sentence or
   its reason, in the same question relation 2 asks.
```

(e) Immediately before the paragraph beginning **"Where no anchor in the whole inventory resolves, that is a read failure"**, insert:

```markdown
**The two new anchor forms resolve by their own rule.** A linked-markdown anchor resolves where its path
names a file `/brd-intake` Phase 2 copied and the part after `›` resolves against *that* file by the
three branches above. An image anchor resolves where its path names an image `brd/brd-figures.md`
records as read, and the quoted element appears verbatim in that image's *Text* or *Annotations* — or,
for `annotation <n>`, where the image has an n-th annotation.
```

- [ ] **Step 6: §3 — the image rules**

Immediately after the paragraph beginning *"A single `[BR#n]` may carry more than one defect"* (ends *"…to force a single-class read."*), insert:

```markdown
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
```

- [ ] **Step 7: §4 — a customer decision settles a defect too**

Replace the table row

```
| `resolved-by: [CG#n]` | a code- or design-grounding finding settled the defect (typically closing an `unsourced` entry) |
```

with

```
| `resolved-by: [CG#n]` · `resolved-by: [CD#n]` | a code- or design-grounding finding settled the defect (typically closing an `unsourced` entry), or a customer decision did — the answer to the question the defect raised (`commands/brd-interview.md`, the requirement-defect question source), frozen by `/brd-reconcile` |
```

The table keeps four rows, so every *"exactly four resolutions"* elsewhere stays true.

- [ ] **Step 8: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5. No gate reads this file's content, so green proves only that nothing else broke; Step 9 is the check.

- [ ] **Step 9: Verify by hand**

Run each, and confirm the stated count:
- the collapsed-whitespace count of `reads only the document` across `plugins/`, `README.md` and `CLAUDE.md` — this file now contributes **0** (other files are Tasks 5, 6 and 9's);
- `grep -c '^### 1.2 ' plugins/product-workflows/references/brd-format.md` → `1`, and `grep -n '^## \|^### ' …brd-format.md` shows §1, §1.1, §1.2, §2, §2.2, §2.1, §3, §4, §5 in that order (the file already places §2.2 before §2.1; leave that as it is).

- [ ] **Step 10: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/references/brd-format.md
git commit -m "feat(brd-format): figures, linked markdown and external sources in the BRD's record

<body>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

### Task 4: `brd-reader` — extract from everything the BRD links, on Opus

**Files:**
- Modify (full rewrite): `plugins/product-workflows/agents/brd-reader.md`
- Modify: `plugins/product-workflows/docs/reference/agents.md` (line 3; the `brd-reader` row)

**Interfaces:**
- Consumes: `brd-format.md` §1.2, §2's three anchor forms, §3's image rules (Task 3); the `brd/brd-figures.md` format.
- Produces: the dispatch contract Task 6 uses — inputs `source_path`, `appendices`, `figures_path`; output adds `figures[].illustrates`.

- [ ] **Step 1: Replace the file**

Replace the whole of `plugins/product-workflows/agents/brd-reader.md` with exactly:

````markdown
---
name: brd-reader
description: Extracts a requirement inventory from a customer-supplied BRD — its document, every markdown file it links, and the transcriptions of every image it links — one [BR#n] row per requirement, with a source anchor and unconfirmed defect candidates. Splits a requirement carrying more than one obligation; raises an ambiguity on an obligation only an image states, and a conflict where an image and the prose cannot both hold. Read-only; never writes the source. Uses Claude Opus — its defect candidates are judgement over a long, contradictory document, and a conflict or obligation it misses reaches no human.
model: opus
tools: ["Read", "Glob", "Grep"]
---

Read `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` for the `[BR#n]` row shape, the three
`source_anchor` forms and the numbering order (§2), the splitting rule, the six defect classes with
their one-line tests and the rules for a requirement drawn from an image (§3), and the
`brd/brd-figures.md` format (§1.2). Follow that reference; do not restate it here.

Extract a requirement inventory from one customer-supplied BRD. Read-only — this agent never modifies
anything, and never decides anything about `/brd-intake`, which owns its own phases and is the only
place a defect candidate this agent proposes can be confirmed.

## The one rule that matters most

**This agent proposes defect candidates. It does not confirm defects.** Every entry this agent
emits under `defect_candidates` is a hypothesis for a human to accept or reject — confirmation
happens interactively, inside `/brd-intake`. Nothing in this agent's output may be read as a confirmed
`[DEF#n]`: this agent assigns no `[DEF#n]` id, closes no defect, and never upgrades its own candidate to
a decision. Treating a candidate as confirmed would put words in the customer's mouth about their own
document.

**And what it misses, nobody sees.** A human confirms or rejects what is *proposed*; a conflict between
§3 and §12 that this agent never proposed, or an obligation an image states that it never extracted,
reaches no one. That is why this agent runs on Opus, and why the image rules below are not optional.

## Inputs

```yaml
source_path:  <absolute path to the customer's document under <BRD-dir>/brd/source/>
appendices:                        # every markdown file the document links, as /brd-intake Phase 2 copied them, in capture order
  - <absolute path under <BRD-dir>/brd/source/ or <BRD-dir>/brd/source-external/>
figures_path: <absolute path to <BRD-dir>/brd/brd-figures.md — omitted when the BRD links no image>
```

**Refuse to run without `source_path`.** If it, any `appendices` entry, or `figures_path` where given
is missing, not a markdown file, or does not resolve to an existing file, return `status: NOT_FOUND`
naming exactly which and why — never guess at a file, and never search for "something that looks like
a BRD". **Read exactly these files.** `Glob` confirms a given path resolves; it never discovers a file
the caller did not hand over, and a link inside a file is never followed — the caller walked the links
already (`${CLAUDE_PLUGIN_ROOT}/references/linked-sources.md`) and handed over what it took.

## Process

1. **Read everything handed over, verbatim**: the document, each appendix, and — where given — the
   figures file, whose per-image *Text*, *Annotations* and *Flow* sections are the plugin's
   transcription of each image (`brd-format.md` §1.2). Read the whole set before extracting anything:
   whether an image's content is stated elsewhere in prose is a question about the whole set.

2. **Walk the document, then each appendix, structurally** — headings, numbered items, bulleted items
   and standalone paragraphs — to find each discrete customer obligation. A heading or a list label is
   not itself a requirement; the obligation is the sentence or clause that binds the delivery team to
   something. **An appendix is the customer's prose exactly as the document is**: a field list, a
   sample-data rule, an approval matrix stated there binds as the same statement would in the document.

3. **At each passage that links an image, read that image's transcription beside it**, and apply
   `brd-format.md` §3's image rules:
   - an obligation the image states and **no prose anywhere in the set** states → a row anchored on the
     image, carrying an `ambiguity` candidate whose reason reads *"stated only in `<image path>` —
     binding force unknown"*, **unless** the linking passage makes the image binding by its own words;
   - an image-derived row that cannot hold at the same time as a prose row → a `conflict` candidate
     naming that row;
   - an image that only restates the prose → no row; return it under `figures` with the rows it
     restates in `illustrates`;
   - an image that bears on no obligation (a logo, a banner) → no row; return it under `figures` with
     an empty `illustrates` and a one-line `note`.
   **An image-derived row's `text` states the obligation in words, quoting the transcribed element
   verbatim** — every later reader (`code-grounder`, `/brd-interview`, the customer) reads the text,
   and none of them reads the picture. An image the figures file records as not read yields nothing:
   never reason from its path or filename.

4. **Emit one `[BR#n]` row per discrete obligation**, numbered contiguously from `BR#1` in the reading
   order `brd-format.md` §2 fixes — the document first, then each appendix in the order given, and an
   image-derived row at the passage that links its image:
   - `id` — `[BR#n]`.
   - `text` — the requirement verbatim, or its first sentence when quoting the whole passage would be
     unwieldy.
   - `source_anchor` — in one of `brd-format.md` §2's three forms, precise enough that a later reader
     finds the exact passage or element without this agent's help. Paths in it are relative to
     `<BRD-dir>/brd/`.

5. **Apply the splitting rule** (`brd-format.md` §2): one numbered item binding the delivery team to
   two or more separable obligations becomes one `[BR#n]` per obligation, each carrying a `duplicate`
   candidate naming the other rows the split produced.

6. **Propose defect candidates per row**, applying the six one-line tests of `brd-format.md` §3 as
   written there. A row may carry zero, one or several candidates, and more than one class at once.
   `conflict` and `duplicate` candidates always name the other `[BR#n]` involved. An annotation that
   asserts how the current system behaves (*"this total is wrong"*) is `unsourced` as well as whatever
   else it is.

7. **Never rewrite, normalise, reflow, or "clean up" any text you quote.** `text` and `source_anchor`
   quote and locate the source as it stands, typos and all.

## Output

Return this exact YAML shape (no preamble, no chatter):

```yaml
status: OK | EMPTY | NOT_FOUND
source_path: <as received>
inventory:
  - id: BR#<n>
    text: <verbatim requirement, or its first sentence; for an image-derived row, the obligation in words quoting the element>
    source_anchor: <one of brd-format.md §2's three forms>
    defect_candidates:                # UNCONFIRMED — proposals only
      - class: ambiguity | conflict | untestable | unsourced | duplicate | scope-leak
        reason: <one line, applying the brd-format.md §3 test for this class>
        names: [BR#<m>, ...]          # required for conflict and duplicate; omitted otherwise
figures:                              # one entry per image the figures file records as read; [] when figures_path was omitted
  - path: <the image's path relative to brd/, as the figures file heads it>
    illustrates: [BR#<n>, ...]        # prose rows the image restates; [] when none
    note: <optional — e.g. "company logo; bears on no obligation">
notes: |
  <optional — anything the caller should know about the read: an unusually structured source, a
  passage that could not be confidently split, an image whose transcription was too partial to judge>
```

- `status: OK` — the set was read and produced at least one `[BR#n]` row.
- `status: EMPTY` — the set was read and contained no identifiable requirement.
- `status: NOT_FOUND` — an input was missing, not markdown, or did not resolve to a file.
- The rows an image *yields* are those whose `source_anchor` names it; they are not listed again under
  `figures`.

## Hard rules

- NEVER modify, reword, reflow, or reformat any file. This agent only reads.
- NEVER assign, close, or otherwise decide a `[DEF#n]`. `defect_candidates` are proposals.
- NEVER fabricate a `[BR#n]` row not grounded in the document, an appendix, or a transcription. If the
  set contains no identifiable requirement, return `status: EMPTY`.
- NEVER treat a transcription as the customer's words: it is the plugin's reading of their picture
  (`brd-format.md` §1.2), so an image-derived row anchors on the image, never on the figures file.
- NEVER renumber or reuse a `[BR#n]` within one read — ids are assigned once, in reading order, from
  `BR#1`. Coordinating ids across intake runs is the orchestrator's responsibility.
- NEVER read a file the caller did not hand over, and NEVER follow a link.
````

- [ ] **Step 2: Update the agents page**

In `plugins/product-workflows/docs/reference/agents.md`:

(a) Line 3 — replace *"Ten carry a `model: opus` frontmatter pin (shown as **opus** below) and run on Opus every time, regardless of the dispatching command's own model tier for that run; one, `brd-reader`, carries a `model: sonnet` frontmatter pin (shown as **sonnet** below) and runs on Sonnet every time, because its extraction work is mechanical; the remaining three"* with *"Eleven carry a `model: opus` frontmatter pin (shown as **opus** below) and run on Opus every time, regardless of the dispatching command's own model tier for that run; the remaining three"*. (Task 2 left it at *Ten*; if you find *Nine*, Task 2 did not land — stop.)

(b) Replace the `brd-reader` row with:

```markdown
| `brd-reader` | opus | Read, Glob, Grep | Extracts a `[BR#n]` inventory from a customer's BRD — the document, every markdown file it links, and the transcriptions of its images — with a `source_anchor` per row and unconfirmed `defect_candidates`; raises an `ambiguity` on an obligation only an image states. Never rewrites the source. | `/brd-intake` |
```

Check the new row's *What it does* cell is at most 200 characters (check 6); shorten wording, never drop the Opus fact, if it is not.

- [ ] **Step 3: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5.

- [ ] **Step 4: Sweep the tier claim by subject**

Count, collapsed-whitespace, across `plugins/`, `README.md`, `CLAUDE.md` (changelogs included): `brd-reader` within 80 characters of `Sonnet` or `sonnet`. Record every hit. The ones in `commands/brd-intake.md` and `docs/commands/brd-intake.md` are Task 6's to change; a hit in a `CHANGELOG.md` is history and stays; **any other hit is this task's to fix now**. Expected after this task: hits only in those three places.

- [ ] **Step 5: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/agents/brd-reader.md plugins/product-workflows/docs/reference/agents.md
git commit -m "feat(brd-reader): read the appendices and image transcriptions, on Opus

<body>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---
### Task 5: `/brd-intake` capture — walk first, consent, then copy

**Files:**
- Modify: `plugins/product-workflows/commands/brd-intake.md` — Phase 1 (lines 116–142), Phase 2 (lines 185–228), Phase 7 (lines 438–440)

The documentation page and the frontmatter description are Task 6's, which rewrites them once for capture and reading together. A reviewer of this task should not expect them changed.

**Interfaces:**
- Consumes: `linked-sources.md` §3–§7 (Task 1); `brd-format.md` §1.1's `brd/source-external/` and the link log's mapping table (Task 3).
- Produces: after Phase 2, every taken file copied — inside ones under `brd/source/` at their relative paths, outside ones under `brd/source-external/` at their basenames — and `brd/brd-link-log.md` with the reason `ambiguous` and the table *Captured links that do not resolve as written*. Task 6's Phase 2.5 reads the copied images by those paths; its Phase 3 hands `brd-reader` the copied markdown in Phase 2's capture order.

- [ ] **Step 1: Phase 1 — the walk, shown before consent**

Replace the Phase 1 bullet that begins *"The resolved absolute path to `@<brd-file>`, **and its own directory**"* (lines 122–125, ending *"…before consenting to it."*) with:

```markdown
- The resolved absolute path to `@<brd-file>`, **and its own directory**. **Run the walk
  `${CLAUDE_PLUGIN_ROOT}/references/linked-sources.md` §4 defines, from the document, now** — it is
  read-only: it copies nothing, writes nothing and dispatches nothing. Show what it found: how many
  linked files of each kind — **markdown**, **image**, **other** — inside the document's own directory
  and outside it, and every target it could not resolve, with its reason (`url`, `unreadable`, or
  `ambiguous` with every candidate). Name by path every file outside the directory and every *other*
  file. This is the list Phase 2 copies from, so the operator consents to exactly what is about to be
  copied out of their filesystem.
```

- [ ] **Step 2: Phase 1 — the two consent questions**

Immediately before the fenced block holding `choices: ["Proceed with <folder> (Recommended)", "Use a different key or path (you'll be prompted)", "Cancel"]`, insert:

````markdown
**Where the walk reached any file outside the document's own directory, ask first** — the answer
decides the set the next question is asked over:

```
choices: ["Capture all <n> (Recommended)", "Only the document's own folder — log the rest, as today", "Stop"]
```

*Capture all* takes every file the walk reached; Phase 2 copies the outside ones into
`brd/source-external/`. *Only the document's own folder* takes the files inside it and leaves every
outside file `excluded` — with everything reachable only through one (`linked-sources.md` §7) — and
Phase 2 logs each with the reason this command gave it before it could capture them: exactly the
behaviour a run had before this question existed. *Stop* ends the run with nothing written. Where
nothing lies outside the directory, this question is not asked.

**Where the taken set holds an *other* file — neither markdown nor an image — ask next:**

```
choices: ["Stop and convert them first — nothing has been written (Recommended)", "Proceed — none of them carries an obligation (recorded)", "Use a different key or path (you'll be prompted)"]
```

*Stop and convert* ends the run with nothing written:
`BRD_INTAKE_UNREAD_ATTACHMENTS: <n> linked file(s) are neither markdown nor an image and would be copied but never read: <paths>. Convert each (markdown for a document, PNG for a picture), link the converted file from the BRD, check the conversion against the original, and re-run '/product-workflows:brd-intake <BRD-KEY> @<brd-file>'.`
It is an operator halt, not a plugin gap, so `emit-block` does not fire — Phase 9 makes the same call
for every Phase 0 stop. **Converting is the operator's checked step for the same reason Phase 0 step 3
refuses to convert the document**: an unchecked conversion would silently become part of the record.
*Proceed* copies them, reads none of them, and records the operator's account in the final report,
exactly as Phase 3's *"They hold no obligation"* answer is recorded. Where the taken set holds no
*other* file, this question is not asked.

````

- [ ] **Step 3: Phase 2 — copy what the walk took**

In Phase 2, replace everything from the line beginning `**The link forms covered**, which are the ones a customer's markdown actually uses:` through the reason table's last row (`| \`unreadable\` | the target names no file under the source document's directory, or names one that cannot be read |`), inclusive, with:

````markdown
**The links were found, resolved and walked in Phase 1**, by `linked-sources.md` — this phase copies
what that walk took and never walks again. The walk's record says, per target, what kind of file it
reached and whether it lies inside the document's own directory; Phase 1's answers say which are taken.

**Where each taken file lands.**

- **Inside the document's own directory** → at **its path relative to that directory** under
  `<BRD-dir>/brd/source/`, creating intermediate directories as needed. The copied document sits at
  `brd/source/<basename>` and the copy mirrors the source tree's own layout beneath it, so every
  relative link resolves from the copy exactly as it did from the customer's original — **with no edit
  to the copied text**. `../images/flow.png` written in `appendix/notes.md` resolves inside the
  directory and is copied like any other; a syntactic `..` test would have refused a file in scope.
- **Outside it** — taken only on Phase 1's *Capture all* → into `<BRD-dir>/brd/source-external/`, at its
  **basename**, never at a path mirroring where it came from. A second file with the same basename
  takes the lowest free `_NN` suffix on the original basename; byte-identical content already there is
  reused rather than copied twice. `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §1.1 says why.

Copy each file **byte-for-byte, whatever its type** — an image, a PDF, a spreadsheet — never opened
as text, never re-encoded, never resized. Phase 0 step 3's markdown-only rule is about the *document*
the inventory anchors into; a file it links is captured as it stands. **What is read, and by whom, is
Phase 2.5's and Phase 3's** — this phase copies and reads nothing.

**Every link not copied is named, never dropped in silence.** Write `<BRD-dir>/brd/brd-link-log.md`
in the shape `brd-format.md` §1.1 fixes — the source document's basename, the counts, and one row per
uncopied link carrying the target as written, the copied file the link sits in, and one of these
reasons:

| Reason | Fires when |
|---|---|
| `outside the source directory` | the target resolves above the document's own directory, and Phase 1's answer was *Only the document's own folder* |
| `absolute path` | the target begins with `/`, and Phase 1's answer was *Only the document's own folder* |
| `url` | the target carries a URI scheme |
| `unreadable` | the target resolves to no readable file (`linked-sources.md` §3) |
| `ambiguous` | a `[[wikilink]]` matched more than one file in the vault; the row names every candidate |

**Then map every captured link that does not resolve as written**, in the log's second table,
*Captured links that do not resolve as written* — columns `Target as written | Linked from | Copy` —
one row per link whose copy cannot be reached by reading its target as a path relative to the file it
sits in: every file copied into `source-external/`, and every `[[wikilink]]`. `Copy` is the copy's path
relative to `brd/`. The table is written, with a header and no rows, even where nothing needs mapping.
````

Leave the paragraph beginning **"Write the log on every run, including one that captured everything"** exactly as it stands, directly after your replacement.

- [ ] **Step 4: Phase 7 — hand off the external copies**

In Phase 7, change *"That is each file this run actually copied into `brd/source/` — the customer's document **and every file it links** (Phase 2) — named individually (the copy step knows them; `brd/source/**` is not a path)"* to *"That is each file this run actually copied into `brd/source/` or `brd/source-external/` — the customer's document **and every file it links** (Phase 2) — named individually (the copy step knows them; neither `brd/source/**` nor `brd/source-external/**` is a path)"*.

- [ ] **Step 5: Sweep the capture vocabulary**

Collapsed-whitespace counts across `plugins/`, `README.md`, `CLAUDE.md` (changelogs included), before and after your edits, for each of: `The link forms covered`, `Then repeat the whole capture`, `the boundary Phase 2's capture stops at`. Each must fall to **0** outside a `CHANGELOG.md`. For any hit in a file other than `commands/brd-intake.md`, `docs/commands/brd-intake.md` (Task 6) or `agents/idea-reader.md` (Task 9): read its paragraph and fix it here.

- [ ] **Step 6: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5. Check 12 now counts two more `choices:` arrays, both of three options, and passes.

- [ ] **Step 7: Mutation control on check 12**

Append a fourth and a fifth option to the new outside-folder array (`, "x", "y"`), run `./scripts/check-docs.sh --root .`, and confirm it fails naming check 12. Restore and rerun the chain green.

- [ ] **Step 8: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/commands/brd-intake.md
git commit -m "feat(brd-intake): walk the links before consent; capture wikilinks and files outside the folder

<body: the wikilink defect this fixes; the two questions; source-external and the mapping table>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

### Task 6: `/brd-intake` reading — figures, appendices, coverage, and the page

**Files:**
- Modify: `plugins/product-workflows/commands/brd-intake.md` — frontmatter `description` (line 3); Phase 1.5 (lines 150–165); new Phase 2.5 before `## Phase 3`; Phase 3 (lines 238–300); Phase 4 (after line 368); Phase 5 (after line 389); Phase 7; Phase 9 step 1 (lines 517–523); Final report (lines 548–549)
- Modify: `plugins/product-workflows/docs/commands/brd-intake.md`
- Modify: `plugins/product-workflows/docs/brd-workflow.md` (the folder tree, lines ~238–242)

**Interfaces:**
- Consumes: `figure-reader` (Task 2); `brd-format.md` §1.2, §2, §2.2 (Task 3); `brd-reader`'s inputs and `figures[].illustrates` (Task 4); Phase 2's copies and capture order (Task 5).
- Produces: `brd/brd-figures.md`, written in Phase 2.5 and completed in Phase 5; Task 8 ships it.

- [ ] **Step 1: Frontmatter description**

Replace the `description:` value on line 3 with exactly:

```
BRD-intake workflow (PM phase, entry point of the BRD-to-PRD flow). Walks every link a customer-supplied business requirements document makes — wikilinks included — read-only, shows the operator the list and asks before capturing anything outside the document's folder or anything it cannot read, then copies the document and every file it takes into the specs repo byte-for-byte, naming in brd/brd-link-log.md each link it did not copy and why. figure-reader transcribes every linked image into brd/brd-figures.md, and brd-reader extracts a [BR#n] requirement inventory from the document, its linked markdown and those transcriptions; its defect candidates are confirmed interactively against the six brd-format.md classes, and a coverage-ledger.md is written with every row unallocated. Rejects a non-markdown source rather than converting it. Grounds on the shipped product documentation when $DOCS_PATH resolves (--no-docs off), consumed grill-rank over the defect walk. Optional --sort-existing migrates an already-hand-written package into seed files. Offers /brd-split as the next step.
```

- [ ] **Step 2: Phase 1.5 — both agents on Opus**

(a) In the `model_routing` block, replace the line beginning `  detection_model:` with these two lines:

```yaml
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # docs-grounder (Phase 3.5)
  extraction_model: <§2 Opus chain>   # figure-reader (Phase 2.5) and brd-reader (Phase 3) — both frontmatter-pinned to opus; recorded, no override
```

(b) Replace the paragraph *"`brd-reader` runs on Sonnet regardless of `classification` — its extraction work is mechanical, per its own frontmatter pin. If no Opus resolves for `current_model`, **degrade to best-available + record** in `notes` and the final report — do not hard-block."* with:

```markdown
`figure-reader` and `brd-reader` run on Opus regardless of `classification`, per their own frontmatter
pins. A misread label, a missed annotation or an unproposed conflict yields no candidate, so Phase 4's
human never sees it — the tier is bought where a miss is silent. If no Opus resolves, **degrade to
best-available + record** in `notes` and the final report — do not hard-block.
```

- [ ] **Step 3: Insert Phase 2.5**

Immediately before the line `## Phase 3 — Extract the inventory` (and after the `---` that closes Phase 2), insert:

````markdown
## Phase 2.5 — Read the figures

**Every image Phase 2 copied is read here, and there is no cap on how many.** A cap would leave an
image's obligations outside the record exactly as not reading it did (`brd-format.md` §1.2).

1. **Re-use before reading.** Compute each copied image's SHA-256. Where
   `<BRD-dir>/brd/brd-figures.md` already holds a section for that image whose *Content hash* matches,
   keep the section **verbatim** and do not dispatch the image — a writer preserves what it did not
   produce, as `workflows-core:grounding-format` §6.2 has an index writer do with a row. On a first
   intake there is no file and nothing is re-used.
2. **Dispatch `figure-reader` over the rest**, at most 10 images per dispatch and at most 4 dispatches
   in a single response, in further waves until none remain:

   → Agent (subagent_type: "product-workflows:figure-reader", model: `<extraction_model — frontmatter-pinned to opus>`):
     > "figures: [absolute path of each image in this batch, in Phase 2's capture order]"

   An `INPUT_MISSING` return is this run's defect — it sent an empty batch — and is fixed and
   re-dispatched, never recorded as an unread image.
3. **Write `<BRD-dir>/brd/brd-figures.md`** per `brd-format.md` §1.2: one section per image Phase 2
   copied, in capture order — re-used sections verbatim, new ones from the agent's return, an image
   returned `read: false` with its reason and no transcription. A section already on file for an image
   the current document no longer links stays, marked as §1.2 says. Leave every *Rows* line empty;
   Phase 5 completes them.

Where Phase 2 copied no image, this phase dispatches nothing, writes no file, and says so in the
final report.

---

````

- [ ] **Step 4: Phase 3 — the dispatch**

Replace the dispatch block

```
→ Agent (subagent_type: "product-workflows:brd-reader", model: `<detection_model — frontmatter-pinned to sonnet>`):
  > "source_path: [absolute path to the copied source **document** under `<BRD-dir>/brd/source/` — that directory also holds the files it links (Phase 2), and this agent reads only the document]"
```

with

```
→ Agent (subagent_type: "product-workflows:brd-reader", model: `<extraction_model — frontmatter-pinned to opus>`):
  > "source_path: [absolute path to the copied document at `<BRD-dir>/brd/source/<basename>`]
  >  appendices:  [absolute path of every markdown file Phase 2 copied — under `brd/source/` or `brd/source-external/` — in Phase 2's capture order; `[]` when none]
  >  figures_path: [absolute path to `<BRD-dir>/brd/brd-figures.md`; omit when Phase 2.5 wrote none]"
```

- [ ] **Step 5: Phase 3 — map every returned id through the reconciliation**

Immediately after the paragraph ending *"…and any existing row this source no longer contains (which keeps its id and is reported, never renumbered away)."*, insert:

```markdown
**Map every id the agent returned through that reconciliation, not only the row ids** — each
candidate's `names`, and each `figures` entry's `illustrates`. The agent numbers its own read from
`BR#1`; a `conflict` naming its `BR#7`, or an image said to illustrate its `BR#7`, means whatever row
the reconciliation matched to that `BR#7`, and writing the agent's number through would attach the
candidate or the image to a different requirement.
```

- [ ] **Step 6: Phase 3 — the coverage check over all three**

(a) Replace *"Both relations read the anchors already written and the copied source document — never a file it links, which carries no section and holds no `[BR#n]`; nothing else is stored and the agent is not re-dispatched."* with:

```markdown
The three relations read the anchors already written, the copied document and linked markdown,
`brd/brd-figures.md`, and the `figures` list the agent returned; nothing else is stored and the agent
is not re-dispatched.
```

(b) In relation 1, change *"**Every `source_anchor` resolves to a section the source has** — by its section reference, or, where it carries none, by the line it names (`brd-format.md` §2.2 fixes the order)."* to *"**Every `source_anchor` resolves**, in whichever of `brd-format.md` §2's three forms it takes — a document anchor to a section by its section reference or, where it carries none, the line it names; a linked-markdown anchor to a section of that file; an image anchor to a read image whose transcription holds the quoted element (`brd-format.md` §2.2 fixes each rule)."*

In the `BRD_INTAKE_DANGLING_ANCHOR` message, change `resolves to no section of the copied source document under brd/source/` to `resolves to nothing in the copied source under brd/`.

(c) Replace the line *"2. **Every top-level section either holds a row or is accounted for.** Name each section that holds none, with what the source has under it, and ask — one question for the set, not one per section:"* with:

```markdown
  2. **Every top-level section — of the document and of each linked markdown file — either holds a row
     or is accounted for.** Name each section that holds none, with what the source has under it.
  3. **Every image yields a row, illustrates one, or is accounted for** (`brd-format.md` §2.2). Name
     each image that does neither — with its *Depicts* sentence from `brd/brd-figures.md`, or its reason
     where it was not read.

  Ask about relations 2 and 3 together — one question for the whole set, not one per section or image:
```

The `choices:` array that follows is unchanged.

- [ ] **Step 7: Phase 4 — a candidate on an image-derived row comes with its picture**

Immediately after the fenced block holding `choices: ["Confirm as written (Recommended)", "Confirm with an edited reason", "Reject — not a defect", "Cancel"]`, insert:

```markdown
**A candidate on a row drawn from an image is put with its picture.** Show the image's path relative to
`brd/` and its transcription from `brd/brd-figures.md` beside the candidate, and tell the operator to
open the image before answering: the transcription is the plugin's reading of the customer's picture
(`brd-format.md` §1.2), and the picture is what the candidate is about.
```

- [ ] **Step 8: Phase 5 — complete the figures' *Rows***

Immediately after the paragraph ending *"No row is ever written in any other disposition here."*, insert:

```markdown
**Then complete `brd/brd-figures.md`'s *Rows* line for every image**, from the final inventory — after
Phase 3's reconciliation mapping, never from the agent's own numbering: `yields` every row whose
`source_anchor` names the image, `illustrates` every row the agent returned for it, or
`accounted for — <the operator's Phase 3 account>` where it does neither. A run that wrote no figures
file skips this.
```

- [ ] **Step 9: Phase 7 — hand off the figures file**

In the `deliverable_paths` sentence, change `plus \`brd/brd-inventory.md\`, \`brd/brd-defect-log.md\`, \`brd/brd-link-log.md\`,` to `plus \`brd/brd-inventory.md\`, \`brd/brd-defect-log.md\`, \`brd/brd-link-log.md\`, \`brd/brd-figures.md\` when Phase 2.5 wrote it,`.

- [ ] **Step 10: Phase 9 and the final report**

(a) In Phase 9 step 1, change *"what was produced (the copied source and the files it links, the inventory, the confirmed defect log, the link log, the ledger skeleton); key events (a rejected PDF, an `EMPTY` read, a link the copy could not capture, unresolved candidates left `open`, docs grounding OFF or a docs-raised defect — or "none")"* to *"what was produced (the copied source and the files it links, the figures transcriptions, the inventory, the confirmed defect log, the link log, the ledger skeleton); key events (a rejected PDF, an *other* file the operator accounted for, an `EMPTY` read, a link the copy could not capture, an `ambiguous` wikilink, an image not read, unresolved candidates left `open`, docs grounding OFF or a docs-raised defect — or "none")"*.

(b) In the Final report's first sentence, change *"how many files were copied beside the source and, per `brd/brd-link-log.md`, every link the copy could not capture with its reason (Phase 2);"* to *"how many files were copied beside the source — inside its directory and into `brd/source-external/` — and, per `brd/brd-link-log.md`, every link the copy could not capture with its reason (Phase 2), with Phase 1's answers and any *other* file the operator accounted for; how many images were transcribed, re-used and not read, with each reason (Phase 2.5); how many linked markdown files were read beside the document (Phase 3); the coverage outcome for sections and images;"*.

- [ ] **Step 11: The command's documentation page**

In `plugins/product-workflows/docs/commands/brd-intake.md`:

(a) Opening paragraph (lines 3–6) — replace it with:

```markdown
Copies a customer-supplied business requirements document into the specs repo verbatim — and with
it every file that document links, wikilinks included, after showing you the list — transcribes every
linked image, extracts a `[BR#n]` requirement inventory from the document, its linked markdown and
those transcriptions, confirms the document's defects with a human, and writes a coverage ledger
where every requirement starts `unallocated`.
```

(b) In the mermaid diagram, replace `    p2 --> p3["Phase 3 — Extract the inventory"]` with the two lines:

```
    p2 --> p25["Phase 2.5 — Read the figures"]
    p25 --> p3["Phase 3 — Extract the inventory"]
```

(c) Replace the paragraph beginning *"Two subagents are dispatched: `brd-reader` (Phase 3, frontmatter-pinned to Sonnet —"* through *"`workflows-core:impl-maintenance` also runs, in Phase 9, for session lessons-learned."* with:

```markdown
Three subagents are dispatched: `figure-reader` (Phase 2.5, frontmatter-pinned to Opus — it transcribes
every linked image, in parallel batches, without reading the document that links it), `brd-reader`
(Phase 3, frontmatter-pinned to Opus — its defect candidates are judgement over a long, contradictory
document, and a conflict it never proposes reaches no one) and `workflows-core:docs-grounder`
(Phase 3.5, read-only grounding on the shipped product docs — default ON when `$DOCS_PATH` resolves,
advisory, never a gate). `workflows-core:impl-maintenance` also runs, in Phase 9, for session
lessons-learned.
```

(d) In *What it needs*, add after the `@<brd-file>` bullet:

```markdown
- **Your answer about what the document links.** Phase 1 walks every link first, read-only, and shows
  you what it found. Where anything lies outside the document's own folder it asks whether to capture
  it; where anything is neither markdown nor an image it asks you to convert it first
  (`BRD_INTAKE_UNREAD_ATTACHMENTS` on *Stop*), because nothing reads such a file.
```

(e) In *What it produces*, replace the `brd/source/<the paths it links>` and `brd/brd-link-log.md` bullets with:

```markdown
- `brd/source/<the paths it links>` — every file that document links from its own directory, copied
  byte-for-byte to the same relative path, so the copied text's links resolve exactly as the
  customer's did. Screenshots are the usual case, and capturing them is the only chance there is:
  nothing under `brd/source/` is ever written again.
- `brd/source-external/<basename>` — every file the document links from outside its own folder, where
  you chose to capture it, by basename; immutable exactly as `brd/source/` is.
- `brd/brd-link-log.md` — the links the copy could **not** capture, each with its reason (a URL, an
  unreadable target, a wikilink matching several files, or — where you chose the document's own folder
  only — one above it or an absolute path), the run's counts, and a table mapping every captured link
  that does not resolve as written (a wikilink, an external file) to its copy. Written on every run.
- `brd/brd-figures.md` — what the plugin read in each linked image: a verbatim transcription, the
  customer's annotations and what they point at, and the rows each image yields or illustrates.
```

(f) In *Gates*, replace the bullet beginning `- **Phase 3 — \`brd-reader\`** (Sonnet, frontmatter-pinned).` — only its first sentence — with `- **Phase 3 — \`brd-reader\`** (Opus, frontmatter-pinned). Read-only extraction from the document, its linked markdown and the image transcriptions: it proposes a \`[BR#n]\` row per requirement plus unconfirmed \`defect_candidates\` — an \`ambiguity\` on any obligation only an image states — and never decides a defect itself.` Leave the rest of that bullet as it is.

In the same bullet's second paragraph, change *"And every **top-level section** must either hold a row or be accounted for"* to *"And every **top-level section** — of the document and of each linked markdown file — and every **image** must either hold or illustrate a row or be accounted for"*.

(g) In *Example*, change *"copies `customer-brd.md` verbatim into `brd/source/` together with every file it links from its own directory, records in `brd/brd-link-log.md` each link it could not capture and why, dispatches `brd-reader` to extract the `[BR#n]` inventory,"* to *"shows you every file `customer-brd.md` links, copies it verbatim into `brd/source/` together with the files you took, records in `brd/brd-link-log.md` each link it did not copy and why, transcribes the linked images, dispatches `brd-reader` to extract the `[BR#n]` inventory from all of it,"*.

(h) In *See also*, change the `brd-format.md` bullet's *"§1.1's account of what `brd/source/` holds and of the link log beside it"* to *"§1.1's account of what `brd/source/` and `brd/source-external/` hold and of the link log beside them, §1.2's figures file"*; change `` [Agents](../reference/agents.md) — `brd-reader`'s and `docs-grounder`'s full contracts. `` to `` [Agents](../reference/agents.md) — `figure-reader`'s, `brd-reader`'s and `docs-grounder`'s full contracts. ``; and add a bullet `- [\`linked-sources.md\`](../../references/linked-sources.md) — how Phase 1 finds, resolves and walks the document's links.`

- [ ] **Step 12: The folder tree**

In `plugins/product-workflows/docs/brd-workflow.md`'s tree, replace the two lines

```
│   ├── brd-inventory.md         # [BR#n] rows, /brd-intake
│   ├── brd-link-log.md          # the links the copy could not capture, with reasons, /brd-intake
```

with

```
│   ├── source-external/<name>   # files the document links from outside its folder, when captured
│   ├── brd-inventory.md         # [BR#n] rows, /brd-intake
│   ├── brd-link-log.md          # links not captured, with reasons, and the as-written map, /brd-intake
│   ├── brd-figures.md           # each linked image's transcription and the rows it yields, /brd-intake
```

- [ ] **Step 13: Sweep**

Collapsed-whitespace counts, before and after, across `plugins/`, `README.md`, `CLAUDE.md` (changelogs included), for: `reads only the document`, `nothing in this run reads its content`, `frontmatter-pinned to sonnet`, `frontmatter-pinned to Sonnet`, `runs on Sonnet regardless`, `its extraction work is mechanical`. Intended after-count: **0** for each, outside a `CHANGELOG.md` and outside `agents/idea-reader.md` / `commands/idea.md` (Task 9). `nothing in this run reads their content` in `commands/brd-package.md` is Task 8's. Any other hit is this task's to fix.

Then read `brd-intake.md` end to end, Phase 0 through the Final report, and confirm no sentence still describes the document as the only thing read, the capture as bounded by the directory, or `brd-reader` as Sonnet.

- [ ] **Step 14: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5. The mermaid gate parses the page's new node.

- [ ] **Step 15: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/commands/brd-intake.md plugins/product-workflows/docs/commands/brd-intake.md plugins/product-workflows/docs/brd-workflow.md
git commit -m "feat(brd-intake): read the linked images and markdown, and account for every one

<body>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---
### Task 7: An open requirement defect becomes a customer question, and its answer settles it

**Files:**
- Modify: `plugins/product-workflows/references/interview-tagging.md` (§1)
- Modify: `plugins/product-workflows/commands/brd-interview.md` (Phase 2 lines ~339–341, ~374–381, ~388–395; Phase 3 after line ~462; Phase 7 lines ~659–663; Phase 9 lines ~742–760; every count of the question sources)
- Modify: `plugins/product-workflows/references/decision-register-format.md` (§1 YAML, table, prose, line 79; §7 lines 212–214 and table)
- Modify: `plugins/product-workflows/commands/brd-reconcile.md` (frontmatter `description`; Phase 5 table; Phase 8)
- Modify: `plugins/product-workflows/docs/commands/brd-interview.md` (lines 28–40)
- Modify: `plugins/product-workflows/docs/commands/brd-reconcile.md` (lines 441–442)

**Interfaces:**
- Consumes: `brd-format.md` §4's `resolved-by: [CD#n]` (Task 3).
- Produces: the requirement-defect question source; the `customer-questions.md` entry field naming its `[DEF#n]`; the `settles` field; the third `/brd-reconcile` resolution. Nothing later depends on these by name except Task 9, which ships the question set unchanged, and Task 11's fixture.

- [ ] **Step 1: `interview-tagging.md` §1 — the tag is fixed**

Immediately after the paragraph beginning **"A `[C]` reaches the customer only through the review package"** (ending *"…this file fixes only the first: who may be asked."*), insert:

```markdown
**A question raised by a requirement defect is always `[C]`.** `commands/brd-interview.md` raises one
for each open `[DEF#n]` of a class grounding cannot settle (`references/brd-format.md` §3) — which of
two readings the customer meant, which of two conflicting requirements governs, whether an obligation
only a picture states binds at all. The defect is in the customer's own statement, so only the
customer can settle it. A delivery-team preference may travel inside the question as the reading
proposed for confirmation; it never turns the question into a `[V]`, and a `[G]` part split off it
under §4 takes its own tag without changing this one.
```

- [ ] **Step 2: `/brd-interview` Phase 3 — the seventh source**

Immediately after the bullet beginning *"- an in-scope ledger row resolved `deferred-to` or `rejected` whose consequence for the rest of the BRD is unstated;"* and before the bullet beginning *"- anything the package will have to **assert without evidence**"*, insert:

```markdown
- an **open requirement defect** — a `[DEF#n]` in `brd/brd-defect-log.md` (the parent's on a slice,
  one hop — `brd-format.md` §4) whose resolution is `open` and whose class grounding cannot settle:
  `ambiguity`, `conflict`, `duplicate`, `untestable` or `scope-leak`. `unsourced` is not in the list:
  grounding settles it, and a finding that could not is already a question under the `NOT-PROVABLE`
  bullet above. **Which BRD asks is read off the inventory and the ledgers, never off the log**, whose
  entry names no row: the defect's rows are the rows whose `defects` column lists it in the log-owning
  BRD's inventory (the parent's, on a slice), and it is asked **once**, by the BRD that owns the
  **lowest-numbered** of them — on a slice, the one the parent's `coverage-ledger.md` records that row
  `covered-by`. This BRD asks it where that is this BRD **and** the row's disposition in this BRD's own
  ledger is `covered-here` or `deferred-to`; otherwise it asks nothing about it, because another BRD
  owns the question or the row's fate (`rejected`, `superseded-by`) has settled it, and the bullet
  above covers what the customer needs to hear about that. Every other row the defect lists, and every
  counterpart a `conflict` or `duplicate` names, is context for the question. **The question states
  what the defect records** — the two readings, the two requirements that cannot both hold, the
  missing observable outcome — and, where the row is drawn from an image (`brd-format.md` §2), names
  the image's path, which the customer holds in the bundle. It is `[C]` (`interview-tagging.md` §1);
```

The new bullet ends with `;`, and the existing *assert without evidence* bullet follows it directly.

- [ ] **Step 3: `/brd-interview` — every count of the sources, and the no-question walk**

(a) Change each of these three phrases, wherever it sits (match wrap-insensitively):
- `names each of the six question sources` → `names each of the seven question sources`
- `must not re-derive the six sources above` → `must not re-derive the seven sources above`
- `each of the six sources *Round 1 is generated from the grounding* names` → `each of the seven sources *Round 1 is generated from the grounding* names`

(b) In Phase 2's *"No question at all"* branch, change *"no `deferred-to`/`rejected` row with an unstated consequence, and nothing the package must assert without evidence."* to *"no `deferred-to`/`rejected` row with an unstated consequence, no open requirement defect this BRD asks, and nothing the package must assert without evidence."*

(c) In Phase 9's round-record paragraph, change *"no ledger row with an unstated consequence, nothing asserted without evidence."* to *"no ledger row with an unstated consequence, no open requirement defect this BRD asks, nothing asserted without evidence."*

- [ ] **Step 4: `/brd-interview` Phase 9 — the account line**

Immediately after the paragraph beginning **"`<BRD-dir>/interview/round-<N>.md`** — the round's own record, append-only."** (ending *"…in the same words, that *Resolve the round* resumes on."*), insert:

```markdown
**Every round record carries one line accounting for the requirement-defect source**, whether or not
the round raised a question: `requirement defects: [DEF#n], [DEF#m] asked`, or
`requirement defects: none open in this BRD's scope`. It is the line the *Resolve the round* phase
reads to tell a round written after that source existed from one written before it, which never
walked it.
```

- [ ] **Step 5: `/brd-interview` Phase 2 — a confirmed defect reopens the conversation; an old round is re-opened for it**

(a) In the *"Every round is closed"* bullet, change *"or a decision in `decisions.md` moved to `reopened` or `superseded`."* to *"or a decision in `decisions.md` moved to `reopened` or `superseded` — or an open requirement defect this BRD asks (*Round 1 is generated from the grounding*) that no round record names, where the latest round record carries the requirement-defect account line (*Write the register and the round record*): that defect was confirmed after the round closed, by an intake re-run over a revised source, and a new round is exactly where it belongs."*

(b) Immediately after that bullet, insert:

```markdown
- **Every round is closed, the latest round record carries no requirement-defect account line, and
  this BRD asks an open requirement defect** → the round records were written before this command read
  the defect log, so those defects were never walked — and a question that could have been asked in
  round 1 stays in round 1 (`interview-tagging.md` §5), never in a new round. Open no round; report
  each such `[DEF#n]` and name the re-open that asks them:
  `/product-workflows:brd-interview <BRD-KEY> --round 1`, with the cause *requirement defects became a
  question source*.
```

(c) In the `--round N` *"Round `N` is closed"* bullet, append after *"…and never merely because this round is open again."*:

```markdown
  **A re-open whose cause is *requirement defects became a question source*** runs that one source
  (*Round 1 is generated from the grounding*) over this BRD and appends each question it raises to the
  re-opened round, numbered after the round's last question — never renumbering one — and writes the
  round's account line.
```

- [ ] **Step 6: `/brd-interview` Phase 7 — the held question carries its defect**

Change *"the findings that bear on it, so the customer is asked against what is known rather than in the abstract;"* to *"the findings that bear on it, so the customer is asked against what is known rather than in the abstract; **for a question the requirement-defect source raised, the `[DEF#n]` it asks about** and, where the defect sits on a row drawn from an image, that image's path relative to `brd/` — `/brd-reconcile` copies the `[DEF#n]` into the answering `[CD#n]`'s `settles` field, and resolves it from nothing else;"*.

- [ ] **Step 7: `decision-register-format.md` — `settles`, the thirteenth field**

(a) In §1's YAML, insert after the `defects:` line:

```yaml
settles: [[DEF#4]]                        # omitted unless a [CD#n] answers a question a requirement defect raised
```

(b) In §1's table, insert after the `defects` row:

```markdown
| `settles` | the `[DEF#n]` requirement-defect entries a `[CD#n]` answers — the one the `[C]` question it answers was raised by (`references/interview-tagging.md` §1), copied by `/brd-reconcile` from that question's held entry, never inferred from the customer's answer. **Only ever on a `[CD#n]`**: a requirement defect is in the customer's statement and is settled by the customer. Omitted when absent |
```

(c) Immediately after the paragraph beginning **"`defects` is not `evidence`, and the separation is load-bearing rather than tidy."**, insert:

```markdown
**`settles` is neither `evidence` nor `defects`.** `defects` names defects in the *code*, `[CDF#n]`,
that a position has to repair; `settles` names defects in the *customer's document*, `[DEF#n]`
(`references/brd-format.md` §3), that the decision answers — and it is what lets `/brd-reconcile`
resolve each one `resolved-by: [CD#n]` (`references/brd-format.md` §4) from a field rather than from a
reading of the customer's prose.
```

(d) Change *"§7 accounts for all twelve of these fields on an assumption record, one by one."* to *"§7 accounts for all thirteen of these fields on an assumption record, one by one."*

(e) In §7, change *"It uses the same twelve fields as §1"* to *"It uses the same thirteen fields as §1"* and *"All twelve are accounted for here."* to *"All thirteen are accounted for here."*

(f) In §7's table, insert after the `defects` row:

```markdown
| `settles` | **Not applicable.** An assumption answers no question, so it settles no requirement defect; a customer who confirms one does so in a `[CD#n]`, which carries `settles` only where the question it answers was raised by a defect |
```

- [ ] **Step 8: `/brd-reconcile` — write `settles`, then resolve**

(a) Frontmatter `description`: change `writes customer-amended and withdrawn resolutions to the defect log` to `writes customer-amended, withdrawn and resolved-by: [CD#n] resolutions to the defect log`.

(b) Phase 5's field table: insert after the `defects` row:

```markdown
| `settles` | the `[DEF#n]` the answered `[C]` question's entry in `interview/customer-questions.md` names, copied from that entry (`references/decision-register-format.md` §1); omitted where it names none. **Never inferred from the review**: which question an answer answers is already fixed by the round and position it cites, and the entry is the record of what that question was raised by |
```

(c) Phase 8: change *"**This command writes two of them, and only those:**"* to *"**This command writes three of them, and only those:**"*; insert after the table's `withdrawn` row:

```markdown
| `resolved-by: [CD#n]` | a `[CD#n]` this run froze `settles` the defect, and neither row above applies — the customer said which reading they meant. The `[CD#n]` named is the one whose `settles` names the defect, never one that merely looks related |
```

and immediately after the table (before *"`resolved-by: [CG#n]` is a grounding outcome"*), insert:

```markdown
**Which of the three a settled defect takes is read off the answer, in this order:** `withdrawn` where
the `[CD#n]` drops the requirement the defect was raised against — the *Update the coverage ledger*
phase then writes `rejected: [DEF#n]`, which is how *"it was only a sketch"* ends for an obligation only
an image stated; `customer-amended <date>` where the review supplied corrected text for it; otherwise
`resolved-by: [CD#n]`. **A `[CD#n]` frozen `open` resolves nothing** — its question stays held for the
customer (*Freeze the customer decisions*), and so does its defect.
```

- [ ] **Step 9: The two documentation pages**

(a) `docs/commands/brd-interview.md`: in the `--round N` bullet, change *"and proposes a new one only if findings or decisions have changed since the last round closed"* to *"and proposes a new one only if findings or decisions have changed, or a requirement defect was confirmed, since the last round closed"*. Then, immediately after that bullet (after *"…rather than re-deriving that judgement for itself."*), insert a paragraph at the bullet's indentation level:

```markdown
  **Every open requirement defect this BRD owns becomes a question for the customer** — an
  ambiguity, a conflict, a duplicate, or an untestable or scope-leaking requirement confirmed at
  intake, including an obligation only an image states — and always a `[C]`: the defect is in the
  customer's own words. A slice interviewed before this source existed gets its questions with
  `--round 1`, re-opened with the cause *requirement defects became a question source*; a bare run
  says so rather than opening a new round.
```

(b) `docs/commands/brd-reconcile.md`: change *"the four defect resolutions, two of which this command writes"* to *"the four defect resolutions, three of which this command writes — `customer-amended`, `withdrawn`, and `resolved-by: [CD#n]` for a defect whose question the customer answered"*.

- [ ] **Step 10: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5.

- [ ] **Step 11: Verify by hand**

Collapsed-whitespace counts across `plugins/`, `README.md`, `CLAUDE.md`, **excluding** `CHANGELOG.md` files, after the edits:
- `six question sources`, `six sources` in `brd-interview.md` → **0**; `seven question sources` / `seven sources` → **3**;
- `twelve` in `decision-register-format.md` → **0**; `thirteen` → **3**;
- `writes two of them` → **0**; `two of which this command writes` → **0**.

Then search `plugins/` for any other sentence enumerating the question sources or the register's fields by count (`sources`, `fields` within 40 characters of a number word) and fix any you find. Record what you searched and found in the commit body.

- [ ] **Step 12: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/references/interview-tagging.md plugins/product-workflows/commands/brd-interview.md plugins/product-workflows/references/decision-register-format.md plugins/product-workflows/commands/brd-reconcile.md plugins/product-workflows/docs/commands/brd-interview.md plugins/product-workflows/docs/commands/brd-reconcile.md
git commit -m "fix(brd-route): an open requirement defect is asked of the customer, and the answer settles it

<body: the shipped defect — nothing asked; the seventh source; the account line; settles; the third resolution>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---
### Task 8: The bundle carries the transcriptions and the external images

**Files:**
- Modify: `plugins/product-workflows/references/bundle-packaging.md` (§1.1 table; §2.1; §6.2 relation 1's table and the paragraph after it)
- Modify: `plugins/product-workflows/references/customer-review-schema.md:138` (section 4's row)
- Modify: `plugins/product-workflows/commands/brd-package.md` (Phase 0 step 10's resolve paragraph, ~line 301)
- Modify: `plugins/product-workflows/docs/commands/brd-package.md` (~lines 144–148)

**Interfaces:**
- Consumes: `brd-format.md` §1.1's mapping table and `brd/source-external/`, §1.2's *Rows* line declared as naming the log-owning BRD's requirements, §4's `resolved-by: [CD#n]` (Task 3).
- Produces: a bundle that holds `brd-figures.md` and every image the customer's document references, including through a wikilink or from outside its folder.

- [ ] **Step 1: §1.1 — the figures file ships**

In `bundle-packaging.md` §1.1's allow-list table, insert immediately after the `brd/brd-defect-log.md` row:

```markdown
| `brd/brd-figures.md` — **the parent's on a slice**, one hop, as the defect log is, and only where the BRD links an image | requirement traceability: the review's section 4 asks the customer to confirm or correct the package's reading of their document, and this file is its reading of their images (`references/brd-format.md` §1.2) |
```

- [ ] **Step 2: §2.1 — images reached through the link log's map**

Immediately after the paragraph beginning *"Where that leaves something a plain reader cannot open — an embedded image, a one-tool block — the fix is **beside the file, never inside it**"* (ending *"…the source document is not."*), insert:

```markdown
**An image the document reaches through a `[[wikilink]]`, or from outside its own directory, is found
through `brd/brd-link-log.md`'s *Captured links that do not resolve as written* table**
(`references/brd-format.md` §1.1) — its copy is in `brd/source/` or `brd/source-external/`, at a path
the link as written does not name. It is copied into the bundle like any other image, and the manifest
names the link as written beside the bundled file it resolves to: the source document itself is never
edited to point there.
```

- [ ] **Step 3: §6.2 relation 1 — two fields its authorities now declare**

(a) Replace the row

```
| `resolved-by: [CG#n]` | `references/brd-format.md` §4 | the grounding finding that settled a defect; grounding is slice-only, so it is whichever slice settled it |
```

with

```
| `resolved-by: [CG#n]`, `resolved-by: [CD#n]` | `references/brd-format.md` §4 | the grounding finding or the customer decision that settled a defect; grounding and deciding are both slice-only, so it is whichever slice settled it |
```

(b) Append one row at the end of that table, after the `superseded-by: [BR#n]` row:

```
| the *Rows* line of `brd/brd-figures.md` — every `[BR#n]` it yields or illustrates | `references/brd-format.md` §1.2 | a requirement in the figures file's owning BRD's inventory — the parent's on a slice |
```

(c) In the paragraph that follows, change *"**The last three are routine rather than exotic**"* to *"**The last four are routine rather than exotic**"*, and change *"§1.1 ships the **parent's** defect log whole into a slice's bundle,"* to *"§1.1 ships the **parent's** defect log and figures file whole into a slice's bundle,"*.

- [ ] **Step 4: The review's section 4 covers the transcriptions**

In `customer-review-schema.md`, replace line 138's row with:

```markdown
| 4 | Requirement traceability | Per requirement in scope: does the package's reading match the customer's intent — confirmed, corrected, or missing entirely. The package's reading includes its transcription of the customer's own images (`brd-figures.md`), which the reviewer confirms or corrects exactly as they do a requirement |
```

- [ ] **Step 5: `/brd-package` resolves the figures file with the other two**

In `commands/brd-package.md` Phase 0 step 10, change *"**Resolve `brd/source/<basename>` and `brd/brd-defect-log.md` here too**, even though nothing in this run reads their *content*: both go into the bundle"* to *"**Resolve `brd/source/<basename>`, `brd/brd-defect-log.md` and — where the BRD links an image — `brd/brd-figures.md` here too**, even though nothing in this run reads their *content*: all three go into the bundle"*, and in the same paragraph change *"and on a **slice** neither is in this folder at all — each resolves one hop up"* to *"and on a **slice** none is in this folder at all — each resolves one hop up"*.

Read the rest of that paragraph and of *Assemble the bundle*; where a sentence enumerates what the bundle holds, add `brd-figures.md` beside the defect log in the same words §1.1's new row uses. Record each site in the commit body.

- [ ] **Step 6: The `/brd-package` page's list**

In `docs/commands/brd-package.md`, change *"the customer's own source document and defect log (the parent's on a slice);"* to *"the customer's own source document, defect log and — where it links an image — the transcription of each image (the parent's on a slice);"*.

- [ ] **Step 7: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5.

- [ ] **Step 8: Verify by hand**

Collapsed-whitespace, across `plugins/` excluding changelogs: `The last three are routine` → **0**; `both go into the bundle` → **0**; and every place that lists the bundle's contents (`grep -rn -i 'defect log' plugins/product-workflows` within 200 characters of `bundle`) now names the figures file or states a reason it need not. Record the list in the commit body.

- [ ] **Step 9: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/references/bundle-packaging.md plugins/product-workflows/references/customer-review-schema.md plugins/product-workflows/commands/brd-package.md plugins/product-workflows/docs/commands/brd-package.md
git commit -m "feat(brd-package): ship the image transcriptions and every image the document reaches

<body>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---
### Task 9: `/idea` — the walk, the consent, and no caps

**Files:**
- Modify: `plugins/product-workflows/commands/idea.md` — frontmatter `description` (line 3); new Phase 1.5 before `## Phase 2`; Phase 2 (lines 102–108, 126–146); Phase 4.5 (lines ~279–282, ~351–352, ~368–371); Final report (lines ~517–519, ~528)
- Modify: `plugins/product-workflows/agents/idea-reader.md` — `description` (line 3); Inputs; Process; `### The link forms` through `### Links to anything else`; `## Bounding`; Output; Hard rules
- Modify: `plugins/product-workflows/references/idea-format.md` (lines ~189–191, ~200–205)
- Modify: `plugins/product-workflows/docs/commands/idea.md` (diagram line 28–29; lines 45–47, 76, 164)
- Modify: `plugins/product-workflows/docs/reference/agents.md` (the `idea-reader` row)

**Interfaces:**
- Consumes: `linked-sources.md` §4–§7 and the walk record (Task 1); `figure-reader` (Task 2).
- Produces: `idea-reader`'s new inputs `walk` and `figures`. **Its output field names are unchanged** — `images`, `wikilinks_followed`, `wikilinks_not_followed`, `wikilinks_broken`, `links_other` — because Phase 4.5 and `idea-format.md`'s *Vendored sources* consume them; only their values' vocabulary changes (no `cap`, no `depth` reason; `excluded`; `ambiguous`).

- [ ] **Step 1: `idea.md` frontmatter description**

In the `description:` value, replace *"a markdown file (whose links to other pages are followed two levels deep — wikilinks, inline markdown links and images, reference-style definitions and HTML img src alike — and whose linked images are read as context)"* with *"a markdown file (whose links are walked in full — wikilinks, inline markdown links and images, reference-style definitions and HTML img src alike — asking the operator before a walk reaches past two levels, twelve pages or six images, and whose linked images are transcribed and read as context)"*. Leave the rest of the value as it is.

- [ ] **Step 2: Insert Phase 1.5**

Immediately before the line `## Phase 2 — Ingest the source (idea-reader)`, insert:

````markdown
## Phase 1.5 — Walk the source's links

**Only for a `markdown` source** — a prompt carries no links, and this phase is skipped silently for
one.

Run the walk `${CLAUDE_PLUGIN_ROOT}/references/linked-sources.md` §4 defines, from the source file. It
is read-only — it copies nothing, reads no image and dispatches nothing — and its record is what
Phase 2 hands the readers, so nothing after this phase finds a link on its own.

**Ask only where an older bound would have cut.** This command once read at most two levels of links,
twelve markdown files counting the source, and six images, and reported the rest unread. Where the
walk stayed inside all three, take everything it reached, print one line of counts, and ask nothing.
Where it reached past any of them — a file deeper than 2, more than 12 markdown files, or more than 6
images — say which, name every file past that bound, and ask:

```
choices: ["Read all <n> (Recommended)", "Only what the source links directly", "Stop"]
```

*Read all* takes every file the walk reached. *Only what the source links directly* takes depth 1 —
the source's own links, markdown and images alike — and leaves every deeper file `excluded`
(`linked-sources.md` §6, §7), which Phase 4.5 reports rather than copies. *Stop* ends the run with
nothing written — an operator halt, so `emit-block` does not fire.

---

````

- [ ] **Step 3: Phase 2 — two dispatches**

Replace the dispatch block (from `Dispatch \`idea-reader\` to read the source and return a structured digest:` through the closing `"` line of the agent prompt, lines ~102–108) with:

```markdown
**First the figures.** Where Phase 1.5 took any image, dispatch `figure-reader` over the taken images
before the reader, at most 10 per dispatch and at most 4 dispatches in a single response, in further
waves until none remain:

→ Agent (subagent_type: "product-workflows:figure-reader", model: opus — frontmatter-pinned):
  > "figures: [absolute path of each taken image in this batch, in the walk's order]"

**Then the reader**, handed everything it is to read:

→ Agent (subagent_type: "product-workflows:idea-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Ingest this idea source and return the structured digest:
  >
  > argument:        [the resolved argument]
  > provenance_hint: [prompt | markdown — the only two Phase 1 computes; the reader upgrades to community-post or prd off the file itself]
  > walk:            [Phase 1.5's walk record, every entry with its `taken` state — omit for a prompt]
  > figures:         [every entry `figure-reader` returned, in the walk's order — omit where no image was taken]"
```

Leave *"Wait for the digest. If `status: NOT_FOUND`…"* and the carry-forward paragraph after it as they are: the field names they carry are unchanged.

- [ ] **Step 4: Phase 2 — what the digest carries**

(a) In the paragraph beginning **"What the digest now carries, and what it is worth."**, replace its first sentence — *"The reader follows links **two levels deep**, in every form its own `### The link forms` names — a `[[wikilink]]`, a markdown inline link or image, a reference-style definition, an HTML `<img src>` — under one total-file cap and **reads** the images the source links in any of them, returning a `description` of what each frame shows rather than a bare path."* — with:

```markdown
The reader reads every markdown file Phase 1.5's walk took, however deep and however many, and every
image's transcription, which `figure-reader` produced without seeing the source; the digest carries a
`description` of what each frame shows — the transcription's `depicts` sentence — rather than a bare
path.
```

(b) Replace the paragraph beginning **"Every bound that bit is surfaced, never swallowed."** (through *"…indistinguishable from a link that was never there."*) with:

```markdown
**Everything not read is surfaced, never swallowed.** An `images` entry with `read: false` names its
`reason` (`excluded`, `missing`, `unreadable`, `not_an_image`); `wikilinks_not_followed` names each page
the operator's Phase 1.5 answer left out; `wikilinks_broken` names each target the walk could not
resolve, an `ambiguous` wikilink with every candidate it matched; and `links_other` names each link
that resolved to a file nothing reads — a PDF, an archive, any other binary — enumerated and never
opened. Carry all of them to the Final report: a read the operator is not told was partial is
indistinguishable from a source that said less, and a link nothing copied and nothing reported is
indistinguishable from a link that was never there.
```

- [ ] **Step 5: Phase 4.5 and the Final report**

(a) Phase 4.5 step 1: change *"so `idea-reader`'s caps — 12 files, 6 images — bound it without a second bound being written anywhere."* to *"so the set Phase 1.5's walk took bounds it without a second bound being written anywhere."*

(b) Phase 4.5 step 8: change *"`wikilinks_not_followed[]` with each `cap`/ `depth` reason"* (it wraps after `cap`/) to *"`wikilinks_not_followed[]` with its `excluded` reason"*.

(c) Replace *"up to 12 copies in `attachments/` (the reader's total-file cap), up to 6 in `design/idea-sources/` (its image cap) and that set's `index.md`, which is **19 beside `idea.md`, so as many as 20 dirty OTHER paths**."* with *"one copy in `attachments/` for every markdown file Phase 1.5 took and one in `design/idea-sources/` for every image, plus that set's `index.md` — a number the walk fixes and no cap bounds, so a source that links a hub note leaves dozens of dirty OTHER paths."*

(d) Final report: change *"how many files the traversal read (and at which depths), every `wikilinks_not_followed` entry with its `cap`/`depth` reason, how many linked images were read"* to *"Phase 1.5's walk — how many files it reached, at which depths, and the operator's answer where one was asked — every `wikilinks_not_followed` entry with its `excluded` reason, how many linked images were transcribed"*; and change *"reason (`cap`, `depth`, broken, `unreadable`, `not_an_image`,"* to *"reason (`excluded`, broken, `ambiguous`, `unreadable`, `not_an_image`,"*.

- [ ] **Step 6: `idea-reader` — description, inputs, process**

(a) Replace the `description:` value with exactly:

```
Ingests one idea source (inline prompt, a markdown file with links/images, a community post, or a saved file) and returns a structured source digest for /idea. For a markdown source it reads exactly what its caller hands over — every page the caller's link walk took, and figure-reader's transcription of every image — maps the walk onto the digest's link arrays, captures community-post demand signals, and summarises each page read so the caller need not re-read it. Follows no link and opens no image itself. Read-only; never modifies files. Model tier assigned by the caller per the model-routing policy (no fixed pin).
```

(b) Replace the Inputs YAML block with:

```yaml
argument:        <the raw /idea argument: prompt text | file path>
provenance_hint: prompt | markdown | community-post | rfe | prd   # from the caller's Phase 1 classification
walk:            <the caller's walk record — ${CLAUDE_PLUGIN_ROOT}/references/linked-sources.md §5, each entry carrying `taken`; absent for a prompt>
figures:         <every figure-reader return entry for the taken images; absent where none was taken>
```

and change *"Refuse to run without `argument` and `provenance_hint`."* to *"Refuse to run without `argument` and `provenance_hint`, and — for a markdown source — without `walk`."*

(c) In the **markdown / community-post** paragraph, change *"Read it, then traverse its links and read its linked images, both under the caps in **`## Bounding`** below."* to *"Read it, then read every page the `walk` took and every transcription in `figures` (*What the caller hands over*, below)."*

- [ ] **Step 7: `idea-reader` — replace the traversal with what the caller hands over**

Replace everything from the line `### The link forms` up to, **but not including**, the line `Then split by provenance:` with:

````markdown
### What the caller hands over

**The caller walked the links; this agent walks nothing.** `/idea` Phase 1.5 ran
`${CLAUDE_PLUGIN_ROOT}/references/linked-sources.md`'s walk, the operator decided what to take, and
`figure-reader` transcribed every taken image. Read every `walk` entry whose `kind` is `markdown` and
whose `taken` is true — each file once, however many links reach it — and read each image's
transcription from `figures`. **Never follow a link, never open a path the walk did not take, and
never open an image**: its transcription is what you have of it.

**Every `walk` entry lands in exactly one array**, with `target` and `from` copied from the entry:

| Walk entry | Array | Carries |
|---|---|---|
| `kind: markdown`, `taken: true` — the first entry reaching each file | `wikilinks_followed` | `path`, `depth`, and a `salient_summary` of what you read |
| `kind: markdown`, `taken: false` | `wikilinks_not_followed` | `reason: excluded` |
| `kind: image` | `images` | taken → from its `figures` entry: `read`, and `description` = its `depicts` where read, `reason` where not; not taken → `read: false`, `reason: excluded` |
| `reason: unreadable` or `ambiguous`, any kind | `wikilinks_broken` | the `reason`, and every `candidates` path for an ambiguous one |
| `kind: other`, taken or not | `links_other` | `path` and its lowercased extension |

An entry with `reason: url` goes in no array: a URL is part of the source's prose, not a file.

**A transcription is CONTEXT, never grounded evidence.** It informs `raw_context` and the questions the
caller's grill puts to the operator. It is **not** a `[DG#n]` design-grounding finding, it needs **no**
index file, and it gets **no** verifier pass — `workflows-core:grounding-format` §6's frame-set rules
govern *evidence*, and none of them reaches here. Treat a transcription as you treat a sentence in a
linked page: something the operator handed over, never proof of shipped behaviour, and never a factual
claim in `raw_context` that the source's prose does not also carry.

**Never infer anything about an image you have no transcription of** — an `excluded`, `missing`,
`unreadable` or `not_an_image` entry carries no `description`, and its filename is not one.

**`links_other` exists so the caller can say what it is not carrying.** `/idea` copies the sources
that were read into the PRD folder (`${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`, *Vendored
sources*) and copies nothing from this list. Enumerating is the whole obligation: never open one of
these files, never summarise it, and never infer what it holds from its name or its extension.

````

- [ ] **Step 8: `idea-reader` — remove the bounds, adjust the output and the rules**

(a) Delete the whole `## Bounding` section — from the line `## Bounding` up to, **but not including**, the line `## Output`.

(b) In the Output YAML: change the `images[].reason` line to `    reason:      excluded | missing | unreadable | not_an_image        # present IFF read: false`; change `    depth:           1 | 2` to `    depth:           <1, 2, … — as the walk recorded it>`; change the `wikilinks_not_followed[].reason` line to `    reason: excluded`; and in `wikilinks_broken`, add after its `from:` line:

```yaml
    reason:     unreadable | ambiguous
    candidates: [<absolute path>, …]        # present IFF reason: ambiguous
```

(c) In Hard rules: replace *"Read a linked image as **context only** — it informs `raw_context` and the caller's grill. It NEVER becomes a `[DG#n]` finding, NEVER requires or implies a frame-set index file, and NEVER goes to a verifier. This agent is not `design-grounder` and must not behave like one."* with *"Read a transcription as **context only** — it informs `raw_context` and the caller's grill. It NEVER becomes a `[DG#n]` finding, NEVER requires or implies a frame-set index file, and NEVER goes to a verifier. This agent is not `design-grounder` and must not behave like one."*; replace *"Follow links at most **TWO** levels deep, never read the same resolved path twice, and never exceed the total-file cap in `## Bounding`. A revisit is a silent skip, never an error and never a broken link."* with *"Read exactly the pages the `walk` took and the transcriptions in `figures` — NEVER follow a link, open a path the walk did not take, or open an image — and read each file once, however many entries reach it."*; and replace *"NEVER let a cap pass unreported: an item the depth bound, the file cap, or the image cap excluded is listed with its `reason`. Silent truncation is a defect, not a bound."* with *"NEVER drop a `walk` entry: each lands in exactly one array (*What the caller hands over*), so nothing the source links is left unreported."*

(d) Read the whole file once more and fix any sentence still describing a traversal, a cap, a depth bound or this agent reading an image.

- [ ] **Step 9: `idea-format.md` — the copy set**

(a) Replace *"The copy set is exactly the digest's positive reads. It inherits `idea-reader`'s caps — 12 files in total, 6 images — and adds none of its own, because a file the reader never opened is a file this rule has nothing to copy:"* with *"The copy set is exactly the digest's positive reads — everything `/idea` Phase 1.5's walk took and was read, however many — and adds no bound of its own, because a file nothing read is a file this rule has nothing to copy:"*.

(b) In the *Four sets are deliberately not copied* table, replace the `wikilinks_not_followed[]` row with `| \`wikilinks_not_followed[]\` | the operator's Phase 1.5 answer left it out | the target, the file that linked it, and its \`excluded\` reason |`; the `wikilinks_broken[]` row with `| \`wikilinks_broken[]\` | it resolves to nothing, or to more than one file | the target as written, and every candidate of an \`ambiguous\` one |`; and the `images[]` row with `| \`images[]\` with \`read: false\` | it was never transcribed | the path and its \`excluded\`/\`missing\`/\`unreadable\`/\`not_an_image\` reason |`. The sentence above the table — *"A truncation the operator is not told about is indistinguishable from a source that said less"* — becomes *"A partial read the operator is not told about is indistinguishable from a source that said less"*.

- [ ] **Step 10: The `/idea` page and the agents row**

In `docs/commands/idea.md`:
- diagram: replace `    p1 --> p2["Phase 2 — Ingest the source (idea-reader)"]` with the two lines `    p1 --> p15["Phase 1.5 — Walk the source's links"]` and `    p15 --> p2["Phase 2 — Ingest the source (idea-reader)"]`;
- replace the three bullets at lines 45–47 (*Links to other pages, two levels deep*, *Linked images, read — not just listed*, *Bounded, and every bound reported*) with:

```markdown
- **Every link, walked first.** Phase 1.5 walks every link the source makes, and the links on every page it reaches — the `[[wikilink]]` (resolved by name across the vault where it is not next to the note, and reported as ambiguous rather than guessed where two notes share the name), the ordinary inline link or image, a reference-style `[label]: target` definition, and an HTML `<img src="target">`. The walk reads nothing but links, and a cycle — A links B, B links back to A — is a silent skip.
- **You decide past the old bounds.** Where the walk stays within two levels, twelve pages and six images, everything is read and nothing is asked. Where it reaches past any of those, the run names what lies beyond and asks: read all of it, only what the source links directly, or stop. Nothing is capped behind your back.
- **Linked images, transcribed — not just listed.** Every taken image goes to `figure-reader`, in parallel batches, which transcribes its labels and annotations without seeing your source, so the grill knows what a linked mockup actually shows.
```

- line 76: change *"A link past the twelve-file or six-image cap, a broken link, an image that would not open"* to *"A page or image you chose not to read, a broken or ambiguous link, an image that would not open"*;
- line 164: change *"Here the reader walks that note's links two levels out, opens the images it links, and hands the grill both the prose and what the frames show — then reports anything the twelve-file or six-image cap left behind."* to *"Here the run walks every link that note makes, has each linked image transcribed, and hands the grill both the prose and what the frames show — asking first if the walk reaches further than two levels, twelve pages or six images."*

In `docs/reference/agents.md`, replace the `idea-reader` row with:

```markdown
| `idea-reader` | per routing | Read, Glob, Grep, Skill | Ingests one idea source into a digest for `/idea` from what its caller hands over — every page the link walk took and each image's transcription — as context; other linked files named, never opened. | `/idea` |
```

- [ ] **Step 11: Sweep**

Collapsed-whitespace counts across `plugins/`, `README.md`, `CLAUDE.md` (changelogs included; a changelog hit is history and stays), before and after, for: `two levels deep`, `two levels`, `12 files`, `twelve-file`, `Total files read`, `six images`, `6 images`, `six-image`, `image cap`, `total-file cap`, `reason: cap`, `` `cap`/`depth` ``, `restated in full here`. Intended after-count outside changelogs: **0** for each, except `two levels` and `twelve` / `six images` in `idea.md` Phase 1.5 and the `/idea` page's two new bullets, where they name the trigger — list each surviving hit in the commit body with why it stands.

- [ ] **Step 12: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5. Check 12 counts the new three-option array; the mermaid gate parses the new node.

- [ ] **Step 13: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add plugins/product-workflows/commands/idea.md plugins/product-workflows/agents/idea-reader.md plugins/product-workflows/references/idea-format.md plugins/product-workflows/docs/commands/idea.md plugins/product-workflows/docs/reference/agents.md
git commit -m "feat(idea): walk every link first, ask past the old bounds, transcribe every image

<body>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---
### Task 10: The shared authorities, `CLAUDE.md`, the release, and the whole-branch sweep

**Files:**
- Modify: `plugins/workflows-core/references/grounding-format.md` (§6.1 lines ~482, ~486–488; §6.2's writer table ~line 651)
- Modify: `CLAUDE.md` (lines 35, 413; the workflow map's `/idea` and `/brd-intake` lines; the agent tree)
- Modify: `plugins/product-workflows/.claude-plugin/plugin.json`, `plugins/workflows-core/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (two entries: `version`, and `product-workflows`'s `description`)
- Modify: `plugins/product-workflows/CHANGELOG.md`, `plugins/workflows-core/CHANGELOG.md`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/docs-workflows/CHANGELOG.md`
- Modify: any file the Step 7 sweep finds

**Interfaces:**
- Consumes: everything Tasks 1–9 wrote.
- Produces: `product-workflows` **3.7.0** and `workflows-core` **1.7.1**, with changelogs that tell the truth about what is published.

- [ ] **Step 1: `grounding-format` §6.1 — `idea-reader` no longer reads pictures**

In `plugins/workflows-core/references/grounding-format.md`:

(a) Change *"This paragraph exists to foreclose the mistake of reading `idea-reader`'s image support, `frame-describer`'s descriptions, or either writer's index as itself being that reconciliation"* to *"This paragraph exists to foreclose the mistake of reading `figure-reader`'s transcriptions, `frame-describer`'s descriptions, or either writer's index as itself being that reconciliation"*.

(b) Replace *"**Reading a picture is not design grounding, and both writers do the first without doing the second.** `idea-reader` reads the images an idea source links; `frame-describer` reads the frames of a set being indexed."* with *"**Reading a picture is not design grounding, and the family's picture readers do the first without the second.** `product-workflows:figure-reader` transcribes the images an idea source or a customer's BRD links, for `/idea` and `/brd-intake`; `frame-describer` reads the frames of a set being indexed."* Then read the rest of that paragraph and the one after it: where *"both writers"* or *"Each"* now fails to cover `figure-reader` — which writes no frame-set index — reword so each claim names exactly the agents it is true of. `brd/brd-figures.md` is not a frame-set index and is not in `design/`; say so in one clause if the paragraph could be read otherwise.

(c) In §6.2's *What each writer accounts for* table, change the `/idea` row's last cell from `` `idea-reader`'s per-image `description` `` to `` `idea-reader`'s per-image `description` — `figure-reader`'s `depicts` sentence for that image ``. In the sentence below the table, change *"An image `/idea`'s reader never opened"* to *"An image `/idea` never had transcribed"*.

- [ ] **Step 2: `CLAUDE.md`**

(a) Line 35: `plus thirteen subagents, eleven reference files, one hook` → `plus fourteen subagents, twelve reference files, one hook`.

(b) Line 413: `none of the product-definition commands, their thirteen agents or their eleven references` → `none of the product-definition commands, their fourteen agents or their twelve references`.

(c) In the workflow map, replace the `/idea` line's opening `/idea                → idea-reader → ` with `/idea                → [walk every link read-only (product-workflows:linked-sources); past two levels / 12 pages / 6 images, the operator decides] → [figure-reader@Opus ×N (parallel, ≤10 per dispatch, cap 4)] → idea-reader → `, leaving the rest of the line as it is.

(d) Replace the `/brd-intake` line's opening `/brd-intake          → brd-reader → ` with `/brd-intake          → [walk every link read-only, wikilinks included (product-workflows:linked-sources); the operator decides on files outside the folder and on files neither markdown nor an image] → copy what was taken (outside files into brd/source-external/, mapped in the link log) → [figure-reader@Opus ×N (parallel) → brd/brd-figures.md] → brd-reader@Opus (document + linked markdown + transcriptions) → `, and in the same line change `write \`brd/source/\` verbatim — the customer's document **and every file it links from its own directory**, byte-for-byte at the same relative paths, with \`brd/brd-link-log.md\` naming each link that could not be captured and why — ` to `write \`brd/source/\` verbatim — the customer's document **and every file it links from its own directory**, byte-for-byte at the same relative paths, with \`brd/brd-link-log.md\` naming each link not copied and why and mapping each captured link that does not resolve as written — `.

(e) In the agent tree, insert immediately after the `└── brd-reader (product-workflows)` line:

```
                      └── figure-reader (product-workflows)          (used by /brd-intake, /idea)
```

- [ ] **Step 3: Versions and the catalog description**

(a) `plugins/product-workflows/.claude-plugin/plugin.json`: `"version": "3.6.1"` → `"version": "3.7.0"`; in `description`, replace `Thirteen agents carry the grounding, reconciliation, PRD/ARD/spec/Epic/proposal review and Epic writing. Eleven reference pages define the artifact formats these commands author against.` with `Fourteen agents carry the grounding, figure transcription, reconciliation, review and Epic writing. Twelve reference pages define the artifact formats and the link walk these commands share.` — 881 characters in total.

(b) `.claude-plugin/marketplace.json`, `product-workflows` entry: the same `version` and the same `description` replacement, byte for byte. Edit the two values in place; reformat nothing.

(c) `plugins/workflows-core/.claude-plugin/plugin.json` and its `marketplace.json` entry: `1.7.0` → `1.7.1`.

(d) Run `python3 scripts/validate-catalog.py .` and confirm `0 error(s), 0 warning(s)`.

- [ ] **Step 4: Date the sections today's push published**

Every changelog section headed `— Unreleased` that is present at commit `4387959f` was published by the push of that commit on 2026-09-18, and the file's own header says an `— Unreleased` section *"has not been published yet"*. For each of the four `CHANGELOG.md` files, list the `## [x.y.z] — Unreleased` headings in `git show 4387959f:<path>`; change each of those, and only those, to `## [x.y.z] — 2026-09-18`. Expected: `dev-workflows` 4.1.1, 4.1.0, 4.0.4; `product-workflows` 3.6.1, 3.6.0; `docs-workflows` 1.2.1, 1.2.0; `workflows-core` 1.7.0, 1.6.0 — **re-derive the list from the command, never from this line**, and stop if they differ.

- [ ] **Step 5: `product-workflows` 3.7.0 changelog entry**

Insert at the top of `plugins/product-workflows/CHANGELOG.md`, directly under the header block, a `## [3.7.0] — Unreleased` section with these subsections, each written as the file's existing entries are — what changed, why, what it costs a user, and the population a fix reaches:

- `### Fixed — an open requirement defect was never put to the customer`: `/brd-interview` generated no question from `brd/brd-defect-log.md`; the bundle shipped the log only so citations resolve; the review schema has no defect section. Population: every BRD intaken with a confirmed `ambiguity`, `conflict`, `duplicate`, `untestable` or `scope-leak` defect. The fix: the seventh question source, always `[C]`; `settles`; `resolved-by: [CD#n]`; for a slice interviewed before this release, `/brd-interview <KEY> --round 1` with the cause *requirement defects became a question source*.
- `### Fixed — a wikilinked file in a BRD was dropped without a trace`: `/brd-intake` recognised no `[[wikilink]]`, so such a file was not copied, not read and not logged — including every image Obsidian pastes as `![[Pasted image …]]`. Population: every BRD authored or converted in Obsidian. Re-running `/brd-intake` over the same folder captures them.
- `### Added — /brd-intake reads what it captures`: linked markdown and images are read; `figure-reader`; `brd/brd-figures.md`; an obligation only an image states is proposed with an `ambiguity` for the customer to settle; Phase 1's walk and its two questions; `brd/source-external/`.
- `### Changed — /idea walks every link and asks rather than caps`: the 12-page / 2-level / 6-image caps are gone; Phase 1.5; images transcribed by `figure-reader` in parallel.
- `### Changed — brd-reader runs on Opus`: why, and that a text-only BRD now costs more than before. Record that the Opus default for both agents is **unmeasured** (spec §13).

Name the spec by path in the section's first line.

- [ ] **Step 6: `workflows-core` 1.7.1 changelog entry**

Insert at the top of `plugins/workflows-core/CHANGELOG.md`, under the header block, a `## [1.7.1] — Unreleased` section with one `### Changed` subsection: `grounding-format` §6.1 and §6.2 named `idea-reader` as the agent reading an idea source's images; `product-workflows` 3.7.0 moved that to `figure-reader`, which also transcribes a BRD's images, and the two paragraphs now name it. No behaviour of any `workflows-core` command or agent changes.

- [ ] **Step 7: The whole-branch sweep**

Scope: `plugins/`, `README.md`, `CLAUDE.md`, **changelogs included** (a changelog *quotation* of a retired form stays; a count or claim about today's tree in a changelog is fixed like any other).

(a) **Phrases** — collapsed-whitespace counts; intended after-count **0** outside a changelog quotation unless noted: `reads only the document`, `nothing in this run reads its content`, `The link forms covered`, `Then repeat the whole capture`, `frontmatter-pinned to Sonnet`, `frontmatter-pinned to sonnet`, `its extraction work is mechanical`, `Extraction is mechanical`, `six question sources`, `six sources`, `writes two of them`, `two of which this command writes`, `The last three are routine`, `Total files read`, `twelve-file`, `six-image`, `total-file cap`, `image cap`, `reason: cap`, `restated in full here`, `Thirteen agents`, `13 reusable subagents`, `11 files under`, `Eleven reference pages`, `thirteen subagents`, `eleven reference files`.

(b) **Subjects** — every sentence naming `brd-reader`, `idea-reader`, `figure-reader`, `brd/source/`, `brd-link-log`, `brd-figures`, `customer-questions.md`, `resolved-by`, or the decision register's field count: read each hit's **whole paragraph** and confirm it true of the tree as it now stands.

(c) **Exclusivity probe** — `only`, `is the only`, `nothing else`, `and no other`, `only ever`, `the one`, `sole` within 200 characters of any subject in (b): confirm each claim still holds. Two known candidates to check first: `/brd-intake`'s *"nothing else of the route reads a customer-supplied source document"* (docs page, *Who runs it*) and `grounding-format` §6.1's *"Two commands WRITE a frame set's index"*.

(d) **End-to-end reads**: `commands/brd-intake.md` Phase 0 → Final report; `commands/idea.md` Phases 1–2 and 4.5; `commands/brd-interview.md` Phases 2–3, 7 and 9; `commands/brd-reconcile.md` Phases 5 and 8. Read in order, as a run would execute them, looking for any step that contradicts another.

Fix every finding in place. Record, in the commit body, each string's before/after count and each paragraph changed.

- [ ] **Step 8: Run the gates and verify green**

Expected: `GATES_EXIT=0`, 198, 5, and `validate-catalog.py .` at `0 error(s), 0 warning(s)`.

- [ ] **Step 9: Commit**

```bash
git branch --show-current   # must print iv-gu/brd-figures
git add <every file this task changed, each named>
git commit -m "release: product-workflows 3.7.0, workflows-core 1.7.1 — and date what today's push published

<body: versions; the dating; the sweep's counts and fixes>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU"
```

---

### Task 11: Execute the changed prose over fixtures (controller-run)

**Run by the controller, not an implementer**, because it dispatches the agents it exercises. The installed plugins are the released versions, so `subagent_type: "product-workflows:figure-reader"` would run the old tree or nothing: every agent here is dispatched as a `general-purpose` subagent whose prompt is the **worktree's** agent file body plus its inputs, on the model that file's frontmatter pins. The command prose is executed by a `general-purpose` orchestrator subagent reading the **worktree's** command file. Where nested dispatch is unavailable to that subagent, the controller executes the command prose itself.

All fixtures live under the session scratchpad (`$S` below), never in the repository. **Write the expected result of every case to `$S/brd-figures-verify/expected.md` before running anything.** The verification record is written **last**, after the final fix wave (`CLAUDE.md`).

**Files:** none in the repository. `$S=/tmp/claude-1000/-home-ihudak-dev-ai-tools-ihudak-claude-plugins/eca918d8-f7c1-43c4-b7da-5479c07b5d88/scratchpad`.

- [ ] **Step 1: Tooling**

```bash
python3 -m venv $S/brd-figures-verify/venv && $S/brd-figures-verify/venv/bin/pip install --quiet pillow
```

If the install fails, stop and report it. **Do not fall back to SVG fixtures**: an `.svg` reaches `figure-reader` as text, so it would test text reading and not image reading.

- [ ] **Step 2: The BRD fixture**

Build, under `$S/brd-figures-verify/vault/` (a `.obsidian/` directory at its root makes it a vault):

- `customers/acme/brd.md` — a BRD with six top-level sections. §2 states *"The monthly report lists every invoice."* and links `![report](images/report.png)`; §3 states *"Approval must follow the attached flow."* and links `![flow](images/flow.png)`; §4 states *"The settings page lets a user choose a theme."* and embeds `![[Pasted image 20260918.png]]`; §5 says *"Required report fields are listed in the appendix"* and links `[fields](appendix/fields.md)`; §6 links `[pricing](pricing.pdf)` and `[[glossary]]`.
- `customers/acme/appendix/fields.md` — one section listing three required fields.
- `customers/acme/images/report.png` — rendered with Pillow: a table headed `Invoice | Customer | Net total | Tax` with two rows, and a red box around `Tax` annotated *"remove this column"* — which contradicts nothing in the prose but states an obligation only the image states.
- `customers/acme/images/flow.png` — a diagram `Submit → Manager approval → [> 10k] Finance approval → Done`.
- `attachments/Pasted image 20260918.png` — **outside** `customers/acme/`: a settings screen with a `Theme` dropdown and a `Font size` stepper, an arrow annotated *"add a dark mode here"*.
- `customers/acme/pricing.pdf` — any bytes.
- `notes/glossary.md` and `archive/glossary.md` — two files named `glossary.md`, so `[[glossary]]` is ambiguous.

Expected, written first: Phase 1 names one outside file (`attachments/Pasted image 20260918.png`), one *other* file (`pricing.pdf`) and one `ambiguous` target with both candidates; *Capture all* then *Proceed* copies the pasted image into `brd/source-external/Pasted image 20260918.png` with a mapping row, logs `[[glossary]]` as `ambiguous`; `brd-figures.md` has three sections, each with a hash; the inventory holds rows anchored `source/appendix/fields.md › …` for the three fields; an image-only row for *"remove the Tax column"* with an `ambiguity` candidate; an image-only row for the dark-mode annotation with an `ambiguity` candidate (and `unsourced` only if it asserts current behaviour — it does not); rows anchored `source/images/flow.png › …` for the approval steps and **no** `ambiguity` on any of them, because §3's prose makes the diagram binding; the report image's rows anchored on it, one of them carrying the *remove this column* `ambiguity`; every section and image accounted for.

- [ ] **Step 3: Run it, three ways**

With a scratch `SPECS_PATH` (`git init`, one empty commit on `main`), `--no-docs`, and scripted answers — *Capture all*, *Proceed*, *Proceed with <folder>*, *Confirm as written* on every candidate, *They hold no obligation* on coverage, *Just write the files* at handoff:
1. First run: compare every expected item; record each as met or not, with the file and line that shows it.
2. Same fixture, same folder, re-run: expect no `figure-reader` dispatch at all (every hash re-used).
3. A fresh folder with *Only the document's own folder*: expect the pasted image logged `outside the source directory`, nothing in `source-external/`, and the settings-row absent.
4. A fresh folder, answering *Stop and convert them first* at the *other* question: expect `BRD_INTAKE_UNREAD_ATTACHMENTS` and **nothing written** under the specs repo.

- [ ] **Step 4: The defect path, by construction**

Hand-build a root BRD and one slice in a scratch specs repo: the root's inventory lists `[BR#1]`–`[BR#3]`; its defect log holds `[DEF#1]` (`ambiguity`, open) on `[BR#2]` and `[DEF#2]` (`conflict`, open) on `[BR#3]` naming `[BR#1]`; its ledger has all three `covered-by` the slice; the slice's ledger has `[BR#1]`, `[BR#2]` `covered-here` and `[BR#3]` `rejected: [DEF#2]`. Execute `/brd-interview`'s Phase 3 prose over the slice. Build the root inventory's `defects` column as `[BR#2]` → `[DEF#1]` and `[BR#3]` → `[DEF#2]`. Expected: one `[C]` question naming `[DEF#1]`, whose only row `[BR#2]` is `covered-here` in the slice; **none** for `[DEF#2]`, whose only row `[BR#3]` is `rejected` in the slice's ledger — its fate is settled, and the `[BR#1]` its `conflict` names is context, not one of its rows. Then feed `/brd-reconcile` Phases 5 and 8 a confirmed answer to that question: expect a `[CD#1]` with `settles: [[DEF#1]]` and `[DEF#1]` resolved `resolved-by: [CD#1]`; and a second fixture answer that drops `[BR#2]`: expect `withdrawn`, then `rejected: [DEF#1]` in the ledger.

- [ ] **Step 5: `/idea`**

Build a source note linking 14 notes that reach depth 3, and 8 rendered images. Run `/idea` with `--no-docs`, answering the grill with *use your recommendation*:
1. Phase 1.5 fires, naming what lies past two levels, twelve pages and six images; *Read all* — all 14 pages vendored into `attachments/`, all 8 images into `design/idea-sources/`, each index row's description a `depicts` sentence.
2. *Only what the source links directly* — depth-1 pages and images only; every other entry reported `excluded` in the Final report; nothing excluded copied.
3. A source inside the old bounds (3 pages, 2 images) — no Phase 1.5 question at all.

- [ ] **Step 6: Findings**

Every expected item not met is a finding. Fix each through the subagent-driven fix loop against the task that owns the file, re-run the affected case, and only then write `$S/brd-figures-verify/record.md`: each case, expected, observed, and the evidence. **Nothing merges while a case is unmet.**

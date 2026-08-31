# Design: the specs-native pipeline — removing the tracker round-trip from the open-source plugin

**Status:** approved in brainstorming, not yet planned.
**Supersedes in part:** `2026-06-29-jira-input-resolution-b2-design.md`,
`2026-07-01-jira-input-adoption-epics-release-notes-b3-design.md`,
`2026-07-07-two-key-grammar-foundation-design.md`, `2026-07-08-grammar-adoption-design.md`.
**Depends on:** `2026-08-29-brd-to-prd-workflow-design.md` — the BRD route is the existence proof
this design generalises.

---

## 1. Problem

`dev-workflows` authors a PRD as markdown in `$SPECS_PATH`, then asks the operator to **paste it
into Jira** and **re-import it** to `$VAULT_PATH/jira-products/` so that `/epics`,
`/release-notes`, `/design` and `/ready` can read it back. The content makes a round trip through a
tracker to reach commands running on the same machine that wrote it.

That loop exists for a reason that does not apply here. It was built for an environment with no
tracker CLI and no API access, where paste-and-re-import was the only way to move content. Every
other environment has a CLI or an MCP server — and the open-source plugin cannot assume Jira at all:
a user may be on ClickUp, Rally, Linear, or nothing.

Three consequences today:

1. **The PRD exists twice** — authored in `$SPECS_PATH`, mirrored in `$VAULT_PATH/jira-products/`,
   and the mirror is what four commands actually read. The two can diverge and nothing detects it.
2. **`$VAULT_PATH` is load-bearing for content it did not author.** Release-note drafts, Epic
   drafts and bug reports land there because the vault was where the tracker's mirror lived.
3. **A tracker is assumed.** `jira-reader`, `jira-input-resolution.md` and the `jira-products` tree
   name one vendor in a plugin that should name none.

**Scale.** 84 of 110 command/agent/reference files mention Jira. 29 of 41 documentation pages do.
`jira-input-resolution.md` is cited by 16 files, `jira-reader` by 32, and 51 files carry `jira_key`.
This is larger than the BRD route, which was 83 files.

**The existence proof.** All six `/brd-*` commands have **zero** `$VAULT_PATH` references. They run
entirely on `$SPECS_PATH`, including a customer sign-off loop, and hand into `/create-prd --from-brd`
without a tracker key. The model works; this design generalises it to the `/idea` route.

---

## 2. Scope and decomposition

**In scope:** the input model of every pipeline command; the `$SPECS_PATH` tree shape; key grammar
and addressing; `/idea`, `/create-prd`, `/epics`, `/specify`, `/design`, `/create-ard`,
`/implement`, `/document`, `/release-notes`, `/ready`, `/brd-split`; the deletion of `jira-reader`
and `jira-input-resolution.md`; `$VAULT_PATH` reduced to follow-up tasks; every affected reference,
documentation page, and `CLAUDE.md`.

**Out of scope:** the `/brd-*` route's own mechanics (unchanged except `/brd-split`'s always-slice
rule); `$DOCS_PATH` documentation grounding (vault-independent already); `/vuln`, `/upgrade`,
`/docs-profile`, `/statusline`, `/feedback`, `/prompt*`, and the two reviewer commands.

**Editions.** This is canonical-only. The mgd edition keeps the tracker loop because its environment
still requires it, and copilot stays coupled to mgd. After this design the editions no longer share
ten commands or two shared front-ends. That is accepted, deliberately, and recorded here so it is
never discovered as a surprise: the divergence to date has been **additive** (canonical has commands
mgd lacks), and this is the first change that **modifies** shared files.

---

## 3. Decisions

| # | Decision |
|---|---|
| **D1** | `$SPECS_PATH` is the system of record. No command reads a tracker, of any vendor, by any mechanism |
| **D2** | Directories carry a **kind prefix** — `BRD-`, `PRD-`, `EPIC-`. Keys carry no kind |
| **D3** | Filenames carry the **kind**, never a key. The path supplies identity; the filename supplies kind |
| **D4** | Every command takes **one key**. A key encodes its own ancestry, so no command takes a chain |
| **D5** | A BRD is a container, never implementable. `/brd-split` always produces at least one iteration |
| **D6** | Epics come from a PRD only. There are no Epics at BRD level |
| **D7** | `/idea` requires its key up front and writes in its final location. No relocation, no staging |
| **D8** | `/ready` derives the phase from artifacts. `--claimed "<status>"` restores the divergence check |
| **D9** | `/implement` records a **pointer**, not a record — enough to find the work in git, nothing more |
| **D10** | Frontmatter is user-extensible. Every command that rewrites frontmatter **preserves unknown keys** |
| **D11** | `workitem_key` is reserved and documented, **never written** by the plugin and never resolved by |
| **D12** | `kind:` replaces `issue_type:`; `ValueIncrement` is retired |
| **D13** | The release-note taxonomy stays. Its three destinations become **sections** of one file |
| **D14** | The legacy flat layout is accepted as a deprecated fallback. No migration command ships |
| **D15** | `$VAULT_PATH` is optional and serves follow-up tasks only |

### Why D4, stated once

A key encodes its ancestry: `ACME-90-01-01` is an Epic of `ACME-90-01`, which is an iteration of
`ACME-90`. A command taking `<BRD> <SLICE> <PRD> <EPIC>` would take three arguments derivable from
the fourth — and each redundant argument is one that can **disagree** with the key, which is a
failure class the plugin does not have today. One key, resolved against the tree.

### Why D5, stated once

Without it, a BRD parent can be both split into iterations *and* PRD-eligible itself, so its folder
holds iterations and Epics as siblings — two kinds in one namespace. Worse, `/brd-split` Phase 0
step 9 enumerates subdirectories by name match and treats each as a child BRD; an Epic folder has no
`brd-link.md`, reads as an empty `claims:` list, and Phase 4.5 then offers to **remove the folder**,
deleting `epic.md`, `specification.md` and `design.md` with it. D5 removes the collision
structurally, because the PRD gets its own directory level and iterations and Epics are never
siblings.

**Independently of D5**, `/brd-split` step 9 must require a `brd-link.md` carrying `parent:` before
counting a subdirectory as a child BRD — a positive test, not a name match plus an
absent-file-reads-as-empty inference.

### What D5 does *not* simplify

`/brd-split` keeps orphan rows (a provisional claim withdrawn to *another* iteration), keeps
standing-empty-children, and keeps `deferred-to` on a parent. What goes is `covered-here` on a
parent and its escape-valve prose. This is a smaller collapse than it appears.

---

## 4. The artifact model

### 4.1 The tree

```
specifications/
├── PRD-ACME-77-billing/                     idea route: PRD at level 1
│   ├── idea.md
│   ├── prd.md
│   ├── ard.md
│   ├── release-notes.md
│   └── EPIC-ACME-77-01-intake/
│       ├── epic.md
│       ├── specification.md
│       ├── design.md
│       └── implementation.md
│
└── BRD-ACME-90-platform/                    BRD route: BRD at level 1
    ├── brd/  grounding/  interview/
    ├── coverage-ledger.md  decisions.md  slices.md  brd-link.md
    └── BRD-ACME-90-01-orders/               iteration — always at least one
        ├── brd-link.md  coverage-ledger.md  decisions.md
        └── PRD-ACME-90-01-orders/           PRD at level 3
            ├── prd.md  ard.md  release-notes.md
            └── EPIC-ACME-90-01-01-intake/
                ├── epic.md  specification.md  design.md  implementation.md
```

### 4.2 Naming

`<KIND>-<KEY>-<slug>/`, kind ∈ `BRD` | `PRD` | `EPIC`.

**The kind prefix disambiguates; the key is inherited.** An iteration and its PRD share a key
(`ACME-90-01`) and differ only by prefix — which is what today's `<BRD-KEY>_<slug>.md` already
expresses, promoted from a filename to a directory.

**A user whose own key begins with a kind token gets `PRD-PRD-1234-…`.** That is a documented
consequence of a documented convention, not a defect. The convention is stated in the README and in
`docs/`; a user who then names their work `PRD-…` has chosen the collision. We cannot dodge every
key any user might pick, and a convention we can rely on is worth more than one that bends.

### 4.3 Filenames

Filenames carry the kind and never a key (D3). The folder already carries the key, and the Epic
level already works this way — `specification.md`, `design.md` — so this generalises an existing
convention rather than inventing one.

| File | Written by | Notes |
|---|---|---|
| `idea.md` | `/idea` | written in final location; never relocated |
| `prd.md` | `/create-prd`, `/update-prd` | was `<KEY>_<slug>.md` |
| `ard.md` | `/create-ard` | was `<KEY>_ARD.md`. **In the folder whose key the run was given** — the PRD folder for a PRD-level ARD, the Epic folder for an Epic-level one. `ard-resolution.md`'s most-specific-first ladder reads the Epic's, then the PRD's |
| `release-notes.md` | `/release-notes` | was a vault path |
| `epic.md` | `/epics` | was `$VAULT_PATH/jira-drafts/<key>.md` or `<slug>.md` |
| `specification.md` | `/specify` | unchanged |
| `design.md` | `/design` | unchanged |
| `implementation.md` | `/implement` | new — §7.3 |
| `_readiness.md` | `/ready` | unchanged |

**Three resolvers simplify as a direct consequence.** `/create-prd`'s prior-PRD check globs
`<KEY>_*.md` *and* verifies frontmatter `issue_type: ValueIncrement`; `ard-resolution.md` globs
`*_ARD.md`; `prd-source-resolution.md` globs `<KEY>_*.md`. All three become a filename test.

### 4.4 Frontmatter

```yaml
kind: prd                    # prd | ard | epic | specification | design | brd | idea
workitem_key: CU-8x9f2a1     # optional, the user's, never written by the plugin
```

**`kind:` replaces `issue_type:` (D12).** `issue_type` is tracker vocabulary — Jira says *issue*,
ClickUp says *task*, Rally says *work item* — and `ValueIncrement` is one vendor's custom type. With
keyless filenames the filename is already the discriminator, so `kind:` exists for readers and sync
tools rather than for resolution.

**`workitem_key` is reserved and never written (D11).** The plugin documents the field, preserves it
across every frontmatter rewrite, and displays it in reports. It never mints it, never validates it,
and never resolves anything by it. The name is deliberately vendor-neutral: genericisation works in
speech but not in a field name a tool parses, and someone writing a ClickUp sync who reads
`jira_key` reasonably wonders whether it is Jira-shaped.

**Unknown keys are preserved (D10).** Every command that rewrites frontmatter — `/update-prd` most
of all — keeps fields it does not recognise. Without this rule a user's `clickup_id` disappears on
the next run and nothing reports it. This is a small rule with a large blast radius and it is
stated in `prd-format.md`, `ard-format.md` and `specification-format.md`.

---

## 5. Addressing

### 5.1 Key grammar

One grammar, one namespace: `^[A-Z][A-Z0-9_]*(-\d+)+$` — a leading alphabetic token followed by one
or more hyphen-numeric segments. `ACME-90`, `ACME-90-01`, `ACME-90-01-01` are all valid, and **shape
is not depth**: how many segments a key carries says nothing about where its folder sits.

**The two-grammar rule is retired.** Today `brd_key` accepts two-or-more segments and `jira_key`
accepts exactly two, and `CLAUDE.md`'s longest rule polices the gap — *"widening a tracker-side check
to accept three segments is a defect, not a fix"* — because no tracker mints a three-segment key. The
plugin now mints its own keys at up to four segments, no tracker is read, and there is no second
grammar to protect. The rule, and the defect family it existed to prevent, both go.

### 5.2 Resolution

`resolve-key <KEY> [<KIND>]` globs `specifications/**/*-<KEY>-*`, **bounded at four levels** below
`specifications/`, and returns **the resolved folder and the kind it found**.

**The kind is an output, not a required input.** A caller that already knows the kind may pass it to
narrow the glob and to refuse a mismatch — `/create-prd --from-brd` wants a `BRD-` iteration and
nothing else. A caller that does **not** know it must not have to guess: `/epics <KEY>` partitions
when the key resolves to a `PRD-` folder and refines when it resolves to an `EPIC-` one (§6.3), and
that branch is only possible because resolution reports the kind. A signature demanding the kind up
front would make the mode undecidable at the point the mode is decided.

Four is the maximum depth the tree can hold: BRD → iteration → PRD → Epic. The bound is a
**constant**, not a property of the key or of the tree, which is the property
`brd-addressing.md` §2 actually argues for; the number 2 was never the point.

- **Exactly one match** → return it.
- **No match** → `absent`. The caller decides whether that is a stop or a folder to create.
- **More than one match** → a hard stop naming every match. Two folders with one key is a tree
  defect, and guessing between them would pick silently.

### 5.3 Legacy layout (D14)

A repo written before this change holds `specifications/<KEY>-<slug>/` with no kind prefix.
Resolution therefore falls back to the **unprefixed flat form** when the prefixed glob misses —
reached only on a miss, so a prefixed tree resolves exactly as it should, and reported once per run
as deprecated.

**No migration command ships.** A user's specs repo is theirs, it is a git repository they review,
and a renaming script we cannot test against their tree is a liability. Renaming a folder is one
`git mv`, and the fallback means they need never do it.

### 5.4 What replaces `jira-input-resolution.md`

That file resolved a Jira key against `$VAULT_PATH/jira-products/`, classified path tokens, owned
Fallbacks A–E and the two-key `<PRD> <Epic>` grammar. It is deleted. In its place each command's
Phase 0 does:

1. Parse the single positional key; validate the §5.1 grammar.
2. `resolve-key` it against the tree.
3. Branch on the resolved folder's kind prefix where the command supports more than one level.

**The two-key grammar collapses to one** — `/specify PRD-KEY EPIC-KEY` becomes `/specify EPIC-KEY`,
and the key's kind decides whether the run is PRD-level or Epic-level. Fallbacks A–E disappear with
the vault they described.

---

## 6. Command contracts

| Command | Today | After |
|---|---|---|
| `/idea` | `[<prompt>\|@file\|JiraID]`, writes to the vault, relocates later | `<PRD-KEY> [<prompt>\|@<file>]` — writes `idea.md` in final location |
| `/create-prd` | `<JIRA-KEY> [@idea]` / `<BRD-KEY> --from-brd` | `<PRD-KEY>` / `<ITERATION-KEY> --from-brd` |
| `/update-prd` | `<KEY>`, Jira-import-first | `<PRD-KEY>`, reads `prd.md` |
| `/create-ard` | `<PRD> [<Epic>]` / `--from-brd` | one key; kind decides the level |
| `/epics` | `<PRD>` + `mode: refine\|both` | `<PRD-KEY>` partitions; `<EPIC-KEY>` or `@<file>` refines |
| `/specify` | `<PRD> [<Epic>]` | one key |
| `/design` | `<PRD> <Epic>` | one key |
| `/implement` | `<PRD> <Epic>` / direct | one key / direct — writes `implementation.md` |
| `/document` | `<PRD>` / direct | `<PRD-KEY>` / direct |
| `/release-notes` | `<PRD>` | `<PRD-KEY>` — writes `release-notes.md` |
| `/ready` | `<PRD> [<Epic>]` | one key, `+ --claimed "<status>"` |
| `/brd-*` | `<BRD-KEY>` | unchanged |

### 6.1 `/idea`

**Takes its key up front (D7).** Today `idea.md` is written keyless to the vault and Phase 5
relocates it once a Jira key exists. With `$SPECS_PATH` as the only home there is nowhere keyless to
write, so the key is an argument — the same act `/brd-intake <BRD-KEY>` already asks for, validated
for shape and never checked against anything.

**Deleted with it:** the relocation phase, the write-path derivation, the container rule, the
`area_proposal`, the `prd_disposition` machinery, and the Jira source type with its
`resolve-export-for-key` and `ValueIncrement`→`prd` / `Product Need`→`rfe` typing.

**Sources become:** an inline prompt, a markdown file, a community post. The "an existing PRD this
extends, parallels or rewrites" case is served by `@<path>` and by `/create-prd --from-prd`.

**Accepted cost:** an abandoned idea leaves a folder in `specifications/` where it used to die in the
vault. Reintroducing a staging area to avoid that would restore the relocation step this removes.

### 6.2 `/create-prd`

**The idea ladder collapses to two states.** Rungs 3 (same-session) and 4 (`find "$VAULT_PATH/Projects"
-name idea.md` plus a picker) exist only because the idea might be anywhere. It is now in-contract or
absent. Rung 1's `require-on-main` gate stays; rung 2's out-of-contract `@path` stays.

**`CREATE_PRD_NEEDS_KEY` loses "create an empty Jira workitem first to get the ID."**

**`--from-brd`** now resolves an **iteration** key and creates `PRD-<KEY>-<slug>/` **inside** the
iteration folder. Its two Phase 0 refusals are unchanged in substance and read over the iteration's
own ledger rows.

### 6.3 `/epics`

**Mints Epic keys** as `<PRD-KEY>-NN` — the next unused two-digit segment, operator may override,
validated for shape and re-prompted rather than coerced. This is `/brd-split` Phase 3 step 1's
mechanism, reused.

**Writes `epic.md`** into `EPIC-<PRD-KEY>-NN-<eslug>/` under the PRD folder. `$VAULT_PATH/jira-drafts/`
is gone.

**Three invocations, one rule — the argument decides the mode:**

- `/epics <PRD-KEY>` — partition the PRD into Epics.
- `/epics <EPIC-KEY>` — refine that Epic.
- `/epics @<file>` — refine the Epic that file holds. **Stop if the file is not an Epic**, tested by
  its `kind: epic` frontmatter, naming what it found instead.

**Refine's job changes, and the spec says so rather than letting a reader assume continuity.** Today
refine fills in *empty Epics somebody else created in the tracker* — which existed so that linking an
Epic to a PRD would surface the PRD on that team's dashboard. That is an artefact of one
organisation's tooling and has no analogue here. Refine now means: iterate on an Epic that exists —
re-ground it, sharpen it after the specification moved.

### 6.4 `/ready` (D8)

**Derives the phase from artifacts.** `workflow-states.md` is read in the other direction: its
*expected artifacts* column becomes the rubric, and the phase is what the artifacts imply. The
verdict becomes *"this PRD is at Ready for Implementation, and here is what is missing to leave it."*

**`--claimed "<status>"` restores the divergence check.** Anyone with a tracker pastes what it says
and gets exactly today's behaviour — a mismatch between a claimed phase and the work that supports
it — with no dependency on which tracker it is.

**What is genuinely lost without the flag:** a derived phase cannot contradict itself, so a run
without `--claimed` reports what exists rather than catching a human's wrong claim. That is the cost
of removing the mirror, and it is stated rather than glossed.

---

## 7. What the tracker supplied, and what replaces it

Four things came from `jira-products/` that `$SPECS_PATH` did not hold. Each needs an answer, and
"it degrades" is an answer only where it is stated.

### 7.1 The linked-item hierarchy → the tree

Epics were linked items in the export. They are now `EPIC-` folders under the PRD folder, minted by
`/epics` (§6.3). The tree *is* the hierarchy.

### 7.2 Workflow status → derived (§6.4)

### 7.3 PR URLs → `implementation.md`

`/implement` records where its work landed. This is a **pointer, not a record** (D9): only what git
cannot be asked without it.

```markdown
# Implementation — ACME-77-01 intake

## 2026-08-31 — /implement
- repo:    orders-service
  branch:  feat/order-intake
  base:    main
  commit:  a3f91c2          # squashed
  pushed:  true
- repo:    billing-api
  branch:  feat/order-intake
  base:    main
  commit:  7be0d41
  pushed:  false            # local only — resolvable on this machine
```

**Append-only, one block per run**, one entry per repository — the shape `grounding/baselines.md`
already uses, which is the same thing one layer over.

**Branch for convenience, commit for durability.** A merged branch is deleted; the squashed commit
stays reachable from the base. `diff-summarizer` accepts either, and recording both means the file
survives branch cleanup.

**It holds no summary of what was implemented.** A summary is a *description*, and
`source-truth.md` exists because descriptions drift from code — one here would be a new, unverified
description in a folder of grounded artifacts. A ref cannot drift: git resolves it or does not, and
`pushed: false` is recorded so a later run says *"this was never pushed"* rather than reporting an
empty diff.

**Two limits, stated in the file's own authority:**

- `/implement` in **direct mode writes nothing** — no key, no Epic folder, nothing to append to. A
  directly-implemented change therefore has no diff source, exactly as today.
- **The plugin knows only what it did.** Work done by hand or by another tool leaves no block, so
  diff grounding is best-effort over what this plugin implemented.

**Consumers, and which blocks they read.** `/document` reads **every** block under the PRD — it
documents the feature as it now stands. `/release-notes` reads **only blocks appended since the last
section was written to `release-notes.md`**, because a second release must not re-describe the first
one's work; with `release_versions` retired (§7.4) the file's own last-written date is the only
honest boundary, and the run **names the blocks it used** so a wrong boundary is visible rather than
silent. Both hand `diff-summarizer` a `{repo_path, branch_from, branch_to}` triple — a shape its Inputs already
declare, on the pure-local-git path it already prefers when `gh` is absent. No URL, no host
classification, no `gh` requirement.

### 7.4 The mirror fields → dropped, inferred, or asked

`prd-format.md` carries `release_versions`, `change_type` and `release_notes_category` as
tracker-mirror fields set as dropdowns and returned by the importer.

- **`change_type`** — `release-note-types.md` already sources it `imported_change_type` → **infer**,
  and confirms a low-confidence inference with the user. The import half goes; the infer half is
  already the fallback and becomes the only path.
- **`release_notes_category`** — supplied the `{{#context}}` label. Retired with it (§7.5).
- **`release_versions`** — has no derivable source and no consumer that gates on it. Retired; a user
  who wants it puts it in their own frontmatter, which D10 preserves.

### 7.5 Release notes → one file, three sections (D13)

**The taxonomy stays.** Breaking change / feature update / fix is universal — any product has all
three — and `release-note-types.md` remains the authority for the per-type draft shape, the prose
rules, and the deprecation-note rule with its required end-of-life date.

**The destination map becomes a section map.** The three destinations were three files in a docs
repo. Release notes now land in one `release-notes.md` in the PRD folder, so the Change Type selects
a **section** of that file rather than a file. Exactly one draft per run, as today.

**`{{#context}}…{{/context}}` is retired.** It is a docs-automation macro; in a plain markdown file
it renders as literal text. A plain label does the same job.

---

## 8. Deleted surface

| Deleted | Cited by | Replaced by |
|---|---|---|
| `agents/jira-reader.md` | 32 files | §5.2 resolution + the tree |
| `references/jira-input-resolution.md` | 16 files | each command's Phase 0 |
| `agents/vault-prior-art-finder.md` | `/idea`, `/create-prd` | nothing — see below |
| `references/vault-prior-art.md` | 2 commands | — |
| `references/handoff/jira-reader.md` | dispatch contract | — |
| `$VAULT_PATH/jira-products/**` | the mirror | `$SPECS_PATH` |
| `$VAULT_PATH/jira-drafts/**` | `/epics` output | `EPIC-…/epic.md` |
| the paste + re-import round-trip | `/create-prd`, `/update-prd` | nothing |
| `dependencies.md`'s `jira-workitem-import` row | — | — |
| `issue_type: ValueIncrement` | 11 files | `kind:` (D12) |

**Vault prior art is dropped, and it is the one deletion that removes a capability rather than a
redundancy.** `vault-prior-art-finder` searched `Projects/Products/**` for prior initiatives and fed
`/idea` and `/create-prd` a bounded digest — genuinely useful, and *not* tracker-redundant. It goes
because it is vault-dependent and D15 leaves the vault for follow-up tasks only. It was already
advisory, already optional, and already a silent skip when absent, so nothing gates on it. Recorded
here as a loss taken deliberately, not an oversight.

**Residual vendor vocabulary swept in the increment that touches each:**
`prose-formatting.md` justifies its no-hard-wrap rule by *"copy-paste into Jira/Grammarly"* — the
rule stays, the rationale is rewritten. `docs-profile.md` uses `gen3` as its example templating
token — detection is generic, only the example is vendor-shaped.

**Checked and clear, recorded so the sweep is not repeated:** `references/api-guidelines/` is
genuinely generic — 26 files citing NIST, IETF, AWS and `example.com`, no org content.
`/document`'s space model has zero `saas`/`managed` references. `Dynatrace`, `Grail`, `GUIDElines`,
`dynatrace-docs` and `Experience Standards` are absent from the plugin entirely.

---

## 9. Documentation and instruction files

**Docs ride with each increment, never after.** `scripts/check-docs.sh` forces the inventory half —
a deleted agent or reference turns the build red — but the **semantic** half is ungated, and the
2026-08-31 review round found five stalls where a page's claims had drifted from the thing that runs.
So each increment updates its own pages in the same change.

| Surface | Scale | Notes |
|---|---|---|
| `docs/` pages | **29 of 41** mention Jira or `$VAULT_PATH` | heaviest: `roles-and-phases.md`, `reference/environment.md`, `reference/references.md`, `reference/agents.md`, `getting-started.md`, `workflow.md`, `reference/follow-ups.md` |
| `CLAUDE.md` | **43 of 352** lines | the workflow map, the two-keys rule (retired, §5.1), the `$VAULT_PATH` claims, the agent and reference inventories |
| root `README.md` | install block + surface blurb | `check-docs.sh` check 7 pins `getting-started.md` to it verbatim |
| `plugin.json` + `marketplace.json` | description | currently **898** of a 900-char warning threshold — this change frees words, and the blurb must be **rewritten, never appended to** |

**No `AGENTS.md` or `.github/copilot-instructions.md` exists in canonical.** Those are mgd/copilot
files and are out of scope; they matter only if this ever ports, which §2 says it will not.

**Two documentation rules this design must not break.** `check-docs.sh` check 10 forbids any page
under `docs/` from naming the marketplace or the containing repository. Check 9 gates seven prose
counts against the tree — deleting two agents and two references moves the agent, reference-file and
environment-variable totals, so those sentences change in the same commit.

---

## 10. Non-goals

- **No tracker integration of any kind**, including via a CLI. A user who wants one installs an MCP
  server, a CLI or a skill and syncs it against the markdown. The plugin never learns whether a
  tracker exists.
- **No migration command** (D14).
- **No status field in the specs tree.** It would re-create the duplicated state this design removes,
  inside `$SPECS_PATH` instead of a tracker. The artifacts answer the question the field would.
- **No change to the `/brd-*` route** beyond D5 and the step-9 positive test.
- **No port to mgd or copilot.**

---

## 11. Build order

Four increments. Each ships green, leaves the tree consistent, and is independently revertible.

### Increment A — the addressing model

Rewrite `brd-addressing.md` for kind prefixes, the four-level bound, one-key resolution, keyless
filenames and the legacy fallback. Update its **twelve** adopters — nine commands plus
`ard-resolution.md`, `jira-input-resolution.md` and `prd-source-resolution.md`. Apply D5 and the
step-9 positive test to `/brd-split`; follow through `coverage-ledger-format.md` §5 and
`/create-prd`'s gate. Rename artifact files (§4.3) and simplify the three resolvers.

*Jira is untouched, so the plugin still runs end to end.* This is the seam everything else needs.

### Increment B — cut the tracker

Delete `jira-reader` and `jira-input-resolution.md`. Rewrite every Phase 0 to resolve a key against
the tree. Drop the paste/re-import round-trip and `prd-source-resolution.md`'s import-first ladder.
Retire the mirror fields (§7.4), `issue_type` (D12) and the two-grammar rule (§5.1). Add
`workitem_key` and the unknown-key preservation rule (D10, D11).

*The largest increment. It can only follow A — commands need the new resolver before the old one goes.*

### Increment C — refill what the tracker supplied

`/epics` mints keys and writes `epic.md`; `/implement` writes `implementation.md`; `/document` and
`/release-notes` diff from it; `release-notes.md` lands in the PRD folder with sections not
destinations; `/ready` derives the phase and gains `--claimed`; `workflow-states.md` is inverted.

*These are exactly the capabilities B removes, and they need B's absence to be designed against.*

### Increment D — `$VAULT_PATH` reduction and sweep

Vault → follow-up tasks only (D15). Delete `vault-prior-art-finder` and `vault-prior-art.md`. Sweep
every residual vault reference, the `dependencies.md` row, and the residual vendor vocabulary in
§8. Rewrite the plugin description.

### Verification, every increment

This plugin is prose; there is no test framework and the plan must not pretend otherwise.
`scripts/check-docs.sh` (with `--selftest`), `scripts/check-id-grammar.sh` and
`scripts/validate-catalog.py` all green; a read-through of each changed command end to end; and a
**residue audit** asking *what did this make false elsewhere* — the technique that found five of the
2026-08-31 round's findings and four of its documentation stalls.

**One standing item this design does not fix**, recorded so it is not mistaken for new: 40 of 232
`choices:` arrays exceed `AskUserQuestion`'s four-option maximum. It is plugin-wide, predates this
work, and belongs to its own sub-project.

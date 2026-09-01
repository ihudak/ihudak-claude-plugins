# Design: the specs-native pipeline — removing the tracker round-trip from the open-source plugin

**Status:** in review — §§1–5 revised after the first review pass (2026-08-31).
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
`$VAULT_PATH` appears 188 times across 50 files. This is larger than the BRD route, which was 83
files.

**The existence proof.** All six `/brd-*` commands have **zero** `$VAULT_PATH` references. They run
entirely on `$SPECS_PATH`, including a customer sign-off loop, and hand into `/create-prd --from-brd`
without a tracker key. The model works; this design generalises it to the `/idea` route.

---

## 2. Scope and decomposition

**In scope:** the input model of every pipeline command; the `$SPECS_PATH` tree shape; key grammar
and addressing; `/idea`, `/create-prd`, `/epics`, `/specify`, `/design`, `/create-ard`,
`/implement`, `/document`, `/release-notes`, `/ready`, `/brd-split`; the deletion of `jira-reader`
and `jira-input-resolution.md`; the deletion of `$VAULT_PATH`; every affected reference,
documentation page, and `CLAUDE.md`.

**Out of scope:** the `/brd-*` route's own mechanics (unchanged except `/brd-split`'s always-slice
rule and the folder it names); `$DOCS_PATH` documentation grounding (vault-independent already);
`/vuln`, `/upgrade`, `/docs-profile`, `/statusline`, `/feedback`, `/prompt*`, and the two reviewer
commands.

**Editions.** This is canonical-only. The mgd edition keeps the tracker loop because its environment
still requires it, and copilot stays coupled to mgd. **No edition can break as a consequence of this
change**: each edition holds full copies of the files, never shared ones, so nothing here reaches
mgd's tree or copilot's. What ends is the hand-maintained *synchronisation* of those copies —
divergence to date has been additive (canonical has commands mgd lacks), and after this the same
filename in two editions describes two different workflows. That is accepted, deliberately, and
recorded so a later porting session does not treat the drift as a defect to reconcile.

---

## 3. Decisions

| # | Decision |
|---|---|
| **D1** | `$SPECS_PATH` is the system of record. No command reads a tracker, of any vendor, by any mechanism |
| **D2** | Directories carry a **kind prefix** — `BRD-`, `PRD-`, `EPIC-`. Keys carry no kind |
| **D3** | Filenames carry the **kind**, never a key. The path supplies identity; the filename supplies kind |
| **D4** | Every command takes **one** address. A key encodes its own ancestry, so no command takes a chain |
| **D5** | A BRD is a container, never implementable. `/brd-split` always produces at least one PRD folder |
| **D6** | Epics come from a PRD only. There are no Epics at BRD level |
| **D7** | `/idea` requires its key up front and writes in its final location. No relocation, no staging |
| **D8** | `/ready` derives the phase from artifacts. `--claimed "<status>"` restores the divergence check |
| **D9** | `/implement` records a **pointer**, not a record — enough to find the work in git, nothing more |
| **D10** | Frontmatter is user-extensible. Every command that rewrites frontmatter **preserves unknown keys** |
| **D11** | `workitem_key` is reserved and documented, **never written** by the plugin and never resolved by |
| **D12** | `kind:` replaces `issue_type:`; `ValueIncrement` is retired |
| **D13** | The release-note taxonomy stays. Its three destinations become **sections** of one file |
| **D14** | The legacy flat layout is accepted as a deprecated fallback. No migration command ships |
| **D15** | **`$VAULT_PATH` is deleted.** The plugin reads and writes one tree, `$SPECS_PATH` |
| **D16** | Every keyed command accepts `<KEY>` **or** `@<path>`. A path is used verbatim; only a key is resolved |
| **D17** | A folder **asserts** its own key in frontmatter. No key is ever parsed out of a folder name |
| **D18** | `--from-brd` is inferred from the resolved folder, not typed. The flag is retired |

### Why D5, stated once

Without it, a BRD parent can be both split into iterations *and* PRD-eligible itself, so its folder
holds PRD folders and its own Epic folders as siblings — two kinds in one namespace. Worse,
`/brd-split` Phase 0 step 9 enumerates subdirectories by name match and treats each as a child; an
Epic folder has no `brd-link.md`, reads as an empty `claims:` list, and Phase 4.5 then offers to
**remove the folder**, deleting `epic.md`, `specification.md` and `design.md` with it. D5 removes
the collision structurally: everything directly under a BRD is a PRD folder, and Epics live one
level further down.

**Independently of D5**, `/brd-split` step 9 must require a `brd-link.md` carrying `parent:` before
counting a subdirectory as a child — a positive test, not a name match plus an
absent-file-reads-as-empty inference. Under §4.1 that same file is what distinguishes a
BRD-route PRD folder from an idea-route one, so the positive test earns its keep twice.

### What D5 does *not* simplify

`/brd-split` keeps orphan rows (a provisional claim withdrawn to *another* iteration), keeps
standing-empty-children, and keeps `deferred-to` on a parent. What goes is `covered-here` on a
parent and its escape-valve prose. This is a smaller collapse than it appears.

### Why D4, stated once

A key encodes its ancestry: `ACME-90-01-01` is an Epic of `ACME-90-01`, which is an iteration of
`ACME-90`. A command taking `<BRD> <PRD> <EPIC>` would take two arguments derivable from the third —
and each redundant argument is one that can **disagree** with the others, which is a failure class
the plugin does not have today. One address, resolved once.

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
│   ├── follow-ups.md
│   ├── design/                           exported frame sets — one subdir each
│   │   └── orders-v3/  <images> index.md
│   └── EPIC-ACME-77-01-intake/
│       ├── epic.md
│       ├── specification.md
│       ├── design.md
│       └── implementation.md
│
└── BRD-ACME-90-platform/                    BRD route: BRD at level 1
    ├── brd/  grounding/  interview/
    ├── coverage-ledger.md  decisions.md  slices.md
    └── PRD-ACME-90-01-orders/               iteration AND PRD — one folder, level 2
        ├── brd-link.md  coverage-ledger.md  decisions.md
        ├── prd.md  ard.md  release-notes.md
        ├── design/                          exported frame sets — one subdir each
        └── EPIC-ACME-90-01-01-intake/
            ├── epic.md  specification.md  design.md  implementation.md
```

**The iteration folder and the PRD folder are one folder.** `/brd-split` carves an iteration out of
a BRD *so that a PRD can be written for it*; that iteration has no other purpose and no other
consumer. Giving it a directory of its own, with a `PRD-` directory nested inside holding one file,
bought a level of tree for nothing. Merged, the folder holds the iteration's own bookkeeping
(`brd-link.md`, `coverage-ledger.md`, `decisions.md`) beside the documents authored from it — which
is what the idea route's PRD folder already does with `idea.md`.

The names then tell the story the workflow actually follows: **a BRD is what the customer sent; a
PRD folder holds one part of it, and the PRD authored for that part.**

**`design/` is a reserved subdirectory, and it already exists — on one route only.** `/brd-ground`
Phase 5 looks for `<BRD-dir>/design/` and treats each immediate subdirectory as one exported frame
set: images plus an index file, which `design-grounder` **refuses to run without**, because a
filename is not a reliable statement of what a frame depicts (`grounding-format.md` §6). Nothing on
the `/idea` route defines such a place at all, so a design file authored there has nowhere to live
and nothing could find it if it did.

The §4.1 merge makes one convention out of two: a BRD-route PRD folder **is** the slice folder
`/brd-ground` already runs against, so `<PRD-folder>/design/<frame-set>/` is a path that works on
that route today. The location is therefore defined as a property of **any** folder under
`specifications/` — BRD, PRD or Epic — stated once in `grounding-format.md` §6 and cited rather than
restated by the commands that read it.

**Defining the location is not wiring a consumer**, and the two are deliberately separated.
`design-grounder` is dispatched by `/brd-ground` and by nothing else; giving the `/idea` route design
grounding means a dispatch, a findings file and a verifier pass it does not have. That is a
capability, not a directory, and it is decided on its own rather than improvised alongside an
addressing change.

### 4.2 Naming

`<KIND>-<KEY>-<slug>/`, kind ∈ `BRD` | `PRD` | `EPIC`.

**Two invariants, and the second is what the §4.1 merge bought.**

1. Kinds appear in a fixed order down any path: `BRD` → `PRD` → `EPIC`, each optional at the top.
2. **No path holds two folders of the same kind.** The tree is therefore at most three levels deep,
   and every level is identifiable from its own name without reading its parent.

**A user whose own key begins with a kind token gets `PRD-PRD-1234-…`.** That is a documented
consequence of a documented convention, not a defect — and it is not hypothetical: a key like
`EPIC-008` yields `PRD-EPIC-008-01-orders`. The convention is stated in the README and in `docs/`;
a user who then names their work `PRD-…` has chosen the collision. We cannot dodge every key any
user might pick, and a convention we can rely on is worth more than one that bends.

### 4.3 Filenames

Filenames carry the kind and never a key (D3). The folder already carries the key, and the Epic
level already works this way — `specification.md`, `design.md` — so this generalises an existing
convention rather than inventing one.

| File | Written by | Notes |
|---|---|---|
| `idea.md` | `/idea` | written in final location; never relocated |
| `prd.md` | `/create-prd`, `/update-prd` | was `<KEY>_<slug>.md` |
| `ard.md` | `/create-ard` | was `<KEY>_ARD.md`. **In the folder whose address the run was given** — the PRD folder for a PRD-level ARD, the Epic folder for an Epic-level one. `ard-resolution.md`'s most-specific-first ladder reads the Epic's, then the PRD's |
| `release-notes.md` | `/release-notes` | was a vault path |
| `epic.md` | `/epics` | was `$VAULT_PATH/jira-drafts/<key>.md` or `<slug>.md` |
| `specification.md` | `/specify` | unchanged |
| `design.md` | `/design` | unchanged |
| `implementation.md` | `/implement` | new — §7.3 |
| `_readiness.md` | `/ready` | unchanged |
| `follow-ups.md` | the follow-up emitter | was a vault task list — §8.1 |
| `implementation-gaps.md` | `/document` | was `$VAULT_PATH/Projects/…/<KEY>-implementation-gaps.md` |

**Three resolvers simplify as a direct consequence.** `/create-prd`'s prior-PRD check globs
`<KEY>_*.md` *and* verifies frontmatter `issue_type: ValueIncrement`; `ard-resolution.md` globs
`*_ARD.md`; `prd-source-resolution.md` globs `<KEY>_*.md`. All three become a filename test.

### 4.4 Frontmatter

```yaml
kind: prd                    # prd | ard | epic | specification | design | brd | idea
key: ACME-90-01              # written by the plugin; must agree with the folder name
workitem_key: CU-8x9f2a1     # optional, the user's, never written by the plugin
```

**`key:` is how a folder states its identity (D17).** Every artifact this plugin writes carries it,
and **the command that creates a folder writes a keyed artifact into it in the same act** — so a
folder is never keyless, not even for the moment between its creation and its first document.
Resolution by key globs the folder name, but everything *downstream* of resolution — minting
`<PRD-KEY>-NN` for a new Epic, naming a branch, citing an identifier in a report — **reads this
field**, off whichever artifact the run had to open anyway. Nothing parses a key out of a directory
name.

That matters because a directory name is not a safe place to parse from. `PRD-ACME-90-01-orders`
splits into key and slug only under a rule about where numeric segments stop, and `CLAUDE.md`'s
standing rule is explicit that a key re-derived by pattern is a key nothing asserted. With `key:`
present the folder asserts it, which is also what makes D16's `@<path>` form fully equivalent to a
key: a path resolves to a folder, and the folder says who it is.

**A `key:` that disagrees with its folder name is a hard stop**, naming both. That is the whole cost
of carrying identity twice, and it converts a hand-rename from a silent divergence into a message.

**`kind:` replaces `issue_type:` (D12).** `issue_type` is tracker vocabulary — Jira says *issue*,
ClickUp says *task*, Rally says *work item* — and `ValueIncrement` is one vendor's custom type. With
keyless filenames the filename is already the discriminator, so `kind:` exists for readers, for the
`@<path>` kind check, and for sync tools rather than for resolution.

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
plugin now mints its own keys, no tracker is read, and there is no second grammar to protect. The
rule, and the defect family it existed to prevent, both go.

### 5.2 Two address forms (D16)

Every keyed command takes **one positional address**, in one of two forms.

**`@<path>` — used verbatim.** A directory, or a file inside one (the folder is its parent). No
glob, no tree walk, no ambiguity, no legacy fallback: the operator has already answered the question
resolution exists to ask. The command reads the folder's `kind:` (§4.4) and refuses a mismatch,
which is the only check a path still needs.

**`<KEY>` — resolved.** `resolve-key <KEY> [<KIND>]` globs `specifications/**/*-<KEY>-*`, **bounded
at three levels** below `specifications/`, and returns the resolved folder and the kind it found.

- **Exactly one match** → return it.
- **No match** → `absent`. The caller decides whether that is a stop or a folder to create.
- **More than one match** → a hard stop naming every match. Two folders with one key is a tree
  defect, and guessing between them would pick silently. `@<path>` is the stated way through it.

**Why both, rather than paths alone.** Paths are the better address wherever the folder exists and
the operator can see it, and they remove resolution entirely — that is why they are accepted
everywhere. They cannot be the *only* form for two reasons that do not go away:

1. **Two commands create the folder they are given.** `/idea` and `/brd-intake` open a route; there
   is nothing on disk to point at and nothing for `@` to complete against. They take a key, exactly
   as `/brd-intake <BRD-KEY>` does today.
2. **`$SPECS_PATH` is normally not under the working directory.** Every command runs with cwd in a
   code repository and reaches the specs repo through `git -C "$SPECS_PATH"`, never a `cd`. `@`
   completion is rooted at the workspace, so the convenient completion that makes paths attractive
   is unavailable in the case that matters, and the operator would be typing
   `@../specs/specifications/BRD-ACME-90-platform/PRD-ACME-90-01-orders/` by hand.

**The kind is an output of resolution, not a required input.** A caller that already knows the kind
may pass it to narrow the glob and refuse a mismatch. A caller that does **not** know it must not
have to guess: `/epics <KEY>` partitions when the key resolves to a `PRD-` folder and refines when
it resolves to an `EPIC-` one (§6.3), and that branch is only possible because resolution reports
the kind.

Three is the maximum depth the tree can hold (§4.2 invariant 2). The bound is a **constant**, not a
property of the key or of the tree, which is the property `brd-addressing.md` §2 actually argues
for; the number 2 was never the point.

### 5.3 Legacy layout (D14)

A repo written before this change holds `specifications/<KEY>-<slug>/` with no kind prefix.
Resolution therefore falls back to the **unprefixed flat form** when the prefixed glob misses —
reached only on a miss, so a prefixed tree resolves exactly as it should, and reported once per run
as deprecated. `@<path>` bypasses the fallback along with the rest of resolution.

**No migration command ships.** A user's specs repo is theirs, it is a git repository they review,
and a renaming script we cannot test against their tree is a liability. Renaming a folder is one
`git mv`, and the fallback means they need never do it.

### 5.4 What replaces `jira-input-resolution.md`

That file resolved a Jira key against `$VAULT_PATH/jira-products/`, classified path tokens, owned
Fallbacks A–E and the two-key `<PRD> <Epic>` grammar. It is deleted. In its place each command's
Phase 0 does:

1. Read the single positional address. `@`-prefixed → a path (§5.2). Otherwise validate the §5.1
   grammar and `resolve-key` it.
2. Read the resolved folder's `kind:` and branch where the command supports more than one level.

**The two-key grammar collapses to one** — `/specify PRD-KEY EPIC-KEY` becomes `/specify EPIC-KEY`,
and the kind decides whether the run is PRD-level or Epic-level. Fallbacks A–E disappear with the
vault they described.

---

## 6. Command contracts

Every row's *After* column accepts `@<path>` in place of the key (D16), except the two marked
key-only.

| Command | Today | After |
|---|---|---|
| `/idea` | `[<prompt>\|@file\|JiraID]`, writes to the vault, relocates later | `<PRD-KEY> [<prompt>\|@<file>]` — **key-only**; writes `idea.md` in final location |
| `/create-prd` | `<JIRA-KEY> [@idea]` / `<BRD-KEY> --from-brd` | one address; the BRD route is **inferred** (D18) |
| `/update-prd` | `<KEY>`, Jira-import-first | one address, reads `prd.md` |
| `/create-ard` | `<PRD> [<Epic>]` / `--from-brd` | one address; kind decides the level |
| `/epics` | `<PRD>` + `mode: refine\|both` | `PRD-` partitions; `EPIC-` or `@<file>` refines |
| `/specify` | `<PRD> [<Epic>]` | one address |
| `/design` | `<PRD> <Epic>` | one address |
| `/implement` | `<PRD> <Epic>` / direct | one address / direct — writes `implementation.md` |
| `/document` | `<PRD>` / direct | one address / direct |
| `/release-notes` | `<PRD>` | one address — writes `release-notes.md` |
| `/ready` | `<PRD> [<Epic>]` | one address, `+ --claimed "<status>"` |
| `/brd-intake` | `<BRD-KEY>` | unchanged — **key-only** |
| other `/brd-*` | `<BRD-KEY>` | one address |

### 6.1 `/idea`

**Takes its key up front (D7), and takes only a key.** Today `idea.md` is written keyless to the
vault and Phase 5 relocates it once a Jira key exists. With `$SPECS_PATH` as the only home there is
nowhere keyless to write, so the key is an argument — the same act `/brd-intake <BRD-KEY>` already
asks for, validated for shape and never checked against anything.

**Deleted with it:** the relocation phase, the write-path derivation, the container rule, the
`area_proposal`, the `prd_disposition` machinery, and the Jira source type with its
`resolve-export-for-key` and `ValueIncrement`→`prd` / `Product Need`→`rfe` typing.

**Sources become two things: an inline prompt, or a file.** Nothing else, because nothing else is
reachable — `idea-reader` never went over HTTPS and this design does not give it a way to. A
community post is still a first-class source and still read for its demand signals (upvotes,
duplicate reports, the shape of the complaint); the operator saves it as a file first, and the
"community post" case describes *how the file is read*, not a URL the plugin fetches. The "an
existing PRD this extends, parallels or rewrites" case is served by `@<path>` and by
`/create-prd --from-prd`.
`idea-reader` loses its `vault_path` input and with it `@wikilink` resolution: a wikilink has no
root to resolve against once the vault is gone, so a source is a path. Wikilinks *inside* a source
file are still followed one level where they resolve relative to that file's own directory.

**Accepted cost:** an abandoned idea leaves a folder in `specifications/` where it used to die in the
vault. Reintroducing a staging area to avoid that would restore the relocation step this removes.

### 6.2 `/create-prd`

**The idea ladder collapses to two states.** Rungs 3 (same-session) and 4 (`find "$VAULT_PATH/Projects"
-name idea.md` plus a picker) exist only because the idea might be anywhere. It is now in-contract or
absent. Rung 1's `require-on-main` gate stays; rung 2's out-of-contract `@path` stays.

**`CREATE_PRD_NEEDS_KEY` loses "create an empty Jira workitem first to get the ID."**

**`--from-brd` is retired as a flag (D18).** Under §4.1 the BRD route's PRD folder is created by
`/brd-split`, carries `brd-link.md`, and holds the ledger rows the two *data* Phase 0 refusals read
— which are reached only after a third, structural one has passed: a `BRD-` container is refused on
the resolved folder's kind before any ledger row is read (D5), so the two data refusals are
slice-only and there are three in all. So the
route is a property of the resolved folder, not something the operator restates: `/create-prd` takes
one address, detects `brd-link.md`, and **prints which mode it entered** before doing anything. A
flag that can disagree with the folder it names is one more of the disagreements D4 exists to
remove, and `--from-brd` on a folder without `brd-link.md` was exactly that.

`--from-prd` stays a flag. It names a *different* PRD to seed from — a genuine choice the folder
cannot make on the operator's behalf.

### 6.3 `/epics`

**Mints Epic keys** as `<PRD-KEY>-NN` — where `<PRD-KEY>` is read from the PRD folder's `key:` field
(D17) — the next unused two-digit segment, operator may override, validated for shape and
re-prompted rather than coerced. This is `/brd-split` Phase 3 step 1's mechanism, reused.

**Writes `epic.md`** into `EPIC-<PRD-KEY>-NN-<eslug>/` under the PRD folder. `$VAULT_PATH/jira-drafts/`
is gone.

**Three invocations, one rule — the address decides the mode:**

- a `PRD-` folder — partition the PRD into Epics.
- an `EPIC-` folder **that has a PRD above it** — refine that Epic.
- `@<file>` — refine the Epic that file holds. **Stop if the file is not an Epic**, tested by its
  `kind: epic` frontmatter, naming what it found instead.

**And two refusals, because D6 is enforced structurally rather than assumed.** A **stand-alone
`EPIC-` folder** — one with no PRD above it — is refused (`EPICS_EPIC_NOT_UNDER_PRD`), and so is a
**`BRD-` container** (`EPICS_BRD_NOT_SLICED`, taken on the directory prefix before any read, naming
the `PRD-` slices under it, one set of Epics each). **`/epics` is the only command that creates an
`EPIC-` folder**: `/create-ard` and `/specify` each stop on an absent one rather than minting it on
first write, and the *stand-alone top-level Epic* case those two commands carried — a `specification.md`
or an `ard.md` written flat into a top-level `EPIC-` folder — is retired with it.

**The accept gate is `prd.md`'s own `kind: prd`, never the folder's asserted kind.** A `PRD-` slice
folder asserts `kind: brd` in the `brd-link.md` `/brd-split` writes into it (§4.1), so an
asserted-kind gate would refuse every slice and accept nothing. `/create-prd` cannot take this test —
it is the run that writes `prd.md` — but `/epics` can, because by then the PRD exists; the Epic side
is the same test one level down, on `epic.md`'s own `kind: epic`. Neither test reads a directory
name, so §5.3's legacy unprefixed folder is classified exactly as a prefixed one is. A `PRD-` folder
in which no PRD has been authored yet is refused too (`EPICS_NO_PRD`), naming `/create-prd`.

**`focus_key` is derived from the address, not typed beside it (D4).** `/epics` already parsed a
refinement target but nothing ever set it, so refine-by-focus was unreachable and an `EPIC-` address
was silently partitioned as though it were a PRD. It is now derived from a resolved `EPIC-` folder
the way `/specify` derives its own altitude — the folder's kind decides, and `<PRD-KEY>` is the
parent's asserted `key`.

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

- `/implement` in **direct mode writes nothing** — no address, no Epic folder, nothing to append to.
  A directly-implemented change therefore has no block of its own.
- **This file knows only what the plugin did.** Work done by hand or by another tool leaves no
  block — which is why it is not the only source (§7.3.1).

**Consumers, and which blocks they read.** `/document` reads **every** block under the PRD — it
documents the feature as it now stands. `/release-notes` reads **only blocks appended since the last
section was written to `release-notes.md`**, because a second release must not re-describe the first
one's work; with `release_versions` retired (§7.4) the file's own last-written date is the only
honest boundary, and the run **names the blocks it used** so a wrong boundary is visible rather than
silent. Both hand `diff-summarizer` a `{repo_path, branch_from, branch_to}` triple — a shape its Inputs already
declare, on the pure-local-git path it already prefers when `gh` is absent. No URL, no host
classification, no `gh` requirement. The §7.3.1 scan feeds the same triple, with a commit SHA at
either end, and inherits each consumer's boundary — every commit for `/document`, only commits
dated after the last written section for `/release-notes`.

### 7.3.1 Commit messages → work this plugin did not do

`implementation.md` records what `/implement` did. It cannot record what a human did by hand, and
that happens — a session runs out of budget and the work is finished manually. Release notes and
documentation built only from recorded blocks would silently omit that work, and the omission would
read as completeness.

So `/document` and `/release-notes` **also scan git history for the run's own identifiers**:

```
git -C <repo> log --grep='<key>' --grep='<workitem_key>' --extended-regexp --regexp-ignore-case
```

over the repositories `implementation.md` names, or — when it names none — the repositories resolved
from `$REPOS_PATH`, which is the discovery `/create-ard` already does.

**This is a search for known tokens, never an extraction.** The keys come from the folder's own
`key:` (D17) and its `workitem_key` (D11); nothing parses an identifier out of a commit message. It
is the pattern `CLAUDE.md` prescribes — resolve against a set the run already holds — pointed at git
history instead of at a folder name.

**D11 is narrowed here, not contradicted.** "Never resolved by" means no *folder* is ever addressed
by `workitem_key`. Using it as a grep token runs the other way: the plugin already knows which
folder it is in and is asking git what mentions it. That is the field's main reason to exist — a
team whose commit convention carries the tracker key (the Jira/PR linkage this design otherwise
gives up) gets its hand-made commits found.

**Merged and deduped by SHA**, and what the scan finds beyond the recorded blocks is reported as
**unrecorded work**, named as such with its commits listed. A run that quietly folds hand-made
commits into the recorded set makes the record look more complete than it is.

**The convention is taught, and that is stronger than "written" — because only one command can
write it.** Increment C's execution established the fact this paragraph originally got wrong:
`/implement` and `/upgrade` leave their changes **uncommitted** on the branch, so **`/vuln` is the
only command here that commits into a code repository**. Most commits in a repository this plugin
touched are therefore written by a person at handover — which is exactly why a convention nobody
was taught is a scan that finds nothing. The key goes where a human will see it and copy it:

- **The commit subject ends with `[<key>]`** — `feat(orders): add order intake [ACME-77-01]`. In
  the subject rather than a trailer, because a trailer does not survive `git log --oneline` and is
  therefore invisible to the person deciding what their own commit should look like. All three write it, behind `code-handoff.md` §2's consent choice; where an operator declines the
  commit, they state it instead.
- **A `Work-Item: <workitem_key>` trailer**, when the folder carries one (D11). The tracker key is
  for the operator's own integration and belongs where their tooling looks; it is never invented,
  and the trailer is absent when the field is.
- **The branch carries the key too** — `feat/<key>-<slug>` — which gives a second recovery path and
  reuses `specs-repo-git.md` §3.5's `branch-key` resolution, already built to resolve a key out of a
  branch name **against a set the run holds** rather than by pattern.

The convention is documented as a convention, in `docs/`, not only implied by what the plugin
happens to emit — a contributor who has never run `/implement` still has to be able to write a
commit this scan can find.

**What is honestly still lost**, and what the run therefore says out loud: only a commit whose
message names the key is findable. A commit that names nothing is invisible, and no convention
compels a human to follow one — so the run **reports how many commits it scanned and how many
matched**. A zero-match scan in a repository with commits is a signal about the convention, not
proof that no work happened.

### 7.4 The mirror fields → inferred, then confirmed in the grill

`prd-format.md` carries `release_versions`, `change_type` and `release_notes_category` as
tracker-mirror fields — dropdowns set in the tracker and returned by the importer. **There is no
importer** (§8). None of the three is retired for want of one: each becomes something the run infers
and the operator confirms, which is what the grill already exists to do.

- **`change_type`** — inferred from the change itself. `release-note-types.md` already sources it
  `imported_change_type` → **infer** and confirms a low-confidence inference; the import half goes
  and inference becomes the only path. Because it selects the destination section (§7.5), it is
  confirmed **by shape and destination, never by enum label** — today's rule, unchanged.
- **`release_notes_category`** — the `{{#context}}` macro is retired (§7.5), but the label it
  carried is not. It groups notes inside a section and a reader wants it, so it is inferred from the
  work's subject area, confirmed in the same grill, and rendered as a plain label line.
- **`release_versions`** — `/release-notes` gains `--version <v>`; absent, the grill asks. Never
  invented, and absent from the draft when the operator declines to give one.

**One of today's invariants inverts, and must be rewritten rather than left standing beside its
replacement.** `/release-notes` currently forbids the release version in any title or prose, because
the docs repo's own file structure carried it. In a single `release-notes.md` nothing else can say
which release a section belongs to — so the version becomes the **section heading**, and the
prohibition survives only for the body prose.

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
| `references/handoff/jira-reader.md` | dispatch contract | — |
| `agents/vault-prior-art-finder.md` | `/idea`, `/create-prd` | nothing — see §8.2 |
| `references/vault-prior-art.md` | 2 commands | — |
| **`$VAULT_PATH` itself** | **188 references in 50 files** | `$SPECS_PATH` |
| `$VAULT_PATH/jira-products/**` | the mirror | the tree |
| `$VAULT_PATH/jira-drafts/**` | `/epics` output | `EPIC-…/epic.md` |
| the vault task machinery | `followup-emission.md` | §8.1 |
| the paste + re-import round-trip | `/create-prd`, `/update-prd` | nothing |
| `--from-brd` | 3 commands | inferred (D18) |
| `dependencies.md`'s `jira-workitem-import` row | — | — |
| `issue_type: ValueIncrement` | 11 files | `kind:` (D12) |

### 8.1 Follow-ups keep the capture, lose the vault (D15)

`followup-emission.md` is the largest vault-shaped surface left: Obsidian-Tasks line format with
Fibonacci effort checkboxes and date symbols, `#tags` reused from
`$VAULT_PATH/.obsidian/copilot/tag-index.md`, project files named `P<NNNN> <slug>.md`, a `Tasks.md`
fallback, a `Journal.md` for verbose notes, and a Jira browse-URL discovered by grepping existing
vault tasks. All of it goes.

**The three follow-ups it was mostly emitting are the ones this design deletes** — paste the PRD
into the tracker, paste the release note into the tracker, re-import the value increment. Those
were round-trip chores, and with D1 they do not exist.

**What survives is the out-of-scope finding**, which is not a chore: `/implement` naming work it
deliberately did not do, `/ready` naming a coverage gap. Those outlive the session and belong beside
the artifact that produced them, so they land in `follow-ups.md` in the resolved folder — a plain
markdown checklist, no effort symbols, no tags, no vault. This is the emitter's existing tier 2,
promoted to the only tier; tiers 1, 3 and 4, the availability preflight, the interactive escape and
the notice ladder all go with the vault, and a run that cannot resolve a folder keeps its follow-ups
in the Final Report as it does today.

**The same collapse applies to the other three emitters**, which already prefer `$SPECS_PATH` and
name the vault only as a lower tier: `feedback-emission.md`, `cost-emission.md` and
`session-hygiene.md` each lose one branch of a ladder, not a feature.

### 8.2 Vault prior art is dropped, and it is the one deletion that removes a capability

`vault-prior-art-finder` searched `Projects/Products/**` for prior initiatives and fed `/idea` and
`/create-prd` a bounded digest — genuinely useful, and *not* tracker-redundant. It goes because it
is vault-dependent and D15 leaves no vault. It was already advisory, already optional, and already
a silent skip when absent, so nothing gates on it. Recorded here as a loss taken deliberately, not
an oversight.

*(The specs tree is a plausible future home for the same idea — prior art discovered over
`specifications/**` rather than over a vault. That is a separate design, not a quiet substitution
inside this one.)*

### 8.3 Residual vendor vocabulary

Swept in the increment that touches each: `prose-formatting.md` justifies its no-hard-wrap rule by
*"copy-paste into Jira/Grammarly"* — the rule stays, the rationale is rewritten. `docs-profile.md`
uses `gen3` as its example templating token — detection is generic, only the example is
vendor-shaped. `hooks/preload-context.sh` prints `VAULT_PATH` and describes `$VAULT_PATH`-based
specs in a comment.

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

**Two documentation rules this design must not break.** `check-docs.sh` check 10 forbids any page
under `docs/` from naming the marketplace or the containing repository. Check 9 gates seven prose
counts against the tree — deleting two agents and two references moves the agent and reference-file
totals, and **deleting `$VAULT_PATH` moves the environment-variable total** — so those sentences
change in the same commit as the deletion. Check 6's both-directions environment-variable inventory
is the gate that will catch a half-done vault removal.

### 9.1 Every command, every diagram

Two obligations that no script gates, and that are therefore the easiest half of this work to leave
half-done. Both were **audited against the tree** for this design rather than read out of
`CLAUDE.md`'s summary of itself.

**Every command participates in the session emitters.** The audit's result, per command, over
`cost-emission.md`, `feedback-emission.md`, `followup-emission.md`, `session-hygiene.md` and
`commit-artifacts`:

- **The six `/brd-*` commands are complete.** All six emit cost and feedback, all six carry a
  `cost-emission.md` §7 row, all six write a resume pointer and run `commit-artifacts`. Nothing was
  forgotten when they were built.
- **`/upgrade` and `/vuln` emit no session cost, and that was already documented — the audit that
  called it a defect had not read far enough.** Both command pages carry the reason: *"runs outside
  the PRD pipeline: no cost-attribution phase and no role."* What was genuinely missing is a
  statement in `cost-emission.md`, the runtime authority, which is why an audit reading that file
  found an absence and reported it. It is not a defect. **Session cost measures AI investment
  in a project**, and a CVE bump or a library upgrade is noise against a PRD or a BRD — a metric
  that averages the two answers a question nobody asked. The rule this makes explicit: **a cost
  entry attaches to a run that advances a PRD- or BRD-scoped artifact**, and a run that only touches
  a code repository emits none. `cost-emission.md` §7 and `docs/reference/session-cost.md` state the
  exemption and its reason, so the next audit reads it as a decision rather than re-finding it as a
  gap.

  *(One premise the audit got wrong, corrected here so it is not repeated: both commands do run
  `specs-preflight` and `commit-artifacts` and do write into `$SPECS_PATH`, with a `NOISSUE …`
  commit message for the keyless case. "Nowhere to write it" was never the reason — the reason is
  what the number is for.)*
- **The feedback those two emit is kept, and it is not the same thing.** It is `emit-auto` from
  `feedback-emission.md` §6 — the **plugin-facing** slice of `impl-maintenance`'s Lessons Learned
  report, recording that *dev-workflows itself* lacked a capability the run needed. That is how the
  plugin learns about its own gaps, it is silent and additive, and a vulnerability run surfaces one
  as readily as a PRD run does. Dropping it would trade a real signal for a tidier table.
- **`/docs-profile`, `/api-guideline-reviewer` and `/guideline-reviewer` emit nothing, and stay
  that way** — by the same rule. None advances a PRD- or BRD-scoped artifact, so none carries a
  cost entry. `specs-repo-git.md`'s "twenty-three commands" is unchanged.
- **`/statusline` stays out** — it configures a setting rather than running a task — and
  `/prompt-brainstorm` / `/prompt-grill-me` keep their documented exemption: they cede the session
  before a cost phase could run. With the rule above, the cost-emitting set is exactly the
  pipeline that produces a PRD or a BRD, plus `/feedback` and `/prompt`, which inherit the phase and
  role of whatever they are correcting.
- **Follow-up emission is deliberately narrower** — five commands cite `followup-emission.md`.
  Increment D re-examines that boundary when it rewrites the file around `follow-ups.md` (§8.1),
  since `/brd-split` and `/brd-interview` do surface deferred work.

**Every workflow diagram is re-derived, not patched.** There are **21** mermaid diagrams —
`workflow.md`, `brd-workflow.md`, and 19 of the 27 command pages. `check-docs.sh` validates none of
their *content*, so every one will still render perfectly after this change while describing a
pipeline that no longer exists. Each is rebuilt from its own command's `## Phase` headings in the
increment that changes that command — the same derive-from-the-thing-that-runs rule the rest of
`docs/` is held to. The eight command pages with no diagram are the simple ones — `feedback`,
`prompt`, `prompt-brainstorm`, `prompt-grill-me`, `statusline` and the two reviewer commands —
**except `/docs-profile`**, which scans a repository, writes a profile and opens a PR, and gains one.

**No `AGENTS.md` or `.github/copilot-instructions.md` exists in canonical.** Those are mgd/copilot
files and are out of scope; they matter only if this ever ports, which §2 says it will not.

---

## 10. Non-goals

- **No tracker integration of any kind**, including via a CLI. A user who wants one installs an MCP
  server, a CLI or a skill and syncs it against the markdown. The plugin never learns whether a
  tracker exists.
- **No migration command** (D14).
- **No status field in the specs tree.** It would re-create the duplicated state this design removes,
  inside `$SPECS_PATH` instead of a tracker. The artifacts answer the question the field would.
- **No change to the `/brd-*` route** beyond D5, the folder merge (§4.1) and the step-9 positive test.
- **No prior-art discovery over the specs tree** (§8.2) — a separate design.
- **No port to mgd or copilot.**

---

## 11. Build order

Four increments. Each ships green, leaves the tree consistent, and is independently revertible.

### Increment A — the addressing model

Rewrite `brd-addressing.md` for kind prefixes, the three-level bound, one-address resolution
(key **or** `@<path>`, D16), keyless filenames, `key:` frontmatter (D17) and the legacy fallback.
Update its **twelve** adopters — nine commands plus `ard-resolution.md`, `jira-input-resolution.md`
and `prd-source-resolution.md`. Apply D5, the §4.1 folder merge and the step-9 positive test to
`/brd-split`; follow through `coverage-ledger-format.md` §5 and `/create-prd`'s gate. Rename
artifact files (§4.3) and simplify the three resolvers.

*Jira is untouched, so the plugin still runs end to end.* This is the seam everything else needs.

### Increment B — cut the tracker

Delete `jira-reader` and `jira-input-resolution.md`. Rewrite every Phase 0 to resolve one address
against the tree. Drop the paste/re-import round-trip and `prd-source-resolution.md`'s import-first
ladder. Retire `--from-brd` (D18), the mirror fields (§7.4), `issue_type` (D12) and the two-grammar
rule (§5.1). Add `workitem_key` and the unknown-key preservation rule (D10, D11).

*The largest increment. It can only follow A — commands need the new resolver before the old one goes.*

### Increment C — refill what the tracker supplied

`/epics` mints keys and writes `epic.md`; `/implement` writes `implementation.md` **and adopts the
§7.3.1 commit convention, with `/vuln` and `/upgrade`**; `/document` and `/release-notes` diff from
both it and the commit scan; `release-notes.md` lands in the PRD folder with sections not
destinations; `/ready` derives the phase and gains `--claimed`; `workflow-states.md` is inverted.

*These are exactly the capabilities B removes, and they need B's absence to be designed against.*

### Increment D — delete `$VAULT_PATH`

Collapse the four emitter ladders to `$SPECS_PATH` and rewrite `followup-emission.md` around
`follow-ups.md` (§8.1). Delete `vault-prior-art-finder` and `vault-prior-art.md`. Move `/document`'s
gaps draft into the PRD folder. Strip `vault_path` from `idea-reader` and the hook. Sweep every
residual vault reference and the residual vendor vocabulary in §8.3, drop the `dependencies.md` row,
and rewrite the plugin description.

*Last, because the emitters run in every command and the ladder collapse is only safe once every
command resolves a folder in `$SPECS_PATH`.*

### Verification, every increment

This plugin is prose; there is no test framework and the plan must not pretend otherwise.
`scripts/check-docs.sh` (with `--selftest`), `scripts/check-id-grammar.sh` and
`scripts/validate-catalog.py` all green; a read-through of each changed command end to end; and a
**residue audit** asking *what did this make false elsewhere* — the technique that found five of the
2026-08-31 round's findings and four of its documentation stalls.

### Review protocol

**Per increment.** A review pass over everything the increment changed, and **every defect it finds
is fixed before the increment closes.** A defect that turns out to be unrelated to the increment is
still fixed — in its own PR where that keeps the increment's diff readable. Nothing is carried
forward as a known-but-unfixed finding; that is the standing bugs-first rule, and this design does
not get an exemption from it.

**After increment D closes.** A **comprehensive review of the whole design's changes by an Opus 5
subagent**, given the four increments' diffs and this spec, reviewing across increment boundaries —
which is where the defects the per-increment reviews cannot see will be, because each of those saw
only its own diff. Every finding is fixed and the reviewer re-runs. **At most three re-review
rounds**; anything still standing after the third is reported to the operator by name, never
absorbed into a summary.

**One standing item this design does not fix**, recorded so it is not mistaken for new: 40 of 232
`choices:` arrays exceed `AskUserQuestion`'s four-option maximum. It is plugin-wide, predates this
work, and belongs to its own sub-project.

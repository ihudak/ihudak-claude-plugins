# Addressing — Shared Reference

The key grammar, the directory-naming convention, and the folder-resolution rule for **every** folder
under `$SPECS_PATH/specifications/` — a BRD, a PRD, or an Epic alike. This file is where addressing is
defined once rather than reinvented per caller. Design authority:
`docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` §§4–5.

**Consumed by every command that addresses a folder in the specs tree.** Each calls `resolve-address`
(§3) and, where it validates a key before touching the filesystem, `key-valid` (§1). The six `/brd-*`
commands, the eleven commands in §7's table, and the one shared authority §7 names all reach the
tree through this file; `references/brd-format.md` and `references/coverage-ledger-format.md` cite it
for the key grammar and folder resolution neither of them restates. Read §7's list as a **list**, not
as a count — it is longer than a reader expects, and summarising it is how an adopter goes missing.

## 1. Key grammar

```
^[A-Z][A-Z0-9_]*(-\d+)+$
```

A key is one or more hyphen-numeric segments after a leading alphabetic token. `ACME-90`,
`ACME-90-01` and `ACME-90-01-01` are all valid — the grammar fixes no depth. **Shape is not depth**:
how many segments a key carries says nothing about where its folder sits, which §3 bounds at three
levels below `specifications/` regardless.

**One grammar, one namespace.** There is no second, narrower grammar for a "tracker" key: the plugin
reads no tracker, mints its own keys, and validates every key against this one expression. A caller
that re-states this grammar locally instead of citing this section is the defect family
`CLAUDE.md` names — the copies drift, and a key that is valid here hard-stops somewhere else.

**Shape only, never checked against anything.** A key names a folder in `$SPECS_PATH`, not a record
in a system that could confirm it exists. Validating shape and validating existence are two different
questions, and this section answers only the first; §3 answers the second.

### Entry point: `key-valid <KEY>`

Returns `valid` when `<KEY>` matches the grammar above, `invalid` otherwise. Takes no other input and
touches no filesystem — a pure string test, safe to call before `$SPECS_PATH` is even resolved.

## 2. Directory naming

```
<KIND>-<KEY>-<slug>/          kind ∈ BRD | PRD | EPIC
```

**Two invariants, and §3's bound is derived from the second:**

1. **Kinds appear in a fixed order down any path** — `BRD` → `PRD` → `EPIC`, each optional at the top.
   An idea-route PRD folder sits directly under `specifications/`; a BRD-route PRD folder is the
   slice folder inside its BRD. Both are `PRD-` folders, both are where the `prd.md` is authored, and
   both hold their Epics one level below. **The `BRD-` folder itself is never one of them**: it is a
   container, and `prd.md`, `ard.md` and `specification.md` are authored in the `PRD-` slice folders
   under it, never beside `brd/` and `coverage-ledger.md`
   (`references/coverage-ledger-format.md` §5).
2. **No path holds two folders of the same kind.** Every level is therefore identifiable from its own
   name without reading its parent, and the tree is at most three levels deep.

**Reserved subdirectory names are not folder kinds.** A folder under `specifications/` may hold
fixed-name subdirectories that carry no key and are never resolved by one — `brd/`, `grounding/`,
`interview/`, `dev-workflows/`, `design/` (exported frame sets, one per immediate subdirectory, each
indexed per `references/grounding-format.md` §6.1–§6.2), and `attachments/` (the text and markdown sources a run copied
into the folder — `references/idea-format.md`, *Vendored sources*). None matches §3's `*-<KEY>-*` glob,
so resolution passes over them without a rule of its own, and none carries a `brd-link.md`, so
`/brd-split`'s positive test excludes them by construction rather than by an exclusion list.

**Each reserved name is defined once, elsewhere, and cited here.** This list is the register of names
resolution must pass over; it is not where any of them acquires its meaning. `design/` is
`grounding-format.md` §6.1's — with §6.2 owning the index every set inside it must carry —
`attachments/` is `idea-format.md`'s, and a name added here without an
authority to cite is a name two files will disagree about.

**A user whose own key begins with a kind token gets `PRD-PRD-1234-…`.** That is a documented
consequence of a documented convention, not a defect, and it is not hypothetical: a key like
`EPIC-008` yields `PRD-EPIC-008-01-orders` and `EPIC-EPIC-008-01-01-intake`. We cannot dodge every key
any user might pick, and a convention that can be relied on is worth more than one that bends. The
convention is stated in the README and in `docs/`; a user who then names their work `PRD-…` has chosen
the collision.

## 3. Resolution

### Entry point: `resolve-address <ARG> [<KIND>]`

**The caller-facing entry point.** Every command calls this one. `<KIND>`, when supplied, narrows the
search and refuses a mismatch; a caller that does not yet know the kind must not have to guess, because
the kind is frequently what decides the run's mode.

1. **`<ARG>` begins with `@` → the path branch.** Strip the `@`. A directory resolves to itself; a file
   resolves to its parent directory. Read the folder's `kind:` and `key:` (§4) and return `form: path`.

   **No glob, no tree walk, no ambiguity, and no §5 fallback** — the operator has already answered the
   question resolution exists to ask, and re-deriving an answer they supplied would only introduce a way
   to disagree with them. The one check a path still needs is the kind: a `<KIND>` argument that
   disagrees with the folder's own `kind:` is a stop naming both.

2. **Anything else → the key branch.** `key-valid <ARG>`; on `invalid`, return `status: invalid`. On
   `valid`, `resolve-key <ARG> [<KIND>]` and return `form: key`.

### Entry point: `resolve-key <KEY> [<KIND>]`

1. **Glob `specifications/**/*-<KEY>-*`, bounded at three levels below `specifications/`.** Do not
   narrow the glob by `<KIND>`: the folder **prefix** and the asserted **`kind:`** are allowed to
   differ, and on the BRD route they routinely do — `/brd-split` creates a slice as a `PRD-` folder
   whose `brd-link.md` asserts `kind: brd`, so globbing `BRD-<KEY>-*` for `<KIND> = brd` would miss a
   folder that exists, fall through to §5, miss again, and return `absent`. `<KIND>` is applied in
   step 2 instead, against what each candidate asserts.
2. **Filter the candidates by what each one asserts.** A glob matches *names*, and a name is not an
   assertion. Open each candidate and keep only those whose own frontmatter says `key: <KEY>` — and,
   where `<KIND>` was supplied, whose `kind:` equals it. This is §4's read, applied as a filter rather
   than only to the winner, and it is the only place `<KIND>` narrows anything. **This step is not optional and it is not
   tidiness**: `*-<KEY>-*` matches every folder whose key merely *extends* `<KEY>`, and a child keyed
   from its parent is this plugin's default. `/brd-split` proposes "the parent's key plus the next
   unused two-digit segment" and nests the child inside the parent, so on a tree holding
   `BRD-ACME-90-billing-intake/` with children `PRD-ACME-90-01-invoicing/` and
   `PRD-ACME-90-02-dunning/`, the bare glob returns **three** matches for `ACME-90` — and step 4 would
   hard-stop as `ambiguous` on a tree that is entirely correct, making the parent unaddressable by all
   six `/brd-*` commands from the moment its first child exists. Exactly one of those three asserts
   `key: ACME-90`.
3. **Exactly one surviving candidate** → `status: found`.
4. **No surviving candidate** → apply §5's legacy fallback. Still nothing → `status: absent`. The
   caller decides whether that is a stop or a folder to create; this resolver never creates one.
   **A folder that matched the glob but asserts a different key is not a match**, so a legacy parent
   holding a prefixed child no longer returns the child: before the filter, `ACME-90-billing/` with
   `PRD-ACME-90-01-invoicing/` inside it globbed to exactly one match — the child — and returned
   `found` for it silently, with §5's fallback never reached because the prefixed glob had not missed.
5. **More than one surviving candidate** → `status: ambiguous`, a **hard stop naming every match**. Two
   folders *asserting* one key is a defect in the tree, and choosing between them would pick silently —
   the one failure mode a resolver must never have. Name `@<path>` in the stop as the way through it.

### The resolution record

```yaml
status:  found | absent | ambiguous | invalid
path:    <absolute path of the resolved folder>   # found only
kind:    brd | prd | epic                         # found only
key:     <the folder's asserted key>              # found only; read, never parsed (§4)
form:    key | path                               # which form the caller supplied
legacy:  true | false                             # true when §5's fallback resolved it
matches: [ <absolute path>, … ]                   # ambiguous only
```

**It terminates because the bound is a constant, not a property of the key or of the tree.** Three
levels are scanned, each enumerating a finite set of directories; nothing found on disk can raise
that. So `resolve-key` always answers, and always after a bounded number of scans.

**The key's segment count buys no depth.** The default key `/brd-split` proposes is the parent's key
plus one more numeric segment (`commands/brd-split.md` Phase 3), and an operator may supply any key
satisfying §1 instead, including one that adds no segment. Either resolves identically: a segment count
is a naming convention, never a depth declaration, and §1's grammar deliberately fixes no depth.

## 4. The kind and the key are read, never parsed

`resolve-address` returns a folder's `kind` and `key` by **reading frontmatter**, never by splitting the
directory name.

**A directory name is not a safe place to parse from.** `PRD-ACME-90-01-orders` divides into key and
slug only under a rule about where numeric segments stop, and a slug beginning with a numeric segment
falsifies it. More fundamentally, a key re-derived by pattern is a key nothing in the tree ever
asserted — `CLAUDE.md`'s standing rule — so every match is a guess that a longer or differently-shaped
identifier defeats. Reading the field turns the guess into an assertion.

**Which artifact carries it is not a fixed filename**, and must not be written down as one. The rule is:

> The command that creates a folder writes a keyed artifact into it in the same act, so a folder is
> never keyless — not even between its creation and its first document. A resolver reads `kind:` and
> `key:` off whichever artifact it had to open anyway; where it has opened none yet, it reads the first
> artifact in the folder carrying both fields.

An enumeration of carriers per kind would be a list that goes stale the first time a command writes a
new artifact, and nothing in `scripts/` would catch it.

**A `key:` that disagrees with its folder name is a hard stop naming both.** That is the whole cost of
carrying identity in two places, and it buys the conversion of a hand-rename from a silent divergence
into a message.

## 5. The legacy layout

A specs repo written before the kind prefixes existed holds `specifications/<KEY>-<slug>/`, with a BRD
slice one level inside its parent. `resolve-key` therefore falls back to the **unprefixed** form —
matching `<KEY>{-|_}<slug>/` at either level, tolerating a human-adjusted slug and a stray extra `-`/`_`
immediately after the key, exactly as the pre-prefix resolution did.

**The fallback is reached only after the prefixed glob has already missed**, so a prefixed tree resolves
exactly as it would if this section did not exist. A run that resolves through it sets `legacy: true`
and reports it **once per run** as deprecated. `@<path>` bypasses it along with the rest of resolution.

**No migration command ships.** A user's specs repo is theirs, it is a git repository they review, and a
renaming script that cannot be tested against their tree is a liability. Renaming a folder is one
`git mv`, and the fallback means they need never do it.

## 6. Nesting

A PRD folder produced by `/brd-split` is not a sibling of its BRD — it lives **inside** it, and its Epics
live inside it in turn:

```
specifications/BRD-<PARENT-KEY>-<slug>/PRD-<CHILD-KEY>-<slug>/EPIC-<EPIC-KEY>-<eslug>/
```

`resolve-address <CHILD-KEY>` finds the middle folder through §3's glob without the caller ever supplying
the parent key — resolution alone locates a PRD folder from its own key.

**The folder `/brd-split` creates for a slice *is* the folder its PRD is authored in.** A slice exists
precisely to become a PRD, so giving it a directory of its own with a PRD directory nested inside bought a
level of tree for nothing. The merged folder holds the slice's own bookkeeping — `brd-link.md`,
`coverage-ledger.md`, `decisions.md` — beside the documents authored from it, which is what the idea route's
PRD folder already does with `idea.md`.

**Nothing is created below a PRD folder except its Epics** — invariant 2 of §2 says so, and this is the
path it forbids:

```
specifications/BRD-<KEY>-<slug>/PRD-<KEY>-<slug>/PRD-<KEY>-<slug>/     # never created
```

**Why, rather than a second inheritance rule.** A slice inherits `brd/source/` and its defect log from its
BRD (`references/brd-format.md` §2.1, §4). A slice of a slice would have a parent holding neither: its
inventory header would name a `source:` path that does not exist, and a `rejected: [DEF#n]` disposition
taken against it would cite a defect log that is not there. Chasing every inheritance up to the
source-owning root would fix that, but nothing in practice needs it, and one rule beats two. **Every "its
parent's" in this route is therefore literal**: a PRD folder's parent is always a BRD that owns the source
document — which is what makes its one live inheritance, the parent's defect log behind a
`rejected: [DEF#n]`, a single hop.

**The cap is on nesting, never on allocation.** A folder whose ledger could not be walked would keep every
row `unallocated` forever and could never become PRD-eligible
(`references/coverage-ledger-format.md` §4, §5) — which would make slicing pointless, since a slice exists
precisely to become a PRD. Refusing a further child, not the walk, is the whole of the cap.

## 7. The shared fallback for existing commands

Every command outside the `/brd-*` family that addresses a PRD directory resolved it as the flat form
`specifications/<KEY>-<slug>/`, which on its own cannot see a nested PRD (`/create-prd` on the BRD
route authors into the `PRD-` slice folder one level inside a BRD). All of them therefore reach the tree through `resolve-address`, which searches
every level §3 bounds and carries §5's fallback. One shared rule, defined here once rather than reinvented
per caller. The adopter list below is the authority on who applies it — **it is longer than the six the
original design named**, and it is meant to be read as a list, not summarised as a count.

**Adopted in twelve files.** Eleven commands cite this section from the step that resolves their PRD
directory — or, for `/frames`, the folder of any kind whose frame sets it indexes:

| Command | Step (by name) | What the resolved directory is for |
|---|---|---|
| `/create-prd` | *Feature folder*, Phase 0 — Resolve inputs | the PRD it authors, and its rung-1 `idea.md` |
| `/update-prd` | *Feature folder*, Phase 0 — Resolve inputs | the frozen draft, any ARD, and the spec it grounds on |
| `/create-ard` | *Feature folder*, Phase 0 — Resolve input | the PRD it reads and the ARD it writes |
| `/epics` | *Resolve the PRD dir*, Phase 2.6 — PRD-level spec enrichment (optional) | the optional PRD-level spec |
| `/specify` | *Resolve the feature folder*, Phase 0 — Resolve input | the spec it authors, and each Epic subfolder under it |
| `/design` | *Map onto the specs repo + require the spec on main*, Phase 0 — Resolve input | the merged spec it takes over |
| `/ready` | *Map onto the specs repo (PRD dir + optional Epic subdir)*, Phase 0 — Resolve input | every artifact it judges |
| `/idea` | *Resolve the address*, Phase 0 step 1 | the folder `idea.md` is written into on the first write |
| `/release-notes` | *Resolve `run_phase`*, Phase 6 — Render the draft | the `run_phase` signal |
| `/document` | *Resolve the address*, Phase 0 step 1 | the `specs` files it grounds documentation in |
| `/frames` | *The address (mandatory)*, Phase 0 step 1 | the folder whose `design/*/` frame sets it indexes |

One further file adopts it and **it is not a command** — it is a shared authority commands delegate
to, which is why the adopter count and the command count differ:

- `references/ard-resolution.md`, from step 1 of its *Resolution (most-specific first)*. It is where the
  fallback reaches an **ARD**: `/create-ard`, `/design`, `/specify`, `/epics` and `/ready` delegate ARD
  lookup to it rather than resolving an ARD path themselves, so their own adoption above would not have
  found an ARD in a nested directory.
**Twelve files, twelve commands** — and the two matching is a coincidence of this moment, not a rule.
One command adopts it purely **by delegation** and appears nowhere in the table: `/implement`, which
resolves no PRD directory of its own and reaches an ARD solely by citing `ard-resolution.md`. Counting
files rather than commands is what keeps both facts visible — a reader who counted only the table would
conclude `/implement` was left flat, and one who counted only commands would miss a shared authority
that needed the fallback in its own right.

**Re-derive both, every time, rather than adjusting them.** Cutting the tracker moved this arithmetic
twice in one increment and never by the amount a decrement would have guessed: retiring the shared
front-end removed an authority *and* moved `/document` into the table on its own account, leaving both
totals where they started; folding the PRD-source resolver into its two callers then removed a file
without removing a command; adding `/frames` then moved both by one at once, which is the only kind of
change that leaves the coincidence intact. Eleven commands in the table, one by delegation, one shared
authority.

**Where a handoff crosses two adopters, both must carry it.** `/create-prd` redirects to `/update-prd` on
finding an existing PRD (its *Prior PRD* step), including one found through this fallback; `/idea`
writes `idea.md` into the folder `/create-prd` then reads, resolving it with this file's §3 on its
first write and **never relocating it afterwards** (D7). A redirect, or a first write into a folder a
command with a narrower resolution then has to find again, is a dead-end handoff, which is why those
two are in the table rather than deferred as low-risk.

**Not adopters, and correctly so.** The `/brd-*` commands resolve a folder with `resolve-address` (§3)
directly, which already searches every level — the fallback here is §5's rule restated for callers that
were never wired to it. `/implement` is covered by delegation as above.

**Adoption is additive, in all twelve.** §5's fallback is reached only where the prefixed glob already
returned nothing, so a key whose folder resolves at the first attempt resolves exactly as it did before
any of them adopted this — and where a command creates the folder it did not find, it still creates it
with the §2 prefix: the fallback honors a legacy folder that exists, it never proposes one. The one shared authority creates nothing at all — `ard-resolution.md` is a reader, so for it the additive
claim is simply that a resolvable key returns what it returned before: the same `found` / `none` /
`unmerged`.

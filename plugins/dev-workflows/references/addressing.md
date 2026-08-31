# Addressing — Shared Reference

The key grammar, the directory-naming convention, and the folder-resolution rule for **every** folder
under `$SPECS_PATH/specifications/` — a BRD, a PRD, or an Epic alike. This file is where addressing is
defined once rather than reinvented per caller. Design authority:
`docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` §§4–5.

**Consumed by every command that addresses a folder in the specs tree.** Each calls `resolve-address`
(§3) and, where it validates a key before touching the filesystem, `key-valid` (§1). The six `/brd-*`
commands, the nine commands in §7's table, and the three shared authorities §7 names all reach the
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
   An idea-route PRD sits directly under `specifications/`; a BRD-route PRD sits inside its BRD. Both
   are `PRD-` folders and both hold their Epics one level below.
2. **No path holds two folders of the same kind.** Every level is therefore identifiable from its own
   name without reading its parent, and the tree is at most three levels deep.

**Reserved subdirectory names are not folder kinds.** A folder under `specifications/` may hold
fixed-name subdirectories that carry no key and are never resolved by one — `brd/`, `grounding/`,
`interview/`, `dev-workflows/`, and `design/` (exported frame sets, one per immediate subdirectory —
`references/grounding-format.md` §6.1). None matches §3's `*-<KEY>-*` glob, so resolution passes over
them without a rule of its own, and none carries a `brd-link.md`, so `/brd-split`'s positive test
excludes them by construction rather than by an exclusion list.

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

1. **Glob `specifications/**/*-<KEY>-*`, bounded at three levels below `specifications/`.** With
   `<KIND>` supplied, narrow to `<KIND>-<KEY>-*` and treat a match of another kind as no match.
2. **Exactly one match** → `status: found`.
3. **No match** → apply §5's legacy fallback. Still nothing → `status: absent`. The caller decides
   whether that is a stop or a folder to create; this resolver never creates one.
4. **More than one match** → `status: ambiguous`, a **hard stop naming every match**. Two folders
   carrying one key is a defect in the tree, and choosing between them would pick silently — the one
   failure mode a resolver must never have. Name `@<path>` in the stop as the way through it.

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
`specifications/<KEY>-<slug>/`, which on its own cannot see a nested PRD (one `/create-prd --from-brd`
authors inside a BRD). All of them therefore reach the tree through `resolve-address`, which searches
every level §3 bounds and carries §5's fallback. One shared rule, defined here once rather than reinvented
per caller. The adopter list below is the authority on who applies it — **it is longer than the six the
original design named**, and it is meant to be read as a list, not summarised as a count.

**Adopted in twelve files.** Ten commands cite this section from the step that resolves their PRD
directory:

| Command | Step (by name) | What the resolved directory is for |
|---|---|---|
| `/create-prd` | *Feature folder*, Phase 0 — Resolve inputs | the PRD it authors, and its rung-1 `idea.md` |
| `/update-prd` | *Feature folder*, Phase 0 — Resolve inputs | the frozen draft, any ARD, and the spec it grounds on |
| `/create-ard` | *Feature folder*, Phase 0 — Resolve input | the PRD it reads and the ARD it writes |
| `/epics` | *Resolve the PRD dir*, Phase 2.6 — PRD-level spec enrichment (optional) | the optional PRD-level spec |
| `/specify` | *Resolve the feature folder*, Phase 0 — Resolve input | the spec it authors, and each Epic subfolder under it |
| `/design` | *Map onto the specs repo + require the spec on main*, Phase 0 — Resolve input | the merged spec it takes over |
| `/ready` | *Map onto the specs repo (PRD dir + optional Epic subdir)*, Phase 0 — Resolve input | every artifact it judges |
| `/idea` | *Phase 5* relocation | where `idea.md` is relocated once a key exists |
| `/release-notes` | *Resolve `run_phase`*, Phase 6 — Render the draft | the `run_phase` signal |
| `/document` | *Resolve the address*, Phase 0 step 1 | the `specs` files it grounds documentation in |

Two further files adopt it and **neither is a command** — both are shared authorities that commands
delegate to, which is why the adopter count and the command count differ:

- `references/ard-resolution.md`, from step 1 of its *Resolution (most-specific first)*. It is where the
  fallback reaches an **ARD**: `/create-ard`, `/design`, `/specify`, `/epics` and `/ready` delegate ARD
  lookup to it rather than resolving an ARD path themselves, so their own adoption above would not have
  found an ARD in a nested directory.
- `references/prd-source-resolution.md`, from step 2 of `resolve-existing-prd`. It is where the fallback
  reaches the **frozen specs draft** for `/update-prd` and `/create-prd --from-prd`. Both commands already
  resolve their own feature folder in the table above, but neither resolves the draft itself: they delegate
  that to this resolver, so a PRD authored inside a BRD would have been invisible to it.

**Twelve files, eleven commands** — and neither number is derivable from the other. One command adopts
it purely **by delegation** and appears nowhere in the table: `/implement`, which resolves no PRD
directory of its own and reaches an ARD solely by citing `ard-resolution.md`.
`prd-source-resolution.md` adds a file without adding a command, because both commands that delegate to
it are already in the table on their own account. Counting files rather than commands is what keeps both
facts visible — a reader who counted only the table would conclude `/implement` was left flat, and one
who counted only commands would miss a shared authority that needed the fallback in its own right.

**Both totals are unchanged and their composition is not, which is why they are re-derived rather than
adjusted.** Retiring the tracker front-end removed one shared authority and moved `/document` into the
table on its own account — it reached its `specs` list through that front-end and now resolves a folder
itself. Minus one authority, plus one command: the arithmetic lands where it started, and a decrement
would have been wrong in both halves.

**Where a handoff crosses two adopters, both must carry it.** `/create-prd` redirects to `/update-prd` on
finding an existing PRD (its *Prior PRD* step), including one found through this fallback; `/idea`
relocates `idea.md` into the folder `/create-prd` then reads. A redirect or a relocation into a command
with a narrower resolution than the one that produced the state is a dead-end handoff, which is why those
two are in the table rather than deferred as low-risk.

**Not adopters, and correctly so.** The `/brd-*` commands resolve a folder with `resolve-address` (§3)
directly, which already searches every level — the fallback here is §5's rule restated for callers that
were never wired to it. `/implement` is covered by delegation as above.

**Adoption is additive, in all twelve.** §5's fallback is reached only where the prefixed glob already
returned nothing, so a key whose folder resolves at the first attempt resolves exactly as it did before
any of them adopted this — and where a command creates the folder it did not find, it still creates it
with the §2 prefix: the fallback honors a legacy folder that exists, it never proposes one. Neither of the
two shared authorities creates anything at all — both are readers, so for them the additive claim is
simply that a resolvable key returns what it returned before: the same `found` / `none` / `unmerged` from
`ard-resolution.md`, and the same frozen specs draft from `prd-source-resolution.md`.

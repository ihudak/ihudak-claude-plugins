# Addressing — Shared Reference

The key grammar, the directory-naming convention, and the folder-resolution rule for **every** folder
under `$SPECS_PATH/specifications/` — a BRD, a PRD, or an Epic alike. This file is where addressing is
defined once rather than reinvented per caller. Design authority:
`docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` §§4–5.

**Consumed by every command that addresses a folder in the specs tree.** Each calls `resolve-address`
(§3) and, where it validates a key before touching the filesystem, `key-valid` (§1). Those commands
are what `grep -l resolve-address plugins/*/commands/*.md` returns — re-run it rather than keeping a
list or a count here, since both went stale in this paragraph — and they, with the one shared
authority §7 names, all reach the tree through this file; `product-workflows:brd-format` and
`product-workflows:coverage-ledger-format` cite it for the key grammar and folder resolution neither
of them restates.

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
   (`product-workflows:coverage-ledger-format` §5).
2. **No path holds two folders of the same kind.** Every level is therefore identifiable from its own
   name without reading its parent, and the tree is at most three levels deep.

**Reserved subdirectory names are not folder kinds.** A folder under `specifications/` may hold
fixed-name subdirectories whose names carry no key and that are never resolved by one — `brd/`,
`grounding/`, `interview/`, `dev-workflows/`, `design/` (exported frame sets, one per immediate subdirectory, each
indexed per `references/grounding-format.md` §6.1–§6.2), and `attachments/` (the text and markdown sources a run copied
into the folder — `product-workflows:idea-format`, *Vendored sources*). None matches §3's `*-<KEY>-*` glob,
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
   from its parent is the default wherever a command mints one. `/brd-split` proposes "the parent's key plus the next
   unused two-digit segment" and nests the child inside the parent, so on a tree holding
   `BRD-ACME-90-billing-intake/` with children `PRD-ACME-90-01-invoicing/` and
   `PRD-ACME-90-02-dunning/`, the bare glob returns **three** matches for `ACME-90` — and step 4 would
   hard-stop as `ambiguous` on a tree that is entirely correct, making the parent unaddressable by all
   six `/brd-*` commands and `/prd-ground` from the moment its first child exists. Exactly one of those three asserts
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
plus one more numeric segment (`/product-workflows:brd-split` Phase 3), and an operator may supply any key
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

**Which artifact carries it is not a fixed filename at the folder's top level**, and must not be
written down as one there. The rule is:

> The command that creates a folder writes a keyed artifact into it in the same act, so a folder is
> never keyless — not even between its creation and its first document. A resolver reads `kind:` and
> `key:` off the folder's **carrier**, found in this order:
>
> 1. **The folder's top level.** Take its files in byte-wise order of name, and the carrier is the
>    first whose frontmatter holds `key:` and a `kind:` naming a folder kind — `brd`, `prd` or
>    `epic`, §2's three kinds as the resolution record (§3) spells them.
> 2. **Else `brd/brd-inventory.md`.** Where no top-level file qualifies, the carrier is the
>    inventory inside the reserved `brd/` subdirectory — the one file below the top level that is
>    ever read for this.

**Why a kind outside the three is passed over.** A document's `kind:` names what that document is —
`ard`, `specification`, `design` — and an idea-route PRD folder holding an `ard.md` would otherwise
resolve as kind `ard`, a value the resolution record (§3) has no place for. **Why byte-wise order.**
"The first artifact" meant nothing until an order was fixed, and a slice shows why it matters: its
`brd-link.md` asserts `kind: brd` and its `prd.md` `kind: prd`, and a resolver that read whichever
it had opened anyway — which this rule used to allow — could return either for one folder. Byte-wise
order puts `brd-link.md` first, which is the reading the family's container refusals already give as
their reason for testing a directory prefix rather than an asserted kind: a slice asserts `brd`.

**Why step 2 exists.** `/brd-intake` creates a root BRD folder whose only artifact naming a folder
kind is the inventory it writes inside `brd/` (`product-workflows:brd-format` §2.1), and no command
writes one at a root's top level, so that inventory is a root's only carrier. The
`coverage-ledger.md` `/brd-intake` writes at the top level carries `key:` beside a `kind:` naming its
own document (`product-workflows:coverage-ledger-format` §2), which step 1 passes over — so step 1
alone finds nothing in that folder, and a strict reading of this rule left every root BRD
unresolvable. It is **one named file, not an enumeration of carriers per kind**: such a list would
go stale the first time a command writes a new artifact, and nothing in `scripts/` would catch it,
while this exception names the single place the family's own reserved subdirectory holds the
folder's identity.

**A reserved subdirectory is otherwise not a candidate for this test.** A frame-set index carries its
*parent's* `key:` while sitting in a directory named for the set (`design/checkout-flow/`), so every
frame-set index in the tree presents an apparent disagreement. Testing it there would tell an operator
their tree is broken on the ordinary `@<path>`-to-a-frame-set gesture, where the right answer is the
consuming command's own redirect (`/frames`'s `FRAMES_NOT_A_SPEC_FOLDER`: re-run against the folder
above). §2's reserved subdirectories are passed over by key resolution and are passed over here too,
save the one file step 2 reads — and step 2 reads it for the folder `brd/` sits in, whose key it
carries, never for `brd/` itself.

**A `key:` that disagrees with its folder name is a hard stop naming both.** That is the whole cost of
carrying identity in two places, and it buys the conversion of a hand-rename from a silent divergence
into a message.

### 4.1 A folder is placed by its prefix — or, where it has none, by positive evidence

**The level a run works at — a BRD container, a PRD folder or an Epic folder — is read off the
folder's kind prefix, never off the `kind:` its carrier asserts.** A BRD-route slice is a `PRD-`
folder whose carrier, `brd-link.md`, asserts `brd` (above), so a level taken from the asserted kind
puts every slice at the one level it is not. A `BRD-` folder is a container, a `PRD-` folder is
PRD-level, and an `EPIC-` folder is Epic-level, its PRD folder being the folder above it.

**A folder is prefixed only where its name begins `<KIND>-<key>-`**, `<KIND>` one of §2's three and
`<key>` the key this section read off its carrier — a test against a key the run already holds, so
nothing is parsed out of the name. A name that merely begins with a kind token is not prefixed: §5's
legacy name starts with the key, and a key may itself begin with a kind token (§2), so
`EPIC-008-01-orders/`, keyed `EPIC-008-01`, is a legacy folder and not an Epic folder — it does not
begin `EPIC-EPIC-008-01-`.

**A folder with no prefix is placed by positive evidence, in this order, and never by the absence of
a file.** It is one §5's fallback resolved (`legacy: true`), or an unprefixed folder an `@<path>`
names, which §3 resolves without the fallback and so without the flag.

1. **A BRD container** where it holds `coverage-ledger.md` or `brd/brd-inventory.md` and no
   `brd-link.md` naming a `parent:` — `product-workflows:coverage-ledger-format` §5.1's test, which
   that section owns and argues. It is taken first, as it is there, so that no evidence of a lower
   level can place a container at one.
2. **Epic-level** where the resolved `kind` is `epic`.
3. **PRD-level** where the resolved `kind` is `prd`, or where a `brd-link.md` names a `parent:` — a
   legacy BRD-route slice, whose carrier asserts `brd`.

A folder none of the three places is never guessed at: the caller stops, naming the folder and what
it carries.

**What a caller does at each level is its own, and so is its refusal of a level it does not work
at.** Where a refusal names the slices under a container, it finds them by
`/product-workflows:brd-split` Phase 0 step 9's positive test — each immediate subdirectory carrying
a `brd-link.md` whose `parent:` names the container — and never by a name match.

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
`git mv`, and the fallback above means they need never do it.

**The fallback covers the folder name and nothing inside it, which is a narrowing of what this
paragraph used to claim.** It said the fallback meant a user need never rename, unqualified — and that
covered filenames it never reached. Every command resolves an artifact by its **current** name and none
carries a fallback of its own, so a folder written before the artifact filenames lost their keys still
needs its `<KEY>_<slug>.md` renamed to `prd.md` and its `<KEY>_ARD.md` to `ard.md`. Two more `git mv`s,
and unlike the folder nothing resolves them for you: a command meeting the old filename reports the
artifact absent and stops on that, with a remedy written for a folder that never had one. **The
unqualified claim was load-bearing in the wrong direction** — a resolver for the legacy artifact names
is derivable from it, and was derived in full, before anyone measured how many trees it would serve.
State the boundary here so the derivation stops at this paragraph.

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

**Why, rather than a second inheritance rule.** A slice inherits `brd/source/` and its **requirement**
defect log from its BRD (`product-workflows:brd-format` §2.1, §4 — the route's separate code-defect log is
slice-owned and inherits nothing). A slice of a slice would have a parent holding neither: its
inventory header would name a `source:` path that does not exist, and a `rejected: [DEF#n]` disposition
taken against it would cite a defect log that is not there. Chasing every inheritance up to the
source-owning root would fix that, but nothing in practice needs it, and one rule beats two. **Every "its
parent's" in this route is therefore literal**: a PRD folder's parent is always a BRD that owns the source
document — which is what makes its one live inheritance, the parent's defect log behind a
`rejected: [DEF#n]`, a single hop.

**The cap is on nesting, never on allocation.** A folder whose ledger could not be walked would keep every
row `unallocated` forever and could never become PRD-eligible
(`product-workflows:coverage-ledger-format` §4, §5) — which would make slicing pointless, since a slice exists
precisely to become a PRD. Refusing a further child, not the walk, is the whole of the cap.

## 7. The shared fallback for existing commands

Every command outside the `/brd-*` family, `/prd-ground` and `/prd-proposal` that addresses a PRD
directory once resolved it as the flat form `specifications/<KEY>-<slug>/`, which on its own cannot see
a nested PRD (`/create-prd` on the BRD route authors into the `PRD-` slice folder one level inside a
BRD). **Every command that addresses a folder now reaches the tree through `resolve-address` (§3)**,
which searches every level §3 bounds and carries §5's fallback — so the fallback is reached by calling
§3, and a caller cites §3 (and §5 for the fallback itself), not this section. One shared rule, defined
here once rather than reinvented per caller.

**Re-derive the set; do not read it off this section.** `grep -l resolve-address plugins/*/commands/*.md`
returns every command that resolves a folder in the specs tree. No total is kept here, deliberately:
this section once carried two — *"twelve files"*, *"eleven commands cite this section"* — and both went
false, the second because no command cites it to reach the fallback (each cites §3; `/brd-split`
cites only its *Adoption is additive* rule) and both because the set grew past the table below
(`/implement`, `/vuln` and `/brd-proposal` resolve through §3 and are in no row of it).

**The table is a finding aid, not the set.** It names the resolving step, and what the resolved
directory is for, for eleven of those commands — all but the five `/brd-*` route commands,
`/prd-ground`, the proposal pair, `/implement` and `/vuln`. For `/frames` the directory is a folder of
any kind whose frame sets it indexes. A command absent from the table is not absent from the fallback.
The eleven rows:

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

**One shared authority calls it too, and it is not a command:**

- `references/ard-resolution.md`, from step 1 of its *Resolution (most-specific first)*. It is where the
  fallback reaches an **ARD**: `/create-ard`, `/design`, `/implement`, `/specify`, `/epics` and `/ready`
  delegate ARD lookup to it rather than resolving an ARD path themselves, so their own resolution of a
  folder would not have found an ARD in a nested directory. `/implement` in particular reaches an ARD
  solely through it, though it resolves its own positional address with §3 on a keyed run.

**Where a handoff crosses two callers, both must resolve through §3.** `/create-prd` redirects to
`/update-prd` on finding an existing PRD (its *Prior PRD* step), including one found through this
fallback; `/idea` writes `idea.md` into the folder `/create-prd` then reads, resolving it with this
file's §3 on its first write and **never relocating it afterwards** (D7). A redirect, or a first write
into a folder a command with a narrower resolution then has to find again, is a dead-end handoff, which
is why neither was deferred as low-risk.

**Adoption is additive, for every caller.** §5's fallback is reached only where the prefixed glob already
returned nothing, so a key whose folder resolves at the first attempt resolves exactly as it did before
the fallback existed — and where a command creates the folder it did not find, it still creates it
with the §2 prefix: the fallback honors a legacy folder that exists, it never proposes one. The one shared authority creates nothing at all — `ard-resolution.md` is a reader, so for it the additive
claim is simply that a resolvable key returns what it returned before: the same `found` / `none` /
`unmerged`.

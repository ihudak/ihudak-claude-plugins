# BRD addressing — Shared Reference

The key grammar and folder-resolution rule for a **BRD** (business requirements document) parent
or slice under `$SPECS_PATH/specifications/`. Written first among the BRD→PRD workflow's reference
files because every `/brd-*` command addresses a BRD folder by key, and this file is where that
addressing is defined once rather than reinvented per caller. Design authority:
`docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §4.3.

**Consumed by every `/brd-*` command** — each calls `brd-key-valid` (§1) and `resolve-brd` (§2) by
name, and `commands/brd-reconcile.md` additionally uses §2's two-level bound in reverse, scanning
both levels for the BRDs that declare a `depends-on` against the one it is reconciling — and cited by
`references/brd-format.md` and `references/coverage-ledger-format.md` for the key grammar and
folder resolution neither of them restates.
§4's fallback is **also** consumed outside the `/brd-*` family — by `/create-prd`, `/create-ard`,
`/epics`, `/specify`, `/design` and `/ready` from their own PRD-directory resolution steps, and by the
two shared authorities those six delegate to, `references/ard-resolution.md` and
`references/jira-input-resolution.md`; see the adoption note there.

## 1. Key grammar

```
^[A-Z][A-Z0-9_]*(-\d+)+$
```

A key is one or more hyphen-numeric segments after a leading alphabetic token. Both a two-segment
key (`EPIC-008`) and a three-segment key (`EPIC-008-01`) are valid — the grammar does not fix a
depth, so a BRD slice's key is exactly as valid as its parent's. **Shape is not depth**: how many
segments a key carries says nothing about where its folder sits, which §3 caps at one level below
`specifications/` regardless.

**Shape only, never checked against a tracker.** A BRD is a markdown file living in
`$SPECS_PATH`, not a Jira ticket — there is no lookup that could confirm a BRD key "exists" beyond
the folder resolution in §2. Validating shape and validating existence are two different
questions, and this section answers only the first.

### Entry point: `brd-key-valid <KEY>`

Returns `valid` when `<KEY>` matches the grammar above, `invalid` otherwise. Takes no other input
and touches no filesystem — it is a pure string test, safe to call before `$SPECS_PATH` is even
resolved.

## 2. Folder resolution

### Entry point: `resolve-brd <KEY>`

1. **Top level.** Match `specifications/<KEY>{-|_}<slug>/` — i.e. the key followed by either a
   literal `-` or `_` and then any slug. Tolerate a human-adjusted slug (the slug text itself is
   never re-derived or checked) and a stray extra `-`/`_` immediately after the key, exactly as the
   existing feature-folder resolution does for a PRD (`specifications/<PRD>-<vslug>/`,
   key-number match, `commands/design.md` and sibling commands).
2. **No match → step exactly one level deeper, and stop there.** Scan the directories found
   directly under `specifications/` and, inside each, look for a directory matching the same
   `<KEY>{-|_}<slug>/` pattern. This is the level a slice key resolves at (`EPIC-008-01` inside its
   parent's folder), and it is the last level searched.
3. **Found → return the absolute path.** Not found at either level → return `absent`.

**One level below `specifications/`, full stop — because that is the deepest a BRD folder can be.**
Nesting is capped at one level (§3): a slice is a BRD in every other respect, but it is not itself
sliceable, so no BRD folder ever exists inside a slice. A resolver that searched deeper would spend
its walk on a level the tree cannot hold, and would mask a genuinely absent key behind it instead
of answering the question. The depth of the search and the depth of the tree are the same rule,
stated once in §3 and applied here.

**It terminates because the bound is a constant, not a property of the key or of the tree.** Two
levels are scanned, each enumerating a finite set of directories; nothing found on disk can raise
that. So `resolve-brd` always answers, and always after a bounded number of scans.

**The key's segment count buys no depth.** The default key `/brd-split` proposes is the parent's
key plus one more numeric segment (`commands/brd-split.md` Phase 3), and an operator may supply any
key satisfying §1 instead, including one that adds no segment. Either resolves identically: a
segment count is a naming convention, never a depth declaration, and §1's grammar deliberately
fixes no depth.

## 3. Nesting

A child BRD (a slice produced by `/brd-split`) is not a sibling of its parent — its folder lives
**inside** the parent's folder:

```
specifications/<PARENT-KEY>-<slug>/<CHILD-KEY>-<slug>/
```

`resolve-brd <CHILD-KEY>` finds this via §2 step 2: the top-level match against
`specifications/<CHILD-KEY>-<slug>/` fails (no such directory exists directly under
`specifications/`), so the search steps one level into `specifications/<PARENT-KEY>-<slug>/` and
finds it there. The caller never supplies the parent key explicitly — resolution alone is enough
to locate a slice from its own key.

**Nesting is capped at one level: no BRD folder is ever created inside a slice.** A slice **is** a
BRD — it holds the same artifacts (`references/brd-format.md` §2.1,
`references/coverage-ledger-format.md` §1), it is ground by `/brd-ground` on its own claimed
requirements, it is allocated by `/brd-split` on its own ledger, and it may declare a `depends-on`
against any other BRD. What the cap forbids is **child creation**, and only that: run on a slice,
`/brd-split` skips its slice-proposal and child-creation phases and walks the ledger with
`covered-by` unavailable (`commands/brd-split.md` Phase 0 step 5, the `BRD_SPLIT_ON_SLICE`
notice — a notice, not a stop). So this path never exists:

```
specifications/<KEY>-<slug>/<CHILD-KEY>-<slug>/<GRANDCHILD-KEY>-<slug>/   # never created
```

**Why the cap, rather than a second inheritance rule.** A slice inherits `brd/source/` and its
defect log from its parent (`references/brd-format.md` §2.1, §4), and a grandchild's parent would
be a slice, which holds neither: its inventory header would name a `source:` path that does not
exist, and a `rejected: [DEF#n]` disposition taken against it would cite a defect log that is not
there. Chasing every inheritance up to the source-owning root would fix that, but nothing in
practice needs three levels, and the cap is one rule instead of two. **Every "its parent's" in this
route is therefore literal**: a slice's parent is always a BRD that owns the source document — which
is what makes a slice's one live inheritance, the parent's defect log behind a `rejected: [DEF#n]`,
a single hop.

**The cap is on nesting, never on allocation.** A slice whose ledger could not be walked would keep
every row `unallocated` forever and could never become PRD-eligible
(`references/coverage-ledger-format.md` §4, §5) — which would make slicing pointless, since a slice
exists precisely to become a PRD of its own. Refusing the child, not the walk, is the whole of the
cap.

## 4. The shared fallback for existing commands

`/create-prd`, `/create-ard`, `/epics`, `/specify`, `/design`, and `/ready` each resolve a PRD
directory as the flat form `specifications/<KEY>-<slug>/`, which on its own cannot see a nested PRD
(one produced under a BRD slice, once `/create-prd --from-brd` exists). All six therefore apply the
same one-level fallback described in §2: when the flat match fails, search exactly one level deeper
before reporting the PRD absent. One shared rule, defined here once rather than reinvented per
caller — and adopted by more callers than those six, per the note below.

**Adopted in eight files.** Six commands cite this section from the step that resolves their PRD
directory: `/create-prd` and `/create-ard` from their *Feature folder* step in *Phase 0 — Resolve
inputs* and *Phase 0 — Resolve input*; `/epics` from *Resolve the PRD dir* in *Phase 2.6 — PRD-level
spec enrichment (optional)*; `/specify` from *Resolve the feature folder* and `/design` from *Map
onto the specs repo + require the spec on main*, both in *Phase 0 — Resolve input*; and `/ready` from
*Map onto the specs repo (PRD dir + optional Epic subdir)* in the same phase.

Two more files adopt it, and neither is a command — both are **shared authorities the six
delegate to**, which is why the adopter count and the command count differ:

- `references/ard-resolution.md`, from step 1 of its *Resolution (most-specific first)*. It is where
  the fallback reaches an **ARD**: `/create-ard`, `/design`, `/specify`, `/epics` and `/ready`
  delegate ARD lookup to it rather than resolving an ARD path themselves, so their own adoption above
  would not have found an ARD in a nested directory.
- `references/jira-input-resolution.md`, from the PRD-folder bullet of its *Specs resolution
  (jira-driven)*. It is where the fallback reaches the **`specs` file list** that shared front-end returns to
  the commands citing it.

**Eight files, and the reach is wider than the six commands.** Two commands adopt it purely **by
delegation**, appearing nowhere in the list above: `/implement`, which resolves no PRD directory of
its own and reaches both an ARD and its `specs` list solely by citing those two files, and
`/document`, which reaches its `specs` list the same way. Counting files rather than commands is what
keeps that visible — a reader who counted only commands would conclude those two were left flat.

**Adoption is additive, in all eight.** The fallback is reached only where the flat match already
returned nothing, so a key whose folder sits directly under `specifications/` resolves exactly as it
did before any of them adopted this — and where a command creates the folder it did not find, it
still creates it flat: the fallback honors a nested folder that exists, it never proposes one.
Neither shared authority creates anything at all — both are readers, so for them the additive claim
is simply that a flat key returns what it returned before: the same `found` / `none` / `unmerged` from
`ard-resolution.md`, and the same `specs` list from `jira-input-resolution.md`.

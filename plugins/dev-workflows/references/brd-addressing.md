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
§4's `--from-brd` fallback for the six existing commands is the one part of this file nothing
consumes yet; see the note there.

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
directory today as the flat form `specifications/<KEY>-<slug>/` only — a nested PRD (one produced
under a BRD slice, once `/create-prd --from-brd` exists) is invisible to all six. Each of those six
commands is designed to gain the same one-level fallback described in §2: when the flat match
fails, search exactly one level deeper before reporting the PRD absent. Six commands, one shared
rule, defined here once rather than reinvented per command.

**Not yet adopted in this increment.** None of the six commands above has been changed to add this
fallback yet — that lands with the `--from-brd` work in increment 3. This section exists now so the
rule it states is fixed before six call sites start depending on it, not because any of them
depend on it today.

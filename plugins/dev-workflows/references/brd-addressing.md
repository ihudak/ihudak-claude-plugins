# BRD addressing — Shared Reference

The key grammar and folder-resolution rule for a **BRD** (business requirements document) parent
or slice under `$SPECS_PATH/specifications/`. Written first among the BRD→PRD workflow's reference
files because every `/brd-*` command addresses a BRD folder by key, and this file is where that
addressing is defined once rather than reinvented per caller. Design authority:
`docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §4.3.

**Consumed by** `commands/brd-intake.md`, `commands/brd-ground.md`, and `commands/brd-split.md` —
each calls `brd-key-valid` (§1) and `resolve-brd` (§2) by name — and cited by
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
depth, so a BRD slice's key is exactly as valid as its parent's.

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

0. **Compute the search depth from the key alone, before touching the filesystem.** Let `S` be the
   number of hyphen-numeric segments in `<KEY>` (`EPIC-008` → 1, `EPIC-008-01` → 2,
   `EPIC-008-01-03` → 3). The search descends at most **`max(1, S − 1)`** levels below
   `specifications/`.
1. **Top level.** Match `specifications/<KEY>{-|_}<slug>/` — i.e. the key followed by either a
   literal `-` or `_` and then any slug. Tolerate a human-adjusted slug (the slug text itself is
   never re-derived or checked) and a stray extra `-`/`_` immediately after the key, exactly as the
   existing feature-folder resolution does for a PRD (`specifications/<PRD>-<vslug>/`,
   key-number match, `commands/design.md` and sibling commands).
2. **No match → step one level deeper, and repeat, up to the depth from step 0.** At each level,
   scan the directories found at the level above and, inside each, look for a directory matching the
   same `<KEY>{-|_}<slug>/` pattern. Level 1 is what resolves a slice key (`EPIC-008-01`) living
   inside its parent's folder; level 2 is what resolves a grandchild (`EPIC-008-01-03`) inside that
   slice's folder.
3. **Found → return the absolute path.** Not found within the computed depth → return `absent`.

**Why the depth is bounded by the key rather than by a fixed number.** **A slice is a BRD** (§3),
so `/brd-split` runs on a slice exactly as it runs on a parent, and the grandchild it produces is a
BRD too. A resolver capped at one level would report `absent` for a folder that plainly exists —
the deeper the slicing, the more of the tree it could not see. A resolver with no cap at all has
the opposite failure: it masks a genuinely absent key behind an ever-longer walk of the whole
`specifications/` subtree instead of answering the question.

**It terminates because `S` is a property of the key string, fixed before any directory is read.**
The bound is computed once, in step 0, from a finite key; nothing found on disk can raise it, and
each level enumerates a finite set of directories. So `resolve-brd` always answers, and always
after a bounded number of scans — the same guarantee the one-level rule gave, now scaled to the
depth the key itself declares.

**The floor of one level is what makes the bound safe.** The default key `/brd-split` proposes is
the parent's key plus one more numeric segment (`commands/brd-split.md` Phase 3), so a key created
that way always carries enough segments to reach its own depth. An operator may supply any key that
satisfies §1 instead, including one that adds no segment; the floor guarantees such a key is still
found one level below `specifications/`, exactly as before this rule generalised — it simply buys
no further depth for slices of its own.

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

**Nesting is recursive, and nothing caps it at one level.** A slice **is** a BRD: it holds the same
artifacts (`references/brd-format.md` §2.1, `references/coverage-ledger-format.md` §1), it is
ground by `/brd-ground` on its own claimed requirements, and `/brd-split` runs on it exactly as on
a parent. So a slice of a slice is an ordinary outcome, not an edge case:

```
specifications/<KEY>-<slug>/<CHILD-KEY>-<slug>/<GRANDCHILD-KEY>-<slug>/
```

§2 step 0's depth bound is what keeps resolution in step with that: each additional numeric segment
a key carries buys exactly one more level of search, which is the depth the default keying
convention produces.

## 4. The shared fallback for existing commands

`/create-prd`, `/create-ard`, `/epics`, `/specify`, `/design`, and `/ready` each resolve a PRD
directory today as the flat form `specifications/<KEY>-<slug>/` only — a nested PRD (one produced
under a BRD slice, once `/create-prd --from-brd` exists) is invisible to all six. Each of those six
commands is designed to gain the same depth-bounded fallback described in §2: when the flat match
fails, keep searching one level at a time, up to `max(1, S − 1)` levels, before reporting the PRD
absent. Six commands, one shared rule, defined here once rather than reinvented per command.

**Not yet adopted in this increment.** None of the six commands above has been changed to add this
fallback yet — that lands with the `--from-brd` work in increment 3. This section exists now so the
rule it states is fixed before six call sites start depending on it, not because any of them
depend on it today.

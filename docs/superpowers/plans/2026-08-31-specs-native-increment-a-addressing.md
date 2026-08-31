# Specs-Native Pipeline — Increment A: the addressing model

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the BRD-only, two-level, key-only addressing rule with one tree-wide addressing authority — kind-prefixed directories, a three-level bound, one address in two forms (`<KEY>` or `@<path>`), keyless filenames, and folders that assert their own key — leaving the tracker round-trip fully intact so the plugin still runs end to end.

**Architecture:** `references/brd-addressing.md` is rewritten and renamed to `references/addressing.md`, exposing three entry points (`key-valid`, `resolve-key`, `resolve-address`). Its twelve adopters — nine commands plus three shared authorities — switch to `resolve-address`. Artifact filenames lose their keys, so three glob-based resolvers collapse to filename tests. `/brd-split` stops creating a nested `BRD-` child and creates the `PRD-` folder directly, which removes the two-kinds-in-one-namespace collision and drops the tree from four levels to three.

**Tech Stack:** Markdown only. This plugin is prose — there is no test framework, and the plan does not pretend otherwise. The test cycle is a **failing grep assertion**, then the edit, then the same grep passing, then the three repository gates.

**Spec:** `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` — approved 2026-08-31. Read §§4, 5 and 11 before starting; every task below argues from them.

**Scope:** This plan covers **increment A only**. Increments B (cut the tracker), C (refill what the tracker supplied) and D (delete `$VAULT_PATH`) get their own plans, each written once its predecessor has landed — the spec's build order requires it, and B's Phase 0 rewrites are only designable against the resolver A ships.

## Global Constraints

- **Key grammar, verbatim:** `^[A-Z][A-Z0-9_]*(-\d+)+$`. One namespace. Shape is not depth.
- **Directory naming, verbatim:** `<KIND>-<KEY>-<slug>/`, kind ∈ `BRD` | `PRD` | `EPIC`.
- **Resolution bound:** three levels below `specifications/`. A constant, never derived from a key or from the tree.
- **Additive resolution:** the unprefixed legacy form is reached **only** after the prefixed glob misses. A prefixed tree must resolve exactly as it would with no fallback present.
- **Jira is untouched in this increment.** No `jira-reader` change, no `jira-input-resolution.md` deletion, no `$VAULT_PATH` change, no `issue_type` retirement. Those are increments B and D. A that removes a tracker path has broken the "ships green, runs end to end" property.
- **Every git call against the specs repo is `git -C "$SPECS_PATH"`** — never a `cd`. (`references/specs-repo-git.md`.)
- **Every requirement ID a doc teaches is the bracketed `[PREFIX#N]` form.** `scripts/check-id-grammar.sh` enforces it.
- **No page under `plugins/dev-workflows/docs/` may name the marketplace or the containing repository.** `check-docs.sh` check 10.
- **Prose is never hard-wrapped in artifacts the plugin writes** (`references/prose-formatting.md`). The plugin's own reference and doc files follow the surrounding file's existing wrapping.
- **Branch first.** Every task commits to `iv-gu/specs-native-increment-a`, never to `main`.

## Repository Gates — run after every task

```bash
cd /workspace/ihudak-claude-plugins
./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && python3 scripts/validate-catalog.py
```

All three must exit 0. `--selftest` runs first on purpose: a gate that has stopped being able to fail is a green build that proves nothing.

---

### Task A1: The addressing authority — rewrite and rename

**Files:**
- Create: `plugins/dev-workflows/references/addressing.md`
- Delete: `plugins/dev-workflows/references/brd-addressing.md`
- Modify: the 32 files that cite it by name (mechanical), listed in Step 5
- Modify: `plugins/dev-workflows/docs/reference/references.md:9` — the entry line
- Modify: `CLAUDE.md` — the reference inventory sentence naming `brd-addressing.md`

**Interfaces:**
- Consumes: nothing. This is the seam every other task builds on.
- Produces — three entry points every later task calls by these exact names:
  - `key-valid <KEY>` → `valid` | `invalid`. Pure string test, no filesystem, safe before `$SPECS_PATH` resolves. (Was `brd-key-valid`.)
  - `resolve-key <KEY> [<KIND>]` → the resolution record below. Globs `specifications/**/*-<KEY>-*` bounded at three levels. (Was `resolve-brd`, which was bounded at two and knew no kinds.)
  - `resolve-address <ARG> [<KIND>]` → the same record. **This is the caller-facing entry point**; the nine commands and three authorities call this one and nothing else. `@`-prefixed `<ARG>` takes the path branch; anything else is `key-valid` then `resolve-key`.
- Produces — the resolution record, emitted by both resolvers:

```yaml
status: found | absent | ambiguous | invalid
path:   <absolute path of the resolved folder>   # present only on found
kind:   brd | prd | epic                         # present only on found
key:    <the folder's asserted key>              # present only on found; read, never parsed
form:   key | path                               # which form the caller supplied
legacy: true | false                             # true when §5.3's unprefixed fallback resolved it
matches: [ <absolute path>, … ]                  # present only on ambiguous
```

- [ ] **Step 1: Branch**

```bash
cd /workspace/ihudak-claude-plugins
git switch -c iv-gu/specs-native-increment-a
```

- [ ] **Step 2: Write the failing assertion**

Create `/tmp/claude-502/-workspace-ihudak-claude-plugins/f237654a-6b60-4e30-aac9-cb96f1e94e11/scratchpad/assert-a1.sh`:

```bash
#!/usr/bin/env bash
# Task A1 assertions. Exit 0 = the task landed.
set -u
P=plugins/dev-workflows
fail=0
a() { if eval "$2" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s\n' "$1"; fail=1; fi; }

a "addressing.md exists"              "[ -f $P/references/addressing.md ]"
a "brd-addressing.md is gone"         "[ ! -f $P/references/brd-addressing.md ]"
a "no stale brd-addressing citation"  "! grep -rl 'brd-addressing' $P CLAUDE.md"
a "entry point resolve-address"       "grep -q 'resolve-address' $P/references/addressing.md"
a "entry point resolve-key"           "grep -q 'resolve-key' $P/references/addressing.md"
a "entry point key-valid"             "grep -q 'key-valid' $P/references/addressing.md"
a "old entry resolve-brd retired"     "! grep -rl 'resolve-brd' $P"
a "old entry brd-key-valid retired"   "! grep -rl 'brd-key-valid' $P"
a "three-level bound stated"          "grep -qi 'three levels' $P/references/addressing.md"
a "kind prefixes stated"              "grep -q 'BRD-' $P/references/addressing.md && grep -q 'EPIC-' $P/references/addressing.md"
a "path form documented"              "grep -q '@<path>' $P/references/addressing.md"
a "ambiguous is a hard stop"          "grep -qi 'ambiguous' $P/references/addressing.md"
a "references.md entry renamed"       "grep -q '\`addressing.md\`' $P/docs/reference/references.md"
exit $fail
```

Make it executable: `chmod +x` that path.

- [ ] **Step 3: Run it and watch it fail**

Run the script from the repo root.
Expected: `FAIL` on every line except `brd-addressing.md is gone` (which also fails, since the file is still there). No line may pass by accident — if one already passes, stop and find out why before editing anything.

- [ ] **Step 4: Write `references/addressing.md`**

`git mv plugins/dev-workflows/references/brd-addressing.md plugins/dev-workflows/references/addressing.md`, then rewrite the body. The new file has six sections. What each must say:

**Preamble.** The addressing authority for **every** folder under `$SPECS_PATH/specifications/` — BRD, PRD and Epic alike — not for BRDs only. Design authority: `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` §§4–5. Name the consumers as a list, never as a count (the retired file's own instruction, and it was right).

**§1 Key grammar.** `^[A-Z][A-Z0-9_]*(-\d+)+$`, one namespace, shape is not depth. Carry over the retired file's "shape only, never checked against a tracker" paragraph — it is still true and is now true of every key, not just a BRD's. Entry point `key-valid <KEY>`.

**§2 Directory naming.** `<KIND>-<KEY>-<slug>/`. State spec §4.2's two invariants explicitly, because §3's bound is derived from the second:
1. Kinds appear in a fixed order down any path: `BRD` → `PRD` → `EPIC`, each optional at the top.
2. No path holds two folders of the same kind.

State the `PRD-PRD-1234-…` consequence and that it is a documented consequence of a documented convention, not a defect. Use the spec's own example (`EPIC-008` → `PRD-EPIC-008-01-orders`), because it is the user's real key shape rather than a hypothetical.

**§3 Resolution.** Both entry points.

`resolve-address <ARG> [<KIND>]`:
- `<ARG>` begins with `@` → **the path branch.** Strip the `@`. A directory resolves to itself; a file resolves to its parent directory. Read the folder's `kind:` and `key:` (§4). No glob, no tree walk, no ambiguity, no legacy fallback — the operator has already answered the question resolution exists to ask. Return `form: path`. A `<KIND>` argument that disagrees with the folder's own `kind:` is a stop naming both.
- otherwise → `key-valid`, then `resolve-key`. Return `form: key`.

`resolve-key <KEY> [<KIND>]`:
- Glob `specifications/**/*-<KEY>-*`, bounded at **three** levels below `specifications/`. When `<KIND>` is given, narrow the glob to `<KIND>-<KEY>-*` and refuse a match of another kind.
- Exactly one match → `status: found`.
- No match → §5's legacy fallback, then `status: absent` if that misses too. The caller decides whether `absent` is a stop or a folder to create.
- More than one match → `status: ambiguous`, a **hard stop** naming every match. Two folders with one key is a tree defect, and guessing between them would pick silently. Name `@<path>` as the way through it.

Keep the retired file's termination argument, updated: the bound is a constant, not a property of the key or of the tree, so resolution always answers after a bounded number of scans. Keep "the key's segment count buys no depth" verbatim in substance — it is still the rule and it is still the thing readers get wrong.

**§4 The kind and the key are read, never parsed.** The resolved folder's `kind:` and `key:` come from the frontmatter of an artifact inside it (Task A2 defines which fields; Task A3 puts them in the files). Nothing parses a key out of a directory name. State why, citing `CLAUDE.md`'s standing rule: a key re-derived by pattern is a key nothing asserted, and `PRD-ACME-90-01-orders` splits into key and slug only under a rule about where numeric segments stop. A `key:` that disagrees with its folder name is a hard stop naming both.

**§5 The legacy layout.** A tree written before this change holds `specifications/<KEY>-<slug>/` with no kind prefix, at one or two levels. Resolution falls back to the unprefixed form **only when the prefixed glob has already missed**, so a prefixed tree resolves exactly as it would with no fallback present. Report it once per run as deprecated. `@<path>` bypasses it along with the rest of resolution. No migration command ships (spec D14) — say why: a user's specs repo is theirs, renaming a folder is one `git mv`, and the fallback means they need never do it.

**§6 Nesting.** Rewrite the retired §3. Under spec D5 and §4.1 the child of a BRD is a **PRD folder**, not a nested BRD, so:

```
specifications/BRD-<PARENT-KEY>-<slug>/PRD-<CHILD-KEY>-<slug>/EPIC-<EPIC-KEY>-<eslug>/
```

Keep the substance of the retired file's cap argument — a slice inherits `brd/source/` and its defect log from its parent, so every "its parent's" in this route stays literal and a defect-log lookup is one hop — but state it as the §2 invariant rather than as a separate rule. Keep "the cap is on nesting, never on allocation" and the reason: a folder whose ledger could not be walked could never become PRD-eligible, which would make slicing pointless.

**§7 The shared fallback's adopter list.** Carry the retired §4's table and its three shared authorities forward **unchanged in substance** — the adopter list is still the authority on who applies it, still longer than a reader expects, and still meant to be read as a list rather than summarised as a count. Update only what the rewrite changed: the entry point is now `resolve-address`, and the fallback is §5's rather than §2's. Keep the "adoption is additive, in all twelve" paragraph and the "where a handoff crosses two adopters, both must carry it" paragraph verbatim in substance — both are load-bearing and neither is affected by the rewrite.

- [ ] **Step 5: Sweep the 32 citing files**

The rename touches every file citing the old name. Derive the list rather than trusting this one:

```bash
cd /workspace/ihudak-claude-plugins
grep -rl 'brd-addressing' plugins/dev-workflows CLAUDE.md | grep -v CHANGELOG
```

Then rewrite the citations. **Not a blind `sed`** — three distinct substitutions, and the section numbers moved:

| Old | New |
|---|---|
| `brd-addressing.md` | `addressing.md` |
| `brd-addressing.md` §1 (key grammar) | `addressing.md` §1 |
| `brd-addressing.md` §2 (folder resolution) | `addressing.md` §3 |
| `brd-addressing.md` §3 (nesting) | `addressing.md` §6 |
| `brd-addressing.md` §4 (shared fallback) | `addressing.md` §7 |
| `resolve-brd` | `resolve-address` |
| `brd-key-valid` | `key-valid` |

Do the filename substitution mechanically, then **read every §-number citation by hand** — there are 118 citations across the 32 files and the section renumbering is exactly where a mechanical sweep goes wrong. `commands/brd-split.md` (12 citations), `commands/specify.md` (7) and `commands/create-ard.md` (7) are the heaviest.

`CHANGELOG.md` keeps the old name — it is history.

- [ ] **Step 6: Update the two inventory sites**

`plugins/dev-workflows/docs/reference/references.md:9` — replace the `brd-addressing.md` bullet with an `addressing.md` bullet describing what the file now is: the key grammar, the kind-prefixed directory convention and its two invariants, the two address forms, the three-level bound, the read-never-parse rule for a folder's kind and key, and the deprecated unprefixed fallback. Keep the bullet's existing shape (backticked filename, em dash, one sentence naming the consumers).

`CLAUDE.md` — the reference-inventory sentence that names `brd-addressing.md`. Find it with `grep -n 'brd-addressing' CLAUDE.md` and rewrite it against what the file now says, not against what the old sentence said.

- [ ] **Step 7: Run the assertion — expect all green**

Run `assert-a1.sh`. Expected: every line `ok`.

- [ ] **Step 8: Run the repository gates**

Run the three-gate block from the top of this plan. All three exit 0.

`check-docs.sh` check 3 (inventory, both directions) is the one that catches a half-done rename: a reference file with no `references.md` entry, or an entry naming a file that does not exist, fails the build.

- [ ] **Step 9: Commit**

```bash
git add -A -- plugins/dev-workflows CLAUDE.md
git commit -m "refactor(addressing): one addressing authority for the whole specs tree

brd-addressing.md becomes addressing.md: kind-prefixed directories, a
three-level bound, two address forms (<KEY> or @<path>), and a folder's
kind and key read from frontmatter rather than parsed out of its name.

Entry points renamed with it - resolve-brd becomes resolve-address,
brd-key-valid becomes key-valid - and all 118 citations across 32 files
follow, including the section renumbering (2 -> 3, 3 -> 6, 4 -> 7).

Jira is untouched: the plugin still runs end to end.

Spec: docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md 4-5"
```

---

### Task A2: The artifact model — `kind:`, `key:`, and keyless filenames

**Files:**
- Modify: `plugins/dev-workflows/references/prd-format.md`
- Modify: `plugins/dev-workflows/references/ard-format.md`
- Modify: `plugins/dev-workflows/references/brd-format.md`
- Modify: `plugins/dev-workflows/references/specification-format.md`
- Modify: `plugins/dev-workflows/references/design-format.md`
- Modify: `plugins/dev-workflows/references/addressing.md` — §4 gains the per-kind carrier rule
- Modify: `plugins/dev-workflows/docs/reference/references.md` — the five format-file entries

**Interfaces:**
- Consumes: `resolve-address` from A1 (§4's read-never-parse rule needs somewhere to read from).
- Produces — two frontmatter fields every later task and every later increment relies on:
  - `kind:` — one of `prd | ard | epic | specification | design | brd | idea`. Replaces nothing yet; `issue_type:` stays until increment B (D12).
  - `key:` — the folder's asserted key, written by the plugin, matching the folder name.
- Produces — the keyless filename convention, applied by Task A3:

| Kind | Filename | Was |
|---|---|---|
| PRD | `prd.md` | `<KEY>_<slug>.md` |
| ARD, PRD-level or Epic-level | `ard.md` | `<KEY>_ARD.md`, `<EPIC>_ARD.md` |
| ARD, area-scoped | `ard-<area>.md` | `<EPIC>-<area>_ARD.md` |
| Epic | `epic.md` | vault path (increment C) |
| specification | `specification.md` | unchanged |
| design | `design.md` | unchanged |
| idea | `idea.md` | unchanged |
| release notes | `release-notes.md` | vault path (increment C) |
| implementation | `implementation.md` | did not exist (increment C) |

- [ ] **Step 1: Write the failing assertion**

Create `scratchpad/assert-a2.sh`:

```bash
#!/usr/bin/env bash
set -u
P=plugins/dev-workflows
fail=0
a() { if eval "$2" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s\n' "$1"; fail=1; fi; }

for f in prd ard brd specification design; do
  a "$f-format teaches kind:" "grep -q '^\`\?kind:' $P/references/$f-format.md || grep -q 'kind: ' $P/references/$f-format.md"
  a "$f-format teaches key:"  "grep -q 'key:' $P/references/$f-format.md"
done
a "prd-format names prd.md"           "grep -q 'prd\.md' $P/references/prd-format.md"
a "ard-format names ard.md"           "grep -q 'ard\.md' $P/references/ard-format.md"
a "ard-format names ard-<area>.md"    "grep -q 'ard-<area>\.md' $P/references/ard-format.md"
a "key-mismatch is a stop"            "grep -qi 'disagrees with' $P/references/addressing.md"
exit $fail
```

- [ ] **Step 2: Run it and watch it fail**

Expected: `FAIL` on all twelve lines except `key-mismatch is a stop`, which A1 already landed.

- [ ] **Step 3: Add the two fields to the five format references**

Each file has a frontmatter block or a "frontmatter" section describing what the artifact carries. Add both fields there, with the field's own justification stated once in `prd-format.md` and cited from the other four:

```yaml
kind: prd
key: ACME-90-01
```

The justification, in `prd-format.md`: `kind:` names what the document is, for readers and for the `@<path>` kind check, in vocabulary no tracker owns. `key:` is how the folder asserts its identity, so that everything downstream of resolution — minting an Epic key, naming a branch, citing an identifier in a report — **reads** the key rather than parsing it out of a directory name.

**`issue_type:` stays.** Retiring it is D12, increment B. A file that carries both for one increment is correct; a file that dropped `issue_type` here would break `prd-source-resolution.md`'s `issue_type: ValueIncrement` check, which is still live.

- [ ] **Step 4: State the keyless filename convention**

In each format reference, replace the keyed filename with the keyless one from the Interfaces table. The convention's own justification, stated once in `prd-format.md`: the folder carries the key, the filename carries the kind, and the Epic level already worked this way — `specification.md`, `design.md` — so this generalises an existing convention rather than inventing one.

`ard-format.md` needs the area-scoped form spelled out, because it is the one filename that still carries a discriminator: `ard-<area>.md`, where `<area>` is the same area token `ard-resolution.md` already accepts.

- [ ] **Step 5: Add §4's per-kind carrier rule to `addressing.md`**

`resolve-address` reads `kind:` and `key:` from **an artifact inside the resolved folder**. Which one is not a fixed filename, because a folder's first artifact depends on how it was created — and that is fine, because the rule is not "read file X" but:

> The command that creates a folder writes a keyed artifact into it in the same act, so a folder is never keyless — not even between its creation and its first document. A resolver reads `kind:` and `key:` off whichever artifact it had to open anyway; where it has opened none yet, it reads the first artifact in the folder carrying both fields.

State it that way rather than enumerating a carrier per kind. An enumeration here is a list that goes stale the first time a command writes a new artifact, and nothing in `scripts/` would catch it.

- [ ] **Step 6: Update `docs/reference/references.md`**

The five format-file entries each gain the two fields and the keyless filename. Keep each bullet's existing shape.

- [ ] **Step 7: Run the assertion — expect all green**

- [ ] **Step 8: Run the repository gates**

- [ ] **Step 9: Commit**

```bash
git add -A -- plugins/dev-workflows
git commit -m "feat(artifacts): kind:, key:, and keyless filenames

Every artifact gains kind: (what the document is, in vocabulary no tracker
owns) and key: (how a folder asserts its identity, so nothing downstream
parses a key out of a directory name). Filenames lose their keys - the
folder carries identity, the filename carries kind, generalising the
convention specification.md and design.md already followed.

issue_type: deliberately stays: retiring it is increment B, and
prd-source-resolution.md still checks it.

Spec: 4.3, 4.4"
```

---

### Task A3: The three shared resolvers adopt the filename tests

**Files:**
- Modify: `plugins/dev-workflows/references/ard-resolution.md` — *Resolution (most-specific first)* steps 1–2
- Modify: `plugins/dev-workflows/references/prd-source-resolution.md` — `resolve-existing-prd` steps 1, 2, 6
- Modify: `plugins/dev-workflows/references/jira-input-resolution.md` — the PRD-folder bullet of *Specs resolution (jira-driven)*
- Modify: `plugins/dev-workflows/docs/reference/references.md` — the three entries

**Interfaces:**
- Consumes: `resolve-address` (A1), the keyless filenames and `key:`/`kind:` (A2).
- Produces: three resolvers whose output shape is **unchanged** — `ard-resolution.md` still returns `status: found | none | unmerged` with `ard_paths` and `invariants`; `prd-source-resolution.md` still returns the frozen draft; `jira-input-resolution.md` still returns its `specs` list. Only how they find a file changes.

- [ ] **Step 1: Write the failing assertion**

Create `scratchpad/assert-a3.sh`:

```bash
#!/usr/bin/env bash
set -u
P=plugins/dev-workflows/references
fail=0
a() { if eval "$2" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s\n' "$1"; fail=1; fi; }

a "ard-resolution calls resolve-address"  "grep -q 'resolve-address' $P/ard-resolution.md"
a "ard-resolution globs no *_ARD.md"      "! grep -q '_ARD\.md' $P/ard-resolution.md"
a "ard-resolution names ard.md"           "grep -q '\bard\.md' $P/ard-resolution.md"
a "prd-source calls resolve-address"      "grep -q 'resolve-address' $P/prd-source-resolution.md"
a "prd-source globs no <KEY>_*.md"        "! grep -q '<KEY>_\*\.md' $P/prd-source-resolution.md"
a "prd-source names prd.md"               "grep -q 'prd\.md' $P/prd-source-resolution.md"
a "jira-input calls resolve-address"      "grep -q 'resolve-address' $P/jira-input-resolution.md"
exit $fail
```

- [ ] **Step 2: Run it and watch it fail**

- [ ] **Step 3: `ard-resolution.md`**

Step 1 becomes: resolve the folder with `resolve-address`, which already carries the legacy fallback — delete the hand-rolled "match by key-number, tolerating a stray `-`/`_`" prose and the separate fallback citation, because both are now the resolver's job. **Keep** the paragraph explaining that this step is the only route by which the fallback reaches an ARD; it is still true and it is still the reason the delegation matters.

Step 2's candidate collection becomes a filename test inside the resolved folder:
- Epic-level (`epic` set): the Epic folder's `ard.md` and any `ard-<area>.md`, **plus** the PRD folder's `ard.md` for inherited invariants.
- PRD-level (`epic` null): only the PRD folder's `ard.md`.

**Keep the `[AD-N]` legacy-reader tolerance in step 3 exactly as it is**, including its `id-grammar-ok` marker. It is a reader tolerance for ARDs authored by older installs, it has nothing to do with addressing, and removing it would silently empty the `invariants` list of a real ARD — the failure that paragraph exists to prevent.

- [ ] **Step 4: `prd-source-resolution.md`**

Step 1's grammar citation moves to `addressing.md` §1. Step 2's frozen-draft location becomes: resolve the folder with `resolve-address`, then read `prd.md`. The `issue_type: ValueIncrement` frontmatter check **stays** — the filename is now a discriminator but `issue_type` is still what distinguishes a PRD from another `.md` in older trees, and retiring it is increment B.

Step 6's secondary-grounding list: `prd.md`, `ard.md` / `ard-<area>.md`, `specification.md`.

**Everything about the Jira import stays** — steps 3, 4 and 5, the two-keys paragraph, the paste-first branch, the staleness check. Increment A does not touch the tracker.

- [ ] **Step 5: `jira-input-resolution.md`**

Only the PRD-folder bullet of *Specs resolution (jira-driven)* changes: resolve with `resolve-address`, and the `specs` list is built from the keyless filenames. The whole Fallback A–E apparatus, the `jira-products/` resolution and the two-key grammar stay — they go in increment B.

- [ ] **Step 6: Update `docs/reference/references.md`** — the three entries, where they describe how a file is found.

- [ ] **Step 7: Run the assertion — expect all green**

- [ ] **Step 8: Run the repository gates**

- [ ] **Step 9: Commit**

```bash
git add -A -- plugins/dev-workflows
git commit -m "refactor(resolvers): three glob resolvers become filename tests

ard-resolution.md, prd-source-resolution.md and jira-input-resolution.md
delegate folder resolution to resolve-address and find their files by
name instead of by key-glob. Output shapes are unchanged.

The [AD-N] legacy reader tolerance is kept deliberately - it is a reader
tolerance for older ARDs, unrelated to addressing, and dropping it would
silently empty a real ARD's invariants list.

Spec: 4.3"
```

---

### Task A3.5: The artifact writers follow the filenames

**Added during execution.** A2 defines the keyless filenames and A3 makes the three resolvers read them, but no task was assigned the commands and agents that **write** them. Left undone, `/create-ard` keeps writing `<KEY>_ARD.md` while `ard-resolution.md` looks for `ard.md` — a resolver that finds nothing, invisible to every gate because both files are internally consistent on their own. That is the dead-gate shape: a rule shipped whose consumer never gets the data.

**Files** (derived, not recalled — re-derive before starting):

```bash
cd plugins/dev-workflows
grep -rln '_ARD[.]md\|_<slug>[.]md\|<KEY>_[*][.]md' commands agents references docs
```

At the time this task was written: `commands/create-ard.md` (8), `commands/create-prd.md` (7), `commands/update-prd.md` (5), `commands/ready.md` (3), `agents/prd-reviewer.md` (3), `references/pre-lint.md` (2), `docs/roles-and-phases.md` (2), `docs/commands/{create-ard,update-prd}.md` (2 each), and one each in `agents/ard-reviewer.md`, `references/{prd-format,prd-source-resolution,coverage-ledger-format}.md`, `docs/commands/create-prd.md`.

**Interfaces:**
- Consumes: A2's filename table, A3's readers.
- Produces: writers and readers that name the same files.

- [ ] **Step 1: Write the failing assertion**

```bash
#!/usr/bin/env bash
set -u
P=plugins/dev-workflows
fail=0
a() { if eval "$2" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s\n' "$1"; fail=1; fi; }
a "no keyed ARD filename"  "! grep -rl '_ARD[.]md' $P/commands $P/agents $P/references $P/docs"
a "no keyed PRD filename"  "! grep -rl '_<slug>[.]md' $P/commands $P/agents $P/references $P/docs"
a "no <KEY>_*.md glob"     "! grep -rl '<KEY>_[*][.]md' $P/commands $P/agents $P/references $P/docs"
a "create-ard writes ard.md"    "grep -qE '[^-]ard[.]md' $P/commands/create-ard.md"
a "create-prd writes prd.md"    "grep -qE '[^-]prd[.]md' $P/commands/create-prd.md"
exit $fail
```

- [ ] **Step 2: Run it and watch it fail**

- [ ] **Step 3: Rewrite each writer**

Per the A2 filename table. Two that need judgement rather than substitution:

- **`references/pre-lint.md`'s Jira-key collision grep** (`\b[A-Z]{2,10}-[0-9]+\b`) is **not** a filename and must not be touched. `CLAUDE.md` is explicit: it reads like a key validator and is not one — it is an *autolink detector*, and its narrowness is what makes it correct. Check whether its two hits are the detector or a filename before editing either.
- **`agents/prd-reviewer.md` and `agents/ard-reviewer.md`** name the file they review. A reviewer that opens the wrong filename returns "absent" on a document that exists, which reads as a passing review of nothing.

- [ ] **Step 4: Run the assertion — expect all green**

- [ ] **Step 5: Run the repository gates**

- [ ] **Step 6: Commit**

---

### Task A4: `/brd-split` — D5, the folder merge, and the step-9 positive test

**Files:**
- Modify: `plugins/dev-workflows/commands/brd-split.md` — frontmatter description, Phase 0 step 9, Phase 3, Phase 4.5
- Modify: `plugins/dev-workflows/references/addressing.md` §6 — the worked path
- Modify: `plugins/dev-workflows/docs/commands/brd-split.md` — prose and the mermaid diagram
- Modify: `plugins/dev-workflows/docs/brd-workflow.md` — the route diagram

**Interfaces:**
- Consumes: `resolve-address` (A1), the directory convention (A2).
- Produces: the folder a BRD's child now is — `specifications/BRD-<PARENT-KEY>-<slug>/PRD-<CHILD-KEY>-<child-slug>/`, carrying `brd-link.md`, `brd/brd-inventory.md` and `coverage-ledger.md`. Task A5 and increment B's `/create-prd --from-brd` both resolve this folder.

- [ ] **Step 1: Write the failing assertion**

Create `scratchpad/assert-a4.sh`:

```bash
#!/usr/bin/env bash
set -u
C=plugins/dev-workflows/commands/brd-split.md
fail=0
a() { if eval "$2" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s\n' "$1"; fail=1; fi; }

a "Phase 3 creates a PRD- folder"     "grep -q 'PRD-<CHILD-KEY>' $C"
a "no nested BRD- child"              "! grep -q '<PARENT-KEY>-<parent-slug>/<CHILD-KEY>' $C"
a "step 9 requires brd-link.md"       "grep -q 'brd-link.md' $C && grep -qi 'positive test' $C"
a "step 9 does not match by name"     "! grep -q 'whose name matches \`<KEY>' $C"
a "always at least one slice"         "grep -qi 'at least one' $C"
a "docs page mermaid updated"         "grep -q 'PRD-' plugins/dev-workflows/docs/commands/brd-split.md"
exit $fail
```

- [ ] **Step 2: Run it and watch it fail**

- [ ] **Step 3: Phase 3 — create the PRD folder**

Phase 3 step 2 currently reads:

> **Create the folder inside this one.** `specifications/<PARENT-KEY>-<parent-slug>/<CHILD-KEY>-<child-slug>/`, per `brd-addressing.md` §3 — a child BRD is never a sibling of its parent.

It becomes:

> **Create the folder inside this one.** `specifications/BRD-<PARENT-KEY>-<parent-slug>/PRD-<CHILD-KEY>-<child-slug>/`, per `addressing.md` §6 — the folder a slice gets **is** the folder its PRD will be authored in, and it is never a sibling of its BRD.

Steps 1, 3, 4 and 5 keep their substance: the key default (`<PARENT-KEY>` plus the next unused two-digit segment), `brd-link.md` with `parent:` and `claims:`, the copied inventory, the seeded ledger. The provisional-claims paragraph in step 3 and the orphan-row rule stay verbatim in substance — spec §3's "what D5 does not simplify" says so explicitly.

Add `key:` and `kind: brd` to the child's `brd-link.md` per A2, since `brd-link.md` is the created folder's first artifact and therefore its key carrier.

- [ ] **Step 4: Phase 0 step 9 — the positive test**

Step 9 currently enumerates by name match:

> list every immediate subdirectory of `<BRD-dir>` whose name matches `<KEY>{-|_}<slug>` (`brd-addressing.md` §2 step 1), excluding `brd/`, `grounding/`, and `dev-workflows/` — none of those is ever a BRD folder.

Replace with a positive test:

> list every immediate subdirectory of `<BRD-dir>` that **contains a `brd-link.md` carrying a `parent:` field naming this BRD**. A name match plus an absent-file-reads-as-empty inference is what let an Epic folder be counted as a child and offered for removal in Phase 4.5 — `epic.md`, `specification.md` and `design.md` deleted with it. The exclusion list (`brd/`, `grounding/`, `dev-workflows/`) is no longer needed: none of those carries a `brd-link.md`, so the positive test excludes them by construction.

Keep everything else in step 9 — the `claims:` read, the standing-empty-child marking, the `reason:` note, and the "carry the marked set forward even when it is empty" rule that step 10 depends on.

- [ ] **Step 5: D5 — always at least one slice**

In Phase 2 (slice proposal), state the rule: a BRD is a container, never implementable, so this command always produces **at least one** PRD folder. An operator who confirms no slice is asked again; the run does not complete with zero.

Delete `covered-here` from the `full`-mode Phase 4 picker and its escape-valve prose — a parent BRD can no longer build a row itself. **Do not touch the `allocate-only` picker**: on a slice, `covered-here` is the normal disposition and remains its standing recommendation. The `full` picker drops from five resolutions to four; the `allocate-only` picker stays at four. Update the `<recommended>` placeholder wording that named `covered-here` on the `full` picker.

**Keep** orphan rows, standing-empty-children and `deferred-to` on a parent. Spec §3 says so by name; a reviewer who removes them has over-applied D5.

- [ ] **Step 6: Update the frontmatter description**

`brd-split.md`'s frontmatter description is one long sentence that names the five resolutions, the nested child BRD, and the one-level cap. Rewrite it against what the phases now do. This file's description has gone stale twice before — check every clause against the phase it describes rather than editing the clauses that look wrong.

- [ ] **Step 7: Update `addressing.md` §6's worked path** to the three-level form.

- [ ] **Step 8: Update the two documentation surfaces**

`docs/commands/brd-split.md`: the prose, the produced-artifact table, and **the mermaid diagram**, re-derived from the command's own `## Phase` headings rather than patched. `docs/brd-workflow.md`: the route diagram, which shows the BRD → child → PRD chain that is now BRD → PRD.

- [ ] **Step 9: Run the assertion — expect all green**

- [ ] **Step 10: Run the repository gates**

`check-docs.sh` check 11 is the one to watch: it gates the `<merge-clause>` placeholder on every `choices:` option in the `/brd-*` family, and Step 5 edits a picker.

- [ ] **Step 11: Commit**

```bash
git add -A -- plugins/dev-workflows
git commit -m "feat(brd-split): a slice's folder is its PRD folder

The iteration folder and the PRD folder merge (spec 4.1): /brd-split now
creates PRD-<CHILD-KEY>-<slug>/ directly inside the BRD instead of a
nested BRD- child that held one PRD- directory holding one file. The tree
loses a level and no path holds two folders of the same kind.

D5: a BRD is a container, never implementable - covered-here and its
escape valve leave the full-mode picker, which drops to four resolutions.
The allocate-only picker is untouched: covered-here is a slice's normal
disposition. Orphan rows, standing-empty-children and deferred-to stay.

Phase 0 step 9 becomes a positive test on brd-link.md's parent: field. A
name match plus an absent-file-reads-as-empty inference is what let an
Epic folder be counted as a child and offered for removal, deleting
epic.md, specification.md and design.md with it.

Spec: D5, 3, 4.1"
```

---

### Task A5: PRD eligibility follows the merge

**Files:**
- Modify: `plugins/dev-workflows/references/coverage-ledger-format.md` §5, and §4's escape valve
- Modify: `plugins/dev-workflows/commands/create-prd.md` — the `--from-brd` eligibility gate
- Modify: `plugins/dev-workflows/docs/reference/references.md` — the `coverage-ledger-format.md` entry
- Modify: `plugins/dev-workflows/docs/commands/create-prd.md`

**Interfaces:**
- Consumes: the PRD folder A4 creates, and the four-resolution `full`-mode picker.
- Produces: the eligibility rule increment B's `/create-prd --from-brd` Phase 0 refusals read.

- [ ] **Step 1: Write the failing assertion**

Create `scratchpad/assert-a5.sh`:

```bash
#!/usr/bin/env bash
set -u
R=plugins/dev-workflows/references/coverage-ledger-format.md
fail=0
a() { if eval "$2" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s\n' "$1"; fail=1; fi; }

a "eligibility names no <BRD-KEY>_<slug>.md" "! grep -q '<BRD-KEY>_<slug>\.md' $R"
a "eligibility names prd.md"                 "grep -q 'prd\.md' $R"
a "never-split case retired"                 "! grep -q 'the BRD was never split' $R"
exit $fail
```

- [ ] **Step 2: Run it and watch it fail**

- [ ] **Step 3: Rewrite §5's eligibility rule**

Eligibility is now a property of a **PRD folder**, never of a parent BRD. Concretely:

- The eligible case's "may go on to author its own `<BRD-KEY>_<slug>.md`" becomes "may go on to author its own `prd.md`".
- **Row 2 of the three-ways table — "No row is `covered-by`: the BRD was never split" — is deleted.** Under D5 `/brd-split` always produces at least one PRD folder, so a walked BRD is never unsplit. Delete §4's escape valve for the same reason: it existed to let a never-split BRD complete.
- Rows 1 and 3 stay. Row 3 (the slice case) becomes the **main** case rather than a special one, since every PRD folder is what row 3 described.
- Keep the "name no child that does not exist" rule and the "`the requirements are deferred` is the common shape of those cases, not the whole of them" paragraph. Both are about honest reporting and neither depends on D5.
- Keep the last three paragraphs verbatim in substance — orphan rows can neither create eligibility nor withhold it; eligibility is read from the ledger, not decided in advance; read it from the ledger file, never from the §6 line. All three are load-bearing and A4 did not touch what they say.

- [ ] **Step 4: `/create-prd`'s gate**

`/create-prd --from-brd`'s Phase 0 has two refusals — a claimed ledger row still `unallocated`, and no `covered-here` row at all. Both now read the **PRD folder's own** ledger, which is the folder `/create-prd` was given. The refusals' substance is unchanged; what changes is that there is no longer a parent-versus-child question about which ledger they read.

- [ ] **Step 5: Update the two documentation surfaces.**

- [ ] **Step 6: Run the assertion — expect all green**

- [ ] **Step 7: Run the repository gates**

- [ ] **Step 8: Commit**

```bash
git add -A -- plugins/dev-workflows
git commit -m "refactor(ledger): PRD eligibility is a property of a PRD folder

Eligibility now names prd.md rather than <BRD-KEY>_<slug>.md, and the
never-split case is retired along with section 4's escape valve: under D5
/brd-split always produces at least one PRD folder, so a walked BRD is
never unsplit. The slice case becomes the main case.

The orphan-row, read-from-the-ledger and never-from-the-line rules are
kept verbatim in substance - none depends on D5.

Spec: D5, 3"
```

---

### Task A6: The nine commands resolve one address

**Files:**
- Modify, each at its own PRD-directory resolution step (named in `addressing.md` §7's table): `commands/create-prd.md`, `commands/update-prd.md`, `commands/create-ard.md`, `commands/epics.md`, `commands/specify.md`, `commands/design.md`, `commands/ready.md`, `commands/idea.md`, `commands/release-notes.md`
- Modify: the six `/brd-*` commands' Phase 0 resolution steps
- Modify: the matching pages under `plugins/dev-workflows/docs/commands/`

**Interfaces:**
- Consumes: `resolve-address` (A1) and its resolution record.
- Produces: fifteen commands whose folder resolution is one call. Increment B rewrites what they take as an **argument**; this task only changes how the argument they already take is resolved.

- [ ] **Step 1: Write the failing assertion**

Create `scratchpad/assert-a6.sh`:

```bash
#!/usr/bin/env bash
set -u
P=plugins/dev-workflows/commands
fail=0
a() { if eval "$2" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s\n' "$1"; fail=1; fi; }

for c in create-prd update-prd create-ard epics specify design ready idea release-notes \
         brd-intake brd-ground brd-split brd-interview brd-package brd-reconcile; do
  a "$c calls resolve-address" "grep -q 'resolve-address' $P/$c.md"
done
a "no command re-states the key grammar" \
  "[ \$(grep -l '\[A-Z\]\[A-Z0-9_\]\*(-' $P/*.md | wc -l) -eq 0 ]"
a "ambiguous stop is reachable" "grep -rq 'ambiguous' $P"
exit $fail
```

The middle assertion is the important one: it is the defect family `CLAUDE.md` calls the longest-running of 3.3.0 — four sites re-stated a key grammar locally instead of citing the one the authority fixes, the copies drifted, and a valid key hard-stopped a command its own redirect had sent it to.

- [ ] **Step 2: Run it and watch it fail**

- [ ] **Step 3: Rewrite each command's resolution step**

For each of the fifteen, at the step `addressing.md` §7's table names:

1. Replace the hand-rolled key match (`match by key-number, tolerating a stray -/_ and a human-adjusted slug`, or `resolve-brd`) with one `resolve-address` call.
2. Delete any locally re-stated key grammar; cite `addressing.md` §1 instead.
3. Branch on the record's `status`:
   - `found` → proceed, using `path`, `kind` and `key` from the record.
   - `absent` → the command's **existing** behaviour for a missing folder, unchanged. A command that created the folder flat still creates it — now prefixed, per A2's convention.
   - `ambiguous` → stop, naming every match and `@<path>` as the way through.
   - `invalid` → the command's existing malformed-key stop.
4. Where the command supports more than one level (`/epics`, `/create-ard`, `/specify`, `/ready`), branch on `kind` rather than on the number of positional arguments. **The two-key argument grammar stays for now** — collapsing `/specify <PRD> <EPIC>` to one key is increment B.

- [ ] **Step 4: Check the two delegating commands**

`/implement` and `/document` resolve no folder of their own — they reach one only through `ard-resolution.md` and `jira-input-resolution.md`, both updated in A3. Verify by grep that neither has grown a resolution step of its own:

```bash
grep -n 'specifications/' plugins/dev-workflows/commands/implement.md plugins/dev-workflows/commands/document.md
```

Every hit must be a citation of a shared authority, not a local resolution. If one is local, it is an unlisted adopter — fix it here and add it to `addressing.md` §7's table.

- [ ] **Step 5: Update the fifteen documentation pages**, including each page's mermaid diagram where the resolution step appears in it.

- [ ] **Step 6: Run the assertion — expect all green**

- [ ] **Step 7: Run the repository gates**

- [ ] **Step 8: Commit**

```bash
git add -A -- plugins/dev-workflows
git commit -m "refactor(commands): fifteen commands resolve one address

Every PRD- and BRD-directory resolution step becomes a single
resolve-address call. Locally re-stated key grammars are deleted and
cited from addressing.md 1 instead - the defect family where four copies
of one grammar drifted apart and a valid key hard-stopped a command its
own redirect had sent it to.

Argument grammars are unchanged: collapsing the two-key forms is
increment B. This task changes only how the argument is resolved.

Spec: 5.2, 5.4"
```

---

### Task A7: Residue audit and increment review

**Files:** whatever the audit finds.

**Interfaces:**
- Consumes: everything A1–A6 changed.
- Produces: a green increment with no known unfixed defect, and a written record of what the audit checked.

- [ ] **Step 1: Run the four mechanical sweeps**

These four came back clean in the 2026-08-31 round and are worth reusing rather than re-inventing:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# 1. Stop codes named in docs vs defined in commands
diff <(grep -rhoE '\b[A-Z][A-Z0-9_]{6,}\b' docs/ | sort -u) \
     <(grep -rhoE '\b[A-Z][A-Z0-9_]{6,}\b' commands/ | sort -u) | head -40
# 2. Agents dispatched vs named per page (check the UNDER-report direction)
for f in commands/*.md; do n=$(basename "$f" .md); \
  comm -23 <(grep -ohE 'dev-workflows:[a-z-]+' "$f" | sort -u) \
           <(grep -ohE 'dev-workflows:[a-z-]+' "docs/commands/$n.md" 2>/dev/null | sort -u); done
# 3. Documented flags vs parsed flags
for f in commands/*.md; do n=$(basename "$f" .md); \
  comm -13 <(grep -ohE '^\s*[-*] `--[a-z-]+' "docs/commands/$n.md" 2>/dev/null | grep -oE '\-\-[a-z-]+' | sort -u) \
           <(grep -ohE '\-\-[a-z-]+' "$f" | sort -u); done
# 4. Produced-artifact tables vs deliverable_paths
grep -rn 'deliverable_paths' commands/ | head -20
```

Phase-title comparison is **not** worth running — collapsed mermaid nodes and multi-mode commands reusing phase numbers drown it in noise.

- [ ] **Step 2: Run the residue audit**

The question is not *"did my rule land everywhere"* but **"what did this increment make false?"** That framing found five of the 2026-08-31 round's findings and four of its documentation stalls. Sweep **by phrase, never by line number**, for sentences that were true before A and are false after:

| Phrase to sweep for | Why it is now false |
|---|---|
| `two-level` / `one level deeper` / `two levels` | the bound is three |
| `nesting is capped at one level` | still true of PRD folders, but the sentence now sits beside a three-level tree — re-read each instance against §4.2's invariant 2 |
| `child BRD` / `a slice is a BRD` | a slice's folder is a PRD folder |
| `covered-here` on a parent | retired by D5 |
| `<KEY>_<slug>.md` / `*_ARD.md` / `<KEY>_*.md` | keyless filenames |
| `resolve-brd` / `brd-key-valid` | renamed |
| `never split` | D5 makes it unreachable |
| `five resolutions` / `four resolutions` | the `full` picker is now four; the `allocate-only` picker was always four |

For each hit: rewrite it against **what the shipped thing now enforces**, read out of its own phase, not against what this plan says it should enforce. A sentence that named an absence as its *reason* for an offer needs a new reason, not a deletion.

- [ ] **Step 3: Re-derive every count you touched**

`CLAUDE.md` states inventory numbers that nothing gates. A1–A6 did not add or remove a command, agent, hook, skill or environment variable, and the reference-file count is unchanged by a rename — so **no count should have moved**. Verify rather than assume:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
ls commands/*.md | wc -l; ls agents/*.md | wc -l; find references -type f | wc -l; ls hooks/*.sh | wc -l
```

If one moved, the increment did something it was not supposed to. Find out what before changing a number.

- [ ] **Step 4: Read every changed command end to end**

Not a diff read — a **read-through**. A diff shows what changed; it does not show a phase that now contradicts a phase the diff did not touch. Prioritise `brd-split.md` (the heaviest change) and the four multi-level commands.

- [ ] **Step 5: Fix every defect found**

Every one, before the increment closes. A defect unrelated to increment A is still fixed — in its own PR where that keeps this branch's diff readable. Nothing is carried forward as a known-but-unfixed finding.

One known-standing item is **not** increment A's to fix and is not a defect it introduced: the 40 `choices:` arrays exceeding `AskUserQuestion`'s four-option maximum. It has its own PR.

The absent cost emission in `/upgrade` and `/vuln` is **not** a finding — it is a deliberate exemption (spec §9.1). Do not "fix" it. If the audit surfaces it, the correct action is to confirm `cost-emission.md` §7 and `docs/reference/session-cost.md` state the exemption and its reason; adding emission would be the defect.

- [ ] **Step 6: Run the repository gates one final time, then open the PR**

```bash
cd /workspace/ihudak-claude-plugins
./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && python3 scripts/validate-catalog.py
git push -u origin iv-gu/specs-native-increment-a
gh pr create --title "Increment A: the addressing model" --body "$(cat <<'EOF'
Implements increment A of `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md`.

One addressing authority for the whole specs tree, kind-prefixed directories, a three-level bound, two address forms, keyless filenames, and a folder that asserts its own key. `/brd-split` creates the PRD folder directly, which removes the two-kinds-in-one-namespace collision.

**Jira is untouched.** The plugin runs end to end; cutting the tracker is increment B.

Gates: `check-docs.sh --selftest` + `--root .`, `check-id-grammar.sh --selftest` + `--root .`, `validate-catalog.py` — all green.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01LpEV21VKMLmmcrENYq6v9k
EOF
)"
```

- [ ] **Step 7: Bump the version and changelog**

`plugins/dev-workflows/.claude-plugin/plugin.json` and `CHANGELOG.md`. This is a breaking change to the tree layout, so it is a **minor** bump at least — the legacy fallback means it is not major.

**Do not touch the plugin description.** It sits at 898 of a 900-character warning threshold; rewriting it is increment D's, and appending to it is what took it to 2788 characters once already.

---

## Self-Review

**Spec coverage — increment A's four sentences, mapped:**

| Spec §11 increment A clause | Task |
|---|---|
| "Rewrite `brd-addressing.md` for kind prefixes, the three-level bound, one-address resolution, keyless filenames, `key:` frontmatter and the legacy fallback" | A1, A2 |
| "Update its twelve adopters — nine commands plus `ard-resolution.md`, `jira-input-resolution.md` and `prd-source-resolution.md`" | A3 (the three authorities), A6 (the nine commands + the six `/brd-*`) |
| "Apply D5, the §4.1 folder merge and the step-9 positive test to `/brd-split`" | A4 |
| "follow through `coverage-ledger-format.md` §5 and `/create-prd`'s gate" | A5 |
| "Rename artifact files (§4.3) and simplify the three resolvers" | A2 (the convention), A3 (the resolvers), **A3.5 (the writers — added during execution; the original mapping covered the readers and left the writers unassigned)** |
| §11 "Verification, every increment" + "Review protocol" | A7 |

**Two gaps I found and closed while checking:** the spec's increment-A sentence names nine commands, but the six `/brd-*` commands also call the renamed entry points — A6 covers all fifteen. And the spec does not say where `kind:`/`key:` are *defined* as opposed to used, which is why A2 exists as its own task rather than as a step inside A1.

**Placeholder scan:** no TBD, no "handle edge cases", no "similar to Task N". Every rewrite step names the file, the section by its own heading or opening phrase, and what the replacement must say.

**Name consistency:** `resolve-address` / `resolve-key` / `key-valid` are used identically in A1's Interfaces, A3, A6 and every assertion script. The resolution record's field names (`status`, `path`, `kind`, `key`, `form`, `legacy`, `matches`) appear only in A1 and A6, and match.

**What this plan deliberately does not do**, so a reviewer does not read it as an omission: no `jira-reader` change, no `$VAULT_PATH` change, no argument-grammar collapse, no `issue_type` retirement, no `/epics` key minting, no `implementation.md`. Each belongs to B, C or D, and A shipping without them is what makes A revertible.

---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# Effort B1b — Monotonic Phase Renumber Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `/document` (Jira mode) Phase 6 cluster physically, numerically, and execution-order monotonic (and tidy the one odd `/epics` number), with zero behavior change.

**Architecture:** Three tasks. Task 1 reorders + renumbers `commands/document.md` Mode A and deletes the now-redundant execution-order note. Task 2 sweeps every cross-reference to a renumbered phase across the other 16 files, mapped **per-site** (bare "Phase 6" means the docs Write phase in `/document` context → `6.3`, but stays `6` in `/epics` / `/release-notes` / `/docs-profile` context). Task 3 ships PATCH `v2.0.1`.

**Tech Stack:** Markdown + Handlebars command/agent/reference files in a Claude Code plugin (`/workspace/ihudak-claude-plugins/plugins/dev-workflows`). No test framework — verification is **structural** (grep anchors, heading-order checks, `git diff` inspection, `python3 -c json.load` for manifests).

## Global Constraints

- **Repo / branch:** work in `/workspace/ihudak-claude-plugins`. Branch off `origin/main` (`2331622`, v2.0.0): `ivgu/NOISSUE-phase-renumber`. Never start on `main`.
- **Zero behavior change.** Phase *content* (steps, gates, agent dispatches, git semantics) is byte-identical. Only headings, physical order of the Branch-setup block, the deleted note, cross-reference phase numbers, and the release manifests change.
- **Bare "Phase 6" is ambiguous — map per-site, never blind-replace.** In `/document` (docs pipeline) context it is the **Write** phase → `6.3`. In `/epics`, `/release-notes`, and `/docs-profile` context it is that command's own Phase 6 and **stays `6`**.
- **Substantive completion gate** (hardened — the literal `Phase 6.7` form misses bare `(6.7)`, plural `Phases 6.7`, and non-`Phase` refs): `grep -rnE '6\.[78]' plugins/dev-workflows --include='*.md' | grep -vE 'CHANGELOG.md|fix-vuln/nvd-api'` MUST return **EMPTY** after Task 2 — `6.7`/`6.8` are fully retired as phases (6.7 → 6.4 docs / 6.1 epics; 6.8 → 6.5). The exclusions are: `CHANGELOG.md` (history + the new entry mention the old numbers) and `references/fix-vuln/nvd-api.md` (`5.16.7` etc. are CVE version numbers, not phases). Reused numbers (`6.1`, `6.2`, `6.5`, bare `6`) cannot gate to empty and are verified by reading — and watch for **non-`Phase` forms** (bare `(6)`, `(6.2)`, plural `Phases 6.x`) which the `Phase 6(\.\d)?` map does NOT reach.
- **Preserve CHANGELOG history** — only prepend the new `[2.0.1]` entry; never edit existing entries (their historical "Phase 6.x" references stay as written).
- **Release = PATCH `v2.0.1`:** `plugin.json` top-level `version`; `marketplace.json` **`plugins[0].version`** (NOT top-level, NOT the other plugin entries); `CHANGELOG.md` `## [2.0.1] — 2026-06-28` (em-dash date).
- **Commit hygiene:** stage explicit paths only — never `git add -A`, never stage `.superpowers/` or `.docstack`. Commit trailer on every commit:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
  The `.husky/pre-commit` hook runs prettier on staged `*.md`/`*.json`; if pnpm/prettier is unavailable, commit with `--no-verify` and note it in the report so the user runs `pnpm prettier -w <files>` before pushing.

---

## The authoritative renumber map

**Docs cluster — `/document` (Jira mode) Mode A, and every `/document`-context cross-reference (`document.md`, `README`, the docs agents, the docs references):**

| Phase | Old → New |
|-------|-----------|
| CDN image handoff | `6.2` → **`6.1`** |
| Branch setup *(block moves to before Write)* | `6.5` → **`6.2`** |
| Write documentation | `6` → **`6.3`** |
| Style check | `6.7` → **`6.4`** |
| Render verification | `6.8` → **`6.5`** |

`Phase 6.<x>` for any other `<x>` (none exist) and all `Phase 5.x / 7 / 8 / 8.5 / 9` are unchanged.

**Epics cluster — `/epics` (`epics.md`, `epic-reviewer.md`, `epic-writer.md`):**

| Phase | Old → New |
|-------|-----------|
| Write Epics | `6` → **stays `6`** |
| Dynatrace style check | `6.7` → **`6.1`** |

**Other contexts (unchanged):** `/release-notes` Phase 6 ("Render the draft") stays `6`; `/docs-profile` Phase 6 ("Final report") stays `6`. The single exception in `docs-profile.md` is line 163, which is a **`/document` cross-reference** (`6.5` → `6.2`).

### The renumber mechanism (collision-free, single pass)

Because the renumber **reuses** numbers (old `6.5`→`6.2` while old `6.2`→`6.1`; old `6.8`→`6.5` while old `6.5`→`6.2`), a sequential `sed` chain corrupts. Use this **atomic** `perl` substitution, which matches each `Phase 6` / `Phase 6.N` token once and maps it via a hash in a single pass — the **docs map**:

```bash
DOCS_RENUMBER() {
  perl -i -pe '
    s{Phase 6(\.\d)?}{
      my $k = "6" . ($1 // "");
      my %m = ("6"=>"6.3", "6.2"=>"6.1", "6.5"=>"6.2", "6.7"=>"6.4", "6.8"=>"6.5");
      "Phase " . ($m{$k} // $k);
    }ge
  ' "$1"
}
```

Why it is safe:
- `Phase 6(\.\d)?` matches `Phase 6`, `Phase 6.2`, `Phase 6.5`, `Phase 6.7`, `Phase 6.8` atomically and replaces atomically — no re-scan, so no collision between source and target numbers.
- `Phase 6.` at a **sentence end** (e.g. "skip to Phase 6.") → the `(\.\d)?` does not match a non-digit, so it maps bare `6`→`6.3`, giving "Phase 6.3." — correct.
- `Phases 3–6.2` (the range endpoint in `doc-writer.md:7`) does **not** contain the token `Phase 6` (it is `Phases`, and `6.2` is not preceded by `Phase `), so it is **left intact** — correct (after the renumber `6.2` denotes Branch setup, still the last pre-writer phase).

For the **epics** files and the one `docs-profile.md` cross-ref, the map differs (bare `6` must stay), so those use targeted single-number substitutions (Task 2, Part B).

> If `perl` is unavailable, the equivalent `python3` one-liner is:
> `python3 -c "import re,sys; p=sys.argv[1]; m={'6':'6.3','6.2':'6.1','6.5':'6.2','6.7':'6.4','6.8':'6.5'}; s=open(p).read(); open(p,'w').write(re.sub(r'Phase 6(\.\d)?', lambda x: 'Phase '+m.get('6'+(x.group(1) or ''), '6'+(x.group(1) or '')), s))" FILE`

### Complete per-site cross-reference inventory (enumerate-first result)

This is the full set of files carrying a `Phase 6.x` token (excluding `CHANGELOG.md`, whose history is preserved). Task 1 owns `document.md`; Task 2 owns the rest.

| File | Tokens present | Map to apply |
|------|----------------|--------------|
| `commands/document.md` | 6.2, 6, 6.5, 6.7, 6.8 (+ note) | **Task 1** — docs map + block move + note delete |
| `README.md` | 6 (×2), 6.8 (×2), 6.5 | docs map |
| `agents/doc-location-finder.md` | 6 | docs map |
| `agents/doc-planner.md` | 6 (×6) | docs map |
| `agents/doc-reviewer.md` | 6 (×2), 6.7 (×2) | docs map |
| `agents/doc-writer.md` | 6.2, 6.5, 6.7, 6 (keep `Phases 3–6.2`) | docs map |
| `agents/docs-style-checker.md` | 6, 6.7 (Phase 3/3.5 untouched) | docs map |
| `references/dynatrace-docs/multi-space-writing.md` | 6.7, 6 (×2) | docs map |
| `references/dynatrace-docs/render-verification.md` | 6.8 (×4), 6 (×2), 6.7 | docs map |
| `references/dynatrace-docs/docs-profile-schema.md` | 6.8 | docs map |
| `references/finish-and-handoff.md` | 6.5 (×3), 6.8 | docs map |
| `references/source-truth.md` | 6 (×2) | docs map |
| `agents/epic-reviewer.md` | 6.7, 6 (×2 — stay) | **6.7 → 6.1** only |
| `agents/epic-writer.md` | 6.7, 6 (stay) | **6.7 → 6.1** only |
| `commands/epics.md` | 6.7 (×5), 6 (stay) | **6.7 → 6.1** only |
| `commands/docs-profile.md` | 6.5 (line 163), 6 (stay) | **6.5 → 6.2** only |
| `commands/release-notes.md` | 6 (own — STAYS) | **no change** |

---

## Task 1: `document.md` Mode A — reorder, renumber, delete the note

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md` (Mode A cluster, lines ~493–625 and all in-file `Phase 6.x` cross-refs)

**Interfaces:**
- Consumes: nothing from earlier tasks (first task).
- Produces: the renumbered `document.md` whose Phase 6 headings read, in physical order, `6.1` CDN → `6.2` Branch setup → `6.3` Write → `6.4` Style → `6.5` Render. Task 2 relies on this map being applied identically to `/document`-context cross-refs in other files.

**Model suggestion:** Opus implementer + Opus reviewer (semantic care — block move, note deletion, ambiguity).

- [ ] **Step 1: Create the branch**

```bash
cd /workspace/ihudak-claude-plugins
git fetch origin
git switch -c ivgu/NOISSUE-phase-renumber origin/main
git log --oneline -1   # expect 2331622 ... v2.0.0
```

- [ ] **Step 2: Delete the execution-order apology note**

Delete the entire paragraph at `document.md:517` (the only line between the `## Phase 6 — Write documentation` heading and the `The writing is delegated to the **doc-writer**...` paragraph). The exact text to remove (and its trailing blank line):

```
**Execution order with Phase 6.5 (branch setup).** When branching applies — write context `docs_repo` (or confirmed `non_docs_repo`) **and** the user opted into branching at plan approval — **Phase 6.5 runs *before* this phase**: it creates (or, for an inline-profiling run, renames) the branch off the base, and this phase then writes and commits onto that branch. Follow this execution order, not the numeric phase order (the `6.2`/`6`/`6.5`/`6.7`/`6.8` cluster is pending a monotonic renumber). For `obsidian`/`plain_dir` or no-branch runs, no branch is created and this phase writes in place without committing.
```

After deletion, the Write phase reads: heading `## Phase 6 — Write documentation`, then directly the `The writing is delegated...` paragraph. The branch/commit **table** (currently lines 540–545) and the line `Write context governs branch/commit (Phase 0 step 7); **the orchestrator commits the writer's output**...` are **kept** — they carry the actual semantics. Do not add any replacement note.

- [ ] **Step 3: Verify the note is gone, content intact**

```bash
grep -n 'Execution order with Phase\|pending a monotonic renumber' plugins/dev-workflows/commands/document.md   # EMPTY
grep -c 'the orchestrator commits the writer' plugins/dev-workflows/commands/document.md                          # 1 (semantics kept)
```
Expected: first grep prints nothing; second prints `1`.

- [ ] **Step 4: Move the Branch-setup block to before Write**

Swap the two adjacent sections so Branch setup physically precedes Write. The Branch-setup section runs from the line `## Phase 6.5 — Branch setup (conditional)` through its last body line `No external CLI calls; all git operations are local.`; the Write section runs from `## Phase 6 — Write documentation` through the end of its branch/commit table (`| plain_dir | NEVER | NEVER |`). They are currently in order Write → `---` → Branch. Re-order them to Branch → `---` → Write, **preserving the `---` separator between them and every body line byte-for-byte** (only the order of the two blocks changes).

Concretely, perform a single Edit whose `old_string` is the full Write section + the `\n\n---\n\n` separator + the full Branch section, and whose `new_string` is the full Branch section + the same `\n\n---\n\n` separator + the full Write section. Read the current file region first to capture both blocks exactly.

- [ ] **Step 5: Apply the docs renumber map to the whole file**

```bash
cd /workspace/ihudak-claude-plugins
DOCS_RENUMBER() {
  perl -i -pe '
    s{Phase 6(\.\d)?}{
      my $k = "6" . ($1 // "");
      my %m = ("6"=>"6.3", "6.2"=>"6.1", "6.5"=>"6.2", "6.7"=>"6.4", "6.8"=>"6.5");
      "Phase " . ($m{$k} // $k);
    }ge
  ' "$1"
}
DOCS_RENUMBER plugins/dev-workflows/commands/document.md
```

(Mode A is the only part of `document.md` with `Phase 6` tokens; Mode B uses Phase 3/3.5 and is untouched — verified in Step 6.)

- [ ] **Step 6: Verify renumber + monotonic physical order**

```bash
cd /workspace/ihudak-claude-plugins
echo "=== headings in physical order (must be 6.1,6.2,6.3,6.4,6.5) ==="
grep -nE '^## Phase 6' plugins/dev-workflows/commands/document.md
echo "=== retired numbers (must be EMPTY) ==="
grep -n 'Phase 6\.7\|Phase 6\.8' plugins/dev-workflows/commands/document.md
echo "=== Branch-setup body anchor sits between 6.1 and 6.3 ==="
grep -n 'symbolic-ref --short refs/remotes/origin/HEAD' plugins/dev-workflows/commands/document.md
echo "=== doc-writer range endpoint intact ==="
grep -n 'Phases 3–6.2' plugins/dev-workflows/commands/document.md   # (this token lives in doc-writer.md, not here — expect EMPTY in document.md; informational)
echo "=== Mode B unaffected (no Phase 6 below the Mode B marker) ==="
awk '/^# Mode B/{b=1} b && /Phase 6/{print NR": "$0}' plugins/dev-workflows/commands/document.md   # EMPTY
```

Expected: the five `## Phase 6.x` headings print in ascending order `6.1`(CDN) → `6.2`(Branch setup) → `6.3`(Write) → `6.4`(Style) → `6.5`(Render); the retired-numbers grep is EMPTY; the `symbolic-ref` anchor line number falls between the `6.1` and `6.3` heading line numbers; the Mode B awk is EMPTY.

- [ ] **Step 7: Inspect the diff — confirm pure renumber/reorder, no content change**

```bash
git -C /workspace/ihudak-claude-plugins diff --stat plugins/dev-workflows/commands/document.md
git -C /workspace/ihudak-claude-plugins diff plugins/dev-workflows/commands/document.md | grep -E '^[+-]' | grep -vE 'Phase 6|^\+\+\+|^---|Execution order|pending a monotonic' | head -40
```
Expected: the `--stat` shows only `document.md`; the second command (added/removed lines that are NOT phase-number or note lines) shows only the relocated Branch/Write block lines (moved verbatim), nothing else. Any unexpected `+`/`-` line is a content change and must be reverted.

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/document.md
git commit -m "$(cat <<'EOF'
PRODUCT v2.0.1: document.md Mode A — monotonic Phase 6 renumber + Branch-setup reorder

Move Branch-setup before Write, renumber CDN 6.2→6.1 / Branch 6.5→6.2 /
Write 6→6.3 / Style 6.7→6.4 / Render 6.8→6.5, delete the now-redundant
execution-order note. Physical = numeric = execution. No behavior change.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Per-site cross-reference sweep (all other files)

**Files:**
- Modify (docs map): `plugins/dev-workflows/README.md`, `agents/doc-location-finder.md`, `agents/doc-planner.md`, `agents/doc-reviewer.md`, `agents/doc-writer.md`, `agents/docs-style-checker.md`, `references/dynatrace-docs/multi-space-writing.md`, `references/dynatrace-docs/render-verification.md`, `references/dynatrace-docs/docs-profile-schema.md`, `references/finish-and-handoff.md`, `references/source-truth.md`
- Modify (epics map, `6.7`→`6.1` only): `commands/epics.md`, `agents/epic-reviewer.md`, `agents/epic-writer.md`
- Modify (one cross-ref, `6.5`→`6.2`): `commands/docs-profile.md`
- Untouched: `commands/release-notes.md` (its Phase 6 is its own — verify it did not change)

**Interfaces:**
- Consumes: the docs map from Task 1 (identical mapping; the `DOCS_RENUMBER` function above).
- Produces: the global retirement gate `grep -rn 'Phase 6\.7\|Phase 6\.8' plugins/dev-workflows` = EMPTY.

**Model suggestion:** Sonnet implementer; **Opus reviewer** (the docs-vs-epics "bare Phase 6" distinction is the dominant risk and warrants Opus reading the surviving hits).

- [ ] **Step 1: Apply the docs map to the 11 `/document`-context files**

```bash
cd /workspace/ihudak-claude-plugins
DOCS_RENUMBER() {
  perl -i -pe '
    s{Phase 6(\.\d)?}{
      my $k = "6" . ($1 // "");
      my %m = ("6"=>"6.3", "6.2"=>"6.1", "6.5"=>"6.2", "6.7"=>"6.4", "6.8"=>"6.5");
      "Phase " . ($m{$k} // $k);
    }ge
  ' "$1"
}
for f in \
  plugins/dev-workflows/README.md \
  plugins/dev-workflows/agents/doc-location-finder.md \
  plugins/dev-workflows/agents/doc-planner.md \
  plugins/dev-workflows/agents/doc-reviewer.md \
  plugins/dev-workflows/agents/doc-writer.md \
  plugins/dev-workflows/agents/docs-style-checker.md \
  plugins/dev-workflows/references/dynatrace-docs/multi-space-writing.md \
  plugins/dev-workflows/references/dynatrace-docs/render-verification.md \
  plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md \
  plugins/dev-workflows/references/finish-and-handoff.md \
  plugins/dev-workflows/references/source-truth.md ; do
    DOCS_RENUMBER "$f"
done
```

- [ ] **Step 2: Apply the epics map (`6.7`→`6.1`) — bare `Phase 6` stays**

These files contain no other dotted `Phase 6.x` token, so a single-number substitution is collision-free and leaves the epics Write phase (`Phase 6`) intact:

```bash
cd /workspace/ihudak-claude-plugins
perl -i -pe 's{Phase 6\.7}{Phase 6.1}g' \
  plugins/dev-workflows/commands/epics.md \
  plugins/dev-workflows/agents/epic-reviewer.md \
  plugins/dev-workflows/agents/epic-writer.md
```

- [ ] **Step 3: Apply the one `docs-profile.md` cross-ref (`6.5`→`6.2`) — its own `Phase 6` stays**

`docs-profile.md` has exactly one `Phase 6.5` (line 163, a `/document` cross-ref) and no other dotted token; its many bare `Phase 6` (its own "Final report" phase) must stay:

```bash
cd /workspace/ihudak-claude-plugins
perl -i -pe 's{Phase 6\.5}{Phase 6.2}g' plugins/dev-workflows/commands/docs-profile.md
```

- [ ] **Step 4: Verify the substantive global retirement gate is EMPTY**

```bash
cd /workspace/ihudak-claude-plugins
grep -rnE '6\.[78]' plugins/dev-workflows --include='*.md' | grep -vE 'CHANGELOG.md|fix-vuln/nvd-api'
```
Expected: **no output** (exit 1). This catches `Phase 6.7`, plural `Phases 6.7`, and bare `(6.7)`/`6.8` forms — not just the literal `Phase 6.7`. Exclusions: `CHANGELOG.md` (history) and `references/fix-vuln/nvd-api.md` (`5.16.7` etc. are CVE version numbers). The Task-2 files were pre-verified to carry only canonical `Phase 6.x` forms (plus `doc-writer.md:7`'s `(Phases 3–6.2)` range endpoint, which correctly stays — its `6.2` now denotes Branch setup, and the docs map leaves it untouched because it is not a `Phase 6` token). If this gate is non-empty, a non-`Phase` straggler slipped through — fix it before committing.

- [ ] **Step 5: Verify the per-site invariants that the gate cannot prove**

```bash
cd /workspace/ihudak-claude-plugins
echo "=== epics Write STAYS 6 (heading + bare refs) ==="
grep -nE '^## Phase 6' plugins/dev-workflows/commands/epics.md          # '## Phase 6 — Write Epics' AND '## Phase 6.1 — Dynatrace style check'
grep -n 'Phase 6 ' plugins/dev-workflows/commands/epics.md | head       # bare-6 Write refs still present
echo "=== release-notes own Phase 6 UNCHANGED ==="
grep -n 'Phase 6' plugins/dev-workflows/commands/release-notes.md       # '## Phase 6 — Render the draft' only
git diff --quiet plugins/dev-workflows/commands/release-notes.md && echo "release-notes UNCHANGED ✓" || echo "ERROR: release-notes changed"
echo "=== docs-profile own Phase 6 stays; only the /document xref moved to 6.2 ==="
grep -n 'Phase 6' plugins/dev-workflows/commands/docs-profile.md        # '## Phase 6 — Final report' stays; line ~163 now 'Phase 6.2'
echo "=== doc-writer range endpoint intact ==="
grep -n 'Phases 3–6.2' plugins/dev-workflows/agents/doc-writer.md       # endpoint unchanged (now denotes Branch setup)
echo "=== epic agents: 6.7 gone, bare 6 stays ==="
grep -n 'Phase 6' plugins/dev-workflows/agents/epic-reviewer.md plugins/dev-workflows/agents/epic-writer.md
```
Expected: `epics.md` shows BOTH `## Phase 6 — Write Epics` (stays) and `## Phase 6.1 — Dynatrace style check`; `release-notes.md` prints `UNCHANGED ✓`; `docs-profile.md` keeps `## Phase 6 — Final report` and shows the former `6.5` xref now as `6.2`; `doc-writer.md` still shows `Phases 3–6.2`; epic agents show bare `Phase 6` (stays) and no `6.7`.

- [ ] **Step 6: Inspect the diff for blind-replace mistakes**

```bash
git -C /workspace/ihudak-claude-plugins diff --stat
git -C /workspace/ihudak-claude-plugins diff | grep -E '^[+-].*Phase 6' | grep -v 'Phase 6\.[12345]' | grep -vE '^\+\+\+|^---'
```
Expected: `--stat` lists exactly the 15 files touched in Steps 1–3 (not `release-notes.md`, not `CHANGELOG.md`, not the manifests). The second command surfaces any changed `Phase 6` line whose new value is NOT `6.1`–`6.5`; for the `/epics` and `/docs-profile` files the surviving bare `Phase 6` lines appear as unchanged context (no `+`/`-`), so a `+`/`-` bare `Phase 6` here means an accidental edit — investigate.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add \
  plugins/dev-workflows/README.md \
  plugins/dev-workflows/agents/doc-location-finder.md \
  plugins/dev-workflows/agents/doc-planner.md \
  plugins/dev-workflows/agents/doc-reviewer.md \
  plugins/dev-workflows/agents/doc-writer.md \
  plugins/dev-workflows/agents/docs-style-checker.md \
  plugins/dev-workflows/agents/epic-reviewer.md \
  plugins/dev-workflows/agents/epic-writer.md \
  plugins/dev-workflows/commands/epics.md \
  plugins/dev-workflows/commands/docs-profile.md \
  plugins/dev-workflows/references/dynatrace-docs/multi-space-writing.md \
  plugins/dev-workflows/references/dynatrace-docs/render-verification.md \
  plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md \
  plugins/dev-workflows/references/finish-and-handoff.md \
  plugins/dev-workflows/references/source-truth.md
git commit -m "$(cat <<'EOF'
PRODUCT v2.0.1: per-site cross-reference sweep for the phase renumber

Map /document-context refs via the docs map (6.2→6.1, 6.5→6.2, 6→6.3,
6.7→6.4, 6.8→6.5) across README, the docs agents, and the docs references;
renumber /epics style 6.7→6.1 (epics Write stays 6); repoint the one
/document cross-ref in docs-profile.md (6.5→6.2). Retirement gate
'Phase 6.7|Phase 6.8' is now empty plugin-wide. No behavior change.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Release `v2.0.1`

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json:3` (top-level `version`)
- Modify: `.claude-plugin/marketplace.json:12` (**`plugins[0].version`** — the dev-workflows entry only)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend `[2.0.1]` entry)

**Interfaces:**
- Consumes: the renumbered content from Tasks 1–2.
- Produces: a shippable PATCH release.

**Model suggestion:** Sonnet (mechanical).

- [ ] **Step 1: Bump `plugin.json`**

Change `plugins/dev-workflows/.claude-plugin/plugin.json` line 3 from `"version": "2.0.0",` to `"version": "2.0.1",`. (Do not touch the `description` — its only phase reference is `Phase 4.5`, which is unchanged.)

- [ ] **Step 2: Bump `marketplace.json` `plugins[0].version`**

Change `.claude-plugin/marketplace.json` line 12 (the dev-workflows entry, first in `plugins[]`) from `"version": "2.0.0",` to `"version": "2.0.1",`. Leave the other plugin entries (lines 24, 36) and any top-level field untouched.

- [ ] **Step 3: Prepend the CHANGELOG entry**

Insert this block immediately above the existing `## [2.0.0] — 2026-06-28` heading, matching the file's existing heading style (read the `[2.0.0]` entry first and mirror its `### Changed` / bullet format):

```markdown
## [2.0.1] — 2026-06-28

### Changed

- **Internal phase renumber — documentation only, no behavior change.** Renumbered the `/document` (Jira mode) Phase 6 cluster to monotonic execution order — CDN image handoff `6.2`→`6.1`, branch setup `6.5`→`6.2` (its section now physically precedes the writer), write `6`→`6.3`, style check `6.7`→`6.4`, render verification `6.8`→`6.5` — and removed the execution-order note the old non-monotonic numbering required. Renumbered the `/epics` Dynatrace style-check phase `6.7`→`6.1` (the `/epics` Write phase stays `6`). Every step, gate, and agent dispatch is unchanged.
```

- [ ] **Step 4: Verify manifests parse and versions are consistent**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; print('plugin.json', json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"
python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); print('marketplace plugins[0]', d['plugins'][0]['version'])"
grep -n '^## \[2.0.1\] — 2026-06-28' plugins/dev-workflows/CHANGELOG.md
grep -n '^## \[2.0.0\]' plugins/dev-workflows/CHANGELOG.md   # still present (history preserved)
echo "=== substantive retirement gate still EMPTY (no regression) ==="
grep -rnE '6\.[78]' plugins/dev-workflows --include='*.md' | grep -vE 'CHANGELOG.md|fix-vuln/nvd-api'
```
Expected: both versions print `2.0.1`; the `[2.0.1]` heading exists with the em-dash date; `[2.0.0]` is still present; the gate is EMPTY. (The `[2.0.1]` CHANGELOG entry itself mentions `6.7`/`6.8`, but it lives in `CHANGELOG.md`, which the gate excludes.)

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add \
  plugins/dev-workflows/.claude-plugin/plugin.json \
  .claude-plugin/marketplace.json \
  plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
PRODUCT dev-workflows v2.0.1: release the monotonic phase renumber (no behavior change)

Bump plugin.json + marketplace.json plugins[0].version to 2.0.1; add the
CHANGELOG [2.0.1] entry documenting the internal /document and /epics phase
renumber.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Spec coverage** (against `spec/2026-06-28-phase-renumber-b1b-design.md`):
- §A `document.md` reorder + renumber + delete note → Task 1 (Steps 2–8). ✓
- §B `epics.md` `6.7`→`6.1`, Write stays `6` → Task 2 Step 2 + Step 5 verify. ✓
- §C per-site cross-ref sweep (enumerate-first, per-site map, completion re-grep) → Task 2 (the inventory table + Steps 1–6). ✓
- §D release `v2.0.1` (both manifests + CHANGELOG em-dash) → Task 3. ✓
- Risks: per-site sweep (mitigated by the atomic single-pass map + Opus reviewer + per-site verify Step 5); block move (mitigated by byte-identical swap + diff inspection Step 7); zero behavior change (mitigated by diff inspection in both content tasks). ✓
- Invariants: Mode B / `/release-notes` / `/docs-profile` own Phase 6 / `/implement` / `/vuln` / `/upgrade` untouched → verified in Task 1 Step 6 (Mode B) and Task 2 Step 5 (release-notes, docs-profile own). ✓

**2. Placeholder scan:** No "TBD"/"TODO"/"handle appropriately". Every renumber is a concrete map; the block move names exact boundary lines; the CHANGELOG text is provided verbatim. The only judgment step (note deletion) quotes the exact text to remove. ✓

**3. Type/number consistency:** The docs map (`6.2→6.1, 6.5→6.2, 6→6.3, 6.7→6.4, 6.8→6.5`) is identical in Task 1 Step 5 and Task 2 Step 1 (same `DOCS_RENUMBER` function). The epics map (`6.7→6.1`) and the `docs-profile` xref (`6.5→6.2`) are consistent with the authoritative map tables. The retirement gate string `'Phase 6\.7\|Phase 6\.8'` is identical across Task 2 Step 4 and Task 3 Step 4. ✓

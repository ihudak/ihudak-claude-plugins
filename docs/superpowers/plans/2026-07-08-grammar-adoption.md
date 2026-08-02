---
tags:
  - tasks-exclude
---

# Grammar Adoption Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/implement`, `/document`, `/epics`, and `/release-notes` consume the `focus_key` the shared Jira-input front-end already emits, so a `<VI> <Epic>` (or bare nested `<Epic>`) input stops silently reading the whole VI.

**Architecture:** All five files are Markdown command/reference definitions (Handlebars-free prose + phase headings). Changes are **additive edits** to existing Phase-0 / read / write / handoff prose. The shared reference `references/jira-input-resolution.md` §Specs-resolution becomes `focus_key`-aware (the single home for nested per-Epic path discovery); each command carries `focus_key` forward from Phase 0 and scopes its own downstream work. `/implement` additionally renders the progress-aware Epic picker. No subagent, no `/specify`/`/design`, no reviewer or format ref, and no sibling plugin is modified.

**Tech Stack:** Markdown (`.md`) command/agent/reference files + two JSON manifests (`plugin.json`, `marketplace.json`). **No test framework, no husky/prettier hook** — every task's verification is **structural**: `grep` for added anchors, `python3 -c 'json.load(...)'` for the JSON manifests, and a byte-diff (`git diff`) review confirming only the intended lines changed.

## Global Constraints

- **Feature branch:** `ivgu/NOISSUE-grammar-adoption`, cut from `main` (`1312b90`). Never implement on `main`.
- **Ships as v2.7.0** — version lock-step across `plugins/dev-workflows/.claude-plugin/plugin.json`, repo-root `.claude-plugin/marketplace.json` (`plugins[0]` only), and `plugins/dev-workflows/CHANGELOG.md`.
- **Additive-only:** with `focus_key` null, every command behaves **byte-for-byte** as today. Single-key `<VI-Key>`, single-key stand-alone item, and `<dir>` / `<dir> <Epic>` inputs resolve exactly as today.
- **VI-level commands** (`/epics`, `/document`, `/release-notes`) keep working for an **un-split (0-Epic) VI** and are **never** forced into the per-Epic picker. The picker is added to **`/implement` only**.
- **Not touched:** `commands/specify.md`, `commands/design.md`, `agents/jira-reader.md`, `agents/epic-writer.md`, `agents/spec-reviewer.md`, `agents/design-reviewer.md`, `references/specification-format.md`, `references/design-format.md`; the sibling plugins `dt-style-guide` (0.2.2) and `obsidian-llm-wiki` (0.3.1) in `marketplace.json`.
- **`jira-reader` is not modified** — all Epic-subtree scoping is done in-orchestrator (the foundation's established pattern, mirroring `/specify`).
- **Commit trailer, exactly:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Never `git add -A`** — stage only the named files each task lists. **Commit/push only when the user asks** (in SDD, tasks commit locally; the push/merge decision is the finishing step the user chooses).
- **Recompute any counts** (commands, subagents) from the repo — this effort adds **no** new command or subagent, so the count sentences in `plugin.json` / `marketplace.json` / README stay as-is.

### Shared vocabulary (used across tasks)

- **`focus_key`** — the nullable output field the shared front-end already emits: the target Epic key, or `null` for a bare VI / stand-alone item / directory.
- **`focus_items`** — (orchestrator-derived, `/document` only) the focus Epic plus every linked item beneath it (its Stories / Sub-tasks); used to scope change-driven phases.
- **Epic-subtree scoping** — from a jira-reader handoff, keep the focus Epic + the items linked beneath it and drop sibling Epics' subtrees. Done in-orchestrator.
- **`/implement` done-predicate** — the Epic's **Jira status** (`linked_items[].status` from a `depth: vi-plus-epics` read): *done/closed/resolved* → ●, *in progress/in review* → ◐, else → ○; degrade to a plain unstatused list if the export carries no status.

---

### Task 1: Shared reference — `focus_key`-aware §Specs-resolution

**Files:**
- Modify: `plugins/dev-workflows/references/jira-input-resolution.md` (§Specs resolution, item 1 of the numbered list, ~L103–107)

**Interfaces:**
- Consumes: the existing `focus_key` field of the front-end Output contract (already documented, no change).
- Produces: `specs[]` resolved to the **nested per-Epic home** when `focus_key` is set. Consumed conceptually by `/implement` (Task 2) and `/document` (Task 3), which cite this reference rather than re-implementing it.

- [ ] **Step 1: Replace item 1 of §Specs resolution with the `focus_key`-aware version**

Find this exact block (item 1 of the numbered list under `## Specs resolution (jira-driven)`):

```
1. **`$SPECS_PATH` set →** look for the ticket's specs at
   `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md` — a
   `specs`/`specifications`/`vis` root inside `$SPECS_PATH`, then a `<KEY>`-prefixed
   folder (tolerate `-`/`_` separators and a trailing slug) holding the `.md`
   specs/plans.
```

Replace it with:

```
1. **`$SPECS_PATH` set →** locate a `specs`/`specifications`/`vis` root inside
   `$SPECS_PATH`, then resolve by **matching folders on the Jira key-number**
   (tolerate `-`/`_` separators and a trailing slug):
   - **`focus_key` set →** prefer the nested per-Epic home: under the VI folder
     matching `jira_key` (`<VI>{-|_}<vslug>/`), the Epic folder matching `focus_key`
     (`<focus_key>{-|_}<eslug>/`), holding `specification.md`, `design.md`, and any
     other `.md`. If that nested Epic folder does not exist, **fall back** to the
     VI-flat resolution below (so nothing pre-foundation breaks).
   - **`focus_key` null →** the VI-flat resolution: a `<jira_key>`-prefixed folder
     (`<jira_key>{-|_}<slug>/…/*.md`) holding the `.md` specs/plans — for a
     stand-alone item, a broad VI-level slice, or a legacy pre-foundation layout.
```

Leave items 2 and 3 of the list unchanged.

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n 'focus_key` set' plugins/dev-workflows/references/jira-input-resolution.md
grep -n 'nested per-Epic home' plugins/dev-workflows/references/jira-input-resolution.md
grep -n 'VI-flat resolution' plugins/dev-workflows/references/jira-input-resolution.md
git diff --stat plugins/dev-workflows/references/jira-input-resolution.md
git diff plugins/dev-workflows/references/jira-input-resolution.md
```
Expected: the three greps each return ≥1 line; `--stat` shows only this file changed; the full diff shows **only** item 1 of §Specs-resolution replaced (items 2–3, the Output contract, and the picker section untouched).

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/jira-input-resolution.md
git commit -m "feat(dev-workflows): make shared §Specs-resolution focus_key-aware

Prefer the nested per-Epic home specifications/<VI>-<vslug>/<EPIC>-<eslug>/
when focus_key is set; fall back to the VI-flat layout otherwise.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `/implement` — consume `focus_key` + progress-aware picker

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (Phase 0 carry-forward ~L31; new Epic-unit resolution block after ~L31; Phase 1.7 scoping after ~L144)

**Interfaces:**
- Consumes: `focus_key` from the Phase-0 front-end; the shared reference's §"Progress-aware Epic picker" and §Specs-resolution (Task 1); `jira-reader` `linked_items[].status` (`depth: vi-plus-epics`).
- Produces: nothing other tasks depend on (self-contained command behavior).

- [ ] **Step 1: Add `focus_key` to the Phase 0 carry-forward**

Find (end of the "Jira-input resolution (shared front-end)" paragraph):
```
The classification
table above is the directory branch of that front-end — a Jira ticket folder ↔
jira-export, a spec folder ↔ spec-folder, a code repo ↔ an `/implement`-only
target. Carry `mode`, `jira_key`, `jira_export_root`, and `specs` forward.
```
Replace the final sentence `Carry \`mode\`, \`jira_key\`, \`jira_export_root\`, and \`specs\` forward.` with:
```
Carry `mode`, `jira_key`, `jira_export_root`, `focus_key`, and `specs` forward.
```

- [ ] **Step 2: Insert the Epic-unit resolution + picker block**

Immediately **after** the carry-forward paragraph (the line ending `…and \`specs\` forward.`) and **before** the `Rules:` line, insert this new block:

```
**Epic-unit resolution (jira-driven).** `/implement` implements one Epic at a time.
After the front-end resolves, when `mode: jira-driven`:

- **`focus_key` set** (explicit `<VI> <Epic>`, a bare nested `<Epic>`, or chosen in
  the picker below) → proceed for that Epic. The Jira read (Phase 1.7) and specs
  resolution both scope to it.
- **`focus_key` null** → classify the target with a cheap `jira-reader`
  `depth: vi-plus-epics` read on `jira_export_root`, then follow
  `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` §"Progress-aware Epic
  picker":
  - the item is **itself an Epic** (stand-alone / top-level) → no picker; proceed
    directly (`focus_key` stays null; specs resolve at the item's top-level dir).
  - **VI with exactly 1 Epic** → no picker; set `focus_key` to that Epic and proceed.
  - **VI with ≥2 Epics** → render the picker. `/implement`'s **done-predicate is the
    Epic's Jira status** (`linked_items[].status`): map *done / closed / resolved* →
    ● (greyed, not default-selectable; selecting offers "implement anyway"), *in
    progress / in review* → ◐, anything else → ○; always show the raw status text
    beside each row so a lagging status can't mislead. If the export carries no
    status, degrade to a plain unstatused selection list. Include the explicit choice
    **"Implement one broad VI-level slice instead"** (`focus_key` stays null → specs
    resolve VI-level). Selecting an Epic sets `focus_key` and proceeds for **that Epic
    only** — there is **no "Next Epic?" loop** (code-writing is heavy and branchy;
    each `/implement` run targets one Epic).
  - **VI with 0 Epics** → offer: split with `/epics` first (then re-import), or
    implement one broad VI-level slice (`focus_key` stays null).

When the picker (or the 1-Epic auto-path) sets `focus_key` that was initially null,
**re-resolve `specs`** per the shared reference §Specs-resolution now that `focus_key`
is set — the front-end's first pass resolved `specs` with `focus_key` null, so it must
run again to pick up the Epic's nested per-Epic home.
```

- [ ] **Step 3: Scope the Phase 1.7 Jira read to the focus Epic**

Find (Phase 1.7, step 1 tail):
```
   Run multiple `jira-reader` calls sequentially (it is fast and read-only). Collect the themes and PR references.
```
Insert immediately after it:
```
   When `focus_key` is set, scope the collected result to the focus Epic's subtree:
   keep the focus Epic plus the items linked beneath it (its Stories / Sub-tasks) and
   drop sibling Epics' subtrees before folding themes/PRs into the plan. `jira-reader`
   itself is not modified — the scoping is done here, mirroring `/specify`.
```

- [ ] **Step 4: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -c 'focus_key' plugins/dev-workflows/commands/implement.md
grep -n 'Epic-unit resolution (jira-driven)' plugins/dev-workflows/commands/implement.md
grep -n 'no "Next Epic?" loop' plugins/dev-workflows/commands/implement.md
grep -n 're-resolve `specs`' plugins/dev-workflows/commands/implement.md
# jira-reader is NOT re-wired: exactly the pre-existing dispatch count, unchanged
grep -c 'subagent_type: "dev-workflows:jira-reader"' plugins/dev-workflows/commands/implement.md
git diff plugins/dev-workflows/commands/implement.md
```
Expected: `focus_key` count ≥ 4; the three named greps return a line; the `jira-reader` dispatch count is **1** (unchanged — the picker's cheap read is described in prose, not a new hard-coded dispatch block); the diff touches only Phase 0 and Phase 1.7, and the open-question guard (L35–44) is untouched.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/implement.md
git commit -m "feat(dev-workflows): /implement consumes focus_key + Epic picker

Carry focus_key from Phase 0; render the progress-aware picker (Jira-status
done-predicate, one Epic per run, no Next-Epic loop) for a bare multi-Epic VI;
re-resolve specs after the picker; scope the Phase 1.7 Jira read to the Epic.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `/document` (Mode A) — consume `focus_key`, scope change-driven phases

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md` (Mode A Phase 0 carry-forward ~L37–38; Phase 3 `focus_items` after ~L242; Phase 5 dispatch ~L304/L308; Phase 5.7 dispatch ~L405)

**Interfaces:**
- Consumes: `focus_key` from the Phase-0 front-end; §Specs-resolution (Task 1).
- Produces: `focus_items` (orchestrator-local); no cross-task dependency.

- [ ] **Step 1: Add `focus_key` to the Mode A Phase 0 carry-forward**

Find:
```
`jira_key`, `jira_export_root`, and `specs` forward.
```
Replace with:
```
`jira_key`, `jira_export_root`, `focus_key`, and `specs` forward.
```

- [ ] **Step 2: Derive `focus_items` in Phase 3**

Find (Phase 3 tail):
```
Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`) and act accordingly. On `OK`, store the handoff for downstream phases.
```
Insert immediately after it:
```
When `focus_key` is set (explicit `<VI> <Epic>`), also derive `focus_items` = the
focus Epic plus every linked item beneath it (its Stories / Sub-tasks). The
change-scoped phases below consume `focus_items` in place of the full hierarchy —
Phase 5 (diff summarisation) and Phase 5.7 (doc planning) — while VI-descriptive
phases (e.g. Phase 4.5 space determination) keep the full handoff. When `focus_key`
is null, every phase uses the full hierarchy exactly as today.
```

- [ ] **Step 3: Scope the Phase 5 diff-summariser brief**

Find:
```
  > pr_refs:     [ ... full PR entries from jira-reader handoff, filtered to this repo ... ]
```
Replace with:
```
  > pr_refs:     [ ... full PR entries from jira-reader handoff, filtered to this repo (and, when focus_key is set, to focus_items) ... ]
```
Then find:
```
  > jira_keys_hierarchy:
  >   [VI key + every linked_items key from jira-reader]
```
Replace with:
```
  > jira_keys_hierarchy:
  >   [VI key + every linked_items key from jira-reader; when focus_key is set, restrict to focus_items — the focus Epic + its linked descendants]
```

- [ ] **Step 4: Scope the Phase 5.7 doc-planner brief**

Find:
```
  > jira_reader_handoff: [paste full YAML from Phase 3]
```
Replace with:
```
  > jira_reader_handoff: [paste full YAML from Phase 3; when focus_key is set, restrict linked items to focus_items]
```

- [ ] **Step 5: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -c 'focus_key' plugins/dev-workflows/commands/document.md
grep -c 'focus_items' plugins/dev-workflows/commands/document.md
git diff plugins/dev-workflows/commands/document.md
```
Expected: `focus_key` ≥ 4 and `focus_items` ≥ 4; the diff touches only the carry-forward, Phase 3, Phase 5, and Phase 5.7 anchors; Mode B and all other phases untouched.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/commands/document.md
git commit -m "feat(dev-workflows): /document honors focus_key (VI-level, scoped)

Carry focus_key; when a focus Epic is given, scope the change-driven phases
(diff summarisation, doc planning) to focus_items; VI-descriptive phases keep
the full handoff. No picker. Default whole-VI unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `/release-notes` — consume `focus_key`, scope the draft

**Files:**
- Modify: `plugins/dev-workflows/commands/release-notes.md` (Phase 0 carry-forward ~L32–33; Phase 3 scoping after the dispatch ~L121; Phase 6 handoff ~L147)

**Interfaces:**
- Consumes: `focus_key` from the Phase-0 front-end.
- Produces: nothing cross-task.

- [ ] **Step 1: Add `focus_key` to the Phase 0 carry-forward**

Find:
```
Carry `jira_key` and
   `jira_export_root` forward.
```
Replace with:
```
Carry `jira_key`,
   `jira_export_root`, and `focus_key` forward.
```

- [ ] **Step 2: Scope the handoff in Phase 3**

Find the Phase 3 jira-reader dispatch closing line:
```
  > depth:      [vi-only | full]"
```
Insert immediately after it (as a new paragraph):
```

When `focus_key` is set (explicit `<VI> <Epic>`), scope the handoff to the focus
Epic's subtree — the focus Epic plus its linked descendants — before Phase 6 renders
the draft, so the release note covers that Epic's user-facing changes rather than the
whole VI. When `focus_key` is null, the draft covers the whole ticket/VI exactly as
today.
```

- [ ] **Step 3: Note the scoped handoff at Phase 6**

Find:
```
  > jira_reader_handoff: [the Phase 3 handoff]
```
Replace with:
```
  > jira_reader_handoff: [the Phase 3 handoff — scoped to the focus Epic's subtree when focus_key is set]
```

- [ ] **Step 4: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -c 'focus_key' plugins/dev-workflows/commands/release-notes.md
grep -n 'focus Epic' plugins/dev-workflows/commands/release-notes.md
git diff plugins/dev-workflows/commands/release-notes.md
```
Expected: `focus_key` ≥ 3; the diff touches only the carry-forward, Phase 3, and Phase 6 anchors.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/release-notes.md
git commit -m "feat(dev-workflows): /release-notes honors focus_key (VI-level, scoped)

Carry focus_key; when a focus Epic is given, scope the handoff to that Epic's
subtree before rendering. No picker. Default whole-ticket unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: `/epics` — honor `focus_key` as a refinement target

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md` (Phase 0 carry-forward ~L25–27; Phase 3 refinement target after ~L148; Phase 6 handoff ~L218)

**Interfaces:**
- Consumes: `focus_key` from the Phase-0 front-end; the existing `epic-writer` input contract (`scope`, `existing_epics`, `output_dir`, …) — **unchanged**.
- Produces: nothing cross-task. **`agents/epic-writer.md` MUST NOT be modified** — the single-target behavior is achieved by how `epics.md` fills the existing handoff fields.

- [ ] **Step 1: Add `focus_key` to the Phase 0 carry-forward**

Find:
```
Carry `jira_key` and
   `jira_export_root` forward. Downstream, `<JIRA_KEY>` and `<VI-KEY>` both
   denote this `jira_key`.
```
Replace with:
```
Carry `jira_key`,
   `jira_export_root`, and `focus_key` forward. Downstream, `<JIRA_KEY>` and
   `<VI-KEY>` both denote this `jira_key`.
```

- [ ] **Step 2: Add the refinement-target rule in Phase 3**

Find (Phase 3 tail):
```
Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On `OK`, identify the Epics already linked to the VI (filter `linked_items` to `type == Epic`) — the new Epic drafts MUST NOT duplicate their scope (enforced later by `epic-reviewer`).
```
Insert immediately after it (new paragraph):
```

**Refinement target (`focus_key`).** `/epics` always reads and analyses the whole VI
(the partition and non-duplication logic are inherently VI-holistic). When `focus_key`
is set (explicit `<VI> <Epic>`), validate it is among the linked Epics; if it is not,
surface `EPICS_FOCUS_NOT_FOUND: <focus_key> is not a linked Epic of <jira_key>.` and
offer `choices: ["Proceed VI-level (draft the full partition)", "Re-enter the Epic key", "Cancel"]`.
When present, treat `focus_key` as the **single refinement target**: Phase 6 re-drafts
only that Epic's definition, and Phase 7 reviews only that file. The non-duplication
set (`existing_epics`) is the *other* linked Epics — exclude the focus Epic so Phase 6
re-emits it rather than skipping it as a duplicate. When `focus_key` is null, behaviour
is unchanged (draft the full partition of new Epics).
```

- [ ] **Step 3: Reflect the single target in the Phase 6 handoff**

Find (Phase 6, step 1):
```
1. **Write the handoff file.** Create a temp file (`mktemp` — never the vault, never a repo) containing the `epic-writer` input contract: `jira_reader_handoff`, `code_scanner_outputs` (empty if no scan), `scope` (Phase 2 in/out of scope), `existing_epics` (non-duplication), `output_dir` (resolved Phase 1 dir), `vi_goal`, `jira_key`. Record its absolute path.
```
Replace with (adds one sentence to the same bullet):
```
1. **Write the handoff file.** Create a temp file (`mktemp` — never the vault, never a repo) containing the `epic-writer` input contract: `jira_reader_handoff`, `code_scanner_outputs` (empty if no scan), `scope` (Phase 2 in/out of scope), `existing_epics` (non-duplication), `output_dir` (resolved Phase 1 dir), `vi_goal`, `jira_key`. Record its absolute path. When `focus_key` is set (the Phase 3 refinement target), set `scope` in-scope to just the focus Epic and `existing_epics` to the *other* linked Epics, so `epic-writer` re-drafts the single focus Epic's definition file; `output_dir` is unchanged.
```

- [ ] **Step 4: Structural verification (incl. epic-writer untouched)**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -c 'focus_key' plugins/dev-workflows/commands/epics.md
grep -n 'EPICS_FOCUS_NOT_FOUND' plugins/dev-workflows/commands/epics.md
grep -n 'single refinement target' plugins/dev-workflows/commands/epics.md
# epic-writer must NOT appear in the working-tree changes
git status --porcelain plugins/dev-workflows/agents/epic-writer.md
git diff plugins/dev-workflows/commands/epics.md
```
Expected: `focus_key` ≥ 3; the two named greps return a line; `git status --porcelain … epic-writer.md` prints **nothing** (unmodified); the diff touches only Phase 0, Phase 3, and Phase 6. Phase 7 is intentionally unchanged — it reviews `files_written`, which is the single focus-Epic file when `focus_key` is set.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/epics.md
git commit -m "feat(dev-workflows): /epics honors focus_key as a refinement target

Carry focus_key; whole-VI analysis unchanged, but a focus Epic narrows Phase 6
to re-drafting just that Epic (single in-scope target, siblings as
existing_epics) and Phase 7 to that file. epic-writer unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Release surfaces — v2.7.0 (versions, CHANGELOG, READMEs)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (version)
- Modify: `.claude-plugin/marketplace.json` (`plugins[0].version` only)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend `[2.7.0]`)
- Modify: `plugins/dev-workflows/README.md` (four command-table signature rows)
- Verify (likely no change): repo-root `README.md`

**Interfaces:**
- Consumes: the behaviors implemented in Tasks 1–5 (for accurate CHANGELOG/README prose).
- Produces: the released version surface. Run last.

- [ ] **Step 1: Bump `plugin.json`**

Find `  "version": "2.6.0",` and replace with `  "version": "2.7.0",`. Leave `description` unchanged (no new commands/subagents).

- [ ] **Step 2: Bump `marketplace.json` (dev-workflows entry only)**

Find `      "version": "2.6.0",` (the dev-workflows entry — `2.6.0` is unique; siblings are `0.2.2` / `0.3.1`) and replace with `      "version": "2.7.0",`. Leave that entry's `description` unchanged and **do not touch** the `dt-style-guide` / `obsidian-llm-wiki` entries.

- [ ] **Step 3: Prepend the CHANGELOG entry**

Find `## [2.6.0] — 2026-07-08` and insert this block **immediately before** it:

```
## [2.7.0] — 2026-07-09

### Changed

- **`/implement`, `/document`, `/epics`, and `/release-notes` now honor the shared front-end's `focus_key`.** Since the v2.5.0 foundation these four commands parsed the two-key `<VI> <Epic>` grammar but ignored the focus Epic (they resolved the VI and read the whole subtree). They now consume `focus_key`:
  - **`/implement`** is treated as an Epic-unit command: for a bare multi-Epic VI it renders the progress-aware Epic picker (done-predicate = the Epic's Jira status — done / in-progress / not-started, degrading to a plain list if the export carries no status), scopes the Jira read to the chosen Epic's subtree, and resolves specs from the nested per-Epic home. Each run targets **one** Epic — there is **no "Next Epic?" loop** (unlike `/specify`+`/design`), because code-writing is heavy and branchy.
  - **`/document`** (Jira mode) and **`/release-notes`** stay VI-level and gain no picker; when an explicit focus Epic is passed they scope their change-driven phases (diff summarisation, doc planning / release-note rendering) to that Epic's subtree, defaulting to whole-VI otherwise.
  - **`/epics`** stays VI-level (its partition analysis reads the whole VI); an explicit focus Epic is honored as a **refinement target** — Phase 6 re-drafts only that Epic's definition and Phase 7 reviews only that file (`epic-writer` unchanged).
- **Shared `references/jira-input-resolution.md` §Specs-resolution is now `focus_key`-aware.** With a focus Epic it prefers the nested per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/{specification.md,design.md}` (matched by Jira key-number, tolerating slug drift), falling back to the VI-flat layout when no nested Epic folder exists; with no focus Epic the VI-flat resolution is unchanged. This is the nested per-Epic path discovery `/implement` needed.

Single-key and directory inputs, and un-split-VI (0-Epic) behaviour, are unchanged; `jira-reader`, `/specify`, `/design`, the reviewers, and the format references are untouched.

```

- [ ] **Step 4: Refresh the four README command-table signature rows**

In `plugins/dev-workflows/README.md`, update these rows so the four commands advertise the focus-Epic grammar the way `/specify` and `/design` already do. Apply each find/replace:

(a) `/implement` row — find the cell start:
```
| `/implement <JiraID \| jira-export-dir \| description \| @paths>` | Structured code implementation: accepts the shared Jira-input grammar — a **JiraID**, an **imported-Jira directory**, or a **direct prompt/`@file`** (also `@spec`/`@repo`) — then
```
replace with:
```
| `/implement <VI-KEY \| Epic-KEY \| jira-export-dir \| description \| @paths> [focus-Epic-KEY]` | Structured code implementation: accepts the shared Jira-input grammar — a **JiraID** (VI or Epic), an **imported-Jira directory**, or a **direct prompt/`@file`** (also `@spec`/`@repo`), optionally with a **focus Epic** (`<VI> <Epic>`); for a multi-Epic VI it renders the progress-aware Epic picker (done-predicate = the Epic's Jira status) and implements **one Epic per run**. Then
```

(b) `/epics` row — find:
```
| `/epics <VI-KEY \| jira-export-dir>` | Jira-driven Epic drafting. Accepts the shared Jira-input grammar — a **VI key** (discovered under `$VAULT_PATH/jira-products/`) or an **imported-Jira directory** (works when `$VAULT_PATH` is unset).
```
replace with:
```
| `/epics <VI-KEY \| jira-export-dir> [focus-Epic-KEY]` | Jira-driven Epic drafting. Accepts the shared Jira-input grammar — a **VI key** (discovered under `$VAULT_PATH/jira-products/`) or an **imported-Jira directory** (works when `$VAULT_PATH` is unset); an explicit focus Epic (`<VI> <Epic>`) is honored as a refinement target — it re-drafts just that Epic.
```

(c) `/release-notes` row — find:
```
| `/release-notes <KEY \| jira-export-dir>` | Jira-driven release-notes drafting. Accepts the shared Jira-input grammar — a **ticket key** or an **imported-Jira directory** (works when `$VAULT_PATH` is unset).
```
replace with:
```
| `/release-notes <KEY \| jira-export-dir> [focus-Epic-KEY]` | Jira-driven release-notes drafting. Accepts the shared Jira-input grammar — a **ticket key** or an **imported-Jira directory** (works when `$VAULT_PATH` is unset); an explicit focus Epic (`<VI> <Epic>`) scopes the draft to that Epic.
```

(d) `/document` (Jira-mode) row — find:
```
| `/document <VI-KEY \| jira-export-dir [saas\|managed]>` | (Jira mode) Jira-driven feature documentation. Accepts the shared Jira-input grammar — a **JiraID** discovered under `$VAULT_PATH/jira-products/`, or an **imported-Jira directory** (works when `$VAULT_PATH` is unset) — plus the optional `saas\|managed` constraint.
```
replace with:
```
| `/document <VI-KEY \| jira-export-dir> [focus-Epic-KEY] [saas\|managed]` | (Jira mode) Jira-driven feature documentation. Accepts the shared Jira-input grammar — a **JiraID** discovered under `$VAULT_PATH/jira-products/`, or an **imported-Jira directory** (works when `$VAULT_PATH` is unset) — optionally with a **focus Epic** (`<VI> <Epic>`, which scopes the change-driven phases to that Epic) plus the optional `saas\|managed` constraint.
```

- [ ] **Step 5: Verify the root README needs no change**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -niE 'only at VI scope|ignore.*focus|whole VI' README.md
```
Expected: no output (the root README's dev-workflows summary is a command list + capability blurb; it makes no VI-only-scope claim, so no functional edit is required). Leave `README.md` unchanged.

- [ ] **Step 6: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('plugin.json OK')"
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); v={p['name']:p['version'] for p in m['plugins']}; print(v); assert v['dev-workflows']=='2.7.0' and v['dt-style-guide']=='0.2.2' and v['obsidian-llm-wiki']=='0.3.1'"
grep -n '## \[2.7.0\] — 2026-07-09' plugins/dev-workflows/CHANGELOG.md
grep -c 'focus-Epic-KEY' plugins/dev-workflows/README.md
git diff --stat
```
Expected: both JSON files parse; the marketplace assertion passes (dev-workflows `2.7.0`, siblings unchanged); the CHANGELOG grep returns a line; `focus-Epic-KEY` appears **4** times in the README; `--stat` lists exactly the five files (plugin.json, marketplace.json, CHANGELOG.md, dev-workflows/README.md) plus nothing else.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md
git commit -m "release(dev-workflows): v2.7.0 — focus_key grammar adoption

Version lock-step (plugin.json + marketplace.json dev-workflows entry),
CHANGELOG [2.7.0], and README command-row signatures. Siblings untouched.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Notes for the executor

- **Byte-diff discipline:** these are prose files; after each task, read the `git diff` and confirm no unintended reflow or anchor drift. Prettier is **not** run here.
- **Anchor drift:** line numbers in this plan are approximate (from a 2026-07-08 read). Locate edits by the quoted anchor text, not by line number.
- **`focus_key` null = today:** if any verification shows a behavior change when `focus_key` is null, that is a defect — the whole contract is additive.

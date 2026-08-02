---
tags:
  - tasks-exclude
---

# Follow-up Task & Journal Emission Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the four Jira-driven dev-workflows commands (`/document`, `/release-notes`, `/epics`, `/implement`) a terminal "Emit follow-up tasks" phase that persists their out-of-scope / manual-step follow-ups as durable Obsidian tasks (plus `Journal.md` notes), via a new self-contained `references/followup-emission.md`, and ship it as v2.8.0.

**Architecture:** All edited files are Markdown command/reference definitions (prose + phase headings) plus two JSON manifests. Changes are **additive**: one new reference file (T1) is the single source of truth for the emitter; each command (T2–T5) gains one terminal phase, inserted **after** its Final Report and **before** its trailing invariants block, that cites the reference and executes its steps inline. The emitter mirrors the obsidian-llm-wiki plugin's `_shared/task-rules.md` + `vault-conventions.md` conventions internally, so there is **no runtime dependency** on that sibling plugin. T6 bumps the version surfaces. No subagent, reviewer, format reference, or sibling plugin is modified.

**Tech Stack:** Markdown (`.md`) command/reference files + two JSON manifests (`plugin.json`, `marketplace.json`). **No test framework, no husky/prettier hook** — every task's verification is **structural**: `grep` for added anchors, `python3 -c "import json; json.load(...)"` for the JSON manifests, and a byte-diff (`git diff --stat` / `git diff`) review confirming only the intended lines changed.

## Global Constraints

Every task's requirements implicitly include this section.

- **Feature branch:** `ivgu/NOISSUE-followup-task-emission`, cut from `main` (`0ff2c95`). Never implement on `main`.
- **Additive only** — do NOT alter existing phase behavior, `jira-reader`, `format-refs`, reviewers, or sibling plugins. With no follow-up signals and no writable target, every command behaves as today (the follow-ups also always remain in the Final Report — zero regression) and the phase never fails the run.
- **Commit trailer, EXACTLY:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **NEVER `git add -A`** — stage only the files named in the task. Commit/push only per the executing skill's checkpoint policy; the push/merge decision is the finishing step the user chooses.
- **Version lock-step:** `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of repo-root `.claude-plugin/marketplace.json` are BOTH `2.8.0`.
- **Siblings untouched:** `dt-style-guide` (`0.2.2`) and `obsidian-llm-wiki` (`0.3.1`) in `marketplace.json` — their versions AND description strings are unchanged.
- **One commit per task; structural verification only** (no tests exist).
- **Recompute counts from the repo** — this effort adds **no** new command and **no** new subagent, so the "Eleven slash commands" / "Twenty-six reusable subagents" count sentences in `plugin.json` / `marketplace.json` stay as-is (a new *reference* file is not a command or subagent).
- **Anchor by quoted text, not line number** — line numbers here are from a 2026-07-09 read and are approximate. After each edit, read the `git diff` and confirm no unintended reflow.

### Shared vocabulary (used across tasks)

- **Emitter** — the logic in `references/followup-emission.md` (T1): qualifying predicate → target resolution → render/place → dedupe → batch-preview confirm → write.
- **Qualifying predicate** — emit a task ONLY for signals whose action lands *outside* the current change or needs a *manual human step*; NEVER for in-scope items the report already tracks (deferred review BLOCKERs, skipped tests, in-draft `<!-- TODO -->`).
- **Fallback ladder** — write-target resolution, most-durable first: writable vault → the VI's `$SPECS_PATH` dir (`<VI-dir>/dev-workflows/<KEY>-followups.md`) → beside the imported Jira directory (`source = directory`) → report-only. **Never** the current working directory.
- **`vault_writable`** — `$VAULT_PATH` is set **and** `$VAULT_PATH/.obsidian/` is a directory **and** the path is writable.

## File Structure

| File | Task | Responsibility |
|------|------|----------------|
| `plugins/dev-workflows/references/followup-emission.md` | T1 (create) | Single source of truth for the emitter: task-line format, Jira-key→project-file resolution, notes/`Journal.md` placement, dedupe, no-vault fallback ladder, qualifying predicate, batch-preview interaction. Self-contained; mirrors obsidian-llm-wiki `_shared/*.md` as upstream. |
| `plugins/dev-workflows/commands/document.md` | T2 (modify ×2) | Add a terminal phase to Mode A (Phase 10) and Mode B (Phase 6), each before that mode's `## Invariants` block. |
| `plugins/dev-workflows/commands/release-notes.md` | T3 (modify) | Add Phase 9, before `## Invariants`. |
| `plugins/dev-workflows/commands/epics.md` | T4 (modify) | Add Phase 10, before `## Invariants`. |
| `plugins/dev-workflows/commands/implement.md` | T5 (modify) | Add Phase 6, before `## Invariants`. |
| `plugins/dev-workflows/.claude-plugin/plugin.json` | T6 (modify) | Version `2.7.0` → `2.8.0`. |
| `.claude-plugin/marketplace.json` | T6 (modify) | `dev-workflows` entry version `2.7.0` → `2.8.0` only. |
| `plugins/dev-workflows/CHANGELOG.md` | T6 (modify) | Prepend `## [2.8.0] — 2026-07-09` (`### Added`). |
| `plugins/dev-workflows/README.md` | T6 (modify) | Document the feature (Environment prerequisites bullet + Reference docs bullet). Root README untouched. |

The command phases (T2–T5) all cite T1, so T1 lands first. T6 (versions/changelog/README) runs last, after the behaviors exist. T2–T5 are mutually independent.

---

### Task 1: Create `references/followup-emission.md`

**Files:**
- Create: `plugins/dev-workflows/references/followup-emission.md`

**Interfaces:**
- Consumes: nothing from earlier tasks. At runtime, reads `$VAULT_PATH`, `$SPECS_PATH`, the run's `jira_key` and `source` (from `references/jira-input-resolution.md`), and the vault's `.obsidian/copilot/tag-index.md` if present.
- Produces: the reference cited by T2–T5 at `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md`. Section numbers the commands rely on: §1 task-line format, §2 target resolution, §3 notes, §4 fallback ladder, §5 dedupe, §6 qualifying predicate, §7 batch preview, §8 caller contract.

- [ ] **Step 1: Write the new reference file**

Create `plugins/dev-workflows/references/followup-emission.md` with EXACTLY this content:

```markdown
# Follow-up Task & Journal Emission — Shared Reference

Single source of truth for the dev-workflows follow-up emitter. A terminal
"Emit follow-up tasks" phase in `/document`, `/release-notes`, `/epics`, and
`/implement` cites this file and executes its steps inline — the orchestrator
owns every prompt.

**Self-contained.** This reference has NO runtime dependency on the
obsidian-llm-wiki plugin. It MIRRORS that plugin's
`skills/_shared/task-rules.md` (task-line format; effort / priority / date
symbols; tag rules) and `skills/_shared/vault-conventions.md` (project-file
structure; `Tasks.md` fallback; read-only zones) as upstream — keep this copy
in sync when those evolve. Journaling (§3) exists in neither plugin; it is
net-new here.

## 1. Task-line format

Mirrors the wiki `_shared/task-rules.md` Obsidian-Tasks line:

    - [effort] Description #tag1 #tag2 priority ⏳ scheduled 📅 due ➕ <today>

- **effort** — a Fibonacci checkbox: `[0]` tiny · `[1]` under an hour · `[2]`
  a few hours · `[3]` half-day to a day · `[5]` days · `[8]` a week+ · `[13]`
  multi-week. Use `[ ]` when effort is unknown. When unsure between two, pick
  the higher.
- **Description** — one imperative line naming the out-of-scope action.
- **#tags** — REUSE-ONLY from `$VAULT_PATH/.obsidian/copilot/tag-index.md`.
  NEVER invent a tag. If `tag-index.md` is absent, omit tags entirely and warn
  once: "No tag-index.md — follow-up tasks emitted without tags."
- **priority** (optional) — `🔺` / `⏫` / `🔼` / `🔽` / `⏬`, placed after tags,
  before dates.
- **➕ `<today>`** — ALWAYS add the creation date (`YYYY-MM-DD`). Scheduled
  (`⏳`) and due (`📅`) dates are optional — add only when the signal implies
  them.
- **Jira link** — when the item carries a Jira key, render it
  `[<KEY>](<base>/browse/<KEY>)` using the base URL discovered from existing
  vault tasks
  (`grep -rh 'atlassian.net/browse/' "$VAULT_PATH"/Projects "$VAULT_PATH"/Tasks.md 2>/dev/null | head -3`);
  if no base is known, include the bare `<KEY>` as plain text.

## 2. Target-file resolution (Jira-first, deterministic)

The run carries `source` (`vault | directory | none`) and, when Jira-driven, a
`jira_key`. Resolve the task's home:

1. **Vault writable (§4) AND the run has a `jira_key`** → locate the project
   folder with the existing pattern (`references/finish-and-handoff.md`):

       find "$VAULT_PATH"/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"

   Inside it, the project file is `P<NNNN> <slug>.md`. Verify its frontmatter
   `tags:` includes `task` and `archived:` is `false` or absent, then insert
   the task under `## Work Items → ### Tasks`.
2. **Vault writable but no project match / verification fails / no `jira_key`**
   → fall back to `$VAULT_PATH/Tasks.md`, inserting under `# Irregular`. Create
   `Tasks.md` from the bootstrap template (frontmatter `tags: [task]` +
   `# Tasks` + `# Irregular`) if it does not exist.
3. **NEVER** insert into `## Archived Tasks`, `# Archive`, Daily notes, or any
   section excluded from dashboard queries.

## 3. Verbose notes — project file first, `Journal.md` as fallback

Some follow-ups need more than a line (a table, multi-step context, a
paste-ready draft). Notes follow the SAME primary → fallback split as tasks
(§2): `Journal.md` is the notes analogue of `Tasks.md` — the home for notes
that have no project yet, NOT a catch-all.

- **Task landed in a project file** (`P<NNNN> <slug>.md`) → append the note as
  a new dated block to that file's `## Work Items → ### Notes` section (create
  the `### Notes` section under `## Work Items` if the resolved file lacks one).
  The task links to it: `[[<project-file>#<note-heading>]]`.
- **Task landed in `Tasks.md`** (no project home) → append the note to
  `$VAULT_PATH/Journal.md` as a dated H1 block
  (`# <Topic> — <purpose> (YYYY-MM-DD)`, matching the existing style). The task
  links via `[[Journal#<note-heading>]]`.
- **No writable vault** → inline the note as a section of the fallback
  `<KEY>-followups.md` (§4 tier 2+); the task links that section.

Notes are APPEND-ONLY — never modify an existing block. When the run already
produced a `<KEY>-implementation-gaps.md` draft, the task REFERENCES that file
rather than duplicating it.

## 4. Vault-availability preflight & fallback ladder

At the start of the phase, resolve the write target by walking the ladder,
most-durable first. `vault_writable` = `$VAULT_PATH` is set **and**
`$VAULT_PATH/.obsidian/` is a directory **and** the path is writable.

1. **Vault writable** → emit vault tasks (§2) + verbose notes (§3). *[primary]*
2. **No vault; `$SPECS_PATH` resolvable and the VI spec dir exists** — the dir
   matched by `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…` →
   write `<VI-dir>/dev-workflows/<KEY>-followups.md` (§4.1). Durable, VI-scoped,
   git-tracked (the specs repo), and NOT a code repo. Verbose "journal" content
   is inlined as sections of that same file (no `Journal.md` outside a vault);
   the task line links the section.
3. **No vault; no `$SPECS_PATH` VI dir; `source = directory`** → write beside
   the imported Jira directory:
   `<parent-of-jira_export_root>/<KEY>-followups.md` (where `/epics` +
   `/release-notes` already write their no-vault output).
4. **None resolvable** → **report-only.** Keep the follow-ups in the Final
   Report and emit the notice. **NEVER** write into the current working
   directory — it may be a code repository.

In every non-vault tier the follow-ups ALSO remain in the Final Report (today's
behaviour — zero regression) and the pipeline never fails.

- **Notice** (tiers 2–4):
  `⚠ No writable Obsidian vault — N follow-ups written to <path>`;
  tier 4: `⚠ No writable vault or specs dir — N follow-ups kept in this report only; set $VAULT_PATH or $SPECS_PATH to persist them`.
- **Interactive escape** (folds into the §7 batch preview, mirroring Fallback A
  in `jira-input-resolution.md`): below the vault tier, show the resolved
  fallback path and offer
  `choices: ["Save to <resolved path>", "Enter a vault path", "Keep in report only"]`,
  default = save.
- **Write fails mid-insert** (read-only mount / permission) → drop to the next
  tier, same notice.

### 4.1 Shared per-VI artifact area under `$SPECS_PATH`

`<VI-dir>/dev-workflows/` (a subdir of the VI's `$SPECS_PATH` spec dir) is the
home for dev-workflows per-VI artifacts written outside the vault. This feature
writes `<KEY>-followups.md` there; planned future extensions (session feedback,
session cost reporting) share the same directory. This keeps the VI spec dir
uncluttered and groups all dev-workflows output for a VI in one place.

## 5. Idempotency / dedupe

Pipelines re-run. Before inserting, READ the existing tasks in the target
section and SKIP any whose stable key already appears. **Stable key** = the
finding's identity: `jira_key` + (file path | gap-id | signal-type). Report a
match as `SKIP — already exists` (mirrors `/wiki-tasks-extract` Step 5); never
re-insert.

## 6. Qualifying predicate — what becomes a follow-up

Emit a task ONLY for signals whose action lands OUTSIDE the current change or
requires a MANUAL human step:

- Files/pages owned by others (non-allowlisted, override-copy, owner surfaced).
- Implementation gaps (Jira vs source; the `<KEY>-implementation-gaps.md`
  draft) → the task links the draft; verbose context → a note (§3).
- Manual publish steps: screenshots to upload (CDN), "paste release notes into
  Jira", "create these Epics in Jira manually", open-the-PR-by-hand.
- SPEC-VS-JIRA ("update the Jira ticket to match the spec").
- Unresolved PRs on unsupported hosts (must be documented manually).

DO NOT emit tasks for in-scope items the report/draft already tracks: deferred
review BLOCKERs, skipped tests, in-draft `<!-- TODO -->` markers. Those belong
to the current task and are already carried in the Final Report.

## 7. Interaction model — batch preview at end-of-run

Mirror `/wiki-tasks-extract`: NO mid-run interruption. After the Final Report
is composed, present the qualifying follow-ups as a batch preview GROUPED BY
TARGET FILE, then act on one confirmation:

    choices: ["approve-all", "select", "cancel"]

- **approve-all** → insert every previewed row.
- **select** → let the user pick a subset by row number, then insert those.
- **cancel** → write nothing; the follow-ups remain in the Final Report only.

Each preview row shows: the source signal, the target file → section, and the
rendered task line. Nothing is written to the vault (or a fallback file)
without one confirmation.

## 8. Caller contract (what a wiring command passes in)

The calling phase provides:

- `follow_up_items` — the qualifying signals it already aggregated in its Final
  Report follow-up sections.
- `jira_key` — the run's resolved key, or `null`.
- `source` — `vault | directory | none` from `jira-input-resolution.md`.

The phase applies §6 (filter) → §4 (resolve target) → §1–§3 (render + place) →
§5 (dedupe) → §7 (confirm), then writes. It is ADDITIVE: the follow-ups always
also remain in the Final Report, the phase NEVER commits, and it NEVER writes
into a docs/code repo or the current working directory.
```

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '^## 4. Vault-availability preflight' plugins/dev-workflows/references/followup-emission.md
grep -n 'find "\$VAULT_PATH"/Projects -maxdepth 5' plugins/dev-workflows/references/followup-emission.md
grep -n '<VI-dir>/dev-workflows/<KEY>-followups.md' plugins/dev-workflows/references/followup-emission.md
grep -c '"approve-all", "select", "cancel"' plugins/dev-workflows/references/followup-emission.md
grep -n 'MIRRORS that plugin' plugins/dev-workflows/references/followup-emission.md
git status --porcelain plugins/dev-workflows/references/followup-emission.md
```
Expected: the four named greps each return ≥1 line; the `approve-all` count is `1`; `git status --porcelain` shows `?? plugins/dev-workflows/references/followup-emission.md` (a new, untracked file) and nothing else.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/followup-emission.md
git commit -m "feat(dev-workflows): add follow-up task & journal emitter reference

New references/followup-emission.md — the single source of truth for the
end-of-run follow-up emitter (task-line format, Jira-key -> project-file
resolution, Journal.md notes, dedupe, no-vault fallback ladder, qualifying
predicate, batch preview). Self-contained; mirrors obsidian-llm-wiki
_shared/task-rules.md + vault-conventions.md as upstream.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Wire `/document` (Mode A + Mode B)

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md` (Mode A: new Phase 10 before `## Invariants` ~L901; Mode B: new Phase 6 before `## Invariants` ~L1177)

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` (T1); the run's `jira_key`, `source`, and the Mode A / Mode B Final Report follow-up sections.
- Produces: nothing other tasks depend on (self-contained command behavior).

- [ ] **Step 1: Insert the Mode A terminal phase (Phase 10)**

Find this exact block (the report code-fence close, the separator, and the start of the **Mode A** invariants — the first bullet is unique to Mode A):

```
---

## Invariants (always enforced)

- ALWAYS run Phase 0 docs-repo detection; if 0 signals, require user confirmation before proceeding
```

Replace it with:

```
---

## Phase 10 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 9 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's out-of-scope / manual-step
follow-ups as durable Obsidian tasks (and notes) by citing
`${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` and executing its steps
inline.

1. **Collect** the follow-up items already aggregated in the Phase 9 report:
   `### Screenshots to upload manually`, `### Implementation gaps (Jira vs source)`,
   `### Skipped items`, and `### Deferred items`.
2. **Filter** them with the reference's §6 qualifying predicate — emit only
   out-of-scope / manual-step signals; drop in-scope items the report already
   tracks.
3. **Resolve** the write target via the §4 vault-availability ladder using the
   run's `jira_key` and `source`; render + place tasks and verbose notes per
   §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 9 report (today's behaviour).
This phase NEVER fails the run, NEVER commits, and NEVER writes into the docs
repo or the current working directory.

---

## Invariants (always enforced)

- ALWAYS run Phase 0 docs-repo detection; if 0 signals, require user confirmation before proceeding
```

- [ ] **Step 2: Insert the Mode B terminal phase (Phase 6)**

Find this exact block (the **Mode B** invariants — the first bullet is unique to Mode B):

```
---

## Invariants (always enforced)

- ALWAYS run Phase 3.5 (style check) after editing — `docs-style-checker` falls back to `dt-style-checker`; never skip style on tool-absence judgement
```

Replace it with:

```
---

## Phase 6 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 5 Final Report is composed; NEVER
interrupts an earlier phase. Persist any out-of-scope / manual-step follow-ups
by citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` and executing
its steps inline.

1. **Collect** the follow-up items from the Phase 5 `### Deferred items` section
   (direct edits rarely produce out-of-scope work; this phase is usually a
   no-op).
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder. Direct mode usually has no
   `jira_key` (`source = none`), so tasks land in `Tasks.md # Irregular` when the
   vault is writable, else the phase degrades to report-only.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 5 report. This phase NEVER
fails the run, NEVER commits (the user manages git manually), and NEVER writes
into the docs repo or the current working directory.

---

## Invariants (always enforced)

- ALWAYS run Phase 3.5 (style check) after editing — `docs-style-checker` falls back to `dt-style-checker`; never skip style on tool-absence judgement
```

- [ ] **Step 3: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '## Phase 10 — Emit follow-up tasks' plugins/dev-workflows/commands/document.md
grep -n '## Phase 6 — Emit follow-up tasks' plugins/dev-workflows/commands/document.md
grep -c 'references/followup-emission.md' plugins/dev-workflows/commands/document.md
grep -c '## Invariants (always enforced)' plugins/dev-workflows/commands/document.md
git diff plugins/dev-workflows/commands/document.md
```
Expected: the two `## Phase …` greps each return one line (Phase 10 for Mode A, Phase 6 for Mode B); `references/followup-emission.md` count is `2`; the `## Invariants (always enforced)` count is still `2` (both preserved); the diff shows only the two new phase blocks inserted, with each mode's invariants block unchanged below it.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/commands/document.md
git commit -m "feat(dev-workflows): /document emits follow-up tasks at end-of-run

Add a terminal Emit-follow-up-tasks phase to both modes (Mode A Phase 10,
Mode B Phase 6), inserted before each mode's invariants block. Cites
references/followup-emission.md; feeds it the Final Report follow-up
sections, jira_key, and source. Additive — follow-ups still appear in the
report; never fails, commits, or writes to the docs repo.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Wire `/release-notes`

**Files:**
- Modify: `plugins/dev-workflows/commands/release-notes.md` (new Phase 9 before `## Invariants` ~L209)

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` (T1); the run's `jira_key`, `source`, the Phase 8 report's paste-into-Jira reminder, and any implementation-gap signals.
- Produces: nothing cross-task.

- [ ] **Step 1: Insert the terminal phase (Phase 9)**

Find this exact block:

```
---

## Invariants (always enforced)

- ZERO external API calls — PR URLs are identifiers only; all resolution is local `git`.
```

Replace it with:

```
---

## Phase 9 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 8 report is composed; NEVER interrupts an
earlier phase. Persist the run's manual-step follow-ups by citing
`${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` and executing its steps
inline.

1. **Collect** the qualifying follow-ups: the mandatory manual publish step
   ("paste this release-notes draft into the ticket's Jira release-notes field")
   and any implementation-gap signals surfaced during the run.
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder using `jira_key` and `source`;
   render + place tasks and verbose notes per §1–§3; dedupe per §5. The task
   references the draft file written in Phase 8 rather than duplicating it.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 8 report. This phase NEVER
fails the run, NEVER commits, NEVER makes an external API call, and NEVER writes
into a docs repo or the current working directory.

---

## Invariants (always enforced)

- ZERO external API calls — PR URLs are identifiers only; all resolution is local `git`.
```

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '## Phase 9 — Emit follow-up tasks' plugins/dev-workflows/commands/release-notes.md
grep -c 'references/followup-emission.md' plugins/dev-workflows/commands/release-notes.md
grep -c '## Invariants (always enforced)' plugins/dev-workflows/commands/release-notes.md
git diff plugins/dev-workflows/commands/release-notes.md
```
Expected: the Phase 9 grep returns one line; `references/followup-emission.md` count is `1`; `## Invariants` count is `1`; the diff shows only the Phase 9 block inserted immediately before the (unchanged) invariants block.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/commands/release-notes.md
git commit -m "feat(dev-workflows): /release-notes emits follow-up tasks at end-of-run

Add a terminal Phase 9 (Emit follow-up tasks) before the invariants block. Cites
references/followup-emission.md for the paste-into-Jira manual step and any
implementation gaps; the task references the Phase 8 draft file. Additive; no
API calls, no commit, no docs-repo write.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Wire `/epics`

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md` (new Phase 10 before `## Invariants` ~L451)

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` (T1); the run's `jira_key`, `source`, and the Phase 9 report's `### Deferred items`.
- Produces: nothing cross-task.

- [ ] **Step 1: Insert the terminal phase (Phase 10)**

Find this exact block:

```
---

## Invariants (always enforced)

- ALWAYS resolve input via the shared Jira-input front-end (Phase 0) — a JiraID requires `$VAULT_PATH`; an imported-Jira directory works without it; `/epics` is cwd-agnostic and rejects `mode: direct`
```

Replace it with:

```
---

## Phase 10 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 9 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's manual-step / out-of-scope
follow-ups by citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md`
and executing its steps inline.

1. **Collect** the qualifying follow-ups: the manual publish step ("create these
   drafted Epics in Jira manually" — the drafts are vault/dir files, not Jira
   tickets) and the Phase 9 `### Deferred items` that are out-of-scope refinement.
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder using `jira_key` and `source`;
   render + place tasks and verbose notes per §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 9 report. This phase NEVER
fails the run, NEVER commits (git is the user's responsibility), and NEVER
writes into `jira-products/`, `jira_export_root`, or the current working
directory.

---

## Invariants (always enforced)

- ALWAYS resolve input via the shared Jira-input front-end (Phase 0) — a JiraID requires `$VAULT_PATH`; an imported-Jira directory works without it; `/epics` is cwd-agnostic and rejects `mode: direct`
```

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '## Phase 10 — Emit follow-up tasks' plugins/dev-workflows/commands/epics.md
grep -c 'references/followup-emission.md' plugins/dev-workflows/commands/epics.md
grep -c '## Invariants (always enforced)' plugins/dev-workflows/commands/epics.md
git diff plugins/dev-workflows/commands/epics.md
```
Expected: the Phase 10 grep returns one line; `references/followup-emission.md` count is `1`; `## Invariants` count is `1`; the diff shows only the Phase 10 block inserted immediately before the (unchanged) invariants block.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/commands/epics.md
git commit -m "feat(dev-workflows): /epics emits follow-up tasks at end-of-run

Add a terminal Phase 10 (Emit follow-up tasks) before the invariants block.
Cites references/followup-emission.md for the create-Epics-in-Jira manual step
and out-of-scope deferred refinement items. Additive; never commits or writes
into jira-products/ / jira_export_root / cwd.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Wire `/implement`

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (new Phase 6 before `## Invariants` ~L561)

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` (T1); the run's `jira_key`, `source`, and Phase 5 report signals.
- Produces: nothing cross-task.

- [ ] **Step 1: Insert the terminal phase (Phase 6)**

Find this exact block:

```
---

## Invariants (always enforced)

- NEVER skip Phase 1.5 classification — every run must state the level
```

Replace it with:

```
---

## Phase 6 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 5 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's out-of-scope / manual-step
follow-ups by citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md`
and executing its steps inline.

1. **Collect** the qualifying follow-ups: manual publish/config steps and
   out-of-scope maintenance items surfaced during the run (e.g. an
   impl-maintenance suggestion that touches another repo or team, or a manual
   post-merge step). **Do NOT** collect the report's `### Deferred items (from
   review or tests)` or skipped tests — §6 explicitly excludes those as in-scope
   work already carried by the current task.
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder using `jira_key` and `source`
   (jira-driven runs carry a key; direct-prompt runs usually do not, so tasks
   land in `Tasks.md # Irregular` when the vault is writable, else report-only);
   render + place tasks and verbose notes per §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 5 report. This phase NEVER
fails the run, NEVER commits, and NEVER writes into the code repo or the current
working directory.

---

## Invariants (always enforced)

- NEVER skip Phase 1.5 classification — every run must state the level
```

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '## Phase 6 — Emit follow-up tasks' plugins/dev-workflows/commands/implement.md
grep -c 'references/followup-emission.md' plugins/dev-workflows/commands/implement.md
grep -c '## Invariants (always enforced)' plugins/dev-workflows/commands/implement.md
grep -n 'explicitly excludes those as in-scope' plugins/dev-workflows/commands/implement.md
git diff plugins/dev-workflows/commands/implement.md
```
Expected: the Phase 6 grep returns one line; `references/followup-emission.md` count is `1`; `## Invariants` count is `1`; the "explicitly excludes" grep returns one line (the in-scope guard); the diff shows only the Phase 6 block inserted immediately before the (unchanged) invariants block.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/commands/implement.md
git commit -m "feat(dev-workflows): /implement emits follow-up tasks at end-of-run

Add a terminal Phase 6 (Emit follow-up tasks) before the invariants block.
Cites references/followup-emission.md for manual steps and out-of-scope
maintenance items; explicitly excludes in-scope deferred review/test items per
the predicate. Additive; never commits or writes into the code repo / cwd.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Release surfaces — v2.8.0 (versions, CHANGELOG, README)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (version)
- Modify: `.claude-plugin/marketplace.json` (`dev-workflows` entry version only)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend `[2.8.0]`)
- Modify: `plugins/dev-workflows/README.md` (Environment prerequisites bullet + Reference docs bullet)

**Interfaces:**
- Consumes: the behaviors implemented in Tasks 1–5 (for accurate CHANGELOG / README prose).
- Produces: the released version surface. Run last.

- [ ] **Step 1: Bump `plugin.json`**

Find `  "version": "2.7.0",` and replace with `  "version": "2.8.0",`. Leave `description` unchanged (no new commands/subagents).

- [ ] **Step 2: Bump `marketplace.json` (dev-workflows entry only)**

Find `      "version": "2.7.0",` (the dev-workflows entry — `2.7.0` is unique; siblings are `0.2.2` / `0.3.1`) and replace with `      "version": "2.8.0",`. Leave that entry's `description` unchanged and **do not touch** the `dt-style-guide` / `obsidian-llm-wiki` entries.

- [ ] **Step 3: Prepend the CHANGELOG entry**

Find this exact block (the current top-most entry):

```
## [2.7.0] — 2026-07-09

### Changed
```

Replace it with (the new entry, then the found block unchanged):

```
## [2.8.0] — 2026-07-09

### Added

- **Follow-up task & journal emission — `/document`, `/release-notes`, `/epics`, and `/implement` now persist out-of-scope / manual-step follow-ups at end-of-run.** Each command gains a terminal "Emit follow-up tasks" phase (after its Final Report) that filters the run's follow-up signals to those whose action lands *outside* the current change or needs a *manual human step* (files owned by other teams, Jira-vs-source implementation gaps, "paste release notes into Jira", "create these Epics in Jira manually", screenshots to upload), then persists them as durable Obsidian-Tasks `- [ ]` lines — with a `Journal.md` (or project `### Notes`) entry when an item needs more than a task line. A batch preview grouped by target file (`approve-all | select | cancel`) gates every write; nothing is written without one confirmation. In-scope items the report already tracks (deferred review BLOCKERs, skipped tests, in-draft TODOs) are deliberately excluded.
- **New shared reference `references/followup-emission.md`.** The single source of truth for the emitter: task-line format, Jira-key → project-file resolution (`P<NNNN> <slug>.md` → `## Work Items → ### Tasks`, else `Tasks.md # Irregular`), notes placement (project `### Notes` → `Journal.md`), stable-key dedupe, and the no-vault fallback ladder (`$VAULT_PATH` → the VI's `$SPECS_PATH` dir `<VI-dir>/dev-workflows/<KEY>-followups.md` → beside the imported Jira directory → report-only; never the cwd). **Self-contained** — no runtime dependency on the `obsidian-llm-wiki` plugin; it mirrors that plugin's `_shared/task-rules.md` + `vault-conventions.md` as upstream and adds journaling (which exists in neither plugin).

Additive only — existing phase behaviour, `jira-reader`, the reviewers, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; the follow-ups also remain in each command's Final Report (zero regression) and the phase never fails the run.

## [2.7.0] — 2026-07-09

### Changed
```

- [ ] **Step 4: Add the README Environment-prerequisites bullet**

In `plugins/dev-workflows/README.md`, find this exact line (the SPECS_PATH bullet):

```
- **`SPECS_PATH`** — Optional, AI-Containers env var (same rules as `VAULT_PATH`; mounted to `/workspace/specs` in-container). The deterministic source for a Jira ticket's specifications, at `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`. Used by `/implement` (required) and `/document` (additive).
```

Replace it with (same line, then a new bullet):

```
- **`SPECS_PATH`** — Optional, AI-Containers env var (same rules as `VAULT_PATH`; mounted to `/workspace/specs` in-container). The deterministic source for a Jira ticket's specifications, at `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`. Used by `/implement` (required) and `/document` (additive).
- **Follow-up task & journal emission (all four Jira-driven commands).** At end-of-run, `/document`, `/release-notes`, `/epics`, and `/implement` persist their out-of-scope / manual-step follow-ups (files owned by other teams, implementation gaps, "paste into Jira", screenshots to upload) as durable Obsidian tasks — plus a `Journal.md` note when an item needs more than a task line — via a batch preview (`approve-all | select | cancel`). Self-contained: it works **without** the `obsidian-llm-wiki` plugin (it mirrors that plugin's task conventions internally). Without a writable vault it degrades gracefully down a ladder — `$VAULT_PATH` → the VI's `$SPECS_PATH` dir (`<VI-dir>/dev-workflows/<KEY>-followups.md`) → beside the imported Jira directory → report-only — and never writes into the current working directory. See `references/followup-emission.md`.
```

- [ ] **Step 5: Add the README Reference-docs bullet**

In `plugins/dev-workflows/README.md`, find this exact line (the finish-and-handoff bullet):

```
- `references/finish-and-handoff.md` — how `/document` (Jira mode) Phase 8.5 finishes a run (squash, opt-in push, host-aware copy-paste PR draft) and how Phase 6.2 adopts an inline-profiling branch
```

Replace it with (same line, then a new bullet):

```
- `references/finish-and-handoff.md` — how `/document` (Jira mode) Phase 8.5 finishes a run (squash, opt-in push, host-aware copy-paste PR draft) and how Phase 6.2 adopts an inline-profiling branch
- `references/followup-emission.md` — the end-of-run follow-up task & journal emitter shared by `/document`, `/release-notes`, `/epics`, and `/implement` (task-line format, Jira-key → project-file resolution, notes / `Journal.md` placement, dedupe, the no-vault fallback ladder). Self-contained; mirrors obsidian-llm-wiki's `_shared/task-rules.md` + `vault-conventions.md`.
```

- [ ] **Step 6: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('plugin.json OK')"
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); v={p['name']:p['version'] for p in m['plugins']}; print(v); assert v['dev-workflows']=='2.8.0' and v['dt-style-guide']=='0.2.2' and v['obsidian-llm-wiki']=='0.3.1'"
grep -n '## \[2.8.0\] — 2026-07-09' plugins/dev-workflows/CHANGELOG.md
grep -c 'references/followup-emission.md' plugins/dev-workflows/README.md
git diff --stat
```
Expected: both JSON files parse; the marketplace assertion passes (dev-workflows `2.8.0`, siblings unchanged); the CHANGELOG grep returns one line; `references/followup-emission.md` appears **2** times in the README (Environment bullet + Reference-docs bullet); `--stat` lists exactly the four files (`plugin.json`, `marketplace.json`, `CHANGELOG.md`, `README.md`) and nothing else.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md
git commit -m "release(dev-workflows): v2.8.0 — follow-up task & journal emission

Version lock-step (plugin.json + marketplace.json dev-workflows entry),
CHANGELOG [2.8.0] Added, and README (Environment + Reference docs bullets).
Siblings untouched.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Notes for the executor

- **Byte-diff discipline:** these are prose/JSON files; after each task, read the `git diff` and confirm no unintended reflow or anchor drift. Prettier is **not** run here.
- **Anchor drift:** line numbers in this plan are approximate (from a 2026-07-09 read). Locate edits by the quoted anchor text, not by line number.
- **Additive contract:** with no qualifying follow-ups and no writable target, every command behaves exactly as today (the follow-ups always also remain in the Final Report). Any behavior change in that case is a defect.
- **`document.md` has two `## Invariants (always enforced)` headings** (Mode A, Mode B). The T2 find blocks disambiguate by including each mode's first invariant bullet — never match the bare heading.
```
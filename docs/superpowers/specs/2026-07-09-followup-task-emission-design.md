---
tags: tasks-exclude
---

# Follow-up Task & Journal Emission — Design

**Date:** 2026-07-09
**Status:** Approved (design) — awaiting spec review
**Target:** dev-workflows plugin (`/workspace/ihudak-claude-plugins/plugins/dev-workflows/`), release **v2.8.0**
**Backlog item:** B4

---

## 1. Goal

When a dev-workflows pipeline surfaces something the user must act on **outside the
current task** — files owned by other teams, Jira-vs-source implementation gaps,
manual publish steps ("paste this into Jira", "create these Epics manually", upload
these screenshots) — persist the qualifying items as durable **Obsidian tasks**
(Obsidian-Tasks `- [ ]` syntax), plus a **`Journal.md`** entry when an item needs
more explanation than fits on a task line. Today these live only in the ephemeral
end-of-run Final Report; when the session ends, the follow-up evaporates.

## 2. Motivating example

During the PRODUCT-14902 (ActiveGate autoupdate) documentation run, the pipeline
found 4 non-allowlisted docs files owned by 4 other people — unrelated to the AG
work in flight. Those had to be surfaced so the user could contact the owners. That
is the canonical B4 case: a real, actionable, **out-of-scope** finding that must
outlive the session.

## 3. Architecture decision — self-contained

dev-workflows ships its **own** follow-up emitter (a shared reference + a terminal
phase per command). It mirrors the obsidian-llm-wiki task-line format and placement
rules and adds journaling. **No install-time dependency** on obsidian-llm-wiki.

Rationale:

- The wiki plugin's own batch tool `/wiki-tasks-extract` reuses the shared
  *conventions inline* and explicitly does **not** invoke `/wiki-task` as a command
  (its Step 7: "apply the same rules inline"). So the reusable unit is the
  conventions, never the command.
- Journaling exists in **neither** plugin — `Journal.md` is the user's own vault
  convention. It is net-new regardless of which plugin hosts it.
- Marketplace plugins should install independently; a hard dependency would force a
  "requires obsidian-llm-wiki" caveat into every command's docs.
- dev-workflows has structured Jira context (the run's `jira_key`) that resolves the
  target project file **deterministically** by matching the key to the project
  folder — something `/wiki-task`'s natural-language parse cannot do.

Cost: a small, second copy of a stable task-line format spec. Mitigated by keeping
dev-workflows' copy minimal and citing the wiki `_shared/*.md` files as upstream.

**Rejected alternatives:** hard dependency on obsidian-llm-wiki (delegating to
`/wiki-task`); runtime read of the sibling plugin's `_shared/*.md` (cache-path /
version fragility). Both add coupling for no journaling benefit.

## 4. Components

### 4.1 New reference — `references/followup-emission.md`

Single source of truth for the emitter. Contents:

- **Task-line format** — mirrors wiki `_shared/task-rules.md`:
  `- [effort] Description #tags priority ➕ <today>` (scheduled/due optional). Effort
  on the Fibonacci scale; tags **reuse-only** from `.obsidian/copilot/tag-index.md`
  (never invent; omit if absent).
- **Target-file resolution** (see §5).
- **Notes placement** — project `### Notes` first, `Journal.md` fallback (see §6).
- **Idempotency / dedupe** (see §7).
- **Vault-availability preflight & fallback ladder** (see §8).
- **Qualifying predicate** — what becomes a task (see §9).

### 4.2 Qualifying predicate (§9) — reused by every wired command.

### 4.3 Interaction model (§10) — batch preview at end-of-run.

### 4.4 Command wiring (§11) — one terminal phase per command.

## 5. Target-file resolution (Jira-first, deterministic)

Runs carry a `source` field (`vault | directory | none`) from
`references/jira-input-resolution.md`.

1. **Vault writable (§8) and run has a `jira_key`:** locate the project folder with
   the existing pattern `find $VAULT_PATH/Projects -maxdepth 5 -type d -name
   "<JIRA_KEY>*"` (`references/finish-and-handoff.md:58`). Inside it, the project
   file is `P<NNNN> <slug>.md`. Verify frontmatter `tags:` includes `task` and
   `archived:` is `false`/absent, then insert under `## Work Items → ### Tasks`.
   (Verified against `P14902 Env AG Update Win.md`: `jira.id: PRODUCT-14902`,
   `tags: [task, …]`, `archived: false`, `## Work Items → ### Tasks` at the expected
   place, `## Archived Tasks` present as the never-touch zone.)
2. **Vault writable but no project match / verification fails / no `jira_key`
   (`source = none`):** fall back to `Tasks.md` under `# Irregular`; create
   `Tasks.md` from the bootstrap template if it does not exist (wiki rule).
3. **Never** insert into `## Archived Tasks`, `# Archive`, or Daily notes.

## 6. Verbose notes — project file first, `Journal.md` as fallback

Some follow-ups need more than a task line (a table, multi-step context, a
paste-ready draft). Notes follow the **same primary → fallback split as tasks** (§5):
`Journal.md` is the notes analogue of `Tasks.md` — the home for notes that have no
project yet, *not* a catch-all.

- **Task landed in a project file** (`P<NNNN> <slug>.md`) → append the note as a new
  dated block to that file's `## Work Items → ### Notes` section (verified present in
  `P14902 …`; create the section under `## Work Items` if a resolved project file
  lacks one). The task links to it: `[[<project-file>#<note-heading>]]`.
- **Task landed in `Tasks.md`** (no project home) → append the note to
  `$VAULT_PATH/Journal.md` as a dated H1 block (`# <Topic> — <purpose>
  (YYYY-MM-DD)`, matching the existing style). The task links via
  `[[Journal#<note-heading>]]`.
- **No writable vault** → the note is inlined as a section of `<KEY>-followups.md`
  (§8 tier 2+); the task links to that section.

Notes are append-only; never modify existing blocks. When a run already produced a
`<KEY>-implementation-gaps.md` draft (source-truth §7.5), the task references that
file rather than duplicating it.

## 7. Idempotency / dedupe

Pipelines re-run. Before inserting, read existing tasks in the target section and
**skip** any whose stable key already appears. Stable key = the finding's identity:
`jira_key` + (file path | gap-id | signal-type). Matches on that key are reported as
`SKIP — already exists` (mirrors `/wiki-tasks-extract` Step 5), never re-inserted.

## 8. Vault-availability preflight & fallback ladder

At the start of the emission phase, resolve the write target by walking a ladder,
most-durable first. `vault_writable` = `$VAULT_PATH` set **and** `$VAULT_PATH/.obsidian/`
is a directory **and** the path is writable.

1. **Vault writable** → emit vault tasks (§5) + verbose notes (§6). *[primary]*
2. **No vault, `$SPECS_PATH` resolvable and the VI spec dir exists**
   (`$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…`) → write
   `<VI-dir>/dev-workflows/<KEY>-followups.md` (see §8.1). Durable, VI-scoped,
   git-tracked (the specs repo), and **not** a code repo. Verbose "journal" content
   is inlined as sections of that same file (no `Journal.md` outside a vault); the
   task line links to the section.
3. **No vault, no `$SPECS_PATH` VI dir, `source = directory`** → beside the imported
   Jira directory (where `/epics` + `/release-notes` already write their no-vault
   output).
4. **None resolvable** → **report-only.** Keep the follow-ups in the Final Report and
   emit the notice. **Never** write into the current working directory — it may be a
   code repository.

In every non-vault tier the follow-ups **also remain** in the Final Report (today's
behavior — zero regression) and the pipeline never fails.

- **Notice** (tiers 2–4): `⚠ No writable Obsidian vault — N follow-ups written to
  <path>` (tier 4: `… kept in this report only; set $VAULT_PATH or $SPECS_PATH to
  persist them`).
- **Interactive escape** (folds into the batch preview, mirrors Fallback A in
  `jira-input-resolution.md`): below the vault tier, show the resolved fallback path
  and offer `["Save to <resolved path>", "Enter a vault path", "Keep in report
  only"]`, default = save.
- **Write fails mid-insert** (read-only mount / permission) → drop to the next tier,
  same notice.

### 8.1 Shared per-VI artifact area under `$SPECS_PATH`

`<VI-dir>/dev-workflows/` (a subdir of the VI's `$SPECS_PATH` spec dir) is the home
for dev-workflows per-VI artifacts written outside the vault. B4 writes
`<KEY>-followups.md` there; planned future extensions (session feedback, session cost
reporting) share the same directory. This keeps the VI spec dir uncluttered and
groups all dev-workflows output for a VI in one place.

## 9. Qualifying predicate — what becomes a follow-up

Emit a task **only** for signals whose action lands *outside the current change* or
requires a *manual human step*:

- Files/pages owned by others (non-allowlisted, override-copy, owner surfaced) — the
  PRODUCT-14902 case.
- Implementation gaps (Jira vs source; the `<KEY>-implementation-gaps.md` draft) →
  task links the draft; verbose context → Journal.
- Manual publish steps: screenshots to upload (CDN), "paste release notes into
  Jira", "create these Epics in Jira manually", open-the-PR-by-hand.
- SPEC-VS-JIRA ("update the Jira ticket to match the spec").
- Unresolved PRs on unsupported hosts (must be documented manually).

**Do not** emit tasks for in-scope items the report/draft already tracks: deferred
review BLOCKERs, skipped tests, in-draft `<!-- TODO -->` markers. Those belong to the
current task and are already carried.

## 10. Interaction model

Mirror `/wiki-tasks-extract`: **no mid-run interruption.** A new terminal phase
(after the Final Report is composed) presents the qualifying follow-ups as a **batch
preview grouped by target file** → `approve-all | select | cancel` → then inserts.
Nothing is written to the vault (or fallback file) without one confirmation. Each
preview row shows: source signal, target file → section, and the rendered task line.

## 11. Command wiring

Each command gains one new **terminal phase — "Emit follow-up tasks"** — that reads
its own accumulated follow-up items (already aggregated in the Final Report
sections), applies §9, and calls `references/followup-emission.md`.

In scope (the four Jira-driven commands the user named):

- **`/document`** (Mode A + Mode B) — richest source: implementation gaps, CDN
  uploads, non-allowlisted files/owners, SPEC-VS-JIRA, unresolved PRs.
- **`/release-notes`** — paste-into-Jira, implementation gaps.
- **`/epics`** — create-Epics-in-Jira-manually, deferred refinement items that are
  out-of-scope.
- **`/implement`** — manual steps and out-of-scope maintenance items.

Untouched: `jira-reader`, `format-refs`, all reviewers, and sibling plugins
(`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1).

## 12. Release surfaces

- `plugin.json` version → **2.8.0**; `.claude-plugin/marketplace.json` dev-workflows
  entry → 2.8.0 (lock-step; siblings 0.2.2 / 0.3.1 untouched).
- `CHANGELOG.md` — prepend a `## [2.8.0] — 2026-07-09` entry.
- `README.md` — document the follow-up-tasks feature (and that it works without the
  wiki plugin; degrades gracefully without a vault).
- Additive only. Commit trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Never
  `git add -A`.

## 13. Non-goals

- No dependency on obsidian-llm-wiki (self-contained by decision §3).
- No mid-run task creation / no per-signal interruption.
- No emission for in-scope, already-tracked report items (§9).
- No modification of existing task or note blocks (append-only).
- No changes to `jira-reader`, reviewers, or sibling plugins.

## 14. Resolved decisions (from brainstorming)

- **A. Architecture** — self-contained (§3). Approved.
- **B. Qualifying boundary** — out-of-scope / manual-step only (§9). Approved.
- **C. Interaction** — batch preview at end-of-run (§10). Approved.
- **D. Scope** — the four Jira-driven commands (§11). Approved.
- **E. No writable vault** — fallback ladder: vault → `$SPECS_PATH` VI dir
  (`<VI-dir>/dev-workflows/<KEY>-followups.md`) → beside-import → report-only; never
  cwd (§8, §8.1). Approved.

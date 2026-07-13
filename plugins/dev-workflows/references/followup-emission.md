# Follow-up Task & Journal Emission — Shared Reference

Single source of truth for the dev-workflows follow-up emitter. A terminal
"Emit follow-up tasks" phase in `/document`, `/release-notes`, `/epics`,
`/implement`, and `/ready` cites this file and executes its steps inline — the orchestrator
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
   folder with the existing pattern (`${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md`):

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
is an existing directory **and** the path is writable.

1. **Vault writable** → emit vault tasks (§2) + verbose notes (§3). *[primary]*
2. **No vault; `$SPECS_PATH` resolvable and the VI spec dir exists** — the dir
   matched by `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…` →
   write `<VI-dir>/dev-workflows/<KEY>-followups.md` (§4.1). Durable, VI-scoped,
   git-tracked (the specs repo), and NOT a code repo. Verbose "journal" content
   is inlined as sections of that same file (no `Journal.md` outside a vault);
   the task line links the section.
3. **No vault; no `$SPECS_PATH` VI dir; `source = directory`** → write beside
   the imported Jira directory:
   `<parent-of-jira_export_root>/<KEY>-followups.md` (the imported hierarchy's
   parent — the same area under which /epics and /release-notes place their
   no-vault drafts, e.g. /epics' epic-drafts/<jira_key>/).
4. **None resolvable** → **report-only.** Keep the follow-ups in the Final
   Report and emit the notice. **NEVER** write into the current working
   directory — it may be a code repository.

In every non-vault tier the follow-ups ALSO remain in the Final Report (today's
behaviour — zero regression) and the pipeline never fails.

- **Notice** (tiers 2–4):
  `⚠ No writable vault — N follow-ups written to <path>`;
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

**If no signal qualifies after this filter, the phase is a no-op:** resolve no
target, show no preview or vault-path prompt, write nothing, and end silently —
the run is byte-identical to one where this phase did not exist.

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

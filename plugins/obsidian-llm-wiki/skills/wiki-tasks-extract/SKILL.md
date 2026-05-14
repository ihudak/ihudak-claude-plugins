---
name: wiki-tasks-extract
description: >
  Batch-extract tasks from a wiki knowledge base. Harvests explicit action-item flags
  from _log.md and performs a semantic scan of wiki pages for implicit action items.
  Deduplicates against existing tasks, presents candidates for approval, and creates
  them using wiki-task format rules. Invoke after wiki-ingest or wiki-scan has processed
  meeting transcripts or documents. Triggers on: wiki-tasks-extract, extract tasks from
  wiki, harvest tasks, find action items.
allowed-tools: Read Write Edit Glob Grep Bash AskUser
---

# wiki-tasks-extract

Read these files fully before proceeding:
- `skills/_shared/task-rules.md`
- `skills/_shared/vault-conventions.md`

Then attempt to read `.obsidian/copilot/tag-index.md` (at vault root).
If the file does not exist, note it and continue — tags will be omitted from tasks.
See the "If `tag-index.md` does not exist" section in `task-rules.md`.

Invoke with: `/wiki-tasks-extract [wiki-path]`

---

## Step 1 — Resolve VAULT_PATH

Vault path: `~/obsidian_vault` by default; set `VAULT_PATH` to override.
WSL users with a Windows-side vault must set `VAULT_PATH` explicitly
(e.g. `/mnt/c/Users/<name>/obsidian_vault`).

All file paths below are relative to the vault root.

---

## Step 2 — Determine wiki path

| Argument | Resolved path |
|----------|---------------|
| _(none)_ | `wiki/` (vault root wiki) |
| Relative path (e.g. `Projects/Products/MyProject/wiki/`) | As given, relative to vault root |
| Absolute path | Use directly |

Validate:
- The directory exists
- It contains `_log.md` or `_index.md` (confirming it is a wiki directory)

If invalid, report the error and stop.

Identify the **project context**: if the wiki path is under
`Projects/<Category>/<project>/`, remember this project for target-file
matching in Step 7.

---

## Step 3 — Phase A: Harvest flagged action items

Read `<wiki-path>/_log.md`. Extract every line matching:

```
- Action items flagged: <description>
```

For each, record:
- The description text
- The source file from the log entry heading
  (the log format is `## [YYYY-MM-DD] ingest | <source-file>` followed by bullet points)
- The date from the log entry heading
- Any surrounding context (decisions, people mentioned, technologies)

Skip any action item that appears in a previous `tasks-extract` log entry
(heading format: `## [YYYY-MM-DD] tasks-extract | ...`). This prevents
re-extraction on subsequent runs.

These are **high-confidence** candidates — the ingest process already
identified them as action items.

---

## Step 4 — Phase B: Semantic scan

Read wiki pages in:
- `<wiki-path>/concepts/`
- `<wiki-path>/entities/`
- `<wiki-path>/decisions/`
- `<wiki-path>/patterns/`
- `<wiki-path>/sources/`

For each page, look for implicit action items — sentences or phrases that
indicate something that needs to be done but was not flagged as an
`action-item:` during ingest. Signals include:

- **Obligation language**: "need to", "should", "must", "have to", "required to"
- **Future commitments**: "will follow up", "plan to", "going to", "agreed to"
- **Explicit TODO markers**: "TODO", "FIXME", "HACK", "FOLLOWUP"
- **Deadlines**: "by next week", "before the release", "deadline is"
- **Assignments**: "[person] will", "[person] is responsible for", "assigned to"
- **Open questions needing resolution**: "still open", "needs decision",
  "unresolved", "TBD"

For each candidate, record:
- The extracted action text
- The source wiki page
- The source file referenced in the wiki page's frontmatter (`source:` field)
- Surrounding context

**Important**: Do not extract observations, facts, or decisions that are
already completed. Only extract items that represent future work or
unresolved commitments.

---

## Step 5 — Deduplicate

### 5.1 — Deduplicate Phase A vs Phase B

Remove Phase B candidates that duplicate Phase A items (same action,
same source).

### 5.2 — Deduplicate against existing tasks

Read current tasks from:
1. If project context is known and `Projects/` exists: the project file in
   `Projects/` that matches the project context
2. `Tasks.md` (if it exists)

If neither location exists, skip deduplication — there are no existing tasks.

For each candidate, check if a substantially similar task already exists
(match on description keywords, Jira ticket IDs, or source references).
Mark duplicates as `SKIP — already exists in <file>:<line>`.

---

## Step 6 — Present candidates

Group candidates by proposed target file. For each candidate, show:

```
[source] <wiki-page or log entry>
[target] <proposed target file> → ### Tasks
[task]   - [effort] Description #tags priority dates
[status] NEW | SKIP — already exists in <file>
```

Present the full list and ask the user to:
- **Approve all** — create all non-skipped candidates
- **Select** — approve/reject/modify individual candidates
- **Cancel** — abort without creating any tasks

---

## Step 7 — Create approved tasks

For each approved candidate, apply the **wiki-task creation logic** directly
(do not invoke `/wiki-task` as a separate command — apply the same rules inline):

1. **Find target file** — use the file-selection algorithm from `task-rules.md`.
   If project context was identified in Step 2, prefer that project.
2. **Verify** — run the verification checklist.
3. **Format** — assemble the task line with effort, tags, priority, dates,
   `➕ <today>`.
4. **Insert** — add to the correct section in the target file.

Process all approved tasks in a single pass. Group insertions by target file
to minimise file reads/writes.

---

## Step 8 — Append extraction record to the log

Append a new entry at the TOP of `<wiki-path>/_log.md` (newest first).
Do **not** modify any existing log entries — `_log.md` is append-only.

```markdown
## [YYYY-MM-DD] tasks-extract | <wiki-path>
- Tasks created: N (in M files)
- From Phase A (flagged action items): X
- From Phase B (wiki content scan): Y
- Skipped (duplicates): D
- Skipped (rejected by user): R
- Source action items processed: "<description1>", "<description2>", ...
```

The `Source action items processed` line lists the Phase A descriptions that
were turned into tasks. Subsequent runs of `/wiki-tasks-extract` read previous
`tasks-extract` entries to identify already-processed action items and skip them.

Do **not** modify wiki pages for Phase B items — those were implicit
extractions, not structured flags.

---

## Step 9 — Summary

Report to the user:

```
✅ Tasks extracted from <wiki-path>

Created: N tasks
  - <file1>: K tasks
  - <file2>: M tasks
Skipped (duplicates): X
Skipped (rejected): Y

Log entry appended to _log.md (tasks-extract record)
```

List the full text of each created task with its target file for reference.

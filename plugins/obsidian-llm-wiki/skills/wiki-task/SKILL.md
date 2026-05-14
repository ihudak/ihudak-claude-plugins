---
name: wiki-task
description: >
  Create a single Obsidian Tasks-compatible task from a natural language prompt. Detects
  target file, tags, Fibonacci effort estimate, priority, scheduled/due dates, Jira links,
  and people references. Previews the formatted task for user approval before inserting.
  Replaces the legacy "task:" prefix. Triggers on: wiki-task, create task, add task,
  new task.
allowed-tools: Read Write Edit Glob Grep Bash AskUser
---

# wiki-task

Read these files fully before proceeding:
- `skills/_shared/task-rules.md`
- `skills/_shared/vault-conventions.md`

Then attempt to read `.obsidian/copilot/tag-index.md` (at vault root).
If the file does not exist, note it and continue — tags will be omitted from tasks.
See the "If `tag-index.md` does not exist" section in `task-rules.md`.

Invoke with: `/wiki-task <description>`

---

## Step 1 — Resolve VAULT_PATH

Vault path: `~/obsidian_vault` by default; set `VAULT_PATH` to override.
WSL users with a Windows-side vault must set `VAULT_PATH` explicitly
(e.g. `/mnt/c/Users/<name>/obsidian_vault`).

All file paths below are relative to the vault root.

---

## Step 2 — Parse the prompt

Analyse the natural-language `<description>` and extract every field you can.
Do not ask follow-up questions for fields that are simply absent — leave them
at their defaults. Only ask the user when the prompt is genuinely ambiguous
(e.g., two plausible target projects).

### 2.1 — Description text

The core task description. Strip out metadata you extract into other fields
(dates, priority words, effort hints) so the description reads cleanly.

### 2.2 — Effort estimate

Map effort hints to Fibonacci values using the scale in `task-rules.md`.
Heuristics:
- Explicit numbers or words: "5 min" → `[0]`, "quick" → `[0]`–`[1]`,
  "half a day" → `[3]`, "a few days" → `[5]`, "a week" → `[8]`.
- Action verbs: "review" / "approve" / "check" → lean `[0]`–`[1]`;
  "implement" / "build" / "migrate" → lean `[2]`–`[5]`;
  "design" / "architect" → lean `[3]`–`[8]`.
- If truly no signal: use `[ ]` (unestimated).
- When in doubt between two values, pick the higher one.

### 2.3 — Priority

Look for: "urgent", "critical", "highest", "high", "low", "lowest",
"asap", "blocking", "nice to have", "backlog".
Map to the priority emoji from `task-rules.md`. Default: none (Normal).

### 2.4 — Dates

- Scheduled date (`⏳`): "start on", "begin", "from", "starting"
- Due date (`📅`): "due", "by", "before", "deadline", "until"
- Relative dates: "today", "tomorrow", "next Monday", "in two weeks",
  "end of month" — resolve to `YYYY-MM-DD` using the current date.
- Always add `➕ <today>` (created date).

### 2.5 — Tags

**If `tag-index.md` was loaded**: match keywords against the tag index
categories (work areas, technology, people, work type, etc.).
Never invent tags. If a keyword has no match, skip it silently.

**If `tag-index.md` was not found**: skip tagging entirely. The task is still
valid — Obsidian Tasks does not require tags.

### 2.6 — Jira tickets

Pattern: uppercase letters + dash + digits (e.g., `MGD-7211`).
To find the Jira base URL, follow the detection steps in `task-rules.md`
(search existing tasks → ask user → or skip linking).

### 2.7 — Dependencies and recurrence

Only extract if explicitly stated. See `task-rules.md` for `🆔`, `⛔`, `🔁` syntax.

---

## Step 3 — Find the target file

### 3.1 — Project match

First, check whether `Projects/` exists:

```bash
[ -d "Projects/" ] && echo "EXISTS" || echo "ABSENT"
```

**If absent**: skip to Step 3.3 (fallback).

**If present**: search `Projects/` for a file whose name or content keywords match
the task's context (project name, tags, Jira project prefix).

```bash
grep -rl "tags:" Projects/ --include="*.md" | head -20
```

For each candidate, read the frontmatter and check:
- `archived:` is `false` (or absent)
- `tags:` contains `task`

If multiple projects match, prefer the one with the strongest keyword overlap.
If still ambiguous, ask the user which project.

### 3.2 — Project-level wiki context

If the user invoked `/wiki-task` while discussing a specific project's wiki
(e.g., after `/wiki-tasks-extract Projects/Products/MyProject/wiki/`), prefer
the project file in that same project directory.

### 3.3 — Fallback

If no eligible project matches: target `Tasks.md`, section `# Irregular`.

**If `Tasks.md` does not exist**: create it with the bootstrap template from
`task-rules.md`, then insert the task under `# Irregular`.

### 3.4 — Never

Never target Daily notes unless the user explicitly says "add to today's daily note".

---

## Step 4 — Verify target

Run the verification checklist from `task-rules.md`:
- Target file has `#task` in frontmatter tags (project files only)
- Target file has `archived: false` or no `archived` field
- The insertion point is in `### Tasks` section (project files) or
  `# Irregular` (Tasks.md), not an archive section

If verification fails, try the next candidate or fall back to Tasks.md.

---

## Step 5 — Assemble the task line

Build the complete task line following the format in `task-rules.md`:

```markdown
- [effort] Description #tag1 #tag2 priority ⏳ scheduled 📅 due ➕ created
```

Order of elements:
1. `- [effort]` — checkbox with effort character
2. Description text (with Jira links inline if applicable)
3. Tags
4. Priority emoji (if not Normal)
5. Dependency markers (if any)
6. Recurrence (if any)
7. `⏳ YYYY-MM-DD` scheduled (if any)
8. `📅 YYYY-MM-DD` due (if any)
9. `➕ YYYY-MM-DD` created (always)

---

## Step 6 — Preview and confirm

Present the formatted task to the user along with:
- The target file path
- The section where it will be inserted
- The parsed fields (effort, priority, dates, tags) so they can verify

Use AskUser to get approval. The user may:
- **Approve** — proceed to insert
- **Modify** — adjust fields, re-preview
- **Cancel** — abort without writing

---

## Step 7 — Insert the task

Read the target file. Find the correct section heading:
- Project files: `### Tasks`
- Tasks.md: `# Irregular`

Insert the task line at the **end** of the existing tasks in that section
(before the next heading or end of file). Do not reorder existing tasks.

Use the `Edit` tool to insert the line.

---

## Step 8 — Confirm

Report to the user:
- ✅ Task created
- File: `<path>`
- Line: (approximate line number)
- Full task text (for copy-paste reference)

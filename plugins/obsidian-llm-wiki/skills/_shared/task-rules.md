# Task Rules — Shared Reference

Single source of truth for Obsidian Tasks format, placement, and tag rules.
Referenced by `/wiki-task` and `/wiki-tasks-extract` skills.

For vault directory layout, project file structure, and section conventions,
see `vault-conventions.md` (also in `_shared/`).

### Vault-level reference files (read at runtime if they exist)

| File | Purpose | If missing |
|------|---------|------------|
| `.obsidian/copilot/tag-index.md` | Tag vocabulary | Skip tagging — do **not** invent tags. Warn the user once that tag-index.md is absent and tags will be omitted. |
| `.obsidian/copilot/vault-structure.md` | Vault directory layout | Use defaults below (Projects/, Tasks.md). |

---

## Task Line Format

```markdown
- [effort] Description #tag1 #tag2 priority ⏳ scheduled 📅 due ➕ created
```

---

## Effort Estimate (Fibonacci)

The checkbox character encodes estimated effort on a Fibonacci scale.

| Char | Meaning | Guideline |
|------|---------|-----------|
| `[ ]` | Unestimated | Could not determine effort |
| `[0]` | Tiny | Almost no effort — a quick toggle, trivial fix |
| `[1]` | Small | Under an hour — a focused, self-contained change |
| `[2]` | Medium | A few hours — requires thought but scope is clear |
| `[3]` | Large | Half a day to a day — multiple files or coordination |
| `[5]` | Very large | Multiple days — significant scope, possible unknowns |
| `[8]` | Huge | A week+ — consider splitting into subtasks |
| `[13]` | Epic-scale | Multi-week — almost certainly should be broken down |

Special status characters (not effort — set by task lifecycle):

| Char | Meaning |
|------|---------|
| `[/]` | In progress |
| `[x]` | Completed |
| `[-]` | Cancelled |

When estimating: if unsure between two values, pick the higher one.
If the task is clearly composite (multiple independent steps), suggest splitting.

---

## Priority

| Symbol | Level | When to use |
|--------|-------|-------------|
| `🔺` | Critical | Blocking others or time-critical escalation |
| `⏫` | Highest | Must be done first among current tasks |
| `🔼` | High | Important but not blocking |
| _(none)_ | Normal | Default — most tasks |
| `🔽` | Low | Can wait; do when convenient |
| `⏬` | Lowest | Backlog / nice-to-have |

Place the priority symbol after tags, before dates.

---

## Dates

| Symbol | Meaning | Format |
|--------|---------|--------|
| `⏳` | Scheduled (start working on) | `⏳ YYYY-MM-DD` |
| `📅` | Due (must be done by) | `📅 YYYY-MM-DD` |
| `✅` | Completed on | `✅ YYYY-MM-DD` (added when task is checked off) |
| `➕` | Created on | `➕ YYYY-MM-DD` (add when creating the task) |

Always add `➕ <today>` when creating a task. Scheduled and due dates are optional —
add only when the prompt provides or implies them.

---

## Dependencies

| Symbol | Meaning | Format |
|--------|---------|--------|
| `🆔` | Task identifier | `🆔 <short-id>` — assign when other tasks will reference this one |
| `⛔` | Blocked by | `⛔ <short-id>` — this task cannot start until the referenced task completes |

Use only when the user explicitly describes a dependency chain.

---

## Recurrence

Format: `🔁 every <interval>` — e.g., `🔁 every week on Tuesday`.
Use only when the prompt explicitly describes a recurring task.

---

## Jira Ticket Linking

When the prompt mentions a Jira ticket ID (e.g., `MGD-7211`, `PRODUCT-8313`):

**Detecting the Jira base URL** (run once per session, cache the result):

1. Search existing tasks for Jira links: `grep -rh 'atlassian.net/browse/' Projects/ Tasks.md 2>/dev/null | head -3`
2. If found, extract the base URL (e.g., `https://my-org.atlassian.net/browse/`).
3. If not found, ask the user: "I found a Jira ticket ID but don't know your Jira URL. What is your Atlassian base URL? (e.g., `https://my-org.atlassian.net`)"
4. If the user says they don't use Jira, include the ticket ID as plain text without a link.

Format when URL is known:
```markdown
[TICKET-ID](https://my-org.atlassian.net/browse/TICKET-ID)
```

---

## Tag Rules

**If `.obsidian/copilot/tag-index.md` exists:**

1. **Always** reuse tags from the tag index.
2. **Never** invent new tags silently. If a new tag seems warranted, ask the user.
3. Select tags by matching prompt keywords to the tag index categories
   (work areas, technology, people, work type, etc.).
4. Tags are critical for dashboard filtering — use them consistently.

**If `tag-index.md` does not exist:**

1. Warn the user once: "No tag-index.md found — tags will be omitted. Create `.obsidian/copilot/tag-index.md` with your tag vocabulary to enable tagging."
2. Create the task **without tags**. Do not guess tags.
3. The task is still valid — Obsidian Tasks does not require tags.

---

## File Selection Priority

### Step 1 — Find related project file

Check whether a `Projects/` directory exists in the vault root.

**If `Projects/` exists**: search it for a file whose name or content matches
keywords from the task prompt.

**Eligibility criteria** (both must be true):
- Frontmatter `archived:` is `false` (or the field is absent)
- Frontmatter `tags:` includes `task`

If the prompt references a specific project-level wiki path
(`Projects/<Category>/<project>/wiki/`), prefer the project file in that same
project directory.

**If `Projects/` does not exist**: skip straight to Step 2.

### Step 2 — Fallback

If no eligible project file matches (or `Projects/` does not exist): add the
task to `Tasks.md` under the `# Irregular` section.

**If `Tasks.md` does not exist**: create it with this minimal structure:

```markdown
---
tags:
  - task
---

# Tasks

# Irregular
```

Then insert the task under `# Irregular`.

### Step 3 — Never

Never add tasks to Daily notes (`Daily/`) unless the user explicitly requests it.
Daily-note tasks are hard to reschedule.

---

## Section Placement

- **In project files**: insert under the `### Tasks` heading (active tasks).
  Never insert into "Archive", "Archived Tasks", or any section excluded from
  dashboard queries.
- **In `Tasks.md`**: insert under `# Irregular`.
- **In Daily notes** (only when explicitly requested): insert into the worklog
  section.

---

## Verification Checklist

Before inserting a task, confirm:

- [ ] Target file has `task` in frontmatter `tags` array (project files only; not applicable to Tasks.md)
- [ ] Target file has `archived: false` or no `archived` field (project files only)
- [ ] Inserting into `### Tasks` section, not an archive section
- [ ] All tags come from `tag-index.md` (skip this check if tag-index.md is absent)
- [ ] Line format includes: effort, description, tags (if available), priority, dates
- [ ] `➕ <today>` date is present
- [ ] Jira links are properly formatted (if applicable and Jira base URL is known)

---

## Complete Examples

```markdown
- [1] Review multi-env support PR #review ⏫ 📅 2026-01-23 ➕ 2026-01-20
- [2] Draft architecture doc for new pipeline #doc 🔼 ⏳ 2026-02-10 📅 2026-02-14 ➕ 2026-02-07
- [0] Approve token rotation PR #review ➕ 2026-03-01
- [5] Migrate legacy metrics endpoint to v2 API ⏫ ⏳ 2026-03-15 📅 2026-03-28 ➕ 2026-03-10
- [ ] Investigate intermittent dashboard failure ➕ 2026-04-01
```

(Tags shown above are illustrative. Use only tags from your vault's `tag-index.md`.)

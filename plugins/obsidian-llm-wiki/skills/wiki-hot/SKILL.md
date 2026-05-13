---
name: wiki-hot
description: >
  Manually refresh the wiki hot cache (hot.md) by reading recent wiki activity and
  summarising the current state of the wiki in 300 words or fewer. Use when the hot
  cache is stale, missing, or you want to seed it at the start of a new project phase.
  Triggers on: wiki-hot, refresh hot cache, update hot cache, hot cache, wiki hot.
allowed-tools: Read Write Glob Grep Bash
---

# wiki-hot

Read `skills/wiki-schema/SKILL.md` fully before proceeding.

Invoke with: `/wiki-hot`

---

## Step 1 — Resolve VAULT_PATH

Vault path: `~/obsidian_vault` by default; set `VAULT_PATH` to override. WSL users with a Windows-side vault must set `VAULT_PATH` explicitly (e.g. `/mnt/c/Users/<name>/obsidian_vault`).

---

## Step 2 — Read recent activity

1. Read the last 10 entries of `wiki/_log.md` (top of file — newest first).
2. Read `wiki/_index.md` to understand current wiki scope.
3. For any pages created or updated in the last 3 log entries: read those pages.

---

## Step 3 — Write hot.md

Overwrite `wiki/hot.md` completely with a fresh summary following the format
from `wiki-schema`:

```markdown
---
type: meta
title: "Hot Cache"
updated: YYYY-MM-DDTHH:MM:SS
---

# Recent Context

## Last Updated
YYYY-MM-DD. [One sentence: what the most recent wiki activity was]

## Key Recent Facts
- [Most important recent knowledge in the wiki]
- [Second most important]
- [Third, only if genuinely significant]

## Recent Changes
- Created: [[list of recently created pages]]
- Updated: [[list of recently updated pages]]
- Flagged: [any unresolved contradictions or open issues, or "none"]

## Active Threads
- [Current research topic or work in progress, based on log]
- [Open question not yet resolved, or "none identified"]
```

Constraints:
- Total file length: ≤300 words. Cut ruthlessly.
- Focus on what is most likely to be useful at the start of the next session.
- Do not narrate the full log history. Synthesise.

---

## Step 4 — Append to _log.md

```markdown
## [YYYY-MM-DD] hot | manual refresh
```

---

## Finish

```
Hot cache refreshed. wiki/hot.md updated (YYYY-MM-DD).
```

---
name: guideline-reviewer
description: Review Dynatrace app code and UI for compliance with Dynatrace Experience Standards (GUIDElines). Checks AppHeader, DataTable, FilterField, Connections, Permissions, Settings, Dashboards, accessibility, and Grail naming.
allowed-tools: Read Bash Glob Grep WebFetch
---

Review Dynatrace app code and UI for compliance with Dynatrace Experience Standards (GUIDElines): $ARGUMENTS

Read the full review instructions from the agent file:
`~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/guideline-reviewer.md`

Follow those instructions exactly. Load ALL GUIDEline reference files before reviewing — never use a subset.

If `$ARGUMENTS` is empty, ask the user which files or components to review.

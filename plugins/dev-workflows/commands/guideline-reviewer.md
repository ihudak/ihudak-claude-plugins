---
name: guideline-reviewer
description: Review Dynatrace app code and UI for compliance with Dynatrace Experience Standards (GUIDElines). Checks AppHeader, DataTable, FilterField, Connections, Permissions, Settings, Dashboards, accessibility, and Grail naming.
allowed-tools: Read Bash Glob Grep WebFetch
---

Review Dynatrace app code and UI for compliance with Dynatrace Experience Standards (GUIDElines): $ARGUMENTS

If `$ARGUMENTS` is empty, ask the user which files or components to review.

Dispatch the review to the `guideline-reviewer` subagent:

→ Agent (subagent_type: "dev-workflows:guideline-reviewer"):
  > "Review the following app code and UI for compliance with Dynatrace Experience Standards (GUIDElines): $ARGUMENTS"

Surface the subagent's verdict to the user.

---
name: guideline-reviewer
description: Review app code and UI for compliance with public UI design-system and accessibility standards. Checks app header, data table, filter field, connections, permissions, settings, dashboards, accessibility, and data naming.
allowed-tools: Read Bash Glob Grep WebFetch
---

Review app code and UI for compliance with public UI design-system and accessibility standards: $ARGUMENTS

If `$ARGUMENTS` is empty, ask the user which files or components to review.

Dispatch the review to the `guideline-reviewer` subagent:

→ Agent (subagent_type: "dev-workflows:guideline-reviewer"):
  > "Review the following app code and UI for compliance with public UI design-system and accessibility standards: $ARGUMENTS"

Surface the subagent's verdict to the user.

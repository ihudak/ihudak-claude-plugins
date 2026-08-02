---
tags: tasks-exclude
type: bug-log
project: dev-workflows copilot port
date: 2026-07-13
---

# Bugs / issues found in the Claude marketplace during the Copilot port

Log of problems spotted in `/workspace/ihudak-claude-plugins` while porting to
Copilot. These are **not fixed here** — they are captured for later remediation
in the Claude marketplace.

Format: one dated entry per finding.

## 2026-07-14 — dev-workflows/skills/_shared/followup-emission.md §2 — Project-file resolution misses `P<NNNN> <slug>.md` files in shared product-area folders
- **What:** Target-file resolution finds a ticket's project doc via `find "$VAULT_PATH"/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"` (looking for a *directory* named e.g. `PRODUCT-17012*`). This fails when the working document is a **file** (`P17012 Public Container Registry.md`) grouped inside a shared product-area folder (`Projects/Products/DAQ/`) rather than a per-ticket `PRODUCT-<NNNN>-<slug>/` folder. Two compounding causes: (1) `-type d` won't match a `.md` file; (2) the file uses the `P<NNNN>` naming convention (which §2 itself references as `P<NNNN> <slug>.md`) plus a descriptive slug, not the literal `PRODUCT-<NNNN>` key. Result: the follow-up task falls back to `Tasks.md → # Irregular` even though a proper project doc with `## Work Items → ### Tasks` exists.
- **Where:** `dev-workflows/skills/_shared/followup-emission.md` §2 (also used by `session-hygiene.md` §1 and `finish-and-handoff.md` — same `-type d -name "<KEY>*"` pattern).
- **Impact:** bug
- **Suggested fix:** Resolve the project file by frontmatter `jira.id` (grep `Projects/**/*.md` for `id: <JIRA_KEY>`, then verify `tags:` includes `task` and `archived:` is false/absent) instead of, or in addition to, matching a folder name. This handles both layouts: per-ticket folders and product-area-grouped `P<NNNN> <slug>.md` files.

<!-- template
## YYYY-MM-DD — <plugin>/<file> — <short title>
- **What:** <the problem>
- **Where:** <path:line>
- **Impact:** blocker | bug | inconsistency | polish
- **Suggested fix:** <one line>
-->


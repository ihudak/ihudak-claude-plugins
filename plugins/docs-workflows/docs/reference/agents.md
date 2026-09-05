# Agents reference

`docs-workflows` bundles seven agents under `agents/`, dispatched internally by the invoking command via `subagent_type: "docs-workflows:<name>"` — none of them is a user entry point. One, `doc-reviewer`, carries a `model: opus` frontmatter pin (shown as **opus** below) and runs on Opus every time, regardless of the dispatching command's own model tier for that run; the remaining six carry no pin (shown as **per routing**) and are assigned a tier by the dispatching command per the task-complexity classification the `workflows-core` model-routing reference fixes. Two further agents these commands dispatch — `doc-fixer` and `impl-maintenance` — ship in the companion `workflows-core` plugin and are listed in its own agents reference, not here; `prose-style-checker` and `prose-fixer` ship in `prose-style`. Each row's **Used by** column lists only the commands that actually dispatch that agent as a subagent.

## Reviewers and planners

The gate `/document` runs after writing, plus the planner and the style checker that feed it.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `doc-reviewer` | opus | Read, Glob, Grep, Skill | Reviews product documentation written by `/document` for correctness, completeness, and fitness for purpose; product-docs only — Epic drafts go through the pipeline plugin's `epic-reviewer`. | `/document` |
| `doc-planner` | per routing | Read, Glob, Grep, Skill | Synthesises PRD content, per-repo diff summaries, and confirmed write targets into the documentation checklist the writer follows and the reviewer checks against; writes no content itself. | `/document` |
| `docs-style-checker` | per routing | Read, Glob, Grep, Bash, Task | Runs the docs repo's configured prose linter and a complementary `prose-style-checker` pass; merges both finding sets for `doc-reviewer`/`doc-fixer`. | `/document` |

## Readers and scanners

Read-only discovery — each returns a structured digest rather than editing anything.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `diff-summarizer` | per routing | Read, Glob, Grep, Bash, Skill | Reads one repository's PR diff(s) and returns a documentation-focused summary; host-aware — `gh` CLI for GitHub when available, pure local git for Bitbucket and GitHub fallback. | `/document`, `/release-notes` |
| `doc-location-finder` | per routing | Read, Glob, Grep | Finds the right place(s) in a docs repository to write new or extended documentation, returning a prioritised list of write targets with rationale; heuristic search, no content written. | `/document` |

## Writers

Produce content from a structured handoff. Neither runs git.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `doc-writer` | per routing | Read, Glob, Grep, Write, Edit, Bash, Skill | Writes product documentation from a structured handoff — the `doc-planner` checklist, approved per-page write strategies, discrepancy decisions, snippets, screenshots, frontmatter, links. | `/document` |
| `release-notes-writer` | per routing | Read, Glob, Grep, Skill | Renders a release-notes draft — exactly one Summary, shaped by its resolved destination; emits no work-item ID, PR link, or internal-note wrapper. Does not write files. | `/release-notes` |

Every one of the seven agents above is dispatched by at least one command. `/docs-profile` dispatches none of them: it scans a documentation repository itself and writes the profile `/document` consumes.

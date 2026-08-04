# Escalation rules (shared)

Canonical `choices:` arrays for escalation decision points. Every decision
point uses a `choices:` array whose **last** entry is `"Other… (describe)"` where
applicable. Command bodies are authoritative; where `/document` and `/epics`
differ for the same scenario, both variants are listed.

## Jira key dir not found

`choices: ["Re-enter key", "Cancel"]`

Used when `jira-reader` returns `status: NOT_FOUND` or `status: EMPTY`, or when
Phase 0 of `jira-reader` rejects an invalid `jira_key` format.

## Repo unresolved (zero matches) — /document

`choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]`

Used in `/document` Phase 4 when a repo slug has zero matches in the
slug→clone map.

## Repo unresolved (zero matches) — /epics

`choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]`

Used in `/epics` Phase 4 when a repo slug has zero matches in the
slug→clone map.

## No repos derivable — /epics

`choices: ["List repos to scan manually", "Proceed without code scan", "Cancel", "Other… (describe)"]`

Used in `/epics` Phase 4 when the final resolved repo list is empty (every repo
was skipped or missing — "Use case B with no repos derivable").

## Repo missing (after resolution)

`choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]`

Used when a diff-summarizer or code-scanner batch returns `REPO_MISSING` at
Phase 5, after Phase 4 already checked. Present this choice per affected repo.

## Dirty working tree

`choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel", "Other… (describe)"]`

Used in `/document` Phase 5 when a diff-summarizer returns `DIRTY_TREE`.

In `/epics` Phase 5 the `"Other… (describe)"` entry is omitted:
`choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]`

## Branch prefix undetected

`choices: ["Use `<fallback>` (default for this command)", "Use my initials — I'll enter them", "Other… (describe)"]`

Used by every branch-creating command (`/implement`, `/document`, `/docs-profile`, `/upgrade`, `/vuln`) when the `branch-naming.md` §1 ladder — `$GIT_USER_INITIALS`, `git config user.initials`, then inference from existing branches — yields nothing and the per-command fallback in §1.4 would be used. `<fallback>` is that command's own default (`feat/`, `docs/`, `fix/`, `chore/`).

On `"Use my initials"`, follow up with a free-text prompt: `"Enter your initials (lowercase; 2–8 characters from [a-z0-9-], starting with a letter or digit, e.g. `iv-gu` or `ivgu`; used as `<initials>/<slug>`):"` — then suggest, without persisting, `GIT_USER_INITIALS` or `git config --global user.initials`.

## Refresh blocked

`choices: ["Continue with current local state", "Skip this repo", "Cancel", "Other… (describe)"]`

Used in `/document` Phase 5 when a diff-summarizer returns `REFRESH_BLOCKED`.

In `/epics` Phase 5 the `"Other… (describe)"` entry is omitted:
`choices: ["Continue with current local state", "Skip this repo", "Cancel"]`

## Review verdict BLOCK (unresolved after one fix cycle) — /document

`choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]`

Used in `/document` Phase 7 when `doc-reviewer` returns BLOCK a second time.
Escalate per unresolved BLOCKER individually.

## Review verdict BLOCK (unresolved after one fix cycle) — /epics

`choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run", "Other… (describe)"]`

Used in `/epics` Phase 7 when `epic-reviewer` returns BLOCK a second time.
Escalate per unresolved BLOCKER individually. "Defer" means the finding goes
into an Epic-refinement note in the draft itself (appended as a
`## Refinement notes` section) in addition to the Phase 9 report.

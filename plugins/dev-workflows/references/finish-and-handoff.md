# Finish & handoff (/document — Jira mode)

The mechanics for Phase 6.2's inline-profiling-branch handling and Phase 8.5's
finish & handoff (squash → opt-in push → copy-paste PR draft). Generic git +
PR-draft logic; the command cites this so it stays lean. Read repo specifics
from the resolved `profile`. The plugin NEVER creates a PR via any REST API.

## 1. The branch entering Phase 8.5

Phase 6.2 created (normal case) or renamed (inline-profiling case) the work
branch off the base (main/master/release), named per repo convention, and
recorded:
- `base_branch` — the resolved base.
- `profile_commit` (C0) — set ONLY for an inline-profiling run
  (`profile_source: generated`): the commit that introduced
  `.dev-workflows/docs-profile.yml`, found with
  `git log --diff-filter=A --format=%H -- .dev-workflows/docs-profile.yml | head -1`.
  Absent otherwise.

## 2. Squash (always)

Stage the run's uncommitted docs-repo edits first — Phase 8 Agent 1 (doc index /
cross-links) may have edited without committing; the Phase 6.2 clean-tree
precondition means anything uncommitted is this run's work.
Then squash:
- squash base = `profile_commit` (C0) when recorded — keeps the profile-config
  commit as a distinct first commit; otherwise `git merge-base <base_branch> HEAD`.
- mechanics: `git add` the docs-repo changes → `git reset --soft <squash-base>`
  → one `git commit -m "<message>"`.
- message follows `profile.commit_convention` when present (dynatrace-docs:
  `<JIRA-KEY> <summary>`); for a repo with no such field, infer from recent
  `git log` / `CONTRIBUTING` (a ticket-key prefix, or a conventional-commits
  `docs:` prefix), else fall back to `<JIRA_KEY> <summary>`. The Jira key carries
  traceability; the reader-visible changelog still must NOT name it.

## 3. Push (opt-in)

Offer `["Push <branch> to origin now", "Skip — I'll push later", "Cancel"]`.
- **Push** → `git push -u origin <branch>`; report the result. `git push` is
  git-protocol, not the REST API the zero-external-API invariant forbids.
- **Skip** → "Branch `<branch>` ready with N commit(s). Push when ready."
- **Cancel** → stop and summarise.
Never force-push. Never call a PR REST API.

## 4. Host detection

Classify the docs repo's `git remote get-url origin`:
- host `bitbucket.org` → Bitbucket Cloud;
- a self-hosted host with `/scm/` in the path or a bitbucket-style hostname →
  Bitbucket Server;
- host `github.com` → GitHub;
- anything else → other.

## 5. PR draft (always; no API)

Compose the draft and BOTH write and show it:
- **write** to the vault project folder as `<JIRA_KEY>-pr-draft.md`
  (`find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if
  none) — the same destination convention as the release-notes / bug drafts.
- **title**: per `commit_convention` (e.g. `<JIRA-KEY> <summary>`).
- **body**: what was documented; the output files; the Phase 6.5
  render-verification summary; deferred style/review/render items; a link back
  to the Jira VI.
- **DO-NOT-MERGE banner** at the very top WHEN Phase 5.8 recorded any
  `document-as-spec` / `skip-and-report` decision:
  `> ⚠ DO NOT MERGE until <JIRA_KEY>-implementation-gaps.md is resolved.`
- **host footer**:
  - Bitbucket (Cloud / Server) → "Open a pull request in the web UI and paste
    the title + body above." (No API.)
  - GitHub → additionally offer a command the USER may run:
    `gh pr create --title "<title>" --body-file <pr-draft path>`.
  - other → "Open a pull request in your host and paste the title + body above."

The plugin never opens the PR itself.

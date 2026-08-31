# Finish & handoff (/document — keyed mode)

The mechanics for Phase 6.2's inline-profiling-branch handling and Phase 8.5's
finish & handoff (squash → opt-in push → copy-paste PR draft). Generic git +
PR-draft logic; the command cites this so it stays lean. Read repo specifics
from the resolved `profile`. This flow does not open the pull request itself: docs repos here are Bitbucket-hosted, and Bitbucket offers no CLI that can create one. Where a host does — the GitHub-hosted specs repo — the plugin opens it via `gh`; see `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.6.

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
- message follows `profile.commit_convention` when present (example-docs:
  `<KEY> <summary>`); for a repo with no such field, infer from recent
  `git log` / `CONTRIBUTING` (a ticket-key prefix, or a conventional-commits
  `docs:` prefix), else fall back to `<KEY> <summary>`. The key carries
  traceability; the reader-visible changelog still must NOT name it.

## 3. Push (opt-in)

Offer `["Push <branch> to origin now", "Skip — I'll push later", "Cancel"]`.
- **Push** → `git push -u origin <branch>`; report the result. `git push` is
  git-protocol, not the REST API the zero-external-API invariant forbids.
- **Skip** → "Branch `<branch>` ready with N commit(s). Push when ready."
- **Cancel** → stop and summarise.
Never force-push. Never call a REST API over HTTPS from this flow. (The `gh` CLI wraps the API rather than calling it over HTTPS and is permitted where a host provides one — but that allowance belongs to pull-request creation, which this docs-repo flow does not perform; see §5 and `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.6.)

## 4. Host detection

Classify the docs repo's `git remote get-url origin`:
- host `bitbucket.org` → Bitbucket Cloud;
- a self-hosted host with `/scm/` in the path or a bitbucket-style hostname →
  Bitbucket Server;
- host `github.com` → GitHub;
- anything else → other.

## 5. PR draft (always; no API)

Compose the draft and BOTH write and show it:
- **write** to the vault project folder as `<KEY>-pr-draft.md`
  (the resolved PRD folder; ask if
  none) — the same destination convention as the release-notes / bug drafts.
- **title**: per `commit_convention` (e.g. `<KEY> <summary>`).
- **body**: what was documented; the output files; the Phase 6.5
  render-verification summary; deferred style/review/render items; a link back to the PRD.
- **DO-NOT-MERGE banner** at the very top WHEN Phase 5.8 recorded any
  `document-as-spec` / `skip-and-report` decision:
  `> ⚠ DO NOT MERGE until <KEY>-implementation-gaps.md is resolved.`
- **host footer**:
  - Bitbucket (Cloud / Server) → "Open a pull request in the web UI and paste
    the title + body above." (No API.)
  - GitHub → additionally offer a command the USER may run:
    `gh pr create --title "<title>" --body-file <pr-draft path>`.
  - other → "Open a pull request in your host and paste the title + body above."

For a Bitbucket-hosted docs repo the plugin cannot open the pull request — there is no CLI for it — so it writes the draft and the user opens it. This is a host capability limit, not a policy: on a host with a CLI — the GitHub-hosted specs repo — the plugin does open the pull request, but that is a separate flow against `$SPECS_PATH`, never this docs repo (`phase-handoff.md` §2.6).

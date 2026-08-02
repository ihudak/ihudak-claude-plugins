---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-27
---

# dev-workflows docs automation — SP2 Increment 3c: finish & handoff (design)

## Context

Increment 3 of sub-project 2 (the `/impl:jira:docs` single-entry enhancement),
sub-increment **3c**. Builds on 3a (v1.12.0 — multi-space write safety) and 3b
(v1.13.0 — render verification). Plugin `main` at `d92f746`.

Today the command commits the docs to a branch (Phase 6.5 creates it, Phase 6
commits) but **stops at "Branch created with N commits. Push when ready"**
(Phase 9) — no squash, no push, and it never opens a PR
(`The plugin does NOT open a PR (zero-external-API invariant)`). 3c adds the
finish & handoff: squash, an opt-in push, and a copy-paste PR draft — plus it
fixes the carried obligation that the on-demand profiling branch leaves the
command on the wrong branch.

The remaining sub-increment gets its own spec→plan cycle:
- **3d — docs & disambiguation:** README "AI-Containers as default"; the
  committed Vale-fallback-note restore; "which docs command?" disambiguation;
  the "All five `/impl:*`" count fix; **and the vestigial-write-context wording
  cleanup surfaced here (see Out of scope).**

## Decisions (resolved during brainstorming)

| Decision                | Choice                                                                                                                                                                                                                                                                                                                                                                                                        |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Push                    | **Offer to push (opt-in prompt).** A `choices` prompt is the explicit "ask" (satisfies "push only when the user asks"). Yes → `git push -u origin <branch>`; No → today's "push when ready" guidance. `git push` is git-protocol, not the REST API the zero-external-API invariant forbids.                                                                                                                   |
| Squash                  | **Always squash the run into one docs commit** before push (composed message `<JIRA_KEY> <summary>`, per repo commit convention). Cleaner PR history; reversible because it happens before push.                                                                                                                                                                                                              |
| Inline-profiling branch | **Keep the profile-config commit separate.** Phase 6.5 detects HEAD on the generated-profile branch, renames it to the docs-branch convention, and records the profile-config commit `C0`. The squash base is then `C0`, so `C0` (profile) survives as a distinct first commit and only the docs commits fold into one → **two commits, one PR**.                                                             |
| Gaps at handoff         | **Proceed + DO-NOT-MERGE banner.** Phase 8.5 always squashes/offers push; when Phase 5.8 recorded any `document-as-spec` (code lags) or `skip-and-report` decision, the PR draft carries a "⚠ DO NOT MERGE until `<JIRA_KEY>-implementation-gaps.md` resolved" banner. (These "gaps" are the user's deliberate document-ahead-of-code choice, not a workflow error.)                                          |
| cwd / obsidian          | **Keep Phase 0's redirect; gate Phase 8.5 on "a branch + commits exist."** Phase 0 already resolves a real docs repo (cwd-if-docs-repo → discover `dynatrace-docs` under `/workspace` → ask); a cwd hard-stop would wrongly break the "run from anywhere" flow. The `obsidian`/`plain_dir` *write-contexts* are vestigial post-Inc1; 3c drops the obsidian framing and the wording cleanup is deferred to 3d. |
| PR creation             | **Copy-paste draft only — never a PR API call** (preserves the zero-external-API invariant).                                                                                                                                                                                                                                                                                                                  |
| Mechanics location      | A new top-level `references/finish-and-handoff.md` (generic git + PR-draft logic, not dynatrace-specific), cited by Phase 6.5 + Phase 8.5 — mirrors `multi-space-writing.md` / `render-verification.md`.                                                                                                                                                                                                      |

## Placement

New **Phase 8.5 — Finish & handoff**, between Phase 8 (maintenance) and Phase 9
(report). It must run after Phase 8 so the squash captures the maintenance edits.
It runs only when Phase 6 wrote + committed in a git repo (write context
`docs_repo`, or `non_docs_repo` confirmed at Phase 0) — i.e. **a branch + commits
exist**; otherwise it is skipped.

## Increment 3c design

### A. Phase 6.5 — inline-profiling-branch handling

When Phase 0 profiled a custom repo (`profile_source: generated`),
`/impl:docs:profile` already ran `git switch -c <profile-branch>` and committed
`.dev-workflows/docs-profile.yml`, so the command reaches Phase 6.5 already on
that branch. Phase 6.5:
- detects HEAD is on the generated-profile branch (`profile_source == generated`
  and the current branch is the one profiling created);
- **renames it to the docs-branch convention** (`git branch -m <docs-name>`,
  the same name it would otherwise derive in step 3) rather than branching anew;
- **records `profile_commit` = the profile-config commit SHA (C0)** for the
  Phase 8.5 squash base.

For in-repo / built-in profiles (the dynatrace-docs case) this never fires;
Phase 6.5 behaves exactly as today (`git switch -c <name>` from the resolved base).

### B. Phase 8.5 step 1 — squash (always)

Stage any uncommitted Phase 8 maintenance edits (in the docs repo only), then
collapse the run into a single docs commit.

**Why there can be uncommitted edits here:** Phase 6 commits the docs writes,
but Phase 8's maintenance agents *edit without committing* — Agent 1
(Documentation) may touch an index / sidebar / cross-reference in the docs repo,
and Agent 3 (Instructions) may touch `CLAUDE.md` in the repo root. Folding them
into the squash is safe because Phase 6.5 step 2 enforced a **clean tree at
branch creation**, so anything uncommitted post-Phase-8 is *this run's* work,
nothing stray. (Committing them in Phase 8 only to squash them away here would
be redundant.)

- **squash base** is contextual:
  - `profile_commit` (C0) recorded → base = **C0** (the profile-config commit
    survives as the first commit; only the docs commits fold) → **two commits**;
  - otherwise → base = `git merge-base <base-branch> HEAD` → **one commit**.
    (The branch was created off the base in Phase 6.5 and holds only this run's
    work, so this collapses exactly this JIRA_KEY's docs.)
- mechanics: stage the run's docs-repo changes (`git add`) → `git reset --soft
  <base>` → one `git commit`.
- **commit message** follows `profile.commit_convention` when present (the
  dynatrace-docs default is `"<JIRA-KEY> <summary>"`); for a repo with no such
  field, infer the convention from recent `git log` / `CONTRIBUTING` (e.g. a
  ticket-key prefix or a conventional-commits `docs:` prefix), else fall back to
  `<JIRA_KEY> <summary>`. The Jira key carries traceability — the reader-visible
  changelog still must NOT name it.

### C. Phase 8.5 step 2 — offer push

```
choices: ["Push <branch> to origin now", "Skip — I'll push later", "Cancel"]
```
- **Push** → `git push -u origin <branch>`; report the result.
- **Skip** → today's "Branch `<name>` ready with N commit(s). Push when ready."
- **Cancel** → stop and summarise.

### D. Phase 8.5 step 3 — copy-paste PR draft (always, no API)

- **Detect the host** from the docs repo's `git remote get-url origin`
  (Bitbucket Cloud / Bitbucket Server / GitHub / other).
- **Compose the draft**: title (`<JIRA_KEY> <summary>`); body — what was
  documented, the output files, the Phase 6.8 render-verification summary, any
  deferred style/review/render items, a link back to the Jira VI, and — **when
  Phase 5.8 recorded any `document-as-spec`/`skip-and-report` decision** — a top
  banner "⚠ DO NOT MERGE until `<JIRA_KEY>-implementation-gaps.md` resolved".
- **Write + show**: write `<JIRA_KEY>-pr-draft.md` to the vault project folder
  (resolved like the release-notes / bug drafts —
  `find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if
  none) **and** print it.
- **Host-specific footer**: Bitbucket → "open a PR in the web UI and paste this
  title/body"; GitHub → additionally offer the `gh pr create --title … --body-file
  <path>` command **the user** can run (the plugin still never calls a PR API);
  other → generic "open a PR and paste this".

### Phase 9 update

The branch / next-steps section reports what Phase 8.5 did: squashed to N
commit(s); pushed (yes/no, with the branch); and the PR-draft path. Replaces
today's static "Branch created with N commits. Push when ready."

### Mechanics reference (new)

`references/finish-and-handoff.md` — the single source of truth for: the
contextual squash-base computation (C0 vs merge-base), the squash mechanics, the
opt-in push flow, host detection from the docs-repo remote, and the PR-draft
template (title/body, the conditional DO-NOT-MERGE banner, the host-specific
footer). Generic git/PR-draft logic; cited by Phase 6.5 + Phase 8.5 to keep the
command lean.

## Touch list

- `commands/impl/jira/docs.md` — Phase 6.5 (generated-profile-branch detect +
  rename + record `profile_commit`); new **Phase 8.5**; Phase 9 branch/next-steps
  update.
- `references/finish-and-handoff.md` (NEW) — the mechanics.
- `references/dynatrace-docs/docs-profile-schema.md` — document the new
  `commit_convention` field (sits beside `branch_naming`).
- `references/dynatrace-docs/docs-profile.default.yml` — add
  `commit_convention: "<JIRA-KEY> <summary>"`.
- Manifests + CHANGELOG + README — release bump to **v1.14.0**.

~4 plan tasks.

## Invariants preserved

- **Zero-external-API:** no PR is created via any REST API; the draft is
  copy-paste (or, on GitHub, a command the *user* may run). Pushing a branch via
  `git push` is git-protocol and is gated behind the explicit opt-in prompt.
- **"Push only when the user asks":** push happens only on the explicit choice.
- The reader-visible changelog still never names the Jira key (the squash commit
  message does).

## Out of scope (later sub-increment)

- **3d** — README "AI-Containers as default"; the **committed** Vale-fallback
  note restore; "which docs command?" disambiguation; the "All five `/impl:*`"
  count fix; **and tidying the vestigial `obsidian`/`plain_dir` write-context
  wording** (the command always resolves a real docs repo or asks — it reads the
  vault and writes drafts there, but never writes product docs into a non-docs
  repo).

## Resolved during spec review

- **Uncommitted edits at Phase 8.5** are Phase 8 Agent 1 / Agent 3 maintenance
  edits (doc index/cross-links, `CLAUDE.md`); safe to fold into the squash given
  the Phase 6.5 clean-tree precondition.
- **Commit message** = a new `profile.commit_convention` field (dynatrace-docs
  default `"<JIRA-KEY> <summary>"`); non-dynatrace repos infer from `git log` /
  `CONTRIBUTING`, else default `<JIRA_KEY> <summary>`. Schema + default profile
  updated.
- **Branch** is off the base (main/master/release), named per convention,
  containing only this JIRA_KEY's docs commits (plus the `C0` profile-config
  commit in the custom-repo inline-profiling case).

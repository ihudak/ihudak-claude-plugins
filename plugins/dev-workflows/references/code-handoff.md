# Code-repo handoff — Shared Reference

Single source of truth for the step that turns finished work in a **code repository** into a commit on its own branch, pushes that branch, and opens a pull request where the host allows one: the `finish-code-branch` entry point (§2). Consumed by `/implement`, `/vuln`, and `/upgrade` — the three commands that create a branch in a code repo and write into it.

**The principle.** Work that exists only in a working tree is one `git checkout` away from gone, and a command that created the branch it was written on owns getting it committed before the run ends. Committing is local and reversible, so it is not the user's to approve. Pushing and opening a pull request leave the machine, so they are.

**Why this file exists.** `/implement` and `/upgrade` each created a branch, wrote into it, ran their gates, and then ended — leaving every change uncommitted, with nothing but the user's own memory standing between a finished implementation and a stray `git checkout`. `/vuln` did commit and open a pull request, but named no mechanics for either: no capability probe, no fallback for a host without `gh`, no defined base branch. All three are now this file's callers.

**Relationship to the other two git references.** Three references, and what separates them is which repository each may write into:

| Reference | Repository | Scope |
|---|---|---|
| `specs-repo-git.md` | `$SPECS_PATH` | bookkeeping — session artifacts, cost, feedback |
| `phase-handoff.md` | `$SPECS_PATH` | phase deliverables — idea, PRD, ARD, specification, design, readiness, BRD artifacts |
| **this file** | the **code** repo (under `$REPOS_PATH`, or the working clone) | the code the run just wrote |

This file never writes into `$SPECS_PATH` and neither of the others ever writes into a code repo; the two that share `$SPECS_PATH` are separated by *which paths* they stage, not by repository (`specs-repo-git.md` §2.1's bounded bookkeeping set versus the caller's own declared deliverable paths). A single run may execute all three against different targets, and the outcome lines — `Specs repo:`, `Phase handoff:`, `Code repo:` — are what keep them attributable in its output.

---

## 1. Hard rules

1. **`git -C "<repo>"` always; `cd` never.** The caller may be standing somewhere else entirely — `/implement` on a multi-source run reasons about several repos at once, and a `cd` would corrupt whichever one it left.
2. **Never the default branch.** The commit lands on the run's own branch or it does not land. This entry point never commits to `main` / `master` / `develop`, and never pushes to one.
3. **Never destructive.** No `push --force`, no `push -f`, no `branch -D`, no `merge`, no `rebase`, no `reset`, no `checkout --`, no `commit --amend`, and never delete an `index.lock`. It also never *drops* a stash: a stash the caller pushed at branch time is the user's, and §2.2 carve-out 2 says so.
4. **Never fatal.** Every failure is reported and the run's remaining phases still execute — including the caller's terminal `commit-artifacts` step, which commits a different repository.
5. **The commit is prompt-free; the push and the pull request are not.** This is the same rule as `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §1 rule 7, drawn one step later: there, nothing at all happens without consent because the deliverable is already safe on disk. Here the work is *not* safe until it is committed, and a prompt that can be answered "no" is exactly the failure mode this file was written to remove. So the commit runs unconditionally and §2.4's choice governs only what leaves the machine.

**The one opt-out, and it is typed rather than clicked.** `/implement` and `/upgrade` take `--no-commit`, which skips this entry point entirely and leaves the work in the tree. That does not contradict rule 5: the rule is about a prompt a tired operator clicks past at the end of a long run, not about someone who deliberately asked. A caller running under it says once, in its report, what the choice costs — the work is recoverable only on this machine, and `/document` and `/release-notes` will not find it later (`${CLAUDE_PLUGIN_ROOT}/references/implementation-format.md` §4) — and does not argue it twice. `/vuln` has no such flag.

---

## 2. `finish-code-branch` — the entry point

Called once per branch the run finished work on, at the point where **every** in-repo write is done — including the caller's post-implementation maintenance agents, which edit `README.md`, `CHANGELOG.md`, `CLAUDE.md`, and in-repo memory files. A call placed before those agents run leaves their edits outside the commit, which is the one ordering mistake this step can make.

### 2.1 Gate

All of: `repo` is set and is an existing directory; `git -C "<repo>" rev-parse --git-dir` succeeds; the repo **and** its `.git` are writable (`${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md` §1's probe — a read-only mount can hold no commit); `git -C "<repo>" symbolic-ref --quiet HEAD` succeeds (HEAD is on a branch, not detached); and that branch is not the resolved default branch (§2.7).

A failed gate is reported through §3.1's `NOT committed` line and the run continues. Two of the failures are worth naming rather than merely reporting:

- **Read-only mount.** Expected, not anomalous — a run that could not write into the repo has nothing to commit either. Name the mount and do not offer a retry.
- **Detached HEAD.** The same blocking state `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §3.3 G0 names for the specs repo, and for the same reason: a commit made there is reachable from no ref. Report it; never create a branch to escape it, because the branch this run was supposed to be on is not the one this step gets to choose.

### 2.2 What gets staged

**The precondition.** Every caller runs a clean-tree check before its first file edit (`/implement` Pre-Phase 3 step 1, `/upgrade` Phase 2 prep step 1, `/vuln` Step 3). Where that check found a clean tree, everything uncommitted in the repo now **is** this run's work — the same reasoning `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §2 applies to the docs repo — and staging is `git -C "<repo>" add -A`.

Enumerate before staging regardless: `git -C "<repo>" status --porcelain --untracked-files=all`. `--untracked-files=all` is required — the default collapses an untracked directory to a single `?? dir/` line, so the run would report a file count it never actually saw.

Three carve-outs:

1. **The user chose "proceed anyway" on a dirty tree.** Then the precondition does not hold, and `add -A` would sweep somebody else's uncommitted work into this run's commit. The caller passes `pre_existing_dirty` — the porcelain paths it captured at branch time. List them and ask:

       choices: ["Commit only this run's changes (Recommended)", "Commit everything in the working tree", "Skip the commit — leave the tree as it is"]

   Option 1 stages by enumeration: the current porcelain set minus the recorded paths. **A path that was already dirty and that this run also edited is staged by option 1**, and is listed in the prompt as both — the run's edit is inside that file and cannot be separated from what was there before. Say which paths those are; do not silently decide it.

2. **A stash the caller pushed.** Never restored here and never dropped. It stays where it is and §3.1's line names it, because a stash nobody mentions is a stash nobody remembers.

3. **Temp files are already out of reach.** Every caller writes its diffs, claims files, and scan summaries to `mktemp -t …` outside any repo tree specifically so `add -A` cannot pick them up. This step does not re-verify that; a caller that writes a temp file inside the tree breaks this step's staging, which is why the rule sits in the callers.

**Nothing staged → no commit.** Emit §3.1's `nothing to commit` line and continue to §2.4 only if there is an earlier commit on this branch to push. This is not an error: an `/upgrade` component already at its target version, or a re-run that changed nothing, both land here legitimately.

### 2.3 Commit

**Subject.** Every commit this entry point makes ends with `[<key>]` where the run resolved a key, and carries a `Work-Item: <workitem_key>` trailer where the resolved folder has one — `${CLAUDE_PLUGIN_ROOT}/references/implementation-format.md` §3, which is this plugin's own documented convention and applies to all three callers. **This is where the plugin writes that convention rather than merely teaching it**, and it is why §3's table has no "asks the operator to" row any more.

Everything the convention leaves open comes from the repository, never from habit: read `git -C "<repo>" log --oneline -20` and match what it shows. A conventional-commits log gets `feat:` / `fix:` / `chore:` matching the type the run's own branch prefix already expresses (`${CLAUDE_PLUGIN_ROOT}/references/branch-naming.md` §2.4 lists each command's fallback prefix, but a repo with its own documented convention may have supplied a different one — read what the run resolved, not the fallback table); a log with no discernible convention gets a plain imperative subject. A caller with a full template of its own overrides this paragraph — `/vuln`'s "Git Workflow → Commit message" is the one that exists today — and passes it as `commit_template`.

**A run with no key writes no suffix.** `/implement` in direct mode and `/vuln` on a bare `CVE-ID` both resolve no folder; the subject is the bare imperative and the trailer is absent. Never invent a key to satisfy the convention — the scan in `implementation-format.md` §4 searches for tokens the run already holds, and a minted one matches nothing.

**Body.** What changed and why — one line per notable item — plus the review verdict where the caller has one, and the test result where the caller ran tests.

**Trailer.** `Co-Authored-By: Claude <noreply@anthropic.com>`, plus `Work-Item:` where the folder supplies one. This diverges from `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §1 rule 6, which forbids the trailer, and follows `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §1 rule 6 instead, for the same reason: a bookkeeping file is plugin-generated, and code is authored.

`git -C "<repo>" commit -m …`. Never `--amend` (§1 rule 3): an amend rewrites a commit that may already be pushed, and this step is reachable more than once per run.

### 2.4 The consent choice

Asked **after** the commit, and presented verbatim — order, wording, and the `(Recommended)` marker are not the caller's to change:

    choices: ["Push the branch and open a pull request (Recommended)", "Push the branch only — no pull request", "Neither — the commit stays on this machine"]

There is deliberately no `Cancel`: the commit has already happened, so there is nothing left to cancel, and the third option *is* the decline. A caller that adds a fourth option implying the work can still be discarded is describing something this step cannot do.

**Asked once per run, then reused.** Record the answer as `code_handoff_choice` on the first call and reuse it for every later call in the same run without re-prompting. `/vuln` finishes one branch per CVE and `/upgrade` commits once per component; re-asking would turn a single decision into one per unit of work, which is how a prompt becomes something a user clicks through without reading.

### 2.5 Push

`git -C "<repo>" push -u origin <branch>`. Never force.

- **No `origin` remote** → there is nothing to push. Report it and go to §3.1's reporting; a purely local clone is a legitimate setup, not a failure.
- **Non-fast-forward rejection** → reported, never resolved by rebasing, resetting, or forcing. The branch is the run's own, so this means somebody else pushed to it; that is a human's call.
- **A failed push never undoes the commit and never starts a retry loop.** The commit is the durable half and it survives every push failure — which is the whole reason §1 rule 5 puts it first.

### 2.6 Open the pull request

Mechanics and rationale are `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.6's, unchanged — a **capability probe, not a host classification**, because push authority and pull-request authority are independent and no hostname test can detect the mismatch. Only the repository and the base differ:

    OWNER_REPO=$(git -C "<repo>" remote get-url origin \
      | sed -E 's#^(git@[^:]+:|https://[^/]+/)##; s#\.git$##')

    gh pr create -R "$OWNER_REPO" --base <default> --head <branch> \
                 --title "<title>" --body-file <body-path> [--draft]

`--draft` is added when `clean_finish: false` (§2.8). Every argument that would otherwise make `gh` prompt is supplied — the plugin must never block on an interactive editor. Run the cheap `gh auth status` pre-check first, purely so a missing login reports as a login problem rather than a raw `gh` error.

On **any** failure — `gh` absent, not authenticated, no API permission, a host with no CLI that can open one — fall back to §3.2's text. Choose that text's wording by classifying the remote per `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §4: host classification is right for picking *instructions* and insufficient for deciding whether to try, which is exactly the split those two sections describe.

`gh` wraps the API rather than calling it over HTTPS, which is what the zero-direct-API rule permits.

### 2.7 Resolving the base branch

In order, stopping at the first that succeeds — never assume `main`:

1. `git -C "<repo>" symbolic-ref --short refs/remotes/origin/HEAD` (strip the leading `origin/`)
2. `git -C "<repo>" rev-parse --verify --quiet origin/main`
3. `git -C "<repo>" rev-parse --verify --quiet origin/master`
4. `git -C "<repo>" rev-parse --verify --quiet origin/develop`

This is `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md` §3's ladder plus `develop`, which appears in the callers' own default-branch checks. An exhausted ladder means no pull request can be opened: report it through §3.1 and skip §2.6. `git remote set-head origin --auto` is not in the chain — it writes.

The same resolved value is what §2.1 compares HEAD against.

### 2.8 A run that did not end clean

`clean_finish: false` when the caller reports any of:

- an Opus review verdict still `BLOCK` after its single allowed fix cycle plus re-review;
- test regressions the user chose to keep rather than fix or revert;
- a unit of work the caller marked `BLOCKED` (a `/vuln` CVE, an `/upgrade` component).

**Commit and push run exactly as they would on a clean finish.** Unreviewed work that exists is recoverable; work that was never committed is not, and a failed gate is the case where losing it hurts most. What changes is only the pull request:

- opened with `--draft`, so it cannot be merged by reflex;
- its body's **first line** is the banner `> ⚠ DO NOT MERGE — <the blocking fact>.`, mirroring `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §5's banner for the same purpose;
- where §2.6 fell back, §3.2's text carries that banner as its own first line, so the user pastes it into the web UI rather than losing it.

### 2.9 Failure discipline

Never fatal (§1 rule 4). Every failure is reported in §3.1's line, and no report may imply a step succeeded that did not. In particular: "committed" and "pushed" are separate claims, and a run that committed but could not push says both.

### 2.10 Caller-supplied inputs

| Input | Meaning |
|---|---|
| `repo` | absolute path of the code repository |
| `branch` | the branch the caller created or adopted |
| `pre_existing_dirty` | porcelain paths dirty before the run's first edit, or `null` |
| `stash_ref` | the stash the caller pushed at branch time, or `null` |
| `key` | the resolved folder's `key` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4), or `null` |
| `workitem_key` | the resolved folder's `workitem_key`, or `null` |
| `title` | the commit subject and pull-request title |
| `body_facts` | what §2.3 and §2.6 render |
| `clean_finish` | `true` / `false` per §2.8 |
| `commit_template` | the caller's own message template, or `null` |

### 2.11 Splitting the call across a loop

A caller whose work arrives in units — `/upgrade`'s per-component loop, `/vuln`'s per-CVE loop — may run **§2.2–§2.3 alone** at the end of each unit and the **full entry point once** at the end of the run. The unit-level call commits and stops; the terminal call finds nothing left to stage, takes §2.2's `nothing staged` path, and continues into §2.4's choice and §2.5–§2.6 because the branch carries commits to push. That is why §2.2's `nothing staged` rule ends at §2.4 rather than returning.

The split is what makes per-unit committing worth having: a batch that dies on component three still has one and two committed, each with its own message, on a branch that bisects. Both halves are required — a caller that runs the unit-level half and never reaches the terminal call has committed the work and left it on the machine, which is only half the fix.

Where the units each get **their own branch** (`/vuln`, one branch per CVE) there is no split: each CVE runs the full entry point, and §2.4's once-per-run caching is what keeps that from asking N times.

---

## 3. Reporting

### 3.1 Outcome line

Exactly one per **full** call, prefixed `Code repo:`. A caller that finishes several branches in one run (a `/vuln` CVE loop) emits one line per branch. A §2.11 split call emits none — §2.2–§2.3 have no outcome line of their own, so an `/upgrade` batch of six components emits one line, not seven; each component's commit is reported in that command's own results table instead.

| Case | Line |
|---|---|
| Committed, pushed, PR opened | `Code repo: <sha7> on <branch> — pushed, PR #<n> open (<url>).` |
| Committed, pushed, draft PR | `Code repo: <sha7> on <branch> — pushed, DRAFT PR #<n> open (<url>) — <blocking fact>.` |
| Committed, pushed, no PR asked | `Code repo: <sha7> on <branch> — pushed. No pull request opened (not requested).` |
| Committed, pushed, PR not opened | `Code repo: <sha7> on <branch> — pushed, PR NOT opened (<reason>). Open it manually.` |
| Committed, push failed | `Code repo: <sha7> on <branch> — push FAILED (<reason>). The work IS committed locally.` |
| Committed, push declined | `Code repo: <sha7> on <branch> — not pushed at your request.` |
| Committed, no remote | `Code repo: <sha7> on <branch> — no origin remote, nothing to push.` |
| Nothing to commit, nothing to push | `Code repo: no changes to commit on <branch>.` |
| Nothing new to commit, earlier commits pushed | `Code repo: <n> commit(s) on <branch> — pushed, PR #<n> open (<url>).` |
| Gate failed | `Code repo: NOT committed — <reason>. Your changes are still in the working tree.` |
| Skipped under `--no-commit` | `Code repo: not committed — --no-commit. Your changes are in the working tree on <branch>.` |
| A stash is outstanding | append `; a stash from this run's branch step is still on the stack (<stash_ref>).` |
| Only part of the tree staged | append `; <n> pre-existing dirty path(s) were left uncommitted at your request.` |

The `push FAILED` line states the surviving commit explicitly. A user reading "FAILED" needs to know in the same sentence that their work is not gone.

### 3.2 The no-`gh` fallback text

    The branch is pushed but no pull request was opened (<reason>).
    Open one from <branch> into <default> in the web UI, using this title:
      <title>
    The body is at <body-path>.

For a GitHub remote where `gh` is merely absent, append the command the user may run once it is installed:

    gh pr create -R <OWNER_REPO> --base <default> --head <branch> \
      --title "<title>" --body-file <body-path>

On a `clean_finish: false` run the `> ⚠ DO NOT MERGE — <the blocking fact>.` banner is the **first** line of this text, above everything else (§2.8).

---

## 4. Caller contract

Four obligations. Omitting any one is a defect, not a style choice.

1. **Call it after the last in-repo write, not before.** Post-implementation maintenance edits files inside the repo; a call placed ahead of them commits a partial run.
2. **Record `pre_existing_dirty` and `stash_ref` at branch time.** A caller that does not cannot honour §2.2's first two carve-outs, and will either sweep up somebody else's work or forget a stash.
3. **Emit §3.1's line exactly once per call**, in the run's own report.
4. **Never restate this reference's rules** — cite the section number. A rule copied into a command is a rule that goes stale.

## 5. What this entry point never does

- Never touches `$SPECS_PATH` — that repository belongs to `specs-repo-git.md` (bookkeeping) and `phase-handoff.md` (deliverables) — and never touches a docs repo, which belongs to `finish-and-handoff.md`. `$DOCS_PATH` is a read-only grounding base and is nobody's to commit.
- Never merges a pull request, and never approves one.
- Never calls a REST API over HTTPS. `git push` is git-protocol; `gh` wraps the API (§2.6).
- Never writes a file into the repository it is committing. Everything it needs — the pull-request body included — is written outside the tree.

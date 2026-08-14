# Phase handoff — Shared Reference

Single source of truth for the two entry points that move a **phase deliverable** into `$SPECS_PATH`'s default branch and that refuse to start a phase whose input never got there: `handoff-to-main` (§2, producer) and `require-on-main` (§3, consumer).

**The principle.** A workflow phase is not finished until its artifact is on the default branch. A command that ends a phase commits, pushes, and opens a pull request. The command that starts the next phase does not run until the previous artifact is there. The gate applies even when the role does not change — it may be a different human of the same role, and even the same human should have to confirm the previous phase is done.

**Relationship to `specs-repo-git.md`.** That reference owns the *bookkeeping* paths (its §2.1) and the run-start/terminal steps for them. This one owns *deliverables*. It inherits four of that file's hard rules and deliberately differs on three; §1 states which.

## 1. Hard rules

Inherited from `specs-repo-git.md`, unchanged:

1. **`git -C` always; `cd` never.** Every invocation is `git -C "$SPECS_PATH" …`. Most callers are running inside a *different* repository; a `cd` would corrupt their git state. The `gh` calls in §2.6 and §3.5 name the repository with `-R` for the same reason.
2. **Bounded paths.** Only the calling command's own declared deliverable paths are staged, by enumeration (§2.3). `git add -A` is never issued at repository scope.
3. **Bounded branches.** Only branches matching `^(idea|vi|ard|spec|design|ready)/` are the plugin's (`specs-repo-git.md` §2.2).
4. **Never destructive.** No `push --force`, no `push -f`, no `branch -D`, no `merge`, no `rebase`, no `reset`, no `stash`, no `checkout --`, and never delete an `index.lock`.

Where this reference **differs** — each difference is deliberate, and a reader who "corrects" one to match `specs-repo-git.md` breaks this contract:

5. **`require-on-main` is fatal by design.** `specs-repo-git.md` §1 rule 5 is "never fatal", which is right for bookkeeping. A gate that reports and continues is not a gate. `handoff-to-main` is *not* fatal — the deliverable is already written — but it must report the phase as **not handed off**.
6. **The `Co-Authored-By` trailer IS carried.** `specs-repo-git.md` §1 rule 6 forbids it because bookkeeping files are plugin-generated. A deliverable is authored content, and the existing handoff phases already carry the trailer.
7. **`handoff-to-main` runs only behind a user choice.** `specs-repo-git.md` §1 rule 7 is "prompt-free". Opening a pull request is outward-facing, so it is never reached except through the calling command's consent choice (§4.3).

## 2. `handoff-to-main` — the producer entry point

Called from a producing command's Handoff phase, and **only** when the user picked the branch-and-PR choice of §4.3.

### 2.1 Gate

All of: `$SPECS_PATH` is set and is an existing directory; `git -C "$SPECS_PATH" rev-parse --git-dir` succeeds; the resolved `.git` directory is **writable**; and the run does not carry `specs_git: blocked` (`specs-repo-git.md` §3.3 G0 — a commit on a detached HEAD is reachable from no ref).

Gate fails on path / repo / permission grounds → report that the deliverable is written but not handed off, and stop. Gate fails on `specs_git: blocked` → re-emit that notice. **Never silent** — unlike the bookkeeping steps, silence here would hide the fact that the phase did not complete.

### 2.2 Branch resolution, and the collision rule

Intended name: `<prefix>/<KEY>-<slug>`, where `<prefix>` is the caller's own (§2.9) and `<KEY>-<slug>` come from **the resolved feature folder the deliverable was written into** — never re-derived from the Jira title. Folder resolution already tolerates a human-adjusted slug and a stray `-`/`_` after the key, and re-deriving would produce a branch name that disagrees with the directory it commits.

Collision is normal, not exceptional: `_readiness.md` is overwritten on every `/ready` run, and a `/create-vi` re-run after its pull request merged wants the same name again. `gh pr create` fails on an already-merged branch, and force-pushing and `branch -D` are both forbidden (§1 rule 4). So:

1. Test both `git -C "$SPECS_PATH" rev-parse --verify --quiet refs/heads/<name>` and `… refs/remotes/origin/<name>`.
2. Neither exists → use `<name>`.
3. One exists **and** it is this run's own in-progress branch — its prefix is the caller's, its key is in the run key set (`specs-repo-git.md` §3.2), and `git -C "$SPECS_PATH" merge-base --is-ancestor refs/remotes/origin/<name> refs/remotes/origin/<default>` fails (not yet merged) → **reuse it**, switching to it rather than creating it.
4. Otherwise → append the lowest free integer suffix, starting at `-2`, retesting both refs each time. Report the substitution in the §4.1 outcome line, because a branch name the user did not expect is a branch name they will not find.

### 2.3 Staging the deliverable

Staging is by enumeration, never by glob — the same discipline as `specs-repo-git.md` §2.1, applied to a different path set:

1. `git -C "$SPECS_PATH" status --porcelain --untracked-files=all`. `--untracked-files=all` is **required**: the default collapses an untracked directory to a single `?? dir/` line, hiding which files are staged.
2. Classify each reported path against the caller's declared deliverable paths (§2.9). Everything else is **OTHER** and is never staged — including the `dev-workflows/**` bookkeeping paths, which belong to `commit-artifacts`.
3. `git -C "$SPECS_PATH" add -A -- <path> [<path>…]` with the literal paths. `-A` is required: a producer may delete a file it relocated (`/idea` moves `idea.md` out of the vault; `/update-vi` supersedes a revision), and plain `git add` would not stage the deletion.

Nothing staged → no commit. Emit the §4.1 `nothing to commit` line. This is not an error: a re-run that changed nothing is a legitimate outcome.

### 2.4 Commit

Message `<KEY> <summary>`, matching the specs repo's own `<KEY|NOISSUE> <summary>` convention. Carry `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` (§1 rule 6).

### 2.5 Push

`git -C "$SPECS_PATH" push -u origin <branch>`. Never force. A non-fast-forward rejection is reported, never resolved by rebasing or forcing mid-run.

### 2.6 Open the pull request

Derive the repository, then call `gh` with every argument that would otherwise make it prompt — the plugin must never block on an interactive editor:

    OWNER_REPO=$(git -C "$SPECS_PATH" remote get-url origin \
      | sed -E 's#^(git@[^:]+:|https://[^/]+/)##; s#\.git$##')

    gh pr create -R "$OWNER_REPO" --base <default> --head <branch> \
                 --title "<title>" --body-file <body-path>

**Capability probe, not host classification.** Try the call; on any failure fall back to §4.2's instruction. Push authority and pull-request authority are independent — push runs over SSH with a per-repo key, `gh` runs over the API with a token, and the same account can have write access to one repository and read access to another. No hostname or host-type test can detect that mismatch, so a run can push successfully and still be unable to open the pull request. This is why `finish-and-handoff.md` §4's host classification is right for choosing *instructions* and insufficient here.

`gh` wraps the API rather than calling it over HTTPS, which is what the zero-direct-API rule permits — the same allowance `/document` already relies on.

### 2.7 Title and body

Title: the commit subject of §2.4.

Body: written to a file (never passed inline, which would break on newlines and quoting) containing what the phase produced; the artifact paths; the reviewer verdict where the caller has one; the count of open questions or `[NEEDS CLARIFICATION]` markers; and the next command in the chain together with the fact that it will not run until this pull request is merged.

### 2.8 Failure discipline

Every failure is reported and the phase is described as **not handed off**. The run is not retroactively failed — the deliverable is written and intact — but no report may imply the handoff succeeded. The next phase's gate is what enforces the consequence.

### 2.9 Caller-supplied inputs

| Input | Meaning |
|---|---|
| `prefix` | one of `idea`, `vi`, `ard`, `spec`, `design`, `ready` |
| `feature_folder` | the resolved directory the deliverable was written into |
| `deliverable_paths` | the literal repo-relative paths this phase authored |
| `title` | the commit subject and pull-request title |
| `body_facts` | what §2.7 renders |

<!-- Task 2 inserts §3 here -->

## 4. Reporting

### 4.1 `handoff-to-main` outcome line

Exactly one, prefixed `Phase handoff:`.

| Case | Line |
|---|---|
| Committed, pushed, PR opened | `Phase handoff: <branch> pushed — PR #<n> open (<url>). The next phase runs once it is merged.` |
| PR not opened | `Phase handoff: <branch> pushed — PR NOT opened (<reason>). Open it manually; the next phase will stop until it is merged.` |
| Push failed | `Phase handoff: committed <sha7> on <branch> — push FAILED (<reason>). The phase is NOT handed off.` |
| Nothing to commit | `Phase handoff: no deliverable changes to commit on <branch>` |
| Branch name substituted | append `; branch name <intended> was taken, used <actual>` |
| Declined by the user | `Phase handoff: skipped at your request — <artifact> is written but not on <default>; the next phase will stop until it is.` |
| Gate failed | `Phase handoff: NOT handed off — <reason>` |

### 4.2 The no-`gh` fallback text

    The branch is pushed but no pull request was opened (<reason>).
    Open one from <branch> into <default> in the web UI, using this title:
      <title>
    The body is at <body-path>.
    Until it is merged, the next phase will stop.

### 4.3 The consent choice

Every producing command presents this array verbatim — order, wording, and the `(Recommended)` marker are not the caller's to change:

    choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]

The second option's parenthetical is load-bearing: it is the only place the user learns that declining has a downstream cost.

### 4.4 Stop contract

Every `require-on-main` stop carries the same four parts as `specs-repo-git.md` §5, in this order: what was found (the concrete state — the path, the branch, the pull-request number); what the plugin did **not** do, stated as the consequence; the exact commands to resolve it with `$SPECS_PATH` already substituted; and one clause on what happens if it is ignored.

## 5. Caller contract

Four obligations. Omitting any one is a defect, not a style choice.

1. A command that **produces** a `$SPECS_PATH` deliverable cites and executes `handoff-to-main` (§2) in its Handoff phase, behind §4.3's choice, and emits the §4.1 line exactly once.
2. A command that **consumes** one cites and executes `require-on-main` (§3) in its Phase 0 — before its first subagent dispatch, code scan, docs-grounding retrieval, or grill question. A gate that fires after a scan has already spent what it was meant to save.
3. A consumer acts on the returned state, and on `absent` applies its own pre-existing behaviour (§3.4). **No consumer turns an optional input into a prerequisite.**
4. **Never restate this reference's rules** — cite the section number. A rule copied into a command is a rule that goes stale.

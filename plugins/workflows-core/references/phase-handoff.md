# Phase handoff — Shared Reference

Single source of truth for the two entry points that move a **phase deliverable** into `$SPECS_PATH`'s default branch and that refuse to start a phase whose input never got there: `handoff-to-main` (§2, producer) and `require-on-main` (§3, consumer).

**The principle.** A workflow phase is not finished until its artifact is on the default branch. A command that ends a phase commits, pushes, and opens a pull request. The command that starts the next phase does not run until the previous artifact is there. The gate applies even when the role does not change — it may be a different human of the same role, and even the same human should have to confirm the previous phase is done.

**Relationship to `specs-repo-git.md`.** That reference owns the *bookkeeping* paths (its §2.1) and the run-start/terminal steps for them. This one owns *deliverables*. It inherits four of that file's hard rules and deliberately differs on three; §1 states which.

**Relationship to `code-handoff.md`.** That reference is this one's counterpart in the **code** repo: same shape (gate, stage, commit, push, `gh` probe, outcome line), different repository, and two deliberate inversions. The first is staging scope: §2.2 there stages at **repository** scope, which §1 rule 2 here and in `specs-repo-git.md` both forbid — sanctioned there because that run branched off a verified-clean tree and the whole diff *is* the deliverable, and a reader who carries it back into either sibling breaks theirs. The second is the prompt: its commit is prompt-free, because a deliverable is already safe on disk when this file's §4.3 choice is asked and a code change is not. Neither file's entry points ever run against the other's repository.

## 1. Hard rules

Inherited from `specs-repo-git.md`, unchanged:

1. **`git -C` always; `cd` never.** Every invocation is `git -C "$SPECS_PATH" …`. Most callers are running inside a *different* repository; a `cd` would corrupt their git state. The `gh` calls in §2.6 and §3.5 name the repository with `-R` for the same reason.
2. **Bounded paths.** Only the calling command's own declared deliverable paths are staged, by enumeration (§2.3). `git add -A` is never issued at repository scope.
3. **Bounded branches.** Only branches matching `^(idea|prd|ard|spec|design|ready|brd|frames)/` are the plugin's (`specs-repo-git.md` §2.2).
4. **Never destructive — and this one is WIDER than the rule it inherits, deliberately.** `specs-repo-git.md` §1 rule 4 forbids `push --force`, `push -f`, `branch -D`, `merge`, `rebase`, `reset`, and deleting an `index.lock`. This rule adds **`stash`** and **`checkout --`**, because a deliverable commit runs where the user's own work may be uncommitted and both of those discard it silently. Same repository, two rules — so the addition is declared here rather than left for a reader to notice. No `push --force`, no `push -f`, no `branch -D`, no `merge`, no `rebase`, no `reset`, no `stash`, no `checkout --`, and never delete an `index.lock`.

Where this reference **differs** — each difference is deliberate, and a reader who "corrects" one to match `specs-repo-git.md` breaks this contract:

5. **`require-on-main` is fatal by design.** `specs-repo-git.md` §1 rule 5 is "never fatal", which is right for bookkeeping. A gate that reports and continues is not a gate. `handoff-to-main` is *not* fatal — the deliverable is already written — but it must report the phase as **not handed off**.
6. **The `Co-Authored-By` trailer IS carried.** `specs-repo-git.md` §1 rule 6 forbids it because bookkeeping files are plugin-generated. A deliverable is authored content, and the existing handoff phases already carry the trailer.
7. **`handoff-to-main` runs only behind a user choice.** `specs-repo-git.md` §1 rule 7 is "prompt-free". Opening a pull request is outward-facing, so it is never reached except through the calling command's consent choice (§4.3).

## 2. `handoff-to-main` — the producer entry point

Called from a producing command's Handoff phase, and **only** when the user picked the branch-and-PR choice of §4.3.

### 2.1 Gate

All of: `$SPECS_PATH` is set and is an existing directory; `git -C "$SPECS_PATH" rev-parse --git-dir` succeeds; the resolved `.git` directory is **writable**; and the run does not carry `specs_git: blocked` (`specs-repo-git.md` §3.3 G0 — a commit on a detached HEAD is reachable from no ref).

Gate fails on path / repo / permission grounds → report that the deliverable is written but not handed off, and stop. Gate fails on `specs_git: blocked` → re-emit that notice. **Never silent** — unlike the bookkeeping steps, silence here would hide the fact that the phase did not complete.

**Then probe for a push target — and do not gate on it.** `git -C "$SPECS_PATH" remote get-url origin`: exit 0 with a non-empty URL sets `remote: origin`, anything else sets `remote: none`. A specs repo with no `origin` is an ordinary state (a tree kept locally, a clone whose remote was removed), and it is deliberately **not** a gate failure: branching and committing there still does the useful half of this entry point, and a deliverable is safer on a local commit than in a working tree. What `remote: none` removes is §2.5's push and §2.6's pull request — both are skipped — so the run says so **before** the choice is presented (§4.3's notice) and reports it afterwards through §4.1's *No remote* row.

**The probe is `origin` specifically, because every later step names `origin` literally** — §2.2's `refs/remotes/origin/<name>`, §2.5's `push -u origin`, §2.6's `OWNER_REPO` derivation, and §3.2's `origin/<default>`. A repository whose only remote is under some other name is therefore `remote: none` for this entry point. **Probing is not optional and no earlier step stands in for it:** §2.1's four existing conditions are all satisfiable on a repository with no remote at all, so without this probe the producer offers — marked `(Recommended)` — a *"push + open PR"* option that cannot succeed, and the operator learns it only from the raw `git push` error §2.5 reports. That is the state this probe was added for, observed live.

### 2.2 Branch resolution, and the collision rule

Intended name: `<prefix>/<KEY>-<slug>`, where `<prefix>` is the caller's own (§2.9) and `<KEY>-<slug>` come from **the resolved feature folder the deliverable was written into** — never re-derived from the item title. Folder resolution already tolerates a human-adjusted slug and a stray `-`/`_` after the key, and re-deriving would produce a branch name that disagrees with the directory it commits.

Collision is normal, not exceptional: `_readiness.md` is overwritten on every `/ready` run, and a `/create-prd` re-run after its pull request merged wants the same name again. `gh pr create` fails on an already-merged branch, and force-pushing and `branch -D` are both forbidden (§1 rule 4). So:

1. Test both `git -C "$SPECS_PATH" rev-parse --verify --quiet refs/heads/<name>` and `… refs/remotes/origin/<name>`.
2. Neither exists → use `<name>`.
3. **At least one exists** (the local ref, the remote ref, or — the common reuse case — both) **and** it is this run's own in-progress branch — its prefix is the caller's, `specs-repo-git.md` §3.5's `branch-key` resolves it to a key in the run key set (§3.2 there — the same resolution the preflight's B3 makes, so a branch the preflight stayed on is a branch this rule reuses), and the branch is **not already merged** → **reuse it**, switching to it rather than creating it.

   **Test the merge against a ref that still exists, and read a missing ref as merged.** Resolve the branch ref first — `refs/remotes/origin/<name>` when it exists, else `refs/heads/<name>` — and run `git -C "$SPECS_PATH" merge-base --is-ancestor <that ref> <default-ref> 2>/dev/null`: exit 0 = merged (do not reuse; fall to rule 4 and create a fresh name), non-zero = not yet merged (reuse). The `2>/dev/null` is required for the same reason §3.2 gives for its own probe — on a missing ref git writes `fatal: Not a valid object name`, which must not leak into the run's output.

   **Why the remote ref alone is not enough:** with GitHub's *delete branch on merge* — the ordinary configuration — a merged branch's **remote** ref is gone while the **local** one survives. Probing only `refs/remotes/origin/<name>` then exits 128, which reads as "not yet merged", so the run switches onto a merged branch and calls `gh pr create` — the failure this section's own premise names ("`gh pr create` fails on an already-merged branch"). `specs-repo-git.md`'s B2 asks the same question against a ref that exists, and the two must not disagree about which ref to test.
4. Otherwise → append the lowest free integer suffix, starting at `-2`, retesting both refs each time. Report the substitution in the §4.1 outcome line, because a branch name the user did not expect is a branch name they will not find.

### 2.3 Staging the deliverable

Staging is by enumeration, never by glob — the same discipline as `specs-repo-git.md` §2.1, applied to a different path set:

1. `git -C "$SPECS_PATH" status --porcelain --untracked-files=all`. `--untracked-files=all` is **required**: the default collapses an untracked directory to a single `?? dir/` line, hiding which files are staged.
2. Classify each reported path against the caller's declared deliverable paths (§2.9). Everything else is **OTHER** and is never staged — including the `dev-workflows/**` bookkeeping paths, which belong to `commit-artifacts`.
3. `git -C "$SPECS_PATH" add -A -- <path> [<path>…]` with the literal paths. `-A` is used deliberately: a producer may delete a file it relocated (`/update-prd` supersedes a revision), and that deletion must be staged. `-A` states the intent explicitly and was strictly required before git 2.0; on git ≥ 2.0 a plain `git add -- <path>` stages a deletion for a literal path too — verified empirically — so keep `-A`, but do not justify it by claiming plain `git add` cannot stage the deletion.

**A declared path is always a file, never a directory and never a glob.** Step 2 classifies each
reported path against the declaration, so a directory in the list would leave every file under it
ambiguous — matched by a reader who expands it, OTHER by one who does not. A caller whose phase writes
a set of files rather than one (`/idea` vendors its sources into `attachments/` and
`design/<frame-set>/` — `product-workflows:idea-format`, *Vendored sources*;
`/frames` writes one `index.md` per `design/*/` set of the folder it resolved —
`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.2) enumerates every one of them literally. The consequence of leaving one out is silent and total: it is
classified OTHER, never staged, and never reaches the default branch, while the deliverable that links
it lands there pointing at a path on no ref.

Nothing staged → no commit. Emit the §4.1 `nothing to commit` line. This is not an error: a re-run that changed nothing is a legitimate outcome.

### 2.4 Commit

Message `<KEY> <summary>`, matching the specs repo's own `<KEY|NOISSUE> <summary>` convention. Carry `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` (§1 rule 6).

### 2.5 Push

`git -C "$SPECS_PATH" push -u origin <branch>`. Never force. A non-fast-forward rejection is reported, never resolved by rebasing or forcing mid-run.

**Skipped entirely where §2.1 set `remote: none`**, and §2.6 is skipped with it — a pull request needs a pushed head. The commit §2.4 made still stands; §4.1's *No remote* row reports it, and the phase is described as **not handed off** exactly as §2.8 requires of every other way the push can fail to land.

### 2.6 Open the pull request

Not reached where §2.1 set `remote: none` — §2.5 pushed nothing, and `gh` has no head branch to open a pull request from.

**First, probe for an existing pull request** — this entry point's §2.2 rule 3 deliberately *reuses* an in-progress branch, and §2.2 says in as many words that collision is normal rather than exceptional, so a branch that already carries a pull request is the ordinary case here:

    gh pr list -R "$OWNER_REPO" --head <branch> --state open --json number,url

One already open ⇒ §2.5's push has already updated it. Report it through §4.1's *already existed* row and do **not** call `gh pr create`, which fails on the duplicate and would send the run down §4.2 telling the user to open a pull request that exists. This is the same primitive §3.5 already uses on the consumer side.

Otherwise: derive the repository, run a cheap `gh auth status` pre-check purely to avoid a confusing raw error, then call `gh` with every argument that would otherwise make it prompt — the plugin must never block on an interactive editor:

    url=$(git -C "$SPECS_PATH" remote get-url origin)
    host=$(printf '%s' "$url" | sed -E 's#^[a-zA-Z][a-zA-Z0-9+.-]*://##; s#^[^/@]+@##; s#[:/].*$##')
    slug=$(printf '%s' "$url" | sed -E 's#^[a-zA-Z][a-zA-Z0-9+.-]*://##; s#^[^/@]+@##; s#^[^/:]+(:[0-9]+)?[/:]##; s#/+$##; s#\.git$##')
    case "$host" in github.com) OWNER_REPO="$slug" ;; *) OWNER_REPO="$host/$slug" ;; esac

    gh pr create -R "$OWNER_REPO" --base <default> --head <branch> \
                 --title "<title>" --body-file <body-path>

**The host is kept, not stripped** — the same rule as `dev-workflows:code-handoff` §2.6, and for the same reason. `gh -R` accepts `[HOST/]OWNER/REPO`, and `gh auth status` succeeds whenever the user is authenticated to *any* host, so a bare `OWNER/REPO` derived from a GitHub Enterprise remote resolves against **github.com** — silently opening the phase's pull request on an unrelated public repository if one happens to sit at that path, with the capability probe catching nothing because the call succeeded. Only `github.com` may drop the host. Validate the slug against `^[^/]+/[^/]+$` before calling `gh`; anything else (a Bitbucket `scm/proj/repo`, a nested GitLab group) is not a `gh` target — skip to §4.2. §3.5's `gh pr list -R "$OWNER_REPO"` uses the same value and mistargets identically without this.


The expressions strip a scheme, a `user@`, and a host with an optional `:port` terminated by `/` or `:` (the scp-like `git@host:Org/repo` form uses a colon), then a trailing slash and `.git`. The earlier two-expression form handled only `git@host:` and `https://host/`, and passed an `ssh://git@host/Org/repo.git` remote through unchanged — `gh` then failed on a repository argument that was a whole URL. Do not simplify it back.
**Capability probe, not host classification.** Try the call; on any failure fall back to §4.2's instruction. Push authority and pull-request authority are independent — push runs over SSH with a per-repo key, `gh` runs over the API with a token, and the same account can have write access to one repository and read access to another. No hostname or host-type test can detect that mismatch, so a run can push successfully and still be unable to open the pull request. This is why `docs-workflows:finish-and-handoff` §4's host classification is right for choosing *instructions* and insufficient here.

`gh` wraps the API rather than calling it over HTTPS, which is what the zero-direct-API rule permits — the same allowance `/document` already relies on.

### 2.7 Title and body

Title: the commit subject of §2.4.

Body: written to a file (never passed inline, which would break on newlines and quoting) containing what the phase produced; the artifact paths; the reviewer verdict where the caller has one; the count of open questions or `[NEEDS CLARIFICATION]` markers; and, **where the caller has one**, the next command in the chain together with the fact that it will not run until this pull request is merged — scoped exactly as the reviewer verdict beside it is, because a producer whose artifact has no §3.4 row has no next command to name and cannot render this sentence without inventing one.

### 2.8 Failure discipline

Every failure is reported and the phase is described as **not handed off**. The run is not retroactively failed — the deliverable is written and intact — but no report may imply the handoff succeeded. The next phase's gate is what enforces the consequence.

### 2.9 Caller-supplied inputs

| Input | Meaning |
|---|---|
| `prefix` | one of `idea`, `prd`, `ard`, `spec`, `design`, `ready`, `brd` (shared by every `/brd-*` command, the way `prd` is shared by `/create-prd` and `/update-prd`), `frames` |
| `feature_folder` | the resolved directory the deliverable was written into |
| `deliverable_paths` | the literal repo-relative paths this phase wrote — authored or copied in — one file each, never a directory (§2.3) |
| `title` | the commit subject and pull-request title |
| `body_facts` | what §2.7 renders |

## 3. `require-on-main` — the consumer entry point

Runs in the caller's Phase 0, immediately after `specs-preflight`, so it reuses that step's best-effort `fetch` (`specs-repo-git.md` §3.2) — no second network call.

### 3.1 Gate

`$SPECS_PATH` set, an existing directory, and `git -C "$SPECS_PATH" rev-parse --git-dir` succeeding. Unlike §2.1 the `.git` directory need **not** be writable — the gate only reads. A failed gate is a **silent skip** (state H): the artifacts are going to a tier the plugin does not manage, and there is nothing to verify.

### 3.2 Inputs and primitives

Inputs: the repo-relative `path` of the artifact, the `default` branch (`specs-repo-git.md` §3.2), the caller's own branch prefixes, and the run key set.

**`<default-ref>` is resolved by `specs-repo-git.md` §3.2**, which owns default-branch resolution and now also owns which ref represents it: `origin/<default>` where a remote is configured, the local `refs/heads/<default>` where none is. It is defined there rather than here because `specs-repo-git.md` is the reference this one extends, and two definitions of one ref is how they drift apart. The rationale — that with no remote there is no remote state to be uncertain about, so the local branch *is* the truth — is stated there in full. Row G below fires on the **resolved** ref, so a configured-but-unreadable remote still stops, which is its correct case.

The four primitives, each verified against a real specs repo:

- **The default-branch ref exists:** `git -C "$SPECS_PATH" rev-parse --verify --quiet "<default-ref>"` Exit 0 = the ref exists — run the next primitive. Non-zero = row G: nothing to verify against, stop. This runs **before** the next primitive, because that primitive's own required `2>/dev/null` discards the only signal that would otherwise distinguish "path absent on an existing ref" (row F) from "the ref itself does not exist" (row G) — `git cat-file -e` exits 128 for both, verified empirically: a missing path and a missing ref are indistinguishable by exit code alone.
- **On the default branch:** `git -C "$SPECS_PATH" cat-file -e "<default-ref>:<path>" 2>/dev/null` Exit 0 = present. The `2>/dev/null` is required — on absence git writes `fatal: path '<path>' does not exist in '<default-ref>'` to stderr, which must not leak into the run's output. Only reached once the ref-existence primitive above has already confirmed `<default-ref>` exists, so a non-zero exit here means the path is absent, never that the ref is.
- **Worktree matches the ref:** `git -C "$SPECS_PATH" diff --quiet "<default-ref>" -- "<path>"` Exit 0 = identical. This also catches a **staged-only** change, which a `hash-object` comparison against the working file would miss.
- **Plugin branches carrying the artifact:** `git -C "$SPECS_PATH" for-each-ref --format='%(refname:short)' refs/remotes/origin refs/heads` filtered to `(origin/)?(idea|prd|ard|spec|design|ready|brd|frames)/*`, then `git -C "$SPECS_PATH" cat-file -e "<ref>:<path>" 2>/dev/null` on each. **Local `refs/heads` are scanned as well as remote ones**, and for the same reason §2.2's branch resolution tests both: a deliverable that was committed but whose push failed (§2.5, reported by §4.1 as "NOT handed off") exists only on a local branch. Scanning remote refs alone would return `absent` for it — the one state §2.8 promises "the next phase's gate is what enforces the consequence" of. Prefer the remote ref when both carry the path, so rows D and E report the branch the pull request is open against. **Then strip a leading `origin/` and carry the bare branch name forward** — `%(refname:short)` of a remote ref is `origin/spec/PRD-2-y`, while the branch that exists on the host is `spec/PRD-2-y`. This is not cosmetic: §3.5 feeds this value to `gh pr list --head`, which filters by the head branch name **on the host** and matches nothing against an `origin/`-prefixed string, so leaving the prefix on made **row D unreachable in every repository state** — a pushed branch with an open pull request reported row E's "was never handed off", silently, with `gh` exiting 0. The bare name is also the only form the operator can act on. **This primitive is unaffected by which case `<default-ref>` resolved to** — it scans plugin-prefixed branches, a pattern the default branch itself never matches, whether or not the repo has a remote.

### 3.3 The state table

First matching row applies.

| # | On `<default-ref>` | Worktree | HEAD | Outcome |
|---|---|---|---|---|
| H | — | — | gate of §3.1 fails | **silent skip** — return `unmanaged`; the caller proceeds exactly as it did before this feature |
| I | — | — | run carries `specs_git: blocked` (detached HEAD), **or** HEAD is detached and no preflight set that flag | **stop**, re-emitting that notice where there is one. A phase cannot complete from a detached HEAD, so verifying one is meaningless |
| G | `<default-ref>` does not exist | — | any | **stop** — the plugin cannot verify what is on `<default>` |
| A | present | matches ref | any | **pass** |
| B | present | differs | a branch **this run itself created or reused during this run**: created earlier in the same invocation via this caller's own `handoff-to-main`, or reused because `specs-repo-git.md` §3.5 B3 kept the preflight checkout on it AND the branch is the caller's **own** — its prefix is this caller's and its key is in the run key set (`specs-repo-git.md` §3.2). The test is **branch ownership, not artifact authorship**: the load-bearing case is `/design` resumed on its own `design/<EPIC>-<eslug>` branch gating the `specification.md` that same branch amends, and `/design` is not that file's original author (`/specify` is). Requiring authorship would exclude the one case this row exists for and drop it into row C, whose repair offer re-grounds the session on the un-amended copy. Ownership is still never merely a prefix the caller is *capable of* producing for an unrelated purpose, such as `/implement`'s Phase 4.5 escalation handoff onto `spec`/`design` | **pass, reported** — `reading <path> from your in-progress <branch>, which amends the approved version on <default>` |
| C′ | present | differs | any other HEAD, **and** the tree is dirty in a way that would block the switch **or** the `pull --ff-only` that follows it | **stop**, naming the exact files |
| C″ | present | differs | HEAD **is** the default branch (so nothing to switch to), and the divergence is local — an uncommitted edit **or** a committed-but-unpushed one | **stop**, naming the files and saying the repair offer cannot help here |
| C | present | differs | any other HEAD | **repair offer**, then re-test once |
| D | not on ref | — | artifact found on a plugin ref, pull request open | **stop** — `<path> is on branch <branch> with PR #<n> open, not merged` |
| E | not on ref | — | found on a plugin ref, no open pull request | **stop** — `<path> is on branch <branch> and was never handed off` |
| F | not on ref | — | found on no ref | **delegate** — return `absent`; see §3.4 |

**`not on ref` describes the repository, not the return value.** Rows D, E, and F all read `not on ref` in the first column because none of the three has the artifact on `<default-ref>` — that column is a statement about the repository. It is row F alone that returns `absent` (§3.7), and D/E are stopping rows that never reach a caller's `absent` branch at all. A consumer that keys off this column instead of the returned `stopped` flag cannot tell D/E from F.

**Row order matters.** H, I, and G precede everything else because they are about the repository, not the artifact — and G, like H and I, must precede every row that keys on `not on ref` (D, E, F) and every row that tests the worktree against the ref at all (A, B, C′, C″, C): §3.2's ref-existence primitive runs before the on-ref-presence primitive, so a reader who has not first ruled out G cannot tell "path absent on an existing ref" (row F) from "the ref itself does not exist" (row G) — the defect `f5a9713` closed in §3.2 but this table, until now, never propagated to its own row order. **Both primitives run against the same resolved `<default-ref>`** (§3.2) — a remote-tracking ref when the specs repo has a remote, the local default branch when it does not — so ruling out G rules out the same absence for either case of that resolution, not only the remote-present one. C′ precedes C because offering a switch that git would refuse is worse than naming the blocker.

**Row B is load-bearing and must not be folded into C.** `/design` amends `specification.md` on its own branch, so on a resume the worktree copy legitimately differs from the default branch. Under row C the plugin would offer `switch to <default> + pull --ff-only` and **discard the in-progress design**. The distinguishing test is **branch ownership**, never whether the file differs.

**Row C's repair offer:**

    choices: ["Switch to <default> and pull --ff-only, then continue (Recommended)", "Cancel"]

**Row C″ exists because the offer above is a no-op on the branch you are already standing on.** Row B is scoped to a branch this run owns and row C′ requires a dirty state that would *block* a switch — so a user sitting on the default branch with an uncommitted edit to the gated artifact matched neither and fell to row C, which offered `git switch <default>` from `<default>` ("Already on 'main'") followed by a `git pull` that aborts on the unstaged change, then re-tested, failed, and stopped. The offer could never resolve it. Row C″ catches that state first and says so plainly instead of spending a prompt on it: the remedy is to commit, stash, or discard the local edit, and the stop names the files.

On the first choice: `git -C "$SPECS_PATH" switch <default>` then `git -C "$SPECS_PATH" pull --ff-only`, then re-test **once**. A second failure stops — never merge, rebase, or reset, and never loop.

**Three states the C-row family used to misclassify, each fixed above and recorded so the narrowing is not undone.**

- **A committed local divergence on the default branch (C″).** C″ once required the divergence to be an *uncommitted* edit, so a commit whose push failed — the state `specs-repo-git.md` §3.4's retry exists for — fell to row C. Row C's offer is `switch` + `pull --ff-only`, and on the default branch the switch reports *"Already on 'main'"* and the pull *"Already up to date."*, both exit 0: a repair that changes nothing, reports success, and then stops anyway. That is exactly the defect C″ was added to close, in the variant its wording excluded, and worse than the case it did cover — there the pull errored visibly.
- **Dirt that blocks the pull rather than the switch (C′).** C′ exists because "offering a switch that git would refuse is worse than naming the blocker", but row C's offer is a switch **and** a pull, and a dirty file that is identical on both branches blocks only the second: `git switch` succeeds and moves the user off their branch, then `pull --ff-only` aborts with *"Your local changes … would be overwritten"*. The user is left relocated by a repair that failed. C′ must therefore test both commands, not the first.
- **A detached HEAD on a read-only mount (I).** Row I keyed on the `specs_git: blocked` flag, whose only producer is `specs-preflight` — and §3.1 there requires a **writable** `.git`, which `require-on-main`'s own gate deliberately does not. On a read-only mount the preflight is a silent no-op, so the flag is never set, and a detached HEAD fell through to row C, whose offer is a write: `git switch` exits 128 with a raw `fatal: Unable to create '.git/index.lock': Permission denied`. Row I now tests the state as well as the flag.

### 3.4 Row F delegates — the gate never makes an optional input mandatory

Row F is the difference between "this phase was not handed off" and "this phase never happened". Only the second is row F **as the family produces it** — `handoff-to-main` always names a branch carrying one of §1 rule 3's eight prefixes, so any family command's run that handed off is found on a ref, whichever plugin ships it. **Read "the family", not "this plugin", everywhere in this paragraph**: the eight prefixes are shared across every plugin that calls these entry points, and the gate routinely runs across a plugin boundary — `/design` ships from `dev-workflows` and gates on a `specification.md` that `/specify` handed off from `product-workflows`. A row-F reading scoped to one plugin's own runs would put every cross-plugin handoff in it and stop the route at each boundary. A **person** working on their own branch is the third case: `specs-repo-git.md` G2 sanctions a run committing and pushing artifacts onto a non-plugin branch, and §3.2's scan is filtered to plugin prefixes, so that artifact is "found on no ref" and lands in row F too. Row F therefore means *not found on a branch these eight prefixes name*, which is not quite *never happened*; the gate has no opinion about either, which is why delegating rather than stopping is still right. **An input that was optional before this gate existed stays optional, and that must not change.** The gate returns `absent`; the caller does what it already does.

Several consumers map `absent` to a hard stop, and every one of them is legitimate for the same reason: their gated input was **never optional to begin with** — it is a new input, introduced together with the command that reads it, with no pre-existing "what it already did" to fall back to. The rule this section protects is that the gate must not *promote* an optional input into a prerequisite; it does not require a genuinely mandatory input to be made optional.

| Caller | Input | Pre-existing absent behaviour, preserved |
|---|---|---|
| `/create-prd <KEY>` | `idea.md` | continue down the Phase 0 idea ladder — prompt for a path, or grill the PRD from scratch. **`/idea` is not a prerequisite.** |
| `/create-ard` | the PRD | read the resolved folder's own contents — **reported** rather than silent |
| `/specify` | the PRD | the folder read is already the primary read path (the merged PRD is a grounding confirmation, not a new content source); on `absent` the confirmation is simply skipped — now **reported** rather than silent, the same shape as `/create-ard`'s row |
| `/specify` `/design` `/implement` `/epics` `/ready` | the ARD | `status: none` and the no-regression rule of `ard-resolution.md` |
| `/epics` | PRD-level `specification.md` | `vi_spec_present: false`, the existing silent skip |
| `/implement` | `specification.md` / `design.md` | only an **in-scope** spec is gated; a direct-prompt run resolves none |
| `/design` | `specification.md` | **stops** — but that stop already exists; this reference only makes its test correct |
| `/ready` | ARD / spec / design | records the artifact as missing in its coverage roll-up, as today |
| `/brd-ground` **(a slice)** | the BRD's `coverage-ledger.md` | **stops**, and **splits row F into two stops on a test this gate cannot make** — no `coverage-ledger.md` in the folder at all is *never produced*, which is `BRD_GROUND_NEEDS_SPLIT` for a slice or, for the legacy unprefixed folder that reads as an interrupted intake instead, `BRD_GROUND_NEEDS_INTAKE`; a ledger in the folder but on no ref is `BRD_GROUND_NOT_HANDED_OFF` (produced, handoff declined), whose action is to land the files already on disk, and which names `/brd-split` as a way out only where re-running it would in fact stage them — never on a **bare** re-run against a fully-allocated parent. Never optional either way: grounding has no claim list without the inventory this file arrives with, and the route ships with no pre-gate behaviour to fall back to |
| `/brd-split` **(`split_mode: allocate-only`)** | the BRD's `grounding/code-grounding.md` | **stops** — `BRD_SPLIT_NEEDS_GROUNDING`. Never optional: a BRD with no code findings at all has nothing to allocate against. This is one of that command's three Phase 0 step 7 tests, not the whole of its gate — the other two are a non-emptiness relation on this same file and the design row below |
| `/brd-ground` **(a slice)** | the BRD's `brd/brd-inventory.md` | **stops** — `BRD_GROUND_NO_INVENTORY` where no inventory is in the folder (naming the producer by level), `BRD_GROUND_INVENTORY_NOT_HANDED_OFF` where one is in the folder and on no ref. Row F is split on that test rather than borrowing step 8's `BRD_GROUND_EMPTY_INVENTORY`, which reports a content fact and whose remedy would rewrite an inventory that is merely unmerged. Never optional: the run's whole claim list comes from this file |
| `/brd-split` **(`split_mode: allocate-only`)** | the BRD's `grounding/design-grounding.md` — **only where `design/` holds at least one immediate subdirectory** | **stops** — `BRD_SPLIT_DESIGN_NOT_GROUND`. **The row is conditional, and the condition is what keeps it inside §5 rule 3.** A BRD with no exported frame set has no design grounding to require, so nothing is promoted for it; a BRD with frame sets on disk and nothing reconciling them is the state `/brd-split` shipped passing silently, and the repair is not a stricter count but a requirement that the artifact exist and be on main. Like rows D/E this is a real behaviour change, declared rather than smuggled: before it a slice could reach build with its designs never reconciled |
| `/brd-interview` **(a slice)** | the BRD's `grounding/code-grounding.md` | **stops** — `BRD_INTERVIEW_NEEDS_GROUNDING`. Never optional: every `[G]` is answered from the findings and from nothing else, so a BRD with none has no question this command may answer |
| `/brd-package` **(a slice)** | each `interview/round-<N>.md` **that `decisions.md` names in a `[VD#n]`'s or `[AS#n]`'s `round`** | **stops** — `BRD_PACKAGE_ROUND_UNSETTLED` on a round holding a deferred, needs-grounding or untagged question; `BRD_PACKAGE_ROUNDS_NOT_ON_MAIN` collecting every round that came back row F. **The set is derived from the register, not from the directory**, which is what makes a partial merge visible: enumerating `interview/` would find the rounds that landed and never learn a third was owed. Never optional — the package is assembled from what the rounds settled. It gates rather than inheriting step 6's implication, per §4.0 |
| `/brd-package` **(a slice)** | the BRD's `decisions.md` | **stops**, and **splits row F into two stops on a test this gate cannot make** — no `decisions.md` in the folder at all is `BRD_PACKAGE_NEEDS_INTERVIEW` (no interview ever ran); a register in the folder but on no ref is `BRD_PACKAGE_REGISTER_NOT_HANDED_OFF` (ran, handoff declined), which must **not** send the operator back to `/brd-interview`, whose no-new-round path stages nothing on an unchanged BRD. Never optional either way: the package is assembled from the register, and a BRD with none has nothing to put in front of a customer |
| `/brd-reconcile` **(a slice)** | the BRD's most recent `customer-review-prompt-<YYYYMMDD>.md` — **unless `--sent` was given**, which replaces this gate with operator-supplied sent material committed beside the review, for a review answering a package the route did not build | **stops**, and **splits row F into two stops on a test this gate cannot make** — no prompt in the folder at all is `BRD_RECONCILE_NEEDS_PACKAGE` (no package was ever built); a prompt in the folder but on no ref is `BRD_RECONCILE_PACKAGE_NOT_HANDED_OFF` (built, handoff declined), which must **not** send the operator back to `/brd-package`, since that command will not rewrite a dated bundle. Never optional either way: reconciling against a package that exists only in a working tree would freeze customer authority against a document nobody can produce later |

Four of these callers refuse a root outright: grounding and the customer interview happen at the slice. Their rows therefore describe a slice run, and a root never reaches the gate at all.

For the consumers that predate this gate, rows D and E add the only new stop: an artifact that **exists** and was never handed off. That state was **not** unreachable before this feature — pre-J, `/specify` already created `spec/<EPIC>-<eslug>` (or `spec/<PRD>-<vslug>`) branches and offered branch + PR, and `/create-prd` did the same on `prd/<KEY>-<slug>`, with no downstream gate reading them; an artifact sitting on such a branch, unmerged, was a common, ordinary state. This is a real behaviour change: for that state, `/create-ard`, `/specify`, and `/epics` now hard-stop where they previously proceeded with a documented fallback (the deliberate, well-argued stop in `epics.md`'s `/create-prd`-refusal table). It qualifies caller-contract rule 3 (§5 — no consumer turns an optional input into a prerequisite) precisely: for those consumers, row F's `absent` case is still fully delegated to the caller's own pre-existing behaviour, but rows D/E are a new stop for a state that was previously reachable and previously non-blocking. All five `/brd-*` consumers named in that qualification — `/brd-ground`, `/brd-split`, `/brd-interview`, `/brd-package` and `/brd-reconcile` (`/brd-intake` consumes nothing and runs no gate) — sit outside that qualification entirely: they have no pre-gate behaviour, because their inputs and the commands that read them shipped together, so rule 3 has no optional input to protect there.

### 3.5 Locating the branch and its pull request

For rows D and E, after §3.2's ref scan finds a carrying branch:

    gh pr list -R "$OWNER_REPO" --head <branch> --state open --json number,url

**Derive `$OWNER_REPO` first (§2.6), and skip this probe when the derivation does not validate.** §2.6's slug test (`^[^/]+/[^/]+$`) is what says whether this remote is a `gh` target at all; running the probe before it means calling `gh` with an unvalidated `-R`. `<branch>` is the bare name §3.2 carried forward, never `origin/`-prefixed. On `gh` failure, use **row E's** wording plus a note that the pull-request state could not be checked — never assert a pull request exists, and never assert one does not.

### 3.6 Degraded verification

- **Fetch failed** (offline, auth) → test against the last-known `origin/<default>` and say so, the precedent `specs-repo-git.md` §3.2 already sets: `offline — checked against the last-fetched ref`. This case presupposes a remote: with no remote configured there is nothing to fetch, so §3.2's resolution never enters it and `<default-ref>` is simply the current local branch.
- **Read-only specs mount** → `references/read-only-repos.md` applies: no `fetch`, use the existing ref, emit the degraded clause. **The read-only rows degrade in freshness only; the repair rows do not run at all.** Every classifying primitive in §3.2 is a read, so **ten of the eleven rows** — H, I, G, A, B, C′, C″, D, E, F — reach their verdict unchanged against a stale ref. C′ and I are in that set for the same reason as the rest: both are settled by reads (a `status --porcelain`, a `symbolic-ref`) and both stop, which is not a write. Row C's offer, though, is a `switch` and a `pull` — writes that `read-only-repos.md` forbids and that git refuses with a raw `fatal:` — so on a read-only mount row C **stops with its finding instead of offering the repair**, naming the mount as the reason. Saying only that freshness degrades was false for the one row that writes.
- **No `<default-ref>` at all** → row G, whichever case §3.2 resolved to — a missing `origin/<default>` where the specs repo has a remote, a missing local `<default>` branch where it does not. Nothing to verify against either way, and proceeding silently is the failure this reference exists to prevent.

### 3.7 Return value

    on_main: pass | pass_amending | absent | unmanaged
    stopped: true | false
    branch: <the carrying plugin branch, or null>
    pr: <number, or null>
    degraded: <the clause to print, or null>

`pass_amending` is row B. `absent` is row F and is the caller's to interpret per §3.4. `unmanaged` is row H. Every stopping row returns `stopped: true`, and every caller but one then stops.

**`/ready` is the sole exception, by design.** It is a read-only verifier whose entire function is to report, so a run that stops instead of reporting has failed at the one thing it exists to do. It records each stopping row as a readiness finding — capping the verdict at `PARTIAL` — and continues (`ready.md`'s frontmatter, and its `require-on-main` mapping step). `ard-resolution.md` carves `/ready` out of its own `status: unmerged` stop in exactly the same way and for exactly the same reason. No other caller may take this exception, and a caller that wants one adds it here first.

**`on_main` is defined only when `stopped: false`.** Its four values — `pass` (row A), `pass_amending` (row B), `absent` (row F), `unmanaged` (row H) — map to the four **non**-stopping rows, and the other **seven** (I, C′, C″, C, D, E, G) define none; are exhaustive for the non-stopping rows only. Every stopping row (I, C′, C, D, E, G) carries no defined `on_main` value; a caller has nothing to read there and must act on `stopped`/`branch`/`pr`/`degraded` instead.

**A caller tests `stopped` before `on_main`.** `on_main: absent` is returned only by row F; every stopping row (I, C′, C″, C, D, E, G — seven of the eleven) returns `stopped: true` regardless of what `on_main` reads. A caller that branches on `on_main == "absent"` before checking `stopped` cannot distinguish row F (never happened — §3.4 applies) from rows D/E (happened, but not handed off — the run must stop).

## 4. Reporting

### 4.0 The three downstream classes

`<downstream-clause>` (§4.1), `<next-phase-clause>` (§4.1) and the consent array (§4.3) all answer one question about the artifact the producer has just written — **what does not landing it cost?** — and all three must answer it the same way. There are **three** answers, not two:

| Class | The test | What declining costs |
|---|---|---|
| **gated** | a consumer runs `require-on-main` on it — §3.4's table has a row naming it | that consumer's own §3.4 behaviour: a stop for most rows, a delegated fallback for the rows that preserve one |
| **advisory** | no §3.4 row, **but** a command reads the artifact and never gates on it | nothing stops **because of the decline**. The reader reads the working copy, so it still sees this run's result — the artifact is unshared, not blocking. **"Nothing stops" is about the handoff, not about the file's contents**: a consumer may perfectly well refuse what it finds inside an advisory artifact (`/brd-ground` stops on a moved pin recorded in `grounding/baselines.md`; `/epics` on a `prd.md` stating no requirements), and that is a different question from whether the artifact reached the default branch |
| **unread** | no §3.4 row and no reader at all | nothing |

**What this table is, and what it is not.** It classifies every artifact the tree's `deliverable_paths` declarations name — derived from those declarations rather than from memory, which is the direction that had never been walked: the table carried twelve rows against roughly thirty declared paths, and most of the missing ones rode in a set that already held a gated path and were carried by the strongest-class rule, which is why their absence had cost nothing until `/brd-ground --no-code` produced the first set with no classified path in it at all. **Treat an unlisted path as unclassified rather than as unread**, name its reader, add its row, and only then pick the array. A producer adding a deliverable adds its row here in the same change.

The classes as the tree stands, each derived from the consumer rather than asserted here. **Verified against the tree, not carried forward:** the gated row is a two-way match with §3.4's Input column, and each advisory row was re-derived by opening the reader it names. That verification is what moved the frame-set index out of **unread**, where it had been asserted rather than derived — and where it had made `/frames` tell every operator that nothing downstream reads a file `/brd-ground` refuses a frame set without. **The gated half is mechanically checkable and the other two are not**, which is why this table is held by review: a §3.4 row is a row, but naming the reader of an ungated artifact is reading, and no script does it.

| Artifact | Class | Derivation |
|---|---|---|
| `idea.md`, the PRD, the ARD, `specification.md`, `design.md`, `grounding/code-grounding.md`, `decisions.md`, `customer-review-prompt-<YYYYMMDD>.md` | gated | each is named in a §3.4 row |
| `grounding/design-grounding.md` | gated | named in §3.4's conditional `/brd-split` row. **Conditionally gated is still gated for this table's purpose**: a producer cannot know whether the consuming BRD will have frame sets on disk when the consumer runs, so it takes the gated class and the array that goes with it. A class that varied per run would have the producer guessing at the consumer's future state |
| `_readiness.md` | advisory | `/implement` Phase 0.5 reads a co-located copy and surfaces a one-line advisory on a `NOT-SUPPORTED`/`PARTIAL` verdict, explicitly never blocking. §3.4 names no gate on it |
| `customer-sent-<YYYYMMDD>/`'s files | advisory | `/brd-reconcile` Phase 0 step 8 reads them on a `--sent` run, in place of the `bundle-<YYYYMMDD>/` manifest, so a returned quotation resolves against what was actually sent. §3.4 names no gate on them. **Handed off as one literal path per file, never as the directory** (§2.3) |
| `customer-review-<YYYYMMDD>.md` | advisory | `/brd-reconcile` reads the copy it canonicalised, and a later run of it reads one already on file for its overwrite-refusal test. Neither is a gate, and §3.4's `/brd-reconcile` row targets the *prompt*, not the review |
| `interview/round-<N>.md` | gated | `/brd-package` step 7 executes `require-on-main` on each before reading it, and stops on a round holding a deferred question |
| `brd/brd-inventory.md` **(a slice)** | gated | named in §3.4's `/brd-ground` row, itself level-qualified there (§3.4: "Four of these callers refuse a root outright... their rows therefore describe a slice run") — a root never reaches that gate, so it only ever reaches a slice's own copy. It was classed advisory for one commit, in the same change that gated it |
| `brd/brd-inventory.md` **(a root)** | advisory | `/brd-intake` writes it, and `/brd-split`'s own step 8 reads it directly in `split_mode: full` — a plain worktree read, never a `require-on-main` gate — and stops on what it finds there (`BRD_SPLIT_EMPTY_INVENTORY`). That stop is about the file's *contents*, the same way `/brd-ground` stopping on a moved pin in `grounding/baselines.md` is (§4.0's own advisory-class note); no gate on the handoff exists for it |
| `coverage-ledger.md` **(a slice)** | gated | named in §3.4's `/brd-ground` row, itself level-qualified there for the same reason as `brd/brd-inventory.md`'s row above — a root never reaches that gate |
| `coverage-ledger.md` **(a root)** | advisory | `/brd-intake` writes it, and `/brd-split`'s own step 8 reads it directly in `split_mode: full` — a plain worktree read, never a `require-on-main` gate — computing the no-op test from its disposition counts (`coverage-ledger-format.md` §3). No gate on the handoff exists for it either, and `/brd-intake`'s whole `deliverable_paths` set is therefore **advisory**, not gated: nothing else in it (`brd/source/*`, `brd/brd-defect-log.md`, the optional seeds) carries a §3.4 row, so no path lifts the set to `gated` |
| `brd-link.md`, `grounding/baselines.md`, `brd/source/*`, `brd/brd-defect-log.md`, `interview/customer-questions.md`, `self-review-<YYYYMMDD>.md`, `customer-delivery-note-<YYYYMMDD>.md`, `bundle-<YYYYMMDD>/`'s files (one literal path each, never the directory — §2.3, the same rule the `customer-sent-<YYYYMMDD>/` row states), `reconciliation-<YYYYMMDD>.md`, `prd-seed.md`, `ard-seed.md`, `spec-seed.md`, `/idea`'s vendored `attachments/*` and `design/idea-sources/*` | advisory | each is read by a named consumer and gated by none: `brd-link.md` by BRD-route detection in `/create-prd`, `/create-ard` and `/specify`, by `/epics` step 1a and by `/brd-split` step 5; `baselines.md` by `/brd-ground` Phase 3 on a re-run; the intake and package artifacts by `/brd-package` and `/brd-reconcile`; the three seeds by their one altitude consumer each; and `/idea`'s vendored `attachments/*` by `/create-prd` and the grill commands that read the folder's `idea.md` and follow its links, its `design/idea-sources/*` by `product-workflows:design-grounder` through the frame-set index row below |
| `slices.md` | advisory | `/brd-reconcile` **corrects it in place** (its correction table names `slices.md` explicitly) and its stale-cross-reference sweep scopes it by name; `/brd-package` and `product-workflows:bundle-packaging` §5 both name it among the working records they read. It was classed **unread** for one commit on a "no reader found" that had not looked |
| `/specify`'s `_session.md` / `_glossary.md` / rendered `.html`, `/design`'s `_design-session.md` / `_design-glossary.md`, `/update-prd`'s archived revision | unread | handed off, and no reader found for any of them. **Listed rather than omitted**: an artifact absent from this table is unclassified, and a producer that reads absence as "unread" is making the mistake the frame-set index row records — which is also how `slices.md` spent a commit in this row |
| a frame-set `index.md` | advisory | `product-workflows:design-grounder` **refuses to run** on a frame set holding no index, and `product-workflows:grounding-verifier` returns `NO_INDEX`/`STALE_INDEX` on one — both dispatched by `/brd-ground` Phase 5 and Phase 7, both reading the working tree. §3.4 names no gate on it |

**Never infer an artifact's merged-ness from a sibling's gate.** A consumer may read the worktree and stop on what it finds there — most do, legitimately, and that is not what this rule is about. What is forbidden is the sentence *"every deliverable a `handoff-to-main` run stages lands in one commit, **so** this gated file's presence on `origin/<default>` implies its sibling merged with it."* That inference is true of the run that produced them and is **not a property of the tree**: `/brd-ground --no-code` hands off `design-grounding.md` alone, a hand-committed set can land partially (`/brd-reconcile`'s own §3.4 row says so), and either leaves the sibling on no ref while the gated file is merged.

**The rule was found by the defect, not derived and then applied.** Every command that states the implication must either gate what its stop depends on or carry a clause saying what the implication does not cover. **No count is kept here**: one attempt asserted a number taken from the defects that had been fixed rather than from the tree, and a recipe written to replace it could not reproduce its own result. Read the commands.

**So the test is not "does this command stop", it is "does this command claim".** A command that knowingly reads the worktree — `/epics` on `prd.md`, `/brd-interview` on `coverage-ledger.md`, `/ready` on the PRD it is reporting against — asserts nothing false and needs no gate; promoting every such read into a prerequisite would breach §5 rule 3 in a dozen places and refuse work that is ordinary today. A command that *states* the implication owes a gate or owes the deletion of the sentence. **This distinction is why the earlier, wider form of this rule was wrong**: written as "a reader that stops gates what it stops on", it condemned eight correct commands and was itself breached by the commit that introduced it.

**A handoff whose `deliverable_paths` set spans classes takes the strongest class in it** — **gated** if any one path is gated, otherwise **advisory** if any one is advisory. One array is presented for one handoff, and it has to state the largest thing declining costs: an operator told "no command stops on this" about a set containing a gated artifact will meet the stop anyway. `/brd-reconcile`'s two handoffs are the live case, and they differ: its first hands off the returned review alone (advisory), its second hands that review off together with `decisions.md` and `coverage-ledger.md`, both gated — so the second is gated even though one path in it is not.

**Classify by naming the reader, never by the absence of a §3.4 row.** A missing row rules out **gated** and settles nothing else: it says the artifact is not *gated*, and says nothing at all about whether it is *read*. Conflating the two is what shipped — §4.3's second array told the operator that nothing downstream reads the artifact it was selected for, while `/implement` Phase 0.5 was reading `_readiness.md` on every keyed run. So: a §3.4 row ⇒ **gated**; no row ⇒ name the command and the phase that reads it, and where one can be named the class is **advisory**, where none can it is **unread**. Adding a reader for an artifact adds its row to the table above; a reader that becomes a gate moves the artifact into §3.4 and out of it.

### 4.1 `handoff-to-main` outcome line

Exactly one, prefixed `Phase handoff:`.

| Case | Line |
|---|---|
| Committed, pushed, PR opened | `Phase handoff: <branch> pushed — PR #<n> open (<url>). <downstream-clause>` |
| PR already existed | `Phase handoff: <branch> pushed to existing PR #<n> (<url>). <downstream-clause>` |
| PR not opened | `Phase handoff: <branch> pushed — PR NOT opened (<reason>). Open it manually. <downstream-clause>` |
| Push failed | `Phase handoff: committed <sha7> on <branch> — push FAILED (<reason>). The phase is NOT handed off.` |
| No remote | `Phase handoff: committed <sha7> on <branch> — this specs repo has no origin remote, so nothing was pushed and no PR was opened. The phase is NOT handed off.` |
| Nothing to commit | `Phase handoff: no deliverable changes to commit on <branch>` |
| Branch name substituted | append `; branch name <intended> was taken, used <actual>` |
| Declined by the user | `Phase handoff: skipped at your request — <artifact> is written but not on <default>. <next-phase-clause>` |
| Gate failed | `Phase handoff: NOT handed off — <reason>` |

**`<downstream-clause>` is resolved from §4.0's class, on the same principle as the array.** On a **gated** artifact it is `The next phase runs once it is merged.` — or, on the *PR not opened* row, `The next phase will stop until it is merged.` On an **advisory** one it is `No command waits on this; what reads it reads it as advice.` On an **unread** one it is `Nothing downstream reads it, so no command waits on this.` These are the *success* path, and before this clause existed they asserted a waiting phase unconditionally — so a `/frames` run that handed off cleanly printed "The next phase runs once it is merged." having, in the same phase, just offered the §4.3 array that says nothing reads it. Both halves of that run were wrong, and it took two fixes to see it: the clause was corrected first, and the array it was made to agree with was itself wrong — a frame-set index is read (§4.0), so `/frames` is **advisory**. A run must not contradict its own prompt, and the outcome line is the half the operator acts on. The *No remote* and *Push failed* rows carry no clause at all: neither landed the artifact, so the sentence to print about what happens next is the same one the *Declined by the user* row prints, and repeating it beside "The phase is NOT handed off." would say twice what that row already says once.

**`<next-phase-clause>` resolves four ways: §4.0's three classes, with the *gated* one split by §3.4's own column.** Declining writes no branch and no commit, so a gated artifact's next phase reads **row F** — which delegates, and §3.4 records per consumer whether that delegation is a stop or a fallback. The four:

- **gated**, where §3.4's row for that consumer says *stops* → `the next phase will stop until it is.`
- **gated**, where the row preserves a pre-existing absent behaviour — the `/create-prd` idea ladder, and the PRD read in `/create-ard` and `/specify` → `the next phase does not stop on that: it reports the artifact as un-landed and proceeds from the resolved folder.`
- **advisory** → `nothing stops on this; the phase that reads it reads your working copy, so it still sees this run's result.`
- **unread** → `nothing downstream reads it, so no command stops on this.`

No two of the four are interchangeable, and each wrong pick misleads in its own direction: the stop clause promises a refusal the operator will not meet, the fallback clause reports an un-landing to a phase that was never waiting, the advisory clause tells them a reader exists where none does, and the unread clause tells them to ignore a phase that is in fact reading the file. Telling them apart costs nothing — the producer knows which artifact it just wrote, and §4.0 says which class it is in.

### 4.2 The no-`gh` fallback text

    The branch is pushed but no pull request was opened (<reason>).
    Open one from <branch> into <default> in the web UI, using this title:
      <title>
    The body is at <body-path>.
    <downstream-clause>   # §4.1, resolved from the artifact's §4.0 class — never the bare
                          # "until it is merged" sentence, which is false for both the
                          # advisory and the unread class.

### 4.3 The consent choice

**One array per §4.0 class.** A producing command presents the array its artifact's class selects, verbatim — order, wording, and the `(Recommended)` marker are not the caller's to change. Only the second option's parenthetical differs between the three; the first and third options are identical in all of them. (Quoting these arrays into a command is sanctioned, and is the one thing §5 rule 4 exempts from its "never restate this reference" rule — an array is user-facing text the harness renders literally, not a rule. That exemption carries one obligation, and it falls on the citing form only: a command that *cites* this array rather than quoting it names the class it cites for.)

**gated** — a consumer runs `require-on-main` on this artifact:

    choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]

**advisory** — nothing gates it, but a command reads it. `_readiness.md` is the case, and `/ready` the producer:

    choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (no command stops on this; what reads it reads your working copy)", "Cancel"]

**unread** — nothing gates it and nothing reads it. §4.0's register now names its members: `/specify`'s `_session.md`, `_glossary.md` and rendered `.html`, `/design`'s `_design-session.md` and `_design-glossary.md`, and `/update-prd`'s archived revision. **Two artifacts have already left this class after someone actually looked** — the frame-set index, which `design-grounder` refuses to run without, and `slices.md`, which `/brd-reconcile` corrects in place. A producer reaching for this array is making the claim both of those failed: that it looked for a reader and there is none. Look, before selecting it:

    choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (nothing downstream reads this, so no command stops on it)", "Cancel"]

The second option's parenthetical is load-bearing: it is the only place the user learns what declining costs, and the only reason there are three arrays rather than one. It must agree with the `<next-phase-clause>` §4.1 prints on that same decline — the two are read by the same operator minutes apart, and a run that contradicts its own prompt teaches them to trust neither half. Each wrong pick misleads in its own direction: the gated array promises a refusal the operator will not meet, and the unread array tells them to ignore a phase that is reading the file.

**Select by §4.0's test, never by "has a §3.4 row" alone.** A missing row rules out **gated** and decides nothing between **advisory** and **unread**; the producer settles that by naming the reader, or by naming that there is none. Both halves of the old binary were wrong about `_readiness.md` at once: `/ready` presented the gated array for an artifact no command gates, and the alternate it should have fallen to under the "no §3.4 row" test would have told the operator that nothing downstream reads a file `/implement` Phase 0.5 reads on every keyed run.

**Where §2.1 set `remote: none`, print one line immediately above the array**, then present the array itself unchanged:

    This specs repo has no `origin` remote: the first option will branch and commit locally, and the push and pull request cannot run.

The array is not reworded for this, and that is deliberate rather than lazy. The option text says what the option is *for*; the class parenthetical is already the only thing that varies between the three, and making the option line vary on the remote as well would be three more literal strings for every producer to keep in step — to carry a fact about the *repository*, which every class shares, rather than about the artifact, which is what the class distinguishes. The line above the array is where the operator meets that fact, at the moment they choose, which is exactly what this section's agreement principle asks for; §4.1's *No remote* row then reports the same fact when the run finishes. The first option keeps its `(Recommended)` marker: committing the deliverable locally is still the best of the three, and the notice has already said what it will and will not do.

**What each option means.** Option 1 runs `handoff-to-main` (§2). Options 2 and 3 both decline it: the deliverable stays written and uncommitted, and the producer emits §4.1's "Declined by the user" line either way. They differ only in recorded intent — option 2 states the user will handle git themselves, option 3 states nothing — so a caller must not infer from option 3 that the artifact is unwanted, and must never delete or revert it. **Neither option stops the run's emitter tail**: feedback → follow-ups → cost → `resume.md` → `commit-artifacts` still executes, because that tail commits only `$SPECS_PATH`'s bounded session-artifact paths (`specs-repo-git.md` §2.1), never the deliverable this choice governs.

### 4.4 Stop contract

Every `require-on-main` stop carries the same four parts as `specs-repo-git.md` §5, in this order: what was found (the concrete state — the path, the branch, the pull-request number); what the plugin did **not** do, stated as the consequence; the exact commands to resolve it with `$SPECS_PATH` already substituted; and one clause on what happens if it is ignored.

## 5. Caller contract

Four obligations. Omitting any one is a defect, not a style choice.

1. A command that **produces** a `$SPECS_PATH` deliverable cites and executes `handoff-to-main` (§2) in its Handoff phase, behind §4.3's choice, and emits the §4.1 line exactly once.
2. A command that **consumes** one cites and executes `require-on-main` (§3) in its Phase 0 — before its first subagent dispatch, code scan, docs-grounding retrieval, or grill question. A gate that fires after a scan has already spent what it was meant to save.
3. A consumer acts on the returned state, and on `absent` applies its own pre-existing behaviour (§3.4). **No consumer turns an optional input into a prerequisite.** A consumer whose gated input shipped with the consumer itself — so there is no pre-existing behaviour and nothing was ever optional — may map `absent` to a stop, and §3.4's table names each one and why.
4. **Never restate this reference's rules** — cite the section number. A rule copied into a command is a rule that goes stale. **§4.3's choice arrays are the one exception, and they are quoted rather than cited on purpose.** An array is not a rule: it is user-facing text that `AskUserQuestion` renders literally, and `scripts/check-docs.sh` check 12 gates the arity of the arrays it can *see*, so an array a command only cites is an array with no arity gate on it. The exemption is that narrow — the arrays, nothing else — and it carries one obligation in exchange, which falls on the citing form only: **a command that cites the array rather than quoting it names the §4.0 class it cites for**, because with three variants "present §4.3's consent choice verbatim" identifies none of them. A command that quotes needs no such label: the quoted string *is* the claim, and it is greppable. **§4.0 stays the authority on which artifact is in which class.** A command may state the class its own deliverable is in and why — that is a fact about its own output, and stating it is what would have caught the `_readiness.md` defect before it shipped — but §4.0's register is what that statement is checked against, and a command that disagrees with it is the defective half. This exemption is written down because its absence was a defect of exactly the kind `instruction-file-maintenance.md` names: §4.3 said *present this array verbatim* while this rule said *never restate*, both live, both binding, and no reader could follow both.

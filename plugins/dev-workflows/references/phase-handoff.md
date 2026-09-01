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

### 2.2 Branch resolution, and the collision rule

Intended name: `<prefix>/<KEY>-<slug>`, where `<prefix>` is the caller's own (§2.9) and `<KEY>-<slug>` come from **the resolved feature folder the deliverable was written into** — never re-derived from the item title. Folder resolution already tolerates a human-adjusted slug and a stray `-`/`_` after the key, and re-deriving would produce a branch name that disagrees with the directory it commits.

Collision is normal, not exceptional: `_readiness.md` is overwritten on every `/ready` run, and a `/create-prd` re-run after its pull request merged wants the same name again. `gh pr create` fails on an already-merged branch, and force-pushing and `branch -D` are both forbidden (§1 rule 4). So:

1. Test both `git -C "$SPECS_PATH" rev-parse --verify --quiet refs/heads/<name>` and `… refs/remotes/origin/<name>`.
2. Neither exists → use `<name>`.
3. **At least one exists** (the local ref, the remote ref, or — the common reuse case — both) **and** it is this run's own in-progress branch — its prefix is the caller's, `specs-repo-git.md` §3.5's `branch-key` resolves it to a key in the run key set (§3.2 there — the same resolution the preflight's B3 makes, so a branch the preflight stayed on is a branch this rule reuses), and the branch is **not already merged** → **reuse it**, switching to it rather than creating it.

   **Test the merge against a ref that still exists, and read a missing ref as merged.** Resolve the branch ref first — `refs/remotes/origin/<name>` when it exists, else `refs/heads/<name>` — and run `git -C "$SPECS_PATH" merge-base --is-ancestor <that ref> refs/remotes/origin/<default> 2>/dev/null`: exit 0 = merged (do not reuse; fall to rule 4 and create a fresh name), non-zero = not yet merged (reuse). The `2>/dev/null` is required for the same reason §3.2 gives for its own probe — on a missing ref git writes `fatal: Not a valid object name`, which must not leak into the run's output.

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
`design/<frame-set>/` — `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`, *Vendored sources*;
`/frames` writes one `index.md` per `design/*/` set of the folder it resolved —
`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.2) enumerates every one of them literally. The consequence of leaving one out is silent and total: it is
classified OTHER, never staged, and never reaches the default branch, while the deliverable that links
it lands there pointing at a path on no ref.

Nothing staged → no commit. Emit the §4.1 `nothing to commit` line. This is not an error: a re-run that changed nothing is a legitimate outcome.

### 2.4 Commit

Message `<KEY> <summary>`, matching the specs repo's own `<KEY|NOISSUE> <summary>` convention. Carry `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` (§1 rule 6).

### 2.5 Push

`git -C "$SPECS_PATH" push -u origin <branch>`. Never force. A non-fast-forward rejection is reported, never resolved by rebasing or forcing mid-run.

### 2.6 Open the pull request

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

**The host is kept, not stripped** — the same rule as `${CLAUDE_PLUGIN_ROOT}/references/code-handoff.md` §2.6, and for the same reason. `gh -R` accepts `[HOST/]OWNER/REPO`, and `gh auth status` succeeds whenever the user is authenticated to *any* host, so a bare `OWNER/REPO` derived from a GitHub Enterprise remote resolves against **github.com** — silently opening the phase's pull request on an unrelated public repository if one happens to sit at that path, with the capability probe catching nothing because the call succeeded. Only `github.com` may drop the host. Validate the slug against `^[^/]+/[^/]+$` before calling `gh`; anything else (a Bitbucket `scm/proj/repo`, a nested GitLab group) is not a `gh` target — skip to §4.2. §3.5's `gh pr list -R "$OWNER_REPO"` uses the same value and mistargets identically without this.


The expressions strip a scheme, a `user@`, and a host with an optional `:port` terminated by `/` or `:` (the scp-like `git@host:Org/repo` form uses a colon), then a trailing slash and `.git`. The earlier two-expression form handled only `git@host:` and `https://host/`, and passed an `ssh://git@host/Org/repo.git` remote through unchanged — `gh` then failed on a repository argument that was a whole URL. Do not simplify it back.
**Capability probe, not host classification.** Try the call; on any failure fall back to §4.2's instruction. Push authority and pull-request authority are independent — push runs over SSH with a per-repo key, `gh` runs over the API with a token, and the same account can have write access to one repository and read access to another. No hostname or host-type test can detect that mismatch, so a run can push successfully and still be unable to open the pull request. This is why `finish-and-handoff.md` §4's host classification is right for choosing *instructions* and insufficient here.

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

The four primitives, each verified against a real specs repo:

- **The default-branch ref exists:** `git -C "$SPECS_PATH" rev-parse --verify --quiet "origin/<default>"` Exit 0 = the ref exists — run the next primitive. Non-zero = row G: nothing to verify against, stop. This runs **before** the next primitive, because that primitive's own required `2>/dev/null` discards the only signal that would otherwise distinguish "path absent on an existing ref" (row F) from "the ref itself does not exist" (row G) — `git cat-file -e` exits 128 for both, verified empirically: a missing path and a missing ref are indistinguishable by exit code alone.
- **On the default branch:** `git -C "$SPECS_PATH" cat-file -e "origin/<default>:<path>" 2>/dev/null` Exit 0 = present. The `2>/dev/null` is required — on absence git writes `fatal: path '<path>' does not exist in 'origin/<default>'` to stderr, which must not leak into the run's output. Only reached once the ref-existence primitive above has already confirmed `origin/<default>` exists, so a non-zero exit here means the path is absent, never that the ref is.
- **Worktree matches the ref:** `git -C "$SPECS_PATH" diff --quiet "origin/<default>" -- "<path>"` Exit 0 = identical. This also catches a **staged-only** change, which a `hash-object` comparison against the working file would miss.
- **Plugin branches carrying the artifact:** `git -C "$SPECS_PATH" for-each-ref --format='%(refname:short)' refs/remotes/origin refs/heads` filtered to `(origin/)?(idea|prd|ard|spec|design|ready|brd|frames)/*`, then `git -C "$SPECS_PATH" cat-file -e "<ref>:<path>" 2>/dev/null` on each. **Local `refs/heads` are scanned as well as remote ones**, and for the same reason §2.2's branch resolution tests both: a deliverable that was committed but whose push failed (§2.5, reported by §4.1 as "NOT handed off") exists only on a local branch. Scanning remote refs alone would return `absent` for it — the one state §2.8 promises "the next phase's gate is what enforces the consequence" of. Prefer the remote ref when both carry the path, so rows D and E report the branch the pull request is open against. **Then strip a leading `origin/` and carry the bare branch name forward** — `%(refname:short)` of a remote ref is `origin/spec/PRD-2-y`, while the branch that exists on the host is `spec/PRD-2-y`. This is not cosmetic: §3.5 feeds this value to `gh pr list --head`, which filters by the head branch name **on the host** and matches nothing against an `origin/`-prefixed string, so leaving the prefix on made **row D unreachable in every repository state** — a pushed branch with an open pull request reported row E's "was never handed off", silently, with `gh` exiting 0. The bare name is also the only form the operator can act on.

### 3.3 The state table

First matching row applies.

| # | On `origin/<default>` | Worktree | HEAD | Outcome |
|---|---|---|---|---|
| H | — | — | gate of §3.1 fails | **silent skip** — return `unmanaged`; the caller proceeds exactly as it did before this feature |
| I | — | — | run carries `specs_git: blocked` (detached HEAD), **or** HEAD is detached and no preflight set that flag | **stop**, re-emitting that notice where there is one. A phase cannot complete from a detached HEAD, so verifying one is meaningless |
| G | `origin/<default>` ref does not exist | — | any | **stop** — the plugin cannot verify what is on `<default>` |
| A | present | matches ref | any | **pass** |
| B | present | differs | a branch **this run itself created or reused during this run**: created earlier in the same invocation via this caller's own `handoff-to-main`, or reused because `specs-repo-git.md` §3.5 B3 kept the preflight checkout on it AND the branch is the caller's **own** — its prefix is this caller's and its key is in the run key set (`specs-repo-git.md` §3.2). The test is **branch ownership, not artifact authorship**: the load-bearing case is `/design` resumed on its own `design/<EPIC>-<eslug>` branch gating the `specification.md` that same branch amends, and `/design` is not that file's original author (`/specify` is). Requiring authorship would exclude the one case this row exists for and drop it into row C, whose repair offer re-grounds the session on the un-amended copy. Ownership is still never merely a prefix the caller is *capable of* producing for an unrelated purpose, such as `/implement`'s Phase 4.5 escalation handoff onto `spec`/`design` | **pass, reported** — `reading <path> from your in-progress <branch>, which amends the approved version on <default>` |
| C′ | present | differs | any other HEAD, **and** the tree is dirty in a way that would block the switch **or** the `pull --ff-only` that follows it | **stop**, naming the exact files |
| C″ | present | differs | HEAD **is** the default branch (so nothing to switch to), and the divergence is local — an uncommitted edit **or** a committed-but-unpushed one | **stop**, naming the files and saying the repair offer cannot help here |
| C | present | differs | any other HEAD | **repair offer**, then re-test once |
| D | not on ref | — | artifact found on a plugin ref, pull request open | **stop** — `<path> is on branch <branch> with PR #<n> open, not merged` |
| E | not on ref | — | found on a plugin ref, no open pull request | **stop** — `<path> is on branch <branch> and was never handed off` |
| F | not on ref | — | found on no ref | **delegate** — return `absent`; see §3.4 |

**`not on ref` describes the repository, not the return value.** Rows D, E, and F all read `not on ref` in the first column because none of the three has the artifact on `origin/<default>` — that column is a statement about the repository. It is row F alone that returns `absent` (§3.7), and D/E are stopping rows that never reach a caller's `absent` branch at all. A consumer that keys off this column instead of the returned `stopped` flag cannot tell D/E from F.

**Row order matters.** H, I, and G precede everything else because they are about the repository, not the artifact — and G, like H and I, must precede every row that keys on `not on ref` (D, E, F) and every row that tests the worktree against the ref at all (A, B, C′, C″, C): §3.2's ref-existence primitive runs before the on-ref-presence primitive, so a reader who has not first ruled out G cannot tell "path absent on an existing ref" (row F) from "the ref itself does not exist" (row G) — the defect `f5a9713` closed in §3.2 but this table, until now, never propagated to its own row order. C′ precedes C because offering a switch that git would refuse is worse than naming the blocker.

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

Row F is the difference between "this phase was not handed off" and "this phase never happened". Only the second is row F **as the plugin produces it** — `handoff-to-main` always names a prefixed branch, so a plugin-internal run that handed off is found on a ref. A **person** working on their own branch is the third case: `specs-repo-git.md` G2 sanctions a run committing and pushing artifacts onto a non-plugin branch, and §3.2's scan is filtered to plugin prefixes, so that artifact is "found on no ref" and lands in row F too. Row F therefore means *not found on a branch this plugin manages*, which is not quite *never happened*; the gate has no opinion about either, which is why delegating rather than stopping is still right. **An input that was optional before this gate existed stays optional, and that must not change.** The gate returns `absent`; the caller does what it already does.

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
| `/brd-ground` | the BRD's `coverage-ledger.md` | **stops**, and **splits row F into two stops on a test this gate cannot make** — no `coverage-ledger.md` in the folder at all is *never produced* and names the producing run by level (`BRD_GROUND_NEEDS_INTAKE`, or `BRD_GROUND_NEEDS_SPLIT` for a slice); a ledger in the folder but on no ref is `BRD_GROUND_NOT_HANDED_OFF` (produced, handoff declined), whose action is to land the files already on disk, and which names the producer only where re-running it would in fact stage them — never `/brd-split`, a no-op on a fully-allocated parent. Never optional either way: grounding has no claim list without the inventory this file arrives with, and the route ships with no pre-gate behaviour to fall back to |
| `/brd-split` | the BRD's `grounding/code-grounding.md` | **stops** — `BRD_SPLIT_NEEDS_GROUNDING`. Never optional: the command's whole gate is that every finding carries a verifier outcome, and a BRD with no findings at all has nothing to allocate against |
| `/brd-interview` | the BRD's `grounding/code-grounding.md` | **stops** — `BRD_INTERVIEW_NEEDS_GROUNDING`. Never optional: every `[G]` is answered from the findings and from nothing else, so a BRD with none has no question this command may answer |
| `/brd-package` | the BRD's `decisions.md` | **stops**, and **splits row F into two stops on a test this gate cannot make** — no `decisions.md` in the folder at all is `BRD_PACKAGE_NEEDS_INTERVIEW` (no interview ever ran); a register in the folder but on no ref is `BRD_PACKAGE_REGISTER_NOT_HANDED_OFF` (ran, handoff declined), which must **not** send the operator back to `/brd-interview`, whose no-new-round path stages nothing on an unchanged BRD. Never optional either way: the package is assembled from the register, and a BRD with none has nothing to put in front of a customer |
| `/brd-reconcile` | the BRD's most recent `customer-review-prompt-<YYYYMMDD>.md` | **stops**, and **splits row F into two stops on a test this gate cannot make** — no prompt in the folder at all is `BRD_RECONCILE_NEEDS_PACKAGE` (no package was ever built); a prompt in the folder but on no ref is `BRD_RECONCILE_PACKAGE_NOT_HANDED_OFF` (built, handoff declined), which must **not** send the operator back to `/brd-package`, since that command will not rewrite a dated bundle. Never optional either way: reconciling against a package that exists only in a working tree would freeze customer authority against a document nobody can produce later |

For the consumers that predate this gate, rows D and E add the only new stop: an artifact that **exists** and was never handed off. That state was **not** unreachable before this feature — pre-J, `/specify` already created `spec/<EPIC>-<eslug>` (or `spec/<PRD>-<vslug>`) branches and offered branch + PR, and `/create-prd` did the same on `prd/<KEY>-<slug>`, with no downstream gate reading them; an artifact sitting on such a branch, unmerged, was a common, ordinary state. This is a real behaviour change: for that state, `/create-ard`, `/specify`, and `/epics` now hard-stop where they previously proceeded with a documented fallback (the deliberate, well-argued stop at `epics.md:180`). It qualifies caller-contract rule 3 (§5 — no consumer turns an optional input into a prerequisite) precisely: for those consumers, row F's `absent` case is still fully delegated to the caller's own pre-existing behaviour, but rows D/E are a new stop for a state that was previously reachable and previously non-blocking. All five `/brd-*` consumers — `/brd-ground`, `/brd-split`, `/brd-interview`, `/brd-package` and `/brd-reconcile` (`/brd-intake` consumes nothing and runs no gate) — sit outside that qualification entirely: they have no pre-gate behaviour, because their inputs and the commands that read them shipped together, so rule 3 has no optional input to protect there.

### 3.5 Locating the branch and its pull request

For rows D and E, after §3.2's ref scan finds a carrying branch:

    gh pr list -R "$OWNER_REPO" --head <branch> --state open --json number,url

**Derive `$OWNER_REPO` first (§2.6), and skip this probe when the derivation does not validate.** §2.6's slug test (`^[^/]+/[^/]+$`) is what says whether this remote is a `gh` target at all; running the probe before it means calling `gh` with an unvalidated `-R`. `<branch>` is the bare name §3.2 carried forward, never `origin/`-prefixed. On `gh` failure, use **row E's** wording plus a note that the pull-request state could not be checked — never assert a pull request exists, and never assert one does not.

### 3.6 Degraded verification

- **Fetch failed** (offline, auth) → test against the last-known `origin/<default>` and say so, the precedent `specs-repo-git.md` §3.2 already sets: `offline — checked against the last-fetched ref`.
- **Read-only specs mount** → `references/read-only-repos.md` applies: no `fetch`, use the existing ref, emit the degraded clause. **The read-only rows degrade in freshness only; the repair rows do not run at all.** Every classifying primitive in §3.2 is a read, so rows H/G/A/B/C″/D/E/F reach their verdict unchanged against a stale ref. Row C's offer, though, is a `switch` and a `pull` — writes that `read-only-repos.md` forbids and that git refuses with a raw `fatal:` — so on a read-only mount row C **stops with its finding instead of offering the repair**, naming the mount as the reason. Saying only that freshness degrades was false for the one row that writes.
- **No `origin/<default>` ref at all** → row G. Nothing to verify against, and proceeding silently is the failure this reference exists to prevent.

### 3.7 Return value

    on_main: pass | pass_amending | absent | unmanaged
    stopped: true | false
    branch: <the carrying plugin branch, or null>
    pr: <number, or null>
    degraded: <the clause to print, or null>

`pass_amending` is row B. `absent` is row F and is the caller's to interpret per §3.4. `unmanaged` is row H. Every stopping row returns `stopped: true`, and every caller but one then stops.

**`/ready` is the sole exception, by design.** It is a read-only verifier whose entire function is to report, so a run that stops instead of reporting has failed at the one thing it exists to do. It records each stopping row as a readiness finding — capping the verdict at `PARTIAL` — and continues (`ready.md:18`, `:86`). `ard-resolution.md` carves `/ready` out of its own `status: unmerged` stop in exactly the same way and for exactly the same reason. No other caller may take this exception, and a caller that wants one adds it here first.

**`on_main` is defined only when `stopped: false`.** Its four values — `pass` (row A), `pass_amending` (row B), `absent` (row F), `unmanaged` (row H) — are exhaustive for the non-stopping rows only. Every stopping row (I, C′, C, D, E, G) carries no defined `on_main` value; a caller has nothing to read there and must act on `stopped`/`branch`/`pr`/`degraded` instead.

**A caller tests `stopped` before `on_main`.** `on_main: absent` is returned only by row F; every stopping row (I, C′, C″, C, D, E, G — seven of the eleven) returns `stopped: true` regardless of what `on_main` reads. A caller that branches on `on_main == "absent"` before checking `stopped` cannot distinguish row F (never happened — §3.4 applies) from rows D/E (happened, but not handed off — the run must stop).

## 4. Reporting

### 4.1 `handoff-to-main` outcome line

Exactly one, prefixed `Phase handoff:`.

| Case | Line |
|---|---|
| Committed, pushed, PR opened | `Phase handoff: <branch> pushed — PR #<n> open (<url>). <downstream-clause>` |
| PR already existed | `Phase handoff: <branch> pushed to existing PR #<n> (<url>). <downstream-clause>` |
| PR not opened | `Phase handoff: <branch> pushed — PR NOT opened (<reason>). Open it manually. <downstream-clause>` |
| Push failed | `Phase handoff: committed <sha7> on <branch> — push FAILED (<reason>). The phase is NOT handed off.` |
| Nothing to commit | `Phase handoff: no deliverable changes to commit on <branch>` |
| Branch name substituted | append `; branch name <intended> was taken, used <actual>` |
| Declined by the user | `Phase handoff: skipped at your request — <artifact> is written but not on <default>. <next-phase-clause>` |
| Gate failed | `Phase handoff: NOT handed off — <reason>` |

**`<downstream-clause>` is resolved from §3.4's row too, and on the same principle.** Where §3.4 has
a row for this artifact, it is `The next phase runs once it is merged.` — or, on the *PR not opened*
row, `The next phase will stop until it is merged.` Where §3.4 has **no row at all**, it is `Nothing
downstream reads it, so no command waits on this.` These three lines are the *success* path, and
before this clause existed they asserted a waiting phase unconditionally — so a `/frames` run that
handed off cleanly printed "The next phase runs once it is merged." having, in the same phase, just
offered the §4.3 array that says nothing reads it. A run must not contradict its own prompt, and the
outcome line is the half the operator acts on.

**`<next-phase-clause>` is resolved from §3.4's row for this artifact, and it is not always a stop.**
Declining writes no branch and no commit, so the next phase's gate reads **row F** — which delegates.
Where §3.4's row for that consumer says *stops*, the clause is
`the next phase will stop until it is.` Where the row preserves a pre-existing absent behaviour — the
`/create-prd` idea ladder, and the PRD read in `/create-ard` and `/specify` — the clause is
`the next phase does not stop on that: it reports the artifact as un-landed and proceeds from the
resolved folder.` Where §3.4 has **no row at all** because nothing downstream consumes the artifact —
a frame-set index is the case, and `/frames` the producer — the clause is `nothing downstream reads it,
so no command stops on this.` A missing row is not the same as a row that stops, and neither of the
first two sentences is true of an artifact with no consumer: one promises a refusal that cannot
happen, the other reports an un-landing to a phase that was never waiting. Printing the stop clause on
a seam that does not stop tells the operator to expect a refusal they will not meet, and the three
sentences cost nothing to tell apart: the producer knows which artifact it just wrote.

### 4.2 The no-`gh` fallback text

    The branch is pushed but no pull request was opened (<reason>).
    Open one from <branch> into <default> in the web UI, using this title:
      <title>
    The body is at <body-path>.
    <downstream-clause>   # §4.1 — never the bare "until it is merged" sentence, which is
                          # false for an artifact nothing downstream consumes.

### 4.3 The consent choice

Every producing command presents this array verbatim — order, wording, and the `(Recommended)` marker are not the caller's to change:

    choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]

The second option's parenthetical is load-bearing: it is the only place the user learns that declining has a downstream cost.

**Where the artifact has no §3.4 row, present this array instead** — a frame-set index is the case, and `/frames` the producer:

    choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (nothing downstream reads this, so no command stops on it)", "Cancel"]

Only the second option's parenthetical differs, and it differs for the same reason §4.1 resolves `<next-phase-clause>` three ways rather than one: declining costs the operator nothing here, and the array is where they decide. Promising a stop that cannot happen tells them to expect a refusal they will not meet — and the run then contradicts itself, because §4.1's own third clause correctly reports that nothing downstream reads it. The choice and the outcome line must agree, and the producer knows which artifact it just wrote.

**What each option means.** Option 1 runs `handoff-to-main` (§2). Options 2 and 3 both decline it: the deliverable stays written and uncommitted, and the producer emits §4.1's "Declined by the user" line either way. They differ only in recorded intent — option 2 states the user will handle git themselves, option 3 states nothing — so a caller must not infer from option 3 that the artifact is unwanted, and must never delete or revert it. **Neither option stops the run's emitter tail**: feedback → follow-ups → cost → `resume.md` → `commit-artifacts` still executes, because that tail commits only `$SPECS_PATH`'s bounded session-artifact paths (`specs-repo-git.md` §2.1), never the deliverable this choice governs.

### 4.4 Stop contract

Every `require-on-main` stop carries the same four parts as `specs-repo-git.md` §5, in this order: what was found (the concrete state — the path, the branch, the pull-request number); what the plugin did **not** do, stated as the consequence; the exact commands to resolve it with `$SPECS_PATH` already substituted; and one clause on what happens if it is ignored.

## 5. Caller contract

Four obligations. Omitting any one is a defect, not a style choice.

1. A command that **produces** a `$SPECS_PATH` deliverable cites and executes `handoff-to-main` (§2) in its Handoff phase, behind §4.3's choice, and emits the §4.1 line exactly once.
2. A command that **consumes** one cites and executes `require-on-main` (§3) in its Phase 0 — before its first subagent dispatch, code scan, docs-grounding retrieval, or grill question. A gate that fires after a scan has already spent what it was meant to save.
3. A consumer acts on the returned state, and on `absent` applies its own pre-existing behaviour (§3.4). **No consumer turns an optional input into a prerequisite.** A consumer whose gated input shipped with the consumer itself — so there is no pre-existing behaviour and nothing was ever optional — may map `absent` to a stop, and §3.4's table names each one and why.
4. **Never restate this reference's rules** — cite the section number. A rule copied into a command is a rule that goes stale.

# Specs-repo git — Shared Reference

Single source of truth for the two git entry points the plugin runs against the
**specs repo** (`$SPECS_PATH`). Every command that writes a bookkeeping artifact
there cites this file and executes its steps inline. The orchestrator owns any
printed output; this reference owns the gates, the bounded write authority, the
branch policy, and the failure discipline — the same shape as
`feedback-emission.md`, `cost-emission.md`, and `followup-emission.md`.

**Purpose.** The per-PRD `dev-workflows/` area exists so feedback, cost,
follow-ups, and the resume pointer reach the **plugin maintainer**. They reach
the maintainer only if they are committed and pushed. The emitters deliberately
never commit — they run mid-run, often from inside someone else's repository,
and must never touch git. This reference supplies the two steps that close the
loop: a **run-start** flush and branch disposition (`specs-preflight`, §3) and a
**terminal** commit (`commit-artifacts`, §4).

**Scope.** ONLY the bounded artifact paths of §2.1, ONLY inside `$SPECS_PATH`. Nothing here ever touches a code repo, a docs repo, the vault, or the current working directory. Neither entry point here opens a pull request: `specs-preflight` and `commit-artifacts` are prompt-free bookkeeping steps, and opening a pull request is outward-facing. Deliverable handoff — including `gh pr create` where the host supports it — lives in `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.6, behind that reference's consent choice. `git push` here is git-protocol, already sanctioned by `finish-and-handoff.md` §3.

## 1. Hard rules

1. **`git -C` always; `cd` never.** Every invocation is
   `git -C "$SPECS_PATH" …`. The working directory is NEVER changed. Most
   callers are running inside a *different* repository when these entry points
   fire; a `cd` would corrupt their git state.
2. **Bounded paths.** Only §2.1 paths are ever staged. `git add -A` is never
   issued at repository scope — always `git add -A -- <literal paths>`.
3. **Bounded branches.** Only branches matching `^(idea|prd|ard|spec|design|ready|brd)/`
   are the plugin's to switch away from or delete (§2.2).
4. **Never destructive.** No `push --force`, no `push -f`, no `branch -D`, no
   `merge`, no `rebase`, no `reset`, and never delete an `index.lock`.
5. **Never fatal.** Every failure is reported and the run continues. The run
   never fails because of a git step here.
6. **No `Co-Authored-By` trailer.** These are plugin-generated bookkeeping
   files, not authored content, and each artifact already carries its own
   `author:` field (`feedback-emission.md` §1).
7. **Prompt-free.** Neither entry point asks the user anything. `specs-preflight`
   is silent unless it acts; `commit-artifacts` emits one outcome line (§6).

## 2. Bounded write authority

### 2.1 Paths

Exactly three shapes, derived from the emission ladders. Nothing outside this
set is ever staged.

```
<specs-root>/{specs|specifications|vis}/**/dev-workflows/**   # tier 1: feedback, cost, follow-ups, resume.md
<specs-root>/dev-workflows-feedback/**                        # feedback-emission.md §2 tier 2 (keyless runs)
<specs-root>/dev-workflows-cost/**                            # cost-emission.md §9 pending files (keyless runs)
```

Sources: `feedback-emission.md` §2 tiers 1–2, `cost-emission.md` §8 tier 1 and
§9 pending, `followup-emission.md` §4 (the shared per-PRD area),
`session-hygiene.md` §1 (resume tier 1).

**Staging is by enumeration, not by glob.** Pathspec glob magic (`:(glob)`) is
fragile to express and to review. The procedure is:

1. `git -C "$SPECS_PATH" status --porcelain --untracked-files=all`
   `--untracked-files=all` is **required** — the default collapses an untracked
   directory to a single `?? dir/` line, which would hide which files are being
   staged.
2. Classify each reported path: **ARTIFACT** if it matches
   `^(specs|specifications|vis)/.+/dev-workflows/` or `^dev-workflows-feedback/`
   or `^dev-workflows-cost/`; **OTHER** otherwise.
3. Stage the literal ARTIFACT paths only:
   `git -C "$SPECS_PATH" add -A -- <path> [<path>…]`.

`-A` is used deliberately: `cost-emission.md` §9 relocates a pending cost file
into a PRD directory and then **deletes** the pending file, and that deletion
must be staged. `-A` states that intent explicitly, and it was strictly
required before git 2.0, where `git add <path>` did not stage a deletion. On
git ≥ 2.0 a plain `git add -- <path>` stages a deletion for a literal path too
— verified empirically — so keep `-A` for explicitness and for older git, but
do not justify it by claiming plain `git add` cannot stage the deletion.

### 2.2 Branches

**The plugin manages only branches it created.** A branch is plugin-owned when
its name matches `^(idea|prd|ard|spec|design|ready|brd)/`.

Any other **named** branch — the user's own work, a hand-made branch — is left
alone and never switched away from (§3.3 G2). The run's artifacts are still
committed there, because a named branch cannot be lost.

A **detached HEAD** is not a branch. It is handled separately and far more
strictly (§3.3 G0, §3.7): nothing is committed at all.

## 3. `specs-preflight` — run start

Runs as early as `$SPECS_PATH` is known — Phase 0 in most commands. Prompt-free.
Silent when the repository is already clean and on the default branch; it emits
a block only when it acts or when a guard fires.

### 3.1 Gate

All of: `$SPECS_PATH` is set and is an existing directory;
`git -C "$SPECS_PATH" rev-parse --git-dir` succeeds; and the resolved `.git`
directory is **writable**. Test `.git` specifically, not just the worktree —
`commit` and `fetch` both write there, and a read-only specs mount is a normal
state in this container setup.

Gate fails → **silent no-op**. The artifacts are going to a vault or
report-only tier the plugin does not manage.

### 3.2 Resolution inputs

**Default branch:** `git -C "$SPECS_PATH" symbolic-ref --quiet refs/remotes/origin/HEAD`,
then strip the `refs/remotes/origin/` prefix. If unset, fall back to `main`,
then `master`, then the current branch — in which case no branch switching
occurs at all.

**Freshness:** best-effort `git -C "$SPECS_PATH" fetch origin <default>` before
the ancestry test. On failure (offline, auth), use the existing local
`origin/<default>` ref and note `offline — ancestry checked against the
last-fetched ref`. Never fatal.

**Run key set:** every key the run is scoped to — the identity each of this run's
own branches is *named for* — taking each key already resolved at the call site.
A PRD-scoped run contributes its PRD key. A run invoked as `<PRD> <Epic>`
(`/create-ard`, `/specify`, `/design`, `/ready`) contributes **both** — the Epic
is as much this run's key as the PRD is, and §3.5 must recognise a branch named
for either (§3.6). When no key is resolved at the call site the set is empty and
the run is **keyless**. Both are correct behaviour — no command needs to defer
its preflight in order to obtain a key.

**Keyless is a property of the route, not of the command**, and `/create-prd` is
where the two routes diverge:

- **On the `/idea` route** it is structurally keyless here: its key is minted by
  the Jira round-trip in a later phase, and keyless is the right classification
  for it — a new PRD must not stack on another PRD's branch.
- **On the BRD route it is not keyless**, and classifying it so is a defect
  rather than a conservative default. The positional token is a **BRD key**,
  resolved and validated at the call site by that command's own Phase 0 step 1 —
  before this preflight runs — the deliverable is written into that BRD's folder,
  and the branch `handoff-to-main` names is `prd/<BRD-KEY>-<slug>`. So the run
  contributes that BRD key. Without it, a BRD-route run interrupted after its
  branch exists takes **B4** on its own in-progress branch and switches away;
  `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.2 rule 3 then cannot
  resolve `branch-key` into an empty set, so rule 4 appends `-2` and the run
  duplicates its own branch. The reason keyless is right on the other route is
  untouched: it is about not stacking a *new* PRD on another PRD's branch, and a
  BRD-route run reusing the branch it opened for **this** BRD key is not that.

**The contributed key is a folder identity, and contributing it widens no tracker
identity.** This set exists to match branch names in §3.5 and nothing else; a
three-segment slice key is matched here exactly as a two-segment one is (§3.5,
*A two-segment key resolves exactly as it did before*). `jira_key` is minted by
the Jira round-trip, stays two-segment, and is not written by this route's
authoring phase at all.

**This run key set is the preflight's, and only the preflight's.** It exists to
match branches in §3.5 and is resolved at the *start* of the run.
`commit-artifacts` resolves its own key independently — a single key, at the
*end* of the run (§4 step 4) — by which point a command that started keyless may
well have one. A run that is keyless here is not thereby committing under
`NOISSUE`.

### 3.3 Stage 1 — guards

**Any match ends the preflight; the run proceeds.** Every guard emits the §5
notice, never a quiet line.

| # | State | Action |
|---|---|---|
| G0 | **HEAD is detached** | **Hand off, and set `specs_git: blocked` for the whole run** — `commit-artifacts` (§4) must also skip. §5 notice at **blocking** severity. See §3.7. |
| G1 | Any dirty **OTHER** path (§2.1) | **Hand off** — no commit, no branch switch, no push. §5 notice at **advisory** severity, listing the paths. Those files are not the plugin's, and switching branches would carry them. **This does NOT set `specs_git: blocked`**: the terminal `commit-artifacts` still runs, because it stages only artifact paths and is safe beside unrelated dirt. Losing the artifacts to protect files the step never touches would be the worse failure. |
| G2 | On a **named** branch that is neither the default branch nor a match for `^(idea\|prd\|ard\|spec\|design\|ready\|brd)/` | **Leave it; stay on it.** §5 notice at **advisory** severity, naming the branch, so the user knows where this run's artifacts will land. The commit is safe — a named branch cannot be lost — so `commit-artifacts` proceeds. The plugin manages only branches it created (§2.2). |

### 3.4 Stage 2 — flush leftovers

Always runs when stage 1 matched nothing.

- **Dirty ARTIFACT paths exist** → commit them **onto the current branch** (they
  belong to the run that wrote them) and push, per §4 steps 2–6.
- **No dirty ARTIFACT path** → check whether the current branch is **ahead of
  its upstream** and every ahead-commit touches only §2.1 artifact paths. If so,
  **retry the push**. Without this, a push that failed in a previous run leaves
  a local commit that nothing ever retries — the original defect, re-created one
  layer up.

Either way, continue to stage 3 with a clean tree.

### 3.5 Stage 3 — branch disposition

First matching row applies.

| # | State | Action |
|---|---|---|
| B1 | On the default branch | Nothing further. |
| B2 | Plugin branch, and `git -C "$SPECS_PATH" merge-base --is-ancestor HEAD origin/<default>` succeeds (already merged upstream) | Switch to default, `git -C "$SPECS_PATH" pull --ff-only`, `git -C "$SPECS_PATH" branch -d <branch>`. If `-d` fails, report and skip — **never `-D`**. If `pull --ff-only` fails (the local default branch has diverged), report and continue on default **without** pulling — never merge, rebase, or reset. |
| B3 | Plugin branch, unmerged, `branch-key` (below) resolves the branch to **any** key in the run key set (§3.2) | **Stay on it.** See §3.6. |
| B4 | Plugin branch, unmerged, `branch-key` resolves the branch to **no** key in the set, or the set is empty (keyless run) | Switch to default, `git -C "$SPECS_PATH" pull --ff-only`. **Leave the branch and its pull request alone.** Report the branch name. |

**Branch key resolution — `branch-key <branch>`.** The branch's key is resolved
*against the run key set*, by testing the keys the run already holds. It is never
extracted from the branch name as free text.

1. Strip the `idea/`, `prd/`, `ard/`, `spec/`, `design/`, `ready/`, or `brd/`
   prefix. Call the remainder `R`. No prefix matches → not a plugin branch, and
   no row here applies (§3.3 G2 already kept the run on it).
2. A key `K` in the run key set (§3.2) is a **candidate** when `R` is exactly `K`,
   or `R` begins with `K-` or `K_`. **The separator is required.** It is the same
   boundary folder resolution uses (`<KEY>{-|_}<slug>`,
   `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), and a branch name is
   built from the resolved folder's name rather than re-derived
   (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.2), so the two agree by
   construction.
3. **The longest candidate wins**, so a run that holds both a key and a longer key
   extending it resolves the branch to the one the branch was actually named for.
4. No candidate → the branch matches no key in the set (B4). An empty set (a
   keyless run) can produce no candidate, which is the same B4 its own row already
   states.

**Why this is a resolution and not an extraction.** Every candidate is a key the
run *already holds*, so nothing in the branch name can become a key — slug text
included. `spec/PRODUCT-1234-2fa-rollout` on a run keyed `PRODUCT-1234` resolves to
`PRODUCT-1234`, because `2fa-rollout` was never a key and so was never a candidate.
A regex over free text has no such anchor, and both plausible ones fail: the narrow
`[A-Z][A-Z0-9_]*-[0-9]+` reads `EPIC-008` out of `ard/EPIC-008-01-<slug>` and sends
a resumed slice run to B4 to duplicate its own branch, while the obvious widening to
`[A-Z][A-Z0-9_]*(-[0-9]+)+` reads `PRODUCT-1234-2` out of that same
`spec/PRODUCT-1234-2fa-rollout` — a slug beginning with a digit captured as a key
segment. Step 2's required separator forecloses that second failure even for a run
that genuinely holds `PRODUCT-1234-2`: there `PRODUCT-1234-2` is followed by `f`,
not by `-` or `_`, so it is not a candidate, and `PRODUCT-1234` still is.

**A two-segment key resolves exactly as it did before.** For a run keyed
`PRODUCT-1234`, `prd/PRODUCT-1234-<slug>` was extracted as `PRODUCT-1234` and is the
single candidate here; a branch named for some other key matched nothing then and
has no candidate now. The rule never asks how many segments a key carries, which is
why a three-segment slice key needs no special case — `addressing.md` §1's
"shape is not depth" holds here too — and why nothing above has to change when a
key grammar widens again.

**No auto-merge, deliberately.** No row above creates a merge commit or merges a
branch into the default branch, and none should be added. The routing here
already resolves every case, and an auto-merge would push an unreviewed PRD or
ARD past the very pull request the command opened for it one phase earlier. B2
handles the only case where a merge would otherwise be needed — a branch already
merged upstream — with cleanup instead. If auto-merge is ever wanted, it slots
into B4 as `merge --ff-only → push → branch -d`, with B3 unchanged.

### 3.6 Why B3 exists — do not "simplify" it away

B3 looks redundant next to B4 and is the obvious candidate for a future simplification into "always return to the default branch." **That simplification is a bug.**

B3 now exists for two reasons.

**First, same-phase resume.** `phase-handoff.md`'s `require-on-main` (§3) has a state — row B — that *passes* when the artifact is on the default branch but the worktree copy differs because the current branch is one this run itself owns: `/design` amends `specification.md` on its own `design/<EPIC>-<eslug>` branch, so a re-run of `/design` legitimately finds that copy has diverged from what merged earlier. B3 is what keeps the repo on that branch in the first place, and that is what makes row B reachable at all. If the preflight instead fell through to B4 and switched to the default branch, `/design`'s in-progress amendments would be left behind on a branch nobody is standing on, and row B — built to pass on exactly this divergence — would never see the case it exists for.

**Second, `/ready`'s explicit checkout.** The user may choose to proceed on the current checkout rather than switch to the default branch. Switching off it mid-run while the readiness report still claims that checkout is the one that was read would make the report false.

**The same shape reaches Epic-scoped runs — which is why §3.2 resolves a key *set*, not a single key.** `/specify <PRD> <Epic>` authors `specification.md` on `spec/<EPIC>-<eslug>`, a branch keyed by the **Epic**. The follow-up `/design <PRD> <Epic>` run resolves the PRD as its primary key, so a single-key comparison would read branch key ≠ run key, fall through to B4, and switch away from the branch holding the very `specification.md` `/design`'s resume depends on — the same reachability loss described above, one key earlier in the chain. Matching the branch key against **any** key in the set keeps B3 in force for the `<PRD> <Epic>` invocations (`/create-ard`, `/specify`, `/design`, `/ready`) exactly as it holds for PRD-scoped ones.

The failure this section used to defend against — `/create-ard` continuing silently against the wrong source when the authored PRD file existed only on an unmerged branch — is now caught loudly instead: `phase-handoff.md` §3.3 rows D and E stop that run rather than letting it proceed, so the defense moved there.

B3 keeps the working tree containing the artifact the run is about to read or amend. The cost is that the follow-up command's own branch is cut from the earlier branch rather than from the default — a stacked branch. That is correct: an ARD genuinely depends on its PRD and a design on its spec, and stacking is the honest representation.

### 3.7 Detached HEAD is blocking, not merely skipped

G0 is the one state where the plugin refuses to commit at all, and it is a
data-loss guard rather than a courtesy.

A commit made on a detached HEAD is reachable from no ref. Nothing points at it,
`git branch` will not list it, and it is eligible for garbage collection. If
`commit-artifacts` committed there, the run would report a short SHA and a
success line while the artifacts were already on their way to being
unrecoverable — the worst possible failure shape, because it looks like success.

So G0 propagates: it sets `specs_git: blocked` for the whole run,
`commit-artifacts` gates on that flag (§4 step 1), and the §5 notice fires at
**blocking** severity at both ends of the run. The artifacts stay in the working
tree, uncommitted and intact, and the notice gives the exact command to attach
them to a branch.

**This is the only condition that disables the terminal commit.** In particular
G1 does not — see the note in its row.

## 4. `commit-artifacts` — terminal step

Runs as the **last action of the run**, after `resume.md` is written (where the
command writes one) and before or as the run's last printed output (§6).

**The one exception — a phase that cedes control.** Where a later phase hands the
session to another skill, or opens an open-ended interactive stretch, this step
runs immediately **before** that hand-off instead, and prints its §6 outcome line
there. `/prompt-brainstorm` (whose Phase 3 hands off to
`superpowers:brainstorming`) and `/prompt-grill-me` (whose Phase 3 is a long
interactive grill) are the cases. "Last" is protective only while the run still
reaches its own end: a commit placed after control has left the command never
executes, and the artifacts it was meant to persist are stranded uncommitted —
the exact loss this reference exists to prevent. The exception is deliberately
narrow. It applies where control genuinely leaves the command, never as a
convenience to commit early, and it never licenses splitting the step across more
than one invocation.

1. **Gate.** All of §3.1's environment conditions, **plus** the run must not
   carry `specs_git: blocked` from §3.3 G0.
   - Fails on path / repo / permission grounds → **silent no-op**, matching the
     emission ladders' silent-skip discipline. Nothing committed, nothing
     reported, run unaffected.
   - Fails on `specs_git: blocked` → **not silent**: re-emit the §5 blocking
     notice. The repo *is* managed; the plugin is deliberately refusing to
     commit, and the user must know.
2. **Enumerate and stage** per §2.1. OTHER paths are never staged.
3. **Nothing staged** (the gate passed but no artifact path is dirty) → no
   commit; emit the §6 `nothing to commit` outcome line. This is distinct from
   step 1's silence — here the specs repo *is* managed and simply had nothing
   new.
4. **Commit.** Message:
   `<KEY> Add dev-workflows session artifacts (<command>)`, or
   `NOISSUE Add dev-workflows session artifacts (<command>)` when the run
   resolved no key. This matches the specs repo's own `<KEY|NOISSUE> <summary>`
   convention. **No `Co-Authored-By` trailer** (§1 rule 6).
5. **Push** to the current branch's upstream. If the branch has no upstream:
   `git -C "$SPECS_PATH" push -u origin <branch>`.
6. **Failure at any step is reported, never fatal.**
   - No remote / auth failure → report; the commit stays local. §3.4 retries the
     push on the next run.
   - **Non-fast-forward rejection** → report; **never force-push**, never
     auto-rebase mid-run. The commit stays local; §3.4 retries.
   - **`index.lock` present** (a concurrent session holds the repo) → report and
     skip; **never delete a lock file**. The artifacts stay in the working tree
     and the next run's preflight flushes them.
7. **Emit the §6 outcome line**, plus the full §5 notice repeated verbatim when
   a guard fired at §3.3.

### 4.1 Where the commit lands

- **A command that opened a specs-repo branch at handoff** (`/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/design`, `/implement`, `/ready`, and every `/brd-*` command) — on that `idea|prd|ard|spec|design|ready|brd/*` branch, so the push updates the pull request already open. Two commits on one branch: the deliverable, then the artifacts. Every `/brd-*` command opens on the shared `brd` prefix (`phase-handoff.md` §2.9), so a later `/brd-*` run that reuses the branch a prior phase of the same BRD opened lands there rather than on the default branch.
- **The same command when the user declined git at handoff** ("just write the
  files — I'll handle git") — the repo is still on the default branch and the
  deliverable is uncommitted there. `commit-artifacts` still runs and commits
  **only** the bookkeeping paths; the uncommitted deliverable is untouched,
  because it is an OTHER path. This is deliberate: "I'll handle git" refers to
  the deliverable, and the bookkeeping still has to reach the maintainer. The
  outcome line states plainly that the deliverable remains uncommitted.
- **Every other command** — on the default branch, unless §3.3 G2 left the run
  on a branch the plugin does not manage, or §3.5 B3 kept it on a plugin branch
  keyed to this run. The commit follows the branch the preflight settled on; it
  never switches.

## 5. Notice contract — the guards must be impossible to overlook

A guard fires precisely when the plugin has decided **not** to do something the
user is relying on. A single dim line in a long run is how that becomes a silent
loss, so every guard emits a structured block rather than a sentence, at both
the point of detection and again in the run's last printed output.

Every notice carries four parts, in this order:

1. **What was found** — the concrete state, with the branch name, the file
   count, or the path list. Never "an issue was detected".
2. **What the plugin did NOT do** — stated as the consequence for the user's
   data.
3. **The exact commands to resolve it**, ready to paste, with `$SPECS_PATH`
   already substituted.
4. **What happens if it is ignored** — one clause.

Severities: **blocking** (G0 — the terminal commit will not run) and **advisory**
(G1, G2 — the commit still runs, but somewhere the user should know about). Both
use the same four-part shape; only the wording of part 2 differs.

The `Specs repo:` emission (§6) **repeats the notice in full** when a guard
fired. A notice printed only at Phase 0 of a long run is a notice the user has
scrolled past by the time the run ends.

**G0 — blocking:**

```
⚠ SPECS REPO — THIS RUN'S ARTIFACTS WILL NOT BE COMMITTED

Found:    <SPECS_PATH> is on a detached HEAD (<sha7>), not on a branch.
Not done: this run's feedback, cost, follow-ups, and resume pointer will NOT be
          committed and will NOT reach the plugin maintainer. A commit made here
          would be reachable from no branch and eligible for deletion by git's
          garbage collector, so the plugin refuses to make one.
Fix:      git -C "<SPECS_PATH>" switch -c rescue/<YYYY-MM-DD>
          # or, to rejoin an existing branch:
          git -C "<SPECS_PATH>" switch <branch>
If ignored: the artifacts stay in your working tree, uncommitted and intact; the
          next run's preflight picks them up once HEAD is on a branch.
```

**G1 — advisory:**

```
⚠ SPECS REPO — UNCOMMITTED FILES THAT ARE NOT THE PLUGIN'S

Found:    <SPECS_PATH> has <N> uncommitted change(s) outside the plugin's
          artifact area: <path list>
Not done: the preflight did not commit, switch branches, or push. Those files
          are yours, and switching branches would carry them along. This run's
          own artifacts WILL still be committed at the end of the run —
          commit-artifacts stages only the §2.1 artifact paths.
Fix:      git -C "<SPECS_PATH>" status
          git -C "<SPECS_PATH>" add <path list> && git -C "<SPECS_PATH>" commit
If ignored: nothing is lost — your files stay uncommitted, and this run's
          artifacts are committed alongside them.
```

**G2 — advisory:**

```
⚠ SPECS REPO — ON A BRANCH THIS PLUGIN DID NOT CREATE

Found:    <SPECS_PATH> is on branch `<branch>`, which is neither the default
          branch (`<default>`) nor a plugin branch (idea/ prd/ ard/ spec/
          design/ ready/ brd/).
Not done: the preflight did not switch away from it — the plugin manages only
          branches it created. This run's artifacts WILL be committed, on
          `<branch>`.
Fix:      # only if that is the wrong place for them:
          git -C "<SPECS_PATH>" switch <default>
If ignored: the artifacts land on `<branch>` and reach the maintainer when that
          branch is merged or pushed.
```

## 6. The outcome line

`commit-artifacts` step 7 emits exactly one of these, prefixed `Specs repo:`.
The caller places it per its own contract (§7) — inside its final report where
the report is the run's last output, or as its own terminal block where the
report was composed earlier.

| Case | Line |
|---|---|
| Committed and pushed | `Specs repo: committed <sha7> (<N> files) on <branch> — pushed` |
| Committed, push failed | `Specs repo: committed <sha7> (<N> files) on <branch> — push FAILED (<reason>); the commit is local and the next run retries it` |
| Nothing to commit | `Specs repo: no session artifacts to commit` |
| Locked | `Specs repo: skipped — another session holds the repo (index.lock); the next run picks the artifacts up` |
| Blocked (G0) | `Specs repo: NOT COMMITTED — see the notice below`, followed by the §5 G0 block verbatim |
| Gate failed on environment | *(no line at all — silent no-op)* |

When a guard fired at §3.3 G1 or G2, the outcome line is followed by that
guard's §5 block, repeated verbatim.

When the deliverable is still uncommitted because the user declined git at
handoff (§4.1), append to the line:
`; the deliverable at <path> remains uncommitted, as you asked`.

## 7. Caller contract

A command that writes anything into `$SPECS_PATH` must do all four of these.
Omitting any one of them is a defect, not a style choice.

1. **Cite and execute `specs-preflight` (§3)** as early as `$SPECS_PATH` is
   known — Phase 0 in most commands. Carry any returned `specs_git: blocked`
   flag for the whole run.
2. **Cite and execute `commit-artifacts` (§4)** as the last action of the run,
   after `resume.md` (where one is written) and after the cost phase — or, where
   a later phase cedes control to another skill or to an open-ended interactive
   stretch, immediately before that hand-off (§4's exception).
3. **Emit the §6 outcome line exactly once**, wherever `commit-artifacts`
   ran — at the end of the run, or immediately before the hand-off in the
   cede-control case above.
4. **Never restate this reference's rules** — cite the section number. A rule
   copied into a command is a rule that goes stale.

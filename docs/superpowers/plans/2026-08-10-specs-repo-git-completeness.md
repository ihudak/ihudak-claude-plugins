# Specs-repo git completeness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the specs repo self-maintaining — every `dev-workflows` run flushes leftovers and settles the branch at its start, and commits + pushes its own bookkeeping artifacts at its end, so feedback / cost / follow-ups / resume pointers reach the plugin maintainer without a hand-written housekeeping commit.

**Architecture:** One new shared reference, `references/specs-repo-git.md`, owns two entry points — `specs-preflight` (run start) and `commit-artifacts` (terminal step) — in the plugin's established `emit-*` idiom: the reference owns the gates, the bounded write authority, the branch policy, and the failure discipline; the command cites it and executes its steps inline. Seventeen command files gain one preflight citation each (18 commit citations — `document.md` shares one Phase 0 across two modes but needs a commit step in each). Ten commands move their `resume.md` write to after their cost phase so the canonical terminal order holds. The ~50 `NEVER commits` assertions across the command set are reconciled in one concentrated sweep.

**Tech Stack:** Prompt-markdown. The "code" is instruction text an LLM executes at run time. **There is no build and no test framework.** Verification is grep, diff, and reading — see each task's verification steps and the plan-wide V1–V13 table in §Verification.

**Source spec:** `docs/superpowers/specs/2026-08-10-specs-repo-git-completeness-design.md` (approved, commit `ba70c9b`).

**One spec section has since been overtaken by events.** §2.1's non-goal — "the stale model references are not refreshed here… Tracked as a separate pass" — describes a pass that has now shipped, as 2.44.1 / 2.14.1. The five `Co-Authored-By` trailers it names already read `Claude Opus 5`, and `references/model-routing/classification.md` already tops its chain at `claude-opus-5`. This plan adds no sixth trailer site (the artifact commit carries no trailer at all — Global Constraint G-5), so the non-goal still holds; there is simply nothing left to defer.

---

## Global Constraints

Every task's requirements implicitly include this section.

**G-1 — `git -C` always, `cd` never.** Every git invocation written anywhere in this change is `git -C "$SPECS_PATH" …`. The working directory is NEVER changed. Eight of the seventeen commands are operating inside a *different* repository (code or docs) when these entry points fire.

**G-2 — Bounded paths.** Only these three shapes are ever staged, and `git add -A` is never issued at repository scope:

```
<specs-root>/{specs|specifications|vis}/**/dev-workflows/**
<specs-root>/dev-workflows-feedback/**
<specs-root>/dev-workflows-cost/**
```

**G-3 — Bounded branches.** Only `^(vi|ard|spec|design)/` branches are the plugin's to switch away from or delete.

**G-4 — Never destructive, never fatal.** No `push --force`, no `push -f`, no `branch -D`, no `merge`, no `rebase`, no `reset`, never delete an `index.lock`. Every failure is reported; the run continues.

**G-5 — No `Co-Authored-By` trailer** on the artifact commit.

**G-6 — Prose is hard-wrapped in reference and command source files** (~78 columns), matching `references/feedback-emission.md`. `references/prose-formatting.md` governs command *output*, not command source.

**G-7 — Target versions:** canonical `dev-workflows` 2.44.1 → **2.45.0**; mgd 2.44.1 → **2.45.0**; copilot 2.14.1 → **2.15.0**. (The spec says 2.44.0 → 2.45.0; 2.44.1 shipped in between as the model-reference refresh. 2.45.0 is unchanged.)

**G-8 — The three repos:**

| Repo | Edition | Reference path | Command path | Citation form |
|---|---|---|---|---|
| `/workspace/ihudak-claude-plugins` | canonical | `plugins/dev-workflows/references/` | `plugins/dev-workflows/commands/<name>.md` | `${CLAUDE_PLUGIN_ROOT}/references/<ref>.md` |
| `/workspace/mgd-claude-plugins` | content-verbatim except 5 identity files | same | same | same |
| `/workspace/ihudak-copilot-plugins` | adapted dialect | `dev-workflows/skills/_shared/` | `dev-workflows/skills/<name>/SKILL.md` | `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<ref>.md` |

**G-9 — Copilot edition has no cost subsystem at all.** No `cost-emission.md`, zero `emit-cost` references, no `session-cost.py`. Its artifact set is **feedback + follow-ups + `resume.md`**, and the `dev-workflows-cost/**` path shape is **omitted** from that edition. `-A` staging still applies (a user can delete a feedback or follow-up file between runs). Copilot also has no `/statusline`.

**G-10 — Canonical terminal order** (`references/session-hygiene.md` §1 becomes its authority):

> deliverable + handoff → feedback → follow-ups → cost → `resume.md` → `commit-artifacts` → the run's last printed output

**G-11 — The outcome-line placement rule (deviation from spec §8.3 — read this).** Spec §8.3 says all 18 `Specs repo:` lines go in "the final-report template". That is only true where the final report is genuinely the last thing the command prints. Six commands (7 sites) compose their Final Report *before* their terminal follow-up/cost phases, which already print their own output afterwards. So:

- **Report-template sites (8)** — the command has a report section that is genuinely the last thing it prints, and `commit-artifacts` runs *before* it. The **report template** carries the `Specs repo:` line: `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `/idea`, `/feedback`, `/prompt`.
- **Terminal-block sites (10)** — either the report was composed before the terminal phases, or the command has no report section at all. `commit-artifacts` **prints its own `Specs repo:` block** as the run's final output, exactly as the follow-up and cost phases already do: `/epics`, `/ready`, `/release-notes`, `/implement`, `/document` (Jira), `/document` (direct), `/vuln`, `/upgrade`, `/prompt-brainstorm`, `/prompt-grill-me`.

Either way there is exactly **one** `Specs repo:` emission per command, at the end of the run, and V5 stays a hard count of 18.

**G-12 — Every `resume.md` write moves to the end of its command's cost phase**, immediately before `commit-artifacts` — all **ten** commands that write one, not just the eight the spec §7 table lists as violating. `/design` and `/specify` write theirs inside the Final report, which is *after* cost but *after* `commit-artifacts` would run; leaving them there would commit a stale or absent `resume.md`. The printed `### Context hygiene` block keeps its `/compact` | `/clear` | `/rename` suggestion and stops carrying the write instruction.

**G-13 — Verbatim citation snippets.** Where a task says "insert the preflight citation" or "insert the commit citation", it means the exact text given in that task's steps. Do not paraphrase; the sweep in Task 8 and the V2–V5 counts depend on the literal strings `specs-repo-git.md`, `specs-preflight`, `commit-artifacts`, and `Specs repo:`.

---

## File Structure

**Created (3 files, one per edition):**

- `plugins/dev-workflows/references/specs-repo-git.md` (canonical) — the whole mechanism
- `/workspace/mgd-claude-plugins/plugins/dev-workflows/references/specs-repo-git.md` — verbatim copy
- `/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/specs-repo-git.md` — dialect-adapted, cost paths removed

**Modified, canonical (per repo, mirrored to mgd verbatim):**

| File | Responsibility of the change |
|---|---|
| `references/session-hygiene.md` | §1 terminal order + the resume-write relocation rule |
| `references/feedback-emission.md` | the "reaches the maintainer" sentence is now satisfied; `:182` cross-reference |
| `references/cost-emission.md` | `:334` cross-reference |
| `references/followup-emission.md` | `:183` cross-reference |
| `commands/create-vi.md` `update-vi.md` `create-ard.md` `specify.md` `design.md` | class A wiring |
| `commands/idea.md` `epics.md` `ready.md` `release-notes.md` `implement.md` `document.md` | class B pipeline wiring |
| `commands/vuln.md` `upgrade.md` | class B non-pipeline wiring |
| `commands/feedback.md` `prompt.md` `prompt-brainstorm.md` `prompt-grill-me.md` | class C wiring |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (repo root), `CHANGELOG.md`, `README.md`, `CLAUDE.md` (repo root) | release + docs |

**Modified, copilot:** the same 17 skills under `dev-workflows/skills/<name>/SKILL.md`, the three sibling `_shared/` references (no `cost-emission.md`), `dev-workflows/.plugin/plugin.json`, `.github/plugin/marketplace.json`, `.github/copilot-instructions.md`, `dev-workflows/README.md`, `dev-workflows/CHANGELOG.md`.

---

## Task Sequence

| # | Task | Repo |
|---|---|---|
| 1 | Create `references/specs-repo-git.md` | canonical |
| 2 | Sibling reference updates (`session-hygiene`, `feedback-`, `cost-`, `followup-emission`) | canonical |
| 3 | Class A wiring — `/create-vi` `/update-vi` `/create-ard` `/specify` `/design` | canonical |
| 4 | Class B wiring part 1 — `/idea` `/epics` `/ready` | canonical |
| 5 | Class B wiring part 2 — `/release-notes` `/implement` `/document` (both modes) | canonical |
| 6 | Class B non-pipeline — `/vuln` `/upgrade` | canonical |
| 7 | Class C — `/feedback` `/prompt` `/prompt-brainstorm` `/prompt-grill-me` | canonical |
| 8 | The `NEVER commits` reconciliation sweep (all 17 files, one implementer) | canonical |
| 9 | Release: version, catalog, CHANGELOG, README, CLAUDE.md | canonical |
| 10 | mgd port | mgd |
| 11 | copilot: reference + siblings | copilot |
| 12 | copilot: 17 skills wiring + sweep | copilot |
| 13 | copilot: release | copilot |

---

### Task 1: Create `references/specs-repo-git.md`

**Files:**
- Create: `plugins/dev-workflows/references/specs-repo-git.md`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: two entry-point names every later task cites — **`specs-preflight`** (§3) and **`commit-artifacts`** (§4) — plus the section numbers callers cite: `§2.1` (bounded paths), `§3.3 G0` (the `specs_git: blocked` flag), `§4` (the commit step), `§5` (the notice contract), `§6` (the outcome line). Later tasks cite these numbers literally; do not renumber.

- [ ] **Step 1: Write the file**

Create `plugins/dev-workflows/references/specs-repo-git.md` with exactly this content:

````markdown
# Specs-repo git — Shared Reference

Single source of truth for the two git entry points the plugin runs against the
**specs repo** (`$SPECS_PATH`). Every command that writes a bookkeeping artifact
there cites this file and executes its steps inline. The orchestrator owns any
printed output; this reference owns the gates, the bounded write authority, the
branch policy, and the failure discipline — the same shape as
`feedback-emission.md`, `cost-emission.md`, and `followup-emission.md`.

**Purpose.** The per-VI `dev-workflows/` area exists so feedback, cost,
follow-ups, and the resume pointer reach the **plugin maintainer**. They reach
the maintainer only if they are committed and pushed. The emitters deliberately
never commit — they run mid-run, often from inside someone else's repository,
and must never touch git. This reference supplies the two steps that close the
loop: a **run-start** flush and branch disposition (`specs-preflight`, §3) and a
**terminal** commit (`commit-artifacts`, §4).

**Scope.** ONLY the bounded artifact paths of §2.1, ONLY inside `$SPECS_PATH`.
Nothing here ever touches a code repo, a docs repo, the vault, or the current
working directory. Nothing here opens a pull request or calls a REST API —
`git push` is git-protocol, already sanctioned by `finish-and-handoff.md` §3.

## 1. Hard rules

1. **`git -C` always; `cd` never.** Every invocation is
   `git -C "$SPECS_PATH" …`. The working directory is NEVER changed. Most
   callers are running inside a *different* repository when these entry points
   fire; a `cd` would corrupt their git state.
2. **Bounded paths.** Only §2.1 paths are ever staged. `git add -A` is never
   issued at repository scope — always `git add -A -- <literal paths>`.
3. **Bounded branches.** Only branches matching `^(vi|ard|spec|design)/` are the
   plugin's to switch away from or delete (§2.2).
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
§9 pending, `followup-emission.md` §4 (the shared per-VI area),
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

`-A` is required, not optional: `cost-emission.md` §9 relocates a pending cost
file into a VI directory and then **deletes** the pending file. That deletion
must be staged, and plain `git add` would not stage it.

### 2.2 Branches

**The plugin manages only branches it created.** A branch is plugin-owned when
its name matches `^(vi|ard|spec|design)/`.

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

**Run key:** take the run's Jira key if it is already resolved at the call site;
otherwise the run is **keyless**. Both are correct behaviour — no command needs
to defer its preflight in order to obtain a key. `/create-vi` is structurally
keyless here (its key is minted by the Jira round-trip in a later phase), and
keyless is the right classification for it: a new VI must not stack on another
VI's branch.

### 3.3 Stage 1 — guards

**Any match ends the preflight; the run proceeds.** Every guard emits the §5
notice, never a quiet line.

| # | State | Action |
|---|---|---|
| G0 | **HEAD is detached** | **Hand off, and set `specs_git: blocked` for the whole run** — `commit-artifacts` (§4) must also skip. §5 notice at **blocking** severity. See §3.7. |
| G1 | Any dirty **OTHER** path (§2.1) | **Hand off** — no commit, no branch switch, no push. §5 notice at **advisory** severity, listing the paths. Those files are not the plugin's, and switching branches would carry them. **This does NOT set `specs_git: blocked`**: the terminal `commit-artifacts` still runs, because it stages only artifact paths and is safe beside unrelated dirt. Losing the artifacts to protect files the step never touches would be the worse failure. |
| G2 | On a **named** branch that is neither the default branch nor a match for `^(vi\|ard\|spec\|design)/` | **Leave it; stay on it.** §5 notice at **advisory** severity, naming the branch, so the user knows where this run's artifacts will land. The commit is safe — a named branch cannot be lost — so `commit-artifacts` proceeds. The plugin manages only branches it created (§2.2). |

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
| B3 | Plugin branch, unmerged, branch key **==** run key | **Stay on it.** See §3.6. |
| B4 | Plugin branch, unmerged, branch key **≠** run key, or run keyless | Switch to default, `git -C "$SPECS_PATH" pull --ff-only`. **Leave the branch and its pull request alone.** Report the branch name. |

**Branch key extraction:** strip the `vi/`, `ard/`, `spec/`, or `design/`
prefix, then take the leading token matching `[A-Z][A-Z0-9_]*-[0-9]+`. No match
→ treat as "not this run's key" (B4).

**No auto-merge, deliberately.** No row above creates a merge commit or merges a
branch into the default branch, and none should be added. The routing here
already resolves every case, and an auto-merge would push an unreviewed VI or
ARD past the very pull request the command opened for it one phase earlier. B2
handles the only case where a merge would otherwise be needed — a branch already
merged upstream — with cleanup instead. If auto-merge is ever wanted, it slots
into B4 as `merge --ff-only → push → branch -d`, with B3 unchanged.

### 3.6 Why B3 exists — do not "simplify" it away

B3 looks redundant next to B4 and is the obvious candidate for a future
simplification into "always return to the default branch." **That
simplification is a bug.**

A `/create-ard PRODUCT-13950` run following `/create-vi` finds the repo on
`vi/PRODUCT-13950-…` with an unmerged pull request. The authored VI file exists
**only on that branch**. Switching to the default branch removes it from the
working tree — and `/create-ard` reads the VI from
`$SPECS_PATH/specifications/<VI>-<vslug>/`, falling back to `jira-reader`
against the Jira export when the authored file is absent. **That fallback is
silent**: the run would quietly architect against the stale Jira export instead
of the VI just authored, with no error to notice.

B3 keeps the working tree containing the artifact the run is about to read. The
cost is that the follow-up command's own branch is cut from the earlier branch
rather than from the default — a stacked branch. That is correct: an ARD
genuinely depends on its VI, and stacking is the honest representation.

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

- **A command that opened a specs-repo branch at handoff** (`/create-vi`,
  `/update-vi`, `/create-ard`, `/specify`, `/design`) — on that
  `vi|ard|spec|design/*` branch, so the push updates the pull request already
  open. Two commits on one branch: the deliverable, then the artifacts.
- **The same command when the user declined git at handoff** ("just write the
  files — I'll handle git") — the repo is still on the default branch and the
  deliverable is uncommitted there. `commit-artifacts` still runs and commits
  **only** the bookkeeping paths; the uncommitted deliverable is untouched,
  because it is an OTHER path. This is deliberate: "I'll handle git" refers to
  the deliverable, and the bookkeeping still has to reach the maintainer. The
  outcome line states plainly that the deliverable remains uncommitted.
- **Every other command** — on the default branch.

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
          branch (`<default>`) nor a plugin branch (vi/ ard/ spec/ design/).
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
   after `resume.md` (where one is written) and after the cost phase.
3. **Emit the §6 outcome line exactly once**, at the end of the run.
4. **Never restate this reference's rules** — cite the section number. A rule
   copied into a command is a rule that goes stale.
````

- [ ] **Step 2: Verify the hard rules hold inside the file itself**

Run each and confirm the stated expectation:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# V7 — no `cd` anywhere
grep -n 'cd ' references/specs-repo-git.md          # expect: no output
# V8 — every `git add -A` is followed by ` -- ` on the same line
grep -n 'git add -A' references/specs-repo-git.md | grep -v ' -- '   # expect: no output
# V9 — no destructive verbs
grep -nE '\-\-force|push -f|branch -D' references/specs-repo-git.md  # expect: no output
# every git call carries -C "$SPECS_PATH"
grep -nE '`?git ' references/specs-repo-git.md | grep -v 'git -C "\$SPECS_PATH"' | grep -v 'git branch will not list\|git.s garbage'   # expect: only the `Fix:` blocks in §5, which already use git -C "<SPECS_PATH>"
```

The last check will surface the §5 `Fix:` lines that use the literal
`<SPECS_PATH>` placeholder rather than `$SPECS_PATH` — that is correct (they are
paste-ready commands for the user with the value substituted) and requires no
change. Everything else must carry `-C "$SPECS_PATH"`.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/specs-repo-git.md
git commit -m "feat(dev-workflows): add references/specs-repo-git.md

Owns the two specs-repo git entry points: specs-preflight (run start:
flush leftovers, retry an unpushed artifact commit, settle the branch)
and commit-artifacts (terminal: stage the bounded artifact paths, commit,
push). Bounded to three path shapes and to plugin-created branches;
never destructive, never fatal, never cd."
```

---

### Task 2: Sibling reference updates

**Files:**
- Modify: `plugins/dev-workflows/references/session-hygiene.md`
- Modify: `plugins/dev-workflows/references/feedback-emission.md`
- Modify: `plugins/dev-workflows/references/cost-emission.md`
- Modify: `plugins/dev-workflows/references/followup-emission.md`

**Interfaces:**
- Consumes: `references/specs-repo-git.md` from Task 1 — its entry-point names `specs-preflight` / `commit-artifacts` and its section numbers §2.1 / §3 / §4.
- Produces: `session-hygiene.md` §1's amended sentence, which Tasks 3–5 implement per command: the `resume.md` write moves out of the printed `### Context hygiene` block and becomes the last step of the command's cost phase.

- [ ] **Step 1: Amend `session-hygiene.md` §1's opening paragraph**

In `plugins/dev-workflows/references/session-hygiene.md`, replace this paragraph:

```markdown
At command finalization — AFTER the deliverable artifact is saved/committed and AFTER
`emit-cost` / feedback / follow-up, and BEFORE the printed suggestion — a VI-scoped run
writes/overwrites a **resume pointer**. It runs regardless of which suggestion (or none)
fires: **prepare always, suggest adaptively.**
```

with:

```markdown
At command finalization — AFTER the deliverable artifact is saved/committed, AFTER
`emit-cost` / feedback / follow-up, and BEFORE the terminal `commit-artifacts` step
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4) — a VI-scoped run
writes/overwrites a **resume pointer**. It runs regardless of which suggestion (or none)
fires: **prepare always, suggest adaptively.**

**The write is a step of the cost phase, not of the printed suggestion.** The
`### Context hygiene` block in a command's report carries the `/compact` | `/clear` |
`/rename` guidance only; the pointer itself is written as the last step of the command's
terminal cost phase, immediately before `commit-artifacts`. Several commands compose
their Final Report *before* their follow-up and cost phases run, so binding the write to
the printed block would put it before the cost entry it is supposed to follow — and
would leave it uncommitted, since `commit-artifacts` runs after cost. Prepare-first is
still satisfied: the write happens before the run ends, and therefore before the user
can act on the suggestion.
```

- [ ] **Step 2: Add the terminal order to `session-hygiene.md` §5 (Contract)**

In the same file, in `## 5. Contract (5 rules)`, replace rule 2:

```markdown
2. **Prepare-first** — the disk flush (resume pointer) always precedes the printed
   suggestion, so acting on it is safe. Prepare is unconditional (VI-scoped); only the
   suggestion is adaptive.
```

with:

```markdown
2. **Prepare-first** — the disk flush (resume pointer) always happens before the run
   ends, so acting on the printed suggestion is safe. Prepare is unconditional
   (VI-scoped); only the suggestion is adaptive. The canonical terminal order is:
   **deliverable + handoff → feedback → follow-ups → cost → `resume.md` →
   `commit-artifacts` → the run's last printed output**
   (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4).
```

- [ ] **Step 3: Amend the `feedback-emission.md` purpose paragraph**

In `plugins/dev-workflows/references/feedback-emission.md`, replace:

```markdown
maintainer can aggregate feedback across engineers. Feedback reaches the
maintainer only if it lands in the committed, pushed specs repo — hence the
persistence ladder is **specs-first** (§2).
```

with:

```markdown
maintainer can aggregate feedback across engineers. Feedback reaches the
maintainer only if it lands in the committed, pushed specs repo — hence the
persistence ladder is **specs-first** (§2), and hence every command's terminal
`commit-artifacts` step commits and pushes it
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4). This emitter still
never touches git itself (§6 caller contract); the commit is a separate,
bounded, end-of-run step.
```

- [ ] **Step 4: Cross-reference the three emitter "never commits" statements**

Each of these three sentences stays true of the *emitter* and must gain a
cross-reference so a reader does not conclude the artifacts are never committed
at all. Find each by its quoted text and append the sentence given.

In `feedback-emission.md`, the sentence containing `None of them commits` — append:

```markdown
 The artifacts are committed later, once, by the run's terminal `commit-artifacts` step (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4).
```

In `cost-emission.md`, the sentence containing `it NEVER commits` — append:

```markdown
 The cost entry is committed later, once, by the run's terminal `commit-artifacts` step (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4).
```

In `followup-emission.md`, the sentence containing `the phase NEVER commits` — append:

```markdown
 Follow-ups written into `$SPECS_PATH` are committed later, once, by the run's terminal `commit-artifacts` step (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4); vault-tier follow-ups stay the user's own sync responsibility.
```

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c 'specs-repo-git.md' references/session-hygiene.md      # expect: 3
grep -c 'specs-repo-git.md' references/feedback-emission.md    # expect: 2
grep -c 'specs-repo-git.md' references/cost-emission.md        # expect: 1
grep -c 'specs-repo-git.md' references/followup-emission.md    # expect: 1
grep -n 'BEFORE the printed suggestion' references/session-hygiene.md   # expect: no output
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/
git commit -m "feat(dev-workflows): wire the sibling references to specs-repo-git

session-hygiene.md §1 moves the resume.md write out of the printed
Context hygiene block and into the terminal cost phase, and §5 rule 2
states the canonical terminal order. The three emitters keep their
'never commits' statements — true of the emitter — and each now
cross-references the terminal commit-artifacts step."
```

---

### Task 3: Class A wiring — `/create-vi` `/update-vi` `/create-ard` `/specify` `/design`

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md`
- Modify: `plugins/dev-workflows/commands/update-vi.md`
- Modify: `plugins/dev-workflows/commands/create-ard.md`
- Modify: `plugins/dev-workflows/commands/specify.md`
- Modify: `plugins/dev-workflows/commands/design.md`

**Interfaces:**
- Consumes: the entry points `specs-preflight` (§3) and `commit-artifacts` (§4) from Task 1; the terminal-order rule from Task 2.
- Produces: the four-leg wiring pattern (preflight citation, `resume.md` relocation, commit citation, outcome line) that Tasks 4–7 repeat for the other twelve commands.

All five of these commands open a specs-repo branch at their handoff phase, so
their artifact commit lands on that branch and updates the already-open PR
(reference §4.1).

- [ ] **Step 1: Add the preflight citation to each command's Phase 0**

Append this block to the **end** of the `## Phase 0 — Resolve inputs` /
`## Phase 0 — Resolve input` section of each of the five files (i.e. immediately
before the `---` or the `## Phase 1` heading that follows it), verbatim:

```markdown
**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.
```

- [ ] **Step 2: Move the `resume.md` write out of the `### Context hygiene` block**

In each of the five files, find the `### Context hygiene` block and replace the
resume-write instruction, leaving the printed guidance intact. Each replacement
below is exact — old text on the left, new text on the right. Match the source
byte-for-byte, including the line wrapping.

**`create-vi.md`** — replace:

```markdown
Write/overwrite the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per
`session-hygiene.md` §1; the VI-Key is minted by the Jira round-trip, so **omit the
session-name line** and name the session manually if useful). Then:
```

with:

```markdown
The resume pointer is written in the terminal cost phase (Phase 7), per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — the VI-Key is minted by the
Jira round-trip, so it **omits the session-name line**; name the session manually if
useful. Then:
```

**`update-vi.md`** — replace:

```markdown
Write/overwrite the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then: continuing as PM → `/compact`; handing to PA/PE → `/clear`. Guidance only.
```

with:

```markdown
The resume pointer is written in the terminal cost phase (Phase 7), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then: continuing as PM → `/compact`; handing to PA/PE → `/clear`. Guidance only.
```

**`create-ard.md`** — replace:

```markdown
Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md`
§1). The next step hands off from PA to PE/Team, so:
```

with:

```markdown
The resume pointer is written in the terminal cost phase (Phase 8), per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. The next step hands off from PA
to PE/Team, so:
```

**`specify.md`** and **`design.md`** — replace, in each:

```markdown
Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:
```

with:

```markdown
The resume pointer is written in the terminal cost phase (Phase 9), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:
```

- [ ] **Step 3: Add the `resume.md` write + `commit-artifacts` to the terminal cost phase**

Append these two numbered steps to the **end** of each command's terminal cost
phase — `## Phase 7 — Session maintenance, feedback & cost` in `create-vi.md`
and `update-vi.md`, `## Phase 8 — Session maintenance, feedback & cost` in
`create-ard.md`, `## Phase 9 — Session cost` in `specify.md` and `design.md` —
after the existing final numbered step and **before** the trailing
`ADDITIVE — …` paragraph where one exists. Continue the existing numbering.

```markdown
N. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<VI-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the report.
N+1. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/<command>)` with no `Co-Authored-By` trailer, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.
```

Substitute the real numbers for `N` / `N+1`, and the real command name for
`/<command>` (`/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`).

- [ ] **Step 4: Add the `Specs repo:` line to each Final report**

Each of these five commands has a prose-style `## Final report` section that
lists what to report. Append this clause to that sentence, immediately before
the final `; and …` clause:

```markdown
; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full
```

For example, `create-ard.md`'s report sentence ends
`…; the feedback + cost paths; and the adaptive next-step recommendation.` and
becomes `…; the feedback + cost paths; the `Specs repo:` outcome line from
`commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6),
with any guard notice repeated in full; and the adaptive next-step
recommendation.`

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
for f in create-vi.md update-vi.md create-ard.md specify.md design.md; do
  echo "$f: preflight=$(grep -c 'specs-preflight' $f) commit=$(grep -c 'commit-artifacts' $f) line=$(grep -c 'Specs repo:' $f)"
done
# expect for each: preflight=1 commit>=1 line=1
# (commit-artifacts may appear more than once: the phase step plus the Context-hygiene
#  and Final-report cross-references. The *executable* citation must be exactly one —
#  confirm by reading, per the reference §7 caller contract.)
grep -n 'Write the resume pointer at' create-vi.md update-vi.md create-ard.md specify.md design.md   # expect: no output
grep -c 'resume.md' create-vi.md update-vi.md create-ard.md specify.md design.md   # expect: >=1 each
```

Then read each file's terminal cost phase and confirm the order is
**cost entry → `resume.md` → `commit-artifacts`**.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/
git commit -m "feat(dev-workflows): wire specs-repo git into the five VI-authoring commands

/create-vi /update-vi /create-ard /specify /design each gain a Phase 0
specs-preflight, a terminal commit-artifacts step, and the Specs repo:
outcome line in their Final report. The resume.md write moves out of the
printed Context hygiene block into the cost phase, so it lands after the
cost entry and before the commit that captures it."
```

---

### Task 4: Class B wiring part 1 — `/idea` `/epics` `/ready`

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md`
- Modify: `plugins/dev-workflows/commands/epics.md`
- Modify: `plugins/dev-workflows/commands/ready.md`

**Interfaces:**
- Consumes: the entry points and section numbers from Task 1; the terminal-order rule from Task 2; the four-leg wiring pattern from Task 3.
- Produces: the first use of the **terminal-block** outcome-line variant (Global Constraint G-11) — `/epics` and `/ready` compose their reports before their cost phase, so `commit-artifacts` prints its own `Specs repo:` block as the run's last output.

None of these three opens a specs-repo branch; their artifact commit lands on the
specs repo's default branch.

- [ ] **Step 1: Preflight citation**

Append verbatim to the end of the Phase 0 section of each file
(`## Phase 0 — Validate environment + resolve model routing` in `idea.md`,
`## Phase 0 — Load` in `epics.md`, `## Phase 0 — Resolve input` in `ready.md`):

```markdown
**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.
```

- [ ] **Step 2: `/idea` — commit step + Final report line**

`/idea` writes **no** `resume.md` (it is pre-VI and keyless — the skip list in
`session-hygiene.md` §1 names it), so it gets no resume relocation. Its
`## Final report` is the run's last output, so it is a **report-template** site.

Append this numbered step to the end of `## Phase 6 — Session maintenance,
feedback & cost`, after existing step 3 and **before** the trailing
`ADDITIVE — …` paragraph:

```markdown
4. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `NOISSUE Add dev-workflows session artifacts (/idea)` (this run is keyless — no VI-Key exists yet), and pushes. It NEVER touches a code/docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.
```

Then, in `## Final report`, append to the report sentence immediately before its
final `; and …` clause:

```markdown
; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full
```

- [ ] **Step 3: `/epics` — resume relocation, commit step, terminal block**

`/epics` composes its Final Report at Phase 9 and then runs Phase 10
(follow-ups) and Phase 11 (cost). It is a **terminal-block** site.

3a. In the Phase 9 report template's `### Context hygiene` block, replace:

```markdown
Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:
```

with:

```markdown
The resume pointer is written in the terminal cost phase (Phase 11), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:
```

3b. Append to the end of `## Phase 11 — Session cost`, after the existing prose
and **before** the trailing `ADDITIVE — …` paragraph:

```markdown
**Then write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<VI-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the Phase 9 report.

**Then commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/epics)`, and pushes to the specs repo's default branch. It NEVER touches the vault, `jira-products/`, `jira_export_root`, a code/docs repo, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Because the Phase 9 report was composed before this phase, **print its §6 outcome line here**, as the run's last output — prefixed `Specs repo:`, with any guard notice repeated in full.
```

- [ ] **Step 4: `/ready` — resume relocation, commit step, terminal block**

`/ready` writes its report at Phase 5 and then runs Phase 6 (maintenance +
feedback), Phase 7 (follow-ups), Phase 8 (cost). It is a **terminal-block** site.

4a. In the Phase 5 report template's `### Context hygiene` block, replace these
two lines (note the three-space indentation — the block sits inside a fenced
report template):

```markdown
   Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1;
   record the readiness verdict as a carry-forward line). Then:
```

with:

```markdown
   The resume pointer is written in the terminal cost phase (Phase 8), per
   `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1, recording the readiness
   verdict as a carry-forward line. Then:
```

4b. Append to the end of `## Phase 8 — Session cost`, before any trailing
`ADDITIVE — …` paragraph, the same two blocks as Step 3b with these
substitutions: `(Phase 11)` → `(Phase 8)`, `Phase 9 report` → `Phase 5 report`,
`(/epics)` → `(/ready)`, and drop the `jira-products/` / `jira_export_root`
clause (that is `/epics`-specific wording) in favour of: `It NEVER touches a
code/docs repo, the vault, or the current working directory`.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
for f in idea.md epics.md ready.md; do
  echo "$f: preflight=$(grep -c 'specs-preflight' $f) commit=$(grep -c 'commit-artifacts' $f) line=$(grep -c 'Specs repo:' $f)"
done
# expect for each: preflight=1, line=1
grep -n 'Write the resume pointer at' epics.md ready.md   # expect: no output
grep -n 'resume pointer is written in the terminal cost phase' epics.md ready.md   # expect: 1 each
grep -n 'resume' idea.md   # expect: only the existing "no resume pointer" note — /idea writes none
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/
git commit -m "feat(dev-workflows): wire specs-repo git into /idea, /epics, /ready

Each gains a Phase 0 specs-preflight and a terminal commit-artifacts
step. /epics and /ready compose their report before their cost phase, so
commit-artifacts prints its own Specs repo: block as the run's last
output and their resume.md write moves into the cost phase. /idea writes
no resume pointer (pre-VI, keyless) and reports in its Final report."
```

---

### Task 5: Class B wiring part 2 — `/release-notes` `/implement` `/document`

**Files:**
- Modify: `plugins/dev-workflows/commands/release-notes.md`
- Modify: `plugins/dev-workflows/commands/implement.md`
- Modify: `plugins/dev-workflows/commands/document.md`

**Interfaces:**
- Consumes: the entry points and section numbers from Task 1; the terminal-order rule from Task 2; the wiring pattern and the terminal-block variant from Tasks 3–4.
- Produces: the only **two-commit-sites-in-one-file** case — `document.md` has one shared Phase 0 preflight and two `commit-artifacts` steps, one per mode. This is what makes the plan-wide counts 17 preflight sites and 18 commit sites.

All three are **terminal-block** sites (G-11): the outcome line is printed by
`commit-artifacts` itself as the run's last output.

- [ ] **Step 1: Preflight citation (3 files, 3 sites)**

Append verbatim to the end of the Phase 0 section of each file. In
`release-notes.md` that is `## Phase 0 — Load`; in `implement.md`,
`## Phase 0 — Load and classify inputs`; in `document.md`,
`## Phase 0 — Load and dispatch` — **the Jira-mode Phase 0 only**. Do **not**
add a second preflight to `document.md`'s direct-mode
`## Phase 0 — Load the description`; instead add the one-line pointer in Step 5.

```markdown
**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. This runs against `$SPECS_PATH` only — `git -C "$SPECS_PATH"`, never a `cd`, so the code/docs repo this run is working in is untouched (§1 rule 1). Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.
```

- [ ] **Step 2: `/release-notes` — resume relocation + terminal steps**

2a. In the Phase 8 report template's `### Context hygiene` block, replace the
indented line:

```markdown
   Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:
```

with (same indentation):

```markdown
   The resume pointer is written in the terminal cost phase (Phase 11), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:
```

2b. Append to the end of `## Phase 11 — Session cost`, before any trailing
`ADDITIVE — …` paragraph:

```markdown
**Then write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<VI-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the Phase 8 report.

**Then commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/release-notes)`, and pushes to the specs repo's default branch. It NEVER writes into a docs repo — the release-note draft is untouched — NEVER touches a code repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Because the Phase 8 report was composed before this phase, **print its §6 outcome line here**, as the run's last output — prefixed `Specs repo:`, with any guard notice repeated in full.
```

- [ ] **Step 3: `/implement` — resume relocation + terminal steps**

3a. In the Phase 5 report template's `### Context hygiene` block, replace:

```markdown
Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:
```

with:

```markdown
The resume pointer is written in the terminal cost phase (Phase 7), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:
```

3b. Append to the end of `## Phase 7 — Session cost`, before any trailing
`ADDITIVE — …` paragraph, the same two blocks as Step 2b with these
substitutions: `(Phase 11)` → `(Phase 7)`, `Phase 8 report` → `Phase 5 report`,
`(/release-notes)` → `(/implement)`, and replace the docs-repo clause with:
`It NEVER writes into the code repo this run just changed — the implementation
commit and branch are untouched — NEVER touches a docs repo, the vault, or the
current working directory`.

Additionally, prefix the resume block with its mode guard, since `/implement`
direct mode writes no resume pointer:

```markdown
**Then write the resume pointer (Jira mode only).**
```

- [ ] **Step 4: `/document` Jira mode — resume relocation + terminal steps**

4a. In the Phase 9 report template's `### Context hygiene` block, replace:

```markdown
Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:
```

with:

```markdown
The resume pointer is written in the terminal cost phase (Phase 11), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:
```

4b. Append to the end of `## Phase 11 — Session cost` (the Jira-mode one, the
first of the two in this file), before any trailing `ADDITIVE — …` paragraph,
the same two blocks as Step 2b with these substitutions: `(Phase 11)` stays,
`Phase 8 report` → `Phase 9 report`, `(/release-notes)` → `(/document)`, and
replace the docs-repo clause with: `It NEVER writes into the docs repo this run
just changed — the documentation commit, branch, and PR are untouched — NEVER
touches a code repo, the vault, or the current working directory`.

- [ ] **Step 5: `/document` direct mode — Phase 0 pointer + terminal steps**

5a. Append to the end of the direct-mode `## Phase 0 — Load the description`:

```markdown
**Specs-repo preflight.** Already run — the shared Phase 0 dispatch executed `specs-preflight` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §3) before mode detection, and any `specs_git: blocked` flag it set is carried into this mode too. Do not run it a second time.
```

5b. `/document` direct mode writes **no** `resume.md` (`session-hygiene.md` §1
names Mode B in its skip list), so there is no resume relocation here. Append to
the end of the direct-mode `## Phase 7 — Session cost`, before any trailing
`ADDITIVE — …` paragraph:

```markdown
**Then commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/document)` — or `NOISSUE …` when this doc-edit run resolved no key — and pushes to the specs repo's default branch. It NEVER writes into the docs repo this run just changed, NEVER touches a code repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Because the Phase 5 report was composed before this phase, **print its §6 outcome line here**, as the run's last output — prefixed `Specs repo:`, with any guard notice repeated in full. No `resume.md` is written in this mode (`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 skip list).
```

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
for f in release-notes.md implement.md document.md; do
  echo "$f: preflight=$(grep -c 'specs-preflight' $f) line=$(grep -c 'Specs repo:' $f)"
done
# expect: release-notes.md preflight=1 line=1
#         implement.md    preflight=1 line=1
#         document.md     preflight=2 line=2   <- one is the direct-mode "already run" pointer
grep -n 'execute its `specs-preflight` entry point' document.md   # expect: exactly 1 (Jira-mode Phase 0)
grep -n 'commit-artifacts` entry point (§4) inline' document.md   # expect: exactly 2 (one per mode)
grep -n 'Write the resume pointer at' release-notes.md implement.md document.md   # expect: no output
```

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/
git commit -m "feat(dev-workflows): wire specs-repo git into /release-notes, /implement, /document

All three work inside a code or docs repo, so the preflight citation
states the git -C rule explicitly. Each composes its report before its
cost phase, so commit-artifacts prints its own Specs repo: block last
and the resume.md write moves into the cost phase. document.md shares
one Phase 0 preflight across both modes and carries a commit step in
each — the one file with two commit sites."
```

---

### Task 6: Class B non-pipeline — `/vuln` `/upgrade`

**Files:**
- Modify: `plugins/dev-workflows/commands/vuln.md`
- Modify: `plugins/dev-workflows/commands/upgrade.md`

**Interfaces:**
- Consumes: the entry points and section numbers from Task 1; the wiring pattern from Tasks 3–5.
- Produces: nothing later tasks depend on.

Neither command has a cost phase, a `resume.md`, or a `## Final report` heading.
Both persist feedback as the last step of their terminal phase, and both work
inside a **code repo** — so the `git -C` rule matters most here. Both are
**terminal-block** sites per G-11: there is no report template to carry the
line, so `commit-artifacts` prints its own `Specs repo:` block as the run's last
output — after `/vuln`'s feedback path, and after `/upgrade`'s step 9.

- [ ] **Step 1: `/vuln` — preflight**

Append to the end of `## Step 0 — Classify & Route (mandatory)`:

```markdown
**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. This runs against `$SPECS_PATH` only — `git -C "$SPECS_PATH"`, never a `cd`, so the code repo this run is about to branch and fix is untouched (§1 rule 1). Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.
```

- [ ] **Step 2: `/vuln` — terminal commit**

Append to the end of `## Step 4 — Summarise`, after the existing
`**Then persist plugin feedback (automatic).**` paragraph:

```markdown
**Then commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/vuln)` — or `NOISSUE …` when the run resolved no Jira key — and pushes to the specs repo's default branch. It NEVER touches the code repo this run just fixed: the CVE branches, commits, and PRs are the code repo's, made by `vuln-fixer`, and are untouched here. It NEVER force-pushes, NEVER fails the run, and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Print its §6 outcome line after the feedback path, prefixed `Specs repo:`, with any guard notice repeated in full. No `resume.md` is written for `/vuln` (`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 skip list — the durable state is the branch and PR).
```

- [ ] **Step 3: `/upgrade` — preflight**

`/upgrade` has no Phase 0. Insert a new section immediately **before**
`## Phase 1 — Compatibility Planning (no files changed)`:

```markdown
## Phase 0 — Specs-repo preflight

Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. This runs against `$SPECS_PATH` only — `git -C "$SPECS_PATH"`, never a `cd`, so the code repo this run is about to upgrade is untouched (§1 rule 1). Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

---
```

- [ ] **Step 4: `/upgrade` — terminal commit**

In `## Phase 2 — Execution (after user confirms)`, append a new numbered step
`10.` immediately after the existing step `9. **Persist plugin feedback
(automatic)** …`:

```markdown
10. **Commit session artifacts (terminal)** — Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/upgrade)` — or `NOISSUE …` when the run resolved no Jira key — and pushes to the specs repo's default branch. It NEVER touches the code repo this run just upgraded: the upgrade changes are left uncommitted on the current branch by `upgrade-executor`, exactly as before. It NEVER force-pushes, NEVER fails the run, and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Print its §6 outcome line as the run's last output, prefixed `Specs repo:`, with any guard notice repeated in full. No `resume.md` is written for `/upgrade` (`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 skip list).
```

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
for f in vuln.md upgrade.md; do
  echo "$f: preflight=$(grep -c 'specs-preflight' $f) commitsite=$(grep -c 'commit-artifacts` entry point (§4) inline' $f) line=$(grep -c 'Specs repo:' $f)"
done
# expect for each: preflight=1 commitsite=1 line=1
grep -n '^## Phase 0' upgrade.md   # expect: 1 (the new section)
grep -n 'left uncommitted on the current branch' upgrade.md   # expect: >=1 — the pre-existing invariant is preserved
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/
git commit -m "feat(dev-workflows): wire specs-repo git into /vuln and /upgrade

Both run inside a code repo, so each citation states the git -C rule and
names what stays untouched — /vuln's CVE branches and PRs, /upgrade's
uncommitted working tree. Neither writes a resume.md. /upgrade gains a
Phase 0 section; it had none."
```

---

### Task 7: Class C — `/feedback` `/prompt` `/prompt-brainstorm` `/prompt-grill-me`

**Files:**
- Modify: `plugins/dev-workflows/commands/feedback.md`
- Modify: `plugins/dev-workflows/commands/prompt.md`
- Modify: `plugins/dev-workflows/commands/prompt-brainstorm.md`
- Modify: `plugins/dev-workflows/commands/prompt-grill-me.md`

**Interfaces:**
- Consumes: the entry points and section numbers from Task 1.
- Produces: nothing later tasks depend on. This task completes the 17 preflight / 18 commit sites.

These four are pure emitters — they write one feedback entry through the
specs-first ladder and nothing else. They are also the commands that most
obviously needed this: the feedback entry recording *this very defect* had to be
committed by hand, by `/prompt`. None writes a `resume.md`.

- [ ] **Step 1: Add a Phase 0 to all four**

Insert this new section into each file immediately **before** its
`## Phase 1 — …` heading:

```markdown
## Phase 0 — Specs-repo preflight

Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. This runs against `$SPECS_PATH` only — `git -C "$SPECS_PATH"`, never a `cd`, so whatever repository you are standing in is untouched (§1 rule 1). Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag — the terminal `commit-artifacts` step skips on it.

---
```

- [ ] **Step 2: `/feedback` — commit step + report line**

Append to the end of `## Phase 3 — Persist`:

```markdown
**Then commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/feedback)` — or `NOISSUE …` when no `jira_key` resolved — and pushes. It NEVER touches a code/docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for Phase 4.
```

Then replace the whole of `## Phase 4 — Report`'s body:

```markdown
Surface the persisted path and any degradation notice (e.g. the tier-3 vault
warning, or tier-5 report-only). This command NEVER commits, and NEVER writes
into a docs/code repo or the current working directory.
```

with:

```markdown
Surface the persisted path and any degradation notice (e.g. the tier-3 vault
warning, or tier-5 report-only), then the `Specs repo:` outcome line from
`commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6),
with any guard notice repeated in full.

This command NEVER commits into a docs/code repo, the vault, or the current
working directory. The terminal `commit-artifacts` step commits ONLY
`$SPECS_PATH`'s bounded artifact paths
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
```

- [ ] **Step 3: `/prompt` — commit step + report line**

Append to the end of `## Phase 3 — Persist the corrective triple` the same
paragraph as Step 2, with `(/feedback)` → `(/prompt)` and
`Hold its §6 outcome line for Phase 4.` unchanged.

Then replace the whole of `## Phase 4 — Report`'s body:

```markdown
Surface the persisted path and any degradation notice. This command NEVER
commits, and NEVER writes into a docs/code repo or the current working directory
(only the correction itself edits your target files, as you requested).
```

with:

```markdown
Surface the persisted path and any degradation notice, then the `Specs repo:`
outcome line from `commit-artifacts`
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice
repeated in full.

This command NEVER commits into a docs/code repo, the vault, or the current
working directory — only the correction itself edits your target files, as you
requested, and those edits are never staged. The terminal `commit-artifacts`
step commits ONLY `$SPECS_PATH`'s bounded artifact paths
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
```

- [ ] **Step 4: `/prompt-brainstorm` — commit step before the hand-off**

`/prompt-brainstorm`'s Phase 3 hands control to `superpowers:brainstorming`, so
the commit must complete **before** that hand-off.

Append to the end of `## Phase 2 — Persist the corrective triple`, after the
existing `Surface the persisted path and any degradation notice.` sentence:

```markdown

**Then commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — before the Phase 3 hand-off, because the brainstorming skill takes over the session there. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/prompt-brainstorm)` — or `NOISSUE …` when no `jira_key` resolved — and pushes. It NEVER touches a code/docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Print its §6 outcome line here, prefixed `Specs repo:`, with any guard notice repeated in full.
```

Then replace the closing paragraph of `## Phase 3 — Hand off`:

```markdown
This command NEVER commits, and NEVER writes into a docs/code repo or the
current working directory.
```

with:

```markdown
This command NEVER commits into a docs/code repo, the vault, or the current
working directory. The Phase 2 `commit-artifacts` step commits ONLY
`$SPECS_PATH`'s bounded artifact paths
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
```

- [ ] **Step 5: `/prompt-grill-me` — commit step before the grill**

Append to the end of `## Phase 2 — Persist the corrective triple`, after the
existing `Surface the persisted path.` sentence, the same paragraph as Step 4
with `(/prompt-brainstorm)` → `(/prompt-grill-me)` and the clause `— before the
Phase 3 hand-off, because the brainstorming skill takes over the session there`
replaced with `— before the Phase 3 grill, which is interactive and may run
long`.

Then replace the closing sentence of `## Phase 3 — Grill the fix (inline)`:

```markdown
This command NEVER
commits, and NEVER writes into a docs/code repo or the current working
directory.
```

with:

```markdown
This command NEVER commits into a docs/code repo, the vault, or the current
working directory. The Phase 2 `commit-artifacts` step commits ONLY
`$SPECS_PATH`'s bounded artifact paths
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
```

Note the original sentence in this file wraps `This command NEVER` / `commits,`
across a line break — match the file exactly when replacing.

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
for f in feedback.md prompt.md prompt-brainstorm.md prompt-grill-me.md; do
  echo "$f: preflight=$(grep -c 'specs-preflight' $f) commitsite=$(grep -c 'commit-artifacts` entry point (§4) inline' $f) line=$(grep -c 'Specs repo:' $f)"
done
# expect for each: preflight=1 commitsite=1 line=1
# no unreconciled bare "NEVER commits," survives in these four:
for f in feedback.md prompt.md prompt-brainstorm.md prompt-grill-me.md; do
  tr '\n' ' ' < $f | grep -o 'NEVER *commits[^.]*' ; echo "  ^^ $f"
done
# every hit must read "NEVER commits into a docs/code repo, the vault, or the current working directory"
```

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/
git commit -m "feat(dev-workflows): wire specs-repo git into the four emitter commands

/feedback /prompt /prompt-brainstorm /prompt-grill-me each gain a Phase 0
specs-preflight and a commit-artifacts step at the end of their persist
phase — for the two that hand off or grill afterwards, deliberately
before that hand-off. Their NEVER-commits assertions are scoped to the
specs-repo carve-out rather than deleted."
```

---

### Task 8: The `NEVER commits` reconciliation sweep

**Files:**
- Modify: any of the 17 in-scope files under `plugins/dev-workflows/commands/` that the sweep finds, plus `plugins/dev-workflows/agents/*.md` if the sweep finds an assertion there.
- Do NOT modify: `plugins/dev-workflows/commands/statusline.md`, `api-guideline-reviewer.md`, `guideline-reviewer.md`, `docs-profile.md` — out of scope, and `/statusline` keeps its unscoped assertion because it writes only under `~/.claude/`.

**Interfaces:**
- Consumes: the wiring from Tasks 3–7 (some assertions were already reconciled there — those are done, leave them).
- Produces: a plugin with no internal contradiction. This is the last canonical content task; Task 9 releases it.

**Why this is one task and not seven.** Around fifty assertions state that a
phase or a whole command does not commit. Each becomes false or ambiguous the
moment `commit-artifacts` ships, and this plugin's own reviewers flag internal
contradiction. Splitting the sweep across implementers produces inconsistent
wording; one implementer holds one wording.

- [ ] **Step 1: Enumerate every hit, across every phrasing variant, whitespace-normalized**

A grep for `NEVER commits` finds most of them and **misses a whole tail** —
including two that wrap across a line break and defeat any line-level grep. Run
this and work from its output. Do **not** work from a hand-written file list.

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in commands/create-vi.md commands/update-vi.md commands/create-ard.md \
         commands/specify.md commands/design.md commands/idea.md \
         commands/epics.md commands/ready.md commands/release-notes.md \
         commands/implement.md commands/document.md commands/vuln.md \
         commands/upgrade.md commands/feedback.md commands/prompt.md \
         commands/prompt-brainstorm.md commands/prompt-grill-me.md; do
  hits=$(tr '\n' ' ' < "$f" | grep -o -iE '.{60}(NEVER +commits?|never +branches|NEVER +auto-commit|no branch, no commit|nothing +commits|Nothing is committed|git (is|management is) (the user.s|your) responsibility|the user manages git manually|never branches or commits).{80}')
  if [ -n "$hits" ]; then echo "===== $f"; echo "$hits"; fi
done
```

Also sweep the agents directory, which the spec's variant table did not cover
but which uses the same phrasings:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in agents/*.md; do
  hits=$(tr '\n' ' ' < "$f" | grep -o -iE '.{60}(NEVER +commits?|never +branches|NEVER +auto-commit|nothing +commits|Nothing is committed).{80}')
  if [ -n "$hits" ]; then echo "===== $f"; echo "$hits"; fi
done
```

Write the full enumeration to a scratch file and work through it row by row.

- [ ] **Step 2: Classify each hit — became false, or still true**

For each hit, decide which of two categories it is in. **Most stay.** This is
"check each assertion and scope the ones that became false", not "rewrite them
all".

**Still true — leave the text alone, but annotate in place with the reason.**
Examples of genuinely-still-true assertions:
- `/epics` never branches, and never commits its *drafts* — those go to the vault.
- An agent that writes files but runs no git at all.
- `never writes into jira-products/ / jira_export_root / the current working directory`.
- A statement scoped to a code repo or docs repo.

Annotate each of these by appending a short clause naming *why* it stayed true —
a bare label is not enough:

```markdown
 (still true — this phase writes into the vault, which `commit-artifacts` never touches; the specs-repo artifact area is committed separately, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1.)
```

**Became false — rewrite, scoped, never deleted.** The protective intent is
real; only the scope changed. Use this wording, adapted minimally to the
sentence it replaces:

```markdown
NEVER commits into a code/docs repo, the vault, or the current working directory. The terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
```

For an `ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER
writes into …` sentence, the minimal edit is to replace `NEVER commits, and` with
`NEVER commits anything itself, and`, then append to the paragraph:

```markdown
 The artifacts this phase writes are committed once, at the end of the run, by the terminal `commit-artifacts` step (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4).
```

- [ ] **Step 3: Handle the two line-wrapped hits explicitly**

`prompt.md` and `prompt-grill-me.md` wrap `This command NEVER` / `commits`
across a line break. Task 7 should already have replaced both. Confirm:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
for f in prompt.md prompt-grill-me.md; do
  echo "== $f"; tr '\n' ' ' < $f | grep -o 'This command NEVER *commits[^.]*\.'
done
# expect each to read: "This command NEVER commits into a docs/code repo, the vault, or the current working directory"
```

If either still reads as the old unscoped assertion, fix it here.

- [ ] **Step 4: Handle the `Invariants (always enforced)` lists**

`epics.md`, `ready.md`, `release-notes.md`, `implement.md`, `document.md` (×2),
`vuln.md`, and `upgrade.md` each carry an `## Invariants (always enforced)`
section with bullet-level assertions. These are the sites that "fix three of
four and miss the fourth" applies to most — they are lists, not prose, and read
as authoritative.

For each in-scope invariants list:
- Reconcile or annotate every commit/branch bullet per Step 2.
- **Add one new bullet** to each of the 8 lists:

```markdown
- ALWAYS run `specs-preflight` at Phase 0 and `commit-artifacts` as the run's last action (per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`) — bounded to `$SPECS_PATH`'s artifact paths (§2.1) and to plugin-created branches (§2.2), always `git -C "$SPECS_PATH"` and never a `cd` (§1 rule 1), never force-pushing, and never failing the run
```

`epics.md`'s existing `NEVER create a git branch (this command never branches)`
and `NEVER commit (git management is the user's responsibility)` bullets both
became partly false: `/epics` still never branches (the preflight only switches
between branches that already exist, and only plugin-created ones) but it does
now commit the specs-repo artifact area. Rewrite that pair as:

```markdown
- NEVER create a git branch — this command never branches. `specs-preflight` may switch `$SPECS_PATH` between branches that already exist, and only ones the plugin created (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2); it creates none.
- NEVER commit the Epic drafts or anything in the vault, `jira-products/`, `jira_export_root`, or the current working directory — git management there is the user's responsibility. The terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
```

- [ ] **Step 5: Re-run the sweep and confirm zero unreconciled hits**

Re-run both commands from Step 1. Every surviving hit must be either:
- **scoped** — its text names the `$SPECS_PATH` carve-out, or
- **annotated** — its text carries a stated *reason* it remained true.

A hit that is neither is a failure of this task. Record the final tally
(total hits / scoped / annotated) in the task report.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/
git commit -m "fix(dev-workflows): reconcile every 'never commits' assertion with commit-artifacts

Swept all 17 in-scope command files plus agents/ across nine phrasing
variants, whitespace-normalized so the two assertions that wrap across a
line break are not missed. Assertions that became false are scoped to
the \$SPECS_PATH carve-out rather than deleted — the protective intent is
real, only the scope changed. Assertions that stayed true are annotated
with the reason they stayed true. Each in-scope Invariants list gains the
specs-preflight/commit-artifacts bullet."
```

---

### Task 9: Canonical release — version, catalog, CHANGELOG, README, CLAUDE.md

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (repo root)
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `plugins/dev-workflows/README.md`
- Modify: `CLAUDE.md` (repo root)

**Interfaces:**
- Consumes: everything from Tasks 1–8.
- Produces: version `2.45.0`, which Task 10 mirrors into mgd verbatim.

**Both `marketplace.json` and the README reference list are explicitly named
here because each was missed in 2.42.0.**

- [ ] **Step 1: Bump the plugin version**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, change
`"version": "2.44.1"` to `"version": "2.45.0"`.

- [ ] **Step 2: Bump and extend the marketplace catalog**

In `.claude-plugin/marketplace.json`, in the `dev-workflows` entry:
- change `"version": "2.44.1"` to `"version": "2.45.0"`
- append this sentence to the end of the `description` string (inside the
  existing quotes, after the final period):

```
 Every run now maintains the specs repo itself: a Phase 0 preflight flushes leftover artifacts, retries an unpushed artifact commit, and settles the branch, and a terminal commit-artifacts step commits and pushes the run's feedback, cost, follow-ups, and resume pointer — bounded to $SPECS_PATH's artifact paths and to plugin-created branches, always via git -C, never force-pushing, and never failing the run.
```

Verify the file still parses:

```bash
cd /workspace/ihudak-claude-plugins
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo OK
python3 -m json.tool plugins/dev-workflows/.claude-plugin/plugin.json > /dev/null && echo OK
```

- [ ] **Step 3: Add the CHANGELOG entry**

Insert immediately after the `Versions follow semver at the plugin level.` line
and its blank line, above `## [2.44.1] — 2026-08-10`:

```markdown
## [2.45.0] — 2026-08-10

### Fixed

- **`$SPECS_PATH` is a git repository that no command ever committed.** Seventeen of the twenty-one commands write bookkeeping artifacts into it — feedback, cost entries, follow-ups, resume pointers — and none of them committed those artifacts. The five commands that do run git against the specs repo commit only their deliverable, in a handoff phase that fires *before* the artifacts are written, so the artifacts were untracked by construction. `references/feedback-emission.md` states the purpose outright — feedback reaches the maintainer only if it lands in the committed, pushed specs repo — and nothing in the plugin made that landing happen; twenty-eight tracked artifact files across nine VI directories all arrived by hand-written housekeeping commits, one of which had to commit the feedback entry recording this very defect. New `references/specs-repo-git.md` owns two entry points: `specs-preflight` at Phase 0 (flush leftovers onto the current branch, retry an artifact commit whose push failed, settle the branch) and `commit-artifacts` as the run's last action (stage the bounded artifact paths, commit `<KEY|NOISSUE> Add dev-workflows session artifacts (<command>)`, push). Every git call is `git -C "$SPECS_PATH"` and never a `cd` — eight of the seventeen commands are standing in a *different* repository when these run. Staging is by enumeration, never by glob, and never `git add -A` at repository scope. The plugin manages only branches it created (`vi|ard|spec|design/*`); a detached HEAD is the one blocking state, because a commit made there is reachable from no ref and garbage-collectable, and a run that reported a SHA over it would be a failure that looked like success.
- **Eight of the ten commands that write `resume.md` violated the ordering `references/session-hygiene.md` §1 already required.** It states the pointer is written after `emit-cost` / feedback / follow-up; only `/design` and `/specify` complied, and those two wrote it inside their Final report — after the point where `commit-artifacts` now runs, which would have left it uncommitted. All ten now write the pointer as the last step of their cost phase, immediately before the commit that captures it. The printed `### Context hygiene` block keeps its `/compact` | `/clear` | `/rename` guidance and no longer carries the write instruction, because six commands compose that report *before* their cost phase runs.
- **Around fifty `NEVER commits` assertions became false or ambiguous the moment the terminal step shipped.** They were swept across nine phrasing variants — including `never branches`, `NEVER auto-commit`, `no branch, no commit`, `git is the user's responsibility`, and two that wrap across a line break and defeat any line-level grep — and reconciled rather than deleted: the protective intent is real, only the scope changed. Assertions that stayed true (the vault, `jira-products/`, a code or docs repo) are annotated with the reason they stayed true. `/statusline` keeps its unscoped assertion — it writes only under `~/.claude/` and is out of scope.

### Added

- **`references/specs-repo-git.md`** — the bounded write authority (three path shapes, `^(vi|ard|spec|design)/` branches), the three preflight guards and their four-part notice contract, the three-stage resolution, the seven-step commit, and the `Specs repo:` outcome line. Never force-pushes, never `branch -D`, never merges/rebases/resets, never deletes an `index.lock`, and never fails the run.
- **A `Specs repo:` outcome line at the end of every in-scope run** — eighteen sites, one per command plus one per `/document` mode. Where the Final Report is the run's last output the line lives in the report template; where the report is composed before the terminal phases, `commit-artifacts` prints its own block, as the follow-up and cost phases already do.

```

- [ ] **Step 4: Update the README**

4a. In the reference-doc list (the section containing the
`references/session-hygiene.md` / `references/feedback-emission.md` /
`references/cost-emission.md` / `references/followup-emission.md` bullets), add
this bullet immediately after the `references/cost-emission.md` bullet:

```markdown
- `references/specs-repo-git.md` — the two specs-repo git entry points shared by all seventeen commands that write into `$SPECS_PATH`: `specs-preflight` (run start — flush leftover artifacts, retry an unpushed artifact commit, settle the branch) and `commit-artifacts` (terminal — stage the bounded artifact paths, commit, push). Owns the bounded write authority (three path shapes; `^(vi|ard|spec|design)/` branches only), the three guards and their four-part notice contract, the branch-disposition table, and the `Specs repo:` outcome line. Always `git -C "$SPECS_PATH"`, never a `cd`; never force-pushes; never fails the run.
```

4b. Add a feature paragraph alongside the existing follow-up/feedback/cost
descriptions (the section containing the
`**Follow-up task & journal emission (all four Jira-driven commands).**`
paragraph), immediately after it:

```markdown
- **Specs-repo git completeness (all seventeen commands that write to `$SPECS_PATH`).** The specs repo maintains itself. At Phase 0, `specs-preflight` commits and pushes any artifacts a previous run left behind, retries a commit whose push failed, and settles the branch — switching away only from branches the plugin created, and standing still on anything else. As the run's last action, `commit-artifacts` stages the bounded artifact paths, commits `<KEY|NOISSUE> Add dev-workflows session artifacts (<command>)`, and pushes; for the five VI-authoring commands that opened a specs-repo PR at handoff, that push updates the PR they already opened. It is bounded to three path shapes inside `$SPECS_PATH`, never issues `git add -A` at repository scope, never force-pushes, never deletes a branch with `-D` or a lock file, and never fails the run. A detached HEAD blocks the commit outright and says so loudly — a commit made there would be unreachable and garbage-collectable, and reporting a SHA over it would be a failure that looked like success. See `references/specs-repo-git.md`.
```

- [ ] **Step 5: Update `CLAUDE.md` (repo root)**

5a. Add a source-truth paragraph. Insert immediately after the
`references/bug-diagnosis.md` paragraph and before the
`references/gate-ledger.md` paragraph:

```markdown
`plugins/dev-workflows/references/specs-repo-git.md` is the **single source of truth** for the two git entry points the plugin runs against `$SPECS_PATH` — `specs-preflight` (run start: flush leftover artifacts, retry an unpushed artifact commit, settle the branch) and `commit-artifacts` (terminal: stage the bounded artifact paths, commit, push). It owns the bounded write authority (three path shapes; `^(vi|ard|spec|design)/` branches only), the three guards and their four-part notice contract, the branch-disposition table, and the `Specs repo:` outcome line. Consumed by the seventeen commands that write into `$SPECS_PATH` — every command except `/api-guideline-reviewer`, `/guideline-reviewer`, `/statusline`, and `/docs-profile`. Hard rules: every git call is `git -C "$SPECS_PATH"` and never a `cd`; `git add -A` is never issued at repository scope; never force-push, never `branch -D`, never merge/rebase/reset, never delete an `index.lock`; never fatal.
```

5b. Add to the `## Key invariants` section, in the "enforced by all three
code-oriented commands" list, one new bullet at the end:

```markdown
- Every command that writes into `$SPECS_PATH` runs `specs-preflight` at Phase 0 and `commit-artifacts` as its last action (`references/specs-repo-git.md`) — bounded to the artifact paths and to plugin-created branches, and reported once as a `Specs repo:` line
```

5c. Add a new key-invariants block immediately after the
`Key invariants for `$DOCS_PATH` docs grounding:` block:

```markdown
Key invariants for specs-repo git (`references/specs-repo-git.md`):

- Every git invocation is `git -C "$SPECS_PATH"` — the working directory is NEVER changed; eight of the seventeen callers are standing in a different repository
- Staging is by enumeration over `git status --porcelain --untracked-files=all`, never by glob; `git add -A` is only ever issued as `git add -A -- <literal paths>`, and `-A` is required because cost reconciliation deletes a pending file
- Only `^(vi|ard|spec|design)/` branches are the plugin's to switch away from or delete; any other **named** branch is left alone and the artifacts are committed on it
- **Detached HEAD is the one blocking state** — it sets `specs_git: blocked` for the whole run, `commit-artifacts` skips on that flag, and the notice fires at both ends. A dirty unrelated path (G1) does NOT block the terminal commit
- Never force-push, never `branch -D`, never merge/rebase/reset, never delete an `index.lock`, never open a PR, never call a REST API
- Never fatal — every failure is reported and the run continues
- The artifact commit carries no `Co-Authored-By` trailer; each artifact already carries its own `author:` field
- The canonical terminal order is deliverable + handoff → feedback → follow-ups → cost → `resume.md` → `commit-artifacts` → the run's last printed output
- Exactly one `Specs repo:` outcome line per run, at the end; a guard notice is repeated in full there, never only at Phase 0
```

5d. In the `## `dev-workflows` workflow relationships` diagram, append
` → commit-artifacts` to the end of each in-scope command's line. For example
`/idea → idea-reader → … → write idea.md` becomes
`/idea → idea-reader → … → write idea.md → commit-artifacts`. Apply to all
seventeen in-scope command lines; leave `/docs-profile`,
`/api-guideline-reviewer`, and `/guideline-reviewer` unchanged. Add one line
above the diagram's `└──` helper list:

```
All seventeen in-scope commands additionally run `specs-preflight` at Phase 0 and `commit-artifacts` as their last action (`references/specs-repo-git.md`).
```

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -m1 '"version"' plugins/dev-workflows/.claude-plugin/plugin.json    # expect 2.45.0
grep -n '"version": "2.45.0"' .claude-plugin/marketplace.json            # expect 1 hit (dev-workflows)
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo JSON-OK
grep -n '^## \[' plugins/dev-workflows/CHANGELOG.md | head -4            # expect 2.45.0 first, then 2.44.1, 2.44.0
grep -c 'specs-repo-git' plugins/dev-workflows/README.md                 # expect >=2
grep -c 'specs-repo-git' CLAUDE.md                                       # expect >=3
```

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json \
        plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md CLAUDE.md
git commit -m "release(dev-workflows): 2.45.0 — specs-repo git completeness

Version, marketplace catalog description, CHANGELOG, README (reference
list + feature paragraph), and CLAUDE.md (source-truth paragraph, key
invariants block, workflow map)."
```

---

### Task 10: mgd port

**Files:**
- Create: `/workspace/mgd-claude-plugins/plugins/dev-workflows/references/specs-repo-git.md`
- Modify: every other file Tasks 1–9 touched, at the same path under `/workspace/mgd-claude-plugins/`
- Do NOT modify: the 5 mgd identity files (see Step 1)

**Interfaces:**
- Consumes: the finished canonical `plugins/dev-workflows/` tree from Tasks 1–9.
- Produces: an mgd tree whose only diff against canonical is the 5 identity files.

The mgd edition is **content-verbatim**. Do not re-author anything; copy.

- [ ] **Step 1: Establish the identity-file baseline before copying**

```bash
cd /workspace/mgd-claude-plugins
git status --porcelain    # expect clean
diff -rq plugins/dev-workflows /workspace/ihudak-claude-plugins/plugins/dev-workflows
```

Record the differing files. Before this task's changes there should be exactly
the known identity set. Every file that differs *and is not in that set* is a
pre-existing drift you must report, not silently absorb.

- [ ] **Step 2: Copy the content files**

Copy each file Tasks 1–9 created or modified under
`plugins/dev-workflows/{references,commands,agents}/` plus
`plugins/dev-workflows/CHANGELOG.md`, from canonical to mgd, preserving the
executable bit where one exists. **Use `cp`, not `sed`** — `sed -i` silently
drops the executable bit, which cost a follow-up commit in 2.44.1.

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for rel in references/specs-repo-git.md references/session-hygiene.md \
           references/feedback-emission.md references/cost-emission.md \
           references/followup-emission.md CHANGELOG.md; do
  cp -p "$rel" "/workspace/mgd-claude-plugins/plugins/dev-workflows/$rel"
done
# every command file Tasks 3-8 touched:
for f in create-vi update-vi create-ard specify design idea epics ready \
         release-notes implement document vuln upgrade feedback prompt \
         prompt-brainstorm prompt-grill-me; do
  cp -p "commands/$f.md" "/workspace/mgd-claude-plugins/plugins/dev-workflows/commands/$f.md"
done
```

If Task 8 modified any file under `agents/`, copy those too — read Task 8's
report for the list rather than assuming it touched none.

- [ ] **Step 3: Apply the version bump and the identity-aware docs**

`plugin.json` and `marketplace.json` are identity files in part — the version
must change, the name/homepage/author must not. Edit rather than copy:

- `/workspace/mgd-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json` — `"version": "2.44.1"` → `"2.45.0"`
- `/workspace/mgd-claude-plugins/.claude-plugin/marketplace.json` — the `dev-workflows` entry's `"version"` → `"2.45.0"`, and append the same description sentence Task 9 Step 2 appended (the description text is content, not identity)
- `/workspace/mgd-claude-plugins/plugins/dev-workflows/README.md` — apply Task 9 Step 4's two additions (copy the file from canonical only if a prior diff shows README.md was already byte-identical; otherwise apply the two edits by hand)
- `/workspace/mgd-claude-plugins/CLAUDE.md` — apply Task 9 Step 5's four additions by hand; this file carries mgd-specific paths and must not be copied

- [ ] **Step 4: Verify parity (V12)**

```bash
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows \
         /workspace/mgd-claude-plugins/plugins/dev-workflows
```

The output must list **exactly the 5 known identity files** and nothing else.
Any additional differing file is a port miss — fix it before committing.

```bash
cd /workspace/mgd-claude-plugins
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo JSON-OK
python3 -m json.tool plugins/dev-workflows/.claude-plugin/plugin.json > /dev/null && echo JSON-OK
grep -n '^## \[' plugins/dev-workflows/CHANGELOG.md | head -3   # expect 2.45.0, 2.44.1, 2.44.0
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/mgd-claude-plugins
git add -A
git commit -m "release(dev-workflows): 2.45.0 — specs-repo git completeness (port)

Content-verbatim port of the canonical 2.45.0: references/specs-repo-git.md,
the four sibling reference updates, all seventeen command files, the
never-commits reconciliation, and the release docs. Parity verified as
exactly the five identity files."
```

---

### Task 11: copilot — reference + sibling references

**Files:**
- Create: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/specs-repo-git.md`
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/session-hygiene.md`
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/feedback-emission.md`
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/followup-emission.md`

**Interfaces:**
- Consumes: the canonical `references/specs-repo-git.md` from Task 1 as the source text to adapt.
- Produces: `skills/_shared/specs-repo-git.md` with the copilot dialect's entry points and section numbers, which Task 12's seventeen skills cite.

**Copilot dialect rules for this task:**

| Canonical | Copilot |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/<ref>.md` | `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<ref>.md` |
| `/create-vi`, `/epics`, … | `create-vi:`, `epics:`, … |
| `subagent_type: "dev-workflows:x"` | the agent's `name:` idiom |
| `.claude-plugin/plugin.json` | `.plugin/plugin.json` |

**There is no `cost-emission.md` in this edition** — no cost subsystem exists at
all (Global Constraint G-9).

- [ ] **Step 1: Create the adapted reference**

Copy the canonical `plugins/dev-workflows/references/specs-repo-git.md` to
`/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/specs-repo-git.md`,
then apply exactly these adaptations and no others:

1a. In §2.1, **remove the `dev-workflows-cost/**` line** from the code block, so
it reads:

```
<specs-root>/{specs|specifications|vis}/**/dev-workflows/**   # tier 1: feedback, follow-ups, resume.md
<specs-root>/dev-workflows-feedback/**                        # feedback-emission.md §2 tier 2 (keyless runs)
```

1b. In §2.1's classification step 2, drop the `or ^dev-workflows-cost/` clause:

```markdown
2. Classify each reported path: **ARTIFACT** if it matches
   `^(specs|specifications|vis)/.+/dev-workflows/` or
   `^dev-workflows-feedback/`; **OTHER** otherwise.
```

1c. Replace §2.1's `Sources:` sentence with:

```markdown
Sources: `feedback-emission.md` §2 tiers 1–2, `followup-emission.md` §4 (the
shared per-VI area), `session-hygiene.md` §1 (resume tier 1). This edition has
**no cost subsystem** — there is no `cost-emission.md`, no `emit-cost`, and no
`dev-workflows-cost/` path shape.
```

1d. Replace §2.1's `-A` justification paragraph with:

```markdown
`-A` is required, not optional: the user may delete a feedback or follow-up file
between runs, and that deletion must be staged. Plain `git add` would not stage
it.
```

1e. In §3.6, change `/create-ard` to `create-ard:`.

1f. In §4, change the `commit-artifacts` message template's `<command>` example
usage to the copilot form — `<KEY> Add dev-workflows session artifacts (create-vi:)`.

1g. In §4.1, change the parenthesised command list
`(`/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`)` to
`(`create-vi:`, `update-vi:`, `create-ard:`, `specify:`, `design:`)`.

1h. In §4 step 1 and §7, replace every reference to a *cost* artifact. §4's
opening becomes `after `resume.md` is written (where the skill writes one)`, and
§7 item 2 becomes:

```markdown
2. **Cite and execute `commit-artifacts` (§4)** as the last action of the run,
   after `resume.md` (where one is written) and after the terminal feedback and
   follow-up steps.
```

1i. In §5's three notice blocks, change `this run's feedback, cost, follow-ups,
and resume pointer` to `this run's feedback, follow-ups, and resume pointer`.

1j. Replace the canonical citation form in the intro paragraph and anywhere else
it appears with the copilot form from the dialect table above.

- [ ] **Step 2: Adapt `session-hygiene.md`**

Apply Task 2 Steps 1–2 to
`/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/session-hygiene.md`,
with these changes:

- every `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` → the copilot path form
- `AFTER `emit-cost` / feedback / follow-up` → `AFTER the terminal feedback and follow-up steps` (there is no `emit-cost` here)
- `the last step of the command's terminal cost phase` → `the last step of the skill's terminal feedback/follow-up phase`
- the §5 rule-2 terminal order becomes: **deliverable + handoff → feedback → follow-ups → `resume.md` → `commit-artifacts` → the run's last printed output**

Check first whether the copilot `session-hygiene.md` already differs from
canonical in these sentences (it has no cost subsystem, so it may already read
differently). Adapt what is there; do not paste canonical text over it.

- [ ] **Step 3: Adapt `feedback-emission.md` and `followup-emission.md`**

Apply Task 2 Step 3 to copilot's `feedback-emission.md` (the purpose paragraph)
and Task 2 Step 4's `feedback-emission.md` + `followup-emission.md` sentences,
using the copilot citation path form. Skip the `cost-emission.md` edit entirely —
the file does not exist in this edition.

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared
ls specs-repo-git.md                                   # exists
grep -c 'dev-workflows-cost' specs-repo-git.md         # expect 0  (V11)
grep -c 'emit-cost' specs-repo-git.md                  # expect 0
grep -c 'CLAUDE_PLUGIN_ROOT' specs-repo-git.md         # expect 0
grep -n 'cd ' specs-repo-git.md                        # expect no output  (V7)
grep -n 'git add -A' specs-repo-git.md | grep -v ' -- '   # expect no output  (V8)
grep -nE '\-\-force|push -f|branch -D' specs-repo-git.md  # expect no output  (V9)
grep -c 'specs-repo-git.md' session-hygiene.md feedback-emission.md followup-emission.md
# expect: session-hygiene 3, feedback-emission 2, followup-emission 1
ls cost-emission.md 2>/dev/null                        # expect: no such file
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add dev-workflows/skills/_shared/
git commit -m "feat(dev-workflows): add _shared/specs-repo-git.md and wire the siblings

Copilot edition of the two specs-repo git entry points. This edition has
no cost subsystem, so the dev-workflows-cost path shape is omitted and
the -A staging requirement rests on user-deleted feedback/follow-up
files instead. Citation paths, command names, and the terminal order
adapted to the copilot dialect."
```

---

### Task 12: copilot — seventeen skills wiring + sweep

**Files:**
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/<name>/SKILL.md` for all seventeen in-scope skills: `create-vi` `update-vi` `create-ard` `specify` `design` `idea` `epics` `ready` `release-notes` `implement` `document` `vuln` `upgrade` `feedback` `prompt` `prompt-brainstorm` `prompt-grill-me`
- Do NOT modify: `api-guideline-reviewer`, `guideline-reviewer`, `docs-profile` (out of scope). There is no `statusline` skill in this edition.

**Interfaces:**
- Consumes: `skills/_shared/specs-repo-git.md` from Task 11 and its entry points / section numbers.
- Produces: 17 preflight sites and 18 commit sites in the copilot edition, matching canonical.

- [ ] **Step 1: Mirror Tasks 3–7 skill by skill**

For each of the seventeen skills, **open the canonical counterpart command file
side by side** — `/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/<name>.md`,
already finished by Tasks 3–8 — and mirror its four legs into the copilot skill:
the Phase 0 preflight citation, the `resume.md` relocation (where the skill
writes one), the terminal `commit-artifacts` step, and the `Specs repo:` outcome
line. The canonical file is the source of the exact wording; apply the dialect
substitutions from Task 11 to it. Do not re-author the text.

The mapping from canonical task to copilot skill:

| Canonical task | Copilot skills |
|---|---|
| Task 3 | `create-vi` `update-vi` `create-ard` `specify` `design` |
| Task 4 | `idea` `epics` `ready` |
| Task 5 | `release-notes` `implement` `document` (both modes — one shared preflight, two commit steps) |
| Task 6 | `vuln` `upgrade` |
| Task 7 | `feedback` `prompt` `prompt-brainstorm` `prompt-grill-me` |

**Two dialect-driven differences from the canonical wiring:**

1. **There is no cost phase.** Where a canonical task said "append to the end of
   the terminal cost phase", append instead to the end of the skill's **last
   terminal phase** — the one that persists feedback and/or follow-ups. In
   `create-vi/SKILL.md` that is `## Phase 7 — Session maintenance & feedback`
   (note: no `& cost` in this edition). Read each skill's phase list before
   editing; the phase numbers mostly match canonical but the titles do not.
2. **The `resume.md` write moves after the feedback/follow-up steps**, not after
   a cost entry. Adapt the wording accordingly: `after the feedback and
   follow-up entries above, so the pointer reflects the completed run, and
   before the commit step below, so it is included in it`.

Verify each skill's report-template vs terminal-block classification by reading it —
do not assume it matches canonical. The rule is Global Constraint G-11: if the
skill's report section is the last thing it prints, the report carries the
`Specs repo:` line; otherwise `commit-artifacts` prints its own block.

- [ ] **Step 2: Run the reconciliation sweep on the copilot edition**

Apply Task 8's method to this edition. Derive the file list from the sweep, not
by hand:

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows
for f in skills/create-vi/SKILL.md skills/update-vi/SKILL.md skills/create-ard/SKILL.md \
         skills/specify/SKILL.md skills/design/SKILL.md skills/idea/SKILL.md \
         skills/epics/SKILL.md skills/ready/SKILL.md skills/release-notes/SKILL.md \
         skills/implement/SKILL.md skills/document/SKILL.md skills/vuln/SKILL.md \
         skills/upgrade/SKILL.md skills/feedback/SKILL.md skills/prompt/SKILL.md \
         skills/prompt-brainstorm/SKILL.md skills/prompt-grill-me/SKILL.md; do
  hits=$(tr '\n' ' ' < "$f" | grep -o -iE '.{60}(NEVER +commits?|never +branches|NEVER +auto-commit|no branch, no commit|nothing +commits|Nothing is committed|git (is|management is) (the user.s|your) responsibility|the user manages git manually|never branches or commits).{80}')
  if [ -n "$hits" ]; then echo "===== $f"; echo "$hits"; fi
done
# and the agents directory:
for f in agents/*.md; do
  hits=$(tr '\n' ' ' < "$f" | grep -o -iE '.{60}(NEVER +commits?|never +branches|NEVER +auto-commit|nothing +commits|Nothing is committed).{80}')
  if [ -n "$hits" ]; then echo "===== $f"; echo "$hits"; fi
done
```

Reconcile or annotate each hit exactly as Task 8 Step 2 prescribes, using the
copilot citation path. Re-run the sweep afterwards and confirm every surviving
hit is scoped or annotated-with-a-reason.

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows
# V2: skill FILES citing the reference
grep -rl 'specs-repo-git.md' skills/*/SKILL.md | wc -l          # expect 17
# V3: preflight sites
grep -rc 'specs-preflight' skills/*/SKILL.md | grep -v ':0' | awk -F: '{s+=$2} END {print s}'   # expect 17
# V4: commit sites
grep -rc 'commit-artifacts` entry point (§4) inline' skills/*/SKILL.md | grep -v ':0' | awk -F: '{s+=$2} END {print s}'   # expect 18
# V5: outcome lines
grep -rc 'Specs repo:' skills/*/SKILL.md | grep -v ':0' | awk -F: '{s+=$2} END {print s}'       # expect 18
# V11: no cost paths anywhere in the edition
grep -rn 'dev-workflows-cost' skills/ agents/ 2>/dev/null       # expect no output
# out-of-scope skills untouched
grep -l 'specs-repo-git' skills/api-guideline-reviewer/SKILL.md skills/guideline-reviewer/SKILL.md skills/docs-profile/SKILL.md 2>/dev/null   # expect no output
```

If V4 or V5 reads 17, the missing one is `document/SKILL.md`'s second mode —
that is the site the count exists to catch.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add dev-workflows/skills/ dev-workflows/agents/
git commit -m "feat(dev-workflows): wire specs-repo git into all seventeen copilot skills

Seventeen specs-preflight sites and eighteen commit-artifacts sites
(document: carries one per mode), the resume.md relocation adapted to an
edition with no cost phase, and the never-commits reconciliation swept
across nine phrasing variants."
```

---

### Task 13: copilot release

**Files:**
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/.plugin/plugin.json`
- Modify: `/workspace/ihudak-copilot-plugins/.github/plugin/marketplace.json`
- Modify: `/workspace/ihudak-copilot-plugins/.github/copilot-instructions.md`
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/README.md`
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: Tasks 11–12.
- Produces: copilot `dev-workflows` 2.15.0. Final task.

**`marketplace.json` and `.github/copilot-instructions.md` are both named
explicitly because each was missed in 2.42.0.**

- [ ] **Step 1: Version**

`dev-workflows/.plugin/plugin.json` — `"version": "2.14.1"` → `"2.15.0"`.

- [ ] **Step 2: Catalog**

`.github/plugin/marketplace.json`, `dev-workflows` entry — `"version": "2.14.1"`
→ `"2.15.0"`, and append to the `description` string:

```
 Every run now maintains the specs repo itself: a Phase 0 preflight flushes leftover artifacts, retries an unpushed artifact commit, and settles the branch, and a terminal commit-artifacts step commits and pushes the run's feedback, follow-ups, and resume pointer — bounded to $SPECS_PATH's artifact paths and to plugin-created branches, always via git -C, never force-pushing, and never failing the run.
```

- [ ] **Step 3: `.github/copilot-instructions.md`**

Read the file, find the section that enumerates the shared `_shared/` references
(or the equivalent guidance block), and add `specs-repo-git.md` alongside
`feedback-emission.md` / `followup-emission.md` / `session-hygiene.md`, with a
one-line description matching Task 9 Step 4a's README bullet, adapted to the
copilot path form. If the file carries a version string or a capability summary
for `dev-workflows`, update those too.

- [ ] **Step 4: README + CHANGELOG**

`dev-workflows/README.md` — apply Task 9 Step 4's two additions (reference-list
bullet + feature paragraph) with the copilot path form, and with `feedback,
follow-ups, and resume pointer` in place of any cost mention.

`dev-workflows/CHANGELOG.md` — add a `## [2.15.0] — 2026-08-10` entry above
`## [2.14.1]`, using Task 9 Step 3's entry text with these adaptations: the
counts stay (seventeen skills, eighteen commit sites), `/statusline` is not
mentioned (this edition has none), and the cost artifact is dropped from every
list — this edition's artifact set is feedback + follow-ups + `resume.md`.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-copilot-plugins
grep -m1 '"version"' dev-workflows/.plugin/plugin.json                # expect 2.15.0
python3 -m json.tool .github/plugin/marketplace.json > /dev/null && echo JSON-OK
python3 -m json.tool dev-workflows/.plugin/plugin.json > /dev/null && echo JSON-OK
grep -n '^## \[' dev-workflows/CHANGELOG.md | head -3                 # expect 2.15.0, 2.14.1, 2.14.0
grep -c 'specs-repo-git' .github/copilot-instructions.md              # expect >=1
grep -c 'specs-repo-git' dev-workflows/README.md                      # expect >=2
grep -rn 'statusline' dev-workflows/CHANGELOG.md | head -3            # the 2.15.0 entry must not mention it
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add -A
git commit -m "release(dev-workflows): 2.15.0 — specs-repo git completeness

Version, marketplace catalog, copilot-instructions, README, and
CHANGELOG. This edition's artifact set is feedback + follow-ups +
resume.md; it has no cost subsystem, so the dev-workflows-cost path
shape is absent throughout."
```

---

## Verification (plan-wide, run after Task 13)

Counts are **per edition**. Seventeen command *files* are in scope in every
edition, but `/document` carries two modes in one file, so call-site counts
differ from file counts where noted. Canonical and mgd hold 21 commands (17 in
scope, minus `/api-guideline-reviewer`, `/guideline-reviewer`, `/statusline`,
`/docs-profile`); copilot holds 20 (no `/statusline`), so 17 in scope there too.

| # | Check | Expectation |
|---|---|---|
| V1 | `references/specs-repo-git.md` exists (copilot: `skills/_shared/specs-repo-git.md`) | 1 file per edition |
| V2 | Command **files** citing `specs-repo-git.md` (`grep -l`) | 17 |
| V3 | `specs-preflight` call sites (`grep -c`, summed) | 17 — one per file; `/document`'s Phase 0 is shared by both modes |
| V4 | `commit-artifacts` call sites (`grep -c` on the executable citation, summed) | **18** — one per file, **two** in `document.md` |
| V5 | `Specs repo:` outcome-line sites | **18** — same split as V4 |
| V6 | Whitespace-normalized scan of each in-scope file for every phrasing variant; each surviving hit is either scoped (names the `$SPECS_PATH` carve-out) or annotated with a stated reason | 0 unreconciled hits |
| V6b | Annotated-as-still-true assertions each carry a stated **reason**, not just a label | every one |
| V7 | `cd ` inside `specs-repo-git.md` | 0 |
| V8 | `git add -A` in `specs-repo-git.md` not followed by ` -- ` on the same line | 0 |
| V9 | `--force` / `push -f` / `branch -D` in `specs-repo-git.md` | 0 |
| V10 | `resume.md` written after the cost phase (copilot: after the feedback/follow-up phase) | 10 of the 10 commands that write it |
| V11 | `dev-workflows-cost` anywhere in the copilot edition | 0 |
| V12 | mgd diff against canonical | exactly the 5 identity files |
| V13 | CHANGELOG ordering monotonic in all three | canonical/mgd 2.45.0 → 2.44.1 → …; copilot 2.15.0 → 2.14.1 → … |

Run V2–V6 with:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
SCOPE="create-vi update-vi create-ard specify design idea epics ready release-notes implement document vuln upgrade feedback prompt prompt-brainstorm prompt-grill-me"
echo "V2 files: $(for f in $SCOPE; do grep -l 'specs-repo-git.md' $f.md; done | wc -l)"      # 17
echo "V3 preflight: $(for f in $SCOPE; do grep -c 'specs-preflight' $f.md; done | paste -sd+ | bc)"   # >=17
echo "V4 commit: $(for f in $SCOPE; do grep -c 'commit-artifacts` entry point (§4) inline' $f.md; done | paste -sd+ | bc)"   # 18
echo "V5 line: $(for f in $SCOPE; do grep -c 'Specs repo:' $f.md; done | paste -sd+ | bc)"   # 18
```

V3 may exceed 17 because `document.md` carries a direct-mode "already run"
pointer. Confirm the number of **executable** preflight citations is exactly 17
by grepping the executable phrasing:

```bash
for f in $SCOPE; do grep -c 'execute its `specs-preflight` entry point' $f.md; done | paste -sd+ | bc   # 17
```

---

## Risks carried from the spec

Each is mitigated by a named clause above; a reviewer should check the clause
exists.

| # | Risk | Where it is handled |
|---|---|---|
| R1 | Committing onto a detached HEAD silently destroys the artifacts | Task 1 reference §3.3 G0 + §3.7; §4 step 1 gates on the flag |
| R2 | The ~50 `NEVER commits` assertions contradict the shipped step | Task 8 (one implementer, nine variants, whitespace-normalized) |
| R3 | The outcome-line transport leg is dropped (the dead-gate class) | Global Constraint G-11 assigns it per command; V5 is a hard count of 18 |
| R4 | B3 gets "simplified" into "always return to default" later | Task 1 reference §3.6 ships the rationale, naming the exact failure |
| R5 | Artifacts committed but never pushed, and never retried | Task 1 reference §3.4 stage 2 |
| R6 | G1 mis-wired to disable the terminal commit | Task 1 reference §3.3 G1 row states the non-propagation and its reason; §3.7 states G0 is the only blocking condition |
| R7 | Read-only specs mount passes a worktree-only writability test | Task 1 reference §3.1 tests `.git` writability specifically |
| R8 | Concurrent sessions hit `index.lock` | Task 1 reference §4 step 6 — report and skip, never delete a lock file |
| R9 | Diverged local default branch breaks `pull --ff-only` | Task 1 reference §3.5 B2 — report and continue without pulling |
| R10 | *(new)* The copilot port reproduces the cost-path shape it has no subsystem for | Global Constraint G-9; Task 11 Step 1a–1d; V11 |

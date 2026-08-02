---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# dev-workflows docs automation — SP2 pipeline hardening (design)

## Context

After SP2 Increment 3 shipped (3a–3d, v1.12.0→v1.14.1), the user-requested
**comprehensive 3a–3d Opus pipeline review** found the `/impl:jira:docs`
pipeline "Solid with fixes": **0 Critical, 4 Important** cross-phase seams, 4
benign Minors. This hardening pass fixes **three of the four review findings**
(I#1, I#2, I#4) plus **two fresh findings surfaced during this spec review** —
I#5 (redundant prompt/handoff in the inline-profiling path) and I#6 (the
stranded/unmerged standalone-profile edge). The fourth review finding (I#3, the
`§15` dangling escalation reference) is **deferred to the namespace refactor**
(the reviewer noted extracting a shared `escalation-rules.md` overlaps that
effort).

Plugin `main` at `af343a4` (v1.14.1). This is a **patch** release **v1.14.2**
(command/profile prose bugfixes — no new capability).

## Findings fixed here

### I#1 — Phase 6 / Phase 6.5 ordering (note, not renumber)

**Problem:** the document's numeric order is `… 5.9 → 6.2 (CDN) → 6 (write) →
6.5 (branch setup) → 6.7 …`. Phase 6.5 (branch setup) is a **prerequisite** for
Phase 6's commits, but it is numbered *after* Phase 6. An agent executing in
printed order would write+commit on whatever branch is current, then 6.5's
`git switch <base>` / `git switch -c` would move HEAD away and orphan the run's
commits — also breaking the Phase 8.5 squash base.

**Fix (decided):** add a crisp ordering note at the **top of Phase 6** —
"When branching applies (write context `docs_repo`, or confirmed
`non_docs_repo`, **and** the user opted into branching at plan approval),
**Phase 6.5 runs *before* this phase**: it creates the branch off the base; this
phase then writes and commits onto that branch." No renumbering now.

**Deferred:** the full monotonic renumber of the whole `6.2 / 6 / 6.5 / 6.7 /
6.8` cluster (physical order ≠ numeric order) + all ~8 `Phase 6.x`
cross-references + the README/CHANGELOG is folded into the **namespace
refactor** (already its scope per the review). `5.9` is taken, and a partial
renumber would leave the `6.2`-after-`6` inversion — so the note is the
contained correctness fix now.

### I#2 — `docs_repo_path` vs "cwd's git root" drift

**Problem:** Phase 0 resolves `docs_repo_path` in order — (a) **cwd's git root
if it has docs signals** (today's default), (b) a discovered `dynatrace-docs`
clone under `/workspace`, (c) a user-entered path. Phase 0 step 68 states the
writing phases consume `docs_repo_path`, not cwd. But six downstream agent
briefs hardcode **"cwd's git root"** as `repo_root` / `Project root`. When
`docs_repo_path ≠ cwd` (cases b/c — the capability Inc1 added),
`doc-location-finder` / `doc-planner` scan the wrong tree, `doc-planner`'s
home-space routing mis-routes, and the style/review agents lint the wrong root.

**Fix:** replace "cwd's git root" → "the resolved `docs_repo_path` (Phase 0)" in
the agent briefs at `docs.md` lines **290** (`doc-location-finder` `repo_root`),
**359** (`doc-planner` `repo_root`), **561** (`docs-style-checker` `repo_root`),
**575** & **672** (`doc-reviewer` `Project root`), **748** (Phase 8 Agent 4
`Project root`). Align the output-filename phrasing (**105**, **160** —
"under cwd" → "under `docs_repo_path`") and the Phase 8 `git diff` (**687**) to
`docs_repo_path`. **Safe by construction:** in case (a) `docs_repo_path` *is*
cwd's git root, so the change is a no-op there and only corrects cases (b)/(c).
Leave the Phase-1 readiness display (line 138 "Resolved cwd absolute path") as
informational.

**Invariant reword (line 865).** Today: "NEVER write outside cwd unless the user
provides an explicit absolute path at Phase 5.5." Reality: the run writes to
`docs_repo_path` (the docs) **and** the vault project folder under `$VAULT_PATH`
(the `<JIRA_KEY>-implementation-gaps.md` bug draft, the `<JIRA_KEY>-pr-draft.md`,
and screenshot staging). Reword to: "NEVER write product docs outside
`docs_repo_path` (Phase 0); the only other writes are to the ticket's vault
project folder under `$VAULT_PATH` (bug-report / PR drafts + screenshot staging)
— never anywhere else."

### I#4 — `profile.md` branches off the base

**Problem:** `/impl:docs:profile` step 5 creates its branch with
`git -C <repo> switch -c <name>` from **whatever HEAD currently is** (it has a
clean-tree check but never switches to the default branch first). So if the user
launched `/impl:jira:docs` (which invokes profiling inline) — or ran
`/impl:docs:profile` directly — while on a feature branch, the profile branch
(and the docs work layered on it) is based off that branch, not the default.
`docs.md` Phase 6.5 then asserts (`:544`) the profile branch was "created off the
base … already current", which can be false.

**Fix (decided): fix `profile.md`** — before `git switch -c <name>` (step 5),
resolve the default branch (`git -C <repo> symbolic-ref --short
refs/remotes/origin/HEAD`, with the same `origin/HEAD`→`main`→`master` fallbacks
`docs.md` Phase 6.5 step 1 uses) and `git -C <repo> switch <base> && git -C
<repo> pull --ff-only` (the clean-tree check already ran). Then create the
branch. The profile PR is then always off the base, which makes `docs.md:544`'s
assumption true (no `docs.md` change needed for I#4) and improves
`/impl:docs:profile` as a standalone command (a profile PR should branch off the
default, not a random feature branch).

### I#5 — single handoff in the inline-profiling path (fresh finding)

**Problem (not in the review — surfaced during spec review):** when
`/impl:jira:docs` invokes `/impl:docs:profile` inline (Phase 0 case c), the
single-branch outcome is already correct (Phase 6.5 renames the profiling branch;
one branch, one PR). But `/impl:docs:profile` is a full standalone command, so
inline it also runs its **branch-naming prompt** (step 1 — "what initials?") and
its **standalone PR-draft / handoff** (step 6 + final report). The naming prompt
is wasted (Phase 6.5 renames the branch anyway) and the profile PR draft is
redundant with the docs PR draft Phase 8.5 emits for the same branch → a
double-prompt + double-draft for one branch.

**Fix — an inline mode for `profile.md`:**
- **`docs.md` Phase 0 case (c)** passes an explicit inline signal when invoking
  profiling (e.g. an `--inline` token alongside `docs_repo_path` in the Skill
  invocation).
- **`profile.md`**, when the inline signal is present:
  - **step 1** — skip the branch-naming prompt; create the branch under a
    deterministic temporary name (Phase 6.5 renames it to the docs convention).
  - **steps 2–5** — unchanged (clean-tree check, base switch [I#4], `switch -c`,
    scan, write `.dev-workflows/docs-profile.yml` + commit C0).
  - **step 6 + the final standalone report** — skipped; control returns to
    `/impl:jira:docs`, which owns the single PR draft at Phase 8.5.
  - Run **standalone** (no inline signal) → entirely unchanged (still prompts for
    the name and drafts its own profile PR).

Net: the inline path is a clean **single branch + single decision + single
handoff**; the standalone command is untouched.

### I#6 — guard the stranded/unmerged standalone-profile edge (fresh finding)

**Problem (surfaced during spec review):** the inline path is safe (I#5), but a
**custom repo** where the user ran **standalone `/impl:docs:profile` first and
has not merged that profile PR** is not. profile.md (with I#4) committed the
profile on a branch off the base (e.g. `ivgu/NOISSUE-…`). A later
`/impl:jira:docs PRODUCT-NNNN` then either: (a) finds the profile in the working
tree (user still on that branch), loads it, but Phase 6.5 branches the docs work
off the **base** — so the docs branch doesn't contain the profile files (they
stay stranded on the unmerged branch; the docs PR won't carry them); or (b) the
user is back on the base (profile unmerged, not in the working tree) → Phase 0
finds no profile → **re-profiles inline**, creating a *second* profile branch.
The run never breaks (the profile is in memory once loaded), but the profile can
be stranded or duplicated. **Does not affect dynatrace-docs** (built-in profile,
no file) **or the inline/generated path** (single branch).

**Fix — a Phase 0 guard, scoped to `profile_source: in-repo` only:** after Phase
0 resolves an in-repo profile (case a), resolve the base branch (the standard
`git -C <docs_repo_path> symbolic-ref --short refs/remotes/origin/HEAD` →
`main`→`master` fallback) and check whether the profile is committed there:
`git -C <docs_repo_path> cat-file -e <base>:.dev-workflows/docs-profile.yml`.
- **present on base** → proceed (today's behavior; the common case where the
  profile was merged long ago).
- **absent on base** → warn ("the docs-profile is in your working tree but not
  on `<base>`; the docs branch created off `<base>` in Phase 6.5 won't include
  it") and offer `choices: ["Proceed — run uses the in-memory profile; I'll merge the profile PR separately", "Cancel — merge the profile PR first"]`.

Do **not** run this check for `profile_source: built-in` (no file) or `generated`
(the inline profiling branch is adopted by Phase 6.5, so the profile rides the
single docs branch — a base check would false-fire).

## Touch list

- `plugins/dev-workflows/commands/impl/jira/docs.md` — I#1 (Phase 6 ordering
  note), I#2 (cwd→`docs_repo_path` at the six agent briefs + lines 105/160/687 +
  the line-865 invariant reword), I#5 (Phase 0 case (c) passes the `--inline`
  signal), I#6 (Phase 0 in-repo-profile-not-on-base guard).
- `plugins/dev-workflows/commands/impl/docs/profile.md` — I#4 (resolve + switch
  to the default branch before `switch -c`), I#5 (inline mode: skip the naming
  prompt + the standalone PR-draft/handoff).
- Manifests + CHANGELOG — patch release **v1.14.2**.

~2 plan tasks (the command/profile prose edits; the patch release).

## Out of scope

- **I#3** (`§15` / "Section 15" dangling escalation reference) — deferred to the
  **namespace refactor** (extract `references/escalation-rules.md`).
- The monotonic Phase renumber — deferred to the namespace refactor.
- The Minor findings (5–8) — benign; Minor 7 (Phase 8 `git diff` in cwd) is
  covered by the I#2 line-687 alignment.
- No new feature; no schema/profile-field change.

## Invariants preserved

- No behavior change beyond the I#4 branch-base fix (which makes the
  documented-but-false assumption true). The zero-external-API invariant, the
  multi-space render-unchanged invariant, and opt-in commit/push are untouched.

## Open items (confirm during spec review)

- None — all three fixes and the deferral are settled. (I#2's exact line numbers
  are from the review against `af343a4`; the implementer matches by anchor text,
  not line number, in case of drift.)

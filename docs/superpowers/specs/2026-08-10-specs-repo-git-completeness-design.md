# Specs-repo git completeness — design

**Status:** approved 2026-08-10
**Sub-project:** C of the 2026-08-07 PM feedback round on `dev-workflows` (A shipped 2.42.0, B1 2.43.0, B2 2.44.0)
**Target versions:** canonical `dev-workflows` 2.44.0 → **2.45.0**; mgd 2.44.0 → **2.45.0**; copilot 2.14.0 → **2.15.0**

---

## 1. Problem

`$SPECS_PATH` is a git repository that **no `dev-workflows` command ever commits.** Seventeen of the twenty-one commands write artifacts into it; none of them commits those artifacts. The five commands that do run git against the specs repo commit only their deliverable, in a phase that fires *before* the artifacts are written.

The purpose of the per-VI artifact area is aggregation to the plugin maintainer. `references/feedback-emission.md:12-14` states it outright:

> Feedback reaches the maintainer only if it lands in the committed, pushed specs repo — hence the persistence ladder is **specs-first** (§2).

Nothing in the plugin makes that landing happen.

### 1.1 Evidence

Source entry: `$SPECS_PATH/specifications/PRODUCT-13950-managed-self-monitoring-lifecycle-events/dev-workflows/PRODUCT-13950-feedback.md:414-420` — `category: manual-workaround`, `impact: friction`, `origin: prompt`. Its own diagnosis: *"The ordering makes this outcome certain, not occasional."*

The specs repo carries the receipts. Twenty-eight artifact files are tracked across nine VI directories, every one of them landed by a hand-written housekeeping commit after the fact:

| Commit | Subject |
|---|---|
| `28dd702` | `NOISSUE Log /prompt feedback: dev-workflows artifacts are written after the git step` |
| `60a6a39` | `NOISSUE Add dev-workflows session artifacts for PRODUCT-13950 and PRODUCT-14589` |
| `9e807e2` | `PRODUCT-15670 Add /update-vi session telemetry (resume, cost, feedback)` |
| `68b65ad` | `PRODUCT-18503: Feedback and cost reports` |
| `4e536b9` | `Add resume pointer for PRODUCT-18503 VI session` |

`28dd702` is the sharpest instance: the feedback entry recording this very defect had to be committed by hand, by a command (`/prompt`) that the source feedback never identified as affected.

### 1.2 Second defect, found while surveying

`references/session-hygiene.md:16-19` requires the resume pointer be written "AFTER the deliverable artifact is saved/committed and AFTER `emit-cost` / feedback / follow-up." **Eight of the ten commands that write `resume.md` violate this.** Only `/design` and `/specify` comply. This is in scope (§7) because the new terminal step forces the canonical order to be stated, and that same `session-hygiene.md` sentence is edited either way.

---

## 2. Scope

Seventeen commands write into `$SPECS_PATH`, in three classes.

| Class | Commands | Specs-repo git today |
|---|---|---|
| **A** — specs-repo git offer, fires before the artifacts exist | `/create-vi` `/update-vi` `/create-ard` `/specify` `/design` | deliverable committed on a `vi\|ard\|spec\|design/*` branch; artifacts orphaned |
| **B** — git targets a *different* repo, or no git at all | `/idea` `/epics` `/ready` `/release-notes` `/implement` `/document` (both modes) `/vuln` `/upgrade` | specs repo never touched by git |
| **C** — pure emitters via the §2 ladder | `/feedback` `/prompt` `/prompt-brainstorm` `/prompt-grill-me` | specs repo never touched by git |

**Out of scope — write nothing into `$SPECS_PATH`:** `/api-guideline-reviewer`, `/guideline-reviewer`, `/statusline`, `/docs-profile`.

Class-A git offers target `$SPECS_PATH` (`create-vi.md:192`, `update-vi.md:92`, `create-ard.md:131`, `specify.md:410`, `design.md:305`). Class-B git, where it exists, targets a code repo (`/implement`, `/vuln`, `/upgrade`) or a docs repo (`/document`, `document.md:708-766`, `1036-1062`) — never the specs repo. Class-C commands resolve their write target through the same specs-first ladder (`feedback.md:55`, `prompt.md:42`, `prompt-brainstorm.md:32`, `prompt-grill-me.md:36`) and declare `NEVER commits`.

### 2.1 Non-goals

- **The primary artifacts do not move.** Code and tests stay in the code repo; documentation stays in the docs repo; the deliverable VI/ARD/spec/design stays where its handoff phase puts it. This design touches only the bookkeeping artifact area.
- **No new external-API surface.** `git push` is git-protocol, already sanctioned (`finish-and-handoff.md` §3). No PR is created by either new entry point; no REST call is added.
- **The vault is not managed.** Tier-3 fallbacks that write into `$VAULT_PATH` (`feedback-emission.md` §2 tier 3, `session-hygiene.md` §1 tier 3) stay the user's own sync responsibility.

---

## 3. Deviation from the source feedback's recommendation

`PRODUCT-13950-feedback.md:420` recommends: *"move the git offer to the true end of the run… Option (a) is better — it removes the manual step rather than documenting it."*

**This design does not move the git offer.** Two reasons:

1. **It fixes 5 of 17.** Class B and class C have no specs-repo git offer to move. The feedback identified only class A plus a misread of `/release-notes` (which it describes as repeating the pattern, but which has no git step at all — `release-notes.md:393`).
2. **For class A it is a regression.** The handoff phase is where the user sees the deliverable and decides on the PR, and where the Jira round-trip instructions live (`create-vi.md:194-199`). Deferring it past the maintenance, feedback, and cost phases delays the PR and detaches the round-trip from the handoff it belongs to.

Instead: **the handoff stays exactly where it is, and a second bounded commit is appended at the very end of the run.** Class A produces two commits on one branch; class B and C produce one commit on the default branch. One mechanism covers all seventeen.

The feedback's core diagnosis — that phase ordering defeats the subsystem's stated purpose, and that the `NEVER commits` invariant on the terminal phases is itself sound — is accepted in full. Only the remedy differs.

---

## 4. New reference: `references/specs-repo-git.md`

A single shared reference owning both entry points, in the plugin's established `emit-*` idiom (`feedback-emission.md`, `cost-emission.md`, `followup-emission.md`). Commands cite it and execute its steps inline; the orchestrator owns any prompt.

Entry points:

- **`specs-preflight`** — run start (§6)
- **`commit-artifacts`** — terminal step (§5)

### 4.1 Repository handle

**Every git invocation uses `git -C "$SPECS_PATH" …`. The working directory is NEVER changed.** Eight of the seventeen commands are operating inside a *different* repository (code or docs) at the time these entry points run; a `cd` would corrupt their own git state. This is a hard rule and a review-checkable one.

### 4.2 Bounded write authority — paths

Exactly three path shapes, derived from the emission ladders. Nothing outside this set is ever staged, and `git add -A` is never issued at repository scope.

```
<specs-root>/{specs|specifications|vis}/**/dev-workflows/**   # tier 1: feedback, cost, follow-ups, resume.md
<specs-root>/dev-workflows-feedback/**                        # feedback-emission.md §2 tier 2 (keyless runs)
<specs-root>/dev-workflows-cost/**                            # cost-emission.md §9 pending files (keyless runs)
```

Sources: `feedback-emission.md:88-100` (tiers 1–2), `cost-emission.md:275-278` and `:298` (tier 1 + pending), `followup-emission.md:90-92` and `:119-125` (the shared per-VI area), `session-hygiene.md:28-31` (resume tier 1).

**Staging is by enumeration, not by glob.** Pathspec glob magic (`:(glob)`) is fragile to express and to review. The procedure is:

1. `git -C "$SPECS_PATH" status --porcelain --untracked-files=all`
   (`--untracked-files=all` is required — the default collapses an untracked directory to a single `?? dir/` line, which would hide which files are being staged.)
2. Classify each reported path: **ARTIFACT** if it matches `^(specs|specifications|vis)/.+/dev-workflows/` or `^dev-workflows-feedback/` or `^dev-workflows-cost/`; **OTHER** otherwise.
3. Stage with the literal ARTIFACT paths only: `git -C "$SPECS_PATH" add -A -- <path> [<path>…]`.

`-A` is required, not optional: `cost-emission.md:186-192` relocates a pending cost file into a VI directory and then **deletes** it ("Relocation moves, then DELETES"). That deletion must be staged, and plain `git add` would not stage it.

### 4.3 Bounded write authority — branches

**The plugin manages only branches it created.** A branch is plugin-owned when its name matches `^(vi|ard|spec|design)/`. Any other branch — the user's own work, a hand-made branch, a detached HEAD — is left alone and never switched away from (§6.1 guard G2).

---

## 5. `commit-artifacts` — terminal step

Runs as the **last step of the run**, after `resume.md` is written and before the final report is printed. All seventeen commands.

1. **Gate.** `$SPECS_PATH` is set, exists, is writable, and `git -C "$SPECS_PATH" rev-parse --git-dir` succeeds. Any failure → **silent no-op**, matching the emission ladders' silent-skip discipline: nothing is committed, nothing is reported, and the run is unaffected. The artifacts in this case went to a vault or report-only tier, which the plugin does not manage (§2.1).
2. **Enumerate and stage** per §4.2. OTHER paths are never staged.
3. **Nothing staged** (the gate passed but no artifact path is dirty) → no commit; one line in the final report: `Specs repo: no session artifacts to commit`. This is distinct from step 1's silence — here the specs repo *is* managed and simply had nothing new.
4. **Commit.** Message: `<KEY> Add dev-workflows session artifacts (<command>)`, or `NOISSUE Add dev-workflows session artifacts (<command>)` when the run resolved no key. This matches the specs repo's own `<KEY|NOISSUE> <summary>` convention (`31d2cc6`, `60a6a39`, `28dd702`).
   **No `Co-Authored-By` trailer.** These are plugin-generated bookkeeping files, not authored content, and each artifact already carries its own `author:` field (`feedback-emission.md:130-133`). Adding a trailer would also hardcode a model name that goes stale — `create-vi.md:192` still names Opus 4.8.
5. **Push** to the current branch's upstream. If the branch has no upstream, `git -C "$SPECS_PATH" push -u origin <branch>`.
6. **Failure at any step is reported, never fatal.** The run never fails because of this step.
   - No remote / auth failure → report; the commit stays local.
   - **Non-fast-forward rejection** → report; **never force-push**, never auto-rebase mid-run. The commit stays local and the next run's `specs-preflight` will surface the branch.
7. **Report** in the final report: the short SHA, the file count, the branch, and the push result.

### 5.1 Where the commit lands

- **Class A** — on the `vi|ard|spec|design/*` branch the handoff phase created, so the push updates the pull request that is already open. Two commits on one branch: the deliverable, then the artifacts.
- **Class A, git declined at handoff** ("Just write the files — I'll handle git") — the repo is still on the default branch and the deliverable is uncommitted there. `commit-artifacts` still runs and commits **only** the bookkeeping paths; the uncommitted deliverable is untouched, because it is an OTHER path. This is deliberate: the user's "I'll handle git" refers to their deliverable, and the bookkeeping still has to reach the maintainer. The final report states plainly that the deliverable remains uncommitted.
- **Class B and C** — on the default branch.

---

## 6. `specs-preflight` — run start

Runs as early as `$SPECS_PATH` is known — Phase 0 in most commands (§8). **Prompt-free.** It is silent when the repository is already clean and on the default branch; it reports a compact block only when it acts.

**Gate:** identical to §5 step 1. Not a git repo, unset, or unwritable → silent no-op.

**Default branch resolution:** `git -C "$SPECS_PATH" symbolic-ref --quiet refs/remotes/origin/HEAD` → strip `refs/remotes/origin/`. Verified against the live specs repo, which resolves to `main`. If unset, fall back to `main`, then `master`, then the current branch (in which case no branch switching occurs).

**Freshness:** best-effort `git -C "$SPECS_PATH" fetch origin <default>` before the ancestry test. On failure (offline, auth), use the existing local `origin/<default>` ref and note `offline — ancestry checked against the last-fetched ref`. Never fatal.

**Run key:** the entry point takes the run's Jira key if it is already resolved at the call site, and otherwise treats the run as **keyless**. Both paths are correct behaviour, so no command needs to defer its preflight to obtain a key. `/create-vi` is structurally keyless here — its key is minted by the Jira round-trip in Phase 5 (`create-vi.md:194-199`) — and keyless is the right classification for it, since a new VI must not stack on another VI's branch.

### 6.1 Resolution — three stages

Not a first-match table: stage 1 can end the preflight, and stage 2 always runs before stage 3.

**Stage 1 — guards. Either match ends the preflight; the run proceeds.**

| # | State | Action |
|---|---|---|
| G1 | Any dirty **OTHER** path (§4.2) | **Hands off.** No commit, no branch switch, no push. One-line report naming the count. Those files are not the plugin's, and switching branches would carry them. |
| G2 | HEAD is detached, **or** on a branch that is neither the default branch nor a match for `^(vi\|ard\|spec\|design)/` | **Leave it; stay on it.** One-line report. The plugin manages only branches it created (§4.3). |

**Stage 2 — flush leftovers.** If any dirty ARTIFACT path exists, commit it **onto the current branch** (it belongs to the run that wrote it) and push, per §5 steps 2–6. If none exists, do nothing. Either way, continue to stage 3 with a clean tree.

**Stage 3 — branch disposition.** First matching row applies.

| # | State | Action |
|---|---|---|
| B1 | On the default branch | Nothing further. |
| B2 | Plugin branch, and `git merge-base --is-ancestor HEAD origin/<default>` succeeds (already merged upstream) | Switch to default, `git pull --ff-only`, `git branch -d <branch>`. If `-d` fails, report and skip — **never `-D`**. |
| B3 | Plugin branch, unmerged, branch key **==** run key | **Stay on it.** See §6.2. |
| B4 | Plugin branch, unmerged, branch key **≠** run key, or run keyless | Switch to default, `git pull --ff-only`. **Leave the branch and its pull request alone.** Report the branch name. |

**Branch key extraction:** strip the `vi/`, `ard/`, `spec/`, or `design/` prefix, then take the leading token matching `[A-Z][A-Z0-9_]*-[0-9]+`. No match → treat as "not this run's key" (B4).

### 6.2 Why B3 exists — do not "simplify" it away

B3 looks redundant next to B4 and is the obvious candidate for a future simplification into "always return to the default branch." **That simplification is a bug.**

`/create-ard PRODUCT-13950` run after `/create-vi` finds the repo on `vi/PRODUCT-13950-…` with an unmerged pull request. The authored VI file exists **only on that branch**. Switching to the default branch removes it from the working tree — and `create-ard.md:63` reads the VI from `$SPECS_PATH/specifications/<VI>-<vslug>/`, falling back to `jira-reader` against the Jira export when the authored file is absent. The fallback is **silent**: the run would quietly architect against the stale Jira export instead of the VI just authored, with no error to notice. B3 keeps the working tree containing the artifact the run is about to read.

The cost is that the follow-up command's own branch is cut from the earlier branch rather than from the default — a stacked branch. That is correct: an ARD genuinely depends on its VI, and stacking is the honest representation.

### 6.3 No auto-merge

The design deliberately never creates a merge commit and never merges a branch into the default branch.

The user's stated position was that auto-merging to the specs repo's default branch would be acceptable, since engineers work on separate VIs and conflicts are rare. It is left out because the branch/key routing in §6.1 already resolves every case correctly without one, and because an auto-merge would push an unreviewed VI or ARD past the very pull request the command opened for it one phase earlier. B2 handles the only case where a merge would have been needed — a branch already merged upstream — with cleanup rather than a merge.

If auto-merge is wanted later it slots into B4 as `merge --ff-only → push → branch -d`, with B3 unchanged.

---

## 7. Canonical terminal order

The new step forces the order to be stated once, in `references/session-hygiene.md` §1, and followed everywhere:

> deliverable + handoff → feedback → follow-ups → cost → `resume.md` → **`commit-artifacts`** → final report

`session-hygiene.md:16-19` already places `resume.md` after cost, feedback, and follow-ups. Eight of the ten commands that write it violate that:

| Command | `resume.md` at | Violates because |
|---|---|---|
| `/create-vi` | Phase 6 (`create-vi.md:219`) | before feedback + cost (Phase 7, `:242-243`) |
| `/update-vi` | Phase 6 (`update-vi.md:112`) | before feedback + cost (Phase 7, `:125-126`) |
| `/create-ard` | Phase 7 (`create-ard.md:143`) | before feedback + cost (Phase 8, `:164-165`) |
| `/ready` | Phase 5 (`ready.md:340`) | before feedback (6), follow-ups (7), cost (8) |
| `/release-notes` | Phase 8 (`release-notes.md:281`) | before follow-ups (9), feedback (10), cost (11) |
| `/epics` | Phase 9 (`epics.md:614`) | before follow-ups (10), cost (11) |
| `/document` (Jira) | Phase 9 (`document.md:1195`) | before follow-ups (10), cost (11) |
| `/implement` | Phase 5 (`implement.md:618`) | before follow-ups (6), cost (7) |

Compliant: `/design` (`design.md:404`), `/specify` (`specify.md:509`). Not applicable — write no `resume.md`, per the `session-hygiene.md:21-24` skip list: `/idea`, `/implement` direct mode, `/document` direct mode, `/vuln`, `/upgrade`.

Each of the eight moves its `resume.md` write to after its cost phase. `session-hygiene.md` §1 gains the `commit-artifacts` step as the sentence's new terminus.

---

## 8. Per-command wiring

Each of the seventeen command files gains one `specs-preflight` citation and one `commit-artifacts` citation — except `document.md`, which shares one Phase 0 preflight across both modes but needs a `commit-artifacts` step in each, for **17 preflight sites and 18 commit sites**. Neither entry point takes a decision from the orchestrator; both are cited and executed inline.

| Command | `specs-preflight` at | `commit-artifacts` at |
|---|---|---|
| `/create-vi` | Phase 0 | after Phase 7 (post-cost, post-resume) |
| `/update-vi` | Phase 0 | after Phase 7 |
| `/create-ard` | Phase 0 | after Phase 8 |
| `/specify` | Phase 0 | after Phase 9 |
| `/design` | Phase 0 | after Phase 9 |
| `/idea` | Phase 0 | after Phase 6 |
| `/epics` | Phase 0 | after Phase 11 |
| `/ready` | Phase 0 | after Phase 8 |
| `/release-notes` | Phase 0 | after Phase 11 |
| `/implement` | Phase 0 | after Phase 7 |
| `/document` (Jira) | Phase 0 | after Phase 11 |
| `/document` (direct) | Phase 0 | after Phase 7 |
| `/vuln` | before step 1 | after step 4 |
| `/upgrade` | before Phase 1 | after Phase 2 step 9 |
| `/feedback` | at start | at end |
| `/prompt` | at start | at end |
| `/prompt-brainstorm` | at start | at end |
| `/prompt-grill-me` | at start | at end |

### 8.1 The `NEVER commits` contradiction — highest-risk item

Roughly thirty lines across the command set assert that a phase or a whole command `NEVER commits`. **Every one of them becomes false or ambiguous** the moment `commit-artifacts` ships. Shipping the step without reconciling them is a self-contradicting plugin.

Known sites include `create-vi.md:245`, `update-vi.md:128`, `create-ard.md:167`, `specify.md:469,495`, `design.md:361,387`, `idea.md:192`, `epics.md:13,451,607,641,668,679,687`, `ready.md:3,331,363,453,482,509,518-519`, `release-notes.md:309,347,376,393`, `implement.md:561,650,676`, `document.md:1031,1225,1251,1531,1617,1639,1666,1679`, `vuln.md:181`, `upgrade.md:155`, `feedback.md:63`, `prompt-brainstorm.md:43`, `prompt-grill-me.md:50`, `prompt.md:48`, `statusline.md:71`.

**Reconciled wording.** The invariant is scoped rather than deleted — its protective intent is real and stays:

> NEVER commits into a code/docs repo, the vault, or the current working directory. The terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4.2).

`/statusline` keeps its unscoped `NEVER commits` — it writes only under `~/.claude/` and is out of scope.

**Verification:** after the change, every remaining unscoped `NEVER commit` assertion in an in-scope command must either name the `$SPECS_PATH` carve-out or be justified in place. This is grep-checkable and belongs in the plan as an explicit count.

### 8.2 Sibling references to update

- `feedback-emission.md:12-14` — the "reaches the maintainer only if it lands in the committed, pushed specs repo" sentence is now satisfied automatically; state that and cite the new reference.
- `feedback-emission.md:182` ("None of them commits"), `cost-emission.md:334` ("it NEVER commits"), `followup-emission.md:183` ("the phase NEVER commits") — still true of the *emitters*, but each must cross-reference `commit-artifacts` so a reader does not conclude the artifacts are never committed at all.
- `session-hygiene.md:16-19` — §7's terminal order.
- `CLAUDE.md` (repo root) — the workflow map and the key-invariants section.

### 8.3 Dead-gate watch

Per the defect class that dominated B1 and B2: a rule ships whose consumer never receives the data. Two new producers here, each with exactly one consumer:

| Producer | Transport | Consumer |
|---|---|---|
| `specs-preflight` actions report | inline block at Phase 0 | printed immediately; **plus** a `Specs repo:` line in the final report |
| `commit-artifacts` SHA + push result | run state | the **final-report template** of each in-scope command — 18 templates (`/document` has one per mode) |

The transport leg that will be dropped is the final-report template — it lives in a section neither entry point owns. **All 18 final-report templates must gain the `Specs repo:` line**, and the plan must assign that leg explicitly rather than assuming it rides along with the citation. `/vuln`, `/upgrade`, and the four class-C commands have no phase named "Final report"; there the line goes at the end of the run's printed output, which §8's table pins per command.

---

## 9. Three-repo port

| Repo | Edition | Version |
|---|---|---|
| `/workspace/ihudak-claude-plugins` | canonical | 2.44.0 → **2.45.0** |
| `/workspace/mgd-claude-plugins` | content-verbatim except its 5 identity files | 2.44.0 → **2.45.0** |
| `/workspace/ihudak-copilot-plugins` | adapted layout and dialect | 2.14.0 → **2.15.0** |

**Both `marketplace.json` catalogs and `.github/copilot-instructions.md` must appear explicitly in the per-repo file tables.** Each was missed in 2.42.0.

### 9.1 Copilot edition differences

- **No cost subsystem at all.** `skills/_shared/` contains no `cost-emission.md`; there are zero `emit-cost` references; `scripts/` contains only `specification-to-html.py`. The copilot artifact set is therefore **feedback + follow-ups + `resume.md`**, and the `dev-workflows-cost/**` glob (§4.2) is **omitted** from that edition. The `-A` staging requirement still holds — follow-up and feedback files can be removed by the user between runs.
- No `${CLAUDE_PLUGIN_ROOT}`: references live at `skills/_shared/`, commands at `skills/<name>/SKILL.md`, catalog at `.github/plugin/marketplace.json`.
- No `subagent_type`; agents are referenced by their `name:` idiom.
- The copilot edition has no `/statusline`, so §8.1's carve-out note does not apply there.

---

## 10. Verification

This is a prompt-markdown repository: the "code" is instruction text an LLM executes at run time. There is no build and no test framework. Verification is grep, diff, and reading — the same discipline used in A, B1, and B2.

| # | Check | Expectation |
|---|---|---|
Counts are per edition. **17 command *files* are in scope in every edition**, but `/document` carries two modes in one file, so call-site counts differ from file counts where noted. Canonical and mgd hold 21 commands (17 in scope, minus `/api-guideline-reviewer`, `/guideline-reviewer`, `/statusline`, `/docs-profile`); copilot holds 20 (no `/statusline`), so 17 in scope there too.

| # | Check | Expectation |
|---|---|---|
| V1 | `references/specs-repo-git.md` exists (copilot: `skills/_shared/specs-repo-git.md`) | 1 file per edition |
| V2 | Command **files** citing `specs-repo-git.md` (`grep -l`) | 17 |
| V3 | `specs-preflight` call sites (`grep -c`, summed) | 17 — one per file; `/document`'s Phase 0 is shared by both modes |
| V4 | `commit-artifacts` call sites (`grep -c`, summed) | **18** — one per file, **two** in `document.md` (Jira after Phase 11, direct after Phase 7) |
| V5 | Final-report templates carrying the `Specs repo:` line | **18** — same split as V4 (§8.3) |
| V6 | Every line matching `NEVER commit` / `never commit` in an in-scope command file also contains `code/docs repo` or `specs-repo-git` on that same line | 0 non-conforming lines (§8.1). Line-level grep is sufficient because `references/prose-formatting.md` forbids hard-wrapping, so each assertion occupies one line. `/statusline` is excluded — out of scope, keeps its unscoped wording |
| V7 | `cd ` inside `specs-repo-git.md` | 0 — every git call is `git -C "$SPECS_PATH"` (§4.1) |
| V8 | `git add -A` occurrences in `specs-repo-git.md` not followed by ` -- ` on the same line | 0 (§4.2) |
| V9 | `--force` / `push -f` / `branch -D` in `specs-repo-git.md` | 0 (§5 step 6, §6.1 B2) |
| V10 | `resume.md` written after the cost phase | 10 of the 10 commands that write it (§7) |
| V11 | `dev-workflows-cost` in the copilot edition | 0 (§9.1) |
| V12 | mgd diff against canonical | exactly the 5 identity files |
| V13 | CHANGELOG ordering monotonic in all three | canonical/mgd 2.45 → 2.44 → …; copilot 2.15 → 2.14 → … |

---

## 11. Risks

1. **The `NEVER commits` contradiction (§8.1)** — the largest. Thirty-odd assertions across seventeen files, in a plugin whose reviewers check for internal contradiction. Mitigated by V6 as a hard count, and by concentrating the reconciliation in one task so a single implementer holds the wording.
2. **The final-report transport leg (§8.3)** — the classic dead gate: the citation lands, the report line does not. Mitigated by V5 as a hard count.
3. **B3 being "simplified" later (§6.2)** — a plausible-looking cleanup that breaks `/create-ard` after `/create-vi`. Mitigated by the rationale living in the reference itself, not only in this spec.
4. **A run that pushes to a moved remote** — non-fast-forward rejection. Mitigated by explicit no-force, no-auto-rebase, report-and-continue (§5 step 6), and by the next run's preflight surfacing it.
5. **Prompt-free preflight acting on a repo the user is mid-edit on** — mitigated by guard G1 (any dirty OTHER path ⇒ hands off entirely) and by branch authority being limited to the four plugin prefixes (§4.3).

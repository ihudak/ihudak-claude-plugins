# Sub-project J — Phase-handoff gates + PR-on-completion

**Date:** 2026-08-14
**Ships as:** dev-workflows 2.52.0 (canonical) / 2.52.0 (mgd) / 2.22.0 (copilot)
**Inputs:** `docs/superpowers/specs/2026-08-13-phase-handoff-gates-decisions.md` (the decisions agreed in conversation on 2026-08-13), plus finding **I3** absorbed from sub-project I.

---

## 1. Context

The plugin's authoring commands form a role-handoff chain: `/idea` (PM) → `/create-vi` (PM) → `/create-ard` (PA) → `/specify` (PE) → `/design` (Dev) → `/implement` (Dev), with `/epics` (PE) branching off the VI and `/ready` (QA) auditing the whole chain. Each command writes its deliverable into `$SPECS_PATH` (`Dynatrace-Internal/mgd-specifications`, GitHub) and then *offers* to branch, commit, push, and open a PR.

Three things are broken today:

1. **The PR offer has no machinery.** Five commands print `"Branch + commit + push + open PR to main (Recommended)"`, but no reference defines how to open a PR. `gh pr create` appears in the plugin only as a string printed *for the user to run* (`finish-and-handoff.md:71`, `document.md:1080`). Two NEVER rules — `specs-repo-git.md:20` and `finish-and-handoff.md:74` — read as a blanket ban.
2. **Nothing verifies the previous phase finished.** `/design` is the only command with an on-main gate, and it is finding **I3**: `design.md:50-57` claims to "confirm the spec is on main" but implements a worktree file-existence test, which passes on any branch that happens to carry the file. The same defect sits a second time in the Epic picker at `design.md:67-68`.
3. **Two commands write into `$SPECS_PATH` and never commit it.** `/implement` Phase 7.5 (`implement.md:488`) writes `- [ ]` escalation notes onto `specification.md`/`design.md`; `/ready` writes `_readiness.md`. `commit-artifacts` stages only the `dev-workflows/**` bookkeeping paths (`specs-repo-git.md` §2.1), so both are OTHER paths that sit dirty forever and trip the §3.3 G1 advisory on every subsequent run of every command.

The "no PR" rules were never a policy choice. They exist because the docs repo and most code repos are **Bitbucket**-hosted, where no CLI can open a pull request. `$SPECS_PATH` is GitHub, `gh` 2.97.0 is installed and authenticated (`ivan-gudak`, `repo` scope, `viewerPermission: WRITE` on `mgd-specifications`), so there the PR *can* be opened.

## 2. Governing principle

> A workflow phase is not finished until its artifact is on `main`. A command that ends a phase must commit, push, **and open a PR**. The command that starts the next phase refuses to run until the previous artifact is on `main`.

The gate applies **even when the role does not change** — it may be a different human of the same role, and even the same human should have to confirm the previous phase is done and approved. `main` is the signal of readiness. Without the gate the next person may struggle to find the right files, or silently build on an older version.

**Corollary adopted 2026-08-14:** anything a command writes into `$SPECS_PATH` must reach `main` by the same route. This is what brings `/implement` Phase 7.5 and `/ready` in as producers.

## 3. Decisions

Each decision records the alternative rejected, so a later reader does not re-open it.

### D1 — PR creation lives in the **Handoff phase**, not in `commit-artifacts`

`handoff-to-main` is called from each producing command's Handoff phase, behind the consent choice that already lives there.

*Rejected:* decision §1 as originally written, which put PR creation in `commit-artifacts`. Two reasons it fails. `commit-artifacts` is **prompt-free** by `specs-repo-git.md` §1 rule 7, and opening a PR is an outward-facing action that must be consented to; consent belongs where asking is possible. And `commit-artifacts` runs for seventeen commands, most of which never create a branch, so it would need to learn per-run whether a branch exists — coupling for no gain.

*Also rejected:* a split where the Handoff takes consent and pushes but `commit-artifacts` opens the PR at the end. A run that dies after the Handoff would leave a pushed branch that nothing ever opens a PR for — the preflight flush (§3.4) creates no PRs.

### D2 — Merge authority: nobody. Both sides hard-stop.

The producing command opens the PR and stops. The consuming command hard-stops naming the open PR. Merging happens in the forge, by a human.

*Rejected:* letting the producer offer `gh pr merge` (turns the PR into ceremony for solo runs, and `main` is protected so it may fail anyway), and letting the consumer offer to merge (the consumer would approve the producer's work, which is exactly the confirmation the principle exists to force).

### D3 — The gate tests the `origin/<default>` ref **and** worktree blob equality

`git -C "$SPECS_PATH" cat-file -e origin/<default>:<relpath>` establishes "on main" — checkout-independent, which is what fixes I3. Then the worktree copy's blob must equal the ref's blob, so the run provably reads the approved bytes.

*Rejected:* ref-existence only while still reading the worktree (a weaker I3 — the gate passes while the run reads branch-local or uncommitted content and reports it as "on main"). *Also rejected:* reading content from the ref via `git show` and ignoring the worktree — `/design` and `/implement` also *write* to `specification.md`, so they need a worktree copy anyway, and two sources of truth in one run means the file edited is not the file read.

### D4 — A new reference, `references/phase-handoff.md`

Both new entry points live there, not in `specs-repo-git.md`, which contradicts them on three points: its declared scope is the §2.1 bookkeeping paths and it explicitly classes a deliverable as an OTHER path; its rule 5 is **never fatal** while the consumer gate is fatal by design; its rule 6 forbids the `Co-Authored-By` trailer that deliverable commits already carry (`create-vi.md:201`). It cites `specs-repo-git.md` for the shared primitives: `git -C` always and never a `cd` (§1 rule 1), default-branch resolution (§3.2), never destructive (§1 rule 4), the branch authority (§2.2).

*Rejected:* a third section inside `specs-repo-git.md`. It would have to state three exceptions to its host file's own hard rules — the shape that produces contradictory-SSOT findings.

### D5 — Two new branch prefixes: `idea/` and `ready/`

The authority becomes `^(idea|vi|ard|spec|design|ready)/`.

*Rejected:* reusing `vi/` for `/idea` (a name that lies about its content, and `/idea` and `/create-vi` would compete for it). *Rejected for `/implement` Phase 7.5:* a seventh prefix — its notes amend an existing artifact, so it reuses that artifact's own prefix (`spec/` or `design/`; `design/` when both files got notes).

### D6 — Branch-name collision is disambiguated, never forced

`handoff-to-main` step 1: if a branch of the intended name exists locally **or** on `origin`, then — if it is this run's own in-progress branch (same prefix, key in the run key set, unmerged) reuse it; otherwise append the lowest free `-2`, `-3`, … suffix.

This is not hypothetical. `_readiness.md` is overwritten on every `/ready` run, so a second run on the same key collides. Re-running `/create-vi` after its VI PR merged collides the same way, and `gh pr create` fails on an already-merged branch.

*Rejected:* force-pushing over the existing branch (forbidden by `specs-repo-git.md` §1 rule 4) and deleting it (forbidden — never `branch -D`).

### D7 — The PR is opened by capability probe, not by host classification

Try `gh pr create`; on any failure fall back to pushing the branch and printing the exact instruction for the user to open the PR in the host's web UI. A cheap `gh auth status` pre-check avoids a confusing error, but the fallback is triggered by actual failure.

Rationale: push authority and PR authority are **independent**. Push runs over SSH with a per-repo key; `gh pr create` runs over the API with a token. The same account here has `WRITE` on `Dynatrace-Internal/mgd-specifications` but only `READ` on `ihudak/ihudak-claude-plugins`. No hostname or host-type test can detect that mismatch — a run can push successfully and still be unable to open the PR.

*Rejected:* classifying the remote host up front and branching on it, as `finish-and-handoff.md` §4 does for the docs repo. Correct there (it only needs to choose *instructions*); insufficient here.

### D8 — Gate coverage

Every command that reads an artifact out of `$SPECS_PATH` gates on it, including the ARD.

**The gate never makes an optional input mandatory.** Every gated input keeps its current optionality; the gate adds exactly one new outcome, for an artifact that **exists but is not on main**. Absent stays absent.

- **The ARD stays optional.** `references/ard-resolution.md:39` states `status: none` is "the common case — `/create-ard` is optional", and `:43` makes it a **no-regression rule**: a caller receiving `none` must behave exactly as it did before the ARD feature existed. J does not touch that. What J adds is `unmerged`, which is reachable only when an ARD file resolves and is not on main — the case where the run would otherwise either bind itself to unapproved `AD-N` rules or silently discard approved-in-progress ones. There is no VI-level vs Epic-level difference: both resolve through the same entry point and both keep the same optionality.
- **VI-level `/specify` stays optional.** `/epics`'s VI-level `specification.md` is grounding, not a prerequisite. **Absent** ⇒ the existing silent skip (`vi_spec_present: false`), so the Jira-export-only path works exactly as today. **Present but not on main** ⇒ stop, because drafting Epics against a weaker basis than the one about to land means re-doing them.
- **The gated readers are the five in `ard-resolution.md`'s own Consumers section** (`:59-63`): `/design`, `/implement`, `/specify`, `/epics`, `/ready`. That file's header at `:4-5` names only four, omitting `/ready` — a stale caller list contradicted by its own body (§7).
- **`/ready` never stops.** Its job is to report readiness, so a not-on-main artifact becomes a **finding** that caps the verdict at PARTIAL — "authored but not handed off". Reporting a phase complete when its artifact is not on main is precisely the lie the gate exists to prevent.

*Rejected:* limiting coverage to decision §2's six commands, which omitted `/epics` and the ARD entirely.

### D9 — `ard-resolution.md` gains a third status

`status: none | found | unmerged`. `unmerged` stops every caller except `/ready`, which records it as a finding.

*Rejected:* mapping unmerged onto `none`. That is the dead-gate shape — the caller proceeds ungoverned and reports nothing.

### D10 — `specs-repo-git.md` §3.5 B3 and §3.6 survive, with a rewritten rationale

**This deviates from decisions §6**, which predicted §3.6 "largely dissolves". It does not. B3 is required by gate state **B**: `/design` resuming its own branch legitimately holds a `specification.md` that differs from main, because `/design` itself amends it. Without B3, the preflight would switch away from that branch, and rows A/C alone would then offer "switch to main + pull", discarding in-progress design work.

What changes is the *reasoning*. §3.6's current justification — the silent-stale-fallback bug where `/create-ard` quietly architects against a stale Jira export — is now caught loudly by `require-on-main`. §3.6 is rewritten to justify B3 by same-phase resume plus `/ready`'s explicit-checkout case, and to cross-reference the gate. Behaviour is unchanged.

*Rejected:* narrowing B3 to "this command's own prefix only". `/ready` has no prefix of its own, so the narrowing would drop the case §3.6 explicitly documents.

### D11 — `/implement` Phase 7.5 and `/ready` become producers

Both write into `$SPECS_PATH` and neither reaches main today. **This extends the agreed decisions.**

`/ready`'s `NEVER auto-commit _readiness.md` invariant (`ready.md:558`) **narrows rather than flips**: the commit goes behind the same consent choice as every other producer, so "never automatically" stays true.

*Rejected:* folding these paths into `specs-repo-git.md` §2.1 so `commit-artifacts` stages them. §2.1 is the bookkeeping area; a deliverable committed with no branch, no PR, and no consent contradicts the principle. *Also rejected:* leaving them out of J, which would knowingly ship two commands that dirty the specs repo on every run.

### D12 — `/create-vi`'s contract changes; `/idea` owns relocation

- **`/create-vi <KEY>`** — in-contract. Derives the idea from `<KEY>` at `specifications/<KEY>-<slug>/idea.md`. The gate applies. **No relocation** — `/idea` already did it.
- **`/create-vi <KEY> @<path>`** — explicitly out-of-contract. Reads the idea where it sits, **does not move it**, and the gate does not apply.

This is a **breaking change**: called out in each edition's CHANGELOG under breaking changes and in each README's `/create-vi` row.

*Rejected:* a staging directory (`specifications/_inbox/<slug>/`) holding the idea before a key exists. It puts unkeyed artifacts into a repo whose whole grammar is keyed, and creates an abandoned-idea cleanup problem, for a case `@<path>` already covers.

### D13 — `/update-vi` is a producer but **not** a consumer

`/update-vi` Phase 0 step 5 globs `*_ARD.md` and `specification.md` out of the feature folder as *secondary* grounding, and Phase 2 states that where the frozen draft disagrees with the Jira import, **the import wins**. Its authoritative input is therefore the Jira export, not the specs repo, and gating an advisory read would block a legitimate VI refresh because an unrelated ARD happens to sit on a branch.

So `/update-vi` calls `handoff-to-main` for its own output (R14) and is **not** gated on its secondary reads. An artifact found only off main is **reported** in the Phase 1 confirmation, beside the divergence notice already there.

*Rejected:* gating it for symmetry with the other ARD readers. `/update-vi` does not use `ard-resolution.md` and does not treat the ARD as binding, so the ARD's contract status is not what its run depends on.

*Also rejected:* saying nothing about `/update-vi`. An omitted command reads as an oversight, and the next reviewer re-opens it.

## 4. The new reference: `references/phase-handoff.md`

### 4.1 `handoff-to-main` — the producer entry point

Called from a producing command's Handoff phase, **only** on the consent choice. Steps:

1. **Resolve the branch name** `<prefix>/<KEY>-<slug>`, then apply D6's collision rule.
2. **Create the branch** off the base the preflight settled on (`git -C "$SPECS_PATH" switch -c <branch>`), or reuse it per D6.
3. **Stage the deliverable paths only**, by enumeration over `git -C "$SPECS_PATH" status --porcelain --untracked-files=all`, classifying each path against the run's own deliverable set. `git add -A` is never issued at repository scope; only `git add -A -- <literal paths>`.
4. **Commit.** Message `<KEY> <summary>`, matching the specs repo's `<KEY|NOISSUE> <summary>` convention. The `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` trailer **is** carried — unlike artifact commits, these are authored content.
5. **Push** `git -C "$SPECS_PATH" push -u origin <branch>`. Never force.
6. **Open the PR** per D7. The repository is named explicitly so that no `cd` is needed and `specs-repo-git.md` §1 rule 1 holds: derive `<owner>/<repo>` by parsing `git -C "$SPECS_PATH" remote get-url origin` (both `git@host:owner/repo.git` and `https://host/owner/repo.git` forms, `.git` suffix stripped), then

   ```
   gh pr create -R <owner>/<repo> --base <default> --head <branch> \
                --title "<title>" --body-file <body-path>
   ```

   Every argument that would otherwise make `gh` prompt is supplied, because the plugin must never block on an interactive editor. On any failure, fall back to the printed instruction.
7. **Report** the outcome line (§4.4).

**Failure discipline** — deliberately unlike `specs-repo-git.md` §1 rule 5. A failure here is **reported and surfaced**, and the phase reports itself as **not handed off**, because the next phase's gate will stop on it. The run itself is not aborted retroactively (the deliverable is already written), but the report must never imply the handoff succeeded.

**PR body** (written to a file, never passed inline): what the phase produced; the artifact paths; the reviewer verdict (`vi-reviewer` / `ard-reviewer` / `spec-reviewer` / `design-reviewer` / `readiness-reviewer`) where the command has one; open questions or `[NEEDS CLARIFICATION]` counts; the next command in the chain and the fact that it will not run until this PR is merged.

### 4.2 `require-on-main` — the consumer entry point

Runs in Phase 0, immediately after `specs-preflight`, so it reuses that step's best-effort `fetch` (§3.2) — no second network call.

The full state space, enumerated rather than reasoned case-by-case:

| # | On `origin/<default>` | Worktree blob | HEAD | Outcome |
|---|---|---|---|---|
| A | yes | matches ref | any | **pass** |
| B | yes | differs | a branch **this run owns** — its prefix is one this command produces (§5), and its key is in the run key set (`specs-repo-git.md` §3.2) | **pass, reported**: "reading `<path>` from your in-progress `<branch>`, which amends the approved version on main" |
| C | yes | differs | anything else | repair offer `["Switch to main and pull --ff-only, then continue (Recommended)", "Cancel"]`, then re-test |
| C′ | yes | differs | anything else, and the tree is dirty in a way that would block the switch | **hard stop** naming the exact files, with the commands to resolve and an instruction to re-run. No stash, no forced switch |
| D | no | — | the artifact exists on an `origin/(idea\|vi\|ard\|spec\|design\|ready)/*` ref, and a PR is open for that branch | **stop**: `<artifact> is on branch <branch> with PR #<n> open, not merged — merge it, then re-run` |
| E | no | — | exists on such a ref, no PR open | **stop**: `<artifact> is on branch <branch> and was never handed off — open a PR for it, then re-run` |
| F | no | — | exists on no ref at all | **delegate — not a new stop.** The gate reports `absent` and the command applies its own pre-existing absent behaviour (§4.2.1) |
| G | `origin/<default>` ref missing entirely | — | any | **stop**: cannot verify what is on main |
| H | — | — | `$SPECS_PATH` unset, or `.git` not a managed/readable repo | **silent skip**, mirroring `specs-repo-git.md` §3.1 |
| I | — | — | detached HEAD (`specs_git: blocked` from §3.3 G0) | **stop**, re-emitting the G0 notice — a phase cannot complete from a detached HEAD |

**Row B is load-bearing.** Without it the gate would offer to discard in-progress design work. It must be decided by **branch ownership**, not by whether the file differs.

#### 4.2.1 Row F delegates — the gate never makes an optional input mandatory

Row F is the difference between "this phase was not handed off" and "this phase never happened". Only the second is row F, and the gate has no opinion about it: every gated input except `/design`'s `specification.md` is **optional today**, and J must not change that. The gate reports `absent`; the command does what it already does.

| Command | Gated input | Pre-existing absent behaviour, preserved unchanged |
|---|---|---|
| `/create-vi <KEY>` | `idea.md` | continue down the Phase 0 step 3 ladder — prompt for a path, or grill the VI from scratch (`create-vi.md:32`). **`/idea` does not become a prerequisite.** |
| `/create-ard` | the VI | fall back to `jira-reader` against the Jira export — now **reported** rather than silent |
| `/specify`, `/design`, `/implement`, `/epics`, `/ready` | the ARD | `status: none` and the no-regression rule of `ard-resolution.md:43-45`, untouched |
| `/epics` | VI-level `specification.md` | `vi_spec_present: false`, the existing silent skip |
| `/implement` | `specification.md` / `design.md` | only an **in-scope** spec is gated; a direct-prompt run resolves none and is unaffected |
| `/design` | `specification.md` | **stops** — but that stop already exists today (`design.md:56-57`), and J only makes its test correct |
| `/ready` | ARD / spec / design | records the artifact as missing in its coverage roll-up, exactly as today |

The only behaviour rows D and E add is a stop for an artifact that **exists** and was never handed off. That case is unreachable today, which is why nothing regresses.

**Degraded network:** if the preflight's fetch failed, the gate tests against the last-known `origin/<default>` and says so — the precedent `specs-preflight` §3.2 already sets ("offline — ancestry checked against the last-fetched ref"). Row G covers the case where there is no such ref at all.

**Read-only specs mount:** `references/read-only-repos.md` applies — `fetch` is skipped, the existing ref is used, and the degraded clause is emitted. The gate still functions; only its freshness degrades.

### 4.3 Locating the branch and PR for rows D/E

Bounded and cheap, no REST call:

1. `git -C "$SPECS_PATH" for-each-ref --format='%(refname:short)' refs/remotes/origin`, filtered to the six plugin prefixes.
2. For each, `git -C "$SPECS_PATH" cat-file -e <ref>:<relpath>`.
3. For a hit, `gh pr list --head <branch> --state open --json number,url` to name the PR. On `gh` failure, row E's wording is used instead of row D's, with a note that the PR state could not be checked.

### 4.4 Outcome and stop contract

`handoff-to-main` emits exactly one `Phase handoff:` line:

| Case | Line |
|---|---|
| Committed, pushed, PR opened | `Phase handoff: <branch> pushed — PR #<n> open (<url>). The next phase runs once it is merged.` |
| Committed, pushed, PR not opened | `Phase handoff: <branch> pushed — PR NOT opened (<reason>). Open it manually; the next phase will stop until it is merged.` |
| Committed, push failed | `Phase handoff: committed <sha7> on <branch> — push FAILED (<reason>). The phase is NOT handed off.` |
| Declined by the user | `Phase handoff: skipped at your request — <artifact> is written but not on main; the next phase will stop until it is.` |

Every stop from `require-on-main` carries the same four parts as `specs-repo-git.md` §5: what was found, what the plugin did **not** do, the exact commands to resolve it with `$SPECS_PATH` substituted, and what happens if it is ignored.

The consent choice in every producing command is reworded so the consequence is visible:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

### 4.5 Caller contract

A command that produces a `$SPECS_PATH` deliverable must cite and execute `handoff-to-main` in its Handoff phase and emit the §4.4 line exactly once. A command that consumes one must cite and execute `require-on-main` in Phase 0, before any expensive work, and act on the outcome. Neither rule may be restated inline — cite the section number.

## 5. Producer wiring

| Command | Deliverable paths | Branch |
|---|---|---|
| `/idea` | `specifications/<KEY>-<slug>/idea.md` (relocated from the vault) | `idea/<KEY>-<slug>` |
| `/create-vi` | `<KEY>_<slug>.md` | `vi/<KEY>-<slug>` |
| `/update-vi` | canonical + archived revisions | `vi/<KEY>-<slug>` |
| `/create-ard` | the ARD file(s) | `ard/<VI>-<vslug>` \| `ard/<EPIC>-<eslug>` |
| `/specify` | `specification.md`, `_session.md`, `_glossary.md`, the rendered `.html` | `spec/<EPIC>-<eslug>` \| `spec/<VI>-<vslug>` |
| `/design` | `design.md`, the amended `specification.md`, `_design-session.md`, `_design-glossary.md` | `design/<EPIC>-<eslug>` \| `design/<VI>-<vslug>` |
| `/implement` (Phase 7.5) | the `- [ ]` escalation notes on `specification.md`/`design.md` | `spec/…` or `design/…` per D5 |
| `/ready` | `_readiness.md` | `ready/<KEY>-<slug>` |

**`/implement`'s escalation notes are written in Phase 7.5 but handed off late, and the placement is a hard requirement.** Phase 7.5 sits inside Phase 3B, before the tests have even run; committing and opening a PR there would interrupt the run mid-review. The notes are written where they are today, and `handoff-to-main` for them runs **after Phase 4 (maintenance) and before the emitter tail** — which `references/session-hygiene.md` rule 2 permits, since the deliverable-side finish may sit anywhere relative to that tail.

The placement is load-bearing, not stylistic, because of what the two nearby claims actually say. `implement.md:719` defines its term explicitly — *"the implementation remains uncommitted on the branch created in Pre-Phase 3"* — so "the deliverable" there means **the code**, and the claim is scoped to Phase 7. `:669`'s claim is scoped to the follow-up phase and is about follow-up files. Both therefore stay true, but only while no `handoff-to-main` call lands inside Phase 6 or Phase 7. Read plainly, though, `:718` would still tell a future reader that `/implement` commits nothing at all — so it gains a scoping clause naming the escalation handoff as a distinct step in an earlier phase. A clarification, not a reversal.

`<KEY>` and `<slug>` are always taken from the **resolved feature folder** the deliverable was written into — never re-derived from the Jira title at handoff time. The folder resolution already tolerates a human-adjusted slug and a stray `-`/`_` after the key, and re-deriving would produce a branch name that disagrees with the directory it commits.

### 5.1 `/idea`'s handoff, driven by `vi_disposition`

`/idea` Phase 4 already computes `vi_disposition`. Phase 5 now completes the handshake:

- **`vi_disposition: rewrite`** — the key is already known from the `vi` source. Relocate to `specifications/<KEY>-<slug>/idea.md`, then `handoff-to-main`. **No human round trip.**
- **`vi_disposition: new`, `status: refined`** — offer: *"create the Jira workitem and give me the key, and I'll complete the handoff."* On receiving a key matching `^[A-Z][A-Z0-9_]*-\d+$`, relocate and run `handoff-to-main`. If the user declines, the idea stays in the vault and Phase 5 reports plainly that it was **not handed off**, and that `/create-vi` will need the out-of-contract `@<path>` form.
- **`status: draft`** (open `[NEEDS CLARIFICATION]` items) — **never hand off.** The phase is not finished. Offer `--deep`, or the explicit out-of-contract route.

## 6. Consumer wiring

| Command | Gated input | Where | On failure |
|---|---|---|---|
| `/create-vi <KEY>` | `idea.md` — **in-contract form only** | Phase 0 step 3 | stop |
| `/create-ard` | the VI; the inherited VI-level ARD on Epic-level runs | Phase 0 / Phase 2 | stop |
| `/specify` | the VI; the applicable ARD | Phase 0 / Phase 2.5 | stop |
| `/design` | `specification.md`; the applicable ARD | Phase 0 step 3 and step 4's picker; Phase 2.5 | stop |
| `/implement` | in-scope `specification.md`/`design.md`; the applicable ARD | Phase 0 | stop, naming the **specs** repo — it runs standing in a code repo |
| `/epics` | VI-level `specification.md` **if present**; the applicable ARD | its ARD/spec resolution steps | stop if present-not-on-main; silent skip if absent |
| `/ready` | ARD / spec / design | Phase 1 inventory | **finding**, caps the verdict at PARTIAL |

`/create-ard`'s silent fallback is now decided rather than silent: VI absent **everywhere** ⇒ the `jira-reader` fallback is legitimate but **reported**; VI on a branch ⇒ stop (row D/E).

## 7. Residue — every claim J makes false

Measured in the canonical repo, live surfaces only (`CHANGELOG.md` and `docs/` excluded), and each must be swept in **all three editions**.

| Claim | Measured sites | Change |
|---|---|---|
| Branch authority is `^(vi\|ard\|spec\|design)/` | 7 lines / 3 files: `references/specs-repo-git.md:31,80,291,370`; `CLAUDE.md:123,267`; `plugins/dev-workflows/README.md:348` | add `idea` and `ready` |
| "The plugin never opens a PR / never calls a PR REST API" | 6 lines / 4 files: `references/specs-repo-git.md:20`; `references/finish-and-handoff.md:6,43,74`; `commands/document.md:1080`; `README.md:217` | restate as **capability**, not policy: GitHub ⇒ `gh pr create` (it wraps the API, already allowed); Bitbucket has no CLI ⇒ push the branch and instruct. `specs-repo-git.md:20` stays true for its own two entry points but is scoped and cross-referenced |
| `/create-vi` relocates `idea.md` | 7 lines / 4 files: `commands/create-vi.md:59,195`; `commands/idea.md:13,276`; `README.md:17,96`; `CLAUDE.md:147` | relocation moves to `/idea` |
| `/idea` writes no specs deliverable | **1 line**: `commands/idea.md:3` — the frontmatter `description` ("no specs deliverable — the only `$SPECS_PATH` writes are the run's own session artifacts"). Measured: `CLAUDE.md` does **not** carry this claim, and neither does either README | it now does |
| `/ready` never commits its deliverable | **11 lines / 2 files**: `commands/ready.md:3,18,343,363,364,378,470,501,544,558`; `CLAUDE.md:250` | narrows to "never **automatically**" — the commit is behind the consent gate |
| `/ready` never branches | **5 lines / 1 file**: `commands/ready.md:17,110,112,545,555` — `:555` is a hard invariant ("NEVER branch — this command never creates a git branch") | `/ready` now creates `ready/<KEY>-<slug>` via the consent gate. `:17` and `:18` are adjacent lines of one prose block carrying *both* claims, so the block is rewritten once |
| `/design` confirms the spec is on main | **two** sites: `commands/design.md:50-57` (step 3) and `:67-68` (the Epic picker's "each with a `specification.md` on main") | both replaced by `require-on-main`. Fixing only the reviewed one would leave the picker listing branch-only Epics as designable |
| `/implement` "NEVER commits the deliverable" | **1 line**: `commands/implement.md:718` | gains a scoping clause. Not a reversal — `:719` already defines "the deliverable" as the code on the Pre-Phase 3 branch, and the claim is Phase-7-scoped. `:669` needs no change (follow-up files, follow-up phase) |
| `ard-resolution.md` has four callers | **1 line**: `references/ard-resolution.md:4-5` | corrected to five. Contradicted by that file's own Consumers section at `:59-63`, which lists `/ready`. A pre-existing stale caller list, surfaced by J's coverage question and in scope because J's D8 count depends on it |

Additional surfaces that must be updated, not merely checked: `CLAUDE.md`'s workflow-relationship map (a `handoff-to-main` / `require-on-main` edge per command), its "Key invariants for specs-repo git" list, its per-command invariant blocks for `/idea`, `/create-vi`, `/ready`, and the VI-creation flow; each edition's `README.md` command table and reference list; each edition's `CHANGELOG.md` with D12 under breaking changes; `references/next-phase-offer.md`, whose next-step wording must now include the merge step.

Copilot carries `_shared/specs-repo-git.md` and needs a hand-written `_shared/phase-handoff.md` under the four dialect rules (`subagent_type:` → `agent_type:`; `${CLAUDE_PLUGIN_ROOT}/references/X.md` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/X.md`; the §2.1 Sonnet chain → its own detection chain; command names in colon form, `idea:` not `/idea`). **Never `cp` into copilot.**

## 8. Requirements

**The new reference**

- **R1** `references/phase-handoff.md` exists and declares its scope, its divergences from `specs-repo-git.md` (fatal-by-design; `Co-Authored-By` carried; deliverable paths), and its caller contract.
- **R2** `handoff-to-main` specifies steps 1–7 of §4.1, including the enumerated staging and the never-`git add -A`-at-repo-scope rule.
- **R3** `handoff-to-main` specifies D6's collision rule with both branches: reuse this run's own in-progress branch, else the lowest free `-N` suffix.
- **R4** `handoff-to-main` specifies D7's capability probe and its fallback.
- **R5** `handoff-to-main` specifies the PR title and the body-file contents of §4.1.
- **R6** `handoff-to-main`'s failure discipline is stated explicitly as differing from `specs-repo-git.md` §1 rule 5, and requires the report to say "not handed off".
- **R7** `require-on-main` specifies all **ten** states of §4.2 — A, B, C, C′, D, E, F, G, H, I — with their outcomes.
- **R8** `require-on-main` specifies the degraded-network and read-only-mount behaviour, citing `specs-repo-git.md` §3.2 and `references/read-only-repos.md`.
- **R9** §4.3's bounded branch/PR lookup is specified, including the `gh`-failure downgrade from row D wording to row E wording.
- **R10** §4.4's four `Phase handoff:` outcome lines and the four-part stop contract are specified.

**Producers**

- **R11** `/idea` relocates `idea.md` into `specifications/<KEY>-<slug>/` and calls `handoff-to-main` on branch `idea/<KEY>-<slug>`.
- **R12** `/idea`'s three `vi_disposition` × `status` handoff branches behave per §5.1, including `status: draft` never handing off.
- **R13** `/create-vi` calls `handoff-to-main` and no longer relocates `idea.md`.
- **R14** `/update-vi` calls `handoff-to-main`.
- **R15** `/create-ard` calls `handoff-to-main`.
- **R16** `/specify` calls `handoff-to-main`.
- **R17** `/design` calls `handoff-to-main`.
- **R18** `/implement` Phase 7.5 calls `handoff-to-main` for its escalation notes, on the amended artifact's own prefix.
- **R19** `/ready` calls `handoff-to-main` for `_readiness.md` on branch `ready/<KEY>-<slug>`.
- **R20** All eight producers present the reworded consent choice of §4.4 verbatim.

**Consumers**

- **R21** `/create-vi <KEY>` derives `idea.md` from `<KEY>` and gates it; `@<path>` is out-of-contract, reads in place, does not relocate, and is ungated. An `idea.md` absent everywhere continues down the existing Phase 0 step 3 ladder (§4.2.1) — `/idea` is not a prerequisite.
- **R22** `/create-ard` gates the VI and the inherited VI-level ARD; the absent-VI `jira-reader` fallback is reported, never silent.
- **R23** `/specify` gates the VI and the ARD.
- **R24** `/design` step 3's gate is replaced by `require-on-main`.
- **R25** `/design` step 4's Epic picker enumerates spec'd Epics **from the ref**, not the worktree.
- **R26** `/implement` gates **in-scope** `specification.md`/`design.md` and the ARD, and its stop text names the specs repo. A direct-prompt run resolves no spec and is unaffected.
- **R27** `/epics` gates a VI-level `specification.md` that exists but is not on main; absent keeps the existing silent skip, so **VI-level `/specify` remains optional**.
- **R28** `/ready` records a not-on-main artifact as a finding capping the verdict at PARTIAL, and never stops.
- **R29** `ard-resolution.md` returns `none | found | unmerged`; `unmerged` stops all callers except `/ready`.
- **R50** `ard-resolution.md`'s no-regression rule (`:43-45`) is preserved **verbatim** and its `status: none` definition (`:39`, "`/create-ard` is optional") is unchanged. `unmerged` is reachable only when an ARD file resolves — never when none does. **The ARD does not become a prerequisite for any command.**
- **R51** `ard-resolution.md:4-5`'s caller list is corrected to the five callers its own Consumers section lists at `:59-63`, adding `/ready`.
- **R52** `implement.md:718` gains a clause scoping its "NEVER commits the deliverable" claim, naming the escalation handoff as a distinct step in an earlier phase. `:669` is unchanged. No `handoff-to-main` call lands in Phase 6 or Phase 7.
- **R53** Row F delegates per §4.2.1: for each of the seven gated inputs, the absent case reaches the command's pre-existing behaviour unchanged. No gate turns an optional input into a prerequisite.
- **R30** Every consumer's gate call sits before the first subagent dispatch, code scan, docs-grounding retrieval, or grill question in that command's phase order — a gate that fires after a `code-scanner` fan-out has already burned the cost it was meant to prevent.
- **R47** `/update-vi` is **not** gated on the `*_ARD.md` / `specification.md` it discovers in Phase 0 step 5 (D13); an artifact found only off main is **reported** in that phase's confirmation, alongside the existing Jira-import-vs-draft divergence notice.
- **R48** `handoff-to-main`'s exact `gh pr create` invocation is confirmed to run non-interactively against a named repository before any command depends on it.

**Revisions**

- **R31** `specs-repo-git.md` §1 rule 3, §2.2, §3.3 G2, §3.5 B2–B4 and its branch-key extraction, and §5's G2 notice all carry the six-prefix authority.
- **R32** `specs-repo-git.md:20` is scoped to its own two entry points and cross-references `phase-handoff.md`.
- **R33** `specs-repo-git.md` §3.6 is rewritten per D10 — B3 retained, rationale replaced, gate cross-referenced, and the "do not simplify this away" warning preserved with its new reason.
- **R34** `finish-and-handoff.md:6,43,74` and `document.md:1080` state the capability reason rather than a policy ban. `/document`'s behaviour is unchanged.
- **R35** `README.md:217`'s parenthetical is corrected the same way.
- **R36** All 7 `/create-vi`-relocation sites are corrected.
- **R37** All `/idea`-writes-no-specs-deliverable sites are corrected, including the command's frontmatter `description`.
- **R38** All 11 `/ready`-never-commits sites are narrowed to "never automatically".
- **R49** All 5 `/ready`-never-branches sites are corrected, including the hard invariant at `commands/ready.md:555`. `/epics`, `/release-notes`, and `/document` keep their never-branches claims — they are not producers, and their claims stay true.
- **R39** `CLAUDE.md`'s workflow map, specs-repo-git invariant list, and the `/idea`, `/create-vi`, `/ready`, and VI-creation-flow invariant blocks reflect J.
- **R40** `CLAUDE.md` gains a `phase-handoff.md` source-truth paragraph.
- **R41** `references/next-phase-offer.md`'s next-step wording includes the merge step.
- **R42** Each edition's README documents `phase-handoff.md` in its reference list and the new `/create-vi` grammar in its command table.
- **R43** Each edition's CHANGELOG records D12 under breaking changes, and the version bumps land: 2.52.0 / 2.52.0 / 2.22.0.

**Port**

- **R44** mgd is content-verbatim with canonical except its five identity files, verified empirically at port time rather than assumed.
- **R45** copilot gains a hand-written `_shared/phase-handoff.md` and all residue fixes under the four dialect rules; nothing is `cp`'d into copilot.
- **R46** copilot's `.github/plugin/marketplace.json` and `.github/copilot-instructions.md` are updated — both were found stale after a previous release.

## 9. Risks and their executable mitigations

Each mitigation is a verification step someone runs, not advice.

**Risk 1 — an unreachable gate state.** Ten states is the size at which case-by-case reasoning produced three unreachable guards in one feature last round.
*Mitigation:* the verification table carries one row per state — A, B, C, C′, D, E, F, G, H, I — each naming the concrete repository condition that reaches it (branch, ref presence, blob state, PR state) and the observable outcome. A state with no reaching input is a defect, not a rounding error.

**Risk 2 — `unmerged` is a dead gate.** A status nothing consumes is the exact shape of the five dead gates shipped in sub-project B2, none of which grep would have caught.
*Mitigation:* for each of the five `ard-resolution.md` callers, quote the line that receives `unmerged` and the line that acts on it. Five quoted pairs, or the requirement is not met.

**Risk 3 — the residue sweep is sampled, not exhaustive.** A review last round named 3 stale lines; the exhaustive sweep found 6 of 34.
*Mitigation:* the sweep reports every one of §7's measured sites in all three editions with a verdict — **fixed** or **checked and correct** — never only the fixed ones. A sweep that reports only fixes cannot be told from a sample.

**Risk 4 — row B regresses into data loss.** If row B is dropped or mis-ordered, the gate offers to switch away from an in-progress `/design` branch and discards the work.
*Mitigation:* a verification row that puts the repo on `design/<KEY>-<slug>` with a locally amended `specification.md` and asserts the gate takes row B — passes and reports, never offering the switch.

**Risk 5 — the identity files go stale.** Four findings in sub-project I traced to exactly this: the port skips them, they duplicate claims from elsewhere, and `diff -rq` reports them as expected-to-differ.
*Mitigation:* a per-identity-file pass — for each of the five, plus each root `CLAUDE.md` and marketplace catalog, answer in writing whether it duplicates any §7 claim, and record the answer even when it is "no".

**Risk 6 — a PR is opened where it should not be.** `handoff-to-main` performs an outward-facing action.
*Mitigation:* assert that no producer reaches `handoff-to-main` except through the consent choice, and that the "Just write the files" branch reaches no `gh` call. One grep per producer plus a read of the surrounding phase text.

**Risk 7 — the `gh` invocation blocks or is wrong.** A `gh pr create` missing a required argument opens an interactive editor, which in a non-TTY agent context hangs or fails obscurely; and `-R` behaviour without a `cd` is the part of §4.1 step 6 that is asserted rather than observed.
*Mitigation:* before any command is wired to it, run the exact invocation with `--dry-run` against `$SPECS_PATH` from a **different** working directory, and record the observed output. `--dry-run` is what makes this checkable without creating a real pull request in `mgd-specifications` (R48).

**Risk 8 — the gate silently promotes an optional input to a prerequisite.** This is the most likely way J does real damage: `/create-ard`, VI-level `/specify`, and `/idea` are all deliberately optional steps, and a gate that stops on absence would make each of them mandatory without anyone deciding to.
*Mitigation:* one verification row per line of §4.2.1's table — seven rows — each exercising the **absent** case and asserting the pre-J behaviour, plus a quoted diff showing `ard-resolution.md:39` and `:43-45` are byte-identical to their pre-J text. An absent input that produces a stop anywhere except `/design` is a Critical.

**Risk 9 — the gate runs after the cost.** R30's ordering is easy to satisfy on paper and miss in a command whose Phase 0 is long.
*Mitigation:* for each of the seven consumers, record the line number of the gate call and the line number of the first subagent dispatch / scan / grill in that command, and assert the first is smaller. Seven numeric pairs, not seven assurances.

## 9.1 What is at risk today, and what J leaves accepted

**The loss mechanism J closes.** `/implement`'s Phase 7.5 notes and `/ready`'s `_readiness.md` cannot be *destroyed* by the plugin — verified: nothing in it runs `git stash`/`clean`/`checkout`/`reset` against `$SPECS_PATH` (`implement.md:327`'s stash is the code repo's dirty-tree gate; `diff-summarizer.md:169` is a NEVER rule), and `specs-preflight` G1 fires on a dirty OTHER path and **ends the preflight before stage 3**, so no `switch` or `pull --ff-only` runs while they are dirty.

They are lost a different way. They never reach `main`, so no later reader sees them — an engineering finding that the shipped code contradicts the spec exists only in one working tree. And G1's own notice **mis-attributes them**: "Those files are *yours*" and "nothing is lost — your files stay uncommitted" are both false for a plugin-written file, and together they ensure nobody acts on it. That is why the defect survived: the guard detects the dirt correctly and describes it wrongly. Because the files then look like stray edits, ordinary hygiene (`git checkout -- .`) deletes them with no record.

After J both are committed, pushed, and PR'd, and G1's wording becomes true — the only OTHER dirt left in `$SPECS_PATH` is genuinely the user's, or a deliberately declined handoff.

**Accepted residual.** A user who declines the handoff leaves the deliverable uncommitted, and nothing will ever commit it. That is the explicit consequence of D2 and is surfaced twice — in the reworded consent choice and in §4.4's "skipped at your request" outcome line — but the file remains destructible by ordinary git hygiene until the user acts. Accepted, not mitigated: the alternative is committing a deliverable against the user's stated wish.

## 10. Verification approach

There is no test framework — the plugin is prompt markdown. Verification is `grep`/`awk`/`diff`/reading, with every count whitespace-normalized, recorded as a table of one row per requirement: the assertion, the exact command, the expected value, and the observed value.

Two rules carried from sub-project I: **the verification record is written last**, after the final fix wave, and **every expected value is re-derived against the tree being verified** — never copied from another plan.

## 11. Out of scope

- `/document`'s docs-repo PR behaviour. Docs repos are Bitbucket-hosted, so there is no PR to open; only the *stated reason* changes (R34).
- Auto-merge anywhere (D2).
- The ~100 per-VI feedback entries under `$SPECS_PATH/specifications/*/dev-workflows/*-feedback.md`.
- Any change to `commit-artifacts`' bounded paths (`specs-repo-git.md` §2.1). Deliverables reach main by `handoff-to-main`, not by widening the bookkeeping area.

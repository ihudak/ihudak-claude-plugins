---
name: brd-ground
description: BRD-grounding workflow (PA phase, second of the BRD-to-PRD route). Pins every mounted repository to a verified commit, grounds every [BR#n] claim against code (code-grounder) and an exported design frame set (design-grounder), independently re-derives every finding (grounding-verifier, Opus), and assigns each finding a current/will-change horizon against declared prerequisite BRDs. Read-only against every repository. Optional --depends-on persists prerequisites to brd-link.md; --derivation-matrix adds an implementation-altitude build list; --rebaseline re-runs against moved code, superseding findings by ID. Offers /brd-split as the next step.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Ground the BRD's requirement inventory against code and design: $ARGUMENTS

`/brd-ground` is the **second command of the BRD-to-PRD flow** (PA phase) — it takes the
`[BR#n]` inventory `/brd-intake` wrote and checks its premises against real code and real design
assets, at pinned commits, rather than letting a plausible-sounding claim stand unverified. Every
finding is independently re-derived by a different agent before it counts as evidence
(`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §8) — this command's whole job is to make
that discipline happen, not to ground anything itself.

Usage: `/brd-ground <BRD-KEY> [--depends-on <BRD-KEY>…] [--derivation-matrix|--no-derivation-matrix] [--no-design] [--rebaseline]`

Runs at whatever level `<BRD-KEY>` names (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md`
§3) — a parent BRD or one of its slices — grounding only the requirements that BRD claims.

---

## Phase 0 — Resolve inputs and gate on main

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate with `brd-key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §1). If absent or invalid, stop:
   `BRD_GROUND_NEEDS_KEY: /brd-ground needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/dev-workflows:brd-ground <KEY>'.`
2. **Flags.** `--depends-on <BRD-KEY>` — repeatable, each consuming the next token; validate each
   with `brd-key-valid` and drop (warn, do not stop the run) any that fail shape. `--no-design` —
   boolean, skips Phase 5's `design-grounder` step. `--rebaseline` — boolean, see Phase 3. `--derivation-matrix`
   / `--no-derivation-matrix` — mutually exclusive; absent means "let Phase 8 decide the default".
3. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`
   (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
4. **Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute
   its `specs-preflight` entry point (§3) inline, **before** the gate below — `require-on-main`
   performs no fetch of its own (`phase-handoff.md` §3.2) and relies on this step's best-effort
   one, the same ordering `/design` Phase 0 uses and for the same reason. Prompt-free and silent
   when the specs repo is clean and on its default branch. If it returns `specs_git: blocked`
   (§3.3 G0), carry that flag for the whole run.
5. **Resolve the BRD folder.** `resolve-brd <BRD-KEY>` (`brd-addressing.md` §2). Absent → stop:
   `BRD_GROUND_NOT_FOUND: no BRD folder found for <BRD-KEY> — run /dev-workflows:brd-intake <BRD-KEY> @<brd-file> first.`
6. **Gate the intake artifacts on main.** Execute `require-on-main` (`phase-handoff.md` §3)
   against the resolved BRD folder's `coverage-ledger.md` (the last file `/brd-intake` writes, so
   its presence on `origin/<default>` implies `brd/brd-inventory.md` and `brd/brd-defect-log.md`
   landed with it). Map the §3.7 return by `stopped` first: any stopping row → stop, naming the
   concrete branch/PR state it reports; `pass` → proceed; `pass_amending` → proceed, printing the
   §3.3 row-B message; `absent` (row F) → stop:
   `BRD_GROUND_NEEDS_INTAKE: no intake artifacts on main for <BRD-KEY> — run /dev-workflows:brd-intake for it and merge the pull request first.`;
   `unmanaged` → proceed as before this feature.
7. **Require `$REPOS_PATH`.** Resolve `${REPOS_PATH:-/workspace}` (`docs/reference/environment.md`)
   as one directory or a colon-separated list. If no entry resolves to an existing directory,
   stop naming `REPOS_PATH` (`choices: ["Set REPOS_PATH (enter the path)", "Cancel"]`) — grounding
   has nothing to check a claim against without at least one mounted repository.
8. **Read the claim list.** From the gated `<BRD-dir>/brd/brd-inventory.md`, extract every
   `[BR#n]` row's `id` and `text` (`brd-format.md` §2 field shape) — this is the `claims` array
   every dispatch in Phase 5 draws from. Zero rows (an `EMPTY` intake) → nothing to ground; report
   that plainly and skip straight to the Terminal phase's ledger line.
9. **Read `brd-link.md`, if present**, to recover any `depends-on` already recorded from an
   earlier run — Phase 4 merges this run's `--depends-on` into it additively, never replacing it.

---

## Phase 1 — Resolve repositories

BRDs carry no PR links to auto-derive a repo list from (unlike `/epics`), so this phase is always
the manual path:

1. Prompt for the repos in scope for this BRD's claims — a free-text list of short names, one per
   line or space-separated.
2. **Build a slug→clone map**, exactly as `/epics` Phase 4 does: for each top-level directory
   under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin
   2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's
   slug. Skip directories with no `.git` or whose `git remote` call fails/times out. **Never
   assume a `<base>/<slug>` directory name** — resolution is always by remote slug.
3. Resolve each named repo against the map: one match → use it; multiple matches → auto-prefer
   basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last (show candidates before
   proceeding); zero matches → escalate:
   ```
   choices: ["Skip and continue without this repo", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
   ```
4. Empty final list (every repo skipped or missing) → escalate:
   ```
   choices: ["List repos to check manually", "Cancel", "Other… (describe)"]
   ```

Read-only throughout (`${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md`) — this command never
switches a branch, fetches, or pulls any repository it resolves here; Phase 3 reads whatever
`HEAD` already is.

---

## Phase 2 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # floors at SIGNIFICANT when Phase 1 resolved >1 repository —
                                   # the multi-source rule in model-routing/classification.md §1.1
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # code-grounder, design-grounder (Phase 5)
  review_model:    <§2 Opus chain>     # grounding-verifier (frontmatter-pinned; recorded, no override)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`grounding-verifier` keeps its frontmatter Opus pin regardless of classification, the same way
`design-reviewer`/`epic-reviewer` do elsewhere — the floor at `SIGNIFICANT` records that a
multi-repository run carries more cross-cutting risk; it does not change which model verification
runs on. If no Opus resolves, degrade to best-available and record it in `notes` and the final
report — never hard-block.

---

## Phase 3 — Baseline integrity gate

Run `baseline-integrity` (`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §4) **once per
resolved repository, before any finding is written**:

```bash
git -C "<repo>" rev-parse HEAD
git -C "<repo>" diff --ignore-cr-at-eol --stat
git -C "<repo>" status --porcelain
```

1. Record `rev-parse HEAD` as the repo's pinned commit.
2. `diff --ignore-cr-at-eol --stat` must be empty. Any output → **non-empty content diff, stop**:
   `BRD_GROUND_DIRTY_TREE: <repo> has content changes at <sha> — grounding it would cite an unidentifiable snapshot.`
3. For every entry `status --porcelain` reports, compare its working-tree line count against
   `git show <sha>:<path> | wc -l` when the path exists at the pinned commit (an untracked path
   that exists nowhere at the pin has nothing to compare against and is not itself a dirty-pin
   signal). A line-count mismatch is a non-empty content diff — stop with the same message above,
   naming the porcelain-flagged path.

**This gate is the orchestrator's, never delegated.** `code-grounder` and `grounding-verifier`
each re-verify `HEAD` against the commit *they* are handed (their own step 1/2), but that check
alone would let a repository whose working tree is dirty *around* an otherwise-matching `HEAD*`
pass silently — the content-diff and line-count checks above are what this phase adds, and they
run before Phase 5's first dispatch, not inside it.

**`--rebaseline`, and a plain re-run against moved code.** If `<BRD-dir>/grounding/baselines.md`
already records a pin for a repository:
- **Its `HEAD` still matches the recorded pin** → nothing moved; this is a harmless re-run. Skip
  re-grounding claims this repository already answered (Phase 5) unless a new `--depends-on` was
  added this run (Phase 6 still reassesses horizons against it).
- **Its `HEAD` has moved, and `--rebaseline` was NOT given** → stop:
  `BRD_GROUND_NEEDS_REBASELINE: <repo> moved since the last grounding pin (<old-sha> -> <new-sha>) — re-run with --rebaseline to supersede the affected findings by ID.`
- **Its `HEAD` has moved, and `--rebaseline` WAS given** → proceed; Phase 5 re-grounds every claim
  against the new pin, and Phase 8 supersedes the old findings by ID rather than renumbering them
  (grounding-format.md §3, `SUPERSEDED`) — a citation into an already-sent package still resolves.

**Record the outcome as a `[CG#n]` finding** (`grounding-format.md` §4: "the outcome is recorded
as a `[CG#n]` finding" — a verified fact about a code repository at a commit is exactly what that
prefix denotes, and inventing a separate prefix for it would only fragment the namespace). One per
repository that passes this gate, assigned first, in repo-resolution order, **before** Phase 5's
claim-level findings — `CG#1..CG#R` on a first run for `R` resolved repositories, continuing after
whatever the highest `CG#n` already on file is on a `--rebaseline` run. Each carries every field
`grounding-format.md` §2 defines: `claim` — "baseline integrity: `<repo>` is pinned at a verified,
unmodified commit"; `verdict: CONFIRMED` (a repository that failed this gate never reaches a
finding — it stopped the run instead); `evidence` — the three command outputs (the pinned SHA, the
empty `--stat` diff, and the `--porcelain`/line-count result); `commit` — the same pinned SHA;
`altitude: implementation`; `horizon: current`; `consumed_by: none`. Phase 5 continues the BRD-wide
`[CG#n]` sequence from these, never restarting at `CG#1` once a baseline finding already claimed
it. Phase 7 verifies these findings the same as any other — `grounding-verifier`'s own Process
step 1 already re-runs `baseline-integrity` for whatever finding it is handed, so re-checking a
baseline finding is exactly that re-run.

Append (never overwrite) one dated entry per repository to `<BRD-dir>/grounding/baselines.md`:
the repo, the pinned commit, the verification result, and the `[CG#n]` id assigned above — the same
three commands are what the customer's own reviewer re-runs later against their own checkout.

---

## Phase 4 — Prerequisites

Persist any Phase 0 `--depends-on` keys into `<BRD-dir>/brd-link.md` under a `depends-on:` list —
**additive only**: merge into whatever the file already carries (including a `parent:` or
`claims:` field another command wrote), never drop an existing prerequisite, and never touch any
field but `depends-on:`. The file may also be edited by hand between runs; this phase reads it
fresh, adds, and writes back.

For every declared prerequisite (this run's plus any already on file):

1. `resolve-brd <PREREQ-KEY>`. Absent → report `<PREREQ-KEY> — BRD not found`.
2. Found → look for `decisions.md` in its folder. Absent → report
   `<PREREQ-KEY> — no decisions.md yet; contributes no will-change horizons` (per
   `grounding-format.md` §5: a prerequisite whose decisions are not yet frozen contributes none).
3. Present → read only decisions recorded as frozen (never a draft position or an interview
   answer still open, and never a decision this reader cannot confidently tell is frozen — an
   unparseable or ambiguously structured `decisions.md` is treated the same as "none frozen" here,
   never guessed into either state). Two outcomes:
   - **Nothing in it reads as frozen** → report
     `<PREREQ-KEY> — decisions.md present, none frozen yet; contributes no will-change horizons`
     — the same "contributes none" consequence as the absent-file case above, just reached from a
     different cause.
   - **At least one decision reads as frozen** → report readiness in the exact form spec'd for
     this command:
     ```
     prerequisites: EPIC-008-01 — decisions frozen, customer-reviewed 2026-08-27, not yet built
                    EPIC-002    — decisions frozen, NOT customer-reviewed
     ```
     "customer-reviewed `<date>`" comes from the newest `customer-review-<date>.md` in the
     prerequisite's folder, if any, else "NOT customer-reviewed"; "not yet built" is this
     prerequisite's default state — grounding is what tells the operator when a decision is about
     to move the ground it is standing on, so it is stated even when obvious.

No declared prerequisites at all → `prerequisites: none declared`. Hold this block for the final
report; Phase 6 also uses it to decide which findings get `horizon: will-change`.

---

## Phase 5 — Fan out grounding

**`code-grounder`, one per repository, ≤4 concurrent per Agent message** (wait for a batch before
starting the next). Each dispatch gets the *whole* claim list (Phase 0 step 8) and its own pinned
commit (Phase 3) — a BRD carries no per-repo claim tagging, and a claim that genuinely belongs to a
different system is exactly what `NOT-PROVABLE` exists to say, not a reason to pre-filter:

→ Agent (subagent_type: "dev-workflows:code-grounder", model: `<detection_model>`):
  > "repo_path: [resolved absolute path from Phase 1]
  > commit:    [Phase 3 pinned commit for this repo]
  > claims:
  >   - id:   [BR#n]
  >     text: [requirement text]
  >   [… every claim from Phase 0 step 8]
  > refresh:
  >   pull: false"

Handle `status`: `OK` → collect `findings`. `INPUT_MISSING` / `REPO_MISSING` → should not occur
(Phases 0/1/3 already checked); if it does, stop and name the gap. `COMMIT_MISMATCH` → the tree
moved between Phase 3 and this dispatch — stop and re-run from Phase 3.

**Renumber into one BRD-wide sequence.** Each `code-grounder` instance numbers its own output from
`CG#1` (its own contract, per dispatch) — this is per-instance, not global. Merge every batch's
findings, in repo-resolution order, into one contiguous `[CG#n]` sequence continuing from the
highest `CG#n` already assigned this run — Phase 3's own baseline findings on a first run, or
whatever the highest `CG#n` already on file is on a `--rebaseline` run — never trusting an agent's
own numbers as the BRD's numbering.

**Then `design-grounder`, unless `--no-design`.** Look for `<BRD-dir>/design/`; each immediate
subdirectory is a candidate exported frame set (`grounding-format.md` §6 convention — images plus
an index file). None found → skip, reporting why (`--no-design` given, or no `design/` folder
exists yet for this BRD). One or more found → dispatch one instance per frame set, same ≤4
concurrent discipline, **after** the code-grounder batch above has fully returned — this agent's
fourth reconciliation class cites a `[CG#n]`, so the findings it needs must already exist:

→ Agent (subagent_type: "dev-workflows:design-grounder", model: `<detection_model>`):
  > "frame_set_dir: [absolute path to this frame set]
  > inventory:
  >   - id:   [BR#n]
  >     text: [requirement text]
  >   [… every claim from Phase 0 step 8]
  > cg_findings:
  >   [… every merged [CG#n] finding from this phase, in the shape design-grounder's Inputs declare:
  >      id, claim, verdict, evidence, commit]"

Handle `status`: `OK` → collect `findings` (may be empty — agreement produces none). `INPUT_MISSING`
/ `FRAME_SET_MISSING` → should not occur; stop and name the gap if it does. `NO_INDEX` → this
frame set cannot be reconciled without an index file; report it and skip that directory rather
than guessing at frame identity. Renumber into one BRD-wide `[DG#n]` sequence the same way as
`[CG#n]` above, continuing from the highest `DG#n` already on file.

A `design-grounder` `notes` entry naming a class-4 gap it deferred for lack of a settling
`[CG#n]` is carried into the final report verbatim — it is a real, actionable gap, not noise.

---

## Phase 6 — Horizons

Every finding leaves Phase 5 as `horizon: current` by default (an agent grounding one claim
against one repository or frame set has no visibility into another BRD's decisions to do
otherwise). This phase is where prerequisite awareness — Phase 4's readiness block — is applied
across the whole finding set:

For each finding, and for each declared prerequisite whose decisions Phase 4 found **frozen**:
read the frozen decision text and judge whether it directly determines this finding's claim once
built — not merely mentions the same area. Where it does, set `horizon: will-change` and record
`prerequisite: <the specific decision, by id and a one-line summary>` — naming the decision itself,
never merely the prerequisite BRD (`grounding-format.md` §5). Where no declared prerequisite has
any frozen decisions at all (the common case before `/brd-interview` has run against any of them),
every finding stays `current`, and this is reported plainly rather than left to look like nothing
was checked.

A finding already carrying `horizon: will-change` from a previous `--rebaseline` pass keeps it
unless the naming decision itself has since shipped (superseded by a later finding, per §3) —
`will-change` findings are never silently reverted to `current`.

---

## Phase 7 — Verify

Dispatch `grounding-verifier` over **every** finding this run holds — Phase 3's baseline `[CG#n]`
findings, freshly-merged Phase 5 claim findings, and any pre-existing ones a `--rebaseline` pass is
re-checking — one instance per finding, same ≤4-concurrent batching discipline as Phase 5, pinned
to the Opus chain (`review_model`, frontmatter-pinned, no override):

→ Agent (subagent_type: "dev-workflows:grounding-verifier", model: `<review_model>`):
  > "finding:
  >   id:       [CG#n or DG#n]
  >   claim:    [the BR#n premise as the finding recorded it]
  >   class:    [1-4 — DG#n only, omit for CG#n]
  >   verdict:  [the finding's verdict]
  >   evidence: [the finding's evidence list]
  >   commit:   [the finding's pinned commit]
  >   cites:    [class-4 DG#n only — the CG#n it cites]
  > repo_path:  [the repository this finding is pinned against]
  > provenance: [own-run | inherited — see below]"

Supply the finding **exactly as the agent's own Inputs contract declares it** — including
`evidence` and, for a class-4 `[DG#n]`, `cites` — even though the agent's own hard rules forbid
reading either before it finishes its independent re-derivation. That sequencing discipline is the
agent's to enforce on itself (its Process step 2 is explicit about it); this orchestrator's job is
only to hand over the full, correctly-shaped record, never to withhold a field the contract lists.

**`provenance` is set per finding, never blanket.** `own-run` for a finding this same invocation
produced in Phase 5. `inherited` for a finding this invocation did not itself just produce —
concretely, a pre-existing finding a `--rebaseline` pass is re-checking, since it was written by an
earlier run of this workflow. The agent's own Inputs contract and `grounding-format.md` §8 both
define `inherited` as "another team's report **or an earlier run of this workflow**," and a finding
surviving from before this invocation is the second of those, regardless of how confident its
write-up reads — mislabelling it `own-run` would tell the verifier to relax exactly where §5 of its
own instructions say rigor must not drop.

Act on `outcome`:
- **`agree`** — keep the finding as written; record the outcome alongside it.
- **`extend`** — keep the finding's verdict; append the verifier's additional evidence to the
  finding's `evidence` list; record the outcome.
- **`unprovable`** — keep the finding's verdict unchanged (the verifier's own search settling
  nothing either way is not the same as it being wrong); record the outcome and flag the finding
  in the report as verification-inconclusive.
- **`contradict`** — **the finding is rewritten, and the rewrite retains the same id.** Replace
  the finding's `verdict` and `evidence` with the verifier's `own_verdict` and `own_evidence`, and
  keep a one-line note of the pre-rewrite verdict for the audit trail. The id never changes, so
  every existing citation into it still resolves.

A finding carrying no verifier outcome is not evidence (`grounding-format.md` §8) and is never
written to the package with `consumed_by` anything but `none` — this phase is what stands between
a raw finding and one a downstream command may cite.

---

## Phase 8 — Write findings

Write `<BRD-dir>/grounding/code-grounding.md` (every `[CG#n]`) and
`<BRD-dir>/grounding/design-grounding.md` (every `[DG#n]`, or a short note when Phase 5 skipped
design grounding and why) — one block per finding, carrying every field
`grounding-format.md` §2 defines (`id`, `claim`, `verdict`, `evidence`, `commit`, `altitude`,
`horizon`, `class`/`cites` for `[DG#n]`, `consumed_by: none`) plus this run's verifier `outcome`.
A `--rebaseline` run appends its new findings after the existing ones and marks any finding it
superseded with `verdict: SUPERSEDED`, id retained, rather than deleting or renumbering it.

**Derivation matrix.** Resolve whether it runs: an explicit `--derivation-matrix` /
`--no-derivation-matrix` wins outright; otherwise default it **on** when the BRD inventory reads
as reporting- or data-centric (a judgment call this command makes from the claim text — recurring
language about reports, dashboards, exports, extracts, or stored/displayed data fields) and **off**
otherwise. When on, append one implementation-altitude row per data element the inventory asks to
display or store to `<BRD-dir>/grounding/code-grounding.md`, classed per `grounding-format.md` §7
(`EXISTS | DERIVED | NEW-CAPTURE | NEW-CONFIG | PARTNER | DEFERRED | DEPENDENCY`) — appended there
rather than as a new file, since it is not in this command's produced-artifact set on its own.

---

## Phase 9 — Handoff

Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`phase-handoff.md` §2) with `prefix: brd` (shared
by the three `/brd-*` commands, per `brd-intake.md`'s own precedent), `feature_folder` as resolved
in Phase 0, `deliverable_paths` = every file this run wrote or updated under `<BRD-dir>`
(`grounding/baselines.md`, `grounding/code-grounding.md`, `grounding/design-grounding.md`,
`brd-link.md`), `title: <BRD-KEY> Ground requirements against code and design`, and `body_facts` =
the finding counts by verdict, the verifier agreement/extend/contradict/unprovable tally, and the
prerequisite-readiness block; emit its §4.1 outcome line in the final report.

---

## Phase 10 — Next steps

```
choices: ["Split the BRD once every finding carries a verifier outcome — /dev-workflows:brd-split <BRD-KEY> is not yet available; a later task in this increment adds it (Recommended)", "Ground another declared prerequisite first", "Stop here", "Other… (describe)"]
```

`/dev-workflows:brd-split <BRD-KEY>` is the third command of the BRD-to-PRD route — a later task
in this increment adds it, and, once it does, it will not start until this phase's pull request is
merged, and will carry its own role and cost-attribution row. Guidance only, per
`${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — names only that `/brd-split` exists and
where it sits in the route, never its behaviour, which task 12 owns.

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 11), per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Grounding another repository or
prerequisite in the same BRD? → run **`/compact`**. Handing off to `/brd-split`, even yourself? →
run **`/clear`**. Guidance only — nothing is auto-run.

---

## Phase 11 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 10, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin / skill / command /
reference gap, `emit-block` (`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) fires at
that halt before escalating. None of Phase 0's stops qualify — a missing key, an unresolved BRD,
an ungated intake artifact, and an unset `$REPOS_PATH` are environment / sequencing halts, never a
plugin capability gap. `BRD_GROUND_DIRTY_TREE` and `BRD_GROUND_NEEDS_REBASELINE` are repository
state, not a plugin gap, either.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-ground`; what was produced (baselines,
   code/design findings, verifier tally, prerequisite readiness); key events (a dirty-tree stop, a
   rebaseline, a skipped design pass, an unresolved repo — or "none"); workarounds; test result
   N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`
   and call its `emit-auto` entry point (§6) with the Lessons Learned report, `command: /brd-ground`,
   the run's `jira_key` (the `<BRD-KEY>`), `source`, and `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no
   plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and
   call its `emit-cost` entry point with `command: /brd-ground`, `phase: brd-to-prd`, `role: pa`,
   the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the
   report-only notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and
   write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry, before the
   commit step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`
   and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. Stages
   ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
   `<BRD-KEY> Add dev-workflows session artifacts (/brd-ground)` with no `Co-Authored-By` trailer,
   and pushes to the branch Phase 9's handoff created. NEVER touches a code repo, the vault, or the
   current working directory; NEVER force-pushes; NEVER fails the run; skips entirely when the run
   carries `specs_git: blocked`, re-emitting that notice. Hold its §6 outcome line for the final
   report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable
is offered only in Phase 9), and NEVER writes into a code repo, the vault, or the current working
directory; no user name is ever written.

---

## Final report

Report: the BRD folder + resolved repositories (with each one's pinned commit); the classification
and model routing (+ any Opus degradation); the prerequisite-readiness block from Phase 4, verbatim
in the §5.6 form; finding counts by verdict for `[CG#n]` and `[DG#n]` separately, and the verifier
tally (`agree` / `extend` / `contradict` / `unprovable`) with every `contradict` rewrite named by
id; whether the derivation matrix ran and why; any `design-grounder` class-4 gap deferred for want
of a settling `[CG#n]`; the feedback + cost paths; the `Phase handoff:` outcome line
(`phase-handoff.md` §4.1); the `Specs repo:` outcome line (`specs-repo-git.md` §6); the next-step
recommendation; and end with the ledger line, read fresh from the (unmodified-by-this-run)
`coverage-ledger.md`, exactly per `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated
```

`/brd-ground` never changes a ledger disposition — that line simply reports where allocation stands
going into `/brd-split`.

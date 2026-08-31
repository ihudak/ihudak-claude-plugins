---
name: brd-ground
description: BRD-grounding workflow (PA phase, second of the BRD-to-PRD route). Pins every mounted repository to a verified commit, grounds every [BR#n] claim against code (code-grounder) and an exported design frame set (design-grounder), independently re-derives every finding (grounding-verifier, Opus), and assigns each finding a current/will-change horizon against declared prerequisite BRDs. Read-only against every repository. Grounds on the shipped product documentation when $DOCS_PATH resolves (--no-docs off) — as a lead and a divergence finding, NEVER as evidence for a [CG#n]. Optional --depends-on persists prerequisites to brd-link.md; --derivation-matrix adds an implementation-altitude build list; --rebaseline re-runs against moved code, superseding findings by ID. Offers /brd-split as the next step.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Ground the BRD's requirement inventory against code and design: $ARGUMENTS

`/brd-ground` is the **second command of the BRD-to-PRD flow** (PA phase) — it takes the
`[BR#n]` inventory `/brd-intake` wrote and checks its premises against real code and real design
assets, at pinned commits, rather than letting a plausible-sounding claim stand unverified. Every
finding is independently re-derived by a different agent before it counts as evidence
(`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §8) — this command's whole job is to make
that discipline happen, not to ground anything itself.

Usage: `/brd-ground <BRD-KEY> [--depends-on <BRD-KEY>…] [--derivation-matrix|--no-derivation-matrix] [--no-design] [--no-docs] [--rebaseline]`

Runs at either of the two levels `<BRD-KEY>` can name (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md`
§3) — a BRD that owns its source document, or one of its slices — grounding only the requirements
that BRD claims. Unlike `/brd-split`, this command refuses neither: a slice is ground exactly as
its parent is.

**Standing rule, stated in full at Phase 4.5 and binding on every phase: documentation is a lead
and a divergence finding — it is NEVER evidence for a `[CG#n]`.** No finding this run writes may
cite a documentation page in its `evidence`, under any verdict. A document is a claim *about*
behaviour, not the behaviour.

---

## Phase 0 — Resolve inputs and gate on main

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate with `key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). If absent or invalid, stop:
   `BRD_GROUND_NEEDS_KEY: /brd-ground needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/dev-workflows:brd-ground <KEY>'.`
2. **Flags.** `--depends-on <BRD-KEY>` — repeatable, each consuming the next token; validate each
   with `key-valid` and drop (warn, do not stop the run) any that fail shape. `--no-design` —
   boolean, skips Phase 5's `design-grounder` step. `--no-docs` — boolean, turns documentation
   grounding off for this run (Phase 1 step 0, Phase 4.5). `--rebaseline` — boolean, see Phase 3. `--derivation-matrix`
   / `--no-derivation-matrix` — mutually exclusive; absent means "let Phase 8 decide the default".
3. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`, per the
   `Required path environment variable unset` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Set SPECS_PATH (enter the path)", "Cancel"]
   ```
4. **Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute
   its `specs-preflight` entry point (§3) inline, **before** the gate below — `require-on-main`
   performs no fetch of its own (`phase-handoff.md` §3.2) and relies on this step's best-effort
   one, the same ordering `/design` Phase 0 uses and for the same reason. Prompt-free and silent
   when the specs repo is clean and on its default branch. If it returns `specs_git: blocked`
   (§3.3 G0), carry that flag for the whole run.
5. **Resolve the BRD folder.** `resolve-address <BRD-KEY>` (`addressing.md` §3), which searches
   `specifications/` and exactly one level below it — either level a `<BRD-KEY>` can name — a BRD folder directly under `specifications/`, or the `PRD-` folder of a slice inside it.
   Absent → stop, without asserting which command would create it: no folder exists, so no
   `brd-link.md` exists either, and nothing on disk says whether this key names a BRD with a source
   document or a slice of one. Naming `/brd-intake` unconditionally would be the wrong advice for
   half the cases, exactly as it is in step 6's `absent` branch below:
   `BRD_GROUND_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent. Do not run /brd-intake on a slice; it has no source document of its own.`
6. **Gate this BRD's own inventory and ledger on main.** Execute `require-on-main`
   (`phase-handoff.md` §3) against the resolved BRD folder's `coverage-ledger.md`. Whichever
   command wrote that ledger wrote the inventory beside it in the same handoff commit
   (`coverage-ledger-format.md` §3's creator table), so its presence on `origin/<default>` implies
   `brd/brd-inventory.md` landed with it: for a BRD with a source document of its own, that was
   `/brd-intake`, and `brd/brd-defect-log.md` landed too; for a slice, it was `/brd-split` running
   on the parent, and there is no defect log to land — a slice reads the parent's
   (`brd-format.md` §2.1). Map the §3.7 return by `stopped` first: any stopping row → stop, naming
   the concrete branch/PR state it reports; `pass` → proceed; `pass_amending` → proceed, printing
   the §3.3 row-B message; `unmanaged` → proceed as before this feature.

   **`absent` (row F) — nothing for this BRD is on any ref — is split twice before it is reported.**
   Row F conflates two states: *never produced* and *produced, handoff declined*. Reported as one,
   the message tells an operator whose files are already written to go and produce them — and on a
   slice it names `/brd-split`, which in that state is a no-op that stages nothing and can never land
   those files at all. Split row F **first on whether `coverage-ledger.md` exists in the worktree**,
   then by level — reading the resolved folder's `brd-link.md` from the worktree (it is there whether
   or not anything reached main) and branching on its `parent:` field, because a slice must never be
   told to run a command that would refuse it.

   **(a) No `coverage-ledger.md` in the folder — it was never produced.** The producing run is the
   fix, and which run that is depends on the level:
   - **No `brd-link.md`, or one with no `parent:`** — this BRD owns its source document. Stop:
     `BRD_GROUND_NEEDS_INTAKE: no intake artifacts on main for <BRD-KEY>, and none in the folder either — run /dev-workflows:brd-intake <BRD-KEY> @<brd-file> for it and merge the pull request first.`
   - **`parent: <PARENT-KEY>` present** — this is a slice, and `/brd-intake` is not the fix: a
     slice has no document of its own to intake (`brd-format.md` §2.1), and the command that writes
     a slice's ledger and inventory is `/brd-split` on the parent
     (`coverage-ledger-format.md` §3). Stop:
     `BRD_GROUND_NEEDS_SPLIT: <BRD-KEY> is a slice of <PARENT-KEY> and its inventory and ledger exist on no ref and in no folder — run /dev-workflows:brd-split <PARENT-KEY> and merge the pull request first. Do not run /brd-intake on a slice; it has no source document of its own.`

   **(b) `coverage-ledger.md` is in the folder, and on no ref — it was produced and its handoff was
   declined.** The files exist; what is missing is a commit. **Say so, and name landing them as the
   action** — one stop code at both levels, because the remedy does not differ:
   `BRD_GROUND_NOT_HANDED_OFF: <BRD-KEY>'s inventory and ledger are written at <BRD-dir> but are on no branch — their handoff was declined, so nothing is missing but the commit. Commit brd/brd-inventory.md and coverage-ledger.md (and, on a BRD that owns its source document, brd/source/ and brd/brd-defect-log.md beside them) to the specs repo's default branch, then re-run '/dev-workflows:brd-ground <BRD-KEY>'. <the level clause below>`

   **Whether the producing command is also a way out differs by level, so name it only where it
   is one:**
   - **A slice — do not name `/brd-split`.** Re-running it on a parent whose ledger is fully
     allocated and whose children are non-empty is a no-op by its own Phase 0
     (`coverage-ledger-format.md` §4): it stages nothing, reports `nothing to commit` and opens no
     pull request. `handoff-to-main` stages only the paths *that* run declared, so the slice's
     already-written files are OTHER to it
     (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.3) and can never reach main by that
     route.

     **Both halves of that condition matter, so the clause carries both.** A parent re-run is a
     no-op only where its ledger is fully allocated **and** no child is left standing while claiming
     nothing; a standing empty child keeps that run alive through its empty-child phase, which does
     stage a `brd-link.md` it writes a `reason:` into. Read the `claims:` list of the `brd-link.md`
     step 6 already opened for its `parent:` and branch on it, because the two states take different
     clauses and asserting the first over the second would tell an operator a live run does nothing:
     - **This slice claims at least one `[BR#n]`** — the ordinary case, and the parent re-run is a
       genuine no-op: `Re-running /dev-workflows:brd-split <PARENT-KEY> will not land them — with this slice claiming rows and the parent's ledger fully allocated, that run is a no-op: it stages nothing and opens no pull request.`
     - **This slice claims nothing** — it is a standing empty child, so the parent re-run is not a
       no-op, but it still will not land *these* files: it declares that child's `brd-link.md`, not
       its inventory and ledger. Say both, so the operator is neither sent to a no-op nor told a
       live run is one: `Re-running /dev-workflows:brd-split <PARENT-KEY> is not a no-op — this slice claims nothing, so that run resolves it, offering to remove it or keep it against a recorded reason. It still will not land these files: it stages that decision, not this slice's inventory and ledger. Committing what is already on disk remains the direct route.`
   - **A BRD that owns its source document — `/brd-intake` is a second, slower way out, and may be
     named as one.** Its Phase 7 declares exactly these paths, so a re-run over this same folder
     does stage them and open a pull request. It is second rather than first because it re-extracts
     the inventory from the source and rewrites the ledger with `disposition: unallocated` on every
     row (its Phase 5) — harmless in *this* state, where nothing has allocated yet (`/brd-split`
     gates on findings this run has not written), and it still needs the source file named again.
     The clause reads: `Re-running '/dev-workflows:brd-intake <BRD-KEY> @<brd-file>' over this same folder would also land them — it rewrites these files and hands them off — but committing what is already on disk is the direct route.`

   This is the same split `/dev-workflows:brd-reconcile` makes on its own row F
   (`BRD_RECONCILE_NEEDS_PACKAGE` versus `BRD_RECONCILE_PACKAGE_NOT_HANDED_OFF`), for the same
   reason: *never produced* and *produced but never handed off* are different facts, and a stop that
   collapses them names a command that does nothing in the state it is reporting.
7. **Require `$REPOS_PATH`.** Resolve `${REPOS_PATH:-/workspace}` (`docs/reference/environment.md`)
   as one directory or a colon-separated list. If no entry resolves to an existing directory,
   stop naming `REPOS_PATH`, per the `Required path environment variable unset` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` — grounding has nothing to check a claim
   against without at least one mounted repository:
   ```
   choices: ["Set REPOS_PATH (enter the path)", "Cancel"]
   ```
8. **Read the claim list, and stop if there is none.** From the gated
   `<BRD-dir>/brd/brd-inventory.md`, extract every `[BR#n]` row's `id` and `text`
   (`brd-format.md` §2 field shape) — this is the `claims` array every dispatch in Phase 5 draws
   from.

   **Zero rows is a stop, not a quiet completion.** With no claim there is nothing to ground, so
   this run writes no finding; writing no finding means there is nothing to hand off; and
   `/brd-split` and `/brd-interview` both gate on exactly that handoff. Reporting "nothing to
   ground" and ending successfully therefore leaves a BRD whose next two commands refuse it and name
   **this** command as the fix — sending the operator back here to be told "nothing to ground"
   again, with the one thing that would change the state named nowhere. The fix for a claimless BRD
   is always upstream, and it differs by level, so this stop reads the resolved folder's
   `brd-link.md` from the worktree and branches on its `parent:` field exactly as step 6 does:
   - **No `brd-link.md`, or one with no `parent:`** — this BRD owns its source document, so its
     inventory is `/brd-intake`'s to rebuild:
     `BRD_GROUND_EMPTY_INVENTORY: <BRD-KEY>'s inventory holds no [BR#n] row, so there is nothing to ground and no finding this run can write. /dev-workflows:brd-split and /dev-workflows:brd-interview both gate on grounding findings, so neither can run until one exists — and re-running this command will report the same emptiness. The fix is upstream: re-run '/dev-workflows:brd-intake <BRD-KEY> @<brd-file>' over this same folder (an existing BRD folder is a re-run, not a refusal) with a source whose requirements brd-reader can identify, and merge that pull request. If the source genuinely states no requirement, this BRD has nothing for the route to carry and stopping here is the end of it.`
   - **`parent: <PARENT-KEY>` present** — this is a slice, and `/brd-intake` is not the fix: a slice
     has no document of its own to intake (`brd-format.md` §2.1), and its inventory is written by
     `/brd-split` on the parent from the rows that parent delegated to it
     (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3). A slice reaches this state
     only as the empty child `/brd-split`'s empty-child check offered to keep with a recorded
     reason:
     `BRD_GROUND_EMPTY_INVENTORY: <BRD-KEY> is a slice of <PARENT-KEY> and its inventory holds no [BR#n] row — it claims nothing, so there is nothing to ground. Do not run /dev-workflows:brd-intake on a slice; it has no source document of its own. Re-run '/dev-workflows:brd-split <PARENT-KEY>': it resolves every standing empty child, so it will offer to remove this slice or to keep it against its recorded reason, and it will offer covered-by against it for any row on the parent's ledger that is still unallocated. If the parent's ledger has no unallocated row left, removal is the only thing that can change this slice's state — /brd-split never re-allocates a row that already carries a fate.`

   **Why a stop rather than an empty handoff.** Writing an empty `grounding/code-grounding.md` and
   handing it off would let both downstream gates pass, but it would assert that grounding ran over
   this BRD when nothing was ever checked, and it would carry `/brd-interview` into generating a
   round's questions for a BRD with no requirement — leaving an empty round record permanently on
   file, which no later run may delete or renumber. A stop that names the upstream fix leaves the
   tree honest and the operator able to act.
9. **Read `brd-link.md`, if present**, and carry **both** of its fields for the rest of the run:
   - `depends-on:` — any prerequisite already recorded by an earlier run. Phase 4 merges this run's
     `--depends-on` into it additively, never replacing it.
   - `parent:` — absent on a BRD that owns its source document, present on a slice. **Phase 10 branches
     on it**, and this is the only step that reads it on a run that reaches Phase 10 at all: steps 6
     and 8 read it too, but each does so inside a branch that *stops*, so on the ordinary path
     neither has run. A file absent here means no `parent:`, which is the source-owning case.

   Recording it here rather than re-opening the file at Phase 10 is what keeps that phase's own
   citation true; a phase that names a step for a value the step never took is a citation nobody can
   follow.

---

## Phase 1 — Resolve repositories

BRDs carry no PR links to auto-derive a repo list from (unlike `/epics`), so this phase is always
the manual path:

0. **Resolve documentation grounding, once, before prompting.** Run
   `resolve-docs-grounding brd-ground` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` and
   surface the `docs grounding:` line it returns — `ON <root> (retrieval: …)` or `OFF (<reason>)` —
   **verbatim**, including any index-build, staleness, or shadowing clause it carries (off switch:
   --no-docs), alongside the repo prompt below. It runs **exactly once per run**, here; Phase 4.5
   consumes the cached result and never re-resolves. Resolving at the phase that prompts is what
   puts the only consent-bearing step (an index build, or a refresh that breached its cap) in front
   of the operator at the moment they are already answering a question, rather than mid-fan-out.
   The `/epics` consent-ordering exception — resolving *ahead* of a `require-on-main` gate
   (`commands/epics.md` Phase 2) — is deliberately not taken here: this command's gate is Phase 0's
   route-sequencing gate, which must stay first so a BRD whose inventory never merged is refused
   before anything else happens at all, and an index build is a durable, run-independent artifact
   that a later stop does not waste.
1. Prompt for the repos in scope for this BRD's claims — a free-text list of short names, one per
   line or space-separated.
2. **Build a slug→clone map**, exactly as `/epics` Phase 4 does: for each top-level directory
   under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin
   2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's
   slug. Skip directories with no `.git` or whose `git remote` call fails/times out. **Never
   assume a `<base>/<slug>` directory name** — resolution is always by remote slug.
3. Resolve each named repo against the map: one match → use it; multiple matches → auto-prefer
   basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last (show candidates before
   proceeding); zero matches → escalate per the `Repo unresolved (zero matches) — /brd-ground` rule
   in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Skip and continue without this repo", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
   ```
4. Empty final list (every repo skipped or missing) → escalate per the `No repos derivable — /epics`
   rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, whose `/brd-ground` variant
   this is:
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
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # docs-grounder (Phase 4.5), code-grounder, design-grounder (Phase 5)
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
   `BRD_GROUND_DIRTY_TREE: <repo> has content changes at <sha> — grounding it would cite an unidentifiable snapshot. Settle that repository's working tree and re-run '/dev-workflows:brd-ground <BRD-KEY>': commit the changes, stash them, or check out a clean copy — the plugin will not do it for you, because these are your files in a code repository this route never writes to. If the changes are what you want grounded, commit them first and re-run with --rebaseline so the new commit becomes the recorded pin.`

   **Every other stop on this route names a command or an action, and this one must too.** The
   remedy is the operator's, not the plugin's — `/brd-ground` mounts code repositories read-only and
   commits to none of them — but "settle the tree, three ways, then re-run this command" is still an
   action a reader can take, and naming which repository and which commit is what makes it one. Both
   named re-runs resolve in the state being reported: the BRD folder and its ledger are already
   gated on main by Phase 0, so nothing about this stop invalidates the command it offers.
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
`altitude: implementation`; `horizon: current`; `consumed_by: none` — which on a baseline finding is
permanent and reports no gap, per `grounding-format.md` §4.1: there is nothing for a PRD, an ARD or a
specification to draw from an assertion that a commit is identifiable, so every downstream
unconsumed-item report excludes these findings rather than carrying one open item per repository
forever. Phase 5 continues the BRD-wide
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

1. `resolve-address <PREREQ-KEY>`. Absent → report `<PREREQ-KEY> — BRD not found`.
2. Found → look for `decisions.md` in its folder. Absent → report
   `<PREREQ-KEY> — no decisions.md yet; contributes no will-change horizons` (per
   `grounding-format.md` §5: a prerequisite whose decisions are not yet frozen contributes none).
3. Present → read only the decisions that are **frozen, which is a field test and not a judgement:
   `status: decided`**, the second of the five statuses
   `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §3 fixes. Nothing else counts, and
   each exclusion is that section's own rule rather than this command's caution: `open` and
   `reopened` "may not be consumed downstream" while they stand; `superseded` and `withdrawn` are
   terminal and describe a position that is no longer held; and an `[AS#n]` never reaches `decided`
   at all (§7), so an assumption is never a frozen decision however confidently it is written.
   **Read the status, do not infer it from how settled a record sounds** — the register carries the
   answer in a field precisely so that this reader does not have to weigh prose, and
   `/dev-workflows:brd-reconcile` uses the same equivalence when it says what freezing a `[CD#n]`
   means. A `decisions.md` this reader genuinely cannot parse into records with statuses — not one
   whose records simply carry no `decided` — is treated as "none frozen" and **reported as
   unparseable rather than as empty**, because the two are different facts and only the first is
   worth someone's attention. Two outcomes:
   - **No record carries `status: decided`** → report
     `<PREREQ-KEY> — decisions.md present, none frozen yet; contributes no will-change horizons`
     — the same "contributes none" consequence as the absent-file case above, just reached from a
     different cause.
   - **At least one record carries `status: decided`** → report readiness in this exact form — the
     `prerequisites:` block, one aligned line per prerequisite, which the Final report below
     reproduces verbatim:
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

## Phase 4.5 — Documentation leads (optional)

Consume the `resolve-docs-grounding brd-ground` result cached in Phase 1 step 0 — never re-run it.
`docs_grounding: OFF` → skip silently, reporting the `OFF` line once. `docs_grounding: ON` →
`dispatch-docs-grounder` (`${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`) with
`feature_summary` = two to four sentences built from the Phase 0 step 8 claim list (what this BRD
asserts and asks for, in product terms), `key` = `<BRD-KEY>`, and `themes` = the capability
themes those claims cluster into.

### A document is never evidence for a `[CG#n]`. Never.

**No `[CG#n]` or `[DG#n]` may cite a documentation page in its `evidence`, under any verdict, in
any phase of this run.** Not as a supporting line, not as a corroborating second source, not as the
thing that turns a `NOT-PROVABLE` into a `CONFIRMED`. Grounding answers one question — *is this
claim true of this specific commit?* (`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §1) —
and a document cannot answer it, because **a document is a claim about behaviour, not the
behaviour**. It was written by a person, at a date, about a version, and nothing keeps it in step
with the code. Cite one and a confident, stale page satisfies a claim the code does not: precisely
the failure `NOT-PROVABLE` exists to make sayable. If the code will not settle a claim, the answer
is `NOT-PROVABLE`, and a page that seems to settle it changes nothing about that.

This is why the digest is **not** passed into `code-grounder`, `design-grounder`, or
`grounding-verifier` — none of their input contracts carries a documentation field, and none is to
be given one. The digest is consumed by this orchestrator alone, in exactly two ways:

1. **As a lead — where to look.** A `docs_references` page naming a subsystem, service, or module
   that **no repository resolved in Phase 1 covers** is surfaced now, before Phase 5 dispatches
   anything, with one choice: add that repository and re-resolve it through Phase 1 step 2–3 (then
   pin it through Phase 3 like any other), or proceed on the record and let the affected claims
   land as `NOT-PROVABLE`. A lead is a question about coverage, never an answer about behaviour.
2. **As a divergence — recorded in Phase 8, after verification, never before.** See below.

### A doc-versus-code divergence gets no identifier of its own

**It is recorded without one, and names the `[CG#n]` it diverges from instead.** Two reasons, and
neither is stylistic:

- **`[CG#n]`/`[DG#n]` cannot carry it.** Those prefixes denote a *finding* — an answer to a `[BR#n]`
  premise checked against a pinned commit or a frame set (`grounding-format.md` §1, §2). A
  divergence is not an answer to a `[BR#n]`; it is an observation about two artifacts, neither of
  which is the requirement. Minting a `[CG#n]` for it would also make it citable and
  `consumed_by`-able — the exact outcome the rule above forbids.
- **A new prefix would be worse, not better.** Every `[CG#n]`/`[DG#n]` must carry a verifier
  outcome or it is not evidence and blocks `/brd-split` (`grounding-format.md` §8). A divergence
  cannot earn one: `grounding-verifier` re-derives from a pinned repository or from a frame set,
  and a documentation page is neither, so a new prefix would either need a verification pass this
  workflow does not have or would sit permanently unverified in the namespace. The existing
  namespace carries the divergence perfectly well **by reference** — the identifier in the entry is
  the finding's, never the divergence's.

Because an entry must name a `[CG#n]`, a divergence can never stand on the page alone, and can
never be written before Phase 7 has verified that finding. That ordering is the safeguard, not a
formality.

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
moved between Phase 3 and this dispatch — stop and re-run from Phase 3 **with `--rebaseline`**, for
the reason Phase 7's `BRD_GROUND_VERIFY_COMMIT_MISMATCH` row states: this run already recorded a
pin, so a plain re-run stops with `BRD_GROUND_NEEDS_REBASELINE`.

**Renumber into one BRD-wide sequence.** Each `code-grounder` instance numbers its own output from
`CG#1` (its own contract, per dispatch) — this is per-instance, not global. Merge every batch's
findings, in repo-resolution order, into one contiguous `[CG#n]` sequence continuing from the
highest `CG#n` already assigned this run — Phase 3's own baseline findings on a first run, or
whatever the highest `CG#n` already on file is on a `--rebaseline` run — never trusting an agent's
own numbers as the BRD's numbering.

**Then `design-grounder`, unless `--no-design`.** Look for `<BRD-dir>/design/`; each immediate
subdirectory is a candidate exported frame set. The location and the index requirement are
`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.1's, cited here rather than restated —
`design/` is a reserved subdirectory of any folder under `specifications/`, so the same path resolves
whether this run stands on a BRD folder or on the PRD folder a slice is. None found → skip, reporting
why (`--no-design` given, or no `design/` folder exists yet for this BRD). One or more found → dispatch one instance per frame set, same ≤4
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

**Record which frame set each `[DG#n]` came from** as you merge — the dispatch that produced it
names exactly one `frame_set_dir`, and Phase 7 hands that same directory back to
`grounding-verifier` so it can re-derive a design-only finding at all. Recovering the association
after the merge would mean guessing; carrying it forward costs nothing.

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
never merely the prerequisite BRD (`grounding-format.md` §5). Where no declared prerequisite has any
`status: decided` record at all, every finding stays `current`, and this is reported plainly rather
than left to look like nothing was checked.

**That case is ordinary, and it is no longer the *only* case.** A prerequisite's `decisions.md` is
written by `/dev-workflows:brd-interview` (its register phase) and gains its `[CD#n]` records from
`/dev-workflows:brd-reconcile`, both of which ship — so a prerequisite that has been through the
route carries frozen decisions as a matter of course, and this phase does real work on it. What
makes the no-frozen-decision case still ordinary is **sequencing, not absence of the capability**:
a prerequisite is typically declared while it is in flight, which is exactly when its register holds
`open` records and no `decided` ones. Report which of the two it is — a prerequisite with nothing
frozen yet, or one this run had nothing to declare against — because "every finding stayed
`current`" reads identically in both and means different things.

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
  >   commit:   [the finding's pinned commit — every CG#n and every class-4 DG#n; omit only for a
  >              class-1/2/3 DG#n, which is pinned to no commit]
  >   cites:    [class-4 DG#n only — the CG#n it cites]
  > repo_path:     [the repository this finding is pinned against — every CG#n; for a class-4
  >                 DG#n, the repository the cited CG#n is pinned against; omit for a
  >                 class-1/2/3 DG#n]
  > frame_set_dir: [every DG#n — the Phase 5 frame set this finding was reconciled against; omit
  >                 for a CG#n]
  > provenance: [own-run | inherited — see below]"

Supply the finding **exactly as the agent's own Inputs contract declares it** — including
`evidence` and, for a class-4 `[DG#n]`, `cites` — even though the agent's own hard rules forbid
reading either before it finishes its independent re-derivation. That sequencing discipline is the
agent's to enforce on itself (its Process step 2 is explicit about it); this orchestrator's job is
only to hand over the full, correctly-shaped record, never to withhold a field the contract lists.

**Which anchor fields go with which finding is that contract's own Inputs table, not this
command's** — read it there (`agents/grounding-verifier.md`, Inputs), never from a copy kept here
that could drift from it. Two consequences for this dispatch:

- **Always pass `class` for a `[DG#n]`.** The agent's row selection is fail-closed — a `[DG#n]`
  arriving without a readable `class` is treated as resting on code and refused for want of a
  commit — so an omitted `class` does not relax the gate, it stops the finding. Phase 5 recorded
  the class on every `[DG#n]` it merged; pass it through.
- **Always pass `frame_set_dir` for a `[DG#n]`.** Phase 5 dispatched `design-grounder` once per
  frame set, so every `[DG#n]` on file traces back to exactly one directory; carry that association
  forward from Phase 5 rather than re-deriving it here. A class-4 `[DG#n]` gets both it and the
  code pair — it is the one finding with a foot in each source.

**`provenance` is set per finding, by origin — never by which phase produced it, and never
blanket.** `own-run` for any finding **this invocation itself produced**, regardless of which
phase did the producing: Phase 3's baseline `[CG#n]` findings qualify exactly as Phase 5's claim
findings do, because Phase 3 re-runs `baseline-integrity` and assigns a fresh id every invocation —
first run or `--rebaseline` alike — never carrying a prior run's baseline finding forward
unreproduced. `inherited` for a finding **this invocation did not reproduce** — concretely, any re-run in which
a given repository's `HEAD` still matched its recorded pin, so Phase 3's first bullet skipped
re-grounding that repository's claims and the pre-existing findings from an earlier invocation
stand as they were, now being re-checked rather than regenerated. **That bullet fires on a plain
re-run and on a `--rebaseline` pass alike** — it is keyed on the pin still matching, not on the
flag — so a plain re-run against an unmoved repository inherits exactly as a `--rebaseline` pass
over one does. Illustrating only the flagged case would read as though the flag were what made a
finding `inherited`; the rule is the origin, and the flag never enters it. Phrasing the rule by origin rather than by
phase number is deliberate: it is immune to a future renumbering the way a phase-keyed rule is not.
The agent's own Inputs contract and `grounding-format.md` §8 both define `inherited` as "another
team's report **or an earlier run of this workflow**," and a finding surviving from before this
invocation, unreproduced, is the second of those, regardless of how confident its write-up reads —
mislabelling it `own-run` would tell the verifier to relax exactly where §5 of its own instructions
say rigor must not drop.

**Act on `status` first — an `outcome` exists only on `status: OK`.** The four statuses below are
refusals, not verdicts: the agent performed no re-derivation and returned no `outcome`, and a
finding carrying no outcome is not evidence and blocks `/brd-split` for as long as it stays on file
(`grounding-format.md` §8). So none of them may be shrugged off and none may be written:

- **`OK`** — act on `outcome`, below.
- **`COMMIT_MISMATCH`** — the repository moved between Phase 3's pin and this dispatch. Stop:
  `BRD_GROUND_VERIFY_COMMIT_MISMATCH: <finding-id> could not be verified — <repo> is at <resolved-HEAD>, not the pinned <commit>. Re-run '/dev-workflows:brd-ground <BRD-KEY> --rebaseline' from a clean tree.`
  The same repair as Phase 5's own `COMMIT_MISMATCH`: re-run from Phase 3, which re-pins and
  re-grounds. **`--rebaseline` is part of the remedy, not an optional extra**, and the message says
  so: Phase 3 already appended this repository's pin to `grounding/baselines.md` before dispatching
  anything, so the re-run finds a recorded pin its `HEAD` no longer matches and stops with
  `BRD_GROUND_NEEDS_REBASELINE` unless the flag is given. "Re-run from a clean tree" on its own
  would send the operator straight into that second stop.
- **`INPUT_MISSING`** — this orchestrator's dispatch was malformed (most often a `[DG#n]` sent
  without its `class` or its `frame_set_dir`). Stop, quoting the field and row the agent named, and
  fire `emit-block` per Phase 11's capture-at-block invariant — a dispatch this command controls
  getting the contract wrong is a plugin gap, unlike Phase 0's environment halts.
- **`REPO_MISSING` / `FRAME_SET_MISSING` / `NO_INDEX`** — the source this finding rests on is gone
  or unusable (a repository unmounted mid-run, a frame set removed or exported without an index
  since it was ground). Stop, naming the finding and the path the agent reported.

**Nothing reaches Phase 8 unverified.** Any stop above happens before Phase 8's first write, so a
finding without an outcome is never written into the package; whatever was on file from a previous
run stands untouched until a clean run replaces it. This is the invariant `/brd-split`'s Phase 0
gate depends on — it counts findings carrying no outcome and refuses to split while any exists, so
a run that wrote one would deadlock the route rather than merely leave a gap.

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
`grounding-format.md` §2 defines (`id`, `claim`, `verdict`, `evidence`, `altitude`, `horizon`,
`consumed_by: none`, plus `class`/`cites` on a `[DG#n]` and `commit` on everything **except** a
`[DG#n]` of class 1, 2 or 3 — those are settled from the frame set alone and are pinned to no commit,
per §2's applicability note) plus this run's verifier `outcome`.
A `--rebaseline` run appends its new findings after the existing ones and marks any finding it
superseded with `verdict: SUPERSEDED`, id retained, rather than deleting or renumbering it.

**Documentation divergences (only when Phase 4.5 ran).** Append a `## Documentation divergences`
section to `<BRD-dir>/grounding/code-grounding.md` — appended there, like the derivation matrix
below, because it is not a produced artifact in its own right. One prose entry per divergence, each
carrying: the documentation page (path relative to the resolved `docs_root`), what it states, and
the **`[CG#n]` whose verified evidence it diverges from**, quoted by id. **No entry gets an
identifier of its own, and no entry may exist without naming a verified `[CG#n]`** (Phase 4.5) —
so a divergence is always the code contradicting a page, established by a finding, never a page
asserting anything about the code. A run with docs grounding ON that found no divergence writes the
section with an explicit "none found" line rather than omitting it; a run with it OFF writes no
section at all. Nothing in this section is ever copied into a finding's `evidence`, and no ledger
row's `evidence` column ever names a page.

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
by every `/brd-*` command, per `brd-intake.md`'s own precedent), `feature_folder` as resolved
in Phase 0, `deliverable_paths` = every file this run wrote or updated under `<BRD-dir>`
(`grounding/baselines.md`, `grounding/code-grounding.md`, `grounding/design-grounding.md`,
`brd-link.md`), `title: <BRD-KEY> Ground requirements against code and design`, and `body_facts` =
the finding counts by verdict, the verifier agreement/extend/contradict/unprovable tally, and the
prerequisite-readiness block; emit its §4.1 outcome line in the final report.

---

## Phase 10 — Next steps

**Branch on whether this BRD is a slice**, using the `parent:` field Phase 0 step 9 carried forward
from `brd-link.md` — offering a command that would refuse the very key just ground is worse than
offering nothing.

**No `parent:` — this BRD owns its source document:**

```
choices: ["Split the BRD now that every finding carries a verifier outcome — /dev-workflows:brd-split <BRD-KEY> (Recommended) <merge-clause>", "Ground another declared prerequisite first", "Stop here", "Other… (describe)"]
```

`/dev-workflows:brd-split <BRD-KEY>` is the third command of the BRD-to-PRD route, and the last
one that has to run before this BRD's requirements all carry a recorded fate — **it is not the end
of the route**. `/dev-workflows:brd-interview <BRD-KEY>` follows it, and `/brd-split`'s own Phase 7
is what offers it, so it is not offered here: putting it in this list would name a step out of
order, since it refuses a ledger that still holds an unallocated row. `/brd-split` will not start
until this phase's findings are on the specs repo's default branch — its own Phase 0 gates
`grounding/code-grounding.md` on `origin/<default>`; **which words state that wait are
`<merge-clause>`'s**, resolved from this run's own `Phase handoff:` outcome line per
`${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`, since a declined handoff opened no pull
request to wait on — and it carries its own role and
cost-attribution row (`docs/roles-and-phases.md`). Guidance only, per
`${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — names only that `/brd-split` exists and
where it sits in the route, never its behaviour, which `commands/brd-split.md` owns.

**`parent: <PARENT-KEY>` — this BRD is a slice.** `/brd-split` **is** offered, and the offer says
which of its two modes will run, so nobody expects a fan-out that cannot happen: on a slice it runs
`allocate-only` (`commands/brd-split.md` Phase 0 step 5) — it creates no child, because nesting is
capped at one level (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §6), and walks this
slice's ledger to a recorded fate through four resolutions instead of five, `covered-by` being the
one that command's walk does not offer on a slice. Allocating is what
makes this slice PRD-eligible
(`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5), so it is a real next step, not a
formality:

```
choices: ["Allocate this slice's ledger — /dev-workflows:brd-split <BRD-KEY> (Recommended — allocate-only, so no child is created) <merge-clause>", "Ground another declared prerequisite first", "Stop here", "Other… (describe)"]
```

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
an inventory or ledger not yet on main (`BRD_GROUND_NEEDS_INTAKE` or, for a slice,
`BRD_GROUND_NEEDS_SPLIT`; `BRD_GROUND_NOT_HANDED_OFF` where they exist and were never handed off),
an inventory carrying no claim at all
(`BRD_GROUND_EMPTY_INVENTORY`, which is a fact about the customer's document or about what the
parent allocated, not about this plugin), and an unset `$REPOS_PATH` are environment / sequencing
halts, never a plugin capability gap. `BRD_GROUND_DIRTY_TREE`, `BRD_GROUND_NEEDS_REBASELINE`, and Phase 7's
`BRD_GROUND_VERIFY_COMMIT_MISMATCH` are repository state, not a plugin gap, either — unlike Phase
7's `INPUT_MISSING`, which is this command getting its own dispatch contract wrong and does fire
`emit-block`.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-ground`; what was produced (baselines,
   code/design findings, verifier tally, prerequisite readiness, documentation divergences); key
   events (a dirty-tree stop, a rebaseline, a skipped design pass, an unresolved repo, docs
   grounding OFF or a lead that added a repository — or "none"); workarounds; test result
   N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`
   and call its `emit-auto` entry point (§6) with the Lessons Learned report, `command: /brd-ground`,
   the run's `key` (the `<BRD-KEY>`), `source`, and `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no
   plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and
   call its `emit-cost` entry point with `command: /brd-ground`, `phase: brd-to-prd`, `role: pa`,
   the run's `key`, `source`, and `plugin_version`. Surface the persisted path (or the
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
in the two-column form Phase 4 step 3 fixes; finding counts by verdict for `[CG#n]` and `[DG#n]`
separately, and the verifier
tally (`agree` / `extend` / `contradict` / `unprovable`) with every `contradict` rewrite named by
id; the `docs grounding:` line from Phase 1 step 0 verbatim, any repository a Phase 4.5 lead added,
and the count of documentation divergences recorded (each named by the `[CG#n]` it diverges from —
never by an identifier of its own, because it has none); whether the derivation matrix ran and why; any `design-grounder` class-4 gap deferred for want
of a settling `[CG#n]`; the feedback + cost paths; the `Phase handoff:` outcome line
(`phase-handoff.md` §4.1); the `Specs repo:` outcome line (`specs-repo-git.md` §6); the next-step
recommendation; and end with the ledger line, read fresh from the (unmodified-by-this-run)
`coverage-ledger.md`, exactly per `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

`/brd-ground` never changes a ledger disposition — that line simply reports where allocation stands
going into `/brd-split`.

**Reporting it now reads one ledger per `covered-by` row.** §6 counts a delegated row through the
BRD it names — a child on a BRD that owns its source document, a sibling or the parent on a slice
(`coverage-ledger-format.md` §3) — so this report resolves each `covered-by: <BRD-KEY>` row one hop
into that BRD's own `coverage-ledger.md`, resolved from the
working tree by `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3). **This adds
no precondition and no gate.** A child folder that is absent from the tree this run is standing in —
its split not yet merged, most commonly — makes that row `unresolved` in the line and nothing more:
grounding this BRD does not depend on any child, and a run must never stop, degrade, or withhold its
findings because a child could not be read. Phase 0's `require-on-main` gates stay exactly as they
are, on this BRD's own inventory and ledger. A slice does **not** always reach this with
nothing to resolve. `covered-by` is legal on a slice (`coverage-ledger-format.md` §3), where it
names a sibling under the same parent or that parent and marks an **orphan row** — a provisional
claim the parent's walk withdrew (§2). Those rows are resolved one hop exactly like a parent's
delegated rows, so a slice reports zero delegated only when its parent withdrew none of its
claims.

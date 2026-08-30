---
name: brd-split
description: BRD-splitting workflow (PM phase, third and final command of increment 1's BRD-to-PRD route). Gates on every grounding finding carrying a verifier verdict, proposes candidate slices from the grounded picture (buildable now, blocked, or dependent), keys and nests a child BRD folder per confirmed slice with its own brd-link.md, then walks every unallocated coverage-ledger row one at a time through five resolutions (build here, assign to a named child, defer to this BRD, reject citing a defect, or mark superseded) until none remain unallocated, and writes slices.md with the rationale for each slice and each deferral. Re-running on a fully-allocated BRD is a no-op that prints the ledger. Offers /brd-ground on each new child as the next step.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Split the grounded BRD into child BRDs and allocate every requirement: $ARGUMENTS

`/brd-split` is the **third and final command of increment 1's BRD-to-PRD flow** (PM phase) — it
takes the findings `/brd-ground` verified and forces every `[BR#n]` in this BRD's coverage ledger
to a recorded fate: built here, built by a named child, deferred, rejected, or superseded. This is
the only place that fate is ever decided (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md`
§1) — without this command's gate, a long BRD split across several children could have every child
quietly wave a requirement past, and nothing would notice.

Usage: `/brd-split <BRD-KEY>`

Runs at whatever level `<BRD-KEY>` names (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md`
§3) — a parent BRD or one of its own slices — splitting and allocating only that BRD's own claimed
requirements.

---

## Phase 0 — Resolve inputs and gate on verification

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate with `brd-key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §1). If absent or invalid, stop:
   `BRD_SPLIT_NEEDS_KEY: /brd-split needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/dev-workflows:brd-split <KEY>'.`
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`
   (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute
   its `specs-preflight` entry point (§3) inline. Prompt-free and silent when the specs repo is
   clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
   `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal
   `commit-artifacts` step skips on it.
4. **Resolve the BRD folder.** `resolve-brd <BRD-KEY>` (`brd-addressing.md` §2). Absent → stop:
   `BRD_SPLIT_NOT_FOUND: no BRD folder found for <BRD-KEY> — run /dev-workflows:brd-intake <BRD-KEY> @<brd-file> first.`
5. **Require grounding findings on file.** Read `<BRD-dir>/grounding/code-grounding.md` and
   `grounding/design-grounding.md`. Neither exists (grounding has never run for this BRD) → stop:
   `BRD_SPLIT_NEEDS_GROUNDING: no grounding findings on file for <BRD-KEY> — run /dev-workflows:brd-ground <BRD-KEY> first.`
6. **Gate on verification.** Every `[CG#n]`/`[DG#n]` finding carries a verifier `outcome` (one of
   the four in `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §8 — `agree`, `extend`,
   `contradict`, `unprovable`) once `/brd-ground` Phase 7 has run over it; a finding without one
   "is not evidence and cannot be recorded as `consumed_by` anything" (§8), and this command must
   never propose a slice or offer `covered-here` against a claim nobody has actually verified.
   Count every finding on file carrying no recorded `outcome`. Any count `N` greater than zero →
   stop: `BRD_SPLIT_UNVERIFIED: N findings have no verifier verdict — run /dev-workflows:brd-ground first.`
7. **Read the ledger; check for the no-op case.** Read `<BRD-dir>/coverage-ledger.md` and compute
   its disposition counts (`coverage-ledger-format.md` §3). **Zero rows are `unallocated`** → this
   run is a no-op (§4): nothing in Phases 2–5 has anything left to do, so skip straight to Phase 6
   (Handoff), which will report nothing to commit, and the Final Report's ledger line below.
8. **Enumerate existing children.** List every immediate subdirectory of `<BRD-dir>` whose name
   matches `<KEY>{-|_}<slug>` (`brd-addressing.md` §2 step 1), excluding `brd/`, `grounding/`, and
   `dev-workflows/` — none of those is ever a BRD folder. Each match is a child a previous
   `/brd-split` run already created, nested per §3, and remains a valid `covered-by` target in
   Phase 4 even when this run proposes no new slice of its own.

---

## Phase 1 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT for an unusually large requirement count or slice fan-out
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # impl-maintenance only — no other agent runs in this command
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`/brd-split` dispatches no grounding or review agent of its own — every finding it reads was
already independently verified by `/brd-ground`'s `grounding-verifier` pass (Phase 0 step 6) — so
`detection_model` here exists only for the terminal `impl-maintenance` dispatch. If no Opus
resolves for `current_model`, degrade to best-available + record in `notes` and the final report —
never hard-block.

---

## Phase 2 — Propose slices

Read `<BRD-dir>/brd/brd-inventory.md`, `coverage-ledger.md`, `grounding/code-grounding.md`, and
`grounding/design-grounding.md`. For every `[BR#n]` still `unallocated`, read its findings'
`verdict` and `horizon` (`grounding-format.md` §2–§3, §5): a requirement whose findings are all
`CONFIRMED`/`AMENDED` at `horizon: current` is **buildable now**; one carrying `REWRITTEN` or
`FALSE-FRIEND` needs reconsidering before it is buildable at all; one carrying `NOT-PROVABLE` or a
`will-change` horizon is **blocked** or **dependent** on the named prerequisite decision. Cluster
requirements along these buildable / blocked / depends-on lines into candidate slices — a
coherent, independently buildable group of `[BR#n]` rows, never a single row on its own unless
nothing else clusters with it.

Present the candidate slices (each: a short working name, its `[BR#n]` rows, and the one-line
buildable/blocked/depends-on rationale that put them together) and confirm before anything is
created:

```
choices: ["Accept these slices as proposed (Recommended)", "Edit one or more slices (rename, merge, move a row)", "Replace with a different slice list entirely", "Propose no slices — walk the ledger directly", "Cancel", "Other… (describe)"]
```

**Zero confirmed slices is a legitimate outcome.** A BRD nobody splits still needs every row walked
in Phase 4 — most naturally landing on `covered-here`, per §5's PRD-eligibility rule — so choosing
"walk the ledger directly" or editing the list down to nothing skips Phase 3 entirely and proceeds
straight to Phase 4 with whatever children Phase 0 step 8 already found (if any).

---

## Phase 3 — Key and nest each confirmed slice

For every slice Phase 2 confirmed:

1. **Take a key.** Propose a default of the parent's key plus the next unused two-digit segment
   (e.g. `<PARENT-KEY>-01`, `<PARENT-KEY>-02`, …, skipping any segment an existing child from
   Phase 0 step 8 already uses) and let the operator accept it or supply their own. Validate
   whatever is used with `brd-key-valid` (`brd-addressing.md` §1); an invalid key is re-prompted,
   never silently coerced.
2. **Create the folder inside this one.** `specifications/<PARENT-KEY>-<parent-slug>/<CHILD-KEY>-<child-slug>/`,
   per `brd-addressing.md` §3 — a child BRD is never a sibling of its parent. `<child-slug>` is a
   kebab of the slice's working name from Phase 2.
3. **Write the child's `brd-link.md`**: `parent: <BRD-KEY>` and `claims:` — the slice's `[BR#n]`
   rows as currently proposed. This is provisional: Phase 4's walk is the step that actually moves
   a row's disposition, and a row proposed here for this child but resolved differently there (for
   example rejected instead) is removed from this list at that point, never left to disagree with
   the ledger.

A slice confirmed in Phase 2 but never given a folder here (the operator cancelled mid-key-taking)
is dropped — it never becomes a `covered-by` target, and its rows return to the ledger walk
unclustered.

---

## Phase 4 — Walk the ledger

For every row in `coverage-ledger.md` still `disposition: unallocated`, present it **exactly one
at a time, never batched**, via `AskUserQuestion` — quoting its `id`, `text`, `defects`, and
`evidence` so the operator has everything needed without opening the file:

```
choices: ["Build here — covered-here (Recommended when nothing clusters, or this fits no slice)", "Assign to a named child BRD — covered-by", "Defer to this BRD — deferred-to (a real allocation, not a shortcut)", "Reject — citing a [DEF#n]", "Mark superseded by another [BR#n]", "Cancel", "Other… (describe)"]
```

These are the five resolutions `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3
defines, and this command **cannot complete while any row stays `unallocated`** (§4) — a `Cancel`
mid-walk stops the run naming how many rows remain, but every row already resolved this pass stays
written; nothing already decided is rolled back.

- **Build here** → `disposition: covered-here`. **This is the resolution that makes the whole BRD
  PRD-eligible** (`coverage-ledger-format.md` §5) — it is not an afterthought among the five, it is
  the escape valve that keeps this command able to complete on a BRD nobody actually splits.
  Without it, an unsplit BRD would have no row that could ever leave `unallocated` except by
  deferring, rejecting, or superseding every one of them, and no BRD could ever become eligible for
  a PRD of its own — allocation would deadlock at the very case this command must handle most
  routinely.
- **Assign to a named child BRD** → prompt for the child's key: any created in Phase 3 this run, or
  any found already nested under this BRD in Phase 0 step 8. Reject a key that resolves to neither
  and re-prompt — `covered-by` never names a folder that does not exist. Write
  `disposition: covered-by: <CHILD-KEY>`, and add this row's `[BR#n]` to that child's `brd-link.md`
  `claims:` list if it is not already there.
- **Defer to this BRD** → `disposition: deferred-to: <this BRD>`. Prompt for a one-line rationale —
  held for Phase 5's `slices.md`. Deferring is itself an allocation
  (`coverage-ledger-format.md` §3): the point is that the requirement's fate is recorded, not that
  everything must be built now.
- **Reject** → prompt for the `[DEF#n]` that justifies it; it must already exist in
  `brd/brd-defect-log.md` (`brd-format.md` §3–§4) — a row with no qualifying defect is not rejected
  this way; resolve or raise the defect first. Write `disposition: rejected: [DEF#n]`.
- **Mark superseded** → prompt for the replacing `[BR#n]`; it must already exist in
  `brd/brd-inventory.md`. Write `disposition: superseded-by: [BR#n]`.

---

## Phase 5 — Write `slices.md`

Write `<BRD-dir>/slices.md`:

- **One block per slice** confirmed and keyed in Phases 2–3: its key, its folder, and the
  buildable / blocked / depends-on rationale that put its `[BR#n]` rows together rather than
  elsewhere or left on this BRD.
- **One block per row** Phase 4 resolved `deferred-to: <this BRD>`: its `[BR#n]` and the one-line
  rationale collected for it in Phase 4 — why it is a live obligation of this BRD rather than built
  now.

A run that proposed zero slices (Phase 2) still writes `slices.md`, with an explicit note that no
slice was proposed and why, plus every deferral this run recorded — the file is never skipped just
because nothing was carved off this BRD.

Skipped entirely on the Phase 0 step 7 no-op path — nothing was walked, so there is nothing new to
rationalize.

---

## Phase 6 — Handoff

Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`phase-handoff.md` §2) with `prefix: brd` (shared
by the three `/brd-*` commands, per `brd-intake.md`'s own precedent), `feature_folder` as resolved
in Phase 0, `deliverable_paths` = every file this run wrote or updated under `<BRD-dir>`
(`coverage-ledger.md`, `slices.md`, and — one per confirmed slice — its new folder and
`brd-link.md`), `title: <BRD-KEY> Split into child BRDs and allocate coverage`, and `body_facts` =
the slice count and keys, the walk's resolution tally by disposition, and whether this run was the
Phase 0 step 7 no-op; emit its §4.1 outcome line in the final report. The no-op path reaches this
phase with nothing staged, so it reports the `nothing to commit` line rather than opening a pull
request.

---

## Phase 7 — Next steps

Every child folder Phase 3 created **re-enters the route at grounding** — a child BRD is graded on
its own claimed requirements exactly as any BRD is, and nothing about being a slice exempts it from
that:

```
choices: ["Ground each child created above — /dev-workflows:brd-ground <CHILD-KEY> (Recommended, once per child)", "Stop here — this BRD's own allocation is complete", "Other… (describe)"]
```

No children were created this run (every row landed `covered-here`, deferred, rejected, or
superseded) → the second choice is the natural one, stated plainly rather than omitted. Guidance
only — never auto-invokes another command. Recording decisions and preparing a customer package
are not steps this plugin offers yet; `/brd-split` is the last command of this route today, so a
BRD that is fully allocated — split or not — simply stops here for now.

### Context hygiene

Per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`, the resume pointer is written in the
terminal cost phase (Phase 8), after the cost entry and before the commit step. Grounding a child
created above, even yourself? → run **`/clear`** for a clean slate. Guidance only — nothing is
auto-run.

---

## Phase 8 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 7, NEVER interrupts an earlier phase, and runs on the Phase 0
step 7 no-op path exactly as on any other.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin / skill / command / reference
gap, `emit-block` (`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) fires at that halt
before escalating. None of Phase 0's stops qualify — a missing key, an unresolved BRD, missing or
unverified grounding, and an unset `$SPECS_PATH` are environment / sequencing halts, never a plugin
capability gap.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-split`; what was produced (slices
   confirmed and keyed, the ledger walk's tally, `slices.md`); key events (the no-op path, a
   cancelled walk with N rows left, a rejected `covered-by` key — or "none"); workarounds; test
   result N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-split`, the run's `jira_key` (the `<BRD-KEY>`),
   `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
   Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call
   its `emit-cost` entry point with `command: /brd-split`, `phase: brd-to-prd`, `role: pm`, the
   run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and
   write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry above, and before
   the commit step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry
   point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths
   inside `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-split)` with
   no `Co-Authored-By` trailer, and pushes to the branch Phase 6's handoff created. It NEVER touches
   a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER
   fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0),
   re-emitting that notice. Hold its §6 outcome line for the final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable
is offered only in Phase 6), and NEVER writes into a code/docs repo or the current working
directory; no user name is ever written.

---

## Final report

Report: the BRD folder; whether Phase 0 step 7 found this run a no-op (fully allocated already) or
whether it actually split and/or walked the ledger; the classification and model routing (+ any
Opus degradation); every slice proposed, keyed, and its folder (or that none were proposed and
why); the ledger walk's resolution tally by disposition, with every new `covered-by` key and every
`rejected`/`superseded-by` citation named; the `slices.md` path (or that it was skipped on the
no-op path); the feedback + cost paths; the `Phase handoff:` outcome line from `handoff-to-main`
(`phase-handoff.md` §4.1); the `Specs repo:` outcome line from `commit-artifacts`
(`specs-repo-git.md` §6); the next-step recommendation; and end with the ledger line, exactly per
`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated
```

`/brd-split` is the only `/brd-*` command that can ever change this line's final term — a
completed run always ends it at `0 unallocated` (`coverage-ledger-format.md` §4: "cannot complete
while any row in this BRD's ledger is `unallocated`"), whether that took an actual walk this run or
was already true when Phase 0 step 7 found nothing left to do.

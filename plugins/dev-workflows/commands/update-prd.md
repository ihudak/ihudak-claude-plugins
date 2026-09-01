---
name: update-prd
description: PRD-update workflow (PM phase) — refresh/re-do an existing Product Requirements Document. Resolves the PRD from the specs tree (the only copy), grounds on the PRD + any ARD/spec/transcript, updates it via a relentless grill against references/prd-format.md, gated by the Opus prd-reviewer, and writes canonical + archived revisions into $SPECS_PATH/specifications/PRD-<KEY>-<slug>/. Product-level (no code scan).
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Update the Product Requirements Document: $ARGUMENTS

`/update-prd` refreshes an **existing** Product Requirements Document (PM phase). It covers routine refreshes (new
information, scope tweaks, wording) and the rare obstacle-driven re-do (a human read an ARD/spec finding,
discussed it, and decided the PRD must change). The PRD is **product-level** — what / why /
for-whom, not how. Zero code scan; no repos.

Usage: `/update-prd <KEY> [@transcript-or-notes ...] [--no-docs]` (`--no-docs` turns off documentation grounding for the run — see Phase 1).

---

## Phase 0 — Resolve inputs

1. **`KEY` (mandatory).** Parse the first non-flag token and validate it with `key-valid` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1) — the grammar is that file's, cited rather than copied here. If absent or malformed, stop: `UPDATE_PRD_NEEDS_KEY: /update-prd needs the PRD's key — '/dev-workflows:update-prd <KEY>'.` **The grammar is a superset of the two-segment form** — every key that validated before still validates, so a `PRODUCT-1234` refresh behaves exactly as it did — and it is the one this command needs for the same reason step 3's folder resolution is: a PRD authored inside a BRD slice by `/create-prd` on the BRD route carries a three-segment key (`EPIC-008-01`), and `/create-prd` **redirects here** on finding it. A validation narrower than `/create-prd`'s would refuse that redirect at the door, which is the identical dead-end step 3 exists to close, one step earlier.
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Feature folder.** Resolve it with `resolve-address <KEY>` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which searches every level §3 bounds and carries §5's legacy fallback; `ambiguous` → stop, naming every match and `@<path>` as the way through. **`status: absent` is a stop, not a folder to create**: surface the `key dir not found` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`choices: ["Re-enter key", "Cancel"]`) and name `/dev-workflows:create-prd <ADDRESS>` as the run that authors a PRD where none exists. **Named unqualified here and only conditionally at step 4, and the difference is what resolved: nothing did.** There is no folder, so there is no `brd-link.md`, no gate set and no kind to test — `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5.2's *Only a BRD-route folder has a gate set at all* is the case that applies, and the container refusal that is `/create-prd`'s third has no folder to fire on. Step 4 reports a folder that **does** exist, which is why it tests all three before it names that command. No matching rule is written here — §5 owns it.
4. **Resolve the base PRD.** It is the `prd.md` in the folder step 3 resolved — the only copy there is, and therefore authoritative without a test. Absent → stop gracefully:
   ```
   UPDATE_PRD_NO_PRD: <ADDRESS> resolves a folder at <path> holding no prd.md, and /update-prd refreshes an existing PRD rather than authoring one. <the remedy, per the row below that matches>
   ```

   **`/create-prd` is named only where that command can itself run.** It refuses **three** shapes,
   not one (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5.2, the authority, not
   restated here), and this step has cleared **none** of them. `/update-prd` takes no container
   refusal of its own and needs none — a `BRD-` container holds no `prd.md` and stops right here —
   but that is exactly why the folder this stop reports may *be* a container; and on the BRD route it
   may be a slice whose own ledger refuses a PRD. Naming `/create-prd` unconditionally sends the
   operator into another command's Phase 0 to be refused a second time, and on a slice whose every
   claimed row is `deferred-to` or `rejected` it sends them into `CREATE_PRD_BRD_NOT_ELIGIBLE` — the
   branch that names no command at all by design. Resolve the remedy from the table below.

   | The resolved folder | What the stop names |
   |---|---|
   | A `BRD-` container — the `BRD-` prefix, or on an unprefixed legacy folder §5.1's positive test (`coverage-ledger.md` or `brd/brd-inventory.md` present, and no `brd-link.md` naming a `parent:`) | **Not** `/create-prd`, which refuses a container in turn. Name the `PRD-` slices under it, one PRD each — enumerated by `/brd-split` Phase 0 step 9's positive test (an immediate subdirectory whose `brd-link.md` `parent:` names this BRD), never by a name match — and offer `/dev-workflows:create-prd <SLICE-KEY>` once per slice, as the statement that a PRD belongs there rather than a promise that the slice is already eligible. Where the container holds no slice, `/dev-workflows:brd-split <BRD-KEY>` is the run that carves one, and it is a **no-op** on a ledger with no `unallocated` row (`commands/brd-split.md` Phase 0 step 10), so say what the operator does then rather than leaving the offer to fail silently |
   | No `brd-link.md` — an idea-route `PRD-` folder, or its legacy unprefixed form, which carries neither §5.1 file | `/dev-workflows:create-prd <ADDRESS>`. There is no gate set, so neither data refusal exists for it and the container test is the only one there was — which this row has passed |
   | A `brd-link.md`; the gate set leaves **no** row `unallocated` **and** at least one `covered-here` | `/dev-workflows:create-prd <ADDRESS>` — all three refusals cleared |
   | A `brd-link.md`; a gate-set row is still `unallocated` | **Not** `/create-prd`, which raises `CREATE_PRD_BRD_UNALLOCATED`. Name `/dev-workflows:brd-split <SLICE-KEY>`, whose walk moves exactly those rows and which on a slice runs allocate-only — and say beside it that its own Phase 0 gates on this slice's grounding findings each carrying a verifier verdict and stops naming `/dev-workflows:brd-ground <SLICE-KEY>` when they do not |
   | A `brd-link.md`; no gate-set row `covered-here`, and the gate set is **empty** | **Not** `/create-prd`, which raises `CREATE_PRD_BRD_NOT_ELIGIBLE`. This is a standing empty child: name the keep-or-remove `/dev-workflows:brd-split <PARENT-KEY>`, the one run that resolves one and not a no-op there. `<PARENT-KEY>` is **read** off the same `brd-link.md` the `claims:` list came from (§5.2), never parsed out of the slice's own key or folder name |
   | A `brd-link.md`; no gate-set row `covered-here`, and the gate set is **non-empty** | **Name no command at all**, and say why rather than going quiet: this slice holds no PRD of its own, `/create-prd` would raise `CREATE_PRD_BRD_NOT_ELIGIBLE` whose non-empty branch names nothing either, and nothing in this plugin moves a terminal row back to `unallocated` (§3). Report what the gate-set rows actually resolved to — `deferred-to` is a live obligation of this slice, `rejected` is an obligation of nobody, `superseded-by` was absorbed by the `[BR#n]` that replaced it |

   **The gate set is §5.2's, cited rather than re-derived**: this slice's own `coverage-ledger.md`
   rows narrowed by its `brd-link.md` `claims:`, read **out of the ledger file and never off a
   `ledger:` line** (§6.1), with an orphan row neither adding the option nor withholding it because
   it is never `covered-here` and never `unallocated`. **This is the only coverage ledger
   `/update-prd` ever opens**, it is confined to this stop, and it happens after the run has already
   been refused — no phase of a proceeding run reads one.

   **This used to be a ladder, and the ladder's premise is what went.** The authoritative PRD text lived in a tracker, so this step read an imported copy, stopped when none existed, and offered a refresh when one was more than three days old. There is one copy now and it is in the folder this run resolved: nothing to import, nothing to go stale, and no second copy to disagree with.
5. **Secondary grounding (read-only).** Discover in the feature folder: the folder's `prd.md`, any `ard.md`, `specification.md`; plus any `@transcript` / notes path(s) passed in `$ARGUMENTS`.

These reads are deliberately **not** gated: `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) is never executed by this command. `/update-prd`'s authoritative base is the resolved folder's own `prd.md`, and Phase 2 already rules that it wins where a secondary artifact disagrees. Gating advisory grounding would block a legitimate PRD refresh because an unrelated ARD sits on a branch. Where a discovered `ard.md` or `specification.md` is **not** on the specs repo's default branch, say so in the Phase 1 confirmation — the user should know the grounding is unapproved, not be stopped by it.

`/update-prd` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

---

## Phase 1 — Configure

Use `choices` arrays; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0).

1. **Confirm** the feature folder; the resolved PRD base; and the secondary artifacts discovered (specs draft / ARD / spec / transcript).
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).
   - Report any discovered `ard.md` or `specification.md` that is not on the specs repo's default branch — per Phase 0 step 5, this grounding is unapproved but advisory-only; it is never a reason to stop the run.
2. **Scope of the update.** `choices: ["Refresh (incorporate new info / comments / transcript) (Recommended)", "Re-do (substantive re-scope driven by an ARD/spec obstacle)", "Cancel"]`.

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record the `model_routing` block exactly as `/create-prd` does (`classification`, `reason`, `current_model`, `detection_model` §2.1 Sonnet chain, `review_model` §2 Opus chain for `prd-reviewer` (frontmatter-pinned), `authoring_model` = current_model, `opus_available`, `notes`). The grill + authoring run inline on `current_model`; if no Opus resolves, degrade to best-available + record in `notes`.

---

## Phase 2 — Read the base + grounding

Read the PRD **body** (the authoritative base and the signal for *what to change*), then the secondary artifacts (ARD, spec, transcript). Do NOT treat a secondary artifact as authoritative where it disagrees with the resolved folder's `prd.md` — the base PRD wins; surface a notable divergence to the user.

Then run `resolve-docs-grounding update-prd` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the PRD goal + the change signal from comments, `key` = `<KEY>`. Carry the digest into the Phase 3 grill with **grill-rank** consumption. When OFF, skip silently.

---

## Phase 3 — Update via grill

**Interview technique (grilling — embedded).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split, dependency order.

Update the PRD live against `${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, **diffing against the base** rather than authoring from blank: surface what changed and why (drawing on comments / ARD / spec / transcript), resolve open questions, keep the PRD product-level. Apply the **self-consistency check** — no `[AC#N]` delivering an Out-of-scope behaviour, no `## Goal` vs `## Scope` contradiction, no conflicting `[US#N]`; record a deliberately-kept tension under `## Assumptions & open questions`. Preserve the frontmatter provenance fields (`sources`, `derived_from`, `seeded_from_prd` if present) — **and, on a PRD that carries them, `brd_key`, `brd_parent` and `depends_on`**, copied through the refresh unchanged. Those three are BRD provenance `/create-prd` on the BRD route wrote from the slice's own `brd-link.md` (`${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`), and this command reads no BRD tree, so a value it drops is one nothing later can restore. **`brd_parent` travels with `brd_key`**: that route resolves a `PRD-` slice folder and refuses a `BRD-` container, and a slice always has a `parent:`, so a PRD arriving with `brd_key` and no `brd_parent` is one `prd-reviewer` raises as a finding rather than one this run should complete — preserve what is there and author neither. **No command consumes the three fields yet** — neither `/dev-workflows:epics` nor `/dev-workflows:ready` reads any of them, `depends_on` has no reader anywhere; `brd_parent` and `brd_key` are read only by `prd-reviewer`, which raises a finding when one appears without the other — an integrity check on the pair, never a consumer of what they record. Nothing consumes the prerequisites they record. Preserving them is right regardless: provenance that survives an update is the precondition for any future consumer, and re-deriving it later would mean re-reading a BRD tree that may have moved on. Dropping them would silently make a slice's PRD look like an ordinary one, with nothing left to restore it from. Carrying an existing value forward is **preservation, not authoring** — this run mints none of the three, asks the PM for none of them, and writes none onto a PRD that arrived without them, so `prd-format.md`'s rule that they are written only by `/create-prd` on the BRD route holds unchanged. `key` is likewise carried, not re-derived. `/create-prd` writes it on both routes, set to the resolved folder's own key (`${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`), so a PRD reaching this command already carries one and this run has nothing to mint: on the BRD route that value is the `PRD-` slice's key, which is the folder this PRD lives in, and a PRD arriving with `brd_key` and no `key` at all is a finding `prd-reviewer` raises rather than a gap for this run to fill.

---

## Phase 3.5 — Prose style check

Run the prose style check on the updated PRD **before** the review gate (quality enhancement, never a gate) — mirror `/create-prd` Phase 3.5 (Agent `prose-style:prose-style-checker`, `doc_type: prd`, `detection_model`); apply MAJOR fixes inline and re-run once; skip gracefully if the agent is unavailable.

---

## Phase 3.6 — Structural pre-lint

Run the deterministic checks in `${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` (the Universal checks + the **key-collision** check on the body below the frontmatter + the **PRD** block) against the updated file; inline-fix mechanical findings; leave content gaps for the grill. Advisory — never blocks; `prd-reviewer` remains the gate.

---

## Phase 4 — Review gate

Dispatch `prd-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:prd-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the Product Requirements Document:
  >
  > PRD path: [absolute path to the updated prd.md]
  > Profile: [lean | hybrid | full — infer from the sections present]"

Act on the verdict as `/create-prd` Phase 4 does: on `BLOCK`, fix the BLOCKER findings inline and re-review once; if still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. Cap: one fix cycle + one re-review.

---

## Phase 5 — Handoff (canonical + archive)

1. **Archive the current canonical PRD** (if one exists) to `<feature-folder>/revisions/<KEY>_<slug>_<YYYYMMDD>.md` before overwrite (same-day second revision → suffix `-2`, `-3`, …).
2. **Write the refreshed PRD** to the **canonical** path `<feature-folder>/prd.md`. Record `revision_of: <archived snapshot path>` and `built_from_date: <YYYY-MM-DD>` (the date the update was built from) in the frontmatter.
3. **Hand off** (commit-when-asked — never automatic). Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's consent choice verbatim: `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]`. On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: prd`; `feature_folder` as resolved in Phase 0; `deliverable_paths` = the canonical PRD file (step 2) and the archived snapshot file (step 1); `title: <KEY> Update Product Requirements Document`; and `body_facts` = which sections changed, the date the update was built from, the open-question count, and the `prd-reviewer` verdict. Emit its §4.1 outcome line in the Final report.

---

## Phase 6 — Next steps

Offer (guidance only — never auto-invoke), per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.
Five routes do not fit in four slots, so the prose carries all of them and the array carries `Stop
here` plus three — that reference's overflow rule:

```
An updated PRD can invalidate what was derived from it. Where this run can go next:
  • Re-run the spec         — /dev-workflows:specify <KEY> <merge-clause>    (PE, if one exists)
  • Re-run architecture     — /dev-workflows:create-ard <KEY> <merge-clause> (PA, if one exists)
  • Re-run epics            — /dev-workflows:epics <KEY>                     (PE)
  • Re-draft the release note — /dev-workflows:release-notes <KEY>           (PM)
```

```
choices: ["Re-run the spec — /dev-workflows:specify <KEY> (PE, if one exists) <merge-clause>", "Re-run architecture — /dev-workflows:create-ard <KEY> (PA, if one exists) <merge-clause>", "Re-run epics — /dev-workflows:epics <KEY> (PE)", "Stop here"]
```

**The release note is on the list and not in the array**, and the ordering is the reference's rule 3
rather than taste: an updated PRD invalidates what was *derived* from it — the spec, the ARD, the
Epics — before it changes what is *said about the release*, which is drafted last and from the
shipped diff rather than from the PRD. Say in one line that the list is longer than the options and
that the release-note route is reachable through the free-text option.

**One key appears in that array.** `<ADDRESS>` is what this run was invoked with; it resolves the `$SPECS_PATH` folder Phase 0 step 3 found, and every command offered below resolves that same folder through the same entry point. There is no second identity to keep straight and no import to wait for.

**Two options carry `<merge-clause>` and two do not, and which is which is derived, not stylistic.** `/dev-workflows:create-ard` and `/dev-workflows:specify` both gate this run's PRD on the specs repo's default branch, so both stop where the updated PRD reached a branch; where it reached none, `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3.4's rows for them apply unchanged — `/create-ard` falls back to the resolved folder, reported, and `/specify` skips the grounding confirmation rather than stopping; `/dev-workflows:epics` gates `<PRD-dir>/specification.md` and `/dev-workflows:release-notes` gates nothing, so neither waits on anything this run wrote. The placeholder is resolved from this run's own `Phase handoff:` outcome line (§4.1) per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` and is never written as an unconditional "once the pull request above is merged" — a declined handoff, a failed push and a nothing-to-commit run each leave a different wait, and two of them open no pull request to wait on. It is a placeholder, not an instruction to reword an option, so the array is still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 7), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then: continuing as PM → `/compact`; handing to PA/PE → `/clear`. Guidance only.

---

## Phase 7 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 6, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin/skill/command/reference gap, `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment/user halt (missing key, unset `$SPECS_PATH`, not-imported, cancellation) or a work-quality review BLOCK.

**Session-hygiene invariant.** End Phase 6 with a `### Context hygiene` block per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the `resume.md` write runs later, in the terminal cost phase, per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the guidance only), then a span suggestion (PM continue → `/compact`; PA/PE handoff → `/clear`). Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/update-prd`; what was updated (which sections changed + why); key events (import/freshness friction, BLOCK reviews, unresolved clarifications — or 'none'); workarounds; the `prd-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call `emit-auto` (§6) with the report, `command: /update-prd`, the run's `key`, `source`, and `plugin_version` (from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call `emit-cost` with `command: /update-prd`, `phase: prd-update`, `role: pm`, the run's `key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the report.
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/update-prd)` with no `Co-Authored-By` trailer, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches anything outside `$SPECS_PATH`; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is offered only in Phase 5; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the canonical PRD path + the archived snapshot path; which sections changed; the base `prd.md` the update was built from; open-question count; the `prd-reviewer` verdict; the prose style-check outcome; the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); the handoff reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and the next-step recommendations.

---
name: update-prd
description: PRD-update workflow (PM phase) — refresh/re-do an existing Product Requirements Document. Resolves the PRD from the specs tree (the only copy) with a 3-day freshness gate, grounds on the PRD + comments + any ARD/spec/transcript, updates it via a relentless grill against references/prd-format.md, gated by the Opus prd-reviewer, and writes canonical + archived revisions to $SPECS_PATH/specifications/<KEY>-<slug>/. Product-level (no code scan).
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

1. **`KEY` (mandatory).** Parse the first non-flag token and validate it with `key-valid` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1) — the grammar is that file's, cited rather than copied here. If absent or malformed, stop: `UPDATE_VI_NEEDS_KEY: /update-prd needs the PRD's key — '/dev-workflows:update-prd <KEY>'.` **The grammar is a superset of the two-segment form** — every key that validated before still validates, so a `PRODUCT-1234` refresh behaves exactly as it did — and it is the one this command needs for the same reason step 3's folder resolution is: a PRD authored inside a BRD slice by `/create-prd` on the BRD route carries a three-segment key (`EPIC-008-01`), and `/create-prd` **redirects here** on finding it. A validation narrower than `/create-prd`'s would refuse that redirect at the door, which is the identical dead-end step 3 exists to close, one step earlier.
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Feature folder.** Resolve it with `resolve-address <KEY>` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which searches every level §3 bounds and carries §5's legacy fallback; `status: absent` → the folder does not exist and this command has no PRD to update; `ambiguous` → stop, naming every match and `@<path>` as the way through. No matching rule is written here — §5 owns it.
4. **Resolve the base PRD.** It is the `prd.md` in the folder step 3 resolved — the only copy there is, and therefore authoritative without a test. Absent → stop with `UPDATE_PRD_NO_PRD: <ADDRESS> resolves a folder holding no prd.md — run '/dev-workflows:create-prd <ADDRESS>' to author one first.`

   **This used to be a ladder, and the ladder's premise is what went.** The authoritative PRD text lived in a tracker, so this step read an imported copy, stopped when none existed, and offered a refresh when one was more than three days old. There is one copy now and it is in the folder this run resolved: nothing to import, nothing to go stale, and no second copy to disagree with.
5. **Secondary grounding (read-only).** Discover in the feature folder: the folder's `prd.md`, any `ard.md`, `specification.md`; plus any `@transcript` / notes path(s) passed in `$ARGUMENTS`.

These reads are deliberately **not** gated: `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) is never executed by this command. `/update-prd`'s authoritative base is the resolved folder, and Phase 2 already rules that the import wins where a frozen draft disagrees. Gating advisory grounding would block a legitimate PRD refresh because an unrelated ARD sits on a branch. Where a discovered `ard.md` or `specification.md` is **not** on the specs repo's default branch, say so in the Phase 1 confirmation — the user should know the grounding is unapproved, not be stopped by it.

`/update-prd` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

---

## Phase 1 — Configure

Use `choices` arrays; the last choice is always `"Other… (describe)"`.

1. **Confirm** the feature folder; the resolved PRD base; and the secondary artifacts discovered (specs draft / ARD / spec / transcript).
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).
   - Report any discovered `ard.md` or `specification.md` that is not on the specs repo's default branch — per Phase 0 step 5, this grounding is unapproved but advisory-only; it is never a reason to stop the run.
2. **Scope of the update.** `choices: ["Refresh (incorporate new info / comments / transcript) (Recommended)", "Re-do (substantive re-scope driven by an ARD/spec obstacle)", "Cancel", "Other… (describe)"]`.

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record the `model_routing` block exactly as `/create-prd` does (`classification`, `reason`, `current_model`, `detection_model` §2.1 Sonnet chain, `review_model` §2 Opus chain for `prd-reviewer` (frontmatter-pinned), `authoring_model` = current_model, `opus_available`, `notes`). The grill + authoring run inline on `current_model`; if no Opus resolves, degrade to best-available + record in `notes`.

---

## Phase 2 — Read the base + grounding

Read the PRD **body** (the authoritative base and the signal for *what to change*), then the secondary artifacts (specs draft, ARD, spec, transcript). Do NOT treat the frozen specs draft as authoritative where it disagrees with the resolved folder — the import wins; surface a notable divergence to the user.

Then run `resolve-docs-grounding update-prd` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the PRD goal + the change signal from comments, `key` = `<KEY>`. Carry the digest into the Phase 3 grill with **grill-rank** consumption. When OFF, skip silently.

---

## Phase 3 — Update via grill

**Interview technique (grilling — embedded).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split, dependency order.

Update the PRD live against `${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, **diffing against the base** rather than authoring from blank: surface what changed and why (drawing on comments / ARD / spec / transcript), resolve open questions, keep the PRD product-level. Apply the **self-consistency check** — no `[AC#N]` delivering an Out-of-scope behaviour, no `## Goal` vs `## Scope` contradiction, no conflicting `[US#N]`; record a deliberately-kept tension under `## Assumptions & open questions`. Preserve the frontmatter provenance fields (`sources`, `derived_from`, `seeded_from_prd` if present) — **and, on a PRD that carries them, `brd_key`, `brd_parent` and `depends_on`**, copied through the refresh unchanged. Those three are BRD provenance `/create-prd` on the BRD route wrote from the BRD's own `brd-link.md` (`${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`), and this command reads no BRD tree, so a value it drops is one nothing later can restore. **No command consumes the three fields yet** — neither `/dev-workflows:epics` nor `/dev-workflows:ready` reads any of them, `brd_parent` and `depends_on` have no reader anywhere, and the only read of `brd_key` in the plugin is a *presence* test only. Nothing consumes the prerequisites they record. Preserving them is right regardless: provenance that survives an update is the precondition for any future consumer, and re-deriving it later would mean re-reading a BRD tree that may have moved on. Dropping them would silently make a slice's PRD look like an ordinary one, with nothing left to restore it from. Carrying an existing value forward is **preservation, not authoring** — this run mints none of the three, asks the PM for none of them, and writes none onto a PRD that arrived without them, so `prd-format.md`'s rule that they are written only by `/create-prd` on the BRD route holds unchanged. `key` is likewise carried, not re-derived: Phase 0 step 4 resolved the tracker identity from it, and under the `/create-prd` on the BRD route redirect it is the minted key and never the `<BRD-KEY>` this run was invoked with.

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
2. **Write the refreshed PRD** to the **canonical** path `<feature-folder>/prd.md`. Record `revision_of: <archived snapshot path>` and `built_from_import: <YYYY-MM-DD>` (the date the update was built from) in the frontmatter.
3. **Hand off** (commit-when-asked — never automatic). Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's consent choice verbatim: `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]`. On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: prd`; `feature_folder` as resolved in Phase 0; `deliverable_paths` = the canonical PRD file (step 2) and the archived snapshot file (step 1); `title: <KEY> Update Product Requirements Document`; and `body_facts` = which sections changed, the date the update was built from, the open-question count, and the `prd-reviewer` verdict. Emit its §4.1 outcome line in the Final report.

---

## Phase 6 — Next steps

Offer (guidance only — never auto-invoke), per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`:
```
choices: ["Re-draft the release note — /dev-workflows:release-notes <KEY> (PM)", "Re-run architecture — /dev-workflows:create-ard <KEY> (PA, if one exists) <merge-clause>", "Re-run epics — /dev-workflows:epics <KEY> (PE)", "Re-run the spec — /dev-workflows:specify <KEY> (PE, if one exists) <merge-clause>", "Stop here", "Other… (describe)"]
```

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
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/update-prd)` with no `Co-Authored-By` trailer, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is offered only in Phase 5; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the canonical PRD path + the archived snapshot path; which sections changed; the import date the update was built from; open-question count; the `prd-reviewer` verdict; the prose style-check outcome; the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); the handoff reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and the next-step recommendations.

---
name: update-vi
description: VI-update workflow (PM phase) — refresh/re-do an existing Value Increment. Resolves the VI Jira-import-first (source of truth) with a 3-day freshness gate, grounds on the VI + comments + any ARD/spec/transcript, updates it via a relentless grill against references/vi-format.md, gated by the Opus vi-reviewer, and writes canonical + archived revisions to $SPECS_PATH/specifications/<KEY>-<slug>/. Product-level (no code scan).
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Update the Value Increment for the Jira item: $ARGUMENTS

`/update-vi` refreshes an **existing** Value Increment (PM phase). It covers routine refreshes (new
information, scope tweaks, wording) and the rare obstacle-driven re-do (a human read an ARD/spec finding,
discussed it in Jira, and decided the VI must change). The VI is **product-level** — what / why /
for-whom, not how. Zero code scan; no repos.

Usage: `/update-vi <KEY> [@transcript-or-notes ...] [--no-docs]` (`--no-docs` turns off documentation grounding for the run — see Phase 1).

---

## Phase 0 — Resolve inputs

1. **`KEY` (mandatory).** Parse the first non-flag token; validate `^[A-Z][A-Z0-9_]*-\d+$`. If absent or malformed, stop: `UPDATE_VI_NEEDS_KEY: /update-vi needs the VI's Jira key — '/dev-workflows:update-vi <KEY>'.`
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Feature folder.** `<SPECS_PATH>/specifications/<KEY>-<slug>/` — honor an existing dir matched by key-number (tolerate a stray `-`/`_` and a human-adjusted slug).
4. **Resolve the base VI — Jira-import-first.** Execute `${CLAUDE_PLUGIN_ROOT}/references/vi-source-resolution.md` (`resolve-existing-vi <KEY>`): the re-imported `$VAULT_PATH/jira-products/<KEY>` VI (body + `-comments.md`) is the **authoritative base**; not imported → stop and ask to import; stale (>3 days) → offer re-import.
5. **Secondary grounding (read-only).** Discover in the feature folder: the frozen specs draft (glob `<KEY>_*.md`, `issue_type: ValueIncrement`), any `*_ARD.md`, `specification.md`; plus any `@transcript` / notes path(s) passed in `$ARGUMENTS`.

These reads are deliberately **not** gated: `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) is never executed by this command. `/update-vi`'s authoritative base is the Jira import, and Phase 2 already rules that the import wins where a frozen draft disagrees. Gating advisory grounding would block a legitimate VI refresh because an unrelated ARD sits on a branch. Where a discovered `*_ARD.md` or `specification.md` is **not** on the specs repo's default branch, say so in the Phase 1 confirmation — the user should know the grounding is unapproved, not be stopped by it.

`/update-vi` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

---

## Phase 1 — Configure

Use `choices` arrays; the last choice is always `"Other… (describe)"`.

1. **Confirm** the feature folder; the resolved Jira-import base **with its import date**; and the secondary artifacts discovered (specs draft / ARD / spec / transcript).
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).
   - Report any discovered `*_ARD.md` or `specification.md` that is not on the specs repo's default branch — per Phase 0 step 5, this grounding is unapproved but advisory-only; it is never a reason to stop the run.
2. **Scope of the update.** `choices: ["Refresh (incorporate new info / comments / transcript) (Recommended)", "Re-do (substantive re-scope driven by an ARD/spec obstacle)", "Cancel", "Other… (describe)"]`.

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record the `model_routing` block exactly as `/create-vi` does (`classification`, `reason`, `current_model`, `detection_model` §2.1 Sonnet chain, `review_model` §2 Opus chain for `vi-reviewer` (frontmatter-pinned), `authoring_model` = current_model, `opus_available`, `notes`). The grill + authoring run inline on `current_model`; if no Opus resolves, degrade to best-available + record in `notes`.

---

## Phase 2 — Read the base + grounding

Read the Jira-import VI **body + `-comments.md`** (the authoritative base and the signal for *what to change*), then the secondary artifacts (specs draft, ARD, spec, transcript). Do NOT treat the frozen specs draft as authoritative where it disagrees with the Jira import — the import wins; surface a notable divergence to the user.

Then run `resolve-docs-grounding update-vi` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the VI goal + the change signal from comments, `jira_key` = `<KEY>`. Carry the digest into the Phase 3 grill with **grill-rank** consumption. When OFF, skip silently.

---

## Phase 3 — Update via grill

**Interview technique (grilling — embedded).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split, dependency order.

Update the VI live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, **diffing against the base** rather than authoring from blank: surface what changed and why (drawing on comments / ARD / spec / transcript), resolve open questions, keep the VI product-level. Apply the **self-consistency check** — no `[AC#N]` delivering an Out-of-scope behaviour, no `## Goal` vs `## Scope` contradiction, no conflicting `[US#N]`; record a deliberately-kept tension under `## Assumptions & open questions`. Preserve the frontmatter provenance fields (`sources`, `derived_from`, `seeded_from_vi` if present).

---

## Phase 3.5 — Dynatrace style check

Run the corporate style check on the updated VI **before** the review gate (quality enhancement, never a gate) — mirror `/create-vi` Phase 3.5 (Agent `dt-style-guide:dt-style-checker`, `doc_type: vi`, `detection_model`); apply MAJOR fixes inline and re-run once; skip gracefully if the agent is unavailable.

---

## Phase 3.6 — Structural pre-lint

Run the deterministic checks in `${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` (Universal + **VI** block) against the updated file; inline-fix mechanical findings; leave content gaps for the grill. Advisory — never blocks; `vi-reviewer` remains the gate.

---

## Phase 4 — Review gate

Dispatch `vi-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:vi-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the Value Increment:
  >
  > VI path: [absolute path to the updated <KEY>_<slug>.md]
  > Profile: [lean | hybrid | full — infer from the sections present]"

Act on the verdict as `/create-vi` Phase 4 does: on `BLOCK`, fix the BLOCKER findings inline and re-review once; if still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. Cap: one fix cycle + one re-review.

---

## Phase 5 — Handoff (canonical + archive) + Jira round-trip

1. **Archive the current canonical VI** (if one exists) to `<feature-folder>/revisions/<KEY>_<slug>_<YYYYMMDD>.md` before overwrite (same-day second revision → suffix `-2`, `-3`, …).
2. **Write the refreshed VI** to the **canonical** path `<feature-folder>/<KEY>_<slug>.md`. Record `revision_of: <archived snapshot path>` and `built_from_import: <YYYY-MM-DD>` (the Jira-import date the update was built from) in the frontmatter.
3. **Hand off** (commit-when-asked — never automatic). Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's consent choice verbatim: `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]`. On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: vi`; `feature_folder` as resolved in Phase 0; `deliverable_paths` = the canonical VI file (step 2) and the archived snapshot file (step 1); `title: <KEY> Update Value Increment`; and `body_facts` = which sections changed, the Jira-import date the update was built from, the open-question count, and the `vi-reviewer` verdict. Emit its §4.1 outcome line in the Final report.

### Jira round-trip (document to the user — they will otherwise miss it)

1. **Paste** the updated VI body (below the frontmatter) back into the Jira workitem `<KEY>`.
2. **Re-import** the VI to `$VAULT_PATH/jira-products/<KEY>` (via `https://github.com/ivan-gudak/jira-workitem-import`) so the downstream pipeline and the next `/update-vi` see the current text.

Without these steps the update silently diverges from Jira again.

---

## Phase 6 — Next steps

Offer (guidance only — never auto-invoke), per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`:
```
choices: ["Re-draft the release note — /dev-workflows:release-notes <KEY> (PM)", "Re-run architecture — /dev-workflows:create-ard <KEY> (PA, if one exists)", "Re-run the spec — /dev-workflows:specify <KEY> (PE, if one exists)", "Stop here", "Other… (describe)"]
```

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 7), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then: continuing as PM → `/compact`; handing to PA/PE → `/clear`. Guidance only.

---

## Phase 7 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 6, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin/skill/command/reference gap, `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment/user halt (missing key, unset `$SPECS_PATH`, not-imported, cancellation) or a work-quality review BLOCK.

**Session-hygiene invariant.** End Phase 6 with a `### Context hygiene` block per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the `resume.md` write runs later, in the terminal cost phase, per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the guidance only), then a span suggestion (PM continue → `/compact`; PA/PE handoff → `/clear`). Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/update-vi`; what was updated (which sections changed + why); key events (import/freshness friction, BLOCK reviews, unresolved clarifications — or 'none'); workarounds; the `vi-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call `emit-auto` (§6) with the report, `command: /update-vi`, the run's `jira_key`, `source`, and `plugin_version` (from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call `emit-cost` with `command: /update-vi`, `phase: vi-update`, `role: pm`, the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<VI-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the report.
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/update-vi)` with no `Co-Authored-By` trailer, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is offered only in Phase 5; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the canonical VI path + the archived snapshot path; which sections changed; the Jira-import date the update was built from; open-question count; the `vi-reviewer` verdict; the Dynatrace style-check outcome; the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); the Jira round-trip reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and the next-step recommendations.

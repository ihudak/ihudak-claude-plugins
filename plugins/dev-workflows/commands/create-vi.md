---
name: create-vi
description: VI-creation workflow (PM phase, sub-project 2 of the VI-creation flow). Turns a refined idea.md + a user-supplied JIRA-KEY into a high-quality Value Increment document (spine + adapt-in profiles: --lean|--hybrid|--full), authored via a relentless grill against references/vi-format.md, gated by the Opus vi-reviewer, written to $SPECS_PATH/specifications/<KEY>-<slug>/ and published to Jira by paste + re-import. Product-level (no code scan). Offers /release-notes and /create-ard as next steps.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Author a Value Increment for the Jira item: $ARGUMENTS

`/create-vi` is **sub-project 2 of the VI-creation flow** (PM phase) — it consumes the `idea.md` from
`/idea` and a **user-supplied `JIRA-KEY`** (an empty Jira workitem the user created to get the ID) and
authors a high-quality **Value Increment** that feeds the downstream pipeline. The VI is **product-level**
(a PRD): what / why / for-whom, not how. Zero Jira API — the VI is authored as markdown in the specs
repo and published to Jira by paste + re-import.

Usage: `/create-vi <JIRA-KEY> [@idea.md] [--lean|--hybrid|--full]` (default `--hybrid`).

---

## Phase 0 — Resolve inputs

1. **`JIRA-KEY` (mandatory).** Parse the first non-flag token; validate `^[A-Z][A-Z0-9_]*-\d+$`. If absent or malformed, **stop gracefully**: `CREATE_VI_NEEDS_KEY: /create-vi needs a Jira key — create an empty Jira workitem first to get the ID, then re-run '/create-vi <KEY> @<idea.md>'.` (Format only — zero Jira API, so existence is not verified.)
2. **Profile.** `--lean | --hybrid | --full`; default `--hybrid`.
3. **Resolve `idea.md` (ladder — stop at first hit):**
   1. explicit `@path` argument;
   2. **same-session** — if `/idea` ran earlier in this session, use its recorded output path (confirm with the user);
   3. **discover** — `find "$VAULT_PATH/Projects" -type f -name idea.md` (recent first); if any, present a picker;
   4. prompt for a path, or — last resort — proceed with **no idea** and grill the VI from scratch.
4. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
5. **Feature folder.** `<SPECS_PATH>/specifications/<KEY>-<slug>/` — `<slug>` from the idea title (else a kebab of the VI summary). Honor an existing dir matched by key-number (tolerate a stray `-`/`_` and a human-adjusted slug). Auto-created by the first write (Phase 5).
6. **Prior VI.** If `<KEY>_ValueIncrement.md` exists in the folder, Phase 1 offers refine-vs-fresh.

`/create-vi` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

---

## Phase 1 — Configure

Use `choices` arrays; the last choice is always `"Other… (describe)"`.

1. **Confirm** the feature folder, the profile, and the resolved `idea.md` (or "none — grill from scratch").
2. **Refine vs fresh** (only if a prior `<KEY>_ValueIncrement.md` exists):
   ```
   choices: ["Refine the existing VI (Recommended)", "Start fresh — overwrite", "Cancel", "Other… (describe)"]
   ```
3. **Relocate `idea.md`.** If it is outside the feature folder, **copy/move** it to `<feature-folder>/idea.md` (**never a symlink** — a cross-root link between `$VAULT_PATH` and `$SPECS_PATH` would break). Record its original path for `derived_from`.
4. **Draft idea → warn-and-fold.** If `idea.md` is `status: draft` (open `[NEEDS CLARIFICATION]`), note that the grill resolves those items — do **not** hard-block.

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT for large/cross-cutting VIs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # impl-maintenance
  review_model:    <§2 Opus chain>     # vi-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + VI authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (the §2 Opus chain — interactive judgment, not a delegated subagent). If no Opus resolves, **degrade to best-available + record** in `notes` and the final report — do not hard-block.

---

## Phase 2 — Read the seed

Read the resolved `idea.md` **directly** (it is the plugin's own format — `idea-reader` is for arbitrary external sources and is not used here). Extract Problem / Who / desired outcome & value / rough scope / signals & evidence / candidate success signal, plus any open `[NEEDS CLARIFICATION]`. Carry the idea's `sources[]` forward to **propagate** into the VI frontmatter (the real provenance — RFE key / community-post URL / prompt), and record `derived_from` = the idea's original path.

Optionally ground in the idea's cited sources and any strategy/vision docs the user points to. **No code scan; no repos.**

If there is no idea (Phase 0 ladder exhausted), grill the VI from scratch.

---

## Phase 3 — Author via grill

**Interview technique (grilling — embedded; no runtime dependency).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the idea/sources; put only decisions to the user), walk the design tree in dependency order, continue to shared understanding then write each section.

Author `<KEY>_ValueIncrement.md` live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md` for the selected profile. Walk the **spine** in dependency order:

1. Frontmatter — incl. `release_versions` + `relevant_for_release_notes`, `sources` (propagated), `derived_from`, `jira_key`.
2. **Problem**
3. **Goal** (crisp 2–3 sentences)
4. **Target audience** (personas)
5. **User Stories** (`[US-N]`)
6. **Acceptance Criteria** (`[AC-N]` per story)
7. **Scope** (In / Out)
8. **Success Metrics** (`[SM-N]`)

Then author the profile's **adapt-in clusters**, each **pulled only when the idea warrants it** (never an empty section). Fold the idea's open `[NEEDS CLARIFICATION]` into the grill; resolve to zero where possible, leaving genuinely-unresolvable ones under `## Assumptions & open questions` (hybrid/full). Keep the VI **product-level** — no implementation detail.

---

## Phase 4 — Review gate

Dispatch `vi-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:vi-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the Value Increment:
  >
  > VI path: [absolute path to <KEY>_ValueIncrement.md]
  > Profile: [lean | hybrid | full]"

Act on the verdict (mirrors `/specify`):
- **`BLOCK`** — fix the BLOCKER findings inline (the orchestrator/grill edits the VI — no delegated writer) and re-review **once**. If still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER (`choices: ["Provide manual fix notes", "Defer to a follow-up issue", "Override and accept", "Cancel", "Other… (describe)"]`).
- **`PASS` / `PASS WITH RECOMMENDATIONS`** — proceed. Cap: one fix cycle + one re-review.

---

## Phase 5 — Handoff

Write the feature folder: `<KEY>_ValueIncrement.md` + the relocated `idea.md`. Then **offer** (commit-when-asked — never automatic):

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git", "Cancel"]
```

On the first choice, in the specs repo (`$SPECS_PATH`): create branch `vi/<KEY>-<slug>`; commit **only** the feature folder (never `git add -A`); push; open a PR targeting `main`. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

### Jira round-trip (document to the user — they will otherwise miss it)

1. **Paste** the VI body (below the frontmatter) into the Jira workitem `<KEY>`.
2. **Re-import** the VI to `$VAULT_PATH/jira-products/<KEY>` (via `https://github.com/ivan-gudak/jira-workitem-import`) so the downstream pipeline sees it.

Without these steps the pipeline cannot read the VI.

---

## Phase 6 — Next steps

Offer these — clearly labeling the role handoff:

```
choices: ["Draft the release note now — /release-notes <KEY> (PM) (Recommended)", "Hand to a Product Architect — /create-ard <KEY> (PA, optional)", "Hand to a Product Engineer — /epics <KEY> (PE)", "Stop here", "Other… (describe)"]
```

- **`/release-notes <KEY>`** (PM) — draft the customer-facing release note now (the cost model's `pm`/`vi-creation` inferred case: no spec/design yet).
- **`/create-ard <KEY>`** (PA, **optional**) — hand to a Product Architect to author the grounded architecture document.
- **`/epics <KEY>`** (PE) — hand to a Product Engineer to split the VI into Epics (or author a VI-level spec → `/specify <KEY>`).

Guidance only — never auto-invokes another command. Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.

---

## Phase 7 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 6, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (missing key, unset `$SPECS_PATH`, cancellation) or a work-quality review BLOCK.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-vi`; what was authored (VI + profile); key events (source-ladder friction, unresolved clarifications, BLOCK reviews — or 'none'); workarounds; the `vi-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the Lessons Learned report, `command: /create-vi`, the run's `jira_key`, `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-vi`, `phase: vi-creation`, `role: pm`, the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in Phase 5), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the VI path + profile; US/AC/SM counts + which adapt-in clusters were included; open-question count; the `vi-reviewer` verdict; the PR URL (if opened); the Jira round-trip reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; and the next-step recommendations.

---
name: create-vi
description: VI-creation workflow (PM phase, sub-project 2 of the VI-creation flow). Turns a refined idea.md + a user-supplied JIRA-KEY into a high-quality Value Increment document (spine + adapt-in profiles: --lean|--hybrid|--full), authored via a relentless grill against references/vi-format.md, gated by the Opus vi-reviewer, written to $SPECS_PATH/specifications/<KEY>-<slug>/ and published to Jira by paste + re-import. Product-level (no code scan). Offers /release-notes and /create-ard as next steps.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch LS
---

Author a Value Increment for the Jira item: $ARGUMENTS

`/create-vi` is **sub-project 2 of the VI-creation flow** (PM phase) — it consumes the `idea.md` from
`/idea` and a **user-supplied `JIRA-KEY`** (an empty Jira workitem the user created to get the ID) and
authors a high-quality **Value Increment** that feeds the downstream pipeline. The VI is **product-level**
(a PRD): what / why / for-whom, not how. Zero Jira API — the VI is authored as markdown in the specs
repo and published to Jira by paste + re-import.

Usage: `/create-vi <JIRA-KEY> [@idea.md] [--from-vi <VI-KEY|path>] [--lean|--hybrid|--full]` (default `--hybrid`).

---

## Phase 0 — Resolve inputs

1. **`JIRA-KEY` (mandatory).** Parse the first non-flag token; validate `^[A-Z][A-Z0-9_]*-\d+$`. If absent or malformed, **stop gracefully**: `CREATE_VI_NEEDS_KEY: /create-vi needs a Jira key — create an empty Jira workitem first to get the ID, then re-run '/create-vi <KEY> @<idea.md>'.` (Format only — zero Jira API, so existence is not verified.)
2. **Profile.** `--lean | --hybrid | --full`; default `--hybrid`.
2a. **`--from-vi <VI-KEY|path>` (optional seed).** When present, this run authors a **new** VI (the
    positional `<JIRA-KEY>`) seeded read-only by another VI. Resolve the seed via
    `${CLAUDE_PLUGIN_ROOT}/references/vi-source-resolution.md` (`resolve-existing-vi` — Jira-import-first,
    3-day freshness) for a key, or read the given path directly. The seed is **grounding, not content**
    (Phase 3 adapts it; it is never copied wholesale).
3. **Resolve `idea.md` (ladder — stop at first hit):**
   1. explicit `@path` argument;
   2. **same-session** — if `/idea` ran earlier in this session, use its recorded output path (confirm with the user);
   3. **discover** — `find "$VAULT_PATH/Projects" -type f -name idea.md` (recent first); if any, present a picker;
   4. prompt for a path, or — last resort — proceed with **no idea** and grill the VI from scratch.
4. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
5. **Feature folder.** `<SPECS_PATH>/specifications/<KEY>-<slug>/` — `<slug>` from the idea title (else a kebab of the VI summary). Honor an existing dir matched by key-number (tolerate a stray `-`/`_` and a human-adjusted slug). Auto-created by the first write (Phase 5).
6. **Prior VI (frontmatter-based).** Glob `<feature-folder>/<KEY>_*.md` and confirm frontmatter `issue_type: ValueIncrement` (tolerant of any slug). If a VI is found, this is an **existing VI** — `/create-vi` is greenfield-only, so **redirect** (see Phase 1) to `/update-vi <KEY>` unless `--from-vi` is present.

`/create-vi` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

---

## Phase 1 — Configure

Use `choices` arrays; the last choice is always `"Other… (describe)"`.

1. **Confirm** the feature folder, the profile, and the resolved `idea.md` (or "none — grill from scratch").
   - Show the `docs grounding: ON <root> | OFF (<reason>)` line (off switch: --no-docs).
2. **Existing-VI handling** (only if Phase 0 step 6 found a VI for `<KEY>`):
   - **No `--from-vi`** → `/create-vi` is greenfield-only; **redirect**:
     ```
     choices: ["Switch to /update-vi <KEY> to refresh it (Recommended)", "Overwrite as a fresh VI (archives the current one)", "Cancel", "Other… (describe)"]
     ```
   - **`--from-vi` present** → "create new (seeded)" conflicts with "a VI already exists here":
     ```
     choices: ["Update the existing <KEY> instead — /update-vi <KEY> (seed ignored) (Recommended)", "Overwrite <KEY> as a new seeded VI (archives the current one)", "Cancel", "Other… (describe)"]
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

**Profile nudge (complex VIs).** If `classification` is **SIGNIFICANT** (a
complex / cross-cutting VI) and the chosen profile is `--lean` or `--hybrid`
(so `FR-N` is unavailable — it is full-only), surface a one-line **non-blocking**
recommendation before Phase 2:
> "This VI classifies SIGNIFICANT — consider `--full` so Functional Requirements
> (`FR-N`) and richer Use Cases (`UC-N`) are available for stronger, more
> traceable downstream Epic coverage."

Offer `choices: ["Switch to --full", "Keep <profile>", "Other… (describe)"]`. On
"Keep", proceed unchanged. For a SIMPLE / MODERATE classification, or when the
profile is already `--full`, this nudge does **not** fire.

---

## Phase 2 — Read the seed

Read the resolved `idea.md` **directly** (it is the plugin's own format — `idea-reader` is for arbitrary external sources and is not used here). Extract Problem / Who / desired outcome & value / rough scope / signals & evidence / candidate success signal, plus any open `[NEEDS CLARIFICATION]`. Carry the idea's `sources[]` forward to **propagate** into the VI frontmatter (the real provenance — RFE key / community-post URL / prompt), and record `derived_from` = the idea's original path.

Optionally ground in the idea's cited sources and any strategy/vision docs the user points to. **No code scan; no repos.**

If `--from-vi` was resolved (Phase 0 step 2a), also read the **seed VI** (body + comments) as read-only
grounding — structure, personas, scope shape, and metrics to *adapt* (never copy) to the new VI.

If there is no idea (Phase 0 ladder exhausted), grill the VI from scratch.

---

## Phase 2.5 — Documentation grounding (optional)

Run `resolve-docs-grounding create-vi` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the idea's problem/goal + VI themes, `jira_key` = `<KEY>`, and `themes` from the idea. Carry the returned digest into Phase 3 with **grill-rank** consumption. When OFF, skip silently — the VI is authored exactly as today.

---

## Phase 3 — Author via grill

**Interview technique (grilling — embedded; no runtime dependency).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the idea/sources; put only decisions to the user), walk the design tree in dependency order, continue to shared understanding then write each section.

Author `<KEY>_<slug>.md` live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md` for the selected profile. Walk the **spine** in dependency order:

1. Frontmatter — incl. `release_versions` + `relevant_for_release_notes`, and (when `relevant_for_release_notes: yes`) the optional `change_type` (one of `Breaking change` / `New technology support` / `Bug fix` / `not applicable`) + `release_notes_category` (the Dynatrace Solution); `sources` (propagated), `derived_from`, `seeded_from_vi` (only when `--from-vi` was used), `jira_key`. Ask for `change_type` / `release_notes_category` only when the note is release-notes-relevant; leave them out otherwise (dates/deprecation stay out of frontmatter — they belong in the release-notes Summary).
2. **Problem**
3. **Goal** (crisp 2–3 sentences)
4. **Target audience** (personas)
5. **User Stories** (`[US-N]`)
6. **Acceptance Criteria** (`[AC-N]` per story)
7. **Scope** (In / Out)
8. **Success Metrics** (`[SM-N]`)

Then author the profile's **adapt-in clusters**, each **pulled only when the idea warrants it** (never an empty section). **For a complex VI (`classification` SIGNIFICANT), actively author the `FR-N` (full) and `UC-N` (hybrid/full) clusters** within the chosen profile — lower the bar for pulling them in, because ID'd functional requirements and use cases feed a finer downstream `/epics` `_coverage.md` (traceability to `FR-N`/`UC-N`, not only `US`/`AC`/`SM`); still never an empty section. Fold the idea's open `[NEEDS CLARIFICATION]` into the grill; resolve to zero where possible, leaving genuinely-unresolvable ones under `## Assumptions & open questions` (hybrid/full). Keep the VI **product-level** — no implementation detail. **Self-consistency check:** before writing each section, check it against the already-settled sections — a new `[AC-N]` must not deliver an Out-of-scope behaviour, the `## Goal` must not assert a scope the `## Scope` contradicts, and `[US-N]`s must not conflict. Resolve any contradiction inline with the user, or record it under `## Assumptions & open questions` — never leave it implicit (the Opus `vi-reviewer` flags a silently-baked contradiction).

---

## Phase 3.5 — Dynatrace style check

Run a corporate style check on the authored VI **before** the review gate. This
is a **quality enhancement, not a gate** — it never blocks the handoff.
`vi-reviewer` (Phase 4) judges content; style / terminology is checked here
(mirrors `/epics` Phase 6.2).

→ Agent (subagent_type: "dt-style-guide:dt-style-checker", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > files:    [absolute path to <KEY>_<slug>.md]
  > doc_type: vi
  > emphasis: terminology and customer-facing captions, labels, messages, and text"

Act on the return:
- **`OK`** — proceed to Phase 4.
- **`VIOLATIONS_FOUND`** — the orchestrator/grill applies the **MAJOR** fixes
  **inline** (no delegated writer — consistent with Phase 4's inline-fix model),
  then re-runs `dt-style-checker` **once**. Remaining MINOR/NIT are recorded in
  the final report.
- **`ERROR`** — surface the reason and proceed to Phase 4 (non-gating).

If `dt-style-checker` is unavailable (agent not found — the `dt-style-guide`
plugin is not installed), **skip this phase gracefully** and note
`SKIPPED (dt-style-checker unavailable)` in the final report.

---

## Phase 3.6 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `<KEY>_<slug>.md`: the
**Universal checks** plus the **VI** block. Surface every finding; inline-fix the mechanical ones
(renumber a duplicate `[US-N]`/`[AC-N]`/`[SM-N]`, delete a stray placeholder token); leave content gaps
(missing section, unresolved `[NEEDS CLARIFICATION]`) for the grill/author. **Advisory** — never blocks;
proceed to Phase 4 once findings are surfaced. `vi-reviewer` remains the gate.

## Phase 4 — Review gate

Dispatch `vi-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:vi-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the Value Increment:
  >
  > VI path: [absolute path to <KEY>_<slug>.md]
  > Profile: [lean | hybrid | full]"

Act on the verdict (mirrors `/specify`):
- **`BLOCK`** — fix the BLOCKER findings inline (the orchestrator/grill edits the VI — no delegated writer) and re-review **once**. If still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER (`choices: ["Provide manual fix notes", "Defer to a follow-up issue", "Override and accept", "Cancel", "Other… (describe)"]`).
- **`PASS` / `PASS WITH RECOMMENDATIONS`** — proceed. Cap: one fix cycle + one re-review.

---

## Phase 5 — Handoff

Write the feature folder: `<KEY>_<slug>.md` + the relocated `idea.md`. Then **offer** (commit-when-asked — never automatic):

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

### Context hygiene

Write/overwrite the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per
`session-hygiene.md` §1; the VI-Key is minted by the Jira round-trip, so **omit the
session-name line** and name the session manually if useful). Then:

- **Continuing as PM (`/release-notes <VI>` after the round-trip)?** → run **`/compact`**.
- **Handing to PA (`/create-ard <VI>`) or PE (`/epics <VI>`), even yourself?** → run **`/clear`** for a clean slate.

Guidance only — nothing is auto-run. See `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 7 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 6, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (missing key, unset `$SPECS_PATH`, cancellation) or a work-quality review BLOCK.

**Session-hygiene invariant.** End Phase 6 with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (write `resume.md`),
then a span suggestion (PM continue → `/compact`; PA/PE handoff → `/clear`). No `/rename`
label yet (no VI-Key). Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-vi`; what was authored (VI + profile); key events (source-ladder friction, unresolved clarifications, BLOCK reviews — or 'none'); workarounds; the `vi-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the Lessons Learned report, `command: /create-vi`, the run's `jira_key`, `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-vi`, `phase: vi-creation`, `role: pm`, the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in Phase 5), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the VI path + profile; US/AC/SM counts + which adapt-in clusters were included; open-question count; the `vi-reviewer` verdict; the Dynatrace style-check outcome (`OK` | `N fixed, M remaining` | `SKIPPED`); the PR URL (if opened); the Jira round-trip reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; and the next-step recommendations.

---
name: idea
description: Idea-refinement workflow (PM phase, front of the VI-creation flow). Takes one source — an inline prompt, a markdown file (with wikilinks/images), a community post, or an exported RFE Jira ticket — and, through a bounded one-question-at-a-time grill (--deep for relentless), authors a well-refined idea.md: a lean one-page brief that seeds the future /create-vi. Writes to the vault (keyless); no Jira, no code, no specs write.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch LS
---

Refine an idea into `idea.md`: $ARGUMENTS

`/idea` is the **front door of the VI-creation flow** (PM phase) — upstream of `/create-vi` (future) and
the existing pipeline. It ingests one source, refines it through a grill, and writes a lean one-page
`idea.md` (per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`) that seeds the Value Increment. It is
**not** a VI: no Jira write, no code change, no specs-repo write. Output lands keyless in the vault;
`/create-vi` relocates it under `$SPECS_PATH` once a Jira key exists.

Flag: `--deep` switches the grill from bounded (≤5 questions) to relentless (until convergence).

---

## Phase 0 — Validate environment + resolve model routing

1. **Validate `$VAULT_PATH`.** It must be **set**, an **existing directory**, and **writable** — the
   env var is the user's explicit declaration of their personal store; the plugin trusts it and does
   NOT require an Obsidian `.obsidian/` marker. If any check fails, STOP and offer:
   ```
   choices: ["Enter a directory to write idea.md into", "Cancel", "Other… (describe)"]
   ```
   On a user-supplied directory, validate it exists and is writable, then use it as the **write root**
   for this run. **NEVER** write into the current working directory (it may be a code repo). This is an
   environment halt, **not** a plugin-gap halt — do NOT `emit-block`.

2. **Resolve model routing.** Invoke the `model-routing` skill (Skill tool,
   `skill: "dev-workflows:model-routing"`), then record:
   ```yaml
   model_routing:
     classification: MODERATE          # idea refinement is typically MODERATE
     reason: <one-line>
     current_model: <the model this orchestrator/grill is running under>
     detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # idea-reader
     authoring_model: <= current_model>   # the interactive grill + idea.md authoring (session model, not a delegated subagent)
     opus_available: <true if a §2 Opus model resolved, else false>
     notes: <any §2/§2.1 fallback or degradation>
   ```
   The grill + authoring run inline on `current_model` (the §2 Opus chain — interactive judgment, not a
   delegated subagent). `idea-reader` runs on `detection_model`. If no Opus resolves, **degrade to the
   best available and record the degradation** in `notes` and the final report — do NOT hard-block (a PM
   must not be blocked from capturing an idea by a momentary Opus outage).

---

## Phase 1 — Classify the source

Classify `$ARGUMENTS` (minus the `--deep` flag) by precedence:

1. Matches the Jira-key regex `^[A-Z][A-Z0-9_]*-\d+$` → **rfe** (an exported Product-Enhancement ticket
   under `$VAULT_PATH/jira-products/<KEY>/`).
2. An existing `.md` path or an `@wikilink` → **markdown** (a community post is just a markdown file,
   typically under `Projects/Products/…` — the reader tags it `community-post`; an existing `idea.md`
   passed back for re-refinement is detected here too).
3. Otherwise → **prompt** (the argument text is the raw idea).

Surface a one-line confirmation before ingesting:
```
choices: ["Read this as <detected-type> (Recommended)", "It's actually a <other-type>", "Cancel", "Other… (describe)"]
```
(A dedicated `--as prompt|file|rfe` override is future work — the confirmation covers a mis-detection.)

---

## Phase 2 — Ingest the source (idea-reader)

Dispatch `idea-reader` to read the source and return a structured digest:

→ Agent (subagent_type: "dev-workflows:idea-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Ingest this idea source and return the structured digest:
  >
  > argument:        [the resolved argument]
  > provenance_hint: [prompt | markdown | community-post | rfe from Phase 1]
  > vault_path:      [resolved $VAULT_PATH]"

Wait for the digest. If `status: NOT_FOUND` (invalid RFE key / missing file), surface:
```
choices: ["Re-enter the source", "Cancel", "Other… (describe)"]
```
This is an environment/user halt — do NOT `emit-block`. On `OK`, carry forward `raw_context`,
`signals`, `images`, `candidate_title`, `candidate_slug`, `source_refs`, `provenance`, and the
followed/broken wikilinks — `source_refs`/`provenance` feed the `sources:` frontmatter entry in Phase 4.

---

## Phase 3 — Refine via grill

**Interview technique (grilling — embedded; no runtime dependency).** Follow the shared technique in `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the `idea-reader` digest / vault, put only decisions to the user), walk the design tree in dependency order. **Depth: bounded by default (below); `--deep` = relentless.**

Scan for gaps against an idea-stage **ambiguity taxonomy**: *problem clarity, target users, desired
outcome/value, scope boundaries, evidence/demand sufficiency, success signal, terminology.* Rank gaps
by **Impact × Uncertainty**.

- **Default (bounded):** ask **≤5** questions across the ranked gaps, then stop. Remaining high-impact
  gaps become `- [NEEDS CLARIFICATION: <question>]` in the `idea.md` **Open questions & assumptions**
  section, **capped at 3**; reasonable defaults are recorded as `- **Assumption:** <text>`.
- **`--deep`:** relentless — keep walking the design tree one question at a time until you and the user
  reach shared understanding; the cap does not apply.

---

## Phase 4 — Write idea.md

Author `idea.md` per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` into the write root resolved in
Phase 0:

- **Path:** `<write-root>/Projects/<area>/<candidate_slug>/idea.md`, where `<area>` = `Products` when
  the source already lives under `Projects/Products/…`, else `ideas`.
- **Existing file:** if `idea.md` already exists at that path, offer:
  ```
  choices: ["Refine the existing idea.md (Recommended)", "Create a new one (you'll be prompted for a slug)", "Cancel", "Other… (describe)"]
  ```
  On *refine*, re-open it, resolve its open `[NEEDS CLARIFICATION]` items, and append the new source
  (`{provenance, ref}` built from Phase 2's `provenance` and `source_refs`) to `sources`.
- **`status`:** set frontmatter `status: refined` IFF zero `[NEEDS CLARIFICATION]` markers remain;
  otherwise `status: draft`.

---

## Phase 5 — Handoff: adaptive next-phase offer

Report where `idea.md` was written and its `status`, then offer the next phase — **adapted to status**:

- **`refined`:** *"Idea refined. Next: create the VI — first create an empty Jira workitem, then run
  `/create-vi <JIRA-KEY> @<idea.md path>`."*
- **`draft`** (N open clarifications): *"This idea has N open clarification(s). You can (a) run
  `/idea @<idea.md path> --deep` to resolve them, or (b) proceed to `/create-vi <JIRA-KEY> @<idea.md
  path>`, which will grill you on the rest."*

`/create-vi` is a separate command; this offer is guidance the user acts on — it never auto-invokes
another command. (Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — the plugin-wide
next-phase-offer contract; `/idea` is one reference implementation.)

### Context hygiene

Continuing to `/create-vi` (still the PM phase)? → run **`/compact`** to free context; your
`idea.md` is already on disk. (No resume pointer or `/rename` label here — the VI-Key is
minted later, and the ideation phase is short.) Guidance only — see
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 6 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 5, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference
gap** (a capability the run needed but the plugin lacked), `emit-block` (per
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating — so a run
abandoned at the block still records the gap. NEVER `emit-block` for an environment / user halt (bad
`$VAULT_PATH`, source-not-found, cancellation).

**Session-hygiene invariant.** End Phase 5 with a `### Context hygiene` note per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — a same-role `/compact` suggestion
(no `resume.md`, no `/rename`: pre-VI, short PM phase). Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /idea
   > - What was done: [one-paragraph summary of the idea refined + source type]
   > - Key events: [source-detection corrections, unresolved clarifications, broken wikilinks — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: N/A (no reviewer in /idea)
   > - Test result: N/A (no tests in /idea)
   > - Project root: [the idea.md folder]"
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /idea`, `jira_key: null`, the run's `source`, and
   `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It renders only the
   plugin-facing slice (§4), dedupes by stable `id` (§3), resolves the target via the §2 specs-first
   ladder, and writes silently. Surface the persisted path (or "no plugin-facing signal — nothing
   persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its
   `emit-cost` entry point with `command: /idea`, `phase: vi-creation`, `role: pm`, `jira_key: null`,
   the run's `source`, and `plugin_version`. A keyless run writes to the pending ladder (§9) and
   **advances the chained checkpoint** (§3); surface the persisted path (or the report-only notice).

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into a code/docs repo or the
current working directory; no user name is ever written.

---

## Final report

Report: the `idea.md` path + `status` (refined / draft with N open clarifications); the source type and
`sources`; the count of `[NEEDS CLARIFICATION]` items and Assumptions; any source-detection correction
or broken wikilinks; the resolved model routing (+ any Opus degradation); the feedback path; the cost
path (or notice); and the adaptive next-phase recommendation.

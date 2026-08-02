# `/specify` — PM Specification Brainstorm (design)

**Date:** 2026-07-07
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Effort:** net-new command (brainstorm-from-Jira, PM phase). First of a two-command PM→Dev pipeline.
**Spec/plan home:** this vault (`Projects/AI-First/dev-workflows - docs automation/{spec,plan}/`).

## Context & motivation

The `dev-workflows` plugin has Jira-driven commands (`/implement`, `/document`, `/epics`,
`/release-notes`) but no **brainstorming** front-end — nothing that turns a Jira feature into a
reviewed specification through a real interview.

Separately, `$SPECS_PATH` (`/workspace/specs`, the git repo `mgd-specifications`) already hosts an
org **specification system**: `create-specification` drafts `problem statement → scope → user stories
→ acceptance criteria → test cases → HTML`, with a `review-specification` gate, a
`specification-to-html` renderer, and change-management. Its one weakness is its only interaction
model: **draft single-pass → stop at open questions → human resolves → continue.** It never
interviews, and it is blind to Jira and to code.

`/specify` fills exactly that gap: a **Jira- and code-grounded grilling command** that authors the
org-standard specification through a relentless one-question-at-a-time interview, resolving the open
questions live instead of stopping, and lands the result on the specs repo's **main** branch for the
development team to pick up.

### The two-command pipeline (PM → Dev)

`/specify` is phase 1 of a deliberate ownership split:

- **`/specify`** (this effort, PM phase) → `specification.md` (problem/scope/stories/AC/TC). Committed
  to the specs repo's main branch via branch+PR. The **handoff**.
- **`/design`** (future effort, Dev take-over) → reads the merged spec from main + full code, runs a
  grill that *challenges* the spec and *designs* the implementation → `design.md` + `plan.md`; depth
  scaled by the complexity classifier. Feeds `/implement`.

Rationale for the split: development teams own the consequences of the code (bugs, incidents, on-call),
so the **engineering-facing** artifacts must be produced by the dev phase — not thrown over the wall by
the PM's AI. `/specify` therefore produces the specification only; it never produces `design.md` or a
dev-plan.

## Goal

Given a Jira Epic (or VI) key or an imported-Jira directory, produce a **reviewed
`specification.md`** in the org format, grounded in Jira + light code, authored via a
one-question-at-a-time grill, and landed on the specs repo's **main** branch (via branch + PR) as
`Published: no` — discoverable by the development team once merged.

## Non-goals / out of scope (this effort)

- The `/design` dev take-over (its own brainstorm→spec→plan cycle).
- Epic splitting — that stays in `/epics`.
- `design.md` / dev-plan / `plan.md`.
- VI fan-out (one specification per invocation).
- Any **runtime** dependency on the specs repo's `.claude` agents/skills.
- Direct free-text ("direct mode") input — `/specify` is Jira-driven only.

## Decisions (locked during brainstorming)

| Area                   | Decision                                                                                                                                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Command name           | `/specify` (PM). Pairs with future `/design` (dev).                                                                                                                                                                                                                 |
| Input                  | Jira-driven only; reuses the shared `jira-input-resolution` front-end (JiraID \| imported-Jira dir). Rejects `mode: direct`.                                                                                                                                        |
| Scope                  | One specification per invocation, scoped to the passed key (typically an Epic; a VI yields one broad spec). No fan-out.                                                                                                                                             |
| Output                 | `specification.md` + rendered HTML only. No plan.                                                                                                                                                                                                                   |
| Authoring              | **Own it in the plugin** (Option 3): embed the spec format + stage rules + reviewer + HTML renderer into dev-workflows; the grill authors `specification.md` directly. No runtime dependency on the specs repo's `.claude`.                                         |
| Interview              | grilling primitive: one question at a time, a recommended answer for each, explore the code to self-answer where possible; walk the specification **stages** as the design tree.                                                                                    |
| Durability             | live `_session.md` (decisions + open questions + required-repos + stage progress) and `_glossary.md` (genuinely ambiguous terms only). Resumable across remount re-runs.                                                                                            |
| Code grounding         | **light** (feasibility sanity only). Auto-derive candidate repos; empty → ask; ambiguous → ask. Light `code-scanner` scan of mounted candidates.                                                                                                                    |
| Repo gate (timing)     | **during, early** — after the Jira read + repo derivation, before the deep grill; re-fires if a gap surfaces mid-grill.                                                                                                                                             |
| Repo gate (strictness) | **soft advisory** for the PM phase — an unmounted repo becomes a feasibility `- [ ]` open question; the command reports it and proceeds. (The strict "whole-feature" gate belongs to `/design`.)                                                                    |
| Open questions         | grill resolves to zero where possible (grounded in Jira+code); genuinely unresolvable items remain as `- [ ]` in the spec and are surfaced in the final report.                                                                                                     |
| Handoff                | land on the specs repo's **main** via **branch + PR** (main is protected — a PR is required). Merged-to-main = ready for dev handover. `Published: no` on landing; the human flips `Published: yes` to freeze. Devs (and `/design`) read from main, never a branch. |
| Model routing          | per the model-routing SSOT: `jira-reader`/`code-scanner` → Sonnet (detection); the interactive grill + authoring → session model (judgment); `spec-reviewer` → Opus (pinned gate).                                                                                  |

## Command surface

```
/specify <JiraID | @imported-jira-dir>
```

- Jira-driven only (like `/epics`). Reuses `references/jira-input-resolution.md` Phase 0 verbatim.
- Consumes `{mode, source, jira_key, jira_export_root}`; rejects `mode: direct` with a clear error.

## Architecture / components

**New assets (built in this effort):**

- `commands/specify.md` — the orchestrator (all phases below).
- `references/specification-format.md` — an **imported snapshot** of the org spec format: the
  `specification-template.md` structure + the condensed drafting/validation rules of the five stages
  (problem statement, scope, user stories, acceptance criteria, test cases), plus the ID conventions
  (`[Uxx]`/`[ACxx]`/`[TCxx]`) and header fields. Carries a provenance note: *source =
  `mgd-specifications` `.claude/skills/specification-*`, snapshot date, manual re-sync only.* The grill
  follows this file — never the specs repo's `.claude` at runtime.
- `agents/spec-reviewer.md` — imported/adapted from the specs repo's `review-specification`; the
  Opus-pinned quality gate. Returns a findings report in the doc-reviewer schema so a fix loop can act
  on it.
- Import the `specification-to-html` Python script into the plugin — HTML rendering is a Phase 6 step
  (the `.md` remains the primary artifact; the `.html` is the rendered review).

**Reused (existing) assets:**

- `references/jira-input-resolution.md` (Phase 0 front-end).
- `agents/jira-reader.md` (Jira hierarchy read).
- `agents/code-scanner.md` (light capability scan; parallel, ≤4 concurrent).
- `references/model-routing/classification.md` (routing).
- `references/escalation-rules.md` (repo-unresolved / repo-missing prompts).

**Embedded technique (not a runtime dependency):** the **grilling** interview method — one question at
a time, a recommended answer for each, explore-code-to-self-answer, walk the design tree resolving
dependencies — is embedded inline in `commands/specify.md`. Grilling is not installed as a plugin here,
and the technique is tiny, so we own it rather than depend on it.

**Durable artifacts (written into the feature folder during a run):**

- `_session.md` — live decision log: settled decisions, still-open questions, the required/derived
  repos list + mounted status, and stage progress. The resume anchor.
- `_glossary.md` — canonical terms, captured only when a term is genuinely ambiguous.

## Dependencies & provenance

- **No hard runtime plugin dependencies.** `/specify` runs standalone: it embeds the grilling technique
  and the specification format, produces `specification.md` (not a superpowers artifact), and invokes no
  external skill at runtime.
- **Dev-time only:** superpowers (brainstorming → writing-plans → subagent-driven-development) is used
  to design and build the command, not at runtime.
- **Provenance / attribution:** grilling technique adapted from mattpocock `grill-me`/`grilling`; the
  specification format, `spec-reviewer`, and `specification-to-html` are one-time snapshots imported
  from `mgd-specifications` (manual re-sync only).

## Workflow: `/epics` → `/specify` (the Jira round-trip — document to users)

The end-to-end PM flow, and the step users most easily miss, must be documented in the command help and
surfaced in the Phase 2.5 guidance and the final report:

1. `/epics <VI>` drafts child Epic definitions (markdown).
2. **The user creates those Epics in Jira** (manual — `/specify`/`/epics` do not call Jira).
3. **The user re-imports** the VI to `$VAULT_PATH/jira-products/<KEY>` so the new Epics appear in the
   export.
4. `/specify <each Epic>` reads the Epic from the refreshed export and authors its `specification.md`.

Steps 2–3 are the round-trip; without them `/specify` cannot see the Epics.

## Phase flow

- **Phase 0 — Resolve input.** Run `jira-input-resolution` (jira-driven only; reject direct). Resolve
  the feature folder `$SPECS_PATH/specifications/<KEY>_<slug>/` (honor an existing folder if present;
  tolerate `-`/`_` after the key). If a `_session.md` exists there → offer **resume** (read it back,
  skip settled stages/questions) vs **fresh**.
- **Phase 1 — Config (light).** Confirm output folder; repo-refresh policy (default: fetch + pull
  default branch, matching `code-scanner`); resume-vs-fresh.
- **Phase 1.5 — Classify.** Load model routing; record `detection_model` / session model / gate model.
- **Phase 2 — Read Jira.** `jira-reader` at **`depth: full`** (the passed item + its full linked
  subtree — Stories/Sub-tasks included, which become the user stories / acceptance criteria / test
  cases; `vi-plus-epics` is too shallow for a spec). Extract capability themes and component/product
  mentions. Seed `idea.md` from the Jira text (provenance + matches the specs-system convention).
- **Phase 2.5 — Granularity pre-flight.** From the `jira-reader` output, determine the input item's
  type (VI vs Epic) and whether it has child Epics:
  - **Epic input** → proceed (the sweet spot).
  - **VI input *with* Epics** → inform the user that specs are authored per Epic; list the child Epics.
    Offer: run `/specify` per Epic (recommended) / author one broad VI-level spec / cancel.
  - **VI input *without* Epics** → **flag it** and offer: (a) split into Epics first — run `/epics`,
    then **create those Epics in Jira and re-import** the VI to `$VAULT_PATH/jira-products/<KEY>`, then
    `/specify` per Epic; (b) author one broad VI-level spec now; (c) cancel. `/specify` does not create
    Jira Epics itself (zero external API) — it guides the user through the manual round-trip.
- **Phase 3 — Derive repos + soft gate.** Auto-derive candidate repos from themes + any linked PR
  URLs; **empty → ask**, **ambiguous → ask**. Build the slug→clone map (`/epics`-style `git remote`
  match). Cross-check mounted status; **unmounted → record a feasibility `- [ ]` open question, report
  it, and proceed** (soft gate).
- **Phase 4 — Light code scan.** `code-scanner` (batches ≤4 concurrent) on the mounted candidates →
  "does this exist / where / gaps" grounding for the grill's feasibility questions.
- **Phase 5 — The grill.** Walk the stage tree **problem → scope → user stories → acceptance criteria
  → test cases**. One question at a time, each with a recommended answer; explore the scanned code to
  self-answer where possible (don't ask what the code settles). Write each section to
  `specification.md` live, following `references/specification-format.md`. Append settled decisions to
  `_session.md` and ambiguous terms to `_glossary.md` as they resolve. Resolve open questions to zero
  where possible; leave genuinely unresolvable ones as `- [ ]`. A repo gap that surfaces here →
  escalate (describe the missing capability and why it's needed — cannot name/link an unmounted repo)
  → stop; the run is resumable after the user remounts and re-invokes.
- **Phase 6 — Finalize + review gate.** Render HTML via the imported `specification-to-html` script. Run `spec-reviewer`
  (Opus). Act on the verdict with a fix loop (mirrors `/epics`/`/document`): BLOCKER/MAJOR findings
  fixed and re-reviewed; MINOR/NIT deferred to the final report and/or captured as `- [ ]` refinement
  notes. The gate is a quality enhancement, not a hard blocker.
- **Phase 7 — Handoff.** Write the feature folder with `specification.md` (`Published: no`), `idea.md`,
  `_session.md`, `_glossary.md` (+ HTML). Then **offer** (commit-when-asked): create a branch
  (`spec/<KEY>_<slug>` by default), commit the folder, push, and **open a PR targeting main**.
  Merged-to-main = ready for the dev-team handover; devs and `/design` read the spec from main.
  Decline → files written; the user handles git. Emit a final report (folder path, stage/AC/TC counts,
  open-question count, unmounted-repo advisories, review verdict, PR URL if opened).

## Durability & resume mechanics

- `_session.md` records: settled decisions (by stage), still-open `- [ ]` questions, the
  derived-repos list with mounted status, and which stage the grill reached.
- On re-invocation with an existing `_session.md`, the command reads it back, skips settled
  stages/questions, and resumes at the first unsettled stage.
- **Remount loop:** when a needed repo is unmounted, the command describes the missing capability and
  why it matters (it cannot name or link a repo it can't see), the user restarts the container to mount
  it, and re-runs `/specify` — the run resumes from `_session.md` rather than re-interviewing.

## Model routing (per SSOT)

- `jira-reader`, `code-scanner` → §2.1 Sonnet detection chain.
- Interactive grill + `specification.md` authoring → the **session model** (judgment/interactive; no
  delegated subagent).
- `spec-reviewer` → §2 Opus chain, pinned (frontmatter), no caller override — consistent with the
  other Opus-pinned reviewers (`code-review`, `doc-reviewer`, `epic-reviewer`).

## Verification (no test framework — structural, per plugin convention)

- `commands/specify.md` parses; cites `jira-input-resolution`, `specification-format`,
  `model-routing`, `escalation-rules`; phase anchors present.
- `agents/spec-reviewer.md` frontmatter valid; Opus pin present; not caller-overridable.
- `references/specification-format.md` present with the five stages, ID conventions, header fields,
  and the provenance note.
- Manifests (`plugin.json`, `marketplace.json`) valid JSON; version bumped in lock-step; siblings
  untouched; CHANGELOG entry prepended.
- README/command-list surface updated to include `/specify`.
- Phase 2.5 granularity pre-flight present (VI-vs-Epic detection; VI-without-Epics offer); the Jira
  round-trip (create Epics in Jira → re-import) is documented in the command help and the final report.

## Resolved during review

- **Branch name** → default `spec/<KEY>_<slug>` (not user-hardcoded).
- **HTML** → import `specification-to-html`; HTML render is a Phase 6 step.
- **`jira-reader` depth** → `depth: full` (a spec needs Story/Sub-task detail for user stories / AC /
  test cases).
- **`Published` flag** → `/specify` always writes `Published: no`; only a human flips `Published: yes`
  (the freeze into an engineering contract). Merged-to-main = ready for pickup; `yes` = frozen.

## Confirmed (this review round)

- **Runtime dependencies** → **embed + attribute** (confirmed). Grilling technique embedded inline;
  provenance attributed; superpowers is dev-time-only. `/specify` has no hard runtime plugin
  dependencies. (See *Dependencies & provenance*.)
- **`/epics` → `/specify` ordering** → confirmed: `/epics` first, one `specification.md` per Epic, with
  the Jira round-trip. Two consequences baked in: the round-trip is **documented to users** (see
  *Workflow* above — command help + Phase 2.5 guidance + final report), and `/specify` gains a
  **VI-without-Epics pre-flight** (Phase 2.5) that flags a VI with no Epics and offers to create them
  first.
- **v-next (noted, not now):** let `/specify` consume `/epics` draft output directly to skip the
  round-trip.

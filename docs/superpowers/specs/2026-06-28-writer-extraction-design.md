---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# dev-workflows — Extract inline writers to subagents (docs + epics) + epics routing (design)

## Context

After `v1.15.0` (per-step model delegation for `/impl:jira:docs`), the two
Phase 6 writers are still **inline orchestrator steps**: docs "Write
documentation" and epics "Write Epics" both run as the orchestrating command
("the writer is NOT a separate subagent — it's the orchestrating command with
full context"). Because they are the orchestrator, they run on `current_model`
and **cannot be model-pinned**.

This violates the principle established with the user: **`current_model` should
cover only non-delegatable orchestration (coordination + interactive gates);
everything delegatable should be pinned to the chain its work actually
warrants.** Complex workflows start on Opus, so a MODERATE epics run started on
Opus writes its Epics on Opus *for no reason*; and a docs run started on Sonnet
writes published docs on Sonnet.

This effort extracts both writers to **write-only subagents** pinned to the right
chain, and **folds in the deferred epics per-step routing** (the original
"item 1"). Extraction is the keystone: it fixes the writer model in both
directions (docs → Opus, epics → Sonnet) and relieves the orchestrator's context
window.

Plugin `main` at `9a4cb85` (v1.15.0). Release: **MINOR `v1.16.0`** (new agents +
extraction; output-preserving, adds delegation behavior).

## Goals

- New **`doc-writer`** agent: produces product documentation. Pinned to the §2
  reasoning (Opus) chain (docs is SIGNIFICANT). Write-only.
- New **`epic-writer`** agent: produces Epic-definition files. Pinned to the §2.1
  detection (Sonnet) chain for MODERATE; escalates to §2 (Opus) only if the run
  is classified SIGNIFICANT/HIGH-RISK. Write-only.
- **Orchestrator owns all git** (branch at Phase 6.5, commit after the writer
  returns, squash at Phase 8.5); the writers never touch git.
- **Fold in epics per-step routing** (old item 1): `jira-reader`, `code-scanner`,
  `dt-style-checker`, `doc-fixer` → detection (Sonnet); `epic-reviewer` → Opus
  (frontmatter-pinned, recorded, no override); a `model_routing` block at epics
  Phase 1.5; a Phase 9 `### Model Routing` section; a routing invariant.
- **Narrow the docs Phase 1.5 advisory** to a window-focused note (the writer and
  the heavy analysis now both run on Opus regardless of session).
- **Update `classification.md` §9** to reflect delegated (pinned) writers + the
  two clarifications carried from old item 1.

## Non-goals

- The **command-namespace refactor** / monotonic phase renumber (the next effort).
- **Extracting the interactive gates** (Phase 4.5 applicability, 5.8 discrepancy
  *decision*, 5.9 strategy approval, 6.2 CDN handoff) — they are interactive
  (need the user), so they stay orchestration on `current_model`. (The heavy
  discrepancy *analysis* already runs on `doc-planner`/Opus at 5.7; Phase 5.8
  only presents it + collects the decision.)
- Touching other commands (`/impl:code`, `/upgrade`, `/vuln`).
- Changing the writers' **output contract** — same files, locations, markers,
  and traceability, so Phases 6.7 / 6.8 / 7 are unaffected.

## Design

### A. `doc-writer` agent (new)

`plugins/dev-workflows/agents/doc-writer.md`. Tools: `Read, Glob, Grep, Write,
Edit` (write-only; **no Bash, no git**). Inherits the session model by default;
the orchestrator **always** dispatches it with an explicit `model:` override
(§2 reasoning chain).

**Input contract** (the orchestrator writes these named variables — which it
already holds from Phases 3–6.2 — to a **structured handoff file** that
`doc-writer` reads verbatim; see *Biggest risk & mitigations* #1):

- `jira_reader_handoff`, `diff_summaries`
- `write_targets` (confirmed, Phase 5.5)
- `doc_planner_checklist` (Phase 5.7) + gap dispositions (TODO markers)
- `discrepancy_decisions[]` (Phase 5.8) — drives which claims are written, and
  any intentional-discrepancy markers + bug-report-draft destination
- `write_strategies[]` (Phase 5.9) — per-target `{strategy, target_space}`
- `cdn_handoff_decision` + `cdn_urls` (Phase 6.2) + `screenshot_staging_dir`
- `screenshots`, `target_spaces`, `profile`, `docs_repo_path`
- the `multi-space-writing.md` reference path (the agent reads the **mechanics**
  there — only structured data crosses the dispatch boundary, never logic)

**Behavior:** exactly what docs Phase 6 specifies today — per-space home routing,
apply each approved `write_strategy` (conditional `{{#if project='…'}}` /
override-copy + `managed/docstack.jsonc` `ignore` / plain), TODO markers for
gaps, CDN placeholders or real URLs, frontmatter, internal links by postid.
**Write-only — no commit.**

**Entry validation:** validate inputs on entry; if a required field is missing or
inconsistent (e.g. a target marked `override-copy` with no `target_space`),
return **BLOCKED** with the specific gap — never guess. Returns: status
(`DONE` / `BLOCKED`) + the list of files written/modified + any TODO/placeholder
notes for the Phase 9 report.

### B. `epic-writer` agent (new)

`plugins/dev-workflows/agents/epic-writer.md`. Tools: `Read, Glob, Grep, Write,
Edit`. Dispatched with an explicit `model:` override (detection/Sonnet for
MODERATE; reasoning/Opus if SIGNIFICANT/HIGH-RISK).

**Input contract** (same structured-handoff-file mechanism as `doc-writer`):
`jira_reader_handoff`, `code_scanner_outputs` (if scan ran), the Phase 2 scope
(in/out of scope), existing-Epics list (non-duplication), output directory, VI
goal, and the Epic-definition template. **Write-only.**

**Behavior:** one Epic-definition file per new Epic, following the template
(Goal / Business value / Scope / Acceptance criteria / Dependencies / Suggested
stories / References) and the write restrictions (never `jira-products/`,
`_archive/`, outside `$VAULT_PATH`; always the resolved output dir). Traceability:
every claim traces to the handoff or a `code-scanner` output. Returns: status +
Epic files written.

### C. docs.md changes

- **Phase 6:** replace the "writer is NOT a separate subagent" paragraph and the
  inline write mechanics with: (1) the orchestrator **writes the structured
  handoff file** (A); (2) a `doc-writer` dispatch
  (`model: <planning_model — §9 / §2 Opus chain>`) passing that file's path. Keep
  the execution-order note (Phase 6.5 branch setup runs first). **After
  `doc-writer` returns `DONE`, the orchestrator commits** its output onto the
  branch (branch from 6.5; squash still at 8.5); on `BLOCKED`, surface the gap.
  Record the written-files list for Phases 6.7 / 6.8 / 7 / 8.
- **Phase 1.5 advisory → narrowed (window-focused):** `doc-planner` (5.7) and
  `doc-writer` (6) run on Opus regardless of session; only coordination + the
  interactive gates run on `current_model`. On a non-Opus session, **large
  multi-repo tickets** may still pressure the orchestrator's context window —
  offer the relaunch/proceed/cancel choice **only** for the large-ticket +
  non-Opus case; otherwise no advisory. Keep the no-Opus degradation note
  (planning/review models fall to the Sonnet floor).
- `model_routing` block: `implementation_model` now records the **`doc-writer`
  model** (= `planning_model`), not `current_model` — the writer is delegated.

### D. epics.md changes

- **Phase 6:** replace the inline Epic-writing with (1) the orchestrator writing
  the structured handoff file (B), then (2) an `epic-writer` dispatch
  (`model: <detection_model for MODERATE; planning_model if SIGNIFICANT/HIGH-RISK>`)
  passing its path. **No git** — epics' invariants are explicit:
  *"NEVER create a git branch"* and *"NEVER commit (vault git management is the
  user's responsibility)."* So `epic-writer` simply writes the Epic files (its
  `Write` auto-creates the output dir) and the flow proceeds to Phase 6.7; nothing
  commits. (Contrast docs.md, where the orchestrator commits the writer's output.)
- **Per-step routing (folded-in item 1):** add `model:` overrides —
  `jira-reader` → detection; **`code-scanner` → detection** (per the §9.4
  refinement, E.3); `dt-style-checker` → detection; `doc-fixer` (×2) → detection.
  `epic-reviewer` keeps its frontmatter Opus pin (no override, recorded as
  `review_model`).
- **Phase 1.5:** resolve a `model_routing` block (reuse §4 names; **no
  `planning_model`** unless SIGNIFICANT; `implementation_model` = the
  `epic-writer` model). Reword `MODERATE → no Opus planning` to add the routing +
  "no relaunch advisory for MODERATE (per §3.1/§9.1); record the no-Opus
  degradation for `epic-reviewer`".
- **Phase 9:** add a `### Model Routing` section after `### Classification`.
- Add a routing **invariant** to epics' existing `## Invariants (always enforced)`
  section (mirroring docs.md's routing invariant).

### E. classification.md §9 updates

1. **§9.1** — gate the writer advisory: *applies when the task is
   SIGNIFICANT/HIGH-RISK; for SIMPLE/MODERATE the writer may run on its detection
   pin without a relaunch advisory (per §3.1).*
2. **§9.2** — replace the single "Inline writer + interactive gates → session
   model → advisory" row with two rows:
   - *Delegated writer (`doc-writer` / `epic-writer`) → §2 reasoning (Opus) for
     SIGNIFICANT/judgment writing; §2.1 detection (Sonnet) for MODERATE writing.*
   - *Coordination + interactive gates (the orchestrator itself) → session model;
     narrowed window advisory for large non-Opus runs.*
3. **§9.4** — refinement: *`code-scanner` inherits under §8.3 only when a
   powerful-chain synthesis step consumes its output; in an authoring pipeline
   with no such step (e.g. `/impl:jira:epics`), pin it to the detection chain.*

### F. Release & touch list

- MINOR **`v1.16.0`** — `plugin.json` top-level `version`; `marketplace.json`
  `plugins[0].version`; `CHANGELOG.md [1.16.0]`.
- Touch: `agents/doc-writer.md` (new), `agents/epic-writer.md` (new),
  `commands/impl/jira/docs.md`, `commands/impl/jira/epics.md`,
  `references/model-routing/classification.md`, manifests + CHANGELOG.
- ~5 plan tasks (structural verification — no test framework).

## Biggest risk & mitigations

**Risk — lossy context handoff (mainly `doc-writer`).** The inline writer holds
every prior-phase decision in working memory; a fresh subagent knows only the
dispatch. An incomplete/under-specified handoff makes the writer guess → subtly
wrong docs (wrong space protected, a skipped claim written, a placeholder where a
real CDN URL belonged). `epic-writer` is far lower-risk (simple inputs).

**Mitigations:**
1. **Structured handoff file** (A) — the orchestrator writes the fixed-schema
   input contract to a **temporary file** (`mktemp` under `$TMPDIR`/`/tmp` — *not*
   the vault, *not* the docs repo) that the writer reads **verbatim**: no prose
   paraphrase, lossless serialization, and the dispatch stays small. It is
   transient internal scratch — **decoupled from `$VAULT_PATH`** (so it works for
   any docs repo / vault layout, not just ai-containers) and never committed; the
   OS reclaims it (or the orchestrator removes it at Phase 9). The schema is built
   from variables the orchestrator already holds — not re-derived.
2. **Agent reads the SSOT** (`multi-space-writing.md`, profile) — only structured
   data crosses the boundary, never logic.
3. **Entry validation → BLOCKED, not guess** — missing/inconsistent required
   input returns BLOCKED with the specific gap.
4. **`doc-reviewer` backstop unchanged** — Phase 7 reviews against the
   doc-planner checklist + Jira + diffs and can BLOCK → `doc-fixer`; anything the
   writer drops is caught.

Output contract is identical (same files/locations/markers/traceability), so
6.7/6.8/7 are unaffected; and `doc-writer` runs on Opus — the same model a
relaunched inline writer would use — so prose quality is preserved.

## Invariants preserved

- **Zero external API** — writers are local Read/Write/Edit; no network, no git.
- The frontmatter Opus pins on cross-command reviewers are untouched.
- The multi-space render-unchanged invariant and opt-in commit/push are
  untouched (the orchestrator still owns branch/commit/squash/push).
- `doc-planner` (5.7) and `doc-reviewer` (7) routing from v1.15.0 unchanged.

## Open items (confirm during spec review)

- None — the two-agent split, write-only + orchestrator-commits, the narrowed
  docs advisory, the epics writer/​dispatch routing, and the §9 updates are all
  settled.

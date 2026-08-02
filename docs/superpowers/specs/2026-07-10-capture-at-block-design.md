---
tags:
  - tasks-exclude
---

# Capture-at-block — `emit-block` feedback on a gap-caused halt

**Status:** approved (design), pending implementation
**Date:** 2026-07-10
**Target:** `dev-workflows` plugin — `references/feedback-emission.md` + the 8 pipeline commands
**Release:** MINOR `v2.14.0`
**Origin:** AI-First.md task line 93 ("interrupt a workflow on a skill gap, escalate to the user"). Decided during brainstorming: an **interrupting guard / enforced collection is NOT built** — it contradicts v2.9.0's deliberate silent, high-recall, maintainer-curates model, "gap" is unreliable to auto-detect, and genuine hard blocks already escalate. The one real seam closed here: gap capture happens in the **terminal maintenance phase**, so a run **abandoned at a BLOCK** loses its highest-value signal (the gap that actually stopped the work).

## Goal

When a pipeline run **halts on a plugin-facing gap** (the plugin lacked a capability / reference / skill / command-path the run needed), emit **one** `blocker`-impact feedback entry **silently, at the halt, before the escalation** — so an abandoned-at-block run still records the gap. No interrupt, no prompt, no enforced collection: the escalation the user sees is the normal `BLOCKED` message; the feedback write is silent, consistent with the existing model.

## Design

### New entry point — `emit-block` (in `references/feedback-emission.md`)

A fourth caller contract alongside `emit-auto` / `emit-manual` / `emit-prompt`, sharing the silent / `origin: auto` / dedup semantics of `emit-auto`:

- **Inputs:** `command` (exact slash-command name), `jira_key` (or `null`), `source` (`vault | directory | none`), and the **halting gap** — a short description of the plugin-facing capability / reference / skill / command-path the run needed but the plugin lacked. (Unlike `emit-auto`, no `impl-maintenance` report exists — the run is being abandoned mid-flight, so the gap is passed directly.)
- **Behavior:** render **one** entry with `origin: auto` and **`impact: blocker`**; `category` from the existing controlled vocab (`missing-capability` / `missing-reference-doc` / `manual-workaround` / `model-routing` as fits); `plugin_version` per §3; dedupe by the stable `id` (§3 — so it will not double-log if a later terminal `emit-auto` captures the same gap on a resumed run); resolve the target (§2); **write silently** (§5). Then the caller proceeds to surface its normal `BLOCKED` escalation. Returns the persisted path (for the caller's block message / final report), or nothing to surface interactively.
- **Predicate (tight — the key to avoiding noise):** fires **only** for a **plugin-facing gap**. It does **NOT** fire for:
  - code / doc / Epic **review BLOCKs** (a defect in the *work*, not the plugin),
  - environment / user halts — repo-missing, dirty-tree, jira-not-found, refresh-blocked, and the other `escalation-rules.md` cases (user/environment, not a plugin gap),
  - user-cancellation.
  The same plugin-facing scoping as §4 applies (never target-project `CLAUDE.md` / hook advice).

### §5 interaction-model note

Add a bullet: `emit-block` writes silently like `emit-auto`; the halt is surfaced by the caller's existing `BLOCKED` escalation, not by a feedback prompt — capture-at-block stays inside the silent model.

### Wiring — one invariant per pipeline command

Add a single invariant to each of the **8** commands that already run `emit-auto` in their terminal phase — `/implement`, `/document` (both modes share one invariants block), `/epics`, `/release-notes`, `/specify`, `/design`, `/vuln`, `/upgrade`:

> ALWAYS `emit-block` (per `references/feedback-emission.md`) before escalating a halt that is caused by a **plugin / skill / command / reference gap** — a capability the run needed but the plugin lacked — so a run abandoned at the block still records the gap. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, jira-not-found, cancellation).

An invariant (rather than editing each scattered block site) covers every halt path in the command uniformly and low-risk.

## Scope & boundaries

- Edited: `references/feedback-emission.md` (+ the new entry point, §5 note) and the 8 command files (one invariant each) + release surfaces.
- **Untouched:** the `impl-maintenance` agent (still report-only; `emit-block` takes the gap directly, no agent change), `emit-auto`/`emit-manual`/`emit-prompt` behavior, all reviewers/subagents, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1).

## Invariants preserved

- **Silent model intact** — no curation/approval gate; no interrupt beyond the block that was already happening; a run with no gap-caused halt writes nothing new.
- **Dedup** — a capture-at-block entry and any later terminal `emit-auto` entry for the same gap share the stable `id` → no duplicate.
- Persistence ladder (specs-first, never cwd), attribution, and privacy (no user name) unchanged — `emit-block` reuses §2/§3.
- No enforced-feedback gate, no new external calls, no new subagents.

## Verification (structural — no test framework)

- `feedback-emission.md` defines `emit-block` with `origin: auto` + `impact: blocker` + the tight predicate (excludes review-BLOCK / env-user halts) + dedup; the §5 note is present.
- Each of the 8 commands carries exactly one `emit-block` invariant referencing `feedback-emission.md` with the plugin-gap-only predicate.
- `git diff` touches only `feedback-emission.md` + the 8 commands + release files; `impl-maintenance`, other agents, and siblings byte-unchanged.
- JSON valid; versions lock-step `2.14.0`; siblings byte-identical.

## Release

MINOR `v2.14.0`. Lock-step `plugin.json` + root `marketplace.json` (dev-workflows only); `## [2.14.0]` CHANGELOG entry (em-dash date). Trailer exact: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Never `git add -A`. Lightweight direct edit + structural verification.

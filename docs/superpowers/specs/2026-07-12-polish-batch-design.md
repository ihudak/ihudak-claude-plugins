---
tags:
  - tasks-exclude
---

# Polish batch + deterministic pre-lint — design

**Date:** 2026-07-12
**Task:** the "polish batch" agreed as the next effort from the AI-First.md line-85 borrow analysis (Tier-1 cheap borrows).
**Effort:** dev-workflows **v2.26.0**
**Predecessor:** `research/2026-07-12-bmad-speckit-superpowers-grillme-borrow-analysis.md` (Tier-1 "BUILD next (cheap): Polish batch + deterministic pre-lint — one release").

## Scope decision (locked)

Six items were proposed; **two dropped** after exploration showed they don't fit:
- **Dropped — /idea URL-fetch trust policy:** `/idea` has no live web-fetch today (`idea-reader` has no WebFetch tool and an explicit "NEVER reach out over HTTPS" rule; a "community post" is vault-markdown only). A fetch *trust policy* presupposes a fetch capability that doesn't exist — web ingestion is a feature, revisit as its own effort.
- **Dropped — /specify seam step:** the "highest seam" concept already lives in `/design` (`design-format.md` §Seams, gated by `design-reviewer`) — the engineering layer grill-me's `to-spec` maps to. `/specify` is product-level; a seam step there would cross into implementation detail.

**Four items ship in one release (v2.26.0):** (1) deterministic pre-lint; (3) grilling self-answer guard; (4) vi-reviewer theater detection; (6) /implement context-exhaustion strategy.

## Goal

Cheap, idiomatic quality polish: a deterministic structural pre-check before the Opus reviewers, plus three targeted hardening tweaks — all additive, no new command/agent, no test-framework dependency.

## Item 1 — Deterministic pre-lint

**Form (chosen):** a shared SSOT reference doc + a thin per-command phase step; no Python; **advisory** (surface + inline-fix mechanical findings before the reviewer, never a hard block); **the five reviewer agents are untouched**.

**NEW `references/pre-lint.md`** — defines deterministic (grep-expressible) structural checks in two tiers.

*Universal (all artifacts):*
- **Placeholder scan** — flag `TBD`, `TODO`, `FIXME`, `XXX`, angle-bracket placeholders `<…>`, and unfilled `[instruction]` brackets. (Legitimate per-artifact markers `[NEEDS CLARIFICATION]` and `- [ ]` open questions are counted per-artifact below, not flagged as generic placeholders.)
- **Identifier integrity** — for each artifact's sequential ID series, verify monotonic numbering and no duplicates; a gap is MINOR.
- **Required-section presence** — every mandatory heading for the artifact type is present.

*Per-artifact* (checks are defined against each artifact's existing format reference; the plan pins exact grep patterns after reading those docs):
- **VI** (`vi-format.md` spine): Problem, Goal, Target audience, User Stories, Acceptance Criteria, Scope, Success Metrics present; story/criterion IDs sequential; `[NEEDS CLARIFICATION]` count ≤ 3.
- **ARD** (`ard-format.md`): every `AD-N` block carries **Binds / Prevents / Rule**; AD-N IDs monotonic + no dupes; no unpinned-version placeholders.
- **spec** (`specification-format.md`): `[Uxx]` / `[ACxx]` / `[TCxx]` ID integrity; required sections (problem, scope, user stories, acceptance criteria, test cases) present.
- **Epic** (`epic-format.md`): each Epic has Given/When/Then acceptance criteria and a `## Independent Test` section; IDs intact.
- **design** (`design-format.md`): `## Seams` present for MODERATE+; open-question `- [ ]` scan (report count — the existing design-reviewer hard-block on open questions still governs).

*Output/severity contract:* pre-lint surfaces findings; **mechanical** ones (duplicate/renumberable ID, stray placeholder token) are inline-fixed; **content** gaps (missing section body, unresolved placeholder needing text) are surfaced for the author/grill to resolve. The command then proceeds to the Opus reviewer. Pre-lint **never hard-stops** on its own; the reviewer remains the gate. This mirrors the existing `create-vi` Phase 3.5 style-check precedent.

**Per-command wiring (5 commands)** — a thin new phase step inserted immediately before each Opus-reviewer dispatch, citing `${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` and running the universal + artifact-specific checks:
- `commands/create-vi.md` — between existing Phase 3.5 (style) and Phase 4 (vi-reviewer, ~line 139).
- `commands/create-ard.md` — before Phase 5 (ard-reviewer, ~line 97).
- `commands/specify.md` — between Phase 5 (author, ~line 339) and Phase 6 (spec-reviewer, ~line 355).
- `commands/design.md` — between Phase 5 (author) and Phase 6 (design-reviewer, ~line 256).
- `commands/epics.md` — after existing Phase 6.1 (style) / 6.2 (clarification), before Phase 7 (epic-reviewer, ~line 358).

Exact phase numbers/anchors pinned in the plan.

## Item 3 — Grilling self-answer guard

**`references/grilling-technique.md`** — add a short subsection between *Mechanics* and *Depth*: **when no human turn is available (autonomous / background run), genuine *decisions* must be recorded as open questions** (`[NEEDS CLARIFICATION]` for bounded callers, `- [ ]` for relentless callers) rather than self-answered. This complements the existing fact-vs-decision split (line 12): facts → answer yourself; decisions → the user, or *if no user is present* → a recorded open question. One paragraph; keeps the file's other mechanics intact.

## Item 4 — vi-reviewer theater detection

**`agents/vi-reviewer.md`** — extend the existing line-37 "substance over theater" dimension. Today it flags only *empty/boilerplate* adapt-in sections. Add coverage for **well-written-but-hollow prose**: a non-empty section that states no testable commitment, decision, or constraint (vision/persona/NFR that "reads well, does no work") → **MAJOR**, same bar as empty/boilerplate. One dimension bullet; no other reviewer touched.

## Item 6 — /implement context-exhaustion strategy

**NEW `references/context-management.md`** (small, `grilling-technique.md`-style) — three long-run strategies:
- **scope-to-N** — implement the first N steps, checkpoint (commit + report), then continue.
- **sub-agent-per-`[P]`** — offload parallel-safe (`[P]`-marked) steps to fresh subagents to preserve the orchestrator's context.
- **decompose** — split an oversized step list into independently shippable units.

**`commands/implement.md`** — a thin note in Phase 3B (~line 409, before "Make precise, surgical changes") citing `${CLAUDE_PLUGIN_ROOT}/references/context-management.md` for long step lists. Cited only by `/implement` in this batch (the doc is reusable by `/design`/`/epics` later — YAGNI now).

## Manifests & counts

- **2 new reference docs, 0 new commands/agents** → counts stay **20 commands / 30 subagents**. The manifest `description` strings do not count reference docs, so both descriptions stay **byte-identical**.
- **Version 2.25.0 → 2.26.0** lock-step (`plugin.json` + the dev-workflows entry in `.claude-plugin/marketplace.json`).
- `CHANGELOG.md` — new `## [2.26.0] — 2026-07-12` entry.

## Non-goals

- No web-fetch / URL ingestion in `/idea` (dropped).
- No seam step in `/specify` (dropped).
- No edits to `ard-reviewer`, `spec-reviewer`, `design-reviewer`, `epic-reviewer` (pre-lint is command-side; only `vi-reviewer` changes, for the theater dimension).
- No changes to `/vuln`, `/upgrade`, or the sibling plugins.
- No pre-lint hard-block (advisory only; reviewers remain the gate).
- Pre-lint stays grep/markdown — no Python, no new `scripts/` file.

## Verification (structural — no test framework)

- **New files exist & are cited:** `references/pre-lint.md` and `references/context-management.md` present; `grep -l pre-lint.md commands/*.md` returns the 5 reviewer-gated commands; `grep -l context-management.md commands/implement.md` matches.
- **Each of the 5 commands** has exactly one new phase step citing `pre-lint.md`, placed immediately before its reviewer dispatch.
- **grilling-technique.md** contains the autonomous/background guard; the fact-vs-decision line and Depth section are unchanged.
- **vi-reviewer.md** theater dimension extended; other four reviewer agents 0-line diff.
- **implement.md** Phase 3B cites `context-management.md`; direct-mode behavior otherwise unchanged.
- **Manifests parse** at `2.26.0` (both); descriptions byte-identical + count-strings `Twenty slash commands` / `Thirty reusable subagents` intact; counts `ls commands/*.md`=20, `ls agents/*.md`=30.
- **No-regression:** siblings `dt-style-guide` 0.2.2 / `obsidian-llm-wiki` 0.3.1, and `/vuln`, `/upgrade`, `ard-reviewer`, `spec-reviewer`, `design-reviewer`, `epic-reviewer` all 0-line diff.

## Risks

- **Low.** Additive markdown + grep-expressible checks; no runtime code, no reviewer-agent behavior change.
- **Pre-lint / reviewer overlap** — the checks partly duplicate what the Opus reviewers already do; the value is cheaper iteration (mechanical defects caught before an Opus pass is consumed) and one structural SSOT, not net-new coverage. Accepted.
- **Per-artifact ID-scheme accuracy** — the plan must read each format reference to pin exact grep patterns; a wrong pattern would mis-report. Mitigated by pinning patterns from the format docs at plan time, not from memory.

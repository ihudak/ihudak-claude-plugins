---
tags:
  - tasks-exclude
---

# `/create-vi` VI-authoring quality — design (v2.22.0)

**Status:** approved-for-planning
**Date:** 2026-07-12
**Plugin:** dev-workflows (repo `/workspace/ihudak-claude-plugins`)
**Version:** 2.21.0 → **2.22.0** (minor; feature, no new command/agent)
**Counts:** unchanged — Nineteen slash commands / Twenty-nine reusable subagents

## 1. Goal

Improve the quality of the Value Increment that `/create-vi` produces, by
closing two recorded follow-ups from the v2.21.0 `/epics` uplift:

- **#5** — run a **Dynatrace style check** on the VI (VIs get none today; Epics
  do, via `/epics` Phase 6.1), with emphasis on terminology + customer-facing
  text.
- **#1** — **nudge** the author toward the richer `FR-N` / `UC-N` requirement
  clusters for complex VIs, so downstream `/epics` coverage is finer-grained.

This is **Cluster A** of the v2.21.0 follow-up set. Cluster B (`/epics`
VI-level-spec `[TCxx]` enrichment) is a separate follow-on effort. The two
marginal follow-ups (graded reviewer rubric; cross-iteration regression
tracking) were **dropped** (user decision 2026-07-12).

## 2. Motivation & grounding

- `/create-vi` runs **no** style checker today (`grep` confirms); `vi-reviewer`
  has **no** terminology/style dimension — consistent with `epic-reviewer`
  (content-only), where corporate style is a *separate* `dt-style-checker` pass.
  So #5 fills a real gap and belongs in a new phase, not in `vi-reviewer`.
- `vi-reviewer` explicitly **"never flags an omitted adapt-in cluster the
  profile doesn't require."** So #1 must be **authoring-side** (grill + profile
  selection), NOT a reviewer flag — a reviewer flag would contradict that rule
  and produce false positives.
- `/create-vi` authors **inline** (the orchestrator/grill writes and fixes; no
  delegated writer — see Phase 4's inline BLOCK fixing). Style fixes follow the
  same inline model.
- The VI spine (`## User Stories [US-N]`, `## Acceptance Criteria [AC-N]`,
  `## Success Metrics [SM-N]`) is mandatory in every profile; `FR-N` is
  full-only, `UC-N` is hybrid/full (`vi-format.md`). So #1 is a *within-profile*
  active-pull plus a *profile-upgrade* suggestion — never a hard requirement.

## 3. Scope

### In scope
1. New **Phase 3.5 — Dynatrace style check** in `commands/create-vi.md`.
2. Profile nudge in **Phase 1.5** + active-pull guidance in **Phase 3** for
   complex VIs.
3. Manifest version bump + CHANGELOG.

### Out of scope
- Any `vi-reviewer` change (its "never flag omitted cluster" rule stands).
- A delegated style fixer (`dt-doc-fixer`) — fixes are applied inline, matching
  `/create-vi`'s authoring model.
- Making the style check a hard gate — it is advisory (like `/epics` 6.1).
- Cluster B (`[TCxx]` enrichment) and the dropped #2/#3.

## 4. Feature #5 — Dynatrace style check (new Phase 3.5)

Insert **`## Phase 3.5 — Dynatrace style check`** between Phase 3 (Author via
grill) and Phase 4 (Review gate).

- Invoke `dt-style-guide:dt-style-checker` (model: the `§2.1` Sonnet detection
  chain, matching `/epics` Phase 6.1) with:
  - `files:` the absolute path to `<KEY>_ValueIncrement.md`
  - `doc_type: vi`
  - `emphasis: terminology and customer-facing captions, labels, messages, and text`
- Act on the return (mirrors `/epics` Phase 6.1, but fixes inline):
  - **`OK`** — proceed to Phase 4.
  - **`VIOLATIONS_FOUND`** — the orchestrator applies the **MAJOR** fixes
    **inline** (it is the author; consistent with Phase 4's inline model), then
    re-runs `dt-style-checker` **once**. Remaining MINOR/NIT → final report.
  - **`ERROR`** — surface the reason, proceed to Phase 4 (non-gating).
- If `dt-style-checker` is unavailable (agent not found — `dt-style-guide` not
  installed) → **skip Phase 3.5 gracefully**, note "SKIPPED (dt-style-checker
  unavailable)" in the final report. **Non-gating** throughout: style is a
  quality enhancement, never blocks the handoff.

## 5. Feature #1 — Nudge toward FR-N / UC-N for complex VIs

Two authoring-side touches; **no `vi-reviewer` change**.

- **Phase 1.5 (classify) — profile nudge.** After classification, if the VI is
  **SIGNIFICANT** (complex/cross-cutting) AND the chosen profile is `--lean` or
  `--hybrid` (so `FR-N` is unavailable), surface a one-line, **non-blocking**
  recommendation:
  > "This VI classifies SIGNIFICANT — consider `--full` so Functional
  > Requirements (`FR-N`) and richer Use Cases (`UC-N`) are available for
  > stronger, more traceable downstream Epic coverage."
  The user keeps their profile if they decline; the run continues unchanged.
- **Phase 3 (author) — active pull.** Strengthen the adapt-in authoring
  guidance: for a **complex** VI, *actively* author `FR-N` (full) / `UC-N`
  (hybrid/full) within the chosen profile — lowering the bar from today's
  passive "pulled only when the idea warrants it," while preserving "never an
  empty section." Add the rationale inline: richer, ID'd requirements feed a
  finer `/epics` `_coverage.md` (traceability to `FR-N`/`UC-N`, not only
  `US/AC/SM`).

## 6. No-regression

- A **SIMPLE/MODERATE** VI sees no profile nudge (guarded on the SIGNIFICANT
  classification) → byte-identical to today.
- `dt-style-guide` absent ⇒ Phase 3.5 skips ⇒ byte-identical to today.
- `vi-reviewer` untouched; the two sibling plugins (`dt-style-guide` 0.2.2,
  `obsidian-llm-wiki` 0.3.1), `/vuln`, `/upgrade` untouched.
- Command/agent counts unchanged (19/29); marketplace description strings
  ("Nineteen…"/"Twenty-nine…") byte-identical.
- `/create-vi` still commits only when asked (Phase 5), never `git add -A`,
  never writes into a code/docs repo or cwd.

## 7. Verification (structural — no test framework)

- `python3 -c json.load` parses both manifests; version `2.22.0` in
  `plugin.json` + the `dev-workflows` `marketplace.json` entry.
- grep anchors in `create-vi.md`: `Phase 3.5 — Dynatrace style check`,
  `dt-style-guide:dt-style-checker`, `doc_type: vi`,
  `emphasis: terminology and customer-facing`, the Phase 1.5 profile-nudge
  string (`consider \`--full\``), the Phase 3 active-pull guidance.
- `git diff --stat main` shows only: `commands/create-vi.md`, `plugin.json`,
  `marketplace.json`, `CHANGELOG.md`. `agents/vi-reviewer.md`, `/vuln`,
  `/upgrade`, and both sibling plugins show **no** diff.
- CHANGELOG prepends `## [2.22.0] — 2026-07-12`.

## 8. Files changed

- `commands/create-vi.md` — new Phase 3.5; Phase 1.5 nudge; Phase 3 active-pull
  guidance; final-report line for the style-check outcome.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — 2.22.0.
- `CHANGELOG.md` — 2.22.0 entry.

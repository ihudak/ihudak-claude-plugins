---
tags:
  - tasks-exclude
---

# ARD-consumption wiring — design (dev-workflows v2.18.0)

**Date:** 2026-07-10
**Effort:** dev-workflows **v2.18.0** — additive (modifies existing commands/reviewers; strictly no-regression)
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Context:** The committed follow-up to `/create-ard` (v2.17.0). `/create-ard` *produces* ARDs; this effort makes the downstream *consume* them.
**Trailer:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` — commit named files only, never `git add -A`.

---

## Goal

Make `/design`, `/implement`, and `/specify` **read and respect** the applicable ARD's `AD-N` invariants — at both VI and Epic levels (Epic inherits VI; a big Epic may have per-area ARDs) — while **gracefully no-op'ing when no ARD exists** (behavior byte-identical to today).

## Why (scope framing)

An ARD nothing consumes is only human-facing. This wiring makes the architect's invariants *bind* the design, implementation, and spec — via one shared resolver (DRY) and a **conditional** reviewer dimension that is skipped whenever no ARD is in scope. The whole flow now closes: `/create-ard` → the ARD → enforced downstream.

## Decisions (locked in brainstorming)

1. **All three consumers ship in one v2.18.0** (the shared resolver is built once; each wiring is a small parallel edit citing it).
2. **Enforcement = binding + deviation-record.** An `AD-N` Rule violation is a reviewer **BLOCKER** by default; the fix is conform **or** record an explicit "ARD deviation" flagged to the architect — never a silent violation, and **the consumer never edits the architect's ARD**. The ARD's non-`AD-N` grounding/guidance is advisory.
3. **Shared `references/ard-resolution.md`** owns resolution + the optional/no-regression discipline + the deviation-record convention.
4. **No new command / no new subagent** → command/subagent counts and the feedback/cost enums are **unchanged**; only a version bump.

---

## Architecture

### 1. `references/ard-resolution.md` (NEW — shared resolver, cited by all three consumers)

**Inputs:** `vi` (VI key), `epic` (or `null`), `area` (or `null`), `$SPECS_PATH`.

**Resolution (most-specific first):**
1. Resolve the VI dir `$SPECS_PATH/specifications/<VI>-<vslug>/` (match by key-number, tolerate `-`/`_` drift — same rule the other commands use).
2. Collect candidate ARD files:
   - **Epic-level run** (`epic` set): `<VI>-<vslug>/<EPIC>-<eslug>/<EPIC>_ARD.md` and any `<EPIC>-<area>_ARD.md` (the area-scoped one when `area` is given, else all per-area ARDs) **plus** the VI-level `<VI>_ARD.md` for inherited invariants.
   - **VI-level run** (`epic` null): just `<VI>-<vslug>/<VI>_ARD.md`.
3. Parse each file's `## Architecture decisions` into `AD-N {id, Binds, Prevents, Rule, source: vi|epic|area}`. VI-level `AD-N` are the inherited base; Epic/area `AD-N` layer on top (Epic-specific wins on any conflict — though `ard-reviewer` already blocked contradictions at authoring time).

**Output — the normalized ARD context, or `none`:**
```yaml
status: found | none
ard_paths: [ <absolute paths of the ARD files used> ]
invariants:
  - id: AD-1
    source: vi | epic | area
    binds: <text>
    prevents: <text>
    rule: <testable statement>
guidance_summary: <short prose: the ARD's non-AD-N architecture guidance a consumer should heed>
```
`status: none` when no ARD file resolves (the common case — `/create-ard` is optional).

**No-regression rule (central):** a caller that gets `status: none` **must behave exactly as it did before v2.18.0** — no prompt, no extra phase, no reviewer dimension. The ARD steps are strictly additive and guarded on `status: found`.

**Deviation-record convention:** when an artifact must not honor an `AD-N`, the consumer records — in its own artifact, **never in the ARD** — a line:
`- ARD deviation: [<AD-N id>] — <what deviates> — <why> — flag: architect`
and surfaces it in the final report. A reviewer treats a violating artifact **with** a matching deviation record as *allowed-but-flagged* (the architect adjudicates), **without** one as a **BLOCKER**.

### 2. Reviewer conditional dimension (shared wording, added to three reviewers)

Add an input `applicable_ard` (the `invariants` list, or absent) and this dimension:

> **ARD conformance (conditional — only when `applicable_ard` is provided).** For each `AD-N`, check the artifact honors its `Rule`. A violation with **no** matching recorded ARD-deviation → **BLOCKER**; **with** a recorded deviation → surface as a flagged note (not a blocker). When `applicable_ard` is absent/empty, **skip this dimension entirely** (byte-identical behavior).

- **`design-reviewer`** (`/design` only) — checks `design.md` honors the invariants.
- **`spec-reviewer`** (`/specify` only) — flags a spec whose stories/scope contradict an `AD-N` or the ARD scope.
- **`code-review`** (**SHARED** by `/implement` + `/vuln` + `/upgrade`) — the dimension is gated on the caller passing `applicable_ard`. `/implement` (Jira mode) passes it; **`/vuln` + `/upgrade` never do → their behavior is byte-identical** (they are not modified at all).

### 3. Per-consumer wiring

- **`/design` (primary consumer).** At input resolution, call `ard-resolution.md` with `<VI>`/`<EPIC>`. On `found`, inject the `invariants` + `guidance_summary` into the design grill — the design is authored *within* them; a necessary deviation is recorded in a `## ARD deviations` section of `design.md` + as an open question. Pass `applicable_ard` to `design-reviewer`. On `none`, unchanged.
- **`/implement`.** Jira mode: resolve the ARD; inject `AD-N` as **implementation guardrails** into the implementation guidance; pass `applicable_ard` to the `code-review` gate (SIGNIFICANT/HIGH-RISK). A code violation → BLOCKER unless conformed, or logged-override + a recorded deviation in the Phase-5 report. SIMPLE/MODERATE (no `code-review` gate) still receive the guardrails as guidance. Direct mode (no Jira key) → `none`, unchanged.
- **`/specify`.** Resolve the ARD; the spec grill keeps user stories + scope consistent with the `AD-N` + ARD scope; deviations → the spec's `### Open questions`. Pass `applicable_ard` to `spec-reviewer`. On `none`, unchanged.

---

## Out of scope (YAGNI)

- **`/vuln` + `/upgrade`** — never architecture-driven; not modified at all. `code-review`'s new dimension is conditional so they stay byte-identical.
- **`/document` + `/release-notes`** — docs, not architecture-bound.
- No changes to `/create-ard` or `ard-format.md` (the producer side is done).
- The next-phase-offer-everywhere and `.obsidian` follow-ups remain separate.

## Follow-ups (unchanged, recorded)

- **Next-phase-offer-everywhere** — generalize the phase offer to all pipeline commands.
- **Revisit the `.obsidian/` vault-check plugin-wide.**

## Verification (structural — no test framework, no husky/prettier hook)

- **No-regression (the critical check):** `git diff --stat main -- commands/vuln.md commands/upgrade.md` → **no output** (untouched). grep each consumer's ARD step is guarded on `status: found` / "if an ARD resolves", and the reviewer dimension text contains "conditional" + "skip this dimension entirely" so the no-ARD path is byte-identical.
- `references/ard-resolution.md` present with the `status`/`invariants`/`guidance_summary` output keys + the deviation-record convention + the most-specific-first precedence.
- grep anchors: `commands/{design,implement,specify}.md` each cite `references/ard-resolution.md` and pass `applicable_ard` to their reviewer; `agents/{design-reviewer,code-review,spec-reviewer}.md` each carry the conditional "ARD conformance" dimension.
- `python3 json.load` on both manifests; version 2.18.0 lock-step; the two `dev-workflows` descriptions **byte-identical** (description text unchanged — only the version field moves); siblings `dt-style-guide` 0.2.2 / `obsidian-llm-wiki` 0.3.1 unchanged.

## File manifest (11 — 1 new + 10 modified)

**New**
- `references/ard-resolution.md`

**Modified**
- `commands/design.md` — resolve ARD, inject invariants into the grill, pass `applicable_ard` to `design-reviewer`, `## ARD deviations` handling
- `commands/implement.md` — Jira-mode resolve ARD, AD-N guardrails, pass `applicable_ard` to `code-review`
- `commands/specify.md` — resolve ARD, keep spec consistent with AD-N/scope, pass `applicable_ard` to `spec-reviewer`
- `agents/design-reviewer.md` — conditional ARD-conformance dimension
- `agents/code-review.md` — conditional ARD-conformance dimension (gated on `applicable_ard`; `/vuln`+`/upgrade` never pass it)
- `agents/spec-reviewer.md` — conditional ARD-conformance dimension
- `.claude-plugin/plugin.json` — version → 2.18.0 (description unchanged)
- `.claude-plugin/marketplace.json` — `dev-workflows` entry version → 2.18.0 (byte-identical description)
- `CHANGELOG.md` — prepend `## [2.18.0] — 2026-07-10`
- `README.md` — brief ARD-consumption notes on the `/design`, `/implement`, `/specify` rows

## Release discipline

Branch `ivgu/NOISSUE-ard-consumption`; commit named files only (never `git add -A`); trailer as above. Version lock-step (plugin.json + marketplace.json dev-workflows entry). Prepend CHANGELOG (em-dash date). Merge ff to `main`; **push only when the user asks**. Watch for lima read-after-write flakiness (fsck-first, `update-ref` the dangling commit if a ref-write fails; verify HEAD after each).

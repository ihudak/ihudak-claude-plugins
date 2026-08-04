---
tags:
  - tasks-exclude
---

# `/epics` quality uplift — design (v2.21.0)

**Status:** Shipped in dev-workflows v2.21.0 — pre-implementation design snapshot, kept as authored.
**Date:** 2026-07-12
**Plugin:** dev-workflows (repo `/workspace/ihudak-claude-plugins`)
**Version:** 2.20.0 → **2.21.0** (minor; feature, no new command/subagent)
**Counts:** unchanged — Nineteen slash commands / Twenty-nine reusable subagents

## 1. Goal

Make `/epics` Epic-decomposition **auditable** (requirement→Epic coverage with
gap-detection), **honest about unknowns** (`[NEEDS CLARIFICATION]` markers),
**independently-shippable** (no-forward-dependency check), and
**architecture-consistent** (ARD wiring) — by folding in the ideas that BMAD and
SpecKit independently converged on, adapted to our Jira-driven, vault-markdown,
does-NOT-author-Stories model.

## 2. Motivation & research

Two research fan-outs (local clones `/workspace/BMAD-METHOD`,
`/workspace/github-spec-kit`) independently pointed at the same gaps in our
`/epics`. That convergence is the high-confidence signal:

- **Requirement→Epic coverage matrix** — BMAD `FR Coverage Map`
  (`bmad-create-epics-and-stories/steps/step-02-design-epics.md`,
  `bmad-check-implementation-readiness/steps/step-03`), SpecKit `/analyze`
  coverage map + stable IDs. We had only a narrative "non-duplication" judgment.
- **Explicit uncertainty markers** — SpecKit `[NEEDS CLARIFICATION]`
  (`templates/spec-template.md`, `templates/commands/specify.md`). We had none;
  the writer silently guessed.
- **Given/When/Then ACs + "Independent Test"** — SpecKit
  `templates/spec-template.md`; BMAD story ACs. We said "testable" but never
  enforced a shape.
- **Epic-independence / no-forward-dependency** — BMAD explicit rule + red-flag
  list. We had only a generic "Dependencies" field.
- **Anti-pattern + good/bad example pairs** — BMAD ✅/❌ Epic examples, SpecKit
  good/bad success-criteria pairs. Cheap prompt sharpening.
- **Filler / "theater" detection** — BMAD `prd-validation-checklist.md`.

The Epic/Story boundary and full Story authoring (BMAD `step-03-create-stories`,
`bmad-create-story`), SpecKit's git-branch-per-feature layout, its `/plan`+
`/implement` code-gen machinery, and constitution *versioning ceremony*
explicitly **do not transfer** to a draft-for-a-human, doesn't-author-Stories
tool. The constitution-as-gate *idea* maps onto our existing ARD-resolution
mechanism (v2.18.0), which `/epics` is the one VI-consuming command **not** yet
wired to — closing that is part of this effort.

## 3. Scope

### In scope (base)

1. `jira-reader` emits a `requirements[]` inventory (native VI IDs).
2. `epic-writer` template + discipline: G/W/T ACs, `## Independent Test`,
   `## Covers`, source-anchored citations, `[NEEDS CLARIFICATION]` markers,
   pre-draft dedup pre-flight, ARD-respect, and it writes `_coverage.md`.
3. `_coverage.md` — the VI-holistic coverage matrix + roll-up verdict/%.
4. New **Phase 6.2** clarification-resolution gate.
5. `epic-reviewer` new/upgraded dimensions: requirement-coverage,
   epic-independence, internal terminology-drift, unresolved-marker BLOCK,
   conditional ARD-conformance, anti-pattern + filler detection under goal
   clarity.
6. `commands/epics.md` wiring: new Phase 2.5 (ARD), carry `requirements[]`,
   handoff + reviewer-brief additions, Phase 6.2 gate, Phase 6.1 dt-style
   emphasis, Phase 9 report additions, invariants.
7. Sizing/sequencing heuristic (writer + Phase 2 plan).
8. `references/ard-resolution.md` — add `/epics` to the citing-commands list
   and the informative consumers list.
9. Manifests (version) + CHANGELOG.

### Out of scope → follow-ups (user pre-agreed)

- Graded strong/adequate/thin/broken **output-shape rewrite** of the reviewer
  (the cheap *filler-detection* half is in-scope; the scale rewrite is not).
- Cross-iteration regression tracking (low value under the 1-fix/1-re-review
  cap).
- VI-level-spec `[TCxx]` enrichment of the inventory (requires a 2nd read
  source: the `$SPECS_PATH` VI spec).
- Applying `dt-style-checker` to **VIs** — a `/create-vi` change, different
  command.

### Dropped

- Any `/create-vi` "nudge" toward richer requirements — the PE/PA already
  enrich VIs manually when needed.

## 4. Data source & the coverage inventory

`/epics` Phase 3 already invokes `jira-reader` (depth `vi-plus-epics`), which
reads the **imported** VI in `jira-products/<KEY>/<KEY>.md` (the PM→Jira→PE
round-trip copy). The VI **spine is present in every profile** (`vi-format.md`):
`## User Stories [US-N]`, `## Acceptance Criteria [AC-N]`, `## Success Metrics
[SM-N]` are mandatory in `--lean`, `--hybrid`, and `--full`; `[FR-N]`/`[UC-N]`
are profile-gated (full/hybrid). So the inventory is guaranteed for any
well-formed VI; a leaner VI simply yields a coarser matrix (by design).

**`jira-reader` new output field** (additive; `/document` + `/specify` ignore
it):

```yaml
requirements_source: native | derived
requirements:
  - id:   US-1 | AC-3 | SM-2 | FR-1 | UC-1 | R1   # native VI id, or synthetic Rn
    type: story | criterion | metric | functional | usecase | derived
    text: <the requirement text>
```

- **native** — parse the VI body's `[US-N]`/`[AC-N]`/`[SM-N]`/`[FR-N]`/`[UC-N]`
  sections into rows using each item's own id.
- **derived** — fallback when the imported Description has none of those
  structured sections (legacy VI, or a PM who pasted only prose): decompose
  `value_increment.goal` + `themes` into synthetic `R1..Rn` and set
  `requirements_source: derived`. Consumers note the matrix is coarse.

Populated at every depth (the VI file is always read; extraction is nearly free).

## 5. Epic file template (epic-writer)

Additions to the existing template (`Goal / Business value / Scope / Acceptance
criteria / Dependencies / Suggested stories / References`):

- **Acceptance criteria** — each criterion in **Given/When/Then** shape
  (a bullet that isn't G/W/T-shaped fails the reviewer's testability check).
- **`## Independent Test`** — one line: "this Epic is verifiable standalone by
  <observable test> and delivers <value> without any not-yet-built Epic."
- **`## Covers`** — the requirement ids this Epic satisfies, e.g. `US-2, AC-4,
  AC-5, SM-1`. Drives `_coverage.md` and per-Epic traceability.
- **References** — source-anchored `[Source: <path>#<Section>]` citations when
  code-scan ran (was: bare paths). VI parent link `[[<VI-KEY>]]` unchanged.
- **`[NEEDS CLARIFICATION: <specific question>]`** — inserted inline wherever
  the writer genuinely cannot infer a detail from the VI/code sources, INSTEAD
  of silently guessing. **Cap 3 per Epic**; priority **dependencies > acceptance
  criteria > scope**; **never** on Goal or Business value (those must be
  inferable — an un-inferable goal signals a broken VI, a different problem).
- **`- ARD deviation: [AD-N] — <what> — <why> — flag: architect`** — recorded
  in the Epic draft (never in the ARD) when an Epic must not honor a VI-level
  `AD-N`.

**Pre-draft dedup pre-flight:** before drafting, enumerate the existing linked
Epics' themes; for each proposed new Epic that overlaps, report
`theme X already covered by <KEY> → skip | merge` in the writer's `notes`
(makes today's implicit non-duplication explicit and cheap; SpecKit dedup-before-
create pattern).

**Sizing/sequencing heuristic** (writer + Phase 2 plan): prefer *fewer, larger*
Epics when direction is validated; split only at a genuine risk / feedback-loop
boundary; propose an ordering in which no Epic depends on a later one.

**Writer contract additions:**
- input handoff gains `requirements[]`, `applicable_ard` (or absent),
  `existing_epic_themes`.
- returns `clarifications_needed: [{epic, section, question, suggested_answer}]`
  (empty when none) and `coverage_file` (the `_coverage.md` path written).

## 6. `_coverage.md` format

Written by `epic-writer` into `output_dir` (co-located with the Epic drafts),
underscore-prefixed so it sorts above the Epic files and is unmistakably NOT a
Jira Epic (never pasted into Jira; a PE decomposition-completeness aid).

```markdown
# Requirement coverage — <VI-KEY>

_source: native | derived_
**Roll-up: READY | NEEDS WORK | NOT READY — N/M requirements covered (P%), K gaps**

| Req  | Type      | Text (short)        | Covered by                          | Status |
|------|-----------|---------------------|-------------------------------------|--------|
| US-1 | story     | …                   | Epic: <slug-a> (new); FOO-12 (exist)| ✅     |
| AC-3 | criterion | …                   | —                                   | ❌ gap |
```

- Rows = the passed `requirements[]`.
- "Covered by" counts **existing linked Epics + new drafts**.
- Roll-up verdict: `READY` (0 gaps), `NEEDS WORK` (≥1 gap, none critical),
  `NOT READY` (writer/reviewer judges the gaps fundamental). `P% = covered/total`.
- `❌ gap` rows are what the reviewer flags (§7).
- **Focus mode (`<VI> <Epic>`).** When Phase 3 set a `focus_key`, the writer
  re-drafts only that Epic, but `_coverage.md` stays **VI-holistic** —
  recomputed across all existing linked Epics + the re-drafted focus Epic — so
  the matrix and roll-up never regress to a single-Epic view. The reviewer's
  per-Epic dimensions still apply only to the focus file; the coverage dimension
  is evaluated holistically.

## 7. Reviewer (epic-reviewer) dimensions

Existing dimensions unchanged except as noted. New/upgraded:

- **Requirement coverage (new).** Verify `_coverage.md` against the passed
  `requirements[]`: every `❌ gap` (a requirement no existing-or-new Epic
  covers) → **MAJOR** (a real decomposition gap, but the PE may knowingly defer
  scope — surfaced, not auto-BLOCK). A `Covers` id that isn't in `requirements[]`
  → MINOR (stale reference).
- **Epic independence (new).** No-forward-dependency: an Epic that cannot deliver
  its value without a not-yet-existing Epic → **MAJOR** (resequence/merge). Uses
  the `## Independent Test` + `## Dependencies` sections.
- **Terminology drift (new, internal-only).** Inconsistent naming of the *same
  concept* across the Epic batch → **MINOR/NIT**. Scoped to internal cross-Epic
  consistency — corporate terminology vs the style guide is `dt-style-checker`'s
  job (Phase 6.1), not this dimension.
- **Unresolved `[NEEDS CLARIFICATION]`** → **BLOCKER** (under structural
  integrity). By Phase 7 these are only the markers the user *chose* to leave
  unresolved in Phase 6.2.
- **ARD-conformance (conditional).** Only when `applicable_ard` is passed
  (else the dimension is skipped entirely — no-regression). An Epic violating a
  VI-level `AD-N` **without** a matching `- ARD deviation: … flag: architect`
  line → **BLOCKER**; **with** one → allowed-but-flagged. Mirrors `spec-reviewer`.
- **Goal clarity (upgraded).** Add a named **anti-pattern list** (technical-
  milestone titles — "Database Setup", "API Development", "Infrastructure Setup"
  ❌ — vs user-value ✅) + good/bad example pairs, and a **filler/"theater"
  check** (boilerplate business-value, vague untestable ACs) folded into the
  relevant dimensions.

Reviewer brief (Phase 7) gains: `requirements[]`, the `_coverage.md` path, and
`applicable_ard` (or omitted).

## 8. `commands/epics.md` wiring

- **New Phase 2.5 — Resolve applicable ARD (optional).** Cite
  `references/ard-resolution.md` with `vi = jira_key`, **`epic: null`** (Epics
  don't exist yet → VI-level ARD only), `$SPECS_PATH`. `status: none` (including
  `$SPECS_PATH` unset/unresolvable) → **skip, byte-identical to today**.
  `status: found` → carry `invariants` + `guidance_summary` forward to the
  writer (respect during drafting) and the reviewer (`applicable_ard`). Mirrors
  `/specify` Phase 2.5.
- **Phase 3.** Carry `requirements[]` (+ `requirements_source`) forward from
  `jira-reader`.
- **Phase 6 handoff** gains `requirements[]`, `applicable_ard`,
  `existing_epic_themes`. Writer now also emits `_coverage.md`.
- **New Phase 6.2 — Resolve clarifications.** If `clarifications_needed[]` is
  non-empty, one batched prompt — per marker: *use writer's recommended answer /
  type your own / leave unresolved* — fold answers into the drafts (Edit inline,
  or re-dispatch the writer once), then continue. Unresolved-by-choice markers
  stay in the drafts and become reviewer BLOCKERs. If empty, this phase is a
  silent no-op.
- **Phase 6.1 dt-style-checker** — sharpen the brief to emphasize **terminology
  and customer-facing captions/labels/messages/text** (still `doc_type: epic`;
  still non-gating). Already-wired; this is a brief edit only.
- **Phase 7 reviewer brief** — add `requirements[]`, `_coverage.md` path,
  `applicable_ard`. Marker-BLOCK handling: because 6.2 already resolved/deferred
  markers, remaining marker-BLOCKERs are user-chosen — the existing Phase 7
  BLOCK escalation handles them (no doc-fixer attempt on a genuine unknown).
- **Phase 9 report** — add sections: **Requirement coverage** (roll-up verdict +
  `❌ gap` list + `_coverage.md` path), **Clarifications** (resolved / deferred),
  **ARD conformance** (verdict + any deviation lines) — the ARD section is
  omitted entirely when `status: none`.
- **Invariants** — add: ALWAYS write `_coverage.md` to `output_dir`; ALWAYS run
  the Phase 6.2 gate when markers exist; ARD steps are additive and guarded on
  `status: found`.

## 9. `references/ard-resolution.md`

Additive doc edits only: add `/epics` to the citing list (line ~5) and a
`/epics` bullet to the informative Consumers list — "`/epics` — VI-level `AD-N`
= inherited invariants for the drafted Epics; deviations → an
`- ARD deviation: …` line in the Epic draft + the Phase 9 report."

## 10. No-regression

- **ARD:** `status: none` ⇒ no prompt, no extra output, no reviewer dimension —
  strictly additive, guarded on `found` (matches `/specify`).
- **Coverage:** a well-formed VI always yields the matrix; a degraded VI
  degrades to a coarse `derived` matrix — never fails the run.
- **Clarifications:** no markers ⇒ Phase 6.2 is a silent no-op.
- **Byte-identical elsewhere:** siblings `dt-style-guide` (0.2.2) +
  `obsidian-llm-wiki` (0.3.1) untouched; `/vuln` + `/upgrade` untouched;
  `document.md` untouched; command/subagent counts unchanged (19/29); the
  marketplace description strings ("Nineteen…"/"Twenty-nine…") unchanged.
- `/epics` still **never branches, never commits**, never writes into
  `jira-products/`, `jira_export_root`, or the cwd.

## 11. Verification (structural — no test framework)

- `python3 -c json.load` parses both manifests; version 2.21.0 in
  `plugin.json` + `marketplace.json` dev-workflows entry.
- grep anchors: `requirements[]` in `jira-reader.md`; `Independent Test`,
  `## Covers`, `NEEDS CLARIFICATION`, `ARD deviation` in `epic-writer.md`;
  the new dimensions + `applicable_ard` in `epic-reviewer.md`; `Phase 2.5`,
  `Phase 6.2`, `_coverage.md` in `epics.md`; `/epics` in `ard-resolution.md`
  citing + consumers lists.
- `git diff --stat main` shows only: 4 agents/command files + `ard-resolution.md`
  + 2 manifests + CHANGELOG. `document.md`, `vuln*`, `upgrade*`, and the two
  sibling plugins show **no** diff.
- CHANGELOG prepends `## [2.21.0] — 2026-07-12`.

## 12. Files changed

- `agents/jira-reader.md` — `requirements[]` output field + extraction/fallback.
- `agents/epic-writer.md` — template additions, markers, pre-draft dedup,
  ARD-respect, sizing heuristic, `_coverage.md`, contract I/O.
- `agents/epic-reviewer.md` — new/upgraded dimensions + brief inputs.
- `commands/epics.md` — Phase 2.5, 6.2, 6.1 emphasis, handoff/brief/report/
  invariants.
- `references/ard-resolution.md` — add `/epics` (additive).
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — 2.21.0.
- `CHANGELOG.md` — 2.21.0 entry.

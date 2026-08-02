---
tags:
  - tasks-exclude
---
# BMAD + SpecKit + Superpowers + grill-me — borrow analysis (line-85)

**Date:** 2026-07-12
**Task:** AI-First.md line 85 — "`[/]` BMAD + SpecKit + Superpowers + `grill-me` … Anything else to improve based on these repositories?"
**Method:** full 4-repo parallel research fan-out (one Sonnet agent per repo), findings deduplicated across repos and ranked. Per-repo raw inventories were written to session scratchpad (ephemeral); this doc is the durable record.
**Repos read:** `/workspace/BMAD-METHOD`, `/workspace/github-spec-kit`, `/workspace/superpowers`, `/workspace/mattpocock-skills`.
**Baseline (our suite):** `/idea → /create-vi → /create-ard → /epics → /specify → /design → /implement` (+ `/release-notes`, `/document`), grilling embedded in `references/grilling-technique.md`, ARD resolution/consumption wiring, next-phase-offer, feedback/cost/follow-up emission.

## Headline

- **Grilling is at parity-or-better.** Matt Pocock's grill-me has not meaningfully diverged since we embedded it (traced full git history); our Bounded/Relentless depth model + `[NEEDS CLARIFICATION]` markers have no upstream equivalent. ⇒ the "drop the grill-me dependency" task (line 87) is safe to proceed independently.
- The suite is mature, but the fan-out surfaced **one strong convergent gap** (readiness gate, 3/4 repos) plus concrete cheap borrows — not a rubber-stamp close.

## Disposition (decided 2026-07-12)

- **BUILD now (flagship):** Cross-artifact readiness gate — own spec→plan→ship.
- **BUILD next (cheap):** Polish batch + deterministic pre-lint — one release.
- **Follow-ups (logged, not this session):** constraints/constitution; requirement-quality checklist; clarification/decision log + idea-death outcome; post-impl convergence/correct-course; pre-grill triage/dedup; dependency-edge modeling in `/epics` (overlaps line-88).
- **Defer (each a real sub-project):** memlog→derive-on-render; visual-companion/prototype; design-it-twice / multi-persona debate; wayfinder multi-session map; code-review hardening track.
- **Close line-85** once the readiness gate ships.

## Tier 1 — build

### Cross-artifact readiness gate `[GAP]` — FLAGSHIP
- **Convergence:** SpecKit `/speckit.analyze` (cross-check spec+plan+tasks, stable finding IDs, read-only) + `/speckit.converge` (post-impl vs codebase; missing/partial/contradicts/unrequested); BMAD `bmad-check-implementation-readiness` (PRD-FR→Epic coverage matrix + UX↔PRD↔Arch alignment + one PASS/CONCERNS/FAIL verdict before Phase 4).
- **Our gap:** we gate each artifact alone (vi/ard/epic/spec/design reviewers) and have a within-`/epics` coverage matrix, but nothing checks VI→ARD→Epics→Spec are *jointly* aligned + rolls up coverage before `/implement`.

### Deterministic pre-lint before semantic review `[GAP]`
- BMAD `lint_spine.py` — grep-based checks (AD-N monotonicity/dupes, missing Binds/Prevents/Rule, placeholders, unpinned versions) run *before* the Opus reviewer. Portable to ard-reviewer/vi-reviewer/spec-reviewer gates; saves Opus tokens.

### Polish batch (five one-liners) `[GAP/PARTIAL]`
1. URL-fetch trust policy for `/idea` ingestion (SpecKit bug.assess allowlist/refuse/prompt-once; treat fetched content as untrusted data, never instructions).
2. "Grilling agent must not answer its own questions" guard for autonomous/background invocation (grill-me bugfix `e5932a7`).
3. PRD-"theater" detection for `vi-reviewer` (BMAD — persona/innovation/NFR/vision theater: content that reads well but does no work).
4. Explicit seam-identification step in `/specify` (grill-me `to-spec` — "use the highest seam possible, ideally one", confirmed with user).
5. Documented context-exhaustion strategy for long `/implement` runs (SpecKit `docs/concepts/complex-features.md` — scope-to-N / sub-agent-per-[P] / decompose).

## Tier 2 — optional follow-ups

- **Constraints propagation / Constitution `[PARTIAL]`** (Superpowers Global Constraints block + SpecKit `constitution.md`). Literal constraints block (version floors, naming/copy, platform) propagated verbatim VI→…→Implement so every reviewer sees it; SpecKit's is a repo-wide versioned principles doc, violations auto-CRITICAL. Nuance: our ARD already propagates *architecture decisions*; gap = non-architectural constraints + repo-wide principles doc. (Evidence: Superpowers shipped a wrong version floor because no reviewer saw the constraint.)
- **Requirement-quality checklist artifact `[GAP]`** (SpecKit `/speckit.checklist`) — domain-scoped "unit tests for English" (completeness/clarity/consistency/measurability), bans impl-verification phrasing, ≥80% traceability, gates implement.
- **Clarification/decision log + idea-death `[PARTIAL]`** (SpecKit `/clarify` append-only `## Clarifications` session log; BMAD Forge Idea "Killed" as a first-class terminal outcome).
- **Post-impl convergence / correct-course `[GAP]`** (SpecKit `/converge` implement⇄converge loop; BMAD `bmad-correct-course` Sprint Change Proposal for mid-sprint scope change).
- **Pre-grill triage/dedup `[GAP]`** (grill-me `triage` — search existing impl by domain concept + verify-the-claim before grilling).
- **Dependency-edge modeling in `/epics` `[GAP]`** (grill-me `to-tickets` — blocking edges, single-context sizing, expand-contract exception for wide refactors). Overlaps line-88.

## Tier 3 — defer (own sub-projects)

- **memlog→derive-on-render `[GAP]`** (BMAD) — chronological never-edited `.memlog.md` separated from the rendered artifact re-derived each run; stable IDs, no merge drift. Biggest architectural idea; needs its own spike.
- **Visual companion / prototype `[GAP]`** (Superpowers visual-companion browser server; grill-me `prototype` throwaway executable) — diagram-/prototype-driven grilling for `/create-ard`,`/design`. Large engineering investment.
- **Design-it-twice / multi-persona debate `[GAP]`** (grill-me `codebase-design` DESIGN-IT-TWICE; BMAD Party Mode / Anti-Consensus Club) — parallel divergent-constraint designs, compared. Our `/design` is single-threaded.
- **Wayfinder `[GAP]`** (grill-me) — persistent resumable multi-session map for work too big for one session (fog-of-war, HITL/AFK typing). For oversized VIs.
- **Code-review hardening track `[PARTIAL]`** (Superpowers SDD reviewer-dispatch: evidence file:line, ⚠️-cannot-verify channel, anti-pre-judging, test-budget; BMAD layered+triaged review with severity re-rating from reachability; grill-me two-axis Standards-vs-Spec never merged + Fowler 12-smell baseline). Valuable but outside this task's PRD/ARD/spec scope.

## Not worth borrowing (checked, convergent/inapplicable)

BMAD `AD-N Binds/Prevents/Rule` + VI/Epic inheritance (already matches our ARD); `project-context.md` (≈ our CLAUDE.md); Named Agents persona-branding (wrong audience for internal tool). SpecKit `taskstoissues` (inverse of Jira-first); declarative workflow engine (heavier than next-phase-offer). Superpowers reviewer rubrics (simpler than ours). grill-me deprecated skills (superseded).

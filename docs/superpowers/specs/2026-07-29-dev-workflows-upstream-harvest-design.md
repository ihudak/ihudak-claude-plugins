# dev-workflows upstream-harvest — design spec (2026-07-29)

> Adapts 8 improvements harvested from four upstreams (SpecKit, Matt Pocock skills, superpowers,
> BMAD) into the `dev-workflows` plugin. Source analysis: `docs/superpowers/harvest/{INDEX,mattpocock,
> superpowers,bmad,speckit}.md`. These are **additive adaptations judged for fit** to a Jira-driven,
> Opus-gated, specs-repo pipeline — not mechanical upstream syncs. Nothing here is verbatim-vendored.

**Goal:** Close real capability gaps (spec→code drift, bug-diagnosis discipline, test-quality) and
sharpen existing artifacts (ambiguity taxonomy, plan-conflict handling, code smells, seam vocab,
plan hygiene), then port to the Copilot mirror + the mgd Claude marketplace, with all doc surfaces
in sync.

**Architecture:** Edit the **canonical** plugin
`ai-tools/ihudak-claude-plugins/plugins/dev-workflows` in two waves (Tier 1 → Tier 2), then a single
port pass to the two downstream copies. All changes are additive, backward-compatible, single-purpose
edits to agents/references/one command; one new reference file; no new agents, no new phases, no new
infrastructure.

## Global constraints

- **Pushes are HELD** for explicit user confirmation before each push (all three repos).
- Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- `specification-format.md` is a **frozen snapshot** (imported from `mgd-specifications`) — do NOT edit
  it. Coverage additions sourced from it land in `spec-reviewer.md` instead.
- `design-format.md` is **net-new / no import source** — freely editable.
- Every new behavior is **conditional/opt-in**: it fires only when its trigger is present (a spec/design
  in scope, a bug-shaped task, a plausible-to-game metric) and is a no-op otherwise. Direct-mode and
  SIMPLE/MODERATE runs stay byte-compatible unless a change explicitly says otherwise.
- **Shared seam vocabulary** is defined once (in `design-format.md`) and cross-referenced from
  `bug-diagnosis.md` — never duplicated.

---

## Wave 1 — Tier 1 (capability gaps)

### Item 1 — Spec→code "converge" conformance check

**Gap:** nothing verifies the *shipped code* satisfies every in-scope `[Uxx]`/`[ACxx]`/`[TCxx]` in
`specification.md`/`design.md`. `design-reviewer` checks spec→design (pre-code); `readiness-reviewer`
checks Jira-status↔artifact-presence; neither checks design→built-code.

**Design (gate in `code-review`, anchored by `risk-planner` tags):**

- `agents/risk-planner.md` — new Planning-discipline bullet: **when the brief carries a
  `specification.md`/`design.md`**, annotate each `### Steps` entry with the requirement ID(s) it
  implements, e.g. `1. <step> — implements [AC-3], [TC-7]`. Optional; when no spec/design is in the
  brief (direct mode), skip silently.
- `agents/code-review.md` — new **conditional 10th dimension "Spec/design conformance"**, active only
  when the caller passes a new optional input `applicable_spec` (the in-scope spec/design paths + the
  in-scope ID list). Structurally parallel to the existing conditional ARD dimension. For each in-scope
  ID, trace it against the diff and classify: `satisfied` / `missing` / `partial` / `contradicts`.
  Severity mirrors the ARD dimension's recorded-deviation logic:
  - `contradicts` (code does the opposite of a requirement) → **BLOCKER**
  - `missing`, no recorded deferral → **MAJOR**
  - `missing`, with a recorded deferral (the plan's `Out of scope`, or an explicit deferral note) →
    **MINOR** flagged note
  - `partial` → **MINOR**
  - Explicitly scoped design→**code**; it must NOT re-perform `design-reviewer`'s spec→design
    traceability. Add a `#### Spec/design conformance` findings block + a one-line coverage summary
    (`N satisfied / M missing / …`) to the output shape. Add `applicable_spec` to the Inputs section.
- `commands/implement.md`:
  - When Jira mode resolved a `specification.md`/`design.md` in scope, extract the in-scope requirement
    IDs (reuse the specs already resolved in Phase 0). Pass the spec/design to `risk-planner`
    (Phase 2B brief) for step-tagging, and pass `applicable_spec` to `code-review` (Phase 3B step 6
    dispatch).
  - Phase 5 report: new `### Spec/design conformance` line (coverage summary + any `missing`/`partial`/
    `contradicts`). Unresolved `missing`/`contradicts` gaps are written back as `- [ ]` notes on the
    spec/design (the same escalation `/design` uses via `## Engineering review`) — never silently
    dropped, never auto-invented as new Jira work.
  - New invariant recorded in the "Invariants" block.
- **Scope note:** the gate runs only where `code-review`+`risk-planner` run (SIGNIFICANT/HIGH-RISK). A
  design-driven `/implement` is SIGNIFICANT+ in practice; SIMPLE/MODERATE conformance is deliberately
  out of scope (drift on a trivial change is low-value to gate).

### Item 2 — `references/bug-diagnosis.md` (new) — bug-diagnosis discipline

**Gap:** `/implement` has no structured discipline for bug-shaped SIGNIFICANT/HIGH-RISK tasks — no
red-capable repro before hypothesizing, no ranked hypotheses, no instrumentation-cleanup gate.

**Design (new reference, folded into `risk-planner`):**

- **New `references/bug-diagnosis.md`** — feedback-loop-first discipline:
  1. Build a **red-capable, deterministic, fast, agent-runnable repro** *before* hypothesizing; minimize
     it to the smallest failing case.
  2. Rank **3–5 falsifiable hypotheses**, each stating its prediction and how it would be falsified.
  3. **`[DEBUG-xxxx]`-tagged instrumentation** with a mandatory **cleanup gate** — every tag is removed
     before the change is finalized.
  4. Add a regression test only at a **correct seam** (cross-reference the seam vocab in
     `design-format.md`, Item 7); *"no correct seam exists"* is itself a recorded finding, not a reason
     to bolt a test onto the wrong seam.
  5. Evidence-first: never claim fixed until the repro goes green (aligns with
     `superpowers:verification-before-completion`).
- `agents/risk-planner.md` — when the caller sets `task_shape: bug`, the plan **leads `### Steps` with a
  repro step** and includes a `### Hypotheses (ranked)` section (3–5 falsifiable). Cite
  `bug-diagnosis.md`. The **existing plan-approval gate** surfaces the hypotheses — no new interrupt.
- `commands/implement.md`:
  - Detect **bug-shaped** tasks heuristically (defect signals: fix / bug / regression / broken /
    incorrect / wrong-output / crash). When ambiguous, ask (existing Phase 1 `choices` machinery).
  - Phase 2B: pass `task_shape: bug` + cite `bug-diagnosis.md` to `risk-planner`.
  - Phase 3B: implement repro-first (red), instrument with `[DEBUG-xxxx]`, and **strip all `[DEBUG-xxxx]`
    before the diff is captured** for Opus review (a Phase 3B step-5 checklist item). `code-review` flags
    any leftover `[DEBUG-xxxx]` as a finding.
  - SIGNIFICANT/HIGH-RISK only; for SIMPLE/MODERATE bug fixes `bug-diagnosis.md` is guidance-only (no
    enforcement).

### Item 3 — `agents/test-writer.md` quality gate

**Gap:** the embedded test discipline names no anti-patterns; a writer could produce a test that looks
like coverage but never fails on a real regression.

**Design:** in step 5's constraints, add four named anti-patterns —
- **Falsifiability:** before writing each test, name the exact production change that would make it fail;
  if you cannot, it is a change-detector — do not write it.
- **No mirror-assertion:** never compute the expected value using the same logic as the code under test.
- **No change-detector:** assert the behavior that depends on a value, not a constant or private
  structure for its own sake.
- **Production methods only:** test-only helpers/cleanup live in test utilities, never in production
  classes.

Add a new **step 6 — mutation self-check** (renumber "Verify syntax" → 7): for each test, mentally mutate
the production code (flip a condition, drop a line) and confirm the test would catch it; strengthen if
not. Add a matching Hard rule. **Output shape unchanged** (discipline is internal — no report bloat).

---

## Wave 2 — Tier 2 (sharpeners)

### Item 4 — Unified ambiguity taxonomy (altitude-aware, all grills)

- `references/grilling-technique.md` — new `## Ambiguity taxonomy` section: gap-categories the grill
  scans to feed the existing **Impact×Uncertainty** ranking. Not a user-facing menu; adds **no mandatory
  questions** (bounded callers still cap at ≤5). Altitude-scaled:
  - **All altitudes:** terminology-precision forcing move (name an overloaded term — user/buyer/payer —
    force a precise choice); pre-mortem / assumption-audit; second-order effects.
  - **Product (`/idea`, `/create-vi`):** unstated quality *expectations* + overloaded terms, framed as
    product outcomes (not engineering NFRs).
  - **Engineering (`/specify`, `/design`):** full NFR set (performance, scalability, reliability,
    observability, security/compliance); integration / external-dependency gaps; implicit-enum-branch
    (an N-valued field where only some values are specified).
- `agents/spec-reviewer.md` — Coverage cross-stage check gains: a systematically-missed **NFR category**
  (feature plainly implies a perf/observability/compliance criterion, none present) → finding; an
  **implicit enum branch** (AC/TC special-cases some values of an N-ary field, others unmentioned with no
  explicit exclusion) → generalizes the existing paired-state check → BLOCKER/MAJOR.
- `references/specification-format.md` — **untouched** (frozen).

### Item 5 — `agents/review-fixer.md` plan-conflict disposition

- New Deferred-reason category **`plan-conflict`** ("the approved plan explicitly mandated this; the
  finding contradicts the plan — needs human ruling"). Fix method: a finding that contradicts the
  approved plan is **never** auto-fixed against the plan and **never** buried in generic "other" — flag
  `DEFERRED — plan-conflict` and set `Stop condition flag → NEEDS HUMAN`. Update the Deferred output enum.
- `commands/implement.md` Phase 3B step 7 — one sentence: a `plan-conflict` deferral is surfaced to the
  user **immediately** with a `choices` prompt (revise the plan / apply the fix against the plan), not
  folded into the BLOCK-still-BLOCK path.

### Item 6 — `agents/code-review.md` Fowler 12-smell floor

- Architectural-consistency dimension gains the 12 named Fowler smells (Mysterious Name, Duplicated Code,
  Feature Envy, Data Clumps, Primitive Obsession, Repeated Switches, Shotgun Surgery, Divergent Change,
  Speculative Generality, Message Chains, Middle Man, Refused Bequest) as a **judgment-call floor** —
  reported at MINOR/NIT (not hard violations), and **explicitly overridden by a documented repo
  standard**. No parallel-subagent split. *(Second edit to `code-review.md`, after Item 1.)*

### Item 7 — deep-module / seam vocab (`design-format.md` + `design-reviewer.md`)

- `references/design-format.md` (`## Architecture & components` + `## Seams`): define the shared
  vocabulary — **deep module** (small interface, substantial implementation — favor depth), the
  **deletion test** (would removing this module concentrate complexity or merely relocate it?), the
  **two-adapters heuristic** (one hypothetical adapter = a speculative seam; introduce a seam only when a
  second real consumer exists — YAGNI for seams). This is the canonical definition Item 2's
  `bug-diagnosis.md` cross-references.
- `agents/design-reviewer.md` — extend the "Seam / test-strategy soundness" check: a **shallow module**
  (interface nearly as large as its implementation) or a **speculative seam** (justified by a single
  hypothetical adapter) → MAJOR/MINOR, giving the reviewer a citable standard instead of ad-hoc judgment.

### Item 8 — risk-planner no-placeholders + counter-metrics + freebie

- `agents/risk-planner.md` — new Planning-discipline bullet **No placeholders**: before returning, scan
  the plan for "TBD" / "add proper error handling" / "similar to step N" / vague non-code instructions,
  and replace with concrete content. *(Second edit to `risk-planner.md`, after Items 1 & 2.)*
- `references/vi-format.md` (`## Success Metrics`) — optional **counter-metrics** (`[SM-C1]` — a metric
  explicitly named as *not* to optimize/game, counterbalancing a primary SM). `agents/vi-reviewer.md` — a
  Primary SM with plausible gaming and no counter-metric → NIT/MINOR (non-blocking).
- **Freebie:** `references/grilling-technique.md` line 13 "design tree" → "decision tree" (removes the
  clash with the `design.md` artifact). Rides along with Item 4's edit to the same file — **one task**.

---

## Port matrix (single port pass, after both canonical waves land)

Canonical: `ai-tools/ihudak-claude-plugins/plugins/dev-workflows`.

| Canonical file | → Copilot (`ihudak-copilot-plugins/dev-workflows`) | → mgd (`mgd-claude-plugins/plugins/dev-workflows`) |
|---|---|---|
| `agents/*.md` (code-review, risk-planner, test-writer, review-fixer, design-reviewer, spec-reviewer, vi-reviewer) | `agents/*.md` — **straight port** | `agents/*.md` — **straight port** |
| `references/{grilling-technique,design-format,vi-format}.md` | `skills/_shared/*.md` — **straight port** | `references/*.md` — **straight port** |
| `references/bug-diagnosis.md` (NEW) | `skills/_shared/bug-diagnosis.md` — **new file** | `references/bug-diagnosis.md` — **new file** |
| `commands/implement.md` | `skills/implement/SKILL.md` — **CONVERSION** (Copilot phrasing, keyword-triggered; re-express the converge wiring, bug-shaped detection, plan-conflict surfacing) | `commands/implement.md` — **straight port** |

- **mgd** is a straightforward same-structure Claude Code copy — verify it carries no mgd-specific
  divergence in the touched files before overwriting; if it does, merge rather than clobber.
- **Copilot** `${CLAUDE_PLUGIN_ROOT}` path references have their Copilot-equivalent form — preserve
  whatever convention the existing copilot files already use; do not introduce Claude-only path syntax.

## Doc-surface sync (per the user's explicit ask)

For **each** of the three repos, in the port pass:

- **`marketplace.json`** — bump the `dev-workflows` `version` (claude `2.37.0 → 2.38.0`; copilot
  `2.5.0 → 2.6.0`; mgd — its own current value, minor-bump). The long description does not need
  re-listing (no new commands/agents), but confirm it isn't contradicted.
- **Per-plugin `README.md`** — add `bug-diagnosis.md` to any reference listing; note the converge /
  spec-conformance behavior and bug-diagnosis discipline if the README enumerates behaviors.
- **`CLAUDE.md`** (claude repos) / **`.github/copilot-instructions.md`** (copilot repo) — add a
  `bug-diagnosis.md` entry to the reference-doc section (it's a documented reference `/implement`
  consults, like `source-truth.md`); light touch to the workflow map for the converge + bug-diagnosis
  behaviors. Minimal, additive — do not rewrite sections.
- **`CHANGELOG.md`** (per plugin, where present) — one entry summarizing the harvest.

## Execution

1. **SDD** (`superpowers:subagent-driven-development`) on the canonical plugin, fresh implementer per
   task + task review + final whole-branch review.
2. **Wave 1** (Items 1–3) → review checkpoint → **Wave 2** (Items 4–8). `code-review.md` and
   `risk-planner.md` each get a Wave-1 then a Wave-2 edit as **separate tasks/commits**.
3. **Single port pass** (Copilot + mgd) once both waves land on canonical, followed by the
   **doc-surface sync** + version bumps + CHANGELOG.
4. **Hold all pushes** for explicit user confirmation (3 repos).

## Out of scope (deliberately not adopting — see INDEX.md §"NOT adopting")

BMAD/SpecKit CLI+template scaffolding, `constitution`, governance presets, extension hooks; superpowers
SDD ledger / plan-scoped workspace / 5-round fix-breaker; BMAD `bmad-review` generic lens engine; Matt's
git-push-blocking hook; BMAD PRD-coach "never recommend an answer" (a deliberate disagreement with our
recommend-first grill); the batch-grill-me denser-round mode; the `context-management.md` "hand off by
file" adjacent item (a larger multi-agent-dispatch refactor, tracked separately).

## Open questions

None — the three design forks were resolved with the user (converge → gate in code-review; bug-diagnosis
→ folded into risk-planner; taxonomy → altitude-aware across all grills). Additive items confirmed.

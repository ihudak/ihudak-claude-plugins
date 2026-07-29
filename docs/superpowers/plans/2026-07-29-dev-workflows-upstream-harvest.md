# dev-workflows upstream-harvest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement
> this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adapt 8 harvested upstream improvements into the `dev-workflows` plugin (canonical Claude
marketplace), then port to the Copilot mirror + the mgd Claude marketplace, with all doc surfaces synced.

**Architecture:** Additive, backward-compatible edits to 7 agents, 3 references, 1 command; 1 new
reference file. Two implementation waves on the **canonical** plugin
(`ai-tools/ihudak-claude-plugins/plugins/dev-workflows`), then one port pass (mgd straight copy; Copilot
hybrid conversion) + a doc-surface sync. No new agents, no new phases, no new infrastructure.

**Tech Stack:** Markdown agent/reference/command files; Claude Code plugin manifests
(`.claude-plugin/*.json`); GitHub Copilot plugin manifests (`.plugin/*.json`, `skills/*/SKILL.md`).

**Design spec:** `docs/superpowers/specs/2026-07-29-dev-workflows-upstream-harvest-design.md`
(source analysis: `docs/superpowers/harvest/{INDEX,mattpocock,superpowers,bmad,speckit}.md`).

## Global Constraints

- **Pushes are HELD** for explicit user confirmation before each push (all three repos). The plan
  produces commits only; never `git push` without the user's go-ahead.
- Commit trailer (every commit): `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Do **NOT** edit `references/specification-format.md` — it is a frozen snapshot from `mgd-specifications`.
  Coverage additions sourced from it land in `agents/spec-reviewer.md`.
- Every new behavior is **conditional/opt-in** — a no-op when its trigger is absent. Direct-mode and
  SIMPLE/MODERATE `/implement` runs stay byte-compatible except where a task explicitly changes them.
- The **seam vocabulary** is defined once in `references/design-format.md` (Task 8) and cross-referenced
  from `references/bug-diagnosis.md` (Task 2) — never duplicated. Task 2's cross-reference points at
  `design-format.md`'s existing `## Seams` section (which already exists; Task 8 enriches it).
- Preserve LF line endings and the repo's prose convention (never hard-wrap prose — one unbroken line
  per paragraph, per `references/prose-formatting.md`).
- Work on a feature branch off `main` in the canonical repo before any edit (repo is currently clean on
  `main`).

## Verification model (markdown, not code)

There is no unit-test cycle. Each task's verification is:
1. **Read-back** — re-read each edited file end-to-end; confirm the edit landed and the section still
   parses/flows.
2. **Consistency grep(s)** — the concrete `grep` commands named per task (e.g. a new input name appears
   in both producer and consumer; no stale term remains after a rename).
3. **Manifest validation** — after any structural/manifest change, run `claude plugin validate` in the
   canonical repo (and confirm the Copilot manifest parses as JSON in the port pass).
The task-review gate (spec compliance + quality) runs per SDD after each task.

## File Structure

**Wave 1 (canonical `plugins/dev-workflows/`):**
- `agents/risk-planner.md` — Item 1 (step ID-tagging) + Item 2 (`task_shape: bug` handling). Edited
  again in Wave 2 Task 9 (no-placeholders).
- `agents/code-review.md` — Item 1 (10th dimension "Spec/design conformance" + `applicable_spec` input).
  Edited again in Wave 2 Task 7 (Fowler smells).
- `references/bug-diagnosis.md` — Item 2 (**new file**).
- `commands/implement.md` — Item 1 + Item 2 wiring. Edited again in Wave 2 Task 6 (plan-conflict surface).
- `agents/test-writer.md` — Item 3 (quality gate).

**Wave 2 (canonical):**
- `references/grilling-technique.md` — Item 4 (ambiguity taxonomy) + freebie rename + terminology move.
- `agents/spec-reviewer.md` — Item 4 (NFR + implicit-enum-branch coverage).
- `agents/review-fixer.md` + `commands/implement.md` — Item 5 (plan-conflict).
- `agents/code-review.md` — Item 6 (Fowler smells).
- `references/design-format.md` + `agents/design-reviewer.md` — Item 7 (seam vocab).
- `agents/risk-planner.md` + `references/vi-format.md` + `agents/vi-reviewer.md` — Item 8.

**Wave 3 (port + docs):** mgd copy, Copilot conversion, doc-surface sync across all three repos.

---

## Wave 1 — Tier 1

### Task 1: Item 1 agents — converge contract (risk-planner tags + code-review dimension)

**Files:**
- Modify: `plugins/dev-workflows/agents/risk-planner.md`
- Modify: `plugins/dev-workflows/agents/code-review.md`

**Interfaces:**
- Produces: `code-review` gains an optional input **`applicable_spec`** = `{ spec_paths: [...], in_scope_ids: [Uxx/ACxx/TCxx...] }`, consumed by `implement.md` (Task 3).
- Produces: `risk-planner` step-tag format `N. <step> — implements [AC-x], [TC-y]`, consumed by
  `code-review`'s new dimension and read by `implement.md` (Task 3).

- [ ] **Step 1 — risk-planner: add the traceability-tag Planning-discipline bullet.**
  In `agents/risk-planner.md`, under `## Planning discipline`, add a new bullet **after** the
  "Minimise scope." bullet:
  ```markdown
  - **Trace to requirements (when a spec/design is in the brief).** If the brief carries a
    `specification.md`/`design.md`, annotate each `### Steps` entry with the requirement ID(s) it
    implements — e.g. `1. <step> — implements [AC-3], [TC-7]`. A step that implements no specific
    requirement needs no tag. When no spec/design is in the brief (direct mode), skip this silently.
  ```

- [ ] **Step 2 — code-review: register the `applicable_spec` input.**
  In `agents/code-review.md`, under `## Inputs`, immediately after the `applicable_ard` bullet, add:
  ```markdown
  - **`applicable_spec`** (optional) — the in-scope specification/design context, passed only by
    `/implement` (Jira mode) when a `specification.md`/`design.md` is in scope: `spec_paths` (absolute
    paths) + `in_scope_ids` (the in-scope `[Uxx]`/`[ACxx]`/`[TCxx]` list). Absent for `/vuln`,
    `/upgrade`, `/implement` direct mode, and when no spec/design exists — in which case the conditional
    Spec/design-conformance dimension (below) does not apply and is not mentioned.
  ```

- [ ] **Step 3 — code-review: add the 10th dimension.**
  In `## Review dimensions`, after dimension `9. ARD conformance`, add:
  ```markdown
  10. **Spec/design conformance** (conditional — only when `applicable_spec` is provided; otherwise this
      dimension does not apply — omit it silently) — trace each `in_scope_ids` requirement against the
      diff and classify it: `satisfied` / `missing` / `partial` / `contradicts`. This checks
      design→**code** — it does NOT re-verify spec→design traceability (that is `design-reviewer`'s
      pre-code job). Severity:
      - `contradicts` (the code does the opposite of a requirement) → `BLOCKER`.
      - `missing` with **no** recorded deferral → `MAJOR`.
      - `missing` **with** a recorded deferral (named in the plan's `Out of scope`, or an explicit
        deferral note in the brief) → `MINOR` flagged note.
      - `partial` → `MINOR`.
  ```
  In step 3 of `## Review method`, change "the conditional ninth" wording to cover both conditionals —
  replace `(plus the conditional ninth, **only** when `applicable_ard` is provided)` with
  `(plus the conditional ninth and tenth — dimension 9 only when `applicable_ard` is provided, dimension
  10 only when `applicable_spec` is provided)`.

- [ ] **Step 4 — code-review: add the output block.**
  In `## Output`, after the `#### ARD conformance (only if applicable_ard provided)` block, add:
  ```markdown
  #### Spec/design conformance (only if applicable_spec provided)
  - Coverage: [N satisfied / M missing / P partial / C contradicts]
  - [severity] `[ACxx]` - [missing | partial | contradicts] - [what the diff does vs. what the
    requirement demands]
  - _or_ "no findings — all in-scope requirements satisfied"
  ```

- [ ] **Step 5 — Verify + commit.**
  - Read both files end-to-end.
  - Run: `grep -n "applicable_spec" plugins/dev-workflows/agents/code-review.md` → expect ≥2 hits
    (Inputs + dimension + method + output). Run:
    `grep -n "Spec/design conformance" plugins/dev-workflows/agents/code-review.md` → expect ≥2 hits.
    Run: `grep -n "implements \[" plugins/dev-workflows/agents/risk-planner.md` → expect the new bullet.
  - `git add -A && git commit` (trailer). Message: `feat(dev-workflows): converge contract — risk-planner ID-tags + code-review spec/design-conformance dimension`.

### Task 2: Item 2 — bug-diagnosis reference + risk-planner bug-shape handling

**Files:**
- Create: `plugins/dev-workflows/references/bug-diagnosis.md`
- Modify: `plugins/dev-workflows/agents/risk-planner.md`

**Interfaces:**
- Produces: `risk-planner` accepts a brief hint **`task_shape: bug`**; when set, its plan leads `### Steps`
  with a repro step and adds a `### Hypotheses (ranked)` section. Consumed by `implement.md` (Task 3).

- [ ] **Step 1 — Create `references/bug-diagnosis.md`** with exactly this content:
  ```markdown
  # Bug-diagnosis discipline (embedded — shared reference)

  Feedback-loop-first discipline for **bug-shaped** SIGNIFICANT / HIGH-RISK tasks. Cited by
  `/implement` (Phase 2B) and followed by `risk-planner` when the caller sets `task_shape: bug`. Adapted
  from mattpocock `diagnosing-bugs`; aligns with `superpowers:verification-before-completion`.

  ## Principle — build the feedback loop before hypothesizing

  A bug fix is only as trustworthy as the loop that proves it. Establish a failing, observable loop
  first; only then reason about cause.

  ## Steps

  1. **Repro first.** Construct a **red-capable, deterministic, fast, agent-runnable** reproduction
     command that fails *because of this bug* — before forming any hypothesis. Minimize it to the
     smallest input/state that still fails. A bug you cannot reproduce on demand is not yet ready to fix.
  2. **Rank falsifiable hypotheses.** List **3–5** candidate causes, each stating (a) what it predicts
     you would observe and (b) the cheapest observation that would **falsify** it. Order by likelihood ×
     cheapness-to-test. A hypothesis you cannot falsify is not a hypothesis — drop it.
  3. **Instrument with tagged, removable probes.** Add temporary instrumentation tagged `[DEBUG-xxxx]`
     (a short unique token per probe). Test the ranked hypotheses against the repro. Every `[DEBUG-xxxx]`
     probe MUST be removed before the change is finalized (the `/implement` Phase 3B cleanup gate strips
     them before the review diff is captured).
  4. **Fix at the correct seam; regression-test there.** Land the fix and its regression test at the
     **correct seam** (see `${CLAUDE_PLUGIN_ROOT}/references/design-format.md` `## Seams` — prefer the
     highest seam that still isolates the behavior). If **no correct seam exists**, that is itself a
     finding — record it (the code needs a seam before it can be safely tested); do NOT bolt a test onto
     the wrong seam to manufacture green.
  5. **Evidence before the claim.** Never report the bug fixed until the repro from step 1 goes green.
  ```

- [ ] **Step 2 — risk-planner: add `task_shape: bug` handling.**
  In `agents/risk-planner.md` under `## Inputs`, add a bullet after "Current state":
  ```markdown
  - **`task_shape`** (optional) — `bug` when the caller classified the task as a defect fix. When
    `task_shape: bug`, follow `${CLAUDE_PLUGIN_ROOT}/references/bug-diagnosis.md`: lead `### Steps` with a
    red-capable repro step, and add a `### Hypotheses (ranked)` section (3–5 falsifiable causes) to the
    plan output. Absent/other → plan normally.
  ```
  In the `## Output` plan shape, add — immediately after the `### Approach` block — an optional section:
  ```markdown
  ### Hypotheses (ranked)   # include ONLY when task_shape: bug
  1. [cause] — predicts [observation]; falsified by [cheapest test]
  2. ...
  ```

- [ ] **Step 3 — Verify + commit.**
  - Read both files.
  - Run: `grep -n "task_shape" plugins/dev-workflows/agents/risk-planner.md` → expect ≥2 hits;
    `grep -n "DEBUG-xxxx" plugins/dev-workflows/references/bug-diagnosis.md` → expect the cleanup rule;
    `grep -c "seam" plugins/dev-workflows/references/bug-diagnosis.md` → ≥1 (cross-ref present).
  - `git add -A && git commit` (trailer). Message:
    `feat(dev-workflows): add bug-diagnosis reference + risk-planner bug-shape handling`.

### Task 3: Item 1 + Item 2 command wiring — `implement.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md`

**Interfaces:**
- Consumes: `applicable_spec` (Task 1), `risk-planner` step-tags (Task 1), `task_shape: bug` (Task 2),
  `bug-diagnosis.md` (Task 2).

- [ ] **Step 1 — Bug-shape detection (Phase 1.5).**
  At the end of Phase 1.5 (after the `model_routing` block, before "Then choose the branch:"), add:
  ```markdown
  **Detect task shape.** Inspect the description for defect signals (fix / bug / regression / broken /
  incorrect / wrong output / crash / fails). If bug-shaped, set `task_shape: bug`; when genuinely
  ambiguous whether this is a defect fix or new work, ask with a `choices` prompt (last choice
  `"Other… (describe)"`). `task_shape: bug` only affects the SIGNIFICANT / HIGH-RISK path (Phase 2B/3B);
  for SIMPLE / MODERATE it is guidance only.
  ```

- [ ] **Step 2 — Resolve in-scope IDs + pass to planner (Phase 2B).**
  In Phase 2B's `risk-planner` dispatch prompt, add two brief lines after `Current state:`:
  ```markdown
  >  Specs in scope: [the resolved specification.md/design.md path(s) from Phase 0, or "none"]
  >  task_shape: [bug | omit]
  ```
  Immediately before the dispatch, add:
  ```markdown
  When a `specification.md`/`design.md` is in scope, extract its **in-scope** `[Uxx]`/`[ACxx]`/`[TCxx]`
  IDs (reuse the specs resolved in Phase 0) into `in_scope_ids` for the review dispatch below. When
  `task_shape: bug`, the plan will lead with a repro step and a ranked-hypotheses section — surface them
  in the normal plan-approval gate (no extra interrupt).
  ```

- [ ] **Step 3 — `[DEBUG-xxxx]` cleanup gate (Phase 3B).**
  In Phase 3B step 5 ("After all changes are written: DO NOT run tests yet. Capture the diff…"), prepend
  a sentence:
  ```markdown
  When `task_shape: bug`, first **strip every `[DEBUG-xxxx]` probe** added during diagnosis (per
  `${CLAUDE_PLUGIN_ROOT}/references/bug-diagnosis.md`); the review diff must contain no debug
  instrumentation. Then capture the diff.
  ```

- [ ] **Step 4 — Pass `applicable_spec` to code-review (Phase 3B step 6).**
  In the Phase 3B `code-review` dispatch prompt, after the `applicable_ard:` line, add:
  ```markdown
  >  applicable_spec: [ { spec_paths: [...], in_scope_ids: [...] } when a spec/design is in scope, else omit ]
  ```

- [ ] **Step 5 — Phase 5 report line + escalation.**
  In the Phase 5 report template, add after the `### Opus review (if applicable)` block:
  ```markdown
  ### Spec/design conformance (if a spec/design was in scope)
  [coverage summary from code-review's dimension; list any missing/partial/contradicts — or "N/A"]
  ```
  In Phase 3B step 7 (or a new step 7.5 just before step 8), add:
  ```markdown
  - **Spec/design conformance findings** — for each unresolved `missing`/`contradicts` in-scope
    requirement from the code-review dimension, write a `- [ ]` note back onto the source
    `specification.md`/`design.md` under an `## Engineering review` heading (the same escalation `/design`
    uses; annotate only — never mutate existing `[Uxx]`/`[ACxx]`/`[TCxx]` IDs). Never silently drop them,
    never invent new Jira work.
  ```

- [ ] **Step 6 — Add invariants.**
  In the `## Invariants (always enforced)` block, add:
  ```markdown
  - WHEN a `specification.md`/`design.md` is in scope on a SIGNIFICANT / HIGH-RISK run: extract its
    in-scope IDs, pass `applicable_spec` to `code-review`, report conformance in Phase 5, and escalate
    unresolved `missing`/`contradicts` as `- [ ]` notes on the spec/design — never silently
  - WHEN `task_shape: bug` on a SIGNIFICANT / HIGH-RISK run: risk-planner follows `bug-diagnosis.md`
    (repro-first + ranked hypotheses), and all `[DEBUG-xxxx]` instrumentation is stripped before the
    Opus-review diff is captured
  ```

- [ ] **Step 7 — Verify + commit.**
  - Read `implement.md` end-to-end.
  - Run: `grep -n "applicable_spec\|task_shape\|DEBUG-xxxx\|Spec/design conformance" plugins/dev-workflows/commands/implement.md`
    → expect hits in Phase 1.5, 2B, 3B, 5, and Invariants.
  - Run `claude plugin validate` in the canonical repo → expect pass.
  - `git add -A && git commit` (trailer). Message:
    `feat(dev-workflows): wire converge + bug-diagnosis into /implement`.

### Task 4: Item 3 — test-writer quality gate

**Files:**
- Modify: `plugins/dev-workflows/agents/test-writer.md`

- [ ] **Step 1 — Add the four anti-patterns to step 5.**
  In `## Steps` step 5 ("Write tests covering the behavior…"), append these bullets to its Constraints:
  ```markdown
  - **Falsifiability gate** — before writing each test, name the exact production change that would make
    it fail. If you cannot name one, the test is a change-detector — do not write it.
  - **No mirror-assertion** — never compute the expected value using the same logic as the code under
    test; derive it independently.
  - **No change-detector** — assert the observable behavior that depends on a value, not a bare constant
    or a private/internal structure for its own sake.
  - **Production methods only** — test-only helpers, fixtures, and cleanup live in test utilities, never
    in the production class under test.
  ```

- [ ] **Step 2 — Add step 6 (mutation self-check); renumber Verify syntax → 7.**
  Insert a new step 6 before the current "Verify syntax" step (renumber it to 7):
  ```markdown
  6. **Mutation self-check.** For each test just written, mentally mutate the production code it covers
     (flip a condition, drop a line, off-by-one). Confirm the test would fail under that mutation; if it
     would still pass, the test is too weak — strengthen its assertions before returning.
  ```

- [ ] **Step 3 — Add a hard rule.**
  In `## Hard rules`, add:
  ```markdown
  - NEVER write a test that cannot fail on a real regression (tautological / change-detector /
    mirror-assertion). Every test must have a named production change that would break it.
  ```

- [ ] **Step 4 — Verify + commit.**
  - Read `test-writer.md`; confirm output shape is UNCHANGED (no new report fields).
  - Run: `grep -n "Falsifiability\|Mutation self-check\|mirror-assertion" plugins/dev-workflows/agents/test-writer.md`
    → expect the additions; confirm the step after mutation is renumbered to `7`.
  - `git add -A && git commit` (trailer). Message:
    `feat(dev-workflows): add test-writer quality gate (falsifiability + mutation check)`.

**→ Wave 1 review checkpoint:** run the SDD final-review-lite over Tasks 1–4 as a group (or proceed to
the whole-branch review at the very end — controller's call). Then continue to Wave 2.

---

## Wave 2 — Tier 2

### Task 5: Item 4 — ambiguity taxonomy + freebie rename (grilling-technique + spec-reviewer)

**Files:**
- Modify: `plugins/dev-workflows/references/grilling-technique.md`
- Modify: `plugins/dev-workflows/agents/spec-reviewer.md`

- [ ] **Step 1 — Freebie rename.**
  In `references/grilling-technique.md`, change the Mechanics bullet "**Walk the design tree in dependency
  order**…" → "**Walk the decision tree in dependency order**…". Verify no other "design tree" remains:
  `grep -n "design tree" plugins/dev-workflows/references/grilling-technique.md` → expect **0 hits**.

- [ ] **Step 2 — Add the terminology-precision Mechanics bullet.**
  In `## Mechanics`, add after the fact-vs-decision bullet:
  ```markdown
  - **Force terminology precision.** When a term is overloaded or fuzzy (e.g. "user" vs. "buyer" vs.
    "payer"; "enable" vs. "install"), name the ambiguity and make the user pick a precise meaning before
    building on it.
  ```

- [ ] **Step 3 — Add the `## Ambiguity taxonomy` section** at the end of the file:
  ```markdown
  ## Ambiguity taxonomy (gap-categories, altitude-aware)

  Categories the grill scans to *find* gaps — they feed the existing **Impact × Uncertainty** ranking of
  what to ask. This is **not** a user-facing menu and adds **no** mandatory questions: bounded callers
  still cap at ≤5; relentless callers still stop at convergence. Scale the categories to the caller's
  altitude:

  - **All altitudes:** overloaded/fuzzy **terminology**; **pre-mortem / assumption audit** (which
    unstated assumption, if wrong, breaks this?); **second-order effects** (what does this change
    downstream?).
  - **Product altitude** (`/idea`, `/create-vi`): unstated **quality expectations** (implied latency,
    scale, availability, or compliance expectations) framed as product outcomes — not engineering NFRs.
  - **Engineering altitude** (`/specify`, `/design`): the full **NFR** set (performance, scalability,
    reliability, observability, security/compliance); **integration / external-dependency** gaps;
    **implicit enum branch** (a field with N values where only some are specified — the rest are an
    untested branch).
  ```

- [ ] **Step 4 — spec-reviewer coverage additions.**
  In `agents/spec-reviewer.md` `## Cross-stage checks`, extend the **Coverage** bullet (or add adjacent
  bullets) with:
  ```markdown
  - **NFR coverage:** when the feature plainly implies a non-functional criterion (performance,
    scalability, reliability, observability, security/compliance) and no AC/TC addresses it → `MAJOR`
    (or `MINOR` if arguably out of scope but unstated).
  - **Implicit enum branch:** when an AC/TC special-cases some values of an N-ary field (status/mode/type)
    and leaves the remaining value(s) unmentioned with no explicit exclusion → `BLOCKER` (generalizes the
    existing paired-state-transition check from binary to N-ary).
  ```

- [ ] **Step 5 — Verify + commit.**
  - Read both files.
  - Run: `grep -n "design tree" plugins/dev-workflows/references/grilling-technique.md` → **0 hits**;
    `grep -n "Ambiguity taxonomy\|terminology precision\|Force terminology" plugins/dev-workflows/references/grilling-technique.md`
    → expect hits; `grep -n "Implicit enum\|NFR coverage" plugins/dev-workflows/agents/spec-reviewer.md`
    → expect hits.
  - `git add -A && git commit` (trailer). Message:
    `feat(dev-workflows): ambiguity taxonomy + decision-tree rename (grill + spec-reviewer)`.

### Task 6: Item 5 — review-fixer plan-conflict disposition

**Files:**
- Modify: `plugins/dev-workflows/agents/review-fixer.md`
- Modify: `plugins/dev-workflows/commands/implement.md`

- [ ] **Step 1 — review-fixer: add the plan-conflict rule.**
  In `agents/review-fixer.md` `## Fix method`, add a sub-bullet under the BLOCKER/MAJOR handling (step 2):
  ```markdown
  - If a finding **contradicts the approved plan** (the plan explicitly mandated the thing the finding
    objects to), do NOT auto-fix against the plan and do NOT bury it in a generic "other" defer. Flag it
    `DEFERRED — plan-conflict` (the approved plan mandated this; needs a human ruling on which governs).
  ```
  In `## Output` → `### Deferred`, add `plan-conflict` to the reason enum:
  `→ [reason: design change / migration / process / cross-cutting test strategy / plan-conflict / other]`.
  In `## Hard rules`, add:
  ```markdown
  - NEVER fix a finding that contradicts the approved plan by overriding the plan; flag it
    `DEFERRED — plan-conflict` and set `Stop condition flag` to `NEEDS HUMAN`.
  ```
  In the `### Stop condition flag` description, note that any `plan-conflict` deferral forces `NEEDS HUMAN`.

- [ ] **Step 2 — implement.md: surface plan-conflict immediately.**
  In `commands/implement.md` Phase 3B step 7, in the **BLOCK** and **PASS WITH RECOMMENDATIONS** handling
  (after the review-fixer sub-step), add:
  ```markdown
  - If the fix report contains any `DEFERRED — plan-conflict` finding, surface it to the user
    **immediately** (do not wait for the BLOCK-still-BLOCK path): show the finding beside the plan text it
    contradicts and ask `choices: ["Revise the plan (the finding governs)", "Apply the fix against the
    plan (the plan governs — logged in Phase 5)", "Other… (describe)"]`. Act on the answer before
    re-running the review.
  ```

- [ ] **Step 3 — Verify + commit.**
  - Read both files.
  - Run: `grep -n "plan-conflict" plugins/dev-workflows/agents/review-fixer.md plugins/dev-workflows/commands/implement.md`
    → expect hits in both.
  - `git add -A && git commit` (trailer). Message:
    `feat(dev-workflows): review-fixer plan-conflict disposition + /implement surfacing`.

### Task 7: Item 6 — Fowler 12-smell floor (code-review)

**Files:**
- Modify: `plugins/dev-workflows/agents/code-review.md`

- [ ] **Step 1 — Extend the Architectural-consistency dimension.**
  In `## Review dimensions` dimension 3 (Architectural consistency), append:
  ```markdown
  As a **floor** when the repo has no documented standard (a documented standard **overrides** this
  list), watch for the classic code smells — flag as judgment-call findings (`MINOR`/`NIT`, not hard
  violations): Mysterious Name, Duplicated Code, Feature Envy, Data Clumps, Primitive Obsession, Repeated
  Switches, Shotgun Surgery, Divergent Change, Speculative Generality, Message Chains, Middle Man, Refused
  Bequest.
  ```

- [ ] **Step 2 — Verify + commit.**
  - Read the file; confirm the smells are framed as MINOR/NIT floor, overridable.
  - Run: `grep -n "Refused Bequest\|Speculative Generality\|floor" plugins/dev-workflows/agents/code-review.md`
    → expect hits.
  - `git add -A && git commit` (trailer). Message:
    `feat(dev-workflows): add Fowler smell floor to code-review architectural dimension`.

### Task 8: Item 7 — deep-module / seam vocab (design-format + design-reviewer)

**Files:**
- Modify: `plugins/dev-workflows/references/design-format.md`
- Modify: `plugins/dev-workflows/agents/design-reviewer.md`

- [ ] **Step 1 — design-format.md: define the vocab.**
  In `references/design-format.md`, in the `## Sections` list under item `5. ## Seams`, append to that
  section's description (and reference it from item `3. ## Architecture & components`):
  ```markdown
  Judge seam/module quality by: **deep module** (a small interface over substantial implementation —
  prefer depth over many shallow pass-throughs); the **deletion test** (would removing this module
  concentrate complexity meaningfully, or merely relocate it? if only relocate, it may not earn its
  keep); the **two-adapters heuristic** (one hypothetical consumer = a *speculative* seam — do not
  introduce it yet; introduce a seam when a second real consumer exists — YAGNI for seams).
  ```

- [ ] **Step 2 — design-reviewer.md: add the quality check.**
  In `agents/design-reviewer.md` `## Cross-cutting checks`, extend the **Seam / test-strategy soundness**
  bullet with:
  ```markdown
  A **shallow module** (interface nearly as large as its implementation) or a **speculative seam** (a
  seam justified by a single hypothetical adapter, no second real consumer) → `MAJOR` if it drives the
  design's structure, else `MINOR`. Cite the deep-module / deletion-test / two-adapters vocabulary in
  `${CLAUDE_PLUGIN_ROOT}/references/design-format.md`.
  ```

- [ ] **Step 3 — Verify + commit.**
  - Read both files.
  - Run: `grep -n "deep module\|deletion test\|two-adapters\|speculative seam" plugins/dev-workflows/references/design-format.md plugins/dev-workflows/agents/design-reviewer.md`
    → expect hits in both.
  - `git add -A && git commit` (trailer). Message:
    `feat(dev-workflows): deep-module/seam quality vocab (design-format + design-reviewer)`.

### Task 9: Item 8 — risk-planner no-placeholders + counter-metrics

**Files:**
- Modify: `plugins/dev-workflows/agents/risk-planner.md`
- Modify: `plugins/dev-workflows/references/vi-format.md`
- Modify: `plugins/dev-workflows/agents/vi-reviewer.md`

- [ ] **Step 1 — risk-planner: no-placeholders self-review bullet.**
  In `agents/risk-planner.md` `## Planning discipline`, add:
  ```markdown
  - **No placeholders.** Before returning, re-read the plan and replace any placeholder with concrete
    content: "TBD", "add proper error handling", "handle edge cases", "similar to step N", or any step
    that says *what* without *how*. A plan step that a fresh engineer could not act on is a plan failure.
  ```

- [ ] **Step 2 — vi-format.md: counter-metrics.**
  In `references/vi-format.md` `## Spine`, in the `## Success Metrics` bullet, append:
  ```markdown
   Optionally add **counter-metrics** (`[SM-C1]`, `[SM-C2]`…) — a metric explicitly named as *not* to be
  optimized or gamed, counterbalancing a Primary SM (e.g. "throughput up, but `[SM-C1]` error-rate must
  not rise").
  ```

- [ ] **Step 3 — vi-reviewer.md: counter-metric note.**
  In `agents/vi-reviewer.md`, in its Success-Metrics-related dimension (locate the metrics check), add:
  ```markdown
  - A Primary success metric that is plausibly gameable with no counter-metric (`[SM-Cx]`) guarding it →
    `NIT`/`MINOR` (non-blocking) — suggest a counter-metric.
  ```
  *(Implementer: read `vi-reviewer.md` first to place this beside the existing measurable-metrics check;
  match its finding-format.)*

- [ ] **Step 4 — Verify + commit.**
  - Read all three files.
  - Run: `grep -n "No placeholders" plugins/dev-workflows/agents/risk-planner.md`;
    `grep -n "counter-metric\|SM-C1" plugins/dev-workflows/references/vi-format.md plugins/dev-workflows/agents/vi-reviewer.md`
    → expect hits.
  - `git add -A && git commit` (trailer). Message:
    `feat(dev-workflows): risk-planner no-placeholders + VI counter-metrics`.

**→ Wave 2 complete. Dispatch the SDD whole-branch final review over the full canonical diff
(`git merge-base main HEAD`..HEAD) before the port pass.** Fix any Critical/Important findings with ONE
fix subagent (batched), then continue.

---

## Wave 3 — Port + doc-surface sync

### Task 10: Port to mgd (straight Claude-Code copy)

**Target repo:** `dt-utils/mgd-claude-plugins/plugins/dev-workflows/` (branch off its `main`).

- [ ] **Step 1 — Diff-check for mgd divergence.** For each touched file, diff the mgd copy against the
  pre-change canonical to see whether mgd carries mgd-specific edits:
  `for f in agents/risk-planner.md agents/code-review.md agents/test-writer.md agents/review-fixer.md agents/design-reviewer.md agents/spec-reviewer.md agents/vi-reviewer.md references/grilling-technique.md references/design-format.md references/vi-format.md commands/implement.md; do diff <(git -C dt-utils/mgd-claude-plugins show HEAD:plugins/dev-workflows/$f 2>/dev/null) <(git -C ai-tools/ihudak-claude-plugins show <PRE-CHANGE-SHA>:plugins/dev-workflows/$f 2>/dev/null) >/dev/null 2>&1 && echo "IDENTICAL $f" || echo "DIVERGES $f"; done`
  For **IDENTICAL** files: copy the new canonical version over. For **DIVERGES** files: apply the same
  targeted edits by hand (do NOT clobber mgd-specific content).

- [ ] **Step 2 — Copy/port the changed files** into `mgd-claude-plugins/plugins/dev-workflows/` (agents,
  references, `commands/implement.md`) and add the new `references/bug-diagnosis.md`.

- [ ] **Step 3 — Verify.** Run `claude plugin validate` in `mgd-claude-plugins`. Grep the ported files
  for the same tokens verified in Wave 1/2 (`applicable_spec`, `task_shape`, `Ambiguity taxonomy`,
  `plan-conflict`, `deep module`, `counter-metric`). Confirm `bug-diagnosis.md` exists.

- [ ] **Step 4 — Commit** (trailer). Message: `feat(dev-workflows): port upstream-harvest improvements (converge, bug-diagnosis, quality gates, taxonomy, seam vocab)`.

### Task 11: Port to Copilot (hybrid conversion)

**Target repo:** `ai-tools/ihudak-copilot-plugins/dev-workflows/` (branch off its `main`).

- [ ] **Step 1 — Agents: straight port.** Copy the changed agent files into
  `dev-workflows/agents/` (code-review, risk-planner, test-writer, review-fixer, design-reviewer,
  spec-reviewer, vi-reviewer). First diff each against its canonical pre-change version to confirm the
  Copilot agent had no Copilot-specific divergence; if it diverges, apply edits by hand. Preserve the
  Copilot repo's own path-reference convention (do not introduce Claude-only `${CLAUDE_PLUGIN_ROOT}`
  syntax if the Copilot files use a different form — check an existing Copilot agent first).

- [ ] **Step 2 — References → `skills/_shared/`.** Copy `grilling-technique.md`, `design-format.md`,
  `vi-format.md` into `dev-workflows/skills/_shared/`, and add the new `bug-diagnosis.md` there. Apply
  the same divergence check + path-convention rule as Step 1.

- [ ] **Step 3 — `implement.md` → `skills/implement/SKILL.md` (CONVERSION).** Read the existing
  `skills/implement/SKILL.md` first to learn its Copilot phrasing/structure. Re-express the four Wave-1/2
  `implement.md` behavior changes in that idiom: (a) bug-shape detection + `task_shape`; (b) in-scope-ID
  extraction + `applicable_spec` to the review; (c) `[DEBUG-xxxx]` cleanup before the review diff; (d)
  Phase-5 conformance line + `- [ ]` escalation; (e) plan-conflict immediate surfacing. Do NOT copy the
  Claude command verbatim — match the skill's existing keyword-triggered, Copilot-agent-routed style.

- [ ] **Step 4 — Verify.** Confirm the Copilot marketplace manifest still parses
  (`python3 -c "import json,sys; json.load(open('ai-tools/ihudak-copilot-plugins/.github/plugin/marketplace.json'))"`).
  Grep `skills/_shared/` + `skills/implement/SKILL.md` + `agents/` for the ported tokens. Confirm
  `skills/_shared/bug-diagnosis.md` exists.

- [ ] **Step 5 — Commit** (trailer). Message: `feat(dev-workflows): port upstream-harvest improvements to Copilot (agents + _shared refs + implement skill)`.

### Task 12: Doc-surface sync (all three repos)

- [ ] **Step 1 — Version bumps in each `marketplace.json`.**
  - `ai-tools/ihudak-claude-plugins/.claude-plugin/marketplace.json`: dev-workflows `2.37.0 → 2.38.0`.
  - `ai-tools/ihudak-copilot-plugins/.github/plugin/marketplace.json`: dev-workflows `2.5.0 → 2.6.0`.
  - `dt-utils/mgd-claude-plugins/.claude-plugin/marketplace.json`: read its current dev-workflows version
    and minor-bump it. Confirm no description sentence is now contradicted (no re-listing needed — no new
    commands/agents).

- [ ] **Step 2 — Per-plugin `README.md`** (all three): if the README enumerates references or behaviors,
  add `bug-diagnosis.md` and note the converge (spec/design-conformance) + bug-diagnosis discipline. Read
  each README first; make minimal additive edits only.

- [ ] **Step 3 — `CLAUDE.md` / copilot-instructions.**
  - `ai-tools/ihudak-claude-plugins/CLAUDE.md` and `dt-utils/mgd-claude-plugins/CLAUDE.md`: add a
    `bug-diagnosis.md` entry to the reference-doc section (model it on the existing `source-truth.md`
    entry) and a light touch to the workflow map for the converge + bug-diagnosis behaviors. Additive.
  - `ai-tools/ihudak-copilot-plugins/.github/copilot-instructions.md`: the same, in that file's idiom.

- [ ] **Step 4 — `CHANGELOG.md`** (per plugin, where present) — one entry each summarizing the harvest
  (converge check, bug-diagnosis discipline, test/plan/seam quality gates, ambiguity taxonomy).

- [ ] **Step 5 — Verify + commit (per repo).**
  - `claude plugin validate` in both Claude repos; JSON-parse the Copilot manifest.
  - Grep each `CLAUDE.md`/copilot-instructions for `bug-diagnosis`.
  - Commit in each repo (trailer). Message (per repo): `docs(dev-workflows): sync READMEs/CLAUDE/manifests for upstream-harvest`.

---

## Push (HELD — user gate)

After Task 12, present a per-repo commit summary and **ask the user** before pushing any of the three
repos. Do not push without explicit go-ahead (Global Constraint).

## Self-review checklist (controller, before dispatching Task 1)

- Spec coverage: every one of the 8 items + the doc-sync + the two ports has a task (Items 1→T1+T3,
  2→T2+T3, 3→T4, 4→T5, 5→T6, 6→T7, 7→T8, 8→T9; ports T10/T11; docs T12). ✅
- No placeholder edits — each task names the exact file, anchor, and the literal content to insert. ✅
- Shared-file ordering: `risk-planner.md` (T1→T2→T9), `code-review.md` (T1→T7), `implement.md`
  (T3→T6) are sequenced; each later task re-reads the file. ✅
- Frozen `specification-format.md` is never edited (Item 4 coverage lands in spec-reviewer). ✅
- Seam vocab defined once (T8 design-format) and only cross-referenced from bug-diagnosis (T2). ✅

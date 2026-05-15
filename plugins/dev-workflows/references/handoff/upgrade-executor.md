# upgrade-executor Handoff Format

## Input (orchestrator → upgrade-executor)

The upgrade plan from upgrade-planner with `status: READY`, plus baseline info:

```markdown
## Upgrade Execution Request
repo: /absolute/path/to/repo
phase: full                # full (default) | verify-resume — see "Phase" below
baseline:                    # The orchestrator (upgrade/SKILL.md Phase 2 Step 1)
                             # ALWAYS captures the baseline before invoking this
                             # agent — this agent never re-baselines.
                             # On phase: verify-resume the orchestrator MUST
                             # re-supply the same baseline (the captured value
                             # cannot survive the AWAITING_REVIEW boundary).
  passing_count: 142
  passing_tests:             # REQUIRED — full list of passing test IDs so
                             # test-baseliner verify can detect regressions
                             # exactly. Also required on phase: verify-resume.
    - com.example.OrderTest#testCreate
    - com.example.UserTest#testLogin
model_routing:               # optional; set by orchestrator for SIGNIFICANT / HIGH-RISK
  classification: SIGNIFICANT
  gate_tests_on_review: true # if true: stop after Build, return AWAITING_REVIEW
  # full schema: see ~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md §4

## Upgrade Plan: spring-boot
status: READY
component: spring-boot
ecosystem: Maven
from: "3.1.4"
to: "3.3.11"
files:
  - path: pom.xml
    change: "bump spring-boot-starter-parent from 3.1.4 to 3.3.11"
related:
  - component: hibernate
    from: "6.2.0"
    to: "6.4.0"
    required: true
    reason: "Spring Boot 3.3 requires Hibernate 6.4+"
```

**phase values:**
- `full` (or omitted) — apply changes, build, verify, output. Default.
- `verify-resume` — second-call protocol after Opus review. Skip steps 1–2
  (changes are already applied and built); resume at step 3 (Verify).

## Output (upgrade-executor → orchestrator)

```markdown
## Upgrade Result: spring-boot
status: OK              # OK | BUILD_FAILED | SKIPPED | TEST_REGRESSION_KEPT | TEST_REGRESSION_REVERTED | AWAITING_REVIEW
component: spring-boot
from: "3.1.4"
to: "3.3.11"
related_applied:
  - {component: hibernate, from: "6.2.0", to: "6.4.0"}
tests_before: 142
tests_after: 142
regressions: 0
notes: "Updated 2 test files: renamed @RunWith to @ExtendWith"
model_routing:           # echoed back when present in input
  classification: SIGNIFICANT
  gate_tests_on_review: true
```

**status values:**
- `OK` — all changes applied, all previously-green tests still green
- `BUILD_FAILED` — build failed, all changes reverted for this component
- `SKIPPED` — component was NOT_FOUND or user chose to skip
- `TEST_REGRESSION_KEPT` — regressions present, user chose to keep upgrade
- `TEST_REGRESSION_REVERTED` — regressions present, user chose to revert
- `AWAITING_REVIEW` — `gate_tests_on_review: true` was set; changes are
  applied and the build succeeded, but tests have **not** been run yet.
  The orchestrator must perform the Opus code review, then re-invoke this
  agent with `phase: verify-resume` to continue from the Verify step.

### AWAITING_REVIEW output shape

Use this exact shape (omit `tests_before` / `tests_after` / `regressions` —
they are meaningless before tests run):

```markdown
## Upgrade Result: spring-boot
status: AWAITING_REVIEW
component: spring-boot
from: "3.1.4"
to: "3.3.11"
related_applied:
  - {component: hibernate, from: "6.2.0", to: "6.4.0"}
build: OK
files_changed:                # full list — needed by the orchestrator's Opus review
  - pom.xml
  - subproject/build.gradle
notes: null                   # or any in-place adjustments made during apply
model_routing:
  classification: SIGNIFICANT
  gate_tests_on_review: true
```

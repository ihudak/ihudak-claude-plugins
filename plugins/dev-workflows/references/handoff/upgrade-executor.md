# upgrade-executor Handoff Format

## Input (orchestrator → upgrade-executor)

The upgrade plan from upgrade-planner with `status: READY`, plus baseline info:

The `## Upgrade Plan` section may arrive inline (as shown below) **or** as a line naming the
absolute path of a `mktemp` file the orchestrator wrote it to. When given a path, `Read` the file
first and treat its content as that section.

```markdown
## Upgrade Execution Request
repo: /absolute/path/to/repo
phase: full                # full (default) | verify-resume | regression-resume — see "Phase" below
regression_decision: keep-anyway  # keep-anyway | revert — REQUIRED on phase: regression-resume only;
                            # the orchestrator obtains this from the user (subagents cannot prompt
                            # the user directly — see /upgrade "Handling Test Failures")
baseline:                    # The orchestrator (commands/upgrade.md Phase 2 prep, Step 2)
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
  # full schema: see ${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md §4

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
- `regression-resume` — second-call protocol after the orchestrator asked the
  user about a `TEST_REGRESSION` return. Skip straight to "Test regression"
  step 4; requires `regression_decision`.

## Output (upgrade-executor → orchestrator)

```markdown
## Upgrade Result: spring-boot
status: OK              # OK | BUILD_FAILED | SKIPPED | TEST_REGRESSION | TEST_REGRESSION_KEPT | TEST_REGRESSION_REVERTED | AWAITING_REVIEW | BLOCKED
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
- `TEST_REGRESSION` — regressions present, not auto-fixable, awaiting a user
  decision. This agent cannot ask the user (subagents have no interactive
  tools), so it stops here — see `notes` for the failing-test list and
  diagnosis. The orchestrator asks the user (per `/upgrade` "Handling Test
  Failures"), then re-invokes this agent with `phase: regression-resume` +
  `regression_decision: keep-anyway | revert`.
- `TEST_REGRESSION_KEPT` — the `regression-resume` call's `regression_decision` was `keep-anyway`
- `TEST_REGRESSION_REVERTED` — the `regression-resume` call's `regression_decision` was `revert`
- `AWAITING_REVIEW` — `gate_tests_on_review: true` was set; changes are
  applied and the build succeeded, but tests have **not** been run yet.
  The orchestrator must perform the Opus code review, then re-invoke this
  agent with `phase: verify-resume` to continue from the Verify step.
- `BLOCKED` — the upgrade plan could not be read at the path the orchestrator supplied;
  nothing was changed. Per the read-failure contract
  (`${CLAUDE_PLUGIN_ROOT}/references/context-management.md`), the orchestrator must not
  re-run upgrade-planner to reconstruct the plan — surface the unreadable path to the user
  and stop the upgrade for this component.

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

### TEST_REGRESSION output shape

```markdown
## Upgrade Result: spring-boot
status: TEST_REGRESSION
component: spring-boot
from: "3.1.4"
to: "3.3.11"
related_applied:
  - {component: hibernate, from: "6.2.0", to: "6.4.0"}
tests_before: 142
tests_after: 140
regressions: 2
failing_tests:                # full list — the orchestrator shows these to the user
  - com.example.OrderTest#testCreate
diagnosis: <one-line: likely cause, e.g. "Hibernate 6.4 changed default fetch type">
notes: null
model_routing:
  classification: SIGNIFICANT
  gate_tests_on_review: true
```

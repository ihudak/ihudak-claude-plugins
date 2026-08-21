# vuln-fixer Handoff Format

## Input (orchestrator → vuln-fixer)

The research report from vuln-research for a SINGLE CVE with `status: READY`, plus:

The `## Research Report` section may arrive inline (as shown below) **or** as a line naming the
absolute path of a `mktemp` file the orchestrator wrote it to. When given a path, `Read` the file
first and treat its content as that section.

```markdown
## Vuln Fix Request
repo: /absolute/path/to/repo
phase: full                        # full (default) | verify-resume | regression-resume — see "Phase" below
baseline_tests: provided           # "provided" | "run-fresh"
  # If "provided", the orchestrator supplies results below.
  # If "run-fresh", vuln-fixer runs the suite itself first.
  # NOTE: when gate_tests_on_review: true, "run-fresh" is INVALID —
  # the orchestrator MUST capture the baseline itself (see `/vuln`
  # Step 3) so it can be replayed on the verify-resume call. The captured
  # baseline cannot survive the AWAITING_REVIEW boundary inside the fixer.
baseline_passing: 47               # count of passing tests (required when "provided")
baseline:                          # required when "provided"; may also be sent on verify-resume
  passing_tests:                   # the full list — needed for precise regression detection
    - com.example.FooTest#testCreate
    - com.example.BarTest#testLogin
jira_placeholder: NOJIRA           # or omit if project uses no placeholder
regression_decision: keep-anyway   # keep-anyway | revert — REQUIRED on phase: regression-resume only;
                                    # the orchestrator obtains this from the user (subagents cannot
                                    # prompt the user directly — see /vuln "Handling Test Failures")
model_routing:                     # optional; set by orchestrator for SIGNIFICANT / HIGH-RISK
  classification: SIGNIFICANT
  gate_tests_on_review: true       # if true: stop after Build, return AWAITING_REVIEW
  # full schema: see ${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md §4

## Research Report (single CVE)
### CVE-2023-46604
status: READY
jira: MGD-2423
description: "Apache ActiveMQ RCE via ClassInfo deserialization"
library: activemq-broker
ecosystem: Maven
vulnerable_range: "<5.15.16"
current_version: "5.15.5"
safe_version: "5.15.16"
files:
  - path: pom.xml
    change: "bump activemq-broker.version from 5.15.5 to 5.15.16"
```

**phase values:**
- `full` (or omitted) — baseline → apply → build → verify → commit → PR. Default.
- `verify-resume` — second-call protocol after Opus review. Skip steps 1–3
  (baseline, fix, build are already done); resume at step 4 (Verify) and
  proceed through commit and PR.
- `regression-resume` — second-call protocol after the orchestrator asked the
  user about a `TEST_REGRESSION` return. Skip straight to "Test regression"
  step 4; requires `regression_decision`.

## Output (vuln-fixer → orchestrator)

```markdown
## Vuln Fix Result: CVE-2023-46604
status: SUCCESS         # SUCCESS | BUILD_FAILED | TEST_REGRESSION | REVERTED | SKIPPED_BY_USER | AWAITING_REVIEW | BASELINE_FAILED | BLOCKED
branch: fix/MGD-2423-CVE-2023-46604
pr_url: https://github.com/org/repo/pull/42
tests_before: 47
tests_after: 47
regressions: 0
notes: null             # or description of any auto-fixed test changes
model_routing:           # echoed back when present in input
  classification: SIGNIFICANT
  gate_tests_on_review: true
```

**status values:**
- `SUCCESS` — fix applied, tests green, PR opened
- `BUILD_FAILED` — build failed after fix, changes reverted
- `TEST_REGRESSION` — previously-green tests failed and were not auto-fixable;
  the fix is applied and built, but **not committed and no PR opened**. This
  agent cannot ask the user (subagents have no interactive tools), so it
  stops here — see `notes` for the failing-test list and diagnosis. The
  orchestrator asks the user (per `/vuln` "Handling Test Failures"), then
  re-invokes this agent with `phase: regression-resume` +
  `regression_decision: keep-anyway | revert`.
- `BASELINE_FAILED` — `test-baseliner` capture returned `RUN_FAILED` or
  `COMMAND_NOT_FOUND` before any fix was applied; nothing was changed
- `REVERTED` — the `regression-resume` call's `regression_decision` was `revert`
- `SKIPPED_BY_USER` — user chose to skip (set by the orchestrator; this agent
  is not re-invoked in that case)
- `AWAITING_REVIEW` — `gate_tests_on_review: true` was set; the fix is
  applied and the build succeeded, but tests have **not** been run, no
  commit was made, and no PR was opened. The orchestrator must perform
  the Opus code review, then re-invoke this agent with
  `phase: verify-resume` to run Verify, Commit, and PR.
- `BLOCKED` — the research report could not be read at the path the orchestrator supplied;
  nothing was changed. Per the read-failure contract
  (`${CLAUDE_PLUGIN_ROOT}/references/context-management.md`), the orchestrator must not
  re-run vuln-research to reconstruct the report — surface the unreadable path to the user
  and stop remediation for this CVE.

### AWAITING_REVIEW output shape

Use this exact shape (omit `branch` / `pr_url` / `tests_before` /
`tests_after` / `regressions` — none of them exist yet):

```markdown
## Vuln Fix Result: CVE-2023-46604
status: AWAITING_REVIEW
build: OK
files_changed:                # full list — needed by the orchestrator's Opus review
  - pom.xml
notes: null                   # or any in-place adjustments made during apply
model_routing:
  classification: SIGNIFICANT
  gate_tests_on_review: true
```

### TEST_REGRESSION output shape

Use this exact shape (omit `branch` / `pr_url` — no commit/PR has happened yet):

```markdown
## Vuln Fix Result: CVE-2023-46604
status: TEST_REGRESSION
tests_before: 47
tests_after: 45
regressions: 2
failing_tests:                # full list — the orchestrator shows these to the user
  - com.example.FooTest#testCreate
  - com.example.BarTest#testLogin
diagnosis: <one-line: likely cause, e.g. "API signature changed in v5.15.16">
notes: null
model_routing:
  classification: SIGNIFICANT
  gate_tests_on_review: true
```

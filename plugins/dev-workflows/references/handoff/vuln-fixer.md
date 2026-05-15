# vuln-fixer Handoff Format

## Input (orchestrator → vuln-fixer)

The research report from vuln-research for a SINGLE CVE with `status: READY`, plus:

```markdown
## Vuln Fix Request
repo: /absolute/path/to/repo
phase: full                        # full (default) | verify-resume — see "Phase" below
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
model_routing:                     # optional; set by orchestrator for SIGNIFICANT / HIGH-RISK
  classification: SIGNIFICANT
  gate_tests_on_review: true       # if true: stop after Build, return AWAITING_REVIEW
  # full schema: see ~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md §4

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

## Output (vuln-fixer → orchestrator)

```markdown
## Vuln Fix Result: CVE-2023-46604
status: SUCCESS         # SUCCESS | BUILD_FAILED | TEST_REGRESSION | REVERTED | SKIPPED_BY_USER | AWAITING_REVIEW
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
- `TEST_REGRESSION` — previously-green tests failed; see `notes` for detail
- `REVERTED` — user chose to revert
- `SKIPPED_BY_USER` — user chose to skip
- `AWAITING_REVIEW` — `gate_tests_on_review: true` was set; the fix is
  applied and the build succeeded, but tests have **not** been run, no
  commit was made, and no PR was opened. The orchestrator must perform
  the Opus code review, then re-invoke this agent with
  `phase: verify-resume` to run Verify, Commit, and PR.

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

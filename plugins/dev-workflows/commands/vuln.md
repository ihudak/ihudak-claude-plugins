---
name: vuln
description: Security vulnerability fix workflow. Researches CVEs via NVD, applies dependency and code fixes one at a time, runs Opus code review, and verifies with tests.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Fix security vulnerabilities: $ARGUMENTS

Each argument token is either `JIRA-ID:CVE-ID` (e.g. `MGD-2423:CVE-2023-46604`) or a bare `CVE-ID` (e.g. `CVE-2023-46604`). Parse and filter each token, research all CVEs first, then fix them one at a time.

---

## Step 0 — Classify & Route (mandatory)

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify **per CVE**, based on the size of the required repository change — not the CVE category alone.

Default heuristics:

| Required fix (from research output) | Classification |
|---|---|
| Patch or same-major minor bump, no source-code changes expected | `MODERATE` |
| Major version bump, or code changes required to adopt the new version | `SIGNIFICANT` |
| Major bump of a security-critical library, or code changes in auth/session/token/permission/payment/audit paths | `HIGH-RISK` |

Because the required fix is not known up front, start with a provisional `MODERATE` routing block for research, then finalize the classification from the research report **before** fix application begins.

---

## Step 1 — Prepare

1. **Parse** — Extract Jira ID (optional) and CVE ID from each token.
2. **Determine NOJIRA placeholder** — Scan recent branch names and commit history for `NOJIRA` / `NO-JIRA`; use the project convention when a Jira ID is missing.
3. **Filter** — Skip non-CVE IDs (`CWE-*`, OWASP patterns) with a warning.
4. **Snapshot repo context** — Note the repo path and, when obvious, the primary ecosystem so the research agent can disambiguate detection.

---

## Step 2 — Research (parallel)

Invoke one research task per valid CVE. Use a single agent message for the batch.

```
task(
  subagent_type: "dev-workflows:vuln-research",
  model: `<detection_model — §2.1 Sonnet chain>`,
  description: "Research CVE",
  prompt: "## Vuln Research Request
  repo: [absolute repo path]
  cves:
    - id: [CVE-ID]
      jira: [optional Jira key]
  ecosystem_hint: [optional]
  model_routing:
    classification: MODERATE
    reason: <one-line>
    current_model: <the model this orchestrator is running under>
    detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # vuln-research; vuln-fixer (SIMPLE/MODERATE); review-fixer
    planning_model: <§2 Opus chain>   # vuln-fixer escalates here only if HIGH-RISK
    review_model:  <§2 Opus chain>    # code-review (frontmatter-pinned; recorded, no override)
    opus_available: <true if a §2 Opus model resolved, else false>
    gate_tests_on_review: false
    notes: <any §2 / §2.1 fallback or degradation>"
)
```

Collect all reports:
- `READY` → candidate for fixing
- `NOT_IN_REPO` → notify and skip
- `LOOKUP_FAILED` → warn and offer retry or skip
- `SKIP_NON_CVE` → already filtered; no further action

Finalize the per-CVE classification from the research output. If the finalized class is `HIGH-RISK`, re-run `vuln-research` on Opus for a confirmation pass. If it is `SIGNIFICANT`, re-run on Opus when the major bump or breaking-change surface is non-trivial.

---

## Step 3 — Fix (sequential)

Process `READY` CVEs one at a time to avoid conflicting edits to the same dependency files.

For each `READY` CVE, before invoking the fixer, write its research report to a temp file (`mktemp -t dw-vuln-research-XXXX.md`, never inside a repo tree) and record its absolute path as `research_file`; the fixer, code-review, and resume steps below receive this path instead of the pasted report.

### SIMPLE / MODERATE path

Invoke `vuln-fixer` with `baseline_tests: run-fresh`:

```
task(
  subagent_type: "dev-workflows:vuln-fixer",
  model: `<detection_model — §2.1 Sonnet chain>`,
  description: "Fix CVE",
  prompt: "## Vuln Fix Request
  repo: [absolute repo path]
  phase: full
  baseline_tests: run-fresh
  jira_placeholder: [NOJIRA or omit]
  model_routing:
    classification: [MODERATE]
    reason: <one-line>
    current_model: <the model this orchestrator is running under>
    detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # vuln-research; vuln-fixer (SIMPLE/MODERATE); review-fixer
    planning_model: <§2 Opus chain>   # vuln-fixer escalates here only if HIGH-RISK
    review_model:  <§2 Opus chain>    # code-review (frontmatter-pinned; recorded, no override)
    opus_available: <true if a §2 Opus model resolved, else false>
    gate_tests_on_review: false
    notes: <any §2 / §2.1 fallback or degradation>

  read the single READY research report from the file at [`research_file`]"
)
```

If the fixer returns `status: TEST_REGRESSION`, follow "Handling Test Failures" below, then
re-invoke `vuln-fixer` with `phase: regression-resume` + the chosen `regression_decision`,
passing the same CVE input with the original research report re-supplied from `research_file`.

### SIGNIFICANT / HIGH-RISK path

1. **Capture baseline at the orchestrator** using the existing `test-baseliner` agent. Keep the full baseline block (`passing_count` and `passing_tests`).
2. **Invoke `vuln-fixer` with review gating enabled**:

```
task(
  subagent_type: "dev-workflows:vuln-fixer",
  model: `<detection_model for SIGNIFICANT; planning_model (§2 Opus chain) only if HIGH-RISK>`,
  description: "Apply CVE fix before review",
  prompt: "## Vuln Fix Request
  repo: [absolute repo path]
  phase: full
  baseline_tests: provided
  baseline_passing: [captured count]
  baseline:
    passing_tests:
      - [captured test ids]
  jira_placeholder: [NOJIRA or omit]
  model_routing:
    classification: [SIGNIFICANT | HIGH-RISK]
    reason: <one-line>
    current_model: <the model this orchestrator is running under>
    detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # vuln-research; vuln-fixer (SIMPLE/MODERATE); review-fixer
    planning_model: <§2 Opus chain>   # vuln-fixer escalates here only if HIGH-RISK
    review_model:  <§2 Opus chain>    # code-review (frontmatter-pinned; recorded, no override)
    opus_available: <true if a §2 Opus model resolved, else false>
    gate_tests_on_review: true
    notes: <any §2 / §2.1 fallback or degradation>

  read the single READY research report from the file at [`research_file`]"
)
```

3. **If the fixer returns `AWAITING_REVIEW`**, run Opus code review before tests:
   - Capture the diff to a temp file: write `git add -N . && git diff` to `mktemp -t dw-vuln-diff-XXXX.patch` (never inside a repo tree) and record its path as `review_diff_file`
   - Invoke `code-review` with the CVE summary, the research handoff (from `research_file`), the fixer output, and the diff (from `review_diff_file`) (frontmatter-pinned to Opus; recorded as `review_model` above, no `model:` override needed)
   - If review returns `BLOCK` or `PASS WITH RECOMMENDATIONS`, invoke `review-fixer` with model: `<detection_model — §2.1 Sonnet chain>` for `BLOCKER` and `MAJOR` findings, then **overwrite `review_diff_file`** with a fresh `git add -N . && git diff` and re-run the Opus review once against that refreshed path — so the re-review reads the post-fix diff, not the stale pre-fix capture
   - If the second verdict is still `BLOCK`, stop and escalate; do not continue to tests, commit, or PR

4. **Resume the fixer after review** — Re-invoke `vuln-fixer` with `phase: verify-resume`, the same baseline block, and the original research report re-supplied from `research_file`.

5. **If the fixer returns `status: TEST_REGRESSION`** (from step 4's resumed verify), follow
   "Handling Test Failures" below, then re-invoke `vuln-fixer` with `phase: regression-resume` +
   the chosen `regression_decision`, the same baseline block, and the original research report
   re-supplied from `research_file`.

---

## Step 4 — Summarise

After all CVEs are processed, print a result table:

```
| CVE            | Library         | Change         | Class        | Result  | PR  |
|----------------|-----------------|----------------|--------------|---------|-----|
| CVE-2023-46604 | activemq-broker | 5.15.5→5.15.16 | MODERATE     | OK      | #42 |
| CVE-2024-99999 | (not in repo)   | —              | —            | SKIP    | —   |
```

Append a `### Model Routing` section summarising the per-CVE classification, why it was chosen, the models used, and any Opus review verdicts.

Then invoke `impl-maintenance` with a compact session handoff covering the CVEs fixed, notable regressions, workarounds, and overall outcome. **Always pass `Command run: /vuln`** in that handoff — omitting it makes `impl-maintenance` default to `/implement`, mislabeling the run.

**Context hygiene.** This was a large run — consider **`/compact`** to free context before your next task (per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3 — non-pipeline, so `/compact` only; guidance only).

**Then persist plugin feedback (automatic).** After `impl-maintenance` returns, project its plugin-facing slice into the specs repo by citing `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its `emit-auto` entry point (§6). Pass the Lessons Learned report, `command: /vuln`, the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only the report's **Command workflow improvements**, **New agents / skills**, and plugin **Reference docs** sections plus the **Key observations** that triggered them (§4 plugin-facing predicate) — never target-project `CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via the §2 specs-first ladder, and writes silently. List the persisted path (or "no plugin-facing signal — nothing persisted") after the lessons-learned report. ADDITIVE — the impl-maintenance report still appears in the output; this step NEVER fails the run, NEVER commits, and NEVER writes into the code repo or the current working directory.

---

## Handling Test Failures

`vuln-fixer` cannot prompt the user directly — dispatched subagents have no access to
interactive tools, even when one is listed in their `tools:`. When it returns
`status: TEST_REGRESSION` (previously-green tests now failing, not auto-fixable), the
**orchestrator** (this command, running in the interactive session) handles the decision:

- Present the failing tests clearly (from the fixer's `failing_tests` / `diagnosis`).
- Ask:
  ```
  choices: ["Apply the fix anyway and flag the failures in the PR (Recommended if tests are flaky)", "Revert this fix and skip it", "Investigate further", "Other… (describe)"]
  ```
- **"Investigate further"** → show more detail (the diff, full failure output) and re-ask
  the same choices — this loops here at the orchestrator until the user picks apply or revert.
- Map the final choice to `regression_decision: keep-anyway | revert` and re-invoke
  `vuln-fixer` with `phase: regression-resume` (see Step 3).

---

## Git Workflow

### Branch naming

Resolve the prefix per `${CLAUDE_PLUGIN_ROOT}/references/branch-naming.md` §1 (`$GIT_USER_INITIALS` → `git config user.initials` → inferred from existing branches → fallback `fix/`; reaching the fallback triggers its §1.5 escalation, which the orchestrator runs before dispatching `vuln-fixer`).

- With Jira ID: `<prefix>/JIRA-ID-CVE-XXXX-XXXXX`
- Without Jira ID: `<prefix>/NOJIRA-CVE-XXXX-XXXXX` (or `<prefix>/CVE-XXXX-XXXXX` if the project omits placeholders)

### Commit message

Use the project's existing style. Default template:

**With Jira ID:**
```
fix(deps): upgrade <library> to <version> to remediate <CVE-ID>

Resolves <JIRA-ID>
Fixes <CVE-ID> - <one-line CVE description>

Vulnerable range: <range>
Safe version: <version>

Co-authored-by: Claude <noreply@anthropic.com>
```

**Without Jira ID:**
```
fix(deps): upgrade <library> to <version> to remediate <CVE-ID>

Fixes <CVE-ID> - <one-line CVE description>

Vulnerable range: <range>
Safe version: <version>

Co-authored-by: Claude <noreply@anthropic.com>
```

### PR

- Base branch: `main` (fallback: `master`)
- Title: `fix(deps): <library> upgrade to remediate <CVE-ID>` (append ` [<JIRA-ID>]` when present)
- Body: CVE summary, vulnerable range, version change made, classification, and test results (pass count before vs. after)

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, jira-not-found, cancellation)
- ALWAYS classify **per CVE** after research
- NEVER use Opus for a `MODERATE` fix unless the user explicitly asks for it
- NEVER run tests for a `SIGNIFICANT` / `HIGH-RISK` CVE before the Opus review returns a non-BLOCK verdict
- ALWAYS pass the captured baseline block back to `vuln-fixer` on `phase: verify-resume`
- NEVER push directly to `main` / `master`
- After the run, suggest **`/compact`** (a big non-pipeline run) per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3 — compact-only, no clear/resume pointer; guidance only, never auto-run.

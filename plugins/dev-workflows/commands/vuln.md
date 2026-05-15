---
name: vuln
description: Security vulnerability fix workflow. Researches CVEs via NVD, applies dependency and code fixes one at a time, runs Opus code review, and verifies with tests.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Fix security vulnerabilities: $ARGUMENTS

Each argument token is either `JIRA-ID:CVE-ID` (e.g. `MGD-2423:CVE-2023-46604`) or a bare `CVE-ID` (e.g. `CVE-2023-46604`). Parse and filter each token, research all CVEs first, then fix them one at a time.

Reference files (read when needed):
- Build-system detection and update commands: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/fix-vuln/build-systems.md`
- NVD API usage: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/fix-vuln/nvd-api.md`
- Model routing: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md`
- Research handoff: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/vuln-research.md`
- Fixer handoff: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/vuln-fixer.md`
- Test baseline handoff: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/test-baseliner.md`

---

## Step 0 — Classify & Route (mandatory)

Read `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md`. Classify **per CVE**, based on the size of the required repository change — not the CVE category alone.

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
  agent_type: "general-purpose",
  description: "Research CVE",
  # Re-run with model: "claude-opus-4.7" for HIGH-RISK CVEs after the provisional pass,
  # and for SIGNIFICANT CVEs when the major-bump surface is non-trivial.
  prompt: "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/vuln-research.md`
  (fall back to `~/.claude/agents/vuln-research.md` if installed at user level).

  Handoff format: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/vuln-research.md`

  ## Vuln Research Request
  repo: [absolute repo path]
  cves:
    - id: [CVE-ID]
      jira: [optional Jira key]
  ecosystem_hint: [optional]
  model_routing:
    classification: MODERATE
    ..."
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

### SIMPLE / MODERATE path

Invoke `vuln-fixer` with `baseline_tests: run-fresh`:

```
task(
  agent_type: "general-purpose",
  description: "Fix CVE",
  prompt: "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/vuln-fixer.md`
  (fall back to `~/.claude/agents/vuln-fixer.md` if installed at user level).

  Handoff format: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/vuln-fixer.md`

  ## Vuln Fix Request
  repo: [absolute repo path]
  phase: full
  baseline_tests: run-fresh
  jira_placeholder: [NOJIRA or omit]
  model_routing:
    classification: [MODERATE]
    gate_tests_on_review: false

  [paste the single READY research report verbatim]"
)
```

### SIGNIFICANT / HIGH-RISK path

1. **Capture baseline at the orchestrator** using the existing `test-baseliner` agent. Keep the full baseline block (`passing_count` and `passing_tests`).
2. **Invoke `vuln-fixer` with review gating enabled**:

```
task(
  agent_type: "general-purpose",
  description: "Apply CVE fix before review",
  prompt: "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/vuln-fixer.md`
  (fall back to `~/.claude/agents/vuln-fixer.md` if installed at user level).

  ## Vuln Fix Request
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
    gate_tests_on_review: true

  [paste the single READY research report verbatim]"
)
```

3. **If the fixer returns `AWAITING_REVIEW`**, run Opus code review before tests:
   - Capture the diff with `git add -N . && git diff`
   - Invoke `code-review` on Opus with the CVE summary, the research handoff, the fixer output, and the diff
   - If review returns `BLOCK` or `PASS WITH RECOMMENDATIONS`, invoke `review-fixer` for `BLOCKER` and `MAJOR` findings, then re-run the Opus review once
   - If the second verdict is still `BLOCK`, stop and escalate; do not continue to tests, commit, or PR

4. **Resume the fixer after review** — Re-invoke `vuln-fixer` with `phase: verify-resume`, the same baseline block, and the original research report re-supplied verbatim.

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

Then invoke `impl-maintenance` with a compact session handoff covering the CVEs fixed, notable regressions, workarounds, and overall outcome.

---

## Handling Test Failures

If the fix causes previously-green tests to fail and a quick investigation does not reveal an obvious fix:

- Present the failing tests clearly.
- Ask the user whether to:
  1. apply the fix anyway and flag the failures in the PR description,
  2. revert the fix, or
  3. investigate further.
- Honor the user's choice.

---

## Git Workflow

### Branch naming

Inspect recent git history and existing branches to match the project's naming convention.

- With Jira ID: `fix/JIRA-ID-CVE-XXXX-XXXXX`
- Without Jira ID: `fix/NOJIRA-CVE-XXXX-XXXXX` (or `fix/CVE-XXXX-XXXXX` if the project omits placeholders)

### Commit message

Use the project's existing style. Default template:

**With Jira ID:**
```
fix(deps): upgrade <library> to <version> to remediate <CVE-ID>

Resolves <JIRA-ID>
Fixes <CVE-ID> - <one-line CVE description>

Vulnerable range: <range>
Safe version: <version>

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

**Without Jira ID:**
```
fix(deps): upgrade <library> to <version> to remediate <CVE-ID>

Fixes <CVE-ID> - <one-line CVE description>

Vulnerable range: <range>
Safe version: <version>

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

### PR

- Base branch: `main` (fallback: `master`)
- Title: `fix(deps): <library> upgrade to remediate <CVE-ID>` (append ` [<JIRA-ID>]` when present)
- Body: CVE summary, vulnerable range, version change made, classification, and test results (pass count before vs. after)

---

## Invariants (always enforced)

- ALWAYS classify **per CVE** after research
- NEVER use Opus for a `MODERATE` fix unless the user explicitly asks for it
- NEVER run tests for a `SIGNIFICANT` / `HIGH-RISK` CVE before the Opus review returns a non-BLOCK verdict
- ALWAYS pass the captured baseline block back to `vuln-fixer` on `phase: verify-resume`
- NEVER push directly to `main` / `master`

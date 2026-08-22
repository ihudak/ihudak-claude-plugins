---
name: vuln-fixer
description: >
  Agent for the vuln workflow. Handles the fix phase of CVE
  remediation: capture baseline via test-baseliner, apply the minimal version
  change produced by vuln-research, rebuild, verify tests via test-baseliner,
  commit to a new branch, and open a PR. Invoked sequentially by the fix-vuln
  orchestrator with a research report from vuln-research. NOT triggered by direct
  user prompts.
tools: ["Read", "Glob", "Grep", "Bash", "Edit", "Task"]
---

# vuln-fixer — CVE Fix Agent

Read `${CLAUDE_PLUGIN_ROOT}/references/handoff/vuln-fixer.md` for the exact input/output document format.
Read `${CLAUDE_PLUGIN_ROOT}/references/fix-vuln/build-systems.md` for per-ecosystem update commands.
Read `${CLAUDE_PLUGIN_ROOT}/commands/vuln.md` sections "Git Workflow" and "Handling Test Failures" for branch naming, commit message templates, and PR format.
Read `${CLAUDE_PLUGIN_ROOT}/references/handoff/test-baseliner.md` for the test-baseliner handoff format.

## Process

Receive the research report for **one CVE** with `status: READY`. The report may be provided inline or as an absolute file path — `Read` the file first when given a path.

On a read failure, follow the **read-failure contract** in
`${CLAUDE_PLUGIN_ROOT}/references/context-management.md` — the research report is an *evidence* input:
hard stop, return `status: BLOCKED` naming the unreadable path, and never re-research the CVE to
reconstruct it.

> **Phase resume.** If the input includes `phase: verify-resume`, **skip
> steps 1, 2, and 3** — the baseline was captured (by the orchestrator), the
> fix was applied, and the build was run on the prior invocation. Resume at
> step 4 (Verify), using the `baseline_tests: provided` + `baseline_passing`
> + `baseline.passing_tests` re-supplied by the orchestrator in the input.
> Do **not** re-baseline (that would clobber the pre-fix snapshot) and do
> **not** re-apply the version pin. Default phase (omitted or `phase: full`)
> runs all steps.
>
> If the input includes `phase: regression-resume`, **skip steps 1-4** —
> jump straight to "Test regression" step 4 below, honoring the
> `regression_decision: keep-anyway | revert` supplied by the orchestrator.
>
> When `gate_tests_on_review: true` is set on a `phase: full` call, the
> orchestrator is required to capture and pass the baseline itself (see
> `/vuln` command Step 3); under that gate, **`baseline_tests:
> run-fresh` is invalid** because the captured baseline cannot survive the
> AWAITING_REVIEW boundary.

1. **Baseline** — If `baseline_tests: run-fresh`, invoke `test-baseliner` in `capture` mode.
   If `baseline_tests: provided`, the orchestrator has already captured the baseline — skip this step.
   - On `status: RUN_FAILED` or `COMMAND_NOT_FOUND`: set output `status: BASELINE_FAILED`, return.
   - On `status: NO_TESTS`: the project has no runnable test suite. Proceed with the fix
     (steps 2-3), then **skip step 4 (Verify) entirely** — there is nothing to diff against —
     and go straight to step 5, noting in the output that no test suite was found.

2. **Apply fix** — Update the version pin(s) listed in the research report's `files` array.
   Use the ecosystem-appropriate update command (see `${CLAUDE_PLUGIN_ROOT}/references/fix-vuln/build-systems.md`).

3. **Build** — Run the project build (compile only, no tests). On failure see "Build failure" below.

4. **Verify** — Invoke `test-baseliner` in `verify` mode, passing the baseline from step 1.
   - `status: OK` → proceed to step 5.
   - `status: REGRESSIONS` → follow "Test regression" below.
   - `status: RUN_FAILED` → revert fix, set `status: BUILD_FAILED`, return.

5. **Commit & PR** — Follow the Git Workflow in `/vuln` exactly.
   Branch name, commit message, and PR body must conform to that spec.

6. **Output** — Produce the result record (see `${CLAUDE_PLUGIN_ROOT}/references/handoff/vuln-fixer.md` output format).

## Build failure

1. Read the full error; attempt an obvious automatic fix (wrong API, missing plugin).
2. If unfixable in one attempt: revert the change, set `status: BUILD_FAILED`, report clearly.

## Test regression

Subagents have no access to interactive tools — `AskUserQuestion` is unavailable even if
granted, so this agent can never ask the user directly. The orchestrator owns that decision.

1. Inspect failures — are they caused by the version bump (API change, renamed class)?
2. If fixable automatically (import rename, trivial API migration): fix and note in output, then proceed to step 5 (Commit & PR).
3. If not fixable: **stop here.** Return `status: TEST_REGRESSION` with the full list of
   newly-failing tests and a one-line diagnosis of the likely cause. Do NOT commit or open
   a PR. The orchestrator asks the user (see `/vuln` "Handling Test Failures") and
   re-invokes this agent with `phase: regression-resume` + `regression_decision`.
4. **On `phase: regression-resume`:** honor `regression_decision`:
   - `keep-anyway` → proceed to step 5 (Commit & PR), flagging the failures in the PR body.
   - `revert` → revert the fix, set `status: REVERTED`, return.
   Record the outcome in the output record.

## Invariants

- Process one CVE per invocation.
- Never push to `main`/`master` — always use a dedicated fix branch.
- Always include the `Co-authored-by: Claude` trailer (see `/vuln`).
- NEVER dispatch any subagent other than `test-baseliner`. That one dispatch is your entire `Task` authority. **Never dispatch a reviewer of your own.** Review is the caller's to schedule, not yours. Your caller deliberately runs no reviewer on some paths — a SIMPLE / MODERATE run is classified out of the Opus `code-review` gate on purpose — so a reviewer you spawn silently overrides the caller's own gate policy. Its verdict has no standing either: the caller never sees it, and you cannot act on it without exceeding your brief.

## Model Routing

If the orchestrator passes a `model_routing` block (see
`${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §4):

- Record it in the output result record so the final report can quote it.
- If the block contains `gate_tests_on_review: true` (set by the orchestrator
  for SIGNIFICANT / HIGH-RISK CVEs), **stop after step 3 (Build)** and return
  `status: AWAITING_REVIEW` with the list of files changed and the build
  outcome. **Do NOT run `test-baseliner verify`, do NOT commit, and do NOT
  open a PR.** The orchestrator will perform an Opus code review, then
  re-invoke this agent with `phase: verify-resume` to run step 4 onward
  (verify, commit, PR).
- For SIMPLE / MODERATE classification (or no `model_routing` block), proceed
  through all steps as normal.

This agent itself runs under whichever model the orchestrator selected.
Opus is reserved for `vuln-research` planning and the post-impl review — not
required for the actual file edits.

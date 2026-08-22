---
name: upgrade
description: Component upgrade workflow. Upgrades libraries, frameworks, runtimes, or build tools to specified or latest versions. Plans with Opus for complex upgrades, runs code review, and verifies with tests.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Upgrade components: $ARGUMENTS

Each token is one of: `component:1.2.3` (exact), `component:minor` (latest patch on current minor), `component:latest` (latest stable), `component:lts` (latest LTS), or bare `component` (latest compatible with everything else).

`component` can be a library, framework, language runtime, build tool, or path like `.github/workflows`.

All changes are left **uncommitted** on the current branch.

---

## Phase 0 — Specs-repo preflight

Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. This runs against `$SPECS_PATH` only — `git -C "$SPECS_PATH"`, never a `cd`, so the code repo this run is about to upgrade is untouched (§1 rule 1). Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

---

## Phase 1 — Compatibility Planning (no files changed)

1. **Inventory** — Detect all components and their current versions from build files, runtime version files, and CI YAML. Use `${CLAUDE_PLUGIN_ROOT}/references/upgrade/ecosystems.md`.

2. **Resolve requested targets** — Apply the `Version Resolution` section below to each requested token.

3. **Delegate planning in parallel** — Spawn one planner task per requested component. Use a single agent message for the whole batch.

   Use this pattern for each component:

   ```
   task(
     subagent_type: "dev-workflows:upgrade-planner",
     model: `<detection_model — §2.1 Sonnet chain>`,
     description: "Plan component upgrade",
     prompt: "## Upgrade Plan Request
     repo: [absolute repo path]
     component: [component name]
     target: [exact | minor | latest | lts | bare]
     other_upgrades:
       - name: [other requested component]
         target: [its target token]
     repo_inventory:
       [component]: [current version]
     model_routing:
       classification: [SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK]
       reason: <one-line>
       current_model: <the model this orchestrator is running under>
       detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # upgrade-planner, test-baseliner; upgrade-executor (SIMPLE/MODERATE); review-fixer
       planning_model: <§2 Opus chain>   # risk-planner (SIGNIFICANT/HIGH-RISK; frontmatter-pinned, recorded, no override); upgrade-executor escalates here only if HIGH-RISK
       review_model:  <§2 Opus chain>    # code-review (frontmatter-pinned; recorded, no override)
       opus_available: <true if a §2 Opus model resolved, else false>
       gate_tests_on_review: <true for SIGNIFICANT/HIGH-RISK, false otherwise>
       notes: <any §2 / §2.1 fallback or degradation>"
   )
   ```

4. **Collect planner results**
   - `READY` → candidate for execution
   - `NOT_FOUND` → warn and skip
   - `CONFLICT` → surface `conflict_details` and ranked `alternatives`; do not proceed until the conflict is resolved or the component is skipped

   For each `READY` component, write its planner handoff to a temp file (`mktemp -t dw-upgrade-plan-XXXX.md`, never inside a repo tree) and record its absolute path as the component's `plan_file` (it persists into Phase 2); the risk-planner, executor, and resume steps below receive this path instead of the pasted handoff.

5. **Classify each READY component** — Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then apply them using the actual resolved change, related upgrades, and planner findings. Print one classification line per component. When in doubt, escalate to `SIGNIFICANT`.

6. **Risk plan for SIGNIFICANT / HIGH-RISK components** — For every component classified `SIGNIFICANT` or `HIGH-RISK`, invoke `risk-planner` before execution (frontmatter-pinned to Opus; recorded as `planning_model` above, no `model:` override needed):

   ```
   task(
     subagent_type: "dev-workflows:risk-planner",
     description: "Plan risky upgrade",
     prompt: "Task description: Upgrade [component] from [current] to [target] in this repo.
     Classification: [SIGNIFICANT | HIGH-RISK] — reason: [routing trigger]
     Upgrade plan: read it from the file at [`plan_file`]
     Current state: branch = [git branch], uncommitted = [git status --short summary]

     Before writing the plan, grep the repo for import sites and usage patterns of this component to understand blast radius, migration order, test coverage, and rollback."
   )
   ```

   If the planner returns `### Re-classification`, surface it and let the user accept the down-classification, override it, or cancel the component.

7. **Confirm the full plan** — Present the resolved component list, classifications, related upgrades, and any Opus plans. Do not touch files until approved.

---

## Phase 2 — Execution (after user confirms)

### Phase 2 prep (once)

1. **Create feature branch**
   - Run `git status --porcelain`. If dirty, show the diff summary and ask whether to stash, proceed anyway, or cancel.
   - Resolve the branch name per `${CLAUDE_PLUGIN_ROOT}/references/branch-naming.md` — **the repo's own documented convention wins**. Read the repo's `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `DOCUMENTATION-GUIDELINES.md`, `CLAUDE.md` for a branch-naming section (§1.1) and fill its segments (§1.2): an **identity** placeholder from the §2 ladder (`$GIT_USER_INITIALS` → `git config user.initials` → inference → the §2.5 prompt), an **issue-key** segment from the run's Jira key when it has one (else the documented no-issue literal), and the **description** segment from the slug `upgrade-<component>-to-<version>` (or `upgrade-<first>-and-<N>-more` for a batch). Never add an identity segment the pattern does not ask for. Only when no convention is documented (§1.4) build `<prefix>/<slug>` with the §2 ladder's fallback `chore/`.
   - If HEAD is on a non-default branch with ahead commits, ask whether to branch from current position, branch from default, or cancel.
   - Run `git checkout -b <branch-name>`. If it exists, append `-<7-char-sha>`.

2. **Capture baseline tests** — Invoke the existing test baseline agent once and reuse the result for the entire batch:

   ```
   task(
     subagent_type: "dev-workflows:test-baseliner",
     model: `<detection_model — §2.1 Sonnet chain>`,
     description: "Capture test baseline",
     prompt: "Mode: capture
     Project root: [absolute repo path]"
   )
   ```

   Store the returned baseline; do not re-run baseline capture per component.

### Per-component loop (sequential, in requested order)

3. **Delegate execution** — For each `READY` plan, invoke the executor agent with the planner handoff and the captured baseline.

   ```
   task(
     subagent_type: "dev-workflows:upgrade-executor",
     model: `<detection_model — §2.1 Sonnet chain — for SIMPLE/MODERATE; planning_model — §2 Opus chain — only if HIGH-RISK>`,
     description: "Execute component upgrade",
     prompt: "## Upgrade Execution Request
     repo: [absolute repo path]
     phase: full
     baseline:
       passing_count: [captured count]
       passing_tests:
         - [captured test ids]
     model_routing:
       classification: [component class]
       reason: <one-line>
       current_model: <the model this orchestrator is running under>
       detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # upgrade-planner, test-baseliner; upgrade-executor (SIMPLE/MODERATE); review-fixer
       planning_model: <§2 Opus chain>   # risk-planner (SIGNIFICANT/HIGH-RISK; frontmatter-pinned, recorded, no override); upgrade-executor escalates here only if HIGH-RISK
       review_model:  <§2 Opus chain>    # code-review (frontmatter-pinned; recorded, no override)
       opus_available: <true if a §2 Opus model resolved, else false>
       gate_tests_on_review: [true for SIGNIFICANT / HIGH-RISK, false otherwise]
       notes: <any §2 / §2.1 fallback or degradation>

     read the full READY upgrade plan from the file at [`plan_file`]"
   )
   ```

3a. **Handle an `upgrade-executor` stop.** If the executor returns `status: BLOCKED`, the upgrade plan at `plan_file` could not be read — an orchestrator bug, not a user choice: report the unreadable path to the user, mark this component `BLOCKED` in the Step 7 results table, and stop working this component (do not retry with a fresh planning pass). This applies regardless of classification — skip steps 4–6 for this component and continue the per-component loop with the next one.

4. **Review gate for SIGNIFICANT / HIGH-RISK** — If the executor returns `status: AWAITING_REVIEW`, run the Opus code-review gate before any test verification:
   - Capture the diff to a temp file: write `git add -N . && git diff` to `mktemp -t dw-upgrade-diff-XXXX.patch` (never inside a repo tree) and record its path as `review_diff_file`
   - Write the executor output to a temp file (`mktemp -t dw-upgrade-claims-XXXX.md`, never inside a repo tree) and record its path as `claims_file`. Invoke `code-review` using the approved risk plan, the diff (from `review_diff_file`), and `claims_file: [the path]` (frontmatter-pinned to Opus; recorded as `review_model` above, no `model:` override needed)
   - **Check the review's first line before acting on the verdict.** If it is `Diff: unreadable at <path>`, the orchestrator's own `review_diff_file` could not be read — an orchestrator bug, not a user choice: surface the unreadable path to the user and stop working this component, marking it `BLOCKED` in the Step 7 results table. Do NOT triage the finding and do NOT dispatch `review-fixer`: the finding names a capture failure no fixer can act on, and running the cycle would spend a fix dispatch and a re-review to arrive back here.
   - **Triage sub-step** (before any fixer dispatch): follow `${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md`. For each finding, verify its claimed consequence at the location it names; keep or dismiss; record every dismissal with a reason that disposes of that finding's own claim. Hand the fixer **survivors only**, and carry the dismissal list into this run's report.
   - If review returns `BLOCK` or `PASS WITH RECOMMENDATIONS`, invoke `review-fixer` with model: `<detection_model — §2.1 Sonnet chain>` for the surviving `BLOCKER` and `MAJOR` findings
   - **Handle a `review-fixer` stop.** If its `Stop condition flag` is `NEEDS HUMAN`, do NOT re-run the review: surface the deferred BLOCKER(s) to the user with the reason `review-fixer` gave, mark this component `BLOCKED` in the Step 7 results table, and stop working this component — skip steps 5–6 and continue the per-component loop with the next one. Only when the flag is `CLEAR` do you **overwrite `review_diff_file`** with a fresh `git add -N . && git diff` and re-run the Opus review once against that refreshed path — so the re-review reads the post-fix diff, not the stale pre-fix capture
   - If the second verdict is still `BLOCK`, stop and escalate; do not continue to tests

5. **Resume verify step after review** — Re-invoke `upgrade-executor` with `phase: verify-resume`, the original `READY` plan (from `plan_file`), and the same baseline block captured in Phase 2 prep. If the resumed agent returns `status: BLOCKED`, the re-supplied file path could not be read: report the named path to the user and stop this component. Do NOT retry, and do NOT reconstruct the artifact — a resume that re-derives its own input is the failure `${CLAUDE_PLUGIN_ROOT}/references/context-management.md`'s read-failure contract exists to prevent.

6. **If the executor returns `status: TEST_REGRESSION`**, follow "Handling Test Failures" below, then re-invoke `upgrade-executor` with `phase: regression-resume` + the chosen `regression_decision`, the original `READY` plan (from `plan_file`), and the same baseline block. If the resumed agent returns `status: BLOCKED`, the re-supplied file path could not be read: report the named path to the user and stop this component. Do NOT retry, and do NOT reconstruct the artifact — a resume that re-derives its own input is the failure `${CLAUDE_PLUGIN_ROOT}/references/context-management.md`'s read-failure contract exists to prevent.

7. **Collect results** — Accumulate one summary row per component. Preserve the classification, review verdict, related upgrades applied, and any regression notes.

8. **Post-batch maintenance** — After all components finish, invoke `impl-maintenance` with a compact session handoff summarising what was upgraded, key failures or workarounds, and the overall result. **Always pass `Command run: /upgrade`** in that handoff — omitting it makes `impl-maintenance` default to `/implement`, mislabeling the run.

**Context hygiene.** This was a large run — consider **`/compact`** to free context before your next task (per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3 — non-pipeline, so `/compact` only; guidance only).

9. **Persist plugin feedback (automatic)** — After `impl-maintenance` returns, project its plugin-facing slice into the specs repo by citing `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its `emit-auto` entry point (§6). Pass the Lessons Learned report, `command: /upgrade`, the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only the report's **Command workflow improvements**, **New agents / skills**, and plugin **Reference docs** sections plus the **Key observations** that triggered them (§4 plugin-facing predicate) — never target-project `CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via the §2 specs-first ladder, and writes silently. List the persisted path (or "no plugin-facing signal — nothing persisted") after the lessons-learned report. ADDITIVE — this step NEVER fails the run, NEVER commits (still true — the assertion is scoped to *this step*, which only writes the feedback file; those writes are committed by the separate terminal `commit-artifacts` step, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes into the code repo or the current working directory.

10. **Commit session artifacts (terminal)** — Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/upgrade)` — or `NOISSUE …` when the run resolved no Jira key — and pushes per §4 step 5. It NEVER touches the code repo this run just upgraded: the upgrade changes are left uncommitted on the current branch by `upgrade-executor`, exactly as before. It NEVER force-pushes, NEVER fails the run, and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Print its §6 outcome line as the run's last output, prefixed `Specs repo:`, with any guard notice repeated in full. No `resume.md` is written for `/upgrade` (`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 skip list).

---

## Version Resolution

| Token | Resolution |
|---|---|
| `component:1.2.3` | Use exact version; verify it exists; run compatibility check; surface conflicts (never silently downgrade) |
| `component:minor` | Latest stable patch within current `MAJOR.MINOR.*` |
| `component:latest` | Highest stable release; run compatibility check |
| `component:lts` | Consult official LTS source (see `lts-sources.md`); if lookup fails, ask the user |
| bare `component` | Highest version compatible with all other repo components; report conflict if none found |

---

## Output

```
## Upgrade Summary

| Component  | Before | After  | Class       | Review | Status  | Notes                       |
|------------|--------|--------|-------------|--------|---------|-----------------------------|
| springboot | 3.1.4  | 3.3.11 | HIGH-RISK   | PASS   | OK      | Also upgraded hibernate 6.4 |
| java       | 17     | 21     | SIGNIFICANT | PASS W/RECS | OK | Updated 2 test files        |
| commons-text | 1.10 | 1.11   | MODERATE    | N/A    | OK      |                             |
| redis      | -      | -      | -           | -      | SKIPPED | Not found in project        |

Tests: 142 passed, 0 regressions (baseline: 142 passing)
```

Append a `### Review triage` section with one line per SIGNIFICANT/HIGH-RISK component that went through Opus review: - **Review triage:** [N findings reviewed, M survived] — dismissals: [one line per dismissal, `finding — reason`; or "none"] — or "N/A (SIMPLE / MODERATE, no Opus review)" for components that never reached review.

Include the `impl-maintenance` lessons-learned report after the summary table.

---

## Handling Test Failures

`upgrade-executor` cannot prompt the user directly — dispatched subagents have no access to
interactive tools, even when one is listed in their `tools:`. When it returns
`status: TEST_REGRESSION` (previously-green tests now failing, not auto-fixable), the
**orchestrator** (this command, running in the interactive session) handles the decision:

- Present the failing tests clearly (from the executor's `failing_tests` / `diagnosis`).
- Ask:
  ```
  choices: ["Keep the upgrade and leave the failing tests for you to fix", "Revert this upgrade and skip it", "Investigate further before deciding", "Other… (describe)"]
  ```
- **"Investigate further"** → show more detail (the diff, full failure output) and re-ask
  the same choices — this loops here at the orchestrator until the user picks keep or revert.
- Map the final choice to `regression_decision: keep-anyway | revert` and re-invoke
  `upgrade-executor` with `phase: regression-resume` (see Phase 2 step 6).

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, jira-not-found, cancellation)
- NEVER skip per-component classification after planning
- NEVER use Opus for a `MODERATE` component unless the user explicitly asks for it
- NEVER run tests for a `SIGNIFICANT` / `HIGH-RISK` component before the Opus review returns a non-BLOCK verdict
- NEVER modify files during Phase 1
- NEVER touch files before the upgrade branch exists
- ALWAYS capture the baseline once before executing any component
- ALWAYS pass the same baseline block to `upgrade-executor` on `phase: verify-resume`
- ALWAYS include classification in the final summary table
- ALWAYS run `specs-preflight` at Phase 0 and `commit-artifacts` as the run's last action (per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`) — bounded to `$SPECS_PATH`'s artifact paths (§2.1) and to plugin-created branches (§2.2), always `git -C "$SPECS_PATH"` and never a `cd` (§1 rule 1), never force-pushing, and never failing the run
- After the run, suggest **`/compact`** (a big non-pipeline run) per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3 — compact-only, no clear/resume pointer; guidance only, never auto-run.

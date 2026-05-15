Upgrade components: $ARGUMENTS

Each token is one of: `component:1.2.3` (exact), `component:minor` (latest patch on current minor), `component:latest` (latest stable), `component:lts` (latest LTS), or bare `component` (latest compatible with everything else).

`component` can be a library, framework, language runtime, build tool, or path like `.github/workflows`.

Reference files (read when needed):
- Ecosystem detection and update commands: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/upgrade/ecosystems.md`
- LTS lookup sources: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/upgrade/lts-sources.md`
- Compatibility constraints: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/upgrade/compatibility.md`
- Model routing: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md`
- Planner handoff: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/upgrade-planner.md`
- Executor handoff: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/upgrade-executor.md`
- Test baseline handoff: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/test-baseliner.md`

All changes are left **uncommitted** on the current branch.

---

## Phase 1 — Compatibility Planning (no files changed)

1. **Inventory** — Detect all components and their current versions from build files, runtime version files, and CI YAML. Use `references/upgrade/ecosystems.md`.

2. **Resolve requested targets** — Apply the `Version Resolution` section below to each requested token.

3. **Delegate planning in parallel** — Spawn one planner task per requested component. Use a single agent message for the whole batch.

   Use this pattern for each component:

   ```
   task(
     agent_type: "general-purpose",
     description: "Plan component upgrade",
     # Add model: "claude-opus-4.7" for SIGNIFICANT / HIGH-RISK planning when routing requires it.
     prompt: "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/upgrade-planner.md`
     (fall back to `~/.claude/agents/upgrade-planner.md` if installed at user level).

     Handoff format: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/upgrade-planner.md`

     ## Upgrade Plan Request
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
       ..."
   )
   ```

4. **Collect planner results**
   - `READY` → candidate for execution
   - `NOT_FOUND` → warn and skip
   - `CONFLICT` → surface `conflict_details` and ranked `alternatives`; do not proceed until the conflict is resolved or the component is skipped

5. **Classify each READY component** — Apply `references/model-routing/classification.md` using the actual resolved change, related upgrades, and planner findings. Print one classification line per component. When in doubt, escalate to `SIGNIFICANT`.

6. **Risk plan for SIGNIFICANT / HIGH-RISK components** — For every component classified `SIGNIFICANT` or `HIGH-RISK`, invoke `risk-planner` on Opus before execution:

   ```
   task(
     agent_type: "general-purpose",
     model: "claude-opus-4.7",
     description: "Plan risky upgrade",
     prompt: "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/risk-planner.md`
     (fall back to `~/.claude/agents/risk-planner.md` if installed at user level).

     Task description: Upgrade [component] from [current] to [target] in this repo.
     Classification: [SIGNIFICANT | HIGH-RISK] — reason: [routing trigger]
     Upgrade plan: [paste the READY planner handoff]
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
   - Generate `chore/upgrade-<component>-to-<version>` for a single component, or `chore/upgrade-<first>-and-<N>-more` for a batch. Match the repo's existing prefix convention when obvious.
   - If HEAD is on a non-default branch with ahead commits, ask whether to branch from current position, branch from default, or cancel.
   - Run `git checkout -b <branch-name>`. If it exists, append `-<7-char-sha>`.

2. **Capture baseline tests** — Invoke the existing test baseline agent once and reuse the result for the entire batch:

   ```
   task(
     agent_type: "general-purpose",
     description: "Capture test baseline",
     prompt: "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/test-baseliner.md`
     (fall back to `~/.claude/agents/test-baseliner.md` if installed at user level).

     Mode: capture
     Project root: [absolute repo path]"
   )
   ```

   Store the returned baseline; do not re-run baseline capture per component.

### Per-component loop (sequential, in requested order)

3. **Delegate execution** — For each `READY` plan, invoke the executor agent with the planner handoff and the captured baseline.

   ```
   task(
     agent_type: "general-purpose",
     description: "Execute component upgrade",
     prompt: "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/upgrade-executor.md`
     (fall back to `~/.claude/agents/upgrade-executor.md` if installed at user level).

     Handoff format: `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/upgrade-executor.md`

     ## Upgrade Execution Request
     repo: [absolute repo path]
     phase: full
     baseline:
       passing_count: [captured count]
       passing_tests:
         - [captured test ids]
     model_routing:
       classification: [component class]
       gate_tests_on_review: [true for SIGNIFICANT / HIGH-RISK, false otherwise]

     [paste the full READY upgrade plan verbatim]"
   )
   ```

4. **Review gate for SIGNIFICANT / HIGH-RISK** — If the executor returns `status: AWAITING_REVIEW`, run the Opus code-review gate before any test verification:
   - Capture the diff with `git add -N . && git diff`
   - Invoke `code-review` on Opus using the approved risk plan, the executor output, and the diff
   - If review returns `BLOCK` or `PASS WITH RECOMMENDATIONS`, invoke `review-fixer` for `BLOCKER` and `MAJOR` findings, then re-run the Opus review once
   - If the second verdict is still `BLOCK`, stop and escalate; do not continue to tests

5. **Resume verify step after review** — Re-invoke `upgrade-executor` with `phase: verify-resume`, the original `READY` plan, and the same baseline block captured in Phase 2 prep.

6. **Collect results** — Accumulate one summary row per component. Preserve the classification, review verdict, related upgrades applied, and any regression notes.

7. **Post-batch maintenance** — After all components finish, invoke `impl-maintenance` with a compact session handoff summarising what was upgraded, key failures or workarounds, and the overall result.

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

Include the `impl-maintenance` lessons-learned report after the summary table.

---

## Invariants (always enforced)

- NEVER skip per-component classification after planning
- NEVER use Opus for a `MODERATE` component unless the user explicitly asks for it
- NEVER run tests for a `SIGNIFICANT` / `HIGH-RISK` component before the Opus review returns a non-BLOCK verdict
- NEVER modify files during Phase 1
- NEVER touch files before the upgrade branch exists
- ALWAYS capture the baseline once before executing any component
- ALWAYS pass the same baseline block to `upgrade-executor` on `phase: verify-resume`
- ALWAYS include classification in the final summary table

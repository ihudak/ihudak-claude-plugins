# Changelog

All notable changes to the **dev-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.2.1] — 2026-05-15

### Added
- **`upgrade-planner` agent.** Dedicated sub-agent for analysing a project and
  producing a versioned, step-by-step upgrade plan with risk annotations.
- **`upgrade-executor` agent.** Dedicated sub-agent that executes an approved
  upgrade plan step-by-step, running builds/tests after each step.
- **`vuln-research` agent.** Dedicated sub-agent for vulnerability triage —
  reads advisories, assesses exploitability, and recommends fix vs mitigate.
- **`vuln-fixer` agent.** Dedicated sub-agent that applies vulnerability
  remediation (dependency bumps, code patches) and verifies the fix.
- **Nine handoff reference docs** under `references/handoff/` for sub-agents
  that receive delegated work: code-scanner, diff-summarizer,
  impl-maintenance, jira-reader, test-baseliner, upgrade-executor,
  upgrade-planner, vuln-fixer, vuln-research.

### Changed
- `/upgrade` command refactored to delegate planning and execution to the new
  `upgrade-planner` and `upgrade-executor` agents via the `task` tool.
- `/vuln` command refactored to delegate research and remediation to the new
  `vuln-research` and `vuln-fixer` agents via the `task` tool.
- `CLAUDE.md` expanded from 60 → 204 lines: added skill taxonomy table,
  orchestrator/sub-agent relationship diagram, model-routing contract,
  key invariants, test requirements, update procedures, and guardrails.

## [1.2.0] — 2026-05-15

### Added
- **`guideline-reviewer` agent.** Reviews code and UI for compliance with
  Dynatrace Experience Standards (GUIDElines). Covers component usage
  (AppHeader, DataTable, FilterField, etc.), accessibility/WCAG compliance,
  terminology, settings patterns, and permissions. Reference docs in
  `references/guidelines/`.
- **`api-guideline-reviewer` agent.** Reviews OpenAPI specification files
  against Dynatrace REST API and IAM permission naming guidelines. Two-pass
  review (comprehensive analysis + detailed verification) checking version
  consistency, required elements, naming conventions, IAM scope format,
  HTTP status codes, and schema composition. Reference docs in
  `references/api-guidelines/` (REST API guidelines, permission guidelines,
  and an OpenAPI template).
- **`check_guidelines.py` script** in `references/guidelines/` — automated
  checklist generator for GUIDEline reviews.
- **`checklist-template.md`** in `references/guidelines/` — structured
  review template.

### Changed
- `plugin.json` keywords expanded.
- `marketplace.json` description updated (15 → 17 agents).
- **Model routing reference (`references/model-routing/classification.md`)
  expanded** from 92 to 265 lines — now includes model fallback chain,
  `model_routing` handoff block format, `task` tool delegation pattern,
  mandatory code-review checklist verdicts, and reporting section (synced
  from Copilot CLI port).

## [1.1.0] — 2026-05-10

`plugin.json` and `marketplace.json` declare `1.1.0`. The work landed across seven increments:

- **Increment A** — scaffolding (commit `25c73fc`)
- **Increment B** — `/impl:code` + `test-writer` agent (commit `29a727f`)
- **Increment C** — `/impl:docs` one-shot doc editing (commit `052e772`)
- **Increment D** — `/impl:jira:docs` + `/impl:jira:epics` + 9 agents (commit `e785adb`)
- **Increment E** — hook regex, README refresh, marketplace description refresh
- **Increment F** — per-command routing in `preload-context.sh` per spec §3 table (commit `4e18081`)
- **Increment G** — `/impl` repurposed as a dispatcher (breaking for 1.0.x users); verbatim-copy maintenance tax eliminated (this commit)

### Breaking changes
- **`/impl <description>` no longer runs the code-implementation workflow** (Increment G). In 1.0.x, `/impl <description>` was the canonical invocation for the full code workflow. In 1.1.0, `/impl` is a **dispatcher**: it prints a help message listing the `/impl:*` variants plus `/vuln` / `/upgrade`, then stops. If you have muscle-memory invocations like `/impl add rate limiting`, re-run them as `/impl:code add rate limiting` — the workflow body is unchanged (it lives in `commands/impl/code.md` and is registered as the slash command `/impl:code`). No aliasing; the redirect is a printed message only. Mid-1.1.0, an Increment-A iteration briefly shipped `commands/impl.md` as a verbatim copy of `commands/impl/code.md` with a `<!-- KEEP IN SYNC -->` marker — that approach is **not** what 1.1.0 ultimately ships; Increment G replaced it with the dispatcher to remove ~27 KB of duplication and eliminate the drift risk the marker was trying to manage.

### Added
- **Namespaced command layout.** New directory `commands/impl/` with sub-files `code.md`, `docs.md`, `jira/docs.md`, `jira/epics.md` — these become the slash commands `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics` via Claude Code's directory-to-namespace convention.
- **`/impl:code` full workflow (Increment B).** `commands/impl/code.md` is the canonical code-implementation command: classify → optional Opus planning → feature branch → **capture test baseline (new Pre-Phase 3.5)** → implement → **test-writing + regression verification (new Phase 3.5)** → optional Opus review → Phase 4 maintenance → Phase 5 report. Same structure as the pre-split `/impl`, with the two new test-related phases inserted and three new invariants added (`ALWAYS capture baseline`, `NEVER skip Phase 3.5`, `AFTER two fix-loop attempts, stop and surface`).
- **`commands/impl.md` is now a dispatcher** (final shape after Increment G). Prints a help page listing the four `/impl:*` variants (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`), a Related-commands section for `/vuln` and `/upgrade`, and a migration note pointing 1.0.x users at `/impl:code`. Does not execute any workflow — no classification, no branching, no agents, no git. The file is ~40 lines instead of ~27 KB; no "keep in sync" marker is needed because there is no longer a shadow copy of `commands/impl/code.md`. See the **Breaking changes** section above for the 1.0.x impact.
- **`agents/test-writer.md` (Increment B).** Default-model agent that writes tests for new or changed behaviour based on a diff. Mirrors `test-baseline`'s framework detection and returns `Framework: not detected` immediately if none matches, so the caller can ask the user. Does NOT run tests — the caller runs `test-baseline` verify separately. Hard rules: never retrofit tests for unchanged code, never invent a framework the project doesn't already use, never modify production code.
- **`/impl:docs` full workflow (Increment C).** `commands/impl/docs.md` is the one-shot doc-editing command: classify (always SIMPLE or MODERATE — redirects to `/impl:jira:docs` / `/impl:jira:epics` if the task turns out to be SIGNIFICANT on inspection) → plan with the `/impl:code`-style repo-exploration subagent → implement → validation checks (link integrity, heading structure, frontmatter parse, broken `[[wikilinks]]`) → Phase 4 maintenance → Phase 5 report. No branch, no baseline, no tests, no Opus, no commit — the user manages git manually. Phase 4 handoff sets `Change type: docs` and `Command run: /impl:docs`. Explicit invariants block all five "never" axes.
- **`/impl:jira:docs` full workflow (Increment D).** `commands/impl/jira/docs.md` is the Jira-driven feature-documentation command: Phase 0 vault + docs-repo detection → Phase 1 PR-status filter / refresh policy / `<repos_base>` / optional screenshot paths → Phase 1.5 classification (SIGNIFICANT; Jira read *is* the plan so no Opus planning) → Phase 2 plan + approval → Phase 3 `jira-reader` depth `full` → Phase 4 repo resolution (escalate missing per §15) → Phase 5 parallel `code-diff-summarizer` (batches of 4; aggregate "All PRs unresolved" gate) → Phase 5.5 `doc-location-finder` (3 status branches) → Phase 5.7 `doc-planner` (gap dispositions: ask-user / mark-TODO / skip-with-note) → Phase 6 writer (main command, with three-branch `image_policy` screenshot placement — `local` / `cdn_upload_required` / `ambiguous`) → Phase 6.5 branch setup (conditional on `docs_repo` context + user opt-in at plan approval) → Phase 6.7 `docs-style-checker` + `doc-fixer` + re-lint → Phase 7 `doc-reviewer` Opus gate (1-fix-1-rereview cap; per-BLOCKER escalation) → Phase 8 four maintenance agents in a single message → Phase 9 final report including `### Screenshots to upload manually` when any target used `cdn_upload_required`. Phase 8 handoff sets `Change type: docs` and `Command run: /impl:jira:docs`. Invariants from spec §6 preserved verbatim.
- **`/impl:jira:epics` full workflow (Increment D).** `commands/impl/jira/epics.md` is the Jira-driven Epic-writing command: Phase 0 vault-only context check (refuses to run outside `$VAULT_PATH`) → Phase 1 output dir / code-scan on-off / refresh policy / `<repos_base>` → Phase 1.5 classification (MODERATE; no Opus planning) → Phase 2 plan + approval → Phase 3 `jira-reader` depth `vi-plus-epics` (VI + every Epic linked to it, skipping Stories / Sub-tasks / Research / RFA) → Phase 4 conditional repo resolution (auto-derived from sibling Epics' PR URLs or manual) → Phase 5 conditional parallel `code-scanner` (batches of 4; scanner defaults `pull: true`, deliberately asymmetric with `code-diff-summarizer`'s `pull: false`) → Phase 6 writer (one `.md` per Epic with `## Goal` / `## Business value` / `## Scope (in / out)` / `## Acceptance criteria` / `## Dependencies` / `## Suggested stories` / `## References`) → Phase 7 `epic-reviewer` Opus gate (1-fix-1-rereview cap; "Defer" appends a `## Refinement notes` section to the draft) → Phase 8 four maintenance agents → Phase 9 final report. NEVER branches, NEVER commits, NEVER writes inside `jira-products/` or `_archive/`, NEVER writes outside `$VAULT_PATH`, NEVER runs `docs-style-checker` (enforced by absence of a Phase 6.7). Phase 8 handoff sets `Change type: docs` and `Command run: /impl:jira:epics`.
- **Nine new agents (Increment D).** All declare `tools:` as YAML arrays matching the existing in-repo style (`risk-planner`, `code-review`, `test-writer`).
  - **`agents/jira-reader.md` (§12)** — reads the pre-exported Jira markdown hierarchy under `$VAULT_PATH/jira-products/<JIRA_KEY>/`; three depths (`full` / `vi-plus-epics` / `vi-only`). Output: `value_increment` + `linked_items` + `pull_requests` + `themes`. Parses the Jira-to-Obsidian exporter's two-line-per-PR bulleted format with backticked branch names and a Unicode `→` arrow (not ASCII `->`). Three host categories recognised (`github_cloud`, `bitbucket_cloud`, `bitbucket_server`); `bitbucket_server` detected by the substring rule (hostname contains `bitbucket` and is not `bitbucket.org`), never a hardcoded domain. Inherits the session's model.
  - **`agents/doc-fixer.md` (§10)** — shared between `/impl:jira:docs` and `/impl:jira:epics`. Applies BLOCKER / MAJOR fixes from a `doc-reviewer`, `epic-reviewer`, or `docs-style-checker` output. Returns a `Fix Report` with the same `Stop condition flag` contract as `review-fixer`. Doc-type-agnostic because the finding schema is shared. Inherits the session's model.
  - **`agents/code-diff-summarizer.md` (§13)** — resolves a single repo's PR diffs and returns a doc-focused summary. Host-aware resolver: `gh` CLI for `github_cloud` (when installed + authenticated), local-git Strategies 1–4 for the rest (including GitHub fallback). Strategy 1: Bitbucket Server `refs/pull-requests/*` (usually absent). Strategy 2: branch search (0 or 2+ matches fall through silently). Strategy 3: merge-commit grep (`[Pp]ull[ _-]?[Rr]equest[ _-]?#?<pr_id>\b`). Strategy 4: cross-hierarchy Jira-key commit grep (last resort; summary MUST carry the "reconstructed from commit — may not exactly correspond" caveat). Statuses: `OK` / `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` / `NO_PRS_RESOLVED` / `PARTIAL`. `refresh.pull` defaults to `false`. Inherits the session's model.
  - **`agents/doc-location-finder.md` (§10a)** — finds write target(s) in a docs repository. Heuristic + grep scoring across the detected docs-tree root(s); three placement kinds (`extend-existing` / `new-page-in-existing-section` / `new-section`). Statuses: `OK` / `LOW_CONFIDENCE` (with `confidence_notes`) / `EMPTY`. Never writes. Inherits the session's model.
  - **`agents/doc-planner.md` (§10b)** — synthesises the documentation checklist the writer follows and `doc-reviewer` checks against. Detects the repo's `image_policy` by sampling sibling / ancestor markdown pages: `local` (copy screenshots to `<page-dir>/img/`), `cdn_upload_required` (stage under `/tmp/<JIRA_KEY>-screenshots/` — NEVER inside the repo — and surface in Phase 9), or `ambiguous` (writer prompts the user at Phase 6). Per-page YAML frontmatter updates (including the mandatory `changelog:` append), snippet reuse / extract, cross-links, and gap dispositions. Inherits the session's model.
  - **`agents/docs-style-checker.md` (§10c)** — runs the repo's project-configured prose linter on files written in Phase 6 and normalises output into the shared finding schema. Detection order: Vale via `.vale.ini` → `package.json` `*:lint` / `lint:*` script → `.markdownlint.json(c)` / `.remarkrc*` → `NOT_CONFIGURED`. Severity mapping: `error` → MAJOR, `warning` → MINOR, `suggestion` → NIT. 2-minute cap. Never promotes linter severity. Inherits the session's model.
  - **`agents/doc-reviewer.md` (§9, Opus)** — reviews product documentation written by `/impl:jira:docs`. Eleven dimensions: factual correctness, completeness vs plan, coverage, audience fit, structural integrity, YAML frontmatter, screenshots (both `image_policy` branches), snippets, actionability, source traceability, style-check follow-through (from `docs-style-checker`). Verdict: PASS / PASS WITH RECOMMENDATIONS / BLOCK. `model: opus` declared in frontmatter and `model: "opus"` passed on the caller's Agent call (belt-and-braces, mirroring `risk-planner` / `code-review`).
  - **`agents/code-scanner.md` (§14)** — scans a single code repo for existing capabilities and gaps relative to a set of themes. Pure filesystem search (grep / glob / read); no HTTPS. `refresh.pull` defaults to `true` (capability scans target the default-branch tip — deliberately asymmetric with `code-diff-summarizer`). Per-theme 30-second budget; themes that can't be scanned get `classification: error` + reason and do NOT abort the whole scan. Statuses: `OK` / `PARTIAL` / `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` / `EMPTY`. Inherits the session's model.
  - **`agents/epic-reviewer.md` (§9b, Opus)** — reviews Epic drafts written by `/impl:jira:epics`. Nine dimensions: goal clarity, business value, scope (in / out), acceptance criteria (testable), dependencies, suggested stories, non-duplication (BLOCKER when undetected; cross-checks against `jira-reader` `linked_items` filtered to `type == Epic`), references (code paths must match `code-scanner` `evidence.path` when that output is provided), structural integrity. Never treats the absence of a `code-scanner` output as a finding — the user may have opted out of code examination. `model: opus` in frontmatter + `model: "opus"` on the caller's Agent call.

### Changed
- **`agents/impl-maintenance.md` input / output enums.** The Inputs section now requires a `Command run:` field (one of `/impl`, `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`); missing values default to `/impl:code` with a note in the report. The "Command workflow improvements" output enum broadened to match, so maintenance suggestions from the three new Jira/docs commands are scoped to the right command variant.
- **`commands/vuln.md` and `commands/upgrade.md` session handoffs.** Both now pass `Command run: /vuln` and `Command run: /upgrade` respectively to `impl-maintenance`. Without this, the agent would default to `/impl:code` and misattribute any `/vuln` or `/upgrade` suggestions — a silent regression the spec's Wave 6 W6-m2 + §3 update implied but didn't explicitly call out for the two pre-existing commands.
- **`commands/impl/code.md` Phase 4 change summary block now includes `Change type: code`** (and a matching invariant). Aligns with `/impl:docs` (`Change type: docs`) and the two new Jira commands (both `docs`). The field is a scoping hint for the Documentation / Knowledge / Instructions maintenance agents — their prompts already reference the change summary block, so no agent prompt changes are needed.
- **`hooks/preload-context.sh` regex (Increment E).** Replaced `^/(impl|vuln|upgrade)[[:space:]]+[^[:space:]-]` with `^/(impl(:(code|docs|jira(:(docs|epics))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-]` so `/impl:code`, `/impl:docs`, `/impl:jira:docs`, and `/impl:jira:epics` now trigger context injection. The normative regex is defined in spec §3 and verified against a 28-case matrix. Bare `/impl:jira foo` also matches — the `:(docs|epics)` sub-namespace is optional by design (over-match is preferable to missing a valid invocation). Header comment updated to list all covered commands.
- **`hooks/preload-context.sh` per-command routing (Increment F).** After the regex match the hook now reads `${BASH_REMATCH[1]}` and routes per the spec §3 table: `/impl`, `/impl:code`, `/vuln`, `/upgrade` get the full block (model-routing reminder + git status + recent commits + small-repo directory listing); `/impl:jira:docs` and `/impl:jira:epics` get a `Jira workflow` header with `VAULT_PATH` (or an unset-note fallback), a `repos_base` default (`${REPOS_BASE:-/repos}`), and `git branch --show-current` only when cwd is inside a git repo — no model-routing, no full status/log, no directory listing; `/impl:docs` exits silently (spec: "None — user manages git manually; model-routing is not triggered"). Bare `/impl:jira foo` (spec-intentional over-match) is routed to the Jira branch. Verified with a 10-assertion stdin harness covering all four routing paths plus noise.
- **`hooks/preload-context.sh` — `/impl` moved to silent branch (Increment G).** Follows the dispatcher change. `/impl <args>` now prints help and stops, so injecting the full git context + model-routing reminder would be pure noise before a help screen. `/impl:code`, `/vuln`, `/upgrade` continue to get the full context; `/impl:jira:docs` / `/impl:jira:epics` continue to get the Jira context; `/impl` joins `/impl:docs` in the silent branch. This is a minor deviation from spec §3's "`/impl` (alias) → Full" row, justified by the alias no longer existing; the spec table is superseded for the `/impl` row by Increment G.
- **`agents/impl-maintenance.md` — `/impl` removed from the live Command-run enum (Increment G).** The Inputs section now lists six live values (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`). For replay compatibility with archived 1.0.x handoffs, the literal legacy value `/impl` is still accepted on input and internally mapped to `/impl:code` with a note in the report. The "Command workflow improvements" output enum drops `/impl` entirely — the agent will never suggest changes against a command that no longer runs a workflow.
- **`commands/impl/code.md` Phase 4 handoff (Increment G).** Dropped the now-stale parenthetical on the `Command run: /impl:code` line that explained the "`/impl` alias is a transport detail". The alias is gone; no explanation is needed.
- **`README.md` refresh (Increment E).** Rewritten to document the final 1.1.0 shape: dropped the "1.1.0 in progress" banner; rebuilt the Commands section as a 5-row table for the `/impl` family plus a secondary 2-row table for `/vuln` and `/upgrade`; rebuilt the Agents section as 15 rows with a Model column (Opus for `risk-planner`, `code-review`, `doc-reviewer`, `epic-reviewer`; `inherits` for the other 11); added an Environment prerequisites section covering `gh auth login`, optional `vale`, and the recommended [ihudak/ai-containers](https://github.com/ihudak/ai-containers) environment (per spec §17); updated the Hooks table to list the seven command shapes the matcher now covers.
- **`.claude-plugin/marketplace.json` dev-workflows description (Increment E).** Refreshed from "Three slash commands (/impl, /vuln, /upgrade) … five reusable subagents … three notification hooks" to name all five `/impl`-family commands plus `/vuln` and `/upgrade`, list all fifteen subagents, and describe the three notification / context hooks. `version` field unchanged (1.1.0).

Design spec: `docs/superpowers/specs/2026-04-30-impl-split-and-test-writing-design.md`.
Review history: `docs/superpowers/specs/2026-05-08-impl-split-and-test-kiro-review.md` (waves 1–7).

---

## Pre-plugin-split history (prior monorepo)

The sections below describe the original [`ihudak-claude-plugins`](https://github.com/ihudak/ihudak-claude-plugins) monorepo from which this plugin was extracted. They reference infrastructure that no longer applies to the standalone plugin — root-level `install.sh` / `uninstall.sh` / `install.ps1`, `plugins/workflow-tools/`, `tests/smoke.sh`, and `~/.claude/settings.json` hook merging. Retained as provenance; not part of the **dev-workflows** plugin's own version history.

### [Unreleased] (pre-plugin-split)

#### Added
- **Model routing across `/impl`, `/vuln`, `/upgrade`.** Every command now classifies the task as `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK` before planning. `SIMPLE` / `MODERATE` continue on the currently selected model. `SIGNIFICANT` / `HIGH-RISK` route planning and post-implementation review through Opus and gate the test run on the review verdict.
- **`agents/risk-planner.md`** — Opus-backed risk-weighted planner system prompt. Returns a structured plan with explicit security, migration, API-stability, concurrency, dependency, rollback, and test-adequacy sections. Refuses to run without a classification. Includes a re-classification escape hatch: if the task turns out to be `SIMPLE` / `MODERATE` on inspection, the planner returns a `### Re-classification` section instead of the full plan and the caller falls back to the non-Opus path.
- **`agents/code-review.md`** — Opus-backed post-implementation reviewer system prompt. Checks eight dimensions (correctness, security, architecture, edge cases, migration risks, dependency risks, test adequacy, rollback). Returns `PASS` / `PASS WITH RECOMMENDATIONS` / `BLOCK`. `BLOCK` gates the test run. Same re-classification escape hatch.
- **`agents/test-baseline.md`** — moved from `plugins/workflow-tools/` to the repo's top-level `agents/`. Same behaviour, now installed at `~/.claude/agents/test-baseline.md` as a user-level subagent.
- **`agents/review-fixer.md`** — default-model agent that auto-fixes BLOCKER and MAJOR findings from a code-review report, deferring findings that require design judgment, migration sequencing, or cross-cutting test strategy. Returns a structured fix report with a `Stop condition flag` so callers know whether to re-review. Wired into all three commands' BLOCK and PASS-WITH-RECOMMENDATIONS branches.
- **`agents/impl-maintenance.md`** — default-model suggest-only post-session analyst. Reads the session handoff, scans existing rules/hooks/agents, returns a structured Lessons Learned report (CLAUDE.md rules, hooks, reference doc gaps, new agent suggestions, command workflow improvements). Does not write files.
- **`references/model-routing/classification.md`** — single source of truth for the four complexity levels, the triggers, the routing rules, and the eight review dimensions. All three commands link to it.
- **`tests/smoke.sh`** — install → uninstall → install smoke test in a throwaway `HOME`. 54 assertions. Covers full install, idempotent re-run, subtractive `--no-hooks`, `--no-plugin` rejection (the flag is retired), `uninstall.sh`, round-trip re-install, legacy `plugins/workflow-tools` cleanup, JSON validity, and agent-file frontmatter validation.
- **`uninstall.ps1`** — native Windows uninstaller (PowerShell). Mirrors `uninstall.sh`: removes managed symlinks/copies and strips hook entries from `settings.json` if Python is available.
- **`.gitignore`** — added `settings.local.json`, `settings-local.json`, `.claude/settings.local.json` to prevent accidental commit of Claude Code machine-specific overrides.
- **`test-baseline.md` verify mode** — second mode alongside `capture`: re-runs tests, diffs against a prior baseline, returns a structured regression report (regressions, missing-from-run, newly fixed, new failures, current snapshot for chaining). All three commands now use verify mode for post-fix comparisons.
- **Feature-branch pre-step in `/impl`, `/vuln`, `/upgrade`** — clean-tree check (stash/proceed/cancel), branch-convention detection, slug generation, HEAD context check, `git checkout -b` BEFORE any file is written. Branch naming: `feat/<slug>` for impl, `chore/upgrade-<component>-to-<ver>` for upgrade, `fix/[JIRA-]CVE-XXXX-XXXXX` for vuln.
- **Ruby/Bundler section in `references/fix-vuln/build-systems.md`** and **PHP/Composer section in `references/upgrade/ecosystems.md`** — expand ecosystem coverage to match `/vuln` Detect agent scan list.

#### Changed in commands
- **`/impl`** — new Phase 1.5 classification step; for `SIGNIFICANT` / `HIGH-RISK`, planning is delegated to `risk-planner` (Opus) and the post-implementation `code-review` (Opus) gates the test run. Implementation itself stays on the currently selected model or Sonnet — Opus is reserved for planning and review. Phases 4 and 5 include the classification and the review verdict. Phase 2B "Revise" re-sends the full risk-planner brief (the planner refuses partial briefs).
- **`/vuln`** — step 5 classifies each CVE on the actual change required (same-major patch/minor bump → `MODERATE`; major bump or API-break or security-sensitive code path → `SIGNIFICANT` / `HIGH-RISK`). `MODERATE` keeps the existing flow; `SIGNIFICANT` / `HIGH-RISK` delegate planning to Opus, review the fix with Opus, and gate tests on the verdict. Classification is included in the commit message and PR body. The risk-planner brief no longer overstates the inputs — it passes declaration paths from the Detect agent and lets the planner do its own usage-site grep.
- **`/upgrade`** — Phase 1 step 5 classifies each component. `MODERATE` components follow the existing apply → build → test path. `SIGNIFICANT` / `HIGH-RISK` components plan with Opus (Phase 1 step 8) and get an Opus review before build/test (Phase 2 step 6). Summary table gains `Class` and `Review` columns. Same brief-correctness fix as `/vuln` — the brief passes inventory paths + Agent A's compat output and delegates usage-site scanning to the planner.

#### Changed in hooks
- **`preload-context.sh`** — injects a one-line model-routing reminder before the existing git context for `/impl`, `/vuln`, `/upgrade`. Points at `references/model-routing/classification.md` so the rules are one read away. Regex tightened to require at least one non-whitespace, non-hyphen argument so bare `/impl` or `/impl --help` no longer triggers a context injection. Directory listing now gated to repos with ≤30 root entries — large repos no longer leak the listing into context.

#### Changed in installers / docs
- **`install.sh --no-hooks` is subtractive**, not just a skip-flag. It actively removes previously-installed hook symlinks and strips matching entries from `settings.json` so the post-flag state matches what users expect.
- **`uninstall.sh` and `uninstall.ps1` symlink matching tightened** — require a path-segment boundary (`/claude-config/` rather than a loose substring) so unrelated paths like `claude-config-backup` can't be matched.
- **`install.sh` / `install.ps1` legacy-plugin cleanup** — on upgrade from a pre-restructure install, both installers remove any leftover `~/.claude/plugins/workflow-tools` symlink and drop the empty `~/.claude/plugins/` parent if nothing else lives there.
- **`README.md`** — surfaces the Windows installation path from the main Install section; adds the native Windows uninstall command and update workflow; documents the new `Class` / `Review` columns in the `/upgrade` example table; new "Subagents" section explaining the `general-purpose` + `model: "opus"` invocation pattern; replaces "commands + plugin" framing with "commands + agents".

#### Fixed
- **Subagent invocation pattern: `general-purpose` + `model` override.** Earlier iterations of this release tried two layouts that did not actually register the subagents — `plugins/workflow-tools/` (which requires marketplace registration + `installed_plugins.json` + `enabledPlugins`, not satisfied by a local symlink) and a user-level `agents/*.md` install (which requires a session restart to be discovered). Both produced static-correctness wins but a no-op routing in the installing session. The three commands now invoke the agents via `Agent(subagent_type: "general-purpose", model: "opus", prompt: "Read and adopt ~/.claude/agents/<name>.md, then [brief]")`. The `model` argument on the `Agent` tool itself forces Opus for `risk-planner` / `code-review` regardless of discovery; `test-baseline` omits the override and inherits the session's model. Agent files are still installed at `~/.claude/agents/` so a future Claude Code release with reliable user-agent discovery can invoke them directly with no further changes. Verified empirically in-session. Removes the `--no-plugin` installer flag (the agents are required by `/vuln`, `/upgrade`, and the Opus-gated `/impl` flow — there is no opt-out).
- **`agents/risk-planner.md` and `agents/code-review.md` cite classification rules by absolute path** (`~/.claude/claude-config/references/model-routing/classification.md`). The agents' working directory is the caller's project, not this repo, so relative paths wouldn't resolve.
- **Classification file-count threshold made exclusive** — was `more than 3-5` on SIGNIFICANT and `fewer than 3-5` on MODERATE, which both matched at exactly 4. Pinned to `4 or more` for SIGNIFICANT and `3 or fewer` for MODERATE.
- **`agents/test-baseline.md` Makefile parse row** — previously detected `make test` but had no parse pattern; a Make-driven project would silently get `Total: 0 | Passing: 0 | Failing: 0`. The parse table now has a Make row with best-effort pattern matching and a note explaining the limitation.
- **`install.ps1` / `uninstall.ps1`** — removed PowerShell 7+ only operators (`||`, `??`) that broke on Windows PowerShell 5.1 (the default on Windows 10/11). Replaced with PS5.1-compatible forms.
- **`install.ps1` / `uninstall.ps1`** — replaced em-dashes and box-drawing characters with ASCII. Windows PowerShell 5.1 reads BOM-less script files using the ANSI code page, which mangled UTF-8 multi-byte sequences and caused parser errors at every line with fancy characters.
- **`uninstall.ps1`** — probe Python with a real `--version` call before using it, so the Windows Store `python3.exe` stub (a placeholder that errors at runtime) is correctly identified as "not Python" and the script prints a helpful skip-message instead of a red error.
- **NVD/Detect circular dependency in `/vuln`** — split research into Round A (NVD + Baseline in parallel, no package name needed) then Round B (Detect agents per CVE, package names now known). Per-CVE failure handling explicit.
- **`subagent_type: "Explore"`** replaced with `general-purpose` + explicit Read/Glob/Grep/LS tool restrictions in `/impl` and `/vuln` (Explore is not a valid Claude Code Agent type).
- **`git diff` for new-file-only implementations** — all three commands now use `git add -N . && git diff` so the code-review agent never receives an empty diff.
- **`/upgrade` Agent B is now read-only** in Phase 1; changes are applied in Phase 2 prep step 3, AFTER baseline capture, so the baseline is pristine.
- **`/upgrade` Opus planning** moved before user confirmation; user now sees the full Opus-generated plan before approving.
- **`code-review.md` `Bash` removed from tools list** — reviewer must be read-only; the "NEVER modify files" prompt rule is now enforced by the toolset.
- **Stop condition enforcement** — all three commands enforce: after one review-fixer pass + one re-review, if verdict is still BLOCK, stop and surface to user. No infinite loops.
- **OWASP filter regex** in `/vuln` — `A\d` → `A\d{2}` (OWASP IDs use two digits).
- **`/vuln` Detect agent scan list** expanded to include `*.csproj`, `Gemfile`, `composer.json` (aligning with `build-systems.md` coverage).
- **`hooks/test-notify.sh` ARG_MAX** — switched from passing test output as argv to stdin pipe; large test outputs (>128KB on Linux, >256KB on macOS) no longer crash the hook.
- **`commands/vuln.md` SIGNIFICANT/HIGH-RISK path numbering** — fixed duplicated step 4, missing step 5; downstream references updated.
- **`commands/upgrade.md` Phase 2 structure** — split into "Phase 2 prep (once)" + per-component loop with unambiguous numbering (prep: 1–3, loop: 1–8).
- **`commands/impl.md` Phase 4 agent count** — corrected "three agents" → "four agents".
- **`commands/impl.md` Phase 5 report** — now surfaces feature-branch name under `### Branch`.
- **`references/model-routing/classification.md`** — "4+ non-test files" threshold qualified to require non-trivial logic changes (excludes pure renames, import updates, mechanical refactors, generated-code changes).
- **`references/fix-vuln/nvd-api.md` safe-version derivation** — added worked examples for `.Final`/`-RELEASE` suffixes; clarified range-matching against project's current version line to avoid wrong-range selection.
- **`references/upgrade/compatibility.md`** — new "Known major migrations" section documenting Spring Boot `javax`→`jakarta` migration with detection command, fix approach, and companion changes.
- **`/upgrade` companion-upgrade chain** — now hard-capped at 3 levels with cycle detection; chains exceeding the limit are surfaced as `BLOCKED — companion-cycle` in the summary table (matters for unattended ai-container runs).
- **`hooks/preload-context.sh`** — directory listing gated to repos with ≤30 root entries; large repos no longer leak the listing into context.
- **`/vuln` commit template** — removed hardcoded `Co-authored-by: Claude Code <noreply@anthropic.com>` (some corp Bitbucket instances reject the email).
- **All PowerShell code fences in `references/fix-vuln/build-systems.md`** corrected to `bash` fences.

#### Verified
- End-to-end install and uninstall on Windows with both Windows PowerShell 5.1 and PowerShell 7.6.1. PS 5.1 falls back to file copies (no Dev Mode / admin); PS 7.6.1 successfully creates symlinks. Round-trip install → uninstall → install works cleanly on both. Smoke test (`tests/smoke.sh`) is 54/54 green on Linux.

### 2026-04-24 (monorepo 1.1.0)

#### Added
- **`uninstall.sh`** — idempotent reverse of `install.sh`; removes managed symlinks and strips our hook entries from `~/.claude/settings.json`.
- **`install.sh --no-hooks` / `--no-plugin` / `--help`** flags for granular installs.
- **`install.ps1`** — native Windows installer (PowerShell). Creates symlinks with auto-fallback to file copy when Developer Mode / admin isn't available. Skips hooks (bash-only).
- **`references/fix-vuln/`** and **`references/upgrade/`** — reference docs for `/vuln` and `/upgrade` are now vendored into the repo (previously external at `~/.copilot/skills/`).
- **`CHANGELOG.md`** — this file.

#### Changed
- **Hook field names corrected**: `preload-context.sh` now reads the `prompt` field (with `user_prompt`/`message` fallbacks) from the UserPromptSubmit payload; `test-notify.sh` now reads `tool_input.command` and `tool_response.output` (with top-level fallbacks) from the PostToolUse payload. Both hooks were previously silently exiting early due to reading the wrong fields.
- **`preload-context.sh` hardening** — removed `set -euo pipefail`, added `python3` availability guard, error-tolerant command substitution. Matches the robustness of `test-notify.sh`.
- **`/impl` step 8 agents** now receive a structured change summary block (including `git diff --stat` output and notable additions/removals) instead of a one-sentence description. Documentation, knowledge, and instructions agents can now reason precisely about what changed.
- **`install.sh` location guard** — refuses to run unless located at `$HOME/.claude/claude-config/`. Prevents silent misconfiguration when the repo is cloned elsewhere.
- **`install.sh` plugin symlink** — now unconditionally `rm -rf`s the target before `ln -sf`, preventing the "stray nested symlink" bug that occurred on repeated runs.
- **`install.sh` settings.json guard** — creates an empty `{}` skeleton if `~/.claude/settings.json` doesn't exist, rather than crashing.
- **`test-notify.sh` output parsing** — uses `python3` for framework output parsing (portable) instead of `grep -oP` (GNU-only, fails on macOS).
- **`/vuln` intro** — clarified the sequential-then-parallel execution model.
- **`/upgrade` Phase 2 step 3** — excludes `.github/workflows/` to prevent GitHub Actions from being processed twice.
- **README** — added detailed per-command phase explanations, Windows section, uninstall instructions, install-flag table.

### 2026-04-24 (monorepo 1.0.0)

Initial shareable repo.

#### Added
- **`commands/impl.md`** — `/impl` command with Explore subagent before planning and three parallel post-implementation agents (Documentation / Knowledge / Instructions).
- **`commands/vuln.md`** — `/vuln` command with parallel NVD / Detect / Baseline research before fix.
- **`commands/upgrade.md`** — `/upgrade` command with parallel compatibility research and GitHub Actions agents in Phase 1; uses `workflow-tools:test-baseline` for the test baseline.
- **`plugins/workflow-tools/`** — plugin with the reusable `test-baseline` agent (Maven / Gradle / npm / pytest / Makefile detection).
- **`hooks/notify-done.sh`** — Stop hook; cross-platform desktop notification (macOS / Linux / WSL2 fallback chain).
- **`hooks/preload-context.sh`** — UserPromptSubmit hook; injects git branch/status/log for `/impl` / `/vuln` / `/upgrade`.
- **`hooks/test-notify.sh`** — PostToolUse:Bash hook; parses test output and notifies.
- **`install.sh`** — idempotent installer; `ln -sf` symlinks + Python JSON merge.
- **`settings-additions.json`** — hook entries merged into `~/.claude/settings.json`.
- **`README.md`** — setup, usage, and platform notes.
- **`docs/specs/2026-04-24-command-subagents-hooks-design.md`** — design document.

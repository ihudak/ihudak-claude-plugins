# Agents reference

`dev-workflows` bundles 34 reusable subagents under `agents/`, dispatched internally by the invoking command via `subagent_type: "dev-workflows:<name>"` — none of them is a user entry point. Nine carry a `model: opus` frontmatter pin (shown as **opus** below) and run on Opus every time, regardless of the dispatching command's own model tier for that run; the remaining 25 carry no pin (shown as **per routing**) and are assigned a tier by the dispatching command per the task-complexity classification in `classification.md`. Agents are grouped below by role — reviewers and planners, readers and scanners, writers, fixers, and maintenance — and each row's **Used by** column lists only the commands that actually dispatch that agent as a subagent; a command that merely names another command's agent in passing (for example, `/implement` noting that a design was already reviewed upstream by `design-reviewer`, or `/design` noting it does *not* call `jira-reader`) is not counted as a dispatch.

## Reviewers and planners

Opus-gated quality gates, plus the lighter-weight planners and style checkers that feed or precede them.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `ard-reviewer` | opus | Read, Glob, Grep | Reviews an ARD for grounding integrity, well-formed `AD#N` rules, non-contradiction with inherited PRD-level invariants, and altitude purity; returns PASS / PASS WITH RECOMMENDATIONS / BLOCK. | `/create-ard` |
| `code-review` | opus | Read, Glob, Grep | Post-implementation review for SIGNIFICANT / HIGH-RISK changes — correctness, security, architecture, edge cases, migration, dependencies, tests, rollback; gates the test run. | `/implement`, `/upgrade`, `/vuln` |
| `design-reviewer` | opus | Read, Glob, Grep | Reviews an engineering design against the design-format authority and its specification, treating any unresolved design open question as a BLOCKER. | `/design` |
| `doc-reviewer` | opus | Read, Glob, Grep | Reviews product documentation written by `/document` for correctness, completeness, and fitness for purpose; product-docs only — Epic drafts go through `epic-reviewer`. | `/document` |
| `epic-reviewer` | opus | Read, Glob, Grep | Reviews Epic drafts for goal clarity, testable acceptance criteria, scope boundaries, and non-duplication with existing Epics under the parent PRD. | `/epics` |
| `readiness-reviewer` | opus | Read, Glob, Grep | Cross-artifact readiness verifier — checks the ARD/spec/design justify the Jira status and the next transition; the only reviewer that does joint cross-artifact analysis. | `/ready` |
| `risk-planner` | opus | Read, Glob, Grep, Bash, WebFetch, WebSearch | Risk-weighted planner for SIGNIFICANT / HIGH-RISK tasks; returns a structured plan with an explicit risks section. Never dispatched for SIMPLE / MODERATE work. | `/implement`, `/upgrade` |
| `spec-reviewer` | opus | Read, Glob, Grep | Reviews a specification for per-stage quality, cross-stage consistency, coverage, and identifier integrity. | `/specify` |
| `prd-reviewer` | opus | Read, Glob, Grep | Reviews a Product Requirements Document for goal crispness, testable stories/criteria, internal consistency, measurable metrics, and product-level purity (no implementation detail). | `/create-prd`, `/update-prd` |
| `api-guideline-reviewer` | per routing | Read, Glob, Grep | Reviews an OpenAPI spec against the bundled REST API and IAM permission naming guidelines — version consistency, naming, IAM scope format, status codes, schema composition. | `/api-guideline-reviewer` |
| `guideline-reviewer` | per routing | Read, Glob, Grep, Bash | Reviews app code and UI against public design-system and accessibility standards — app header, data table, permissions, accessibility/WCAG, terminology, data naming. | `/guideline-reviewer` |
| `docs-style-checker` | per routing | Read, Glob, Grep, Bash, Task | Runs the docs repo's configured prose linter and, when the prose-style plugin is installed, a complementary prose-style pass; merges both finding sets for `doc-reviewer`/`doc-fixer`. | `/document` |
| `doc-planner` | per routing | Read, Glob, Grep | Synthesises Jira data, per-repo diff summaries, and confirmed write targets into the documentation checklist the writer follows and the reviewer checks against; writes no content itself. | `/document` |
| `interface-designer` | per routing | Read, Glob, Grep, Bash | Produces one interface proposal for one contested interface under one named design constraint, for `/design`'s optional three-take Phase 5 fan-out. | `/design` |
| `upgrade-planner` | per routing | Read, Glob, Grep, WebFetch | Detects a component, resolves its requested target version, and verifies compatibility with every other component in the repo; one instance per component, dispatched in parallel. | `/upgrade` |

## Readers and scanners

Read-only discovery and grounding — each returns a structured digest rather than editing anything. `test-baseliner` is the one that touches the working tree at all: it holds `Bash` because its job is to *run* the suite, so build and coverage output appears as a side effect.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `code-scanner` | per routing | Read, Glob, Grep, Bash | Scans one code repository for existing capabilities and gaps relative to a set of themes; pure filesystem search, designed for parallel per-repo invocation capped at 4 concurrent. | `/create-ard`, `/design`, `/epics`, `/idea`, `/implement`, `/specify` |
| `counterpart-finder` | per routing | Read, Glob, Grep, Bash | For a space-constrained `/document` run, finds the counterpart space's existing docs for the same feature as read-only grounding; never writes and never adds images to the pipeline. | `/document` |
| `diff-summarizer` | per routing | Read, Glob, Grep, Bash | Reads one repository's PR diff(s) and returns a documentation-focused summary; host-aware — `gh` CLI for GitHub when available, pure local git for Bitbucket and GitHub fallback. | `/document`, `/release-notes` |
| `doc-location-finder` | per routing | Read, Glob, Grep | Finds the right place(s) in a docs repository to write new or extended documentation, returning a prioritised list of write targets with rationale; heuristic search, no content written. | `/document` |
| `docs-grounder` | per routing | Read, Glob, Grep, Bash | Read-only `$DOCS_PATH` grounding — retrieves the most relevant existing product-doc pages and returns a bounded digest of positive references plus reconciliation challenges. | `/create-ard`, `/create-prd`, `/epics`, `/idea`, `/release-notes`, `/specify`, `/update-prd` |
| `idea-reader` | per routing | Read, Glob, Grep | Ingests one idea source — an inline prompt, a markdown file, a community post, or an exported Jira ticket — and returns a structured source digest for `/idea`. | `/idea` |
| `jira-reader` | per routing | Read, Glob, Grep | Reads a pre-exported Jira markdown hierarchy from the vault and returns a structured handoff — linked items, PR URLs with host classification, capability themes. | `/create-ard`, `/document`, `/epics`, `/implement`, `/ready`, `/release-notes`, `/specify` |
| `vault-prior-art-finder` | per routing | Read, Glob, Grep | Searches the vault for tracked initiatives that cover, precede, parallel, or are superseded by new work, returning each match classified, status-resolved, and summarised. | `/idea`, `/create-prd` |
| `vuln-research` | per routing | Read, Glob, Grep, WebFetch | Read-only CVE research phase — NVD lookup, library detection in the repository, current-version discovery, and minimum-safe-version resolution. Has no side effects. | `/vuln` |
| `test-baseliner` | per routing | Bash, Read, Glob | Runs the full test suite and returns structured results in two modes — capture a baseline, or verify a later run's result against a previously captured one. | `/implement`, `/upgrade`, `/vuln` |

## Writers

Produce artifact content from a structured handoff. None of these run git.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `doc-writer` | per routing | Read, Glob, Grep, Write, Edit, Bash | Writes product documentation from a structured handoff — the `doc-planner` checklist, approved per-page write strategies, discrepancy decisions, snippets, screenshots, frontmatter, links. | `/document` |
| `epic-writer` | per routing | Read, Glob, Grep, Write, Edit | Writes one file per child Epic from a structured handoff, traceable to the `jira-reader` handoff and `code-scanner` evidence; write-only, never commits. | `/epics` |
| `release-notes-writer` | per routing | Read, Glob, Grep | Renders a release-notes draft — exactly one Summary, shaped by its resolved destination; emits no Jira ID, PR link, or internal-note wrapper. Does not write files. | `/release-notes` |
| `test-writer` | per routing | Read, Glob, Grep, Write, Edit | Writes tests for new or changed behaviour based on a diff; does not run them, and reports "not detected" immediately when no test framework is found. | `/implement` |

## Fixers

Apply changes the caller has already decided on, rather than deciding anything themselves. `doc-fixer` and `review-fixer` patch findings a reviewer or linter surfaced, and the caller re-runs the gate afterward; `upgrade-executor` applies an upgrade plan and runs the build, and `vuln-fixer` applies the version change `vuln-research` resolved.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `doc-fixer` | per routing | Read, Glob, Grep, Write, Edit | Applies targeted fixes for surviving BLOCKER/MAJOR findings from `doc-reviewer` or `epic-reviewer`, or for violations from a style checker; mirrors `review-fixer` for the docs domain. | `/document`, `/epics` |
| `review-fixer` | per routing | Read, Glob, Grep, Write, Edit | Applies targeted code fixes for surviving BLOCKER/MAJOR findings from a `code-review` report; returns a structured fix report for the caller to re-review against. | `/implement`, `/upgrade`, `/vuln` |
| `upgrade-executor` | per routing | Read, Glob, Grep, Bash, Edit, Task | Applies one component's approved upgrade plan, runs the build, verifies tests via `test-baseliner`, and auto-fixes test-code breakage caused by the new version's API changes. | `/upgrade` |
| `vuln-fixer` | per routing | Read, Glob, Grep, Bash, Edit, Task | Captures a baseline, applies the minimal version change `vuln-research` produced, rebuilds, verifies tests, commits to a new branch, and opens a PR. | `/vuln` |

## Maintenance

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `impl-maintenance` | per routing | Read, Glob, Grep | Reads what happened during a session and produces a structured Lessons Learned report — CLAUDE.md, reference-doc, hook, and workflow suggestions; suggest-only, writes nothing itself. | `/create-ard`, `/create-prd`, `/design`, `/document`, `/epics`, `/idea`, `/implement`, `/ready`, `/release-notes`, `/specify`, `/update-prd`, `/upgrade`, `/vuln` |

Every one of the 34 agents above is dispatched by at least one command — none has an empty **Used by** cell. Two of them, `docs-grounder` and `vault-prior-art-finder`, are dispatched indirectly: their calling commands invoke a named procedure (`dispatch-docs-grounder`, `dispatch-prior-art-finder`) defined in the agent's own governing reference file rather than writing `subagent_type: "dev-workflows:<name>"` inline, but that procedure resolves to exactly the `subagent_type` named above, so the derivation counts it as a real dispatch.

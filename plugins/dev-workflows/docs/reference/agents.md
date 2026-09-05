# Agents reference

`dev-workflows` bundles 24 reusable subagents under `agents/`, dispatched internally by the invoking command via `subagent_type: "dev-workflows:<name>"` — none of them is a user entry point. Ten carry a `model: opus` frontmatter pin (shown as **opus** below) and run on Opus every time, regardless of the dispatching command's own model tier for that run; one, `brd-reader`, carries a `model: sonnet` frontmatter pin (shown as **sonnet** below) and runs on Sonnet every time, regardless of the dispatching command's own model tier for that run, because its extraction work is mechanical; the remaining 13 carry no pin (shown as **per routing**) and are assigned a tier by the dispatching command per the task-complexity classification in the model-routing classification reference. Five further agents this plugin's commands dispatch — `code-scanner`, `doc-fixer`, `docs-grounder`, `frame-describer` and `impl-maintenance` — ship in the companion `workflows-core` plugin and are listed in its own agents reference, not here; the seven documentation agents that used to sit in the tables below — `diff-summarizer`, `doc-location-finder`, `doc-planner`, `doc-reviewer`, `doc-writer`, `docs-style-checker` and `release-notes-writer` — ship in the companion `docs-workflows` plugin now, alongside the three commands that dispatched them. Agents are grouped below by role — reviewers and planners, readers and scanners, writers, fixers, and maintenance — and each row's **Used by** column lists only the commands that actually dispatch that agent as a subagent; a command that merely names another command's agent in passing (for example, `/implement` noting that a design was already reviewed upstream by `design-reviewer`) is not counted as a dispatch.

## Reviewers and planners

Opus-gated quality gates, plus the lighter-weight planners that feed or precede them.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `ard-reviewer` | opus | Read, Glob, Grep, Skill | Reviews an ARD for grounding integrity, well-formed `AD#N` rules, non-contradiction with inherited PRD-level invariants, and altitude purity; returns PASS / PASS WITH RECOMMENDATIONS / BLOCK. | `/create-ard` |
| `brd-package-reviewer` | opus | Read, Glob, Grep, Skill | Attacks a BRD package before it reaches the customer instead of summarising it — unsupported decisions, a `[C]` that is really a `[V]`, assumptions as facts, overclaims; returns `[SR#n]`. | `/brd-package` |
| `code-review` | opus | Read, Glob, Grep, Skill | Post-implementation review for SIGNIFICANT / HIGH-RISK changes — correctness, security, architecture, edge cases, migration, dependencies, tests, rollback; gates the test run. | `/implement`, `/upgrade`, `/vuln` |
| `design-reviewer` | opus | Read, Glob, Grep | Reviews an engineering design against the design-format authority and its specification, treating any unresolved design open question as a BLOCKER. | `/design` |
| `epic-reviewer` | opus | Read, Glob, Grep | Reviews Epic drafts for goal clarity, testable acceptance criteria, scope boundaries, and non-duplication with existing Epics under the parent PRD. | `/epics` |
| `grounding-verifier` | opus | Read, Glob, Grep, Bash, Skill | Re-derives a `[CG#n]`/`[DG#n]` from its source — the pinned repo, or the frame set for a design-only one — without first reading `evidence`; returns agree / extend / contradict / unprovable. | `/brd-ground` |
| `readiness-reviewer` | opus | Read, Glob, Grep | Cross-artifact readiness verifier — checks the ARD/spec/design justify the phase derived from them and the next transition; the only reviewer that does joint cross-artifact analysis. | `/ready` |
| `risk-planner` | opus | Read, Glob, Grep, Bash, WebFetch, WebSearch, Skill | Risk-weighted planner for SIGNIFICANT / HIGH-RISK tasks; returns a structured plan with an explicit risks section. Never dispatched for SIMPLE / MODERATE work. | `/implement`, `/upgrade` |
| `spec-reviewer` | opus | Read, Glob, Grep | Reviews a specification for per-stage quality, cross-stage consistency, coverage, and identifier integrity. | `/specify` |
| `prd-reviewer` | opus | Read, Glob, Grep, Skill | Reviews a Product Requirements Document for goal crispness, testable stories/criteria, internal consistency, measurable metrics, and product-level purity (no implementation detail). | `/create-prd`, `/update-prd` |
| `interface-designer` | per routing | Read, Glob, Grep, Bash, Skill | Produces one interface proposal for one contested interface under one named design constraint, for `/design`'s optional three-take Phase 5 fan-out. | `/design` |
| `upgrade-planner` | per routing | Read, Glob, Grep, WebFetch, Skill | Detects a component, resolves its requested target version, and verifies compatibility with every other component in the repo; one instance per component, dispatched in parallel. | `/upgrade` |

## Readers and scanners

Read-only discovery and grounding — each returns a structured digest rather than editing anything. `test-baseliner` is the one that touches the working tree at all: it holds `Bash` because its job is to *run* the suite, so build and coverage output appears as a side effect.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `brd-reader` | sonnet | Read, Glob, Grep | Extracts a `[BR#n]` inventory from a customer-supplied BRD — `source_anchor` per row, unconfirmed `defect_candidates`; splits multi-obligation requirements. Never rewrites the source. | `/brd-intake` |
| `code-grounder` | per routing | Read, Glob, Grep, Bash, Skill | Grounds specific BRD claims against one repository at a pinned commit — one `[CG#n]` finding per claim, verifying `HEAD` matches the pin before grounding anything. | `/brd-ground` |
| `customer-review-reader` | per routing | Read, Glob, Grep | Reads a returned customer review in two modes — parses a schema-shaped file, or drafts that schema from prose; every free-text inference returns an unconfirmed candidate. | `/brd-reconcile` |
| `design-grounder` | per routing | Read, Glob, Grep, Skill | Reconciles a BRD against an exported design frame set — one `[DG#n]` per divergence in four classes; refuses without an index file; the code-capture class cites a `[CG#n]` instead of asserting it. | `/brd-ground` |
| `idea-reader` | per routing | Read, Glob, Grep, Skill | Ingests one idea source into a source digest for `/idea`: links two levels deep in either syntax, linked images read and described as context, every other linked file enumerated but never opened. | `/idea` |
| `vuln-research` | per routing | Read, Glob, Grep, WebFetch, Skill | Read-only CVE research phase — NVD lookup, library detection in the repository, current-version discovery, and minimum-safe-version resolution. Has no side effects. | `/vuln` |
| `test-baseliner` | per routing | Bash, Read, Glob | Runs the full test suite and returns structured results in two modes — capture a baseline, or verify a later run's result against a previously captured one. | `/implement`, `/upgrade`, `/vuln` |

## Writers

Produce artifact content from a structured handoff. None of these run git.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `epic-writer` | per routing | Read, Glob, Grep, Write, Edit, Skill | Writes one file per child Epic from a structured handoff, traceable to the PRD it partitions and `code-scanner` evidence; write-only, never commits. | `/epics` |
| `test-writer` | per routing | Read, Glob, Grep, Write, Edit | Writes tests for new or changed behaviour based on a diff; does not run them, and reports "not detected" immediately when no test framework is found. | `/implement` |

## Fixers

Apply changes the caller has already decided on, rather than deciding anything themselves. `review-fixer` patches findings a reviewer surfaced, and the caller re-runs the gate afterward (`doc-fixer` does the same for the docs domain, from `workflows-core`); `upgrade-executor` applies an upgrade plan and runs the build, and `vuln-fixer` applies the version change `vuln-research` resolved. Neither commits: the orchestrator does that, because the consent choice behind the push and the pull request is one a subagent cannot ask.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `review-fixer` | per routing | Read, Glob, Grep, Write, Edit, Skill | Applies targeted code fixes for surviving BLOCKER/MAJOR findings from a `code-review` report; returns a structured fix report for the caller to re-review against. | `/implement`, `/upgrade`, `/vuln` |
| `upgrade-executor` | per routing | Read, Glob, Grep, Bash, Edit, Task, Skill | Applies one component's approved upgrade plan, runs the build, verifies tests via `test-baseliner`, and auto-fixes test-code breakage caused by the new version's API changes. | `/upgrade` |
| `vuln-fixer` | per routing | Read, Glob, Grep, Bash, Edit, Task, Skill | Captures a baseline, creates the fix branch **before** the first edit, applies the version change `vuln-research` produced, rebuilds, and verifies tests — leaving it uncommitted for Step 3.9. | `/vuln` |

Every one of the 24 agents above is dispatched by at least one command. There is no maintenance section here any more: the one agent that filled it, `impl-maintenance`, ships in `workflows-core` — as does `docs-grounder`, the one agent no command dispatches by writing a `subagent_type:` inline, since its callers invoke a named procedure defined in its own governing reference file instead.

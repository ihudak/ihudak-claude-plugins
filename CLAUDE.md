# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

A private Claude Code plugin marketplace hosted at `github.com/ihudak/ihudak-claude-plugins`.
Registered in `~/.claude/plugins/known_marketplaces.json` as `ihudak-plugins`.

## Structure

```
.claude-plugin/marketplace.json   ← plugin catalog (do not reformat; Claude Code parses it)
plugins/
  <plugin-name>/
    .claude-plugin/plugin.json    ← required: name, description, author
    README.md
    LICENSE
    commands/                     ← slash commands (.md files)
    agents/                       ← subagent system prompts (.md files, YAML frontmatter required)
    hooks/
      hooks.json                  ← hook declarations; use ${CLAUDE_PLUGIN_ROOT} for paths
      *.sh                        ← hook scripts
    skills/                       ← skills (.md files), if any
    references/                   ← vendored reference docs the commands consult
```

## Active plugin: dev-workflows

`plugins/dev-workflows/` contains three commands (`/impl`, `/vuln`, `/upgrade`),
five agents, three hooks, and reference docs.

That count reflects the original bootstrap layout. The live `dev-workflows`
workflow now relies on a larger set of helper agents and workflow roles; see
the taxonomy and workflow map below.

**Internal path convention:** all paths inside command/agent/hook files use
`~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/` as the root prefix.
This is where Claude Code installs the plugin's content.

**When editing `dev-workflows`:** update the files in `plugins/dev-workflows/` directly.
Do NOT edit `~/.claude/claude-config/` — that repo is retired and will be deleted.

## Adding a new plugin

1. Create `plugins/<name>/` with `.claude-plugin/plugin.json`.
2. Add content directories (`commands/`, `agents/`, `hooks/`, etc.).
3. For hooks: create `hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}` for all paths.
4. Register in `.claude-plugin/marketplace.json` with `"source": "./plugins/<name>"`.
5. Commit and push to `main`. Claude Code picks up changes on next sync/reinstall.

## Conventions

- Agent `.md` files must start with YAML frontmatter (`---`) containing at minimum `name` and `description`.
- Hook scripts must exit 0 — they must never block Claude.
- `hooks.json` `matcher` field (for PostToolUse) goes at the entry level, not inside the hook object.
- All paths in plugin content use `~/.claude/plugins/data/<plugin>@ihudak-claude-plugins/` — never hardcode `~/.claude/` subdirectories directly.
- MIT license applies to all plugins unless a plugin directory has its own LICENSE file.

## Command, agent, and skill taxonomy

### Commands

User-facing slash commands live under `commands/`. They own the end-to-end
workflow, gather context, decide whether to branch, test, or review, and may
dispatch helper agents via the `task` tool.

### Agents

Helper agents live under `agents/`. They are Claude Code sub-agent system
prompts, not user entry points. Each agent does one bounded job — planning,
research, review, fixing, test writing, Jira reading, or maintenance — and
returns its result to the invoking command.

### Skills

Optional reusable guidance lives under `skills/`. A skill is neither a command
nor an agent: it packages durable instructions or domain knowledge that multiple
commands or agents may consult. If a plugin has no `skills/`, keep shared
runtime docs under `references/`.

### Working rule

Commands orchestrate. Agents execute bounded tasks. Skills provide reusable
knowledge. Keep those roles separate so workflows stay predictable.

## Model routing reference

`plugins/dev-workflows/references/model-routing/classification.md` is the
**single source of truth** for:

- Task complexity classification (`SIMPLE` / `MODERATE` / `SIGNIFICANT` /
  `HIGH-RISK`)
- The model fallback chain (Opus 4.7 → 4.6 → 4.5 → Sonnet 4.6 → Sonnet 4.5)
- The mandatory Opus code-review checklist
- The `model_routing` YAML handoff block shared between commands and agents
- The `phase: verify-resume` protocol for review-gated verification

All top-level commands that dispatch helper agents (`/impl`, `/impl:docs`,
`/impl:jira:*`, `/vuln`, `/upgrade`) must load and follow this file at the
start of every invocation. Standalone review commands (`/api-guideline-reviewer`
and `/guideline-reviewer`) are exempt. Agents receive the `model_routing` block
in their prompt; they do not re-read the file.

## `dev-workflows` workflow relationships

```
/impl:code           → /impl → [risk-planner@Opus plan critique] → [code-review@Opus] → review-fixer → test-writer → tests → impl-maintenance
/impl                → dispatcher / help page; does not run a workflow
/impl:docs           → /impl:docs → [doc-reviewer] → [doc-fixer] → impl-maintenance
/impl:jira:docs      → /impl:jira:docs → jira-reader → [diff-summarizer×N (parallel)] → [doc-location-finder] → [doc-planner] → writing → [docs-style-checker → dt-style-checker fallback] → [doc-fixer] → [doc-reviewer] → [doc-fixer] → impl-maintenance
/impl:jira:epics     → /impl:jira:epics → jira-reader → [code-scanner×N (parallel, optional)] → writing → [dt-style-checker] → [doc-fixer] → [epic-reviewer@Opus] → [doc-fixer] → impl-maintenance
/vuln                → vuln-research → vuln-fixer → [code-review@Opus] → review-fixer → tests → impl-maintenance
/upgrade             → upgrade-planner → upgrade-executor → [code-review@Opus] → review-fixer → tests → impl-maintenance
                      └── test-baseliner      (used by upgrade-executor, vuln-fixer, and /impl:code)
                      └── test-writer        (used by /impl:code only)
                      └── risk-planner       (used by /impl:code plan critique)
                      └── code-review        (used by /impl:code, /vuln, /upgrade)
                      └── doc-reviewer       (used by /impl:docs and /impl:jira:docs)
                      └── doc-fixer          (used by /impl:docs and /impl:jira:*)
                      └── doc-location-finder (used by /impl:jira:docs)
                      └── doc-planner        (used by /impl:jira:docs)
                      └── docs-style-checker (used by /impl:jira:docs)
                      └── epic-reviewer      (used by /impl:jira:epics)
/api-guideline-reviewer → standalone command; reviews OpenAPI specs against Dynatrace REST API + IAM guidance
/guideline-reviewer     → standalone command; reviews code/UI against Dynatrace Experience Standards
```

## Key invariants

Key invariants enforced by all three code-oriented commands:

- Branch created before any file is touched (`feat/<slug>` or equivalent)
- Opus review gate runs **before** tests for `SIGNIFICANT` / `HIGH-RISK` tasks
- `review-fixer` handles BLOCKER findings; only one `review-fixer` cycle per review
- `impl-maintenance` runs post-batch to update KB, `CLAUDE.md`, and project docs

Key invariants for `/impl:code` specifically:

- Test baseline captured **before** any source edits, using `test-baseliner`
- `test-writer` writes tests for **new or changed behaviour** — mandatory for code changes
- If no test framework is detected, surface that explicitly — test-writing is never silently skipped
- Full test suite is verified against the captured baseline before the workflow is considered complete

Key invariants for `/impl:docs`:

- **No branch creation by default** — it works on the current branch unless the user requests one
- **No `test-baseliner`, no `test-writer`, no `code-review`** — docs-only phases only
- `doc-reviewer` performs comprehensive review: links, headings, wikilinks, style, completeness
- BLOCKER findings trigger a fix cycle via `doc-fixer` (max one fix + one re-review); CONCERNs are recorded and may be fixed inline
- Mixed code + docs changes must use `/impl:code` instead

Key invariants for `/impl:jira`:

- Subcommand dispatch is explicit: `/impl:jira:docs`, `/impl:jira:epics`; bare `/impl:jira` must dispatch intentionally
- **Zero external API calls** — PR URLs from Jira exports are identifiers only; no `gh`, no Bitbucket REST API, no HTTPS fetch to Bitbucket; all resolution is local `git` against clones under `/repos/`
- `jira-reader` is strictly read-only — it never modifies vault files
- Parallel agent invocation: all diff summarizers (docs flow) or code scanners (epics flow) are launched in a **single response**
- Branch setup happens **before** writing output files — never after
- Branch policy: walk up cwd for `.obsidian/` → `obsidian` (never branch); else `git rev-parse` → `git_repo` (branch opt-in) or `plain_dir` (never branch). User override is allowed at plan approval
- `doc-location-finder` (docs flow) identifies write targets before writing begins
- `doc-planner` (docs flow) synthesizes Jira + diffs into a documentation checklist
- `docs-style-checker` + `doc-fixer` lint prose after writing, before the review gate; if no repo linter exists, fall back to `dt-style-checker` when installed
- For epics, `dt-style-checker` is the primary style checker; skip gracefully if `dt-style-guide` is not installed
- Review gate is `doc-reviewer` (docs flow) or `epic-reviewer@Opus` (epics flow); `doc-fixer` resolves BLOCKERs; cap at one fix cycle plus one re-review
- Sub-agents return `DIRTY_TREE` / `REFRESH_BLOCKED` when they cannot refresh repos — never fail silently
- Every written claim must cite the originating Jira key (`[[KEY]]`) plus PR URL (docs flow) or file path (epics flow)
- Writes never touch `_archive/` and never write outside cwd unless the user provides an explicit absolute path

## Test-writing requirement for code changes

Any `/impl:code` (or `/impl`) invocation that touches source code **must**
produce at least one passing test for each new or changed behaviour before the
workflow is considered complete.

- Prefer unit tests; use integration or end-to-end tests only if that is the project's established pattern
- Tests must be meaningful (assert specific behaviour), deterministic, and follow existing project conventions
- If no test framework is detected, the workflow surfaces this explicitly — it never silently skips test-writing
- Docs-only changes (`/impl:docs`) are exempt from this requirement

## Updating installed plugins after editing

After editing files in this repo and pushing, reinstall the affected plugin on
each machine so Claude Code picks up the new command, agent, hook, and
reference content:

```bash
claude plugin reinstall dev-workflows@ihudak-plugins
```

Use the same pattern for any other plugin in this marketplace.

## Behavioral guardrails (Karpathy) — marketplace-specific notes

These notes complement the user-scope Claude guidance. They add only the
marketplace-specific behaviors that are easy to forget during workflow edits.

- **Goal-Driven Execution** maps directly onto the existing `test-baseliner` → implementation → `test-writer` → re-run flow enforced by `dev-workflows`. Frame each command invocation as a verifiable goal up front so the test gates have a concrete target to check.
- **Surgical Changes** applies in both directions when you edit command docs, agent prompts, hook declarations, or `references/model-routing/classification.md`: if you remove a `model_routing` field, phase, or workflow edge, remove every cross-reference to it in the same change. Stale references between commands and agents silently break the workflow.

## Git

- `origin` → `git@github-ig.com:ihudak/ihudak-claude-plugins.git`
- Default branch: `main`

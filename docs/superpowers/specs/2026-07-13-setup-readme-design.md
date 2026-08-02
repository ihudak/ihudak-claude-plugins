---
tags:
  - tasks-exclude
---

# Setup README — design

**Date:** 2026-07-13
**Task:** AI-First.md line 92, priority `[1]` — the repo README must explain how to set up: install the marketplace, then the plugins, prerequisites (superpowers, jira-workitem-import, env vars, `$VAULT_PATH`/`$SPECS_PATH`/`$REPOS_PATH` dir structures), and which command to run first (`/statusline`).
**Repo:** `/workspace/ihudak-claude-plugins` (documentation only — NOT a plugin behavior change).

## Context (from exploration)

The repo-root `README.md` (47 lines) **already** has an `## Installation` section with the three install commands: marketplace add → `claude plugin install` the three plugins → `claude plugin marketplace update`. What it lacks is the rest of line 92 — **prerequisites, environment variables + directory structures, and the first command to run**. The richest existing installer model is `plugins/obsidian-llm-wiki/README.md` (Vault Prerequisites + Installation A/B/C); `plugins/dev-workflows/README.md` already has a strong `## Environment prerequisites` + AI-Containers block (`README.md:244-260`) and `## Dependencies & companions` to draw facts from. `dt-style-guide/README.md` has a minimal `## Installation`.

Accurate facts to encode (verified):
- Marketplace `name: ihudak-plugins`; three plugins `dev-workflows@2.26.0`, `dt-style-guide@0.2.2`, `obsidian-llm-wiki@0.3.1`.
- Env vars: `VAULT_PATH` (`jira-products/<KEY>/`, `Projects/<area>/<slug>/`), `SPECS_PATH` (`specifications/<KEY>-<slug>/…/*.md`; required by `/implement`, additive for `/document`), `REPOS_PATH` (defaults to `/workspace`; single dir or colon-separated list; repos matched by `git remote get-url origin` slug, not dir name).
- Prereqs: **superpowers** (recommended companion — `/prompt-brainstorm` + brainstorm/plan/SDD flow; no hard dependency), **`jira-workitem-import`** (external tool, populates `$VAULT_PATH/jira-products/`), **`gh auth login`** (GitHub PR reading; graceful fallback), **vale** (optional prose linter), **AI-Containers** (`ihudak/ai-containers`, recommended environment).
- `/statusline` installs the multi-line statusline into `~/.claude/settings.json` and enables the Option-B session-cost snapshot; idempotent; backs up anything it overwrites.
- Stale spot: repo-root `CLAUDE.md` (~lines 29-31) still describes an old command shape (`/impl`, `/vuln`, `/upgrade`, `/impl:docs:profile`) that doesn't match the current 20-command surface.

## Decisions (locked)

- **Location:** expand the repo-root `README.md` (single entry point). Not a separate SETUP.md.
- **Scope (widest):** the setup guide + a navigational pointer line in each of the 3 plugin READMEs + refresh the stale `CLAUDE.md` command list.
- **Versioning:** **no plugin version bumps, no CHANGELOG entries** — repo-level docs + navigational pointers are not functional changes. Sibling `plugin.json`/functional content untouched (only a one-line README pointer each).

## Change surface

### 1. Repo-root `README.md` (expand)

Target section order (extends the existing file; existing `## Plugins`, `## Adding new plugins`, `## License` kept):
- **`## Prerequisites`** (NEW) — Claude Code; superpowers (recommended); `jira-workitem-import` (required for Jira-driven commands); `gh auth login` (GitHub PRs, graceful fallback); vale (optional); **AI-Containers** as the recommended environment (mounts repos + vault under `/workspace`, installs `gh`, mounts host `gh` auth) with the outside-container fallback (set `$REPOS_PATH` yourself, manage `gh`).
- **`## Installation`** (expand existing): (1) add marketplace `claude plugin marketplace add ihudak/ihudak-claude-plugins`; (2) install the three plugins `claude plugin install <name>@ihudak-plugins`; (3) **Configure environment variables** (NEW) — `export VAULT_PATH=… SPECS_PATH=… REPOS_PATH=…`; (4) **Run `/statusline` first** (NEW) — installs the statusline + enables Option-B cost reporting; (5) update after releases `claude plugin marketplace update ihudak-plugins`.
- **`## Directory structure`** (NEW) — the layout each env-var root expects: `$VAULT_PATH/{jira-products/<KEY>/, Projects/<area>/<slug>/}`; `$SPECS_PATH/specifications/<KEY>-<slug>/…`; `$REPOS_PATH` = `/workspace/<repo>` (matched by git-remote slug).

Draw wording from `dev-workflows/README.md:244-260` (Environment prerequisites + AI-Containers) so facts stay consistent; do not contradict the plugin README.

### 2. Plugin-README pointers (3 one-line edits)

Add to each plugin README's install/prereq section a line: part of the `ihudak-plugins` marketplace — see the [repo-root setup guide](../../README.md) for marketplace install + prerequisites. Files: `plugins/dev-workflows/README.md`, `plugins/dt-style-guide/README.md`, `plugins/obsidian-llm-wiki/README.md`. `obsidian-llm-wiki` keeps its own vault-specific prerequisites; the pointer only covers the common marketplace-install path.

### 3. Refresh `CLAUDE.md` command list

Replace the stale `/impl` / `/vuln` / `/upgrade` / `/impl:docs:profile` description with the current 20-command surface: `/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/api-guideline-reviewer`, `/guideline-reviewer`, `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`, `/statusline`, `/ready`. Only the stale command reference is touched; the rest of `CLAUDE.md` is unchanged. Exact old text pinned in the plan.

## Non-goals

- No new command/agent; no plugin behavior change.
- No version bumps, no CHANGELOG entries (docs-only).
- Not rewriting the plugin READMEs beyond the one pointer line each; not rewriting `obsidian-llm-wiki`'s vault-specific setup.
- Not a SETUP.md / docs/ file (chose to expand the root README).
- Not fixing any other CLAUDE.md content beyond the stale command list.

## Verification (structural — no test framework)

- Repo-root `README.md` contains new `## Prerequisites`, a "Configure environment variables" install step, a "Run `/statusline` first" install step, and a `## Directory structure` section; the three original install commands are still present and correct.
- Each of the 3 plugin READMEs contains the setup-guide pointer line; the `../../README.md` relative link resolves (target file exists).
- `CLAUDE.md` no longer contains `/impl:docs:profile`; it lists the 20 current commands; nothing else in `CLAUDE.md` changed.
- `plugin.json` (all three) and `marketplace.json` versions **unchanged** (`2.26.0` / `0.2.2` / `0.3.1`); no CHANGELOG touched.
- No collateral: commands/, agents/, references/, scripts/ — 0-line diff.
- Markdown links introduced resolve to existing files.

## Risks

- **Very low.** Documentation only. Main risk is factual drift (an env-var/dir-structure detail contradicting the plugin README) — mitigated by sourcing every fact from the exploration / the existing `dev-workflows/README.md`, and by the verification cross-checks.

# Getting started

This page takes you from zero to your first successful run — install the plugin, set the environment variables it reads, install the status line, and run `/idea` end to end. Once you have done this once, [Workflow overview](workflow.md) shows the whole pipeline and [Roles and phases](roles-and-phases.md) says what your role owns at each step.

## Install

### 1. Add this marketplace to Claude Code (once)

```bash
claude plugin marketplace add ihudak/ihudak-claude-plugins
```

### 2. Install plugins

```bash
claude plugin install dev-workflows@ihudak-plugins
claude plugin install dt-style-guide@ihudak-plugins
claude plugin install obsidian-llm-wiki@ihudak-plugins
claude plugin install acli@ihudak-plugins
```

`dev-workflows` is the pipeline this documentation covers. `dt-style-guide` is the primary style checker for `/epics`, and a fallback prose linter for `/document` when the target docs repo has none configured. `obsidian-llm-wiki` compiles your vault into a persistent, cross-referenced wiki with task management. `acli` is a reference skill for the Atlassian CLI, covering Jira and Confluence operations from the command line. None of the four imports Jira tickets into your vault — that is a separate, external tool, [`jira-workitem-import`](https://github.com/ivan-gudak/jira-workitem-import), which populates `$VAULT_PATH/jira-products/<KEY>/` in the structure every Jira-driven command expects; install it too before you run `/specify`, `/document`, or any other Jira-driven command (the inline-prompt `/idea` walked below needs none of this).

## Update

```bash
claude plugin marketplace update ihudak-plugins
```

Run this whenever you want the latest command, agent, hook, and reference content — Claude Code does not pick up marketplace changes on its own.

## What you set on your machine

`dev-workflows` reads six environment variables. Two are required for the pipeline to have anywhere to write (`VAULT_PATH`, `SPECS_PATH`); the rest are read where relevant and degrade gracefully — a missing optional one degrades rather than fails — though only `$DOCS_PATH` and `$DEV_WORKFLOWS_COST_PRICES` degrade *silently*; an unset `$GIT_USER_INITIALS` walks its fallback ladder and, if that comes up empty, the command asks you before creating a branch. Export the ones you use in your shell profile. For defaults, resolution order, and the exact directory layout each one expects, see [Environment](reference/environment.md); this section explains what each variable *is*.

### `VAULT_PATH`

Your **personal** knowledge store — where your own working files live, not the team's. Obsidian is the common case, and the name mirrors that, but nothing about the plugin requires Obsidian: every file it reads or writes here is plain markdown, so any markdown-backed store — a plain directory, a different notes app, a git repo of `.md` files — works exactly the same way. It holds the `jira-products/<KEY>/` tree an external import tool produces from Jira, your `Projects/<area>/<slug>/` idea and working files, Epic drafts, and release-notes drafts. Nothing under `VAULT_PATH` is expected to be team-visible.

### `SPECS_PATH`

The **shared, team-visible repository for the AI-authored documents** — the Value Increment, the ARD, `specification.md`, and `design.md`, each under `specifications/<KEY>-<slug>/`. This is the reason a second store exists at all: it is the medium through which one role hands work to the next. A producing command lands its artifact on the specs repo's default branch, and the next command in the chain refuses to start expensive work until it finds that artifact there — not merely written to disk, and not merely committed to a branch of its own. See [Roles and phases](roles-and-phases.md) for what each seam hands over and what happens when an artifact is missing or stuck on an unmerged branch.

### `REPOS_PATH`

Where your code clones live — one directory, or a colon-separated list of them. It has a sensible built-in default, so most readers never need to set it at all; see [Environment](reference/environment.md) for the exact value and resolution order. Repos are matched by their `git remote get-url origin` slug, **never by directory name** — a repo cloned under any path, or renamed on disk, is still found correctly as long as its `origin` remote is intact. This is the detail that surprises people, so it is worth saying plainly here.

### `DOCS_PATH`

A **read-only** clone of your shipped product documentation. It matters most to `/document`, which prefers it as a docs-repo discovery hint, and it also grounds seven other authoring commands against what is already published, so a new draft does not contradict or duplicate an existing page. The plugin never writes to `DOCS_PATH`; every miss — unset, missing, or no markdown found — is a silent, non-blocking skip.

### `GIT_USER_INITIALS`

Your branch identifier. Branch naming is **repo-rule-first**: every branch-creating command reads the target repo's own documented convention and follows it as written. Where that convention has a name-or-initials segment, `GIT_USER_INITIALS` fills it; where it does not, the convention is followed without it, and this variable is simply unused for that repo.

### `DEV_WORKFLOWS_COST_PRICES`

An optional path to your own price table, overriding the bundled `references/cost-prices.yaml` that session-cost reporting prices tokens against. It is the variable of the six you are least likely ever to set — the bundled defaults are used until you do.

## Install the status line

Run `/dev-workflows:statusline` once, right after installing. It installs the plugin's multi-line status line (session identity, git, context, cost, tokens, rate limits) into `~/.claude/settings.json` and enables the cost snapshot that session-cost reporting reads. It is idempotent and backs up anything it would overwrite.

```
/dev-workflows:statusline
```

Claude Code ships its own built-in `/statusline` command, so typing the bare form reaches that instead of this plugin's — always use the qualified `/dev-workflows:statusline`.

## Your first run

`/idea` is the pipeline's entry point, and it needs no Jira key — which makes it the honest place to try the plugin for the first time. Point it at whatever you already have in mind: an inline prompt, a markdown file, a community post, or an existing VI you want to extend.

```
/idea a lightweight way for on-call engineers to silence a noisy alert for one hour without editing the alerting rule
```

Here is what to expect:

1. **A bounded grill.** `/idea` asks you up to ten questions, one at a time, to sharpen the idea before writing anything — scope, who it is for, what "done" looks like. Answer as best you can; a question you cannot answer yet becomes a logged `[NEEDS CLARIFICATION]` marker rather than a blocker.
2. **A written brief.** It writes `idea.md` — a lean one-page brief — into `VAULT_PATH`. If `DOCS_PATH` is set and readable, the idea is also checked against what is already documented, and if your vault has prior related work, that surfaces too.
3. **A handoff, once a Jira key exists.** The moment you create the corresponding Jira ticket, re-running `/idea` relocates `idea.md` into `$SPECS_PATH/specifications/<KEY>-<slug>/` and lands it on the specs repo's default branch, where the next command, `/create-vi <KEY>`, finds it and takes over — `/create-vi` never does the relocating itself.

From here, [Workflow overview](workflow.md) shows where every other command sits relative to `/idea`, and [Roles and phases](roles-and-phases.md) says what happens at each handoff along the way.

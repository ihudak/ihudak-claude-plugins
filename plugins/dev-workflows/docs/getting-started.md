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
claude plugin install prose-style@ihudak-plugins
```

`dev-workflows` is the pipeline this documentation covers. `prose-style` is the one other plugin **in this marketplace** it genuinely reaches for: it is the primary style checker for `/epics` and for the Product Requirements Document commands, and a fallback prose linter for `/document` when the target docs repo has none configured. Most commands that use it degrade gracefully when it is absent — `/document` is the exception: there, an absent `prose-style` with no other prose linter configured is a real coverage hole, not a no-op, and `gate-ledger.md` §5 forces an explicit choice — fix by hand, proceed without the check, or cancel the run — before the run continues. It is still *recommended*, not required.

**What you also need, and it is not a plugin.** Nothing — the pipeline reads and writes one markdown tree and calls no external service. If you keep your work in a tracker as well, syncing the two is yours to arrange; no command here learns whether one exists.

**One more that is not in this marketplace.** [`superpowers`](https://github.com/obra/superpowers) is a separate Claude Code plugin, recommended rather than required: `/prompt-brainstorm` cedes its Phase 3 to `superpowers:brainstorming`, and the brainstorm → plan → subagent-driven-development flow this plugin's own development uses comes from it. Without it that one hand-off has nowhere to go; everything else degrades gracefully. Note that *grilling* is **not** an external dependency — the relentless-interrogation technique the authoring commands run is bundled here, in `references/grilling-technique.md`.

**What you do not need for this plugin.** The marketplace also ships `obsidian-llm-wiki` (compiling a vault into a cross-referenced wiki) and `acli` (an Atlassian CLI reference skill) <!-- vendor-token-ok: names the subject of a sibling plugin this one does not use -->. Neither is used by `dev-workflows` — `acli` is referenced nowhere in it, and `references/followup-emission.md` states outright that it has no dependency on it — runtime or editorial. It used to mirror that plugin's task conventions, because follow-ups landed in a vault; they land in the specs tree now, as plain markdown. Install them if you want them for their own sake; see the [marketplace README](../../../README.md).

## Update

```bash
claude plugin marketplace update ihudak-plugins
```

Run this whenever you want the latest command, agent, hook, and reference content — Claude Code does not pick up marketplace changes on its own.

## What you set on your machine

`dev-workflows` reads seven environment variables. One is required for the pipeline to have anywhere to write (`SPECS_PATH`); the rest are optional and each degrades to a documented default or a silent skip.

### `SPECS_PATH`

The **shared, team-visible repository for the AI-authored documents** — the Product Requirements Document, the ARD, `specification.md`, and `design.md`, each under a kind-prefixed folder — `specifications/PRD-<KEY>-<slug>/`, with `EPIC-` folders below it. This is the reason a second store exists at all: it is the medium through which one role hands work to the next. A producing command lands its artifact on the specs repo's default branch, and the next command in the chain refuses to start expensive work until it finds that artifact there — not merely written to disk, and not merely committed to a branch of its own. See [Roles and phases](roles-and-phases.md) for what each seam hands over and what happens when an artifact is missing or stuck on an unmerged branch.

### `REPOS_PATH`

Where your code clones live — one directory, or a colon-separated list of them. It has a sensible built-in default, so most readers never need to set it at all; see [Environment](reference/environment.md) for the exact value and resolution order. Matching depends on how a command finds the repo. Where a command resolves a repo from a pull-request URL — `/document`, `/epics`, `/release-notes` — it is matched by its `git remote get-url origin` slug, **never by directory name**, so a clone renamed on disk is still found as long as its `origin` remote is intact. The commands that instead discover repos to offer you — `/idea`, `/create-ard`, `/design` — list top-level directories under `$REPOS_PATH` and match on their **basenames**, so a repo renamed on disk is *not* found by those three. This is the detail that surprises people, so it is worth saying plainly here.

### `DOCS_PATH`

A **read-only** clone of your shipped product documentation. It matters most to `/document`, which prefers it as a docs-repo discovery hint, and it also grounds nine other commands against what is already published, so a new draft does not contradict or duplicate an existing page. The plugin never writes to `DOCS_PATH`; every miss — unset, missing, or no markdown found — is a silent, non-blocking skip.

### `GIT_USER_INITIALS`

Your branch identifier. Branch naming is **repo-rule-first**: every branch-creating command reads the target repo's own documented convention and follows it as written. Where that convention has a name-or-initials segment, `GIT_USER_INITIALS` fills it; where it does not, the convention is followed without it, and this variable is simply unused for that repo.

### `UI_GUIDELINES_PATH`

Your organization's own UI rules, as a directory of `.md` files. The bundled guidelines are a vendor-neutral baseline distilled from public standards (Apple HIG, Material Design 3, Fluent 2, WCAG 2.2, the ARIA APG); rules specific to your design system have no public equivalent and should not ship in a public plugin, so `/guideline-reviewer` layers this directory over the baseline instead. Unset is the normal case and degrades silently to the baseline alone.

### `API_GUIDELINES_PATH`

The same idea for `/api-guideline-reviewer` — your own scope grammar, header spellings, or error-envelope contract, layered over the bundled public-source baseline. This governs the *prose* rules; the executable half is separate, where your repo's own `.spectral.yaml` takes precedence over the bundled Spectral ruleset. Unset degrades silently.

### `DEV_WORKFLOWS_COST_PRICES`

An optional path to your own price table, overriding the bundled `references/cost-prices.yaml` that session-cost reporting prices tokens against. It is the variable of the seven you are least likely ever to set — the bundled defaults are used until you do.

## Install the status line

**Worth doing before your first real run.** Two things come out of it.

The visible half is a permanent multi-line status line at the bottom of your terminal — session identity, git state, context usage, running cost, tokens, and rate limits — so you can see a long command spending your budget while it spends it, rather than finding out in the final report.

The half you don't see is the **cost cross-check**. Session-cost reporting works without the status line: it reads the session transcript and prices it against the bundled table. What the status line adds is a second, independent figure — Claude Code's own reported cost, captured per render — which the cost phase differences into a per-invocation delta. Where the two disagree, the gap is the signal that the bundled price table has drifted and needs refreshing. Install it and you get both numbers; skip it and you still get a cost report, just without anything to calibrate it against. (Even with it installed, the first cost phase of a session has no baseline yet and omits the second figure; it appears from the second command onward.)

See [Session cost](reference/session-cost.md) for what the report contains and where it lands. The command is idempotent, backs up anything it would overwrite, and changes no workflow-command behaviour.

```
/dev-workflows:statusline
```

Claude Code ships its own built-in `/statusline` command, so typing the bare form reaches that instead of this plugin's — always use the qualified `/dev-workflows:statusline`.

## Your first run

`/idea` is the pipeline's entry point. It takes **one argument you choose yourself** — the key that names the folder this idea will live in — because there is nowhere keyless to write: the brief lands in its final folder on the first write and is never moved afterwards. Point it at whatever you already have in mind: an inline prompt, or a markdown file with `@path`.

```
/idea ACME-77 a lightweight way for on-call engineers to silence a noisy alert for one hour without editing the alerting rule
```

`ACME-77` is yours to invent — nothing looks it up, and no tracker is read. It only has to match `^[A-Z][A-Z0-9_]*(-\d+)+$`.

Here is what to expect:

1. **A bounded grill.** `/idea` asks you up to ten questions, one at a time, to sharpen the idea before writing anything — scope, who it is for, what "done" looks like. Answer as best you can; a question you cannot answer yet becomes a logged `[NEEDS CLARIFICATION]` marker rather than a blocker. (`--deep` drops the cap and grills to convergence instead.)
2. **A written brief.** It writes `idea.md` — a lean one-page brief — into `$SPECS_PATH/specifications/PRD-ACME-77-<slug>/`, creating that folder if it does not exist. If `DOCS_PATH` is set and readable, the idea is also checked against what is already documented.
3. **A handoff.** At the end it offers to commit the brief, push it, and open a pull request against the specs repo's default branch. Once that lands, `/create-prd ACME-77` finds `idea.md` in the same folder and takes over.

From here, [Workflow overview](workflow.md) shows where every other command sits relative to `/idea`, and [Roles and phases](roles-and-phases.md) says what happens at each handoff along the way.

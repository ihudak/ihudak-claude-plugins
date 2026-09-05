# Getting started

This page takes you from zero to your first successful run — install the plugin, set the environment variables it reads, and run `/document` end to end. Once you have done this once, [Workflow overview](workflow.md) shows how the three commands fit together.

## Install

### 1. Add this marketplace to Claude Code (once)

```bash
claude plugin marketplace add ihudak/ihudak-claude-plugins
```

### 2. Install the plugin

```bash
claude plugin install docs-workflows@ihudak-plugins
```

Two other plugins arrive with it, because they are **declared dependencies** rather than suggestions. `workflows-core` carries the shared reference corpus every command here loads at runtime — an unsatisfied dependency disables the plugin instead of letting it half-run, which is the intended behaviour: there is no degraded mode to fall back to. `prose-style` is the complementary semantic prose pass the style check runs alongside a repo's own linter, and the fallback linter when a repository configures none.

**What you do not need.** The companion `dev-workflows` pipeline plugin is not a dependency in either direction. `/document` and `/release-notes` read a folder in a specs tree; whether the plugin that authored that folder is installed on *your* machine makes no difference. Install it if you also author PRDs, specifications and designs.

**What you also need, and it is not a plugin.** A prose linter helps but is not required — `vale`, a repo lint script, `markdownlint` or `remark` are all detected if present, and `prose-style` covers the run when none of them is. Because `prose-style` arrives as a declared dependency, a repository with no linter of its own is still style-checked rather than waved through; what a missing `vale` costs you is the lexical pass CI will run on your PR, which is why the Phase 0 toolchain preflight names it.

## Update

```bash
claude plugin marketplace update ihudak-plugins
```

Run this whenever you want the latest command, agent, and reference content — Claude Code does not pick up marketplace changes on its own.

## What you set on your machine

This plugin reads four environment variables. None is required for a direct-mode `/document` edit or for `/docs-profile`; a keyed run wants the first, and the rest degrade to a documented default or a silent skip. [Environment](reference/environment.md) has the exact resolution order and failure behaviour for each.

### `SPECS_PATH`

The shared, team-visible repository holding the Product Requirements Document folder a keyed run reads, and the one place a run commits its own session bookkeeping. Set it to your specs clone. Without it, `/document` has nothing to resolve a key against and `/release-notes` falls back to attributing its cost to the PM's early phase.

### `REPOS_PATH`

Where your code clones live — one directory, or a colon-separated list of them. It defaults to `/workspace`, so most readers never set it. A keyed `/document` run resolves each pull-request URL to a local clone under here, matched by `git remote get-url origin` slug and **never by directory name**, so a clone renamed on disk is still found as long as its `origin` remote is intact.

### `DOCS_PATH`

A read-only clone of your shipped product documentation, defaulting to `/workspace/docs`. `/document` prefers it as a docs-repo discovery hint when your current working directory carries no documentation signals — in a container the docs clone is usually mounted right here, which makes this the common fast path. `/release-notes` reads the same variable for optional grounding against what is already published.

### `GIT_USER_INITIALS`

Your branch identifier, used by the two runs that create a branch in a documentation repository — `/document` in keyed mode, and `/docs-profile`. Branch naming is repo-rule-first: each reads the target repo's own documented convention and follows it as written, and this variable only fills a name-or-initials segment where the convention asks for one.

## Your first run

Start with `/docs-profile`, once per documentation repository:

```
/docs-workflows:docs-profile ~/repos/your-docs
```

It scans the repository, proposes a `.dev-workflows/docs-profile.yml` and complementary `CLAUDE.md` guidance, and leaves both on a branch with a drafted pull-request message. It never pushes or auto-merges. Skip this step and `/document` still runs — it falls back to a bundled default profile, or offers to profile the repository inline.

Then document a feature from its PRD:

```
/docs-workflows:document ACME-77
```

Here is what to expect. The run resolves the docs repository and its profile, reads the resolved PRD folder, resolves the pull requests named there to local clones, summarises their diffs in parallel, finds where each page belongs, plans the documentation, writes it, runs the style check, and gates the result on an Opus review before finishing on a branch with a copy-paste pull-request draft. For a one-off typo fix, pass a file or a description instead of a key — `/docs-workflows:document @note.md` — and the run takes the much shorter direct-mode path.

From here, [Workflow overview](workflow.md) shows where `/release-notes` fits, and the [documentation index](README.md) links every command page and inventory.

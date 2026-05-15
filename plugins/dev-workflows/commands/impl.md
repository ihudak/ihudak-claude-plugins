---
name: impl
description: Help and dispatcher for /impl variants. Prints available subcommands (/impl:code, /impl:docs, /impl:jira:docs, /impl:jira:epics) and usage guidance. Does not run any workflow itself.
allowed-tools: Read Glob
---

`/impl` is a help / dispatcher command, not an implementation workflow. It never executes any implementation, does not branch, does not run tests, does not invoke agents, and does not touch git state.

Your task: print the message below to the user, interpolating `$ARGUMENTS` into the "You invoked" line so they can see what the dispatcher received (if `$ARGUMENTS` is empty, render the line as `/impl  (no arguments passed)`). Do not classify, do not read project files, do not invoke any subagent, do not propose a plan — just print the message and stop.

---

### Message to print

```
You invoked: /impl $ARGUMENTS
```

As of plugin version **1.1.0**, `/impl` is a dispatcher — it does not run a workflow. Pick the variant that matches your task and re-run.

#### `/impl:*` variants

| Command | When to use | Example |
|---|---|---|
| `/impl:code <description>` | Source code changes — features, refactors, bug fixes in executable code. Classify → optional Opus plan → feature branch → test baseline → implement → write/verify tests → optional Opus review → maintenance → report. | `/impl:code add rate limiting to /api/users` |
| `/impl:docs <description>` | One-shot doc edits — single-file markdown, README tweaks, Obsidian notes, formatting. No branch, no tests, no code review, no commit. Always SIMPLE or MODERATE. | `/impl:docs add a troubleshooting section to README.md` |
| `/impl:jira:docs <VI-KEY>` | Jira-driven **feature documentation** — reads a Value Increment from the vault, resolves PR URLs to local repos, runs parallel PR-diff summaries, writes product docs, gated by Opus `doc-reviewer`. | `/impl:jira:docs MGD-2423` |
| `/impl:jira:epics <VI-KEY>` | Jira-driven **Epic drafting** — reads a Value Increment plus its existing Epics, optionally scans code for reusable capabilities, writes child Epic drafts into the vault, gated by Opus `epic-reviewer`. Never branches or commits. | `/impl:jira:epics MGD-2423` |

#### Related commands (same plugin)

| Command | When to use |
|---|---|
| `/vuln CVE-XXXX-XXXXX[:JIRA-ID]` | Fix security vulnerabilities — NVD research, classify, branch, fix, Opus review (for SIGNIFICANT / HIGH-RISK), baseline compare, PR. |
| `/upgrade component:version` | Upgrade dependencies — compatibility research, Opus plan (for SIGNIFICANT / HIGH-RISK), branch, apply, Opus review, baseline compare. |

#### Migration note (1.0.x users)

Pre-1.1.0, `/impl <description>` ran the full code-implementation workflow. That behaviour was removed in 1.1.0 to eliminate a ~27 KB verbatim copy between `commands/impl.md` and `commands/impl/code.md`. **Re-run your command as `/impl:code <description>`** — the workflow is unchanged, only the trigger moved.

See the plugin [CHANGELOG](https://github.com/ihudak/ihudak-claude-plugins/blob/main/plugins/dev-workflows/CHANGELOG.md) for details.

---

Do NOT proceed with any workflow. After printing the message above, stop.

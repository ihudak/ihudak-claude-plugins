---
name: prompt
description: Log a corrective interaction — a command produced something wrong and you're fixing it — as plugin feedback, then act on your correction directly. Captures the friction, your verbatim prompt, and the resolution to the specs repo for the maintainer.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Log a corrective interaction and act on it: $ARGUMENTS

`/prompt` is for when a dev-workflows command (`/specify`, `/design`,
`/implement`, `/document`, …) produced something wrong and you want to correct
it directly. It captures the **corrective triple** as plugin feedback, then
performs the correction. `origin: prompt`.

Captured (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` §1):
1. **Friction** — what the command produced that was wrong.
2. **User prompt** — your corrective request, **verbatim** (`$ARGUMENTS`).
3. **Resolution** — what the AI actually did.

---

## Phase 1 — Identify the target

Infer the target command from recent context — which command's output you are
correcting. Ask only if genuinely ambiguous (one grouped prompt, last choice
`"Other… (describe)"`). If no command applies, use `n/a`.

## Phase 2 — Act on the correction

Perform the corrective request in `$ARGUMENTS` directly (the quick correction).
Keep a one-line summary of what you did — this becomes the **Resolution** block.

## Phase 3 — Persist the corrective triple

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-prompt` entry point (§6). Provide:
- **Friction** — what the command produced that was wrong.
- **User prompt** — `$ARGUMENTS`, **verbatim** (never paraphrased).
- **Resolution** — the one-line summary of the correction you just applied.
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `jira_key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), and appends per §3
(prompt entries are never silently skipped). Write silently — a single append.

## Phase 4 — Report

Surface the persisted path and any degradation notice. This command NEVER
commits, and NEVER writes into a docs/code repo or the current working directory
(only the correction itself edits your target files, as you requested).

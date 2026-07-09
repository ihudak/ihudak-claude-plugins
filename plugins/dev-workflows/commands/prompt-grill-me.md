---
name: prompt-grill-me
description: Log a corrective interaction as plugin feedback, then hand off to /grilling (mattpocock-skills) to interrogate the fix — falling back to superpowers:brainstorming if mattpocock-skills is not installed. No hard dependency.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Log a corrective interaction, then grill the fix: $ARGUMENTS

`/prompt-grill-me` is for when a dev-workflows command produced something wrong
and you want a **relentless one-question-at-a-time interrogation** of the
correction. It captures the **corrective triple** as plugin feedback, then
runtime-resolves `/grilling` (mattpocock-skills), falling back to
`superpowers:brainstorming` if mattpocock-skills is not installed. `origin: prompt`.

`/grilling` is the invocable target — mattpocock's `/grill-me` is
`disable-model-invocation`, so this command resolves `/grilling` (which has no
such flag). mattpocock-skills is **NOT a declared dependency**; the command
degrades gracefully.

---

## Phase 1 — Identify the target

Infer the target command from recent context — which command's output you are
correcting. Ask only if genuinely ambiguous (one grouped prompt, last choice
`"Other… (describe)"`). If no command applies, use `n/a`.

## Phase 2 — Resolve the handoff target

Check whether the `/grilling` command (mattpocock-skills) is available in this
session:
- **Available** → the handoff target is `/grilling`.
- **Not available** → the handoff target is `superpowers:brainstorming`, and you
  MUST emit the notice:
  `mattpocock-skills not installed — using superpowers:brainstorming instead.`

## Phase 3 — Persist the corrective triple

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-prompt` entry point (§6). Provide:
- **Friction** — what the command produced that was wrong.
- **User prompt** — `$ARGUMENTS`, **verbatim** (never paraphrased).
- **Resolution** — `Handed off to <resolved target>` (the Phase 2 target —
  `/grilling`, or `superpowers:brainstorming` with the fallback notice).
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `jira_key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), appends per §3
(never silently skipped), and writes silently. Surface the persisted path and
any degradation notice.

## Phase 4 — Hand off

Invoke the Phase 2 target (Skill tool): `/grilling` when available, else
`superpowers:brainstorming` (having emitted the fallback notice). This command
NEVER commits, and NEVER writes into a docs/code repo or the current working
directory.

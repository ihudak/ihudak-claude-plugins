---
name: prompt-brainstorm
description: Log a corrective interaction as plugin feedback, then hand off to superpowers:brainstorming to redesign the correction together. Captures the friction, your verbatim prompt, and the resolution to the specs repo for the maintainer.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Log a corrective interaction, then brainstorm the fix: $ARGUMENTS

`/prompt-brainstorm` is for when a dev-workflows command produced something
wrong and the correction needs **exploration** rather than a one-shot fix. It
captures the **corrective triple** as plugin feedback, then hands off to
`superpowers:brainstorming`. `origin: prompt`.

---

## Phase 1 — Identify the target

Infer the target command from recent context — which command's output you are
correcting. Ask only if genuinely ambiguous (one grouped prompt, last choice
`"Other… (describe)"`). If no command applies, use `n/a`.

## Phase 2 — Persist the corrective triple

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-prompt` entry point (§6). Provide:
- **Friction** — what the command produced that was wrong.
- **User prompt** — `$ARGUMENTS`, **verbatim** (never paraphrased).
- **Resolution** — `Handed off to superpowers:brainstorming to redesign the correction.`
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `jira_key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), appends per §3
(never silently skipped), and writes silently. Surface the persisted path and
any degradation notice.

## Phase 3 — Hand off

Invoke `superpowers:brainstorming` (Skill tool) to explore and redesign the
correction with the user. This is a direct skill use — there is **no declared
install-time dependency**; the command simply invokes the skill if present.

This command NEVER commits, and NEVER writes into a docs/code repo or the
current working directory.

---
name: prompt-grill-me
description: Log a corrective interaction as plugin feedback, then grill the fix inline — a bounded one-question-at-a-time interrogation (≤5 questions) of the correction following the embedded grilling technique. Self-contained; no plugin dependency.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Log a corrective interaction, then grill the fix: $ARGUMENTS

`/prompt-grill-me` is for when a dev-workflows command produced something wrong
and you want a **bounded one-question-at-a-time interrogation** (≤5 questions) of
the correction. It captures the **corrective triple** as plugin feedback, then
grills the fix **inline** following the embedded grilling technique
(`${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md`). `origin: prompt`.

The interrogation is self-contained — this command owns the grill and has **no
plugin dependency**.

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
- **Resolution** — `Grilled the fix inline`.
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `jira_key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), appends per §3
(never silently skipped), and writes silently. Surface the persisted path.

## Phase 3 — Grill the fix (inline)

Interrogate the correction directly, following
`${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md`:
- **Depth:** **bounded** — a capped set (≤5) of the highest Impact×Uncertainty
  questions about the fix, then stop; record any leftover high-impact gaps.
- **Stage:** the correction itself — why the original output was wrong, what the
  right shape is, and what should change so the mistake does not recur.

Follow the technique's mechanics (one question at a time, a recommended answer
each time, fact-vs-decision split, dependency order). This command NEVER
commits, and NEVER writes into a docs/code repo or the current working
directory.

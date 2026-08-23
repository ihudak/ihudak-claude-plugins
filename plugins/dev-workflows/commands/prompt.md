---
name: prompt
description: Log a corrective interaction — a command produced something wrong and you're fixing it — as plugin feedback, then act on your correction directly. Captures the friction, your verbatim prompt, and the resolution to the specs repo for the maintainer.
allowed-tools: Read Edit Write Bash Glob Grep Task
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

## Phase 0 — Specs-repo preflight

Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session
artifacts from an earlier run, retry an artifact commit that failed to push,
and settle the branch. This runs against `$SPECS_PATH` only — `git -C
"$SPECS_PATH"`, never a `cd`, so whatever repository you are standing in is
untouched (§1 rule 1). Prompt-free and silent when the specs repo is clean and
on its default branch. If a guard fires, emit its §5 notice; if it returns
`specs_git: blocked` (§3.3 G0), carry that flag — the terminal
`commit-artifacts` step skips on it.

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

**Then emit session cost.** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md`
and call its `emit-cost` entry point with `command: /prompt`, `phase: inferred`,
`role: inferred`, the run's `jira_key` (or `null`) and `source`, and
`plugin_version`. The cost phase resolves the real labels from the **target
command** recorded above, per §7: a target with a fixed `phase`/`role` is
inherited outright, so correcting a `/specify` output is priced as
`specification`/`pe`; a target of `n/a`, a target with no §7 row, or a target
that is itself one of the four feedback commands resolves to
`phase: plugin-feedback`, `role: n/a`. A keyless run lands in §9's pending file
exactly as `/idea`'s does. Surface the persisted path (or the report-only
notice). This runs BEFORE the commit step below, per the emitter tail in §4 of
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline. It stages ONLY the §2.1 bounded
artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session
artifacts (/prompt)` — or `NOISSUE …` when no `jira_key` resolved — and
pushes. It NEVER touches a code/docs repo, the vault, or the current working
directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the
run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its
§6 outcome line for Phase 4.

## Phase 4 — Report

Surface the persisted path and any degradation notice, then the `Specs repo:`
outcome line from `commit-artifacts`
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard
notice repeated in full.

This command NEVER commits into a docs/code repo, the vault, or the current
working directory — only the correction itself edits your target files, as
you requested, and those edits are never staged. The terminal
`commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).

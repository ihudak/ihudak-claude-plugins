---
name: prompt-brainstorm
description: Log a corrective interaction as plugin feedback, then hand off to superpowers:brainstorming to redesign the correction together. Captures the friction, your verbatim prompt, and the resolution to the specs repo for the maintainer.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Log a corrective interaction, then brainstorm the fix: $ARGUMENTS

`/prompt-brainstorm` is for when a dev-workflows command produced something
wrong and the correction needs **exploration** rather than a one-shot fix. It
captures the **corrective triple** as plugin feedback, then hands off to
`superpowers:brainstorming`. `origin: prompt`.

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

## Phase 2 — Persist the corrective triple

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-prompt` entry point (§6). Provide:
- **Friction** — what the command produced that was wrong.
- **User prompt** — `$ARGUMENTS`, **verbatim** (never paraphrased).
- **Resolution** — `Handed off to superpowers:brainstorming to redesign the correction.`
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), appends per §3
(never silently skipped), and writes silently. Surface the persisted path and
any degradation notice.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — before the Phase 3 hand-off,
because the brainstorming skill takes over the session there. It stages ONLY the
§2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add
dev-workflows session artifacts (/prompt-brainstorm)` — or `NOISSUE …` when no
`key` resolved — and pushes. It NEVER touches a code/docs repo, the vault,
or the current working directory; NEVER force-pushes; NEVER fails the run; and
skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting
that notice. Print its §6 outcome line here, prefixed `Specs repo:`, with any
guard notice repeated in full.

## Phase 3 — Hand off

Invoke `superpowers:brainstorming` (Skill tool) to explore and redesign the
correction with the user. This is a direct skill use — there is **no declared
install-time dependency**; the command simply invokes the skill if present.

This command NEVER commits into a docs/code repo, the vault, or the current
working directory. The Phase 2 `commit-artifacts` step commits ONLY
`$SPECS_PATH`'s bounded artifact paths
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).

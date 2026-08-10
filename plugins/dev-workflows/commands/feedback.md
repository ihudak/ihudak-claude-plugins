---
name: feedback
description: Log a manual note about the dev-workflows plugin itself — friction you hit or an improvement you want — to the per-VI feedback file in the specs repo, for the plugin maintainer to aggregate. Tied to no command; run any time.
allowed-tools: Read Edit Write Bash Glob Grep
---

Log session feedback about the dev-workflows plugin: $ARGUMENTS

`/feedback` captures a **manual note about the dev-workflows plugin itself** —
friction you hit, or an improvement you want — and persists it per-VI into the
specs repo so the plugin maintainer can aggregate feedback across engineers. It
is tied to **no command** and can be run any time. You author the prose; the
command fills the metadata and writes the entry. `origin: manual`.

This command captures signal about **the plugin**, not about your target
project. Target-project tooling advice does not belong here (see
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` §4).

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

## Phase 1 — Compose the note

1. If `$ARGUMENTS` is empty, ask the user for the note (the friction and the
   improvement they want). Do not guess.
2. From the user's text, author two prose blocks — you may lightly tidy wording
   but never invent content the user did not express:
   - **Friction** — what about the plugin was wrong, slow, or missing.
   - **Suggested improvement** — the change they want.

## Phase 2 — Fill the metadata

Resolve, then confirm with the user in one grouped prompt (last choice always
`"Other… (describe)"`):

- **`command`** — the exact slash-command name this note is about, inferred from
  recent context; or `n/a` if it is not about a specific command. Confirm.
- **`category`** — inferred from the controlled vocab in
  `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` §1
  (`missing-capability`, `wrong-output`, `ambiguous-prompt`,
  `missing-reference-doc`, `model-routing`, `manual-workaround`,
  `false-positive`, `docs-ux`, `other`); reuse an existing value when it fits.
  Confirm.
- **`impact`** — `blocker | friction | polish`.
- **`author`** — `git config user.email` run in the specs repo (best-effort;
  `unknown` if unset).
- **`plugin_version`** — read from
  `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

Also resolve `jira_key` (from recent context, or `null`) and `source`
(`vault | directory | none`).

## Phase 3 — Persist

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-manual` entry point (§6): resolve the write target via the §2 specs-first
ladder using `jira_key` and `source`, format the entry per §1 (`origin:
manual`), and append per §3 (manual entries are never silently skipped — on an
`id` collision append a numeric suffix and warn). Write silently.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline. It stages ONLY the §2.1 bounded
artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session
artifacts (/feedback)` — or `NOISSUE …` when no `jira_key` resolved — and
pushes. It NEVER touches a code/docs repo, the vault, or the current working
directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the
run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its
§6 outcome line for Phase 4.

## Phase 4 — Report

Surface the persisted path and any degradation notice (e.g. the tier-3 vault
warning, or tier-5 report-only), then the `Specs repo:` outcome line from
`commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6),
with any guard notice repeated in full.

This command NEVER commits into a docs/code repo, the vault, or the current
working directory. The terminal `commit-artifacts` step commits ONLY
`$SPECS_PATH`'s bounded artifact paths
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).

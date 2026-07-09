---
name: feedback
description: Log a manual note about the dev-workflows plugin itself — friction you hit or an improvement you want — to the per-VI feedback file in the specs repo, for the plugin maintainer to aggregate. Tied to no command; run any time.
allowed-tools: Read Edit Write Bash Glob Grep LS
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

## Phase 4 — Report

Surface the persisted path and any degradation notice (e.g. the tier-3 vault
warning, or tier-5 report-only). This command NEVER commits, and NEVER writes
into a docs/code repo or the current working directory.

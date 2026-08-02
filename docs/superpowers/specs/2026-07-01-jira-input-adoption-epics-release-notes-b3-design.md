---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-07-01
---

# dev-workflows — Jira-input front-end adoption for `/epics` + `/release-notes` (Effort B3) (design)

## Context

Effort B2 (v2.1.0, shipped) extracted a **shared Jira-input resolution
front-end** into `references/jira-input-resolution.md` and wired `/implement`
and `/document` onto it: one input grammar (JiraID **or** imported-Jira
directory **or** direct prompt), a mode classifier (`jira-driven` | `direct`),
`SPECS_PATH`-based specs resolution, and a normalized output contract. The
reference was deliberately written to be **adoptable** by the two remaining
Jira-driven commands — its own text says so (lines 7-8: "`/epics` and
`/release-notes` do **not** use this yet").

Today `/epics` and `/release-notes` still each carry their **own** Phase 0
input resolution:

- **`/epics`** — resolves `$VAULT_PATH` (required, must contain `jira-products/`),
  **requires cwd to be inside `$VAULT_PATH`** (a leftover output-safety gate),
  resolves `<JIRA_KEY>` from `$ARGUMENTS`, validates
  `$VAULT_PATH/jira-products/<KEY>/`, and calls `jira-reader` with the legacy
  `vault_path` + `jira_key` form. It is JiraID-only and hard-requires the vault.
- **`/release-notes`** — same JiraID-only Phase 0 (resolve `$VAULT_PATH`, resolve
  `<JIRA_KEY>`, validate `jira-products/<KEY>/`), legacy `jira-reader` call. Also
  JiraID-only, hard-requires the vault.

Both carry literal `$VAULT_PATH/jira-products/<KEY>/` references throughout —
the exact "literal `jira-products` consumer" class B2 rewired onto
`jira_export_root` in `/document`. Neither accepts a directory, so neither works
when `$VAULT_PATH` is unset (non-AI-Containers, or a ticket imported elsewhere).

This effort makes both commands **adopt the shared front-end** for input,
gaining the directory / undefined-`$VAULT_PATH` case and closing the literal
`jira-products` consumer class across the whole command surface. Plugin `main`
at `39be608` (v2.1.0). Release: **MINOR `v2.2.0`** (purely additive — every
existing JiraID + `$VAULT_PATH`-set invocation still works byte-for-byte).

## Goals

- Both commands' Phase 0 **cite and execute** `references/jira-input-resolution.md`
  for input resolution, replacing their bespoke `$VAULT_PATH` + `jira-products`
  resolution.
- **Directory input** (the new capability) for both: accept an imported-Jira
  directory rooted anywhere, so they work when `$VAULT_PATH` is unset.
- **Rewire literal `jira-products` read-consumers** onto `jira_export_root`
  (the B2 fix, applied to these two commands).
- `jira-reader` invoked with the **additive `jira_export_root` + `jira_key`**
  form in both commands (the front-end always resolves `jira_export_root`).
- **Output stays a file, always** — no print-only fallback (markdown pasted from
  a console into Jira loses formatting).
- **Projects/Products kept as the output home** — decoupled from *input*, retained
  for *output* (release-notes drafts, gaps, screenshots, the working file).
- Purely additive: `$VAULT_PATH`-set behavior is **byte-unchanged**.

## Architecture principle

The front-end resolves **input only** (`jira_key`, `jira_export_root`); each
command keeps its **output** resolution command-local (the contract carries no
workdir — a settled B2 decision). This is *not* `/document`'s docs-repo model:
`/document` works against a discovered docs repo (`docs_repo_path`), whereas
`/epics` and `/release-notes` write into the vault. The only thing all four
commands share is the input front-end.

Per-command working-dir / output targets:

| Command | Output target | Resolved how |
|---|---|---|
| `/document` | docs repo (`docs_repo_path`) | Phase 0 preflight discovery under `/workspace` |
| `/epics` | vault `jira-drafts/<VI-KEY>/` (or derived) | `$VAULT_PATH`-absolute, else derived from `jira_export_root` |
| `/release-notes` | vault `Projects/<KEY>*/…` (or derived) | `$VAULT_PATH`-absolute, else derived from `jira_export_root` |

## Non-goals (recorded as future work)

- **Follow-up-tasks-in-the-working-file (Effort B4)** — appending `- [ ]` tasks
  (Obsidian-Tasks syntax) to a project's `P<NNNN> <slug>.md` working file
  `### Tasks` section when the pipeline finds a gap / discrepancy / manual step.
  Cross-command (also `/document`); its own brainstorm.
- **Full Projects/Products *removal*** — retired. Superseded by "keep for output,
  decouple from input" (this effort embodies that; no removal work).
- **Resumable `/epics` drafting** — reviewing the output dir for drafts from a
  prior partial run (interrupted by rate limits, continued next day) and
  continuing from Epic N+1 without regenerating the first N. A Phase 6 workflow
  concern, orthogonal to input adoption; B3 leaves Phase 6 write behavior
  unchanged (`/epics` re-drafts all Epics each run today). Recorded as its own
  future effort.
- Per-step **model-delegation** for `/implement` / `/vuln` / `/upgrade`.
- The **brainstorm-spec+dev-plan-from-a-Jira-ticket** command(s).
- No change to either command's **downstream pipeline** (code-scan, `epic-writer`,
  `release-notes-writer`, review/style gates) beyond input/output plumbing.
- No change to **`jira-reader`'s reading logic** — only which input fields the
  callers pass (the additive form already shipped in B2).

## Design

### A. Reference generalization (`references/jira-input-resolution.md`)

Minimal, no behavioral change to the algorithm:

- **Line 3** — broaden "Shared input-resolution mechanics for `/implement` and
  `/document`" → "…for the Jira-driven commands: `/implement`, `/document`,
  `/epics`, `/release-notes`."
- **Lines 7-8** — drop the "`/epics` and `/release-notes` do **not** use this
  yet (the reference is written to be adoptable by them later)" note.
- Add **one** clause (near §Output-contract or §Specs-resolution): "`/epics` and
  `/release-notes` are **jira-driven only** — they consume
  `{mode, source, jira_key, jira_export_root}`, ignore `specs` / `direct_prompt`
  / `direct_files`, and **reject** `mode: direct` (stop with a clear error; they
  have no non-Jira behavior)."
- Grammar, mode decision, resolution branches, fallbacks A/B/C, and the output
  contract are **unchanged** — they already generalize.

### B. `/epics` Phase 0 rewrite

Replace steps 1-3 (resolve `$VAULT_PATH` / require-cwd-in-vault / resolve
`<JIRA_KEY>`) with an **inline citation** of the front-end (parse `$ARGUMENTS`
→ the normalized contract), the same inline-execution pattern `/document` uses.
The command consumes `{mode, source, jira_key, jira_export_root}`.

1. **Reject `direct` mode.** If the front-end returns `mode: direct` (no Jira
   input resolved), stop: "`/epics` needs a Jira key or an imported-Jira
   directory."
2. **Drop the cwd-in-vault gate.** `/epics` becomes **cwd-agnostic** (like
   `/document` is for its docs repo); the output is always resolved to an
   absolute path, so the guardrail is vestigial. Output-dir resolution:
   - **`$VAULT_PATH` set** → default `$VAULT_PATH/jira-drafts/<VI-KEY>/`
     (**unchanged**; auto-created if missing per the existing Phase 1 default and
     the Phase 6 write invariant; works from any cwd). `<VI-KEY>` = the resolved
     **input `jira_key`** (the Value Increment the Epics are drafted *for*).
   - **`$VAULT_PATH` unset** (directory input) → default
     `<parent-of-jira_export_root>/epic-drafts/<VI-KEY>/` (auto-created;
     writability-checked). The existing "use a different path / cancel" choices
     are retained. The **warn** here is a *path-safety guard*: it fires only if
     the resolved dir would land *inside* `jira_export_root` (wiped and
     regenerated on every import, so drafts there would be lost) — **not** when
     the dir already exists with drafts, which is normal.
   - The drafted Epics have no Jira ID yet, so — as today — they are written as
     **slug-named files** (`<new-epic-slug>.md`) *inside* the VI-keyed folder.
     `/epics` is **one-shot**: a single invocation dispatches `epic-writer` once
     and drafts all child Epics of the VI in that pass, so the guard above (and
     any output-dir prompt) fires at most once per run.
3. **`jira-reader` call (Phase 3)** — pass `jira_export_root` + `jira_key`
   (front-end contract) instead of `vault_path` + `jira_key`; `depth`
   unchanged (`vi-plus-epics`).
4. **Rewire literal consumers** — every literal `$VAULT_PATH/jira-products/<KEY>/`
   used to *read/echo the input hierarchy* (e.g. the Phase 2 plan echo, the
   Phase 9 report) → `jira_export_root`. Literal `$VAULT_PATH`-based **output**
   paths (`jira-drafts/`) stay as-is in the vault case.
5. **"Project root = `$VAULT_PATH`" usages** — the `dt-style-checker` "Project
   root" briefs, the Phase 8 `git diff`, and the Phase 7 review "Project root"
   resolve to the **output-dir root** when `$VAULT_PATH` is unset (the vault case
   is unchanged).
6. **Label consistency** — the current command labels the same value both
   `<VI-KEY>` and `<JIRA_KEY>`; standardize the rewrite on the front-end's
   `jira_key`, stated explicitly as "the input VI key."

### C. `/release-notes` Phase 0 rewrite

Replace steps 1-2 with the front-end citation; consume the same four fields;
**reject `direct` mode** (same message pattern).

1. **`jira-reader` call (Phase 3)** — pass `jira_export_root` + `jira_key`;
   `depth` logic unchanged (`vi-only` when diff-grounding OFF, `full` when ON).
2. **Rewire literal `jira-products` read-consumers** → `jira_export_root`.
3. **Output — always a file, never print-only:**
   - **`$VAULT_PATH` set** → resolve the ticket's persistent Projects folder and
     write `<KEY>-release-notes.md` there, **exactly as today** (byte-unchanged;
     the existing `find "$VAULT_PATH/Projects" -maxdepth 5 -type d -name
     `"<KEY>*"` resolution and its choice menu are preserved).
   - **`$VAULT_PATH` unset** (directory input, no Projects folder to find) →
     write a **file** at a derived default (`<KEY>-release-notes.md` next to
     `jira_export_root`, auto-created). **Print-to-screen is demoted to a
     secondary option**, never the default.
4. **Gaps** (`bug_report_destination` / `<KEY>-implementation-gaps.md`) follow
   the same rule: vault set → Projects folder as today; unset → derived path
   (report-only remains a secondary option, not the default).

### D. Projects/Products — kept for output

No removal work. Projects/Products remains the persistent **output** home
(release-notes drafts, `-implementation-gaps.md`, `Doc screenshots/`, the
`P<NNNN> <slug>.md` working file). It is decoupled only from **input**: input
resolution now flows through the front-end (`jira_export_root` for the Jira
hierarchy; `SPECS_PATH`/directory for specs — though these two commands consume
no specs). This supersedes the earlier "remove Projects/Products dependency"
candidate.

### E. Per-command contract consumption

Both commands read only `{mode, source, jira_key, jira_export_root}` from the
normalized output contract and **ignore** `specs`, `direct_prompt`,
`direct_files`. `mode: direct` is rejected (goal B/C step 1).

### F. Hook (`hooks/preload-context.sh`)

**No functional change required.** The `epics|release-notes` case already calls
`emit_jira_context`, which already degrades when `$VAULT_PATH` is unset
("(not set — the command will ask …)"); directory arguments already match the
submit regex (`^/(…|epics|release-notes|…)[[:space:]]+[^[:space:]-]`). Optional:
refresh the comment block (lines 15-18) to note directory input is now accepted.
(`emit_jira_context` prints `SPECS_PATH`, which these two don't use — harmless;
left as-is to keep the shared helper simple.)

### G. Manifests / README / CHANGELOG

- `.claude-plugin/plugin.json` top-level `version` → **`2.2.0`**.
- `.claude-plugin/marketplace.json` `plugins[0].version` → **`2.2.0`**
  (siblings `dt-style-guide` `0.2.2` / `obsidian-llm-wiki` `0.3.1` untouched).
- `README.md` — note `/epics` and `/release-notes` now accept an imported-Jira
  directory and work without `$VAULT_PATH`.
- `CHANGELOG.md` — prepend `## [2.2.0] — 2026-07-01` (em-dash), additive entry;
  preserve all prior history.

## Touch list

- `references/jira-input-resolution.md` — §A generalization (≈4 lines).
- `commands/epics.md` — §B Phase 0 rewrite + output resolution + drop cwd gate +
  `jira-reader` call + literal-consumer rewire + project-root fallback.
- `commands/release-notes.md` — §C Phase 0 rewrite + output (never-print-only) +
  `jira-reader` call + literal-consumer rewire + gaps fallback.
- `hooks/preload-context.sh` — optional comment refresh only (§F).
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
  `README.md`, `plugins/dev-workflows/CHANGELOG.md` — §G release v2.2.0.

## Verification (structural — no test framework)

- **Adoption** — both command files cite `references/jira-input-resolution.md`;
  their Phase 0 no longer duplicates `$VAULT_PATH` + `jira-products/<KEY>`
  resolution.
- **Consumer rewire** — no literal `$VAULT_PATH/jira-products/<KEY>` remains as a
  *read/echo of the input hierarchy* in either file (grep); `jira-reader`
  invocations pass `jira_export_root` + `jira_key`.
- **Byte-unchanged** — diff-inspect that the JiraID + `$VAULT_PATH`-set path
  produces the same prompts, output dirs, and destination menus as before
  (only the vault-unset directory branch is new).
- **Direct-mode rejection** — both commands stop with a clear error on
  `mode: direct`.
- **Hook** — if touched, `bash -n hooks/preload-context.sh` + a functional
  submit test for `/epics <dir>` and `/release-notes <dir>`.
- **Release** — `plugin.json` + `marketplace.json plugins[0].version` both
  `2.2.0`; siblings untouched; JSON valid; CHANGELOG history preserved,
  new entry uses an em-dash.

## Invariants preserved

- `jira-reader` remains read-only; legacy `vault_path` + `jira_key` form still
  works for any un-migrated caller (additive, from B2).
- `/epics` never branches, never commits; `/release-notes` never commits.
- Zero external API calls added.
- `$VAULT_PATH`-set behavior is byte-for-byte unchanged for both commands.

## Task decomposition (estimate)

Four tasks, structural verification, order T1 → T4:

- **T1** — reference generalization (§A).
- **T2** — `/epics` Phase 0 + output + drop cwd gate + `jira-reader` + rewire (§B).
- **T3** — `/release-notes` Phase 0 + never-print-only output + `jira-reader` +
  rewire (§C).
- **T4** — hook comment (§F) + manifests/README/CHANGELOG v2.2.0 (§G).

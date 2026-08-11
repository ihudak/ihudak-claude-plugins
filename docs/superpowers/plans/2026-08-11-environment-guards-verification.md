# 2026-08-11 environment-guards — verification results (Task 12)

Whole-branch verification sweep across three repositories, all on branch `iv-gu/environment-guards`:

- `/workspace/ihudak-claude-plugins` (canonical) — `plugins/dev-workflows/`, v2.47.0
- `/workspace/mgd-claude-plugins` (mgd) — `plugins/dev-workflows/`, v2.47.0
- `/workspace/ihudak-copilot-plugins` (copilot) — `dev-workflows/`, v2.17.0

Rule applied throughout: every expected value below was re-derived from the tree at verification time, not restated from the spec, the plan, or the task-12 brief. Where a stated expectation in the brief/spec proved wrong, the discrepancy is called out in the Notes column rather than silently corrected.

## Half A — qmd discipline in `docs-grounder.md` (V1–V4, V11–V13), all three editions

| Check | Command | Actual | Pass/Fail | Notes |
|---|---|---|---|---|
| V1 | `grep -n 'qmd collection add\|qmd collection remove\|qmd collection rename\|qmd embed\|qmd update\|qmd init\|qmd cleanup' agents/docs-grounder.md` (×3 editions) | 3 hits per edition, identical lines 131–133, all under `- NEVER …` bullets; line 131 alone bans all 7 named ops in one bullet | PASS | Content identical across canonical, mgd, copilot |
| V2 | `grep -n 'qmd query' agents/docs-grounder.md` (×3 editions) | 2 hits per edition — line 46 is prose stating "`qmd query` is NEVER invoked", line 134 is a `- NEVER run \`qmd query\`` bullet | PASS | Both hits are ban prose, none is an invocation instruction |
| V3 | `grep -c 'qmd-vector\|qmd-lexical' agents/docs-grounder.md` (×3 editions) | 3 | PASS | Matches the rung table (2 rows) + the `retrieval:` enum line (1) |
| V4 | Read `references/docs-grounding.md` step 3.5 | Step 3.5 has 3 branches (qmd absent → fallback; collection covers docs_root → `timeout 60s qmd update`; no collection → build prompt), both `choices:` arrays present (lines 39–42, 48–51), 60s cap present (line 36, referenced again line 71) | PASS | V4 not scripted in the brief; verified by direct read of `docs-grounding.md` |
| V11 | `git diff main..HEAD -U0 -- plugins/dev-workflows/references/docs-grounding.md \| grep -E '^-.*(non-empty\|test -d\|test -r\|find "\$docs_root")'` | No output (4 lines removed total; none match the pattern) | PASS | Confirmed non-trivial: diff has 4 deletions / 39 insertions; none of the 4 removed lines touch the validity gate |
| V12 | `grep -c '200 files\|40 files\|3–8' agents/docs-grounder.md` (×3 editions) | 3 | PASS | Matches Path B's 3 bounds: "3–8" keywords, "200 files" drop, "40 files" cap (lines 53–55) |
| V13 | `grep -n 'Shadow detection\|staleness' references/docs-grounding.md` | Both present — "Shadow detection." (line 82) and "Docs-checkout staleness." (line 80) | PASS | V13 not scripted in the brief; verified by direct read |

## V5 — plan-approval line ownership

| Check | Command | Actual | Pass/Fail | Notes |
|---|---|---|---|---|
| V5 | `grep -rl 'docs grounding:' commands/*.md` | 6 consumer commands: `idea.md`, `create-vi.md`, `create-ard.md`, `epics.md`, `update-vi.md`, `specify.md` — all instruct "Show the `docs grounding:` line … verbatim …" quoting `docs-grounding.md` as the format owner, `/epics` included | PASS | Not identical prose word-for-word, but all single-source the format from `docs-grounding.md` and instruct verbatim reproduction, satisfying "this reference owns the format; consumer commands quote it" |

## Half B — read-only wiring and the dead-gate check (V6–V10)

| Check | Command | Actual | Pass/Fail | Notes |
|---|---|---|---|---|
| V6 | `grep -l 'read-only-repos.md' agents/*.md` | 3: `code-scanner.md`, `diff-summarizer.md`, `docs-grounder.md`; file exists at `references/read-only-repos.md` | PASS | `docs-grounder.md` confirmed to touch `git` directly (line 59, `git log --all --grep`), so all 3 are legitimately "git-touching" |
| **V7 (dead-gate check)** | `grep -l 'Read-only mount — ref stale or diverged' commands/*.md` | **7**: `implement.md`, `epics.md`, `design.md`, `create-ard.md`, `document.md`, `release-notes.md`, `specify.md` | **PASS** | Matches the brief's exact expectation (5 from Task 6 + `/create-ard` + `/release-notes` from Task 7). Cross-checked: union of commands citing `code-scanner`/`diff-summarizer` is 8 (adds `ready.md`), but `ready.md` explicitly states (×2) "never dispatch `code-scanner`" — so it correctly does not need the citation. No missing command found |
| V8 | `grep -A3 'Read-only mount — ref stale or diverged' references/escalation-rules.md` | Entry present with 4 `choices:` — "Scan released code at `<ref>` (Recommended — cites shipped behavior)", "Scan the working tree …", "Cancel — refresh on the host …", "Other… (describe)" | PASS | Last option is `"Other… (describe)"`; Recommended option is reason-annotated |
| V9 | `grep -c 'read_only\|scanned_ref\|ref_committed_at\|head_divergence' references/handoff/{code-scanner,diff-summarizer}.md` | 6 each; both files define all 4 fields in the `prep:` block and restate "always present, so a caller never branches on absence" | PASS | |
| V10 | `grep -n 'git switch\|git pull --ff-only' agents/code-scanner.md agents/diff-summarizer.md` | Both present in both files — writable-path prep steps unchanged, read-only fallback added alongside | PASS | No regression on writable mounts |

## Cross-repo (V14–V18)

| Check | Command | Actual | Pass/Fail | Notes |
|---|---|---|---|---|
| V14 | `diff -rq plugins/dev-workflows` (canonical vs mgd) + separate root-file diff | Inside `plugins/dev-workflows`: **5** files differ — `.claude-plugin/plugin.json`, `CHANGELOG.md`, `LICENSE`, `README.md`, `references/dependencies.md`. At repo root: **2** more differ — `CLAUDE.md`, `.claude-plugin/marketplace.json`. Total = **7** identity files, all differences confirmed content-legitimate (edition-specific: marketplace name, dates, author) | **PASS (content) / plan wrong (arithmetic)** | The task-12 brief's own comment says "5 here plus the 2 root files checked separately = **6** identity files" and the design spec (`specs/2026-08-11-environment-guards-design.md` line 233, 274) also says "exactly the **six** identity files" and its enumerated list omits `CHANGELOG.md`. Both undercount: 5 + 2 = 7, not 6, and `CHANGELOG.md` legitimately differs (it is one of the 4 files the mgd port hand-edits per spec line 233 itself). **The plan/spec's number and file list are wrong; the shipped content is correct** — this is exactly the class of error this task exists to catch, not a content defect |
| V15 | `find . -name 'marketplace.json'` in each repo, then check `dev-workflows` entry version | canonical `.claude-plugin/marketplace.json` → 2.47.0; mgd `.claude-plugin/marketplace.json` → 2.47.0; copilot `.github/plugin/marketplace.json` → 2.17.0 — each matches its repo's `plugin.json` version | PASS | Enumerated by `find`, not typed; copilot's catalog correctly found at `.github/plugin/marketplace.json` |
| V16 | `git diff main..HEAD` in copilot repo, grep added (`^+`) lines only for `${CLAUDE_PLUGIN_ROOT}`, `subagent_type`, `Agent (subagent_type:` | No output — zero forbidden tokens in newly added copilot content | PASS | A naive whole-file grep on changed files does hit 2 lines in `CHANGELOG.md` (mentioning `${CLAUDE_PLUGIN_ROOT}` in contrastive prose about what copilot does *not* use), but those lines are pre-existing (not in the diff hunks) — confirmed via `git diff -U2` showing no match. Restricting to actual added lines is the correct check and it is clean |
| V17 | `grep -n 'read-only-repos.md'` in canonical `CLAUDE.md`, mgd `CLAUDE.md`, copilot `dev-workflows/README.md` | Present in all 3: canonical line 122, mgd line 134, copilot README line 363 — all describe the same contract (probe, skip list, write-free reads, 14-day staleness, `prep` fields) and both canonical/mgd say "cited by the seven commands that dispatch them" | PASS | Cross-confirms the V7 count of 7 independently, from a different source file |
| V18 | Compare `plugin.json` version, catalog version, `CHANGELOG.md` top entry per repo | canonical: 2.47.0 / 2.47.0 / `## [2.47.0] — 2026-08-11`; mgd: 2.47.0 / 2.47.0 / `## [2.47.0] — 2026-08-11 (ported from \`ihudak-claude-plugins\`)`; copilot: 2.17.0 / 2.17.0 / `## [2.17.0] — 2026-08-11` | PASS | All 3 sources agree per repo; mgd's CHANGELOG header correctly annotates the port |

## Summary

- **34 sub-checks run across V1–V18** (several ×3 editions). All PASS on content.
- **V7, the dead-gate check, returns 7** — `implement.md`, `epics.md`, `design.md`, `create-ard.md`, `document.md`, `release-notes.md`, `specify.md` — matching the brief's exact expectation. No command dispatching `code-scanner`/`diff-summarizer` is missing the escalation citation.
- **One plan/spec defect found (V14):** the task-12 brief and the design spec both state the mgd-parity diff should show "six identity files," and the design spec's file list omits `CHANGELOG.md`. The tree actually shows **7** identity files differing (5 inside `plugins/dev-workflows` including `CHANGELOG.md`, + 2 at repo root: `CLAUDE.md` and `.claude-plugin/marketplace.json`), and every one of the 7 differences is legitimate edition-specific content (not drift). This is an arithmetic/enumeration error in the planning documents, not a defect in the shipped port — no fix to `plugins/dev-workflows` or `mgd-claude-plugins` content is warranted.
- No FAILED checks.

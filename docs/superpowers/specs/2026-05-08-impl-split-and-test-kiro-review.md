# Kiro review — impl split + test-writing design

**Reviewed spec:** [`2026-04-30-impl-split-and-test-writing-design.md`](2026-04-30-impl-split-and-test-writing-design.md)
**Review date:** 2026-05-08
**Reviewer:** Kiro (AI)

> **Superseded in part (2026-05-10):** Sections of this review that discuss the `/impl` **alias** mechanism (verbatim duplication of `commands/impl/code.md` into `commands/impl.md` guarded by a `<!-- KEEP IN SYNC -->` marker — e.g. entries Q3b, line 150, line 163, line 246, W7-m3) reflect the **pre-Increment-G** design. Increment G (2026-05-10) replaced the alias with a **help / dispatcher**; `commands/impl.md` no longer mirrors `commands/impl/code.md` and no KEEP IN SYNC marker exists in the shipped code. For the authoritative current design, see the **Design evolution** section at the top of the main spec document. This review remains accurate for every finding that is not specifically about the alias mechanism.

---

## Legend

| Field | Meaning |
|---|---|
| **Status** | `Open` — not started · `In progress` — being applied · `Fixed` — spec updated · `Deferred` — postponed to a follow-up · `Won't fix` — rejected with reason |
| **Spec section(s)** | The section(s) of the design spec that must be edited |
| **Resolution** | One-liner describing what was actually changed (filled when `Fixed`) |

**Progress:** 29 / 29 fixed from the original audit · 4 critical · 9 major · 10 minor · 6 nits · 4 post-review amendments (A1 + wave-5 feedback + wave-6 self-audit + wave-7 reality-ground)

---

## Decisions resolved (2026-05-08)

These design choices were agreed before applying fixes. Each fix below must honour them.

| # | Question | Choice |
|---|---|---|
| Q1 | Bitbucket PR-ref Strategy 1 | Demote to optimistic first try; Strategies 2/3 are the workhorse. No HTTPS/REST wrapper (`acli` is Cloud-only; Bitbucket Server CLIs all wrap REST). |
| Q2 | Versioning | Add `version` field to each plugin's `plugin.json` and the `plugins[]` entry in `marketplace.json`; bump as part of this change. |
| Q3 | Namespaced-command file layout | Directory form: `commands/impl/code.md` → `/impl:code`. (Cross-platform safe; avoids `:` in filenames.) |
| Q3b | `/impl` alias mechanism | `impl.md` contains the full content of `impl:code.md` duplicated verbatim, with a `<!-- KEEP IN SYNC WITH commands/impl/code.md -->` marker. |
| Q4 | `/impl:code` no-test-framework on SIGNIFICANT/HIGH-RISK | Mirror the SIMPLE/MODERATE prompt: `choices: ["Specify test command", "Skip tests (document why)", "Cancel"]`, asked before Opus review. |
| Q5 | Parallel spawn cap | Cap at **4** in parallel for `diff-summarizer` / `code-scanner`; queue the rest. |
| Q6 | `doc-reviewer` model | **Opus** (mirrors `code-review` gate role). |
| Q7 | `preload-context` hook scope | `/impl:code` = full context; `/impl:docs` = none; `/impl:jira:docs` + `/impl:jira:epics` = inject `$VAULT_PATH` + `/repos` base only (no git branch context unless cwd is in a git repo). |
| Q8 | `jira-reader` depth for Epic writing | Introduce new `depth: vi-plus-epics` — reads the index + VI + existing Epic `.md` files linked to the VI (not Stories/Sub-tasks). Used by `/impl:jira:epics`. |
| Q9 | `<KEY>-comments.md` / `attachments/` | Ignore by default; no user-facing toggle. |
| Q10 | GitHub PR support via `gh` | Add `gh`-based resolution for `github.com` URLs as a second code path in `diff-summarizer`. Bitbucket stays pure-local-git. |
| Q10b | GitHub repo layout | GitHub repos also expected under `/repos/<name>`; same escalation rules if missing. |
| Q11 | Cloud-without-CLI behaviour | Graceful fallback to local-git strategies (branch search, merge-commit grep) — keeps the command useful even when no CLI is installed. |
| Q12 | Bitbucket Cloud CLI | **Deferred.** Atlassian's official `acli` does not support Bitbucket at time of writing (verified against ACLI v1.3.15). Bitbucket Cloud URLs use local-git strategies for now. Third-party CLIs (Appfire BCCLI, community `bkt`) are noted as future options but not adopted in this iteration. |
| Q12' | Bitbucket Cloud CLI plan | Defer — note as a future enhancement; add when an official or de-facto-standard CLI stabilises. |
| Q13 | Self-hosted Bitbucket host matching | Hostname contains substring `bitbucket` AND is not `bitbucket.org`. No hardcoded hostname in the plugin. |

### Environment prerequisites to document in the design spec

- **`gh auth login`** must be run once on the host before `/impl:jira:docs` or `/impl:jira:epics` will resolve GitHub PRs (graceful fallback to local-git strategies if absent).
- **No Bitbucket CLI is required or assumed** — both Bitbucket Cloud and self-hosted Bitbucket Server URLs are resolved purely from the local clone.
- **Recommended environment: AI Container** (<https://github.com/ihudak/ai-containers>) — mounts `/repos`, installs `gh` automatically, and mounts `~/.config/gh` from the host so `gh` authentication carries over transparently.

---

## Summary

The spec is well thought-through, but has several concrete technical errors that will bite during implementation, plus a handful of ambiguities and missing pieces. Findings are ranked by severity.

---

## Critical (will break implementation)

### C1. Strategy 1 PR-ref resolution does not work on a default Bitbucket clone

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 13 (`diff-summarizer`)
- **Resolution:** Section 13 PR-resolution block rewritten to flag Strategy 1 as "optimistic; usually absent" and explicitly note fall-through behavior. Strategies 2/3 are now called out as the real workhorse; runtime refspec configuration is explicitly forbidden (explicit user opt-in only).

Section 13, `diff-summarizer`, Strategy 1 says:

> Try `git rev-parse refs/pull-requests/<pr_id>/from`. If present, use as head.

I verified on a representative self-hosted Bitbucket Server clone: `refs/pull-requests/*/from` refs **do not exist** by default. Bitbucket Server exposes them, but they're only in the local clone if the user has added a custom refspec (`refs/pull-requests/*/from:refs/remotes/origin/pr/*`) and fetched. Running the command fatal-errors with `unknown revision`.

**Impact:** Strategy 1 will always return "not present" on a fresh clone → silent fall-through to Strategy 2. Not catastrophic but the spec sells this as the primary path, and nobody will understand why it never hits.

**Fix (per Q1):** Demote Strategy 1 to an optimistic first try; emphasise Strategies 2/3 as the real workhorse. Document the rationale in Section 13 so future readers don't re-promote it without adding the required refspec configuration.

---

### C2. Strategy 3 merge-commit grep regex is wrong

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 13 (`diff-summarizer`, Strategy 3)
- **Resolution:** Strategy 3 regex replaced with `git log --all -E --grep="[Pp]ull[ _-]?[Rr]equest[ _-]?#?<pr_id>\b"` (ERE mode). A parenthetical calls out the previous broken pattern so future readers don't re-introduce it. Matches the real `Pull request #<PR_ID>: …` format on both Bitbucket and GitHub merge commits.

Section 13, Strategy 3 says:

> `git log --all --grep="pull[- ]request[- ]<pr_id>" -n 5`

Actual merge commit format observed on two representative self-hosted Bitbucket Server repos used for grounding:

```
Pull request #12345: PROJ-1234 handle update windows...
Pull request #12346: NOISSUE remove empty metadata...
```

The separator is `#`, not `-` or space. The regex `pull[- ]request[- ]<pr_id>` won't match `Pull request #12345` (missing `#` in the pattern, and the `[- ]` between `request` and id is literal hyphen/space only — no `#`).

**Fix:** Replace with `"[Pp]ull.?[Rr]equest.?#?<pr_id>"` or specifically anchor on `"Pull request #<pr_id>:"`.

---

### C3. Path ambiguity in `jira-reader` Section 12

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 12 (`jira-reader`)
- **Resolution:** Steps 2 and 3 rewritten to spell out the full path: `<vault_path>/jira-products/<jira_key>/<LINKED_KEY>/<LINKED_KEY>.md`. Step 3 explicitly warns against the wrong path `<vault_path>/jira-products/<LINKED_KEY>/<LINKED_KEY>.md`. Covers both the VI itself and all linked items.

Step 2 says:

> read `<KEY>/<KEY>.md` for every linked item

Relative to what? The actual layout is:

```
<vault>/jira-products/<ROOT_KEY>/<ITEM_KEY>/<ITEM_KEY>.md
```

Not `<vault>/jira-products/<ITEM_KEY>/<ITEM_KEY>.md`. Every linked item (including the root VI itself) lives as a subdirectory of the root export directory.

If the agent interprets it the wrong way it will hit `NOT_FOUND` on every linked item and return an empty hierarchy.

**Fix:** State explicitly: "read `<vault_path>/jira-products/<root_jira_key>/<linked_key>/<linked_key>.md` for every linked item, including the root VI itself (which also lives in its own subdirectory)."

---

### C4. `marketplace.json` version bump is not a thing

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 3 (new command files / modified files list)
- **Resolution:** Section 3 "Modified files" list rewritten with accurate rationale for each file. A new `### Versioning (introduced by this change)` subsection documents: initial `"1.0.0"` for `dev-workflows` plugin.json + marketplace entry, bumped to `"1.1.0"` by this change (additive, non-breaking), with a note that other plugins are not forced to adopt versioning now but should follow the same convention later.

Section 3 lists:

```
.claude-plugin/
  marketplace.json          ← version bump
```

The current `marketplace.json` has no `version` field, and neither does any `plugin.json`. There's nothing to bump.

**Fix (per Q2):** Introduce versioning as part of this change — add a `version` field to each plugin's `plugin.json` and to the corresponding `plugins[]` entry in `marketplace.json`. Document the initial value (e.g. `"version": "1.0.0"`) and that this change bumps `dev-workflows` accordingly.

---

## Major (design issues)

### M1. `impl.md` alias mechanism is fragile

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 3 (architecture — new command files), 4 (impl:code delegation note)
- **Resolution:** §3 "New command files" block rewritten to directory form (`commands/impl/code.md` etc.); "Namespaced slash commands are loaded via directory convention" rationale added; §3 "`impl.md` alias pattern" subsection fully rewritten to specify verbatim duplication with a `<!-- KEEP IN SYNC WITH commands/impl/code.md -->` marker, explaining why duplication beats runtime delegation.

Section 3:

> Then reads and executes `~/.claude/plugins/data/.../commands/impl:code.md` with `$ARGUMENTS` forwarded.

Two concerns:

1. **Filenames with `:` are forbidden on Windows filesystems.** Repo lives on Git, can be cloned to Windows. `impl:code.md` will fail to check out. Claude Code convention for namespaced commands is usually `commands/<parent>/<child>.md` (directory-based) — i.e. `commands/impl/code.md` mapping to `/impl:code`.
2. **"Reads and executes" is vague** — slash command files aren't directly executable from another command. The alias needs an explicit mechanism.

**Fix (per Q3 + Q3b):**
- Adopt directory form: `commands/impl/code.md`, `commands/impl/docs.md`, `commands/impl/jira/docs.md`, `commands/impl/jira/epics.md`.
- `commands/impl.md` contains the full content of `commands/impl/code.md` duplicated verbatim, prefixed by a short alias notice and a `<!-- KEEP IN SYNC WITH commands/impl/code.md -->` marker. Document the sync obligation in the plugin CHANGELOG and README.

---

### M2. `/impl:code` SIGNIFICANT/HIGH-RISK path: what happens when no test framework is detected?

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 4 (Insertion 2 — SIGNIFICANT/HIGH-RISK)
- **Resolution:** §4 Insertion 2 SIGNIFICANT sub-path now explicitly asks the user `choices: ["Specify test command", "Skip tests", "Cancel"]` **before** invoking Opus review, mirroring the SIMPLE/MODERATE branch. Keeps the Opus-review input deterministic; skip decisions are logged.

Section 4, "SIGNIFICANT/HIGH-RISK" sub-path:

> - **After step 4** (implementation complete), **before step 5** (diff capture):
>   - Invoke `test-writer` agent.
>   - If `Framework: not detected`: note it, include in handoff to Opus.

"Include in handoff to Opus" — OK, but Opus does code review, not test-strategy review. What happens to Phase 3.5 if test-writer returned "not detected"? Is Phase 3.5 skipped? Does the code-review-without-tests still gate the commit? The SIMPLE/MODERATE branch has explicit `choices` for this case but SIGNIFICANT/HIGH-RISK doesn't.

**Fix (per Q4):** Mirror the SIMPLE/MODERATE prompt exactly — ask the user `choices: ["Specify test command to use", "Skip tests for this run (document why in Phase 5 report)", "Cancel"]` **before** invoking Opus review, so the review input is deterministic and the skip decision is visible.

---

### M3. Fix loop for SIMPLE/MODERATE Phase 3.5 is underspecified

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 4 (Insertion 2 — SIMPLE/MODERATE)
- **Resolution:** §4 Insertion 2 SIMPLE/MODERATE step 5 rewritten as a "Fix loop" block: session model applies fixes (no subagent indirection), diff is re-captured each attempt, `test-baseliner` verify runs against the **original** baseline (no mid-loop re-baselining), cap of 2 attempts, then existing choices prompt.

Section 4:

> 4. Invoke `test-baseliner` in verify mode against the captured baseline.
> 5. If regressions or new test failures: fix, re-run verify (max 2 attempts).

Who does the fix? The session model or a subagent? Is it silent ("just fix it") or guided ("here are regressions, invoke the fixer")? For Phase 3B there's an explicit `review-fixer` invocation pattern. Phase 3.5 needs the equivalent.

**Fix:** Specify that the fix loop is performed by the **session model** (no subagent indirection for SIMPLE/MODERATE), using the `test-baseliner` verify report as the authoritative list of regressions. Each fix attempt re-captures a fresh diff and re-runs verify. Cap at 2 attempts, after which the user is prompted with the existing choice set.

---

### M4. Parallel spawn count has no cap

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 6 Phase 5 (`/impl:jira:docs`), 7 Phase 5 (`/impl:jira:epics`)
- **Resolution:** Both Phase 5 blocks rewritten to spawn "in batches of up to 4 concurrent agents, single Agent message per batch, wait for each batch before spawning the next". Rationale (Claude Code ~4–5 parallel limit) inlined. §13 and §14 agent sections also note the concurrency cap.

Both Phase 5 blocks say:

> spawn one `diff-summarizer` instance per repo simultaneously (single Agent message, all in parallel).

Claude Code has practical parallel-subagent limits (typically 4–5). A realistically-sized VI could easily touch 5+ repos.

**Fix (per Q5):** Cap parallelism at **4**. Spawn the first batch of up to 4 instances in a single message; wait for all to complete; then spawn the next batch. Document the cap and the batching pattern.

---

### M5. `doc-reviewer` model not declared

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 9 (`doc-reviewer.md` frontmatter), 8/10/12/13/14 (other new agents)
- **Resolution:** All six new-agent sections (§8 test-writer, §9 doc-reviewer, §10 doc-fixer, §12 jira-reader, §13 diff-summarizer, §14 code-scanner) now carry an explicit `**Model:**` line. §9 `doc-reviewer` declares `opus` with rationale mirroring `code-review`'s gate role. The other five inherit session model with a one-line rationale.

All existing Opus-backed quality gates (`code-review`, `risk-planner`) declare `model: opus` in frontmatter. Section 9 for `doc-reviewer` doesn't.

**Fix (per Q6):**
- `doc-reviewer.md` frontmatter: `model: opus`.
- For the other new agents (`test-writer`, `doc-fixer`, `jira-reader`, `diff-summarizer`, `code-scanner`): explicitly state in each section that they inherit the session model (no `model:` override). State the rationale once in Section 3.

---

### M6. Preload-context hook will miss the new commands

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 3 (modified files), plus new subsection in 4/5/6/7
- **Resolution:** §3 "Modified files" list updated to include `hooks/preload-context.*`. New "Hook scope (`preload-context`)" subsection in §3 specifies per-command injection policy: `/impl` + `/impl:code` = full; `/impl:docs` = none; `/impl:jira:docs` + `/impl:jira:epics` = `$VAULT_PATH` + `<repos_base>` (+ git branch only if cwd is in a git repo). Hook must pattern-match `/impl` and all `/impl:*` variants rather than literal command names.

Current hook injects git context and model-routing reminder for `/impl`, `/vuln`, `/upgrade`. The new `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics` aren't covered. Spec's "Modified files" list in Section 3 doesn't include `hooks/` at all.

**Fix (per Q7):**
- Add `hooks/preload-context.*` to the Section 3 "Modified files" list.
- Update the hook to match:
  - `/impl:code` → full context (git + model routing).
  - `/impl:docs` → no injection (nothing git-relevant; user manages git manually).
  - `/impl:jira:docs`, `/impl:jira:epics` → inject `$VAULT_PATH` + `/repos` base; include git branch context only if cwd is in a git repo.
- Keep `/impl` (the alias) matching the same behaviour as `/impl:code`.

---

### M7. `/repos` base path discovery

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 6 Phase 1 (`/impl:jira:docs`), 7 Phase 1 (`/impl:jira:epics`)
- **Resolution:** Both Phase 1 blocks now include a "Repos base path" grouped question: detect `/repos` (existence-checked), offer `["Use /repos (Recommended)", "Use a different path", "Cancel"]`, free-text follow-up with validation. §6 Phase 4 repo-existence check now uses the resolved `<repos_base>` path; circular "ask at Phase 1" reference removed. Missing-repo escalation rerouted through §15.

Section 6 Phase 1 clarification list doesn't include asking about `<repos_base>`. Phase 4 says "ask at Phase 1 if different path needed" — circular. User should be shown the detected default (`/repos`) at Phase 1 and offered to override.

**Fix:** Add a Phase 1 clarification in both Jira commands: detect `/repos` as default (check existence); ask the user `choices: ["Use /repos (Recommended)", "Use a different path", "Cancel"]`. If "different path", follow up with a free-text entry. Remove the circular Phase 4 reference.

---

### M8. `jira-reader` themes extraction for `depth: vi-only`

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 12 (`jira-reader`), 7 Phase 3 (`/impl:jira:epics`)
- **Resolution:** §12 input enum now `full | vi-plus-epics | vi-only`. New step 3 defines `vi-plus-epics`: reads the index + VI's own `.md` + every Epic `.md` directly linked to the VI; Stories/Sub-tasks/Research/RFA skipped. Step 5 (themes) notes that `vi-only` themes may be sparse and directs Epic-writing flows to use `vi-plus-epics`. §7 Phase 3 now calls `jira-reader` with `depth: vi-plus-epics`.

Section 12 step 4 says "Extract capability themes" unconditionally. But for `depth: vi-only`, only the VI's own `.md` is read — themes come from a single description. For `/impl:jira:epics` this may produce weak themes that starve `code-scanner`.

**Fix (per Q8):** Introduce a new depth level `vi-plus-epics` in `jira-reader`:
- `depth: vi-plus-epics` reads the index + VI's own `.md` + every Epic `.md` linked to the VI (Stories/Sub-tasks/Research/RFA excluded).
- Themes are then extracted across VI + Epic descriptions, giving `code-scanner` a richer seed.
- Update Section 7 Phase 3 to use `depth: vi-plus-epics` instead of `vi-only`.

---

### M9. "Ask per unresolved BLOCKER" is hand-wavy

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 15 (escalation rules)
- **Resolution:** §15 "doc-reviewer BLOCK after one fix cycle" row rewritten with concrete per-BLOCKER choices: `["Provide manual fix notes", "Defer to a follow-up issue", "Override and accept the finding", "Cancel the whole run"]`. Each option's effect is stated: Cancel aborts; Override records override+rationale; Defer records without override flag; Manual fix notes triggers a bounded one-shot `doc-fixer` pass on the user-supplied fix text.

Section 15:

> `doc-reviewer` BLOCK after one fix cycle: Ask per unresolved BLOCKER with direct fix question + "Defer", "Override"

If 5 BLOCKERs remain, that's 5 serial prompts.

**Fix:** Present each unresolved BLOCKER individually with a concrete `choices` set: `["Provide manual fix notes", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]`. State that "Cancel" aborts the run; "Override" records the override with rationale; "Defer" records the finding in the Phase 9 `### Deferred items` section.

---

## Minor

### m1. Bitbucket project vs repo name

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 6 Phase 4, 13 ("URL parse note" under Resolver selection)
- **Resolution:** §13 now has an explicit "URL parse note" paragraph: for Bitbucket URLs the `<PROJECT_KEY>` prefix is for server namespacing only and plays no role in the local-lookup path `<repos_base>/<REPO_NAME>`. §6 Phase 4 URL extraction step likewise extracts only `<REPO>`.

PR URL pattern `projects/<PROJECT>/repos/<REPO>/pull-requests/<PR_ID>` — spec correctly extracts `<REPO>`. Worth spelling out that the `<PROJECT>` prefix (`RX`, `sus`, etc.) is irrelevant for local repo lookup; only `<REPO>` matters.

**Fix:** Add a note next to the URL-parse instruction: "The `<PROJECT>` component identifies the Bitbucket project namespace and is not used for local repo lookup — only `<REPO>` maps to `<repos_base>/<REPO>`."

---

### m2. `-comments.md` and `attachments/` siblings ignored

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 12 (`jira-reader`)
- **Resolution:** §12 now has an explicit "Ignored by default" paragraph stating that sibling `<KEY>-comments.md` files and `attachments/` sub-directories are skipped, with rationale (noisy, rarely authoritative, easy to revisit manually) and an explicit "no user-facing toggle in this iteration" statement.

Each item directory contains `<KEY>-comments.md` and often `attachments/`. Spec says nothing.

**Fix (per Q9):** State explicitly in Section 12 that `jira-reader` ignores `<KEY>-comments.md` and `attachments/` sub-directories by default, with no user-facing toggle. Rationale: keeps the agent fast and focused; comments occasionally have useful history but are noisy and easy to revisit manually.

---

### m3. `diff-summarizer` output field: `repo` is a name or a path?

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 13 (`diff-summarizer`)
- **Resolution:** §13 output block now documents `repo: <short repo name — the basename of repo_path>` and adds a new `repo_path: <absolute path as received in input>` field so callers can reference the source tree. §14 `code-scanner` output updated symmetrically.

Input is `repo_path` (absolute); output is `repo: <repo name>`. Fine, but readers may expect symmetry.

**Fix:** Clarify in Section 13 output that `repo` is the short repository name (the basename of `repo_path`), not the absolute path. Consider adding a `repo_path` field to the output too if callers need to reference the source tree.

---

### m4. `refresh.pull` asymmetry between diff-summarizer (false) and code-scanner (true)

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 13 (`diff-summarizer`), 14 (`code-scanner`)
- **Resolution:** Both agent `refresh:` YAML blocks now carry an inline comment explaining the asymmetry: `diff-summarizer.pull: false` because diffs target historical merged commits (pulling risks moving HEAD away from the merge target); `code-scanner.pull: true` because capability scans target present-day default-branch code.

**Fix:** Add a one-line rationale in Section 13 and Section 14: "diff summaries target historical merged PRs and need no current-branch state → `pull: false`; capability scans target present-day code and want the default-branch tip → `pull: true`."

---

### m5. Grouped vs one-per-message questions

- **Status:** Fixed (2026-05-08 — resolved as part of wave 2 M7)
- **Spec section(s):** 6 Phase 1 (`/impl:jira:docs`), 7 Phase 1 (`/impl:jira:epics`)
- **Resolution:** Both Phase 1 blocks were rewritten in wave 2 (M7) from "one question per message" to "grouped where possible, `choices` arrays, last choice always `\"Other… (describe)\"`", matching the `impl.md` style.

Section 6 Phase 1 says "one question per message" but `impl.md` style says "Group related decisions into a single question where possible".

**Fix:** Update Sections 6 and 7 to match `impl.md` grouping style. Keep `choices` arrays with `"Other… (describe)"` as the last entry.

---

### m6. Output-file-exists default missing

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 15 (escalation rules)
- **Resolution:** §15 "Output file already exists" row reordered with `"Write with -v2 suffix (Recommended — non-destructive)"` as the first choice.

Section 15: "Overwrite / Append / Write with -v2 suffix / Cancel" — no `(Recommended)` marker.

**Fix:** Mark `"Write with -v2 suffix"` as `(Recommended)` (non-destructive default).

---

### m7. Index column-format brittleness

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 12 (`jira-reader`)
- **Resolution:** §12 step 1 now requires header-row validation: the first data table's header row must equal `| Key | Type | Status | Summary | Role |` exactly. On mismatch, return `status: EMPTY` with a message naming the mismatched columns — never parse rows with an unknown schema. Documented the assumed exporter version dependency.

`jira-reader` parses exactly `| Key | Type | Status | Summary | Role |`. If the Jira-to-Obsidian exporter changes the column layout, parser breaks silently.

**Fix:** Add a header-validation step: before parsing rows, verify the table's header row contains exactly `Key | Type | Status | Summary | Role`. If not, return `status: EMPTY` with a clear error message naming the mismatch. Document the assumed exporter version.

---

### m8. `impl-maintenance` agent scope

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 3 (modified files + new "`impl-maintenance` update" subsection)
- **Resolution:** §3 "Modified files" now includes `agents/impl-maintenance.md`. New `### impl-maintenance update` subsection states: session-handoff must include `Command run: /impl:code | /impl:docs | /impl:jira:docs | /impl:jira:epics`; the agent's Inputs and "Command workflow improvements" sections must be updated to recognise all command variants.

Existing `impl-maintenance` refers to commands `/impl | /vuln | /upgrade`. After the split, sessions from `/impl:code`, `/impl:docs`, etc. will run it. The "Command workflow improvements" section will reference the wrong command unless the specific command name is passed in the handoff.

**Fix:** Update the session-handoff block used by Phase 4 (code) and Phase 8 (jira) to include `Command run: /impl:code | /impl:docs | /impl:jira:docs | /impl:jira:epics`. Update `impl-maintenance.md`'s "Command workflow improvements" section to list all command variants.

---

### m9. DECLINED / OPEN PRs for `diff-summarizer`

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 13 (`diff-summarizer`)
- **Resolution:** §13 now has a "Note on non-MERGED PRs" paragraph: for OPEN/DECLINED/UNKNOWN PRs, expect a high unresolved rate (DECLINED PRs often have no merge commit → Strategy 3 fails; feature branches may be deleted after decline → Strategy 2 fails). `aggregate_summary` is directed to call out the unresolved count so doc writers know what's missing.

Default filter is MERGED-only (good). But if user picks "all PRs", a DECLINED PR may have no merge commit (Strategy 3 fails) and may not have an extant branch (Strategy 2 fails).

**Fix:** Add a note in Section 13: "For non-MERGED PRs (OPEN, DECLINED, UNKNOWN), expect a high rate of `unresolved` — the corresponding branches or merge commits may no longer exist locally. Surface unresolved counts clearly in the aggregate output."

---

### m10. `git stash` from Pre-Phase 3 not addressed for docs commands

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 6 Phase 6.5 (`/impl:jira:docs`), 7 Phase 6.5 (`/impl:jira:epics`)
- **Resolution:** §6 Phase 6.5 now explicitly spells out the clean-tree check: `git status --porcelain`, with the same `["Stash (Recommended)", "Proceed anyway", "Cancel"]` choices as `commands/impl/code.md` Pre-Phase 3. §7 Phase 6.5 shortened to "Same as `/impl:jira:docs` Phase 6.5 — including the pre-branch clean-tree check and the `docs/` branch prefix" so it's self-contained.

Section 11 says "reuse the clean-tree check … from `impl:code.md` Pre-Phase 3" — good, but it's only mentioned once.

**Fix:** Explicitly state at the top of Phase 6.5 in both Jira commands: "Before creating the branch, run the clean-tree check from `impl:code.md` Pre-Phase 3. If the tree is dirty, surface the same `Stash / Proceed / Cancel` choices."

---

## Nits

### n1. Section 4 phrasing

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 4
- **Resolution:** Opening sentence now reads "All existing phases from the current `impl.md` (which becomes `commands/impl/code.md` under the new directory layout — see §3) are preserved."

Section 4 says "All existing phases from `impl.md` are preserved" — should read "from the existing `impl.md`, which becomes `impl/code.md`" to avoid confusion (given the directory-form decision in Q3).

---

### n2. `doc-reviewer` product-docs actionability

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 9 (`doc-reviewer` table)
- **Resolution:** Product-docs Actionability cell replaced: `"Examples runnable; commands copyable verbatim; links resolve"`.

Section 9 table row for `product-docs` "Actionability: N/A" — product docs have actionability too (working examples, copyable commands).

**Fix:** Update the cell to `"Examples runnable, commands copyable, links resolve"` or similar.

---

### n3. Plugin loader support for namespaced filenames

- **Status:** Fixed (2026-05-08 — resolved as part of wave 2 M1)
- **Spec section(s):** 3
- **Resolution:** M1's fix adopted the directory-form command layout (`commands/impl/code.md` etc.) and added the sentence "Namespaced slash commands are loaded via directory convention (`commands/<parent>/<child>.md` → `/<parent>:<child>`). This avoids `:` in filenames, which is forbidden on Windows filesystems" directly in §3. Nothing further needed.

Q3 resolved to directory form (`commands/impl/code.md`), so the `:` in filenames is no longer a concern. This nit becomes a note: "namespaced commands are loaded via directory convention; avoid `:` in filenames."

---

### n4. `code-scanner` missing PARTIAL status

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 14 (`code-scanner`)
- **Resolution:** §14 output enum now `OK | PARTIAL | REPO_MISSING | DIRTY_TREE | REFRESH_BLOCKED | EMPTY`. New paragraph defines PARTIAL ("some themes completed successfully but at least one failed") and specifies per-theme `classification: error` with a one-line reason, mirroring `diff-summarizer`'s PARTIAL semantics for a consistent caller recovery pattern.

`code-scanner` output: `status: OK | REPO_MISSING | DIRTY_TREE | REFRESH_BLOCKED | EMPTY` — missing `PARTIAL` which `diff-summarizer` has.

**Fix:** Add `PARTIAL` to the status enum in Section 14, defined as "some themes scanned, some failed (e.g. permission error, file not readable)". Include how to communicate per-theme failures in the output.

---

### n5. Bitbucket host hardcoding

- **Status:** Fixed (2026-05-08) — subsequently generalised further in A1 below (this initial fix kept a single-host assumption; A1 removed all internal-hostname leakage).
- **Spec section(s):** 12 (`jira-reader` URL formats), 13 (`diff-summarizer` resolver selection), 17 (out of scope + prerequisites)
- **Resolution:** §12 now documents two recognised URL formats (Bitbucket + GitHub) with an explicit assumption about the (then-unspecified) self-hosted Bitbucket Server host. §13 has a new "Resolver selection by host" table routing per-PR to Bitbucket local-git or GitHub `gh`-CLI paths; a new "GitHub resolver (via `gh` CLI)" subsection spells out the `gh pr view --json` → `git fetch` → `git diff` flow. §17 drops the old "Handling non-Bitbucket PR URL formats (deferred)" line, replaced with a narrower statement about non-target Bitbucket Server hosts and non-GitHub Git hosts. New "Environment prerequisites" subsection documents `gh auth login` and recommends the ihudak/ai-containers environment.

PR URL hostname was hardcoded to a single self-hosted Bitbucket Server instance. Section 17 deferred non-Bitbucket formats, but this needed to be an explicit assumption.

**Fix:** Add an explicit assumption in Section 12/13 that PR URL resolution is tuned for a specific Bitbucket Server instance and `github.com` (per Q10); other hosts return `unresolved`. Update Section 17 to match. *(Superseded by A1 — see below — which removed all internal hostnames in favour of host-category detection.)*

---

### n6. Jira-key directory-name validation

- **Status:** Fixed (2026-05-08)
- **Spec section(s):** 12 (`jira-reader`)
- **Resolution:** §12 Process now opens with "Phase 0 — Validate `jira_key`": accept only `^[A-Z][A-Z0-9_]*-\d+$`, return `status: NOT_FOUND` on mismatch. Caller surfaces §15's existing `Jira key dir not found` choices (`"Re-enter key"`, `"Cancel"`) to the user.

No mention of how to handle `<KEY>` values that are not valid directory names (unlikely with Jira keys but worth a belt-and-braces validator).

**Fix:** Add a validation step in `jira-reader` Phase 0: `<JIRA_KEY>` must match `^[A-Z][A-Z0-9_]*-\d+$`. On mismatch, escalate with `choices: ["Re-enter key", "Cancel"]`.

---

## Post-review amendments

### A1. Remove internal-Bitbucket-Server host references; generalise to host categories

- **Status:** Fixed (2026-05-08)
- **Raised by:** User, after wave 3 review — open-source plugin must not embed internal hostnames.
- **Spec section(s):** 6 Phase 4, 6 Invariants, 12 (URL formats + output schema), 13 (inputs + Resolver selection + local-git strategies + GitHub resolver), 17 (out-of-scope + prerequisites)
- **Decisions:** Q11 (fallback = local-git), Q12' (defer Bitbucket Cloud CLI), Q13 (hostname contains `bitbucket` AND is not `bitbucket.org`).
- **Resolution:** All hardcoded references to a single internal Bitbucket Server hostname (7 occurrences) were removed from the design spec. Introduced a three-category host classification — `github_cloud`, `bitbucket_cloud`, `bitbucket_server` (opaque hostname match). Resolver selection now follows the unified rule "if cloud AND CLI available → use CLI; else → local-git fallback". GitHub continues to use `gh`; Bitbucket Cloud has no CLI adopted this iteration (verified against Atlassian ACLI v1.3.15 — `acli` does not yet cover Bitbucket), so Bitbucket Cloud falls back to local-git strategies alongside self-hosted Bitbucket Server. §17 documents the deferral and leaves a clean extension point for a future Bitbucket CLI. The §6 invariant and §17 out-of-scope list both rephrased to drop any specific Bitbucket domain.

---

## Wave 5 — Ivan's feedback round (2026-05-10)

**Source:** `$VAULT_PATH/Projects/AI-First/AI Containers/Prompts/20260510 Claude impl-split Ivan feedback.md`

**Status:** Applied (2026-05-10). Spec updated across §§2, 3, 6, 7, 9, 9b, 10, 10a, 10b, 10c, 11, 13, 15, 17.

### Decisions resolved (wave 5)

| # | Question | Choice |
|---|---|---|
| Q14 | `/impl:jira:docs` docs-repo requirement | Heuristic detection (package.json scripts, `.docstack/`, `mkdocs.yml`, `docusaurus.config.js`, `antora.yml`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, `_snippets/`); if 0 signals, confirm with user (default = Cancel). Not a hard quit. |
| Q15 | Fetch main + read CONTRIBUTION for branch name | Yes. Phase 6.5 updated: `git fetch origin` → `git switch <base> && git pull --ff-only`, then grep `CONTRIBUTING.md` / `CONTRIBUTION.md` / `README.md` / `DOCUMENTATION-GUIDELINES.md` for naming convention; fall back to `docs/<jira-key>-<slug>`; always confirm. |
| Q16 | `doc-location-finder` subagent | Add. Name `doc-location-finder` (clearer than "placeholder finder"). §10a defines it — heuristic + grep, session model. |
| Q17 | `doc-planner` subagent | Add. §10b. Synthesises Jira + diffs + confirmed locations into a checklist (topics × locations × frontmatter × snippets × screenshots × cross-links). Invoked after `doc-location-finder` in new Phase 5.7. |
| Q18 | Split `doc-reviewer` into `doc-reviewer` + `epic-reviewer` | Yes. Both Opus. §9 rewritten product-docs-only; §9b added for Epic-specific dimensions (acceptance-criteria testability, non-duplication with existing Epics). |
| Q19 | Split `doc-fixer` | **No.** Finding schema is identical across reviewers; fixer stays single and shared. §10 updated to explicitly note shared use. |
| Q20 | YAML frontmatter (`changelog:`) handling | Mandatory. Phase 6 preserves existing frontmatter on extended pages; adds/updates `changelog:` per `doc-planner` instructions; updates other fields the planner flags. Reviewer checks. |
| Q21 | Screenshot prompt | Phase 1 asks; user may provide any absolute path (not vault-only). Phase 6 copies screenshots into the docs repo's idiomatic image location adjacent to the target page. |
| Q22 | `/impl:jira:epics` vault-only | Yes. Phase 0 refuses to run outside `$VAULT_PATH`. §11 rewritten as a two-policy section. |
| Q23 | `/impl:jira:epics` output directory | `$VAULT_PATH/jira-drafts/<VI-KEY>/<slug>.md` (sibling to `jira-products/`, not inside it — `jira-products/` is re-created on every import, so writes there would be lost). Option (b) from the proposal; option (a) "carve out jira-products/ writes" was rejected because it would conflict with the import model. |
| Q24 | `/impl:jira:epics` branching | Never. Phase 6.5 deleted entirely from §7. |
| Q25 | `docs-style-checker` mechanism | **Wrap Vale / project lint**, not a style-guide URL crawler. §10c detects `.vale.ini` → runs `vale --output=JSON`; else tries `yarn *:lint`, else `markdownlint`/`remark`; else reports `NOT_CONFIGURED`. §17 out-of-scope now explicitly excludes URL crawling of the style guide. |
| Q26 | `doc-branch-creator` as a subagent | **No.** Inline step in `/impl:jira:docs` Phase 6.5 (~30 lines of logic). Promote later if scope grows. |
| Q27 | Strategy 4 — Jira-key commit grep | Broaden. Accept full VI hierarchy (`jira_keys_hierarchy` input); grep each key across all commits; emit per-commit entries with `resolved_via: jira_key_commits` and a summary note that the diff may not match the original PR exactly. Existing `resolved_via: issue_grep` enum value renamed to `jira_key_commits`. |
| Q28 | Aggregate unresolved-PRs gate | Add. §15 now has a separate row for "All PRs across all repos unresolved" → single aggregate prompt `["Proceed with Jira-only content (Recommended)", "Review candidates one by one", "Cancel"]`. |
| Q29 | Role clarification between the two Jira commands | Add a 1-sentence note in §2 distinguishing tech-writer role (`/impl:jira:docs`) from PM/PO role (`/impl:jira:epics`). |

### Grounding (verified on 2026-05-10 against a representative product docs repo)

Before applying the changes, the proposed design signals were verified against a real Docusaurus/Nx-style product docs repository to make sure the heuristics would actually fire:

- **yarn + nx build** — `package.json` contains product-flavoured scripts matching `*:build`, `*:lint`, `*:start`, plus a `setup` script that wires yarn workspaces and nx. Confirms the docs-repo detection signal set.
- **Vale config present** — `.vale.ini` with `BasedOnStyles = <ProjectStyle>, Microsoft`; `.vale/styles/` directory exists. Confirms Q25 choice to wrap Vale rather than re-crawl the style guide.
- **Snippets convention** — `<product>/_snippets/`, `<variant>/_snippets/`, `.docstack/sources/*/_snippets/` directories exist. Confirms the `doc-planner` snippets-reuse output shape.
- **YAML frontmatter with `changelog:`** — verified on a representative page; typical frontmatter fields are `postid`, `legacyids`, `title`, `description`, `published`, `meta`, `changelog`, `readtime`, `tags`, `owners`, `userintention`, `order`. Confirms Q20's frontmatter handling scope.
- **CONTRIBUTION.md branch-name guidance** — confirmed that the repo documents explicit patterns like `<initials>/<JIRA-KEY>-<short-slug>` and a no-issue variant. Confirms Q15's read-CONTRIBUTION approach.
- **DOCUMENTATION-GUIDELINES.md** — present as an additional in-repo style source; `docs-style-checker` can use it as a signal for docs-repo detection.
- **Vault path layout** — `$VAULT_PATH` has `.obsidian/` at the root and `jira-products/` containing one VI sub-directory plus an `export-index.md`. Confirms `/impl:jira:epics` vault-only enforcement is feasible.

### Amendments applied to the spec

| Section | Change |
|---|---|
| §2 | Added 1-sentence role clarification (Q29) |
| §3 | Agent listing grew from 6 agents to 10 (4 new in this wave): existing `test-writer`, `doc-reviewer`, `doc-fixer`, `jira-reader`, `diff-summarizer`, `code-scanner`; new `epic-reviewer`, `doc-planner`, `doc-location-finder`, `docs-style-checker` |
| §6 | Phase 0 gained docs-repo detection (Q14); Phase 1 gained screenshot prompt (Q21); new Phase 5.5 invokes `doc-location-finder` (Q16); new Phase 5.7 invokes `doc-planner` (Q17); Phase 6 rewritten with frontmatter/snippet/screenshot handling (Q20, Q21); Phase 6.5 enhanced with fetch-main + CONTRIBUTION parsing (Q15); new Phase 6.7 invokes `docs-style-checker` (Q25); Phase 7 product-docs-specific (Q18); invariants updated |
| §7 | Phase 0 vault-required (Q22); Phase 1 default output `jira-drafts/<VI-KEY>/<slug>.md` with rationale (Q23); Phase 6.5 deleted (Q24); Phase 7 uses `epic-reviewer` (Q18); invariants rewritten |
| §9 | Rewritten as product-docs-only reviewer (Q18) |
| §9b | New agent: `epic-reviewer` Opus, Epic-specific dimensions (Q18) |
| §10 | `doc-fixer` clarified as shared across workflows (Q19) |
| §10a | New agent: `doc-location-finder` (Q16) |
| §10b | New agent: `doc-planner` (Q17) |
| §10c | New agent: `docs-style-checker` (Q25) |
| §11 | Rewritten as two-policy section: `/impl:jira:epics` vault-only no-branch (Q22, Q24); `/impl:jira:docs` uses docs-repo detection (Q14) |
| §13 | Strategy 4 broadened to cross-hierarchy Jira-key grep (Q27); `resolved_via` enum: `issue_grep` → `jira_key_commits`; `jira_keys_hierarchy` input added |
| §15 | Aggregate all-PRs-unresolved row added (Q28) |
| §17 | Out-of-scope excludes style-guide URL crawling (Q25), running `/impl:jira:docs` outside docs repo (Q14), running `/impl:jira:epics` outside vault (Q22). Prerequisites note `vale` as optional/recommended |

### Open items for implementation time (not blocking)

- `doc-planner` output schema includes `frontmatter_updates.other`; the exact fields to check are best read from 2–3 adjacent pages at invocation time (per the §10b process step "detect existing conventions by sampling 2–3 adjacent pages"). No hardcoded field list in the spec — intentionally.
- `docs-style-checker` fallback chain (vale → yarn:lint → markdownlint/remark) may need extension if other docs-repo conventions surface during implementation. The spec's priority order is additive-safe.
- `doc-location-finder` scoring is heuristic; if the initial implementation consistently returns low confidence, consider a small embedding-based match as a follow-up — not in this iteration.

---

## What works well

For completeness — these are strong points worth preserving:

- Clean separation of concerns across the five commands; motivation in Section 2 is convincing.
- The Obsidian vault / git-repo / plain-dir detection in Section 11 is pragmatic and correct (confirmed `$VAULT_PATH` has `.obsidian/`, so the walk-up logic works there).
- Read-only constraints on `jira-products/` and `_archive/` prevent accidental corruption of the export artifacts.
- Reuse of existing `test-baseliner` and Phase 4 maintenance agents across commands is good design hygiene.
- Escalation table (Section 15) covers the realistic failure modes.
- Parallel `diff-summarizer` / `code-scanner` design maps well to the real data (the test VI we used for grounding spans 2+ repos).


---

## Wave 6 — Fresh-context self-audit (2026-05-10)

**Source:** a fresh-context reviewer subagent pointed at the spec, asked to re-audit it end-to-end with the tracker as optional supporting context.

**Status:** Applied (2026-05-10). Spec updated across §§4, 5, 6, 7, 14, 15.

**Audit summary:** 14 findings (0 blocker, 3 major, 7 minor, 4 nit). Verdict: NEEDS FIXES — the spec was implementable, but three agent status-handling gaps and seven schema / cross-reference fidelity issues would have surfaced as ambiguities mid-implementation. All 14 applied.

### MAJOR — agent status handling gaps

| # | Fix |
|---|---|
| W6-M1 | §15 BLOCK-escalation row generalised from `doc-reviewer` to `doc-reviewer` OR `epic-reviewer`; added note that "Defer" means an Epic-refinement note in the draft when the workflow is `/impl:jira:epics`. |
| W6-M2 | §6 Phase 5.7 now specifies what happens for `doc-planner` `PARTIAL` status and for each `recommended_action` gap value: `"ask user"` → inline prompt + single re-invocation; `"mark TODO in draft"` → writer emits `<!-- TODO: ... -->` marker; `"skip with note"` → carried into Phase 9 report. |
| W6-M3 | §6 Phase 5.5 now handles `doc-location-finder` `EMPTY` (prompts for manual path entry) and `LOW_CONFIDENCE` (displays `confidence_notes`; flips default choice from "Accept all" to "Adjust individual"). |

### MINOR — schema and cross-reference fidelity

| # | Fix |
|---|---|
| W6-m1 | §6 Phase 4: `status_marker` → `status` (matches the `jira-reader` output schema's `pull_requests[].status` field; disambiguates from top-level agent `status`). |
| W6-m2 | §5 `/impl:docs`: Phase 4 handoff now sets `change_type: docs` (was the only command missing it; aligns with `/impl:jira:docs` and `/impl:jira:epics`). |
| W6-m3 | §15: added `DIRTY_TREE` row; clarified `REFRESH_BLOCKED` mapping to both `diff-summarizer` and `code-scanner`. |
| W6-m4 | §6 Phase 5: "Section 13 escalation rules" → "Section 15" (rules live in §15, not §13). |
| W6-m5 | §14 `code-scanner`: explicitly emits `REFRESH_BLOCKED` on `git pull --ff-only` failure (was in the output status enum but not produced by any process step). |
| W6-m6 | §7 Phase 7: explicit note that there is **no** `docs-style-checker` step for Epics (prevents implementers from copy-pasting the docs flow). |
| W6-m7 | §6 Phase 5.7: added `repo_root` to the `doc-planner` invocation inputs (required by the agent's schema in §10b but not passed by the caller). |

### NIT — polish

| # | Fix |
|---|---|
| W6-n1 | §7 Phase 0: "Change to `<VAULT_PATH>` and retry (Recommended)" → "Cancel and re-run after `cd <VAULT_PATH>`" (both original choices cancelled; removed contradictory "Recommended" + "Default = Cancel"). |
| W6-n2 | §6 Phase 6 Jira-key example: `[[JIRA-1127]]` → `[[<JIRA_KEY>]]` (the last internal-looking identifier; the prior sanitisation sweep missed it). |
| W6-n3 | §4: "Phase 5 report" → "the final report — Phase 5 of the inherited /impl:code workflow" (clarifies the cross-reference to inherited behaviour). |
| W6-n4 | Tracker arithmetic: "6 to 9 new agents" → "6 to 10 (4 new)" with all 10 named (existing 6: `test-writer`, `doc-reviewer`, `doc-fixer`, `jira-reader`, `diff-summarizer`, `code-scanner`; new 4: `epic-reviewer`, `doc-planner`, `doc-location-finder`, `docs-style-checker`). |

**Final state after Wave 6:** 0 BLOCKERs, 0 MAJORs, 0 MINORs, 0 NITs from the audit. 0 internal identifiers, 0 repo-specific paths, 0 internal Jira keys leaking. Status-to-escalation coverage: every non-OK status emitted by any agent is handled either at the caller (Phase 5.5 / 5.7 / etc.) or in §15.

---

## Wave 7 — Reality-grounded review (2026-05-10)

**Source:** a manual reality-grounded review (session model) cross-checking every agent input/output and each phase of every command against the actual artifacts the plugin will touch: `plugins/dev-workflows/` source, a representative product-docs repo under `/repos/`, a real code repo under `/repos/` referenced by a real PR in the vault, and a real Jira export under `$VAULT_PATH/jira-products/<VI_KEY>/`.

**Motivation:** Waves 1–6 were all spec-internal consistency audits. They caught many things but never verified the spec against the systems it describes. Wave 7 is the first reality-ground.

**Status:** Applied (2026-05-10). Spec updated across §§3, 4, 6, 8, 11, 12, 13, 14, 16, 17.

### Grounding (what was checked)

- **Plugin source**: existing `commands/impl.md`, `hooks/preload-context.sh`, and 5 existing agents read end-to-end. Opus agents (`risk-planner`, `code-review`) confirmed to use `model: opus` in frontmatter **and** receive `model: "opus"` on the Agent call — the belt-and-braces routing the spec relies on.
- **jira-products export**: the real per-VI index (`<VI_KEY>-index.md`) has the 5-column `| Key | Type | Status | Summary | Role |` header the spec assumes. Role enum matches (`root`, `linked`, `epic_child`). Type enum covers all cases (`ValueIncrement`, `Epic`, `Story`, `Research`, `Request for Assistance`). VI's own file at the nested `<VI>/<VI>/<VI>.md` path matches the spec. One export uses capitalised `Attachments/` instead of lowercase `attachments/` — spec updated.
- **PR URL / branch / status markers**: a real self-hosted-Bitbucket PR URL of shape `https://<bitbucket-server-host>/projects/<PROJECT>/repos/<repo>/pull-requests/<PR_ID>` parses correctly under the §13 pattern. Status markers `**MERGED**` / `**DECLINED**` confirmed. Branch line format uses backticks around names and a Unicode `→` arrow (not `->` ASCII) — was previously undocumented.
- **docs-repo signals**: a representative product-docs repo under `/repos/` hits 3 of the 6 listed signals (`.docstack/`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, plus `_snippets/` under product directories). Detection works.
- **Vale config**: the real `.vale.ini` uses `BasedOnStyles = <ProjectStyle>, Microsoft` — confirms §10c's rationale that wrapping the repo's existing tooling is the only correct path (the project style is local to `.vale/styles/`, not in a public package).
- **Branch-naming convention**: the real `CONTRIBUTION.md` documents `<your-name-or-initials>/<JIRA-ISSUE-KEY>-<short-branch-name>` — the §6 Phase 6.5 grep-for-section heuristic will find it.
- **Strategy 3 regex**: a real merge commit of shape `Pull request #<PR_ID>: <JIRA_KEY> <feature summary>` matches the spec's `[Pp]ull[ _-]?[Rr]equest[ _-]?#?<pr_id>\b` regex ✓.
- **Strategy 2 ambiguity**: `git branch -a --list "*<JIRA_KEY>*"` in the real code repo returns **two** matching branches (feature branch + earlier revision) — triggering the previously undefined "ambiguous match" case.
- **Default branch**: the real code repo has `git symbolic-ref refs/remotes/origin/HEAD → refs/remotes/origin/master`, not `main`.
- **Image convention**: the real product-docs repo has **zero** `.png` / `.jpg` / `.gif` files under the product content tree. Every image reference uses external CDN URLs. The `CONTRIBUTION.md` explicitly instructs "uploaded to the Image Manager" for new images. **This is a major mismatch with the spec's copy-to-page-local-img-dir assumption.**

### Findings and fixes

#### BLOCKER

| # | Finding | Fix applied |
|---|---|---|
| W7-B1 | §6 Phase 6 screenshot placement assumed every docs repo has local `img/` or `images/` directories; the reality-ground repo uses external CDN / Image Manager uploads with zero local image files, so the writer would either silently fail or invent a non-idiomatic directory. | `doc-planner` (§10b) now detects `image_policy: local | cdn_upload_required | ambiguous` by sampling sibling / ancestor markdown pages. Output schema adds per-screenshot `staging` path (for CDN-upload repos — staged under `/tmp/<JIRA_KEY>-screenshots/`, **never** copied into the repo), `upload_note`, and policy-dependent `dest`. §6 Phase 6 "Place screenshots" rewritten with three branches (local copy / stage + TODO placeholder / ask user). §6 Phase 1 screenshot prompt text updated to reflect the new flow. §6 Phase 9 adds `### Screenshots to upload manually` section populated only when staging occurs. §9 `doc-reviewer` review dimension for screenshots updated to check both policies. |

#### MAJOR

| # | Finding | Fix applied |
|---|---|---|
| W7-M1 | §6 Phase 6.5 step 1 hardcoded "default `main`" and §14 Process step 2 used `<default-branch>` without specifying resolution — both incorrect for master-default legacy repos (the real code repo used for grounding is one). | Both steps rewritten to resolve the default via `git symbolic-ref --short refs/remotes/origin/HEAD`, with a fallback chain (run `git remote set-head origin --auto`; then try `main`, then `master`). §14 explicitly emits `REFRESH_BLOCKED` with reason `cannot resolve default branch` if the fallback chain exhausts. |
| W7-M2 | §3 "Hook scope" said "pattern-match against `/impl` and all `/impl:*` variants" but the existing `preload-context.sh` regex `^/(impl\|vuln\|upgrade)[[:space:]]+` literally does not match `/impl:code foo` (the `:` is not whitespace). No corrected regex was given, so implementers would have to invent one. | Added a **Normative regex** block to §3 specifying the replacement: `^/(impl(:(code\|docs\|jira(:(docs\|epics))?))?\|vuln\|upgrade)[[:space:]]+[^[:space:]-]` with the longest-match alternation explicit so `/impl:jira:docs` binds before `/impl`. |
| W7-M3 | §11 detection sketch produced `context ∈ {obsidian, git_repo, plain_dir}` — three branches — but the §11 context table above had **four** rows (obsidian, docs git repo, non-docs git repo, not in git repo). Implementers following the sketch literally would never trigger the "non-docs git repo → confirm with user" path. | Sketch extended to run the §6 Phase 0 signal check inside the `git_repo` branch and produce `docs_repo` or `non_docs_repo`. Added a sentence mapping the four states to the four table rows. Two stale references elsewhere in the spec (§6 Phase 1 clarification, §6 Phase 6.5 trigger condition) updated to the new 4-state vocabulary. |
| W7-M4 | §12 documented URL parsing and status-marker values but never showed the actual `## Pull Requests` section markdown structure it needs to parse — a 2-line bulleted item per PR, with backticked branch names and a Unicode `→` arrow (not ASCII `->`). A naive regex would capture backticks and miss the arrow. | Added a dedicated "`## Pull Requests` section markdown format" block under §12 with the exact shape, an explicit regex (`` ^\s*-\s+Branch:\s+`([^`]+)`\s+→\s+`([^`]+)` ``), and the rules for missing status markers and empty sections. |
| W7-M5 | §13 Strategy 2 only defined "if unique match → use as head" — didn't say what happens for 0 matches (branch deleted after merge — common) or 2+ matches (multiple feature-branch revisions — also common; verified on real data). | Strategy 2 now spells out that 0 or 2+ matches fall through silently to Strategy 3; no user prompt at this level; any remaining unresolved PRs are aggregated and surfaced once via §15's "All PRs unresolved" row. |

#### MINOR

| # | Finding | Fix applied |
|---|---|---|
| W7-m1 | §3 Modified files listed `preload-context.*` with a wildcard; only `preload-context.sh` exists, so the wildcard was confusing. | Replaced with `preload-context.sh`. |
| W7-m2 | §16 Success criterion 1 required a passing test on every `/impl:code` run, contradicting the §4-specified "Skip tests" branch available when no test framework is detected. | Criterion 1 rewritten to acknowledge the Skip path as a valid alternative outcome, provided the skip decision is logged in the Phase 5 report with user-provided rationale. |
| W7-m3 | §3 `impl.md` alias pattern said both "the drift risk is managed by the `KEEP IN SYNC` marker plus the CHANGELOG entry" **and** "CI should diff and fail on drift" — these are inconsistent, and no CI workflow is scoped in §3. | Dropped the "CI should" claim. Added a sentence noting CI enforcement is a plausible future enhancement but out of scope here. |
| W7-m4 | §12 "Ignored by default" only mentioned lowercase `attachments/`, but real exports use both `attachments/` and `Attachments/` (case varies by item creation date). | Clarified "case-insensitive match (real exports use both spellings)". |
| W7-m5 | §4 "Pre-Phase 3.5" heading placed the new test-baseliner phase between Pre-Phase 3 (branch creation) and Phase 3A (implementation), but the `.5` suffix was ambiguous — could read as a sub-step of Pre-Phase 3 rather than its own phase. | Heading expanded to "Pre-Phase 3.5 (between Pre-Phase 3 and Phase 3A/3B): Capture test baseline" with a one-sentence clarification that the `.5` means "inserted between 3 and 4 of the existing ordering — its own phase". |

#### NIT

| # | Finding | Fix applied |
|---|---|---|
| W7-n1 | §17 out-of-scope used `bitbucket*` — looks like a shell glob but §13 defines it as a substring check on the hostname. | Rephrased to cite the §13 rule directly: "hostname contains the substring `bitbucket` and is not `bitbucket.org`". |
| W7-n2 | §3 `impl-maintenance` update lists `/impl` as one of the Command-run values, but `/impl` is only an alias — the spec didn't say which value the handoff should record when the alias was used. | Added a sentence: when the alias is invoked, `Command run:` records `/impl:code` (the canonical workflow being executed); `/impl` is a transport detail, not a distinct workflow. |
| W7-n3 | §12 `depth: full` step 2 used the same `<LINKED_KEY>/<LINKED_KEY>.md` path for the VI itself — not wrong (it resolves to the nested `<VI>/<VI>/<VI>.md`) but only obvious after inspecting a real export. | Added a parenthetical noting the nested path and confirming it's verified against real exports. |
| W7-n4 | §§8–14 described agent Tools as prose (`**Tools:** Read, Glob, ...`), but existing in-repo agents use YAML arrays (`tools: ["Read", "Glob", ...]`). No existing agent has the prose form — implementers might reproduce the prose form verbatim. | Added a note just before §8 explaining that the prose Tools/Model lines are documentation shorthand; the actual agent frontmatter must use YAML arrays. The note also repeats the belt-and-braces Opus invocation pattern (`model: opus` in frontmatter **plus** `model: "opus"` on the caller's Agent call) for the two Opus agents in the new set (`doc-reviewer`, `epic-reviewer`), mirroring the existing `risk-planner` / `code-review` pattern. |

### Final state after Wave 7

- Reality-ground coverage: every agent input / output / invocation path was cross-checked against a real artifact (existing plugin code, real docs repo, real code repo, real Jira export).
- No remaining known blockers, majors, or minors.
- Spec still does not prescribe implementation details inside agents (e.g., exact Vale invocation, exact frontmatter merging logic) — these are correctly left to the implementation phase.
- The 4 new agents plus the 6 pre-existing ones stay the total count — no additions or removals in wave 7, only clarifications and schema tightening.

### Open items for implementation time (not blocking)

- The `doc-planner` image-policy detection's classification rules ("count > 0 and negligible" thresholds) are deliberately qualitative. An implementation will pick concrete numeric thresholds (e.g., "≥ 3 of the 5 sampled pages"); this is an implementation detail not worth hardcoding in the spec.
- The fallback chain for default-branch resolution (`origin/HEAD` → `remote set-head` retry → try `main` → try `master`) could be extended with `git config init.defaultBranch` if implementers see enough repos where that's the only signal; additive.
- The hook regex's longest-match alternation relies on Bash `grep -E` / POSIX ERE alternation ordering. If implementers move the hook to a different matcher, they must verify `/impl:jira:docs` still binds before `/impl`.

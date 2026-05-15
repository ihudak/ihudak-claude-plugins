# Design: Split `/impl` — test-writing, docs, and Jira-driven workflows

**Date:** 2026-04-30 (updated 2026-05-10)
**Status:** Approved — ready for implementation
**Scope:** `plugins/dev-workflows` only

---

## Design evolution

One deliberate change of direction during implementation:

- **`/impl` was originally specced as a backward-compatible alias** of `/impl:code` — implemented via a verbatim duplicate of `commands/impl/code.md` inside `commands/impl.md`, guarded by a `<!-- KEEP IN SYNC -->` marker. This shipped briefly inside 1.1.0 (Increment A).
- **Increment G reversed that decision** and reshaped `/impl` as a **help / dispatcher**: `commands/impl.md` now prints a short help page listing the `/impl:*` variants plus `/vuln` / `/upgrade` under "Related commands", and stops. The verbatim-copy approach was removing a ~27 KB shadow of `commands/impl/code.md` — drift-prone the moment anyone edited one side and forgot the other. The final shape of 1.1.0 ships the dispatcher, not the alias.

Everywhere below that this document talks about `/impl`, treat it as the dispatcher. The `/impl:code` workflow body is unchanged; only the trigger moved. 1.0.x muscle memory (`/impl <description>`) prints the dispatcher message pointing at `/impl:code <description>`.

This is a **breaking change** relative to 1.0.x, documented in `plugins/dev-workflows/CHANGELOG.md` under the 1.1.0 `### Breaking changes` section.

---

## 1. Problem

The `/impl` command serves two fundamentally different contexts:

- **Code changes** — tests should be written for new/changed behavior; none are currently written
- **Documentation changes** — branching, code review, and test suites are irrelevant noise

Additionally, a third workflow is needed: Jira-driven documentation and Epic writing, which is a multi-source aggregation pipeline bearing no resemblance to either of the above.

---

## 2. Decisions

**Split `/impl` into five commands:**

| Command | Purpose |
|---|---|
| `/impl` | Help / dispatcher — prints a list of the `/impl:*` variants and `/vuln` / `/upgrade`, then stops. Does NOT execute any workflow. |
| `/impl:code` | Full code workflow + test-writing phase (new) |
| `/impl:docs` | One-shot doc editing (simple markdown, READMEs, Obsidian notes) |
| `/impl:jira:docs` | Jira hierarchy + PR diffs → feature documentation |
| `/impl:jira:epics` | Jira VI + code scan → child Epic writing |

**Why not a single command with context detection:** Ambiguity risk is too high (`.yaml`, `.sh`, `.json` — code or config?). The Jira workflow is a multi-source aggregation pipeline that shares nothing meaningful with `/impl:docs`.

**Why `/impl:jira:docs` and `/impl:jira:epics` are separate from `/impl:docs`:** The Jira-driven workflows involve multi-repo parallel analysis, structured handoff schemas between agents, and Jira hierarchy traversal. Merging into `/impl:docs` would force it to carry conditional bloat for an unrelated workflow.

**Role clarification — `/impl:jira:docs` vs `/impl:jira:epics`:** these two commands serve different roles. `/impl:jira:docs` is a **technical-writer** workflow — it produces product documentation for features that have already been implemented, grounded in Jira items and PR diffs. `/impl:jira:epics` is a **product-manager / product-owner / engineering-lead** workflow — it produces Epic drafts for features that are being scoped for implementation. They share some infrastructure (jira-reader, the vault layout) but their outputs, audiences, invariants, and execution contexts diverge substantially.

---

## 3. Architecture

### New command files

```
plugins/dev-workflows/commands/
  impl/
    code.md               ← canonical full code workflow + test-writing phase   → /impl:code
    docs.md               ← one-shot doc editing workflow                        → /impl:docs
    jira/
      docs.md             ← Jira + PR diffs → feature documentation              → /impl:jira:docs
      epics.md            ← Jira VI + code scan → Epic writing                   → /impl:jira:epics
```

Namespaced slash commands are loaded via **directory convention** (`commands/<parent>/<child>.md` → `/<parent>:<child>`). This avoids `:` in filenames, which is forbidden on Windows filesystems; the repo must remain clone-able on Windows.

### New agent files

```
plugins/dev-workflows/agents/
  test-writer.md          ← writes tests for new/changed code behavior
  doc-reviewer.md         ← reviews product documentation (Opus gate)
  epic-reviewer.md        ← reviews Epic drafts (Opus gate)
  doc-fixer.md            ← fixes BLOCKER/MAJOR findings from either reviewer
  doc-planner.md          ← synthesises Jira + diffs into a documentation checklist
  doc-location-finder.md  ← finds existing/new target paths in a docs repo
  docs-style-checker.md   ← runs Vale / project lint; emits violations for doc-fixer
  jira-reader.md          ← reads Jira markdown hierarchy from vault
  diff-summarizer.md ← summarizes PR diffs per repo (parallel, use case A)
  code-scanner.md         ← scans code for reuse/gaps (parallel, use case B)
```

### Modified files

```
plugins/dev-workflows/
  commands/
    impl.md               ← short dispatcher body (help-only; see §3 dispatcher pattern)
  .claude-plugin/
    plugin.json           ← register all new commands + introduce `version` field
  agents/
    impl-maintenance.md   ← extend to recognise all /impl:* sub-commands (see §3 impl-maintenance update)
  hooks/
    preload-context.sh    ← extend to handle the new /impl:* variants (see §3 hook scope)
  README.md               ← update command and agent tables
  CHANGELOG.md            ← add entry
.claude-plugin/
  marketplace.json        ← introduce `version` field on the dev-workflows entry and bump it
```

### Versioning (introduced by this change)

Neither `plugin.json` nor `marketplace.json` currently carry a `version` field — there is nothing to bump in the existing schema. This change introduces semantic versioning for the `dev-workflows` plugin:

- Add `"version": "<semver>"` to `plugins/dev-workflows/.claude-plugin/plugin.json`.
- Add `"version": "<semver>"` to the `plugins[]` entry for `dev-workflows` in `.claude-plugin/marketplace.json`.
- Initial value: `"1.0.0"` (representing the pre-split state captured in git); this change bumps it to `"1.1.0"` (additive commands, no breaking changes to `/impl`).
- Other plugins in the marketplace are not required to adopt versioning as part of this change but should follow the same convention when they next see substantive edits.

### `impl.md` dispatcher pattern

`/impl <description>` does **not** execute the code-implementation workflow. `commands/impl.md` is a short help body that prints the available `/impl:*` variants (plus `/vuln` / `/upgrade` under "Related commands") and stops. A user whose muscle memory is `/impl add a feature` is redirected to `/impl:code add a feature` via the printed message — no aliasing, no auto-delegation.

The dispatcher file prompts the model to render a single help message, including whatever arguments the user passed, and then to stop without classifying, branching, invoking agents, or touching git. Typical file shape:

```markdown
`/impl` is a help / dispatcher command, not an implementation workflow. It never
executes any implementation, does not branch, does not run tests, does not invoke
agents, and does not touch git state.

Your task: print the message below to the user, interpolating $ARGUMENTS into the
"You invoked" line… then stop.

---

### Message to print

…/impl:* variants table…
…Related commands table (/vuln, /upgrade)…
…Migration note for 1.0.x users pointing at /impl:code…

---

Do NOT proceed with any workflow. After printing the message above, stop.
```

**Why a printed redirect rather than a verbatim copy or runtime delegation:**

- **Verbatim copy** (the initial Increment-A design) puts a ~27 KB shadow of `commands/impl/code.md` in `commands/impl.md` with a `<!-- KEEP IN SYNC -->` marker. The marker is a social-contract enforcement mechanism — i.e. not enforced. The moment anyone edits one side and forgets the other, the two commands diverge silently. The maintenance tax is paid on every edit to `impl/code.md`.
- **Runtime delegation** ("read file X and follow it as if it were this command's body") is not a first-class Claude Code primitive; plugin paths change across installs, and the delegation semantics are undefined. Brittle.
- **Printed redirect** (the Increment-G design, final) makes the failure mode loud instead of silent: a user whose muscle memory is wrong sees a one-screen help page with the right command to re-type. There is exactly one source of truth for the code workflow (`commands/impl/code.md`, registered as `/impl:code`). Maintenance burden is zero because the dispatcher has no workflow content to keep in sync.

The cost of the printed-redirect design is the breaking change for 1.0.x users (`/impl <description>` no longer runs the workflow); this is accepted and documented in `plugins/dev-workflows/CHANGELOG.md` under 1.1.0 `### Breaking changes`.

### Hook scope (`preload-context`)

The existing `preload-context` hook injects git context and a model-routing reminder for `/impl`, `/vuln`, `/upgrade`. After this change it must match the new command shape:

| Command | Context injection |
|---|---|
| `/impl` (dispatcher) | **None** — dispatcher prints help and stops; injected context would be noise before the help screen |
| `/impl:code` | Full — git context + model-routing reminder |
| `/impl:docs` | **None** — user manages git manually; model-routing is not triggered |
| `/impl:jira:docs` | `$VAULT_PATH` and `<repos_base>` (default `/repos`); git branch context **only if** cwd is inside a git repo |
| `/impl:jira:epics` | Same as `/impl:jira:docs` |

The hook should pattern-match against `/impl` and all `/impl:*` variants rather than each one literally, to avoid regressions when future sub-commands are added.

**Normative regex** — the existing hook (`hooks/preload-context.sh`) uses

```bash
^/(impl|vuln|upgrade)[[:space:]]+[^[:space:]-]
```

which does **not** match `/impl:code foo` because the character after `impl` is `:`, not whitespace. Replace with:

```bash
^/(impl(:(code|docs|jira(:(docs|epics))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-]
```

The longest-match alternation inside the `impl` group is deliberate — `/impl:jira:docs` must be recognised before the outer `/impl` fallback. After the match, the hook reads `$1` (the full command token, e.g. `impl:jira:docs`) and routes to the correct context-injection branch per the table above.

### `impl-maintenance` update

Every command that runs Phase 4 (code) or Phase 8 (Jira) maintenance invokes `impl-maintenance` via the session-handoff block. After this split, the handoff block must include an explicit **`Command run:` field** so the agent's "Command workflow improvements" section can suggest changes against the right command variant:

```
Command run: /impl:code | /impl:docs | /impl:jira:docs | /impl:jira:epics
```

The existing `agents/impl-maintenance.md` prompt must also be updated in two places:

1. The **Inputs** section adds `Command run` to the expected session-handoff fields, listing the live values (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`). The literal legacy value `/impl` is accepted on input (mapped to `/impl:code`) but not listed as a live option — see the Increment G note below.
2. The **"Command workflow improvements"** output sub-section, currently fixed to `"Command: [/impl | /vuln | /upgrade]"`, is broadened to `"Command: [/impl:code | /impl:docs | /impl:jira:docs | /impl:jira:epics | /vuln | /upgrade]"` (no `/impl` in the live output enum — see the Increment G note below).

As of Increment G, `/impl` no longer runs any workflow (it is a dispatcher that prints help and stops — see §3 dispatcher pattern), so no live workflow will pass `Command run: /impl` to `impl-maintenance`. For replay compatibility with archived 1.0.x handoffs that still carry the literal value `/impl`, `impl-maintenance` accepts it on input and internally maps it to `/impl:code`, with a note in the report's `### Session summary` so the caller notices the legacy value. Live output ("Command workflow improvements") omits `/impl` from its enum — the agent will never suggest improvements against a command that does not run a workflow.

Without this routing discipline, maintenance suggestions from the three new Jira/docs commands would be labelled against the wrong command and silently misdirected.

---

## 4. `/impl:code` — workflow changes

All existing phases from the current `impl.md` (which becomes `commands/impl/code.md` under the new directory layout — see §3) are preserved. Two insertions are made.

### Insertion 1 — Pre-Phase 3.5 (between Pre-Phase 3 and Phase 3A/3B): Capture test baseline

Placed **after** branch creation (Pre-Phase 3), **before** any file edits. The `.5` numbering signals "inserted between step 3 and step 4 of the existing ordering" — it is its own phase, not a sub-step of Pre-Phase 3's branch-creation steps.

```
→ Agent (subagent_type: "dev-workflows:test-baseliner"):
  Mode: capture
  Project root: [absolute path]
```

Store the returned `## Test Baseline` block. If `Framework: not detected`, note it but continue — Phase 3.5 will surface this to the user explicitly.

### Insertion 2 — Phase 3.5: Write and verify tests

#### For SIMPLE/MODERATE (after Phase 3A implementation):

1. Invoke `test-writer` agent (Section 8).
2. If `test-writer` returns `Framework: not detected`:
   ```
   choices: ["Specify test command to use", "Skip tests for this run (document why in the final report — Phase 5 of the inherited /impl:code workflow)", "Cancel"]
   ```
3. Run linters/builds.
4. Invoke `test-baseliner` in verify mode against the captured baseline.
5. **Fix loop** — if regressions or new test failures are reported:
   - The **session model** (not a subagent) applies fixes using the `test-baseliner` verify report as the authoritative list of regressions. No `review-fixer`-style indirection is used here — the scope is narrow and the context is already fully in-session.
   - After each fix attempt, re-capture the diff (`git add -N . && git diff`) and re-run `test-baseliner` in verify mode against the **original** baseline (never re-baseline mid-loop).
   - Cap at **2 fix attempts**. If regressions remain, surface to user with `choices: ["Investigate further", "Accept regressions and proceed", "Cancel"]`.

#### For SIGNIFICANT/HIGH-RISK (inside Phase 3B):

- **After step 4** (implementation complete), **before step 5** (diff capture):
  - Invoke `test-writer` agent.
  - If `test-writer` returns `Framework: not detected`: **before** invoking Opus review, ask the user (mirrors the SIMPLE/MODERATE branch):
    ```
    choices: ["Specify test command to use", "Skip tests for this run (document why in the final report — Phase 5 of the inherited /impl:code workflow)", "Cancel"]
    ```
    This keeps the Opus-review input deterministic — the reviewer is never asked to reason about an unknown test strategy — and ensures the "Skip" decision is an explicit, logged choice.
- **Step 5 diff** now includes test files → Opus reviews code and tests together (test adequacy is already a review dimension in `code-review.md`).
- Phase 3.5 runs **after** the review gate clears (non-BLOCK verdict), replacing steps 8–10 of the original Phase 3B (run tests, fix failures, re-run). The fix loop here uses the same pattern as Phase 3B review-fix handling: the session model applies fixes; if fixes are non-trivial the Opus review is re-invoked on the delta (unless the reviewer was down-classified in step 7).

### New invariants for `/impl:code`

```
- ALWAYS capture test baseline (Pre-Phase 3.5) before writing any file
- NEVER skip Phase 3.5 — if no test framework detected, ask the user rather than silently skipping
- NEVER run tests for SIGNIFICANT/HIGH-RISK before Opus review returns non-BLOCK (preserved)
```

---

## 5. `/impl:docs` — one-shot doc editing

### What is removed vs `/impl:code`

| Removed | Reason |
|---|---|
| Pre-Phase 3 (branch creation, clean-tree check, git operations) | No branching; user manages git manually |
| Pre-Phase 3.5 (baseline capture) | No tests |
| Phase 3B (SIGNIFICANT/HIGH-RISK code path) | Docs changes are never SIGNIFICANT in this command |
| Phase 3.5 (test writing + verify) | No tests |
| Opus planning / Opus review | Never warranted for one-shot doc edits |
| Git commit | User manages manually |

### Scope

`/impl:docs` handles only **one-shot doc editing**: minor edits, formatting, small updates to existing pages, single-file additions where the content comes from the user's description alone. All classification is SIMPLE or MODERATE.

For net-new documentation created from Jira hierarchy + code repos, use `/impl:jira:docs` or `/impl:jira:epics`.

### Phase 2A plan template change

Replace "Tests" section with "Validation" — spot-check steps (link integrity, heading structure, broken `[[wikilinks]]`).

### Phase 3 implementation

Make edits; run validation checks from plan; no test step; no git commit.

### Phase 4 and Phase 5

All four Phase 4 maintenance agents run unchanged. Session-handoff sets `change_type: docs` (consistent with `/impl:jira:docs` and `/impl:jira:epics`). Phase 5 report: no branch, no test results, no Opus review. Add `### Validation` section.

### Invariants

```
- NEVER create a git branch
- NEVER run tests
- NEVER invoke Opus
- NEVER commit — user manages git manually
- ALWAYS run Phase 4 maintenance agents
```

---

## 6. `/impl:jira:docs` — Jira-driven feature documentation

### Purpose

Given a Jira Value Increment key, reads the full Jira hierarchy from pre-exported markdown files in the vault, resolves PR URLs to local git repos, runs parallel PR diff summaries, synthesizes product documentation, reviews, and writes output to cwd.

### Phase 0 — Load and dispatch

1. Resolve `$VAULT_PATH` (env var → ask if unset → validate existence).
2. Resolve `<JIRA_KEY>` from `$ARGUMENTS`; validate `$VAULT_PATH/jira-products/<JIRA_KEY>/` exists. If not: stop with error.
3. **Docs-repo detection.** This command writes feature documentation into a product docs repository; running it outside such a repository is almost always a mistake. Detect signals in cwd's git root:
   - `package.json` with any script matching `*:start`, `*:build`, `*:lint`, `docs:*` (common in Docusaurus/Nx/Docstack repos), **or**
   - any of `.docstack/`, `mkdocs.yml`, `docusaurus.config.js`, `antora.yml`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, **or**
   - a `_snippets/` directory at any level under the repo root.

   If ≥1 signal is present → proceed silently.
   If 0 signals are present → confirm with the user:
   ```
   choices: ["Proceed — I confirm this is a docs repo", "Cancel — switch to a docs repo first"]
   ```
   Default = Cancel. The prompt must list the signals that were checked and not found, so the user can decide against an informed picture.

### Phase 1 — Clarification

Ask (grouped where possible, `choices` arrays, last choice always `"Other… (describe)"`):

- Output filename / sub-path under cwd (default: `<KEY>-<slug>.md`).
- PR status filter (MERGED only `(Recommended)` / all / specific list).
- Repo refresh policy: `fetch only` `(Recommended)` / `fetch + pull default branch` / `no refresh`.
- **Repos base path** — detect `/repos` (check existence) and ask:
  ```
  choices: ["Use /repos (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]
  ```
  If "different path", follow up with a free-text entry and validate that at least one directory exists under it.
- **Screenshots** — ask:
  ```
  choices: ["No screenshots needed", "I'll provide screenshot paths (you'll be prompted)", "Cancel"]
  ```
  If "provide paths", follow up with a free-text entry accepting any absolute filesystem path (vault, `/tmp`, home, the docs repo itself). Accept multiple paths (one per line or space-separated). Validate each exists and is an image by extension (`.png|.jpg|.jpeg|.gif|.svg|.webp`). The downstream `doc-planner` agent at Phase 5.7 detects the repo's image policy (local-file vs. CDN-upload) and decides per screenshot whether the writer will copy it into the repo's idiomatic image location or stage it outside the repo for manual upload — see §10b `image_policy` and §6 Phase 6 "Place screenshots".

Also detect and show: resolved cwd absolute path, write context (`obsidian` / `docs_repo` / `non_docs_repo` / `plain_dir` — see Section 11), whether branching will happen, and the resolved `<repos_base>`.

### Phase 1.5 — Classify

Jira-driven feature docs are typically **SIGNIFICANT** (large blast radius if wrong — published documentation). State classification and reason. SIGNIFICANT → no Opus planning (Jira read is the plan); but doc-reviewer gate is mandatory.

### Phase 2 — Plan + approval

Present: resolved JIRA_KEY, output file path, repos to examine, PRs in scope, parallelism plan. Ask for approval.

### Phase 3 — Read Jira hierarchy

Invoke `jira-reader` agent (Section 12) with `depth: full`. Wait for handoff.

### Phase 4 — Resolve repos

From the `jira-reader` handoff `pull_requests` list:
1. Parse each PR URL. Three host categories are recognised (see §13 resolver selection):
   - **Cloud GitHub** — hostname `github.com`, URL shape `https://github.com/<OWNER>/<REPO>/pull/<PR_ID>` → extract `<REPO>` (and `<OWNER>` for `gh` use).
   - **Cloud Bitbucket** — hostname `bitbucket.org`, URL shape `https://bitbucket.org/<WORKSPACE>/<REPO>/pull-requests/<PR_ID>` → extract `<REPO>`.
   - **Self-hosted Bitbucket Server** — hostname contains the substring `bitbucket` and is not `bitbucket.org`, URL shape `https://<host>/projects/<PROJECT>/repos/<REPO>/pull-requests/<PR_ID>` → extract `<REPO>`. The `<host>` is opaque to the resolver; it is only used for host classification.
   Any other host is recorded as `unresolved` with reason `unsupported host`.
2. Filter by `status` per Phase 1 setting (default: MERGED only). This is the `pull_requests[].status` field on the `jira-reader` output (see §12 schema), not the top-level agent `status` field.
3. For each unique repo, check `<repos_base>/<REPO>` exists using the path resolved at Phase 1.
4. If any repos missing, escalate using the rules in Section 15 (choices include "Skip and continue without its PRs", "I'll clone it — wait", "Cancel", and "Re-resolve with a different `<repos_base>`"). List missing repos explicitly.

### Phase 5 — Parallel diff summarization

Spawn `diff-summarizer` instances **in batches of up to 4 concurrent agents** (single Agent message per batch). Wait for all instances in a batch to return before spawning the next batch. If fewer than 4 repos remain, the final batch is smaller.

Rationale: Claude Code's practical parallel-subagent limit is ~4–5; going above that causes silent serialisation or rate-limiting. Capping at 4 makes runtime deterministic and keeps handoff latency predictable.

Handle `status: REPO_MISSING`, `DIRTY_TREE`, `REFRESH_BLOCKED`, `NO_PRS_RESOLVED`, or `PARTIAL` per Section 15 escalation rules.

### Phase 5.5 — Find documentation locations

Invoke `doc-location-finder` agent (see agent spec) with the docs-repo root, the feature summary (from `jira-reader` themes + VI goal), and the per-repo diff summaries (for naming hints from the changed code areas).

Expected output: a list of recommended write targets, each annotated with `kind` (extend-existing | new-page-in-existing-section | new-section), `section` (e.g. "Setup", "How to use", "Reference"), absolute path, and 1-sentence rationale.

**Status handling:**
- `status: OK` with a populated `targets` list → present to the user and ask:
  ```
  choices: ["Accept all proposed locations (Recommended)", "Adjust individual locations (you'll be prompted per item)", "Cancel"]
  ```
- `status: LOW_CONFIDENCE` → display the `confidence_notes` alongside the targets so the user sees what was ambiguous; present the same accept/adjust/cancel choices but change the default from "Accept all" to "Adjust individual locations".
- `status: EMPTY` (no targets produced) → skip the accept/adjust flow and go straight to:
  ```
  choices: ["Specify locations manually (you'll be prompted)", "Cancel"]
  ```
  The manual-specify path takes a free-text entry per target (path + kind + section) and validates path existence for `extend-existing` targets.

The confirmed target list (from any of the three paths above) is the authoritative write-target set for Phase 6 and is handed to `doc-planner` in Phase 5.7.

### Phase 5.7 — Plan the documentation

Invoke `doc-planner` agent (see agent spec) with:
- `jira-reader` handoff
- per-repo diff summaries
- confirmed write-target list from Phase 5.5
- screenshot paths (if any) from Phase 1
- `repo_root` (the docs-repo root resolved in Phase 0)

Expected output: a `documentation checklist` — topics × locations, per-file YAML frontmatter updates (including `changelog:` entries), snippet reuse/extraction proposals, screenshot placement instructions, and cross-link needs. This checklist is what the Phase 6 writer follows and what `doc-reviewer` checks against in Phase 7.

**Status handling:**
- `status: OK`, `gaps: []` → proceed to approval.
- `status: OK` or `PARTIAL` with `gaps` entries → for each gap, act on its `recommended_action`:
  - `"ask user"` → prompt the user inline **before** showing the checklist-approval choice. Use a free-text prompt scoped to what the gap describes; feed the answer back to the planner (single re-invocation, no further loops). If the user declines to provide input, fall back to `"mark TODO in draft"` for that gap.
  - `"mark TODO in draft"` → surface in the checklist display as a visible TODO; the writer will emit a `<!-- TODO: … -->` marker at Phase 6. Does not block approval.
  - `"skip with note in final report"` → list in the checklist display; carry forward into Phase 9 `### Skipped items`. Does not block approval.
- `status: PARTIAL` is presented to the user alongside the checklist so the approval decision is informed.

Present the checklist (with any gaps + their dispositions) to the user for approval:
```
choices: ["Approve & write (Recommended)", "Adjust (describe)", "Cancel"]
```

### Phase 6 — Write documentation

The main command (session model) writes the markdown following the `doc-planner` checklist from Phase 5.7. The writer is not a separate subagent — it's the orchestrating command, which has full context from Phases 3–5.7 already loaded.

For each target from the confirmed write-target list:
- **Preserve any existing YAML frontmatter** on pages being extended. Never strip unknown fields.
- **Add or update** the `changelog:` field per the planner's checklist (append a new dated entry naming the Jira key and a 1-line change summary). Create the field if it doesn't exist on an extended page.
- **Update other frontmatter fields** the planner flagged: `published` (creation date on new pages), `meta.generation`, `readtime` (estimate from word count), `tags` (merge — don't duplicate), `owners` (leave to the user to maintain).
- **Reuse snippets** per the planner's checklist: if a snippet path is proposed, `include` it rather than inlining the content; if the planner recommends extracting new content into a snippet, create the snippet file in the repo's idiomatic `_snippets/` location and reference it from the page.
- **Place screenshots** per each target's `image_policy` from the `doc-planner` checklist:
  - `local` → copy each user-provided `src` to the planner's `dest` path (typically `<page-dir>/img/` or the detected idiomatic directory). Reference the local path in markdown with the repo's preferred syntax (`![alt](./img/name.png)` or similar — match sibling pages).
  - `cdn_upload_required` → **do NOT copy user-provided screenshots into the repo.** Stage them at the planner's `staging` path (`/tmp/<JIRA_KEY>-screenshots/`). In the markdown, insert a placeholder reference with a clearly marked TODO — for example `![alt text](TODO-upload-screenshot-to-image-manager)` or a commented-out block — so the reviewer sees the intent but the build does not silently ship a broken link. List every staged screenshot and its upload instructions in the Phase 9 `### Screenshots to upload manually` section.
  - `ambiguous` → ask the user at this step, per target:
    ```
    choices: ["Use local path <page-dir>/img/ (Recommended if this repo uses local images)", "Stage for manual upload to the repo's image-management tool", "Skip this screenshot", "Other… (describe)"]
    ```
    Apply the chosen branch.
  
  This design is grounded in the reality that product-docs repos split along this line: some (e.g. Docusaurus-style with adjacent `img/` dirs) store images in-tree; others upload to an external CDN or Image Manager and reference via `https://` URLs with zero local image files — this second pattern was verified against a representative product-docs repo during design. The plugin cannot automate the upload step, so staging + explicit reporting is the correct handoff.
- **Traceability**: every claim must cite the originating Jira key (e.g. `[[<JIRA_KEY>]]`) and/or PR URL inline. If the claim comes only from imported Jira content (no PR was resolved), cite the Jira key alone.

Write to cwd (see Section 11 for branch/write policy).

### Phase 6.5 — Branch setup (conditional)

Only when write context = `docs_repo` (or `non_docs_repo` after user confirmation in Phase 0) AND user confirmed branching at plan approval. Never for `obsidian` or `plain_dir`.

1. **Update the base branch.** Determine the base by running `git symbolic-ref --short refs/remotes/origin/HEAD` — this returns the remote's default branch (typically `main` or `master`; legacy repos frequently still use `master`). If that command fails (unset `origin/HEAD`), run `git remote set-head origin --auto` first and retry; if it still fails, fall back to trying `main`, then `master`, in that order. If the user picked a `release/*` branch earlier in Phase 1, use that instead of the default. Once the base is resolved, run `git fetch origin` → `git switch <base> && git pull --ff-only`. If the fast-forward pull fails (local commits on base), escalate with `choices: ["Stash local changes and continue (Recommended)", "Proceed from current base state", "Cancel"]`.
2. **Clean-tree check.** Run `git status --porcelain`; if non-empty, prompt `choices: ["Stash changes and continue (Recommended)", "Proceed anyway — pre-existing changes will appear in the diff", "Cancel"]`. Mirrors `commands/impl/code.md` Pre-Phase 3.
3. **Derive branch name from repo conventions.** In priority order, look at repo root for `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `DOCUMENTATION-GUIDELINES.md`. Grep each for a branch-naming section (case-insensitive, patterns like `Branch name`, `Branch naming`, `naming your branch`). If a pattern like `<user>/<JIRA-KEY>-<slug>` or `<prefix>/<name>` is documented, derive the branch name by filling placeholders with known values (Jira key from Phase 0, slug from the feature summary, `<user>` from `git config user.name` or its initials). If multiple patterns are documented, offer them to the user.
4. **Confirm the branch name with the user.** Always — even when derived from conventions — because initials and slugs are subjective:
   ```
   choices: ["Use proposed name: <name>", "Edit name (you'll be prompted)", "Cancel"]
   ```
   Fallback default when no convention is found: `docs/<jira-key>-<slug>`.
5. **Create the branch.** `git switch -c <name>`.

No external CLI call; all git operations are local.

### Phase 6.7 — Style check (before reviewer)

Invoke `docs-style-checker` agent on the files written in Phase 6. It detects and runs the repo's project-configured prose linter — Vale via `.vale.ini`, or a `yarn <project>:lint` script, or similar — and returns a violations list.

- **No linter configured in the repo** → agent returns `status: NOT_CONFIGURED` with no violations. Move on to Phase 7; the doc-reviewer will still check correctness/completeness.
- **Linter ran, 0 violations** → proceed to Phase 7.
- **Violations present** → invoke `doc-fixer` with the violations treated as MAJOR findings. After `doc-fixer` completes, re-run the linter once. If violations remain, surface to user with `choices: ["Proceed to review anyway — reviewer may still PASS", "Show remaining violations and let me fix manually", "Cancel"]`.

The goal is to catch corporate-style issues locally so the doc-reviewer (Opus) spends its attention budget on correctness and completeness, not prose policing, and so the eventual PR doesn't bounce on CI style checks.

### Phase 7 — Doc review gate

Invoke `doc-reviewer` agent (Section 9). The reviewer is **product-docs-only**; Epic drafts use `epic-reviewer` in `/impl:jira:epics`. Act on verdict:
- **BLOCK** → invoke `doc-fixer` (BLOCKER findings). Re-invoke `doc-reviewer` once. If still BLOCK: surface to user. Cap: one fix cycle + one re-review.
- **PASS WITH RECOMMENDATIONS** → invoke `doc-fixer` (MAJOR findings only). MINOR/NIT deferred to Phase 9 report.
- **PASS** → proceed.

### Phase 8 — Maintenance

All four Phase 4 maintenance agents (docs, knowledge base, instructions, session report). `change_type: docs` in session handoff.

### Phase 9 — Final report

Standard Phase 5 structure plus:
- `### Jira hierarchy summary`
- `### Repos analysed`
- `### PRs in scope`
- `### Output file(s)`
- `### Doc review verdict`
- `### Screenshots to upload manually` — populated only when any target used `image_policy: cdn_upload_required` (or the user selected "Stage for manual upload" under the `ambiguous` branch). For each staged screenshot: `src` (original user-provided path), `staging` path under `/tmp/<JIRA_KEY>-screenshots/`, the target page it belongs on, the proposed alt-text, and the `upload_note` from the planner. Omit this section entirely when no screenshots were staged.

### Invariants

```
- ALWAYS run Phase 0 docs-repo detection; if 0 signals, require user confirmation before proceeding
- NEVER call Bitbucket REST APIs for Cloud or self-hosted Server — Bitbucket URLs are identifiers only; all resolution is pure local git. (No official Atlassian CLI covers Bitbucket at time of writing; adopting a third-party one would be a separate decision.)
- GitHub URLs may use the `gh` CLI for head/base SHA resolution (see §13 GitHub resolver); no direct REST calls outside `gh`
- NEVER write inside _archive/ — that path is read-only by convention
- NEVER write inside jira-products/ — that path is re-created from scratch on every Jira import; writes there will be lost
- NEVER write outside cwd unless user provides explicit absolute path
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS run docs-style-checker (Phase 6.7) before doc-reviewer
- ALWAYS invoke doc-reviewer before Phase 8
- Cap review/fix cycles: 1 fix + 1 re-review max
- All written claims must be traceable to Jira keys or PR diffs; if only Jira is available, cite the Jira key alone
```

---

## 7. `/impl:jira:epics` — Jira-driven Epic writing

### Purpose

Given a Jira Value Increment key, reads the VI and its existing Epics, optionally scans code repos to identify reusable code and gaps, drafts child Epic definitions in markdown, reviews, and writes output to cwd.

**Key distinction from `/impl:jira:docs`:** The VI being Epic-ized is NOT yet implemented — there are no PRs to diff. Code scanning is a plain filesystem search to understand what exists and what needs to be built.

### Phase 0 — Load

1. Resolve `$VAULT_PATH` as in `/impl:jira:docs` Phase 0.1.
2. **Require vault context.** This command writes Epic drafts into the user's Obsidian vault; running it outside the vault would produce files in the wrong place. Verify cwd is inside `$VAULT_PATH` (cwd starts with the resolved `$VAULT_PATH` prefix, case-sensitive). If not:
   ```
   choices: ["Cancel and re-run after `cd <VAULT_PATH>`", "Cancel"]
   ```
   Both choices end the current run — the command cannot `cd` for the user safely across shells. The first choice emits a `cd "$VAULT_PATH"` instruction for the user to copy-paste. Default = Cancel.
3. Resolve `<JIRA_KEY>` from `$ARGUMENTS`; validate `$VAULT_PATH/jira-products/<JIRA_KEY>/` exists. If not: stop with error.

### Phase 1 — Clarification

Ask (grouped where possible, `choices` arrays, last choice always `"Other… (describe)"`):

- **Output directory** (default: `$VAULT_PATH/jira-drafts/<VI-KEY>/`; one `.md` file per Epic, filename `<NEW-EPIC-SLUG>.md`). This path lives **outside** `jira-products/` by design — `jira-products/` is re-created from scratch on every Jira import, so any Epic drafts written there would be lost. `jira-drafts/` is a sibling directory reserved for PM/PO work-in-progress that survives re-imports. The directory is auto-created if missing.
- Code examination on/off (default: ON) — if ON, ask which repos under `<repos_base>` to scan (defaults: repos referenced by sibling/parent Epics in the index; otherwise user lists them).
- Repo refresh policy: `fetch + pull default branch` `(Recommended)` / `fetch only` / `no refresh`.
- **Repos base path** — detect `/repos` (check existence) and ask:
  ```
  choices: ["Use /repos (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]
  ```
  If "different path", follow up with a free-text entry and validate that at least one directory exists under it.

Also detect and show: resolved cwd absolute path, resolved output directory, and the resolved `<repos_base>`. No branching context is shown — `/impl:jira:epics` never branches (see Phase 6.5 removal and invariants).

### Phase 1.5 — Classify

Epic writing is typically **MODERATE** (bounded scope, single VI). State classification.

### Phase 2 — Plan + approval

Present: VI summary, existing Epics identified (will not duplicate), repos to scan, output file layout. Ask for approval.

### Phase 3 — Read Jira hierarchy

Invoke `jira-reader` agent with `depth: vi-plus-epics` (reads the index + the VI's own `.md` + every Epic `.md` linked to the VI; Stories/Sub-tasks/Research/RFA are skipped). This depth is specifically designed for Epic-writing: richer than `vi-only` so themes extracted for `code-scanner` are not starved of context, lighter than `full` so the agent does not read dozens of already-closed child Stories. Identify already-linked Epics to avoid duplicate scope.

### Phase 4 — Resolve repos (conditional)

If code scan ON: verify each repo exists at `<repos_base>/<REPO>` (using the path resolved at Phase 1). Escalate missing repos per Section 15.

### Phase 5 — Parallel code scanning (conditional)

If code scan ON: spawn `code-scanner` instances **in batches of up to 4 concurrent agents** (single Agent message per batch). Wait for all instances in a batch to return before spawning the next batch. Each instance gets: capability themes from `jira-reader` output + VI goal as search seeds.

If code scan OFF: skip Phase 5.

### Phase 6 — Write Epics

Draft child Epic definitions — one file per Epic:
- `goal` (1 sentence)
- `business value` (1–2 sentences)
- `scope` (in / out)
- `acceptance criteria` (testable)
- `dependencies` (other Epics, repos, teams)
- `suggested stories` (high-level breakdown)
- `references` (Jira links, code paths if code scan was run)

Write to the resolved output directory from Phase 1 (default `$VAULT_PATH/jira-drafts/<VI-KEY>/`). Create the directory if missing. One file per Epic. Show resolved absolute paths at plan approval.

### Phase 7 — Epic review gate

Invoke `epic-reviewer` agent (see agent spec). This reviewer is Epic-specific — it focuses on acceptance-criteria testability, scope clarity, and non-duplication of existing Epics under the VI. Verdict handling is the same as `/impl:jira:docs` Phase 7 (BLOCK / PASS WITH RECOMMENDATIONS / PASS; cap 1 fix + 1 re-review). Fixes go through the shared `doc-fixer` agent.

Unlike `/impl:jira:docs`, there is **no** `docs-style-checker` step preceding `epic-reviewer`. Epic drafts are vault-internal and not subject to product-docs prose linting; corporate style compliance matters at product-docs publication time, not at Epic scoping time.

### Phase 8 — Maintenance

All four Phase 4 maintenance agents. `change_type: docs`.

### Phase 9 — Final report

Standard structure plus:
- `### VI summary`
- `### Existing Epics (not duplicated)`
- `### New Epics written`
- `### Repos scanned`
- `### Epic review verdict`

### Invariants

```
- ALWAYS run Phase 0 vault check — refuse to run outside $VAULT_PATH
- NEVER create a git branch (this command never branches)
- NEVER commit (vault git management is the user's responsibility)
- NEVER write inside jira-products/ — re-created on every import; writes would be lost
- NEVER write inside _archive/ — read-only by convention
- ALWAYS write to jira-drafts/<VI-KEY>/ (or the user-confirmed alternative under $VAULT_PATH)
- ALWAYS escalate missing repos before proceeding
- ALWAYS invoke epic-reviewer before Phase 8
- Cap review/fix cycles: 1 fix + 1 re-review max
- All written claims must be traceable to Jira keys or code paths
```

---

## 8. Agent: `test-writer.md`

> **Note on agent frontmatter conventions (applies to §§8–14).** The `**Tools:**` and `**Model:**` lines in each agent spec below are documentation shorthand. The actual agent files placed in `plugins/dev-workflows/agents/` MUST use YAML frontmatter matching the existing in-repo style (see `agents/risk-planner.md`, `agents/code-review.md`, `agents/test-baseliner.md`):
>
> ```yaml
> ---
> name: <agent-name>
> description: <one-line description>
> model: opus         # only for Opus agents; omit to inherit the session model
> tools: ["Read", "Glob", "Grep", "LS", ...]   # YAML array, not prose
> ---
> ```
>
> Opus agents (in this spec: `doc-reviewer`, `epic-reviewer`) additionally receive `model: "opus"` on the `Agent` call from the caller command, mirroring the existing `/impl` → `risk-planner` / `code-review` invocation pattern. This belt-and-braces approach ensures Opus routing works regardless of whether user-level agent auto-discovery is active in the session.

**Purpose:** Writes tests for new or changed behavior. Does NOT run tests.

**Model:** inherits session (no `model:` override in frontmatter).

**Tools:** Read, Glob, Grep, LS, Write, Edit

**Inputs:** Task description, plan, diff (`git diff` output), project root, baseline snapshot.

**Steps:**
1. Detect framework (same logic as `test-baseliner`). If not detected: return "not detected" report immediately.
2. Map changed behavior from diff — identify new functions, changed logic, new branches, new API surface. Skip: pre-existing untested code, renames, comment-only changes.
3. Discover test patterns from 2–3 representative test files (naming, assertions, fixtures).
4. Write tests covering new/changed behavior only. Follow existing style exactly.

**Output:**
```markdown
## Test Writer Report
- **Framework**: [name | "not detected"]
- **Tests written**: [N]

### Tests added
- `[test name]` in `[file:line]` — covers [what behavior]

### Skipped (pre-existing untested code)
[list or "none"]

### Notes
[anything unusual or "none"]
```

---

## 9. Agent: `doc-reviewer.md`

**Purpose:** Reviews **product documentation** written by `/impl:jira:docs` for correctness, completeness, and fitness for purpose. Returns PASS / PASS WITH RECOMMENDATIONS / BLOCK. Epic drafts are reviewed by `epic-reviewer` (see §9b); this agent is product-docs-only.

**Model:** `opus` (declared in frontmatter). Mirrors the Opus-backed gate role of `code-review` — this agent decides whether to BLOCK the run, so it needs the strongest reasoning model available. Do NOT down-grade to session model.

**Tools:** Read, Glob, Grep, LS

**Inputs:** Written doc file path(s), Jira directory path (for cross-check), diff summaries, the `doc-planner` checklist from Phase 5.7 (review against plan), the `docs-style-checker` report from Phase 6.7.

**Review dimensions:**

| Dimension | Check |
|---|---|
| Factual correctness | Matches Jira + code diffs |
| Completeness vs plan | Every item in the `doc-planner` checklist is addressed; nothing silently skipped |
| Coverage | "How to use" and "How to configure" sections present when the feature needs them |
| Audience fit | End-user clarity; technical jargon explained or linked; commands copy-pasteable |
| Structural integrity | Headings, links, `[[wikilinks]]` resolve; internal nav consistent |
| YAML frontmatter | `changelog:` updated with the Jira key; other required fields per the repo's convention (e.g., `title`, `description`, `published`, `tags`) present on new pages |
| Screenshots | Referenced where the planner flagged them; for `image_policy: local` the referenced image files resolve on disk; for `image_policy: cdn_upload_required` a TODO placeholder is present and the Phase 9 `### Screenshots to upload manually` section lists the staged file; alt-text present in all cases |
| Snippets | Reused where the planner proposed reuse; not needlessly inlined; new snippets (if any) follow repo conventions |
| Actionability | Examples runnable; commands copyable verbatim; links resolve |
| Source traceability | Claims cite Jira keys + PRs (or Jira keys alone when no PR was resolved) |
| Style-check follow-through | Any unresolved `docs-style-checker` violations above MINOR are reflected as BLOCKER or MAJOR findings here |

**Verdict:** PASS (no findings above MINOR), PASS WITH RECOMMENDATIONS (MAJOR/MINOR/NIT only), BLOCK (at least one BLOCKER). Same output shape as `code-review.md`.

---

## 9b. Agent: `epic-reviewer.md`

**Purpose:** Reviews **Epic drafts** written by `/impl:jira:epics` for scope clarity, testability, and non-duplication. Returns PASS / PASS WITH RECOMMENDATIONS / BLOCK. Product documentation is reviewed by `doc-reviewer` (§9); this agent is Epic-specific.

**Model:** `opus` (declared in frontmatter). Same rationale as `doc-reviewer`.

**Tools:** Read, Glob, Grep, LS

**Inputs:** Written Epic markdown file(s), `jira-reader` handoff (incl. existing Epics under the VI), `code-scanner` output.

**Review dimensions:**

| Dimension | Check |
|---|---|
| Goal clarity | 1-sentence goal, unambiguous, tied to the parent VI |
| Business value | 1–2 sentences linking the Epic to the VI's outcome |
| Scope (in / out) | Clearly delimited; "out of scope" is concrete, not hand-waving |
| Acceptance criteria | Testable (each criterion has an observable pass/fail signal); not a restatement of the goal |
| Dependencies | Other Epics / repos / teams named; no unstated external blockers |
| Suggested stories | High-level breakdown is plausible; no story overlap with existing Epics under the VI |
| Non-duplication | No overlap with existing Epics linked to the VI (from `jira-reader` output); if overlap exists, it's called out and justified |
| References | Jira parent link; code paths from `code-scanner` if relevant |
| Structural integrity | Headings, `[[wikilinks]]` resolve; markdown well-formed |

**Verdict:** PASS / PASS WITH RECOMMENDATIONS / BLOCK. Same output shape as `doc-reviewer` and `code-review`.

---

## 10. Agent: `doc-fixer.md`

**Purpose:** Applies targeted fixes for BLOCKER and MAJOR findings produced by either `doc-reviewer` (product docs) or `epic-reviewer` (Epic drafts). Also applies fixes for violations reported by `docs-style-checker`. Analogous to `review-fixer.md`. Shared between `/impl:jira:docs` and `/impl:jira:epics`; the fixer is doc-type-agnostic because the finding schema (file, line, severity, description, suggested fix) is the same across reviewers.

**Model:** inherits session (no `model:` override in frontmatter). Mirrors `review-fixer` — fixes are targeted, no deep reasoning required.

**Tools:** Read, Glob, Grep, LS, Write, Edit

**Inputs:** File path(s), full reviewer output (or `docs-style-checker` output), severities to fix.

**Hard rules:**
- NEVER rewrite whole sections when only a targeted edit is needed.
- NEVER fix MINOR or NIT findings.
- NEVER modify files not referenced in the review findings.

---

## 10a. Agent: `doc-location-finder.md`

**Purpose:** Finds the right place(s) in a docs repository to write new or extended documentation. Returns a prioritised list of write targets with rationale; the main command confirms each with the user in `/impl:jira:docs` Phase 5.5.

**Model:** inherits session (no `model:` override in frontmatter). Heuristic + grep work, no deep reasoning needed.

**Tools:** Read, Glob, Grep, LS

**Inputs:**
```yaml
repo_root:         <absolute path to docs repo root>
feature_summary:   <2–4 sentences from jira-reader themes + VI goal>
diff_highlights:   <optional: key filenames/areas from diff-summarizer outputs to seed topical search>
```

**Process:**
1. Detect the docs tree root(s) — likely subdirectories: `docs/`, `content/`, `site/`, `website/`, `handbook/`, `guide/` — whichever contain the majority of `.md` files with frontmatter. Product docs repos often use product-flavoured names (e.g. a top-level directory per product variant); the agent discovers these by content-weight rather than relying on a fixed list.
2. Build a lightweight topical index: for each markdown page, read the frontmatter (`title`, `description`, `tags`) + H1/H2 headings (first 50 lines).
3. Score candidates by keyword overlap with `feature_summary` and `diff_highlights`.
4. Distinguish three placement kinds:
   - **extend-existing** — the feature naturally belongs in an existing page; add a section or edit content.
   - **new-page-in-existing-section** — the topic is new but its section/folder exists (e.g., a new "how-to" under `…/configure/`).
   - **new-section** — no adjacent content; a new folder + index page is justified.
5. If the feature has multiple natural homes (e.g., a Settings reference + a How-to page), propose multiple targets — each with its own kind and rationale.

**Output:**
```yaml
status: OK | LOW_CONFIDENCE | EMPTY
targets:
  - kind:      extend-existing | new-page-in-existing-section | new-section
    section:   <human-readable label, e.g. "Setup and configuration">
    path:      <absolute path; for extend-existing this is the existing file, for new-* this is the proposed new file>
    rationale: <1 sentence: why this location>
    linked_from: [<paths of pages that should cross-link to this, if any>]
confidence_notes: <when status == LOW_CONFIDENCE: what's ambiguous>
```

If multiple targets are returned, the caller prompts the user to accept all, or adjust individually.

---

## 10b. Agent: `doc-planner.md`

**Purpose:** Synthesises Jira data, diff summaries, and confirmed write targets into a documentation checklist that the writer follows and the reviewer checks against. Does NOT write content.

**Model:** inherits session (no `model:` override in frontmatter).

**Tools:** Read, Glob, Grep, LS

**Inputs:**
```yaml
jira_reader_handoff:    <full YAML from jira-reader>
diff_summaries:         <array of diff-summarizer outputs>
write_targets:          <confirmed list from doc-location-finder + user>
screenshots:            [<array of user-provided image paths, possibly empty>]
repo_root:              <absolute path>
```

**Process:**
1. For each write target, decide:
   - What topics the page must cover (how-to-use, how-to-configure, reference, migration/upgrade notes, what's new).
   - Which `jira-reader` items and which diff summaries source each topic.
   - What YAML frontmatter updates are needed (new page vs. extended page; `changelog:` entry with the Jira key; `published`, `tags`, `readtime`, `meta.generation` when relevant — detect existing conventions by sampling 2–3 adjacent pages).
   - Whether existing snippets apply (grep `_snippets/` for topical matches); whether new content should be extracted into a snippet for reuse.
   - **Detect the repo's image policy** (per target, or once per run if the policy is uniform across the repo). Sample 5–10 sibling pages under the target's folder and up to 3 ancestor folders; count markdown image references and classify each reference as:
     - `local` — reference is a relative path resolving inside the repo (e.g. `./img/foo.png`, `../images/bar.jpg`, `<page-dir>/img/...`); a matching file exists on disk.
     - `cdn` — reference is an absolute URL to an external host (e.g. `https://cdn.example.com/images/...`); no local file exists.
     - `wikilink` — `![[name.png]]` Obsidian-style (unlikely in a docs repo but possible).
     
     Then pick the policy:
     - If `local` count > 0 and `cdn` count is 0 (or negligible) → `image_policy: local` and identify the idiomatic directory (most common pattern across samples — typically `<page-dir>/img/` or `<page-dir>/images/`).
     - If `cdn` count > 0 and `local` count is 0 (or negligible) → `image_policy: cdn_upload_required` — the writer must NOT copy user-provided screenshots into the repo; they are staged outside the repo and surfaced in the Phase 9 report for manual upload to the repo's image-management tool (e.g. CDN, Image Manager, CMS).
     - Mixed or zero references → `image_policy: ambiguous` — the writer asks the user at Phase 6 which approach to use for this specific feature.
   - Whether any provided screenshot belongs on this page; the destination depends on `image_policy` (see output schema below).
   - Which cross-links should point to/from this page (including internal nav / sidebar files if the repo uses them).
2. Flag gaps the writer cannot fill from inputs alone (e.g., "feature requires a DB-migration note but no migration steps were found in Jira or diffs — user input needed").

**Output — the documentation checklist:**
```yaml
status:   OK | PARTIAL
checklist:
  - target_path: <absolute path>
    kind:        extend-existing | new-page-in-existing-section | new-section
    topics:
      - name:    <"How to use" | "Setup" | "Reference" | "Migration" | etc.>
        sources: [<Jira key | PR URL>, ...]
        notes:   <optional 1-line guidance for the writer>
    frontmatter_updates:
      changelog: {action: append, entry: "<YYYY-MM-DD> <1-line summary, ref <JIRA_KEY>>"}
      other:     {<field>: <value>, ...}   # only fields needing change
    snippets:
      reuse:   [<relative snippet path>]
      extract: [<description of content to extract + proposed snippet path>]
    image_policy: local | cdn_upload_required | ambiguous
    screenshots:
      - src:         <user-provided absolute path>
        # When image_policy == local:
        dest:        <absolute path under <page-dir>/img/ or the detected idiomatic directory>
        # When image_policy == cdn_upload_required:
        staging:     <absolute path under /tmp/<JIRA_KEY>-screenshots/ — NOT inside the repo>
        upload_note: <1-line instruction for the user, e.g. "Upload via <repo's image-management process>; replace placeholder URL in page">
        # When image_policy == ambiguous: both dest and staging are null; the writer prompts the user at Phase 6.
        alt:         <proposed alt-text>
    cross_links:
      from:  [<page paths that should link here>]
      to:    [<page paths this should link out to>]
gaps:
  - description: <what's missing from inputs>
    recommended_action: <"ask user" | "mark TODO in draft" | "skip with note in final report">
```

---

## 10c. Agent: `docs-style-checker.md`

**Purpose:** Runs the docs repo's project-configured prose linter on the files written by the main command, and returns violations in the same finding schema used by `doc-reviewer` / `doc-fixer`. Detects tooling from the repo; does not embed any specific style guide.

**Model:** inherits session (no `model:` override in frontmatter).

**Tools:** Read, Glob, Grep, LS, Bash

**Rationale:** Corporate style guides (Dynatrace, Microsoft, Google, and various organisation-specific variants) are encoded as Vale style packages maintained by each organisation's docs team, not by this plugin. The docs repo references them via `.vale.ini` (`BasedOnStyles = …`). Re-encoding or crawling the corporate style-guide site would duplicate the canonical source and drift. Wrapping the repo's existing tooling guarantees the local check matches what CI will run on the PR.

**Inputs:**
```yaml
repo_root: <absolute path>
files:     [<absolute paths of files written in Phase 6>]
```

**Process (priority order — first match wins):**
1. **Vale via `.vale.ini`** — if `<repo_root>/.vale.ini` exists, run `vale --output=JSON <files>` from the repo root. Parse the JSON output into finding records.
2. **Project-specific lint script** — if `package.json` has a script matching `*:lint` or `lint:*` that covers markdown (e.g., `docs:lint`, `site:lint`, `lint:md`, or any repo-local convention), run it on the repo. Parse stderr/stdout for line-level violations. If the script lints the whole tree, filter violations to the target files.
3. **Generic markdown linter** — if `.markdownlint.json(c)` or `.remarkrc*` exists and the binary is available, run it on the target files.
4. **Nothing configured** → return `status: NOT_CONFIGURED` with empty violations.

Each violation is normalised into:
```yaml
file:     <absolute path>
line:     <line number>
rule:     <linter rule identifier, e.g. "Microsoft.Acronyms" (from the public Vale Microsoft style) or "<ProjectStyle>.<RuleName>" for a project-local package>
severity: BLOCKER | MAJOR | MINOR | NIT      # map from linter severity: error→MAJOR, warning→MINOR, suggestion→NIT
message:  <human-readable description>
suggestion: <linter's proposed fix, if any>
```

**Output:**
```yaml
status:     OK | NOT_CONFIGURED | VIOLATIONS_FOUND | ERROR
linter:     vale | yarn:<script> | markdownlint | remark | none
command:    <exact command line executed, or null>
violations: [<array as above, may be empty>]
error:      <only when status == ERROR: one-line reason, e.g. "vale not on PATH">
```

**Hard rules:**
- NEVER promote a MINOR/NIT style finding to BLOCKER. The linter's own severity is authoritative.
- NEVER modify repo files. Output is advisory; fixes are applied by `doc-fixer`.
- NEVER run the whole-repo lint if a files-scoped invocation is available (performance + noise reduction).

---

## 11. Branch and write policy (Jira commands)

The two Jira commands have **different** branch/write policies — reflecting their distinct roles (see §2 role clarification). `/impl:jira:epics` never branches and never writes outside the vault. `/impl:jira:docs` writes to a docs repo and may branch+commit there.

### `/impl:jira:epics`

| Rule | Value |
|---|---|
| Required context | Running inside `$VAULT_PATH` (enforced in Phase 0) |
| Branch | NEVER |
| Commit | NEVER |
| Write target | `$VAULT_PATH/jira-drafts/<VI-KEY>/<NEW-EPIC-SLUG>.md` (default; user may override under `$VAULT_PATH`) |
| Forbidden write paths | `jira-products/`, `_archive/`, anything outside `$VAULT_PATH` |

Vault git hygiene is the user's responsibility — they may or may not have the vault under version control.

### `/impl:jira:docs`

Output is written to **cwd** (where the user invoked the command). Context is classified as follows:

| Detected context | Signals | Branch / commit |
|---|---|---|
| **Obsidian vault** | `.obsidian/` at any ancestor of cwd | NEVER branch, NEVER commit (treat like `/impl:jira:epics` hygiene) |
| **Docs git repo** | cwd is inside a git repo (`git rev-parse --show-toplevel` succeeds), no `.obsidian/` ancestor, AND at least one docs-repo signal from §6 Phase 0 is present | Branch = YES (opt-in confirmed at plan approval); commit = YES |
| **Non-docs git repo** | git repo but no docs signals | Phase 0 asks the user to confirm or cancel. If confirmed, behave as **Docs git repo**. |
| **Not in any git repo** | Neither condition above | NEVER branch, NEVER commit; write to cwd as plain files |

**Detection algorithm (sketch):**
```bash
# 1. Walk up from cwd looking for .obsidian/
dir="$(pwd)"
while [ "$dir" != "/" ]; do
  [ -d "$dir/.obsidian" ] && { context=obsidian; break; }
  dir="$(dirname "$dir")"
done

# 2. Otherwise check git repo + run docs-repo signal check (Phase 0)
if [ -z "$context" ] && git rev-parse --show-toplevel >/dev/null 2>&1; then
  repo_root=$(git rev-parse --show-toplevel)
  # 2a. Apply the §6 Phase 0 signal set: .docstack/, mkdocs.yml,
  #     docusaurus.config.js, antora.yml, .vale.ini, DOCUMENTATION-GUIDELINES.md,
  #     any _snippets/ directory, or a package.json with a script matching
  #     *:start, *:build, *:lint, docs:*.
  if has_any_docs_signal "$repo_root"; then
    context=docs_repo
  else
    context=non_docs_repo   # Phase 0 will prompt the user to confirm or cancel
  fi
fi

# 3. Plain dir otherwise
[ -z "$context" ] && context=plain_dir
```

The four-state output (`obsidian`, `docs_repo`, `non_docs_repo`, `plain_dir`) maps 1:1 to the four rows of the context table above. A `non_docs_repo` result triggers the confirm/cancel prompt in §6 Phase 0 before the command proceeds; if the user confirms, the command then behaves as a `docs_repo` for the remainder of the run.

When branching (docs git repo): see §6 Phase 6.5 for the full branch-setup procedure (fetch base, read CONTRIBUTION/README for naming conventions, confirm name). Fallback branch prefix when no convention is found: `docs/`.

Always show at plan approval: resolved absolute output path, detected context, whether branching+commit will happen.

---

## 12. Agent: `jira-reader.md`

**Purpose:** Reads the pre-exported Jira markdown hierarchy from the vault. Read-only — never modifies vault files.

**Model:** inherits session (no `model:` override in frontmatter).

**Tools:** Read, Glob, Grep, LS

**Inputs:**
```yaml
vault_path: <absolute path>
jira_key:   <e.g. JIRA-12345>
depth:      full | vi-plus-epics | vi-only
```

**Process:**

**Phase 0 — Validate `jira_key`.** Accept only `^[A-Z][A-Z0-9_]*-\d+$` (Jira key convention: uppercase letters / digits / underscores, a dash, digits). On mismatch, return `status: NOT_FOUND` with a clear message naming the invalid key — caller surfaces the Section 15 `Jira key dir not found` choices to the user.

1. Read `<vault_path>/jira-products/<jira_key>/<jira_key>-index.md`. **Header validation:** the first data table in the file must have header row `| Key | Type | Status | Summary | Role |` exactly. If the header differs (e.g. Jira-to-Obsidian exporter changed its output format), return `status: EMPTY` with a message naming the mismatched columns — do **not** try to parse rows with an unknown schema. Document the assumed exporter version in the plugin README.
2. If `depth: full` — for every linked item (including the root VI itself, which lives in its own sub-directory), read `<vault_path>/jira-products/<jira_key>/<LINKED_KEY>/<LINKED_KEY>.md`. For the VI itself, `<LINKED_KEY> == <jira_key>`, so the path resolves to `<vault_path>/jira-products/<jira_key>/<jira_key>/<jira_key>.md` (a nested same-named subdirectory — verified against real exports). Parse YAML frontmatter, extract the Description body, and collect PR URLs from the `## Pull Requests` section.
3. If `depth: vi-plus-epics` — read the VI's own file at `<vault_path>/jira-products/<jira_key>/<jira_key>/<jira_key>.md` **plus** every Epic `.md` directly linked to the VI (filter the linked-items table to `type == Epic`). Skip Stories, Sub-tasks, Research, Request for Assistance. This gives Epic-writing workflows enough context to extract meaningful themes for `code-scanner` without reading the entire hierarchy.
4. If `depth: vi-only` — read only the VI's own file at `<vault_path>/jira-products/<jira_key>/<jira_key>/<jira_key>.md` plus the index. Every linked item is nested under the root export directory; never look for `<vault_path>/jira-products/<LINKED_KEY>/<LINKED_KEY>.md` (that path does not exist).
5. Extract capability themes (2–4 short bullets summarizing recurring topics) for use by `code-scanner`. Themes may be sparse for `depth: vi-only`; callers that need richer themes should request `vi-plus-epics` or `full`.

**Ignored by default:** sibling `<KEY>-comments.md` files and `attachments/` sub-directories (case-insensitive — real exports use both lowercase `attachments/` and capitalised `Attachments/` depending on when the Jira item was created) inside each item's folder. Rationale: comments and image attachments are occasionally useful for decision-history context but are noisy, rarely authoritative for user-facing docs, and easy to revisit manually when needed. Keeping them out of the default read path also keeps `jira-reader` fast on large VIs. No user-facing toggle is provided in this iteration.

**PR URL formats to parse:**

Three host categories are recognised; anything else is recorded with `host: other` and is surfaced later by `diff-summarizer` as `unresolved`.

- **Cloud GitHub** (`host: github_cloud`) — hostname exactly `github.com`:
  ```
  https://github.com/<OWNER>/<REPO_NAME>/pull/<PR_ID>
  ```
- **Cloud Bitbucket** (`host: bitbucket_cloud`) — hostname exactly `bitbucket.org`:
  ```
  https://bitbucket.org/<WORKSPACE>/<REPO_NAME>/pull-requests/<PR_ID>
  ```
- **Self-hosted Bitbucket Server** (`host: bitbucket_server`) — hostname contains the substring `bitbucket` and is **not** `bitbucket.org`; the exact hostname is treated as opaque (no hardcoded domain):
  ```
  https://<bitbucket-server-host>/projects/<PROJECT_KEY>/repos/<REPO_NAME>/pull-requests/<PR_ID>
  ```

Also parse the `Branch:` line and status marker (`**MERGED**` / `**OPEN**` / `**DECLINED**`) — present in all three formats.

**`## Pull Requests` section markdown format** — the Jira-to-Obsidian exporter emits each PR as a **two-line bulleted item**, top-level bullet followed by an indented child bullet for the branch:

```markdown
## Pull Requests

- [<PR title>](<full PR URL>) **<STATUS>**
  - Branch: `<from-branch>` → `<to-branch>`
- [<next PR title>](<next PR URL>) **<STATUS>**
  - Branch: `<from-branch>` → `<to-branch>`
```

Non-obvious details when writing the parser:

- The branch names are **wrapped in backticks** and separated by ` → ` (Unicode U+2192 right arrow), **not** `->` ASCII. A regex like `Branch:\s*(\S+)\s*->\s*(\S+)` will capture the backticks and miss the Unicode arrow. Use: `` ^\s*-\s+Branch:\s+`([^`]+)`\s+→\s+`([^`]+)` ``.
- The status marker is always the **last token on the title line**, separated from the URL by a space. No status marker → treat as `UNKNOWN`.
- Empty or missing `## Pull Requests` section → `pull_requests: []` in the output, not an error.

**Output (structured handoff):**
```yaml
status: OK | EMPTY | NOT_FOUND
jira_key: <key>
value_increment:
  key:     <key>
  summary: <text>
  status:  <text>
  goal:    <2–3 sentence extraction from Description>
linked_items:
  - key: <key>
    type: ValueIncrement | Epic | Story | Sub-task | Research | "Request for Assistance"
    status: <text>
    summary: <text>
    parent: <key | null>
    role:   root | linked | epic_child
pull_requests:
  - url:         <full URL>
    host:        github_cloud | bitbucket_cloud | bitbucket_server | other
    repo:        <repo name extracted from URL>
    owner:       <for github_cloud: the <OWNER> segment; for bitbucket_cloud: the <WORKSPACE> segment; null otherwise>
    pr_id:       <id>
    status:      MERGED | OPEN | DECLINED | UNKNOWN
    source_item: <Jira key the URL was found in>
    title:       <link text from markdown>
    branch_from: <feature branch, from Branch: line>
    branch_to:   <target branch, from Branch: line>
themes:
  - <2–4 short bullet points summarising recurring topics across items>
```

---

## 13. Agent: `diff-summarizer.md`

**Purpose:** Reads a single code repository's PR diff and returns a documentation-focused summary. Designed for parallel invocation — one instance per repo, capped at 4 concurrent (see §6 Phase 5 / §7 Phase 5).

**Model:** inherits session (no `model:` override in frontmatter).

**Tools:** Read, Glob, Grep, LS, Bash

**Inputs:**
```yaml
repo_path:   <absolute, e.g. /repos/<repo-name>>
pr_refs:
  - url:         <full PR URL>
    host:        github_cloud | bitbucket_cloud | bitbucket_server | other
    repo:        <repo name>
    owner:       <github_cloud: <OWNER>; bitbucket_cloud: <WORKSPACE>; null otherwise>
    pr_id:       <id>
    branch_from: <feature branch from jira-reader>
    branch_to:   <target branch from jira-reader>
    title:       <link text>
    status:      MERGED | OPEN | DECLINED | UNKNOWN
context: |
  <what this repo's PRs relate to, for doc focus>
jira_keys_hierarchy:   # optional; passed by caller to enable Strategy 4 cross-key grep
  - <VI-KEY>
  - <every Epic/Story/Sub-task/Research/RFA/Bug key discovered by jira-reader>
refresh:
  fetch: true   # default true
  pull:  false  # default false — historical PR diffs do not need the current branch tip;
                # pulling risks moving HEAD away from the merge commit we want to reach.
                # (Asymmetry with code-scanner, which pulls by default — it targets present-day
                # capability scans. See §14.)
```

**Resolver selection by host:**

Before attempting any git operation, inspect `pr_refs[*].host` and route per-PR to the matching resolver. The rule is: **if the URL is on a cloud service AND an official CLI is available, use the CLI; otherwise fall back to pure-local-git strategies against the cloned repo.**

| Category | Detected by | Cloud CLI (preferred when installed + authenticated) | Fallback |
|---|---|---|---|
| `github_cloud` | `host == github.com` | **`gh` CLI** — `gh pr view --json headRefOid,baseRefOid,...` (see "GitHub resolver" below) | Local-git Strategies 1–4 (below) |
| `bitbucket_cloud` | `host == bitbucket.org` | **None yet** — Atlassian's official `acli` does not currently support Bitbucket (verified against ACLI v1.3.15 reference). A future iteration may adopt an official CLI when Atlassian ships one, or a vetted third-party tool (e.g. Appfire's Bitbucket Cloud CLI, the community `bkt`). Until then, no Cloud CLI is shipped or assumed. | Local-git Strategies 1–4 (below) |
| `bitbucket_server` | `host` contains `bitbucket` **and** is **not** `bitbucket.org` (treat the hostname as opaque — no host string is hardcoded in the plugin) | — | Local-git Strategies 1–4 (below) |
| `other` | anything else | — | Record as `unresolved` with `reason: unsupported host <host>`; caller escalates |

**Fallback semantics (per Q11 resolution):** when a cloud URL's preferred CLI is not installed or not authenticated on the host, the resolver silently falls back to the local-git strategies rather than failing. The repo must still be cloned under `<repos_base>/<REPO>` for the fallback to succeed; if it isn't, the per-PR result is `unresolved` with `reason: CLI not available and branch/merge-commit search did not resolve`.

**URL parse notes:**

- For **Bitbucket Server** URLs, extract **only** `<REPO_NAME>` for the local-lookup path `<repos_base>/<REPO_NAME>`. The `<PROJECT_KEY>` prefix identifies the Bitbucket project namespace on the server and plays no role in local resolution — do not confuse the two or try to match both.
- For **Bitbucket Cloud** URLs, the `<WORKSPACE>` segment is analogous to the Server `<PROJECT_KEY>` and is not used for local lookup.
- For **GitHub** URLs, `<REPO_NAME>` is the only piece used for the filesystem path; `<OWNER>` is passed to `gh --repo <OWNER>/<REPO>` but not used in the path.

**Local-git strategies (used for Bitbucket Server, Bitbucket Cloud when no CLI is available, and GitHub when `gh` is not available — all pure local git, no HTTPS calls):**

The default Bitbucket Server clone does **not** fetch `refs/pull-requests/*/from` refs — so Strategy 1 below is an optimistic first attempt that rarely hits unless the user has pre-configured the extra refspec and run `git fetch` manually. **Strategies 2 and 3 are the real workhorse** for these hosts; treat Strategy 1 as best-effort and fall through silently when it misses.

1. **Strategy 1 — Bitbucket Server PR refs (optimistic; usually absent).** Try `git rev-parse refs/pull-requests/<pr_id>/from`. If present, use as head; derive base via `git merge-base <target_branch> <head>`. If the ref does not exist (the default for a fresh clone), fall through to Strategy 2. Do **not** attempt to configure the refspec or fetch it at runtime — that is an explicit opt-in step for the user, not an automatic side effect. (On Bitbucket Cloud and GitHub clones these refs don't exist either — Strategy 1 simply no-ops and the resolver moves on.)
2. **Strategy 2 — Branch search.** `git branch -a --list "*<pr_id>*"` and `git branch -a --list "*<issue_key>*"`. If **exactly one** branch matches → use as head. If **0 matches** (branch was deleted after merge — common for merged PRs) or **2+ matches** (multiple revisions of the feature branch, or overlapping issue keys) → fall through silently to Strategy 3. Do not prompt the user here — the per-PR result is decided by the strategy chain; any remaining unresolved PRs are aggregated and surfaced once via §15's "All PRs unresolved" row.
3. **Strategy 3 — Merge-commit search.** `git log --all -E --grep="[Pp]ull[ _-]?[Rr]equest[ _-]?#?<pr_id>\b" -n 5` and `git log --all -E --grep="<title_keyword>" -n 5`. The primary pattern matches the merge-commit title format `Pull request #<PR_ID>: …` produced by both Bitbucket and GitHub (note the `#` separator — a previous draft used `pull[- ]request[- ]<pr_id>` which did not match). For a merge commit: head = `<commit>^2`, base = `<commit>^1`.
4. **Strategy 4 — Cross-hierarchy Jira-key commit search (last resort).** Accept an optional `jira_keys_hierarchy` input (passed from the caller: the VI key + every key discovered by `jira-reader` — Epics, Stories, Sub-tasks, Research, RFA, Bugs). For each key, run `git log --all --grep="<key>" --oneline`. The matches are treated as "commits associated with this feature" rather than a specific reconstructed PR. Return every match's full diff (`git show --format= <sha>`) as a **separate per-PR entry** with `pr_id: <the PR's own id, best-effort>` and `resolved_via: jira_key_commits`. Annotate the `summary` explicitly: *"Diff reconstructed from commit <sha> matched on Jira key <key>; this may not correspond to the original PR content exactly."*

   If the original PR's merge-commit and branch are both missing (Strategies 1–3 failed) but Strategy 4 finds commits by key: the PR is **partially resolved** — the content is drawn from key-matched commits, and the output notes this clearly.

   If `jira_keys_hierarchy` is not provided (caller didn't pass it), fall back to the original single-key behaviour (grep only the PR's own `source_item` key) and emit candidate SHAs in `unresolved_prs` for user review, as before.

If all strategies fail (including Strategy 4): record under `unresolved_prs` and continue (caller escalates).

**Note on non-MERGED PRs:** The default filter is MERGED-only. If the caller opts into OPEN / DECLINED / UNKNOWN PRs, expect a high rate of `unresolved`: DECLINED PRs often have no merge commit (Strategy 3 fails) and feature branches may have been deleted after decline (Strategy 2 fails). Surface the unresolved count clearly in `aggregate_summary` so the documentation writer knows what's missing.

**GitHub resolver (via `gh` CLI, used when `host == github_cloud` AND `gh` is installed + authenticated):**

1. **Resolve head/base SHAs.** Run `gh pr view <pr_id> --repo <owner>/<repo> --json headRefOid,baseRefOid,state,title,mergeCommit`. This is the single authoritative call. `gh` handles authentication via `gh auth login` (configured once on the host; see §17).
2. **Ensure commits are local.** If `headRefOid` or `baseRefOid` is missing from the local clone (`git cat-file -e <sha>` returns non-zero), run `git fetch origin <headRefOid> <baseRefOid>`. If fetch is rejected (server refuses direct-SHA fetch), fall back to `gh pr checkout <pr_id> --repo <owner>/<repo>` which fetches the branches.
3. **Produce diff.** `git diff <baseRefOid>..<headRefOid>`. Set `resolved_via: gh_cli`.
4. **Failure modes:** `gh` not installed → drop to local-git strategies (do NOT set REFRESH_BLOCKED — the fallback may still succeed). Not authenticated → same fallback. PR not found (deleted, private, wrong repo) → record in `unresolved_prs` with the gh error; do not fall back (the local repo won't have it either).

**Output:**
```yaml
status:   OK | REPO_MISSING | DIRTY_TREE | REFRESH_BLOCKED | NO_PRS_RESOLVED | PARTIAL
repo:      <short repo name — the basename of repo_path>
repo_path: <absolute path as received in input, so callers can reference the source tree>
per_pr:
  - pr_id: <id>
    resolved_via: pr_ref | branch_search | merge_commit | jira_key_commits | gh_cli | unresolved
    summary: |
      <prose; 3–8 sentences: new behavior, changed behavior, API surface.
      If resolved_via == jira_key_commits, the summary must note that the diff
      was reconstructed from commits matching a Jira key and may not exactly
      correspond to the original PR content.>
unresolved_prs:
  - pr_id: <id>
    reason: <why resolution failed>
    candidates: [<sha — first line, if Strategy 4 found any>]
aggregate_summary: |
  <1–2 paragraphs: what this repo contributed to the feature. If any non-MERGED PRs were
  in scope and ended up unresolved, state the count explicitly so the doc writer knows.>
```

---

## 14. Agent: `code-scanner.md`

**Purpose:** Scans a single code repo for existing capabilities and gaps relative to a set of themes from a Value Increment / Epic. Used for Epic writing where there are no PRs (feature not yet implemented). Designed for parallel invocation — one instance per repo, capped at 4 concurrent (see §7 Phase 5).

**Model:** inherits session (no `model:` override in frontmatter).

**Tools:** Read, Glob, Grep, LS, Bash

**Inputs:**
```yaml
repo_path:   <absolute, e.g. /repos/<repo-name>>
capability_themes:
  - <short phrase, e.g. "Auto-update scheduling" or "Config UI for rate limits">
context: |
  <3–5 sentences: VI goal, what the Epic-set is meant to achieve>
search_hints:
  symbols:  [<class/function names>]
  paths:    [<directory globs, e.g. "**/autoupdate/**">]
  keywords: [<grep keywords>]
refresh:
  switch_to_default_branch: true
  pull: true   # default true — capability scans target present-day code and want the
               # default-branch tip. (Asymmetry with diff-summarizer, which keeps
               # pull: false because it targets historical merged commits. See §13.)
```

**Process:**
1. Verify repo exists. If not → return `status: REPO_MISSING`.
2. Prep step: `git status --porcelain` → if dirty and refresh is true → return `status: DIRTY_TREE`. If refresh is true: resolve the default branch via `git symbolic-ref --short refs/remotes/origin/HEAD` (if unset, run `git remote set-head origin --auto` first; if still unset, try `main` then `master`); then `git switch <default-branch>` followed by `git pull --ff-only`. If the fast-forward pull fails (non-fast-forward, network error, authentication, or any other git error) → return `status: REFRESH_BLOCKED` with a one-line reason. If default-branch resolution itself fails after all fallbacks → return `status: REFRESH_BLOCKED` with reason `cannot resolve default branch`.
3. Scan — pure filesystem (`grep`/`glob`/`read`), no git involvement. For each theme: search by keywords, symbols, paths. Collect file paths and top-level symbols.
4. Read head (~80 lines) of top candidate files per theme to characterize the capability.
5. Classify each theme: `present` (clear existing implementation), `partial` (related but incomplete), `absent` (gap).

**Output:**
```yaml
status:    OK | PARTIAL | REPO_MISSING | DIRTY_TREE | REFRESH_BLOCKED | EMPTY
repo:      <short repo name — the basename of repo_path>
repo_path: <absolute path as received in input>
capability_map:
  - theme: <theme text>
    classification: present | partial | absent | error
    evidence:
      - path: <relative to repo>
        symbols: [<names>]
        note: <one-line characterisation>
    gap_summary: |
      <only when partial/absent — what's missing>
    error: <only when classification == error — one-line reason>
reusable_components: |
  <1–2 paragraphs: what existing code the new Epic can build on>
gap_summary: |
  <1–2 paragraphs: what needs to be implemented from scratch>
```

`PARTIAL` is returned when some themes completed successfully but at least one failed (e.g. permission error on a sub-tree, file-read error, timeout). Failing themes are marked `classification: error` in the `capability_map` with a one-line reason; the overall scan is not aborted. This mirrors `diff-summarizer`'s `PARTIAL` status so callers have a consistent recovery pattern.

---

## 15. Escalation rules (both Jira commands)

| Situation | Choices |
|---|---|
| `$VAULT_PATH` unset | "Set to detected path (Recommended)", "Enter manually", "Cancel" |
| Jira key dir not found | "Re-enter key", "Cancel" |
| Repo missing under `/repos/` | "Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Use different /repos path" |
| `git fetch` failed, `git pull --ff-only` refused, or any other refresh failure (status `REFRESH_BLOCKED` from `diff-summarizer` / `code-scanner`) | "Continue with current local state", "Skip this repo", "Cancel" |
| Working tree dirty in a repo the agent tried to refresh (status `DIRTY_TREE`) | "Stash changes and retry this repo", "Skip this repo", "Cancel" |
| `unresolved_prs` returned (some, not all) | "Show candidates and let me pick", "Skip this PR", "Skip this repo", "Cancel" |
| **All PRs across all repos unresolved** after every strategy (incl. Strategy 4 cross-key grep) | `["Proceed with Jira-only content (Recommended — writer/planner draw from jira-reader output; final report notes missing PR content)", "Review candidates one by one", "Cancel"]`. Presented **once** as an aggregate gate rather than per-PR, to avoid N clicks on a big VI. If selected, the writer and planner run without any diff summaries and the Phase 9 report lists every skipped PR with its unresolved reason. |
| Use case B with no repos derivable from index | "List repos to scan manually", "Proceed without code scan", "Cancel" |
| `doc-reviewer` or `epic-reviewer` BLOCK after one fix cycle | For each unresolved BLOCKER, ask individually: `["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]`. "Cancel" aborts. "Override" records the override + rationale in the Phase 9 `### Deferred items` section. "Defer" records the finding there without an override flag (for `/impl:jira:epics`, "Defer" means the finding goes into an Epic-refinement note in the draft). "Manual fix notes" lets the user type the fix text, which is then applied by `doc-fixer` in a bounded one-shot pass. |
| Output file already exists | "Write with -v2 suffix (Recommended — non-destructive)", "Append", "Overwrite", "Cancel" |

---

## 16. Success criteria

1. `/impl:code` on a code change produces a passing test for the new behavior before marking done — or, if no test framework is detected and the user explicitly selected the "Skip tests" path in Phase 3.5, the skip decision is logged in the Phase 5 report with the user-provided rationale.
2. `/impl:docs` on a simple doc change does not trigger tests, branching, or code review.
3. `/impl:jira:docs` on a VI key reads the vault markdown, summarizes merged PR diffs from local repos, writes traceable documentation, and passes doc-reviewer.
4. `/impl:jira:epics` on a VI key reads the vault markdown, scans code repos for reuse/gaps, writes child Epic drafts to `$VAULT_PATH/jira-drafts/<VI-KEY>/` with testable acceptance criteria, and passes `epic-reviewer`.
5. All existing regression baseline behavior from the original `/impl` is preserved unchanged.
6. All new/modified files follow existing `dev-workflows` plugin conventions.
7. `/impl <anything>` prints the dispatcher help page (listing the `/impl:*` variants plus `/vuln` / `/upgrade` under Related commands, with a migration note pointing 1.0.x muscle memory at `/impl:code <description>`) and stops without executing any workflow, without classifying, without branching, without invoking agents, and without touching git. This is a deliberate breaking change relative to 1.0.x; see the 1.1.0 `### Breaking changes` entry in `plugins/dev-workflows/CHANGELOG.md`.

---

## 17. Out of scope

- Standalone `/write-tests` command (test-writer is internal pipeline agent only)
- Direct HTTPS/REST calls to Bitbucket (Cloud or self-hosted Server) — all Bitbucket PR resolution is pure local git. At time of writing, Atlassian's official `acli` does not cover Bitbucket; when it does (or a vetted third-party CLI becomes the community standard), adding a Bitbucket Cloud resolver is a strictly additive change to the resolver table in §13.
- Direct HTTPS/REST calls to GitHub outside the `gh` CLI wrapper
- PR creation (branch + commit only; PR is a future task)
- Rewriting Jira items (jira-reader is read-only)
- Re-crawling / re-encoding external style-guide URLs (the docs-style-checker wraps the repo's existing Vale/lint tooling, which is the canonical source — see §10c rationale)
- Cloning missing repos (escalate to user instead)
- Git hosts whose hostname does not match `github.com`, `bitbucket.org`, or the self-hosted Bitbucket Server rule from §13 (hostname contains the substring `bitbucket` and is not `bitbucket.org`) — treated as `other` → `unresolved`; add a resolver in a future iteration
- Running `/impl:jira:docs` outside a docs repo (Phase 0 detects and asks the user to confirm or cancel)
- Running `/impl:jira:epics` outside the Obsidian vault (Phase 0 refuses; vault git management remains the user's responsibility)
- Changes outside `plugins/dev-workflows` (flag before touching)

### Environment prerequisites

- **`gh auth login`** — required once on the host to enable GitHub PR resolution. Without it, GitHub URLs fall back to local-git strategies against the cloned repo (no hard failure).
- **No Bitbucket CLI is required or assumed** in this iteration. Bitbucket Cloud and self-hosted Bitbucket Server URLs are resolved purely from the local clone.
- **`vale`** (optional but recommended) — when the target docs repo has `.vale.ini`, `docs-style-checker` will invoke `vale` to match what the repo's CI runs. If `vale` is not on PATH, the agent falls back to `yarn <project>:lint` (or similar) as defined in the repo's `package.json`. If neither is available, style checks are skipped and `doc-reviewer` is the only style gate.
- **Recommended environment: AI Container.** These commands work best when the agent is run inside the [ihudak/ai-containers](https://github.com/ihudak/ai-containers) environment, which:
  - Mounts `/repos` with all relevant code repositories already cloned, so the default `<repos_base>` just works.
  - Installs `gh` automatically.
  - Mounts `~/.config/gh` from the host, so `gh` authentication carries over transparently — `gh auth login` on the host is sufficient, no re-auth inside the container.

  Outside this environment the commands still function, but the user must manage `<repos_base>`, `gh` installation, and `gh auth login` themselves.

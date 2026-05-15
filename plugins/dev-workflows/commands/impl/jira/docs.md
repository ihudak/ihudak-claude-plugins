---
name: impl:jira:docs
description: Jira-driven feature-documentation workflow. Reads a Value Increment hierarchy from exported markdown, resolves PR diffs in parallel, synthesises product documentation, and gates on style-check and Opus doc review.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Generate product documentation for the Jira Value Increment: $ARGUMENTS

`/impl:jira:docs` is the **Jira-driven feature-documentation** workflow. Given a Jira Value Increment key, it reads the full Jira hierarchy from pre-exported markdown in the user's Obsidian vault, resolves PR URLs to local git repos, runs parallel PR-diff summaries, synthesises product documentation, runs style-check + Opus review gates, and writes the output to the current working directory (a product docs repository).

For small one-off doc edits, use `/impl:docs`. For writing child Epic drafts from a VI, use `/impl:jira:epics`.

Reference: model-routing rules live at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md`. The classification step below follows that file verbatim. Opus gates (`doc-reviewer`) are independent of the four-level classification.

---

## Phase 0 — Load and dispatch

1. **Resolve `$VAULT_PATH`.** Read the `VAULT_PATH` environment variable. If unset, ask:
   ```
   choices: ["Set to detected path (Recommended)", "Enter manually", "Cancel"]
   ```
   Validate that the resolved path exists and contains a `jira-products/` subdirectory. If not, stop with an error.

2. **Resolve `<JIRA_KEY>`** from `$ARGUMENTS`. Validate that `$VAULT_PATH/jira-products/<JIRA_KEY>/` exists. If not, stop with an error naming the missing directory.

3. **Docs-repo detection.** This command writes feature documentation into a product docs repository; running it outside such a repository is almost always a mistake. Detect signals in cwd's git root:
   - `package.json` with any script matching `*:start`, `*:build`, `*:lint`, `docs:*`, or
   - any of `.docstack/`, `mkdocs.yml`, `docusaurus.config.js`, `antora.yml`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, or
   - a `_snippets/` directory at any level under the repo root.

   If ≥ 1 signal is present → proceed silently.
   If 0 signals are present → ask:
   ```
   "No product-docs-repo signals detected in this working tree. The signals I checked:
    - package.json scripts matching *:start, *:build, *:lint, docs:*
    - .docstack/, mkdocs.yml, docusaurus.config.js, antora.yml, .vale.ini, DOCUMENTATION-GUIDELINES.md
    - any _snippets/ directory under the repo root
    None were found. Proceed anyway?"
   choices: ["Proceed — I confirm this is a docs repo", "Cancel — switch to a docs repo first"]
   ```
   Default = Cancel.

4. **Classify write context** for later branch/write decisions. Walk up from cwd looking for `.obsidian/`; if found, context = `obsidian`. Else if `git rev-parse --show-toplevel` succeeds AND at least one docs signal from step 3 is present, context = `docs_repo`. Else if `git rev-parse --show-toplevel` succeeds with no docs signals, context = `non_docs_repo` (step 3 has already asked the user; their confirmation promotes this to `docs_repo` behaviour). Else context = `plain_dir`.

   Record the resolved context — it drives Phase 6.5 (branch setup) and Phase 6 write rules.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess. This rule is absolute.**

Group questions where possible; use `choices` arrays; the last choice in every array MUST be `"Other… (describe)"`.

Ask about:

- **Output filename / sub-path under cwd** (default: `<KEY>-<slug>.md`; the `doc-location-finder` in Phase 5.5 may override this per target).
- **PR status filter**:
  ```
  choices: ["MERGED only (Recommended)", "All PRs (MERGED + OPEN + DECLINED)", "Specific list (you'll be prompted)", "Other… (describe)"]
  ```
- **Repo refresh policy**:
  ```
  choices: ["fetch only (Recommended)", "fetch + pull default branch", "no refresh", "Other… (describe)"]
  ```
  The `fetch only` default matches the `diff-summarizer` default (`refresh.fetch: true, refresh.pull: false`) — historical PR diffs don't need the current branch tip, and pulling risks moving HEAD away from the merge commit we want to reach.
- **Repos base path**. Detect `/repos` first (`[ -d /repos ]`). Ask:
  ```
  choices: ["Use /repos (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input and validate that at least one directory exists under it. Record the resolved path as `<repos_base>`.
- **Screenshots**:
  ```
  choices: ["No screenshots needed", "I'll provide screenshot paths (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "provide paths", take free-text accepting any absolute filesystem path (vault, `/tmp`, home, the docs repo). Accept multiple paths (one per line or space-separated). Validate each exists and has an image extension (`.png|.jpg|.jpeg|.gif|.svg|.webp`). The downstream `doc-planner` (Phase 5.7) detects the repo's `image_policy` and decides per screenshot whether the writer will copy it locally or stage it outside the repo for manual upload.

Also display (for user context):
- Resolved cwd absolute path
- Write context (`obsidian` / `docs_repo` / `non_docs_repo` / `plain_dir`)
- Whether branching will happen (only when context is `docs_repo` — confirmed at plan approval)
- Resolved `<repos_base>`
- Resolved `$VAULT_PATH` and `<JIRA_KEY>`

---

## Phase 1.5 — Classify

Jira-driven feature docs are typically **SIGNIFICANT** (large blast radius if wrong — published documentation). State the classification and a one-sentence reason.

SIGNIFICANT → no Opus planning (the Jira hierarchy + diff summaries *are* the plan); `doc-reviewer` gate is mandatory.

---

## Phase 2 — Plan + approval

Present a concise plan:

- Resolved `<JIRA_KEY>` and the `$VAULT_PATH/jira-products/<JIRA_KEY>/` path
- Output filename / path under cwd (from Phase 1)
- `<repos_base>` and the repos that will be examined (inferred from the `jira-reader` output in Phase 3; if Phase 3 hasn't run yet, list "TBD — resolved after Jira read")
- PR filter (MERGED only / all / specific)
- Parallelism plan (up to 4 `diff-summarizer` instances per batch; up to 4 repos per Agent message)
- Write context + whether branching will happen
- Screenshots provided (count + paths, or "none")

Ask:
```
"Documentation plan ready. What would you like to do?"
choices: ["Approve & continue (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → proceed to Phase 3
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarise what was planned

---

## Phase 3 — Read Jira hierarchy

Invoke `jira-reader` with `depth: full`:

→ Agent (subagent_type: "general-purpose"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/jira-reader.md`
  > (fall back to `~/.claude/agents/jira-reader.md` if installed at user level).
  > Then return the structured handoff for this brief:
  >
  > vault_path: [resolved $VAULT_PATH]
  > jira_key:   [resolved <JIRA_KEY>]
  > depth:      full"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the §15 `Jira key dir not found` choices (`["Re-enter key", "Cancel"]`) and act accordingly. On `OK`, store the handoff for downstream phases.

---

## Phase 4 — Resolve repos

From the `jira-reader` handoff `pull_requests` list:

1. Filter by `status` per the Phase 1 PR-status setting (default: MERGED only). This is the `pull_requests[].status` field, NOT the top-level `jira-reader` `status`.
2. Group the remaining PRs by `repo` (short repo name).
3. For each unique `repo`, check that `<repos_base>/<repo>` exists as a directory.
4. If any repos are missing, escalate using the §15 rules:
   ```
   choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Use different /repos path"]
   ```
   List the missing repos explicitly. "Skip" removes that repo's PRs from scope; "I'll clone it — wait" pauses the run until the user confirms the clone is done, then re-checks existence; "Use different /repos path" re-prompts for `<repos_base>` and re-validates.
5. If any PRs had `host: other` (unsupported host), record them as `unresolved` and carry them into the Phase 9 report; do not block.

---

## Phase 5 — Parallel diff summarisation

Spawn `diff-summarizer` instances in **batches of up to 4 concurrent agents** per Agent message. Wait for each batch to complete before spawning the next. If fewer than 4 repos remain, the final batch is smaller.

**Rationale:** Claude Code's practical parallel-subagent limit is ~4–5; going above that causes silent serialisation or rate-limiting. Capping at 4 makes runtime deterministic.

For each repo, in the same Agent message:

→ Agent (subagent_type: "general-purpose"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/diff-summarizer.md`
  > (fall back to `~/.claude/agents/diff-summarizer.md` if installed at user level).
  > Then summarise this repo's PRs for the brief:
  >
  > repo_path:   <repos_base>/<repo>
  > pr_refs:     [ ... full PR entries from jira-reader handoff, filtered to this repo ... ]
  > context:    |
  >   [1–2 sentences: VI goal + themes relevant to this repo]
  > jira_keys_hierarchy:
  >   [VI key + every linked_items key from jira-reader]
  > refresh:
  >   fetch: true
  >   pull:  [false if Phase 1 chose 'fetch only' (default) or 'no refresh'; true if 'fetch + pull default branch']"

After the batch returns, handle each per-repo status:

- `OK` / `PARTIAL` — store the output, continue.
- `REPO_MISSING` — should not happen at this stage (Phase 4 already checked). If it does, escalate per §15 "Repo missing".
- `DIRTY_TREE` — escalate:
  ```
  choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel", "Other… (describe)"]
  ```
- `REFRESH_BLOCKED` — escalate:
  ```
  choices: ["Continue with current local state", "Skip this repo", "Cancel", "Other… (describe)"]
  ```
- `NO_PRS_RESOLVED` — record all that repo's PRs as unresolved; continue.

After every batch completes, if **every PR across every repo** is unresolved, present a single aggregate gate (not per-PR):
```
choices: ["Proceed with Jira-only content (Recommended — writer/planner draw from jira-reader output; final report notes missing PR content)", "Review candidates one by one", "Cancel"]
```

---

## Phase 5.5 — Find documentation locations

Invoke `doc-location-finder`:

→ Agent (subagent_type: "general-purpose"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/doc-location-finder.md`
  > (fall back to `~/.claude/agents/doc-location-finder.md` if installed at user level).
  > Then find write target(s) for the brief:
  >
  > repo_root:       [cwd's git root, resolved in Phase 0]
  > feature_summary: [2–4 sentences combining jira-reader themes + value_increment.goal]
  > diff_highlights: [key filenames / symbols from the diff-summarizer per_pr summaries]"

Handle the return:

- **`status: OK`** with a populated `targets` list:
  ```
  choices: ["Accept all proposed locations (Recommended)", "Adjust individual locations (you'll be prompted per item)", "Cancel"]
  ```
- **`status: LOW_CONFIDENCE`** — display `confidence_notes` alongside the targets so the user sees what was ambiguous:
  ```
  choices: ["Adjust individual locations (Recommended)", "Accept all proposed locations", "Cancel"]
  ```
  (The default flips to "Adjust" because confidence is low.)
- **`status: EMPTY`** — skip the accept/adjust flow:
  ```
  choices: ["Specify locations manually (you'll be prompted)", "Cancel"]
  ```
  The manual path takes a free-text entry per target (`path` + `kind` + `section`) and validates path existence for `extend-existing` targets.

The confirmed target list (from any of the three paths above) is the **authoritative write-target set** for Phase 6 and is handed to `doc-planner` in Phase 5.7.

---

## Phase 5.7 — Plan the documentation

Invoke `doc-planner`:

→ Agent (subagent_type: "general-purpose"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/doc-planner.md`
  > (fall back to `~/.claude/agents/doc-planner.md` if installed at user level).
  > Then produce the documentation checklist for the brief:
  >
  > jira_reader_handoff: [paste full YAML from Phase 3]
  > diff_summaries:       [paste array of diff-summarizer outputs from Phase 5]
  > write_targets:        [paste confirmed list from Phase 5.5]
  > screenshots:          [user-provided paths from Phase 1, possibly empty]
  > repo_root:            [cwd's git root]"

Handle the `status` and `gaps`:

- **`status: OK`, `gaps: []`** → proceed to the approval prompt.
- **`status: OK` or `PARTIAL` with `gaps` entries** — for each gap, act on its `recommended_action`:
  - `"ask user"` → prompt inline **before** showing the checklist-approval choice. Free-text prompt scoped to the gap; feed the answer back to the planner via a single re-invocation (pass the user's answer as an additional `gap_resolution` field in the brief). If the user declines, fall back to `"mark TODO in draft"`.
  - `"mark TODO in draft"` → surface in the checklist display as a visible TODO; the writer at Phase 6 emits `<!-- TODO: … -->` markers. Does not block approval.
  - `"skip with note in final report"` → list in the checklist display; carry forward into the Phase 9 `### Skipped items`. Does not block approval.
- **`status: PARTIAL`** alone (without user-asked gaps) is presented to the user alongside the checklist so the approval decision is informed.

Present the checklist (with any gaps + dispositions):
```
choices: ["Approve & write (Recommended)", "Adjust (describe)", "Cancel"]
```

---

## Phase 6 — Write documentation

The main command writes the markdown following the `doc-planner` checklist. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5.7 already loaded.

For each target in the confirmed write-target list:

1. **Preserve any existing YAML frontmatter** on pages being extended. Never strip unknown fields.
2. **Add or update** the `changelog:` field per the planner's checklist (append a new dated entry naming the Jira key and a 1-line change summary). Create the field if it doesn't exist on an extended page.
3. **Update other frontmatter** the planner flagged: `published` (creation date on new pages), `meta.generation`, `readtime` (estimate from word count), `tags` (merge — don't duplicate), `owners` (leave to the user).
4. **Reuse snippets** per the checklist: for snippets listed under `snippets.reuse`, use the repo's include syntax rather than inlining content. For snippets listed under `snippets.extract`, create the new snippet file in the repo's idiomatic `_snippets/` location and reference it from the target page.
5. **Place screenshots** per each target's `image_policy`:
   - **`local`** → copy each user-provided `src` to the planner's `dest` path (typically `<page-dir>/img/` or the detected idiomatic directory). Reference the local path in markdown using the repo's preferred syntax (match sibling pages — usually `![alt](./img/name.png)` or similar).
   - **`cdn_upload_required`** → **do NOT copy user-provided screenshots into the repo.** Stage them at the planner's `staging` path (`/tmp/<JIRA_KEY>-screenshots/`). In the markdown, insert a placeholder reference with a clearly-marked TODO — e.g. `![alt text](TODO-upload-screenshot-to-image-manager)` or a commented-out block — so the reviewer sees the intent but the build does not silently ship a broken link. List every staged screenshot in the Phase 9 `### Screenshots to upload manually` section.
   - **`ambiguous`** → ask the user at this step, per target:
     ```
     choices: ["Use local path <page-dir>/img/ (Recommended if this repo uses local images)", "Stage for manual upload to the repo's image-management tool", "Skip this screenshot", "Other… (describe)"]
     ```
     Apply the chosen branch.
6. **Traceability** — every claim must cite the originating Jira key (e.g. `[[<JIRA_KEY>]]`) and/or PR URL inline. When a claim comes only from imported Jira content (no PR resolved), cite the Jira key alone.

Write to cwd. Branch and commit policy is governed by the write context (Phase 0 step 4):

| Write context | Branch | Commit |
|---|---|---|
| `obsidian` | NEVER | NEVER |
| `docs_repo` | YES (opt-in confirmed at plan approval) — see Phase 6.5 | YES |
| `non_docs_repo` | Phase 0 step 3 already asked user to confirm; if confirmed, behave as `docs_repo` | YES (if user confirmed at Phase 0) |
| `plain_dir` | NEVER | NEVER |

---

## Phase 6.5 — Branch setup (conditional)

Run this phase only when write context = `docs_repo` (or `non_docs_repo` after user confirmed at Phase 0 step 3) AND the user confirmed branching at plan approval. Never for `obsidian` or `plain_dir`.

1. **Update the base branch.** Resolve the default branch by running `git symbolic-ref --short refs/remotes/origin/HEAD`; this returns the remote's default (`main` or `master`; legacy repos frequently still use `master`). If the command fails (unset `origin/HEAD`), run `git remote set-head origin --auto` and retry; if it still fails, try `main`, then `master`, in that order. If the user picked a `release/*` branch earlier in Phase 1, use that instead. Once the base is resolved: `git fetch origin` → `git switch <base> && git pull --ff-only`. If the fast-forward pull fails:
   ```
   choices: ["Stash local changes and continue (Recommended)", "Proceed from current base state", "Cancel"]
   ```

2. **Clean-tree check.** `git status --porcelain`; if non-empty:
   ```
   choices: ["Stash changes and continue (Recommended)", "Proceed anyway — pre-existing changes will appear in the diff", "Cancel"]
   ```

3. **Derive branch name from repo conventions.** In priority order, look at repo root for `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `DOCUMENTATION-GUIDELINES.md`. Grep each for a branch-naming section (case-insensitive, patterns like "Branch name", "Branch naming", "naming your branch"). If a pattern like `<user>/<JIRA-KEY>-<slug>` or `<prefix>/<name>` is documented, derive the branch name by filling placeholders with known values (Jira key from Phase 0, slug from the feature summary, `<user>` from `git config user.name` or its initials). If multiple patterns are documented, offer them all to the user.

4. **Confirm the branch name** — always, even when derived from conventions (initials and slugs are subjective):
   ```
   choices: ["Use proposed name: <name>", "Edit name (you'll be prompted)", "Cancel"]
   ```
   Fallback default when no convention is found: `docs/<jira-key>-<slug>`.

5. **Create the branch.** `git switch -c <name>`.

No external CLI calls; all git operations are local.

---

## Phase 6.7 — Style check (before reviewer)

Invoke `docs-style-checker` on the files written in Phase 6:

→ Agent (subagent_type: "general-purpose"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/docs-style-checker.md`
  > (fall back to `~/.claude/agents/docs-style-checker.md` if installed at user level).
  > Then run the style check for this brief:
  >
  > repo_root: [cwd's git root]
  > files:     [absolute paths of every file written or modified in Phase 6]"

Act on the return:

- **`status: NOT_CONFIGURED`** — no repo linter detected. Fall back to `dt-style-checker` (Dynatrace corporate style guide):

  → Agent (subagent_type: "general-purpose"):
    > "Read and adopt the system prompt at `~/.claude/plugins/data/dt-style-guide@ihudak-claude-plugins/agents/dt-style-checker.md`
    > (fall back to `~/.claude/agents/dt-style-checker.md` if installed at user level).
    > Then run the style check for this brief:
    >
    > files:    [absolute paths of every file written or modified in Phase 6]
    > doc_type: product-docs"

  Act on the `dt-style-checker` return identically to `docs-style-checker` (OK → Phase 7, VIOLATIONS_FOUND → `doc-fixer` + one re-run, ERROR → ask user). If `dt-style-checker` is also unavailable (agent file not found), proceed to Phase 7; `doc-reviewer` will still check correctness/completeness.
- **`status: OK`** — linter ran, zero violations. Proceed to Phase 7.
- **`status: VIOLATIONS_FOUND`** — invoke `doc-fixer` with the violations treated as per their severity. After `doc-fixer` completes, re-run the linter once:

  → Agent (subagent_type: "general-purpose"):
    > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/doc-fixer.md`
    > (fall back to `~/.claude/agents/doc-fixer.md` if installed at user level).
    > Then fix the style violations for this brief:
    >
    > Task description: [doc writing for <JIRA_KEY>]
    > Reviewer or style-checker output: [paste full docs-style-checker output]
    > Project root: [cwd's git root]
    > Severities to fix: BLOCKER and MAJOR"

  If violations remain after the re-run:
  ```
  choices: ["Proceed to review anyway — reviewer may still PASS", "Show remaining violations and let me fix manually", "Cancel"]
  ```

- **`status: ERROR`** — surface the error reason and ask:
  ```
  choices: ["Proceed to review without style check", "Cancel and fix locally"]
  ```

---

## Phase 7 — Doc review gate

Invoke `doc-reviewer` (Opus). The reviewer is **product-docs-only**; Epic drafts go through `epic-reviewer` in `/impl:jira:epics`.

→ Agent (subagent_type: "general-purpose", model: "opus"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/doc-reviewer.md`
  > (fall back to `~/.claude/agents/doc-reviewer.md` if installed at user level).
  > Then review the written product documentation for this brief:
  >
  > Task description: [one-paragraph summary of the feature and <JIRA_KEY>]
  > Written doc file paths: [absolute paths of every file written in Phase 6]
  > Jira directory path:    [$VAULT_PATH/jira-products/<JIRA_KEY>/]
  > Diff summaries:         [array of diff-summarizer outputs from Phase 5]
  > doc-planner checklist:  [the full YAML from Phase 5.7]
  > style-check report: [the violations output from Phase 6.7 — from docs-style-checker or dt-style-checker (fallback), or 'status: NOT_CONFIGURED' if neither ran]"

Act on the verdict:

- **BLOCK** — invoke `doc-fixer` with `Severities to fix: BLOCKER and MAJOR`. Re-invoke `doc-reviewer` once. If the second verdict is still BLOCK, escalate for each unresolved BLOCKER individually per §15:
  ```
  choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]
  ```
  "Manual fix notes" → take free-text from the user; apply via `doc-fixer` in a bounded one-shot pass (no further re-review cycle). "Defer" → record in Phase 9 `### Deferred items` without an override flag. "Override" → record in `### Deferred items` with the user's rationale. "Cancel" aborts.

- **PASS WITH RECOMMENDATIONS** — invoke `doc-fixer` for MAJOR findings only:

  → Agent (subagent_type: "general-purpose"):
    > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/doc-fixer.md`
    > (fall back to `~/.claude/agents/doc-fixer.md` if installed at user level).
    > Then fix the review findings for this brief:
    >
    > Task description: [doc writing for <JIRA_KEY>]
    > Reviewer or style-checker output: [paste full doc-reviewer output]
    > Project root: [cwd's git root]
    > Severities to fix: BLOCKER and MAJOR"

  MINOR / NIT findings are deferred to the Phase 9 report.

- **PASS** — proceed to Phase 8.

Cap: one fix cycle + one re-review maximum.

---

## Phase 8 — Post-implementation maintenance

First gather the change context:

a. Run `git diff --stat` against the base branch (if branching happened at Phase 6.5) or against HEAD (if no branching) and capture the list of changed files.
b. Compose a **change summary block**:

```
Implementation: [one-sentence description of what was documented, naming <JIRA_KEY>]
Change type: docs
Classification: SIGNIFICANT
Files changed (from git diff --stat):
<paste the git diff --stat output>
Notable additions/removals: [new pages, new sections, new snippets, new cross-links, restructured navigation — one line each; or "none"]
Doc-review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
```

Then spawn all four Phase 4-style maintenance agents in a **single Agent message**. They are independent and run concurrently.

**Agent 1 — Documentation** (general-purpose):
> "Post-write documentation review. Change summary:
> [paste change summary block]
>
> Scan for README.md, CHANGELOG.md, docs/, or any .md files in the project root or an adjacent docs tree.
> Determine if *other* documentation needs updating as a consequence of this write (e.g., an index page, a cross-referenced overview, a changelog entry in the repo root, a release-notes file).
> - Skip if: the edit is confined to the intended target pages with no inbound cross-references.
> - Update if: new page requires an index/sidebar entry, new sections require inbound cross-links, new snippet file needs a release-notes mention.
> If an update is warranted: apply minimal edits to the relevant section(s).
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose):
> "Post-write knowledge review. Change summary:
> [paste change summary block]
>
> Check ~/.claude/memory/ (global) and .claude/memory/ (project-level, preferred for repo-specific knowledge) for existing knowledge files.
> Determine if a new knowledge entry is warranted — look for: reusable insights about this docs repo's conventions, non-obvious style rules uncovered, Vale / lint interactions, snippet patterns, image-policy discoveries.
> If YES: append to the most appropriate existing file (never create a new file if an existing one fits) using this format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the Jira key + feature summary]
> Return: file updated/created and summary of entry, OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-write instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any doc-writing rules, guidance, or guardrails are missing because of what this run revealed (e.g., a repo-specific frontmatter field that must always be present, a cross-link pattern that's easy to miss, an image-policy rule that caught you out).
> Skip if: the run followed existing conventions with no surprises. Only update if a concrete, recurring rule would have prevented a decision point or misunderstanding.
> If YES: apply minimal, additive, scoped changes only — do not rewrite sections wholesale.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (general-purpose):
> "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/impl-maintenance.md`
> (fall back to `~/.claude/agents/impl-maintenance.md` if installed at user level).
> Then analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /impl:jira:docs
> - What was done: [one-paragraph summary of the documentation produced]
> - Key events: [BLOCK reviews encountered and their reason, ambiguous image policies, unresolved PRs, style-check failures, branch-naming conflicts — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
> - Test result: N/A (no tests in /impl:jira:docs)
> - Project root: [cwd's git root]"

Collect all four summaries for the Phase 9 report.

---

## Phase 9 — Final Report

Output a structured report — do NOT ask any closing confirmation:

```
## Jira-driven Documentation Report

### Classification
SIGNIFICANT — Jira-driven feature documentation has large blast radius if wrong

### Jira hierarchy summary
- VI: [<KEY>] [summary, 1 line]
- Linked items: [count by type — e.g. "3 Epics, 7 Stories, 2 Sub-tasks, 1 Research"]
- Themes: [2–4 bullet points from jira-reader]

### Repos analysed
- <repos_base>/<repo-1> — [N PRs in scope, M resolved, K unresolved]
- ...

### PRs in scope
- [PR URL] — status: [MERGED | OPEN | DECLINED | UNKNOWN], resolved_via: [pr_ref | branch_search | merge_commit | jira_key_commits | gh_cli | unresolved]
- ...

### Output file(s)
- [absolute path] — [kind: extend-existing | new-page-in-existing-section | new-section]
- ...

### Branch
[branch name created in Phase 6.5, e.g. docs/<jira-key>-<slug>] OR "N/A — no branch created (context: obsidian / plain_dir / user declined branching)"

### Doc review verdict
[PASS | PASS WITH RECOMMENDATIONS | BLOCK] — [1-line summary of findings applied / deferred]

### Documentation (Agent 1)
- [file updated] — [what was added/changed] OR "no update required (reason)"

### Knowledge base (Agent 2)
- [file updated/created] — [summary of entry] OR "no update required"

### Instructions (Agent 3)
- [summary of change] OR "no update required"

### Session learnings (Agent 4)
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Screenshots to upload manually
[Only populated when any target used image_policy: cdn_upload_required (or the user selected "Stage for manual upload" under the ambiguous branch). For each staged screenshot: src (original user-provided path), staging path under /tmp/<JIRA_KEY>-screenshots/, the target page it belongs on, the proposed alt-text, and the upload_note from the planner. Omit this section entirely when no screenshots were staged.]

### Skipped items
[Gaps the planner flagged with recommended_action: "skip with note in final report" — one line each; or "none"]

### Deferred items
[MINOR / NIT findings that were not applied, OR user-declined screenshots, OR doc-reviewer BLOCK findings that were overridden / deferred — one line each; or "none"]

### Assumptions & limitations
- [list any]

### Git state
[If branching happened: "Branch <name> created with N commits. Push when ready." If no branching: "Working tree has uncommitted changes. /impl:jira:docs writes but does not commit in non-git contexts."]
```

---

## Invariants (always enforced)

- ALWAYS run Phase 0 docs-repo detection; if 0 signals, require user confirmation before proceeding
- NEVER call Bitbucket REST APIs for Cloud or self-hosted Server — Bitbucket URLs are identifiers only; all resolution is pure local git
- GitHub URLs may use the `gh` CLI for head/base SHA resolution; no direct REST calls outside `gh`
- NEVER write inside `_archive/` — that path is read-only by convention
- NEVER write inside `jira-products/` — that path is re-created from scratch on every Jira import; writes there will be lost
- NEVER write outside cwd unless the user provides an explicit absolute path at Phase 5.5
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS invoke `docs-style-checker` (Phase 6.7) before `doc-reviewer` (Phase 7)
- ALWAYS invoke `doc-reviewer` before Phase 8 maintenance
- ALWAYS cap review/fix cycles: 1 fix + 1 re-review max
- ALWAYS pass `Change type: docs` in the Phase 8 change summary block
- ALWAYS pass `Command run: /impl:jira:docs` in the Phase 8 Agent 4 session handoff
- ALWAYS spawn Phase 8 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 9 report as the final output
- ALL written claims must be traceable to Jira keys or PR diffs; if only Jira is available, cite the Jira key alone
- For `image_policy: cdn_upload_required`, NEVER copy user-provided screenshots into the repo — stage at `/tmp/<JIRA_KEY>-screenshots/` and surface in the Phase 9 `### Screenshots to upload manually` section

---
name: impl:jira:docs
description: Jira-driven feature-documentation workflow. Reads a Value Increment hierarchy from exported markdown, resolves PR diffs in parallel, synthesises product documentation, and gates on style-check and Opus doc review.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Generate product documentation for the Jira Value Increment: $ARGUMENTS

`/impl:jira:docs` is the **Jira-driven feature-documentation** workflow. Given a Jira Value Increment key, it reads the full Jira hierarchy from pre-exported markdown in the user's Obsidian vault, resolves PR URLs to local git repos, runs parallel PR-diff summaries, synthesises product documentation, runs style-check + Opus review gates, and writes the output to the current working directory (a product docs repository).

For small one-off doc edits, use `/impl:docs`. For writing child Epic drafts from a VI, use `/impl:jira:epics`. For release notes, use `/impl:jira:release-notes` — this command never writes release-notes / what's-new pages, because those are generated from Jira by the docs team's automation.

---

## Phase 0 — Load and dispatch

1. **Resolve `$VAULT_PATH`.** Read the `VAULT_PATH` environment variable. If unset, ask:
   ```
   choices: ["Set to detected path (Recommended)", "Enter manually", "Cancel"]
   ```
   Validate that the resolved path exists and contains a `jira-products/` subdirectory. If not, stop with an error.

2. **Resolve `<JIRA_KEY>`** from `$ARGUMENTS`. Validate that `$VAULT_PATH/jira-products/<JIRA_KEY>/` exists. If not, stop with an error naming the missing directory.

3. **Resolve the docs repo (cwd-preferred).** This command writes feature documentation into a product docs repository; running it outside such a repository is almost always a mistake. The **docs signals** checked throughout this step are:
   - `package.json` with any script matching `*:start`, `*:build`, `*:lint`, `docs:*`, or
   - any of `.docstack/`, `mkdocs.yml`, `docusaurus.config.js`, `antora.yml`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, or
   - a `_snippets/` directory at any level under the repo root.

   Resolve `docs_repo_path` in this order:

   - **(a) cwd with signals (preserves today's behavior).** Resolve cwd's git root (`git rev-parse --show-toplevel`). If it succeeds **and** ≥ 1 docs signal is present there → `docs_repo_path` = that git root and proceed silently. This keeps every downstream phase that assumes cwd correct.
   - **(b) Search for a dynatrace-docs clone.** Else, look under `${REPOS_PATH:-/workspace}` (single dir or colon-separated list) for a `dynatrace-docs` checkout: a top-level directory either named `dynatrace-docs`, or a git root that contains both `dynatrace/_content` and `managed/docstack.jsonc`. If exactly one matches → `docs_repo_path` = that path. If several match, list them and ask which to use (`choices` array, recommended first, last item `"Other… (describe)"`).
   - **(c) Ask.** Else, ask:
     ```
     "No product-docs-repo signals in this working tree and no dynatrace-docs clone found under ${REPOS_PATH:-/workspace}. The signals I checked in cwd:
      - package.json scripts matching *:start, *:build, *:lint, docs:*
      - .docstack/, mkdocs.yml, docusaurus.config.js, antora.yml, .vale.ini, DOCUMENTATION-GUIDELINES.md
      - any _snippets/ directory under the repo root
      Where should I write the documentation?"
     choices: ["Use cwd anyway — I confirm this is a docs repo (Recommended)", "Enter the docs repo path", "Cancel — switch to a docs repo first", "Other… (describe)"]
     ```
     "Use cwd anyway" sets `docs_repo_path` = cwd's git root (or cwd if not a git tree) and carries the user's confirmation forward. "Enter the docs repo path" takes a free-text absolute path and validates it exists.

   **Confirm writeable.** Once `docs_repo_path` is resolved, run `test -w <docs_repo_path>`. If it fails, stop with the named error `REPO_NOT_WRITEABLE: <docs_repo_path> is not writeable.`

4. **Recognize dynatrace-docs.** Set `is_dynatrace_docs` = `true` when the resolved `docs_repo_path` contains **both** `managed/docstack.jsonc` and `dynatrace/_content/` and — when a git remote is available (`git -C <docs_repo_path> remote get-url origin`) — its slug (last path segment, trailing `.git` stripped) is `dynatrace-docs`. Directory name alone is **not** sufficient; the signals decide.

5. **Resolve the profile** (record `profile_source`). The profile steers all later phases' conventions. Resolve in this order:
   - **(a) In-repo profile →** `in-repo`. If `<docs_repo_path>/.dev-workflows/docs-profile.yml` exists, load it. `profile_source: in-repo`.
   - **(b) dynatrace-docs built-in default →** `built-in`. Else, if `is_dynatrace_docs`, load `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/docs-profile.default.yml`. `profile_source: built-in`.
   - **(c) Custom repo, no profile →** `generated`. Else (a custom docs repo with no profile), run **inline on-demand profiling**: invoke the `/impl:docs:profile` flow against `docs_repo_path` (Skill tool, `skill: "dev-workflows:impl:docs:profile"`, with `docs_repo_path` as its argument) and wait for it to write `<docs_repo_path>/.dev-workflows/docs-profile.yml`. Then load that file. `profile_source: generated`. If the user cancels profiling (it produces no profile), stop with the named error `PROFILE_REQUIRED: a docs-profile is required to write into a custom docs repo; run /impl:docs:profile or switch to a profiled repo.`

   Hold the loaded profile for later phases.

6. **Discover the specs dir.** Specs are additive context, not a prerequisite. Under `${REPOS_PATH:-/workspace}` (single dir or colon-separated list), look for a sibling directory whose detected **vis-root** (a `specifications/` or `vis/` subdirectory) contains a folder matching `<JIRA_KEY>*` (prefix match; tolerate mixed `-`/`_` separators and a trailing slug, e.g. `PRODUCT-14902-foo` or `PRODUCT_14902_foo`):
   - **Found →** record `specs_dir` = the matching `<JIRA_KEY>*` folder's absolute path.
   - **Not found →** `specs_dir: none`; **proceed** (do NOT stop — specs are optional).
   - **Multiple candidate sibling repos match →** list them and ask which to use:
     ```
     choices: ["<first candidate> (Recommended)", "<other candidates…>", "None — proceed without specs", "Other… (describe)"]
     ```

7. **Classify write context** for later branch/write decisions — computed against the resolved `docs_repo_path` (not necessarily cwd). Walk up from `docs_repo_path` looking for `.obsidian/`; if found, context = `obsidian`. Else if `git -C <docs_repo_path> rev-parse --show-toplevel` succeeds AND at least one docs signal from step 3 is present, context = `docs_repo`. Else if it succeeds with no docs signals, context = `non_docs_repo` (step 3 has already asked the user; their confirmation promotes this to `docs_repo` behaviour). Else context = `plain_dir`.

   Record the resolved context — it drives Phase 6.5 (branch setup) and Phase 6 write rules. When `docs_repo_path` differs from cwd, record **both** and note that the writing phases (Increments 2–3) consume `docs_repo_path`, not cwd, for every write.

### Readiness

Before clarification, show a readiness table summarizing what Phase 0 resolved:

| Item | Resolved |
|---|---|
| Vault + Jira | `$VAULT_PATH` ok; `jira-products/<JIRA_KEY>/` ok |
| Docs repo | `<docs_repo_path>` (`is_dynatrace_docs`: yes/no) — write context `<obsidian \| docs_repo \| non_docs_repo \| plain_dir>` |
| Profile | `profile_source`: `<in-repo \| built-in \| generated>` |
| Specs | `<specs_dir>` or `none` |
| Code repos | resolved later in Phase 4 (slug→clone match under `$REPOS_PATH`) |

All discovery defaults to `/workspace` (`${REPOS_PATH:-/workspace}`); on a host, or when a path is missing, the command asks rather than guessing.

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
- **Repos search base (`$REPOS_PATH`)**. Read `${REPOS_PATH:-/workspace}` (the container mounts every repo under `/workspace`). `$REPOS_PATH` may be a single directory or a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input (single dir or colon-separated list) and validate that at least one directory exists under it. Record the resolved value as `$REPOS_PATH`. Individual clones are located in Phase 4 by matching their `git remote` against each PR's repo slug — not by assuming a `<base>/<slug>` directory name.
- **Screenshots**:
  ```
  choices: ["No screenshots needed", "I'll provide screenshot paths (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "provide paths", take free-text accepting any absolute filesystem path (vault, `/tmp`, home, the docs repo). Accept multiple paths (one per line or space-separated). Validate each exists and has an image extension (`.png|.jpg|.jpeg|.gif|.svg|.webp`). The downstream `doc-planner` (Phase 5.7) detects the repo's `image_policy` and decides per screenshot whether the writer will copy it locally or stage it for manual upload.

  **Resolve `<screenshot_staging_dir>` (only when screenshots were provided).** For the `cdn_upload_required` case the staged copies must live somewhere that survives a container restart — `$VAULT_PATH` is always host-mounted, the docs repo (often a docker repo-volume) and `/tmp` are not. Find the ticket's persistent Obsidian project folder:
  ```bash
  find "$VAULT_PATH/Projects" -maxdepth 5 -type d -name "<JIRA_KEY>*" 2>/dev/null | head -1
  ```
  - **Found** → set `<screenshot_staging_dir>` to that project folder's screenshot subfolder: prefer an existing `Doc screenshots/` or `Attachments/` subdirectory; otherwise `Doc screenshots/` (created on first write).
  - **Not found** (e.g. a non-`PRODUCT-` ticket with no project folder) → ask:
    ```
    choices: ["Enter an absolute directory under $VAULT_PATH (you'll be prompted)", "Skip — only needed if the docs repo turns out to be cdn_upload_required", "Cancel", "Other… (describe)"]
    ```
    Reject `/tmp` and any path inside the docs repo. Record the result as `<screenshot_staging_dir>` (or null if skipped).

Also display (for user context):
- Resolved cwd absolute path
- Write context (`obsidian` / `docs_repo` / `non_docs_repo` / `plain_dir`)
- Whether branching will happen (only when context is `docs_repo` — confirmed at plan approval)
- Resolved `$REPOS_PATH`
- Resolved `$VAULT_PATH` and `<JIRA_KEY>`

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of: `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK`. Jira-driven feature docs are typically **SIGNIFICANT** (large blast radius if wrong — published documentation). State the classification and a one-sentence reason.

SIGNIFICANT → no Opus planning (the Jira hierarchy + diff summaries *are* the plan); `doc-reviewer` gate is mandatory.

---

## Phase 2 — Plan + approval

Present a concise plan:

- Resolved `<JIRA_KEY>` and the `$VAULT_PATH/jira-products/<JIRA_KEY>/` path
- Output filename / path under cwd (from Phase 1)
- `$REPOS_PATH` and the slug→clone resolution for the repos that will be examined (inferred from the `jira-reader` output in Phase 3; if Phase 3 hasn't run yet, list "TBD — resolved after Jira read")
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

→ Agent (subagent_type: "dev-workflows:jira-reader"):
  > "Return the structured handoff for this brief:
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
3. Build a slug→clone map. For each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote` call fails/times out. Result: `<slug> → [<absolute path>, ...]`.
4. Resolve each unique in-scope `repo` slug against the map:
   - **One match** — use that absolute path as `repo_path`.
   - **Multiple matches** (e.g. `cluster` and `cluster-repo`, both pointing at the same upstream) — auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last; show all candidates at plan approval so the user can override.
   - **Zero matches** — escalate using the §15 rules:
     ```
     choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]
     ```
     List the unresolved slugs explicitly. "Skip" removes that repo's PRs from scope; "I'll clone it — wait" pauses until the user confirms the clone is present under `$REPOS_PATH`, then re-runs step 3; "Specify a different absolute path" records the path directly as `repo_path` for that slug.
   Record the resolution as `repo_slug → repo_path` for Phase 5.
5. If any PRs had `host: other` (unsupported host), record them as `unresolved` and carry them into the Phase 9 report; do not block.

---

## Phase 5 — Parallel diff summarisation

Spawn `diff-summarizer` instances in **batches of up to 4 concurrent agents** per Agent message. Wait for each batch to complete before spawning the next. If fewer than 4 repos remain, the final batch is smaller.

**Rationale:** Claude Code's practical parallel-subagent limit is ~4–5; going above that causes silent serialisation or rate-limiting. Capping at 4 makes runtime deterministic.

For each repo, in the same Agent message:

→ Agent (subagent_type: "dev-workflows:diff-summarizer"):
  > "Summarise this repo's PRs for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 4>
  > repo_url_slug: <repo slug, e.g. "cluster">
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

→ Agent (subagent_type: "dev-workflows:doc-location-finder"):
  > "Find write target(s) for the brief:
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

→ Agent (subagent_type: "dev-workflows:doc-planner"):
  > "Produce the documentation checklist for the brief:
  >
  > jira_reader_handoff: [paste full YAML from Phase 3]
  > diff_summaries:       [paste array of diff-summarizer outputs from Phase 5]
  > write_targets:        [paste confirmed list from Phase 5.5]
  > screenshots:          [user-provided paths from Phase 1, possibly empty]
  > screenshot_staging_dir: [resolved <screenshot_staging_dir> from Phase 1, or null]
  > repo_root:            [cwd's git root]
  > code_repos:           [the Phase-4 resolved {slug, path} map; [] if none resolved]"

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

## Phase 5.8 — Discrepancy analysis & user decision

Run this phase when the `doc-planner` handoff contains any `verification_warnings` with `finding: CONTRADICTED`, `NOT_FOUND`, or `AMBIGUOUS`. If there are none, skip to Phase 6.

1. **Present the analysis table** (informational, before asking):
   ```
   | # | Claim | Jira phrasing | Source phrasing | Source location | Verdict |
   ```
   One row per warning. Use `Source phrasing: "(not verifiable)"` for `no-source-evidence` entries.

2. **Batch decision:**
   ```
   choices: ["Decide per discrepancy (Recommended)", "Document ALL as source suggests", "Document ALL as Jira claims (drafts a bug report)", "Skip ALL and report (drafts a bug report)", "Cancel", "Other… (describe)"]
   ```

3. **Per-discrepancy** (if "Decide per discrepancy"): for each warning, show claim + Jira phrasing + source phrasing + location, then:
   ```
   choices: ["Document as source suggests", "Document as Jira claims (adds an intentional-discrepancy marker + bug-report draft)", "Skip this claim and report it", "Cancel", "Other… (describe)"]
   ```

4. **Record `discrepancy_decisions[]`** keyed by `number` (claim, jira_phrasing, source_phrasing, source_location, decision ∈ {document-as-source, document-as-jira, skip-and-report}, rationale). Set `bug_report_destination` to the ticket's vault project folder (resolved exactly like the release-notes destination in `/impl:jira:release-notes` — `find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if none) when any decision is `document-as-jira` or `skip-and-report`.

Pass `discrepancy_decisions` to Phase 6.

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
   - **`cdn_upload_required`** → **do NOT copy user-provided screenshots into the repo.** Stage them at the planner's `staging` path, which lives under `<screenshot_staging_dir>` — the ticket's persistent Obsidian project folder resolved in Phase 1 (e.g. `…/Projects/…/<JIRA_KEY> - <name>/Doc screenshots/`). `$VAULT_PATH` is always host-mounted, so the staged files survive a container restart (the docs repo and `/tmp` may not). Create the staging directory if it does not exist. If `<screenshot_staging_dir>` was skipped/null, prompt the user for a persistent directory now. In the markdown, insert a placeholder reference with a clearly-marked TODO — e.g. `![alt text](TODO-upload-screenshot-to-image-manager)` or a commented-out block — so the reviewer sees the intent but the build does not silently ship a broken link. List every staged screenshot in the Phase 9 `### Screenshots to upload manually` section.
   - **`ambiguous`** → ask the user at this step, per target:
     ```
     choices: ["Use local path <page-dir>/img/ (Recommended if this repo uses local images)", "Stage for manual upload to the repo's image-management tool", "Skip this screenshot", "Other… (describe)"]
     ```
     Apply the chosen branch.
6. **Traceability** — every claim must cite the originating Jira key (e.g. `[[<JIRA_KEY>]]`) and/or PR URL inline. When a claim comes only from imported Jira content (no PR resolved), cite the Jira key alone.

7. **Apply discrepancy decisions** (from Phase 5.8), per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.4–§7.6:
   - `document-as-source` → use the source phrasing verbatim.
   - `document-as-jira` → use the Jira phrasing AND insert immediately before the affected prose:
     `<!-- intentional-discrepancy: Jira <JIRA_KEY> describes "<jira_phrasing>" but the source at <source_location> currently has "<source_phrasing>". User decision: document Jira phrasing pending implementation. See <JIRA_KEY>-implementation-gaps.md gap #<n>. -->`
     Strongly recommend committing to a branch (Phase 6.5); the Phase 9 report MUST flag "do NOT merge this docs PR until the gaps are resolved". The plugin does NOT open a PR (zero-external-API invariant).
   - `skip-and-report` → omit the claim from the docs.
   - When any decision is `document-as-jira`/`skip-and-report`, write `<bug_report_destination>/<JIRA_KEY>-implementation-gaps.md` using the §7.5 format (vault project folder; never `/tmp`; never the docs repo).

Write to the resolved `docs_repo_path` (Phase 0). Branch and commit policy is governed by the write context (Phase 0 step 7):

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

**Mandatory:** the orchestrator MUST dispatch `docs-style-checker` and act on its return — never skip on its own judgement of which linters are installed.

`docs-style-checker` runs the chain **internally**: the repo's primary linter (Vale, etc.) AND — when the `dt-style-guide` plugin is installed — `dt-style-checker` as a complementary semantic / cross-page-consistency pass, merging and deduping both finding sets. The two are complementary, not redundant (Vale: lexical at scale + frontmatter; `dt-style-checker`: engineer jargon, cross-page label consistency, subject-verb agreement, plural/singular label mismatch). The command does NOT invoke `dt-style-checker` separately — the agent already did.

Invoke `docs-style-checker` on the files written in Phase 6:

→ Agent (subagent_type: "dev-workflows:docs-style-checker"):
  > "Run the style check for this brief:
  >
  > repo_root: [cwd's git root]
  > files:     [absolute paths of every file written or modified in Phase 6]"

Act on the return:

- **`status: NOT_CONFIGURED`** — neither a repo linter NOR the `dt-style-checker` complementary pass was available (the agent already tried both). Proceed to Phase 7; `doc-reviewer` will still check correctness/completeness.
- **`status: OK`** — the chain ran (primary and/or complementary), zero merged violations. Proceed to Phase 7.
- **`status: VIOLATIONS_FOUND`** — invoke `doc-fixer` with the violations treated as per their severity. After `doc-fixer` completes, re-run the linter once:

  → Agent (subagent_type: "dev-workflows:doc-fixer"):
    > "Fix the style violations for this brief:
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
  choices: ["Proceed to doc-reviewer (style check unavailable — doc-reviewer still runs)", "Cancel and fix locally"]
  ```

---

## Phase 7 — Doc review gate

Invoke `doc-reviewer` (Opus). The reviewer is **product-docs-only**; Epic drafts go through `epic-reviewer` in `/impl:jira:epics`.

→ Agent (subagent_type: "dev-workflows:doc-reviewer"):
  > "Review the written product documentation for this brief:
  >
  > Task description: [one-paragraph summary of the feature and <JIRA_KEY>]
  > Written doc file paths: [absolute paths of every file written in Phase 6]
  > Jira directory path:    [$VAULT_PATH/jira-products/<JIRA_KEY>/]
  > Diff summaries:         [array of diff-summarizer outputs from Phase 5]
  > doc-planner checklist:  [the full YAML from Phase 5.7]
  > style-check report: [the violations output from Phase 6.7 — from docs-style-checker or dt-style-checker (fallback), or 'status: NOT_CONFIGURED' if neither ran]
  > code_repos:         [the Phase-4 resolved {slug, path} map; [] if none resolved]"

Act on the verdict:

- **BLOCK** — invoke `doc-fixer` with `Severities to fix: BLOCKER and MAJOR`. Re-invoke `doc-reviewer` once. If the second verdict is still BLOCK, escalate for each unresolved BLOCKER individually per §15:
  ```
  choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]
  ```
  "Manual fix notes" → take free-text from the user; apply via `doc-fixer` in a bounded one-shot pass (no further re-review cycle). "Defer" → record in Phase 9 `### Deferred items` without an override flag. "Override" → record in `### Deferred items` with the user's rationale. "Cancel" aborts.

- **PASS WITH RECOMMENDATIONS** — invoke `doc-fixer` for MAJOR findings only:

  → Agent (subagent_type: "dev-workflows:doc-fixer"):
    > "Fix the review findings for this brief:
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
> Determine if *other* documentation needs updating as a consequence of this write (e.g., an index page, a cross-referenced overview, a changelog entry in the repo root). Do NOT touch release-notes / what's-new pages — those are generated from Jira by automation.
> - Skip if: the edit is confined to the intended target pages with no inbound cross-references.
> - Update if: new page requires an index/sidebar entry, new sections require inbound cross-links.
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

**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance):
> "Analyse this session and return a Lessons Learned report.
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
- <repo-1> (<resolved repo_path>) — [N PRs in scope, M resolved, K unresolved]
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
[Only populated when any target used image_policy: cdn_upload_required (or the user selected "Stage for manual upload" under the ambiguous branch). For each staged screenshot: src (original user-provided path), staging path under <screenshot_staging_dir> (the persistent Obsidian project folder), the target page it belongs on, the proposed alt-text, and the upload_note from the planner. Omit this section entirely when no screenshots were staged.]

### Implementation gaps (Jira vs source)
[Populated when Phase 5.8 produced any document-as-jira / skip-and-report decision. List each gap (claim, decision) and: "Bug-report draft written to <path>. If docs were branched, DO NOT merge the PR until these gaps are resolved." Omit when there were no discrepancies.]

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
- For `image_policy: cdn_upload_required`, NEVER copy user-provided screenshots into the repo — stage under `<screenshot_staging_dir>`, the ticket's persistent Obsidian project folder under `$VAULT_PATH` (never the docs repo, never `/tmp`) — and surface in the Phase 9 `### Screenshots to upload manually` section

---
name: impl:jira:docs
description: Jira-driven feature-documentation workflow. Phase 0 preflight-discovers the docs repo + profile (in-repo → built-in dynatrace-docs default → on-demand /impl:docs:profile) and the VI's specs dir under /workspace. Phase 4.5 determines/confirms the applicable space(s). Optional saas|managed constraint scopes the run to one space. Reads a Value Increment hierarchy from exported markdown, resolves PR diffs in parallel, synthesises product documentation, and gates on style-check and Opus doc review.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Generate product documentation for the Jira Value Increment: $ARGUMENTS

Signature: `PRODUCT-NNNN [saas|managed]`. The optional second token is a **space constraint**, not a target list. When you pass `saas` or `managed`, the command documents **only that space** and leaves the OTHER space's rendered output unchanged (SaaS pages stay as they are when you pass `managed`, and vice-versa). When you omit it, the command **determines the applicable space(s)** from the Jira hierarchy and the resolved repos, then confirms with you. `both` is intentionally NOT an accepted value — omit the argument to cover both spaces.

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

7. **Classify write context** for later branch/write decisions — computed against the resolved `docs_repo_path` (not necessarily cwd). Walk up from `docs_repo_path` looking for `.obsidian/`; if found, context = `obsidian`. Else if `git -C <docs_repo_path> rev-parse --show-toplevel` succeeds AND at least one docs signal from step 3 is present, context = `docs_repo`. Else if it succeeds with no docs signals, context = `non_docs_repo` (step 3 has already asked the user; their confirmation promotes this to `docs_repo` behaviour). Else context = `plain_dir`. In a normal run, Phase 0's docs-repo resolution (steps 3–4) yields a real docs repo (`docs_repo`) or a user-confirmed `non_docs_repo`; `obsidian` and `plain_dir` are **defensive guards** (they forbid branch/commit) rather than expected write targets.

   Record the resolved context — it drives Phase 6.5 (branch setup) and Phase 6 write rules. When `docs_repo_path` differs from cwd, record **both** and note that the writing phases (Increments 2–3) consume `docs_repo_path`, not cwd, for every write.

8. **Parse the optional space constraint.** Read `$ARGUMENTS` as `<JIRA_KEY> [space]` — the same `$ARGUMENTS` already split for `<JIRA_KEY>` in step 2; the optional second whitespace-separated token is the space constraint.
   - **No second token** → `space_constraint = none`. Phase 4.5 will determine and confirm the applicable space(s).
   - **Second token is `saas` or `managed`** (case-insensitive) → `space_constraint = <space>`. This is a deliberate scoping decision by the user, so Phase 4.5 skips its determination step and records `target_spaces = [space_constraint]` directly.
   - **Second token present but not `saas`/`managed`** (e.g. `both`, a typo, or extra free text) → do NOT silently guess. Reject it and ask:
     ```
     "'<token>' is not a valid space constraint. The constraint scopes the run to a single space; to cover both, omit the argument and let the command determine the applicable space(s). How would you like to proceed?"
     choices: ["Drop the constraint — auto-determine (Recommended)", "saas", "managed", "Cancel"]
     ```
     "Drop the constraint" → `space_constraint = none`. "saas"/"managed" → `space_constraint = <choice>`. "Cancel" → stop.

### Readiness

Before clarification, show a readiness table summarizing what Phase 0 resolved:

| Item | Resolved |
|---|---|
| Vault + Jira | `$VAULT_PATH` ok; `jira-products/<JIRA_KEY>/` ok |
| Docs repo | `<docs_repo_path>` (`is_dynatrace_docs`: yes/no) — write context `<obsidian \| docs_repo \| non_docs_repo \| plain_dir>` |
| Profile | `profile_source`: `<in-repo \| built-in \| generated>` |
| Specs | `<specs_dir>` or `none` |
| Space constraint | `<space_constraint>` (`saas` \| `managed` \| `none` → auto-determine in Phase 4.5) |
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
- **Screenshots** — ask only whether images are wanted; the candidate list itself is built later in **Phase 5.6** (by which point `specs_dir`, the `jira-reader` `attachments[]`, and the resolved repos are all available):
  ```
  choices: ["Yes — include screenshots (you'll pick the sources in Phase 5.6) (Recommended)", "No screenshots needed", "Cancel", "Other… (describe)"]
  ```
  Record the answer as `images_wanted` (true/false). When `false`, Phase 5.6 is skipped and `screenshots[]` stays empty. The downstream `doc-planner` (Phase 5.7) detects the repo's `image_policy` and decides per screenshot whether the writer will copy it locally or stage it for manual upload.

  **Resolve `<screenshot_staging_dir>` (only when `images_wanted` is true).** For the `cdn_upload_required` case the staged copies must live somewhere that survives a container restart — `$VAULT_PATH` is always host-mounted, the docs repo (often a docker repo-volume) and `/tmp` are not. Find the ticket's persistent Obsidian project folder:
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
- Space scope — show `space_constraint` (Phase 0 step 8): `saas`/`managed` means `target_spaces` is already fixed to that single space; `none` means the applicable space(s) are auto-determined and confirmed in Phase 4.5 (after the Jira read and repo resolution). Once Phase 4.5 has run, the resolved `target_spaces` is the authoritative value displayed here.

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
- Screenshots: `images_wanted` (yes/no, from Phase 1). When yes, the candidate list is gathered and confirmed in Phase 5.6 (specs scan + Jira `attachments[]` + manual paths) — list "candidates resolved in Phase 5.6".
- Target space(s): the resolved `target_spaces` (`[saas]` / `[managed]` / `[saas, managed]`). State whether it came from the `space_constraint` argument (and that the other space's render is left unchanged) or from the Phase 4.5 auto-determination the user confirmed. If Phase 4.5 hasn't run yet (auto-determine, `space_constraint = none`), list "TBD — determined and confirmed in Phase 4.5".

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

## Phase 4.5 — Determine applicable space(s)

Resolve `target_spaces` — one of `[saas]`, `[managed]`, or `[saas, managed]`. This is the set of spaces the documentation will cover; the constraint semantics that *protect* the other space (`{{#if project='…'}}` conditionals or override-copies + `managed/docstack.jsonc` `ignore` allowlisting) are Increment 3, so this increment only carries `target_spaces` forward.

- **If `space_constraint` is set** (`saas` or `managed`, from Phase 0 step 8) → set `target_spaces = [space_constraint]` and skip the determination below. Print:
  ```
  Constrained to <space_constraint> (the other space's render is left unchanged — see Increment 3 techniques).
  ```

- **If `space_constraint` is `none`** → run a **first-pass determination** from cheap signals already in hand, then confirm with the user:
  1. **Jira text/labels** — scan the `jira-reader` handoff (VI + linked Epics: summaries, descriptions, labels, components) for explicit "SaaS", "Managed", or "both" mentions. Explicit wording is the strongest signal.
  2. **Resolved-repo leaning** — use the Phase-4 `repo_slug → repo_path` map as a **hint, not authority**: cluster/Managed-oriented repos (e.g. names containing `cluster`, `managed`, `server`, `appliance`) lean `managed`; SaaS-service repos lean `saas`. A mix of both leans `[saas, managed]`.
  3. **Specs presence/name** — if `specs_dir` was resolved in Phase 0, a `saas`/`managed` hint in its name reinforces the guess; absence is neutral.

  Form a best-guess `target_spaces` from these signals (when they conflict or are silent, default the guess to `both saas and managed` — under-scoping silently drops a space, which is worse than over-scoping). **Confirm with the user**, ordering the recommended (auto-detected) option first:
  ```
  "Determined applicable space(s): <auto-detected> — from [signals that drove it]. Confirm or override:"
  choices: ["<auto-detected> (Recommended)", "saas only", "managed only", "both saas and managed", "Other… (describe)"]
  ```
  Map the confirmed choice to `target_spaces`: "saas only" → `[saas]`, "managed only" → `[managed]`, "both saas and managed" → `[saas, managed]`; "Other… (describe)" takes free text and resolves to one of the three. Record the confirmed `target_spaces`.

The authoritative determination (from full diff/spec analysis rather than these cheap signals) is refined in Increment 2; here `target_spaces` is a confirmed best guess that threads through Phases 1 and 2 and the writing phases.

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

## Phase 5.6 — Image candidates

**Skip this phase entirely when `images_wanted` is `false`** (Phase 1) — `screenshots[]` stays empty and Phase 5.7 receives no images.

When `images_wanted` is `true`, build a **merged, deduped candidate list** from three sources (by this point Phase 0's `specs_dir`, the Phase 3 `jira-reader` `attachments[]`, and the Phase 4 resolved repos are all in hand):

1. **Recursive scan of `<specs_dir>`** — when Phase 0 resolved a `specs_dir` (not `none`), recursively scan it for image files across the spec root, `epics/`, and `spec/`:
   ```bash
   find "<specs_dir>" \( -path "*/epics/*" -o -path "*/spec/*" -o -path "<specs_dir>/*" \) \
     -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.svg" -o -iname "*.webp" \) 2>/dev/null
   ```
   When `specs_dir` is `none`, this source contributes nothing.
2. **`jira-reader` `attachments[]`** — the image paths enumerated under the VI's `attachments/` dirs (Phase 3 handoff `attachments[].path`). May be empty.
3. **Manual paths** — the user-provided "I'll provide screenshot paths" option (free text, see the `choices` below).

**Dedupe** by resolved absolute path (collapse mixed separators / trailing-slash differences); when the same image appears in more than one source, keep one entry and note its origins. Present the deduped candidates, then ask:
```
"Found <N> candidate image(s): <count> from specs scan, <count> from Jira attachments. How would you like to source screenshots?"
choices: ["Use all auto-discovered + add manual paths (Recommended)", "Use all auto-discovered only", "Select a subset (you'll pick per candidate)", "Provide screenshot paths manually only (you'll be prompted)", "No images after all", "Other… (describe)"]
```
- **Use all auto-discovered + add manual** → take every deduped candidate, then prompt for additional free-text absolute paths to append.
- **Use all auto-discovered only** → take every deduped candidate; no manual prompt.
- **Select a subset** → present the deduped candidates and let the user pick which to keep.
- **Provide screenshot paths manually only** → ignore the auto-discovered candidates; take free text only.
- **No images after all** → set `images_wanted = false` semantics for this run; leave `screenshots[]` empty and skip the rest of this phase.

For any **manual** free-text paths, accept any absolute filesystem path (vault, `/tmp`, home, the docs repo); accept multiple (one per line or space-separated). Validate each path exists and has an image extension (`.png|.jpg|.jpeg|.gif|.svg|.webp`); drop and report any that don't.

The selected paths populate the existing **`screenshots[]`** passed to `doc-planner` in Phase 5.7 — the downstream placement machinery (per-screenshot `dest`/`staging`/`upload_note`, `image_policy`) is unchanged.

---

## Phase 5.7 — Plan the documentation

Invoke `doc-planner`:

→ Agent (subagent_type: "dev-workflows:doc-planner"):
  > "Produce the documentation checklist for the brief:
  >
  > jira_reader_handoff: [paste full YAML from Phase 3]
  > diff_summaries:       [paste array of diff-summarizer outputs from Phase 5]
  > write_targets:        [paste confirmed list from Phase 5.5]
  > screenshots:          [selected candidate paths from Phase 5.6, possibly empty]
  > screenshot_staging_dir: [resolved <screenshot_staging_dir> from Phase 1, or null]
  > repo_root:            [cwd's git root]
  > code_repos:           [the Phase-4 resolved {slug, path} map; [] if none resolved]
  > specs_dir:            [resolved <specs_dir> from Phase 0, or null]
  > profile:              [the docs-profile loaded in Phase 0 — drives space routing + the multi-space write strategy]
  > target_spaces:        [the resolved target_spaces from Phase 4.5: [saas] | [managed] | [saas, managed]]"

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

Run this phase when the `doc-planner` handoff contains any `verification_warnings` with `finding: CONTRADICTED`, `NOT_FOUND`, `AMBIGUOUS`, or verdict `SPEC-VS-JIRA`. If there are none, skip to Phase 6.

This phase is **three-way** when a spec was provided (Phase 0 resolved `specs_dir` and Phase 5.7 passed it to `doc-planner`): it compares the **Jira** narrative, the **Spec** (authoritative "intended"), and the **Code** ("actual"), per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7. When no spec was provided, the planner emits `spec_phrasing: "(no spec)"`; the **Spec phrasing** column simply renders `(no spec)` and the run behaves exactly as the original Jira-vs-code two-way protocol.

1. **Present the analysis table** (informational, before asking):
   ```
   | # | Claim | Jira phrasing | Spec phrasing | Source (code) phrasing | Source location | Verdict |
   ```
   One row per warning. The **Spec phrasing** cell reads `(no spec)` when no spec was provided. Use `Source (code) phrasing: "(not verifiable)"` for `no-source-evidence` entries. The **Verdict** carries the §4.2 finding (`CONTRADICTED`, `NOT_FOUND`, `AMBIGUOUS`) or `SPEC-VS-JIRA` (the spec differs from the Jira narrative; recommended action "Document as intended (spec)").

2. **Batch decision:**
   ```
   choices: ["Decide per discrepancy (Recommended)", "Document ALL as intended (spec)", "Document ALL as actual (code)", "Skip ALL and report (drafts a bug report)", "Cancel", "Other… (describe)"]
   ```
   "Document ALL as intended (spec)" uses the `spec_phrasing` (or the Jira phrasing when it is `(no spec)`).

3. **Per-discrepancy** (if "Decide per discrepancy"): for each warning, show claim + Jira phrasing + Spec phrasing + Source (code) phrasing + location, then:
   ```
   choices: ["Document as intended (spec)", "Document as actual (code)", "Skip this claim and report it", "Cancel", "Other… (describe)"]
   ```
   "Document as intended (spec)" describes the agreed contract — the `spec_phrasing` (or the Jira phrasing when it is `(no spec)`) — and, when the code lags the intended phrasing, adds an intentional-discrepancy marker + bug-report draft. "Document as actual (code)" matches what shipped. "Skip this claim and report it" omits the claim but still records the gap in the bug-report draft.

4. **Record `discrepancy_decisions[]`** keyed by `number` (claim, jira_phrasing, spec_phrasing, source_phrasing, source_location, decision ∈ {document-as-spec, document-as-code, skip-and-report}, rationale). `spec_phrasing` is recorded verbatim (`(no spec)` when none was provided). Set `bug_report_destination` to the ticket's vault project folder (resolved exactly like the release-notes destination in `/impl:jira:release-notes` — `find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if none) when any decision is `document-as-spec` (where the code lags the intended phrasing) or `skip-and-report`.

Pass `discrepancy_decisions` to Phase 6.

---

## Phase 5.9 — Write-strategy approval (multi-space safety)

Run this phase when the `doc-planner` checklist contains **any** target whose
`write_strategy.strategy` is `conditional` or `override-copy` (i.e. at least one
shared page needs cross-space protection). If every target is `plain`, skip to
Phase 6 — there is nothing to protect.

The mechanics are defined in
`${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md`; this
phase only confirms the per-page **strategy choice** before Phase 6 writes.

1. **Present the recommended strategies** (informational, before asking) — one
   row per non-`plain` target:
   ```
   | # | Page (target_path) | space_scope | rendered_in | Recommended | For space | Rationale |
   ```
   `Recommended` is `write_strategy.strategy`; `For space` is `write_strategy.target_space`. Remind the user of the invariant: a `conditional` edits the shared file in place but leaves the protected space's *render* unchanged; an `override-copy` duplicates the page into the other space and allowlists it in `cross_space_override`'s `ignore`.

2. **Batch decision:**
   ```
   choices: ["Accept all recommended (Recommended)", "Decide per page", "Cancel", "Other… (describe)"]
   ```

3. **Per page** (if "Decide per page"): for each non-`plain` target, show the row and:
   ```
   choices: ["Conditional — edit shared page in place ({{#if project='…'}})", "Override-copy — separate page in the other space + docstack ignore", "Cancel", "Other… (describe)"]
   ```
   The default/recommended choice is the planner's `write_strategy.strategy`, listed first.

4. **Record `write_strategies[]`** keyed by `target_path`: `{target_path, strategy ∈ {conditional, override-copy, plain}, target_space, rationale}`. Targets the planner marked `plain` are carried through as `plain` without prompting. Pass `write_strategies` to Phase 6.

---

## Phase 6.2 — CDN image handoff

Run this phase only when, in the Phase 5.7 `doc-planner` return, **any** screenshot has `image_policy: cdn_upload_required` — **or** the user picked "Stage for manual upload" under an `ambiguous` target in Phase 6. (When the only image policy in play is `local`, skip this phase: local images are copied into the repo at Phase 6 with no handoff needed.)

1. **List each affected image** so the decision is informed — one row per image:
   - target page / anchor it belongs on (from the planner's per-screenshot placement);
   - proposed alt text;
   - the planner's `upload_note`.

2. **Ask how to handle the upload:**
   ```
   choices: ["Upload now — I'll paste the CDN links (Recommended)", "Defer — stage with TODO placeholders + Phase 9 list", "Cancel", "Other… (describe)"]
   ```

   - **Upload now** → collect one CDN URL per image (prompt per image, or one URL per line in image order). Validate each pasted value looks like a URL (e.g. starts with `http://` / `https://`); re-prompt for any that don't. Record `cdn_urls[<image>]`. Phase 6 then writes the **real CDN URL** into each markdown image reference instead of a TODO placeholder. Nothing is staged and the Phase 9 "Screenshots to upload manually" section stays empty for these images.
   - **Defer** → the existing async behavior: stage each image under `<screenshot_staging_dir>` (the ticket's persistent Obsidian project folder resolved in Phase 1), Phase 6 inserts the `TODO-upload` placeholder reference, and every staged image is listed in the Phase 9 `### Screenshots to upload manually` section.
   - **Cancel** → stop and summarise.

   Record the decision as `cdn_handoff_decision ∈ {upload-now, defer}` and carry it (with any `cdn_urls`) into Phase 6.

---

## Phase 6 — Write documentation

The main command writes the markdown following the `doc-planner` checklist. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5.7 already loaded.

Multi-space safety is governed by `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md`. Before writing, resolve **per-space routing** for each target:
- Determine the target's **home space** by matching `target_path` against each `profile.spaces[].content_root`/`snippet_root` prefix.
- A target whose home space is **not** in `target_spaces` is a routing error — stop and surface it (it should not occur once Phase 4.5/5.5 honored `target_spaces`); the one legitimate write outside `target_spaces` is an `override-copy` destination (step 0 below).
- Apply the **approved `write_strategy`** for the target (from Phase 5.9 `write_strategies[]`; absent ⇒ `plain`).

For each target in the confirmed write-target list:

0. **Apply the approved write strategy** (per `write_strategies[<target_path>]` and `multi-space-writing.md`):
   - **`plain`** → write the page in its home space's `content_root` as usual (steps 1–7 below). No cross-space action.
   - **`conditional`** → edit the **shared source page in place** in its home space and wrap the per-space delta in `{{#if project='<target_space>'}}…{{/if}}` (project value from `profile.tokens.project_conditionals`). The protected space's render does not change because the wrapped content is excluded for it. Continue with steps 1–7 for the edited content.
   - **`override-copy`** → copy the page into `profile.spaces[]` `content_root` of `write_strategy.target_space` at the **same relative path** under that `content_root` (`<home content_root>/<rel>` → `<dest content_root>/<rel>`), edit the copy for the destination space (steps 1–7), then make the override win: add the **shared source path** to the override manifest's `ignore` allowlist per `profile.cross_space_override.rule` (for dynatrace-docs: add `../dynatrace/_content/<rel>` to the `ignore` block of `managed/docstack.jsonc`). Leave the home-space source untouched so its render is unchanged.

1. **Preserve any existing YAML frontmatter** on pages being extended. Never strip unknown fields.
2. **Add or update** the `changelog:` field per the planner's checklist (append a new dated entry naming the Jira key and a 1-line change summary). Create the field if it doesn't exist on an extended page.
3. **Update other frontmatter** the planner flagged: `published` (creation date on new pages), `meta.generation`, `readtime` (estimate from word count), `tags` (merge — don't duplicate), `owners` (leave to the user).
4. **Reuse snippets** per the checklist: for snippets listed under `snippets.reuse`, use the repo's include syntax rather than inlining content. For snippets listed under `snippets.extract`, create the new snippet file in the repo's idiomatic `_snippets/` location and reference it from the target page.
5. **Place screenshots** per each target's `image_policy`:
   - **`local`** → copy each user-provided `src` to the planner's `dest` path (typically `<page-dir>/img/` or the detected idiomatic directory). Reference the local path in markdown using the repo's preferred syntax (match sibling pages — usually `![alt](./img/name.png)` or similar).
   - **`cdn_upload_required`** → **do NOT copy user-provided screenshots into the repo.** Branch on the Phase 6.2 `cdn_handoff_decision`:
     - **`upload-now`** → reference the **real CDN URL** the user pasted in Phase 6.2 (`cdn_urls[<image>]`) directly in the markdown image reference — e.g. `![alt text](<pasted CDN URL>)`. Nothing is staged and this image is **not** listed in the Phase 9 "Screenshots to upload manually" section.
     - **`defer`** → the existing async behavior. Stage the image at the planner's `staging` path, which lives under `<screenshot_staging_dir>` — the ticket's persistent Obsidian project folder resolved in Phase 1 (e.g. `…/Projects/…/<JIRA_KEY> - <name>/Doc screenshots/`). `$VAULT_PATH` is always host-mounted, so the staged files survive a container restart (the docs repo and `/tmp` may not). Create the staging directory if it does not exist. If `<screenshot_staging_dir>` was skipped/null, prompt the user for a persistent directory now. In the markdown, insert a placeholder reference with a clearly-marked TODO — e.g. `![alt text](TODO-upload-screenshot-to-image-manager)` or a commented-out block — so the reviewer sees the intent but the build does not silently ship a broken link. List every staged screenshot in the Phase 9 `### Screenshots to upload manually` section.
   - **`ambiguous`** → ask the user at this step, per target:
     ```
     choices: ["Use local path <page-dir>/img/ (Recommended if this repo uses local images)", "Stage for manual upload to the repo's image-management tool", "Skip this screenshot", "Other… (describe)"]
     ```
     Apply the chosen branch.
6. **Traceability** — every claim must cite the originating Jira key (e.g. `[[<JIRA_KEY>]]`) and/or PR URL inline. When a claim comes only from imported Jira content (no PR resolved), cite the Jira key alone.

7. **Apply discrepancy decisions** (from Phase 5.8), per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.4–§7.6:
   - `document-as-code` → use the source phrasing verbatim.
   - `document-as-spec` → use the intended (spec) phrasing AND insert immediately before the affected prose:
     `<!-- intentional-discrepancy: <JIRA_KEY> intends "<spec_phrasing>" (spec; "<jira_phrasing>" per Jira when no spec) but the source at <source_location> currently has "<source_phrasing>". User decision: document intended phrasing pending implementation. See <JIRA_KEY>-implementation-gaps.md gap #<n>. -->`
     Strongly recommend committing to a branch (Phase 6.5); the Phase 9 report MUST flag "do NOT merge this docs PR until the gaps are resolved". The plugin does NOT open a PR (zero-external-API invariant).
   - `skip-and-report` → omit the claim from the docs.
   - When any decision is `document-as-spec`/`skip-and-report`, write `<bug_report_destination>/<JIRA_KEY>-implementation-gaps.md` using the §7.5 format (vault project folder; never `/tmp`; never the docs repo).

8. **Shared-registries lock-step** (per `profile.shared_registries` and `multi-space-writing.md` §5). If any write **renames, retitles, or creates** a page matching a `shared_registries[].when` condition (for dynatrace-docs: a settings-schema page under `dynatrace/_content/dynatrace-api/environment-api/settings/schemas/`), update **every** file in that entry's `files` list together per its `rule` (for dynatrace-docs: the `text:` entry in BOTH `schema-ids.yml` and `schema-mappings.yml`, in lock-step). Stage all of them in the same commit.
9. **Token-correctness validation** (per `profile.tokens` and `multi-space-writing.md` §6). On every file written or edited in this phase, validate before handing off to the style/review gates: every `{{#if project='…'}}` has a matching `{{/if}}`; each `project='…'` value is a known space/edition (`saas`, `managed`, `classic`, `latest`); `{{tag kind='latest'}}` and `::app-settings::` are spelled exactly and used only in a space that supports them. Fix malformed or space-inappropriate tokens now; do not defer them to Phase 6.7.

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

1. **Update the base branch.** Resolve the default branch by running `git symbolic-ref --short refs/remotes/origin/HEAD`; this returns the remote's default (`main` or `master`; legacy repos frequently still use `master`). If the command fails (unset `origin/HEAD`), run `git remote set-head origin --auto` and retry; if it still fails, try `main`, then `master`, in that order. If the user picked a `release/*` branch earlier in Phase 1, use that instead. Once the base is resolved: `git fetch origin`. Then update the base working copy **only outside the inline-profiling case**: when `profile_source` is NOT `generated`, `git switch <base> && git pull --ff-only`. **In the inline-profiling case (`profile_source: generated`), do NOT switch** — HEAD must stay on the generated profile branch so step 5's `git branch -m <name>` renames *that* branch (the profile branch was created off the base in Phase 0, so it is already current). When a switch happened and the fast-forward pull fails:
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

5. **Create or adopt the branch, and record handoff anchors.** Record `base_branch` = the base resolved in step 1 (the Phase 8.5 squash uses it).
   - **Normal case** (`profile_source` is `in-repo` or `built-in`, or a custom repo whose profiling did not create a branch): `git switch -c <name>` from `base_branch`.
   - **Inline-profiling case** (`profile_source: generated`): Phase 0's `/impl:docs:profile` already ran `git switch -c <profile-branch>` and committed `.dev-workflows/docs-profile.yml`, so HEAD is already on that branch. Do NOT create a new branch — rename it with `git branch -m <name>`. Record `profile_commit` = the commit that introduced the profile config: `git log --diff-filter=A --format=%H -- .dev-workflows/docs-profile.yml | head -1`. Phase 8.5 squashes the docs commits onto `profile_commit`, keeping the profile-config commit as a distinct first commit. (Per `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §1.)

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

## Phase 6.8 — Render verification

Run this phase after Phase 6.7 **only** when Phase 6 wrote files into a buildable docs repo (write context `docs_repo`, or `non_docs_repo` confirmed at Phase 0). Skip for `obsidian` / `plain_dir` (nothing was written into a repo that builds). Mechanics: `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/render-verification.md`. "Affected pages" = every file written or modified in Phase 6.

### Step 1 — Build check (gating)

Run `profile.commands.build` if the profile defines one. Do NOT re-run the Phase 6.7 prose linter. Classify any failure:
- **Content failure** (Handlebars won't compile, unresolved snippet include, broken postid/internal link, malformed conditional) → invoke `doc-fixer` (Severities: BLOCKER and MAJOR), then re-run the build once. If failures remain:
  ```
  choices: ["Proceed to smoke-check anyway", "Show remaining and fix manually", "Cancel"]
  ```
- **Environmental failure** (the build tool will not run — missing toolchain, `command not found`, missing `.docstack` shim) → surface the reason; no `doc-fixer` loop:
  ```
  choices: ["Proceed (build unverified)", "I'll fix locally — retry the build", "Cancel"]
  ```

When the profile defines **no** build command (the dynatrace-docs case), record "no build command in profile; build proof deferred to the dev-server boot (Step 2)" and proceed.

### Step 2 — Dev-server smoke-check (opt-in, best-effort)

Offer it:
```
choices: ["Run smoke-check (Recommended)", "Skip — use the manual table only", "Cancel"]
```

When run, for each space in `target_spaces`, **sequentially** (`profile.dev_servers.concurrent: false` forbids overlap) — full mechanics in `render-verification.md`:
1. **Prerequisites (best-effort, never auto-applied).** Verify `profile.prerequisites`. The `.docstack` shim is a local, gitignored dev-environment workaround — check it, NEVER apply it. Unmet → record "smoke-check skipped for `<space>`: prerequisite `<x>` unmet" and use the manual table for that space.
2. **Boot** `profile.dev_servers.servers[<space>].command` in the background; record the process id.
3. **Readiness poll** — GET `http://localhost:<port><base_path>/` until HTTP 200 or `profile.dev_servers.readiness_timeout_seconds` seconds (fall back to **120** when absent). On timeout → stop the process, record "smoke-check skipped for `<space>`: not ready", use the manual table for that space.
4. For each affected page rendered in `<space>`, GET its derived URL (Step 3 route rule) → assert **HTTP 200**.
5. For each **cross-space** page (its `write_strategy.strategy` is `conditional` or `override-copy`), grep the rendered HTML for the page's **delta marker** (`render-verification.md` §4): PRESENT when `<space>` is the strategy's `target_space`, ABSENT when `<space>` is the protected space.
6. **Stop the server** (kill the recorded process id) before the next space.

Outcomes:
- **404/500** on an affected page = render defect → treat as a Step 1 content failure (offer `doc-fixer` / surface).
- **Invariant violation** (a cross-space delta marker present in the protected space's render, or missing from the target space's render) = **Critical** (the 3a protection failed):
  ```
  choices: ["Fix manually then retry", "Defer to a follow-up (record in Phase 9)", "Cancel"]
  ```
- Any **boot / prerequisite / readiness** problem is best-effort → never blocks; that space falls back to the manual table.

### Step 3 — "Pages to visit" table (always)

Emit a table, one row per affected page — URL per space the page renders in (`http://localhost:<port><base_path>/<route>`; blank for a space the page does not render in), the page's `write_strategy.strategy`, and what to verify (cross-space: "confirm `<target_space>` shows the change and the `<protected_space>` render is unchanged"; `plain`: "confirm the page renders as intended"). When the smoke-check ran, annotate each cell ✅ 200 / ⚠️ skipped (reason) / ❌ failed.

**Route derivation (best-effort):** `<route>` = the page path relative to its space's `content_root` with a trailing `index.md`/`.md` removed. Approximate — a wrong route that 404s in Step 2 simply downgrades that page to the manual table.

Carry the table and the Step 1/Step 2 outcomes into the Phase 9 `### Render verification` section, and pass a one-paragraph `render_verification` summary to Phase 7.

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
  > render_verification: [the Phase 6.8 summary — build result; smoke-check per space (passed / skipped with reason); cross-space invariant check result]
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

## Phase 8.5 — Finish & handoff

Run this phase only when Phase 6 wrote + committed in a git repo (write context `docs_repo`, or `non_docs_repo` confirmed at Phase 0) — i.e. a branch with this run's commits exists. Skip otherwise (nothing to hand off). Mechanics: `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md`.

### Step 1 — Squash (always)

Fold the run into clean history before handoff:
1. Stage the run's uncommitted docs-repo edits — Phase 8 Agent 1 (doc index / cross-links) and Agent 3 (`CLAUDE.md`) may have edited without committing; the Phase 6.5 clean-tree check means everything uncommitted is this run's work.
2. Compute the squash base: if Phase 6.5 recorded `profile_commit` (inline-profiling run), base = `profile_commit` (keeps the profile-config commit as a distinct first commit → two commits); otherwise base = `git merge-base <base_branch> HEAD` (one commit).
3. `git add` the docs-repo changes → `git reset --soft <squash-base>` → one `git commit`. The message follows `profile.commit_convention` when present (dynatrace-docs: `<JIRA-KEY> <summary>`); for a repo with no such field, infer from recent `git log` / `CONTRIBUTING`, else fall back to `<JIRA_KEY> <summary>`. NEVER put the Jira key in a reader-visible changelog — the commit message carries traceability.

### Step 2 — Offer push

```
choices: ["Push <branch> to origin now", "Skip — I'll push later", "Cancel"]
```
- **Push** → `git push -u origin <branch>`; report the result. (`git push` is git-protocol, not a REST API — the zero-external-API invariant is preserved.)
- **Skip** → "Branch `<branch>` ready with N commit(s). Push when ready."
- **Cancel** → stop and summarise.

### Step 3 — Copy-paste PR draft (always; no API)

Per `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §4–§5:
1. **Detect the host** from the docs repo's `git remote get-url origin` (Bitbucket Cloud / Bitbucket Server / GitHub / other).
2. **Compose the draft**: title (per `commit_convention`); body — what was documented, the output files, the Phase 6.8 render-verification summary, deferred style/review/render items, a link to the Jira VI. When Phase 5.8 recorded any `document-as-spec` / `skip-and-report` decision, prepend a banner: `> ⚠ DO NOT MERGE until <JIRA_KEY>-implementation-gaps.md is resolved.`
3. **Write + show**: write `<JIRA_KEY>-pr-draft.md` to the vault project folder (`find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if none) AND print it.
4. **Host footer**: Bitbucket → "open a PR in the web UI and paste the title + body"; GitHub → additionally offer `gh pr create --title "<title>" --body-file <pr-draft path>` that the user may run; other → "open a PR and paste the title + body". The plugin never opens the PR itself.

Carry the squash result, push outcome, and PR-draft path into the Phase 9 report.

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

### Render verification
- Build: [ran — pass/fail | no build command — boot is the proof | unverified (reason)]
- Smoke-check: [per space — passed (N pages, HTTP 200) | skipped (reason)] OR "not run (user skipped)"
- Cross-space invariant: [verified (markers present in target, absent in protected) | not checked | VIOLATION — see deferred items]
- Pages to visit: [the Phase 6.8 Step 3 table]

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
[Only populated for the **Defer** path of Phase 6.2 — i.e. a target used image_policy: cdn_upload_required (or the user selected "Stage for manual upload" under the ambiguous branch) AND the user chose "Defer — stage with TODO placeholders" at the Phase 6.2 CDN handoff. For each staged screenshot: src (original user-provided path), staging path under <screenshot_staging_dir> (the persistent Obsidian project folder), the target page it belongs on, the proposed alt-text, and the upload_note from the planner. Omit this section entirely when no screenshots were staged — including when the user chose "Upload now" in Phase 6.2 (those images carry real CDN URLs in the markdown and need no manual step).]

### Implementation gaps (Jira vs source)
[Populated when Phase 5.8 produced any document-as-spec / skip-and-report decision. List each gap (claim, decision) and: "Bug-report draft written to <path>. If docs were branched, DO NOT merge the PR until these gaps are resolved." Omit when there were no discrepancies.]

### Skipped items
[Gaps the planner flagged with recommended_action: "skip with note in final report" — one line each; or "none"]

### Deferred items
[MINOR / NIT findings that were not applied, OR user-declined screenshots, OR doc-reviewer BLOCK findings that were overridden / deferred — one line each; or "none"]

### Assumptions & limitations
- [list any]

### Git state
[When Phase 8.5 ran: "Branch <name> — squashed to N commit(s); pushed to origin: <yes/no>; PR draft: <pr-draft path>." When Phase 8.5 was skipped (no branch/commits): "Working tree has uncommitted changes. /impl:jira:docs writes but does not commit in non-git contexts."]
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

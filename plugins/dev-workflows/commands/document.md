---
name: document
description: Jira-driven feature-documentation workflow. Phase 0 preflight-discovers the docs repo + profile (in-repo → built-in dynatrace-docs default → on-demand /docs-profile) and the VI's specs dir under /workspace. Phase 4.5 determines/confirms the applicable space(s). Optional saas|managed constraint scopes the run to one space. Reads a Value Increment hierarchy from exported markdown, resolves PR diffs in parallel, synthesises product documentation, and gates on style-check and Opus doc review.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Generate product documentation for the Jira Value Increment: $ARGUMENTS

Signature: `PRODUCT-NNNN [saas|managed]`. The optional second token is a **space constraint**, not a target list. When you pass `saas` or `managed`, the command documents **only that space** and leaves the OTHER space's rendered output unchanged (SaaS pages stay as they are when you pass `managed`, and vice-versa). When you omit it, the command **determines the applicable space(s)** from the Jira hierarchy and the resolved repos, then confirms with you. `both` is intentionally NOT an accepted value — omit the argument to cover both spaces.

`/document` (Jira mode) is the **Jira-driven feature-documentation** workflow. Given a Jira Value Increment key, it reads the full Jira hierarchy from pre-exported markdown in the user's Obsidian vault, resolves PR URLs to local git repos, runs parallel PR-diff summaries, synthesises product documentation, runs style-check + Opus review gates, and writes the output to the current working directory (a product docs repository).

For small one-off doc edits, use direct mode (below). For writing child Epic drafts from a VI, use `/epics`. For release notes, use `/release-notes` — this command never writes release-notes / what's-new pages, because those are generated from Jira by the docs team's automation.

---

## Mode detection

`/document` has **two modes**, selected by the first argument token:

- **Jira mode (Mode A)** — the input resolves `jira-driven` via the shared front-end (`${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`): a first token matching a JiraID (`^[A-Z][A-Z0-9]+-[0-9]+`), optionally followed by `saas` | `managed`, **or** a directory that inspects as a Jira-export (contains `<KEY>-index.md`). The front-end's Fallback B handles a JiraID-shaped token with no `jira-products/<KEY>` folder.
- **Direct mode (Mode B)** — the input resolves `direct` (a leading `@file` token, free-text prose, or a non-Jira-export directory, which Mode B handles via its existing "anything else" path).

Echo the detected mode, then proceed to that mode's phases. The two modes share the same `docs-style-checker` / `doc-reviewer` / `doc-fixer` agents (each mode emits its own final report).

---

# Mode A — Jira-driven documentation (JiraID argument)

## Phase 0 — Load and dispatch

1. **Resolve the Jira input via the shared front-end.** Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against
   `$ARGUMENTS`. For Mode A the result is `mode: jira-driven` with `jira_key`,
   `jira_export_root` (the ticket export dir — `$VAULT_PATH/jira-products/<KEY>`
   for a JiraID, or the passed directory), `source`, and `specs`. The front-end
   owns the `$VAULT_PATH`/`jira-products` validation and Fallbacks A/B. Carry
   `jira_key`, `jira_export_root`, `focus_key`, and `specs` forward.

3. **Resolve the docs repo (cwd-preferred).** This command writes feature documentation into a product docs repository; running it outside such a repository is almost always a mistake. The **docs signals** checked throughout this step are:
   - `package.json` with any script matching `*:start`, `*:build`, `*:lint`, `docs:*`, or
   - any of `.docstack/`, `mkdocs.yml`, `docusaurus.config.js`, `antora.yml`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, or
   - a `_snippets/` directory at any level under the repo root.

   Resolve `docs_repo_path` in this order:

   - **(a) cwd with signals (preserves today's behavior).** Run `git rev-parse --show-toplevel` from cwd to resolve the git root. If it succeeds **and** ≥ 1 docs signal is present there → `docs_repo_path` = that git root and proceed silently. This keeps every downstream phase that assumes cwd correct.
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
     "Use cwd anyway" sets `docs_repo_path` = the git root of cwd (or cwd itself if not a git tree) and carries the user's confirmation forward. "Enter the docs repo path" takes a free-text absolute path and validates it exists.

   **Confirm writeable.** Once `docs_repo_path` is resolved, run `test -w <docs_repo_path>`. If it fails, stop with the named error `REPO_NOT_WRITEABLE: <docs_repo_path> is not writeable.`

4. **Recognize dynatrace-docs.** Set `is_dynatrace_docs` = `true` when the resolved `docs_repo_path` contains **both** `managed/docstack.jsonc` and `dynatrace/_content/` and — when a git remote is available (`git -C <docs_repo_path> remote get-url origin`) — its slug (last path segment, trailing `.git` stripped) is `dynatrace-docs`. Directory name alone is **not** sufficient; the signals decide.

5. **Resolve the profile** (record `profile_source`). The profile steers all later phases' conventions. Resolve in this order:
   - **(a) In-repo profile →** `in-repo`. If `<docs_repo_path>/.dev-workflows/docs-profile.yml` exists, load it. `profile_source: in-repo`.
   - **(b) dynatrace-docs built-in default →** `built-in`. Else, if `is_dynatrace_docs`, load `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/docs-profile.default.yml`. `profile_source: built-in`.
   - **(c) Custom repo, no profile →** `generated`. Else (a custom docs repo with no profile), run **inline on-demand profiling**: invoke the `/docs-profile` flow against `docs_repo_path` (Skill tool, `skill: "dev-workflows:docs-profile"`, with `docs_repo_path --inline` as its arguments — the `--inline` token tells profiling to skip its branch-naming prompt and standalone PR-draft handoff, since this command owns the single branch + PR draft) and wait for it to write `<docs_repo_path>/.dev-workflows/docs-profile.yml`. Then load that file. `profile_source: generated`. If the user cancels profiling (it produces no profile), stop with the named error `PROFILE_REQUIRED: a docs-profile is required to write into a custom docs repo; run /docs-profile or switch to a profiled repo.`

   Hold the loaded profile for later phases.

   **In-repo-profile-not-on-base guard.** When `profile_source: in-repo`, confirm the profile is committed on the base branch before relying on a docs branch cut from it. Resolve the base (`git -C <docs_repo_path> symbolic-ref --short refs/remotes/origin/HEAD`; fall back to `main`, then `master`) and run `git -C <docs_repo_path> cat-file -e <base>:.dev-workflows/docs-profile.yml`:
   - **exit 0 (present on base)** → proceed (the common case — the profile was merged earlier).
   - **non-zero (absent on base)** → the profile is only in the working tree / on an unmerged branch, so the docs branch Phase 6.2 cuts from `<base>` will not include it. Warn and ask:
     ```
     choices: ["Proceed — the run uses the in-memory profile; I'll merge the profile PR separately", "Cancel — merge the profile PR first, then re-run", "Other… (describe)"]
     ```
   Skip this check for `profile_source: built-in` (no profile file) and `generated` (the inline profiling branch is adopted by Phase 6.2, so the profile rides the single docs branch — a base check would false-fire).

6. **Specs (additive).** Use the `specs` list from the front-end (§Specs
   resolution — `$SPECS_PATH` then the directory case). `specs: []` is fine —
   specs are additive context for `/document`; proceed without prompting. For
   the downstream phases that scan or cite a single specs location (the Phase 4.5
   space hint, the Phase 5.6 image scan, the Phase 5.7 `doc-planner` dispatch,
   and the Phase 5.8 three-way analysis), also record `specs_dir` = the directory
   containing the resolved `specs` (their common parent — e.g. the
   `$SPECS_PATH/…/<KEY>…/` folder, or the directory they were found in), or
   `none` when `specs` is empty.

7. **Classify write context** for later branch/write decisions — computed against the resolved `docs_repo_path` (not necessarily cwd). Walk up from `docs_repo_path` looking for `.obsidian/`; if found, context = `obsidian`. Else if `git -C <docs_repo_path> rev-parse --show-toplevel` succeeds AND at least one docs signal from step 3 is present, context = `docs_repo`. Else if it succeeds with no docs signals, context = `non_docs_repo` (step 3 has already asked the user; their confirmation promotes this to `docs_repo` behaviour). Else context = `plain_dir`. In a normal run, Phase 0's docs-repo resolution (steps 3–4) yields a real docs repo (`docs_repo`) or a user-confirmed `non_docs_repo`; `obsidian` and `plain_dir` are **defensive guards** (they forbid branch/commit) rather than expected write targets.

   Record the resolved context — it drives Phase 6.2 (branch setup) and Phase 6.3 write rules. When `docs_repo_path` differs from cwd, record **both** and note that the writing phases (Increments 2–3) consume `docs_repo_path`, not cwd, for every write.

8. **Parse the optional space constraint.** Read `$ARGUMENTS` as `<JIRA_KEY> [space]` — the same `$ARGUMENTS` already split for `<JIRA_KEY>` in step 1; the optional second whitespace-separated token is the space constraint.
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
| Jira input | source: `<vault \| directory>`; export root: `<jira_export_root>` |
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

- **Output filename / sub-path under the resolved `docs_repo_path`** (Phase 0) (default: `<KEY>-<slug>.md`; the `doc-location-finder` in Phase 5.5 may override this per target).
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

SIGNIFICANT → no separate Opus **risk-planner** for the high-level plan (the Jira hierarchy + diff summaries *are* the plan), **but `doc-planner` (Phase 5.7) is pinned to the §2 Opus reasoning chain**; the `doc-reviewer` gate (Opus) is mandatory.

**Resolve the per-step routing.** Following `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9, record a `model_routing` block (reusing the §4 field names) resolving each model against the fallback chains:

```yaml
model_routing:
  classification: SIGNIFICANT
  reason: <one-line>
  current_model: <the model this orchestrator is running under>   # = the inline writer + Phase 5.8 framing
  detection_model: <§2.1 mid-tier Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>
  planning_model:  <§2 powerful chain: claude-opus-4-8 … fallback Sonnet per §2>   # doc-planner (5.7)
  review_model:    <§2 powerful chain>     # doc-reviewer (frontmatter-pinned; recorded here, no override added)
  implementation_model: <= planning_model>  # the doc-writer subagent (Phase 6.3) — now a delegated, Opus-pinned writer
  fixes_model: <= detection_model>         # doc-fixer (6.4 / 7) runs on the detection chain
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2 / §2.1 fallback or degradation>
```

Each subagent dispatch below cites which chain it uses (the §9 role→chain map): `doc-planner` → `planning_model`; `jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, and the Phase 8 maintenance agents → `detection_model`; `doc-reviewer` keeps its own frontmatter Opus pin (recorded as `review_model`, no override added).

**Orchestration advisory (window-focused).** `doc-planner` (5.7) and `doc-writer` (6.3) run on the §2 Opus chain regardless of session; only coordination + the interactive gates (4.5, 5.8 decision, 5.9, 6.1) run on `current_model`. So:

- **`current_model` is on the §2 chain** → no advisory.
- **`current_model` is NOT on the §2 chain and `opus_available: true`** → the heavy synthesis + writing are already on Opus; the residual risk is the orchestrator's **context window** on a **large multi-repo ticket**. Offer relaunch **only** in that case:
  ```
  choices: ["Relaunch /document under Opus — I'll restart (Recommended for large multi-repo tickets)", "Proceed on <current_model>", "Cancel"]
  ```
  Otherwise proceed without prompting.
- **`current_model` is NOT on the §2 chain and `opus_available: false`** → `planning_model`, `review_model`, and the **doc-writer** all fall to the Sonnet floor; record the degradation in `notes` and the Phase 9 report; proceed.

---

## Phase 2 — Plan + approval

Present a concise plan:

- Resolved `<JIRA_KEY>` and the Jira export root `<jira_export_root>`
- Output filename / path under the resolved `docs_repo_path` (from Phase 1)
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

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root from Phase 0]
  > jira_key:         [resolved <JIRA_KEY>]
  > depth:            full"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`) and act accordingly. On `OK`, store the handoff for downstream phases.

When `focus_key` is set (explicit `<VI> <Epic>`), also derive `focus_items` = the
focus Epic plus every linked item beneath it (its Stories / Sub-tasks). The
change-scoped phases below consume `focus_items` in place of the full hierarchy —
Phase 5 (diff summarisation) and Phase 5.7 (doc planning) — while VI-descriptive
phases (e.g. Phase 4.5 space determination) keep the full handoff. When `focus_key`
is null, every phase uses the full hierarchy exactly as today.

---

## Phase 4 — Resolve repos

From the `jira-reader` handoff `pull_requests` list:

1. Filter by `status` per the Phase 1 PR-status setting (default: MERGED only). This is the `pull_requests[].status` field, NOT the top-level `jira-reader` `status`.
2. Group the remaining PRs by `repo` (short repo name).
3. Build a slug→clone map. For each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote` call fails/times out. Result: `<slug> → [<absolute path>, ...]`.
4. Resolve each unique in-scope `repo` slug against the map:
   - **One match** — use that absolute path as `repo_path`.
   - **Multiple matches** (e.g. `cluster` and `cluster-repo`, both pointing at the same upstream) — auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last; show all candidates at plan approval so the user can override.
   - **Zero matches** — escalate using the `Repo unresolved (zero matches) — /document` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
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

→ Agent (subagent_type: "dev-workflows:diff-summarizer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Summarise this repo's PRs for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 4>
  > repo_url_slug: <repo slug, e.g. "cluster">
  > pr_refs:     [ ... full PR entries from jira-reader handoff, filtered to this repo (and, when focus_key is set, to focus_items) ... ]
  > context:    |
  >   [1–2 sentences: VI goal + themes relevant to this repo]
  > jira_keys_hierarchy:
  >   [VI key + every linked_items key from jira-reader; when focus_key is set, restrict to focus_items — the focus Epic + its linked descendants]
  > refresh:
  >   fetch: true
  >   pull:  [false if Phase 1 chose 'fetch only' (default) or 'no refresh'; true if 'fetch + pull default branch']"

After the batch returns, handle each per-repo status:

- `OK` / `PARTIAL` — store the output, continue.
- `REPO_MISSING` — should not happen at this stage (Phase 4 already checked). If it does, escalate per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
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

→ Agent (subagent_type: "dev-workflows:doc-location-finder", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Find write target(s) for the brief:
  >
  > repo_root:       [the resolved docs_repo_path (Phase 0)]
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

The confirmed target list (from any of the three paths above) is the **authoritative write-target set** for Phase 6.3 and is handed to `doc-planner` in Phase 5.7.

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

→ Agent (subagent_type: "dev-workflows:doc-planner", model: `<planning_model — §9 / §2 Opus chain>`):
  > "Produce the documentation checklist for the brief:
  >
  > jira_reader_handoff: [paste full YAML from Phase 3; when focus_key is set, restrict linked items to focus_items]
  > diff_summaries:       [paste array of diff-summarizer outputs from Phase 5]
  > write_targets:        [paste confirmed list from Phase 5.5]
  > screenshots:          [selected candidate paths from Phase 5.6, possibly empty]
  > screenshot_staging_dir: [resolved <screenshot_staging_dir> from Phase 1, or null]
  > repo_root:            [the resolved docs_repo_path (Phase 0)]
  > code_repos:           [the Phase-4 resolved {slug, path} map; [] if none resolved]
  > specs_dir:            [resolved <specs_dir> from Phase 0, or null]
  > profile:              [the docs-profile loaded in Phase 0 — drives space routing + the multi-space write strategy]
  > target_spaces:        [the resolved target_spaces from Phase 4.5: [saas] | [managed] | [saas, managed]]"

Handle the `status` and `gaps`:

- **`status: OK`, `gaps: []`** → proceed to the approval prompt.
- **`status: OK` or `PARTIAL` with `gaps` entries** — for each gap, act on its `recommended_action`:
  - `"ask user"` → prompt inline **before** showing the checklist-approval choice. Free-text prompt scoped to the gap; feed the answer back to the planner via a single re-invocation (pass the user's answer as an additional `gap_resolution` field in the brief). If the user declines, fall back to `"mark TODO in draft"`.
  - `"mark TODO in draft"` → surface in the checklist display as a visible TODO; the writer at Phase 6.3 emits `<!-- TODO: … -->` markers. Does not block approval.
  - `"skip with note in final report"` → list in the checklist display; carry forward into the Phase 9 `### Skipped items`. Does not block approval.
- **`status: PARTIAL`** alone (without user-asked gaps) is presented to the user alongside the checklist so the approval decision is informed.

Present the checklist (with any gaps + dispositions):
```
choices: ["Approve & write (Recommended)", "Adjust (describe)", "Cancel"]
```

---

## Phase 5.8 — Discrepancy analysis & user decision

Run this phase when the `doc-planner` handoff contains any `verification_warnings` with `finding: CONTRADICTED`, `NOT_FOUND`, `AMBIGUOUS`, or verdict `SPEC-VS-JIRA`. If there are none, skip to Phase 6.3.

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

4. **Record `discrepancy_decisions[]`** keyed by `number` (claim, jira_phrasing, spec_phrasing, source_phrasing, source_location, decision ∈ {document-as-spec, document-as-code, skip-and-report}, rationale). `spec_phrasing` is recorded verbatim (`(no spec)` when none was provided). Set `bug_report_destination` to the ticket's vault project folder (resolved exactly like the release-notes destination in `/release-notes` — `find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if none) when any decision is `document-as-spec` (where the code lags the intended phrasing) or `skip-and-report`.

Pass `discrepancy_decisions` to Phase 6.3.

---

## Phase 5.9 — Write-strategy approval (multi-space safety)

Run this phase when the `doc-planner` checklist contains **any** target whose
`write_strategy.strategy` is `conditional` or `override-copy` (i.e. at least one
shared page needs cross-space protection). If every target is `plain`, skip to
Phase 6.3 — there is nothing to protect.

The mechanics are defined in
`${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md`; this
phase only confirms the per-page **strategy choice** before Phase 6.3 writes.

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

4. **Record `write_strategies[]`** keyed by `target_path`: `{target_path, strategy ∈ {conditional, override-copy, plain}, target_space, rationale}`. Targets the planner marked `plain` are carried through as `plain` without prompting. Pass `write_strategies` to Phase 6.3.

---

## Phase 6.1 — CDN image handoff

Run this phase only when, in the Phase 5.7 `doc-planner` return, **any** screenshot has `image_policy: cdn_upload_required` — **or** the user picked "Stage for manual upload" under an `ambiguous` target in Phase 6.3. (When the only image policy in play is `local`, skip this phase: local images are copied into the repo at Phase 6.3 with no handoff needed.)

1. **List each affected image** so the decision is informed — one row per image:
   - target page / anchor it belongs on (from the planner's per-screenshot placement);
   - proposed alt text;
   - the planner's `upload_note`.

2. **Ask how to handle the upload:**
   ```
   choices: ["Upload now — I'll paste the CDN links (Recommended)", "Defer — stage with TODO placeholders + Phase 9 list", "Cancel", "Other… (describe)"]
   ```

   - **Upload now** → collect one CDN URL per image (prompt per image, or one URL per line in image order). Validate each pasted value looks like a URL (e.g. starts with `http://` / `https://`); re-prompt for any that don't. Record `cdn_urls[<image>]`. Phase 6.3 then writes the **real CDN URL** into each markdown image reference instead of a TODO placeholder. Nothing is staged and the Phase 9 "Screenshots to upload manually" section stays empty for these images.
   - **Defer** → the existing async behavior: stage each image under `<screenshot_staging_dir>` (the ticket's persistent Obsidian project folder resolved in Phase 1), Phase 6.3 inserts the `TODO-upload` placeholder reference, and every staged image is listed in the Phase 9 `### Screenshots to upload manually` section.
   - **Cancel** → stop and summarise.

   Record the decision as `cdn_handoff_decision ∈ {upload-now, defer}` and carry it (with any `cdn_urls`) into Phase 6.3.

---

## Phase 6.2 — Branch setup (conditional)

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
   - **Inline-profiling case** (`profile_source: generated`): Phase 0's `/docs-profile` already ran `git switch -c <profile-branch>` and committed `.dev-workflows/docs-profile.yml`, so HEAD is already on that branch. Do NOT create a new branch — rename it with `git branch -m <name>`. Record `profile_commit` = the commit that introduced the profile config: `git log --diff-filter=A --format=%H -- .dev-workflows/docs-profile.yml | head -1`. Phase 8.5 squashes the docs commits onto `profile_commit`, keeping the profile-config commit as a distinct first commit. (Per `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §1.)

No external CLI calls; all git operations are local.

---

## Phase 6.3 — Write documentation

The writing is delegated to the **`doc-writer`** subagent (pinned to the §2 Opus reasoning chain — see `classification.md` §9.2). The orchestrator prepares a structured handoff and dispatches; it does not write pages itself.

1. **Write the handoff file.** Create a temp file (`mktemp`, e.g. `$(mktemp -t dw-<JIRA_KEY>-XXXX.yml)` — never the vault, never the docs repo) containing the `doc-writer` input contract: `jira_reader_handoff`, `diff_summaries`, `write_targets`, `doc_planner_checklist` (+ gap dispositions), `discrepancy_decisions` (Phase 5.8), `write_strategies` (Phase 5.9), `cdn_handoff_decision` + `cdn_urls` + `screenshot_staging_dir` + `screenshots` (Phase 6.1), `target_spaces`, `profile`, `docs_repo_path`, and `bug_report_destination`. Record its absolute path.

2. **Dispatch the writer:**

→ Agent (subagent_type: "dev-workflows:doc-writer", model: `<planning_model — §9 / §2 Opus chain>`):
  > "Write the product documentation for this brief.
  >
  > handoff_file: [absolute path of the temp handoff file from step 1]"

3. **Handle the return.**
   - **`status: DONE`** — record `files_written` + `notes` for Phases 6.4 / 6.5 / 7 / 8. Then **commit** per the branch/commit policy below.
   - **`status: BLOCKED`** — surface the named gap to the user:
     ```
     choices: ["Provide the missing input (you'll be prompted)", "Cancel"]
     ```
     On a provided value, rewrite the handoff file and re-dispatch once.

Write context governs branch/commit (Phase 0 step 7); **the orchestrator commits the writer's output** (the writer never commits):

| Write context | Branch | Commit |
|---|---|---|
| `obsidian` | NEVER | NEVER |
| `docs_repo` | YES (opt-in confirmed at plan approval) — see Phase 6.2 | YES (orchestrator commits doc-writer's `files_written`) |
| `non_docs_repo` | Phase 0 step 3 already asked user to confirm; if confirmed, behave as `docs_repo` | YES (if user confirmed at Phase 0) |
| `plain_dir` | NEVER | NEVER |

---

## Phase 6.4 — Style check (before reviewer)

**Mandatory:** the orchestrator MUST dispatch `docs-style-checker` and act on its return — never skip on its own judgement of which linters are installed.

`docs-style-checker` runs the chain **internally**: the repo's primary linter (Vale, etc.) AND — when the `dt-style-guide` plugin is installed — `dt-style-checker` as a complementary semantic / cross-page-consistency pass, merging and deduping both finding sets. The two are complementary, not redundant (Vale: lexical at scale + frontmatter; `dt-style-checker`: engineer jargon, cross-page label consistency, subject-verb agreement, plural/singular label mismatch). The command does NOT invoke `dt-style-checker` separately — the agent already did.

Invoke `docs-style-checker` on the files written in Phase 6.3:

→ Agent (subagent_type: "dev-workflows:docs-style-checker", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > repo_root: [the resolved docs_repo_path (Phase 0)]
  > files:     [absolute paths of every file written or modified in Phase 6.3]"

Act on the return:

- **`status: NOT_CONFIGURED`** — neither a repo linter NOR the `dt-style-checker` complementary pass was available (the agent already tried both). Proceed to Phase 7; `doc-reviewer` will still check correctness/completeness.
- **`status: OK`** — the chain ran (primary and/or complementary), zero merged violations. Proceed to Phase 7.
- **`status: VIOLATIONS_FOUND`** — invoke `doc-fixer` with the violations treated as per their severity. After `doc-fixer` completes, re-run the linter once:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the style violations for this brief:
    >
    > Task description: [doc writing for <JIRA_KEY>]
    > Reviewer or style-checker output: [paste full docs-style-checker output]
    > Project root: [the resolved docs_repo_path (Phase 0)]
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

## Phase 6.5 — Render verification

Run this phase after Phase 6.4 **only** when Phase 6.3 wrote files into a buildable docs repo (write context `docs_repo`, or `non_docs_repo` confirmed at Phase 0). Skip for `obsidian` / `plain_dir` (nothing was written into a repo that builds). Mechanics: `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/render-verification.md`. "Affected pages" = every file written or modified in Phase 6.3.

### Step 1 — Build check (gating)

Run `profile.commands.build` if the profile defines one. Do NOT re-run the Phase 6.4 prose linter. Classify any failure:
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

Invoke `doc-reviewer` (Opus — pinned by its own frontmatter; recorded as `review_model`, no dispatch override added). The reviewer is **product-docs-only**; Epic drafts go through `epic-reviewer` in `/epics`.

→ Agent (subagent_type: "dev-workflows:doc-reviewer"):
  > "Review the written product documentation for this brief:
  >
  > Task description: [one-paragraph summary of the feature and <JIRA_KEY>]
  > Written doc file paths: [absolute paths of every file written in Phase 6.3]
  > Jira directory path:    [<jira_export_root>]
  > Diff summaries:         [array of diff-summarizer outputs from Phase 5]
  > doc-planner checklist:  [the full YAML from Phase 5.7]
  > style-check report: [the violations output from Phase 6.4 — from docs-style-checker or dt-style-checker (fallback), or 'status: NOT_CONFIGURED' if neither ran]
  > render_verification: [the Phase 6.5 summary — build result; smoke-check per space (passed / skipped with reason); cross-space invariant check result]
  > code_repos:         [the Phase-4 resolved {slug, path} map; [] if none resolved]"

Act on the verdict:

- **BLOCK** — invoke `doc-fixer` with `Severities to fix: BLOCKER and MAJOR`. Re-invoke `doc-reviewer` once. If the second verdict is still BLOCK, escalate for each unresolved BLOCKER individually per the `Review verdict BLOCK (unresolved after one fix cycle) — /document` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
  ```
  choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]
  ```
  "Manual fix notes" → take free-text from the user; apply via `doc-fixer` in a bounded one-shot pass (no further re-review cycle). "Defer" → record in Phase 9 `### Deferred items` without an override flag. "Override" → record in `### Deferred items` with the user's rationale. "Cancel" aborts.

- **PASS WITH RECOMMENDATIONS** — invoke `doc-fixer` for MAJOR findings only:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the review findings for this brief:
    >
    > Task description: [doc writing for <JIRA_KEY>]
    > Reviewer or style-checker output: [paste full doc-reviewer output]
    > Project root: [the resolved docs_repo_path (Phase 0)]
    > Severities to fix: BLOCKER and MAJOR"

  MINOR / NIT findings are deferred to the Phase 9 report.

- **PASS** — proceed to Phase 8.

Cap: one fix cycle + one re-review maximum.

---

## Phase 8 — Post-implementation maintenance

First gather the change context:

a. Run `git -C <docs_repo_path> diff --stat` against the base branch (if branching happened at Phase 6.2) or against HEAD (if no branching) and capture the list of changed files.
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

**Agent 1 — Documentation** (general-purpose, model: `<detection_model — §9 / §2.1 Sonnet chain>`):
> "Post-write documentation review. Change summary:
> [paste change summary block]
>
> Scan for README.md, CHANGELOG.md, docs/, or any .md files in the project root or an adjacent docs tree.
> Determine if *other* documentation needs updating as a consequence of this write (e.g., an index page, a cross-referenced overview, a changelog entry in the repo root). Do NOT touch release-notes / what's-new pages — those are generated from Jira by automation.
> - Skip if: the edit is confined to the intended target pages with no inbound cross-references.
> - Update if: new page requires an index/sidebar entry, new sections require inbound cross-links.
> If an update is warranted: apply minimal edits to the relevant section(s).
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose, model: `<detection_model — §9 / §2.1 Sonnet chain>`):
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

**Agent 3 — Instructions** (general-purpose, model: `<detection_model — §9 / §2.1 Sonnet chain>`):
> "Post-write instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any doc-writing rules, guidance, or guardrails are missing because of what this run revealed (e.g., a repo-specific frontmatter field that must always be present, a cross-link pattern that's easy to miss, an image-policy rule that caught you out).
> Skip if: the run followed existing conventions with no surprises. Only update if a concrete, recurring rule would have prevented a decision point or misunderstanding.
> If YES: apply minimal, additive, scoped changes only — do not rewrite sections wholesale.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance, model: `<detection_model — §9 / §2.1 Sonnet chain>`):
> "Analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /document
> - What was done: [one-paragraph summary of the documentation produced]
> - Key events: [BLOCK reviews encountered and their reason, ambiguous image policies, unresolved PRs, style-check failures, branch-naming conflicts — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
> - Test result: N/A (no tests in /document)
> - Project root: [the resolved docs_repo_path (Phase 0)]"

Collect all four summaries for the Phase 9 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /document (Jira mode)`, the run's `jira_key` and `source`, and
`plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
`emit-auto` renders only the report's **Command workflow improvements**, **New
agents / skills**, and plugin **Reference docs** sections plus the **Key
observations** that triggered them (§4 plugin-facing predicate) — never
target-project `CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by
stable `id` (§3), resolves the target via the §2 specs-first ladder, and writes
silently. List the persisted path (or "no plugin-facing signal — nothing
persisted") in the Phase 9 report's Session learnings line. ADDITIVE — the
impl-maintenance report still appears in the report; this step NEVER fails the
run, NEVER commits, and NEVER writes into the docs repo or the current working
directory.

---

## Phase 8.5 — Finish & handoff

Run this phase only when Phase 6.3 wrote + committed in a git repo (write context `docs_repo`, or `non_docs_repo` confirmed at Phase 0) — i.e. a branch with this run's commits exists. Skip otherwise (nothing to hand off). Mechanics: `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md`.

### Step 1 — Squash (always)

Fold the run into clean history before handoff:
1. Stage the run's uncommitted docs-repo edits — Phase 8 Agent 1 (doc index / cross-links) and Agent 3 (`CLAUDE.md`) may have edited without committing; the Phase 6.2 clean-tree check means everything uncommitted is this run's work.
2. Compute the squash base: if Phase 6.2 recorded `profile_commit` (inline-profiling run), base = `profile_commit` (keeps the profile-config commit as a distinct first commit → two commits); otherwise base = `git merge-base <base_branch> HEAD` (one commit).
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
2. **Compose the draft**: title (per `commit_convention`); body — what was documented, the output files, the Phase 6.5 render-verification summary, deferred style/review/render items, a link to the Jira VI. When Phase 5.8 recorded any `document-as-spec` / `skip-and-report` decision, prepend a banner: `> ⚠ DO NOT MERGE until <JIRA_KEY>-implementation-gaps.md is resolved.`
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

### Model Routing
- Session / writer model (current_model): [model] — [if it ran degraded: "Sonnet; user proceeded past the Phase 1.5 advisory" | "Sonnet; no Opus available" | "on §2 chain — no degradation"]
- doc-planner synthesis (planning_model): [model]
- Detection steps — jira-reader, diff-summarizer, doc-location-finder, docs-style-checker, doc-fixer, maintenance (detection_model): [model]
- doc-reviewer (review_model): [model]
- Opus available: [yes | no]

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
[branch name created in Phase 6.2, e.g. docs/<jira-key>-<slug>] OR "N/A — no branch created (context: obsidian / plain_dir / user declined branching)"

### Render verification
- Build: [ran — pass/fail | no build command — boot is the proof | unverified (reason)]
- Smoke-check: [per space — passed (N pages, HTTP 200) | skipped (reason)] OR "not run (user skipped)"
- Cross-space invariant: [verified (markers present in target, absent in protected) | not checked | VIOLATION — see deferred items]
- Pages to visit: [the Phase 6.5 Step 3 table]

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
[Only populated for the **Defer** path of Phase 6.1 — i.e. a target used image_policy: cdn_upload_required (or the user selected "Stage for manual upload" under the ambiguous branch) AND the user chose "Defer — stage with TODO placeholders" at the Phase 6.1 CDN handoff. For each staged screenshot: src (original user-provided path), staging path under <screenshot_staging_dir> (the persistent Obsidian project folder), the target page it belongs on, the proposed alt-text, and the upload_note from the planner. Omit this section entirely when no screenshots were staged — including when the user chose "Upload now" in Phase 6.1 (those images carry real CDN URLs in the markdown and need no manual step).]

### Implementation gaps (Jira vs source)
[Populated when Phase 5.8 produced any document-as-spec / skip-and-report decision. List each gap (claim, decision) and: "Bug-report draft written to <path>. If docs were branched, DO NOT merge the PR until these gaps are resolved." Omit when there were no discrepancies.]

### Skipped items
[Gaps the planner flagged with recommended_action: "skip with note in final report" — one line each; or "none"]

### Deferred items
[MINOR / NIT findings that were not applied, OR user-declined screenshots, OR doc-reviewer BLOCK findings that were overridden / deferred — one line each; or "none"]

### Assumptions & limitations
- [list any]

### Git state
[When Phase 8.5 ran: "Branch <name> — squashed to N commit(s); pushed to origin: <yes/no>; PR draft: <pr-draft path>." When Phase 8.5 was skipped (no branch/commits): "Working tree has uncommitted changes. /document (Jira mode) writes but does not commit in non-git contexts."]
```

---

## Phase 10 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 9 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's out-of-scope / manual-step
follow-ups as durable Obsidian tasks (and notes) by citing
`${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` and executing its steps
inline.

1. **Collect** the follow-up items already aggregated in the Phase 9 report:
   `### Screenshots to upload manually`, `### Implementation gaps (Jira vs source)`,
   `### Skipped items`, and `### Deferred items`.
2. **Filter** them with the reference's §6 qualifying predicate — emit only
   out-of-scope / manual-step signals; drop in-scope items the report already
   tracks.
3. **Resolve** the write target via the §4 vault-availability ladder using the
   run's `jira_key` and `source`; render + place tasks and verbose notes per
   §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 9 report (today's behaviour).
This phase NEVER fails the run, NEVER commits, and NEVER writes into the docs
repo or the current working directory.

---

## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /document (Jira mode)`, `phase: documenting`,
`role: dev`, the run's `jira_key` and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into
the docs repo or the current working directory; no user name is ever written
(§10 privacy).

---

## Invariants (always enforced)

- ALWAYS run Phase 0 docs-repo detection; if 0 signals, require user confirmation before proceeding
- NEVER call Bitbucket REST APIs for Cloud or self-hosted Server — Bitbucket URLs are identifiers only; all resolution is pure local git
- GitHub URLs may use the `gh` CLI for head/base SHA resolution; no direct REST calls outside `gh`
- NEVER write inside `_archive/` — that path is read-only by convention
- NEVER write inside `jira-products/` — that path is re-created from scratch on every Jira import; writes there will be lost
- NEVER write product documentation outside the resolved `docs_repo_path` (Phase 0); the only other writes are to the ticket's vault project folder under `$VAULT_PATH` (the `<JIRA_KEY>-implementation-gaps.md` bug-report draft, the `<JIRA_KEY>-pr-draft.md`, and screenshot staging) — never anywhere else.
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS invoke `docs-style-checker` (Phase 6.4) before `doc-reviewer` (Phase 7)
- ALWAYS invoke `doc-reviewer` before Phase 8 maintenance
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin each subagent dispatch to its §9 chain via `model:` — `doc-planner` to the §2 Opus chain, the mechanical steps (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, maintenance) to the §2.1 Sonnet chain; `doc-reviewer` keeps its frontmatter Opus pin (no override); the inline writer + gates run on `current_model` (advisory only)
- ALWAYS cap review/fix cycles: 1 fix + 1 re-review max
- ALWAYS pass `Change type: docs` in the Phase 8 change summary block
- ALWAYS pass `Command run: /document` in the Phase 8 Agent 4 session handoff
- ALWAYS spawn Phase 8 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 9 report as the final output
- ALL written claims must be traceable to Jira keys or PR diffs; if only Jira is available, cite the Jira key alone
- For `image_policy: cdn_upload_required`, NEVER copy user-provided screenshots into the repo — stage under `<screenshot_staging_dir>`, the ticket's persistent Obsidian project folder under `$VAULT_PATH` (never the docs repo, never `/tmp`) — and surface in the Phase 9 `### Screenshots to upload manually` section

---

# Mode B — direct documentation edit (`@file` / free-text)

Implement the following doc edit: $ARGUMENTS

If the argument starts with `@`, treat it as a path to a markdown file. Resolve relative to the current working directory. Read its full content and use it as the description. Echo `📄 Reading prompt from \`<file>\`…` before proceeding. If the file cannot be read, stop and report the error immediately.

`/document` (direct mode) is the **one-shot doc-editing** workflow — minor edits, formatting, small updates to existing pages, and single-file additions where the content comes from the user's description alone. It is the right tool when:
- the change is small and the content is already in the user's head or the file, **not** scattered across Jira items and PR diffs
- no tests, no branch, no code review, and no commit are warranted

For net-new documentation assembled from a Jira hierarchy plus PR diffs, use Jira mode (above). For writing child Epic drafts from a Value Increment, use `/epics`.

No model-routing reminder is injected for this command — classification still happens but is always SIMPLE or MODERATE, and Opus is never invoked.

---

## Phase 0 — Load the description

If `@file` syntax: read the file, confirm `"Loaded prompt from <filename.md> (N lines)."`, note any embedded images as "referenced image: <path>". Otherwise use the inline text verbatim.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess. This rule is absolute.**

Before producing a plan, analyze the description for:
- Ambiguous scope or unclear boundaries (which file? which section? extend or replace?)
- Conflicting style guidance in the repo vs. the user's wording
- Multiple valid placements for new content
- Undefined target audience (end-user vs developer vs operator)
- Missing acceptance criteria (what makes this "done"?)

If **any** ambiguity exists, ask the user. Rules:
- Use `choices` arrays for every question — never plain text questions
- The **last choice** in every `choices` array MUST be `"Other… (describe)"` to allow free-text
- When a clearly superior default exists, make it the first choice and label it `"(Recommended)"`
- Group related decisions into a single question (minimize total questions)
- Do **not** proceed until all questions are answered

If **nothing** is ambiguous, skip directly to Phase 1.5.

---

## Phase 1.5 — Classify task complexity

Doc edits in this command are always either **SIMPLE** or **MODERATE**:

- **SIMPLE** — single file, small additions / fixes / rewording, no cross-file linking
- **MODERATE** — multi-file edit, non-trivial restructure, or content that needs internal cross-references

If your reading of the task lands closer to SIGNIFICANT or HIGH-RISK (multi-repo, net-new feature pages from a Jira hierarchy, published-documentation blast radius that needs a reviewer gate), **stop and redirect the user** to Jira mode or `/epics`:
```
choices: ["Re-run under /document (Jira mode) (for Jira-sourced feature documentation) (Recommended)", "Re-run under /epics (for Epic drafting)", "Proceed under direct mode anyway — I accept the simplified flow", "Cancel"]
```

State the classification and a one-line reason, then proceed to Phase 2A.

*(There is no Phase 2B, Phase 3B, or Opus review in this command. A mandatory Phase 3.5 style check runs after Phase 3. Phase numbering is kept aligned with `/implement` to make cross-referencing straightforward; the A-suffix on Phase 2A below is retained for symmetry, not because a Phase 2B exists for docs.)*

---

## Phase 2A — Plan

**Repo exploration** — Before writing the plan, spawn an exploration subagent to map the relevant docs and any sibling conventions:

→ Agent (subagent_type: "general-purpose", tools: Read/Glob/Grep/LS only — no Bash, no Edit):
  "Given this doc-edit description: [paste the full description from Phase 0 or Phase 1 here], find and return:
   - Target file(s) and their current structure (headings, frontmatter, approximate size)
   - Sibling / adjacent pages that may need matching updates (cross-references, navigation files, index pages)
   - Style / naming / frontmatter conventions visible in 2–3 neighbouring files (e.g. YAML frontmatter fields, heading depth, `[[wikilink]]` vs `[text](url)` preference)
   - Existing reference docs that govern this content (e.g. `CONTRIBUTION.md`, `DOCUMENTATION-GUIDELINES.md`, `STYLE.md`)
   Return a structured summary — no edits."

**Wait for the agent's response before proceeding.** If the agent returns no relevant files or fails, gather the context yourself via Read/Glob/Grep before drafting the plan.

Produce a written plan with these sections:

1. **Classification** — `SIMPLE` or `MODERATE` (with reason)
2. **Goal** — one-sentence summary of the desired end state
3. **Approach** — chosen edit strategy and why (extend existing page vs. create new vs. restructure)
4. **Steps** — numbered, concrete edits
5. **Files to create/modify** — list with brief rationale for each
6. **Validation** — spot-check steps to run after the edit. Replace the `/implement` "Tests" section with this. Typical checks:
   - Heading structure renders correctly (no orphan H3 under H1, no skipped levels)
   - All `[[wikilinks]]` resolve to existing files in the vault / docs tree
   - All `[text](relative-path)` links resolve on disk
   - YAML frontmatter parses (if the page has frontmatter)
   - `changelog:` or equivalent field updated if the repo's convention requires one
   - No broken inline image references
   - Spell-check / grammar only if the repo has a configured linter (e.g. Vale, markdownlint); do not run any linter that isn't already configured
7. **Assumptions** — decisions made without user input (must be minimal)
8. **Out of scope** — explicitly list what is NOT being done (e.g., "not renaming the file", "not updating sibling pages")

Then ask:
```
"Doc-edit plan ready. What would you like to do?"
choices: ["Approve & implement now (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → proceed to Phase 3
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarize what was planned

---

## Phase 3 — Implementation

**Implement immediately. Do NOT ask "Should I implement?" or any variation.**

1. Work through each edit in order
2. Make precise, surgical changes — do not rewrite sections wholesale when a targeted edit is enough
3. Follow the repo's detected style conventions from the Phase 2A exploration; LF line endings
4. If a **new ambiguity** emerges mid-edit: STOP, ask with choices (last: `"Other… (describe)"`), resume after answer
5. After all edits: run the Validation checks from the plan's step 6. Fix any failures caused by your changes (broken links, unparseable frontmatter, bad heading hierarchy).
6. **Do NOT run tests.** This command has no test phase — validation checks are all that's expected.
7. **Do NOT create a branch or commit.** The user manages git manually for doc edits.
8. Verify the outcome matches the approved plan.
9. Proceed to Phase 3.5.

---

## Phase 3.5 — Style check (mandatory)

After writing the edits and before Phase 4, dispatch `docs-style-checker` on the changed file(s):

→ Agent (subagent_type: "dev-workflows:docs-style-checker"):
  > repo_root: [cwd's git root]
  > files:     [the files edited in Phase 3]

- `VIOLATIONS_FOUND` → apply safe fixes via `doc-fixer` (one fix cycle), then re-run once.
- `OK` / `NOT_CONFIGURED` → proceed to Phase 4 (NOT_CONFIGURED means no primary linter AND `dt-style-guide` not installed — recorded, not silently ignored).
- `ERROR` → surface the reason; proceed to Phase 4 (the edit is small and user-managed).

Never skip this phase on your own judgement of which linters are installed. `docs-style-checker` runs the chain internally: the primary linter PLUS `dt-style-checker` as a complementary semantic pass when the `dt-style-guide` plugin is installed (and as the fallback when the primary linter fails) — so the semantic / cross-page class is never silently dropped just because Vale exists.

---

## Phase 4 — Post-implementation maintenance

First gather the actual change context:

a. Run `git diff --stat` (or equivalent) and capture the list of changed files with line counts. Note: the user has not committed, so `git diff --stat` will reflect unstaged changes.
b. Compose a **change summary block**:

```
Implementation: [one-sentence description of what was edited]
Change type: docs
Classification: [SIMPLE | MODERATE]
Files changed (from git diff --stat):
<paste the git diff --stat output>
Notable additions/removals: [new pages, new sections, new cross-links, restructured navigation — one line each; or "none"]
Validation result: [PASS | PARTIAL — with note on what's still broken]
```

Then spawn all four Phase 4 agents. They are independent and can run in any order — spawn them all before waiting for any to complete:

**Agent 1 — Documentation** (general-purpose):
> "Post-doc-edit documentation review. Change summary:
> [paste change summary block]
>
> Scan for README.md, CHANGELOG.md, docs/, or any .md files in the project root or a docs/ directory that are adjacent to the edited files.
> Determine if *other* documentation needs updating as a consequence of this edit (e.g., an index page, a cross-referenced overview, a changelog entry in the repo root).
> - Skip if: purely a typo fix, reformat, or edit confined to a single page with no cross-references
> - Update if: new page, restructured content, renamed headings that break inbound links, new cross-references that need a mate added elsewhere
> If an update is warranted: apply minimal edits to the relevant section(s).
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose):
> "Post-doc-edit knowledge review. Change summary:
> [paste change summary block]
>
> Check ~/.claude/memory/ (global) and .claude/memory/ (project-level, preferred for repo-specific knowledge) for existing knowledge files.
> Determine if a new knowledge entry is warranted — look for: reusable insights about this repo's doc conventions, non-obvious style rules uncovered, tooling gotchas (Vale rule interactions, snippet conventions).
> If YES: append to the most appropriate existing file (never create a new file if an existing one fits) using this format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the doc-edit description]
> Return: file updated/created and summary of entry, OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-doc-edit instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any doc-editing rules, guidance, or guardrails are missing because of what this edit revealed (e.g., a repo-specific frontmatter field that must always be present, a cross-link pattern that's easy to miss, a style rule that caught you out).
> Skip if: the edit followed existing conventions with no surprises. Only update if a concrete, recurring rule would have prevented a decision point or misunderstanding during this edit.
> If YES: apply minimal, additive, scoped changes only — do not rewrite sections wholesale.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance):
> "Analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /document (direct mode)
> - What was done: [one-paragraph summary of the doc edit]
> - Key events: [ambiguities that required user clarification, style-rule surprises, broken links encountered and fixed, convention mismatches — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: N/A (no review gate in /document direct mode)
> - Test result: N/A (no tests in /document direct mode)
> - Project root: [absolute path]"

Collect all four summaries for the Phase 5 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /document (direct mode)`, the run's `jira_key` (usually `null` in
direct mode) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only
the report's **Command workflow improvements**, **New agents / skills**, and
plugin **Reference docs** sections plus the **Key observations** that triggered
them (§4 plugin-facing predicate) — never target-project `CLAUDE.md`/hook advice
— as `origin: auto` entries, dedupes by stable `id` (§3), resolves the target
via the §2 specs-first ladder, and writes silently. List the persisted path
(or "no plugin-facing signal — nothing persisted") in the Phase 5
`### Session learnings (Agent 4)` line. ADDITIVE — the impl-maintenance report
still appears in the report; this step NEVER fails the run, NEVER commits, and
NEVER writes into the docs repo or the current working directory.

---

## Phase 5 — Final Report

Output a structured report — do NOT ask any closing confirmation:

```
## Doc-edit Report

### Classification
[SIMPLE | MODERATE] — [reason]

### What was edited
[High-level summary]

### Files changed
- path/to/file.ext — [what changed]

### Validation
- [check name] → [result]
- ...

### Documentation (Agent 1)
- [file updated] — [what was added/changed] OR "no update required (reason)"

### Knowledge base (Agent 2)
- [file updated/created] — [summary of entry] OR "no update required"

### Instructions (Agent 3)
- [summary of change] OR "no update required"

### Session learnings (Agent 4)
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Assumptions & limitations
- [list any]

### Deferred items
- [anything the user asked to defer, OR validation failures the user accepted, OR "none"]

### Git state
The working tree has uncommitted changes. `/document` (direct mode) never commits — you manage git manually. Run `git status` to review, then commit when ready.
```

---

## Phase 6 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 5 Final Report is composed; NEVER
interrupts an earlier phase. Persist any out-of-scope / manual-step follow-ups
by citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` and executing
its steps inline.

1. **Collect** the follow-up items from the Phase 5 `### Deferred items` section
   (direct edits rarely produce out-of-scope work; this phase is usually a
   no-op).
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder. Direct mode usually has no
   `jira_key` (`source = none`), so tasks land in `Tasks.md # Irregular` when the
   vault is writable, else the phase degrades to report-only.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 5 report. This phase NEVER
fails the run, NEVER commits (the user manages git manually), and NEVER writes
into the docs repo or the current working directory.

---

## Phase 7 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 6 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /document (direct mode)`, `phase: documenting`,
`role: dev`, the run's `jira_key` (usually `null` in direct mode) and `source`,
and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into
the docs repo or the current working directory; no user name is ever written
(§10 privacy).

---

## Invariants (always enforced)

- ALWAYS run Phase 3.5 (style check) after editing — `docs-style-checker` falls back to `dt-style-checker`; never skip style on tool-absence judgement
- NEVER create a git branch (the user manages git manually)
- NEVER run tests (this command has no test phase)
- NEVER invoke Opus (no planning agent, no review agent — docs edits are always SIMPLE or MODERATE)
- NEVER commit (the user manages git manually)
- NEVER make assumptions that could have been asked — ask instead
- NEVER end implementation with "Should I implement?" — if approved, implement
- NEVER rewrite sections wholesale when only a targeted edit is needed
- NEVER skip Phase 4 — documentation, knowledge, instructions, and session-maintenance are mandatory after every successful doc edit; always collect all four agent summaries for Phase 5
- ALWAYS run the Phase 2A exploration subagent before drafting the plan
- ALWAYS pass `Change type: docs` in the Phase 4 change summary block
- ALWAYS pass `Command run: /document (direct mode)` in the Phase 4 Agent 4 session handoff
- ALWAYS spawn Phase 4 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 5 report as the final output
- ALWAYS run the Validation checks from the plan — validation failures are surfaced in the Phase 5 report, not silently accepted
- IF the task reads as SIGNIFICANT / HIGH-RISK on inspection: redirect to `/document` (Jira mode) or `/epics` rather than proceeding under the simplified flow

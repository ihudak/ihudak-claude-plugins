---
name: document
description: keyed feature-documentation workflow. Phase 0 preflight-discovers the docs repo + profile (in-repo → built-in example-docs default → on-demand /docs-profile) and the PRD's specs dir under /workspace. Reads a Product Requirements Document hierarchy from exported markdown, resolves PR diffs in parallel, synthesises product documentation, and gates on style-check and Opus doc review.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Generate product documentation for the resolved Product Requirements Document: $ARGUMENTS

Signature: one positional address — a key, or an `@<path>` naming a folder in the specs tree. Phase 5.5 resolves each write target against the content roots the resolved profile declares, and Phase 6.3 writes each page into the root that owns it.

`/document` (keyed mode) is the **keyed feature-documentation** workflow. Given a PRD address, it reads the resolved PRD folder, resolves PR URLs to local git repos, runs parallel PR-diff summaries, synthesises product documentation, runs style-check + Opus review gates, and writes the output to the current working directory (a product docs repository).

For small one-off doc edits, use direct mode (below). For writing child Epic drafts from a PRD, use `/epics`. For release notes, use `/release-notes` — this command never writes release-notes / what's-new pages, because those are generated from the tracker by the docs team's automation.

---

## Mode detection

`/document` has **two modes**, selected by the first argument token:

- **Keyed mode (Mode A)** — the first token is a **single positional address**: a `<KEY>` matching `references/addressing.md` §1's grammar, or an `@<path>` naming a folder in the specs tree. `resolve-address` (§3) turns it into a folder; `status: absent` means no such folder exists, and `ambiguous` is a stop naming every match.
- **Direct mode (Mode B)** — no positional address: a leading `@file` token, free-text prose, or a directory that is not in the specs tree, which Mode B handles via its existing "anything else" path.

**The mode test is the presence of an address**, which is what replaces the retired shared front-end's own mode return. Mode B is unchanged in every other respect — a direct-mode run is byte-identical to before.

**Specs-repo preflight.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session
artifacts from an earlier run, retry an artifact commit that failed to push,
and settle the branch. This runs against `$SPECS_PATH` only — `git -C
"$SPECS_PATH"`, never a `cd`, so the code/docs repo this run is working
in is untouched (§1 rule 1). Prompt-free and silent when the specs repo
is clean and on its default branch. If a guard fires, emit its §5 notice;
if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole
run — the terminal `commit-artifacts` step skips on it.

Echo the detected mode, then proceed to that mode's phases. The two modes share the same `docs-style-checker` / `doc-fixer` agents; only Keyed mode also runs `doc-reviewer` (each mode emits its own final report).

---

# Mode A — keyed documentation (address argument)

## Phase 0 — Load and dispatch

1. **Resolve the address.** Parse the single positional address from `$ARGUMENTS` — a `<KEY>`, or
   an `@<path>` naming a folder or a file inside one — and resolve it with `resolve-address`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3). Present and resolving → `mode: keyed`;
   absent from the argument list → `mode: direct`, and the rest of this phase's keyed steps are
   skipped. Carry the resolved `path`, `kind`, `key`, and the `specs` files found in that folder
   forward.

2. **Resolve the docs repo (cwd-preferred).** This command writes feature documentation into a product docs repository; running it outside such a repository is almost always a mistake. The **docs signals** checked throughout this step are:
   - `package.json` with any script matching `*:start`, `*:build`, `*:lint`, `docs:*`, or
   - any of `.docstack/`, `mkdocs.yml`, `docusaurus.config.js`, `antora.yml`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, or
   - a `_snippets/` directory at any level under the repo root.

   Resolve `docs_repo_path` in this order:

   - **(a) cwd with signals (preserves today's behavior).** Run `git rev-parse --show-toplevel` from cwd to resolve the git root. If it succeeds **and** ≥ 1 docs signal is present there → `docs_repo_path` = that git root and proceed silently. This keeps every downstream phase that assumes cwd correct.
   - **(a.5) `$DOCS_PATH` hint.** Else, resolve `${DOCS_PATH:-/workspace/docs}`. If it exists and carries **≥ 1 docs signal** (the same signal set as (a)) **or** an in-repo `.dev-workflows/docs-profile.yml`, set `docs_repo_path` = that path and proceed. In an AI container the docs clone is mounted here, so this is the common fast path when cwd carries no docs signals. The check is signal-based, never keyed to a particular repository's name or file layout.
   - **(b) Search for a docs repo.** Else, look under `${REPOS_PATH:-/workspace}` (single dir or colon-separated list) for a git root that carries an in-repo `.dev-workflows/docs-profile.yml` **or** ≥ 1 docs signal from (a)'s set. If exactly one matches → `docs_repo_path` = that path. If several match, list them and ask which to use (`choices` array, a profiled repo recommended first, last item `"Other… (describe)"`). Discovery is by signal, never by repository name — no repo name is special-cased.
   - **(c) Ask.** Else, ask:
     ```
     "No product-docs-repo signals in this working tree and no docs repo found under ${REPOS_PATH:-/workspace}. The signals I checked in cwd:
      - package.json scripts matching *:start, *:build, *:lint, docs:*
      - .docstack/, mkdocs.yml, docusaurus.config.js, antora.yml, .vale.ini, DOCUMENTATION-GUIDELINES.md
      - any _snippets/ directory under the repo root
      Where should I write the documentation?"
     choices: ["Use cwd anyway — I confirm this is a docs repo (Recommended)", "Enter the docs repo path", "Cancel — switch to a docs repo first", "Other… (describe)"]
     ```
     "Use cwd anyway" sets `docs_repo_path` = the git root of cwd (or cwd itself if not a git tree) and carries the user's confirmation forward. "Enter the docs repo path" takes a free-text absolute path and validates it exists.

   **Confirm writeable.** Once `docs_repo_path` is resolved, run `test -w <docs_repo_path>`. If it fails, stop with the named error `REPO_NOT_WRITEABLE: <docs_repo_path> is not writeable.`

3. **Does the built-in default profile apply?** Set `is_known_docs_repo` = `true` only when the resolved `docs_repo_path` matches the **built-in default profile's own layout** — it contains every `spaces[].content_root` and `snippet_root` that profile declares. This is a narrow test for "this repo is shaped like the bundled example", not a test for "this is a docs repo"; a real repo almost always answers `false` here and is served by its own in-repo profile at step 4(a), or by on-demand profiling at 4(c). Directory name is **never** a factor.

4. **Resolve the profile** (record `profile_source`). The profile steers all later phases' conventions. Resolve in this order:
   - **(a) In-repo profile →** `in-repo`. If `<docs_repo_path>/.dev-workflows/docs-profile.yml` exists, load it. `profile_source: in-repo`.
   - **(b) Built-in default profile →** `built-in`. Else, if `is_known_docs_repo`, load `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile.default.yml`. `profile_source: built-in`.
   - **(c) Custom repo, no profile →** `generated`. Else (a custom docs repo with no profile), run **inline on-demand profiling**: invoke the `/docs-profile` flow against `docs_repo_path` (Skill tool, `skill: "dev-workflows:docs-profile"`, with `docs_repo_path --inline` as its arguments — the `--inline` token tells profiling to skip its branch-naming prompt and standalone PR-draft handoff, since this command owns the single branch + PR draft) and wait for it to write `<docs_repo_path>/.dev-workflows/docs-profile.yml`. Then load that file. `profile_source: generated`. If the user cancels profiling (it produces no profile), stop with the named error `PROFILE_REQUIRED: a docs-profile is required to write into a custom docs repo; run /dev-workflows:docs-profile or switch to a profiled repo.`

   Hold the loaded profile for later phases.

   **In-repo-profile-not-on-base guard.** When `profile_source: in-repo`, confirm the profile is committed on the base branch before relying on a docs branch cut from it. Resolve the base (`git -C <docs_repo_path> symbolic-ref --short refs/remotes/origin/HEAD`; fall back to `main`, then `master`) and run `git -C <docs_repo_path> cat-file -e <base>:.dev-workflows/docs-profile.yml`:
   - **exit 0 (present on base)** → proceed (the common case — the profile was merged earlier).
   - **non-zero (absent on base)** → the profile is only in the working tree / on an unmerged branch, so the docs branch Phase 6.2 cuts from `<base>` will not include it. Warn and ask:
     ```
     choices: ["Proceed — the run uses the in-memory profile; I'll merge the profile PR separately", "Cancel — merge the profile PR first, then re-run", "Other… (describe)"]
     ```
   Skip this check for `profile_source: built-in` (no profile file) and `generated` (the inline profiling branch is adopted by Phase 6.2, so the profile rides the single docs branch — a base check would false-fire).

5. **Specs (additive).** Use the `specs` list from the front-end (§Specs
   resolution — `$SPECS_PATH` then the directory case). `specs: []` is fine —
   specs are additive context for `/document`; proceed without prompting. For
   the downstream phases that scan or cite a single specs location (the Phase 5.6
   image scan, the Phase 5.7 `doc-planner` dispatch, and the Phase 5.8 three-way
   analysis), also record `specs_dir` = the directory
   containing the resolved `specs` (their common parent — e.g. the
   `$SPECS_PATH/…/<KEY>…/` folder, or the directory they were found in), or
   `none` when `specs` is empty.

6. **Classify write context** for later branch/write decisions — computed against the resolved `docs_repo_path` (not necessarily cwd). Walk up from `docs_repo_path` looking for `.obsidian/`; if found, context = `obsidian`. Else if `git -C <docs_repo_path> rev-parse --show-toplevel` succeeds AND at least one docs signal from step 2 is present, context = `docs_repo`. Else if it succeeds with no docs signals, context = `non_docs_repo` (step 2 has already asked the user; their confirmation promotes this to `docs_repo` behaviour). Else context = `plain_dir`. In a normal run, Phase 0's docs-repo resolution (steps 2–3) yields a real docs repo (`docs_repo`) or a user-confirmed `non_docs_repo`; `obsidian` and `plain_dir` are **defensive guards** (they forbid branch/commit) rather than expected write targets.

   Record the resolved context — it drives Phase 6.2 (branch setup) and Phase 6.3 write rules. When `docs_repo_path` differs from cwd, record **both** and note that Phase 6.3 consumes `docs_repo_path`, not cwd, for every write.

7. **Toolchain preflight.** Execute `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` against
   the resolved `docs_repo_path` and the profile loaded in step 4. Derive the required set from all
   three sources (profile commands including `commands.per_space`, repo config signals, the repo's
   documented `Prerequisites`), check each, and build the `toolchain` block.

   Initialize the run's `gate_ledger` (schema:
   `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3) and append its first row:

   ```yaml
   gate_ledger:
     - gate: toolchain_preflight
       phase: "0"
       outcome: RAN
       mechanism: command -v / test -d over the derived required set
       findings: <count of tools with status: missing>
   ```

   - **Every required tool present** → record the row, contribute one line to the Readiness table, and
     proceed. Do NOT prompt.
   - **One or more missing** → present the `toolchain-preflight.md` §5 report and its choice list
     **verbatim** (the "Choice lists are presented verbatim" rule in
     `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` binds this prompt — `(Recommended)` stays
     on "Cancel"). On "Cancel", stop with the named error
     `TOOLCHAIN_UNAVAILABLE: <comma-separated missing tools> not available in this environment.` On
     "Continue anyway", pre-seed the affected gates' rows per `toolchain-preflight.md` §5 with the
     user's choice quoted verbatim in `user_decision`, and proceed.

   When the write context resolved in step 6 is `obsidian` or `plain_dir`, the build and render
   gates have no precondition to meet — do not name them in the consequence line. Phase 6.5 records
   their `NOT_APPLICABLE` rows before its own run-condition, so they are present even though that
   phase does not execute.

### Readiness

Before clarification, show a readiness table summarizing what Phase 0 resolved:

| Item | Resolved |
|---|---|
| Address | the resolved folder |
| Docs repo | `<docs_repo_path>` (`is_known_docs_repo`: yes/no) — write context `<obsidian \| docs_repo \| non_docs_repo \| plain_dir>` |
| Profile | `profile_source`: `<in-repo \| built-in \| generated>` |
| Toolchain | `<all required tools present>` OR `<N missing: vale, pnpm — user chose to continue>`; writing into `<docs_repo_path>`[ (cwd is `<cwd>`)] |
| Specs | `<specs_dir>` or `none` |
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
  choices: ["fetch only (Recommended)", "fetch + pull default branch", "no refresh — resolve PRs from local objects only; a PR not yet fetched will not resolve, and a dirty clone stops blocking", "Other… (describe)"]
  ```
  The `fetch only` default matches the `diff-summarizer` default (`refresh.fetch: true, refresh.pull: false`) — historical PR diffs don't need the current branch tip, and pulling risks moving HEAD away from the merge commit we want to reach.
- **Repos search base (`$REPOS_PATH`)**. Read `${REPOS_PATH:-/workspace}` (the container mounts every repo under `/workspace`). `$REPOS_PATH` may be a single directory or a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input (single dir or colon-separated list) and validate that at least one directory exists under it. Record the resolved value as `$REPOS_PATH`. Individual clones are located in Phase 4 by matching their `git remote` against each PR's repo slug — not by assuming a `<base>/<slug>` directory name.
- **Screenshots** — this question seeds the **add-list** only; it never skips Phase 5.6. The candidate list itself is built later in **Phase 5.6** (by which point `specs_dir`, the folder read `attachments[]`, and the resolved repos are all available), and Phase 5.6 **always** runs — it also reviews the images already on the pages this run is about to edit, regardless of this answer:
  ```
  choices: ["Yes — I have new screenshots to add (you'll pick the sources in Phase 5.6) (Recommended)", "No new screenshots", "Cancel", "Other… (describe)"]
  ```
  Record the answer as `new_images_wanted` (true/false). When `false`, Phase 5.6 skips its **add** list only and still reviews existing images on the edited pages. The downstream `doc-planner` (Phase 5.7) detects the repo's `image_policy` and decides per screenshot whether the writer will copy it locally or stage it for manual upload.

  **Resolve `<screenshot_staging_dir>`.** No longer gated on `new_images_wanted`: Phase 5.6 always runs and its existing-image review can need a durable location for a replacement source regardless of this answer, so `<project_dir>` (set below) must be resolved on every run, not only an add-list one. **This unconditional resolution is deliberate and stays**, including the "Not found" prompt it can raise on a run that turns out to have no image work at all: Phase 1 runs long before `write_targets` exist, so any narrower precondition ("only when this run will touch images") is undecidable here. The occasional needless prompt is the accepted cost of closing a container-restart data-loss gap — do not re-gate this on `new_images_wanted` or on a guess about image work. For the `cdn_upload_required` case the staged copies must live somewhere that survives a container restart — a host-mounted directory the operator names survives it, the docs repo (often a docker repo-volume) and `/tmp` are not. Use the resolved PRD folder:
  ```bash
  the resolved PRD folder
  ```
  - **Found** → record the matched folder as `<project_dir>` (the project-folder root — reused as an image source in Phase 5.6), and set `<screenshot_staging_dir>` to that project folder's screenshot subfolder: prefer an existing `Doc screenshots/` or `Attachments/` subdirectory; otherwise `Doc screenshots/` (created on first write).
  - **Not found** (e.g. a ticket whose project has no project folder) → `<project_dir>` is null (Phase 5.6's project-folder scan then contributes nothing); ask:
    ```
    choices: ["Enter an absolute staging directory (you'll be prompted)", "Skip — only needed if the docs repo turns out to be cdn_upload_required", "Cancel", "Other… (describe)"]
    ```
    Reject `/tmp` and any path inside the docs repo. Record the result as `<screenshot_staging_dir>` (or null if skipped).

Also display (for user context):
- Resolved cwd absolute path
- Write context (`obsidian` / `docs_repo` / `non_docs_repo` / `plain_dir`)
- Whether branching will happen (only when context is `docs_repo` — confirmed at plan approval)
- Resolved `$REPOS_PATH`
- The resolved address and folder

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of: `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK`. keyed feature docs are typically **SIGNIFICANT** (large blast radius if wrong — published documentation). State the classification and a one-sentence reason.

SIGNIFICANT → no separate Opus **risk-planner** for the high-level plan (the PRD folder + diff summaries *are* the plan), **but `doc-planner` (Phase 5.7) is pinned to the §2 Opus reasoning chain**; the `doc-reviewer` gate (Opus) is mandatory.

**Resolve the per-step routing.** Following `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9, record a `model_routing` block (reusing the §4 field names) resolving each model against the fallback chains:

```yaml
model_routing:
  classification: SIGNIFICANT
  reason: <one-line>
  current_model: <the model this orchestrator is running under>   # = the inline writer + Phase 5.8 framing
  detection_model: <§2.1 mid-tier Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>
  planning_model:  <§2 powerful chain: claude-opus-5 … fallback Sonnet per §2>   # doc-planner (5.7)
  review_model:    <§2 powerful chain>     # doc-reviewer (frontmatter-pinned; recorded here, no override added)
  implementation_model: <= planning_model>  # the doc-writer subagent (Phase 6.3) — now a delegated, Opus-pinned writer
  fixes_model: <= detection_model>         # doc-fixer (6.4 / 7) runs on the detection chain
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2 / §2.1 fallback or degradation>
```

Each subagent dispatch below cites which chain it uses (the §9 role→chain map): `doc-planner` → `planning_model`; the folder read, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, and the Phase 8 maintenance agents → `detection_model`; `doc-reviewer` keeps its own frontmatter Opus pin (recorded as `review_model`, no override added).

**Orchestration advisory (window-focused).** `doc-planner` (5.7) and `doc-writer` (6.3) run on the §2 Opus chain regardless of session; only coordination + the interactive gates (5.8 decision, 6.1) run on `current_model`. So:

- **`current_model` is on the §2 chain** → no advisory.
- **`current_model` is NOT on the §2 chain and `opus_available: true`** → the heavy synthesis + writing are already on Opus; the residual risk is the orchestrator's **context window** on a **large multi-repo ticket**. Offer relaunch **only** on such a ticket — that condition gates the prompt, so once the list is shown the recommendation holds unconditionally (per the `(Recommended)`-marker rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`):
  ```
  choices: ["Relaunch /dev-workflows:document under Opus — I'll restart (Recommended)", "Proceed on <current_model>", "Cancel"]
  ```
  Otherwise proceed without prompting.
- **`current_model` is NOT on the §2 chain and `opus_available: false`** → `planning_model`, `review_model`, and the **doc-writer** all fall to the Sonnet floor; record the degradation in `notes` and the Phase 9 report; proceed.

---

## Phase 2 — Plan + approval

Present a concise plan:

- The resolved address and the folder it resolved to
- Output filename / path under the resolved `docs_repo_path` (from Phase 1)
- `$REPOS_PATH` and the slug→clone resolution for the repos that will be examined (inferred from the folder read output in Phase 3; if Phase 3 hasn't run yet, list "TBD — resolved after the folder read")
- PR filter (MERGED only / all / specific)
- Parallelism plan (up to 4 `diff-summarizer` instances per batch; up to 4 repos per Agent message)
- Write context + whether branching will happen
- Screenshots: `new_images_wanted` (yes/no, from Phase 1). Phase 5.6 always runs: when yes, its add-list candidates are gathered and confirmed there (specs scan + folder `attachments[]` + manual paths) — list "candidates resolved in Phase 5.6"; either way, Phase 5.6 also reviews the images already on the edited pages for staleness.

Ask:
```
"Documentation plan ready. What would you like to do?"
choices: ["Approve & continue (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → proceed to Phase 3
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarise what was planned

---

## Phase 3 — Read the PRD folder

Invoke the folder read with `depth: full`:

**Read the resolved folder directly.** Read its `prd.md` for the product content, and the `specs`
files Phase 0 resolved alongside it.

**Resolve the diff sources — two of them, merged.** Follow
`${CLAUDE_PLUGIN_ROOT}/references/implementation-format.md` §4:

1. **The record.** Read `implementation.md` in the resolved folder. **Read every block under the PRD** — this command documents the feature as it now stands, so every change that reached it is in scope.
2. **The scan.** For each repository — those `implementation.md` names, or, when it names none, the
   repositories resolved from `$REPOS_PATH` — search commit messages for the identifiers this run
   already holds:

   ```
   git -C <repo> log --grep='<key>' --grep='<workitem_key>' --extended-regexp --regexp-ignore-case
   ```

   The keys come from the resolved folder's own `key:` and its `workitem_key`; **nothing is parsed
   out of a commit message.** This is what finds work the plugin did not do — a commit written by
   hand after a session ended, a colleague's push, a follow-up nobody ran a command for.

**Merge and dedupe by SHA.** Anything the scan finds beyond the recorded blocks is reported as
**unrecorded work**, named as such with its commits listed: folding hand-made commits silently into
the recorded set would make the record look more complete than it is.

**Report the scan's own reach.** Say **how many commits it scanned and how many matched**. Only a
commit whose message names the key is findable, and no convention compels a human to follow one — so
a zero-match scan in a repository that has commits is a signal about the commit convention
(`docs/reference/commit-convention.md`), not proof that no work happened.

Hand each resolved ref to `diff-summarizer` as a `{repo_path, branch_from, branch_to}` triple — a
shape its Inputs already declare, on the pure-local-git path it prefers when `gh` is absent. No URL,
no host classification, no `gh` requirement.

  >
  > key:         [resolved <KEY>]
  > depth:            full"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `key dir not found` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`) and act accordingly. On `OK`, store the handoff for downstream phases.

When `focus_key` is set (explicit `<PRD> <Epic>`), also derive `focus_items` = the
focus Epic plus every linked item beneath it (its Stories / Sub-tasks). The
change-scoped phases below consume `focus_items` in place of the full hierarchy —
Phase 5 (diff summarisation) and Phase 5.7 (doc planning) — while every phase that
describes the PRD as a whole keeps the full handoff. When `focus_key`
is null, every phase uses the full hierarchy exactly as today.

---

## Phase 4 — Resolve repos

From the folder read handoff `pull_requests` list:

1. Filter by `status` per the Phase 1 PR-status setting (default: MERGED only). This is the `pull_requests[].status` field, NOT the top-level the folder read `status`.
2. Group the remaining PRs by `repo` (short repo name).
3. Build a slug→clone map. For each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote` call fails/times out. Result: `<slug> → [<absolute path>, ...]`.
4. Resolve each unique in-scope `repo` slug against the map:
   - **One match** — use that absolute path as `repo_path`.
   - **Multiple matches** (e.g. `cluster` and `cluster-repo`, both pointing at the same upstream) — auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last; show all candidates at plan approval so the user can override.
   - **Zero matches** — record the slug as **missing** and defer it to the consolidated repo gate in step 5 (do NOT escalate per slug).
   Record each resolution as `repo_slug → repo_path` for Phase 5.
5. **Consolidated repo gate.** From step 4, compute `expected` = the unique in-scope repo slugs, `mounted` = those that resolved to a path, and `missing` = the zero-match slugs. This is the earliest point the repo set is known (it depends on the Phase 3 the folder read PR links) and it runs before any diff work.
   - **`missing` is empty** — print one line and continue with no gate:
     ```
     Resolved <M>/<N> repositories from the recorded PRs.
     ```
   - **`missing` is non-empty** — present ONE consolidated gate (not one prompt per slug):
     ```
     This PRD's recorded PRs span <N> repositories. <M> mounted, <K> missing:

       ✓ <mounted slug>            ✓ <mounted slug>
       ✗ <missing slug>            (<n> <status> PRs — not found under $REPOS_PATH)

     Missing repos are skipped: their code won't be diff-summarised or checked
     against the PRD's requirements, so the discrepancy analysis will be partial.

     choices: ["Mount the missing repo(s) now — I'll wait, then re-scan (Recommended)", "Proceed without them — PRD-only for the missing repos", "Cancel", "Specify a different absolute path for a missing repo", "Other… (describe)"]
     ```
     Choice semantics follow the `Repo unresolved (zero matches) — /document` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, applied to the whole missing set at once:
     - **Mount now & re-scan** (≈ the rule's "I'll clone it — wait") — pause until the user confirms the clones are present under `$REPOS_PATH`, then re-run step 3's scan and re-render this gate. Loop until `missing` is empty or the user picks another option. This is how the operator gets per-repo control: mount whichever repos are available, re-scan, then choose "Proceed" for whatever remains.
     - **Proceed without them** (≈ the rule's "Skip and continue without its PRs") — record every currently-missing repo's PRs as `unresolved`, out of scope; continue. Identical downstream state to the previous per-slug skip.
     - **Cancel** — abort the run.
     - **Specify a different absolute path for a missing repo** (≈ the rule's "Specify a different absolute path") — record the given path as that slug's `repo_path`, move it from `missing` to `mounted`, and re-render.
6. If any PRs had `host: other` (unsupported host), record them as `unresolved` and carry them into the Phase 9 report; do not block.

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
  > pr_refs:     [ ... full PR entries from the folder read handoff, filtered to this repo (and, when focus_key is set, to focus_items) ... ]
  > context:    |
  >   [1–2 sentences: PRD goal + themes relevant to this repo]
  > keys_hierarchy:
  >   [PRD key + every linked_items key from the folder read; when focus_key is set, restrict to focus_items — the focus Epic + its linked descendants]
  > refresh:
  >   fetch: [false if Phase 1 chose 'no refresh'; true otherwise]
  >   pull:  [true if Phase 1 chose 'fetch + pull default branch'; false otherwise]"

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
- `prep.read_only: true` — not a failure. The scan ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently and cite evidence at `prep.scanned_ref`.
- `NO_PRS_RESOLVED` — record all that repo's PRs as unresolved; continue.

After every batch completes, if **every PR across every repo** is unresolved, present a single aggregate gate (not per-PR):
```
choices: ["Proceed with PRD-only content (Recommended — writer/planner draw from the folder read output; final report notes missing PR content)", "Review candidates one by one", "Cancel"]
```

---

## Phase 5.5 — Find documentation locations

Invoke `doc-location-finder`:

→ Agent (subagent_type: "dev-workflows:doc-location-finder", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Find write target(s) for the brief:
  >
  > repo_root:       [the resolved docs_repo_path (Phase 0)]
  > feature_summary: [2–4 sentences combining the folder read themes + value_increment.goal]
  > diff_highlights: [key filenames / symbols from the diff-summarizer per_pr summaries]
  > profile:         [the resolved profile — its spaces[] content roots and its announcement_pages block]"

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

## Phase 5.6 — Images

**Always runs**, regardless of the Phase 1 `new_images_wanted` answer. Declining new screenshots seeds an empty add list; it never skips reviewing whether the images already on the pages this run is about to edit are still accurate — that was the defect: one Phase 1 answer used to gate both concerns. Build **two** lists.

### Add list (new screenshots)

Build this list only when `new_images_wanted` is `true` (Phase 1); when `false`, the add list is empty and contributes nothing to the merged prompt below — skip straight to the existing-image list. When `true`, build a **merged, deduped candidate list** from four sources (by this point Phase 0's `specs_dir`, the Phase 1 `<project_dir>`, the Phase 3 the folder read `attachments[]`, and the Phase 4 resolved repos are all in hand):

1. **Recursive scan of `<specs_dir>`** — when Phase 0 resolved a `specs_dir` (not `none`), recursively scan it for image files across the spec root, `epics/`, and `spec/`:
   ```bash
   find "<specs_dir>" \( -path "*/epics/*" -o -path "*/spec/*" -o -path "<specs_dir>/*" \) \
     -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.svg" -o -iname "*.webp" \) 2>/dev/null
   ```
   When `specs_dir` is `none`, this source contributes nothing.
2. **PRD-folder attachments** — the image paths enumerated under the resolved PRD folder's `attachments/` directory, where one exists. May be empty.
3. **Recursive scan of `<project_dir>`** — when Phase 1 resolved a `<project_dir>` (the folder this run resolved), recursively scan it for image files:
   ```bash
   find "<project_dir>" -type f \
     \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.svg" -o -iname "*.webp" \) 2>/dev/null
   ```
   This surfaces images you keep in the project folder (custom diagrams, curated screenshots). When `<project_dir>` is null, this source contributes nothing.
4. **Manual paths** — the user-provided "I'll provide screenshot paths" option (free text, see the `choices` below).

**Dedupe** by resolved absolute path (collapse mixed separators / trailing-slash differences); when the same image appears in more than one source, keep one entry and note its origins.

### Existing-image list (staleness review)

**Always build this list** — it does not depend on `new_images_wanted`. The orchestrator owns it (`doc-planner` runs later, at Phase 5.7, and never supplies or reads this list). For every `extend-existing` write target in Phase 5.5's confirmed `write_targets`, read the target file and record **every image reference in document order** — one row per occurrence, not per unique URL: the same URL can recur several times on one page, and each occurrence is decided separately (two sections can carry the same stale URL, and only one of them may need the fix). For each occurrence record:
- `target` — the write target's path.
- `occurrence` — the 1-based index of this image reference within the whole target, counted in document order across **all** image references in the file — never filtered by `old_url`, never scoped to a section.
- `old_url` — the image reference's current URL/path.
- `section` — the nearest enclosing heading.

A target with no image references contributes nothing.

### Merged prompt

Present both lists — "Found `<N>` add-list candidate(s) (`<count>` from specs scan, `<count>` from folder attachments, `<count>` from the project folder)" and "Found `<M>` existing image(s) across `<K>` edited page(s) to review for staleness" — then ask:
```
choices: ["Review both lists item by item (Recommended)", "Add-list only — existing images are current", "Nothing to do — no image work this run", "Cancel", "Other… (describe)"]
```
When both lists are empty, skip presenting this prompt — there is nothing to show — and set `screenshots[] = []`, `existing_image_decisions[] = []` directly.

- **Review both lists item by item**:
  - **Add list**, if non-empty, asks:
    ```
    "Found <N> candidate image(s): <count> from specs scan, <count> from folder attachments, <count> from the project folder. How would you like to source screenshots?"
    choices: ["Use all auto-discovered + add manual paths (Recommended)", "Use all auto-discovered only", "Select a subset (you'll pick per candidate)", "Provide screenshot paths manually only (you'll be prompted)", "No images after all", "Other… (describe)"]
    ```
    - **Use all auto-discovered + add manual** → take every deduped candidate, then prompt for additional free-text absolute paths to append.
    - **Use all auto-discovered only** → take every deduped candidate; no manual prompt.
    - **Select a subset** → present the deduped candidates and let the user pick which to keep.
    - **Provide screenshot paths manually only** → ignore the auto-discovered candidates; take free text only.
    - **No images after all** → leave `screenshots[]` empty; the add list contributes nothing further.
  - **Existing-image list**, if non-empty, walks each occurrence in order — showing `target`, `section`, and `old_url` — and asks per item (no default is safe to recommend across arbitrary items, so no `(Recommended)` marker):
    ```
    choices: ["Replace — I'll provide a new screenshot (staged via Phase 6.1)", "Leave as is — still accurate", "Cancel", "Other… (describe)"]
    ```
    "Replace" appends an `existing_image_decisions[]` entry `{target, occurrence, old_url, new_url, section, decision: accepted}` with `new_url` left pending (Phase 6.1 resolves it) and records the replacement's source (a path from the add list just reviewed, or a new free-text path). "Leave as is" appends the same shape with `decision: declined` and no `new_url`.
- **Add-list only — existing images are current** → run the add-list sub-flow above (if non-empty); `existing_image_decisions[] = []` — the user's verbatim choice is the record of the (skipped) existing-image review, not a per-item entry.
- **Nothing to do — no image work this run** → `screenshots[] = []`, `existing_image_decisions[] = []`.
- **Cancel** → stop and summarise.
- **Other… (describe)** → takes free text and resolves to one of the three dispositions above — "Review both lists item by item", "Add-list only", or "Nothing to do" — and the run then behaves exactly as if that option had been chosen directly, including which ledger row it writes. There is no fourth disposition and no "skip on my own judgement" path here.

**Append the `image_review` ledger row once this phase's outcome is settled — by the user's answer to the merged prompt above, or by the both-lists-empty precondition when that prompt itself was skipped — outside any conditional branch above**, so every path through this phase writes exactly one row (schema: `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3; registry entry: §4):
- `RAN` — the choice was "Review both lists item by item" and at least one of the two lists was non-empty; `mechanism: "per-item user review of the add list and the existing-image list built from extend-existing write targets"`; `findings:` = the count of existing-image occurrences reviewed.
- `SKIPPED_BY_USER` — the choice was "Add-list only — existing images are current" or "Nothing to do — no image work this run"; `user_decision` quotes the choice verbatim.
- `NOT_APPLICABLE` — both lists were empty (the prompt above was skipped); `precondition_unmet: "no add-list candidates and no image references on any extend-existing write target"`.

For any **manual** free-text paths, accept any absolute filesystem path (`/tmp`, home, the docs repo); accept multiple (one per line or space-separated). Validate each path exists and has an image extension (`.png|.jpg|.jpeg|.gif|.svg|.webp`); drop and report any that don't.

When you need to **add a new image** for this feature (a screenshot the docs should have but no source yet holds — including a replacement source for an accepted existing-image entry), place it in the resolved PRD folder's `attachments/` directory, beside the images source 2 enumerates. There is one home for a feature's images now, and it is the folder the run already resolved.

The selected add-list paths populate the existing **`screenshots[]`** passed to `doc-planner` in Phase 5.7 — the downstream placement machinery (per-screenshot `dest`/`staging`/`upload_note`, `image_policy`) is unchanged. An accepted item — from either list — carries into Phase 6.1 for its CDN URL. The outcome is recorded as `existing_image_decisions[]` (schema above; matches `doc-writer`'s input contract) and carried in the Phase 6.3 handoff file alongside `cdn_urls`.

---

## Phase 5.7 — Plan the documentation

Invoke `doc-planner`:

→ Agent (subagent_type: "dev-workflows:doc-planner", model: `<planning_model — §9 / §2 Opus chain>`):
  > "Produce the documentation checklist for the brief:
  >
  > folder_read: [paste full YAML from Phase 3; when focus_key is set, restrict linked items to focus_items]
  > diff_summaries:       [paste array of diff-summarizer outputs from Phase 5]
  > write_targets:        [paste confirmed list from Phase 5.5]
  > screenshots:          [selected candidate paths from Phase 5.6, possibly empty]
  > screenshot_staging_dir: [resolved <screenshot_staging_dir> from Phase 1, or null]
  > repo_root:            [the resolved docs_repo_path (Phase 0)]
  > code_repos:           [the Phase-4 resolved {slug, path} map; [] if none resolved]
  > specs_dir:            [resolved <specs_dir> from Phase 0, or null]
  > profile:              [the docs-profile loaded in Phase 0 — supplies the spaces[] content roots, tokens, and link conventions]"

Handle the `status` and `gaps`:

- **`status: OK`, `gaps: []`** → proceed to the approval prompt.
- **`status: OK` or `PARTIAL` with `gaps` entries** — for each gap, act on its `recommended_action`:
  - `"ask user"` → prompt inline **before** showing the checklist-approval choice. Free-text prompt scoped to the gap; feed the answer back to the planner via a single re-invocation (pass the user's answer as an additional `gap_resolution` field in the brief). If the user declines, fall back to `"mark TODO in draft"`.
  - `"mark TODO in draft"` → surface in the checklist display as a visible TODO; the writer at Phase 6.3 emits `<!-- TODO: … -->` markers. Does not block approval.
  - `"skip with note in final report"` → list in the checklist display; carry forward into the Phase 9 `### Skipped items`. Does not block approval.
- **`status: PARTIAL`** alone (without user-asked gaps) is presented to the user alongside the checklist so the approval decision is informed.

Present the checklist (with any gaps + dispositions, and — when the planner returned a non-empty `repo_authoring_guidance` — the repo-specific authoring rules it extracted from the repo's own guidance files, so the user sees "this repo's CONTRIBUTING.md / CLAUDE.md requires …" before approving):
```
choices: ["Approve & write (Recommended)", "Adjust (describe)", "Cancel"]
```

---

## Phase 5.8 — Discrepancy analysis & user decision

**Ledger first — before the skip check below.** This gate must carry a row on every run, including runs with nothing to escalate. Append the `source_truth_verification` row now, per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3:

- `code_repos` is empty → `NOT_APPLICABLE`, `precondition_unmet: "code_repos is empty"`.
- `code_repos` is non-empty and `doc-planner` returned no `verification_warnings` of an escalating type (`CONTRADICTED`, `NOT_FOUND`, `AMBIGUOUS`, `SPEC-VS-PRD`) → `RAN`, `mechanism: "claim-class verification per source-truth.md §2–§3"`, `findings: 0`. A list of only `VERIFIED` entries counts as none for this purpose — the row is final and this phase's body does not run.
- `code_repos` is non-empty and at least one warning IS of an escalating type → append `RAN` provisionally now, then rewrite the row at the end of this phase per **Ledger (final)** below.

Run the rest of this phase when the `doc-planner` handoff contains any `verification_warnings` with `finding: CONTRADICTED`, `NOT_FOUND`, `AMBIGUOUS`, or verdict `SPEC-VS-PRD`. If there are none, skip to Phase 6.3 — the row above is already recorded.

This phase is **three-way** when a spec was provided (Phase 0 resolved `specs_dir` and Phase 5.7 passed it to `doc-planner`): it compares the **PRD** narrative, the **Spec** (authoritative "intended"), and the **Code** ("actual"), per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7. When no spec was provided, the planner emits `spec_phrasing: "(no spec)"`; the **Spec phrasing** column simply renders `(no spec)` and the run behaves exactly as the original PRD-vs-code two-way protocol.

**Supplementary resolution (one attempt, before presenting anything).** For every
`verification_warning` whose `finding` is `AMBIGUOUS` or `NOT_FOUND`, check whether the relevant repo
is present in the Phase-4 `code_repos` map. When it is, run **one** direct grep against that resolved
local path to try to resolve the claim — using the `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md`
§3 technique matching the claim's type — **including when `diff-summarizer` returned `REFRESH_BLOCKED`
for that repo**. A repo whose refresh genuinely failed — a network or auth error, or an unresolvable
default branch — can still be grepped at its current local state, and this is exactly
the case a user previously had to resolve by hand.

Update the warning in place when the grep resolves it (`finding: VERIFIED` or `CONTRADICTED`, with
`source_phrasing` and `source_location` filled from the grep). Present only what remains unresolved.
Record the outcome in the `source_truth_verification` ledger row: a resolution obtained this way makes
the row `DEGRADED`, with `not_run:` naming what did not run (e.g.
`mechanism: diff-summarizer refresh`, `reason: REFRESH_BLOCKED`), never a clean `RAN`.

1. **Present the analysis table** (informational, before asking):
   ```
   | # | Claim | PRD phrasing | Spec phrasing | Source (code) phrasing | Source location | Verdict |
   ```
   One row per warning. The **Spec phrasing** cell reads `(no spec)` when no spec was provided. Use `Source (code) phrasing: "(not verifiable)"` for `no-source-evidence` entries. The **Verdict** carries the §4.2 finding (`CONTRADICTED`, `NOT_FOUND`, `AMBIGUOUS`) or `SPEC-VS-PRD` (the spec differs from the PRD narrative; recommended action "Document as intended (spec)").

2. **Batch decision:**
   ```
   choices: ["Decide per discrepancy (Recommended)", "Document ALL as intended (spec)", "Document ALL as actual (code)", "Skip ALL and report (drafts a bug report)", "Cancel", "Other… (describe)"]
   ```
   "Document ALL as intended (spec)" uses the `spec_phrasing` (or the PRD phrasing when it is `(no spec)`).

3. **Per-discrepancy** (if "Decide per discrepancy"): for each warning, show claim + PRD phrasing + Spec phrasing + Source (code) phrasing + location, then:
   ```
   choices: ["Document as intended (spec)", "Document as actual (code)", "Skip this claim and report it", "Cancel", "Other… (describe)"]
   ```
   "Document as intended (spec)" describes the agreed contract — the `spec_phrasing` (or the PRD phrasing when it is `(no spec)`) — and, when the code lags the intended phrasing, adds an intentional-discrepancy marker + bug-report draft. "Document as actual (code)" matches what shipped, and when it is a qualifying `document-as-code` case per §7.5, also records the gap in the bug-report draft. "Skip this claim and report it" omits the claim but still records the gap in the bug-report draft.

4. **Record `discrepancy_decisions[]`** keyed by `number` (claim, prd_phrasing, spec_phrasing, source_phrasing, source_location, decision ∈ {document-as-spec, document-as-code, skip-and-report}, rationale). `spec_phrasing` is recorded verbatim (`(no spec)` when none was provided). Set `bug_report_destination` to the resolved PRD folder (ask if none) when any decision is `document-as-spec` (where the code lags the intended phrasing), `skip-and-report`, or a qualifying `document-as-code` per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.5.

Pass `discrepancy_decisions` to Phase 6.3.

**Ledger (final).** Rewrite the `source_truth_verification` row appended at the top of this phase, per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3: when the row you appended at the top is already `NOT_APPLICABLE` (`code_repos` was empty), leave it exactly as it is — a phase body that ran on no-source-evidence warnings does not turn an unmet precondition into a performed check; `RAN` when verification ran against the resolved repos; `DEGRADED` when any claim was resolved only by the supplementary grep, with `not_run:` naming what did not run (e.g. `mechanism: diff-summarizer refresh`, `reason: REFRESH_BLOCKED`) and a `ci_still_checks:` line; `UNAVAILABLE` when the primary verification AND the supplementary grep both failed to execute at all with `code_repos` non-empty — convert that per `gate-ledger.md` §5 before leaving this phase. `findings:` is the count of `verification_warnings` presented to the user.

---

## Phase 6.1 — CDN image handoff

Run this phase when, in the Phase 5.7 `doc-planner` return, **any** screenshot has `image_policy: cdn_upload_required` — **or** the user picked "Stage for manual upload" under an `ambiguous` target in Phase 6.3 — **or** any Phase 5.6 `existing_image_decisions[]` entry has `decision: accepted`. (When the only image policy in play is `local` and there is no accepted existing-image replacement, skip this phase: local images are copied into the repo at Phase 6.3 with no handoff needed.)

1. **List each affected image** so the decision is informed — one row per image:
   - target page / anchor it belongs on (from the planner's per-screenshot placement, or — for an existing-image replacement — the `target` / `section` recorded in Phase 5.6);
   - proposed alt text;
   - the planner's `upload_note`.

   An item sourced from the existing-image list (Phase 5.6) is a **replacement**, not a new insertion: the writer swaps that occurrence's URL rather than inserting a new reference, and because a CDN URL is immutable, the collected `new_url` is always a different URL from `old_url`. A swap has no deferred/TODO form — `doc-writer` only ever writes a real replacement URL for an `existing_image_decisions` entry — so even when the batch choice below is "Defer", still collect each accepted existing-image entry's `new_url` individually (record it as that entry's `new_url`, not in `cdn_urls`) before Phase 6.3; only the remaining, non-swap screenshots follow the Defer path.

2. **Ask how to handle the upload:**
   ```
   choices: ["Upload now — I'll paste the CDN links (Recommended)", "Defer — stage with TODO placeholders + Phase 9 list", "Cancel", "Other… (describe)"]
   ```

   - **Upload now** → collect one CDN URL per image (prompt per image, or one URL per line in image order). Validate each pasted value looks like a URL (e.g. starts with `http://` / `https://`); re-prompt for any that don't. Record `cdn_urls[<image>]` for a regular screenshot, or the entry's `new_url` for an existing-image replacement. Phase 6.3 then writes the **real CDN URL** into each markdown image reference instead of a TODO placeholder — for an existing-image replacement, it swaps that occurrence in place. Nothing is staged and the Phase 9 "Screenshots to upload manually" section stays empty for these images.
   - **Defer** → the existing async behavior for regular screenshots: stage each image under `<screenshot_staging_dir>` (the staging directory resolved in Phase 1), Phase 6.3 inserts the `TODO-upload` placeholder reference, and every staged image is listed in the Phase 9 `### Screenshots to upload manually` section. Existing-image replacements are exempt from this path (see above) — their `new_url` is still collected now.
   - **Cancel** → stop and summarise.

   Record the decision as `cdn_handoff_decision ∈ {upload-now, defer}` and carry it (with any `cdn_urls` and the updated `existing_image_decisions[]`) into Phase 6.3.

---

## Phase 6.2 — Branch setup (conditional)

Run this phase only when write context = `docs_repo` (or `non_docs_repo` after user confirmed at Phase 0 step 2) AND the user confirmed branching at plan approval. Never for `obsidian` or `plain_dir`.

1. **Update the base branch.** Resolve the default branch by running `git symbolic-ref --short refs/remotes/origin/HEAD`; this returns the remote's default (`main` or `master`; legacy repos frequently still use `master`). If the command fails (unset `origin/HEAD`), run `git remote set-head origin --auto` and retry; if it still fails, try `main`, then `master`, in that order. If the user picked a `release/*` branch earlier in Phase 1, use that instead. Once the base is resolved: `git fetch origin`. Then update the base working copy **only outside the inline-profiling case**: when `profile_source` is NOT `generated`, `git switch <base> && git pull --ff-only`. **In the inline-profiling case (`profile_source: generated`), do NOT switch** — HEAD must stay on the generated profile branch so step 5's `git branch -m <name>` renames *that* branch (the profile branch was created off the base in Phase 0, so it is already current). When a switch happened and the fast-forward pull fails:
   ```
   choices: ["Stash local changes and continue (Recommended)", "Proceed from current base state", "Cancel"]
   ```

2. **Clean-tree check.** `git status --porcelain`; if non-empty:
   ```
   choices: ["Stash changes and continue (Recommended)", "Proceed anyway — pre-existing changes will appear in the diff", "Cancel"]
   ```

3. **Derive branch name from repo conventions.** In priority order, look at repo root for `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `DOCUMENTATION-GUIDELINES.md`. Grep each for a branch-naming section (case-insensitive, patterns like "Branch name", "Branch naming", "naming your branch"). If a pattern like `<user>/<KEY>-<slug>` or `<prefix>/<name>` is documented, derive the branch name by filling placeholders with known values (key from Phase 0, slug from the feature summary, and any **identity** placeholder (`<user>`, `<your-name-or-initials>`, `<initials>`, …) from the §2 ladder in `${CLAUDE_PLUGIN_ROOT}/references/branch-naming.md` — `$GIT_USER_INITIALS` → `git config user.initials` → inference from existing branches → its §2.5 prompt). Classify the pattern's segments per §1.2 and never add an identity segment it does not ask for. If multiple patterns are documented, offer them all to the user. When no pattern is documented (§1.4), take the whole prefix from the same ladder, whose fallback for this command is `docs/`.

4. **Confirm the branch name** — always, even when derived from conventions (initials and slugs are subjective):
   ```
   choices: ["Use proposed name: <name>", "Edit name (you'll be prompted)", "Cancel"]
   ```
   Fallback default when no convention is found: `<prefix>/<key>-<slug>`, where `<prefix>` comes from `${CLAUDE_PLUGIN_ROOT}/references/branch-naming.md` §2 (fallback `docs/`).

5. **Create or adopt the branch, and record handoff anchors.** Record `base_branch` = the base resolved in step 1 (the Phase 8.5 squash uses it).
   - **Normal case** (`profile_source` is `in-repo` or `built-in`, or a custom repo whose profiling did not create a branch): `git switch -c <name>` from `base_branch`.
   - **Inline-profiling case** (`profile_source: generated`): Phase 0's `/docs-profile` already ran `git switch -c <profile-branch>` and committed `.dev-workflows/docs-profile.yml`, so HEAD is already on that branch. Do NOT create a new branch — rename it with `git branch -m <name>`. Record `profile_commit` = the commit that introduced the profile config: `git log --diff-filter=A --format=%H -- .dev-workflows/docs-profile.yml | head -1`. Phase 8.5 squashes the docs commits onto `profile_commit`, keeping the profile-config commit as a distinct first commit. (Per `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §1.)

No external CLI calls; all git operations are local.

---

## Phase 6.3 — Write documentation

The writing is delegated to the **`doc-writer`** subagent (pinned to the §2 Opus reasoning chain — see `classification.md` §9.2). The orchestrator prepares a structured handoff and dispatches; it does not write pages itself.

1. **Write the handoff file.** Create a temp file (`mktemp`, e.g. `$(mktemp -t dw-<KEY>-XXXX.yml)` — never the specs tree, never the docs repo) containing the `doc-writer` input contract: `folder_read`, `diff_summaries`, `write_targets`, `doc_planner_checklist` (+ gap dispositions), `repo_authoring_guidance` (the planner's extracted repo-specific rules), `component_patterns` (the planner's recurring content-shape → dominant-component evidence, per `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §3 — like `repo_authoring_guidance`, a top-level sibling of the planner's `checklist:`, so it must be carried explicitly; `[]` when the sibling sample showed no established pattern), `discrepancy_decisions` (Phase 5.8), `cdn_handoff_decision` + `cdn_urls` + `screenshot_staging_dir` + `screenshots` + `existing_image_decisions` (Phase 5.6 / 6.1), `profile`, `docs_repo_path`, and `bug_report_destination`. Record its absolute path.

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

Write context governs branch/commit (Phase 0 step 6); **the orchestrator commits the writer's output** (the writer never commits (still true — `doc-writer` runs no git at all; it only writes files)):

| Write context | Branch | Commit |
|---|---|---|
| `obsidian` | NEVER | NEVER |
| `docs_repo` | YES (opt-in confirmed at plan approval) — see Phase 6.2 | YES (orchestrator commits doc-writer's `files_written`) |
| `non_docs_repo` | Phase 0 step 2 already asked user to confirm; if confirmed, behave as `docs_repo` | YES (if user confirmed at Phase 0) |
| `plain_dir` | NEVER | NEVER |

This table governs the **documentation write target only**. Independently of every row above, the run's terminal `commit-artifacts` step commits `$SPECS_PATH`'s bounded session-artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1) — a different repository, never the docs write target.

---

## Phase 6.4 — Style check (before reviewer)

**Mandatory:** the orchestrator MUST dispatch `docs-style-checker` and act on its return — never skip on its own judgement of which linters are installed.

`docs-style-checker` runs the chain **internally**: the repo's primary linter (Vale, etc.) AND — when the `prose-style` plugin is installed — `prose-style-checker` as a complementary semantic / cross-page-consistency pass, merging and deduping both finding sets. The two are complementary, not redundant (Vale: lexical at scale + frontmatter; `prose-style-checker`: engineer jargon, cross-page label consistency, subject-verb agreement, plural/singular label mismatch). The command does NOT invoke `prose-style-checker` separately — the agent already did. It climbs the rungs as a ladder — a detected-but-broken rung does not abandon the ones below it — and, when the caller passes `spaces`, lints each written space with that space's own command.

Invoke `docs-style-checker` on the files written in Phase 6.3:

→ Agent (subagent_type: "dev-workflows:docs-style-checker", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > repo_root: [the resolved docs_repo_path (Phase 0)]
  > files:     [absolute paths of every file written or modified in Phase 6.3]
  > spaces:    [one entry per space in profile.spaces that has a profile.commands.per_space entry — {id, content_root, lint}; omit the key entirely when the profile declares no per_space commands]"

Write the `style_check` ledger row before acting on the return — rewriting the row Phase 0's preflight pre-seeded if there is one, per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3's one-row-per-gate rule, and preserving any `user_decision` it carries (schema:
`${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3), deriving its outcome from the agent's
`primary_attempts` and `complementary_linter`:

- no file was written in Phase 6.3 → `NOT_APPLICABLE`, `precondition_unmet: "no files written"`.
- a primary rung succeeded → `RAN`, `mechanism: <primary_linter>` (+ `prose-style-checker` when it ran),
  `findings:` = the number of merged violations returned.
- every primary rung failed but `prose-style-checker` ran → `DEGRADED`, `not_run:` one entry per failed
  rung from `primary_attempts`, `ci_still_checks: "<the repo's own linter> runs on the PR in CI"`, and
  `findings:` = the number of merged violations returned.
- `status: NOT_CONFIGURED` (no primary rung detected AND `prose-style` absent) → `UNAVAILABLE`;
  convert it per `gate-ledger.md` §5 before proceeding.
- `status: ERROR` → `UNAVAILABLE`; convert it per `gate-ledger.md` §5.

Also write the `repo_checklist` row (creating it, or rewriting it in place if one exists): `NOT_APPLICABLE` with
`precondition_unmet: "the repo publishes no authoring or verification guidance"` when
`doc-planner`'s `repo_verification_gates` block is empty; otherwise `RAN` with `findings:` = the
number of checklist items that failed against the written files.

Then act on the return:

- **`status: NOT_CONFIGURED`** — no primary rung was detected AND `prose-style` is not installed (the agent already climbed the whole ladder). This is a real coverage hole, not a no-op: the ledger row is `UNAVAILABLE` and `gate-ledger.md` §5 converts it before Phase 7. Never proceed on `NOT_CONFIGURED` without that conversion.
- **`status: OK`** — the chain ran (primary and/or complementary), zero merged violations. Proceed to Phase 7.
- **`status: VIOLATIONS_FOUND`** — invoke `doc-fixer` with the violations treated as per their severity. After `doc-fixer` completes, **check its `Stop condition flag`**: `docs-style-checker` maps a linter's own blocking failure to `BLOCKER` (`agents/docs-style-checker.md`), so this dispatch can return `NEEDS HUMAN` — the fixer deferred a blocking violation it could not safely fix. On `NEEDS HUMAN`, surface each deferred BLOCKER with the fixer's reason and ask the user how to resolve it — fix by hand and re-run, or skip the check. A silent re-run only reports the same violation again. The `style_check` gate row stays open until that answer lands and then records its outcome per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` — `RAN` after a hand fix and re-run, `SKIPPED_BY_USER` with the choice quoted verbatim if skipped. Only on `CLEAR` re-run the linter once:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the style violations for this brief:
    >
    > Task description: [doc writing for <KEY>]
    > Reviewer or style-checker output: [paste full docs-style-checker output]
    > Project root: [the resolved docs_repo_path (Phase 0)]
    > Severities to fix: BLOCKER and MAJOR"

  If violations remain after the re-run:
  ```
  choices: ["Proceed to review anyway — reviewer may still PASS", "Show remaining violations and let me fix manually", "Cancel"]
  ```

  When the re-run completes, rewrite the `style_check` row's `findings:` to the post-fix violation count so the Phase 9 table reports what survived, not what was found.

- **`status: ERROR`** — every primary rung AND the `prose-style-checker` pass failed or were unavailable. Surface the error reason, then STOP: the `style_check` row is `UNAVAILABLE`, and the only prompt the user sees is the `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §5 conversion list. Do NOT ask an ad-hoc question here — §5 owns this decision, and the "Choice lists are presented verbatim" rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` binds it.

---

## Phase 6.5 — Render verification

**Ledger first — before the run-condition below.** Both gates this phase owns must carry a row on every run, including runs where the phase does not execute. Per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3 each gate holds exactly one row, so **rewrite** the row Phase 0's preflight pre-seeded rather than appending beside it — and when that pre-seeded row carries a `user_decision`, keep it: the user already decided to proceed without this tooling, and that decision stands until the gate itself proves otherwise. Create the row here only when the preflight did not pre-seed one:

- Write context is `obsidian` or `plain_dir` → append BOTH `build_check` and `render_smoke_check` as `NOT_APPLICABLE` with `precondition_unmet` naming the actual context — `"write context is obsidian"` or `"write context is plain_dir"`. These rows are final; the phase does not run.
- Write context is `docs_repo` or a confirmed `non_docs_repo` → append both provisionally as `RAN`, then rewrite each at the end of this phase per **Ledger (final)** below.

Run this phase after Phase 6.4 **only** when Phase 6.3 wrote files into a buildable docs repo (write context `docs_repo`, or `non_docs_repo` confirmed at Phase 0). Skip for `obsidian` / `plain_dir` (nothing was written into a repo that builds) — the rows above are already recorded. Mechanics: `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/render-verification.md`. "Affected pages" = every file written or modified in Phase 6.3.

### Step 1 — Build check (gating)

Resolve the build command per space — `profile.commands.per_space.<space>.build`, else the flat `profile.commands.build` — and run it for every space in the **verification set** (`${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/render-verification.md` §2): every space whose `content_root` holds at least one affected page. Do NOT re-run the Phase 6.4 prose linter. Classify any failure:
- **Content failure** (the template won't compile, unresolved snippet include, broken postid/internal link, malformed token) → invoke `doc-fixer` (Severities: BLOCKER and MAJOR), then re-run the build once. If failures remain:
  ```
  choices: ["Proceed to smoke-check anyway", "Show remaining and fix manually", "Cancel"]
  ```
- **Environmental failure** (the build tool will not run — missing toolchain, `command not found`, missing `.docstack` shim) → surface the reason; no `doc-fixer` loop:
  ```
  choices: ["Install <the missing tool> and retry this gate", "Proceed without this check — record my decision", "Cancel the run", "Other… (describe)"]
  ```
  This is the `gate-ledger.md` §5 conversion for `build_check`, not an orchestrator decision: "Proceed without this check" writes `SKIPPED_BY_USER` with the chosen option quoted verbatim in `user_decision`. Do NOT present this list when the `build_check` row already carries a `user_decision` from Phase 0's preflight naming the same missing tool — the user answered this question before anything was written, and that answer stands. Record the failure reason in the row, keep the existing `user_decision`, and continue to Step 2 without prompting.

When the profile declares **no** build command at either level, record "no build command in profile; build proof deferred to the dev-server boot (Step 2)" and proceed. Under the built-in example-docs profile this branch does not apply — `commands.per_space.cloud.build` and `commands.per_space.self-hosted.build` are both defined.

### Step 2 — Dev-server smoke-check (opt-in, best-effort)

Offer it. Present this list **verbatim** — the "Choice lists are presented verbatim" rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` forbids moving `(Recommended)`, reordering the options, or re-wording them. Dev-server flakiness and a clean static check are reasons to say something in prose beside the list; they are never reasons to recommend Skip.
```
choices: ["Run smoke-check (Recommended)", "Skip — use the manual table only", "Cancel", "Other… (describe)"]
```

When run, boot each space in the **verification set** — every space whose `content_root` holds at least one affected page (see `render-verification.md` §2) — **sequentially** (`profile.dev_servers.concurrent: false` forbids overlap). Full mechanics in `render-verification.md`:
1. **Prerequisites (best-effort, never auto-applied).** Verify `profile.prerequisites`. The `.docstack` shim is a local, gitignored dev-environment workaround — check it, NEVER apply it. Unmet → record "smoke-check skipped for `<space>`: prerequisite `<x>` unmet" and use the manual table for that space.
2. **Boot** `profile.dev_servers.servers[<space>].command` in the background; record the process id.
3. **Readiness poll** — GET `http://localhost:<port><base_path>/` until HTTP 200 or `profile.dev_servers.readiness_timeout_seconds` seconds (fall back to **120** when absent). On timeout → stop the process, record "smoke-check skipped for `<space>`: not ready", use the manual table for that space.
4. For each affected page in `<space>`, GET its derived URL (Step 3 route rule) → assert **HTTP 200**.
5. **Stop the server** (kill the recorded process id) before the next space.

Outcomes:
- **404/500** on an affected page = render defect → treat as a Step 1 content failure (offer `doc-fixer` / surface).
- Any **boot / prerequisite / readiness** problem is best-effort → never blocks; that space falls back to the manual table.

### Step 3 — "Pages to visit" table (always)

Emit a table, one row per affected page — its URL (`http://localhost:<port><base_path>/<route>`, derived against its own space's dev server) and what to verify ("confirm the page renders as intended"). When the smoke-check ran, annotate each row ✅ 200 / ⚠️ skipped (reason) / ❌ failed.

**Route derivation (best-effort):** `<route>` = the page path relative to its space's `content_root` with a trailing `index.md`/`.md` removed. Approximate — a wrong route that 404s in Step 2 simply downgrades that page to the manual table.

Carry the table and the Step 1/Step 2 outcomes into the Phase 9 `### Render verification` section, and pass a one-paragraph `render_verification` summary to Phase 7.

**Ledger (final).** Rewrite the two rows appended at the top of this phase (schema: `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3). A row already written as `NOT_APPLICABLE` is never reached here — this phase did not run:

- `build_check` — `RAN` when a build command executed; `DEGRADED` when no build command exists and the
  Step 2 boot served as the proof, with `ci_still_checks: "the repo's build runs on the PR in CI"`;
  `FAILED` on a content failure. A row Step 1 already wrote as `SKIPPED_BY_USER` (its §5 conversion,
  when the build tool would not run and the user chose to proceed) is **final — do not rewrite it**.
  `UNAVAILABLE` applies only when the build could not be attempted AND Step 1 did not already convert
  it: no build command exists **and** Step 2 did not run. That is the coverage hole
  `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` §5 predicts — convert per
  `gate-ledger.md` §5. When the user has just declined the Step 2 smoke-check, fold this conversion into that same decision rather than prompting twice — record `SKIPPED_BY_USER` carrying their Step 2 choice, since declining the only remaining source of build proof is declining the build check.
- `render_smoke_check` — `RAN` when the smoke-check completed for every space in scope;
  `DEGRADED` when at least one space fell back to the manual table, with `not_run:` naming the space
  and its reason (prerequisite unmet / boot failure / readiness timeout);
  `SKIPPED_BY_USER` with the chosen option quoted verbatim when the user selected Skip.

---

## Phase 7 — Doc review gate

Invoke `doc-reviewer` (Opus — pinned by its own frontmatter; recorded as `review_model`, no dispatch override added). The reviewer is **product-docs-only**; Epic drafts go through `epic-reviewer` in `/epics`.

→ Agent (subagent_type: "dev-workflows:doc-reviewer"):
  > "Review the written product documentation for this brief:
  >
  > Task description: [one-paragraph summary of the feature and <KEY>]
  > Written doc file paths: [absolute paths of every file written in Phase 6.3]
  > PRD folder path:        [the resolved folder]
  > Diff summaries:         [array of diff-summarizer outputs from Phase 5]
  > doc-planner checklist:  [the full YAML from Phase 5.7]
  > style-check report: [the violations output from Phase 6.4 — from docs-style-checker or prose-style-checker; same violation schema regardless of source]
  > gate_ledger:        [the complete gate_ledger block — one row per gate in references/gate-ledger.md §4, including the Phase 0 toolchain_preflight row]
  > render_verification: [the Phase 6.5 summary — build result; smoke-check per space (passed / skipped with reason)]
  > code_repos:         [the Phase-4 resolved {slug, path} map; [] if none resolved]
  > existing_image_decisions: [the Phase 5.6/6.1 stale-image-swap array, one entry per **reviewed occurrence** and each {target, occurrence, old_url, new_url, section, decision}. `[]` when the per-item existing-image review did not run — the existing-image list was empty, or the user chose "Add-list only" / "Nothing to do" at the Phase 5.6 merged prompt. An all-declined review is NOT `[]`: every reviewed occurrence appends an entry, `decision: declined` included. Supplies the swap-completeness evidence for the 'Screenshots' dimension]
  > profile:            [the resolved docs-profile from Phase 0 — supplies frontmatter.changelog_guidelines and spaces[]]"

Act on the verdict:

**Triage sub-step** (before any fixer dispatch): follow `${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md`. For each finding, verify its claimed consequence at the location it names; keep or dismiss; record every dismissal with a reason that disposes of that finding's own claim. Hand the fixer **survivors only**, and carry the dismissal list into this run's report.

- **BLOCK** — invoke `doc-fixer` with `Severities to fix: BLOCKER and MAJOR`. Write the `doc-fixer` Fix Report to a temp file (`mktemp -t dw-doc-claims-XXXX.md`, never inside a repo tree or the specs tree), record its path as `claims_file`, then **check `doc-fixer`'s `Stop condition flag` before re-invoking anything**. If it is `NEEDS HUMAN`, the fixer deferred at least one BLOCKER as needing a human decision: do NOT re-invoke `doc-reviewer` — a re-review can only re-find the BLOCKER the fixer has just reported it could not resolve — and instead surface each deferred BLOCKER with the reason the fixer gave, then escalate it individually per the `Review verdict BLOCK (unresolved after one fix cycle) — /document` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, which names this entry point alongside the second-BLOCK one. Only when the flag is `CLEAR` do you re-invoke `doc-reviewer` once **passing `claims_file`** — so the re-review falsifies the fixer's account rather than assuming it. If the second verdict is still BLOCK, escalate for each unresolved BLOCKER individually per the `Review verdict BLOCK (unresolved after one fix cycle) — /document` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
  ```
  choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]
  ```
  "Manual fix notes" → take free-text from the user; apply via `doc-fixer` in a bounded one-shot pass (no further re-review cycle). "Defer" → record in Phase 9 `### Deferred items` without an override flag. "Override" → record in `### Deferred items` with the user's rationale. "Cancel" aborts.

- **PASS WITH RECOMMENDATIONS** — invoke `doc-fixer` for MAJOR findings only:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the review findings for this brief:
    >
    > Task description: [doc writing for <KEY>]
    > Reviewer or style-checker output: [paste the triaged survivor list from the triage sub-step above — the surviving `doc-reviewer` findings only, never the dismissed ones]
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
Implementation: [one-sentence description of what was documented, naming <KEY>]
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
> Determine if *other* documentation needs updating as a consequence of this write (e.g., an index page, a cross-referenced overview, a changelog entry in the repo root). Do NOT touch release-notes / what's-new pages — those are generated by automation.
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
> If YES: identify the most appropriate existing file (never propose a new file if an existing one fits) and return a proposed edit — write nothing. The entry format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the key + feature summary]
> Return: `{file, anchor, replacement, reason}` — `anchor` is the exact existing text to change, or the section to append to; `replacement` is the entry above in full; `reason` is why it's warranted — OR 'no update required'."

**Agent 3 — Instructions** (general-purpose, model: `<detection_model — §9 / §2.1 Sonnet chain>`):
> "Post-write instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any doc-writing rules, guidance, or guardrails are missing because of what this run revealed (e.g., a repo-specific frontmatter field that must always be present, a cross-link pattern that's easy to miss, an image-policy rule that caught you out).
> Skip if: the run followed existing conventions with no surprises. Only update if a concrete, recurring rule would have prevented a decision point or misunderstanding.
> If YES: keep it minimal, additive, and scoped — do not propose rewriting sections wholesale — and return a proposed edit — write nothing.
> Return: `{file, anchor, replacement, reason}` — `anchor` is the exact existing text to change, or the section to append to; `replacement` is the proposed new/changed text; `reason` is what this run revealed that warrants it — OR 'no update required'."

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
`command: /document (keyed mode)`, the run's `key` and `source`, and
`plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only
the report's **Command workflow improvements**, **New agents / skills**, and
plugin **Reference docs** sections plus the **Key observations** that
triggered them (§4 plugin-facing predicate) — never target-project
`CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id`
(§3), resolves the target via the §2 specs-first ladder, and writes silently.
List the persisted path (or "no plugin-facing signal — nothing persisted") in
the Phase 9 report's Session learnings line. ADDITIVE — the impl-maintenance
report still appears in the report; this step NEVER fails the run, NEVER
commits (still true — this step only writes the feedback file; those writes
are committed by the separate terminal `commit-artifacts` step, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the docs repo or the current working directory.

---

## Phase 8.5 — Finish & handoff

Run this phase only when Phase 6.3 wrote + committed in a git repo (write context `docs_repo`, or `non_docs_repo` confirmed at Phase 0) — i.e. a branch with this run's commits exists. Skip otherwise (nothing to hand off). Mechanics: `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md`.

### Step 1 — Squash (always)

Fold the run into clean history before handoff:
1. Stage the run's uncommitted docs-repo edits — Phase 8 Agent 1 (doc index / cross-links) may have edited without committing; the Phase 6.2 clean-tree check means everything uncommitted is this run's work.
2. Compute the squash base: if Phase 6.2 recorded `profile_commit` (inline-profiling run), base = `profile_commit` (keeps the profile-config commit as a distinct first commit → two commits); otherwise base = `git merge-base <base_branch> HEAD` (one commit).
3. `git add` the docs-repo changes → `git reset --soft <squash-base>` → one `git commit`. The message follows `profile.commit_convention` when present (example-docs: `<KEY> <summary>`); for a repo with no such field, infer from recent `git log` / `CONTRIBUTING`, else fall back to `<KEY> <summary>`. NEVER put the key in a reader-visible changelog — see `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §1.

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
2. **Compose the draft**: title (per `commit_convention`); body — what was documented, the output files, the Phase 6.5 render-verification summary, deferred style/review/render items, a link to the PRD. When Phase 5.8 recorded any `document-as-spec` / `skip-and-report` decision, prepend a banner: `> ⚠ DO NOT MERGE until <KEY>-implementation-gaps.md is resolved.` A qualifying `document-as-code` decision (§7.5) does NOT get this banner even though it also produces a gaps file — the docs correctly describe what shipped, so the PR is mergeable; only the source ticket needs correcting.
3. **Write + show**: write `pr-draft.md` to the resolved PRD folder (`ignore: legacy find $x -maxdepth 5 -type d -name "<KEY>*"`; ask if none) AND print it.
4. **Host footer**: Bitbucket → "open a PR in the web UI and paste the title + body"; GitHub → additionally offer `gh pr create --title "<title>" --body-file <pr-draft path>` that the user may run; other → "open a PR and paste the title + body". Bitbucket offers no CLI to open one — a host capability limit, not a policy: the plugin does open a pull request on a host with a CLI, but only in the separate GitHub-hosted specs repo (`$SPECS_PATH`), via a different flow — never in this docs repo (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.6).

Carry the squash result, push outcome, and PR-draft path into the Phase 9 report.

---

## Phase 8.6 — Maintenance proposals

Runs **after** Phase 8.5 — never before. The ordering is the whole safety property, and it holds whether or not Phase 8.5 ran: once this phase starts, **the run will create no further commit in the docs write target** — either Phase 8.5 sealed the docs commit, or the write context never commits at all (`obsidian` / `plain_dir`, per the Phase 6.3 branch/commit table — which governs the docs write target only, never `$SPECS_PATH`). Either way an accepted `CLAUDE.md` (or knowledge-base) edit has no commit left to ride. What still commits after this point is the terminal `commit-artifacts` step, which stages ONLY `$SPECS_PATH`'s bounded artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1) — it can never pick up a `CLAUDE.md` or knowledge-base edit, so the safety property holds unchanged.

Skip this phase with no prompt when both Phase 8 Agent 2 and Agent 3 returned `'no update required'`.

Otherwise present one row per proposal:

| File | Rule / entry | Reason |
|---|---|---|
[one row per Agent 2 / Agent 3 proposal — `file`, the rule or knowledge entry in one line, `reason`]

```
choices: ["Skip — report only (Recommended)", "Apply all", "Choose per proposal", "Cancel"]
```

- **Skip — report only** — apply nothing; every proposal's disposition is `proposed` for the Phase 9 report.
- **Apply all** — apply every proposal via the mechanism below; every proposal's disposition is `applied-uncommitted`.
- **Choose per proposal** — ask accept/decline for each proposal; apply the accepted ones (`applied-uncommitted`), leave the rest `declined`.
- **Cancel** — apply nothing; every proposal's disposition is `proposed`. Unlike every other "Cancel" in this command, **Cancel here does not abort the run**: by the time this phase runs there is nothing upstream left to unwind — Phase 8.5's squash (and any push / PR draft) is already done, or the write context never committed at all (`obsidian` / `plain_dir`) (still true — what still commits after this point is the terminal `commit-artifacts` step, bounded to `$SPECS_PATH`'s artifact paths per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1, and therefore never able to carry a proposal from this phase). Cancel only declines this phase's proposals; the run proceeds to Phase 9 and the Final Report is produced exactly as it would be after Skip.

**Apply mechanism.** For each accepted proposal, re-dispatch the agent that produced it — Agent 2 or Agent 3, same general-purpose agent and model as Phase 8, no new agent type — in apply mode, carrying its own proposal back verbatim:

> "Apply this proposed edit exactly as returned — do not re-derive it:
> `{file, anchor, replacement, reason}`: [paste the proposal]
>
> Locate `anchor` in `file` and write `replacement` in its place (or append it, if the proposal is an append). Return: file written, OR a mismatch note if `anchor` no longer matches the file's current content — do NOT guess at the intended location; skip and report the mismatch."

Applied edits are left **uncommitted** — deliberately. Do NOT stage, commit, or re-run Phase 8.5 for these files: in a repo where a `CLAUDE.md` change triggers a review of its own, long enough to delay the documentation it would otherwise ride with, that change needs its own PR on the user's timing. A later `/document` run's Phase 6.2 clean-tree check will trip on these uncommitted files until the user commits or discards them — that is intended, not a bug to fix.

Carry each proposal's `{file, reason, disposition}` into the Phase 9 report.

---

## Phase 9 — Final Report

Output a structured report — do NOT ask any closing confirmation:

```
## keyed Documentation Report

### Classification
SIGNIFICANT — keyed feature documentation has large blast radius if wrong

### Model Routing
- Session / writer model (current_model): [model] — [if it ran degraded: "Sonnet; user proceeded past the Phase 1.5 advisory" | "Sonnet; no Opus available" | "on §2 chain — no degradation"]
- doc-planner synthesis (planning_model): [model]
- Detection steps — the folder read, diff-summarizer, doc-location-finder, docs-style-checker, doc-fixer, maintenance (detection_model): [model]
- doc-reviewer (review_model): [model]
- Opus available: [yes | no]

### PRD folder summary
- PRD: [<KEY>] [summary, 1 line]
- Linked items: [count by type — e.g. "3 Epics, 7 Stories, 2 Sub-tasks, 1 Research"]
- Themes: [2–4 bullet points from the folder read]

### Repos analysed
- <repo-1> (<resolved repo_path>) — [N PRs in scope, M resolved, K unresolved]
- ...

### PRs in scope
- [PR URL] — status: [MERGED | OPEN | DECLINED | UNKNOWN], resolved_via: [pr_ref | branch_search | merge_commit | key_commits | gh_cli | unresolved]
- ...

### Output file(s)
- [absolute path] — [kind: extend-existing | new-page-in-existing-section | new-section]
- ...

### Branch
[branch name created in Phase 6.2, e.g. docs/<key>-<slug>] OR "N/A — no branch created (context: obsidian / plain_dir / user declined branching)"

### Verification gates
| Gate | Outcome | Mechanism | Detail |
|---|---|---|---|
[One row per gate in the `gate_ledger`, in registry order (`references/gate-ledger.md` §4). "Detail" carries the row's `ci_still_checks` (DEGRADED), `user_decision` (SKIPPED_BY_USER), or `precondition_unmet` (NOT_APPLICABLE) — empty otherwise. When any row is DEGRADED, follow the table with a one-line warning naming what CI will check that this run did not.]

### Render verification
- Build: [ran — pass/fail | unverified (reason) | no build command in profile — boot served as the proof (does NOT apply to example-docs, which defines per-space build commands)]
- Smoke-check: [per space — passed (N pages, HTTP 200) | skipped (reason)] OR "not run (user skipped)"
- Pages to visit: [the Phase 6.5 Step 3 table]

### Doc review verdict
[PASS | PASS WITH RECOMMENDATIONS | BLOCK] — [1-line summary of findings applied / deferred]

### Review triage
- **Review triage:** [N findings reviewed, M survived] — dismissals: [one line per dismissal, `finding — reason`; or "none"]

### Documentation (Agent 1)
- [file updated] — [what was added/changed] OR "no update required (reason)"

### Knowledge base (Agent 2)
- [file, rule/entry summary, reason] — disposition: [proposed | applied-uncommitted | declined] OR "no update required"

### Instructions (Agent 3)
- [file, rule/entry summary, reason] — disposition: [proposed | applied-uncommitted | declined] OR "no update required"

### Maintenance applied (uncommitted)
[Every Phase 8.6 proposal with disposition `applied-uncommitted` — file, one-line summary, reason — one per line. These edits are deliberately excluded from the Phase 8.5 docs commit: a repo-governance file like `CLAUDE.md` needs its own PR on the user's timing, not a ride on this run's docs commit. Run `git status` in the docs repo to review before committing them separately. OR "none".]

### Session learnings (Agent 4)
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Screenshots to upload manually
[Only populated for the **Defer** path of Phase 6.1 — i.e. a target used image_policy: cdn_upload_required (or the user selected "Stage for manual upload" under the ambiguous branch) AND the user chose "Defer — stage with TODO placeholders" at the Phase 6.1 CDN handoff. For each staged screenshot: src (original user-provided path), staging path under <screenshot_staging_dir> (the staging directory), the target page it belongs on, the proposed alt-text, and the upload_note from the planner. Omit this section entirely when no screenshots were staged — including when the user chose "Upload now" in Phase 6.1 (those images carry real CDN URLs in the markdown and need no manual step).]

### Implementation gaps (PRD vs source)
[Populated when Phase 5.8 produced any `document-as-spec` / `skip-and-report` decision, **or** any qualifying `document-as-code` decision (per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.5 — the PRD phrasing asserts a specific value that contradicts the source). All three write the same bug-report draft, so all three are listed here; the status line differs by decision:
- `document-as-spec` / `skip-and-report` → "Bug-report draft written to <path>. If docs were branched, DO NOT merge the PR until these gaps are resolved."
- qualifying `document-as-code` → "Bug-report draft written to <path>. Documented as shipped; the source ticket carries an incorrect claim — correct the ticket, no PR block."

List each gap (claim, decision) with its own status line — never print the DO-NOT-MERGE sentence for a `document-as-code` gap, and never print it at all on a run whose only gaps are `document-as-code`: the docs describe what shipped, the PR is mergeable, and Phase 8.5 deliberately withholds the PR banner for exactly this case. Omit the section when there were no discrepancies.]

### Skipped items
[Gaps the planner flagged with recommended_action: "skip with note in final report" — one line each; or "none"]

### Deferred items
[List first, each tagged **MAJOR — incomplete swap, invisible in the diff**: any accepted existing-image swap `doc-writer` skipped because the file's occurrence no longer matched `old_url` (its `notes` return — the position went stale between Phase 5.6 and Phase 6.3). This is distinct from the items below — it's a race that left an already-accepted decision unfulfilled, not a routine low-priority deferral. Then: MINOR / NIT findings that were not applied, OR user-declined screenshots, OR doc-reviewer BLOCK findings that were overridden / deferred — one line each; or "none"]

### Assumptions & limitations
- [list any]

### Git state
[When Phase 8.5 ran: "Branch <name> — squashed to N commit(s); pushed to origin: <yes/no>; PR draft: <pr-draft path>." When Phase 8.5 was skipped (no branch/commits): "Working tree has uncommitted changes. /document (keyed mode) writes but does not commit the docs write target in non-git contexts; this run's $SPECS_PATH session artifacts are committed separately by the terminal step."]

### Next step
[Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — guidance only, never auto-invoked. Once **all** the PRD's Epics are documented, draft/finalize the release note → `/dev-workflows:release-notes <PRD>` (PRD-level; run once, not per Epic). If the review BLOCKED, resolve that first.]

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 11), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:

- **On to `/dev-workflows:release-notes <PRD>` (still Dev — a spec or design exists by now, so this is the late run)?** → run **`/compact`** — context stays relevant.
- Consider **`/rename <PRD-ID>-<slug>-dev`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

---

## Phase 10 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 9 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's out-of-scope / manual-step
follow-ups by citing
`${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` and executing its steps
inline.

1. **Collect** the follow-up items already aggregated in the Phase 9 report:
   `### Screenshots to upload manually`, `### Implementation gaps (PRD vs source)`,
   `### Skipped items`, and `### Deferred items`.
2. **Filter** them with the reference's §6 qualifying predicate — emit only
   out-of-scope / manual-step signals; drop in-scope items the report already
   tracks.
3. **Resolve** the write target via §2 using the
   run's `key` and `source`; render + place tasks and verbose notes per
   §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 9 report (today's
behaviour). This phase NEVER fails the run, NEVER commits (still true — this
phase only writes follow-up files; those writes are committed by the separate
terminal `commit-artifacts` step, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the docs repo or the current working directory.

---

## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /document (keyed mode)`, `phase: documenting`,
`role: dev`, the run's `key` and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<PRD-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no PRD key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

**Then write the resume pointer.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite
`<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the
pointer reflects the completed run, and before the commit step below, so it
is included in it. Redact per §1. Silent; the printed `### Context hygiene`
guidance already appeared in the Phase 9 report.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — the LAST action of the
run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`,
commits `<KEY> Add dev-workflows session artifacts (/document)`, and pushes
per §4 step 5. It NEVER writes into the docs repo this run just changed —
the documentation commit, branch, and PR are untouched — NEVER touches a
code repo, anything outside `$SPECS_PATH`;
NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries
`specs_git: blocked` (§3.3 G0), re-emitting that notice. Because the Phase 9
report was composed before this phase, **print its §6 outcome line here**,
as the run's last output — prefixed `Specs repo:`, with any guard notice
repeated in full.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (the
documentation commit, branch, and PR are handled in Phase 8.5; the terminal
step above commits only the bounded session-artifact paths in `$SPECS_PATH`),
and NEVER writes into the docs repo or the current working directory; no user
name is ever written (§10 privacy).

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, key-not-found, cancellation)
- ALWAYS run Phase 0 docs-repo detection; if 0 signals, require user confirmation before proceeding
- NEVER call Bitbucket REST APIs for Cloud or self-hosted Server — Bitbucket URLs are identifiers only; all resolution is pure local git
- GitHub URLs may use the `gh` CLI for head/base SHA resolution; no direct REST calls outside `gh`
- NEVER write inside `_archive/` — that path is read-only by convention
- NEVER write product documentation outside the resolved `docs_repo_path` (Phase 0); the only other writes are to the resolved PRD folder (the `implementation-gaps.md` bug-report draft, the `<KEY>-pr-draft.md`, and screenshot staging) — never anywhere else.
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS invoke `docs-style-checker` (Phase 6.4) before `doc-reviewer` (Phase 7)
- ALWAYS run the Phase 0 toolchain preflight (`${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md`) after profile resolution and before Phase 1; it prompts only when a required tool is missing
- ALWAYS run `specs-preflight` in the shared `## Mode detection` section, before dispatching to either mode — so it runs for Mode B as well as Mode A — and `commit-artifacts` as the run's last action (per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`) — bounded to `$SPECS_PATH`'s artifact paths (§2.1) and to plugin-created branches (§2.2), always `git -C "$SPECS_PATH"` and never a `cd` (§1 rule 1), never force-pushing, and never failing the run
- ALWAYS append each gate's ledger row at the moment that gate completes, per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` — NEVER reconstruct the ledger at Phase 9, and NEVER leave a registry gate without a row
- NEVER present a phase's `choices:` array in an order, wording, or recommendation other than the one written; the "Choice lists are presented verbatim" rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` binds every prompt in this command
- ALWAYS invoke `doc-reviewer` before Phase 8 maintenance
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin each subagent dispatch to its §9 chain via `model:` — `doc-planner` to the §2 Opus chain, the mechanical steps (the folder read, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, maintenance) to the §2.1 Sonnet chain; `doc-reviewer` keeps its frontmatter Opus pin (no override); the inline writer + gates run on `current_model` (advisory only)
- ALWAYS cap review/fix cycles: 1 fix + 1 re-review max
- ALWAYS pass `Change type: docs` in the Phase 8 change summary block
- ALWAYS pass `Command run: /document` in the Phase 8 Agent 4 session handoff
- ALWAYS spawn Phase 8 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 9 report as the final output
- ALWAYS end the Phase 9 report with a `### Next step` recommendation (per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`) — guidance only, never auto-invoked; omitted in direct doc-edit mode (Mode B)
- ALL written claims must be traceable to a resolved key or to PR diffs — attribution goes in the run's return payload and the commit message, NEVER inline in the rendered page (`${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §1)
- For `image_policy: cdn_upload_required`, NEVER copy user-provided screenshots into the repo — stage under `<screenshot_staging_dir>`, a persistent directory the operator named (never the docs repo, never `/tmp`) — and surface in the Phase 9 `### Screenshots to upload manually` section
- ALWAYS end the Phase 9 report with a `### Context hygiene` block per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the `resume.md` write runs later, in the terminal cost phase, per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the guidance only), then a docs→PM handoff suggestion (`/clear`) + `/rename <PRD-ID>-<slug>-dev`; guidance only, never auto-run. **Mode B (direct doc-edit) omits this** — no PRD context.

---

# Mode B — direct documentation edit (`@file` / free-text)

Implement the following doc edit: $ARGUMENTS

If the argument starts with `@`, treat it as a path to a markdown file. Resolve relative to the current working directory. Read its full content and use it as the description. Echo `📄 Reading prompt from \`<file>\`…` before proceeding. If the file cannot be read, stop and report the error immediately.

`/document` (direct mode) is the **one-shot doc-editing** workflow — minor edits, formatting, small updates to existing pages, and single-file additions where the content comes from the user's description alone. It is the right tool when:
- the change is small and the content is already in the user's head or the file, **not** scattered across PRD sections and PR diffs
- no tests, no branch (still true — the specs-repo preflight creates none, `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2), no code review, and no commit of the doc edit are warranted

For net-new documentation assembled from a PRD folder plus PR diffs, use keyed mode (above). For writing child Epic drafts from a Product Requirements Document, use `/epics`.

No model-routing reminder is injected for this command — classification still happens but is always SIMPLE or MODERATE, and Opus is never invoked.

---

## Phase 0 — Load the description

1. If `@file` syntax: read the file, confirm `"Loaded prompt from <filename.md> (N lines)."`, note any embedded images as "referenced image: <path>". Otherwise use the inline text verbatim.

2. **Initialize the ledger.** Create the run's `gate_ledger` block per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3 — unconditionally, before the git-tree check below. Direct mode registers three gates (`gate-ledger.md` §4); each needs a row even when this run cannot lint anything.

3. **Toolchain preflight.** Resolve `repo_root` = `git rev-parse --show-toplevel` from cwd. Then execute
   `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` against it. Direct mode has no profile, so
   use **sources 2 and 3 only** (repo config signals and the repo's documented `Prerequisites`); the
   only gate in scope is `style_check`, so `required_by` never names `build_check` or
   `render_smoke_check`.

   Append the `toolchain_preflight` row per
   `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3. Present the §5 prompt verbatim only when a
   required tool is missing; on "Cancel", stop with `TOOLCHAIN_UNAVAILABLE: <missing tools> not
   available in this environment.` When cwd is not a git tree there is no repo to lint: record `toolchain_preflight` as `RAN` with `mechanism: "no repo to check — cwd is not a git repository"` and `findings: 0` (its precondition is "always", so it is never `NOT_APPLICABLE`), record `style_check` and `repo_checklist` as `NOT_APPLICABLE` with `precondition_unmet: "cwd is not a git repository"`, then skip the rest of this step and the checklist extraction below and proceed — the ledger is complete and Phase 3.5 runs no gates.

4. **Extract the repo's pre-PR checklist.** Direct mode has no `doc-planner`, so the orchestrator does
   this itself. In the **same pass** that read the repo's guidance files for step 3's `Prerequisites`,
   follow `${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §2–§4 and build the
   `repo_verification_gates` block. Carry it to Phase 3.5, which checks the edited files against it and
   records the `repo_checklist` ledger row. An empty block is normal — record it and move on. Skip this
   step entirely when cwd is not a git tree (step 3 already skipped for the same reason).

**Specs-repo preflight.** Already run — the shared `## Mode detection` section executed
`specs-preflight` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §3) before dispatching to
either mode, so it runs for Mode B exactly as it does for Mode A, and any `specs_git: blocked` flag
it set is carried into this mode too. Do not run it a second time.

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

If your reading of the task lands closer to SIGNIFICANT or HIGH-RISK (multi-repo, net-new feature pages from a PRD folder, published-documentation blast radius that needs a reviewer gate), **stop and redirect the user** to keyed mode or `/epics`:
```
choices: ["Re-run under /dev-workflows:document (keyed mode) (for PRD-sourced feature documentation) (Recommended)", "Re-run under /dev-workflows:epics (for Epic drafting)", "Proceed under direct mode anyway — I accept the simplified flow", "Cancel"]
```

State the classification and a one-line reason, then proceed to Phase 2A.

*(There is no Phase 2B, Phase 3B, or Opus review in this command. A mandatory Phase 3.5 style check runs after Phase 3. Phase numbering is kept aligned with `/implement` to make cross-referencing straightforward; the A-suffix on Phase 2A below is retained for symmetry, not because a Phase 2B exists for docs.)*

---

## Phase 2A — Plan

**Repo exploration** — Before writing the plan, spawn an exploration subagent to map the relevant docs and any sibling conventions:

→ Agent (subagent_type: "general-purpose", tools: Read/Glob/Grep only — no Bash, no Edit):
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
   - All `[[wikilinks]]` resolve to existing files in the docs tree
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
7. **Do NOT create a branch, and do NOT commit the doc edits.** The user manages git manually for doc edits. (The run's terminal `commit-artifacts` step is a separate repository — it stages ONLY `$SPECS_PATH`'s bounded artifact paths, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1 — and never the files edited here.)
8. Verify the outcome matches the approved plan.
9. Proceed to Phase 3.5.

---

## Phase 3.5 — Style check (mandatory)

**Skip this entire phase** when Phase 0 recorded direct mode's gates as `NOT_APPLICABLE` (cwd is not a git repository): do not dispatch `docs-style-checker`, do not check the repo checklist, and write no rows — the ledger is already complete and final. Proceed to Phase 4.

After writing the edits and before Phase 4, dispatch `docs-style-checker` on the changed file(s):

→ Agent (subagent_type: "dev-workflows:docs-style-checker"):
  > repo_root: [cwd's git root]
  > files:     [the files edited in Phase 3]

- `VIOLATIONS_FOUND` → apply safe fixes via `doc-fixer` (one fix cycle), then check the fixer's `Stop condition flag`. On `NEEDS HUMAN` it deferred a blocking violation it could not safely fix: surface each deferred BLOCKER with the fixer's reason and ask the user whether to fix it by hand and re-run, or skip the check — direct mode runs no reviewer, so nothing downstream would catch it. Record the `style_check` row from that answer per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` (`RAN` after a hand fix and re-run, `SKIPPED_BY_USER` with the choice quoted verbatim). Only on `CLEAR` re-run once.
- `OK` → proceed to Phase 4.
- `NOT_CONFIGURED` / `ERROR` → no primary rung and no complementary pass produced a result, so the gate has no coverage. Record `style_check` as `UNAVAILABLE` and convert it per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §5 before proceeding. Direct mode has no reviewer gate, so this prompt is the only place the gap surfaces — never proceed past it silently.

Never skip this phase on your own judgement of which linters are installed. `docs-style-checker` runs the chain internally as a **ladder**: each primary rung is tried in turn (a detected-but-broken rung does not abandon the ones below it), and `prose-style-checker` runs as a complementary semantic pass whenever the `prose-style` plugin is installed — so neither the repo's own linter nor the semantic / cross-page class is silently dropped. Write the `style_check` ledger row here — rewriting the preflight's pre-seeded row if there is one, per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3's one-row-per-gate rule (schema: `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3), carrying the returned `primary_attempts`: `RAN` when a primary rung succeeded; `DEGRADED` when every rung failed but `prose-style-checker` ran, with `not_run:` one `{mechanism, reason}` entry per failed rung and a `ci_still_checks:` line; `UNAVAILABLE` per the bullets above; `NOT_APPLICABLE` with `precondition_unmet: "no files edited"` when Phase 3 changed nothing.

After the style check, hold the edited files against the `repo_verification_gates` block extracted in Phase 0 (`${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §5) and append the `repo_checklist` ledger row: `RAN` with `findings:` = the number of entries that failed, or `NOT_APPLICABLE` with `precondition_unmet: "the repo publishes no pre-PR checklist"` when the block is empty. Report any failed entry to the user with its `source` citation — direct mode has no reviewer gate, so this is where the repo's own rules surface.

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
> If YES: identify the most appropriate existing file (never propose a new file if an existing one fits) and return a proposed edit — write nothing. The entry format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the doc-edit description]
> Return: `{file, anchor, replacement, reason}` — `anchor` is the exact existing text to change, or the section to append to; `replacement` is the entry above in full; `reason` is why it's warranted — OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-doc-edit instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any doc-editing rules, guidance, or guardrails are missing because of what this edit revealed (e.g., a repo-specific frontmatter field that must always be present, a cross-link pattern that's easy to miss, a style rule that caught you out).
> Skip if: the edit followed existing conventions with no surprises. Only update if a concrete, recurring rule would have prevented a decision point or misunderstanding during this edit.
> If YES: keep it minimal, additive, and scoped — do not propose rewriting sections wholesale — and return a proposed edit — write nothing.
> Return: `{file, anchor, replacement, reason}` — `anchor` is the exact existing text to change, or the section to append to; `replacement` is the proposed new/changed text; `reason` is what this edit revealed that warrants it — OR 'no update required'."

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
`command: /document (direct mode)`, the run's `key` (usually `null` in
direct mode) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only
the report's **Command workflow improvements**, **New agents / skills**, and
plugin **Reference docs** sections plus the **Key observations** that
triggered them (§4 plugin-facing predicate) — never target-project
`CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id`
(§3), resolves the target via the §2 specs-first ladder, and writes silently.
List the persisted path (or "no plugin-facing signal — nothing persisted") in
the Phase 5 `### Session learnings (Agent 4)` line. ADDITIVE — the
impl-maintenance report still appears in the report; this step NEVER fails the
run, NEVER commits (still true — this step only writes the feedback file;
those writes are committed by the separate terminal `commit-artifacts` step,
per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the docs repo or the current working directory.

---

## Phase 4.5 — Maintenance proposals

Direct mode never commits the doc edits — Phase 3 explicitly creates no branch and no commit — so the ordering constraint that gates keyed mode's Phase 8.6 is already satisfied here: there is no docs commit for an accepted proposal to ride. What the run does commit, via the terminal `commit-artifacts` step, is bounded to `$SPECS_PATH`'s artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1) and can never carry a proposal from this phase. This phase exists only so an accepted proposal still gets applied instead of just reported, the same as keyed mode's Phase 8.6.

Skip this phase with no prompt when both Phase 4 Agent 2 and Agent 3 returned `'no update required'`.

Otherwise present one row per proposal:

| File | Rule / entry | Reason |
|---|---|---|
[one row per Agent 2 / Agent 3 proposal — `file`, the rule or knowledge entry in one line, `reason`]

```
choices: ["Skip — report only (Recommended)", "Apply all", "Choose per proposal", "Cancel"]
```

- **Skip — report only** — apply nothing; every proposal's disposition is `proposed` for the Phase 5 report.
- **Apply all** — apply every proposal via the mechanism below; every proposal's disposition is `applied-uncommitted`.
- **Choose per proposal** — ask accept/decline for each proposal; apply the accepted ones (`applied-uncommitted`), leave the rest `declined`.
- **Cancel** — apply nothing; every proposal's disposition is `proposed`. Unlike every other "Cancel" in this command, **Cancel here does not abort the run**: direct mode never branches or commits the doc edits (Phase 3), so there is nothing upstream to unwind (still true — what still commits after this point is the terminal `commit-artifacts` step, bounded to `$SPECS_PATH`'s artifact paths per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1). Cancel only declines this phase's proposals; the run proceeds to Phase 5 and the Final Report is produced exactly as it would be after Skip.

**Apply mechanism.** For each accepted proposal, re-dispatch the agent that produced it — Agent 2 or Agent 3, same general-purpose agent as Phase 4, no new agent type — in apply mode, carrying its own proposal back verbatim:

> "Apply this proposed edit exactly as returned — do not re-derive it:
> `{file, anchor, replacement, reason}`: [paste the proposal]
>
> Locate `anchor` in `file` and write `replacement` in its place (or append it, if the proposal is an append). Return: file written, OR a mismatch note if `anchor` no longer matches the file's current content — do NOT guess at the intended location; skip and report the mismatch."

The edit lands on disk, uncommitted, alongside the rest of this run's changes — direct mode leaves the whole working tree for the user to review and commit manually.

Carry each proposal's `{file, reason, disposition}` into the Phase 5 report.

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
- [file, rule/entry summary, reason] — disposition: [proposed | applied-uncommitted | declined] OR "no update required"

### Instructions (Agent 3)
- [file, rule/entry summary, reason] — disposition: [proposed | applied-uncommitted | declined] OR "no update required"

### Maintenance applied (uncommitted)
[Every Phase 4.5 proposal with disposition `applied-uncommitted` — file, one-line summary, reason — one per line. Direct mode never commits the doc edits (the terminal `commit-artifacts` step stages only `$SPECS_PATH`'s bookkeeping paths), so these edits already sit in the same uncommitted working tree as the rest of this run's changes; listed separately so an accepted `CLAUDE.md` / knowledge-base edit doesn't get lost among the doc edits when you review before committing. OR "none".]

### Session learnings (Agent 4)
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Verification gates
| Gate | Outcome | Detail |
|---|---|---|
[One row per gate in the `gate_ledger` — direct mode registers three (`references/gate-ledger.md` §4). "Detail" carries the row's `ci_still_checks` (DEGRADED), `user_decision` (SKIPPED_BY_USER), or `precondition_unmet` (NOT_APPLICABLE); empty otherwise. When any row is DEGRADED or SKIPPED_BY_USER, follow the table with a one-line warning naming what CI will check that this run did not.]

### Assumptions & limitations
- [list any]

### Deferred items
- [anything the user asked to defer, OR validation failures the user accepted, OR "none"]

### Git state
The working tree has uncommitted changes. `/document` (direct mode) never commits your doc edits — you manage git manually. Run `git status` to review, then commit when ready. (This run's `$SPECS_PATH` session artifacts are committed separately — see the terminal step's outcome line at the end of the run.)
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
   `key` (`source = none`), so the phase degrades to report-only.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 5 report. This phase NEVER
fails the run, NEVER commits (still true — this phase only writes follow-up
files, and the user manages git manually for the doc edits; those writes are
committed by the separate terminal `commit-artifacts` step, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the docs repo or the current working directory.

---

## Phase 7 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 6 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /document (direct mode)`, `phase: documenting`,
`role: dev`, the run's `key` (usually `null` in direct mode) and `source`,
and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<PRD-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no PRD key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — the LAST action of the run. It
stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
`<KEY> Add dev-workflows session artifacts (/document)` — or `NOISSUE …`
when this doc-edit run resolved no key — and pushes per §4 step 5. It NEVER
writes into the docs repo this run just changed, NEVER touches a code repo,
anything outside `$SPECS_PATH`;
NEVER force-pushes; NEVER fails the run; and skips entirely when the run
carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Because
the Phase 5 report was composed before this phase, **print its §6 outcome
line here**, as the run's last output — prefixed `Specs repo:`, with
any guard notice repeated in full. No `resume.md` is written in this mode
(`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 skip list).

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable
(direct-mode doc edits remain uncommitted — the user manages git manually;
the terminal step above commits only the bounded session-artifact paths in
`$SPECS_PATH`), and NEVER writes into the docs repo or the current working
directory; no user name is ever written (§10 privacy).

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, key-not-found, cancellation)
- ALWAYS run Phase 3.5 (style check) after editing — `docs-style-checker` falls back to `prose-style-checker`; never skip style on tool-absence judgement
- NEVER create a git branch — this mode never branches. `specs-preflight` may switch `$SPECS_PATH` between branches that already exist, and only ones the plugin created (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2); it creates none.
- NEVER run tests (this command has no test phase)
- NEVER invoke Opus (no planning agent, no review agent — docs edits are always SIMPLE or MODERATE)
- NEVER commit the doc edits, or anything else in a docs/code repo or the current working directory — the user manages git manually there. The terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
- ALWAYS run `specs-preflight` in the shared `## Mode detection` section, before dispatching to either mode — so it runs for Mode B as well as Mode A — and `commit-artifacts` as the run's last action (per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`) — bounded to `$SPECS_PATH`'s artifact paths (§2.1) and to plugin-created branches (§2.2), always `git -C "$SPECS_PATH"` and never a `cd` (§1 rule 1), never force-pushing, and never failing the run
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
- IF the task reads as SIGNIFICANT / HIGH-RISK on inspection: redirect to `/document` (keyed mode) or `/epics` rather than proceeding under the simplified flow

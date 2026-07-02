---
name: epics
description: Jira-driven Epic-writing workflow. Reads a Value Increment and existing Epics from exported markdown, optionally scans code repos, drafts child Epic definitions, and gates on dt-style-checker and Opus epic-reviewer.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Draft child Epics for the Jira Value Increment: $ARGUMENTS

`/epics` is the **Jira-driven Epic-writing** workflow. Given a Value Increment key, it reads the VI plus its existing Epics from pre-exported markdown in the user's Obsidian vault, optionally scans code repos to identify reusable capabilities and gaps, drafts child Epic definitions as markdown files under the vault, and gates the result on an Opus review.

Key distinction from `/document` (Jira mode): the VI being Epic-ized is **not yet implemented** — there are no PRs to diff. Code scanning (when enabled) is a plain filesystem search to understand what exists and what needs to be built.

`/epics` **never branches** and **never commits**, and writes only to the resolved output directory — `jira-drafts/<jira_key>/` under `$VAULT_PATH`, or a derived `epic-drafts/<jira_key>/` dir beside the imported hierarchy when `$VAULT_PATH` is unset. Git hygiene of the write target is the user's responsibility — they may or may not have it under version control.

---

## Phase 0 — Load

1. **Resolve the Jira input via the shared front-end.** Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against
   `$ARGUMENTS`. `/epics` is **jira-driven only**: expect `mode: jira-driven`
   with `jira_key` (the input Value Increment key), `jira_export_root` (the VI
   export dir — `$VAULT_PATH/jira-products/<KEY>` for a JiraID, or the passed
   directory), and `source`. The front-end owns the `$VAULT_PATH` /
   `jira-products` validation and Fallbacks A/B. Carry `jira_key` and
   `jira_export_root` forward. Downstream, `<JIRA_KEY>` and `<VI-KEY>` both
   denote this `jira_key`.

   If the front-end returns `mode: direct` (no Jira input), stop with
   `EPICS_NEEDS_JIRA: /epics needs a Jira key or an imported-Jira directory.` —
   `/epics` has no direct-prompt behavior.

`/epics` is **cwd-agnostic**: it writes Epic drafts to an absolute output
directory (resolved in Phase 1), so it does **not** require cwd to be inside the
vault.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess. This rule is absolute.**

Group questions where possible; use `choices` arrays; the last choice in every array MUST be `"Other… (describe)"`.

Ask about:

- **Output directory.** One `.md` file per Epic, filename `<NEW-EPIC-SLUG>.md`
  (drafted Epics have no Jira ID yet, so they are slug-named files inside the
  VI-keyed folder). The default depends on `$VAULT_PATH`:
  - **`$VAULT_PATH` set** → `$VAULT_PATH/jira-drafts/<jira_key>/`. This lives
    **outside** `jira-products/` by design — `jira-products/` is re-created on
    every Jira import, so drafts written there would be lost; `jira-drafts/` is a
    sibling reserved for PM/PO work-in-progress that survives re-imports.
  - **`$VAULT_PATH` unset** (directory input) →
    `<parent-of-jira_export_root>/epic-drafts/<jira_key>/`. **Path-safety
    guard:** warn and offer another path if this dir would fall *inside*
    `jira_export_root` (wiped and regenerated on every import). A pre-existing
    dir that already holds drafts is normal — **not** a warning.
  The directory is auto-created if missing. Record `output_dir`, and record
  `project_root` = `$VAULT_PATH` when set, else `output_dir`. Ask:
  ```
  choices: ["Use <output_dir> (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```

- **Code examination on/off** (default ON). If ON, ask which repos under `$REPOS_PATH` to scan:
  ```
  choices: ["Scan repos referenced by sibling/parent Epics under this VI (Recommended — auto-derived)", "Let me list the repos manually (you'll be prompted)", "Turn code scan off — produce Epic drafts from Jira content alone", "Other… (describe)"]
  ```
  When "auto-derived" is chosen, inspect the sibling/parent Epics' `## Pull Requests` sections (if any) for repo references; if none, fall back to asking the user to list repos.

- **Repo refresh policy** (only if code scan is ON):
  ```
  choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh", "Other… (describe)"]
  ```
  The `fetch + pull default branch` default matches `code-scanner`'s default (`refresh.switch_to_default_branch: true, refresh.pull: true`) — capability scans target present-day code and want the default-branch tip. This is deliberately different from `/document` (Jira mode), which keeps `pull: false` because historical merged commits must not move.

- **Repos search base (`$REPOS_PATH`)** (only if code scan is ON). Read `${REPOS_PATH:-/workspace}` (the container mounts every repo under `/workspace`). `$REPOS_PATH` may be a single directory or a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input (single dir or colon-separated list) and validate that at least one directory exists under it. Record the resolved value as `$REPOS_PATH`. Individual clones are located in Phase 4 by matching their `git remote` against each repo slug — not by assuming a `<base>/<slug>` directory name.

Also display (for user context):
- Resolved cwd absolute path
- Resolved output directory
- Resolved `$REPOS_PATH` (or "N/A — code scan off")
- Resolved `jira_export_root` and `jira_key` (plus `$VAULT_PATH` when set)

No branching context is shown — this command never branches.

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of: `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK`. Epic writing is typically **MODERATE** (bounded scope, single VI, vault-internal output). State the classification and a one-sentence reason.

MODERATE → no separate Opus planner; the `epic-reviewer` gate (Opus, frontmatter-pinned) is mandatory. Resolve the per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-4-6, fallback claude-sonnet-4-5>   # jira-reader, code-scanner, dt-style-checker, doc-fixer, epic-writer (MODERATE)
  review_model:    <§2 Opus chain>     # epic-reviewer (frontmatter-pinned; recorded, no override)
  implementation_model: <= detection_model>   # the epic-writer subagent (Phase 6); planning_model if SIGNIFICANT/HIGH-RISK
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

Each subagent dispatch below cites its chain (§9 role→chain map). **No relaunch advisory** for MODERATE — the writer runs on its detection pin and the gates run on `current_model`, which §3.1 allows (if a run is classified SIGNIFICANT/HIGH-RISK, the §9.1 advisory applies and `epic-writer` escalates to the §2 chain). If no Opus is available, `epic-reviewer` falls to the Sonnet floor — record the degradation in `notes` and the Phase 9 report.

---

## Phase 2 — Plan + approval

Present a concise plan:

- Resolved `jira_key` and the `jira_export_root` path
- Existing Epics identified under this VI (will NOT be duplicated)
- Repos to scan (or "code scan off")
- Output directory with one file per new Epic; propose a name stub per Epic if the themes already suggest them
- Parallelism plan (up to 4 `code-scanner` instances per batch, single Agent message per batch)

Ask:
```
"Epic drafting plan ready. What would you like to do?"
choices: ["Approve & continue (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → proceed to Phase 3
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarise what was planned

---

## Phase 3 — Read Jira hierarchy

Invoke `jira-reader` with `depth: vi-plus-epics`. This depth is specifically designed for Epic writing: richer than `vi-only` so themes extracted for `code-scanner` aren't starved of context, but lighter than `full` so the agent doesn't read dozens of already-closed child Stories.

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
  > depth:      vi-plus-epics"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On `OK`, identify the Epics already linked to the VI (filter `linked_items` to `type == Epic`) — the new Epic drafts MUST NOT duplicate their scope (enforced later by `epic-reviewer`).

---

## Phase 4 — Resolve repos (conditional)

If code scan is OFF, skip to Phase 6.

If code scan is ON:

1. Derive the repo list:
   - **Auto-derived** (Phase 1 default) — walk the `jira-reader` `linked_items` filtered to `type == Epic`; for each Epic `.md` file (already read during Phase 3), collect repo names from its `## Pull Requests` section URLs. Dedupe. If the auto-derived list is empty, fall back to asking the user.
   - **Manual list** — prompt for a free-text list of repo short names (one per line or space-separated). Resolve each against the `$REPOS_PATH` slug→clone map built in step 2 below.

2. Build a slug→clone map. For each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote` call fails/times out. Resolve each in-scope repo slug against the map: one match → use it; multiple matches → auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last (show candidates at plan approval); zero matches → escalate per the `Repo unresolved (zero matches) — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
   ```

3. If the final resolved repo list is empty (every repo was skipped or missing), escalate per the `No repos derivable — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["List repos to scan manually", "Proceed without code scan", "Cancel", "Other… (describe)"]
   ```

---

## Phase 5 — Parallel code scanning (conditional)

If code scan is OFF, skip to Phase 6.

Spawn `code-scanner` instances in **batches of up to 4 concurrent agents** per Agent message. Wait for each batch before spawning the next.

For each repo in the batch:

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 4>
  > repo_url_slug: <repo slug, e.g. "cluster">
  > capability_themes:
  >   [paste the themes array from jira-reader, plus any VI-goal-derived themes]
  > context: |
  >   [3–5 sentences: VI goal, what the Epic-set is meant to achieve]
  > search_hints:
  >   symbols:  [class/function names inferred from VI/Epic descriptions, or []]
  >   paths:    [directory globs inferred from themes, or []]
  >   keywords: [grep keywords extracted from themes]
  > refresh:
  >   switch_to_default_branch: [true if Phase 1 chose 'fetch + pull default branch' (default) or 'fetch only'; false if 'no refresh']
  >   pull: [true if 'fetch + pull default branch'; false otherwise]"

Handle per-repo status after the batch returns:

- `OK` / `PARTIAL` / `EMPTY` — store the output, continue.
- `REPO_MISSING` — should not happen at this stage (Phase 4 already checked). If it does, escalate per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `DIRTY_TREE` — escalate:
  ```
  choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]
  ```
- `REFRESH_BLOCKED` — escalate:
  ```
  choices: ["Continue with current local state", "Skip this repo", "Cancel"]
  ```

---

## Phase 6 — Write Epics

The drafting is delegated to the **`epic-writer`** subagent (pinned to the §2.1 Sonnet detection chain for MODERATE; §2 Opus only if the run is SIGNIFICANT/HIGH-RISK — see `classification.md` §9.2). The orchestrator prepares a handoff and dispatches; it does not write Epics itself, and **nothing commits** (epics never branches/commits — vault git is the user's responsibility).

1. **Write the handoff file.** Create a temp file (`mktemp` — never the vault, never a repo) containing the `epic-writer` input contract: `jira_reader_handoff`, `code_scanner_outputs` (empty if no scan), `scope` (Phase 2 in/out of scope), `existing_epics` (non-duplication), `output_dir` (resolved Phase 1 dir), `vi_goal`, `jira_key`. Record its absolute path.

2. **Dispatch the writer:**

→ Agent (subagent_type: "dev-workflows:epic-writer", model: `<detection_model — §9 / §2.1 Sonnet chain; planning_model (§2 Opus) only if classification is SIGNIFICANT/HIGH-RISK>`):
  > "Write the child Epic definitions for this brief.
  >
  > handoff_file: [absolute path of the temp handoff file from step 1]"

3. **Handle the return.** `status: DONE` → record `files_written` for Phase 6.1 onward. `status: BLOCKED` → surface the named gap:
   ```
   choices: ["Provide the missing input (you'll be prompted)", "Cancel"]
   ```
   On a provided value, rewrite the handoff and re-dispatch once. Nothing is committed (vault git is the user's responsibility).

---

## Phase 6.1 — Dynatrace style check

Invoke `dt-style-checker` on the files written in Phase 6. Unlike `/document` (Jira mode), this does NOT use `docs-style-checker` (no repo linter for vault content). Instead, the Dynatrace corporate style guide checker validates terminology, trademarks, voice/tone, and inclusive language.

→ Agent (subagent_type: "dt-style-guide:dt-style-checker", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > files:    [absolute paths of every Epic file written in Phase 6]
  > doc_type: epic"

Act on the return:

- **`status: OK`** — zero violations. Proceed to Phase 7.
- **`status: VIOLATIONS_FOUND`** — invoke `doc-fixer` with the violations treated as per their severity. After `doc-fixer` completes, re-run `dt-style-checker` once:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the style violations for this brief:
    >
    > Task description: [Epic drafting for <JIRA_KEY>]
    > Reviewer or style-checker output: [paste full dt-style-checker output]
    > Project root: [resolved project_root]
    > Severities to fix: MAJOR only"

  If violations remain after the re-run, proceed to Phase 7 — the remaining findings (mostly MINOR/NIT for epics) are informational and will appear in the Phase 9 report.

- **`status: ERROR`** — surface the error reason. Proceed to Phase 7 regardless (style check is not a gate for Epics, but a quality enhancement).

If `dt-style-checker` is unavailable (agent file not found), proceed directly to Phase 7. The style check is optional but recommended.

---

## Phase 7 — Epic review gate

Invoke `epic-reviewer` (Opus). This reviewer is Epic-specific — scope clarity, acceptance-criteria testability, non-duplication of existing Epics. `docs-style-checker` is NOT used here (no repo linter for vault content); Dynatrace corporate style is handled by the Phase 6.1 `dt-style-checker` step above.

→ Agent (subagent_type: "dev-workflows:epic-reviewer"):
  > "Review the Epic drafts for this brief:
  >
  > Task description: [one-paragraph: VI key, VI goal, number of Epics drafted]
  > Written Epic file paths: [absolute paths of every Epic file written in Phase 6]
  > jira-reader handoff: [paste full YAML from Phase 3]
  > code-scanner output:  [paste array of per-repo scanner outputs from Phase 5, or 'N/A — code scan off']"

Act on the verdict (same shape as `/document` Jira mode Phase 7):

- **BLOCK** — invoke `doc-fixer` with `Severities to fix: BLOCKER and MAJOR`. Re-invoke `epic-reviewer` once. If still BLOCK, escalate per the `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER individually:
  ```
  choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run", "Other… (describe)"]
  ```
  For `/epics`, "Defer" means the finding goes into an Epic-refinement note in the draft itself (appended as a `## Refinement notes` section) in addition to the Phase 9 report.

- **PASS WITH RECOMMENDATIONS** — invoke `doc-fixer` for MAJOR findings only:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the review findings for this brief:
    >
    > Task description: [Epic drafting for <JIRA_KEY>]
    > Reviewer or style-checker output: [paste full epic-reviewer output]
    > Project root: [resolved project_root]
    > Severities to fix: BLOCKER and MAJOR"

  MINOR / NIT findings are deferred to the Phase 9 report.

- **PASS** — proceed to Phase 8.

Cap: one fix cycle + one re-review maximum.

---

## Phase 8 — Post-write maintenance

First gather the change context:

a. `project_root` (the vault when `$VAULT_PATH` is set, else the resolved output directory) is the "project root" for this run. Run `git diff --stat` from `project_root` if it is a git repo; otherwise list the written files manually. This command never commits — just report what changed.
b. Compose a **change summary block**:

```
Implementation: [one-sentence description: how many Epics drafted for <JIRA_KEY>, resolved output directory]
Change type: docs
Classification: MODERATE
Files changed:
<list of new Epic file paths, one per line>
Notable additions/removals: [new Epics by slug — one line each]
Epic-review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
```

Then spawn all four maintenance agents in a **single Agent message**. They are independent and run concurrently.

**Agent 1 — Documentation** (general-purpose):
> "Post-write documentation review. Change summary:
> [paste change summary block]
>
> The project root is an Obsidian vault; look only for vault-internal documentation files that reference Epic drafts (e.g., a `jira-drafts/README.md` or an index page enumerating active drafts).
> Determine if any such file needs updating — e.g., a new entry in a drafts index.
> Skip if: no such file exists or drafts aren't indexed centrally.
> If an update is warranted: apply minimal edits.
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose):
> "Post-write knowledge review. Change summary:
> [paste change summary block]
>
> Check ~/.claude/memory/ (global) and .claude/memory/ (project-level, preferred for vault-specific knowledge) for existing knowledge files.
> Determine if a new knowledge entry is warranted — look for: reusable insights about this VI-family's Epic patterns, non-obvious scoping constraints uncovered, code-reuse discoveries from code-scanner, duplicate-Epic near-misses that required scope adjustment.
> If YES: append to the most appropriate existing file (never create a new file if an existing one fits) using this format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the Jira key + VI summary]
> Return: file updated/created and summary of entry, OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-write instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any Epic-drafting rules, guidance, or guardrails are missing because of what this run revealed (e.g., a domain-specific acceptance-criteria pattern, a naming convention for Epic files, a scope-boundary rule that caught you out).
> Skip if: the run followed existing conventions with no surprises.
> If YES: apply minimal, additive, scoped changes only.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance):
> "Analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /epics
> - What was done: [one-paragraph summary of Epics drafted]
> - Key events: [BLOCK reviews and their reason, DIRTY_TREE / REFRESH_BLOCKED scanner statuses, duplicate-Epic near-misses, missing repos, user override decisions — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
> - Test result: N/A (no tests in /epics)
> - Project root: [resolved project_root]"

Collect all four summaries for the Phase 9 report.

---

## Phase 9 — Final Report

Output a structured report — do NOT ask any closing confirmation:

```
## Jira-driven Epic Drafting Report

### Classification
MODERATE — vault-internal Epic drafting for a single VI

### Model Routing
- Session model (current_model): [model]
- epic-writer (implementation_model): [model] — detection (MODERATE) | reasoning (SIGNIFICANT)
- Detection steps — jira-reader, code-scanner, dt-style-checker, doc-fixer (detection_model): [model]
- epic-reviewer (review_model): [model]
- Opus available: [yes | no]

### VI summary
- Key: <JIRA_KEY>
- Summary: [VI summary, 1 line]
- Goal: [2–3 sentence extraction from jira-reader]

### Existing Epics (not duplicated)
- [<KEY>] [summary] — [status]
- ...
- _or_ "none"

### New Epics written
- [absolute path] — [1-line Epic summary]
- ...

### Repos scanned
- <repo-1> (<resolved repo_path>) — [status: OK | PARTIAL | EMPTY | DIRTY_TREE | REFRESH_BLOCKED; N themes classified present, M partial, K absent, E error]
- ...
- _or_ "N/A — code scan off"

### Epic review verdict
[PASS | PASS WITH RECOMMENDATIONS | BLOCK] — [1-line summary of findings applied / deferred]

### Dynatrace style check (Phase 6.1)
[OK | VIOLATIONS_FOUND (N fixed, M remaining) | ERROR (reason) | SKIPPED (dt-style-checker unavailable)] — [1-line summary]

### Documentation (Agent 1)
- [file updated] — [what was added/changed] OR "no update required (reason)"

### Knowledge base (Agent 2)
- [file updated/created] — [summary of entry] OR "no update required"

### Instructions (Agent 3)
- [summary of change] OR "no update required"

### Session learnings (Agent 4)
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Deferred items
[MINOR / NIT findings that were not applied, OR epic-reviewer BLOCK findings that were overridden / deferred with the ## Refinement notes section appended — one line each; or "none"]

### Assumptions & limitations
- [list any]

### Git state
The vault has uncommitted changes. `/epics` never commits — vault git management is your responsibility.
```

---

## Invariants (always enforced)

- ALWAYS resolve input via the shared Jira-input front-end (Phase 0) — a JiraID requires `$VAULT_PATH`; an imported-Jira directory works without it; `/epics` is cwd-agnostic and rejects `mode: direct`
- NEVER create a git branch (this command never branches)
- NEVER commit (vault git management is the user's responsibility)
- NEVER write inside `jira-products/` — re-created on every import; writes would be lost
- NEVER write inside `_archive/` — read-only by convention
- NEVER write inside `jira_export_root` — it is re-created on every Jira import, so drafts there would be lost (the Phase 1 path-safety guard enforces this for the derived `epic-drafts/` default)
- ALWAYS write to the resolved `output_dir` — `$VAULT_PATH/jira-drafts/<jira_key>/` when `$VAULT_PATH` is set, else `<parent-of-jira_export_root>/epic-drafts/<jira_key>/` (or the user-confirmed alternative) — auto-create the directory if missing
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS invoke `epic-reviewer` before Phase 8 maintenance
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin each subagent dispatch to its §9 chain via `model:` — the mechanical steps (`jira-reader`, `code-scanner`, `dt-style-checker`, `doc-fixer`) and `epic-writer` (MODERATE) to the §2.1 Sonnet chain; `epic-reviewer` keeps its frontmatter Opus pin (no override); coordination + interactive gates run on `current_model`
- ALWAYS delegate Phase 6 writing to the `epic-writer` subagent (write-only); the orchestrator never writes Epics itself and never commits (vault git is the user's responsibility)
- ALWAYS cap review/fix cycles: 1 fix + 1 re-review max
- ALWAYS pass `Change type: docs` in the Phase 8 change summary block
- ALWAYS pass `Command run: /epics` in the Phase 8 Agent 4 session handoff
- ALWAYS spawn Phase 8 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 9 report as the final output
- ALL written claims must be traceable to Jira keys (from `jira-reader`) or code paths (from `code-scanner`); do not invent content the sources don't contain
- NEVER run `docs-style-checker` — Epic drafts are vault-internal and not subject to product-docs prose linting. Dynatrace corporate style is checked via `dt-style-checker` in Phase 6.1 instead.

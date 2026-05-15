---
name: impl:jira:epics
description: Jira-driven Epic-writing workflow. Reads a Value Increment and existing Epics from exported markdown, optionally scans code repos, drafts child Epic definitions, and gates on dt-style-checker and Opus epic-reviewer.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Draft child Epics for the Jira Value Increment: $ARGUMENTS

`/impl:jira:epics` is the **Jira-driven Epic-writing** workflow. Given a Value Increment key, it reads the VI plus its existing Epics from pre-exported markdown in the user's Obsidian vault, optionally scans code repos to identify reusable capabilities and gaps, drafts child Epic definitions as markdown files under the vault, and gates the result on an Opus review.

Key distinction from `/impl:jira:docs`: the VI being Epic-ized is **not yet implemented** — there are no PRs to diff. Code scanning (when enabled) is a plain filesystem search to understand what exists and what needs to be built.

`/impl:jira:epics` **never branches**, **never commits**, and only writes inside `$VAULT_PATH`. Vault git hygiene is the user's responsibility — they may or may not have the vault under version control.

Reference: model-routing rules live at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md`. The classification step below follows that file verbatim. The Opus gate (`epic-reviewer`) is independent of the four-level classification.

---

## Phase 0 — Load

1. **Resolve `$VAULT_PATH`.** Read the `VAULT_PATH` environment variable. If unset, ask:
   ```
   choices: ["Set to detected path (Recommended)", "Enter manually", "Cancel"]
   ```
   Validate the resolved path exists and contains a `jira-products/` subdirectory. If not, stop with an error.

2. **Require vault context.** This command writes Epic drafts into the user's Obsidian vault; running it outside the vault would produce files in the wrong place. Verify cwd is inside `$VAULT_PATH` (cwd starts with the resolved `$VAULT_PATH` prefix, case-sensitive). If not:
   ```
   choices: ["Cancel and re-run after `cd <VAULT_PATH>`", "Cancel"]
   ```
   Both choices end the current run — the command cannot `cd` for the user safely across shells. The first choice emits a `cd "$VAULT_PATH"` instruction for the user to copy-paste. Default = Cancel.

3. **Resolve `<JIRA_KEY>`** from `$ARGUMENTS`. Validate that `$VAULT_PATH/jira-products/<JIRA_KEY>/` exists. If not, stop with an error naming the missing directory.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess. This rule is absolute.**

Group questions where possible; use `choices` arrays; the last choice in every array MUST be `"Other… (describe)"`.

Ask about:

- **Output directory** (default: `$VAULT_PATH/jira-drafts/<VI-KEY>/`; one `.md` file per Epic, filename `<NEW-EPIC-SLUG>.md`). This path lives **outside** `jira-products/` by design — `jira-products/` is re-created from scratch on every Jira import, so any Epic drafts written there would be lost. `jira-drafts/` is a sibling directory reserved for PM/PO work-in-progress that survives re-imports. The directory is auto-created if missing.
  ```
  choices: ["Use $VAULT_PATH/jira-drafts/<JIRA_KEY>/ (Recommended)", "Use a different path under $VAULT_PATH (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```

- **Code examination on/off** (default ON). If ON, ask which repos under `<repos_base>` to scan:
  ```
  choices: ["Scan repos referenced by sibling/parent Epics under this VI (Recommended — auto-derived)", "Let me list the repos manually (you'll be prompted)", "Turn code scan off — produce Epic drafts from Jira content alone", "Other… (describe)"]
  ```
  When "auto-derived" is chosen, inspect the sibling/parent Epics' `## Pull Requests` sections (if any) for repo references; if none, fall back to asking the user to list repos.

- **Repo refresh policy** (only if code scan is ON):
  ```
  choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh", "Other… (describe)"]
  ```
  The `fetch + pull default branch` default matches `code-scanner`'s default (`refresh.switch_to_default_branch: true, refresh.pull: true`) — capability scans target present-day code and want the default-branch tip. This is deliberately different from `/impl:jira:docs`, which keeps `pull: false` because historical merged commits must not move.

- **Repos base path** (only if code scan is ON). Detect `/repos` first. Ask:
  ```
  choices: ["Use /repos (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input and validate that at least one directory exists under it. Record the resolved path as `<repos_base>`.

Also display (for user context):
- Resolved cwd absolute path
- Resolved output directory
- Resolved `<repos_base>` (or "N/A — code scan off")
- Resolved `$VAULT_PATH` and `<JIRA_KEY>`

No branching context is shown — this command never branches.

---

## Phase 1.5 — Classify

Epic writing is typically **MODERATE** (bounded scope, single VI, vault-internal output). State the classification and a one-sentence reason.

MODERATE → no Opus planning; `epic-reviewer` gate is mandatory.

---

## Phase 2 — Plan + approval

Present a concise plan:

- Resolved `<JIRA_KEY>` and the `$VAULT_PATH/jira-products/<JIRA_KEY>/` path
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

→ Agent (subagent_type: "general-purpose"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/jira-reader.md`
  > (fall back to `~/.claude/agents/jira-reader.md` if installed at user level).
  > Then return the structured handoff for this brief:
  >
  > vault_path: [resolved $VAULT_PATH]
  > jira_key:   [resolved <JIRA_KEY>]
  > depth:      vi-plus-epics"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the §15 `Jira key dir not found` choices (`["Re-enter key", "Cancel"]`). On `OK`, identify the Epics already linked to the VI (filter `linked_items` to `type == Epic`) — the new Epic drafts MUST NOT duplicate their scope (enforced later by `epic-reviewer`).

---

## Phase 4 — Resolve repos (conditional)

If code scan is OFF, skip to Phase 6.

If code scan is ON:

1. Derive the repo list:
   - **Auto-derived** (Phase 1 default) — walk the `jira-reader` `linked_items` filtered to `type == Epic`; for each Epic `.md` file (already read during Phase 3), collect repo names from its `## Pull Requests` section URLs. Dedupe. If the auto-derived list is empty, fall back to asking the user.
   - **Manual list** — prompt for a free-text list of repo short names (one per line or space-separated). Validate each is a directory under `<repos_base>`.

2. For each resolved repo, check `<repos_base>/<repo>` exists. Escalate missing repos per §15:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Use different /repos path", "Other… (describe)"]
   ```

3. If the final resolved repo list is empty (every repo was skipped or missing), escalate per §15 "Use case B with no repos derivable":
   ```
   choices: ["List repos to scan manually", "Proceed without code scan", "Cancel", "Other… (describe)"]
   ```

---

## Phase 5 — Parallel code scanning (conditional)

If code scan is OFF, skip to Phase 6.

Spawn `code-scanner` instances in **batches of up to 4 concurrent agents** per Agent message. Wait for each batch before spawning the next.

For each repo in the batch:

→ Agent (subagent_type: "general-purpose"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/code-scanner.md`
  > (fall back to `~/.claude/agents/code-scanner.md` if installed at user level).
  > Then scan this repo for the brief:
  >
  > repo_path:   <repos_base>/<repo>
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
- `REPO_MISSING` — should not happen at this stage (Phase 4 already checked). If it does, escalate per §15.
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

The main command drafts child Epic definitions — one file per Epic — following the `jira-reader` handoff and (when code scan ran) the `code-scanner` outputs. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5 already loaded.

For each new Epic, emit a markdown file under the resolved output directory (default `$VAULT_PATH/jira-drafts/<JIRA_KEY>/<NEW-EPIC-SLUG>.md`):

```markdown
# <Epic title>

## Goal
<one sentence, tied concretely to the parent VI's outcome>

## Business value
<1–2 sentences linking the Epic to the VI's outcome>

## Scope

### In scope
- <concretely delimited features/behaviours/surfaces>
- ...

### Out of scope
- <concrete — not "anything else" or "future work">
- ...

## Acceptance criteria
- <testable; each has an observable pass/fail signal — a user action + expected system response, a measurable threshold, a reproducible test case>
- ...

## Dependencies
- <other Epics under this VI or elsewhere, repos, teams, external systems — named>
- ...

## Suggested stories
- <high-level breakdown; each story plausibly pickup-ready without further scoping>
- ...

## References
- Parent VI: [[<JIRA_KEY>]]
- <code paths from code-scanner evidence, when relevant — especially classification: present or partial anchors>
- ...
```

Create the output directory if missing (`mkdir -p`). Write every Epic file before proceeding to Phase 6.7.

Traceability: every claim in each Epic must be traceable to the `jira-reader` handoff (Jira key + which item type — VI goal, existing Epic summary, Story theme) or a `code-scanner` output (`evidence.path` + symbols). Do not invent content the sources don't contain.

**Write restrictions** (enforced by invariants):
- NEVER write inside `jira-products/` — re-created on every import.
- NEVER write inside `_archive/` — read-only by convention.
- NEVER write outside `$VAULT_PATH`.
- ALWAYS write inside the resolved output directory from Phase 1 (default `jira-drafts/<VI-KEY>/`).

---

## Phase 6.7 — Dynatrace style check

Invoke `dt-style-checker` on the files written in Phase 6. Unlike `/impl:jira:docs`, this does NOT use `docs-style-checker` (no repo linter for vault content). Instead, the Dynatrace corporate style guide checker validates terminology, trademarks, voice/tone, and inclusive language.

→ Agent (subagent_type: "general-purpose"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dt-style-guide@ihudak-claude-plugins/agents/dt-style-checker.md`
  > (fall back to `~/.claude/agents/dt-style-checker.md` if installed at user level).
  > Then run the style check for this brief:
  >
  > files:    [absolute paths of every Epic file written in Phase 6]
  > doc_type: epic"

Act on the return:

- **`status: OK`** — zero violations. Proceed to Phase 7.
- **`status: VIOLATIONS_FOUND`** — invoke `doc-fixer` with the violations treated as per their severity. After `doc-fixer` completes, re-run `dt-style-checker` once:

  → Agent (subagent_type: "general-purpose"):
    > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/doc-fixer.md`
    > (fall back to `~/.claude/agents/doc-fixer.md` if installed at user level).
    > Then fix the style violations for this brief:
    >
    > Task description: [Epic drafting for <JIRA_KEY>]
    > Reviewer or style-checker output: [paste full dt-style-checker output]
    > Project root: [resolved $VAULT_PATH]
    > Severities to fix: MAJOR only"

  If violations remain after the re-run, proceed to Phase 7 — the remaining findings (mostly MINOR/NIT for epics) are informational and will appear in the Phase 9 report.

- **`status: ERROR`** — surface the error reason. Proceed to Phase 7 regardless (style check is not a gate for Epics, but a quality enhancement).

If `dt-style-checker` is unavailable (agent file not found), proceed directly to Phase 7. The style check is optional but recommended.

---

## Phase 7 — Epic review gate

Invoke `epic-reviewer` (Opus). This reviewer is Epic-specific — scope clarity, acceptance-criteria testability, non-duplication of existing Epics. `docs-style-checker` is NOT used here (no repo linter for vault content); Dynatrace corporate style is handled by the Phase 6.7 `dt-style-checker` step above.

→ Agent (subagent_type: "general-purpose", model: "opus"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/epic-reviewer.md`
  > (fall back to `~/.claude/agents/epic-reviewer.md` if installed at user level).
  > Then review the Epic drafts for this brief:
  >
  > Task description: [one-paragraph: VI key, VI goal, number of Epics drafted]
  > Written Epic file paths: [absolute paths of every Epic file written in Phase 6]
  > jira-reader handoff: [paste full YAML from Phase 3]
  > code-scanner output:  [paste array of per-repo scanner outputs from Phase 5, or 'N/A — code scan off']"

Act on the verdict (same shape as `/impl:jira:docs` Phase 7):

- **BLOCK** — invoke `doc-fixer` with `Severities to fix: BLOCKER and MAJOR`. Re-invoke `epic-reviewer` once. If still BLOCK, escalate per §15 for each unresolved BLOCKER individually:
  ```
  choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run", "Other… (describe)"]
  ```
  For `/impl:jira:epics`, "Defer" means the finding goes into an Epic-refinement note in the draft itself (appended as a `## Refinement notes` section) in addition to the Phase 9 report.

- **PASS WITH RECOMMENDATIONS** — invoke `doc-fixer` for MAJOR findings only:

  → Agent (subagent_type: "general-purpose"):
    > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/doc-fixer.md`
    > (fall back to `~/.claude/agents/doc-fixer.md` if installed at user level).
    > Then fix the review findings for this brief:
    >
    > Task description: [Epic drafting for <JIRA_KEY>]
    > Reviewer or style-checker output: [paste full epic-reviewer output]
    > Project root: [resolved $VAULT_PATH]
    > Severities to fix: BLOCKER and MAJOR"

  MINOR / NIT findings are deferred to the Phase 9 report.

- **PASS** — proceed to Phase 8.

Cap: one fix cycle + one re-review maximum.

---

## Phase 8 — Post-write maintenance

First gather the change context:

a. The vault is the "project root" for this run. Run `git diff --stat` from `$VAULT_PATH` if the vault is a git repo; otherwise list the written files manually. This command never commits — just report what changed.
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

**Agent 4 — Session maintenance** (general-purpose):
> "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/impl-maintenance.md`
> (fall back to `~/.claude/agents/impl-maintenance.md` if installed at user level).
> Then analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /impl:jira:epics
> - What was done: [one-paragraph summary of Epics drafted]
> - Key events: [BLOCK reviews and their reason, DIRTY_TREE / REFRESH_BLOCKED scanner statuses, duplicate-Epic near-misses, missing repos, user override decisions — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
> - Test result: N/A (no tests in /impl:jira:epics)
> - Project root: [resolved $VAULT_PATH]"

Collect all four summaries for the Phase 9 report.

---

## Phase 9 — Final Report

Output a structured report — do NOT ask any closing confirmation:

```
## Jira-driven Epic Drafting Report

### Classification
MODERATE — vault-internal Epic drafting for a single VI

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
- <repos_base>/<repo-1> — [status: OK | PARTIAL | EMPTY | DIRTY_TREE | REFRESH_BLOCKED; N themes classified present, M partial, K absent, E error]
- ...
- _or_ "N/A — code scan off"

### Epic review verdict
[PASS | PASS WITH RECOMMENDATIONS | BLOCK] — [1-line summary of findings applied / deferred]

### Dynatrace style check (Phase 6.7)
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
The vault has uncommitted changes. `/impl:jira:epics` never commits — vault git management is your responsibility.
```

---

## Invariants (always enforced)

- ALWAYS run Phase 0 vault check — refuse to run outside `$VAULT_PATH`
- NEVER create a git branch (this command never branches)
- NEVER commit (vault git management is the user's responsibility)
- NEVER write inside `jira-products/` — re-created on every import; writes would be lost
- NEVER write inside `_archive/` — read-only by convention
- NEVER write outside `$VAULT_PATH`
- ALWAYS write to `jira-drafts/<JIRA_KEY>/` (or the user-confirmed alternative under `$VAULT_PATH`) — auto-create the directory if missing
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS invoke `epic-reviewer` before Phase 8 maintenance
- ALWAYS cap review/fix cycles: 1 fix + 1 re-review max
- ALWAYS pass `Change type: docs` in the Phase 8 change summary block
- ALWAYS pass `Command run: /impl:jira:epics` in the Phase 8 Agent 4 session handoff
- ALWAYS spawn Phase 8 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 9 report as the final output
- ALL written claims must be traceable to Jira keys (from `jira-reader`) or code paths (from `code-scanner`); do not invent content the sources don't contain
- NEVER run `docs-style-checker` — Epic drafts are vault-internal and not subject to product-docs prose linting. Dynatrace corporate style is checked via `dt-style-checker` in Phase 6.7 instead.

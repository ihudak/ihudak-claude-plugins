# `/impl:jira:release-notes` Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone `/impl:jira:release-notes` command that drafts a dynatrace-docs release-notes body for a Jira VI/ticket (optionally grounded in PR diffs), gated by a light style check, written to a persistent destination to paste into Jira.

**Architecture:** A new orchestrator command + one bounded `release-notes-writer` agent, reusing `jira-reader`, `diff-summarizer` (optional, via the `$REPOS_PATH` resolution added in 1.5.0), and `dt-style-checker`/`dt-doc-fixer` (optional). A targeted correction stops the docs flow from treating release notes as a repo write target. The draft is the **authored body only** (`{{#context}}` label + `### title` + customer-facing prose) — no `{{#internal-note}}`, no Jira IDs, no PR links; the docs team's Jira automation adds the metadata wrapper.

**Tech Stack:** Markdown plugin content (command + agent + handoff reference), one Bash hook regex edit, JSON manifests. No unit-test framework — verification is `grep` assertions, JSON validity, and a structural smoke check against the real PRODUCT-14902 export (which is release-notes-worthy).

**Spec:** `docs/superpowers/specs/2026-06-16-jira-release-notes-command-design.md`

---

## File Structure

| File | Responsibility |
|---|---|
| `plugins/dev-workflows/references/handoff/release-notes-writer.md` (new) | Input/output contract for the agent (defined first) |
| `plugins/dev-workflows/agents/release-notes-writer.md` (new) | Renders the authored release-notes body from the jira-reader handoff + optional diffs |
| `plugins/dev-workflows/commands/impl/jira/release-notes.md` (new) | Orchestrator command |
| `plugins/dev-workflows/hooks/preload-context.sh` (edit) | Widen the command-token regex to match `release-notes` |
| `plugins/dev-workflows/agents/doc-planner.md` (edit) | Stop proposing release-notes as a doc target |
| `plugins/dev-workflows/agents/doc-location-finder.md` (edit) | Same |
| `plugins/dev-workflows/commands/impl/jira/docs.md` (edit) | Defer release notes to the new command |
| `plugins/dev-workflows/README.md`, `CLAUDE.md` (edit) | Command list, workflow map, invariants |
| `plugins/dev-workflows/CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (edit) | 1.6.0 release bookkeeping |

---

## Task 0: Prerequisite — land the staging fix first, rebase this branch

The `fix/persistent-screenshot-staging` branch (dev-workflows 1.5.1) edits `agents/doc-planner.md`, which Task 5 also edits. Land it first so versions and `doc-planner.md` are coherent.

- [ ] **Step 1: Confirm whether the staging fix is merged to `main`**

```bash
cd /workspace/ihudak-claude-plugins
git log --oneline main | grep -q "persist cdn screenshot staging" && echo "ALREADY MERGED" || echo "NOT MERGED"
```

- [ ] **Step 2: If NOT merged, merge it and rebase this feature branch**

```bash
cd /workspace/ihudak-claude-plugins
git checkout main && git merge --ff-only fix/persistent-screenshot-staging
git checkout feat/jira-release-notes-command && git rebase main
grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json   # expect 1.5.1 now
```

Expected: `plugin.json` shows `1.5.1` after rebase. If the human has not yet approved merging the staging fix, STOP and surface this — do not proceed (Task 7 bumps from 1.5.1 → 1.6.0).

---

## Task 1: Handoff reference for `release-notes-writer`

**Files:**
- Create: `plugins/dev-workflows/references/handoff/release-notes-writer.md`

- [ ] **Step 1: Create the handoff reference**

```markdown
# release-notes-writer Handoff Format

## Input

```yaml
jira_reader_handoff: <full YAML from jira-reader; see agents/jira-reader.md output schema>
diff_summaries:      <optional array of diff-summarizer outputs; one entry per repo; omit when diff-grounding is off>
release_versions:    [<parsed version strings, e.g. "Managed (344)", "SaaS (344)">]   # derived by the command from release_versions frontmatter; [] when none declared
context_label_hint:  <optional 1–2 short category labels the user suggested; null otherwise>
model_routing:
  classification: MODERATE
  reason: <from orchestrator>
  current_model: <model name>
  planning_model: n/a
  review_model: n/a
  implementation_model: <model name>
  opus_available: true | false
  gate_tests_on_review: false
```

Refuse to run without `jira_reader_handoff`. When `release_versions` is `[]`, emit a single undated entry and flag it in `gaps`.

## Output

```yaml
status: OK | PARTIAL

release_notes_block:
  target_format: dynatrace-docs-release-notes-v1
  entries:
    - release_version: <e.g. "Managed (344)" | "(unspecified)">
      context_label:   <e.g. "Platform" | "Platform | Settings">
      feature_title:   <5–10 word headline; sentence case; no leading "New feature:"; no trailing period>
      prose: |
        <2–4 sentence customer-facing paragraph; no Jira IDs; no PR links>
      rendered: |
        {{#context}}<context_label>{{/context}}

        ### <feature_title>

        <prose>
  combined_rendered: |
    <all entries' `rendered` blocks concatenated, separated by one blank line>

gaps:
  - field:              <context_label | feature_title | prose | release_version>
    reason:             <why this is low-confidence or missing>
    recommended_action: "ask user" | "mark TODO in draft"
```

`status: PARTIAL` when at least one gap has `recommended_action: "ask user"`.

## Status codes

| Status    | Meaning                                                              |
|-----------|---------------------------------------------------------------------|
| `OK`      | Draft rendered; every entry has a confident context label and prose.|
| `PARTIAL` | Draft rendered but at least one gap needs the user (low-confidence label, missing version, or unverifiable claim). |
```

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
test -f plugins/dev-workflows/references/handoff/release-notes-writer.md && echo "PASS: file exists"
grep -q "dynatrace-docs-release-notes-v1" plugins/dev-workflows/references/handoff/release-notes-writer.md && echo "PASS: schema tag"
grep -qi "no Jira IDs; no PR links" plugins/dev-workflows/references/handoff/release-notes-writer.md && echo "PASS: no-ID rule"
```

Expected: three `PASS` lines.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/handoff/release-notes-writer.md
git commit -m "feat(dev-workflows): add release-notes-writer handoff contract"
```

---

## Task 2: `release-notes-writer` agent

**Files:**
- Create: `plugins/dev-workflows/agents/release-notes-writer.md`

- [ ] **Step 1: Create the agent**

````markdown
---
name: release-notes-writer
description: Renders a dynatrace-docs release-notes draft (authored body only — a {{#context}} label, an ### title, and customer-facing prose) for a Jira VI/ticket from the jira-reader handoff and optional PR-diff summaries. One entry per declared release version. Emits NO Jira IDs, NO PR links, and NO {{#internal-note}} block (the docs automation adds that). Does NOT write files. Inherits the session's model.
tools: ["Read", "Glob", "Grep", "LS"]
---

Render a release-notes draft for a Jira Value Increment (or other ticket) in the
dynatrace-docs feature-update format. You produce only the **authored body** that a
PM pastes into the ticket's Jira release-notes field; the docs team's automation adds
the `{{#internal-note}}` metadata wrapper (Ticket URL, assignee, status, release
versions) from the ticket itself.

You do NOT write files — you return the rendered draft to the caller.

## Inputs

```yaml
jira_reader_handoff: <full YAML from jira-reader>
diff_summaries:      <optional array of diff-summarizer outputs; omit when diff-grounding is off>
release_versions:    [<parsed version strings, e.g. "Managed (344)", "SaaS (344)">]
context_label_hint:  <optional category labels; null otherwise>
model_routing:       <standard block>
```

Refuse to run without `jira_reader_handoff`.

## Process

1. **Gather substance.** From the VI/ticket file in the handoff, read the summary,
   `## User Story`, `## Acceptance Criteria`, and `## Problem/Pain`. When
   `diff_summaries` is present, use it only to confirm what actually shipped — never to
   add implementation detail that is not user-visible.

2. **Determine release versions.** Use `release_versions` as given. If `[]`, produce a
   single entry with `release_version: "(unspecified)"` and add a `gaps` entry
   (`field: release_version`, `recommended_action: "ask user"`).

3. **Per entry, build the authored body:**
   - **Context label** — 1–2 short product-area labels (pipe-separated when 2, e.g.
     `Platform | Settings`), inferred from the VI summary / themes, or from
     `context_label_hint` when provided. If confidence is low, still emit a best guess
     and add a `gaps` entry (`field: context_label`, `recommended_action: "ask user"`).
   - **Feature title** — 5–10 words, sentence case, release-note headline style. No
     leading "New feature:", no trailing period.
   - **Prose** — 2–4 sentences for end users: what they can now do and why it matters.
     Plain customer-facing language.

4. **Render** each entry as exactly:

   ```handlebars
   {{#context}}<context_label>{{/context}}

   ### <feature_title>

   <prose>
   ```

   Concatenate entries (blank-line separated) into `combined_rendered`.

## Output

Return YAML exactly as defined in `${CLAUDE_PLUGIN_ROOT}/references/handoff/release-notes-writer.md`.

## Hard rules

- NEVER write or modify files. This agent renders; the command writes.
- NEVER include a Jira ID/key (e.g. `PRODUCT-14902`, `[[KEY]]`, or a browse URL)
  anywhere in `context_label`, `feature_title`, `prose`, or `rendered`. The draft is
  pasted into the ticket's Jira release-notes field; the automation associates the ID.
- NEVER include a Bitbucket/GitHub/GitLab PR URL or PR number in any output field.
  Release notes are customer-facing.
- NEVER emit a `{{#internal-note}}` block — the docs automation generates it.
- NEVER invent user-visible behaviour not supported by the Jira content (or the diff
  summaries when provided); flag unverifiable claims as a `gaps` entry.
- ALWAYS produce one entry per `release_versions` item (or a single `(unspecified)`
  entry when none are declared).
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/agents/release-notes-writer.md
head -1 "$F" | grep -q '^---$' && echo "PASS: frontmatter start"
grep -q "^name: release-notes-writer$" "$F" && echo "PASS: name"
grep -q "NEVER emit a \`{{#internal-note}}\` block" "$F" && echo "PASS: no internal-note rule"
grep -q "NEVER include a Jira ID/key" "$F" && echo "PASS: no-ID rule"
grep -q "release-notes-writer.md" "$F" && echo "PASS: references handoff"
```

Expected: five `PASS` lines.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/agents/release-notes-writer.md
git commit -m "feat(dev-workflows): add release-notes-writer agent"
```

---

## Task 3: `/impl:jira:release-notes` command

**Files:**
- Create: `plugins/dev-workflows/commands/impl/jira/release-notes.md`

- [ ] **Step 1: Create the command**

````markdown
---
name: impl:jira:release-notes
description: Jira-driven release-notes drafting. Reads a Value Increment (or any ticket) from exported markdown, optionally grounds in PR diffs, renders a dynatrace-docs release-notes body, runs a light dt-style-checker gate, and writes a persistent draft to paste into Jira's release-notes field.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Draft release notes for the Jira ticket: $ARGUMENTS

`/impl:jira:release-notes` produces a **customer-facing release-notes draft** for a Jira
Value Increment (or any ticket) from pre-exported markdown in the user's Obsidian vault.
It optionally grounds the prose in merged PR diffs, renders the dynatrace-docs authored
release-notes body (a `{{#context}}` label + `### title` + prose — **no `{{#internal-note}}`,
no Jira IDs, no PR links**; the docs automation adds the metadata wrapper), runs a light
style gate, and writes the draft to a persistent destination for the user to paste into
Jira's release-notes field.

For full feature documentation use `/impl:jira:docs`; for Epic drafting use `/impl:jira:epics`.

This command makes **zero external API calls** and **never writes into the docs repo**
(release-notes pages there are generated by Jira-driven automation).

---

## Phase 0 — Load

1. **Resolve `$VAULT_PATH`.** Read the `VAULT_PATH` environment variable. If unset, ask:
   ```
   choices: ["Set to detected path (Recommended)", "Enter manually", "Cancel"]
   ```
   Validate the resolved path exists and contains a `jira-products/` subdirectory. If not, stop with an error.

2. **Resolve `<JIRA_KEY>`** from `$ARGUMENTS`. Validate that `$VAULT_PATH/jira-products/<JIRA_KEY>/` exists. If not, stop with an error naming the missing directory.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess.** Group questions; use `choices` arrays; the last choice MUST be `"Other… (describe)"`.

- **Diff grounding** (default OFF — Jira content is usually enough for release notes):
  ```
  choices: ["Jira content only (Recommended)", "Also ground in merged PR diffs (you'll pick repos)", "Cancel", "Other… (describe)"]
  ```
  If "ground in PR diffs", additionally ask the two sub-questions below.

- **Repos search base (`$REPOS_PATH`)** (only if diff grounding is ON). Read `${REPOS_PATH:-/workspace}`; may be a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  Clones are located in Phase 4 by matching `git remote` against each PR's repo slug — not by assuming a `<base>/<slug>` directory name.

- **PR status filter** (only if diff grounding is ON):
  ```
  choices: ["MERGED only (Recommended)", "All PRs (MERGED + OPEN + DECLINED)", "Specific list (you'll be prompted)", "Other… (describe)"]
  ```

- **Output destination.** First resolve the ticket's persistent Obsidian project folder (the durable home where the user keeps project work — NOT `jira-products/`, which is regenerated on every Jira import):
  ```bash
  find "$VAULT_PATH/Projects" -maxdepth 5 -type d -name "<JIRA_KEY>*" 2>/dev/null | head -1
  ```
  Then ask (the default uses the resolved `<project-dir>` when found):
  ```
  choices: ["Write to <project-dir>/<JIRA_KEY>-release-notes.md (Recommended — persistent project folder)", "Write to a different absolute path (you'll be prompted)", "Print to screen only", "Skip writing", "Other… (describe)"]
  ```
  When no project folder is found (e.g. a non-`PRODUCT-` ticket), drop the first choice and make "Write to a different absolute path" the recommended one. The default is persistent under `$VAULT_PATH` (always host-mounted; survives container restart, unlike `/tmp`). NEVER offer or accept a path inside a docs repo or under `jira-products/`.

- **Style check** (default ON when the `dt-style-guide` plugin is installed):
  ```
  choices: ["Run dt-style-checker then apply safe fixes (Recommended)", "Run dt-style-checker, report only (no auto-fix)", "Skip style check", "Other… (describe)"]
  ```

Also display: resolved `$VAULT_PATH`, `<JIRA_KEY>`, `$REPOS_PATH` (or "N/A — Jira-only"), and the resolved destination.

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then classify the task. Release-notes drafting is **MODERATE** (bounded prose synthesis from a single ticket; no Opus planning or review gate). State the classification and a one-sentence reason.

---

## Phase 2 — Worthiness check + plan/approval

1. **Worthiness.** After Phase 3 reads the ticket (or by reading the VI frontmatter now), check `relevant_for_release_notes` and `release_versions`. If `relevant_for_release_notes != "Yes"` AND `release_versions` is empty/absent, warn and ask:
   ```
   choices: ["Proceed anyway (Recommended)", "Cancel", "Other… (describe)"]
   ```

2. **Plan.** Present: resolved `<JIRA_KEY>`, destination, diff-grounding on/off (+ `$REPOS_PATH` and repos to scan when on), release versions detected, style-check choice. Ask:
   ```
   choices: ["Approve & continue (Recommended)", "Revise plan", "Cancel"]
   ```

---

## Phase 3 — Read Jira

Invoke `jira-reader`. Use `depth: vi-only` when diff grounding is OFF; `depth: full` when ON (to collect PR URLs from the hierarchy's `## Pull Requests` sections).

→ Agent (subagent_type: "dev-workflows:jira-reader"):
  > "Return the structured handoff for this brief:
  >
  > vault_path: [resolved $VAULT_PATH]
  > jira_key:   [resolved <JIRA_KEY>]
  > depth:      [vi-only | full]"

If `status: NOT_FOUND` / `EMPTY`, surface `["Re-enter key", "Cancel"]`. On `OK`, parse `release_versions` from the VI frontmatter into a list (e.g. `"Managed (344), SaaS (344)"` → `["Managed (344)", "SaaS (344)"]`).

---

## Phase 4 — Resolve repos (only if diff grounding is ON)

Build a slug→clone map: for each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as the clone's slug. Resolve each in-scope PR repo slug against the map: one match → use it; multiple → auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last; zero matches → escalate:
```
choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
```

---

## Phase 5 — Diff summarisation (only if diff grounding is ON)

Spawn `diff-summarizer` in batches of up to 4 concurrent agents per Agent message, passing each resolved absolute `repo_path` plus `repo_url_slug` and the PRs filtered to that repo. Collect the outputs into a `diff_summaries` array.

---

## Phase 6 — Render the draft

→ Agent (subagent_type: "dev-workflows:release-notes-writer"):
  > "Render the release-notes draft for this brief:
  >
  > jira_reader_handoff: [the Phase 3 handoff]
  > diff_summaries:      [the Phase 5 array, or omit when diff grounding was off]
  > release_versions:    [parsed list, or [] ]
  > context_label_hint:  [user hint if any, else null]
  > model_routing:       [the block from Phase 1.5]"

If `status: PARTIAL`, surface each `gaps` entry with `recommended_action: "ask user"` and let the user supply the label/prose or accept a `<!-- TODO -->` marker.

---

## Phase 7 — Style gate (optional)

If the user chose a style check AND the `dt-style-guide` plugin is installed:

→ Agent (subagent_type: "dt-style-guide:dt-style-checker") on the `combined_rendered` draft (write it to the destination first when the destination is a file, or pass it inline). If violations are returned and the user chose auto-fix:

→ Agent (subagent_type: "dt-style-guide:dt-doc-fixer") to apply safe fixes.

If `dt-style-guide` is not installed, skip this phase and note "style check skipped — dt-style-guide not installed" in the report.

---

## Phase 8 — Write + report

1. **Write** the `combined_rendered` draft to the resolved destination:
   - `file:<path>` → write it. If the file exists, ask: `["Overwrite", "Write to <path>.new", "Print to screen instead", "Skip"]`.
   - `stdout` → include the full draft in the report under `### Release-notes draft`.
   - `skip` → do not write.
   NEVER write into a docs repo.

2. **Report:**
   ```
   ## Release-notes draft — <JIRA_KEY>
   - Destination: <path | stdout | skipped>
   - Release versions: <list, or "none declared">
   - Diff grounding: <on (repos: …) | off>
   - Style check: <applied N safe fixes | report only (M findings) | skipped (dt-style-guide absent)>
   - Reminder: paste this into the ticket's Jira release-notes field — the docs automation adds the {{#internal-note}} metadata and emits it into dynatrace-docs.
   ```

---

## Invariants (always enforced)

- ZERO external API calls — PR URLs are identifiers only; all resolution is local `git`.
- `jira-reader` is read-only.
- The draft contains NO Jira IDs/keys, NO PR links, and NO `{{#internal-note}}` block.
- NEVER write into a docs repo; the default destination is persistent (never `/tmp`).
- ALWAYS use `choices` arrays; the last choice is always `"Other… (describe)"`.
- Light gate only — no Opus review, no tests, no branch, no commit.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/impl/jira/release-notes.md
grep -q "^name: impl:jira:release-notes$" "$F" && echo "PASS: name"
grep -q "dev-workflows:release-notes-writer" "$F" && echo "PASS: invokes writer"
grep -q "dev-workflows:jira-reader" "$F" && echo "PASS: invokes jira-reader"
grep -q "NEVER write into a docs repo" "$F" && echo "PASS: no-docs-repo rule"
grep -qi "no Jira IDs" "$F" && echo "PASS: no-ID invariant"
```

Expected: five `PASS` lines.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/commands/impl/jira/release-notes.md
git commit -m "feat(dev-workflows): add /impl:jira:release-notes command"
```

---

## Task 4: Widen the preload-context hook regex

**Files:**
- Modify: `plugins/dev-workflows/hooks/preload-context.sh:37`

The current regex only matches `jira(:(docs|epics))?`, so `/impl:jira:release-notes` fails to match and no context is injected. Add `release-notes` to the alternation.

- [ ] **Step 1: Edit the regex**

Replace (line 37):

```
if [[ ! "$prompt" =~ ^/(impl(:(code|docs|jira(:(docs|epics))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-] ]]; then
```

with:

```
if [[ ! "$prompt" =~ ^/(impl(:(code|docs|jira(:(docs|epics|release-notes))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-] ]]; then
```

- [ ] **Step 2: Verify with a stdin harness**

```bash
cd /workspace/ihudak-claude-plugins
HOOK=plugins/dev-workflows/hooks/preload-context.sh
out=$(printf '{"prompt":"/impl:jira:release-notes PRODUCT-14902"}' | env -u REPOS_PATH bash "$HOOK")
echo "$out" | grep -q "Jira workflow" && echo "PASS: routed to jira branch" || echo "FAIL: not routed"
echo "$out" | grep -q "repos_path: /workspace" && echo "PASS: repos_path default" || echo "FAIL"
# regression: existing commands still route
printf '{"prompt":"/impl:jira:docs X"}' | bash "$HOOK" | grep -q "Jira workflow" && echo "PASS: docs still routes" || echo "FAIL"
printf '{"prompt":"/impl:jira:release-notes X"}' | bash "$HOOK" >/dev/null; echo "exit=$?"
```

Expected: `PASS: routed to jira branch`, `PASS: repos_path default`, `PASS: docs still routes`, `exit=0`.

> Note: the hook prints a `=== Auto-injected project context (Jira workflow) ===` header for the `impl:jira*` branch — that is the "Jira workflow" string asserted above. Confirm by reading the `impl:jira*)` case if the assertion fails.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/hooks/preload-context.sh
git commit -m "fix(dev-workflows): preload hook routes /impl:jira:release-notes"
```

---

## Task 5: Docs-flow correction — release notes are not a repo target

**Files:**
- Modify: `plugins/dev-workflows/agents/doc-planner.md` (the "What's new" topic + hard rules)
- Modify: `plugins/dev-workflows/agents/doc-location-finder.md:42`
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md` (intro + consequential-updates phase)

- [ ] **Step 1: doc-planner — reframe the "What's new" topic**

Replace (in `agents/doc-planner.md`, the topic line ~32):

```
   - "What's new" — when the feature warrants a release-notes entry
```

with:

```
   - (Do NOT add a "What's new" / release-notes topic here — dynatrace-docs release-notes pages are generated by Jira-driven automation, not authored in the repo. Release notes are produced by the separate `/impl:jira:release-notes` command.)
```

- [ ] **Step 2: doc-planner — add a hard rule**

In `agents/doc-planner.md`, in the `## Hard rules` list, add a new bullet at the end:

```
- NEVER propose a release-notes / what's-new path as a `target_path` (e.g. `_snippets/release-notes/...`, `_content/whats-new/...`, `_data/release-notes/...`). Those pages are generated from Jira by the docs team's automation; a manual write would be overwritten. Release notes are produced by the `/impl:jira:release-notes` command.
```

- [ ] **Step 3: doc-location-finder — drop the release-notes example + add exclusion**

Replace (in `agents/doc-location-finder.md:42`):

```
5. **Return multiple targets when the feature has multiple natural homes.** A single feature can straddle a Settings reference page, a How-to guide, and a What's New/Release Notes entry. Emit one target per natural home, each with its own kind and rationale. Cross-linking intent between targets is captured in `linked_from`.
```

with:

```
5. **Return multiple targets when the feature has multiple natural homes.** A single feature can straddle a Settings reference page and a How-to guide. Emit one target per natural home, each with its own kind and rationale. Cross-linking intent between targets is captured in `linked_from`. NEVER propose a What's New / release-notes path (e.g. `_content/whats-new/...`, `_snippets/release-notes/...`, `_data/release-notes/...`) as a target — those are generated from Jira by automation; release notes are produced by the `/impl:jira:release-notes` command.
```

- [ ] **Step 4: docs.md — note the boundary in the intro**

In `commands/impl/jira/docs.md`, replace (line ~11):

```
For small one-off doc edits, use `/impl:docs`. For writing child Epic drafts from a VI, use `/impl:jira:epics`.
```

with:

```
For small one-off doc edits, use `/impl:docs`. For writing child Epic drafts from a VI, use `/impl:jira:epics`. For release notes, use `/impl:jira:release-notes` — this command never writes release-notes / what's-new pages, because those are generated from Jira by the docs team's automation.
```

- [ ] **Step 5: docs.md — remove release-notes from the consequential-updates phase**

In `commands/impl/jira/docs.md`, replace (line ~424):

```
> Determine if *other* documentation needs updating as a consequence of this write (e.g., an index page, a cross-referenced overview, a changelog entry in the repo root, a release-notes file).
```

with:

```
> Determine if *other* documentation needs updating as a consequence of this write (e.g., an index page, a cross-referenced overview, a changelog entry in the repo root). Do NOT touch release-notes / what's-new pages — those are generated from Jira by automation.
```

And replace (line ~426):

```
> - Update if: new page requires an index/sidebar entry, new sections require inbound cross-links, new snippet file needs a release-notes mention.
```

with:

```
> - Update if: new page requires an index/sidebar entry, new sections require inbound cross-links.
```

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins
# release notes no longer proposed as a doc target
grep -q "NEVER propose a release-notes" plugins/dev-workflows/agents/doc-planner.md && echo "PASS: planner rule"
grep -q "NEVER propose a What's New" plugins/dev-workflows/agents/doc-location-finder.md && echo "PASS: finder rule"
grep -q "/impl:jira:release-notes" plugins/dev-workflows/commands/impl/jira/docs.md && echo "PASS: docs defers"
# the old "What's new" topic line is gone from the planner topic list
grep -q '"What.s new" — when the feature warrants' plugins/dev-workflows/agents/doc-planner.md && echo "FAIL: stale topic" || echo "PASS: topic reframed"
```

Expected: `PASS: planner rule`, `PASS: finder rule`, `PASS: docs defers`, `PASS: topic reframed`.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/agents/doc-planner.md plugins/dev-workflows/agents/doc-location-finder.md plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "fix(dev-workflows): docs flow defers release notes to /impl:jira:release-notes"
```

---

## Task 6: README + CLAUDE.md

**Files:**
- Modify: `plugins/dev-workflows/README.md` (command table)
- Modify: `CLAUDE.md` (workflow relationships + invariants)

- [ ] **Step 1: README — add the command row**

In `plugins/dev-workflows/README.md`, after the `/impl:jira:epics` row (line ~13), add:

```
| `/impl:jira:release-notes <KEY>` | Jira-driven release-notes drafting. Reads the ticket from the vault, optionally grounds in merged PR diffs, renders the dynatrace-docs authored release-notes body (`{{#context}}` + title + prose; no IDs, no `{{#internal-note}}`), runs a light `dt-style-checker` gate, and writes a persistent draft to paste into Jira. Never branches, commits, or writes into the docs repo. |
```

- [ ] **Step 2: CLAUDE.md — add to the workflow-relationships map**

In `CLAUDE.md`, in the ```` ``` ```` workflow map under `## \`dev-workflows\` workflow relationships`, after the `/impl:jira:epics` line, add:

```
/impl:jira:release-notes → /impl:jira:release-notes → jira-reader → [diff-summarizer×N (parallel, optional)] → [release-notes-writer] → [dt-style-checker → dt-doc-fixer (optional)] → write draft (paste into Jira)
```

- [ ] **Step 3: CLAUDE.md — add an invariants block**

In `CLAUDE.md`, after the `Key invariants for /impl:jira:` block, add:

```
Key invariants for `/impl:jira:release-notes`:

- **Zero external API calls** — PR URLs are identifiers only; all resolution is local `git` against clones under `$REPOS_PATH`
- `jira-reader` is read-only
- The draft is the **authored body only** — a `{{#context}}` label, `### title`, and customer-facing prose; NEVER a Jira ID/key, a PR link, or a `{{#internal-note}}` block (the docs automation adds the metadata wrapper)
- NEVER writes into a docs repo; the default destination is persistent (never `/tmp`)
- Light gate only — `dt-style-checker` (optional, skipped if `dt-style-guide` absent); no Opus review, no tests, no branch, no commit
- Diff grounding is opt-in; when on, it reuses `$REPOS_PATH` resolution + `diff-summarizer`
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -q "/impl:jira:release-notes <KEY>" plugins/dev-workflows/README.md && echo "PASS: README row"
grep -q "Key invariants for \`/impl:jira:release-notes\`" CLAUDE.md && echo "PASS: CLAUDE invariants"
grep -q "release-notes-writer" CLAUDE.md && echo "PASS: workflow map"
```

Expected: three `PASS` lines.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/README.md CLAUDE.md
git commit -m "docs: document /impl:jira:release-notes in README and CLAUDE.md"
```

---

## Task 7: Release bookkeeping — dev-workflows 1.6.0

**Files:**
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend 1.6.0)
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (`1.5.1` → `1.6.0`)
- Modify: `.claude-plugin/marketplace.json` (dev-workflows `1.5.1` → `1.6.0`)

- [ ] **Step 1: Prepend the CHANGELOG entry**

Insert directly after the header block (before the latest `## [1.5.1]` entry):

```
## [1.6.0] — 2026-06-16

### Added
- **`/impl:jira:release-notes` command.** Standalone Jira-driven release-notes
  drafting: reads a VI (or any ticket) from the vault, optionally grounds the prose
  in merged PR diffs (reusing `$REPOS_PATH` resolution + `diff-summarizer`), and
  renders the dynatrace-docs authored release-notes body — a `{{#context}}` label,
  an `### title`, and customer-facing prose. The draft carries **no Jira IDs, no PR
  links, and no `{{#internal-note}}` block**; it is pasted into the ticket's Jira
  release-notes field, where the docs team's automation adds the metadata wrapper.
  Light `dt-style-checker` gate (optional; skipped if `dt-style-guide` is absent).
  Never branches, commits, or writes into the docs repo; the default destination is
  persistent.
- **`release-notes-writer` agent** + handoff reference — renders the
  `release_notes_block` (one entry per declared release version).

### Fixed
- **Docs flow no longer treats release notes as a repo write target.** `doc-planner`
  and `doc-location-finder` previously proposed "What's New / Release Notes" pages as
  documentation targets, but those pages are generated from Jira by automation — a
  manual write would be overwritten. Both now exclude release-notes / what's-new paths,
  and `/impl:jira:docs` defers release notes to `/impl:jira:release-notes`.

```

- [ ] **Step 2: Bump plugin.json**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, replace `"version": "1.5.1",` with `"version": "1.6.0",`.

- [ ] **Step 3: Bump marketplace.json (surgical — do not reformat)**

Use Edit (not a JSON re-serializer — that escapes the em-dashes). Replace:

```
      "name": "dev-workflows",
      "version": "1.5.1",
```

with:

```
      "name": "dev-workflows",
      "version": "1.6.0",
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json    # expect 1.6.0
grep -A1 '"name": "dev-workflows"' .claude-plugin/marketplace.json | grep version  # expect 1.6.0
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('JSON valid')"
grep -c '\\u' .claude-plugin/marketplace.json | sed 's/^/backslash-u count (expect 0): /'
```

Expected: `1.6.0` in both manifests, `JSON valid`, backslash-u count 0.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "release: dev-workflows 1.6.0 (/impl:jira:release-notes)"
```

---

## Task 8: End-to-end structural smoke check

**Files:** none (verification only)

- [ ] **Step 1: Confirm the command wiring is internally consistent**

```bash
cd /workspace/ihudak-claude-plugins
# command references the new agent; agent + handoff exist
grep -q "dev-workflows:release-notes-writer" plugins/dev-workflows/commands/impl/jira/release-notes.md && echo "PASS: command→agent"
test -f plugins/dev-workflows/agents/release-notes-writer.md && test -f plugins/dev-workflows/references/handoff/release-notes-writer.md && echo "PASS: agent+handoff exist"
# no Jira ID / internal-note leakage in the authored-body contract
grep -rq "NEVER emit a \`{{#internal-note}}\`" plugins/dev-workflows/agents/release-notes-writer.md && echo "PASS: no internal-note"
# PRODUCT-14902 is a valid release-notes-worthy smoke target
grep -q 'relevant_for_release_notes: "Yes"' "$VAULT_PATH/jira-products/PRODUCT-14902/PRODUCT-14902/PRODUCT-14902.md" && echo "PASS: smoke target is worthy"
```

Expected: four `PASS` lines.

- [ ] **Step 2: Manual smoke test (human-run, optional)**

After reinstalling the plugin and restarting, run `/impl:jira:release-notes PRODUCT-14902` with diff grounding OFF and destination = stdout; confirm the rendered draft is `{{#context}}…{{/context}}` + `### title` + prose for **two** entries (`Managed (344)`, `SaaS (344)`) with no Jira IDs, PR links, or `{{#internal-note}}`.

---

## Post-implementation

- [ ] Offer to merge `feat/jira-release-notes-command` → `main`, push, and update the installed plugin (`claude plugin marketplace update ihudak-plugins` then `claude plugin update dev-workflows@ihudak-plugins`). Do not push without the human's go-ahead.

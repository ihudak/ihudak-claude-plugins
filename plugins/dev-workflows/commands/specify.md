---
name: specify
description: Jira-driven specification-authoring workflow (PM phase). Reads a Jira Epic/VI from exported markdown, lightly grounds in code, and authors an org-standard specification.md through a relentless one-question-at-a-time grill; gates on the Opus spec-reviewer and lands the spec on the specs repo's main branch via branch + PR for the /design dev take-over.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Author a product specification for the Jira item: $ARGUMENTS

`/specify` is the **PM-phase specification-authoring** workflow — phase 1 of the PM→Dev pipeline
(`/specify` → `specification.md`; then `/design` → `design.md` + `plan.md`). Given a Jira Epic (or VI)
key or an imported-Jira directory, it reads the item from pre-exported markdown, lightly scans code to
ground feasibility, and authors an org-standard `specification.md` through a relentless
one-question-at-a-time grill — resolving open questions live instead of stopping. It gates on the
Opus `spec-reviewer` and offers to land the spec on the specs repo's main branch (via branch + PR) as
`Published: no`.

Key distinction from `/epics`: `/epics` *splits* a VI into Epic drafts; `/specify` *authors one
specification* for a single item (typically an Epic). Run `/epics` first, then `/specify` per Epic.

---

## Phase 0 — Resolve input

1. **Resolve the Jira input via the shared front-end.** Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against `$ARGUMENTS`. `/specify` is
   **jira-driven only**: expect `mode: jira-driven` with `jira_key` (the Epic or VI key being
   specified) and `jira_export_root`. The front-end owns the `$VAULT_PATH` / `jira-products`
   validation and Fallbacks A/B. Carry `jira_key` and `jira_export_root` forward. Downstream, `<KEY>`
   denotes this `jira_key`.

   If the front-end returns `mode: direct` (no Jira input), stop with
   `SPECIFY_NEEDS_JIRA: /specify needs a Jira key or an imported-Jira directory.` — `/specify` has no
   direct-prompt behavior.

2. **Resolve `$SPECS_PATH`.** `/specify` writes specifications under
   `$SPECS_PATH/specifications/<KEY>_<slug>/` — the specs repo, not the vault. If `$SPECS_PATH` is
   unset, stop with a clear error naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)",
   "Cancel"]`) — there is no vault-relative fallback for this write target the way there is for reads.

3. **Resolve the feature folder.** Derive a provisional `<slug>` as the kebab-case form of the Jira
   item's title (from the index/summary — finalized once `jira-reader` runs in Phase 2, but a
   provisional slug is enough to check for an existing folder now). Look for an existing folder at
   `$SPECS_PATH/specifications/<KEY>{-|_}<slug>/` — tolerate `-`/`_` after the key and a pre-existing
   slug that doesn't exactly match a freshly-derived one (a human may have adjusted it). Honor an
   existing folder if found; otherwise the folder is created at `$SPECS_PATH/specifications/<KEY>_<slug>/`
   the first time a phase writes to it — Phase 2's `idea.md` write, in a fresh run.

4. **Detect a prior run.** If a `_session.md` exists in the resolved feature folder, record that a
   resume is available — Phase 1 asks the user resume-vs-fresh. If no `_session.md` exists, this is a
   fresh run.

`/specify` is **cwd-agnostic**, like `/epics` — it reads Jira from the vault/export and writes specs to
an absolute `$SPECS_PATH`-rooted directory, so it does not require cwd to be inside either.

---

## Phase 1 — Configure

**Rule: Ask, don't guess. This rule is absolute.**

Use `choices` arrays; the last choice in every array MUST be `"Other… (describe)"`.

1. **Feature folder.** Confirm the path resolved in Phase 0:
   ```
   choices: ["Use <feature_folder> (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
   ```

2. **Resume vs fresh** (only if Phase 0 found a `_session.md`). Read it back and summarise which
   stages/questions are already settled:
   ```
   choices: ["Resume — skip settled stages/questions (Recommended)", "Start fresh — discard the prior session", "Cancel", "Other… (describe)"]
   ```
   On resume, Phase 5 begins at the first unsettled stage instead of the header.

3. **Repo refresh policy** (governs Phase 4's `code-scanner` dispatches):
   ```
   choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh", "Other… (describe)"]
   ```
   `fetch + pull default branch` matches `code-scanner`'s own default
   (`refresh.switch_to_default_branch: true, refresh.pull: true`) — grounding wants present-day code,
   the same rationale `/epics` uses.

4. **Repos search base (`$REPOS_PATH`)**. Read `${REPOS_PATH:-/workspace}`. `$REPOS_PATH` may be a
   single directory or a colon-separated list:
   ```
   choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
   ```
   If "different path", validate that at least one directory exists under the given value before
   recording it.

Also display (for user context): resolved feature folder; resolved `jira_export_root` and `jira_key`;
resolved `$REPOS_PATH`; resolved `$SPECS_PATH`.

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then classify as `SIMPLE` / `MODERATE` / `SIGNIFICANT` / `HIGH-RISK`. Specification authoring is typically **MODERATE**. Resolve per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible for large/cross-cutting VIs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader, code-scanner
  review_model:    <§2 Opus chain>     # spec-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + specification.md authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (interactive judgment — not a delegated subagent), consistent with the model-routing SSOT. If no Opus is available, `spec-reviewer` falls to the Sonnet floor — record the degradation in `notes` and the final report.

---

## Phase 2 — Read Jira

Dispatch `jira-reader` at `depth: full` — richer than `/epics`' `vi-plus-epics`, because `/specify`
needs the full linked subtree (Stories/Sub-tasks) as the raw material for user stories, acceptance
criteria, and test cases; `vi-plus-epics` would starve the grill of exactly the detail it needs.

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
  > depth:      full"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found`
rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On
`OK`:

- Extract **capability themes** and component/product mentions — feeds Phase 3's repo derivation and
  Phase 4's `code-scanner` dispatches.
- Write **`idea.md`** in the feature folder from the Jira text (the item's summary, description, and
  linked-item summaries) — pre-spec brainstorming provenance, in the same spirit as the `idea.md`
  convention `source-truth.md` already treats as non-authoritative once `specification.md` exists.
- Carry the full linked-item tree (Stories/Sub-tasks) forward into Phase 5 — the raw material the
  grill mines for user stories, acceptance criteria, and test cases.

---

## Phase 2.5 — Granularity pre-flight

From the `jira-reader` output, determine the input item's type (VI vs Epic) and whether it has child Epics:

- **Epic input** → proceed (the sweet spot).
- **VI input _with_ Epics** → inform the user that specs are authored per Epic; list the child Epics. Offer:
  `choices: ["Run /specify per Epic (Recommended — I'll list them)", "Author one broad VI-level spec", "Cancel"]`
- **VI input _without_ Epics** → flag it and offer:
  `choices: ["Split into Epics first with /epics, then create them in Jira and re-import (Recommended)", "Author one broad VI-level spec now", "Cancel"]`
  `/specify` does NOT create Jira Epics itself (zero external API) — it guides the user through the manual round-trip (see the round-trip note below).

---

## Phase 3 — Derive repos + soft gate

1. **Auto-derive candidate repos.** From the Phase 2 capability themes and any linked PR URLs in the
   `jira-reader` handoff (`pull_requests[].repo`), build a candidate repo-slug list. If the list is
   empty, escalate per the `No repos derivable — /epics` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["List repos to scan manually", "Proceed without code scan", "Cancel", "Other… (describe)"]
   ```

2. **Build the slug→clone map** (`/epics`-style). For each top-level directory under each entry of
   `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing
   `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git`
   or whose `git remote` call fails/times out.

3. **Resolve each candidate against the map.** One match → use it. An ambiguous slug (multiple
   matches) or zero matches both escalate per the `Repo unresolved (zero matches) — /epics` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
   ```

4. **Cross-check mounted status — soft gate.** A resolved repo slug that is not actually mounted under
   `$REPOS_PATH` does NOT hard-block `/specify` the way an unresolved slug does above. Instead: record
   a feasibility `- [ ]` open question in `_session.md` (e.g. "Cannot ground <theme> — `<repo-slug>` is
   not mounted; feasibility unverified"), report the gap to the user now, and **PROCEED** to Phase 4
   with the remaining mounted repos. Describe the missing capability and why it matters — the
   specification cannot name or link an unmounted repo's code, so any claim resting on it stays an
   open question until the repo is mounted and `/specify` is re-invoked (Phase 5 keeps `_session.md`
   current, so the run is resumable).

---

## Phase 4 — Light code scan

Spawn `code-scanner` instances in **batches of up to 4 concurrent agents** per Agent message, on the
mounted candidates resolved in Phase 3. Wait for each batch before spawning the next. This is
deliberately a **light** scan relative to `/epics`' — grounding for feasibility and to avoid
contradicting existing behaviour, not a full reuse audit.

For each repo in the batch:

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 3>
  > repo_url_slug: <repo slug, e.g. "cluster">
  > capability_themes:
  >   [paste the themes array from jira-reader]
  > context: |
  >   [3–5 sentences: the Jira item's goal, what the specification must ground]
  > search_hints:
  >   symbols:  [class/function names inferred from the Jira text, or []]
  >   paths:    [directory globs inferred from themes, or []]
  >   keywords: [grep keywords extracted from themes]
  > refresh:
  >   switch_to_default_branch: [true if Phase 1 chose 'fetch + pull default branch' (default) or 'fetch only'; false if 'no refresh']
  >   pull: [true if 'fetch + pull default branch'; false otherwise]"

Handle per-repo status after the batch returns:

- `OK` / `PARTIAL` / `EMPTY` — store the "does this exist / where / gaps" output; this grounds Phase 5's
  grill (e.g. answering a question from the scan instead of asking the user).
- `REPO_MISSING` — should not happen at this stage (Phase 3 already checked). If it does, escalate per
  the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `DIRTY_TREE` — escalate:
  ```
  choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]
  ```
- `REFRESH_BLOCKED` — escalate:
  ```
  choices: ["Continue with current local state", "Skip this repo", "Cancel"]
  ```

---

## Phase 5 — Author via grill

**Interview technique (grilling — embedded; no runtime plugin dependency).** Conduct each stage as a relentless interview:

- Ask exactly ONE question at a time; wait for the answer before the next. Never batch questions — a firehose is bewildering.
- For every question, give your recommended answer, so the user reacts to a proposal, not a blank prompt.
- If a question can be answered from the Phase 4 code scan or the Jira content, explore and answer it yourself instead of asking.
- Walk the design tree in dependency order — resolve a parent decision before the choices that depend on it.
- Continue until you and the user reach a shared understanding for the stage, then write that stage's section.

(Technique adapted from mattpocock grill-me/grilling; embedded here so `/specify` has no runtime dependency.)

Walk the stages in order, authoring `specification.md` live against `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`:

1. Header + **Problem statement**
2. **Scope** (In/Out)
3. **User stories** (`[Uxx]`)
4. **Acceptance criteria** (`[ACxx]`, EARS)
5. **Test cases** (`[TCxx]`)

As each decision settles, append it to `_session.md`; capture a genuinely-ambiguous term in `_glossary.md`. Resolve open questions to zero where possible; leave genuinely unresolvable ones as `- [ ]` and keep the header **Open questions** count in sync. A repo gap surfacing here → escalate (describe the missing capability + why) and STOP; the run is resumable from `_session.md` after the user remounts and re-invokes.

---

## Phase 6 — Finalize + review gate

1. **Render HTML.** `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/specification-to-html.py" <spec path>`
   against the `specification.md` written in Phase 5. On failure, report the error and proceed — the
   HTML mirror is a review convenience, secondary to the markdown source of record.

2. **Dispatch `spec-reviewer`.**

→ Agent (subagent_type: "dev-workflows:spec-reviewer", model: `<review_model — §2 Opus chain; frontmatter-pinned, recorded, no override>`):
  > "Review the specification for this brief:
  >
  > Specification path: [absolute path to specification.md]
  > Detected maturity: test"

3. **Act on the verdict** (mirrors `/epics` Phase 7):
   - **`BLOCK`** — fix the BLOCKER findings (the orchestrator/grill edits `specification.md` inline —
     there is no delegated writer to re-dispatch) and re-review once. If still `BLOCK`, escalate per
     the `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in
     `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER individually:
     ```
     choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in the final report)", "Override and accept the finding", "Cancel the whole run", "Other… (describe)"]
     ```
     "Defer" means appending a `## Refinement notes` section to `specification.md` with a `- [ ]` item
     per deferred finding (mirrors `/epics`' Epic-refinement note), in addition to the final report.
   - **`MAJOR` / `MINOR` / `NIT`** (surfaced under `PASS WITH RECOMMENDATIONS`) — defer to the final
     report; no mandatory fix cycle.
   - **`PASS`** / **`PASS WITH RECOMMENDATIONS`** — proceed to Phase 7.

Cap: one fix cycle + one re-review maximum.

---

## Phase 7 — Handoff

Write the feature folder: `specification.md` (`Published: no`), `idea.md`, `_session.md`, `_glossary.md`, and the rendered `.html`.

Then **offer** (commit-when-asked — never automatic):
```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git", "Cancel"]
```

On the first choice, in the specs repo (`$SPECS_PATH`): create branch `spec/<KEY>_<slug>` (main is protected — a PR is required), commit ONLY the feature folder (never `git add -A`), push, and open a PR targeting `main`. **Merged-to-main = ready for the dev-team handover.** Devs and `/design` read the spec from `main`, never from the branch. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

### Jira round-trip (document to the user — they will otherwise miss it)

The end-to-end PM flow:
1. `/epics <VI>` drafts child Epic definitions.
2. **You create those Epics in Jira** (manual — `/specify`/`/epics` never call Jira).
3. **You re-import** the VI to `$VAULT_PATH/jira-products/<KEY>` so the new Epics appear in the export.
4. `/specify <each Epic>` reads the Epic from the refreshed export and authors its `specification.md`.

Steps 2–3 are the round-trip; without them `/specify` cannot see the Epics.

## Final report

Report: feature-folder path; stage/user-story/AC/TC counts; open-question count; unmounted-repo advisories; the `spec-reviewer` verdict; the PR URL (if opened); and a reminder of the round-trip described above + that `Published: yes` is a human-only freeze step.

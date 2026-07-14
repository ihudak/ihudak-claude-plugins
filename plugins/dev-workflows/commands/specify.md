---
name: specify
description: Jira-driven specification-authoring workflow (PE phase). Reads a Jira Epic/VI from exported markdown, lightly grounds in code, and authors an org-standard specification.md through a relentless one-question-at-a-time grill; gates on the Opus spec-reviewer and lands the spec on the specs repo's main branch via branch + PR for the /design dev take-over.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch LS
---

Author a product specification for the Jira item: $ARGUMENTS

`/specify` is the **PE-phase specification-authoring** workflow — the specification step of the PM→PA→PE→Dev pipeline
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
   **jira-driven only**: expect `mode: jira-driven`. The front-end owns the `$VAULT_PATH` /
   `jira-products` validation, Fallbacks A/B **and D/E**, and the VI-selector (key-or-directory) +
   focus-Epic grammar. Carry forward:
   - `jira_key` — the resolved **top-level** key: the **VI** when a focus Epic is present, or the
     stand-alone top-level item's own key otherwise.
   - `focus_key` — the **Epic** to center on within `jira_export_root`, or `null` for a bare VI /
     stand-alone item / directory.
   - `jira_export_root`, `source`.

   Define `<VI>` = `jira_key` and `<EPIC>` = `focus_key` (may be `null`). Downstream steps use these
   two symbols in place of the old single `<KEY>`.

   If the front-end returns `mode: direct` (no Jira input), stop with
   `SPECIFY_NEEDS_JIRA: /specify needs a Jira key or an imported-Jira directory.` — `/specify` has no
   direct-prompt behavior.

2. **Resolve `$SPECS_PATH`.** `/specify` writes specifications under `$SPECS_PATH/specifications/`
   (exact layout resolved in step 3) — the specs repo, not the vault. If `$SPECS_PATH` is unset, stop
   with a clear error naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`) —
   there is no vault-relative fallback for this write target the way there is for reads.

3. **Resolve the feature folder.** Derive provisional kebab-case slugs from the relevant
   Jira item title(s) (from the index/summary — finalized once `jira-reader` runs in Phase 2, but a
   provisional slug is enough to check for existing folders now): `<vslug>` for the `<VI>` title, and
   `<eslug>` for the `<EPIC>` title when `focus_key` is set.

   - **Resolve/derive the VI (top-level) dir:** `specifications/<VI>-<vslug>/`. Look for an existing
     dir at `specifications/<VI>{-|_}<vslug-or-other-slug>/` — honor an existing dir matched by
     key-number (tolerate a stray `-`/`_` after the key, and a pre-existing slug that doesn't exactly
     match a freshly-derived one — a human may have adjusted it). Create `<VI>-<vslug>` (hyphen) only
     if no such dir exists yet.
   - **Resolve the feature folder itself**, by case:
     - `focus_key` set (an Epic nested under a VI) →
       `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` — a per-Epic subfolder under the VI dir
       (`<eslug>` = kebab of the Epic title). Apply the same honor-an-existing-dir tolerance to the
       `<EPIC>-<eslug>` segment.
     - `focus_key` null **and** the item is a **VI** for which the broad-VI-spec choice is made
       (Phase 2, Step A) → `specifications/<VI>-<vslug>/specification.md` — flat at the VI-dir level, no
       per-Epic subfolder; the feature folder is the VI dir itself.
     - `focus_key` null **and** the item is a **stand-alone top-level Epic** (no parent VI) →
       `specifications/<EPIC>-<eslug>/`, where `<EPIC>` here is this item's own key (== `jira_key`,
       since `focus_key` is null) — top-level, keyed by the Epic, no VI wrapper. Physically this is
       the same dir the VI-dir step above already resolved (`specifications/<VI>-<vslug>/` with
       `<VI>` = `<EPIC>` = `jira_key`), so no separate resolution step is needed: the two null-`focus_key`
       cases share one physical target, `specifications/<jira_key>-<slug>/`, with `specification.md`
       written flat inside it either way.
   - All delimiters this step writes are hyphens; matching an existing dir tolerates a stray `-`/`_`.
     Neither the VI dir nor the feature folder is created here — the first phase that writes to it
     (Phase 2's `idea.md` write, in a fresh run) creates it.

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

Also display (for user context): resolved feature folder; resolved `jira_export_root`; resolved
`jira_key` (VI); resolved `focus_key` (Epic, or 'none — VI-level'); resolved `$REPOS_PATH`; resolved
`$SPECS_PATH`.

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

Phase 2 reads Jira in **two steps, cheap before expensive**. Step A settles *granularity* — the
input's type and, for a multi-Epic VI, *which* Epic — with a cheap `vi-plus-epics` read (and, when
needed, the progress-aware picker), resolving `focus_key`. Only then does Step B spend the full-depth
read, now scoped to the resolved Epic. This ordering resolves a null `focus_key` by a cheap
enumeration **before** any expensive full read, so the full read never pulls a whole multi-Epic VI
subtree the grill would only discard. When `focus_key` is already set on entry, Step A is skipped and
Phase 2 is just the full read (Step B).

### Step A — Resolve granularity + focus Epic (cheap enumeration + picker)

**Skip this step entirely when `focus_key` is already set on entry** — any two-token form
(`<VI-Key> <Epic-Key>`, `<dir> <Epic-Key>`) or a bare `<Epic-Key>` auto-resolved to its parent VI in
Phase 0. The Epic is already chosen, so go straight to Step B.

Otherwise (`focus_key` is null), dispatch `jira-reader` at the **cheap** `depth: vi-plus-epics` to
determine the item's type and enumerate its child Epics *without* reading the full Story/Sub-task
subtree:

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
  > depth:      vi-plus-epics"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found`
rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On
`OK`, read the item's type from `value_increment` / `linked_items` and enumerate its **child Epics**
(filter `linked_items` to `type == Epic`). Then branch — this is the reusable **progress-aware
Epic-picker pattern** documented in `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`
(§ Progress-aware Epic picker), applied here with `/specify`'s own done-predicate:

- **Stand-alone top-level Epic** (the item is itself an Epic, no parent VI) → no picker; the item
  *is* the focus. Set `focus_key` = the item (== `jira_key`). The feature folder stays the flat
  `specifications/<jira_key>-<slug>/` resolved in Phase 0 — a stand-alone Epic has no distinct parent
  VI, so `<VI>` == `<EPIC>` and there is no self-nested subfolder (Phase 0 step 3's
  shared-physical-target note). Proceed to Step B.
- **VI with exactly 1 Epic** → no picker; auto-select it. Set `focus_key` = that Epic and emit a
  one-line notice (e.g. `Single child Epic <EPIC> '<title>' — authoring its spec.`). Re-point the
  feature folder to that Epic's per-Epic subfolder (see *Re-pointing* below). Proceed to Step B.
- **VI with ≥2 Epics** → render the **progress-aware picker**, one row per child Epic. For each Epic,
  first resolve its **actual** feature folder the same way Phase 0 step 3 does: look under
  `specifications/<VI>-<vslug>/` for an existing dir matched by that Epic's key-number (tolerate a
  stray `-`/`_` after the key, and a pre-existing slug that doesn't exactly match a freshly-derived
  one), falling back to the freshly-derived `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` only when no
  such dir exists — this keeps a human-adjusted Epic dir slug from mis-displaying as ○ not-started.
  Compute each Epic's status from `/specify`'s **done-predicate** against that resolved folder:
  - **○ not started** — no `specification.md` and no `_session.md` there → selectable.
  - **◐ in progress** (resume) — a `_session.md` exists there but no `specification.md` → selectable
    as a resume; the per-Epic stage-level resume then runs in Phase 5 from that `_session.md`
    (resume *stacks* on the picker, per the shared pattern).
  - **● done** — `specification.md` exists there → shown greyed, **not** default-selectable;
    selecting it offers *revise*.
  Default cursor = the first actionable row (in-progress before not-started). Render as a `choices`
  array: one entry per Epic (its ○/◐/● marker + key + title), then an explicit
  **"Author one broad VI-level spec instead"** choice, then `"Other… (describe)"`.
  - On selecting an Epic → set `focus_key` = that Epic; re-point the feature folder to its per-Epic
    subfolder (see *Re-pointing* below).
  - On **"Author one broad VI-level spec instead"** → leave `focus_key` = null; the feature folder
    stays the flat VI-dir path `specifications/<VI>-<vslug>/` (Phase 0 step 3's `focus_key`-null VI
    case). Step B then reads the whole VI subtree.
- **VI with 0 Epics** → this VI hasn't been split yet. Offer the existing without-Epics choices:
  `choices: ["Split into Epics first with /epics, then create them in Jira and re-import (Recommended)", "Author one broad VI-level spec now", "Cancel", "Other… (describe)"]`
  `/specify` does NOT create Jira Epics itself (zero external API) — on "Split…", stop and guide the
  user through the manual round-trip (see the Phase 7 round-trip note). On "Author one broad VI-level
  spec now", leave `focus_key` = null and proceed to Step B.

**Re-pointing the feature folder after the picker.** When Step A sets `focus_key` to an Epic (the
single-Epic and ≥2-Epic-selection cases), the feature folder becomes that Epic's per-Epic subfolder
`specifications/<VI>-<vslug>/<EPIC>-<eslug>/` (Phase 0 step 3's `focus_key`-set case), superseding the
provisional VI-level folder confirmed in Phase 1 — Phase 0 already marks that folder provisional until
`jira-reader` runs. Re-detect a prior run there (a `_session.md` → a resume is available for that
Epic). The stand-alone-Epic and broad-VI-spec cases leave the Phase 0 folder unchanged.

### Step B — Full Epic-scoped read

With granularity settled and `focus_key` resolved, dispatch `jira-reader` at `depth: full` — richer
than Step A's `vi-plus-epics`, because `/specify` needs the full linked subtree (Stories/Sub-tasks) as
the raw material for user stories, acceptance criteria, and test cases; `vi-plus-epics` would starve
the grill of exactly the detail it needs.

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
  > depth:      full"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found`
rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On
`OK`:

- **Epic-scope the read.** `jira-reader` is dispatched with `jira_key` = the VI and returns the
  **whole VI** linked-item hierarchy (`jira-reader` itself is unchanged). When `focus_key` is set,
  **scope the returned hierarchy to `focus_key`'s subtree** — the Epic itself plus its linked
  Stories/Sub-tasks (`linked_items` whose `parent` chain leads to `focus_key`) — filtering
  in-orchestrator and discarding sibling Epics' subtrees before feeding the downstream phases. When
  `focus_key` is null (broad VI-level spec), use the whole VI subtree as today. Everything below —
  themes, `idea.md`, the Phase 5 raw material — derives from this scoped `focus_key` subtree.
- Extract **capability themes** and component/product mentions from the scoped subtree — feeds
  Phase 3's repo derivation and Phase 4's `code-scanner` dispatches.
- Write **`idea.md`** in the feature folder from the scoped Jira text (the focus item's summary,
  description, and its linked-item summaries) — pre-spec brainstorming provenance, in the same spirit
  as the `idea.md` convention `source-truth.md` already treats as non-authoritative once
  `specification.md` exists.
- Carry the scoped linked-item tree (the Epic's Stories/Sub-tasks) forward into Phase 5 — the raw
  material the grill mines for user stories, acceptance criteria, and test cases.

---

## Phase 2.5 — Resolve applicable ARD (optional)

Resolve any ARD for this item by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `<VI>`, `<EPIC>` (`focus_key`), and `$SPECS_PATH`. On `status: none`, **skip and proceed exactly as before**. On `status: found`, keep the spec's user stories + scope consistent with the returned `invariants` + `guidance_summary` during the Phase 5 grill; record a necessary deviation under the spec's `### Open questions` (never edit the ARD). Pass the `invariants` to `spec-reviewer` in Phase 6 as `applicable_ard`.

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

**Interview technique (grilling — embedded; no runtime dependency).** Conduct each stage as a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 4 code scan / Jira content to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write that stage's section.

Walk the stages in order, authoring `specification.md` live against `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`:

1. Header + **Problem statement**
2. **Scope** (In/Out)
3. **User stories** (`[Uxx]`)
4. **Acceptance criteria** (`[ACxx]`, EARS)
5. **Test cases** (`[TCxx]`)

As each decision settles, append it to `_session.md`; capture a genuinely-ambiguous term in `_glossary.md`. Resolve open questions to zero where possible; leave genuinely unresolvable ones as `- [ ]` and keep the header **Open questions** count in sync. A repo gap surfacing here → escalate (describe the missing capability + why) and STOP; the run is resumable from `_session.md` after the user remounts and re-invokes.

---

## Phase 5.5 — Structural pre-lint

Before finalizing, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `specification.md`: the **Universal
checks** plus the **spec** block (incl. the `- **Open questions**: N` header equalling the `- [ ]`
count). Surface every finding; inline-fix the mechanical ones (renumber a duplicate `[Uxx]`/`[ACxx]`/
`[TCxx]`, correct the open-questions count, delete a stray placeholder token); leave content gaps for
the grill/author. **Advisory** — never blocks; proceed to Phase 6 once findings are surfaced.
`spec-reviewer` remains the gate.

## Phase 6 — Finalize + review gate

1. **Render HTML.** `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/specification-to-html.py" <spec path>`
   against the `specification.md` written in Phase 5. On failure, report the error and proceed — the
   HTML mirror is a review convenience, secondary to the markdown source of record.

2. **Dispatch `spec-reviewer`.**

→ Agent (subagent_type: "dev-workflows:spec-reviewer", model: `<review_model — §2 Opus chain; frontmatter-pinned, recorded, no override>`):
  > "Review the specification for this brief:
  >
  > Specification path: [absolute path to specification.md]
  > Detected maturity: test
  > applicable_ard: [the ARD invariants resolved in Phase 2.5, or omit if none]"

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

On the first choice, in the specs repo (`$SPECS_PATH`): create the branch — `spec/<EPIC>-<eslug>` for a **per-Epic** spec (a VI + focus Epic) or a **stand-alone-Epic** spec (`<EPIC>` = `focus_key`, which for a stand-alone Epic equals `jira_key`), or `spec/<VI>-<vslug>` for a **broad VI-level** spec (`focus_key` null). Epic keys are globally unique, so the per-Epic form needs no VI prefix; both forms use hyphens. main is protected — a PR is required — so commit ONLY the feature folder (never `git add -A`), push, and open a PR targeting `main`. **Merged-to-main = ready for the dev-team handover.** Devs and `/design` read the spec from `main`, never from the branch. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

### Next Epic (after a per-Epic spec from a multi-Epic VI)

When this run authored a **per-Epic** spec that was selected from Step A's ≥2-Epics picker, offer — once Phase 7's write/commit completes — to continue with a sibling Epic under the same VI:
```
choices: ["Next Epic — re-open the picker (Recommended)", "Stop here", "Other… (describe)"]
```
On **"Next Epic"**, **re-render the Phase 2 Step A progress-aware picker minus the just-completed Epic** — recompute each remaining Epic's ○/◐/● state from its feature folder, so the freshly-authored spec now shows **● done** and drops out of the actionable set — then, on selection, set `focus_key` to the new Epic and loop back through Phase 2 Step B → Phases 3–7 for it. This offer does **not** apply to a stand-alone Epic, a single-Epic VI, or a broad VI-level spec — there is no sibling to advance to.

### Jira round-trip (document to the user — they will otherwise miss it)

The end-to-end flow:
1. `/epics <VI>` drafts child Epic definitions.
2. **You create those Epics in Jira** (manual — `/specify`/`/epics` never call Jira).
3. **You re-import** the VI to `$VAULT_PATH/jira-products/<KEY>` so the new Epics appear in the export.
4. `/specify <each Epic>` reads the Epic from the refreshed export and authors its `specification.md`.

Steps 2–3 are the round-trip; without them `/specify` cannot see the Epics.

## Phase 8 — Session maintenance & feedback

Terminal phase — runs after Phase 7 and before the Final report is presented;
NEVER interrupts an earlier phase. `/specify` has no built-in maintenance agent,
so this phase invokes `impl-maintenance` on the Sonnet detection chain and then
persists the plugin-facing slice of its report as session feedback.

**Capture-at-block invariant.** This terminal phase captures gaps for a *completed* run. Separately, if an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating — so a run abandoned at the block still records the gap. NEVER `emit-block` for a work-quality review BLOCK or an environment / user halt (repo/spec gate, jira-not-found, cancellation).

**Session-hygiene invariant.** End the report with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (`resume.md`), then a
span suggestion (VI-level→`/epics` `/compact`; Epic-level→`/design` `/clear`) +
`/rename <VI-ID>-<slug>-pe`. Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /specify
   > - What was done: [one-paragraph summary of the specification authored]
   > - Key events: [BLOCK reviews and their reason, unmounted-repo soft-gate advisories, unresolved open questions, picker / round-trip friction — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: [the spec-reviewer verdict — PASS | PASS WITH RECOMMENDATIONS | BLOCK]
   > - Test result: N/A (no tests in /specify)
   > - Project root: [the resolved feature folder under $SPECS_PATH]"
2. **Persist plugin feedback (automatic).** Project the report's plugin-facing
   slice into the specs repo by citing
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
   `emit-auto` entry point (§6). Pass the Lessons Learned report,
   `command: /specify`, the run's `jira_key` and `source`, and `plugin_version`
   (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
   renders only the report's **Command workflow improvements**, **New agents /
   skills**, and plugin **Reference docs** sections plus the **Key observations**
   that triggered them (§4) — never target-project `CLAUDE.md`/hook advice — as
   `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via
   the §2 specs-first ladder, and writes silently.
3. **Surface** the persisted path (or "no plugin-facing signal — nothing
   persisted") as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in
Phase 7), and NEVER writes into the current working directory. The specs-first
ladder writes the feedback file inside `$SPECS_PATH`, alongside the feature
folder — the intended home.

## Phase 9 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 8 (feedback)
and NEVER interrupts an earlier phase. Records this command's token-cost
contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /specify`, `phase: specification`, `role: pe`,
the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in
Phase 7), and NEVER writes into a docs/code repo or the current working
directory; no user name is ever written (§10 privacy).

## Final report

Report: feature-folder path; stage/user-story/AC/TC counts; open-question count; unmounted-repo advisories; the `spec-reviewer` verdict; the PR URL (if opened); and a reminder of the round-trip described above + that `Published: yes` is a human-only freeze step.

### Next step

End the report with a `### Next step` recommendation per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` (guidance only — never auto-invoked): **Epic-level spec** (`<VI> <Epic>`) → hand to the team → `/design <VI> <Epic>`, and the **Epic fan-out** `/specify <VI> <another-Epic>` for a sibling Epic (breadth); **VI-level spec** (`<VI>` only) → `/epics <VI>` (PE). If the run BLOCKED or left open `- [ ]` items, recommend resolving those first.

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:

- **VI-level spec → `/epics <VI>` (still PE)?** → run **`/compact`** — context still relevant.
- **Epic-level spec → Team `/design <VI> <Epic>` (even yourself)?** → run **`/clear`** for a clean slate.
- Consider **`/rename <VI-ID>-<slug>-pe`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

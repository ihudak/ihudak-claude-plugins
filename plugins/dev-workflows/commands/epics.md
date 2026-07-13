---
name: epics
description: Jira-driven Epic-writing workflow. Reads a Value Increment and existing Epics from exported markdown, optionally scans code repos, drafts child Epic definitions, and gates on dt-style-checker and Opus epic-reviewer.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Draft child Epics for the Jira Value Increment: $ARGUMENTS

`/epics` is the **Jira-driven Epic-writing** workflow. Given a Value Increment key, it reads the VI plus its existing Epics from pre-exported markdown in the user's Obsidian vault, optionally scans code repos to identify reusable capabilities and gaps, drafts child Epic definitions as markdown files under the resolved output directory, and gates the result on an Opus review.

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
   `jira-products` validation and Fallbacks A/B. Carry `jira_key`,
   `jira_export_root`, and `focus_key` forward. Downstream, `<JIRA_KEY>` and
   `<VI-KEY>` both denote this `jira_key`.

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
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader, code-scanner, dt-style-checker, doc-fixer, epic-writer (MODERATE)
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
- Proposed Epic sizing/sequencing — prefer fewer, larger Epics where the VI direction is validated; split only at a genuine risk / feedback-loop boundary; order so that no Epic depends on a later one

Ask:
```
"Epic drafting plan ready. What would you like to do?"
choices: ["Approve & continue (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → proceed to Phase 3
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarise what was planned

---

## Phase 2.5 — Resolve applicable ARD (optional)

Resolve any VI-level ARD for this VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `vi = jira_key`,
**`epic: null`** (Epics do not exist yet — VI-level ARD only), and `$SPECS_PATH`.

- On `status: none` (including `$SPECS_PATH` unset/unresolvable) → **skip and
  proceed exactly as before.** No prompt, no extra output.
- On `status: found` → carry `invariants` + `guidance_summary` forward: pass them
  to `epic-writer` (Phase 6 handoff, as `applicable_ard`) so drafts stay
  consistent with the `AD-N`, and to `epic-reviewer` (Phase 7, as `applicable_ard`)
  which then activates its ARD-conformance dimension. A necessary deviation is
  recorded by the writer in the Epic draft (`- ARD deviation: … flag: architect`)
  and surfaced in the Phase 9 report — never edit the ARD.

---

## Phase 2.6 — VI-level spec enrichment (optional)

If a VI-level specification exists, fold its requirements into the coverage
inventory. **Additive, zero-cost when absent** — the common case, since
`/specify` usually runs per-Epic *after* `/epics`.

1. **Resolve the VI dir:** `$SPECS_PATH/specifications/<VI>-<vslug>/`, matched by
   key-number, tolerating a stray `-`/`_` and a human-adjusted slug (the same
   rule `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` step 1 uses). If
   `$SPECS_PATH` is unset/unresolvable, or no VI dir matches → **skip** (set
   `vi_spec_present: false`).
2. **Detect:** if `<VI-dir>/specification.md` does not exist → **skip** (set
   `vi_spec_present: false`); the run proceeds byte-identically to today.
3. **Parse** `<VI-dir>/specification.md` directly (Read it — one file, a simple
   heading scan): extract its user stories `[Uxx]` and their nested acceptance
   criteria `[ACxx]` into `vi_spec_requirements[]`. **Skip `[TCxx]` test cases**
   (per-AC, non-unique, below Epic granularity) and the prose sections
   (Problem/Scope). Because `[ACxx]` numbering restarts per story, qualify each
   `spec-criterion` id with its parent story (`<Uxx>/<ACxx>`) so every `Req` id
   in `_coverage.md` is unique; `spec-story` `[Uxx]` ids are document-unique and
   used as-is:

   ```yaml
   vi_spec_requirements:
     - id:   <Uxx (story) | <parent-Uxx>/<ACxx> (criterion)>   # spec-story id is document-unique; qualify criterion ids with the parent story
       type: spec-story | spec-criterion
       text: <requirement text>
   ```

   Set `vi_spec_present: true` and record the resolved `specification.md` path
   for the Phase 9 report.

---

## Phase 3 — Read Jira hierarchy

Invoke `jira-reader` with `depth: vi-plus-epics`. This depth is specifically designed for Epic writing: richer than `vi-only` so themes extracted for `code-scanner` aren't starved of context, but lighter than `full` so the agent doesn't read dozens of already-closed child Stories.

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
  > depth:      vi-plus-epics"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On `OK`, carry the handoff `requirements[]` and `requirements_source` forward —
they are the coverage ground truth for Phases 6–7.

When Phase 2.6 set `vi_spec_present: true`, **append** its
`vi_spec_requirements[]` to this `requirements[]` — the VI's own rows are
unchanged; the appended rows carry `type: spec-story` / `spec-criterion`, which
separates them from the VI's `story`/`criterion` rows. The merged list flows
unchanged into the Phase 6 handoff and the Phase 7 reviewer brief. When
`vi_spec_present: false`, `requirements[]` is exactly what `jira-reader` returned.

On `OK`, identify the Epics already linked to the VI (filter `linked_items` to `type == Epic`) — the new Epic drafts MUST NOT duplicate their scope (enforced later by `epic-reviewer`).

**Refinement target (`focus_key`).** `/epics` always reads and analyses the whole VI
(the partition and non-duplication logic are inherently VI-holistic). When `focus_key`
is set (explicit `<VI> <Epic>`), validate it is among the linked Epics; if it is not,
surface `EPICS_FOCUS_NOT_FOUND: <focus_key> is not a linked Epic of <jira_key>.` and
offer `choices: ["Proceed VI-level (draft the full partition)", "Re-enter the Epic key", "Cancel"]`.
When present, treat `focus_key` as the **single refinement target**: Phase 6 re-drafts
only that Epic's definition, and Phase 7 reviews only that file. The non-duplication
set (`existing_epics`) is the *other* linked Epics — exclude the focus Epic so Phase 6
re-emits it rather than skipping it as a duplicate. When `focus_key` is null, behaviour
is unchanged (draft the full partition of new Epics).
When `focus_key` is set, `mode = refine` and `refinement_targets = [the focus Epic]` — Phase 6 iterates on its current imported content (see `epic-writer` refinement mode) rather than regenerating from the VI alone.

**Refinement candidates.** From the same `linked_items` (`type == Epic`), read the additive per-Epic fields `refinement_candidate`, `team`, and `scope_hint` (emitted by `jira-reader` at `vi-plus-epics`). Collect `refinement_candidates` = every linked Epic with `refinement_candidate: true`. These are empty/almost-empty team-Epic shells the PE pre-created to encode team boundaries — refinement *targets to fill in*, not non-duplication constraints. This set drives the Phase 3.5 gate.

---

## Phase 3.5 — Refinement-mode gate (conditional)

Runs only when `focus_key` is set OR `refinement_candidates` is non-empty. Otherwise skip silently — `mode = generate`, behaviour byte-identical to the legacy net-new flow.

**Focus key set** → `mode = refine`, `refinement_targets = [focus Epic]`; skip the mode question (the PE named the target explicitly).

**No focus key, `refinement_candidates` non-empty** → present the detected set as a CONFIRMABLE list (detection only *proposes*; the PE is the authority) and ask the mode:
```
Detected N empty/almost-empty team-Epic shells linked to <jira_key>:
  - <EPIC-KEY> · <team, or "team: [NEEDS CLARIFICATION]"> · <scope_hint>
  ...
choices: ["Refine these N (partition the VI across them) (Recommended)", "Generate net-new Epics (ignore the shells)", "Both — refine the shells and draft net-new for leftover scope", "Let me adjust which shells to refine (you'll be prompted)", "Other… (describe)"]
```
Record `mode` (`refine` | `generate` | `both`) and the confirmed `refinement_targets` (empty for `generate`). A target whose `team` is empty carries a `[NEEDS CLARIFICATION — team]` note into the writer handoff.

**Adaptive code-scan default (refine / both only).** Re-surface the code-examination choice now that the target count is known — the Phase 1 answer was given before detection. Default **ON when `len(refinement_targets) >= 2`** (a real cross-team boundary to draw), **OFF when == 1**:
```
choices: ["<adaptive default> (Recommended)", "<the other setting>", "Keep my Phase 1 choice", "Other… (describe)"]
```
with a one-line rationale ("2+ team-Epics → code context helps draw the boundary" / "single Epic → no cross-team boundary; scan off is faster"). This runs ONLY in the refine branch, so the generate / no-candidate path never sees it (no-regression).

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

The drafting is delegated to the **`epic-writer`** subagent (pinned to the §2.1 Sonnet detection chain for MODERATE; §2 Opus only if the run is SIGNIFICANT/HIGH-RISK — see `classification.md` §9.2). The orchestrator prepares a handoff and dispatches; it does not write Epics itself, and **nothing commits** (epics never branches/commits — git is the user's responsibility).

1. **Write the handoff file.** Create a temp file (`mktemp` — never the vault, never a repo) containing the `epic-writer` input contract: `jira_reader_handoff`, `code_scanner_outputs` (empty if no scan), `scope` (Phase 2 in/out of scope), `existing_epics` (non-duplication), `output_dir` (resolved Phase 1 dir), `vi_goal`, `jira_key`, `requirements` + `requirements_source` (from Phase 3), `applicable_ard` (the Phase 2.5 invariants + guidance_summary, or omit when status was none), `existing_epic_themes` (themes of the already-linked Epics), `mode` (`generate` | `refine` | `both` — from Phase 3.5; `generate` when 3.5 skipped), and `refinement_targets` (list of `{key, team, scope_hint, current_body_path}`, where `current_body_path = <jira_export_root>/<EPIC-KEY>/<EPIC-KEY>.md`; empty in `generate` mode). Record its absolute path. When `focus_key` is set (the Phase 3 refinement target), set `scope` in-scope to just the focus Epic and `existing_epics` to the *other* linked Epics, so `epic-writer` re-drafts the single focus Epic's definition file; `output_dir` is unchanged.

2. **Dispatch the writer:**

→ Agent (subagent_type: "dev-workflows:epic-writer", model: `<detection_model — §9 / §2.1 Sonnet chain; planning_model (§2 Opus) only if classification is SIGNIFICANT/HIGH-RISK>`):
  > "Write the child Epic definitions for this brief.
  >
  > handoff_file: [absolute path of the temp handoff file from step 1]"

3. **Handle the return.** `status: DONE` → record `files_written` for Phase 6.1 onward. `status: BLOCKED` → surface the named gap:
   ```
   choices: ["Provide the missing input (you'll be prompted)", "Cancel"]
   ```
   On a provided value, rewrite the handoff and re-dispatch once. Nothing is committed (git is the user's responsibility).

   Also record `coverage_file` (the `_coverage.md` path) and `clarifications_needed[]` for Phases 6.2 and 7.

---

## Phase 6.2 — Resolve clarifications

If the writer returned a non-empty `clarifications_needed[]`, resolve it BEFORE
the style check and review (so no review cycle is spent on known unknowns).
Present ONE batched prompt listing every marker grouped by Epic; for each:
```
choices: ["Use the writer's suggested answer", "I'll answer (you'll be prompted)", "Leave unresolved", "Other… (describe)"]
```
Fold each resolved answer into the affected Epic draft (Edit the file inline, or
re-dispatch `epic-writer` once with the resolutions). Markers the user chooses to
**leave unresolved** stay visible in the draft and become `epic-reviewer`
BLOCKERs in Phase 7. If `clarifications_needed[]` is empty, this phase is a
**silent no-op** (byte-identical to a run without it).

**Leftover disposition (refine / both only).** After the writer returns, read `_coverage.md`; every `❌ gap` row is a VI requirement no team-Epic covers. In ONE batched prompt, ask per gap:
```
choices: ["Assign to team-Epic <KEY> (re-drafts that Epic to include it)", "Propose as a new (net-new, slug-named) Epic", "Defer (leave as an uncovered row)", "Other… (describe)"]
```
Fold the results back: *assign* → re-dispatch `epic-writer` once (or Edit inline) to add the requirement to the named target's `## Covers` + scope; *new Epic* → add a slug-named net-new draft; *defer* → the row stays `❌ gap` in `_coverage.md` and is listed in the Phase 9 report. Reuses the same batched-gate pattern as the clarification resolution above; no gaps → silent no-op.

---

## Phase 6.1 — Dynatrace style check

Invoke `dt-style-checker` on the files written in Phase 6. Unlike `/document` (Jira mode), this does NOT use `docs-style-checker` (no repo linter for vault content). Instead, the Dynatrace corporate style guide checker validates terminology, trademarks, voice/tone, and inclusive language.

→ Agent (subagent_type: "dt-style-guide:dt-style-checker", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > files:    [absolute paths of every Epic file written in Phase 6]
  > doc_type: epic
  > emphasis: terminology and customer-facing captions, labels, messages, and text"

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

## Phase 6.3 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against each drafted Epic file: the **Universal checks**
plus the **Epic** block (required headings incl. `## Independent Test`; Given/When/Then acceptance
criteria; `[NEEDS CLARIFICATION]` ≤ 3 per Epic; `_coverage.md` present). Surface every finding;
inline-fix the mechanical ones (delete a stray placeholder token); leave content gaps for the author.
**Advisory** — never blocks; proceed to Phase 7 once findings are surfaced. `epic-reviewer` remains the
gate.

## Phase 7 — Epic review gate

Invoke `epic-reviewer` (Opus). This reviewer is Epic-specific — scope clarity, acceptance-criteria testability, non-duplication of existing Epics. `docs-style-checker` is NOT used here (no repo linter for vault content); Dynatrace corporate style is handled by the Phase 6.1 `dt-style-checker` step above.

→ Agent (subagent_type: "dev-workflows:epic-reviewer"):
  > "Review the Epic drafts for this brief:
  >
  > Task description: [one-paragraph: VI key, VI goal, number of Epics drafted]
  > Written Epic file paths: [absolute paths of every Epic file written in Phase 6]
  > jira-reader handoff: [paste full YAML from Phase 3]
  > code-scanner output:  [paste array of per-repo scanner outputs from Phase 5, or 'N/A — code scan off']
  > requirements:        [paste the requirements[] array from Phase 3]
  > _coverage.md path:    [absolute path of the coverage file from Phase 6]
  > applicable_ard:       [the Phase 2.5 invariants, or omit if status was none]"

When `mode` is `refine`/`both`, include `refinement_targets` in the `epic-reviewer` brief so its conditional refinement dimensions (completeness, partition integrity, cross-team dependency sanity, team preserved) activate; omit it in `generate` mode so those dimensions report N/A.

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
(In `refine`/`both` mode, refined Epics are identified by key `<EPIC-KEY>`, not slug.)
Epic-review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
```

Then spawn all four maintenance agents in a **single Agent message**. They are independent and run concurrently.

**Agent 1 — Documentation** (general-purpose):
> "Post-write documentation review. Change summary:
> [paste change summary block]
>
> The project root is an Obsidian vault when `$VAULT_PATH` is set, else the resolved output directory; look only for internal documentation files that reference Epic drafts (e.g., a `jira-drafts/README.md` or an index page enumerating active drafts).
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

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /epics`, the run's `jira_key` and `source`, and `plugin_version`
(read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
renders only the report's **Command workflow improvements**, **New agents /
skills**, and plugin **Reference docs** sections plus the **Key observations**
that triggered them (§4 plugin-facing predicate) — never target-project
`CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id`
(§3), resolves the target via the §2 specs-first ladder, and writes silently.
List the persisted path (or "no plugin-facing signal — nothing persisted") in
the Phase 9 report's Session learnings line. ADDITIVE — the impl-maintenance
report still appears in the report; this step NEVER fails the run, NEVER
commits, and NEVER writes into `jira-products/`, `jira_export_root`, or the
current working directory.

---

## Phase 9 — Final Report

Output a structured report — do NOT ask any closing confirmation:

**When `mode` is `refine`/`both`,** begin the report with a `Mode: <refine | both>` line and split the written-Epics listing into three labelled groups: **Refined** (keyed `<EPIC-KEY>.md`), **Net-new** (slug-named), and **Deferred** (VI requirements left uncovered via the Phase 6.2 leftover gate). In `generate` mode the report is unchanged.

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

### Requirement coverage
[Roll-up verdict + N/M covered (P%); list each ❌ gap requirement ID; _coverage.md path] If Phase 2.6 enriched the inventory, also name the VI-level `specification.md` path and the count of `spec-*` rows added. — _or_ "derived (coarse) — VI had no structured requirements"

### Clarifications
[Resolved: <n>; Deferred (left unresolved → became blockers): <n>] — _or_ "none raised"

### ARD conformance
[verdict + any `- ARD deviation:` lines recorded] — _omit this whole section when Phase 2.5 status was none_

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
The project root has uncommitted changes. `/epics` never commits — git management is your responsibility.

### Next step
[Per `references/next-phase-offer.md` — guidance only, never auto-invoked. For each Epic just drafted, author its spec → `/specify <VI> <Epic>` (PE); the **Epic fan-out** (depth vs breadth) applies from the spec/design stage on. Optionally a Product Architect adds an Epic-level ARD first → `/create-ard <VI> <Epic>`. If the review BLOCKED, resolve that first.]

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:

- **Continuing as PE (`/specify <VI> <Epic>`)?** → run **`/compact`** — context still relevant.
- **Handing to PA (`/create-ard <VI> <Epic>`), even yourself?** → run **`/clear`** for a clean slate.
- Consider **`/rename <VI-ID>-<slug>-pe`** to relocate this session later.

Guidance only — see `references/session-hygiene.md`.
```

---

## Phase 10 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 9 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's manual-step / out-of-scope
follow-ups by citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md`
and executing its steps inline.

1. **Collect** the qualifying follow-ups: the manual publish step ("create these
   drafted Epics in Jira manually" — the drafts are vault/dir files, not Jira
   tickets) and the Phase 9 `### Deferred items` that are out-of-scope refinement.
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder using `jira_key` and `source`;
   render + place tasks and verbose notes per §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 9 report. This phase NEVER
fails the run, NEVER commits (git is the user's responsibility), and NEVER
writes into `jira-products/`, `jira_export_root`, or the current working
directory.

---

## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /epics`, `phase: epic-refinement`, `role: pe`,
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

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is the user's
responsibility), and NEVER writes into `jira-products/`, `jira_export_root`, or
the current working directory; no user name is ever written (§10 privacy).

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, jira-not-found, cancellation)
- ALWAYS resolve input via the shared Jira-input front-end (Phase 0) — a JiraID requires `$VAULT_PATH`; an imported-Jira directory works without it; `/epics` is cwd-agnostic and rejects `mode: direct`
- NEVER create a git branch (this command never branches)
- NEVER commit (git management is the user's responsibility)
- NEVER write inside `jira-products/` — re-created on every import; writes would be lost
- NEVER write inside `_archive/` — read-only by convention
- NEVER write inside `jira_export_root` — it is re-created on every Jira import, so drafts there would be lost (the Phase 1 path-safety guard enforces this for the derived `epic-drafts/` default)
- ALWAYS write to the resolved `output_dir` — `$VAULT_PATH/jira-drafts/<jira_key>/` when `$VAULT_PATH` is set, else `<parent-of-jira_export_root>/epic-drafts/<jira_key>/` (or the user-confirmed alternative) — auto-create the directory if missing
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS invoke `epic-reviewer` before Phase 8 maintenance
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin each subagent dispatch to its §9 chain via `model:` — the mechanical steps (`jira-reader`, `code-scanner`, `dt-style-checker`, `doc-fixer`) and `epic-writer` (MODERATE) to the §2.1 Sonnet chain; `epic-reviewer` keeps its frontmatter Opus pin (no override); coordination + interactive gates run on `current_model`
- ALWAYS delegate Phase 6 writing to the `epic-writer` subagent (write-only); the orchestrator never writes Epics itself and never commits (git is the user's responsibility)
- ALWAYS cap review/fix cycles: 1 fix + 1 re-review max
- ALWAYS pass `Change type: docs` in the Phase 8 change summary block
- ALWAYS pass `Command run: /epics` in the Phase 8 Agent 4 session handoff
- ALWAYS spawn Phase 8 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 9 report as the final output
- ALWAYS end the Phase 9 report with a `### Next step` recommendation (per `references/next-phase-offer.md`) — guidance only, never auto-invoked
- ALL written claims must be traceable to Jira keys (from `jira-reader`) or code paths (from `code-scanner`); do not invent content the sources don't contain
- NEVER run `docs-style-checker` — Epic drafts are vault-internal and not subject to product-docs prose linting. Dynatrace corporate style is checked via `dt-style-checker` in Phase 6.1 instead.
- ALWAYS have `epic-writer` write `_coverage.md` to `output_dir` (VI-holistic, even in focus mode); it is NOT a Jira Epic and is never pasted to Jira
- ALWAYS run the Phase 6.2 clarification gate when the writer returns clarifications; unresolved-by-choice markers become `epic-reviewer` BLOCKERs
- ARD steps (Phase 2.5, writer/reviewer `applicable_ard`, the Phase 9 ARD section) are ADDITIVE and guarded on `status: found` — a run with no ARD is byte-identical to before
- ALWAYS pass `requirements[]`, the `_coverage.md` path, and `applicable_ard` (when found) to `epic-reviewer`
- ALWAYS treat linked Epics flagged `refinement_candidate: true` as fill-in targets (not non-duplication constraints) once the Phase 3.5 gate selects `refine`/`both`; the confirmed target set is the PE's, not the raw detection
- ALWAYS write refined team-Epics to `<output_dir>/<EPIC-KEY>.md` (keyed by real Jira id) and net-new Epics to `<output_dir>/<slug>.md`; refined files carry a `**Team:**` line
- ALWAYS re-surface the code-scan default adaptively in Phase 3.5 for refine/both (ON at ≥2 targets, OFF at 1) — never in the generate path
- ALWAYS run the Phase 6.2 leftover-disposition gate in refine/both when `_coverage.md` has `❌ gap` rows; silent no-op when none
- Refinement mode (Phase 3.5 gate, `refinement_targets` handoff, leftover gate, keyed output) is ADDITIVE and guarded — no `refinement_candidate` targets AND no `focus_key` ⇒ `mode = generate` and the run is byte-identical to the legacy net-new flow
- ALWAYS end the Phase 9 report with a `### Context hygiene` block per `references/session-hygiene.md` — prepare-first (`resume.md`), then a role-aware `/compact`|`/clear` suggestion + `/rename <VI-ID>-<slug>-pe`; guidance only, never auto-run.

---
tags:
  - tasks-exclude
---
# `/epics` Refinement & VI-Partition Mode — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an auto-detected refinement mode to `/epics` that fills in empty team-Epic shells and partitions the VI scope across them, without adding a new command.

**Architecture:** Additive, guarded changes across five markdown files (`jira-reader` emits detection fields → `epics.md` gates + routes → `epic-writer` fills keyed Epics + coverage → `epic-reviewer` gains conditional dimensions → references note the behavior) plus a lock-step version bump. The generate-net-new path stays byte-identical.

**Tech Stack:** Markdown command/agent/reference files + JSON manifests. NO test framework — every "verify" step is structural (`grep -n`, `python3 -c json.load`, `git diff --stat`).

## Global Constraints

Every task implicitly includes these — copied verbatim from the spec / standing rules:

- **Version:** bump `plugins/dev-workflows/.claude-plugin/plugin.json` line 3 and repo-root `.claude-plugin/marketplace.json` line 12 in **lock-step** `2.27.0 → 2.28.0`.
- **Count strings byte-identical:** the description lines (`plugin.json:4`, `marketplace.json:13`) must keep "Twenty slash commands", "Thirty reusable subagents", "four hooks" — **no new command, no new agent**. Verify no `+`/`-` on those two lines in the diff.
- **The two description strings are identical text** (one is indented deeper) — if either is touched, both change in lockstep. This task does NOT touch them.
- **Commit named files only** — never `git add -A`.
- **Commit trailer EXACTLY:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Siblings byte-identical:** `dt-style-guide` (0.2.2) and `obsidian-llm-wiki` (0.3.1) — 0-line diff.
- **Never write to `jira-products/`** — refined output goes to `$VAULT_PATH/jira-drafts/<VI-KEY>/`, refined team-Epics keyed `<EPIC-KEY>.md`, net-new Epics slug-named `<slug>.md`.
- **Team** is read verbatim from the imported Epic frontmatter `team:` key (fallback: the `## Metadata` `**Team:**` line); `""` → `[NEEDS CLARIFICATION — team]`. Keep the `[DTT]` prefix, do not parse it.
- **No-regression anchor:** `/epics <VI>` with no `refinement_candidate` targets AND no `focus_key` ⇒ `mode = generate` and the run is byte-identical to 2.27.0. `/vuln`, `/upgrade`, siblings untouched.
- **CHANGELOG heading format:** `## [2.28.0] — 2026-07-13` (square-bracket version, spaced em-dash ` — `, ISO date).
- **Anchor correction:** the `<NEW-EPIC-SLUG>.md` filename rule is in `commands/epics.md:47`, NOT `epic-writer.md`.
- **Branch:** work on `ivgu/NOISSUE-epics-refine-partition` (never implement on `main`).
- **Model routing (for the SDD controller):** all implementers + reviewers on **Sonnet** — this is a small prose/JSON diff, no code.

**Repo:** `/workspace/ihudak-claude-plugins`. All paths below are relative to it unless absolute.

---

### Task 1: `jira-reader` — additive detection fields

**Files:**
- Modify: `plugins/dev-workflows/agents/jira-reader.md` (the `depth: vi-plus-epics` bullet ~line 43; the `linked_items[]` block in the handoff YAML, lines 123-129)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: three additive per-Epic fields on `linked_items[]` entries, populated ONLY for `type == Epic` at `depth: vi-plus-epics`:
  - `refinement_candidate: true | false`
  - `team: <verbatim string | "">`
  - `scope_hint: <description free-text | summary>`
  (Tasks 2, 3, 4 read these names verbatim.)

- [ ] **Step 1: Add the three fields to the `linked_items[]` handoff block.** In the YAML handoff (lines 123-129), the Epic entry currently ends at `role:`. Insert after the `role:   root | linked | epic_child` line, indented to match:

```yaml
    # Epic-only, populated ONLY at depth: vi-plus-epics (absent at other depths):
    refinement_candidate: true | false   # true = empty/almost-empty shell (no real Scope/Description/AC beyond summary + importer boilerplate)
    team: <verbatim, e.g. "[DTT] Team Storage"; "" if absent>
    scope_hint: <the Epic's description/scope free-text if present, else its summary>
```

- [ ] **Step 2: Add the detection prose after the `vi-plus-epics` bullet (line 43).** Insert a new indented paragraph immediately after the existing `depth: vi-plus-epics` bullet:

```markdown
   For each Epic read at `vi-plus-epics`, also parse its YAML frontmatter and body and emit three additive fields on its `linked_items[]` entry (Epic-only, this depth only — absent elsewhere, so other consumers are unaffected):
   - `team` — verbatim from the Epic frontmatter `team:` key; fall back to the `**Team:**` line in the `## Metadata` section; `""` when neither is present. Keep the value verbatim (e.g. `[DTT] Team Storage`) — do not strip the bracketed org-unit prefix.
   - `refinement_candidate` — `true` when the Epic body carries no substantive free-text beyond its summary and the importer's structured boilerplate (`## Metadata`, a `## Details` field-dump of counts, `## Comments`): i.e. no populated `## Description`/scope/acceptance content, or such content merely restates the summary. `false` when the Epic already has real scope/acceptance prose. Heuristic only — it *proposes* refinement targets; the `/epics` Phase 3.5 gate lets the PE confirm/adjust the set.
   - `scope_hint` — the Epic's dedicated description/scope free-text when present, else its `summary`.
```

- [ ] **Step 3: Verify the additions are present and additive.**

Run: `grep -nE 'refinement_candidate|scope_hint|Keep the value verbatim' plugins/dev-workflows/agents/jira-reader.md`
Expected: matches for `refinement_candidate` (2×: YAML + prose), `scope_hint` (2×), and the verbatim-team line.

Run: `git diff --stat plugins/dev-workflows/agents/jira-reader.md`
Expected: only this one file changed; additions only (no deletions of existing handoff fields).

- [ ] **Step 4: Commit.**

```bash
git add plugins/dev-workflows/agents/jira-reader.md
git commit -m "feat(jira-reader): emit refinement_candidate/team/scope_hint at vi-plus-epics

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `epic-writer` — refinement mode

**Files:**
- Modify: `plugins/dev-workflows/agents/epic-writer.md` (handoff-inputs list lines 13-21; add a new `## Refinement mode` section; coverage-matrix rules ~line 124; the Epic template header ~line 42)

**Interfaces:**
- Consumes (from Task 1): `linked_items[].refinement_candidate/team/scope_hint`.
- Consumes (from Task 4's handoff): `mode: generate | refine | both` and `refinement_targets[]` = `{key, team, scope_hint, current_body_path}`.
- Produces: refined Epic files keyed `<key>.md` carrying a `**Team:** <team>` line; `_coverage.md` "Covered by" values `<KEY> (refined)` / `<slug> (new)` / `<KEY> (exist)`. (Task 3 reviews these; Task 4 reads `files_written[]`/`coverage_file`.)

- [ ] **Step 1: Add `mode` + `refinement_targets` to the handoff-inputs list.** After the `existing_epic_themes` bullet (line 21), append:

```markdown
- `mode` — `generate` (net-new Epics, the legacy default), `refine` (fill in / re-refine the `refinement_targets`), or `both`.
- `refinement_targets` — list of `{key, team, scope_hint, current_body_path}` for the empty/existing Epics to fill in (present only when `mode` is `refine` or `both`; empty otherwise). `current_body_path` is the imported Epic file, e.g. `<jira_export_root>/<EPIC-KEY>/<EPIC-KEY>.md`.
```

- [ ] **Step 2: Add the `**Team:**` line to the Epic template.** In the template (lines 41-82), the block opens `# <Epic title>` then a blank line then `## Goal`. Insert a `**Team:**` line between the title and `## Goal` so refined files are self-describing (net-new Epics simply omit it / leave it blank):

Change the template top from:
```markdown
# <Epic title>

## Goal
```
to:
```markdown
# <Epic title>

**Team:** <assigned team, refinement mode only — verbatim, e.g. [DTT] Team Storage; omit this line for net-new Epics>

## Goal
```

- [ ] **Step 3: Add the `## Refinement mode` section.** Insert immediately BEFORE the `## Coverage matrix (`_coverage.md`)` heading (currently line 109):

```markdown
## Refinement mode (`mode: refine | both`)

When `mode` is `refine` or `both`, treat every entry in `refinement_targets[]` as an Epic to **fill in**, not a duplicate to avoid:

- **Iterate, don't regenerate.** Read the target's `current_body_path` (the imported Epic file) first. Preserve any real scope/acceptance content already there; fill the gaps and improve — never blow away existing substance.
- **Keyed filename.** Write each refined Epic to `<output_dir>/<key>.md` using its real Jira Epic key (e.g. `MGD-12573.md`) — NOT a slug. Slug-named files (`<slug>.md`) are reserved for net-new Epics with no Jira ID yet.
- **Surface the team.** Emit the template's `**Team:** <team>` line under the H1. When `team` is empty, emit `**Team:** [NEEDS CLARIFICATION — team not found in import]` and add a matching `clarifications_needed[]` entry.
- **Partition the VI.** Distribute the VI `requirements[]` across the refinement targets; each target's `## Covers` lists only its slice. Two targets must not silently claim the same requirement.
- **Cross-team dependencies are expected.** When one team-Epic depends on another (e.g. a framework Epic that must land first), name the other Epic by key in `## Dependencies`. Such inter-target dependencies are legal (they encode build order) — do not suppress them.
- **Undrawable boundaries** → a `[NEEDS CLARIFICATION]` marker in the affected Epic + a `clarifications_needed[]` entry (subject to the ≤3-per-Epic cap).

In `mode: both`, also draft net-new Epics for scope no target covers (slug-named, per the normal generate flow). In `mode: generate` (or when `refinement_targets[]` is empty) behaviour is exactly as before.
```

- [ ] **Step 4: Add the refinement row to the coverage-matrix rules.** In the `_coverage.md` rules, immediately after the `**Focus mode:**` bullet (ends ~line 124), append:

```markdown
- **Refinement mode:** refined targets appear in "Covered by" as `<KEY> (refined)`; net-new drafts as `<slug> (new)`; untouched existing Epics as `<KEY> (exist)`. Requirements no target covers are `❌ gap` rows — the leftover the `/epics` Phase 6.2 gate routes.
```

- [ ] **Step 5: Verify.**

Run: `grep -nE 'Refinement mode|refinement_targets|current_body_path|Keyed filename|\(refined\)' plugins/dev-workflows/agents/epic-writer.md`
Expected: matches for the new section heading, both handoff bullets, `current_body_path`, `Keyed filename`, and the `(refined)` coverage note.

Run: `grep -nE '^\*\*Team:\*\*' plugins/dev-workflows/agents/epic-writer.md`
Expected: 1 match (the template line).

Run: `git diff --stat plugins/dev-workflows/agents/epic-writer.md`
Expected: only this file; additions dominate (one template line changed, rest inserted).

- [ ] **Step 6: Commit.**

```bash
git add plugins/dev-workflows/agents/epic-writer.md
git commit -m "feat(epic-writer): refinement mode — fill keyed team-Epics, partition VI

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `epic-reviewer` — conditional refinement dimensions

**Files:**
- Modify: `plugins/dev-workflows/agents/epic-reviewer.md` (dimensions table lines 43-57; the Epic-independence row; the Output findings block lines 59-119)

**Interfaces:**
- Consumes (from Task 4's brief): the presence of `refinement_targets`; from Task 2: the `**Team:**` line, keyed files, cross-team `## Dependencies`.
- Produces: four new conditional findings subsections; unchanged verdict tokens `PASS / PASS WITH RECOMMENDATIONS / BLOCK`.

- [ ] **Step 1: Carve the refinement exception into the Epic-independence row.** Replace the existing row:

```markdown
| Epic independence | Each Epic delivers its value without any not-yet-built Epic (no forward dependency). A forward dependency → MAJOR (resequence/merge). |
```
with:
```markdown
| Epic independence | Each Epic delivers its value without any not-yet-built Epic. A forward dependency on an Epic that does not yet exist → MAJOR (resequence/merge). **Exception (refinement mode):** a dependency between two Epics in the same refined `refinement_targets` set is legal (it encodes real cross-team build order) and is judged by the Cross-team dependency sanity dimension, not flagged here. |
```

- [ ] **Step 2: Add the four conditional dimension rows.** Immediately after the `ARD conformance (conditional)` row (line 57, the last table row), append:

```markdown
| Refinement completeness (conditional) | Only when the brief includes `refinement_targets`: every target is actually filled — a still-empty target (no real Scope/Acceptance content beyond the summary) is a BLOCKER. Absent → dimension skipped. |
| Partition integrity (conditional) | Only in refinement mode: the union of the refined targets' `## Covers` spans the intended VI slice with no silent overlap (two targets claiming the same requirement without a stated split → MAJOR) and no unflagged uncovered requirement. Absent → skipped. |
| Cross-team dependency sanity (conditional) | Only in refinement mode: inter-target `## Dependencies` are present where a build order exists and are acyclic. A dependency on a not-yet-existing Epic still → MAJOR. Absent → skipped. |
| Team preserved (conditional) | Only in refinement mode: each refined Epic records a `**Team:**` line matching its target's team. Missing/wrong team → MINOR (or the retained `[NEEDS CLARIFICATION]` when the import lacked it). Absent → skipped. |
```

- [ ] **Step 3: Add the four findings subsections to the Output block.** In the Output template, immediately AFTER the `#### Terminology drift` subsection and BEFORE `#### ARD conformance`, insert:

```markdown
#### Refinement completeness
- _"N/A — no refinement targets"_ when the brief omitted `refinement_targets`, else findings.

#### Partition integrity
- _"N/A — not refinement mode"_ when not applicable, else findings.

#### Cross-team dependency sanity
- _"N/A — not refinement mode"_ when not applicable, else findings.

#### Team preserved
- _"N/A — not refinement mode"_ when not applicable, else findings.
```

- [ ] **Step 4: Verify.**

Run: `grep -nE 'Refinement completeness|Partition integrity|Cross-team dependency sanity|Team preserved' plugins/dev-workflows/agents/epic-reviewer.md`
Expected: 2 matches for EACH label (one table row + one findings subsection = 8 total).

Run: `grep -nE 'Exception \(refinement mode\)' plugins/dev-workflows/agents/epic-reviewer.md`
Expected: 1 match (the Epic-independence carve-out).

Run: `grep -c 'PASS WITH RECOMMENDATIONS' plugins/dev-workflows/agents/epic-reviewer.md`
Expected: unchanged from before (verdict tokens not altered) — ≥2.

- [ ] **Step 5: Commit.**

```bash
git add plugins/dev-workflows/agents/epic-reviewer.md
git commit -m "feat(epic-reviewer): conditional refinement dimensions

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `epics.md` — detection, gate, adaptive default, leftover routing, invariants

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md` (Phase 3 ~line 210-221; new Phase 3.5; Phase 6 writer handoff; Phase 6.2 leftover extension; Phase 7 reviewer brief; Invariants section lines 623-650)

**Interfaces:**
- Consumes (Task 1): `linked_items[].refinement_candidate/team/scope_hint`.
- Consumes (Task 2): `epic-writer` handoff fields `mode` + `refinement_targets[]`; return `coverage_file` with `❌ gap` rows.
- Consumes (Task 3): `epic-reviewer` activates conditional dimensions when the brief includes `refinement_targets`.
- Produces: the orchestration that wires it all; the no-regression guard.

- [ ] **Step 1: Add refinement-candidate collection to Phase 3.** After the focus-mode block (ends line 221), append a new paragraph:

```markdown
**Refinement candidates.** From the same `linked_items` (`type == Epic`), read the additive per-Epic fields `refinement_candidate`, `team`, and `scope_hint` (emitted by `jira-reader` at `vi-plus-epics`). Collect `refinement_candidates` = every linked Epic with `refinement_candidate: true`. These are empty/almost-empty team-Epic shells the PE pre-created to encode team boundaries — refinement *targets to fill in*, not non-duplication constraints. This set drives the Phase 3.5 gate.
```

- [ ] **Step 2: Enrich the focus block for refine mode.** At the end of the focus-mode block (after "...draft the full partition of new Epics.", line 221), append:

```markdown
When `focus_key` is set, `mode = refine` and `refinement_targets = [the focus Epic]` — Phase 6 iterates on its current imported content (see `epic-writer` refinement mode) rather than regenerating from the VI alone.
```

- [ ] **Step 3: Add Phase 3.5 (the gate).** Insert a new phase between Phase 3 (ends line 223 `---`) and Phase 4 (line 225 `## Phase 4`):

```markdown
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
```

- [ ] **Step 4: Pass `mode` + `refinement_targets` to `epic-writer` in Phase 6.** In Phase 6, the orchestrator writes a temp handoff for `epic-writer` (already carrying `jira_reader_handoff`, `scope`, `existing_epics`, `output_dir`, `requirements`, `applicable_ard`, etc.). Add two fields to that handoff:

```
mode:               <generate | refine | both>   # from Phase 3.5; generate when 3.5 skipped
refinement_targets: <list of {key, team, scope_hint, current_body_path}; empty in generate mode>
                    # current_body_path = <jira_export_root>/<EPIC-KEY>/<EPIC-KEY>.md
```

- [ ] **Step 5: Add the leftover-disposition gate to Phase 6.2.** At the END of Phase 6.2 (after the current final sentence about the silent no-op, line 322), append:

```markdown

**Leftover disposition (refine / both only).** After the writer returns, read `_coverage.md`; every `❌ gap` row is a VI requirement no team-Epic covers. In ONE batched prompt, ask per gap:
```
choices: ["Assign to team-Epic <KEY> (re-drafts that Epic to include it)", "Propose as a new (net-new, slug-named) Epic", "Defer (leave as an uncovered row)", "Other… (describe)"]
```
Fold the results back: *assign* → re-dispatch `epic-writer` once (or Edit inline) to add the requirement to the named target's `## Covers` + scope; *new Epic* → add a slug-named net-new draft; *defer* → the row stays `❌ gap` in `_coverage.md` and is listed in the Phase 9 report. Reuses the same batched-gate pattern as the clarification resolution above; no gaps → silent no-op.
```

- [ ] **Step 6: Activate the reviewer's conditional dimensions in Phase 7.** In Phase 7, where the brief for `epic-reviewer` is assembled (it already passes `requirements[]`, the `_coverage.md` path, and `applicable_ard`), add one instruction line:

```markdown
When `mode` is `refine`/`both`, include `refinement_targets` in the `epic-reviewer` brief so its conditional refinement dimensions (completeness, partition integrity, cross-team dependency sanity, team preserved) activate; omit it in `generate` mode so those dimensions report N/A.
```

- [ ] **Step 7: Add the refinement invariants.** In the Invariants section (lines 623-650), immediately after the existing `- ALWAYS pass `requirements[]`, the `_coverage.md` path, and `applicable_ard` ... to `epic-reviewer`` line (the last bullet), append:

```markdown
- ALWAYS treat linked Epics flagged `refinement_candidate: true` as fill-in targets (not non-duplication constraints) once the Phase 3.5 gate selects `refine`/`both`; the confirmed target set is the PE's, not the raw detection
- ALWAYS write refined team-Epics to `<output_dir>/<EPIC-KEY>.md` (keyed by real Jira id) and net-new Epics to `<output_dir>/<slug>.md`; refined files carry a `**Team:**` line
- ALWAYS re-surface the code-scan default adaptively in Phase 3.5 for refine/both (ON at ≥2 targets, OFF at 1) — never in the generate path
- ALWAYS run the Phase 6.2 leftover-disposition gate in refine/both when `_coverage.md` has `❌ gap` rows; silent no-op when none
- Refinement mode (Phase 3.5 gate, `refinement_targets` handoff, leftover gate, keyed output) is ADDITIVE and guarded — no `refinement_candidate` targets AND no `focus_key` ⇒ `mode = generate` and the run is byte-identical to the legacy net-new flow
```

- [ ] **Step 8: Verify.**

Run: `grep -nE 'Phase 3.5|Refinement-mode gate|Refinement candidates|Leftover disposition|refinement_targets|Adaptive code-scan' plugins/dev-workflows/commands/epics.md`
Expected: matches for the new phase heading, the candidate paragraph, the leftover gate, the adaptive-default block, and ≥3 `refinement_targets` references (Phase 3.5, Phase 6 handoff, Phase 7 brief).

Run: `grep -c 'refinement_candidate' plugins/dev-workflows/commands/epics.md`
Expected: ≥2 (Phase 3 collection + an invariant).

Run: `grep -nE 'byte-identical to the legacy net-new flow' plugins/dev-workflows/commands/epics.md`
Expected: 2 matches (Phase 3.5 + the invariant) — the no-regression anchor is stated.

Run: `git diff --stat plugins/dev-workflows/commands/epics.md`
Expected: only this file; additions only (no lines removed except the two-line focus-block/independence edits are additive; Phase 1 UNCHANGED).

Run: `git diff plugins/dev-workflows/commands/epics.md | grep -E '^-' | grep -v '^---'`
Expected: EMPTY (or only the intentional in-place edits from Steps 2 — this command should show no deletions of Phase 1 text, confirming the generate path is untouched).

- [ ] **Step 9: Commit.**

```bash
git add plugins/dev-workflows/commands/epics.md
git commit -m "feat(epics): refinement mode — detect shells, gate, partition, leftover routing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: References — workflow-states + pre-lint

**Files:**
- Modify: `plugins/dev-workflows/references/workflow-states.md` (after the Epic-ladder table, ~line 37)
- Modify: `plugins/dev-workflows/references/pre-lint.md` (Epic section, lines 50-59)

**Interfaces:**
- Consumes: the behavior defined in Tasks 1-4 (keyed `<EPIC-KEY>.md`, `**Team:**` line).
- Produces: reference notes only.
- Note: `references/next-phase-offer.md` needs NO change (refinement is a behavior of `/epics`, not a routing change) — verified in Step 3.

- [ ] **Step 1: Add the refinement note under the Epic ladder in `workflow-states.md`.** Immediately after the Epic-ladder table (the `| Closed | Team | — | merged/done |` row, line 37), insert:

```markdown

> When the PE has pre-created empty Epic shells in Jira (one per team), `/epics <VI>` detects and **refines** them in place — partitioning the VI scope across teams — instead of generating net-new Epics. Same `Open → Epic draft` transition; the refined drafts are keyed `<EPIC-KEY>.md` and carry a `**Team:**` line.
```

- [ ] **Step 2: Add the refined-file check to the `pre-lint.md` Epic section.** After the last bullet of the Epic section (`- A `_coverage.md` file is present in the output dir.`, line 59), append:

```markdown
- Refined Epic files (keyed `<EPIC-KEY>.md`, from `/epics` refinement mode) carry a `**Team:**` line
  (`grep -nE '^\*\*Team:\*\*' <file>`) and a `## Scope` with real in/out bullets (not just the summary).
```

- [ ] **Step 3: Verify (including the next-phase-offer no-change check).**

Run: `grep -nE 'refines. them in place|keyed .<EPIC-KEY>' plugins/dev-workflows/references/workflow-states.md`
Expected: 1 match for the note.

Run: `grep -nE 'Refined Epic files .keyed' plugins/dev-workflows/references/pre-lint.md`
Expected: 1 match.

Run: `git diff --stat plugins/dev-workflows/references/next-phase-offer.md`
Expected: EMPTY (no change — routing unchanged).

- [ ] **Step 4: Commit.**

```bash
git add plugins/dev-workflows/references/workflow-states.md plugins/dev-workflows/references/pre-lint.md
git commit -m "docs(refs): note /epics refinement mode in workflow-states + pre-lint

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Version bump + CHANGELOG (counts unchanged)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json:3`
- Modify: `.claude-plugin/marketplace.json:12`
- Modify: `plugins/dev-workflows/CHANGELOG.md` (new entry above `## [2.27.0]`)

**Interfaces:**
- Consumes: all prior tasks (this is the release bookkeeping).
- Produces: version 2.28.0; a CHANGELOG entry.

- [ ] **Step 1: Bump `plugin.json` version.** Replace line 3:

`  "version": "2.27.0",` → `  "version": "2.28.0",`

- [ ] **Step 2: Bump `marketplace.json` dev-workflows version.** Replace line 12:

`      "version": "2.27.0",` → `      "version": "2.28.0",`

- [ ] **Step 3: Add the CHANGELOG entry.** Insert BETWEEN the intro block (ends line 6, blank line after "Versions follow semver at the plugin level.") and the `## [2.27.0] — 2026-07-13` heading:

```markdown
## [2.28.0] — 2026-07-13

### Added

- **`/epics` refinement & VI-partition mode** — when a PE pre-creates empty Epic shells in Jira (one per team) and they are re-imported, `/epics <VI>` now detects them and offers to **refine** them in place: it partitions the VI scope across the team-Epics, fills each in (keyed `<EPIC-KEY>.md` in `jira-drafts/`, carrying a `**Team:**` line), captures cross-team dependencies, and routes leftover VI scope through an inline batched gate (assign to a team-Epic / propose a net-new Epic / defer). `/epics <VI> <Epic>` re-refines a single Epic by iterating on its current imported content. No new command — refinement is an auto-detected mode of `/epics`.
- `jira-reader` (`depth: vi-plus-epics`) now emits three additive per-Epic fields — `refinement_candidate`, `team` (verbatim from the Epic frontmatter `team:`), and `scope_hint` — used to detect empty team-Epic shells. Additive and depth-gated; other consumers are unaffected.
- `epic-reviewer` gains four conditional refinement dimensions (refinement completeness, partition integrity, cross-team dependency sanity, team preserved), active only when the review brief includes refinement targets.

### Changed

- The code-examination default is now **adaptive in refinement mode** — ON when 2+ team-Epics are being refined, OFF for a single target (always still asked interactively). The generate-net-new path is unchanged.

### Notes

- Strictly additive / no-regression: `/epics <VI>` with no empty shells and no focus key is byte-identical to 2.27.0. `/vuln`, `/upgrade`, and the sibling plugins are untouched. Command / agent counts unchanged (Twenty / Thirty).

```

- [ ] **Step 4: Verify manifests parse, versions match, counts + descriptions unchanged.**

Run: `python3 -c "import json; json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); json.load(open('.claude-plugin/marketplace.json')); print('json ok')"`
Expected: `json ok`

Run: `grep -n '"version": "2.28.0"' plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json`
Expected: one match in each file.

Run: `git diff .claude-plugin/marketplace.json plugins/dev-workflows/.claude-plugin/plugin.json | grep -E '^[-+]' | grep -iE 'Twenty|Thirty|four hooks'`
Expected: EMPTY — the count strings are NOT in the diff (descriptions untouched).

Run: `grep -nE '^## \[2\.28\.0\] — 2026-07-13' plugins/dev-workflows/CHANGELOG.md`
Expected: 1 match with the exact heading format.

- [ ] **Step 5: Commit.**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore: release dev-workflows 2.28.0 (/epics refinement mode)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Final whole-branch verification (before finishing)

Run from repo root:

- [ ] `git diff --stat main` — exactly these files changed: `agents/jira-reader.md`, `agents/epic-writer.md`, `agents/epic-reviewer.md`, `commands/epics.md`, `references/workflow-states.md`, `references/pre-lint.md`, `.claude-plugin/plugin.json` (plugin), `.claude-plugin/marketplace.json` (root), `CHANGELOG.md`. NOTHING else.
- [ ] Siblings 0-diff: `git diff main -- plugins/dt-style-guide plugins/obsidian-llm-wiki` → EMPTY.
- [ ] Untouched commands 0-diff: `git diff main -- plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md` → EMPTY.
- [ ] Counts still 20/30: `ls plugins/dev-workflows/commands/*.md | wc -l` → 20; `ls plugins/dev-workflows/agents/*.md | wc -l` → 30.
- [ ] Whole-branch review (Sonnet) via `scripts/review-package`, then finishing-a-development-branch (present merge/PR options — do NOT push/merge without the user choosing).

## Self-Review (against the spec)

**Spec coverage:** §4.1 mode model → Task 4 Steps 1-3; §4.2 jira-reader fields → Task 1; §4.3 gate → Task 4 Step 3; §4.4 adaptive default + ordering → Task 4 Step 3; §4.5 partition/cross-team/[NEEDS CLARIFICATION] → Task 2 Step 3 + Task 4; §4.6 leftover gate → Task 4 Step 5; §4.7 output layout → Task 2 Steps 2-4 + Task 4 invariants; §4.8 epic-writer → Task 2; §4.9 epic-reviewer → Task 3; §4.10 references/ARD → Task 5 (ARD untouched = inherited); §5 no-regression → Task 4 Steps 8 (deletion check) + invariant; §6 version/manifests → Task 6. No gaps.

**Placeholder scan:** every edit step carries the literal new text; no "TBD"/"handle X"/"similar to". Verifications are exact grep/json commands with expected output.

**Type/name consistency:** `refinement_candidate` / `team` / `scope_hint` / `mode` / `refinement_targets` / `current_body_path` used identically across Tasks 1→2→3→4. Verdict tokens and severity schema unchanged. Keyed `<EPIC-KEY>.md` vs slug `<slug>.md` consistent throughout.

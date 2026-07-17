# Release-note Change-Type sourcing + VI capture — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `release-notes-writer` source the Change Type + `release_notes_category` from imported/authored VI data (inferring only as a last resort); capture those fields at `/create-vi`; and bring all plugin metadata current.

**Architecture:** A sourcing ladder replaces the writer's infer-only Classify step — `change_type_hint` → imported VI frontmatter (surfaced by `jira-reader`) → authored specs-draft VI (secondary grounding per `vi-source-resolution.md`) → infer. Write-side adds two optional VI frontmatter fields captured by `/create-vi` and validated by `vi-reviewer`. Deprecation is unchanged (prose in the Summary). Metadata (dev-workflows `2.34.0 → 2.35.0`, dt-style-guide marketplace sync) is brought current.

**Tech Stack:** Markdown agent prompts, reference docs, slash-command specs, and plugin JSON metadata for the `dev-workflows` + `dt-style-guide` Claude Code plugins. No runtime code; verification is grep-based cross-reference checks + dry-runs.

## Global Constraints

- **Design source of truth:** `docs/superpowers/specs/2026-07-17-release-note-sourcing-and-vi-capture-design.md`.
- **Branch is rebased on `main` @ `633b211`.** Every edit builds on the CURRENT file content (633b211 already changed `create-vi.md`, `vi-reviewer.md`, `vi-format.md`, and the metadata). Implementers must read the current file and match its existing structure.
- **Field names, verbatim:** writer inputs `imported_change_type`, `imported_release_notes_category`, `authored_vi_fields: { change_type, release_notes_category }`; `change_type_hint` stays the top override; jira-reader/handoff + vi-format frontmatter keys `change_type`, `release_notes_category`.
- **The four Change Type values, EXACT:** `Breaking change`, `New technology support`, `Bug fix`, `not applicable`.
- **Sourcing ladder order (change_type):** `change_type_hint` → imported → authored → infer. First-available-wins (no merge); on import-vs-authored divergence, **import wins** + a non-blocking Phase-8 report note.
- **`release_notes_category`:** ladder imported → authored → none; **surfaced** (handoff + Phase-8 report + settable draft line); it is **NOT** the `{{#context}}` label (label stays inferred).
- **Deprecation is prose, not a field** — unchanged from the merged feature. Add no `deprecation:` frontmatter, no deprecation vi-reviewer rule.
- **Authored-VI read** reuses `references/vi-source-resolution.md` §5 (specs draft = secondary grounding, `issue_type: ValueIncrement`, glob `<KEY>_*.md`; never authoritative over the Jira import); missing file → graceful skip.
- **Version:** dev-workflows → **`2.35.0`** (2.34.0 is taken by 633b211); its `[2.35.0]` CHANGELOG covers the merged-but-undocumented Change Type feature AND this feature; leave 633b211's `[2.34.0]` intact. Counts unchanged by this feature (baseline is "Twenty-one commands", agents "Thirty-one"). dt-style-guide marketplace.json `0.2.2 → 0.2.3`.
- **Plugin reference convention:** cite bundled files via `${CLAUDE_PLUGIN_ROOT}/...` in agent/handoff bodies.
- **Commits:** LOCAL commit per task on branch `feat/release-note-sourcing` (user-authorized; nothing pushed). End messages with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: Add the "Sourcing change_type" section to `release-note-types.md`

**Files:** Modify `plugins/dev-workflows/references/release-note-types.md`

**Interfaces:** Produces the §-referenced sourcing ladder that Task 3 (writer) and Task 4 (command) cite.

- [ ] **Step 1: Append a new section** after §5 (end of file), before any trailing content:

```markdown
## 6. Sourcing the Change Type

`change_type` is **sourced**, not just inferred. Resolve it by this precedence — the first
source that supplies a value wins (no merging):

1. **`change_type_hint`** — an explicit value the user/command passed. Always wins.
2. **Imported VI frontmatter** — `change_type` from the re-imported Jira VI (surfaced by
   `jira-reader`). This is the Jira field of record for a note already authored in Jira
   (the dev-phase run).
3. **Authored specs-draft VI** — `change_type` from `$SPECS_PATH/.../<KEY>_<slug>.md`, read
   as **secondary grounding** per `${CLAUDE_PLUGIN_ROOT}/references/vi-source-resolution.md`
   §5 (never authoritative over the Jira import). Covers the PM-phase run, before the Jira
   dropdown is set.
4. **Infer** — classify from content per §1–§2 (the last resort).

When both the imported and authored sources are present and **differ**, the imported value
wins and the caller records a non-blocking divergence note. `release_notes_category` follows
the same ladder minus the hint (imported → authored → none) and is surfaced, never inferred.
```

- [ ] **Step 2: Verify**

Run: `grep -nE 'Sourcing the Change Type|vi-source-resolution|first source that supplies' plugins/dev-workflows/references/release-note-types.md`
Expected: the new section, the reference citation, and the precedence phrasing all present.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/release-note-types.md
git commit -m "feat(dev-workflows): document the change_type sourcing ladder in release-note-types.md" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: `jira-reader` surfaces `change_type` + `release_notes_category`

**Files:** Modify `plugins/dev-workflows/agents/jira-reader.md` and `plugins/dev-workflows/references/handoff/jira-reader.md`

**Interfaces:** Produces `value_increment.change_type` + `value_increment.release_notes_category` in the handoff, consumed by the command (Task 4).

- [ ] **Step 1: Add the two fields to the handoff `value_increment` block.** In `references/handoff/jira-reader.md`, replace:

```yaml
value_increment:
  key:     <key>
  summary: <text from frontmatter>
  status:  <text from frontmatter>
  goal:    <2–3 sentence extraction from the Description / Goal section>
```

with:

```yaml
value_increment:
  key:     <key>
  summary: <text from frontmatter>
  status:  <text from frontmatter>
  goal:    <2–3 sentence extraction from the Description / Goal section>
  change_type:            <verbatim from frontmatter `change_type:` when present; null otherwise — one of Breaking change | New technology support | Bug fix | not applicable>
  release_notes_category: <verbatim from frontmatter `release_notes_category:` when present; null otherwise>
```

- [ ] **Step 2: Instruct the agent to extract them.** In `agents/jira-reader.md`, find the step that parses the VI's YAML frontmatter for the `value_increment` output (the `depth: full` / `vi-only` read of `<EXPORT_ROOT>/<jira_key>/<jira_key>.md`). Add a sentence to that step:

```markdown
   Also surface `change_type` and `release_notes_category` verbatim from the VI frontmatter into `value_increment` (null when a key is absent) — additive read-only fields; no other consumer is affected when they are null.
```

(Place it alongside the existing frontmatter-extraction instruction for the VI item; do not alter the Epic-only fields.)

- [ ] **Step 3: Verify**

Run: `grep -nE 'change_type|release_notes_category' plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/references/handoff/jira-reader.md`
Expected: both fields appear in the agent body (extraction) and the handoff (schema).

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/references/handoff/jira-reader.md
git commit -m "feat(dev-workflows): jira-reader surfaces VI change_type + release_notes_category" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: `release-notes-writer` — sourcing ladder + category surfacing

**Files:** Modify `plugins/dev-workflows/agents/release-notes-writer.md` and `plugins/dev-workflows/references/handoff/release-notes-writer.md`

**Interfaces:** Consumes the new writer inputs; produces `release_notes_block.change_type` (via ladder) + a surfaced `release_notes_category`. Task 4 supplies the inputs and consumes the outputs.

- [ ] **Step 1: Add the new inputs.** In `agents/release-notes-writer.md` `## Inputs`, replace:

```yaml
change_type_hint:    <optional user-supplied Change Type and/or deprecation signal; null otherwise>
```

with:

```yaml
change_type_hint:    <optional user-supplied Change Type and/or deprecation signal; null otherwise>
imported_change_type:            <change_type from the imported VI frontmatter (jira-reader handoff); null otherwise>
imported_release_notes_category: <release_notes_category from the imported VI frontmatter; null otherwise>
authored_vi_fields:  <optional { change_type, release_notes_category } from the authored specs-draft VI; null/absent otherwise>
```

- [ ] **Step 2: Replace the Classify step with the sourcing ladder.** Replace Process step 1 (`1. **Classify the Change Type.** …` through its closing `...ask user"`).) with:

```markdown
1. **Source the Change Type (ladder).** Resolve `release_notes_block.change_type` per
   `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` §6: `change_type_hint` →
   `imported_change_type` → `authored_vi_fields.change_type` → infer from content (§1–§2).
   First non-null wins. If both `imported_change_type` and `authored_vi_fields.change_type`
   are present and differ, use the imported value and emit a `gaps[]` entry
   (`field: change_type_divergence`, `recommended_action: "note in report"`,
   `imported: <v>`, `authored: <v>`). Only when the value had to be **inferred** and is
   low-confidence, emit `gaps[]` (`field: change_type`, `recommended_action: "ask user"`).
   Set it to one of `Breaking change` / `New technology support` / `Bug fix` /
   `not applicable`.

2. **Surface the release-notes category.** Set `release_notes_block.release_notes_category`
   = `imported_release_notes_category` → `authored_vi_fields.release_notes_category` → null
   (first non-null; never inferred). It is surfaced only — it does NOT become the
   `{{#context}}` label.
```

Renumber the remaining Process steps accordingly (old 2 "Detect deprecation" → 3, and so on; keep their bodies, updating any internal "Process step N" reference).

- [ ] **Step 3: Emit `change_type` + `release_notes_category` in the render.** In the Render step's `combined_rendered` description, add a `Release-notes category:` line beside the existing `Change type:` line (only when the category is non-null):

```markdown
   When `release_notes_block.release_notes_category` is non-null, add a `Release-notes category: <value>` line immediately after the `Change type:` line (both above the `--- Summary … ---` divider). The category is metadata for the PM to set the Jira field; it never appears inside the `{{#context}}` Summary body.
```

- [ ] **Step 4: Update the handoff.** In `references/handoff/release-notes-writer.md`: add the three new input fields (mirroring Step 1); add `release_notes_category` as a top-level field of `release_notes_block` (beside `change_type`); add the `change_type_divergence` gap reason to the `gaps[]` `field:` enum; note the `Release-notes category:` line in the `combined_rendered` description.

- [ ] **Step 5: Verify**

Run: `grep -nE 'imported_change_type|imported_release_notes_category|authored_vi_fields|change_type_divergence|Release-notes category:' plugins/dev-workflows/agents/release-notes-writer.md plugins/dev-workflows/references/handoff/release-notes-writer.md`
Expected: all five tokens present across the two files.

Run: `grep -nE '^[0-9]+\. \*\*' plugins/dev-workflows/agents/release-notes-writer.md | head`
Expected: Process steps contiguously numbered, no dup/gap.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/agents/release-notes-writer.md plugins/dev-workflows/references/handoff/release-notes-writer.md
git commit -m "feat(dev-workflows): release-notes-writer sources change_type via ladder; surfaces release_notes_category" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: `/release-notes` — read imported + authored, pass to writer, report

**Files:** Modify `plugins/dev-workflows/commands/release-notes.md`

**Interfaces:** Consumes jira-reader's `value_increment.change_type`/`release_notes_category` (Task 2) + reads the authored VI; supplies the writer's new inputs (Task 3).

- [ ] **Step 1: Read imported + authored fields in Phase 3.** After the Phase 3 sentence that parses `release_versions` from the VI frontmatter (`On \`OK\`, parse \`release_versions\` …`), add:

```markdown

Also capture `imported_change_type` and `imported_release_notes_category` from the
jira-reader handoff's `value_increment` block (null when absent).

**Resolve the authored specs-draft VI (secondary grounding).** Per
`${CLAUDE_PLUGIN_ROOT}/references/vi-source-resolution.md` §5, glob
`$SPECS_PATH/specifications/<jira_key>-*/<jira_key>_*.md` (first match whose frontmatter is
`issue_type: ValueIncrement`); read its `change_type` + `release_notes_category` into
`authored_vi_fields`. A missing file or `$SPECS_PATH` is a graceful skip
(`authored_vi_fields: null`) — never authoritative over the imported values.
```

- [ ] **Step 2: Pass the new fields in the Phase 6 writer brief.** After the `> change_type_hint:    [...]` line in the render brief, add:

```
  > imported_change_type:            [from Phase 3, else null]
  > imported_release_notes_category: [from Phase 3, else null]
  > authored_vi_fields:              [from Phase 3, else null]
```

- [ ] **Step 3: Report category + divergence in Phase 8.** After the `- Change type: …` report line (added by the merged feature), add:

```markdown
   - Release-notes category: <value | none>
   - Change-type source: <hint | imported | authored | inferred>  (+ "imported/authored differ: <imp> vs <auth> — used imported" when a change_type_divergence gap was returned)
```

Handle a `change_type_divergence` gap by printing the divergence note (non-blocking; no user prompt).

- [ ] **Step 4: Add the invariant.** In `## Invariants (always enforced)`, after the existing Change-Type invariant, add:

```markdown
- Change Type + `release_notes_category` are **sourced** — `change_type_hint` → imported VI frontmatter (jira-reader) → authored specs-draft VI (secondary grounding per `vi-source-resolution.md` §5) → infer; import wins over authored on divergence (non-blocking note). The category is surfaced only, never the `{{#context}}` label.
```

- [ ] **Step 5: Verify**

Run: `grep -nE 'imported_change_type|imported_release_notes_category|authored_vi_fields|vi-source-resolution|Release-notes category:|Change-type source' plugins/dev-workflows/commands/release-notes.md`
Expected: all tokens present across Phase 3, Phase 6, Phase 8, invariants.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/commands/release-notes.md
git commit -m "feat(dev-workflows): /release-notes sources change_type from imported + authored VI" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: `vi-format.md` — add the two authored frontmatter fields

**Files:** Modify `plugins/dev-workflows/references/vi-format.md`

**Interfaces:** Produces the authored `change_type` / `release_notes_category` keys that `/create-vi` (Task 6) writes and `vi-reviewer` (Task 7) validates.

- [ ] **Step 1: Add the fields to the frontmatter block.** Replace:

```yaml
relevant_for_release_notes: <yes | no>
release_versions: "<e.g. Managed (344), SaaS (344)>"
```

with:

```yaml
relevant_for_release_notes: <yes | no>
release_versions: "<e.g. Managed (344), SaaS (344)>"
change_type: <Breaking change | New technology support | Bug fix | not applicable>   # optional; authored-then-mirrored, like release_versions
release_notes_category: <Dynatrace Solution, e.g. Application Observability>          # optional
```

- [ ] **Step 2: Verify**

Run: `grep -nE 'change_type|release_notes_category' plugins/dev-workflows/references/vi-format.md`
Expected: both keys present in the frontmatter block.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/vi-format.md
git commit -m "feat(dev-workflows): vi-format authors optional change_type + release_notes_category" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: `/create-vi` captures the two fields

**Files:** Modify `plugins/dev-workflows/commands/create-vi.md`

**Interfaces:** Consumes the vi-format keys (Task 5); produces authored VIs that carry them (read later by Task 4's command).

- [ ] **Step 1: Extend the frontmatter authoring list.** Replace (Phase 3, the frontmatter bullet — current text):

```markdown
1. Frontmatter — incl. `release_versions` + `relevant_for_release_notes`, `sources` (propagated), `derived_from`, `seeded_from_vi` (only when `--from-vi` was used), `jira_key`.
```

with:

```markdown
1. Frontmatter — incl. `release_versions` + `relevant_for_release_notes`, and (when `relevant_for_release_notes: yes`) the optional `change_type` (one of `Breaking change` / `New technology support` / `Bug fix` / `not applicable`) + `release_notes_category` (the Dynatrace Solution); `sources` (propagated), `derived_from`, `seeded_from_vi` (only when `--from-vi` was used), `jira_key`. Ask for `change_type` / `release_notes_category` only when the note is release-notes-relevant; leave them out otherwise (dates/deprecation stay out of frontmatter — they belong in the release-notes Summary).
```

- [ ] **Step 2: Verify**

Run: `grep -nE 'change_type|release_notes_category' plugins/dev-workflows/commands/create-vi.md`
Expected: both fields appear in the frontmatter authoring step.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/commands/create-vi.md
git commit -m "feat(dev-workflows): /create-vi captures optional change_type + release_notes_category" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: `vi-reviewer` validates `change_type`

**Files:** Modify `plugins/dev-workflows/agents/vi-reviewer.md`

**Interfaces:** Consumes the vi-format keys (Task 5); adds validation. No deprecation rule.

- [ ] **Step 1: Extend the frontmatter check.** In the `## Review method`, replace step 2:

```markdown
2. Verify frontmatter: `issue_type: ValueIncrement`; `jira_key` matches `^[A-Z][A-Z0-9_]*-\d+$`; the downstream-contract fields `relevant_for_release_notes` + `release_versions` present; `sources` carries real provenance (not the literal `idea.md` path).
```

with:

```markdown
2. Verify frontmatter: `issue_type: ValueIncrement`; `jira_key` matches `^[A-Z][A-Z0-9_]*-\d+$`; the downstream-contract fields `relevant_for_release_notes` + `release_versions` present; `sources` carries real provenance (not the literal `idea.md` path). When present, `change_type` must be one of `Breaking change` / `New technology support` / `Bug fix` / `not applicable` (`MAJOR` if it is some other value); when `relevant_for_release_notes: yes` and `change_type` is absent, raise a `MINOR` (recommended, not required). `release_notes_category`, when present, is free text — no format check.
```

- [ ] **Step 2: Verify**

Run: `grep -nE 'change_type|release_notes_category' plugins/dev-workflows/agents/vi-reviewer.md`
Expected: both appear in the frontmatter check; no deprecation rule added.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/agents/vi-reviewer.md
git commit -m "feat(dev-workflows): vi-reviewer validates optional change_type" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 8: `CLAUDE.md` — invariants + references

**Files:** Modify `CLAUDE.md`

- [ ] **Step 1: Extend the `/release-notes` invariants.** After the Change-Type invariants added by the merged feature, add:

```markdown
- Change Type + `release_notes_category` are **sourced** — `change_type_hint` → imported VI frontmatter (surfaced by `jira-reader`) → authored specs-draft VI (secondary grounding per `references/vi-source-resolution.md` §5) → infer; import wins over authored on divergence (non-blocking). `release_notes_category` is surfaced only, never the `{{#context}}` label. Deprecation stays prose in the Summary (no frontmatter field)
```

- [ ] **Step 2: Extend the VI-creation invariants.** In the `Key invariants for the VI-creation flow` list, add:

```markdown
- `/create-vi` captures optional `change_type` + `release_notes_category` VI frontmatter (release-notes-relevant VIs only); `vi-reviewer` validates `change_type` ∈ the four values (MAJOR if malformed; MINOR if missing when relevant). These feed the `/release-notes` sourcing ladder
```

- [ ] **Step 3: Verify**

Run: `grep -nE 'sourced|vi-source-resolution|release_notes_category' CLAUDE.md`
Expected: the sourcing invariant + reference citation present.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: register /release-notes sourcing ladder + /create-vi capture invariants" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 9: Metadata + CHANGELOG + README (dev-workflows 2.35.0 + dt-style-guide sync)

**Files:** Modify `plugins/dev-workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/README.md`, and (dt-style-guide) `.claude-plugin/marketplace.json`

**Interfaces:** Pure metadata; no code interface.

- [ ] **Step 1: Bump dev-workflows version.** In `plugins/dev-workflows/.claude-plugin/plugin.json` change `"version": "2.34.0"` → `"version": "2.35.0"`. In `.claude-plugin/marketplace.json` change the **dev-workflows** entry `"version": "2.34.0"` → `"2.35.0"`.

- [ ] **Step 2: Touch up the two dev-workflows descriptions (keep byte-identical).** In BOTH `plugin.json` and `.claude-plugin/marketplace.json`, add a clause to the dev-workflows `description` noting release-notes Change Type + sourcing — e.g. append to the `/release-notes` mention: "`/release-notes` classifies a Change Type (Breaking change / New technology support / Bug fix / not applicable), shapes the Summary per type, and sources the type from the imported/authored VI." Do NOT change the command/agent counts ("Twenty-one" / "Thirty-one" stay). After editing, the two description strings must be identical.

- [ ] **Step 3: Add the CHANGELOG entry.** Prepend a `## [2.35.0] — 2026-07-17` entry above `## [2.34.0]` in `plugins/dev-workflows/CHANGELOG.md`, with an `### Added` covering (a) `/release-notes` Change Type + type-aware Summary + deprecation note (the merged-but-undocumented feature) and (b) the authored/imported sourcing ladder (`jira-reader` surfaces `change_type` + `release_notes_category`; writer ladder; `vi-source-resolution.md` reuse) + `/create-vi` capture + `vi-reviewer` validation. Leave `[2.34.0]` intact.

- [ ] **Step 4: Update the README command rows.** In `plugins/dev-workflows/README.md`, update the `/release-notes` row (Change Type line + type-aware Summary + sourcing) and the `/create-vi` row (captures optional `change_type` + `release_notes_category`), building on 633b211's current text. Counts unchanged.

- [ ] **Step 5: Sync dt-style-guide marketplace version.** In `.claude-plugin/marketplace.json`, change the **dt-style-guide** entry `"version": "0.2.2"` → `"0.2.3"` (matches its plugin.json).

- [ ] **Step 6: Verify parity**

Run: `grep -n '"version"' plugins/dev-workflows/.claude-plugin/plugin.json; grep -nE '2\.35\.0' plugins/dev-workflows/CHANGELOG.md .claude-plugin/marketplace.json`
Expected: dev-workflows plugin.json = 2.35.0, marketplace.json dev-workflows = 2.35.0, CHANGELOG has `[2.35.0]`.

Run: `python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); p=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); dw=[x for x in m['plugins'] if x['name']=='dev-workflows'][0]; dt=[x for x in m['plugins'] if x['name']=='dt-style-guide'][0]; print('dw desc identical:', dw['description']==p['description']); print('dw ver:', dw['version']); print('dt ver:', dt['version'])"`
Expected: `dw desc identical: True`, `dw ver: 2.35.0`, `dt ver: 0.2.3`.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md
git commit -m "chore(dev-workflows): bump to 2.35.0; document Change Type + sourcing; sync dt-style-guide marketplace to 0.2.3" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 10: Final cross-reference verification + dry-run

**Files:** none (verification only).

- [ ] **Step 1: No dangling fields.** Confirm each new field is defined AND consumed.

Run: `grep -rnE 'imported_change_type|imported_release_notes_category|authored_vi_fields|change_type_divergence' plugins/dev-workflows/`
Expected: writer inputs (agent + handoff), command (Phase 3 read + Phase 6 brief), and the divergence gap in writer + command — no orphans.

Run: `grep -rnE 'change_type|release_notes_category' plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/references/handoff/jira-reader.md plugins/dev-workflows/references/vi-format.md plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/agents/vi-reviewer.md`
Expected: present in every one (jira-reader surface, vi-format author, create-vi capture, vi-reviewer validate).

- [ ] **Step 2: Ladder consistency.** Confirm the ladder order + import-wins-on-divergence is stated identically in `release-note-types.md` §6, `release-notes-writer.md`, `commands/release-notes.md`, and `CLAUDE.md`.

Run: `grep -rnE 'change_type_hint.*imported.*authored|imported.*wins|secondary grounding' plugins/dev-workflows/ CLAUDE.md`

- [ ] **Step 3: Metadata parity** — rerun Task 9 Step 6 checks; all pass.

- [ ] **Step 4: Dry-run (mental trace; write a 6-line confirmation as the task output).**
  - PRODUCT-14900: jira-reader surfaces `change_type: New technology support` + `release_notes_category: Application Observability` → writer ladder uses imported directly (no inference); category surfaced as a `Release-notes category:` line, not the `{{#context}}` label; deprecation still inferred from the "classic layers deprecated" prose (unchanged).
  - PRODUCT-14902: no imported `change_type` → command reads the authored specs VI (if present) → else infer/hint; `release_notes_category: Software Delivery` surfaced.

- [ ] **Step 5: Whole-branch review** — dispatch the final reviewer on the `git merge-base main HEAD`..HEAD package (Opus), then `superpowers:finishing-a-development-branch`.

---

## Self-Review (completed by plan author)

**1. Spec coverage:** A (reader ladder) → Tasks 1/3/4; B (jira-reader surface + command read) → Tasks 2/4; C (vi-format/create-vi/vi-reviewer) → Tasks 5/6/7; D (release-note-types + CLAUDE.md) → Tasks 1/8; E (metadata 2.35.0 + dt sync) → Task 9. `vi-source-resolution.md` reuse → Tasks 1/4/8. Deprecation deliberately unchanged (no task) — matches the spec.

**2. Placeholder scan:** No "TBD/TODO" as instructions. The literal `<!-- TODO: end-of-life date -->` referenced in Task 10 is the merged feature's existing artifact, not new.

**3. Type consistency:** Field names identical across tasks — `imported_change_type`, `imported_release_notes_category`, `authored_vi_fields{change_type,release_notes_category}`, gap `change_type_divergence`, frontmatter `change_type`/`release_notes_category`; the four exact values; version `2.35.0`; dt `0.2.3`.

---
title: Grammar adoption in the four Jira-driven commands
date: 2026-07-08
status: approved
effort: dev-workflows backlog item 3
ships-as: v2.7.0
tags:
  - tasks-exclude
---

# Grammar adoption in the four Jira-driven commands — design

## Goal

Make `/implement`, `/document`, `/epics`, and `/release-notes` actually **consume**
the `focus_key` the shared front-end (`references/jira-input-resolution.md`) already
emits, so a two-key `<VI> <Epic>` (or a bare nested `<Epic>`) input stops silently
resolving the VI and reading the whole VI subtree. Ships as **v2.7.0**.

## Background: why this effort exists

The v2.5.0 foundation changed the shared reference **additively**: it now parses the
two-key `<VI> <Epic>` grammar, auto-resolves a bare nested `<Epic>` to its parent VI,
and emits a nullable `focus_key` field on the output contract. `/specify` and
`/design` (v2.4.0 / v2.6.0) consume `focus_key` and render the progress-aware Epic
picker natively — they are done.

But the four other Jira-driven commands only ever cited the reference and carried
forward `{mode, jira_key, jira_export_root, specs}`. None carry `focus_key`. Result:
a `<VI> <Epic>` input resolves the VI and **silently ignores the focus Epic** — every
one of them reads the whole VI/ticket subtree. This is a known, recorded gap (not a
silent regression, since single-key behavior is preserved) that must be closed so the
grammar is honored uniformly.

### Current state (verified against the files, 2026-07-08)

| Fact | implement.md | document.md | epics.md | release-notes.md |
|---|---|---|---|---|
| Cites `jira-input-resolution.md` | Yes (Phase 0) | Yes (Mode A Phase 0) | Yes (Phase 0) | Yes (Phase 0) |
| Reproduces steps inline | No | No | No | No |
| Carries `focus_key` | No | No | No | No |
| jira-reader depth | `full` | `full` | `vi-plus-epics` | `vi-only` \| `full` |
| Scoped to a single Epic | No | No | No | No |
| Renders the Epic picker | No | No | No | No |
| Total lines | 550 | 1189 | 461 | 210 |

`/implement` does **not** scan `$SPECS_PATH` itself — it consumes the `specs[]` list
the shared reference produces. The specs scan pattern
(`$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`, VI-flat, no
per-Epic level) lives only in the reference's §Specs-resolution.

`jira-reader` reliably surfaces both signals the `/implement` picker needs, at the
cheap `depth: vi-plus-epics` level:
- **Per-Epic Jira status** — the index table header is
  `| Key | Type | Status | Summary | Role |`; the output contract carries
  `linked_items[].status`.
- **Per-Epic PR merge state** — `pull_requests[].status = MERGED | OPEN | DECLINED | UNKNOWN`.

## Design decisions (approved 2026-07-08)

1. **`/implement` picker = Option 1** — for a bare multi-Epic VI, render the
   progress-aware picker with the **Epic's Jira status** as the done-predicate;
   selecting an Epic runs `/implement` for that Epic only, with **no auto "Next Epic?"
   loop**. Rationale: no new artifacts and no spec-repo writes; Epic-native and cheap;
   and it deliberately drops the chain-loop because code-writing is heavy, branchy, and
   less idempotent than authoring a spec — chaining Epics in one session is the risky
   part `/implement` should not inherit from `/specify`+`/design`.
2. **`/epics` + `focus_key` = refinement target** — `/epics` still reads and analyzes
   the whole VI (its non-duplication partition analysis is inherently VI-holistic), but
   when an explicit focus Epic is passed it narrows its **write** and **review** to
   (re)drafting/refining that one Epic, using the whole-VI analysis only as context.
3. **Nested per-Epic specs discovery lives in the shared reference** (not duplicated in
   `implement.md`), so `/implement` and `/document` resolve specs consistently.

## Scope

**Files touched:**
- `references/jira-input-resolution.md` — §Specs-resolution becomes `focus_key`-aware
  (additive). (Section A)
- `commands/implement.md` — consume `focus_key`; render the picker for a bare
  multi-Epic VI. (Section B)
- `commands/document.md` — Mode A consumes `focus_key` to scope downstream. (Section C)
- `commands/release-notes.md` — consume `focus_key` to scope the draft. (Section C)
- `commands/epics.md` — honor `focus_key` as a refinement target. (Section D)
- Release surfaces: `plugin.json`, `marketplace.json`, `CHANGELOG.md`, both `README.md`.

**Explicitly NOT touched:** `commands/specify.md`, `commands/design.md` (already
consume `focus_key`); `agents/jira-reader.md` (scoping is done in-orchestrator, the
foundation's established pattern); `agents/spec-reviewer.md`, `agents/design-reviewer.md`;
`references/specification-format.md`, `references/design-format.md`; the sibling plugins
`dt-style-guide` and `obsidian-llm-wiki`.

## Guardrails (unchanged behavior — the additive contract)

- Single-key `<VI-Key>`, single-key stand-alone item, and `<dir>` / `<dir> <Epic>`
  inputs resolve exactly as today; only the *use* of an already-emitted `focus_key`
  changes.
- VI-level commands (`/epics`, `/document`, `/release-notes`) keep working for a VI that
  has **not** been split into Epics (0 child Epics). They are **never** forced into the
  per-Epic picker.
- The picker is added to `/implement` **only** among the four commands.
- A stand-alone/top-level Epic (`focus_key = null`, `jira_export_root` is the Epic
  itself) proceeds directly with no picker — the reference already classifies this.

---

## Section A — shared reference: `focus_key`-aware Specs-resolution

The reference's §Specs-resolution currently resolves a single VI-flat
`<KEY>{-|_}<slug>/…/*.md` folder. Make it branch on `focus_key` (additive):

- **`focus_key` set** → prefer the nested per-Epic home
  `specifications/<VI>-<vslug>/<focus_key>-<eslug>/{specification.md, design.md, *.md}`.
  Resolve by locating, under a `specs`/`specifications`/`vis` root, the VI dir whose
  name matches the VI key **by key-number** (tolerating `-`/`_` separators and slug
  drift), then within it the Epic dir matching `focus_key` by key-number.
- **`focus_key` null** → the existing top-level/VI-flat resolution
  (`<jira_key>{-|_}<slug>/…/*.md`) — for a stand-alone item, a broad VI-level slice, or
  a legacy pre-foundation layout.
- **Fallback** — if `focus_key` is set but no nested Epic dir exists, fall back to the
  VI-flat resolution so nothing pre-foundation breaks; then the consuming command
  applies its own specs policy (`/implement`: required-with-override prompt;
  `/document`: additive/proceed).

The §Output-contract already documents `focus_key`; only the resolution prose grows.
This is the single home for the "nested per-Epic path discovery" the backlog had
tentatively assigned to `/implement`.

---

## Section B — `/implement` (the heavy adopter)

`/implement` is an Epic-unit command. Two additions, both in / around Phase 0:

### B1 — Consume `focus_key`
When `focus_key` is set (explicit `<VI> <Epic>`, bare nested `<Epic>`, or chosen in the
picker), scope the Jira read to the focus Epic's subtree **in-orchestrator**: after the
`depth: full` read returns `linked_items`, keep the focus Epic plus the items linked
beneath it (its Stories / Sub-tasks) and drop sibling Epics' subtrees.
`jira-reader` is **not** modified — this mirrors the scoping `/specify` already does.
Carry `focus_key` forward from Phase 0 alongside the existing fields.

### B2 — Picker for a bare multi-Epic VI (`focus_key` null)
Added as a Phase 0 step (right after the shared front-end resolves, for
`mode: jira-driven`), so it can set `focus_key` before specs-resolution and the main
read:

1. Cheap classify read: `jira-reader depth: vi-plus-epics` on `jira_export_root`.
2. Branch on the result:
   - **Item is itself an Epic** (stand-alone/top-level) → no picker; proceed directly
     (`focus_key` stays null; specs resolve at the item's top-level dir).
   - **VI with exactly 1 Epic** → no picker; auto-set `focus_key` to that Epic and
     proceed.
   - **VI with ≥2 Epics** → render the picker.
   - **VI with 0 Epics** → `/implement`'s no-Epics policy: offer "split with `/epics`
     first" or "implement one broad VI-level slice" (`focus_key` stays null).
3. **Picker rows** — one per Epic, status glyph from the Epic's Jira status
   (`linked_items[].status`), with the raw status text always shown so a lagging status
   can't mislead:
   - **● done** — status maps to done/closed/resolved → shown greyed, not
     default-selectable; selecting offers "revise / implement anyway".
   - **◐ in progress** — status maps to in-progress/in-review → selectable.
   - **○ not started** — any other/unknown status (to do, open, backlog, blank) →
     selectable.
   - Default cursor = first actionable (in-progress before not-started).
   - Explicit choice: **"Implement one broad VI-level slice instead"** (`focus_key`
     stays null → specs resolve VI-level).
   - If the export carries no usable status column, degrade to a plain unstatused
     selection list (glyphs omitted) — the selection still works.
4. Selecting an Epic sets `focus_key` and proceeds for **that Epic only**.
   **No "Next Epic?" prompt** after the run — the command ends at its normal Phase 5
   report.

### B3 — Specs
Consumed via the Section-A reference change — no path logic is duplicated in
`implement.md`. With `focus_key` set, specs resolve at the Epic's nested dir; the
existing "specs required for jira-driven runs" prompt still fires when nothing is found.

The Phase 0 open-question guard (design-doc `- [ ]` refusal) is untouched.

---

## Section C — `/document` + `/release-notes` (light adopters, VI-level)

Both remain VI-level, keep working for un-split VIs, and gain **no picker**. When
`focus_key` is explicitly set, each reads the VI at the depth it already uses, then
scopes its downstream work to the focus Epic's linked items (filtered
in-orchestrator from the jira-reader result):

- **`/document` (Mode A):** scope Phase 5 parallel diff-summarization and Phase 5.7 doc
  planning to the focus Epic's `pull_requests` / linked items. Phases that are
  VI-descriptive (e.g. Phase 4.5 space determination) still see the VI. Default (no
  focus) = whole VI, exactly as today. Specs consumed via the Section-A change.
- **`/release-notes`:** scope Phase 6 rendering (and, when diff grounding is on, the
  Phase 5 diff-summarization) to the focus Epic's user-facing changes. Default = VI/ticket
  scope, exactly as today.

Carry `focus_key` forward from Phase 0 in both; when null, behavior is byte-for-byte
unchanged.

---

## Section D — `/epics` (VI-level, refinement target)

`/epics`'s job — partition a VI into non-overlapping Epics — is inherently VI-holistic,
so it **always** reads and analyzes the whole VI (`depth: vi-plus-epics`, unchanged) for
non-duplication. Grammar adoption:

- **`focus_key` null** → unchanged VI-level partition drafting.
- **`focus_key` set** (`<VI> <Epic>`) → honor it as a **refinement target**: the
  whole-VI analysis still runs (for non-duplication context), but Phase 6 **write** and
  Phase 7 **review** narrow to (re)drafting/refining just that one Epic. If the focus
  Epic isn't among the VI's linked Epics, surface a clear message and offer to proceed
  VI-level.

Carry `focus_key` forward from Phase 0; VI-level remains the default and the un-split-VI
path is untouched. No picker.

---

## Version & release surfaces (lock-step, v2.7.0)

- `plugins/dev-workflows/.claude-plugin/plugin.json` — `version` → `2.7.0`; refresh the
  `description` if the command/subagent inventory sentence needs it (no new commands or
  subagents this effort — the count sentences stay; only refresh if wording implies the
  commands ignore focus Epics).
- repo-root `.claude-plugin/marketplace.json` — `plugins[0].version` → `2.7.0`; mirror
  any `description` change. **Do not touch** `dt-style-guide` / `obsidian-llm-wiki`
  entries.
- `plugins/dev-workflows/CHANGELOG.md` — prepend `## [2.7.0] — 2026-07-08` describing
  the four-command focus_key adoption + `/implement` picker + nested per-Epic specs.
- `plugins/dev-workflows/README.md` and repo-root `README.md` — refresh any prose that
  claims the Jira commands operate only at VI scope, to note the two-key `<VI> <Epic>`
  grammar is now honored end-to-end.

## Global constraints (for the plan)

- Additive-only: single-key / `<dir>` inputs and un-split-VI behavior unchanged;
  `focus_key` null ⇒ byte-for-byte today's behavior in every command.
- `jira-reader`, `/specify`, `/design`, the reviewers, and the format refs are not
  modified; scoping is in-orchestrator.
- Version lock-step across `plugin.json` + `marketplace.json` + `CHANGELOG.md`; siblings
  untouched.
- No test framework in the plugin repo — verification is **structural** (grep anchors,
  `python3 -c json.load` for the two JSON manifests, byte-diff review).
- Commit trailer exactly: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Never `git add -A`; stage only named files. Commit/push only when the user asks.
- Recompute any counts (commands, subagents) from the repo — never assert from memory.

## Out of scope

- Changing `jira-reader` to accept a `focus_key` argument (deliberately kept
  in-orchestrator).
- Adding the picker or the "Next Epic?" loop to any VI-level command.
- Any change to `/specify` / `/design` (already grammar-native).
- Re-slugging or migrating existing `specifications/` folders.

## Open questions

None — both flagged sub-decisions were resolved at design approval.

## Appendix — current-state line anchors (for the plan)

- **implement.md** (550 lines): Phase 0 `L11–55` (rules `L33–55`; open-question guard
  `L35–44`; carry-forward `L31`; front-end cite `L22–23`); Phase 1.7 jira-reader
  dispatch `L135–142` (`depth: full`).
- **document.md** (1189 lines): Mode A Phase 0 `L30–101` (front-end `L32–33`;
  carry-forward `L36–38`; specs cite `L79–80`); Phase 3 jira-reader `L231–240`
  (`depth: full`); Phase 5 diff-summarization `L291–333`; Phase 5.7 doc-planning
  `L398–431`; Phase 4.5 space determination `L266–290`.
- **epics.md** (461 lines): Phase 0 `L17–35` (front-end `L19–20`; carry-forward
  `L24–27`; reject-direct `L29–31`); Phase 3 jira-reader `L137–148` (`vi-plus-epics`);
  Phase 6 write `L214–234`; Phase 7 review `L266–303`.
- **release-notes.md** (210 lines): Phase 0 `L24–37` (front-end `L26–27`; carry-forward
  `L31–33`; reject-direct `L35–37`); Phase 3 jira-reader `L112–121` (`vi-only | full`);
  Phase 6 render `L142–169`.
- **jira-input-resolution.md**: §Specs-resolution `L96–112`; §Output-contract (incl.
  `focus_key`) `L127–141`; §Progress-aware picker `L143–163`.

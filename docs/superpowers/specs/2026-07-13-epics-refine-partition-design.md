# `/epics` Refinement & VI-Partition Mode — Design

**Effort:** AI-First.md task (line 84, priority `[2]`) — `/epics <VI> <Epic>` re-refine + empty-Epic handling
**Target repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Version:** 2.28.0 (minor; edits commands + runtime agents + references; **no new command, no new agent** → counts unchanged Twenty/Thirty)
**Date:** 2026-07-13
**Test framework:** none — structural verification only (grep, `python3 -c json.load`, `git diff --stat`)

---

## 1. Goal

When a PE has pre-created **empty Epic shells** in Jira (one per team, each with a real Jira ID, an assigned team, and a summary/scope hint) and the `jira-workitem-importer` has re-imported the VI + those Epics into `$VAULT_PATH/jira-products/<VI-dir>`, `/epics` should **partition the VI scope across those team-Epics and fill each one in** — instead of treating linked Epics only as non-duplication constraints (today's behavior). The existing `<VI> <Epic>` focus mode becomes the single-Epic re-refine.

This helps draw **team-responsibility boundaries**. Example (from the requester): a Settings-2.0 schema at cluster level — the EMU team ports the UI generator from environment to cluster (a framework Epic), then Cluster Core builds the schema + API on top (a dependent Epic, no UI). Boundaries do not always partition cleanly; the command must surface undrawable boundaries rather than guess.

**Explicitly not** a new command. The task text proposed a singular `/epic <VI>`, but `/epics` (plural) already exists and `/epics <VI> <Epic>` already re-refines one Epic; a singular `/epic` next to `/epics` is a naming footgun. Decision (approved): fold both capabilities into `/epics` as an auto-detected **refinement mode**.

## 2. Current state (what exists today)

- `/epics <VI | dir> [focus-Epic]` — Jira-driven Epic-*writing* workflow. Argument grammar via `references/jira-input-resolution.md`. `mode: direct` rejected (`EPICS_NEEDS_JIRA`).
- **Output:** `$VAULT_PATH/jira-drafts/<jira_key>/` (when `$VAULT_PATH` set) or `<parent-of-export-root>/epic-drafts/<jira_key>/` (dir input). **Never** `jira-products/` — the importer re-creates that dir on every run, so writes there are lost (hard invariant, repeated across `epics.md`, `epic-writer.md`, `document.md`, `ready.md`, `release-notes.md`).
- **Reads** existing linked Epics (via `jira-reader depth: vi-plus-epics`) only for **non-duplication**; otherwise generates **net-new slug-named** Epic drafts.
- **Focus mode** (`focus_key`, set by `<VI> <Epic>`): re-drafts only that one Epic; Phase 7 reviews only that file (`epics.md:212–221`).
- Produces one `<slug>.md` per new Epic + one `_coverage.md` (requirement-coverage matrix, `_source: native|derived [+ VI-level spec]` first line, roll-up %, `| Req | Type | Text | Covered by | Status |`).
- Optional code scan (Phase 1 asks; Phase 4 resolves repos under `$REPOS_PATH`; Phase 5 runs `code-scanner` in batches ≤4).
- Consumes **VI-level ARD** (Phase 2.5, `epic: null`) and optional **VI-level spec** (Phase 2.6) — both additive/guarded.
- `epic-writer` (Sonnet/Opus per classification) writes Epic files + `_coverage.md`. `epic-reviewer` (**Opus**) gates with `PASS / PASS WITH RECOMMENDATIONS / BLOCK`.

## 3. Confirmed import data format (sample: PRODUCT-17742 / Epic MGD-12573)

Verified against a real import in the vault:

- Path: `$VAULT_PATH/jira-products/<VI-KEY>/<EPIC-KEY>/<EPIC-KEY>.md` (nested same-named subdir; VI itself at `<VI-KEY>/<VI-KEY>/<VI-KEY>.md`). Index at `<VI-KEY>/<VI-KEY>-index.md`.
- **Team** is in the Epic **frontmatter** key `team: "[DTT] Team Storage"` **and** in the `## Metadata` section line `**Team:** [DTT] Team Storage`. Extracted **verbatim** (the `[DTT]` org-unit prefix is kept, not parsed).
- **Team is NOT in the index** — the index "Role" column is the export role (`linked`/`root`), not the team. So team must be read from the Epic file (which `jira-reader` already opens at `vi-plus-epics`).
- **Empty-shell body** = summary (frontmatter `summary:` + H1) + importer boilerplate only: `## Metadata`, a `## Details` field-dump (all-zero counts — `### Children of Epic count 0.0`, etc.), `## Comments`. **No** `## Description`/scope/AC free-text.
- `status: "Open"` in frontmatter — matches the `workflow-states.md` Epic ladder ("Open | PE | /epics | Epic draft").

## 4. Design

### 4.1 Mode model (auto-detect)
- **`/epics <VI>`** → after the hierarchy read, if empty/almost-empty team-Epics are linked to the VI, present a **refinement-mode gate** (§4.3).
- **`/epics <VI> <Epic>`** → refine/re-refine that one Epic (existing focus mode), **enriched to iterate on the Epic's current imported content** rather than regenerate from scratch. Skips the gate.
- **No empty Epics detected + no focus key** → **byte-identical to today** (generate net-new). This is the no-regression anchor.

### 4.2 Detection — additive `jira-reader` fields
At `depth: vi-plus-epics`, `jira-reader` adds **three additive, per-linked-Epic fields** to its handoff:
- `refinement_candidate: true|false` — `true` when the Epic body has no substantive free-text beyond the summary + importer boilerplate (no populated `## Description`/scope/acceptance content, or such content ≤ a small threshold / merely restates the summary).
- `team` — verbatim from frontmatter `team:` (fallback: the `## Metadata` `**Team:**` line); empty string if absent.
- `scope_hint` — the Epic's dedicated description/scope text if present, else the `summary`.

Additive + only populated at `vi-plus-epics` depth ⇒ every other consumer (`/document`, `/ready`, `/release-notes`, `create-vi`, `specify`, `design`) is unaffected. No-regression on the shared reader is a hard requirement: an export with no empty Epics yields the same handoff as today plus these fields, which the existing generate-new path ignores.

### 4.3 Refinement-mode gate (new, after detection; only when candidates exist and no focus key)
Presents the detected empty team-Epics as a confirmable list — `<EPIC-KEY> · <team> · <scope_hint>` — and asks:
1. **Refine these N** (partition the VI across them),
2. **Generate net-new Epics** (today's behavior),
3. **Both**.

The listed set is **PE-adjustable** (detection *proposes*; the PE is the authority) — so a mis-classified Epic is never load-bearing. If `team` is empty for a candidate, it is flagged in the list and becomes a `[NEEDS CLARIFICATION]` resolved in the leftover/clarification gate.

### 4.4 Adaptive code-scan default
The code-scan choice remains an **always-asked interactive prompt** (never a hidden flag). In refinement mode its **default is ON when 2+ refinement targets** are being refined (a real cross-team boundary to draw), **OFF for a single** target. A one-line rationale accompanies the prompt either way. Generate-new / no-candidate paths keep today's default (ON).

**Ordering:** the adaptive default depends on the detected-target count, which is only known after the hierarchy read (Phase 3). So in refinement mode the code-scan prompt is asked **after** detection/the gate (§4.3), not in the current Phase-1 clarification block. The generate-new / no-candidate path keeps the Phase-1 ordering unchanged (no-regression anchor). The plan resolves exact phase numbers.

### 4.5 Partition, cross-team dependencies, undrawable boundaries
- The VI's `requirements[]` are **partitioned across the refinement targets**; each refined Epic's `## Scope (In/Out)` and `## Covers` reflect its slice.
- **Cross-team dependencies** are captured as explicit `## Dependencies` entries (e.g., Cluster-Core-schema Epic *depends on* EMU-framework Epic). `epic-reviewer`'s existing Epic-independence dimension is relaxed for refinement targets: **inter-team dependencies among the refined set are expected and legal** (they encode the real build order), whereas a forward dependency on a *not-yet-existing* Epic remains a finding.
- Genuinely undrawable boundaries → existing `[NEEDS CLARIFICATION]` markers, resolved in the batched gate (§4.6).

### 4.6 Leftover inline batched gate (no new command)
After partitioning, VI requirements covered by no team-Epic are the **leftover**. Reusing the existing Phase-6.2 batched-clarification pattern, the gate asks **per leftover item**: *assign to an existing team-Epic `<KEY>`* / *propose as a new Epic* / *defer*. Results:
- *assign* → the target Epic's draft is re-emitted to include it;
- *new Epic* → a slug-named net-new Epic draft (§4.7);
- *defer* → remains an uncovered row in `_coverage.md` + the final report.

### 4.7 Output layout
Write to the safe sibling `$VAULT_PATH/jira-drafts/<VI-KEY>/` (or `<parent-of-export-root>/epic-drafts/<VI-KEY>/` for dir input) — **never** `jira-products/`.
- **Refined team-Epics** (have real IDs) → **`<EPIC-KEY>.md`** (keyed).
- **Net-new leftover Epics** (no ID yet) → **`<slug>.md`** (today's convention).
- One `_coverage.md` maps VI reqs → team-Epics (by key) + net-new; uncovered rows = deferred leftover. The `_source:` first line is unchanged.

Refined Epic files surface the team — a `**Team:** <verbatim team>` line near the top of the Epic body — so the draft is self-describing.

### 4.8 `epic-writer` changes
- New handoff inputs: `refinement_targets[]` (`{key, team, scope_hint, current_body_path}`) and `mode: refine|generate|both`.
- For each refinement target: **read its current imported content** and iterate (fill/improve, preserve good content), key the output file by `<EPIC-KEY>.md`, and emit the `**Team:**` line.
- `_coverage.md` covers refined targets (by key) + any net-new; the roll-up counts partitioned coverage.
- Unchanged for `mode: generate` with no targets ⇒ identical output to today.

### 4.9 `epic-reviewer` conditional dimensions
When the review brief includes refinement targets, add (conditional, only in refine mode):
- **Refinement completeness** — every target is actually filled (a still-empty target is a BLOCKER).
- **Partition integrity** — the union of target scopes covers the intended VI slice without silent overlap; overlaps/uncovered-not-flagged are findings.
- **Cross-team dependency sanity** — inter-target dependencies present and acyclic; forward deps on non-existent Epics still flagged.
- **Team preserved** — each refined Epic records its assigned team.
Verdict tokens and severity schema unchanged.

### 4.10 Existing wiring (light touch)
- **ARD:** VI-level ARD (Phase 2.5) flows through unchanged; its `AD-N` invariants now also constrain how scope splits across teams (deviation-record line unchanged).
- **`references/workflow-states.md`:** Epic-ladder row for `/epics` stays valid ("Open → Epic draft"); add a parenthetical that `/epics <VI>` can refine empty team-Epics in place of generating net-new.
- **`references/next-phase-offer.md`:** `/epics` already listed; no routing change (refinement is a behavior, not a new phase).
- **`references/pre-lint.md`:** Epic pre-lint already checks Epic drafts; keyed `<EPIC-KEY>.md` files are covered by the same globs. Add a note that a refined file must carry a `**Team:**` line and a non-boilerplate `## Scope`.

## 5. No-regression contract (hard)
- No empty team-Epics detected **and** no focus key ⇒ the entire path is **byte-identical** to today (generate net-new).
- `jira-reader`'s three new fields are additive and depth-gated; all other consumers' handoffs are unchanged.
- `/vuln`, `/upgrade`, and every command that does not touch `/epics`/`jira-reader`/`epic-writer`/`epic-reviewer` are untouched (0-line diff).
- Sibling plugins `dt-style-guide` (0.2.2) and `obsidian-llm-wiki` (0.3.1) byte-identical.

## 6. Versioning & manifests
- Bump `plugins/dev-workflows/.claude-plugin/plugin.json` version `2.27.0 → 2.28.0` and the repo-root `.claude-plugin/marketplace.json` dev-workflows entry (line 12) in lock-step.
- **Count strings byte-identical** ("Twenty ... commands", "Thirty ... subagents", "four hooks") — no new command/agent, so counts must not change; verify no `+`/`-` on the description lines.
- CHANGELOG entry `## [2.28.0] — 2026-07-13`.

## 7. Out of scope
- Deep per-Epic code-boundary analysis (stays with `/specify <VI> <Epic>`).
- Writing to Jira or `jira-products/`.
- Any new command or agent; any change to sibling plugins.
- Automatic creation of the net-new leftover Epics in Jira (the command proposes drafts; the PE creates + re-imports).

## 8. Assumptions & risks
- **Team format** — resolved from the real sample (frontmatter `team:`; verbatim `[DTT] Team Storage`). Risk: exports without a `team:` key → handled by the empty-string fallback + `[NEEDS CLARIFICATION]` flag at the gate.
- **Filled-vs-empty threshold** — no sample of a *partially* filled Epic; the heuristic is deliberately lenient and the gate is PE-confirmable, so misclassification degrades gracefully.
- **Requirement partitioning quality** — depends on VI requirement granularity; when the VI is thin, `requirements_source: derived` reduces partition precision (same limitation as today's coverage matrix).

## 9. Verification (structural)
- `python3 -c 'import json,sys; json.load(open(p))'` on `plugin.json` + `marketplace.json`; both at `2.28.0`.
- `git diff` shows description count-strings unchanged; siblings + `/vuln` + `/upgrade` 0-line diff.
- `grep` confirms: `refinement_candidate`/`team`/`scope_hint` additive in `jira-reader.md`; refinement-mode gate + adaptive default + leftover gate present in `epics.md`; keyed `<EPIC-KEY>.md` + `**Team:**` in `epic-writer.md`; conditional refine dimensions in `epic-reviewer.md`.
- No-regression: a dry read confirms the generate-new/no-candidate branch text is unchanged from `2.27.0`.
- Command/agent file counts remain 20/30.

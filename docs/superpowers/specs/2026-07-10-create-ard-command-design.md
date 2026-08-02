---
tags:
  - tasks-exclude
---

# `/create-ard` command — design (dev-workflows v2.17.0)

**Date:** 2026-07-10
**Effort:** dev-workflows **v2.17.0** — additive
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Sub-project:** 3 of 3 (final) in the *VI-creation flow* (AI-First.md lines 95–98). Order: `/idea` (✅ v2.15.0) → `/create-vi` (✅ v2.16.0) → **`/create-ard`**.
**Trailer:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` — commit named files only, never `git add -A`.

---

## Goal

Add the **Product Architect (PA)** phase: `/create-ard` grounds on the mounted implementation repos and authors an **Architecture Requirements/Decision Document (ARD)** for a VI (or an Epic within it), establishing the architecture invariants the downstream inherits. The ARD is **optional** and **scoped**.

## Why (scope framing)

`/create-vi` produces the product-level VI; `/create-ard` adds the architecture frame *before* the VI is split into Epics and specified. It sits between `/create-vi` (PM) and `/specify` (PE). Distinct from the existing per-Epic `/design` (dev): the ARD is higher-altitude architecture (VI or Epic level) that `/design`, `/implement`, and `/specify` will later inherit — that consumption is a **dedicated follow-up (v2.18.0)**, not this effort.

## Research basis

Reuses this session's six-repo sweep: Alex's grounded `*-design.md` (Background → Grounding findings with real `file:line` → Design Decisions → Solution → Out of scope → Linked tickets); BMAD's architecture **spine** (only invariants that stop units diverging — `AD-N: Binds/Prevents/Rule`, altitude inheritance, Capability→Architecture map, pinned stack); and the existing `/design` command (closest analog — Dev phase, per-Epic, hard repo gate, embedded grill, Opus `design-reviewer`, tiered hard model gate).

## Decisions (locked in brainstorming)

1. **Optional + scoped** via the plugin's two-key `<VI> <Epic>` grammar: `/create-ard <VI-KEY>` → **VI-level** ARD; `/create-ard <VI-KEY> <Epic-KEY>` → **Epic-level** ARD (inherits the VI-level ARD read-only). Phase 0 advises when an ARD may be unnecessary (small/single-repo VI) but proceeds if wanted.
2. **One shape, depth scales with altitude** — one `references/ard-format.md` (below). VI-level = invariants + frame (no per-repo solutions); Epic-level = deeper.
3. **Per-area split (grill-driven):** for an Epic spanning separable areas in one repo (e.g. `cluster2` `server/`+`ui/`), the grill offers one combined ARD or one per area → `<EPIC>-<area>_ARD.md`.
4. **Grounding is architect-driven, NOT PR-derived** (no PRs exist at ARD time): cheap `$REPOS_PATH` discovery + `theme→repo` proposal + **ask the architect** + consolidated mount-or-descope, then `code-scanner` on the confirmed set.
5. **New Opus `ard-reviewer`** gate; **new `pa` role / `architecture` phase**; Opus orchestrator with `/design`-style tiered **hard** model gate.
6. **Verified (no bug):** `/design` and `/implement` do **not** assume implementation PRs exist — `/design` grounds from `$REPOS_PATH`+`code-scanner` (its PRs are its own output); `/implement` resolves repos from cwd/`@dir`/scan with `jira-reader` PR refs as empty-safe additive context. So dropping PR derivation here is consistent with the whole upstream.

---

## Artifact — the ARD

### Frontmatter

```yaml
---
title: <VI or Epic title> — ARD
scope: vi | epic
vi: <VI-KEY>
epic: <EPIC-KEY | null>          # set for Epic-level
area: <name | null>              # set for a per-area split ARD
status: draft | reviewed
grounded_repos:                  # the architect-confirmed set actually scanned
  - <repo-slug @ absolute path>
inherits: <path to <VI>_ARD.md | null>   # Epic-level inherits the VI-level ARD read-only
derived_from: <path to <VI>_ValueIncrement.md>
---
```

### Sections (depth scales; VI-level stays at invariants/frame, Epic-level goes deeper)

- `## Context` — the problem/goal frame from the VI (Epic-level adds the Epic's scope).
- `## Grounding findings (architecture as-is)` — what exists today, with **real `file:line`** across the `grounded_repos`. Descoped/unmounted repos appear only as Open questions, never as invented "as-is" claims.
- `## Architecture decisions` — `### [AD-N]: <title>` each with **Binds** (what it constrains) / **Prevents** (the divergence it stops) / **Rule** (a testable statement). Epic-level lists the inherited VI-level ADs read-only under "Inherited invariants" and must not contradict them.
- `## Cross-repo / component approach` — the Capability→Architecture map (which capability lands in which repo/component).
- `## Stack & invariants` — pinned versions / conventions that must hold.
- `## Edge cases & risks`.
- `## Open questions` — incl. ungrounded/descoped repos.
- `## Deferred` — VI-level: → per-Epic `/create-ard`/`/design`; Epic-level: → `/design`/`/implement`.

Format SSOT: `references/ard-format.md`. Quality rules: every "as-is" claim cites a grounded `file:line`; `AD-N` are testable and non-overlapping; VI-level carries **no per-repo detailed solutions** (that is `/design`); Epic-level ARDs may go deeper but remain architecture, not an implementation plan.

---

## Architecture — command flow (`commands/create-ard.md`)

```
/create-ard <VI-KEY> [<Epic-KEY>]

Phase 0  Resolve input (jira-input-resolution → VI + optional Epic; $SPECS_PATH; feature folder; prior-ARD; optionality advisory)
Phase 1  Configure (confirm scope; $REPOS_PATH; refresh policy)
Phase 1.5 Classify + model routing (Opus; tiered HARD gate for SIGNIFICANT/HIGH-RISK)
Phase 2  Read the VI (specs-repo VI, else jira-reader export); Epic-level: read Epic + inherit VI-level ARD
Phase 3  Architect-driven grounding (ls $REPOS_PATH + theme→repo proposal + ASK + mount-or-descope → code-scanner on confirmed set)
Phase 4  Author via relentless grill (ard-format.md); AD-N decisions; per-area split for a big Epic
Phase 5  Opus ard-reviewer gate (one fix cycle + re-review)
Phase 6  Handoff (write ARD file(s); branch+PR offer)
Phase 7  Next-step offer (VI: /epics→/specify; Epic: /specify→/design)
Phase 8  Terminal tail: impl-maintenance + emit-auto + emit-cost(architecture/pa) + capture-at-block
```

### Phase 0 — resolve input
- Resolve via `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` → `jira_key` (VI), `focus_key` (Epic or null), `jira_export_root`, `source`.
- `$SPECS_PATH` **required** (stop naming `SPECS_PATH` if unset).
- Feature folder: `specifications/<VI>-<vslug>/` (Epic-level nests `<EPIC>-<eslug>/`); honor an existing dir by key-number.
- **Prior ARD** at the target → Phase 1 offers refine-vs-fresh.
- **Optionality advisory:** gauge size (VI user-story count / scope breadth / #candidate repos); for a small single-repo VI, note "an ARD may be optional here" and offer to proceed or stop.

### Phase 1 — configure
Confirm scope (VI-level vs Epic-level), `$REPOS_PATH` (default `/workspace`), and repo-refresh policy (governs `code-scanner`).

### Phase 1.5 — classify + model routing
`model-routing` skill. Architecture is high-stakes → **Opus orchestrator**; **tiered hard gate** — SIGNIFICANT/HIGH-RISK require an Opus session (relaunch/override/cancel, like `/design`), SIMPLE/MODERATE advisory. `code-scanner` + `impl-maintenance` on the §2.1 Sonnet chain; `ard-reviewer` frontmatter-pinned Opus.

### Phase 2 — read the VI (+ Epic, + inherited ARD)
Read the VI from `$SPECS_PATH/specifications/<VI>-<vslug>/<VI>_ValueIncrement.md` when present (authored source), else via `jira-reader` from the export. Epic-level: read the Epic via `jira-reader` (scoped to `focus_key`) and, if a `<VI>_ARD.md` exists, load its `AD-N` invariants to inherit read-only.

### Phase 3 — architect-driven grounding (no PRs)
1. **Cheap discovery:** `ls "$REPOS_PATH"` top-level dirs (+ optional one-line identity: `timeout 5 git -C <dir> remote get-url origin` slug / README first heading). No deep content scan to guess relevance.
2. **Propose** a `theme→repo` mapping from the VI/Epic requirements against those dirs; **ask the architect to confirm / correct / add**. For any requirement that maps to no obvious repo, **ask outright** ("which repo covers `<X>`?").
3. **Missing repo → consolidated mount-or-descope gate:** `choices: ["Mount now & re-scan", "Ground only the confirmed-mounted set (record the rest as open questions)", "Specify an absolute path", "Cancel"]`.
4. **Ground the confirmed set:** `code-scanner` (Sonnet, batches ≤4 concurrent), scoped by themes → as-is findings with `file:line`. Descoped repos become Open questions.

### Phase 4 — author via grill
Relentless interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md`, authoring the ARD live against `ard-format.md`. Record `AD-N` decisions (Binds/Prevents/Rule); at Epic level, list inherited VI-level ADs read-only and never contradict them. For an Epic whose confirmed grounding spans **separable areas** (e.g. `server/`+`ui/`), grill: one combined ARD or one per area → write `<EPIC>-<area>_ARD.md` each.

### Phase 5 — review gate
Dispatch `ard-reviewer` (Opus). Verdict handling mirrors `/specify`/`/create-vi`: on `BLOCK`, fix inline + re-review once; else proceed. Cap: one fix cycle + one re-review.

### Phase 6 — handoff
Write the ARD file(s) into the feature folder. **Offer** (commit-when-asked): `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git", "Cancel"]`. Branch `ard/<VI>-<vslug>` (VI-level) or `ard/<EPIC>-<eslug>` (Epic-level); commit only the feature folder (never `git add -A`); PR targets `main`.

### Phase 7 — next-step offer (adaptive)
- **VI-level ARD:** if the VI has 0 Epics → offer `/epics <VI>` (then the Jira round-trip) then `/specify`; else offer `/specify`.
- **Epic-level ARD:** offer `/specify <VI> <Epic>` then `/design <VI> <Epic>`.
Guidance only — never auto-invokes.

### Phase 8 — terminal tail
`impl-maintenance` (Sonnet) → `emit-auto`; `emit-cost` (`command: /create-ard`, `phase: architecture`, `role: pa`, `jira_key`, `source`, `plugin_version`); **capture-at-block invariant** (`emit-block` before a plugin-gap halt; never for env/user halts — unset `$SPECS_PATH`, missing key, cancellation — or a review BLOCK). ADDITIVE — never fails the run, never writes to cwd, no user name.

---

## `ard-reviewer` (new Opus agent) — dimensions

- **Grounding is real & cited (BLOCKER):** every "as-is" architectural claim cites a `file:line` in a `grounded_repos` entry; a decision resting on a fabricated/uncited claim → BLOCKER. An ungrounded area must be an Open question, not an asserted fact.
- **`AD-N` well-formed (MAJOR):** each decision has Binds / Prevents / a testable Rule; vague/untestable → MAJOR.
- **Inherited invariants (Epic-level, BLOCKER):** the Epic ARD must not contradict an inherited VI-level `AD-N`.
- **Altitude purity:** VI-level carries no per-repo detailed solutions (→ MAJOR if it does the dev's `/design` job); Epic-level stays architecture, not an impl plan.
- **Open questions:** ungrounded/descoped repos are recorded, not silently dropped.
- Verdict `PASS` / `PASS WITH RECOMMENDATIONS` / `BLOCK`; same severity schema + output contract as `spec-reviewer`/`vi-reviewer`.

---

## Follow-ups (recorded; NOT built here)

- **(v2.18.0) ARD-consumption wiring — the committed next effort.** Wire ARD consumption into **`/design`** (primary consumer — Epic-level ARD as guidance, VI-level as inherited invariants; reads the most-specific available), **`/implement`** (respects `AD-N` invariants as guardrails), and **`/specify`** (references invariants + scope), at **both VI and Epic levels** (Epic inherits VI). Touches those three commands **and** their reviewers (`design-reviewer`, `code-review`, `spec-reviewer`). Its own brainstorm→spec→plan cycle.
- **Next-phase-offer-everywhere** — generalize the Phase-7 offer to all pipeline commands.
- **Revisit the `.obsidian/` vault-check plugin-wide.**

## Out of scope (YAGNI)

- No PR derivation (verified unnecessary). No code *writing* (architecture only). No HTML render.
- ARD-consumption wiring (the v2.18.0 follow-up). No changes to `/specify`/`/design`/`/implement` in this effort.

## Verification (structural — no test framework, no husky/prettier hook)

- `python3 json.load` on both manifests; version 2.17.0 lock-step; the two `dev-workflows` descriptions **byte-identical**; siblings `dt-style-guide` 0.2.2 / `obsidian-llm-wiki` 0.3.1 unchanged.
- grep anchors: `commands/create-ard.md` phases 0–8 + `jira-input-resolution` cite + architect-driven grounding (`ls`/ask/mount-or-descope) + `code-scanner` dispatch + `subagent_type: "dev-workflows:ard-reviewer"` + `emit-cost`(`architecture`/`pa`) + capture-at-block + two-key scope; `references/ard-format.md` frontmatter keys + `AD-N` + sections; `agents/ard-reviewer.md` `model: opus` + dimensions + verdicts.
- count reconciliations: `feedback-emission.md` ten → eleven; `cost-emission.md` VI-lifecycle enum + new `| /create-ard | architecture | pa |` row; `dependencies.md` grilling list includes `/create-ard`; README `Eleven → Twelve` workflow commands + `/create-ard` table row + `eight → nine` VI-lifecycle cost line (both occurrences) + `ten → eleven` feedback list.
- No implementation-PR assumption introduced (grounding is architect-driven).

## File manifest (10 — 3 new + 7 modified)

**New**
- `references/ard-format.md`
- `agents/ard-reviewer.md`
- `commands/create-ard.md`

**Modified**
- `references/feedback-emission.md` — ten → eleven
- `references/cost-emission.md` — VI-lifecycle enum + new `| /create-ard | architecture | pa |` row
- `references/dependencies.md` — add `/create-ard` to the grilling-embed list
- `.claude-plugin/plugin.json` — version 2.17.0 + description (Eighteen → Nineteen commands w/ `/create-ard`; Twenty-eight → Twenty-nine subagents w/ `ard-reviewer`)
- `.claude-plugin/marketplace.json` — `dev-workflows` entry version + byte-identical description
- `CHANGELOG.md` — prepend `## [2.17.0] — 2026-07-10`
- `README.md` — lead count, `/create-ard` table row, cost + feedback count lines

## Release discipline

Branch `ivgu/NOISSUE-create-ard-command`; commit named files only (never `git add -A`); trailer as above. Version lock-step (plugin.json + marketplace.json dev-workflows entry). Prepend CHANGELOG (em-dash date). Merge ff to `main`; **push only when the user asks**. Watch for lima read-after-write flakiness (fsck-first, `update-ref` the dangling commit if a ref-write fails; verify HEAD after each).

---
tags:
  - tasks-exclude
---

# `/ready` — status-anchored readiness gate — design (v2.24.0)

**Status:** Shipped in dev-workflows v2.24.0 — pre-implementation design snapshot, kept as authored.
**Date:** 2026-07-12
**Plugin:** dev-workflows (repo `/workspace/ihudak-claude-plugins`)
**Version:** 2.23.0 → **2.24.0** (minor; NEW command + NEW agent + NEW reference)
**Counts:** 19 → **20** slash commands / 29 → **30** reusable subagents (description strings updated in lock-step)
**Source:** AI-First.md line 85 borrow analysis — the flagship "cross-artifact readiness gate" (3-of-4-repo convergent finding), re-anchored on Jira status per the user's 2026-07-12 decision.

## 1. Goal

A new `/ready <VI> [<Epic>]` command: a **read-only, status-anchored readiness *verifier***. It reads the **Jira workflow status** (already imported and already emitted by `jira-reader`) as the source-of-truth anchor, then verifies that the downstream artifacts (ARD, spec, design) actually justify that status and the next transition — answering the real question *"is this VI/Epic genuinely ready for AI-driven development?"*

It **never sets status** (humans do that in Jira; the importer brings it back). It reports **SUPPORTED / PARTIAL / NOT-SUPPORTED** + a coverage roll-up + cross-artifact mismatches, and persists a derived evidence snapshot (`_readiness.md`) in `$SPECS_PATH` for team visibility.

## 2. Motivation & grounding

- **Convergent finding (3 of 4 researched repos):** SpecKit `/analyze`+`/converge` and BMAD `check-implementation-readiness` all provide a *joint* cross-artifact readiness check, distinct from per-artifact reviewers. Our suite gates each artifact alone (vi/ard/epic/spec/design reviewers) and has a within-`/epics` coverage matrix, but nothing checks VI→ARD→Epics→Spec→Design are *jointly* consistent and complete before `/implement`.
- **Jira as the single source of truth for readiness *state* (user decision 2026-07-12).** Readiness state is the Jira status ladder, managed by humans + the workitems importer — NOT a custom field. A custom field in `jira-products/` is wiped on every re-import; one in `$SPECS_PATH` would drift from Jira. The **native status survives re-import precisely because it is re-sourced from Jira each time.**
  - **VI ladder:** Open → Problem Stated → Use cases defined → Ready for Implementation → Implementation → Release Preparation → Post GA.
  - **Epic ladder:** Open → In Preparation → Refined → In Progress → In Review → Closed.
- **Empirical confirmation (checked in real data):** every imported ticket carries `status:` frontmatter; the index table has a `Status` column `jira-reader` already requires; VI-level `status: "Ready for Implementation"` / `"Post GA"` appear in real exports; and **`jira-reader` already emits `value_increment.status` + per-`linked_items[].status`.** ⇒ **No importer change and no `jira-reader` change are needed** — the status pipe is already built end-to-end.
- **Why a verifier, not just a status reader:** a Jira status is a *declared claim* by a human; the cross-artifact check is *verification* of that claim. Only reading the artifacts catches "marked Ready for Implementation, but Epic E3 has no design / AC-4 has no spec coverage / the design contradicts an `AD-N`." Status anchors the gate; artifacts prove it.

## 3. Scope

### In scope
1. New `commands/ready.md` — the status-anchored verifier command.
2. New `agents/readiness-reviewer.md` (Opus) — the only reviewer doing *cross-artifact joint* analysis.
3. New `references/workflow-states.md` — the status ↔ command ↔ role ↔ expected-artifact rubric (also feeds AI-First line-96's role/workflow graph).
4. `commands/implement.md` — a soft, non-blocking pre-flight (Jira mode only).
5. `references/next-phase-offer.md` — `/ready` added to the routing graph as an optional Team/Dev node.
6. Manifest version bump + count/description-string updates + CHANGELOG.

### Out of scope
- Writing status back to Jira (humans own status; `/ready` is read-only on state).
- Any `jira-reader` change (already emits status + requirements) or importer change (external; not needed).
- Code *scanning* (reading repo contents) — `/ready` is **doc-only** (code grounding is `/design`'s job). A best-effort repo-*availability* presence-check **is** in scope (see §7 dimension 7 — presence only, no scanning/mounting).
- Auto-committing the `_readiness.md` report (git is the user's responsibility).
- The Tier-1 "polish batch + pre-lint" and all Tier-2/3 borrow items — separate efforts.

## 4. Grammar & input resolution

- **`/ready <VI>`** — whole-VI readiness across all in-scope Epics.
- **`/ready <VI> <Epic>`** — one Epic's chain (Epic → spec → design), inheriting VI-level context.
- **Phase 0** resolves input via the shared `references/jira-input-resolution.md` front-end (jira-driven only; two-key grammar; `mode: direct` → stop with `READY_NEEDS_JIRA`). Requires **`$SPECS_PATH`** (for artifacts, like `/design`) and the **vault `jira-products`** (for the status + requirement ground truth). Artifacts are read from the specs-repo **main** (clean checkout, never a branch — same rule as `/design`).

## 5. Inputs read

- **Status + requirement ground truth ← `jira-reader`** (VI-level: `depth: vi-plus-epics`; Epic-level: focus). Uses `value_increment.status`, `linked_items[].status` (each Epic), and `requirements[]` (v2.21.0 native `US/AC/SM/FR/UC`).
- **Downstream artifacts ← `$SPECS_PATH`** VI dir + Epic subdirs: `<VI>_ARD.md`, VI `specification.md`, and per-Epic `<EPIC>-<eslug>/{<EPIC>_ARD.md, specification.md, design.md}`. An **absent artifact is a finding, not an error.**
- **Applicable ARD ← `references/ard-resolution.md`** (reused; VI-level or Epic-level per grammar).
- **Repo availability (best-effort) ← `$REPOS_PATH`** — presence of the clones the work will need (derived from Epic `## Pull Requests` / `design.md` / ARD grounding), checked via the `/epics` slug→clone map. **Presence only — no scanning.**

## 6. The status↔expectation rubric — `references/workflow-states.md` (new)

A single reference mapping each VI/Epic status to **(a)** its owning role, **(b)** the pipeline command that drives the transition into it, and **(c)** the artifacts expected to exist at that status. It is the rubric `readiness-reviewer` applies, and the artifact that feeds AI-First line-96's role graph. Illustrative rows (the reference encodes both full ladders):

- **VI "Use cases defined"** (PM) ⇒ VI authored with use cases / stories (`/create-vi`; optionally a VI-level `specification.md` via `/specify <VI>`).
- **VI "Ready for Implementation"** (PE→Team) ⇒ Epics defined (`/epics`); each in-scope Epic at **Refined+** with a `specification.md` (`/specify`) and a `design.md` (`/design`); requirement coverage complete; ARD (if any) respected; no cross-artifact contradictions. **This is the headline gate.**
- **Epic "Refined"** (PE→Team) ⇒ the Epic is *ready to be worked*: `specification.md` (`/specify`) **and** `design.md` (`/design`) present, coverage complete, ARD (if any) respected. **This is the Epic-level headline gate** — the analogue of VI "Ready for Implementation".
- **Epic "In Progress" / "In Review"** (Team) ⇒ work has already started / is under review — *past* the readiness point; `/ready` reports this and notes the gate is moot.

The rubric is advisory guidance for the reviewer, not a hard schema — it tolerates orgs that skip optional artifacts (e.g. no ARD), which downgrade to CONCERN, not BLOCKER.

## 7. Components & phases

### `commands/ready.md`
- **Phase 0 — Resolve input** (front-end, two-key grammar; require `$SPECS_PATH` + vault; read artifacts from specs main).
- **Phase 1 — Clarify (light) + artifact inventory.** Enumerate, per Epic, which artifacts exist vs. are absent; display the resolved paths + the declared Jira statuses.
- **Phase 1.5 — Classify + model-routing** (MODERATE; `readiness-reviewer` frontmatter-pinned Opus).
- **Phase 2 — Read ground truth** (`jira-reader`) → statuses + `requirements[]`.
- **Phase 2.5 — Resolve ARD** (`ard-resolution.md`; `status: none` → the ARD dimension is simply inactive).
- **Phase 3 — Deterministic skeleton.** Mechanically build (a) the coverage map (which requirement IDs appear in which artifact by ID/section) and (b) the status-expectation checklist (which expected artifacts for the declared status are present/absent), and (c) a best-effort repo-availability presence-check (slug→clone map under `$REPOS_PATH`; presence only, no scanning). Cheap first pass; no model judgment.
- **Phase 4 — Semantic readiness review** (`readiness-reviewer`, Opus) → findings + verdict.
- **Phase 5 — Write `_readiness.md` + terminal report** (see §8–§9).
- **Phase 6 — Post-run maintenance & feedback** (mirror `/epics` Phase 8: the four maintenance agents; **the feedback collector runs here** — persist plugin feedback via `emit-auto` / `feedback-emission.md`, same as every pipeline command).
- **Phase 7 — Emit follow-up tasks** (mirror; `followup-emission.md`).
- **Phase 8 — Session cost** (mirror; `cost-emission.md`; `role: team`, `phase: readiness`).

### `agents/readiness-reviewer.md` (Opus)
- **Inputs:** the `requirements[]` inventory, the Phase 3 coverage + status-expectation skeleton, the artifact texts, `applicable_ard`, and the `workflow-states.md` rubric.
- **Dimensions:**
  1. **Status consistency** — does the evidence justify the *declared* status and the *next* transition? (headline)
  2. **Coverage chain** — every VI requirement → ≥1 Epic → a spec → a design (to the depth that exists). VI requirement with no Epic = **MAJOR**; in-scope Epic with no spec/design when the status implies it should = **MAJOR**; absent optional artifact = **CONCERN/MINOR**.
  3. **Cross-artifact alignment** — terminology drift + contradictions across VI↔ARD↔spec↔design.
  4. **ARD conformance** — spec/design/Epics respect `AD-N`; reuses the deviation-record convention. *Conditional* on an ARD existing (skipped when `applicable_ard` absent).
  5. **Scope integrity** — spec/design items with no upstream VI/Epic parent = scope creep, flagged.
  6. **Identifier integrity** — IDs consistent + unique across the chain.
  7. **Repo availability (best-effort)** — the repo list derived in Phase 3 (from Epic `## Pull Requests` / `design.md` / ARD grounding), checked for presence under `$REPOS_PATH` (reusing the `/epics` Phase 4 slug→clone map; **presence only, no scanning**). A needed-but-unmounted repo = **MAJOR** (it will hard-stop `/design`/`/implement`); a list not yet derivable (pre-implementation, no PRs) = reported, **not** blocking. Complementary early-warning — `/design`/`/implement` still enforce their own strict run-time repo gates.
- **Output:** per-dimension findings (BLOCKER / MAJOR / MINOR / NIT with `file:section` evidence) + one overall verdict.

## 8. Verdict semantics

Mapped to the Jira status the item is *declared* at (or aspiring to):
- **SUPPORTED** — the artifacts justify the current status and support the next transition.
- **PARTIAL** — mostly, with named gaps; advance with caution.
- **NOT-SUPPORTED** — the declared status overstates reality; named blockers.

"Ready for AI-driven development" = SUPPORTED (or PARTIAL with acknowledged gaps) for the transition into **Ready for Implementation** (VI) / **Refined** (Epic). `/ready` recommends the human update the Jira status accordingly; it never writes it.

## 9. Persistence of the verdict

- Write **`_readiness.md`** to the VI dir `$SPECS_PATH/specifications/<VI>-<vslug>/` (VI-level) or the Epic subdir `<VI>-<vslug>/<EPIC>-<eslug>/` (Epic-level). **Overwritten each run** — a current-state snapshot stamped with the run timestamp, the analyzed git rev of the specs repo, and the Jira status(es) it checked against.
- **NEVER auto-committed** (git is the user's responsibility; avoids PR churn on frequent re-runs). The Phase 5 report names the written path and reminds the user to commit it so teammates see it.
- **NEVER** writes to Jira, `jira-products/`, or the vault. **NEVER** branches.

## 10. Wiring (minimal, additive)

- **`commands/implement.md` — soft pre-flight (Jira mode only).** After resolving the item, read its declared Jira status (via the existing `jira-reader`/index read). If the status is below **Ready for Implementation** (VI) / **Refined** (Epic), or a co-located `_readiness.md` records **NOT-SUPPORTED / PARTIAL**, surface a **one-line, non-blocking** recommendation to run `/ready` first. **Direct mode → byte-identical** (no Jira/status context, nothing added).
- **`references/next-phase-offer.md`.** Add `/ready` as an optional Team/Dev node: `/design <VI> <Epic>` → *optionally* `/ready <VI> <Epic>` → `/implement`; `/ready` → `/implement` (SUPPORTED) or "resolve the named gaps + update the Jira status" (PARTIAL/NOT-SUPPORTED). Guidance-only; `/ready` follows the same `### Next step` contract.

## 11. No-regression

- New command/agent/reference; every existing command is byte-identical **except**: (a) `/implement`'s new Jira-mode pre-flight (direct mode unchanged), and (b) the additive `/ready` entry in `next-phase-offer.md`.
- `jira-reader` **unchanged** (already emits status). The external importer is **not** touched (not needed).
- Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1), `/vuln`, `/upgrade` untouched.
- Counts 19→20 / 29→30 — description strings bumped in lock-step in `plugin.json` + the `dev-workflows` entry in `marketplace.json` (exact current spellings resolved from the repo in the plan, not asserted here).

## 12. Model routing

MODERATE. `jira-reader` on the §2.1 Sonnet detection chain; `readiness-reviewer` frontmatter-pinned to the §2 Opus chain (cross-artifact judgment); coordination + interactive gates on `current_model`. If no Opus resolves, `readiness-reviewer` falls to the Sonnet floor — record the degradation.

## 13. Verification (structural — no test framework)

- `python3 -c json.load` parses both manifests; version `2.24.0` in `plugin.json` + the `dev-workflows` `marketplace.json` entry; command count = 20, agent count = 30 (recount from `commands/`+`agents/`); description strings say "Twenty…"/"Thirty…" (recomputed spellings).
- grep anchors: `ready.md` phases (0–8) + the SUPPORTED/PARTIAL/NOT-SUPPORTED verdict; `readiness-reviewer.md` seven dimensions (incl. the best-effort repo-availability check); `workflow-states.md` both ladders + the expected-artifact rows; `implement.md` the Jira-mode pre-flight + its non-blocking/`direct`-untouched guard; `next-phase-offer.md` the `/ready` node.
- `git diff --stat main` shows only: NEW `commands/ready.md`, NEW `agents/readiness-reviewer.md`, NEW `references/workflow-states.md`, `commands/implement.md`, `references/next-phase-offer.md`, `plugin.json`, `marketplace.json`, `CHANGELOG.md`. `agents/jira-reader.md`, `/vuln`, `/upgrade`, and both sibling plugins show **no** diff.
- CHANGELOG prepends `## [2.24.0] — 2026-07-12`.

## 14. Files changed

- NEW `commands/ready.md`
- NEW `agents/readiness-reviewer.md`
- NEW `references/workflow-states.md`
- `commands/implement.md` — Jira-mode soft pre-flight
- `references/next-phase-offer.md` — `/ready` node
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — 2.24.0 + counts + description strings
- `CHANGELOG.md` — 2.24.0 entry

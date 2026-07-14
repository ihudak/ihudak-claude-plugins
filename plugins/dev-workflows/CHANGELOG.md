# Changelog

All notable changes to the **dev-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [2.31.0] — 2026-07-14

Fixes from a full internal-correctness audit (2 BLOCKER, 7 MAJOR, 26 MINOR findings). No new commands, agents, or hooks — counts unchanged.

### Fixed

**Blockers**
- `test-baseliner` never emitted the `status:` field that `vuln-fixer`/`upgrade-executor` branch their entire verify → proceed/revert control flow on (it only returned a differently-named, differently-valued `Comparison status:`) — every status-branch in both consumers was dead code. Added an explicit `Status` line with a documented computation rule to both capture and verify output, and rewrote the handoff SSOT to match the agent's real Markdown output shape.
- `docs-style-checker` dispatches `dt-style-guide:dt-style-checker` as its complementary/fallback/sole pass but didn't declare `Task` in `tools:` — the dispatch couldn't execute, so the style gate silently no-op'd on any repo without a primary linter.

**Majors**
- `vuln.md` (3×) and `upgrade.md` (4×) used the Copilot CLI's `agent_type:` instead of Claude Code's `subagent_type:`, breaking every sub-agent dispatch in both commands; the `model-routing` SSOT §5 example taught the same wrong param. Also fixed a leaked GitHub Copilot bot co-author trailer in `vuln.md`'s commit template and `vuln-fixer.md`.
- `implement.md` Phase 2B/3B carried stale "invoke via `general-purpose` with a `model: opus` override" prose that contradicted the frontmatter-pinned `subagent_type` dispatch directly below it.
- `upgrade-planner.md` claimed the orchestrator pins it to Opus for SIGNIFICANT/HIGH-RISK; `upgrade.md` always invokes it on the Sonnet chain before classification even happens — Opus review of a risky plan is `risk-planner`'s job, not a re-invocation of `upgrade-planner`.
- All 14 commands that invoke the `Skill` tool (the 13 model-routing-aware commands plus `prompt-brainstorm.md`) omitted `Skill` from `allowed-tools` — none of them could run their mandatory classification step if `allowed-tools` is enforced.
- `doc-writer.md` was told to name the Jira key in the changelog entry — `doc-planner`/`doc-reviewer`/`document.md` Phase 8.5 all BLOCK on exactly that.
- `references/handoff/jira-reader.md`'s `pull_requests[]` schema had a phantom `also_in` field (nothing emits it) and was missing `branch_from`/`branch_to`, which the agent does emit and `diff-summarizer` requires.
- `impl-maintenance`'s `Command run` enum (handoff + agent) listed only 9 of the 12 invoking commands — `/idea`, `/create-vi`, `/create-ard`, `/ready` had no valid slot to pass.

**Minors**
- Gave `upgrade-executor`, `upgrade-planner`, `vuln-fixer`, `vuln-research` explicit `tools:` (previously undeclared, inheriting everything) for parity with the other 26 agents.
- Added `BASELINE_FAILED` to `vuln-fixer`'s declared status enum and an explicit `NO_TESTS` branch in its baseline step; required `Command run: /vuln` / `/upgrade` in each command's `impl-maintenance` handoff (both previously defaulted to mislabeling as `/implement`); renumbered `implement.md`'s "Pre-Phase 2" to "Phase 1.6" (it sat between 1.5 and 1.7).
- Fixed `document.md`'s Phase 0 step numbering (1, 3–8 → 1–7) and every cross-reference to it; repointed 3 dead "Increment 2/3" pointers to the real phases (5.9, 6.3) that implement that logic.
- Swapped `epics.md`'s inverted 6.1/6.2 sub-phase labels (clarifications physically ran before the style check but was numbered after it) across all internal and 3 external cross-references.
- Reconciled `release-notes-writer`'s handoff schema (missing `code_repos` input, missing `jira_phrasing`/`source_phrasing`/`source_location` in `gaps[]`); aligned `doc-fixer`'s declared finding-schema field name (`description` → `message`, matching what producers actually emit); gave `doc-writer` `Bash` (scoped to local screenshot copy only) since `image_policy: local` requires a file copy its prior tools couldn't perform.
- `specify.md`: deleted a dead "(design §7)" pointer. `create-ard.md`: converted a prose jira-reader fallback into a formal Agent block with `depth`/`jira_key` (the agent hard-refuses without them) and added it to the `detection_model` consumer annotation. `ready.md`: added the missing `model:` on the `readiness-reviewer` dispatch. Replaced the non-enum "CONCERN" severity term with `MINOR` in `readiness-reviewer.md` / `workflow-states.md`. `idea.md`: carried `source_refs`/`provenance` forward so Phase 4 can build the `sources:` frontmatter entry it claims to append.
- Reworded `api-guideline-reviewer.md`'s self-contradicting "load ALL files — never a subset" (it lists a curated subset); marked `guideline-reviewer.md`'s dt-app MCP lookup section optional/environment-dependent (this plugin doesn't bundle that MCP server); synced `code-scanner`/`diff-summarizer`'s inline Output blocks to their handoff SSOTs (both were missing the `prep:` block; diff-summarizer was also missing several per-PR fields); prefixed 3 remaining bare `references/…`/`scripts/…`/`agents/…` citations with `${CLAUDE_PLUGIN_ROOT}/`; documented that `jira-reader`'s `NOT_FOUND` status covers both the Form-1 (`jira_export_root`) and Form-2 (vault path) resolution.

### Notes

- `guideline-reviewer.md`/`api-guideline-reviewer.md`'s remaining bare `references/guidelines/…` mentions, and `create-vi.md`/`create-ard.md`'s description-frontmatter mentions of `references/*-format.md`, are confirmed **not** bugs — the former carry their own "all paths relative to `${CLAUDE_PLUGIN_ROOT}`" preamble, the latter are human-facing catalog text, not runtime citations (both already excluded by the prior `12c245a` cleanup).

## [2.30.0] — 2026-07-13

### Changed

- **Documentation-consistency refresh.** README, repo-root CLAUDE.md, and the `model-routing` SKILL.md were brought in line with the plugin as shipped: the README Agents section now says **Thirty** subagents and **nine** Opus gates (added `vi-reviewer`, `ard-reviewer`, `readiness-reviewer`, `idea-reader` rows); the Commands table covers all 20 commands (one merged `/document` row + 8 previously-undocumented commands) with corrected classification framing; the Reference-docs catalog lists the ~18 SSOTs added since v2.14; and the `model-routing` consumer list is corrected to the **13** commands that invoke it (in CLAUDE.md and the skill's own description).
- **CLAUDE.md relationships diagram** extended to the six VI-creation-flow commands (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, `/ready`) and their agents, with a concise VI-creation invariants block.
- The stale `## /implement workflow` per-phase mermaid graph was **replaced** with a coarse decision-shape graph (no Phase-N nodes) that no longer drifts when a phase is inserted.
- The four newly-cited handoff schemas (`code-scanner`, `diff-summarizer`, `impl-maintenance`, `jira-reader`) were reconciled to the agents' current input/output contracts — they had silently drifted while uncited (e.g. `impl-maintenance`'s schema still described a write-to-KB contract, contradicting the agent's current suggest-only report). No agent behavior changed; only the schema docs were corrected.

### Added

- The four handoff-schema references (`code-scanner`, `diff-summarizer`, `impl-maintenance`, `jira-reader`) are now cited by their agents, matching the wired sibling pattern.

### Notes

- No new command, agent, or hook — counts unchanged (Twenty slash commands / Thirty reusable subagents). Docs + one additive agent citation each; no command body changed.

## [2.29.0] — 2026-07-13

### Added

- `references/session-hygiene.md` — the plugin-wide SSOT for **session-hygiene suggestions**: a prepare-checkpoint that flushes resume-critical state to `<VI-dir>/dev-workflows/resume.md`, then a role-aware `/compact` (same role) vs `/clear` (cross-role handoff) suggestion, plus a `/rename <VI-ID>-<slug>-<role>` session-name aid. Guidance-only — never auto-run.
- A `### Context hygiene` block at the Final Report of every pipeline command (role-aware per `next-phase-offer.md`), and a mid-phase `/compact` suggestion at `/implement`'s checkpoint.

### Changed

- `/vuln` and `/upgrade` now end with a plain `/compact` suggestion (big non-pipeline runs).
- `next-phase-offer.md` and `context-management.md` cross-reference `session-hygiene.md`.

### Notes

- No new command, agent, or hook — counts unchanged (Twenty slash commands / Thirty reusable subagents).
- `/idea` and `/create-vi` (pre-VI-Key PM ideation) get the suggestion but no `resume.md`/`/rename`; direct/doc-edit modes omit the block.

## [2.28.0] — 2026-07-13

### Added

- **`/epics` refinement & VI-partition mode** — when a PE pre-creates empty Epic shells in Jira (one per team) and they are re-imported, `/epics <VI>` now detects them and offers to **refine** them in place: it partitions the VI scope across the team-Epics, fills each in (keyed `<EPIC-KEY>.md` in `jira-drafts/`, carrying a `**Team:**` line), captures cross-team dependencies, and routes leftover VI scope through an inline batched gate (assign to a team-Epic / propose a net-new Epic / defer). `/epics <VI> <Epic>` re-refines a single Epic by iterating on its current imported content. No new command — refinement is an auto-detected mode of `/epics`.
- `jira-reader` (`depth: vi-plus-epics`) now emits three additive per-Epic fields — `refinement_candidate`, `team` (verbatim from the Epic frontmatter `team:`), and `scope_hint` — used to detect empty team-Epic shells. Additive and depth-gated; other consumers are unaffected.
- `epic-reviewer` gains four conditional refinement dimensions (refinement completeness, partition integrity, cross-team dependency sanity, team preserved), active only when the review brief includes refinement targets.

### Changed

- The code-examination default is now **adaptive in refinement mode** — ON when 2+ team-Epics are being refined, OFF for a single target (always still asked interactively). The generate-net-new path is unchanged.

### Notes

- Strictly additive / no-regression: `/epics <VI>` with no empty shells and no focus key is byte-identical to 2.27.0. `/vuln`, `/upgrade`, and the sibling plugins are untouched. Command / agent counts unchanged (Twenty / Thirty).

## [2.27.0] — 2026-07-13

### Added

- **`## Workflow overview`** in `README.md` — a mermaid role-graph (PM / PA / PE / Dev / QA lanes) of the idea→VI→ARD→Epics→spec→design→implement→document→release-notes pipeline, an annotation table (role · starting command · consumes · produces), a "Sources of truth & artifact homes" note (including where feedback / cost / follow-up files land in the specs repo, and that committing them is expected), and a "Cross-cutting commands" subsection surfacing `/feedback`, `/prompt*`, `/vuln`, `/upgrade`, and the setup / review utilities.

### Changed

- **`/specify` is labelled PE, not PM**, everywhere — `commands/specify.md`, `commands/design.md`, the `README.md` command table, and `references/workflow-states.md` — matching `references/next-phase-offer.md` (already routed under PE) and the command's own `role: pe` cost attribution. No behavior change.
- Repo-root `CLAUDE.md` — de-staled the retired `/impl:*` colon-taxonomy (`/impl:code`, `/impl:docs`, `/impl:jira:*`, …) to the current flat commands (`/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`) across the workflow-relationships diagram, the model-routing / source-truth references, and the per-command invariants blocks.
- Corrected the stale "Twelve workflow slash commands" lead in `README.md` to "Twenty …".

## [2.26.0] — 2026-07-12

### Added

- **`references/pre-lint.md`** — new SSOT of deterministic, grep-expressible structural checks (universal + per-artifact for VI/ARD/spec/Epic/design). A thin advisory **Structural pre-lint** phase now runs immediately before the Opus reviewer in `/create-vi` (3.6), `/create-ard` (4.5), `/specify` (5.5), `/design` (5.5), and `/epics` (6.3): it surfaces mechanical defects (missing sections, duplicate/gapped IDs, stray placeholders, ARD `Binds`/`Prevents`/`Rule`, spec open-questions-count) and inline-fixes the trivial ones so an Opus pass is not consumed on structure. Advisory — never hard-blocks; the reviewers remain the gate and are unchanged.
- **`references/context-management.md`** — new long-run strategy doc (scope-to-N / sub-agent-per-`[P]` / decompose); `/implement` Phase 3B cites it for long step lists.

### Changed

- **Grilling technique** — added an "Autonomous / background invocation" guard: with no human turn available, genuine decisions are recorded as open questions (`[NEEDS CLARIFICATION]` / `- [ ]`) rather than self-answered.
- **`vi-reviewer`** — the substance-over-theater dimension now also flags non-empty-but-hollow prose (vision/persona/NFR that reads well but states no testable commitment) as `MAJOR`.

### Notes

- Polish batch from the AI-First line-85 borrow analysis. 2 new reference docs, 0 new commands/agents — counts unchanged (20 commands / 30 subagents), descriptions byte-identical. No-regression: `/vuln`, `/upgrade`, the four other reviewer agents, and the sibling plugins are untouched. (Items "/idea URL-fetch policy" and "/specify seam step" were dropped — no live fetch exists in `/idea`, and the seam concept already lives in `/design`.)

## [2.25.0] — 2026-07-12

### Changed

- **`/prompt-grill-me`** no longer hands off to Matt Pocock's `/grilling` skill (or the `superpowers:brainstorming` fallback). It now grills the fix **inline** — a bounded one-question-at-a-time interrogation of the correction following the embedded `references/grilling-technique.md`. Feedback capture (`emit-prompt`, `origin: prompt`) and the "never commits / never writes to a repo or the cwd" guarantees are unchanged.
- **Dropped the optional `mattpocock-skills` dependency.** Removed it from the *Recommended companions* table in `references/dependencies.md` and the operational mentions in `README.md`, `references/feedback-emission.md`, and `references/grilling-technique.md`. The grilling technique remains fully embedded; the "adapted from mattpocock grill-me/grilling" attribution is retained.

### Notes

- Closes AI-First line 87. The five authoring commands (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`) were already zero-dependency. Counts unchanged — **20** commands / **30** subagents (`/prompt-grill-me` retargeted, not removed). No-regression: `/vuln`, `/upgrade`, `jira-reader`, and the sibling plugins are untouched.

## [2.24.0] — 2026-07-12

### Added

- **`/ready <VI> [<Epic>]`** — new status-anchored readiness gate. Reads the Jira workflow status (already emitted by `jira-reader` — no importer/reader change) and verifies the ARD/spec/design artifacts justify it and the next transition; returns **SUPPORTED / PARTIAL / NOT-SUPPORTED** with a coverage roll-up and cross-artifact findings. Read-only: never sets Jira status, never branches, never auto-commits. Writes a `_readiness.md` evidence snapshot to `$SPECS_PATH` for team visibility. Doc-only, with a best-effort repo-availability presence check.
- **`readiness-reviewer`** — new Opus subagent; the only reviewer doing joint cross-artifact analysis (status consistency, coverage chain, alignment, ARD conformance, scope integrity, identifier integrity, repo availability).
- **`references/workflow-states.md`** — new rubric mapping VI/Epic Jira status ladders ↔ pipeline command ↔ owning role ↔ expected artifacts.
- `/implement`: additive Jira-mode **Phase 0.5 readiness pre-flight** (advisory, non-blocking; direct mode byte-identical). `next-phase-offer.md`: `/ready` added as an optional Team/Dev gate.

### Notes

- Flagship borrow from the BMAD + SpecKit + Superpowers + grill-me analysis (AI-First line 85). New command + agent — counts 19 → **20** commands / 29 → **30** subagents. No-regression: `jira-reader`, `/vuln`, `/upgrade`, and the sibling plugins are untouched; `/implement` direct mode is byte-identical.

## [2.23.0] — 2026-07-12

### Added

- `/epics`: new optional **Phase 2.6 VI-level spec enrichment** — when a VI-level `specification.md` exists (detected via the VI dir `/epics` already resolves), its `[Uxx]`/`[ACxx]` requirements are folded into the coverage inventory as `spec-story`/`spec-criterion` rows, so the `_coverage.md` matrix reflects the richer spec-level requirements. Test cases (`[TCxx]`) are excluded (per-AC, non-unique, below Epic granularity). `epic-writer` notes `+ VI-level spec` on the `_source:` line; `epic-reviewer` checks the spec rows identically (uncovered → MAJOR).

### Notes

- Closes the last v2.21.0 follow-up (Cluster B / #4). Strictly additive: a run with no VI-level spec (the common case) is byte-identical to v2.22.0. No new command or agent — counts unchanged (19 / 29). `jira-reader`, `vi-reviewer`, `/vuln`, `/upgrade`, and the sibling plugins are untouched.

## [2.22.0] — 2026-07-12

### Added

- `/create-vi`: new **Phase 3.5 Dynatrace style check** — runs `dt-style-checker` on the authored VI before the `vi-reviewer` gate (emphasis: terminology + customer-facing captions/labels/messages/text), fixes applied inline, graceful skip when `dt-style-guide` is not installed. Advisory (non-gating); mirrors `/epics` Phase 6.1. VIs previously got no style check.
- `/create-vi`: **nudge toward richer requirements for complex VIs** — a Phase 1.5 non-blocking profile suggestion (SIGNIFICANT + `--lean`/`--hybrid` → consider `--full` for `FR-N`/`UC-N`) and Phase 3 active-pull of the `FR-N`/`UC-N` clusters, for finer downstream `/epics` coverage traceability. `vi-reviewer` unchanged (authoring-side only).

### Notes

- Closes two recorded follow-ups from v2.21.0. No new command or agent — counts unchanged (19 / 29). No-regression: a SIMPLE/MODERATE VI (or one run without `dt-style-guide`) behaves as before; `/vuln`, `/upgrade`, `agents/vi-reviewer.md`, and the sibling plugins are untouched. The two marginal v2.21.0 follow-ups (graded reviewer rubric; cross-iteration regression tracking) were dropped.

## [2.21.0] — 2026-07-12

### Added

- `/epics`: requirement→Epic **coverage matrix** with gap-detection — `jira-reader` now emits a `requirements[]` inventory (native VI `US/AC/SM/FR/UC` IDs, with a goal+themes `derived` fallback); `epic-writer` writes `_coverage.md` (VI-holistic, roll-up verdict + coverage %); `epic-reviewer` verifies it (uncovered requirement = MAJOR).
- `/epics`: `[NEEDS CLARIFICATION]` markers (cap 3/Epic; deps > AC > scope) + a Phase 6.2 batched resolution gate; unresolved-by-choice markers become reviewer BLOCKERs.
- `/epics`: Given/When/Then acceptance criteria + an `## Independent Test` line; source-anchored `[Source: path#Section]` citations; a pre-draft dedup pre-flight + a sizing/sequencing heuristic.
- `/epics`: new `epic-reviewer` dimensions — epic-independence (no-forward-dependency, MAJOR), internal terminology-drift (MINOR), anti-pattern + filler/"theater" detection under goal clarity.
- `/epics`: **ARD wiring** — new optional Phase 2.5 resolves the VI-level ARD (mirrors `/specify`); writer respects `AD-N` + records deviations; reviewer gains a conditional ARD-conformance dimension (BLOCKER without a deviation record). Additive, guarded on `status: found`. `/epics` added to `references/ard-resolution.md` consumers.
- `/epics`: Phase 6.1 `dt-style-checker` brief now emphasizes terminology + customer-facing captions/labels/messages/text.

### Notes

- No new command or agent — counts unchanged (19 commands / 29 agents). No-regression: a run with no ARD and no clarification markers behaves as before; `/vuln`, `/upgrade`, `/document`, and the sibling plugins are untouched.

## [2.20.0] — 2026-07-10

### Changed

- **The personal-store write-gate no longer requires an Obsidian `.obsidian/` directory.** The four vault write-gates — `/idea` Phase 0, and the `$VAULT_PATH`-fallback tiers of `references/feedback-emission.md`, `references/cost-emission.md`, and `references/followup-emission.md` — now accept `$VAULT_PATH` when it is **set + an existing directory + writable**, dropping the `.obsidian/`-directory proxy. Setting `$VAULT_PATH` is the user's explicit declaration of their personal store, and the rest of the plugin (`/release-notes`, `/epics`, `/document` staging) already trusted it on "set" alone — so this makes the four outlier gates consistent and lets non-Obsidian personal stores work. The "never write to the wrong place" guard is preserved: `$VAULT_PATH` must be set + exist + be writable, writes always land in a namespaced subdir (`$VAULT_PATH/dev-workflows/…`, `$VAULT_PATH/Projects/…`), and the NEVER-cwd rule is untouched. The `/followup` no-vault notice is softened `⚠ No writable Obsidian vault` → `⚠ No writable vault`. **No-regression:** existing `.obsidian/` vaults are still writable directories, so they behave identically; `/document`'s defensive `.obsidian/` git-forbid guard and the `.obsidian/copilot/` tag-index path are unchanged, and `/vuln`, `/upgrade`, and sibling plugins are untouched. No new command or subagent (version-only manifest bump).

## [2.19.0] — 2026-07-10

### Added

- **Every pipeline command now ends with an adaptive `### Next step` recommendation.** The end-of-run next-phase offer — previously only in `/idea`, `/create-vi`, `/create-ard` — is now a plugin-wide invariant backed by a new single-source-of-truth reference, `references/next-phase-offer.md` (the role-aware routing graph + a 5-rule contract: guidance-only / role-labeled / adaptive-to-outcome / mode-aware / Epic fan-out). The six pipeline commands that lacked it — `/specify`, `/design`, `/implement`, `/document`, `/epics`, `/release-notes` — now close their Final Report with a `### Next step` section naming the next command(s) tagged with the owning role (PM / PA / PE / Team), so a multi-hat user just keeps going. **Epic fan-out:** the per-Epic commands (`/create-ard <VI> <Epic>`, `/specify <VI> <Epic>`, `/design`, `/implement`) offer both depth (next command, same Epic) and breadth (same command, next Epic); `/document` + `/release-notes` are VI-level and run once after all Epics are implemented. The three reference commands are retrofitted to cite the SSOT; `/create-vi` also gains the PE → `/epics` handoff (and marks `/release-notes` recommended, `/create-ard` optional). **Strictly no-regression / additive:** the `### Next step` only *adds* a report section, and it is omitted in a command's direct / doc-edit mode (no VI/Epic pipeline context), so those runs are byte-identical. `/vuln` and `/upgrade` are not pipeline nodes and are untouched. No new command or subagent (version-only manifest bump — Nineteen commands / Twenty-nine subagents unchanged). Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched. **Follow-up:** revisit the `.obsidian/` vault-check.

## [2.18.0] — 2026-07-10

### Added

- **`/design`, `/implement`, and `/specify` now respect the ARD produced by `/create-ard`.** A new shared `references/ard-resolution.md` resolves the applicable ARD(s) for a `<VI>` (+ optional `<Epic>`/area) — most-specific first (per-area → Epic-level → inherited VI-level `AD-N`) — and returns a normalized context or **`none`**. Each consumer resolves early and passes the `AD-N` invariants to its reviewer as an optional `applicable_ard`; `design-reviewer`, `spec-reviewer`, and the shared `code-review` gain a **conditional** "ARD conformance" dimension that checks the artifact honors every `AD-N` `Rule`. Enforcement is **binding + deviation-record**: a violation with no recorded "ARD deviation" (flagged to the architect, in the consumer's own artifact — never the ARD) is a reviewer **BLOCKER**; a recorded deviation is allowed-but-flagged. **Strictly no-regression:** when no ARD resolves (the common case — `/create-ard` is optional) every command behaves byte-identically to before, and the reviewer dimension is skipped. Because `code-review` is shared, its dimension is gated on the caller passing `applicable_ard` — **`/vuln` and `/upgrade` never do and are not modified**. No new command or subagent (version-only manifest bump). Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched. **Follow-ups:** next-phase-offer-everywhere; revisit the `.obsidian/` vault-check.

## [2.17.0] — 2026-07-10

### Added

- **New `/create-ard` command — sub-project 3 (final) of the VI-creation flow (Product Architect phase).** `/create-ard <VI-KEY> [<Epic-KEY>]` grounds on the mounted implementation repos and authors an **ARD** (Architecture Requirements/Decision Document) that establishes the architecture invariants the downstream inherits. **Optional** (a simple VI may not need one — Phase 0 advises) and **scoped** via the two-key grammar: `<VI-KEY>` → VI-level (cross-cutting invariants + broad grounding); `<VI-KEY> <Epic-KEY>` → Epic-level (deeper; inherits the VI-level ARD's `AD-N` read-only). A big Epic spanning separable areas in one repo (e.g. `cluster2` `server/`+`ui/`) can split into `<EPIC>-<area>_ARD.md`. Grounding is **architect-driven, not PR-derived** (no PRs exist at ARD time): cheap `$REPOS_PATH` discovery + a `theme→repo` proposal + ask the architect + a consolidated mount-or-descope gate, then `code-scanner` on the confirmed set. Authored inline via the relentless grill against a new `references/ard-format.md` (Context · Grounding findings with real `file:line` · Architecture decisions `AD-N: Binds/Prevents/Rule` · Cross-repo map · Stack & invariants · Edge cases · Open questions · Deferred), gated by a new Opus **`ard-reviewer`** (grounding integrity, `AD-N` testability, no contradiction of inherited invariants, altitude purity), with a `/design`-style tiered hard model gate, written to `$SPECS_PATH/specifications/<KEY>-<slug>/`, branch+PR offer. Introduces the **`pa` (Product Architect)** role / `architecture` phase in the cost + feedback model. `references/feedback-emission.md` (ten → eleven commands) and `references/dependencies.md` (grilling list) reconciled. The sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched. **Follow-up (v2.18.0):** wire ARD *consumption* into `/design`, `/implement`, and `/specify` (both VI + Epic levels) — this effort ships the producer only.

## [2.16.0] — 2026-07-10

### Added

- **New `/create-vi` command — sub-project 2 of the VI-creation flow (PM phase).** `/create-vi <JIRA-KEY> [@idea.md] [--lean|--hybrid|--full]` turns a refined `idea.md` + a user-supplied Jira key (an empty workitem the user created for the ID; mandatory — graceful fail without it) into a product-level **Value Increment**. A new `references/vi-format.md` defines a mandatory **spine** (Problem · Goal · Target audience · User Stories `[US-N]` · Acceptance Criteria `[AC-N]` · Scope · Success Metrics `[SM-N]`) plus an **adapt-in menu** (union of Mike's + Alex's sections) selected by profile and pulled only when the idea warrants it. Authored inline via a relentless grill, gated by a new Opus **`vi-reviewer`**, written to `$SPECS_PATH/specifications/<KEY>-<slug>/<KEY>_ValueIncrement.md` (the relocated `idea.md` co-located; `sources` propagated from the idea's real provenance, not the literal `idea.md`), with a branch+PR offer and a documented paste-into-Jira + re-import round-trip. Product-level: **no code scan, no repos required** (`/specify` does the light code grounding + Test Cases downstream). Phase 6 offers **both** next steps — `/release-notes` (PM, now) and `/create-ard` (Product Architect handoff). Wired into the terminal tail: `impl-maintenance` + `emit-auto` + `emit-cost` (`vi-creation`/`pm`) + capture-at-block.

### Changed

- **Grilling technique consolidated into `references/grilling-technique.md` (SSOT).** `/idea`, `/specify`, and `/design` now cite it instead of each embedding the ~5-line technique (DRY; each keeps its own depth — bounded/`--deep` for `/idea`, relentless for the others — and stage list). Still no runtime dependency. `references/feedback-emission.md` (nine → ten commands) and `references/cost-emission.md` (VI-lifecycle enum + the promoted `/create-vi` attribution row) reconciled. Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched.

## [2.15.0] — 2026-07-10

### Added

- **New `/idea` command — the front door of the VI-creation flow (PM phase).** `/idea <prompt | @file | JIRA-KEY> [--deep]` ingests one of four sources — an inline prompt, a markdown file (wikilinks + images followed), a community post, or an exported RFE Jira ticket — via a new read-only `idea-reader` subagent (Sonnet tier; auto-detects the source type with provenance tags, follows wikilinks one level, enumerates linked images by path, captures community-post demand signals). The Opus orchestrator then refines it through the embedded grilling technique — bounded by default (≤5 Impact×Uncertainty questions, one at a time, recommended answers; leftover gaps become `[NEEDS CLARIFICATION]` capped at 3 + logged Assumptions) or relentless under `--deep` — and writes a lean one-page `idea.md` (new `references/idea-format.md` is the SSOT) to the vault under `$VAULT_PATH/Projects/<area>/<slug>/`, keyless, `status: refined` iff zero open clarifications remain. `$VAULT_PATH` is validated (falls back to a user-supplied directory, never cwd). The grill is the quality gate (no reviewer agent at the idea stage). On finish it makes an adaptive next-phase offer toward the future `/create-vi`. Wired into the standard terminal tail: `impl-maintenance` + `emit-auto` feedback, `emit-cost` (`phase: vi-creation`, `role: pm`, keyless → pending ladder), and the capture-at-block invariant. A new `references/dependencies.md` documents the recommended companions (`mattpocock-skills` `/grilling`, `superpowers`, `dt-style-guide`) and the external `jira-workitem-import` importer, all convention + runtime-resolve + graceful fallback (no manifest field). `references/feedback-emission.md` (eight → nine commands) and `references/cost-emission.md` (VI-lifecycle enumeration + the `/idea` attribution row) are reconciled. The sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.14.0] — 2026-07-10

### Added

- **Capture-at-block: a workflow that halts on a plugin gap now records it immediately, so an abandoned run doesn't lose its highest-value feedback.** A new `emit-block` entry point in `references/feedback-emission.md` (fourth alongside `emit-auto` / `emit-manual` / `emit-prompt`) writes one silent `origin: auto`, `impact: blocker` feedback entry when a run stops because the plugin lacked a capability / reference / skill / command-path the run needed — passing the gap directly (no `impl-maintenance` report exists mid-flight), deduped by the stable `id` so it never double-logs with a later terminal `emit-auto`. All eight pipeline commands (`/implement`, `/document`, `/epics`, `/release-notes`, `/specify`, `/design`, `/vuln`, `/upgrade`) carry the invariant: `emit-block` **before** escalating a plugin-gap halt. It fires **only** for plugin-facing gaps — never for a code/doc/Epic review BLOCK (a defect in the work), an environment/user halt (repo-missing, dirty-tree, jira-not-found, refresh-blocked), or a cancellation. This is not an interrupt or an enforced-collection gate — capture-at-block stays inside the deliberate silent, high-recall model (the halt is surfaced by the command's normal BLOCKED escalation, not a feedback prompt). The `impl-maintenance` agent and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.13.0] — 2026-07-10

### Added

- **`/document` (Jira mode) now discovers images from the project folder too.** Phase 5.6 gains a fourth candidate source — a recursive scan of the ticket's persistent Obsidian project folder (`<project_dir>`, resolved in Phase 1 under `$VAULT_PATH/Projects/<VI-dir>`) — alongside the existing specs-dir scan, the `jira-reader` Jira attachments (developer-attached screenshots under `jira-products/<VI-dir>/…`), and manual paths. So curated diagrams and screenshots kept in the project folder are offered automatically (deduped with the other sources; the "select a subset" flow still applies; contributes nothing when no project folder exists). The candidate summary now reports the per-source counts including "from the project folder." The add-a-new-image guidance is made explicit: place new images in the Projects VI-dir, **never** under `jira-products/` (which the Jira importer regenerates, discarding manual additions). Downstream placement, `image_policy`, and the CDN upload/defer handoff are unchanged; `jira-reader`, the doc agents, `/release-notes`, direct mode, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.12.0] — 2026-07-10

### Added

- **`/document` now applies the full dynatrace-docs frontmatter/metadata rules, not just changelog + owners.** A new reference `references/dynatrace-docs/frontmatter-guidelines.md` is the source of truth for the metadata fields: `title` (sentence case), `description` (**120–160 chars** SEO), `meta.content-type` (**mandatory** on new pages — the Diátaxis-plus-Dynatrace enum `how-to`/`tutorial`/`explanation`/`reference`/`get-started`/`troubleshooting`/`upgrade`/`best-practices`/`app`/`extension`; `overview` is deprecated; `release-notes` pages remain automation-generated), `meta.i18n-priority` (number), and `meta.generation` (`latest`/`classic`, with the Managed-build caveat). The `dynatrace-docs-frontmatter` skill sets/validates them, `doc-planner` plans them, `doc-writer` writes them, and `doc-reviewer` gates them — **missing/invalid `content-type` on a new page → BLOCKER; `description` outside 120–160 → warning; the rest advisory**. Applied only under the dynatrace-docs profile; a generic docs repo is unaffected. The `changelog:` and `owners:` conventions keep their own references (only cross-linked).
- **`/document` (Jira mode) now ingests a docs repo's own authoring rules.** `doc-planner` reads whichever guidance files a repo has — `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `CLAUDE.md` (+ `.claude/`), `STYLE.md`, `DOCUMENTATION-GUIDELINES.md` — and extracts the **authoring/structural** rules (required sections, voice/tone, page templates, structure/naming conventions), emitting a `repo_authoring_guidance` block that is surfaced in the Phase 5.7 plan (so you see "this repo's CONTRIBUTING.md requires …" before approving), passed to `doc-writer` (which follows it), and checked by `doc-reviewer` (a missing repo-mandated section → MAJOR). Generic (any repo); it **augments, never overrides** the built-in references and `dt-style-guide`, and does not duplicate the existing branch-naming read. Direct mode already ingests these files in its Phase 2A exploration and is unchanged. `/release-notes` and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.11.0] — 2026-07-10

### Changed

- **`/document` (Jira mode) now shows a single consolidated repo gate up front instead of a per-repo escalation loop.** As soon as the affected-repo set is known — Phase 4, right after `jira-reader` returns the PR links and before any diff work — `/document` presents one summary: the repositories the VI's Jira PRs span, which are mounted (✓) and which are missing (✗), and a note that missing repos are skipped so their code is not diff-summarised or checked against the VI's requirements (the discrepancy analysis is partial). It then offers **mount the missing repo(s) now and re-scan** (recommended — mount whichever are available under `$REPOS_PATH`, re-scan, repeat, which also gives per-repo control), **proceed without them** (Jira-only for the missing repos — byte-identical downstream state to the previous per-repo "skip"), **cancel**, or **specify an absolute path** for a missing repo. The all-mounted happy path is unchanged apart from a one-line "Resolved N/N repositories" note. The choice semantics still come from the `Repo unresolved (zero matches) — /document` rule in `references/escalation-rules.md`, now applied to the whole missing set at once. Jira mode only — `/document` direct mode (no repos), `/design`'s hard repo gate, and every subagent / reference / sibling plugin (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.10.2] — 2026-07-10

### Fixed

- **Session-cost price table now carries real Claude API rates for every model the routing policy can reach.** `references/cost-prices.yaml` had shipped with placeholder rates: Claude Opus 4.8 was priced at the old Opus 4.1 rates (`$15` / `$75` per MTok — roughly 3× too high), and `claude-sonnet-4-6` — a real, heavily-used Sonnet-chain fallback — had no key at all, so its usage was silently priced `null` (`unpriced-model`). Rates are now the standard first-party Claude API prices from Anthropic's pricing page: Opus 4.6–4.8 `$5` / `$25`, Sonnet 5 / 4.5 / 4.6 `$3` / `$15`, Haiku 4.5 `$1` / `$5`, with the cache 5m / 1h / read tiers at the standard 1.25× / 2× / 0.1× multipliers. Keys now cover the whole Opus chain (`4-8` / `4-7` / `4-6`), the whole Sonnet chain (`5` / `4-6` / `4-5`), and Haiku (`4-5`); prefix-matching prices dated transcript ids (e.g. `claude-haiku-4-5-20251001`) off their undated base key. **Permanent standard rates are used deliberately — never promotional / introductory rates** (Sonnet 5 is keyed at its standard `$3` / `$15`, not the `$2` / `$10` introductory price in effect through 2026-08-31) so cost figures stay comparable across Value Increments over time. `references/cost-emission.md` §4 is reconciled to describe the real permanent-rate table. Data / documentation only — no `session-cost.py` engine logic changed.

## [2.10.1] — 2026-07-10

### Changed

- **`impl-maintenance` agent — completed its illustrative `Command` enumeration.** The agent's two command lists (the `Command run` input description and the `Command workflow improvements` output section) now include `/design`, `/specify`, and `/release-notes` alongside the existing `/implement`, `/document` (both modes), `/epics`, `/vuln`, and `/upgrade` — matching the eight commands that actually invoke the agent (the three were added by the v2.9.0 feedback / maintenance phases). Documentation-only; no behavior change (the agent already defaults correctly when `Command run` is absent).

## [2.10.0] — 2026-07-09

### Added

- **Session cost reporting — the plugin now records how many dollars a Value Increment cost across its lifecycle, by phase / role / model, persisted per-VI into the specs repo for the maintainer to aggregate.** Claude Code stores no dollar figure in the transcript, so cost is **computed**: a new stdlib-only engine `scripts/session-cost.py` reads the session's main transcript from a chained-checkpoint line offset forward plus the session's `subagents/agent-*.jsonl` within a `(last_ts, now]` window, sums `usage` by model, and applies the new `references/cost-prices.yaml` price table (USD per million tokens; the cache 5m/1h split priced exactly; unknown model → tokens recorded, cost `null`; overridable via `$DEV_WORKFLOWS_COST_PRICES`). A new shared reference `references/cost-emission.md` is the single source of truth: session-artifact resolution, the chained-checkpoint model (advance ALWAYS — even report-only), the machine-friendly per-invocation entry format written to `<VI-dir>/dev-workflows/cost/<sid8>.md` (one file per session → merge-safe under massive team fan-out), the specs-first persistence ladder (never the cwd), pending + opportunistic move-then-delete reconciliation for keyless runs, the optional statusline cross-check, attribution (incl. the `/release-notes` PM-vs-dev inference keyed on `specification.md` / `design.md` presence, never Epics), privacy (no user name in any cost file), and the single `emit-cost` caller contract.
- **Terminal cost phase across the six VI-lifecycle commands.** `/specify` (specification/pe), `/epics` (epic-refinement/pe), `/design` (planning/dev), `/implement` (implementation/dev), `/document` (documenting/dev — Mode A + Mode B), and `/release-notes` (phase/role inferred) gain a terminal Session cost phase — the new final operational phase, after the feedback phase — that cites `cost-emission.md` and calls `emit-cost`. Cost **always runs** and always advances the chained checkpoint (even report-only), so per-command costs sum to the session total. `/vuln` and `/upgrade` are deliberately out of scope (no VI to attribute to).
- **New command `/statusline`.** Installs the plugin's multi-line status line into `~/.claude/settings.json` (idempotent; backs up any existing script + `statusLine` block; confirms before writing). Its vendored script also writes a per-render `{ts, cost_usd}` snapshot from `.cost.total_cost_usd` to `~/.claude/dev-workflows/cost-snapshots/<session_id>.json`, enabling the Option B authoritative cross-check in session cost reporting.

Additive only — the `impl-maintenance` agent, `jira-reader`, the reviewers, the format references, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; no cost phase ever fails the run, commits, or writes into the current working directory, and no user name is written to any cost file.

## [2.9.0] — 2026-07-09

### Added

- **Session feedback collection — the plugin now captures friction and improvement signals about itself and persists them per-VI into the specs repo for the maintainer to aggregate.** A new shared reference `references/feedback-emission.md` is the single source of truth: the machine-friendly entry format (file frontmatter `type` / `vi` / `slug` + per-entry YAML `id` / `date` / `command` / `plugin_version` / `origin` / `author` / `category` / `impact` + prose), the **specs-first** persistence ladder (`$SPECS_PATH` VI dir `<VI-dir>/dev-workflows/<KEY>-feedback.md` → `$SPECS_PATH/dev-workflows-feedback/` → a writable vault with a loud "won't auto-aggregate" notice → beside an imported Jira directory → report-only; **never the cwd**), append-only dedup with `git`-derived attribution, the plugin-facing predicate (persist plugin signal only — never target-project `CLAUDE.md` / hook advice), and a three-entry-point caller contract (`emit-auto`, `emit-manual`, `emit-prompt`).
- **Automatic capture across all eight workflow commands.** `/implement`, `/document` (Mode A + Mode B), `/epics`, `/vuln`, and `/upgrade` now persist the plugin-facing slice of their existing `impl-maintenance` report (Command workflow improvements + New agents/skills + Reference-doc gaps + the triggering Key observations) as `origin: auto` feedback, silently, after maintenance runs. `/release-notes`, `/specify`, and `/design` gain a new lightweight terminal maintenance phase that invokes `impl-maintenance` on the Sonnet detection chain and then persists. A routine session with no plugin-facing signal writes nothing (byte-identical to before).
- **New commands `/feedback`, `/prompt`, `/prompt-brainstorm`, and `/prompt-grill-me`.** `/feedback <text>` logs a universal manual note (`origin: manual`). The `/prompt*` family captures a corrective interaction — Friction, your verbatim prompt, and the Resolution (`origin: prompt`): `/prompt` acts on the correction directly, `/prompt-brainstorm` hands off to `superpowers:brainstorming`, and `/prompt-grill-me` runtime-resolves `/grilling` (mattpocock-skills) and falls back to `superpowers:brainstorming` if it is not installed. No hard cross-plugin dependency.

Additive only — the `impl-maintenance` agent core, `jira-reader`, the reviewers, `format-refs`, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; feedback also always remains in the run's final output (zero loss) and no capture phase ever fails the run.

## [2.8.0] — 2026-07-09

### Added

- **Follow-up task & journal emission — `/document`, `/release-notes`, `/epics`, and `/implement` now persist out-of-scope / manual-step follow-ups at end-of-run.** Each command gains a terminal "Emit follow-up tasks" phase (after its Final Report) that filters the run's follow-up signals to those whose action lands *outside* the current change or needs a *manual human step* (files owned by other teams, Jira-vs-source implementation gaps, "paste release notes into Jira", "create these Epics in Jira manually", screenshots to upload), then persists them as durable Obsidian-Tasks `- [ ]` lines — with a `Journal.md` (or project `### Notes`) entry when an item needs more than a task line. A batch preview grouped by target file (`approve-all | select | cancel`) gates every write; nothing is written without one confirmation. In-scope items the report already tracks (deferred review BLOCKERs, skipped tests, in-draft TODOs) are deliberately excluded.
- **New shared reference `references/followup-emission.md`.** The single source of truth for the emitter: task-line format, Jira-key → project-file resolution (`P<NNNN> <slug>.md` → `## Work Items → ### Tasks`, else `Tasks.md # Irregular`), notes placement (project `### Notes` → `Journal.md`), stable-key dedupe, and the no-vault fallback ladder (`$VAULT_PATH` → the VI's `$SPECS_PATH` dir `<VI-dir>/dev-workflows/<KEY>-followups.md` → beside the imported Jira directory → report-only; never the cwd). **Self-contained** — no runtime dependency on the `obsidian-llm-wiki` plugin; it mirrors that plugin's `_shared/task-rules.md` + `vault-conventions.md` as upstream and adds journaling (which exists in neither plugin).

Additive only — existing phase behaviour, `jira-reader`, the reviewers, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; the follow-ups also remain in each command's Final Report (zero regression) and the phase never fails the run.

## [2.7.0] — 2026-07-09

### Changed

- **`/implement`, `/document`, `/epics`, and `/release-notes` now honor the shared front-end's `focus_key`.** Since the v2.5.0 foundation these four commands parsed the two-key `<VI> <Epic>` grammar but ignored the focus Epic (they resolved the VI and read the whole subtree). They now consume `focus_key`:
  - **`/implement`** is treated as an Epic-unit command: for a bare multi-Epic VI it renders the progress-aware Epic picker (done-predicate = the Epic's Jira status — done / in-progress / not-started, degrading to a plain list if the export carries no status), scopes the Jira read to the chosen Epic's subtree, and resolves specs from the nested per-Epic home. Each run targets **one** Epic — there is **no "Next Epic?" loop** (unlike `/specify`+`/design`), because code-writing is heavy and branchy.
  - **`/document`** (Jira mode) and **`/release-notes`** stay VI-level and gain no picker; when an explicit focus Epic is passed they scope their change-driven phases (diff summarisation, doc planning / release-note rendering) to that Epic's subtree, defaulting to whole-VI otherwise.
  - **`/epics`** stays VI-level (its partition analysis reads the whole VI); an explicit focus Epic is honored as a **refinement target** — Phase 6 re-drafts only that Epic's definition and Phase 7 reviews only that file (`epic-writer` unchanged).
- **Shared `references/jira-input-resolution.md` §Specs-resolution is now `focus_key`-aware.** With a focus Epic it prefers the nested per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/{specification.md,design.md}` (matched by Jira key-number, tolerating slug drift), falling back to the VI-flat layout when no nested Epic folder exists; with no focus Epic the VI-flat resolution is unchanged. This is the nested per-Epic path discovery `/implement` needed.

Single-key and directory inputs, and un-split-VI (0-Epic) behaviour, are unchanged; `jira-reader`, `/specify`, `/design`, the reviewers, and the format references are untouched.

## [2.6.0] — 2026-07-08

### Added

- **`/design` — Jira-driven engineering design authoring (Dev phase).** The developer take-over half of the PM→Dev pipeline: reads a merged `specification.md` from the specs repo's main branch, grounds strictly in the fully-mounted implementation code (a **hard** repo gate — any unmounted repo in the confirmed set stops the run until remounted, unlike `/specify`'s soft gate), and authors an engineering `design.md` through a relentless one-question-at-a-time grill that both **challenges** the spec (recording an `## Engineering review` section + `- [ ]` open questions back onto `specification.md`) and **designs** the implementation. A single complexity classification scales grill depth, `design.md` section-inclusion, and reviewer rigor together; a **tiered model gate** hard-stops SIGNIFICANT/HIGH-RISK work that is not running on Opus (the critical synthesis is inline, not a subagent). Consumes the shared front-end's `focus_key`; for a multi-Epic VI it renders the progress-aware Epic picker (○/◐/●, done-predicate `design.md` exists) enumerated from the specs repo, and offers a Next-Epic loop. Writes `design.md` **flat** in the per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` (durable/resumable via `_design-session.md` + `_design-glossary.md`, namespaced to coexist with `/specify`'s session files), gates on the new Opus `design-reviewer`, and offers a branch+PR handoff (`design/<EPIC>-<eslug>` / `design/<VI>-<vslug>`) to the specs repo's main for `/implement`. `design.md` open questions **hard-block** handoff (opposite of `specification.md`, where they are tolerated). New assets: `commands/design.md`, `references/design-format.md` (net-new format authority), `agents/design-reviewer.md` (Opus). `/design` uses the shared Jira-input front-end only to parse the grammar — it does not read Jira content (`jira-reader` is not used).
- **`/implement` refuses to implement a design doc with unresolved open questions.** A cross-command backstop for `/design`'s decision-completeness policy: when the primary description is a design doc (`design.md` / `*-design.md`) with unresolved `- [ ]` items, `/implement` stops (override-only, logged in the Phase 5 report). `specification.md`-level open questions remain exempt.

## [2.5.0] — 2026-07-08

### Added

- **VI-selector two-key grammar for the shared Jira-input front-end** (`references/jira-input-resolution.md`). `/implement`, `/document`, `/epics`, `/specify`, and `/release-notes` share a uniform way to point at one Epic inside a multi-Epic VI: `<VI> <Epic>` (both under `$VAULT_PATH/jira-products/`) or `<dir> <Epic>` (a jira-export directory plus an Epic key, no `$VAULT_PATH` needed). A single nested-Epic key alone now auto-resolves to its parent VI (Fallback E if the parent is ambiguous; Fallback D if the Epic isn't found). The resolver exposes a new nullable `focus_key` output field (the resolved Epic, or `null` for a bare VI / stand-alone item) and documents a reusable progress-aware Epic-picker pattern (○ not-started / ◐ in-progress / ● done) for commands that need to let the user choose among a VI's Epics. All five commands now accept the grammar and resolve `focus_key`, but only `/specify` acts on it this release (below) — `/implement`, `/document`, `/epics`, and `/release-notes` resolve the VI and ignore `focus_key` for now.
- **`/specify` resolves nested/bare Epic keys and writes per-Epic output paths.** Phase 0 now accepts a nested or stand-alone Epic key directly (previously only a VI key or directory worked) and, once an Epic is in focus, writes to the hyphen-delimited per-Epic path `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` — replacing the old flat `specifications/<KEY>_<slug>/` target, whose underscore delimiter mismatched the repo's hyphen convention and which had no per-Epic home (it collided with / duplicated the VI's own dir). The PR-handoff branch name follows suit: `spec/<EPIC>-<eslug>` (per-Epic) / `spec/<VI>-<vslug>` (broad VI-level) — replacing the old `spec/<KEY>_<slug>`.
- **`/specify` progress-aware Epic picker.** For a VI with two or more Epics and no Epic already selected, Phase 2 Step A now renders the shared picker (○/◐/●) before the full-depth read, so the interview scopes to one Epic's linked Stories/Sub-tasks instead of the whole VI. A single-Epic VI or a stand-alone top-level Epic skips the picker and auto-focuses; a broad VI-level spec remains available as an explicit choice. After finishing a per-Epic spec, `/specify` offers to loop back into the picker (Epic dropped from the actionable set) to author a sibling Epic's spec next.

## [2.4.0] — 2026-07-07

### Added

- **`/specify` — Jira- and code-grounded specification authoring (PM phase).** A grilling command that reads a Jira Epic/VI from exported markdown, lightly grounds in code (auto-derived repos, soft advisory gate), and authors an org-standard `specification.md` (problem → scope → user stories → acceptance criteria → test cases) through a relentless one-question-at-a-time interview — resolving open questions live and leaving genuinely unresolvable ones as `- [ ]`. Durable/resumable via `_session.md` + `_glossary.md`; a VI-without-Epics pre-flight; gates on the new Opus `spec-reviewer`; renders HTML; and offers a branch+PR handoff to the specs repo's main branch (`Published: no`) for the future `/design` dev take-over. New assets: `commands/specify.md`, `references/specification-format.md`, `agents/spec-reviewer.md`, `scripts/specification-to-html.py` (format/reviewer/renderer imported from mgd-specifications; grilling technique embedded — no runtime plugin dependency).

## [2.3.1] — 2026-07-02

### Fixed

- **Docs reflect the uniform routing doctrine.** The 10 mechanical agent descriptions and the plugin README's subagent table + summary no longer say those agents "inherit the session's model" (stale after v2.3.0). They now state each agent has no fixed model pin and its tier is assigned by the caller per the model-routing policy (mechanical → Sonnet, synthesis/review → Opus). The four Opus-pinned reviewers/planners remain marked explicitly.

## [2.3.0] — 2026-07-02

### Added

- **Per-step model routing for `/implement`, `/vuln`, `/upgrade`.** These commands now build the full §4 `model_routing` block at classification time and pin each subagent dispatch to a tier: mechanical steps (readers, scanners, `test-writer`/`test-baseliner`, `review-fixer`, and the `/vuln`/`/upgrade` coordinators) run on the §2.1 Sonnet chain, while judgment gates (`risk-planner`, `code-review`) keep their frontmatter Opus pins. `/vuln` and `/upgrade` pin at the orchestrator level; their coordinators' internal leaves inherit the pinned tier.

### Changed

- **Sonnet 5 is the Sonnet-tier primary.** The §2.1 detection chain and the §2 Opus-chain Sonnet fallback now lead with `claude-sonnet-5` (then `claude-sonnet-4-6` → `claude-sonnet-4-5`). Opus primaries (`claude-opus-4-8` …) and all review/planning-gate Opus pins are unchanged.

## [2.2.1] — 2026-07-02

### Fixed

- **`/epics` wording now reflects cwd-agnostic output.** Corrected prose that still asserted the Obsidian vault as the only output home (intro line, doc-maintenance dispatch, git-state report template) and normalized the "vault git is the user's responsibility" idiom to "git … responsibility" — accurate when Epics are drafted to `epic-drafts/<jira_key>/` beside an imported hierarchy without `$VAULT_PATH`.
- **`/release-notes` placeholder normalized.** Replaced the uppercase `<JIRA_KEY>` display token with the canonical `jira_key` (prose) / `<jira_key>` (report template), and dropped the now-redundant binding note.
- **Marketplace README command list refreshed.** Replaced the pre-B1 `/impl:*` names with the current surface: `/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/api-guideline-reviewer`, `/guideline-reviewer`.

## [2.2.0] — 2026-07-02

### Added

- **`/epics` and `/release-notes` adopt the shared Jira-input front-end.** Both commands now accept the same grammar as `/implement` and `/document`: a **JiraID** (discovered under `$VAULT_PATH/jira-products/`) **or** an **imported-Jira directory** (the same exporter output rooted anywhere — works when `$VAULT_PATH` is unset). Input is resolved via `references/jira-input-resolution.md`, and `jira-reader` is invoked with `jira_export_root`.

### Changed

- **`/epics` is now cwd-agnostic** — it no longer requires the working directory to be inside `$VAULT_PATH`. Epic drafts are written to an absolute output directory: `$VAULT_PATH/jira-drafts/<VI-KEY>/`, or `<import-parent>/epic-drafts/<VI-KEY>/` when `$VAULT_PATH` is unset.
- **`/release-notes` always writes a file** — the draft (and any implementation-gaps report) goes to the vault project folder when `$VAULT_PATH` is set, or beside the imported directory when it is unset. Print-to-screen is a secondary option, never the default.

## [2.1.0] — 2026-06-29

### Added

- **Shared Jira-input resolution front-end** (`references/jira-input-resolution.md`). `/implement` and `/document` now share one input grammar: a **JiraID** (discovered under `$VAULT_PATH/jira-products/`), an **imported-Jira directory** (the same exporter output rooted anywhere — works when `$VAULT_PATH` is unset), or a **direct prompt/`@file`**. `/implement` gains JiraID discovery; `/document` gains directory input.
- **`SPECS_PATH`** env var (same rules as `VAULT_PATH`) — the deterministic source for a ticket's specifications at `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`. Specs are **required (with override)** for `/implement` jira-driven runs and **additive** for `/document`.
- `jira-reader` accepts an additive `jira_export_root` input (an explicit ticket export directory); `/epics` and `/release-notes` keep using `vault_path` + `jira_key` unchanged.

### Changed

- The `jira-workitem-import` tool (https://github.com/ivan-gudak/jira-workitem-import) is now referenced as the source of the `jira-products/` export.

## [2.0.1] — 2026-06-28

### Changed

- **Internal phase renumber — documentation only, no behavior change.** Renumbered the `/document` (Jira mode) Phase 6 cluster to monotonic execution order — CDN image handoff `6.2`→`6.1`, branch setup `6.5`→`6.2` (its section now physically precedes the writer), write `6`→`6.3`, style check `6.7`→`6.4`, render verification `6.8`→`6.5` — and removed the execution-order note the old non-monotonic numbering required. Renumbered the `/epics` Dynatrace style-check phase `6.7`→`6.1` (the `/epics` Write phase stays `6`). Every step, gate, and agent dispatch is unchanged.

## [2.0.0] — 2026-06-28

### Changed (BREAKING)
- Renamed all `/impl:*` commands to top-level verbs: `/impl:code` → `/implement`; `/impl:jira:docs` → `/document`; `/impl:jira:epics` → `/epics`; `/impl:jira:release-notes` → `/release-notes`; `/impl:docs:profile` → `/docs-profile`.
- `/impl:docs` (one-shot doc editor) is **folded into `/document`** as direct mode — `/document <JiraID> [saas|managed]` runs the Jira pipeline; `/document @file` or `/document <free-text>` runs the one-shot edit. The standalone `/impl:docs` command is removed.
- The `/impl` dispatcher command is removed (no namespace left to dispatch).
- The context hook now matches the new verbs and routes `/document` by argument (JiraID → vault/repos context; free-text → silent).

### Added
- `references/escalation-rules.md` — the shared escalation `choices:` rules, resolving the previously-dangling "§15" references.

## [1.16.0] — 2026-06-28

### Changed
- `/impl:jira:docs` and `/impl:jira:epics`: the Phase 6 writers are extracted into dedicated write-only subagents (`doc-writer`, `epic-writer`) fed by a structured temp handoff file. `doc-writer` is pinned to the Opus reasoning chain (closes the docs writer gap on non-Opus sessions); `epic-writer` is pinned to the Sonnet detection chain for MODERATE runs (stops MODERATE Epic writing from running on an Opus session). Orchestrators commit (docs) or never commit (epics) as before; output is unchanged.
- `/impl:jira:docs` Phase 1.5 advisory narrowed to a context-window note (the synthesis and writing now run on Opus regardless of session).

### Added
- `/impl:jira:epics`: per-step model routing — `jira-reader`, `code-scanner`, `dt-style-checker`, `doc-fixer` pinned to the Sonnet detection chain; `epic-reviewer` keeps its Opus pin; a `model_routing` block + Phase 9 `### Model Routing` section.
- `classification.md` §9: delegated-writer routing rows, the advisory classification gate, and the code-scanner-no-synthesis refinement.

## [1.15.0] — 2026-06-28

### Added
- `/impl:jira:docs`: per-step model delegation. A `model_routing` block resolved at Phase 1.5 pins `doc-planner` (Phase 5.7) to the §2 Opus chain and the mechanical steps (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, Phase 8 maintenance) to the §2.1 Sonnet chain. `doc-reviewer` keeps its frontmatter Opus pin.
- A Phase 1.5 advisory recommends relaunching the whole run on Opus (orchestration + the 5.8/5.9 gates + the inline writer + a 1M context window) when the session is not on the Opus chain; a no-Opus-available path records the degradation.
- `references/model-routing/classification.md` §9 — the reusable per-step routing policy for multi-phase authoring pipelines (role→chain map, no-Opus rule, §8.3 reconciliation).

## [1.14.2] — 2026-06-28

### Fixed
- **`/impl:jira:docs` pipeline hardening (post-review).** A comprehensive 3a–3d pipeline review + this spec review found five cross-phase seams, now fixed: (I#1) a Phase 6 ordering note clarifying that Phase 6.5 branch-setup runs before the writer (full renumber deferred); (I#2) the downstream agent briefs and the write invariant now consume the resolved `docs_repo_path` rather than "cwd's git root", so a docs repo discovered outside cwd (or user-entered) is scanned/written correctly; (I#4) `/impl:docs:profile` now bases its branch on the repo's default branch (clean profile PR); (I#5) when `/impl:jira:docs` invokes profiling inline it passes `--inline`, and `/impl:docs:profile` then skips its branch-naming prompt and standalone PR-draft — one branch, one decision, one handoff; (I#6) a Phase 0 guard warns when an in-repo profile is not yet on the base branch (so the docs branch won't include it). No command behavior changed beyond I#4. (`§15` escalation cleanup + the monotonic phase renumber remain deferred to the namespace refactor.)

## [1.14.1] — 2026-06-28

### Fixed
- **README & `/impl` dispatcher accuracy (docs-only).** Corrected the stale slash-command counts (intro now reads eight workflow commands plus the `/impl` dispatcher; the classification sentence now names the five `/impl:*` commands that run per-task SIMPLE/MODERATE/SIGNIFICANT/HIGH-RISK classification and notes that `/impl:docs:profile` runs at a fixed SIGNIFICANT). Refreshed the `/impl:jira:docs` description to cover multi-space write safety, render verification (Phase 6.8), and finish & handoff (Phase 8.5 — squash, opt-in push, copy-paste PR draft). Added the missing `/impl:docs:profile` and `/impl:jira:release-notes` rows to the `/impl` dispatcher and a "which docs command?" note. Clarified that the `obsidian`/`plain_dir` write contexts are defensive guards (Phase 0 normally resolves a real docs repo). No command behavior changed.

## [1.14.0] — 2026-06-27

### Added
- **`references/finish-and-handoff.md`.** Single source of truth for `/impl:jira:docs` finish & handoff: the branch entering Phase 8.5, the contextual squash (profile-config commit vs merge-base), the opt-in push, host detection, and the copy-paste PR-draft template.
- **`commit_convention` profile field (default `"<JIRA-KEY> <summary>"`).** The squash commit-message format Phase 8.5 uses; inferred from `git log` / `CONTRIBUTING` when absent.

### Changed
- **`/impl:jira:docs` finish & handoff (Increment 3c).** Phase 6.5 now adopts the inline-profiling branch (renames it to the docs-branch convention and records the profile-config commit) instead of leaving the run on it. A new **Phase 8.5** squashes the run into clean history (keeping the profile-config commit separate when profiling ran), offers an opt-in `git push`, and writes a copy-paste PR draft to the vault project folder — host-aware (Bitbucket web UI / a `gh pr create` command the user may run), with a DO-NOT-MERGE banner when document-as-spec/skip-and-report gaps exist. Phase 9's git-state line reports the squash/push/draft outcome. The zero-external-API invariant is preserved — the plugin never creates a PR via an API.

## [1.13.0] — 2026-06-27

### Added
- **`references/dynatrace-docs/render-verification.md`.** Single source of truth for `/impl:jira:docs` render verification: build-vs-boot proof, sequential dev-server boot + readiness poll + stop, route derivation, delta-marker extraction + the cross-space invariant check, prerequisites best-effort/no-auto-apply, and graceful fallback to the pages-to-visit table.
- **`dev_servers.readiness_timeout_seconds` profile field (default 120).** Overridable per-repo; how long Phase 6.8 polls a booted dev server for readiness before falling back to the manual table.

### Changed
- **`/impl:jira:docs` Phase 6.8 — render verification (Increment 3b).** New phase after the style check: runs the profile's build command (gating, with the content→`doc-fixer` / environmental→ask split); offers an opt-in best-effort sequential dev-server smoke-check that asserts HTTP 200 per affected page and verifies the 3a invariant on cross-space pages (delta marker present in the target space's render, absent in the protected space's); always emits a "pages to visit" table. Results thread into the Phase 7 `doc-reviewer` invocation and a new Phase 9 `### Render verification` section. The `.docstack` shim is checked but never auto-applied.

## [1.12.0] — 2026-06-27

### Added
- **`references/dynatrace-docs/multi-space-writing.md`.** Single source of truth for writing dynatrace-docs across the SaaS and Managed spaces: shared-vs-single pages, the render-unchanged-≠-file-untouched invariant, the conditional-vs-override-copy strategies + heuristic, the shared-registries lock-step, and token correctness. Cited by `doc-planner` and `/impl:jira:docs`.

### Changed
- **`/impl:jira:docs` multi-space write safety (Increment 3a).** `doc-planner` now receives the resolved `profile` + `target_spaces`, classifies each target's `space_scope`/`rendered_in`, and recommends a per-target `write_strategy` (`conditional` | `override-copy` | `plain`). A new **Phase 5.9** presents those recommendations for approval/override. **Phase 6** consumes `profile` + `target_spaces` + the approved strategies to route each write to the correct space's `content_root`, edit shared pages in place with `{{#if project='…'}}` conditionals for small diffs, override-copy + `managed/docstack.jsonc` `ignore` for structural ones, keep `schema-ids.yml`/`schema-mappings.yml` in lock-step, and validate token correctness — so a `saas`/`managed`-constrained run never changes the other space's rendered output.

## [1.11.0] — 2026-06-26

### Added
- **`jira-reader` image attachment enumeration.** `jira-reader` now enumerates image attachments found in the Jira hierarchy and surfaces them as an `attachments[]` array in its output, making images available to downstream phases without manual discovery.

### Changed
- **`/impl:jira:docs` spec-tree as authoritative intended source (`doc-planner`).** Phase 5.7 now feeds the VI spec tree to `doc-planner` as the authoritative intended source, enabling 3-way `Jira|Spec|Code` discrepancy detection in Phase 5.8. `doc-planner` records `spec_phrasing` alongside `jira_phrasing` and `source_phrasing`; the new `spec-markdown` technique lets writers ground prose in the spec tree before cross-checking against Jira and source. `source-truth.md` updated to describe the spec-authoritative 3-way protocol.
- **`/impl:jira:docs` auto-discovers candidate images (Phase 5.6).** Before the writer phase, Phase 5.6 now automatically scans spec files for embedded images, enumerates Jira attachment images from `jira-reader`'s `attachments[]`, and falls back to a manual discovery prompt — producing a ranked candidate list the writer uses for screenshot placement.
- **`/impl:jira:docs` interactive CDN handoff with async fallback.** When `image_policy` is `cdn_upload_required`, the command now offers an interactive handoff step: the user can paste CDN links immediately and the command substitutes real URLs into the draft. When the user defers, the existing async fallback (stage screenshots to the persistent Obsidian project folder, surface in the Phase 9 report) is used unchanged.

## [1.10.0] — 2026-06-26

### Added
- **Built-in dynatrace-docs default profile (`references/dynatrace-docs/docs-profile.default.yml`).** Provides zero-config profile resolution for dynatrace-docs clones: when no in-repo `.dev-workflows/docs-profile.yml` exists and `is_dynatrace_docs` is true, Phase 0 loads this built-in instead of invoking on-demand profiling.

### Changed
- **`/impl:jira:docs` Phase 0 — preflight discovery.** Phase 0 now resolves the docs repo (cwd-preferred → search `/workspace` for a dynatrace-docs clone → ask), the profile (in-repo → built-in dynatrace-docs default → inline `/impl:docs:profile` on-demand), and the VI's specs dir under `${REPOS_PATH:-/workspace}` before Phase 1 clarification. A readiness table summarises all resolved items.
- **`/impl:jira:docs` Phase 4.5 — applicability determination.** New phase determines and confirms the applicable space(s) (`saas`, `managed`, or both) from the Jira hierarchy and resolved repos when no space constraint is passed; skips determination when `saas|managed` is supplied as the optional second argument.
- **`/impl:jira:docs` optional `saas|managed` space constraint.** The command now accepts `PRODUCT-NNNN [saas|managed]` as its signature. Passing `saas` or `managed` scopes the run to that space and leaves the other space's output unchanged; omitting it triggers Phase 4.5 auto-determination.

## [1.9.0] — 2026-06-25

### Added
- **`/impl:docs:profile` command.** Scans a docs repo and writes/refreshes `.dev-workflows/docs-profile.yml` + CLAUDE.md guidance as a reviewable PR; consumed by `/impl:jira:docs`.
- **model-routing SSOT §2.1 — mid-tier Sonnet chain.** Mid-tier Sonnet detection chain (`claude-sonnet-4-6` → `claude-sonnet-4-5`), pinned via `model:` so detection never inherits an Opus session.
- **`references/dynatrace-docs/docs-profile-schema.md`.** The docs-profile schema.

## [1.8.0] — 2026-06-25

### Added
- **`dynatrace-docs-frontmatter` skill.** Applies the dynatrace-docs frontmatter conventions when editing documentation pages under `dynatrace/_content/**` or `managed/_content/**`: prepends a `changelog:` entry dated today on changed existing pages (newest-first, ≤200 chars, with the period rule — complete sentence ends with a period, phrase does not), and unions the required managed-docs owners into `managed/_content/**` pages without removing existing owners. Cites two new reference files as source of truth.
- **`changelog-owners-reminder` hook (`PostToolUse`: `Edit|Write|MultiEdit`).** Warn-only `systemMessage` reminder when a dynatrace-docs content page is edited without a `changelog:` entry dated today, or (managed pages) without the required owners. Skips the changelog check for brand-new/untracked pages (first-publish rule). A `.sh` wrapper delegates to `.py` logic that reads the payload from stdin; always exits 0, never blocks.
- **`references/dynatrace-docs/changelog-guidelines.md`** — single source of truth for dynatrace-docs changelog writing rules (format, business-critical rationale, the period rule, worked examples) plus the managed-docs owners policy.
- **`references/dynatrace-docs/managed-owners.txt`** — managed-docs owner IDs unioned into `managed/_content/**` pages (read by the skill and the hook). Ships with `ivan.gudak` only; extend by adding one ID per line.

### Changed
- **Docs.** README gains a `## Skills` section and a Hooks-table row for `changelog-owners-reminder`; the dev-workflows hook count is now four (root `CLAUDE.md`, `plugin.json`, `marketplace.json`).

## [1.7.2] — 2026-06-17

### Added
- **`/impl:code` multi-source fan-out (Phase 1.7).** When the input includes more than one repo or any directory (spec file folder, Jira ticket folder), the task is floored at SIGNIFICANT (overridable at plan approval) and a Phase 1.7 fan-out scan runs before planning: `jira-reader` (for Jira folders) + per-repo `code-scanner` (single response, cap 4 concurrent) → synthesised summary fed to the planner. A referenced directory that is missing or unrecognised is surfaced, never silently skipped.
- **`references/model-routing/classification.md` §8 — large-input scan fan-out policy.** New section defines the input-shape trigger (multi-repo or any directory), the `jira-reader → parallel code-scanner (cap 4) → Opus synthesis` pattern, and the SIGNIFICANT floor it imposes. Single source of truth for all commands that dispatch fan-out scans.

### Changed
- **`code-scanner` agent generalised.** Now serves both `/impl:jira:epics` (theme-gap scan) and `/impl:code` (multi-source fan-out scan) callers; the agent description and handoff reference updated accordingly.

### Fixed
- **`/impl:code` reclassification fallback.** When the `risk-planner` returns a reclassification notice (task is actually SIMPLE/MODERATE), the command now correctly falls back to the standard-plan path instead of staying on the Opus path.
- **Planner `reason` field and diagram label.** Minor wording corrections in the Phase 2B plan presentation.

## [1.7.1] — 2026-06-16

### Fixed
- **`docs-style-checker` now chains Vale + `dt-style-checker` as complementary passes, not fallback-only.** Previously (1.7.0) `dt-style-checker` ran only when the primary linter failed — so whenever Vale ran successfully, the entire semantic / cross-page class of findings was silently dropped (engineer jargon like `latest-minus-one`, cross-page UI-label consistency, subject-verb agreement, plural/singular label mismatch). Vale and `dt-style-checker` are complementary, not redundant. Now, when the primary linter succeeds, `dt-style-checker` ALSO runs as a complementary pass and both finding sets are merged with line-level dedupe; fallback behaviour is preserved when the primary fails; the chain degrades to primary-only when `dt-style-guide` is not installed. Output **schema v3**: `linter`/`command` → `primary_linter`/`primary_command`, new `complementary_linter`/`complementary_command`/`complementary_error`, and each violation carries a `source: primary|complementary` tag. `/impl:jira:docs` Phase 6.7 and `/impl:docs` Phase 3.5 updated to describe the internal chain (the command no longer dispatches `dt-style-checker` separately). Ports Copilot dev-workflows v1.8.2.
- **`/impl:docs` phase-numbering contradiction fixed** — the "There is no Phase 3.5" disclaimer was stale after 1.7.0 added a mandatory Phase 3.5 style check.

## [1.7.0] — 2026-06-16

### Added
- **Source-truth discrepancy escalation (`references/source-truth.md`).** The docs flow now verifies user-visible claims against the shipped source and, when Jira and source disagree, escalates to the user (`/impl:jira:docs` Phase 5.8) instead of silently picking a side — document-as-source / document-as-jira (+ `<KEY>-implementation-gaps.md` bug-report draft + `intentional-discrepancy` marker) / skip-and-report. `doc-planner` records both `jira_phrasing` and `source_phrasing` (never auto-corrects); `doc-reviewer` gains a marker-aware Source-code accuracy dimension; the release-notes flow escalates the same way. Ports Copilot dev-workflows v1.7.0 + v1.8.0.

### Fixed
- **Style checks are robust and mandatory.** `docs-style-checker` falls back to the LLM-based `dt-style-checker` when the primary linter (Vale, etc.) errors or is missing — `NOT_CONFIGURED` only when nothing is available. `/impl:jira:docs` Phase 6.7 and a new `/impl:docs` Phase 3.5 are mandatory. `risk-planner` forbids recommending a skipped style check. (Copilot v1.7.0)
- **`doc-planner` accuracy rules.** No Jira key in changelog entries (commit carries traceability); no changelog-only frontmatter updates; cross-product parity touches are one-line pointers, never copied implementation detail. (Copilot v1.7.1 + v1.8.1)

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

## [1.5.1] — 2026-06-16

### Fixed
- **`/impl:jira:docs` screenshot staging is now persistent.** When a docs repo's
  `image_policy` is `cdn_upload_required`, screenshots awaiting manual CDN upload
  were staged under `/tmp/<JIRA_KEY>-screenshots/`. `/tmp` is in-image and
  ephemeral, so the staged files were lost on container restart — before the user
  had uploaded them. Staging now targets the ticket's **persistent Obsidian project
  folder** under `$VAULT_PATH` (always host-mounted), resolved by the command as a
  directory under `$VAULT_PATH/Projects/` whose name starts with `<JIRA_KEY>` (its
  `Doc screenshots/` or `Attachments/` subfolder); when no project folder is found
  the command asks for a persistent directory. The command passes the resolved
  `screenshot_staging_dir` to `doc-planner`. Neither the docs repo (which may be a
  docker repo-volume, not on the host) nor `/tmp` is used. Affects `doc-planner` and
  the `/impl:jira:docs` Phase 1 resolution, Phase 6 writer step, Phase 9 report, and
  invariants.

## [1.5.0] — 2026-06-16

### Changed (breaking for orchestrators that hardcode `/repos/`)
- **`/impl:jira:*` repo discovery is now `$REPOS_PATH`-based.** The old fixed
  `<repos_base>/<slug>` directory lookup (default `/repos`) is replaced by a scan
  rooted at `$REPOS_PATH` (default `/workspace`; colon-separated list supported)
  that maps each PR's repo-URL slug to an absolute local clone by matching
  `git remote get-url origin`. Multiple clones of one upstream are disambiguated
  by the preference order `<slug>-repo` > `<slug>_repo` > `<slug>_fast` >
  alphabetically last. This matches the container's `/workspace` umbrella layout
  (every repo and the Obsidian vault mounted under `/workspace`).
- **`diff-summarizer` / `code-scanner` inputs.** `repo_path` is now any absolute
  path (no longer assumed `/repos/<name>`), and a new optional `repo_url_slug`
  enables an upstream cross-check — on mismatch the agent returns `REPO_MISSING`
  instead of summarising the wrong repo.
- **`preload-context.sh`.** Emits `repos_path: ${REPOS_PATH:-/workspace}`
  (previously `repos_base: ${REPOS_BASE:-/repos}`).

### Migration notes
- If your clones still live under `/repos`, set `REPOS_PATH=/repos` to preserve
  the old base. The slug→clone match by `git remote` works regardless of base.

## [1.4.0] — 2026-06-15

### Changed
- **Subagent dispatch via `subagent_type`** — agents are now invoked as `dev-workflows:<agent>` (e.g. `dev-workflows:risk-planner`); Claude Code loads each agent's file body as its system prompt and honours its `model:` frontmatter. No caller-side `model` override or file-path read is needed. Supersedes the earlier `general-purpose` + `"Read and adopt ~/.claude/agents/<name>.md"` workaround.
- **Bundled reference paths via `${CLAUDE_PLUGIN_ROOT}`** — agent and skill bodies (and hook configs) now reference vendored docs via `${CLAUDE_PLUGIN_ROOT}/references/...` instead of hardcoded absolute data-directory paths.
- **`model-routing` skill** — new skill for command-level classification; slash commands invoke it to load `references/model-routing/classification.md` (skills can resolve `${CLAUDE_PLUGIN_ROOT}`, commands cannot).
- **Model fallback chain refreshed** — Opus 4.8 / Sonnet 4.6 with hyphenated model IDs throughout `references/model-routing/classification.md`.
- **Guideline commands (`/api-guideline-reviewer`, `/guideline-reviewer`) now dispatch their review in a subagent** — consistent with the rest of the command set.
- **`preload-context.sh` cosmetic fix** — the model-routing path hint now reads "invoke the model-routing skill" instead of the old `~/.claude/plugins/data/...` absolute path.

## [1.3.0] — 2026-05-15

### Changed
- **Cross-platform naming sync with Copilot CLI plugin (v1.3.0).**
  - Renamed `code-diff-summarizer` agent → `diff-summarizer` (aligns with
    Copilot CLI naming; all cross-references updated repo-wide).
  - Renamed `test-baseline` agent → `test-baseliner` (aligns with Copilot
    CLI naming; all cross-references updated repo-wide including handoff
    docs, orchestrator commands, and design specs).
  - Version numbers now track 1:1 between Claude Code and Copilot CLI
    plugin repos. Previous version drift: Claude 1.2.1 / Copilot 1.2.1.

## [1.2.1] — 2026-05-15

### Added
- **`upgrade-planner` agent.** Dedicated sub-agent for analysing a project and
  producing a versioned, step-by-step upgrade plan with risk annotations.
- **`upgrade-executor` agent.** Dedicated sub-agent that executes an approved
  upgrade plan step-by-step, running builds/tests after each step.
- **`vuln-research` agent.** Dedicated sub-agent for vulnerability triage —
  reads advisories, assesses exploitability, and recommends fix vs mitigate.
- **`vuln-fixer` agent.** Dedicated sub-agent that applies vulnerability
  remediation (dependency bumps, code patches) and verifies the fix.
- **Nine handoff reference docs** under `references/handoff/` for sub-agents
  that receive delegated work: code-scanner, diff-summarizer,
  impl-maintenance, jira-reader, test-baseliner, upgrade-executor,
  upgrade-planner, vuln-fixer, vuln-research.

### Changed
- `/upgrade` command refactored to delegate planning and execution to the new
  `upgrade-planner` and `upgrade-executor` agents via the `task` tool.
- `/vuln` command refactored to delegate research and remediation to the new
  `vuln-research` and `vuln-fixer` agents via the `task` tool.
- `CLAUDE.md` expanded from 60 → 204 lines: added skill taxonomy table,
  orchestrator/sub-agent relationship diagram, model-routing contract,
  key invariants, test requirements, update procedures, and guardrails.

## [1.2.0] — 2026-05-15

### Added
- **`guideline-reviewer` agent.** Reviews code and UI for compliance with
  Dynatrace Experience Standards (GUIDElines). Covers component usage
  (AppHeader, DataTable, FilterField, etc.), accessibility/WCAG compliance,
  terminology, settings patterns, and permissions. Reference docs in
  `references/guidelines/`.
- **`api-guideline-reviewer` agent.** Reviews OpenAPI specification files
  against Dynatrace REST API and IAM permission naming guidelines. Two-pass
  review (comprehensive analysis + detailed verification) checking version
  consistency, required elements, naming conventions, IAM scope format,
  HTTP status codes, and schema composition. Reference docs in
  `references/api-guidelines/` (REST API guidelines, permission guidelines,
  and an OpenAPI template).
- **`check_guidelines.py` script** in `references/guidelines/` — automated
  checklist generator for GUIDEline reviews.
- **`checklist-template.md`** in `references/guidelines/` — structured
  review template.

### Changed
- `plugin.json` keywords expanded.
- `marketplace.json` description updated (15 → 17 agents).
- **Model routing reference (`references/model-routing/classification.md`)
  expanded** from 92 to 265 lines — now includes model fallback chain,
  `model_routing` handoff block format, `task` tool delegation pattern,
  mandatory code-review checklist verdicts, and reporting section (synced
  from Copilot CLI port).

## [1.1.0] — 2026-05-10

`plugin.json` and `marketplace.json` declare `1.1.0`. The work landed across seven increments:

- **Increment A** — scaffolding (commit `25c73fc`)
- **Increment B** — `/impl:code` + `test-writer` agent (commit `29a727f`)
- **Increment C** — `/impl:docs` one-shot doc editing (commit `052e772`)
- **Increment D** — `/impl:jira:docs` + `/impl:jira:epics` + 9 agents (commit `e785adb`)
- **Increment E** — hook regex, README refresh, marketplace description refresh
- **Increment F** — per-command routing in `preload-context.sh` per spec §3 table (commit `4e18081`)
- **Increment G** — `/impl` repurposed as a dispatcher (breaking for 1.0.x users); verbatim-copy maintenance tax eliminated (this commit)

### Breaking changes
- **`/impl <description>` no longer runs the code-implementation workflow** (Increment G). In 1.0.x, `/impl <description>` was the canonical invocation for the full code workflow. In 1.1.0, `/impl` is a **dispatcher**: it prints a help message listing the `/impl:*` variants plus `/vuln` / `/upgrade`, then stops. If you have muscle-memory invocations like `/impl add rate limiting`, re-run them as `/impl:code add rate limiting` — the workflow body is unchanged (it lives in `commands/impl/code.md` and is registered as the slash command `/impl:code`). No aliasing; the redirect is a printed message only. Mid-1.1.0, an Increment-A iteration briefly shipped `commands/impl.md` as a verbatim copy of `commands/impl/code.md` with a `<!-- KEEP IN SYNC -->` marker — that approach is **not** what 1.1.0 ultimately ships; Increment G replaced it with the dispatcher to remove ~27 KB of duplication and eliminate the drift risk the marker was trying to manage.

### Added
- **Namespaced command layout.** New directory `commands/impl/` with sub-files `code.md`, `docs.md`, `jira/docs.md`, `jira/epics.md` — these become the slash commands `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics` via Claude Code's directory-to-namespace convention.
- **`/impl:code` full workflow (Increment B).** `commands/impl/code.md` is the canonical code-implementation command: classify → optional Opus planning → feature branch → **capture test baseline (new Pre-Phase 3.5)** → implement → **test-writing + regression verification (new Phase 3.5)** → optional Opus review → Phase 4 maintenance → Phase 5 report. Same structure as the pre-split `/impl`, with the two new test-related phases inserted and three new invariants added (`ALWAYS capture baseline`, `NEVER skip Phase 3.5`, `AFTER two fix-loop attempts, stop and surface`).
- **`commands/impl.md` is now a dispatcher** (final shape after Increment G). Prints a help page listing the four `/impl:*` variants (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`), a Related-commands section for `/vuln` and `/upgrade`, and a migration note pointing 1.0.x users at `/impl:code`. Does not execute any workflow — no classification, no branching, no agents, no git. The file is ~40 lines instead of ~27 KB; no "keep in sync" marker is needed because there is no longer a shadow copy of `commands/impl/code.md`. See the **Breaking changes** section above for the 1.0.x impact.
- **`agents/test-writer.md` (Increment B).** Default-model agent that writes tests for new or changed behaviour based on a diff. Mirrors `test-baseliner`'s framework detection and returns `Framework: not detected` immediately if none matches, so the caller can ask the user. Does NOT run tests — the caller runs `test-baseliner` verify separately. Hard rules: never retrofit tests for unchanged code, never invent a framework the project doesn't already use, never modify production code.
- **`/impl:docs` full workflow (Increment C).** `commands/impl/docs.md` is the one-shot doc-editing command: classify (always SIMPLE or MODERATE — redirects to `/impl:jira:docs` / `/impl:jira:epics` if the task turns out to be SIGNIFICANT on inspection) → plan with the `/impl:code`-style repo-exploration subagent → implement → validation checks (link integrity, heading structure, frontmatter parse, broken `[[wikilinks]]`) → Phase 4 maintenance → Phase 5 report. No branch, no baseline, no tests, no Opus, no commit — the user manages git manually. Phase 4 handoff sets `Change type: docs` and `Command run: /impl:docs`. Explicit invariants block all five "never" axes.
- **`/impl:jira:docs` full workflow (Increment D).** `commands/impl/jira/docs.md` is the Jira-driven feature-documentation command: Phase 0 vault + docs-repo detection → Phase 1 PR-status filter / refresh policy / `<repos_base>` / optional screenshot paths → Phase 1.5 classification (SIGNIFICANT; Jira read *is* the plan so no Opus planning) → Phase 2 plan + approval → Phase 3 `jira-reader` depth `full` → Phase 4 repo resolution (escalate missing per §15) → Phase 5 parallel `diff-summarizer` (batches of 4; aggregate "All PRs unresolved" gate) → Phase 5.5 `doc-location-finder` (3 status branches) → Phase 5.7 `doc-planner` (gap dispositions: ask-user / mark-TODO / skip-with-note) → Phase 6 writer (main command, with three-branch `image_policy` screenshot placement — `local` / `cdn_upload_required` / `ambiguous`) → Phase 6.5 branch setup (conditional on `docs_repo` context + user opt-in at plan approval) → Phase 6.7 `docs-style-checker` + `doc-fixer` + re-lint → Phase 7 `doc-reviewer` Opus gate (1-fix-1-rereview cap; per-BLOCKER escalation) → Phase 8 four maintenance agents in a single message → Phase 9 final report including `### Screenshots to upload manually` when any target used `cdn_upload_required`. Phase 8 handoff sets `Change type: docs` and `Command run: /impl:jira:docs`. Invariants from spec §6 preserved verbatim.
- **`/impl:jira:epics` full workflow (Increment D).** `commands/impl/jira/epics.md` is the Jira-driven Epic-writing command: Phase 0 vault-only context check (refuses to run outside `$VAULT_PATH`) → Phase 1 output dir / code-scan on-off / refresh policy / `<repos_base>` → Phase 1.5 classification (MODERATE; no Opus planning) → Phase 2 plan + approval → Phase 3 `jira-reader` depth `vi-plus-epics` (VI + every Epic linked to it, skipping Stories / Sub-tasks / Research / RFA) → Phase 4 conditional repo resolution (auto-derived from sibling Epics' PR URLs or manual) → Phase 5 conditional parallel `code-scanner` (batches of 4; scanner defaults `pull: true`, deliberately asymmetric with `diff-summarizer`'s `pull: false`) → Phase 6 writer (one `.md` per Epic with `## Goal` / `## Business value` / `## Scope (in / out)` / `## Acceptance criteria` / `## Dependencies` / `## Suggested stories` / `## References`) → Phase 7 `epic-reviewer` Opus gate (1-fix-1-rereview cap; "Defer" appends a `## Refinement notes` section to the draft) → Phase 8 four maintenance agents → Phase 9 final report. NEVER branches, NEVER commits, NEVER writes inside `jira-products/` or `_archive/`, NEVER writes outside `$VAULT_PATH`, NEVER runs `docs-style-checker` (enforced by absence of a Phase 6.7). Phase 8 handoff sets `Change type: docs` and `Command run: /impl:jira:epics`.
- **Nine new agents (Increment D).** All declare `tools:` as YAML arrays matching the existing in-repo style (`risk-planner`, `code-review`, `test-writer`).
  - **`agents/jira-reader.md` (§12)** — reads the pre-exported Jira markdown hierarchy under `$VAULT_PATH/jira-products/<JIRA_KEY>/`; three depths (`full` / `vi-plus-epics` / `vi-only`). Output: `value_increment` + `linked_items` + `pull_requests` + `themes`. Parses the Jira-to-Obsidian exporter's two-line-per-PR bulleted format with backticked branch names and a Unicode `→` arrow (not ASCII `->`). Three host categories recognised (`github_cloud`, `bitbucket_cloud`, `bitbucket_server`); `bitbucket_server` detected by the substring rule (hostname contains `bitbucket` and is not `bitbucket.org`), never a hardcoded domain. Inherits the session's model.
  - **`agents/doc-fixer.md` (§10)** — shared between `/impl:jira:docs` and `/impl:jira:epics`. Applies BLOCKER / MAJOR fixes from a `doc-reviewer`, `epic-reviewer`, or `docs-style-checker` output. Returns a `Fix Report` with the same `Stop condition flag` contract as `review-fixer`. Doc-type-agnostic because the finding schema is shared. Inherits the session's model.
  - **`agents/diff-summarizer.md` (§13)** — resolves a single repo's PR diffs and returns a doc-focused summary. Host-aware resolver: `gh` CLI for `github_cloud` (when installed + authenticated), local-git Strategies 1–4 for the rest (including GitHub fallback). Strategy 1: Bitbucket Server `refs/pull-requests/*` (usually absent). Strategy 2: branch search (0 or 2+ matches fall through silently). Strategy 3: merge-commit grep (`[Pp]ull[ _-]?[Rr]equest[ _-]?#?<pr_id>\b`). Strategy 4: cross-hierarchy Jira-key commit grep (last resort; summary MUST carry the "reconstructed from commit — may not exactly correspond" caveat). Statuses: `OK` / `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` / `NO_PRS_RESOLVED` / `PARTIAL`. `refresh.pull` defaults to `false`. Inherits the session's model.
  - **`agents/doc-location-finder.md` (§10a)** — finds write target(s) in a docs repository. Heuristic + grep scoring across the detected docs-tree root(s); three placement kinds (`extend-existing` / `new-page-in-existing-section` / `new-section`). Statuses: `OK` / `LOW_CONFIDENCE` (with `confidence_notes`) / `EMPTY`. Never writes. Inherits the session's model.
  - **`agents/doc-planner.md` (§10b)** — synthesises the documentation checklist the writer follows and `doc-reviewer` checks against. Detects the repo's `image_policy` by sampling sibling / ancestor markdown pages: `local` (copy screenshots to `<page-dir>/img/`), `cdn_upload_required` (stage under `/tmp/<JIRA_KEY>-screenshots/` — NEVER inside the repo — and surface in Phase 9), or `ambiguous` (writer prompts the user at Phase 6). Per-page YAML frontmatter updates (including the mandatory `changelog:` append), snippet reuse / extract, cross-links, and gap dispositions. Inherits the session's model.
  - **`agents/docs-style-checker.md` (§10c)** — runs the repo's project-configured prose linter on files written in Phase 6 and normalises output into the shared finding schema. Detection order: Vale via `.vale.ini` → `package.json` `*:lint` / `lint:*` script → `.markdownlint.json(c)` / `.remarkrc*` → `NOT_CONFIGURED`. Severity mapping: `error` → MAJOR, `warning` → MINOR, `suggestion` → NIT. 2-minute cap. Never promotes linter severity. Inherits the session's model.
  - **`agents/doc-reviewer.md` (§9, Opus)** — reviews product documentation written by `/impl:jira:docs`. Eleven dimensions: factual correctness, completeness vs plan, coverage, audience fit, structural integrity, YAML frontmatter, screenshots (both `image_policy` branches), snippets, actionability, source traceability, style-check follow-through (from `docs-style-checker`). Verdict: PASS / PASS WITH RECOMMENDATIONS / BLOCK. `model: opus` declared in frontmatter and `model: "opus"` passed on the caller's Agent call (belt-and-braces, mirroring `risk-planner` / `code-review`).
  - **`agents/code-scanner.md` (§14)** — scans a single code repo for existing capabilities and gaps relative to a set of themes. Pure filesystem search (grep / glob / read); no HTTPS. `refresh.pull` defaults to `true` (capability scans target the default-branch tip — deliberately asymmetric with `diff-summarizer`). Per-theme 30-second budget; themes that can't be scanned get `classification: error` + reason and do NOT abort the whole scan. Statuses: `OK` / `PARTIAL` / `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` / `EMPTY`. Inherits the session's model.
  - **`agents/epic-reviewer.md` (§9b, Opus)** — reviews Epic drafts written by `/impl:jira:epics`. Nine dimensions: goal clarity, business value, scope (in / out), acceptance criteria (testable), dependencies, suggested stories, non-duplication (BLOCKER when undetected; cross-checks against `jira-reader` `linked_items` filtered to `type == Epic`), references (code paths must match `code-scanner` `evidence.path` when that output is provided), structural integrity. Never treats the absence of a `code-scanner` output as a finding — the user may have opted out of code examination. `model: opus` in frontmatter + `model: "opus"` on the caller's Agent call.

### Changed
- **`agents/impl-maintenance.md` input / output enums.** The Inputs section now requires a `Command run:` field (one of `/impl`, `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`); missing values default to `/impl:code` with a note in the report. The "Command workflow improvements" output enum broadened to match, so maintenance suggestions from the three new Jira/docs commands are scoped to the right command variant.
- **`commands/vuln.md` and `commands/upgrade.md` session handoffs.** Both now pass `Command run: /vuln` and `Command run: /upgrade` respectively to `impl-maintenance`. Without this, the agent would default to `/impl:code` and misattribute any `/vuln` or `/upgrade` suggestions — a silent regression the spec's Wave 6 W6-m2 + §3 update implied but didn't explicitly call out for the two pre-existing commands.
- **`commands/impl/code.md` Phase 4 change summary block now includes `Change type: code`** (and a matching invariant). Aligns with `/impl:docs` (`Change type: docs`) and the two new Jira commands (both `docs`). The field is a scoping hint for the Documentation / Knowledge / Instructions maintenance agents — their prompts already reference the change summary block, so no agent prompt changes are needed.
- **`hooks/preload-context.sh` regex (Increment E).** Replaced `^/(impl|vuln|upgrade)[[:space:]]+[^[:space:]-]` with `^/(impl(:(code|docs|jira(:(docs|epics))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-]` so `/impl:code`, `/impl:docs`, `/impl:jira:docs`, and `/impl:jira:epics` now trigger context injection. The normative regex is defined in spec §3 and verified against a 28-case matrix. Bare `/impl:jira foo` also matches — the `:(docs|epics)` sub-namespace is optional by design (over-match is preferable to missing a valid invocation). Header comment updated to list all covered commands.
- **`hooks/preload-context.sh` per-command routing (Increment F).** After the regex match the hook now reads `${BASH_REMATCH[1]}` and routes per the spec §3 table: `/impl`, `/impl:code`, `/vuln`, `/upgrade` get the full block (model-routing reminder + git status + recent commits + small-repo directory listing); `/impl:jira:docs` and `/impl:jira:epics` get a `Jira workflow` header with `VAULT_PATH` (or an unset-note fallback), a `repos_base` default (`${REPOS_BASE:-/repos}`), and `git branch --show-current` only when cwd is inside a git repo — no model-routing, no full status/log, no directory listing; `/impl:docs` exits silently (spec: "None — user manages git manually; model-routing is not triggered"). Bare `/impl:jira foo` (spec-intentional over-match) is routed to the Jira branch. Verified with a 10-assertion stdin harness covering all four routing paths plus noise.
- **`hooks/preload-context.sh` — `/impl` moved to silent branch (Increment G).** Follows the dispatcher change. `/impl <args>` now prints help and stops, so injecting the full git context + model-routing reminder would be pure noise before a help screen. `/impl:code`, `/vuln`, `/upgrade` continue to get the full context; `/impl:jira:docs` / `/impl:jira:epics` continue to get the Jira context; `/impl` joins `/impl:docs` in the silent branch. This is a minor deviation from spec §3's "`/impl` (alias) → Full" row, justified by the alias no longer existing; the spec table is superseded for the `/impl` row by Increment G.
- **`agents/impl-maintenance.md` — `/impl` removed from the live Command-run enum (Increment G).** The Inputs section now lists six live values (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`). For replay compatibility with archived 1.0.x handoffs, the literal legacy value `/impl` is still accepted on input and internally mapped to `/impl:code` with a note in the report. The "Command workflow improvements" output enum drops `/impl` entirely — the agent will never suggest changes against a command that no longer runs a workflow.
- **`commands/impl/code.md` Phase 4 handoff (Increment G).** Dropped the now-stale parenthetical on the `Command run: /impl:code` line that explained the "`/impl` alias is a transport detail". The alias is gone; no explanation is needed.
- **`README.md` refresh (Increment E).** Rewritten to document the final 1.1.0 shape: dropped the "1.1.0 in progress" banner; rebuilt the Commands section as a 5-row table for the `/impl` family plus a secondary 2-row table for `/vuln` and `/upgrade`; rebuilt the Agents section as 15 rows with a Model column (Opus for `risk-planner`, `code-review`, `doc-reviewer`, `epic-reviewer`; `inherits` for the other 11); added an Environment prerequisites section covering `gh auth login`, optional `vale`, and the recommended [ihudak/ai-containers](https://github.com/ihudak/ai-containers) environment (per spec §17); updated the Hooks table to list the seven command shapes the matcher now covers.
- **`.claude-plugin/marketplace.json` dev-workflows description (Increment E).** Refreshed from "Three slash commands (/impl, /vuln, /upgrade) … five reusable subagents … three notification hooks" to name all five `/impl`-family commands plus `/vuln` and `/upgrade`, list all fifteen subagents, and describe the three notification / context hooks. `version` field unchanged (1.1.0).

Design spec: `docs/superpowers/specs/2026-04-30-impl-split-and-test-writing-design.md`.
Review history: `docs/superpowers/specs/2026-05-08-impl-split-and-test-kiro-review.md` (waves 1–7).

---

## Pre-plugin-split history (prior monorepo)

The sections below describe the original [`ihudak-claude-plugins`](https://github.com/ihudak/ihudak-claude-plugins) monorepo from which this plugin was extracted. They reference infrastructure that no longer applies to the standalone plugin — root-level `install.sh` / `uninstall.sh` / `install.ps1`, `plugins/workflow-tools/`, `tests/smoke.sh`, and `~/.claude/settings.json` hook merging. Retained as provenance; not part of the **dev-workflows** plugin's own version history.

### [Unreleased] (pre-plugin-split)

#### Added
- **Model routing across `/impl`, `/vuln`, `/upgrade`.** Every command now classifies the task as `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK` before planning. `SIMPLE` / `MODERATE` continue on the currently selected model. `SIGNIFICANT` / `HIGH-RISK` route planning and post-implementation review through Opus and gate the test run on the review verdict.
- **`agents/risk-planner.md`** — Opus-backed risk-weighted planner system prompt. Returns a structured plan with explicit security, migration, API-stability, concurrency, dependency, rollback, and test-adequacy sections. Refuses to run without a classification. Includes a re-classification escape hatch: if the task turns out to be `SIMPLE` / `MODERATE` on inspection, the planner returns a `### Re-classification` section instead of the full plan and the caller falls back to the non-Opus path.
- **`agents/code-review.md`** — Opus-backed post-implementation reviewer system prompt. Checks eight dimensions (correctness, security, architecture, edge cases, migration risks, dependency risks, test adequacy, rollback). Returns `PASS` / `PASS WITH RECOMMENDATIONS` / `BLOCK`. `BLOCK` gates the test run. Same re-classification escape hatch.
- **`agents/test-baseliner.md`** — moved from `plugins/workflow-tools/` to the repo's top-level `agents/`. Same behaviour, now installed at `~/.claude/agents/test-baseliner.md` as a user-level subagent.
- **`agents/review-fixer.md`** — default-model agent that auto-fixes BLOCKER and MAJOR findings from a code-review report, deferring findings that require design judgment, migration sequencing, or cross-cutting test strategy. Returns a structured fix report with a `Stop condition flag` so callers know whether to re-review. Wired into all three commands' BLOCK and PASS-WITH-RECOMMENDATIONS branches.
- **`agents/impl-maintenance.md`** — default-model suggest-only post-session analyst. Reads the session handoff, scans existing rules/hooks/agents, returns a structured Lessons Learned report (CLAUDE.md rules, hooks, reference doc gaps, new agent suggestions, command workflow improvements). Does not write files.
- **`references/model-routing/classification.md`** — single source of truth for the four complexity levels, the triggers, the routing rules, and the eight review dimensions. All three commands link to it.
- **`tests/smoke.sh`** — install → uninstall → install smoke test in a throwaway `HOME`. 54 assertions. Covers full install, idempotent re-run, subtractive `--no-hooks`, `--no-plugin` rejection (the flag is retired), `uninstall.sh`, round-trip re-install, legacy `plugins/workflow-tools` cleanup, JSON validity, and agent-file frontmatter validation.
- **`uninstall.ps1`** — native Windows uninstaller (PowerShell). Mirrors `uninstall.sh`: removes managed symlinks/copies and strips hook entries from `settings.json` if Python is available.
- **`.gitignore`** — added `settings.local.json`, `settings-local.json`, `.claude/settings.local.json` to prevent accidental commit of Claude Code machine-specific overrides.
- **`test-baseliner.md` verify mode** — second mode alongside `capture`: re-runs tests, diffs against a prior baseline, returns a structured regression report (regressions, missing-from-run, newly fixed, new failures, current snapshot for chaining). All three commands now use verify mode for post-fix comparisons.
- **Feature-branch pre-step in `/impl`, `/vuln`, `/upgrade`** — clean-tree check (stash/proceed/cancel), branch-convention detection, slug generation, HEAD context check, `git checkout -b` BEFORE any file is written. Branch naming: `feat/<slug>` for impl, `chore/upgrade-<component>-to-<ver>` for upgrade, `fix/[JIRA-]CVE-XXXX-XXXXX` for vuln.
- **Ruby/Bundler section in `references/fix-vuln/build-systems.md`** and **PHP/Composer section in `references/upgrade/ecosystems.md`** — expand ecosystem coverage to match `/vuln` Detect agent scan list.

#### Changed in commands
- **`/impl`** — new Phase 1.5 classification step; for `SIGNIFICANT` / `HIGH-RISK`, planning is delegated to `risk-planner` (Opus) and the post-implementation `code-review` (Opus) gates the test run. Implementation itself stays on the currently selected model or Sonnet — Opus is reserved for planning and review. Phases 4 and 5 include the classification and the review verdict. Phase 2B "Revise" re-sends the full risk-planner brief (the planner refuses partial briefs).
- **`/vuln`** — step 5 classifies each CVE on the actual change required (same-major patch/minor bump → `MODERATE`; major bump or API-break or security-sensitive code path → `SIGNIFICANT` / `HIGH-RISK`). `MODERATE` keeps the existing flow; `SIGNIFICANT` / `HIGH-RISK` delegate planning to Opus, review the fix with Opus, and gate tests on the verdict. Classification is included in the commit message and PR body. The risk-planner brief no longer overstates the inputs — it passes declaration paths from the Detect agent and lets the planner do its own usage-site grep.
- **`/upgrade`** — Phase 1 step 5 classifies each component. `MODERATE` components follow the existing apply → build → test path. `SIGNIFICANT` / `HIGH-RISK` components plan with Opus (Phase 1 step 8) and get an Opus review before build/test (Phase 2 step 6). Summary table gains `Class` and `Review` columns. Same brief-correctness fix as `/vuln` — the brief passes inventory paths + Agent A's compat output and delegates usage-site scanning to the planner.

#### Changed in hooks
- **`preload-context.sh`** — injects a one-line model-routing reminder before the existing git context for `/impl`, `/vuln`, `/upgrade`. Points at `references/model-routing/classification.md` so the rules are one read away. Regex tightened to require at least one non-whitespace, non-hyphen argument so bare `/impl` or `/impl --help` no longer triggers a context injection. Directory listing now gated to repos with ≤30 root entries — large repos no longer leak the listing into context.

#### Changed in installers / docs
- **`install.sh --no-hooks` is subtractive**, not just a skip-flag. It actively removes previously-installed hook symlinks and strips matching entries from `settings.json` so the post-flag state matches what users expect.
- **`uninstall.sh` and `uninstall.ps1` symlink matching tightened** — require a path-segment boundary (`/claude-config/` rather than a loose substring) so unrelated paths like `claude-config-backup` can't be matched.
- **`install.sh` / `install.ps1` legacy-plugin cleanup** — on upgrade from a pre-restructure install, both installers remove any leftover `~/.claude/plugins/workflow-tools` symlink and drop the empty `~/.claude/plugins/` parent if nothing else lives there.
- **`README.md`** — surfaces the Windows installation path from the main Install section; adds the native Windows uninstall command and update workflow; documents the new `Class` / `Review` columns in the `/upgrade` example table; new "Subagents" section explaining the `general-purpose` + `model: "opus"` invocation pattern; replaces "commands + plugin" framing with "commands + agents".

#### Fixed
- **Subagent invocation pattern: `general-purpose` + `model` override.** Earlier iterations of this release tried two layouts that did not actually register the subagents — `plugins/workflow-tools/` (which requires marketplace registration + `installed_plugins.json` + `enabledPlugins`, not satisfied by a local symlink) and a user-level `agents/*.md` install (which requires a session restart to be discovered). Both produced static-correctness wins but a no-op routing in the installing session. The three commands now invoke the agents via `Agent(subagent_type: "general-purpose", model: "opus", prompt: "Read and adopt ~/.claude/agents/<name>.md, then [brief]")`. The `model` argument on the `Agent` tool itself forces Opus for `risk-planner` / `code-review` regardless of discovery; `test-baseliner` omits the override and inherits the session's model. Agent files are still installed at `~/.claude/agents/` so a future Claude Code release with reliable user-agent discovery can invoke them directly with no further changes. Verified empirically in-session. Removes the `--no-plugin` installer flag (the agents are required by `/vuln`, `/upgrade`, and the Opus-gated `/impl` flow — there is no opt-out).
- **`agents/risk-planner.md` and `agents/code-review.md` cite classification rules by absolute path** (`~/.claude/claude-config/references/model-routing/classification.md`). The agents' working directory is the caller's project, not this repo, so relative paths wouldn't resolve.
- **Classification file-count threshold made exclusive** — was `more than 3-5` on SIGNIFICANT and `fewer than 3-5` on MODERATE, which both matched at exactly 4. Pinned to `4 or more` for SIGNIFICANT and `3 or fewer` for MODERATE.
- **`agents/test-baseliner.md` Makefile parse row** — previously detected `make test` but had no parse pattern; a Make-driven project would silently get `Total: 0 | Passing: 0 | Failing: 0`. The parse table now has a Make row with best-effort pattern matching and a note explaining the limitation.
- **`install.ps1` / `uninstall.ps1`** — removed PowerShell 7+ only operators (`||`, `??`) that broke on Windows PowerShell 5.1 (the default on Windows 10/11). Replaced with PS5.1-compatible forms.
- **`install.ps1` / `uninstall.ps1`** — replaced em-dashes and box-drawing characters with ASCII. Windows PowerShell 5.1 reads BOM-less script files using the ANSI code page, which mangled UTF-8 multi-byte sequences and caused parser errors at every line with fancy characters.
- **`uninstall.ps1`** — probe Python with a real `--version` call before using it, so the Windows Store `python3.exe` stub (a placeholder that errors at runtime) is correctly identified as "not Python" and the script prints a helpful skip-message instead of a red error.
- **NVD/Detect circular dependency in `/vuln`** — split research into Round A (NVD + Baseline in parallel, no package name needed) then Round B (Detect agents per CVE, package names now known). Per-CVE failure handling explicit.
- **`subagent_type: "Explore"`** replaced with `general-purpose` + explicit Read/Glob/Grep/LS tool restrictions in `/impl` and `/vuln` (Explore is not a valid Claude Code Agent type).
- **`git diff` for new-file-only implementations** — all three commands now use `git add -N . && git diff` so the code-review agent never receives an empty diff.
- **`/upgrade` Agent B is now read-only** in Phase 1; changes are applied in Phase 2 prep step 3, AFTER baseline capture, so the baseline is pristine.
- **`/upgrade` Opus planning** moved before user confirmation; user now sees the full Opus-generated plan before approving.
- **`code-review.md` `Bash` removed from tools list** — reviewer must be read-only; the "NEVER modify files" prompt rule is now enforced by the toolset.
- **Stop condition enforcement** — all three commands enforce: after one review-fixer pass + one re-review, if verdict is still BLOCK, stop and surface to user. No infinite loops.
- **OWASP filter regex** in `/vuln` — `A\d` → `A\d{2}` (OWASP IDs use two digits).
- **`/vuln` Detect agent scan list** expanded to include `*.csproj`, `Gemfile`, `composer.json` (aligning with `build-systems.md` coverage).
- **`hooks/test-notify.sh` ARG_MAX** — switched from passing test output as argv to stdin pipe; large test outputs (>128KB on Linux, >256KB on macOS) no longer crash the hook.
- **`commands/vuln.md` SIGNIFICANT/HIGH-RISK path numbering** — fixed duplicated step 4, missing step 5; downstream references updated.
- **`commands/upgrade.md` Phase 2 structure** — split into "Phase 2 prep (once)" + per-component loop with unambiguous numbering (prep: 1–3, loop: 1–8).
- **`commands/impl.md` Phase 4 agent count** — corrected "three agents" → "four agents".
- **`commands/impl.md` Phase 5 report** — now surfaces feature-branch name under `### Branch`.
- **`references/model-routing/classification.md`** — "4+ non-test files" threshold qualified to require non-trivial logic changes (excludes pure renames, import updates, mechanical refactors, generated-code changes).
- **`references/fix-vuln/nvd-api.md` safe-version derivation** — added worked examples for `.Final`/`-RELEASE` suffixes; clarified range-matching against project's current version line to avoid wrong-range selection.
- **`references/upgrade/compatibility.md`** — new "Known major migrations" section documenting Spring Boot `javax`→`jakarta` migration with detection command, fix approach, and companion changes.
- **`/upgrade` companion-upgrade chain** — now hard-capped at 3 levels with cycle detection; chains exceeding the limit are surfaced as `BLOCKED — companion-cycle` in the summary table (matters for unattended ai-container runs).
- **`hooks/preload-context.sh`** — directory listing gated to repos with ≤30 root entries; large repos no longer leak the listing into context.
- **`/vuln` commit template** — removed hardcoded `Co-authored-by: Claude Code <noreply@anthropic.com>` (some corp Bitbucket instances reject the email).
- **All PowerShell code fences in `references/fix-vuln/build-systems.md`** corrected to `bash` fences.

#### Verified
- End-to-end install and uninstall on Windows with both Windows PowerShell 5.1 and PowerShell 7.6.1. PS 5.1 falls back to file copies (no Dev Mode / admin); PS 7.6.1 successfully creates symlinks. Round-trip install → uninstall → install works cleanly on both. Smoke test (`tests/smoke.sh`) is 54/54 green on Linux.

### 2026-04-24 (monorepo 1.1.0)

#### Added
- **`uninstall.sh`** — idempotent reverse of `install.sh`; removes managed symlinks and strips our hook entries from `~/.claude/settings.json`.
- **`install.sh --no-hooks` / `--no-plugin` / `--help`** flags for granular installs.
- **`install.ps1`** — native Windows installer (PowerShell). Creates symlinks with auto-fallback to file copy when Developer Mode / admin isn't available. Skips hooks (bash-only).
- **`references/fix-vuln/`** and **`references/upgrade/`** — reference docs for `/vuln` and `/upgrade` are now vendored into the repo (previously external at `~/.copilot/skills/`).
- **`CHANGELOG.md`** — this file.

#### Changed
- **Hook field names corrected**: `preload-context.sh` now reads the `prompt` field (with `user_prompt`/`message` fallbacks) from the UserPromptSubmit payload; `test-notify.sh` now reads `tool_input.command` and `tool_response.output` (with top-level fallbacks) from the PostToolUse payload. Both hooks were previously silently exiting early due to reading the wrong fields.
- **`preload-context.sh` hardening** — removed `set -euo pipefail`, added `python3` availability guard, error-tolerant command substitution. Matches the robustness of `test-notify.sh`.
- **`/impl` step 8 agents** now receive a structured change summary block (including `git diff --stat` output and notable additions/removals) instead of a one-sentence description. Documentation, knowledge, and instructions agents can now reason precisely about what changed.
- **`install.sh` location guard** — refuses to run unless located at `$HOME/.claude/claude-config/`. Prevents silent misconfiguration when the repo is cloned elsewhere.
- **`install.sh` plugin symlink** — now unconditionally `rm -rf`s the target before `ln -sf`, preventing the "stray nested symlink" bug that occurred on repeated runs.
- **`install.sh` settings.json guard** — creates an empty `{}` skeleton if `~/.claude/settings.json` doesn't exist, rather than crashing.
- **`test-notify.sh` output parsing** — uses `python3` for framework output parsing (portable) instead of `grep -oP` (GNU-only, fails on macOS).
- **`/vuln` intro** — clarified the sequential-then-parallel execution model.
- **`/upgrade` Phase 2 step 3** — excludes `.github/workflows/` to prevent GitHub Actions from being processed twice.
- **README** — added detailed per-command phase explanations, Windows section, uninstall instructions, install-flag table.

### 2026-04-24 (monorepo 1.0.0)

Initial shareable repo.

#### Added
- **`commands/impl.md`** — `/impl` command with Explore subagent before planning and three parallel post-implementation agents (Documentation / Knowledge / Instructions).
- **`commands/vuln.md`** — `/vuln` command with parallel NVD / Detect / Baseline research before fix.
- **`commands/upgrade.md`** — `/upgrade` command with parallel compatibility research and GitHub Actions agents in Phase 1; uses `workflow-tools:test-baseliner` for the test baseline.
- **`plugins/workflow-tools/`** — plugin with the reusable `test-baseliner` agent (Maven / Gradle / npm / pytest / Makefile detection).
- **`hooks/notify-done.sh`** — Stop hook; cross-platform desktop notification (macOS / Linux / WSL2 fallback chain).
- **`hooks/preload-context.sh`** — UserPromptSubmit hook; injects git branch/status/log for `/impl` / `/vuln` / `/upgrade`.
- **`hooks/test-notify.sh`** — PostToolUse:Bash hook; parses test output and notifies.
- **`install.sh`** — idempotent installer; `ln -sf` symlinks + Python JSON merge.
- **`settings-additions.json`** — hook entries merged into `~/.claude/settings.json`.
- **`README.md`** — setup, usage, and platform notes.
- **`docs/specs/2026-04-24-command-subagents-hooks-design.md`** — design document.

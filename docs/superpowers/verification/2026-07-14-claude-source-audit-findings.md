# Claude Marketplace — dev-workflows source audit findings

> ## ✅ RESOLVED — 2026-07-14
>
> All findings below (2 BLOCKER, 7 MAJOR, 26 MINOR) were fixed on branch
> `fix/claude-source-audit-findings` in `/workspace/ihudak-claude-plugins`,
> released as **v2.31.0**. 16 commits, one per logical fix group (blockers
> first, then majors, then minors by section) — see that branch's log or
> `plugins/dev-workflows/CHANGELOG.md` [2.31.0] for the itemized list.
>
> Two items were investigated and found to be **false positives**, not bugs:
> BUG-3's `guideline-reviewer.md`/`api-guideline-reviewer.md` bare-path
> citations (both carry their own "all paths relative to
> `${CLAUDE_PLUGIN_ROOT}`" preamble) and the `create-vi`/`create-ard`
> description-frontmatter mentions (human-facing catalog text, not runtime
> citations) — both already deliberately excluded by the prior `12c245a`
> cleanup commit, which the fresh audit re-flagged without that context.
>
> One additional bug was found and fixed while addressing BUG-1 (same
> contamination class, not originally in this doc): `vuln.md`'s commit
> template and `vuln-fixer.md`'s invariant both hardcoded a GitHub Copilot
> bot co-author trailer (`Co-authored-by: Copilot <...@users.noreply.github.com>`)
> — replaced with a generic Claude trailer.
>
> Merged and pushed to `main` in `ihudak-claude-plugins` (`1ff46a8`, v2.31.1)
> and ported + merged + pushed to `main` in `mgd-claude-plugins` (`eb105a2`,
> v2.31.1) as well, keeping the two marketplaces at feature parity.
>
> ## ✅ §4 RESOLVED — 2026-07-14
>
> The one residual issue below (stale `clarifications_needed[]` cross-ref in
> `epics.md`, "Phases 6.2 and 7" → "Phases 6.1 and 7") was fixed in both
> repos as **v2.31.1** (`ihudak-claude-plugins@1ff46a8`,
> `mgd-claude-plugins@eb105a2`), merged and pushed to `main` in both.

---

**Audited:** `/workspace/ihudak-claude-plugins/plugins/dev-workflows` (v2.30.0)
**Date:** 2026-07-14
**Scope:** Internal correctness/consistency of the **Claude Code native** plugin. This is
NOT about Copilot compatibility. Cost reporting, statusline, and the intentional model IDs
(`claude-sonnet-5`, `claude-opus-4-8`, …) are working-as-designed and are NOT flagged.
**Method:** Deterministic mechanical sweeps (this file, §1) + 4 parallel Opus-4.8 semantic
audits (§2, appended after the agents return).

> Per workflow convention, these are **logged for later fixing in the Claude marketplace** —
> NOT fixed in place during the Copilot port.

---

## §1 — Mechanical findings (deterministic, high confidence)

### BUG-1 (MAJOR — likely BLOCKER): wrong Task-tool dispatch parameter in `vuln.md` + `upgrade.md`
Claude Code's `Task` tool takes **`subagent_type:`**. 56 dispatch calls across the plugin
use it correctly, but **7 calls use `agent_type:`** (that is the *Copilot* CLI parameter —
almost certainly leaked in from a cross-marketplace edit):

- `commands/vuln.md:44` — `agent_type: "dev-workflows:vuln-research"`
- `commands/vuln.md:86` — `agent_type: "dev-workflows:vuln-fixer"`
- `commands/vuln.md:116` — `agent_type: "dev-workflows:vuln-fixer"`
- `commands/upgrade.md:29` — `agent_type: "dev-workflows:upgrade-planner"`
- `commands/upgrade.md:65` — `agent_type: "dev-workflows:risk-planner"`
- `commands/upgrade.md:96` — `agent_type: "dev-workflows:test-baseliner"`
- `commands/upgrade.md:112` — `agent_type: "dev-workflows:upgrade-executor"`

**Impact:** In Claude Code these dispatches may fail (unrecognised param) — i.e. `vuln:` and
`upgrade:` could be broken end-to-end. **Fix:** rename all 7 `agent_type:` → `subagent_type:`.
*(Confirm against current Claude Code Task-tool schema before fixing — if Claude Code has
started accepting `agent_type` as an alias, downgrade to a consistency-only MINOR.)*

### BUG-2 (MINOR): 4 agents missing the `tools:` frontmatter field
`agents/upgrade-executor.md`, `agents/upgrade-planner.md`, `agents/vuln-fixer.md`,
`agents/vuln-research.md` declare no `tools:` (the other 26 agents do). In Claude Code an
agent without `tools:` inherits the full tool set — so this is *valid* but **inconsistent**,
and it hides intent (e.g. whether these agents should be able to dispatch other sub-agents).
**Fix:** add explicit `tools:` lists for parity, OR document that the omission is deliberate.
*(Note: this was the root cause of the `task`-tool gap discovered in the Copilot port.)*

### BUG-3 (MINOR): residual bare `references/…` citations (inconsistent with the prefixed convention)
198 citations use `${CLAUDE_PLUGIN_ROOT}/references/…`; a handful use a bare relative
`references/X.md` that only resolves if the reading agent's cwd is the plugin root:
- `agents/guideline-reviewer.md` (11), `agents/api-guideline-reviewer.md` (3)
- `commands/create-ard.md`, `commands/create-vi.md` (description fields), `commands/docs-profile.md:115`
- `references/dynatrace-docs/docs-profile.default.yml:52-53`, `docs-profile-schema.md:55-56`
  — these two are config **values** written into a docs repo, so likely intentional repo-relative.

**Fix:** prefix the agent/command prose citations with `${CLAUDE_PLUGIN_ROOT}/`; leave the
docs-profile config values as-is (confirm they're meant to be repo-relative).
*(You already fixed the 4 prose refs in context-management/feedback-emission/next-phase-offer/followup-emission — thanks.)*

### Verified CLEAN (mechanical)
- All `${CLAUDE_PLUGIN_ROOT}/references|scripts|commands/…` targets that ARE prefixed resolve to real files.
- All 26 `subagent_type: "dev-workflows:<x>"` targets resolve to real agent files.
- Version consistent: plugin.json = CHANGELOG top = marketplace.json = **2.30.0**.
- All 30 agents have `name` (matching filename) + `description`; all 20 commands have `description`.
- Model IDs internally consistent (`claude-sonnet-5` is a deliberate "latest Sonnet" tier in the routing ladder, used across all 14 routing-aware commands).
- No stray GPT/Gemini refs (correct — Claude-only plugin).
- `opus_available` used consistently (23×); no `strong_available` drift (that was a Copilot-port-only artifact).
- TODO/TBD markers found are all intentional feature behavior (doc-writer placeholders, runtime-deferred values), not unfinished work.

---

## §2 — Semantic findings (Opus-4.8 deep audit)

### 2A — Code Orchestrators (implement / vuln / upgrade + agents + model-routing SSOT)

**BLOCKER — `test-baseliner` dual/incompatible output schema breaks vuln+upgrade verify flow.**
`agents/test-baseliner.md:44,96,100` tells the agent to emit `## Test Baseline` / `## Test Verify
Report` with **no `status:` field** (verify uses `Comparison status:` + a `Regressions` count).
But `references/handoff/test-baseliner.md:23-45` documents a *different* "exact" schema
(`## Test Baseline Result` + `status: OK|REGRESSIONS|RUN_FAILED|COMMAND_NOT_FOUND|NO_TESTS`).
`agents/vuln-fixer.md:40,48-50` and `agents/upgrade-executor.md:35-37` drive their entire
verify→proceed-or-revert control flow off the `status:` field the agent never emits → every
status-branch is dead. **Fix:** unify on one schema (make test-baseliner emit the
`## Test Baseline Result` + `status:` form, or reparse `Comparison status`+`Regressions` in both executors).

**MAJOR — `implement.md` stale dispatch prose contradicts the actual call.** `commands/implement.md:264-269`
(Phase 2B) and `:436-440` (Phase 3B) say "invoke via `general-purpose` with `model: "opus"` override
+ read-the-system-prompt-from-file", but the dispatch right below uses
`subagent_type: "dev-workflows:risk-planner"` / `"dev-workflows:code-review"` (frontmatter-pinned,
no override). **Fix:** delete the stale general-purpose+override paragraphs — the dedicated agents already pin `model: opus`.

**MAJOR — `upgrade-planner` claims an Opus pinning the orchestrator never does.**
`agents/upgrade-planner.md:56` says the orchestrator pins it to Opus for SIGNIFICANT/HIGH-RISK, but
`commands/upgrade.md:29-30` always invokes it on the Sonnet detection chain and classification
happens *after* planning (step 5) — no Opus re-invocation exists (unlike `/vuln`, which correctly
re-runs `vuln-research` on Opus). **Fix:** correct upgrade-planner's Model Routing to state it always runs on the detection chain.

**MAJOR (systematic) — mandatory `model-routing` Skill call missing from `allowed-tools`.**
`implement.md:4`, `vuln.md:4`, `upgrade.md:4` list `allowed-tools: Read Edit Write Bash Glob Grep Task
WebFetch LS` — no **`Skill`** — yet each mandates invoking the `model-routing` skill via the Skill tool
at its classification step. If allowed-tools is enforced, the mandatory step can't run. **Fix:** add `Skill` to allowed-tools of all routing-aware commands.

**MINOR — model-routing SSOT §5 teaches the wrong dispatch param (root of BUG-1).**
`references/model-routing/classification.md:217,225,228,230` shows `agent_type: "risk-planner" | …`
— wrong param name AND missing `dev-workflows:` prefix. **Fix:** `subagent_type: "dev-workflows:risk-planner" | …`.

**MINOR — `vuln-fixer` emits `status: BASELINE_FAILED` absent from its declared enum**
(`agents/vuln-fixer.md:40` vs `references/handoff/vuln-fixer.md:66`). **Fix:** add `BASELINE_FAILED` to the handoff enum.

**MINOR — `vuln.md:166` + `upgrade.md:147` invoke `impl-maintenance` without `Command run:`**,
so maintenance mislabels the run as `/implement` (contradicts the `command: /vuln|/upgrade` passed to
feedback-emission on the next line). **Fix:** pass `Command run: /vuln` (resp. `/upgrade`).

**MINOR — `vuln-fixer` step 1 has no branch for capture status `NO_TESTS`** (`agents/vuln-fixer.md:40`). **Fix:** handle `NO_TESTS` explicitly.

**MINOR (cosmetic) — implement.md phase-number inversion** ("Pre-Phase 2" precedes "Phase 1.7/1.8";
Phase 3B step 8 reuses "Phase 3.5"). Cross-refs are correct, so readability-only. **Fix:** renumber Pre-Phase 2 → Phase 1.6.

**Confirmed clean:** fallback ladders (§2/§2.1), 8-dimension review checklist order vs code-review,
verify-resume protocol across all files, frontmatter Opus pins, baseline hand-back invariant, all prefixed path refs resolve.

### 2C — VI / Spec Lifecycle
**0 BLOCKER, 0 MAJOR.** MINOR (consistency/drift only):
- `commands/specify.md:47` — dead pointer "(design §7)"; no such design doc §7 exists. **Fix:** delete or repoint (folder layout is fully inline anyway).
- `commands/create-ard.md:62` — VI-level `jira-reader` fallback is prose with **no `depth`/structured block**, but `jira-reader` hard-refuses without `depth`+`jira_key` (agents/jira-reader.md:33). **Fix:** use a formal Agent block (`depth: vi-plus-epics`/`full`, `jira_key: <VI>`) like siblings.
- `commands/create-ard.md:50` — `model_routing` comment omits `jira-reader` from the `detection_model` annotation though Phase 2 dispatches it. **Fix:** add it.
- `commands/ready.md:222` — dispatches `readiness-reviewer` with **no `model:`** while the other 4 authoring reviewers pass `model: <review_model — §2 Opus chain>`. Behavior identical (all frontmatter-pinned), convention diverges. **Fix:** harmonize.
- `agents/readiness-reviewer.md:54` + `references/workflow-states.md:46` — use "CONCERN", not in the declared severity schema `BLOCKER/MAJOR/MINOR/NIT`. **Fix:** replace with `MINOR`.
- `commands/idea.md:84-86` — Phase-2 carry-forward omits `source_refs`+`provenance` that `idea-reader` emits and the `sources:` frontmatter needs (reconstructable, low impact). **Fix:** add them.

**Confirmed clean:** specify.md→`specification-to-html.py` interface matches (positional `inputs`, writes `.html` alongside); all 5 reviewer I/O contracts + verdict enums; all 19 `${CLAUDE_PLUGIN_ROOT}` paths resolve; pre-lint heading blocks match format docs; branch prefixes (`vi/ard/spec/design`, ready never branches); **commit trailer identical across all 4 authoring commands** (Claude trailer — intentional & consistent); contiguous phase numbering.

### 2B — Docs / Jira Pipeline
**BLOCKER — `docs-style-checker` dispatches a sub-agent but lacks the `Task` tool.**
`agents/docs-style-checker.md:4` declares `tools: [Read, Glob, Grep, LS, Bash]` (no `Task`), yet
`:55-56` dispatches `subagent_type: "dt-style-guide:dt-style-checker"` as its complementary/fallback/
sole pass. In Claude Code an agent WITH an explicit tools list can't use undeclared tools → the
dispatch can't execute; for a no-primary-linter repo (dynatrace-docs case) the style gate silently
no-ops. **Fix:** add `Task` to the tools array. *(Same bug class as the port's task-gap — real in Claude too because this agent declares tools explicitly.)*

**MAJOR — `doc-writer` told to put the Jira key in the changelog, which its own gate BLOCKs.**
`agents/doc-writer.md:52` says append a changelog entry "naming the Jira key" — but `doc-planner`
("NEVER include a Jira key in the changelog entry"), `doc-reviewer` (flags a Jira key in changelog),
and `document.md` Phase 8.5 all forbid it. The writer would emit output its own review gate BLOCKs.
**Fix:** "append a dated customer-readable 1-line entry with **no** Jira key"; traceability lives in the commit message.

**MINOR:**
- `commands/document.md:32→40` — Phase 0 step numbering skips 2 (1→3); later prose assumes it. **Fix:** renumber 3-8 → 2-7.
- `commands/epics.md:336 vs :358` — sub-phase labels inverted: 6.2 (clarifications) physically precedes 6.1 (style) and runs "BEFORE the style check." **Fix:** swap labels.
- `references/handoff/release-notes-writer.md` — schema drift: Input omits `code_repos` (agent+command use it); `gaps[]` omits `jira_phrasing`/`source_phrasing`/`source_location` (emitted+consumed for the discrepancy table). **Fix:** add them.
- `agents/doc-fixer.md:9 vs docs-style-checker.md:96` — doc-fixer expects finding field `description`, but style-checker emits `message:`+`rule:` and reviewers emit prose `observation`/`Suggestion:`. No producer emits `description`. **Fix:** align on `message`.
- `agents/jira-reader.md` inline Output vs `references/handoff/jira-reader.md:56,71` — two "exact" schemas disagree (inline omits `linked_items[].not_found`, `pull_requests[].also_in`); same for diff-summarizer inline vs handoff. **Fix:** reconcile or drop unused fields.
- `commands/document.md:293,297,312` — dead "Increment 2/3" pointers (leftover incremental language); real logic is in Phase 5.9/6.3. **Fix:** repoint to concrete phases.
- `agents/doc-writer.md:56` — `image_policy: local` tells writer to copy binary screenshots, but its tools (`Read,Glob,Grep,LS,Write,Edit`) can't copy binaries. **Fix:** add `Bash`, or have the orchestrator do local image copies.

**Confirmed clean:** phase cross-refs resolve (doc-location-finder→5.5, doc-planner→5.7, doc-writer→6.3, doc-reviewer→7); reference-section citations (source-truth §3/§4.2/§7.4-7.6, multi-space-writing §5/§6, frontmatter-guidelines); handoff↔dispatch field parity for doc-planner/doc-writer/epic-writer/code-scanner; jira-reader `depth` values match all callers; all in-scope `${CLAUDE_PLUGIN_ROOT}` paths resolve.

### 2D — Reviewers + Shared References
**0 BLOCKER, 2 MAJOR.**
- **MAJOR — `references/handoff/jira-reader.md:62-71` `pull_requests[]` SSOT drifts both ways.** Lists a phantom `also_in` (no producer emits it) and **omits `branch_from`/`branch_to`** which the producer emits (`agents/jira-reader.md:150-151`) and which `diff-summarizer` **requires** (`handoff/diff-summarizer.md:14-15`; `document.md:329`). A reader trusting the SSOT builds a `pr_refs` payload missing the branch fields diff-summarizer needs. **Fix:** add `branch_from`/`branch_to`, delete `also_in`.
- **MAJOR — `impl-maintenance` `Command run` enum lists only 9 of the 12 invoking commands.** Both `references/handoff/impl-maintenance.md:18-20` and `agents/impl-maintenance.md:20-23` omit `/idea`, `/create-vi`, `/create-ard`, `/ready` (all four DO invoke it), contradicting `feedback-emission.md:5` ("all twelve workflow commands"). Those 4 callers get no valid `Command` slot. **Fix:** add the 4 commands to both enumerations.

**MINOR:**
- `agents/api-guideline-reviewer.md:13` — "never use a subset" contradicts the curated subset it then lists (12/18 + 2/6 files). **Fix:** reword to "load the files listed below" or expand to full dir.
- `agents/guideline-reviewer.md:64-74` — instructs `strato_*`/`sdk_get_doc` MCP calls but `tools:` (line 4) grants no MCP tools → dead guidance. **Fix:** grant the MCP tools or gate the section on MCP availability.
- `handoff/code-scanner.md` + `handoff/diff-summarizer.md` — agents' inline `## Output` are strict subsets of the handoff SSOTs they tell readers to trust (omit `prep:` block + several per-PR fields). **Fix:** sync inline schemas or defer to handoff.
- Bare path citations (inconsistent w/ prefixed norm): `cost-emission.md:21,114` (`scripts/session-cost.py`, `references/cost-prices.yaml`), `handoff/release-notes-writer.md:6` (also mis-points to `agents/jira-reader.md` instead of `handoff/jira-reader.md`), `pre-lint.md:50` (`agents/epic-writer.md`). **Fix:** prefix with `${CLAUDE_PLUGIN_ROOT}/`.
- `handoff/jira-reader.md:92` — `NOT_FOUND` desc only mentions `<vault_path>/jira-products/…` but Form-1 resolves via `jira_export_root`. **Fix:** cover both.

**Confirmed clean:** version 2.30.0 consistent (plugin.json / marketplace.json / CHANGELOG); count claims accurate (20 commands, 30 agents all mapped to real files, 4 hooks + scripts exist); all 49 `${CLAUDE_PLUGIN_ROOT}` citations resolve; reviewer command↔agent pairs; utility→feedback-emission entry points; §-anchors resolve; `impl-maintenance` output shape matches its handoff; no dangling `branch-naming.md`.

---

## §3 — Executive tally

| Area | BLOCKER | MAJOR | MINOR |
|------|:---:|:---:|:---:|
| §1 Mechanical | 0* | 1 (`agent_type`→`subagent_type`, ×7) | 2 |
| 2A Code orchestrators | 1 | 3 | 5 |
| 2B Docs / Jira | 1 | 1 | 7 |
| 2C VI lifecycle | 0 | 0 | 6 |
| 2D Reviewers / shared | 0 | 2 | 6 |
| **Total** | **2** | **7** | **26** |

\* BUG-1 is filed MAJOR mechanically but is functionally BLOCKER-level if Claude Code rejects the unknown `agent_type` param.

### Cross-cutting themes (fix once, benefits many)
1. **Missing `Task` in `tools:`** — `docs-style-checker` (BLOCKER, 2B) can't dispatch `dt-style-checker`; the 4 no-tools agents (BUG-2) hide the same intent. Every agent that dispatches a sub-agent must declare `Task`.
2. **Wrong dispatch param `agent_type:`** — BUG-1 (vuln/upgrade, ×7) + its source template (classification.md §5, MINOR 2A). Fix the SSOT §5 example AND the 7 call sites.
3. **Missing `Skill` in `allowed-tools`** — all 3 code commands (MAJOR 2A) can't load the mandatory `model-routing` skill; verify every routing-aware command.
4. **Inline agent `## Output` vs `references/handoff/*` SSOT drift** — recurs in jira-reader (MAJOR 2D), release-notes-writer (2B), code-scanner + diff-summarizer (2D), test-baseliner (BLOCKER 2A), vuln-fixer (2A). Systematic: pick the handoff doc as SSOT and regenerate every inline block from it.
5. **Residual bare `references/…` citations** (BUG-3 + several MINOR) — finish the prefix normalization you started.

**Note:** the four audits were scoped port-vs-nothing (pure internal Claude-native review). All model
IDs, cost/statusline features, `${CLAUDE_PLUGIN_ROOT}`, and `subagent_type` are correct-for-Claude and
were explicitly excluded from flagging.

---

## §4 — Residual issues found during the Copilot port (2026-07-14)

While porting the v2.31.0 fixes into the Copilot marketplace, one residual
inconsistency was found in the **verified Claude source** that the v2.31.0 fix
batch missed (logged here per convention — NOT fixed in Claude during the port):

- **`commands/epics.md:332` (Claude) — stale cross-ref after the 6.1/6.2 label swap.**
  The v2.31.0 fix swapped the sub-phase labels so clarifications = Phase 6.1 and
  Dynatrace style check = Phase 6.2. But the data-recording line still reads
  "record `clarifications_needed[]` for **Phases 6.2 and 7**". `clarifications_needed[]`
  is consumed by the clarification gate (now **6.1**, `epics.md:340`) and the review
  (Phase 7, `:349`) — never by the style check (6.2). It should read
  "**Phases 6.1 and 7**". Fixed correctly in the Copilot port
  (`skills/epics/SKILL.md:334`); the Claude line remains to be fixed in a Claude session.

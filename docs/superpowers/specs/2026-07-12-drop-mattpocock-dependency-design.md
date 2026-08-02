---
tags:
  - tasks-exclude
---

# Drop the mattpocock-skills dependency — design (line-87)

**Date:** 2026-07-12
**Task:** AI-First.md line 87 — drop the (even optional) dependency on Matt Pocock's plugin now that the grilling technique is embedded in dev-workflows.
**Effort:** dev-workflows **v2.25.0**
**Predecessor:** line-85 borrow analysis (`research/2026-07-12-bmad-speckit-superpowers-grillme-borrow-analysis.md`) — headline finding: grilling is at parity-or-better, so dropping the dependency is safe.

## Goal

Remove every *operational* dependency of dev-workflows on `mattpocock-skills`, so the plugin is fully self-contained for grilling. Keep honest *attribution* ("adapted from mattpocock grill-me/grilling").

## Context — what "dependency" means today

dev-workflows has **no hard dependency**: `plugin.json` carries no dependency field, and `references/dependencies.md` declares the plugin self-contained. The grilling *technique* is embedded in `references/grilling-technique.md`; the five authoring commands (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`) carry it inline with zero runtime dependency.

**One optional dependency remains**, concentrated in:

1. **`commands/prompt-grill-me.md`** — its Phase 2/Phase 4 runtime-resolve Matt's `/grilling`, falling back to `superpowers:brainstorming`.
2. **`references/dependencies.md`** — lists `mattpocock-skills` as a *Recommended companion*.
3. Supporting mentions in `README.md`, `references/feedback-emission.md`, and `references/grilling-technique.md`.

Matt's repo (pulled 2026-07-10, latest `391a270`) shows recent activity (`setup-deep-modules`, `prototype`, `to-tickets`, `wayfinder`) but **no grilling divergence** that affects us — the only grilling-touching commits (`e5932a7` self-grilling guard, `0e9a072` confirmation gate) are older and already logged on the polish backlog. Dropping the dependency stays safe.

## Decision

Retarget `/prompt-grill-me` to a **self-contained inline grill** (chosen over "hand off to superpowers" and "delist-only"). The command performs the interrogation itself following `references/grilling-technique.md` — no external-skill handoff at all, matching how the other five commands already embed the technique. This drops **both** Matt and the superpowers fallback from `/prompt-grill-me`'s path.

**Attribution vs. dependency line:** keep every "adapted from mattpocock grill-me/grilling" *credit*; remove every *operational* "install / invoke Matt's skill" instruction.

## Change surface

### Behavior (1 command)

- **`commands/prompt-grill-me.md`**
  - Frontmatter `description`: drop the "hand off to /grilling (mattpocock-skills) … falling back to superpowers:brainstorming" clause; restate as an inline relentless-interrogation-of-the-fix command with no hard dependency.
  - Intro: drop the `/grilling`-is-the-invocable-target / `disable-model-invocation` / mattpocock-not-a-declared-dependency paragraph.
  - **Phase 2 (Resolve the handoff target):** replaced by a step that sets up the inline grill — cite `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md`, depth **bounded (≤5)**, stage = interrogate the correction. No availability check, no fallback notice.
  - **Phase 4 (Hand off):** replaced by "Grill the fix (inline)" — perform the interrogation directly per the cited technique. Preserve the closing guarantees verbatim in spirit: **never commits; never writes into a docs/code repo or the cwd.**
  - **Phase 3 (Persist the corrective triple):** unchanged except the Resolution value — it no longer records "Handed off to <target>"; it records that the fix was grilled inline (e.g. `Grilled the fix inline`). `emit-prompt`, `origin: prompt`, the §1 vocab/category/impact/jira_key/source fields, and the specs-first write ladder are unchanged.

### Documentation / references (drop dependency, keep attribution)

- **`references/dependencies.md`** — remove the `mattpocock-skills` row from *Recommended companions*. Trim the `superpowers` row: it is no longer a `/prompt-grill-me` fallback; keep it for `/prompt-brainstorm`. (`dt-style-guide` row unchanged; external-tooling and siblings sections unchanged.)
- **`README.md`**
  - Lines 54–57: rewrite the `/prompt-grill-me` bullet — "same capture, then grill the fix inline per the embedded technique"; drop the mattpocock-skills optional-dependency sentence.
  - Line ~301: drop `mattpocock-skills` `/grilling` from the "Recommended companions (…)" parenthetical; keep `superpowers`, `dt-style-guide`.
- **`references/feedback-emission.md`** — lines 16–19: the "Self-contained — no hard cross-plugin dependency" note keeps `/prompt-brainstorm` uses `superpowers:brainstorming`; drop the `/prompt-grill-me` runtime-resolves-`/grilling`/fallback sentence (state `/prompt-grill-me` grills inline via the embedded technique). §207 `emit-prompt` header (`/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`) unchanged.
- **`references/grilling-technique.md`** — remove the lines-21–22 "If `mattpocock-skills` `/grilling` is installed the user may invoke it directly …; it is not a runtime dependency" operational block. **Keep** the line-4 "technique adapted from mattpocock grill-me/grilling" credit.

### Attribution left intentionally untouched

- **`references/design-format.md:88–91`** — the Provenance note ("adapted from mattpocock grill-me/grilling, so `/design` has no runtime plugin dependency") is attribution that *supports* the no-dependency story. Leave as-is.
- **`CHANGELOG.md`** historical entries referencing grill-me — history, never rewritten.

### Manifests

- **`plugin.json`** + root **`marketplace.json`** (dev-workflows entry) — version `2.24.0` → `2.25.0`, lock-step.
- **No count-string change.** Still `Twenty slash commands` / `Thirty reusable subagents` — `/prompt-grill-me` is retargeted, not removed; no agent added/removed; the description never named Matt. Command list in the description already contains `/prompt-grill-me` and stays.
- **`CHANGELOG.md`** — new `## [2.25.0] — 2026-07-12` entry describing the dependency drop + `/prompt-grill-me` retarget.

## Non-goals

- Not removing or renaming `/prompt-grill-me` (kept, retargeted).
- Not touching `superpowers` as a companion for `/prompt-brainstorm` (stays).
- Not touching `dt-style-guide` or the `jira-workitem-import` external tool.
- Not scrubbing "adapted from mattpocock" attribution/credit.
- Not editing the embedded grilling technique's mechanics.
- No change to `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design` (already zero-dependency).

## Verification (structural — no test framework)

- **grep sweep:** after the change, `grep -rin -E "grill-me|pocock|mattpocock" commands/ references/ README.md` returns only (a) `commands/prompt-grill-me.md` filename + self-references, (b) the three intentional *attribution* credits (`grilling-technique.md` line 4, `design-format.md` provenance), and (c) `CHANGELOG.md` history — **zero operational "install/invoke Matt" instructions and zero "runtime-resolve /grilling"**.
- **manifests parse:** `python3 -c "import json,sys; json.load(open(f))"` on `plugin.json` and `marketplace.json`; both report `2.25.0`.
- **counts unchanged:** `ls commands/*.md | wc -l` = 20; agent count = 30; description count-strings byte-identical to pre-change ("Twenty…", "Thirty…").
- **lock-step:** `plugin.json` version == the dev-workflows `marketplace.json` entry version == `2.25.0`; the two description strings byte-identical across both manifests.
- **siblings byte-identical:** `dt-style-guide` 0.2.2 and `obsidian-llm-wiki` 0.3.1 — `git diff --stat` shows 0 lines.
- **no collateral:** `/vuln`, `/upgrade`, `jira-reader`, and all other commands/agents — 0-line diff.
- **`/prompt-grill-me` self-consistency:** the command no longer contains "handoff", "/grilling", "mattpocock", or "superpowers"; it cites `references/grilling-technique.md`; the "never commits / never writes to a repo or cwd" guarantee is present.

## Risks

- **Low.** All edits are markdown; no logic, no runtime code. The one behavioral shift (`/prompt-grill-me` grills inline instead of delegating) is strictly *more* self-contained and cannot fail for missing-companion reasons that the old fallback existed to cover.
- **Attribution-scrub ambiguity** resolved by the explicit decision above (keep credit, drop operational instructions).

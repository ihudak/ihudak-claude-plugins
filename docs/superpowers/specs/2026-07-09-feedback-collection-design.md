---
tags: tasks-exclude
---

# Session Feedback Collection — Design

**Date:** 2026-07-09
**Status:** Approved (design) — awaiting spec review
**Target:** dev-workflows plugin (`/workspace/ihudak-claude-plugins/plugins/dev-workflows/`), release **v2.9.0**
**Follows:** B4 (follow-up task & journal emission, v2.8.0) — shares the `<VI-dir>/dev-workflows/` per-VI artifact area

---

## 1. Goal

Capture friction and improvement signals about the **dev-workflows plugin itself**
from engineers' AI sessions, persist them per-VI into the **specs repo**, and make
them aggregatable so the plugin **maintainer** can review feedback across all
engineers (with Claude Code) and plan plugin improvements and fixes.

Today this signal is either lost or ephemeral: the `impl-maintenance` agent already
produces a per-session "Session Learnings" report, but it is suggest-only and lives
only in the run's Final Report — it evaporates when the session ends and never
reaches a central place. And the highest-value signal — friction that happens in
free-form conversation, outside any command — is captured nowhere at all.

## 2. Motivating example

This whole improvements effort began *after* the PRODUCT-14902 (ActiveGate autoupdate)
documentation run. The user asked "what went wrong?" and collected improvement items
from memory. The canonical case: `/document` produced one page covering **both** SaaS
and Managed; the SaaS half then got pushback in review because the two products differ
there. The outcome was a plugin improvement — an optional `saas|managed` parameter was
added to `/document` to scope a run to one product.

That is exactly the feedback this feature must capture automatically: a real,
actionable friction with a command, surfaced through conversation and human judgment,
that should outlive the session and reach the maintainer. As the plugin is adopted by
other engineers, their AI agents must feed the same signal back.

## 3. Architecture decision — reuse impl-maintenance, self-contained

**Reuse, don't reinvent, the analysis.** The automatic capture rides the existing
`impl-maintenance` agent (already wired as "Agent 4 — Session maintenance" in five
commands). The new work is to **project the plugin-facing slice** of that agent's
report and **persist** it — not to build a second analyzer. `impl-maintenance`'s agent
definition is **untouched**; the caller passes its report to the emitter, which
extracts the plugin-facing sections.

**Self-contained — no hard cross-plugin dependency.** The `/prompt-grill-me` handoff
resolves `/grilling` (mattpocock-skills) at runtime and falls back to
`superpowers:brainstorming` if it is not installed. `/prompt-brainstorm` uses
`superpowers:brainstorming` directly. Neither is a declared install-time dependency —
the commands work for every engineer regardless of what else they have installed. This
mirrors the B4 self-contained decision: marketplace plugins install independently.

**Rejected alternatives:**

- A brand-new lessons-learned analyzer agent — `impl-maintenance` already does the
  reasoning; a second analyzer would duplicate it and drift.
- A hard dependency on mattpocock-skills for `/prompt-grill-me` — would force a
  "requires mattpocock-skills" caveat into the docs for a command that must degrade
  gracefully instead.
- A curation/approval gate on automatic capture — rejected in favor of silent,
  high-recall capture (see §10): the non-expert engineer cannot triage well, so
  curation belongs to the maintainer, centrally, at analysis time.

## 4. Components

### 4.1 New reference — `references/feedback-emission.md`

Single source of truth (parallels B4's `references/followup-emission.md`). Contents:

- **Entry format** (§7) — file frontmatter + per-entry YAML metadata + prose.
- **Persistence ladder** (§6) — specs-first, never cwd.
- **Dedup / append + attribution** (§8).
- **Plugin-facing predicate** (§9) — what persists vs. what stays in-session.
- **Caller contract** — how automatic callers and the `/*` commands invoke the emitter.

### 4.2 Capture surfaces

- **Automatic** — the maintenance phase of all 8 commands (§5.1, §11).
- **`/feedback`** — universal manual note (§5.2).
- **`/prompt`**, **`/prompt-brainstorm`**, **`/prompt-grill-me`** — corrective-interaction
  capture + act/handoff (§5.3).

All surfaces write to the same `<KEY>-feedback.md` through `feedback-emission.md`.

## 5. Capture surfaces (detail)

### 5.1 Automatic (rides the end-of-run maintenance phase)

`impl-maintenance` already runs in `/implement` (Phase 4), `/document` (Phase 8 Mode A
/ Phase 4 Mode B), `/epics` (Phase 8), `/vuln`, and `/upgrade`. Its report already
separates plugin-facing suggestions (**Command workflow improvements**, **New agents /
skills**, plugin **Reference docs** under `${CLAUDE_PLUGIN_ROOT}`) from target-project
advice (project `CLAUDE.md` rules, target-repo hooks). The emitter renders the
plugin-facing slice **plus the Key observations** that triggered it into feedback
entries. `origin: auto`. Written **silently** and listed in the Final Report.

`/release-notes`, `/specify`, and `/design` do not run maintenance today; each gains a
**lightweight terminal maintenance phase** that invokes `impl-maintenance` (pinned to
the Sonnet detection chain, matching the existing five) and then persists. This makes
automatic capture uniform across all 8 commands (decision B).

### 5.2 `/feedback <text>` — universal manual note

Run any time, tied to no command. The user authors the `Friction` and
`Suggested improvement` prose; the command fills the YAML block (command named or
"n/a", `category` inferred and confirmed, `author`, `plugin_version`). `origin: manual`.

### 5.3 `/prompt` family — corrective-interaction capture

For when the user is unhappy with what a command (`/specify`, `/design`, `/implement`,
`/document`, …) produced and wants to correct it directly. These capture the
**corrective triple**:

1. **Friction** — what the command produced that was wrong.
2. **User prompt** — the user's corrective request, **verbatim**.
3. **Resolution** — what the AI actually did.

Common behavior: infer the target command from recent context (ask only if genuinely
ambiguous); `origin: prompt`; write silently; then perform the action / handoff.

- **`/prompt <text>`** — log, then act on the request directly (quick correction).
- **`/prompt-brainstorm <text>`** — log, then hand off to `superpowers:brainstorming`.
- **`/prompt-grill-me <text>`** — log, then runtime-resolve `/grilling` (mattpocock-skills).
  If mattpocock-skills is not installed, fall back to `superpowers:brainstorming` with a
  notice. (`grill-me` itself is `disable-model-invocation`; the invocable target is
  `/grilling`, which has no such flag.)

## 6. Persistence ladder (specs-first; never cwd)

**Inverts B4.** B4 wrote to the vault first because tasks/notes are the engineer's
working area; here `$SPECS_PATH` is primary because the entire purpose is central
aggregation — feedback only reaches the maintainer if it lands in the committed,
pushed specs repo.

1. **`$SPECS_PATH` resolvable + writable + VI dir exists**
   (`$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…`) →
   `<VI-dir>/dev-workflows/<KEY>-feedback.md`. *[primary — the whole point]*
2. **`$SPECS_PATH` writable but no VI dir matched** (no `jira_key` / no matching spec
   dir) → `$SPECS_PATH/dev-workflows-feedback/<KEY-or-date>.md` at the repo root. Still
   committed & aggregated; notice: "unfiled — move under the VI dir if it belongs to one."
3. **No `$SPECS_PATH` (unset / missing / read-only), vault writable**
   (`$VAULT_PATH` set **and** `$VAULT_PATH/.obsidian/` is a directory **and** writable)
   → `$VAULT_PATH/dev-workflows/feedback/<KEY>-feedback.md`, with a **loud notice**:
   `⚠ $SPECS_PATH unavailable — saved to your vault; it will NOT auto-aggregate to the
   maintainer. Set $SPECS_PATH and commit, or forward manually.`
4. **`source = directory`** (imported Jira dir, no specs/vault) → beside the imported
   directory, where `/epics` + `/release-notes` already drop no-vault output.
5. **Nothing resolvable** → **report-only**: keep the feedback in the run's final
   output + emit the notice. **Never write to the current working directory.**

Resolution is **deterministic** — no interactive vault-path prompt (consistent with
silent capture, §10). In every non-primary tier the feedback also stays in the Final
Report (zero loss) and the run never fails. A write that fails mid-write (read-only
mount / permission) drops to the next tier with the same notice.

## 7. Entry format (machine-friendly hybrid)

Optimized for a future Claude Code session to aggregate across many engineers and VIs:
deterministic YAML fields for filtering/clustering, prose for the human judgment.

File-level frontmatter (once, on creation):

```yaml
---
type: dev-workflows-feedback
vi: PRODUCT-14902
slug: env-ag-update-window
---
```

Per entry (appended):

````markdown
## 2026-07-09 — /document — missing-capability

```yaml
id: PRODUCT-14902-document-saas-managed-split
date: 2026-07-09
command: /document           # controlled: exact command name, or n/a
plugin_version: 2.9.0
origin: auto                 # auto | manual | prompt
author: ivan.gudak@dynatrace.com
category: missing-capability # controlled, extensible, reuse-first
impact: friction             # blocker | friction | polish
```

**Friction:** One page covered both SaaS and Managed; the SaaS half got pushed
back in review because the two products differ here.

**Suggested improvement:** Add an optional `saas|managed` parameter to `/document`
so the run scopes to one product.
````

- `origin: prompt` entries add two more prose blocks: **User prompt** (verbatim) and
  **Resolution** (what the AI did).
- **`category`** controlled vocab, extensible, reuse-first (like the B4 tag rule):
  `missing-capability`, `wrong-output`, `ambiguous-prompt`, `missing-reference-doc`,
  `model-routing`, `manual-workaround`, `false-positive`, `docs-ux`, `other`. Reuse an
  existing category when it fits so clusters don't fragment.
- `impact`: `blocker | friction | polish`.

## 8. Dedup / append + attribution

- **Append-only.** Never modify or delete existing entries. Entries appended
  **chronologically** (newest at the end) for clean git diffs.
- Before appending an **auto** entry, read existing `id:` values and **skip** any that
  already exist (reported `SKIP — already logged`). Stable
  `id = <KEY>-<command>-<short-slug>`, so re-running a pipeline never double-logs.
- **Manual** (`/feedback`) and **prompt** (`/prompt*`) entries are intentional and are
  never silently skipped; on an `id` collision, append a numeric suffix and warn if one
  looks near-identical.
- File created from the frontmatter + header template on first write.
- **Attribution:** `author` from `git config user.email` in the specs repo (best-effort;
  `unknown` if unset) — the *commit* author gives a second, authoritative layer once the
  engineer commits and pushes the specs. `plugin_version` read from `plugin.json` at run
  time.

## 9. Plugin-facing predicate — what persists

Persist **only** signals about the dev-workflows plugin itself:

- Command workflow improvements (a command should behave differently — the
  `saas|managed` case).
- New agents / skills the plugin should offer.
- Gaps in the plugin's own reference docs (`${CLAUDE_PLUGIN_ROOT}/references/**`).
- Corrective interactions captured by `/prompt*` (any command output the user had to fix).

**Do not** persist target-project tooling advice — project `CLAUDE.md` rules, target-repo
hooks, and other repo-specific suggestions stay in `impl-maintenance`'s in-session report,
not the feedback file. That advice is for the engineer's current repo, not the plugin
maintainer.

## 10. Interaction model — silent, high-recall

**No curation/approval gate on capture** (decision B). Capture is high-recall and
zero-friction; curation is the maintainer's job, centrally, at analysis time. A
non-expert engineer asked to approve/select/edit would rubber-stamp or drop the exact
signal the maintainer needs.

- **Automatic** entries are written silently and listed in the Final Report (visibility
  without a gate). A routine session with no plugin-facing signal writes nothing — no
  empty entry, byte-identical to today's report-only behavior.
- **`/feedback`** and **`/prompt*`** are user-invoked, so invocation *is* the intent;
  they write silently and surface the resulting path (and any degradation notice) in the
  command output.

## 11. Command wiring

- **Automatic persist** attaches inside the maintenance phase of each command, after
  `impl-maintenance`'s report is available:
  - Already have the phase: `/implement`, `/document` (Mode A + Mode B), `/epics`,
    `/vuln`, `/upgrade` — add the persist step.
  - Gain a lightweight terminal maintenance phase (invoke `impl-maintenance` on the
    Sonnet detection chain, then persist): `/release-notes`, `/specify`, `/design`.
- **New commands:** `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`
  (each calls `references/feedback-emission.md`).
- **Untouched:** the `impl-maintenance` agent definition, `jira-reader`, `format-refs`,
  all reviewers, and sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1).

## 12. Release surfaces

- `plugin.json` version → **2.9.0**; `.claude-plugin/marketplace.json` dev-workflows
  entry → 2.9.0 (lock-step; siblings 0.2.2 / 0.3.1 untouched). The dev-workflows
  **description** updates for the 4 new commands (Eleven → Fifteen slash commands; add
  `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`).
- `CHANGELOG.md` — prepend a `## [2.9.0] — 2026-07-09` entry.
- `README.md` — document the feedback subsystem, the 4 new commands, the optional
  grill-me dependency, and graceful degradation.
- Additive only. Commit trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Never
  `git add -A`.

## 13. Relationship to B4 and impl-maintenance

- **B4 (`followup-emission.md`)** captures the *engineer's own* follow-up actions
  (contact owners, upload screenshots, paste into Jira) → **vault-first**, audience =
  the engineer. **This feature** captures *plugin* friction → **specs-first**, audience
  = the maintainer. Both share the `<VI-dir>/dev-workflows/` home. **No dedup between
  them** — different purpose, different audience.
- **`impl-maintenance`** keeps producing its full in-session report (including
  target-project advice). This feature reuses its analysis and persists only the
  plugin-facing slice; the agent itself is not modified.

## 14. Non-goals

- No hard dependency on mattpocock-skills or superpowers (runtime-resolve + fallback).
- No curation/approval gate on capture (silent, high-recall).
- No dedup against B4 follow-ups.
- No modification of existing feedback entries (append-only).
- No persisting of target-project tooling advice (§9).
- No changes to the `impl-maintenance` agent core, `jira-reader`, reviewers, or siblings.

## 15. Resolved decisions (from brainstorming)

- **Capture model** — both automatic + explicit (§5). Approved.
- **Automatic scope** — all 8 commands; the 3 maintenance-less commands gain a
  lightweight phase (decision B, §5.1, §11). Approved.
- **Interaction** — silent, high-recall capture; no curation gate; curation is central
  (decision B, §10). Approved.
- **Fallback** — specs-first ladder with a vault fallback tier and a loud
  "won't auto-aggregate" notice; never cwd (§6). Approved.
- **Entry format** — machine-friendly hybrid: frontmatter + per-entry YAML + prose;
  controlled, extensible `category` (§7). Approved.
- **`/prompt` family** — capture the corrective triple; `/prompt` acts directly,
  `/prompt-brainstorm` → brainstorming, `/prompt-grill-me` → `/grilling` with graceful
  fallback (§5.3). Approved.
- **`/prompt-grill-me`** — optional dependency; runtime-resolve `/grilling`; fallback to
  `superpowers:brainstorming` if mattpocock-skills is absent (§3, §5.3). Approved.

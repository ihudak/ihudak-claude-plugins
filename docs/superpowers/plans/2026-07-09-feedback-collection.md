---
tags:
  - tasks-exclude
---

# Session Feedback Collection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the dev-workflows plugin a **Session Feedback Collection** subsystem that captures friction/improvement signals about the plugin **itself** and persists them per-VI into the **specs repo** for the maintainer to aggregate — via a new self-contained `references/feedback-emission.md` (single source of truth), automatic capture in all eight workflow commands' maintenance phases, and four new commands (`/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`) — shipped as **v2.9.0**.

**Architecture:** All edited/created files are Markdown command/reference definitions (prose + phase headings) plus two JSON manifests. Changes are **additive**. T1 creates the single source of truth (`references/feedback-emission.md`): entry format, the **specs-first** persistence ladder, append-only dedup/attribution, the plugin-facing predicate, and a three-entry-point **caller contract** (`emit-auto`, `emit-manual`, `emit-prompt`). T2/T3 create the four new commands, each citing T1. T4 wires the **automatic** persist step into the five commands that already run `impl-maintenance` (`/implement`, `/document` ×2, `/epics`, `/vuln`, `/upgrade`), projecting the plugin-facing slice of that agent's report — the `impl-maintenance` agent file is **untouched**; projection happens in the caller. T5 gives the three maintenance-less commands (`/release-notes`, `/specify`, `/design`) a new lightweight terminal maintenance phase that invokes `impl-maintenance` on the Sonnet detection chain, then persists. T6 bumps the version surfaces and docs. The subsystem reuses `impl-maintenance`'s analysis (no second analyzer) and has **no hard cross-plugin dependency** (`/prompt-grill-me` runtime-resolves `/grilling` with a `superpowers:brainstorming` fallback). It mirrors B4's `references/followup-emission.md` shape but **inverts** its ladder (specs-first, not vault-first) because the audience is the maintainer, not the engineer; the two share the `<VI-dir>/dev-workflows/` per-VI area with **no dedup between them**.

**Tech Stack:** Markdown (`.md`) command/reference files + two JSON manifests (`plugin.json`, `marketplace.json`). **No test framework, no husky/prettier hook** — every task's verification is **structural**: `grep` for added anchors, `python3 -c "import json; json.load(...)"` for the JSON manifests, and a byte-diff (`git diff` / `git diff --stat`) review confirming only the intended lines changed.

## Global Constraints

Every task's requirements implicitly include this section.

- **Feature branch:** `ivgu/NOISSUE-feedback-collection`, cut from `main` (`b0fd201`). Never implement on `main`.
- **Additive only** — do NOT alter existing phase behavior, the `impl-maintenance` agent core, `jira-reader`, `format-refs`, the reviewers, or sibling plugins. With no plugin-facing signal and no writable specs/vault target, every command behaves byte-identically to today (feedback also always remains in the run's final output — zero loss) and no capture phase ever fails the run.
- **No test framework — structural verification only** (no tests exist; NEVER write "run pytest").
- **Commit trailer, EXACTLY:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **NEVER `git add -A`** — stage only the files named in the task. Commit/push only per the executing skill's checkpoint policy; the push/merge decision is the finishing step the user chooses.
- **Version lock-step:** `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of repo-root `.claude-plugin/marketplace.json` are BOTH `2.9.0`.
- **Siblings untouched:** `dt-style-guide` (`0.2.2`) and `obsidian-llm-wiki` (`0.3.1`) in `marketplace.json` — their versions AND description strings are unchanged.
- **`impl-maintenance` agent / `jira-reader` / reviewers / `format-refs` untouched** — the plugin-facing projection happens in the *caller*, never by editing the agent.
- **Recompute all counts from the repo, never assert from memory** — this effort adds **four** new commands (Eleven → Fifteen in the plugin description) but **no** new subagent (stays 26) and **no** new hook (stays 4). A new *reference* file is not a command or subagent. Verify each count against the repo before writing it.
- **Anchor by quoted text, not line number** — line numbers here are from a 2026-07-09 read and are approximate. After each edit, read the `git diff` and confirm no unintended reflow.
- **`plugin.json` `keywords` array is intentionally NOT modified** (additive/minimal; not required by the design).

### Shared vocabulary (used across tasks)

- **Emitter** — the logic in `references/feedback-emission.md` (T1): entry format → plugin-facing predicate → specs-first target resolution → dedup/append → write.
- **Caller-contract entry points** — the three named ways to invoke the emitter, defined in T1 §6 and used verbatim by later tasks:
  - **`emit-auto`** — automatic callers (the eight commands' maintenance phases). Projects the plugin-facing slice of an `impl-maintenance` report; `origin: auto`; silent; deduped by stable `id`.
  - **`emit-manual`** — `/feedback`; user-authored note; `origin: manual`; never silently skipped.
  - **`emit-prompt`** — `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`; the corrective triple; `origin: prompt`; never silently skipped.
- **Plugin-facing slice** — an `impl-maintenance` report's **Command workflow improvements** + **New agents / skills** + **Reference docs** (paths under `${CLAUDE_PLUGIN_ROOT}`) sections, plus the **Key observations** that triggered them. Its **CLAUDE.md rules** and **Hooks** sections (target-project advice) are discarded.
- **Persistence ladder (specs-first)** — `$SPECS_PATH` VI dir → `$SPECS_PATH/dev-workflows-feedback/` → writable vault (loud "won't auto-aggregate" notice) → beside an imported Jira directory → report-only. **Never** the current working directory.

## File Structure

| File | Task | Responsibility |
|------|------|----------------|
| `plugins/dev-workflows/references/feedback-emission.md` | T1 (create) | Single source of truth: entry format, specs-first persistence ladder, append-only dedup/attribution, plugin-facing predicate, and the `emit-auto` / `emit-manual` / `emit-prompt` caller contract. Self-contained; mirrors B4's `followup-emission.md` shape, inverts its ladder, reuses `impl-maintenance` (agent untouched). |
| `plugins/dev-workflows/commands/feedback.md` | T2 (create) | `/feedback <text>` — universal manual note (`origin: manual`), tied to no command. Calls `emit-manual`. |
| `plugins/dev-workflows/commands/prompt.md` | T3 (create) | `/prompt <text>` — corrective triple (`origin: prompt`), then acts directly. Calls `emit-prompt`. |
| `plugins/dev-workflows/commands/prompt-brainstorm.md` | T3 (create) | `/prompt-brainstorm <text>` — corrective triple, then hands off to `superpowers:brainstorming`. Calls `emit-prompt`. |
| `plugins/dev-workflows/commands/prompt-grill-me.md` | T3 (create) | `/prompt-grill-me <text>` — corrective triple, then runtime-resolves `/grilling` (mattpocock-skills) with a `superpowers:brainstorming` fallback. No hard dependency. Calls `emit-prompt`. |
| `plugins/dev-workflows/commands/implement.md` | T4 (modify) | Add the `emit-auto` persist step after Phase 4 Agent 4 (before `## Phase 5 — Final Report`). |
| `plugins/dev-workflows/commands/document.md` | T4 (modify ×2) | Add the `emit-auto` persist step after Mode A Phase 8 Agent 4 (before `## Phase 8.5`) AND after Mode B Phase 4 Agent 4 (before `## Phase 5 — Final Report`). |
| `plugins/dev-workflows/commands/epics.md` | T4 (modify) | Add the `emit-auto` persist step after Phase 8 Agent 4 (before `## Phase 9 — Final Report`). |
| `plugins/dev-workflows/commands/vuln.md` | T4 (modify) | Add the `emit-auto` persist step after the Step 4 `impl-maintenance` invocation (before `## Handling Test Failures`). |
| `plugins/dev-workflows/commands/upgrade.md` | T4 (modify) | Add the `emit-auto` persist step as Phase 2 step 8 after the post-batch `impl-maintenance` (before `## Version Resolution`). |
| `plugins/dev-workflows/commands/release-notes.md` | T5 (modify) | Add new terminal **Phase 10 — Session maintenance & feedback** before `## Invariants (always enforced)`. |
| `plugins/dev-workflows/commands/specify.md` | T5 (modify) | Add new terminal **Phase 8 — Session maintenance & feedback** before `## Final report` (no `## Invariants` block exists). |
| `plugins/dev-workflows/commands/design.md` | T5 (modify) | Add new terminal **Phase 8 — Session maintenance & feedback** before `## Final report` (no `## Invariants` block exists). |
| `plugins/dev-workflows/.claude-plugin/plugin.json` | T6 (modify) | Version `2.8.0` → `2.9.0`; description Eleven → Fifteen slash commands (+ the four new). |
| `.claude-plugin/marketplace.json` | T6 (modify) | `dev-workflows` entry version `2.8.0` → `2.9.0` + the same description update. Siblings untouched. |
| `plugins/dev-workflows/CHANGELOG.md` | T6 (modify) | Prepend `## [2.9.0] — 2026-07-09` (`### Added`). |
| `plugins/dev-workflows/README.md` | T6 (modify) | New `## Session feedback` section + a Reference-docs bullet. Root README untouched. |

T1 lands first (everything cites it). T2–T3 create the new commands, T4–T5 wire capture; all cite T1 and are mutually independent. T6 (versions/CHANGELOG/README) runs last, after the commands exist so counts are accurate.

**Computed phase numbers (recomputed from the 2026-07-09 repo read):**
- `release-notes.md` — current MAX phase is **Phase 9** (Emit follow-up tasks); it HAS `## Invariants (always enforced)`. New phase = **Phase 10**, inserted before `## Invariants`.
- `specify.md` — current MAX phase is **Phase 7** (Handoff); it has **NO `## Invariants` block** (ends with `## Final report`). New phase = **Phase 8**, inserted before `## Final report`.
- `design.md` — current MAX phase is **Phase 7** (Handoff); it has **NO `## Invariants` block** (ends with `## Final report`). New phase = **Phase 8**, inserted before `## Final report`.

---

### Task 1: Create `references/feedback-emission.md`

**Files:**
- Create: `plugins/dev-workflows/references/feedback-emission.md`

**Interfaces:**
- Consumes: nothing from earlier tasks. At runtime, reads `$SPECS_PATH`, `$VAULT_PATH`, the run's `jira_key` / `source`, `git config user.email` (in the specs repo), and `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (`version`).
- Produces: the reference cited by T2–T5 at `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`. **Caller-contract entry points that later tasks invoke by name:** `emit-auto` (T4, T5), `emit-manual` (T2), `emit-prompt` (T3). Section numbers callers rely on: §1 entry format, §2 persistence ladder, §3 dedup/attribution, §4 plugin-facing predicate, §5 interaction model, §6 caller contract.

- [ ] **Step 1: Write the new reference file**

Create `plugins/dev-workflows/references/feedback-emission.md` with EXACTLY this content:

````markdown
# Session Feedback Emission — Shared Reference

Single source of truth for the dev-workflows session-feedback emitter. Every
capture surface — the automatic maintenance phase of all eight workflow
commands, and the `/feedback` and `/prompt*` commands — cites this file and
executes its steps inline. The orchestrator owns every prompt; this reference
owns the entry format, the persistence ladder, dedup/attribution, the
plugin-facing predicate, and the caller contract.

**Purpose.** Capture friction and improvement signals about the **dev-workflows
plugin itself** and persist them per-VI into the **specs repo** so the plugin
maintainer can aggregate feedback across engineers. Feedback reaches the
maintainer only if it lands in the committed, pushed specs repo — hence the
persistence ladder is **specs-first** (§2).

**Self-contained — no hard cross-plugin dependency.** `/prompt-brainstorm` uses
`superpowers:brainstorming`; `/prompt-grill-me` runtime-resolves `/grilling`
(mattpocock-skills) and falls back to `superpowers:brainstorming` if it is not
installed. Neither is a declared install-time dependency.

**Relationship to B4 (`followup-emission.md`).** B4 captures the *engineer's own*
follow-up actions → vault-first, audience = the engineer. This feature captures
*plugin* friction → specs-first, audience = the maintainer. Both share the
`<VI-dir>/dev-workflows/` per-VI area. **No dedup between them** — different
purpose, different audience.

**Relationship to `impl-maintenance`.** The automatic surface reuses the existing
`impl-maintenance` agent's analysis; the agent definition is **untouched**. The
caller passes its Lessons Learned report to `emit-auto` (§6), which projects the
plugin-facing slice (§4) and persists it. This reference never analyses a
session itself.

## 1. Entry format (machine-friendly hybrid)

One file per VI, named `<KEY>-feedback.md`. Deterministic YAML for
filtering/clustering; prose for human judgment.

File-level frontmatter, written once on creation:

```yaml
---
type: dev-workflows-feedback
vi: PRODUCT-14902
slug: env-ag-update-window
---
```

- `vi` — the run's Jira key, or `n/a` when no key resolved.
- `slug` — the feature slug from the VI dir, or the ISO date on a keyless file.

Each entry is appended as a dated H2 header + a fenced YAML block + prose:

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

**Suggested improvement:** Add an optional `saas|managed` parameter to
`/document` so the run scopes to one product.
````

- YAML fields, all required: `id`, `date`, `command`, `plugin_version`,
  `origin`, `author`, `category`, `impact`.
- `origin` — `auto | manual | prompt`.
- `impact` — `blocker | friction | polish`.
- **`category`** — controlled vocab, extensible, reuse-first (reuse an existing
  value when it fits so clusters don't fragment):
  `missing-capability`, `wrong-output`, `ambiguous-prompt`,
  `missing-reference-doc`, `model-routing`, `manual-workaround`,
  `false-positive`, `docs-ux`, `other`.
- **`origin: prompt` entries add two more prose blocks** after Friction /
  Suggested improvement: **User prompt** (the user's corrective request,
  verbatim) and **Resolution** (what the AI actually did).
- `id` — stable: `<KEY>-<command>-<short-slug>` (drop the leading `/` from the
  command; use `manual` / `prompt` when `command` is `n/a`).

## 2. Persistence ladder (specs-first; never cwd)

`$SPECS_PATH` is primary — central aggregation is the whole point. Resolution is
**deterministic** (no interactive vault-path prompt, consistent with silent
capture, §5). Walk the ladder top-down and stop at the first tier that applies:

1. **`$SPECS_PATH` resolvable + writable + the VI dir exists** — the dir matched
   by `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…` →
   `<VI-dir>/dev-workflows/<KEY>-feedback.md`. *[primary — the whole point]*
2. **`$SPECS_PATH` writable but no VI dir matched** (no `jira_key`, or no
   matching spec dir) → `$SPECS_PATH/dev-workflows-feedback/<KEY-or-date>.md` at
   the specs-repo root. Still committed & aggregated; notice:
   `unfiled — move under the VI dir if it belongs to one.`
3. **No `$SPECS_PATH` (unset / missing / read-only) AND the vault is writable**
   (`$VAULT_PATH` set **and** `$VAULT_PATH/.obsidian/` is a directory **and**
   writable) → `$VAULT_PATH/dev-workflows/feedback/<KEY>-feedback.md`, with a
   **loud notice**:
   `⚠ $SPECS_PATH unavailable — saved to your vault; it will NOT auto-aggregate to the maintainer. Set $SPECS_PATH and commit, or forward manually.`
4. **`source = directory`** (imported Jira dir, no specs/vault) → beside the
   imported directory, where `/epics` + `/release-notes` already drop their
   no-vault output.
5. **Nothing resolvable** → **report-only**: keep the feedback in the run's
   final output and emit the notice. **NEVER write into the current working
   directory** — it may be a code repo.

In every non-primary tier the feedback also stays in the run's final output
(zero loss) and the run never fails. A write that fails mid-write (read-only
mount / permission) drops to the next tier with the same notice.

## 3. Dedup / append + attribution

- **Append-only.** Never modify or delete an existing entry. Append entries
  **chronologically** (newest at the end) for clean git diffs.
- **Auto entries dedupe:** before appending an `origin: auto` entry, read the
  existing `id:` values in the file and **skip** any that already exist (report
  `SKIP — already logged`). Because `id = <KEY>-<command>-<short-slug>` is
  stable, re-running a pipeline never double-logs.
- **Manual (`/feedback`) and prompt (`/prompt*`) entries are intentional** and
  are **never silently skipped.** On an `id` collision, append a numeric suffix
  (`-2`, `-3`, …) and warn if one looks near-identical.
- The file is created from the frontmatter template (§1) on first write.
- **Attribution:** `author` from `git config user.email` run in the specs repo
  (best-effort; `unknown` if unset). The *commit* author gives a second,
  authoritative layer once the engineer commits and pushes the specs.
  `plugin_version` is read at run time from
  `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
  (`python3 -c "import json;print(json.load(open('<path>'))['version'])"`).

## 4. Plugin-facing predicate — what persists

Persist **only** signals about the dev-workflows plugin itself:

- Command workflow improvements (a command should behave differently — e.g. the
  `saas|managed` scoping case).
- New agents / skills the plugin should offer.
- Gaps in the plugin's own reference docs (`${CLAUDE_PLUGIN_ROOT}/references/**`).
- Corrective interactions captured by `/prompt*` (any command output the user
  had to fix).

**Do NOT persist target-project tooling advice** — project `CLAUDE.md` rules,
target-repo hooks, and other repo-specific suggestions stay in
`impl-maintenance`'s in-session report, not the feedback file. That advice is
for the engineer's current repo, not the plugin maintainer.

When projecting an `impl-maintenance` report (§6 `emit-auto`), the plugin-facing
slice is exactly its **Command workflow improvements**, **New agents / skills**,
and **Reference docs** (paths under `${CLAUDE_PLUGIN_ROOT}`) sections, plus the
**Key observations** that triggered them. Discard its **CLAUDE.md rules** and
**Hooks** sections (target-project advice).

## 5. Interaction model — silent, high-recall

No curation/approval gate on capture. Capture is high-recall and zero-friction;
curation is the maintainer's job, centrally, at analysis time. A non-expert
engineer asked to approve/select/edit would rubber-stamp or drop the exact
signal the maintainer needs.

- **Automatic (`emit-auto`)** entries are written **silently**; the caller lists
  the persisted path (or "no plugin-facing signal — nothing persisted") in its
  output. A routine session with no plugin-facing signal writes nothing — no
  empty entry, byte-identical to today's report-only behavior.
- **`/feedback` and `/prompt*`** are user-invoked, so invocation *is* the
  intent; they write silently and surface the resulting path (and any
  degradation notice) in the command output.

## 6. Caller contract

Three named entry points. Every caller supplies `plugin_version` (§3) and lets
this reference resolve the target (§2), dedupe/append (§3), and format the entry
(§1). None of them commits; none writes into a docs/code repo or the current
working directory.

### `emit-auto` — automatic callers (the eight commands' maintenance phases)

Inputs: the `impl-maintenance` **Lessons Learned report**, `command` (the exact
slash-command name), `jira_key` (or `null`), `source` (`vault | directory |
none`).

Behavior: project the plugin-facing slice per §4 (Command workflow improvements
+ New agents / skills + plugin Reference docs + the triggering Key observations);
render one `origin: auto` entry per distinct plugin-facing signal (Friction =
the observation, Suggested improvement = the suggestion); dedupe by stable `id`
(§3); resolve the target (§2); write silently (§5). Return the persisted path,
or "no plugin-facing signal — nothing persisted" when the slice is empty.

### `emit-manual` — `/feedback`

Inputs: `command` (the exact name, or `n/a`), the user-authored **Friction** and
**Suggested improvement** prose, an inferred-and-confirmed `category` (§1 vocab),
`impact`, `jira_key` (or `null`), `source`.

Behavior: `origin: manual`; never silently skipped (§3 collision rule); resolve
the target (§2); write; surface the path + any degradation notice.

### `emit-prompt` — `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`

Inputs: `command` (inferred from recent context, or `n/a`), the **corrective
triple** — Friction, the **verbatim User prompt**, and the Resolution — a
`category`, `impact`, `jira_key` (or `null`), `source`.

Behavior: `origin: prompt`; write the entry with the two extra prose blocks
(User prompt verbatim + Resolution, §1); never silently skipped (§3); resolve
the target (§2); write silently (§5); surface the path.
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '^## 2. Persistence ladder (specs-first; never cwd)' plugins/dev-workflows/references/feedback-emission.md
grep -n 'type: dev-workflows-feedback' plugins/dev-workflows/references/feedback-emission.md
grep -c '### `emit-auto`' plugins/dev-workflows/references/feedback-emission.md
grep -c '### `emit-manual`' plugins/dev-workflows/references/feedback-emission.md
grep -c '### `emit-prompt`' plugins/dev-workflows/references/feedback-emission.md
grep -n 'NEVER write into the current working' plugins/dev-workflows/references/feedback-emission.md
grep -n '<VI-dir>/dev-workflows/<KEY>-feedback.md' plugins/dev-workflows/references/feedback-emission.md
git status --porcelain plugins/dev-workflows/references/feedback-emission.md
```
Expected: the ladder / frontmatter / cwd / VI-dir greps each return ≥1 line; each of the three `emit-*` counts is `1`; `git status --porcelain` shows `?? plugins/dev-workflows/references/feedback-emission.md` (a new, untracked file) and nothing else.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/feedback-emission.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): add session-feedback emitter reference

New references/feedback-emission.md — the single source of truth for the
session-feedback subsystem: machine-friendly entry format, the specs-first
persistence ladder (never cwd), append-only dedup + git attribution, the
plugin-facing predicate, and the emit-auto / emit-manual / emit-prompt caller
contract. Self-contained; reuses impl-maintenance (agent untouched); mirrors
B4's followup-emission.md shape but inverts the ladder to specs-first.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Create `commands/feedback.md`

**Files:**
- Create: `plugins/dev-workflows/commands/feedback.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` (T1), entry point `emit-manual`.
- Produces: the `/feedback` command (self-contained behavior).

- [ ] **Step 1: Write the new command file**

Create `plugins/dev-workflows/commands/feedback.md` with EXACTLY this content:

````markdown
---
name: feedback
description: Log a manual note about the dev-workflows plugin itself — friction you hit or an improvement you want — to the per-VI feedback file in the specs repo, for the plugin maintainer to aggregate. Tied to no command; run any time.
allowed-tools: Read Edit Write Bash Glob Grep LS
---

Log session feedback about the dev-workflows plugin: $ARGUMENTS

`/feedback` captures a **manual note about the dev-workflows plugin itself** —
friction you hit, or an improvement you want — and persists it per-VI into the
specs repo so the plugin maintainer can aggregate feedback across engineers. It
is tied to **no command** and can be run any time. You author the prose; the
command fills the metadata and writes the entry. `origin: manual`.

This command captures signal about **the plugin**, not about your target
project. Target-project tooling advice does not belong here (see
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` §4).

---

## Phase 1 — Compose the note

1. If `$ARGUMENTS` is empty, ask the user for the note (the friction and the
   improvement they want). Do not guess.
2. From the user's text, author two prose blocks — you may lightly tidy wording
   but never invent content the user did not express:
   - **Friction** — what about the plugin was wrong, slow, or missing.
   - **Suggested improvement** — the change they want.

## Phase 2 — Fill the metadata

Resolve, then confirm with the user in one grouped prompt (last choice always
`"Other… (describe)"`):

- **`command`** — the exact slash-command name this note is about, inferred from
  recent context; or `n/a` if it is not about a specific command. Confirm.
- **`category`** — inferred from the controlled vocab in
  `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` §1
  (`missing-capability`, `wrong-output`, `ambiguous-prompt`,
  `missing-reference-doc`, `model-routing`, `manual-workaround`,
  `false-positive`, `docs-ux`, `other`); reuse an existing value when it fits.
  Confirm.
- **`impact`** — `blocker | friction | polish`.
- **`author`** — `git config user.email` run in the specs repo (best-effort;
  `unknown` if unset).
- **`plugin_version`** — read from
  `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

Also resolve `jira_key` (from recent context, or `null`) and `source`
(`vault | directory | none`).

## Phase 3 — Persist

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-manual` entry point (§6): resolve the write target via the §2 specs-first
ladder using `jira_key` and `source`, format the entry per §1 (`origin:
manual`), and append per §3 (manual entries are never silently skipped — on an
`id` collision append a numeric suffix and warn). Write silently.

## Phase 4 — Report

Surface the persisted path and any degradation notice (e.g. the tier-3 vault
warning, or tier-5 report-only). This command NEVER commits, and NEVER writes
into a docs/code repo or the current working directory.
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '^name: feedback$' plugins/dev-workflows/commands/feedback.md
grep -c 'emit-manual' plugins/dev-workflows/commands/feedback.md
grep -c 'origin: manual' plugins/dev-workflows/commands/feedback.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/feedback.md
git status --porcelain plugins/dev-workflows/commands/feedback.md
```
Expected: the `name:` grep returns one line; `emit-manual` ≥ 1; `origin: manual` ≥ 1; `references/feedback-emission.md` ≥ 1; `git status --porcelain` shows `?? plugins/dev-workflows/commands/feedback.md` and nothing else.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/commands/feedback.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): add /feedback universal manual-note command

/feedback <text> logs a manual note about the plugin itself (origin: manual),
tied to no command. The user authors Friction + Suggested improvement; the
command fills the YAML (command, category, impact, author, plugin_version) and
persists via feedback-emission.md emit-manual (specs-first ladder). Never
commits or writes into a docs/code repo or the cwd.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Create the `/prompt*` family (`prompt.md`, `prompt-brainstorm.md`, `prompt-grill-me.md`)

**Files:**
- Create: `plugins/dev-workflows/commands/prompt.md`
- Create: `plugins/dev-workflows/commands/prompt-brainstorm.md`
- Create: `plugins/dev-workflows/commands/prompt-grill-me.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` (T1), entry point `emit-prompt`. At runtime `/prompt-brainstorm` uses `superpowers:brainstorming`; `/prompt-grill-me` runtime-resolves `/grilling` (mattpocock-skills) with a `superpowers:brainstorming` fallback — neither is a declared dependency.
- Produces: the three `/prompt*` commands (self-contained behavior).

- [ ] **Step 1: Write `commands/prompt.md`**

Create `plugins/dev-workflows/commands/prompt.md` with EXACTLY this content:

````markdown
---
name: prompt
description: Log a corrective interaction — a command produced something wrong and you're fixing it — as plugin feedback, then act on your correction directly. Captures the friction, your verbatim prompt, and the resolution to the specs repo for the maintainer.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Log a corrective interaction and act on it: $ARGUMENTS

`/prompt` is for when a dev-workflows command (`/specify`, `/design`,
`/implement`, `/document`, …) produced something wrong and you want to correct
it directly. It captures the **corrective triple** as plugin feedback, then
performs the correction. `origin: prompt`.

Captured (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` §1):
1. **Friction** — what the command produced that was wrong.
2. **User prompt** — your corrective request, **verbatim** (`$ARGUMENTS`).
3. **Resolution** — what the AI actually did.

---

## Phase 1 — Identify the target

Infer the target command from recent context — which command's output you are
correcting. Ask only if genuinely ambiguous (one grouped prompt, last choice
`"Other… (describe)"`). If no command applies, use `n/a`.

## Phase 2 — Act on the correction

Perform the corrective request in `$ARGUMENTS` directly (the quick correction).
Keep a one-line summary of what you did — this becomes the **Resolution** block.

## Phase 3 — Persist the corrective triple

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-prompt` entry point (§6). Provide:
- **Friction** — what the command produced that was wrong.
- **User prompt** — `$ARGUMENTS`, **verbatim** (never paraphrased).
- **Resolution** — the one-line summary of the correction you just applied.
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `jira_key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), and appends per §3
(prompt entries are never silently skipped). Write silently — a single append.

## Phase 4 — Report

Surface the persisted path and any degradation notice. This command NEVER
commits, and NEVER writes into a docs/code repo or the current working directory
(only the correction itself edits your target files, as you requested).
````

- [ ] **Step 2: Write `commands/prompt-brainstorm.md`**

Create `plugins/dev-workflows/commands/prompt-brainstorm.md` with EXACTLY this content:

````markdown
---
name: prompt-brainstorm
description: Log a corrective interaction as plugin feedback, then hand off to superpowers:brainstorming to redesign the correction together. Captures the friction, your verbatim prompt, and the resolution to the specs repo for the maintainer.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Log a corrective interaction, then brainstorm the fix: $ARGUMENTS

`/prompt-brainstorm` is for when a dev-workflows command produced something
wrong and the correction needs **exploration** rather than a one-shot fix. It
captures the **corrective triple** as plugin feedback, then hands off to
`superpowers:brainstorming`. `origin: prompt`.

---

## Phase 1 — Identify the target

Infer the target command from recent context — which command's output you are
correcting. Ask only if genuinely ambiguous (one grouped prompt, last choice
`"Other… (describe)"`). If no command applies, use `n/a`.

## Phase 2 — Persist the corrective triple

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-prompt` entry point (§6). Provide:
- **Friction** — what the command produced that was wrong.
- **User prompt** — `$ARGUMENTS`, **verbatim** (never paraphrased).
- **Resolution** — `Handed off to superpowers:brainstorming to redesign the correction.`
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `jira_key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), appends per §3
(never silently skipped), and writes silently. Surface the persisted path and
any degradation notice.

## Phase 3 — Hand off

Invoke `superpowers:brainstorming` (Skill tool) to explore and redesign the
correction with the user. This is a direct skill use — there is **no declared
install-time dependency**; the command simply invokes the skill if present.

This command NEVER commits, and NEVER writes into a docs/code repo or the
current working directory.
````

- [ ] **Step 3: Write `commands/prompt-grill-me.md`**

Create `plugins/dev-workflows/commands/prompt-grill-me.md` with EXACTLY this content:

````markdown
---
name: prompt-grill-me
description: Log a corrective interaction as plugin feedback, then hand off to /grilling (mattpocock-skills) to interrogate the fix — falling back to superpowers:brainstorming if mattpocock-skills is not installed. No hard dependency.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Log a corrective interaction, then grill the fix: $ARGUMENTS

`/prompt-grill-me` is for when a dev-workflows command produced something wrong
and you want a **relentless one-question-at-a-time interrogation** of the
correction. It captures the **corrective triple** as plugin feedback, then
runtime-resolves `/grilling` (mattpocock-skills), falling back to
`superpowers:brainstorming` if mattpocock-skills is not installed. `origin: prompt`.

`/grilling` is the invocable target — mattpocock's `/grill-me` is
`disable-model-invocation`, so this command resolves `/grilling` (which has no
such flag). mattpocock-skills is **NOT a declared dependency**; the command
degrades gracefully.

---

## Phase 1 — Identify the target

Infer the target command from recent context — which command's output you are
correcting. Ask only if genuinely ambiguous (one grouped prompt, last choice
`"Other… (describe)"`). If no command applies, use `n/a`.

## Phase 2 — Resolve the handoff target

Check whether the `/grilling` command (mattpocock-skills) is available in this
session:
- **Available** → the handoff target is `/grilling`.
- **Not available** → the handoff target is `superpowers:brainstorming`, and you
  MUST emit the notice:
  `mattpocock-skills not installed — using superpowers:brainstorming instead.`

## Phase 3 — Persist the corrective triple

Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its
`emit-prompt` entry point (§6). Provide:
- **Friction** — what the command produced that was wrong.
- **User prompt** — `$ARGUMENTS`, **verbatim** (never paraphrased).
- **Resolution** — `Handed off to <resolved target>` (the Phase 2 target —
  `/grilling`, or `superpowers:brainstorming` with the fallback notice).
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `jira_key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), appends per §3
(never silently skipped), and writes silently. Surface the persisted path and
any degradation notice.

## Phase 4 — Hand off

Invoke the Phase 2 target (Skill tool): `/grilling` when available, else
`superpowers:brainstorming` (having emitted the fallback notice). This command
NEVER commits, and NEVER writes into a docs/code repo or the current working
directory.
````

- [ ] **Step 4: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '^name: prompt$' plugins/dev-workflows/commands/prompt.md
grep -n '^name: prompt-brainstorm$' plugins/dev-workflows/commands/prompt-brainstorm.md
grep -n '^name: prompt-grill-me$' plugins/dev-workflows/commands/prompt-grill-me.md
grep -l 'emit-prompt' plugins/dev-workflows/commands/prompt.md plugins/dev-workflows/commands/prompt-brainstorm.md plugins/dev-workflows/commands/prompt-grill-me.md
grep -c 'superpowers:brainstorming' plugins/dev-workflows/commands/prompt-brainstorm.md
grep -c 'mattpocock-skills not installed — using superpowers:brainstorming instead' plugins/dev-workflows/commands/prompt-grill-me.md
grep -c '/grilling' plugins/dev-workflows/commands/prompt-grill-me.md
git status --porcelain plugins/dev-workflows/commands/prompt.md plugins/dev-workflows/commands/prompt-brainstorm.md plugins/dev-workflows/commands/prompt-grill-me.md
```
Expected: the three `name:` greps each return one line; `grep -l 'emit-prompt'` lists all three files; `superpowers:brainstorming` in `prompt-brainstorm.md` ≥ 1; the exact fallback-notice grep in `prompt-grill-me.md` is `1`; `/grilling` in `prompt-grill-me.md` ≥ 1; `git status --porcelain` shows exactly the three new `??` files.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/prompt.md plugins/dev-workflows/commands/prompt-brainstorm.md plugins/dev-workflows/commands/prompt-grill-me.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): add /prompt* corrective-capture command family

/prompt, /prompt-brainstorm, and /prompt-grill-me capture the corrective triple
(Friction + verbatim User prompt + Resolution) as origin: prompt feedback via
feedback-emission.md emit-prompt, then: /prompt acts directly; /prompt-brainstorm
hands off to superpowers:brainstorming; /prompt-grill-me runtime-resolves
/grilling (mattpocock-skills) and falls back to superpowers:brainstorming with a
notice. No hard cross-plugin dependency. Never commits or writes into the cwd.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Wire the automatic persist step into the five already-wired commands

Add the `emit-auto` persist step **after** each maintenance phase's `impl-maintenance` output. The `impl-maintenance` agent file is **untouched** — the plugin-facing projection happens in the caller. `document.md` has TWO insertion points (Mode A + Mode B).

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (Phase 4, after "Collect all four summaries for the Phase 5 report.")
- Modify: `plugins/dev-workflows/commands/document.md` (Mode A Phase 8, after "Collect all four summaries for the Phase 9 report."; Mode B Phase 4, after "Collect all four summaries for the Phase 5 report.")
- Modify: `plugins/dev-workflows/commands/epics.md` (Phase 8, after "Collect all four summaries for the Phase 9 report.")
- Modify: `plugins/dev-workflows/commands/vuln.md` (Step 4, after the `impl-maintenance` invocation)
- Modify: `plugins/dev-workflows/commands/upgrade.md` (Phase 2, after step 7 post-batch maintenance)

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` (T1), entry point `emit-auto`; each command's `impl-maintenance` Lessons Learned report, `jira_key`, and `source`.
- Produces: nothing other tasks depend on (self-contained command behavior).

- [ ] **Step 1: `implement.md` — insert the persist step in Phase 4**

Find this exact block:

```
Collect all four summaries for the Phase 5 report.

---

## Phase 5 — Final Report
```

Replace it with:

```
Collect all four summaries for the Phase 5 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /implement`, the run's `jira_key` and `source`, and `plugin_version`
(read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
renders only the report's **Command workflow improvements**, **New agents /
skills**, and plugin **Reference docs** sections plus the **Key observations**
that triggered them (§4 plugin-facing predicate) — never target-project
`CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id`
(§3), resolves the target via the §2 specs-first ladder, and writes silently.
List the persisted path (or "no plugin-facing signal — nothing persisted") in
the Phase 5 `### Session learnings` line. ADDITIVE — the impl-maintenance report
still appears in the report; this step NEVER fails the run, NEVER commits, and
NEVER writes into the code repo or the current working directory.

---

## Phase 5 — Final Report
```

- [ ] **Step 2: `document.md` — insert the Mode A persist step (Phase 8)**

Find this exact block:

```
Collect all four summaries for the Phase 9 report.

---

## Phase 8.5 — Finish & handoff
```

Replace it with:

```
Collect all four summaries for the Phase 9 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /document (Jira mode)`, the run's `jira_key` and `source`, and
`plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
`emit-auto` renders only the report's **Command workflow improvements**, **New
agents / skills**, and plugin **Reference docs** sections plus the **Key
observations** that triggered them (§4 plugin-facing predicate) — never
target-project `CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by
stable `id` (§3), resolves the target via the §2 specs-first ladder, and writes
silently. List the persisted path (or "no plugin-facing signal — nothing
persisted") in the Phase 9 report's Session learnings line. ADDITIVE — the
impl-maintenance report still appears in the report; this step NEVER fails the
run, NEVER commits, and NEVER writes into the docs repo or the current working
directory.

---

## Phase 8.5 — Finish & handoff
```

- [ ] **Step 3: `document.md` — insert the Mode B persist step (Phase 4)**

Find this exact block:

```
Collect all four summaries for the Phase 5 report.

---

## Phase 5 — Final Report
```

Replace it with:

```
Collect all four summaries for the Phase 5 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /document (direct mode)`, the run's `jira_key` (usually `null` in
direct mode) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only
the report's **Command workflow improvements**, **New agents / skills**, and
plugin **Reference docs** sections plus the **Key observations** that triggered
them (§4 plugin-facing predicate) — never target-project `CLAUDE.md`/hook advice
— as `origin: auto` entries, dedupes by stable `id` (§3), resolves the target
via the §2 specs-first ladder, and writes silently. List the persisted path
(or "no plugin-facing signal — nothing persisted") in the Phase 5
`### Session learnings (Agent 4)` line. ADDITIVE — the impl-maintenance report
still appears in the report; this step NEVER fails the run, NEVER commits, and
NEVER writes into the docs repo or the current working directory.

---

## Phase 5 — Final Report
```

- [ ] **Step 4: `epics.md` — insert the persist step in Phase 8**

Find this exact block:

```
Collect all four summaries for the Phase 9 report.

---

## Phase 9 — Final Report
```

Replace it with:

```
Collect all four summaries for the Phase 9 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /epics`, the run's `jira_key` and `source`, and `plugin_version`
(read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
renders only the report's **Command workflow improvements**, **New agents /
skills**, and plugin **Reference docs** sections plus the **Key observations**
that triggered them (§4 plugin-facing predicate) — never target-project
`CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id`
(§3), resolves the target via the §2 specs-first ladder, and writes silently.
List the persisted path (or "no plugin-facing signal — nothing persisted") in
the Phase 9 report's Session learnings line. ADDITIVE — the impl-maintenance
report still appears in the report; this step NEVER fails the run, NEVER
commits, and NEVER writes into `jira-products/`, `jira_export_root`, or the
current working directory.

---

## Phase 9 — Final Report
```

- [ ] **Step 5: `vuln.md` — insert the persist step in Step 4**

Find this exact block:

```
Then invoke `impl-maintenance` with a compact session handoff covering the CVEs fixed, notable regressions, workarounds, and overall outcome.

---

## Handling Test Failures
```

Replace it with:

```
Then invoke `impl-maintenance` with a compact session handoff covering the CVEs fixed, notable regressions, workarounds, and overall outcome.

**Then persist plugin feedback (automatic).** After `impl-maintenance` returns, project its plugin-facing slice into the specs repo by citing `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its `emit-auto` entry point (§6). Pass the Lessons Learned report, `command: /vuln`, the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only the report's **Command workflow improvements**, **New agents / skills**, and plugin **Reference docs** sections plus the **Key observations** that triggered them (§4 plugin-facing predicate) — never target-project `CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via the §2 specs-first ladder, and writes silently. List the persisted path (or "no plugin-facing signal — nothing persisted") after the lessons-learned report. ADDITIVE — the impl-maintenance report still appears in the output; this step NEVER fails the run, NEVER commits, and NEVER writes into the code repo or the current working directory.

---

## Handling Test Failures
```

- [ ] **Step 6: `upgrade.md` — insert the persist step as Phase 2 step 8**

Find this exact block:

```
7. **Post-batch maintenance** — After all components finish, invoke `impl-maintenance` with a compact session handoff summarising what was upgraded, key failures or workarounds, and the overall result.

---

## Version Resolution
```

Replace it with:

```
7. **Post-batch maintenance** — After all components finish, invoke `impl-maintenance` with a compact session handoff summarising what was upgraded, key failures or workarounds, and the overall result.

8. **Persist plugin feedback (automatic)** — After `impl-maintenance` returns, project its plugin-facing slice into the specs repo by citing `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its `emit-auto` entry point (§6). Pass the Lessons Learned report, `command: /upgrade`, the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only the report's **Command workflow improvements**, **New agents / skills**, and plugin **Reference docs** sections plus the **Key observations** that triggered them (§4 plugin-facing predicate) — never target-project `CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via the §2 specs-first ladder, and writes silently. List the persisted path (or "no plugin-facing signal — nothing persisted") after the lessons-learned report. ADDITIVE — this step NEVER fails the run, NEVER commits, and NEVER writes into the code repo or the current working directory.

---

## Version Resolution
```

- [ ] **Step 7: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/implement.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/document.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/epics.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/vuln.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/upgrade.md
grep -c 'emit-auto' plugins/dev-workflows/commands/document.md
grep -n 'command: /document (Jira mode)' plugins/dev-workflows/commands/document.md
grep -n 'command: /document (direct mode)' plugins/dev-workflows/commands/document.md
grep -c '## Invariants (always enforced)' plugins/dev-workflows/commands/implement.md
git diff --stat plugins/dev-workflows/commands/implement.md plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md
git diff plugins/dev-workflows/commands/document.md
```
Expected: `references/feedback-emission.md` count is `1` in implement/epics/vuln/upgrade and **`2`** in document.md; `emit-auto` in document.md is `2`; both `command: /document (…)` greps return one line each (Mode A + Mode B); implement.md's `## Invariants (always enforced)` count is unchanged (still `1`); `--stat` lists exactly the five files; the document.md diff shows only the two persist blocks inserted, each mode's headings unchanged below it.

- [ ] **Step 8: Commit**

```bash
git add plugins/dev-workflows/commands/implement.md plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): auto-persist plugin feedback in the five maintenance-wired commands

/implement, /document (Mode A + Mode B), /epics, /vuln, and /upgrade now persist
the plugin-facing slice of their existing impl-maintenance report (Command
workflow improvements + New agents/skills + Reference-doc gaps + triggering Key
observations) via feedback-emission.md emit-auto (origin: auto, silent, deduped,
specs-first). Projection happens in the caller; the impl-maintenance agent file
is untouched. Additive — the report is unchanged; never fails, commits, or
writes into the cwd.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Add a terminal maintenance phase to the three maintenance-less commands

Each of `/release-notes`, `/specify`, and `/design` gains a NEW lightweight terminal phase that invokes `impl-maintenance` on the Sonnet detection chain, then persists via `emit-auto`. `release-notes.md` has an `## Invariants` block (anchor before it). `specify.md` and `design.md` have **no** `## Invariants` block — insert the new phase immediately BEFORE the unique `## Final report` heading, keeping the numbered phases contiguous (Phase 8, then the terminal Final report). The phase surfaces the persisted path as its OWN output.

**Files:**
- Modify: `plugins/dev-workflows/commands/release-notes.md` (new **Phase 10** before `## Invariants (always enforced)`)
- Modify: `plugins/dev-workflows/commands/specify.md` (new **Phase 8** before `## Final report`)
- Modify: `plugins/dev-workflows/commands/design.md` (new **Phase 8** before `## Final report`)

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` (T1), entry point `emit-auto`; the `dev-workflows:impl-maintenance` agent (invoked, not modified); each run's `jira_key` and `source`.
- Produces: nothing cross-task.

- [ ] **Step 1: `release-notes.md` — insert Phase 10 before `## Invariants`**

Find this exact block:

```
---

## Invariants (always enforced)

- ZERO external API calls — PR URLs are identifiers only; all resolution is local `git`.
```

Replace it with:

```
---

## Phase 10 — Session maintenance & feedback

Terminal phase — runs AFTER the Phase 8 report and the Phase 9 follow-up phase;
NEVER interrupts an earlier phase. `/release-notes` has no built-in maintenance
agent, so this phase invokes `impl-maintenance` on the Sonnet detection chain
and then persists the plugin-facing slice of its report as session feedback.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<Sonnet detection chain — claude-sonnet-5, fallback claude-sonnet-4-6 / 4-5>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /release-notes
   > - What was done: [one-paragraph summary of the release-notes draft produced]
   > - Key events: [source-truth discrepancies, PARTIAL renders, style-check failures, ambiguous destinations — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: N/A (light gate only, no Opus review)
   > - Test result: N/A (no tests in /release-notes)
   > - Project root: [the resolved jira_export_root or the destination directory]"
2. **Persist plugin feedback (automatic).** Project the report's plugin-facing
   slice into the specs repo by citing
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
   `emit-auto` entry point (§6). Pass the Lessons Learned report,
   `command: /release-notes`, the run's `jira_key` and `source`, and
   `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only
   the report's **Command workflow improvements**, **New agents / skills**, and
   plugin **Reference docs** sections plus the **Key observations** that
   triggered them (§4) — never target-project `CLAUDE.md`/hook advice — as
   `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via
   the §2 specs-first ladder, and writes silently.
3. **Surface** the persisted path (or "no plugin-facing signal — nothing
   persisted") as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits, NEVER makes an external
API call, and NEVER writes into a docs repo or the current working directory.

---

## Invariants (always enforced)

- ZERO external API calls — PR URLs are identifiers only; all resolution is local `git`.
```

- [ ] **Step 2: `specify.md` — insert Phase 8 before `## Final report`**

Find this exact line (the unique Final-report heading — its hard-wrapped body stays untouched below the new phase):

```
## Final report
```

Replace it with:

```
## Phase 8 — Session maintenance & feedback

Terminal phase — runs after Phase 7 and before the Final report is presented;
NEVER interrupts an earlier phase. `/specify` has no built-in maintenance agent,
so this phase invokes `impl-maintenance` on the Sonnet detection chain and then
persists the plugin-facing slice of its report as session feedback.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /specify
   > - What was done: [one-paragraph summary of the specification authored]
   > - Key events: [BLOCK reviews and their reason, unmounted-repo soft-gate advisories, unresolved open questions, picker / round-trip friction — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: [the spec-reviewer verdict — PASS | PASS WITH RECOMMENDATIONS | BLOCK]
   > - Test result: N/A (no tests in /specify)
   > - Project root: [the resolved feature folder under $SPECS_PATH]"
2. **Persist plugin feedback (automatic).** Project the report's plugin-facing
   slice into the specs repo by citing
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
   `emit-auto` entry point (§6). Pass the Lessons Learned report,
   `command: /specify`, the run's `jira_key` and `source`, and `plugin_version`
   (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
   renders only the report's **Command workflow improvements**, **New agents /
   skills**, and plugin **Reference docs** sections plus the **Key observations**
   that triggered them (§4) — never target-project `CLAUDE.md`/hook advice — as
   `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via
   the §2 specs-first ladder, and writes silently.
3. **Surface** the persisted path (or "no plugin-facing signal — nothing
   persisted") as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in
Phase 7), and NEVER writes into the current working directory. The specs-first
ladder writes the feedback file inside `$SPECS_PATH`, alongside the feature
folder — the intended home.

## Final report
```

- [ ] **Step 3: `design.md` — insert Phase 8 before `## Final report`**

Find this exact line (the unique Final-report heading — its hard-wrapped body stays untouched below the new phase):

```
## Final report
```

Replace it with:

```
## Phase 8 — Session maintenance & feedback

Terminal phase — runs after Phase 7 and before the Final report is presented;
NEVER interrupts an earlier phase. `/design` has no built-in maintenance agent,
so this phase invokes `impl-maintenance` on the Sonnet detection chain and then
persists the plugin-facing slice of its report as session feedback.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /design
   > - What was done: [one-paragraph summary of the engineering design authored]
   > - Key events: [BLOCK reviews and their reason, STRICT repo-gate hard-stops, model-gate overrides, unresolved design open questions — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: [the design-reviewer verdict — PASS | PASS WITH RECOMMENDATIONS | BLOCK]
   > - Test result: N/A (no tests in /design)
   > - Project root: [the resolved feature folder under $SPECS_PATH]"
2. **Persist plugin feedback (automatic).** Project the report's plugin-facing
   slice into the specs repo by citing
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
   `emit-auto` entry point (§6). Pass the Lessons Learned report,
   `command: /design`, the run's `jira_key` and `source`, and `plugin_version`
   (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
   renders only the report's **Command workflow improvements**, **New agents /
   skills**, and plugin **Reference docs** sections plus the **Key observations**
   that triggered them (§4) — never target-project `CLAUDE.md`/hook advice — as
   `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via
   the §2 specs-first ladder, and writes silently.
3. **Surface** the persisted path (or "no plugin-facing signal — nothing
   persisted") as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in
Phase 7), and NEVER writes into the current working directory. The specs-first
ladder writes the feedback file inside `$SPECS_PATH`, alongside the feature
folder — the intended home.

## Final report
```

- [ ] **Step 4: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '## Phase 10 — Session maintenance & feedback' plugins/dev-workflows/commands/release-notes.md
grep -n '## Phase 8 — Session maintenance & feedback' plugins/dev-workflows/commands/specify.md
grep -n '## Phase 8 — Session maintenance & feedback' plugins/dev-workflows/commands/design.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/release-notes.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/specify.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/commands/design.md
grep -c 'dev-workflows:impl-maintenance' plugins/dev-workflows/commands/release-notes.md
grep -c 'dev-workflows:impl-maintenance' plugins/dev-workflows/commands/specify.md
grep -c 'dev-workflows:impl-maintenance' plugins/dev-workflows/commands/design.md
grep -c '## Invariants (always enforced)' plugins/dev-workflows/commands/release-notes.md
git diff plugins/dev-workflows/commands/release-notes.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md
```
Expected: each new-phase grep returns one line (Phase 10 for release-notes, Phase 8 for specify + design); `references/feedback-emission.md` count is `1` in each of the three files; `dev-workflows:impl-maintenance` count is `1` in each (the new invocation); release-notes `## Invariants (always enforced)` count is still `1` (preserved below the new phase); each specify/design `## Final report` count is still `1` (preserved directly below the new phase); the diff shows only the new phase blocks inserted (before the release-notes invariants block; before each specify/design `## Final report` heading).

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/release-notes.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): terminal maintenance+feedback phase for /release-notes, /specify, /design

The three maintenance-less commands gain a lightweight terminal phase that
invokes impl-maintenance on the Sonnet detection chain, then persists the
plugin-facing slice via feedback-emission.md emit-auto (origin: auto, silent,
specs-first). /release-notes gets Phase 10 (before Invariants); /specify and
/design get Phase 8 (inserted before Final report — neither has an Invariants
block). Additive — never fails, commits, or writes into the cwd.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Release surfaces — v2.9.0 (versions, description, CHANGELOG, README)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (version + description)
- Modify: `.claude-plugin/marketplace.json` (`dev-workflows` entry version + description)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend `[2.9.0]`)
- Modify: `plugins/dev-workflows/README.md` (new `## Session feedback` section + Reference-docs bullet). Root README untouched.

**Interfaces:**
- Consumes: the behaviors implemented in Tasks 1–5 (for accurate CHANGELOG / README prose and the +4 command count).
- Produces: the released version surface. Run last.

- [ ] **Step 1: Bump `plugin.json` version**

Find `  "version": "2.8.0",` and replace with `  "version": "2.9.0",`.

- [ ] **Step 2: Update `plugin.json` description (Eleven → Fifteen slash commands)**

Find this exact substring:

```
Eleven slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /specify, and /design — with
```

Replace it with:

```
Fifteen slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /specify, /design, /feedback, /prompt, /prompt-brainstorm, and /prompt-grill-me — with
```

Leave the "Twenty-six reusable subagents" and "four hooks" sentences unchanged (no subagent or hook added).

- [ ] **Step 3: Bump `marketplace.json` (dev-workflows entry version only)**

Find `      "version": "2.8.0",` (the dev-workflows entry — `2.8.0` is unique; siblings are `0.2.2` / `0.3.1`) and replace with `      "version": "2.9.0",`. Do NOT touch the `dt-style-guide` / `obsidian-llm-wiki` entries.

- [ ] **Step 4: Update `marketplace.json` description (same Eleven → Fifteen edit)**

Find this exact substring (identical to Step 2's; it appears only in the `dev-workflows` entry):

```
Eleven slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /specify, and /design — with
```

Replace it with:

```
Fifteen slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /specify, /design, /feedback, /prompt, /prompt-brainstorm, and /prompt-grill-me — with
```

- [ ] **Step 5: Prepend the CHANGELOG entry**

Find this exact block (the current top-most entry header):

```
## [2.8.0] — 2026-07-09

### Added
```

Replace it with (the new entry, then the found block unchanged):

```
## [2.9.0] — 2026-07-09

### Added

- **Session feedback collection — the plugin now captures friction and improvement signals about itself and persists them per-VI into the specs repo for the maintainer to aggregate.** A new shared reference `references/feedback-emission.md` is the single source of truth: the machine-friendly entry format (file frontmatter `type` / `vi` / `slug` + per-entry YAML `id` / `date` / `command` / `plugin_version` / `origin` / `author` / `category` / `impact` + prose), the **specs-first** persistence ladder (`$SPECS_PATH` VI dir `<VI-dir>/dev-workflows/<KEY>-feedback.md` → `$SPECS_PATH/dev-workflows-feedback/` → a writable vault with a loud "won't auto-aggregate" notice → beside an imported Jira directory → report-only; **never the cwd**), append-only dedup with `git`-derived attribution, the plugin-facing predicate (persist plugin signal only — never target-project `CLAUDE.md` / hook advice), and a three-entry-point caller contract (`emit-auto`, `emit-manual`, `emit-prompt`).
- **Automatic capture across all eight workflow commands.** `/implement`, `/document` (Mode A + Mode B), `/epics`, `/vuln`, and `/upgrade` now persist the plugin-facing slice of their existing `impl-maintenance` report (Command workflow improvements + New agents/skills + Reference-doc gaps + the triggering Key observations) as `origin: auto` feedback, silently, after maintenance runs. `/release-notes`, `/specify`, and `/design` gain a new lightweight terminal maintenance phase that invokes `impl-maintenance` on the Sonnet detection chain and then persists. A routine session with no plugin-facing signal writes nothing (byte-identical to before).
- **New commands `/feedback`, `/prompt`, `/prompt-brainstorm`, and `/prompt-grill-me`.** `/feedback <text>` logs a universal manual note (`origin: manual`). The `/prompt*` family captures a corrective interaction — Friction, your verbatim prompt, and the Resolution (`origin: prompt`): `/prompt` acts on the correction directly, `/prompt-brainstorm` hands off to `superpowers:brainstorming`, and `/prompt-grill-me` runtime-resolves `/grilling` (mattpocock-skills) and falls back to `superpowers:brainstorming` if it is not installed. No hard cross-plugin dependency.

Additive only — the `impl-maintenance` agent core, `jira-reader`, the reviewers, `format-refs`, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; feedback also always remains in the run's final output (zero loss) and no capture phase ever fails the run.

## [2.8.0] — 2026-07-09

### Added
```

- [ ] **Step 6: Add the README `## Session feedback` section**

In `plugins/dev-workflows/README.md`, find this exact block (the end of the Commands section + the start of the `/implement` deep-dive):

```
`/implement` adds test-writing (Phase 3.5) between implementation and review, then verifies the baseline.

## `/implement` workflow
```

Replace it with (the same lines, with the new section inserted between):

```
`/implement` adds test-writing (Phase 3.5) between implementation and review, then verifies the baseline.

## Session feedback

Beyond the workflow commands, dev-workflows captures **friction and improvement
signals about the plugin itself** and persists them per-VI into the specs repo,
so the plugin maintainer can aggregate feedback across engineers and plan
improvements. Capture is **silent and high-recall** — there is no approval gate;
curation is the maintainer's job, centrally, at analysis time.

- **Automatic.** The end-of-run maintenance phase of all eight workflow commands
  (`/implement`, `/document`, `/epics`, `/vuln`, `/upgrade`, `/release-notes`,
  `/specify`, `/design`) projects the plugin-facing slice of the
  `impl-maintenance` report (command workflow improvements, new agents/skills,
  reference-doc gaps) into a feedback entry (`origin: auto`). A routine session
  with no plugin-facing signal writes nothing.
- **`/feedback <text>`** — a universal manual note about the plugin, tied to no
  command (`origin: manual`).
- **`/prompt <text>`** — capture a corrective interaction (a command produced
  something wrong; you fix it) as Friction + your verbatim prompt + the
  Resolution, then act on the correction directly (`origin: prompt`).
- **`/prompt-brainstorm <text>`** — same capture, then hand off to
  `superpowers:brainstorming`.
- **`/prompt-grill-me <text>`** — same capture, then runtime-resolve `/grilling`
  (mattpocock-skills), **falling back to `superpowers:brainstorming` with a
  notice if mattpocock-skills is not installed**. mattpocock-skills is an
  **optional** dependency — the command degrades gracefully; there is no hard
  install-time requirement.

**Graceful degradation.** Persistence is **specs-first** (central aggregation is
the point) and deterministic: `$SPECS_PATH` VI dir
(`<VI-dir>/dev-workflows/<KEY>-feedback.md`) → `$SPECS_PATH/dev-workflows-feedback/`
→ a writable vault (with a loud "won't auto-aggregate to the maintainer" notice)
→ beside an imported Jira directory → report-only. It **never** writes into the
current working directory, and no capture phase ever fails the run. See
`references/feedback-emission.md`.

## `/implement` workflow
```

- [ ] **Step 7: Add the README Reference-docs bullet**

In `plugins/dev-workflows/README.md`, find this exact line (the `followup-emission.md` bullet):

```
- `references/followup-emission.md` — the end-of-run follow-up task & journal emitter shared by `/document`, `/release-notes`, `/epics`, and `/implement` (task-line format, Jira-key → project-file resolution, notes / `Journal.md` placement, dedupe, the no-vault fallback ladder). Self-contained; mirrors obsidian-llm-wiki's `_shared/task-rules.md` + `vault-conventions.md`.
```

Replace it with (the same line, then a new bullet):

```
- `references/followup-emission.md` — the end-of-run follow-up task & journal emitter shared by `/document`, `/release-notes`, `/epics`, and `/implement` (task-line format, Jira-key → project-file resolution, notes / `Journal.md` placement, dedupe, the no-vault fallback ladder). Self-contained; mirrors obsidian-llm-wiki's `_shared/task-rules.md` + `vault-conventions.md`.
- `references/feedback-emission.md` — the session-feedback emitter shared by the automatic maintenance phases and the `/feedback` + `/prompt*` commands (entry format, the specs-first persistence ladder, append-only dedup + attribution, the plugin-facing predicate, and the `emit-auto` / `emit-manual` / `emit-prompt` caller contract). Self-contained; persists plugin signal to `$SPECS_PATH` for maintainer aggregation.
```

- [ ] **Step 8: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('plugin.json OK')"
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); v={p['name']:p['version'] for p in m['plugins']}; print(v); assert v['dev-workflows']=='2.9.0' and v['dt-style-guide']=='0.2.2' and v['obsidian-llm-wiki']=='0.3.1'"
grep -c 'Fifteen slash commands' plugins/dev-workflows/.claude-plugin/plugin.json
grep -c 'Fifteen slash commands' .claude-plugin/marketplace.json
grep -c 'Twenty-six reusable subagents' plugins/dev-workflows/.claude-plugin/plugin.json
grep -n '## \[2.9.0\] — 2026-07-09' plugins/dev-workflows/CHANGELOG.md
grep -c '## Session feedback' plugins/dev-workflows/README.md
grep -c 'references/feedback-emission.md' plugins/dev-workflows/README.md
git diff --stat
```
Expected: both JSON files parse; the marketplace assertion passes (dev-workflows `2.9.0`, siblings unchanged); `Fifteen slash commands` appears once in each JSON file; `Twenty-six reusable subagents` still appears once in `plugin.json` (subagent count unchanged); the CHANGELOG grep returns one line; `## Session feedback` appears once in the README; `references/feedback-emission.md` appears **2** times in the README (Session-feedback section + Reference-docs bullet); `--stat` lists exactly the four files (`plugin.json`, `marketplace.json`, `CHANGELOG.md`, `README.md`) and nothing else.

- [ ] **Step 9: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md
git commit -m "$(cat <<'EOF'
release(dev-workflows): v2.9.0 — session feedback collection

Version lock-step (plugin.json + marketplace.json dev-workflows entry) to 2.9.0;
description Eleven -> Fifteen slash commands (+ /feedback, /prompt,
/prompt-brainstorm, /prompt-grill-me); subagent count (26) and hook count (4)
unchanged. CHANGELOG [2.9.0] Added; README Session-feedback section +
Reference-docs bullet. Siblings dt-style-guide 0.2.2 / obsidian-llm-wiki 0.3.1
untouched.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Notes for the executor

- **Byte-diff discipline:** these are prose/JSON files; after each task, read the `git diff` and confirm no unintended reflow or anchor drift. Prettier is **not** run here (no husky/pnpm in this repo).
- **Anchor drift:** line numbers in this plan are approximate (from a 2026-07-09 read). Locate edits by the quoted anchor text, not by line number.
- **Additive contract:** with no plugin-facing signal and no writable specs/vault target, every command behaves exactly as today (feedback always also remains in the run's final output). Any behavior change in that case is a defect.
- **`document.md` has two `## Phase 5 — Final Report` / `Collect all four summaries…` regions** (Mode A uses "Phase 9 report"; Mode B uses "Phase 5 report"). The T4 Mode A and Mode B find blocks disambiguate by including the following `## Phase …` heading — never match the bare "Collect all four summaries" line. The Mode B find block ("Phase 5 report" + `## Phase 5 — Final Report`) is textually identical to `implement.md`'s T4 find block, but they are edits on two different files, so each is unambiguous within its own file.
- **`impl-maintenance` handoff enum:** the agent's documented `Command run` enum predates `/release-notes`, `/specify`, and `/design`; passing those names is fine — the agent uses the value verbatim to scope its "Command workflow improvements" and is suggest-only. Do NOT edit the agent to add them (agent core is untouched by constraint).

## Plan self-review (writing-plans)

**(1) Spec coverage — every design section maps to a task:**

| Design §| Where covered |
|---|---|
| §1 Goal | Plan Goal + T1 (purpose) |
| §2 Motivating example | T1 §1 (the `saas|managed` example is the canonical entry) |
| §3 Architecture decision (reuse impl-maintenance; self-contained; rejected alts) | Plan Architecture + T1 (relationships) + T4 (caller-side projection) + T3 (no hard dep) |
| §4 Components (4.1 reference, 4.2 surfaces) | T1 (reference) + T2 (`/feedback`) + T3 (`/prompt*`) + T4/T5 (automatic) |
| §5 Capture surfaces (5.1 auto, 5.2 `/feedback`, 5.3 `/prompt*`) | 5.1 → T4 (5 wired) + T5 (3 new phases); 5.2 → T2; 5.3 → T3 |
| §6 Persistence ladder (specs-first, 5 tiers) | T1 §2 (verbatim 5 tiers) |
| §7 Entry format | T1 §1 (verbatim YAML fields + category vocab + impact) |
| §8 Dedup / append + attribution | T1 §3 |
| §9 Plugin-facing predicate | T1 §4; cited by T4/T5 persist blocks |
| §10 Interaction model (silent, high-recall) | T1 §5; reflected in every persist step + new command |
| §11 Command wiring | T4 (5 add persist) + T5 (3 gain phase) + T2/T3 (new commands) |
| §12 Release surfaces | T6 (versions, description, CHANGELOG, README) |
| §13 Relationship to B4 + impl-maintenance | T1 (relationship notes) + Plan Architecture |
| §14 Non-goals | Global Constraints (no hard dep, no gate, no B4 dedup, append-only, no target-project advice, agent/siblings untouched) |
| §15 Resolved decisions | Baked into T1 §2/§5/§7 and T3 (grill-me fallback) |

**(2) Placeholder scan:** No "TBD", "handle edge cases", or "similar to Task N". CREATE steps (T1, T2, T3) contain complete file content; MODIFY steps (T4, T5, T6) contain verbatim anchors + full insertion text. Bracketed `[…]` tokens appear only inside `impl-maintenance` handoff prompts, which are runtime fill-ins the orchestrator supplies per session (matching the existing five commands' handoff style) — not plan placeholders.

**(3) Anchor / name consistency:** The caller-contract entry-point names defined in T1 §6 — **`emit-auto`**, **`emit-manual`**, **`emit-prompt`** — are used verbatim: `emit-auto` in T4 (all six insertion points) and T5 (all three new phases); `emit-manual` in T2; `emit-prompt` in T3 (all three commands). The plugin-facing slice definition (Command workflow improvements + New agents/skills + Reference docs + Key observations) is stated identically in T1 §4 and repeated in every T4/T5 persist block. File name `references/feedback-emission.md` and the `<VI-dir>/dev-workflows/<KEY>-feedback.md` path are consistent across T1, T4, T5, T6, and the README.

---
tags:
  - tasks-exclude
---
# Drop the mattpocock-skills dependency — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make dev-workflows fully self-contained for grilling by retargeting `/prompt-grill-me` to an inline grill and removing every operational `mattpocock-skills` dependency, while keeping honest attribution. Ship as v2.25.0.

**Architecture:** Three tasks — (1) rewrite `commands/prompt-grill-me.md` to grill inline via the embedded technique; (2) scrub operational Matt references from four doc/reference files (keep credits); (3) bump manifests to 2.25.0 lock-step + CHANGELOG. All edits are markdown; no runtime code, no test framework.

**Tech Stack:** Markdown command/reference files; JSON manifests (`plugin.json`, `marketplace.json`). Verification is structural: `grep`, `python3 -c json.load`, `git diff --stat`, byte-diff, recomputed counts.

## Global Constraints

- **Commit/push only when asked.** Work on branch `ivgu/NOISSUE-drop-mattpocock-dependency` off `main`. Per-task commits on that branch are part of the agreed execution; **pushing** is gated to the finish-branch menu.
- **Never `git add -A`.** Stage only the named files in each commit step.
- **Commit trailer:** match the exact trailer of recent commits in `/workspace/ihudak-claude-plugins` — verify with `git log -1 --format=%B` before the first commit. Established format: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Version lock-step:** `plugin.json` version == the dev-workflows entry in root `.claude-plugin/marketplace.json` == `2.25.0`. Bump **only** the dev-workflows entry (marketplace.json line 12) — NOT the sibling entries (lines 24, 36).
- **Siblings byte-identical:** `dt-style-guide` (0.2.2) and `obsidian-llm-wiki` (0.3.1) must show a 0-line `git diff`.
- **No count-string change:** the manifest descriptions must stay byte-identical (still `Twenty slash commands` / `Thirty reusable subagents`). `/prompt-grill-me` is retargeted, not removed; no agent added/removed. Do NOT edit either `description` field.
- **Keep attribution, drop operational instructions:** retain every "adapted from mattpocock grill-me/grilling" *credit*; remove every "install / invoke Matt's `/grilling`" *instruction* and every "runtime-resolve `/grilling`" description.
- **No collateral:** `/vuln`, `/upgrade`, `jira-reader`, `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, and all other commands/agents show a 0-line diff.
- **Depth note (spec reconciliation):** the spec fixed the inline grill depth at **bounded (≤5)**. The command's old intro said "relentless" (it delegated to Matt's unbounded `/grilling`). To keep the file internally consistent with the approved bounded depth, the intro/description wording changes "relentless" → "bounded (≤5)". This is intentional, not a drift.
- The vault holding this plan is auto-backed-up by Obsidian Git — do NOT hand-commit vault files.

---

## Task 1: Retarget `/prompt-grill-me` to an inline grill

**Files:**
- Modify (full rewrite): `plugins/dev-workflows/commands/prompt-grill-me.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` (embedded technique — Bounded depth); `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` `emit-prompt` entry point (§6).
- Produces: a self-contained `/prompt-grill-me` — no `/grilling`, no `mattpocock`, no `superpowers` handoff.

- [ ] **Step 1: Rewrite the command file**

Overwrite `plugins/dev-workflows/commands/prompt-grill-me.md` with exactly this content:

````markdown
---
name: prompt-grill-me
description: Log a corrective interaction as plugin feedback, then grill the fix inline — a bounded one-question-at-a-time interrogation (≤5 questions) of the correction following the embedded grilling technique. Self-contained; no plugin dependency.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---

Log a corrective interaction, then grill the fix: $ARGUMENTS

`/prompt-grill-me` is for when a dev-workflows command produced something wrong
and you want a **bounded one-question-at-a-time interrogation** (≤5 questions) of
the correction. It captures the **corrective triple** as plugin feedback, then
grills the fix **inline** following the embedded grilling technique
(`${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md`). `origin: prompt`.

The interrogation is self-contained — this command owns the grill and has **no
plugin dependency**.

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
- **Resolution** — `Grilled the fix inline`.
- `command` (Phase 1), an inferred `category` (§1 vocab, reuse-first), `impact`,
  `jira_key` (or `null`), `source`.

`emit-prompt` resolves the write target via the §2 specs-first ladder, formats
the entry with the two extra prose blocks (`origin: prompt`), appends per §3
(never silently skipped), and writes silently. Surface the persisted path.

## Phase 3 — Grill the fix (inline)

Interrogate the correction directly, following
`${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md`:
- **Depth:** **bounded** — a capped set (≤5) of the highest Impact×Uncertainty
  questions about the fix, then stop; record any leftover high-impact gaps.
- **Stage:** the correction itself — why the original output was wrong, what the
  right shape is, and what should change so the mistake does not recur.

Follow the technique's mechanics (one question at a time, a recommended answer
each time, fact-vs-decision split, dependency order). This command NEVER
commits, and NEVER writes into a docs/code repo or the current working
directory.
````

- [ ] **Step 2: Verify the command is self-contained**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -inE "grilling|mattpocock|pocock|superpowers|handoff|hand off|runtime-resolve" commands/prompt-grill-me.md
```
Expected: matches ONLY for the embedded-technique citation lines (`grilling-technique.md`) and the phrase "grill(s) the fix inline" / "grilling technique". **Zero** matches for `mattpocock`, `pocock`, `superpowers`, `/grilling`, `handoff`, `hand off`, or `runtime-resolve`.

Then confirm the guarantees survived:
```bash
grep -in "NEVER commits" commands/prompt-grill-me.md
grep -in "grilling-technique.md" commands/prompt-grill-me.md
```
Expected: both present (the "never commits / never writes" guarantee, and the technique citation).

- [ ] **Step 3: Confirm no other command references `/grilling`**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -rlnE "runtime-resolve .*/grilling|resolve \`/grilling\`" commands/
```
Expected: no output (empty) — `/prompt-grill-me` was the only command that resolved `/grilling`.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/prompt-grill-me.md
git commit -m "$(cat <<'EOF'
refactor(dev-workflows): grill inline in /prompt-grill-me, drop /grilling handoff

/prompt-grill-me now interrogates the correction inline via the embedded
references/grilling-technique.md (bounded ≤5) instead of resolving Matt
Pocock's /grilling with a superpowers:brainstorming fallback. Feedback
capture and the never-commits/never-writes guarantees are unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Scrub operational Matt references from docs & references (keep credits)

**Files:**
- Modify: `plugins/dev-workflows/references/dependencies.md` (Recommended-companions table)
- Modify: `plugins/dev-workflows/README.md` (`/prompt-grill-me` bullet + companions parenthetical)
- Modify: `plugins/dev-workflows/references/feedback-emission.md` (self-contained note)
- Modify: `plugins/dev-workflows/references/grilling-technique.md` (remove operational block; keep credit)

**Interfaces:**
- Consumes: the retargeted `/prompt-grill-me` from Task 1 (docs now describe inline grilling).
- Produces: docs whose only remaining Matt references are attribution credits.

- [ ] **Step 1: `references/dependencies.md` — remove the mattpocock row, trim the superpowers row**

Replace this exact block:
```markdown
| Companion | Used by | Relationship | Fallback when absent |
|-----------|---------|--------------|----------------------|
| `mattpocock-skills` (skill `/grilling`) | `/prompt-grill-me`; the embedded grilling technique in `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design` | Recommended | `/prompt-grill-me` runtime-resolves `/grilling`, else falls back to `superpowers:brainstorming`. The grilling *technique* is embedded in `/idea` / `/create-vi` / `/create-ard` / `/specify` / `/design`, so those have no runtime dependency. |
| `superpowers` (skill `brainstorming`) | `/prompt-brainstorm`; grilling fallback | Recommended | Embedded technique; no hard dependency. |
| `dt-style-guide` (in this marketplace) | `docs-style-checker`; planning-doc style checks | Optional companion | `docs-style-checker` falls back to it when no repo-configured prose linter exists; `/epics` and `/release-notes` skip the style gate entirely if it is absent. |
```
with:
```markdown
| Companion | Used by | Relationship | Fallback when absent |
|-----------|---------|--------------|----------------------|
| `superpowers` (skill `brainstorming`) | `/prompt-brainstorm` | Recommended | Embedded technique; no hard dependency. |
| `dt-style-guide` (in this marketplace) | `docs-style-checker`; planning-doc style checks | Optional companion | `docs-style-checker` falls back to it when no repo-configured prose linter exists; `/epics` and `/release-notes` skip the style gate entirely if it is absent. |
```

- [ ] **Step 2: `README.md` — rewrite the `/prompt-grill-me` bullet**

Replace this exact block:
```markdown
- **`/prompt-grill-me <text>`** — same capture, then runtime-resolve `/grilling`
  (mattpocock-skills), **falling back to `superpowers:brainstorming` with a
  notice if mattpocock-skills is not installed**. mattpocock-skills is an
  **optional** dependency — the command degrades gracefully; there is no hard
  install-time requirement.
```
with:
```markdown
- **`/prompt-grill-me <text>`** — same capture, then grill the fix **inline** — a
  bounded one-question-at-a-time interrogation of the correction following the
  embedded grilling technique. Self-contained; no plugin dependency.
```

- [ ] **Step 3: `README.md` — drop mattpocock from the companions parenthetical**

Replace this exact block:
```markdown
dev-workflows is self-contained — no command hard-requires another plugin. Recommended companions
(`mattpocock-skills` `/grilling`, `superpowers`, `dt-style-guide`) and the external
[`jira-workitem-import`](https://github.com/ivan-gudak/jira-workitem-import) importer are documented in
```
with:
```markdown
dev-workflows is self-contained — no command hard-requires another plugin. Recommended companions
(`superpowers`, `dt-style-guide`) and the external
[`jira-workitem-import`](https://github.com/ivan-gudak/jira-workitem-import) importer are documented in
```

- [ ] **Step 4: `references/feedback-emission.md` — rewrite the self-contained note**

Replace this exact block:
```markdown
**Self-contained — no hard cross-plugin dependency.** `/prompt-brainstorm` uses
`superpowers:brainstorming`; `/prompt-grill-me` runtime-resolves `/grilling`
(mattpocock-skills) and falls back to `superpowers:brainstorming` if it is not
installed. Neither is a declared install-time dependency.
```
with:
```markdown
**Self-contained — no hard cross-plugin dependency.** `/prompt-brainstorm` uses
`superpowers:brainstorming`; `/prompt-grill-me` grills the fix inline following
the embedded grilling technique (`references/grilling-technique.md`). Neither is
a declared install-time dependency.
```

- [ ] **Step 5: `references/grilling-technique.md` — remove the operational block, keep the credit**

Delete this exact trailing block (including the blank line that precedes it):
```markdown

If `mattpocock-skills` `/grilling` is installed the user may invoke it directly (see
`${CLAUDE_PLUGIN_ROOT}/references/dependencies.md`); it is **not** a runtime dependency.
```
The file then ends at the `- **Relentless** — …` bullet. Do NOT touch line 4 ("technique adapted from mattpocock grill-me/grilling") — that credit stays.

- [ ] **Step 6: Verify only attribution credits remain**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -rinE "grill-me|pocock|mattpocock" README.md references/ commands/prompt-grill-me.md
```
Expected — matches ONLY:
- `references/grilling-technique.md` line ~4: "adapted from mattpocock grill-me/grilling" (credit — KEEP)
- `references/design-format.md` provenance: "adapted from mattpocock grill-me/grilling" (credit — KEEP)
- `commands/prompt-grill-me.md`: the `name:`/`/prompt-grill-me` self-references only (no "mattpocock"/"pocock")

There must be **zero** matches for: "runtime-resolve", "falling back", "optional dependency" tied to mattpocock, or "invoke it directly". Confirm the operational block is gone:
```bash
grep -in "may invoke it directly" references/grilling-technique.md || echo "REMOVED-OK"
grep -in "runtime-resolve" references/feedback-emission.md README.md || echo "REMOVED-OK"
```
Expected: `REMOVED-OK` for both.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/dependencies.md plugins/dev-workflows/README.md plugins/dev-workflows/references/feedback-emission.md plugins/dev-workflows/references/grilling-technique.md
git commit -m "$(cat <<'EOF'
docs(dev-workflows): drop operational mattpocock-skills references

Remove mattpocock-skills from the Recommended companions table and the
operational mentions in README, feedback-emission, and grilling-technique.
The grilling technique stays embedded; the "adapted from mattpocock"
attribution credits are retained.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Version bump (lock-step) + CHANGELOG

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (version)
- Modify: `.claude-plugin/marketplace.json` (dev-workflows entry version, line 12)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (new entry)

**Interfaces:**
- Consumes: the completed Tasks 1–2.
- Produces: v2.25.0 across both manifests + a changelog record.

- [ ] **Step 1: Bump `plugin.json`**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, replace:
```json
  "version": "2.24.0",
```
with:
```json
  "version": "2.25.0",
```
(Do NOT touch the `description` field.)

- [ ] **Step 2: Bump the dev-workflows entry in `marketplace.json`**

In `.claude-plugin/marketplace.json`, change **only line 12** (the dev-workflows entry):
```json
      "version": "2.24.0",
```
to:
```json
      "version": "2.25.0",
```
Leave lines 24 (`0.2.2`) and 36 (`0.3.1`) untouched.

- [ ] **Step 3: Add the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, insert this block immediately before the `## [2.24.0] — 2026-07-12` line:
```markdown
## [2.25.0] — 2026-07-12

### Changed

- **`/prompt-grill-me`** no longer hands off to Matt Pocock's `/grilling` skill (or the `superpowers:brainstorming` fallback). It now grills the fix **inline** — a bounded one-question-at-a-time interrogation of the correction following the embedded `references/grilling-technique.md`. Feedback capture (`emit-prompt`, `origin: prompt`) and the "never commits / never writes to a repo or the cwd" guarantees are unchanged.
- **Dropped the optional `mattpocock-skills` dependency.** Removed it from the *Recommended companions* table in `references/dependencies.md` and the operational mentions in `README.md`, `references/feedback-emission.md`, and `references/grilling-technique.md`. The grilling technique remains fully embedded; the "adapted from mattpocock grill-me/grilling" attribution is retained.

### Notes

- Closes AI-First line 87. The five authoring commands (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`) were already zero-dependency. Counts unchanged — **20** commands / **30** subagents (`/prompt-grill-me` retargeted, not removed). No-regression: `/vuln`, `/upgrade`, `jira-reader`, and the sibling plugins are untouched.

```

- [ ] **Step 4: Verify manifests parse, versions lock-step, counts + descriptions unchanged**

Run:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; d=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('plugin.json', d['version'])"
python3 -c "
import json
d=json.load(open('.claude-plugin/marketplace.json'))
def walk(o):
    if isinstance(o,list):
        for x in o: yield from walk(x)
    elif isinstance(o,dict):
        if o.get('name')=='dev-workflows': yield o
        for v in o.values(): yield from walk(v)
p=next(walk(d)); print('marketplace dev-workflows', p['version'])
"
```
Expected: both print `2.25.0`.

Version lock-step + descriptions byte-identical + counts:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "
import json
pj=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))
mp=json.load(open('.claude-plugin/marketplace.json'))
def walk(o):
    if isinstance(o,list):
        for x in o: yield from walk(x)
    elif isinstance(o,dict):
        if o.get('name')=='dev-workflows': yield o
        for v in o.values(): yield from walk(v)
me=next(walk(mp))
assert pj['version']==me['version']=='2.25.0', 'version mismatch'
assert pj['description']==me['description'], 'description drift between manifests'
assert 'Twenty slash commands' in pj['description'], 'command count-string changed'
assert 'Thirty reusable subagents' in pj['description'], 'subagent count-string changed'
print('OK versions lock-step, descriptions byte-identical, count-strings intact')
"
ls plugins/dev-workflows/commands/*.md | wc -l   # expect 20
ls plugins/dev-workflows/agents/*.md | wc -l      # expect 30
```
Expected: `OK …`, `20`, `30`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
chore(dev-workflows): release v2.25.0 — drop mattpocock-skills dependency

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final structural verification (before finish-branch)

Run from the branch tip:
```bash
cd /workspace/ihudak-claude-plugins
echo "=== files changed vs main ==="
git diff --stat main...HEAD
echo "=== siblings must be 0-line diff ==="
git diff --stat main...HEAD -- plugins/dt-style-guide plugins/obsidian-llm-wiki
echo "=== no collateral: these must be empty ==="
git diff --stat main...HEAD -- plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/commands/idea.md plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/create-ard.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md
echo "=== whole-plugin operational-Matt sweep (expect only attribution + CHANGELOG history + prompt-grill-me self-refs) ==="
grep -rinE "mattpocock|pocock|/grilling|grill-me" plugins/dev-workflows/commands plugins/dev-workflows/references plugins/dev-workflows/README.md
```
Expected: exactly 6 files changed (`commands/prompt-grill-me.md`, `references/dependencies.md`, `README.md`, `references/feedback-emission.md`, `references/grilling-technique.md`, `CHANGELOG.md`) plus the two manifests = 8 total; siblings and collateral empty; the sweep shows only the two attribution credits, `CHANGELOG.md` history, and `/prompt-grill-me` self-references.

Then hand off to **superpowers:finishing-a-development-branch** for the merge/PR choice (there is no test suite; structural verification above is the gate).

---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# SP2 Increment 3d — Docs & disambiguation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `dev-workflows` README + `/impl` dispatcher truthful — fix the stale command counts, refresh the `/impl:jira:docs` description for the shipped 3a/3b/3c behavior, complete the dispatcher's command list + a "which docs command?" note, and clarify the `obsidian`/`plain_dir` write contexts as defensive guards.

**Architecture:** Pure documentation/wording edits to three files (`README.md`, `commands/impl.md`, `commands/impl/jira/docs.md`); no command behavior changes. Two items (AI-Containers section, Vale-fallback note) are verified already-present. A patch release ships it as v1.14.1.

**Tech Stack:** Markdown command/README files, JSON manifests. **No test framework** — verification is structural (`grep` for the new/old strings, `python3` JSON parse). Those checks ARE the test cycle.

## Global Constraints

- Plugin repo `/workspace/ihudak-claude-plugins`; plugin under `plugins/dev-workflows/`. Plugin `main` is at `fa79035`, v1.14.0.
- Work on a branch off `origin/main`: **`ivgu/NOISSUE-dev-workflows-docs-disambiguation`**. Never implement on `main`.
- **`marketplace.json` version is at `plugins[0].version`, NOT top-level.** `plugin.json` version is the top-level `"version"`.
- This is a **patch** release **v1.14.1** (docs/wording only — no new capability).
- Commit messages (in the PLUGIN repo) end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Stage only the files each task names with `git add <path>`. Never `git add -A`/`.`; never stage `.superpowers/`, `.docstack`, or unrelated files.
- **No command behavior changes.** The `obsidian`/`plain_dir` edit is wording-only; keep the taxonomy and its NEVER-branch/commit guards.
- The AI-Containers repo link is `https://github.com/ihudak/ai-containers` (public github.com). Any AI-Containers mention must use it.
- **Out of scope (do NOT do here):** the per-step Sonnet↔Opus model-delegation design; the command-namespace refactor; the comprehensive 3a–3d Opus pipeline review. All deferred to post-3d (see the spec's Deferred work).
- **Verified facts** (do not re-derive): of the six `/impl:*` commands, **five run the Phase 1.5 variable classification** (`/impl:code`, `/impl:docs` [SIMPLE/MODERATE only], `/impl:jira:docs` [typically SIGNIFICANT], `/impl:jira:epics`, `/impl:jira:release-notes`); **`/impl:docs:profile` runs at a fixed SIGNIFICANT** (no Phase 1.5). Counting all workflow commands (incl. `/vuln`, `/upgrade`) there are **eight**, plus the `/impl` dispatcher.

---

## File Structure

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/README.md` | Intro count fix; line-17 classification sentence; `/impl:jira:docs` row refresh (3a/3b/3c); branch/push line; "which docs command?" note; verify items 1 & 2 present. | 1 |
| `plugins/dev-workflows/commands/impl.md` | Dispatcher: add the missing `/impl:docs:profile` + `/impl:jira:release-notes` rows + frontmatter list. | 1 |
| `plugins/dev-workflows/commands/impl/jira/docs.md` | Phase 0 step 7: one-line defensive-guard clarification for `obsidian`/`plain_dir`. | 1 |
| `plugin.json`, `marketplace.json`, `CHANGELOG.md` | Patch release v1.14.1. | 2 |

---

## Task 1: Documentation accuracy edits (README + dispatcher + docs.md)

**Files:**
- Modify: `plugins/dev-workflows/README.md`
- Modify: `plugins/dev-workflows/commands/impl.md`
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md`

**Interfaces:**
- Consumes: nothing (doc edits).
- Produces: the corrected README + dispatcher + the defensive-guard note. Task 2 (release) describes these in the CHANGELOG.

- [ ] **Step 1: Verify items 1 & 2 are already satisfied (no edit expected)**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
grep -q "ihudak/ai-containers](https://github.com/ihudak/ai-containers)" plugins/dev-workflows/README.md && echo "OK  AI-Containers section + link present (item 1)" || echo "GAP item 1" && \
grep -q "falls back to the repo's \`package.json\`" plugins/dev-workflows/README.md && grep -q "NOT_CONFIGURED\` is returned only when no linter of any kind is available" plugins/dev-workflows/README.md && echo "OK  Vale-fallback note present (item 2)" || echo "GAP item 2"
```
Expected: two `OK` lines. If a `GAP` appears, STOP and report — the spec assumed both are present.

- [ ] **Step 2: Fix the intro command count (README line 3)**

Replace this exact line:
```
Six Claude Code slash commands for structured implementation, one-shot doc edits, docs-repo profile scanning, Jira-driven feature documentation and Epic drafting, vulnerability remediation, and dependency upgrades — with Opus-backed risk planning, post-implementation code review, test regression detection, and prose-style / Opus doc review gates.
```
with:
```
Eight workflow slash commands — plus an `/impl` dispatcher — for structured implementation, one-shot doc edits, docs-repo profile scanning, Jira-driven feature documentation, Epic drafting, release-notes drafting, vulnerability remediation, and dependency upgrades — with Opus-backed risk planning, post-implementation code review, test regression detection, and prose-style / Opus doc review gates.
```

- [ ] **Step 3: Refresh the `/impl:jira:docs` README row (item 6, line 13)**

In `plugins/dev-workflows/README.md`, the `/impl:jira:docs` table row currently ends with:
```
... When `image_policy` is `cdn_upload_required`, an interactive CDN handoff lets the user paste links immediately (real URLs substituted inline) with the existing async fallback when deferred. |
```
Replace that ending with (append the new sentences before the closing `|`):
```
... When `image_policy` is `cdn_upload_required`, an interactive CDN handoff lets the user paste links immediately (real URLs substituted inline) with the existing async fallback when deferred. A `saas`/`managed` run routes per space and protects the other product's render with `{{#if project}}` conditionals or override-copies (Phase 6). Phase 6.8 then verifies the docs build and render (build + opt-in best-effort dev-server smoke-check + a pages-to-visit table), and Phase 8.5 finishes the run — squash, opt-in `git push`, and a host-aware copy-paste PR draft (never an API call). |
```

- [ ] **Step 4: Fix the classification sentence (item 4, README line 17)**

Replace this exact line:
```
All five `/impl:*` workflow commands classify tasks as SIMPLE / MODERATE / SIGNIFICANT / HIGH-RISK before acting (the `/impl` dispatcher does not — it prints help and stops). The three code-oriented commands (`/impl:code`, `/vuln`, `/upgrade`) also:
```
with:
```
Five of the six `/impl:*` commands — `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, and `/impl:jira:release-notes` — classify tasks as SIMPLE / MODERATE / SIGNIFICANT / HIGH-RISK before acting (`/impl:docs` only ever lands SIMPLE or MODERATE; `/impl:jira:docs` is typically SIGNIFICANT). `/impl:docs:profile` runs at a fixed SIGNIFICANT (no per-task classification), and the `/impl` dispatcher does not classify — it prints help and stops. The three code-oriented commands (`/impl:code`, `/vuln`, `/upgrade`) also:
```

- [ ] **Step 5: Add the "which docs command?" note (item 3, README — after the commands table)**

In `plugins/dev-workflows/README.md`, immediately AFTER the `/impl:jira:release-notes` table row (the last row of the Commands table) and BEFORE the line that now begins `Five of the six `/impl:*` commands`, insert this paragraph (with a blank line on each side):
```
**Which docs command?** `/impl:docs` is for one-shot manual doc edits (no Jira, no branch/commit). `/impl:jira:docs` is the Jira-driven feature-documentation workflow end to end (resolves repos/specs, writes into the docs repo, branches/commits, and — opt-in — squashes, pushes, and drafts a PR). `/impl:docs:profile` is a one-time profiler that generates a repo's `.dev-workflows/docs-profile.yml` (consumed by `/impl:jira:docs`).
```

- [ ] **Step 6: Update the branch/push line (item 6, README line ~110)**

Replace this exact line:
```
`/impl:docs`, `/impl:jira:docs`, and `/impl:jira:epics` never run tests and never touch production code. Only `/impl:jira:docs` can create a branch (opt-in at plan approval, and only when a docs repo is detected).
```
with:
```
`/impl:docs`, `/impl:jira:docs`, and `/impl:jira:epics` never run tests and never touch production code. Only `/impl:jira:docs` can create a branch (opt-in at plan approval, and only when a docs repo is detected) — and, also opt-in, squash + `git push` it and emit a copy-paste PR draft (it never opens the PR via an API).
```

- [ ] **Step 7: Complete the `/impl` dispatcher (item 3, `commands/impl.md`)**

7a. In `commands/impl.md`, replace the frontmatter description line:
```
description: Help and dispatcher for /impl variants. Prints available subcommands (/impl:code, /impl:docs, /impl:jira:docs, /impl:jira:epics) and usage guidance. Does not run any workflow itself.
```
with:
```
description: Help and dispatcher for /impl variants. Prints available subcommands (/impl:code, /impl:docs, /impl:docs:profile, /impl:jira:docs, /impl:jira:epics, /impl:jira:release-notes) and usage guidance. Does not run any workflow itself.
```

7b. In the `#### `/impl:*` variants` table, the last row is the `/impl:jira:epics` row:
```
| `/impl:jira:epics <VI-KEY>` | Jira-driven **Epic drafting** — reads a Value Increment plus its existing Epics, optionally scans code for reusable capabilities, writes child Epic drafts into the vault, gated by Opus `epic-reviewer`. Never branches or commits. | `/impl:jira:epics MGD-2423` |
```
Immediately AFTER it, add these two rows:
```
| `/impl:docs:profile` | Generate or refresh a docs repo's profile (`.dev-workflows/docs-profile.yml` + CLAUDE.md guidance) as a reviewable PR. One-time setup, consumed by `/impl:jira:docs`. | `/impl:docs:profile` |
| `/impl:jira:release-notes <KEY>` | Jira-driven **release-notes drafting** — renders the dynatrace-docs authored release-notes body from a ticket and writes a persistent draft to paste into Jira. Never branches or commits. | `/impl:jira:release-notes MGD-2423` |
```

- [ ] **Step 8: Add the defensive-guard clarification (item 5, `commands/impl/jira/docs.md` Phase 0 step 7)**

In `plugins/dev-workflows/commands/impl/jira/docs.md`, Phase 0 step 7 ends with `Else context = \`plain_dir\`.`. Append this sentence to the end of that step (same paragraph):
```
 In a normal run, Phase 0's docs-repo resolution (steps 3–4) yields a real docs repo (`docs_repo`) or a user-confirmed `non_docs_repo`; `obsidian` and `plain_dir` are **defensive guards** (they forbid branch/commit) rather than expected write targets.
```

- [ ] **Step 9: Verify all edits landed and the docs are internally consistent**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import sys
rm = open("plugins/dev-workflows/README.md").read()
im = open("plugins/dev-workflows/commands/impl.md").read()
dm = open("plugins/dev-workflows/commands/impl/jira/docs.md").read()
checks = {
  "intro Eight":            "Eight workflow slash commands — plus an `/impl` dispatcher" in rm,
  "intro no stale Six":     "Six Claude Code slash commands" not in rm,
  "row 3a/3b/3c refresh":   "protects the other product's render" in rm and "Phase 6.8 then verifies" in rm and "Phase 8.5 finishes the run" in rm,
  "classification sentence":"Five of the six `/impl:*` commands" in rm and "`/impl:docs:profile` runs at a fixed SIGNIFICANT" in rm,
  "no stale All five":      "All five `/impl:*` workflow commands classify" not in rm,
  "which-docs note":        "**Which docs command?**" in rm,
  "branch/push line":       "squash + `git push` it and emit a copy-paste PR draft" in rm,
  "AI-Containers link kept":"https://github.com/ihudak/ai-containers" in rm,
  "dispatcher frontmatter": "/impl:docs:profile, /impl:jira:docs, /impl:jira:epics, /impl:jira:release-notes) and usage guidance" in im,
  "dispatcher profile row": "| `/impl:docs:profile` | Generate or refresh a docs repo's profile" in im,
  "dispatcher relnotes row":"| `/impl:jira:release-notes <KEY>` | Jira-driven **release-notes drafting**" in im,
  "docs.md defensive guard":"are **defensive guards** (they forbid branch/commit)" in dm,
}
miss=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(("OK  " if v else "MISS")+" "+k)
sys.exit(0 if not miss else 1)
PY
```
Expected: every check `OK`, exit 0.

- [ ] **Step 10: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/README.md \
        plugins/dev-workflows/commands/impl.md \
        plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "$(cat <<'EOF'
NOISSUE dev-workflows docs: fix command counts, refresh impl:jira:docs description, complete dispatcher, clarify defensive write-contexts

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Release v1.14.1 (manifests + CHANGELOG)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: the doc edits from Task 1.
- Produces: a released v1.14.1.

- [ ] **Step 1: Bump `plugin.json` (top-level version)**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, change the top-level `"version"` from `"1.14.0"` to `"1.14.1"`.

- [ ] **Step 2: Bump `marketplace.json` (plugins[0].version — NOT top-level)**

In `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`, change the dev-workflows entry's version under `plugins[0].version` from `1.14.0` to `1.14.1`. Verify you edited `plugins[0].version`, not any top-level field.

- [ ] **Step 3: Add the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, insert a new section immediately above `## [1.14.0] — 2026-06-27`:
```markdown
## [1.14.1] — 2026-06-28

### Fixed
- **README & `/impl` dispatcher accuracy (docs-only).** Corrected the stale slash-command counts (intro now reads eight workflow commands plus the `/impl` dispatcher; the classification sentence now names the five `/impl:*` commands that run per-task SIMPLE/MODERATE/SIGNIFICANT/HIGH-RISK classification and notes that `/impl:docs:profile` runs at a fixed SIGNIFICANT). Refreshed the `/impl:jira:docs` description to cover multi-space write safety, render verification (Phase 6.8), and finish & handoff (Phase 8.5 — squash, opt-in push, copy-paste PR draft). Added the missing `/impl:docs:profile` and `/impl:jira:release-notes` rows to the `/impl` dispatcher and a "which docs command?" note. Clarified that the `obsidian`/`plain_dir` write contexts are defensive guards (Phase 0 normally resolves a real docs repo). No command behavior changed.
```

- [ ] **Step 4: Verify the manifests parse and carry 1.14.1, and the CHANGELOG entry exists**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import json,sys
pj=json.load(open("plugins/dev-workflows/.claude-plugin/plugin.json"))
mk=json.load(open(".claude-plugin/marketplace.json"))
ok_pj = pj.get("version")=="1.14.1"
mkv = mk["plugins"][0].get("version")
ok_mk = mkv=="1.14.1"
print(("OK  " if ok_pj else "MISS")+f" plugin.json top-level version = {pj.get('version')}")
print(("OK  " if ok_mk else "MISS")+f" marketplace.json plugins[0].version = {mkv}")
cl=open("plugins/dev-workflows/CHANGELOG.md").read()
ok_cl = "## [1.14.1] — 2026-06-28" in cl and "which docs command?" in cl
print(("OK  " if ok_cl else "MISS")+" CHANGELOG [1.14.1] entry")
sys.exit(0 if all([ok_pj,ok_mk,ok_cl]) else 1)
PY
```
Expected: three `OK` lines, exit 0.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json \
        plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
NOISSUE Release dev-workflows v1.14.1 — docs & disambiguation (Increment 3d)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Spec coverage** (against `spec/2026-06-28-sp2-increment3d-docs-and-disambiguation-design.md`):
- Item 1 (AI-Containers) verify-only → Task 1 Step 1. ✅
- Item 2 (Vale note) verify-only → Task 1 Step 1. ✅
- Item 3 (which-docs disambiguation: README note + dispatcher completion) → Task 1 Steps 5, 7. ✅
- Item 4 ("All five" count, verify-then-state + intro count) → Task 1 Steps 2, 4. ✅
- Item 5 (obsidian/plain_dir defensive-guard wording) → Task 1 Step 8. ✅
- Item 6 (`/impl:jira:docs` row + branch/push line refresh) → Task 1 Steps 3, 6. ✅
- Patch release v1.14.1 → Task 2. ✅
- Deferred work (model-delegation, namespace refactor, comprehensive Opus review) → excluded per Global Constraints. ✅

**2. Placeholder scan:** No "TBD"/"TODO"/"fill in". The `<VI-KEY>`/`<KEY>`/`<description>` strings are existing command-signature placeholders in the dispatcher table (intended), not plan gaps. ✅

**3. Type/name consistency:** The verified facts (five classifiers; eight workflow commands) are stated identically in the Global Constraints, the README line-17 replacement (Step 4), the intro (Step 2), and the CHANGELOG (Task 2 Step 3). The AI-Containers URL is the same everywhere. The dispatcher rows match the README commands-table descriptions. ✅

**Model guidance for execution:** Task 1 — standard model (transcription of supplied blocks + a verify step; the content is fully specified). Task 2 — cheapest tier; reviewer confirms `marketplace.json` at `plugins[0].version`. Final whole-branch review — most capable model. (Separately, the user has scheduled a comprehensive 3a–3d Opus pipeline review as deferred follow-up work — that is NOT this increment's whole-branch review.)

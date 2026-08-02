---
tags:
  - tasks-exclude
---
# `.obsidian` vault-check revisit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drop the Obsidian-specific `.obsidian/` requirement from the four personal-store write-gates so they trust `$VAULT_PATH` (set + existing dir + writable), while preserving the "never write to the wrong place" guard.

**Architecture:** Pure text edits to four in-use files (one interactive command + three emission references), plus a version-only manifest bump and a CHANGELOG entry. This is a *loosening* — existing `.obsidian/` vaults are still writable directories and behave identically. No new files, no new command/subagent.

**Tech Stack:** Markdown command/reference files + JSON manifests. NO test framework, NO husky/prettier hook — verification is STRUCTURAL (grep anchors, `python3 -c json.load`, `git diff --stat`).

## Global Constraints

- Target repo: `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`.
- Version lock-step: `plugins/dev-workflows/.claude-plugin/plugin.json` **and** the `dev-workflows` entry in root `.claude-plugin/marketplace.json` both go `2.19.0` → `2.20.0`.
- Manifest descriptions stay byte-identical (no new command/subagent — do NOT edit the description strings).
- Commit trailer, exactly: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Never `git add -A`** — stage only named files.
- Commit / push only when the user asks. This plan commits locally per task; finish-branch presents merge/PR options. Do NOT push.
- Branch `ivgu/NOISSUE-obsidian-vault-check`; ff-merge to `main`; delete branch.
- No user name in any file.
- **In scope:** the 4 Category-A write-gates only. **Out of scope (must stay byte-identical):** `commands/document.md` (Category-B defensive git-forbid guard), the `references/followup-emission.md` line-27 `.obsidian/copilot/tag-index.md` path (Category-C), `README.md`, `/vuln`, `/upgrade`, sibling plugins `dt-style-guide` 0.2.2 + `obsidian-llm-wiki` 0.3.1.
- The new gate wording everywhere: `$VAULT_PATH` **set** + an **existing directory** + **writable**.

---

### Task 1: Loosen the four personal-store write-gates

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (Phase 0, step 1, ~lines 21-23)
- Modify: `plugins/dev-workflows/references/feedback-emission.md` (tier 3, ~lines 102-104)
- Modify: `plugins/dev-workflows/references/cost-emission.md` (tier 3, ~lines 278-279)
- Modify: `plugins/dev-workflows/references/followup-emission.md` (§4 `vault_writable` ~lines 86-87; §5 notice ~line 109)

**Interfaces:**
- Produces: the four gates all read `$VAULT_PATH` set + existing dir + writable (no `.obsidian/`); one softened followup notice.

- [ ] **Step 1: Create the branch (clean tree first)**

```bash
cd /workspace/ihudak-claude-plugins
git status --porcelain   # expect empty
git checkout main && git checkout -b ivgu/NOISSUE-obsidian-vault-check
git rev-parse --abbrev-ref HEAD   # expect ivgu/NOISSUE-obsidian-vault-check
```

- [ ] **Step 2: Re-confirm anchors are current**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n "personal store (\`\$VAULT_PATH/.obsidian/\` is a directory" commands/idea.md
grep -n "\`\$VAULT_PATH/.obsidian/\` is a directory \*\*and\*\*" references/feedback-emission.md
grep -n "\`\$VAULT_PATH/.obsidian/\` a writable dir" references/cost-emission.md
grep -n "\`\$VAULT_PATH/.obsidian/\` is a directory \*\*and\*\* the path is writable" references/followup-emission.md
grep -n "No writable Obsidian vault" references/followup-emission.md
```
Expected: each prints exactly one line. If any differs, STOP and re-capture.

- [ ] **Step 3: `commands/idea.md` — drop the `.obsidian/` clause in Phase 0**

Replace:
```
1. **Validate `$VAULT_PATH`.** It must be **set**, an **existing directory**, look like the user's
   personal store (`$VAULT_PATH/.obsidian/` is a directory — the same marker the specs-first ladder
   uses), and be **writable**. If any check fails, STOP and offer:
```
With:
```
1. **Validate `$VAULT_PATH`.** It must be **set**, an **existing directory**, and **writable** — the
   env var is the user's explicit declaration of their personal store; the plugin trusts it and does
   NOT require an Obsidian `.obsidian/` marker. If any check fails, STOP and offer:
```

- [ ] **Step 4: `references/feedback-emission.md` — tier 3**

Replace:
```
   (`$VAULT_PATH` set **and** `$VAULT_PATH/.obsidian/` is a directory **and**
   writable) → `$VAULT_PATH/dev-workflows/feedback/<KEY>-feedback.md`, with a
```
With:
```
   (`$VAULT_PATH` set **and** an existing directory **and**
   writable) → `$VAULT_PATH/dev-workflows/feedback/<KEY>-feedback.md`, with a
```

- [ ] **Step 5: `references/cost-emission.md` — tier 3**

Replace:
```
3. No `$SPECS_PATH`, vault writable (`$VAULT_PATH` set **and**
   `$VAULT_PATH/.obsidian/` a writable dir) ->
```
With:
```
3. No `$SPECS_PATH`, vault writable (`$VAULT_PATH` set **and**
   an existing, writable dir) ->
```

- [ ] **Step 6: `references/followup-emission.md` — §4 gate**

Replace:
```
most-durable first. `vault_writable` = `$VAULT_PATH` is set **and**
`$VAULT_PATH/.obsidian/` is a directory **and** the path is writable.
```
With:
```
most-durable first. `vault_writable` = `$VAULT_PATH` is set **and**
is an existing directory **and** the path is writable.
```

- [ ] **Step 7: `references/followup-emission.md` — soften the §5 notice**

Replace:
```
  `⚠ No writable Obsidian vault — N follow-ups written to <path>`;
```
With:
```
  `⚠ No writable vault — N follow-ups written to <path>`;
```
(Do NOT touch the following tier-4 line `⚠ No writable vault or specs dir …` — it already reads "vault".)

- [ ] **Step 8: Verify structurally**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "=== no .obsidian in the 3 gate spots + idea (only the Category-C tag-index should remain) ==="
grep -rn "\.obsidian" commands/idea.md references/feedback-emission.md references/cost-emission.md references/followup-emission.md
echo "=== new wording present at each gate ==="
grep -n "does NOT require an Obsidian" commands/idea.md
grep -n "set \*\*and\*\* an existing directory \*\*and\*\*" references/feedback-emission.md
grep -n "an existing, writable dir) ->" references/cost-emission.md
grep -n "is an existing directory \*\*and\*\* the path is writable" references/followup-emission.md
echo "=== notice softened (expect 0 for the old text) ==="
grep -c "No writable Obsidian vault" references/followup-emission.md
```
Expected: the `.obsidian` grep prints **only** `references/followup-emission.md:27:…copilot/tag-index.md` (Category-C, intentionally kept) — no other `.obsidian` lines; the four new-wording greps each print one line; the "No writable Obsidian vault" count is **0**.

- [ ] **Step 9: Confirm out-of-scope files untouched so far**

```bash
cd /workspace/ihudak-claude-plugins
git diff --stat main -- plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md
```
Expected: empty (no Category-B / maintenance-command changes).

- [ ] **Step 10: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md plugins/dev-workflows/references/feedback-emission.md plugins/dev-workflows/references/cost-emission.md plugins/dev-workflows/references/followup-emission.md
git commit -m "feat(dev-workflows): trust \$VAULT_PATH for the personal-store write-gate (drop .obsidian/ proxy)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: v2.20.0 packaging + final no-regression sweep

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json:3`
- Modify: `.claude-plugin/marketplace.json` (the `dev-workflows` entry version — unique `"version": "2.19.0"`)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend before `## [2.19.0]`)

**Interfaces:**
- Consumes: Task 1's edits (the whole change must be present for the sweep).

- [ ] **Step 1: Bump `plugin.json`**

Replace (in `plugins/dev-workflows/.claude-plugin/plugin.json`):
```
  "version": "2.19.0",
```
With:
```
  "version": "2.20.0",
```

- [ ] **Step 2: Bump the `dev-workflows` version in `marketplace.json`**

First confirm the string is unique to the dev-workflows entry, then edit:
```bash
cd /workspace/ihudak-claude-plugins && grep -n '"version": "2.19.0"' .claude-plugin/marketplace.json
```
Expected: exactly one line (the dev-workflows entry). Replace:
```
      "version": "2.19.0",
```
With:
```
      "version": "2.20.0",
```

- [ ] **Step 3: Prepend the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, replace:
```
## [2.19.0] — 2026-07-10
```
With:
```
## [2.20.0] — 2026-07-10

### Changed

- **The personal-store write-gate no longer requires an Obsidian `.obsidian/` directory.** The four vault write-gates — `/idea` Phase 0, and the `$VAULT_PATH`-fallback tiers of `references/feedback-emission.md`, `references/cost-emission.md`, and `references/followup-emission.md` — now accept `$VAULT_PATH` when it is **set + an existing directory + writable**, dropping the `.obsidian/`-directory proxy. Setting `$VAULT_PATH` is the user's explicit declaration of their personal store, and the rest of the plugin (`/release-notes`, `/epics`, `/document` staging) already trusted it on "set" alone — so this makes the four outlier gates consistent and lets non-Obsidian personal stores work. The "never write to the wrong place" guard is preserved: `$VAULT_PATH` must be set + exist + be writable, writes always land in a namespaced subdir (`$VAULT_PATH/dev-workflows/…`, `$VAULT_PATH/Projects/…`), and the NEVER-cwd rule is untouched. The `/followup` no-vault notice is softened `⚠ No writable Obsidian vault` → `⚠ No writable vault`. **No-regression:** existing `.obsidian/` vaults are still writable directories, so they behave identically; `/document`'s defensive `.obsidian/` git-forbid guard and the `.obsidian/copilot/` tag-index path are unchanged, and `/vuln`, `/upgrade`, and sibling plugins are untouched. No new command or subagent (version-only manifest bump).

## [2.19.0] — 2026-07-10
```

- [ ] **Step 4: Verify manifests parse + versions match + descriptions byte-identical**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; d=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); assert d['version']=='2.20.0', d['version']; assert 'Nineteen slash commands' in d['description']; assert 'Twenty-nine reusable subagents' in d['description']; print('plugin.json OK', d['version'])"
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); e=[p for p in m['plugins'] if p['name']=='dev-workflows'][0]; assert e['version']=='2.20.0', e['version']; print('marketplace OK', e['version'])"
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); d=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); e=[p for p in m['plugins'] if p['name']=='dev-workflows'][0]; assert e['description']==d['description'], 'DESCRIPTIONS DIFFER'; print('descriptions byte-identical')"
```
Expected: three OK lines; no assertion errors.

- [ ] **Step 5: Final no-regression sweep**

```bash
cd /workspace/ihudak-claude-plugins
echo "=== out-of-scope files untouched (expect empty) ==="
git diff --stat main -- plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md
echo "=== siblings untouched (expect empty) ==="
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki
echo "=== README untouched (expect empty) ==="
git diff --stat main -- plugins/dev-workflows/README.md
echo "=== full change surface (expect 7 files) ==="
git diff --stat main
```
Expected: the document/vuln/upgrade, sibling, and README diffs are empty; `git diff --stat main` lists exactly 7 files (idea.md, feedback-emission.md, cost-emission.md, followup-emission.md, plugin.json, marketplace.json, CHANGELOG.md).

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(dev-workflows): v2.20.0 — personal-store gate no longer requires .obsidian/

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## After all tasks

Announce and run **superpowers:finishing-a-development-branch**. No test suite — structural verification (grep anchors, `python3 json.load`, `git diff --stat`) stands in and is green. Present the merge/PR options and let the user choose; do NOT push unless the user asks.

## Self-review (author checklist — completed)

- **Spec coverage:** 4 write-gate edits (Task 1 Steps 3-6) ✓; softened followup notice (Task 1 Step 7) ✓; version lock-step + CHANGELOG (Task 2) ✓; no README change (confirmed empty in Task 2 Step 5) ✓; no-regression for document.md/vuln/upgrade/siblings verified (Task 1 Step 9 + Task 2 Step 5) ✓; Category-C tag-index intentionally retained and asserted (Task 1 Step 8) ✓.
- **Placeholder scan:** none — every edit shows exact old/new text and exact verification commands.
- **Consistency:** the new gate wording ("set + existing directory + writable") is used identically across all four sites; version `2.20.0` and the count strings ("Nineteen"/"Twenty-nine") are consistent throughout; the 7-file surface matches the spec's file list.

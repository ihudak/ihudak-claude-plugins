# mgd-claude-plugins Marketplace Clone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Populate the empty repo at `/Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins` with a rebranded copy of the `ihudak-claude-plugins` Claude Code plugin marketplace ("Dynatrace Managed internal", repo name `mgd-claude-plugins`).

**Architecture:** Copy git-tracked files only (via `git archive`) into the empty target, then apply one ordered `sed` script for all token + identity rewrites, overwrite the four LICENSE files with an internal notice, validate JSON, and verify no stray source-branding tokens remain while external repo references are preserved.

**Tech Stack:** bash, git, BSD `sed` (macOS — `sed -i ''`), `find`/`xargs -0`, `python3 -m json.tool` for JSON validation.

**Conventions used below:**
- `SRC` = `/Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins`
- `DST` = `/Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins`
- All `sed`/`grep`/`find` commands run **inside `DST`** unless stated otherwise.

**Spec:** `docs/superpowers/specs/2026-06-15-mgd-marketplace-clone-design.md`

---

### Task 1: Copy tracked files into the target

**Files:**
- Source tree (read): all git-tracked files under `SRC`
- Target tree (create): mirror under `DST` (excluding `.git`)

- [ ] **Step 1: Confirm source tree is clean and target is empty**

Run:
```bash
git -C /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins status --porcelain
ls -A /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
```
Expected: first command prints nothing (clean); second prints only `.git`.

- [ ] **Step 2: Copy tracked files from source HEAD into target**

Run:
```bash
git -C /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins archive HEAD \
  | tar -x -C /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
```
This copies only tracked files; `.git/`, `.ai-containers/`, `.agent-discovery/`, `.idea/`, and `settings*.local.json` are excluded automatically.

- [ ] **Step 3: Verify the copied file set matches the source's tracked files**

Run:
```bash
diff \
  <(git -C /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins ls-files | sort) \
  <(cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins && find . -type f -not -path './.git/*' | sed 's|^\./||' | sort)
```
Expected: no output (identical file lists).

- [ ] **Step 4: Confirm the target's git remote is intact and untouched**

Run:
```bash
git -C /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins remote -v
```
Expected: `origin  git@github.com:Dynatrace-Internal/mgd-claude-plugins.git` (fetch and push).

No commit in this task — the working tree is left for subsequent rename tasks.

---

### Task 2: Write the rename `sed` script

**Files:**
- Create: `/tmp/mgd-rename.sed`

Using a script file (not inline `-e`) avoids shell-quoting problems with the apostrophe in `Ivan Gudak's` and keeps the replacement **order** explicit. Order is load-bearing: owner-qualified URLs are rewritten before the bare repo token, and `Ivan Gudak's private` is rewritten before the bare `Ivan Gudak`.

- [ ] **Step 1: Write the sed script**

Write this exact content to `/tmp/mgd-rename.sed`:
```sed
s|github-ig\.com|github.com|g
s|ihudak/ihudak-claude-plugins|Dynatrace-Internal/mgd-claude-plugins|g
s|ihudak-claude-plugins|mgd-claude-plugins|g
s|ihudak-plugins|mgd-plugins|g
s|Ivan Gudak's private|Dynatrace Managed internal|g
s|A private Claude Code plugin marketplace|A Dynatrace Managed internal Claude Code plugin marketplace|g
s|Ivan Gudak|Dynatrace Managed|g
s|Ivan's feedback|maintainer feedback|g
s|Ivan feedback|maintainer feedback|g
s|"license": "MIT"|"license": "UNLICENSED"|g
```

- [ ] **Step 2: Verify the script has exactly 10 substitution lines**

Run:
```bash
grep -c '^s|' /tmp/mgd-rename.sed
```
Expected: `10`

**Why each line, and why this order:**
- `github-ig.com` → `github.com`: normalize the SSH host alias (appears only in CLAUDE.md's origin line).
- `ihudak/ihudak-claude-plugins` → `Dynatrace-Internal/mgd-claude-plugins`: owner+repo together — handles every web URL and the now-normalized SSH URL. Leaves external `ihudak/ai-containers` and `ihudak/ihudak-copilot-plugins` owners untouched.
- `ihudak-claude-plugins` → `mgd-claude-plugins`: remaining bare tokens — the `@ihudak-claude-plugins` data-path token (~100 hits), README title, backtick text.
- `ihudak-plugins` → `mgd-plugins`: marketplace `name` and install/reinstall commands. Not a substring of `ihudak-copilot-plugins`, so that external name is safe.
- `Ivan Gudak's private` → `Dynatrace Managed internal`: before the bare-name rule, or it would never match.
- `A private Claude Code plugin marketplace` → prefixed form: CLAUDE.md line 7.
- `Ivan Gudak` → `Dynatrace Managed`: remaining author/owner names. Does **not** match the lowercase-dotted email `ivan.gudak@dynatrace.com`.
- `Ivan's feedback` / `Ivan feedback` → `maintainer feedback`: two historical spec mentions.
- `"license": "MIT"` → `"UNLICENSED"`: the three plugin.json license fields (exact-string match; root LICENSE handled separately in Task 4).

---

### Task 3: Apply the rename script across the target tree

**Files:**
- Modify: every text file under `DST` (excluding `.git/`)

- [ ] **Step 1: Apply the sed script to all files**

Run (inside `DST`):
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
find . -type f -not -path './.git/*' -print0 | xargs -0 sed -i '' -f /tmp/mgd-rename.sed
```

- [ ] **Step 2: Verify no migrated-repo branding tokens remain**

Run:
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
grep -rIn --exclude-dir=.git -e 'ihudak-claude-plugins' -e 'ihudak-plugins' -e 'Ivan Gudak' -e 'github-ig' . ; echo "exit:$?"
```
Expected: no match lines, and `exit:1` (grep found nothing).

- [ ] **Step 3: Verify external repo references are preserved (and unchanged in count vs source)**

Run:
```bash
echo -n "DST ai-containers:   "; grep -rI --exclude-dir=.git -c 'ihudak/ai-containers' /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins | awk -F: '{s+=$2} END{print s}'
echo -n "SRC ai-containers:   "; git -C /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins grep -c 'ihudak/ai-containers' | awk -F: '{s+=$2} END{print s}'
echo -n "DST copilot-plugins: "; grep -rI --exclude-dir=.git -c 'ihudak-copilot-plugins' /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins | awk -F: '{s+=$2} END{print s}'
echo -n "SRC copilot-plugins: "; git -C /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins grep -c 'ihudak-copilot-plugins' | awk -F: '{s+=$2} END{print s}'
```
Expected: DST and SRC counts match for both (ai-containers: 8; copilot-plugins: 2).

- [ ] **Step 4: Verify the contact email was preserved**

Run:
```bash
grep -rI --exclude-dir=.git -l 'ivan.gudak@dynatrace.com' /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins | wc -l
```
Expected: `7` (4 author blocks in marketplace.json + 3 plugin.json files = the same files that had it in source).

- [ ] **Step 5: Verify the migrated repo's new URLs are present and correct**

Run:
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
grep -rIn --exclude-dir=.git 'Dynatrace-Internal/mgd-claude-plugins' . | head
grep -rIn --exclude-dir=.git '@mgd-claude-plugins' . | wc -l
```
Expected: web/SSH URLs show `github.com/Dynatrace-Internal/mgd-claude-plugins`; the `@mgd-claude-plugins` data-path token count is non-zero (~100).

---

### Task 4: Replace the LICENSE files with the internal notice

**Files:**
- Modify: `LICENSE`, `plugins/dev-workflows/LICENSE`, `plugins/dt-style-guide/LICENSE`, `plugins/obsidian-llm-wiki/LICENSE`

- [ ] **Step 1: Write the internal notice to all four LICENSE files**

Run (inside `DST`):
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
read -r -d '' NOTICE <<'EOF'
Copyright (c) 2026 Dynatrace LLC

Dynatrace internal — all rights reserved.
This software is confidential and proprietary to Dynatrace.
Unauthorized copying, distribution, or use outside Dynatrace is prohibited.
EOF
for f in LICENSE plugins/dev-workflows/LICENSE plugins/dt-style-guide/LICENSE plugins/obsidian-llm-wiki/LICENSE; do
  printf '%s\n' "$NOTICE" > "$f"
done
```

- [ ] **Step 2: Verify all four files contain the notice and no MIT text remains**

Run:
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
grep -rIl 'Dynatrace internal — all rights reserved' LICENSE plugins/*/LICENSE | wc -l
grep -rI 'Permission is hereby granted' LICENSE plugins/*/LICENSE ; echo "exit:$?"
```
Expected: first prints `4`; second prints no lines with `exit:1` (no MIT boilerplate left).

- [ ] **Step 3: Verify the three plugin.json license fields are now UNLICENSED**

Run:
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
grep -rI '"license"' plugins/*/.claude-plugin/plugin.json
```
Expected: all three show `"license": "UNLICENSED"`.

---

### Task 5: Validate JSON and do a final consistency sweep

**Files:**
- Read: `.claude-plugin/marketplace.json`, `plugins/*/.claude-plugin/plugin.json`

- [ ] **Step 1: Validate every JSON file parses**

Run (inside `DST`):
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
for f in .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json; do
  python3 -m json.tool "$f" > /dev/null && echo "OK  $f" || echo "BAD $f"
done
```
Expected: `OK` for all four files.

- [ ] **Step 2: Confirm marketplace name and owner are rebranded**

Run:
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
python3 -c "import json;d=json.load(open('.claude-plugin/marketplace.json'));print(d['name']);print(d['owner']);print(d['description'])"
```
Expected: name = `mgd-plugins`; owner name = `Dynatrace Managed`, email = `ivan.gudak@dynatrace.com`; description begins `Dynatrace Managed internal Claude Code plugin marketplace`.

- [ ] **Step 3: Confirm no collateral damage to unrelated github.com links**

Run:
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
grep -rIn --exclude-dir=.git -e 'spring-projects/spring-boot' -e 'OpenAPITools' -e 'api.github.com' -e 'users.noreply.github.com' . | wc -l
```
Expected: non-zero (these legitimate links are untouched — present exactly as in source).

- [ ] **Step 4: Spot-check README and CLAUDE.md headers**

Run:
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
head -3 README.md
grep -n 'hosted at\|registered\|origin' CLAUDE.md | head
```
Expected: README title `# mgd-claude-plugins`, subtitle `Dynatrace Managed internal Claude Code plugin marketplace.`; CLAUDE.md references `github.com/Dynatrace-Internal/mgd-claude-plugins`, registration `mgd-plugins`, and origin `git@github.com:Dynatrace-Internal/mgd-claude-plugins.git`.

---

### Task 6: Stage, review, and commit the initial import

**Files:**
- Target repo working tree

- [ ] **Step 1: Stage everything and review the result**

Run (inside `DST`):
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
git add -A
git status
git diff --cached --stat | tail -5
```
Expected: all copied files staged; status shows new files on branch `main`.

- [ ] **Step 2: Commit the initial import** *(run only after user confirms — this is the first commit on `main`)*

Run:
```bash
cd /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins
git commit -m "$(cat <<'EOF'
chore: initial import of mgd-claude-plugins marketplace

Rebranded clone of the ihudak-claude-plugins Claude Code plugin
marketplace for Dynatrace Managed internal use. Renamed repo/marketplace
tokens, author/owner identity, and licensing; external repo references
(ai-containers, copilot-plugins) left untouched.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Verify the commit landed**

Run:
```bash
git -C /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins log --oneline -1
git -C /Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins status
```
Expected: one commit on `main`; working tree clean. (Push is **not** part of this plan — do it only when the user asks.)

---

## Self-Review

**Spec coverage:**
- Copy mechanism (`git archive` of tracked files) → Task 1 ✔
- Full rename map (URL, repo/marketplace tokens, identity) → Tasks 2–3 ✔
- External refs preserved → Task 3 Step 3 ✔
- Email unchanged → Task 3 Step 4 ✔
- LICENSE internal notice + `"UNLICENSED"` → Task 4 ✔
- JSON validity + branding verification → Task 5 ✔
- Final review/commit → Task 6 ✔
- All five spec verification checks are realized as Task steps (no-stray-tokens, external-preserved, JSON-valid, email-preserved, no-collateral-github-damage). ✔

**Placeholder scan:** No TBD/TODO/"handle appropriately"; every step has exact commands and content. ✔

**Token consistency:** `SRC`/`DST` paths, the 10 sed expressions, and the verification greps all reference the same literal tokens (`mgd-claude-plugins`, `mgd-plugins`, `Dynatrace-Internal`, `Dynatrace Managed`, `UNLICENSED`). ✔

**Risk note carried from spec:** `"UNLICENSED"` is the npm proprietary convention; if the field should be dropped instead, adjust Task 2 line 10 and Task 4 Step 3.

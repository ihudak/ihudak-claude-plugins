---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-27
---

# SP2 Increment 3c — Finish & handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the finish & handoff to `/impl:jira:docs` — Phase 6.5 adopts an inline-profiling branch, and a new Phase 8.5 squashes the run into clean history, offers an opt-in push, and emits a copy-paste PR draft (no PR API).

**Architecture:** One new reference (`finish-and-handoff.md`) holds the mechanics plus a new `commit_convention` profile field; the command's Phase 6.5 gains generated-profile-branch handling (rename + record anchors), a new Phase 8.5 (squash → push → PR draft) lands between Phase 8 and Phase 9, and Phase 9's git-state line reports the outcome; a release bump ships it as v1.14.0.

**Tech Stack:** Markdown command/agent/reference files, YAML profile, JSON manifests, local git. **No test framework** — verification is structural (`grep` anchors, `python3` YAML/JSON parse, phase-ordering + fence parity). Those checks ARE the test cycle.

## Global Constraints

- Plugin repo `/workspace/ihudak-claude-plugins`; plugin under `plugins/dev-workflows/`. Plugin `main` is at `d92f746`, v1.13.0.
- Work on a branch off `origin/main`: **`ivgu/NOISSUE-impl-jira-docs-handoff`**. Never implement on `main`.
- **`marketplace.json` version is at `plugins[0].version`, NOT top-level.** `plugin.json` version is the top-level `"version"`.
- Commit messages (in the PLUGIN repo) end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Stage only the files each task names with `git add <path>`. Never `git add -A`/`.`; never stage `.superpowers/`, `.docstack`, or unrelated files.
- Reference-path citation format in command prose: `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md`.
- **Zero-external-API invariant preserved:** the plugin NEVER creates a PR via any REST API. The PR handoff is a copy-paste draft (on GitHub, optionally a `gh pr create` command the *user* runs). `git push` is git-protocol and is gated behind the explicit opt-in prompt.
- **"Push only when the user asks":** push happens only on the explicit `choices` selection.
- **Always squash** the run into a clean commit before push; squash base is contextual (`profile_commit` C0 when an inline-profiling run, else `git merge-base <base_branch> HEAD`).
- The reader-visible changelog still never names the Jira key; the squash commit message carries the traceability.
- Phase 8.5 runs only when a branch + this run's commits exist (write context `docs_repo` / confirmed `non_docs_repo`); skipped otherwise.
- **Out of scope (do NOT implement here):** 3d — README "AI-Containers as default", the committed Vale-fallback-note restore, "which docs command?" disambiguation, the "All five `/impl:*`" count fix, and the vestigial `obsidian`/`plain_dir` write-context wording cleanup.
- Profile field shapes are fixed by `references/dynatrace-docs/docs-profile.default.yml`. The new `commit_convention` is a top-level profile key (sits beside `branch_naming`), default `"<JIRA-KEY> <summary>"`.

---

## File Structure

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/references/finish-and-handoff.md` (NEW) | SSOT for the mechanics: the branch entering 8.5, the contextual squash, the opt-in push, host detection, the PR-draft template. Cited by Phase 6.5 + Phase 8.5. | 1 |
| `plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md` + `…/docs-profile.default.yml` | New `commit_convention` profile field (default `"<JIRA-KEY> <summary>"`). | 1 |
| `plugins/dev-workflows/commands/impl/jira/docs.md` | Phase 6.5 (generated-profile-branch detect/rename + record `base_branch`/`profile_commit`); new **Phase 8.5**; Phase 9 git-state update. | 2 |
| `plugin.json`, `marketplace.json`, `CHANGELOG.md`, `README.md` | Release bump to v1.14.0. | 3 |

---

## Task 1: `finish-and-handoff.md` reference + `commit_convention` profile field

**Files:**
- Create: `plugins/dev-workflows/references/finish-and-handoff.md`
- Modify: `plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md`
- Modify: `plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml`

**Interfaces:**
- Consumes: existing profile keys; `target_spaces`, the Phase 6.8 render summary, Phase 5.8 decisions (referenced, not redefined).
- Produces: the reference with section anchors Task 2 cites — `## 1. The branch entering Phase 8.5`, `## 2. Squash (always)`, `## 3. Push (opt-in)`, `## 4. Host detection`, `## 5. PR draft (always; no API)`. And the new profile field `commit_convention` (default `"<JIRA-KEY> <summary>"`) that Phase 6.5/8.5 read.

- [ ] **Step 1: Write the reference file**

Create `plugins/dev-workflows/references/finish-and-handoff.md` with exactly this content:

````markdown
# Finish & handoff (/impl:jira:docs)

The mechanics for Phase 6.5's inline-profiling-branch handling and Phase 8.5's
finish & handoff (squash → opt-in push → copy-paste PR draft). Generic git +
PR-draft logic; the command cites this so it stays lean. Read repo specifics
from the resolved `profile`. The plugin NEVER creates a PR via any REST API.

## 1. The branch entering Phase 8.5

Phase 6.5 created (normal case) or renamed (inline-profiling case) the work
branch off the base (main/master/release), named per repo convention, and
recorded:
- `base_branch` — the resolved base.
- `profile_commit` (C0) — set ONLY for an inline-profiling run
  (`profile_source: generated`): the commit that introduced
  `.dev-workflows/docs-profile.yml`, found with
  `git log --diff-filter=A --format=%H -- .dev-workflows/docs-profile.yml | head -1`.
  Absent otherwise.

## 2. Squash (always)

Stage the run's uncommitted docs-repo edits first — Phase 8 Agent 1 (doc index /
cross-links) and Agent 3 (`CLAUDE.md`) may have edited without committing; the
Phase 6.5 clean-tree precondition means anything uncommitted is this run's work.
Then squash:
- squash base = `profile_commit` (C0) when recorded — keeps the profile-config
  commit as a distinct first commit; otherwise `git merge-base <base_branch> HEAD`.
- mechanics: `git add` the docs-repo changes → `git reset --soft <squash-base>`
  → one `git commit -m "<message>"`.
- message follows `profile.commit_convention` when present (dynatrace-docs:
  `<JIRA-KEY> <summary>`); for a repo with no such field, infer from recent
  `git log` / `CONTRIBUTING` (a ticket-key prefix, or a conventional-commits
  `docs:` prefix), else fall back to `<JIRA_KEY> <summary>`. The Jira key carries
  traceability; the reader-visible changelog still must NOT name it.

## 3. Push (opt-in)

Offer `["Push <branch> to origin now", "Skip — I'll push later", "Cancel"]`.
- **Push** → `git push -u origin <branch>`; report the result. `git push` is
  git-protocol, not the REST API the zero-external-API invariant forbids.
- **Skip** → "Branch `<branch>` ready with N commit(s). Push when ready."
- **Cancel** → stop and summarise.
Never force-push. Never call a PR REST API.

## 4. Host detection

Classify the docs repo's `git remote get-url origin`:
- host `bitbucket.org` → Bitbucket Cloud;
- a self-hosted host with `/scm/` in the path or a bitbucket-style hostname →
  Bitbucket Server;
- host `github.com` → GitHub;
- anything else → other.

## 5. PR draft (always; no API)

Compose the draft and BOTH write and show it:
- **write** to the vault project folder as `<JIRA_KEY>-pr-draft.md`
  (`find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if
  none) — the same destination convention as the release-notes / bug drafts.
- **title**: per `commit_convention` (e.g. `<JIRA-KEY> <summary>`).
- **body**: what was documented; the output files; the Phase 6.8
  render-verification summary; deferred style/review/render items; a link back
  to the Jira VI.
- **DO-NOT-MERGE banner** at the very top WHEN Phase 5.8 recorded any
  `document-as-spec` / `skip-and-report` decision:
  `> ⚠ DO NOT MERGE until <JIRA_KEY>-implementation-gaps.md is resolved.`
- **host footer**:
  - Bitbucket (Cloud / Server) → "Open a pull request in the web UI and paste
    the title + body above." (No API.)
  - GitHub → additionally offer a command the USER may run:
    `gh pr create --title "<title>" --body-file <pr-draft path>`.
  - other → "Open a pull request in your host and paste the title + body above."

The plugin never opens the PR itself.
````

- [ ] **Step 2: Add the `commit_convention` field to the schema example**

In `plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md`, the `branch_naming` block reads:
```yaml
branch_naming:
  pattern: "<initials>/<JIRA-KEY>-<short-slug>"
```
Replace it with:
```yaml
branch_naming:
  pattern: "<initials>/<JIRA-KEY>-<short-slug>"
commit_convention: "<JIRA-KEY> <summary>"     # Phase 8.5 squash commit message format
```

- [ ] **Step 3: Add a field rule to the schema's Field rules**

In the same file, the `## Field rules` list contains the line:
```markdown
- `dev_servers.readiness_timeout_seconds` is optional (default 120) — how many seconds Phase 6.8 polls a booted server for readiness before falling back to the manual table.
```
Immediately after it, add:
```markdown
- `commit_convention` is optional — the squash commit-message format Phase 8.5 uses. When absent, the consumer infers it from recent `git log` / `CONTRIBUTING`, else falls back to `<JIRA_KEY> <summary>`.
```

- [ ] **Step 4: Add the field to the built-in default profile**

In `plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml`, the `branch_naming` block reads:
```yaml
branch_naming:
  pattern: "<initials>/<JIRA-KEY>-<short-slug>"
```
Replace it with:
```yaml
branch_naming:
  pattern: "<initials>/<JIRA-KEY>-<short-slug>"
commit_convention: "<JIRA-KEY> <summary>"
```

- [ ] **Step 5: Verify the reference anchors, the profile field, and YAML validity**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
echo "=== reference anchors ===" && \
for h in \
  "^# Finish & handoff" \
  "^## 1. The branch entering Phase 8.5" \
  "^## 2. Squash (always)" \
  "^## 3. Push (opt-in)" \
  "^## 4. Host detection" \
  "^## 5. PR draft (always; no API)" ; do \
  grep -qE "$h" plugins/dev-workflows/references/finish-and-handoff.md && echo "OK  $h" || echo "MISS $h" ; \
done && \
echo "=== commit_convention (schema example + field rule + default) ===" && \
grep -q 'commit_convention: "<JIRA-KEY> <summary>"' plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md && echo "OK  schema example" || echo "MISS schema example" && \
grep -q '`commit_convention` is optional' plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md && echo "OK  schema field rule" || echo "MISS schema field rule" && \
grep -q 'commit_convention: "<JIRA-KEY> <summary>"' plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml && echo "OK  default profile" || echo "MISS default profile"
```
Expected: six anchor `OK` lines, then three `OK` lines. No `MISS`.

- [ ] **Step 6: Verify the default profile still parses as YAML**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import sys
try:
    import yaml
    d = yaml.safe_load(open("plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml"))
    cc = d["commit_convention"]
    assert cc == "<JIRA-KEY> <summary>", f"got {cc!r}"
    print("OK  default profile parses; commit_convention ==", repr(cc))
except ImportError:
    print("SKIP pyyaml not installed — visually confirm commit_convention is a top-level key")
except Exception as e:
    print("FAIL", e); sys.exit(1)
PY
```
Expected: `OK` (or `SKIP`), no `FAIL`.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/finish-and-handoff.md \
        plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md \
        plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml
git commit -m "$(cat <<'EOF'
NOISSUE Add finish-and-handoff reference + commit_convention profile field

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `/impl:jira:docs` — Phase 6.5 anchors + new Phase 8.5 + Phase 9 git-state

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md`

**Interfaces:**
- Consumes: `finish-and-handoff.md` (Task 1, cited); the `commit_convention` field (Task 1); `profile_source` (Phase 0); the Phase 6.8 render summary; Phase 5.8 decisions.
- Produces: `base_branch` + (inline-profiling) `profile_commit` recorded in Phase 6.5; the squash/push/PR-draft outcomes reported in Phase 9. No new downstream agent interface.

- [ ] **Step 1: Phase 6.5 — handle the generated-profile branch + record anchors**

In `plugins/dev-workflows/commands/impl/jira/docs.md`, Phase 6.5 step 5 reads:
```markdown
5. **Create the branch.** `git switch -c <name>`.
```
Replace it with:
```markdown
5. **Create or adopt the branch, and record handoff anchors.** Record `base_branch` = the base resolved in step 1 (the Phase 8.5 squash uses it).
   - **Normal case** (`profile_source` is `in-repo` or `built-in`, or a custom repo whose profiling did not create a branch): `git switch -c <name>` from `base_branch`.
   - **Inline-profiling case** (`profile_source: generated`): Phase 0's `/impl:docs:profile` already ran `git switch -c <profile-branch>` and committed `.dev-workflows/docs-profile.yml`, so HEAD is already on that branch. Do NOT create a new branch — rename it with `git branch -m <name>`. Record `profile_commit` = the commit that introduced the profile config: `git log --diff-filter=A --format=%H -- .dev-workflows/docs-profile.yml | head -1`. Phase 8.5 squashes the docs commits onto `profile_commit`, keeping the profile-config commit as a distinct first commit. (Per `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §1.)
```

- [ ] **Step 2: Insert Phase 8.5 between Phase 8 and Phase 9**

Find the heading line `## Phase 9 — Final Report` (preceded by the `---` that closes Phase 8). Replace that single heading line:
```markdown
## Phase 9 — Final Report
```
with this block (the new Phase 8.5, a separator, then the original Phase 9 heading):
````markdown
## Phase 8.5 — Finish & handoff

Run this phase only when Phase 6 wrote + committed in a git repo (write context `docs_repo`, or `non_docs_repo` confirmed at Phase 0) — i.e. a branch with this run's commits exists. Skip otherwise (nothing to hand off). Mechanics: `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md`.

### Step 1 — Squash (always)

Fold the run into clean history before handoff:
1. Stage the run's uncommitted docs-repo edits — Phase 8 Agent 1 (doc index / cross-links) and Agent 3 (`CLAUDE.md`) may have edited without committing; the Phase 6.5 clean-tree check means everything uncommitted is this run's work.
2. Compute the squash base: if Phase 6.5 recorded `profile_commit` (inline-profiling run), base = `profile_commit` (keeps the profile-config commit as a distinct first commit → two commits); otherwise base = `git merge-base <base_branch> HEAD` (one commit).
3. `git add` the docs-repo changes → `git reset --soft <squash-base>` → one `git commit`. The message follows `profile.commit_convention` when present (dynatrace-docs: `<JIRA-KEY> <summary>`); for a repo with no such field, infer from recent `git log` / `CONTRIBUTING`, else fall back to `<JIRA_KEY> <summary>`. NEVER put the Jira key in a reader-visible changelog — the commit message carries traceability.

### Step 2 — Offer push

```
choices: ["Push <branch> to origin now", "Skip — I'll push later", "Cancel"]
```
- **Push** → `git push -u origin <branch>`; report the result. (`git push` is git-protocol, not a REST API — the zero-external-API invariant is preserved.)
- **Skip** → "Branch `<branch>` ready with N commit(s). Push when ready."
- **Cancel** → stop and summarise.

### Step 3 — Copy-paste PR draft (always; no API)

Per `${CLAUDE_PLUGIN_ROOT}/references/finish-and-handoff.md` §4–§5:
1. **Detect the host** from the docs repo's `git remote get-url origin` (Bitbucket Cloud / Bitbucket Server / GitHub / other).
2. **Compose the draft**: title (per `commit_convention`); body — what was documented, the output files, the Phase 6.8 render-verification summary, deferred style/review/render items, a link to the Jira VI. When Phase 5.8 recorded any `document-as-spec` / `skip-and-report` decision, prepend a banner: `> ⚠ DO NOT MERGE until <JIRA_KEY>-implementation-gaps.md is resolved.`
3. **Write + show**: write `<JIRA_KEY>-pr-draft.md` to the vault project folder (`find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if none) AND print it.
4. **Host footer**: Bitbucket → "open a PR in the web UI and paste the title + body"; GitHub → additionally offer `gh pr create --title "<title>" --body-file <pr-draft path>` that the user may run; other → "open a PR and paste the title + body". The plugin never opens the PR itself.

Carry the squash result, push outcome, and PR-draft path into the Phase 9 report.

---

## Phase 9 — Final Report
````

- [ ] **Step 3: Update the Phase 9 `### Git state` section**

In the Phase 9 report template, find:
```
### Git state
[If branching happened: "Branch <name> created with N commits. Push when ready." If no branching: "Working tree has uncommitted changes. /impl:jira:docs writes but does not commit in non-git contexts."]
```
Replace with:
```
### Git state
[When Phase 8.5 ran: "Branch <name> — squashed to N commit(s); pushed to origin: <yes/no>; PR draft: <pr-draft path>." When Phase 8.5 was skipped (no branch/commits): "Working tree has uncommitted changes. /impl:jira:docs writes but does not commit in non-git contexts."]
```

- [ ] **Step 4: Verify the edits, placement, ordering, and fence parity**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import sys
t = open("plugins/dev-workflows/commands/impl/jira/docs.md").read()
checks = {
  "6.5 generated-branch case":  "Inline-profiling case** (`profile_source: generated`)" in t,
  "6.5 git branch -m":          "git branch -m <name>" in t,
  "6.5 records profile_commit": "Record `profile_commit`" in t,
  "6.5 records base_branch":    "Record `base_branch`" in t,
  "Phase 8.5 heading":          "## Phase 8.5 — Finish & handoff" in t,
  "8.5 cites reference":        "references/finish-and-handoff.md" in t,
  "8.5 squash always":          "Step 1 — Squash (always)" in t,
  "8.5 squash base contextual": "base = `profile_commit`" in t and "git merge-base <base_branch> HEAD" in t,
  "8.5 offer push":             "Push <branch> to origin now" in t,
  "8.5 PR draft no API":        "The plugin never opens the PR itself." in t,
  "8.5 do-not-merge banner":    "DO NOT MERGE until <JIRA_KEY>-implementation-gaps.md" in t,
  "Phase 9 git-state updated":  "squashed to N commit(s); pushed to origin" in t,
}
miss=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(("OK  " if v else "MISS")+" "+k)
i8,i85,i9 = t.find("## Phase 8 —"), t.find("## Phase 8.5"), t.find("## Phase 9")
order_ok = -1 < i8 < i85 < i9
print(("OK  " if order_ok else "MISS")+f" ordering 8<8.5<9 {(i8,i85,i9)}")
fences = t.count("\n```")
print(("OK  " if fences%2==0 else "MISS")+f" code-fence parity (count={fences})")
sys.exit(0 if (not miss and order_ok and fences%2==0) else 1)
PY
```
Expected: every check `OK`, ordering `OK`, fence parity `OK`, exit 0.

- [ ] **Step 5: Confirm no existing phase was disturbed**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import sys
t=open("plugins/dev-workflows/commands/impl/jira/docs.md").read()
phases=["## Phase 0","## Phase 5.8","## Phase 5.9","## Phase 6 — Write","## Phase 6.5","## Phase 6.7","## Phase 6.8","## Phase 7 — Doc review","## Phase 8 —","## Phase 8.5","## Phase 9"]
miss=[p for p in phases if p not in t]
for p in phases: print(("OK  " if p not in miss else "MISS")+" "+p)
sys.exit(0 if not miss else 1)
PY
```
Expected: every phase `OK`, exit 0.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "$(cat <<'EOF'
NOISSUE impl:jira:docs: Phase 6.5 profiling-branch handling + Phase 8.5 finish & handoff (squash/push/PR-draft)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Release v1.14.0 (manifests + CHANGELOG + README)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `plugins/dev-workflows/README.md`

**Interfaces:**
- Consumes: the merged behavior from Tasks 1–2.
- Produces: a released v1.14.0.

- [ ] **Step 1: Bump `plugin.json` (top-level version)**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, change the top-level `"version"` from `"1.13.0"` to `"1.14.0"`.

- [ ] **Step 2: Bump `marketplace.json` (plugins[0].version — NOT top-level)**

In `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`, change the dev-workflows entry's version under `plugins[0].version` from `1.13.0` to `1.14.0`. Verify you edited `plugins[0].version`, not any top-level field.

- [ ] **Step 3: Add the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, insert a new section immediately above `## [1.13.0] — 2026-06-27`:
```markdown
## [1.14.0] — 2026-06-27

### Added
- **`references/finish-and-handoff.md`.** Single source of truth for `/impl:jira:docs` finish & handoff: the branch entering Phase 8.5, the contextual squash (profile-config commit vs merge-base), the opt-in push, host detection, and the copy-paste PR-draft template.
- **`commit_convention` profile field (default `"<JIRA-KEY> <summary>"`).** The squash commit-message format Phase 8.5 uses; inferred from `git log` / `CONTRIBUTING` when absent.

### Changed
- **`/impl:jira:docs` finish & handoff (Increment 3c).** Phase 6.5 now adopts the inline-profiling branch (renames it to the docs-branch convention and records the profile-config commit) instead of leaving the run on it. A new **Phase 8.5** squashes the run into clean history (keeping the profile-config commit separate when profiling ran), offers an opt-in `git push`, and writes a copy-paste PR draft to the vault project folder — host-aware (Bitbucket web UI / a `gh pr create` command the user may run), with a DO-NOT-MERGE banner when document-as-spec/skip-and-report gaps exist. Phase 9's git-state line reports the squash/push/draft outcome. The zero-external-API invariant is preserved — the plugin never creates a PR via an API.
```

- [ ] **Step 4: Add a README note**

In `plugins/dev-workflows/README.md`, find the line:
```markdown
- `references/dynatrace-docs/render-verification.md` — how `/impl:jira:docs` Phase 6.8 verifies the written docs build and render (build-vs-boot, sequential dev-server smoke-check, the cross-space render-unchanged invariant, pages-to-visit table)
```
Immediately **below** that line, add:
```markdown
- `references/finish-and-handoff.md` — how `/impl:jira:docs` Phase 8.5 finishes a run (squash, opt-in push, host-aware copy-paste PR draft) and how Phase 6.5 adopts an inline-profiling branch
```

- [ ] **Step 5: Verify the manifests parse and carry 1.14.0, and the docs mention the feature**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import json,sys
pj=json.load(open("plugins/dev-workflows/.claude-plugin/plugin.json"))
mk=json.load(open(".claude-plugin/marketplace.json"))
ok_pj = pj.get("version")=="1.14.0"
mkv = mk["plugins"][0].get("version")
ok_mk = mkv=="1.14.0"
print(("OK  " if ok_pj else "MISS")+f" plugin.json top-level version = {pj.get('version')}")
print(("OK  " if ok_mk else "MISS")+f" marketplace.json plugins[0].version = {mkv}")
cl=open("plugins/dev-workflows/CHANGELOG.md").read()
ok_cl = "## [1.14.0] — 2026-06-27" in cl and "finish-and-handoff.md" in cl
print(("OK  " if ok_cl else "MISS")+" CHANGELOG [1.14.0] entry")
rm=open("plugins/dev-workflows/README.md").read()
ok_rm = "finish-and-handoff.md" in rm
print(("OK  " if ok_rm else "MISS")+" README mentions finish-and-handoff.md")
sys.exit(0 if all([ok_pj,ok_mk,ok_cl,ok_rm]) else 1)
PY
```
Expected: four `OK` lines, exit 0.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json \
        plugins/dev-workflows/CHANGELOG.md \
        plugins/dev-workflows/README.md
git commit -m "$(cat <<'EOF'
NOISSUE Release dev-workflows v1.14.0 — finish & handoff (Increment 3c)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Spec coverage** (against `spec/2026-06-27-sp2-increment3c-finish-and-handoff-design.md`):
- A. Phase 6.5 inline-profiling-branch handling (detect/rename + record `profile_commit`) → Task 2 Step 1. ✅
- B. Squash always, contextual base (C0 vs merge-base), commit_convention message → Task 2 Step 2 + reference §2 (Task 1). ✅
- C. Offer push (opt-in) → Task 2 Step 2 + reference §3. ✅
- D. Copy-paste PR draft, host-aware, DO-NOT-MERGE banner, vault destination → Task 2 Step 2 + reference §4/§5. ✅
- Phase 9 git-state update → Task 2 Step 3. ✅
- New `finish-and-handoff.md` reference → Task 1. ✅
- `commit_convention` profile field (schema + default) → Task 1 Steps 2–4. ✅
- Release v1.14.0 → Task 3. ✅
- Q1 (uncommitted Phase 8 edits folded into squash) → reference §2 + Task 2 Step 2.1. ✅
- Q3 (branch off base, this run only) → Task 2 Step 1 + reference §1. ✅
- Invariants preserved (zero-external-API, push-only-when-asked, changelog no Jira key) → Global Constraints + reference §3/§5. ✅
- Out-of-scope 3d items → excluded per Global Constraints. ✅

**2. Placeholder scan:** No "TBD"/"TODO"/"fill in" in plan steps. `<JIRA_KEY>`, `<branch>`, `<name>`, `<pr-draft path>` are template placeholders in the command/reference prose (intended), not plan gaps. ✅

**3. Type/name consistency:** `base_branch`, `profile_commit`, `commit_convention` are spelled identically in the reference (Task 1), the schema/default (Task 1), and the command Phase 6.5/8.5 (Task 2). Reference §-anchors (`§1`/`§2`/`§4`/`§5`) cited by Task 2 match the headings created in Task 1. `<JIRA_KEY>-pr-draft.md` destination + `<JIRA_KEY>-implementation-gaps.md` banner names are consistent. Profile keys (`profile_source`, `commit_convention`) match existing/added keys. ✅

**Model guidance for execution:** Task 1 — cheapest tier (full content supplied + small schema/YAML edits). Task 2 — implement on a standard model (transcription of supplied blocks), **review on the most capable model** (it carries the git squash/branch mechanics + the zero-external-API invariant — the core of 3c). Task 3 — cheapest tier; reviewer confirms `marketplace.json` was edited at `plugins[0].version`. Final whole-branch review — most capable model.

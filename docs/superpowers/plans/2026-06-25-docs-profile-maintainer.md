---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-25
---

# docs-repo profile maintainer (sub-project 1) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax. These are Markdown command/skill/reference files — "tests" are structural verifications (parse, grep, schema-load), not a unit suite.

**Goal:** Add a `/impl:docs:profile` command to the `dev-workflows` plugin that scans a docs repo and writes/refreshes a machine-readable `docs-profile.yml` (+ complementary CLAUDE.md guidance) as a reviewable PR, and add the mid-tier Sonnet model chain it relies on.

**Architecture:** Four deliverables in `/workspace/ihudak-claude-plugins/plugins/dev-workflows/`: (1) a new `§2.1` mid-tier chain in the model-routing SSOT; (2) a `docs-profile` schema reference; (3) the phased command file; (4) manifest + docs registration. The command pins detection to the Sonnet chain and synthesis to the Opus chain, and defers changelog/owners to the existing v1.8.0 `dynatrace-docs-frontmatter` skill.

**Tech Stack:** Markdown (command/skill/reference files), YAML frontmatter + profile, Claude Code plugin conventions, git.

## Global Constraints

- Plugin root: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/` (the "PLUGIN" below). Currently v1.8.0, on `main` → **branch first**.
- Command name `/impl:docs:profile` → file `commands/impl/docs/profile.md` (coexists with `commands/impl/docs.md`).
- The command writes the profile to **`.dev-workflows/docs-profile.yml` in the TARGET docs repo** (not the plugin).
- **Detection** steps pin to the mid-tier Sonnet chain (`claude-sonnet-4-6` → `claude-sonnet-4-5`) via the `task` `model:` override — never inherit the session model. **Synthesis** pins to the §2 Opus chain. Record both in the `model_routing` block.
- **changelog/owners: defer** to the existing `dynatrace-docs-frontmatter` skill + `references/dynatrace-docs/{changelog-guidelines.md,managed-owners.txt}`. Do NOT duplicate the rules.
- Output = reviewable PR (branch + commit + drafted PR message); **never auto-merge**.
- Adding `§2.1` must be **purely additive** — the §2 powerful chain stays byte-identical.
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

### Task 1: Add the mid-tier Sonnet chain to the model-routing SSOT

**Files:**
- Branch: create `ivgu/NOISSUE-impl-docs-profile` in the PLUGIN repo.
- Modify: `references/model-routing/classification.md` (insert `§2.1` after `§2`; extend the `§4` handoff block with an optional `detection_model:`).

- [ ] **Step 1: Branch the plugin repo off main**

```bash
cd /workspace/ihudak-claude-plugins
git fetch origin -q && git checkout -b ivgu/NOISSUE-impl-docs-profile origin/main 2>&1 | tail -2
```

- [ ] **Step 2: Note the additive-only requirement**

The edit must be **purely additive** — no existing line of `classification.md` may change (the §2 powerful chain stays byte-identical). Step 5 verifies this with `git diff --numstat` (deletions must be 0).

- [ ] **Step 3: Insert §2.1 immediately after the §2 section** (before `## 3. Routing rules`)

Exact text to insert:

```markdown
## 2.1 Mid-tier ("detection / throughput") fallback chain

Some steps are deliberately **not** reasoning-heavy — mechanical detection,
repo scanning, transcription, formatting. Pin these to the strongest **Sonnet**
model available via the `task` tool's `model:` override; do **not** let them
inherit the session model (an Opus session would otherwise run "cheap" steps on
Opus, defeating the point).

Use the first available:

1. `claude-sonnet-4-6` (latest Sonnet)
2. `claude-sonnet-4-5` (fallback — note the degradation in the report)

If neither Sonnet is available, fall back to the session model and announce it.
Record the chosen model as `detection_model:` in the `model_routing` block.
```

- [ ] **Step 4: Add `detection_model` to the §4 handoff block doc**

In the `model_routing` YAML example under `## 4`, add this line after `implementation_model:`:

```yaml
  detection_model: <e.g. claude-sonnet-4-6>  # mid-tier steps (§2.1); never the session model
```

- [ ] **Step 5: Verify the change is purely additive and §2.1 is present**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/references/model-routing/classification.md
git diff --numstat "$F"                       # columns: added  deleted  file
test "$(git diff --numstat "$F" | awk '{print $2}')" = "0" && echo "purely additive (0 deletions) OK"
grep -q "## 2.1" "$F" && echo "§2.1 present"
grep -c "claude-sonnet-4-6" "$F"              # >=1
```
Expected: deletions = 0; `§2.1 present`; sonnet count ≥ 1.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/references/model-routing/classification.md
git commit -m "feat(dev-workflows): add §2.1 mid-tier Sonnet detection chain to model-routing SSOT

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Create the docs-profile schema reference

**Files:**
- Create: `references/dynatrace-docs/docs-profile-schema.md`

**Interfaces:**
- Produces: the canonical `docs-profile.yml` schema that Task 3 writes against and that sub-project 2 (`/impl:jira:docs`) will consume.

- [ ] **Step 1: Write the schema reference file**

Create `references/dynatrace-docs/docs-profile-schema.md` with this content (the fenced YAML is the canonical schema + a worked dynatrace-docs example):

````markdown
# docs-profile schema

`/impl:docs:profile` writes this file to **`.dev-workflows/docs-profile.yml`** in
the target docs repo. `/impl:jira:docs` reads it. `changelog` and `owners` are
intentionally absent — they are owned by the `dynatrace-docs-frontmatter` skill.

```yaml
schema_version: 1
repo:
  name: dynatrace-docs                # detected from git remote / dir name
spaces:                               # one entry per rendered space
  - id: saas
    content_root: dynatrace/_content
    snippet_root: dynatrace/_snippets
    base_path: /docs
  - id: managed
    content_root: managed/_content
    snippet_root: managed/_snippets
    base_path: /managed
dev_servers:
  concurrent: false                   # cannot run two spaces at once
  servers:
    - space: saas
      command: "pnpm dynatrace:start"
      port: 4000
      base_path: /docs
    - space: managed
      command: "pnpm managed:start"
      port: 4001
      base_path: /managed
commands:
  lint: "pnpm dynatrace:lint"
  format: "pnpm prettier -w"
  commit_hook: "husky pre-commit -> lint-staged -> pnpm prettier -w"
cross_space_override:
  manifest: managed/docstack.jsonc
  mechanism: "the managed manifest pulls an allowlist of ../dynatrace/_content/... pages; last-write-wins by path silently shadows a managed/_content override"
  rule: "to make a managed/_content override win, add the shared dynatrace path to the allowlist block's `ignore`"
shared_registries:
  - files: [schema-ids.yml, schema-mappings.yml]
    when: "renaming/retitling/creating a settings-schema page under dynatrace/_content/dynatrace-api/environment-api/settings/schemas/"
    rule: "update the `text:` entry in BOTH files in lock-step"
tokens:
  latest_tag: "{{tag kind='latest'}}"          # gen3/Latest marker
  gen3_settings_breadcrumb: "::app-settings::"
  project_conditionals: "{{#if project='saas'}}…{{/if}} / project='managed' / project='classic'"
internal_links:
  convention: "[text](<postid>); postid comes from target frontmatter; verify it exists before linking"
branch_naming:
  pattern: "<initials>/<JIRA-KEY>-<short-slug>"
frontmatter:                          # pointers only — NOT a re-spec
  owned_by_skill: dynatrace-docs-frontmatter
  changelog_guidelines: references/dynatrace-docs/changelog-guidelines.md
  managed_owners: references/dynatrace-docs/managed-owners.txt
images:
  policy: "CDN-hosted; the user uploads to CDN and supplies links; docs reference the URLs; never commit binaries"
prerequisites:
  - "a dev server may need a working .docstack toolchain (e.g. an axios>=1.16 shim) before `*:start` boots"
```

## Field rules
- `spaces[]` is required and non-empty. A single-space repo has one entry and omits `cross_space_override`.
- `dev_servers.concurrent: false` means the consumer must start servers sequentially.
- `cross_space_override` and `shared_registries` are present only when detected (multi-space / docstack repos).
- `frontmatter.*` are pointers; never copy the rules here.
````

- [ ] **Step 2: Verify the embedded schema is valid YAML and has required keys**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
python3 - <<'PY'
import re, yaml, pathlib
txt = pathlib.Path("references/dynatrace-docs/docs-profile-schema.md").read_text()
block = re.search(r"```yaml\n(.*?)\n```", txt, re.S).group(1)
d = yaml.safe_load(block)
for k in ("schema_version","spaces","dev_servers","frontmatter"):
    assert k in d, f"missing {k}"
assert isinstance(d["spaces"], list) and d["spaces"], "spaces must be non-empty list"
assert "changelog" not in d and "owners" not in d, "changelog/owners must be deferred, not inlined"
print("schema OK:", list(d.keys()))
PY
```
Expected: `schema OK: [...]` with no assertion error.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md
git commit -m "feat(dev-workflows): add docs-profile schema reference

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Create the `/impl:docs:profile` command

**Files:**
- Create: `commands/impl/docs/profile.md`

**Interfaces:**
- Consumes: `references/dynatrace-docs/docs-profile-schema.md` (Task 2); `references/model-routing/classification.md` §2 + §2.1 (Task 1); the existing `dynatrace-docs-frontmatter` skill + `references/dynatrace-docs/*`.
- Produces: the `/impl:docs:profile` command users invoke.

- [ ] **Step 1: Write the command file** `commands/impl/docs/profile.md`

Frontmatter (verbatim):

```markdown
---
name: impl:docs:profile
description: Scan a documentation repository and write/refresh a machine-readable docs-profile (.dev-workflows/docs-profile.yml) plus complementary CLAUDE.md guidance, as a reviewable PR. Captures spaces, dev-servers, cross-space override/shadowing, shared registries, gen3/Classic tokens, links, branch-naming, images, and prerequisites; defers changelog/owners to the dynatrace-docs-frontmatter skill. Bootstraps or refreshes the profile that /impl:jira:docs consumes.
allowed-tools: Read Edit Write Bash Glob Grep Task LS
---
```

Body — the argument line and these phases (write each phase as concrete instructions; cite reference paths with `${CLAUDE_PLUGIN_ROOT}`):

```markdown
Profile the documentation repository: $ARGUMENTS

`$ARGUMENTS` is an optional repo path; default to the current working directory.

## Phase 0 — Resolve and validate the target repo
- Resolve the repo path (arg or cwd). Confirm it is a git work tree (`git -C <path> rev-parse --is-inside-work-tree`) and writeable (`test -w <path>`); stop with a named error if not.
- Detect docs-repo signals (package.json doc scripts, `.docstack/`, `.vale.ini`, `*/_content/`). If zero signals, ask the user to confirm this is a docs repo (`choices: [...,"Other… (describe)"]`) before continuing.

## Phase 1 — Model routing
- Invoke the `model-routing` skill to load `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md`. Profiling is SIGNIFICANT (cross-cutting synthesis). Record a `model_routing` block: `detection_model` from §2.1 (Sonnet chain), `planning_model`/synthesis from §2 (Opus chain).

## Phase 2 — Detect (Sonnet-tier)
- Dispatch a read-only detection subagent **pinned via `task` `model:` to the §2.1 chain** (`claude-sonnet-4-6`, fallback `claude-sonnet-4-5`) — never the session model. It gathers, without writing: package.json scripts (`*:start`, lint, format) + ports/base paths; presence + shape of `managed/docstack.jsonc` (allowlist + `ignore`); `schema-ids.yml`/`schema-mappings.yml`; grep for `{{tag kind='latest'}}`, `::app-settings::`, `{{#if project=`; `*/_content` + `*/_snippets` roots; CONTRIBUTING/CONTRIBUTION/README/DOCUMENTATION-GUIDELINES/CLAUDE.md branch-naming + link conventions. Returns a detection report.

## Phase 3 — Synthesize the draft profile (Opus)
- On the §2 Opus chain, turn the detection report into a `docs-profile.yml` that conforms to `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/docs-profile-schema.md`. Populate `frontmatter.*` as POINTERS to the `dynatrace-docs-frontmatter` skill and its references — never copy changelog/owners rules. Draft complementary CLAUDE.md additions ONLY for conventions not already covered by that skill/hook.

## Phase 4 — Confirm and fill gaps
- For anything detection could not settle (exact build command, prerequisites like the `.docstack` shim, ambiguous space mapping), ask the user with `choices` arrays whose last item is `"Other… (describe)"`; recommended default first.
- **Idempotent:** if `.dev-workflows/docs-profile.yml` already exists, show a field-level diff and confirm before overwriting.

## Phase 5 — Write as a reviewable PR
- Create/switch to a branch in the target repo (use the repo's naming convention if detected, else `<initials>/NOISSUE-docs-profile`; ask initials if unknown). Write `.dev-workflows/docs-profile.yml` and apply the confirmed CLAUDE.md additions. Run the repo formatter/lint if present. Commit; draft a Bitbucket/GitHub PR message to copy-paste. **Never push or auto-merge** unless the user asks.

## Phase 6 — Final report
- Report the profile path, which fields were detected vs. user-supplied, the CLAUDE.md additions, and the PR draft. Note any §2.1/§2 model fallback that occurred.
```

- [ ] **Step 2: Verify the command frontmatter parses and the file resolves**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
test -f commands/impl/docs/profile.md && echo "file OK"
python3 - <<'PY'
import re, yaml, pathlib
t = pathlib.Path("commands/impl/docs/profile.md").read_text()
fm = re.search(r"^---\n(.*?)\n---", t, re.S).group(1)
d = yaml.safe_load(fm)
assert d["name"] == "impl:docs:profile", d.get("name")
assert "Task" in d["allowed-tools"], "needs Task tool for subagents"
print("frontmatter OK:", d["name"])
PY
test -f commands/impl/docs.md && echo "/impl:docs not clobbered"
```
Expected: `file OK`, `frontmatter OK: impl:docs:profile`, `/impl:docs not clobbered`.

- [ ] **Step 3: Verify cited references exist**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in references/dynatrace-docs/docs-profile-schema.md \
         references/model-routing/classification.md \
         references/dynatrace-docs/changelog-guidelines.md \
         references/dynatrace-docs/managed-owners.txt \
         skills/dynatrace-docs-frontmatter/SKILL.md ; do
  test -f "$f" && echo "OK $f" || echo "MISSING $f"
done
```
Expected: all `OK`.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/docs/profile.md
git commit -m "feat(dev-workflows): add /impl:docs:profile command

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Register and document the new command

**Files:**
- Modify: `.claude-plugin/plugin.json` (version 1.8.0 → 1.9.0; add command to the `description`)
- Modify: every file that enumerates commands (discover via grep — typically `CHANGELOG.md`, root `README.md`, `plugins/dev-workflows/README.md`, `plugins/dev-workflows/CLAUDE.md`)

- [ ] **Step 1: Discover every file that enumerates the commands**

```bash
cd /workspace/ihudak-claude-plugins
grep -rl "/impl:jira:release-notes" --include='*.md' --include='*.json' . | sort
```
This is the authoritative list of places that list commands; update each in the following steps.

- [ ] **Step 2: Bump version and extend the manifest description**

In `plugins/dev-workflows/.claude-plugin/plugin.json`: set `"version": "1.9.0"`, and add `/impl:docs:profile` to the command list in `description` (e.g. after `/impl:docs`).

- [ ] **Step 3: Add a CHANGELOG entry** (top of `plugins/dev-workflows/CHANGELOG.md`, matching its existing format)

```markdown
## 1.9.0
- feat: `/impl:docs:profile` — scans a docs repo and writes/refreshes `.dev-workflows/docs-profile.yml` + CLAUDE.md guidance as a reviewable PR (consumed by `/impl:jira:docs`).
- feat: model-routing SSOT §2.1 — mid-tier Sonnet detection chain (`claude-sonnet-4-6` → `claude-sonnet-4-5`), pinned via `model:` so detection never inherits an Opus session.
- feat: `references/dynatrace-docs/docs-profile-schema.md` — the docs-profile schema.
```

- [ ] **Step 4: Add `/impl:docs:profile` to each README/CLAUDE.md command list found in Step 1**, mirroring the surrounding entries' wording (one-line: "scan a docs repo and write/refresh its docs-profile").

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;d=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));print(d['version']);assert d['version']=='1.9.0';assert 'impl:docs:profile' in d['description']"
grep -rl "impl:docs:profile" --include='*.md' --include='*.json' . | sort   # should match Step 1's list (minus none) + the new command file
grep -q "## 1.9.0" plugins/dev-workflows/CHANGELOG.md && echo "CHANGELOG OK"
```
Expected: prints `1.9.0`; `/impl:docs:profile` appears in every enumeration file; `CHANGELOG OK`.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json plugins/dev-workflows/CHANGELOG.md
git add -A -- '*README.md' '*CLAUDE.md'   # only the command-list docs found in Step 1
git status --short                         # confirm only intended files staged
git commit -m "docs(dev-workflows): register /impl:docs:profile + release 1.9.0

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## After all tasks

Use superpowers:finishing-a-development-branch on `ivgu/NOISSUE-impl-docs-profile` in the plugin repo to push and draft the PR (user selects the option). Sub-project 2 (the `/impl:jira:docs` enhancement that consumes this profile) is a separate spec → plan.

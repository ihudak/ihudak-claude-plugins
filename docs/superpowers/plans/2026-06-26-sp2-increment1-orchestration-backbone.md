---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-26
---

# SP2 Increment 1 — orchestration backbone: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax. These are Markdown command/reference files + JSON manifests — "tests" are structural verifications (parse, grep, schema-load, dry-run), not a unit suite.

**Goal:** Turn `/impl:jira:docs` into a single-entry command that, given `PRODUCT-NNNN [saas|managed]`, preflight-discovers every input under `/workspace` (asking on a host), resolves the docs repo + its profile (built-in dynatrace-docs default, in-repo override, or inline on-demand profiling), discovers the VI's specs, and determines/confirms the applicable space(s).

**Architecture:** Edit the existing `commands/impl/jira/docs.md` (Phase 0 + a new Phase 4.5) and add a built-in default profile file in the plugin. Reuse the command's existing `$VAULT_PATH`/`jira-products` validation, `$REPOS_PATH`→`/workspace` default, and multi-repo slug→clone resolution. No downstream writing changes (deferred to Increments 2–3).

**Tech Stack:** Markdown (command/reference), YAML (profile), JSON (manifests), Claude Code plugin conventions, git.

## Global Constraints

- Plugin repo `/workspace/ihudak-claude-plugins/plugins/dev-workflows/` (the PLUGIN). On `main` → **branch first** off `origin/main`.
- Single command `/impl:jira:docs PRODUCT-NNNN [saas|managed]` — **no `both`**; the arg is a **constraint** (document only that space, keeping the other space's render unchanged); **omitted** → determine applicable space(s) and **confirm** with the user.
- All discovery defaults to `/workspace` (AI-Containers); when a path isn't found (host / non-standard mount) → **ask**, remembering the last value.
- Profile resolution order for the resolved docs repo: (1) in-repo `.dev-workflows/docs-profile.yml`; (2) else recognized dynatrace-docs → **built-in default** `references/dynatrace-docs/docs-profile.default.yml` (conforms to `references/dynatrace-docs/docs-profile-schema.md`); (3) else custom repo → **inline `/impl:docs:profile`**, then resume.
- Specs: sibling repo under `/workspace`; detect vis-root (`specifications/` or `vis/`); **`PRODUCT-NNNN*` prefix match**; **missing → `specs: none`, proceed**.
- Code repos are **plural** — resolve all the VI's PR URLs across repositories (existing Phase 4).
- **Do not break** `/impl:docs` or `/impl:docs:profile`; do not change downstream writing phases (Increments 2–3 own those).
- Increment 1 is the **mechanism only**: first-pass applicability + readiness; deep analysis, multi-space write safety, dev-server verify, planning gate, and PR are later increments.
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

### Task 1: Built-in dynatrace-docs default profile

**Files:**
- Branch: create `ivgu/NOISSUE-impl-jira-docs-backbone` in the PLUGIN repo off `origin/main`.
- Create: `references/dynatrace-docs/docs-profile.default.yml`

**Interfaces — Produces:** the built-in default profile that Task 2's profile-resolution step loads for dynatrace-docs.

- [ ] **Step 1: Branch the plugin repo off main**

```bash
cd /workspace/ihudak-claude-plugins
git fetch origin -q && git checkout -b ivgu/NOISSUE-impl-jira-docs-backbone origin/main 2>&1 | tail -2
```

- [ ] **Step 2: Write the built-in default profile** (`references/dynatrace-docs/docs-profile.default.yml`)

Content (the dynatrace-docs values, conforming to `docs-profile-schema.md`):

```yaml
# Built-in default profile for dynatrace-docs (dev-workflows).
# Used by /impl:jira:docs when the resolved docs repo is recognized as
# dynatrace-docs and no in-repo .dev-workflows/docs-profile.yml is present.
# An in-repo profile, if present, overrides this file.
schema_version: 1
repo:
  name: dynatrace-docs
spaces:
  - id: saas
    content_root: dynatrace/_content
    snippet_root: dynatrace/_snippets
    base_path: /docs
  - id: managed
    content_root: managed/_content
    snippet_root: managed/_snippets
    base_path: /managed
dev_servers:
  concurrent: false
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
  latest_tag: "{{tag kind='latest'}}"
  gen3_settings_breadcrumb: "::app-settings::"
  project_conditionals: "{{#if project='saas'}}…{{/if}} / project='managed' / project='classic'"
internal_links:
  convention: "[text](<postid>); postid comes from target frontmatter; verify it exists before linking"
branch_naming:
  pattern: "<initials>/<JIRA-KEY>-<short-slug>"
frontmatter:
  owned_by_skill: dynatrace-docs-frontmatter
  changelog_guidelines: references/dynatrace-docs/changelog-guidelines.md
  managed_owners: references/dynatrace-docs/managed-owners.txt
images:
  policy: "CDN-hosted; the user uploads to CDN and supplies links; docs reference the URLs; never commit binaries"
prerequisites:
  - "a dev server may need a working .docstack toolchain (e.g. an axios>=1.16 shim) before `*:start` boots"
```

- [ ] **Step 3: Verify it validates against the schema** (same required-keys + no changelog/owners check used by the schema)

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
python3 - <<'PY'
import yaml, pathlib
d = yaml.safe_load(pathlib.Path("references/dynatrace-docs/docs-profile.default.yml").read_text())
for k in ("schema_version","spaces","dev_servers","frontmatter"):
    assert k in d, f"missing {k}"
assert [s["id"] for s in d["spaces"]] == ["saas","managed"], d["spaces"]
assert d["dev_servers"]["concurrent"] is False
assert "changelog" not in d and "owners" not in d, "changelog/owners must be deferred"
print("default profile OK:", [s["id"] for s in d["spaces"]])
PY
```
Expected: `default profile OK: ['saas', 'managed']`.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml
git commit -m "feat(dev-workflows): add built-in dynatrace-docs default profile

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Phase 0 preflight discovery (docs repo + profile + specs + readiness)

**Files:**
- Modify: `commands/impl/jira/docs.md` — extend Phase 0 (currently lines ~15–44).

**Interfaces — Consumes:** the built-in default profile from Task 1. **Produces:** resolved `docs_repo_path`, `profile_source` (`in-repo` | `built-in` | `generated`), `specs_dir` (or `none`), and a readiness table that Task 3 and later increments read.

- [ ] **Step 1: Extend Phase 0 with the four discovery blocks**

Keep the existing steps 1–4 intact — including step 4's **write-context classification** (`obsidian`/`docs_repo`/`non_docs_repo`/`plain_dir`), which downstream phases (6.5/6) still consume and Increment 1 does NOT touch. AUGMENT step 3 and ADD the new blocks below (write idiomatic prose; preserve the `choices`-array house style, last item `"Other… (describe)"`, recommended first):

1. **Resolve the docs repo (cwd-preferred).** (a) If cwd's git root shows docs signals (existing list: `package.json` `*:start|*:build|*:lint|docs:*`, `.docstack/`, `mkdocs.yml`, `docusaurus.config.js`, `antora.yml`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, any `_snippets/`) → `docs_repo_path = cwd git root` (preserves today's behavior; downstream phases that assume cwd stay correct). (b) Else look under `${REPOS_PATH:-/workspace}` for a `dynatrace-docs` clone (dir name `dynatrace-docs`, or a git root containing both `dynatrace/_content` and `managed/docstack.jsonc`) → use it. (c) Else ask with `choices: ["Enter the docs repo path", "Cancel", "Other… (describe)"]`. Confirm the resolved path is writeable (`test -w`); if not, stop with `REPO_NOT_WRITEABLE`. Compute step 4's write-context against `docs_repo_path`; when it differs from cwd, record both and note that Increments 2–3 consume `docs_repo_path` for writing.
2. **Recognize dynatrace-docs.** `is_dynatrace_docs` = the resolved repo has `managed/docstack.jsonc` AND `dynatrace/_content/` (and, when available, a git remote whose slug is `dynatrace-docs`). Name alone is not sufficient.
3. **Resolve the profile** (record `profile_source`): (a) `<docs_repo>/.dev-workflows/docs-profile.yml` exists → load it, `profile_source: in-repo`; (b) else `is_dynatrace_docs` → load `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/docs-profile.default.yml`, `profile_source: built-in`; (c) else (custom repo, no profile) → **inline on-demand profiling**: invoke the `/impl:docs:profile` flow against `docs_repo_path` (Skill/command), wait for it to write `.dev-workflows/docs-profile.yml`, then load it, `profile_source: generated`. If the user cancels profiling, stop with `PROFILE_REQUIRED`.
4. **Discover the specs dir.** Under `${REPOS_PATH:-/workspace}`, find a sibling dir whose detected vis-root (`specifications/` or `vis/`) contains a `<JIRA_KEY>*` folder (prefix match; mixed `-`/`_` + slug). If found → record `specs_dir` = that `<JIRA_KEY>*` folder. If not found → `specs_dir: none` (specs are additive; do NOT stop). If multiple candidate sibling repos match, list them and ask which to use.

Then add a **readiness table** at the end of Phase 0 summarizing: `$VAULT_PATH` + `jira-products/<KEY>` (ok), `docs_repo_path` + `profile_source`, `specs_dir` (path or `none`), and a note that code repos resolve in Phase 4. State "all discovery defaults to `/workspace`; on a host or when a path is missing the command asks."

Leave the **Phase 1.5/2** classification and the existing Phase 1 `$REPOS_PATH`/screenshots handling unchanged (Phase 1 already defaults `$REPOS_PATH` to `/workspace`).

- [ ] **Step 2: Verify the command still parses and references resolve**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
python3 - <<'PY'
import re, yaml, pathlib
t = pathlib.Path("commands/impl/jira/docs.md").read_text()
fm = yaml.safe_load(re.search(r"^---\n(.*?)\n---", t, re.S).group(1))
assert fm["name"] == "impl:jira:docs"
for needle in ["docs-profile.default.yml", "docs-profile.yml", "specifications/", "PROFILE_REQUIRED", "readiness"]:
    assert needle in t, f"missing: {needle}"
print("Phase 0 OK; profile + specs + readiness present")
PY
test -f references/dynatrace-docs/docs-profile.default.yml && echo "default profile present"
grep -q "name: impl:docs:profile" commands/impl/docs/profile.md && echo "/impl:docs:profile intact"
test -f commands/impl/docs.md && echo "/impl:docs intact"
```
Expected: all four lines print OK.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "feat(impl:jira:docs): Phase 0 preflight — docs-repo + profile + specs discovery

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Space constraint arg + applicability determination

**Files:**
- Modify: `commands/impl/jira/docs.md` — the intro line (~7–9), a Phase 0 arg-parse note, and a new **Phase 4.5** after Phase 4 (~line 162).

**Interfaces — Consumes:** `specs_dir` from Task 2's Phase 0 and the resolved repos from Phase 4. **Produces:** `target_spaces` (`[saas]` | `[managed]` | `[saas, managed]`) recorded for downstream phases.

- [ ] **Step 1: Document the optional space arg in the intro**

Update the intro (`Generate product documentation for the Jira Value Increment: $ARGUMENTS`) to state the signature `PRODUCT-NNNN [saas|managed]`: the optional second token is a **constraint** — `saas` or `managed` documents only that space (keeping the other space's rendered output unchanged); omitted → the command determines the applicable space(s) and confirms. Note `both` is intentionally NOT an accepted value (omit the arg instead).

- [ ] **Step 2: Parse the arg in Phase 0**

Add a Phase 0 step: parse `$ARGUMENTS` as `<JIRA_KEY> [space]`. If `space` ∈ {`saas`,`managed`} → record `space_constraint = space` (skip Phase 4.5 determination). If a second token is present but not `saas`/`managed` (e.g. `both`) → reject with a `choices` prompt: `["Drop the constraint — auto-determine (Recommended)", "saas", "managed", "Cancel"]`. If absent → `space_constraint = none`.

- [ ] **Step 3: Add Phase 4.5 — Determine applicable space(s)**

Insert a new `## Phase 4.5 — Determine applicable space(s)` after Phase 4. Logic:
- If `space_constraint` is set → `target_spaces = [space_constraint]`; print "Constrained to <space> (the other space's render is left unchanged — see Increment 3 techniques)." and skip the rest.
- Else **first-pass determination** from cheap signals: (a) the `jira-reader` VI/Epics text/labels for explicit "SaaS"/"Managed"/"both" mentions; (b) the resolved Phase-4 repos' space leaning (e.g., cluster/managed-oriented repos → managed; SaaS-service repos → saas; record as a hint, not authoritative); (c) `specs_dir` presence/name. Form a best-guess `target_spaces` and **confirm with the user**:
  ```
  choices: ["<auto-detected> (Recommended)", "saas only", "managed only", "both saas and managed", "Other… (describe)"]
  ```
  where `<auto-detected>` is the guess (e.g. "both saas and managed"). Record the confirmed `target_spaces`. (Authoritative determination from full diff/spec analysis is refined in Increment 2.)
- Display `target_spaces` in the Phase 1 context block and the Phase 2 plan.

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
python3 - <<'PY'
import pathlib
t = pathlib.Path("commands/impl/jira/docs.md").read_text()
assert "[saas|managed]" in t, "intro signature missing"
assert "## Phase 4.5 — Determine applicable space(s)" in t, "Phase 4.5 missing"
assert "space_constraint" in t and "target_spaces" in t
assert t.count("both") >= 1  # both is discussed (rejected as an arg; allowed as an outcome)
print("space arg + Phase 4.5 OK")
PY
```
Expected: `space arg + Phase 4.5 OK`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "feat(impl:jira:docs): optional saas|managed constraint + applicability determination (Phase 4.5)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Register + release 1.10.0

**Files:**
- Modify: `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` (version 1.9.0 → 1.10.0; refresh the `/impl:jira:docs` description), `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/README.md` (the `/impl:jira:docs` row + intro count if affected).

- [ ] **Step 1: Discover enumeration files + the current command description**

```bash
cd /workspace/ihudak-claude-plugins
grep -rl "/impl:jira:docs" --include='*.md' --include='*.json' . | sort
grep -n '"version"' plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
```

- [ ] **Step 2: Bump version to 1.10.0** in both `plugins/dev-workflows/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (keep them identical).

- [ ] **Step 3: Refresh the `/impl:jira:docs` description** (frontmatter `description:` in `commands/impl/jira/docs.md`, and the command-table row in `plugins/dev-workflows/README.md` + the manifest descriptions) to note: single-entry preflight discovery under `/workspace`, the optional `saas|managed` constraint, and on-demand profile bootstrap. Keep wording consistent across all files found in Step 1. (The full "AI-Containers as the default use-case" README narrative is deferred to Increment 3 — do not add it here.)

- [ ] **Step 4: Add the CHANGELOG entry** (top of `plugins/dev-workflows/CHANGELOG.md`, house format `## [1.10.0] — 2026-06-26` + `### Added`/`### Changed` with bold lead-ins):
  - **Added** — built-in dynatrace-docs default profile (`references/dynatrace-docs/docs-profile.default.yml`).
  - **Changed** — `/impl:jira:docs` Phase 0 now preflight-discovers the docs repo + profile (in-repo → built-in → inline `/impl:docs:profile`) and the VI's specs dir under `/workspace`; new Phase 4.5 determines/confirms the applicable space(s); optional `saas|managed` constraint added.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));b=json.load(open('.claude-plugin/marketplace.json'));assert a['version']=='1.10.0'==b['version'],(a['version'],b['version']);print('1.10.0 OK')"
grep -q "## \[1.10.0\] — 2026-06-26" plugins/dev-workflows/CHANGELOG.md && echo "CHANGELOG OK"
```
Expected: `1.10.0 OK`; `CHANGELOG OK`.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md plugins/dev-workflows/commands/impl/jira/docs.md
git status --short   # confirm only intended files
git commit -m "docs(dev-workflows): register /impl:jira:docs backbone + release 1.10.0

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## After all tasks

Use superpowers:finishing-a-development-branch on `ivgu/NOISSUE-impl-jira-docs-backbone`. Increments 2 (specs→planner, 3-way discrepancy, images→CDN) and 3 (multi-space write safety, dev-server verify + pages table, planning gate, squash/push + PR draft, README AI-Containers doc + the "which docs command?" disambiguation note) follow as their own spec→plan cycles.

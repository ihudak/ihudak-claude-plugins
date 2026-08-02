---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-27
---

# SP2 Increment 3a — Multi-space write safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/impl:jira:docs` Phase 6 write per space and protect the *rendered output* of the other space — via in-place `{{#if project='…'}}` conditionals for small diffs or override-copies + `managed/docstack.jsonc` `ignore` for structural ones — so a `saas`/`managed`-constrained run never changes the other space's render.

**Architecture:** Three coordinated edits to the `dev-workflows` plugin's markdown contract. (1) A new reference, `multi-space-writing.md`, is the single source of truth for the mechanics. (2) `doc-planner` gains multi-space awareness: it learns the profile + `target_spaces`, classifies each target's `space_scope`, and recommends a per-target `write_strategy`. (3) The `/impl:jira:docs` command gains a new **Phase 5.9** approval gate (present + override the recommended strategies) and a rebuilt **Phase 6** that routes per space and applies the chosen strategy, the shared-registries lock-step, and token-correctness validation. A release bump ships it as v1.12.0.

**Tech Stack:** Markdown command/agent/reference files (Handlebars-aware prose contracts), YAML profile, JSON plugin manifests. **No code, no test framework** — this is a documentation-driven agent plugin, so every task's verification is *structural*: `grep` for required anchors, `python3` YAML/JSON parse for validity, and link/key-existence checks. There is no `pytest`/`npm test` suite in this repo; the structural checks below ARE the test cycle.

## Global Constraints

- Plugin repo is `/workspace/ihudak-claude-plugins`; the plugin lives under `plugins/dev-workflows/`. Plugin `main` is at `806d597`, v1.11.0.
- Work on a branch off `origin/main`: **`ivgu/NOISSUE-impl-jira-docs-multispace`**. Never implement on `main`.
- **`marketplace.json` version is at `plugins[0].version`, NOT the top-level** — the top-level `version` (if any) is the marketplace's own, not the plugin's.
- `plugin.json` plugin version is the **top-level** `"version"` key.
- Commit messages end with the trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Stage only the explicit files each task names with `git add <path>`. Never `git add -A`/`.`; never stage `.superpowers/`, `.docstack`, or unrelated files.
- Reference-path citation format inside command/agent prose is `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md` (matches the existing `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` citations).
- **Render-unchanged ≠ file-untouched:** the `saas`/`managed` constraint protects the other space's *rendered output*, not its source file. Editing a shared source file to add an `{{#if project='<otherspace>'}}` clause is a valid small-diff path (the file changes; the constrained space's render does not).
- `both` is **not** an accepted space value anywhere; spaces are `saas`, `managed`, with `target_spaces ∈ {[saas], [managed], [saas, managed]}`.
- Do NOT touch the zero-external-API invariant (no push/PR/squash in the command) — that is Increment 3c.
- **Out of scope (do not implement here):** README Vale-fallback-note restore, "which docs command?" disambiguation, the "All five `/impl:*`" count fix (all 3d); render verification (3b); finish/handoff (3c).
- Profile field names are fixed by the built-in default profile (`references/dynatrace-docs/docs-profile.default.yml`): `spaces[].{id,content_root,snippet_root,base_path}`, `cross_space_override.{manifest,mechanism,rule}`, `shared_registries[].{files,when,rule}`, `tokens.{latest_tag,gen3_settings_breadcrumb,project_conditionals}`. Cite these exact paths; do not invent new keys.

---

## File Structure

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/references/dynatrace-docs/multi-space-writing.md` (NEW) | SSOT for the multi-space mechanics: shared vs single pages, the render-unchanged invariant, the conditional vs override-copy strategies + heuristic, shared-registries lock-step, token correctness. Cited by both the agent and the command so neither inlines the mechanics. | 1 |
| `plugins/dev-workflows/agents/doc-planner.md` | Add multi-space awareness: new `profile` + `target_spaces` inputs; a process step that classifies `space_scope`/`rendered_in` and recommends a per-target `write_strategy`; the corresponding output-schema fields + one hard rule. | 2 |
| `plugins/dev-workflows/commands/impl/jira/docs.md` (Phase 5.7 + new 5.9) | Pass `profile` + `target_spaces` into the `doc-planner` invocation; add **Phase 5.9** — present the recommended per-target write strategies, let the user approve/override, record `write_strategies[]`. | 3 |
| `plugins/dev-workflows/commands/impl/jira/docs.md` (Phase 6) | Rebuild Phase 6 to consume `profile` + `target_spaces` + `write_strategies[]`: per-space routing, conditional in-place edit, override-copy + docstack `ignore`, shared-registries lock-step, token-correctness validation. | 4 |
| `plugins/dev-workflows/.claude-plugin/plugin.json`, `/.claude-plugin/marketplace.json`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/README.md` | Release bump to v1.12.0 + changelog/readme entries. | 5 |

---

## Task 1: `multi-space-writing.md` reference (the mechanics SSOT)

**Files:**
- Create: `plugins/dev-workflows/references/dynatrace-docs/multi-space-writing.md`

**Interfaces:**
- Consumes: nothing (foundation task). Cites profile keys that already exist in `references/dynatrace-docs/docs-profile.default.yml`.
- Produces: a reference document with these section anchors that Tasks 2 and 4 cite — `## 1. Shared vs single pages`, `## 2. The invariant — render-unchanged ≠ file-untouched`, `## 3. Two protection strategies` (with `### 3.1 Conditional` and `### 3.2 Override-copy`), `## 4. Choosing a strategy (the heuristic)`, `## 5. Shared-registries lock-step`, `## 6. Token correctness`.

- [ ] **Step 1: Write the reference file**

Create `plugins/dev-workflows/references/dynatrace-docs/multi-space-writing.md` with exactly this content:

````markdown
# Multi-space writing (dynatrace-docs)

How `/impl:jira:docs` Phase 6 writes documentation across more than one space
(SaaS + Managed in dynatrace-docs) while honoring the `saas`/`managed`
constraint — i.e. changing one space's documentation **without altering the
other space's rendered output**.

This is the single source of truth for the mechanics. The command (Phase 5.9,
Phase 6) and `doc-planner` both cite it; neither inlines these rules.

All paths and rules below come from the resolved `profile` (the built-in
dynatrace-docs default, an in-repo `.dev-workflows/docs-profile.yml`, or a
generated one). Read them from the profile — do not hard-code dynatrace-docs
specifics.

## 1. Shared vs single pages

Each space has a `content_root` (and `snippet_root`) under `profile.spaces[]`.
A page's **home space** is the space whose `content_root`/`snippet_root` prefixes
its path.

A page is **shared** when its rendered output appears in more than one space.
In dynatrace-docs this happens through `profile.cross_space_override`: the
Managed manifest (`cross_space_override.manifest`, e.g. `managed/docstack.jsonc`)
pulls an allowlist of `dynatrace/_content/...` (SaaS) pages into the Managed
render. So a page whose home space is `saas` is typically **shared** (rendered
in both `saas` and `managed`), while a page under the Managed `content_root`
(`managed/_content/...`) is **single** (rendered only in `managed`).

- `space_scope: shared` — rendered in `>1` space; `rendered_in` lists them.
- `space_scope: single` — rendered in exactly one space (its home space).

Whether a shared page needs protection depends on the run's `target_spaces`:
protection is required only when the page renders in a space that is **not** in
`target_spaces` (that space's render must stay unchanged), or when a
both-spaces run needs the two renders to **differ**.

## 2. The invariant — render-unchanged ≠ file-untouched

The `saas`/`managed` constraint protects the **rendered output** of the other
space, not the source file. It is correct and expected to **edit a shared
source file** as long as the constrained (protected) space's *render* does not
change. Adding an `{{#if project='managed'}}…{{/if}}` block to a shared SaaS
page changes the file but renders nothing new for SaaS — that is the
small-diff path, not a violation.

## 3. Two protection strategies

### 3.1 Conditional (small / localized delta) — preferred for small diffs

Edit the **shared source page in place** and wrap the per-space delta in a
project conditional from `profile.tokens.project_conditionals`:

```handlebars
{{#if project='managed'}}
…content that must render only for Managed…
{{/if}}
```

The other space's render is unchanged because the wrapped content is excluded
for it. Use the project value of the space the delta is **for** (`target_space`).

### 3.2 Override-copy (significant / structural divergence)

When the two spaces must differ substantially (new sections, large rewrites,
structural changes), copy the page into the **destination space's**
`content_root` at the same relative path, then make the override win:

1. Copy `(<home content_root>)/<rel>` → `(<dest space content_root>)/<rel>`
   (same `<rel>` under each `content_root`). Edit the copy for the dest space.
2. Add the **shared source path** to the override manifest's `ignore` allowlist
   per `profile.cross_space_override.rule` — for dynatrace-docs: add the
   `../dynatrace/_content/<rel>` path to the `ignore` block in
   `managed/docstack.jsonc` so the Managed override wins and is not silently
   shadowed by the pulled-in SaaS page. (See [[managed-docs-override-shadowing]].)

The home space's render is unchanged (its source is untouched); the dest
space now renders the override copy.

## 4. Choosing a strategy (the heuristic)

`doc-planner` recommends per shared target, from the divergence it already
estimates while building the checklist:

- **localized wording / a single added block / one differing value** → `conditional`.
- **structural change / new sections / large rewrite for one space** → `override-copy`.
- **no protection needed** (single-space page, or a both-spaces run whose
  content is identical for both) → `plain`.

The recommendation is **advisory**: the user approves or overrides it in
Phase 5.9 before any file is written.

## 5. Shared-registries lock-step

When a write **renames, retitles, or creates** a settings-schema page in the
condition described by `profile.shared_registries[].when` (for dynatrace-docs:
a page under `dynatrace/_content/dynatrace-api/environment-api/settings/schemas/`),
update **every** file in that entry's `files` list together, per its `rule`
(for dynatrace-docs: update the `text:` entry in BOTH `schema-ids.yml` and
`schema-mappings.yml` in lock-step). The two registries must stay
byte-for-byte consistent on the shared field.

## 6. Token correctness

Before the style/review gates, validate the tokens the write emitted, per
`profile.tokens`:

- **Conditionals are balanced** — every `{{#if project='…'}}` has a matching
  `{{/if}}`.
- **Project values are valid** — the `project='…'` value is a known space/edition
  (`saas`, `managed`, `classic`, `latest`); flag anything else.
- **gen3/Classic tokens are well-formed** — `profile.tokens.latest_tag`
  (`{{tag kind='latest'}}`) and `profile.tokens.gen3_settings_breadcrumb`
  (`::app-settings::`) are spelled exactly and used in a space that supports them.

Flag malformed or space-inappropriate tokens for fixing **before** Phase 6.7
(style check) and Phase 7 (`doc-reviewer`).
````

- [ ] **Step 2: Verify the file exists with every required section anchor**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
for h in \
  "^# Multi-space writing" \
  "^## 1. Shared vs single pages" \
  "^## 2. The invariant" \
  "^## 3. Two protection strategies" \
  "^### 3.1 Conditional" \
  "^### 3.2 Override-copy" \
  "^## 4. Choosing a strategy" \
  "^## 5. Shared-registries lock-step" \
  "^## 6. Token correctness" ; do \
  grep -qE "$h" plugins/dev-workflows/references/dynatrace-docs/multi-space-writing.md && echo "OK  $h" || echo "MISS $h" ; \
done
```
Expected: nine `OK` lines, zero `MISS`.

- [ ] **Step 3: Verify every profile key the reference cites actually exists in the default profile**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
for k in "content_root" "snippet_root" "cross_space_override" "manifest" "shared_registries" "tokens" "project_conditionals" "latest_tag" "gen3_settings_breadcrumb"; do \
  grep -q "$k" plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml && echo "OK  $k" || echo "MISS $k" ; \
done
```
Expected: nine `OK` lines (every cited key is a real profile key), zero `MISS`.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/dynatrace-docs/multi-space-writing.md
git commit -m "$(cat <<'EOF'
NOISSUE Add multi-space-writing reference (dynatrace-docs SaaS/Managed write safety)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `doc-planner` multi-space awareness — recommend `write_strategy`

**Files:**
- Modify: `plugins/dev-workflows/agents/doc-planner.md`

**Interfaces:**
- Consumes: the `multi-space-writing.md` reference from Task 1 (cited by path).
- Produces: two new inputs (`profile`, `target_spaces`) and, on every checklist target, the fields `space_scope` (`shared|single`), `rendered_in` (list of space ids), and `write_strategy: {strategy: conditional|override-copy|plain, rationale: <str>, target_space: <space id>}`. Phase 5.9 (Task 3) reads `write_strategy`; Phase 6 (Task 4) reads all three.

- [ ] **Step 1: Add the two new inputs to the Inputs block**

In `plugins/dev-workflows/agents/doc-planner.md`, the Inputs YAML block currently ends:
```yaml
specs_dir:              <absolute path to the VI's spec folder (PRODUCT-NNNN*), or null; the authoritative intended-behavior source>
repo_root:              <absolute path to the docs repo root>
```
Replace that with:
```yaml
specs_dir:              <absolute path to the VI's spec folder (PRODUCT-NNNN*), or null; the authoritative intended-behavior source>
repo_root:              <absolute path to the docs repo root>
profile:                <the resolved docs-profile (built-in dynatrace-docs default, in-repo, or generated); supplies spaces[], cross_space_override, shared_registries, tokens>
target_spaces:          <the run's resolved space set: [saas] | [managed] | [saas, managed]>
```

- [ ] **Step 2: Add the multi-space process step (new step 10) at the end of the Process section**

The Process section's last step is step 9 ("Source-truth verification …"), which ends just before the `## Output — the documentation checklist` heading. Insert this new step immediately before that heading:

````markdown
10. **Recommend a per-target multi-space write strategy** (per `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md`). For each write target:
    - Determine its **home space** by matching `target_path` against each `profile.spaces[].content_root`/`snippet_root` prefix.
    - Determine `rendered_in` and `space_scope`: a page is **`shared`** when `profile.cross_space_override` pulls its home `content_root` into another space's render (in dynatrace-docs, a `saas`-home page under `dynatrace/_content` is pulled into the Managed render, so `rendered_in: [saas, managed]`); otherwise **`single`** (`rendered_in: [<home space>]`).
    - Recommend `write_strategy.strategy`:
      - **`plain`** — no protection needed: a `single` page whose home space is in `target_spaces`, OR a `[saas, managed]` run whose planned content is identical for every space the page renders in.
      - **`conditional`** — the page is `shared` and the planned change is localized (a single added block, localized wording, or one differing value) AND it must NOT alter the render of a space outside `target_spaces` (or must differ per space within a both-spaces run). The shared source is edited in place; the delta is wrapped in `{{#if project='<target_space>'}}…{{/if}}`.
      - **`override-copy`** — the page is `shared` and the divergence is structural (new sections, large rewrite). The page is copied into the destination space's `content_root` and the shared path is added to `cross_space_override`'s `ignore` allowlist.
    - Set `write_strategy.target_space` to the space the change is **for**: for `conditional`, the `project='…'` value of the wrapped delta; for `override-copy`, the destination space the copy lands in; for `plain`, the page's home space.
    - Set `write_strategy.rationale` to a 1-line justification grounded in the divergence you estimated (used by Phase 5.9's table).
    - This recommendation is **advisory** — the orchestrator presents it for approval/override in Phase 5.9 before any write. Do NOT write files.
````

- [ ] **Step 3: Add the output-schema fields to each checklist target**

In the `## Output — the documentation checklist` YAML block, the per-target entry currently begins:
```yaml
  - target_path: <absolute path>
    kind:        extend-existing | new-page-in-existing-section | new-section
    topics:
```
Replace those three lines with:
```yaml
  - target_path: <absolute path>
    kind:        extend-existing | new-page-in-existing-section | new-section
    space_scope: shared | single          # shared = rendered in >1 space (per profile.cross_space_override); single = its home space only
    rendered_in: [<space id>, ...]         # the spaces this page's render appears in
    write_strategy:                        # advisory; approved/overridden in /impl:jira:docs Phase 5.9
      strategy:    conditional | override-copy | plain
      rationale:   <1-line justification grounded in the estimated divergence>
      target_space: <space id>             # conditional → the {{#if project='<target_space>'}} value; override-copy → the destination space the copy lands in; plain → the home space
    topics:
```

- [ ] **Step 4: Add a hard rule**

In the `## Hard rules` bullet list, append this bullet at the end:
```markdown
- NEVER pick `override-copy` over `conditional` to "play it safe" — an override-copy duplicates a whole page and must then be maintained in two places. Recommend `override-copy` ONLY for genuinely structural divergence; localized deltas are `conditional`. The user can still override either way in Phase 5.9. NEVER write files or perform the copy/`ignore` edit yourself — Phase 6 does that.
```

- [ ] **Step 5: Verify the edits parse and contain the new contract**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
python3 - <<'PY'
import re, sys
p = "plugins/dev-workflows/agents/doc-planner.md"
t = open(p).read()
# Frontmatter still valid YAML
import_ok = True
fm = t.split('---',2)
try:
    import yaml  # noqa
    yaml.safe_load(fm[1])
    print("OK  frontmatter parses")
except ImportError:
    print("SKIP frontmatter (pyyaml not installed) — visual-check the --- block")
except Exception as e:
    print("FAIL frontmatter:", e); sys.exit(1)
needles = [
  "profile:", "target_spaces:",
  "Recommend a per-target multi-space write strategy",
  "references/dynatrace-docs/multi-space-writing.md",
  "space_scope: shared | single",
  "rendered_in:",
  "write_strategy:",
  "strategy:    conditional | override-copy | plain",
  "target_space:",
  "NEVER pick `override-copy` over `conditional`",
]
miss = [n for n in needles if n not in t]
for n in needles: print(("OK  " if n not in miss else "MISS")+" "+n)
sys.exit(1 if miss else 0)
PY
```
Expected: every needle `OK`, exit 0 (the frontmatter line prints `OK` or `SKIP`).

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/doc-planner.md
git commit -m "$(cat <<'EOF'
NOISSUE doc-planner: recommend per-target multi-space write_strategy

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `/impl:jira:docs` — feed the planner + new Phase 5.9 approval gate

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md` (Phase 5.7 invocation brief; new Phase 5.9 inserted after Phase 5.8)

**Interfaces:**
- Consumes: `doc-planner`'s `write_strategy`/`space_scope`/`rendered_in` per target (Task 2); the `profile` (Phase 0) and `target_spaces` (Phase 4.5) already resolved upstream.
- Produces: `write_strategies[]` — the user-approved per-target strategy list, keyed by `target_path`, each `{target_path, strategy ∈ {conditional, override-copy, plain}, target_space, rationale}` — consumed by Phase 6 (Task 4).

- [ ] **Step 1: Pass `profile` + `target_spaces` into the Phase 5.7 `doc-planner` invocation**

In `plugins/dev-workflows/commands/impl/jira/docs.md`, the Phase 5.7 invocation brief currently ends:
```
  > code_repos:           [the Phase-4 resolved {slug, path} map; [] if none resolved]
  > specs_dir:            [resolved <specs_dir> from Phase 0, or null]"
```
Replace with:
```
  > code_repos:           [the Phase-4 resolved {slug, path} map; [] if none resolved]
  > specs_dir:            [resolved <specs_dir> from Phase 0, or null]
  > profile:              [the docs-profile loaded in Phase 0 — drives space routing + the multi-space write strategy]
  > target_spaces:        [the resolved target_spaces from Phase 4.5: [saas] | [managed] | [saas, managed]]"
```

- [ ] **Step 2: Insert Phase 5.9 after Phase 5.8**

Phase 5.8 ends with the line `Pass \`discrepancy_decisions\` to Phase 6.` followed by a `---` separator, then `## Phase 6.2 — CDN image handoff`. Insert this new phase **between** that `---` and the `## Phase 6.2` heading:

````markdown
## Phase 5.9 — Write-strategy approval (multi-space safety)

Run this phase when the `doc-planner` checklist contains **any** target whose
`write_strategy.strategy` is `conditional` or `override-copy` (i.e. at least one
shared page needs cross-space protection). If every target is `plain`, skip to
Phase 6 — there is nothing to protect.

The mechanics are defined in
`${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md`; this
phase only confirms the per-page **strategy choice** before Phase 6 writes.

1. **Present the recommended strategies** (informational, before asking) — one
   row per non-`plain` target:
   ```
   | # | Page (target_path) | space_scope | rendered_in | Recommended | For space | Rationale |
   ```
   `Recommended` is `write_strategy.strategy`; `For space` is `write_strategy.target_space`. Remind the user of the invariant: a `conditional` edits the shared file in place but leaves the protected space's *render* unchanged; an `override-copy` duplicates the page into the other space and allowlists it in `cross_space_override`'s `ignore`.

2. **Batch decision:**
   ```
   choices: ["Accept all recommended (Recommended)", "Decide per page", "Cancel", "Other… (describe)"]
   ```

3. **Per page** (if "Decide per page"): for each non-`plain` target, show the row and:
   ```
   choices: ["Conditional — edit shared page in place ({{#if project='…'}})", "Override-copy — separate page in the other space + docstack ignore", "Cancel", "Other… (describe)"]
   ```
   The default/recommended choice is the planner's `write_strategy.strategy`, listed first.

4. **Record `write_strategies[]`** keyed by `target_path`: `{target_path, strategy ∈ {conditional, override-copy, plain}, target_space, rationale}`. Targets the planner marked `plain` are carried through as `plain` without prompting. Pass `write_strategies` to Phase 6.

---
````

- [ ] **Step 3: Verify the insertions parse and are correctly placed**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
python3 - <<'PY'
import sys
t = open("plugins/dev-workflows/commands/impl/jira/docs.md").read()
checks = {
  "5.7 passes profile":        "> profile:              [the docs-profile loaded in Phase 0",
  "5.7 passes target_spaces":  "> target_spaces:        [the resolved target_spaces from Phase 4.5",
  "Phase 5.9 heading":         "## Phase 5.9 — Write-strategy approval",
  "5.9 cites reference":       "references/dynatrace-docs/multi-space-writing.md",
  "5.9 produces write_strategies": "Record `write_strategies[]`",
  "5.9 conditional choice":    "Conditional — edit shared page in place",
  "5.9 override choice":       "Override-copy — separate page in the other space",
}
miss=[k for k,v in checks.items() if v not in t]
for k,v in checks.items(): print(("OK  " if k not in miss else "MISS")+" "+k)
# ordering: 5.8 < 5.9 < 6.2 < 6
i58, i59 = t.find("## Phase 5.8"), t.find("## Phase 5.9")
i62, i6  = t.find("## Phase 6.2"), t.find("## Phase 6 — Write")
order_ok = -1 < i58 < i59 < i62 < i6
print(("OK  " if order_ok else "MISS")+" ordering 5.8<5.9<6.2<6", (i58,i59,i62,i6))
sys.exit(0 if (not miss and order_ok) else 1)
PY
```
Expected: every check `OK`, ordering `OK`, exit 0.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "$(cat <<'EOF'
NOISSUE impl:jira:docs: feed profile+target_spaces to planner; add Phase 5.9 write-strategy approval

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `/impl:jira:docs` Phase 6 — per-space routing + write mechanics

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md` (Phase 6)

**Interfaces:**
- Consumes: `profile` + `target_spaces` (Phase 0 / 4.5); the approved `write_strategies[]` (Phase 5.9, Task 3); the per-target schema from `doc-planner` (Task 2); the mechanics in `multi-space-writing.md` (Task 1).
- Produces: the written docs across spaces with the other space's render protected — no new downstream interface; Phase 6.5/6.7/7 consume the written files as before.

- [ ] **Step 1: Add the Phase 6 preamble — consume profile, target_spaces, write_strategies**

In `plugins/dev-workflows/commands/impl/jira/docs.md`, the Phase 6 section currently opens:
```markdown
## Phase 6 — Write documentation

The main command writes the markdown following the `doc-planner` checklist. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5.7 already loaded.

For each target in the confirmed write-target list:
```
Replace that with:
```markdown
## Phase 6 — Write documentation

The main command writes the markdown following the `doc-planner` checklist. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5.7 already loaded.

Multi-space safety is governed by `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md`. Before writing, resolve **per-space routing** for each target:
- Determine the target's **home space** by matching `target_path` against each `profile.spaces[].content_root`/`snippet_root` prefix.
- A target whose home space is **not** in `target_spaces` is a routing error — stop and surface it (it should not occur once Phase 4.5/5.5 honored `target_spaces`); the one legitimate write outside `target_spaces` is an `override-copy` destination (step 0 below).
- Apply the **approved `write_strategy`** for the target (from Phase 5.9 `write_strategies[]`; absent ⇒ `plain`).

For each target in the confirmed write-target list:

0. **Apply the approved write strategy** (per `write_strategies[<target_path>]` and `multi-space-writing.md`):
   - **`plain`** → write the page in its home space's `content_root` as usual (steps 1–7 below). No cross-space action.
   - **`conditional`** → edit the **shared source page in place** in its home space and wrap the per-space delta in `{{#if project='<target_space>'}}…{{/if}}` (project value from `profile.tokens.project_conditionals`). The protected space's render does not change because the wrapped content is excluded for it. Continue with steps 1–7 for the edited content.
   - **`override-copy`** → copy the page into `profile.spaces[]` `content_root` of `write_strategy.target_space` at the **same relative path** under that `content_root` (`<home content_root>/<rel>` → `<dest content_root>/<rel>`), edit the copy for the destination space (steps 1–7), then make the override win: add the **shared source path** to the override manifest's `ignore` allowlist per `profile.cross_space_override.rule` (for dynatrace-docs: add `../dynatrace/_content/<rel>` to the `ignore` block of `managed/docstack.jsonc`). Leave the home-space source untouched so its render is unchanged.
```

- [ ] **Step 2: Append the shared-registries lock-step and token-correctness steps to Phase 6**

Phase 6's numbered steps currently end at step 7 ("Apply discrepancy decisions …"), whose last sub-bullet is the `write <bug_report_destination>/<JIRA_KEY>-implementation-gaps.md …` line, followed by the paragraph beginning `Write to the resolved \`docs_repo_path\` (Phase 0).` Insert these two steps **between** step 7's last sub-bullet and that paragraph:
```markdown
8. **Shared-registries lock-step** (per `profile.shared_registries` and `multi-space-writing.md` §5). If any write **renames, retitles, or creates** a page matching a `shared_registries[].when` condition (for dynatrace-docs: a settings-schema page under `dynatrace/_content/dynatrace-api/environment-api/settings/schemas/`), update **every** file in that entry's `files` list together per its `rule` (for dynatrace-docs: the `text:` entry in BOTH `schema-ids.yml` and `schema-mappings.yml`, in lock-step). Stage all of them in the same commit.
9. **Token-correctness validation** (per `profile.tokens` and `multi-space-writing.md` §6). On every file written or edited in this phase, validate before handing off to the style/review gates: every `{{#if project='…'}}` has a matching `{{/if}}`; each `project='…'` value is a known space/edition (`saas`, `managed`, `classic`, `latest`); `{{tag kind='latest'}}` and `::app-settings::` are spelled exactly and used only in a space that supports them. Fix malformed or space-inappropriate tokens now; do not defer them to Phase 6.7.
```

- [ ] **Step 3: Verify the Phase 6 edits parse and contain the new mechanics**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
python3 - <<'PY'
import sys
t = open("plugins/dev-workflows/commands/impl/jira/docs.md").read()
p6 = t[t.find("## Phase 6 — Write documentation"):t.find("## Phase 6.5")]
checks = {
  "cites reference":        "references/dynatrace-docs/multi-space-writing.md" in p6,
  "home space routing":     "home space" in p6 and "content_root" in p6,
  "consumes target_spaces": "target_spaces" in p6,
  "consumes write_strategies": "write_strategies" in p6,
  "step 0 strategy":        "Apply the approved write strategy" in p6,
  "conditional mechanic":   "{{#if project='<target_space>'}}" in p6,
  "override-copy mechanic": "override-copy" in p6 and "ignore" in p6 and "managed/docstack.jsonc" in p6,
  "shared-registries step": "Shared-registries lock-step" in p6 and "schema-ids.yml" in p6 and "schema-mappings.yml" in p6,
  "token-correctness step": "Token-correctness validation" in p6,
}
miss=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(("OK  " if v else "MISS")+" "+k)
sys.exit(0 if not miss else 1)
PY
```
Expected: every check `OK`, exit 0.

- [ ] **Step 4: Sanity-check the whole command file still has balanced fences and all phases present**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
python3 - <<'PY'
import sys
t=open("plugins/dev-workflows/commands/impl/jira/docs.md").read()
# fenced code blocks balanced
fences = t.count("\n```")
print(("OK  " if fences%2==0 else "MISS")+f" code-fence parity (count={fences})")
phases=["## Phase 0","## Phase 1","## Phase 4.5","## Phase 5.7","## Phase 5.8","## Phase 5.9","## Phase 6 — Write","## Phase 6.5","## Phase 6.7"]
miss=[p for p in phases if p not in t]
for p in phases: print(("OK  " if p not in miss else "MISS")+" "+p)
sys.exit(0 if (fences%2==0 and not miss) else 1)
PY
```
Expected: fence parity `OK`, every phase `OK`, exit 0.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "$(cat <<'EOF'
NOISSUE impl:jira:docs Phase 6: per-space routing + conditional/override-copy + registries lock-step + token checks

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Release v1.12.0 (manifests + CHANGELOG + README)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `plugins/dev-workflows/README.md`

**Interfaces:**
- Consumes: the merged behavior from Tasks 1–4 (describes it).
- Produces: a released v1.12.0 (no code interface).

- [ ] **Step 1: Bump `plugin.json` (top-level version)**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, change the top-level `"version"` from `"1.11.0"` to `"1.12.0"`.

- [ ] **Step 2: Bump `marketplace.json` (plugins[0].version — NOT top-level)**

In `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`, change the dev-workflows entry's version under `plugins[0].version` from `1.11.0` to `1.12.0`. Verify you edited `plugins[0].version`, not any top-level field.

- [ ] **Step 3: Add the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, insert a new section immediately above `## [1.11.0] — 2026-06-26`:
```markdown
## [1.12.0] — 2026-06-27

### Added
- **`references/dynatrace-docs/multi-space-writing.md`.** Single source of truth for writing dynatrace-docs across the SaaS and Managed spaces: shared-vs-single pages, the render-unchanged-≠-file-untouched invariant, the conditional-vs-override-copy strategies + heuristic, the shared-registries lock-step, and token correctness. Cited by `doc-planner` and `/impl:jira:docs`.

### Changed
- **`/impl:jira:docs` multi-space write safety (Increment 3a).** `doc-planner` now receives the resolved `profile` + `target_spaces`, classifies each target's `space_scope`/`rendered_in`, and recommends a per-target `write_strategy` (`conditional` | `override-copy` | `plain`). A new **Phase 5.9** presents those recommendations for approval/override. **Phase 6** consumes `profile` + `target_spaces` + the approved strategies to route each write to the correct space's `content_root`, edit shared pages in place with `{{#if project='…'}}` conditionals for small diffs, override-copy + `managed/docstack.jsonc` `ignore` for structural ones, keep `schema-ids.yml`/`schema-mappings.yml` in lock-step, and validate token correctness — so a `saas`/`managed`-constrained run never changes the other space's rendered output.
```

- [ ] **Step 4: Add a README note**

In `plugins/dev-workflows/README.md`, find the references list that already contains the line:
```markdown
- `references/dynatrace-docs/changelog-guidelines.md` — dynatrace-docs changelog writing rules + managed owners policy (consulted by the `dynatrace-docs-frontmatter` skill)
```
Immediately **above** that line, add:
```markdown
- `references/dynatrace-docs/multi-space-writing.md` — how `/impl:jira:docs` writes across the SaaS and Managed spaces while protecting the other space's render (conditional vs override-copy, docstack `ignore`, shared-registries lock-step, token correctness)
```

- [ ] **Step 5: Verify the manifests parse and carry 1.12.0, and the docs mention the feature**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
python3 - <<'PY'
import json,sys
pj=json.load(open("plugins/dev-workflows/.claude-plugin/plugin.json"))
mk=json.load(open(".claude-plugin/marketplace.json"))
ok_pj = pj.get("version")=="1.12.0"
mkv = mk["plugins"][0].get("version")
ok_mk = mkv=="1.12.0"
print(("OK  " if ok_pj else "MISS")+f" plugin.json top-level version = {pj.get('version')}")
print(("OK  " if ok_mk else "MISS")+f" marketplace.json plugins[0].version = {mkv}")
cl=open("plugins/dev-workflows/CHANGELOG.md").read()
ok_cl = "## [1.12.0] — 2026-06-27" in cl and "multi-space-writing.md" in cl
print(("OK  " if ok_cl else "MISS")+" CHANGELOG [1.12.0] entry")
rm=open("plugins/dev-workflows/README.md").read()
ok_rm = "multi-space-writing.md" in rm
print(("OK  " if ok_rm else "MISS")+" README mentions multi-space-writing.md")
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
NOISSUE Release dev-workflows v1.12.0 — multi-space write safety (Increment 3a)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Spec coverage** (against `spec/2026-06-26-sp2-increment3a-multi-space-write-safety-design.md`):
- Design A (per-space routing) → Task 4 step 1. ✅
- Design B (per-shared-page `write_strategy` from `doc-planner`) → Task 2. ✅
- Design C (override-copy + docstack `ignore`) → Task 1 §3.2, Task 4 step 1. ✅
- Design D (conditional in-place edit) → Task 1 §3.1, Task 4 step 1. ✅
- Design E (shared-registries lock-step) → Task 1 §5, Task 4 step 2. ✅
- Design F (token/conditional correctness) → Task 1 §6, Task 4 step 2. ✅
- New Phase 5.9 approval gate → Task 3. ✅
- New `multi-space-writing.md` reference → Task 1. ✅
- Heuristic = planner's estimated divergence (open item, user-confirmed) → Task 1 §4, Task 2 step 2. ✅
- Release bump v1.12.0 → Task 5. ✅
- Render-unchanged ≠ file-untouched precision → Task 1 §2, Global Constraints, Task 4 conditional mechanic. ✅
- Out-of-scope carried obligations (3b/3c/3d) → excluded per Global Constraints. ✅

**2. Placeholder scan:** No "TBD"/"TODO"/"implement later" in plan steps. The literal `<!-- TODO: … -->` and `TODO-upload` strings referenced are pre-existing Phase 6 behavior, not plan placeholders. ✅

**3. Type/name consistency:** `write_strategy` object shape (`strategy`/`rationale`/`target_space`) is identical in Task 2 (planner output), Task 3 (Phase 5.9 reads `write_strategy.strategy`/`.target_space`), and Task 4 (Phase 6 reads `write_strategies[<target_path>]`). `write_strategies[]` (approved list, command-side) vs `write_strategy` (per-target field, planner-side) are deliberately distinct names. `space_scope`/`rendered_in` consistent across Tasks 2 and 4. Profile keys (`content_root`, `cross_space_override.rule`, `shared_registries`, `tokens.project_conditionals`, `tokens.latest_tag`, `tokens.gen3_settings_breadcrumb`) match the default profile verbatim. ✅

**Model guidance for execution:** Task 1 — cheapest tier (full content supplied, transcription). Task 5 — cheapest tier (mechanical), but the reviewer MUST confirm `marketplace.json` was edited at `plugins[0].version`. Tasks 2 and 3 — standard model (schema + phase prose). Task 4 — most capable model (keystone; the render-protection invariant must be exactly right). Final whole-branch review — most capable model.

---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-26
---

# SP2 Increment 2 — inputs & analysis: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax. These are Markdown agent/command/reference files + JSON manifests — "tests" are structural verifications (parse, grep, schema-load), not a unit suite.

**Goal:** Wire the VI's spec tree into `/impl:jira:docs` as the authoritative "intended" source (3-way discrepancy: Jira | Spec | Code), and auto-feed spec/Jira images into an interactive CDN handoff.

**Architecture:** Extend existing components at their known extension points — `references/source-truth.md` (spec as authoritative source + 3-way), `agents/doc-planner.md` (new `specs_dir` input, spec-tree read, `spec-markdown` technique, `spec_phrasing`), `agents/jira-reader.md` (`attachments[]` image enumeration), and `commands/impl/jira/docs.md` (Phase 5.7 passes `specs_dir`; Phase 5.8 3-way; new image-candidate + interactive-CDN steps). No new agents.

**Tech Stack:** Markdown (agent/command/reference), YAML (handoff/schema), JSON (manifests), Claude Code plugin conventions, git.

## Global Constraints

- Plugin repo `/workspace/ihudak-claude-plugins/plugins/dev-workflows/`. On `main` (currently `3051148`) → **branch first** off `origin/main`.
- **Spec = authoritative "intended"** source, corroborated by Jira; **code = actual**. Discrepancy is **3-way** `Jira | Spec | Code`: code-differs-from-spec is the main case; spec-differs-from-Jira is surfaced (spec wins).
- **Authoritative spec files:** VI-level spec (`PRODUCT-<key>*.md` / `specification.md` at the folder root) + per-epic specs (`epics/epic-*.md`) + each epic's `requirements.md` + `design.md`. `tasks.md` = secondary "planned" signal. **Ignore** `idea.md`/`prompt.md`/generated HTML. `doc-planner` reads **selectively from the `specs_dir` path** (requirements/design/epic+VI specs first) to bound volume.
- When `specs_dir` is null/empty → behave exactly as today (Jira-vs-code 2-way; `spec_phrasing: "(no spec)"`). Backward-compatible.
- **CDN handoff:** interactive (list cdn images + target page/anchor + alt → user uploads + pastes each link → write real URLs) **with async fallback** (existing stage under `<screenshot_staging_dir>` + `TODO-upload` placeholder + Phase 9 list).
- **Image sources:** recursive `specs_dir` scan + `jira-reader` `attachments[]` (enumerate image files; do NOT read attachment content) + the existing manual paths.
- Extend existing agents/phases only. Do NOT break `/impl:docs`, `/impl:docs:profile`, `/impl:jira:epics`, or `/impl:jira:release-notes` (diff-summarizer / release-notes-writer never receive `specs_dir`, so their behavior is unchanged).
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

### Task 1: source-truth.md — spec as authoritative source + 3-way protocol

**Files:**
- Branch: create `ivgu/NOISSUE-impl-jira-docs-inputs` off `origin/main`.
- Modify: `references/source-truth.md`

**Interfaces — Produces:** the verification semantics that Task 2 (`doc-planner`) and Task 4 (Phase 5.8) reference: the `spec-markdown` source, the `spec_phrasing` field, and the 3-way discrepancy table/choices/record/bug-draft.

- [ ] **Step 1: Branch off main**

```bash
cd /workspace/ihudak-claude-plugins
git fetch origin -q && git checkout -b ivgu/NOISSUE-impl-jira-docs-inputs origin/main 2>&1 | tail -2
```

- [ ] **Step 2: Edit `references/source-truth.md`** (idiomatic prose, mirroring the file's existing style):
  - **§1/§2** — add that, **when a spec is provided**, the **spec markdown is the authoritative "intended"** source (Jira corroborates; code is "actual"). State the authoritative file set (VI spec + epic specs + `requirements.md` + `design.md`; `tasks.md` secondary; ignore `idea.md`/`prompt.md`/HTML).
  - **§4.2 (`doc-planner`)** — the claim's intended phrasing comes from the **spec** when present (falls back to Jira when absent); add a `spec-markdown` verification technique (read the spec tree); record `spec_phrasing` verbatim alongside `jira_phrasing`/`source_phrasing`. When no spec: `spec_phrasing: "(no spec)"`, behavior unchanged.
  - **§7 (discrepancy protocol)** — make it 3-way:
    - §7.1 table header → `| # | Claim | Jira | Spec | Code | Source location | Verdict |`
    - §7.2/§7.3 choices → "Document as intended (spec) (Recommended)" / "Document as actual (code)" / "Skip & report (drafts a bug)"; keep `Cancel` / `Other… (describe)`.
    - §7.4 record → `discrepancy_decisions[]` entries gain `spec_phrasing`; `decision` ∈ `document-as-spec | document-as-code | skip-and-report`.
    - §7.5 bug-draft (`…-implementation-gaps.md`) gains a **Spec phrasing** line.
    - Add a note that **spec-differs-from-Jira** is itself surfaced as a row (verdict `SPEC-VS-JIRA`), spec authoritative.
  - Bump the §6 example note to show the added Spec column (one line; keep PRODUCT-14902 example).

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for needle in "spec-markdown" "spec_phrasing" "document-as-spec" "Spec | Code" "SPEC-VS-JIRA"; do
  grep -q "$needle" references/source-truth.md && echo "OK: $needle" || echo "MISSING: $needle"
done
grep -c "no spec" references/source-truth.md   # >=1 (backward-compat phrasing)
```
Expected: all five `OK`; count ≥ 1.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/source-truth.md
git commit -m "feat(dev-workflows): source-truth — spec as authoritative source + 3-way discrepancy protocol

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: doc-planner — specs_dir input, spec-tree read, 3-way warnings

**Files:**
- Modify: `agents/doc-planner.md`

**Interfaces — Consumes:** the `source-truth.md` semantics from Task 1. **Produces:** a `doc-planner` that accepts `specs_dir`, reads the spec tree, and emits `verification_warnings[]` with `spec_phrasing` + `technique: spec-markdown`.

- [ ] **Step 1: Add the `specs_dir` input** to the input block (after the `code_repos:` line, ~line 19):

```yaml
specs_dir:              <absolute path to the VI's spec folder (PRODUCT-NNNN*), or null; the authoritative intended-behavior source>
```

- [ ] **Step 2: Add the spec-tree read + verification** to process step 9 (the source-truth step, ~line 87). Insert prose: when `specs_dir` is non-null, **read the spec tree selectively** — the VI spec (`PRODUCT-<key>*.md` or `specification.md` at root), `epics/epic-*.md`, and each `epics/<epic>/requirements.md` + `design.md` (authoritative intended); `tasks.md` only as a secondary "planned" signal; ignore `idea.md`/`prompt.md`/HTML. The intended phrasing of each user-visible claim comes from the **spec** (fall back to Jira when no spec covers it). Continue verifying intended-vs-**code** via the §3 techniques. When `specs_dir` is null/empty, behave as today (Jira-vs-code) and set `spec_phrasing: "(no spec)"`.

- [ ] **Step 3: Extend the warning schema** (~lines 122–129): add `spec_phrasing` after `jira_phrasing`, and add `spec-markdown` to the `technique` enum:

```yaml
    jira_phrasing:   <verbatim from the Jira/description source>
    spec_phrasing:   <verbatim from the spec markdown, or "(no spec)">
    source_phrasing: <verbatim from the code, or "(not verifiable)">
    source_location: <file:line checked, or null>
    technique:       <schema-json | datasource-class | constant | openapi | ui-source | test-fallback | menu-builder | spec-markdown | no-source-evidence>
    finding:         VERIFIED | CONTRADICTED | NOT_FOUND | AMBIGUOUS | SPEC-VS-JIRA
```
Add prose that `finding: SPEC-VS-JIRA` flags a spec-vs-Jira drift (spec authoritative).

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
python3 - <<'PY'
import re, yaml, pathlib
t = pathlib.Path("agents/doc-planner.md").read_text()
fm = yaml.safe_load(re.search(r"^---\n(.*?)\n---", t, re.S).group(1))
assert fm["name"] == "doc-planner", fm.get("name")
for n in ["specs_dir", "spec_phrasing", "spec-markdown", "requirements.md", "design.md", "(no spec)", "SPEC-VS-JIRA"]:
    assert n in t, f"missing {n}"
print("doc-planner OK")
PY
```
Expected: `doc-planner OK`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/doc-planner.md
git commit -m "feat(doc-planner): specs_dir input + spec-tree read + spec_phrasing/spec-markdown 3-way warnings

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: jira-reader — attachments[] image enumeration

**Files:**
- Modify: `agents/jira-reader.md`, `references/handoff/jira-reader.md`

**Interfaces — Produces:** `attachments[]` in the jira-reader handoff (image file paths), consumed by Task 5's image-candidate step.

- [ ] **Step 1: Edit `agents/jira-reader.md`:**
  - Refine the "Ignored by default" note (~line 37) and the hard rule (~line 115): jira-reader still does NOT read attachment **content** or comments, but it now **enumerates image files** (by extension `.png|.jpg|.jpeg|.gif|.svg|.webp`) under the VI's `attachments/` / `Attachments/` directories (case-insensitive) into a new `attachments[]` output field. Enumeration only — paths, not content — so it stays fast and never treats images as authoritative doc source.
  - Add to the `## Output` schema (~line 77+) a new field:

```yaml
attachments:            # image files found under the VI's attachments/ dirs (paths only, not read)
  - path:   <absolute path to the image file>
    item:   <the Jira key whose folder it was found under>
```
  Empty or no attachments dirs → `attachments: []` (not an error).

- [ ] **Step 2: Update `references/handoff/jira-reader.md`** to document the new `attachments[]` field consistently with the agent's output schema.

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -q "attachments:" agents/jira-reader.md && echo "agent attachments[] OK"
grep -qiE "enumerat" agents/jira-reader.md && echo "enumerate-not-read OK"
grep -q "attachments" references/handoff/jira-reader.md && echo "handoff OK"
python3 -c "import re,yaml,pathlib;t=pathlib.Path('agents/jira-reader.md').read_text();assert yaml.safe_load(re.search(r'^---\n(.*?)\n---',t,re.S).group(1))['name']=='jira-reader';print('frontmatter OK')"
```
Expected: all four OK.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/references/handoff/jira-reader.md
git commit -m "feat(jira-reader): enumerate image attachments into attachments[]

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: command — Phase 5.7 passes specs_dir + Phase 5.8 3-way

**Files:**
- Modify: `commands/impl/jira/docs.md` (Phase 5.7 invocation brief; Phase 5.8 discrepancy block)

**Interfaces — Consumes:** `specs_dir` resolved in Phase 0 (Increment 1); the Task 1/2 3-way semantics. **Produces:** a 3-way Phase 5.8.

- [ ] **Step 1: Phase 5.7** — add `specs_dir` to the `doc-planner` invocation brief (after the `code_repos:` line):

```
specs_dir:            [resolved <specs_dir> from Phase 0, or null]
```

- [ ] **Step 2: Phase 5.8** — make the discrepancy block 3-way (per `source-truth.md` §7 as updated in Task 1):
  - Table header → `| # | Claim | Jira phrasing | Spec phrasing | Source (code) phrasing | Source location | Verdict |`.
  - Trigger now includes `SPEC-VS-JIRA` alongside `CONTRADICTED`/`NOT_FOUND`/`AMBIGUOUS`.
  - Batch choices → "Decide per discrepancy (Recommended)", "Document ALL as intended (spec)", "Document ALL as actual (code)", "Skip ALL and report (drafts a bug report)", "Cancel", "Other… (describe)".
  - Per-discrepancy choices → "Document as intended (spec)", "Document as actual (code)", "Skip this claim and report it", "Cancel", "Other… (describe)".
  - `discrepancy_decisions[]` records gain `spec_phrasing`; `decision` ∈ `document-as-spec | document-as-code | skip-and-report`.

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
t=commands/impl/jira/docs.md
grep -q "specs_dir:" "$t" && echo "5.7 specs_dir OK"
grep -q "Spec phrasing" "$t" && echo "5.8 3-way table OK"
grep -q "Document ALL as intended (spec)" "$t" && echo "5.8 batch choices OK"
grep -q "document-as-spec" "$t" && echo "5.8 decisions OK"
python3 -c "import re,yaml,pathlib;t=pathlib.Path('$t').read_text();assert yaml.safe_load(re.search(r'^---\n(.*?)\n---',t,re.S).group(1))['name']=='impl:jira:docs';print('frontmatter OK')"
```
Expected: all five OK.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "feat(impl:jira:docs): pass specs_dir to planner + 3-way discrepancy (Phase 5.7/5.8)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: command — image-candidate step + interactive CDN handoff

**Files:**
- Modify: `commands/impl/jira/docs.md` (Phase 1 screenshots block; new image-candidate step; new interactive CDN step; Phase 6 image-write; Phase 9 list)

**Interfaces — Consumes:** `specs_dir` (Phase 0) + `attachments[]` (Task 3 jira-reader handoff) + `doc-planner` `image_policy`/`screenshots[]` placements.

- [ ] **Step 1: Image-candidate step** — add a dedicated **`## Phase 5.6 — Image candidates`** (after Phase 5.5 doc-location-finder, before Phase 5.7 doc-planner — by which point `specs_dir` (Phase 0), the `jira-reader` `attachments[]` (Phase 3), and repos (Phase 4) are all resolved). Simplify the **Phase 1** screenshots block to just (a) ask whether images are wanted and (b) resolve `<screenshot_staging_dir>` (unchanged); move the actual candidate-building to Phase 5.6. Phase 5.6 builds a **merged, deduped candidate list** from three sources:
  - recursive scan of `<specs_dir>` for image files (`.png|.jpg|.jpeg|.gif|.svg|.webp`) across root + `epics/` + `spec/`;
  - the `jira-reader` handoff `attachments[]` (image paths);
  - the existing manual "I'll provide screenshot paths" option.
  Present the deduped candidates with `choices` (recommended first: "Use all auto-discovered + add manual"; last item `"Other… (describe)"`). Selected paths populate the existing `screenshots[]` passed to `doc-planner` in Phase 5.7 — downstream placement machinery unchanged. If no images are wanted (Phase 1) → skip Phase 5.6.

- [ ] **Step 2: Interactive CDN handoff step** — add a new step after Phase 5.7 returns (e.g. `## Phase 6.2 — CDN image handoff`), running only when any target's `image_policy: cdn_upload_required` (or the user picked "stage for upload" under `ambiguous`):
  - List each image → its target page/anchor + proposed alt text + the planner's `upload_note`.
  - Ask: `choices: ["Upload now — I'll paste the CDN links (Recommended)", "Defer — stage with TODO placeholders + Phase 9 list", "Cancel", "Other… (describe)"]`.
  - **Upload now** → collect one CDN URL per image (free text, one per line / prompted per image); validate each looks like a URL; Phase 6 writes the **real CDN URLs** into the markdown image references.
  - **Defer** → exactly the existing behavior (stage under `<screenshot_staging_dir>`, insert `TODO-upload` placeholders, list in Phase 9).
  - Update the Phase 6 `cdn_upload_required` write-rule to branch on this decision (real URL vs TODO placeholder), and the Phase 9 "Screenshots to upload manually" note to say it is populated only for the **Defer** path.

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
t=commands/impl/jira/docs.md
grep -q "## Phase 5.6 — Image candidates" "$t" && echo "Phase 5.6 OK"
grep -q "CDN image handoff" "$t" && echo "CDN step OK"
grep -q "Upload now — I'll paste the CDN links" "$t" && echo "interactive choice OK"
grep -qE "recursive|scan.*specs_dir|specs_dir.*scan" "$t" && echo "image scan OK"
grep -q "attachments" "$t" && echo "jira attachments consumed OK"
grep -q "TODO-upload" "$t" && echo "async fallback preserved OK"
```
Expected: all five OK.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "feat(impl:jira:docs): image-candidate discovery + interactive CDN handoff (async fallback)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: register + release 1.11.0

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` (version 1.10.0 → 1.11.0; marketplace version is at `plugins[0].version`), `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/README.md` (refresh the `/impl:jira:docs` row to note spec-grounded 3-way verification + auto image discovery + interactive CDN).

- [ ] **Step 1: Bump version to 1.11.0** in `plugin.json` (top-level `version`) and `marketplace.json` (`plugins[0].version`); keep both valid JSON.

- [ ] **Step 2: CHANGELOG** (`## [1.11.0] — 2026-06-26`, house format `### Added`/`### Changed`, bold lead-ins):
  - **Added** — `jira-reader` now enumerates image attachments into `attachments[]`.
  - **Changed** — `/impl:jira:docs` now feeds the VI spec tree to `doc-planner` as the authoritative intended source (3-way `Jira|Spec|Code` discrepancy in Phase 5.8, new `spec-markdown` technique + `spec_phrasing`); auto-discovers candidate images (specs scan + Jira attachments + manual); and adds an interactive CDN handoff (paste links → real URLs) with the existing async fallback. `source-truth.md` updated for the spec-authoritative 3-way protocol.

- [ ] **Step 3: README** — refresh the `/impl:jira:docs` command-table row to mention spec-grounded 3-way verification, auto image discovery, and the interactive CDN handoff. (Do not add the AI-Containers narrative — Increment 3.)

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));b=json.load(open('.claude-plugin/marketplace.json'));assert a['version']=='1.11.0';assert b['plugins'][0]['version']=='1.11.0';print('1.11.0 OK')"
grep -q "## \[1.11.0\] — 2026-06-26" plugins/dev-workflows/CHANGELOG.md && echo "CHANGELOG OK"
```
Expected: `1.11.0 OK`; `CHANGELOG OK`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md
git status --short   # confirm only intended files
git commit -m "docs(dev-workflows): register Increment 2 (spec-grounded docs + images) + release 1.11.0

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## After all tasks

Use superpowers:finishing-a-development-branch on `ivgu/NOISSUE-impl-jira-docs-inputs`. Increment 3 (multi-space write safety, dev-server verify + pages table, planning gate, squash/push + PR draft, README AI-Containers doc, the README Vale-fallback-note restore, the "which docs command?" disambiguation, and the inline-profiling-branch handling) follows as its own spec→plan cycle.

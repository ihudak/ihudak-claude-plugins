---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-27
---

# SP2 Increment 3b — Render verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Phase 6.8 to `/impl:jira:docs` that proves the docs it just wrote build and render — auto build-check (gating), an opt-in best-effort sequential dev-server smoke-check that also verifies the 3a render-unchanged invariant, and an always-emitted "pages to visit" table.

**Architecture:** One new reference (`render-verification.md`) is the mechanics SSOT plus a new overridable `dev_servers.readiness_timeout_seconds` profile field; the command gains Phase 6.8 (between 6.7 style and 7 review) that cites the reference, threads its result into Phase 7's `doc-reviewer` invocation and a Phase 9 `### Render verification` section; a release bump ships it as v1.13.0.

**Tech Stack:** Markdown command/agent/reference files, YAML profile, JSON manifests. **No test framework** — verification is structural (`grep` anchors, `python3` YAML/JSON parse, phase-ordering + fence-parity checks). Those structural checks ARE the test cycle.

## Global Constraints

- Plugin repo `/workspace/ihudak-claude-plugins`; plugin under `plugins/dev-workflows/`. Plugin `main` is at `3c919f3`, v1.12.0.
- Work on a branch off `origin/main`: **`ivgu/NOISSUE-impl-jira-docs-renderverify`**. Never implement on `main`.
- **`marketplace.json` version is at `plugins[0].version`, NOT top-level.** `plugin.json` version is the top-level `"version"`.
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Stage only the files each task names with `git add <path>`. Never `git add -A`/`.`; never stage `.superpowers/`, `.docstack`, or unrelated files.
- Reference-path citation format in command prose: `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/render-verification.md` (matches existing `${CLAUDE_PLUGIN_ROOT}/references/...` citations).
- **Phase 6.8 is build + render only — it does NOT re-run the Phase 6.7 prose linter** (`docs-style-checker` already ran the repo's prose linter). For dynatrace-docs (no build command in the profile), the dev-server boot is the build proof.
- **The `.docstack` shim is a local, gitignored, reversible dev workaround — Phase 6.8 may CHECK a prerequisite but must NEVER auto-apply it.**
- The dev-server smoke-check is **best-effort**: any boot/prerequisite/readiness failure falls back to the always-emitted "pages to visit" table and **never blocks** the run.
- `profile.dev_servers.concurrent: false` → servers are booted **sequentially**, one space at a time, each stopped before the next boots.
- The cross-space **invariant** check: a page's delta marker must be PRESENT in its `write_strategy.target_space` render and ABSENT in the protected space's render. A marker leaking into the protected render is **Critical**.
- `both` is never a space value. Cite only real profile keys.
- Do NOT touch the zero-external-API invariant (no push/PR/squash) — that's 3c.
- **Out of scope:** 3c (finish/handoff), 3d (README AI-Containers, committed Vale-note restore, "which docs command?", "All five" count). Do not implement them here.
- Profile keys are fixed by `references/dynatrace-docs/docs-profile.default.yml`: `commands.build` (optional), `dev_servers.{concurrent,readiness_timeout_seconds,servers[].{space,command,port,base_path}}`, `prerequisites`, `spaces[].{content_root,base_path}`.

---

## File Structure

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/references/dynatrace-docs/render-verification.md` (NEW) | SSOT for the render-verification mechanics: build-vs-boot, sequential boot + readiness poll + stop, route derivation, delta-marker extraction + the invariant check, prerequisites best-effort/no-auto-fix, graceful fallback + the pages table. Cited by Phase 6.8. | 1 |
| `plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md` + `…/docs-profile.default.yml` | New overridable `dev_servers.readiness_timeout_seconds` field (default 120). | 1 |
| `plugins/dev-workflows/commands/impl/jira/docs.md` | New **Phase 6.8** (between 6.7 and 7); Phase 7 `doc-reviewer` invocation gains a `render_verification` input; Phase 9 report gains a `### Render verification` section. | 2 |
| `plugin.json`, `marketplace.json`, `CHANGELOG.md`, `README.md` | Release bump to v1.13.0. | 3 |

---

## Task 1: `render-verification.md` reference + `readiness_timeout_seconds` profile field

**Files:**
- Create: `plugins/dev-workflows/references/dynatrace-docs/render-verification.md`
- Modify: `plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md`
- Modify: `plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml`

**Interfaces:**
- Consumes: existing profile keys (already in the default profile).
- Produces: the reference with section anchors Task 2 cites — `## 1. Build vs boot`, `## 2. Sequential dev-server smoke-check`, `## 3. Route derivation`, `## 4. Delta-marker extraction and the invariant check`, `## 5. Prerequisites (best-effort, never auto-applied)`, `## 6. Graceful fallback and the pages-to-visit table`. And the new profile field `dev_servers.readiness_timeout_seconds` (default 120) that Task 2's Phase 6.8 reads.

- [ ] **Step 1: Write the reference file**

Create `plugins/dev-workflows/references/dynatrace-docs/render-verification.md` with exactly this content:

````markdown
# Render verification (dynatrace-docs)

How `/impl:jira:docs` Phase 6.8 proves the documentation it just wrote builds
and renders — and that cross-space pages honor the 3a render-unchanged invariant
(the protected space's render is unchanged). See [[multi-space-writing]] for the
write strategies this verifies.

This is the single source of truth for the mechanics; Phase 6.8 cites it and
stays lean. Read every path, command, and port from the resolved `profile` — do
not hard-code dynatrace-docs specifics.

"Affected pages" = every file written or modified in Phase 6.

## 1. Build vs boot

Run `profile.commands.build` only if the profile defines one. Phase 6.8 does NOT
re-run the prose linter — that is Phase 6.7's `docs-style-checker`. When the
profile defines no build command (the dynatrace-docs case: only
`commands.lint` + the `*:start` dev servers), the **dev-server boot is the build
proof** — a server that boots and serves HTTP 200s proves the content compiled.

## 2. Sequential dev-server smoke-check

`profile.dev_servers.concurrent: false` means one space at a time. For each space
in `target_spaces`, in order:

1. Verify prerequisites (§5) — best-effort, never applied.
2. Boot `profile.dev_servers.servers[<space>].command` in the background; record
   the process id.
3. Readiness poll: GET `http://localhost:<port><base_path>/` until HTTP 200 or
   `profile.dev_servers.readiness_timeout_seconds` seconds elapse (fall back to
   **120** when the field is absent).
4. For each affected page rendered in this space, GET its derived URL (§3) and
   assert HTTP 200.
5. For cross-space pages, run the invariant check (§4).
6. Stop the server (kill the recorded process id) before booting the next space.

Never run two servers at once. Always stop the current one before the next.

## 3. Route derivation

The page URL is `http://localhost:<port><base_path>/<route>`, where `<port>` and
`<base_path>` come from `profile.dev_servers.servers[<space>]` and `<route>` is
the page path relative to that space's `content_root` with a trailing `index.md`
or `.md` removed. Example: `dynatrace/_content/setup/foo/index.md` in the `saas`
space (`base_path: /docs`, port 4000) → `http://localhost:4000/docs/setup/foo`.

This is best-effort. A wrong route that 404s in the smoke-check simply downgrades
that page to the manual table — it is not a render defect by itself.

## 4. Delta-marker extraction and the invariant check

A **delta marker** is a short, distinctive literal string taken from the
per-space content a cross-space write produced — derived here at verification
time, not emitted by Phase 6:

- `conditional` page → read the written file and take a distinctive literal line
  from inside the `{{#if project='<target_space>'}}…{{/if}}` block.
- `override-copy` page → take a distinctive literal from the override copy's
  content that is absent in the home-space original.

The invariant check, per cross-space page:
- the marker must be **PRESENT** in the render of the strategy's `target_space`;
- the marker must be **ABSENT** in the render of the protected space.

A marker that appears in the **protected** space's render — or is missing from
the **target** space's render — is a **Critical** finding: the 3a protection
failed.

## 5. Prerequisites (best-effort, never auto-applied)

`profile.prerequisites` lists what a dev server may need before `*:start` boots
(e.g. a working `.docstack` toolchain / an axios shim). Phase 6.8 **checks** a
prerequisite but NEVER applies it — the `.docstack` workaround is a local,
gitignored, reversible dev-environment hack and is out of scope for an automated
run. If a prerequisite is unmet, record "smoke-check skipped for `<space>`:
prerequisite `<x>` unmet" and use the manual table for that space.

## 6. Graceful fallback and the pages-to-visit table

The smoke-check is best-effort. Any prerequisite-unmet, boot-failure, or
readiness-timeout outcome is recorded with its reason and falls back to the
manual table for that space — it never blocks the run. (A 404/500 on an affected
page, or an invariant violation, ARE findings — they are surfaced, not silently
dropped.)

The **pages-to-visit table** is always emitted, one row per affected page: its
URL in each space it renders in (§3), its `write_strategy`, and what to verify
(cross-space rows: "confirm `<target_space>` shows the change and the
`<protected_space>` render is unchanged"). When the smoke-check ran, annotate
each row ✅ 200 / ⚠️ skipped (reason) / ❌ failed.
````

- [ ] **Step 2: Add the `readiness_timeout_seconds` field to the schema example**

In `plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md`, the `dev_servers` example currently starts:
```yaml
dev_servers:
  concurrent: false                   # cannot run two spaces at once
  servers:
```
Replace those three lines with:
```yaml
dev_servers:
  concurrent: false                   # cannot run two spaces at once
  readiness_timeout_seconds: 120      # optional; seconds to poll a booted server for readiness (default 120)
  servers:
```

- [ ] **Step 3: Add the field rule to the schema's Field rules**

In the same file, the `## Field rules` list contains the line:
```markdown
- `dev_servers.concurrent: false` means the consumer must start servers sequentially.
```
Immediately after it, add:
```markdown
- `dev_servers.readiness_timeout_seconds` is optional (default 120) — how many seconds Phase 6.8 polls a booted server for readiness before falling back to the manual table.
```

- [ ] **Step 4: Add the field to the built-in default profile**

In `plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml`, the `dev_servers` block currently starts:
```yaml
dev_servers:
  concurrent: false
  servers:
```
Replace those three lines with:
```yaml
dev_servers:
  concurrent: false
  readiness_timeout_seconds: 120
  servers:
```

- [ ] **Step 5: Verify the reference anchors, the profile field, and YAML validity**

Run:
```bash
cd /workspace/ihudak-claude-plugins && \
echo "=== reference anchors ===" && \
for h in \
  "^# Render verification" \
  "^## 1. Build vs boot" \
  "^## 2. Sequential dev-server smoke-check" \
  "^## 3. Route derivation" \
  "^## 4. Delta-marker extraction and the invariant check" \
  "^## 5. Prerequisites" \
  "^## 6. Graceful fallback" ; do \
  grep -qE "$h" plugins/dev-workflows/references/dynatrace-docs/render-verification.md && echo "OK  $h" || echo "MISS $h" ; \
done && \
echo "=== profile field present (schema example + field rule + default) ===" && \
grep -q "readiness_timeout_seconds: 120" plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md && echo "OK  schema example" || echo "MISS schema example" && \
grep -q "dev_servers.readiness_timeout_seconds\` is optional" plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md && echo "OK  schema field rule" || echo "MISS schema field rule" && \
grep -q "readiness_timeout_seconds: 120" plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml && echo "OK  default profile" || echo "MISS default profile"
```
Expected: seven anchor `OK` lines, then three `OK` lines (schema example, schema field rule, default profile). No `MISS`.

- [ ] **Step 6: Verify the default profile still parses as YAML**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import sys
try:
    import yaml
    d = yaml.safe_load(open("plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml"))
    t = d["dev_servers"]["readiness_timeout_seconds"]
    assert t == 120, f"expected 120, got {t}"
    print("OK  default profile parses; dev_servers.readiness_timeout_seconds == 120")
except ImportError:
    print("SKIP pyyaml not installed — visually confirm the YAML indents under dev_servers")
except Exception as e:
    print("FAIL", e); sys.exit(1)
PY
```
Expected: `OK` (or `SKIP` if pyyaml is unavailable), no `FAIL`.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/dynatrace-docs/render-verification.md \
        plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md \
        plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml
git commit -m "$(cat <<'EOF'
NOISSUE Add render-verification reference + dev_servers.readiness_timeout_seconds (default 120)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `/impl:jira:docs` — Phase 6.8 + Phase 7 input + Phase 9 section

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md`

**Interfaces:**
- Consumes: `render-verification.md` (Task 1, cited by path); the `dev_servers.readiness_timeout_seconds` field (Task 1); `target_spaces` and the approved `write_strategies[]` from earlier phases; `profile.commands.build`/`dev_servers`/`prerequisites`/`spaces[]`.
- Produces: the `render_verification` summary line consumed by the Phase 7 `doc-reviewer` invocation and the `### Render verification` Phase 9 report section. No new downstream agent interface.

- [ ] **Step 1: Insert Phase 6.8 between Phase 6.7 and Phase 7**

In `plugins/dev-workflows/commands/impl/jira/docs.md`, find the heading line `## Phase 7 — Doc review gate` (it is preceded by the `---` that closes Phase 6.7). Replace that single heading line:
```markdown
## Phase 7 — Doc review gate
```
with this block (the new Phase 6.8, a separator, then the original Phase 7 heading):
````markdown
## Phase 6.8 — Render verification

Run this phase after Phase 6.7 **only** when Phase 6 wrote files into a buildable docs repo (write context `docs_repo`, or `non_docs_repo` confirmed at Phase 0). Skip for `obsidian` / `plain_dir` (nothing was written into a repo that builds). Mechanics: `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/render-verification.md`. "Affected pages" = every file written or modified in Phase 6.

### Step 1 — Build check (gating)

Run `profile.commands.build` if the profile defines one. Do NOT re-run the Phase 6.7 prose linter. Classify any failure:
- **Content failure** (Handlebars won't compile, unresolved snippet include, broken postid/internal link, malformed conditional) → invoke `doc-fixer` (Severities: BLOCKER and MAJOR), then re-run the build once. If failures remain:
  ```
  choices: ["Proceed to smoke-check anyway", "Show remaining and fix manually", "Cancel"]
  ```
- **Environmental failure** (the build tool will not run — missing toolchain, `command not found`, missing `.docstack` shim) → surface the reason; no `doc-fixer` loop:
  ```
  choices: ["Proceed (build unverified)", "I'll fix locally — retry the build", "Cancel"]
  ```

When the profile defines **no** build command (the dynatrace-docs case), record "no build command in profile; build proof deferred to the dev-server boot (Step 2)" and proceed.

### Step 2 — Dev-server smoke-check (opt-in, best-effort)

Offer it:
```
choices: ["Run smoke-check (Recommended)", "Skip — use the manual table only", "Cancel"]
```

When run, for each space in `target_spaces`, **sequentially** (`profile.dev_servers.concurrent: false` forbids overlap) — full mechanics in `render-verification.md`:
1. **Prerequisites (best-effort, never auto-applied).** Verify `profile.prerequisites`. The `.docstack` shim is a local, gitignored dev-environment workaround — check it, NEVER apply it. Unmet → record "smoke-check skipped for `<space>`: prerequisite `<x>` unmet" and use the manual table for that space.
2. **Boot** `profile.dev_servers.servers[<space>].command` in the background; record the process id.
3. **Readiness poll** — GET `http://localhost:<port><base_path>/` until HTTP 200 or `profile.dev_servers.readiness_timeout_seconds` seconds (fall back to **120** when absent). On timeout → stop the process, record "smoke-check skipped for `<space>`: not ready", use the manual table for that space.
4. For each affected page rendered in `<space>`, GET its derived URL (Step 3 route rule) → assert **HTTP 200**.
5. For each **cross-space** page (its `write_strategy.strategy` is `conditional` or `override-copy`), grep the rendered HTML for the page's **delta marker** (`render-verification.md` §4): PRESENT when `<space>` is the strategy's `target_space`, ABSENT when `<space>` is the protected space.
6. **Stop the server** (kill the recorded process id) before the next space.

Outcomes:
- **404/500** on an affected page = render defect → treat as a Step 1 content failure (offer `doc-fixer` / surface).
- **Invariant violation** (a cross-space delta marker present in the protected space's render, or missing from the target space's render) = **Critical** (the 3a protection failed):
  ```
  choices: ["Fix manually then retry", "Defer to a follow-up (record in Phase 9)", "Cancel"]
  ```
- Any **boot / prerequisite / readiness** problem is best-effort → never blocks; that space falls back to the manual table.

### Step 3 — "Pages to visit" table (always)

Emit a table, one row per affected page — URL per space the page renders in (`http://localhost:<port><base_path>/<route>`; blank for a space the page does not render in), the page's `write_strategy.strategy`, and what to verify (cross-space: "confirm `<target_space>` shows the change and the `<protected_space>` render is unchanged"; `plain`: "confirm the page renders as intended"). When the smoke-check ran, annotate each cell ✅ 200 / ⚠️ skipped (reason) / ❌ failed.

**Route derivation (best-effort):** `<route>` = the page path relative to its space's `content_root` with a trailing `index.md`/`.md` removed. Approximate — a wrong route that 404s in Step 2 simply downgrades that page to the manual table.

Carry the table and the Step 1/Step 2 outcomes into the Phase 9 `### Render verification` section, and pass a one-paragraph `render_verification` summary to Phase 7.

---

## Phase 7 — Doc review gate
````

- [ ] **Step 2: Add the `render_verification` input to the Phase 7 `doc-reviewer` invocation**

In the Phase 7 invocation block, find:
```
  > style-check report: [the violations output from Phase 6.7 — from docs-style-checker or dt-style-checker (fallback), or 'status: NOT_CONFIGURED' if neither ran]
  > code_repos:         [the Phase-4 resolved {slug, path} map; [] if none resolved]"
```
Replace with:
```
  > style-check report: [the violations output from Phase 6.7 — from docs-style-checker or dt-style-checker (fallback), or 'status: NOT_CONFIGURED' if neither ran]
  > render_verification: [the Phase 6.8 summary — build result; smoke-check per space (passed / skipped with reason); cross-space invariant check result]
  > code_repos:         [the Phase-4 resolved {slug, path} map; [] if none resolved]"
```

- [ ] **Step 3: Add the `### Render verification` section to the Phase 9 report**

In the Phase 9 report template, find this block:
```
### Branch
[branch name created in Phase 6.5, e.g. docs/<jira-key>-<slug>] OR "N/A — no branch created (context: obsidian / plain_dir / user declined branching)"

### Doc review verdict
```
Replace with:
```
### Branch
[branch name created in Phase 6.5, e.g. docs/<jira-key>-<slug>] OR "N/A — no branch created (context: obsidian / plain_dir / user declined branching)"

### Render verification
- Build: [ran — pass/fail | no build command — boot is the proof | unverified (reason)]
- Smoke-check: [per space — passed (N pages, HTTP 200) | skipped (reason)] OR "not run (user skipped)"
- Cross-space invariant: [verified (markers present in target, absent in protected) | not checked | VIOLATION — see deferred items]
- Pages to visit: [the Phase 6.8 Step 3 table]

### Doc review verdict
```

- [ ] **Step 4: Verify the three edits, placement, ordering, and fence parity**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import sys
t = open("plugins/dev-workflows/commands/impl/jira/docs.md").read()
checks = {
  "Phase 6.8 heading":          "## Phase 6.8 — Render verification" in t,
  "6.8 cites reference":        "references/dynatrace-docs/render-verification.md" in t,
  "6.8 build gating":           "Build check (gating)" in t,
  "6.8 smoke-check opt-in":     "Dev-server smoke-check (opt-in, best-effort)" in t,
  "6.8 sequential":             "profile.dev_servers.concurrent: false" in t,
  "6.8 readiness field":        "profile.dev_servers.readiness_timeout_seconds" in t,
  "6.8 invariant Critical":     "= **Critical** (the 3a protection failed)" in t,
  "6.8 pages table":            'Pages to visit" table' in t,
  "6.8 docstack no-auto-apply": "NEVER apply it" in t,
  "Phase 7 render_verification":"> render_verification: [the Phase 6.8 summary" in t,
  "Phase 9 section":            "### Render verification" in t,
}
miss=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(("OK  " if v else "MISS")+" "+k)
i67,i68,i7,i9 = t.find("## Phase 6.7"), t.find("## Phase 6.8"), t.find("## Phase 7 — Doc review"), t.find("## Phase 9")
order_ok = -1 < i67 < i68 < i7 < i9
print(("OK  " if order_ok else "MISS")+f" ordering 6.7<6.8<7<9 {(i67,i68,i7,i9)}")
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
phases=["## Phase 0","## Phase 4.5","## Phase 5.7","## Phase 5.8","## Phase 5.9","## Phase 6 — Write","## Phase 6.2","## Phase 6.5","## Phase 6.7","## Phase 6.8","## Phase 7 — Doc review","## Phase 8","## Phase 9"]
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
NOISSUE impl:jira:docs: add Phase 6.8 render verification (build + best-effort smoke-check + pages table)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Release v1.13.0 (manifests + CHANGELOG + README)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `plugins/dev-workflows/README.md`

**Interfaces:**
- Consumes: the merged behavior from Tasks 1–2.
- Produces: a released v1.13.0.

- [ ] **Step 1: Bump `plugin.json` (top-level version)**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, change the top-level `"version"` from `"1.12.0"` to `"1.13.0"`.

- [ ] **Step 2: Bump `marketplace.json` (plugins[0].version — NOT top-level)**

In `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`, change the dev-workflows entry's version under `plugins[0].version` from `1.12.0` to `1.13.0`. Verify you edited `plugins[0].version`, not any top-level field.

- [ ] **Step 3: Add the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, insert a new section immediately above `## [1.12.0] — 2026-06-27`:
```markdown
## [1.13.0] — 2026-06-27

### Added
- **`references/dynatrace-docs/render-verification.md`.** Single source of truth for `/impl:jira:docs` render verification: build-vs-boot proof, sequential dev-server boot + readiness poll + stop, route derivation, delta-marker extraction + the cross-space invariant check, prerequisites best-effort/no-auto-apply, and graceful fallback to the pages-to-visit table.
- **`dev_servers.readiness_timeout_seconds` profile field (default 120).** Overridable per-repo; how long Phase 6.8 polls a booted dev server for readiness before falling back to the manual table.

### Changed
- **`/impl:jira:docs` Phase 6.8 — render verification (Increment 3b).** New phase after the style check: runs the profile's build command (gating, with the content→`doc-fixer` / environmental→ask split); offers an opt-in best-effort sequential dev-server smoke-check that asserts HTTP 200 per affected page and verifies the 3a invariant on cross-space pages (delta marker present in the target space's render, absent in the protected space's); always emits a "pages to visit" table. Results thread into the Phase 7 `doc-reviewer` invocation and a new Phase 9 `### Render verification` section. The `.docstack` shim is checked but never auto-applied.
```

- [ ] **Step 4: Add a README note**

In `plugins/dev-workflows/README.md`, find the line:
```markdown
- `references/dynatrace-docs/multi-space-writing.md` — how `/impl:jira:docs` writes across the SaaS and Managed spaces while protecting the other space's render (conditional vs override-copy, docstack `ignore`, shared-registries lock-step, token correctness)
```
Immediately **below** that line, add:
```markdown
- `references/dynatrace-docs/render-verification.md` — how `/impl:jira:docs` Phase 6.8 verifies the written docs build and render (build-vs-boot, sequential dev-server smoke-check, the cross-space render-unchanged invariant, pages-to-visit table)
```

- [ ] **Step 5: Verify the manifests parse and carry 1.13.0, and the docs mention the feature**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import json,sys
pj=json.load(open("plugins/dev-workflows/.claude-plugin/plugin.json"))
mk=json.load(open(".claude-plugin/marketplace.json"))
ok_pj = pj.get("version")=="1.13.0"
mkv = mk["plugins"][0].get("version")
ok_mk = mkv=="1.13.0"
print(("OK  " if ok_pj else "MISS")+f" plugin.json top-level version = {pj.get('version')}")
print(("OK  " if ok_mk else "MISS")+f" marketplace.json plugins[0].version = {mkv}")
cl=open("plugins/dev-workflows/CHANGELOG.md").read()
ok_cl = "## [1.13.0] — 2026-06-27" in cl and "render-verification.md" in cl
print(("OK  " if ok_cl else "MISS")+" CHANGELOG [1.13.0] entry")
rm=open("plugins/dev-workflows/README.md").read()
ok_rm = "render-verification.md" in rm
print(("OK  " if ok_rm else "MISS")+" README mentions render-verification.md")
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
NOISSUE Release dev-workflows v1.13.0 — render verification (Increment 3b)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Spec coverage** (against `spec/2026-06-27-sp2-increment3b-render-verification-design.md`):
- Placement (new Phase 6.8 between 6.7 and 7) → Task 2 Step 1. ✅
- Step 1 build check + content/environmental gating split → Task 2 Step 1. ✅
- Step 2 opt-in best-effort sequential smoke-check (prereqs no-auto-apply, boot, readiness via the new field, curl 200, invariant, stop) → Task 2 Step 1 + reference §2/§4/§5. ✅
- Step 3 always-emitted pages-to-visit table + route derivation → Task 2 Step 1 + reference §3/§6. ✅
- 6.7-vs-6.8 no-double-lint boundary → Global Constraints + Task 2 Step 1 + reference §1. ✅
- Delta marker derived at 6.8 time → reference §4 (Task 1), cited by Task 2. ✅
- Results flow (Phase 7 input, Phase 9 section) → Task 2 Steps 2–3. ✅
- New `render-verification.md` reference → Task 1. ✅
- `readiness_timeout_seconds` profile field (default 120; schema + default) → Task 1 Steps 2–4. ✅
- Release v1.13.0 → Task 3. ✅
- `.docstack` checked-never-applied → Global Constraints + Task 2 Step 1 + reference §5. ✅
- Out-of-scope 3c/3d → excluded per Global Constraints. ✅

**2. Placeholder scan:** No "TBD"/"TODO"/"fill in" in plan steps. The `<!-- TODO -->` / `[absolute path]` strings are pre-existing Phase 9 template content, not plan placeholders. ✅

**3. Type/name consistency:** Field name `readiness_timeout_seconds` identical in the reference (Task 1 Step 1), schema (Step 2/3), default profile (Step 4), and command (Task 2). The reference section anchors cited by Task 2's verification (`render-verification.md` §2/§4) match the headings created in Task 1. The `render_verification` Phase 7 input name and the `### Render verification` Phase 9 heading are consistent across Task 2's steps. `write_strategy.strategy` / `target_space` reused exactly as established in 3a. Profile keys (`commands.build`, `dev_servers.*`, `prerequisites`, `spaces[].{content_root,base_path}`) match the default profile. ✅

**Model guidance for execution:** Task 1 — cheapest tier (full content supplied, transcription + small YAML/schema edits). Task 2 — implement on a standard model (transcription of the supplied blocks), **review on the most capable model** (it carries the gating + best-effort fallback + the cross-space invariant prose — the core of 3b). Task 3 — cheapest tier; reviewer confirms `marketplace.json` was edited at `plugins[0].version`. Final whole-branch review — most capable model.

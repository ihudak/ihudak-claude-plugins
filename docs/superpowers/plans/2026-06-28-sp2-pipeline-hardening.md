---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# SP2 Pipeline hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix five cross-phase seams in the `/impl:jira:docs` pipeline found by the comprehensive review + spec review — Phase 6/6.5 ordering (I#1), `docs_repo_path` vs cwd (I#2), `profile.md` branching off the base (I#4), inline-profiling single-handoff (I#5), and the stranded-profile guard (I#6).

**Architecture:** Documentation/command-prose edits to two command files (`commands/impl/jira/docs.md`, `commands/impl/docs/profile.md`); no new feature. A patch release ships it as v1.14.2.

**Tech Stack:** Markdown command files, JSON manifests, local git. **No test framework** — verification is structural (`grep` for new/old strings, phase-ordering + fence parity, `python3` JSON parse). Those checks ARE the test cycle.

## Global Constraints

- Plugin repo `/workspace/ihudak-claude-plugins`; plugin under `plugins/dev-workflows/`. Plugin `main` is at `af343a4`, v1.14.1.
- Work on a branch off `origin/main`: **`ivgu/NOISSUE-impl-jira-docs-hardening`**. Never implement on `main`.
- **`marketplace.json` version is at `plugins[0].version`, NOT top-level.** `plugin.json` version is the top-level `"version"`. Patch bump to **v1.14.2**.
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Stage only the files each task names with `git add <path>`. Never `git add -A`/`.`; never stage `.superpowers/`, `.docstack`, or unrelated files.
- **No behavior change beyond I#4** (which makes a documented-but-false assumption true). Zero-external-API, multi-space render-unchanged, and opt-in commit/push are untouched.
- **Out of scope:** I#3 (`§15` escalation) + the monotonic Phase renumber → deferred to the namespace refactor. The line-138 readiness display ("Resolved cwd absolute path") stays as-is (informational).
- The **`--inline` contract** (I#5) spans both files: `docs.md` Phase 0 case (c) passes `docs_repo_path --inline`; `profile.md` detects `--inline` and switches to inline mode. Keep the token spelled exactly `--inline`.

---

## File Structure

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/commands/impl/jira/docs.md` | I#1 (Phase 6 ordering note), I#2 (cwd→`docs_repo_path`), I#5 (Phase 0 case (c) `--inline` signal), I#6 (Phase 0 in-repo-profile-not-on-base guard). | 1 |
| `plugins/dev-workflows/commands/impl/docs/profile.md` | I#4 (branch off base), I#5 (inline mode: skip naming prompt + standalone handoff). | 2 |
| `plugin.json`, `marketplace.json`, `CHANGELOG.md` | Patch release v1.14.2. | 3 |

---

## Task 1: `docs.md` — I#1, I#2, I#5 signal, I#6 guard

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/jira/docs.md`

**Interfaces:**
- Consumes: the `--inline` token consumed by `profile.md` (Task 2).
- Produces: the `--inline` signal (Phase 0 case c) and the in-repo-profile-not-on-base guard. No new agent interface.

- [ ] **Step 1: I#1 — Phase 6 ordering note**

Replace this exact block (the Phase 6 heading + first paragraph):
```
## Phase 6 — Write documentation

The main command writes the markdown following the `doc-planner` checklist. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5.7 already loaded.
```
with:
```
## Phase 6 — Write documentation

**Execution order with Phase 6.5 (branch setup).** When branching applies — write context `docs_repo` (or confirmed `non_docs_repo`) **and** the user opted into branching at plan approval — **Phase 6.5 runs *before* this phase**: it creates (or, for an inline-profiling run, renames) the branch off the base, and this phase then writes and commits onto that branch. Follow this execution order, not the numeric phase order (the `6.2`/`6`/`6.5`/`6.7`/`6.8` cluster is pending a monotonic renumber). For `obsidian`/`plain_dir` or no-branch runs, no branch is created and this phase writes in place without committing.

The main command writes the markdown following the `doc-planner` checklist. The writer is NOT a separate subagent — it's the orchestrating command with full context from Phases 3–5.7 already loaded.
```

- [ ] **Step 2: I#2 — `repo_root` agent briefs (three distinct edits)**

Replace `  > repo_root:       [cwd's git root, resolved in Phase 0]` with `  > repo_root:       [the resolved docs_repo_path (Phase 0)]`.

Replace `  > repo_root:            [cwd's git root]` with `  > repo_root:            [the resolved docs_repo_path (Phase 0)]`.

Replace `  > repo_root: [cwd's git root]` with `  > repo_root: [the resolved docs_repo_path (Phase 0)]`.

- [ ] **Step 3: I#2 — `Project root` agent briefs (replace_all + the Phase 8 one)**

Replace **all occurrences** of `    > Project root: [cwd's git root]` with `    > Project root: [the resolved docs_repo_path (Phase 0)]` (this matches the two `doc-reviewer` briefs; use replace-all).

Replace `> - Project root: [cwd's git root]"` with `> - Project root: [the resolved docs_repo_path (Phase 0)]"` (the Phase 8 Agent 4 brief).

- [ ] **Step 4: I#2 — output-filename phrasing + Phase 8 git diff**

Replace `- **Output filename / sub-path under cwd** (default: `<KEY>-<slug>.md`; the `doc-location-finder` in Phase 5.5 may override this per target).` with `- **Output filename / sub-path under the resolved `docs_repo_path`** (Phase 0) (default: `<KEY>-<slug>.md`; the `doc-location-finder` in Phase 5.5 may override this per target).`

Replace `- Output filename / path under cwd (from Phase 1)` with `- Output filename / path under the resolved `docs_repo_path` (from Phase 1)`.

Replace `a. Run `git diff --stat` against the base branch (if branching happened at Phase 6.5) or against HEAD (if no branching) and capture the list of changed files.` with `a. Run `git -C <docs_repo_path> diff --stat` against the base branch (if branching happened at Phase 6.5) or against HEAD (if no branching) and capture the list of changed files.`

- [ ] **Step 5: I#2 — invariant reword**

Replace `- NEVER write outside cwd unless the user provides an explicit absolute path at Phase 5.5` with:
```
- NEVER write product documentation outside the resolved `docs_repo_path` (Phase 0); the only other writes are to the ticket's vault project folder under `$VAULT_PATH` (the `<JIRA_KEY>-implementation-gaps.md` bug-report draft, the `<JIRA_KEY>-pr-draft.md`, and screenshot staging) — never anywhere else.
```

- [ ] **Step 6: I#5 — Phase 0 case (c) passes `--inline`**

In Phase 0 step 5 case (c), replace `invoke the `/impl:docs:profile` flow against `docs_repo_path` (Skill tool, `skill: "dev-workflows:impl:docs:profile"`, with `docs_repo_path` as its argument) and wait for it to write` with `invoke the `/impl:docs:profile` flow against `docs_repo_path` (Skill tool, `skill: "dev-workflows:impl:docs:profile"`, with `docs_repo_path --inline` as its arguments — the `--inline` token tells profiling to skip its branch-naming prompt and standalone PR-draft handoff, since this command owns the single branch + PR draft) and wait for it to write`.

- [ ] **Step 7: I#6 — Phase 0 in-repo-profile-not-on-base guard**

In Phase 0 step 5, after the line `   Hold the loaded profile for later phases.`, insert this new paragraph:
```
   **In-repo-profile-not-on-base guard.** When `profile_source: in-repo`, confirm the profile is committed on the base branch before relying on a docs branch cut from it. Resolve the base (`git -C <docs_repo_path> symbolic-ref --short refs/remotes/origin/HEAD`; fall back to `main`, then `master`) and run `git -C <docs_repo_path> cat-file -e <base>:.dev-workflows/docs-profile.yml`:
   - **exit 0 (present on base)** → proceed (the common case — the profile was merged earlier).
   - **non-zero (absent on base)** → the profile is only in the working tree / on an unmerged branch, so the docs branch Phase 6.5 cuts from `<base>` will not include it. Warn and ask:
     ```
     choices: ["Proceed — the run uses the in-memory profile; I'll merge the profile PR separately", "Cancel — merge the profile PR first, then re-run", "Other… (describe)"]
     ```
   Skip this check for `profile_source: built-in` (no profile file) and `generated` (the inline profiling branch is adopted by Phase 6.5, so the profile rides the single docs branch — a base check would false-fire).
```

- [ ] **Step 8: Verify all docs.md edits**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import sys
t = open("plugins/dev-workflows/commands/impl/jira/docs.md").read()
checks = {
  "I#1 ordering note":        "**Execution order with Phase 6.5 (branch setup).**" in t,
  "I#2 no cwd's-git-root left":"cwd's git root" not in t,
  "I#2 repo_root docs_repo_path": t.count("repo_root:") >= 3 and "[the resolved docs_repo_path (Phase 0)]" in t,
  "I#2 no 'under cwd' left":   "under cwd" not in t,
  "I#2 git diff -C":          "git -C <docs_repo_path> diff --stat" in t,
  "I#2 invariant reworded":   "NEVER write product documentation outside the resolved `docs_repo_path`" in t and "NEVER write outside cwd unless" not in t,
  "I#5 case-c --inline":      "`docs_repo_path --inline` as its arguments" in t,
  "I#6 guard":                "In-repo-profile-not-on-base guard" in t and "cat-file -e <base>:.dev-workflows/docs-profile.yml" in t,
}
miss=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(("OK  " if v else "MISS")+" "+k)
# ordering + fence parity unaffected
i58,i6,i65,i7 = t.find("## Phase 5.8"), t.find("## Phase 6 — Write"), t.find("## Phase 6.5"), t.find("## Phase 7 — Doc review")
order_ok = -1 < i58 < i6 < i65 < i7
print(("OK  " if order_ok else "MISS")+" phase headings present/ordered")
fences=t.count("\n```"); print(("OK  " if fences%2==0 else "MISS")+f" fence parity ({fences})")
# line-138 readiness left as-is
print(("OK  " if "- Resolved cwd absolute path" in t else "MISS")+" line-138 readiness untouched")
sys.exit(0 if (not miss and order_ok and fences%2==0) else 1)
PY
```
Expected: every check `OK`, exit 0. (Note: the `repo_root:` count ≥ 3 confirms the three repo_root briefs remain; "cwd's git root" count is 0.)

- [ ] **Step 9: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "$(cat <<'EOF'
NOISSUE impl:jira:docs hardening: Phase 6/6.5 ordering note, docs_repo_path (not cwd) in agent briefs, --inline signal, in-repo-profile-not-on-base guard

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `profile.md` — I#4 (branch off base) + I#5 (inline mode)

**Files:**
- Modify: `plugins/dev-workflows/commands/impl/docs/profile.md`

**Interfaces:**
- Consumes: the `--inline` token from `docs.md` Phase 0 case (c) (Task 1).
- Produces: an inline mode that creates the branch off the base + commits the profile but skips the naming prompt and the standalone PR-draft/report; standalone behavior unchanged.

- [ ] **Step 1: I#5 — detect `--inline` in arguments**

Replace ``$ARGUMENTS` is an optional repo path; default to the current working directory.` with:
```
`$ARGUMENTS` is an optional repo path (default: the current working directory), optionally followed by `--inline`. The `--inline` token is passed when `/impl:jira:docs` invokes this flow inline (its Phase 0 case (c)); it switches this command to **inline mode** — see Phase 5 step 1, step 2, step 6, and Phase 6.
```

In step 1's "Resolve the repo path", replace `Take the first token of `$ARGUMENTS` as the target path; if `$ARGUMENTS` is empty, default to the current working directory. Resolve it to an absolute path and record it as `<repo>`.` with `Take the first token of `$ARGUMENTS` as the target path; if `$ARGUMENTS` is empty, default to the current working directory. Resolve it to an absolute path and record it as `<repo>`. Treat a `--inline` token (in any position) as the inline-mode flag, not a path; record `inline = true` when present.`

- [ ] **Step 2: I#5 — inline mode skips the branch-naming prompt (Phase 5 step 1)**

Replace this exact block:
```
1. **Resolve the branch name.**
   - If the repo documents a branch-naming convention (detected in Phase 2 / confirmed in Phase 4), fill its placeholders and use it.
```
with:
```
1. **Resolve the branch name.** **Inline mode** (`--inline`): skip the prompt and the confirmation entirely — use the deterministic name `dev-workflows/docs-profile-bootstrap`; `/impl:jira:docs` Phase 6.5 renames it to the docs-branch convention. **Standalone** (default):
   - If the repo documents a branch-naming convention (detected in Phase 2 / confirmed in Phase 4), fill its placeholders and use it.
```

- [ ] **Step 3: I#4 — branch off the default base (Phase 5 step 2)**

Replace `   Then create/switch to the branch: `git -C <repo-root> switch -c <name>` (or `git -C <repo-root> switch <name>` if it already exists).` with:
```
   Then base the branch on the repo's default branch so the profile PR is cut from a clean base: resolve the base (`git -C <repo-root> symbolic-ref --short refs/remotes/origin/HEAD`; fall back to `main`, then `master`) and run `git -C <repo-root> switch <base> && git -C <repo-root> pull --ff-only` (the clean-tree check above already ran; if the fast-forward pull fails, offer the same stash/proceed/cancel choices). Then create the branch: `git -C <repo-root> switch -c <name>` (or `git -C <repo-root> switch <name>` if it already exists).
```

- [ ] **Step 4: I#5 — inline mode skips the standalone PR draft (Phase 5 step 6)**

Replace `6. **Draft the PR message.** Detect the host` with `6. **Draft the PR message.** **Inline mode** (`--inline`): skip this step — control returns to `/impl:jira:docs`, which owns the single PR draft (its Phase 8.5). **Standalone:** Detect the host`.

- [ ] **Step 5: I#5 — inline mode skips the final report (Phase 6)**

After the heading `## Phase 6 — Final report`, insert a new line:
```
**Inline mode** (`--inline`): skip this report — control returns to `/impl:jira:docs`, which produces the consolidated report (its Phase 9). The rest of this section is the standalone report.
```

- [ ] **Step 6: Verify all profile.md edits**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import sys
t = open("plugins/dev-workflows/commands/impl/docs/profile.md").read()
checks = {
  "I#5 arg detect":        "optionally followed by `--inline`" in t and "record `inline = true`" in t,
  "I#5 step1 inline skip": "Inline mode** (`--inline`): skip the prompt and the confirmation" in t and "dev-workflows/docs-profile-bootstrap" in t,
  "I#4 base resolve":      "symbolic-ref --short refs/remotes/origin/HEAD" in t and "switch <base> && git -C <repo-root> pull --ff-only" in t,
  "I#4 then switch -c":    "Then create the branch: `git -C <repo-root> switch -c <name>`" in t,
  "I#5 step6 inline skip": "skip this step — control returns to `/impl:jira:docs`" in t,
  "I#5 phase6 inline skip":"skip this report — control returns to `/impl:jira:docs`" in t,
}
miss=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(("OK  " if v else "MISS")+" "+k)
fences=t.count("\n```"); print(("OK  " if fences%2==0 else "MISS")+f" fence parity ({fences})")
sys.exit(0 if (not miss and fences%2==0) else 1)
PY
```
Expected: every check `OK`, fence parity `OK`, exit 0.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/impl/docs/profile.md
git commit -m "$(cat <<'EOF'
NOISSUE impl:docs:profile: branch off the default base; add inline mode (skip naming prompt + standalone PR-draft) for /impl:jira:docs

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Release v1.14.2 (manifests + CHANGELOG)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: the fixes from Tasks 1–2.
- Produces: a released v1.14.2.

- [ ] **Step 1: Bump `plugin.json` (top-level version)** — change top-level `"version"` from `"1.14.1"` to `"1.14.2"`.

- [ ] **Step 2: Bump `marketplace.json` (plugins[0].version — NOT top-level)** — change `plugins[0].version` from `1.14.1` to `1.14.2`. Verify it's the array entry, not a top-level field.

- [ ] **Step 3: Add the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, insert immediately above `## [1.14.1] — 2026-06-28`:
```markdown
## [1.14.2] — 2026-06-28

### Fixed
- **`/impl:jira:docs` pipeline hardening (post-review).** A comprehensive 3a–3d pipeline review + this spec review found five cross-phase seams, now fixed: (I#1) a Phase 6 ordering note clarifying that Phase 6.5 branch-setup runs before the writer (full renumber deferred); (I#2) the downstream agent briefs and the write invariant now consume the resolved `docs_repo_path` rather than "cwd's git root", so a docs repo discovered outside cwd (or user-entered) is scanned/written correctly; (I#4) `/impl:docs:profile` now bases its branch on the repo's default branch (clean profile PR); (I#5) when `/impl:jira:docs` invokes profiling inline it passes `--inline`, and `/impl:docs:profile` then skips its branch-naming prompt and standalone PR-draft — one branch, one decision, one handoff; (I#6) a Phase 0 guard warns when an in-repo profile is not yet on the base branch (so the docs branch won't include it). No command behavior changed beyond I#4. (`§15` escalation cleanup + the monotonic phase renumber remain deferred to the namespace refactor.)
```

- [ ] **Step 4: Verify**

Run:
```bash
cd /workspace/ihudak-claude-plugins && python3 - <<'PY'
import json,sys
pj=json.load(open("plugins/dev-workflows/.claude-plugin/plugin.json"))
mk=json.load(open(".claude-plugin/marketplace.json"))
ok_pj=pj.get("version")=="1.14.2"; mkv=mk["plugins"][0].get("version"); ok_mk=mkv=="1.14.2"
print(("OK  " if ok_pj else "MISS")+f" plugin.json version={pj.get('version')}")
print(("OK  " if ok_mk else "MISS")+f" marketplace.json plugins[0].version={mkv}")
cl=open("plugins/dev-workflows/CHANGELOG.md").read()
ok_cl="## [1.14.2] — 2026-06-28" in cl and "pipeline hardening (post-review)" in cl
print(("OK  " if ok_cl else "MISS")+" CHANGELOG [1.14.2] entry")
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
NOISSUE Release dev-workflows v1.14.2 — /impl:jira:docs pipeline hardening

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Spec coverage** (against `spec/2026-06-28-sp2-pipeline-hardening-design.md`):
- I#1 ordering note → Task 1 Step 1. ✅
- I#2 (six agent briefs + 105/160 output-filename + 687 git diff + 865 invariant) → Task 1 Steps 2–5. ✅
- I#4 profile.md branches off base → Task 2 Step 3. ✅
- I#5 inline mode (docs.md signal + profile.md naming/step6/Phase6 skips + arg detect) → Task 1 Step 6 + Task 2 Steps 1,2,4,5. ✅
- I#6 Phase 0 guard (in-repo only) → Task 1 Step 7. ✅
- Patch v1.14.2 → Task 3. ✅
- Deferred (I#3, renumber) excluded; line-138 left as-is → Global Constraints + Task 1 Step 8 check. ✅

**2. Placeholder scan:** No "TBD"/"TODO". `<docs_repo_path>`, `<base>`, `<name>`, `<repo-root>`, `<JIRA_KEY>` are existing template placeholders in the command prose (intended). ✅

**3. Type/name consistency:** The `--inline` token is spelled identically in `docs.md` (Task 1 Step 6) and `profile.md` (Task 2 Steps 1,2,4,5). `docs_repo_path` matches Phase 0's name. `dev-workflows/docs-profile-bootstrap` (inline temp branch) is the name Phase 6.5's rename adopts. The I#6 guard's `cat-file -e <base>:.dev-workflows/docs-profile.yml` matches the profile path used everywhere. ✅

**Model guidance for execution:** Task 1 — standard model (mostly mechanical replacements + two prose inserts; the I#6 guard has light logic). **Task 2 — implement standard, review on the most capable model** (the I#4 base-switch + the inline-mode contract are the git-correctness core). Task 3 — cheapest tier; reviewer confirms `marketplace.json` at `plugins[0].version`. Final whole-branch review — most capable model (verify the `--inline` contract end-to-end + that no "cwd's git root" survives).

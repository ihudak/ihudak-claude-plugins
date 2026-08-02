---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-27
---

# dev-workflows docs automation — SP2 Increment 3b: render verification (design)

## Context

Increment 3 of sub-project 2 (the `/impl:jira:docs` single-entry enhancement),
sub-increment **3b**. Builds on 3a (shipped, dev-workflows **v1.12.0** — plugin
`main` at `3c919f3`): multi-space write safety, where Phase 6 writes per space
and protects the other space's render via `{{#if project='…'}}` conditionals or
override-copies + `managed/docstack.jsonc` `ignore`.

3b adds a **render-verification phase** so the run proves the docs it just wrote
actually build and render — and, for cross-space pages, that the 3a invariant
held (the protected space's render is unchanged).

The remaining sub-increments get their own spec→plan cycles:
- **3c — finish & handoff:** Phase 6.5 inline-profiling-branch handling +
  explicit commit/squash + push + copy-paste Bitbucket PR draft.
- **3d — docs & disambiguation:** README "AI-Containers as default" + the
  committed Vale-fallback-note restore + "which docs command?" disambiguation +
  the "All five `/impl:*`" count fix.

## Decisions (resolved during brainstorming)

| Decision | Choice |
|---|---|
| Automation depth | **Build/compile check (auto, gating) + best-effort sequential dev-server smoke-check (opt-in, graceful fallback) + always-emitted "pages to visit" table.** An agent cannot reliably drive long-running/interactive servers end to end, so the smoke-check is best-effort and the human table is the always-present deliverable. |
| Gating behavior | **Gate + auto-fix loop.** Content failures (broken Handlebars, unresolved snippet includes, broken postid links, malformed conditionals) → `doc-fixer` (BLOCKER/MAJOR) → re-run once → choices prompt if any remain. **Environmental** failures (build/lint tool won't run — missing toolchain or `.docstack` shim) → surface-and-ask, no fix loop. Mirrors Phases 6.7/7. |
| Smoke-check assertions | **HTTP 200 + invariant content check.** Every affected page → HTTP 200 in each space it renders in. Cross-space (conditional/override-copy) pages additionally: a **delta marker** must be PRESENT in the target space's render and ABSENT in the protected space's render — directly verifying the 3a render-unchanged invariant. |
| 6.7 vs 6.8 boundary | **No double-lint.** Phase 6.7's `docs-style-checker` already runs the repo's **prose** linter. Phase 6.8 is **build + render** only; it does NOT re-run prose linting. For dynatrace-docs (no separate build command), the **dev-server boot is the build proof**. |
| Delta marker source | **Derived at 6.8 time** (no new Phase 6 output): read each cross-space written file, extract a distinctive literal line from inside its `{{#if project='<target_space>'}}…{{/if}}` block (or the override-copy's distinguishing content). Keeps Phase 6 unchanged. |
| Server management | Orchestrator-driven (like Phase 6 writing), not a subagent — long-running background-process management + reading written files for markers fit the orchestrator, not an isolated agent. Mechanics live in a new reference. |
| Readiness timeout | A new **`profile.dev_servers.readiness_timeout_seconds`** field, **default 120** (command falls back to 120 when the field is absent). Overridable per-repo by editing the profile — non-interactive, fitting the "human starts it, answers Q&A, then unattended" model. Added to the schema + the built-in default profile. |

## Placement

New **Phase 6.8**, between Phase 6.7 (style check) and Phase 7 (doc-reviewer
Opus gate). Rationale: build/render is a structural check; catching a broken
build before the human-facing Opus review is the correct order, and the result
then feeds Phase 7 and Phase 9.

## Increment 3b design

### Phase 6.8 — Render verification

Runs after Phase 6.7, only when write context produced files in a docs repo
(`docs_repo` / confirmed `non_docs_repo`); skipped for `obsidian` / `plain_dir`
(nothing was written into a buildable repo).

**Step 1 — Build check (gating).** Run `profile.commands.build` if the profile
defines one. Classify any failure:
- **Content failure** (broken Handlebars compile, unresolved snippet include,
  broken postid/internal link, malformed conditional) → invoke `doc-fixer`
  (Severities: BLOCKER and MAJOR), re-run the build once, then if any remain:
  `choices: ["Proceed to smoke-check anyway", "Show remaining and fix manually", "Cancel"]`.
- **Environmental failure** (the build/lint tool won't run at all — missing
  toolchain, `command not found`, missing `.docstack` shim) → surface the
  reason and `choices: ["Proceed (build unverified)", "I'll fix locally — retry", "Cancel"]`.
  No `doc-fixer` loop (it's not a content defect).

  When the profile defines **no** build command (dynatrace-docs case), record
  "no build command in profile; build proof deferred to the dev-server boot
  (step 2)" and proceed. Do NOT re-run the Phase 6.7 prose linter here.

**Step 2 — Best-effort dev-server smoke-check (opt-in, graceful fallback).**
Offer it: `choices: ["Run smoke-check (Recommended)", "Skip — use the manual table only", "Cancel"]`.
When run, for each space in `target_spaces`, **sequentially** (per
`profile.dev_servers.concurrent: false`):
1. **Prerequisites (best-effort, no auto-fix).** Verify `profile.prerequisites`
   (e.g. the `.docstack` axios shim — a local, gitignored, reversible
   dev-environment workaround). 6.8 **checks** prerequisites but NEVER
   auto-applies them. If a prerequisite is unmet → record
   "smoke-check skipped for `<space>`: prerequisite `<x>` unmet" and fall back
   to the manual table for that space.
2. **Boot** the space's server from `profile.dev_servers.servers[space].command`
   in the background (record the PID).
3. **Readiness poll** — GET `http://localhost:<port><base_path>/` until HTTP 200
   or a timeout of `profile.dev_servers.readiness_timeout_seconds` (fall back to
   **120** when the field is absent). On timeout → stop the process, record
   "smoke-check skipped for `<space>`: server did not become ready", fall back
   to the manual table for that space.
4. **Per affected page**, GET its derived URL → assert **HTTP 200**.
5. **Cross-space pages** additionally: grep the rendered HTML for the page's
   **delta marker** → assert PRESENT in the target space's render, ABSENT in the
   protected space's render.
6. **Stop the server** (kill the recorded PID) before moving to the next space
   (`concurrent: false` forbids overlap).

Outcomes:
- A **404/500** on an affected page = a render defect → treat as a content
  failure (offer `doc-fixer` / surface as in step 1).
- An **invariant violation** (a cross-space page's delta marker appears in the
  **protected** space's render, or is missing from the target space's render) =
  **Critical** — the 3a protection failed; surface it prominently and
  `choices: ["Fix manually then retry", "Defer to a follow-up (record in Phase 9)", "Cancel"]`.
- Any **boot/prerequisite/readiness** problem is best-effort → never blocks;
  it downgrades that space to the manual table.

**Step 3 — "Pages to visit" table (always emitted).** For every affected page,
a row with: the page (`target_path`); its local URL in each space it renders in
(`http://localhost:<port><base_path>/<route>`); its `write_strategy`; and what to
verify (cross-space rows read "confirm `<target_space>` shows the change and the
`<protected_space>` render is unchanged"). When the smoke-check ran, annotate
each row ✅ 200 / ⚠️ skipped (reason) / ❌ failed. The table is emitted to the
user here and carried into the Phase 9 report.

- **Route derivation (best-effort):** route = `base_path` + the page path
  relative to its space's `content_root`, with a trailing `index.md`/`.md`
  stripped. Approximate — the table is for human visual confirmation, and a
  wrong route that 404s in the smoke-check just downgrades to the manual table.

### Results flow

- **Phase 7** (`doc-reviewer`): the invocation gains a `render_verification`
  input line summarising step outcomes (build result, smoke-check result per
  space or "skipped (reason)", invariant check result).
- **Phase 9** (final report): a new `### Render verification` section carrying
  the "pages to visit" table, the build/smoke outcomes, and any render issue
  deferred to a follow-up.

### Mechanics reference (new)

`references/dynatrace-docs/render-verification.md` — the single source of truth
for: build-vs-boot proof; sequential boot + readiness poll + stop (honoring
`concurrent: false`); route derivation; delta-marker extraction from the written
conditional/override content; the curl assertions including the cross-space
invariant; prerequisites best-effort + no-auto-fix policy; and the graceful
fallback to the manual table. Cited by Phase 6.8, keeping the command lean
(mirrors `multi-space-writing.md`).

## Touch list

- `commands/impl/jira/docs.md` — new **Phase 6.8** (between 6.7 and 7);
  Phase 7 `doc-reviewer` invocation gains a `render_verification` input;
  Phase 9 report template gains a `### Render verification` section.
- `references/dynatrace-docs/render-verification.md` (NEW) — the mechanics.
- `references/dynatrace-docs/docs-profile-schema.md` — document the new
  `dev_servers.readiness_timeout_seconds` field (default 120).
- `references/dynatrace-docs/docs-profile.default.yml` — add
  `readiness_timeout_seconds: 120` under `dev_servers`.
- Manifests + CHANGELOG + README — release bump to **v1.13.0**.

~4 plan tasks.

## Profile dependencies (all already in the built-in default)

`profile.commands.build` (optional; absent for dynatrace-docs), `profile.dev_servers`
(`concurrent`, `servers[].{space,command,port,base_path}`, and the new
`readiness_timeout_seconds` default 120), `profile.prerequisites`,
`profile.spaces[].{content_root,base_path}`, plus `target_spaces` and the
approved `write_strategies[]` from earlier phases.

## Out of scope (later sub-increments)

- **3c** — finish & handoff (Phase 6.5 inline-profiling-branch handling +
  squash/push + Bitbucket PR draft); the zero-external-API invariant is
  untouched here.
- **3d** — README "AI-Containers as default"; the **committed** Vale-fallback
  note restore; "which docs command?" disambiguation; the "All five `/impl:*`"
  count fix.
- 6.8 NEVER auto-applies the `.docstack` workaround (local gitignored dev hack);
  it only checks and reports.

## Resolved during spec review

- Readiness-poll timeout = new `profile.dev_servers.readiness_timeout_seconds`
  field, default **120** (command falls back to 120 when absent); overridable by
  editing the profile, no interactive prompt. Schema + default profile updated.

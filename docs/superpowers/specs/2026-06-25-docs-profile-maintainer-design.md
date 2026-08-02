---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-25
---

# dev-workflows docs automation — Sub-project 1: docs-repo profile maintainer (design)

## Context

Goal of the overall effort: let a single invocation reproduce the kind of
documentation work done by hand for PRODUCT-14902 — i.e. drive feature docs for
a Dynatrace product from its Jira Value Increment across the SaaS and/or Managed
spaces of `dynatrace-docs`, end to end.

A capable command already exists: **`/impl:jira:docs`** in the `dev-workflows`
plugin (`/workspace/ihudak-claude-plugins/plugins/dev-workflows/`, v1.7.2). It
already covers: VI-import check (Phase 0), repo resolution (Phase 4), discrepancy
analysis with a table + per-item user loop + a written gaps doc (Phase 5.8),
style gate via Vale + dt-style-checker (Phase 6.7), and an Opus `doc-reviewer`
gate (Phase 7). The lighter `/impl:docs` is the minor-edit command (no Jira, no
branch) and is out of scope. So this effort is an **enhancement of
`/impl:jira:docs`**, not a greenfield build.

### Cross-cutting decisions (resolved during brainstorming)

| Decision                                      | Choice                                                                                                                                                                                                                                                                                                  |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Entry point                                   | Enhance `/impl:jira:docs` with a `saas\|managed\|both` space argument. Keep the minor-edit `/impl:docs` as-is.                                                                                                                                                                                          |
| Where dynatrace-docs-specific knowledge lives | **Hybrid**: the plugin gains generic, signal-triggered behavior; the repo supplies the specifics via a machine-readable **profile** + CLAUDE.md.                                                                                                                                                        |
| Render verification (steps 6/7)               | Build/lint always → start each server sequentially (saas, then managed) → HTTP smoke-check changed pages → finish with a human "pages to visit + what to check" table. Graceful fallback to build-only + table if the toolchain can't boot.                                                             |
| Planning gate                                 | Invoke the real **superpowers** brainstorming → writing-plans (→ subagent/executing) skills, **pre-fed** with the jira + diff + discrepancy findings so brainstorming only surfaces genuinely open decisions. Planning routed to **Opus**. Degrade to current Phase 2 light-plan if superpowers absent. |
| Profile maintainer scope                      | **First** sub-project (this spec). The `/impl:jira:docs` enhancement that consumes the profile is **sub-project 2**, deferred to its own spec → plan.                                                                                                                                                   |

### Decomposition

- **Sub-project 1 (this spec):** the `docs-profile` schema + a maintainer command
  that scans a docs repo and writes/refreshes the profile + CLAUDE.md guidance as
  a reviewable PR.
- **Sub-project 2 (own spec later):** enhance `/impl:jira:docs` — space arg,
  dev-server verify (6/7), multi-space safety (shadowing/registries/tokens/
  conditionals), push + squash + Bitbucket PR draft (8), Opus superpowers
  planning gate, and Jira-image identification → CDN handoff. Consumes the
  profile produced here.

---

## Sub-project 1 design — docs-repo profile maintainer

### Command

New **`/impl:docs:profile [repo-path]`** in `dev-workflows` (sibling to
`/impl:docs`, `/impl:jira:docs`). Generic — works on any docs repo; produces a
richer profile when it detects a multi-space / docstack repo. It generalizes the
existing `impl-maintenance` "suggest CLAUDE.md / reference updates" pattern into
a **proactive** repo profiler.

### Artifacts it produces (in the target docs repo, as a reviewable PR)

1. **`.dev-workflows/docs-profile.yml`** — the machine-readable **contract** that
   sub-project 2 reads. (Location is a recommendation; tool-namespaced + versioned
   with the repo. Adjustable in review.)
2. **Proposed `CLAUDE.md` additions** — the human/agent narrative (same spirit as
   the PRODUCT-14902 CLAUDE.md PR).

### Profile schema (fields captured)

- `spaces:` — per space: name, content root, snippet root, base path
  (e.g. saas → `dynatrace/_content` + `dynatrace/_snippets`, base `/docs`;
  managed → `managed/_content`, base `/managed`).
- `dev_servers:` — per space: command, port (4000 / 4001), base path,
  `concurrent: false`.
- `build` / `lint` / `format` commands; `commit_hook` (husky → prettier).
- `cross_space_override:` — the manifest (`managed/docstack.jsonc`), the
  allowlist → shadow (last-write-wins by path) rule, and the `ignore`
  requirement for a `managed/_content` override to win.
- `shared_registries:` — lock-step file sets (`schema-ids.yml` +
  `schema-mappings.yml`) and when they must be updated together.
- `tokens:` — gen3 / Classic markers (`{{tag kind='latest'}}`,
  `::app-settings::`) and project conditionals (`{{#if project='…'}}`).
- `internal_links` (postid convention), `branch_naming`
  (`<initials>/<jira>-<slug>`), `images` policy (CDN; user handles upload), and
  `prerequisites` (env quirks, e.g. the `.docstack` toolchain note).
- `changelog` and `owners` — **do not re-specify the rules.** Point these fields
  at the existing v1.8.0 SSOT (the `dynatrace-docs-frontmatter` skill and its
  references `references/dynatrace-docs/changelog-guidelines.md` and
  `managed-owners.txt`). The profile records only _that_ these conventions are
  owned there, plus the file locations.

### How it works

1. **Detect** (Sonnet-tier — §2.1 chain, pinned via `model:`): package.json scripts, `docstack.jsonc`, `.vale.ini`,
   `schema-*.yml`, grep for gen3 tokens / project conditionals, CONTRIBUTING /
   CLAUDE.md / DOCUMENTATION-GUIDELINES.
2. **Synthesize** a draft profile (**Opus** — analytical synthesis of repo
   conventions).
3. **Confirm / fill gaps** interactively with the user (choices arrays) for
   anything detection can't settle.
4. **Write** the profile + CLAUDE.md additions to a branch, commit, and draft a
   PR message. **Idempotent:** if a profile exists, refresh it and show a diff
   rather than clobbering.

### Output mode

Reviewable PR (branch + commit + drafted PR message); never auto-merge —
consistent with the user's workflow.

### Model routing

Detection sub-steps are **pinned** via the `task` tool's `model:` override to a
**mid-tier Sonnet-first chain** — never the inherited session model. (Today
"cheap" means *inherit*, so an Opus session makes "cheap" = Opus, which is wrong.)
Add this chain to the model-routing SSOT
(`references/model-routing/classification.md`, new **§2.1 "mid-tier /
detection-throughput chain"**), mirroring the existing §2 powerful chain:

1. `claude-sonnet-4-6` (latest Sonnet)
2. `claude-sonnet-4-5` (fallback — note the degradation in the report)

The **synthesis** step is pinned to the §2 **powerful** chain (Opus 4.8 → 4.7 →
4.6 → Sonnet floor). Both are explicit `model:` overrides recorded in the
`model_routing` handoff block; neither inherits the session model.

### Reuse of existing v1.8.0 infrastructure (no duplication)

The plugin already ships (v1.8.0) a dynatrace-docs-specific layer the maintainer
must build on, not re-implement:

- **`dynatrace-docs-frontmatter` skill** — SSOT for changelog entries + managed
  owners; the profile's `changelog`/`owners` fields just point here.
- **`references/dynatrace-docs/{changelog-guidelines.md, managed-owners.txt}`** —
  the rule text and the managed-owners ID list.
- **`changelog-owners-reminder` PostToolUse hook** (warn-only) — already nudges
  on `Edit|Write|MultiEdit`; the profile/CLAUDE.md additions must stay consistent
  with it (don't contradict or duplicate its checks).

This also reconciles the hybrid decision: some dynatrace specifics (frontmatter)
already live *in the plugin*; the per-repo profile covers the rest (spaces,
dev-servers, shadowing, registries, tokens, links, branch-naming, images).

## Out of scope

- Sub-project 2 (the `/impl:jira:docs` enhancement) — separate spec → plan.
- Auto-merging the profile PR.
- The minor-edit `/impl:docs` command (unchanged).
- Non-docstack repos still get a profile, but a thinner one (only what detection
  + the user confirm).

## Resolved

- **Profile path** = `.dev-workflows/docs-profile.yml` (confirmed).
- **Command name** = `/impl:docs:profile` (confirmed).
- **Detection model** = mid-tier Sonnet-first chain (§2.1), pinned via `model:`
  override — not the inherited session model.
- **changelog/owners** = defer to the existing v1.8.0 `dynatrace-docs-frontmatter`
  skill + references; do not duplicate.

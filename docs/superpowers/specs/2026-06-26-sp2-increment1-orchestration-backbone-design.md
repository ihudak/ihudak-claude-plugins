---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-26
---

# dev-workflows docs automation — SP2 Increment 1: orchestration backbone (design)

## Context

Sub-project 2 turns `/impl:jira:docs` into the **single entry point** that drives
Jira-driven Dynatrace documentation end to end — so the user runs one command
with a few parameters rather than memorizing a sequence (the superpowers
`/brainstorming` model). SP2 is large, so it is decomposed into 3 shippable
increments; **this spec is Increment 1** (the backbone). Increments 2–3 get their
own spec → plan cycles.

Builds on **SP1** (shipped, dev-workflows v1.9.0): the `/impl:docs:profile`
command + `docs-profile.yml` schema + the model-routing §2.1 Sonnet chain. SP1's
role is now refined to an **on-demand bootstrap/refresh**, not a required first
step.

### Cross-cutting SP2 decisions (resolved during brainstorming)

| Decision | Choice |
|---|---|
| Entry model | **Single command** `/impl:jira:docs PRODUCT-NNNN [saas\|managed]` drives the whole process; no fixed command sequence the user must remember. |
| Environment / locations | **AI-Containers is the default use-case**: all repos (docs, specs, code, vault) are under `/workspace`. On a host they are not → the command **asks**. |
| dynatrace-docs knowledge | **Built-in default profile shipped in the plugin** (zero-config on dynatrace-docs); an in-repo `.dev-workflows/docs-profile.yml` overrides; `/impl:docs:profile` for custom repos + refresh. |
| Specs as input | A specs repo (e.g. `mgd-specifications`; name varies by capability) under `/workspace`; per-VI specs live in a `PRODUCT-NNNN*` folder under a detected vis-root (`specifications/` or `vis/`). **Missing → no specs for that VI; proceed without them.** |
| Space parameter | Optional `saas\|managed` is a **constraint**, not a selector. **No `both`.** Default = auto-determine applicability (saas / managed / both) from artifacts; arg restricts to one space. |
| Decomposition | Inc 1 = backbone (this spec); Inc 2 = inputs & analysis (specs → planner, 3-way discrepancy, images → CDN); Inc 3 = safe multi-space writing, dev-server verify + pages table, planning gate, squash/push + PR draft, README AI-Containers doc. |

### Constraint semantics (what `saas` / `managed` mean operationally)

The constraint follows the PRODUCT-14902 split-PR model: `managed` produces the
docs for **Managed** customers while the **SaaS** rendered output stays
**unchanged**; `saas` is the converse (don't break the Managed render). The other
space is protected with the established techniques — `{{#if project='…'}}`
conditionals for small differences, or **override-copies + `managed/docstack.jsonc`
`ignore` allowlisting** when changes are significant. These protection techniques
are built in **Increment 3**; Increment 1 only carries the constraint through the
pipeline.

## Increment 1 design — orchestration backbone

### 1. Single entry point

`/impl:jira:docs PRODUCT-NNNN [saas|managed]`. The space arg is optional and acts
as a **constraint**:
- **omitted** → determine applicability and document every applicable space;
- **`saas`** or **`managed`** → document only that space, ignoring the other even
  if the feature applies to both.

### 2. Phase 0 — preflight discovery & validation

Locate + validate every artifact up front, then print a readiness table. All
discovery defaults to `/workspace` (AI-Containers); when a path is not found
(host, or non-standard mount) the command **asks**, remembering the last value.

- **Vault** (`$VAULT_PATH`) + the VI's `jira-products/PRODUCT-NNNN/` (VI/Epics/
  Stories) — existing check; stop if the VI folder is missing.
- **Specs dir** — find a sibling under `/workspace` whose detected vis-root
  (`specifications/` or `vis/`) contains a `PRODUCT-NNNN*` folder (prefix match;
  mixed `-`/`_` separators + slug). **Missing → specs don't exist for this VI;
  record `specs: none` and proceed.**
- **Code repos (usually multiple per VI)** — resolved from **all** the VI's PR
  URLs across repositories, under `/workspace` (default `$REPOS_PATH`); each PR
  URL maps to its repo by remote/slug; unresolved repos escalate to the user
  (existing Phase-4 behavior).
- **Docs repo** (decision A): prefer **cwd** if it is a docs repo; else discover
  **dynatrace-docs** under `/workspace`; else **ask**. Confirm it is writeable.

### 3. Applicability determination (first-pass)

When the space arg is omitted, determine which product(s) the feature shipped to
from cheap preflight signals — Jira VI/Epics product field / labels / text, the
**space classification of the code repos** the PRs touched, and specs presence —
then **confirm with the user** via a `choices` prompt (auto-detected space(s) as
the first/default choice; last choice `"Other… (describe)"`). The space arg, when
given, **skips** this prompt. (The authoritative determination from full diff /
spec / discrepancy analysis is refined in Increment 2; Increment 1 establishes the
mechanism + confirmation.)

### 4. Profile resolution order

For the resolved docs repo (decision B):
1. in-repo `.dev-workflows/docs-profile.yml` present → use it;
2. else recognized as **dynatrace-docs** (by signals — `managed/docstack.jsonc`,
   `dynatrace/_content` — and git remote, not name alone) → use the **built-in
   default profile** shipped in the plugin at
   `references/dynatrace-docs/docs-profile.default.yml` (conforms to SP1's
   `docs-profile-schema.md`);
3. else (custom repo, no profile) → **on-demand profiling** (§5).

### 5. On-demand profiling (inline)

When step 4.3 applies — or required config is otherwise missing — the command
**invokes `/impl:docs:profile` inline** as a sub-flow (the user does the one-time
config interactively), then **resumes**; the user still started only one command.
A host environment with missing *paths* is resolved by **asking**, not profiling.

### 6. Space threading

The resolved space(s) flow into the existing pipeline (jira-reader →
diff-summaries → doc-location-finder → doc-planner → …) so later increments write
to the correct `_content` / `_snippets` roots per the profile's `spaces[]`.

## Deliverable & verification

One command that, given `PRODUCT-NNNN [space]`, resolves and reports readiness for
every input (vault VI, specs presence, code repos, docs repo + profile source),
determines and confirms the applicable space(s) (or honors the constraint), and bootstraps
a custom repo via inline profiling / asks on a host. Verified structurally:
command frontmatter + phases parse; the built-in default profile validates against
`docs-profile-schema.md`; discovery + applicability logic dry-run against
`/workspace`; `/impl:docs` and `/impl:docs:profile` remain intact.

## Out of scope (later increments)

- **Increment 2:** spec markdown → `doc-planner` as authoritative "intended"
  source; 3-way discrepancy (spec vs code vs Jira); image identification + CDN
  handoff.
- **Increment 3:** multi-space write safety (shadowing / schema registries /
  gen3-Classic tokens / `{{#if project}}` conditionals); build/lint + sequential
  dev-server smoke-check + "pages to visit" table; superpowers planning gate;
  squash/push + Bitbucket PR draft; README "AI-Containers as default" doc.
- PR split strategy for a both-spaces feature (Increment 3).

### Carried forward to Increment 3 (surfaced during Increment 1 execution)

- **Restore the README `/impl:jira:docs` Vale-fallback note** ("Vale-missing → dt-style-checker, mandatory") dropped during the 1.10.0 description refresh — the mechanic stays intact in Phase 6.7; only the one-line README summary lost it. **Committed obligation (user-confirmed).**
- **"Which docs command?" disambiguation** in the `/impl` dispatcher help + README (`/impl:docs` vs `/impl:jira:docs` vs `/impl:docs:profile`).
- **Inline-profiling branch handling:** `/impl:docs:profile` does `git switch -c`, so on-demand profiling (Phase 0 `generated` path) leaves `/impl:jira:docs` on the profile branch — Phase 6.5 branch setup must account for it.

## Resolved

- **A** docs-repo target = cwd → `/workspace` discovery (dynatrace-docs) → ask.
- **B** built-in dynatrace-docs default profile in the plugin; in-repo override.
- **C** on-demand profiling is invoked **inline** by the command (custom repos /
  missing config), then resumes.
- **Space param** = optional `saas|managed` constraint; no `both`; default
  auto-determines applicability and confirms.

## Open items (confirm during spec review)

- Built-in default profile filename — defaulted to
  `references/dynatrace-docs/docs-profile.default.yml`. Confirm or rename.
- Code-repo → space classification source for the first-pass applicability guess
  (heuristic by repo name vs a small mapping in the profile) — to be settled when
  Increment 1's plan is written; Increment 1 confirms the guess with the user
  regardless.

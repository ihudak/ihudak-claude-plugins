---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-26
---

# dev-workflows docs automation — SP2 Increment 3a: multi-space write safety (design)

## Context

Increment 3 of sub-project 2 (the `/impl:jira:docs` single-entry enhancement).
Builds on Inc1 (v1.10.0 — single-entry orchestration + `target_spaces`) and Inc2
(v1.11.0 — spec-grounded 3-way discrepancy + images). The plugin's `main` is at
`806d597`.

**Increment 3 is decomposed** into four shippable sub-increments; **this spec is
3a** (the keystone). The others get their own spec→plan cycles:
- **3a (this) — multi-space write safety:** Phase 6 consumes the profile +
  `target_spaces` to write per space and *protect the other space's render*.
- **3b — render verification:** build/lint + sequential dev-server smoke-check +
  "pages to visit" table.
- **3c — finish & handoff:** Phase 6.5 inline-profiling-branch handling + explicit
  commit/squash + push + copy-paste Bitbucket PR draft (respecting the existing
  zero-external-API invariant).
- **3d — docs & disambiguation:** README "AI-Containers as default" section + the
  **committed Vale-fallback-note restore** + "which docs command?" disambiguation +
  fix the "All five `/impl:*`…" count.

**The in-command superpowers planning gate is DROPPED** (was in the original SP2
framing). Rationale (user-confirmed): the command already has the domain-specific
equivalents of planning — `doc-location-finder` (where), `doc-planner` (the
checklist = the plan), the 3-way discrepancy (intended-vs-actual), and the Opus
`doc-reviewer` gate (review). A generic brainstorm→spec→plan would duplicate those
and slow every run. The one genuinely design-y decision (per-shared-page
conditional-vs-override-copy) is handled domain-specifically inside 3a (below),
not via a generic gate.

## Key precision — "SaaS render unchanged" ≠ "SaaS file untouched"

The `saas`/`managed` constraint protects the **rendered output** of the other
space, NOT the source file. For a small difference, the correct technique is to
**edit the shared (SaaS) source file** and wrap the delta in an
`{{#if project='managed'}}…{{/if}}` clause — the file changes, but SaaS renders
nothing new while Managed renders the addition. So 3a's heuristic treats "add an
if-`<otherspace>` conditional to the shared page" as the **small-diff** path; the
override-copy is for **significant/structural** divergence.

## Decisions (resolved during brainstorming)

| Decision | Choice |
|---|---|
| Per-shared-page strategy | **Heuristic + per-page approval**: small/localized → inline `{{#if project='…'}}` conditional in the shared page; significant/structural → override-copy into the other space's `_content` + `managed/docstack.jsonc` `ignore`. Recommended by `doc-planner`; approved (override-able) in a new post-planner step. |
| Strategy approval placement | New **Phase 5.9** (after `doc-planner`/discrepancy, before Phase 6 write) — NOT Phase 2 (which runs before the planner knows per-page divergence). |
| Mechanics location | A new `references/dynatrace-docs/multi-space-writing.md` cited by both the command and `doc-planner` (keeps them lean). |
| Planning gate | Dropped (see Context). |

## Increment 3a design

**A. Per-space routing.** Phase 6 reads `profile.spaces[]` + `target_spaces` and
writes each target into the correct space's `content_root`/`snippet_root`. A
single-space `target_spaces` writes only that space.

**B. Per-shared-page write strategy (keystone).** For a page rendered in both
spaces that must differ — or a `saas`/`managed`-constrained change to a shared
page — `doc-planner` emits a per-shared-target `write_strategy` recommendation
(`conditional` | `override-copy`) with rationale, based on the divergence it
already computes. New **Phase 5.9** presents the per-page strategies; the user
approves or overrides before writing.

**C. Override-copy mechanics.** When `override-copy` is chosen, Phase 6 copies the
page into the target space's `_content` and adds the shared source path to the
`managed/docstack.jsonc` allowlist **`ignore`** (per `profile.cross_space_override`),
so the override wins and the other space's render is unchanged. (The PRODUCT-14902
mechanism — see [[managed-docs-override-shadowing]].)

**D. Conditional mechanics (small diff).** When `conditional` is chosen, Phase 6
edits the shared source page in place, wrapping the per-space delta in
`{{#if project='…'}}…{{/if}}` so the other space's render is unchanged.

**E. Shared-registries lock-step.** When a settings-schema page is renamed/created,
Phase 6 updates `schema-ids.yml` + `schema-mappings.yml` together (per
`profile.shared_registries`).

**F. Token/conditional correctness.** Validate that emitted gen3/Classic tokens
(`{{tag kind='latest'}}`, `::app-settings::`) and `{{#if project='…'}}` conditionals
are well-formed and space-appropriate (per `profile.tokens`); flag malformed ones
before the style/review gates.

**Net effect = the invariant.** A `managed` run produces Managed docs while the
SaaS *render* stays unchanged (via if-managed conditionals for small diffs or
override-copies for large), and vice-versa; a no-constraint both-spaces run
documents both per-page.

## Touch list

- `agents/doc-planner.md` — emit per-shared-target `write_strategy`
  (`conditional`|`override-copy`) + rationale; multi-space awareness.
- `commands/impl/jira/docs.md` — Phase 6 consumes `profile` + `target_spaces`
  (per-space routing); new **Phase 5.9** write-strategy approval; Phase 6
  override-copy + docstack `ignore`, in-place conditional edit, shared-registries
  lock-step, token-correctness validation.
- `references/dynatrace-docs/multi-space-writing.md` (NEW) — the mechanics
  (shadowing/`ignore`, conditional-vs-override heuristic, registries lock-step,
  token rules), cited by the command + `doc-planner`.
- manifests + CHANGELOG + README — release bump.

~5 plan tasks.

## Out of scope (later sub-increments)

- 3b render verification; 3c finish & handoff (incl. the Phase 6.5
  inline-profiling-branch handling + squash/push + Bitbucket PR draft); 3d docs.
- **Carried obligations for 3d:** restore the README `/impl:jira:docs`
  Vale-fallback note (**committed**); "which docs command?" disambiguation; fix
  the "All five `/impl:*`…" count.
- **Carried for 3c:** inline `/impl:docs:profile` does `git switch -c`, leaving
  `/impl:jira:docs` on the profile branch — Phase 6.5 must account for it.

## Open items (confirm during spec review)

- The conditional-vs-override heuristic's divergence signal: `doc-planner` bases
  it on the per-target content divergence it already estimates (structural change
  / new sections / large rewrites → override-copy; localized wording/single-block
  → conditional). Confirm this signal is acceptable vs. needing an explicit
  threshold.

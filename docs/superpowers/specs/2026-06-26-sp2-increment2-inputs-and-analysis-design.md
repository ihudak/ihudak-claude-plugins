---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-26
---

# dev-workflows docs automation — SP2 Increment 2: inputs & analysis (design)

## Context

Increment 2 of sub-project 2 (the `/impl:jira:docs` single-entry enhancement).
Builds on **Increment 1** (shipped, dev-workflows v1.10.0): Phase 0 already
discovers `specs_dir` (the VI's `PRODUCT-NNNN*` folder under `/workspace`) but
currently **drops it** after the space-applicability step. This increment wires
the spec in as the authoritative "intended" source for verification, makes the
discrepancy analysis 3-way, and auto-feeds spec/Jira images into the existing
CDN handoff.

**Approach:** extend the existing agents/phases at the exploration's extension
points — **no new agents**. The machinery already exists: `doc-planner` runs
source-truth verification and emits `verification_warnings[]`; Phase 5.8 already
presents a discrepancy table + per-item decisions + writes the
`<JIRA_KEY>-implementation-gaps.md` bug-draft; the CDN path already stages images
+ inserts `TODO-upload` placeholders + lists them in Phase 9.

### Decisions (resolved during brainstorming)

| Decision | Choice |
|---|---|
| Spec's role | **Authoritative "intended" source**, corroborated by Jira; code is "actual." |
| Discrepancy model | **3-way**: `Jira \| Spec \| Code`. Code-differs-from-spec is the main discrepancy; spec-differs-from-Jira is surfaced (spec wins). |
| CDN handoff | **Interactive with async fallback**: list images + targets → user uploads + pastes links → write real CDN URLs; defer → existing stage + `TODO-upload` + Phase 9 list. |
| Image sources | Recursive `specs_dir` scan **+** extended `jira-reader` `attachments[]` (vault Jira export) **+** manual paths. |
| Authoritative spec files | VI-level spec + per-epic spec summaries + each epic's `requirements.md` + `design.md`. `tasks.md` = secondary "planned-to-ship" signal. Ignore `idea.md`/`prompt.md`/generated HTML. |
| Build vs new | Extend `doc-planner`, `jira-reader`, the command phases, and `source-truth.md`. No new agents. |

## Spec-tree shape (what `specs_dir` contains)

A VI's specs folder is a **tree**, layout varies by VI:
- single root spec `PRODUCT-<key>*.md` (or `specification.md`) ± a `spec/` subdir; or
- a kiro tree: root VI spec + `epics/epic-*.md` + `epics/<epic>/{requirements,design,tasks}.md` (e.g. `PRODUCT-17753` has epics A and B).

Spec ingestion must discover spec markdown flexibly across these layouts, not
assume a single canonical file.

## Increment 2 design

### A. Spec tree as authoritative intended source

- **Forward `specs_dir`** (already resolved in Phase 0) into `doc-planner` as a
  new input; add it to the Phase 5.7 invocation brief.
- `doc-planner` **reads the spec tree from the path selectively** (like it already
  does for `code_repos` — not all pasted): the VI spec + per-epic specs +
  `requirements.md` + `design.md` as authoritative intended; `tasks.md` as a
  secondary "planned" signal; ignore `idea.md`/`prompt.md`/HTML.
- The doc topics' claims reflect the **spec** (authoritative intended); verified
  against **code (actual)** via the existing source-truth techniques plus a new
  `technique: spec-markdown`. Warnings carry `spec_phrasing` alongside
  `jira_phrasing` and `source_phrasing`.
- `source-truth.md` updated: spec markdown is the top "intended" source; defines
  the 3-way classification (see B).

### B. 3-way discrepancy (Phase 5.8)

- Table: `# | Claim | Jira | Spec | Code | Source location | Verdict`.
- Two discrepancy kinds: **code-differs-from-spec** (the main case — decide
  document intended/spec vs actual/code, draft a bug) and **spec-differs-from-Jira**
  (surfaced; spec wins as authoritative).
- `discrepancy_decisions[]` and the `…-implementation-gaps.md` bug-draft gain the
  spec leg; per-item choices read "Document as intended (spec)" / "Document as
  actual (code)" / "Skip & report."

### C. Image identification

- A pre-planner step builds a candidate image list from three sources: a
  **recursive scan of `specs_dir`** (root + `epics/` + `spec/`, deduped), a new
  **`attachments[]`** field from an extended `jira-reader` (image files in the
  vault Jira export for the VI), and the existing **manual path** option.
- Present the merged candidates; selected images flow into `doc-planner`'s
  existing `screenshots[]` → placement machinery (unchanged downstream).

### D. Interactive CDN handoff (async fallback)

- After `doc-planner` returns `cdn_upload_required` placements, a new step lists
  each image → its target page/anchor + alt text, and asks the user to upload to
  CDN and paste each link → writes the **real URLs** into the docs.
- **Defer fallback** = the existing behavior: stage under `<screenshot_staging_dir>`
  + insert `TODO-upload` placeholder + list in Phase 9.

## Touch list

- `agents/doc-planner.md` — new `specs_dir` input; read the spec tree; spec-markdown
  verification; `spec_phrasing` in warnings; new `technique: spec-markdown`.
- `agents/jira-reader.md` + `references/handoff/jira-reader.md` — emit `attachments[]`
  (image files from the vault Jira export).
- `commands/impl/jira/docs.md` — Phase 5.7 pass `specs_dir`; Phase 5.8 3-way table +
  decisions; new image-candidate step; new interactive CDN-handoff step.
- `references/source-truth.md` — spec markdown as authoritative intended source +
  the 3-way classification.
- Manifests + CHANGELOG + README — release bump.

~6 plan tasks.

## Out of scope (Increment 3)

- Multi-space write safety (shadowing / schema registries / gen3-Classic tokens /
  `{{#if project}}` conditionals); build/lint + sequential dev-server smoke-check +
  "pages to visit" table; superpowers planning gate; squash/push + Bitbucket PR draft.
- **README "AI-Containers as default" doc.**
- **Restore the README `/impl:jira:docs` Vale-fallback note** — committed obligation.
- **"Which docs command?" disambiguation** note (`/impl:docs` vs `/impl:jira:docs` vs `/impl:docs:profile`).
- **Inline-profiling branch handling:** `/impl:docs:profile` does `git switch -c`, so the Phase 0 `generated` path leaves `/impl:jira:docs` on the profile branch — Phase 6.5 must account for it.

## Resolved

- Spec = authoritative intended; 3-way `Jira|Spec|Code`; CDN interactive + async
  fallback; image sources = specs scan + jira-reader attachments + manual;
  authoritative spec files = VI/epic specs + requirements + design (tasks secondary).
- `doc-planner` (not the orchestrator) reads the spec tree, keeping verification in
  one place; reads selectively from `specs_dir` to bound volume.

## Open items (confirm during spec review)

- Very large spec corpora: `doc-planner` reads requirements/design/epic+VI specs
  first; `tasks.md` only if needed. Confirm this selective-read order is acceptable
  vs. a hard cap.

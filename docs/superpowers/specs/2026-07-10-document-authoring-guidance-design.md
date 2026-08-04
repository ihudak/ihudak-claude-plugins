---
tags:
  - tasks-exclude
---

# `/document` authoring-guidance uplift — extended frontmatter metadata + repo authoring-rule ingestion

**Status:** Shipped in dev-workflows v2.12.0 — pre-implementation design snapshot, kept as authored.
**Date:** 2026-07-10
**Target:** `dev-workflows` plugin, docs pipeline (`doc-planner`, `doc-writer`, `doc-reviewer`, the `dynatrace-docs-frontmatter` skill, a new reference)
**Release:** MINOR `v2.12.0` (new authoring behavior; additive)
**Origin:** AI-First.md task line 86 ("Incorporate the changelog and metadata guidelines in the docs command"). The audit found the **changelog** guidelines already fully encoded (`references/dynatrace-docs/changelog-guidelines.md`) and styleguide.dynatrace.com already vendored+respected via the `dt-style-guide` plugin. This effort closes the two remaining deltas.

## Goal

- **Delta (a):** hard-encode the docs repo's **extended frontmatter/metadata rules** — `description` length, `meta.content-type` enum, `meta.i18n-priority`, `meta.generation`, `title`, `published` — so `/document` plans, writes, and reviews them (today only `changelog` / `owners` / `published` / `meta.generation` / `readtime` / `tags` are handled, and none with field-level rules).
- **Delta (b):** teach **Jira-mode `/document`** to ingest a docs repo's **own authoring-guidance files** (CONTRIBUTING.md, CLAUDE.md, etc.) as repo-specific rules for the writer — not just for branch naming. (Direct mode's Phase 2A exploration already does the equivalent and is left untouched.)

## Authoritative sources (verified 2026-07-10)

- `dynatrace/_data/meta.yml` (the docs repo): `content-type` is **Mandatory metadata**; enum = `tutorial, explanation, reference, how-to, release-notes, troubleshooting, upgrade, extension, app, get-started, best-practices` plus `overview` (**deprecated — do not use for new content**). `generation` = array of `latest` / `classic` (a `latest`-only page that surfaces in Managed **breaks the build**). `i18n-priority` = a number.
- The docs repo `CLAUDE.md`: `description` = SEO text, **120–160 characters**; internal links use `[text](<postid>)`.
- This repo has **`CONTRIBUTING.md`** (workflow / naming / PR-checklist) and **`CLAUDE.md`** (writing style + frontmatter + components); there is **no** `DOCUMENTATION-GUIDELINES.md`. Delta (b) must therefore be **generic** over whichever guidance files a repo has.

## Delta (a) — extended frontmatter/metadata rules

### New reference — `references/dynatrace-docs/frontmatter-guidelines.md`

Companion to `changelog-guidelines.md`; the single source of truth for dynatrace-docs frontmatter **fields** (changelog + owners stay in their own files, cross-linked). Encodes the rules directly (no dependency on a `meta.yml` path, which is repo-version-specific):

- `title` — required; sentence case; concise.
- `description` — required for SEO; **120–160 characters**; a warning outside that band.
- `meta.content-type` — **mandatory on new pages**; one of the enum above (listed verbatim); `overview` marked deprecated.
- `meta.i18n-priority` — a number (lower = higher priority); optional/advisory.
- `meta.generation` — array of `latest` / `classic` (both = `[classic, latest]`); note the Managed build caveat; advisory.
- `published` — creation date on new pages only (already handled; restated for completeness).
- Cross-links to `changelog-guidelines.md` (the `changelog:` property) and `managed-owners.txt` (owners).
- Scope note: these are **dynatrace-docs** conventions, applied only under the dynatrace-docs profile — exactly like changelog/owners.

### Wiring

- **`skills/dynatrace-docs-frontmatter/SKILL.md`** — reference the new file; extend the "one pass" to set/validate `content-type` (mandatory, new pages) and check `description` length, in addition to the existing changelog + owners work.
- **`agents/doc-planner.md`** — the "Plan frontmatter updates" step adds `description` (120–160), `meta.content-type` (mandatory, new pages, from the enum), `meta.i18n-priority`, reinforced `meta.generation`. Still: detect conventions by sampling adjacent pages; NEVER a Jira key in `changelog`.
- **`agents/doc-writer.md`** — write those fields on new pages; preserve unknown fields; never strip.
- **`agents/doc-reviewer.md`** — the "YAML frontmatter" dimension gains: `content-type` present + valid on a **new page → BLOCKER** if missing/invalid; `description` outside 120–160 → **warning (MAJOR/MINOR)**; `i18n-priority` / `generation` → advisory note only.

### Enforcement (confirmed)

`content-type` = **BLOCKER** (mandatory per meta.yml), `description` length = **warning**, `i18n-priority` / `generation` = **advisory**. Applied only under the dynatrace-docs profile; never universally.

## Delta (b) — Jira-mode ingestion of a repo's own authoring rules (generic)

### `agents/doc-planner.md`

Add an early "**Read repo authoring guidance**" step: scan the docs repo root (and `.claude/`) for `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `CLAUDE.md`, `STYLE.md`, `DOCUMENTATION-GUIDELINES.md` (whichever exist) and extract **authoring/structural** rules — required sections, voice/tone directives, page templates, naming/structure conventions, prohibited constructs. Fold them into the documentation checklist. Emit a distilled **`repo_authoring_guidance`** block (bullet rules + source file) in the handoff.

- **Generic** — no dynatrace-docs assumption; works for any docs repo.
- Does **not** duplicate: branch naming stays in `document.md` Phase 6.2; the built-in dynatrace-docs references remain authoritative for frontmatter/changelog/style. Extract only prose/authoring rules not already covered.

### `agents/doc-writer.md`

Accept `repo_authoring_guidance` in the input contract; follow those rules when writing (they augment, never override, the built-in references or `dt-style-guide`).

### `agents/doc-reviewer.md`

Add a check: written pages adhere to the `repo_authoring_guidance` rules the planner surfaced (severity per the rule's nature; missing a repo-mandated section → MAJOR).

### `commands/document.md` (Jira mode)

Phase 5.7 already dispatches `doc-planner`; surface the planner's `repo_authoring_guidance` in the **Phase 5.7 plan output** so the user sees "this repo's CONTRIBUTING.md requires …" before writing. No new phase; the doc-planner dispatch input/plan-rendering is extended. Direct mode (Mode B) is **untouched** (Phase 2A already ingests these files).

## Scope & boundaries

- Edited files: **new** `references/dynatrace-docs/frontmatter-guidelines.md`; `skills/dynatrace-docs-frontmatter/SKILL.md`; `agents/doc-planner.md`, `agents/doc-writer.md`, `agents/doc-reviewer.md`; `commands/document.md` (Phase 5.7 plan-render only, if needed); release surfaces.
- **Untouched:** `changelog-guidelines.md` (only cross-linked), `/release-notes` + `release-notes-writer`, `docs-profile` schema, the hook, `dt-style-guide` and the other sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1), and `/document` direct mode.

## Invariants preserved

- Frontmatter rules apply **only under the dynatrace-docs profile**; a generic docs repo is unaffected by delta (a).
- `repo_authoring_guidance` **augments**, never overrides, the built-in references or `dt-style-guide`; no rule precedence inversion.
- `doc-writer` still preserves unknown frontmatter fields and never strips them; changelog still carries **no** Jira key.
- No new external calls, no new subagents, no new commands; nothing fails the run.
- Direct mode and `/release-notes` behavior unchanged.

## Verification (structural — no test framework)

- New `frontmatter-guidelines.md` exists; content-type enum listed verbatim (incl. `overview` deprecated); `120`/`160` description band present; cross-links to changelog-guidelines + managed-owners resolve.
- `doc-planner` names `description` / `content-type` / `i18n-priority` and emits `repo_authoring_guidance`; `doc-writer` consumes it; `doc-reviewer` gates `content-type` (BLOCKER) + `description` (warning) + `repo_authoring_guidance` adherence.
- SKILL.md references the new file.
- `git diff` touches only the listed files; `dt-style-guide` / siblings / `/release-notes` / direct mode byte-unchanged.
- JSON valid; versions lock-step `2.12.0`; siblings byte-identical.

## Release

MINOR `v2.12.0`. Lock-step `plugin.json` + root `marketplace.json` (dev-workflows only); `## [2.12.0]` CHANGELOG entry (em-dash date, history preserved). Commit trailer exact: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Never `git add -A`. Execution: lightweight direct edit + structural verification.

---
tags:
  - tasks-exclude
---

# `/document` — broaden image discovery to the Projects VI-dir

**Status:** Shipped in dev-workflows v2.13.0 — pre-implementation design snapshot, kept as authored.
**Date:** 2026-07-10
**Target:** `dev-workflows` plugin, `commands/document.md` (Phase 1 + Phase 5.6), Jira mode
**Release:** MINOR `v2.13.0`
**Origin:** AI-First.md task line 85 ("`/document` to use images also from `jira-products`"). Audit found the literal ask — and most of the broader request — already implemented; this closes the one real gap.

## Already implemented (verified 2026-07-10)

- **`$SPECS_PATH/specifications/<VI-dir>`** — Phase 5.6 source 1 (recursive scan of `specs_dir`: root + `epics/` + `spec/`).
- **`jira-products/<VI-dir>/.../Attachments`** — Phase 5.6 source 2: `jira-reader` enumerates images under each item's `attachments/` **or** `Attachments/` dir (case-insensitive) into `attachments[]`. (This is the literal line-85 ask.)
- **CDN for Dynatrace Docs** — `image_policy: cdn_upload_required` + the Phase 6.1 upload-now/defer handoff.
- **New/deferred images land in Projects, never jira-products** — staging resolves to the Projects project folder (`find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<KEY>*"`); nothing writes to `jira-products`.

## The gap

`$VAULT_PATH/Projects/<VI-dir>/...` is **not auto-scanned as an image source.** The Projects folder is resolved in Phase 1 only to derive the staging subfolder; images already sitting there are not offered as candidates — the user must add them by hand.

## Design (`commands/document.md` only)

### Phase 1 — record the project-folder root

The existing resolution already runs `find "$VAULT_PATH/Projects" -maxdepth 5 -type d -name "<JIRA_KEY>*" | head -1`. Record that result as **`<project_dir>`** (the persistent Obsidian project folder root). `screenshot_staging_dir` remains its screenshot subfolder (`Doc screenshots/` / `Attachments/`), derived from `<project_dir>` as today. `<project_dir>` is null when no project folder exists (non-`PRODUCT-` ticket).

### Phase 5.6 — add source 4: recursive scan of `<project_dir>`

When `images_wanted` is true and `<project_dir>` is non-null, add a fourth candidate source: a recursive image scan of `<project_dir>`, mirroring the specs-dir scan:

```bash
find "<project_dir>" -type f \
  \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.svg" -o -iname "*.webp" \) 2>/dev/null
```

- Merge + dedupe with the other sources by resolved absolute path (existing rule).
- Extend the candidate summary line to name the new origin: "… `<count>` from specs scan, `<count>` from Jira attachments, `<count>` from the project folder."
- The whole `<project_dir>` is scanned recursively (consistent with the specs scan); the existing "Select a subset" flow lets the user drop any non-doc images.

### Point-4 guidance — where to add a new image

Where `/document` prompts the user to **provide/add** an image (the manual-path option in Phase 5.6, and any doc-planner gap that asks for a screenshot), state explicitly: place new images in the **Projects VI-dir** (`$VAULT_PATH/Projects/<VI-dir>/...`); **never** in `jira-products/` — that directory is regenerated on every Jira import, so a manually-added image there is lost on the next import.

## Scope & boundaries

- Edited file: **`commands/document.md`** (Phase 1 resolution note + Phase 5.6 source list, summary line, and manual-path guidance) + release surfaces.
- **Untouched:** `jira-reader` (source 2 already correct), `doc-planner`/`doc-writer`/`doc-reviewer` (the `screenshots[]` contract and downstream placement/`image_policy`/CDN machinery are unchanged), `/release-notes`, sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1), and `/document` direct mode (Mode B has no Jira/specs/Projects image discovery).

## Invariants preserved

- `screenshots[]` handed to `doc-planner` in Phase 5.7 is unchanged in shape; only the candidate set grows.
- Dedupe still collapses the same image found in >1 source.
- `<project_dir>` null (no project folder) ⇒ source 4 contributes nothing; behavior identical to today.
- No new external calls, no new subagents; nothing writes to `jira-products`.

## Verification (structural — no test framework)

- Phase 5.6 lists **four** sources; the `find "<project_dir>"` scan and the extended summary line ("from the project folder") are present.
- Phase 1 records `<project_dir>`.
- The manual-path / add-image guidance names the Projects VI-dir and warns against `jira-products`.
- `git diff` touches only `commands/document.md` + release files; `jira-reader` / agents / `/release-notes` / direct mode byte-unchanged.
- JSON valid; versions lock-step `2.13.0`; siblings byte-identical.

## Release

MINOR `v2.13.0`. Lock-step `plugin.json` + root `marketplace.json` (dev-workflows only); `## [2.13.0]` CHANGELOG entry (em-dash date). Commit trailer exact: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Never `git add -A`. Lightweight direct edit + structural verification.

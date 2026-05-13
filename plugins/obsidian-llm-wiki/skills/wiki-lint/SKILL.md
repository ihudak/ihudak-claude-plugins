---
name: wiki-lint
description: >
  Run a health check on the wiki. Finds orphan pages, dead wikilinks, stale sources,
  contradictions, index gaps, missing concept pages, and unlinked entities. Produces a
  lint report and asks before making any changes.
  Triggers on: wiki-lint, lint the wiki, wiki health check, check the wiki, wiki audit,
  find orphans, wiki maintenance.
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-lint

Read `skills/wiki-schema/SKILL.md` fully before proceeding.

Invoke with: `/wiki-lint`

---

## Step 1 — Resolve VAULT_PATH

Vault path: `~/obsidian_vault` by default; set `VAULT_PATH` to override. WSL users with a Windows-side vault must set `VAULT_PATH` explicitly (e.g. `/mnt/c/Users/<name>/obsidian_vault`).

---

## Step 2 — Enumerate all wiki pages

First verify the wiki directory exists:
```bash
[ -d "wiki" ] || { echo "Wiki not initialised — run /wiki-ingest to create the first page."; exit 0; }
```

```bash
find "wiki" -name "*.md" \
  -not -name "_index.md" \
  -not -name "_log.md" \
  -not -name "hot.md"
```

Also read `wiki/_index.md` for the catalog (skip if absent) and
`wiki/_manifest.json` for ingest history (skip if absent).

---

## Step 3 — Run all lint checks

Work through each check. Collect findings before writing the report.

### Check 1 — Orphan pages

A wiki page is an orphan if:
- No other wiki page contains a `[[wikilink]]` pointing to it, AND
- It is not listed in `_index.md`

Scan every wiki page body and `_index.md` for wikilinks. Any page not referenced by
either is an orphan.

Severity: **medium** (orphans may be intentional seeds — do not auto-delete).

### Check 2 — Dead links

For every `[[wikilink]]` found in wiki page bodies and frontmatter `related:` lists:
check that a file with a matching basename exists somewhere in the vault.

```bash
find "<VAULT_PATH>" -name "<linked-title>.md"
```

Severity: **high** — dead links silently break the wiki graph.

### Check 3 — Stale sources (Layer 1 files changed since ingest)

For every Layer 1 file recorded in `_manifest.json`:
1. Check if the file still exists.
2. Compute its current hash: `md5sum "<filepath>" | cut -d' ' -f1`
3. Compare to the manifest hash.

If hash differs: the source has changed since it was ingested. The wiki pages derived
from it may be outdated.

Severity: **medium** — flag for re-ingest, do not auto-re-ingest.

### Check 4 — Contradictions

Scan all wiki page bodies for `> [!warning]` callouts containing "contradiction" or
"conflict". These were flagged during ingest and need human resolution.

Severity: **high** — unresolved contradictions mean the wiki has conflicting facts.

### Check 5 — Index gaps

For every `.md` file found in `wiki/concepts/`, `entities/`, `decisions/`,
`patterns/`, and `sources/`: check that it appears as a row in `_index.md`.

Pages present on disk but absent from the index are invisible to `wiki-query` Path B.

Severity: **high** — add missing entries to `_index.md`.

### Check 6 — Missing concept pages

Scan all wiki pages for terms that:
1. Are used as `[[wikilinks]]` in 3 or more distinct pages, AND
2. Do not resolve to an existing page anywhere in the vault.

These are concepts the wiki references repeatedly but has never documented.

Severity: **medium** — create stub concept pages with `wiki-status: seed`.

### Check 7 — Unlinked entities

Scan all wiki page bodies for the names of known entities (read the `entities/` directory
for canonical names). When an entity name appears as plain text (not a wikilink), flag it.

Severity: **low** — informational; the wiki is navigable without these links but they
improve the graph.

---

## Step 4 — Write the lint report

Create `wiki/lint-report-YYYY-MM-DD.md`:

```markdown
---
type: meta
title: "Lint Report YYYY-MM-DD"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - doc
wiki-status: stable
---

# Wiki Lint Report — YYYY-MM-DD

## Summary
- Pages scanned: N
- High severity issues: N
- Medium severity issues: N
- Low severity issues: N
- Safe to auto-fix: N

## Check 1 — Orphan Pages [severity: medium]
- [[concepts/Orphaned Page]]: no inbound links. Suggested fix: link from [[related page]]
  or confirm intentional isolation.

## Check 2 — Dead Links [severity: high]
- [[Missing Page]]: referenced in [[concepts/Source Page]] but does not exist.
  Suggested fix: create stub page or remove wikilink.

## Check 3 — Stale Sources [severity: medium]
- `Meetings/MGD/2026-04-10 MCP Planning.md`: hash changed since ingest on 2026-04-10.
  Suggested fix: run `/wiki-ingest Meetings/MGD/2026-04-10 MCP Planning.md`

## Check 4 — Unresolved Contradictions [severity: high]
- [[concepts/MCP Server]]: contains `> [!warning]` contradiction callout. Needs review.

## Check 5 — Index Gaps [severity: high]
- `wiki/concepts/New Concept.md`: not listed in _index.md.
  Suggested fix: add index row (safe to auto-fix).

## Check 6 — Missing Concept Pages [severity: medium]
- "gRPC": referenced as [[gRPC]] in 4 pages but no concept page exists.
  Suggested fix: create `wiki/concepts/gRPC.md` with wiki-status: seed.

## Check 7 — Unlinked Entities [severity: low]
- "John Brown" appears as plain text in [[concepts/MCP Server]] — not wikilinked.
  Suggested fix: replace with [[entities/John Brown]].
```

---

## Step 5 — Ask before fixing

Show the report summary. Ask:
```
Found: N high, M medium, L low severity issues.
Safe to auto-fix (index gaps, seed stubs): N items.
Fix safe items automatically? [yes / no]
Fix all issues interactively? [yes / no]
```

Safe to auto-fix without asking:
- Adding missing `_index.md` rows for existing pages (Check 5)
- Creating seed stub pages for missing concepts with 3+ references (Check 6)

Requires human decision before fixing:
- Deleting orphan pages (might be intentional)
- Resolving contradictions (requires judgment)
- Deciding whether to re-ingest stale sources

---

## Step 6 — Append to _log.md

```markdown
## [YYYY-MM-DD] lint | health check — N pages, H high, M medium, L low
- Report: [[lint-report-YYYY-MM-DD]]
- Auto-fixed: <N items or "none">
```

---

## Step 7 — Update hot.md

Note the lint run, issue counts, and any fixes applied in `## Recent Changes`.

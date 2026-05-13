---
name: wiki-schema
description: >
  Vault knowledge schema for the obsidian-llm-wiki plugin. Defines the three-layer
  source model, page types, frontmatter schemas, tag rules, cross-linking conventions,
  and the format of _index.md, _log.md, _manifest.json, and hot.md. Read this before
  any wiki operation (ingest, scan, query, save, lint, hot, tags-refresh).
  Triggers on: wiki schema, wiki conventions, wiki structure, wiki rules.
---

# Wiki Schema — obsidian-llm-wiki

Vault knowledge schema for the wiki layer. All wiki skills read this file before
operating. This is the single source of truth for conventions, boundaries, and formats.

All `/wiki-*` slash commands follow these conventions identically across
both Claude Code and GitHub Copilot.

---

## Critical Boundary Rule

Wiki operations (ingest, scan, query, save, lint, hot, tags-refresh) MUST NEVER write
to or delete files from:

- `Meetings/`
- `Daily/`
- `Projects/`
- `Customers/`
- `People/`
- `Clippings/`
- `Research/`

These are Layer 1 — read-only knowledge sources. The wiki reads them; it never modifies them.

The wiki includes two task-management commands — `/wiki-task` and
`/wiki-tasks-extract` — that intentionally write outside the wiki directory
(to `Projects/` files and `Tasks.md`). These are the only wiki commands
allowed to modify files outside `wiki/` and `.raw/`.

---

## Three-Layer Source Model

```
Layer 1 — Sources (read-only for wiki):
  Meetings/            ← meeting notes (primary knowledge source)
  Daily/               ← daily notes — extract ## Notes and ## Worklog sections only;
                          skip Dataview task queries (they are not content)
  Projects/            ← project context, decisions, tech stack
                          includes Products/, Data Generators/, Jira/ subdirs
  Customers/           ← customer notes
  People/              ← person/team notes
  Clippings/           ← web clippings
  Research/            ← research notes

Layer 2 — Inbox (read + archive after processing):
  .raw/                ← external sources: PDFs, exports, web clips
                          The ONLY directory wiki may clean up.
                          After successful ingest: move to .raw/_processed/YYYY-MM/
                          For HTML files: use defuddle if available before ingesting
                            npx defuddle parse <file> --md

Layer 3 — Wiki output (write exclusively here):
  wiki/      ← all wiki pages and meta files
```

---

## Wiki Output Structure

```
wiki/
├── _index.md          ← master catalog (every page, one-line summary, category)
├── _log.md            ← append-only operation log
├── _manifest.json     ← delta tracker {filepath: {hash, ingested_at, wiki_pages[]}}
├── hot.md             ← recent context cache (last ~3 sessions, ≤300 words)
├── concepts/          ← technology/domain concept pages
├── entities/          ← people, teams, customers (synthesis, not replacement of source files)
├── decisions/         ← architectural/product decisions extracted from meetings + projects
├── patterns/          ← reusable approaches, solutions, gotchas
└── sources/           ← one summary page per .raw/ file ingested
```

Source files in Layer 1 dirs do NOT get `sources/` pages — they are referenced via
backlinks in the `sources:` frontmatter field of wiki pages.

---

## Page Types

| Type | Folder | Use for |
|------|--------|---------|
| `concept` | `concepts/` | Technology, framework, or domain idea that recurs across sources |
| `entity` | `entities/` | Person, team, customer, or product appearing in multiple sources |
| `decision` | `decisions/` | Architectural/product/strategic decision extracted from meetings or projects |
| `pattern` | `patterns/` | Reusable approach, solution, gotcha, or workflow |
| `source-summary` | `sources/` | Summary of one `.raw/` file (full extraction, for inbox files only) |

---

## Frontmatter Schemas

### Required fields on all wiki pages

```yaml
---
type: concept | entity | decision | pattern | source-summary
title: "Page Title"
wiki-status: seed | developing | stable
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - <tag from .obsidian/copilot/tag-index.md only — see Tag Rules>
---
```

`wiki-status` meanings:
- `seed` — placeholder, minimal content, created to avoid dead links
- `developing` — content present but incomplete or sparsely sourced
- `stable` — well-sourced, cross-referenced, unlikely to change soon

### Concept page

```yaml
---
type: concept
title: "MCP Server"
wiki-status: developing
created: 2026-04-28
updated: 2026-04-28
tags:
  - ai
  - mcp
  - mgd
sources:
  - "[[Meetings/MGD/2026-04-10 MCP Planning.md]]"
related:
  - "[[concepts/API Gateway]]"
  - "[[decisions/MCP Server Architecture]]"
---
```

### Entity page

```yaml
---
type: entity
title: "John Brown"
wiki-status: stable
created: 2026-04-28
updated: 2026-04-28
tags:
  - mgd
sources:
  - "[[People/John Brown.md]]"
related:
  - "[[entities/BRAVO Team]]"
---
```

### Decision page

```yaml
---
type: decision
title: "Use gRPC for MCP Transport"
wiki-status: stable
created: 2026-04-28
updated: 2026-04-28
decision-date: 2026-04-10
decision-status: active | superseded | proposed
tags:
  - mcp
  - mgd
  - api
sources:
  - "[[Meetings/MGD/2026-04-10 MCP Planning.md]]"
related:
  - "[[concepts/MCP Server]]"
---
```

### Pattern page

```yaml
---
type: pattern
title: "Hot Cache Pattern"
wiki-status: stable
created: 2026-04-28
updated: 2026-04-28
tags:
  - ai
  - doc
sources:
  - "[[Research/LLM Wiki Notes.md]]"
related:
  - "[[concepts/LLM Wiki]]"
---
```

### Source summary page (.raw/ files only)

```yaml
---
type: source-summary
title: "Article or Document Title"
wiki-status: stable
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - doc
source-file: ".raw/articles/filename-YYYY-MM-DD.md"
source-url: "https://..."     # include if applicable; omit if not a web source
related:
  - "[[concepts/Related Concept]]"
---
```

---

## Tag Rules

**Only use tags from `.obsidian/copilot/tag-index.md`. Never invent new tags.**

Most applicable tags for wiki pages:

| Category | Tags |
|----------|------|
| Work area | `#mgd` `#oa` `#saas` |
| Technical | `#ai` `#mcp` `#api` `#k8s` `#lambda` `#docker` `#security` `#sql` |
| Work type | `#doc` `#learn` `#review` |
| Special | `#hide` (exclude from task dashboards if wiki page appears in them) |

If content clearly needs a tag that does not exist: use the closest existing tag AND
note `tag-needed: <proposed-tag>` in the `_log.md` ingest entry. The user can then
approve and add it via `/wiki-tags-refresh`,
which scans `wiki/` for undocumented tags and updates `tag-index.md`.

---

## Cross-Linking Rules

1. **Between wiki pages**: `[[Page Title]]` — Obsidian resolves by filename; no path
   prefix needed as long as filenames are unique across the vault.
2. **Back to Layer 1 source files**: use full vault-root-relative path:
   `[[Meetings/MGD/2026-04-10 MCP Planning.md]]`
3. **First mention rule**: the first time a concept, entity, or decision appears in a
   wiki page body, make it a wikilink.
4. **Every non-seed page must have at least one `related` wikilink** in frontmatter.
5. **Do not wikilink folder names** — only specific files.

### Filename uniqueness

Wiki page filenames must be unique across the entire vault. Before creating a page,
verify the name does not conflict with any existing file anywhere in the vault. If a
conflict exists, add a disambiguating qualifier: `MCP Server (Managed).md`.

---

## _index.md Format and Update Rules

Update after every ingest or save. Add a row for every new page immediately.
Sort each section alphabetically by page title.

```markdown
---
type: meta
title: "Wiki Index"
updated: YYYY-MM-DD
---

# Wiki Index

## Concepts
| Page | Summary | Tags | Updated |
|------|---------|------|---------|
| [[concepts/MCP Server]] | Protocol connecting LLMs to external tools | #ai #mcp | 2026-04-28 |

## Entities
| Page | Summary | Tags | Updated |
|------|---------|------|---------|
| [[entities/John Brown]] | Software engineer, BRAVO team | #mgd | 2026-04-28 |

## Decisions
| Page | Summary | Tags | Updated |
|------|---------|------|---------|
| [[decisions/Use gRPC for MCP Transport]] | gRPC chosen over REST for latency | #mcp #api | 2026-04-28 |

## Patterns
| Page | Summary | Tags | Updated |
|------|---------|------|---------|
| [[patterns/Hot Cache Pattern]] | Short-term context cache for LLM sessions | #ai | 2026-04-28 |

## Sources
| Page | Summary | Source | Ingested |
|------|---------|--------|---------|
| [[sources/LLM Wiki Article]] | Karpathy's LLM wiki pattern explained | .raw/articles/... | 2026-04-28 |
```

Never delete index rows. If a page is removed, mark its summary as `(archived)`.

---

## _log.md Format

`_log.md` is append-only. New entries go at the **top** (newest first). Never edit or
delete past entries.

```markdown
---
type: meta
title: "Wiki Log"
---

# Wiki Log

## [2026-04-28] ingest | Meetings/MGD/2026-04-10 MCP Planning.md
- Pages created: [[concepts/MCP Server]], [[decisions/Use gRPC for MCP Transport]]
- Pages updated: [[entities/John Brown]]
- Key insight: Team chose gRPC for latency; REST considered but rejected.

## [2026-04-28] save | Hot Cache Pattern
- Type: pattern
- Location: [[patterns/Hot Cache Pattern]]
- From: conversation about LLM session continuity

## [2026-04-28] scan | Meetings/ — 3 new, 1 changed, 12 unchanged
## [2026-04-28] lint | health check — 12 pages, 2 orphans, 1 dead link
## [2026-04-28] hot | manual refresh
## [2026-04-28] tags-refresh | 2 new tags proposed, 1 approved
```

Entry type prefixes (grep-parseable):
- `ingest` — single file ingested
- `scan` — directory scan + batch ingest
- `save` — conversation saved as wiki page
- `lint` — health check run
- `hot` — manual hot cache refresh
- `tags-refresh` — tag index sync run

---

## _manifest.json Format

Tracks ingested files to prevent duplicate processing.

```json
{
  "version": 1,
  "sources": {
    "Meetings/MGD/2026-04-10 MCP Planning.md": {
      "hash": "abc123def456",
      "ingested_at": "2026-04-28",
      "wiki_pages": [
        "wiki/concepts/MCP Server.md",
        "wiki/decisions/Use gRPC for MCP Transport.md"
      ]
    },
    ".raw/articles/llm-wiki-2026-04-20.md": {
      "hash": "789xyz012",
      "ingested_at": "2026-04-28",
      "wiki_pages": [
        "wiki/sources/LLM Wiki Article.md",
        "wiki/patterns/Hot Cache Pattern.md"
      ]
    }
  }
}
```

Hash computation: `md5sum <filepath> | cut -d' ' -f1`

Rules:
- Before ingest: if path exists in manifest AND hash matches → skip (already up to date).
- After successful ingest: write/update the entry with current hash, date, and wiki_pages.
- Never delete Layer 1 file entries (keep history).
- `.raw/` entries remain after the source file is archived to `_processed/`.

---

## Hot Cache (hot.md) Format and Update Rules

```markdown
---
type: meta
title: "Hot Cache"
updated: YYYY-MM-DDTHH:MM:SS
---

# Recent Context

## Last Updated
YYYY-MM-DD. [One sentence: what happened in the most recent wiki session]

## Key Recent Facts
- [Most important recent takeaway]
- [Second most important]
- [Third, only if truly significant]

## Recent Changes
- Created: [[concepts/MCP Server]], [[decisions/Use gRPC for MCP Transport]]
- Updated: [[entities/John Brown]] (added context from 2026-04-10 meeting)
- Flagged: Potential contradiction between [[concepts/MCP Server]] and [[decisions/REST API]]

## Active Threads
- [Topic currently being researched or worked on]
- [Open question not yet resolved]
```

Update rules:
- **After ingest** — update with what was ingested and key insights.
- **After save** — note the new page and its topic.
- **After lint** — note issues found and any fixes made.
- **Session end (Stop hook)** — summarize the full session; keep last 3 session blocks,
  delete older ones. Total file ≤300 words.
- **Session start (SessionStart hook)** — read silently to restore context; do not announce.
- **After PostCompact** — re-read silently to restore context lost during compaction.

Total file length: ≤300 words. It is a cache, not a journal.

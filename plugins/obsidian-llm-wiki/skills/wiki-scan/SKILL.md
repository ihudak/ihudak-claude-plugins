---
name: wiki-scan
description: >
  Scan a directory (or all source directories) for source files not yet ingested or
  changed since last ingest, then batch-ingest new and changed files. Shows a diff
  report and asks for confirmation before processing. Triggers on: wiki-scan, scan
  the wiki, scan for new files, wiki scan, batch ingest, ingest new files.
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-scan

Read `skills/wiki-schema/SKILL.md` fully before proceeding.

Invoke with: `/wiki-scan [directory]`

If no directory argument is given, scan all Layer 1 directories plus `.raw/`.

---

## Step 1 — Resolve VAULT_PATH and target directories

Vault path: `~/obsidian_vault` by default; set `VAULT_PATH` to override. WSL users with a Windows-side vault must set `VAULT_PATH` explicitly (e.g. `/mnt/c/Users/<name>/obsidian_vault`).

Default scan targets (all Layer 1 + inbox):
```
Meetings/
Daily/
Projects/
Customers/
People/
Clippings/
Research/
.raw/
```

If a directory argument was given, scan only that directory tree.

---

## Step 2 — Read _manifest.json

Read `wiki/_manifest.json`. If it does not exist, treat all files as new.

---

## Step 3 — Enumerate files and compute hashes

For each `.md` file in the target directory tree:
```bash
find "<dir>" -name "*.md" -not -path "*/_processed/*"
```

For each file, compute hash:
```bash
md5sum "<filepath>" | cut -d' ' -f1
```

Classify each file:
- **New**: path not in manifest → needs ingest
- **Changed**: path in manifest, hash differs → needs re-ingest
- **Unchanged**: path in manifest, hash matches → skip

---

## Step 4 — Report and confirm

Show the scan summary before processing anything:

```
Wiki Scan Results — <directory or "all sources">
─────────────────────────────────────────────────
New files (N):
  - Meetings/MGD/2026-04-15 Sprint Review.md
  - .raw/articles/mcp-patterns-2026-04-20.md

Changed files (M):
  - Projects/Products/P43241 MCP server for Managed.md  (hash changed)

Unchanged files: K (skipping)

Proceed with ingesting N new + M changed files? [yes/no]
```

Wait for explicit confirmation before proceeding. If the user says no, stop.

---

## Step 5 — Ingest each new/changed file

Process files sequentially. For each file, follow the full `wiki-ingest` workflow
(Steps 2–10 of `wiki-ingest` skill — delta check, read, extract, resolve, write pages,
update index, log, manifest, hot cache).

Update `_log.md` once per file during processing (not a single batch entry at the end).

After all files are processed, append one summary entry to `_log.md`:

```markdown
## [YYYY-MM-DD] scan | <directory> — N new, M changed, K unchanged
- Directories scanned: <list>
- Total pages created: X
- Total pages updated: Y
```

---

## Step 6 — Archive processed .raw/ files

For every `.raw/` file that was successfully ingested:

1. Determine the archive destination:
   ```
   .raw/_processed/YYYY-MM/<filename>
   ```
2. Create the directory if needed:
   ```bash
   mkdir -p ".raw/_processed/$(date +%Y-%m)"
   ```
3. Move (not delete) the file:
   ```bash
   mv "<filepath>" ".raw/_processed/$(date +%Y-%m)/<filename>"
   ```

The manifest entry stays (records both original path and ingest date).
Layer 1 files are NEVER moved or deleted.

---

## Step 7 — Handle HTML files in .raw/

Before ingesting any `.html` file found in `.raw/`, check for defuddle:
```bash
npx defuddle --version 2>/dev/null && echo "available" || echo "not available"
```

If available: convert to markdown first:
```bash
npx defuddle parse "<filepath>" --md -o "<filepath>.md"
```
Then ingest the `.md` output. Include the original `.html` in the archive move.

If not available: ingest the `.html` directly (Claude can parse HTML natively).

---

## Finish

Report:
```
Scan complete — <directory>
New files ingested:     N
Changed files re-ingested: M
Unchanged files skipped:   K
.raw/ files archived:   P
Wiki pages created:     X
Wiki pages updated:     Y
```

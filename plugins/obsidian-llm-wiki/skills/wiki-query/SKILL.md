---
name: wiki-query
description: >
  Answer a question using the compiled wiki, with page citations and optional links back
  to original source files. Uses qmd MCP for semantic search when available (Claude Code),
  falls back to index-guided reading otherwise (Copilot). Offers to save substantive
  answers as new wiki pages. Triggers on: wiki-query, ask the wiki, what does the wiki
  say about, query the wiki, wiki query, search the wiki.
allowed-tools: Read Glob Grep Bash
---

# wiki-query

Read `skills/wiki-schema/SKILL.md` fully before proceeding.

Invoke with: `/wiki-query <question>`

---

## Step 1 — Resolve VAULT_PATH

Vault path: `~/obsidian_vault` by default; set `VAULT_PATH` to override. WSL users with a Windows-side vault must set `VAULT_PATH` explicitly (e.g. `/mnt/c/Users/<name>/obsidian_vault`).

---

## Step 2 — Load recent context

Read `wiki/hot.md` if it exists. If the file is absent or empty, skip silently.
If it contains a directly relevant answer or strong context clues, use that to guide which
pages to read.

---

## Step 3 — Choose search path

### Path A — qmd MCP (Claude Code, when qmd collection is registered)

Check if qmd has a wiki collection:
```
mcp__plugin_qmd_qmd__status
```

If the `wiki` collection is listed in the status output, use Path A. Otherwise use Path B.

**Path A steps:**

1. Run a hybrid search against the wiki collection:
   ```
   mcp__plugin_qmd_qmd__query
   searches: [{type: "lex", query: "<keywords>"}, {type: "vec", query: "<question>"}]
   intent: "<question>"
   minScore: 0.4
   ```

2. Also check if a `meetings` or `sources` collection is registered. If the question is
   about specific events, decisions, or people, run an additional query against those
   collections and merge the results.

3. Retrieve the top-scoring pages:
   ```
   mcp__plugin_qmd_qmd__get
   path: "<result filepath>"
   ```

4. Read the returned pages fully. Proceed to Step 4.

### Path B — Index-guided reading (Copilot, or qmd not configured)

1. Read `wiki/_index.md` fully.
2. Scan the index summary column for entries relevant to the question.
3. Read up to 5 most relevant pages. Prioritise by: direct title match, then tag match,
   then summary match.
4. If 5 pages are not enough to answer confidently, read up to 3 more. Do not read the
   entire wiki.

---

## Step 4 — Synthesise the answer

Write the answer in declarative present tense. Cite every claim:

- For wiki pages: `(→ [[concepts/MCP Server]])`
- For original source files: `(→ [[Meetings/MGD/2026-04-10 MCP Planning.md]])`
- For multiple sources: list all

If the wiki contains contradicting information on the question: surface both sides and
note the conflict. Do not silently pick one.

If the wiki does not contain enough information to answer: say so explicitly.
Do not fabricate or extrapolate beyond what is in the wiki.

---

## Step 5 — Offer to save

If the answer is substantive (involves synthesis across multiple pages, or produced a
non-obvious conclusion), offer:

```
This answer synthesises content from N wiki pages. Save it as a new wiki page?
Suggested type: decisions/ | concepts/ | patterns/
Suggested title: "<derived from question>"
[yes / no]
```

If the user says yes, follow the `wiki-save` skill workflow.

---

## qmd Setup Note

For enhanced semantic search, register the wiki collection once:

```bash
qmd collection add wiki --name wiki
qmd collection add Meetings --name meetings
qmd embed
```

The skill auto-detects whether the `wiki` collection is registered on each query.
Without it, Path B (index-guided reading) is used — slower but always available.

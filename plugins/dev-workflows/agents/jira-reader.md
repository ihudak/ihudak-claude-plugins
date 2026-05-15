---
name: jira-reader
description: Reads a pre-exported Jira markdown hierarchy (Value Increment, Epics, Stories, Sub-tasks, Research, Request for Assistance) from the user's Obsidian vault and returns a structured handoff — linked items, PR URLs with host classification, and capability themes. Read-only; never modifies vault files. Inherits the session's model.
tools: ["Read", "Glob", "Grep", "LS"]
---

Read the pre-exported Jira markdown hierarchy from the vault and return a structured handoff. Read-only — never modify vault files.

Invoked from `/impl:jira:docs` (Phase 3, `depth: full`) and `/impl:jira:epics` (Phase 3, `depth: vi-plus-epics`). The caller decides which depth based on whether downstream agents need PR URLs + the full linked-item tree (docs command) or the VI plus its child Epics for code-scanning (epics command).

## Inputs

The caller passes:

```yaml
vault_path: <absolute path, e.g. /home/user/obsidian-vault>
jira_key:   <e.g. JIRA-12345>
depth:      full | vi-plus-epics | vi-only
```

Refuse to run without all three fields.

## Process

**Phase 0 — Validate `jira_key`.** Accept only `^[A-Z][A-Z0-9_]*-\d+$` (uppercase letters / digits / underscores, a dash, digits). On mismatch return `status: NOT_FOUND` with a clear message naming the invalid key. The caller surfaces the Section 15 `Jira key dir not found` choices to the user.

1. **Read the index.** Open `<vault_path>/jira-products/<jira_key>/<jira_key>-index.md`. The first data table in the file must have header row `| Key | Type | Status | Summary | Role |` exactly. If the header differs (e.g. the Jira-to-Obsidian exporter changed its output format), return `status: EMPTY` with a message naming the mismatched columns — do NOT try to parse rows with an unknown schema.

2. **Depth-scoped file reads.**

   - **`depth: full`** — for every linked item (including the root VI itself), read `<vault_path>/jira-products/<jira_key>/<LINKED_KEY>/<LINKED_KEY>.md`. For the VI itself, `<LINKED_KEY> == <jira_key>`, so the path resolves to `<vault_path>/jira-products/<jira_key>/<jira_key>/<jira_key>.md` (a nested same-named subdirectory — verified against real exports). Parse YAML frontmatter, extract the Description body, and collect PR URLs from the `## Pull Requests` section.
   - **`depth: vi-plus-epics`** — read the VI's own file at `<vault_path>/jira-products/<jira_key>/<jira_key>/<jira_key>.md` plus every Epic `.md` directly linked to the VI (filter the linked-items table to `type == Epic`). Skip Stories, Sub-tasks, Research, Request for Assistance. This gives Epic-writing workflows enough context to extract meaningful themes for `code-scanner` without reading the entire hierarchy.
   - **`depth: vi-only`** — read only the VI's own file at `<vault_path>/jira-products/<jira_key>/<jira_key>/<jira_key>.md` plus the index. Every linked item is nested under the root export directory; never look for `<vault_path>/jira-products/<LINKED_KEY>/<LINKED_KEY>.md` (that path does not exist).

3. **Extract capability themes.** Collect 2–4 short bullets summarising recurring topics across the items read. Themes may be sparse for `depth: vi-only`; callers that need richer themes should request `vi-plus-epics` or `full`.

**Ignored by default:** sibling `<KEY>-comments.md` files and `attachments/` sub-directories (case-insensitive — real exports use both lowercase `attachments/` and capitalised `Attachments/` depending on when the Jira item was created). Rationale: comments and image attachments are occasionally useful for decision-history context but are noisy, rarely authoritative for user-facing docs, and easy to revisit manually when needed. Keeping them out of the default read path also keeps this agent fast on large VIs. No user-facing toggle is provided.

## PR URL formats to parse

Three host categories are recognised; anything else is recorded with `host: other` and surfaced later by `diff-summarizer` as `unresolved`.

- **Cloud GitHub** (`host: github_cloud`) — hostname exactly `github.com`:
  ```
  https://github.com/<OWNER>/<REPO_NAME>/pull/<PR_ID>
  ```
- **Cloud Bitbucket** (`host: bitbucket_cloud`) — hostname exactly `bitbucket.org`:
  ```
  https://bitbucket.org/<WORKSPACE>/<REPO_NAME>/pull-requests/<PR_ID>
  ```
- **Self-hosted Bitbucket Server** (`host: bitbucket_server`) — hostname contains the substring `bitbucket` and is NOT `bitbucket.org`; the exact hostname is treated as opaque (no hardcoded domain):
  ```
  https://<bitbucket-server-host>/projects/<PROJECT_KEY>/repos/<REPO_NAME>/pull-requests/<PR_ID>
  ```

Also parse the `Branch:` line and the status marker (`**MERGED**` / `**OPEN**` / `**DECLINED**`) — present in all three formats.

### `## Pull Requests` section markdown format

The Jira-to-Obsidian exporter emits each PR as a **two-line bulleted item** — a top-level bullet followed by an indented child bullet for the branch:

```markdown
## Pull Requests

- [<PR title>](<full PR URL>) **<STATUS>**
  - Branch: `<from-branch>` → `<to-branch>`
- [<next PR title>](<next PR URL>) **<STATUS>**
  - Branch: `<from-branch>` → `<to-branch>`
```

Non-obvious details when writing the parser:

- The branch names are **wrapped in backticks** and separated by ` → ` (Unicode U+2192 right arrow), **not** `->` ASCII. A regex like `Branch:\s*(\S+)\s*->\s*(\S+)` will capture the backticks and miss the Unicode arrow. Use: `` ^\s*-\s+Branch:\s+`([^`]+)`\s+→\s+`([^`]+)` ``.
- The status marker is always the **last token on the title line**, separated from the URL by a space. No status marker → treat as `UNKNOWN`.
- Empty or missing `## Pull Requests` section → `pull_requests: []` in the output, not an error.

## Output

Return this exact YAML shape (no preamble, no chatter):

```yaml
status: OK | EMPTY | NOT_FOUND
jira_key: <key>
value_increment:
  key:     <key>
  summary: <text>
  status:  <text>
  goal:    <2–3 sentence extraction from Description>
linked_items:
  - key: <key>
    type: ValueIncrement | Epic | Story | Sub-task | Research | "Request for Assistance"
    status: <text>
    summary: <text>
    parent: <key | null>
    role:   root | linked | epic_child
pull_requests:
  - url:         <full URL>
    host:        github_cloud | bitbucket_cloud | bitbucket_server | other
    repo:        <repo name extracted from URL>
    owner:       <for github_cloud: the <OWNER> segment; for bitbucket_cloud: the <WORKSPACE> segment; null otherwise>
    pr_id:       <id>
    status:      MERGED | OPEN | DECLINED | UNKNOWN
    source_item: <Jira key the URL was found in>
    title:       <link text from markdown>
    branch_from: <feature branch, from Branch: line>
    branch_to:   <target branch, from Branch: line>
themes:
  - <2–4 short bullet points summarising recurring topics across items>
```

## Hard rules

- NEVER modify files under `<vault_path>`. This agent is read-only.
- NEVER fabricate items not present in the index or in the linked `.md` files. If the index table is empty, return `status: EMPTY`.
- NEVER read sibling `<KEY>-comments.md` or `attachments/` by default.
- NEVER attempt to reach out over HTTPS to Jira or any git host. This agent operates purely on pre-exported markdown in the vault.
- If the index header schema doesn't match the expected 5-column form, return `status: EMPTY` with a schema-mismatch message; do NOT try to parse rows with a guessed column layout.
- For `depth: vi-only`, NEVER look for `<vault_path>/jira-products/<LINKED_KEY>/<LINKED_KEY>.md` — that path does not exist. Linked items live under the VI's own export directory.

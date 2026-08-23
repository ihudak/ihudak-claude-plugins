# jira-reader Handoff Format

## Input

```yaml
# Form 1 — preferred (from the jira-input-resolution front-end): explicit export root.
jira_export_root: <absolute path to the ticket export dir, e.g. .../jira-products/PRODUCT-1234>
jira_key:         <e.g. JIRA-12345>
depth:            full | vi-plus-epics | vi-only

# Form 2 — legacy (/epics, /release-notes): vault path + key
# (export root is derived as <vault_path>/jira-products/<jira_key>).
vault_path: <absolute path, e.g. /home/user/obsidian-vault>
jira_key:   <e.g. JIRA-12345>
depth:      full | vi-plus-epics | vi-only

model_routing:
  classification: SIGNIFICANT | MODERATE
  reason: <from orchestrator>
  current_model: <model name>
  planning_model: <model name>
  review_model: n/a
  implementation_model: <model name>
  opus_available: true | false
  gate_tests_on_review: false
```

Refuse to run without `depth`, `jira_key`, and at least one of
`{jira_export_root, vault_path}`.

## Output

```yaml
status: OK | EMPTY | NOT_FOUND
jira_key: <key>

value_increment:
  key:     <key>
  summary: <text from frontmatter>
  status:  <text from frontmatter>
  goal:    <2–3 sentence extraction from the Description / Goal section>
  change_type:            <verbatim from frontmatter `change_type:` when present; null otherwise — one of Breaking change | New technology support | Bug fix | not applicable>
  release_notes_category: <verbatim from frontmatter `release_notes_category:` when present; null otherwise>

requirements_source: native | derived
requirements:
  - id:   <US#N | AC#N | SM#N | SMC#N | FR#N | UC#N | R1..>   # native VI id (always emitted in
          # `#` form, even when the source VI used the legacy dash form), else synthetic
    type: story | criterion | metric | functional | usecase | derived
    text: <requirement text>

linked_items:
  - key:        <key>
    type:       ValueIncrement | Epic | Story | Sub-task | Research | "Request for Assistance"
    status:     <text>
    summary:    <text>
    parent:     <key | null>
    role:       root | linked | epic_child
    # Epic-only, populated ONLY at depth: vi-plus-epics (absent at other depths):
    refinement_candidate: true | false   # true = empty/almost-empty shell (no real Scope/Description/AC beyond summary + importer boilerplate)
    team:       <verbatim, e.g. "[DTT] Team Storage"; "" if absent>
    scope_hint: <the Epic's description/scope free-text if present, else its summary>

pull_requests:
  - url:          <full URL>
    host:         github_cloud | bitbucket_cloud | bitbucket_server | other
    owner:        <for github_cloud: the <OWNER> segment; for bitbucket_cloud: the <WORKSPACE> segment; null otherwise>
    repo:         <repo name slug from URL>
    pr_id:        <numeric id as string>
    status:       MERGED | OPEN | DECLINED | UNKNOWN
    title:        <link text from markdown>
    source_item:  <Jira key of the file where the URL was found>
    branch_from:  <feature branch, from Branch: line>
    branch_to:    <target branch, from Branch: line>

themes:
  - <short phrase, 5–10 words, summarising a recurring capability topic>
  # 2–4 items

attachments:            # image files found under the VI's attachments/ dirs (paths only, not read)
  - path:   <absolute path to the image file>
    item:   <the Jira key whose folder it was found under>
  # empty list when no attachments/ directories exist or no image files are present

notes: |
  <optional: any parse warnings, skipped items, etc.>
```

## Status codes

| Status     | Meaning                                                                 |
|------------|-------------------------------------------------------------------------|
| `OK`       | Successfully read; `linked_items` and `pull_requests` populated.        |
| `EMPTY`    | Directory found but index file is missing or empty.                     |
| `NOT_FOUND`| The resolved export root does not exist — `<vault_path>/jira-products/<jira_key>/` (Form 2), or the caller-supplied `jira_export_root` (Form 1). |

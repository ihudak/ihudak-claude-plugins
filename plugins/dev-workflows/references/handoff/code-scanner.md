# code-scanner Handoff Format

## Input

```yaml
repo_path: <absolute, e.g. /workspace/<repo-name>>
repo_url_slug: <repo slug from source URL; optional, enables upstream cross-check>
capability_themes:
  - <short phrase>
context: |
  <3–5 sentences>
search_hints:
  symbols:  [<optional>]
  paths:    [<optional directory globs>]
  keywords: [<optional>]
refresh:
  switch_to_default_branch: true
  pull: true
model_routing:
  classification: MODERATE
  reason: <from orchestrator>
  current_model: <model name>
  planning_model: <model name>
  review_model: n/a
  implementation_model: <model name>
  opus_available: true | false
  gate_tests_on_review: false
```

## Output

```yaml
status: OK | PARTIAL | REPO_MISSING | DIRTY_TREE | REFRESH_BLOCKED | EMPTY

repo:       <repo name (last segment of repo_path)>
repo_path:  <absolute path>

prep:
  branch_at_scan: <branch name | "unknown">
  refreshed:      true | false
  refresh_note:   <e.g. "switched to main, pulled 12 commits" | "skipped per user" | "tree was dirty">

capability_map:
  - theme:          <theme text>
    classification: present | partial | absent | error
    evidence:
      - path:    <file path relative to repo root>
        symbols: [<class/function names found>]
        note:    <one-line characterisation of what this file provides>
    gap_summary: |
      <required when classification is partial or absent>
      <2–4 sentences: what is missing or needs to be implemented>
    error: <only when classification == error — one-line reason>

reusable_components: |
  <1–2 paragraphs: what existing code the new Epic can build on>

gap_summary: |
  <1–2 paragraphs: what needs to be implemented from scratch>
```

## Status codes

| Status            | Meaning                                                                        |
|-------------------|--------------------------------------------------------------------------------|
| `OK`              | Every theme was scanned and classified (including `absent`, a legitimate scan result, not a failure). |
| `PARTIAL`         | Scan completed but at least one theme has `classification: error`. Failing themes do NOT abort the scan; mirrors `diff-summarizer`'s `PARTIAL` status. |
| `REPO_MISSING`    | `repo_path` does not exist.                                                    |
| `DIRTY_TREE`      | Working tree is dirty and refresh was requested; orchestrator must escalate.   |
| `REFRESH_BLOCKED` | `git checkout` or `git pull` failed (RO mount, network, etc.); orchestrator escalates. |
| `EMPTY`           | Repo exists but every theme classified as absent and no relevant files found. Emit instead of `OK` when `capability_map` would contain only `absent` entries. |

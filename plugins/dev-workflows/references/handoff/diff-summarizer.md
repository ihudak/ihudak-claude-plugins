# diff-summarizer Handoff Format

## Input

```yaml
repo_path: /repos/<repo-name>
pr_refs:
  - url:         <full PR URL — used as identifier only, never fetched>
    pr_id:       <numeric id as string>
    issue_keys:  [<jira key(s) from link title>]
    title_hint:  <link text from markdown>
    status:      MERGED | OPEN | DECLINED | UNKNOWN
context: |
  <2–4 sentences: Jira context>
refresh:
  fetch: true
  pull:  false
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

## Output

```yaml
status: OK | REPO_MISSING | DIRTY_TREE | REFRESH_BLOCKED | NO_PRS_RESOLVED | PARTIAL

repo:       <repo name (last segment of repo_path)>
repo_path:  <absolute path>

prep:
  fetched:       true | false
  pulled:        true | false
  refresh_note:  <e.g. "fetched 3 new refs" | "skipped — RO mount" | "tree was dirty, refresh skipped">

per_pr:
  - pr_id:          <id>
    url:            <url>
    resolved_via:   pr_ref | branch_search | merge_commit | issue_grep | unresolved
    base:           <sha | null>
    head:           <sha | null>
    files_changed:  <count>
    insertions:     <count>
    deletions:      <count>
    diff_truncated: false
    summary: |
      <prose; 3–8 sentences>

unresolved_prs:
  - pr_id:      <id>
    url:        <url>
    candidates: [<"<sha> <first line of commit message>", ...>]   # from Strategy 4 if any; else []
    reason:     <e.g. "no PR ref; branch not found; multiple merge candidates">

aggregate_summary: |
  <1–2 paragraphs: what this repo contributed to the feature>
```

## Status codes

| Status              | Meaning                                                                        |
|---------------------|--------------------------------------------------------------------------------|
| `OK`                | All PRs resolved; summaries complete.                                          |
| `REPO_MISSING`      | `repo_path` does not exist or is not a git repo.                              |
| `DIRTY_TREE`        | Working tree is dirty and refresh was requested; orchestrator must escalate.   |
| `REFRESH_BLOCKED`   | `git fetch` or `git pull` failed (auth, network, RO mount); orchestrator escalates. |
| `NO_PRS_RESOLVED`   | None of the provided PRs could be resolved; `unresolved_prs` lists all of them.|
| `PARTIAL`           | Some PRs resolved, some unresolved; both `per_pr` and `unresolved_prs` populated. |

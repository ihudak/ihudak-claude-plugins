# diff-summarizer Handoff Format

## Input

```yaml
repo_path:   <absolute path to a local clone, e.g. /workspace/<repo-name>>
repo_url_slug: <repo slug from the PR URL, e.g. "cluster"; optional, enables upstream cross-check>
pr_refs:
  - url:         <full PR URL>
    host:        github_cloud | bitbucket_cloud | bitbucket_server | other
    repo:        <repo name>
    owner:       <github_cloud: <OWNER>; bitbucket_cloud: <WORKSPACE>; null otherwise>
    pr_id:       <id>
    branch_from: <feature branch from jira-reader>
    branch_to:   <target branch from jira-reader>
    title:       <link text>
    status:      MERGED | OPEN | DECLINED | UNKNOWN
context: |
  <what this repo's PRs relate to — for documentation focus>
jira_keys_hierarchy:   # optional; passed by caller to enable Strategy 4 cross-key grep
  - <PRD-KEY>
  - <every Epic/Story/Sub-task/Research/RFA/Bug key discovered by jira-reader>
refresh:
  fetch: true   # default true
  pull:  false  # default false — historical PR diffs do not need the current branch tip;
                # pulling risks moving HEAD away from the merge commit we want to reach.
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

Refuse to run without `repo_path` and at least one element in `pr_refs`.

When `repo_url_slug` is provided, before summarising run
`git -C <repo_path> remote get-url origin`, strip a trailing `.git`, and compare
the URL's last path segment to `repo_url_slug`. On mismatch, return
`status: REPO_MISSING` with a note naming both slugs — do NOT summarise the wrong
repository. When `repo_url_slug` is absent, trust `repo_path` as given.

## Output

```yaml
status: OK | REPO_MISSING | DIRTY_TREE | REFRESH_BLOCKED | NO_PRS_RESOLVED | PARTIAL

repo:       <repo name (last segment of repo_path)>
repo_path:  <absolute path>

prep:
  fetched:          true | false
  pulled:           true | false
  refresh_note:     <e.g. "fetched 3 new refs" | "read-only mount; resolved at origin/main" | "tree was dirty, refresh skipped">
  read_only:        true | false
  scanned_ref:      <ref name, e.g. "origin/main"; the default branch name when writable>
  ref_committed_at: <ISO-8601 timestamp of the ref's newest commit>
  head_divergence:  { branch: <working-tree branch>, ahead: <n>, behind: <n> }

per_pr:
  - pr_id:          <id>
    url:            <url>
    resolved_via:   pr_ref | branch_search | merge_commit | jira_key_commits | gh_cli | unresolved
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

`prep.read_only`, `prep.scanned_ref`, `prep.ref_committed_at`, and `prep.head_divergence` are always present, so a caller never branches on absence. See `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md`.

## Status codes

| Status              | Meaning                                                                        |
|---------------------|--------------------------------------------------------------------------------|
| `OK`                | All PRs resolved; summaries complete.                                          |
| `REPO_MISSING`      | `repo_path` does not exist or is not a git repo.                              |
| `DIRTY_TREE`        | Working tree is dirty and refresh was requested, on a **writable** mount; orchestrator must escalate. A read-only mount never returns this. |
| `REFRESH_BLOCKED`   | `git fetch` or `git pull` genuinely failed (auth, network, non-fast-forward); orchestrator escalates. A read-only mount is NOT a cause — resolution proceeds at `prep.scanned_ref` with `prep.read_only: true`. |
| `NO_PRS_RESOLVED`   | None of the provided PRs could be resolved; `unresolved_prs` lists all of them.|
| `PARTIAL`           | Some PRs resolved, some unresolved; both `per_pr` and `unresolved_prs` populated. |

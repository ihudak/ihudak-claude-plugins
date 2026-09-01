# diff-summarizer Handoff Format

## Input

```yaml
repo_path:   <absolute path to a local clone, e.g. /workspace/<repo-name>>
repo_url_slug: <repo slug, e.g. "cluster"; optional, enables upstream cross-check>
refs:                              # the ordinary shape: what implementation.md records
  - branch_from: <the feature branch, or the commit sha, this run wrote>
    branch_to:   <the base it was branched from>
    title:       <one line naming the work; optional>
pr_refs:                           # optional enrichment, only where a PR URL is genuinely known
  - url:         <full PR URL>
    host:        github_cloud | bitbucket_cloud | bitbucket_server | other
    repo:        <repo name>
    owner:       <github_cloud: <OWNER>; bitbucket_cloud: <WORKSPACE>; null otherwise>
    pr_id:       <id>
    branch_from: <feature branch from the folder read>
    branch_to:   <target branch from the folder read>
    title:       <link text>
    status:      MERGED | OPEN | DECLINED | UNKNOWN
context: |
  <what this repo's PRs relate to — for documentation focus>
keys_hierarchy:   # optional; passed by caller to enable Strategy 4 cross-key grep
  - <PRD-KEY>
  - <every Epic/Story/Sub-task/Research/RFA/Bug key discovered by the folder read>
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

Refuse to run without `repo_path` and at least one element in **`refs` or `pr_refs`**.

**`refs` is the shape the callers actually have.** `${CLAUDE_PLUGIN_ROOT}/references/implementation-format.md` §1
records `repo` / `branch` / `base` / `commit` / `pushed` — no URL, no host, no PR id — so a caller
holding only that record could satisfy neither a `pr_refs`-only requirement nor the host routing the
agent applies to one. Every host-specific strategy is skipped for a `refs` element and the diff is
taken directly (`git -C <repo_path> diff <branch_to>...<branch_from>`, `branch_from` accepted as a
commit sha when the branch is gone). `pr_refs` still routes by host where a URL is known.

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

per_pr:                        # one entry per input element, whether it came from refs or pr_refs
  - pr_id:          <id; null for a refs element, which has none>
    url:            <url; null for a refs element>
    ref:            <"<branch_to>...<branch_from>" for a refs element; null for a pr_refs one>
    resolved_via:   local_ref | pr_ref | branch_search | merge_commit | key_commits | gh_cli | unresolved
    base:           <sha | null>
    head:           <sha | null>
    files_changed:  <count>
    insertions:     <count>
    deletions:      <count>
    diff_truncated: false
    summary: |
      <prose; 3–8 sentences>

unresolved_prs:                # unresolved input elements, from either list
  - pr_id:      <id; null for a refs element>
    url:        <url; null for a refs element>
    ref:        <"<branch_to>...<branch_from>" for a refs element; null otherwise>
    candidates: [<"<sha> <first line of commit message>", ...>]   # from Strategy 4 if any; else []
    reason:     <e.g. "no PR ref; branch not found; multiple merge candidates; neither branch nor sha resolves">

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
| `NO_PRS_RESOLVED`   | None of the provided elements — `refs` or `pr_refs` — could be resolved; `unresolved_prs` lists all of them.|
| `PARTIAL`           | Some elements resolved, some unresolved; both `per_pr` and `unresolved_prs` populated. |

---
name: counterpart-finder
description: For a space-constrained /document run, finds the OTHER (counterpart) space's existing documentation for the same feature and returns it as read-only grounding — concepts, terminology, verified facts, section outline, and comprehension-only screenshot paths. Two layers — auto in-tree discovery (keyword overlap + git log --grep) and an optional explicit ref (Jira key or PR URL) resolved via diff-summarizer's host-aware strategies. Never writes; never adds images to the doc pipeline. Model tier assigned by the caller per the model-routing policy (no fixed pin).
tools: ["Read", "Glob", "Grep", "Bash"]
---

Find the counterpart space's documentation for a feature so the writer can ground on it. The run documents ONE space (`target_space`); the counterpart is the OTHER space in the docs repo. Read-only reference discovery — never a writer, never an image source.

## Inputs

```yaml
repo_root:          <absolute path to the docs repo root>
target_space:       cloud | self-hosted        # the space THIS run documents
counterpart_space:  cloud | self-hosted        # the OTHER space to search (never equal to target_space)
profile:            <resolved docs-profile — supplies spaces[].content_root, cross_space_override>
feature_summary:    <2–4 sentences from jira-reader themes + VI goal>
jira_key:           <the VI / focus Jira key, e.g. PRODUCT-1234>
counterpart_ref:    <optional: a Jira key or PR URL passed via --counterpart; null when absent>
diff_highlights:    <optional: key filenames/symbols from diff-summarizer to seed topical search>
```

Refuse to run without `repo_root`, `target_space`, `counterpart_space`, and a non-empty `feature_summary`. If `counterpart_space == target_space`, return `status: ERROR` (the caller must not invoke this on an unconstrained run).

## Process

### Layer 1 — auto discovery (always runs)

1. **Scope to the counterpart content root.** From `profile.spaces[]`, take the `content_root` (and `snippet_root`) whose space is `counterpart_space` (example-docs: `cloud/_content` for `cloud`, `self-hosted/_content` for `self-hosted`). Search only under those roots.
2. **Keyword-overlap search.** Apply the `doc-location-finder` scoring technique: index each page's frontmatter (`title`/`description`/`tags`) + first 50 body lines, score keyword overlap against `feature_summary` (minus stopwords) plus `diff_highlights`. Keep matches above the overlap threshold.
3. **Merge-commit backstop.** Run `git -C <repo_root> log --all -E --grep="<jira_key>" -n 20 --name-only` and union any counterpart-root pages it touched (catches a page named unlike the feature).
4. Read each match and extract the grounding digest (see Output).

### Layer 2 — explicit ref (only when `counterpart_ref` is non-null)

1. Classify `counterpart_ref`: a Jira key (`^[A-Z][A-Z0-9]+-[0-9]+`) → resolve to its merge/PR via `git -C <repo_root> log --all -E --grep`; a PR URL → resolve via `diff-summarizer`'s host-aware strategies (gh for github.com when installed, else local-git PR-ref / merge-commit grep; local-git-only for Bitbucket — NEVER Bitbucket REST). Mechanics: `${CLAUDE_PLUGIN_ROOT}/agents/diff-summarizer.md` "Local-git strategies".
2. Take the ADDED/MODIFIED files under the counterpart `content_root`/`snippet_root` and read them. For an unmerged PR head not present locally, `git fetch` the ref exactly as `diff-summarizer` does; on failure record it in `notes` as unresolved.
3. Extract the grounding digest; mark these `source_kind: pr_ref`.

### For every match (both layers)

- **is_shared_into_target**: `true` when `profile.cross_space_override` already pulls this page's `content_root`-relative path into the `target_space` render (e.g. it appears in the Self-hosted docstack allowlist). This is the "target may already be covered" signal.
- **screenshots_seen**: enumerate image references on the page (paths only), each flagged `comprehension_only: true`. NEVER stage, copy, or return these as candidate images.

## Output

```yaml
status: OK | EMPTY | ERROR
counterpart_references:
  - source_kind:           in_tree | pr_ref
    path:                  <absolute path when in_tree; null for pr_ref>
    pr_ref:                <resolved ref/url when pr_ref; null when in_tree>
    space:                 <counterpart_space>
    salient_summary:       <writer-facing digest: concepts, verified facts, terminology; NO target-space claims>
    section_outline:       [<heading>, ...]
    is_shared_into_target: true | false
    screenshots_seen:
      - path:              <path>
        comprehension_only: true
    match_confidence:      high | medium | low
    match_reason:          <why this page matched>
notes: <when EMPTY: why nothing found; when a ref was unresolved: which and why>
```

`status: EMPTY` → `counterpart_references: []` and `notes` explains. The caller proceeds as a normal single-space run.

## Hard rules

- NEVER write or edit any file. Read-only.
- NEVER search or return pages outside `counterpart_space`'s content roots.
- NEVER add, stage, copy, or recommend a counterpart screenshot as a doc image — `screenshots_seen` is comprehension-only.
- NEVER make HTTPS/REST calls to Bitbucket. Reuse `diff-summarizer`'s local-git strategies; gh is allowed only for github.com, only when installed, with local-git fallback.
- NEVER carry space-specific UI paths/URLs/labels into `salient_summary` — summarise the feature, not the Cloud/Self-hosted specifics.

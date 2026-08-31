# release-notes-writer Handoff Format

## Input

```yaml
jira_reader_handoff: <full YAML from the folder read; see ${CLAUDE_PLUGIN_ROOT}/references/handoff/the folder read.md output schema>
diff_summaries:      <optional array of diff-summarizer outputs; one entry per repo; omit when diff-grounding is off>
code_repos:          <optional array of {slug, path}; provided when diff-grounding is on — enables the writer's Source-truth check>
imported_change_type:            <change_type from the imported PRD frontmatter (the folder read handoff); null otherwise>
imported_release_notes_category: <release_notes_category from the imported PRD frontmatter; null otherwise — used verbatim as the {{#context}} label>
run_phase:                       <"pm" | "dev" — inferred by the command from whether specification.md / design.md exist under the PRD's specs dir; gates the release-note-types.md §4 documentation-link rule only>
model_routing:
  classification: MODERATE
  reason: <from orchestrator>
  current_model: <model name>
  planning_model: n/a
  review_model: n/a
  implementation_model: <model name>
  opus_available: true | false
  gate_tests_on_review: false
docs_grounding:      <optional docs-grounder digest (docs_references + docs_challenges); omit when docs grounding was OFF/EMPTY>
```

Refuse to run without `jira_reader_handoff`. Emit exactly one Summary per run.

## Output

```yaml
status: OK | PARTIAL

release_notes_block:
  target_format: example-docs-release-notes-v1
  change_type:  <one of: "Breaking change" | "New technology support" | "Bug fix">   # selects the destination + shape; NEVER rendered as text
  destination:  <one of: "breaking-changes.md" | "feature-updates.md" | "fixes.md">  # per release-note-types.md §1
  context_label: <the imported release_notes_category verbatim, e.g. "Platform | Settings"; null when the import carries none — the {{#context}} line is then omitted>
  feature_title: <5–10 word headline; sentence case; no leading "New feature:"; no trailing period. null for the fixes destination.>
  prose: |
    <shaped customer-facing body; no Jira IDs; no PR links; no release version. For the titled
    destinations: a 2–4 sentence paragraph, or a short intro sentence + a bulleted list when the
    feature enumerates discrete options. For the fixes destination: ONE self-contained past-tense
    sentence. See release-note-types.md §3 (shape) and §4 (prose rules).>
  combined_rendered: |
    <the exact text the PM pastes into the Jira release-notes field. For a titled destination:
    "{{#context}}<context_label>{{/context}}", a blank line, "### <feature_title>", a blank line,
    then <prose> — with the {{#context}} line omitted entirely when context_label is null. For the
    fixes destination: <prose> alone. NEVER a "Change type:" line, a "Release-notes category:" line,
    or a "--- Summary ---" divider.>

gaps:
  - field:              <feature_title | prose | change_type | deprecation_eol>
    reason:             <why this is low-confidence or missing. For change_type: the destination was inferred and the source supports two destinations roughly equally; the proposed value is still set on release_notes_block. For deprecation_eol: a deprecation was detected but the required end-of-life date is not derivable from the source.>
    recommended_action: "ask user" | "mark TODO in draft" | "note in report"
    jira_phrasing:      <only for source-truth discrepancies — the draft's current (Jira-derived) phrasing>
    source_phrasing:    <only for source-truth discrepancies — what the source code actually shows>
    source_location:    <only for source-truth discrepancies — file:line the source_phrasing was verified against>
```

`status: PARTIAL` when at least one gap has `recommended_action: "ask user"`.

## Status codes

| Status    | Meaning                                                              |
|-----------|---------------------------------------------------------------------|
| `OK`      | Draft rendered; the Summary has its prose and, when the import supplied one, its context label.|
| `PARTIAL` | Draft rendered but at least one gap needs the user (low-confidence destination, missing end-of-life date, or an unverifiable claim). |

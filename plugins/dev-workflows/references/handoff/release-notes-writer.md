# release-notes-writer Handoff Format

## Input

```yaml
jira_reader_handoff: <full YAML from jira-reader; see agents/jira-reader.md output schema>
diff_summaries:      <optional array of diff-summarizer outputs; one entry per repo; omit when diff-grounding is off>
release_versions:    [<parsed version strings, e.g. "Managed (344)", "SaaS (344)">]   # derived by the command from release_versions frontmatter; [] when none declared
context_label_hint:  <optional 1–2 short category labels the user suggested; null otherwise>
model_routing:
  classification: MODERATE
  reason: <from orchestrator>
  current_model: <model name>
  planning_model: n/a
  review_model: n/a
  implementation_model: <model name>
  opus_available: true | false
  gate_tests_on_review: false
```

Refuse to run without `jira_reader_handoff`. When `release_versions` is `[]`, emit a single undated entry and flag it in `gaps`.

## Output

```yaml
status: OK | PARTIAL

release_notes_block:
  target_format: dynatrace-docs-release-notes-v1
  entries:
    - release_version: <e.g. "Managed (344)" | "(unspecified)">
      context_label:   <e.g. "Platform" | "Platform | Settings">
      feature_title:   <5–10 word headline; sentence case; no leading "New feature:"; no trailing period>
      prose: |
        <2–4 sentence customer-facing paragraph; no Jira IDs; no PR links>
      rendered: |
        {{#context}}<context_label>{{/context}}

        ### <feature_title>

        <prose>
  combined_rendered: |
    <all entries' `rendered` blocks concatenated, separated by one blank line>

gaps:
  - field:              <context_label | feature_title | prose | release_version>
    reason:             <why this is low-confidence or missing>
    recommended_action: "ask user" | "mark TODO in draft"
```

`status: PARTIAL` when at least one gap has `recommended_action: "ask user"`.

## Status codes

| Status    | Meaning                                                              |
|-----------|---------------------------------------------------------------------|
| `OK`      | Draft rendered; every entry has a confident context label and prose.|
| `PARTIAL` | Draft rendered but at least one gap needs the user (low-confidence label, missing version, or unverifiable claim). |

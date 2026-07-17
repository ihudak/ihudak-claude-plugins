# release-notes-writer Handoff Format

## Input

```yaml
jira_reader_handoff: <full YAML from jira-reader; see ${CLAUDE_PLUGIN_ROOT}/references/handoff/jira-reader.md output schema>
diff_summaries:      <optional array of diff-summarizer outputs; one entry per repo; omit when diff-grounding is off>
code_repos:          <optional array of {slug, path}; provided when diff-grounding is on — enables the writer's Source-truth check>
release_versions:    [<parsed version strings, e.g. "Managed (344)", "SaaS (344)">]   # derived by the command from release_versions frontmatter; [] when none declared
context_label_hint:  <optional 1–2 short category labels the user suggested; null otherwise>
change_type_hint:    <optional; a user-supplied Change Type and/or deprecation signal
                      (e.g. "Breaking change", "new feature + deprecation"); null otherwise>
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
  change_type: <one of: "Breaking change" | "New technology support" | "Bug fix" | "not applicable">   # the note's Change Type (per note, not per release version); classified by the agent via references/release-note-types.md
  entries:
    - release_version: <e.g. "Managed (344)" | "(unspecified)">
      context_label:   <e.g. "Platform" | "Platform | Settings">
      feature_title:   <5–10 word headline; sentence case; no leading "New feature:"; no trailing period>
      prose: |
        <shaped customer-facing body; no Jira IDs; no PR links. Default: a 2–4
        sentence paragraph. When the feature enumerates discrete options, use a short
        intro sentence + a bulleted list (bold each option); lead with the
        recommended path and demote deprecated options to a trailing sentence or an
        optional `> Note:`. Bold UI/field names; inline `code` for filenames,
        identifiers, and flags. See the agent's Process step 5 for the full shaping
        rules (and references/release-note-types.md §3 for the per-type shaping).>
      rendered: |
        {{#context}}<context_label>{{/context}}

        ### <feature_title>

        <prose>
  combined_rendered: |
    <a leading "Change type: <release_notes_block.change_type>" line, then a
    "--- Summary (paste into release-notes field) ---" divider (a human copy guide, not
    pasted), then all entries' `rendered` blocks concatenated, separated by one blank
    line. The Change Type label appears ONLY on this leading line, never inside an
    entry's rendered Summary body.>

gaps:
  - field:              <context_label | feature_title | prose | release_version | change_type | deprecation_eol>
    reason:             <why this is low-confidence or missing. For change_type: the classification is low-confidence (source supports two types); the proposed value is still set on release_notes_block.change_type. For deprecation_eol: a deprecation was detected but the required end-of-life date is not derivable from the source (or a deprecation-signaling change_type_hint left the dates unclear).>
    recommended_action: "ask user" | "mark TODO in draft"
    jira_phrasing:      <only for source-truth discrepancies — the draft's current (Jira-derived) phrasing>
    source_phrasing:    <only for source-truth discrepancies — what the source code actually shows>
    source_location:    <only for source-truth discrepancies — file:line the source_phrasing was verified against>
```

`status: PARTIAL` when at least one gap has `recommended_action: "ask user"`.

## Status codes

| Status    | Meaning                                                              |
|-----------|---------------------------------------------------------------------|
| `OK`      | Draft rendered; every entry has a confident context label and prose.|
| `PARTIAL` | Draft rendered but at least one gap needs the user (low-confidence label, missing version, or unverifiable claim). |

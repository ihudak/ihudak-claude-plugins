---
name: dt-style-refresh
description: >
  Fetches the latest content from styleguide.dynatrace.com and updates the
  vendored reference docs in this plugin. Run when the Dynatrace style guide
  has been updated and you want the latest rules.
allowed-tools: Read WebFetch Bash Edit
---

# Refresh Dynatrace style guide references

Updates the vendored reference docs in this plugin from the Dynatrace style guide
website. Use when you suspect the style guide has changed and the local references
are stale.

## Procedure

### 1. Fetch all source pages

Fetch the following URLs and extract actionable rules:

| Reference file | Source URLs |
|---|---|
| `terminology.md` | `https://styleguide.dynatrace.com/docs/dynatrace-terminology`, `https://styleguide.dynatrace.com/docs/dynatrace-trademarks` |
| `word-list.md` | `https://styleguide.dynatrace.com/docs/word-list` |
| `voice-and-tone.md` | `https://styleguide.dynatrace.com/docs/style/voice-and-tone` |
| `grammar.md` | `https://styleguide.dynatrace.com/docs/style/grammar` |
| `formatting.md` | `https://styleguide.dynatrace.com/docs/style/numbers`, `https://styleguide.dynatrace.com/docs/style/punctuation`, `https://styleguide.dynatrace.com/docs/style/lists`, `https://styleguide.dynatrace.com/docs/style/titles-and-headings`, `https://styleguide.dynatrace.com/docs/style/acronyms`, `https://styleguide.dynatrace.com/docs/style/date-and-time`, `https://styleguide.dynatrace.com/docs/style/link-text`, `https://styleguide.dynatrace.com/docs/style/emoji` |
| `ui-interactions.md` | `https://styleguide.dynatrace.com/docs/style/ui-interactions` |
| `accessibility.md` | `https://styleguide.dynatrace.com/docs/accessibility-and-inclusivity/inclusive-language`, `https://styleguide.dynatrace.com/docs/accessibility-and-inclusivity/internationalization` |
| `top-10-tips.md` | `https://styleguide.dynatrace.com/docs/best-practices/top-10-tips`, `https://styleguide.dynatrace.com/docs/best-practices/write-for-answer-engine-optimization` |

### 2. Distil into reference format

For each reference file:
- Read the existing file to understand the current structure and categories.
- Compare with the freshly fetched content.
- Update rules, examples, and tables to reflect the latest source content.
- Preserve the document structure (headings, tables, rule identifier scheme).
- Do NOT copy-paste verbatim — distil into actionable rules with ✅/❌ examples.

### 3. Write updated files

Write updated reference docs to:
```
~/.claude/plugins/data/dt-style-guide@ihudak-claude-plugins/references/
```

### 4. Report changes

Summarise what changed in each file:
- New rules added
- Rules modified
- Rules removed
- Terminology additions/removals

If nothing changed, report that the references are already up to date.

## Notes

- This command only updates the vendored references used at runtime. The
  canonical source files in the plugin repo (`plugins/dt-style-guide/references/`)
  are not modified. To persist changes to the repo, copy the updated files manually.
- The website may be paginated or truncated — fetch with sufficient `max_length`
  and use pagination (`start_index`) if content is cut off.
- If the website is unreachable, report the error and leave existing references unchanged.

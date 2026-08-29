# dev-workflows — companion plugins & dependencies

dev-workflows is **self-contained**: no command hard-requires another plugin. There is **no
dependency-manifest field** in `.claude-plugin/plugin.json` (Claude Code plugins don't express one), so
every cross-plugin relationship is **convention + runtime-resolve + graceful fallback** — a missing
companion degrades the feature, never breaks the run.

## Recommended companions

| Companion | Used by | Relationship | Fallback when absent |
|-----------|---------|--------------|----------------------|
| `superpowers` (skill `brainstorming`) | `/prompt-brainstorm` | Recommended | Embedded technique; no hard dependency. |
| `prose-style` (in this marketplace) | `docs-style-checker`; planning-doc style checks | Optional companion | `docs-style-checker` falls back to it when no repo-configured prose linter exists; `/epics` and `/release-notes` skip the style gate entirely if it is absent. |

## Related external tooling (not a plugin)

| Tool | Role |
|------|------|
| [`jira-workitem-import`](https://github.com/ivan-gudak/jira-workitem-import) | Jira WorkItem Reporter — imports Jira tickets to `$VAULT_PATH/jira-products/` in the exact structure `jira-reader` (and every Jira-driven command) expects. The upstream producer of the pre-exported markdown tree the plugin consumes. |

## Marketplace siblings (independent plugins, same marketplace)

`prose-style` and `obsidian-llm-wiki` ship in the `ihudak-plugins` marketplace alongside
dev-workflows but are versioned independently.

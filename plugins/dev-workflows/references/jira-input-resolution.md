# Jira-input resolution (shared front-end)

Shared input-resolution mechanics for the Jira-driven commands `/implement`,
`/document`, `/epics`, `/specify`, and `/release-notes`. The command's Phase 0 **cites this
file and executes these steps inline** — the orchestrator owns every prompt. The
commands parse `$ARGUMENTS` identically and consume the normalized output
contract (§ Output contract); each then layers its own downstream work. `/epics`,
`/specify`, and `/release-notes` are **jira-driven only**: they consume
`{mode, source, jira_key, jira_export_root}`, ignore `specs` / `direct_prompt` /
`direct_files`, and **reject** `mode: direct` (they have no non-Jira behavior —
stop with a clear error).

## Input grammar

`$ARGUMENTS` is a whitespace-separated token list. Classify each token:

- **JiraID** — matches `^[A-Z][A-Z0-9]+-[0-9]+`.
- **Path** — a `@path` token, or a bare path that exists on disk (a directory; or,
  in direct mode, a file).
- **Command-specific trailing option** — consumed by the command *after* this
  resolution (`/document`: an optional `saas` | `managed` token). Not resolved here.
- **Free-text** — anything else (the direct-mode prompt).

## Mode decision

- **`jira-driven`** — at least one JiraID token, **or** at least one directory that
  inspects as a **jira-export** (contains `<KEY>-index.md`).
- **`direct`** — no Jira input: only free-text and/or a file token.

## Resolution

### jira-driven — JiraID token (requires `$VAULT_PATH`)

1. Resolve `$VAULT_PATH` (env). Unset/absent → **Fallback A**.
2. `jira_export_root` = `$VAULT_PATH/jira-products/<KEY>` — validate it exists and
   contains `<KEY>-index.md`. Missing → **Fallback B**.
3. `jira_key` = `<KEY>`; `source = vault`.
4. Resolve `specs` (§ Specs resolution).

### jira-driven — directory token (works *without* `$VAULT_PATH`)

Inspect-classify each path token **by content, not by name** (this is the same
classification `/implement` performs for `@dir`):

- **jira-export** — a directory containing `<KEY>-index.md` (or ticket-key
  subdirectories each containing `<KEY>.md`). `jira_export_root` = this directory;
  `jira_key` = `<KEY>` derived from the `<KEY>-index.md` basename / the nested
  `<KEY>/` subdirectory name; `source = directory`.
- **spec-folder** — a directory containing `prompt.md` and/or a `*-design.md`.
  Contributes to `specs`.
- **other** — surface to the user (never silently skip): ask whether to continue
  without it or stop.

Exactly one jira-export is expected; **≥ 2 → Fallback C**. Additional spec-folders
merge into `specs`. A JiraID **and** a spec-folder directory may be given together
(`PRODUCT-123 @/path/to/specs`): the JiraID fixes the hierarchy, the spec-folder
contributes/overrides `specs`.

### direct

Collect free-text prose into `direct_prompt` and any file tokens into
`direct_files`. No Jira/specs resolution.

## Specs resolution (jira-driven)

`SPECS_PATH` is an AI-Containers environment variable governed by the **same rules
as `VAULT_PATH`** — host-provided, mounted into the container (at
`/workspace/specs` in Ai-Containers; an arbitrary directory on a host). Resolve in
order:

1. **`$SPECS_PATH` set →** look for the ticket's specs at
   `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md` — a
   `specs`/`specifications`/`vis` root inside `$SPECS_PATH`, then a `<KEY>`-prefixed
   folder (tolerate `-`/`_` separators and a trailing slug) holding the `.md`
   specs/plans.
2. **Directory case →** a passed spec-folder, or specs found inside
   `jira_export_root`.
3. **None found →** `specs: []`. The **consuming command** applies its policy:
   `/implement` (jira-driven) prompts the user where the specs are
   (required-with-override); `/document` proceeds (additive).

## Fallback prompts (orchestrator-owned)

- **A — JiraID but no `$VAULT_PATH`:**
  `choices: ["Set VAULT_PATH (enter the path)", "Pass an imported-Jira directory instead", "Cancel"]`
- **B — JiraID-shaped but `jira-products/<KEY>` missing:**
  `choices: ["Re-enter the Jira key", "Treat the text as a direct edit instead", "Cancel"]`
- **C — multiple jira-export directories:** list them;
  `choices: ["<first> (Recommended)", "<other candidates…>", "Cancel"]`

## Output contract

The resolution yields one normalized shape; each command reads only the fields it
needs:

```
mode:             jira-driven | direct
source:           vault | directory | none
jira_key:         <KEY> | null
jira_export_root: <abs path to the ticket export dir> | null   # → jira-reader (jira_export_root input)
specs:            [<abs paths>]    # specs/plans; may be []
direct_prompt:    <free-text> | null
direct_files:     [<abs paths>]
```

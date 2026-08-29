# Jira-input resolution (shared front-end)

Shared input-resolution mechanics for the Jira-driven commands `/implement`,
`/document`, `/epics`, `/specify`, `/release-notes`, `/create-ard`, `/design`, and
`/ready`. (`/idea` uses only the `resolve-export-for-key` sub-procedure, not the
whole front-end.) The command's Phase 0 **cites this
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
  resolution (`/document`: an optional `cloud` | `self-hosted` token). Not resolved here.
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

**Note:** the VI-selector rule below (§ VI selector + optional focus Epic) refines step 2's existence
check for a single JiraID — one that is not a top-level `jira-products/` dir is not a Fallback-B miss
but triggers nested-Epic auto-resolve to its parent VI.

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

### VI selector + optional focus Epic (two-key grammar)

The first positional is a **VI selector** — either a **VI JiraID** (resolved under
`$VAULT_PATH/jira-products/<VI-Key>`, a bare key with **no slug**; requires `$VAULT_PATH`) or a
**jira-export directory** (content-classified as a jira-export; used directly as `jira_export_root`;
**no `$VAULT_PATH` needed**). An optional **focus Epic** (a JiraID) may follow either form.

- **Single VI JiraID** — classify against `jira-products/`: a **top-level dir** → a VI or stand-alone
  item (`jira_export_root = jira-products/<KEY>`, `source = vault`, `focus_key = null`); **not a
  top-level dir** → a **nested Epic**: auto-resolve its parent VI by scanning `jira-products/*/` for a
  child dir named `<KEY>` containing `<KEY>.md` (one parent → that VI is `jira_export_root`,
  `focus_key = <KEY>`; zero → Fallback D; ≥2 → Fallback E).
- **jira-export directory** — `jira_export_root` = the dir, `source = directory`, no `$VAULT_PATH`.
  This is what Fallback A already points users to.
- **Optional focus Epic** (second positional JiraID) — binds to whichever root resolved: validate
  `<root>/<Epic>/<Epic>.md` → `focus_key = <Epic>`; missing → Fallback D.

| Input | Root | `$VAULT_PATH`? | `focus_key` |
|---|---|---|---|
| `<VI-Key>` | `jira-products/<VI-Key>` | required | null |
| `<Epic-Key>` | parent VI (auto-resolved) | required | the Epic |
| `<VI-Key> <Epic-Key>` | `jira-products/<VI-Key>` | required | the Epic |
| `<dir>` | `<dir>` | not needed | null |
| `<dir> <Epic-Key>` | `<dir>` | not needed | the Epic |

Directory tokens stay **content-classified** (jira-export vs spec-folder), so `<dir> <Epic-Key>` never
collides with the existing `<VI-Key> @spec-folder` form (a spec-folder feeds `specs`, not the root).

### direct

Collect free-text prose into `direct_prompt` and any file tokens into
`direct_files`. No Jira/specs resolution.

## Specs resolution (jira-driven)

`SPECS_PATH` is an AI-Containers environment variable governed by the **same rules
as `VAULT_PATH`** — host-provided, mounted into the container (at
`/workspace/specs` in Ai-Containers; an arbitrary directory on a host). Resolve in
order:

1. **`$SPECS_PATH` set →** locate a `specs`/`specifications`/`vis` root inside
   `$SPECS_PATH`, then resolve by **matching folders on the Jira key-number**
   (tolerate `-`/`_` separators and a trailing slug):
   - **`focus_key` set →** prefer the nested per-Epic home: under the VI folder
     matching `jira_key` (`<VI>{-|_}<vslug>/`), the Epic folder matching `focus_key`
     (`<focus_key>{-|_}<eslug>/`), holding `specification.md`, `design.md`, and any
     other `.md`. If that nested Epic folder does not exist, **fall back** to the
     VI-flat resolution below (so nothing pre-foundation breaks).
   - **`focus_key` null →** the VI-flat resolution: a `<jira_key>`-prefixed folder
     (`<jira_key>{-|_}<slug>/…/*.md`) holding the `.md` specs/plans — for a
     stand-alone item, a broad VI-level slice, or a legacy pre-foundation layout.
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
- **D — Epic key given but not found** (single-key: no parent VI contains it; two-key/dir:
  `<root>/<Epic>/` missing): `choices: ["Re-enter the Epic key", "Pass <VI> <Epic> explicitly", "Cancel"]`
- **E — nested Epic key found under multiple VIs:** list the candidate VIs;
  `choices: ["<first> (Recommended)", "<other VIs…>", "Cancel"]`

## Output contract

The resolution yields one normalized shape; each command reads only the fields it
needs:

```
mode:             jira-driven | direct
source:           vault | directory | none
jira_key:         <KEY> | null
jira_export_root: <abs path to the ticket export dir> | null   # → jira-reader (jira_export_root input)
focus_key:        <EPIC key> | null    # Epic to center on within jira_export_root; null for a bare VI/stand-alone/dir
specs:            [<abs paths>]    # specs/plans; may be []
direct_prompt:    <free-text> | null
direct_files:     [<abs paths>]
```

## Entry point — `resolve-export-for-key <KEY>`

Locates the export for **one exact key**, at any depth. Distinct from the VI-selector
rule above, which deliberately resolves a nested Epic *up to its parent VI*; this one
never walks upward. Consumed by `/idea` (source typing), `idea-reader` (export
location for `rfe`/`vi` sources), and `vault-prior-art-finder` (status
resolution) — none of them wants a parent.

1. `candidates` = every `$VAULT_PATH/jira-products/**/<KEY>/<KEY>.md` (**any depth**
   — the export tree nests by hierarchy, so a key recurs under several roots).
2. **none** → `NOT_FOUND`.
3. **exactly one** → that file.
4. **several** → the **most recently modified**. Copies genuinely disagree: one
   `PRODUCT-1234` export reads `Post GA` and another `Release Preparation`, and
   `PRODUCT-1235` has three copies of which two still carry its pre-rewrite summary.
   Picking arbitrarily reports a stale identity.

Returns `{ path, issue_type, status, summary, export_date }`, read from the file's
frontmatter; `export_date` is the file's modification date.

**Additive.** No existing caller's behavior changes: the resolution steps, the
VI-selector rule, the fallback prompts, and the output contract above are untouched.

## Progress-aware Epic picker (opt-in per command)

For an **Epic-unit** command given a top-level key with `focus_key = null`, first determine the item's
type from a cheap `jira-reader depth: vi-plus-epics` read, then:

- **The item is itself an Epic** (stand-alone/top-level) → no picker; proceed for it directly.
- **VI with exactly 1 Epic** → no picker; auto-proceed for that Epic.
- **VI with ≥2 Epics** → render a status-aware picker. Status comes from the command's own output
  artifact (its **done-predicate**), one row per Epic:
  - **○ not started** — no artifact → selectable.
  - **◐ in progress** — a resume file exists but no final artifact → selectable as resume.
  - **● done** — artifact exists → shown greyed, not default-selectable; selecting offers revise.
  Default cursor = first actionable (in-progress before not-started). Include an explicit
  "Author one broad VI-level artifact instead" choice. After finishing one, offer
  "Next Epic? [picker] / Stop here". Resume stacks across sessions (VI picker + the command's own
  per-item resume file).
- **VI with 0 Epics** → the command's no-Epics policy (e.g. split with `/epics` first, or a broad
  VI-level artifact).

This pattern is **policy-neutral in the resolver** — it is invoked by Epic-unit commands only; VI-level
commands (`/epics`, `/document`, `/release-notes`) never use it and must keep working for un-split VIs.

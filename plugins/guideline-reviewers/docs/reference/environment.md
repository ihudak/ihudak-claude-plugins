# Environment reference

[Getting started](../getting-started.md) says what each variable is *for* and what to export before your first run. This page says what each variable **is** — its default, what happens when it is unset, what happens when it points somewhere the plugin cannot read, and the directory layout it expects underneath it. The plugin reads two user-settable variables. The rest of the names its own inventory check encounters while scanning for `$VAR` reads are never user-settable and stay out of scope here: `CLAUDE_PLUGIN_ROOT` and `ARGUMENTS` are runtime plumbing Claude Code itself sets for every plugin invocation.

## `$UI_GUIDELINES_PATH`

**What it is.** An absolute path to a directory of `.md` files carrying **your organization's own UI rules** — a proprietary design system's component contract, internal terminology, anything with no public equivalent. `/guideline-reviewer` layers it over the bundled vendor-neutral baseline in `references/guidelines/`.

**Default.** Unset. There is no default path.

**Unset, or pointing somewhere unreadable.** A silent, non-blocking fall-through: the reviewer resolves `--rules <path>` first, then `<repo-root>/.dev-workflows/ui-guidelines/`, then this variable, then the bundled baseline alone. A miss at every order is the normal case and is never reported as a problem — the run's `rules_source:` line records what actually resolved.

**Layout.** A flat directory of `.md` files. A file whose name matches a bundled one (`datatable.md`, `accessibility.md`, …) layers over it and wins on conflict; a file matching none is an additional rule source. An `## Allowed` section suppresses matching baseline rules. First hit wins across the orders above — two overlays are never merged.

## `$API_GUIDELINES_PATH`

**What it is.** The same mechanism for `/api-guideline-reviewer`: a directory of `.md` files carrying your own API rules — an internal scope grammar, a required header spelling, an error-envelope contract — layered over the bundled baseline in `references/api-guidelines/`.

**Default.** Unset. There is no default path.

**Unset, or pointing somewhere unreadable.** Silent fall-through, in the same order: `--rules <path>`, then `<repo-root>/.dev-workflows/api-guidelines/`, then this variable, then the bundled baseline.

**Layout.** As above. Note this variable governs the **prose** rules the LLM passes read. The **executable** half has its own precedence and does not use this variable: a repository's own `.spectral.yaml` / `.spectral.yml` / `.spectral.json` wins over the bundled Spectral ruleset, which an organization is expected to `extend` from its own file rather than edit in place.

## Directory layout

Both variables above name a flat directory of `.md` files, laid out identically to the bundled subtree it overlays:

```
$UI_GUIDELINES_PATH/    # overlay for references/guidelines/  — /guideline-reviewer
  <name>.md             # matches a bundled filename to override it; any other name is additive

$API_GUIDELINES_PATH/   # overlay for references/api-guidelines/ — /api-guideline-reviewer
  <name>.md             # matches a bundled filename to override it; any other name is additive
```

Neither variable names a file the plugin writes to — both are read-only inputs.

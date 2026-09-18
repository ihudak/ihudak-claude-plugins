# Environment reference

[Getting started](../getting-started.md) says what each variable is *for* and what to export before your first run. This page says what each variable **is** — its default, what happens when it is unset, what happens when it points somewhere the plugin cannot read, and the directory layout it expects underneath it. The plugin reads two user-settable variables. The rest of the names its own inventory check encounters while scanning for `$VAR` reads are never user-settable and stay out of scope here: `CLAUDE_PLUGIN_ROOT` and `ARGUMENTS` are runtime plumbing Claude Code itself sets for every plugin invocation.

## `$UI_GUIDELINES_PATH`

**What it is.** An absolute path to a directory of `.md` files carrying **your organization's own UI rules** — a proprietary design system's component contract, internal terminology, anything with no public equivalent. `/guideline-reviewer` layers it over the bundled vendor-neutral baseline in `references/guidelines/`.

**Default.** Unset. There is no default path.

**Unset, or pointing somewhere unreadable.** A silent, non-blocking fall-through: the reviewer resolves `--rules <path>` first, then `<repo-root>/.dev-workflows/ui-guidelines/`, then this variable, then the bundled baseline alone. A miss at every order is the normal case and is never reported as a problem — the run's `rules_source:` line records what actually resolved. `.dev-workflows/` is named for the plugin `/guideline-reviewer` originally shipped in, before this extraction; the directory name was deliberately left unchanged so an existing overlay a user already created keeps resolving without being moved.

**Set, readable, and holding no `.md` file.** Not the silent case. The reviewer falls through to the next order as before, but says so first, with a `rules_overlay_skipped:<path>` line naming the directory and what it looked for — because that directory is one somebody made, and an empty resolution there loses their rules rather than finding none. See **Directory layout** below for the shape that produces it.

**Layout.** A flat directory of `.md` files. A file whose name matches a bundled one (`datatable.md`, `accessibility.md`, …) layers over it and wins on conflict; a file matching none is an additional rule source. An `## Allowed` section suppresses matching baseline rules. First hit wins across the orders above — two overlays are never merged.

## `$API_GUIDELINES_PATH`

**What it is.** The same mechanism for `/api-guideline-reviewer`: a directory of `.md` files carrying your own API rules — an internal scope grammar, a required header spelling, an error-envelope contract — layered over the bundled baseline in `references/api-guidelines/`.

**Default.** Unset. There is no default path.

**Unset, or pointing somewhere unreadable.** Silent fall-through, in the same order: `--rules <path>`, then `<repo-root>/.dev-workflows/api-guidelines/`, then this variable, then the bundled baseline. As above, `.dev-workflows/` names the plugin `/api-guideline-reviewer` originally shipped in; it is left unchanged so an existing overlay keeps working unmoved.

**Set, readable, and holding no `.md` file.** As above — not silent: the run emits `rules_overlay_skipped:<path>` and falls through. This is the likelier of the two variables to reach it, because the subtree it overlays is nested and the overlay is not.

**Layout.** As above. Note this variable governs the **prose** rules the LLM passes read. The **executable** half has its own precedence and does not use this variable: a repository's own `.spectral.yaml` / `.spectral.yml` / `.spectral.json` wins over the bundled Spectral ruleset, which an organization is expected to `extend` from its own file rather than edit in place.

## Directory layout

Both variables above name a flat directory of `.md` files, whatever shape the bundled subtree it overlays has — a file is matched to a baseline file by **name alone**, never by path:

```
$UI_GUIDELINES_PATH/    # overlay for references/guidelines/  — /guideline-reviewer
  <name>.md             # matches a bundled filename to override it; any other name is additive

$API_GUIDELINES_PATH/   # overlay for references/api-guidelines/ — /api-guideline-reviewer
  <name>.md             # matches a bundled filename to override it; any other name is additive
```

**The two subtrees are not the same shape, and the overlay does not follow either.** `references/guidelines/` is flat — 11 `.md` files, no subdirectories. `references/api-guidelines/` is two levels deep: all 24 of its `.md` files sit under `permission-guidelines/` or `rest-api-guidelines/`, with `spectral/` and `template/` beside them. An `$API_GUIDELINES_PATH` overlay that mirrors that nesting has no `.md` file at its own top level, so it resolves to nothing — the reviewer falls through to the bundled baseline and says so, with the `rules_overlay_skipped:` line described per variable above. Put the files at the top level.

**A name that appears twice in the baseline matches twice.** `references/api-guidelines/` holds two files called `Introduction.md`, one under each of its subtrees. An overlay `Introduction.md` matches **both** — it layers over both, and a `<!-- api-guidelines: replace -->` marker replaces both. `references/guidelines/` repeats no name, so this cannot arise for `$UI_GUIDELINES_PATH`.

Neither variable names a file the plugin writes to — both are read-only inputs.

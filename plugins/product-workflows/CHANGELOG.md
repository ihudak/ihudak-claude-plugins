# Changelog

All notable changes to the **product-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.0.0] — 2026-09-06

### Added — the product-definition half of `dev-workflows`, extracted into its own plugin

Install it with `claude plugin install product-workflows@ihudak-plugins`. Updating the marketplace alone does **not** install it: `dev-workflows` does not declare it, because no `dev-workflows` run loads anything from it.

Twelve commands move here from `dev-workflows` 3.27.0, and each keeps its bare name once this plugin is installed — only the namespaced form changes, from `/dev-workflows:<command>` to `/product-workflows:<command>`:

- the idea → PRD → ARD → specification ladder: `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`
- the Epic breakdown: `/epics`
- the six-command BRD-to-PRD route: `/brd-intake`, `/brd-ground`, `/brd-split`, `/brd-interview`, `/brd-package`, `/brd-reconcile`

Twelve agents and nine reference files move with them. The partition is exact: no agent and no reference is shared with the commands that stayed, so every `${CLAUDE_PLUGIN_ROOT}` citation among the moved files points at a file that moved alongside it.

### Dependencies

Two, both declared, both host-resolved at install:

- **`workflows-core`** — the shared reference corpus every command here loads in its first phase. An unsatisfied dependency disables the plugin rather than letting it half-run, which is the intended behaviour: there is no degraded mode to fall back to.
- **`prose-style`** — `prose-style-checker` is `/epics`'s primary style checker, not a fallback. Declaring it removes the absent case entirely; the "skipped gracefully when not installed" branches that shipped while it was an optional companion are retired, because for `/epics` "skipped gracefully" meant no style check at all.

`dev-workflows` is **not** a dependency in either direction. This plugin's spine hands `specification.md` to `/dev-workflows:design`, but it installs and runs without it, against a specs tree someone else's engineering work will eventually fill in.

### Hooks

One `UserPromptSubmit` hook, which preloads `$SPECS_PATH` and `$REPOS_PATH` context for `/epics`. It matches both the bare and the plugin-qualified form; the family's three preload hooks accept only their own plugin's prefix and cover disjoint command sets, so no single prompt can match two.

# Getting started

Add the marketplace, then install this plugin:

```bash
claude plugin marketplace add ihudak/ihudak-claude-plugins
claude plugin install guideline-reviewers@ihudak-plugins
```

To pick up later changes:

```bash
claude plugin marketplace update ihudak-plugins
```

This plugin is standalone — it depends on no other plugin, consumes no workflow artifact, and produces none. It ships two commands, [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md) and [`/guideline-reviewer`](commands/guideline-reviewer.md); neither needs anything set up before its first run.

## What you can set on your machine

Both variables below are optional. Unset is the normal case for most readers — each degrades silently to the bundled baseline.

### `UI_GUIDELINES_PATH`

Your organization's own UI rules, as a directory of `.md` files. The bundled guidelines are a vendor-neutral baseline distilled from public standards (Apple HIG, Material Design 3, Fluent 2, WCAG 2.2, the ARIA APG); rules specific to your design system have no public equivalent and should not ship in a public plugin, so `/guideline-reviewer` layers this directory over the baseline instead. Unset is the normal case and degrades silently to the baseline alone.

### `API_GUIDELINES_PATH`

The same idea for `/api-guideline-reviewer` — your own scope grammar, header spellings, or error-envelope contract, layered over the bundled public-source baseline. This governs the *prose* rules; the executable half is separate, where your repo's own `.spectral.yaml` takes precedence over the bundled Spectral ruleset. Unset degrades silently.

See [Environment](reference/environment.md) for the exact resolution order and what an unreadable path does.

## Run it

```
/guideline-reviewers:api-guideline-reviewer specs/openapi.yaml
/guideline-reviewers:guideline-reviewer app/src/pages/SettingsPage.tsx
```

Both commands are standalone reviewers — neither reads nor writes `$SPECS_PATH`, opens a branch, or expects a prior workflow artifact; each prints its subagent's verdict directly. See the [documentation index](README.md) for everything else, including [Workflow overview](workflow.md).

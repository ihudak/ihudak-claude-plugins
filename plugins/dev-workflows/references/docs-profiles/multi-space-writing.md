# Multi-space writing (example-docs)

How `/document` Phase 6.3 writes documentation across more than one space
(Cloud + Self-hosted in example-docs) while honoring the `cloud`/`self-hosted`
constraint — i.e. changing one space's documentation **without altering the
other space's rendered output**.

This is the single source of truth for the mechanics. The command (Phase 5.9,
Phase 6.3) and `doc-planner` both cite it; neither inlines these rules.

All paths and rules below come from the resolved `profile` (the built-in
example-docs default, an in-repo `.dev-workflows/docs-profile.yml`, or a
generated one). Read them from the profile — do not hard-code example-docs
specifics.

## 1. Shared vs single pages

Each space has a `content_root` (and `snippet_root`) under `profile.spaces[]`.
A page's **home space** is the space whose `content_root`/`snippet_root` prefixes
its path.

A page is **shared** when its rendered output appears in more than one space.
In example-docs this happens through `profile.cross_space_override`: the
Self-hosted manifest (`cross_space_override.manifest`, e.g. `self-hosted/docstack.jsonc`)
pulls an allowlist of `cloud/_content/...` (Cloud) pages into the Self-hosted
render. So a page whose home space is `cloud` is typically **shared** (rendered
in both `cloud` and `self-hosted`), while a page under the Self-hosted `content_root`
(`self-hosted/_content/...`) is **single** (rendered only in `self-hosted`).

- `space_scope: shared` — rendered in `>1` space; `rendered_in` lists them.
- `space_scope: single` — rendered in exactly one space (its home space).

Whether a shared page needs protection depends on the run's `target_spaces`:
protection is required only when the page renders in a space that is **not** in
`target_spaces` (that space's render must stay unchanged), or when a
both-spaces run needs the two renders to **differ**.

## 2. The invariant — render-unchanged ≠ file-untouched

The `cloud`/`self-hosted` constraint protects the **rendered output** of the other
space, not the source file. It is correct and expected to **edit a shared
source file** as long as the constrained (protected) space's *render* does not
change. Adding an `{{#if project='self-hosted'}}…{{/if}}` block to a shared Cloud
page changes the file but renders nothing new for Cloud — that is the
small-diff path, not a violation.

## 3. Two protection strategies

### 3.1 Conditional (small / localized delta) — preferred for small diffs

Edit the **shared source page in place** and wrap the per-space delta in a
project conditional from `profile.tokens.project_conditionals`:

```handlebars
{{#if project='self-hosted'}}
…content that must render only for Self-hosted…
{{/if}}
```

The other space's render is unchanged because the wrapped content is excluded
for it. Use the project value of the space the delta is **for** (`target_space`).

### 3.2 Override-copy (significant / structural divergence)

When the two spaces must differ substantially (new sections, large rewrites,
structural changes), copy the page into the **destination space's**
`content_root` at the same relative path, then make the override win:

1. Copy `(<home content_root>)/<rel>` → `(<dest space content_root>)/<rel>`
   (same `<rel>` under each `content_root`). Edit the copy for the dest space.
2. Add the **shared source path** to the override manifest's `ignore` allowlist
   per `profile.cross_space_override.rule` — for example-docs: add the
   `../cloud/_content/<rel>` path to the `ignore` block in
   `self-hosted/docstack.jsonc` so the Self-hosted override wins and is not silently
   shadowed by the pulled-in Cloud page. The shadowing is last-write-wins by
   path: without that `ignore` entry the pulled-in Cloud page wins over the
   `self-hosted/_content` override, with no error and no build warning. The
   mechanism and this remedy are carried by the profile itself —
   `cross_space_override.mechanism` and `cross_space_override.rule` (see
   `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile.default.yml`,
   field definitions in `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md`)
   — read them from the resolved profile, which is authoritative for the repo in
   front of the run.

The home space's render is unchanged (its source is untouched); the dest
space now renders the override copy.

## 4. Choosing a strategy (the heuristic)

`doc-planner` recommends per shared target, from the divergence it already
estimates while building the checklist:

- **localized wording / a single added block / one differing value** → `conditional`.
- **structural change / new sections / large rewrite for one space** → `override-copy`.
- **no protection needed** (single-space page, or a both-spaces run whose
  content is identical for both) → `plain`.

The recommendation is **advisory**: the user approves or overrides it in
Phase 5.9 before any file is written.

## 5. Shared-registries lock-step

When a write **renames, retitles, or creates** a settings-schema page in the
condition described by `profile.shared_registries[].when` (for example-docs:
a page under `cloud/_content/api/settings/schemas/`),
update **every** file in that entry's `files` list together, per its `rule`
(for example-docs: update the `text:` entry in BOTH `schema-ids.yml` and
`schema-mappings.yml` in lock-step). The two registries must stay
byte-for-byte consistent on the shared field.

## 6. Token correctness

Before the style/review gates, validate the tokens the write emitted, per
`profile.tokens`:

- **Conditionals are balanced** — every `{{#if project='…'}}` has a matching
  `{{/if}}`.
- **Project values are valid** — the `project='…'` value is a known space/edition
  (`cloud`, `self-hosted`, `classic`, `latest`); flag anything else.
- **gen3/Classic tokens are well-formed** — `profile.tokens.latest_tag`
  (`{{tag kind='latest'}}`) and `profile.tokens.gen3_settings_breadcrumb`
  (`::app-settings::`) are spelled exactly and used in a space that supports them.

Flag malformed or space-inappropriate tokens for fixing **before** Phase 6.4
(style check) and Phase 7 (`doc-reviewer`).

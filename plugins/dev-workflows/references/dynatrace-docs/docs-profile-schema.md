# docs-profile schema

`/impl:docs:profile` writes this file to **`.dev-workflows/docs-profile.yml`** in
the target docs repo. `/impl:jira:docs` reads it. `changelog` and `owners` are
intentionally absent — they are owned by the `dynatrace-docs-frontmatter` skill.

```yaml
schema_version: 1
repo:
  name: dynatrace-docs                # detected from git remote / dir name
spaces:                               # one entry per rendered space
  - id: saas
    content_root: dynatrace/_content
    snippet_root: dynatrace/_snippets
    base_path: /docs
  - id: managed
    content_root: managed/_content
    snippet_root: managed/_snippets
    base_path: /managed
dev_servers:
  concurrent: false                   # cannot run two spaces at once
  servers:
    - space: saas
      command: "pnpm dynatrace:start"
      port: 4000
      base_path: /docs
    - space: managed
      command: "pnpm managed:start"
      port: 4001
      base_path: /managed
commands:
  lint: "pnpm dynatrace:lint"
  format: "pnpm prettier -w"
  commit_hook: "husky pre-commit -> lint-staged -> pnpm prettier -w"
cross_space_override:
  manifest: managed/docstack.jsonc
  mechanism: "the managed manifest pulls an allowlist of ../dynatrace/_content/... pages; last-write-wins by path silently shadows a managed/_content override"
  rule: "to make a managed/_content override win, add the shared dynatrace path to the allowlist block's `ignore`"
shared_registries:
  - files: [schema-ids.yml, schema-mappings.yml]
    when: "renaming/retitling/creating a settings-schema page under dynatrace/_content/dynatrace-api/environment-api/settings/schemas/"
    rule: "update the `text:` entry in BOTH files in lock-step"
tokens:
  latest_tag: "{{tag kind='latest'}}"          # gen3/Latest marker
  gen3_settings_breadcrumb: "::app-settings::"
  project_conditionals: "{{#if project='saas'}}…{{/if}} / project='managed' / project='classic'"
internal_links:
  convention: "[text](<postid>); postid comes from target frontmatter; verify it exists before linking"
branch_naming:
  pattern: "<initials>/<JIRA-KEY>-<short-slug>"
frontmatter:                          # pointers only — NOT a re-spec
  owned_by_skill: dynatrace-docs-frontmatter
  changelog_guidelines: references/dynatrace-docs/changelog-guidelines.md
  managed_owners: references/dynatrace-docs/managed-owners.txt
images:
  policy: "CDN-hosted; the user uploads to CDN and supplies links; docs reference the URLs; never commit binaries"
prerequisites:
  - "a dev server may need a working .docstack toolchain (e.g. an axios>=1.16 shim) before `*:start` boots"
```

## Field rules
- `spaces[]` is required and non-empty. A single-space repo has one entry and omits `cross_space_override`.
- `dev_servers.concurrent: false` means the consumer must start servers sequentially.
- `cross_space_override` and `shared_registries` are present only when detected (multi-space / docstack repos).
- `frontmatter.*` are pointers; never copy the rules here.

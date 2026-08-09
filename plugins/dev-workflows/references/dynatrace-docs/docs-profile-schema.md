# docs-profile schema

`/docs-profile` writes this file to **`.dev-workflows/docs-profile.yml`** in
the target docs repo. `/document` reads it. `changelog` and `owners` are
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
  readiness_timeout_seconds: 120      # optional; seconds to poll a booted server for readiness (default 120)
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
  per_space:                          # optional; keyed by space id from spaces[]
    saas:
      lint: "pnpm dynatrace:lint"
      build: "pnpm dynatrace:build"
      format: "pnpm dynatrace:format"
    managed:
      lint: "pnpm managed:lint"
      build: "pnpm managed:build"
      format: "pnpm managed:format"
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
commit_convention: "<JIRA-KEY> <summary>"     # Phase 8.5 squash commit message format
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
- `dev_servers.readiness_timeout_seconds` is optional (default 120) — how many seconds Phase 6.5 polls a booted server for readiness before falling back to the manual table.
- `commands.per_space` is optional — a map keyed by a space id from `spaces[]`, each entry carrying any of `lint`, `build`, `format`. A multi-space repo that lints or builds each space separately declares it here; consumers run the **lint** command for each space that owns a written file, and the **build** command for every space in the render verification set (`references/dynatrace-docs/render-verification.md` §2) — never scoped by which `content_root` the files sit under. Both fall back to the flat `commands.lint` / `commands.build` when the map is absent. A space id in `per_space` that is not in `spaces[]` is a profile error.
- `commands.build` (flat) and `commands.per_space.<space>.build` are both optional. When neither exists, the consumer treats the dev-server boot as the build proof. Declare a build command whenever the repo has one — an absent build command disables `/document`'s gating build check.
- `commit_convention` is optional — the squash commit-message format Phase 8.5 uses. When absent, the consumer infers it from recent `git log` / `CONTRIBUTING`, else falls back to `<JIRA_KEY> <summary>`.
- `cross_space_override` and `shared_registries` are present only when detected (multi-space / docstack repos).
- `frontmatter.*` are pointers; never copy the rules here.

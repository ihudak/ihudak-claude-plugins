# docs-profile schema

`/docs-profile` writes this file to **`.dev-workflows/docs-profile.yml`** in
the target docs repo. `/document` reads it. `changelog` and `owners` are
intentionally absent — they are owned by the `docs-frontmatter` skill.

```yaml
schema_version: 1
repo:
  name: example-docs                # detected from git remote / dir name
spaces:                               # one entry per rendered space
  - id: cloud
    content_root: cloud/_content
    snippet_root: cloud/_snippets
    base_path: /docs
  - id: self-hosted
    content_root: self-hosted/_content
    snippet_root: self-hosted/_snippets
    base_path: /self-hosted
dev_servers:
  concurrent: false                   # cannot run two spaces at once
  readiness_timeout_seconds: 120      # optional; seconds to poll a booted server for readiness (default 120)
  servers:
    - space: cloud
      command: "pnpm cloud:start"
      port: 4000
      base_path: /docs
    - space: self-hosted
      command: "pnpm self-hosted:start"
      port: 4001
      base_path: /self-hosted
commands:
  lint: "pnpm docs:lint"
  format: "pnpm prettier -w"
  commit_hook: "husky pre-commit -> lint-staged -> pnpm prettier -w"
  per_space:                          # optional; keyed by space id from spaces[]
    cloud:
      lint: "pnpm docs:lint"
      build: "pnpm cloud:build"
      format: "pnpm cloud:format"
    self-hosted:
      lint: "pnpm self-hosted:lint"
      build: "pnpm self-hosted:build"
      format: "pnpm self-hosted:format"
tokens:
  latest_tag: "{{tag kind='latest'}}"          # gen3/Latest marker
  gen3_settings_breadcrumb: "::app-settings::"
internal_links:
  convention: "[text](<postid>); postid comes from target frontmatter; verify it exists before linking"
announcement_pages:
  - postid: end-of-life
    path: cloud/_content/whats-new/technology/end-of-life-announcements.md
    kinds: [deprecation, end-of-life, shutdown, sunset]
  - postid: eos-announcements
    path: cloud/_content/whats-new/technology/end-of-support-news.md
    kinds: [end-of-support]
  - postid: new-technology-support
    path: cloud/_content/whats-new/technology/index.md
    kinds: [new-technology]
branch_naming:
  pattern: "<initials>/<JIRA-KEY>-<short-slug>"
commit_convention: "<JIRA-KEY> <summary>"     # Phase 8.5 squash commit message format
frontmatter:                          # pointers only — NOT a re-spec
  owned_by_skill: docs-frontmatter
  changelog_guidelines: references/docs-profiles/changelog-guidelines.md
  default_owners: references/docs-profiles/default-owners.txt
  owners_spaces: [self-hosted]     # space ids whose pages require an owners block
images:
  policy: "CDN-hosted; the user uploads to CDN and supplies links; docs reference the URLs; never commit binaries. A CDN URL is immutable. Every new or replacing screenshot is a new URL, and the docs edit is always a URL swap. An image is never refreshed in place."
prerequisites:
  - "a dev server may need a working .docstack toolchain (e.g. an axios>=1.16 shim) before `*:start` boots"
```

## Field rules
- `frontmatter.owners_spaces` lists the `spaces[].id` values whose pages require an owners block. Absent or empty means the owners check never fires. It is read by the `changelog-owners-reminder` hook and by the `docs-frontmatter` skill; neither hardcodes a content root, so a repo supplying its own profile gets its own roots and its own owners policy.
- `spaces[]` is required and non-empty. It is a plain list of the repo's content roots: a repo publishing one documentation set has one entry, a repo publishing several has one per set. A page belongs to whichever entry's `content_root`/`snippet_root` prefixes its path, and is written there and nowhere else.
- `dev_servers.concurrent: false` means the consumer must start servers sequentially.
- `dev_servers.readiness_timeout_seconds` is optional (default 120) — how many seconds Phase 6.5 polls a booted server for readiness before falling back to the manual table.
- `commands.per_space` is optional — a map keyed by a space id from `spaces[]`, each entry carrying any of `lint`, `build`, `format`. A repo that lints or builds each content root separately declares it here; consumers run the **lint** command for each space that owns a written file, and the **build** command for every space in the render verification set (`references/docs-profiles/render-verification.md` §2). Both fall back to the flat `commands.lint` / `commands.build` when the map is absent. A space id in `per_space` that is not in `spaces[]` is a profile error. A per-space entry carrying only some of `lint`/`build`/`format` is not specified — no shipped profile does it. A consumer meeting one should surface the gap rather than guess which fallback applies.
- `commands.build` (flat) and `commands.per_space.<space>.build` are both optional. When neither exists, the consumer treats the dev-server boot as the build proof. Declare a build command whenever the repo has one — an absent build command disables `/document`'s gating build check.
- `commit_convention` is optional — the squash commit-message format Phase 8.5 uses. When absent, the consumer infers it from recent `git log` / `CONTRIBUTING`, else falls back to `<JIRA_KEY> <summary>`.
- `announcement_pages` is optional — hand-authored destination pages that receive a given class of change regardless of where the feature itself is documented, typically inside a tree that is otherwise automation-owned. A repo without any omits the block. Each entry is `{postid, path, kinds}`; `kinds` is an open list of change kinds. `path` is authoritative when `path` and `postid` disagree; `postid` alone suffices when the repo's link convention is postid-based. A declared page is a **cross-cutting** destination: `doc-location-finder` proposes it whichever content root it sits under, even one no other target in the run touched.
- `frontmatter.*` are pointers; never copy the rules here.

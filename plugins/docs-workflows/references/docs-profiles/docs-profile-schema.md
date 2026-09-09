# docs-profile schema

`/docs-profile` writes this file to **`.dev-workflows/docs-profile.yml`** in
the target docs repo. `/document` reads it. `changelog` and `owners` are
intentionally absent — they are owned by the `docs-frontmatter` skill.

```yaml
schema_version: 1
repo:
  name: example-docs                # detected from git remote / dir name
generator: mkdocs-material            # informational; consumers still go through commands.*
spaces:                               # one entry per rendered space
  - id: cloud
    content_root: cloud/_content
    snippet_root: cloud/_snippets
    base_path: /docs
  - id: self-hosted
    content_root: self-hosted/_content
    snippet_root: self-hosted/_snippets
    base_path: /self-hosted
builds:                               # two builds from ONE content root
  - { id: public,   config: mkdocs.yml,          command: "mkdocs build --strict -f mkdocs.yml",          out: site,          visibility: public }
  - { id: internal, config: mkdocs.internal.yml, command: "mkdocs build --strict -f mkdocs.internal.yml", out: site-internal, visibility: internal }
dev_servers:
  concurrent: false                   # cannot run two spaces at once
  readiness_timeout_seconds: 120      # optional; seconds to poll a booted server for readiness (default 120)
  servers:
    - space: cloud
      command: "pnpm cloud:start"
      port: 4000
      base_path: /docs
      public_base_url: "http://localhost:4000"   # optional; the URL a consumer reports instead of guessing a container's published port
    - space: self-hosted
      command: "pnpm self-hosted:start"
      port: 4001
      base_path: /self-hosted
      public_base_url: "http://localhost:4001"
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
  latest_tag: "{{tag kind='latest'}}"          # a "latest version" marker
  settings_breadcrumb: "::app-settings::"
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
  pattern: "<initials>/<KEY>-<short-slug>"
commit_convention: "<KEY> <summary>"     # Phase 8.5 squash commit message format
frontmatter:                          # pointers only — NOT a re-spec
  owned_by_skill: docs-frontmatter
  changelog_guidelines: references/docs-profiles/changelog-guidelines.md
  default_owners: references/docs-profiles/default-owners.txt
  owners_spaces: [self-hosted]     # space ids whose pages require an owners block
images:
  policy: in-repo | object-store | cdn  # all three of D16's policies
  root: docs/assets                     # in-repo only
  max_bytes: 307200                     # in-repo only; the CI budget
  public_prefix: https://…/public/      # object-store and cdn; every public-build image URL must start here
  internal_prefix: https://…/internal/  # object-store only; what the third visibility gate asserts against
prerequisites:
  - "a dev server may need a working .docstack toolchain (e.g. an axios>=1.16 shim) before `*:start` boots"
```

## Field rules
- `frontmatter.owners_spaces` lists the `spaces[].id` values whose pages require an owners block. Absent or empty means the owners check never fires. It is read by the `changelog-owners-reminder` hook and by the `docs-frontmatter` skill; neither hardcodes a content root, so a repo supplying its own profile gets its own roots and its own owners policy.
- `spaces[]` is required and non-empty. It is a plain list of the repo's content roots: a repo publishing one documentation set has one entry, a repo publishing several has one per set. A page belongs to whichever entry's `content_root`/`snippet_root` prefixes its path, and is written there and nowhere else.
- `builds[]` is optional — a list of `{id, config, command, out, visibility}` entries for a repo whose ONE content root renders into more than one output. It is not a second `spaces[]` entry: `spaces[]` is defined by content-root ownership — a page belongs to whichever entry's `content_root` prefixes its path — so two spaces sharing one root breaks that rule. Two builds over one root is a different axis and needs its own field.
- `dev_servers.concurrent: false` means the consumer must start servers sequentially.
- `dev_servers.readiness_timeout_seconds` is optional (default 120) — how many seconds Phase 6.5 polls a booted server for readiness before falling back to the manual table.
- `dev_servers.servers[].public_base_url` is optional — the externally reachable URL for that server, distinct from `port`. A command running inside a container cannot infer the host's published port mapping, so a consumer reports this value instead of guessing; when it is absent, the consumer reports the in-container URL with an explicit caveat rather than a URL that may not open.
- `commands.per_space` is optional — a map keyed by a space id from `spaces[]`, each entry carrying any of `lint`, `build`, `format`. A repo that lints or builds each content root separately declares it here; consumers run the **lint** command for each space that owns a written file, and the **build** command for every space in the render verification set (`references/docs-profiles/render-verification.md` §2). Both fall back to the flat `commands.lint` / `commands.build` when the map is absent. A space id in `per_space` that is not in `spaces[]` is a profile error. A per-space entry carrying only some of `lint`/`build`/`format` is not specified — no shipped profile does it. A consumer meeting one should surface the gap rather than guess which fallback applies.
- `commands.build` (flat) and `commands.per_space.<space>.build` are both optional. When neither exists, the consumer treats the dev-server boot as the build proof. Declare a build command whenever the repo has one — an absent build command disables `/document`'s gating build check.
- `commit_convention` is optional — the squash commit-message format Phase 8.5 uses. When absent, the consumer infers it from recent `git log` / `CONTRIBUTING`, else falls back to `<KEY> <summary>`.
- `announcement_pages` is optional — hand-authored destination pages that receive a given class of change regardless of where the feature itself is documented, typically inside a tree that is otherwise automation-owned. A repo without any omits the block. Each entry is `{postid, path, kinds}`; `kinds` is an open list of change kinds. `path` is authoritative when `path` and `postid` disagree; `postid` alone suffices when the repo's link convention is postid-based. A declared page is a **cross-cutting** destination: `doc-location-finder` proposes it whichever content root it sits under, even one no other target in the run touched.
- `frontmatter.*` are pointers; never copy the rules here.
- `images.policy` is one of `in-repo` (scaffold default), `object-store`, or `cdn` (D16) — replacing the free-text sentence this field used to carry. Every rule the old sentence stated is preserved below, under the policy it describes:
  - `in-repo`: the file is committed under `images.root` (default `docs/assets`) and referenced by relative path. A replacement overwrites the same path — one path per slot, never a new filename beside the old one. `images.max_bytes` (default 307200, 300 KB) is the CI budget checked per image; SVG is preferred, then optimised PNG.
  - `object-store`: an S3-compatible bucket, with the same overwrite-in-place rule as `in-repo` (bucket versioning covers it), plus two obligations `in-repo` does not carry — an orphan sweep (deleting a page does not delete its objects, and an unreferenced object is invisible and paid for forever) and a third visibility gate: every image URL in the public build must resolve to `images.public_prefix`, with internal media under `images.internal_prefix`.
  - `cdn`: the human uploads to the CDN and supplies the URL; docs reference it and no binary is ever committed. A CDN URL is immutable, so an image is never refreshed in place — every new or replacing screenshot is a new URL under `images.public_prefix`, and the docs edit is always a URL swap.
- `images.root` and `images.max_bytes` apply to `in-repo` only; `images.public_prefix` applies to `object-store` and `cdn`; `images.internal_prefix` applies to `object-store` only — a consumer reading a field its policy does not use treats it as unset.

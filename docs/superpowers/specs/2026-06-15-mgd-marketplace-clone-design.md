# Clone `ihudak-claude-plugins` → `mgd-claude-plugins` (Dynatrace Managed internal)

**Date:** 2026-06-15
**Status:** Approved design (pending implementation)

## Goal

Populate the empty repository at `/Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins`
with a copy of the `ihudak-claude-plugins` Claude Code plugin marketplace, rebranded
from a personal/private marketplace ("Ivan Gudak", "ihudak") to a Dynatrace Managed
internal marketplace named after its repo (`mgd-claude-plugins`).

Scope is the **Claude marketplace only**. External repositories referenced by the
content (the AI-container environment, the sibling Copilot marketplace) are *not*
part of this migration and their references are left untouched.

## Source and target

| | Path | Remote |
|---|---|---|
| Source | `/Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins` | `git@github-ig.com:ihudak/ihudak-claude-plugins.git` |
| Target | `/Users/ivan.gudak/dev/dt-utils/mgd-claude-plugins` | `git@github.com:Dynatrace-Internal/mgd-claude-plugins.git` |

The target already exists as an empty repo containing only `.git`, with `origin`
already pointing at `Dynatrace-Internal/mgd-claude-plugins`.

## Decisions (confirmed with user)

1. **Author identity:** name → `Dynatrace Managed`; email **stays** `ivan.gudak@dynatrace.com`.
2. **Marketplace `name` field:** `mgd-plugins` (parallels the old `ihudak-plugins`).
3. **License:** replace MIT with an internal/proprietary notice.
4. **Historical docs** (`docs/superpowers/specs/`, CHANGELOGs): rewrite the migrated
   repo's branding inside them too.
5. **External repo references** (`ihudak/ai-containers`, `ihudak/ihudak-copilot-plugins`):
   left exactly as-is — they are separate repos, not being migrated.

## Copy mechanism

Copy **only git-tracked files** from source `HEAD` into the empty target:

```bash
git -C <source> archive HEAD | tar -x -C <target>
```

This automatically excludes everything gitignored/untracked — `.git/`,
`.ai-containers/`, `.agent-discovery/`, `.idea/`, `settings*.local.json`. The
target keeps its own `.git` and existing `origin`. No commit is made; the tree is
left staged for user review.

The source working tree was clean at session start, so `HEAD` reflects the current
content.

## Rename map

Replacements are applied **longest-match-first** so the `ihudak`-owner segment is
only rewritten inside the *migrated* repo's own URLs; external `ihudak/...` owners
are never touched.

### Repo / marketplace tokens

| From | To |
|---|---|
| `github.com/ihudak/ihudak-claude-plugins` | `github.com/Dynatrace-Internal/mgd-claude-plugins` |
| `git@github-ig.com:ihudak/ihudak-claude-plugins.git` | `git@github.com:Dynatrace-Internal/mgd-claude-plugins.git` |
| `ihudak-claude-plugins` (repo name + `@`-data-path token, ~110 hits) | `mgd-claude-plugins` |
| `ihudak-plugins` (marketplace `name`; install/reinstall commands) | `mgd-plugins` |

Note: `git@github-ig.com:...` is the SSH form of the same repo (`github-ig.com` is a
local SSH host alias for `github.com`); it is rewritten to plain `github.com` to
match the target's actual configured remote.

### Identity / branding

| From | To |
|---|---|
| `Ivan Gudak's private` (marketplace + README) | `Dynatrace Managed internal` |
| `A private Claude Code plugin marketplace` (CLAUDE.md) | `A Dynatrace Managed internal Claude Code plugin marketplace` |
| `Ivan Gudak` (author/owner names) | `Dynatrace Managed` |
| `Ivan's feedback` / standalone `Ivan` (specs) | `maintainer feedback` / `the maintainer` |
| `ivan.gudak@dynatrace.com` | **unchanged** |

### Left exactly as-is

- `ihudak/ai-containers` (external AI-container env repo)
- `ihudak/ihudak-copilot-plugins`, `ihudak-copilot-plugins` (external Copilot marketplace)
- All other `github.com` links: spring-boot, OpenAPITools, `api.github.com` examples,
  the Copilot co-author trailer in `vuln.md`
- Technical uses of the word "public" (public API, public functions, public tooling)

## LICENSE files

Four files — root `LICENSE` plus `plugins/{dev-workflows,dt-style-guide,obsidian-llm-wiki}/LICENSE`
— have their MIT text replaced entirely with:

```
Copyright (c) 2026 Dynatrace LLC

Dynatrace internal — all rights reserved.
This software is confidential and proprietary to Dynatrace.
Unauthorized copying, distribution, or use outside Dynatrace is prohibited.
```

The `"license"` field in the three `plugin.json` files changes `"MIT"` → `"UNLICENSED"`
(npm convention for proprietary).

## Affected files (inventory)

Branding tokens appear in, at minimum:

- `.claude-plugin/marketplace.json` — owner, per-plugin author, descriptions, homepages, marketplace name
- `README.md` — title, subtitle, install/update commands
- `CLAUDE.md` — marketplace description, registration name, data-path convention, reinstall command, Git remote section
- `LICENSE` (×4)
- `plugins/*/​.claude-plugin/plugin.json` (×3) — author, homepage, repository, license
- `plugins/dev-workflows/agents/*.md`, `commands/**/*.md`, `hooks/preload-context.sh`, `references/**` — `@ihudak-claude-plugins` data-path token (~100 hits)
- `plugins/dev-workflows/CHANGELOG.md` — monorepo provenance reference
- `docs/superpowers/specs/*.md` — historical narrative mentions

## Verification

After replacements, confirm:

1. **No stray migrated-repo tokens remain:**
   `grep -rI 'ihudak-claude-plugins\|ihudak-plugins\|Ivan Gudak\|github-ig' <target>` → empty.
2. **External references preserved:**
   `grep -rI 'ihudak/ai-containers\|ihudak-copilot-plugins' <target>` → still present, unchanged count vs source.
3. **JSON validity:** `marketplace.json` and all `plugin.json` parse (`python3 -m json.tool` / `jq`).
4. **Email preserved:** `ivan.gudak@dynatrace.com` still present everywhere it was.
5. **No collateral `github.com` damage:** spring-boot / OpenAPITools / `api.github.com` links unchanged.

## Risks / assumptions

- **`"UNLICENSED"`** is the npm convention for proprietary `license` fields. If the
  field should simply be dropped instead, adjust during implementation.
- The target's `origin` is assumed correct (plain `github.com`, no alias). If a push
  alias is later required, only CLAUDE.md's Git section needs updating.
- This is a one-time clone, not an ongoing sync. Future source changes are not
  tracked into the target.

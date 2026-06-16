# Design: Migrate `ihudak-claude-plugins` to the `/workspace` container layout

**Date:** 2026-06-16
**Status:** Approved (design); pending implementation plan
**Author:** session

## Background

The AI container that hosts this marketplace changed its mount layout. Previously
it exposed two dedicated mount points:

- `/repos` — code repositories, one clone per subdirectory
- `/obsidian` (and earlier `/docs`, `/specs`) — the Obsidian vault and docs

The container now mounts **everything under a single `/workspace` umbrella**:

- Each code repository at `/workspace/<repo-name>` (e.g. `/workspace/cluster`)
- The marketplace working directory at `/workspace/ihudak-claude-plugins`
- The Obsidian vault at `/workspace/obsidian`, with `VAULT_PATH=/workspace/obsidian`
  exported into the container environment
- `EXTRA_MOUNTS` and `REPOS` entries also land at `/workspace/<basename>` / `/workspace/<name>`

The repo's own `.ai-containers/` infrastructure is **already migrated** to this
layout (its README documents `REPOS` → `/workspace/<name>`, vault → `/workspace/obsidian`,
and the removal of the `/docs` and `/specs` mounts). Only the **plugin content**
still assumes the old layout.

The Copilot sibling marketplace (`/workspace/ihudak-copilot-plugins`) has already
received this fix (its `dev-workflows` 1.5.0). This spec ports that validated
design to the Claude marketplace, adapted to its command/agent architecture.

## Problem

Vault access already works — the Jira commands read `$VAULT_PATH`, which the
container exports as `/workspace/obsidian`. The broken part is **repo discovery**:
live plugin content still defaults to the now-empty `/repos` mount.

Affected live content (hardcoded `/repos` default or `REPOS_BASE`):

- `plugins/dev-workflows/commands/impl/jira/docs.md` — Phase-1 "Repos base path"
  detection (`[ -d /repos ]`, "Use /repos (Recommended)") and missing-repo escalation
- `plugins/dev-workflows/commands/impl/jira/epics.md` — same
- `plugins/dev-workflows/hooks/preload-context.sh` — `repos_base: ${REPOS_BASE:-/repos}`
- `plugins/dev-workflows/agents/diff-summarizer.md`, `agents/code-scanner.md` —
  `repo_path: /repos/<repo-name>` input example
- `plugins/dev-workflows/references/handoff/diff-summarizer.md`,
  `references/handoff/code-scanner.md` — same handoff-schema example
- `plugins/dev-workflows/README.md` — "Mounts `/repos`…"
- `plugins/dt-style-guide/commands/dt-review-pr.md`, `plugins/dt-style-guide/README.md` —
  `--repo /repos/dynatrace-docs` examples
- `CLAUDE.md` — `/impl:jira` invariant "clones under `/repos/`"

Out of scope for edits: legitimate external URLs (`api.github.com/repos/…`,
`hub.docker.com/…`, `bitbucket.lab.dynatrace.org/projects/…/repos/…`) and the
historical design/plan docs under `docs/superpowers/specs/*` and
`docs/superpowers/plans/*` (left as-is — they are point-in-time records).

## Architecture of the fix (port the Copilot `$REPOS_PATH` design)

Replace the hardcoded `/repos` default and the "detect-then-ask" UX with
**`$REPOS_PATH`-based resolution** matching the Copilot sibling:

1. **`$REPOS_PATH` root** — default `/workspace`; colon-separated list supported
   (e.g. `/workspace:/home/me/projects`). Read from the environment; the command
   confirms or lets the user override at plan approval.
2. **Slug → clone resolution.** For each in-scope PR's repo-URL slug (the last
   path segment of the Bitbucket/GitHub repo URL, e.g. `cluster` from
   `…/repos/cluster/pull-requests/…`), scan candidate directories under
   `$REPOS_PATH`, run `git remote get-url origin` per candidate, and match by the
   upstream URL's **last path segment** (stripping `.git`).
3. **Multiple clones sharing an upstream** → auto-preference order
   `<slug>-repo` > `<slug>_repo` > `<slug>_fast` > alphabetically last. The user
   can override the chosen clone at plan approval.
4. **Sub-agent contract.** `diff-summarizer` and `code-scanner` receive an
   absolute `repo_path` (any path, not only `/repos/<name>`) plus an optional
   `repo_url_slug`. When `repo_url_slug` is present, the agent cross-checks it
   against `git remote get-url origin` and rejects a mismatch rather than
   summarizing the wrong repo.
5. **Environment variable rename.** `REPOS_BASE` → `REPOS_PATH`, with default
   `/workspace`, for consistency with the sibling marketplace.

Because matching is by **upstream URL**, not directory name, this is robust in
two cases the old `<repos_base>/<slug>` lookup mishandled:

- **Clone directory name ≠ slug** — a clone checked out into a directory whose
  name differs from the repo slug still resolves, because the match is on
  `git remote get-url origin`, not on `basename`.
- **Multiple clones of the *same* upstream** — e.g. `cluster` and `cluster-repo`
  both pointing at `…/rx/cluster.git` — are disambiguated by the preference
  order above.

Note this is distinct from two *different* repositories that merely share a name
prefix: `cluster` (`…/rx/cluster.git`) and `cluster-foundation`
(`…/rx/cluster-foundation.git`) are separate upstreams, and the last-path-segment
match resolves each unambiguously (`cluster` ≠ `cluster-foundation`).

## Files to change

Live content only. CHANGELOGs and version bumps record the breaking change.

| File | Change |
|---|---|
| `plugins/dev-workflows/commands/impl/jira/docs.md` | Phase-1 "Repos base path" question → `$REPOS_PATH` (default `/workspace`) scan + git-remote slug match; update Phase-4 repo-existence check and missing-repo escalation wording (`Use different $REPOS_PATH`) |
| `plugins/dev-workflows/commands/impl/jira/epics.md` | Same, gated on code-scan being ON |
| `plugins/dev-workflows/hooks/preload-context.sh` | `repos_base: ${REPOS_BASE:-/repos}` → `repos_path: ${REPOS_PATH:-/workspace}` (label + comment) |
| `plugins/dev-workflows/agents/diff-summarizer.md` | `repo_path` example → absolute (`/workspace/<repo-name>`); add optional `repo_url_slug` input + `git remote` cross-check |
| `plugins/dev-workflows/agents/code-scanner.md` | Same |
| `plugins/dev-workflows/references/handoff/diff-summarizer.md` | Handoff-schema example: `repo_path` absolute; add `repo_url_slug` |
| `plugins/dev-workflows/references/handoff/code-scanner.md` | Same |
| `plugins/dev-workflows/README.md` | "Mounts `/repos`" → `/workspace` umbrella + `$REPOS_PATH` discovery paragraph |
| `plugins/dt-style-guide/commands/dt-review-pr.md` | `--repo /repos/dynatrace-docs` examples → `/workspace/dynatrace-docs` |
| `plugins/dt-style-guide/README.md` | `/dt-review-pr 9089 --repo /repos/dynatrace-docs` → `/workspace/dynatrace-docs` |
| `CLAUDE.md` | `/impl:jira` invariant "clones under `/repos/`" → "clones discovered under `$REPOS_PATH` (default `/workspace`)"; add a short path-convention note |
| `plugins/dev-workflows/CHANGELOG.md` | New entry + minor version bump describing the breaking repo-discovery change (mirrors sibling 1.5.0 "Changed (breaking)" + migration note: `REPOS_PATH=/repos` restores old behaviour) |
| `plugins/dt-style-guide/CHANGELOG.md` | Entry + patch bump for the docs-path example update |
| `.claude-plugin/marketplace.json` | Reflect bumped versions if it pins them |

## Verification report (delivered as part of this work)

A written dry-run of PRODUCT-14902, grounded in this container, with findings
already established during design:

- **Container layout** confirmed: code repos at `/workspace/<name>`, vault at
  `/workspace/obsidian`, `VAULT_PATH` exported, `REPOS_PATH` unset (so the
  `/workspace` default must apply).
- **`/impl:jira:docs` trace:**
  - Vault resolves via `$VAULT_PATH=/workspace/obsidian`. ✓
  - The dominant repo `cluster` (65 of ~80 PR references) is mounted at
    `/workspace/cluster` and resolves by git-remote slug
    (`ssh://…/rx/cluster.git` → `cluster`). ✓
  - The docs write target `dynatrace-docs` is mounted at
    `/workspace/dynatrace-docs` (`ssh://…/sus/dynatrace-docs.git` →
    `dynatrace-docs`) and carries docs-repo signals (`.docstack`, `.vale.ini`,
    `.vale`), so `doc-location-finder` and the docs-write phase have a real
    target. ✓
  - Secondary repos referenced by the VI — `appfw-spec`, `semantic-dictionary`,
    `oneagent-protocols`, `installer-activegate`, `guidelines` — are **not
    mounted** → their PRs are skipped via the existing missing-repo escalation
    (`Skip and continue without its PRs`). This is an expected per-run scope
    decision, not a plugin bug.
- **`/impl` (code) trace:** `/impl:code` operates on the current working
  directory's repo, not a repo scan, so it has no `/repos` dependency. Running it
  from `/workspace/cluster` finds the PRODUCT-14902 implementation surface. It
  works in the new layout unchanged.

## Out of scope

The Copilot sibling's other 1.5.0 features are unrelated to the container
migration and are **not** ported here (flag only):

- branch-hint extraction / `diff-summarizer` Strategy 0
- release-notes draft output + `doc-planner` `release_notes_block`
- `git fetch` / `git pull` timeout wrapping
- `jira-reader` full-frontmatter exposure
- moving sub-agents to a different structure (Claude keeps `agents/` + commands)

## Success criteria

- No live plugin content defaults to `/repos`; all repo discovery roots at
  `$REPOS_PATH` (default `/workspace`).
- `grep -rn "/repos\b"` over live content (excluding external URLs and
  `docs/superpowers/`) returns nothing.
- `preload-context.sh` emits `repos_path: /workspace` when `REPOS_PATH` is unset;
  a 10-assertion stdin harness (mirroring the existing one in the CHANGELOG)
  still passes for all routing paths.
- The PRODUCT-14902 verification report is written and committed.
- Version bumps + CHANGELOG entries recorded for `dev-workflows` and
  `dt-style-guide`.

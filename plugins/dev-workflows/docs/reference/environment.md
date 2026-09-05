# Environment reference

[Getting started](../getting-started.md) says what each variable is *for* and what to export before your first run. This page says what each variable **is** — its default, where that default comes from, what happens when it is unset, what happens when it points somewhere the plugin cannot read or write, and the directory layout it expects underneath it. The plugin reads four user-settable variables. The rest of the names the plugin's own inventory check encounters while scanning for `$VAR` reads are never user-settable and stay out of scope here: `CLAUDE_PLUGIN_ROOT` and `ARGUMENTS` are runtime plumbing Claude Code itself sets for every plugin invocation, and `OSTYPE`, `BASH_SOURCE`, `BASH_REMATCH`, `ROOT`, and `OWNER_REPO` are shell built-ins or internal template/hook-local names, not plugin configuration.

## `$SPECS_PATH`

- **`$SPECS_PATH`** — the shared, team-visible repository every authoring command lands its artifact in; required, with no built-in default.

**Resolution.** Read straight from the shell environment — there is no config file, CLI flag, or derived fallback that feeds it. Every command that writes into it validates it at its own gating step (Phase 0 in most commands, Step 0 in `/vuln`) before doing any expensive work.

**When unset.** Every command that gates on it — `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/design`, `/ready`, and every `/brd-*` command — stops immediately, names `SPECS_PATH` explicitly, and offers `choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`. `/epics` instead degrades, skipping the artifact steps that need it. No command silently substitutes the current working directory or any other path.

**When it points somewhere unreadable.** Two separate gates apply, and they differ in strictness. The bookkeeping entry point, `specs-preflight`, requires `$SPECS_PATH` to be an existing directory, `git -C "$SPECS_PATH" rev-parse --git-dir` to succeed, **and** the resolved `.git` directory to be **writable** (tested specifically rather than the worktree, since a read-only specs mount is a normal state in this container setup); a failed gate is a silent no-op, and because the terminal `commit-artifacts` step applies the same writability gate, the feedback/cost/follow-up bookkeeping never gets committed either — `specs-preflight` only declines to prepare for a commit that step would then decline to make. The deliverable-verification entry point, `require-on-main`, needs only the first two conditions — a **readable** git dir is enough, writability is not required, since this gate only reads; a failed gate here returns the state `unmanaged`, and the caller proceeds exactly as it did before this handoff machinery existed — no artifact is verified, and nothing is reported as a stop. [Roles and phases](../roles-and-phases.md) covers the two states you meet more often mid-pipeline — an artifact stuck on an unmerged branch, and one that is simply absent from the default branch — but not `unmanaged`, since that is this environment condition (an unset or unmanageable `$SPECS_PATH`), not a workflow state.

**Directory layout.** See the layout block at the end of this page.

## `$REPOS_PATH`

- **`$REPOS_PATH`** — where your code clones live; defaults to `/workspace` when unset.

**Resolution.** `${REPOS_PATH:-/workspace}`, read fresh by each command that scans code — there is no persisted override once a run ends. It may be a single directory or a colon-separated list, and every repo-scanning command that offers a choice presents the resolved default first: `choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]`. Where a command resolves a repo from a pull-request URL — `/epics` here, and the companion plugin's `/docs-workflows:document` and `/docs-workflows:release-notes` — the match is by `git remote get-url origin` slug, **never by directory name**, so a clone renamed on disk is still found as long as its `origin` remote is intact. The commands that instead discover repos to offer you (`/idea`, `/create-ard`, `/design`) list the top-level directories under each entry and match on their basenames, attaching the slug afterwards as identity.

**When unset.** The `/workspace` default takes over silently — this is deliberately safe because `$REPOS_PATH` is only ever a read/scan base, so a wrong or empty default just finds nothing to scan rather than writing anywhere unexpected.

**When it points somewhere unreadable or empty.** A directory the user supplies in place of the default is validated to contain at least one directory before it is accepted — in `/epics` and `/specify`, which document that step; `/create-ard` and `/design` offer the same choice without documenting a validation step. Where it runs, validation fails back to the prompt rather than silently accepting a dead path. The default itself is never validated this strictly — a missing or empty `/workspace` on a host without the usual container mounts simply yields zero matched repos, which each repo-dependent command then treats per its own gate (some, like `/design` and `/brd-ground`, hard-stop on no mounted repos — `/brd-ground` because grounding has nothing to check a claim against without one; others degrade to a soft advisory skip — see that command's own page).

**Directory layout.** See the layout block at the end of this page.

## `$DOCS_PATH`

- **`$DOCS_PATH`** — a read-only clone of your shipped product documentation; defaults to `/workspace/docs` when unset.

**Resolution.** Flags first — `--no-docs` forces grounding off regardless of `$DOCS_PATH`; `--docs <path>` overrides it for that run. Otherwise `docs_root = ${DOCS_PATH:-/workspace/docs}`. A validity gate then has to pass for grounding to turn on at all: `docs_root` must be non-empty, an existing readable directory, and contain at least one markdown file.

**When unset.** The `/workspace/docs` default is probed by the validity gate above; on a host where that path does not exist, the gate simply fails.

**When it points somewhere unreadable, or the gate otherwise fails.** Every miss — unset, missing, unreadable, or no markdown file found — is a **silent, non-blocking skip**: `docs_grounding: OFF` with a one-line internal reason, never an error and never `emit-block`. Within the eight grounding consumers this plugin ships — `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/epics`, `/brd-intake` and `/brd-ground` — it never writes into `$DOCS_PATH` under any circumstance. The ninth, `/docs-workflows:release-notes`, holds the same posture from the companion plugin.

**Directory layout.** Unlike `$SPECS_PATH`, the plugin imposes no expected substructure here — it searches whatever markdown it finds under the root (for example, a full documentation-site checkout).

## `$GIT_USER_INITIALS`

- **`$GIT_USER_INITIALS`** — your branch identity string; no default, and the plugin never fails when it is absent.

**Resolution.** It is rung 1 of a five-rung identity ladder applied by the commands that name branches in a *code* repo — `/implement`, `/upgrade` and `/vuln` here, plus the companion plugin's `/docs-workflows:document` in both modes and `/docs-workflows:docs-profile` — the specs-repo handoff branches (`idea/`, `prd/`, `ard/`, `spec/`, `design/`, `ready/`, `brd/`, `frames/`) are named by `workflows-core:phase-handoff` §2.2 instead and never enter it. The rungs run in order, stopping at the first non-empty result: `$GIT_USER_INITIALS` (used verbatim, never with a trailing `/`) → `git config user.initials` (same semantics, set once per repo or globally) → inference from existing branch names (a candidate accepted at ≥30% of a sampled 200 branches and ≥3 occurrences) → a mandatory prompt if all three yield nothing.

**When unset.** The ladder simply falls through to rung 2, then 3, then the prompt — there is no error, only degradation to a less certain source. Where the target repo's documented branch-naming convention has no name-or-initials segment at all, the variable is simply unused for that repo regardless of whether it is set.

**When it points somewhere unreadable.** Not applicable — this variable holds a literal string, not a path.

**Directory layout.** Not applicable — this variable configures a branch-name segment, not a filesystem location.

## Directory layout

The three directory-valued variables above expect this layout. `$GIT_USER_INITIALS` holds a string, not a path, so it does not appear here. `$DEV_WORKFLOWS_COST_PRICES`, the price-table override, is read by the `workflows-core` plugin that now ships the cost subsystem, and is documented on its environment page rather than this one.

```

$SPECS_PATH/                        # shared, team-visible store
  specifications/PRD-<KEY>-<slug>/  # idea.md, prd.md, ard.md, release-notes.md, and EPIC-<KEY>-NN-<eslug>/ below it
    attachments/                    # markdown sources /idea vendored into the folder
    design/<frame-set>/             # exported frames + the index.md each set must carry
    dev-workflows/                  # bookkeeping: feedback, cost, resume.md, follow-ups

$REPOS_PATH/                        # code clones, one directory or a colon-separated list (default /workspace)
  <repo>/                           # discovered by directory name; matched by origin slug for PR-URL resolution

$DOCS_PATH/                         # optional, read-only: a product-docs clone (default /workspace/docs)
  ...                               # searched for grounding; the plugin never writes here
```

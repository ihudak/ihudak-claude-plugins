# Environment reference

[Getting started](../getting-started.md) says what each variable is *for* and what to export before your first run. This page says what each variable **is** — its default, where that default comes from, what happens when it is unset, what happens when it points somewhere the plugin cannot read or write, and the directory layout it expects underneath it. The plugin reads eight user-settable variables. The rest of the names the plugin's own inventory check encounters while scanning for `$VAR` reads are never user-settable and stay out of scope here: `CLAUDE_PLUGIN_ROOT` and `ARGUMENTS` are runtime plumbing Claude Code itself sets for every plugin invocation, and `OSTYPE`, `BASH_SOURCE`, `BASH_REMATCH`, `ROOT`, and `OWNER_REPO` are shell built-ins or internal template/hook-local names, not plugin configuration.

## `$SPECS_PATH`

- **`$SPECS_PATH`** — the shared, team-visible repository every authoring command lands its artifact in; required, with no built-in default.

**Resolution.** Read straight from the shell environment — there is no config file, CLI flag, or derived fallback that feeds it. Every command that writes into it validates it at its own gating step (Phase 0 in most commands, Step 0 in `/vuln`) before doing any expensive work.

**When unset.** The nine commands that gate on it — `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/design`, `/ready`, `/brd-intake`, `/brd-ground`, `/brd-split` — stop immediately, name `SPECS_PATH` explicitly, and offer `choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`. `/epics` and `/release-notes` instead degrade: `/epics` skips the artifact steps that need it, and `/release-notes` falls back to `run_phase: pm`. No command silently substitutes the vault, the current working directory, or any other path.

**When it points somewhere unreadable.** Two separate gates apply, and they differ in strictness. The bookkeeping entry point, `specs-preflight`, requires `$SPECS_PATH` to be an existing directory, `git -C "$SPECS_PATH" rev-parse --git-dir` to succeed, **and** the resolved `.git` directory to be **writable** (tested specifically rather than the worktree, since a read-only specs mount is a normal state in this container setup); a failed gate is a silent no-op, and because the terminal `commit-artifacts` step applies the same writability gate, the feedback/cost/follow-up bookkeeping never gets committed either — `specs-preflight` only declines to prepare for a commit that step would then decline to make. The deliverable-verification entry point, `require-on-main`, needs only the first two conditions — a **readable** git dir is enough, writability is not required, since this gate only reads; a failed gate here returns the state `unmanaged`, and the caller proceeds exactly as it did before this handoff machinery existed — no artifact is verified, and nothing is reported as a stop. [Roles and phases](../roles-and-phases.md) covers the two states you meet more often mid-pipeline — an artifact stuck on an unmerged branch, and one that is simply absent from the default branch — but not `unmanaged`, since that is this environment condition (an unset or unmanageable `$SPECS_PATH`), not a workflow state.

**Directory layout.** See the layout block at the end of this page.

## `$VAULT_PATH`

- **`$VAULT_PATH`** — your personal, markdown-backed store; required for `/idea` and for any command resolving `jira-products/<KEY>/`, with no built-in default.

**Resolution.** Read straight from the shell environment, exactly like `$SPECS_PATH` — no derived fallback exists.

**When unset.** Behavior depends on the command. `/idea` validates it must be set, an existing directory, and writable before doing anything else; if any of that fails it stops and offers `choices: ["Enter a directory to write idea.md into", "Cancel", "Other… (describe)"]`, and a user-supplied directory is validated the same way and used as the write root for that run — it never falls back to the current working directory, since that may be a code repository. Jira-driven commands that accept an already-imported export directory as their input (`/epics`, `/release-notes`) degrade gracefully instead: with `$VAULT_PATH` unset, `/epics` writes Epic drafts to a derived `epic-drafts/<jira_key>/` directory beside the import rather than under `jira-drafts/<PRD-KEY>/`, and `/release-notes` resolves its draft destination the same way.

**When it points somewhere unreadable.** The same validation that catches "unset" catches "exists but not writable" — both trip the same stop-and-offer path in `/idea`; a command with the graceful-degradation behavior above treats an invalid `$VAULT_PATH` the same way it treats an unset one.

**Directory layout.** See the layout block at the end of this page.

## `$REPOS_PATH`

- **`$REPOS_PATH`** — where your code clones live; defaults to `/workspace` when unset.

**Resolution.** `${REPOS_PATH:-/workspace}`, read fresh by each command that scans code — there is no persisted override once a run ends. It may be a single directory or a colon-separated list, and every repo-scanning command that offers a choice presents the resolved default first: `choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]`. Where a command resolves a repo from a pull-request URL — `/document`, `/epics`, `/release-notes` — the match is by `git remote get-url origin` slug, **never by directory name**, so a clone renamed on disk is still found as long as its `origin` remote is intact. The commands that instead discover repos to offer you (`/idea`, `/create-ard`, `/design`) list the top-level directories under each entry and match on their basenames, attaching the slug afterwards as identity.

**When unset.** The `/workspace` default takes over silently — this is deliberately safe because `$REPOS_PATH` is only ever a read/scan base, so a wrong or empty default just finds nothing to scan rather than writing anywhere unexpected.

**When it points somewhere unreadable or empty.** A directory the user supplies in place of the default is validated to contain at least one directory before it is accepted — in `/epics`, `/specify`, and `/document`, which document that step; `/create-ard`, `/design`, and `/release-notes` offer the same choice without documenting a validation step. Where it runs, validation fails back to the prompt rather than silently accepting a dead path. The default itself is never validated this strictly — a missing or empty `/workspace` on a host without the usual container mounts simply yields zero matched repos, which each repo-dependent command then treats per its own gate (some, like `/design` and `/brd-ground`, hard-stop on no mounted repos — `/brd-ground` because grounding has nothing to check a claim against without one; others degrade to a soft advisory skip — see that command's own page).

**Directory layout.** See the layout block at the end of this page.

## `$DOCS_PATH`

- **`$DOCS_PATH`** — a read-only clone of your shipped product documentation; defaults to `/workspace/docs` when unset.

**Resolution.** Flags first — `--no-docs` forces grounding off regardless of `$DOCS_PATH`; `--docs <path>` overrides it for that run. Otherwise `docs_root = ${DOCS_PATH:-/workspace/docs}`. A validity gate then has to pass for grounding to turn on at all: `docs_root` must be non-empty, an existing readable directory, and contain at least one markdown file.

**When unset.** The `/workspace/docs` default is probed by the validity gate above; on a host where that path does not exist, the gate simply fails.

**When it points somewhere unreadable, or the gate otherwise fails.** Every miss — unset, missing, unreadable, or no markdown file found — is a **silent, non-blocking skip**: `docs_grounding: OFF` with a one-line internal reason, never an error and never `emit-block`. Within these nine grounding consumers the plugin never writes into `$DOCS_PATH` under any circumstance.

**Directory layout.** Unlike `$VAULT_PATH` and `$SPECS_PATH`, the plugin imposes no expected substructure here — it searches whatever markdown it finds under the root (for example, a full documentation-site checkout).

## `$GIT_USER_INITIALS`

- **`$GIT_USER_INITIALS`** — your branch identity string; no default, and the plugin never fails when it is absent.

**Resolution.** It is rung 1 of a five-rung identity ladder applied by the five commands that name branches in a *code* repo (`/implement`, `/document` in both modes, `/docs-profile`, `/upgrade`, `/vuln`) — the specs-repo handoff branches (`idea/`, `prd/`, `ard/`, `spec/`, `design/`, `ready/`, `brd/`) are named by `phase-handoff.md` §2.2 instead and never enter it. The rungs run in order, stopping at the first non-empty result: `$GIT_USER_INITIALS` (used verbatim, never with a trailing `/`) → `git config user.initials` (same semantics, set once per repo or globally) → inference from existing branch names (a candidate accepted at ≥30% of a sampled 200 branches and ≥3 occurrences) → a mandatory prompt if all three yield nothing.

**When unset.** The ladder simply falls through to rung 2, then 3, then the prompt — there is no error, only degradation to a less certain source. Where the target repo's documented branch-naming convention has no name-or-initials segment at all, the variable is simply unused for that repo regardless of whether it is set.

**When it points somewhere unreadable.** Not applicable — this variable holds a literal string, not a path.

**Directory layout.** Not applicable — this variable configures a branch-name segment, not a filesystem location.

## `$DEV_WORKFLOWS_COST_PRICES`

- **`$DEV_WORKFLOWS_COST_PRICES`** — optional override path for the token-price table session-cost reporting prices against; the plugin ships its own default price table, so setting this is never required.

**Resolution.** First-found-wins, three tiers: `$DEV_WORKFLOWS_COST_PRICES` (a path) → a repo-local `cost-prices.yaml` → the bundled `${CLAUDE_PLUGIN_ROOT}/references/cost-prices.yaml`. Whichever file resolves must carry a top-level `models:` map keyed by model id (`input`/`output`/`cache_read`/`cache_write_5m`/`cache_write_1h`, in USD per million tokens) — a file missing that wrapper, whether it is the override or the shipped default, prices every model as `cost_usd: null` rather than raising an error.

**When unset.** Resolution falls straight through to the repo-local file, then the bundled default — this is the variable of the six most users never touch — though `$REPOS_PATH`, `$DOCS_PATH`, and `$GIT_USER_INITIALS` all have working fallbacks too.

**When it points somewhere unreadable.** An unreadable or missing path at this tier is treated the same as "not set at this tier" — resolution continues down the same first-found-wins chain to the next tier rather than failing the run.

**Directory layout.** Not applicable — this variable names one file, not a directory tree.

## `$UI_GUIDELINES_PATH`

**What it is.** An absolute path to a directory of `.md` files carrying **your organization's own UI rules** — a proprietary design system's component contract, internal terminology, anything with no public equivalent. `/guideline-reviewer` layers it over the bundled vendor-neutral baseline in `references/guidelines/`.

**Default.** Unset. There is no default path.

**Unset, or pointing somewhere unreadable.** A silent, non-blocking fall-through: the reviewer resolves `--rules <path>` first, then `<repo-root>/.dev-workflows/ui-guidelines/`, then this variable, then the bundled baseline alone. A miss at every order is the normal case and is never reported as a problem — the run's `rules_source:` line records what actually resolved.

**Layout.** A flat directory of `.md` files. A file whose name matches a bundled one (`datatable.md`, `accessibility.md`, …) layers over it and wins on conflict; a file matching none is an additional rule source. An `## Allowed` section suppresses matching baseline rules. First hit wins across the orders above — two overlays are never merged.

## `$API_GUIDELINES_PATH`

**What it is.** The same mechanism for `/api-guideline-reviewer`: a directory of `.md` files carrying your own API rules — an internal scope grammar, a required header spelling, an error-envelope contract — layered over the bundled baseline in `references/api-guidelines/`.

**Default.** Unset. There is no default path.

**Unset, or pointing somewhere unreadable.** Silent fall-through, in the same order: `--rules <path>`, then `<repo-root>/.dev-workflows/api-guidelines/`, then this variable, then the bundled baseline.

**Layout.** As above. Note this variable governs the **prose** rules the LLM passes read. The **executable** half has its own precedence and does not use this variable: a repository's own `.spectral.yaml` / `.spectral.yml` / `.spectral.json` wins over the bundled Spectral ruleset, which an organization is expected to `extend` from its own file rather than edit in place.

## Directory layout

The four directory-valued variables above expect this layout. `$GIT_USER_INITIALS` holds a string, not a path, and `$DEV_WORKFLOWS_COST_PRICES` names one file rather than a directory, so neither appears here.

```
$VAULT_PATH/                        # personal store (e.g. an Obsidian vault; any markdown-backed store works)
  jira-products/<KEY>/              # Jira hierarchy from jira-workitem-import (input; regenerated on each import)
  Projects/<area>/<slug>/           # idea.md and other project working files
  jira-drafts/<PRD-KEY>/             # Epic drafts written by /epics

$SPECS_PATH/                        # shared, team-visible store
  specifications/<KEY>-<slug>/      # the Product Requirements Document, the ARD, specification.md, design.md
    dev-workflows/                  # bookkeeping: feedback, cost, resume.md; follow-ups only with no vault

$REPOS_PATH/                        # code clones, one directory or a colon-separated list (default /workspace)
  <repo>/                           # discovered by directory name; matched by origin slug for PR-URL resolution

$DOCS_PATH/                         # optional, read-only: a product-docs clone (default /workspace/docs)
  ...                               # searched for grounding; the plugin never writes here
```

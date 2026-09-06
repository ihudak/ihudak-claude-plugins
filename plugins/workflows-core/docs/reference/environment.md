# Environment reference

[Getting started](../getting-started.md) says what each variable is *for* and what to export before your first use of this plugin. This page says what each variable **is** — its default, what happens when it is unset, and what happens when it points somewhere unreadable. The plugin reads five user-settable variables. The rest of the names its own inventory check encounters while scanning for `$VAR` reads are never user-settable and stay out of scope here: `CLAUDE_PLUGIN_ROOT` and `ARGUMENTS` are runtime plumbing Claude Code itself sets for every plugin invocation, and `OSTYPE`, `BASH_SOURCE`, `BASH_REMATCH`, `ROOT` and `OWNER_REPO` are shell built-ins or internal template names, not plugin configuration.

Every one of the five is read by a reference this plugin ships rather than by a command of its own — the corpus is where the reads live, and the corpus is here. The set is the union of what any downstream plugin needs, plus the price-table override: `dev-workflows` and `docs-workflows` each read all four of the others (`$GIT_USER_INITIALS` included, since each branches a repository somewhere); `product-workflows` reads three of the four — it never creates a branch in a code or docs repo, so `$GIT_USER_INITIALS` is not among the variables its own commands or references touch.

## `$SPECS_PATH`

- **`$SPECS_PATH`** — the shared, team-visible store the whole family writes its artifacts and bookkeeping into. It is the one write root with no default: nothing is guessed.

**Resolution.** Used verbatim as a directory path. `specs-repo-git.md`'s preflight and terminal commit run every git call as `git -C "$SPECS_PATH"` and never change the working directory.

**When unset.** Cost, feedback and follow-up entries fall through to their report-only tier — the run says what it would have written and writes nothing. Nothing is ever written into the current working directory instead, since it may be a code repository.

**When it points somewhere unreadable or unwritable.** The same degradation, reported rather than fatal.

## `$REPOS_PATH`

- **`$REPOS_PATH`** — where your code clones live; one directory, or a colon-separated list. Defaults to `/workspace`.

**Resolution.** `code-scanner` and the grounding agents resolve a repository under it — by `git remote get-url origin` slug where a command starts from a pull-request URL, and by directory basename where a command lists candidates to offer you.

**When unset.** The default applies. A repository that is simply not mounted is reported as unresolvable rather than guessed at.

**When it points somewhere unreadable.** The scan reports the miss; `read-only-repos.md` covers the narrower case of a mount that is readable but not writable, which is scanned at a pinned ref rather than refused.

## `$DOCS_PATH`

- **`$DOCS_PATH`** — a **read-only** clone of your shipped product documentation. Defaults to `/workspace/docs`.

**Resolution.** `docs-grounding.md` gates on it being a readable directory holding at least one markdown file; `docs-grounder` reads it and never writes to it.

**When unset.** The default is tried, and every miss — unset, missing, or no markdown found — is a silent, non-blocking skip. Grounding is advisory, never a gate.

**When it points somewhere unreadable.** The same silent skip.

## `$GIT_USER_INITIALS`

- **`$GIT_USER_INITIALS`** — your branch identity string; no default, and nothing fails when it is absent.

**Resolution.** It is rung 1 of the identity ladder `branch-naming.md` applies for a code repository. The rungs run in order, stopping at the first non-empty result: this variable, then `git config user.initials`, then inference from existing branch names, then a prompt.

**When unset.** The ladder falls through — there is no error, only degradation to a less certain source. Where the target repo's documented convention has no name-or-initials segment, the variable is simply unused for that repo.

**When it points somewhere unreadable.** Not applicable — this variable holds a literal string, not a path.

## `$DEV_WORKFLOWS_COST_PRICES`

- **`$DEV_WORKFLOWS_COST_PRICES`** — optional override path for the token-price table session-cost reporting prices against; this plugin ships its own default table, so setting it is never required.

**Resolution.** First-found-wins, three tiers: `$DEV_WORKFLOWS_COST_PRICES` (a path) → a repo-local `cost-prices.yaml` → the bundled `${CLAUDE_PLUGIN_ROOT}/references/cost-prices.yaml`. Whichever file resolves must carry a top-level `models:` map keyed by model id — a file missing that wrapper, override or default, prices every model as `cost_usd: null` rather than raising an error.

**When unset.** Resolution falls straight through to the repo-local file, then the bundled default. This is the variable of the five most users never touch.

**When it points somewhere unreadable.** Treated the same as "not set at this tier" — resolution continues down the same chain rather than failing the run.

**Its name keeps the `DEV_WORKFLOWS_` prefix deliberately.** The variable predates this plugin, and renaming it would silently ignore every setting already exported on a working machine. See [Session cost](session-cost.md) for what the table prices.

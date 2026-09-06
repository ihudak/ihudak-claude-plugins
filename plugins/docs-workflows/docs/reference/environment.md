# Environment reference

[Getting started](../getting-started.md) says what each variable is *for* and what to export before your first run. This page says what each variable **is** — its default, where that default comes from, what happens when it is unset, and what happens when it points somewhere the plugin cannot read or write. The plugin reads four user-settable variables. The rest of the names its own inventory check encounters while scanning for `$VAR` reads are never user-settable and stay out of scope here: `CLAUDE_PLUGIN_ROOT` and `ARGUMENTS` are runtime plumbing Claude Code itself sets for every plugin invocation.

## `$SPECS_PATH`

- **`$SPECS_PATH`** — the shared, team-visible repository holding the PRD folder `/document` and `/release-notes` read, and the one place either of them commits its own session bookkeeping; required for a keyed run, with no built-in default.

**Resolution.** Read straight from the shell environment — there is no config file, CLI flag, or derived fallback that feeds it. Every git call against it is `git -C "$SPECS_PATH"`, never a `cd`, so the docs or code repository the run is working in is untouched.

**When unset.** `/document` in keyed mode resolves its address through `resolve-address` against `$SPECS_PATH`, so there is nothing left to resolve and the run cannot get past Phase 0; direct mode resolves no address and never needed one. `/release-notes` degrades rather than stopping — it falls back to `run_phase: pm`, which only suppresses the inference that would otherwise read the PRD folder for a `specification.md` or `design.md`. `/docs-profile` never reads the variable at all.

**When it points somewhere unreadable.** The bookkeeping entry point, `specs-preflight`, requires an existing directory, a resolvable git dir, and a **writable** `.git`; a gate that fails on **writability** is a silent no-op (a read-only specs mount is a normal state here, and there is nothing to fix), while a gate that fails because `$SPECS_PATH` is not a directory or not a git repository at all emits a one-line notice naming the variable and the path — that state is never supported, and it used to be indistinguishable from the read-only one, and because the terminal `commit-artifacts` step applies the same writability gate, nothing gets committed either. The deliverable-verification gate, `require-on-main`, needs only a readable git dir, and a failure there returns `unmanaged` — the caller proceeds exactly as it did before that machinery existed.

## `$REPOS_PATH`

- **`$REPOS_PATH`** — where your code clones live; defaults to `/workspace` when unset.

**Resolution.** `${REPOS_PATH:-/workspace}`, read fresh by each run that resolves PR diffs — there is no persisted override once a run ends. It may be a single directory or a colon-separated list. Repos are matched by `git remote get-url origin` slug, **never by directory name**, so a clone renamed on disk is still found as long as its `origin` remote is intact.

**When unset.** The `/workspace` default takes over silently — safe, because this is only ever a read/scan base, so a wrong or empty default finds nothing to scan rather than writing anywhere unexpected.

**When it points somewhere unreadable or empty.** `/document` validates a user-supplied path for at least one directory before accepting it; `/release-notes` offers the same choice without documenting a validation step. Either way an unresolvable slug escalates to the user rather than being silently dropped. The default itself is never validated this strictly — an empty `/workspace` simply yields zero matched repos, which downstream turns into a diff-summary gap the run reports.

## `$DOCS_PATH`

- **`$DOCS_PATH`** — a read-only clone of your shipped product documentation; defaults to `/workspace/docs` when unset.

**Resolution.** `/document` Phase 0 resolves `${DOCS_PATH:-/workspace/docs}` as a **docs-repo discovery hint** — rung (a.5) of its resolution ladder — and takes it as the write target when it carries at least one docs signal or an in-repo `.dev-workflows/docs-profile.yml`. `/release-notes` resolves it for docs grounding instead, off `--no-docs` and overridable with `--docs <path>`.

**When unset.** The `/workspace/docs` default is probed; on a host where that path does not exist, the rung simply does not fire and `/document` continues down its ladder.

**When it points somewhere unreadable.** Every miss — unset, missing, unreadable, or no markdown file found — is a **silent, non-blocking skip**, never an error. The discovery hint is a write-target *candidate* only, so a docs repository resolved through it is written to as any other would be; the grounding path never writes into `$DOCS_PATH` under any circumstance.

**Directory layout.** No expected substructure — whatever markdown sits under the root (for example, a full documentation-site checkout).

## `$GIT_USER_INITIALS`

- **`$GIT_USER_INITIALS`** — your branch identifier; optional, and rung 1 of the five-rung ladder `workflows-core:branch-naming` §2 fixes.

**Resolution.** It is rung 1 of the identity ladder the two branch-creating commands here apply — `/document` in keyed mode (direct mode creates no branch and no commit) and `/docs-profile`. The rungs run in order, stopping at the first non-empty result: `$GIT_USER_INITIALS` (used verbatim, never with a trailing `/`) → `git config user.initials` → inference from existing branch names → the per-command fallback prefix → a mandatory prompt if nothing above yields anything.

**When unset.** The ladder falls through to the rungs below it — there is no error, only degradation to a less certain source. Branch naming is repo-rule-first: where the target repo's documented convention has no name-or-initials segment at all, the variable is simply unused for that repo regardless of whether it is set.

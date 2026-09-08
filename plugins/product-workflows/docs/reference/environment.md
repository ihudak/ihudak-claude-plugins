# Environment reference

[Getting started](../getting-started.md) says what each variable is *for* and what to export before your first run. This page says what each variable **is** — its default, where that default comes from, what happens when it is unset, and what happens when it points somewhere the plugin cannot read or write. The plugin reads three user-settable variables. The rest of the names its own inventory check encounters while scanning for `$VAR` reads are never user-settable and stay out of scope here: `CLAUDE_PLUGIN_ROOT` and `ARGUMENTS` are runtime plumbing Claude Code itself sets for every plugin invocation.

## `$SPECS_PATH`

- **`$SPECS_PATH`** — the shared, team-visible repository holding every PRD, ARD, specification, idea, and BRD folder these thirteen commands read and write, and the one place any of them commits its own session bookkeeping; required for every keyed run, with no built-in default.

**Resolution.** Read straight from the shell environment — there is no config file, CLI flag, or derived fallback that feeds it. Every git call against it is `git -C "$SPECS_PATH"`, never a `cd`, so your current working directory is untouched.

**When unset.** Every command that needs it stops naming `SPECS_PATH` explicitly and offers to enter a path or cancel — there is no fallback and no silent default, because a PM/PA/PE artifact has nowhere else to live.

**When it points somewhere unreadable.** The bookkeeping entry point, `specs-preflight`, requires an existing directory, a resolvable git dir, and a **writable** `.git`; a gate that fails on **writability** is a silent no-op (a read-only specs mount is a normal state here, and there is nothing to fix), while a gate that fails because `$SPECS_PATH` is not a directory or not a git repository at all emits a one-line notice naming the variable and the path — that state is never supported, and it used to be indistinguishable from the read-only one, and because the terminal `commit-artifacts` step applies the same writability gate, nothing gets committed either. The deliverable-verification gate, `require-on-main`, needs only a readable git dir, and a failure there returns `unmanaged` — the caller proceeds exactly as it did before that machinery existed.

## `$REPOS_PATH`

- **`$REPOS_PATH`** — where your mounted implementation and code clones live; defaults to `/workspace` when unset.

**Resolution.** `${REPOS_PATH:-/workspace}`, read fresh by each run that grounds against code — `/create-ard`'s mandatory repo discovery, `/idea`'s optional `--ground-code`, `/specify`'s light feasibility scan, `/epics`'s optional code scan, and `/prd-ground`'s pinned-commit grounding. It may be a single directory or a colon-separated list; a repo is a top-level directory carrying a `.git` entry directly under it.

**When unset.** The `/workspace` default takes over silently — safe, because this is only ever a read/scan base, so a wrong or empty default finds nothing to scan rather than writing anywhere unexpected.

**When it points somewhere unreadable or empty.** An unresolved repo slug or theme is escalated to the user rather than invented or silently dropped; a repo the user then declines is carried forward by name with its themes left unverified, never disappearing from the record. `/create-ard`'s discovery is mandatory rather than opt-in, so an empty `$REPOS_PATH` there surfaces as zero candidate directories to confirm, not as a stop.

## `$DOCS_PATH`

- **`$DOCS_PATH`** — a read-only clone of your shipped product documentation; defaults to `/workspace/docs` when unset.

**Resolution.** Resolved per the shared `workflows-core:docs-grounding` gate, consumed by every command here except `/brd-split`, `/brd-interview`, `/brd-package`, and `/brd-reconcile` (each of which resolves no docs grounding at all, for a reason its own body states) — grill-rank in the authoring/interview commands, lead-only in `/prd-ground`. Overridable with `--docs <path>` where the command parses it — today `/idea` alone, though the shared gate declares it for every consumer; turned off with `--no-docs` everywhere, and additionally by `--no-code` in `/prd-ground`.

**When unset.** The `/workspace/docs` default is probed; on a host where that path does not exist, the resolution simply reports `OFF` and the run continues.

**When it points somewhere unreadable.** Every miss — unset, missing, unreadable, or no markdown file found — is a **silent, non-blocking skip**, never an error and never a gate or reviewer BLOCKER. `product-workflows` never writes into `$DOCS_PATH` under any circumstance.

**Directory layout.** No expected substructure — whatever markdown sits under the root (for example, a full documentation-site checkout).

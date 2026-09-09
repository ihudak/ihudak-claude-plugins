# /docs-init

Scaffolds a documentation repository for a project that has none — one that builds, serves, lints, and carries the profile every later command in this family reads.

## Who runs it

`/docs-init` is the family's cold-start command, and it runs once per documentation repository. It sits ahead of the pipeline rather than inside it: nothing upstream feeds it, and what it leaves behind is the repository `/document` writes pages into and `/docs-serve` serves. [Workflow overview](../workflow.md) draws it in its own *Cold start* group, with the one edge into `/docs-brand` that it runs as a phase of itself. It classifies as **MODERATE** — mechanical scaffolding against a template held in this plugin's references — but its review gate is Opus regardless, because a scaffold is code and every artefact-writing command in this family passes a high-tier review with no tiering by unit.

**It never writes documentation content.** What it produces is a portal shape: directories, one stub per section stating what belongs there and what does not, two build configurations, a linter, a CI workflow, and a profile. Filling the pages in is `/document`'s job.

## Synopsis

```
/docs-init [<docs-repo-path>] [--generator mkdocs-material] [--no-brand] [--public-only] [--with-pricing] [--with-compliance]
```

Every recognized flag is stripped from `$ARGUMENTS` before the remaining token is read as the optional docs-repo path (Phase 0 step 0). `--generator` accepts `mkdocs-material` and nothing else today; any other value stops the run. `--no-brand` skips the branding phase. `--public-only` omits the internal build config, the `internal/` tree, and the marker gate that separates them. `--with-pricing` and `--with-compliance` each add their optional stubs under `discover/`.

## What it needs

- **Somewhere to scaffold into** — resolved by `resolve-scaffold-target` (`docs-workflow/repo-resolution.md` §2), which is the **inverted** form of the ladder every sibling uses: the given path, else `$DOCS_PATH` *when it is absent or carries no documentation signal*, else the working directory. Every other command in this family accepts a directory because it already looks like a documentation repository; this one accepts it because it does not. The rung that answered is always reported.
- **A git work tree, or an empty or absent directory** — the second is offered a `git init` before anything is written. A non-empty directory that is not a git work tree stops the run.
- **A directory carrying no documentation signal.** One signal is enough to refuse: scaffolding is for cold start, and describing a repository that already exists is `/docs-profile`'s job.
- **The toolchain the scaffold's own gates invoke** — `git`, `python3` and `pip` (or `uv`), `mkdocs`, and `vale`. Checked at Phase 2, and the run prompts only when something is missing.
- **`$SPECS_PATH`**, for its own session bookkeeping only. Nothing about the scaffold is read from there.

## Phases

| Phase | What happens |
|---|---|
| 0 — Resolve and validate | Strip flags; resolve the target and report the rung; run the specs-repo preflight; establish a writable git work tree or offer to create one; refuse a directory carrying a docs signal. |
| 1 — Model routing | Classify MODERATE and record the routing block. The review model is pinned to the Opus chain regardless. |
| 2 — Source repos and toolchain preflight | Confirm which code repositories the portal documents, resolve the product name and current major version, and check that the tools the later gates invoke are present. |
| 2.5 — Branch | Create the branch, **before anything is written**, behind a clean-tree check that is only meaningful ahead of the first write. |
| 3 — Scaffold | Write the tree, the stubs, the generated navigation, both build configs, the visibility markers, and the CI workflow, resolving every substitution including the pinned Vale release. |
| 4 — Vale | Write `requirements-docs.txt` and `.vale.ini`, run `vale sync`, and create the project vocabulary file. |
| 5 — Branding | Run `/docs-brand --inline` against the repository just scaffolded, unless `--no-brand`. Its diff and its contrast finding join this run's single review and single pull request. |
| 6 — Profile | Write `.dev-workflows/docs-profile.yml`: the generator, both builds, both dev servers, the commands, and the structured images block. |
| 7 — Verify the scaffold | Public build strict, internal build strict, `vale docs/`, then the visibility gate against the **public build output** — in that order. |
| 7.5 — Review gate | Dispatch `docs-scaffold-reviewer` at Opus over the written diff, triage its findings, and apply the survivors in the orchestrator. |
| 8 — Finish | Commit on the branch and draft a pull-request message. Never pushes, never merges. |
| 8.5 — Report | The consolidated report, including every verification outcome and the next step. |
| 9–11 — Emitter tail | Session maintenance and feedback, follow-ups, then cost, the resume pointer, and the terminal bookkeeping commit. |

## Gates

**Phase 7 — verification, and a failure is reported rather than worked around.** The four steps run in order, and the rule is stated in the command body rather than left as advice: no relaxed `--strict`, no dropped validation key, no deleted page, no silenced linter. A failing step is carried into the reviewer's brief, into the pull-request draft, and into the report, and nothing downstream describes the scaffold as verified. The run continues, because the branch and the diff still exist and are still worth reviewing.

**Phase 7.5 — the review gate.** `docs-scaffold-reviewer` runs on Opus over a fixed seven-item checklist, six of whose items assert a relationship *between two files* — the navigation against the tree, one config against the other, a workflow step against the profile field that parameterises it. That is exactly what a reviewer reading one diff hunk at a time cannot see, which is why the checklist is fixed rather than left to judgement. The run tells the reviewer which of the seven `--public-only` makes inapplicable, so an absent internal build is reported as by-design rather than as a defect.

Its build-parity item reads an itemisation, not key-level identity: the two configs are *required* to share `docs_dir`, `markdown_extensions`, the theme block, `extra_css`, `validation` and the navigation-generation rule, and are *allowed* to differ in `exclude_docs`, `site_name`, `site_dir` and the generated navigation itself. An internal config with an empty `exclude_docs`, or one missing `site_dir: site-internal`, is the defect — not the difference.

Findings are triaged by the orchestrator before anything is applied: each is verified at the location it names, every dismissal is recorded with a reason, and only survivors are acted on. There is no dedicated fixer for this diff — the orchestrator applies survivors itself, and surfaces one whose fix is not a safe mechanical patch rather than guessing at it.

## Outputs

- **The scaffolded repository**, on a branch with one commit and a drafted pull-request message. Nothing is pushed and nothing is merged.
- **`.dev-workflows/docs-profile.yml`** — the one output that makes every later command work on this repository: `/docs-serve` reads its `dev_servers` block, `/document` reads its content roots and commands, and the CI workflow's conditional image step is written against its `images.policy`.
- **A session cost entry and any feedback**, filed under `$SPECS_PATH/documentation/<docs-repo-slug>/` — per documentation repository rather than in the pending queue, because a documentation run frequently has no PRD and never will. See [Session cost](../reference/session-cost.md).

## Failure modes

- `DOCS_INIT_UNKNOWN_GENERATOR` — `--generator` named something other than `mkdocs-material`. A second generator is a new template, not a flag value.
- `DOCS_INIT_TARGET_NOT_WRITEABLE` — the resolved repository root is not writable.
- `DOCS_INIT_NOT_A_GIT_WORKTREE` — the target is non-empty and is not inside a git work tree. Initialise it yourself, or point the command at an empty or absent directory.
- `DOCS_INIT_EXISTING_DOCS_REPO` — the target already carries at least one documentation signal. Run [`/docs-profile`](docs-profile.md) to describe what is there, or [`/docs-brand`](docs-brand.md) to brand it.
- `DOCS_INIT_TOOLCHAIN_INCOMPLETE` — a required tool is missing and the operator cancelled at the preflight prompt. Proceeding anyway is allowed; Phase 7 then reports the affected step as unrun rather than as passed.
- `DOCS_INIT_UNRESOLVED_BLOCKER` — a BLOCKER finding from `docs-scaffold-reviewer` was neither fixed nor explicitly overridden.
- A cancelled Phase 2.5 is not a failure: nothing is written, no branch is created, and the report says so. The cost entry is still recorded.

## Example

```
/docs-workflows:docs-init /workspace/docs
```

Resolves `/workspace/docs`, finds it empty, offers to `git init` it, confirms the code repositories under `$REPOS_PATH` that the portal will document, branches, and writes the portal: `discover/`, `get-started/`, `guides/`, `reference/`, `administration/`, `troubleshooting/`, `whats-new/`, `internal/`, the snippet and asset directories, both MkDocs configs, `.vale.ini` with its vocabulary, and `.github/workflows/docs.yml`. It brands the site from the product's own code, writes the profile, builds both sites strictly, lints, greps the public output for internal markers, gates the diff on an Opus review, and hands back a branch with a drafted pull request.

```
/docs-workflows:docs-init /workspace/docs --public-only --with-compliance
```

The same run without the internal half — no `mkdocs.internal.yml`, no `internal/` tree, no marker gate — plus the accessibility and security statement stubs under `discover/`. The reviewer is told which of its checks that makes inapplicable.

## See also

- [`/docs-brand`](docs-brand.md) — run as a phase of this command, and separately whenever the brand changes.
- [`/docs-serve`](docs-serve.md) — the natural next step: open the scaffolded portal in a browser.
- [`/docs-profile`](docs-profile.md) — the command for a documentation repository that already exists, and where `DOCS_INIT_EXISTING_DOCS_REPO` sends you.
- [Documentation visibility](../reference/docs-visibility.md) — the two-build model this scaffold implements, the traps that make the obvious checks useless, and the gates that assert on built output instead.
- [Session cost](../reference/session-cost.md) — what this run charges to and where the file lands.

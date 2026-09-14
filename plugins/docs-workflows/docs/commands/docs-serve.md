# /docs-serve

Starts, stops, or checks a profiled documentation repository's dev server, and reports a URL that actually opens from the host.

## Who runs it

`/docs-serve` runs outside the role pipeline, the same way `/docs-profile` does — no role, no cost-attribution phase (it is one of the commands [Session cost](../reference/session-cost.md) names as emitting nothing), and no `workflows-core:model-routing` classification: it starts a process and reports a URL rather than reasoning about anything. [Workflow overview](../workflow.md) draws it beside `/docs-profile` in the setup-utility row, reached at any point rather than as a pipeline stage. It writes no documentation and no artefact, which is also why it carries no review gate — D17, the family rule that every artefact-writing command passes a high-tier review, names `/docs-serve` as its sole exemption.

## Synopsis

```
/docs-serve [<docs-repo-path>] [--internal] [--stop] [--status] [--build] [--port <n>]
```

Every recognized flag is stripped from `$ARGUMENTS` before the remaining token is read as the optional docs-repo path (Phase 0). `--status`, `--stop`, and `--build` each select a short-circuit mode (Mode dispatch); with none of the three, the command resolves the repo's `dev_servers` profile and serves it. `--internal` selects the internal build's server where the profile distinguishes one, and stops where the profile tags a public server but no internal one — a `--public-only` scaffold — rather than serving the public build in its place; `--port <n>` overrides the port this run checks and starts against, without rewriting the profile's own recorded command.

## What it needs

- **A profiled docs repository** — resolved by `resolve-docs-repo` (`docs-workflow/repo-resolution.md` §1), the same signal-positive ladder `/docs-profile` and `/docs-brand` use: the given path, else the working directory, else `$DOCS_PATH`, else a search under `$REPOS_PATH`, else a question — only two of these rungs can hand back a directory carrying no docs signal, an explicit path (taken as given) and the final generic question; every other rung tests against a docs-repo signal before it can answer, and the rung that did is reported.
- **A written `dev_servers` block** — `.dev-workflows/docs-profile.yml` (in the resolved repo, not the plugin), specifically its `dev_servers.servers[]` list. A repo that has never been profiled, or whose profile predates `dev_servers`, stops with `DOCS_SERVE_NO_DEV_SERVER` and points at `/docs-workflows:docs-profile` to write one.
- **Nothing from `$SPECS_PATH`** — this command runs no `specs-preflight` and no `commit-artifacts`. The only state it records lives under the resolved repo's own `.dev-workflows/`.

## What it produces

The default flow (Phase 1 onward) selects the server to run — by a profile's own `visibility` tag when one is recorded, by being the only server on offer, or by asking when several exist and neither applies — then checks whether it is already running (never starting a second copy of a server that is already up), works around a port already held by something else by moving forward to the next free one and saying so, starts the chosen command bound to `0.0.0.0` so a container-mapped port stays reachable from the host, polls it for readiness, and reports the URL to open: the profile's own `public_base_url` when set, or the in-container address with an explicit caveat when not. It then records the pid of the process actually holding the port — read from the socket table, never a wrapper's, so a server started through `npm run` or `pnpm` is the one a later `--stop` ends — under `.dev-workflows/`, **keyed by the port the server is bound to** and naming the server it started — its space, and its visibility where the profile tags one — so a later `--status` or `--stop` — in the same session or a new one — can act on what this run started. A port holds one server and a space name does not identify one: the profile `/docs-init` writes serves one content space twice, a public site and an internal one, and a record per port is what keeps the two from overwriting each other. Every lookup made through the server selection — a serve run checking whether its server is already up, and `--status --internal` or `--stop --internal` — looks only at records of the selected server before it matches a port, so a server a port collision moved onto another server's port is never mistaken for that one: not the public site moved onto the internal site's port, and not one space's server moved onto the next space's. **Where no record survives, a server is identified by evidence, never by the port it answers on.** A port that answers as this docs site — the configured one, one the collision walk reaches, or one a collision would have moved the server to — is asked which process holds it. A process in another checkout of the same repository, such as a sibling `git worktree` (nested inside this one or not), is left running, named in the report and never recorded, so each checkout serves its own pages and one checkout's `--stop` never ends another's server. A process in this checkout is matched to a server by the command line it was started with, and on the two-build profile `/docs-init` writes also by the site name in its page's title. The selected server is re-adopted and recorded wherever it is found, on any profile, and another of this repository's servers is passed over. The ports a collision would have moved it to are searched before anything starts, whether the configured port has come free since or is still held, because a copy moved past a port that was busy then can sit beyond one that is free now. Where two checkouts start the server at once and the other one wins the port, this run records nothing and says which checkout holds it. Only where nothing can say which server answered does a profile with one server re-adopt it anyway, since it can be nothing else, and a profile with more than one say it cannot tell and start nothing, naming the process to stop by hand or `--port <n>` to serve elsewhere. A re-adopted server whose process could not be named gets no pid on record: `--stop` cannot end it while it runs, and clears its entry once its port stops answering. `--stop` reports a server stopped only once its port no longer answers as this docs site. A recorded pid counts only while the socket table still names it on its port, so a pid number reused after a container restart is never taken for the server, and never signalled. The state file is never committed; ignore that one file, not the `.dev-workflows/` directory, which also holds the committed profile.

`--build` runs the profile's build command (from `builds[]`, `commands.per_space.<space>.build`, or `commands.build`, in that order) in the foreground and exits without serving — the flag exists instead of a separate `/docs-build` command, since the pipeline already gates on the profile's build. `--status` reports every server this command has a live record of for the resolved repo. `--stop` ends one.

## Gates

**No review gate, by design (D17).** This command writes no documentation and no other artefact — a start/stop/status/build run against a repo's own dev-server process — so there is nothing for a reviewer to check before it is trusted. Its closing report carries a `### Next step` line rather than a `choices` next-phase offer, and that offer states explicitly that it carries no `<merge-clause>`: nothing downstream ever waits on a pull request this run might have opened, because this run opens none.

## Failure modes

- `DOCS_SERVE_NO_DEV_SERVER` — the resolved repo's profile is absent, or present but records no `dev_servers` block. Run `/docs-workflows:docs-profile` against the repo first.
- `DOCS_SERVE_NO_BUILD_COMMAND` (`--build` only) — none of `builds[]`, `commands.per_space.<space>.build`, or `commands.build` resolves a command to run.
- `DOCS_SERVE_NO_INTERNAL_BUILD` — `--internal` on a profile that tags its servers or builds but records no internal one, which is what a `/docs-init --public-only` scaffold writes. Drop `--internal` to serve the public build; an internal build needs its own build config and a server entry tagged `internal`. `DOCS_SERVE_NO_PUBLIC_BUILD` is the same stop the other way round.
- A port collision, or a `dev_servers.readiness_timeout_seconds` timeout, is reported rather than treated as a stop — the server may still come up, or the operator may need to look at what else is bound to the expected port, and a hard stop would foreclose either.

## Example

```
/docs-workflows:docs-serve ~/repos/example-docs
```

Resolves the repo, reads its `dev_servers` block, starts (or finds already running) the public server, and prints the host-visible URL — `public_base_url` when the profile records one, otherwise the in-container address with a caveat.

```
/docs-workflows:docs-serve --stop
```

Resolves the repo the same way, then stops the server this command has a record of running for it — or, where it has records for several ports, lists them and asks which.

## See also

- [`/docs-profile`](docs-profile.md) — writes the `dev_servers` block this command reads, and is what `DOCS_SERVE_NO_DEV_SERVER` points at.
- [`/document`](document.md) — the natural next step once the served site looks right: write or update the pages it covers.
- [Workflow overview](../workflow.md) — where this command sits among the setup utilities.
- [Session cost](../reference/session-cost.md) — why this command, like `/docs-profile`, emits no cost entry.

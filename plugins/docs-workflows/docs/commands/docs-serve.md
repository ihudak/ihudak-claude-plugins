# /docs-serve

Starts, stops, or checks a profiled documentation repository's dev server, and reports a URL that actually opens from the host.

## Who runs it

`/docs-serve` runs outside the role pipeline, the same way `/docs-profile` does — no role, no cost-attribution phase (it is one of the commands [Session cost](../reference/session-cost.md) names as emitting nothing), and no `workflows-core:model-routing` classification: it starts a process and reports a URL rather than reasoning about anything. [Workflow overview](../workflow.md) draws it beside `/docs-profile` in the setup-utility row, reached at any point rather than as a pipeline stage. It writes no documentation and no artefact, which is also why it carries no review gate — D17, the family rule that every artefact-writing command passes a high-tier review, names `/docs-serve` as its sole exemption.

## Synopsis

```
/docs-serve [<docs-repo-path>] [--internal] [--stop] [--status] [--build] [--port <n>]
```

Every recognized flag is stripped from `$ARGUMENTS` before the remaining token is read as the optional docs-repo path (Phase 0). `--status`, `--stop`, and `--build` each select a short-circuit mode (Mode dispatch); with none of the three, the command resolves the repo's `dev_servers` profile and serves it. `--internal` selects the internal build's server where the profile distinguishes one; `--port <n>` overrides the port this run checks and starts against, without rewriting the profile's own recorded command.

## What it needs

- **A profiled docs repository** — resolved by `resolve-docs-repo` (`docs-workflow/repo-resolution.md` §1), the same signal-positive ladder `/document` Phase 0 applies: the given path, else the working directory, else `$DOCS_PATH`, else a search under `$REPOS_PATH`, else a question — each rung tested against a docs-repo signal, and the rung that answered is reported.
- **A written `dev_servers` block** — `.dev-workflows/docs-profile.yml` (in the resolved repo, not the plugin), specifically its `dev_servers.servers[]` list. A repo that has never been profiled, or whose profile predates `dev_servers`, stops with `DOCS_SERVE_NO_DEV_SERVER` and points at `/docs-workflows:docs-profile` to write one.
- **Nothing from `$SPECS_PATH`** — this command runs no `specs-preflight` and no `commit-artifacts`. The only state it records lives under the resolved repo's own `.dev-workflows/`.

## What it produces

The default flow (Phase 1 onward) selects the server to run — by a profile's own `visibility` tag when one is recorded, by being the only server on offer, or by asking when several exist and neither applies — then checks whether it is already running (never starting a second copy of the same docs site on the same port), works around a port already held by something else by moving forward to the next free one and saying so, starts the chosen command bound to `0.0.0.0` so a container-mapped port stays reachable from the host, polls it for readiness, and reports the URL to open: the profile's own `public_base_url` when set, or the in-container address with an explicit caveat when not. It then records the pid and port under `.dev-workflows/` so a later `--status` or `--stop` — in the same session or a new one — can act on what this run started.

`--build` runs the profile's build command (from `builds[]`, `commands.per_space.<space>.build`, or `commands.build`, in that order) in the foreground and exits without serving — the flag exists instead of a separate `/docs-build` command, since the pipeline already gates on the profile's build. `--status` reports every server this command has a live record of for the resolved repo. `--stop` ends one.

## Gates

**No review gate, by design (D17).** This command writes no documentation and no other artefact — a start/stop/status/build run against a repo's own dev-server process — so there is nothing for a reviewer to check before it is trusted. Its closing report carries a `### Next step` line rather than a `choices` next-phase offer, and that offer states explicitly that it carries no `<merge-clause>`: nothing downstream ever waits on a pull request this run might have opened, because this run opens none.

## Failure modes

- `DOCS_SERVE_NO_DEV_SERVER` — the resolved repo's profile is absent, or present but records no `dev_servers` block. Run `/docs-workflows:docs-profile` against the repo first.
- `DOCS_SERVE_NO_BUILD_COMMAND` (`--build` only) — none of `builds[]`, `commands.per_space.<space>.build`, or `commands.build` resolves a command to run.
- A port collision, or a `dev_servers.readiness_timeout_seconds` timeout, is reported rather than treated as a stop — the server may still come up, or the operator may need to look at what else is bound to the expected port, and a hard stop would foreclose either.

## Example

```
/docs-workflows:docs-serve ~/repos/example-docs
```

Resolves the repo, reads its `dev_servers` block, starts (or finds already running) the public server, and prints the host-visible URL — `public_base_url` when the profile records one, otherwise the in-container address with a caveat.

```
/docs-workflows:docs-serve --stop
```

Resolves the repo the same way, then stops whatever this command has a live record of running for it.

## See also

- [`/docs-profile`](docs-profile.md) — writes the `dev_servers` block this command reads, and is what `DOCS_SERVE_NO_DEV_SERVER` points at.
- [`/document`](document.md) — the natural next step once the served site looks right: write or update the pages it covers.
- [Workflow overview](../workflow.md) — where this command sits among the setup utilities.
- [Session cost](../reference/session-cost.md) — why this command, like `/docs-profile`, emits no cost entry.

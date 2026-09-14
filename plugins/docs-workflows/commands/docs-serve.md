---
name: docs-serve
description: Start, stop or check the documentation site's dev server for a profiled docs repo, and report a URL that actually opens from the host. Reads the profile's dev_servers block; never starts a second server on a port that already answers; falls forward to the next free port on a collision and says so. --build runs the profile's build command and exits. Writes no documentation and no artefact.
allowed-tools: Read Bash Glob Grep Skill
---

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

Serve the documentation site for a profiled docs repo: $ARGUMENTS

`/docs-serve` runs a profiled documentation repository's own dev server and reports a URL that actually opens from the host — on any profiled repo, not only one `/docs-workflows:docs-init` scaffolded. It reads the `dev_servers` block `/docs-workflows:docs-profile` already wrote; it never picks a generator, a port, or a start command of its own. **It writes no documentation and no artefact** — no branch, no commit, no pull request, and (see Phase 0) no `specs-preflight`. **It also runs no review gate**: D17, the family rule that every artefact-writing command passes a high-tier review before it is trusted, names `/docs-serve` as its sole exemption — precisely because there is no artefact here for a reviewer to check.

**Signature:** `/docs-serve [<docs-repo-path>] [--internal] [--stop] [--status] [--build] [--port <n>]`

---

## Phase 0 — Resolve

Strip every recognized flag from `$ARGUMENTS` wherever it appears — `--internal`, `--stop`, `--status`, `--build`, and `--port <n>` (consumes the token immediately following it as its numeric argument) — before reading a positional token; the flags themselves are handled in **Mode dispatch**, below. What remains is the optional `<docs-repo-path>`.

Execute **`resolve-docs-repo`** from `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/repo-resolution.md` §1 — the signal-positive form, since this command needs a docs repo that already exists, never one to create. Do not restate its ladder here; the entry point owns it. Report which rung answered, per its own hard rule — a command that quietly works in an unexpected directory is expensive to unpick afterwards.

**No `specs-preflight`.** This is deliberate, not an omission: `/docs-serve` writes nothing into `$SPECS_PATH` — it starts a process in the resolved docs repo and reports a URL — so opening a branch discipline for a run with no artefact behind it would be ceremony. Its closest sibling is `/workflows-core:statusline`, not `/docs-workflows:document`: like that command, this one runs no `specs-preflight` and no terminal `commit-artifacts`. The only state it writes anywhere is Phase 7's pid/port record, under the resolved repo's own `.dev-workflows/` — never under `$SPECS_PATH`.

---

## Mode dispatch

Exactly one of `--status`, `--stop`, or `--build` drives this run; where more than one appears in `$ARGUMENTS`, the first encountered (left to right) wins, and the run says which of the others it ignored.

- `--status` → **`--status` mode**, below. Reports recorded state; starts nothing.
- `--stop` → **`--stop` mode**, below. Stops a recorded server; starts nothing.
- `--build` → **`--build` mode**, below. Runs the profile's build command; starts no server.
- None of the three → the default serve flow, **Phase 1** onward.

---

## `--status` mode

Read `<repo-root>/.dev-workflows/docs-serve.state.json` (Phase 7 writes it). Absent, or holding no entries → report `No /docs-serve state recorded for <repo>. Nothing appears to be running (a server started outside this command is invisible to --status).` and stop cleanly — an idle repo is the ordinary state, not an error.

Otherwise, for each recorded entry — one per port, the key Phase 7 writes: test the pid with `kill -0`, and re-probe the port and URL with the same reachability check Phase 2 uses. Report, per entry: port, space (and visibility, where recorded), pid, URL, and one of *running* (pid alive, port answering as recorded), *stale* (pid gone, or a live pid whose port no longer answers this docs site), or *unknown* (the probe itself failed); an entry recording no pid — see Phase 2 step 2 — is judged by its port alone, and says it has no pid. A selector narrows the report to the entries **Phase 7's lookup** returns for it: `--internal` is Phase 1's own server selection for `--internal`, looked up as that server — so only entries recorded for it are reported, which on the two-server profile `/docs-workflows:docs-init` writes means those that recorded `internal` — and a bare `--port <n>` is that port, matched against every entry. With neither given, every recorded entry is reported.

## `--stop` mode

Read the same state file. Select the entry to stop through **Phase 7's lookup**, always — never by space alone:

- A bare `--port <n>` argument is the port, matched against every entry — no prompt.
- An `--internal` flag is Phase 1's own selection (steps 1–3, `--port` override included) for `--internal` — the same selection a serve run makes, looked up as that server and at its port. The lookup takes only the entries recorded for the selected server — on a profile that tags its servers, the ones that recorded `internal` — and among them the one bound to the port that selection resolves or moved off it by a collision. So `--stop --internal` stops the server a `--internal` serve run started, given the same `--port` where that run carried one. On the two-server profile `/docs-workflows:docs-init` writes, that is the `internal`-tagged server and never its public twin of the same space — not even a public server an earlier collision moved onto the internal server's configured port, which a lookup by port alone would have returned.
- With neither given and exactly one entry recorded, stop that one — no prompt.
- With neither given and more than one entry recorded, resolve it the same way Phase 1 step 3 resolves an ambiguous server: the state file holds one entry per running server, as many as there are ports in use, with no count fixed anywhere, so the same cap applies. Print every recorded entry as prose above the prompt — its port, its space, and its visibility where recorded — then:
  - **Three or fewer entries** — `choices: ["port <port-1> — <space-1> (Recommended)", "port <port-2> — <space-2>", "port <port-3> — <space-3>"]` (2 or 3 options, matching however many are recorded; a recorded visibility is appended to its option, e.g. `port 8001 — docs (internal)`).
  - **Four or more entries** — `choices: ["port <port-1> — <space-1> (Recommended)", "port <port-2> — <space-2>", "port <port-3> — <space-3>", "Another entry from the list above — name its port"]`.

  The typed answer is resolved against the ports just printed — never parsed out of the free text.

For the selected entry: send `SIGTERM` to the recorded pid; wait up to 5 seconds for it to exit; `SIGKILL` if it has not. Remove the entry from the state file whether or not the pid was still alive — a pid already gone is stopped as far as this command is concerned, and leaving its stale entry behind is what breaks the next `--status`. Report what was stopped, or `Nothing recorded to stop for <repo>` when the file holds no matching entry. An entry recording no pid — one Phase 2 adopted where the socket table could not name the listening process — is reported as a server this command cannot stop, with its port, and left in place.

## `--build` mode

Run the profile's build command and exit without starting a server — this is the flag `/docs-serve` carries instead of a separate `/docs-build` command: the pipeline already gates on the profile's build (`${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md`'s field rules — an absent build command already disables `/docs-workflows:document`'s own gating build check), and a flag is cheaper than a whole command.

Resolve the command to run, most specific first:

1. The profile's `builds[]` list (the two-build MkDocs shape `/docs-init` scaffolds): `--internal` selects the entry whose `id` (or `visibility`) is `internal`; its absence selects `public`. Neither id present → fall through.
2. `commands.per_space.<space>.build`, where `<space>` is Phase 1's own selection logic, applied here even though this mode starts no server — the same space still identifies which build to run.
3. `commands.build` (flat).

No candidate resolves at any of the three → stop:

`DOCS_SERVE_NO_BUILD_COMMAND: <repo>'s profile records no build command (checked builds[], commands.per_space.<space>.build, commands.build). Run /docs-workflows:docs-profile <repo> to record one, or build by hand.`

Run the resolved command via Bash, in the foreground (this mode waits for it, unlike Phase 4's server start), from the repo root. Report its exit code and output; a non-zero exit is reported as a failed build, never swallowed.

---

## Phase 1 — Read `dev_servers` and select the server

Read `<repo-root>/.dev-workflows/docs-profile.yml` (`${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md`). The file absent, or present but carrying no `dev_servers` block, stops the run:

`DOCS_SERVE_NO_DEV_SERVER: <repo> has no dev_servers block recorded. Run /docs-workflows:docs-profile <repo> first — it detects a repo's *:start scripts and writes this block.`

`dev_servers.servers[]` is a list, one entry per server — `space`, `command`, `port`, and optionally `base_path`, `public_base_url`, and `visibility` (`docs-profile-schema.md`'s field rules). Usually that is one per servable space, but not always: the two-build profile `/docs-init` writes records **two** servers for its **one** space, a public and an internal one, told apart by `visibility` alone — which is why the state Phase 7 records is keyed by port and never by space. A space id still labels a row of step 3's picker, beside that server's port, since the servers step 3 offers carry no `visibility` to tell them apart. Select the entry this run serves:

1. Where an entry carries the declared `visibility` field (`public | internal` — it pairs a server with the `builds[]` entry of the same visibility, and the two-build MkDocs shape `/docs-init` scaffolds records one server per build, tagged to match), `--internal` selects the `internal`-tagged entry and its absence selects the `public`-tagged one.
2. Where no entry carries `visibility` and the list holds exactly one entry — the ordinary case for a repo with nothing to split, including a single-space profile with no two-build scaffold behind it — use it regardless of `--internal`, and say plainly that the profile records no public/internal split for this command to honour, rather than pretending `--internal` changed anything.
3. Where the list holds more than one entry and none carries `visibility`, ask — never guess, and never render an array sized to the list: `docs-profile-schema.md` fixes no upper bound on `dev_servers.servers[]` — it states the length of neither that list nor `spaces[]`, which is "required and non-empty" and nothing more — so a naive one-row-per-server array is a tool call `AskUserQuestion` rejects the moment a profile records five servers, not a long menu. This is the same shape `workflows-core:epic-picker` *The cap* exists for — a picker built from a directory listing, with no literal options for a static check to count — so resolve it the same way. Load the reference with `Skill(skill: "workflows-core:reference", args: "epic-picker")`; cited here as the authority rather than restated.

   Print every candidate `dev_servers.servers[]` entry as prose above the prompt, one line each — its `space` id and `port` — then:

   - **Three or fewer entries** — the array carries them all: `choices: ["<space-1> — port <port-1> (Recommended)", "<space-2> — port <port-2>", "<space-3> — port <port-3>"]` (2 or 3 options, matching however many are recorded; a one-entry list never reaches this rung — it resolves at step 2).
   - **Four or more entries** — the array carries the first three plus the overflow option: `choices: ["<space-1> — port <port-1> (Recommended)", "<space-2> — port <port-2>", "<space-3> — port <port-3>", "Another server from the list above — name its space and port"]`.

   The port is on every row because nothing in `docs-profile-schema.md` stops two untagged entries sharing a space id, and two rows reading the same id would be a choice the operator cannot make. The typed answer is resolved against the `space` ids and ports just printed — never parsed out of the free text (`workflows-core:epic-picker`'s closing paragraph states the same rule for its own picker). The worked two-space profile (`cloud`, `self-hosted`) reaches the three-or-fewer case: its two servers differ by space, not by visibility, so step 1 never resolves them and step 3 prints both and asks.

`--port <n>`, when given, overrides the selected entry's configured `port` for this run's own reachability checks (Phases 2 and 3 test `<n>`, not the profile's recorded port); it does not rewrite the entry's `command` — a command that hardcodes its own port (a baked-in `-a 0.0.0.0:8000`, say) is reported as such rather than silently overridden.

## Phase 2 — Already-running detection

Before starting anything, test whether the selected server is already up:

1. Read `<repo-root>/.dev-workflows/docs-serve.state.json` (Phase 7 writes it) and look this run's selection up by Phase 7's lookup — the server Phase 1 selected, at the port Phase 1 resolved, as overridden by `--port`. A returned entry whose pid answers to `kill -0` is the running server — including one an earlier run's Phase 3 moved to a later port, which the lookup finds by its `requested_port`. Report its recorded URL and stop. **Never start a second server.**
2. No living entry returned (a different session started it, the state was lost, or nothing has ever run) — probe the port directly. An unreachable port means nothing is listening: proceed to Phase 4. A port that answers needs identification, not just presence:
   - **A port a living recorded entry of another server is bound to is Phase 3's case, whatever the page says.** It is another of this repo's servers — typically one an earlier run's Phase 3 moved onto the selected server's configured port: the public twin of an internal server, or another space's server — and it names this docs site exactly as the selected server would.
   - Otherwise fetch the response and test it for something that actually names this docs site (the profile's `repo.name`, or the generator's own `site_name`, whichever the repo exposes). An answer carrying no such marker is Phase 3's case.
   - **A confirmed match where `dev_servers.servers[]` holds one server — tagged or not — is the same already-running case as step 1**: there is no other server it could be, so it is re-adopted. Report the URL and stop, recording an entry at that port into the state file in Phase 7's shape, since Phase 7 never ran for it this session — its `pid` read from the socket table, the process listening on that port (`lsof -t -iTCP:<port> -sTCP:LISTEN`, or `ss -ltnp` where `lsof` is absent). Where neither can name it, record the entry without a pid and say that `--stop` cannot end it.
   - **A confirmed match where `dev_servers.servers[]` holds more than one server cannot say which of them answered**: with no recorded entry behind it, every one of them renders a page naming this docs site. So report the URL as this docs site with its server unconfirmed, start nothing, and record nothing — a guessed identity is exactly the entry a later `--stop` would act on — and name a re-run with `--port <n>` as the way to serve the selected server on another port.

## Phase 3 — Port collision

The selected port answers, but not as the selected server — it is not this docs site, or it is another of this repo's servers (Phase 2 step 2). Never fail on this and never reuse the port silently: walk forward from it (`port + 1`, `port + 2`, …, capped at 20 attempts) with the same probe Phase 2 used, and take the first candidate that does not answer at all. Use that port for Phase 4, and **say so explicitly in the Phase 6 report** — a port-shifted stack (a project's ancillary services moved off their standard ports to coexist with another project's containers) is the normal case here, not the exotic one, and a silently shifted port is a URL the operator will not find. Exhausting 20 attempts without a free port is reported, never guessed past.

## Phase 4 — Start

Start the selected entry's `command` with the Bash tool's `run_in_background` option, from the resolved repo root — never from the plugin's own directory. **Bind `0.0.0.0`, never `localhost`**: a server bound to the container's loopback is unreachable from the host, which is where the browser is. The bind address is the recorded `command`'s own concern, not something this run rewrites — a `command` that only binds loopback (a bare `mkdocs serve`, whose default is `127.0.0.1:8000`) is reported as a profile defect, with the fix pointed at `/docs-workflows:docs-profile`, rather than patched here by guessing which flag the repo's generator wants.

## Phase 5 — Readiness

Poll the port this run resolved (Phase 1, as shifted by Phase 3) up to `dev_servers.readiness_timeout_seconds` (default 120 when the profile omits it), on a short interval, using the same reachability probe Phase 2 used. Stop polling the moment it answers and proceed to Phase 6. A timeout is reported, not treated as failure — the started command, its pid, and the elapsed wait are all in the report, so the operator can inspect a slow or wedged boot themselves rather than have a possibly-good server killed on a guess.

## Phase 6 — Report the host-visible URL

Report the URL the operator should open:

- The selected entry's `public_base_url`, when the profile sets one, reported verbatim — recorded for exactly this reason: a command running inside a container cannot infer the host's published port mapping.
- Otherwise the in-container URL, printed together with an explicit caveat naming the likely mismatch: this repo's profile records no `public_base_url` for this server, so if you are running inside a container this address may not be the one your browser can reach — check the container's published port mapping. **Never print a URL silently that may not open.** A port-shifted stack is the normal case, not the exotic one, and guessing the mapping would be wrong more often than right.
- Where Phase 3 shifted the port, restate that here regardless of which bullet above applies: a `public_base_url` the profile recorded was recorded against the *original* port, and may no longer point at the one actually serving.

## Phase 7 — Record state

Write (create, or merge into) `<repo-root>/.dev-workflows/docs-serve.state.json` via Bash — an object **keyed by the port actually bound** (after any Phase 3 shift, written as a string), each entry carrying `{space, visibility, requested_port, pid, url, command, started_at}`: `space` copied from the selected `dev_servers.servers[]` entry; `visibility` the visibility of the server this run started — that entry's `dev_servers.servers[].visibility`, the field `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md` declares — recorded wherever the profile tags the server; `requested_port` the port Phase 1 resolved before any Phase 3 shift; and `url` exactly what Phase 6 reported. `space` and `visibility` are the fields the lookup below filters an entry's server by. Writing at a port replaces whatever was recorded there, and what makes that correct is the successful bind, not a lookup: a port admits one listening server, so once the server this run started holds it, anything recorded at that port describes a process that no longer does. (Phase 2's lookup could not establish it: it consults only entries recorded for the selected server.) This is what lets `--status` and `--stop` (above) work in a later session without re-deriving anything.

**The key is the port because a port holds exactly one server, and a space id does not identify one.** The profile `/docs-workflows:docs-init` writes records **one** space served **twice** — a public server and an internal one, tagged by `visibility` — so a record keyed by space made the second server started overwrite the first one's entry: the process it described kept running past `--stop`, and `--status` could no longer see it.

**The lookup** — the one rule Phase 2, `--status` and `--stop` all apply, in two steps.

1. **Filter to the selected server.** A selection made through Phase 1 — every serve run, and `--internal` in `--status` or `--stop` — names one `dev_servers.servers[]` entry. Only state entries that recorded that entry's `space` and its `visibility` (or recorded none, where it has none) are candidates — `internal` for `--internal` and `public` for its absence on a profile that tags its servers — and an entry recorded for any other server is never returned, whatever port it holds. Where two of the profile's servers share a space and neither is tagged, those fields cannot tell them apart, so a candidate must also have been started for the selection's port: its `requested_port` is *P*. A bare `--port <n>` in `--status` or `--stop` names a port, not a server, and filters nothing.
2. **Match on port.** Among the candidates, the entries for the selection's port *P* are the one keyed at *P* and any whose `requested_port` is *P* — a server Phase 3 moved off *P* because something else held it.

Phase 2 wants the living one among what is returned; `--status` reports every one; `--stop` stops the one there is, and where there are several lists them as prose and asks, with its own picker above. Nothing here looks a server up by its space alone.

**The bound port stays the key; the filter exists because the requested port is not exclusive.** Only one live server can hold a port, so the key never has to tell two live servers apart. But a server Phase 3 moved onto another server's configured port is keyed there: a public server moved onto the internal server's port — say 8001 — or one space's server moved onto the next space's. A lookup by port alone hands the selection for that port the wrong server: Phase 2 reports it as the selected one already running, and `--stop --internal` stops the wrong process. Filtering on the server each entry recorded, before any port is matched, is what rules that out.

This file is repo-local bookkeeping, not a pipeline artefact: it is never staged and never committed. **Ignore the file itself, never its directory**: `.dev-workflows/` also holds `docs-profile.yml`, which *is* committed and which `/docs-workflows:document`, `/docs-workflows:docs-brand` and this command all read, so an ignore rule for the whole directory would silently drop the profile from the next commit that touched it. The line is `.dev-workflows/docs-serve.state.json`, and a repository `/docs-workflows:docs-init` scaffolded already carries it (`${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/scaffold-tree.md` §7).

---

## Next step

End the report with a `### Next step` line, per `Skill(skill: "workflows-core:reference", args: "next-phase-offer")`'s Surface section — the universal-minimum prose form; this command offers no `choices` array here, since a running server has nothing to pick between. On a successful serve, recommend reviewing the site at the reported URL, then `/docs-workflows:document <address>` to write or update pages once satisfied, and `/docs-workflows:docs-serve --stop` when done. On `--stop` / `--status` / `--build`, state plainly what ran and stop there — none of the three has a forward step of its own.

**This offer carries no `<merge-clause>`.** `workflows-core:next-phase-offer`'s merge-clause rule applies where an offer names a downstream command whose `require-on-main` gate is fed by *this run's own artefact* — and `/docs-serve` writes no artefact and runs no `handoff-to-main` (D17; this file's own Phase 0 note), so nothing downstream is ever waiting on a pull request this run might have opened. The same reasoning the reference gives for `/product-workflows:brd-proposal` applies here: an offer that names no gate its own run feeds carries no clause. `scripts/check-docs.sh` check 11 only asserts the placeholder across the `/product-workflows:brd-*` and `/product-workflows:prd-*` families — no `/docs-*` glob is in its scope — so nothing enforces this for `/docs-serve`; it is stated here by discipline, for the next maintainer who adds a `/docs-*` offer that *does* name a fed gate, to hold it to the same rule the check does not check.

---

## Invariants (always enforced)

- ALWAYS resolve the docs repo via `resolve-docs-repo` (`${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/repo-resolution.md` §1) and report which rung answered
- NEVER run `specs-preflight` or `commit-artifacts` — this command writes nothing into `$SPECS_PATH`
- NEVER run a review gate — D17's sole exemption: this command writes no artefact, so there is nothing for a reviewer to check before it is trusted
- NEVER emit a cost entry — `/docs-serve` starts a process and reports a URL; there is no dev/PM spend here to attribute against a PRD (`docs/reference/session-cost.md`)
- ALWAYS bind `0.0.0.0`, never `localhost`, for a server this command starts
- NEVER start a second server on a port that already answers as this docs site — detect and report the existing one instead (Phase 2)
- ALWAYS say so explicitly when a port collision shifts the serving port (Phase 3) or when `public_base_url` is absent (Phase 6) — never print a URL silently that may not open
- ALWAYS record pid/port state under the resolved repo's own `.dev-workflows/`, never under `$SPECS_PATH` — keyed by the port actually bound, NEVER by space id, with the space and visibility of the server started; and ALWAYS look a selection up by Phase 7's lookup, filtering on the server each entry recorded before matching a port — a space id does not identify a server when one space is served twice, and a port alone does not either once a collision has moved one server onto another's configured port
- NEVER re-adopt an unrecorded server by guessing which one it is — a profile with one server re-adopts and records it; a profile with more than one reports the match as unconfirmed and starts nothing (Phase 2 step 2)
- NEVER tell a repo to gitignore `.dev-workflows/` — only `.dev-workflows/docs-serve.state.json`; the directory also holds the committed profile
- ALWAYS use `choices` arrays for a genuine disambiguation; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself. Where the candidate set is unbounded (Phase 1 step 3, `--stop` mode) — a `dev_servers.servers[]` list or a state-file list, neither with a count fixed anywhere — the array is never sized to the list itself: print every candidate as prose first, then cap the array at three concrete rows plus one overflow option, per `workflows-core:epic-picker` *The cap*
- ALWAYS reference this plugin's own bundled files with `${CLAUDE_PLUGIN_ROOT}`; the one `workflows-core` citation (`next-phase-offer`) is loaded through `Skill(skill: "workflows-core:reference", args: "next-phase-offer")`, never by path

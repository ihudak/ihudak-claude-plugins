# Render verification (example-docs)

How `/document` Phase 6.5 proves the documentation it just wrote builds
and renders.

This is the single source of truth for the mechanics; Phase 6.5 cites it and
stays lean. Read every path, command, and port from the resolved `profile` — do
not hard-code example-docs specifics.

"Affected pages" = every file written or modified in Phase 6.3.

## 1. Build vs boot

Resolve the builds to run, most specific first — the precedence `/docs-serve --build` already uses:

1. **`profile.builds[]`, where the profile records it** — run **every** entry's `command`, in list
   order. Those entries are the builds one content root renders into (`docs-profile-schema.md`'s
   field rules): the profile `/docs-init` writes records a public and an internal build over its one
   root, and an internal-only page is compiled by the internal build alone, so a check that ran one
   of them would pass a page the other cannot build.
2. **Otherwise, per space** — `profile.commands.per_space.<space>.build` when the profile declares
   one for that space, else the flat `profile.commands.build`, run for every space in the
   **verification set** defined in §2 — every space whose `content_root` holds at least one affected
   page. For example-docs the two commands are `pnpm cloud:build` and `pnpm self-hosted:build` — both
   exist, and an earlier version of this file wrongly claimed the repo had only `commands.lint` and
   the `*:start` servers, which disabled this gate entirely.

**Each build is recorded on its own**, named by its `builds[]` `id` — or, at rung 2, by its space —
with its command, its exit code and, where it failed, its output. A failure therefore names the build
that failed, and the `doc-fixer` loop a content failure triggers (`/document` Phase 6.5 Step 1) is
handed that build's own output, never a merged log.

Phase 6.5 does NOT re-run the prose linter — that is Phase 6.4's `docs-style-checker`.

Only when a repo genuinely declares **no** build command at any of the three levels — no `builds[]`,
no `commands.per_space.<space>.build`, no `commands.build` — does the **dev-server boot become the
build proof** — a server that boots and serves HTTP 200s proves the content compiled. That is a
fallback for repos without a build, not a description of example-docs.

## 2. Sequential dev-server smoke-check

`profile.dev_servers.concurrent: false` means one server at a time.

**The verification set — which spaces to build and boot.** Match every affected page against each
`profile.spaces[].content_root`/`snippet_root` prefix; the set is the spaces those matches name. A
repo declaring one content root always yields one space; a repo declaring several yields only the
ones this run actually wrote into. A space that owns no affected page is neither built nor booted —
nothing changed in it.

This set governs **both** gates: §1's build check, on a profile that records no `builds[]`, runs each
of its spaces' build commands (with `builds[]` it runs every entry, since they all render the one
content root), and the smoke-check below boots, for each of them, the servers that publish its
affected pages.

The two operative consumers — `/document` Phase 6.5 Steps 1 and 2 — restate this set inline rather than citing it alone, Step 1 restates §1's choice of builds the same way, and Step 2 restates the choice of server below. That duplication is deliberate: those are instructions a model acts on in one pass, and it may not follow a cross-reference before deciding which servers to boot. Keep every restatement in sync with this definition and do not collapse them into a bare citation. Descriptive references elsewhere (`gate-ledger.md` §4's registry, `docs-profile-schema.md`'s field rules) cite this section and should stay short.

**Which server checks a page.** `profile.dev_servers.servers[]` is a list, not a map keyed by space, and a
space id does not identify a server: the two-build profile `/docs-init` writes records **two** servers
for its **one** space, a public and an internal one, told apart by `visibility` alone
(`docs-profile-schema.md`'s field rules). So the server is chosen **per affected page**, never by the
space alone. For each space in the verification set, take the `servers[]` entries whose `space` is
that space's `id`:

- **One entry** — it checks every affected page in the space.
- **Two entries, one tagged `visibility: public` and the other `visibility: internal`** — a page is
  checked on the public server unless the public build excludes it, and then on the internal
  server. Which pages the public build excludes is
  `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/visibility.md` §1's to decide (**the model**), not
  this file's.
- **Any other set of more than one** — two untagged entries, two carrying the same visibility, or
  more than two — nothing tells them apart, and a guessed server is a false result either way: a page
  checked on a server whose build excludes it fails a check it would pass on the other, and a page
  checked on the server that does not publish it passes while the build that does is never booted.
  Record "smoke-check skipped for `<space>`: `<n>` servers share it and nothing tells them apart" and
  use the manual table for that space.
- **No entry** — record "smoke-check skipped for `<space>`: no dev server is recorded for it" and use
  the manual table for that space.

Then boot the chosen servers one at a time — the verification set's spaces in order and, within a
space, its public server before its internal one — skipping any server no affected page was assigned
to. On a profile with one server per space, that is one boot per space in the set.

A port **answers** while something accepts a connection on it: any HTTP status, an error included, is
an answer, and only a refused connection is not (`curl -s -o /dev/null --max-time 2
http://localhost:<port>/` exits 7). Every probe below is this one, and it needs no socket tool. For
each server:

1. Verify prerequisites (§4) — best-effort, never applied.
2. **Probe the server's `port` before booting it.** Where it already answers, something this run did
   not start holds it: boot nothing there, signal nothing, and **boot no further server** — record
   "smoke-check stopped at `<space>`: port `<port>` was answering before its server booted", and
   every page not yet checked falls back to the manual table (§5). Otherwise boot the server's
   `command` in the background, with every `{port}` in it replaced by that server's configured
   `port` — never run with the token unsubstituted, and never rewritten anywhere else
   (`docs-profile-schema.md`'s field rule for `dev_servers.servers[].command`) — and hold whatever
   pid the start returns, where it returns one. That pid is usually a wrapper's — the Bash tool's
   shell, an `npm` or `pnpm` script — whose child holds the port and outlives it, so it is step 5's
   fallback, never its first choice.
3. Readiness poll: GET `http://localhost:<port><base_path>/`, that server's own, until HTTP 200 or
   `profile.dev_servers.readiness_timeout_seconds` seconds elapse (fall back to **120** when the
   field is absent). **Once the port answers, read its listener's pid from the socket table**, as
   `/docs-serve` Phase 5 does, by the definition in `${CLAUDE_PLUGIN_ROOT}/commands/docs-serve.md`
   Phase 2, **The evidence**, item 1's opening paragraph: `lsof`, else `ss`; where several processes
   are named, the one the others descend from; where neither tool is present, or the one present
   names nothing, no listener is named. That definition is all that carries over. Not its
   **Checkout first** test — this run started the server itself, on a port step 2 found silent, so
   whatever now holds that port is this run's — and not its Phase 7 living-entry test, which judges a
   pid recorded in a state file: this command keeps none, and the pid it reads here is used once, by
   step 5 of this same boot, and never recorded. On a timeout, stop the server as step 5 says — the
   signal, then the probe — and record "smoke-check skipped for `<space>`: not ready".
4. For each affected page assigned to this server, GET its derived URL (§3): HTTP 200 passes, and
   §5 gives a 404 and a 5xx their one disposition each.
5. **Stop the server by its listener's pid** — or, where step 3 named no listener, by the pid step 2
   holds, where it holds one: `SIGTERM` it, wait up to 5 seconds for the port to stop answering, and
   `SIGKILL` the same pid if it still answers. **Then probe the port** — the probe, not the signal,
   decides whether the server stopped. Where the port no longer answers, boot the next server. Where
   it still answers — a wrapper's child that outlived the pid signalled, or a server something
   restarted — **boot no further server**: record "smoke-check stopped after `<space>`: port
   `<port>` still answers — left running", with its listener's pid where the socket table names one,
   and every page not yet checked falls back to the manual table (§5). A missing socket tool alone
   never ends the check; only a port that answers when it should be silent does — here, or before a
   boot (step 2).

Never run two servers at once: the next server boots only once the probe has found the last one's
port silent. Where a space has two servers, every record this file names for `<space>` names the
server as well — `docs (internal)`.

## 3. Route derivation

The page URL is `http://localhost:<port><base_path>/<route>`, where `<port>` and
`<base_path>` come from the `dev_servers.servers[]` entry §2 chose for the page
(no `<base_path>` where that entry records none) and `<route>` is
the page path relative to its space's `content_root` with a trailing `index.md`
or `.md` removed. Example: `cloud/_content/setup/foo/index.md` in the `cloud`
space (`base_path: /docs`, port 4000) → `http://localhost:4000/docs/setup/foo`.

This is best-effort, so a 404 cannot tell a wrong route from a missing page. A
404 on an affected page is surfaced as ❌ with its URL and the page stays on the
manual table; it is never a content failure by itself (§5).

## 4. Prerequisites (best-effort, never auto-applied)

`profile.prerequisites` lists what a dev server may need before `*:start` boots
(e.g. a working `.docstack` toolchain / an axios shim). Phase 6.5 **checks** a
prerequisite but NEVER applies it — the `.docstack` workaround is a local,
gitignored, reversible dev-environment hack and is out of scope for an automated
run. If a prerequisite is unmet, record "smoke-check skipped for `<space>`:
prerequisite `<x>` unmet" and use the manual table for that space.

## 5. Graceful fallback and the pages-to-visit table

The smoke-check is best-effort. Any prerequisite-unmet, boot-failure, or
readiness-timeout outcome is recorded with its reason and falls back to the
manual table for that space — on a space with two servers, for that server's
pages — and it never blocks the run. A port that answers before its server
boots, or still answers after the stop (§2 steps 2 and 5), ends the
smoke-check rather than one space's part of it: every page not yet checked
falls back to the manual table, and the record names the port left running —
it never blocks the run either.

A 404 and a 5xx on an affected page are both surfaced, never silently dropped,
and each has exactly one disposition:

- **404** — ❌ with its URL, and the page stays on the manual table. It is
  **never a content failure by itself** and never dispatches `doc-fixer`: §3's
  route is best-effort, so a 404 cannot tell a wrong route from a missing page,
  and §1's build check — which runs every build that compiles an affected page —
  owns compile failures.
- **5xx** — a render defect: a content failure, handled exactly as a build's
  content failure (`/document` Phase 6.5 Step 1), because a server error is not
  a routing question.

The **pages-to-visit table** is always emitted, one row per affected page: its
URL on the server §2 chose for it (§3) and what to verify ("confirm the page
renders as intended"). A page §2 chose no server for gets its route on each of
its space's servers, or the route alone where the space records none. When the
smoke-check ran, annotate each row ✅ 200 / ⚠️ skipped (reason) / ❌ with its
status.

**Static analysis is necessary but never sufficient.** A clean link-integrity grep and a verified
page structure corroborate the render gate and neither satisfies it. Static greps do not catch
template compile errors, do not prove an included snippet resolves, and do not prove a postid
resolves in the build. A run that has only static evidence has not run this gate — record
`render_smoke_check` accordingly.

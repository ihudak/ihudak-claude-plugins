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

Every build runs from `<docs_repo_path>` — the docs repository's git top level (`/document` Phase 0
step 2), which is where every command the profile records runs (`docs-profile-schema.md`, **Where
the profile lives**) — and so does every dev-server command §2 boots.

**Each build is recorded on its own**, named by its `builds[]` `id` — or, at rung 2, by its space —
with its command, its exit code and, where it failed, its output. A failure therefore names the build
that failed, and the `doc-fixer` loop a content failure triggers (`/document` Phase 6.5 Step 1) is
handed that build's own output, never a merged log.

Phase 6.5 does NOT re-run the prose linter — that is Phase 6.4's `docs-style-checker`.

The **dev-server boot becomes the build proof** — a server that boots and serves HTTP 200s proves
that what its build compiles compiled — in two cases, and only there. One is a repo that genuinely
declares **no** build command at any of the three levels — no `builds[]`, no
`commands.per_space.<space>.build`, no `commands.build` — where every server §2 boots stands in.
The other is a build that will not run for an environmental reason — its tool missing, a missing
`.docstack` shim — while the tools its boot needs are present: the smoke check's own, which §2's
tool check names (`bash`, `curl`, and off Linux `ps`), and the tool of the command of one of **that
build's own servers**, the servers that publish what it compiles — for
a `builds[]` entry, the server whose `visibility` pairs with the entry's; for a space's
`commands.per_space.<space>.build`, that space's servers; for the flat `commands.build`, every server
§2 boots. Another build's server is never the proof: it compiles another space or another
configuration. A command's tool is the one
`${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` §2 defines (never a leading `cd`, which
every shell has), tested as its §3 tests it (a tool containing `/` by `test -x` from the directory
the command runs from, never by `command -v` from the working directory), a package manager whose
dependencies are not installed counting as missing (§2 step 1). That is `build_check`'s
registered fallback running, recorded `DEGRADED` rather than skipped (`/document` Phase 6.5 Step 1).
Either way it is a fallback, not a description of example-docs, which declares both builds and whose
servers need the same `pnpm` as its builds.

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

A port **answers** while something listens on it. The probe is
`command curl -s -o /dev/null --noproxy '*' --max-time 2 http://localhost:<port>/`, read by its exit code
alone:

- **7** — the connection was refused: the port does not answer.
- **127** — curl could not run at all (not installed, or not on `PATH`): **no answer either way**,
  neither an answering port nor a quiet one.
- **Any other code** — the port answers: a listener took the connection or left it waiting (an HTTP
  status, an error included, an empty reply or a reset, or 28 when `--max-time` runs out on a
  listener that never replies).

**A port is free only where nothing answers on it and no socket a process holds uses it as its local
port.** The probe settles the first half; **Portability**'s socket-state read (below) settles the
second, in any state — a listener bound to an address `localhost` does not reach, an inbound
connection, an outbound one. A port an outbound connection holds as its local end answers nothing and
binds nothing: a server given it exits with *Address already in use* (measured on Linux 5.15 with a
`curl --local-port` connection standing on the port, against `mkdocs serve -a 0.0.0.0:<port>` and
`python3 -m http.server`), and every port in the kernel's ephemeral range — 32768–60999 on a default
Linux — is one an outbound connection of any process on the host may be holding. **A socket no process
holds is not one of these**: a connection in `TIME_WAIT`, or one whose process has already closed it,
which `/proc/net/tcp` gives inode `0` and which `lsof` does not list at all. Counting those would take
a port from the server that just left it — a server's own closed connections sit in `TIME_WAIT` on its
port for up to a minute after it stops, and `mkdocs serve` and `python3 -m http.server` both bind such
a port again at once (measured). What that leaves is a *client's* `TIME_WAIT` on the port, which does
refuse a bind for that minute; a server started there exits with *Address already in use*, which step
3's gone-group test reports with the command's log, as it reports any other boot failure. Where the
socket-state read cannot be made at all — off Linux with no `lsof` installed, which never ends this
check on its own — the probe alone decides, as before.

Every **GET** below — step 3's readiness poll and step 4's page requests — is
`command curl -sL -o /dev/null -w '%{http_code}' --noproxy '*' --max-time 10 <url>`, read by the status it
prints: the last response's, since `-L` follows a redirect — `mkdocs serve`, for one, answers §3's
route, which carries no trailing slash, with a 302 to the same path with one — and `000` where no
response came. **Every request this check makes carries `--noproxy '*'`**, because each is meant
for a server on this machine: with `http_proxy` or `ALL_PROXY` set and no `no_proxy` naming
`localhost`, curl hands a request for `localhost` to the proxy instead, which answers it — exit 0
on a port nothing listens on, so a free port reads as answering, and the proxy's own page in place
of the server's.

Every probe below is the exit-code probe defined first, and it needs no socket table. **A probe that
cannot run is never read as an answer or as silence**, so the check does not start without its
tools: before the first boot, confirm that `bash` and `curl` are present and, where
`test -r /proc/net/tcp` fails — off Linux — that `ps` is too, each tested as
`${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` §3 tests a tool run through `bash -c` or
as `command <name>`, never by a bare `command -v`, which an alias or a shell function of that name
passes. Step 2 boots under `bash` and reads the process group it made, and step 5 signals that
group under `bash` and reads its members
and a listener's parents: on Linux those reads come from `/proc`, which needs nothing installed, and
elsewhere from `ps` (**Portability**, below, defines each). Where one is missing, boot nothing, record "smoke-check unavailable: `<tool>` is not installed", and every page goes
to the manual table (§5); `/document` Phase 6.5 records that on `render_smoke_check` as `DEGRADED`,
never `UNAVAILABLE`, since the manual table is that gate's registered fallback (`gate-ledger.md` §4)
and needs no tool. A probe that exits 127 anyway, part-way through, ends the check the same way:
boot no further server, signal the process group of one this run already booted as step 5 does
(its signals need neither `curl` nor `ps`), record "smoke-check unavailable: curl could not run
(exit 127) — `<space>`'s server was signalled, and its port could not be probed; its log is
`<log>`", and every page not
yet checked goes to the manual table. For each server:

1. Verify prerequisites (§4) — best-effort, never applied. **Then check the server's command's
   tool** — the tool `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` §2 defines, tested as
   its §3 tests it, for a command that runs from `<docs_repo_path>`: the check `/docs-serve` makes
   before it starts a server (its Phase 4), and the one §1 makes for a failed build's own servers.
   **A package manager whose dependencies are not installed counts as missing too**, since a server
   run through it fails as completely as one whose tool is absent; `/docs-serve` Phase 4 and
   `/document` Phase 6.5 Step 2 cite this step for the rule. Where the tool is `pnpm`, `npm` or
   `yarn`, find its lockfile — `pnpm-lock.yaml`, `package-lock.json` or `yarn.lock` — in the
   directory the command runs from or the nearest directory above it that holds one, up to
   `<docs_repo_path>`. Where one is found with no `node_modules/` beside it, and, for `yarn.lock`, no
   `.pnp.cjs` beside it either — a Yarn Plug'n'Play install keeps that file instead of
   `node_modules/` — the tool counts as missing. Where no lockfile is found, only the tool itself is
   tested. That is `toolchain-preflight.md` §2 source 2's installed-dependencies signal, which its §5
   also counts for `build_check`'s fallback. Where the tool is missing, boot nothing for this server:
   record "smoke-check skipped for `<space>`: `<tool>` is not installed" — or, where its
   dependencies are what is missing, "smoke-check skipped for `<space>`: `<tool>`'s dependencies
   are not installed (`<lockfile>` has none beside it)" — its pages fall back to the manual table
   (§5), and the check goes on to the next server. A server whose tool is missing could never
   start, so it is never booted, and the check never waits out step 3's readiness timeout for it.
2. **Probe the server's `port` before booting it, and judge it free as this section defines free.**
   Where it already answers, something this run did not start holds it: boot nothing there, signal
   nothing, and **boot no further server** — record
   "smoke-check stopped at `<space>`: port `<port>` was answering before its server booted", and
   every page not yet checked falls back to the manual table (§5). Where nothing answers but the
   socket-state read (**Portability**) names a socket a process holds on the port as its local port —
   an outbound connection's local end, which no server can bind — do exactly the same, recording
   "smoke-check stopped at `<space>`: port `<port>` was held as a connection's local end before its
   server booted", with that socket's pid where the read names one. Otherwise **boot the server in a
   process group of its own**, with this one Bash call:

   ```
   command bash -c 'set -m; (cd <docs_repo_path> && <command>) > <log> 2>&1 & echo $!'
   ```

   `<command>` is the server's `command` with every `{port}` in it replaced by that server's
   configured `port` — never run with the token unsubstituted, and never rewritten anywhere else
   (`docs-profile-schema.md`'s field rule for `dev_servers.servers[].command`) — and `<log>` is a
   file outside every repository tree (`command mktemp -t dw-smoke-XXXXXX` names one), where a server
   that fails to boot leaves its output. Inside the single-quoted script, write each `'` that
   `<command>`, `<docs_repo_path>` or `<log>` carries as `'\''`. **The line runs under an explicit
   `command bash -c`, whatever shell the Bash tool itself uses** — Claude Code runs that tool in
   bash or in zsh, zsh on a default macOS — so job control, `$!` and step 5's group signals are
   bash's semantics everywhere; `/bin/bash` ships with macOS (3.2), which has all three. `set -m`
   turns job control on, so the background job leads a
   new process group whose id is the pid `echo` prints, and every wrapper and child the command
   spawns — an `npm` or `pnpm` script, the `sh` it runs, the server itself — inherits that
   group, unless one leaves it for a session of its own — step 5 meets that one only by a port it
   already holds. That is why the command keeps its server in the foreground and never detaches it
   (`docs-profile-schema.md`'s field rule for `dev_servers.servers[].command`): a detaching command
   is a profile defect, and a server it moves out of the group — as `setsid` and `docker run -d`
   do — is one this check can neither stop nor see bind late. The job outlives the call, which
   returns as soon as the pid is printed. **Then confirm the group:** read `<pid>`'s process group
   as **Portability** (below) reads one — from `/proc/<pid>/stat` on Linux, with
   `command ps -o pgid= -p <pid>` elsewhere — and it is `<pid>`, or nothing, where the job has
   already exited, and the id still names whatever of it survives. That `<pid>` is the `<pgid>`
   step 5 signals. Where it is any other number, job control gave the job no group of its own:
   hold the pid alone, and step 5 stops it by its path for a server without a group.
3. Readiness poll: GET `http://localhost:<port><base_path>/`, that server's own, until HTTP 200 or
   `profile.dev_servers.readiness_timeout_seconds` seconds elapse (fall back to **120** when the
   field is absent). **At every interval at which the GET gets no response** — it prints `000` —
   **test the group too**, where step 2 holds a `<pgid>`, by step 5's test for a gone group:
   `command bash -c 'kill -0 -- -<pgid>'` fails, or every member of the group is a zombie. **A gone group
   ends the poll at once**, as `/docs-serve` Phase 5's poll ends: the command exited without its
   port answering — a theme that is not installed, a configuration it cannot load, a script its
   package does not have — and nothing of its group is left to bind the port later, so the check
   never waits out the timeout for it. Record "smoke-check skipped for `<space>`: its server exited
   before it was ready — its command was `<command>`", with the last twenty lines of `<log>`; its
   pages fall back to the manual table (§5). Then probe the port as step 5 confirms
   a stop — the group being gone already, the probe decides: quiet, the check goes on to the next
   server; still answering, a process outside the group holds it, and step 5's **Either not
   confirmed** applies. Where step 2 holds no `<pgid>`, the poll has no group to test and runs to
   its timeout. On a timeout, stop the server as step 5 says. Where step 5 confirms it stopped,
   record "smoke-check skipped for `<space>`: not ready", its pages fall back to the manual table
   (§5), and the check goes on to the next server: nothing of the group survives to bind the port
   later. Where step 5 cannot confirm it, step 5's record ends the check. **A server without a group
   of its own ends the check on a timeout**, because nothing can tell whether a process of it will
   bind the port after the check has moved on: stop what the run holds as step 5 says, then **boot no
   further server** — record "smoke-check stopped at `<space>`: not ready, and started without a
   process group of its own — port `<port>` may still bind; its command was `<command>`, its log
   `<log>`", and every
   page not yet checked falls back to the manual table (§5).
4. For each affected page assigned to this server, GET its derived URL (§3): HTTP 200 passes, and
   §5 gives a 404 and a 5xx their one disposition each.
5. **Stop the server by signalling its process group** — after its pages and after a readiness
   timeout alike:
   1. `command bash -c 'kill -TERM -- -<pgid>'`; wait up to 5 seconds for the group to be gone; where it
      is not, `command bash -c 'kill -KILL -- -<pgid>'` and wait up to 5 seconds more, since a killed
      process stays in its group until its parent reaps it.
   2. **Confirm two things:** the group is gone and the port is quiet — the probe no longer finds it
      answering. **The group is gone** where `command bash -c 'kill -0 -- -<pgid>'` fails, **or** where
      every member of `<pgid>` is a zombie — the states **Portability** (below) reads for the
      group's members are all `Z`, or on a `ps` all begin with `Z`. A zombie runs nothing and holds
      no port; it has exited, and stays in its group only until its parent reaps it, which a parent
      that never reaps — a container whose PID 1 is `sleep infinity`, with no init — never does, so
      `kill -0` alone would call that group running for good.
   3. **Both confirmed** — the next server may boot.
   4. **Either not confirmed** — where the port still answers, a process outside the group holds it
      (one that left for a session of its own, or a server something restarted): read its listener's
      pid from the socket table, as `/docs-serve` Phase 5 does, by the definition in
      `${CLAUDE_PLUGIN_ROOT}/commands/docs-serve.md` Phase 2, **The evidence**, item 1's opening
      paragraph — the processes **Portability**'s socket-table read (below) names for the port, from
      `/proc` on Linux and with `lsof` elsewhere; where several are named, the one the others descend
      from; where it names none, or off Linux no `lsof` is installed to read it, no listener is named —
      then `SIGTERM` it, wait up to 5 seconds for the port to stop answering, `SIGKILL` it if it still
      answers, and confirm both things again. That definition is all that carries over. Not its
      **Checkout first** test — this run started the server itself, on a port step 2 found silent, so
      whatever now holds that port is this run's — and not its Phase 7 living-entry test, which
      judges a pid recorded in a state file: this command keeps none, and the pid it reads here is
      used once, by this stop, and never recorded. Where either is still not confirmed, **boot no
      further server**: record "smoke-check stopped after `<space>`: `<what>` — left running; its
      command was `<command>`, its log `<log>`", where `<what>` is "port `<port>` still answers",
      with the listener's
      pid where the socket table names one, or "process group `<pgid>` still runs", and every page
      not yet checked falls back to the manual table (§5).

   **A server without a group of its own** (step 2) is stopped by what the run holds: `SIGTERM` the
   pid step 2 holds and, where the port answers, its listener, read as above; wait up to 5 seconds
   for the port to stop answering; `SIGKILL` both if it still answers. Then the probe decides: where
   the port is quiet, the next server may boot — unless this stop followed a timeout, which ends the
   check (step 3); where it still answers, boot no further server, recorded as above.

   **A server's `<log>` goes once the server is confirmed stopped.** Wherever step 5's two things
   are confirmed — after its pages, after a readiness timeout, or after step 3 found its group gone
   — and wherever a server without a group of its own is stopped with its port quiet and no timeout
   behind it, remove its log with `command rm -f -- "<log>"`, once any record has quoted what it
   needs from it: nothing else would remove it, and `command` keeps an `rm` alias or function of the
   user's out of it (**Portability**). A server the check cannot show stopped — one it leaves
   running, one without a group of its own that timed out, or one it signalled when `curl` could not
   run — keeps its log, and the record that ends the check names it.

   A missing `lsof` alone never ends the check. What ends it is a port that answers when it
   should be silent — before a boot (step 2) or after the stop — a group that will not go, a
   readiness timeout on a server without a group of its own (step 3), or a probe that cannot run
   (above).

**Portability.** The shell semantics above are bash's, by step 2's and step 5's explicit `command bash -c`.
`curl -s -o /dev/null --noproxy '*' --max-time 2`, the GET's
`curl -sL -o /dev/null -w '%{http_code}' --noproxy '*' --max-time 10`, `awk -v`, and `mktemp -t` —
which BSD reads as a prefix rather than a template and which still names a fresh file, and whose
template ends in `XXXXXX`, the only ending BusyBox's accepts — are called in forms BSD's and
BusyBox's tools document as well as GNU's.

**Every read of the process or socket table has one source per operating system, defined here** —
this check's, and `/docs-serve`'s, which cites this paragraph for each of them. **On Linux** —
wherever `test -r /proc/net/tcp` succeeds — every read comes from the kernel's own tables under
`/proc`, which need no tool beyond the standard utilities `cat`, `sed`, `awk`, `ls` and `tr`, and no root
for this user's own processes. **Anywhere else** — macOS ships both — they come from `lsof` for the
socket table and a working directory, and from `ps` for the rest. A host uses one source, never a
mix, and a Linux host needs neither `lsof` nor `ps`: BusyBox's `ps`, the one Alpine ships, cannot
select a process with `-p` at all, and nothing here reads `ss`.

**Every utility in these reads runs as `command <name>`, and the socket read's `ls` as
`QUOTING_STYLE=literal command ls` — both are load-bearing, so neither is to be simplified away.**
Each read runs in the Bash tool's own shell, which carries the user's aliases and shell functions
— Claude Code's shell snapshot re-applies them, with alias expansion on — and the environment the
terminal that launched it exported. An `ls` alias carrying `-F` appends `=` to the link target,
one carrying `--color=always` wraps it in escape sequences, `-Q` quotes it and `-L` prints no
target at all, and an exported `QUOTING_STYLE` of `shell`, `shell-escape`, `shell-always` or `c`
quotes it too: each leaves the target unequal to `socket:[<inode>]`, so the read names no process
while `lsof` and `ss` name the listener, and nothing in its output says so. An alias on any other
utility here changes what the read parses the same way. `command` skips aliases and shell
functions — a POSIX utility, checked in bash, dash and BusyBox's `ash` — and the variable pins GNU
`ls`'s quoting, which BusyBox's `ls` ignores. **The probe and the GET run `curl` the same way, as
`command curl`, and every call on a process group runs `bash` as `command bash`**: `command` runs the
binary `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` §3 tested for, where a `bash` function
of the user's would otherwise answer `kill -0` for a group it never looked at (bash 5.2 and zsh 5.8:
exit 0 for a gone group, where `command bash` exits 1).

- **The processes holding a listening socket on `<port>`.** On Linux: the rows of `/proc/net/tcp`
  and `/proc/net/tcp6` in state `0A`, listening, whose local port — the four hex digits after the
  `:` of the second field — is `<port>`, each naming its socket's inode in the tenth field; then
  every process one of whose `/proc/<pid>/fd` links reads `socket:[<inode>]`. As one Bash call:

  ```
  i=$(command cat /proc/net/tcp /proc/net/tcp6 2>/dev/null | command awk -v p="$(command printf ':%04X' <port>)" '$4 == "0A" && substr($2, length($2) - 4) == p { printf "socket:[%s] ", $10 }')
  [ -n "$i" ] && QUOTING_STYLE=literal command ls -l /proc/[0-9]*/fd/ 2>/dev/null | command awk -v i="$i" 'BEGIN { n = split(i, s, " "); for (k = 1; k <= n; k++) w[s[k]] = 1 } /^\/proc\// { split($0, a, "/"); p = a[3] } ($NF in w) && !d[p]++ { print p }'
  ```

  It prints each pid once — an IPv4 and an IPv6 listener alike, and a process holding both.
  Elsewhere: `command lsof -t -iTCP:<port> -sTCP:LISTEN`. Either way, a socket another user's
  process holds is in the table but named by no process — its `fd` links cannot be read without
  root, and `lsof` shows no other user's process either — so the read prints nothing for it.
- **The sockets a process holds on `<port>` as their local port, in any state.** On Linux: the rows
  of `/proc/net/tcp` and `/proc/net/tcp6` whose local port — the four hex digits after the `:` of the
  second field — is `<port>` **and whose inode, the tenth field, is not `0`**; a row with inode `0` is
  a connection no process holds any more, `TIME_WAIT` or one its process has closed, and is not one of
  these. It is the listening read's own pipeline with the state test replaced by the inode test, so
  both read the same table the same way. As one Bash call:

  ```
  i=$(command cat /proc/net/tcp /proc/net/tcp6 2>/dev/null | command awk -v p="$(command printf ':%04X' <port>)" 'substr($2, length($2) - 4) == p && $10 != "0" { printf "socket:[%s] ", $10 }')
  [ -n "$i" ] && QUOTING_STYLE=literal command ls -l /proc/[0-9]*/fd/ 2>/dev/null | command awk -v i="$i" 'BEGIN { n = split(i, s, " "); for (k = 1; k <= n; k++) w[s[k]] = 1 } /^\/proc\// { split($0, a, "/"); p = a[3] } ($NF in w) && !d[p]++ { print p }'
  ```

  **The first line decides whether the port is free and the second only names who holds it**: a socket
  another user's process holds is in the table, so the first line prints an inode for it while the
  second names no process — the port is taken all the same. Elsewhere:
  `command lsof -n -P -Fpn -iTCP:<port>`, filtered on the **local** end, since `lsof` matches
  `-iTCP:<port>` at either end and a connection *to* another host's `<port>` holds an ephemeral local
  port of its own:

  ```
  command lsof -n -P -Fpn -iTCP:<port> 2>/dev/null | command awk -v p=":<port>" '/^p/ { pid = substr($0, 2) } /^n/ { n = substr($0, 2); sub(/->.*/, "", n); if (n ~ (p "$")) print pid }' | command sort -u
  ```

  `-n` and `-P` keep addresses and ports numeric, so a well-known port is never printed as a service
  name the filter would miss. `lsof` lists only sockets a process holds, and without root only this
  user's, so a `TIME_WAIT` row is absent there as it is here, and another user's socket is invisible
  rather than counted — the one place the two sources differ, and a port held that way reads as free
  off Linux.
- **A process's parent, and its process group.** On Linux: `/proc/<pid>/stat`, read after its
  **last** `)`, since the process name in parentheses before it may itself hold spaces or
  parentheses — `command sed 's/.*)//' /proc/<pid>/stat` prints the state, then the parent's pid,
  then the process group, so `| command awk '{ print $2 }'` reads the parent and
  `| command awk '{ print $3 }'` the group. Elsewhere: `command ps -o ppid= -p <pid>` and
  `command ps -o pgid= -p <pid>`. Both print nothing where the process
  has exited.
- **A process's start time.** On Linux: field 22 of `/proc/<pid>/stat`, read after its last `)` as
  above — `command sed 's/.*)//' /proc/<pid>/stat | command awk '{ print $20 }'`, in clock ticks
  since the host booted. Elsewhere: `LC_ALL=C TZ=UTC0 command ps -o lstart= -p <pid>`. `lstart`
  prints the start in the reader's local time, with its locale's names for the day and the month,
  so a later run under another `TZ`, or another `LC_ALL`, `LC_TIME` or `LANG` — a laptop whose time
  zone changed, a terminal exporting its own — would print another string for the same process;
  the two variables make every run print one (procps-ng 4.0.4: three time zones and four locales
  gave twelve strings for one process, and this form one). Both print nothing where the
  process has exited, and neither changes while the process lives, an `exec` included, so a
  process that later takes the same pid prints another. This check reads none; `/docs-serve` reads
  it to tell the process group it started from one that reuses its id (its Phase 7).
- **The states of a process group's members.** On Linux:
  `command cat /proc/[0-9]*/stat 2>/dev/null | command sed 's/.*)//' | command awk -v g=<pgid> '$3 == g { print $1 }'`,
  a zombie's state being `Z`. Elsewhere:
  `command ps -A -o pgid=,stat= | command awk -v g=<pgid> '$1 == g { print $2 }'`, a zombie's
  beginning `Z`.
- **A process's command line.** On Linux: `command tr '\0' ' ' < /proc/<pid>/cmdline`, its arguments
  with their NUL separators turned into spaces. Elsewhere: `command ps -o args= -p <pid>`.
- **A process's working directory.** On Linux: `/proc/<pid>/cwd`, a link to it that `git -C` takes
  as it stands. Elsewhere: the path on the `n` line of `command lsof -a -p <pid> -d cwd -Fn`.

Never run two servers at once: the next server boots only once step 5 has confirmed the last one
stopped. Where a space has two servers, every record this file names for `<space>` names the
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

The smoke-check is best-effort. A prerequisite-unmet, missing-server-tool,
boot-failure, or readiness-timeout outcome is recorded with its reason and falls
back to the manual table for that space — on a space with two servers, for that
server's pages — and it never blocks the run. Three outcomes end the smoke-check rather
than one space's part of it: a port that answers before its server boots (§2
step 2), a server §2 step 5 cannot confirm stopped — its port still answers, or
its process group still runs — and a readiness timeout on a server started
without a process group of its own (§2 step 3). Every page not yet checked then
falls back to the manual table, and the record names the port or process group
left running and its command — it never blocks the run either. A fourth ending
is the check being unavailable: `bash` or `curl` — or, off Linux, `ps` — cannot
run (§2), and the check boots, probes and stops through them; every page not yet checked falls
back to the manual table, and the record names the tool.

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

# Render verification (example-docs)

How `/document` Phase 6.5 proves the documentation it just wrote builds
and renders.

This is the single source of truth for the mechanics; Phase 6.5 cites it and
stays lean. Read every path, command, and port from the resolved `profile` — do
not hard-code example-docs specifics.

"Affected pages" = every file written or modified in Phase 6.3.

## 1. Build vs boot

Resolve the build command per space: `profile.commands.per_space.<space>.build` when the profile
declares one for that space, else the flat `profile.commands.build`. Run it for every space in the
**verification set** defined in §2 — every space whose `content_root` holds at least one affected
page. For example-docs the two commands are `pnpm cloud:build` and `pnpm self-hosted:build` — both
exist, and an earlier version of this file wrongly claimed the repo had only `commands.lint` and the
`*:start` servers, which disabled this gate entirely.

Phase 6.5 does NOT re-run the prose linter — that is Phase 6.4's `docs-style-checker`.

Only when a repo genuinely declares **no** build command at either level does the **dev-server boot
become the build proof** — a server that boots and serves HTTP 200s proves the content compiled. That
is a fallback for repos without a build, not a description of example-docs.

## 2. Sequential dev-server smoke-check

`profile.dev_servers.concurrent: false` means one space at a time.

**The verification set — which spaces to build and boot.** Match every affected page against each
`profile.spaces[].content_root`/`snippet_root` prefix; the set is the spaces those matches name. A
repo declaring one content root always yields one space; a repo declaring several yields only the
ones this run actually wrote into. A space that owns no affected page is neither built nor booted —
nothing changed in it.

This set governs **both** gates: §1's build check runs each of its spaces' build commands, and the
smoke-check below boots each of them.

The two operative consumers — `/document` Phase 6.5 Steps 1 and 2 — restate this set inline rather than citing it alone. That duplication is deliberate: those are instructions a model acts on in one pass, and it may not follow a cross-reference before deciding which servers to boot. Keep both restatements in sync with this definition and do not collapse them into a bare citation. Descriptive references elsewhere (`gate-ledger.md` §4's registry, `docs-profile-schema.md`'s field rules) cite this section and should stay short.

For each space in the verification set, in order:

1. Verify prerequisites (§4) — best-effort, never applied.
2. Boot `profile.dev_servers.servers[<space>].command` in the background; record
   the process id.
3. Readiness poll: GET `http://localhost:<port><base_path>/` until HTTP 200 or
   `profile.dev_servers.readiness_timeout_seconds` seconds elapse (fall back to
   **120** when the field is absent).
4. For each affected page in this space, GET its derived URL (§3) and
   assert HTTP 200.
5. Stop the server (kill the recorded process id) before booting the next space.

Never run two servers at once. Always stop the current one before the next.

## 3. Route derivation

The page URL is `http://localhost:<port><base_path>/<route>`, where `<port>` and
`<base_path>` come from `profile.dev_servers.servers[<space>]` and `<route>` is
the page path relative to that space's `content_root` with a trailing `index.md`
or `.md` removed. Example: `cloud/_content/setup/foo/index.md` in the `cloud`
space (`base_path: /docs`, port 4000) → `http://localhost:4000/docs/setup/foo`.

This is best-effort. A wrong route that 404s in the smoke-check simply downgrades
that page to the manual table — it is not a render defect by itself.

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
manual table for that space — it never blocks the run. (A 404/500 on an affected
page IS a finding — it is surfaced, not silently dropped.)

The **pages-to-visit table** is always emitted, one row per affected page: its
URL in its own space (§3) and what to verify ("confirm the page renders as
intended"). When the smoke-check ran, annotate each row ✅ 200 / ⚠️ skipped
(reason) / ❌ failed.

**Static analysis is necessary but never sufficient.** A clean link-integrity grep and a verified
page structure corroborate the render gate and neither satisfies it. Static greps do not catch
template compile errors, do not prove an included snippet resolves, and do not prove a postid
resolves in the build. A run that has only static evidence has not run this gate — record
`render_smoke_check` accordingly.

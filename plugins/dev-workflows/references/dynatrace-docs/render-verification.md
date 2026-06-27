# Render verification (dynatrace-docs)

How `/impl:jira:docs` Phase 6.8 proves the documentation it just wrote builds
and renders — and that cross-space pages honor the 3a render-unchanged invariant
(the protected space's render is unchanged). See [[multi-space-writing]] for the
write strategies this verifies.

This is the single source of truth for the mechanics; Phase 6.8 cites it and
stays lean. Read every path, command, and port from the resolved `profile` — do
not hard-code dynatrace-docs specifics.

"Affected pages" = every file written or modified in Phase 6.

## 1. Build vs boot

Run `profile.commands.build` only if the profile defines one. Phase 6.8 does NOT
re-run the prose linter — that is Phase 6.7's `docs-style-checker`. When the
profile defines no build command (the dynatrace-docs case: only
`commands.lint` + the `*:start` dev servers), the **dev-server boot is the build
proof** — a server that boots and serves HTTP 200s proves the content compiled.

## 2. Sequential dev-server smoke-check

`profile.dev_servers.concurrent: false` means one space at a time. For each space
in `target_spaces`, in order:

1. Verify prerequisites (§5) — best-effort, never applied.
2. Boot `profile.dev_servers.servers[<space>].command` in the background; record
   the process id.
3. Readiness poll: GET `http://localhost:<port><base_path>/` until HTTP 200 or
   `profile.dev_servers.readiness_timeout_seconds` seconds elapse (fall back to
   **120** when the field is absent).
4. For each affected page rendered in this space, GET its derived URL (§3) and
   assert HTTP 200.
5. For cross-space pages, run the invariant check (§4).
6. Stop the server (kill the recorded process id) before booting the next space.

Never run two servers at once. Always stop the current one before the next.

## 3. Route derivation

The page URL is `http://localhost:<port><base_path>/<route>`, where `<port>` and
`<base_path>` come from `profile.dev_servers.servers[<space>]` and `<route>` is
the page path relative to that space's `content_root` with a trailing `index.md`
or `.md` removed. Example: `dynatrace/_content/setup/foo/index.md` in the `saas`
space (`base_path: /docs`, port 4000) → `http://localhost:4000/docs/setup/foo`.

This is best-effort. A wrong route that 404s in the smoke-check simply downgrades
that page to the manual table — it is not a render defect by itself.

## 4. Delta-marker extraction and the invariant check

A **delta marker** is a short, distinctive literal string taken from the
per-space content a cross-space write produced — derived here at verification
time, not emitted by Phase 6:

- `conditional` page → read the written file and take a distinctive literal line
  from inside the `{{#if project='<target_space>'}}…{{/if}}` block.
- `override-copy` page → take a distinctive literal from the override copy's
  content that is absent in the home-space original.

The invariant check, per cross-space page:
- the marker must be **PRESENT** in the render of the strategy's `target_space`;
- the marker must be **ABSENT** in the render of the protected space.

A marker that appears in the **protected** space's render — or is missing from
the **target** space's render — is a **Critical** finding: the 3a protection
failed.

## 5. Prerequisites (best-effort, never auto-applied)

`profile.prerequisites` lists what a dev server may need before `*:start` boots
(e.g. a working `.docstack` toolchain / an axios shim). Phase 6.8 **checks** a
prerequisite but NEVER applies it — the `.docstack` workaround is a local,
gitignored, reversible dev-environment hack and is out of scope for an automated
run. If a prerequisite is unmet, record "smoke-check skipped for `<space>`:
prerequisite `<x>` unmet" and use the manual table for that space.

## 6. Graceful fallback and the pages-to-visit table

The smoke-check is best-effort. Any prerequisite-unmet, boot-failure, or
readiness-timeout outcome is recorded with its reason and falls back to the
manual table for that space — it never blocks the run. (A 404/500 on an affected
page, or an invariant violation, ARE findings — they are surfaced, not silently
dropped.)

The **pages-to-visit table** is always emitted, one row per affected page: its
URL in each space it renders in (§3), its `write_strategy`, and what to verify
(cross-space rows: "confirm `<target_space>` shows the change and the
`<protected_space>` render is unchanged"). When the smoke-check ran, annotate
each row ✅ 200 / ⚠️ skipped (reason) / ❌ failed.

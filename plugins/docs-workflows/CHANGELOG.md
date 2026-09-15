# Changelog

All notable changes to the **docs-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.2.0] — 2026-09-10

### Added — the cold-start scaffold: `/docs-init`, `/docs-brand`, `/docs-serve`

Three commands answer the question the plugin previously could not: *there are no docs and no docs repo — what should exist?* Every existing command assumed documentation already existed, and documented a delta against it.

- **`/docs-init`** scaffolds a documentation repository from nothing: a product-shaped Material for MkDocs page skeleton with a stub in every section, **two builds over one content root** (public and internal), a nav generated from frontmatter `order`, Vale with a project vocabulary seeded with the product name and the scaffold's own stub vocabulary, a CI workflow that runs both builds and the two output-level visibility gates, a `.gitignore` for the build outputs, the synced Vale packages and `/docs-serve`'s state file — **created, or merged into**: an existing `.gitignore`, such as a hosting template's, gains only the lines it lacks and never loses, reorders or rewrites one of its own, and, immediately before the commit, every path the run wrote — the branding phase's logo and stylesheet included — is tested against it: a path a project line ignores is left uncommitted, never force-added, every config reference to it is removed so the committed `mkdocs.yml` names no missing file, and both are reported — and the `.dev-workflows/docs-profile.yml` that `/document`, `/docs-brand` and `/docs-serve` read (`/release-notes` reads none). It refuses to scaffold over a repository that already carries a docs signal — an in-repo `docs-profile.yml` among them, so a profiled repository built with any generator is refused — and points at `/docs-profile` instead. It branches before it writes, verifies the scaffold builds and lints — applying **the same Vale exit criterion its CI workflow applies**, so a scaffold that passes locally cannot fail its first CI run over the same files, and it does pass: the stubs raise no error-level alert against the seeded vocabulary — and finishes on a **drafted** pull request it never pushes. The source-repo set it confirms is used for that run only; no profile field records it until `/docs-audit` needs one.
- **`/docs-brand`** extracts a logo and a rough primary/accent colour pair from the product's own code — a fixed precedence over a Tailwind config, CSS custom properties, a MUI theme, a web-app manifest and SCSS/LESS variables — prints every extracted value with its file and line before applying anything, checks the pair against the WCAG 2.2 threshold pair, and copies assets into `docs/assets/` rather than linking back into the code repo. It runs standalone, or `--inline` from `/docs-init`, which folds its diff and its contrast finding into that command's own review and pull request: a rebrand never requires re-scaffolding the site. **`--inline` never aborts the scaffold**: any stop or Cancel returns `no branding applied: <reason>` with an empty diff, and `/docs-init` continues as if `--no-brand`, recording the reason — an API or CLI product with no frontend reaches `DOCS_BRAND_NOTHING_TO_APPLY` routinely. It validates the **effective** theme, following `INHERIT`, so the inheriting `mkdocs.internal.yml` the scaffold writes is accepted rather than refused, and it writes `theme` and `extra_css` only into the config that inherits nothing — never a second theme block into the inheriting one — and the `logo`/`favicon` keys only when it applies a logo. A standalone run runs the same commit-time ignore test before it commits, so a docs repository whose `.gitignore` keeps `*.svg` or `*.css` out never receives a config naming a file its commit lacks.
- **`/docs-serve`** starts, stops or checks the docs site's dev server for any profiled repo and reports a URL that actually opens from the host. It never starts a second server on a port that already answers, falls forward to the next free port on a collision and says so, and `--build` runs the profile's build command and exits. **The port reaches a server only through the `{port}` token in its recorded command**, which every run replaces with the port it serves on — the configured one, `--port <n>`, or the one a collision moved it to — and which is the only part of a command ever rewritten; the same substitution identifies a moved server by its command line. A command without the token is **fixed-port**: it binds its own port, so a collision on it is reported with what holds the port (`DOCS_SERVE_PORT_HELD`) instead of falling forward, `--port` on it stops (`DOCS_SERVE_FIXED_PORT`), and no pre-scan looks above its port for a copy nothing could have moved there. Its pid record is **keyed by port**, because a port holds one server and the profile `/docs-init` writes serves one space twice (public and internal), and each entry names the server it started — its space, and its **visibility** where the profile tags one. A lookup made through the server selection — every serve run's already-running check, and `--status`/`--stop` with `--internal` — **filters on the recorded server before matching a port**, so a server a collision moved onto another server's configured port is never reported as that one: a public server on the internal server's port is never taken for the internal one, `--stop --internal` never stops it, and one space's server is never taken for the next space's. With no record to consult, **a server is identified by evidence, never by the port it answers on**: the process the socket table names for the port — first its checkout, the git top level of its working directory compared as a whole path, so a `git worktree` nested inside the main checkout is never taken for it, then the command line it or a process it descends from was started with — or, where the profile's builds carry different site names, the home page's whole site name. A server running in another checkout of the same repository is never re-adopted or recorded, so one checkout's `--stop` never ends another's server. The selected server is re-adopted wherever it is found, on every profile — at the configured port, on the collision walk, and, before anything starts, on the ports a collision would have moved a `{port}`-carrying command to, whether the configured port has come free since or is still held, since a moved copy can sit beyond the first free port — and another of the repository's servers is passed over. Where two checkouts start at once and the other wins the port, the loser records nothing rather than the winner's pid. Only where nothing names the server does a one-server profile re-adopt it by its page and a multi-server one report it unconfirmed, starting nothing and naming the pid to stop by hand or, where the command carries `{port}`, `--port <n>`, which runs no such pre-scan. The recorded pid is always the listener's, never a wrapper's, so `--stop` ends a server started through `npm run` or `pnpm` rather than its wrapper, and reports it stopped only once its port no longer answers as this docs site. A recorded pid counts as living only while the socket table still names it on its port, so a pid number reused after a container restart is never reported as the running server and never signalled; a server recorded with no pid is cleared by `--stop` once its port stops answering. `--internal` on a profile that tags a public server but no internal one — a `/docs-init --public-only` scaffold — stops with `DOCS_SERVE_NO_INTERNAL_BUILD` instead of serving or building the public site. It writes no documentation and no artefact — which is why, alone in this plugin's pipeline, it runs no `specs-preflight`, no `commit-artifacts`, no review gate and no maintenance phase.

### Added — `docs-scaffold-reviewer` (D25)

A new Opus-pinned agent gates both scaffolding commands. `/docs-init` and `/docs-brand` write `mkdocs.yml`, a CI workflow, `.vale.ini`, a generated nav and theme CSS — code, reviewed as code (D17) — but the plugin's declared dependencies are `workflows-core` and `prose-style`, and `code-review` and `review-fixer` ship from `dev-workflows`, so nothing guaranteed they were installed: **a miss would have removed the gate silently rather than degraded a feature**. It was also the wrong reviewer on its merits — `code-review` carries a spec-conformance dimension and a captured test baseline, and a scaffold has neither. The fixer disposition is *orchestrator applies*, behind `workflows-core:finding-triage`, so there is no re-review cycle: the orchestrator's direct edit is the fix, applied against the same finding it answers.

### Added — four references under `references/docs-workflow/`

- `scaffold-tree.md` — the scaffold's directory tree and stubs, both `mkdocs.yml` configs with their "must be identical / may differ" table, `.gitignore` with its create-or-merge rule, `.vale.ini` with its seeded vocabulary, and the one Vale exit criterion the scaffold's own verification and its CI both apply: Vale's exit code, which an error-level alert or a configuration error fails, which a flag such as `--no-exit` or `--filter` can move, and which `MinAlertLevel` — a threshold on what is *reported* — cannot.
- `visibility.md` — the two-build model over one content root, both traps (the dev server is not the build — what `mkdocs serve` shows depends on the MkDocs version and the exclusion key, and none shows a snippet leak — and snippets cross the boundary invisibly), the two **output-level** gates, which assert on built HTML rather than on source paths or contributor discipline, the marker-comment convention, and the CI workflow the scaffold writes — whose image size budget tolerates an image directory that does not exist yet.
- `contrast.md` (D24) — the WCAG 2.2 **SC 1.4.3** (4.5:1 body text, 3:1 large text) and **SC 1.4.11** (3:1 UI boundaries) threshold pair and the relative-luminance formula, stated here rather than loaded from `guideline-reviewers`' `accessibility.md`, which sits in a plugin nothing declares and is therefore unreachable. That file is cited as further reading and loaded by nothing.
- `repo-resolution.md` — one docs-repo resolution ladder in two forms: **signal-positive** (`resolve-docs-repo`, for a repo that exists) and **signal-inverted** (`resolve-scaffold-target`, for a repo to create). Same variable, same `${DOCS_PATH:-/workspace/docs}` default, opposite predicate (D23) — an implementer who copies the adopting ladder verbatim gets the scaffold exactly backwards. Both test one signal set, which counts an in-repo `.dev-workflows/docs-profile.yml` as a signal: a profiled repository with no other marker is found by the adopting form and refused by the creating one.

### Changed — the docs profile records what the scaffold produces

`docs-profile-schema.md` and `docs-profile.default.yml` gain `generator` (informational only — every invocation still goes through `commands.*`, which is what keeps the generator choice reversible), `builds[]` for a repo whose one content root renders into more than one output, `dev_servers.servers[].public_base_url` (a command inside a container cannot infer the host's published port mapping, so it reports this instead of guessing) and `dev_servers.servers[].visibility`. `dev_servers.servers[].command` may carry the literal token `{port}`: every consumer that runs the command substitutes the port it serves on and never runs the token unsubstituted, nothing else in a command is rewritten, and a command without it is fixed-port — its port is its own, and no consumer can move it. `/docs-init` writes the token into both of its server commands (`mkdocs serve -f <config> -a 0.0.0.0:{port}`). `/docs-profile` writes it only in place of a literal port a detected command already carries, never inventing a flag or an argument-forwarding form, and its report lists every fixed-port server it wrote; the worked example's `pnpm cloud:start` stays fixed-port. `images.policy` becomes an enum — `in-repo` (the scaffold default) / `object-store` / `cdn` — replacing a free-text sentence, with every rule that sentence carried preserved under the policy it describes, beside `images.root`, `max_bytes`, `public_prefix` and `internal_prefix`.

`frontmatter-guidelines.md` gains a **reserved-keys** section (D18): `type`, `audience`, `visibility` and `unit`, reserved by this family on any docs repo it scaffolds or writes into. `docs-frontmatter`'s ownership of the schema is unchanged.

### Changed — `/document` direct mode files its bookkeeping per docs repo (D19)

A direct-mode run takes no address, so it ordinarily resolves no PRD folder, and its cost entry went to the pending file and its feedback unfiled to the specs-repo root — both reconciling against nothing, forever, which is the problem D19 names. It now takes the same rung `/docs-init` and a standalone `/docs-brand` take: both land under `$SPECS_PATH/documentation/<docs-repo-slug>/dev-workflows/`, the slug being `workflows-core:specs-repo-git` §2.1's name for the write target the run resolved, whether or not that target is a git work tree. Every direct-mode run resolves a write target, so none parks an entry in pending any more; a run whose key does resolve a PRD folder still files under it. Keyed mode is unchanged. Pending and unfiled entries left by earlier direct-mode runs stay where they are.

### Changed — `/document`'s render check boots the server that publishes each page

Phase 6.5's dev-server smoke-check booted `dev_servers.servers[<space>]`, one server per space. The profile `/docs-init` writes records **two** servers for its one space, a public one and an internal one, so that index names no single server there and an agent had to pick: picking the public server checks every internal-only affected page on a server whose build excludes it, and picking the internal one never boots the public build at all. The server is now chosen **per affected page** (`render-verification.md` §2). A space with one server checks every page on it, as before. A space whose two servers are tagged `public` and `internal` checks a page on the public server unless the public build excludes it (`visibility.md` §1 decides which pages those are), and then on the internal one, booting them one at a time, public first. Any other space that several servers share is skipped with its reason and falls to the manual table, since a guessed server is a false result either way. Each server's `{port}` is replaced by its configured port before it boots.

### Changed — `/document`'s build check runs every build the profile records

Phase 6.5's gating build check ran `commands.per_space.<space>.build`, else `commands.build`, and the profile `/docs-init` writes records `commands.build` as the public build alone — so the internal build never ran, an internal-only page with a broken link passed the check, and only CI caught it on the pull request. Where the profile records `builds[]`, the check now runs **every** entry, the precedence `/docs-serve --build` already uses; otherwise it runs the per-space or flat command exactly as before. Each build is recorded on its own under its `id`, so a failure names the build that failed, and `doc-fixer` is handed that build's own output. The toolchain preflight derives its tools from `builds[]` too.

### Changed — `/document`'s render check stops each server by the process that holds its port

The smoke-check recorded "the process id" of each server it booted and killed it before booting the next, without saying which process. Started the way the Bash tool starts a command, that is a wrapper shell, and an `npm` or `pnpm` script adds another: signalling either leaves the server serving, so the next server booted beside it. It now reads the port's **listener** from the socket table once the port answers — `/docs-serve`'s definition of one, without its checkout test (this run started the server) or its state-file test (this command keeps none) — and stops that process, falling back to the pid the start returned only where no socket tool names a listener. **Before booting the next server it probes the port, and the probe decides**: where the port still answers, no further server boots, the record names the port left running, and every page not yet checked falls to the manual table. A missing socket tool alone never ends the check. The same probe runs before each boot: a port something else already holds is never booted onto, and its process is never signalled.

### Changed — a 404 in `/document`'s render check has one disposition

Two live instructions disagreed: Phase 6.5's outcomes treated a 404 on an affected page as a render defect and sent it to `doc-fixer`, while the route note said a wrong route that 404s simply leaves the page on the manual table. A 404 is now always surfaced as ❌ with its URL, the page stays on the manual table, and it is never a content failure by itself: the route is derived best-effort, so a 404 cannot tell a wrong route from a missing page — and the systematic source of false ones, internal-only pages checked on the public server, went with the per-page server choice above — while the build check, which runs every build, owns compile failures. It counts toward `render_smoke_check`'s `findings`, on a `RAN` row. A 5xx stays a render defect, a content failure as before, and is recorded `FAILED` on `render_smoke_check`'s row.

### Changed — `/docs-profile` resolves through the shared ladder

Its Phase 0 took the first token of `$ARGUMENTS`, else the current working directory — which in a container means it profiles wherever the shell happens to be rather than where the docs clone is mounted. It now executes `resolve-docs-repo` and reports which rung answered. Its signal-less confirmation survives as a distinct question — whether to *write a profile* for a repo showing none of the usual signals — and cites `repo-resolution.md` §3's signal set rather than re-deriving it.

### Fixed

A `/docs-profile` refresh could delete what its scan does not detect. Its detection reads `package.json` `*:start` scripts and `*/_content` roots, and looks for `builds[]` and `generator` not at all, so on a profile `/docs-init` wrote the draft carried none of `builds[]`, `generator`, `dev_servers`, `commands` or `images` — and the refresh diff, recommending "overwrite changed fields", could read every one of them as a change to nothing. A refresh now builds the new profile from the existing one: it proposes a change only for a field detection produced a value for, carries every other field forward verbatim and names it in the diff as *kept, not detected*, never treats detection finding nothing as a proposal to delete, and never empties `spaces[]`. Detection itself is unchanged.

`/docs-profile`'s Phase 1 justified invoking the `model-routing` skill on the ground that "slash-command bodies cannot expand `${CLAUDE_PLUGIN_ROOT}`". That was verified false in a live run. The reason that survives is the one that was always doing the work: `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, so this plugin cannot read a `workflows-core` skill or reference by path whatever a command body can expand.

`/document` keyed mode adopts a docs repository whose only marker is an in-repo `.dev-workflows/docs-profile.yml` — its Phase 0 rungs (a.5) and (b) accept the profile in a signal's place — but its write-context classification counted step 2's signals alone, so that repository came out `non_docs_repo` with no confirmation ever asked, and the Phase 6.3 row for `non_docs_repo` assumes one. The classification now counts the in-repo profile too, so such a repository is a `docs_repo` and every later phase treats it as one. It is the population the shared signal set's new profile entry serves, which is how it was found.

The plugin `description` now says "eighteen reference **files**" rather than "reference pages". Eighteen is the file count; sixteen are pages, the other two being `default-owners.txt` and `docs-profile.default.yml`, which are read as data. The predecessor blurb counted pages ("twelve reference pages" against fourteen files), so the unit had silently flipped while the number moved.

## [1.1.3] — 2026-09-09

### Added — a recorded review verdict names the version it was taken against

`/document` (keyed mode) cites the new `A recorded verdict names the version it was taken against` rule in
`workflows-core:escalation-rules`. The one-fix-cycle-plus-one-re-review cap assumes a fix cycle only
removes defects; on three live runs it **introduced** something the re-review then found, with the
budget already spent — so the run either shipped a known defect or fixed it and left the final text
unreviewed. Both end with a `PASS` on record beside a file the `PASS` never saw.

It now states what the verdict covers, and where any edit followed it, the final report says so and
names the edits. Where none did, it says that too, so a clean run reads as checked rather than as
unreported.

## [1.1.2] — 2026-09-08

### Removed

- **`/release-notes` has no worthiness gate.** Phase 2's `relevant_for_release_notes` check, its
  `RELEASE_NOTES_NOT_RELEVANT` stop and that stop's override are gone, and the phase is now
  *Plan + approval*.
  It asked a question with one answer — every PRD is relevant for release notes — so the only value it
  could carry that changed anything was one nobody should write. The run's one refusal is
  `RELEASE_NOTES_NEEDS_KEY`, on an address that does not resolve.

### Fixed

- **The command page no longer documents the gate's own retired implementation.** It said Phase 2 read
  the flag *"straight from the imported PRD frontmatter — never from the authored specs draft"* — the
  instruction the command reversed when the import was cut, which had made the stop unreachable. The
  page was not swept at the time; the paragraph is now gone with the gate it described.

## [1.1.1] — 2026-09-06

### Fixed — two more bare `doc-fixer` dispatches in `document.md`

`doc-fixer` ships from `workflows-core`, so an unqualified name resolves to nothing. An earlier sweep namespaced two dispatch sites in this file; **two of the same shape survived it** — the **BLOCK** branch and the "Manual fix notes" one-shot pass — because both carry their instruction in prose rather than in a dispatch block, where the qualified `subagent_type` lives. Both now name `workflows-core:doc-fixer`. The same shape was found and fixed in `product-workflows`'s `/epics`.

The sentence introducing the two modes also claimed they "share the same `docs-style-checker` / `doc-fixer` agents", which reads as one plugin's pair. They ship from different plugins, and it now says so.

### Documentation

`docs/reference/session-cost.md` now states the claim-namespace discipline: a deferred claim resolves only onto a command of this family, matched against a manifest of its own `<plugin>:<command>` names, and a command from another marketplace ends the open window without ever being claimable. No page in any plugin had said this.

## [1.1.0] — 2026-09-06

### Fixed — the plugin-qualified form now preloads context, where before it matched no hook

`hooks/preload-context.sh` matched `^/(document|release-notes)` only, so `/docs-workflows:document <KEY>` — the disambiguating form, and the form this plugin's own documentation teaches — injected nothing. It now matches an optional `docs-workflows:` prefix as well, and `/docs-workflows:document PRODUCT-1234` preloads specs context exactly as `/document PRODUCT-1234` does.

This matters more than a convenience for `/release-notes`: its bare form resolves to a Claude Code built-in of the same name, so the qualified form is the only one that reaches this plugin — and until now that form matched no hook at all.

The widening was made in one coordinated change across every plugin in the family that ships a `UserPromptSubmit` hook, because widening them independently is how double-injection returns. Each script accepts only its **own** plugin's name as the optional prefix, and the three command sets are disjoint, so no single prompt can match two plugins' hooks.

## [1.0.0] — 2026-09-05

### Added — the documentation half of `dev-workflows`, extracted into its own plugin

Install it with `claude plugin install docs-workflows@ihudak-plugins`. Updating the marketplace alone does **not** install it: `dev-workflows` does not declare it, because no `dev-workflows` run loads anything from it. Three commands move here from `dev-workflows` 3.26.0, and each keeps its bare name once this plugin is installed — only the namespaced form changes:

| Command | Was | Is now |
|---|---|---|
| `/document` | `/dev-workflows:document` | `/docs-workflows:document` |
| `/docs-profile` | `/dev-workflows:docs-profile` | `/docs-workflows:docs-profile` |
| `/release-notes` | `/dev-workflows:release-notes` | `/docs-workflows:release-notes` |

**Seven agents** come with them — `diff-summarizer`, `doc-location-finder`, `doc-planner`, `doc-reviewer`, `doc-writer`, `docs-style-checker` and `release-notes-writer` — dispatched as `docs-workflows:<agent>`. An agent crosses a plugin boundary for free, so every dispatch site in every plugin simply names the new namespace.

**Fourteen reference files and one bundled skill** come with them too. Twelve of the fourteen are markdown pages: `gate-ledger.md`, `repo-verification-gates.md`, `toolchain-preflight.md`, `release-note-types.md`, `finish-and-handoff.md`, the five `docs-profiles/` authoring guides, and the two `handoff/` agent contracts. The other two are data rather than prose — `default-owners.txt` and `docs-profile.default.yml` — read by `/document`, by the `docs-frontmatter` skill and by the changelog/owners hook. The `docs-frontmatter` skill ships here now; it was `dev-workflows`'s only bundled skill and that plugin now has none.

**Two hooks.** `preload-context.sh` injects specs and repo context on a `/document` or `/release-notes` prompt — it is one half of a split, `dev-workflows` keeping the half that matches `/implement`, `/epics`, `/vuln` and `/upgrade`; the two alternations are a disjoint partition of the original six, so no prompt makes both fire. `changelog-owners-reminder` moved whole rather than being duplicated, because it resolves `default-owners.txt` and `docs-profile.default.yml` under its own `${CLAUDE_PLUGIN_ROOT}` and those files are here now — left behind it would have swallowed the miss and exited 0, losing the owners check and the built-in default profile with no signal at all.

**Two declared dependencies: `workflows-core` and `prose-style`.** The first is structural — `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, so the shared reference corpus is reached through the `workflows-core:reference` loader skill rather than by path, and every command and agent here that cites one carries a preamble saying so. The second is the one **behaviour change** in the move, sanctioned as decision S12 of the split design: an unsatisfied dependency disables a plugin rather than letting it half-run, so the branches that skipped or degraded a style check when `prose-style` was absent were unreachable and are deleted. `docs-style-checker` now always runs its complementary `prose-style-checker` pass and can no longer return `NOT_CONFIGURED`; `/release-notes`'s Phase 7 style gate skips only on the user's own answer.

### Fixed — a style-check outcome no rule ever assigned

The same work found a **pre-existing** live defect, and it is worth separating from the deletion above because the deletion did not cause it. The style-check outcome mapping had two rules for a missing primary linter: `DEGRADED` when every detected rung *failed*, and `NOT_CONFIGURED` when no rung was detected **and** `prose-style` was absent. Those do not meet. A repository with no linter of its own and `prose-style` installed — the common case — landed in neither, so the `style_check` gate had no outcome to record at all. Removing the `NOT_CONFIGURED` branch did not expose the hole; it removed the last rule that mentioned the case at all, making it unavoidable. Both rules now name "detected and failed, or never detected" explicitly — the `DEGRADED` rule and the `ERROR` → `UNAVAILABLE` rule, in `/document` and in `docs-style-checker`'s own `status` definitions alike.

One consequence to know about if you read the agent's output: `complementary_linter: none` has **inverted** meaning. It used to say "no complementary pass ran; the primary carried the gate", which mapped to `RAN`. It now says "`prose-style-checker` *was* the primary", which maps to `DEGRADED`. Same token, opposite ledger consequence, in the field `/document` derives the outcome from. Nothing else consumes it.

Everything else is behaviour-preserving. This is the third increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md`; the first extracted `guideline-reviewers`, the second `workflows-core`. `dev-workflows` 3.27.0's changelog records the same move from its side.

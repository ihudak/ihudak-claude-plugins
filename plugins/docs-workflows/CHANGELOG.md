# Changelog

All notable changes to the **docs-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.2.0] — 2026-09-10

### Added — the cold-start scaffold: `/docs-init`, `/docs-brand`, `/docs-serve`

Three commands answer the question the plugin previously could not: *there are no docs and no docs repo — what should exist?* Every existing command assumed documentation already existed, and documented a delta against it.

- **`/docs-init`** scaffolds a documentation repository from nothing: a product-shaped Material for MkDocs page skeleton with a stub in every section, **two builds over one content root** (public and internal), a nav generated from frontmatter `order`, Vale with a project vocabulary seeded with the product name and the scaffold's own stub vocabulary, a CI workflow that runs both builds and the two output-level visibility gates, a `.gitignore` for the build outputs, the synced Vale packages and `/docs-serve`'s state file, and the `.dev-workflows/docs-profile.yml` that `/document`, `/docs-brand` and `/docs-serve` read (`/release-notes` reads none). It refuses to scaffold over a repository that already carries a docs signal and points at `/docs-profile` instead. It branches before it writes, verifies the scaffold builds and lints — applying **the same Vale exit criterion its CI workflow applies**, so a scaffold that passes locally cannot fail its first CI run, and it does pass: the stubs raise no error-level alert against the seeded vocabulary — and finishes on a **drafted** pull request it never pushes. The source-repo set it confirms is used for that run only; no profile field records it until `/docs-audit` needs one.
- **`/docs-brand`** extracts a logo and a rough primary/accent colour pair from the product's own code — a fixed precedence over a Tailwind config, CSS custom properties, a MUI theme, a web-app manifest and SCSS/LESS variables — prints every extracted value with its file and line before applying anything, checks the pair against the WCAG 2.2 threshold pair, and copies assets into `docs/assets/` rather than linking back into the code repo. It runs standalone, or `--inline` from `/docs-init`, which folds its diff and its contrast finding into that command's own review and pull request: a rebrand never requires re-scaffolding the site. **`--inline` never aborts the scaffold**: any stop or Cancel returns `no branding applied: <reason>` with an empty diff, and `/docs-init` continues as if `--no-brand`, recording the reason — an API or CLI product with no frontend reaches `DOCS_BRAND_NOTHING_TO_APPLY` routinely. It validates the **effective** theme, following `INHERIT`, so the inheriting `mkdocs.internal.yml` the scaffold writes is accepted rather than refused, and it writes `theme` and `extra_css` only into the config that inherits nothing — never a second theme block into the inheriting one — and the `logo`/`favicon` keys only when it applies a logo.
- **`/docs-serve`** starts, stops or checks the docs site's dev server for any profiled repo and reports a URL that actually opens from the host. It never starts a second server on a port that already answers, falls forward to the next free port on a collision and says so, and `--build` runs the profile's build command and exits. Its pid record is **keyed by port**, because a port holds one server and the profile `/docs-init` writes serves one space twice (public and internal); `--stop` and `--status` resolve their target to a port through the same server selection before looking it up. It writes no documentation and no artefact — which is why, alone in this plugin's pipeline, it runs no `specs-preflight`, no `commit-artifacts`, no review gate and no maintenance phase.

### Added — `docs-scaffold-reviewer` (D25)

A new Opus-pinned agent gates both scaffolding commands. `/docs-init` and `/docs-brand` write `mkdocs.yml`, a CI workflow, `.vale.ini`, a generated nav and theme CSS — code, reviewed as code (D17) — but the plugin's declared dependencies are `workflows-core` and `prose-style`, and `code-review` and `review-fixer` ship from `dev-workflows`, so nothing guaranteed they were installed: **a miss would have removed the gate silently rather than degraded a feature**. It was also the wrong reviewer on its merits — `code-review` carries a spec-conformance dimension and a captured test baseline, and a scaffold has neither. The fixer disposition is *orchestrator applies*, behind `workflows-core:finding-triage`, so there is no re-review cycle: the orchestrator's direct edit is the fix, applied against the same finding it answers.

### Added — four references under `references/docs-workflow/`

- `scaffold-tree.md` — the scaffold's directory tree and stubs, both `mkdocs.yml` configs with their "must be identical / may differ" table, `.gitignore`, `.vale.ini` with its seeded vocabulary, and the one Vale exit criterion the scaffold's own verification and its CI both apply.
- `visibility.md` — the two-build model over one content root, both traps, the two **output-level** gates, which assert on built HTML rather than on source paths or contributor discipline, the marker-comment convention, and the CI workflow the scaffold writes — whose image size budget tolerates an image directory that does not exist yet.
- `contrast.md` (D24) — the WCAG 2.2 **SC 1.4.3** (4.5:1 body text, 3:1 large text) and **SC 1.4.11** (3:1 UI boundaries) threshold pair and the relative-luminance formula, stated here rather than loaded from `guideline-reviewers`' `accessibility.md`, which sits in a plugin nothing declares and is therefore unreachable. That file is cited as further reading and loaded by nothing.
- `repo-resolution.md` — one docs-repo resolution ladder in two forms: **signal-positive** (`resolve-docs-repo`, for a repo that exists) and **signal-inverted** (`resolve-scaffold-target`, for a repo to create). Same variable, same `${DOCS_PATH:-/workspace/docs}` default, opposite predicate (D23) — an implementer who copies the adopting ladder verbatim gets the scaffold exactly backwards.

### Changed — the docs profile records what the scaffold produces

`docs-profile-schema.md` and `docs-profile.default.yml` gain `generator` (informational only — every invocation still goes through `commands.*`, which is what keeps the generator choice reversible), `builds[]` for a repo whose one content root renders into more than one output, `dev_servers.servers[].public_base_url` (a command inside a container cannot infer the host's published port mapping, so it reports this instead of guessing) and `dev_servers.servers[].visibility`. `images.policy` becomes an enum — `in-repo` (the scaffold default) / `object-store` / `cdn` — replacing a free-text sentence, with every rule that sentence carried preserved under the policy it describes, beside `images.root`, `max_bytes`, `public_prefix` and `internal_prefix`.

`frontmatter-guidelines.md` gains a **reserved-keys** section (D18): `type`, `audience`, `visibility` and `unit`, reserved by this family on any docs repo it scaffolds or writes into. `docs-frontmatter`'s ownership of the schema is unchanged.

### Changed — `/docs-profile` resolves through the shared ladder

Its Phase 0 took the first token of `$ARGUMENTS`, else the current working directory — which in a container means it profiles wherever the shell happens to be rather than where the docs clone is mounted. It now executes `resolve-docs-repo` and reports which rung answered. Its signal-less confirmation survives as a distinct question — whether to *write a profile* for a repo showing none of the usual signals — and cites `repo-resolution.md` §3's signal set rather than re-deriving it.

### Fixed

`/docs-profile`'s Phase 1 justified invoking the `model-routing` skill on the ground that "slash-command bodies cannot expand `${CLAUDE_PLUGIN_ROOT}`". That was verified false in a live run. The reason that survives is the one that was always doing the work: `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, so this plugin cannot read a `workflows-core` skill or reference by path whatever a command body can expand.

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

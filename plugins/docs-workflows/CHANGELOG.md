# Changelog

All notable changes to the **docs-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

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

# Changelog

All notable changes to the **docs-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.1.3] — 2026-09-09

### Added — a recorded review verdict names the version it was taken against

`/document` (keyed mode) cite the new `A recorded verdict names the version it was taken against` rule in
`workflows-core:escalation-rules`. The one-fix-cycle-plus-one-re-review cap assumes a fix cycle only
removes defects; on three live runs it **introduced** something the re-review then found, with the
budget already spent — so the run either shipped a known defect or fixed it and left the final text
unreviewed. Both end with a `PASS` on record beside a file the `PASS` never saw.

Each now states what the verdict covers, and where any edit followed it, the final report says so and
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

# References reference

`docs-workflows` bundles 14 files under `references/` — five top-level markdown files and two bundled subtrees. This page enumerates every file a command or agent actually cites by name (the five top-level files), grouped by concern below, then counts the two subtrees rather than listing each file inside them. The arithmetic: five named individually, plus 5 + 2 = 7 markdown pages counted (not enumerated) across the two subtrees — 5 + 7 = 12 accounted for, against 14 files on disk. The remaining two are non-markdown data or templates inside the `docs-profiles/` subtree, deliberately not listed as reference pages: a defaults file and an owners list, neither of them prose a reader would open. The subtree figures below are markdown-page counts specifically; the two data files already sit inside that same subtree and are not part of that count, so nobody should later "correct" a subtree figure by adding them back in.

The shared corpus every plugin in this family reads — the addressing grammar, the git and phase-handoff entry points, model routing, escalation and triage, cost/feedback/follow-up emission, the docs-grounding and doc-structure conventions, and the PRD format — ships in the companion `workflows-core` plugin and is enumerated on its own references page, reached through the loader skill rather than by path. What is listed here is what `docs-workflows` itself carries.

## Verification gates

The accounting a documentation run keeps about what it actually verified, and the two extractors that decide what there was to verify.

- `gate-ledger.md` — the six verification-gate outcomes (`RAN` / `DEGRADED` / `FAILED` / `UNAVAILABLE` / `SKIPPED_BY_USER` / `NOT_APPLICABLE`), the rule that no outcome is orchestrator-assignable to mean "I decided not to run this", the per-mode gate registry, the `UNAVAILABLE` conversion prompt, and the reviewer contract; consumed by `/document` and by the agents whose gates it registers.
- `repo-verification-gates.md` — how to extract a docs repo's own pre-PR checklist into the `repo_verification_gates` block a reviewer can check the written files against, augmenting the plugin's own gates rather than overriding them.
- `toolchain-preflight.md` — the Phase 0 environment check `/document` runs: deriving the required tool set from the resolved profile, the repo's config signals and the repo's own documented prerequisites, the tool→gate map, and the prompt that fires only when a required tool is missing.

## Git and handoff

The one handoff mechanic that belongs to a single command rather than to the family, executed against a **docs** repository.

- `finish-and-handoff.md` — the mechanics `/document` (keyed mode) uses for its inline-profiling-branch handling and its finish-and-handoff step: squash, opt-in push, copy-paste PR draft. The specs repo's own git entry points, and the code repo's, are elsewhere — `workflows-core:specs-repo-git` and `workflows-core:phase-handoff` for the first, the pipeline plugin's `dev-workflows:code-handoff` for the second.

## Authoring formats

- `release-note-types.md` — the release-note section map (`## Breaking changes` / `## Feature updates` / `## Fixes`, all three in one **release-notes.md** under a release-version heading), the per-section draft shape and prose rules, the deprecation-note rule, and Change Type sourcing; consulted by `release-notes-writer`.

## Bundled reference sets

Two subtrees carry bundled guidance too large or too domain-specific to enumerate file-by-file; each is counted here instead.

- `docs-profiles/` (5) — docs-profile authoring conventions for the built-in `example-docs` worked example (frontmatter, changelog, anchors, render verification, the docs-profile schema), consulted by `/docs-profile`, `/document`, and the `docs-frontmatter` skill.
- `handoff/` (2) — one input/output document-format contract per agent, read by the agent itself rather than by the dispatching command: one for `diff-summarizer`, one for `release-notes-writer`.

One of these subtrees (`docs-profiles/`) also holds the data and template files named in the introduction above, so its `*.md` count here is smaller than `find <dir> -type f` would report; `handoff/` is markdown only, and for it the two counts agree.

## Skills

One skill ships under `skills/` — reusable guidance packaged for the `Skill` tool, distinct from a `references/` file that a command or agent reads directly by path. The `model-routing` skill every pipeline command invokes at its classification step, and the `reference` loader that reaches the shared corpus, both ship in `workflows-core`.

| Skill | Invocable | What it's for |
|---|---|---|
| `docs-frontmatter` | Yes | Applies documentation frontmatter conventions — changelog entries, page owners, core metadata fields — when editing a page under any content root the applicable docs profile declares. |

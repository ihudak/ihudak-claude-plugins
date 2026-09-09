# References reference

`docs-workflows` bundles 18 files under `references/` — five top-level markdown files and three bundled subtrees. This page enumerates every file a command or agent actually cites by name — the five top-level files, and the four in `docs-workflow/`, which are enumerated as well as counted because each is a distinct entry point a command names — grouped by concern below, then counts the other two subtrees rather than listing each file inside them. The arithmetic: five named individually, plus 5 + 2 + 4 = 11 markdown pages across the three subtrees — 5 + 11 = 16 accounted for, against 18 files on disk. The remaining two are non-markdown data or templates inside the `docs-profiles/` subtree, deliberately not listed as reference pages: a defaults file and an owners list, neither of them prose a reader would open. The subtree figures below are markdown-page counts specifically; the two data files already sit inside that same subtree and are not part of that count, so nobody should later "correct" a subtree figure by adding them back in.

The shared corpus every plugin in this family reads — the addressing grammar, the git and phase-handoff entry points, model routing, escalation and triage, cost/feedback/follow-up emission, the docs-grounding and doc-structure conventions, and the PRD format — ships in the companion `workflows-core` plugin and is enumerated on its own references page, reached through the loader skill rather than by path. What is listed here is what `docs-workflows` itself carries.

## Verification gates

The accounting a documentation run keeps about what it actually verified, and the two extractors that decide what there was to verify.

- `gate-ledger.md` — the six verification-gate outcomes (`RAN` / `DEGRADED` / `FAILED` / `UNAVAILABLE` / `SKIPPED_BY_USER` / `NOT_APPLICABLE`), the rule that no outcome is orchestrator-assignable to mean "I decided not to run this", the per-mode gate registry, the `UNAVAILABLE` conversion prompt, and the reviewer contract; consumed by `/document` and by the agents whose gates it registers.
- `repo-verification-gates.md` — how to extract a docs repo's own pre-PR checklist into the `repo_verification_gates` block a reviewer can check the written files against, augmenting the plugin's own gates rather than overriding them.
- `toolchain-preflight.md` — the Phase 0 environment check `/document` and `/docs-init` run: deriving the required tool set from the resolved profile, the repo's config signals and the repo's own documented prerequisites, the tool→gate map, and the prompt that fires only when a required tool is missing.

## Git and handoff

The one handoff mechanic that belongs to a single command rather than to the family, executed against a **docs** repository.

- `finish-and-handoff.md` — the mechanics `/document` (keyed mode) uses for its inline-profiling-branch handling and its finish-and-handoff step: squash, opt-in push, copy-paste PR draft. The specs repo's own git entry points, and the code repo's, are elsewhere — `workflows-core:specs-repo-git` and `workflows-core:phase-handoff` for the first, the pipeline plugin's `dev-workflows:code-handoff` for the second.

## Authoring formats

- `release-note-types.md` — the release-note section map (`## Breaking changes` / `## Feature updates` / `## Fixes`, all three in one **release-notes.md** under a release-version heading), the per-section draft shape and prose rules, the deprecation-note rule, and Change Type sourcing; consulted by `release-notes-writer`.

## The documentation-portal scaffold

`docs-workflow/` (4) — the bulky, stable content the portal-scaffolding commands write, held here so the command bodies stay orchestration. Each file is enumerated rather than merely counted, because each is a named entry point a command cites when it says which part it is executing.

- `docs-workflow/scaffold-tree.md` — what a scaffolded documentation portal contains: the directory tree and why each section is standard, the per-directory stubs with their frontmatter and their "what does not belong here" half, the `nav:` generation rule, the two MkDocs configs, and the Vale config with its vocabulary-seeding rule.
- `docs-workflow/visibility.md` — the two-build public/internal model, the two traps that make the obvious checks useless (the dev server does not exclude; snippets cross the boundary invisibly), the two output-level CI gates and the conditional third, the marker convention both halves of gate 2 depend on, and the CI workflow the scaffold writes.
- `docs-workflow/repo-resolution.md` — the one docs-repo resolution ladder, in its two opposite forms: `resolve-docs-repo` for a command that needs a docs repository that already exists, and `resolve-scaffold-target` for the one command that needs a place to make one, plus the shared signal set both test against.
- `docs-workflow/contrast.md` — the WCAG 2.2 contrast thresholds a derived brand palette is held to, the relative-luminance formula with a worked example, and what a failing colour does (reported with its measured ratio, applied only on the operator's confirmation).

## Bundled reference sets

Two further subtrees carry bundled guidance too large or too domain-specific to enumerate file-by-file; each is counted here instead.

- `docs-profiles/` (5) — docs-profile authoring conventions for the built-in `example-docs` worked example (frontmatter, changelog, anchors, render verification, the docs-profile schema), consulted by `/docs-profile`, `/document`, `/docs-init` (the schema page, for the profile it writes), and the `docs-frontmatter` skill.
- `handoff/` (2) — one input/output document-format contract per agent, read by the agent itself rather than by the dispatching command: one for `diff-summarizer`, one for `release-notes-writer`.

One of these subtrees (`docs-profiles/`) also holds the data and template files named in the introduction above, so its `*.md` count here is smaller than `find <dir> -type f` would report; `handoff/` and `docs-workflow/` are markdown only, and for them the two counts agree.

## Skills

One skill ships under `skills/` — reusable guidance packaged for the `Skill` tool, distinct from a `references/` file that a command or agent reads directly by path. The `model-routing` skill every pipeline command invokes at its classification step, and the `reference` loader that reaches the shared corpus, both ship in `workflows-core`.

| Skill | Invocable | What it's for |
|---|---|---|
| `docs-frontmatter` | Yes | Applies documentation frontmatter conventions — changelog entries, page owners, core metadata fields — when editing a page under any content root the applicable docs profile declares. |

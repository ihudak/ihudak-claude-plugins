# Changelog

All notable changes to the **workflows-core** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [1.1.0] — 2026-09-06

### Added — the two session-wide hooks, and a serialisation the grounding artifacts never fixed

`notify-done` and `test-notify` now ship here. Both are session-wide rather than command-scoped, and every plugin in the family declares `workflows-core`, so one copy serves all of them instead of a copy per plugin (I4-3). Install or update `workflows-core` and both hooks arrive with it.

`grounding-format.md` gains §2.1, which fixes how a `[CG#n]`/`[DG#n]` finding is written to disk — one space after every key's colon, never alignment padding, keys in §2's order, an inapplicable field omitted rather than left empty. Nothing had fixed it, so a writer aligned one section of a `code-grounding.md` and not the next; a scan of that file then reported **140 findings as missing that were on the page**. §2.1 also states the reading rule that outlives the fix: resolve an id against the finding set you parsed, never by matching a column, and report a disagreeing count as a parse failure rather than as an absence.

### Fixed — a frame-set index is read, and every producer had been told it was not

`phase-handoff.md` §4.0's class register said a frame-set `index.md` was **unread**. It is not: `product-workflows:design-grounder` refuses to run on a frame set holding no index, and `grounding-verifier` returns `NO_INDEX`/`STALE_INDEX` on one. The index is **advisory** — read from the working tree, gated by nothing — and `/frames` now presents the advisory consent array. Until this fix it presented the unread array, telling the operator that nothing downstream reads a file `/brd-ground` refuses a frame set without, three lines above its own paragraph saying the set stays `NO_INDEX` for everybody else.

The register was verified against the tree rather than carried forward, which is how this surfaced: the gated row is an exact two-way match with §3.4's Input column (nine artifacts), and each advisory row was re-derived by opening the reader it names. The **unread** class now has no member — every artifact this family hands off turned out to have a reader once one was looked for.

### Fixed — the rest of the release-gating ledger

- **PS1** — an unwritable `.git` and a `$SPECS_PATH` that is not a repository are different states. The first is a silent no-op; the second now emits a named notice. Neither is ever fatal.
- **PS2** — `/frames` adopts a frame-set index kept under another name instead of refusing the set.
- **PS3** — the cost-boundary detector's *cut* test is now separate from its *claim* test. A command from outside this marketplace ends the open window without being claimable; before the split its spend was absorbed into somebody else's claim.
- **I4-6 / I4-7** — `<default-ref>` is resolved by probing for an `origin` remote and is owned by `specs-repo-git.md` §3.2, which `phase-handoff.md` now cites rather than redefining. Three git calls outside `require-on-main` had hardcoded `origin/<default>` too.
- **"this plugin" named the wrong plugin** in `cost-emission.md`, `feedback-emission.md` and `phase-handoff.md` §3.4. Each now names `workflows-core` outright, or says "the family" where the referent is family-wide — §3.4's row-F paragraph in particular, where the gate routinely runs across a plugin boundary and a one-plugin reading would stop the route at each one.

## [1.0.0] — 2026-09-03

### Added — the shared foundation of the `dev-workflows` plugin family

`workflows-core` is the second increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md` (the first extracted `guideline-reviewers`). It carries what more than one plugin in this family reads, so that a family member can be installed without dragging the rest of the pipeline along with it.

**Twenty-nine reference files**, moved from `dev-workflows` with their rules intact — what changed in the move is how they are *cited*, not what they say: the addressing grammar, the specs-repo git entry points and phase handoff, model routing, escalation, finding triage, grounding and grilling technique, the PRD format, cost / feedback / follow-up emission, and the price table they cost against.

**Six commands** — `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`, `/statusline` and `/frames`. The first five are family-meta: they log friction about the plugin family itself or drive its status line. `/frames` indexes a design frame set, which every phase of the pipeline may hold.

**Five agents** — `code-scanner`, `doc-fixer`, `docs-grounder`, `frame-describer` and `impl-maintenance` — each dispatched by commands in more than one plugin, as `workflows-core:<agent>`.

**Two skills.** `model-routing` is the one that moved. `reference` is new, and it is the mechanism the whole split turns on: `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, so a dependent plugin cannot read a shared reference by path. `Skill(skill: "workflows-core:reference", args: "<name>")` reads one reference by name; an optional second argument names an entry point within it to execute inline. One argument-taking skill serves the whole corpus, rather than one wrapper per reference.

**The cost helper**, `scripts/session-cost.py`, and the status-line script beside it. New alongside them is `scripts/command-namespaces.json` — namespace to that plugin's own command names, one entry per plugin of this marketplace that ships commands — which is what command boundaries now resolve against.

`dev-workflows` 3.26.0 declares `workflows-core` as a dependency, so installing it installs this. The two changes below are stated against the same machinery as it shipped inside `dev-workflows` up to 3.25.0, because that is where it ran until now.

### Removed — `session-cost.py --commands-dir`, a breaking change for direct callers

**The flag is gone, not deprecated.** Anyone invoking `scripts/session-cost.py` by hand or from their own tooling and passing `--commands-dir` gets an unknown-argument error and must drop it. That failure is loud on purpose — an unrecognised flag is an error, never a silently ignored one — but it is real, so it is stated here rather than left to be discovered.

Nothing replaces it. The flag existed to hand the script one plugin's `commands/` directory as the set of names a slash-command boundary could be drawn from, and that is precisely the assumption the split had to abandon: a family that spans several plugins has no single such directory. Boundaries now resolve against `scripts/command-namespaces.json`, shipped beside the script and read with no flag and no path assumption. `--namespaces <path>` overrides that manifest and exists to be pointed at a test fixture; where it resolves to nothing, boundary detection is off and every claim is reported unmatched and dropped, rather than guessed at.

### Fixed — a replayed cost claim could absorb a sibling plugin's spend

A command that cedes the session (`/prompt-brainstorm`, `/prompt-grill-me`) cannot write its own cost entry, so it records its labels and the next cost-emitting run writes the entry on its behalf, splitting its window at the transcript's record of where that run began. The boundary used to be accepted only as `<this plugin>:<this plugin's own command>` — resolved against whichever single plugin supplied the command set. Once the family spanned more than one plugin, an intervening command **from a sibling plugin** was not recognised as a boundary at all, and a claim is given the segment up to the next boundary of any kind. The claim therefore swallowed the sibling's run whole.

Nothing was ever double-billed and no entry already written on disk was corrupted. What went wrong is attribution *between two entries of the same replay*: the deferred command's entry was charged for work it did not do, and the replaying run's own remainder was short by exactly that amount. Reproduced at 9000 tokens claimed where 5000 was correct.

Both halves of a boundary now resolve against the manifest — the namespace must be a key of it and the name must appear in *that key's* list — which is why widening the accepted namespaces alone would not have been enough, and why the fix still rejects a bare built-in whose name a plugin here happens to share, and still rejects another marketplace's identically-named command. `session-cost.py --selftest` pins each of those properties against the broken implementation it exists to catch, including the half-fix that widens namespaces without widening the per-namespace name sets.

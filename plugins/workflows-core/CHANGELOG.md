# Changelog

All notable changes to the **workflows-core** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

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

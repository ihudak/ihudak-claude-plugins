# workflows-core — plugin dependencies & optional companions

There are two kinds of relationship a plugin in this family can have with another plugin, and they are not variations of one thing. A **declared dependency** is a hard requirement the host resolves at install time. An **optional companion** is resolved at runtime and must degrade a feature when it is absent. Everything below turns on which of the two a given relationship is.

## Declared dependencies (hard, resolved by the host)

Claude Code plugin manifests **do** express a dependency: `.claude-plugin/plugin.json` carries a `dependencies` array. A declared dependency is installed alongside the plugin that names it, and an unsatisfied one **disables** the plugin rather than letting it half-run — the failure mode is named and loud, not a feature quietly doing less.

**`dev-workflows` hard-requires `workflows-core`**, and that is structural rather than stylistic. `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, so a dependent plugin cannot read the shared reference corpus by path; it reads each reference through the loader skill (`workflows-core:reference`, one argument naming the reference and an optional second naming an entry point within it) and dispatches core's agents natively as `subagent_type: "workflows-core:<agent>"`. Every pipeline command loads at least one core reference in its first phase, so there is no degraded mode to fall back to and none is wanted: a run that could not read `addressing`, `specs-repo-git` or `phase-handoff` would not be a smaller run, it would be a run doing the wrong thing quietly.

**Dependencies are declared bare-name, never version-ranged.** A version range resolves against *git tags*, and one repository tag cannot express a version per plugin — ranges would force per-plugin tags and a release-process change. While every plugin in this family ships from one repository at one commit, a range buys nothing that the commit does not already guarantee.

## Optional companions (soft, resolved at runtime)

A companion outside the family is **convention + runtime-resolve + graceful fallback**: nothing declares it, the run probes for it, and a miss degrades exactly one feature.

| Companion | Used by | Relationship | Fallback when absent |
|-----------|---------|--------------|----------------------|
| `superpowers` (skill `brainstorming`) | `/prompt-brainstorm` | Recommended | Embedded technique; no hard dependency. |
| `prose-style` (a marketplace sibling) | `docs-style-checker`; planning-doc style checks | Optional companion | `docs-style-checker` falls back to it when no repo-configured prose linter exists; `/epics` and `/release-notes` skip the style gate entirely if it is absent. |

## External tools and services

**No command in the PRD-authoring pipeline requires an external tool** — that pipeline reads and writes one markdown tree and calls no service. The commands outside it do reach the network, and saying otherwise would misdescribe them: `/dev-workflows:vuln` fetches CVE records from the NVD REST API and `/dev-workflows:upgrade` queries package registries, both by design; `docs-grounder` shells to `qmd` when it is installed, and `diff-summarizer` and `dev-workflows:code-handoff` §2.6 to `gh`, each degrading gracefully when it is absent. A user who wants their work in an issue tracker syncs it themselves; no plugin in this family ever learns whether one exists.

## Attribution, not a companion

**`mattpocock-skills` is not a dependency of this family and does not belong in either category above.** `references/grilling-technique.md` and `dev-workflows:bug-diagnosis` are both **adapted from** that author's `grilling` and `diagnosing-bugs`, and both say so. Since those skills now ship in the official marketplace, the distinction is worth stating outright: nothing here resolves them at runtime, nothing degrades when they are absent, and installing them changes no behaviour of any plugin in this family.

**Why they are forks rather than dependencies** is recorded where the fork lives — see `references/grilling-technique.md`'s *Relationship to the upstream technique it was adapted from*, which compares the two on cadence, depth, the no-human-turn case and altitude, and says which way to jump on each. The short version: the technique is invoked from eight commands at three depths, one of which may run unattended, and a mid-run dependency on a plugin outside this family is precisely what the optional-companion rule above forbids.

## Marketplace siblings (independent plugins, same marketplace)

`prose-style` and `obsidian-llm-wiki` ship alongside this family in the same marketplace but are versioned independently and depend on nothing here.

# dev-workflows — companion plugins & dependencies

dev-workflows is **self-contained**: no command hard-requires another plugin, and **no command requires an external tool** — it reads and writes one markdown tree and calls no service. A user who wants their work in a tracker syncs it themselves; the plugin never learns whether one exists. There is **no
dependency-manifest field** in `.claude-plugin/plugin.json` (Claude Code plugins don't express one), so
every cross-plugin relationship is **convention + runtime-resolve + graceful fallback** — a missing
companion degrades the feature, never breaks the run.

## Recommended companions

| Companion | Used by | Relationship | Fallback when absent |
|-----------|---------|--------------|----------------------|
| `superpowers` (skill `brainstorming`) | `/prompt-brainstorm` | Recommended | Embedded technique; no hard dependency. |
| `prose-style` (in this marketplace) | `docs-style-checker`; planning-doc style checks | Optional companion | `docs-style-checker` falls back to it when no repo-configured prose linter exists; `/epics` and `/release-notes` skip the style gate entirely if it is absent. |

## Attribution, not a companion

**`mattpocock-skills` is not a dependency of this plugin and does not belong in the table above.**
`references/grilling-technique.md` and `references/bug-diagnosis.md` are both **adapted from** that
author's `grilling` and `diagnosing-bugs`, and both say so. Since those skills now ship in the
official marketplace, the distinction is worth stating outright: nothing here resolves them at
runtime, nothing degrades when they are absent, and installing them changes no behaviour of this
plugin.

**Why they are forks rather than dependencies** is recorded where the fork lives — see
`grilling-technique.md`'s *Relationship to the upstream technique it was adapted from*, which
compares the two on cadence, depth, the no-human-turn case and altitude, and says which way to jump
on each. The short version: this plugin invokes the technique from eight commands at three depths,
one of which may run unattended, and a mid-run cross-marketplace dependency is precisely what the
self-contained rule above forbids.

## Marketplace siblings (independent plugins, same marketplace)

`prose-style` and `obsidian-llm-wiki` ship in the `ihudak-plugins` marketplace alongside
dev-workflows but are versioned independently.

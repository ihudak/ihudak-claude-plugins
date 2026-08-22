# dev-workflows docs restructure — open items

**Branch:** `iv-gu/docs-restructure` · **Version:** 2.57.0 · **State:** all gates pass (`check-docs.sh --selftest` at 15 cases, `check-docs.sh --root .`, `check-id-grammar.sh` both modes, `validate-catalog.py`, spec-ID census), not yet pushed.

This file was written before compaction to carry the review's findings across it. **Every item below has now been closed** in the fix wave of 2026-08-22 — the record is kept so the reasoning, and the two rejected items, survive the branch.

## A. Cosmetic minors — six, all closed

| # | Item | Disposition |
|---|---|---|
| 1 | `docs/workflow.md`'s Jira-status bullet paraphrased the retired README with no primary source cited | **Fixed** — now cites `references/workflow-states.md`, which states the same thing outright and stores no status of its own. |
| 2 | `docs/reference/environment.md` attributed "the bookkeeping is not committed" to `specs-preflight` | **Fixed** — the commit is the terminal `commit-artifacts` step's; both share the §3.1 writable gate, which is why the consequence was true and only the attribution loose. |
| 3 | `docs/commands/release-notes.md`'s `## Example` read dev-first | **Fixed** — the PM run and the dev re-run now get equal treatment, matching `## Who runs it`. |
| 4 | `docs/commands/ready.md:15` omitted the single-Epic case its own parenthetical states | **Fixed** — the two commands part company as soon as spec'd Epic subfolders exist at all. |
| 5 | `docs/commands/ready.md:71`'s See-also phrasing needed a second read | **Fixed** — recast as "the opposite extreme on the same gate". |
| 6 | The plugin README's pitch enumerated phases, omitting `/epics`, `/release-notes`, `/ready` | **Fixed** — names the spine explicitly and hands completeness to the table below it. |

## B. Findings that had no durable record before this file — all closed

| # | Item | Disposition |
|---|---|---|
| 7 | Follow-ups had two "primary location" answers: `$SPECS_PATH` in `workflow.md` + `environment.md`, the vault in `follow-ups.md` | **Fixed** — `follow-ups.md` is the authority; both other pages now name the vault first and point at the full ladder. |
| 8 | `docs/commands/ready.md`'s collapsed node `p678` drifted from the source headings | **Fixed** — relabelled verbatim, matching `commands/ready.md`'s `## Phase` headings and the equivalent node in `epics.md`. |
| 9 | `docs/workflow.md`'s diagram showed `/epics → /specify` as the only path into `/specify` | **Fixed** — `createvi -->\|VI-level spec\| specify` added. |

## C. Gate follow-ups — all closed

| # | Item | Disposition |
|---|---|---|
| 10 | The skills sub-check's direction 2 had no selftest case | **Fixed** — a documented-but-nonexistent skill case added; the selftest went 11 → 15 cases (this one plus three for the new check 8). |
| 11 | The spec-ID census was constraining the corpus rather than describing it | **Fixed** — the README clause held solely to keep the counts steady is now plain English; `scripts/spec-id-baseline.txt` regenerated at −1 on each of `[Uxx]`/`[ACxx]`/`[TCxx]`, with the reason in its header. Verified before regenerating that no concrete `[U01]`-style identifier moved. |
| 12 | D2's fix was defended by no persisted gate | **Fixed** — `check-docs.sh` **check 8**: every command handing `emit-cost` a fixed `phase`/`role` pair has a matching `references/cost-emission.md` §7 row, and no §7 row names a command that emits no fixed pair. Proven to fire in all three directions (missing row, drifted value, orphan row) on both the real tree and the fixture. |

## D. Owner decisions — settled 2026-08-22

**D3 and D6 both resolve into one change: the role vocabulary is four roles, not five. `team` is folded into `dev`; `QA` is retired outright.**

Ivan's ruling: `dev` and `team` denote the same thing in this workflow, `QA` "looked weird", and a role carrying a single command reads as an aside rather than a lane. Keep whichever name is used most.

`dev` is that name, on two grounds:

1. **Usage.** `dev` already labelled four of the five delivery-lane call sites (`/design`, `/implement`, `/document`, and `/release-notes`'s inferred late run) against `team`'s one (`/ready`). The same test Ivan applied to `QA` — one command looks like an aside — applies to `team`.
2. **Collision.** `team` is a live identifier elsewhere in the plugin: `jira-reader` emits a per-Epic `team` field verbatim from Jira Epic frontmatter (`[DTT] Team Storage`), consumed by `epic-writer`, `epic-reviewer`, and `references/pre-lint.md`. Two meanings of one word in one plugin is the kind of thing that silently corrupts a later sweep. Every `team:`-the-Jira-field site is deliberately untouched.

Carriers changed: `references/cost-emission.md` §7, `references/workflow-states.md` (both ladders), `references/next-phase-offer.md`, `references/session-hygiene.md`, six command files (`ready`, `document`, `implement`, `design`, `create-ard`, `specify` — `emit-cost` calls, next-phase offers, `/rename` lane tags, one `choices:` option), and eight docs pages including both Mermaid carriers (`docs/workflow.md`'s `QA` subgraph, now merged into `DEV`, and the Roles table). Nine cost phases, unchanged — only the role label moved. Check 8 now defends the `§7`-vs-command half of this.

## E. Not to be "fixed" — rejected findings, recorded so they are not re-raised

1. **`ROOT` and `OWNER_REPO` in `check-docs.sh`'s `RUNTIME_VARS`.** The final review called them dead exclusions. They are live and correctly excluded: `$ROOT` is read at `hooks/changelog-owners-reminder.sh:10`, `$OWNER_REPO` at `references/phase-handoff.md:70,166,168`. One is a hook-local shell variable, the other a reference template placeholder; neither is user-settable. **Do not remove them.**
2. **A reviewer's claim that `CLAUDE.md`'s taxonomy "uses QA throughout".** It contains zero occurrences of "QA". Acting on that finding would have made twelve consistent pages wrong to match one.

## Carried forward, outside this branch

The role collapse touches files that are `cp`-ported to `mgd-claude-plugins` and hand-adapted for `ihudak-copilot-plugins`. Both editions still carry the five-role vocabulary and the retired `QA` label wherever their own copies of these references live. The port is its own change — see the cross-repo porting notes before starting it.

# Whole-round review — sub-projects I and J (2026-08-17)

Scope set by `specs/2026-08-16-next-whole-round-review-scope.md`: canonical range `bcffb4c..748817b` — sub-project **I** (2.51.0), sub-project **J** (2.52.0, phase-handoff gates), plus `clear-deferred-minors`, `persist-j-decisions`, and the post-J bugs-first pass. 36 product files, 87 commits, +683/−328.

Three reviewers on Fable 5, at most two concurrent: **gate contract vs. its callers**, **claims that expired**, **cross-edition parity**. A fourth axis — mechanical canonical↔mgd parity — was run directly.

## Verdict

Two Critical defects, four Important, nine Minor. All fixed across three editions in commits `2d8960c`, `4461510`/`8194f37`, `9009a66`/`25c37b1`/`36d2da5`, `3e4ac2b`.

## Critical 1 — the gate ran before the fetch it depends on

`create-vi.md` and `design.md` executed `require-on-main` **before** `specs-preflight`; the other five consumers order it the other way. `phase-handoff.md:99` states the dependency: the gate "runs immediately after `specs-preflight`, so it reuses that step's best-effort `fetch` — no second network call." Its own §3.2 primitives perform no fetch.

**Reproduced in a two-clone git harness, not reasoned about.** After a web-UI merge with no intervening fetch:

| Gate position | Row reached | Outcome |
|---|---|---|
| before preflight | A misses (stale `origin/main`); §3.2 primitive 4 finds the deleted branch's stale remote-tracking ref | **D/E hard stop** — "was never handed off" |
| after preflight | A matches | **pass** |

User-visible: merge the `/idea` PR, run `/create-vi <KEY>`, get told the idea was never handed off. Fixed by lifting the preflight above step 3 in both commands — no renumbering, because `specs-preflight` self-gates on `$SPECS_PATH` (§3.1) and step 4's unset-check still follows, keeping `unmanaged` reachable in the idea ladder as rung 1 documents.

## Critical 2 — the row order that CLAUDE.md taught was the one J deleted

Every top-level guidance and changelog document enumerated the ten states as `H/I/A/B/C′/C/D/E/F/G` — **G last**. J's own fix wave (`ccb30b2` F1) moved G to third *because* G-last is shadowed by D/E/F (all key on "not on ref") and unreachable. The mirrors were written hours before the reorder and never revisited. `phase-handoff.md` itself was correct throughout.

**Seven sites**, across three editions: three CLAUDE.md/copilot-instructions.md, three CHANGELOG.md, and copilot's README catalog. The seventh was found only by the post-fix residue sweep, after the six the review named were already fixed.

## Important

- **Row B's condition excluded the case row B exists for.** It required "the caller is the artifact's own canonical author", exemplified by two caller/artifact pairs matching no gate any command performs. The real case — `/design` resumed on its own `design/` branch gating the `specification.md` that branch amends — fails an authorship test, since `/specify` authored that file. Left as written, a `/design` resume falls to row C, whose repair offer re-grounds the session on the un-amended spec: the Risk 4 outcome. Restated as **branch ownership**, which `:137` and `specs-repo-git.md` §3.6 already said the test was.
- **Rows D/E scanned remote refs only** while §2.2's producer side tests local *and* remote. A deliverable committed after a failed push exists only locally → `absent` → `/create-ard` proceeds printing "If a VI exists on a branch, this run would have stopped; it does not, so none does." Now scans `refs/heads` too.
- **`/ready`'s exemption was absent from the contract.** §3.7 stated unconditionally that every stopping row means the caller does not proceed; `/ready` never stops, because reporting is its function. `ard-resolution.md:53` already carved it out; `phase-handoff.md` now does too.
- **`read-only-repos.md` "Cited by the eight commands that dispatch them"** — **no command cites it**. Its consumers are three agents; commands reach it via `escalation-rules.md`. Sub-project I had a requirement on this sentence, changed "seven"→"eight", and recorded PASS: it fixed the count while the verb stayed false.

## Minor (all fixed)

`/epics` map showed the gate after jira-reader and the scan when it runs before both · a dead phase name (`Pre-Phase 2`) · `jira-input-resolution.md` declared 5 consumers of 8 · `impl-maintenance` missing from 7 map lines · five reference docs missing from canonical/mgd README catalogs and two from copilot's · a drifted `:230` line pointer (removed rather than corrected — a rule cited by number cannot drift) · a slash-form `/specify` in a copilot Python comment.

## Clean

Consent arrays byte-identical across all eight producers (md5-verified). No consumer stops on `absent` except the sanctioned `/design`. All seven test `stopped` before `on_main`. Row order free of shadowing. Counts correct — 21 commands, 33 agents, 4 hooks, 8 producers / 7 consumers, ~20 more. All 21 agent "used by" lines accurate. Every §-reference added in the range resolves. Copilot's J port complete and section-identical modulo sanctioned dialect; canonical↔mgd parity exactly the five identity files.

## Method notes worth keeping

- **Three checks of the README catalog gave three different answers.** A mentioned-anywhere grep found 2 files; the reviewer's section read found 2 different ones; only a set difference over the catalog section found all 5. A wrong pattern (path-prefixed vs bare basename) reported all 34 copilot files missing.
- **`head -1` on a grep found `model_routing` comments, not dispatch sites**, in two commands — nearly writing a fresh false claim into the workflow map while fixing an old one.
- **A validator check was cut before shipping** because it asserted a convention that does not exist (catalog and `plugin.json` descriptions are independently authored). It would have failed on correct content.
- The residue sweep — "what did this fix make false?" — found the seventh row-order site after the six named ones were closed.

## Still open

No live end-to-end handoff has been exercised. Every producer/consumer check remains static; the git harness covers the gate primitives, not `gh pr create`. The first genuine handoff is still the only proof a PR actually opens.

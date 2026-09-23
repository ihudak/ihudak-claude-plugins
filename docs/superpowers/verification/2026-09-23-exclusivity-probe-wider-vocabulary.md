# Verification: the exclusivity probe, wider vocabulary (rounds 1 and 2)

**Dates:** 2026-09-22 – 2026-09-23 · **Branch:** `iv-gu/excl-probe-wide` · **Commits:** `1515bddc` (round 1), `0a824488` (round 2), plus the provenance removal and this record · **Predecessor:** `2026-09-22-exclusivity-probe-whole-tree.md`

The 2026-09-22 pass ran `CLAUDE.md`'s five exclusivity phrases and recorded that they are not the vocabulary. This work ran the wider vocabulary in two rounds over `plugins/` plus the repo-root `README.md` and `CLAUDE.md`. **It is not exhaustive**: round 2 found more than round 1, and its readers named claim forms neither round matched (see *Not yet run*). The user decided to ship these fixes and run round 3 separately.

## Method

Each round:

1. **A wrap-insensitive, emphasis-stripped probe** (whitespace collapsed in file and pattern; round 2 also strips `*` and `_`, because `the **only**` matched no phrase in round 1). The hits are sliced by directory, one read-only agent per slice.
2. **Both sides are verified before anything is edited.** A *checkable* claim is one about the repository's contents. `RUN` (what a run does), `RULE` (a normative instruction) and `HISTORY` (a changelog's record of a past state) are triaged out.
3. **Verdicts**: `FALSE`, `SCOPED` (literally false and rescued by a sibling sentence), `STALE-AT-RELEASE` (changelogs: true when written, false today), `SOUND` and `UNVERIFIED`. A *premise false / conclusion true* tag marks lower severity.
4. **Fixers on disjoint file sets**, each sweeping the claim's *subject* rather than its wording, with independent review waves until a wave returned nothing to fix.

| Round | Families | Hits | Files | Slices |
|---|---|---|---|---|
| 1 | `the only <noun>`, `sole`, `only <role>`, `the one <noun>`, `no other`, `nowhere else`, `exactly one`, `<noun> alone`, `exclusively`, `no <role> reads`, `nothing reads`, `single source of truth` | 1,415 | 224 | 7 |
| 2 | inventories (`consumed/read/cited/… by`), counts (`the N <role>`), `every/all other`, passive `by nothing`, `none of` / `neither … nor`, `has one/no <role>`, `the whole of` / `the single X` / `nowhere`, `<verb> only`, wider `nothing … reads`, bold-broken round-1 phrases | 2,587 | 250 | 10 |

The round-2 instrument's families are recorded in the table above. The script itself was session-local, as `CLAUDE.md`'s Seventh refinement says of the one before it: write your own and keep the method.

## Results

- **Round 1:** about 40 `FALSE` and 35 `SCOPED` claims across 85 files. The worst: `phase-handoff` §3.7 named `/ready` as the sole caller that continues past a stopping row, but `/brd-reconcile` does too, at two sites. Also: `depends_on` was called unread (`/brd-proposal` reads it), and the retired shared front-end was still named as live.
- **Round 2:** about 100 `FALSE`, 45 `SCOPED` and 8 `STALE-AT-RELEASE` claims across 108 files. Most were inventories and counts that carry no exclusivity word: consumer lists short by one to five members, "four statuses" where there are six, "seventeen commands that offer a PR" that were really `handoff-to-main` producers.

**Behaviour defects the probe and the reviews of its fixes found**, all now fixed. None of them is a wording defect; each is a run that did the wrong thing:

1. **An Epic key sent to a PRD-level command.**
   - `/create-prd <EPIC-KEY>` wrote a `prd.md` into the Epic's folder.
   - `/update-prd`, `/prd-proposal` and `/brd-proposal` named runs that refuse that folder.
   - All four now refuse an `EPIC-` folder. Every remedy or offer that could have named an Epic's key now names the PRD folder's.
2. **`$SPECS_PATH` unset.**
   - `/idea` had no stop and aimed its first write at `/specifications/`.
   - Keyed `/implement` and `/document` answered a key with a "not found, re-enter" loop that could not succeed.
   - All three now stop and name the variable, and `specs-repo-git` §3.1 now states the unset case.
3. **Keyed `/implement` had no disposition for a key resolving to nothing.**
4. **`/brd-reconcile` could rewrite a sentence in an effort proposal in place.** A proposal already sent to a customer changed with no archived revision and no correction/re-estimate classification. By user decision it is now never edited, and the remedy is a re-run of the proposal command.
5. **The slice remedy tables overlapped and missed a state.** The "non-empty" row overlapped the "unallocated" row, and no row covered a missing ledger. This was pre-existing in `/update-prd` and `/epics`. It is fixed at every copy, `/brd-reconcile`'s Phase 14 included.
6. **Capture-at-block classification is now by rule**, and five agent-contract or record-parse gaps now fire `emit-block`.

**Review waves on the fixes** found 13, 7, 16, 8, 10 and 4 defects in turn, and most of them were introduced by earlier fixes. `CLAUDE.md` already records this ("the risk peaks … when someone is already being careful"); these numbers are one more measurement of it.

## Method defects found (in my briefs and tooling)

- **Line-level exclusion drops claims.** Excluding a hit because round 1 matched *the same line* drops a different claim on that line. Exclude per match, not per line.
- **`only <noun>` matches `read-only <noun>`.** About 4% of that family's hits were noise. Guard it with `(?<![-\w])only`.
- **The paragraph is not the unit.** Several falsified twins sat in the neighbouring bullet, table row or section. Read the enclosing list, table or section, plus any other place in the same file that enumerates the same set.
- **The verdict set needed `STALE-AT-RELEASE` and `HISTORY`** for changelogs. Round 1's set had neither.
- **`agents/` and `product-workflows/docs/` are hard-wrapped too.** The brief named only `commands/` and `references/`.
- **Subagents see the main checkout's `CLAUDE.md`, not the worktree's.** Three readers reported a `CLAUDE.md` defect that the branch had already fixed, because the project `CLAUDE.md` loaded into their context came from the primary checkout. Tell every agent working in a worktree to read the worktree's copy.
- **A `grep -l <file>` inventory recipe misses generic readers.** For example, "every markdown file under X" is a reader of every file under X, and a grep for one file's name cannot see it. That is how the proposal-edit behaviour defect hid.

## Not yet run (round 3's starting vocabulary)

These forms were reported by round-2 readers and matched by no family:

- **Location-authority claims**: "the page that defines X", "is where X lives".
- **`N further / N more <noun>` followed by a list**: "Two further agents …", "Twenty more …".
- **`shared with/by` inventories**: "(shared with `/create-prd` and `/update-prd`)".
- **`neither X, Y, or Z` without `nor`.**
- **A singular `is the exception`** used as an exclusivity claim.
- **Definitional parenthetical lists followed by a count**: "(… `/frames`) … four of the five".
- **Named subsets whose complement is implied**: "for A, B and C, `X` is the only …".
- **Possessive or adjective counts**: "its six commands", "the family's four other …".
- **Write-target lists with verbs outside the inventory set**: "write into", "scaffolds", "charge to".
- **Fidelity claims between copies**: "appear … unchanged, in style and in label".
- **Arithmetic splits across plugins**: "five more … three and two respectively".
- **Claims about another command's behaviour in a state**: "which stops on the same emptiness". `CLAUDE.md` records that no gate can see these.
- **Frontmatter `description` inventories**: "consumed by the X agent", "Referenced by …".
- **Temporal "today" and pending-change claims**: "Step 3 today visits only …", "the command's change to make".

## Not verified

1. **No command body was executed.** Every finding is a comparison of a claim against the tree. The behaviour fixes above were read, not run.
2. **`docs/superpowers/` was out of scope**, as `CLAUDE.md` scopes the probe. That archive named the organisation this edition was written inside and its internal repositories. It was flagged to the user on 2026-09-23, who decided the same day: the design specs and plans under `docs/superpowers/specs/` and `docs/superpowers/plans/` were removed from the tree (all but the active CLAUDE.md split design; each remains readable with `git show 62e791e8:<path>`), every live citation of one was repointed at that command, the names were scrubbed from every other file outside the plugin changelogs, and `scripts/check-docs.sh` check 19 now fails the build if one returns. Git history was not rewritten.
3. **Run-behaviour prose was triaged out, not checked.** It is still the large majority of hits.

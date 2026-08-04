---
tags:
  - tasks-exclude
---

# `/document` Jira-mode consolidated repo gate — design

**Status:** Shipped in dev-workflows v2.11.0 — pre-implementation design snapshot, kept as authored.
**Date:** 2026-07-10
**Target:** `dev-workflows` plugin (`/workspace/ihudak-claude-plugins`), `commands/document.md` — Jira mode (Mode A) only
**Release:** MINOR `v2.11.0` (user-visible workflow behavior; additive, no breaking change) — confirm during spec review

## Goal

Replace `/document` Jira mode's *reactive, per-slug* missing-repo escalation with a single **consolidated upfront repo gate**, shown as soon as the repo set is known (Phase 4), that:

- lists the expected repos (from the Jira PR links) and which are mounted vs missing,
- names the missing ones explicitly,
- states the cost of skipping them (their code is not diff-summarised or checked against the VI's requirements → discrepancy analysis is partial), and
- offers **mount-the-missing-repos-now-and-re-scan** / **proceed Jira-only** / **cancel**.

The happy path (all repos mounted) gains at most a one-line confirmation and no new friction.

## Background — current behavior (as shipped)

`/document` Jira mode already resolves repos and already degrades softly; this effort reshapes the *presentation*, it does not invent the capability.

- **Phase 3** runs `jira-reader`, yielding `pull_requests` (PR links across the VI + linked Epics). Run *after* implementation and Jira re-import, this is the authoritative affected-repo list.
- **Phase 4 (Resolve repos)** filters PRs by status, groups by repo slug, builds a slug→clone map by scanning `$REPOS_PATH`, and resolves each slug:
  - one match → use it; multiple → auto-prefer (`-repo`/`_repo`/`_fast`/alphabetical) and show at plan approval; **zero match** → escalate *per slug* via the `Repo unresolved (zero matches) — /document` rule in `references/escalation-rules.md` with choices `["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]`.
- **Phase 5** aggregate fallback: if *every* PR is unresolved, one gate offers "Proceed with Jira-only content".
- **Phase 5.8** discrepancy analysis (Jira vs Spec vs Code) loses code coverage for skipped repos — their claims render `(not verifiable)` — but nothing ties that consequence back to the skip decision.
- The full **expected-vs-mounted picture** appears only in the **Phase 9** final report (`### Repos analysed`), i.e. after all the work.

### Gaps this closes

1. **No early, whole-set view.** Missing repos surface as a string of per-slug interrupts, not one informed decision; the operator can't see "5 expected, 1 missing" up front.
2. **Skip consequence is implicit.** Nothing says "skipping repo X means its code won't be checked against requirements."

### Explicitly out of scope (decided during brainstorming)

- **Repos affected but not linked in Jira** (e.g. a wrong Jira ID on a PR so it never links). Acknowledged edge case; not solved — `/document` trusts the Jira-derived set.
- **Cross-checking against `/design`'s declared repos** (brainstorming option B). Dropped: `/design`'s repo declaration is reliable-but-not-100%, and post-implementation Jira is the authoritative source, so the cross-check adds complexity without covering a case the Jira set doesn't already cover.

## Design

All changes are confined to `commands/document.md` **Phase 4**, Jira mode. No subagent, reference, hook, or sibling-plugin change.

### Placement

The repo set is unknowable until `jira-reader` has run (Phase 3), so the gate lives at the **top of Phase 4**, immediately after the slug→clone scan — the earliest honest point, and before the expensive Phase 5 diff work. Plan approval (Phase 2) is unchanged; it still happens before repos are known.

### The gate

After the existing slug→clone scan (Phase 4 step 3), compute:

- `expected` = unique in-scope repo slugs from the status-filtered PRs,
- `mounted` = slugs that resolved to a path,
- `missing` = slugs with zero matches.

Then:

- **`missing` empty → no gate.** Print one line, e.g. `Resolved 5/5 repositories from Jira PRs.`, and continue. Behavior is otherwise identical to today.
- **`missing` non-empty → present ONE consolidated summary** and block on a choice:

  ```
  This VI's Jira PRs span <N> repositories. <M> mounted, <K> missing:

    ✓ <mounted slug>            ✓ <mounted slug>
    ✗ <missing slug>            (<n> <status> PRs — not found under $REPOS_PATH)

  Missing repos are skipped: their code won't be diff-summarised or checked
  against the VI's requirements, so the discrepancy analysis will be partial.

  choices: [
    "Mount the missing repo(s) now — I'll wait, then re-scan (Recommended)",
    "Proceed without them — Jira-only for the missing repos",
    "Cancel",
    "Specify a different absolute path for a missing repo",
    "Other… (describe)"
  ]
  ```

  - **Mount now & re-scan** — pause; when the user confirms the clones are present under `$REPOS_PATH`, re-run the Phase 4 step-3 scan and re-render the summary. Loop until `missing` is empty or the user picks another option. (This is the existing "I'll clone it — wait" behavior, applied to the whole missing set at once.)
  - **Proceed Jira-only** — record every currently-missing repo's PRs as unresolved/skipped (identical downstream state to today's per-slug "Skip"); continue. The Phase 9 report already notes the missing PR content.
  - **Cancel** — abort the run.
  - **Specify a different absolute path for a missing repo** — the existing "Specify a different absolute path" path, for one slug; record it as that slug's `repo_path` and re-render.

- **Per-repo granularity without a per-repo matrix:** the operator gets effective per-repo control through the mount-and-re-scan loop — mount whichever repos are available, re-scan, then "Proceed Jira-only" for whatever remains. No per-slug prompt storm.

### What is preserved (no regression)

- The **multiple-match** auto-prefer rule and its plan-approval override list — unchanged; those repos are `mounted`, not `missing`.
- The **`host: other`** unsupported-PR handling (recorded as `unresolved`, carried to Phase 9, non-blocking) — unchanged.
- The `references/escalation-rules.md` `Repo unresolved (zero matches) — /document` rule stays the source of the choice semantics; Phase 4 cites it, now framed as one consolidated gate rather than a per-slug loop. (Rule text extended only if needed to name the "mount all / proceed Jira-only" framing.)
- **Phase 5**'s `REPO_MISSING` "should not happen after Phase 4" note stays valid.

## Scope & boundaries

- **Jira mode (Mode A) only.** Mode B (direct edit — no repos, no Jira) is untouched.
- **`/design`'s hard repo gate is untouched.** This is `/document`'s soft gate; the two are independent.
- **Orchestrator-only:** the sole edited file is `commands/document.md`. `jira-reader`, `diff-summarizer`, `doc-planner`, the reviewers, and every reference except (optionally) `escalation-rules.md` are untouched. Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## Invariants preserved

- **Happy path unchanged:** all-mounted runs behave as today apart from the one-line "Resolved N/N" note.
- **Proceed-Jira-only == today's skip:** downstream state (unresolved PRs, Phase 9 notes) is identical to the current per-slug "Skip and continue without its PRs".
- **No new external calls, no new subagents, no new commands.** The gate never fails the run (only user-chosen Cancel stops it).
- **Phase 9 `### Repos analysed`** report shape is unchanged.

## Verification (structural — no test framework, no husky/prettier hook)

- **Anchors present in Phase 4:** the consolidated summary block, the ✓/✗ mounted/missing rendering, the discrepancy-analysis consequence sentence, and the exact choice list (Mount / Proceed Jira-only / Cancel / Specify path).
- **Happy-path one-liner** present and guarded on `missing` being empty.
- **Ordering:** the gate sits after the slug→clone scan and before Phase 4.5 / Phase 5.
- **Untouched surfaces:** `git diff` shows only `commands/document.md` (+ release files, + `escalation-rules.md` only if extended); Mode B and `/design` byte-unchanged; no subagent/sibling change.
- The escalation-rules reference still resolves (`grep` the cited anchor).

## Release

- MINOR **`v2.11.0`** (new user-visible workflow behavior; additive). Lock-step `plugin.json` + root `marketplace.json` (dev-workflows entry only; siblings byte-identical); `## [2.11.0]` CHANGELOG entry (em-dash date, history preserved). README `/document` guidance updated only if it describes repo resolution.
- Commit trailer exact: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Never `git add -A`.

## Open items (confirm during spec review)

- **Version:** MINOR `v2.11.0` (proposed) vs PATCH (if considered a refinement of existing behavior). Recommendation: MINOR — the gate is a new user-visible interaction.
- **Execution weight:** single-phase, one-file change → a **lightweight direct edit + structural verification** is likely sufficient (as with recent patch releases), rather than a full spec→plan→SDD run. Confirm at the writing-plans handoff.

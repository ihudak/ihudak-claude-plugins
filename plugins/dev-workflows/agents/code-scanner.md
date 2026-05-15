---
name: code-scanner
description: Scans a single code repository for existing capabilities and gaps relative to a set of themes from a Value Increment / Epic. Used for Epic writing where the feature is not yet implemented (no PRs to diff). Pure filesystem search; no HTTPS. Designed for parallel invocation (one instance per repo, capped at 4 concurrent by the caller). Inherits the session's model.
tools: ["Read", "Glob", "Grep", "LS", "Bash"]
---

Scan a single code repo for existing capabilities and gaps relative to a set of themes. One instance per repo; the caller (the `/impl:jira:epics` command) spawns up to 4 concurrent instances per batch.

**Distinction from `diff-summarizer`.** That agent reads *merged PR diffs* for features already implemented; this agent reads *present-day code* for features being scoped. There are no PRs to diff — just filesystem search to understand what exists and what needs to be built.

## Inputs

```yaml
repo_path:   <absolute, e.g. /repos/<repo-name>>
capability_themes:
  - <short phrase, e.g. "Auto-update scheduling" or "Config UI for rate limits">
context: |
  <3–5 sentences: VI goal, what the Epic-set is meant to achieve>
search_hints:
  symbols:  [<class / function names>]
  paths:    [<directory globs, e.g. "**/autoupdate/**">]
  keywords: [<grep keywords>]
refresh:
  switch_to_default_branch: true
  pull: true   # default true — capability scans target present-day code and want the
               # default-branch tip. (Asymmetry with diff-summarizer, which keeps
               # pull: false because it targets historical merged commits.)
```

Refuse to run without `repo_path`, at least one entry in `capability_themes`, and a `context`.

## Process

1. **Verify repo exists.** If `repo_path` is not a directory, return `status: REPO_MISSING`.

2. **Prep step.**
   - `git status --porcelain` — if output is non-empty AND `refresh.pull` is true → return `status: DIRTY_TREE`. The caller's escalation prompts the user to stash-and-retry, skip this repo, or cancel.
   - If `refresh.switch_to_default_branch` is true: resolve the default branch via `git symbolic-ref --short refs/remotes/origin/HEAD`. If that fails (unset `origin/HEAD`), run `git remote set-head origin --auto` and retry; if it still fails, try `main`, then `master`, in that order. If the fallback chain exhausts, return `status: REFRESH_BLOCKED` with reason `cannot resolve default branch`.
   - `git switch <default-branch>` — on failure return `status: REFRESH_BLOCKED` with the one-line git error.
   - If `refresh.pull` is true: `git pull --ff-only`. On any failure (non-fast-forward, network, auth, etc.) return `status: REFRESH_BLOCKED` with the one-line git error.

3. **Scan — pure filesystem.** No git commands beyond step 2. For each theme:
   - Run `grep` / `glob` / file reads against `search_hints.keywords`, `search_hints.symbols`, and `search_hints.paths`.
   - Augment hints with conservative derivations from the theme text itself (tokenise the theme into 2–3 keywords if `search_hints.keywords` is thin).
   - Collect file paths and top-level symbols (class names, function names, exported identifiers) that match.

4. **Read top candidates.** For each theme, open the head (~80 lines) of the top 2–3 matching files. Use that to characterise the capability in a one-line `note`.

5. **Classify each theme.**
   - `present` — clear existing implementation, with at least one authoritative file / symbol / package.
   - `partial` — related code exists but does not cover the theme's full scope (e.g. half the flow is implemented; or the data layer exists but the UI doesn't; or the feature is behind a disabled feature flag).
   - `absent` — no matching code after all searches; the theme is a pure gap.
   - `error` — a search step failed (permission error on a sub-tree, file-read error, timeout). Record the reason and move on; do NOT abort the whole scan.

6. **Write the reusable/gap prose.**
   - `reusable_components` — 1–2 paragraphs naming the existing code the new Epic can build on (by file and symbol). Anchor every mention in the `capability_map` evidence.
   - `gap_summary` — 1–2 paragraphs on what needs to be implemented from scratch. Distinguish "partial — finish the remaining half" from "absent — build the whole thing".

## Output

```yaml
status:    OK | PARTIAL | REPO_MISSING | DIRTY_TREE | REFRESH_BLOCKED | EMPTY
repo:      <short repo name — the basename of repo_path>
repo_path: <absolute path as received in input>
capability_map:
  - theme: <theme text>
    classification: present | partial | absent | error
    evidence:
      - path: <relative to repo>
        symbols: [<names>]
        note: <one-line characterisation>
    gap_summary: |
      <only when classification == partial or absent — what's missing>
    error: <only when classification == error — one-line reason>
reusable_components: |
  <1–2 paragraphs: what existing code the new Epic can build on>
gap_summary: |
  <1–2 paragraphs: what needs to be implemented from scratch>
```

- `status: OK` — every theme was scanned and classified (including classifications of `absent`, which is a legitimate scan result, not a failure).
- `status: PARTIAL` — scan completed but at least one theme has `classification: error`. Failing themes do NOT abort the scan; this mirrors `diff-summarizer`'s `PARTIAL` status for consistent caller recovery.
- `status: EMPTY` — scan ran cleanly but every theme classified as `absent`. This is not an error; it's informative data for the Epic writer.
- `status: REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` — prep step failed; no scan performed.

## Hard rules

- NEVER modify files under `repo_path`. This agent reads and classifies.
- NEVER commit, create branches, cherry-pick, reset, or rebase. Prep step operations are limited to `git status`, `git symbolic-ref`, `git remote set-head`, `git switch`, `git pull --ff-only`.
- NEVER make HTTPS / REST calls to any git host. All scan work is on the local clone.
- NEVER switch away from the detected default branch after the prep step. If the user's workflow requires a different branch, the caller must pre-configure it; this agent does not accept a branch override.
- NEVER invent a theme's classification without evidence. If no files match, classify `absent`.
- NEVER over-claim reuse. `reusable_components` is conservative — it names code the new Epic can genuinely build on, not tangentially-related code.
- If `search_hints` are empty AND the theme text alone tokenises to noise words (e.g. "Improve user experience"), return `classification: error` for that theme with reason `search hints insufficient to scan`. Do not spray-grep the whole repo and invent a classification.
- Cap each theme's scan at 30 seconds of wall time. If a theme's searches exceed that budget, return `classification: error` with reason `theme scan exceeded 30-second budget` and continue to the next theme.

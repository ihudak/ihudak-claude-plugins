---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# dev-workflows docs automation — SP2 Increment 3d: docs & disambiguation (design)

## Context

Increment 3 of sub-project 2 (the `/impl:jira:docs` single-entry enhancement),
the final sub-increment **3d**. Builds on 3a (v1.12.0 — multi-space write
safety), 3b (v1.13.0 — render verification), 3c (v1.14.0 — finish & handoff).
Plugin `main` at `fa79035`.

3d is the **documentation & disambiguation cleanup** — no new command behavior.
It pays down the carried obligations surfaced across Inc1–3c and refreshes the
README to truthfully describe the shipped pipeline.

## Decisions (resolved during brainstorming)

| Decision | Choice |
|---|---|
| Scope | The five carried-obligation items **plus** a refresh of the stale `/impl:jira:docs` README description (item 6). |
| Release | **Patch `v1.14.1`** — docs/wording only, no new capability (so patch, not a minor bump). |
| "All five" count fix | **Verify-then-state**: confirm which `/impl:*` commands actually run the *variable* SIMPLE/MODERATE/SIGNIFICANT/HIGH-RISK classification, and state it precisely — not a blind "five"→"six". This is a **doc-accuracy fix only**; the deeper per-step Sonnet↔Opus delegation design is **deferred** (see Deferred work). |
| obsidian/plain_dir tidy | **Wording only.** Add a clarification that these are defensive guards (Phase 0 normally resolves `docs_repo` / user-confirmed `non_docs_repo`); keep the taxonomy. |
| Items 1 & 2 status | **Already satisfied** in the current README (verified): the AI-Containers section exists at "Environment prerequisites" line 167 (links `https://github.com/ihudak/ai-containers`), and the Vale→`dt-style-checker` fallback note is present at lines 165–166. Both become **verify-only** — touch only to close a small gap (item 1: optionally add a specs-dir mention). |

## Increment 3d design — six documentation edits

### 1. AI-Containers as default (verify-only; already present)

**Already satisfied.** The README "Environment prerequisites" section (line 167)
already documents this: *"Recommended environment:
[ihudak/ai-containers](https://github.com/ihudak/ai-containers)"* — the
`/workspace` umbrella for every repo + the Obsidian vault, the default
`$REPOS_PATH` (`/workspace`), `gh` auto-install, and the host fallback ("Outside
the AI Container … set `$REPOS_PATH` … manage `gh` yourself"). The linked repo
name is present, resolving the ambiguity.

**3d action = verify-only.** The only optional touch: if the section does not
mention that the **specs repo** (e.g. `mgd-specifications`) is discovered under
`/workspace` like the others, add a half-line ("every repository" already
implies it, so this is likely unnecessary). Do NOT create a second
AI-Containers section. Any AI-Containers mention added elsewhere must use the
linked name `[ihudak/ai-containers](https://github.com/ihudak/ai-containers)`.

### 2. Vale-fallback note (verify-only; already present)

**Already satisfied.** The committed obligation (restore the Vale →
`dt-style-checker` fallback note) is met by the current README "Environment
prerequisites" lines 165–166: *"If `vale` is not on PATH, the agent falls back
to the repo's `package.json` `*:lint` script, then to `dt-style-checker` …
Style checks are always mandatory — `NOT_CONFIGURED` is returned only when no
linter of any kind is available."* plus the `dt-style-guide` companion bullet.

**3d action = verify-only.** Confirm this note is intact; no edit needed unless
a gap is found. (The obligation referenced a one-liner dropped in the 1.10.0
refresh; the fuller treatment now lives in Environment prerequisites, which
supersedes it.)

### 3. "Which docs command?" disambiguation

The repo has three docs-adjacent commands that are easy to confuse. Add a short
disambiguation blurb to:
- the **`/impl` dispatcher** help (`commands/impl.md`, which already "prints help
  and stops"); and
- a brief **README** note (near the commands table).

The distinction:
- **`/impl:docs`** — one-shot minor documentation edits; no Jira input, no
  branch/commit.
- **`/impl:jira:docs`** — Jira-driven feature documentation end to end; resolves
  repos/specs, writes into the docs repo, branches/commits, and (opt-in) pushes
  + drafts a PR.
- **`/impl:docs:profile`** — one-time repo profiler that writes/refreshes
  `.dev-workflows/docs-profile.yml`; consumed by `/impl:jira:docs`.

### 4. Fix the "All five `/impl:*`" count (README line 17)

The intro (line 3) already says "Six … slash commands", but line 17 still reads
"All five `/impl:*` workflow commands classify tasks as SIMPLE / MODERATE /
SIGNIFICANT / HIGH-RISK". There are now six `/impl:*` commands (`/impl:code`,
`/impl:docs`, `/impl:docs:profile`, `/impl:jira:docs`, `/impl:jira:epics`,
`/impl:jira:release-notes`), and not all of them run the **variable** 4-level
classification (`/impl:jira:docs` is fixed-SIGNIFICANT; `/impl:docs:profile`
uses the model-routing §2.1 detection chain). **The implementer verifies each
command's actual classification behavior** (grep the command files) and rewrites
the sentence to state it accurately — e.g. naming which commands run the
variable classification rather than asserting a blanket "all".

This is a **documentation-accuracy fix only**. The deeper, related idea — a
per-step Sonnet↔Opus **delegation** model for `/impl:jira:docs` (including the
inline `/impl:docs:profile` sub-flow): when a Sonnet-started run should escalate
a step to Opus, and which steps an Opus-started run can drop to Sonnet — is
**explicitly deferred** (see Deferred work). 3d only corrects the existing
sentence's count/scope.

### 5. Tidy the vestigial `obsidian`/`plain_dir` wording (docs.md) — wording only

Phase 0 step 7 computes the write context against the resolved `docs_repo_path`,
which Phase 0 resolution normally makes a real docs repo (`docs_repo`) or a
user-confirmed `non_docs_repo`. So `obsidian` / `plain_dir` are **defensive
guards**, not expected write targets. Add a one-line clarification to that effect
(at Phase 0 step 7 and/or the Phase 6 write-context table) — **keep the taxonomy**
(it is a real safety net that correctly forbids branch/commit if the resolved
path somehow is a vault or non-git dir). No functional change.

### 6. Refresh the stale `/impl:jira:docs` README row (line 13) + branch/push line (110)

The `/impl:jira:docs` README row describes the pipeline only up to Inc2 (Phase
5.6/5.8/CDN). Refresh it to also mention the shipped 3a/3b/3c capabilities:
- **multi-space write safety** (per-space routing; `{{#if project}}` conditionals
  / override-copies so a `saas`/`managed` run leaves the other space's render
  unchanged);
- **render verification** (build + opt-in best-effort dev-server smoke-check +
  pages-to-visit table);
- **finish & handoff** (squash, opt-in push, host-aware copy-paste PR draft).

Also update line ~110 ("Only `/impl:jira:docs` can create a branch …") to note
it can also, opt-in, push the branch and emit a PR draft (still no PR API).

## Touch list

- `plugins/dev-workflows/README.md` — item 3 (disambiguation note), item 4
  (count sentence, line 17), item 6 (`/impl:jira:docs` row line 13 + branch/push
  line ~110). Items 1 & 2 verify-only (no edit expected).
- `plugins/dev-workflows/commands/impl.md` — item 3 (dispatcher disambiguation).
- `plugins/dev-workflows/commands/impl/jira/docs.md` — item 5 (defensive-guard
  wording at Phase 0 step 7 / Phase 6 write-context table).
- Manifests + CHANGELOG + README header — patch release **v1.14.1**.

~2 plan tasks (README + dispatcher doc edits; docs.md wording + the patch
release), since items 1 & 2 are already satisfied.

## Invariants preserved

- No command behavior changes — docs/wording only. The obsidian/plain_dir
  taxonomy and its NEVER-branch/commit guards are unchanged in effect.
- The zero-external-API description stays accurate (the PR handoff is a
  copy-paste draft; push is git-protocol, opt-in).

## Out of scope (this increment)

- No new reference files, no schema/profile changes, no new phases.
- Nothing in `/impl:code`, `/vuln`, `/upgrade` beyond the count-sentence fix.

## Deferred work (post-3d — user-directed)

3d is the last sub-increment of Increment 3. After it merges, the user wants:

1. **Comprehensive Opus review** of everything built in this session (3a–3d) — a
   whole-pipeline pass over `/impl:jira:docs` end to end (Phase 0 → 9), not just
   per-increment diffs. **This is the gate** before the two efforts below.
2. **Per-step model-delegation classification** for `/impl:jira:docs` (including
   the inline `/impl:docs:profile` sub-flow): define, step by step, when a
   Sonnet-started run should escalate to Opus and which steps an Opus-started
   run can safely drop to Sonnet. Its own brainstorm→spec→plan cycle.
3. **Command-namespace refactor**: every command already carries the implicit
   `dev-workflows:` plugin prefix, so the extra `impl` segment is partly
   redundant — reconsider dropping it for some commands (especially the docs
   ones), and reconsider removing the standalone `/impl:docs` (one-shot minor
   edits) command entirely. Its own cycle; sequenced after the Opus review.

## Resolved during spec review

- AI-Containers stays its own section (it already exists as "Environment
  prerequisites" → "Recommended environment", with the repo link). The
  "which docs command?" disambiguation is a separate small note (README near the
  commands table + the `/impl` dispatcher help) — not merged into one section.
- The AI-Containers repo link is confirmed present and correct
  (`https://github.com/ihudak/ai-containers`).

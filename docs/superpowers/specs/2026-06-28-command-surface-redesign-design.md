---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# dev-workflows — Command-surface redesign (Effort B1) (design)

## Context

The `/impl:*` command family is confusing (`/impl:code`, `/impl:docs`,
`/impl:jira:docs`, `/impl:jira:epics`, `/impl:jira:release-notes`,
`/impl:docs:profile`, plus the `/impl` dispatcher). This effort redesigns the
command surface into memorable **top-level verbs**, folds the one-shot
`/impl:docs` editor into `/document` as a second mode, removes the dead `/impl`
dispatcher, and lands one deferred internal cleanup (the `§15` escalation-rules
extraction). The monotonic phase renumber is split to a tiny **Effort B1b**
(see Deferred) to keep B1's risk on the high-value command rename.

This is **Effort B1**. The Jira-driven `/implement <JiraID>` auto-discovery
feature (find the ticket in `$VAULT_PATH/jira-products`, the spec in the specs
repo, and the code repos — mirroring `jira:docs` Phase 0) is a **behavioral
feature deferred to Effort B2**. In B1, `/implement` is a pure rename of
today's `/impl:code` (same inputs).

Renaming/removing commands is the first **breaking** change to the command
surface → **MAJOR release `v2.0.0`**. Plugin `main` at `9a50ada` (v1.16.0).

## The verb mapping

| Today | B1 target |
|---|---|
| `/impl:code` | `/implement` (rename only; B2 adds JiraID discovery) |
| `/impl:jira:docs` **+** `/impl:docs` | `/document` (unified — two modes) |
| `/impl:jira:epics` | `/epics` |
| `/impl:jira:release-notes` | `/release-notes` |
| `/impl:docs:profile` | `/docs-profile` |
| `/impl` (dispatcher) | **removed** |
| `/upgrade`, `/vuln`, `/guideline-reviewer`, `/api-guideline-reviewer` | unchanged |

## Goals

- Move the command files to top-level verbs (the folder layout *is* the
  namespace) and update each `name:` frontmatter.
- **Unify `/document`**: Phase 0 forks on the argument — a JiraID → the existing
  `jira:docs` pipeline; free-text/`@file` → the existing `/impl:docs` one-shot
  editor. Two delimited sections in one file, sharing the
  style-check / doc-review / report gates.
- **Remove** `/impl` (dispatcher) and the standalone `/impl:docs` file (absorbed).
- **Sweep every `/impl…` reference** (commands, agents, references, README, the
  context hook, `plugin.json`, the model-routing skill) to the new verbs —
  preserving historical CHANGELOG entries.
- **Update the functional files**: `preload-context.sh` (regex + `case` +
  `/document` mode-aware routing) and `plugin.json` (description + keywords).
- Land a new `references/escalation-rules.md` resolving the dangling `§15`
  references. (The monotonic **phase renumber** is split to Effort B1b — see
  Deferred.)

## Non-goals

- **Effort B2** — `/implement <JiraID>` Jira-driven auto-discovery (separate
  design+build).
- Any behavioral change to the *existing* flows beyond the `/document` fork and
  the hook's mode-aware routing — the Jira pipeline is moved **verbatim**.
- Touching `/upgrade`, `/vuln`, the guideline reviewers (already top-level).

## Design

### A. File moves + `name:` frontmatter

- `commands/impl/code.md` → `commands/implement.md` (`name: implement`).
- `commands/impl/jira/docs.md` → `commands/document.md` (`name: document`) — then
  **merge** `commands/impl/docs.md` into it (section B), and delete
  `commands/impl/docs.md`.
- `commands/impl/jira/epics.md` → `commands/epics.md` (`name: epics`).
- `commands/impl/jira/release-notes.md` → `commands/release-notes.md`
  (`name: release-notes`).
- `commands/impl/docs/profile.md` → `commands/docs-profile.md` (`name: docs-profile`).
- `commands/impl.md` → **deleted**.
- Use `git mv` so history follows; then edit `name:` and `description:`.

### B. The `/document` fold (two modes, one file)

`commands/document.md` Phase 0 detects the mode from the first argument token:

- **Jira mode** — the token matches `^[A-Z][A-Z0-9]+-[0-9]+` (a JiraID, e.g.
  `PRODUCT-14902`), optionally followed by `saas` | `managed`. If it is
  JiraID-shaped but no ticket folder is found under `$VAULT_PATH/jira-products`,
  ask the user (re-enter / treat as direct-mode text / cancel). Runs the current
  `jira:docs` pipeline (all phases) **verbatim**.
- **Direct mode** — anything else (`@file` or free-text prose). Runs the current
  `/impl:docs` one-shot flow: load description → clarify → classify
  (SIMPLE/MODERATE) → write inline → style-check → doc-review → report. **No**
  branch / tests / commit / render / maintenance / finish.

Structure: one file with `## Mode A — Jira-driven` and `## Mode B — direct edit`
sections after the Phase 0 fork. The two modes **share** the
`docs-style-checker` / `doc-reviewer` / `doc-fixer` gates and the final report
shape (written once, referenced by both). The Jira pipeline is **not** reworked —
it is the validated v1.16.0 content, moved under the fork. Accepted cost:
`document.md` is large (~1,050 lines).

### C. The reference sweep

`grep -rn '/impl' plugins/dev-workflows` currently spans ~33 files / 300+ hits.
Apply the mapping (section "verb mapping") to every reference in: the command
bodies, all `agents/*.md` `description:` + body mentions, `references/*.md`, the
README, and `skills/model-routing/SKILL.md`. Context-sensitive cases:

- `/impl:docs` → `/document` (most), but rewordings like `docs-style-checker`'s
  "files written by /impl:jira:docs Phase 6 (or /impl:docs Phase 3.5)" become
  "files written by `/document` (Jira mode Phase 6 or direct mode)".
- bare `/impl` (dispatcher) → reword the surrounding text (no dispatcher exists);
  "the /impl workflows" → "the dev-workflows commands".
- **CHANGELOG.md**: historical entries (`[1.x]`) are **preserved verbatim** — they
  accurately document past versions. Only the new `[2.0.0]` entry uses new names.

**Completion gate (robust pattern):** after the sweep,
`grep -rnE '/impl:|/impl\b' plugins/dev-workflows | grep -v '/implement' | grep -v 'CHANGELOG.md'`
returns **empty**. Rationale: `/impl:` can't be a prefix of the new `/implement`
(colon vs. `e`), and `/impl\b` matches bare `/impl` in any punctuation context
(`` `/impl` ``, `/impl.`, `/impl)`, end-of-line) **without** matching `/implement`
(no word boundary between `impl` and `ement`); the two `grep -v`s drop the new
verb and preserved CHANGELOG history. The naive `[:/ ]` pattern misses
backtick/period/paren/EOL bare-`/impl` refs — do not use it.

### D. The context hook (`hooks/preload-context.sh`) — logic change

The hook matches command tokens with a regex and routes context injection via a
`case`. Update both:

- **Regex** (line ~37): match `implement|document|epics|release-notes|vuln|upgrade`
  (drop the `impl(:…)?` alternation). `docs-profile` is intentionally **not**
  matched — it needs no context injection (the same as `/impl:docs:profile` today,
  which the old regex also never matched).
- **`case` routing:**
  - `implement | vuln | upgrade` → **full** context (model-routing + git status +
    repo signals) — same as old `/impl:code`.
  - `document` → **mode-aware**: if the argument is JiraID-shaped → inject
    `$VAULT_PATH` + `$REPOS_PATH` (old `/impl:jira:docs` behavior); else → **silent**
    (old `/impl:docs` behavior — direct mode owns its git hygiene, no Opus).
  - `epics` → `$VAULT_PATH` + `$REPOS_PATH` (old `/impl:jira:epics`).
  - `release-notes` → `$VAULT_PATH` + `$REPOS_PATH` (today it falls under the
    `impl:jira*` case → VAULT+REPOS; the release-notes draft is vault-driven —
    preserve that routing).
  - `docs-profile` → not matched by the regex (no injection; unchanged from today).
- Update the header comment block to describe the new surface.

This is the one piece with **runtime behavior** — verify the regex matches each
new verb and the `document` mode-branch inspects the arg.

### E. `plugin.json` description + keywords

Rewrite the `description` prose: command count **"Nine slash commands"** (was
eleven — `/impl` dispatcher removed, `/impl:docs` folded), list the new verbs
(`/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`, `/vuln`,
`/upgrade`, `/api-guideline-reviewer`, `/guideline-reviewer`), and update the
"`/impl:jira:docs` Phase 0 preflight-discovers …" sentence to "`/document` (Jira
mode) …". Add `doc-writer` + `epic-writer` to the subagent list (now twenty-four)
if not already present. Update `keywords`: `"impl"` → `"implement"` (and add
`"document"`).

### F. Escalation-rules extraction (`§15`)

- **`references/escalation-rules.md`** (new): extract the escalation choice-rules
  the `§15` / "Section 15" references point to (the `choices:` patterns for
  repo-missing, dirty-tree, refresh-blocked, jira-not-found, review-BLOCK, etc.).
  Replace every `§15` / "Section 15" reference (in `document.md`, `epics.md`,
  `jira-reader.md`) with a pointer to this file.

### G. Release v2.0.0

`plugin.json` top-level `version` → `2.0.0`; `marketplace.json`
`plugins[0].version` → `2.0.0`; `CHANGELOG.md` `## [2.0.0]` entry (em-dash date)
with a **BREAKING** section listing the rename mapping (old → new) for
discoverability, the `/impl:docs` fold, the `/impl` removal, and the
renumber/escalation-rules cleanups.

## Touch list

- **Move/merge/delete** (section A): the 6 command files.
- **Mechanical sweep** (section C): all `agents/*.md`, `references/*.md`, README,
  `skills/model-routing/SKILL.md`, command bodies.
- **Logic/content** (sections D, E): `hooks/preload-context.sh`, `plugin.json`.
- **New file** (section F): `references/escalation-rules.md` + repoint the `§15`
  refs in `document.md` / `epics.md` / `jira-reader.md`.
- **Release** (section G): `plugin.json`, `marketplace.json`, `CHANGELOG.md`.

~6–7 plan tasks (structural verification). Suggested grouping: (1) moves +
`/impl` dispatcher removal + frontmatter; (2) `/document` fold; (3) the mechanical
reference sweep (by area) with the grep-gate; (4) the hook logic; (5) plugin.json
rewrite; (6) escalation-rules extraction; (7) release.

## Risks & mitigations

- **Sweep completeness** (a missed `/impl…` ref = dangling pointer). Mitigation:
  the section-C **robust** completion grep-gate (`/impl:|/impl\b`, minus
  `/implement` + CHANGELOG) must return **empty** — sufficient because the pattern
  provably catches every old form and excludes the new verb.
- **Hook runtime behavior** (the only functional logic). Mitigation: a dedicated
  task that (a) `bash -n` parses + shellcheck (if available), and (b)
  **functionally exercises** the hook — pipe sample prompts through it
  (`/document PRODUCT-1 …` → expect VAULT+REPOS; `/document fix a typo` → expect
  silent; `/implement …` → full; `/epics …` → VAULT+REPOS; `/release-notes …` →
  VAULT+REPOS; `/docs-profile …` → silent/unmatched) and assert the injected
  context (or silence) matches the intended routing per verb. Reading the regex
  alone is **not** sufficient — the functional test is required.
- (The **phase-renumber cross-ref** risk is **out of B1** — split to Effort B1b,
  where its per-site sweep is isolated from the command-rename sweep.)
- **Large `document.md`** — accepted (the Jira pipeline is already ~900 lines;
  the fork keeps modes delimited).
- **Breaking change** — communicated via the `[2.0.0]` CHANGELOG mapping; the
  README "Which command?" guidance is rewritten to the new verbs.

## Invariants preserved

- **Zero behavioral change** to the moved flows beyond the `/document` fork and
  the hook's mode-aware routing. The Jira pipeline, all agents, model-routing
  (§9), and the v1.16.0 writer extraction are moved/renamed, not re-logiced.
- Zero external API; opt-in commit/push; multi-space render-unchanged — all
  untouched.
- Historical CHANGELOG entries unchanged.

## Open items (confirm during spec review)

- None — all settled: the mapping, dispatcher removal, two-section `/document`
  fold, MAJOR v2.0.0, the `§15` escalation-rules extraction in B1, and the
  phase-renumber split to **B1b** (below).

## Deferred — Effort B1b (recorded, do not lose)

The monotonic **phase renumber** of the `document.md` Jira-mode cluster to
execution order: CDN `6.2`→**6.1**, branch `6.5`→**6.2**, write `6`→**6.3**,
style `6.7`→**6.4**, render `6.8`→**6.5** (keep `7`/`8`/`8.5`/`9`); `epics.md`
`6.7`→**6.1**. A **per-site** cross-ref sweep — enumerate every `Phase [0-9]`
site across the whole plugin first (incl. the agents — `doc-writer`/`epic-writer`
name Phase 4.5/5.5/6.5/6.7/9), map per-site (bare "Phase 6" is ambiguous — judge
in context), then re-grep to confirm no old number survives. Tiny, isolated, its
own cycle; ships as a patch after B1's v2.0.0.

## Deferred — Effort B2 (recorded, do not lose)

A **shared Jira-driven discovery/resolution front-end** reused by **both**
`/implement` and `/document`, accepting **either** a `<JiraID>` (→ search
`$VAULT_PATH/jira-products`) **or** a **directory** (an imported Jira hierarchy:
an Epic with story subdirs, a Value Increment with epic+story subdirs, or a single
story — the directory case covers non-AI-Containers / undefined-`$VAULT_PATH`).
The same mechanism resolves imported Jira files + the specification + the workdir
(`$VAULT_PATH/Projects/Products/…`) for both commands. Extracting this shared
front-end into a reference also **slims the large `document.md`** (the B1
size concern). Its own brainstorm→design+build cycle.

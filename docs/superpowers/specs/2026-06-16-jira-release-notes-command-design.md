# Design: `/impl:jira:release-notes` command

**Date:** 2026-06-16
**Status:** Approved (design); pending implementation plan
**Plugin:** dev-workflows (additive — 1.5.1 → 1.6.0)

## Summary

Add a standalone `/impl:jira:release-notes` command that generates a customer-facing
release-notes draft for a Value Increment (or any Jira ticket) from a pre-exported
Jira markdown hierarchy, optionally grounded in PR diffs, rendered as the
dynatrace-docs authored release-notes body (`{{#context}}` label + `### title` + prose —
no `{{#internal-note}}` metadata, no Jira IDs), and written to a persistent destination
for the user to paste into Jira's release-notes field (where existing automation adds the
metadata wrapper and emits it into the docs repo).

The Claude marketplace currently has **no** release-notes capability. The Copilot
sibling (dev-workflows 1.5.0) bundles release-notes generation *inside*
`/impl:jira:docs`; this design deliberately makes it a **separate, lighter command**
because release notes are frequently needed independently of product documentation.

## Motivation

- Release notes are often required without writing full product docs (docs may come
  later, or a VI warrants notes but no docs page).
- They generalize beyond VIs to any Jira ticket.
- The pipeline is far lighter than `/impl:jira:docs` (no `doc-location-finder`, no
  `doc-planner`, no doc-page writing, no Opus review gate).
- Claude has nothing here yet — clean design rather than inheriting Copilot's bundling.

## Decisions (from brainstorming)

| Question | Decision |
|---|---|
| Standalone vs bundled | **Standalone command** (`/impl:jira:release-notes`) |
| Input source | **Jira content + optional PR diffs** (diff-grounding flag) |
| Output format & destination | **dynatrace-docs authored body** (`{{#context}}` label + `### title` + prose; no `{{#internal-note}}`, no IDs) → persistent destination (Obsidian project folder default / custom / stdout / skip); pasted into Jira |
| Quality gate | **Light `dt-style-checker`** (+ optional `dt-doc-fixer` safe fixes); skip if `dt-style-guide` absent |
| Dedicated agent | Yes — a bounded `release-notes-writer` agent renders the block |
| Docs-flow correction | Include — stop treating release notes as a repo write target |

## Architecture

A new orchestrator command + one bounded agent; everything else is reused.

| Piece | New? | Role |
|---|---|---|
| `commands/impl/jira/release-notes.md` | new | Orchestrator |
| `agents/release-notes-writer.md` | new | Renders the dt-block draft (one entry per release version) from the jira-reader handoff + optional diff summaries |
| `references/handoff/release-notes-writer.md` | new | Handoff schema for the agent |
| `jira-reader` | reuse | Reads the ticket; full-hierarchy depth when diff-grounding is on (to collect PR URLs) |
| `diff-summarizer` + `$REPOS_PATH` resolution | reuse (optional) | Only when diff-grounding is enabled; uses the `$REPOS_PATH` slug→clone resolution added in 1.5.0 |
| `dt-style-checker` + `dt-doc-fixer` (dt-style-guide plugin) | reuse (optional) | Customer-facing prose gate; skips gracefully if the plugin is not installed |

### Agent: `release-notes-writer`

- **Inputs:** the `jira-reader` handoff (VI/ticket frontmatter + description + linked
  items), an optional array of `diff-summarizer` outputs, and the resolved release
  versions. Inherits the session model (MODERATE).
- **Output:** a `release_notes_block` — `target_format: dynatrace-docs-release-notes-v1`,
  one entry per declared release version, each rendered as the **authored body only**:
  a `{{#context}}<label>{{/context}}` category line, an `### <Feature title>` headline,
  and a 2–4 sentence customer-facing prose paragraph. **No `{{#internal-note}}` block and
  no Jira ticket metadata** — the dynatrace-docs Jira automation generates that wrapper
  (Ticket URL, assignee, status, release versions) from the ticket the draft is pasted
  into, as confirmed by the real `managed/_snippets/release-notes/.../feature-updates.md`
  format in the docs repo. Plus a single combined rendered draft string.
- **Hard rules:** clean customer-facing prose only; **never** embed Jira IDs/keys **or**
  Bitbucket/GitHub PR URLs anywhere in the draft. The draft is placed into the ticket's
  dedicated Jira release-notes field, so the docs automation already knows the ticket ID
  and adds any ID-based references itself — our prose must not. (Our internal Jira is not
  public; IDs never belong in customer-facing notes.) Never write files (the command writes).

## Pipeline (command phases)

1. **Resolve `$VAULT_PATH` + `<JIRA_KEY>`.** Read `VAULT_PATH` (ask if unset). Validate
   `$VAULT_PATH/jira-products/<JIRA_KEY>/` exists; stop with a named error if not.
2. **Load `model-routing`** and classify (MODERATE; no Opus gate). Per the repo
   convention that all `/impl:jira:*` commands load `references/model-routing/classification.md`.
3. **`jira-reader`** reads the ticket. Depth: ticket-only when diff-grounding is off;
   `full` when on (to gather PR URLs from the hierarchy's `## Pull Requests` sections).
4. **Worthiness check.** If `relevant_for_release_notes != "Yes"` **and** `release_versions`
   is empty/absent → warn and offer:
   `choices: ["Proceed anyway (Recommended)", "Cancel", "Other… (describe)"]`.
   Do not hard-block — the command supports any Jira ticket.
5. **Phase-1 questions:**
   - Diff grounding on/off (default off). If on: `$REPOS_PATH` (default `/workspace`,
     confirm/override) + PR-status filter (default MERGED only).
   - Destination: auto-discovered Obsidian project folder (default; e.g.
     `$VAULT_PATH/jira-products/<JIRA_KEY>/<JIRA_KEY>-release-notes.md`) / custom
     absolute path / stdout / skip.
   - Style check on/off (default on if `dt-style-guide` installed).
6. **Optional diff grounding.** If on, resolve repos via `$REPOS_PATH` (git-remote
   slug match) and run `diff-summarizer` in batches of ≤4. Missing repos use the
   existing escalation (skip / clone-wait / specify path).
7. **Render.** `release-notes-writer` produces the `release_notes_block` + combined draft —
   clean customer-facing prose with **no Jira IDs and no PR links** (traceability to the
   source ticket is implicit: the draft is pasted into that ticket's Jira release-notes field).
8. **Optional style gate.** `dt-style-checker` on the draft prose; `dt-doc-fixer`
   applies safe fixes. Skip gracefully if `dt-style-guide` is absent.
9. **Write + report.** Write the draft to the destination (**never** into the
   dynatrace-docs repo). Report the destination path, the versions covered, the
   citations used, any unresolved repos (if diff-grounding was on), and a
   "paste into Jira" reminder.

## Targeted docs-flow correction (related correctness issue)

Claude's docs flow currently treats release notes as a **repo write target**, which is
wrong — dynatrace-docs release-notes pages are auto-generated from Jira, so a manual
write would be overwritten. As part of this change:

- `agents/doc-planner.md` — the "What's new" topic must NOT become a `target_path`;
  add a hard rule forbidding release-notes / what's-new snippet paths as targets.
- `agents/doc-location-finder.md` — remove "What's New/Release Notes entry" from the
  set of proposable write targets; add the same exclusion rule.
- `commands/impl/jira/docs.md` — when the VI is release-notes-worthy, point the user to
  `/impl:jira:release-notes` instead of writing a release-notes page; remove the
  "release-notes file" example from the consequential-updates phase.

Scoped strictly to release-notes handling — no other docs-flow changes.

## Error handling

| Condition | Behaviour |
|---|---|
| `jira-products/<KEY>` missing | Stop with a named error |
| Worthiness fields absent | Warn + offer proceed/cancel |
| Diff-grounding on, repo unresolved | Existing missing-repo escalation (skip / clone-wait / specify path) |
| `dt-style-guide` not installed | Skip the style gate gracefully; note it in the report |
| Destination file already exists | Ask: overwrite / rename / stdout / skip |
| Ticket has no release versions but user proceeds | Emit a single undated entry; note "no release version declared" in the report |

## Bookkeeping

- `README.md` — add `/impl:jira:release-notes` to the command list + workflow map.
- `CLAUDE.md` — add to the taxonomy, the `dev-workflows` workflow-relationships map,
  and a short `/impl:jira:release-notes` invariants block (zero external API calls;
  jira-reader read-only; never write into the docs repo; persistent destination).
- `CHANGELOG.md` — new `1.6.0` entry (additive feature + docs-flow correction).
- Version bump dev-workflows `1.5.1 → 1.6.0` in `plugin.json` and `marketplace.json`
  (surgical edit — do not reformat marketplace.json).
- `hooks/preload-context.sh` — the `impl:jira*` glob already routes this command; verify
  it emits `$VAULT_PATH` + `$REPOS_PATH` context for it.

## Dependencies & sequencing

This change edits `agents/doc-planner.md`, which is also edited by the unmerged
`fix/persistent-screenshot-staging` branch (dev-workflows 1.5.1). To avoid a merge
conflict, **merge the staging fix first**, then base this feature on the result.

## Out of scope

- Porting Copilot's bundled release-notes-inside-`/impl:jira:docs` behaviour (this
  command replaces the need for it).
- Per-Epic release notes (the draft is per-VI; child Epics are rolled into the VI's
  entry unless the user runs the command on an Epic directly).
- Plain-markdown / configurable output formats (dt-block only for now; revisit if needed).
- Writing release notes directly into the dynatrace-docs repo (owned by Jira automation).

## Success criteria

- `/impl:jira:release-notes <KEY>` produces a dynatrace-docs-format draft from the vault
  export, written to a persistent destination, with zero external API calls.
- Diff grounding is optional and reuses `$REPOS_PATH` resolution + `diff-summarizer`.
- The style gate runs when `dt-style-guide` is present and skips cleanly when absent.
- No Jira IDs/keys and no PR URLs appear anywhere in the release-notes draft; the draft
  is placed into the ticket's dedicated Jira release-notes field, where the docs
  automation associates the source ID.
- The docs flow no longer proposes release-notes/what's-new pages as repo write targets.
- `grep` confirms the command, agent, and handoff exist; manifests are valid JSON with
  consistent `1.6.0` versions.

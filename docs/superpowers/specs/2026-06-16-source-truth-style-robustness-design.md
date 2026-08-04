# Design: Discrepancy escalation + style-check robustness (Copilot v1.7.0–v1.8.1 port)

**Date:** 2026-06-16
**Status:** Shipped in dev-workflows v1.7.0 — pre-implementation design snapshot, kept as authored.
**Plugin:** dev-workflows (feature + fix — 1.6.0 → 1.7.0)

> **Supersedes the earlier "code wins, always" draft of this spec.** Source
> verification now makes the plugin an **analyst, not an arbiter**: it detects
> Jira-vs-source discrepancies, surfaces them as a table, and asks the user how
> to document each one. The user — with PM/sprint/scope context — decides; the
> plugin never silently rewrites docs to match either side.

## Summary

Port the Copilot sibling's docs-accuracy and style-robustness fixes (its
dev-workflows v1.7.0 → v1.7.1 → v1.8.0 end-state) into the Claude marketplace:

- **Part A — style-check robustness.** A missing Vale binary currently makes
  `docs-style-checker` return `ERROR`, after which the orchestrator may silently
  skip style checking. Fix: always fall back to the LLM-based `dt-style-checker`
  before returning `ERROR`, and make the style-check phase mandatory in both docs
  workflows.
- **Part B — source verification as discrepancy escalation.** Verify user-visible
  doc claims (option lists, labels, counts, defaults, menu paths) against the
  shipped source. When source and Jira disagree, **do not auto-resolve** — present
  a discrepancy table and let the user decide, per claim, whether to document what
  the Jira ticket promised (and file a bug), document what actually shipped, or
  skip and report.

## Motivation

The driver is real. For PRODUCT-14902, the Jira "UI changes" section promised
several renames that **were never implemented** (verified against `cluster`):

| Jira claim | Source check | Verdict |
|---|---|---|
| Settings → Updates renamed to Settings → Deployment | `ClusterSettingsMenu.java:1404 .withTitle("Updates")` | ❌ not shipped |
| "Manage OneAgent and ActiveGate" menu description | no hits | ❌ not shipped |
| "Update windows for OneAgent updates" page renamed | `ClusterSettingsMenu.java:1413 .withTitle("Update windows for OneAgent updates")` | ❌ not shipped |
| AG schema under existing Updates section | `ClusterSettingsMenu.java:1417 forSchema(PrivateActiveGateUpdates.IDENTIFIER)` | ✅ shipped (FF-gated) |
| "Add update window" button label | `PrivateActiveGateUpdates.schema.json:111` | ✅ shipped (AG schema only) |

Two wrong responses exist: (a) document the Jira prose faithfully → ship docs for
UI that does not exist; (b) "code wins" → silently drop requirements the team was
supposed to deliver, hiding an implementation gap from the PM. The correct response
is to **surface the gap and let the PM decide** — they may reject the feature and
file bugs, while the docs are drafted and held in git until the implementation lands.

## Scope (from brainstorming)

| Decision | Choice |
|---|---|
| Style-check robustness (Part A) | Port fully |
| Source-verification model | **Analyst, not arbiter** — detect, tabulate, escalate; user decides per discrepancy |
| Per-discrepancy options | document-as-source / document-as-jira (+ bug-report draft + marker) / skip-and-report |
| Blast radius | **Docs flow + release-notes command.** Epics (code-scanner / epic-reviewer) out of scope |
| "document-as-jira" hold mechanism | Write docs + marker + bug-report draft; **strongly recommend a branch** and flag "do not merge until gaps resolved" in the report. **No auto-PR** (respects the `/impl:jira` zero-external-API invariant) |
| doc-reviewer severity | Unmarked customer-visible claim contradicted/absent-when-verifiable → **BLOCKER**; claim carrying an `intentional-discrepancy` marker → known gap, **not BLOCKER**; unverifiable (no/partial repos) → **MAJOR** "not verifiable" |
| Version | 1.6.0 → 1.7.0 |

## Part A — Style-check robustness

### `agents/docs-style-checker.md`
- New hard rule: if a detected primary linter (Vale / project lint / markdownlint /
  remark) errors at runtime (missing binary, non-zero exit, timeout), the agent MUST
  attempt the `dt-style-guide:dt-style-checker` fallback before returning `ERROR`,
  mapping its return into this agent's schema (violations → `VIOLATIONS_FOUND`,
  `linter: dt-style-checker`; zero → `OK`; fallback errors → `ERROR`). When the
  fallback ran because the primary failed, prefix `error:` with a note.
- `NOT_CONFIGURED` only when no primary linter is configured AND `dt-style-guide`
  is not installed. "Some check is better than no check."

### `commands/impl/jira/docs.md` (Phase 6.7) and `commands/impl/docs.md`
- Phase 6.7 becomes mandatory; remove the "proceed without style check" escape.
- `/impl:docs` gains a mandatory style phase before `doc-reviewer` (none today),
  same one-fix-one-recheck cycle; on `NOT_CONFIGURED`, proceed.

### `agents/risk-planner.md`
- Hard rule: never recommend "skip the style check" as a disposition.

## Part B — Source verification as discrepancy escalation

### `references/source-truth.md` (new)
Claude's `references/` equivalent of Copilot's `skills/_shared/source-truth.md`.
Contents:
- **Principle: the plugin is the analyst, the user is the decision-maker.** Verify
  user-visible claims against source; when source and description disagree, surface
  it — never silently pick a side.
- The claim-type table (enums, labels, menu paths, defaults, counts, API shapes,
  concurrency/scope rules) and verification techniques (schema JSON → data-source
  classes → constants → OpenAPI → UI source → tests fallback).
- **§Escalation protocol:** the analysis-table format; the batch prompt and the
  per-discrepancy prompt; the `discrepancy_decisions[]` record; the bug-report draft
  destination + format; the `intentional-discrepancy` marker format; and the
  no-source-evidence case (when repos are missing, `Source phrasing: "(not
  verifiable)"` and "document as Jira claims" is the natural default).
- Scoped to the workflows wired here (docs + release-notes). Agents reference it via
  `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md`.

### `agents/doc-planner.md`
- New input `code_repos: [{slug, path}]` (the clones already resolved for
  `diff-summarizer`).
- New verification step: extract every user-visible claim; verify against
  `code_repos`; record results in **`verification_warnings` (v2)** — `number`,
  `claim`, `jira_phrasing` (verbatim), `source_phrasing` (verbatim, or
  `"(not verifiable)"`), `source_location`, `technique`, `finding`
  (`VERIFIED` / `CONTRADICTED` / `NOT_FOUND` / `AMBIGUOUS`).
- **Does NOT rewrite topic notes to match source** — the decision belongs to the
  orchestrator + user (Phase 5.8). Topic notes preserve the Jira phrasing until a
  decision is made.
- When `code_repos` is omitted/empty, emit one `NOT_FOUND` /
  `technique: no-source-evidence` warning per user-visible claim.
- **Port the v1.7.1 fix:** do not emit a frontmatter update whose only change is the
  `changelog` field on an otherwise-unchanged page (drop changelog-only updates).
- **Changelog entries carry no Jira key (Copilot v1.8.1, "Q2").** Change the
  `changelog` template from `"<YYYY-MM-DD> <1-line summary, ref <JIRA_KEY>>"` to a
  customer-readable `"<YYYY-MM-DD> <1-line summary>"`, and update step-3 wording from
  "naming the Jira key" accordingly. The changelog field is reader-visible prose
  ("what changed on this page"); traceability is carried by the commit message and the
  file diff, not the page. (Verifiable: across dynatrace-docs's 5500+ existing entries,
  fewer than 5 cite an issue key.)
- **Cross-product minimal-touch (Copilot v1.8.1, "Q4").** Strengthen the parity-reference
  rule: a reciprocal "minimal touch" on product X's page, for a feature shipped by
  product Y, MUST be a one-line pointer + cross-link to Y's dedicated page — NEVER a copy
  of Y's implementation detail (throttling rules, enum values, precedence, etc.). Plan
  such `topics[].notes` as: "Add a one-line cross-link to `<other-product-page#anchor>`;
  do NOT inline implementation detail that belongs on `<other-product-page>`." Example:
  noting on `oneagent-update` that update windows are shared with ActiveGate is fine;
  copying the per-pool ActiveGate throttling rule onto the OneAgent page is not.

### `commands/impl/jira/docs.md` — new Phase 5.8 (Discrepancy analysis & decision)
Runs after `doc-planner` (5.7) when there are `CONTRADICTED` / `NOT_FOUND` /
`AMBIGUOUS` warnings:
1. Present the analysis table (`# | Claim | Jira phrasing | Source phrasing | Source
   location | Verdict`).
2. Ask batch: "Decide per discrepancy (Recommended) / all-as-source / all-as-jira /
   all-skip-and-report / Cancel".
3. If per-discrepancy: for each, ask document-as-source / document-as-jira /
   skip-and-report / Cancel.
4. Build `discrepancy_decisions[]`; set `bug_report_destination` (the vault project
   folder, resolved like the release-notes destination) when any decision is
   `document-as-jira` or `skip-and-report`.
- Thread `code_repos` into `doc-planner` (5.7) and `doc-reviewer` (7).

### `commands/impl/jira/docs.md` — Phase 6 writer behaviour
- `document-as-source` → use source phrasing verbatim.
- `document-as-jira` → use Jira phrasing AND insert the `intentional-discrepancy`
  marker before the affected prose; **strongly recommend committing to a branch**;
  the Phase-9 report flags "do not merge this docs PR until the gaps are resolved —
  see `<JIRA_KEY>-implementation-gaps.md`". No PR is opened by the plugin.
- `skip-and-report` → omit the claim from the docs.
- When any decision is `document-as-jira`/`skip-and-report`, emit
  `<vault-project-folder>/<JIRA_KEY>-implementation-gaps.md` (bug-report draft;
  same vault destination policy as the release-notes draft — never `/tmp`, never the
  docs repo).

### `agents/doc-reviewer.md`
- New input `code_repos`; new **Source-code accuracy** dimension: spot-check 3–5
  user-visible claims per file. Severity: an unmarked claim contradicted by source
  (or absent when repos are available) is a **BLOCKER**; a claim immediately preceded
  by a valid `<!-- intentional-discrepancy ... -->` marker is a recorded gap, **not
  BLOCKER**; a claim that cannot be verified (no/partial repos) is **MAJOR** with a
  "not verifiable" note.

### Release-notes flow — analogous handling
- `agents/release-notes-writer.md`: new optional `code_repos` input. When present,
  verify the claims the draft makes; if a discrepancy is found, record it in
  `gaps[]` with both `jira_phrasing` and `source_phrasing` (do not auto-resolve).
- `commands/impl/jira/release-notes.md`: when the writer returns discrepancy gaps,
  present the same table and per-discrepancy prompt (the command asks, since there is
  no reviewer). Apply the decision to the prose; for `document-as-jira`/`skip`, emit
  or append to `<vault-project-folder>/<JIRA_KEY>-implementation-gaps.md`. When
  diff-grounding is off (no `code_repos`), behaviour is unchanged.

### `agents/risk-planner.md`
- Hard rules: never recommend "skip the style check"; never recommend silently
  trusting the description over source OR silently trusting source over the
  description — discrepancies MUST be escalated to the user.

## Discrepancy decision options (summary)

| Decision | Docs output | Bug-report draft | Notes |
|---|---|---|---|
| `document-as-source` | source phrasing verbatim | no | matches what shipped |
| `document-as-jira` | Jira phrasing + `intentional-discrepancy` marker | yes | recommend branch; "hold PR until gaps resolved" |
| `skip-and-report` | claim omitted | yes | gap recorded only |

## Files touched

| File | Part | Change |
|---|---|---|
| `agents/docs-style-checker.md` | A | ERROR/NOT_CONFIGURED → dt-style-checker fallback |
| `commands/impl/docs.md` | A | add mandatory style phase |
| `references/source-truth.md` (new) | B | analyst-not-arbiter policy + escalation protocol |
| `agents/doc-planner.md` | B | `code_repos`; `verification_warnings` v2 (jira+source phrasing, no auto-correct); v1.7.1 changelog-only-frontmatter fix; v1.8.1 no-Jira-key-in-changelog (Q2) + cross-product minimal-touch (Q4) |
| `commands/impl/jira/docs.md` | A+B | Phase 6.7 mandatory; new Phase 5.8; thread `code_repos`; writer applies decisions + marker + bug-report draft + branch/flag |
| `agents/doc-reviewer.md` | B | Source-code accuracy dimension + `code_repos`; marker-aware severity |
| `agents/release-notes-writer.md` | B | `code_repos`; record discrepancies in `gaps[]` (jira+source phrasing) |
| `commands/impl/jira/release-notes.md` | B | discrepancy table + per-claim prompt; bug-report draft |
| `agents/risk-planner.md` | A+B | hard rules (no skip-style; escalate discrepancies, never silently pick a side) |
| `CLAUDE.md` | A+B | source-truth as a single-source policy ref; mandatory-style-check invariant; Phase 5.8 + bug-report-draft invariants |
| `README.md`, `CHANGELOG.md`, `plugin.json`, `marketplace.json` | — | 1.7.0 bookkeeping (marketplace.json edited surgically) |

## Error handling

| Condition | Behaviour |
|---|---|
| Primary linter errors | fall back to `dt-style-checker`; ERROR only if both fail |
| No linter + no `dt-style-guide` | `NOT_CONFIGURED`; doc-reviewer remains the gate |
| Jira vs source discrepancy (docs) | doc-planner records both phrasings; Phase 5.8 escalates to the user |
| No/partial `code_repos` | `Source phrasing: "(not verifiable)"`; still escalated; document-as-jira is the natural default |
| Unmarked contradiction in written docs | doc-reviewer BLOCKER |
| Marked (`intentional-discrepancy`) claim | doc-reviewer records as known gap (not BLOCKER) |
| Any `document-as-jira` / `skip-and-report` decision | emit `<KEY>-implementation-gaps.md`; report flags "hold PR" when branched |
| release-notes discrepancy | recorded in `gaps[]`; command asks; no hard gate |

## Out of scope

- Epics (`code-scanner` / `epic-reviewer` source reinforcement).
- Auto-opening a PR (`gh`/Bitbucket) — would break the `/impl:jira` zero-external-API
  invariant; the user pushes and opens the PR.
- Copilot's `branch-naming.md` shared policy (a convention, not a bug).
- Re-encoding any corporate style guide.

## Success criteria

- `docs-style-checker` never silently skips: with no Vale binary it falls back to
  `dt-style-checker`; `NOT_CONFIGURED` only when nothing is available. Style check is
  mandatory in both docs commands.
- `doc-planner` records both `jira_phrasing` and `source_phrasing` and never
  auto-corrects topic notes; changelog-only frontmatter updates are dropped; changelog
  entries carry no Jira key; cross-product parity touches are one-line pointers only.
- `/impl:jira:docs` Phase 5.8 presents a discrepancy table and records
  `discrepancy_decisions[]`; the writer applies them (source / jira+marker / skip)
  and emits `<KEY>-implementation-gaps.md` when warranted.
- `doc-reviewer` BLOCKs an unmarked contradiction, accepts a marked one, and MAJORs
  an unverifiable claim.
- The release-notes flow surfaces discrepancies and asks per claim.
- `risk-planner` forbids skipping style checks and forbids silently resolving
  discrepancies either way.
- Manifests valid JSON with consistent `1.7.0`; `marketplace.json` not reformatted.

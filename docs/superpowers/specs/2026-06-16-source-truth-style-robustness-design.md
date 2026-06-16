# Design: Source-truth verification + style-check robustness (Copilot v1.7.0 port)

**Date:** 2026-06-16
**Status:** Approved (design); pending implementation plan
**Plugin:** dev-workflows (feature + fix — 1.6.0 → 1.7.0)

## Summary

Port the two bug fixes from the Copilot sibling's dev-workflows v1.7.0 into the Claude
marketplace:

- **Part A — style-check robustness.** A missing Vale binary currently makes
  `docs-style-checker` return `ERROR`, after which the orchestrator may silently skip
  style checking — shipping customer-visible style issues uncaught. Fix: always fall back
  to the LLM-based `dt-style-checker` before returning `ERROR`, and make the style-check
  phase mandatory in the docs workflows.
- **Part B — source-truth verification ("Implementation > Description").** When a Jira
  description and the shipped code disagree, the code wins. Verify user-visible doc claims
  (option lists, labels, counts, defaults, menu paths) against the actual source before
  publishing. This is a real accuracy bug: PRODUCT-14902's "User Story" listed 3
  target-version options while the source ships 4 (Latest / Previous / **Older** /
  specific) — and the Claude release-notes smoke test reproduced the same omission.

## Motivation

The Claude marketplace's docs flow has neither fix. The style-check gap means style
checks can be silently skipped in ephemeral/sandboxed containers without Vale. The
source-truth gap means generated docs can faithfully reproduce inaccurate Jira prose.

## Scope (from brainstorming)

| Decision | Choice |
|---|---|
| Style-check robustness | Port fully (docs-style-checker fallback + mandatory phase in both docs commands + risk-planner guardrail) |
| Source-truth blast radius | **Docs flow + the release-notes command.** Epics (code-scanner / epic-reviewer) are out of scope. |
| Severity — contradicted by source, or customer-visible claim absent from source when repos are available | **BLOCKER** in doc-reviewer |
| Severity — cannot verify (no/partial code repos, Jira-only run) | **MAJOR/CONCERN** with a "not verifiable" note; never BLOCKER |
| release-notes mismatches | `gaps[]` entries (`recommended_action: "ask user"`); no hard gate (no reviewer in that flow) |
| Version | 1.6.0 → 1.7.0 |

## Part A — Style-check robustness

### `agents/docs-style-checker.md`
- New hard rule at the top: if a detected primary linter (Vale / project lint script /
  markdownlint / remark) errors at runtime (missing binary, non-zero exit, timeout),
  the agent MUST attempt the `dt-style-checker` fallback before returning `ERROR`.
- The fallback invokes `dt-style-guide:dt-style-checker` and maps its return into this
  agent's schema: violations → `VIOLATIONS_FOUND` (`linter: dt-style-checker`); zero →
  `OK`; the fallback itself errors → `ERROR` (only now). When the fallback ran because the
  primary failed, prefix `error:` with a note explaining the fallback was used.
- `NOT_CONFIGURED` is returned ONLY when no primary linter is configured AND the
  `dt-style-guide` plugin is not installed. "Some check is better than no check."

### `commands/impl/jira/docs.md` (Phase 6.7)
- Make Phase 6.7 **mandatory**: the orchestrator MUST dispatch `docs-style-checker` and
  act on its return — never skip on its own judgement of which linters are installed.
- Remove the "proceed to review without style check" escape choice from the ERROR
  escalation (replace with "proceed to doc-reviewer", which still runs).

### `commands/impl/docs.md`
- Add a mandatory style-check phase before the `doc-reviewer` phase (the command has none
  today), using `docs-style-checker` with the same one-fix-one-recheck cycle as
  `/impl:jira:docs` Phase 6.7. When `docs-style-checker` returns `NOT_CONFIGURED`, proceed
  (doc-reviewer remains the correctness gate).

### `agents/risk-planner.md`
- Hard rule: never recommend "skip the style check" as a valid disposition.

## Part B — Source-truth verification

### `references/source-truth.md` (new)
Claude's `references/` equivalent of Copilot's `skills/_shared/source-truth.md`. Contains:
the **Implementation > Description** principle; the table of claim types to verify (enums,
labels, menu paths, defaults, counts, API shapes, concurrency/scope rules); the
verification techniques (§schema JSON → data-source classes → constants → OpenAPI → UI
source → tests fallback); per-agent responsibilities; and the hard rules (code wins;
never copy a description's option list/count/label without checking source; unverifiable
→ surface, never silently emit). Scoped to the workflows we wire here (docs +
release-notes). Agents reference it via `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md`.

### `agents/doc-planner.md`
- New input `code_repos: [{slug, path}]` (the local clones already resolved for
  `diff-summarizer`).
- New mandatory verification step: extract every user-visible claim from the proposed
  checklist; verify each against `code_repos` using the `source-truth.md` techniques;
  adjust topic notes to the verified phrasing; emit `verification_warnings[]` for any
  claim that is contradicted or cannot be verified (with claim, technique, source
  location checked, discrepancy).
- When `code_repos` is omitted/empty, emit one `verification_warnings[]` entry per
  user-visible claim with a `"not verifiable — no code repos provided"` note.

### `agents/doc-reviewer.md`
- New input `code_repos: [{slug, path}]`.
- New review dimension **Source-code accuracy**: spot-check 3–5 user-visible claims per
  file against source. Severity rule: a documented option/label/value/count that is
  **contradicted by source, or absent from source when repos are available**, is a
  **BLOCKER**. A claim that **cannot be verified because repos are missing/partial** is a
  **MAJOR** with a "not verifiable" note — never a BLOCKER (else Jira-only runs always
  block).

### `agents/release-notes-writer.md`
- New optional input `code_repos: [{slug, path}]` (provided by the command when
  diff-grounding is on).
- When `code_repos` is present, verify the specific option/label/count claims the draft
  makes against source; on mismatch, correct the prose to the source phrasing and record
  a `gaps[]` entry (`field: prose`, `recommended_action: "ask user"`). No hard gate —
  the release-notes flow has no reviewer; the PM reviews before pasting into Jira.
- When `code_repos` is absent (Jira-only), behaviour is unchanged.

### `commands/impl/jira/docs.md` (threading)
- Build `code_repos` from the Phase-4 resolved `repo_slug → repo_path` map (no new
  prompt). Pass it to `doc-planner` (Phase 5.7) and `doc-reviewer` (Phase 7).

### `commands/impl/jira/release-notes.md` (threading)
- When diff-grounding is on, pass the resolved `code_repos` to `release-notes-writer`
  (Phase 6). When off, pass none.

### `agents/risk-planner.md`
- Hard rule: never recommend trusting the Jira description over the source code.

## Files touched

| File | Part | Change |
|---|---|---|
| `agents/docs-style-checker.md` | A | ERROR/NOT_CONFIGURED → dt-style-checker fallback |
| `commands/impl/jira/docs.md` | A+B | Phase 6.7 mandatory; thread `code_repos` to planner + reviewer |
| `commands/impl/docs.md` | A | add mandatory style phase |
| `agents/risk-planner.md` | A+B | two hard rules (no skip-style, no trust-description-over-source) |
| `references/source-truth.md` (new) | B | shared policy |
| `agents/doc-planner.md` | B | verification step + `code_repos` + `verification_warnings[]` |
| `agents/doc-reviewer.md` | B | Source-code accuracy dimension + `code_repos` |
| `agents/release-notes-writer.md` | B | verify claims when `code_repos` present; flag in `gaps[]` |
| `commands/impl/jira/release-notes.md` | B | thread `code_repos` when diff-grounding on |
| `references/handoff/diff-summarizer.md` | B | (optional) note enum/schema/label changes are high-signal for downstream verification |
| `CLAUDE.md` | A+B | add source-truth as a single-source policy ref; mandatory-style-check invariant |
| `README.md`, `CHANGELOG.md`, `plugin.json`, `marketplace.json` | — | 1.7.0 bookkeeping (marketplace.json edited surgically) |

## Error handling

| Condition | Behaviour |
|---|---|
| Primary linter errors (missing Vale, etc.) | `docs-style-checker` falls back to `dt-style-checker`; ERROR only if both fail |
| No linter + no `dt-style-guide` | `NOT_CONFIGURED`; doc-reviewer remains the gate |
| doc claim contradicted by source / absent when repos available | doc-reviewer BLOCKER |
| doc claim unverifiable (no/partial repos) | doc-reviewer MAJOR + "not verifiable" note |
| release-notes claim mismatch | corrected to source; `gaps[]` entry, no hard stop |
| `code_repos` omitted to planner/reviewer | `verification_warnings` / "not verifiable" — never silent pass |

## Out of scope

- Epics: `code-scanner` / `epic-reviewer` source reinforcement (Copilot's use-case B).
- Re-encoding any corporate style guide — we still wrap the repo's Vale config; the
  fallback is the existing `dt-style-checker`.
- Copilot's `branch-naming.md` shared policy (a convention, not a bug).

## Success criteria

- `docs-style-checker` never silently skips: with no Vale binary it falls back to
  `dt-style-checker`; `NOT_CONFIGURED` only when nothing is available.
- `/impl:jira:docs` and `/impl:docs` always run a style check (or explicitly record
  NOT_CONFIGURED); no "skip style" escape hatch remains.
- `doc-planner` and `doc-reviewer` accept `code_repos` and verify user-visible claims;
  a contradicted/absent-when-verifiable claim is a BLOCKER, an unverifiable one is MAJOR.
- `release-notes-writer` corrects and flags claims against source when `code_repos` is
  provided.
- `references/source-truth.md` exists and is referenced by the wired agents via
  `${CLAUDE_PLUGIN_ROOT}`.
- `risk-planner` forbids both "skip style check" and "trust description over source".
- Manifests are valid JSON with consistent `1.7.0`; `marketplace.json` not reformatted.

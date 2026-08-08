# `/document` gate enforcement — design

**Date:** 2026-08-08
**Status:** Approved design, not yet implemented.
**Scope:** `dev-workflows` plugin, all three editions (canonical Claude, mgd Claude, Copilot)
**Source:** PM feedback item 3 from the 2026-08-07 `/superpowers:brainstorming` session, plus the
run record in `$SPECS_PATH/dev-workflows-feedback/PRODUCT-17012-feedback.md`. Sub-project **B1** of
five; **B2** and the remaining sub-projects are listed under [Out of scope](#out-of-scope).

---

## Problem

On PRODUCT-17012 the `/document` run skipped the style check, ignored the docs repo's changelog and
CONTRIBUTING rules, never booted a docs server, and shipped a wrong `helm` command that a human
reviewer caught later. Every one of those steps is written into the workflow, and `git log -S`
places both gate wordings in `commands/document.md` since **v2.0.0** — long before the run. The
obvious conclusion is that the prose needs to be more emphatic. That conclusion is wrong, and acting
on it is the one fix already known not to work.

Reading the failures against the actual repos shows that **only one of the five is an enforcement
failure.** The other four are structural: the gate ran against the wrong target, the guideline had no
consumer, the rule was filtered out by design, or the claim class did not exist. No amount of
emphasis reaches any of them.

| # | Failure | Root cause | Class |
|---|---|---|---|
| 1 | Style check "skipped" | `.vale.ini` exists so `docs-style-checker` step 1 claims the run, but `vale` is not on PATH. On failure the agent jumps to step 5 and never tries steps 2–4, so `pnpm dynatrace:lint` / `managed:lint` — what CI actually runs — are never attempted. | wiring |
| 2 | CHANGELOG rules ignored | `references/dynatrace-docs/changelog-guidelines.md` has **zero consumers in the write path**. `doc-planner`, `doc-writer`, and `doc-reviewer` each carry two inlined rules ("customer-readable 1-line summary", "no Jira key"). The real guideline lives only in the `dynatrace-docs-frontmatter` skill, which no agent invokes and `doc-writer` cannot invoke — its tool list has no Skill. | wiring |
| 3 | CONTRIBUTING rules ignored | `doc-planner` has read `CONTRIBUTING.md` since 2.12.0, but is instructed to *"**Ignore** purely operational content (build/setup steps, PR and branch mechanics)."* The repo's `## PR checklist → Advanced check (InfoDevs)` — the exact list of gates that failed — is operational content, discarded by design. | wiring |
| 4 | Wrong `helm` command | `source-truth.md` §2's claim-class table covers enums, UI labels, menu paths, defaults, flags, API paths, and counts. There is **no row for commands, CLI invocations, or code blocks**. Nothing was ever meant to verify it. | coverage gap |
| 5 | Docs server never booted | Phase 6.5 Step 2's literal choice list is `["Run smoke-check (Recommended)", "Skip — use the manual table only", "Cancel"]`. The orchestrator re-ranked it, presenting Skip as recommended and citing dev-server flakiness plus the static `{{#if project='managed'}}` guarantee. | **enforcement** |

Compounding #5: `references/dynatrace-docs/render-verification.md` asserts *"the dynatrace-docs case:
only `commands.lint` + the `*:start` dev servers"*, and the built-in profile defines no `commands.build`
— so Phase 6.5's **gating** Step 1 build check is disabled by a false claim in the plugin's own
reference. `package.json` in `dynatrace-docs` defines `dynatrace:build`, `managed:build`, and
`managed:lint`. With Step 1 disabled by the false claim and Step 2 skipped by the re-ranking, the run
had zero build proof of any kind.

The design therefore has two halves: one mechanism that removes the orchestrator's discretion to skip
(§1), and four wiring repairs that make the gates capable of the job they were already assigned
(§2–§5), plus the render-gate repair (§6).

---

## 1. The gate ledger

### 1.1 The property we need

A rule that can be rationalized around will be rationalized around. Phase 6.4 has said **"Mandatory:
the orchestrator MUST dispatch `docs-style-checker` — never skip on its own judgement"** since v2.0.0
and still lost. The fix is not a stronger adjective — it is removing the cell in which a run can
write *"I decided this wasn't necessary."*

Every gate terminates in exactly one of six outcomes. Only one of them is assignable by the
orchestrator's own judgement, and it is not terminal.

| Outcome | Means | Assignable by |
|---|---|---|
| `RAN` | The gate's primary mechanism executed. | evidence only |
| `DEGRADED` | Only a fallback executed. Records what did not run, why, and what CI will still check. | evidence only |
| `FAILED` | Ran and found blocking problems. Feeds the existing `doc-fixer` loops. | evidence only |
| `UNAVAILABLE` | Nothing ran and no fallback exists. **Not a resting state** — see §1.7. | the orchestrator, but never as a final answer |
| `SKIPPED_BY_USER` | The user chose to skip. Carries their decision quoted verbatim. | the user only |
| `NOT_APPLICABLE` | A named precondition is unmet (e.g. write context is `obsidian`, so nothing was written into a buildable repo). | evidence only |

There is no orchestrator-assignable "skipped". Every non-run path terminates in a **named missing
precondition**, a **named missing tool**, or a **verbatim user decision**. "Flaky, and the static
analysis was sufficient" has nowhere to go.

Per the approved strictness call, `DEGRADED` proceeds — a weaker check is not a documentation defect,
and Phase 9 names what CI will check that the run did not. Total absence of coverage does not proceed.

### 1.2 The verbatim-choice-list rule

The run did not ignore Phase 6.5. It **re-ranked** it. So the ledger needs a companion rule, and that
rule is not `/document`-specific:

> **A choice list written into a command phase is presented to the user verbatim. Its options, their
> order, their wording, and the `(Recommended)` marker are not the orchestrator's to change. An
> orchestrator that believes a different option is correct for this run says so in prose alongside
> the list — it never edits the list.**

This lands in `references/escalation-rules.md`, which already owns the prompt-shape rules, and binds
every command in the plugin.

### 1.3 Where the ledger lives

A new `references/gate-ledger.md` is the single source of truth for the schema, the outcome
vocabulary, the gate registry, and the reviewer contract.

The ledger itself is an in-context YAML block. The orchestrator **appends a row at the moment each
gate completes** — never reconstructs the ledger at Phase 9 from memory, which is precisely where the
PRODUCT-17012 drift happened. It is passed to `doc-reviewer` and rendered as a table in the Phase 9
report.

```yaml
gate_ledger:
  - gate: <registry id>
    phase: "<the phase that owns it>"
    outcome: RAN | DEGRADED | FAILED | UNAVAILABLE | SKIPPED_BY_USER | NOT_APPLICABLE
    mechanism: <what actually executed; omitted when nothing did>
    not_run: [<primary mechanism>: <reason>]     # DEGRADED only, non-empty
    ci_still_checks: <one line>                  # DEGRADED only, non-empty
    precondition_unmet: <the named precondition> # NOT_APPLICABLE only, non-empty
    user_decision: "<the user's choice, verbatim>"  # SKIPPED_BY_USER only, non-empty
    findings: <count>                            # RAN / DEGRADED / FAILED
```

### 1.4 The gate registry for `/document` (Jira mode)

| Gate id | Phase | Precondition | Primary | Fallback |
|---|---|---|---|---|
| `source_truth_verification` | 5.8 | ≥1 entry in `code_repos` | claim-class verification per `source-truth.md` §2–§3 | supplementary direct grep against the resolved local path (§5.2) |
| `style_check` | 6.4 | ≥1 file written | the repo linter ladder (§2) **plus** `dt-style-checker` complementary | `dt-style-checker` alone |
| `repo_checklist` | 6.4 | the repo publishes authoring/verification guidance | `repo_verification_gates` applied to the written files (§4) | none |
| `build_check` | 6.5 S1 | write context is a buildable repo | `commands.per_space.<space>.build` for each written space, else the whole-repo `commands.build` | the Step 2 dev-server boot |
| `render_smoke_check` | 6.5 S2 | buildable repo with ≥1 affected page | dev servers for the target **and** protected spaces | the manual pages-to-visit table |

A gate whose precondition is unmet records `NOT_APPLICABLE` with the precondition named. It is never
silently absent.

### 1.5 The reviewer contract

`doc-reviewer` gains a **Verification-gate integrity** dimension and receives `gate_ledger` as an
input. It replaces today's two loose free-text inputs, `style-check report` and `render_verification`,
both of which the reviewer could only read narratively.

BLOCKER when any of these hold:

- a registry gate has **no row** in the ledger;
- a row's outcome is `UNAVAILABLE` (it was never converted to a user decision);
- `SKIPPED_BY_USER` with an empty or absent `user_decision`;
- `NOT_APPLICABLE` with an empty or absent `precondition_unmet`;
- `DEGRADED` with an empty `not_run` or `ci_still_checks`.

`DEGRADED` is otherwise not a finding. The reviewer notes it; Phase 9 prints its `ci_still_checks`
line prominently.

The existing **Style-check follow-through** dimension keeps its job (unresolved violations above
MINOR become findings) but reads the `style_check` row instead of the free-text report. Its
"skip when `status: NOT_CONFIGURED`" clause is replaced by "skip when the `style_check` row is
`NOT_APPLICABLE` or `SKIPPED_BY_USER`". `docs-style-checker` can still *return* `NOT_CONFIGURED` —
§2 makes the ladder try every rung first, but a repo with no linter config and no `dt-style-guide`
installed still has nothing to run. That status maps to a ledger `UNAVAILABLE`, which §1.7 then
converts. It never rests as `NOT_CONFIGURED`.

### 1.6 Phase 9 rendering

The Phase 9 report gains a `### Verification gates` table: one row per registry gate — gate, outcome,
mechanism, and the `ci_still_checks` / `user_decision` / `precondition_unmet` detail where it applies.
This is the durable artifact the user reads, and the reason the ledger does not need its own file.

### 1.7 Converting `UNAVAILABLE`

A gate whose primary and fallback mechanisms both failed to run, with the precondition met, is a real
coverage hole — the case the approved strictness call says must not proceed silently. The orchestrator
converts it before the run continues, with a choice list bound by §1.2:

```
choices: ["Install <named tool> and retry this gate", "Proceed without this check — record my decision", "Cancel the run"]
```

"Retry" re-runs the gate and rewrites its row. "Proceed" writes `SKIPPED_BY_USER` with the user's
choice quoted verbatim. "Cancel" aborts. There is no fourth path, and the orchestrator never selects
among the three on the user's behalf.

---

## 2. F1 — the linter ladder falls through instead of jumping

`docs-style-checker`'s detection order is documented as "first match wins", and its failure handling
sends every step-1/2/3 failure to **step 5**. So a *detected but broken* rung abandons every rung
below it. On `dynatrace-docs` that is exactly what happens: `.vale.ini` exists, `vale` is not on
PATH, and `pnpm dynatrace:lint` / `pnpm managed:lint` are never attempted.

Three changes:

1. **It becomes a real ladder.** A failure at step *N* continues to step *N+1*. The first step that
   **succeeds** sets `primary_linter`. Step 5 (`dt-style-checker`) is reached after steps 1–4 have
   each been tried, not as an escape hatch from the first one.
2. **It becomes space-aware.** The agent's inputs today are only `repo_root` and `files`, so it has
   no way to know a file belongs to the Managed space. It gains a third, optional input —
   `spaces: [{id, content_root, lint}]`, passed by the orchestrator from the resolved profile — and
   runs the lint command for each space that owns at least one entry in `files`, matching by
   `content_root` prefix. A Managed-only run is linted by `managed:lint`, not `dynatrace:lint`. When
   `spaces` is absent or empty, the agent falls back to the whole-repo `*:lint` detection it does
   today, so a generic docs repo is unaffected.
3. **It reports its attempts.** The return gains
   `primary_attempts: [{linter, outcome, reason}]`, so the ledger can record `DEGRADED` with
   specifics — "vale: binary not on PATH; pnpm dynatrace:lint: exit 1, build folder absent" — rather
   than an unexplained fallback.

`dt-style-checker` keeps running as the complementary pass whenever `dt-style-guide` is installed.
That was already the specification (v1.7.1: *"If steps 1-3 succeeded → run as COMPLEMENTARY pass
(always, when `dt-style-guide` is installed)"*) and the two are genuinely complementary — Vale covers
lexical-at-scale and frontmatter fields; `dt-style-checker` covers engineer jargon, cross-page label
consistency, and plural/singular UI-label mismatch. The change is that with a working ladder, the
complementary path becomes reachable for the first time in this environment.

**Supporting detail.** `dynatrace-docs`' `CONTRIBUTING.md` states: *"Before running the `lint` command
for the first time in the local repository, run the `serve` command once. This creates a build folder
that is required for the lint command to run properly."* That becomes a declared entry in the
profile's `prerequisites`, so a cold-repo lint failure is reported with its cause instead of as an
opaque non-zero exit.

---

## 3. F2 — `changelog-guidelines.md` gets consumers

The rules stay in the reference. Nothing is duplicated, and the reference remains the single source of
truth.

`doc-planner`, `doc-writer`, and `doc-reviewer` each read
`${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/changelog-guidelines.md` when the profile's
`frontmatter.changelog_guidelines` pointer resolves. Agents cannot invoke skills, but they can read
files — so the `dynatrace-docs-frontmatter` skill stays untouched for interactive use and stops being
the only path to the rules.

- **`doc-planner`** plans `changelog:` entries that conform to the guideline, not just to its two
  inlined rules. Its existing prohibitions (no Jira key; never a changelog-only update on an otherwise
  unchanged page) are unaffected.
- **`doc-writer`** applies the guideline when writing the entry.
- **`doc-reviewer`**'s YAML-frontmatter dimension upgrades from "customer-readable 1-line summary and
  no Jira key" to conformance against the guideline — customer point of view, the "to what effect?"
  test, verb variety, the period rule, and a ban on internal render-mechanic jargon such as
  "Managed-only" — at **MAJOR**.

This is the fix for the concrete PRODUCT-17012 defect: five changelog entries that used space-scoping
jargon ("Added a **Managed-only** notice"), meta phrasing that fails the "to what effect?" test ("a
note **linking … to this section**"), an overused "Added", and a redundant screenshot-only entry.

---

## 4. F3 — the repo's pre-PR checklist is ingested, not discarded

`doc-planner`'s instruction to ignore operational content stays — for its own topic and section
planning, build steps and PR mechanics are noise. But it now **additionally** emits a
`repo_verification_gates` block: the repo's own pre-PR checklist items that are checkable against the
files the run just wrote.

For `dynatrace-docs` that is the `## PR checklist → Advanced check (InfoDevs)` list — frontmatter
fields present and correct, `changelog` present and conforming to the repo's changelog guidelines, no
sensitive information in text or screenshots, no duplicate headers, terminology and product-name
capitalization, no walls of text, and *"Validate the change. The validation must pass with no errors
or warnings"* (a local build plus source validation). It is generic: any repo publishing a checklist
gets one.

The block feeds two consumers — the ledger's `repo_checklist` row, and `doc-reviewer`, which now has
repo-anchored findings rather than only plugin-internal ones. Like `repo_authoring_guidance`, it
**augments and never overrides** the built-in references; a conflict is noted, not silently resolved.

Alongside it, three plugin-side corrections that cost no PR into `dynatrace-docs`:

1. **`docs-profile.default.yml` gains per-space `lint` and `build` commands.** `dynatrace:build`,
   `managed:build`, and `managed:lint` all exist in the repo's `package.json`; the profile knows only
   `pnpm dynatrace:lint`. Shape:

   ```yaml
   commands:
     lint: "pnpm dynatrace:lint"        # whole-repo default, unchanged
     format: "pnpm prettier -w"
     commit_hook: "husky pre-commit -> lint-staged -> pnpm prettier -w"
     per_space:
       saas:    {lint: "pnpm dynatrace:lint", build: "pnpm dynatrace:build"}
       managed: {lint: "pnpm managed:lint",   build: "pnpm managed:build"}
   ```

2. **`docs-profile-schema.md` documents `commands.per_space`** as an optional map keyed by space id,
   and `/docs-profile` learns to detect and populate it.
3. **`render-verification.md`'s false claim is corrected.** The sentence asserting the dynatrace-docs
   case has "only `commands.lint` + the `*:start` dev servers" is replaced with the true statement,
   and the "no build command ⇒ defer build proof to the dev-server boot" branch stays as the generic
   fallback for repos that genuinely lack one.

---

## 5. F4 — commands and code blocks become a verified claim class

### 5.1 The new claim class

`source-truth.md` §2's table gains a row:

| Claim type | Where to verify in code |
|---|---|
| **Commands, CLI invocations, and copy-paste code blocks** (helm/kubectl/pnpm invocations, flags, image references, chart names, registry paths, YAML keys inside fenced blocks) | Chart and manifest files in the source repo (`Chart.yaml`, `values.yaml`, `templates/**`), the CI/release workflows that publish the artifact, sibling docs pages already carrying the same command, and `--help` / usage strings in the CLI source |

An unresolvable command becomes a `NOT_FOUND` / `AMBIGUOUS` verification warning escalated in
Phase 5.8 like every other discrepancy — the existing machinery, not a new one.

`doc-reviewer`'s **Source-code accuracy** dimension treats an unverified copy-paste command as
**MAJOR** rather than an ordinary "not verifiable" note. A reader runs a `helm` line verbatim; it is
the highest-blast-radius claim on a page.

### 5.2 The supplementary grep

One item from the feedback file that the user did not name, folded in because it is the same gate.
Phase 5.8 today escalates an `AMBIGUOUS` / `NOT_FOUND` verification warning straight to the user even
when the relevant repo is sitting resolved in `code_repos`. On PRODUCT-17012 the user resolved it by
grepping the local clone by hand — a step the workflow does not prescribe.

Phase 5.8 will run **one** supplementary direct grep against the resolved local repo path before
presenting the discrepancy table, **including when `diff-summarizer` returned `REFRESH_BLOCKED`** for
that repo — a read-only mount that cannot `git fetch` can still be grepped. This is the
`source_truth_verification` gate's declared fallback (§1.4): a resolution by grep records `DEGRADED`
with `not_run: [diff-summarizer refresh: REFRESH_BLOCKED]`, not a clean `RAN`.

---

## 6. F5 — the render gate stops being skippable by the orchestrator

Four changes to Phase 6.5:

1. **Step 1 actually runs.** With `commands.per_space.<space>.build` now defined (§4), the gating
   build check executes for each written space instead of falling through the "no build command"
   branch.
2. **Step 2's choice list is presented verbatim** under the §1.2 rule. `(Recommended)` stays on the
   smoke-check. Skip is only ever the user's, and it writes `SKIPPED_BY_USER` with their decision
   quoted.
3. **Cross-space runs boot both spaces.** The loop iterates `target_spaces` only, so the *protected*
   space's render — the thing the 3a invariant exists to defend — is never checked. When any page in
   the run has a `conditional` or `override-copy` write strategy, the protected space is booted too:
   the delta marker must be PRESENT in the target render and ABSENT in the protected one. Both
   halves of the invariant, not just the half that is convenient.
4. **Static analysis cannot satisfy the gate.** The `{{#if project='…'}}` conditional-wrapping
   guarantee and the link-integrity greps are declared explicitly **necessary but not sufficient**:
   they corroborate the render gate and can never substitute for it. Static greps do not catch
   Handlebars compile errors, whether `managed/docstack.jsonc`'s allowlist actually pulls a shared
   page into the managed render, or whether a postid resolves in the managed build.

Boot, prerequisite, and readiness problems stay best-effort and non-blocking — but they now record
`DEGRADED` with the reason, and the manual pages-to-visit table is the named fallback rather than an
unremarked substitute.

---

## Files changed

**Canonical (`ihudak-claude-plugins`), `plugins/dev-workflows/`:**

| File | Change |
|---|---|
| `references/gate-ledger.md` | **new** — schema, outcome vocabulary, gate registry, reviewer contract |
| `references/escalation-rules.md` | + the verbatim-choice-list rule (§1.2) |
| `references/source-truth.md` | + the commands/CLI/code-block claim class (§5.1); + the supplementary-grep step (§5.2) |
| `references/dynatrace-docs/render-verification.md` | correct the "no build command" claim; + both-space boot for cross-space runs; + static-analysis-is-insufficient |
| `references/dynatrace-docs/docs-profile.default.yml` | + `commands.per_space`; + the lint-needs-a-prior-serve prerequisite |
| `references/dynatrace-docs/docs-profile-schema.md` | document `commands.per_space` |
| `agents/docs-style-checker.md` | ladder fall-through; space-aware lint; `primary_attempts` in the return |
| `agents/doc-planner.md` | read `changelog-guidelines.md`; emit `repo_verification_gates` |
| `agents/doc-writer.md` | apply `changelog-guidelines.md` |
| `agents/doc-reviewer.md` | + Verification-gate integrity dimension; `gate_ledger` input replaces the two free-text inputs; changelog conformance at MAJOR; unverified command at MAJOR |
| `commands/document.md` | ledger rows written at Phases 5.8 / 6.4 / 6.5; Phase 6.5 Steps 1–2 per §6; Phase 9 `### Verification gates` table |
| `commands/docs-profile.md` | detect and populate `commands.per_space` |
| `README.md` | + `gate-ledger.md` in the reference list; refresh the `/document` row |
| `CHANGELOG.md` | `## [2.43.0] — 2026-08-08` |
| `.claude-plugin/plugin.json` | version → 2.43.0 |
| `../../.claude-plugin/marketplace.json` | `dev-workflows` entry: version + description |
| `../../CLAUDE.md` | + `gate-ledger.md` under Source-truth reference; update the `/document` invariants |

**Direct mode** (`/document` Phase 3.5) gets the same `style_check` ledger row and the same ladder fix
— it shares `docs-style-checker`. It gets no render gate; it has no `target_spaces`.

## Porting

| Repo | Version | Notes |
|---|---|---|
| `ihudak-claude-plugins` | dev-workflows 2.43.0 | canonical |
| `mgd-claude-plugins` | dev-workflows 2.43.0 | content-verbatim **except** the five identity files: `plugins/dev-workflows/.claude-plugin/plugin.json`, `README.md`, `LICENSE`, `references/dependencies.md`, `CHANGELOG.md` — plus repo-root `CLAUDE.md` and `.claude-plugin/marketplace.json` |
| `ihudak-copilot-plugins` | dev-workflows 2.13.0 | adapted layout: `skills/<name>/SKILL.md`, `skills/_shared/<ref>.md`, `~/.copilot/installed-plugins/…` reference paths, `task(agent_type: …)` dispatch, lowercase `tools:` lists. **Both** `.github/plugin/marketplace.json` and `.github/copilot-instructions.md` are in scope — each was missed in 2.42.0 |

The `marketplace.json` bump has now been missed twice on this plugin. It appears in the
implementation plan's file table explicitly, per repo, not only in the porting prose.

## Verification

There is no test framework — this is prompt and reference markdown. Verification is grep and reading:

1. Every gate in the §1.4 registry has a ledger-append instruction at its owning phase in
   `commands/document.md`.
2. No phase in `commands/document.md` offers an outcome the orchestrator can assign that means "I
   decided not to run this" — grep for skip language not bound to a user choice or a named
   precondition.
3. `changelog-guidelines.md` is cited by at least three files in the write path
   (`doc-planner.md`, `doc-writer.md`, `doc-reviewer.md`).
4. `docs-style-checker.md` contains no jump from step 1/2/3 directly to step 5; each failure path
   names the next rung.
5. `docs-profile.default.yml`'s `per_space` commands match `dynatrace-docs`' `package.json` script
   names exactly.
6. `render-verification.md` no longer claims the dynatrace-docs profile has no build command.
7. `source-truth.md` §2's table contains the commands/CLI row; `doc-reviewer.md` grades an unverified
   command at MAJOR.
8. The verbatim-choice-list rule exists in `escalation-rules.md` and is cited from
   `commands/document.md` Phase 6.5.
9. All three `marketplace.json` catalogs and all three `plugin.json` files carry the new version, and
   only the `dev-workflows` entry is touched in each catalog.
10. No `${CLAUDE_PLUGIN_ROOT}` or `subagent_type` token leaks into any Copilot file; no
    Copilot-style path leaks into a Claude file.

## Rejected alternatives

**More emphatic prose.** The Phase 6.4 wording already reads "Mandatory … MUST … never skip on its
own judgement" and has since v2.0.0. Escalating the adjective is the one intervention with a
measured failure.

**A blocking hook.** The plugin ships hooks, and a `Stop` hook could inspect a ledger. But this
repo's convention is that hook scripts must exit 0 and never block Claude, so a hook can only warn —
and a warning is what already failed. A hook would also need the ledger to exist on disk, which
reintroduces the untracked-artifact problem.

**Writing the ledger to a file.** Durable across compaction and independently auditable, but it
lands another untracked artifact in the project folder — the exact problem sub-project C exists to
fix. The Phase 9 report is the durable artifact instead.

**Making every gate unconditional (no choice lists).** Strongest guarantee and zero rationalization
surface, but it boots dev servers on every `/document` run in a buildable repo, with no way to decline
— and the feedback record notes those servers are slow and flaky. Rejected in favour of the ledger,
which keeps the choice but makes it the user's and makes the skip visible.

**Duplicating the changelog rules into the agent prompts.** Faster than wiring the reference, and it
drifts the moment either copy is edited. The reference stays the single source of truth.

## Out of scope

- **B2 — `/document` authoring and placement defects.** The remaining six entries in the PRODUCT-17012
  feedback file: the deprecation note landing in `container-registries/index.md` instead of
  `whats-new/technology/end-of-life-announcements.md` (`doc-location-finder` never scanned
  `whats-new/technology/`); the unwanted `<!-- PRODUCT-17012: … -->` provenance comments; the Phase 8
  maintenance agent's `CLAUDE.md` edit folded into the docs branch, which in this repo would have
  delayed the documentation by months; callout-scope adjacency (option-specific callouts must sit
  beneath their option, never as a trailing block); stale existing screenshots on edited UI-flow
  pages; and reuse of the surrounding content area's established component pattern
  (`{{#tabgroup}}`) instead of ad-hoc bold pseudo-headings. Plus the two `missing-reference-doc`
  items: an anchor-conventions reference, and widening `source-truth.md` §7.5's bug-report trigger to
  cover `document-as-code` decisions where the Jira phrasing was factually wrong.
- **C — git completeness.** `/create-vi` offers git in Phase 5, then Phases 6 and 7 write `resume.md`,
  cost, and feedback files into the same folder; `feedback-emission.md` and `cost-emission.md` both
  say "NEVER commits". Late artifacts are untracked by construction, across roughly eight commands.
- **D — mechanical.** Namespace next-step suggestions as `/dev-workflows:<command>`, and refresh the
  README and workflow diagram to cover `/update-vi` and `/idea --deep`.

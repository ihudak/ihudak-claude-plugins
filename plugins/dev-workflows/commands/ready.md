---
name: ready
description: Status-anchored readiness gate. Reads the Jira workflow status of a VI/Epic and verifies the ARD/spec/design artifacts justify it and the next transition; returns SUPPORTED / PARTIAL / NOT-SUPPORTED with a coverage roll-up. Read-only — never sets Jira status, never commits. Gates on the Opus readiness-reviewer.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch LS
---

Verify readiness for AI-driven development for the Jira item: $ARGUMENTS

`/ready` is the **status-anchored readiness gate**. Given a Jira VI (or VI + Epic) key, it reads the
**declared** Jira workflow status — never inferred, never re-derived — and checks whether the
ARD/spec/design artifacts that actually exist, taken together, justify that status and the *next*
transition, against the rubric in `${CLAUDE_PLUGIN_ROOT}/references/workflow-states.md`. It returns
`SUPPORTED` / `PARTIAL` / `NOT-SUPPORTED` with a requirement coverage roll-up and named gaps, gated on
the Opus `readiness-reviewer`.

Key distinction from every other pipeline command: `/ready` **authors nothing**. It never writes a VI,
Epic, ARD, spec, or design; it never touches Jira; it never branches or commits. Its only write is an
overwritten `_readiness.md` snapshot under `$SPECS_PATH`, and even that is the user's to commit. Where
`/design`'s repo gate is a **strict, hard-stop** mount check because it is about to ground code
decisions, `/ready`'s repo check is **best-effort presence only** — it never scans code, it only notes
whether a needed repo is mounted.

Key distinction from `/design`'s Epic-picker behavior: `/ready`'s two-key grammar treats a **null**
`focus_key` as a first-class **VI-level** check (workflow-states.md's VI ladder), not something that
must be resolved down to a single Epic. Pass an explicit `<VI> <Epic>` to scope the check to one Epic
(the Epic ladder) instead.

---

## Phase 0 — Resolve input

1. **Resolve the Jira input via the shared front-end.** Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against `$ARGUMENTS`. `/ready` is
   **jira-driven only**: expect `mode: jira-driven`. The front-end owns the `$VAULT_PATH` /
   `jira-products` validation, Fallbacks A/B **and D/E**, and the VI-selector (key-or-directory) +
   focus-Epic grammar. Carry forward `jira_key`, `focus_key`, `jira_export_root`, `source`.

   Define **`<VI>` = `jira_key`** and **`<EPIC>` = `focus_key`** (may be `null`) — the two-key grammar.

   If the front-end returns `mode: direct` (no Jira input), stop with
   `READY_NEEDS_JIRA: /ready needs a Jira key or an imported-Jira directory.` — `/ready` has no
   direct-prompt behavior.

2. **Resolve `$SPECS_PATH`.** `/ready` reads the ARD/spec/design artifacts and writes `_readiness.md`
   under `$SPECS_PATH/specifications/`. If `$SPECS_PATH` is unset, stop with a clear error naming
   `SPECS_PATH`: `choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`.

3. **Read from a clean specs-repo main — never a branch.** The specs repo's `main` (or `master`) branch
   is the handoff surface for every artifact `/ready` judges (per `/design`'s Phase 0 rule). Check
   `git -C $SPECS_PATH branch --show-current` and `git -C $SPECS_PATH status --porcelain`:
   - Not on `main`/`master`, or the tree is dirty → warn (a non-`main` or dirty checkout may show
     unmerged, in-flight artifacts as if they were the handed-off truth) and ask:
     `choices: ["I've switched to a clean main — re-check", "Proceed anyway on the current checkout (read-only; noted in the report)", "Cancel", "Other… (describe)"]`
   - Clean `main`/`master` → proceed silently.

4. **Map onto the specs repo (VI dir + optional Epic subdir).** Resolve the VI dir
   `$SPECS_PATH/specifications/<VI>-<vslug>/` by **key-number match** (tolerate a stray `-`/`_` after
   the key and a human-adjusted slug — the same tolerance `ard-resolution.md` and `/design` use). When
   `focus_key` is set, additionally resolve the per-Epic subdir
   `<VI-dir>/<EPIC>-<eslug>/` by the same tolerance. **Unlike `/design`, a missing dir is NOT a hard
   stop** — an early-lifecycle VI (e.g. `Open` / `Problem Stated`) legitimately has no specs-repo
   footprint yet, and "nothing exists" is itself readiness-relevant data, not an error. Record whichever
   dir(s) resolved (or "not found — no specs-repo footprint yet").

`/ready` is **cwd-agnostic** — it reads an absolute `$SPECS_PATH`-rooted feature folder and (Phase 3)
best-effort-checks repos under `$REPOS_PATH`; cwd need not be inside either.

---

## Phase 1 — Clarify + artifact inventory

**Rule: Ask, don't guess. This rule is absolute.** Use `choices` arrays; the last choice in every array
MUST be `"Other… (describe)"`.

1. **Confirm the resolved scope.**
   `choices: ["Use <VI dir> [+ <Epic subdir>] (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]`

2. **Artifact inventory (mechanical presence check — no content judgment yet).** By mode:
   - **VI-level** (`focus_key` null) — check for `<VI-dir>/<VI>_ARD.md` and `<VI-dir>/specification.md`
     (a VI-level spec is optional per `workflow-states.md`); then enumerate **every** Epic subdirectory
     under `<VI-dir>` that matches a key-number pattern, and for each record whether
     `{<EPIC>_ARD.md, specification.md, design.md}` exist — this is per-Epic and plural, because a VI's
     "Ready for Implementation" status requires **every in-scope Epic** to carry spec + design
     (`workflow-states.md`'s VI row).
   - **Epic-level** (`focus_key` set) — check for the VI-level `<VI-dir>/<VI>_ARD.md` (inherited
     invariants) plus the single focus Epic's `{<EPIC>_ARD.md, specification.md, design.md}` under
     `<VI-dir>/<EPIC>-<eslug>/`.
   Record each as present (with its absolute path) or absent. Do not open/read file contents yet beyond
   what's needed to confirm existence — full reads happen in Phase 4 via the reviewer.

3. **Quick Jira status peek (display only — not the ground truth).** Read
   `<jira_export_root>/<jira_key>-index.md`'s `| Key | Type | Status | Summary | Role |` table directly
   (mechanical — no subagent) and note the `Status` column for `<VI>` and, when set, `<EPIC>`. This is
   for **Phase 1 display context only**; Phase 2's `jira-reader` read is the authoritative source the
   reviewer verifies against.

4. **Display** (context, no further prompt): resolved cwd; resolved VI dir (+ Epic subdir); resolved
   `$SPECS_PATH`; the artifact inventory table from step 2; the status peek from step 3.

No branching context is shown — this command never branches.

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the
classification rules, then classify the task as exactly one of: `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or
`HIGH-RISK`. Readiness verification is typically **MODERATE** (bounded scope, a single VI or Epic,
read-only, no code changes) — escalate to `SIGNIFICANT` only for an unusually large multi-Epic VI where
the coverage chain spans many Epics/repos. State the classification and a one-sentence reason.

`/ready` has **no delegated writer/implementation subagent** — the Phase 3 skeleton is deterministic and
orchestrator-inline, and the only judgment-heavy delegate is the `readiness-reviewer` gate (Opus,
frontmatter-pinned, mandatory regardless of tier). Resolve the per-step routing per
`${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible for a large multi-Epic VI
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader (Phase 2); the Phase 3 deterministic skeleton is mechanical and runs orchestrator-inline, not delegated
  review_model:    <§2 Opus chain>     # readiness-reviewer (frontmatter-pinned; recorded, no override)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

**No relaunch advisory for MODERATE** — the mechanical steps run on their detection pin and the
orchestration runs on `current_model`, which §3.1 allows. If no Opus is available, `readiness-reviewer`
falls to the Sonnet floor — record the degradation in `notes` and the final report.

---

## Phase 2 — Read ground truth

Invoke `jira-reader` with `depth: vi-plus-epics` — this is the authoritative status/requirement source
the reviewer verifies the declared status against (never Phase 1's status peek).

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
  > depth:      vi-plus-epics"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found`
rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On `OK`,
carry forward:

- `value_increment.status` — the VI's declared status (VI ladder).
- `linked_items[]` filtered to `type == Epic` and their `.status` — each Epic's declared status (Epic
  ladder). When `focus_key` is set, validate it is among these; if not, surface
  `READY_FOCUS_NOT_FOUND: <focus_key> is not a linked Epic of <jira_key>.` with
  `choices: ["Check VI-level readiness instead (the whole VI)", "Re-enter the Epic key", "Cancel"]`.
- `requirements[]` (+ `requirements_source`) — the coverage ground truth for Phase 3(a).

These declared statuses are passed to the reviewer **exactly as read** — never inferred, never
re-derived (per `readiness-reviewer.md`'s hard rules).

---

## Phase 2.5 — Resolve ARD

Resolve any applicable ARD by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with
`vi = jira_key`, `epic = focus_key` (may be `null`), and `$SPECS_PATH`.

- **`status: none`** (including `$SPECS_PATH` unset/unresolvable) → the ARD dimension is **inactive** for
  this run — no prompt, no extra output, `readiness-reviewer`'s ARD-conformance dimension is skipped
  entirely (no-regression, per `ard-resolution.md`).
- **`status: found`** → carry the returned `invariants` (`AD-N` list, VI-level inherited +
  Epic-level when in scope) forward to Phase 4 as `applicable_ard`. `/ready` never edits the ARD and
  never authors a deviation record itself — it only checks whether one already exists in the artifacts
  it reads (an artifact that violates an `AD-N` **without** a matching
  `- ARD deviation: … flag: architect` line is a BLOCKER per the reviewer's ARD-conformance dimension).

---

## Phase 3 — Deterministic skeleton

Mechanically build three inputs for the reviewer — orchestrator-inline, no subagent, no user prompt.

**(a) Coverage map.** For each requirement in Phase 2's `requirements[]` (by `id`), grep its ID token
across the in-scope Epic `.md` file(s), `specification.md`(s), and `design.md`(s) found in Phase 1's
inventory. Record, per requirement: which Epic(s) mention it, whether a `specification.md` mentions it,
whether a `design.md` mentions it, or "not found by ID in any artifact". **Acknowledge the limitation**
(carried to the final report's Assumptions section): this is an ID-grep, not semantic matching — an
artifact may cover a requirement thematically without repeating its literal ID; `readiness-reviewer`
reads the full artifact text and can catch what the grep misses.

**(b) Status-expectation checklist.** Look up the declared VI status (and, when in scope, each Epic
status) on the matching ladder in `${CLAUDE_PLUGIN_ROOT}/references/workflow-states.md`, list that
status's "Expected artifacts" column, and mark each expected artifact present ✅ or absent ❌ against
Phase 1's inventory. This is the mechanical half of the reviewer's "Status consistency" dimension.

**(c) Repo-availability presence-check (best-effort, presence only — never scanning).**

1. Derive candidate repo names from: each in-scope Epic's `## Pull Requests` section URLs (the repo-name
   segment of each URL, per `jira-reader`'s PR URL formats); the confirmed-repos line of any `design.md`
   found (`design-format.md`'s header `- **Repos**: <the confirmed implementation repos this design
   spans>`); and any ARD's `grounded_repos:` frontmatter list (`ard-format.md`). Dedupe.
2. Build the slug→clone map **exactly as `epics.md` Phase 4 does**: for each top-level directory under
   each entry of `${REPOS_PATH:-/workspace}`, run
   `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the
   URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote`
   call fails/times out.
3. Match each derived candidate against the map: mounted (record the resolved path) or not-mounted.
   **Presence only — never dispatch `code-scanner`, never confirm/mount-gate like `/design`'s Phase 3**;
   this is informative context for the reviewer's "Repo availability" dimension, not a hard gate.
4. If no repo names are derivable from any source (no PRs yet, no `design.md`, no ARD `grounded_repos`)
   → record `repos: not-yet-determinable` rather than an empty/false "all missing" result — this is the
   normal case pre-implementation and must not read as a gap.

---

## Phase 4 — Readiness review

Dispatch `readiness-reviewer` (Opus, frontmatter-pinned — no override) with the Phase 3 skeleton, the
artifact paths from Phase 1 (the reviewer Reads each end-to-end itself — it carries `Read`/`Glob`/
`Grep`/`LS`), the Phase 2 declared statuses, `applicable_ard` (omit entirely when Phase 2.5 was `none`),
and a pointer to the rubric.

→ Agent (subagent_type: "dev-workflows:readiness-reviewer"):
  > "Review readiness for this brief:
  >
  > Task description: [one paragraph: <VI> [+ <EPIC>], the declared status(es), what is being verified]
  > requirements:            [paste the requirements[] array from Phase 2]
  > coverage_map:            [paste Phase 3(a)]
  > status_expectation:      [paste Phase 3(b), plus the workflow-states.md rubric reference]
  > repo_availability:       [paste Phase 3(c)]
  > artifact paths:
  >   VI:      [<VI-dir>/<VI>.md if read, or the jira-reader handoff's VI summary]
  >   ARD:     [absolute path(s), or 'none']
  >   Epics:   [absolute path(s) in scope]
  >   specs:   [absolute path(s) in scope]
  >   designs: [absolute path(s) in scope]
  > declared_status:         [VI: <status>; Epics: <key>=<status>, …]
  > applicable_ard:          [the Phase 2.5 invariants, or omit entirely if status was none]
  > workflow_states_rubric:  ${CLAUDE_PLUGIN_ROOT}/references/workflow-states.md"

Carry back the verdict (`SUPPORTED` / `PARTIAL` / `NOT-SUPPORTED`) and the full Findings section
(by dimension) for Phase 5. `readiness-reviewer` never modifies files and never re-derives status — a
run that returns without a verdict or without the declared-status/`requirements[]` ground truth is a
plugin-gap halt (see Invariants).

---

## Phase 5 — Write report

1. **Compose the readiness artifact.** Build the report content: a header stamping the run timestamp
   (ISO 8601 UTC), the specs-repo git rev (`git -C $SPECS_PATH rev-parse --short HEAD`), the checked
   Jira status(es) exactly as read in Phase 2, the verdict, the coverage roll-up (N/M requirements
   covered, P%, each ❌ gap requirement ID named), and the full Findings section from Phase 4.

2. **Write `_readiness.md`**, **overwriting** any prior run, to the VI dir (VI-level) or the Epic subdir
   (Epic-level):

   ```markdown
   ---
   type: dev-workflows-readiness
   vi: <JIRA_KEY>
   epic: <FOCUS_KEY>            # omitted when VI-level (focus_key null)
   ---

   # Readiness check — <run timestamp, ISO 8601 UTC>

   - Specs repo rev: <short HEAD>
   - Checked status: VI=<status>[, Epic <KEY>=<status>, …]
   - Verdict: SUPPORTED | PARTIAL | NOT-SUPPORTED

   ## Coverage roll-up
   <N/M requirements covered (P%); each ❌ gap requirement ID, one per line>

   ## Findings
   <the readiness-reviewer's Findings section, verbatim, by dimension>

   ## Repo availability
   <Phase 3(c) result>

   ---
   Generated by `/ready`. NOT committed automatically — commit this file yourself if you want to share
   this readiness snapshot with your team.
   ```

3. **Emit the terminal report to stdout:**

   ```
   ## Readiness Report

   ### Classification
   [MODERATE | SIGNIFICANT] — [one-line reason]

   ### Model Routing
   - Session model (current_model): [model]
   - Detection steps — jira-reader (detection_model): [model]
   - readiness-reviewer (review_model): [model]
   - Opus available: [yes | no]

   ### Scope
   - VI: <JIRA_KEY> — [summary]
   - Epic: <FOCUS_KEY> — [summary] — _or_ "none — VI-level check"
   - Specs repo rev: <short HEAD>

   ### Declared status (Phase 2 — authoritative)
   - VI: <status>
   - Epic <KEY>: <status> — _or omit when VI-level_

   ### Artifact inventory (Phase 1)
   [present ✅ / absent ❌ per artifact, one line each]

   ### Verdict
   [SUPPORTED | PARTIAL | NOT-SUPPORTED]

   ### Requirement coverage
   [N/M covered (P%); list each ❌ gap requirement ID] — _or_ "derived (coarse) — VI had no structured requirements"

   ### Findings
   [readiness-reviewer's Findings section, by dimension]

   ### Repo availability
   [Phase 3(c) result]

   ### ARD conformance
   [verdict + any `- ARD deviation:` lines the reviewer found] — _omit this whole section when Phase 2.5 status was none_

   ### Assumptions & limitations
   - Coverage map (Phase 3a) is an ID-grep, not semantic matching — the reviewer's full read may find
     coverage the grep missed, and vice versa.
   - [any other caveats — e.g. non-main/dirty specs checkout override]

   ### `_readiness.md`
   Written (overwritten) to: <absolute path>. NOT committed — `/ready` never commits; commit it yourself
   to share this snapshot.

   ### Next step
   [Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — guidance only, never auto-invoked. SUPPORTED → Team →
   `/implement <VI> [<Epic>]`. PARTIAL / NOT-SUPPORTED → resolve the named gaps above and update the
   Jira status to match reality, then re-run `/ready <VI> [<Epic>]`.]

   ### Context hygiene
   Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1;
   record the readiness verdict as a carry-forward line). Then:

   - **SUPPORTED → `/implement <VI> [<Epic>]` (still Team)?** → run **`/compact`** — context stays relevant.
   - **PARTIAL / NOT-SUPPORTED → resolving the gaps yourself now?** → **`/compact`**.
   - Consider **`/rename <VI-ID>-<slug>-team`** to relocate this session later.

   Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
   ```

`/ready` **NEVER** writes to Jira, `jira-products/`, or the vault, and **NEVER auto-commits**
`_readiness.md` — git is the user's responsibility. Phases 6–8 below append their own short trailing
notices after this report; they do not reopen or restate it.

---

## Phase 6 — Post-run maintenance & feedback

Mirrors `epics.md` Phase 8, run as a genuinely **terminal** phase (unlike `/epics`, where maintenance
feeds the still-to-come final report — here the readiness report already printed in Phase 5).

a. `project_root` = `$SPECS_PATH` for this run (where `_readiness.md` was written). Run
   `git diff --stat` from `project_root` if it is a git repo (it should be, per Phase 0 step 3) —
   just to report what changed; this command never commits.
b. Compose a **change summary block**:

```
Implementation: [one-sentence: readiness check for <VI> [<Epic>], verdict SUPPORTED | PARTIAL | NOT-SUPPORTED]
Change type: docs
Classification: MODERATE
Files changed:
<absolute path of _readiness.md>
Notable additions/removals: _readiness.md (over)written with the Phase 4 verdict
Readiness verdict: [SUPPORTED | PARTIAL | NOT-SUPPORTED]
```

Then spawn all four maintenance agents in a **single Agent message**. They are independent and run
concurrently.

**Agent 1 — Documentation** (general-purpose):
> "Post-run documentation review. Change summary:
> [paste change summary block]
>
> The project root is the specs repo (`$SPECS_PATH`). Look only for internal documentation files that
> reference readiness gates or the `dev-workflows/` per-VI artifact area (e.g. a
> `dev-workflows/README.md` index).
> Determine if any such file needs updating.
> Skip if: no such file exists or readiness runs aren't indexed centrally.
> If an update is warranted: apply minimal edits.
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose):
> "Post-run knowledge review. Change summary:
> [paste change summary block]
>
> Check ~/.claude/memory/ (global) and .claude/memory/ (project-level) for existing knowledge files.
> Determine if a new knowledge entry is warranted — look for: recurring readiness-gate gaps for this
> VI-family, non-obvious status/artifact mismatches uncovered, repo-availability surprises.
> If YES: append to the most appropriate existing file (never create a new file if an existing one fits)
> using this format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the Jira key + VI summary]
> Return: file updated/created and summary of entry, OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-run instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any readiness-gate rules, guidance, or guardrails are missing because of what this run
> revealed.
> Skip if: the run followed existing conventions with no surprises.
> If YES: apply minimal, additive, scoped changes only.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance):
> "Analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /ready
> - What was done: [one-paragraph summary of the readiness check performed]
> - Key events: [status mismatches found, missing repos, non-main/dirty specs checkout override, or
>   'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: [SUPPORTED | PARTIAL | NOT-SUPPORTED]
> - Test result: N/A (no tests in /ready — read-only artifact gate)
> - Project root: [resolved project_root]"

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`) returns, project its
plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its `emit-auto` entry point (§6).
Pass Agent 4's Lessons Learned report, `command: /ready`, the run's `jira_key` and `source`, and
`plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders
only the report's **Command workflow improvements**, **New agents / skills**, and plugin **Reference
docs** sections plus the **Key observations** that triggered them (§4 plugin-facing predicate) — never
target-project `CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id` (§3), resolves
the target via the §2 specs-first ladder, and writes silently.

Emit this phase's own short output:

```
### Post-run maintenance (Phase 6)
- Documentation (Agent 1): [result]
- Knowledge base (Agent 2): [result]
- Instructions (Agent 3): [result]
- Session learnings (Agent 4): [top suggestions, or "no suggestions — routine session"]
- Feedback persisted: [path, or "no plugin-facing signal — nothing persisted"]
```

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into `jira-products/`,
`jira_export_root`, or the current working directory.

---

## Phase 7 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 5 report is composed; NEVER interrupts an earlier phase. Persist
the run's manual-step / out-of-scope follow-ups by citing
`${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` and executing its steps inline.

1. **Collect** the qualifying follow-ups: the **named readiness gaps** from Phase 4's Findings that a
   `PARTIAL` / `NOT-SUPPORTED` verdict surfaced (each gap → one follow-up: "resolve <gap>, see
   `_readiness.md`"), plus a standing **"update the Jira status to match the artifacts (or vice versa)"**
   reminder whenever the verdict is not a clean `SUPPORTED` at the declared status.
2. **Filter** them with the reference's §6 qualifying predicate — a `SUPPORTED` run with no gaps
   qualifies **nothing**; this phase is then a silent no-op (byte-identical to a run without it).
3. **Resolve** the write target via the §4 ladder using `jira_key` and `source`; render + place tasks
   and verbose notes per §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

Emit this phase's own short output:

```
### Follow-up tasks (Phase 7)
[N follow-ups written to <target>, OR "none — verdict SUPPORTED with a clean coverage roll-up"]
```

ADDITIVE — the follow-ups also remain in the Phase 5 report's Findings/coverage sections. This phase
NEVER fails the run, NEVER commits, and NEVER writes into `jira-products/`, `jira_export_root`, or the
current working directory.

---

## Phase 8 — Session cost

Terminal phase — runs after Phase 7 and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and
calling its single `emit-cost` entry point. **Cost ALWAYS runs** — it never "writes nothing".

Call `emit-cost` with `command: /ready`, `phase: readiness`, `role: team`, the run's `jira_key` (or
`null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session transcript + subagents
(§1), loads and **advances the chained checkpoint** (§3), runs `scripts/session-cost.py` to compute the
per-model token-cost delta against the price table (§4), records the optional statusline cross-check
(§5), and appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via the
specs-first ladder (§8) — pending + opportunistic move-then-delete reconciliation (§9) when no VI key
resolves. **The checkpoint advances even in the pending / report-only tiers.**

Emit this phase's own short output:

```
### Session cost (Phase 8)
[persisted path, OR the report-only / pending notice]
```

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into `jira-products/`,
`jira_export_root`, or the current working directory; no user name is ever written (§10 privacy).

---

## Invariants (always enforced)

- NEVER set or write Jira status — status is read-only input (Phase 2), never output
- NEVER write inside `jira-products/` or the vault
- NEVER branch — this command never creates a git branch
- NEVER auto-commit `_readiness.md` (git is the user's responsibility)
- doc-only — repo check is presence-only, no scanning (Phase 3c; never dispatches `code-scanner`)
- ALWAYS end with a `### Next step` per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — guidance only, never
  auto-invoked
- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a
  **plugin / skill / command / reference gap** — a `readiness-reviewer` run that cannot get a verdict
  because the plugin lacked something it needed still records it. NEVER for the reviewer's own
  `PARTIAL`/`NOT-SUPPORTED` verdict (a finding about the *work*, not the plugin) or an environment/user
  halt (specs-repo dirty/non-main, jira-not-found, cancellation)
- the `emit-cost` phase (Phase 8) **ALWAYS runs** — unlike feedback, it never "writes nothing"
- ALWAYS resolve input via the shared Jira-input front-end (Phase 0) and reject `mode: direct`
- ALWAYS require `$SPECS_PATH` — stop naming it explicitly if unset (like `/design`)
- ALWAYS read artifacts from the specs repo's clean **main** — never a branch
- ALWAYS pass the Phase 2 declared status to `readiness-reviewer` exactly as read — never inferred,
  never re-derived
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin `jira-reader` to the §2.1 Sonnet chain;
  `readiness-reviewer` keeps its frontmatter Opus pin (no override); coordination + the Phase 3
  deterministic skeleton run on `current_model`
- ALWAYS invoke `readiness-reviewer` before Phase 5 — no verdict is written or reported without it
- ALWAYS pass `Change type: docs` in the Phase 6 change summary block
- ALWAYS pass `Command run: /ready` in the Phase 6 Agent 4 session handoff
- ALWAYS spawn Phase 6's four maintenance agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ARD steps (Phase 2.5, the reviewer's `applicable_ard`, the report's ARD-conformance section) are
  ADDITIVE and guarded on `status: found` — a run with no ARD is byte-identical to before
- ALL written claims trace to Jira keys (from `jira-reader`) or artifact paths actually read; never
  invent content the sources don't contain
- ALWAYS end with a `### Context hygiene` block per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (`resume.md`, verdict as carry-forward), then a same-role `/compact` suggestion + `/rename <VI-ID>-<slug>-team`; guidance only, never auto-run.

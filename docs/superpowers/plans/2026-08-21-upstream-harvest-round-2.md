# Upstream harvest round 2 — verify what you assert — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended)
> or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`)
> syntax for tracking.

**Goal:** Close the "an agent asserted something it had not verified, and the next station believed it"
failure mode at three stations in the dev-workflows pipeline, plus the instruction files where
unverified claims accumulate — in all three marketplace editions.

**Architecture:** Additive, backward-compatible edits to 12 agents, 5 commands, and 3 references; two
new reference files. No new agents, no new phases beyond one triage step, no new infrastructure. Every
new behaviour is conditional or degrades to today's behaviour when its trigger is absent.

**Tech Stack:** Markdown agent/command/reference files; Claude Code plugin manifests
(`.claude-plugin/*.json`); GitHub Copilot plugin manifests (`.plugin/*.json`, `skills/*/SKILL.md`).
No compiled code, no test framework — verification is read-back, derived greps, and manifest
validators.

**Spec:** `docs/superpowers/specs/2026-08-21-upstream-harvest-round-2-design.md` — read it before
Task 1. The plan argues from the spec; where they disagree, the spec governs and the mismatch is a
finding to report, not to silently resolve.

## Global Constraints

- **Pushes are HELD.** Produce commits only. Never `git push` in any of the three repos without the
  user's explicit go-ahead, and flag the mgd PR-bypass before any push there.
- **Commit trailer**, every commit: `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- **Branch** `iv-gu/upstream-harvest-round-2` in all three repos, off `main`, before any edit.
- **Versions:** canonical + mgd `2.53.2 → 2.54.0`; Copilot `2.23.2 → 2.24.0`. Minor, not patch.
- **Never edit** `references/specification-format.md` — frozen snapshot from `mgd-specifications`.
- **Plugin `description` blurbs do not grow.** 1024-char hard budget enforced by
  `scripts/validate-catalog.py`; this round is behavioural, so the blurbs should not change at all, and
  must never be appended to.
- **Never `cp` into the Copilot edition.** Apply every edit surgically to Copilot's own file. Four
  dialect rules: `task(agent_type:)` not `Agent(subagent_type:)`; absolute
  `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<file>.md` not
  `${CLAUDE_PLUGIN_ROOT}`; colon-form command names (`implement:`, not `/implement`); lowercase
  `tools: [view, glob, grep, bash]`. Copilot also says "strong tier" where the Claude editions say
  "Opus".
- **Never `cp` a repo-root `CLAUDE.md`** between editions — it carries edition-specific paths.
- **Every count is re-derived, never copied.** Where a step gives an expected number, it gives the
  command that produces it. Run the command against the tree in front of you; if it disagrees with this
  plan, **the plan is wrong** — report the mismatch rather than editing to match it. (Implementers who
  flagged such a mismatch have been right every time this has come up.)
- **Prose is hard-wrapped** in this repo's plan/spec/reference docs at ~100 columns, matching
  surrounding files. `references/prose-formatting.md`'s never-hard-wrap rule governs artifacts the
  *plugin authors* at runtime, not these files.
- **The verification record (Task 11, Step 4) is written last**, after the final fix wave — never
  before, and it records what each command actually printed, never an expected value copied from here.
- **Bugs-first: no deferred minors survive this round.** Every defect found during execution —
  including ones graded Minor, ones that are pre-existing, and ones found in this plan itself — is
  fixed before the round is considered done and before any work begins on the next iteration
  (harvest items 5–7). "We'll get it next round" is how the 2.39.2 `/implement` fix failed to reach
  its 2.39.3 siblings and shipped as a defect in two editions. A defect may be closed as *deliberately
  not fixed* only with a written reason; it may never simply be carried forward.
- **Never let a grepped phrase be split across a line break.** This plan's own 100-column wrapping
  broke a bolded phrase inside a Task 1 insert block, and the plan's own verification grep for that
  phrase would have returned one short. When transcribing an insert block, reflow so any phrase a
  later grep depends on stays on one line — words unchanged. When a count comes in one short, check
  for a split phrase **before** concluding an edit is missing.

## Plan-level decision refining spec §4.3

The spec says item 2 adds "a new orchestrator phase" but does not say where the phase's rule text
lives. Duplicating it into five commands would violate the repo's single-source-of-truth convention and
create five copies to drift. **Decision: a new `references/finding-triage.md`**, cited by all five
commands. This is a refinement, not a contradiction — if a reviewer disagrees, the spec is silent and
this is the plan's call to defend.

## File Structure

**New files (canonical paths; per-edition equivalents in Tasks 9–10):**
- `plugins/dev-workflows/references/finding-triage.md` — the triage rule, cited by 5 commands
- `plugins/dev-workflows/references/instruction-file-maintenance.md` — item 4's five rules

**Modified — references:**
- `references/context-management.md` — read-failure contract (item 1)

**Modified — agents (12):**
- `code-review`, `review-fixer`, `risk-planner`, `test-writer`, `vuln-fixer`, `upgrade-executor` — item 1
- `code-review`, `doc-reviewer`, `epic-reviewer` — item 3
- `review-fixer`, `doc-fixer` — item 2
- `impl-maintenance` — item 4

**Modified — commands (5):** `implement`, `vuln`, `upgrade`, `document`, `epics` — items 2 + 3 wiring

**Modified — docs:** `plugins/dev-workflows/README.md`, `CLAUDE.md`, `CHANGELOG.md`,
`.claude-plugin/{plugin,marketplace}.json`, `docs/superpowers/harvest/NEXT.md`

---

# Wave 1 — items 1 → 3 → 2

## Task 1: Item 1 — the read-failure contract

**Files:**
- Modify: `plugins/dev-workflows/references/context-management.md` (after `:17`)
- Modify: `plugins/dev-workflows/agents/code-review.md` (`## Inputs`, near `:29`)
- Modify: `plugins/dev-workflows/agents/review-fixer.md` (`## Inputs`, near `:21`)
- Modify: `plugins/dev-workflows/agents/risk-planner.md` (`## Inputs`, near `:24`)
- Modify: `plugins/dev-workflows/agents/test-writer.md` (`## Inputs`, near `:17`)
- Modify: `plugins/dev-workflows/agents/vuln-fixer.md` (near `:22`)
- Modify: `plugins/dev-workflows/agents/upgrade-executor.md` (near `:21`)

**Interfaces:**
- Produces: a named contract, **"the read-failure contract"**, in `context-management.md`, with two
  tiers named **evidence** and **context**. Tasks 2–5 and every later task refer to it by that name.
- Produces: the citation string
  `${CLAUDE_PLUGIN_ROOT}/references/context-management.md` (read-failure contract) — used verbatim by
  six agents.

- [ ] **Step 1: Create the branch.**

```bash
cd /workspace/ihudak-claude-plugins
git switch main && git pull --ff-only
git switch -c iv-gu/upstream-harvest-round-2
```

If the branch already exists (this plan's spec commits live on it), `git switch iv-gu/upstream-harvest-round-2` instead and confirm `git status` is clean.

- [ ] **Step 2: Record the baseline grep counts.**

Run and write the three numbers down — later steps assert deltas against them, not against absolutes:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -rc "read-failure contract" references/ agents/ | grep -v ':0' | wc -l   # baseline A (expect 0)
grep -rl "context-management" agents/ | wc -l                                  # baseline B (expect 0)
```

If baseline A is not 0, the contract already exists — STOP and report; this task has already run.

- [ ] **Step 3: Add the contract to `references/context-management.md`.**

Insert immediately after the "Hand off by file, not paste" bullet (which ends at `:17` with the
`git add -N . && git diff` sentence) and before the "Prefer the cheapest strategy" paragraph:

```markdown

## The read-failure contract

A handed-over path is only useful if it can be read. Every agent that accepts an input "inline or as an
absolute file path" MUST state what happens when that read fails, and every such failure resolves into
exactly one of two tiers.

**Evidence inputs** — the artifact the agent's judgement rests on (a diff, a review report, a research
report, an upgrade plan). An unreadable evidence path is a **hard stop**: return the agent's structured
gap/blocked shape, naming the path that could not be read. **Never regenerate the artifact by any other
means** — not by re-running `git diff`, not by re-running a test suite, not by reconstructing it from
memory. Evidence you could not read is not evidence that does not exist, and regenerating what you
failed to read is not verification: it silently substitutes a different artifact (a diff at the wrong
base, a suite at the wrong commit) and then reports success over it.

**Context inputs** — optional grounding that sharpens the work but is not the work (a plan, an ARD
invariant set, a spec-scope block). An unreadable context path **degrades to absent**: proceed exactly
as if the input had not been passed — any dimension or section conditional on it stands down as it
already does — and **record the degradation in the output** so the skip is attributed rather than
silent. This matches `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3.4 (an absent optional input
falls back to pre-existing behaviour, never becomes a new prerequisite) and
`${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` (no skip goes unattributed).

Which tier an input belongs to is fixed by the consuming agent and stated in its `## Inputs`, never
decided at runtime.
```

- [ ] **Step 4: Add the citation to `agents/code-review.md`.**

In `## Inputs`, replace the sentence at `:29–30`:

```markdown
  Both **Plan** and **Diff** may be given inline or as an absolute file
  path — `Read` the file first when given a path.
```

with:

```markdown
  Both **Plan** and **Diff** may be given inline or as an absolute file
  path — `Read` the file first when given a path. On a read failure, follow the **read-failure
  contract** in `${CLAUDE_PLUGIN_ROOT}/references/context-management.md`: **Diff** is an *evidence*
  input (hard stop — return the gap naming the path; never re-derive the diff yourself), **Plan**,
  `applicable_ard`, and `applicable_spec` are *context* inputs (degrade to absent, and say so in the
  Summary).
```

- [ ] **Step 5: Add the citation to `agents/review-fixer.md`.**

In `## Inputs`, after the existing "Provided inline or as an absolute file path — `Read` the file first
when given a path." sentence at `:21–22`, append to the same bullet:

```markdown
  On a read failure, follow the **read-failure contract** in
  `${CLAUDE_PLUGIN_ROOT}/references/context-management.md`: the review output is an *evidence* input —
  hard stop, return `Stop condition flag: NEEDS HUMAN` with the unreadable path named, and never
  reconstruct the findings from the diff.
```

- [ ] **Step 6: Add the citation to `agents/risk-planner.md`.**

In `## Inputs`, append to the bullet ending "…`Read` the file first when given a path." at `:24`:

```markdown
  On a read failure, follow the **read-failure contract** in
  `${CLAUDE_PLUGIN_ROOT}/references/context-management.md` — this input is *context*: degrade to absent,
  plan from what remains, and name the unreadable path in the plan's `### Risks`.
```

- [ ] **Step 7: Add the citation to `agents/test-writer.md`.**

In `## Inputs`, append to the **Diff** bullet at `:17`:

```markdown
  On a read failure, follow the **read-failure contract** in
  `${CLAUDE_PLUGIN_ROOT}/references/context-management.md` — **Diff** is *evidence*: hard stop, return
  the "not detected"-style truncated shape with `Diff: unreadable at <path>` as the reason, and **never
  re-derive the diff** with a tool of your own. **Plan** is *context*: degrade to absent.
```

- [ ] **Step 8: Add the citation to `agents/vuln-fixer.md`.**

After the sentence at `:22` ("The report may be provided inline or as an absolute file path — `Read`
the file first when given a path."), append:

```markdown
On a read failure, follow the **read-failure contract** in
`${CLAUDE_PLUGIN_ROOT}/references/context-management.md` — the research report is an *evidence* input:
hard stop, return `status: BLOCKED` naming the unreadable path, and never re-research the CVE to
reconstruct it.
```

- [ ] **Step 9: Add the citation to `agents/upgrade-executor.md`.**

After the sentence at `:21` ("The plan may be provided inline or as an absolute file path — `Read` the
file first when given a path."), append:

```markdown
On a read failure, follow the **read-failure contract** in
`${CLAUDE_PLUGIN_ROOT}/references/context-management.md` — the upgrade plan is an *evidence* input:
hard stop, return `status: BLOCKED` naming the unreadable path, and never re-plan the upgrade to
reconstruct it.
```

- [ ] **Step 10: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# The contract exists exactly once as a heading:
grep -c "^## The read-failure contract" references/context-management.md            # expect 1
# All six agents cite it:
grep -l "read-failure contract" agents/*.md | wc -l                                 # expect 6
# and they are the right six:
grep -l "read-failure contract" agents/*.md | sort
# expect exactly: code-review, review-fixer, risk-planner, test-writer, upgrade-executor, vuln-fixer
# No agent cites a section that does not exist:
grep -rho "context-management.md[^)\`]*" agents/ | sort -u
```

Then re-read all seven modified files end to end and confirm each edit sits in the right section and
the surrounding prose still flows.

- [ ] **Step 11: Validate and commit.**

```bash
cd /workspace/ihudak-claude-plugins
claude plugin validate .
./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root .
git add plugins/dev-workflows/references/context-management.md plugins/dev-workflows/agents/
git commit -m "$(cat <<'EOF'
feat(dev-workflows): read-failure contract for handed-over file paths

Waves M/S gave six agents mktemp path inputs and told each to Read the file,
but none said what happens when that read fails. The dangerous failure is
silent: code-review re-deriving its own git diff at whatever base HEAD happens
to be, or test-writer proceeding with no diff, then reporting success.

Two tiers, per phase-handoff.md §3.4 — evidence inputs hard-stop and are never
regenerated; context inputs degrade to absent and say so.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 12: CHECKPOINT — stop and report.**

Per spec §9.1, do not continue into Task 2 without a review of Task 1. Report: the six citation sites,
the grep output from Step 10, and any place where an agent's existing gap/blocked shape did not
naturally accommodate the contract.

---

## Task 1b: Clear Task 1's deferred minors (bugs-first)

Both were found by Task 1's review cycle and logged rather than fixed. Under the bugs-first constraint
they are cleared inside this round, not carried forward. Neither is cosmetic: the first is a partial
dead gate of exactly the class Task 1 closed.

**Files:**
- Modify: `plugins/dev-workflows/commands/vuln.md` (Step 4 resume, `:163`; regression resume, `:166`)
- Modify: `plugins/dev-workflows/commands/upgrade.md` (Phase 2 step 5, `:153`; step 6, `:155`)
- Modify: `plugins/dev-workflows/commands/implement.md` (`:472`)

- [ ] **Step 1: `BLOCKED` on the resume paths.**

`vuln.md:163` re-invokes `vuln-fixer` with `phase: verify-resume` and "the original research report
re-supplied from `research_file`"; `:166` does the same with `phase: regression-resume`.
`upgrade.md:153` and `:155` re-invoke `upgrade-executor` with `plan_file`. All four re-supply a file
path, so all four can hit the same read failure Task 1 handled at the initial invocation — and the
agent side is phase-independent, so it *will* return `status: BLOCKED` there. Only the command lacks a
branch, which is the dead-gate shape: a status returned and never consumed.

Add to each of the four sites, matching the file's surrounding sentence style:

```markdown
   If the resumed agent returns `status: BLOCKED`, the re-supplied file path could not be read: report
   the named path to the user and stop this CVE / component. Do NOT retry, and do NOT reconstruct the
   artifact — a resume that re-derives its own input is the failure `references/context-management.md`'s
   read-failure contract exists to prevent.
```

Adjust "this CVE" / "this component" per file.

- [ ] **Step 2: `implement.md:472` — state the NEEDS HUMAN branch at the call site.**

The line reads "If `Stop condition flag` is `CLEAR`, re-run the Opus code review…" and never says what
happens when it is `NEEDS HUMAN`. The behaviour is correct today only because `review-fixer.md`'s own
hard rule says the caller must surface and stop — the call site itself is silent, so a reader of
`implement.md` alone would not know. Task 1 made this reachable on a new path (an unreadable diff
produces a BLOCK whose finding is not locally actionable, so `review-fixer` returns NEEDS HUMAN on the
first pass), which turns a latent gap into a live one.

Extend that sentence with:

```markdown
If `Stop condition flag` is `NEEDS HUMAN`, do not re-review: surface the deferred BLOCKER(s) to the
user with the reason `review-fixer` gave and stop.

**Do not cite `escalation-rules.md` here.** An earlier draft of this plan did; that file contains zero
`review-fixer` mentions and its "Review verdict BLOCK" rules cover `/document` and `/epics` only, not
`/implement`. The governing rule is `review-fixer.md`'s own hard rules. Cite nothing rather than a
reference that does not carry the rule.
```

- [ ] **Step 3: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# Grep for the BARE word, not a guessed code-span shape. An earlier draft of this plan matched
# `status: \`BLOCKED\`` — a backtick immediately after "status:" — but the house style these files
# actually use wraps the whole phrase (\`status: BLOCKED\`), so the pattern never matched and the
# check reported a false shortfall. A verification pattern written against an imagined file reports
# on the imagined file.
grep -c "BLOCKED" commands/vuln.md      # every initial AND resume site; derive, do not assume a total
grep -c "BLOCKED" commands/upgrade.md
grep -n "phase: verify-resume\|phase: regression-resume" commands/vuln.md commands/upgrade.md
# ^ Branch EVERY resume call site this prints. Do not trust a count in this plan: an earlier draft
#   said vuln.md had two and it has three (the SIMPLE/MODERATE path carries its own regression-resume).
grep -n "NEEDS HUMAN" commands/implement.md                        # expect >= 1
cd /workspace/ihudak-claude-plugins && claude plugin validate .
```

Then read each of the five edit sites in context and confirm the new sentence sits inside the right
step, not between two unrelated ones.

- [ ] **Step 4: Commit.**

```bash
git add plugins/dev-workflows/commands/
git commit -m "$(cat <<'EOF'
fix(dev-workflows): consume BLOCKED on the resume paths, state NEEDS HUMAN at the call site

Both found by Task 1's review and logged rather than fixed; cleared here under
the bugs-first rule. The resume paths re-supply a file path and so can hit the
same read failure the initial invocation now handles — the agent returns
BLOCKED regardless of phase, but no command branched on it, which is a status
returned and never consumed.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Item 3 — `claims_file` and the falsification dimension

**Files:**
- Modify: `plugins/dev-workflows/agents/code-review.md` (`## Inputs`; `## Review method` `:43–44`, `:49`;
  `## Review dimensions` after dimension 10; `## Output` after the Spec/design conformance slot)
- Modify: `plugins/dev-workflows/agents/doc-reviewer.md` (`## Inputs`; `## Review dimensions`; `## Output`)
- Modify: `plugins/dev-workflows/agents/epic-reviewer.md` (`## Inputs`; `## Review dimensions` table;
  `## Output`)

**Interfaces:**
- Produces: input name **`claims_file`** (absolute path, optional) on all three reviewers. Task 3 passes
  it.
- Produces: dimension name **"Claims falsification"** and output slot heading
  `#### Claims falsification (only if claims_file provided)` on all three reviewers.

- [ ] **Step 1: Re-derive the dimension counts. Do not trust the numbers below.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
sed -n '/^## Review dimensions/,/^## /p' agents/code-review.md | grep -cE "^[0-9]+\. \*\*"   # expect 10
grep -cE "^#### " agents/doc-reviewer.md                                                      # expect 17
grep -cE "^#### " agents/epic-reviewer.md                                                     # expect 18
sed -n '/^## Review dimensions/,/^## /p' agents/epic-reviewer.md | grep -cE "^\| [A-Z]"       # expect 19 (18 + header)
```

If any number differs, STOP and report — the plan's expectations are stale and every count below is
suspect.

- [ ] **Step 2: `code-review` — register `claims_file`.**

In `## Inputs`, immediately after the `applicable_spec` bullet, add:

```markdown
- **`claims_file`** (optional) — an absolute path to the change's own **narrative**: an agent's account
  of what it changed (a `review-fixer` Fix Report at re-review, a `vuln-fixer` or `upgrade-executor`
  report at first review). **DO NOT read this file when you read the brief.** It is read once, in the
  Claims falsification dimension, after every other dimension is complete — see `## Review method` step
  3. Absent ⇒ the Claims falsification dimension does not apply and is not mentioned. This input is
  *evidence* under the read-failure contract only in the sense that it must not be reconstructed: if it
  cannot be read, record `Claims falsification: NOT RUN — claims_file unreadable at <path>` in the
  Summary and continue; never substitute the brief's own text for it.
```

- [ ] **Step 3: `code-review` — update the two count phrases in `## Review method`.**

Replace `:43–45`:

```markdown
3. Check each of the eight dimensions below (plus the conditional ninth and
   tenth — dimension 9 only when `applicable_ard` is provided, dimension 10
   only when `applicable_spec` is provided). Skip dimensions that are clearly
```

with:

```markdown
3. Check each of the eight dimensions below (plus the conditional ninth, tenth,
   and eleventh — dimension 9 only when `applicable_ard` is provided, dimension
   10 only when `applicable_spec` is provided, dimension 11 only when
   `claims_file` is provided). Dimension 11 runs **last, after dimensions 1–10
   are complete and their findings recorded** — that ordering is not a
   preference, it is what makes the dimension work. Skip dimensions that are clearly
```

Replace `:49`'s `- **Dimension** - one of the ten below` with
`- **Dimension** - one of the eleven below`.

- [ ] **Step 4: `code-review` — add dimension 11.**

After dimension 10's `- `partial` → `MINOR`.` line and before `## Output`, add:

```markdown
11. **Claims falsification** (conditional — only when `claims_file` is provided;
    otherwise this dimension does not apply — omit it silently). **Precondition:
    dimensions 1–10 are complete and their findings recorded.** Only now, for the
    first time, `Read` the file at `claims_file`.

    The file holds an agent's account of its own work. That account is
    **testimony, not evidence** — a claim restated in a code comment or a commit
    message is the same claim, not confirmation of it. Extract each *checkable*
    claim — what the change does, what it preserves, ordering, arithmetic, and
    parity claims ("exactly as X does", "same shape as Y") — and try to
    **falsify** each one against the code you have already traced. Where your
    trace does not settle it, read the code that does: the compared-to function,
    the actual callee, the state the claim assumes.

    Report one finding per **falsified** claim: `location` = where the code
    contradicts the claim; `observation` = the claim, quoted or tightly
    paraphrased, against what the code actually does; `suggestion` = the
    correction. Severity by consequence for someone who believed the claim — a
    false claim that something was fixed is a `BLOCKER`.

    **Verified claims produce nothing.** Add nothing when nothing is falsified.
```

- [ ] **Step 5: `code-review` — add the output slot.**

In `## Output`, after the `#### Spec/design conformance (only if applicable_spec provided)` block
(ending `- _or_ "no findings — all in-scope requirements satisfied"`) and before
`### Recommended next step`, add:

```markdown
#### Claims falsification (only if claims_file provided)
- [severity] `path:line` - claim: "[the claim]" - actually: [what the code does]
  Suggestion: [correction]
- _or_ "no findings — every checkable claim verified"
```

- [ ] **Step 6: `doc-reviewer` — register `claims_file`.**

In `## Inputs`, as a new final bullet, add the same text as Step 2 but with the sources changed:

```markdown
- **`claims_file`** (optional) — an absolute path to a `doc-fixer` Fix Report from this run's fix cycle:
  the fixer's account of what it changed. **DO NOT read this file when you read the brief.** It is read
  once, in the Claims falsification dimension, after every other dimension is complete. Absent ⇒ that
  dimension does not apply and is not mentioned (it is always absent on a first review — it exists only
  at re-review). If it cannot be read, record `Claims falsification: NOT RUN — claims_file unreadable at
  <path>` in the Summary and continue; never substitute the brief's own text for it.
```

- [ ] **Step 7: `doc-reviewer` — add the dimension and the output slot.**

In `## Review dimensions`, append as the final (18th) dimension. **That section is a
`| Dimension | Check |` table, not prose** (an earlier draft of this plan said prose — it was wrong,
derived from the output-slot count rather than from the section itself). Append a table row matching
the existing rows' two-column shape, with this text as the `Check` cell:

```markdown
**Claims falsification** (conditional — only when `claims_file` is provided; otherwise omit silently).
**Precondition: every other dimension is complete and its findings recorded.** Only now `Read` the file
at `claims_file`. It holds the fixer's account of what it changed — testimony, not evidence. Extract
each checkable claim ("applied X at `path:line`", "preserved the frontmatter", "swapped every
occurrence") and try to **falsify** it against the written files you have already reviewed. Report one
finding per falsified claim, severity by consequence for a reader who believed it — a fix reported as
applied but absent from the file is a `BLOCKER`. Verified claims produce nothing.
```

In `## Output`, after the final existing `#### ` slot and before whatever section follows it, add:

```markdown
#### Claims falsification (only if claims_file provided)
- [severity] `path:line` — claim: "[the claim]" — actually: [what the file contains]
  Suggestion: [correction]
- _or_ "no findings — every checkable claim verified"
```

- [ ] **Step 8: `epic-reviewer` — register `claims_file`, add the dimension row and the output slot.**

`## Inputs`: add the same bullet as Step 6, with "a `doc-fixer` Fix Report from this run's fix cycle"
unchanged (the same agent fixes Epic drafts).

`## Review dimensions` table: append a final row, matching the table's two-column `| Dimension | Check |`
shape:

```markdown
| Claims falsification | Conditional — only when `claims_file` is provided; otherwise omit silently. **Precondition: every other dimension is complete and its findings recorded.** Only now `Read` the file at `claims_file` — the fixer's account of what it changed, which is testimony, not evidence. Extract each checkable claim and try to **falsify** it against the drafts you have already reviewed. One finding per falsified claim; a fix reported as applied but absent from the draft is a `BLOCKER`. Verified claims produce nothing. |
```

`## Output`: add the same `#### Claims falsification (only if claims_file provided)` slot as Step 7,
with "[what the draft contains]" in place of "[what the file contains]".

- [ ] **Step 9: Update the README agent table — ours and the pre-existing drift (spec §10.3).**

In `plugins/dev-workflows/README.md`, make exactly three row edits:

- `code-review` row: `Post-implementation reviewer — 8 dimensions (correctness, security, architecture, edge cases, migration, dependencies, test adequacy, rollback).`
  → `Post-implementation reviewer — 11 dimensions: eight always (correctness, security, architecture, edge cases, migration, dependencies, test adequacy, rollback) plus three conditional (ARD conformance, spec/design conformance, claims falsification).`
- `doc-reviewer` row: `17 dimensions` → `18 dimensions`, and append `, and claims falsification (the fixer's account of its own work, read only after every other dimension)` to that row's dimension list.
- `epic-reviewer` row: `9 dimensions` → **`19 dimensions`**, and append the same claims-falsification
  mention the other two rows get. **This row was stale by nine before this round** (it never absorbed
  the refinement/partition/ARD dimensions), so there are TWO corrections stacked here: 9 → 18 fixes the
  pre-existing staleness, and 18 → 19 adds the dimension THIS task creates. An earlier draft of this
  plan said "→ 18" — it applied only the first correction and dropped the second. Do not copy either
  number: derive it with `grep -cE "^#### " agents/epic-reviewer.md` AFTER your edit.

- [ ] **Step 10: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# Counts moved by exactly one each:
sed -n '/^## Review dimensions/,/^## /p' agents/code-review.md | grep -cE "^[0-9]+\. \*\*"   # expect 11
grep -cE "^#### " agents/doc-reviewer.md                                                      # expect 18
grep -cE "^#### " agents/epic-reviewer.md                                                     # expect 19
# All three reviewers register the input and the dimension:
grep -l "claims_file" agents/*.md | sort                    # expect exactly the 3 reviewers
grep -c "Claims falsification" agents/code-review.md        # expect >= 3 (method, dimension, output)
# The deferral instruction is present in all three, not just declared:
grep -c "DO NOT read this file when you read the brief" agents/*.md | grep -v ':0'   # expect 3 lines
# No stale count phrase survives in code-review:
grep -nE "one of the ten below|conditional ninth and" agents/code-review.md          # expect no output
# README rows match the derived counts — ALL THREE, not just one. An earlier draft of this plan
# checked only the code-review row, which is why a wrong epic-reviewer count reached review.
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for a in code-review doc-reviewer epic-reviewer; do
  case $a in
    code-review) n=$(sed -n '/^## Review dimensions/,/^## /p' agents/$a.md | grep -cE '^[0-9]+\. \*\*');;
    *)           n=$(grep -cE '^#### ' agents/$a.md);;
  esac
  printf '%-14s agent=%s  README says: ' "$a" "$n"
  grep -oE "\`$a\` \| Opus \| [^|]*dimensions" README.md | grep -oE '[0-9]+ dimensions'
done
# The two numbers on each line MUST match.
```

- [ ] **Step 11: Validate and commit.**

```bash
cd /workspace/ihudak-claude-plugins
claude plugin validate .
git add plugins/dev-workflows/agents/ plugins/dev-workflows/README.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): claims falsification as a deferred read on the three reviewers

An agent's account of its own work is testimony, not evidence. code-review,
doc-reviewer, and epic-reviewer gain an optional claims_file they are told not
to read until every other dimension is complete — the anti-anchoring property
bought structurally with the wave-M/S file handoff, rather than by an
instruction sitting above content already in context.

Also corrects two pre-existing README counts the rows being edited carried:
code-review said 8 dimensions (was already 10), epic-reviewer said 9 (was
already 18).

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Item 3 — wire `claims_file` in the five commands

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (re-review path, near `:472` and `:486`)
- Modify: `plugins/dev-workflows/commands/document.md` (near `:939` and the PASS-WITH-RECOMMENDATIONS
  branch near `:945`)
- Modify: `plugins/dev-workflows/commands/epics.md` (near `:442` and the branch near `:448`)
- Modify: `plugins/dev-workflows/commands/vuln.md` (`:153` dispatch)
- Modify: `plugins/dev-workflows/commands/upgrade.md` (`:147` dispatch)

**Interfaces:**
- Consumes: `claims_file` from Task 2.
- Produces: the variable name **`claims_file`** recorded per run, holding an absolute `mktemp` path.

**There are two different changes here. Do not treat them as one.**

- [ ] **Step 1: `/implement` — ADD (the Fix Report is not currently passed).**

At `:486`, the re-capture instruction currently reads: "Wait for the fix report. Re-capture the diff
after the fixer completes, **overwriting `review_diff_file`** …". Extend that sentence with:

```markdown
   Also write the fixer's full Fix Report to a temp file (`mktemp -t dw-impl-claims-XXXX.md`, never
   inside a repo tree) and record its path as `claims_file` — the one re-review reads it as the
   deferred claims input, so the reviewer checks the fixer's account of its own work instead of
   assuming it.
```

Then in the re-review dispatch (the `- **BLOCK**` branch at `:472`, "re-run the Opus code review on the
updated diff"), add to the brief that dispatch passes:

```markdown
     > claims_file: [the `claims_file` path — the re-review only; omit on the first review]
```

- [ ] **Step 2: `/document` — ADD.**

At `:939`, "Re-invoke `doc-reviewer` once." becomes:

```markdown
Write the `doc-fixer` Fix Report to a temp file (`mktemp -t dw-doc-claims-XXXX.md`, never inside a repo
tree or the vault), record its path as `claims_file`, and re-invoke `doc-reviewer` once **passing
`claims_file`** — so the re-review falsifies the fixer's account rather than assuming it.
```

Apply the identical change to the `- **PASS WITH RECOMMENDATIONS**` branch's re-review, if that branch
re-invokes the reviewer; if it does not, leave it alone and say so in the task report.

- [ ] **Step 3: `/epics` — ADD.**

At `:442`, "Re-invoke `epic-reviewer` once." takes the same treatment as Step 2, with
`mktemp -t dw-epics-claims-XXXX.md` and `epic-reviewer`.

- [ ] **Step 4: `/vuln` — RELOCATE (this is the different one).**

`:153` currently reads:

```markdown
   - Invoke `code-review` with the CVE summary, the research handoff (from `research_file`), the fixer output, and the diff (from `review_diff_file`) (frontmatter-pinned to Opus; …
```

The fixer output is being passed **into the brief**, where it is read first and anchors the reviewer.
Rewrite it as:

```markdown
   - Write the fixer output to a temp file (`mktemp -t dw-vuln-claims-XXXX.md`, never inside a repo tree)
     and record its path as `claims_file`. Invoke `code-review` with the CVE summary, the research
     handoff (from `research_file`), the diff (from `review_diff_file`), and `claims_file: [the path]`
     (frontmatter-pinned to Opus; …
```

**The fixer output must no longer appear in the brief.** Leaving it in both places defeats the deferred
read while appearing to implement it — and would pass every other check in this plan.

- [ ] **Step 5: `/upgrade` — RELOCATE.**

`:147` currently reads:

```markdown
   - Invoke `code-review` using the approved risk plan, the executor output, and the diff (from `review_diff_file`) (frontmatter-pinned to Opus; …
```

Rewrite as:

```markdown
   - Write the executor output to a temp file (`mktemp -t dw-upgrade-claims-XXXX.md`, never inside a repo
     tree) and record its path as `claims_file`. Invoke `code-review` using the approved risk plan, the
     diff (from `review_diff_file`), and `claims_file: [the path]` (frontmatter-pinned to Opus; …
```

Same rule: the executor output must not remain in the brief.

- [ ] **Step 6: Verify — including the relocation check spec §9 item 6 requires.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# All five commands wire it:
grep -l "claims_file" commands/*.md | sort   # expect exactly: document, epics, implement, upgrade, vuln
# RELOCATION completeness — the fixer/executor output must appear ONCE, as claims_file, and
# must NOT still be listed as a brief ingredient:
grep -n "the fixer output" commands/vuln.md        # expect: only inside the mktemp/claims_file sentence
grep -n "the executor output" commands/upgrade.md  # expect: only inside the mktemp/claims_file sentence
# Handoff files are never created inside a repo tree:
grep -n "mktemp -t dw-.*claims" commands/*.md      # expect 5 hits, all with -t (temp dir), none with a repo path
```

Read `:145–160` of `vuln.md` and `:140–155` of `upgrade.md` end to end and confirm the brief no longer
names the fixer/executor output as an inline ingredient.

- [ ] **Step 7: Validate and commit.**

```bash
cd /workspace/ihudak-claude-plugins
claude plugin validate .
git add plugins/dev-workflows/commands/
git commit -m "$(cat <<'EOF'
feat(dev-workflows): wire claims_file in the five reviewer-gated commands

Three adds and two relocations. /implement, /document, and /epics never passed
the Fix Report to the re-review at all. /vuln and /upgrade already passed the
fixer/executor output — but inline in the brief, read before the reviewer had
traced anything, which is active anchoring rather than a missing check. For
those two the content moves out of the brief into claims_file; leaving it in
both places would defeat the deferral while appearing to implement it.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Item 2 — the triage reference and the two fixer contracts

**Files:**
- Create: `plugins/dev-workflows/references/finding-triage.md`
- Modify: `plugins/dev-workflows/agents/review-fixer.md` (`## Inputs`, `## Fix method` step 6,
  `## Hard rules`)
- Modify: `plugins/dev-workflows/agents/doc-fixer.md` (`## Inputs`, `## Fix method` step 6,
  `## Hard rules`)

**Interfaces:**
- Produces: `references/finding-triage.md`, cited by Task 5's five commands.
- Produces: the fixer input contract **"survivors only"** — the fixer receives a triaged finding list
  and does not re-triage it.

- [ ] **Step 1: Create `references/finding-triage.md`.**

```markdown
# Finding triage (embedded — shared reference)

The step between a reviewer's findings and a fixer's edits. Run by the **orchestrator**, never by the
fixer: `review-fixer` and `doc-fixer` run on the detection/Sonnet chain while `code-review`,
`doc-reviewer`, and `epic-reviewer` are Opus-pinned, and a dismissal decision must not sit at a weaker
station than the one that produced the finding.

## When this runs

Wherever an **Opus reviewer's reasoned findings feed a fixer**:

| Path | Triage |
|---|---|
| `code-review` → `review-fixer` (`/implement`, `/vuln`, `/upgrade`) | yes |
| `doc-reviewer` → `doc-fixer` (`/document`, Jira mode) | yes |
| `epic-reviewer` → `doc-fixer` (`/epics`) | yes |
| a style checker → `doc-fixer` (`/document` direct mode, `/release-notes`, and the style-fix cycle inside `/document` Jira mode) | **no** |

The seam is **reasoned-claim producer vs deterministic producer**, not code vs docs. A reviewer finding
is a claim about consequence and can be checked against the thing it names. A linter violation is not —
a rule matched or it did not, and there is nothing to trace. `/document` and `/epics` each dispatch
`doc-fixer` more than once; this step attaches to the **reviewer-fed dispatch only**.

## The step

For each finding, **before any grouping or deduplication**:

1. **Verify its own claimed consequence** at the location it names. Read past the changed lines — into
   the callers, the guards upstream, whatever else the site depends on — far enough to tell whether that
   consequence actually occurs. Another finding's outcome, however adjacent, never settles this one.
2. **Keep or dismiss.** Keep a finding only where verification confirmed its consequence. Dismiss noise,
   claims the verification refuted, and claims it could not substantiate — no path to the claimed
   consequence at the named site is a valid disposal. Whatever the reason, **it must dispose of that
   finding's own claim**: a true fact about neighbouring code that leaves the claim standing is not a
   dismissal, and the finding stays kept.
3. **Record every dismissal with its reason.** Never drop a finding silently. There is no "reject and
   say nothing" disposition and none may be added.

Only survivors are handed to the fixer.

## The patch gate

A survivor may be auto-fixed only where it shows a defect that **actually occurs**, missing coverage for
a specific case, or a broken gate or convention — **not a state nothing reaches** — and where the
smallest fix adds no public surface and **guards no state the finding did not demonstrate**. A survivor
failing any of those conditions is surfaced for a human decision instead of patched.

That last clause is the load-bearing one: a guard added for a state the finding never demonstrated is
the most common shape of a "fix" applied to a false positive, and it is invisible afterwards because it
looks like defensive coding.

## Reporting

The orchestrator's run report names, for the triage step: how many findings were reviewed, how many
survived, and **every dismissal with its reason**. A triage that reports only survivors is
indistinguishable from a reviewer that found less.
```

- [ ] **Step 2: `review-fixer` — accept survivors, drop the re-triage.**

In `## Inputs`, extend the **Review output** bullet with:

```markdown
  This list has already been triaged by the caller per
  `${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md` — every finding you receive is a **survivor** whose
  claimed consequence the caller verified. Do not re-triage, and do not dismiss a finding on your own
  judgement: your dispositions remain Applied and Deferred only.
```

In `## Fix method` step 6 ("When fixing:"), add a bullet after "Make the minimal change that addresses
the finding's suggestion.":

```markdown
   - Apply the **patch gate** (`${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md`): the fix must add no
     public surface and **guard no state the finding did not demonstrate**. If the smallest correct fix
     would add such a guard, defer it as `DEFERRED — needs human decision` with that as the reason,
     rather than adding speculative defence.
```

In `## Hard rules`, add:

```markdown
- NEVER add a guard, branch, or check for a state the finding did not demonstrate is reachable.
```

- [ ] **Step 3: `doc-fixer` — same three edits.**

`## Inputs`: extend the **Reviewer or style-checker output** bullet with:

```markdown
  When the source is `doc-reviewer` or `epic-reviewer`, this list has already been triaged by the caller
  per `${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md` — every finding is a **survivor**; do not
  re-triage and do not dismiss. When the source is a style checker, no triage step ran (a linter
  violation is not a claim about consequence) and the list is as the checker produced it.
```

`## Fix method` step 6: add the same patch-gate bullet as Step 2, with "add speculative content or
structure the finding did not demonstrate is missing" in place of the guard wording.

`## Hard rules`: add:

```markdown
- NEVER add content, a section, or a structural element the finding did not demonstrate is missing.
```

- [ ] **Step 4: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "^## " references/finding-triage.md                       # expect 4 (When this runs / The step / The patch gate / Reporting — the title is a single #)
grep -l "finding-triage" agents/*.md | sort                       # expect exactly: doc-fixer, review-fixer
grep -c "guard no state the finding did not demonstrate" references/finding-triage.md   # expect >= 1
# Neither fixer claims triage authority:
grep -niE "do not re-triage" agents/review-fixer.md agents/doc-fixer.md   # expect 1 hit each
```

- [ ] **Step 5: Validate and commit.**

```bash
cd /workspace/ihudak-claude-plugins
claude plugin validate .
git add plugins/dev-workflows/references/finding-triage.md plugins/dev-workflows/agents/
git commit -m "$(cat <<'EOF'
feat(dev-workflows): finding-triage reference and the fixer patch gate

review-fixer went from "parse all findings" straight to "fix it if locally
actionable" — nothing verified that a finding's claimed consequence occurs. The
most common fix applied to a false positive is a guard for a state nothing
reaches, which is invisible afterwards because it looks like defensive coding.

Triage sits with the orchestrator, not the fixer: the fixers run on the Sonnet
chain and the reviewers are Opus-pinned, so dismissal authority must not sit at
the weaker station.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Item 2 — the triage phase in five commands, and the mermaid diagram

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (before the Review-fixer sub-step, `:476`)
- Modify: `plugins/dev-workflows/commands/vuln.md` (before its review-fixer dispatch)
- Modify: `plugins/dev-workflows/commands/upgrade.md` (before its review-fixer dispatch)
- Modify: `plugins/dev-workflows/commands/document.md` (before the reviewer-fed `doc-fixer` dispatch at
  `:939`/`:945` — **not** the style-fix dispatch at Phase 6.4)
- Modify: `plugins/dev-workflows/commands/epics.md` (before the reviewer-fed `doc-fixer` dispatch at
  `:442`/`:448` — **not** the style-fix dispatch)
- Modify: `plugins/dev-workflows/README.md` (the `/implement` mermaid diagram, `:202`)

**Interfaces:**
- Consumes: `references/finding-triage.md` from Task 4.

- [ ] **Step 1: Insert the triage step in each of the five commands.**

Immediately before each command's **reviewer-fed** fixer dispatch, insert:

```markdown
   **Triage sub-step** (before any fixer dispatch): follow
   `${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md`. For each finding, verify its claimed consequence
   at the location it names; keep or dismiss; record every dismissal with a reason that disposes of that
   finding's own claim. Hand the fixer **survivors only**, and carry the dismissal list into this run's
   report.
```

Indent to match the surrounding list level in each file. In `/document` and `/epics` this goes before
the reviewer-verdict `doc-fixer` dispatches **only** — the Phase 6.4 / style-check `doc-fixer` dispatch
is untouched, per `finding-triage.md`'s own table.

- [ ] **Step 2: Add the dismissal list to each command's run report.**

In each of the five commands' final-report section, add a line to the report shape:

```markdown
- **Review triage:** [N findings reviewed, M survived] — dismissals: [one line per dismissal, `finding — reason`; or "none"]
```

- [ ] **Step 3: Update the `/implement` mermaid diagram (spec §10.2).**

In `plugins/dev-workflows/README.md` at `:202`, the node currently reads:

```
    G -->|Yes| RV["Opus code-review → review-fixer (gate before tests)"]
```

Replace with:

```
    G -->|Yes| RV["Opus code-review → triage (verify each finding) → review-fixer (gate before tests)"]
```

**Do NOT touch the first mermaid diagram** (the PM/PA/PE/Dev/QA pipeline overview at `:55`). It maps
command-to-command relationships and no command's inputs, outputs, or position changes in this round.
Editing it is a defect, not thoroughness.

- [ ] **Step 4: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -l "finding-triage" commands/*.md | sort   # expect exactly: document, epics, implement, upgrade, vuln
# Triage attaches once per command (the reviewer-fed dispatch only):
grep -c "Triage sub-step" commands/document.md commands/epics.md   # expect 1 each — 2 means it landed on the style dispatch too
# Diagram 2 changed, diagram 1 did not:
grep -n "triage (verify each finding)" README.md    # expect 1 hit
git diff README.md | grep -E "^[-+].*subgraph"      # expect NO output — diagram 1 untouched
```

- [ ] **Step 5: Validate and commit.**

```bash
cd /workspace/ihudak-claude-plugins
claude plugin validate .
git add plugins/dev-workflows/commands/ plugins/dev-workflows/README.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): orchestrator triage between reviewer and fixer in five commands

Attaches to the reviewer-fed fixer dispatch only. /document and /epics each
dispatch doc-fixer more than once; the style-check dispatch is deliberately
untouched, because a linter violation is not a claim about consequence.

The /implement mermaid gains the triage step. The pipeline-overview diagram is
deliberately unchanged — no command's inputs, outputs, or position moved.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Wave 2 — item 4

## Task 6: Instruction-file maintenance

**Files:**
- Create: `plugins/dev-workflows/references/instruction-file-maintenance.md`
- Modify: `plugins/dev-workflows/agents/impl-maintenance.md`
- Modify: `CLAUDE.md` (source-truth index, after the `doc-structure-conventions.md` entry at `:137`)

- [ ] **Step 1: Create the reference.**

```markdown
# Instruction-file maintenance (embedded — shared reference)

Rules for proposing or making changes to an agent-instruction file — `CLAUDE.md`, `AGENTS.md`,
`.github/copilot-instructions.md`, a rules file, or any `references/*.md` in this plugin. Consulted by
`impl-maintenance` when it proposes changes, and binding on hand edits, which is where most stale claims
originate.

## 1. Verify every command claim against the thing that runs it

For any claim about what a command, script, gate, or agent does, read the target and confirm it before
writing the claim down. A claim about `scripts/foo.sh` is verified by reading `scripts/foo.sh`, not by
reading another document that describes it. A claim that a gate blocks on X is verified by finding the
rule that blocks on X.

## 2. A rewrite that narrows a rule is a deletion

If a rewrite weakens, narrows, or drops part of an existing rule, the lost part is a **deletion** and is
itemised separately, not folded silently into the rewrite. Keep the rule itself; examples may explain a
rule but can never replace it. "I made it more concise" is how a rule's binding half disappears.

## 3. A pointer must name an observable trigger

A line that sends the reader elsewhere names a trigger the agent can **observe** — a path, a file type, a
named command, a named task. Never one it must judge ("when the task is complex", "for significant
changes") or track about itself ("before your first edit", "once you have enough context"). An
unobservable trigger is a rule that never fires.

## 4. Two live contradictory instructions is a defect

When two instructions in force at the same time disagree, that is a defect to fix, not an ambiguity for
the reader to adjudicate. Fix it at the source; do not add a third instruction explaining which of the
two wins.

## 5. Retirement needs grounds

An instruction is removed only when it is stale, wrong, already enforced by a hook or check, harmful or
contradictory, or explicitly approved for removal as a line item. **Never** because it looks derivable
from the code, and **never** because nothing has failed on it lately — a rule that stops failures is
indistinguishable from a rule nobody needed, right up until it is removed.
```

- [ ] **Step 2: Cite it from `impl-maintenance`.**

In `agents/impl-maintenance.md`, near the top of its process/instructions section, add:

```markdown
Before proposing any change to `CLAUDE.md`, a rules file, or a `references/*.md`, follow
`${CLAUDE_PLUGIN_ROOT}/references/instruction-file-maintenance.md`. In particular: verify every claim you
propose against the thing that runs it (rule 1), and itemise any narrowing of an existing rule as a
deletion rather than presenting it as a rewrite (rule 2). You are suggest-only — but a suggestion
carrying an unverified claim is how the claim gets adopted.
```

- [ ] **Step 3: Index it in `CLAUDE.md`.**

After the `doc-structure-conventions.md` paragraph at `:137`, add:

```markdown
`plugins/dev-workflows/references/instruction-file-maintenance.md` is the **single source of truth** for changes to agent-instruction files (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, rules files, and this plugin's own `references/*.md`) — verify every command claim against the thing that runs it; a rewrite that narrows a rule is a deletion and is itemised separately; a pointer names an observable trigger, never one the agent must judge; two live contradictory instructions is a defect; retirement needs grounds, never "it looks derivable" and never "nothing has failed on it lately". Consumed by `impl-maintenance`, and binding on hand edits to this file.
```

- [ ] **Step 4: Verify and commit.**

```bash
cd /workspace/ihudak-claude-plugins
grep -c "^## [1-5]\." plugins/dev-workflows/references/instruction-file-maintenance.md   # expect 5
grep -c "instruction-file-maintenance" plugins/dev-workflows/agents/impl-maintenance.md  # expect 1
grep -c "instruction-file-maintenance" CLAUDE.md                                          # expect 1
claude plugin validate .
git add plugins/dev-workflows/references/instruction-file-maintenance.md plugins/dev-workflows/agents/impl-maintenance.md CLAUDE.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): instruction-file maintenance reference

impl-maintenance proposes CLAUDE.md and reference changes after every session
and had zero rules about verifying what it proposes or protecting what is
already there. Placed in a reference rather than inside the agent because the
rules bind hand edits too — which is where the stale claims actually originate.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Wave 3 — canonical docs, port, release

## Task 7: Canonical CLAUDE.md sweep and residue audit

**Files:**
- Modify: `CLAUDE.md` (workflow map, key invariants, agent ledger)
- Modify: `docs/superpowers/harvest/NEXT.md`

- [ ] **Step 1: Update the workflow map** in `CLAUDE.md`'s "`dev-workflows` workflow relationships"
  block. Each of the five affected lines gains the triage step. For example, `/implement`'s line's
  `→ [code-review@Opus] → review-fixer →` becomes
  `→ [code-review@Opus] → [triage: verify each finding] → review-fixer →`. Apply the same to `/vuln`,
  `/upgrade`, `/document` (Jira), and `/epics`.

- [ ] **Step 2: Add the round's invariants** to the relevant "Key invariants" blocks:

```markdown
- Every agent that accepts an input as a file path states its read-failure tier (`references/context-management.md`) — an unreadable **evidence** input is a hard stop and is NEVER regenerated; an unreadable **context** input degrades to absent and says so
- A reviewer's findings are triaged before any fixer sees them (`references/finding-triage.md`) — each finding verified at the location it names, every dismissal recorded with a reason that disposes of that finding's own claim, and the fixer receives survivors only
- A reviewer handed `claims_file` reads it ONLY after every other dimension is complete — the deferral is what makes the falsification independent, and it is bought structurally (a path, read late) rather than by instruction
```

- [ ] **Step 3: Residue audit — "what did I make false?"**

This is the step spec §9 item 4 requires. For each, run the command and fix what it surfaces:

```bash
cd /workspace/ihudak-claude-plugins
# a) Does CLAUDE.md still describe review→fixer as direct anywhere?
grep -nE "code-review.*review-fixer|doc-reviewer.*doc-fixer" CLAUDE.md
# b) Does any doc still state a superseded dimension count?
grep -rnE "(8|eight|9|nine|10|ten|17|seventeen) dimensions" CLAUDE.md plugins/dev-workflows/README.md
# c) Reference count claims — CLAUDE.md and READMEs sometimes state how many references exist:
grep -rnE "reference docs|[0-9]+ references" CLAUDE.md plugins/dev-workflows/README.md
ls plugins/dev-workflows/references/*.md | wc -l   # the derived truth
# d) Agent/command count claims:
grep -rnE "[Tt]hirty-|[Tt]wenty-|reusable subagents|slash commands" CLAUDE.md plugins/dev-workflows/README.md
ls plugins/dev-workflows/agents/*.md | wc -l
ls plugins/dev-workflows/commands/*.md | wc -l
```

Fix every mismatch found. Report each one in the task report — a residue audit that finds nothing is
either a clean tree or a check that did not run, and the reviewer must be able to tell which.

- [ ] **Step 4: Update `NEXT.md`.** Replace the "NEXT: no active item" section with a record of this
  round (what shipped, versions, commits) and carry items 5–7 forward verbatim from spec §12, plus the
  two recorded divergences (superpowers reversed the plan-conflict rule; mattpocock's grilling went
  round-based).

- [ ] **Step 5: Commit.**

```bash
git add CLAUDE.md docs/superpowers/harvest/NEXT.md
git commit -m "$(cat <<'EOF'
docs(dev-workflows): CLAUDE.md workflow map, invariants, and residue audit

Also records harvest round 2 in NEXT.md and carries items 5-7 forward as named
backlog — with the reason they were deferred, so a later round does not
re-derive a wrong one.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Port to mgd-claude-plugins

- [ ] **Step 1: Branch and verify lockstep BEFORE copying.**

```bash
cd /workspace/mgd-claude-plugins
git switch main && git pull --ff-only && git switch -c iv-gu/upstream-harvest-round-2
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows plugins/dev-workflows
```

Expect **exactly five** differing files: `.claude-plugin/plugin.json`, `README.md`, `LICENSE`,
`references/dependencies.md`, `CHANGELOG.md` — these are mgd identity plus the annotated changelog.
**Anything else differing means the two editions were already out of lockstep — STOP and report before
copying.**

- [ ] **Step 2: Copy everything except the five.**

```bash
cd /workspace/mgd-claude-plugins
SRC=/workspace/ihudak-claude-plugins/plugins/dev-workflows
cp -r "$SRC"/agents "$SRC"/commands "$SRC"/references plugins/dev-workflows/
```

`README.md`, `LICENSE`, `CHANGELOG.md`, `dependencies.md`, and `plugin.json` are **not** in that command
and must not be added to it.

- [ ] **Step 3: Hand-edit mgd's own `plugins/dev-workflows/README.md`** — apply Task 2 Step 9's three
  agent-table row edits and Task 5 Step 3's mermaid node edit **by hand**, to mgd's copy. Never `cp` it.

- [ ] **Step 4: Hand-edit mgd's repo-root `CLAUDE.md`** — apply Task 6 Step 3's index entry and Task 7
  Steps 1–2's map and invariants **by hand**. Never `cp` it; it carries mgd-specific paths.

- [ ] **Step 5: Verify parity.**

```bash
cd /workspace/mgd-claude-plugins
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows plugins/dev-workflows
```

Expect the same five files and **nothing else**. A sixth difference is either a missed hand-edit or an
accidental copy.

```bash
claude plugin validate .
```

- [ ] **Step 6: Commit** (same message body as the canonical commits, prefixed
  `(ported from ihudak-claude-plugins)`).

---

## Task 9: Port to ihudak-copilot-plugins

**Never `cp` anything into this repo.** Apply each edit surgically to Copilot's own file.

- [ ] **Step 1: Branch.**

```bash
cd /workspace/ihudak-copilot-plugins
git switch main && git pull --ff-only && git switch -c iv-gu/upstream-harvest-round-2
```

- [ ] **Step 2: Apply Tasks 1–6 to Copilot's paths, one file at a time.**

Path mapping: `references/<f>.md` → `dev-workflows/skills/_shared/<f>.md`;
`agents/<a>.md` → `dev-workflows/agents/<a>.md`; `commands/<c>.md` → `dev-workflows/skills/<c>/SKILL.md`.

Dialect, applied to every inserted line:
- `${CLAUDE_PLUGIN_ROOT}/references/<f>.md` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<f>.md`
- `Agent (subagent_type: "dev-workflows:X")` → `task(agent_type: "dev-workflows:X", model: …)`
- `/implement`, `/document`, `/epics`, `/vuln`, `/upgrade` → `implement:`, `document:`, `epics:`,
  `vuln:`, `upgrade:` — but **never** where the token is followed by `.md` or a path separator. After
  converting, run `grep -rn "[a-z]:\.md" dev-workflows/` and expect no output.
- "Opus" → "strong tier" in prose describing a model tier.

- [ ] **Step 3: Copilot README — three edits, one of which differs from the Claude editions.**

- `code-review` row (`:211`): `8 dimensions` → `11 dimensions`, same rewording as Task 2 Step 9.
- `doc-reviewer` row (`:212`): `17 dimensions` → `18 dimensions`.
- `epic-reviewer` row (`:213`): **this row carries NO dimension count.** Do **not** add canonical's
  number by copying it. Either leave it numberless (append the new dimension to its named list) or add
  the count **derived** from `grep -cE "^#### " dev-workflows/agents/epic-reviewer.md`. Copying
  canonical's "9" would import a wrong number into an edition that did not have one.
- `_shared` reference list (near `:346`): add index bullets for `finding-triage.md` and
  `instruction-file-maintenance.md`.
- The `implement:` mermaid node (`:153`) reads
  `RV["test-writer → strong-tier code-review → review-fixer (gate: tests never run before non-BLOCK)"]`
  — insert `→ triage (verify each finding)` before `review-fixer`, preserving the rest of that node's
  wording verbatim. Do not replace it with canonical's node text.

- [ ] **Step 4: `.github/copilot-instructions.md`.** Apply the workflow-map and invariant edits **where a
  target exists**. This file is asymmetric with the Claude editions' `CLAUDE.md`; if a section this round
  would extend does not exist there, **skip it with a stated reason in the task report** — do not invent
  a section.

- [ ] **Step 5: Verify no Claude dialect leaked.**

```bash
cd /workspace/ihudak-copilot-plugins
grep -rn "CLAUDE_PLUGIN_ROOT" dev-workflows/ | grep -v CHANGELOG    # expect no output
grep -rn "subagent_type" dev-workflows/ | grep -v CHANGELOG          # expect no output
grep -rn "[a-z]:\.md" dev-workflows/                                 # expect no output
grep -rnE "/(implement|document|epics|vuln|upgrade)\b" dev-workflows/skills/ | grep -v CHANGELOG
# ^ expect no NEW slash-form command names (pre-existing hits in unrelated prose are fine — compare to
#   `git stash`-ed baseline if unsure)
```

- [ ] **Step 6: Commit.**

---

## Task 10: Versions, catalogs, changelogs

- [ ] **Step 1: Derive the catalog list. Do not type it.**

```bash
for r in ihudak-claude-plugins mgd-claude-plugins ihudak-copilot-plugins; do
  find /workspace/$r -name 'marketplace.json' -not -path '*/.git/*'
done
```

Expect three: `.claude-plugin/marketplace.json` ×2 and `.github/plugin/marketplace.json` (Copilot,
**depth 3** — a bounded `find` misses it, and that exact mistake has shipped a mismatched catalog twice).

- [ ] **Step 2: Bump six files.** In each repo, the plugin manifest **and** the catalog's `dev-workflows`
  entry:
  - canonical: `plugins/dev-workflows/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`
  - mgd: same two paths
  - Copilot: `dev-workflows/.plugin/plugin.json` + `.github/plugin/marketplace.json`

  `2.53.2 → 2.54.0` (canonical, mgd); `2.23.2 → 2.24.0` (Copilot). Each catalog lists four plugins —
  edit **only** the `dev-workflows` entry.

- [ ] **Step 3: Leave every `description` blurb unchanged.** This round is behavioural. If a blurb edit
  seems necessary, it replaces wording rather than appending, and must stay under 1024 characters.

```bash
cd /workspace/ihudak-claude-plugins && python3 scripts/validate-catalog.py
```

- [ ] **Step 4: CHANGELOG entries** in all three repos under the new version heading, `### Added` /
  `### Changed` / `### Fixed` as appropriate. mgd's entry is annotated
  `(ported from ihudak-claude-plugins)`. Include the two corrected README dimension counts under
  `### Fixed` — they are user-visible corrections, not silent cleanup.

- [ ] **Step 5: Verify version sync across all three repos.**

```bash
for r in ihudak-claude-plugins mgd-claude-plugins ihudak-copilot-plugins; do
  echo "== $r"; grep -rh '"version"' $(find /workspace/$r -name 'plugin.json' -path '*dev-workflows*' -not -path '*/.git/*')
  grep -A3 '"dev-workflows"' $(find /workspace/$r -name 'marketplace.json' -not -path '*/.git/*') | grep '"version"'
done
```

The two numbers must match within each repo.

- [ ] **Step 6: Commit in each repo.**

---

## Task 11: Cross-edition verification

- [ ] **Step 1: Gates.**

```bash
cd /workspace/ihudak-claude-plugins && claude plugin validate . && python3 scripts/validate-catalog.py \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root .
cd /workspace/mgd-claude-plugins && claude plugin validate .
cd /workspace/ihudak-copilot-plugins && python3 -c "import json,sys; [json.load(open(p)) for p in ['dev-workflows/.plugin/plugin.json','.github/plugin/marketplace.json']]" && echo "copilot JSON OK"
```

- [ ] **Step 2: Parity.**

```bash
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows /workspace/mgd-claude-plugins/plugins/dev-workflows
```

Expect exactly the five identity files.

- [ ] **Step 3: Reachability — every new rule has a live consumer.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -rl "finding-triage" commands/ agents/ | wc -l                # expect 7 (5 commands + 2 fixers)
grep -rl "instruction-file-maintenance" agents/ ../../CLAUDE.md | wc -l   # expect 2
grep -rl "read-failure contract" agents/ | wc -l                   # expect 6
```

Repeat the equivalent greps in mgd and (with Copilot paths) in the Copilot edition.

- [ ] **Step 4: Report.** Write the verification record — **now, after all fixes, not before** — listing
  every command run, its actual output, and every mismatch found and fixed. Do not copy an expected value
  from this plan into the record; record what the command printed.

---

## Self-review notes

**Spec coverage.** §3→Task 1; §4→Tasks 4–5; §5→Tasks 2–3; §6→Task 6; §7 wave order→Tasks 1–6 sequencing;
§8→Tasks 8–10; §9→Tasks 7 (residue), 11 (record); §9.1 checkpoint→Task 1 Step 12; §10.1→Tasks 2, 5, 6, 7,
9, 10; §10.2→Task 5 Step 3 and Task 9 Step 3; §10.3→Task 2 Step 9 and Task 9 Step 3; §10.4→Task 7 Step 3c;
§12→Task 7 Step 4.

**Known plan-level decision:** `references/finding-triage.md` resolves a gap in spec §4.3, which described
the triage step without saying where its text lives. Flagged at the top of this plan.

**Unverified line references.** Line numbers in Tasks 3 and 5 (`document.md:939/:945`, `epics.md:442/:448`,
`vuln.md:153`, `upgrade.md:147`, `implement.md:472/:476/:486`) were derived on 2026-08-21 and **shift as
earlier tasks edit those files**. Locate by the quoted surrounding text, not by line number; if the quoted
text is absent, STOP and report rather than guessing.

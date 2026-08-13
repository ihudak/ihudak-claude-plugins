# Whole-round review fixes — Implementation Plan (sub-project I)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the 45 requirements of the seven-axis whole-round review of the 2026-08-07 PM feedback round, so the plugin's documentation, caller lists, and verification records describe what it actually does.

**Architecture:** Seventeen tasks. Tasks 1–13 change canonical content; task 14 releases it; tasks 15–16 port to mgd and copilot; task 17 writes the verification record **last**, which is this sub-project's first application of the rule it also ships (R10). Most requirements are one-sentence corrections with a pre-extracted verbatim old→new pair; the few that change behaviour are isolated into their own tasks.

**Tech Stack:** Prompt markdown. **There is no test framework and no code** — every verification is `grep` / `awk` / `diff` / reading. All counts are whitespace-normalized.

## Global Constraints

- **Ships as** dev-workflows **2.51.0** (canonical + mgd) / **2.21.0** (copilot).
- **Branch** `iv-gu/whole-round-review-fixes`, already created in all three repos, forked from `main`. The spec is committed at `468ffb7`, amended `e9cdf0a` and `41bfe52`.
- **Three repos:** canonical `/workspace/ihudak-claude-plugins` (`plugins/dev-workflows/`), mgd `/workspace/mgd-claude-plugins` (`plugins/dev-workflows/`, content-verbatim except its identity files — **verify the divergence set empirically at port time**), copilot `/workspace/ihudak-copilot-plugins` (`dev-workflows/`, adapted dialect, own version track).
- **NEVER `cp` into copilot.** It carries genuinely different content and is hand-adapted.
- **Copilot dialect, four rules:** `subagent_type:` → `agent_type:`; `${CLAUDE_PLUGIN_ROOT}/references/X.md` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/X.md`; `§2.1 Sonnet chain` → copilot's own detection chain; **command names are colon-form (`idea:`) not slash-form (`/idea`)**.
- **Copilot has two depth-3 files** that a `find -maxdepth 2` misses and that have been missed before: `.github/plugin/marketplace.json` (its catalog) and `.github/copilot-instructions.md`.
- **A check must be capable of failing.** Where a step's assertion is a count, run it before the edit too and record both numbers. An assertion that returns the same value before and after proves nothing.
- **Re-derive every expected value at the tree being verified.** Never copy an `expect N` from another plan — 2 of this round's wrong values propagated exactly that way.
- **Do not fix findings outside your task.** If you spot one, report it in your task report; the coordinator routes it.

## Verbatim edit appendices

Two committed appendices carry the exact, pre-verified old→new pairs and per-item assertions:

- `docs/superpowers/plans/2026-08-13-whole-round-review-fixes-edits-claude-md.md` — tasks 1 and 11
- `docs/superpowers/plans/2026-08-13-whole-round-review-fixes-edits-agents-refs.md` — tasks 2, 10

Each entry has `FILE`, `LINE`, `OLD`, `NEW`, `ASSERT`, and a `VERIFIED` note recording how the true value was re-derived. **Apply `OLD`→`NEW` exactly.** Two entries record location drift (R30 is at `:250` not `:186`; R32 is at `:221` not `:220`) — trust the appendix, and re-confirm with `grep -n` before editing.

---

## Task 1: `CLAUDE.md` roster and ledger sweep

Twelve independent stale claims in the repo-root `CLAUDE.md`, all one defect class: caller lists and invariant bullets nobody updated when `/update-vi`, `/ready` and `/create-ard` shipped.

**Requirements:** R7, R16 (+ its `SKILL.md` companion), R17, R21, R22, R25, R29, R30, R31, R32, R33, R34.

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/CLAUDE.md`
- Modify: `plugins/dev-workflows/skills/model-routing/SKILL.md:3` (R16 companion)

**Interfaces:**
- Produces: a corrected `CLAUDE.md` that task 15 ports to mgd verbatim and task 16 hand-adapts for copilot.
- R5's `CLAUDE.md` half is **NOT** in this task — it belongs to task 3, so the direct-mode decision lands in one diff.

- [ ] **Step 1: Record the before-state for every item**

```bash
cd /workspace/ihudak-claude-plugins
for r in R7 R16 R17 R21 R22 R25 R29 R30 R31 R32 R33 R34; do echo "--- $r ---"; done
# Read the appendix and run each entry's ASSERT command NOW, before editing.
# Every one must return 0 (or the stated pre-value). Record the outputs.
```

Expected: every `ASSERT` returns **0**. If any returns 1 already, that item is already fixed — say so in your report and skip it. Do not invent an edit.

- [ ] **Step 2: Apply the twelve edits**

Read `docs/superpowers/plans/2026-08-13-whole-round-review-fixes-edits-claude-md.md` and apply each entry's `OLD` → `NEW` exactly, for R7, R16 (both the `CLAUDE.md` roster line and the `SKILL.md:3` companion count), R17, R21, R22, R25, R29, R30, R31, R32, R33, R34.

- [ ] **Step 3: Per-item assertion — each must pass individually**

Run each entry's `ASSERT` command again, one at a time, and record its output beside its requirement ID.

Expected: **every one returns its stated expected value (1 unless noted).** This is the mitigation for "one large diff" — no item is accepted on the strength of the diff looking right.

- [ ] **Step 4: Collateral-change assertion**

```bash
git diff --stat
```

Expected: exactly **two** files changed — `CLAUDE.md` and `plugins/dev-workflows/skills/model-routing/SKILL.md`. No other file. If a third file appears, stop and report.

- [ ] **Step 5: Prove no claim was broken while fixing another**

```bash
# The roster must now name 14 must-load commands and 7 exempt = 21 total.
grep -c 'update-vi' CLAUDE.md   # must be >= 4 (roster, vi-reviewer ledger, cost, model-routing)
```

Expected: `>= 4`. Then re-read the twelve edited passages once, end to end, checking each reads as a sentence rather than a patched fragment.

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md plugins/dev-workflows/skills/model-routing/SKILL.md
git commit -m "fix(dev-workflows): CLAUDE.md roster sweep — twelve stale caller lists and invariant bullets"
```

---

## Task 2: Agent and reference caller-list sweep

Same defect class as task 1, in `agents/*.md`, `references/*.md`, and the plugin `README.md`.

**Requirements:** R13, R19 (3 sites, 2 files), R20, R23, R24, R26, R27, R28.

**Files:**
- Modify: `plugins/dev-workflows/references/cost-emission.md` (R13), `references/feedback-emission.md` + `README.md` (R19), `agents/risk-planner.md` (R20), `agents/vi-reviewer.md` (R23), `agents/jira-reader.md` (R24), `references/grilling-technique.md` (R26), `references/jira-input-resolution.md` (R27), `README.md` (R28)

**Interfaces:**
- Consumes: nothing from task 1.
- Produces: corrected caller lists that task 17's verification record re-checks in both directions.

- [ ] **Step 1: Run every ASSERT before editing**

Read `docs/superpowers/plans/2026-08-13-whole-round-review-fixes-edits-agents-refs.md`, entries R13, R19, R20, R23, R24, R26, R27, R28. Run each `ASSERT` now.

Expected: each returns its pre-value (0 for "added" items, 1 for R20's "must become 0"). Any item already correct → report and skip.

- [ ] **Step 2: Apply the eight edits**

Apply each entry's `OLD` → `NEW` exactly. R19 has **three** sites across two files — apply all three.

- [ ] **Step 3: Per-item assertion**

Run each `ASSERT` again individually; record the output per requirement ID. Expected: every one at its stated post-value.

- [ ] **Step 4: Bidirectional caller-list check**

For each agent whose caller list you edited, verify the list matches reality **in both directions**:

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for a in risk-planner vi-reviewer jira-reader; do
  echo "--- $a: commands that actually dispatch it ---"
  grep -l "dev-workflows:$a" commands/*.md | xargs -n1 basename
done
```

Expected: the set printed for each agent equals the set named in that agent's corrected caller list. Any mismatch is a defect in your edit — fix it before committing.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/
git commit -m "fix(dev-workflows): agent and reference caller lists — eight stale consumer sets"
```

---

## Task 3: Direct mode has no reviewer gate — make both files say so

**Requirements:** R5 (both halves) + R6. Spec decision **D4**: direct mode's lightweight design is deliberate; the documentation is what is wrong.

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/CLAUDE.md:138` (workflow map), `:203-204` (invariant bullets)
- Modify: `plugins/dev-workflows/commands/document.md:35`

- [ ] **Step 1: Confirm the premise from the tree**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
awk 'NR>=1331 && /doc-reviewer/ {print NR": "$0}' commands/document.md
```

Expected: **no output.** Mode B starts at line 1331 and dispatches no reviewer. If output appears, STOP — the premise is wrong, report it.

- [ ] **Step 2: Fix the workflow-map edge**

In `/workspace/ihudak-claude-plugins/CLAUDE.md`, line 138:

OLD:
```
/document (direct)   → [doc-reviewer] → [doc-fixer] → impl-maintenance → commit-artifacts
```
NEW:
```
/document (direct)   → [docs-style-checker] → [doc-fixer] → impl-maintenance → commit-artifacts
```

- [ ] **Step 3: Fix the invariant bullets**

In the same file, the direct-mode invariants at `:203-204`:

OLD:
```
- `doc-reviewer` performs comprehensive review: links, headings, wikilinks, style, completeness
```
NEW:
```
- **No `doc-reviewer` gate** — direct mode is deliberately lightweight: a mandatory style check (Phase 3.5) and `doc-fixer`, but no Opus review. Two rules in `document.md` (`:1490`, `:1494`) depend on that absence
```

Then the following bullet:

OLD:
```
- BLOCKER findings trigger a fix cycle via `doc-fixer` (max one fix + one re-review); CONCERNs are recorded and may be fixed inline
```
NEW:
```
- Style-check findings are fixed via `doc-fixer`; with no reviewer gate there is no BLOCKER fix cycle and no re-review in this mode
```

- [ ] **Step 4: Fix `document.md:35`**

OLD:
```
The two modes share the same `docs-style-checker` / `doc-reviewer` / `doc-fixer` agents (each mode emits its own final report).
```
NEW:
```
The two modes share the same `docs-style-checker` / `doc-fixer` agents; only Jira mode also runs `doc-reviewer` (each mode emits its own final report).
```

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -c 'doc-reviewer' CLAUDE.md                                    # record; the direct-mode edge and bullets must no longer name it
awk 'NR>=200 && NR<=210' CLAUDE.md | grep -c 'No `doc-reviewer` gate'   # expect 1
grep -cF 'only Jira mode also runs `doc-reviewer`' plugins/dev-workflows/commands/document.md   # expect 1
grep -n '/document (direct)' CLAUDE.md | grep -c 'doc-reviewer'     # expect 0
```

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md plugins/dev-workflows/commands/document.md
git commit -m "fix(dev-workflows): direct mode has no reviewer gate — CLAUDE.md and document.md now agree"
```

---

## Task 4: `/idea` — round-2 `refresh:` and the grill cap

**Requirements:** R8 (round-2 `refresh:`) + R45 (cap 5 → 10).

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (`:15`, `:132`, `:163`, `:183`)
- Modify: `plugins/dev-workflows/references/model-routing/classification.md` §8.5
- Modify: `plugins/dev-workflows/references/grilling-technique.md` (`:27`, `:32`)
- Modify: `/workspace/ihudak-claude-plugins/CLAUDE.md:246`

**Interfaces:**
- Consumes: nothing.
- Produces: `classification.md` §8.5 is also edited by task 10 (R14). **Task 10 must run after this task** to avoid a conflicting edit to the same section.

- [ ] **Step 1 (R8): Pin round 2's refresh block**

In `commands/idea.md`, the round-2 dispatch instruction at `:163` names only `capability_themes` and `search_hints`. Append to that sentence:

NEW (append to the round-2 dispatch instruction):
```
 Round 2 reuses round 1's `refresh:` block verbatim — `switch_to_default_branch: false`, `pull: false` — so the read-only posture and the "dirty-tree status never produced here" claim at `:161` hold for both rounds.
```

- [ ] **Step 2 (R8): Say the same thing in §8.5, where the other caller reads it**

In `references/model-routing/classification.md` §8.5, after the sentence enumerating the narrowed fields, add:

```
The narrowed brief changes only those fields: every other field of round 1's dispatch — **including `refresh:`** — is reused verbatim, so a caller that pinned a read-only posture in round 1 keeps it in round 2.
```

- [ ] **Step 3 (R8): Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -cF "Round 2 reuses round 1's \`refresh:\` block verbatim" commands/idea.md   # expect 1
grep -cF 'including `refresh:`' references/model-routing/classification.md          # expect 1
```

- [ ] **Step 4 (R45): Prove the overflow rule is bound-relative BEFORE changing the number**

This is the mitigation the spec requires. The `[NEEDS CLARIFICATION]` mechanism must fire at whatever the bound is, not at a hardcoded 5.

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
sed -n '22p' references/grilling-technique.md
sed -n '183,185p' commands/idea.md
```

Expected: the overflow rule is expressed in terms of **bounded vs relentless callers** and "remaining/unresolved high-impact gaps" — **not** in terms of the number 5. Record the exact wording in your report. **If either passage ties the overflow to the literal 5, STOP and report** — raising the cap would silently kill the mechanism, and the plan must change.

- [ ] **Step 5 (R45): Change every grill-cap site from 5 to 10**

Four sites carry the literal bound:

| File | Line | OLD | NEW |
|---|---|---|---|
| `commands/idea.md` | 15 | `bounded (≤5 questions)` | `bounded (≤10 questions)` |
| `commands/idea.md` | 132 | `the ≤5 question slots` | `the ≤10 question slots` |
| `commands/idea.md` | 183 | `ask **≤5** questions` | `ask **≤10** questions` |
| `references/grilling-technique.md` | 27 | `Used by `/idea` (≤5;` | `Used by `/idea` (≤10;` |
| `references/grilling-technique.md` | 32 | `bounded callers still cap at ≤5` | `bounded callers still cap at ≤10` |

- [ ] **Step 6 (R45): Fix `CLAUDE.md:246`, which is wrong on both counts**

It claims the bound applies to the whole VI flow (only `/idea` is bounded — R7's neighbour) and that `--deep` "relaxes" the bound (it switches to relentless, i.e. uncapped).

OLD:
```
- The embedded grill is **bounded** (≤5 questions; `--deep` on `/idea` relaxes it); leftover gaps become capped `[NEEDS CLARIFICATION]` markers + logged assumptions
```
NEW:
```
- Only `/idea`'s embedded grill is **bounded** (≤10 questions; `--deep` switches it to relentless — uncapped, not merely relaxed). `/create-vi`, `/update-vi`, `/create-ard`, `/specify` and `/design` are relentless by design. Leftover gaps become capped `[NEEDS CLARIFICATION]` markers + logged assumptions
```

- [ ] **Step 7 (R45): Prove no literal 5 survives, and the overflow still fires**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '≤5\|≤ 5' plugins/dev-workflows/commands/idea.md plugins/dev-workflows/references/grilling-technique.md CLAUDE.md
```
Expected: **no output.** Any surviving `≤5` is a site that now disagrees with the others.

```bash
grep -c '≤10' plugins/dev-workflows/commands/idea.md                      # expect 3
grep -c '≤10' plugins/dev-workflows/references/grilling-technique.md      # expect 2
grep -c 'NEEDS CLARIFICATION' plugins/dev-workflows/references/grilling-technique.md   # expect >= 1, unchanged from before
sed -n '22p' plugins/dev-workflows/references/grilling-technique.md       # must be byte-identical to Step 4's output
```

The last line is the load-bearing one: **the overflow rule must be unchanged**, proving the mechanism was never coupled to the number.

- [ ] **Step 8: Commit**

```bash
git add plugins/dev-workflows/ CLAUDE.md
git commit -m "fix(dev-workflows): /idea round 2 pins its refresh block; grill cap 5 to 10"
```

---

## Task 5: `/document` — make "no refresh" actually mean no refresh

**Requirement:** R2. Spec decision **D3**.

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md:196` (label), `:395-397` (dispatch)

- [ ] **Step 1: Confirm the defect**

```bash
sed -n '395,397p' /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md
```
Expected: `fetch: true` hardcoded, only `pull` varying. If it already varies `fetch`, STOP and report.

- [ ] **Step 2: Fix the dispatch**

OLD:
```
> refresh:
>   fetch: true
>   pull:  [false if Phase 1 chose 'fetch only' (default) or 'no refresh'; true if 'fetch + pull default branch']"
```
NEW:
```
> refresh:
>   fetch: [false if Phase 1 chose 'no refresh'; true otherwise]
>   pull:  [true if Phase 1 chose 'fetch + pull default branch'; false otherwise]"
```

- [ ] **Step 3: Sharpen the choice label**

At `:196`:

OLD:
```
  choices: ["fetch only (Recommended)", "fetch + pull default branch", "no refresh", "Other… (describe)"]
```
NEW:
```
  choices: ["fetch only (Recommended)", "fetch + pull default branch", "no refresh — resolve PRs from local objects only; a PR not yet fetched will not resolve, and a dirty clone stops blocking", "Other… (describe)"]
```

- [ ] **Step 4: Verify the three choices now map to three distinct dispatches**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
sed -n '395,397p' commands/document.md
grep -cF "no refresh — resolve PRs from local objects only" commands/document.md   # expect 1
```

Expected: `fetch` and `pull` each vary; "no refresh" → `false/false`, "fetch only" → `true/false`, "fetch + pull" → `true/true`. Confirm by reading that no two choices produce the same pair. Compare against `/epics`' correct mapping:

```bash
sed -n '316,317p' commands/epics.md
```

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/document.md
git commit -m "fix(dev-workflows): /document's 'no refresh' choice was inert — it now sends fetch: false"
```

---

## Task 6: Narrow two SSOT promises to their real producers

**Requirements:** R3 (`prep` block, decision **D1**) + R18 (`source-truth.md` §4.1, decision **D2**).

**Files:**
- Modify: `plugins/dev-workflows/references/read-only-repos.md:5`, `:69` (and its §6 heading scope)
- Modify: `plugins/dev-workflows/references/source-truth.md:217-221`
- Modify: `/workspace/ihudak-claude-plugins/CLAUDE.md` read-only-repos paragraph

- [ ] **Step 1: Confirm both premises**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c 'prep' agents/docs-grounder.md      # expect 0
grep -c 'prep' agents/code-scanner.md       # expect > 0
grep -c 'prep' agents/diff-summarizer.md    # expect > 0
```
Expected: `docs-grounder` **0**, the other two non-zero. If `docs-grounder` is non-zero, STOP — it already emits `prep` and R3 is void.

- [ ] **Step 2 (R3): Scope the `prep` contract**

At `read-only-repos.md:69`:

OLD:
```
Every consuming agent reports these four fields in its `prep` block, always present so a caller never branches on absence:
```
NEW:
```
`code-scanner` and `diff-summarizer` report these four fields in their `prep` block, always present so a caller never branches on absence. `docs-grounder` follows §1–§4 (read-only detection, what to skip, ref resolution, reading at the ref) but returns a digest — `status` / `retrieval` / `docs_references` / `docs_challenges` / `notes` — not a `prep` block; its staleness signal is the 14-day clause in `docs-grounding.md` instead:
```

At `:5`, keep `docs-grounder` in the consumer list (it genuinely consumes §1–§4) but qualify it:

OLD:
```
This file is the single source of truth for that behavior. Consumers: `code-scanner`, `diff-summarizer`, `docs-grounder`.
```
NEW:
```
This file is the single source of truth for that behavior. Consumers: `code-scanner`, `diff-summarizer`, `docs-grounder` — the first two also emit the §6 `prep` block; `docs-grounder` consumes §1–§4 only.
```

- [ ] **Step 3 (R3): Fix `CLAUDE.md`'s repetition of the same claim**

In `/workspace/ihudak-claude-plugins/CLAUDE.md`, the `read-only-repos.md` paragraph says the `prep` contract comes from all three. Change `Consumed by \`code-scanner\`, \`diff-summarizer\`, and \`docs-grounder\`` to name the `prep` emitters as `code-scanner` and `diff-summarizer` only, with `docs-grounder` consuming §1–§4. **Do not change the "seven"/"eight" wording in this paragraph — task 11 owns that (R35).**

- [ ] **Step 4 (R18): Remove the duty `diff-summarizer` never receives**

At `source-truth.md:217-221` (§4.1 use case A), the text assigns `diff-summarizer` the duty of surfacing enum changes, new constants, and renamed labels. Confirm first:

```bash
grep -c 'enum changes\|renamed label' agents/diff-summarizer.md   # expect 0
```
Expected **0** — the agent's own spec omits the duty. Then rewrite §4.1's sentence so the verification is performed by the consulting agent reading shipped source directly (which is what `source-truth.md` exists for), rather than being delegated to `diff-summarizer`.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -cF 'consumes §1–§4 only' plugins/dev-workflows/references/read-only-repos.md   # expect 1
grep -cF '`docs-grounder` follows §1–§4' plugins/dev-workflows/references/read-only-repos.md   # expect 1
grep -c 'diff-summarizer' plugins/dev-workflows/references/source-truth.md   # record before and after; must decrease
```

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/references/ CLAUDE.md
git commit -m "fix(dev-workflows): narrow two SSOT promises to the producers that keep them"
```

---

## Task 7: `/ready` — run the preflight before the dirt test

**Requirement:** R4.

**Files:**
- Modify: `plugins/dev-workflows/commands/ready.md` (Phase 0: move the preflight from `:71-76` to immediately after `$SPECS_PATH` resolves at `:47-49`)

- [ ] **Step 1: Read the whole of Phase 0 before moving anything**

```bash
sed -n '40,80p' /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/ready.md
```

Record the current step order and what each step depends on. The preflight must not be moved above the point where `$SPECS_PATH` is known.

- [ ] **Step 2: Move the preflight**

Relocate the `specs-preflight` step so it runs immediately after `$SPECS_PATH` is resolved, ahead of the dirty-tree prompt. Per `specs-repo-git.md` §7.1 the preflight belongs "as early as `$SPECS_PATH` is known", and its §3.4 flush is what makes the dirt test meaningful.

- [ ] **Step 3: Reachability check — the moved step must still run on every path**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
awk '/^## Phase 0/,/^## Phase 1/' commands/ready.md | grep -nE 'skip|no-op|only when|STOP|Cancel'
```

Expected: no skip/no-op/early-return instruction sits **between** `$SPECS_PATH` resolution and the relocated preflight. This is the mitigation for the round's eight unreachable guards, most of which were created by moving a rule. If any such instruction appears upstream of the preflight, STOP and report.

- [ ] **Step 4: Verify the ordering and that nothing was lost**

```bash
grep -n 'specs-preflight' commands/ready.md            # expect exactly 1 occurrence
grep -n 'SPECS_PATH' commands/ready.md | head -3
```
Expected: the preflight line number is now **greater** than the `$SPECS_PATH` resolution line and **less** than the dirty-tree prompt line. State all three numbers in your report.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/ready.md
git commit -m "fix(dev-workflows): /ready ran its dirt prompt before the preflight that clears the dirt"
```

---

## Task 8: Terminal order — swap `/release-notes`, clarify the rule for `/document`

**Requirements:** R11 (swap) + R12 (clarify). Spec decision **D6**. **No `document.md` phase is moved** — see D6 for the three verified reasons.

**Files:**
- Modify: `plugins/dev-workflows/commands/release-notes.md` (Phase 9 / Phase 10 order)
- Modify: `plugins/dev-workflows/references/session-hygiene.md` rule 2

- [ ] **Step 1 (R11): Confirm the inversion**

```bash
grep -n '^## Phase 9\|^## Phase 10' /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/release-notes.md
```
Expected: Phase 9 is "Emit follow-up tasks" and Phase 10 is "Session maintenance & feedback" — the inversion. If already correct, STOP and report.

- [ ] **Step 2 (R11): Swap the two phases**

Reorder so feedback precedes follow-ups, and **renumber** so the sequence still reads 9 then 10. Move the whole phase bodies, not just the headings.

- [ ] **Step 3 (R11): Verify the swap and that no content was dropped**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n '^## Phase' commands/release-notes.md | tail -6
grep -c 'emit-auto' commands/release-notes.md        # must equal its pre-edit value
grep -c 'emit-followups\|follow-up' commands/release-notes.md   # must equal its pre-edit value
```
Expected: feedback's phase number is now **lower** than follow-ups'; both content counts unchanged. Record pre- and post-values for both.

- [ ] **Step 4 (R12): Amend the canonical-order rule**

In `references/session-hygiene.md` rule 2:

OLD:
```
The canonical terminal order is:
   **deliverable + handoff → feedback → follow-ups → cost → `resume.md` →
   `commit-artifacts` → the run's last printed output**
```
NEW:
```
The canonical terminal order is:
   **deliverable + handoff → feedback → follow-ups → cost → `resume.md` →
   `commit-artifacts` → the run's last printed output**. What binds every
   command is the **emitter tail** — feedback → follow-ups → cost →
   `resume.md` → `commit-artifacts`. A command's deliverable-side finish may
   precede the tail at whatever point suits it: `/document`'s conditional
   `Phase 8.5 — Finish & handoff` is the docs-repo git finish, while
   `emit-auto` writes into `$SPECS_PATH`, so the two touch different
   repositories and their relative order carries no consequence
```

- [ ] **Step 5 (R12): Verify — and confirm no command file changed**

```bash
cd /workspace/ihudak-claude-plugins
grep -cF 'What binds every' plugins/dev-workflows/references/session-hygiene.md   # expect 1
git diff --name-only
```
Expected: exactly two files — `commands/release-notes.md` and `references/session-hygiene.md`. **`document.md` must NOT appear.**

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/
git commit -m "fix(dev-workflows): /release-notes emitter order; session-hygiene names the binding tail"
```

---

## Task 9: Cost subsystem — correct the roster prose, surface the unpriced case

**Requirements:** R15 (prose) + R43 (the feedback's durable asks).

**Files:**
- Modify: `plugins/dev-workflows/references/cost-prices.yaml:22`
- Modify: `plugins/dev-workflows/references/cost-emission.md:154` and the emission surface

**Interfaces:**
- **`scripts/session-cost.py`'s pricing logic is explicitly out of scope** (spec, R15/R43 note). The engine already returns `"unpriced-model"` at `:218`; only the surfacing is missing.

- [ ] **Step 1: Confirm the arithmetic is sound before touching prose**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -E '^  claude-' references/cost-prices.yaml
grep -n 'unpriced-model' scripts/session-cost.py
```
Expected: exactly **8** keys (Opus 5/4.8/4.7/4.6, Sonnet 5/4.6/4.5, Haiku 4.5), **no `claude-opus-4-5`**, and `session-cost.py` returning `"unpriced-model"`. If a `claude-opus-4-5` key exists, STOP — R15 is a different defect than specified.

- [ ] **Step 2 (R15): Fix the two wrong prose claims**

`cost-prices.yaml:22`:

OLD:
```
  # Opus chain (§2). Opus 5 and Opus 4.5-4.8 all bill at $5 / $25.
```
NEW:
```
  # Opus chain (§2). Opus 5 and Opus 4.6-4.8 all bill at $5 / $25.
```

`cost-emission.md:154`: remove the claim that Haiku is "routing-policy-reachable" — no routing path reaches it. Keep the price key (a harmless defensive entry) and say so.

- [ ] **Step 3 (R43): Surface the unpriced case**

Add to the cost emission surface a visible warning line — not an inline note — fired when a run's tokens are dominated by a model the table cannot price. It must name the model id and state that the cost figure is therefore a lower bound.

- [ ] **Step 4 (R43): Add the maintainer checklist**

Add to `cost-emission.md` a short checklist tying a new model generation to **both** files that must change together (`cost-prices.yaml` and `classification.md`'s chain), which is the omission that produced the stale chain in the first place.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c '4\.5-4\.8' references/cost-prices.yaml          # expect 0
grep -c '4\.6-4\.8' references/cost-prices.yaml          # expect 1
grep -c 'routing-policy-reachable' references/cost-emission.md   # expect 0
grep -c 'unpriced' references/cost-emission.md           # expect >= 1
git diff --name-only -- scripts/                          # expect NO output — the engine is out of scope
```

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/references/
git commit -m "fix(dev-workflows): cost roster prose; surface the unpriced-model case"
```

---

## Task 10: `classification.md` §8.5 precedence and the idea-format enum

**Requirements:** R14 + R42. **Runs after task 4**, which also edits §8.5.

**Files:**
- Modify: `plugins/dev-workflows/references/model-routing/classification.md` §8.5 precedence paragraph
- Modify: `plugins/dev-workflows/references/idea-format.md:14`

- [ ] **Step 1: Apply both edits from the appendix**

Read `docs/superpowers/plans/2026-08-13-whole-round-review-fixes-edits-agents-refs.md`, entries **R14** and **R42**, and apply each `OLD` → `NEW` exactly. R14's replacement scopes the outside-deferral qualifier to `/implement` and states `/idea`'s rule explicitly, so the precedence paragraph and the altitude paragraph stop contradicting each other.

- [ ] **Step 2: Verify the contradiction is gone**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
awk 'NR>=376 && NR<=400' references/model-routing/classification.md | grep -c 'caller-scoped'        # expect 1
awk 'NR>=376 && NR<=400' references/model-routing/classification.md | grep -c 'for `/implement` only' # expect 1
grep -cF 'community-post | prompt | doc-grounding' references/idea-format.md   # expect 1
```

- [ ] **Step 3: Confirm the two §8.5 edits coexist**

Task 4 added a `refresh:` sentence to §8.5. Both must be present:

```bash
grep -cF 'including `refresh:`' references/model-routing/classification.md   # expect 1
```

- [ ] **Step 4: Read §8.5 end to end**

Read the whole of §8.5 once. It now carries edits from two tasks — confirm it reads as one coherent section with no duplicated or orphaned clause.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/
git commit -m "fix(dev-workflows): scope §8.5's outside-deferral rule to /implement; idea-format gains doc-grounding"
```

---

## Task 11: The dispatcher count, all three editions

**Requirement:** R35 — "seven" must become "eight" (H wired `/idea` into `code-scanner`).

**Files:**
- Modify: canonical `/workspace/ihudak-claude-plugins/CLAUDE.md:124`
- Modify: mgd `/workspace/mgd-claude-plugins/CLAUDE.md:136`
- Modify: copilot `/workspace/ihudak-copilot-plugins/dev-workflows/README.md:369`

**Interfaces:**
- This is the one content task that edits all three repos directly, because each edition states the count in its own identity file. Tasks 15 and 16 must **not** re-port it.

- [ ] **Step 1: Re-derive the true count**

```bash
grep -rl 'prep.read_only' /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/*.md | wc -l
```
Expected: **8**. If it is not 8, use the number you measured and say so — do not write 8 because the plan said so.

- [ ] **Step 2: Apply the three edits** from the appendix entry **R35** (in `…-edits-claude-md.md`).

- [ ] **Step 3: Verify all three editions**

```bash
grep -c 'cited by the eight commands' /workspace/ihudak-claude-plugins/CLAUDE.md          # expect 1
grep -c 'cited by the eight commands' /workspace/mgd-claude-plugins/CLAUDE.md             # expect 1
grep -c 'cited by the eight commands' /workspace/ihudak-copilot-plugins/dev-workflows/README.md  # expect 1
grep -rc 'cited by the seven commands' /workspace/ihudak-claude-plugins/ /workspace/mgd-claude-plugins/ /workspace/ihudak-copilot-plugins/ 2>/dev/null | grep -v ':0' | head
```
Expected: three 1s, and the last command prints nothing (no "seven" survives anywhere).

- [ ] **Step 4: Commit in each repo separately**

```bash
git -C /workspace/ihudak-claude-plugins add CLAUDE.md && git -C /workspace/ihudak-claude-plugins commit -m "fix(dev-workflows): read-only-repos is cited by eight commands, not seven"
git -C /workspace/mgd-claude-plugins add CLAUDE.md && git -C /workspace/mgd-claude-plugins commit -m "fix(dev-workflows): read-only-repos is cited by eight commands, not seven"
git -C /workspace/ihudak-copilot-plugins add dev-workflows/README.md && git -C /workspace/ihudak-copilot-plugins commit -m "fix(dev-workflows): read-only-repos is cited by eight commands, not seven"
```

---

## Task 12: copilot dialect — delete the orphan README, finish the chain rename

**Requirements:** R1 (Critical) + R41. **copilot-only; no canonical counterpart.**

**Files:**
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/upgrade/SKILL.md` (absorb two passages)
- Delete: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/upgrade/README.md`
- Modify: `dev-workflows/agents/epic-writer.md:3`, `dev-workflows/skills/docs-profile/SKILL.md:255`, `dev-workflows/skills/epics/SKILL.md:341`
- Modify: `dev-workflows/skills/_shared/next-phase-offer.md` (rule 6 exemption)

- [ ] **Step 1 (R1): Confirm the README is an orphan**

```bash
cd /workspace/ihudak-copilot-plugins
find dev-workflows/skills -name README.md
grep -rn 'upgrade/README' dev-workflows/ | grep -v '^Binary'
```
Expected: exactly **one** README (upgrade's), and **no** references to it. If another skill has a README, or something links to this one, STOP and report — the delete decision assumed otherwise.

- [ ] **Step 2 (R1): Absorb the two unique passages into `SKILL.md`**

Two things exist only in the README and must survive:
1. `.sdkmanrc` in the Java version-declaration file list (README line ~151).
2. The "Incompatible explicit versions" conflict example (README line ~108).

Add both to `skills/upgrade/SKILL.md` in colon form, matching that file's voice.

- [ ] **Step 3 (R1): Verify the content survived, then delete**

```bash
cd /workspace/ihudak-copilot-plugins
grep -c 'sdkmanrc' dev-workflows/skills/upgrade/SKILL.md      # expect >= 1
grep -c 'Incompatible' dev-workflows/skills/upgrade/SKILL.md  # expect >= 1
git rm dev-workflows/skills/upgrade/README.md
```

- [ ] **Step 4 (R1): Close the class — sharpen rule 6's exemption**

In `dev-workflows/skills/_shared/next-phase-offer.md`, rule 6's exemption currently reads "Prose that describes the pipeline to a reader of this edition's source keeps the short form." Replace with wording that exempts **narrative description of the pipeline** while explicitly binding **any text that tells a reader what to type** — usage blocks, example tables, quick-starts, tips — in whatever file it appears.

- [ ] **Step 5 (R41): Finish the chain rename at three sites**

Rename `§2.1 Sonnet chain` / `§2.1 Sonnet detection chain` → `§2.1 detection chain` at `agents/epic-writer.md:3`, `skills/docs-profile/SKILL.md:255`, `skills/epics/SKILL.md:341`, matching the 60+ already-correct sites.

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-copilot-plugins
test ! -f dev-workflows/skills/upgrade/README.md && echo "README gone"
grep -rn '§2.1 Sonnet' dev-workflows/ | grep -v '^Binary' | wc -l   # expect 0
grep -rnE '(^|[^a-z/`])/upgrade\b' dev-workflows/ | grep -v '^Binary' | grep -v CHANGELOG | wc -l   # expect 0
grep -c 'tells a reader what to type' dev-workflows/skills/_shared/next-phase-offer.md   # expect 1
```

- [ ] **Step 7: Commit**

```bash
git -C /workspace/ihudak-copilot-plugins add -A dev-workflows/
git -C /workspace/ihudak-copilot-plugins commit -m "fix(dev-workflows): delete the orphan upgrade README; finish the §2.1 chain rename"
```

---

## Task 13: Specs-repo bookkeeping

**Requirements:** R9, R10, R36, R37, R38, R39, R40, R44. **Zero behavioural impact** — these are historical plan and verification records under `docs/superpowers/`, plus one process rule. No plugin edition is touched, and nothing here is ported.

**Files:**
- Modify: `docs/superpowers/plans/2026-08-11-environment-guards-verification.md` (R9: rows V5, V8)
- Modify: `docs/superpowers/plans/2026-08-11-verification-results.md` + `…-vault-prior-art-discovery-verification.md` (R36)
- Modify: `docs/superpowers/plans/2026-08-10-specs-repo-git-completeness.md` (R37: 12 items)
- Modify: `docs/superpowers/plans/2026-08-08-document-gate-enforcement.md` (R38: 5 items)
- Modify: `docs/superpowers/plans/2026-08-10-document-authoring-placement.md` (R39: 8 items)
- Modify: `docs/superpowers/plans/2026-08-07-release-notes-field-hygiene.md` (R40: 5 items)
- Modify: `/workspace/ihudak-claude-plugins/CLAUDE.md` (R10: the process rule)
- Modify: the `2026-08-12` feedback file (R44)

- [ ] **Step 1 (R10): Add the rule that would have prevented most of this task**

In `/workspace/ihudak-claude-plugins/CLAUDE.md`, under the conventions section, add:

```
- **A sub-project's verification record is written last** — after the final fix wave, never before it. Three of the 2026-08-07 round's records went stale because the record was written first; one was falsified by its own sub-project's next commit 17 minutes later. Re-derive every expected value against the tree being verified, and never copy an `expect N` from another plan — two of that round's wrong values propagated exactly that way.
```

- [ ] **Step 2 (R9): Correct F's two falsified rows**

In `2026-08-11-environment-guards-verification.md`, correct V5's recorded consumer count to **7** and V8's choice count to **3**, and append to each row a note: `superseded same-day by 7142976`. Correcting alone would erase the evidence that the record went stale; annotating alone would leave two wrong numbers standing.

- [ ] **Step 3 (R36): Fix the two bookkeeping slips**

D's V18 records a 28-line breakdown that sums to 27 — recount and correct. G's tally says 25 PASS against 27 passing rows (V11a/V11b uncounted) — correct the tally.

- [ ] **Step 4 (R37–R40): Correct the wrong `expect N` values**

For each of the four plans, correct each listed expected value **by re-deriving it against the tree at that sub-project's ship commit** — not by copying the number from the review. Where a check was wrong-target (it could never have produced its expected value on any tree), annotate it as such rather than inventing a number.

For each corrected value, record in the plan file: the old value, the new value, and the commit the new value was derived at.

- [ ] **Step 5 (R44): Annotate the superseded feedback entry**

Mark `2026-08-12-implement-broad-then-narrow-candidate` as CLOSED, pointing at `CHANGELOG.md`'s 2.50.0 entry — `/implement` adopted §8.5 there.

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -c 'verification record is written last' CLAUDE.md   # expect 1
grep -c 'superseded same-day by 7142976' docs/superpowers/plans/2026-08-11-environment-guards-verification.md   # expect 2
git diff --name-only -- plugins/   # expect NO output — no plugin content in this task
```

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/ CLAUDE.md
git commit -m "docs(superpowers): correct the round's verification-record arithmetic; adopt write-the-record-last"
```

---

## Task 14: Release 2.51.0 — CHANGELOG, version, README

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/README.md`, `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`

- [ ] **Step 1: Bump the version in both places**

`plugin.json` and the repo-root `.claude-plugin/marketplace.json` `dev-workflows` entry → `2.51.0`. **The marketplace catalog has been missed twice on this project — do not skip it.**

- [ ] **Step 2: Write the CHANGELOG entry**

Keep-a-Changelog format, bracketed heading `## [2.51.0] — 2026-08-13`. Cover: the caller-list sweep, the direct-mode reviewer-gate correction, `/document`'s inert "no refresh" choice, the two narrowed SSOT promises, `/ready`'s preflight ordering, `/release-notes`' emitter order, `/idea`'s grill cap 5 → 10, the §8.5 precedence scoping, and the cost-prose corrections. Each bullet states what was wrong and what is now true.

- [ ] **Step 3: Update the README where it states any changed claim**

Check the README for the counts and lists this sub-project changed (`emit-auto`'s twelve→thirteen, the `jira-reader` dispatcher row, the read-only-repos count) and confirm each is already correct from tasks 2 and 11, or fix it here.

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -c '"version": "2.51.0"' plugins/dev-workflows/.claude-plugin/plugin.json   # expect 1
grep -c '2.51.0' .claude-plugin/marketplace.json                                  # expect 1
head -20 plugins/dev-workflows/CHANGELOG.md | grep -c '## \[2.51.0\]'             # expect 1
python3 -c "import json;json.load(open('.claude-plugin/marketplace.json'));print('catalog parses')"
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "release(dev-workflows): 2.51.0 — whole-round review fixes"
```

---

## Task 15: Port to mgd

**Files:** `/workspace/mgd-claude-plugins/`

- [ ] **Step 1: Establish the divergence set empirically — do not assume it**

```bash
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows /workspace/mgd-claude-plugins/plugins/dev-workflows
```
Record exactly which files differ. The expected set is five (`.claude-plugin/plugin.json`, `LICENSE`, `README.md`, `CHANGELOG.md`, `references/dependencies.md`); the two repo-root files (`CLAUDE.md`, `.claude-plugin/marketplace.json`) are checked separately. **mgd's `references/dependencies.md` saying `mgd-plugins` is correct — not drift.**

- [ ] **Step 2: Copy every changed non-identity file**

Copy canonical's changed files under `plugins/dev-workflows/` into mgd, excluding the identity files. Then port the `CLAUDE.md` changes by hand (mgd's root `CLAUDE.md` is an identity file — apply the same *content* edits, keeping mgd's own identity lines). **R35's mgd half was already done in task 11 — do not redo it.**

- [ ] **Step 3: Bump mgd's version and CHANGELOG** to 2.51.0, matching canonical's entry, with mgd's "(ported from `ihudak-claude-plugins`)" convention.

- [ ] **Step 4: Verify parity**

```bash
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows /workspace/mgd-claude-plugins/plugins/dev-workflows
```
Expected: **exactly the five identity files, and zero "Only in" lines.** Any other differing file is an incomplete port.

```bash
grep -c '"version": "2.51.0"' /workspace/mgd-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json   # expect 1
grep -c '2.51.0' /workspace/mgd-claude-plugins/.claude-plugin/marketplace.json                                 # expect 1
```

- [ ] **Step 5: Commit**

```bash
git -C /workspace/mgd-claude-plugins add -A
git -C /workspace/mgd-claude-plugins commit -m "release(dev-workflows): 2.51.0 — whole-round review fixes (ported)"
```

---

## Task 16: Port to copilot

**Files:** `/workspace/ihudak-copilot-plugins/`

**NEVER `cp` into copilot.** Every file is hand-adapted. Task 12's copilot-only work and task 11's copilot half are already done — do not redo them.

- [ ] **Step 1: Enumerate what canonical changed**

```bash
git -C /workspace/ihudak-claude-plugins diff --name-only main..HEAD -- plugins/dev-workflows/ CLAUDE.md
```
For each file, find its copilot counterpart: `commands/X.md` → `skills/X/SKILL.md`; `references/X.md` → `skills/_shared/X.md`; `agents/X.md` → `agents/X.md`; root `CLAUDE.md` → `.github/copilot-instructions.md`.

- [ ] **Step 2: Hand-apply each change in copilot's dialect**

Apply the four dialect rules to every ported line: `agent_type:`, the installed-path form of reference citations, copilot's own detection chain, and **colon-form command names**.

- [ ] **Step 3: Do not forget the two depth-3 files**

`.github/plugin/marketplace.json` (catalog → `2.21.0`) and `.github/copilot-instructions.md` (the `CLAUDE.md` counterpart — port the invariant and roster corrections). **Both have been missed on this project before by a `find -maxdepth 2`.**

- [ ] **Step 4: Bump version and CHANGELOG** to `2.21.0` in `dev-workflows/.plugin/plugin.json`, `dev-workflows/CHANGELOG.md`, and `.github/plugin/marketplace.json`.

- [ ] **Step 5: Verify dialect purity and version agreement**

```bash
cd /workspace/ihudak-copilot-plugins
grep -rn 'subagent_type' dev-workflows/ | grep -v '^Binary' | wc -l          # expect 0
grep -rn 'CLAUDE_PLUGIN_ROOT' dev-workflows/ | grep -v '^Binary' | wc -l     # expect 0
grep -rn '§2.1 Sonnet' dev-workflows/ | grep -v '^Binary' | wc -l            # expect 0
grep -c '2.21.0' dev-workflows/.plugin/plugin.json .github/plugin/marketplace.json
head -20 dev-workflows/CHANGELOG.md | grep -c '2.21.0'                        # expect 1
python3 -c "import json;json.load(open('.github/plugin/marketplace.json'));print('catalog parses')"
```

Then scan **added lines only** for slash-form command names, since paths and prose lists are false positives:

```bash
git diff main..HEAD -- dev-workflows/ | grep '^+' | grep -nE '(^|[^a-z/`])/(idea|implement|document|epics|specify|design|ready|create-vi|update-vi|create-ard|release-notes|upgrade|vuln|feedback)\b'
```
Expected: no output. Read any hit before accepting it.

- [ ] **Step 6: Commit**

```bash
git -C /workspace/ihudak-copilot-plugins add -A
git -C /workspace/ihudak-copilot-plugins commit -m "release(dev-workflows): 2.21.0 — whole-round review fixes (adapted)"
```

---

## Task 17: Whole-branch verification record — written LAST

**This task is R10's first application.** It runs after every fix, every port, and every fix-wave commit. If a later fix wave lands after this record is written, **this record is rewritten**, not patched.

**Files:**
- Create: `docs/superpowers/plans/2026-08-13-whole-round-review-fixes-verification.md`

- [ ] **Step 1: Confirm you are actually last**

```bash
git -C /workspace/ihudak-claude-plugins log --oneline main..HEAD | head -20
git -C /workspace/ihudak-claude-plugins status --porcelain
```
Expected: a clean tree in all three repos, and no fix commits pending. If any fix is still open, STOP — this task cannot run yet. That is the whole point of the rule it ships.

- [ ] **Step 2: Write one row per requirement**

45 rows, `R1`–`R45`. Each row: the requirement, the command that verifies it, the expected value, the **observed** value (run it now, against this tree), and PASS/FAIL.

- [ ] **Step 3: Prove each check could fail**

For every check that is a count or a `grep -c`, confirm it returns a *different* value against the pre-fix tree:

```bash
git -C /workspace/ihudak-claude-plugins stash list   # ensure clean
# For a sample of at least 10 rows spanning all three repos, re-run the check against main:
git -C /workspace/ihudak-claude-plugins show main:CLAUDE.md > /tmp/claude-502/pre-CLAUDE.md
# then run the row's grep against /tmp/claude-502/pre-CLAUDE.md and record that it returns the OLD value
```
Expected: every sampled check returns the old value against `main` and the new value against `HEAD`. **A check returning the same value on both proves nothing** — replace it.

- [ ] **Step 4: Record the three-repo state**

For each repo: branch, HEAD SHA, version in `plugin.json`, CHANGELOG head, catalog version. All three must agree internally.

- [ ] **Step 5: State coverage honestly**

Name every requirement whose verification is a reading rather than a command, and every one you could not verify mechanically. Do not record a PASS for a check you did not run.

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/plans/2026-08-13-whole-round-review-fixes-verification.md
git commit -m "docs(superpowers): sub-project I verification record — 45 requirements across three repos"
```

---

## Self-review notes

**Spec coverage.** All 45 requirements are assigned: R1+R41 → task 12; R2 → 5; R3+R18 → 6; R4 → 7; R5+R6 → 3; R7, R16, R17, R21, R22, R25, R29–R34 → 1; R8+R45 → 4; R9, R10, R36–R40, R44 → 13; R11+R12 → 8; R13, R19, R20, R23, R24, R26–R28 → 2; R14+R42 → 10; R15+R43 → 9; R35 → 11.

**Ordering constraints.** Task 10 must run after task 4 (both edit §8.5). Tasks 15–16 must run after task 14. Task 17 must run last. Tasks 1–13 are otherwise independent and may run in any order.

**The three spec risks.** (1) The `document.md` phase move was **removed** in D6, not mitigated — task 8 step 5 asserts `document.md` does not appear in the diff. (2) R45's overflow path gets an explicit before/after proof at task 4 steps 4 and 7, with a STOP condition if the rule turns out to be coupled to the literal 5. (3) Task 1's large diff gets per-item assertions (step 3) plus a collateral-change assertion (step 4).

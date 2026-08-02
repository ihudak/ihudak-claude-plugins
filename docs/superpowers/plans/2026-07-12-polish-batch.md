---
tags:
  - tasks-exclude
---
# Polish batch + deterministic pre-lint — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship dev-workflows v2.26.0 — a deterministic structural pre-lint before the Opus reviewers plus three targeted hardening tweaks (grilling self-answer guard, vi-reviewer theater dimension, /implement context-exhaustion doc).

**Architecture:** Six tasks — (1) NEW `references/pre-lint.md` SSOT; (2) thin pre-lint phase wired into 5 reviewer-gated commands; (3) grilling guard; (4) vi-reviewer theater bullet; (5) NEW `references/context-management.md` + /implement citation; (6) manifests 2.26.0 + CHANGELOG. All markdown; no runtime code, no test framework.

**Tech Stack:** Markdown commands/agents/reference docs; JSON manifests. Verification is structural: `grep`, `python3 -c json.load`, `git diff --stat`, byte-diff, recomputed counts.

## Global Constraints

- **Commit/push only when asked.** Work on branch `ivgu/NOISSUE-polish-batch` off `main`. Per-task commits on that branch are part of the agreed execution; **pushing** is gated to the finish-branch menu.
- **Never `git add -A`.** Stage only the named files in each commit step.
- **Commit trailer** (last line, exact): `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Verify with `git log -1 --format=%B` before the first commit.
- **Version lock-step:** `plugins/dev-workflows/.claude-plugin/plugin.json` version (line 3) == the dev-workflows entry in root `.claude-plugin/marketplace.json` (**line 12 only**) == `2.26.0`. Do NOT touch sibling marketplace lines 24 (`0.2.2`) / 36 (`0.3.1`).
- **No count/description change:** 2 new reference docs, 0 new commands/agents → counts stay **20 commands / 30 agents**. Both manifest `description` fields stay byte-identical to each other and keep `Twenty slash commands` / `Thirty reusable subagents`. Do NOT edit either `description`.
- **Siblings byte-identical:** `dt-style-guide` / `obsidian-llm-wiki` → 0-line `git diff`.
- **Pre-lint is advisory** — surfaces findings, inline-fixes mechanical ones, never hard-blocks; the Opus reviewer remains the gate. **The reviewer agents are untouched by the pre-lint** — the only reviewer edited in this effort is `vi-reviewer.md`, and only for the theater dimension (Task 4).
- **No collateral:** `/vuln`, `/upgrade`, `ard-reviewer`, `spec-reviewer`, `design-reviewer`, `epic-reviewer`, and every command/agent not named in a task → 0-line diff.
- Your shell cwd resets to `/workspace/docs` between bash calls — use absolute paths / `cd` inline.
- The vault holding this plan is auto-backed-up by Obsidian Git — do NOT hand-commit vault files.

---

## Task 1: NEW `references/pre-lint.md` (the SSOT)

**Files:**
- Create: `plugins/dev-workflows/references/pre-lint.md`

**Interfaces:**
- Produces: the reference the 5 command phases (Task 2) cite. Defines per-artifact check blocks named **VI / ARD / spec / Epic / design** with exact grep patterns.

- [ ] **Step 1: Create the file** with exactly this content:

````markdown
# Structural pre-lint (embedded — shared reference)

Deterministic, grep-expressible structural checks the reviewer-gated commands run against a
just-authored artifact **before** dispatching their Opus reviewer — so an Opus review pass is not
consumed BLOCKing on mechanical structure. **Advisory:** surface findings, inline-fix the mechanical
ones, leave content gaps for the author, then proceed to the reviewer. Pre-lint **never hard-stops**
on its own; the reviewer remains the gate.

Each caller cites this file, states its **artifact type** and the **file(s)** to check, runs the
Universal checks plus its artifact-specific block, and surfaces the findings. Severities: **BLOCKER**
(missing required section, duplicate ID, stray generic placeholder), **MAJOR** (a structural rule
broken), **MINOR** (ID gap, informational count). Inline-fix only the mechanical (renumber a duplicate
ID, delete a stray placeholder token); anything needing content goes back to the author/grill.

## Universal checks (every artifact)

1. **Placeholder scan** — `grep -nE '\b(TBD|TODO|FIXME|XXX)\b|<[a-z][a-z0-9 _./-]*>' <file>`. Any hit →
   BLOCKER (a shipped artifact carries no placeholder). Does NOT flag `[NEEDS CLARIFICATION]` or
   `- [ ]` open questions — those are counted per-artifact below.
2. **Identifier integrity** — for each ID series the artifact uses (below), the numbers form a
   contiguous run from the scheme's base with no duplicates. A duplicate → BLOCKER; a gap → MINOR.
3. **Required-section presence** — every mandatory heading listed for the artifact is present
   (`grep -nF '## <heading>' <file>`). A missing required heading → BLOCKER.

## VI — `<KEY>_ValueIncrement.md` (`/create-vi`; format `vi-format.md`)

- Required headings: `## Problem`, `## Goal`, `## Target audience`, `## User Stories`,
  `## Acceptance Criteria`, `## Scope`, `## Success Metrics`.
- ID series: `[US-N]` (in `### [US-N]:` headings), `[AC-N]`, `[SM-N]` — each contiguous from 1.
- Report the count of `[NEEDS CLARIFICATION]` (a relentless-grilled VI should converge to 0; >0 → MINOR).

## ARD — `*_ARD.md` (`/create-ard`; format `ard-format.md`)

- Required headings: `## Context`, `## Grounding findings (architecture as-is)`,
  `## Architecture decisions`, `## Cross-repo / component approach`, `## Stack & invariants`,
  `## Edge cases & risks`, `## Open questions`, `## Deferred`.
- ID series: `[AD-N]` (in `### [AD-N]:` headings) — contiguous, no dupes.
- Each `### [AD-N]` block carries all three sub-fields `**Binds:**`, `**Prevents:**`, `**Rule:**`
  (a missing one → MAJOR).

## spec — `specification.md` (`/specify`; format `specification-format.md`)

- Required headings: `## Problem statement`, `## Scope`, `## User stories`; header fields
  `- **Published**:` and `- **Open questions**:`.
- ID series: `[Uxx]` (in `### [Uxx]:`) contiguous document-wide; `[ACxx]` (in `#### [ACxx]:`)
  contiguous within each story; `[TCxx]` (in `**[TCxx]:`) contiguous within each AC.
- **Open-questions header consistency:** the integer in `- **Open questions**: N` must equal the
  count of `- [ ]` items in the file (`grep -cE '^[[:space:]]*- \[ \]' <file>`). Mismatch → MAJOR.

## Epic — per-Epic file (`/epics`; template in `agents/epic-writer.md`, NOT a `*-format.md` doc)

- Required headings per Epic file: `## Goal`, `## Business value`, `## Scope`, `### In scope`,
  `### Out of scope`, `## Acceptance criteria`, `## Independent Test`, `## Dependencies`, `## Covers`,
  `## Suggested stories`, `## References`.
- Acceptance criteria are Given/When/Then bullets (`grep -nE '^- Given .*, when .*, then ' <file>`;
  a `## Acceptance criteria` section with zero G/W/T bullets → MAJOR).
- `[NEEDS CLARIFICATION]` count ≤ 3 per Epic (epic-writer cap; >3 → MAJOR).
- `## Covers` references parent-VI IDs (`US-N`/`AC-N`/`SM-N`); Epics do not mint their own criterion IDs.
- A `_coverage.md` file is present in the output dir.

## design — `design.md` (`/design`; format `design-format.md`)

- Required (core) headings: `## Context & problem`, `## Requirements coverage`,
  `## Architecture & components`, `## Interfaces / contracts`, `## Test strategy`, `## Out of scope`,
  `## Open questions`; header field `- **Open questions**:`.
- Scaled sections `## Seams`, `## Data flow`, `## Error handling & edge cases`, `## Risks & mitigations`,
  `## Migration / rollout / backward-compatibility` are present for MODERATE+ **or** replaced by a
  one-line `_N/A — <why>_`; a MODERATE+ design missing `## Seams` with no `_N/A_` → MAJOR.
- Report the `- [ ]` count under `## Open questions` (design-format requires 0 to hand off — the
  design-reviewer enforces the hard block; pre-lint only reports it).
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
test -f references/pre-lint.md && echo "EXISTS"
grep -cE '^## (VI|ARD|spec|Epic|design) ' references/pre-lint.md   # expect 5
grep -c 'Universal checks' references/pre-lint.md                   # expect >=1
grep -c 'Advisory' references/pre-lint.md                           # expect >=1 (never hard-stops)
```
Expected: `EXISTS`, `5`, `>=1`, `>=1`.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/pre-lint.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): add references/pre-lint.md deterministic structural checks

New SSOT of grep-expressible pre-review checks (universal + per-artifact for
VI/ARD/spec/Epic/design). Advisory — surfaces findings before the Opus reviewer,
never hard-blocks. Wired into the commands in the next task.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Wire the pre-lint phase into 5 reviewer-gated commands

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md` (insert before Phase 4, line 139)
- Modify: `plugins/dev-workflows/commands/create-ard.md` (insert before Phase 5, line 97)
- Modify: `plugins/dev-workflows/commands/specify.md` (insert before Phase 6, line 355)
- Modify: `plugins/dev-workflows/commands/design.md` (insert before Phase 6, line 256)
- Modify: `plugins/dev-workflows/commands/epics.md` (insert before Phase 7, line 358)

**Interfaces:**
- Consumes: `references/pre-lint.md` from Task 1 (block names VI / ARD / spec / Epic / design).
- Each insertion is an Edit: `old_string` = the reviewer phase heading line; `new_string` = the new pre-lint phase block + blank line + that same heading line.

- [ ] **Step 1: `create-vi.md` — insert Phase 3.6 before Phase 4**

`old_string`:
```markdown
## Phase 4 — Review gate
```
`new_string`:
```markdown
## Phase 3.6 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `<KEY>_ValueIncrement.md`: the
**Universal checks** plus the **VI** block. Surface every finding; inline-fix the mechanical ones
(renumber a duplicate `[US-N]`/`[AC-N]`/`[SM-N]`, delete a stray placeholder token); leave content gaps
(missing section, unresolved `[NEEDS CLARIFICATION]`) for the grill/author. **Advisory** — never blocks;
proceed to Phase 4 once findings are surfaced. `vi-reviewer` remains the gate.

## Phase 4 — Review gate
```

- [ ] **Step 2: `create-ard.md` — insert Phase 4.5 before Phase 5**

`old_string`:
```markdown
## Phase 5 — Review gate
```
`new_string`:
```markdown
## Phase 4.5 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `*_ARD.md`: the **Universal checks**
plus the **ARD** block (incl. that every `### [AD-N]` carries `**Binds:**` / `**Prevents:**` /
`**Rule:**`). Surface every finding; inline-fix the mechanical ones (renumber a duplicate `[AD-N]`,
delete a stray placeholder token); leave content gaps for the grill/author. **Advisory** — never blocks;
proceed to Phase 5 once findings are surfaced. `ard-reviewer` remains the gate.

## Phase 5 — Review gate
```

- [ ] **Step 3: `specify.md` — insert Phase 5.5 before Phase 6**

`old_string`:
```markdown
## Phase 6 — Finalize + review gate
```
`new_string`:
```markdown
## Phase 5.5 — Structural pre-lint

Before finalizing, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `specification.md`: the **Universal
checks** plus the **spec** block (incl. the `- **Open questions**: N` header equalling the `- [ ]`
count). Surface every finding; inline-fix the mechanical ones (renumber a duplicate `[Uxx]`/`[ACxx]`/
`[TCxx]`, correct the open-questions count, delete a stray placeholder token); leave content gaps for
the grill/author. **Advisory** — never blocks; proceed to Phase 6 once findings are surfaced.
`spec-reviewer` remains the gate.

## Phase 6 — Finalize + review gate
```

- [ ] **Step 4: `design.md` — insert Phase 5.5 before Phase 6**

`old_string`:
```markdown
## Phase 6 — Review gate
```
`new_string`:
```markdown
## Phase 5.5 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `design.md`: the **Universal checks**
plus the **design** block (core headings present; a MODERATE+ design has `## Seams` or a `_N/A — why_`;
report the `## Open questions` `- [ ]` count). Surface every finding; inline-fix the mechanical ones
(delete a stray placeholder token); leave content gaps for the grill/author. **Advisory** — never
blocks; proceed to Phase 6 once findings are surfaced. `design-reviewer` remains the gate (it still
enforces the open-questions hard block).

## Phase 6 — Review gate
```

- [ ] **Step 5: `epics.md` — insert Phase 6.3 before Phase 7**

(Note: this file has Phase 6.2 physically before Phase 6.1; Phase 6.1 is the last phase before Phase 7 in file order. `6.3` is numerically free and sorts after both.)

`old_string`:
```markdown
## Phase 7 — Epic review gate
```
`new_string`:
```markdown
## Phase 6.3 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against each drafted Epic file: the **Universal checks**
plus the **Epic** block (required headings incl. `## Independent Test`; Given/When/Then acceptance
criteria; `[NEEDS CLARIFICATION]` ≤ 3 per Epic; `_coverage.md` present). Surface every finding;
inline-fix the mechanical ones (delete a stray placeholder token); leave content gaps for the author.
**Advisory** — never blocks; proceed to Phase 7 once findings are surfaced. `epic-reviewer` remains the
gate.

## Phase 7 — Epic review gate
```

- [ ] **Step 6: Verify all 5 wired**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -l 'pre-lint.md' commands/create-vi.md commands/create-ard.md commands/specify.md commands/design.md commands/epics.md
echo "--- new phase headings ---"
grep -n '## Phase 3.6 — Structural pre-lint' commands/create-vi.md
grep -n '## Phase 4.5 — Structural pre-lint' commands/create-ard.md
grep -n '## Phase 5.5 — Structural pre-lint' commands/specify.md
grep -n '## Phase 5.5 — Structural pre-lint' commands/design.md
grep -n '## Phase 6.3 — Structural pre-lint' commands/epics.md
echo "--- each pre-lint phase precedes its reviewer phase ---"
for f in create-vi:4 create-ard:5 specify:6 design:6 epics:7; do :; done
grep -n '## Phase' commands/create-vi.md | grep -E '3.6|Phase 4 —'
```
Expected: all 5 filenames listed; each new heading found once; the pre-lint phase line number is less than its reviewer phase line number in every file.

- [ ] **Step 7: Confirm reviewer agents untouched**

```bash
cd /workspace/ihudak-claude-plugins
git diff --stat main -- plugins/dev-workflows/agents/ard-reviewer.md plugins/dev-workflows/agents/spec-reviewer.md plugins/dev-workflows/agents/design-reviewer.md plugins/dev-workflows/agents/epic-reviewer.md plugins/dev-workflows/agents/vi-reviewer.md
```
Expected: empty (no reviewer agent changed in this task).

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/create-ard.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md plugins/dev-workflows/commands/epics.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): run deterministic pre-lint before the Opus reviewers

Add a thin advisory Structural pre-lint phase to create-vi (3.6), create-ard
(4.5), specify (5.5), design (5.5), and epics (6.3), each citing
references/pre-lint.md and running the universal + artifact-specific checks
immediately before the reviewer dispatch. Reviewer agents unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Grilling self-answer guard

**Files:**
- Modify: `plugins/dev-workflows/references/grilling-technique.md` (insert between `## Mechanics` end, line 14, and `## Depth`, line 16)

**Interfaces:**
- Consumes nothing. Adds one subsection; the `## Mechanics` bullets (lines 10–14) and `## Depth` (line 16+) are unchanged.

- [ ] **Step 1: Insert the guard**

`old_string`:
```markdown
## Depth (the caller chooses)
```
`new_string`:
```markdown
## Autonomous / background invocation

When the command runs with **no human turn available** to answer (autonomous or background
invocation), do NOT fabricate answers to genuine **decision** questions. The fact-vs-decision split
still holds — facts you resolve yourself — but a genuine decision that would otherwise go to the user
is **recorded as an open question** (`[NEEDS CLARIFICATION]` for bounded callers, `- [ ]` for relentless
callers) rather than self-answered. Never grill yourself into a fabricated decision.

## Depth (the caller chooses)
```

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n 'Autonomous / background invocation' references/grilling-technique.md
grep -n 'Fact-vs-decision split' references/grilling-technique.md   # still present (line ~12)
grep -n '## Depth (the caller chooses)' references/grilling-technique.md
```
Expected: the new heading present; the fact-vs-decision line still present; the Depth heading still present (now after the new subsection).

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/grilling-technique.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): grilling guard against self-answering in background runs

When no human turn is available, genuine decisions are recorded as open
questions ([NEEDS CLARIFICATION] / - [ ]) rather than self-answered. Complements
the existing fact-vs-decision split.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: vi-reviewer theater dimension

**Files:**
- Modify: `plugins/dev-workflows/agents/vi-reviewer.md` (add a bullet after line 37, before line 38 "Identifier integrity")

**Interfaces:**
- Adds one dimension bullet to the `## Dimensions` list; all other bullets unchanged.

- [ ] **Step 1: Insert the hollow-prose theater bullet**

`old_string`:
```markdown
- **Identifier integrity:** `[US-N]`/`[AC-N]`/`[SM-N]` unique + contiguous; cross-references point at existing IDs.
```
`new_string`:
```markdown
- **Substance over theater (hollow prose):** a section that is non-empty but states no testable commitment, decision, or constraint — vision/persona/NFR prose that reads well yet does no work → `MAJOR` ("reads well, does no work"), the same bar as the empty/boilerplate case above.
- **Identifier integrity:** `[US-N]`/`[AC-N]`/`[SM-N]` unique + contiguous; cross-references point at existing IDs.
```

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n 'Substance over theater (hollow prose)' agents/vi-reviewer.md
grep -c '^- \*\*' agents/vi-reviewer.md   # dimension bullet count rose by exactly 1
```
Expected: new bullet present; count is the prior count + 1.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/vi-reviewer.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): vi-reviewer flags well-written-but-hollow prose

Extend the substance-over-theater coverage from empty/boilerplate sections to
non-empty sections that state no testable commitment, decision, or constraint
(vision/persona/NFR that reads well but does no work) -> MAJOR.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: NEW `references/context-management.md` + /implement citation

**Files:**
- Create: `plugins/dev-workflows/references/context-management.md`
- Modify: `plugins/dev-workflows/commands/implement.md` (Phase 3B, after the intro line 407)

**Interfaces:**
- `/implement` Phase 3B cites the new doc for long step lists.

- [ ] **Step 1: Create `references/context-management.md`** with exactly this content:

````markdown
# Long-run context management (embedded — shared reference)

Strategies for an implementation run whose step list is too long to complete in one context window
without degrading. Apply when the plan/step list is large or the run is nearing its context budget.

- **Scope-to-N** — implement the first N steps, **checkpoint** (commit the working increment + report
  progress), then continue from N+1. The commit history is the durable progress map.
- **Sub-agent-per-`[P]`** — for steps marked parallel-safe (`[P]`) or otherwise independent, dispatch a
  fresh subagent per step so their work never enters the orchestrator's context; the orchestrator only
  integrates the results.
- **Decompose** — if the remaining work is too large even with checkpoints, split it into independently
  shippable units and finish the current unit before starting the next.

Prefer the cheapest strategy that fits: checkpoint first; offload parallel steps only when they are
genuinely independent; decompose only when a single unit still overflows.
````

- [ ] **Step 2: Cite it from `/implement` Phase 3B**

`old_string`:
```markdown
Use the currently selected model or Sonnet for implementation itself. Opus is reserved for the review.
```
`new_string`:
```markdown
Use the currently selected model or Sonnet for implementation itself. Opus is reserved for the review.

For a long step list, apply `${CLAUDE_PLUGIN_ROOT}/references/context-management.md` — checkpoint at N,
offload parallel-safe (`[P]`) steps to subagents, or decompose — so the run does not degrade as context fills.
```

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
test -f references/context-management.md && echo "EXISTS"
grep -n 'context-management.md' commands/implement.md
grep -n 'Scope-to-N' references/context-management.md
```
Expected: `EXISTS`; the citation appears in Phase 3B of implement.md; `Scope-to-N` present.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/context-management.md plugins/dev-workflows/commands/implement.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): context-exhaustion strategy for long /implement runs

New references/context-management.md (scope-to-N / sub-agent-per-[P] /
decompose); /implement Phase 3B cites it for long step lists.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Version bump (lock-step) + CHANGELOG

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (line 3)
- Modify: `.claude-plugin/marketplace.json` (line 12 only)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (insert before line 7)

- [ ] **Step 1: Bump `plugin.json`** — replace `  "version": "2.25.0",` with `  "version": "2.26.0",` (do NOT touch `description`).

- [ ] **Step 2: Bump the dev-workflows entry in `marketplace.json`** — change **only line 12** `      "version": "2.25.0",` to `      "version": "2.26.0",`. Leave lines 24 (`0.2.2`) and 36 (`0.3.1`) untouched.

- [ ] **Step 3: Add the CHANGELOG entry** — insert immediately before `## [2.25.0] — 2026-07-12`:

`old_string`:
```markdown
## [2.25.0] — 2026-07-12
```
`new_string`:
```markdown
## [2.26.0] — 2026-07-12

### Added

- **`references/pre-lint.md`** — new SSOT of deterministic, grep-expressible structural checks (universal + per-artifact for VI/ARD/spec/Epic/design). A thin advisory **Structural pre-lint** phase now runs immediately before the Opus reviewer in `/create-vi` (3.6), `/create-ard` (4.5), `/specify` (5.5), `/design` (5.5), and `/epics` (6.3): it surfaces mechanical defects (missing sections, duplicate/gapped IDs, stray placeholders, ARD `Binds`/`Prevents`/`Rule`, spec open-questions-count) and inline-fixes the trivial ones so an Opus pass is not consumed on structure. Advisory — never hard-blocks; the reviewers remain the gate and are unchanged.
- **`references/context-management.md`** — new long-run strategy doc (scope-to-N / sub-agent-per-`[P]` / decompose); `/implement` Phase 3B cites it for long step lists.

### Changed

- **Grilling technique** — added an "Autonomous / background invocation" guard: with no human turn available, genuine decisions are recorded as open questions (`[NEEDS CLARIFICATION]` / `- [ ]`) rather than self-answered.
- **`vi-reviewer`** — the substance-over-theater dimension now also flags non-empty-but-hollow prose (vision/persona/NFR that reads well but states no testable commitment) as `MAJOR`.

### Notes

- Polish batch from the AI-First line-85 borrow analysis. 2 new reference docs, 0 new commands/agents — counts unchanged (20 commands / 30 subagents), descriptions byte-identical. No-regression: `/vuln`, `/upgrade`, the four other reviewer agents, and the sibling plugins are untouched. (Items "/idea URL-fetch policy" and "/specify seam step" were dropped — no live fetch exists in `/idea`, and the seam concept already lives in `/design`.)

## [2.25.0] — 2026-07-12
```

- [ ] **Step 4: Verify manifests, counts, descriptions**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "
import json
pj=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))
mp=json.load(open('.claude-plugin/marketplace.json'))
def walk(o):
    if isinstance(o,list):
        for x in o: yield from walk(x)
    elif isinstance(o,dict):
        if o.get('name')=='dev-workflows': yield o
        for v in o.values(): yield from walk(v)
me=next(walk(mp))
sib={p['name']:p['version'] for p in walk(mp)} if False else None
assert pj['version']==me['version']=='2.26.0', 'version mismatch'
assert pj['description']==me['description'], 'description drift'
assert 'Twenty slash commands' in pj['description'] and 'Thirty reusable subagents' in pj['description'], 'count-string changed'
print('OK lock-step 2.26.0, descriptions byte-identical, count-strings intact')
"
# siblings untouched
python3 -c "
import json
mp=json.load(open('.claude-plugin/marketplace.json'))
def walk(o):
    if isinstance(o,list):
        for x in o: yield from walk(x)
    elif isinstance(o,dict):
        if 'name' in o and 'version' in o: yield o
        for v in o.values(): yield from walk(v)
v={p['name']:p['version'] for p in walk(mp)}
assert v.get('dt-style-guide')=='0.2.2' and v.get('obsidian-llm-wiki')=='0.3.1', v
print('OK siblings 0.2.2 / 0.3.1 untouched')
"
echo "commands: $(ls plugins/dev-workflows/commands/*.md | wc -l | tr -d ' ')  agents: $(ls plugins/dev-workflows/agents/*.md | wc -l | tr -d ' ')"
```
Expected: `OK lock-step 2.26.0 …`, `OK siblings …`, `commands: 20  agents: 30`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
chore(dev-workflows): release v2.26.0 — polish batch + deterministic pre-lint

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final structural verification (before finish-branch)

```bash
cd /workspace/ihudak-claude-plugins
echo "=== files changed vs main (expect 13: 2 new refs + grilling ref + 6 commands + vi-reviewer + 2 manifests + CHANGELOG) ==="
git diff --stat main...HEAD
echo "=== siblings 0-line diff ==="
git diff --stat main...HEAD -- plugins/dt-style-guide plugins/obsidian-llm-wiki
echo "=== no collateral (expect empty) ==="
git diff --stat main...HEAD -- plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/agents/ard-reviewer.md plugins/dev-workflows/agents/spec-reviewer.md plugins/dev-workflows/agents/design-reviewer.md plugins/dev-workflows/agents/epic-reviewer.md
echo "=== 5 commands cite pre-lint.md; implement cites context-management.md ==="
grep -l 'pre-lint.md' plugins/dev-workflows/commands/*.md
grep -l 'context-management.md' plugins/dev-workflows/commands/*.md
```
Expected: **13** files changed (`references/pre-lint.md` + `references/context-management.md` new; `references/grilling-technique.md`, `commands/create-vi/create-ard/specify/design/epics/implement.md`, `agents/vi-reviewer.md` edited; `plugin.json` + `marketplace.json`; `CHANGELOG.md`); siblings + collateral empty; the 5 reviewer-gated commands cite `pre-lint.md`; only `implement.md` cites `context-management.md`.

Then hand off to **superpowers:finishing-a-development-branch** for the merge/PR choice (no test suite; structural verification above is the gate).

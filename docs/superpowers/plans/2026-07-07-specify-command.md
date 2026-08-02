---
tags:
  - tasks-exclude
---

# `/specify` Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/specify` command to the dev-workflows plugin — a Jira- and code-grounded grilling
command that authors an org-standard `specification.md` and lands it on the specs repo's main branch
(via branch + PR) for the dev `/design` take-over.

**Architecture:** A Markdown command orchestrator (`commands/specify.md`) that reuses the shared
`jira-input-resolution` front-end, `jira-reader`, `code-scanner`, `model-routing`, and
`escalation-rules`, embeds the grilling interview technique inline, and owns the specification format
via a new `references/specification-format.md` (imported snapshot) + a new Opus-pinned
`agents/spec-reviewer.md` + an imported `scripts/specification-to-html.py`. No runtime dependency on
the specs repo's `.claude`.

**Tech Stack:** Markdown command/agent/reference files, one imported Python 3.8+ stdlib script, JSON
manifests. **No test framework, no husky/prettier hook** — verification is STRUCTURAL (grep anchors,
`python3 -c json.load`, `python3 -c ast.parse`, a script smoke-run, byte-diff review).

## Global Constraints

- Base repo: `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`. Branch off `main`.
- Version bump **MINOR**: `2.3.1 → 2.4.0`, lock-step across `plugins/dev-workflows/.claude-plugin/plugin.json` `version`, `.claude-plugin/marketplace.json` `plugins[0].version`, and a new `CHANGELOG.md` block. Siblings `dt-style-guide` (`0.2.2`) and `obsidian-llm-wiki` (`0.3.1`) MUST stay untouched.
- CHANGELOG: prepend above `## [2.3.1] — 2026-07-02`, em-dash date `2026-07-07`, preserve history.
- Commit trailer (every commit): `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Never `git add -A`** — stage only the files each task names. Never stage `.superpowers/` or `.docstack`.
- No external network/API calls in command/agent logic (matches existing commands).
- `/specify` is **jira-driven only** — rejects `mode: direct`.
- The command writes `Published: no` and **never** sets `Published: yes` (human-only).
- Provenance: `specification-format.md`, `spec-reviewer.md`, `specification-to-html.py` are one-time
  snapshots imported from `mgd-specifications` (`/workspace/specs/.claude/…`); each carries a provenance
  note. No runtime dependency on that repo's `.claude`.
- Design doc (source of truth for behavior): `…/spec/2026-07-07-specify-command-design.md` (this vault).

## File Structure

**New files:**
- `plugins/dev-workflows/references/specification-format.md` — the embedded format authority: header/template, the five stages' distilled drafting+validation rules, EARS patterns, ID conventions, provenance. *(Task 1)*
- `plugins/dev-workflows/agents/spec-reviewer.md` — Opus-pinned whole-spec reviewer, adapted from `review-specification`; emits `BLOCKER/MAJOR/MINOR/NIT` + `PASS / PASS WITH RECOMMENDATIONS / BLOCK`. *(Task 2)*
- `plugins/dev-workflows/scripts/specification-to-html.py` — verbatim import + provenance header. *(Task 3)*
- `plugins/dev-workflows/commands/specify.md` — the orchestrator (Phases 0–7, embedded grilling). *(Task 4)*

**Modified files (packaging):** *(Task 5)*
- `plugins/dev-workflows/.claude-plugin/plugin.json` — version + description counts/list.
- `.claude-plugin/marketplace.json` — dev-workflows `plugins[0].version`.
- `plugins/dev-workflows/CHANGELOG.md` — prepend `## [2.4.0]`.
- `README.md` (repo root) — add `/specify` to the command list.
- `plugins/dev-workflows/README.md` — add `/specify` to the command list + `spec-reviewer` to the subagent table.

Task order: 1 → 2 → 3 → 4 → 5. Task 4 consumes the anchors created in 1–3; Task 5 packages everything.

---

### Task 1: `references/specification-format.md` (+ branch)

**Files:**
- Create: `plugins/dev-workflows/references/specification-format.md`

**Interfaces:**
- Produces: the format authority that `commands/specify.md` (Task 4) cites at
  `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`, and that `agents/spec-reviewer.md`
  (Task 2) cites as its rule source. Section anchors other tasks rely on: `## Header`,
  `## Stage 1 — Problem statement`, `## Stage 2 — Scope`, `## Stage 3 — User stories`,
  `## Stage 4 — Acceptance criteria (EARS)`, `## Stage 5 — Test cases`, `## Identifier conventions`,
  `## Provenance`.

- [ ] **Step 1: Branch**

```bash
cd /workspace/ihudak-claude-plugins && git checkout main && git pull && git checkout -b ivgu/NOISSUE-specify-command
```

- [ ] **Step 2: Author `references/specification-format.md`**

Create the file with EXACTLY these sections. Content is distilled verbatim from the source stage
skills (`/workspace/specs/.claude/skills/specification-*`); transcribe the rules below (do not invent
new ones).

````markdown
# Specification format (embedded authority)

The canonical structure and per-stage rules for a product `specification.md`. `/specify` authors
against this file; `spec-reviewer` reviews against it. This is an embedded snapshot — see Provenance.

## Header

```
# Specification

- **Feature name**: <human-readable feature name>
- **Version**: 1
- **Created**: <YYYY-MM-DD>
- **Author**: <whoami>
- **Published**: no
- **Open questions**: <N>
```

Rules: `Published` starts `no` (only a human sets `yes`). `Open questions` must equal the count of
`- [ ]` items across all "Open questions" sub-headings. Sections appear in stage order:
Problem statement → Scope → User stories (with nested Acceptance criteria → Test cases).

## Stage 1 — Problem statement

`## Problem statement` — who is affected and the problem today; why the current situation is
insufficient; why solving it matters now (business/user impact). Validation:
- Solution-free (describe the problem, not the fix).
- ≤ 1500 characters (excluding the Open questions sub-heading + items).
- No technology/implementation details.
- Infer reasonable defaults; raise genuine uncertainty as `- [ ]` under an `### Open questions`
  sub-heading (omit the sub-heading if none). Never fabricate specifics.

## Stage 2 — Scope

`## Scope` with **In scope** and **Out of scope** lists. Validation:
- In scope: ≥ 1 delivered behaviour (or `- [ ] What must this feature deliver?`); *what*, not *how*
  (no SDK classes/internal APIs/DB tables/code paths unless the problem statement requires them as
  constraints); ordered by contribution to the problem.
- Out of scope: only meaningful, confusable exclusions; ordered by confusability. Don't invent
  exclusions to fill the list.
- Coverage scan (drafting aid): configuration lifecycle; runtime lifecycle; failure states;
  paired-state transitions (every state-changing behaviour needs an inverse/recovery, an explicit
  exclusion, or an open question); cardinality; sensitive data; customer visibility.
- `### Open questions` only for unclear include/exclude boundaries; omit if none.

## Stage 3 — User stories

`## User stories`; each `### [U01]: <title>` … `### [U02]: <title>` (incrementing, contiguous),
separated by `---`, in the form `As a [role], I want [capability], so that [benefit].` Validation:
- Answers who (specific role, not "the user"/"everyone"), what (concrete capability), why
  (observable/measurable benefit), and how completion is verifiable.
- Split stories combining unrelated capabilities; merge stories too thin to verify independently.
- No implementation detail; replace vague verbs (support/manage/handle/surface) with concrete
  behaviour (displayed/stored/rejected/transmitted/recorded/changed).
- Ordered by contribution to the problem (core-value story first, then supporting, then
  lifecycle/visibility/auditability).
- `### Open questions` per story only for assumptions/decisions needing stakeholder input; omit if none.

## Stage 4 — Acceptance criteria (EARS)

Under each user story, `#### [AC01]: <title>` … (AC numbering restarts at `AC01` per story,
contiguous). One EARS statement each. Order by how directly each verifies the story's core benefit
(primary outcome first, then supporting, then failure/edge, then auditability). EARS patterns
(mandatory verb `shall`):
- **Ubiquitous:** `The [system] shall [response].`
- **Event-driven:** `When [preconditions] [trigger], the [system] shall [response].`
- **State-driven:** `While [state], the [system] shall [response].` (`During` = synonym.)
- **Optional feature:** `Where [feature is included], the [system] shall [response].` (build/licence
  optionality only — NOT user preferences, which are `While`.)
- **Unwanted behaviour:** `If [preconditions] [unwanted condition], then the [system] shall [response].`
- **Compound:** combine two of the above; use sparingly.
Validation:
- Uses `shall`; `[system]` names a specific component (not "the system"); `[response]` is measurable
  with a concrete verb.
- Display criteria (status/details/errors/summaries) name the exact fields shown (e.g. outcome,
  timestamp, failure message, acting user, identifier, change type).
- No implementation *how*; split any criterion with `and` between two verbs; `While` for runtime
  state, `Where` for static/data conditions.
- AC-level `Open questions` under the criterion; story-level after the last AC.

## Stage 5 — Test cases

Under each AC, `##### Test cases` with `**[TC01]: <title> — <Category>:**` (TC numbering restarts at
`TC01` per AC, contiguous). Category ∈ `Happy path` / `Negative / boundary` / `State / lifecycle` /
`Security / privacy` / `Audit / observability`, chosen by what the expected result verifies (not by
position). Each test: **Preconditions**, **Steps** (numbered), **Expected result** (single pass/fail
outcome asserting the *parent* AC's behaviour, reusing the AC's exact terms). Validation:
- ≥ 1 happy-path AND ≥ 1 negative/boundary per AC; add state/lifecycle, security/privacy,
  audit/observability where the criterion warrants.
- Self-contained (own preconditions/data; never depends on another test's outcome).
- Ordered within an AC by criticality (primary success first).
- Open questions: `- *Open questions:* [q]` on a test, or an `Open questions` sub-heading for broader
  items.

## Identifier conventions

`[Uxx]` unique+contiguous document-wide; `[ACxx]` unique+contiguous within each story; `[TCxx]`
unique+contiguous within each AC. After `Published: yes`, IDs are contracts — never silently
change/remove; changes are traced via the specs repo's change-management (human-run).

## Provenance

Snapshot imported from `mgd-specifications` `.claude/skills/specification-*` on 2026-07-07. Embedded
so `/specify` is self-sufficient (no runtime dependency on that repo). Re-sync manually if the source
format changes.
````

- [ ] **Step 3: Verify Task 1 (structural)**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/references/specification-format.md
echo -n "stages present (expect 5) -> "; grep -cE "^## Stage [1-5] — " "$F"
echo -n "EARS patterns (expect >=5 'shall') -> "; grep -c "shall" "$F"
echo -n "ID conventions -> "; grep -c "Identifier conventions" "$F"
echo -n "provenance -> "; grep -c "Snapshot imported from .mgd-specifications" "$F"
echo -n "Published rule -> "; grep -c "only a human sets" "$F"
```
Expected: `5`, `>=5`, `1`, `1`, `1`.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/specification-format.md
git commit -m "specify: add embedded specification-format reference

Imported+distilled snapshot of the mgd-specifications stage rules (template,
5 stages, EARS, ID conventions) so /specify owns the format with no runtime
dependency on that repo's .claude.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `agents/spec-reviewer.md`

**Files:**
- Create: `plugins/dev-workflows/agents/spec-reviewer.md`

**Interfaces:**
- Consumes: `references/specification-format.md` (Task 1) as its rule source.
- Produces: an agent dispatched from `commands/specify.md` Phase 6 as
  `subagent_type: "dev-workflows:spec-reviewer"`. Input: one `specification.md` path. Output: findings
  in the `BLOCKER/MAJOR/MINOR/NIT` schema + a single verdict `PASS` / `PASS WITH RECOMMENDATIONS` /
  `BLOCK` (matches `epic-reviewer`/`doc-reviewer` so the Phase 6 fix loop can act on it).

- [ ] **Step 1: Author `agents/spec-reviewer.md`**

Adapt `review-specification` (`/workspace/specs/.claude/agents/review-specification.md`) with these
REQUIRED deltas: (a) frontmatter `model: opus` (pinned) + `tools: ["Read","Glob","Grep","LS"]`;
(b) rule source is `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md` (NOT the specs repo's
`.claude/skills/*`); (c) verdict schema is `BLOCKER/MAJOR/MINOR/NIT` + `PASS / PASS WITH
RECOMMENDATIONS / BLOCK`.

```markdown
---
name: spec-reviewer
description: Reviews a product specification.md authored by /specify for per-stage quality (problem/scope/user-stories/acceptance-criteria/test-cases), cross-stage consistency, coverage, and identifier integrity. Read-only; returns findings + a PASS / PASS WITH RECOMMENDATIONS / BLOCK verdict. Uses Claude Opus.
model: opus
tools: ["Read", "Glob", "Grep", "LS"]
---

Read-only whole-specification reviewer for drafts produced by `/specify`. Uses the strongest available
reasoning model (Claude Opus). Reads the **whole** `specification.md` and checks it against the
per-stage rules in `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md` plus the cross-stage
checks below. Never edits the specification.

Invoked from `/specify` Phase 6 after authoring. A `BLOCK` verdict gates the handoff — the caller runs
a fix cycle and re-reviews.

## Input contract

The caller passes:
- **Specification path** — absolute path to the `specification.md`. Required; if absent, stop and report.
- **Detected maturity** — normally `test` (full spec). Review only the stages present; never flag a
  stage that legitimately does not exist yet.

## Review method

1. Read the specification end-to-end before judging.
2. Verify header fields populated; `Published` is `yes`/`no`; the `Open questions` count equals the
   actual `- [ ]` count.
3. For each stage present, apply every validation rule for that stage from
   `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`.
4. Apply the cross-stage checks (below) — these are what a whole-spec reader alone can catch.
5. Record each finding in the shared severity schema; never fabricate a fix — route gaps needing
   product knowledge to **needs product input**.

## Cross-stage checks

- **Structure:** `## User stories` uses `### [Uxx]: <title>` + `As a … I want … so that …`. Any
  `## Requirements`/`[Rxx]`/embedded `**User Story:**` label → `BLOCKER` (must convert).
- **Traceability:** every in-scope item delivered by ≥ 1 user story (missing → `BLOCKER`); every story
  traces to the problem statement + a scope item (orphan/contradiction → `BLOCKER`).
- **Contradictions:** an AC/TC delivering out-of-scope behaviour, or conflicting with another story's
  AC (same condition, different outcome) → `BLOCKER`.
- **Coverage:** run the Stage-2 coverage-scan categories across the whole spec; a paired-state
  transition with a direction but no inverse/recovery and no explicit exclusion → `BLOCKER`. Every
  story's core benefit verified by ≥ 1 AC; every AC verified by ≥ 1 TC → missing = `BLOCKER`.
- **Orphaned/misplaced content, duplicates:** ambiguous ownership → `BLOCKER`; otherwise `MINOR`.
- **Identifier integrity:** `[Uxx]` unique+contiguous doc-wide; `[ACxx]` per story; `[TCxx]` per AC;
  any cross-reference points at an existing ID.
- **Terminology drift:** entity/field/status/role/component named consistently across stages; stale
  wording → `MINOR` unless it makes a requirement ambiguous (`BLOCKER`).
- **Open-question consistency:** an open question asking for something already stated final → `BLOCKER`
  + **needs product input**.

## Output contract

Return only findings, no preamble, ordered `BLOCKER` → `MAJOR` → `MINOR` → `NIT`:

```
[BLOCKER|MAJOR|MINOR|NIT] — <Section or Uxx/ACxx/TCxx>
Violation: <what rule is broken and where>
Fix: <concrete recommendation, or "needs product input">
```

Then a final line — the verdict:
- `PASS` — no findings above MINOR.
- `PASS WITH RECOMMENDATIONS` — MAJOR/MINOR/NIT only, no BLOCKER.
- `BLOCK` — at least one BLOCKER.

If nothing is actionable, say so and state the detected maturity stage.

## Gotchas

- `Where` vs `While`: only flag `Where` when it stands in for a runtime state/preference; it is valid
  for static data conditions.
- Test-case steps may describe how to exercise the system (send a request, click a button) — that is
  NOT the "describes implementation" defect that applies to acceptance criteria.
```

- [ ] **Step 2: Verify Task 2 (structural)**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/agents/spec-reviewer.md
echo -n "model opus pin -> "; grep -c "^model: opus$" "$F"
echo -n "cites embedded format ref -> "; grep -c 'references/specification-format.md' "$F"
echo -n "NO runtime specs-repo .claude dep (expect 0) -> "; grep -c '.claude/skills/specification' "$F"
echo -n "verdict schema -> "; grep -cE "PASS WITH RECOMMENDATIONS|BLOCK" "$F"
python3 - "$F" <<'PY'
import sys,re
t=open(sys.argv[1]).read()
fm=t.split('---')[1]
assert 'name: spec-reviewer' in fm and 'model: opus' in fm, "frontmatter"
print("frontmatter OK")
PY
```
Expected: `1`, `>=1`, `0`, `>=2`, `frontmatter OK`.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/spec-reviewer.md
git commit -m "specify: add Opus-pinned spec-reviewer agent

Adapted from mgd-specifications review-specification; reviews against the
embedded specification-format reference (no runtime specs-repo dependency);
emits BLOCKER/MAJOR/MINOR/NIT + PASS/PASS WITH RECOMMENDATIONS/BLOCK.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Import `scripts/specification-to-html.py`

**Files:**
- Create: `plugins/dev-workflows/scripts/specification-to-html.py`

**Interfaces:**
- Produces: a script `commands/specify.md` Phase 6 invokes as
  `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/specification-to-html.py" <spec.md>` → writes `<spec>.html`
  alongside.

- [ ] **Step 1: Copy the script verbatim + prepend provenance**

```bash
cd /workspace/ihudak-claude-plugins
mkdir -p plugins/dev-workflows/scripts
cp /workspace/specs/.claude/skills/specification-to-html/scripts/specification-to-html.py \
   plugins/dev-workflows/scripts/specification-to-html.py
```

Then insert a provenance comment block immediately AFTER the module docstring (do not alter code).
The block:

```python
# Provenance: verbatim snapshot from mgd-specifications
# .claude/skills/specification-to-html/scripts/specification-to-html.py, imported 2026-07-07.
# Embedded so /specify is self-sufficient (no runtime dependency on that repo). Re-sync manually.
```

- [ ] **Step 2: Verify Task 3 (syntax + smoke run + provenance)**

```bash
cd /workspace/ihudak-claude-plugins
S=plugins/dev-workflows/scripts/specification-to-html.py
python3 -c "import ast,sys; ast.parse(open('$S').read()); print('parses OK')"
grep -c "Provenance: verbatim snapshot from mgd-specifications" "$S"   # expect 1
# smoke run on a tiny spec:
T=$(mktemp -d); printf '# Specification\n\n- **Feature name**: X\n\n## Problem statement\n\nSmoke.\n' > "$T/specification.md"
python3 "$S" "$T/specification.md" && test -f "$T/specification.html" && echo "HTML render OK"; rm -rf "$T"
```
Expected: `parses OK`, `1`, `HTML render OK`.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/scripts/specification-to-html.py
git commit -m "specify: import specification-to-html renderer

Verbatim snapshot from mgd-specifications with a provenance header.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `commands/specify.md` — the orchestrator

**Files:**
- Create: `plugins/dev-workflows/commands/specify.md`
- Reference (read as the structural template, do not modify): `plugins/dev-workflows/commands/epics.md`

**Interfaces:**
- Consumes: `references/jira-input-resolution.md`, `references/specification-format.md` (Task 1),
  `agents/spec-reviewer.md` (Task 2), `scripts/specification-to-html.py` (Task 3),
  `references/model-routing/classification.md`, `references/escalation-rules.md`, `agents/jira-reader.md`,
  `agents/code-scanner.md`.
- Produces: the `/specify` command surface.

Build the file section by section. **Mirror `commands/epics.md`** for connective phrasing and the
dispatch-block style (`→ Agent (subagent_type: "…", model: \`<…>\`): > "…"`); fill the `/specify`
deltas below. Every phase heading is a required anchor.

- [ ] **Step 1: Frontmatter + intro**

```markdown
---
name: specify
description: Jira-driven specification-authoring workflow (PM phase). Reads a Jira Epic/VI from exported markdown, lightly grounds in code, and authors an org-standard specification.md through a relentless one-question-at-a-time grill; gates on the Opus spec-reviewer and lands the spec on the specs repo's main branch via branch + PR for the /design dev take-over.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Author a product specification for the Jira item: $ARGUMENTS

`/specify` is the **PM-phase specification-authoring** workflow — phase 1 of the PM→Dev pipeline
(`/specify` → `specification.md`; then `/design` → `design.md` + `plan.md`). Given a Jira Epic (or VI)
key or an imported-Jira directory, it reads the item from pre-exported markdown, lightly scans code to
ground feasibility, and authors an org-standard `specification.md` through a relentless
one-question-at-a-time grill — resolving open questions live instead of stopping. It gates on the
Opus `spec-reviewer` and offers to land the spec on the specs repo's main branch (via branch + PR) as
`Published: no`.

Key distinction from `/epics`: `/epics` *splits* a VI into Epic drafts; `/specify` *authors one
specification* for a single item (typically an Epic). Run `/epics` first, then `/specify` per Epic.
```

- [ ] **Step 2: Phase 0 — Resolve input (mirror epics Phase 0)**

Cite `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`; jira-driven only; on `mode: direct`
stop with `SPECIFY_NEEDS_JIRA: /specify needs a Jira key or an imported-Jira directory.` Resolve the
feature folder `$SPECS_PATH/specifications/<KEY>_<slug>/` (honor an existing folder if present; tolerate
`-`/`_` after the key; derive `<slug>` kebab-case from the item title). If `$SPECS_PATH` is unset, stop
with a clear error naming `SPECS_PATH`. If a `_session.md` exists in the folder → offer **resume**
(read it back, skip settled stages/questions) vs **fresh**.

```markdown
## Phase 0 — Resolve input
```

- [ ] **Step 3: Phase 1 (config) + Phase 1.5 (classify + model_routing)**

Phase 1: confirm the feature folder; repo-refresh policy (default fetch + pull default branch, matching
`code-scanner`); resume-vs-fresh. Phase 1.5: invoke the `model-routing` skill; classify (typically
MODERATE); emit this block:

```markdown
## Phase 1 — Configure

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then classify as `SIMPLE` / `MODERATE` / `SIGNIFICANT` / `HIGH-RISK`. Specification authoring is typically **MODERATE**. Resolve per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible for large/cross-cutting VIs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader, code-scanner
  review_model:    <§2 Opus chain>     # spec-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + specification.md authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (interactive judgment — not a delegated subagent), consistent with the model-routing SSOT. If no Opus is available, `spec-reviewer` falls to the Sonnet floor — record the degradation in `notes` and the final report.
```

- [ ] **Step 4: Phase 2 — Read Jira (`depth: full`) + seed `idea.md`**

```markdown
## Phase 2 — Read Jira
```

Dispatch `jira-reader` at `depth: full` (`subagent_type: "dev-workflows:jira-reader"`, `model:
\`<detection_model — §2.1 Sonnet chain>\``): read the passed item + its full linked subtree
(Stories/Sub-tasks — the detail that becomes user stories/AC/TC). Extract capability themes and
component/product mentions. Write `idea.md` in the feature folder from the Jira text (provenance).

- [ ] **Step 5: Phase 2.5 — Granularity pre-flight**

```markdown
## Phase 2.5 — Granularity pre-flight

From the `jira-reader` output, determine the input item's type (VI vs Epic) and whether it has child Epics:

- **Epic input** → proceed (the sweet spot).
- **VI input _with_ Epics** → inform the user that specs are authored per Epic; list the child Epics. Offer:
  `choices: ["Run /specify per Epic (Recommended — I'll list them)", "Author one broad VI-level spec", "Cancel"]`
- **VI input _without_ Epics** → flag it and offer:
  `choices: ["Split into Epics first with /epics, then create them in Jira and re-import (Recommended)", "Author one broad VI-level spec now", "Cancel"]`
  `/specify` does NOT create Jira Epics itself (zero external API) — it guides the user through the manual round-trip (see the Jira round-trip note below).
```

- [ ] **Step 6: Phase 3 — Derive repos + soft gate (mirror epics Phase 4)**

```markdown
## Phase 3 — Derive repos + soft gate
```

Auto-derive candidate repos from themes + any linked PR URLs; **empty → ask**
(`choices` per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` "No repos derivable — /epics"),
**ambiguous slug → ask** (per "Repo unresolved (zero matches) — /epics"). Build the slug→clone map
(`git remote` match, `/epics`-style, `timeout 5`). Cross-check mounted status; **unmounted → record a
feasibility `- [ ]` open question in `_session.md`, report it, and PROCEED** (soft gate). Describe the
missing capability + why it matters (cannot name/link an unmounted repo).

- [ ] **Step 7: Phase 4 — Light code scan (mirror epics Phase 5)**

```markdown
## Phase 4 — Light code scan
```

Dispatch `code-scanner` in batches of ≤ 4 concurrent (`model: \`<detection_model — §2.1 Sonnet>\``) on
the mounted candidates → "does this exist / where / gaps" grounding. Handle `REPO_MISSING` /
`DIRTY_TREE` / `REFRESH_BLOCKED` per `escalation-rules.md`.

- [ ] **Step 8: Phase 5 — The grill (embed the technique + stage tree)**

```markdown
## Phase 5 — Author via grill

**Interview technique (grilling — embedded; no runtime plugin dependency).** Conduct each stage as a relentless interview:

- Ask exactly ONE question at a time; wait for the answer before the next. Never batch questions — a firehose is bewildering.
- For every question, give your recommended answer, so the user reacts to a proposal, not a blank prompt.
- If a question can be answered from the Phase 4 code scan or the Jira content, explore and answer it yourself instead of asking.
- Walk the design tree in dependency order — resolve a parent decision before the choices that depend on it.
- Continue until you and the user reach a shared understanding for the stage, then write that stage's section.

(Technique adapted from mattpocock grill-me/grilling; embedded here so `/specify` has no runtime dependency.)

Walk the stages in order, authoring `specification.md` live against `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`:

1. Header + **Problem statement**
2. **Scope** (In/Out)
3. **User stories** (`[Uxx]`)
4. **Acceptance criteria** (`[ACxx]`, EARS)
5. **Test cases** (`[TCxx]`)

As each decision settles, append it to `_session.md`; capture a genuinely-ambiguous term in `_glossary.md`. Resolve open questions to zero where possible; leave genuinely unresolvable ones as `- [ ]` and keep the header **Open questions** count in sync. A repo gap surfacing here → escalate (describe the missing capability + why) and STOP; the run is resumable from `_session.md` after the user remounts and re-invokes.
```

- [ ] **Step 9: Phase 6 — Finalize + review gate**

```markdown
## Phase 6 — Finalize + review gate
```

Render HTML: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/specification-to-html.py" <spec path>` (on failure,
report and proceed — HTML is secondary). Dispatch `spec-reviewer`
(`subagent_type: "dev-workflows:spec-reviewer"`, Opus, frontmatter-pinned; recorded, no override) with
the `specification.md` path. Act on the verdict (mirror `/epics` Phase 7): `BLOCK` → fix the BLOCKER
findings and re-review once; if still `BLOCK`, escalate per `escalation-rules.md` "Review verdict BLOCK
… — /epics" (Defer → append a `## Refinement notes` section + `- [ ]` in the spec). `MAJOR/MINOR/NIT`
→ defer to the final report. `PASS`/`PASS WITH RECOMMENDATIONS` → proceed.

- [ ] **Step 10: Phase 7 — Handoff (branch + PR to main) + Jira round-trip doc + final report**

```markdown
## Phase 7 — Handoff

Write the feature folder: `specification.md` (`Published: no`), `idea.md`, `_session.md`, `_glossary.md`, and the rendered `.html`.

Then **offer** (commit-when-asked — never automatic):
`choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git", "Cancel"]`

On the first choice, in the specs repo (`$SPECS_PATH`): create branch `spec/<KEY>_<slug>` (main is protected — a PR is required), commit ONLY the feature folder (never `git add -A`), push, and open a PR targeting `main`. **Merged-to-main = ready for the dev-team handover.** Devs and `/design` read the spec from `main`, never from the branch. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

### Jira round-trip (document to the user — they will otherwise miss it)

The end-to-end PM flow:
1. `/epics <VI>` drafts child Epic definitions.
2. **You create those Epics in Jira** (manual — `/specify`/`/epics` never call Jira).
3. **You re-import** the VI to `$VAULT_PATH/jira-products/<KEY>` so the new Epics appear in the export.
4. `/specify <each Epic>` reads the Epic from the refreshed export and authors its `specification.md`.

Steps 2–3 are the round-trip; without them `/specify` cannot see the Epics.

## Final report

Report: feature-folder path; stage/user-story/AC/TC counts; open-question count; unmounted-repo advisories; the `spec-reviewer` verdict; the PR URL (if opened); and a reminder of the Jira round-trip + that `Published: yes` is a human-only freeze step.
```

- [ ] **Step 11: Verify Task 4 (structural)**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/specify.md
echo -n "frontmatter name -> "; grep -c "^name: specify$" "$F"
echo -n "all phases (expect 0,1,1.5,2,2.5,3,4,5,6,7 = 10) -> "; grep -cE "^## Phase (0|1|1\.5|2|2\.5|3|4|5|6|7) " "$F"
echo -n "cites jira-input-resolution -> "; grep -c "jira-input-resolution.md" "$F"
echo -n "cites specification-format -> "; grep -c "specification-format.md" "$F"
echo -n "cites model-routing -> "; grep -c "model-routing" "$F"
echo -n "cites escalation-rules -> "; grep -c "escalation-rules.md" "$F"
echo -n "dispatches spec-reviewer -> "; grep -c "dev-workflows:spec-reviewer" "$F"
echo -n "invokes html script -> "; grep -c "specification-to-html.py" "$F"
echo -n "grilling embedded -> "; grep -c "ONE question at a time" "$F"
echo -n "jira round-trip doc -> "; grep -c "Jira round-trip" "$F"
echo -n "branch+PR handoff -> "; grep -c "open a PR targeting" "$F"
echo -n "Published: no rule -> "; grep -c "Published: no" "$F"
echo -n "rejects direct -> "; grep -c "SPECIFY_NEEDS_JIRA" "$F"
```
Expected: `1`, `10`, `≥1` for each cite, `1` for spec-reviewer / html / grilling / round-trip / PR / SPECIFY_NEEDS_JIRA, `≥1` Published.

- [ ] **Step 12: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/specify.md
git commit -m "specify: add the /specify orchestrator command

Jira+code-grounded grilling command (Phases 0-7) that authors an org-standard
specification.md, gates on Opus spec-reviewer, and offers a branch+PR handoff
to the specs repo main branch. Embeds the grilling technique; documents the
/epics -> Jira -> re-import round-trip; VI-without-Epics pre-flight.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Packaging — version bump + CHANGELOG + READMEs

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `README.md` (repo root)
- Modify: `plugins/dev-workflows/README.md`

- [ ] **Step 1: `plugin.json` — version + description**

- `  "version": "2.3.1",` → `  "version": "2.4.0",`
- In `description`: `Nine slash commands —` → `Ten slash commands —`; and
  `/api-guideline-reviewer, and /guideline-reviewer —` → `/api-guideline-reviewer, /guideline-reviewer, and /specify —`
- In `description`: `Twenty-four reusable subagents (` → `Twenty-five reusable subagents (`; and the
  closing of that subagent name list `doc-writer, epic-writer)` → `doc-writer, epic-writer, spec-reviewer)`

- [ ] **Step 2: `marketplace.json` — dev-workflows version only**

- `      "version": "2.3.1",` → `      "version": "2.4.0",` (the dev-workflows entry — the only `2.3.1`
  in the file). Leave `dt-style-guide` `0.2.2` and `obsidian-llm-wiki` `0.3.1` untouched.

- [ ] **Step 3: `CHANGELOG.md` — prepend**

Insert ABOVE `## [2.3.1] — 2026-07-02`:

```markdown
## [2.4.0] — 2026-07-07

### Added

- **`/specify` — Jira- and code-grounded specification authoring (PM phase).** A grilling command that reads a Jira Epic/VI from exported markdown, lightly grounds in code (auto-derived repos, soft advisory gate), and authors an org-standard `specification.md` (problem → scope → user stories → acceptance criteria → test cases) through a relentless one-question-at-a-time interview — resolving open questions live and leaving genuinely unresolvable ones as `- [ ]`. Durable/resumable via `_session.md` + `_glossary.md`; a VI-without-Epics pre-flight; gates on the new Opus `spec-reviewer`; renders HTML; and offers a branch+PR handoff to the specs repo's main branch (`Published: no`) for the future `/design` dev take-over. New assets: `commands/specify.md`, `references/specification-format.md`, `agents/spec-reviewer.md`, `scripts/specification-to-html.py` (format/reviewer/renderer imported from mgd-specifications; grilling technique embedded — no runtime plugin dependency).

```

- [ ] **Step 4: READMEs — command list + subagent table**

```bash
cd /workspace/ihudak-claude-plugins
grep -n "guideline-reviewer" README.md | head            # locate the repo-root command list
grep -n "guideline-reviewer\|inherits\|per routing\|Opus" plugins/dev-workflows/README.md | head -30
```
- `README.md` (repo root): add `/specify` to the command list alongside the existing commands.
- `plugins/dev-workflows/README.md`: add `/specify` to the command list, and add a `spec-reviewer` row
  to the subagent table with the **Opus** model marking (mirror the `epic-reviewer` row — it's an
  Opus-pinned reviewer, NOT "per routing").

- [ ] **Step 5: Verify Task 5 (structural)**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print('plugin',json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"
python3 -c "import json;m=json.load(open('.claude-plugin/marketplace.json'));print([(p['name'],p['version']) for p in m['plugins']])"
grep -nE "^## \[" plugins/dev-workflows/CHANGELOG.md | head -3
echo -n "plugin.json Ten commands + /specify -> "; grep -c "Ten slash commands" plugins/dev-workflows/.claude-plugin/plugin.json; grep -c "and /specify" plugins/dev-workflows/.claude-plugin/plugin.json
echo -n "plugin.json spec-reviewer + Twenty-five -> "; grep -c "Twenty-five reusable subagents" plugins/dev-workflows/.claude-plugin/plugin.json; grep -c "spec-reviewer)" plugins/dev-workflows/.claude-plugin/plugin.json
echo -n "/specify in repo README -> "; grep -c "/specify" README.md
echo -n "/specify + spec-reviewer in plugin README -> "; grep -c "/specify" plugins/dev-workflows/README.md; grep -c "spec-reviewer" plugins/dev-workflows/README.md
```
Expected: `plugin 2.4.0`; marketplace `('dev-workflows','2.4.0')`, `('dt-style-guide','0.2.2')`, `('obsidian-llm-wiki','0.3.1')`; CHANGELOG `[2.4.0]` → `[2.3.1]` → `[2.2.1]`; `1` for each grep.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md README.md plugins/dev-workflows/README.md
git commit -m "specify: release v2.4.0 — package /specify + spec-reviewer

Version lock-step 2.3.1 -> 2.4.0 (plugin.json + marketplace + CHANGELOG);
add /specify to both command lists and spec-reviewer (Opus) to the plugin
README subagent table; siblings untouched.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Finishing

After Task 5, use **superpowers:finishing-a-development-branch** (structural verification stands in for
tests — there is no test framework). Base `main`. Do not push or open a PR unless the user asks.

## Self-Review

**Spec coverage** (design doc → task):
- Jira-driven-only input / reject direct → Task 4 Step 2 (`SPECIFY_NEEDS_JIRA`). ✓
- One spec per invocation → Task 4 intro + Phase 2.5. ✓
- Output specification.md + HTML only, no plan → Task 4 Phase 6/7; Task 3 renderer. ✓
- Own-it authoring (format/reviewer/renderer embedded; no runtime specs-repo dep) → Tasks 1–3 + verify greps (0 `.claude/skills` runtime dep in reviewer). ✓
- Grilling embedded → Task 4 Step 8. ✓
- Durability `_session.md`/`_glossary.md`, resume → Task 4 Steps 2/8, Phase 0 resume. ✓
- Light code grounding; auto-derive (empty→ask, ambiguous→ask); soft gate → Task 4 Steps 6–7. ✓
- Gate timing during/early + re-fire → Phase 3 before Phase 5; mid-grill escalate in Step 8. ✓
- `depth: full` → Task 4 Step 4. ✓
- VI-without-Epics pre-flight → Task 4 Step 5. ✓
- Jira round-trip documented → Task 4 Step 10 + CHANGELOG. ✓
- Handoff branch+PR→main, Published: no → Task 4 Step 10. ✓
- Model routing (Sonnet detection / session authoring / Opus reviewer) → Task 4 Step 3. ✓
- spec-reviewer Opus-pinned gate + fix loop → Task 2 + Task 4 Step 9. ✓
- Packaging lock-step + READMEs + CHANGELOG → Task 5. ✓

**Placeholder scan:** no TBD/TODO; every authored file has concrete content or a verbatim-copy
instruction; every verification step has an exact command + expected output. Task 4's connective prose
cites `epics.md` as the concrete template (not a vague "similar to").

**Type/anchor consistency:** subagent_type strings (`dev-workflows:spec-reviewer`,
`dev-workflows:jira-reader`, `dev-workflows:code-scanner`), the `${CLAUDE_PLUGIN_ROOT}/…` paths, the
`_session.md`/`_glossary.md` names, and the phase anchors are used identically across Task 4 and the
verification greps. Version `2.4.0` consistent across Task 5. spec-reviewer verdict schema matches
between Task 2 (author) and Task 4 Step 9 (consumer).

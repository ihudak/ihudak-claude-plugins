# `$DOCS_PATH` Documentation Grounding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When `$DOCS_PATH` is set and valid, seven dev-workflows authoring commands automatically ground on the product documentation so the operator no longer types "please also check the documentation in `<dir>`".

**Architecture:** A shared reference (`references/docs-grounding.md`) owns the resolution gate + a named `resolve-docs-grounding` procedure + the dispatch/consumption contract. A new read-only agent (`agents/docs-grounder.md`) does keyword/qmd retrieval and returns a bounded digest of `docs_references` (positive grounding) + `docs_challenges` (reconciliation prompts). Each of the seven commands gets a thin citation of the procedure at one phase; `/document` gets a one-tier discovery-hint change only. No runnable code — all deliverables are Markdown plugin files consumed by Claude Code.

**Tech Stack:** Claude Code plugin Markdown (commands/agents/references with YAML frontmatter), `${CLAUDE_PLUGIN_ROOT}` references, the `qmd` CLI (hybrid markdown search), local `git`. Verification uses `python3` YAML parsing, `grep` structural/cross-reference checks, and a documented behavioral smoke test.

## Global Constraints

Copied verbatim from the spec; every task's requirements implicitly include these.

- **Never blocks, never degrades below today's behavior.** Docs grounding is advisory; every failure mode is a silent, non-blocking skip — never an error, never `emit-block`.
- **Read-only, always.** The seven commands never write into `$DOCS_PATH`, regardless of how it is mounted. Neither retrieval path writes into it (`qmd` index is in `~/.cache/qmd/`; `git log --grep` is a pure read).
- **Resolution:** `${DOCS_PATH:-/workspace/docs}`, a single directory. Default-safety principle: read-only search bases default (`REPOS_PATH`, `DOCS_PATH`); write roots stay strict (`SPECS_PATH`, `VAULT_PATH` — untouched, no default).
- **Validity gate — ON only when all hold:** resolved path non-empty, an existing readable directory, contains ≥1 markdown file. Else OFF with a one-line reason.
- **Default ON when valid**, surfaced at plan/approval with an off switch. `--no-docs` forces OFF; `--docs <path>` overrides the root (same gate).
- **Grounding is mostly positive, not adversarial.** `docs_references` carry a `relation` (`same_feature | analogous_precedent | building_block`) and `structural_facts`; `docs_challenges` carry five kinds incl. `diverges_from_precedent`.
- **Bounding:** ≤8 pages read; `docs_references[]` ≤8; `docs_challenges[]` ≤5, severity-ranked; each `salient_summary` ≤150 words.
- **Grill commands rank challenges into the existing Impact × Uncertainty gap list** (do not append — preserves `/idea`'s ≤5-question bound). Writer commands attach the digest to the writer handoff.
- **No qmd skill installed.** `docs-grounder` calls `qmd` via the Bash CLI; `qmd update` never `--pull`.
- **Version:** bump dev-workflows to 2.36.0 with CHANGELOG/README/CLAUDE.md updated in the same change (cross-reference integrity).
- **Repo scope:** `plugins/dev-workflows/` + top-level `CLAUDE.md` only. `.ai-containers/` and sibling repos are follow-ups.
- **Branch:** all work lands on `feat/docs-path-grounding` (already created; the spec is committed there).

---

## File Structure

- **Create** `plugins/dev-workflows/references/docs-grounding.md` — resolution gate, `resolve-docs-grounding` procedure, dispatch pattern, plan-line format, two consumption modes. (Task 1)
- **Create** `plugins/dev-workflows/agents/docs-grounder.md` — read-only retrieval agent. (Task 2)
- **Modify** the 5 grill commands — `commands/{idea,create-vi,update-vi,create-ard,specify}.md`. (Task 3)
- **Modify** the 2 writer commands — `commands/{epics,release-notes}.md`. (Task 4)
- **Modify** `commands/document.md` — Phase 0 middle discovery tier. (Task 5)
- **Modify** `.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`, and top-level `CLAUDE.md` — version + docs + cross-references. (Task 6)

---

## Task 1: Shared reference `references/docs-grounding.md`

**Files:**
- Create: `plugins/dev-workflows/references/docs-grounding.md`

**Interfaces:**
- Consumes: nothing (foundation).
- Produces: the named procedure `resolve-docs-grounding <command-name>` (returns `docs_grounding: ON|OFF`, `docs_root`, `reason`); the `dispatch-docs-grounder` Agent-call pattern; the plan-approval line format `docs grounding: ON <root> | OFF (<reason>)`; the two consumption modes `grill-rank` and `writer-attach`. Tasks 3–4 cite these by name.

- [ ] **Step 1: Write the reference file**

Create `plugins/dev-workflows/references/docs-grounding.md` with exactly this content:

````markdown
# Documentation grounding on `$DOCS_PATH` (shared reference)

Several authoring commands produce markedly better output when grounded in the
product's existing shipped documentation — current behavior, customer-facing
terminology, and well-documented analogous features to model new work on. When
`$DOCS_PATH` is set and valid, the commands below ground on it automatically so
the operator never has to add "please also check the documentation in `<dir>`".

This governs *whether docs grounding runs and against what root*, and *how the
result is consumed*. It is **read-only**: these commands never write into
`$DOCS_PATH`. Every miss is a **silent, non-blocking skip** — never an error,
never `emit-block`.

Consumers: `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`
(grill-rank consumption); `/epics`, `/release-notes` (writer-attach consumption).
`/document` does **not** consume this file — it only uses `$DOCS_PATH` as a
write-target discovery hint (see its Phase 0).

## Procedure — `resolve-docs-grounding <command-name>`

1. **Flags first.** If the invocation carries `--no-docs`, return
   `docs_grounding: OFF`, `reason: "disabled with --no-docs"`. If it carries
   `--docs <path>`, set `docs_root = <path>` and skip step 2.
2. **Resolve the root.** `docs_root = ${DOCS_PATH:-/workspace/docs}` (a single
   directory; the AI container mounts docs at `/workspace/docs`, so the default
   lets grounding work even if the var is not re-exported).
3. **Validity gate — ON only when all hold** (else `OFF` with a one-line reason):
   - `docs_root` is non-empty,
   - it is an existing, readable directory (`test -d "$docs_root" && test -r "$docs_root"`),
   - it contains at least one markdown file
     (`find "$docs_root" -type f -name '*.md' -print -quit` is non-empty).
   On a host where `/workspace/docs` is absent, the gate fails → `OFF` → the run
   behaves exactly as it does today.
4. **Return** `{ docs_grounding, docs_root, reason }`.

**Default-safety note.** A `/workspace/*` default is safe here because this is a
read-only search base — a wrong/missing default just misses and silently skips.
This mirrors `${REPOS_PATH:-/workspace}`. Write roots (`SPECS_PATH`,
`VAULT_PATH`) deliberately do **not** default; do not change them.

## Plan-approval line

When `resolve-docs-grounding` returns, surface one line in the command's
plan/approval (or config-confirm) step, with an off switch:

```
docs grounding: ON  <docs_root>        (turn off with --no-docs)
docs grounding: OFF (<reason>)
```

## Dispatch — `dispatch-docs-grounder`

Run only when `docs_grounding: ON`. Dispatch the read-only agent (model tier per
the run's `model_routing` — the `detection_model` §2.1 Sonnet chain is the
default for this retrieval agent):

```
→ Agent (subagent_type: "dev-workflows:docs-grounder", model: <detection_model>):
  > "Ground this work in the product docs and return the digest:
  >
  > docs_path:       <docs_root>
  > feature_summary: <2–4 sentences: the goal + capability themes for this run>
  > jira_key:        <the VI/Epic/ticket key, or omit for keyless /idea>
  > themes:          [capability themes, or []]"
```

Wait for the digest. On `status: ERROR` or any dispatch failure, treat as
`docs_grounding: OFF` and proceed as today (record one line in the final report).
On `status: EMPTY`, proceed as today; the digest simply adds nothing.

## Consumption

**`grill-rank`** (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`):
Feed `docs_references` to the grill as positive grounding (facts to build on,
analogous precedents to model after, building-block altitude/permissions).
**Rank** each `docs_challenges` entry into the command's existing
Impact × Uncertainty gap list — do **not** append. A docs challenge competes for
a question slot; it never adds one (this preserves `/idea`'s ≤5-question bound).

**`writer-attach`** (`/epics`, `/release-notes`): Pass the whole digest
(`docs_references` + `docs_challenges`) into the writer agent's input handoff as
`docs_grounding`. The writer uses references for consistency and treats
challenges as authoring cautions.

## Invariants

- Read-only; never writes into `$DOCS_PATH`.
- Never blocks; every failure is a silent, non-blocking skip.
- Advisory only — never a gate, never a reviewer BLOCKER.
- Single directory; `${DOCS_PATH:-/workspace/docs}`.
````

- [ ] **Step 2: Verify the file exists and the named contract elements are present**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for tok in "resolve-docs-grounding" "dispatch-docs-grounder" "grill-rank" "writer-attach" '${DOCS_PATH:-/workspace/docs}' "Validity gate" "silent, non-blocking skip"; do
  grep -qF "$tok" references/docs-grounding.md && echo "OK: $tok" || echo "MISSING: $tok"
done
```
Expected: seven `OK:` lines, no `MISSING:`.

- [ ] **Step 3: Verify no consumer is left undeclared**

Run:
```bash
grep -c 'idea\|create-vi\|update-vi\|create-ard\|specify\|epics\|release-notes' references/docs-grounding.md
```
Expected: a non-zero count (all seven consumers named in the header).

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/docs-grounding.md
git commit -m "feat(dev-workflows): add docs-grounding shared reference (resolve + dispatch + consumption)"
```

---

## Task 2: Read-only agent `agents/docs-grounder.md`

**Files:**
- Create: `plugins/dev-workflows/agents/docs-grounder.md`

**Interfaces:**
- Consumes: the dispatch inputs defined in Task 1 (`docs_path`, `feature_summary`, `jira_key?`, `themes?`).
- Produces: the output contract `{ status, retrieval, docs_references[], docs_challenges[], notes }` that Tasks 3–4 consume via the Task 1 consumption modes.

- [ ] **Step 1: Write the agent file**

Create `plugins/dev-workflows/agents/docs-grounder.md` with exactly this content:

````markdown
---
name: docs-grounder
description: Read-only documentation grounding for authoring commands. Given a docs root ($DOCS_PATH), a feature summary, and optional Jira key/themes, retrieves the most relevant existing product-doc pages and returns a bounded digest — docs_references (positive grounding: same-feature facts, analogous precedents to model after, building-block altitude/permissions) plus docs_challenges (reconciliation prompts: already-documented, terminology mismatch, contradiction, divergence-from-precedent, adjacent-undocumented). Two-path retrieval — qmd CLI when available, keyword-overlap + git-grep fallback otherwise. Never writes; advisory only. Model tier assigned by the caller per the model-routing policy (no fixed pin).
tools: ["Read", "Glob", "Grep", "LS", "Bash"]
---

Ground an authoring task in the product's existing documentation so the author
can build on documented behavior, model new work on well-documented analogs, and
reconcile the draft against what already ships. **Read-only reference discovery —
never a writer, never a gate.**

## Inputs

```yaml
docs_path:       <absolute path to the docs root ($DOCS_PATH); a single directory>
feature_summary: <2–4 sentences: the goal + what this run is about>
jira_key:        <optional — a VI/Epic/ticket key; enables the git-grep backstop>
themes:          <optional capability themes from the caller, or []>
```

Refuse to run without `docs_path` and a non-empty `feature_summary`. If
`docs_path` is not an existing readable directory, return `status: ERROR` with a
one-line `notes` (the caller treats this as OFF and proceeds).

## Process — two-path retrieval

### Path A — qmd (preferred)

Use when the `qmd` binary is available (`command -v qmd`) and a `docs` collection
resolves for `docs_path`:

1. **Ensure the collection.** `qmd collection list`. If no collection covers
   `docs_path`, self-heal: `qmd collection add "<docs_path>" --name docs` then
   `qmd embed`. If the index looks stale, `qmd update` (**never `--pull`** — the
   clone may be read-only). Any qmd command failure → fall through to Path B.
2. **Query.** `qmd query "<feature_summary + themes keywords>"` for ranked hits
   (hybrid BM25 + vector + rerank).
3. **Read the top hits** with `qmd get "<file>"` (or `Read`), capped per Bounding.
4. Record `retrieval: qmd`.

### Path B — fallback

Use when `qmd` is absent, off, or Path A failed:

1. **Keyword-overlap scoring** (the `doc-location-finder` technique): index each
   page's frontmatter (`title`/`description`/`tags`) + first ~50 body lines; score
   overlap against `feature_summary` + `themes` minus stopwords; keep matches above
   threshold.
2. **git-grep backstop** (only when `jira_key` is present):
   `git -C "<docs_path>" log --all -E --grep="<jira_key>" -n 20 --name-only` and
   union any pages it touched. This is a pure read and works on a read-only
   `.git`; **best-effort** — on any failure, degrade to keyword-overlap only,
   never an error. Skip entirely when `jira_key` is absent (e.g. `/idea`).
3. Record `retrieval: fallback`.

### For every match (both paths)

Classify the **relation** to the new work and extract the grounding digest:

- `same_feature` — the docs cover this very capability.
- `analogous_precedent` — a *different* but parallel feature to model the new one
  on (e.g. new ActiveGate autoupdate ↔ documented OneAgent autoupdate: shared
  update window, parallel versioning). Often the highest-value match; produces no
  contradiction.
- `building_block` — an existing documented thing the new work sits on (e.g. new
  UI over an existing API — the docs give the API's altitude and permissions).

Extract **structural_facts** when the page has them (illustrative, not
exhaustive): resource altitude/scope (e.g. environment vs cluster), required
permissions/scopes, config/settings-schema shape, versioning & lifecycle/update
mechanics, naming pattern.

## Bounding

Read at most the top **8** pages. `docs_references[]` capped at **8**;
`docs_challenges[]` capped at **5** and severity-ranked; each `salient_summary`
≤ **150 words**.

## Output

```yaml
status: OK | EMPTY | ERROR
retrieval: qmd | fallback
docs_references:
  - path:             <absolute path>
    relation:         same_feature | analogous_precedent | building_block
    salient_summary:  <≤150 words: concepts, current behavior, verified facts>
    structural_facts: <the consistency-bearing facts when present, else omit>
    section_outline:  [<heading>, ...]
    terminology:      [<customer-facing term the docs use>, ...]
    match_confidence: high | medium | low
    match_reason:     <why this page matched>
docs_challenges:
  - kind:      already_documented | terminology_mismatch | contradicts_documented_behavior | diverges_from_precedent | adjacent_undocumented
    challenge: <the reconciliation question to put to the author>
    evidence:  { path: <page>, quoted_line: <verbatim line from the docs> }
    severity:  high | medium | low
notes: <when EMPTY: why nothing found; when a path degraded: which and why>
```

`kind` semantics:
- `already_documented` — this capability appears to ship already; how is the new
  work different?
- `terminology_mismatch` — the docs call it X; the draft calls it Z.
- `contradicts_documented_behavior` — the draft asserts behavior the docs
  describe differently.
- `diverges_from_precedent` — the draft designs something analogous to a
  documented feature (an existing API / policy / settings schema) but
  **inconsistently** (different altitude, permission model, schema shape, or
  naming) without acknowledging it. Match it or justify the divergence.
- `adjacent_undocumented` — a closely related area the docs do **not** cover
  (a scope/opportunity signal).

`status: EMPTY` → both arrays empty and `notes` explains; the caller proceeds as
today.

## Hard rules

- NEVER write or edit any file. Read-only.
- NEVER make HTTPS/REST calls — `git` and the `qmd` CLI are local only.
- NEVER run `qmd update --pull` (the docs clone may be read-only).
- Advisory only — never a gate; `docs_challenges` are reconciliation prompts, not
  auto-applied edits.
- Respect the Bounding caps; a large clone must not flood the caller's context.
````

- [ ] **Step 2: Verify the frontmatter parses as YAML**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
python3 -c "
import yaml
t = open('agents/docs-grounder.md').read()
fm = t.split('---')[1]
d = yaml.safe_load(fm)
assert d['name'] == 'docs-grounder', d.get('name')
assert 'Bash' in d['tools'], d['tools']
assert isinstance(d['description'], str) and len(d['description']) > 40
print('frontmatter OK:', d['name'], d['tools'])
"
```
Expected: `frontmatter OK: docs-grounder ['Read', 'Glob', 'Grep', 'LS', 'Bash']`

- [ ] **Step 3: Verify the contract surface is complete**

Run:
```bash
for tok in "same_feature" "analogous_precedent" "building_block" "structural_facts" \
           "already_documented" "terminology_mismatch" "contradicts_documented_behavior" \
           "diverges_from_precedent" "adjacent_undocumented" "retrieval: qmd | fallback" \
           "never \`--pull\`" "Read-only"; do
  grep -qF "$tok" agents/docs-grounder.md && echo "OK: $tok" || echo "MISSING: $tok"
done
```
Expected: all `OK:`, no `MISSING:`.

- [ ] **Step 4: Verify read-only tool set (no Write/Edit)**

Run:
```bash
python3 -c "
import yaml
d = yaml.safe_load(open('agents/docs-grounder.md').read().split('---')[1])
bad = [t for t in d['tools'] if t in ('Write','Edit','NotebookEdit')]
assert not bad, ('write tools present: %s' % bad)
print('read-only tool set OK')
"
```
Expected: `read-only tool set OK`

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/docs-grounder.md
git commit -m "feat(dev-workflows): add read-only docs-grounder agent (qmd + fallback retrieval)"
```

---

## Task 3: Wire the five grill commands

Each command cites `resolve-docs-grounding` at its input/config phase, surfaces the
plan-approval line, and dispatches `docs-grounder` at the phase named below with
`grill-rank` consumption. Edits are thin (citations), matching the codebase idiom.

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md` (dispatch: new Phase 2.5, after Phase 2 "Read the seed"; feed Phase 3 grill)
- Modify: `plugins/dev-workflows/commands/idea.md` (dispatch: new Phase 2.5, after Phase 2 ingest at line 69–89; feed Phase 3 grill; **no `jira_key`** — keyless)
- Modify: `plugins/dev-workflows/commands/update-vi.md` (dispatch: within Phase 2 "Read the base + grounding"; feed Phase 3 grill)
- Modify: `plugins/dev-workflows/commands/create-ard.md` (dispatch: within Phase 3, after the `code-scanner` batch; feed Phase 4 grill)
- Modify: `plugins/dev-workflows/commands/specify.md` (dispatch: Phase 4, parallel with `code-scanner`; feed Phase 5 grill)

**Interfaces:**
- Consumes: `resolve-docs-grounding`, `dispatch-docs-grounder`, `grill-rank` (Task 1); `docs-grounder` output (Task 2).
- Produces: nothing new — feeds each command's existing grill.

- [ ] **Step 1: `/create-vi` — insert the dispatch phase**

In `plugins/dev-workflows/commands/create-vi.md`, immediately **after** the Phase 2 block ("## Phase 2 — Read the seed" … before "## Phase 3 — Author via grill"), insert:

```markdown
## Phase 2.5 — Documentation grounding (optional)

Run `resolve-docs-grounding create-vi` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the idea's problem/goal + VI themes, `jira_key` = `<KEY>`, and `themes` from the idea. Carry the returned digest into Phase 3 with **grill-rank** consumption. When OFF, skip silently — the VI is authored exactly as today.

---
```

Then in Phase 1 (the "**Confirm** the feature folder, the profile, and the resolved `idea.md`" step), add the plan-approval line: `- Show the `docs grounding: ON <root> | OFF (<reason>)` line (off switch: --no-docs).`

- [ ] **Step 2: `/idea` — insert the dispatch phase (keyless)**

In `plugins/dev-workflows/commands/idea.md`, immediately **after** "## Phase 2 — Ingest the source (idea-reader)" (ends at line ~89) and **before** "## Phase 3 — Refine via grill", insert:

```markdown
## Phase 2.5 — Documentation grounding (optional)

Run `resolve-docs-grounding idea` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the `idea-reader` digest's problem/outcome, `themes` = its signals; **omit `jira_key`** (idea is keyless, so the git-grep backstop is skipped). Carry the digest into Phase 3 with **grill-rank** consumption — challenges compete for the ≤5 question slots, they do not add slots. When OFF, skip silently.

---
```

Then in Phase 1's confirmation step, add the plan-approval line (`docs grounding: ON <root> | OFF (<reason>)`).

- [ ] **Step 3: `/update-vi` — dispatch within Phase 2**

In `plugins/dev-workflows/commands/update-vi.md`, at the end of "## Phase 2 — Read the base + grounding" (before the `---` that precedes Phase 3), append:

```markdown

Then run `resolve-docs-grounding update-vi` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the VI goal + the change signal from comments, `jira_key` = `<KEY>`. Carry the digest into the Phase 3 grill with **grill-rank** consumption. When OFF, skip silently.
```

Then in Phase 1 (Configure), add the plan-approval line.

- [ ] **Step 4: `/create-ard` — dispatch within Phase 3**

In `plugins/dev-workflows/commands/create-ard.md`, at the end of "## Phase 3 — Architect-driven grounding (no PRs)" (after step 4 "Ground the confirmed set", before the `---` preceding Phase 4), append:

```markdown
5. **Documentation grounding (optional).** Run `resolve-docs-grounding create-ard` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the VI/Epic goal + capability themes, `jira_key` = `<VI>` (VI-level) or `<EPIC>` (Epic-level), `themes` = the confirmed themes. Carry the digest into the Phase 4 grill with **grill-rank** consumption (documented analogs and building-block altitude/permissions are strong ARD grounding). When OFF, skip silently.
```

Then in the Phase 1/2 config-confirm step, add the plan-approval line.

- [ ] **Step 5: `/specify` — dispatch in Phase 4 alongside code-scanner**

In `plugins/dev-workflows/commands/specify.md`, in "## Phase 4" (the `code-scanner` dispatch phase), add — in the **same** Agent message batch as the code scanners where possible, else immediately after — :

```markdown
**Documentation grounding (optional).** Run `resolve-docs-grounding specify` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the scoped Epic/VI goal, `jira_key` = the focus key, `themes` = the Phase 2 capability themes. Carry the digest into the Phase 5 grill with **grill-rank** consumption. When OFF, skip silently.
```

Then in the Phase 1 config / plan step, add the plan-approval line.

- [ ] **Step 6: Verify all five commands cite the reference and use grill-rank**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in idea create-vi update-vi create-ard specify; do
  grep -q 'resolve-docs-grounding' commands/$f.md \
    && grep -q 'references/docs-grounding.md' commands/$f.md \
    && grep -q 'grill-rank' commands/$f.md \
    && echo "OK: $f" || echo "MISSING wiring: $f"
done
```
Expected: five `OK:` lines.

- [ ] **Step 7: Verify `/idea` omits jira_key (keyless)**

Run:
```bash
grep -n 'omit .*jira_key\|keyless' commands/idea.md
```
Expected: at least one line confirming `jira_key` is omitted for `/idea`.

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/{idea,create-vi,update-vi,create-ard,specify}.md
git commit -m "feat(dev-workflows): wire docs grounding into the five grill commands"
```

---

## Task 4: Wire the two writer commands

Both dispatch `docs-grounder` and attach the digest to their writer handoff
(`writer-attach`); neither has a grill.

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md` (dispatch: Phase 5, alongside code scanning; attach to Phase 6 `epic-writer` handoff)
- Modify: `plugins/dev-workflows/commands/release-notes.md` (dispatch: new Phase 5.5; attach to Phase 6 `release-notes-writer` handoff)

**Interfaces:**
- Consumes: `resolve-docs-grounding`, `dispatch-docs-grounder`, `writer-attach` (Task 1); `docs-grounder` output (Task 2).
- Produces: a `docs_grounding` field added to each writer's input handoff.

- [ ] **Step 1: `/epics` — dispatch in Phase 5, attach in Phase 6**

In `plugins/dev-workflows/commands/epics.md`, in "## Phase 5 — Parallel code scanning (conditional)", after the batch-handling block (before the `---` preceding Phase 6), append:

```markdown

**Documentation grounding (optional, independent of code scan).** Run `resolve-docs-grounding epics` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the VI goal + Epic-set intent, `jira_key` = the VI key, `themes` = the `jira-reader` themes. Carry the digest into Phase 6 with **writer-attach** consumption. When OFF, skip silently. (Runs even when code scan is OFF.)
```

Then in Phase 6 (Write Epics), where the `epic-writer` handoff is assembled, add a `docs_grounding: [the Phase 5 digest, or omit when OFF/EMPTY]` line to the writer's input contract.

Then in "## Phase 2 — Plan + approval", add a bullet to the plan list:
```markdown
- Docs grounding: `ON <root>` / `OFF (<reason>)` (off switch: --no-docs)
```

- [ ] **Step 2: `/release-notes` — new Phase 5.5, attach in Phase 6**

In `plugins/dev-workflows/commands/release-notes.md`, insert a new phase between "## Phase 5 — Diff summarisation (only if diff grounding is ON)" and "## Phase 6 — Render the draft":

```markdown
## Phase 5.5 — Documentation grounding (optional)

Run `resolve-docs-grounding release-notes` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the ticket goal + release themes, `jira_key` = `jira_key`. Carry the digest into Phase 6 with **writer-attach** consumption. When OFF, skip silently. (Independent of diff grounding.)

---
```

Then in "## Phase 6 — Render the draft", add a line to the `release-notes-writer` Agent handoff: `> docs_grounding: [the Phase 5.5 digest, or omit when OFF/EMPTY]`.

Then in "## Phase 2 — Worthiness check + plan/approval", extend the "**Plan.** Present:" line to include `docs grounding on/off (+ root when on)`.

- [ ] **Step 3: Verify both commands cite the reference and use writer-attach**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in epics release-notes; do
  grep -q 'resolve-docs-grounding' commands/$f.md \
    && grep -q 'writer-attach' commands/$f.md \
    && grep -q 'docs_grounding' commands/$f.md \
    && echo "OK: $f" || echo "MISSING wiring: $f"
done
```
Expected: two `OK:` lines.

- [ ] **Step 4: Verify the release-notes new phase is placed correctly**

Run:
```bash
grep -n '## Phase 5 —\|## Phase 5.5 —\|## Phase 6 —' commands/release-notes.md
```
Expected: `Phase 5 —`, then `Phase 5.5 —`, then `Phase 6 —` in ascending line order.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/{epics,release-notes}.md
git commit -m "feat(dev-workflows): wire docs grounding into /epics and /release-notes writer handoffs"
```

---

## Task 5: `/document` Phase 0 discovery-hint middle tier

Insert `${DOCS_PATH:-/workspace/docs}` as a new middle tier in `/document`'s
docs-repo resolution — a write-target hint only, no grounding, no `docs-grounder`.

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md` (Phase 0, between step (a) and step (b))

**Interfaces:**
- Consumes: nothing from Tasks 1–4 (independent).
- Produces: nothing consumed elsewhere.

- [ ] **Step 1: Insert the middle tier**

In `plugins/dev-workflows/commands/document.md`, in the "Resolve `docs_repo_path` in this order:" list, **between** the `- **(a) cwd with signals ...**` bullet and the `- **(b) Search for a dynatrace-docs clone.**` bullet, insert:

```markdown
   - **(a.5) `$DOCS_PATH` hint.** Else, resolve `${DOCS_PATH:-/workspace/docs}`. If it exists and passes the `is_dynatrace_docs` signal check (see step 3 — contains both `managed/docstack.jsonc` and `dynatrace/_content/`), set `docs_repo_path` = that path and proceed. In an AI container the docs clone is mounted here, so this is the common fast path when cwd carries no docs signals.
```

Renumber nothing else — (b) and (c) remain the `$REPOS_PATH` search and the ask, now the later fallbacks.

- [ ] **Step 2: Verify the three-tier order reads (a) → (a.5) → (b)**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n '(a) cwd with signals\|(a.5) `$DOCS_PATH` hint\|(b) Search for a dynatrace-docs' commands/document.md
```
Expected: three lines in ascending order — `(a) cwd`, then `(a.5) $DOCS_PATH`, then `(b) Search`.

- [ ] **Step 3: Verify no `docs-grounder` dispatch leaked into `/document`**

Run:
```bash
grep -c 'docs-grounder\|resolve-docs-grounding' commands/document.md || true
```
Expected: `0` (this task is discovery-hint only).

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/document.md
git commit -m "feat(dev-workflows): prefer \$DOCS_PATH as /document docs-repo discovery hint"
```

---

## Task 6: Version bump, changelog, README, and CLAUDE.md cross-references

Satisfies the spec §8 cross-reference-integrity check: every doc that indexes the
plugin's agents, references, workflow map, and invariants is updated in the same
change.

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (line 3: `"version": "2.35.0"` → `2.36.0`)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (new top entry)
- Modify: `plugins/dev-workflows/README.md` (agents/references listing + a docs-grounding feature note; qmd optional-prereq line)
- Modify: `CLAUDE.md` (workflow map, agent list, references-SSOT paragraph, invariants)

**Interfaces:**
- Consumes: the file names produced by Tasks 1–5.
- Produces: nothing consumed elsewhere.

- [ ] **Step 1: Bump the version**

Edit `plugins/dev-workflows/.claude-plugin/plugin.json` line 3 from `"version": "2.35.0",` to `"version": "2.36.0",`.

- [ ] **Step 2: Add the CHANGELOG entry**

Prepend a new entry at the top of `plugins/dev-workflows/CHANGELOG.md` (match the existing heading style in that file):

```markdown
## 2.36.0

- **Documentation grounding on `$DOCS_PATH`.** `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, and `/specify` now ground their grill on the product docs when `$DOCS_PATH` is set and valid; `/epics` and `/release-notes` attach the docs digest to their writer handoff. Adds `references/docs-grounding.md` (resolution gate + `resolve-docs-grounding` procedure + consumption modes) and a read-only `docs-grounder` agent (qmd CLI retrieval, keyword + `git log --grep` fallback). Grounding is positive-first (`relation`: same-feature / analogous-precedent / building-block; `structural_facts`) plus reconciliation challenges (incl. `diverges_from_precedent`). Advisory, read-only, and a silent non-blocking skip on any miss.
- **`/document`** now prefers `${DOCS_PATH:-/workspace/docs}` as a docs-repo discovery hint (middle tier between cwd-with-signals and the `$REPOS_PATH` search); write-target hint only, no grounding.
- `$DOCS_PATH` resolves as `${DOCS_PATH:-/workspace/docs}` (read-only search base; write roots `SPECS_PATH`/`VAULT_PATH` stay strict).
```

- [ ] **Step 3: Update the README**

In `plugins/dev-workflows/README.md`:
- Add `docs-grounder` to the agents listing (read-only docs grounding).
- Add `references/docs-grounding.md` to the references listing.
- Add a short "Documentation grounding" note: when `$DOCS_PATH` is set and valid, the seven authoring commands ground on the product docs automatically; disable per-run with `--no-docs`, override the root with `--docs <path>`.
- Add one optional-prerequisite line: the `qmd` binary enables semantic docs grounding; without it the commands use keyword fallback (host users only — the AI container installs it).

- [ ] **Step 4: Update `CLAUDE.md` — workflow map**

In the top-level `CLAUDE.md` "`dev-workflows` workflow relationships" diagram, add the `docs-grounder` edge to each of the seven commands and note the `/document` hint. For example, extend the relevant lines:
- `/idea` → add `→ [docs-grounder (when $DOCS_PATH valid)]` before the grill.
- `/create-vi`, `/update-vi`, `/create-ard`, `/specify` → add `→ [docs-grounder]` at their grounding phase.
- `/epics`, `/release-notes` → add `→ [docs-grounder]` before the writer.
- Add `docs-grounder` to the shared-agents list at the bottom of the map with: `used by /idea, /create-vi, /update-vi, /create-ard, /specify, /epics, /release-notes`.

- [ ] **Step 5: Update `CLAUDE.md` — references SSOT paragraph and invariants**

- In the "Source-truth reference" section, add a sentence: `plugins/dev-workflows/references/docs-grounding.md` is the SSOT for `$DOCS_PATH` documentation grounding — the resolution gate (`${DOCS_PATH:-/workspace/docs}`, read-only, silent-skip), the `resolve-docs-grounding` procedure, and the grill-rank / writer-attach consumption modes; consumed by the seven authoring commands (not `/document`).
- Add an invariants block "Key invariants for `$DOCS_PATH` docs grounding":
  - Read-only; never writes into `$DOCS_PATH`; advisory only — never a gate or reviewer BLOCKER.
  - Default ON when `$DOCS_PATH` (`:-/workspace/docs`) is a readable dir with ≥1 markdown file; `--no-docs` off, `--docs <path>` override; every miss is a silent non-blocking skip.
  - Grill commands rank challenges into the Impact × Uncertainty gap list (never append — preserves `/idea`'s ≤5 bound); writer commands attach the digest.
  - `docs-grounder` retrieves via `qmd` CLI (no skill installed; `qmd update` never `--pull`) with keyword + `git log --grep` fallback; write roots `SPECS_PATH`/`VAULT_PATH` stay strict (no default).

- [ ] **Step 6: Verify version, cross-references, and no dangling edges**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -q '"version": "2.36.0"' plugins/dev-workflows/.claude-plugin/plugin.json && echo "version OK"
grep -q '2.36.0' plugins/dev-workflows/CHANGELOG.md && echo "changelog OK"
grep -q 'docs-grounder' plugins/dev-workflows/README.md && grep -q 'docs-grounding' plugins/dev-workflows/README.md && echo "readme OK"
grep -q 'docs-grounder' CLAUDE.md && grep -q 'docs-grounding.md' CLAUDE.md && echo "claude.md OK"
# Every citation resolves to a real file:
test -f plugins/dev-workflows/references/docs-grounding.md && echo "ref exists"
test -f plugins/dev-workflows/agents/docs-grounder.md && echo "agent exists"
```
Expected: `version OK`, `changelog OK`, `readme OK`, `claude.md OK`, `ref exists`, `agent exists`.

- [ ] **Step 7: Whole-feature cross-reference sweep (no broken plugin-file citations)**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# Every command that cites the reference: the reference must exist (it does) — confirm no typo'd path:
grep -rl 'references/docs-grounding.md' commands/ | while read f; do
  grep -q 'references/docs-grounding.md' "$f" && echo "cite OK: $(basename $f)"
done
# The agent subagent_type is spelled consistently:
grep -rn 'dev-workflows:docs-grounder' commands/ references/ | wc -l
```
Expected: seven `cite OK:` lines (the seven consumers), and a non-zero count for the `subagent_type` spelling.

- [ ] **Step 8: Behavioral smoke test (documented; run manually)**

This is the spec §8 behavioral check. Run it once by hand:
```bash
# OFF path — unset DOCS_PATH, confirm the gate yields OFF:
env -u DOCS_PATH bash -c 'test -d "${DOCS_PATH:-/workspace/docs}" && echo "would be ON" || echo "OFF (default dir absent) — today's behavior"'
# ON path — a temp docs dir with one markdown file passes the gate:
d=$(mktemp -d); echo "# sample" > "$d/page.md"
DOCS_PATH="$d" bash -c 'test -d "$DOCS_PATH" && find "$DOCS_PATH" -name "*.md" -print -quit | grep -q . && echo "gate: ON $DOCS_PATH"'
rm -rf "$d"
```
Expected: first line `OFF (default dir absent) — today's behavior` (on a host without `/workspace/docs`); second line `gate: ON <tmp>`. Confirms the validity gate turns grounding OFF when absent and ON when a markdown-bearing dir is present.

- [ ] **Step 9: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md CLAUDE.md
git commit -m "chore(dev-workflows): bump to 2.36.0; document \$DOCS_PATH grounding (README, CLAUDE.md, changelog)"
```

---

## Self-Review

**1. Spec coverage** (each spec section → task):
- §"Architecture 1" reference → Task 1. §"Architecture 2" agent → Task 2. §"Architecture 3" per-command wiring → Tasks 3–4. §4 `/document` consolidation → Task 5. §"Worked examples" (relation/structural_facts/diverges_from_precedent) → encoded in Task 2's contract. §6 failure modes → Global Constraints + Task 1 gate/dispatch + Task 2 hard rules. §7 container contract → out of scope (documented, operator-wired) — correctly no task. §8 verification → Task 6 Steps 6–8. §"Decision log" defaults → Global Constraints + Task 1 default-safety note. Version/README/CLAUDE.md → Task 6. No gaps.
- Bounding caps, `qmd update` never `--pull`, keyless `/idea`, grill-rank vs writer-attach, read-only tool set — all present with explicit verification steps.

**2. Placeholder scan:** No "TBD/TODO/handle appropriately". The two new files are given in full; wiring snippets are exact insertion text with exact anchors; every code step shows the content or command.

**3. Type/name consistency:** `resolve-docs-grounding`, `dispatch-docs-grounder`, `grill-rank`, `writer-attach`, `subagent_type: "dev-workflows:docs-grounder"`, output fields (`docs_references`, `docs_challenges`, `relation`, `structural_facts`, `retrieval`), and the five `kind` values are spelled identically across Tasks 1, 2, 3, 4, and the verification greps.

---

## Execution Handoff

See the "Execution Handoff" prompt after this file is saved.

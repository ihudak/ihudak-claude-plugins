# Counterpart-space documentation grounding — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teach `/document` (Jira mode) to ground a space-constrained run on the *other* space's existing documentation for the same feature — as read-only reference, never copied text and never as an image source.

**Architecture:** A new read-only agent (`counterpart-finder`) discovers the counterpart space's page(s) via in-tree keyword search + `git log --grep`, plus an optional explicit `--counterpart <JiraID|PR-url>` resolved through `diff-summarizer`'s host-aware strategies. Its `counterpart_references[]` output threads through a new Phase 5.6.5 into `doc-planner` (grounding + a write-strategy signal) and `doc-writer` (read-only reference), with `doc-reviewer` guarding against space-specific leakage. Shipped to all three marketplaces: Claude `dev-workflows` (primary), `mgd-claude-plugins` (1:1 port), `ihudak-copilot-plugins` (Copilot-adapted port).

**Tech Stack:** Claude Code / GitHub Copilot CLI plugin markdown (command, agent, skill files), JSON manifests (`plugin.json`, `marketplace.json`), mermaid-in-README, `jq` + `grep` for structural verification. No executable test framework — "tests" are structural/consistency checks.

## Global Constraints

- **Spec source of truth:** `docs/superpowers/specs/2026-07-15-counterpart-space-doc-grounding-design.md`. Every task traces to it.
- **Grounding only** — counterpart content is read, never copied; no structural mirroring, no port/translate.
- **Screenshots are comprehension-only** — counterpart screenshots NEVER enter the Phase 5.6 image candidate list and are NEVER used as doc images. Target images keep sourcing only from Phase 5.6's four sources.
- **Active only on space-constrained runs** — `target_spaces` must be exactly one space; both-space runs skip the feature and reject an explicit `--counterpart`.
- **Zero new external-API surface** — the `--counterpart` ref path reuses `diff-summarizer`'s existing resolver (gh for github.com when installed + local-git fallback; local-git-only for Bitbucket; NEVER Bitbucket REST).
- **No-leak rule** — never copy counterpart-space-specific UI paths, URLs, labels, defaults, or screenshots into the target doc (extends the existing `doc-planner:175` cross-product guardrail to cross-space).
- **Graceful no-op** — nothing found / ref unresolvable ⇒ record a note and behave exactly as today; never block a run.
- **Flag:** `--counterpart <JiraID | PR-url>`, a named flag (not positional), documented in every affected README.
- **Confirmation gate default:** always ask, high-confidence matches pre-selected.
- **Surgical-changes invariant (CLAUDE.md):** when a field/phase/edge is added, add every cross-reference in the same change; when renamed, update all references.
- **Commit convention:** this repo commits only when asked; the version bump + CHANGELOG is one commit per marketplace at that marketplace's final task. The executor confirms before committing/pushing. Push is out of scope for this plan unless the user asks.
- **Three-marketplace paths:**
  - Claude: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/`, repo `CLAUDE.md`, `.claude-plugin/marketplace.json`.
  - mgd: `/workspace/mgd-claude-plugins/plugins/dev-workflows/`, repo `CLAUDE.md`, `.claude-plugin/marketplace.json`.
  - Copilot: `/workspace/ihudak-copilot-plugins/dev-workflows/` (`skills/`, `agents/`, `.plugin/plugin.json`), `.github/plugin/marketplace.json`.

---

## File Structure (Claude primary — Tasks 1–9)

Base = `/workspace/ihudak-claude-plugins/plugins/dev-workflows/`

- **Create** `agents/counterpart-finder.md` — the discovery agent (Task 1).
- **Modify** `commands/document.md` — `--counterpart` parsing + signature (Task 2); new Phase 5.6.5 (Task 3); Phase 5.7 dispatch brief (Task 4); Phase 6.3 handoff contract (Task 5).
- **Modify** `agents/doc-planner.md` — input field, grounding step, write-strategy signal, cross-space guardrail (Task 4).
- **Modify** `agents/doc-writer.md` — input field + hard rules (Task 5).
- **Modify** `agents/doc-reviewer.md` — review dimensions (Task 6).
- **Modify** `/workspace/ihudak-claude-plugins/CLAUDE.md` — workflow map, invariant, counts (Task 7).
- **Modify** `README.md` — command row, use-case subsection, agents table, dimension count, conditional diagram (Task 8).
- **Modify** `.claude-plugin/plugin.json`, `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`, `CHANGELOG.md` (Task 9).

Ports: **Task 10** (mgd 1:1), **Task 11** (Copilot adapted).

---

### Task 1: Create the `counterpart-finder` agent (Claude)

**Files:**
- Create: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/counterpart-finder.md`

**Interfaces:**
- Consumes: `{repo_root, target_space, counterpart_space, profile, feature_summary, jira_key, counterpart_ref, diff_highlights}`.
- Produces: `status ∈ {OK, EMPTY, ERROR}` and `counterpart_references[]` with fields `{source_kind, path, pr_ref, space, salient_summary, section_outline, is_shared_into_target, screenshots_seen[].{path, comprehension_only}, match_confidence, match_reason}`; `notes`. These exact field names are consumed by Tasks 3, 4, 5.

- [ ] **Step 1: Write the agent file** with this exact content:

````markdown
---
name: counterpart-finder
description: For a space-constrained /document run, finds the OTHER (counterpart) space's existing documentation for the same feature and returns it as read-only grounding — concepts, terminology, verified facts, section outline, and comprehension-only screenshot paths. Two layers — auto in-tree discovery (keyword overlap + git log --grep) and an optional explicit ref (Jira key or PR URL) resolved via diff-summarizer's host-aware strategies. Never writes; never adds images to the doc pipeline. Model tier assigned by the caller per the model-routing policy (no fixed pin).
tools: ["Read", "Glob", "Grep", "LS", "Bash"]
---

Find the counterpart space's documentation for a feature so the writer can ground on it. The run documents ONE space (`target_space`); the counterpart is the OTHER space in the docs repo. Read-only reference discovery — never a writer, never an image source.

## Inputs

```yaml
repo_root:          <absolute path to the docs repo root>
target_space:       saas | managed        # the space THIS run documents
counterpart_space:  saas | managed        # the OTHER space to search (never equal to target_space)
profile:            <resolved docs-profile — supplies spaces[].content_root, cross_space_override>
feature_summary:    <2–4 sentences from jira-reader themes + VI goal>
jira_key:           <the VI / focus Jira key, e.g. PRODUCT-1234>
counterpart_ref:    <optional: a Jira key or PR URL passed via --counterpart; null when absent>
diff_highlights:    <optional: key filenames/symbols from diff-summarizer to seed topical search>
```

Refuse to run without `repo_root`, `target_space`, `counterpart_space`, and a non-empty `feature_summary`. If `counterpart_space == target_space`, return `status: ERROR` (the caller must not invoke this on an unconstrained run).

## Process

### Layer 1 — auto discovery (always runs)

1. **Scope to the counterpart content root.** From `profile.spaces[]`, take the `content_root` (and `snippet_root`) whose space is `counterpart_space` (dynatrace-docs: `dynatrace/_content` for `saas`, `managed/_content` for `managed`). Search only under those roots.
2. **Keyword-overlap search.** Apply the `doc-location-finder` scoring technique: index each page's frontmatter (`title`/`description`/`tags`) + first 50 body lines, score keyword overlap against `feature_summary` (minus stopwords) plus `diff_highlights`. Keep matches above the overlap threshold.
3. **Merge-commit backstop.** Run `git -C <repo_root> log --all -E --grep="<jira_key>" -n 20 --name-only` and union any counterpart-root pages it touched (catches a page named unlike the feature).
4. Read each match and extract the grounding digest (see Output).

### Layer 2 — explicit ref (only when `counterpart_ref` is non-null)

1. Classify `counterpart_ref`: a Jira key (`^[A-Z][A-Z0-9]+-[0-9]+`) → resolve to its merge/PR via `git -C <repo_root> log --all -E --grep`; a PR URL → resolve via `diff-summarizer`'s host-aware strategies (gh for github.com when installed, else local-git PR-ref / merge-commit grep; local-git-only for Bitbucket — NEVER Bitbucket REST). Mechanics: `${CLAUDE_PLUGIN_ROOT}/agents/diff-summarizer.md` "Local-git strategies".
2. Take the ADDED/MODIFIED files under the counterpart `content_root`/`snippet_root` and read them. For an unmerged PR head not present locally, `git fetch` the ref exactly as `diff-summarizer` does; on failure record it in `notes` as unresolved.
3. Extract the grounding digest; mark these `source_kind: pr_ref`.

### For every match (both layers)

- **is_shared_into_target**: `true` when `profile.cross_space_override` already pulls this page's `content_root`-relative path into the `target_space` render (e.g. it appears in the Managed docstack allowlist). This is the "target may already be covered" signal.
- **screenshots_seen**: enumerate image references on the page (paths only), each flagged `comprehension_only: true`. NEVER stage, copy, or return these as candidate images.

## Output

```yaml
status: OK | EMPTY | ERROR
counterpart_references:
  - source_kind:           in_tree | pr_ref
    path:                  <absolute path when in_tree; null for pr_ref>
    pr_ref:                <resolved ref/url when pr_ref; null when in_tree>
    space:                 <counterpart_space>
    salient_summary:       <writer-facing digest: concepts, verified facts, terminology; NO target-space claims>
    section_outline:       [<heading>, ...]
    is_shared_into_target: true | false
    screenshots_seen:
      - path:              <path>
        comprehension_only: true
    match_confidence:      high | medium | low
    match_reason:          <why this page matched>
notes: <when EMPTY: why nothing found; when a ref was unresolved: which and why>
```

`status: EMPTY` → `counterpart_references: []` and `notes` explains. The caller proceeds as a normal single-space run.

## Hard rules

- NEVER write or edit any file. Read-only.
- NEVER search or return pages outside `counterpart_space`'s content roots.
- NEVER add, stage, copy, or recommend a counterpart screenshot as a doc image — `screenshots_seen` is comprehension-only.
- NEVER make HTTPS/REST calls to Bitbucket. Reuse `diff-summarizer`'s local-git strategies; gh is allowed only for github.com, only when installed, with local-git fallback.
- NEVER carry space-specific UI paths/URLs/labels into `salient_summary` — summarise the feature, not the SaaS/Managed specifics.
````

- [ ] **Step 2: Verify frontmatter + tooling + read-only contract**

Run:
```bash
A=/workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/counterpart-finder.md
head -5 "$A" | grep -q '^name: counterpart-finder' && echo NAME_OK
grep -q '"Bash"' "$A" && echo BASH_OK
grep -q 'comprehension_only' "$A" && echo SCREENSHOT_RULE_OK
grep -qi 'NEVER write or edit any file' "$A" && echo READONLY_OK
```
Expected: `NAME_OK`, `BASH_OK`, `SCREENSHOT_RULE_OK`, `READONLY_OK` all print.

- [ ] **Step 3: Verify YAML frontmatter parses** (fences balanced, `tools` is a list)

Run: `awk 'NR==1{f=($0=="---")?1:0} END{print (f?"FM_OK":"FM_BAD")}' "$A"` — Expected: `FM_OK`.

---

### Task 2: `--counterpart` flag parsing + signature (Claude)

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md` (frontmatter description line ~3; Signature line ~9; Phase 0 argument parsing, step 7 at ~line 93–101)

**Interfaces:**
- Produces: a `counterpart_ref` run value (a Jira key / PR URL string, or `null`) consumed by Task 3's Phase 5.6.5.

- [ ] **Step 1: Extend the Signature line.** In the `Signature:` paragraph (~line 9), change the signature to `PRODUCT-NNNN [saas|managed] [--counterpart <JiraID|PR-url>]` and append one sentence:

> `--counterpart <JiraID | PR-url>` is an optional named flag (valid only on a space-constrained run) that points at the OTHER space's documentation for this feature — a Jira key or a PR URL (merged or not). It is used as **read-only grounding**; on a both-space run it is rejected. See Phase 5.6.5.

- [ ] **Step 2: Add the flag to the frontmatter `description`** (~line 3): append `Optional --counterpart <JiraID|PR-url> grounds a space-constrained run on the other space's existing docs (read-only).` to the end of the description string (keep it one line).

- [ ] **Step 3: Add flag parsing in Phase 0.** Immediately after step 7 (the space-constraint parse, ending ~line 101), insert a new step:

```markdown
8. **Parse the optional `--counterpart` flag.** Scan `$ARGUMENTS` for a `--counterpart <value>` token (named flag; `<value>` is the next whitespace-separated token, a Jira key `^[A-Z][A-Z0-9]+-[0-9]+` or a URL). Record `counterpart_ref = <value>` (default `null` when absent).
   - **`--counterpart` present but `space_constraint == none`** (both-space run) → do NOT silently accept. Ask:
     ```
     "--counterpart grounds a single documented space on the OTHER space, so it needs a space constraint (saas|managed). This run covers both spaces. How would you like to proceed?"
     choices: ["Drop --counterpart — cover both spaces (Recommended)", "Constrain to saas", "Constrain to managed", "Cancel"]
     ```
     "Drop" → `counterpart_ref = null`. "Constrain to saas/managed" → set `space_constraint` accordingly and keep `counterpart_ref`. "Cancel" → stop.
   - **`--counterpart` value malformed** (not a Jira key or URL) → do NOT guess. Ask:
     ```
     "'<value>' isn't a valid --counterpart target. It should be a Jira key (e.g. PROJ-1234) or a PR URL. How would you like to proceed?"
     choices: ["Re-enter a valid Jira key / PR URL", "Drop --counterpart (Recommended)", "Cancel"]
     ```
     "Re-enter" → take the new value. "Drop" → `counterpart_ref = null`. "Cancel" → stop.

   When both the both-space-run rejection and a malformed value apply, resolve the both-space rejection first, then re-validate any value the user keeps.
```

**Also amend the existing step 7** (space-constraint parser) so a `--counterpart <value>` flag pair is never mistaken for the space token. Change its opening clause `the optional second whitespace-separated token is the space constraint.` to: `**First set aside any --counterpart <value> flag pair** (parsed in step 8) so it is never mistaken for the space token; the space constraint is then the first remaining whitespace-separated token after <JIRA_KEY> (if any).`

*(Note: verify the actual step count in Phase 0 before inserting — if the last existing step is not 7, insert as `last+1` and keep numbering contiguous.)*

- [ ] **Step 4: Verify**

Run:
```bash
D=/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md
grep -q -- '--counterpart <JiraID|PR-url>' "$D" && echo SIG_OK
grep -q 'Parse the optional `--counterpart` flag' "$D" && echo PARSE_OK
grep -q 'counterpart_ref = null' "$D" && echo DEFAULT_OK
grep -qi 'This run covers both spaces' "$D" && echo BOTHRUN_REJECT_OK
```
Expected: `SIG_OK`, `PARSE_OK`, `DEFAULT_OK`, `BOTHRUN_REJECT_OK`.

---

### Task 3: Phase 5.6.5 — counterpart discovery sub-phase (Claude)

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md` (insert between end of Phase 5.6 at ~line 427 and `## Phase 5.7` at ~line 429)

**Interfaces:**
- Consumes: `counterpart_ref` (Task 2), `target_spaces` (Phase 4.5), `profile`, `jira-reader` handoff, Phase 5 diff summaries.
- Produces: `counterpart_references[]` (schema from Task 1) consumed by Tasks 4 and 5.

- [ ] **Step 1: Insert the new phase** (exact content):

````markdown
## Phase 5.6.5 — Counterpart-space reference discovery

**Run only when `target_spaces` is a single space** (`[saas]` or `[managed]`). A run that already covers both spaces has no "other" space → skip entirely and carry `counterpart_references = []`. (A `--counterpart` on a both-space run was already resolved in Phase 0.)

The **counterpart space** is the one space in `profile.spaces[]` not in `target_spaces`. Discover its existing documentation for this feature and carry it forward as **read-only grounding** — concepts, terminology, facts, section structure, and comprehension-only screenshots. It is never copied into the target doc and never an image source (Phase 5.6 remains the only image source).

Invoke `counterpart-finder`:

→ Agent (subagent_type: "dev-workflows:counterpart-finder", model: `<planning_model — §9>`):
  > "Discover counterpart-space grounding:
  >
  > repo_root:          [docs_repo_path]
  > target_space:       [the single member of target_spaces]
  > counterpart_space:  [the profile.spaces[] space not in target_spaces]
  > profile:            [Phase 0 profile]
  > feature_summary:    [2–4 sentences from the jira-reader themes + VI goal]
  > jira_key:           [<JIRA_KEY> (focus_key when set)]
  > counterpart_ref:    [the --counterpart value from Phase 0, or null]
  > diff_highlights:    [key filenames/symbols from the Phase 5 diff summaries, optional]"

Handle the result:

- **`status: EMPTY`** → set `counterpart_references = []`; print the `notes` line and proceed to Phase 5.7 unchanged.
- **`status: ERROR`** → log the reason, set `counterpart_references = []`, proceed (never block).
- **`status: OK`** → present the candidates and confirm (**always ask**; pre-select the `match_confidence: high` rows):
  ```
  "Found <N> counterpart-space page(s) to ground on:
   | # | Page | Space | Confidence | Already in <target> render? | Why |
   ...
   How should I use these?"
  choices: ["Ground on the recommended (high-confidence) set (Recommended)", "Pick a subset (you'll choose)", "Provide a --counterpart ref instead (you'll be prompted)", "Skip grounding", "Other… (describe)"]
  ```
  - **recommended set** → keep the `high` rows.
  - **subset** → user picks rows.
  - **provide a ref** → take a free-text Jira key / PR URL, re-invoke `counterpart-finder` with `counterpart_ref` set, then confirm again.
  - **skip** → `counterpart_references = []`.

**Shared-page signal.** For any kept reference with `is_shared_into_target: true`, tell the user the target space may **already be covered** by that page (its render is pulled in via `cross_space_override`) — the work may be a small `{{#if project='<target>'}}` delta, not a new page. Carry this into Phase 5.7 (feeds the planner's write-strategy recommendation) and Phase 5.9.

Record the confirmed `counterpart_references[]`. It threads into Phase 5.7 (`doc-planner`) and Phase 6.3 (`doc-writer`); it never alters the Phase 5.6 image set.
````

- [ ] **Step 2: Verify placement + content**

Run:
```bash
D=/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md
grep -n 'Phase 5.6.5 — Counterpart-space reference discovery' "$D"
awk '/## Phase 5.6 —/{a=NR} /## Phase 5.6.5 —/{b=NR} /## Phase 5.7 —/{c=NR} END{print (a<b && b<c)?"ORDER_OK":"ORDER_BAD"}' "$D"
grep -q 'subagent_type: "dev-workflows:counterpart-finder"' "$D" && echo DISPATCH_OK
grep -q 'counterpart_references = \[\]' "$D" && echo NOOP_OK
grep -q 'always ask' "$D" && echo GATE_OK
```
Expected: the header line prints; `ORDER_OK`; `DISPATCH_OK`; `NOOP_OK`; `GATE_OK`.

---

### Task 4: Thread `counterpart_references[]` into `doc-planner` (Claude)

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/doc-planner.md` (Inputs block ~line 23; a new Process step; the cross-product guardrail at ~line 175; output note)
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md` (Phase 5.7 dispatch brief ~lines 435–447)

**Interfaces:**
- Consumes: `counterpart_references[]` (Task 1/3).
- Produces: `write_strategy` recommendations informed by `is_shared_into_target`; no schema rename.

- [ ] **Step 1: Add the input field.** In `doc-planner.md` Inputs (after the `target_spaces:` line ~23), add:

```yaml
counterpart_references: <array of counterpart-finder entries (read-only grounding); [] when none or on a both-space run. Each: {source_kind, path|pr_ref, space, salient_summary, section_outline, is_shared_into_target, screenshots_seen[], match_confidence}>
```

- [ ] **Step 2: Add a Process step for grounding + the write-strategy signal.** Add after the source-truth verification step (the one at ~line 96, "Source-truth verification"), a new numbered step:

```markdown
N. **Ground on the counterpart space (read-only).** When `counterpart_references` is non-empty, use each entry's `salient_summary` and `section_outline` to inform topic/section planning for the *target* space — concepts, terminology, and completeness. Author the plan for the target space; do NOT copy the counterpart's space-specific detail (see the cross-space rule below). **Write-strategy signal:** an entry with `is_shared_into_target: true` is strong evidence the target render is already served by that shared page — prefer `conditional` (an in-place `{{#if project='<target>'}}` delta) over a new `content_root` page, and flag in `notes` that the target "may already be covered". `screenshots_seen` are comprehension-only — never plan them as target images.
```

- [ ] **Step 3: Extend the cross-product guardrail to cross-space.** At the existing guardrail (`doc-planner.md` ~line 175, "NEVER let a cross-product 'minimal touch' parity reference introduce content specific to the OTHER product's implementation…"), append:

```markdown
- The same rule applies **cross-space**: when grounding on a `counterpart_references` page, never plan target-doc content that carries the counterpart space's specific UI paths, URLs, labels, defaults, or screenshots. Consult the counterpart for concepts/terminology/structure; author target-space specifics from the target space's own source.
```

- [ ] **Step 4: Pass the field in the Phase 5.7 dispatch brief.** In `document.md` Phase 5.7 (after the `target_spaces:` line ~447 in the doc-planner brief), add:

```
  > counterpart_references: [the confirmed counterpart_references from Phase 5.6.5; [] when none]"
```
(Move the closing quote to the new last line.)

- [ ] **Step 5: Verify**

Run:
```bash
P=/workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/doc-planner.md
D=/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md
grep -q 'counterpart_references:' "$P" && echo PLANNER_INPUT_OK
grep -qi 'Ground on the counterpart space' "$P" && echo GROUND_STEP_OK
grep -qi 'The same rule applies \*\*cross-space\*\*' "$P" && echo GUARDRAIL_OK
grep -qi 'is_shared_into_target: true' "$P" && echo SIGNAL_OK
grep -q 'counterpart_references: \[the confirmed' "$D" && echo DISPATCH_FIELD_OK
```
Expected: all five OK lines.

---

### Task 5: Thread `counterpart_references[]` into `doc-writer` + screenshot rule (Claude)

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/doc-writer.md` (Inputs ~line 20; Hard rules)
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md` (Phase 6.3 handoff-file contract ~line 584)

**Interfaces:**
- Consumes: `counterpart_references[]` from the handoff file (read-only).

- [ ] **Step 1: Add the input field.** In `doc-writer.md` Inputs (after the `target_spaces, profile, docs_repo_path` bullet ~line 20), add:

```markdown
- `counterpart_references[]` — read-only grounding from `counterpart-finder` (Phase 5.6.5): `{source_kind, path|pr_ref, space, salient_summary, section_outline, is_shared_into_target, screenshots_seen[], match_confidence}`; `[]` when none. Consulted for concepts/terminology/structure only.
```

- [ ] **Step 2: Add hard rules** to `doc-writer.md`'s hard-rules section:

```markdown
- NEVER copy counterpart-space-specific content into the target doc — no counterpart UI paths, URLs, labels, defaults, or verbatim prose. `counterpart_references` is grounding; author target-space specifics from the target space's own source.
- NEVER use a `counterpart_references[].screenshots_seen[]` image as a doc image — they are comprehension-only. Target images come only from the handoff `screenshots[]` (Phase 5.6).
```

- [ ] **Step 3: Add the field to the Phase 6.3 handoff contract.** In `document.md` Phase 6.3 "Write the handoff file" (the `doc-writer` input contract listing ~line 584), add `counterpart_references` to the enumerated fields (after `target_spaces`, `profile`, `docs_repo_path`).

- [ ] **Step 4: Verify**

Run:
```bash
W=/workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/doc-writer.md
D=/workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/document.md
grep -q 'counterpart_references\[\]' "$W" && echo WRITER_INPUT_OK
grep -qi 'NEVER copy counterpart-space-specific content' "$W" && echo NOLEAK_OK
grep -qi 'comprehension-only' "$W" && echo SCREENSHOT_OK
grep -q 'counterpart_references' "$D" && echo HANDOFF_OK
```
Expected: `WRITER_INPUT_OK`, `NOLEAK_OK`, `SCREENSHOT_OK`, `HANDOFF_OK`.

---

### Task 6: `doc-reviewer` cross-space checks (Claude)

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/doc-reviewer.md` (Review dimensions table ~line 35–46)

**Interfaces:**
- Consumes: the written docs + `counterpart_references` context (passed in the review brief). No new output schema — findings use the existing BLOCKER/MAJOR/MINOR bands.

- [ ] **Step 1: Add a review dimension row** to the Review dimensions table:

```markdown
| Cross-space grounding integrity | When the run was space-constrained and grounded on a counterpart space: the target doc carries NO counterpart-space-specific UI paths, URLs, labels, or defaults, and NO image whose provenance is a counterpart screenshot (`screenshots_seen`). Leaked space-specific detail is a BLOCKER; a copied counterpart screenshot is a BLOCKER. |
```

- [ ] **Step 2: Update the dimension count** if the reviewer prose states a fixed number (e.g. "11 dimensions"): search and bump by 1.

Run: `grep -n -iE '[0-9]+ (dimensions|review dimensions)' /workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/doc-reviewer.md` — if a count appears, increment it in place.

- [ ] **Step 3: Verify**

Run:
```bash
R=/workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/doc-reviewer.md
grep -qi 'Cross-space grounding integrity' "$R" && echo DIM_OK
grep -qi 'counterpart screenshot' "$R" && echo SCREENSHOT_CHECK_OK
```
Expected: `DIM_OK`, `SCREENSHOT_CHECK_OK`.

---

### Task 7: CLAUDE.md workflow map, invariant, counts (Claude repo)

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/CLAUDE.md`

- [ ] **Step 1: Update the `/document (Jira)` workflow line.** In the workflow-relationships block, insert the counterpart step into the `/document (Jira)` pipeline after `doc-location-finder`:

Find: `/document (Jira)   → jira-reader → [diff-summarizer×N (parallel)] → [doc-location-finder] → [doc-planner]`
Replace with: `/document (Jira)   → jira-reader → [diff-summarizer×N (parallel)] → [doc-location-finder] → [counterpart-finder (space-constrained runs)] → [doc-planner]`

- [ ] **Step 2: Add the agent to the "used by" list.** In the agent-usage list, add:
```
                      └── counterpart-finder (used by /document Jira mode, space-constrained runs)
```

- [ ] **Step 3: Add a key invariant** under "Key invariants for `/document` (Jira mode) and `/epics`":
```markdown
- Counterpart-space grounding (`counterpart-finder`, Phase 5.6.5) runs only on space-constrained runs; it is **read-only** — never copies counterpart-space-specific detail or screenshots into the target doc; `--counterpart <JiraID|PR-url>` reaches an unmerged counterpart PR via the existing local-git resolver (zero new external API); nothing found ⇒ the run behaves exactly as today
```

- [ ] **Step 4: Verify**

Run:
```bash
C=/workspace/ihudak-claude-plugins/CLAUDE.md
grep -q 'counterpart-finder (space-constrained runs)' "$C" && echo MAP_OK
grep -q 'counterpart-finder (used by /document' "$C" && echo USEDBY_OK
grep -qi 'Counterpart-space grounding (`counterpart-finder`, Phase 5.6.5)' "$C" && echo INVARIANT_OK
```
Expected: `MAP_OK`, `USEDBY_OK`, `INVARIANT_OK`.

---

### Task 8: README documentation + conditional diagram (Claude)

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/README.md`

- [ ] **Step 1: Update the `/document` command-table row** (~line 12): in the signature cell add `[--counterpart <JiraID\|PR-url>]`; in the Jira-mode description append: "On a space-constrained run, `--counterpart` (or auto-discovery) grounds the doc on the other space's existing pages — read-only, never copied, never an image source."

- [ ] **Step 2: Add a use-case subsection.** After the "Which docs command?" paragraph (~line 32), add:

```markdown
**Counterpart-space grounding (`/document <VI> saas|managed`).** When you document one space, someone may already have written the *other* space's docs for the same feature. `/document` discovers that counterpart page (in-tree keyword search + `git log --grep`, or an explicit `--counterpart <JiraID|PR-url>` for an unmerged PR) and hands it to the writer as **read-only grounding** — concepts, terminology, and structure to consult, never text to copy and never screenshots to reuse (Managed and SaaS UIs differ; target images still come from `$VAULT_PATH`). If the counterpart page is already pulled into your target's render, the run tells you the space may already be covered.
```

- [ ] **Step 3: Add the agent to the sub-agents table** (near the `doc-writer`/`jira-reader` rows ~line 239):

```markdown
| `counterpart-finder` | per routing | For a space-constrained `/document` run, finds the OTHER space's existing docs for the feature (in-tree keyword search + `git log --grep`, or an explicit `--counterpart` Jira/PR ref via the diff-summarizer resolver) and returns read-only grounding. Never writes; never an image source. |
```

- [ ] **Step 4: Bump the `doc-reviewer` dimension count** in its table row (~line 221) if it states "11 dimensions" → "12 dimensions" (match Task 6's count change).

- [ ] **Step 5: Conditional diagram update.** Check whether a `/document`-specific phase diagram exists:

Run: `grep -n '```mermaid' /workspace/ihudak-claude-plugins/plugins/dev-workflows/README.md`

The role-overview diagram (~line 46) shows `/document` as a single role node — it does **not** need a counterpart edge (Phase 5.6.5 is internal to `/document`). Only if a diagram depicts `/document`'s *internal phases* (doc-location-finder → doc-planner → …), add a `counterpart-finder` node between location-finding and planning. If no such phase-level diagram exists, this step is a no-op — record that in the commit message.

- [ ] **Step 6: Verify** (including mermaid fence balance)

Run:
```bash
RM=/workspace/ihudak-claude-plugins/plugins/dev-workflows/README.md
grep -q -- '--counterpart <JiraID\\|PR-url>' "$RM" && echo SIG_OK
grep -qi 'Counterpart-space grounding' "$RM" && echo SECTION_OK
grep -q '`counterpart-finder`' "$RM" && echo AGENT_ROW_OK
test $(( $(grep -c '```' "$RM") % 2 )) -eq 0 && echo FENCES_BALANCED
```
Expected: `SIG_OK`, `SECTION_OK`, `AGENT_ROW_OK`, `FENCES_BALANCED`.

---

### Task 9: Version bump + CHANGELOG + marketplace description (Claude)

**Files:**
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json`
- Modify: `/workspace/ihudak-claude-plugins/plugins/dev-workflows/CHANGELOG.md`

- [ ] **Step 1: Read current version.** `grep '"version"' /workspace/ihudak-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json` (currently `2.32.1`). New version = **2.33.0** (new feature → minor bump).

- [ ] **Step 2: Bump `plugin.json`** `version` → `2.33.0`.

- [ ] **Step 3: Bump `marketplace.json`** dev-workflows `version` → `2.33.0`. In its `description`, bump the subagent count (`Thirty reusable subagents` → `Thirty-one`) and add `counterpart-finder` to the enumerated agent list, and note the new counterpart-grounding capability in the `/document` clause.

- [ ] **Step 4: Add CHANGELOG entry** at the top of `CHANGELOG.md`:

```markdown
## [2.33.0] — 2026-07-15

### Added
- **`/document` (Jira mode): counterpart-space grounding.** A space-constrained run (`saas`|`managed`) now discovers the OTHER space's existing documentation for the same feature and hands it to the writer as **read-only grounding** — concepts, terminology, and structure to consult, never text to copy and never screenshots to reuse. New `counterpart-finder` agent (in-tree keyword search + `git log --grep`, plus an optional `--counterpart <JiraID|PR-url>` for an unmerged counterpart PR, resolved via the existing diff-summarizer strategies — zero new external API). New Phase 5.6.5; `counterpart_references[]` threads into `doc-planner` (grounding + a "target may already be covered" write-strategy signal) and `doc-writer`; `doc-reviewer` gains a cross-space leak/screenshot-provenance check.
```

- [ ] **Step 5: Verify JSON validity + version parity**

Run:
```bash
jq -e '.version=="2.33.0"' /workspace/ihudak-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json >/dev/null && echo PLUGIN_OK
jq -e '.plugins[]|select(.name=="dev-workflows")|.version=="2.33.0"' /workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json >/dev/null && echo MP_OK
grep -q '## \[2.33.0\]' /workspace/ihudak-claude-plugins/plugins/dev-workflows/CHANGELOG.md && echo CL_OK
```
Expected: `PLUGIN_OK`, `MP_OK`, `CL_OK`.

- [ ] **Step 6: Commit the Claude changes** (after user confirmation per repo convention):

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows CLAUDE.md .claude-plugin/marketplace.json
git commit -m "feat(dev-workflows): counterpart-space doc grounding for /document; bump to 2.33.0

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 10: mgd-claude-plugins — 1:1 port

**Files (mirror of Tasks 1–9 under the mgd tree):**
- Create: `/workspace/mgd-claude-plugins/plugins/dev-workflows/agents/counterpart-finder.md`
- Modify: `commands/document.md`, `agents/doc-planner.md`, `agents/doc-writer.md`, `agents/doc-reviewer.md`, `README.md` under `/workspace/mgd-claude-plugins/plugins/dev-workflows/`
- Modify: `/workspace/mgd-claude-plugins/CLAUDE.md`, `/workspace/mgd-claude-plugins/.claude-plugin/marketplace.json`, `plugins/dev-workflows/.claude-plugin/plugin.json`, `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:** identical to the Claude primary; this is the same Claude Code marketplace.

- [ ] **Step 1: Confirm the two trees are in parity before porting** (so a verbatim copy is safe):

```bash
for f in agents/doc-planner.md agents/doc-writer.md agents/doc-reviewer.md commands/document.md; do
  diff -q /workspace/ihudak-claude-plugins/plugins/dev-workflows/$f /workspace/mgd-claude-plugins/plugins/dev-workflows/$f
done
```
Expected: no differences on the pre-change baselines (if a file differs, reconcile the port by hand rather than copying — note it).

- [ ] **Step 2: Copy the new agent verbatim.**
```bash
cp /workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/counterpart-finder.md \
   /workspace/mgd-claude-plugins/plugins/dev-workflows/agents/counterpart-finder.md
```

- [ ] **Step 3: Apply the same edits** from Tasks 2–8 to the mgd copies of `commands/document.md`, `agents/doc-planner.md`, `agents/doc-writer.md`, `agents/doc-reviewer.md`, `README.md`, and `CLAUDE.md`. Because the files are parity copies, apply the **same** old→new edits. Adjust **only** identity strings that already differ in mgd: marketplace name (`mgd-plugins`), author (`Dynatrace Managed`), and any `ihudak/ai-containers` → `Dynatrace-Internal/mgd-ai-containers` URL. Do NOT change command syntax — mgd is Claude Code, so `/document` and `--counterpart` are identical.

- [ ] **Step 4: Version bump + marketplace + CHANGELOG.** Bump `plugins/dev-workflows/.claude-plugin/plugin.json` and the dev-workflows entry in `/workspace/mgd-claude-plugins/.claude-plugin/marketplace.json` from `2.32.1` → `2.33.0`; bump the subagent count + agent enumeration in the marketplace description (it lists all agents by name — add `counterpart-finder`). Add the same `## [2.33.0] — 2026-07-15` CHANGELOG entry, plus the trailer line `Ported 1:1 from the ihudak-claude-plugins sibling repo.`

- [ ] **Step 5: Verify parity + validity**

Run:
```bash
diff -q /workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/counterpart-finder.md \
        /workspace/mgd-claude-plugins/plugins/dev-workflows/agents/counterpart-finder.md && echo AGENT_PARITY_OK
jq -e '.plugins[]|select(.name=="dev-workflows")|.version=="2.33.0"' /workspace/mgd-claude-plugins/.claude-plugin/marketplace.json >/dev/null && echo MGD_MP_OK
grep -q 'Phase 5.6.5 — Counterpart-space reference discovery' /workspace/mgd-claude-plugins/plugins/dev-workflows/commands/document.md && echo MGD_PHASE_OK
```
Expected: `AGENT_PARITY_OK`, `MGD_MP_OK`, `MGD_PHASE_OK`.

- [ ] **Step 6: Commit the mgd changes** (after user confirmation; note mgd `main` has PR branch protection — direct push bypasses it, so do not push unless the user explicitly opts for direct-push):

```bash
cd /workspace/mgd-claude-plugins
git add plugins/dev-workflows CLAUDE.md .claude-plugin/marketplace.json
git commit -m "feat(dev-workflows): counterpart-space doc grounding for /document (1:1 port); bump to 2.33.0

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 11: ihudak-copilot-plugins — Copilot-adapted port

**Files (Copilot conventions):**
- Create: `/workspace/ihudak-copilot-plugins/dev-workflows/agents/counterpart-finder.md` (agent body; **no** frontmatter `model:` pin)
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/document/SKILL.md` (the `document:` keyword-trigger skill — the phase edits)
- Modify: `agents/doc-planner.md`, `agents/doc-writer.md`, `agents/doc-reviewer.md`, `README.md` under `/workspace/ihudak-copilot-plugins/dev-workflows/`
- Modify: `.plugin/plugin.json`, `/workspace/ihudak-copilot-plugins/.github/plugin/marketplace.json`, `CHANGELOG.md`

**Interfaces:** same behavior and same `--counterpart` flag; only the plumbing differs (skills vs commands; `task(agent_type:…)` dispatch vs `subagent_type`; no frontmatter model pin).

- [ ] **Step 1: Inspect the Copilot document skill + a sample agent** to mirror the exact conventions (dispatch syntax, agent frontmatter shape):
```bash
sed -n '1,15p' /workspace/ihudak-copilot-plugins/dev-workflows/agents/doc-planner.md
grep -n 'task(agent_type' /workspace/ihudak-copilot-plugins/dev-workflows/skills/document/SKILL.md | head
grep -n -iE 'phase 5.6|phase 5.7|image candidate|doc-planner' /workspace/ihudak-copilot-plugins/dev-workflows/skills/document/SKILL.md | head
```

- [ ] **Step 2: Author the Copilot `counterpart-finder` agent.** Copy the Claude agent body (Task 1) but strip any `model:` frontmatter (Copilot agents carry none — the caller pins the tier at dispatch). Keep `tools` and everything else identical. In the "Layer 2" prose, reference the Copilot `diff-summarizer` agent path.

- [ ] **Step 3: Port the phase edits into `skills/document/SKILL.md`.** Apply the same Phase 5.6.5 block and the same flag/handoff/dispatch edits, translated to Copilot syntax:
  - dispatch: `task(agent_type: "dev-workflows:counterpart-finder", model: <strong-tier>)` instead of the `→ Agent (subagent_type: …)` form.
  - flag surface: `document: <VI> managed --counterpart <JiraID|PR-url>` (keyword-trigger phrasing).
  - all field names (`counterpart_references[]`, etc.) stay identical.

- [ ] **Step 4: Port the `doc-planner` / `doc-writer` / `doc-reviewer` edits** (Tasks 4–6) into the Copilot agents, matching their existing structure.

- [ ] **Step 5: README + version + CHANGELOG.** Add the use-case subsection + `--counterpart` to the `document:` docs and the sub-agent table (30→31 rows; the Copilot README already has a full agent table). Update any `implement:`/phase diagram only if it depicts `document:` internals. Bump `.plugin/plugin.json` and the `.github/plugin/marketplace.json` dev-workflows entry `2.1.2` → `2.2.0` (minor — new feature); bump the subagent count (`Thirty dispatched sub-agents` → `Thirty-one`). Add a `## [2.2.0] — 2026-07-15` CHANGELOG entry (mirror Task 9's prose, Copilot-flavored).

- [ ] **Step 6: Verify Copilot conventions**

Run:
```bash
CA=/workspace/ihudak-copilot-plugins/dev-workflows/agents/counterpart-finder.md
test -f "$CA" && ! grep -q '^model:' "$CA" && echo NO_MODEL_PIN_OK
grep -q 'task(agent_type: "dev-workflows:counterpart-finder"' /workspace/ihudak-copilot-plugins/dev-workflows/skills/document/SKILL.md && echo DISPATCH_OK
jq -e '.plugins[]|select(.name=="dev-workflows")|.version=="2.2.0"' /workspace/ihudak-copilot-plugins/.github/plugin/marketplace.json >/dev/null && echo COPILOT_MP_OK
grep -q 'Counterpart-space grounding' /workspace/ihudak-copilot-plugins/dev-workflows/README.md && echo COPILOT_README_OK
```
Expected: `NO_MODEL_PIN_OK`, `DISPATCH_OK`, `COPILOT_MP_OK`, `COPILOT_README_OK`.

- [ ] **Step 7: Commit the Copilot changes** (after user confirmation):

```bash
cd /workspace/ihudak-copilot-plugins
git add dev-workflows .github/plugin/marketplace.json
git commit -m "feat(dev-workflows): counterpart-space doc grounding for document: (Copilot port); bump to 2.2.0

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage** (each spec section → task):
- §4.1 Concept (space-constrained, symmetric) → Task 3 (Phase 5.6.5 counterpart-space derivation), Task 1 (`counterpart_space` input).
- §4.2 Discovery (auto + pointer, confirmation gate, graceful no-op) → Task 1 (both layers), Task 2 (flag), Task 3 (gate + no-op).
- §4.3 `counterpart_references[]` contract → Task 1 (Output schema); consumed Tasks 3/4/5.
- §4.4 Phase-flow integration (5.6.5, agent, planner signal, writer handoff) → Tasks 3, 4, 5.
- §4.5 Screenshots (comprehension-only, reviewer check) → Task 1 (`screenshots_seen`), Task 5 (writer rule), Task 6 (reviewer check).
- §4.6 Guardrails (no-leak, shared-page, both-run, zero-API) → Task 2 (both-run), Task 4 (guardrail + signal), Task 1 (zero-API rules).
- §4.7 Reviewer additions → Task 6.
- §4.8 Argument surface → Task 2.
- §5 Rollout (Claude / mgd 1:1 / Copilot adapted; README + diagram + CLAUDE.md + version + CHANGELOG each) → Tasks 7–11.
- §6 Resolved defaults (flag name, gate) → Task 2 (flag), Task 3 (gate).
- §7 Success criteria → covered by verification steps in Tasks 3 (no-op), 4 (shared signal), 6 (leak/screenshot).

No gaps found.

**Placeholder scan:** the only conditional step is Task 8 Step 5 (diagram update *if a phase-level diagram exists*) and Task 11's diagram note — both are genuine conditionals with a defined no-op outcome, not deferred work. Task 2 Step 3's parenthetical ("verify the actual step count before inserting") is an anchoring instruction, not a placeholder. No `TBD`/`TODO`/"handle edge cases".

**Type consistency:** `counterpart_references[]` and its field names (`source_kind`, `path`, `pr_ref`, `space`, `salient_summary`, `section_outline`, `is_shared_into_target`, `screenshots_seen[].{path, comprehension_only}`, `match_confidence`, `match_reason`) are defined in Task 1 and used verbatim in Tasks 3, 4, 5, 6. `counterpart_ref` (singular, the input flag value) is distinct from `counterpart_references` (the output array) and used consistently. Agent name `counterpart-finder` and dispatch id `dev-workflows:counterpart-finder` are consistent across Tasks 1, 3, 7, 10, 11.

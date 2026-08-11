# Vault prior-art discovery — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `/idea` and `/create-vi` a deliberate prior-art step — supplied (a Jira key the user hands over) and discovered (a vault search) — feeding one digest, one status ladder, one `## Prior art` section, and a Phase 4 write path that knows where an idea belongs.

**Architecture:** A new read-only agent (`vault-prior-art-finder`) dispatched at Phase 2.5 in parallel with `docs-grounder`, governed by a new shared reference (`vault-prior-art.md`) that owns scope, exclusions, status resolution, container derivation, and bounding. `/idea` gains source typing from Jira `issue_type`, a depth-aware write path with one assembled gate, and a disposition-aware handoff. `idea-reader` gains per-ref summaries.

**Tech Stack:** Prompt markdown only. No build, no runtime, no test framework — verification is `grep`, `awk`, `diff`, and reading.

**Spec:** `docs/superpowers/specs/2026-08-11-vault-prior-art-discovery-design.md`. Section references below (`§3.5`, `§5.2`, …) point into it.

## Global Constraints

Every task's requirements implicitly include this section.

- **Three repos.** Canonical `/workspace/ihudak-claude-plugins/plugins/dev-workflows/`. `mgd-claude-plugins` is **content-verbatim** except its identity files — port by **copying** canonical's changed files, never by retyping. `ihudak-copilot-plugins` is an adapted dialect on its own version track.
- **Copilot dialect:** commands live at `dev-workflows/skills/<name>/SKILL.md`; references at `dev-workflows/skills/_shared/<name>.md`; agents at `dev-workflows/agents/<name>.md`. Agent dispatch is `→ task(agent_type: "dev-workflows:X", model: …)`, **not** `→ Agent (subagent_type: …)`. There is **no `${CLAUDE_PLUGIN_ROOT}`** — paths are written literally as `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<file>.md`. The model chain reads `§2.1 detection chain: claude-sonnet-4.6, fallback claude-sonnet-4.5/gpt-5.4`.
- **Versions:** `2.48.0` canonical, `2.48.0` mgd, `2.18.0` copilot. Sibling plugins in each marketplace stay untouched.
- **No test framework.** Never claim a test run. Verification is grep/diff/reading, and every count is whitespace-normalized.
- **`choices:` arrays are presented verbatim** — order, wording, and the `(Recommended)` marker are not the orchestrator's to change.
- **Advisory only.** Prior-art grounding is never a gate, never a reviewer BLOCKER, never fatal. Source typing and key resolution are *not* advisory — a `NOT_FOUND` key stays a user halt.
- **Read-only.** The finder never writes. No agent builds or refreshes any index — there is no index here at all.
- **Match the surrounding file's line-wrapping style.** Some plugin files hard-wrap near 100 chars, others write one long line per paragraph; follow whatever the file you are editing already does.
- **Never hardcode `~/.claude/plugins/data/...`.** Canonical agents and references cite `${CLAUDE_PLUGIN_ROOT}/...`; command bodies cite the same textual path (it does not shell-expand there, and that is fine — match existing usage).

## File Structure

| Path (canonical) | Responsibility |
|---|---|
| `references/vault-prior-art.md` | **New.** Single source of truth: resolution, dispatch, scope, exclusions, status ladder, short-code map, container derivation, consumption, bounding, invariants. |
| `agents/vault-prior-art-finder.md` | **New.** The read-only search + classification agent. Cites the reference rather than restating it. |
| `references/jira-input-resolution.md` | **New entry point** `resolve-export-for-key`. Purely additive. |
| `agents/idea-reader.md` | `vi` provenance; `salient_summary` per followed ref; key resolution via the new entry point. |
| `commands/idea.md` | Phase 1 typing + grounding line; Phase 2.5 dispatch; Phase 3 grill-rank; Phase 4 container default + gate; Phase 5 handoff. |
| `commands/create-vi.md` | Phase 1 grounding line; Phase 2.5 dispatch; Phase 3 grill-rank. |
| `references/idea-format.md` | `## Prior art` section; `vi` in the `provenance` enum. |
| `references/workflow-states.md` | Status-spelling fix. |

---

### Task 1: `resolve-export-for-key`

**Files:**
- Modify: `plugins/dev-workflows/references/jira-input-resolution.md`

**Interfaces:**
- Produces: a named entry point `resolve-export-for-key <KEY>` returning `{ path, issue_type, status, summary, export_date }` or `NOT_FOUND`. Tasks 3, 4, and 5 consume it.

**Why this is separate from what the file already does:** the existing VI-selector rule resolves a nested Epic **up to its parent VI** — that is VI selection. `/idea` and the finder need the opposite: the export for *that exact key*, wherever it sits. Do not modify the existing rule.

- [ ] **Step 1: Append the new section**

Insert a new `##` section immediately **after** the `## Output contract` section and **before** `## Progress-aware Epic picker (opt-in per command)`:

````markdown
## Entry point — `resolve-export-for-key <KEY>`

Locates the export for **one exact key**, at any depth. Distinct from the VI-selector rule above, which deliberately resolves a nested Epic *up to its parent VI*; this one never walks upward. Consumed by `/idea` (source typing) and `vault-prior-art-finder` (status resolution) — neither wants a parent.

1. `candidates` = every `$VAULT_PATH/jira-products/**/<KEY>/<KEY>.md` (**any depth** — the export tree nests by hierarchy, so a key recurs under several roots).
2. **none** → `NOT_FOUND`.
3. **exactly one** → that file.
4. **several** → the **most recently modified**. Copies genuinely disagree: one `PRODUCT-14902` export reads `Post GA` and another `Release Preparation`, and `PRODUCT-14589` has three copies of which two still carry its pre-rewrite summary. Picking arbitrarily reports a stale identity.

Returns `{ path, issue_type, status, summary, export_date }`, read from the file's frontmatter; `export_date` is the file's modification date.

**Additive.** No existing caller's behavior changes: the resolution steps, the VI-selector rule, the fallback prompts, and the output contract above are untouched.
````

- [ ] **Step 2: Verify the existing sections are byte-unchanged**

```bash
cd /workspace/ihudak-claude-plugins
git diff -U0 -- plugins/dev-workflows/references/jira-input-resolution.md | grep '^-' | grep -v '^---'
```
Expected: **no output**. Any removed line means an existing section was touched — revert it.

- [ ] **Step 3: Verify the anchor placement**

```bash
grep -n '^## ' plugins/dev-workflows/references/jira-input-resolution.md
```
Expected: `## Entry point — resolve-export-for-key <KEY>` appears between `## Output contract` and `## Progress-aware Epic picker (opt-in per command)`.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/references/jira-input-resolution.md
git commit -m "feat(dev-workflows): add resolve-export-for-key to jira-input-resolution"
```

---

### Task 2: The `vault-prior-art.md` reference

**Files:**
- Create: `plugins/dev-workflows/references/vault-prior-art.md`

**Interfaces:**
- Consumes: `resolve-export-for-key` (Task 1).
- Produces: `resolve-prior-art <command-name>` and `dispatch-prior-art-finder`, the container derivation, the digest contract, and the bounding caps. Tasks 3, 5, 6, and 7 all cite this file instead of restating its rules.

- [ ] **Step 1: Write the file**

Write exactly this content:

````markdown
# Vault prior-art discovery (shared reference)

An idea rarely starts on empty ground. The vault already tracks initiatives that cover the same capability, precede it, parallel it in the other product, or *are* it under a different description. Reaching that prior art **before** authoring changes what gets authored; reaching it afterwards changes only how much gets rewritten.

Prior art arrives two ways and this file governs both. **Supplied** — the user hands `/idea` a Value Increment key. **Discovered** — `vault-prior-art-finder` searches the vault. Both produce the same digest, resolve status the same way, and land in the same `## Prior art` section.

Consumers: `/idea` (grill-rank, write path, `## Prior art`, handoff) and `/create-vi` (grill-rank). **Read-only** — neither ever writes into a matched item. **Advisory only** — never a gate, never a reviewer BLOCKER. Every miss is a silent, non-blocking skip.

## Procedure — `resolve-prior-art <command-name>`

1. **Flags first.** `--no-prior-art` → return `prior_art: OFF`, `reason: "disabled with --no-prior-art"`.
2. **Resolve the root.** `vault_root = $VAULT_PATH`. Unlike `$DOCS_PATH` this has **no default** — `$VAULT_PATH` is a write root, and write roots deliberately do not default.
3. **Validity gate — ON only when all hold** (else `OFF` with a one-line reason):
   - `$VAULT_PATH` is non-empty and is an existing, readable directory;
   - the run writes into that vault — when the command fell back to a user-supplied write root, return `OFF`, `reason: "write root is not the vault"`;
   - at least one of `Projects/Products/` and `Projects/ideas/` exists under it.
4. **Return** `{ prior_art, vault_root, reason }`.

There is deliberately **no index, no cache, and no consent prompt**. The corpus is a few hundred markdown files and retrieval is `Glob` + `Grep`, so this file has no analogue of `docs-grounding.md` step 3.5 — and none should be added.

## Plan-approval line

One line, surfaced in the command's plan/approval step. This reference owns the format; consumer commands quote it. It reports **resolution only** — the match count is not known until after dispatch, so no form promises one.

```
prior art: ON <vault-root>
prior art: OFF (<reason>)
```

The off switch (`--no-prior-art`) is stated by the consumer command beside the line, not inline.

## Dispatch — `dispatch-prior-art-finder`

Run only when `prior_art: ON`. Dispatch in the **same response** as `dispatch-docs-grounder` so the two grounding reads run in parallel.

```
→ Agent (subagent_type: "dev-workflows:vault-prior-art-finder", model: <detection_model>):
  > "Find tracked prior art for this idea and return the digest:
  >
  > vault_path:      <vault_root>
  > feature_summary: <2–4 sentences: the problem + desired outcome>
  > themes:          [capability themes, or []]
  > known_refs:      [{path: <abs path> | jira_key: <KEY>, has_summary: true|false}, …]"
```

A `known_refs` entry carries **either** a `path` **or** a `jira_key`. A supplied `vi` source has only a key — the caller does not know which vault directory holds it, and resolving that is the finder's job. A followed wikilink has only a path.

Wait for the digest. On `status: ERROR` or any dispatch failure, treat as `prior_art: OFF` and proceed (record one line in the final report). On `status: EMPTY`, proceed; the digest simply adds nothing.

## Search scope and exclusions

Roots: `<vault_root>/Projects/Products/**` and `<vault_root>/Projects/ideas/**`.

A path is **excluded** when it:

- contains a `Jira - <KEY>/` directory segment — those are immutable snapshots from an older decentralized import, superseded by `jira-products/`;
- belongs to an item whose work document carries `type: valuepack`, or whose Jira `issue_type` is `Value Pack` — the Value Pack layer is abandoned, and this plugin operates at Value Increment level and below;
- lies under any `_archive/` segment.

## Status resolution

An item's Jira key comes from its work document's `jira.id`, else from the item directory name via `^([A-Z][A-Z0-9_]*-\d+)`.

1. **Work-doc frontmatter** `jira.status` → map through the short-code table below → `status_source: vault-frontmatter`.
2. **The export** → `resolve-export-for-key <KEY>` (`${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`) → its `status` → `status_source: jira-products`.
3. Neither → `tracked_status: unknown`, `status_source: none`.

**Frontmatter first, and that ordering is measured rather than assumed.** Across every work document carrying `jira.status` that also has an export, the two disagreed 8 times and the frontmatter was ahead in all 8 — zero the other way. The frontmatter is synced to keep dashboards current; exports are run occasionally.

When steps 1 and 2 both resolve and **disagree**, `tracked_status` takes step 1's value and the match carries `status_conflict` naming both values and the export's date. A disagreement is **reported, never escalated** — it is the signal that catches a broken sync.

A `Jira - <KEY>/` snapshot is never a status source, at any step.

### Short-code map

| Short code | Ladder status |
|---|---|
| `OPEN` | Open |
| `PSTM` | Problem stated |
| `UCDF` | Usecases defined |
| `REDY` | Ready for Implementation |
| `IMPL` | Implementation |
| `RPRE` | Release Preparation |
| `POGA` | Post GA |
| `DONE` | Closed |
| `Cancelled` | Cancelled |

An unrecognised code is **passed through verbatim** and recorded in `notes` — never guessed at, never dropped.

## Container derivation

One derivation, two callers: `/idea`'s provenance default (from the **source** path) and `area_proposal.path` (from the **match** path). Defining it once is what keeps them from drifting.

Given an absolute path `P` inside the write root, its **container** is:

1. the **depth-1 directory under `Projects/Products/`** on `P`'s path — the grouper when `P` sits at depth 2 or deeper (`Projects/Products/<grouper>/<item>/…`), and `P`'s own directory when it sits at depth 1 (`Projects/Products/<item>/…`);
2. `Projects/Products/` itself, when `P` is a bare `.md` directly under `Projects/Products/`;
3. `Projects/ideas/` otherwise — including when `P` lies under `Projects/ideas/` (an idea sibling is not an area), when `P` lies elsewhere in the vault or outside it, and when `P` is absent.

An idea is written at `<container>/<candidate_slug>/idea.md`. Cases 2 and 3 are the **flat containers** — they name a root, not a specific area.

**Choosing `P` for a Jira-key source.** A key has no vault path of its own; its export lives under `jira-products/`, outside `Projects/`, and would always fall to case 3. Instead `P` = the **vault item directory** whose work document carries `jira.id: <KEY>`, when one exists; absent otherwise. So a VI key yields its grouper — a *new sibling* beside the VI, which is right for extending or paralleling it and wrong for rewriting it in place. The write-path gate decides that; this derivation stays a pure path→path function and never guesses intent.

**`area_proposal`.** `path` = the container of the highest-confidence match, except that a **flat container yields `null`** — a root is not an area to propose — and `null` likewise when no match reached `high` confidence. `confidence` = that match's `match_confidence`, downgraded one step when the top two matches resolve to different containers.

## Consumption

**`grill-rank`** (`/idea`, `/create-vi`) — feed `prior_art` to the grill as positive grounding. **Rank** each `prior_art_challenges` entry into the command's existing Impact × Uncertainty gap list together with `docs_challenges`; do **not** append. A challenge competes for a question slot and never adds one — this preserves `/idea`'s ≤5-question bound.

**`## Prior art`** (`/idea`) — the durable carrier, written per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`. Fed from both directions: discovered matches and a supplied `vi` source alike.

**Write path** (`/idea` Phase 4) — the container derivation supplies the provenance default; `area_proposal` and a supplied `vi` source supply the gate's rows.

**Handoff** (`/idea` Phase 5) — matched keys with statuses, plus `vi_disposition`.

## Bounding

| Bound | Value |
|---|---|
| Directory enumeration | ≤ 500 |
| Keywords | 3–8 |
| Keyword drop threshold | > 60 files |
| Shortlist | ≤ 40 files |
| Work documents read | ≤ 8 |
| `prior_art[]` | ≤ 5 |
| `prior_art_challenges[]` | ≤ 4 |
| `salient_summary` | ≤ 150 words |

## Invariants

- Read-only; never writes into a matched item, and never anywhere outside the run's resolved write root.
- Never blocks; every failure is a silent, non-blocking skip. Advisory only — never a gate, never a reviewer BLOCKER.
- `$VAULT_PATH` has **no default** — it is a write root.
- No retrieval index, no cache, no model download, and therefore no consent gate. Do not add one.
- Value Packs are never read, reported, or acted on; a VP-named directory is a grouper and nothing more.
- A `known_ref` whose path no longer resolves is **dropped with a `notes` line** — never an error, never fabricated. Vault items get renamed, so this is ordinary input. When the dropped entry carried a Jira key, re-resolve it by key.
- `supersedes_self` is reachable only for `discovered_by: source` — a search hit is by definition a different item.
- `resolve-prior-art` runs **exactly once per run**, at the earliest phase that shows the `prior art:` line; any later invocation in that run consumes the cached result.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -c '^## ' plugins/dev-workflows/references/vault-prior-art.md   # expect 9
grep -n 'resolve-prior-art\|dispatch-prior-art-finder\|resolve-export-for-key' plugins/dev-workflows/references/vault-prior-art.md
```
Expect the three entry-point names present, and no `qmd`, no `--build`, no consent prompt anywhere in the file.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/vault-prior-art.md
git commit -m "feat(dev-workflows): add vault-prior-art reference"
```

---

### Task 3: The `vault-prior-art-finder` agent

**Files:**
- Create: `plugins/dev-workflows/agents/vault-prior-art-finder.md`

**Interfaces:**
- Consumes: `vault-prior-art.md` (Task 2) for scope, exclusions, status ladder, container derivation, bounding; `resolve-export-for-key` (Task 1) for step 2 of the status ladder.
- Produces: the digest shape consumed by Tasks 5, 6, and 7.

**Critical:** the agent **cites** the reference for the rules it shares; it does **not** restate the short-code table, the exclusion set's rationale, or the bounding caps. Duplicating them is how the two drift apart. What lives here is the retrieval procedure and the classification vocabulary.

- [ ] **Step 1: Write the file**

Write exactly this content:

````markdown
---
name: vault-prior-art-finder
description: Read-only prior-art discovery for the idea-authoring commands. Given the user's vault root, a feature summary, and optional themes, searches Projects/Products/** and Projects/ideas/** for tracked initiatives that cover, precede, parallel, or are superseded by the new work, and returns a bounded digest — each match classified by relation, resolved to a Jira status, and summarised — plus reconciliation challenges and a write-path area proposal. Never writes; advisory only. Model tier assigned by the caller per the model-routing policy (no fixed pin).
tools: ["Read", "Glob", "Grep"]
---

Find the tracked initiatives in the user's vault that this idea must be reconciled against, and return them **summarised**, so the caller never has to read them itself. A bare path shifts the reading cost into the orchestrator's context, which is the most expensive place to put it. **Read-only discovery — never a writer, never a gate.**

`${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` owns the search scope, the exclusion set, the status-resolution ladder and its short-code table, the container derivation, and the bounding caps. **Read it and follow it** — this file does not restate those rules.

## Inputs

```yaml
vault_path:      <absolute $VAULT_PATH>
feature_summary: <2–4 sentences: the problem + desired outcome>
themes:          <optional capability themes from the caller, or []>
known_refs:      <optional [{path | jira_key, has_summary}] the caller already holds, or []>
```

Each `known_refs` entry carries **either** a `path` or a `jira_key`, never both required. A supplied Value Increment arrives as a key — resolving it to a vault item directory is this agent's job, not the caller's.

Refuse to run without `vault_path` and a non-empty `feature_summary`. If `vault_path` is not an existing readable directory, return `status: ERROR` with a one-line `notes` (the caller treats this as OFF and proceeds).

## Process

### 1. Two-pass retrieval

**Pass 1 — directory names.** Enumerate depth-1 and depth-2 directories under both roots and score their names against the keyword set. This is the strongest signal in this vault: directory names carry both the capability name and a Jira key, so `VP-15448 xEnv xProd MCP observability` matches "MCP" on the name alone.

**Pass 2 — content grep.** Derive salient keywords from `feature_summary` + `themes`, minus stopwords. One `Grep` files-with-matches pass per keyword; drop any keyword exceeding the reference's threshold — it is too generic to discriminate. Union the survivors ordered by keyword-hit count.

Cross-product work needs no special handling: keyword overlap on the capability ("Azure function deployment") finds a SaaS initiative whether or not the idea says "Managed". What that case needs is the *vocabulary* to express it (below), not different retrieval.

### 2. Resolve each shortlisted path to its item

An **item** is normally a directory; its **work document** is the `.md` directly inside it carrying `jira:` frontmatter. When none carries it, score every `.md` directly inside and let the highest-scoring one represent the item. A bare `.md` sitting directly under a root is its own item, with `item_dir: null`.

Score each candidate's frontmatter plus its first ~60 body lines against `feature_summary` + `themes`; keep matches above threshold, respecting every Bounding cap.

### 3. Handle `known_refs`

These are references the caller already holds. Resolve each to an item first:

- **`jira_key`** — find the item whose work document carries `jira.id: <KEY>`. Nothing found is not an error: return the entry with `item_dir: null` and whatever `resolve-export-for-key` yields for status, so a supplied VI with no vault note is still reported.
- **`path`** — use it directly.

Then classify and status-resolve them exactly like any other match, returning them with `discovered_by: source`. When `has_summary: true`, **omit** `salient_summary` — the caller already has one and a second costs its context twice.

A `known_ref` whose `path` no longer resolves is **dropped with a `notes` line** — never an error. Vault items get renamed and moved, so a dangling ref is ordinary input rather than an exceptional case. When the dropped entry also carried a Jira key, re-resolve by key instead of discarding it.

### 4. Classify the relation

- `same_capability` — the item covers this very capability.
- `predecessor_phase` — this idea is the next phase of that item.
- `analogous_precedent` — a **parallel** initiative to model this one on, typically the same capability in the other product (an existing SaaS Value Increment ↔ a new Managed one on the 2gen UI). It produces no contradiction by itself; the question is where alignment is required and where divergence is deliberate. Expect this often.
- `supersedes_self` — this idea **rewrites the very item it came from**, in place: same goal, different approach, same Jira key. Reachable **only** for a `known_refs` entry (`discovered_by: source`). A search hit is by definition a *different* item, so never assign this to one.
- `adjacent_initiative` — related but distinct work.

### 5. Resolve status

Follow the reference's ladder — work-doc frontmatter first, the export second, `unknown` third — and report a `status_conflict` when the two disagree rather than silently picking.

### 6. Raise challenges

- `already_tracked` — an initiative already covers this at status X; how is this different?
- `phase_continuation` — this looks like the next phase of `<KEY>`; author it as such?
- `precedent_alignment` — the precedent does X (scope shape, altitude, permissions, naming, UX). Should this match it, and where must it diverge? Name the divergence deliberately.
- `rewrite_delta` — the item currently specifies X and this idea proposes Y. Is the **goal** unchanged, and which existing content is superseded rather than extended? Use this instead of `already_tracked` whenever the relation is `supersedes_self`, where "how is this different from that tracked work?" has the useless answer "it *is* that work".
- `superseded` — the match is `Closed` / `Cancelled` / `Post GA`; does that resolve the problem, or is this a revival?
- `adjacent_scope_boundary` — related work in flight; where is the boundary?

### 7. Propose an area

Derive `area_proposal` per the reference's container derivation.

## Output

```yaml
status: OK | EMPTY | ERROR
prior_art:
  - path:             <absolute path to the work document>
    item_dir:         <absolute path to the item directory, or null>
    area_dir:         <absolute path to the container under Projects/Products, or null>
    jira_key:         <KEY | null>
    tracked_status:   <ladder status | unknown>
    status_source:    vault-frontmatter | jira-products | none
    status_conflict:  { vault_frontmatter: <X>, jira_products: <Y>, export_date: <YYYY-MM-DD> }   # omit when they agree
    relation:         same_capability | predecessor_phase | analogous_precedent | supersedes_self | adjacent_initiative
    salient_summary:  <≤150 words — omitted when the caller declared has_summary: true>
    match_confidence: high | medium | low
    match_reason:     <why this item matched>
    discovered_by:    search | source
prior_art_challenges:
  - kind:      already_tracked | phase_continuation | precedent_alignment | rewrite_delta | superseded | adjacent_scope_boundary
    challenge: <the reconciliation question to put to the author>
    evidence:  { path: <file>, quoted_line: <verbatim line> }
    severity:  high | medium | low
area_proposal:
  path:       <absolute container directory | null>
  confidence: high | medium | low
  basis:      <which match(es) support it>
notes: <degradations, dropped known_refs, unrecognised status codes, why EMPTY>
```

`status: EMPTY` → both arrays empty, `area_proposal.path: null`, and `notes` explains; the caller proceeds as today.

## Hard rules

- NEVER write, create, move, or rename any file. This agent is read-only.
- NEVER read a `Jira - <KEY>/` path for status — those are immutable snapshots of an older import.
- NEVER read, report, or act on a **Value Pack**'s status. A VP-named directory is a grouper and nothing more.
- NEVER assign `supersedes_self` to a `discovered_by: search` match.
- NEVER fabricate a Jira key, a status, or a match — an unresolved status is `unknown`.
- NEVER make HTTPS/REST calls; NEVER shell out. Vault reads only, via `Read`/`Glob`/`Grep`.
- Respect every Bounding cap in the reference; a large vault must not flood the caller's context.
- Advisory only — challenges are reconciliation prompts, not auto-applied edits, and nothing here is a gate.
````

- [ ] **Step 2: Verify frontmatter and non-duplication**

```bash
cd /workspace/ihudak-claude-plugins
head -5 plugins/dev-workflows/agents/vault-prior-art-finder.md
# the short-code table must NOT be restated in the agent:
grep -c 'UCDF' plugins/dev-workflows/agents/vault-prior-art-finder.md   # expect 0
grep -c 'vault-prior-art.md' plugins/dev-workflows/agents/vault-prior-art-finder.md   # expect >= 1
```

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/agents/vault-prior-art-finder.md
git commit -m "feat(dev-workflows): add vault-prior-art-finder agent"
```

---

### Task 4: `idea-reader` — `vi` provenance and per-ref summaries

**Files:**
- Modify: `plugins/dev-workflows/agents/idea-reader.md`

**Interfaces:**
- Consumes: `resolve-export-for-key` (Task 1).
- Produces: `provenance: vi`, and `salient_summary` on `source_refs` / `wikilinks_followed` entries — consumed by Task 5.

- [ ] **Step 1: Widen the input enum**

Replace this line in `## Inputs`:

```
provenance_hint: prompt | markdown | community-post | rfe   # from the caller's Phase 1 classification
```

with:

```
provenance_hint: prompt | markdown | community-post | rfe | vi   # from the caller's Phase 1 classification
```

- [ ] **Step 2: Replace the `rfe` process paragraph**

Replace the whole paragraph beginning `**rfe** (`provenance_hint: rfe`)` with:

````markdown
**rfe / vi** (`provenance_hint: rfe | vi`) — validate `argument` against `^[A-Z][A-Z0-9_]*-\d+$`; on mismatch return `status: NOT_FOUND` naming the invalid key. Locate the export with `resolve-export-for-key <KEY>` (`${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`) — **never** by assuming a top-level `jira-products/<KEY>/` directory, because the export tree nests by hierarchy and hundreds of keys exist only as children. `NOT_FOUND` from that entry point is `status: NOT_FOUND` here. Enumerate `attachments/`/`Attachments/` image filenames (paths only) and read any wikilinked context.

Then split by provenance:

- **`rfe`** — product feedback (a `Product Need`). Distill the ticket summary/description into `raw_context`; put requester / customer-demand info into `signals`, as today.
- **`vi`** — an existing Value Increment. This is **prior art the user supplied**, not demand evidence. Distill its problem / goal / scope / current approach into `raw_context`, and record its `issue_type`, `status`, and `summary` in `tracked`. Do **not** mine it for requesters or upvotes — a VI has none, and inventing them is fabrication. `signals` stays empty unless the ticket genuinely carries demand evidence of its own.
````

- [ ] **Step 3: Add `salient_summary` to the output block**

Replace these three fragments of the `## Output` YAML:

```
source_refs:
  - <path | JIRA-KEY | url>
```
with:
```
source_refs:
  - ref:             <path | JIRA-KEY | url>
    salient_summary: <≤150 words: what this source says that matters to the idea — omit for an inline prompt>
```

and:
```
wikilinks_followed:
  - <path of a followed .md>
```
with:
```
wikilinks_followed:
  - path:            <path of a followed .md>
    salient_summary: <≤150 words: the facts that mattered — status, named customers, what shipped, what closed>
    tracked_status:  <the item's status when its frontmatter carries one, else omit>
```

and add, immediately after the `provenance:` line:
```
tracked:                 # present only for provenance: vi
  jira_key:   <KEY>
  issue_type: <from the export frontmatter>
  status:     <from the export frontmatter>
  summary:    <from the export frontmatter>
```

- [ ] **Step 4: Add hard rules**

Append to `## Hard rules`:

```markdown
- NEVER mine a `vi` source for requesters, upvotes, or demand signals — a Value Increment is prior art, not a demand ticket. Fabricating them is a correctness failure, not a stylistic one.
- NEVER assume `jira-products/<KEY>/` is a top-level directory; always resolve through `resolve-export-for-key`.
- A `salient_summary` summarises **only** what was actually read; never infer content for a broken wikilink.
```

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -c 'salient_summary' plugins/dev-workflows/agents/idea-reader.md      # expect 3
grep -n 'resolve-export-for-key' plugins/dev-workflows/agents/idea-reader.md
grep -n 'jira-products/<KEY>/`' plugins/dev-workflows/agents/idea-reader.md  # the old flat assumption must be gone
```

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/agents/idea-reader.md
git commit -m "feat(dev-workflows): idea-reader gains vi provenance and per-ref summaries"
```

---

### Task 5: `/idea` Phases 0–2.5 — typing, grounding line, dispatch

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: the resolved `prior_art` digest and `provenance`, both consumed by Task 6.

- [ ] **Step 1: Replace Phase 1's classification list**

Replace numbered items 1–3 under `## Phase 1 — Classify the source` with:

````markdown
1. Matches the Jira-key regex `^[A-Z][A-Z0-9_]*-\d+$` → resolve it with `resolve-export-for-key <KEY>`
   (`${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`), then type it from the export's
   **`issue_type` frontmatter** — never from the project prefix, which is a coincidence of Jira
   configuration:
   - `ValueIncrement` → **vi** — an existing VI. Prior art the user supplied.
   - `Product Need` → **rfe** — product feedback, handled as demand evidence exactly as today.
   - anything else → name the actual `issue_type` in the confirmation below and let the user choose;
     **default vi**, since a tracked delivery item is closer to prior art than to demand evidence.

   `NOT_FOUND` from the entry point is handled as today (an environment/user halt, never `emit-block`).
2. An existing `.md` path or an `@wikilink` → **markdown** (a community post is just a markdown file,
   typically under `Projects/Products/…` — the reader tags it `community-post`; an existing `idea.md`
   passed back for re-refinement is detected here too).
3. Otherwise → **prompt** (the argument text is the raw idea).
````

- [ ] **Step 2: Add the prior-art line beside the docs-grounding line**

Immediately after the existing `Show the \`docs grounding:\` line …` paragraph, add:

````markdown
Show the `prior art:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` resolved — `ON <vault-root>` or `OFF (<reason>)` — verbatim (off switch: --no-prior-art). Run `resolve-prior-art idea` per that reference to obtain it; it runs exactly once per run.
````

- [ ] **Step 3: Pass the typed provenance to `idea-reader`**

In Phase 2's dispatch block, replace:
```
  > provenance_hint: [prompt | markdown | community-post | rfe from Phase 1]
```
with:
```
  > provenance_hint: [prompt | markdown | community-post | rfe | vi from Phase 1]
```

And in the paragraph beginning `Wait for the digest.`, replace `carry forward \`raw_context\`, \`signals\`, …` so the carried list also includes `tracked` — the sentence becomes:

````markdown
Wait for the digest. If `status: NOT_FOUND` (invalid key / missing file), surface:
```
choices: ["Re-enter the source", "Cancel", "Other… (describe)"]
```
This is an environment/user halt — do NOT `emit-block`. On `OK`, carry forward `raw_context`,
`signals`, `images`, `candidate_title`, `candidate_slug`, `source_refs`, `provenance`, `tracked` (a
`vi` source only), and the followed/broken wikilinks — `source_refs`/`provenance` feed the `sources:`
frontmatter entry in Phase 4, and `tracked` seeds `## Prior art`.
````

- [ ] **Step 4: Rewrite Phase 2.5 as a parallel two-agent dispatch**

Replace the whole `## Phase 2.5 — Documentation grounding (optional)` section (heading included) with:

````markdown
## Phase 2.5 — Grounding: documentation + vault prior art (optional)

Dispatch both grounding agents **in a single response** so they run in parallel. Each is independent; either being OFF never suppresses the other.

**Docs.** Run `resolve-docs-grounding idea` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the `idea-reader` digest's problem/outcome, `themes` = its signals; **omit `jira_key`** (idea is keyless, so the git-grep backstop is skipped). When OFF, skip silently.

**Prior art.** Using the `resolve-prior-art idea` result already obtained in Phase 1: when `prior_art: ON`, `dispatch-prior-art-finder` per `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` with `feature_summary` = the same problem/outcome, `themes` = the digest's signals, and `known_refs` built from the reader's digest: every `wikilinks_followed` path and every filesystem-path `source_refs` ref as `{path, has_summary: true}` (Task 4's reader already summarised them), plus — for a `vi` source — `{jira_key: <KEY>, has_summary: true}`. Passing the key rather than a path is deliberate: the orchestrator does not know which vault directory holds that VI, and resolving it is the finder's job. The supplied VI is then classified and status-resolved by the same code path as a discovered one. When OFF, skip silently.

Carry both digests into Phase 3 with **grill-rank** consumption — challenges from the two compete together for the ≤5 question slots, they do not add slots. Carry `area_proposal` and the `vi` source's match into Phase 4.
````

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n 'resolve-prior-art\|dispatch-prior-art-finder\|prior art:' plugins/dev-workflows/commands/idea.md
grep -n 'issue_type' plugins/dev-workflows/commands/idea.md
# no prefix-based typing may ship:
grep -n 'PRODFB\|PRODUCT-' plugins/dev-workflows/commands/idea.md   # expect no line that *decides* provenance
```

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/commands/idea.md
git commit -m "feat(dev-workflows): /idea types Jira sources and grounds on vault prior art"
```

---

### Task 6: `/idea` Phases 3–5 — grill-rank, write path, handoff

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md`

**Interfaces:**
- Consumes: Task 5's digests, `area_proposal`, and `provenance`.
- Produces: `vi_disposition`, consumed by the Phase 5 handoff.

- [ ] **Step 1: Fold prior-art challenges into the ranked gap list**

In `## Phase 3 — Refine via grill`, replace the sentence `Rank gaps by **Impact × Uncertainty**.` with:

````markdown
Rank gaps by **Impact × Uncertainty**, ranking every `docs_challenges` and `prior_art_challenges` entry from Phase 2.5 into that same list. Challenges **compete** for the slots below; they never add slots.
````

- [ ] **Step 2: Replace the Phase 4 path bullet with the container default plus the gate**

Replace the `- **Path:**` bullet under `## Phase 4 — Write idea.md` with:

````markdown
- **Path (container default):** `<container(source path)>/<candidate_slug>/idea.md`, where the container
  is derived per `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md`. A source already sitting under a
  `Projects/Products/` grouper lands beside its neighbours in that grouper; an inline prompt, a Jira key
  with no vault item, and any source outside `Projects/Products/` all resolve to `Projects/ideas/`
  exactly as before.
- **Write-path gate.** Assemble **one** `choices:` array, in this row order, and present it verbatim:

  | Row | Included when | Text |
  |---|---|---|
  | 1 | `provenance: vi` **and** the finder resolved a vault item directory for that key | `Rewrite <KEY> — write into <item-dir>/` |
  | 2 | `area_proposal.path` non-null, `confidence: high`, **and** it differs from the container default | `New idea under <area_proposal.path>/<candidate_slug>/` |
  | 3 | always | `Write to <container default>/<candidate_slug>/ as detected` |
  | 4 | always | `Enter a different path` |
  | 5 | always | `Cancel` |
  | 6 | always | `Other… (describe)` |

  The gate **fires only when at least one of rows 1–2 is present**; otherwise the container default
  applies silently. Append `(Recommended)` to **exactly one** row, chosen by the top match's `relation`:
  `supersedes_self` → row 1; `predecessor_phase` or `analogous_precedent` → row 2 when present, else
  row 3; anything else → row 2 when present, else row 3. Never recommend row 1 without
  `supersedes_self` — extending and paralleling a VI are as common as rewriting one, and a wrong
  default here silently mints or fails to mint a Jira key. Validate every chosen path sits inside the
  resolved write root and is writable.

  Record the choice as **`vi_disposition`** — `rewrite` for row 1, `new` for every other row — and carry
  it into Phase 5. This is the only point in the flow where the three shapes of a supplied VI (extend,
  parallel, rewrite-in-place) can be told apart.
- **`## Prior art`:** when Phase 2.5 returned any `prior_art` entry, write the section per
  `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`; omit it entirely otherwise. A `vi` source appears
  there **and** in `sources:`.
````

- [ ] **Step 3: Make the Phase 5 offer disposition-aware**

Replace the two bullets under `## Phase 5 — Handoff: adaptive next-phase offer` with:

````markdown
- **`refined`, `vi_disposition: new`** (and every run with no `vi` source): *"Idea refined. Next: create
  the VI — first create an empty Jira workitem, then run `/dev-workflows:create-vi <JIRA-KEY> @<idea.md
  path>`."*
- **`refined`, `vi_disposition: rewrite`:** *"Idea refined. Next: `/dev-workflows:create-vi <KEY>
  @<idea.md path>` — this rewrites the existing VI, so no new Jira workitem is needed. If an authored VI
  already exists for `<KEY>`, `/create-vi` will redirect you to `/dev-workflows:update-vi <KEY>`."*
- **`draft`** (N open clarifications): *"This idea has N open clarification(s). You can (a) run
  `/dev-workflows:idea @<idea.md path> --deep` to resolve them, or (b) proceed to
  `/dev-workflows:create-vi <KEY-or-JIRA-KEY> @<idea.md path>`, which will grill you on the rest."* Use
  the same `vi_disposition` clause as above when a `vi` source was given.

Also report any prior art found — matched keys with their statuses, and the alternative container path
when one exists — **whether or not the gate fired**, so the user can relocate before `/create-vi` makes
the path sticky.
````

- [ ] **Step 4: Extend the Final report line**

In `## Final report`, add to the reported list: `any prior art found (keys + statuses) and the resolved \`vi_disposition\`;`.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n 'vi_disposition' plugins/dev-workflows/commands/idea.md      # expect >= 4
grep -n 'empty Jira workitem' plugins/dev-workflows/commands/idea.md # must NOT appear on a rewrite path
grep -n 'Recommended' plugins/dev-workflows/commands/idea.md
```

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/commands/idea.md
git commit -m "feat(dev-workflows): /idea write path, gate, and disposition-aware handoff"
```

---

### Task 7: `/create-vi` — grounding line, dispatch, grill-rank

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md`

**Note:** `/create-vi` gets **no write-path gate** — its path is keyed under `$SPECS_PATH/specifications/<KEY>-<slug>/`, so there is no area to resolve.

- [ ] **Step 1: Add the prior-art line**

In `## Phase 1 — Configure` step 1, immediately after the `docs grounding:` sub-bullet, add:

````markdown
   - Show the `prior art:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` resolved — `ON <vault-root>` or `OFF (<reason>)` — verbatim (off switch: --no-prior-art). Run `resolve-prior-art create-vi` per that reference to obtain it; it runs exactly once per run.
````

- [ ] **Step 2: Rewrite Phase 2.5**

Replace the whole `## Phase 2.5 — Documentation grounding (optional)` section (heading included) with:

````markdown
## Phase 2.5 — Grounding: documentation + vault prior art (optional)

Dispatch both grounding agents **in a single response** so they run in parallel. Each is independent; either being OFF never suppresses the other.

**Docs.** Run `resolve-docs-grounding create-vi` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the idea's problem/goal + VI themes, `jira_key` = `<KEY>`, and `themes` from the idea. When OFF, skip silently.

**Prior art.** Using the `resolve-prior-art create-vi` result from Phase 1: when `prior_art: ON`, `dispatch-prior-art-finder` per `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` with `feature_summary` = the idea's problem/goal, `themes` from the idea, and `known_refs` = every filesystem path in the idea's `sources[]` as `{path, …}`, every Jira key in `sources[]` as `{jira_key, …}`, and the Jira key of each `## Prior art` bullet as `{jira_key, …}` — all with `has_summary: false`, since this command reads `idea.md` directly and holds no summaries of its own. Take the **key**, not the wikilink, from a `## Prior art` bullet: a wikilink resolves by file name and dangles the moment a vault item is renamed, which is exactly why the bullet carries both. Recorded `sources[]` paths may dangle for the same reason; the finder drops what it cannot resolve. When OFF, skip silently.

Carry both digests into Phase 3 with **grill-rank** consumption. When both are OFF the VI is authored exactly as today.
````

- [ ] **Step 3: Fold challenges into the grill**

In `## Phase 3 — Author via grill`, append to the first paragraph (the one beginning `**Interview technique**`):

````markdown
Rank every `docs_challenges` and `prior_art_challenges` entry from Phase 2.5 into the grill's question order; a challenge competes for attention, it never suspends the spine below.
````

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n 'prior art:\|resolve-prior-art\|dispatch-prior-art-finder\|prior_art_challenges' plugins/dev-workflows/commands/create-vi.md
grep -n 'write-path gate' plugins/dev-workflows/commands/create-vi.md   # expect 0 — create-vi has none
```

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/create-vi.md
git commit -m "feat(dev-workflows): /create-vi grounds on vault prior art"
```

---

### Task 8: `idea-format.md` and `workflow-states.md`

**Files:**
- Modify: `plugins/dev-workflows/references/idea-format.md`
- Modify: `plugins/dev-workflows/references/workflow-states.md`

- [ ] **Step 1: Widen the `provenance` enum**

In `idea-format.md`'s frontmatter block, replace:
```
  - provenance: rfe | markdown | community-post | prompt
```
with:
```
  - provenance: rfe | vi | markdown | community-post | prompt
```

- [ ] **Step 2: Add the `## Prior art` section**

Insert a new section between `## Section 5 — Signals & evidence` and `## Section 6 — Open questions & assumptions`, and renumber the sections that follow (old 6 → 7, old 7 → 8):

````markdown
## Section 6 — Prior art (optional)

`## Prior art` — tracked initiatives in the vault that this idea covers, continues, parallels, or
rewrites. **Omit the whole section when none was found.** One bullet per entry:

```
- [[<work doc>]] (<JIRA-KEY>, <status>) — <relation>: <one line>
```

The **Jira key is the durable identifier**; the wikilink is a convenience that dangles once a vault item
is renamed, so both are carried and a later reader re-resolves by key. An entry with no Jira key carries
only the wikilink, and that is accepted. Never fabricate a key or a status — an unresolved status is
written as `status unknown`. A `vi` source appears here **and** in `sources:`: `sources` answers how the
idea arrived, `## Prior art` answers what it must stay consistent with.
````

- [ ] **Step 3: Fix the status spelling**

In `workflow-states.md`, replace **every** occurrence of `Use cases defined` with `Usecases defined` — that is the string Jira and every export actually emit, and `readiness-reviewer` string-matches against this table. Expect 2 occurrences (the ladder line and the table row); verify the real count rather than assuming.

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '^## Section ' plugins/dev-workflows/references/idea-format.md   # expect 1..8, no gaps or repeats
grep -rn 'Use cases defined' plugins/dev-workflows/                       # expect 0
grep -c 'Usecases defined' plugins/dev-workflows/references/workflow-states.md
```

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/idea-format.md plugins/dev-workflows/references/workflow-states.md
git commit -m "feat(dev-workflows): idea-format gains Prior art; fix Usecases defined spelling"
```

---

### Task 9: Repo documentation

**Files:**
- Modify: `CLAUDE.md`
- Modify: `plugins/dev-workflows/README.md`

- [ ] **Step 1: Update the workflow map in `CLAUDE.md`**

In the `## \`dev-workflows\` workflow relationships` block:
- `/idea` line → insert `[vault-prior-art-finder]` alongside `[docs-grounder]`, both at Phase 2.5.
- `/create-vi` line → same insertion.
- Add to the agent list: `└── vault-prior-art-finder (used by /idea, /create-vi)`.

- [ ] **Step 2: Add the reference to the source-truth list**

Add a paragraph in `CLAUDE.md` alongside the other `references/*.md` single-source-of-truth entries:

````markdown
`plugins/dev-workflows/references/vault-prior-art.md` is the **single source of truth** for vault prior-art discovery — the `resolve-prior-art` / `dispatch-prior-art-finder` entry points, the search scope (`Projects/Products/**`, `Projects/ideas/**`) and its exclusions (`Jira - <KEY>/` snapshots, Value Packs, `_archive/`), the status-resolution ladder (work-doc frontmatter before the export, disagreements reported not resolved) with its short-code map, the container derivation shared by `/idea`'s write-path default and `area_proposal`, and the bounding caps. Consumed by `/idea` and `/create-vi`. Read-only and advisory — never a gate; there is no retrieval index and therefore no consent gate.
````

- [ ] **Step 3: Update the invariants**

Add to the VI-creation-flow invariants list in `CLAUDE.md`:

````markdown
- `/idea` types a Jira source from the export's `issue_type` (`ValueIncrement` → `vi`, `Product Need` → `rfe`), never from the project prefix, and resolves it with `resolve-export-for-key` at any depth; a `vi` source is prior art recorded in **both** `sources:` and `## Prior art`
- `/idea` Phase 4 derives its write path from the container rule and gates only when a rewrite target or a high-confidence area proposal exists; the resulting `vi_disposition` decides whether Phase 5 tells the user to create a Jira workitem
````

- [ ] **Step 4: Update `plugins/dev-workflows/README.md`**

Add `vault-prior-art-finder` to the agent inventory and bump the agent count wherever one is stated. **Enumerate the agents and count them** rather than incrementing a number you did not verify.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
ls -1 plugins/dev-workflows/agents/ | wc -l
grep -rn 'thirty-two reusable subagents\|thirty-three reusable subagents' CLAUDE.md plugins/dev-workflows/README.md
grep -c 'vault-prior-art-finder' CLAUDE.md plugins/dev-workflows/README.md
```
The stated agent count must equal the directory count.

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md plugins/dev-workflows/README.md
git commit -m "docs(dev-workflows): document vault prior-art discovery"
```

---

### Task 10: Canonical version bump

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

- [ ] **Step 1: Bump both manifests to `2.48.0`**

Only the `dev-workflows` entry in `marketplace.json`. Sibling plugins are untouched.

- [ ] **Step 2: Add the changelog entry**

The file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Match it exactly: a `## [2.48.0] — 2026-08-11` heading, then `### Added` / `### Changed` / `### Fixed` subsections — **only those that apply**, in that order — each holding bullets that lead with a bold claim and then explain the *why*, in the register the 2.47.0 and 2.47.1 entries use. Read those two entries before writing. A bare list of file names is not this file's style.

Suggested distribution — verify each is true of what actually shipped before writing it:

- **Added** — `vault-prior-art-finder` and `references/vault-prior-art.md`; the `resolve-export-for-key` entry point; `## Prior art` in `idea-format.md`; the `--no-prior-art` off switch.
- **Changed** — `/idea` and `/create-vi` ground on vault prior art at Phase 2.5, in parallel with `docs-grounder`; `idea-reader` returns a `salient_summary` per followed ref; `/idea`'s write path derives a container rather than flattening to depth 1.
- **Fixed** — `/idea` classified every Jira key as `rfe`, reading a Value Increment as a demand ticket; key lookup assumed a top-level `jira-products/<KEY>/` while 431 keys exist only nested, so `/idea PRODUCT-14796` returned `NOT_FOUND`; the next-phase offer told a rewrite run to create a Jira workitem it must not create; `workflow-states.md` spelled a status `Use cases defined` where Jira emits `Usecases defined`, which `readiness-reviewer` string-matches against.

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '"version"' plugins/dev-workflows/.claude-plugin/plugin.json
grep -n -A2 '"name": "dev-workflows"' .claude-plugin/marketplace.json
head -20 plugins/dev-workflows/CHANGELOG.md
python3 -c "import json;json.load(open('.claude-plugin/marketplace.json'));json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));print('JSON OK')"
```

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(dev-workflows): 2.48.0"
```

---

### Task 11: Port to `mgd-claude-plugins`

**Files:**
- Repo: `/workspace/mgd-claude-plugins`

**Method:** **copy** canonical's changed files; never retype them. The two repos are content-verbatim apart from a small set of identity files.

- [ ] **Step 1: Create the branch**

```bash
cd /workspace/mgd-claude-plugins
git switch -c iv-gu/vault-prior-art
```

- [ ] **Step 2: Copy every changed plugin file**

```bash
C=/workspace/ihudak-claude-plugins/plugins/dev-workflows
M=/workspace/mgd-claude-plugins/plugins/dev-workflows
for f in references/vault-prior-art.md references/jira-input-resolution.md \
         references/idea-format.md references/workflow-states.md \
         agents/vault-prior-art-finder.md agents/idea-reader.md \
         commands/idea.md commands/create-vi.md \
         README.md CHANGELOG.md .claude-plugin/plugin.json; do
  cp "$C/$f" "$M/$f"
done
```

- [ ] **Step 3: Apply `CLAUDE.md` and `marketplace.json` by hand**

These are identity-bearing. Port the *content* of Task 9's `CLAUDE.md` edits and Task 10's version bump, keeping mgd's own marketplace name, plugin source paths, and any repo-specific wording.

- [ ] **Step 4: Enumerate the divergence and judge it**

```bash
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows \
         /workspace/mgd-claude-plugins/plugins/dev-workflows
```
Every differing path must be a known identity file. **Enumerate and judge each one — do not assume a count.** A content file appearing here is a port error.

- [ ] **Step 5: Commit**

```bash
cd /workspace/mgd-claude-plugins
git add -A
git commit -m "feat(dev-workflows): 2.48.0 — vault prior-art discovery"
```

---

### Task 12: Port to `ihudak-copilot-plugins`

**Files:**
- Repo: `/workspace/ihudak-copilot-plugins`

**Path mapping:** `references/X.md` → `dev-workflows/skills/_shared/X.md`; `agents/X.md` → `dev-workflows/agents/X.md`; `commands/X.md` → `dev-workflows/skills/X/SKILL.md`.

**Dialect conversions — apply to every ported file:**
1. `→ Agent (subagent_type: "dev-workflows:X"` → `→ task(agent_type: "dev-workflows:X"`
2. `${CLAUDE_PLUGIN_ROOT}/references/X.md` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/X.md`
3. `§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5` → `§2.1 detection chain: claude-sonnet-4.6, fallback claude-sonnet-4.5/gpt-5.4`

Read a neighbouring already-ported file (e.g. `skills/_shared/docs-grounding.md`) and match whatever it does — it is the ground truth for this dialect, ahead of this list.

- [ ] **Step 1: Create the branch**

```bash
cd /workspace/ihudak-copilot-plugins
git switch -c iv-gu/vault-prior-art
```

- [ ] **Step 2: Port each file with its conversions**

Copy then convert, file by file. Version files: `dev-workflows/.plugin/plugin.json` and `.github/plugin/marketplace.json` → `2.18.0`; `dev-workflows/CHANGELOG.md` gains the matching entry in that file's own format.

- [ ] **Step 3: Verify zero dialect leaks**

```bash
cd /workspace/ihudak-copilot-plugins
grep -rn 'CLAUDE_PLUGIN_ROOT' dev-workflows/ | grep -v '^Binary'   # expect 0
grep -rn 'subagent_type' dev-workflows/                            # expect 0
grep -rn 'claude-sonnet-5' dev-workflows/                          # expect 0
grep -rn '2\.17\.1' dev-workflows/ .github/                        # expect 0 outside CHANGELOG history
python3 -c "import json;json.load(open('.github/plugin/marketplace.json'));json.load(open('dev-workflows/.plugin/plugin.json'));print('JSON OK')"
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(dev-workflows): 2.18.0 — vault prior-art discovery"
```

---

### Task 13: Verification sweep

**Files:**
- Create: `docs/superpowers/plans/2026-08-11-vault-prior-art-discovery-verification.md`

Run **every** check V1–V27 from the spec's §10 across all three repos and record the result of each with the command or the reading that produced it.

**Method — enumerate and judge, never count.** A check that passes by confirming its own premise has verified nothing. For V13 in particular, list each of the five §5 consumers and quote the shipped line that implements it; a count of five proves nothing about which five.

- [ ] **Step 1: Run V1–V27 and write the table**

One row per check: `#`, `Result` (PASS / FAIL), and the evidence — the command run and its salient output, or the file and line read.

- [ ] **Step 2: Re-verify the traps this plan is most likely to fall into**

- Does any conditional between Phase 2.5's dispatch and its first consumer skip the dispatch, in **either** command? (V9 — this is F's `/epics` bug.)
- Is `supersedes_self` reachable from a `discovered_by: search` path anywhere? (V24)
- Does any path still tell a rewrite run to create an empty Jira workitem? (V26)
- Does the short-code table appear more than once across the three repos' canonical-equivalent files? (V5)
- Does the `known_refs` contract read the same in all three places it appears — the reference's dispatch block, the agent's inputs, and both commands' Phase 2.5? It spans three tasks, which is exactly where an interface drifts.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add docs/superpowers/plans/2026-08-11-vault-prior-art-discovery-verification.md
git commit -m "docs(superpowers): G verification sweep"
```

---

## Model selection

| Tasks | Tier | Why |
|---|---|---|
| 1, 8, 9, 10 | cheapest | Mechanical edits; the plan carries the exact text. |
| 2, 3 | mid | Long verbatim files where a dropped rule is invisible until much later. |
| 4, 5, 6, 7 | mid | Multi-anchor edits inside existing files, with cross-file interfaces. |
| 11, 12 | mid | 11 is copy + enumerate; 12 needs dialect judgment. |
| 13 | mid | Reading and judging across three repos. |

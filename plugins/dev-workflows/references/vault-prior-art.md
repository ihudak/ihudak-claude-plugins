# Vault prior-art discovery (shared reference)

An idea rarely starts on empty ground. The vault already tracks initiatives that cover the same capability, precede it, parallel it in the other product, or *are* it under a different description. Reaching that prior art **before** authoring changes what gets authored; reaching it afterwards changes only how much gets rewritten.

Prior art arrives two ways and this file governs both. **Supplied** — the user hands `/idea` a Value Increment key. **Discovered** — `vault-prior-art-finder` searches the vault. Both produce the same digest, resolve status the same way, and land in the same `## Prior art` section.

Consumers: `/idea` (grill-rank, write path, `## Prior art`, handoff) and `/create-vi` (grill-rank). **Read-only** — neither ever writes into a matched item. **Advisory only** — never a gate, never a reviewer BLOCKER. Every miss is a silent, non-blocking skip.

## Procedure — `resolve-prior-art <command-name>`

1. **Flags first.** `--no-prior-art` → return `prior_art: OFF`, `reason: "disabled with --no-prior-art"`.
2. **Resolve the root.** `vault_root = $VAULT_PATH`. Unlike `$DOCS_PATH` this has **no default** — `$VAULT_PATH` is a write root, and write roots deliberately do not default.
3. **Validity gate — ON only when all hold** (else `OFF` with a one-line reason):
   - `$VAULT_PATH` is non-empty and is an existing, readable directory;
   - **`/idea` only** — the run writes into that vault: when `/idea` fell back to a user-supplied write root, return `OFF`, `reason: "write root is not the vault"`. This check does not apply to `/create-vi`, which writes to `$SPECS_PATH` by design and never into the vault; applying it there would resolve `OFF` on every run.
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

**The top match** — used by `area_proposal` below and by `/idea`'s write-path gate — is the `prior_art` entry with the highest `match_confidence`, ties broken by array order. `prior_art` is returned ranked, so the top match is its first entry among those tied at the highest confidence. Defining this once matters: two consumers pick a row and a path from it, and "highest-confidence" is ambiguous the moment two entries tie.

**`area_proposal`.** `path` = the container of the top match, except that a **flat container yields `null`** — a root is not an area to propose — and `null` likewise when no match reached `high` confidence. `confidence` = that match's `match_confidence`, downgraded one step when the top two matches resolve to different containers.

## Vocabulary

The closed term sets. `idea-format.md` and `vault-prior-art-finder` both cite this section; it is defined here once so the two cannot drift.

**`relation`** — how a match stands to the new work.

| Term | Meaning |
|---|---|
| `same_capability` | The item covers this very capability. |
| `predecessor_phase` | This idea is the next phase of that item. |
| `analogous_precedent` | A **parallel** initiative to model this one on — typically the same capability in the other product (an existing SaaS Value Increment ↔ a new Managed one on the 2gen UI). It produces no contradiction by itself; the question is where alignment is required and where divergence is deliberate. |
| `supersedes_self` | This idea **rewrites the very item it came from**, in place: same goal, different approach, same Jira key. |
| `adjacent_initiative` | Related but distinct work. |

**`kind`** — the reconciliation question a challenge puts to the author.

| Term | Meaning |
|---|---|
| `already_tracked` | An initiative already covers this at status X; how is this different? |
| `phase_continuation` | This looks like the next phase of `<KEY>`; author it as such? |
| `precedent_alignment` | The precedent does X (scope shape, altitude, permissions, naming, UX). Should this match it, and where must it diverge? Name the divergence deliberately. |
| `rewrite_delta` | The item currently specifies X and this idea proposes Y. Is the **goal** unchanged, and which existing content is superseded rather than extended? |
| `superseded` | The match is `Closed` / `Cancelled` / `Post GA`; does that resolve the problem, or is this a revival? |
| `adjacent_scope_boundary` | Related work in flight; where is the boundary? |

## Consumption

**`grill-rank`** (`/idea`, `/create-vi`) — feed `prior_art` to the grill as positive grounding. **Rank** each `prior_art_challenges` entry into the command's existing Impact × Uncertainty gap list together with `docs_challenges`; do **not** append. A challenge competes for a question slot and never adds one — this preserves `/idea`'s ≤10-question bound.

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

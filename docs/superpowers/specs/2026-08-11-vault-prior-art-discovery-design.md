# Vault prior-art discovery — design

**Sub-project G** of the 2026-08-06 `/idea` feedback round. Closes three of the seven open entries. Ships as `dev-workflows` 2.48.0 (canonical + mgd) / 2.18.0 (copilot).

## 1. Framing — one gap, three symptoms

Three feedback entries look like three features. They are one gap with three downstream consequences, which is why they ship together:

| Entry | Symptom |
|---|---|
| `idea-vault-prior-art-discovery` | `/idea` discovers tracked prior art only by accident — through whatever the source happens to wikilink. An inline prompt wikilinks nothing, so an active initiative covering the same capability went unseen until the orchestrator grepped the vault on a hunch. |
| `idea-area-rule-ignores-prior-art` | Phase 4's `<area>` rule keys on **source provenance**, a proxy for the wrong thing. The idea landed in `Projects/ideas/` while an active area for exactly that capability existed. |
| `idea-reader-digest-lacks-prior-art-content` | `idea-reader` returns prior-art **paths**, not content. The orchestrator then reads four vault files itself — the most expensive place to put a read. |

The root gap is that **nothing in `/idea` looks for prior art on purpose**. Fix only the finder and the write path stays provenance-derived; fix only the `<area>` rule and it has no match to act on; fix only the digest and it still summarises whatever the source happened to link. Splitting them manufactures the dead-gate defect deliberately: a producer with no consumer, or a consumer with no producer.

## 2. Premise corrections

Five premises were corrected during design. Each changed the shape of the work.

**2.1 — Value Packs are out of scope entirely.** The motivating entry reports "the natural Jira parent, PRODUCT-15448, is **Cancelled**". PRODUCT-15448 is a **Value Pack**, not a Value Increment. The VP layer (VP → VI → Epic → Story → Task) was judged overkill for the department and every VP was closed while its VIs were kept as orphans. The pipeline commands were never meant to operate on Value Packs. A VP-named directory is a **grouper — a directory, nothing more**; its Jira status is irrelevant and must never be read, reported, or acted on.

**2.2 — `Jira - <KEY>/` directories under `Projects/` are immutable snapshots.** They come from an older decentralized import. Re-importing produces a *new* snapshot rather than updating the old one. They are excluded from the search entirely: never matched, never read, never a status source.

**2.3 — `$VAULT_PATH/jira-products/` is the centralized import**, the same tree `jira-reader` reads. Its layout is nested by hierarchy — `jira-products/<ROOT-KEY>/<KEY>/<KEY>.md` — so a key recurs under several export roots. `PRODUCT-14640` exists both as its own root and as a child of `PRODUCT-15448`. Copies can disagree: `PRODUCT-14902` is `Post GA` in one and `Release Preparation` in another.

**2.4 — The export is staler than the vault frontmatter.** Measured across all 38 work documents carrying `jira.status` that also have an export: **8 real disagreements, all 8 with the vault frontmatter ahead. Zero in the other direction.** Root export dates spread from 2026-07-20 to 2026-08-10; the frontmatter is synced regularly to keep dashboards current. So the status ladder reads the frontmatter first — the reverse of the initial assumption.

**2.5 — The vault's real path convention is one level deeper than the rule produces.** The current rule yields `Projects/<Products|ideas>/<slug>/idea.md`, flat. The convention in practice is `Projects/Products/<grouper-dir>/<item-dir>/idea.md`. So the write-path fix is not swapping an `<area>` token but **resolving a container directory** — and that applies to *both* halves of Phase 4: the provenance default becomes depth-aware on its own (a source already sitting under a grouper belongs in that grouper, prior art or not), and a high-confidence match can propose a different container. One derivation serves both (§3.6).

## 3. Components

| File | Change |
|---|---|
| `references/vault-prior-art.md` | **New.** Single source of truth. |
| `agents/vault-prior-art-finder.md` | **New.** Read/Glob/Grep, `detection_model`. |
| `agents/idea-reader.md` | `salient_summary` per followed wikilink / source ref. |
| `commands/idea.md` | Phase 1 grounding line; Phase 2.5 parallel dispatch; Phase 3 merged grill-rank; Phase 4 depth-aware provenance default **and** write-path gate; Phase 5 handoff. |
| `commands/create-vi.md` | Phase 1 grounding line; Phase 2.5 parallel dispatch; Phase 3 merged grill-rank. |
| `references/idea-format.md` | New optional `## Prior art` section. |
| `references/workflow-states.md` | Status-spelling fix (§3.8). |
| `CLAUDE.md`, `README.md` | Workflow map, agent list, reference list. |
| `plugin.json`, `marketplace.json`, `CHANGELOG.md` | 2.48.0 / 2.18.0, three repos. |

### 3.1 Search scope and exclusions

Roots: `$VAULT_PATH/Projects/Products/**` and `$VAULT_PATH/Projects/ideas/**`.

Hard exclusions — a path is skipped when it:

- contains a `Jira - <KEY>/` directory segment (§2.2);
- resolves to an item whose work document carries `type: valuepack`, or whose Jira `issue_type` is `Value Pack` (§2.1);
- lies under any `_archive/` segment.

Corpus after exclusions: ~220 markdown files across ~50 directories. Two orders of magnitude smaller than `$DOCS_PATH`, which is why this needs no retrieval index and no `qmd` (§8).

### 3.2 Two-pass retrieval

**Pass 1 — directory names.** Enumerate depth-1 and depth-2 directories under both roots and score their names against the keyword set. This is the strongest signal in this vault: directory names carry both the capability name and a Jira key, so `VP-15448 xEnv xProd MCP observability` matches "MCP" on the name alone. Cap enumeration at 500 directories.

**Pass 2 — content grep.** Derive **3–8** salient keywords from `feature_summary` + `themes`, minus stopwords. One `Grep` files-with-matches pass per keyword. **Drop any keyword matching more than 60 files** — the threshold is calibrated to this ~220-file corpus, not to `docs-grounder`'s 200. Union the survivors ordered by keyword-hit count; cap the shortlist at **40** files.

**Resolve each shortlisted path to its item.** An *item* is normally a directory; its **work document** is the `.md` directly inside it carrying `jira:` frontmatter. When none carries it, every `.md` directly inside is scored and the highest-scoring one represents the item. A bare `.md` sitting **directly** under a root — `Projects/Products/Azure Monitor additional metrics.md` and its kind — is its own item with `item_dir: null`.

**Score and select.** Read each candidate's frontmatter plus the first ~60 body lines; score overlap against `feature_summary` + `themes`; keep above threshold; read at most **8** work documents; return at most **5** matches.

### 3.3 Status resolution

For a candidate item, the Jira key comes from its work document's `jira.id`, else from the directory name via `^([A-Z][A-Z0-9_]*-\d+)`.

1. **Work-doc frontmatter** `jira.status` → map the short code through §3.4 → `status_source: vault-frontmatter`.
2. **`jira-products`** → locate `$VAULT_PATH/jira-products/**/<KEY>/<KEY>.md` **at any depth** (§2.3). When several copies exist, take the **most recently modified**. Read its frontmatter `status:` → `status_source: jira-products`.
3. Neither resolves → `tracked_status: unknown`, `status_source: none`.

When steps 1 and 2 both resolve and **disagree**, `tracked_status` takes step 1's value and the match additionally carries `status_conflict` with both values and the export's date. A disagreement is reported, never escalated and never a gate.

`Jira - <KEY>/` snapshots are never consulted for status, at any step.

### 3.4 Short-code map

Derived empirically from the 30 agreeing work-doc/export pairs; every code resolved to exactly one full name.

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

An unrecognised code is **passed through verbatim** and recorded in `notes`. Never guessed at, never dropped.

### 3.5 Digest shape

```yaml
status: OK | EMPTY | ERROR
prior_art:
  - path:             <absolute path to the work document>
    item_dir:         <absolute path to the item directory>
    area_dir:         <absolute path to the depth-1 grouper under Projects/Products, or null>
    jira_key:         <KEY | null>
    tracked_status:   <ladder status | unknown>
    status_source:    vault-frontmatter | jira-products | none
    status_conflict:  { vault_frontmatter: <X>, jira_products: <Y>, export_date: <YYYY-MM-DD> }   # omit when they agree
    relation:         same_capability | predecessor_phase | adjacent_initiative
    salient_summary:  <≤150 words — omitted when the caller declared has_summary: true>
    match_confidence: high | medium | low
    match_reason:     <why this item matched>
    discovered_by:    search | source
prior_art_challenges:
  - kind:      already_tracked | phase_continuation | superseded | adjacent_scope_boundary
    challenge: <the reconciliation question to put to the author>
    evidence:  { path: <file>, quoted_line: <verbatim line> }
    severity:  high | medium | low
area_proposal:
  path:       <absolute grouper directory | null>
  confidence: high | medium | low
  basis:      <which match(es) support it>
notes: <degradations, unrecognised status codes, why EMPTY>
```

`relation` semantics — `same_capability`: the item covers this very capability. `predecessor_phase`: this idea is the next phase of that item. `adjacent_initiative`: related but distinct work.

`kind` semantics — `already_tracked`: an initiative already covers this at status X; how is this different? `phase_continuation`: this looks like the next phase of `<KEY>`; author it as such? `superseded`: the match is Closed / Cancelled / Post GA; does that resolve the problem, or is this a revival? `adjacent_scope_boundary`: related work in flight; where is the boundary?

### 3.6 Container derivation (shared)

One derivation, two callers: it produces both `/idea`'s provenance default (from the **source** path) and `area_proposal.path` (from the **match** path). Defining it once is what keeps the two from drifting apart.

Given an absolute path `P` inside the write root, its **container** is:

1. the **depth-1 directory under `Projects/Products/`** on `P`'s path — the grouper when `P` sits at depth 2 or deeper (`Projects/Products/<grouper>/<item>/…`), and `P`'s own directory when it sits at depth 1 (`Projects/Products/<item>/…`);
2. `Projects/Products/` itself, when `P` is a bare `.md` directly under `Projects/Products/`;
3. `Projects/ideas/` otherwise — including when `P` lies under `Projects/ideas/` (an idea sibling is not an area), when `P` lies elsewhere in the vault or outside it, and when `P` is absent (an inline prompt, or an RFE under `jira-products/`).

An idea is always written at `<container>/<candidate_slug>/idea.md`. Cases 2 and 3 are the **flat containers** — they name a root, not a specific area.

### 3.7 `area_proposal` derivation

`path` = the container (§3.6) of the **highest-confidence match**, except that a **flat container yields `path: null`** — a root is not an area to propose. `path` is likewise `null` when no match reached `high` confidence. A `null` path means no gate.

`confidence` = the highest-confidence match's `match_confidence`, **downgraded one step** when the top two matches resolve to different containers.

### 3.8 Adjacent bug — status spelling

`references/workflow-states.md` writes the third VI rung as **"Use cases defined"**. Jira and every export emit **"Usecases defined"**. `readiness-reviewer` matches status strings against that table, so the mismatch is a live string-comparison bug in `/ready`. One-word fix, in scope because §3.4 makes this file's vocabulary load-bearing for a second command.

## 4. Inputs and the `known_refs` contract

```yaml
vault_path:      <absolute $VAULT_PATH>
feature_summary: <2–4 sentences: the problem + desired outcome>
themes:          <capability themes from the caller, or []>
known_refs:      <list of {path, has_summary} the caller already holds, or []>
```

Refuse to run without `vault_path` and a non-empty `feature_summary`.

`known_refs` prevents the finder and `idea-reader` from summarising the same file twice — the exact duplicated-read cost entry 3 objects to. Entries are classified and status-resolved like any other match and returned with `discovered_by: source`; when `has_summary: true` the finder **omits** `salient_summary`, and the caller merges by `path`.

- `/idea` passes `idea-reader`'s `source_refs` + `wikilinks_followed` with `has_summary: true`.
- `/create-vi` has no `idea-reader` — it reads the seed `idea.md` directly — so it passes the idea's `sources[]` paths and any `## Prior art` refs with `has_summary: false`.

## 5. Consumption

Four consumers. Every one is named here so none of this becomes a producer without a consumer.

**5.1 — Grill-rank (both commands).** `prior_art_challenges` merge with `docs_challenges` into **one** Impact × Uncertainty ranking and compete for the existing **≤5** question slots. They never add slots; `/idea`'s bound is untouched.

**5.2 — Write path (`/idea` Phase 4).** Two changes, and the second depends on the first.

*The provenance default becomes depth-aware.* Today it yields a flat `Projects/<Products|ideas>/<slug>/idea.md` regardless of how deep the source sits. It becomes `<container(source path)>/<candidate_slug>/idea.md` per §3.6. A source under `Projects/Products/<grouper>/<item>/` therefore lands beside its neighbours in `<grouper>/` instead of flat under `Products/` — matching the convention the vault already follows, with no prior-art match required. An inline prompt, an RFE, and any source outside `Projects/Products/` all resolve to `Projects/ideas/` exactly as today, so the common case is unchanged.

*The gate.* Fires **iff** all three hold: `area_proposal.path` is non-null, `area_proposal.confidence` is `high`, **and** `area_proposal.path` differs from the provenance default's container. The third test is load-bearing precisely because the default is now a container too — when the source already sits in the area the finder points at, the two agree and there is nothing to ask. Presented verbatim:

```
choices: ["Write under <area_proposal.path>/<candidate_slug>/ (Recommended)", "Write under <provenance default> as detected", "Enter a different path", "Cancel", "Other… (describe)"]
```

Every choice is validated to sit inside the resolved write root and be writable. When the gate does not fire, the provenance default applies silently. The gate **never** auto-relocates and consumes **zero** grill slots — it sits beside the existing-file gate, where the path is actually decided.

`/create-vi` gets no gate: its path is keyed under `$SPECS_PATH/specifications/<KEY>-<slug>/`, so there is no area to resolve.

**5.3 — `## Prior art` in `idea.md`.** The durable carrier. One bullet per match:

```
- [[<work doc>]] (<JIRA-KEY>, <status>) — <relation>: <one line>
```

The whole section is omitted when nothing was found. A key or status is never fabricated; an unresolved status is written as `status unknown`.

**5.4 — Phase 5 handoff.** Prior art is reported whether or not the gate fired — matched keys with statuses, and the alternative path when one exists. This is the feedback's stated minimum, and it is what lets the user relocate before `/create-vi` makes the path sticky.

## 6. Resolution, off switch, and printed surface

Prior-art grounding is **ON** when `$VAULT_PATH` is a readable directory and at least one of the two roots exists. It is **OFF** when `--no-prior-art` is passed, `$VAULT_PATH` is unset or invalid, the Phase 0 fallback write root was used (the user pointed at a non-vault directory), or neither root exists.

Phase 1 prints resolution only — the match count is not yet known, so the line never promises one:

```
prior art: ON <vault-root>
prior art: OFF (<reason>)
```

Match counts appear in the Phase 5 handoff and the Final report. Both new lines follow the printed-output rules already in force (`references/next-phase-offer.md` rule 6 command qualification).

## 7. Bounding, degradation, and cost

| Bound | Value |
|---|---|
| Directory enumeration | ≤ 500 |
| Keyword count | 3–8 |
| Keyword drop threshold | > 60 files |
| Shortlist | ≤ 40 files |
| Work documents read | ≤ 8 |
| `prior_art[]` | ≤ 5 |
| `prior_art_challenges[]` | ≤ 4 |
| `salient_summary` | ≤ 150 words |

`$VAULT_PATH` invalid ⇒ `status: ERROR`; the caller treats it as OFF and proceeds. No matches ⇒ `status: EMPTY`; the caller proceeds silently. **Advisory only — never a gate, never a reviewer BLOCKER, never fatal.**

**No consent gate.** This is local `Glob`/`Grep` over ~220 files: no model download, no index build, no network. F's stampede has no analogue here. Stated explicitly so a reviewer does not invent one — and equally, no expensive-work-without-consent risk to guard against.

## 8. Non-goals

Recorded with reasons, so a later reader does not read them as oversights.

- **No `/specify` wiring.** The feedback names it, but `jira-reader` already hands `/specify` the Jira hierarchy, so its marginal value is lowest and its wiring cost highest. Deferred as an explicit follow-up, not dropped.
- **No `qmd` or any retrieval index for the vault.** ~220 files after exclusions; grep is the right tool and adds no cache, no consent gate, and no staleness surface.
- **No Value Pack handling of any kind** (§2.1).
- **No change to `vi-format.md`.** `/create-vi` uses prior art in the grill and it lands in the VI's existing sections as prose. Deliberate: adding a VI section would need a `vi-reviewer` rule to be worth anything, and prior art is advisory.
- **No Jira or network calls.** Purely local vault reads, consistent with every agent in this plugin.
- **No auto-relocation** of an existing `idea.md`, and no writes into the vault beyond `idea.md` at its resolved path.
- **No feasibility/code grounding.** That is sub-project H.

## 9. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | A false-positive high-confidence match proposes someone else's area. | The gate always asks; it never auto-writes. The provenance default is always an offered option. |
| R2 | A new Jira status appears and the §3.4 map goes stale. | Unrecognised codes pass through verbatim and are recorded in `notes` — never guessed, never dropped. |
| R3 | `status_conflict` becomes noise when a sync lags. | Reported, never escalated, never a gate. It is the signal that catches a broken sync. |
| R4 | Duplicate export copies disagree (confirmed: `PRODUCT-14902`). | Most-recently-modified copy wins; the rule is documented in §3.3. |
| R5 | **Dead gate** — the finder produces output nothing consumes. | §5 names four consumers; V13 enumerates each and traces it to a shipped line. |
| R6 | The deeper write path breaks `/create-vi`'s idea discovery. | **Verified safe** — `find "$VAULT_PATH/Projects" -type f -name idea.md` is recursive, so a deeper path still matches. |
| R7 | Parity drift across the three repos. | V16–V17; canonical files are copied, never retyped, into mgd. |
| R8 | The Phase 2.5 dispatch sits behind a conditional that skips it — F's `/epics` bug. | V9 traces control flow from Phase 2.5 to the first consumer in both commands. |
| R9 | The two grounding dispatches are serialised instead of parallel. | V8 asserts a single-response dispatch, per the plugin-wide parallel-dispatch invariant. |
| R10 | The depth-aware default changes where ideas land even on runs that find no prior art. | Intended: it matches the convention the vault already follows. Bounded by §3.6 case 3 — every source not under `Projects/Products/` resolves to `Projects/ideas/` exactly as today, so inline prompts and RFEs are untouched. V11b enumerates the unchanged cases. |

## 10. Verification

No test framework — verification is grep, `awk`, `diff`, and reading. Every count is whitespace-normalized.

| # | Check |
|---|---|
| V1 | `references/vault-prior-art.md` exists and covers §3.1–§3.6, §4, §5, §7. |
| V2 | `agents/vault-prior-art-finder.md` has valid frontmatter with `name`, `description`, `tools: ["Read","Glob","Grep"]`. |
| V3 | The exclusion set (§3.1) appears as hard rules in the agent body: `Jira - `, Value Pack, `_archive/`. |
| V4 | The status ladder reads frontmatter **before** `jira-products` in both the reference and the agent. |
| V5 | The §3.4 table appears exactly once in the reference; the agent cites it rather than restating it. |
| V6 | No file instructs reading a `Jira - <KEY>/` path for status. |
| V7 | `idea-reader.md` output block carries `salient_summary` under both `source_refs` and `wikilinks_followed`. |
| V8 | Both commands dispatch `docs-grounder` and `vault-prior-art-finder` in a **single response**. |
| V9 | In both commands, no conditional between the Phase 2.5 dispatch and its first consumer can skip it. |
| V10 | `/idea` Phase 4 carries the write-path gate with the §5.2 `choices:` array verbatim, including `(Recommended)`. |
| V11 | The gate's firing condition names **all three** tests — `path` non-null, `confidence: high`, and differs-from-default. |
| V11a | The §3.6 container derivation appears **once**, in the reference; `/idea` Phase 4 and `area_proposal` both cite it rather than restating it. |
| V11b | Phase 4's provenance default is depth-aware, and the four unchanged cases still resolve to `Projects/ideas/`: inline prompt, RFE, a source under `Projects/ideas/`, a source elsewhere in the vault. |
| V12 | `idea-format.md` has `## Prior art`, marked optional, with the §5.3 bullet shape. |
| V13 | Each of the four §5 consumers traces to a shipped line — enumerate and judge, do not count. |
| V14 | `workflow-states.md` reads "Usecases defined"; no file still reads "Use cases defined". |
| V15 | `--no-prior-art` is documented in `/idea` and `/create-vi`; the Phase 1 line forms match §6 and promise no match count. |
| V16 | mgd differs from canonical in exactly the known identity files — enumerate the diff, do not assume the count. |
| V17 | copilot carries the same content in its own dialect with zero `dev-workflows:` leaks and its own version track. |
| V18 | All three catalogs, manifests, and changelogs read 2.48.0 / 2.48.0 / 2.18.0, with sibling plugins untouched. |

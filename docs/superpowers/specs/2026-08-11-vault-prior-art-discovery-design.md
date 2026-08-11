# Vault prior-art discovery — design

**Sub-project G** of the 2026-08-06 `/idea` feedback round. Closes three of the seven open entries plus two defects found during design. Ships as `dev-workflows` 2.48.0 (canonical + mgd) / 2.18.0 (copilot).

## 1. Framing — two directions, one mechanism

Prior art reaches an idea two ways, and today both are broken.

**Supplied** — the user hands `/idea` an existing VI. It is misread (every Jira key is classified `rfe` and mined for customer-demand signals a VI does not have) and frequently unresolvable (key lookup is flat; 431 keys in the export exist only nested).

**Discovered** — `/idea` finds prior art only incidentally, through whatever the source happens to wikilink. An inline prompt wikilinks nothing.

Both directions want the same three things: a resolved tracked status, a digest the orchestrator does not have to re-read, and a durable place in `idea.md`. Building them apart means building that machinery twice.

| # | Origin | Symptom |
|---|---|---|
| 1 | `idea-vault-prior-art-discovery` | Prior art is discovered only by accident. An active initiative covering the same capability went unseen until the orchestrator grepped the vault on a hunch. |
| 2 | `idea-area-rule-ignores-prior-art` | Phase 4's `<area>` rule keys on **source provenance**, a proxy for the wrong thing, and flattens every idea to depth 1. |
| 3 | `idea-reader-digest-lacks-prior-art-content` | `idea-reader` returns prior-art **paths**, not content. The orchestrator then reads the files itself — the most expensive place to put a read. |
| 4 | Found during design | `/idea` classifies **every** Jira key as `rfe`. A `PRODUCT-NNNN` Value Increment is read as a demand ticket. `PRODFB` appears nowhere in the plugin. |
| 5 | Found during design | `/idea` resolves keys as `jira-products/<KEY>/` flat. **431 keys exist only nested**, including the Value Increments `PRODUCT-14796` and `PRODUCT-14592`. `/idea PRODUCT-14796` returns `NOT_FOUND`. |
| 6 | Found during design | Phase 5's next-phase offer always says *"first create an empty Jira workitem"*. When the idea rewrites the VI it came from (§2.8), that instructs the user to mint a key they must not mint. |

Entries 1–3 ship together because splitting them manufactures the dead-gate defect: a producer with no consumer, or a consumer with no producer. Entries 4–5 join them because a supplied VI *is* prior art — same status ladder, same digest, same `## Prior art` section.

## 2. Premise corrections

Eight premises were corrected during design. Each changed the shape of the work.

**2.1 — Value Packs are out of scope entirely.** The motivating entry reports "the natural Jira parent, PRODUCT-15448, is **Cancelled**". PRODUCT-15448 is a **Value Pack**, not a Value Increment. The VP layer (VP → VI → Epic → Story → Task) was judged overkill for the department and every VP was closed while its VIs were kept as orphans. The pipeline commands were never meant to operate on Value Packs. A VP-named directory is a **grouper — a directory, nothing more**; its Jira status is irrelevant and must never be read, reported, or acted on. *The finder's evidence is therefore one case, not two: what survives from the entry is `PRODUCT-14640` in `Implementation` with the auth work already closed.*

**2.2 — `Jira - <KEY>/` directories under `Projects/` are immutable snapshots.** They come from an older decentralized import. Re-importing produces a *new* snapshot rather than updating the old one. They are excluded from the search entirely: never matched, never read, never a status source.

**2.3 — `$VAULT_PATH/jira-products/` is the centralized import**, the same tree `jira-reader` reads. Its layout is nested by hierarchy — `jira-products/<ROOT-KEY>/…/<KEY>/<KEY>.md` — so a key recurs under several export roots. `PRODUCT-14640` exists both as its own root and as a child of `PRODUCT-15448`. Copies can disagree: `PRODUCT-14902` is `Post GA` in one and `Release Preparation` in another.

**2.4 — The export is staler than the vault frontmatter.** Measured across all 38 work documents carrying `jira.status` that also have an export: **8 real disagreements, all 8 with the vault frontmatter ahead. Zero in the other direction.** Root export dates spread from 2026-07-20 to 2026-08-10; the frontmatter is synced regularly to keep dashboards current. So the status ladder reads the frontmatter first — the reverse of the initial assumption.

**2.5 — The vault's real path convention is one level deeper than the rule produces.** The current rule yields `Projects/<Products|ideas>/<slug>/idea.md`, flat. The convention in practice is `Projects/Products/<grouper-dir>/<item-dir>/idea.md`. So the write-path fix is not swapping an `<area>` token but **resolving a container directory** — and that applies to *both* halves of Phase 4: the provenance default becomes depth-aware on its own (a source already sitting under a grouper belongs in that grouper, prior art or not), and a high-confidence match can propose a different container. One derivation serves both (§3.8).

**2.6 — A supplied VI is both a source and prior art.** The recurring shape is cross-product: an existing **SaaS** VI — shipped or merely planned — and a new **Managed** VI doing the same thing on the 2gen UI. Azure Function deployment is the worked example. That VI is genuinely where the idea came from *and* genuinely an initiative to align against, so it is recorded in **both** `sources:` and `## Prior art`. The duplication is deliberate and load-bearing: `sources:` answers "how did this arrive", `## Prior art` answers "what must this stay consistent with".

**2.7 — That relation is `analogous_precedent`, and it is the common case here, not an edge case.** The SaaS VI is neither the same capability nor a predecessor phase. It is a parallel initiative in the other product, to be modelled on and to diverge from **deliberately** (2gen UI, different altitude, different permissions). For a Managed-facing department this is the most frequent relation, which is why it is first-class in §3.7 and carries its own challenge kind.

**2.8 — A supplied VI has three shapes, indistinguishable at invocation.** `/idea PRODUCT-NNNN` may mean *extend* it (a next phase — `PRODUCT-14640`), *parallel* it (the cross-product twin — §2.6), or **rewrite it in place**. The rewrite case is real and evidenced: `PRODUCT-14589` was "Export Smartscape topology", meaning a new API to export Monitored Entities and their relationships; the goal survived but the approach changed completely, to AI agents over the Managed MCP Server. The user ran `/idea PRODUCT-14589` and then `/create-vi PRODUCT-14589` — **the same key**.

The first two shapes mint a new Jira key; the third reuses one. Nothing in the source distinguishes them, so this is a decision only the user can make, and Phase 4 is where it must be made (§5.2). Three artifacts of that run in the vault corroborate the surrounding defects:

- the shipped `idea.md` records `provenance: rfe, ref: PRODUCT-14589` while the export says `issue_type: "ValueIncrement"` — §3.1's misclassification, in a kept artifact;
- the file landed in `…/PRODUCT-14589 - Detect architecture drift…/idea.md`, **inside the VI's own item directory** — the documented rule yields `Projects/Products/<slug>/`, so the run deviated to be correct, and it went one level deeper than a grouper (§3.8);
- the export tree holds **three copies** of `PRODUCT-14589`, one summarised "Architecture drift detection for Dynatrace Managed" and two still "Export Smartscape topology" — §3.2's most-recently-modified rule is what keeps the finder from reporting the pre-rewrite identity.

## 3. Components

| File | Change |
|---|---|
| `references/vault-prior-art.md` | **New.** Single source of truth for discovery, status, digest, consumption. |
| `agents/vault-prior-art-finder.md` | **New.** Read/Glob/Grep, `detection_model`. |
| `references/jira-input-resolution.md` | **New entry point** `resolve-export-for-key` (§3.2). Purely additive. |
| `commands/idea.md` | Phase 1 source typing + grounding line; Phase 2.5 parallel dispatch; Phase 3 merged grill-rank; Phase 4 depth-aware default **and** write-path gate; Phase 5 handoff. |
| `agents/idea-reader.md` | `vi` provenance handling; `salient_summary` per followed wikilink / source ref; key resolution via §3.2. |
| `commands/create-vi.md` | Phase 1 grounding line; Phase 2.5 parallel dispatch; Phase 3 merged grill-rank. |
| `references/idea-format.md` | New optional `## Prior art` section; `vi` added to the `provenance` enum. |
| `references/workflow-states.md` | Status-spelling fix (§3.10). |
| `CLAUDE.md`, `README.md` | Workflow map, agent list, reference list. |
| `plugin.json`, `marketplace.json`, `CHANGELOG.md` | 2.48.0 / 2.18.0, three repos. |

### 3.1 Source typing (`/idea` Phase 1)

Today: `^[A-Z][A-Z0-9_]*-\d+$` → `rfe`, unconditionally. That reads a Value Increment as a demand ticket.

New: a Jira-key-shaped argument is resolved via §3.2, then typed from the export's **`issue_type` frontmatter** — never from the project prefix, which is a coincidence of Jira configuration:

| `issue_type` | Provenance | Meaning |
|---|---|---|
| `ValueIncrement` | `vi` | An existing VI. Prior art the user supplied. |
| `Product Need` | `rfe` | Product feedback (PRODFB). Demand evidence, as today. |
| anything else | — | Surface the actual `issue_type` in the Phase 1 confirmation and let the user choose; **default `vi`**, since a tracked delivery item is closer to prior art than to demand evidence. |

`rfe` keeps its name — it is the established label in `idea-format.md`'s `provenance` enum and in `idea-reader`, and renaming it would ripple for nothing. `vi` is added alongside it.

A `vi` source is handled as prior art: `idea-reader` distills problem/goal/scope rather than mining for requesters and upvotes, and the orchestrator seeds `## Prior art` with it (§5.3) **in addition to** `sources:` (§2.6).

### 3.2 `resolve-export-for-key` (new entry point)

`references/jira-input-resolution.md` already solves *VI selection* — given a key, find the VI to drive a pipeline from, resolving a nested Epic **up to its parent**. `/idea` and the finder need the opposite: locate the export for **that exact key**, wherever it sits.

```
resolve-export-for-key <KEY>:
  1. candidates = $VAULT_PATH/jira-products/**/<KEY>/<KEY>.md   (any depth)
  2. none        -> NOT_FOUND
  3. one         -> that file
  4. several     -> the most recently modified (§2.3: copies exist and can disagree)
  returns: { path, issue_type, status, summary, export_date }
```

Additive: no existing caller's behavior changes. Consumers are `/idea` Phase 1 (§3.1), `idea-reader`'s `rfe`/`vi` path, and the finder's status step 2 (§3.5).

### 3.3 Search scope and exclusions

Roots: `$VAULT_PATH/Projects/Products/**` and `$VAULT_PATH/Projects/ideas/**`.

Hard exclusions — a path is skipped when it:

- contains a `Jira - <KEY>/` directory segment (§2.2);
- resolves to an item whose work document carries `type: valuepack`, or whose Jira `issue_type` is `Value Pack` (§2.1);
- lies under any `_archive/` segment.

Corpus after exclusions: ~220 markdown files across ~50 directories. Two orders of magnitude smaller than `$DOCS_PATH`, which is why this needs no retrieval index and no `qmd` (§8).

### 3.4 Two-pass retrieval

**Pass 1 — directory names.** Enumerate depth-1 and depth-2 directories under both roots and score their names against the keyword set. This is the strongest signal in this vault: directory names carry both the capability name and a Jira key, so `VP-15448 xEnv xProd MCP observability` matches "MCP" on the name alone. Cap enumeration at 500 directories.

**Pass 2 — content grep.** Derive **3–8** salient keywords from `feature_summary` + `themes`, minus stopwords. One `Grep` files-with-matches pass per keyword. **Drop any keyword matching more than 60 files** — the threshold is calibrated to this ~220-file corpus, not to `docs-grounder`'s 200. Union the survivors ordered by keyword-hit count; cap the shortlist at **40** files.

**Resolve each shortlisted path to its item.** An *item* is normally a directory; its **work document** is the `.md` directly inside it carrying `jira:` frontmatter. When none carries it, every `.md` directly inside is scored and the highest-scoring one represents the item. A bare `.md` sitting **directly** under a root — `Projects/Products/Azure Monitor additional metrics.md` and its kind — is its own item with `item_dir: null`.

**Score and select.** Read each candidate's frontmatter plus the first ~60 body lines; score overlap against `feature_summary` + `themes`; keep above threshold; read at most **8** work documents; return at most **5** matches.

Cross-product matches are not special-cased: keyword overlap on the capability ("Azure function deployment") finds the SaaS VI whether or not the idea says "Managed". What the cross-product case needs is the *vocabulary* to express it (§3.7), not different retrieval.

### 3.5 Status resolution

For a candidate item, the Jira key comes from its work document's `jira.id`, else from the directory name via `^([A-Z][A-Z0-9_]*-\d+)`.

1. **Work-doc frontmatter** `jira.status` → map the short code through §3.6 → `status_source: vault-frontmatter`.
2. **The export** → `resolve-export-for-key <KEY>` (§3.2) → its `status` → `status_source: jira-products`.
3. Neither resolves → `tracked_status: unknown`, `status_source: none`.

When steps 1 and 2 both resolve and **disagree**, `tracked_status` takes step 1's value and the match additionally carries `status_conflict` with both values and the export's date. A disagreement is reported, never escalated and never a gate.

`Jira - <KEY>/` snapshots are never consulted for status, at any step.

### 3.6 Short-code map

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

### 3.7 Digest shape

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
notes: <degradations, unrecognised status codes, why EMPTY>
```

**`relation` semantics**

- `same_capability` — the item covers this very capability.
- `predecessor_phase` — this idea is the next phase of that item.
- `analogous_precedent` — a *parallel* initiative to model this one on, typically the same capability in the other product (an existing SaaS VI ↔ a new Managed VI on 2gen UI). Produces no contradiction by itself; the question is where alignment is required and where divergence is deliberate. **The common relation for Managed-facing work** (§2.7).
- `supersedes_self` — this idea **rewrites the very item it came from**, in place. Only ever reachable for a supplied `vi` source (`discovered_by: source`), never for a discovered match — a search hit is by definition a *different* item. `PRODUCT-14589` is the worked example: same goal, wholly different approach, same Jira key (§2.8).
- `adjacent_initiative` — related but distinct work.

**`kind` semantics**

- `already_tracked` — an initiative already covers this at status X; how is this different?
- `phase_continuation` — this looks like the next phase of `<KEY>`; author it as such?
- `precedent_alignment` — the precedent does X (scope shape, altitude, permissions, naming, UX). Should this match it, and where must it diverge? Name the divergence deliberately.
- `superseded` — the match is `Closed` / `Cancelled` / `Post GA`; does that resolve the problem, or is this a revival?
- `rewrite_delta` — the item currently specifies X and this idea proposes Y. Is the **goal** unchanged, and which of the existing content is superseded rather than extended? Paired with `supersedes_self`; this is the question the `already_tracked` challenge gets wrong for a rewrite, where "how is this different from that tracked work?" has the useless answer "it *is* that work".
- `adjacent_scope_boundary` — related work in flight; where is the boundary?

### 3.8 Container derivation (shared)

One derivation, two callers: it produces both `/idea`'s provenance default (from the **source** path) and `area_proposal.path` (from the **match** path). Defining it once is what keeps the two from drifting apart.

Given an absolute path `P` inside the write root, its **container** is:

1. the **depth-1 directory under `Projects/Products/`** on `P`'s path — the grouper when `P` sits at depth 2 or deeper (`Projects/Products/<grouper>/<item>/…`), and `P`'s own directory when it sits at depth 1 (`Projects/Products/<item>/…`);
2. `Projects/Products/` itself, when `P` is a bare `.md` directly under `Projects/Products/`;
3. `Projects/ideas/` otherwise — including when `P` lies under `Projects/ideas/` (an idea sibling is not an area), when `P` lies elsewhere in the vault or outside it, and when `P` is absent.

An idea is always written at `<container>/<candidate_slug>/idea.md`. Cases 2 and 3 are the **flat containers** — they name a root, not a specific area.

**Choosing `P` for a Jira-key source.** A key has no vault path of its own — its export lives under `jira-products/`, which is outside `Projects/` and would always fall to case 3. Instead, `P` = the **vault item directory** the finder resolved for that key (the item whose work document carries `jira.id: <KEY>`), when one exists; absent otherwise. So `/idea PRODUCT-14589` gets container `VP-15448 …/` — a *new sibling* beside the VI, which is right for extending or paralleling it and wrong for rewriting it in place. §5.2 is where that gets decided; the container rule stays a pure path→path function and does not try to guess intent.

### 3.9 `area_proposal` derivation

`path` = the container (§3.8) of the **highest-confidence match**, except that a **flat container yields `path: null`** — a root is not an area to propose. `path` is likewise `null` when no match reached `high` confidence. A `null` path means no gate.

`confidence` = the highest-confidence match's `match_confidence`, **downgraded one step** when the top two matches resolve to different containers.

### 3.10 Adjacent bug — status spelling

`references/workflow-states.md` writes the third VI rung as **"Use cases defined"**. Jira and every export emit **"Usecases defined"**. `readiness-reviewer` matches status strings against that table, so the mismatch is a live string-comparison bug in `/ready`. One-word fix, in scope because §3.6 makes this file's vocabulary load-bearing for a second command.

## 4. Inputs and the `known_refs` contract

```yaml
vault_path:      <absolute $VAULT_PATH>
feature_summary: <2–4 sentences: the problem + desired outcome>
themes:          <capability themes from the caller, or []>
known_refs:      <list of {path | jira_key, has_summary} the caller already holds, or []>
```

Refuse to run without `vault_path` and a non-empty `feature_summary`.

**A `known_ref` whose `path` no longer resolves is dropped with a `notes` line — never an error, never fabricated.** Vault items get renamed and moved: `PRODUCT-14589`'s folder and work document were both renamed after its rewrite, leaving the shipped `idea.md`'s first `sources[].ref` pointing at nothing. Since `/create-vi` feeds `sources[]` straight into `known_refs`, dangling entries are ordinary input, not an exceptional case. When the dropped entry carried a Jira key, the finder re-resolves it by key (§3.2) instead of discarding it.

`known_refs` prevents the finder and `idea-reader` from summarising the same file twice — the exact duplicated-read cost entry 3 objects to. Entries are classified and status-resolved like any other match and returned with `discovered_by: source`; when `has_summary: true` the finder **omits** `salient_summary`, and the caller merges by `path`.

An entry carries **either** a `path` **or** a `jira_key`, never both required. A supplied `vi` source arrives as a key: the orchestrator does not know which vault directory holds that VI, and resolving it is the finder's job, not the caller's. A key that matches no vault work document is returned with `item_dir: null` and whatever status the export yields — a VI with no vault note is still prior art.

- `/idea` passes `idea-reader`'s `wikilinks_followed` paths and filesystem-path `source_refs` with `has_summary: true`, plus `{jira_key: <KEY>}` for a `vi` source (§3.1). The supplied VI is then classified and status-resolved by the same code path as a discovered one.
- `/create-vi` has no `idea-reader` — it reads the seed `idea.md` directly — so it passes the idea's `sources[]` paths and any `## Prior art` refs with `has_summary: false`.

## 5. Consumption

Five consumers. Every one is named here so none of this becomes a producer without a consumer.

**5.1 — Grill-rank (both commands).** `prior_art_challenges` merge with `docs_challenges` into **one** Impact × Uncertainty ranking and compete for the existing **≤5** question slots. They never add slots; `/idea`'s bound is untouched.

**5.2 — Write path (`/idea` Phase 4).** Two changes, and the second depends on the first.

*The provenance default becomes depth-aware.* Today it yields a flat `Projects/<Products|ideas>/<slug>/idea.md` regardless of how deep the source sits. It becomes `<container(source path)>/<candidate_slug>/idea.md` per §3.8. A source under `Projects/Products/<grouper>/<item>/` therefore lands beside its neighbours in `<grouper>/` instead of flat under `Products/` — matching the convention the vault already follows, with no prior-art match required. An inline prompt, a Jira key, and any source outside `Projects/Products/` all resolve to `Projects/ideas/` exactly as today, so the common case is unchanged.

*The gate.* **One** gate, assembled deterministically — not two that could both fire. Rows are built in this order and the array is presented verbatim:

| Row | Included when | Text |
|---|---|---|
| 1 | the source is `vi` **and** the finder resolved a vault item directory for that key | `Rewrite <KEY> — write into <item-dir>/` |
| 2 | `area_proposal.path` is non-null, `confidence: high`, **and** it differs from the provenance default's container | `New idea under <area_proposal.path>/<candidate_slug>/` |
| 3 | always | `Write to <provenance default>/<candidate_slug>/ as detected` |
| 4 | always | `Enter a different path` |
| 5 | always | `Cancel` |
| 6 | always | `Other… (describe)` |

The gate **fires iff at least one of rows 1–2 is present**; otherwise the provenance default applies silently. Row 2's differs-from-default test is load-bearing precisely because the default is now a container too — when the source already sits in the area the finder points at, the two agree and there is nothing to ask.

`(Recommended)` is appended to **exactly one** row, chosen by the top match's `relation`: `supersedes_self` → row 1; `predecessor_phase` or `analogous_precedent` → row 2 when present, else row 3; anything else → row 2 when present, else row 3. Row 1 is never recommended without `supersedes_self`, because extending and paralleling a VI are just as common as rewriting it (§2.8) and a wrong default here silently mints or fails to mint a Jira key.

**The choice is recorded as `vi_disposition`** — `rewrite` for row 1, `new` for every other row — and carried into Phase 5 (§5.4). This is the only place the three shapes of a supplied VI can be told apart, so the gate is not merely about a directory.

Every choice is validated to sit inside the resolved write root and be writable. The gate **never** auto-relocates and consumes **zero** grill slots — it sits beside the existing-file gate, where the path is actually decided.

`/create-vi` gets no gate: its path is keyed under `$SPECS_PATH/specifications/<KEY>-<slug>/`, so there is no area to resolve.

**5.3 — `## Prior art` in `idea.md`.** The durable carrier, fed from both directions — discovered matches and a supplied `vi` source alike. One bullet per entry:

```
- [[<work doc>]] (<JIRA-KEY>, <status>) — <relation>: <one line>
```

The whole section is omitted when nothing was found. A key or status is never fabricated; an unresolved status is written as `status unknown`. A `vi` source appears here **and** in `sources:` (§2.6).

**The Jira key is the durable identifier; the wikilink is a convenience that may dangle.** Obsidian wikilinks resolve by file name, and vault items get renamed — `P14589 ME Export Smartscape topology.md` became `P14589 Detect arch drift w MCP.md`. Carrying both means a later reader re-resolves by key when the link breaks. An entry with no Jira key carries only the wikilink, and that is accepted.

**5.4 — Phase 5 handoff.** Prior art is reported whether or not the gate fired — matched keys with statuses, and the alternative path when one exists. This is the feedback's stated minimum, and it is what lets the user relocate before `/create-vi` makes the path sticky.

The handoff additionally **consumes `vi_disposition`** (§5.2), because today's offer is wrong for a rewrite. It currently reads *"first create an empty Jira workitem, then run `/dev-workflows:create-vi <JIRA-KEY> …`"* — but a rewrite needs no new workitem and its key is already known:

- `vi_disposition: rewrite` → *"Next: `/dev-workflows:create-vi <KEY> @<path>` — this rewrites the existing VI; no new Jira workitem is needed. If an authored VI already exists for `<KEY>`, `/create-vi` will redirect you to `/dev-workflows:update-vi <KEY>`."*
- `vi_disposition: new` (and every run with no `vi` source) → the existing text, unchanged.

The `draft`-status variants keep their existing shape, differing only in the same clause. Without this, the run that ends in a rewrite tells the user to mint a key they must not mint.

**5.5 — Source typing (`/idea` Phase 1–2).** The resolved `issue_type` drives the provenance label, which drives how `idea-reader` reads the ticket (§3.1). Without a consumer the typing would be decoration.

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

Source typing (§3.1) and key resolution (§3.2) are **not** advisory — a `NOT_FOUND` key is a user halt exactly as today, and typing always produces a provenance.

**No consent gate.** This is local `Glob`/`Grep` over ~220 files: no model download, no index build, no network. F's stampede has no analogue here. Stated explicitly so a reviewer does not invent one — and equally, no expensive-work-without-consent risk to guard against.

## 8. Non-goals

Recorded with reasons, so a later reader does not read them as oversights.

- **No `/specify` wiring.** The feedback names it, but `jira-reader` already hands `/specify` the Jira hierarchy, so its marginal value is lowest and its wiring cost highest. Deferred as an explicit follow-up, not dropped.
- **No `qmd` or any retrieval index for the vault.** ~220 files after exclusions; grep is the right tool and adds no cache, no consent gate, and no staleness surface.
- **No Value Pack handling of any kind** (§2.1).
- **No change to `vi-format.md`.** `/create-vi` uses prior art in the grill and it lands in the VI's existing sections as prose. Deliberate: adding a VI section would need a `vi-reviewer` rule to be worth anything, and prior art is advisory.
- **No change to `jira-input-resolution.md`'s existing entry points.** §3.2 is purely additive; the eight commands that cite the file are untouched.
- **No cross-product inference.** The finder does not try to detect "this is the Managed twin of a SaaS feature" from product names. It classifies the relation from capability overlap and lets the grill ask.
- **No Jira or network calls.** Purely local vault reads, consistent with every agent in this plugin.
- **No auto-relocation** of an existing `idea.md`, and no writes into the vault beyond `idea.md` at its resolved path.
- **No feasibility/code grounding.** That is sub-project H.

## 9. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | A false-positive high-confidence match proposes someone else's area. | The gate always asks; it never auto-writes. The provenance default is always an offered option. |
| R2 | A new Jira status appears and the §3.6 map goes stale. | Unrecognised codes pass through verbatim and are recorded in `notes` — never guessed, never dropped. |
| R3 | `status_conflict` becomes noise when a sync lags. | Reported, never escalated, never a gate. It is the signal that catches a broken sync. |
| R4 | Duplicate export copies disagree (confirmed: `PRODUCT-14902`). | Most-recently-modified copy wins; the rule lives once, in §3.2. |
| R5 | **Dead gate** — the finder produces output nothing consumes. | §5 names five consumers; V13 enumerates each and traces it to a shipped line. |
| R6 | The deeper write path breaks `/create-vi`'s idea discovery. | **Verified safe** — `find "$VAULT_PATH/Projects" -type f -name idea.md` is recursive, so a deeper path still matches. |
| R7 | Parity drift across the three repos. | V16–V17; canonical files are copied, never retyped, into mgd. |
| R8 | The Phase 2.5 dispatch sits behind a conditional that skips it — F's `/epics` bug. | V9 traces control flow from Phase 2.5 to the first consumer in both commands. |
| R9 | The two grounding dispatches are serialised instead of parallel. | V8 asserts a single-response dispatch, per the plugin-wide parallel-dispatch invariant. |
| R10 | The depth-aware default changes where ideas land even on runs that find no prior art. | Intended: it matches the convention the vault already follows. Bounded by §3.8 case 3 — every source not under `Projects/Products/` resolves to `Projects/ideas/` exactly as today. V11b enumerates the unchanged cases. |
| R11 | §3.2 changes behavior for an existing `jira-input-resolution.md` caller. | Purely additive new entry point; V19 diffs the existing sections byte-for-byte. |
| R12 | Typing a non-VI, non-PRODFB issue type wrongly. | Never silent: the actual `issue_type` is surfaced in the Phase 1 confirmation and the user chooses. |
| R13 | The gate's `(Recommended)` marker steers the user to the wrong `vi_disposition`, which decides whether a Jira key gets minted. | The marker derives from the top match's `relation`, never from a fixed default; rows 1–3 are always all present; and the consequence is restated in plain words in the Phase 5 offer, where a wrong choice is still visible before any Jira action. |
| R14 | `supersedes_self` leaks onto a discovered match, making an unrelated item look like a self-rewrite. | Structurally impossible by definition — a search hit is a different item. V24 asserts no instruction path reaches it from `discovered_by: search`. |

## 10. Verification

No test framework — verification is grep, `awk`, `diff`, and reading. Every count is whitespace-normalized.

| # | Check |
|---|---|
| V1 | `references/vault-prior-art.md` exists and covers §3.3–§3.9, §4, §5, §7. |
| V2 | `agents/vault-prior-art-finder.md` has valid frontmatter with `name`, `description`, `tools: ["Read","Glob","Grep"]`. |
| V3 | The exclusion set (§3.3) appears as hard rules in the agent body: `Jira - `, Value Pack, `_archive/`. |
| V4 | The status ladder reads frontmatter **before** the export in both the reference and the agent. |
| V5 | The §3.6 table appears exactly once in the reference; the agent cites it rather than restating it. |
| V6 | No file instructs reading a `Jira - <KEY>/` path for status. |
| V7 | `idea-reader.md` output block carries `salient_summary` under both `source_refs` and `wikilinks_followed`. |
| V8 | Both commands dispatch `docs-grounder` and `vault-prior-art-finder` in a **single response**. |
| V9 | In both commands, no conditional between the Phase 2.5 dispatch and its first consumer can skip it. |
| V10 | `/idea` Phase 4 carries the write-path gate with the §5.2 `choices:` array verbatim, including `(Recommended)`. |
| V11 | The gate's firing condition names **all three** tests — `path` non-null, `confidence: high`, and differs-from-default. |
| V11a | The §3.8 container derivation appears **once**, in the reference; `/idea` Phase 4 and `area_proposal` both cite it rather than restating it. |
| V11b | Phase 4's provenance default is depth-aware, and the four unchanged cases still resolve to `Projects/ideas/`: inline prompt, Jira key, a source under `Projects/ideas/`, a source elsewhere in the vault. |
| V12 | `idea-format.md` has `## Prior art`, marked optional, with the §5.3 bullet shape, and `vi` in the `provenance` enum. |
| V13 | Each of the five §5 consumers traces to a shipped line — enumerate and judge, do not count. |
| V14 | `workflow-states.md` reads "Usecases defined"; no file still reads "Use cases defined". |
| V15 | `--no-prior-art` is documented in `/idea` and `/create-vi`; the Phase 1 line forms match §6 and promise no match count. |
| V16 | mgd differs from canonical in exactly the known identity files — enumerate the diff, do not assume the count. |
| V17 | copilot carries the same content in its own dialect with zero `dev-workflows:` leaks and its own version track. |
| V18 | All three catalogs, manifests, and changelogs read 2.48.0 / 2.48.0 / 2.18.0, with sibling plugins untouched. |
| V19 | `jira-input-resolution.md`'s pre-existing sections are byte-unchanged; only `resolve-export-for-key` is added. |
| V20 | `/idea` types a Jira source from `issue_type`, not from the project prefix — no `PRODUCT`/`PRODFB` string test decides provenance. |
| V21 | `/idea PRODUCT-14796` resolves (a nested-only `ValueIncrement`); the flat `jira-products/<KEY>/` assumption survives nowhere in `/idea` or `idea-reader`. |
| V22 | A `vi` source appears in **both** `sources:` and `## Prior art`, and `idea-reader` does not mine it for demand signals. |
| V23 | `analogous_precedent`/`precedent_alignment` and `supersedes_self`/`rewrite_delta` are defined in the reference and reachable from the agent's classification instructions. |
| V24 | `supersedes_self` is reachable **only** for `discovered_by: source`; no instruction path produces it from a search hit. |
| V25 | `/idea` Phase 4 ships **one** assembled gate with the §5.2 row order, the stated inclusion conditions, and exactly **one** `(Recommended)` marker whose placement is derived from `relation` — not fixed. |
| V26 | `vi_disposition` is produced in Phase 4 and consumed in Phase 5; **both** handoff forms ship, and no path still tells a rewrite run to create an empty Jira workitem. |
| V27 | The §3.8 Jira-key rule ships: a key source resolves `P` to the matched item's vault directory, and falls back to absent (⇒ `Projects/ideas/`) when there is none. |

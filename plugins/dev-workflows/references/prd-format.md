# Product Requirements Document format (embedded authority)

The canonical structure and per-section rules for a `prd.md` PRD file — one per PRD folder, its identity carried by the folder rather than by its own name (`references/addressing.md` §2, §4). `/create-prd` and `/update-prd` author
against this file; `prd-reviewer` reviews against it, and `/release-notes` reads its former mirror fields. The PRD is **product-level** (a PRD): what / why /
for-whom, **not** how — no implementation detail. A mandatory **spine** (always present) plus an
**adapt-in menu** whose clusters are pulled only when the idea warrants them (never an empty section).

## Profiles

- **`--lean`** — spine only.
- **`--hybrid`** (default) — spine + the hybrid adapt-in clusters.
- **`--full`** — spine + the full adapt-in menu.

## Frontmatter (PM-authorable subset)

```yaml
---
kind: prd                    # what this document is
key: <KEY>                   # this folder's key — must match the folder name
title: <human-readable PRD title>
summary: <one-line>
status: <e.g. draft>
owning_program: <program>
tracking_programs: [ ... ]
priority: <e.g. Major>
labels: [ ... ]
relevant_for_release_notes: <yes | no>
sources:                     # PROPAGATED from idea.md's recorded provenance — not the literal idea.md
  - provenance: rfe | prd | community-post | prompt | markdown
    ref: <RFE key | post URL | ...>
derived_from: <path to the idea.md this PRD was built from>
seeded_from_prd: <PRD key or path when this PRD was seeded from another PRD via `/create-prd --from-prd`; omit otherwise>
brd_key: <the BRD key this PRD was authored from via `/create-prd` on the BRD route; omit otherwise>
brd_parent: <that slice's parent BRD key, from its brd-link.md; always present on the BRD route, since the route resolves a PRD- slice folder and a slice always has a parent:; omit outside the BRD route>
depends_on: [ ... ]           # prerequisite BRD keys, from that brd-link.md's depends-on; omit when empty or outside the BRD route
revision_of: <path to the archived prior PRD snapshot; written by `/update-prd` on refresh; omit otherwise>
built_from_date: <YYYY-MM-DD of the resolved folder the `/update-prd` refresh was built from; omit otherwise>
workitem_key: <optional — your own tracker's identity for this work; the plugin never writes it>
---
```

`brd_key`, `brd_parent` and `depends_on` are written only by `/create-prd` on the BRD route, from the BRD's
own `brd-link.md`, and are never asked of the PM. **`brd_parent` is present on every PRD that carries
`brd_key`.** The BRD route resolves a `PRD-` slice folder and refuses a `BRD-` container before any
seed is read (`commands/create-prd.md` Phase 0 step 5a), and a slice always carries a
`parent:` — so the earlier "omitted when it owns its source document" case describes a PRD the route
can no longer author. An absent `brd_parent` beside a present `brd_key` is therefore a **finding**,
not a legitimate omission, and `agents/prd-reviewer.md` raises it. **`/update-prd` preserves all three and authors
none of them** — on a PRD that carries them it copies each through the refresh unchanged, and on a
PRD that does not it writes none — so the *written only by* rule above still reads exactly as it
says: carrying an existing value forward mints no new one, and `/update-prd` reads no BRD tree it
could mint one from. They record, on the PRD itself, the BRD identity and the prerequisites the
customer committed to — and **no command consumes them yet** — which is a claim about *behaviour*, not about
every read. Neither `/epics` nor `/ready` reads any of the three, and nothing branches on them. But
`brd_key` and `brd_parent` do have a reader: `agents/prd-reviewer.md`'s review method raises a finding
when one is present without the other, exactly as this file says six lines above. That is an integrity
check on the pair, not a consumer of what they record, and the distinction matters in both directions —
an increment scoped on "these have no reader" would be scoped against a check that already ships and
already gates every PRD on both routes.
**Nothing consumes the prerequisites these fields record.** Wiring a consumer is new behaviour on
commands used heavily by non-BRD routes and belongs in its own increment with its own review. They are
written, and preserved through a refresh, because provenance recorded at authoring time is the
precondition for any future consumer: re-deriving it later would mean re-reading a BRD tree that may
have moved on. A `brd_key` may carry a third numeric segment
(`references/addressing.md` §1 fixes no depth), so a PRD authored inside a BRD slice is filed
under a key the two-segment form would reject — validate **that folder-side key**, and the
folder name built from it, against §1's grammar rather than a narrower one. **The same holds of
`key`**, which on the BRD route *is* that slice key: it fixes no depth either, and a rule that
`key` is "two-segment everywhere" would reject the ordinary BRD-route PRD.

**`key` is written by `/create-prd`, on both routes, and by nothing else.** It is set to the key of
the folder the run resolved — the positional key on the idea route, the `PRD-` slice's own key on the
BRD route (`commands/create-prd.md` Phase 3, the frontmatter step) — and `/update-prd` carries it
forward unchanged rather than re-deriving it. **It was for a time deferred on the BRD route** to a
tracker step that minted a second identity and wrote it back; that step is gone, nothing replaced it,
and the field simply stayed unset — which left a folder whose only `kind:`+`key:` carrier was
`brd-link.md` (`kind: brd`) resolving as a BRD rather than a PRD (`references/addressing.md` §4), and
left `/document` and `/release-notes` grepping commits for an empty key. There is no second identity
to keep straight: one namespace, one grammar, and the folder's key is the key. **So there is no
legitimate state in which `brd_key` stands beside an absent `key`** — `agents/prd-reviewer.md` raises
one as a finding on every route.

**`workitem_key` is reserved, documented, and never written by the plugin.**

```yaml
workitem_key: CU-8x9f2a1     # optional, the user's own; the plugin never mints it
```

A user who also keeps their work in a tracker records its identity here. The plugin **preserves it
across every frontmatter rewrite, and displays it in reports.** It never mints it, never validates
its shape, and never resolves a folder by it — a folder is addressed by `key` and by nothing else.

**The name is vendor-neutral on purpose.** Genericising in speech but not in a field name a tool
parses is how a field ends up meaning something narrower than it says: someone writing a ClickUp sync <!-- vendor-token-ok: one named third-party tool standing for "any tracker a user keeps", the argument's whole point -->
who reads a field named for one vendor reasonably wonders whether it must be that vendor's shape.

**It is not decorative, and here is its one consumer.** `/document` and `/release-notes` search commit
messages for the run's identifiers, and `workitem_key` is one of the tokens they grep for — so a team
whose commit convention carries their tracker key gets hand-made commits found. That is a *search for
a token the run already holds*, not a lookup: the plugin still learns nothing about whether a tracker
exists.

**Unknown frontmatter keys are preserved.** Every command that rewrites this file — `/update-prd`
most of all — keeps fields it does not recognise, in place and unmodified. Without this rule a user's
own `clickup_id` disappears on the next run and nothing reports it. <!-- vendor-token-ok: an example of a user's OWN frontmatter key, which this rule exists to preserve --> The rule is small and its blast
radius is not: it is what makes the frontmatter extensible rather than a closed vocabulary.

**There is one key namespace.** `brd_key` and `key` both name a folder in `$SPECS_PATH`, validated
for shape and never looked up anywhere (`references/addressing.md` §1). The second, narrower grammar
this paragraph used to police belonged to a tracker-minted key, and no tracker mints anything now.

**`release_versions`, `change_type` and `release_notes_category` are authored here, and that is a
reversal.** They were dropdowns set outside the plugin and returned by an import, so this file
forbade authoring them or asking for them — the question bought nothing when the answer already
existed elsewhere. Nothing supplies them now, so each is authored where it is known and asked for
where it is not: `change_type` and `release_notes_category` are inferred and confirmed in
`/release-notes`'s own grill (`references/release-note-types.md` §7), and `release_versions` comes
from that command's `--version` flag or the same grill. **Never invent one** — an unanswered field is
omitted, not filled.

## Spine (always, every profile)

- `## Problem` — who is affected and why the current situation is insufficient; why now. Solution-free; no implementation detail.
- `## Goal` — a crisp 2–3 sentence statement of the outcome (feeds the folder read's goal extraction and every downstream consumer).
- `## Target audience` — the personas/roles served (specific roles, not "everyone").
- `## User Stories` — `### [US#N]: <title>`, `As a [role], I want [capability], so that [benefit].` Contiguous IDs.
- `## Acceptance Criteria` — `[AC#N]` under each story; externally-observable pass/fail (no "be reliable"/"improve performance").
- `## Scope` — **In scope** (concrete delivered behaviours) / **Out of scope** (concrete confusable exclusions; never "anything else"/"future work").
- `## Success Metrics` — `[SM#N]`; measurable, technology-agnostic outcomes. Optionally add **counter-metrics** (`[SMC#1]`, `[SMC#2]`…) — a metric explicitly named as *not* to be optimized or gamed, counterbalancing a Primary SM (e.g. "throughput up, but `[SMC#1]` error-rate must not rise").

## Adapt-in menu (pulled only when warranted)

| Cluster | hybrid | full |
|---|:-:|:-:|
| `## Use cases & user journey` (`[UC#N]` narrative) | ✓ | ✓ |
| `## Non-functional requirements` | ✓ | ✓ |
| `## Assumptions & open questions` (hybrid: light list; full: Contradictions Log table — Item/Source/Impact/Resolution/Owner) | ✓ | ✓ |
| `## Why now / differentiation` | ✓ | ✓ |
| `## References / linked issues` | ✓ | ✓ |
| `## Documentation impact` | ✓ | ✓ |
| `## Short Abstract / Blogline` (Internal + External) | | ✓ |
| `## Customer Zero` | | ✓ |
| `## Competitive snapshot` (1–3 competitors × Approach / Differentiation / Pricing) | | ✓ |
| `## Functional requirements` (`[FR#N]` *Implements: `[UC#n]` / `[US#n]`*) | | ✓ |
| `## E2E Demo` (per-delivery pass/fail acceptance) | | ✓ |
| `## UX prototype / UI mockups` | | ✓ |
| `## API specification` | | ✓ |
| `## Key deliverable & plan` | | ✓ |
| `## Enablement` (launch / preview) | | ✓ |
| `## Cost analysis` | | ✓ |

## Quality rules

- **No implementation detail** anywhere — the PRD is product-level (algorithms, data structures, code paths, internal APIs belong to the ARD / spec / design).
- **Internally consistent** — no requirement contradicts another or the scope: no `[AC#N]` delivering an Out-of-scope behaviour, no `## Goal` asserting a scope the `## Scope` section contradicts, no conflicting `[US#N]`. A deliberately-kept tension is recorded under `## Assumptions & open questions`, never left implicit in a requirement.
- **FR / UC must not restate US** — reference by ID; each adds capability/behaviour, not a paraphrase.
- Acceptance criteria and success metrics are **externally observable**.
- Consolidate shared data dependencies rather than repeating them.
- Detailed **Test Cases are NOT authored here** — they are `/specify`'s `specification.md` (`[TCxx]`).

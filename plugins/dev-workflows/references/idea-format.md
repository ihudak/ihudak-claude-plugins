# Idea format (embedded authority)

The canonical structure and per-section rules for a refined `idea.md`. `/idea` is the only caller — it authors against this file. `/create-vi` consumes the resulting `idea.md` **artifact**, not this format doc, and never cites it. A lean one-page brief — the seed a Value Increment is built
from, NOT a mini-VI.

## Frontmatter

```yaml
---
title: <candidate human-readable title>
slug: <candidate-kebab-slug>
sources:
  - provenance: rfe | vi | markdown | community-post | prompt | doc-grounding
    ref: <path | JIRA-KEY | url>
created: <YYYY-MM-DD>
status: draft | refined        # refined IFF zero open [NEEDS CLARIFICATION] remain
---
```

Rules: `status` is `refined` only when the **Open questions & assumptions** section carries zero
`[NEEDS CLARIFICATION]` markers; otherwise `draft`. `sources` lists every ingested source with its
provenance (re-running `/idea` for the same `slug` refines the existing file and appends a source).

## Section 1 — Problem

`## Problem` — the pain today, solution-free. Who is affected and why the current situation is
insufficient. No proposed solution, no technology detail.

## Section 2 — Who

`## Who` — the target users / personas affected. Specific roles, not "everyone".

## Section 3 — Desired outcome & value

`## Desired outcome & value` — the value hypothesis: what "better" looks like and why it matters now.

## Section 4 — Rough scope

`## Rough scope` — **In:** initial in-scope bullets; **Out:** initial guardrails. *What*, not *how*.

## Section 5 — Signals & evidence

`## Signals & evidence` — demand evidence grounding the idea: RFE reference, community-post
requesters/upvotes, wikilinked docs, and image references. Cite sources; never fabricate.

**Code findings never go here.** This section is *demand* evidence only. Feasibility findings from a
`--ground-code` run — what the code already does, what is missing, and any reframing they force —
belong in **Feasibility grounding** (Section 7).

## Section 6 — Prior art (optional)

`## Prior art` — tracked initiatives in the vault that this idea covers, continues, parallels, or
rewrites. **Write it when prior art was discovered *or* the source is a `vi`; omit it entirely
otherwise.** One bullet per entry, in one of two shapes.

**Discovered** — the finder matched the item, so every slot has a source:

```
- [[<work doc>]] (<JIRA-KEY>, <status>) — <relation>: <one line>
```

**Supplied only** — a `vi` source the finder did not match (grounding off, or no vault work document
for the key). The `tracked` block carries `jira_key`, `status`, and `summary` and nothing else — no
`relation`, no `match_reason`, no vault path — so the bullet omits the wikilink and the relation
rather than inventing either:

```
- <JIRA-KEY> (<status>) — supplied source: <summary>
```

Never promote a supplied-only entry into the discovered shape by guessing a `relation`; the closed
vocabulary is the finder's output, not the author's choice.

In the discovered shape every slot is **transcribed from the prior-art digest, never invented**:
`<JIRA-KEY>` and `<status>` from its `jira_key` / `tracked_status`, `<relation>` verbatim from its
`relation` field (the closed vocabulary lives in
`${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md`), and `<one line>` a plain-language rendering of
that entry's `match_reason` — why this initiative bears on the idea.

The **Jira key is the durable identifier**; the wikilink is a convenience that dangles once a vault item
is renamed, so both are carried and a later reader re-resolves by key. An entry with no Jira key carries
only the wikilink, and that is accepted. Never fabricate a key or a status — an unresolved status is
written as `status unknown`. A `vi` source appears here **and** in `sources:`: `sources` answers how the
idea arrived, `## Prior art` answers what it must stay consistent with.

## Section 7 — Feasibility grounding (optional)

`## Feasibility grounding` — what the code says today about whether this idea is needed and how large it
is. **Write it when code grounding ran *and* returned at least one finding; omit it entirely
otherwise** — a grounded run that found nothing writes no empty section and no "nothing found" line.

The section opens with what its claims were true of: a single line naming every grounded repo as
`<repo>@<scanned_ref>`, taken from `code-scanner`'s `prep.scanned_ref`. Code moves; a finding with no ref
is unfalsifiable a month later.

Then up to three slots, each optional and each omitted when empty:

- **What exists** — capability present in the code today.
- **What's missing** — the gap, characterised.
- **Reframing** — ONE line, written only when a finding contradicted the idea's premise: the framing the
  source implied, and the framing the code supports.

Every bullet carries a repo-qualified citation `<repo>/<path>:<line>` — the **first** entry of that
evidence's `lines` — or `<repo>/<path>` when the evidence entry has no `lines`. **A bullet with no
citation is not written**: a feasibility claim with no anchor is exactly what this section exists to
prevent.

Nothing speculative goes here. A theme the scan could not resolve is a `[NEEDS CLARIFICATION]` in
**Open questions & assumptions** (Section 8), never a hedged bullet here.

## Section 8 — Open questions & assumptions

`## Open questions & assumptions` — unresolved decisions as `- [NEEDS CLARIFICATION: <question>]`
(**capped at 3** — the highest-impact only); reasonable defaults recorded as
`- **Assumption:** <text>`.

## Section 9 — Candidate success signal

`## Candidate success signal` — how we'd know it worked (rough, outcome-oriented, technology-agnostic).

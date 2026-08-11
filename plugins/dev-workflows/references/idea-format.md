# Idea format (embedded authority)

The canonical structure and per-section rules for a refined `idea.md`. `/idea` authors against this
file; `/create-vi` (future) consumes it. A lean one-page brief — the seed a Value Increment is built
from, NOT a mini-VI.

## Frontmatter

```yaml
---
title: <candidate human-readable title>
slug: <candidate-kebab-slug>
sources:
  - provenance: rfe | vi | markdown | community-post | prompt
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

## Section 7 — Open questions & assumptions

`## Open questions & assumptions` — unresolved decisions as `- [NEEDS CLARIFICATION: <question>]`
(**capped at 3** — the highest-impact only); reasonable defaults recorded as
`- **Assumption:** <text>`.

## Section 8 — Candidate success signal

`## Candidate success signal` — how we'd know it worked (rough, outcome-oriented, technology-agnostic).

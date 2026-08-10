# `/document` authoring and placement — design

**Sub-project B2** of the 2026-08-07 PM feedback round on `dev-workflows`.
B1 (`/document` gate enforcement) shipped 2026-08-09 as dev-workflows 2.43.0
(canonical + mgd) and 2.13.0 (copilot). This design covers the eight remaining
entries in `$SPECS_PATH/dev-workflows-feedback/PRODUCT-17012-feedback.md`.

**Target versions:** dev-workflows 2.44.0 (canonical + mgd), 2.14.0 (copilot).

---

## Context

On the PRODUCT-17012 run the workflow produced documentation that was correct in
substance but wrong in placement, carried noise the target repo does not use,
modified a governance file that would have delayed the PR by months, and left
three stale screenshots live on the pages it edited. Every one of these was
found by the user after the run reported success.

B1 fixed the *verification* half of that run. This is the *authoring* half.

## Problem

Eight defects, of which two have a materially different root cause than the
feedback file recorded — both discovered by grounding the design against the
shipped plugin and the mounted docs repo rather than against the report.

**The deprecation note was not missed. It was forbidden.**
`agents/doc-location-finder.md:42` carries a hard rule:

> NEVER propose a What's New / release-notes path (e.g. `_content/whats-new/...`,
> `_snippets/release-notes/...`, `_data/release-notes/...`) as a target — those
> are generated from Jira by automation; release notes are produced by the
> `/release-notes` command.

The rule is correct about release notes and correct about why: `/release-notes`
feeds them, and hand-editing them is wrong. It is wrong about one directory.
`dynatrace/_content/whats-new/technology/end-of-life-announcements.md` is
hand-authored — its git history is human PRs (`MGD-13397: Announce deprecation
of legacy ActiveGate Update now`, `NOISSUE OneAgent EOL updates`) — and nothing
generates it. The finder did not fail to scan; the plugin banned the answer.
`agents/doc-planner.md:44` and `:201` carry mirrors of the same rule.

**The provenance comments were not improvised. They were mandated.**
`agents/doc-writer.md:63`:

> **Traceability** — every claim must cite the originating Jira key (e.g.
> `[[<JIRA_KEY>]]`) and/or PR URL inline.

and `agents/doc-reviewer.md:54` enforces the identical rule as review dimension
12, "Source traceability". The writer emitted provenance and the reviewer
endorsed it, both correctly following instructions. Meanwhile the plugin states
the opposite for the changelog field in three separate places — `doc-writer.md:54`,
`doc-planner.md:51` and `:188`, `commands/document.md:1002` — each some form of
*"traceability lives in the commit message, not the reader-visible page"*. The
plugin contradicts itself, and `[[wikilink]]` is an Obsidian-vault convention
that renders as literal text in a product docs repo.

The other six defects are absent rather than wrong: zero occurrences of
"callout" or "tabgroup" anywhere in the plugin, nothing about existing images
being stale, and no heading-anchor convention documented at all.

---

## §1 — Destination discovery

### 1.1 The release-notes ban stays; announcement pages are exempt

The ban is not narrowed in intent. Release notes are generated from Jira and
surfaced by the separate `/release-notes` command, so `/document` must never
write them. What changes is that the rule stops treating a directory prefix as
a proxy for "generated".

The rule's exclusion set becomes what is genuinely automation-owned:

- a page whose frontmatter carries `meta.content-type: release-notes`
- anything under `_data/release-notes/**`
- anything under `_snippets/release-notes/**`

and it gains one named exemption: **a page declared in the profile's
`announcement_pages` block is a valid target.**

Under `dynatrace/_content/whats-new` this excludes 182 pages and releases 10.

`agents/doc-location-finder.md:42` and its two mirrors in
`agents/doc-planner.md` (`:44`, `:201`) change in lock-step. Removing one and
leaving the others is the failure mode this repo has hit before.

### 1.2 `announcement_pages` in the docs profile

`references/dynatrace-docs/docs-profile-schema.md` gains the block; the shape is
a list of `{postid, path, kinds}`:

```yaml
announcement_pages:
  - postid: end-of-life
    path: dynatrace/_content/whats-new/technology/end-of-life-announcements.md
    kinds: [deprecation, end-of-life, shutdown, sunset]
  - postid: eos-announcements
    path: dynatrace/_content/whats-new/technology/end-of-support-news.md
    kinds: [end-of-support]
  - postid: new-technology-support
    path: dynatrace/_content/whats-new/technology/index.md
    kinds: [new-technology]
```

`references/dynatrace-docs/docs-profile.default.yml` carries exactly those three
entries. `path` is the authority when both `path` and `postid` are present and
disagree; `postid` alone is enough when the repo's link convention is postid-based.

**Where the kind comes from.** `doc-location-finder` derives it from the
`feature_summary` it already receives — the caller composes that from the
`jira-reader` themes plus the VI goal, so a deprecation, shutdown, end-of-support,
or new-technology-support signal in the ticket reaches the finder without a new
input. Zero matching kinds means the block is simply not consulted; no
announcement target is proposed and nothing is logged.

When a kind matches, the finder proposes the declared page as an **additional**
target alongside the feature-subtree ones — it never replaces them. The
deprecation note belongs on the announcement page *and* a pointer belongs where
the feature is documented; that is what the run's manual fix ended up doing.

`commands/docs-profile.md` learns to discover the block so a fresh repo gets a
populated one.

### 1.3 The heuristic fallback

A docs repo with no `announcement_pages` block is not left with today's
behaviour. The exclusion set in §1.1 is itself the fallback: with the ban keyed
on `content-type` and the two release-notes roots rather than on the
`whats-new/` prefix, the existing topical index can reach an announcement page
on its own.

The fallback is necessary rather than decorative:
`whats-new/technology/end-of-support-news.md` carries **no** `content-type` at
all, so a content-type-only discriminator would misclassify one of the three
destination pages. The profile block is the reliable path; the heuristic is what
keeps an unprofiled repo from reproducing the original miss.

### 1.4 The scope gap in the same input contract

`agents/doc-location-finder.md:13-17` defines its entire input contract as
`repo_root`, `feature_summary`, `diff_highlights`. It receives no
`target_spaces`, no `content_root`, and no `profile`. On a Managed-only run
nothing prevents it proposing a SaaS path.

The contract gains `target_spaces` and `profile`, and `commands/document.md:409`
passes them. This is in scope because it is the same agent, the same contract,
and one line of the same edit — leaving it would mean opening the file twice.

---

## §2 — The traceability boundary

New reference `references/doc-structure-conventions.md`, §1.

**The rendered page carries no source provenance.** Jira keys, PR URLs, and
`<!-- KEY: … -->` comments belong in the commit message and in the run's
handoff — never in body prose, never in a changelog entry, never as an HTML
comment in the markdown.

Three tiers, stated once:

| Where | Carries |
|---|---|
| Rendered page | The customer-facing claim only. |
| Commit message | The Jira key and the summary (`profile.commit_convention`). |
| Run handoff / Phase 9 report | Per-claim attribution to Jira keys and PR URLs. |

Consequent edits:

- `agents/doc-writer.md:63` is rewritten to state the boundary and cite the
  reference. It currently mandates the opposite.
- `agents/doc-reviewer.md:54` (dimension 12, "Source traceability") inverts: a
  Jira key or PR URL appearing in a rendered page is a **MAJOR**. The dimension
  keeps its name and its output slot; only its test changes.
- The three scattered changelog statements (`doc-writer.md:54`,
  `doc-planner.md:51` and `:188`, `commands/document.md:1002`) become citations
  of the one authority rather than four independent restatements.

**One exception survives unchanged.** `source-truth.md` §7.6's
`<!-- intentional-discrepancy: … -->` marker stays. It is a deliberate,
user-decided flag on a spec-vs-code gap, not provenance, and `doc-reviewer.md:57`
and `:133` continue to check it.

---

## §3 — Phase 8 write scope

### 3.1 Propose mode

Phase 8's Agents 2 (knowledge) and 3 (instructions) stop writing into the target
repo. Each returns a **precise proposed edit** — file, anchor, replacement text,
and the reason — rather than applying it. Agent 1 (documentation) keeps writing:
doc index and cross-link edits are the docs work this run exists to do. Agent 4
(`impl-maintenance`) is already suggest-only, so this makes Phase 8 internally
consistent.

This lands in **both modes**: `commands/document.md:954` (Jira mode) and
`commands/document.md:1413` (direct mode). Direct mode never commits, so a
commit-path exclusion would have left it silently writing to `CLAUDE.md`.

There is existing precedent for the distinction — `emit-auto` at
`commands/document.md:983` and `:1442` already filters *"never target-project
`CLAUDE.md`/hook advice"*.

### 3.2 The apply phase

A new phase in each mode:

- **Jira mode — Phase 8.6**, running **after** Phase 8.5 has sealed the docs
  commit.
- **Direct mode — Phase 4.5**, between Phase 4 (maintenance) and Phase 5 (final
  report). Direct mode never commits, so the ordering constraint below is already
  satisfied; the phase exists so an accepted proposal still gets applied.

Present the proposals from Agents 2 and 3 — one row per proposal, showing file,
the rule or entry, and the reason. Then:

```
choices: ["Skip — report only (Recommended)", "Apply all", "Choose per proposal", "Cancel"]
```

Each accepted proposal is applied by **re-dispatching the agent that produced
it** in apply mode, carrying its own proposal back. The agent that wrote the
proposal is the agent that writes the file; no new agent type is introduced.

**Applied edits are left uncommitted.** Because the phase runs after the squash,
an accepted `CLAUDE.md` edit cannot ride the docs commit or the docs PR — which
is the entire point: in this repo a `CLAUDE.md` change needs its own PR on the
user's timing.

The final report (Phase 9 in Jira mode, Phase 5 in direct mode) gains two
sections:

- `## Proposed maintenance (not applied)` — every declined or skipped proposal,
  with enough detail to apply by hand later.
- `## Maintenance applied (uncommitted)` — every applied edit, stated as
  deliberately excluded from the docs commit.

A later run's Phase 6.2 clean-tree check will trip on uncommitted maintenance
edits. That is correct behaviour, not a wart: unresolved governance edits should
block a new documentation run until handled.

### 3.3 The stale clause

`commands/document.md:1000` and `references/finish-and-handoff.md:18-21` both
read:

> Stage the run's uncommitted docs-repo edits — Phase 8 Agent 1 (doc index /
> cross-links) and Agent 3 (`CLAUDE.md`) may have edited without committing …

Both drop the `Agent 3 (CLAUDE.md)` clause. After §3.1 nothing uncommitted
originates there, and the sentence would otherwise describe a path that no
longer exists.

---

## §4 — Callout scope and adjacency

`references/doc-structure-conventions.md`, §2.

A callout that qualifies one member of a set is placed **with that member**,
never as a trailing block after the set. Specifically:

1. When a step or section presents mutually exclusive options, each option owns
   its callouts, placed immediately beneath it.
2. A callout that applies to the whole set goes in the lead-in, **before** the
   options — never after them, where position alone reads as "and finally, this
   applies to everything above".
3. Where placement alone could still mislead, the callout names its own scope in
   its first clause — *"This applies only to the Private Container Registry
   option."*

Consumers: `doc-planner` plans placement per option; `doc-writer` writes it;
`doc-reviewer` flags a callout whose position admits a broader reading than
intended, at **MAJOR** — a misread scope changes what the customer believes is
required or prohibited, which is a correctness failure rather than a stylistic
one.

The reviewer check is the one that was missing. On the shipped page an ARM
limitation specific to the built-in *cluster* registry read as a constraint on
all four options — including a customer-owned private registry, where it is
simply false, since the customer controls that registry's contents and can hold
multi-arch images. A second callout about manually editing `dynakube.yaml`, true
only for the private-registry option, read as a step required for the public
ECR and Docker Hub options too.

---

## §5 — Component-pattern fidelity

`references/doc-structure-conventions.md`, §3.

`agents/doc-planner.md` step 5 already samples 5–10 sibling markdown pages under
the target's folder plus up to 3 ancestor folders, to classify image policy. The
**same sample** gains a second job: record which content component the area uses
for each recurring content shape.

Output block:

```yaml
component_patterns:
  - shape: mutually-exclusive-options
    component: "{{#tabgroup}} / {{#tab title='…'}}"
    evidence: "guides/container-registries/use-public-registry.md:176"
    count: 4
```

`shape` is an open vocabulary, not a closed enum — the planner records what it
observes and names it. Mutually-exclusive option sets, collapsible detail, and
tabular reference are seed examples for the reference doc, not the permitted set.

`doc-writer` reuses the dominant component for a matching shape instead of
inventing a structure. `doc-reviewer` flags a divergence where a sibling pattern
exists, at **MINOR** — an ad-hoc structure still renders, so this is a
consistency and scannability finding, not a correctness one. The human reviewer
who caught it on the shipped page said as much: *"Not a blocker … but worth
considering."*

**No component list is vendored.** The rule is repo-agnostic; the evidence comes
from whatever repo is in front of it. This matters because the failure was never
ignorance that `{{#tabgroup}}` exists — the docs repo's own `CLAUDE.md:43`
documents it, and B1's `repo_authoring_guidance` extraction already reaches that
file. What no guidance file states is *"use tabgroup for mutually-exclusive
option sets"*; that convention exists only in the sibling pages.

The scan would have been decisive here: 4 of the 5 pages in
`dynatrace/_content/ingest-from/setup-on-k8s/guides/container-registries/` use
`{{#tabgroup}}` (the fifth is a landing index with none), and nesting a tabgroup
inside an ordered-list step is established across 49 pages repo-wide — so the
writer's stated worry about "unverified rendering implications" was answerable
from the repo itself.

---

## §6 — Images: one phase, two lists

### 6.1 The phase

Phase 5.6 becomes the single image step and **always runs**. It sources two
lists:

- **To add** — specs dir scan, `jira-reader` `attachments[]`, project dir scan,
  manual paths. Unchanged.
- **Possibly stale** — images already present on each `extend-existing` target,
  each with its file, URL, the section it sits in, and its space gating
  (`{{#if project='…'}}` or none).

The Phase 1 question (`commands/document.md:193-197`) is reworded to seed the
add-list only. Today answering "No screenshots needed" sets `images_wanted: false`
and skips Phase 5.6 entirely — which is precisely how three stale images
survived a run where the user had been asked about screenshots and answered.

### 6.2 Per occurrence, not per URL

Stale candidates are listed **per occurrence**. In the PRODUCT-17012 run one CDN
URL appeared twice in `quickstart/index.md`, once under `{{#if project='saas'}}`
and once under `{{#if project='managed'}}`, and the SaaS-gated occurrence renders
in a space where the feature does not exist. Listing occurrences separately, each
with its gating, is what allows a per-occurrence decision.

### 6.3 URL collection reuses Phase 6.1

No new handoff mechanism. `commands/document.md` Phase 6.1 already offers
*"Upload now — I'll paste the CDN links"*, collects one URL per image, validates
it, records `cdn_urls[<image>]`, and has Phase 6.3 write the real URL into the
markdown. Stale replacements join that same list.

What changes is what the writer does with the result: **swap an existing
reference** rather than insert a new one.

### 6.4 CDN immutability

Stated in `docs-profile.default.yml`'s `images.policy`, in
`docs-profile-schema.md`, and in the `doc-writer` image step — it is currently
absent everywhere:

> A CDN URL is immutable. Every new or replacing screenshot is a new URL, and
> the docs edit is always a URL swap. An image is never refreshed in place.

Deprecating the superseded asset is a manual, CDN-side action by the user,
outside the repo and outside this workflow. The plugin does nothing about it.

### 6.5 Ledger gate

`references/gate-ledger.md` §4 gains one row:

| Gate id | Phase | Precondition | Primary | Fallback |
|---|---|---|---|---|
| `image_review` | 5.6 | ≥1 candidate image (to add or possibly-stale) | the two-list review with per-occurrence decisions | none |

`SKIPPED_BY_USER` carries the user's verbatim words; `NOT_APPLICABLE` names the
unmet precondition (no candidates of either kind). §3's one-row-per-gate rule
applies unchanged.

This is an input-side gate rather than an output-verification gate, unlike the
six existing ones. It belongs in the ledger anyway: the accountability need is
identical, and an unattributed image skip is exactly the failure mode the ledger
exists to prevent.

**The direct-mode carve-out must be updated in the same edit.** `gate-ledger.md`
§4 currently states that direct mode registers exactly three gates and names the
three ids that never appear in a direct-mode ledger. Direct mode has no Phase
5.6, so `image_review` joins that list — it becomes three registered and **four**
never-appearing. Adding the registry row without amending that paragraph would
leave `image_review` undefined for direct mode while §6 makes a missing row a
reviewer BLOCKER, which is precisely the self-blocking defect B1's Task 1 had to
repair.

### 6.6 Reviewer

Dimension 9 ("Screenshots") extends to **swap completeness** — every accepted
replacement URL replaced at every occurrence the review listed. The real fix
touched 3 occurrences across 2 files; a partial swap leaves a stale image live
and is invisible in the diff.

---

## §7 — Anchor conventions

New reference `references/dynatrace-docs/anchor-conventions.md`. Repo-specific,
so it lives under `dynatrace-docs/`.

**One `{:#id}` per heading.** 1,580 files under `dynatrace/_content` +
`managed/_content` use single-anchor syntax; multi-anchor `{:#a #b}` appears
**0 times**. Multi-anchor is unsupported — a fact to cite, not a hunch for each
run to re-derive.

**Link forms**, all verified in-repo:

| Form | Purpose | Occurrences |
|---|---|---|
| `[text](<postid>)` | whole page | (existing `internal_links.convention`) |
| `[text](<postid>#<anchor>)` | cross-page section | 19,560 |
| `[text](#<anchor>)` | same-page section | 4,006 |
| `{{#tabgroup anchor='id'}}` | mints an anchor on a tab group | 698 |

**Tooling.** `pnpm docstack validate-anchors` — *"Validate if anchors point to
hardcoded ids."* An anchor link must target a hardcoded `{:#id}`, not a
generated one.

**Reconciling a product `dt-url` deep link.** When shipped product code
deep-links to `#some-anchor` on a docs page, the page's authored anchor matches
the product's — the product is the harder side to change and ships on its own
cycle. If it cannot match, the mismatch is recorded as a discrepancy through the
normal Phase 5.8 path, not deferred on an in-session judgment that the syntax
"appears unsupported".

Consumers: `doc-writer` (authoring anchors and links), `doc-reviewer`
(dimension 5), `doc-planner` (planning section anchors for cross-links).

---

## §8 — Source truth: lifecycle dates

### 8.1 A new claim class

`references/source-truth.md` §2's table gains a twelfth row:

| Claim type | Where to verify in code |
|---|---|
| **Lifecycle dates and milestones** (end-of-life, end-of-support, shutdown, sunset, availability dates) | UI notice strings and banner constants, announcement/config expiry values, feature-flag sunset metadata, sibling announcement pages that already carry the date |

An EOL date is among the highest-stakes customer-facing claims a docs page can
make, and today nothing verifies it. A date matches none of the eleven existing
classes — it is not an enum, a UI label or button, a menu path, a default, a
feature flag, an API shape, a validation rule, a concurrency rule, a permission
gate, a headline count, or a command.

### 8.2 The equivalence rule

Attached to the class, and load-bearing:

> Compare the **milestone the date denotes, not its surface form.** "EOY 2027",
> "end of 2027", "December 31, 2027", and "stops working on January 1, 2028" all
> denote one boundary and are **not** a discrepancy. A discrepancy exists only
> when the milestones genuinely differ — for example "EOL by mid-2027" against
> "stops working on January 1, 2028".

Without this rule the class would be a false-positive generator: dates have more
semantically equivalent phrasings than any other claim type, and a verifier that
compares strings would flood Phase 5.8 with non-discrepancies and train users to
dismiss the table.

### 8.3 Widening §7.5's bug-report trigger

`references/source-truth.md` §7.5 currently emits the
`<KEY>-implementation-gaps.md` draft for `document-as-spec` and
`skip-and-report`. It gains `document-as-code`, conditionally.

§1 already names two sub-cases behind that decision: the implementer found extra
value, or *"the intended phrasing was simplified for stakeholder consumption."*
Those are different. The stated test:

> Emit a gap when the Jira phrasing asserts a **specific value that contradicts**
> the source. Skip when it is vague or non-committal — a Jira saying "several
> registries" where the source has four is loose, not wrong.

The judgment is resolved toward over-inclusion: the output is a draft file the
user reviews, so a spurious entry costs a paragraph, while a miss leaves a wrong
customer-facing claim in the ticket indefinitely.

The gap format gains a third `Docs status` value —
*"documented as shipped; the source ticket carries an incorrect claim"* — and a
matching `Suggested action` that says correct the source ticket, rather than file
a defect against the implementation team.

**Honest caveat, recorded so it is not re-derived:** the incident this item was
filed against is not an instance of it. The feedback file cites Jira's "EOY 2027"
against the shipped UI's "shut down on January 1, 2028" as a factual error; those
are the same milestone, and §8.2's rule correctly declines to flag it. The
widening stands on the general case, not on that example, and the example is not
cited as motivation anywhere in the shipped reference.

---

## §9 — Reviewer dimensions: 16 → 17

`agents/doc-reviewer.md` carries a dimension table (`:41-58`) and a matching set
of output headings (`:75-123`), plus the rule at `:140` — *"NEVER invent new
review dimensions beyond the ones listed."* B1's final review caught the table
and the output slots drifting apart; they stay in lock-step here.

| Dimension | Change |
|---|---|
| **Page structure conventions** | **New.** Callout scope (§4) and component-pattern fidelity (§5), checked against `doc-structure-conventions.md` §2–§3. |
| 5 — Structural integrity | Extends to anchor form and the `validate-anchors` contract (§7). It already owns headings and internal links. |
| 9 — Screenshots | Extends to swap completeness (§6.6). |
| 12 — Source traceability | **Inverts** (§2): a Jira key or PR URL in the rendered page is a MAJOR. |

Seventeen dimensions, seventeen output slots.

---

## §10 — Files and repos

### Canonical — `/workspace/ihudak-claude-plugins/plugins/dev-workflows/`

**New references (2)**

- `references/doc-structure-conventions.md` — §1 traceability boundary, §2
  callout scope, §3 component-pattern fidelity
- `references/dynatrace-docs/anchor-conventions.md`

**Modified references (5)**

- `references/dynatrace-docs/docs-profile-schema.md` — `announcement_pages`,
  `images.policy` immutability
- `references/dynatrace-docs/docs-profile.default.yml` — the three dynatrace
  announcement pages, `images.policy` immutability
- `references/gate-ledger.md` — §4 registry row `image_review`, **and** the §4
  direct-mode carve-out paragraph (three registered, four never-appearing)
- `references/source-truth.md` — §2 lifecycle-date class + equivalence rule,
  §7.5 trigger and gap format
- `references/finish-and-handoff.md` — drop the `Agent 3 (CLAUDE.md)` clause

**Agents (4)**

- `agents/doc-location-finder.md` — exclusion rule rewording,
  `announcement_pages` consumption, `target_spaces` + `profile` inputs
- `agents/doc-planner.md` — two exclusion mirrors, `component_patterns`,
  existing-image candidates, callout placement, reference citations
- `agents/doc-writer.md` — traceability inversion, structure conventions, image
  swap + CDN immutability, anchor conventions
- `agents/doc-reviewer.md` — 17 dimensions and 17 output slots

**Commands (2)**

- `commands/document.md` — Jira mode: Phase 1 wording, Phase 5.5 inputs, Phase
  5.6 two lists, Phase 6.1 note, Phase 8 propose mode, Phase 8.5 clause, new
  Phase 8.6, Phase 9 sections. Direct mode: Phase 4 propose mode, new Phase 4.5,
  Phase 5 sections
- `commands/docs-profile.md` — discover `announcement_pages`

**Manifests and docs (5)**

- `README.md`
- `CHANGELOG.md`
- `.claude-plugin/plugin.json` → **2.44.0**
- `.claude-plugin/marketplace.json`
- root `CLAUDE.md` — the two new references in the source-truth reference list

### mgd — `/workspace/mgd-claude-plugins/`

Content-verbatim port at **2.44.0**, its 5 identity files excluded, including
its own `.claude-plugin/marketplace.json`.

### copilot — `/workspace/ihudak-copilot-plugins/`

Adapted layout and dialect at **2.14.0**, including its own
`.claude-plugin/marketplace.json` and **`.github/copilot-instructions.md`**.

> The two marketplace catalogs and `copilot-instructions.md` are named
> explicitly because all three were missed in the 2.42.0 port.

---

## Verification evidence

Every number in this design was measured against the mounted repos on
2026-08-10, not taken from the feedback report.

| Claim | Measured |
|---|---|
| Announcement pages are hand-authored | `git log` on `end-of-life-announcements.md` — human PRs (`MGD-13397`, `NOISSUE OneAgent EOL updates`) |
| Three cross-cutting destination pages | `whats-new/technology/` — postids `end-of-life`, `eos-announcements`, `new-technology-support` |
| The content-type discriminator is incomplete | 182 `release-notes` vs 10 other under `whats-new/`; `end-of-support-news.md` has no `content-type` |
| Multi-anchor is unsupported | 1,580 files with `{:#id}`; **0** occurrences of `{:#a #b}` across both spaces |
| Anchor link forms | 19,560 `](postid#anchor)`; 4,006 `](#anchor)`; 698 `{{#tabgroup … anchor=`  |
| Tabgroup is the area's pattern | 4 of 5 pages in `guides/container-registries/`; 49 files nest a tabgroup in an ordered-list step |
| No machine-readable `CLAUDE.md` gate exists | no CODEOWNERS; `reviewer.config.json` scopes the bot to `dynatrace/` |
| `{{#tabgroup}}` is already documented in-repo | docs repo `CLAUDE.md:43` |

---

## Out of scope

- **C — git completeness.** `/create-vi` offers git in Phase 5, then Phases 6
  and 7 write `resume.md`, cost, and feedback files into the same folder, while
  `feedback-emission.md` and `cost-emission.md` both say "NEVER commits". Late
  artifacts are untracked by construction, across roughly eight commands.
- **D — mechanical.** Namespace next-step suggestions as
  `/dev-workflows:<command>` (a bare `/release-notes` invokes a colliding
  command from another plugin), and refresh the README and workflow diagram to
  cover `/update-vi` and `/idea --deep`.
- **The `references/` index.** `references/` holds 37 entries with no README or
  index, and this design adds two more. Discovery is getting worse, but every
  reference here is reached by an explicit `${CLAUDE_PLUGIN_ROOT}` citation at
  its point of use, so nothing in B2 depends on fixing it.
- **Generalizing `announcement_pages` beyond deprecation kinds.** The block is
  deliberately keyed on change kinds the run already knows. Inferring arbitrary
  cross-cutting destinations is a larger retrieval problem and no feedback item
  asks for it.
- **Automating CDN asset deprecation.** Superseding an image on the CDN is a
  manual user action outside the repo. The plugin surfaces the swap and stops
  there.

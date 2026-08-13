# `/document` Authoring and Placement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the eight `/document` authoring and placement defects from PRODUCT-17012 — wrong deprecation destination, provenance noise in rendered pages, governance-file edits riding the docs commit, detached callouts, stale screenshots, ad-hoc structure, undocumented anchors, and an unverified lifecycle-date claim class — across all three plugin editions.

**Architecture:** Two new reference docs own the new rules; the four `/document` agents and the command cite them rather than restating them. Destination discovery moves from a directory-prefix ban to a profile-declared allowlist with a content-type heuristic fallback. Phase 8's knowledge and instructions agents split into propose and apply modes so a `CLAUDE.md` edit can never enter the docs commit.

**Tech Stack:** Claude Code plugin markdown (prompt content + JSON manifests). No build, no test framework — verification is `grep`, `diff`, and reading.

**Spec:** `docs/superpowers/specs/2026-08-10-document-authoring-placement-design.md` (commit `e3d23c2`). Section references below (`§1.2`, `§6.5`, …) point at it.

## Global Constraints

- **Versions:** canonical + mgd `dev-workflows` → **2.44.0**; copilot → **2.14.0**. No other plugin's version moves.
- **mgd parity:** `plugins/dev-workflows/` is byte-identical to canonical except exactly five identity files — `.claude-plugin/plugin.json`, `CHANGELOG.md`, `LICENSE`, `README.md`, `references/dependencies.md` — plus the repo-root `.claude-plugin/marketplace.json`.
- **Copilot dialect:** never emit `${CLAUDE_PLUGIN_ROOT}` or `subagent_type` into the copilot edition. References live at `skills/_shared/…`; commands are `skills/<name>/`. Its catalog is `.github/plugin/marketplace.json` and its version file is `dev-workflows/.plugin/plugin.json`.
- **Reference citation idiom:** inside **agent** and **skill** bodies use `${CLAUDE_PLUGIN_ROOT}/references/…`. It does **not** expand in slash-command bodies — `commands/*.md` describes the reference by path in prose instead. Match whatever the file you are editing already does.
- **One row per gate, created once** (`references/gate-ledger.md` §3). A second row for one gate id is a defect.
- **`doc-reviewer` dimension table and output slots move in lock-step.** Never add a dimension without its `#### ` output heading, and never exceed the listed set (`agents/doc-reviewer.md:140`).
- **Choice lists are verbatim.** A phase's `choices:` array — order, wording, `(Recommended)` marker — is not the orchestrator's to reword (`references/escalation-rules.md`).
- **Surgical changes.** Removing a field, phase, or rule means removing every cross-reference to it in the same task.
- **Line wrapping:** match the surrounding file. Reference and command files in this repo are hard-wrapped near 100 columns; do not reflow untouched paragraphs.

> **On inline `# expect N` values below:** they were derived on 2026-08-10 against the tree at `7f02770`. If your actual count differs, **report the mismatch with your reasoning — do NOT edit content to satisfy the number.** In the previous round implementers were right about this six times out of six.
>
> **Corrected 2026-08-13 (R39, whole-round-review-fixes Task 13).** `7f02770` predates B2's own commits, so several inline expectations went stale by ship time (`25b3628`, the last B2-content commit before the next sub-project began). 8 discrepancies were re-derived against `25b3628` (canonical), `8bc8862` (mgd), and `c25eab7` (copilot) and are annotated in place at their respective checks below: **2 WRONG** (a number that was simply stale — corrected to the true value) and **6 WRONG-TARGET** (a check that, by construction of its own pattern, could never have produced its stated expectation on any tree — annotated with the reason rather than given an invented number). This is a different split than the design spec's "6 wrong + 2 wrong-target" estimate for R39; the total item count (8) matches, the wrong/wrong-target ratio does not — reported per this task's own instruction to trust re-derivation over the brief.

---

## File Structure

**Canonical — `plugins/dev-workflows/`**

| File | Responsibility | Task |
|---|---|---|
| `references/doc-structure-conventions.md` | NEW. Traceability boundary, callout scope, component-pattern fidelity. | 1 |
| `references/dynatrace-docs/anchor-conventions.md` | NEW. Heading anchors, link forms, `validate-anchors`, `dt-url` reconciliation. | 2 |
| `references/dynatrace-docs/docs-profile-schema.md` | `announcement_pages` block; CDN immutability on `images.policy`. | 3 |
| `references/dynatrace-docs/docs-profile.default.yml` | The three dynatrace announcement pages; CDN immutability. | 3 |
| `commands/docs-profile.md` | Discover `announcement_pages` when profiling a repo. | 3 |
| `agents/doc-location-finder.md` | Exclusion rewording, announcement consumption, `target_spaces` + `profile` inputs. | 4 |
| `agents/doc-planner.md` | Ban mirrors (4); traceability citation (5); `component_patterns` + callout placement + existing-image candidates (6). | 4, 5, 6 |
| `agents/doc-writer.md` | Traceability inversion (5); structure conventions + image swap + anchors (6). | 5, 6 |
| `commands/document.md` | Finder inputs (4); changelog citation (5); image phase (7); Phase 8 split (11). | 4, 5, 7, 11 |
| `references/gate-ledger.md` | `image_review` row **and** the direct-mode carve-out. | 8 |
| `references/source-truth.md` | Lifecycle-date claim class, equivalence rule, §7.5 widening. | 9 |
| `agents/doc-reviewer.md` | All four dimension changes, 16 → 17. | 10 |
| `references/finish-and-handoff.md` | Drop the `Agent 3 (CLAUDE.md)` clause. | 11 |
| `README.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, root `CLAUDE.md` | Release surface. | 12 |

**mgd** — same tree, task 13. **copilot** — adapted tree, task 14.

Tasks 1–2 create the authorities. Tasks 3–9 and 11 wire consumers. Task 10 makes every reviewer change in one place so the 17 ↔ 17 invariant lives in one implementer's head. Tasks 12–14 release.

---

### Task 1: `doc-structure-conventions.md`

**Files:**
- Create: `plugins/dev-workflows/references/doc-structure-conventions.md`

**Interfaces:**
- Produces: a reference with three numbered sections — `## 1. The traceability boundary`, `## 2. Callout scope and adjacency`, `## 3. Component-pattern fidelity`. Tasks 5, 6, and 10 cite these by number, so the numbering is a contract.

- [ ] **Step 1: Read the source sections**

Read `docs/superpowers/specs/2026-08-10-document-authoring-placement-design.md` §2, §4, and §5. They carry the full rationale; this file carries the rules.

- [ ] **Step 2: Write the file**

Open with a one-paragraph scope statement: this reference is **repo-agnostic** — it governs how a written page is structured and what it may contain, for any docs repo. Repo-specific conventions live in `references/dynatrace-docs/`.

`## 1. The traceability boundary` must state, verbatim as the normative rule:

> **The rendered page carries no source provenance.** Jira keys, PR URLs, and `<!-- KEY: … -->` HTML comments belong in the commit message and in the run's handoff — never in body prose, never in a changelog entry, never as a comment in the markdown.

Follow it with the three-tier table (Rendered page → the customer-facing claim only; Commit message → the Jira key and summary per `profile.commit_convention`; Run handoff / final report → per-claim attribution to Jira keys and PR URLs).

Close §1 with the exception, stated as an exception so no later reader treats it as a contradiction: `source-truth.md` §7.6's `<!-- intentional-discrepancy: … -->` marker is a deliberate, user-decided flag on a spec-vs-code gap, not provenance, and is unaffected by this rule.

`## 2. Callout scope and adjacency` states the three rules from §4 — with-the-member placement; whole-set callouts in the lead-in **before** the options; explicit scope naming in the first clause where placement alone could mislead. Include the worked example: an ARM limitation specific to a built-in *cluster* registry, placed after a four-option list, reads as a constraint on a customer-owned private registry where it is false. State the reviewer severity: **MAJOR**, because a misread scope changes what the customer believes is required or prohibited.

`## 3. Component-pattern fidelity` states the rule (sample the surrounding content area; reuse the dominant component for a matching content shape; never invent an ad-hoc structure where a sibling pattern exists), the `component_patterns` block shape from §5, and the reviewer severity: **MINOR**, because an ad-hoc structure still renders. Say explicitly that `shape` is an **open vocabulary** — the planner names what it observes — and that mutually-exclusive option sets, collapsible detail, and tabular reference are seed examples, not the permitted set. Say explicitly that **no component list is vendored**; the evidence comes from the repo in front of it.

- [ ] **Step 3: Verify structure**

```bash
cd plugins/dev-workflows
grep -c '^## [123]\. ' references/doc-structure-conventions.md      # expect 3
grep -n 'no source provenance' references/doc-structure-conventions.md   # expect 1 hit
grep -n 'intentional-discrepancy' references/doc-structure-conventions.md # expect >=1
grep -n 'MAJOR\|MINOR' references/doc-structure-conventions.md      # expect both present
grep -c 'CLAUDE_PLUGIN_ROOT' references/doc-structure-conventions.md # expect 0 or citations only
```

Confirm by reading: nothing in the file names dynatrace, `{{#tabgroup}}`, or `{{#callout}}` as a required component. Those may appear only as illustrative examples clearly marked as such.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/references/doc-structure-conventions.md
git commit -m "feat(dev-workflows): add doc-structure-conventions reference"
```

---

### Task 2: `dynatrace-docs/anchor-conventions.md`

**Files:**
- Create: `plugins/dev-workflows/references/dynatrace-docs/anchor-conventions.md`

**Interfaces:**
- Produces: a repo-specific reference cited by `doc-writer`, `doc-reviewer` (dimension 5), and `doc-planner`.

- [ ] **Step 1: Write the file**

Read spec §7. Mirror the house style of its siblings (`frontmatter-guidelines.md`, `multi-space-writing.md`): `# ` title, numbered `## ` sections, tables for enumerable facts.

The file must carry these four facts, each with its evidence, because the point of the reference is that no run re-derives them:

1. **One `{:#id}` per heading.** 1,580 files under `dynatrace/_content` + `managed/_content` use single-anchor syntax; multi-anchor `{:#a #b}` appears **0 times**. Multi-anchor is unsupported.
2. **Link forms** — a table: `[text](<postid>)` whole page; `[text](<postid>#<anchor>)` cross-page section (19,560 uses); `[text](#<anchor>)` same-page (4,006 uses); `{{#tabgroup anchor='id'}}` mints an anchor on a tab group (698 uses).
3. **Tooling** — `pnpm docstack validate-anchors`, described as *"Validate if anchors point to hardcoded ids."* An anchor link must target a hardcoded `{:#id}`, not a generated one.
4. **Reconciling a product `dt-url` deep link** — when shipped product code deep-links to `#some-anchor`, the page's authored anchor matches the product's, because the product is the harder side to change and ships on its own cycle. If it cannot match, the mismatch goes through the normal Phase 5.8 discrepancy path. State the anti-pattern by name: it is **not** deferred on an in-session judgment that the syntax "appears unsupported".

- [ ] **Step 2: Verify**

```bash
cd plugins/dev-workflows
grep -n '1,580\|1580' references/dynatrace-docs/anchor-conventions.md   # expect the evidence count present
grep -n 'validate-anchors' references/dynatrace-docs/anchor-conventions.md # expect >=1
grep -n 'dt-url' references/dynatrace-docs/anchor-conventions.md        # expect >=1
grep -c '19,560\|19560' references/dynatrace-docs/anchor-conventions.md # expect >=1
```

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/dynatrace-docs/anchor-conventions.md
git commit -m "feat(dev-workflows): add dynatrace-docs anchor-conventions reference"
```

---

### Task 3: `announcement_pages` and CDN immutability in the profile

**Files:**
- Modify: `plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md:57-68`
- Modify: `plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml`
- Modify: `plugins/dev-workflows/commands/docs-profile.md`

**Interfaces:**
- Produces: `profile.announcement_pages` — a list of `{postid, path, kinds}`. Task 4's `doc-location-finder` consumes it. `path` is authoritative when `path` and `postid` disagree; `postid` alone suffices when the repo's link convention is postid-based.
- Produces: the CDN immutability sentence, consumed verbatim by Task 6's `doc-writer` edit.

- [ ] **Step 1: Add the schema block**

In `docs-profile-schema.md`, add an `announcement_pages` block. It sits after `internal_links:` (line 57) and before `branch_naming:` (line 59). Document it as: hand-authored destination pages that receive a given class of change regardless of where the feature itself is documented — typically inside a tree that is otherwise automation-owned. Each entry is `{postid, path, kinds}`; `kinds` is an open list of change kinds. Optional: a repo without announcement pages omits the block.

- [ ] **Step 2: Add CDN immutability to the schema**

At `docs-profile-schema.md:66-67`, extend the `images.policy` description with:

> A CDN URL is immutable. Every new or replacing screenshot is a new URL, and the docs edit is always a URL swap. An image is never refreshed in place.

- [ ] **Step 3: Populate the default profile**

In `docs-profile.default.yml`, add between `internal_links:` and `branch_naming:`:

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

Extend the `images:` block's `policy:` string with the same immutability sentence from Step 2.

- [ ] **Step 4: Teach `/docs-profile` to discover the block**

In `commands/docs-profile.md`, add a discovery step to the scan: find hand-authored pages inside otherwise automation-owned trees. The detection signal is a page under a release-notes/what's-new tree whose frontmatter does **not** carry `meta.content-type: release-notes` and whose `git log` shows human PR commits. Record `postid`, `path`, and proposed `kinds` inferred from the page title and headings. Emit `announcement_pages: []` when none are found.

- [ ] **Step 5: Verify**

```bash
cd plugins/dev-workflows
grep -n 'announcement_pages' references/dynatrace-docs/docs-profile-schema.md \
  references/dynatrace-docs/docs-profile.default.yml commands/docs-profile.md   # expect >=1 each
grep -c 'postid: ' references/dynatrace-docs/docs-profile.default.yml           # expect 3
grep -n 'immutable' references/dynatrace-docs/docs-profile-schema.md \
  references/dynatrace-docs/docs-profile.default.yml                            # expect 1 each
python3 -c "import yaml,sys; d=yaml.safe_load(open('references/dynatrace-docs/docs-profile.default.yml')); \
print(len(d['announcement_pages'])); print(sorted(k for e in d['announcement_pages'] for k in e['kinds']))"
# expect 3, and 6 kinds: deprecation end-of-life end-of-support new-technology shutdown sunset
```

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/references/dynatrace-docs/ plugins/dev-workflows/commands/docs-profile.md
git commit -m "feat(dev-workflows): announcement_pages in docs-profile + CDN immutability"
```

---

### Task 4: Destination discovery

**Files:**
- Modify: `plugins/dev-workflows/agents/doc-location-finder.md:13-17` (Inputs), `:42` (rule 5)
- Modify: `plugins/dev-workflows/agents/doc-planner.md:44`, `:201`
- Modify: `plugins/dev-workflows/commands/document.md:409-418` (Phase 5.5 invocation)

**Interfaces:**
- Consumes: `profile.announcement_pages` from Task 3.
- Produces: `doc-location-finder`'s input contract becomes five fields — `repo_root`, `feature_summary`, `diff_highlights`, `target_spaces`, `profile`.

- [ ] **Step 1: Extend the input contract**

`doc-location-finder.md:13-17` currently reads:

```yaml
repo_root:         <absolute path to docs repo root>
feature_summary:   <2–4 sentences from jira-reader themes + VI goal>
diff_highlights:   <optional: key filenames / code areas from diff-summarizer outputs to seed topical search>
```

Add two fields:

```yaml
target_spaces:     <optional: the space ids this run writes to; when non-empty, propose targets only under those spaces' content_root>
profile:           <optional: the resolved docs profile; its announcement_pages block declares hand-authored destinations>
```

Leave the refuse-to-run line unchanged — both new fields are optional, and a run without them behaves as today apart from the reworded rule below.

- [ ] **Step 2: Rewrite the exclusion rule**

Replace the final sentence of `doc-location-finder.md:42` — the one beginning `NEVER propose a What's New / release-notes path` — with the rule below. Keep the rest of point 5 (multiple natural homes, `linked_from`) intact.

> NEVER propose an automation-generated path as a target: a page whose frontmatter carries `meta.content-type: release-notes`, anything under `_data/release-notes/…`, and anything under `_snippets/release-notes/…`. Those are generated from Jira by automation and a manual write would be overwritten; release notes are produced by the `/release-notes` command. **A page declared in `profile.announcement_pages` is exempt** — announcement pages are hand-authored and nothing generates them.

- [ ] **Step 3: Add announcement-page consumption**

Add a new numbered point to the same Process list, after point 5:

> 6. **Propose the declared announcement page when the change kind matches.** Derive the run's change kinds from `feature_summary` — a deprecation, end-of-life, shutdown, sunset, end-of-support, or new-technology-support signal in the ticket reaches you there; no other input is needed. When a derived kind appears in an entry's `kinds`, emit that entry's page as an **additional** target — never as a replacement for the feature-subtree targets, because the announcement belongs on the announcement page *and* a pointer belongs where the feature is documented. Resolve the page by `path` when present, else by `postid`. Zero matching kinds means the block is not consulted and nothing is emitted or logged. Absent `profile.announcement_pages`, fall back to the Step 2 exclusion set alone and let the topical index reach the page on its own.

- [ ] **Step 4: Update the two `doc-planner` mirrors**

`doc-planner.md:44` (a parenthetical in the topics list) and `:201` (a hard rule) both restate the old ban. Rewrite each to match Step 2's exclusion set and carry the `announcement_pages` exemption. Do not simply delete them — both are load-bearing where they sit.

- [ ] **Step 5: Pass the new inputs**

In `commands/document.md`, the Phase 5.5 invocation block (lines 409-418) passes three fields. Add the two new ones:

```
  > target_spaces:   [the resolved target_spaces, or omit for an unconstrained run]
  > profile:         [the resolved profile — its announcement_pages block]
```

- [ ] **Step 6: Verify**

```bash
cd plugins/dev-workflows
grep -c 'announcement_pages' agents/doc-location-finder.md    # expect >=3
grep -n 'target_spaces' agents/doc-location-finder.md         # expect >=2 (contract + rule)
grep -rn "NEVER propose a What's New" agents/ commands/       # expect 0 hits — old wording gone everywhere
grep -rn 'content-type: release-notes' agents/doc-location-finder.md agents/doc-planner.md  # expect 3 (finder + 2 planner mirrors)
grep -n 'target_spaces' commands/document.md | sed -n '1,3p'  # confirm the Phase 5.5 block now passes it
```

Read `agents/doc-planner.md:44` and `:201` side by side and confirm they state the same exclusion set. Divergent mirrors are the exact defect this task exists to fix.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/agents/doc-location-finder.md plugins/dev-workflows/agents/doc-planner.md plugins/dev-workflows/commands/document.md
git commit -m "fix(dev-workflows): announcement pages are a valid /document target"
```

---

### Task 5: The traceability boundary

**Files:**
- Modify: `plugins/dev-workflows/agents/doc-writer.md:63` (rewrite), `:54` (cite)
- Modify: `plugins/dev-workflows/agents/doc-planner.md:51`, `:188` (cite)
- Modify: `plugins/dev-workflows/commands/document.md:1002` (cite)

**Interfaces:**
- Consumes: `references/doc-structure-conventions.md` §1 from Task 1.
- Note: `doc-reviewer`'s dimension 12 is **not** touched here. Every reviewer change lands in Task 10.

- [ ] **Step 1: Rewrite the writer's traceability step**

`doc-writer.md:63` currently reads:

> 6. **Traceability** — every claim must cite the originating Jira key (e.g. `[[<JIRA_KEY>]]`) and/or PR URL inline. When a claim comes only from imported Jira content (no PR resolved), cite the Jira key alone.

Replace it with a step that states the inverse and cites the authority:

> 6. **Traceability** — follow `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §1. The rendered page carries the customer-facing claim only: NEVER write a Jira key, a `[[wikilink]]`, a PR URL, or a `<!-- KEY: … -->` comment into body prose, a heading, or a changelog entry. `[[wikilink]]` syntax is an Obsidian-vault convention and renders as literal text in a product docs repo. Per-claim attribution to Jira keys and PR URLs goes in your return payload, and the commit message carries the Jira key. The one exception is §7.6's `<!-- intentional-discrepancy: … -->` marker, which is a user-decided gap flag, not provenance.

- [ ] **Step 2: Turn the three changelog restatements into citations**

Each of these independently restates the boundary. Replace each restatement with a short citation of `doc-structure-conventions.md` §1, keeping the surrounding instruction intact:

- `doc-writer.md:54` — *"and **no Jira key** — traceability lives in the commit message, not the reader-visible page"*
- `doc-planner.md:51` — *"The Jira reference is carried by the commit message and the file diff, not by the reader-visible page (verified against the repo convention — fewer than 5 of dynatrace-docs's 5500+ entries cite an issue key)."* Keep the measured evidence; replace only the restated rule.
- `doc-planner.md:188` — *"The changelog is reader-visible "what changed on this page" prose; traceability is the commit message's job."*
- `commands/document.md:1002` — *"NEVER put the Jira key in a reader-visible changelog — the commit message carries traceability."* This is a command body: `${CLAUDE_PLUGIN_ROOT}` does not expand here, so cite the reference by plain path.

The prohibition itself stays at each site — a reader must not have to open the reference to learn that a Jira key is banned. What goes away is four independent *justifications* of the same rule.

- [ ] **Step 3: Verify**

```bash
cd plugins/dev-workflows
grep -n 'every claim must cite the originating Jira key' agents/doc-writer.md  # expect 0 — old rule gone
grep -c 'doc-structure-conventions' agents/doc-writer.md agents/doc-planner.md commands/document.md  # expect >=1 each
grep -n 'wikilink' agents/doc-writer.md                                        # expect >=1 (the new prohibition)
grep -n 'intentional-discrepancy' agents/doc-writer.md                         # expect >=2 — §7.6 path intact
```

Read `doc-writer.md` steps 5 through 7 end to end and confirm no remaining instruction asks for an inline citation in the page.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/agents/doc-writer.md plugins/dev-workflows/agents/doc-planner.md plugins/dev-workflows/commands/document.md
git commit -m "fix(dev-workflows): rendered pages carry no source provenance"
```

---

### Task 6: Callout scope, component patterns, existing-image candidates

**Files:**
- Modify: `plugins/dev-workflows/agents/doc-planner.md` — step 5 (image policy, lines 68-78), step 6 (screenshot placement, lines 80-86), the output block (around line 129)
- Modify: `plugins/dev-workflows/agents/doc-writer.md` — step 5 (place screenshots, lines 57-62), plus a new structure step

**Interfaces:**
- Consumes: `references/doc-structure-conventions.md` §2–§3 (Task 1); `references/dynatrace-docs/anchor-conventions.md` (Task 2); the CDN immutability sentence (Task 3); `existing_image_decisions[]` from Task 7 (writer side only).
- Produces, in the `doc-planner` output block, consumed by Task 10's reviewer:

```yaml
component_patterns:                 # [] when the sample shows no established pattern
  - shape: mutually-exclusive-options
    component: "{{#tabgroup}} / {{#tab title='…'}}"
    evidence: "guides/container-registries/use-public-registry.md:176"
    count: 4
```

> **The planner does NOT collect existing images.** It runs at Phase 5.7, *after* the 5.6 image phase, so it cannot be the source of a list 5.6 must present. The orchestrator builds that list at 5.6 from the `write_targets` it already holds (Task 7). Do not add a second collector here — one list, one owner.

- [ ] **Step 1: Extend the planner's sibling scan to component patterns**

`doc-planner.md` step 5 already samples 5–10 sibling markdown pages under the target's folder plus up to 3 ancestor folders, to classify image policy. Give that **same sample** a second job, added as a sub-step rather than a new scan: record which content component the area uses for each recurring content shape, and emit `component_patterns` in the shape above. Cite `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §3 as the authority. State that `shape` is an open vocabulary the planner names from observation, and that `component_patterns: []` is the correct output when the sample shows no established pattern.

- [ ] **Step 2: Add callout placement to the planner**

In the planner's per-target section planning, add the rule from `doc-structure-conventions.md` §2: when a planned section presents mutually exclusive options, plan each option's callouts adjacent to that option, and plan whole-set callouts into the lead-in before the options. Cite the reference; do not restate its three rules in full.

- [ ] **Step 3: Wire the writer**

In `doc-writer.md`:

- Add a structure step citing `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §2–§3: place callouts adjacent to what they qualify, and reuse `component_patterns`' dominant component for a matching content shape instead of inventing a structure.
- Add `existing_image_decisions` to the writer's Inputs list, described as: accepted stale-image replacements from Phase 5.6/6.1, each `{target, occurrence, old_url, new_url}`.
- Extend step 5 (place screenshots) to handle a **swap**: for each accepted `existing_image_decisions` entry, replace that specific occurrence in place, leaving other occurrences of the same URL untouched — an unaccepted occurrence may render in a space the change does not affect. Add the CDN immutability sentence from Task 3 verbatim.
- Add an anchors line citing `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/anchor-conventions.md` for authored heading anchors and internal-link forms.

- [ ] **Step 4: Verify**

```bash
cd plugins/dev-workflows
grep -c 'component_patterns' agents/doc-planner.md          # expect >=2 (process + output block)
grep -c 'existing_images' agents/doc-planner.md             # expect 0 — the planner does NOT collect these
grep -c 'existing_image_decisions' agents/doc-writer.md     # expect >=2 (inputs + step 5)
grep -c 'doc-structure-conventions' agents/doc-planner.md agents/doc-writer.md   # expect >=2 each
grep -n 'anchor-conventions' agents/doc-writer.md           # expect 1
grep -n 'immutable' agents/doc-writer.md                    # expect 1
grep -n 'Sample 5–10 sibling' agents/doc-planner.md         # expect 1 — one scan, not two
```

That last check matters: the component scan must be folded into the existing sibling sample. A second independent scan doubles the planner's read cost for no gain.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/doc-planner.md plugins/dev-workflows/agents/doc-writer.md
git commit -m "feat(dev-workflows): callout scope, component-pattern fidelity, stale-image candidates"
```

---

### Task 7: The image phase

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md:193-197` (Phase 1 question), `:441-480` (Phase 5.6), `:644-676` (Phase 6.1)

**Interfaces:**
- Consumes: `write_targets` from Phase 5.5, which the orchestrator already holds at 5.6.
- Produces: `image_review` ledger-gate outcomes (Task 8), and the handoff block below — read by Task 6's writer and Task 10's reviewer:

```yaml
existing_image_decisions:           # [] when nothing was listed or nothing accepted
  - target: dynatrace/_content/.../quickstart/index.md
    occurrence: 1                   # 1-based index of this image reference within the target
    old_url: https://dt-cdn.net/images/quickstart-2nd-gen-2976-cd3bfad512.png
    new_url: https://dt-cdn.net/images/quickstart-k8s-new-2902-88300e3cd7.png
    section: "Connect automatically via Dynatrace Operator"
    gating: "{{#if project='saas'}}"   # or: none
    decision: accepted                # or: declined
```

> **The orchestrator owns this list — the planner does not.** `doc-planner` runs at Phase 5.7, after this phase, so it cannot supply a list 5.6 must present. The orchestrator builds it here by reading the `extend-existing` write targets it already has. Do not add a planner-side collector; one list, one owner.

- [ ] **Step 1: Reword the Phase 1 question**

Lines 193-197 currently gate the whole image phase on one answer. Rewrite so the question seeds the add-list only and never skips Phase 5.6. The choice list becomes:

```
choices: ["Yes — I have new screenshots to add (you'll pick the sources in Phase 5.6) (Recommended)", "No new screenshots", "Cancel", "Other… (describe)"]
```

Record the answer as `new_images_wanted`. Replace the sentence *"When `false`, Phase 5.6 is skipped and `screenshots[]` stays empty"* with: when `false`, Phase 5.6 skips its **add** list only and still reviews existing images on the edited pages.

Grep for every other use of `images_wanted` in the file and update each — a renamed variable with a stale reader is a silent skip.

- [ ] **Step 2: Make Phase 5.6 two-list**

Retitle the phase from `Image candidates` to `Images` and state that it always runs. Keep the four existing add-list sources unchanged.

Add the second list. Build it by reading each `extend-existing` write target from Phase 5.5 and recording every image reference — **one row per occurrence, not per unique URL**, because the same URL can appear more than once under different space gating and each occurrence is decided separately. For each, record `target`, `occurrence`, `old_url`, the enclosing section heading, and `gating` (the enclosing `{{#if project='…'}}` conditional, or `none`). The gating matters: in the PRODUCT-17012 run one URL appeared in both a `saas`-gated and a `managed`-gated block, and the SaaS one renders where the feature does not exist.

Present both lists in one prompt. The choice list:

```
choices: ["Review both lists item by item (Recommended)", "Add-list only — existing images are current", "Nothing to do — no image work this run", "Cancel", "Other… (describe)"]
```

State that an accepted item — from either list — carries into Phase 6.1 for its CDN URL, and that the outcome is recorded as `existing_image_decisions[]` (schema in this task's Interfaces block) and carried in the Phase 6.3 handoff file alongside `cdn_urls`.

- [ ] **Step 3: Append the ledger row**

Immediately after the user answers, append the `image_review` row (schema: `references/gate-ledger.md` §3; registry: §4, added in Task 8). `RAN` when items were reviewed; `SKIPPED_BY_USER` with the user's verbatim choice when they declined; `NOT_APPLICABLE` naming the unmet precondition when neither list has any candidate.

**Append it outside any conditional branch.** A row written inside a branch that a clean run skips is the self-blocking defect the previous round hit twice — a missing row is a reviewer BLOCKER, so the correct run blocks itself.

- [ ] **Step 4: Note the swap in Phase 6.1**

Phase 6.1 already collects one CDN URL per image under *"Upload now — I'll paste the CDN links"*. Add one sentence: an item sourced from the existing-image list is a **replacement** — the writer swaps that occurrence's URL rather than inserting a new reference, and the new URL is always a different URL (a CDN URL is immutable). No change to the choice list.

Phase 6.1's run condition currently fires only when a screenshot has `image_policy: cdn_upload_required` or the user chose staging under an `ambiguous` target. Extend it so an accepted existing-image replacement also triggers the phase — otherwise an accepted swap never collects its URL.

- [ ] **Step 5: Carry the decisions in the handoff**

`commands/document.md:700` enumerates the `doc-writer` handoff file's contents. Add `existing_image_decisions` to that list, beside `cdn_urls` and `screenshots`.

- [ ] **Step 6: Verify**

```bash
cd plugins/dev-workflows
grep -c 'images_wanted' commands/document.md          # WRONG-TARGET, see note — not 0
grep -c 'new_images_wanted' commands/document.md      # expect >=3
grep -n 'image_review' commands/document.md           # expect >=1
grep -c 'existing_image_decisions' commands/document.md  # expect >=3 (5.6 schema, 6.1, handoff list)
grep -n '^## Phase 5.6 — Images' commands/document.md # expect 1
awk '/^## Phase 5.6 — Images/,/^## Phase 5.6.5/' commands/document.md | grep -c 'gate_ledger\|image_review'  # expect >=1
```

**Corrected 2026-08-13 (R39):** Line 470's `# expect 0 — fully renamed` is **WRONG-TARGET**, not a wrong number. `images_wanted` is a plain substring match, and the new field name `new_images_wanted` (required `>=3` by the very next line) also contains that substring — so this command can never return 0 while the rename it is checking for is actually present; it structurally contradicts the check on line 471. Re-derived at `25b3628`: `grep -c 'images_wanted'` = 6 lines, `grep -c 'new_images_wanted'` = 6 lines (identical — every hit is the new name), and a word-boundary probe `grep -noE '(^|[^_a-z])images_wanted' commands/document.md` returns **no output**, confirming zero bare/old-name occurrences — the rename genuinely is complete; this specific command just cannot prove it.

Then trace by reading, not grepping: follow the `new_images_wanted: false` path from Phase 1 to Phase 5.6 and confirm it reaches the existing-image list and the ledger append. That path is the entire point of the task, and a grep cannot prove it.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/commands/document.md
git commit -m "feat(dev-workflows): one image phase covering additions and stale replacements"
```

---

### Task 8: The `image_review` gate

**Files:**
- Modify: `plugins/dev-workflows/references/gate-ledger.md:60-90` (§4 registry table **and** the direct-mode carve-out paragraph at `:77-79`)

**Interfaces:**
- Consumes: nothing.
- Produces: registry id `image_review`, appended by Task 7 and checked by Task 10's dimension 13.

> **Both edits belong to this task and neither ships alone.** Adding the registry row without amending the carve-out leaves `image_review` undefined for direct mode while §6 makes a missing row a reviewer BLOCKER — every direct-mode run would then block itself. That is the exact defect the previous round's Task 1 had to repair.

- [ ] **Step 1: Add the registry row**

Append to the §4 table, after `render_smoke_check`:

| Gate id | Phase | Precondition | Primary | Fallback |
|---|---|---|---|---|
| `image_review` | 5.6 | ≥1 candidate image (to add or possibly-stale) | the two-list review with per-occurrence decisions | none |

- [ ] **Step 2: Amend the direct-mode carve-out**

Lines 77-79 currently read:

> **Direct mode** (`/document` Mode B) registers exactly three gates: `toolchain_preflight` (Phase 0), `repo_checklist` (Phase 0 extraction, checked at Phase 3.5), and `style_check` (Phase 3.5). The other three ids never appear in a direct-mode ledger — not even as `NOT_APPLICABLE`:

Change "The other three ids" to "The other **four** ids", and add a fourth bullet to the list beneath it:

> - `image_review` — direct mode has no Phase 5.6 and no planner-sourced image candidates.

- [ ] **Step 3: Add the input-side note**

Add one sentence below the table: `image_review` is an input-side gate rather than an output-verification gate, unlike the other six. It is registered anyway because the accountability need is identical — an unattributed image skip is exactly the failure mode this ledger exists to prevent.

- [ ] **Step 4: Verify**

```bash
cd plugins/dev-workflows
grep -c '^| `' references/gate-ledger.md                    # WRONG-TARGET, see note — not 7
grep -n 'exactly three gates' references/gate-ledger.md     # expect 1 — direct mode still registers 3
grep -n 'other four ids\|other \*\*four\*\* ids' references/gate-ledger.md  # expect 1
awk '/never appear in a direct-mode ledger/,/^## 5\./' references/gate-ledger.md | grep -c '^- `'  # expect 3 bullets (not 4 — corrected 2026-08-13)
```

The registered count (3) and the never-appearing count (4 ids) must sum to 7. If they do not, the carve-out and the registry disagree.

**Corrected 2026-08-13 (R39):**
- Line 526's `grep -c '^| \`' references/gate-ledger.md` is **WRONG-TARGET**, not a wrong number: the file has two markdown tables that both open data rows with `` | ` `` — the §1 outcome-legend table (6 rows: `RAN`/`DEGRADED`/`FAILED`/`UNAVAILABLE`/`SKIPPED_BY_USER`/`NOT_APPLICABLE`) and the §4 registry table (7 rows). The pattern isn't scoped to the registry table, so this exact command returns 13 (6+7) on the ship tree and can never isolate 7 by itself. Read directly (`sed -n '65,71p' references/gate-ledger.md`, at `25b3628`): the registry table genuinely has 7 rows, confirming the intended fact — just not via this command.
- Line 529's `# expect 4 bullets` was **WRONG**: re-derived at `25b3628`, the "other four ids" bullet list has only **3** bullet lines, because `build_check` and `render_smoke_check` share one bullet ("`build_check` and `render_smoke_check` — direct mode has no Phase 6.5..."). 4 ids across 3 bullets — the prose "other **four** ids" is correct, the old "4 bullets" comment conflated ids with bullets.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/gate-ledger.md
git commit -m "feat(dev-workflows): register the image_review gate in both mode carve-outs"
```

---

### Task 9: Lifecycle dates in `source-truth.md`

**Files:**
- Modify: `plugins/dev-workflows/references/source-truth.md:106` (§2 table, append a row), `:440-474` (§7.5)

**Interfaces:**
- Produces: a twelfth §2 claim class and a widened §7.5 trigger. Task 10's dimension 15 already cites §3 generically and needs no change for this.

- [ ] **Step 1: Add the claim class**

Append one row to the §2 table, after the `Commands, CLI invocations…` row at line 106:

| Claim type | Where to verify in code |
|---|---|
| **Lifecycle dates and milestones** (end-of-life, end-of-support, shutdown, sunset, availability dates) | UI notice strings and banner constants, announcement/config expiry values, feature-flag sunset metadata, sibling announcement pages that already carry the date |

- [ ] **Step 2: Add the equivalence rule**

Directly beneath the table, add the rule — it is load-bearing and must not live only in the row:

> **Lifecycle dates compare by milestone, not by surface form.** "EOY 2027", "end of 2027", "December 31, 2027", and "stops working on January 1, 2028" all denote one boundary and are **not** a discrepancy. A discrepancy exists only when the milestones genuinely differ — for example "EOL by mid-2027" against "stops working on January 1, 2028". Dates have more semantically equivalent phrasings than any other claim type; a verifier that compares strings floods Phase 5.8 with non-discrepancies and trains users to dismiss the table.

- [ ] **Step 3: Widen the §7.5 trigger**

§7.5's opening sentence currently triggers on `document-as-spec` or `skip-and-report`. Add `document-as-code`, conditionally, with the test stated explicitly:

> …or `document-as-code` **where the Jira phrasing asserts a specific value that contradicts the source**. Skip a `document-as-code` entry whose Jira phrasing is vague or non-committal — "several registries" against a source with four is loose, not wrong. When the two readings are arguable, emit: the output is a draft the user reviews, so a spurious entry costs a paragraph while a miss leaves a wrong customer-facing claim in the ticket indefinitely.

- [ ] **Step 4: Extend the gap format**

In §7.5's `Format:` block:

- `**Docs status**` gains a third value: `"documented as shipped; the source ticket carries an incorrect claim"`.
- `**Suggested action**` gains the matching variant: for a `document-as-code` gap, correct the source ticket — the implementation is right — rather than filing a defect against the implementation team.

- [ ] **Step 5: Verify**

```bash
cd plugins/dev-workflows
awk '/^## 2\. What MUST be verified/,/^## 3\./' references/source-truth.md | grep -c '^| \*\*'  # expect 12
grep -n 'milestone, not by surface form' references/source-truth.md    # expect 1
grep -n 'document-as-code' references/source-truth.md | head           # expect a hit inside §7.5
awk '/^### 7\.5/,/^### 7\.6/' references/source-truth.md | grep -c 'document-as-code'  # expect >=2
```

Confirm by reading that the "EOY 2027" example appears **only** as a not-a-discrepancy illustration in the equivalence rule. It must never be cited as motivation for the §7.5 widening — it is not an instance of it (spec §8.3).

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/references/source-truth.md
git commit -m "feat(dev-workflows): verify lifecycle dates; widen the bug-report trigger"
```

---

### Task 10: `doc-reviewer` — 16 dimensions to 17

**Files:**
- Modify: `plugins/dev-workflows/agents/doc-reviewer.md:41-58` (dimension table), `:75-123` (output slots), `:22` (inputs)

**Interfaces:**
- Consumes: `doc-structure-conventions.md` §2–§3 (Task 1), `anchor-conventions.md` (Task 2), `component_patterns` (Task 6), `existing_image_decisions` (Task 7), `image_review` (Task 8).
- **Every reviewer change in the project lands here.** No other task edits this file.

- [ ] **Step 1: Add the new dimension**

Insert a `Page structure conventions` row into the table. Its check: callouts sit adjacent to what they qualify, and a content shape with an established sibling pattern in `component_patterns` uses that component. Callout-scope violations are **MAJOR** (a misread scope changes what the customer believes is required or prohibited); component divergence is **MINOR** (an ad-hoc structure still renders). Cite `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §2–§3. Skip with "N/A — no `component_patterns`" when the block is empty; the callout half always applies.

- [ ] **Step 2: Extend dimension 5**

`Structural integrity` (line 47) already owns headings and internal links. Extend its check with anchor form and the `validate-anchors` contract, citing `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/anchor-conventions.md`: a heading carries at most one `{:#id}`; an anchor link targets a hardcoded id.

- [ ] **Step 3: Extend dimension 9**

`Screenshots` (line 51) gains swap completeness: every `existing_image_decisions` entry with `decision: accepted` has its `old_url` replaced by its `new_url` at that exact occurrence, and every `decision: declined` entry is left untouched. A partial swap leaves a stale image live and is invisible in the diff — **MAJOR**. A swap applied to a declined occurrence is equally a **MAJOR**: it can push a replacement into a space the change does not affect.

- [ ] **Step 4: Invert dimension 12**

`Source traceability` (line 54) currently requires an inline Jira-key citation. Replace its check with the inverse, citing `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §1: a Jira key, `[[wikilink]]`, PR URL, or `<!-- KEY: … -->` comment appearing in a rendered page is a **MAJOR**. A valid `<!-- intentional-discrepancy: … -->` marker is the one permitted comment and is not a finding. **Keep the dimension's name and its output slot** — only the test changes.

- [ ] **Step 5: Add the output slot**

Add `#### Page structure conventions` to the output-heading list at `:75-123`, positioned to match its row's position in the table. The table and the slots must enumerate the same 17 names in the same order.

- [ ] **Step 6: Add the new inputs**

At `:22`, the inputs list describes the planner checklist including `repo_authoring_guidance` and `repo_verification_gates`. Add `component_patterns` (from the planner) and `existing_image_decisions` (from the orchestrator, Task 7) to that description — a reviewer cannot check dimensions it was never handed.

- [ ] **Step 7: Verify**

```bash
cd plugins/dev-workflows
awk '/^\| Dimension \| Check \|/,/^$/' agents/doc-reviewer.md | grep -c '^| '   # WRONG-TARGET, see note — not 19
sed -n '75,140p' agents/doc-reviewer.md | grep -c '^#### '                      # expect 17
diff <(awk '/^\| Dimension \| Check \|/,/^$/' agents/doc-reviewer.md | grep '^| ' | tail -17 | cut -d'|' -f2 | sed 's/^ *//;s/ *$//') \
     <(sed -n '75,140p' agents/doc-reviewer.md | grep '^#### ' | sed 's/^#### //')
# expect NO output — table names and slot names match, in order
grep -n 'Every factual claim cites the originating Jira key' agents/doc-reviewer.md  # expect 0
grep -c 'component_patterns\|existing_image_decisions' agents/doc-reviewer.md   # expect >=3
```

The `diff` is the important one. The previous round's final review caught these two lists drifting apart, so prove they match rather than counting them separately.

**Corrected 2026-08-13 (R39):** Line 640's `# expect 19 (header + separator + 17)` is **WRONG-TARGET**, not a wrong number. `grep -c '^| '` requires a literal space after the leading pipe; the markdown table separator row is `|---|---|`, which has no space after its leading pipe, so it never matches this pattern on any correctly-formatted table. The command can therefore only ever return header (1) + 17 data rows = **18**, never 19 — confirmed at `25b3628`. This is not a content defect: the `diff` immediately below (line 642) is the check that actually proves the 17 dimensions match, and it passes clean (no output).

- [ ] **Step 8: Commit**

```bash
git add plugins/dev-workflows/agents/doc-reviewer.md
git commit -m "feat(dev-workflows): doc-reviewer gains page-structure conventions; traceability inverts"
```

---

### Task 11: Phase 8 propose and apply

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md:940-965` (Jira Agent 2/3), `:997-1002` (8.5 Step 1), new Phase 8.6 after `:1023`, `:1025+` (Phase 9 sections), `:1390-1425` (direct Agent 2/3), new Phase 4.5 after `:1450`, `:1452+` (Phase 5 sections)
- Modify: `plugins/dev-workflows/references/finish-and-handoff.md:20-21`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the propose/apply contract. Agents 2 and 3, in both modes, return `{file, anchor, replacement, reason}` and write nothing.

- [ ] **Step 1: Convert Agents 2 and 3 to propose mode — Jira mode**

In the Agent 2 prompt (`:940`) and Agent 3 prompt (`:954`), replace the apply instruction (*"If YES: append to the most appropriate existing file…"* / *"If YES: apply minimal, additive, scoped changes only…"*) with a propose instruction: return a precise proposed edit — `file`, `anchor` (the exact existing text to change, or the section to append to), `replacement`, and `reason` — and **write nothing**. Keep every detection instruction and the `'no update required'` return unchanged. Agent 1 and Agent 4 are untouched.

- [ ] **Step 2: Same conversion in direct mode**

Apply the identical change to the direct-mode Agent 2 (`:1398`) and Agent 3 (`:1413`) prompts.

- [ ] **Step 3: Drop the stale staging clause**

`commands/document.md:1000` and `references/finish-and-handoff.md:20-21` both name Agent 3 as a source of uncommitted docs-repo edits. Remove the `and Agent 3 (\`CLAUDE.md\`)` clause from both; Agent 1 remains named. After Step 1 nothing uncommitted originates from Agent 3, and leaving the sentence would describe a path that no longer exists.

- [ ] **Step 4: Add Phase 8.6 (Jira mode)**

Insert `## Phase 8.6 — Maintenance proposals` **after** Phase 8.5 and before Phase 9. Ordering is the whole safety property: 8.5 has already sealed the docs commit, so an accepted `CLAUDE.md` edit cannot ride it.

Present one row per proposal — file, the rule or entry, the reason. Then:

```
choices: ["Skip — report only (Recommended)", "Apply all", "Choose per proposal", "Cancel"]
```

Each accepted proposal is applied by **re-dispatching the agent that produced it**, in apply mode, carrying its own proposal back. Applied edits are left **uncommitted** — state that explicitly, and state why: in a repo where a `CLAUDE.md` change triggers a long review, that change needs its own PR on the user's timing. Note that a later run's Phase 6.2 clean-tree check will trip on them until the user deals with them, and that this is intended.

Skip the phase with no prompt when both agents returned `'no update required'`.

- [ ] **Step 5: Add Phase 4.5 (direct mode)**

Insert `## Phase 4.5 — Maintenance proposals` between Phase 4 and Phase 5, with the same prompt and the same apply mechanism. Direct mode never commits, so state that the ordering constraint is already satisfied and the phase exists so an accepted proposal still gets applied.

- [ ] **Step 6: Report the outcome in both modes**

Both final reports already carry `### Knowledge base (Agent 2)` and `### Instructions (Agent 3)` sections. Extend each to state the proposal **and its disposition** — proposed / applied-uncommitted / declined — rather than adding parallel sections that would duplicate them.

Add one new section to each report, `### Maintenance applied (uncommitted)`, consolidating every applied edit and stating plainly that it is deliberately excluded from the docs commit. Write "none" when nothing was applied.

> **Deviation from spec §3.2, recorded deliberately.** The spec called for *two* new report sections. Two of the three facts already have homes in the existing Agent 2 and Agent 3 sections, so only the consolidated applied-list is new. This satisfies the spec's intent — both facts reported — without duplicate sections.

- [ ] **Step 7: Verify**

```bash
cd plugins/dev-workflows
grep -c 'Agent 3 (`CLAUDE.md`)' commands/document.md references/finish-and-handoff.md   # expect 0 each
grep -n '^## Phase 8.6\|^## Phase 4.5' commands/document.md            # WRONG-TARGET, see note — not 2
grep -c 'Maintenance applied (uncommitted)' commands/document.md       # expect 2 — one per mode
grep -c 'write nothing' commands/document.md                           # expect 4 — Agents 2,3 in both modes
grep -n 'apply minimal, additive, scoped changes' commands/document.md # expect 0 — old apply instruction gone
```

Then confirm by reading the phase order: 8.5 (squash) precedes 8.6 (apply). If 8.6 landed before 8.5, the original bug is intact and the greps above all still pass.

**Corrected 2026-08-13 (R39):** Line 715's `# expect 2 hits` is **WRONG-TARGET**, not a wrong number. The pattern matches any heading numbered `8.6` or `4.5` regardless of title, and `document.md` also carries a pre-existing, unrelated `## Phase 4.5 — Determine applicable space(s)` heading (Jira mode's space-resolution phase, present since before this sub-project). That heading will always coexist with the two "Maintenance proposals" headings this step actually adds (`## Phase 8.6 — Maintenance proposals` Jira mode, `## Phase 4.5 — Maintenance proposals` direct mode), so the command returns 3, permanently, on any tree that keeps the space-resolution phase. Re-derived at `25b3628`: 3 hits (`:341` unrelated, `:1068` and `:1536` the two intended "Maintenance proposals" headings — the fact this check actually intends to prove).

- [ ] **Step 8: Commit**

```bash
git add plugins/dev-workflows/commands/document.md plugins/dev-workflows/references/finish-and-handoff.md
git commit -m "fix(dev-workflows): Phase 8 maintenance proposes, then applies after the commit is sealed"
```

---

### Task 12: Canonical release surface

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `CLAUDE.md` (repo root)

**Interfaces:**
- Consumes: every preceding task.

- [ ] **Step 1: Bump the version**

`plugins/dev-workflows/.claude-plugin/plugin.json` → `"version": "2.44.0"`. Update its `description` if the change is user-visible enough to warrant it. **`.claude-plugin/marketplace.json` carries the version too** — update it in the same step. That file was missed in 2.42.0.

- [ ] **Step 2: Write the changelog entry**

Add a `## 2.44.0` section at the **top** of the version list. Verify placement by reading — the canonical and copilot changelogs already have 2.41.0 listed below 2.40.0 from an earlier slip, so do not assume the first heading is the highest version.

Cover all eight items, leading with the two reframed root causes: the deprecation note was banned rather than missed, and the provenance comments were mandated rather than improvised.

- [ ] **Step 3: Update the README**

Reflect: the two new references, the `announcement_pages` profile block, the reworked image phase, Phase 8's propose/apply split, and `doc-reviewer`'s 17 dimensions.

- [ ] **Step 4: Update the root `CLAUDE.md`**

Add `references/doc-structure-conventions.md` to the source-truth reference list, with a one-line description of what it owns. Update the `/document` (Jira) workflow line if the phase list it shows is now stale. Update the `doc-reviewer` dimension count if `CLAUDE.md` names it.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '"version"' plugins/dev-workflows/.claude-plugin/plugin.json     # expect 2.44.0
grep -n '2\.44\.0' .claude-plugin/marketplace.json                        # expect >=1
grep -n '^## 2\.4' plugins/dev-workflows/CHANGELOG.md | head -3           # WRONG-TARGET, see note — not "2.44.0 first"
grep -n 'doc-structure-conventions' CLAUDE.md                             # expect 1
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo "marketplace.json valid"
python3 -m json.tool plugins/dev-workflows/.claude-plugin/plugin.json > /dev/null && echo "plugin.json valid"
```

**Corrected 2026-08-13 (R39):** Line 768's `grep -n '^## 2\.4'` is **WRONG-TARGET**, not a wrong number: `CHANGELOG.md` headers are formatted `## [2.44.0] — 2026-08-10` — the pattern is missing the `[` — so this exact command returns **no output** on any tree, ever. The correct probe is `grep -n '^## \['` (confirmed at `25b3628`: `## [2.44.0] — 2026-08-10` first, then `## [2.43.0]`, `## [2.42.0]` — the intended fact holds).

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json plugins/dev-workflows/CHANGELOG.md \
        plugins/dev-workflows/README.md .claude-plugin/marketplace.json CLAUDE.md
git commit -m "chore(dev-workflows): 2.44.0 — /document authoring and placement"
```

---

### Task 13: mgd port

**Files:**
- Modify: `/workspace/mgd-claude-plugins/plugins/dev-workflows/**`, `/workspace/mgd-claude-plugins/.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: canonical at 2.44.0.

- [ ] **Step 1: Establish the pre-flight baseline**

```bash
cd /workspace
diff -rq ihudak-claude-plugins/plugins/dev-workflows mgd-claude-plugins/plugins/dev-workflows
```

Before this task the two trees differ **only** in the five identity files: `.claude-plugin/plugin.json`, `CHANGELOG.md`, `LICENSE`, `README.md`, `references/dependencies.md`. Anything else listed is a pre-existing drift — report it and stop rather than porting over it.

- [ ] **Step 2: Copy the non-identity content**

Copy every file tasks 1–11 created or modified, except the five identity files. Do **not** blanket-`cp -r` the tree: that would overwrite mgd's identity files with canonical's.

- [ ] **Step 3: Hand-port the identity files**

`plugin.json` → `"version": "2.44.0"` with mgd's own author and description. `CHANGELOG.md` → a 2.44.0 entry in mgd's voice. `README.md` → the same content updates as canonical, with mgd's naming. `LICENSE` and `references/dependencies.md` change only if the corresponding canonical file changed for a reason that applies to mgd.

- [ ] **Step 4: Update the mgd catalog**

`/workspace/mgd-claude-plugins/.claude-plugin/marketplace.json` → `2.44.0`. It keeps `"name": "mgd-plugins"`, the `Dynatrace Managed` author, and the `Dynatrace-Internal/mgd-claude-plugins` homepage. **This file was missed in 2.42.0.**

- [ ] **Step 5: Verify**

```bash
cd /workspace
diff -rq ihudak-claude-plugins/plugins/dev-workflows mgd-claude-plugins/plugins/dev-workflows
# WRONG, see note below — not exactly 5 lines
grep -n '2\.44\.0' mgd-claude-plugins/.claude-plugin/marketplace.json mgd-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json
grep -c 'ihudak\|Ivan Gudak' mgd-claude-plugins/.claude-plugin/marketplace.json   # expect 0
python3 -m json.tool mgd-claude-plugins/.claude-plugin/marketplace.json > /dev/null && echo valid
```

**Corrected 2026-08-13 (R39):** Line 819–820's `# expect exactly 5 lines` is **WRONG**. Re-derived at `25b3628` (canonical) / `8bc8862` (mgd): the diff has **47** differing files, not 5. Of these, 5 are the genuine identity files this check intends to name (`.claude-plugin/plugin.json`, `CHANGELOG.md`, `LICENSE`, `README.md`, `references/dependencies.md` — content-verified as real, edition-specific differences). The other **42** are `references/guidelines/*` and `references/api-guidelines/**` files that differ **only in line endings** (canonical stores them CRLF, mgd stores them LF — byte-for-byte identical once normalized: `diff <(tr -d '\r' < canonical-file) <(tr -d '\r' < mgd-file)` is empty for every one). This CRLF/LF split is **pre-existing and unrelated to this sub-project** — both files trace back to `9756501` (canonical, "migrate guideline-reviewer and api-guideline-review from vault") and mgd's original "initial import" commit, both long before B2. It was never caught because no earlier sub-project's parity check happened to run a full, literal `diff -rq` across the entire `plugins/dev-workflows` tree and record the true line count — the same class of undercount as `2026-08-11-environment-guards-verification.md`'s V14 (5 identity files reported instead of 7). Not fixed here: normalizing the CRLF drift is a `plugins/` content change, outside this docs-only task's scope — flagged for a future sub-project. **Method note (2026-08-13, fix round 1):** independently re-verified with a real `git worktree` checkout of both `25b3628` and `8bc8862` (not `git show`) followed by `diff -rq` on disk — also **47**, the same as raw-blob comparison; this repo pair has no `.gitattributes` and both sides use `core.autocrlf=input`, which does not rewrite line endings on checkout, so there is no comparison method at this commit pair that returns 5. Only a same-day diff of **today's** live working trees shows these files as identical, because mgd's CRLF was brought in line with canonical by unrelated later commits after B2 shipped.

- [ ] **Step 6: Commit**

```bash
cd /workspace/mgd-claude-plugins
git add -A
git commit -m "chore(dev-workflows): 2.44.0 — /document authoring and placement"
```

---

### Task 14: copilot port

**Files:**
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/**`, `skills/document/**`, `skills/docs-profile/**`, `agents/**`
- Create: `skills/_shared/doc-structure-conventions.md`, `skills/_shared/dynatrace-docs/anchor-conventions.md`
- Modify: `dev-workflows/.plugin/plugin.json`, `dev-workflows/CHANGELOG.md`, `dev-workflows/README.md`
- Modify: `/workspace/ihudak-copilot-plugins/.github/plugin/marketplace.json`, `/workspace/ihudak-copilot-plugins/.github/copilot-instructions.md`

**Interfaces:**
- Consumes: canonical at 2.44.0.

> **Layout differs — never blind-copy.** Copilot has no `commands/` and no `references/`. Commands are `skills/<name>/`; references are `skills/_shared/<name>.md`. Its catalog is `.github/plugin/marketplace.json`, **not** `.claude-plugin/marketplace.json` (the spec's §10 names the wrong path; this plan is correct).

- [ ] **Step 1: Port the two new references**

Canonical `references/doc-structure-conventions.md` → `skills/_shared/doc-structure-conventions.md`.
Canonical `references/dynatrace-docs/anchor-conventions.md` → `skills/_shared/dynatrace-docs/anchor-conventions.md`.

Translate every `${CLAUDE_PLUGIN_ROOT}/references/…` citation to this edition's idiom. Check how a neighbouring `_shared` file (e.g. `gate-ledger.md`, ported in the previous round) refers to its siblings and match it exactly.

- [ ] **Step 2: Port the modified references**

`gate-ledger.md`, `source-truth.md`, `finish-and-handoff.md`, `dynatrace-docs/docs-profile-schema.md`, `dynatrace-docs/docs-profile.default.yml` — same content edits, same citation translation.

- [ ] **Step 3: Port the agents**

`doc-location-finder`, `doc-planner`, `doc-writer`, `doc-reviewer` under `dev-workflows/agents/`. Translate citations. Copilot agents are not addressed by `subagent_type` — check how the existing files name their siblings and match that, do not introduce Claude Code's idiom.

- [ ] **Step 4: Port the commands**

`skills/document/` and `skills/docs-profile/` receive the same phase edits. Phase and section names stay identical to canonical so the two editions describe one workflow.

- [ ] **Step 5: Release surface**

`dev-workflows/.plugin/plugin.json` → `"version": "2.14.0"`. `.github/plugin/marketplace.json` → `2.14.0`. `dev-workflows/CHANGELOG.md` → a `## 2.14.0` entry (check placement by reading — this changelog has 2.11.0 below 2.10.0 from an earlier slip). `dev-workflows/README.md` → the content updates. **`.github/copilot-instructions.md`** → reflect the new references and the reworked phases. That file was missed in 2.42.0.

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-copilot-plugins
grep -rn 'CLAUDE_PLUGIN_ROOT' dev-workflows/ | wc -l      # WRONG-TARGET, see note — not 0
grep -rn 'subagent_type' dev-workflows/ | wc -l           # expect 0
grep -n '2\.14\.0' dev-workflows/.plugin/plugin.json .github/plugin/marketplace.json  # expect 1 each
ls dev-workflows/skills/_shared/doc-structure-conventions.md \
   dev-workflows/skills/_shared/dynatrace-docs/anchor-conventions.md
grep -c 'doc-structure-conventions\|anchor-conventions' .github/copilot-instructions.md  # expect >=1
python3 -m json.tool .github/plugin/marketplace.json > /dev/null && echo valid
```

**Corrected 2026-08-13 (R39):** Line 880's `# expect 0` is **WRONG-TARGET**, not a wrong number. Re-derived at `c25eab7`: `grep -rn 'CLAUDE_PLUGIN_ROOT' dev-workflows/` returns 2 hits, both in `dev-workflows/CHANGELOG.md:799-800`, contrastive prose describing copilot's own dialect ("Path references use `~/.copilot/installed-plugins/...` instead of `${CLAUDE_PLUGIN_ROOT}`" / "Hooks use `${PLUGIN_ROOT}` instead of `${CLAUDE_PLUGIN_ROOT}`"). This is historical CHANGELOG narrative, not a leaked canonical-dialect token — the same false-positive class the F sub-project's V16 check already excludes CHANGELOG.md for. Since CHANGELOG entries are never rewritten, this command will keep returning 2, permanently, on every future tree.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add -A
git commit -m "chore(dev-workflows): 2.14.0 — /document authoring and placement"
```

---

## Self-review

**Spec coverage.** §1.1 → T4; §1.2 → T3; §1.3 → T4 Step 3; §1.4 → T4 Steps 1, 5; §2 → T1 §1 + T5 + T10 Step 4; §3.1 → T11 Steps 1-2; §3.2 → T11 Steps 4-6; §3.3 → T11 Step 3; §4 → T1 §2 + T6 Steps 2-3 + T10 Step 1; §5 → T1 §3 + T6 Steps 1, 3 + T10 Step 1; §6.1-6.3 → T7; §6.4 → T3 + T6 Step 3; §6.5 → T8; §6.6 → T10 Step 3; §7 → T2 + T6 Step 3 + T10 Step 2; §8.1-8.2 → T9 Steps 1-2; §8.3 → T9 Steps 3-4; §9 → T10; §10 → T12, T13, T14. No gaps.

**Type consistency.** Four names cross task boundaries. Each has exactly one producer:

| Name | Producer | Consumers |
|---|---|---|
| `profile.announcement_pages` | T3 (profile) | T4 (finder) |
| `component_patterns` | T6 (`doc-planner`) | T6 (`doc-writer`), T10 (reviewer) |
| `existing_image_decisions` | T7 (orchestrator, Phase 5.6) | T6 (`doc-writer`), T10 (reviewer) |
| `new_images_wanted` | T7 (Phase 1) | T7 (Phase 5.6) |

`existing_images` appears nowhere as a produced name — an earlier draft had both the planner and the orchestrator building that list, which is the duplication the previous round was burned by. T6's verification asserts `grep -c existing_images agents/doc-planner.md` is **0** for exactly this reason.

**Known deviations, all deliberate and all flagged in place:**

1. **T11 Step 6** — one new report section rather than the spec's two, because the Agent 2 and Agent 3 sections already exist in both reports.
2. **T14** — the copilot catalog is `.github/plugin/marketplace.json`; spec §10 says `.claude-plugin/marketplace.json`. The plan's path is the verified one.
3. **T12** — root `CLAUDE.md` gains **one** of the two new references, not two. Only `references/doc-structure-conventions.md` is listed there; `references/dynatrace-docs/anchor-conventions.md` is not, because that list holds nine entries all sitting directly under `references/` — it is the cross-cutting-reference index, not an inventory of every file in the tree, and a repo-specific `dynatrace-docs/` reference does not belong in it. The omission is correct, not an oversight.

**Ordering constraints.** T7 produces `existing_image_decisions`, which T6's writer consumes — but T6 runs first, so its writer edit references a block T7 has not yet defined. That is fine within a plan executed to completion, and T6's Interfaces block names T7 as the source. T8 must land before or with T7's ledger append. T10 must land after T1, T2, T6, T7, and T8, since it cites all five. Sequential execution in the order written satisfies every constraint.

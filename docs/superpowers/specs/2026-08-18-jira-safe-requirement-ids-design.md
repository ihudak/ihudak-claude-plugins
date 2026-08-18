# Jira-safe requirement IDs — design

**Ships as:** dev-workflows 2.53.0 (canonical + mgd) / 2.23.0 (copilot)
**Branch:** `iv-gu/jira-safe-requirement-ids` (all three repos)
**Origin:** PM report, 2026-08-18 — pasting a VI into Jira turns its acceptance-criterion IDs into
links to unrelated tickets.

## 1. Context

`/create-vi` writes a VI whose body is pasted verbatim into the Jira workitem
(`commands/create-vi.md:208` — the body below the frontmatter). That body mints requirement IDs in
the form `[US-1]`, `[AC-1]`, `[SM-1]`, and bare `UC-1` / `FR-1`. `/create-ard` mints `[AD-1]`;
`epic-writer` emits a `## Covers` line carrying **bare** `US-2, AC-4, SM-1`.

Every one of those tokens has the shape of a Jira issue key. The reporting user's Jira has a real
project keyed `AC`, so on paste Jira's autolinker converts `AC-1`, `AC-2`, … into links to genuine,
unrelated tickets — creating false relationships in Jira and noise on the linked tickets.

There is a second, independent failure point downstream. The vault importers
(`$VAULT_PATH/.obsidian/scripts/custom/jira-workitem-import` and `jira-bulk-import`) rewrite bare
issue keys to links in `src/jira_markup_converter.py:381`. Someone has already been bitten by this
once: the regex carries `(?<!\[)…(?!\])` lookarounds whose comment names "a VI's `[US-1]` ID
marker". Brackets therefore shield the **import** side today. Jira ignores brackets entirely, which
is why the paste side still breaks — and why `## Covers`, the one unbracketed site, breaks on both.

The spec and design artifacts are already immune by accident: `specification-format.md` mints
`[U01]` / `[AC01]` / `[TC01]`, which no autolinker and no importer regex recognises.

## 2. Governing principle

**A requirement ID must be impossible to mistake for a Jira issue key, by anything — Jira's
autolinker, the vault importers, or a human reader.** One grammar describes the whole namespace, so
a single expression can check it; and the check runs where an artifact is authored, not only where
it is reviewed.

## 3. Decisions

### D1 — `#` replaces `-` as the separator; the grammar is `[PREFIX#N]`

Every ID the plugin mints into a Jira-bound artifact matches `\[[A-Z]{2,4}#[0-9]+\]`.

*Rejected:* zero-padding on the spec model (`[AC01]`). It is equally Jira-safe, but it collapses the
VI namespace into the spec namespace — an Epic's `## Covers`, a design's traceability table, and
`/ready`'s cross-artifact check all reference both in the same pipeline, and a bare `[AC01]` would
no longer say which document it points at.

*Rejected:* renaming the prefixes (`[VS#1]` for a VI story, `[VC#1]` for a VI criterion). Maximally
unambiguous, largest churn, and the letters stop matching what PMs say out loud.

*Rejected:* a non-ASCII hyphen or zero-width separator. Invisible to a reader, hostile to grep, and
silently broken by any tool that normalises Unicode.

### D2 — Bracketing becomes mandatory, not decorative

`UC-N`, `FR-N` and the Epic `## Covers` line emit bare tokens today, and those are exactly the sites
both Jira and the importers mangle. Under this design every ID reference is bracketed everywhere,
including in prose and table cells.

Two reasons, not one: brackets are already the importers' protection mechanism, and a fully
bracketed namespace makes the pre-lint grep exact rather than heuristic.

### D3 — `[SMC#1]`, not `[SM-C#1]`, for counter-metrics

Both are Jira-safe. Only the first keeps `\[[A-Z]{2,4}#[0-9]+\]` a *complete* description of the
namespace, and therefore checkable in one expression. A second separator form would need a second
rule maintained in parallel forever.

*Rejected:* `[SM-C#1]`, which reads marginally better as "SM counter 1".

### D4 — The spec and design namespaces do not change

`[U01]` / `[AC01]` / `[TC01]` stay exactly as they are. They are already Jira-safe, they are never
pasted into Jira, and `code-review.md`'s spec/design-conformance ("converge") check traces them
against shipped diffs.

This makes a global find-and-replace **unsafe**: `agents/code-review.md`, `references/design-format.md`
and `references/specification-format.md` all carry spec IDs that must survive untouched. The change
is per-file review with the VI/spec boundary checked at each site.

### D5 — Writers are strict; readers accept both forms

Nothing emits the dash form after this change. But `jira-reader` parses the *re-imported* VI and
emits `requirements[].id` for `/epics`, `/document`, `/ready` and `/implement`
(`agents/jira-reader.md:60-64`, contract at `references/handoff/jira-reader.md:47`). It must accept
`[US#1]` **and** `[US-1]`.

The user confirmed no backward compatibility is required for writing. The reader is the exception
because its failure mode is silent rather than loud: an already-published dash-form VI would parse
to zero requirements, and `/epics` or `/ready` would proceed on an empty list instead of erroring.

**Tolerance is section-scoped, not document-wide.** The dash form is accepted only inside the
requirement-bearing sections (`## User Stories`, `## Acceptance Criteria`, `## Success Metrics`,
`## Functional requirements`, `## Use cases & user journey`). Elsewhere — notably
`## References / linked issues` — a `KEY-123` token is a genuine Jira key and must keep being read
as one.

### D6 — The importers get a test, not a patch

Empirically verified against both converters on 2026-08-18 by running
`JiraMarkupConverter.convert()` over the full ID set:

| Input | Output |
|---|---|
| `[US#1]` `[AC#1]` `[SM#1]` `[SMC#1]` `[UC#3]` `[FR#2]` `[AD#1]` | unchanged |
| `h3. [US#1]: …` | `### [US#1]: …` — unchanged ID |
| `[AC#1]` in a wiki table cell | unchanged |
| bare `AC#1` (unbracketed) | unchanged |
| `PRODUCT-123` | `[[PRODUCT-123]]` — still linkified |
| `[PRODUCT-123\|smart-link]` | `[[PRODUCT-123]]` — still linkified |
| legacy bare `US-2, AC-4, SM-1` | `[[US-2]], [[AC-4]], [[SM-1]]` — the accepted drawback |
| legacy `[AC-1]` | unchanged — existing bracket guard |

The `#` grammar is therefore already fully compatible. No converter change is needed, and
linkification of real keys keeps working — which matters because `jira-workitem-import` downloads
every linked ticket, so a `[[KEY-123]]` wikilink resolves to a real file in the vault.

*Rejected:* a `REQUIREMENT_ID_PREFIXES` deny-list suppressing linkification of `US-`/`AC-`/… . It
would fix legacy dash-form VIs, but at the cost of breaking genuine bare mentions of real tickets in
any project sharing a prefix — permanently, to fix a transient problem. Legacy VIs mis-link until
`/update-vi` next touches them, and that is accepted.

What the importers **do** get is a characterization test locking the table above. Today that
compatibility is an accident that nothing records; a future converter change could break the round
trip silently, surfacing as a corrupted VI.

### D7 — Existing `$SPECS_PATH` artifacts are not migrated

19 files under `$SPECS_PATH/specifications/` carry dash-form IDs (canonical VIs, `revisions/`
snapshots, and `dev-workflows/` bookkeeping that never reaches Jira). They are left alone; the
tolerant reader handles them and each converts the next time `/update-vi` touches it.

*Rejected:* migrating all 19. Rewriting an archived `revisions/` snapshot makes it no longer a
faithful record of what was published, which is the only thing a snapshot is for.

## 4. The grammar

```
[PREFIX#N]      PREFIX ∈ {US, AC, SM, SMC, UC, FR}   (VI)
                PREFIX ∈ {AD}                         (ARD)
                N unpadded, contiguous from 1
```

| Artifact | Today | New |
|---|---|---|
| VI user story | `### [US-1]: <title>` | `### [US#1]: <title>` |
| VI acceptance criterion | `[AC-1]` | `[AC#1]` |
| VI success metric | `[SM-1]` | `[SM#1]` |
| VI counter-metric | `[SM-C1]` | `[SMC#1]` |
| VI use case | `UC-1` (bare) | `[UC#1]` |
| VI functional requirement | `FR-1 … Implements: UC-1 / US-2` (bare) | `[FR#1] … Implements: [UC#1] / [US#2]` |
| ARD decision | `### [AD-1]: <title>` | `### [AD#1]: <title>` |
| Epic `## Covers` | `US-2, AC-4, SM-1` (bare) | `[US#2], [AC#4], [SM#1]` |
| spec / design | `[U01]` `[AC01]` `[TC01]` | **unchanged** |

No zero-padding: pre-lint's contiguity check already does the ordering job padding would do, and the
unpadded form matches what the VI emits today.

## 5. Enforcement — `references/pre-lint.md`

`pre-lint.md` is already run by all six commands that produce these artifacts — `/create-vi`,
`/update-vi`, `/create-ard`, `/specify`, `/design`, `/epics` — so no new wiring is needed.

### 5.1 New check — Jira-key collision

Applied to the VI, the ARD, and each Epic file.

```
grep -nE '\b[A-Z]{2,10}-[0-9]+\b' <file>
```

For the VI, run against the body **below the frontmatter** — `/create-vi` pastes only that, and the
frontmatter's `jira_key:` / `ref:` / `seeded_from_vi:` / `revision_of:` fields legitimately carry
keys.

Discard a hit only when it is a deliberate Jira reference: inside a wikilink (`[[KEY-123]]`), inside
a markdown link, or inside a fenced code block. Every surviving hit is a **BLOCKER** naming its own
fix — convert to `[PREFIX#N]` if it is a requirement ID, wrap as `[[KEY-123]]` if it is a real
ticket. The conversion is mechanical, so pre-lint inline-fixes it under its existing contract.

The ARD is not itself pasted into Jira — `/create-ard` has no paste step. It gets the check anyway,
because `epic-writer` copies `AD` references into Epic drafts, which are pasted. Catching it at the
source is cheaper than catching it downstream.

### 5.2 Revised ID-series checks

- **VI** — `[US#N]`, `[AC#N]`, `[SM#N]`, plus `[SMC#N]` / `[UC#N]` / `[FR#N]` when those adapt-in
  clusters are present; each contiguous from 1.
- **ARD** — `[AD#N]` contiguous, no duplicates.
- **Epic** — `## Covers` references parent-VI IDs in bracketed `#` form. (Today's line asserts the
  bare form `US-N`/`AC-N`/`SM-N` and becomes false.)

Pre-lint remains advisory and never hard-stops; the Opus reviewer remains the gate.

## 6. Blast radius

23 files, ~130 sites in the canonical edition. `CHANGELOG.md` is excluded — it is history and keeps
the dash form.

| Group | Files |
|---|---|
| Format authorities | `references/vi-format.md`, `references/ard-format.md`, `references/pre-lint.md` |
| Producers | `commands/create-vi.md`, `commands/update-vi.md`, `commands/create-ard.md`, `commands/epics.md`, `agents/epic-writer.md` |
| Reviewers | `agents/vi-reviewer.md`, `agents/ard-reviewer.md`, `agents/epic-reviewer.md`, `agents/readiness-reviewer.md`, `agents/spec-reviewer.md`, `agents/design-reviewer.md`, `agents/code-review.md` |
| Readers (tolerant per D5) | `agents/jira-reader.md`, `references/handoff/jira-reader.md` |
| Cross-cutting | `references/ard-resolution.md` (15 sites — the densest), `commands/ready.md`, `commands/implement.md`, `commands/design.md` |
| Identity files | root `CLAUDE.md:256`, `plugins/dev-workflows/README.md` (5 sites) |
| Importers (test only) | `jira-workitem-import/tests/test_jira_markup_converter.py`, `jira-bulk-import/tests/test_jira_markup_converter.py` |

**Not touched:** `references/specification-format.md`, `references/design-format.md`, and the spec-ID
sites inside `agents/code-review.md`.

## 7. Porting

Three editions: `ihudak-claude-plugins` (canonical, 2.52.0), `mgd-claude-plugins` (2.52.0),
`ihudak-copilot-plugins` (2.22.0).

Never blind-`cp` into mgd (five identity files); never `cp` into copilot at all (four dialect rules,
including colon-form command names). The identity files — root `CLAUDE.md`, `README.md`,
`plugin.json`, `marketplace.json`, `CHANGELOG.md` — are enumerated per edition and checked
individually, because a parity diff classifies them as expected-to-differ and therefore cannot see a
fix that died in one of them.

## 8. Residue — every claim this makes false

1. `references/vi-format.md` states the `[US-N]` / `[AC-N]` / `[SM-N]` / `[SM-C1]` / `UC-N` / `FR-N`
   grammar in four places, including the quality rule at `:79`.
2. `references/pre-lint.md`'s VI and ARD ID-series lines, and the Epic line asserting `## Covers`
   carries bare `US-N`/`AC-N`/`SM-N`.
3. `agents/jira-reader.md:60-64` maps `### [US-N]:` → `{id: US-N}`; the handoff contract at
   `references/handoff/jira-reader.md:47` and `:130` enumerates `<US-N | AC-N | SM-N | FR-N | UC-N>`.
4. `agents/vi-reviewer.md` — five rule sites plus the finding-format line at `:47`
   (`<Section or US-N/AC-N/SM-N>`).
5. `agents/epic-writer.md:79`'s `## Covers` example and `:160`'s `AD-N` consistency rule.
6. Every `AD-N` mention in `references/ard-format.md`, `references/ard-resolution.md`,
   `agents/ard-reviewer.md`, root `CLAUDE.md:256`, and `README.md` (×5).
7. The importers' round-trip compatibility with `[AC#1]` is currently an undocumented accident; §D6's
   test converts it into a stated contract.

## 9. Requirements

**Grammar**
- **R1** — Every ID the plugin mints into a VI, ARD, or Epic file matches `\[[A-Z]{2,4}#[0-9]+\]`.
- **R2** — VI series are `US`, `AC`, `SM`, `SMC`, `UC`, `FR`; ARD is `AD`; numbers unpadded and
  contiguous from 1.
- **R3** — Every ID reference is bracketed, including in prose, tables, and the Epic `## Covers` line.
- **R4** — `[U01]` / `[AC01]` / `[TC01]` in `specification-format.md`, `design-format.md`, and
  `code-review.md`'s converge check are byte-identical after the change.

**Enforcement**
- **R5** — `pre-lint.md` defines a Jira-key collision check per §5.1, applied to VI, ARD, and Epic
  files.
- **R6** — The VI collision check runs against the body below the frontmatter only.
- **R7** — The check discards hits inside wikilinks, markdown links, and fenced code blocks, and only
  those.
- **R8** — `pre-lint.md`'s VI, ARD, and Epic ID-series rules state the `#` grammar.
- **R9** — Pre-lint stays advisory; no new hard stop is introduced.

**Readers**
- **R10** — `jira-reader` parses both `[US#1]` and `[US-1]` inside the requirement-bearing sections,
  and emits the `#` form in `requirements[].id`.
- **R11** — Dash tolerance does not extend outside those sections; `## References / linked issues`
  still reads `KEY-123` as a Jira key.
- **R12** — `references/handoff/jira-reader.md` documents the emitted form and the tolerance.

**Producers and reviewers**
- **R13** — `create-vi`, `update-vi`, `create-ard`, `epics`, `epic-writer` emit only the `#` form.
- **R14** — `vi-reviewer`, `ard-reviewer`, `epic-reviewer`, `readiness-reviewer` check the `#` form,
  and flag a dash-form ID as a **BLOCKER** — it produces false Jira links on paste, so it is a
  shipped defect, not a style nit.
- **R15** — `ard-resolution.md`, `ready.md`, `implement.md`, `design.md`, root `CLAUDE.md`, and
  `README.md` state `AD#N`.

**Importers**
- **R16** — A characterization test in both `tests/test_jira_markup_converter.py` asserts every row
  of §D6's table.
- **R17** — No behavioural change to either converter; both existing suites stay green.

**Porting**
- **R18** — mgd and copilot editions carry R1–R16, per their own dialect rules.
- **R19** — Each edition's identity files are inspected individually, not diffed as a group.
- **R20** — Version bump and CHANGELOG entry in all three editions.

## 10. Risks and their executable mitigations

**Risk 1 — a global replace corrupts the spec namespace.** `code-review.md` and the two format
authorities carry `[ACxx]`-family IDs that must not change.
*Mitigation:* extract every spec-ID-bearing line (`[U0`, `[AC0`, `[TC0`, `[Uxx`, `[ACxx`, `[TCxx`)
from the tree before and after the change and diff the two extracts — it must be empty. An
occurrence *count* is too weak: it stays equal if a site is changed and another added.

**Risk 2 — the collision check misfires on legitimate Jira keys.** VIs cite real keys in
`## References / linked issues` and in `sources:`.
*Mitigation:* run the check against all 27 existing feature dirs in `$SPECS_PATH`. Every hit must be
classifiable as either a requirement ID or a real key. If the §5.1 filter cannot separate them on
real content, the rule is wrong and gets revised before shipping — not after.

**Risk 3 — the check passes vacuously.** A grep that never fires proves nothing.
*Mitigation:* prove both directions on fixtures — a known-bad VI (dash-form `[AC-1]`) must BLOCK, a
known-good VI (`[AC#1]` plus a real `[[PRODUCT-123]]` reference) must pass clean.

**Risk 4 — the fix dies in an identity file.** The repo's recurring failure: identity files are
excluded from copying, duplicate claims made elsewhere, and get classified as expected-to-differ.
*Mitigation:* R19 — enumerate and inspect them per edition; root `CLAUDE.md:256` and `README.md`'s
five `AD-N` sites are named explicitly so they cannot be skipped.

**Risk 5 — converter compatibility regresses later.** Nothing today records that `[AC#1]` must pass
through untouched.
*Mitigation:* R16's characterization test, in both trees.

**Risk 6 — the two vendored converters drift.** They are currently byte-identical except
`_format_issue_link` and one comment.
*Mitigation:* none in this change — flagged, not fixed. Extracting a shared module is separate work.

## 11. Out of scope

- Migrating the 19 existing dash-form artifacts under `$SPECS_PATH` (D7).
- Any converter behaviour change, including the rejected prefix deny-list (D6).
- De-duplicating the two vendored `jira_markup_converter.py` copies (Risk 6).
- The spec and design ID namespaces (D4).
- Jira-side configuration; the autolinker is not something this plugin can disable.

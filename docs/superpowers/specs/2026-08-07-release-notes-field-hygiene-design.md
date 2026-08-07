# Release-notes field hygiene — design

**Date:** 2026-08-07
**Status:** Approved design, not yet implemented.
**Scope:** `dev-workflows` plugin, all three editions (canonical Claude, mgd Claude, Copilot)
**Source:** PM feedback items 1, 2, and 8 from the 2026-08-07 `/superpowers:brainstorming` session
(`$SPECS_PATH/specifications/PRODUCT-14589-*/dev-workflows/PRODUCT-14589-feedback.md` and the
session transcript). Sub-project **A** of four; the remaining three are listed under
[Out of scope](#out-of-scope).

---

## Problem

**The test a question must pass.** Answering the same thing twice is not the problem — the plugin
asks for the title and the prose too, and the user re-enters those in Jira by pasting. That
duplication is worth it, because a few short answers turn into finished text and the paste saves real
time. A **dropdown** buys none of that: deciding in the Claude Code window and deciding in Jira cost
the same, and selecting the value is identical whether or not a hint sits in the markdown. So a
dropdown question earns its place only if the answer **changes what the plugin generates or decides**.
If it does, asking is worth it even though the user answers twice. If it does not, the question is
pure overhead and the field should go.

Three dropdown values fail that test today, and each also produces a concrete defect:

1. **Release target.** `/create-vi` asks for `release_versions` during authoring, but a VI's release
   target is unknown at authoring time — a VI goes to a planning session with many stakeholders and
   only then gets assigned to a milestone. Setting it in Jira afterwards is a dropdown, not a
   copy-paste from markdown.
2. **Change Type.** `/release-notes` proposes and confirms a Change Type. It repeatedly proposed
   `Bug fix` for Value Increments, where it is almost never right, and its definition of
   `New technology support` as "the release-note-worthy catch-all" does not match what the words
   mean at Dynatrace (OneAgent-monitored technology support).
3. **`{{#context}}` label.** `/release-notes` asks *"Which `{{#context}}` label should the draft
   carry?"* with no explanation of what the label is or why the user must supply it.

Applying the test to each:

| Field | Changes generated content? | Drives a workflow decision? | Verdict |
|---|---|---|---|
| `release_versions` | No — the prose may never name the version, and the design collapses to one Summary block. | No — its only use was an `AND` in a worthiness check that §2.1 replaces. Verified to have no other consumer in the plugin. | **Drop.** |
| `release_notes_category` | It *is* one line of content, but it changes no other prose. | No. | **Drop the question**, source the line from the import. |
| `change_type` | **Yes** — decisively. It selects the destination and therefore the draft's *shape*. | Yes. | **Keep.** Sourced from the import, else inferred; confirmed only when inference is low-confidence, and framed by consequence rather than by enum label. See §4. |

And on the re-import, all three come back in the VI frontmatter anyway, which is where the plugin
should have been reading them from all along.

## Evidence

Gathered from the `dynatrace-docs` working tree (`$DOCS_PATH`), which was not consulted when these
features were originally designed.

### The `{{#context}}` label is the Solution taxonomy

`.docstack/libs/engine/components/src/context/context.docs.md` and the sprint-page template
`dynatrace/_content/whats-new/saas/v1-new-sprint-xyz.md.template` document the full form:

```handlebars
{{#context}}:WarningIcon: Breaking change :SelectIndicatorIcon: Solution | Capability{{/context}}
```

Two segments — an icon-prefixed change type, and the Dynatrace Solution taxonomy.

But that is the **hand-authored sprint-page path**. `/release-notes` output goes down the other
path: the Jira automation that pulls from `api.internal.ace-tools.dynatrace.com/drng/get-release-notes/…`
and writes `<space>/_snippets/release-notes/<product>/<sprint>/`. Across all **852** context lines in
that path, **zero** carry an icon or a change type. Every one is the bare taxonomy:

```handlebars
{{#context}}Digital Experience | Synthetic{{/context}}
```

The label vocabulary is exactly the Dynatrace Solution taxonomy the VI already carries as
`release_notes_category` — `Platform` (×80), `Application Observability | Distributed Tracing` (×73),
`Platform | OneAgent` (×61), `Infrastructure Observability | Kubernetes` (×38), and so on.

Yet `agents/release-notes-writer.md:148-150` **explicitly forbids** using `release_notes_category` as
the `{{#context}}` label and calls it "surfaced metadata only." So the writer holds the correct value,
is banned from using it, guesses instead, and then asks the user. **That prohibition is the defect.**

### The Change Type routes the note to a file; it is never rendered

On the generated path the Change Type does not appear as text at all — it selects the destination
file. Structure of the four generated snippet types:

| Destination | files | `{{#context}}` lines | shape |
|---|---:|---:|---|
| `feature-updates.md` | 58 | 718 | label + `### title` + prose |
| `breaking-changes.md` | 41 | 109 | label + `### title` + prose |
| `fixes.md` | 57 | **1** | **a single bullet — no label, no title** |
| `spotlight.md` | 21 | 24 | curated; not routable from a VI |

A `fixes.md` entry is one self-contained sentence in a shared `### Resolved issues in this release`
list, with the Jira key appended by the automation:

```markdown
* Fixed an issue where the GET account audits endpoint would return a `500` error instead of a `504` in case of a timeout. (LIMA-43865)
```

So classifying a VI as `Bug fix` did not merely mislabel it — it rendered a `{{#context}}` label, an
`### H3` title and multi-paragraph prose for a destination that publishes none of those. The output
was **unpublishable in that shape**.

### The automation assembles the entry; it does not paste the field

`{{#internal-note}}` is injected *between* the title and the prose, and its contents (ticket URL,
assignee, reporter, status, release versions) are all Jira fields. The automation is doing structural
assembly, not verbatim pasting. The context label is metadata of the same kind — a bare dropdown
value with zero authorial variation across 852 instances — so it is likely generated from the same
Jira field.

This cannot be proven from the working tree (the generator lives behind `drng/`), and **the design
does not depend on resolving it**: sourcing the label when the import carries it is free and
guaranteed correct, and omitting it when the import does not is safe under either hypothesis.
Today's *guess* is wrong under both.

### The release version never reaches the prose

`references/release-note-types.md:104` forbids naming the release version in any title or Summary.
The only effect of `release_versions` today is that `release-notes-writer` emits **one Summary block
per declared version** — blocks that are byte-identical, because the one thing that distinguishes them
may not be written. The user pastes one Summary into one Jira field.

## Guiding principle

> **Ask only for what changes the output. For everything else: sourced, or omitted.**

If the Jira import carries a field, use it. If it does not, omit what depends on it and say so. Do not
ask the user for a dropdown value they will set in Jira anyway *unless the answer changes what the
plugin generates* — and do not invent one.

`change_type` is the single field whose answer does change the output, which is why the *decision*
survives (§3) even though the *question* does not: it is sourced from the import, else inferred, and
§4 covers the one case where inference is not safe enough to stand alone.

---

## Design

### 1. Field-class reclassification

`references/vi-format.md` already declares a class of frontmatter fields that "are regenerated by the
importer on the round-trip and are NOT authored here" (`:41-42`) — `statusCategory`, `reporter`,
`url`, `updated`, `synced`. `release_versions`, `change_type`, and `release_notes_category` behave
identically and were filed under the PM-authorable subset (`:27-29`) by mistake. Move them.

Consequences:

- **`/create-vi` Phase 3 step 1** (`commands/create-vi.md:118`) stops asking for all three. The
  sentence collapses to `relevant_for_release_notes` plus the provenance fields (`sources`,
  `derived_from`, `seeded_from_vi`, `jira_key`).
- **`/update-vi`** authors against `vi-format.md` and carries no field-specific prose, so it inherits
  the change with no edit.
- **`vi-reviewer`** (`agents/vi-reviewer.md:23`) stops requiring `release_versions`, stops validating
  `change_type` against the four-value enum, and stops raising the `MINOR` when `change_type` is
  absent on a release-notes-relevant VI. None of the three can be missing, because none is authored.
  `relevant_for_release_notes` remains a required downstream-contract field.
- **`references/vi-source-resolution.md` step 5** (generic secondary grounding) is unchanged. What
  goes is `/release-notes` Phase 3's *use* of it to read `change_type` / `release_notes_category` out
  of the authored specs draft — that rung can never match once the fields are not authored.

`relevant_for_release_notes` stays PM-authorable. It is a genuine product judgment, it defaults to
true, and it is the field the gate below reads.

### 2. `/release-notes` behavior

#### 2.1 The worthiness gate

Phase 2 step 1 becomes a real gate, read from the **import only** — that is, from the imported VI
frontmatter under `jira_export_root`, either via Phase 3's `jira-reader` handoff or by reading the
frontmatter directly at Phase 2, never from the authored specs draft:

| Imported value | Behavior |
|---|---|
| `false` | Stop: `RELEASE_NOTES_NOT_RELEVANT: <KEY> is flagged not relevant for release notes; Jira's status rule does not require one.` Offer an explicit override choice for drafting ahead of the flag. |
| `true` | Proceed. |
| absent | **Proceed silently.** The field defaults to true; absent is not false. |

`release_versions` leaves the check entirely. Today the two are ANDed, so a VI correctly flagged
not-relevant still proceeded whenever a version happened to be set.

This gate is corroborated by a Jira workflow rule: a VI cannot change state without release notes
*unless* `relevant_for_release_notes` is false — so a `false` is a deliberate PM decision that Jira
itself already treats as "no release note required."

#### 2.2 What the draft contains

Three subtractions, one addition:

- **`{{#context}}` label** — sourced from `imported_release_notes_category`; **omitted** from the
  rendered entry when the import does not carry it. Never asked, never guessed. Removes the
  `context_label_hint` input, the `field: context_label` gap, and the prohibition at
  `agents/release-notes-writer.md:148-150`.
- **`Change type:` line** — removed from `combined_rendered`. With it go the `change_type_hint` and
  `authored_vi_fields` inputs and the `field: change_type_divergence` gap (with no authored rung, two
  sources can no longer disagree). The `field: change_type` gap **survives**, reframed per §4.
- **One Summary, not one per version.** `release_versions` no longer multiplies entries, so the
  `(unspecified)` fallback and the `field: release_version` gap both go.
- **Added — a shaping line in the report, not the draft:** `Shaped as: Feature update → feature-updates.md`.
  It states how the prose was shaped and where the note will land, as a sanity check on the shape. It
  is not a field for the user to fill.

#### 2.3 What survives

The deprecation note and its `deprecation_eol` gap, unchanged. Not every VI deprecates something; when
one does, `/release-notes` asks for the end-of-life date and details **only** when they are not
derivable from the VI itself. That is a genuine content question with a "never invent a date" rule —
not a dropdown.

### 3. `release-note-types.md` becomes a destination + shape authority

The file stops being a label taxonomy (the label is gone from the draft) and becomes the authority for
*where the note lands and what shape it must take*. Three routable destinations; `not applicable`
disappears, since §2.1's gate handles it.

| Jira Change Type | Destination | Draft shape |
|---|---|---|
| `Breaking change` | `breaking-changes.md` | `{{#context}}` + `### title` + prose |
| `New technology support` | `feature-updates.md` | `{{#context}}` + `### title` + prose |
| `Bug fix` | `fixes.md` | **one self-contained sentence — no label, no title, no Jira key** |
| `not applicable` | — | no note; the §2.1 gate stops the run |

The conditional shape for `fixes` is the **largest behavioral change in this sub-project**.

Prose rules per destination, taken from the docs team's own sprint template rather than invented:

- **Breaking change** — present tense; state what is breaking; include directions or a link to
  remediate. This **overrides** today's §3 rule "lead with the customer benefit, not what breaks,"
  which contradicts the template. The Action-plan requirement survives as the remediation link.
- **Feature update** — user-value framing, present tense, **and a link to documentation or a blog
  post** — a requirement the current reference does not carry at all.
- **Fixes** — past tense, one sentence, symptom plus resolution, matching the observed corpus.

**Deliberately not added: "Upcoming change."** The sprint template defines it (`:ClockIcon:`, future
tense), but no generated destination exists for it, so `/release-notes` cannot route there and the
branch would be dead. A future-dated deprecation rides `breaking-changes`, which §1 already describes
as "usually announced before it ships."

Sourcing collapses from four rungs to two: `imported_change_type` when the import carries it (the
dev-phase re-run, after the dropdown is set), else infer from content for shaping. `change_type_hint`
and the authored-VI rung both lose their only source and are removed.

### 4. Low-confidence shape confirmation

`change_type` is the one dropped field whose answer changes the output, and the §3 shape contract
makes a wrong inference *more* expensive than it used to be: a mis-classification no longer puts a
wrong label on correctly-shaped prose, it emits a bare bullet where a titled section belonged (or the
reverse). The import removes the risk whenever the dropdown is already set; the exposed case is the
PM-phase run — `/create-vi` → paste → re-import → `/release-notes` — where nothing checks the guess.

So one confirmation survives, under tight conditions:

- **Never** when `imported_change_type` is present. The Jira field is authoritative; no prompt.
- **Never** when the inference is high-confidence.
- **Only** when the value was inferred *and* `release-notes-writer` reports low confidence — the same
  `field: change_type` / `recommended_action: "ask user"` gap that exists today.

**The prompt is reframed.** Today it presents the four bare Jira enum values
(`commands/release-notes.md:184-189`) — opaque labels whose plain-English meaning does not match their
routing behavior, which is what made it confusing. The replacement names the **consequence** of each
choice instead of the label:

```
This note reads like a <inferred type>, so the draft is shaped as <shape> and lands in <file>.
choices:
  - "<inferred type> — <shape>, in <file> (Recommended)"
  - "Feature update — titled section with a docs link, in feature-updates.md"
  - "Breaking change — titled section with remediation steps, in breaking-changes.md"
  - "Fix — one self-contained sentence, in fixes.md"
  - "Other… (describe)"
```

The chosen value drives the shape only. It never becomes a `Change type:` line in the draft, and it is
still the user's job to set the Jira dropdown — the prompt fires because the answer changes the
generated draft, not to collect a field.

The `Shaped as: <type> → <file>` report line (§2.2) stays regardless, so a high-confidence inference
that was nonetheless wrong is still visible without a prompt.

---

## Files changed

Paths are relative to `plugins/dev-workflows/` in the canonical repo.

| File | Change |
|---|---|
| `references/vi-format.md` | Move the three fields from the PM-authorable block (`:27-29`) to the Jira-mirror sentence (`:41-42`). |
| `references/release-note-types.md` | Rewrite per §3 — destination + shape authority; drop the §6 sourcing ladder to two rungs. |
| `references/handoff/release-notes-writer.md` | Drop `context_label_hint`, `change_type_hint`, `authored_vi_fields`, `release_versions` multiplication, and the `change_type_divergence` / `context_label` / `release_version` gaps; **keep** the `change_type` gap (§4); make `context_label` optional; add the conditional `fixes` shape. |
| `commands/create-vi.md` | Phase 3 step 1 (`:118`) — drop the three asks. |
| `commands/release-notes.md` | Phase 2 gate (`:100`); Phase 3 parse + `authored_vi_fields` resolution (`:130-140`); Phase 6 dispatch inputs (`:173-178`); **rewrite** the `change_type` prompt (`:184-189`) to the §4 consequence-framed form and delete the `deprecation`-adjacent divergence handling (`:261`); Phase 8 report lines (`:239-241`); Invariants (`:362-363`). |
| `agents/release-notes-writer.md` | Process steps 1, 2, 5, 6, 7; Hard rules (`:144-150`, `:164`); frontmatter `description`. |
| `agents/vi-reviewer.md` | Frontmatter check (`:23`) — drop `release_versions` requirement and the `change_type` enum/MINOR checks. |
| `README.md` | The `/create-vi` and `/release-notes` rows. |
| `CHANGELOG.md`, `.claude-plugin/plugin.json` | Minor version bump (2.41.0 → 2.42.0) + entry. |
| `CLAUDE.md` (repo root) | The `/release-notes` and VI-creation-flow key invariants that name `change_type` / `release_notes_category`. |

`agents/jira-reader.md` and `references/handoff/jira-reader.md` are **unchanged** — they surface the
imported fields verbatim, which is exactly what the new design consumes.

## Porting

| Repo | Effort | Notes |
|---|---|---|
| `ihudak-claude-plugins` | canonical | Implement here first. |
| `mgd-claude-plugins` | verbatim copy | `plugins/dev-workflows/` is byte-identical at 2.41.0 (verified with `diff -rq`). Copy the changed files; bump its own `plugin.json` + `CHANGELOG.md`. |
| `ihudak-copilot-plugins` | adapted | Same content, different layout: commands are `dev-workflows/skills/<name>/SKILL.md` (triggered by a `<name>:` prefix, not `/<name>`) and references are `dev-workflows/skills/_shared/<ref>.md`. Rewrite `${CLAUDE_PLUGIN_ROOT}/references/…` paths to `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/…`, and command mentions to the `name:` trigger form. Its `release-notes` skill carries the same line-for-line content (verified: worthiness check at `:102`, dispatch inputs at `:164-166`). |

## Verification

No test framework exists for prompt-and-reference content, so verification is by targeted grep plus
one end-to-end run:

1. `grep -rn "context_label_hint\|change_type_hint\|authored_vi_fields" plugins/dev-workflows/` returns
   nothing in all three repos.
2. `grep -rn "release_versions" plugins/dev-workflows/references/vi-format.md` shows it only in the
   Jira-mirror sentence.
3. No file still instructs the writer that `release_notes_category` may not be the `{{#context}}` label.
4. The only `choices:` block in `commands/release-notes.md` that mentions a change type is the §4
   shape confirmation, and every one of its options names a shape and a destination file — not a bare
   Jira enum value.
5. An end-to-end `/release-notes` run on a VI whose import carries `release_notes_category` **and**
   `change_type` produces a draft with a correct `{{#context}}` line, no `Change type:` line, exactly
   one Summary block, and **zero** questions.
6. An end-to-end run on a VI whose import lacks the category produces a draft with **no**
   `{{#context}}` line, and still asks nothing about it.
7. An end-to-end run on a VI whose import lacks `change_type` and whose content classifies
   high-confidence asks nothing; the same run with genuinely ambiguous content asks exactly once, via
   the §4 prompt.

## Rejected alternatives

- **Keep asking for `release_notes_category` in `/create-vi`.** Proposed first; the user rejected it
  on the grounds that the PM sets the Jira dropdown regardless, so the answer changes no downstream
  work. Correct — and the round-trip returns the value anyway.
- **Drop the `{{#context}}` line unconditionally.** Attractive if the automation generates it, but
  unproven; under the other hypothesis a published note loses its label. Source-or-omit is strictly
  better than today under both hypotheses and needs no proof.
- **Adopt the sprint template's four-type vocabulary** (`Breaking change` / `Upcoming change` /
  `Feature update` / `Fixes and maintenance`) as the plugin's Change Type enum. Rejected: that
  vocabulary belongs to the hand-authored sprint pages, while the Jira dropdown drives routing on the
  generated path. Its *prose rules* are adopted; its *enum* is not.
- **Infer the category silently and report it.** Rejected with the user: a wrong Solution ships into a
  customer-facing note, and the guess buys nothing the import does not provide for free.
- **Drop the `change_type` confirmation entirely**, relying on the `Shaped as:` report line to catch a
  wrong shape. Rejected: `change_type` is the one field that passes the "does the answer change the
  output" test, and the §3 shape contract raised the cost of a wrong inference — a mis-shaped draft
  needs a re-run or a hand-edit, which costs far more than one prompt. Narrower variants (confirm only
  when the inference lands on `fixes`, or on `fixes`/`breaking-changes`) were considered and rejected
  for the same reason: low confidence is the signal that matters, not which destination the guess
  happened to land on.

## Out of scope

The other three sub-projects from the same feedback session, each to be brainstormed separately:

- **B — `/document` gate enforcement.** Phase 6.4's mandatory style check, Phase 6.5's render
  verification, the repo's CHANGELOG and CONTRIBUTING rules, and an unverified `helm` command all
  failed on PRODUCT-17012. `git log -S` confirms both gate wordings have been in place since v2.0.0,
  so this is an enforcement problem, not a specification problem.
- **C — git completeness.** `/create-vi` offers git in Phase 5, then Phase 6 writes `resume.md` and
  Phase 7 writes cost and feedback files into the same folder; `feedback-emission.md` and
  `cost-emission.md` both state "NEVER commits." The late artifacts are untracked by construction, in
  roughly eight commands.
- **D — mechanical.** Namespacing next-step suggestions as `/dev-workflows:<command>` so a copy-paste
  cannot invoke a colliding command from another plugin, plus a README and workflow-diagram refresh
  covering `/update-vi` and `/idea --deep`.

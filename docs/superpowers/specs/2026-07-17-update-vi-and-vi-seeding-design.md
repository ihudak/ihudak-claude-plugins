# Design — VI update workflow (`/update-vi`), cross-VI seeding (`/create-vi --from-vi`), and a `/create-vi` self-contradiction check

- **Date:** 2026-07-17
- **Author:** Ivan Gudak
- **Status:** Shipped in dev-workflows v2.34.0 — pre-implementation design snapshot, kept as authored.
- **Plugin:** `dev-workflows` (repo `Dynatrace-Internal/mgd-claude-plugins`, `plugins/dev-workflows`, currently v2.33.0)
- **Motivating ticket:** PRODUCT-17753 (a VI authored at the wrong scope; the author needs to re-do it cleanly)

---

## 1. Context

`/create-vi` is the PM-phase authoring command that turns a refined `idea.md` + a user-supplied Jira key
into a **product-level** Value Increment (VI) markdown in `$SPECS_PATH`. It deliberately mounts **no
repos** and runs **no code scan**; its Opus `vi-reviewer` gate treats any implementation detail as a
`BLOCKER` ("product-level purity"). The VI is then pasted into Jira and re-imported to
`$VAULT_PATH/jira-products/<KEY>` so the downstream pipeline (`/create-ard` → `/specify` → `/design` →
`/implement`) can consume it.

Two real needs motivated this design:

1. **VIs get rewritten.** They are authored quickly, pasted to Jira, edited by many people in Jira, and
   sometimes need a substantive re-do (wrong scope, new information, or — rarely — an obstacle surfaced
   downstream). PRODUCT-17753 is a concrete instance: it was framed as an environment-level UI change
   for what is a cluster-level capability, and must be re-scoped.
2. **VIs cluster into families.** A large class of VIs are near-identical variations of an already-shipped
   one — the "techFit" pattern in OneAgent capability: *"implement support for Akka"*, *"…for Pekko"*,
   *"implement Lambda monitoring for .NET"*, *"…for Node.js"*, and so on. Authoring each from scratch
   wastes the structure already proven by its sibling.

The original brainstorm also explored a **downstream feasibility-validation loop** (having `/specify`
and `/create-ard` detect "this VI asks for something the code makes impossible" and push back to the PM).
That is **out of scope** — see §7.

### 1.1 Key correctness insight — Jira is the source of truth for a VI, not the specs draft

`/create-vi` writes the VI markdown to `$SPECS_PATH`, but that file is only the **initial draft**. Once
pasted into Jira, the VI is edited by people (and gains comments) in Jira, while the `$SPECS_PATH`
markdown stays frozen. Therefore **the authoritative, current VI lives in Jira**, surfaced locally as the
re-imported `$VAULT_PATH/jira-products/<KEY>` tree (VI body + `-comments.md`). Any workflow that consumes
an existing VI (updating it, or seeding a new one from it) must read the **Jira import first**, not the
frozen specs draft.

This is a **new, adjacent policy** to `references/source-truth.md`. That reference governs *code-vs-docs*
verification (the implementation is the truth for what shipped; a spec/Jira is the "intended" starting
point). The rule here governs *VI provenance* (which artifact holds the current VI text). They do not
conflict and must not be conflated; the new rule cross-references `source-truth.md` but lives on its own.

---

## 2. Goals / non-goals

**Goals**

- G1. A first-class, separate command for PM VI refresh/update: **`/update-vi <KEY>`**.
- G2. Cross-VI seeding for new VIs: **`/create-vi <NEW-KEY> --from-vi <VI>`**.
- G3. A product-level **self-contradiction** check in `/create-vi` (and shared with `/update-vi`).
- G4. A shared **Jira-import-first + freshness** resolution rule for consuming an existing VI.
- G5. Preserve VI revision history in-tree via **canonical + archive** file handling.

**Non-goals**

- N1. No downstream feasibility-validation/pushback machinery in `/specify` or `/create-ard` (§7).
- N2. No code scanning or repo mounting added to `/create-vi` or `/update-vi` (they stay product-level).
- N3. No agent-to-agent "PE/PA talks to PM" handoff. Humans discuss in Jira; the workflow only reads
  artifacts and comments.
- N4. No special-casing of the environment-vs-cluster (two product planes) problem — it was one example
  of a broader "not sensibly implementable" class, too rare to design machinery around.

---

## 3. Decisions (locked during the brainstorm)

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **Separate `/update-vi` command** (not an overload of `/create-vi`'s refine branch). | Update has distinct semantics: Jira-first source of truth, freshness check, multi-artifact grounding, versioned output. Keeps `/create-vi` clean greenfield. Shares grill/format/reviewer via references — no duplication. |
| D2 | **Keep the self-contradiction check (Scope A).** | Cheap, generic, always-on; catches a VI that fights itself; independent of the (dropped) feasibility concern. |
| D3 | **Canonical + archive** versioning. | `<KEY>_<slug>.md` always holds the latest so downstream reads one stable path; prior version snapshotted before overwrite so history is visible in-tree (beyond git). |
| D4 | **`/create-vi` positional stays the authored VI's own key** (Model 1). | Preserves today's contract (a VI needs its own key for the Jira round-trip). Seeds are flags; RFEs keep flowing through `/idea`. |
| D5 | **Drop the downstream feasibility loop (Scope B).** | Genuinely-infeasible VIs are a corner case; the *use case* is served by `/update-vi` reading the ARD/spec when a human decides a re-do is warranted. |
| D6 | **Jira-import-first + freshness** for consuming an existing VI (both `/update-vi` and `--from-vi`). | The specs draft is frozen; Jira holds the current VI. |
| D7 | **Frontmatter-based prior-VI detection** (`issue_type: ValueIncrement` in any `<KEY>_*.md`), not the literal filename. | On-disk VIs are `<KEY>_<slug>.md`; the current filename-only check misses them. |

---

## 4. Design

### 4.1 Shared rule — Jira-import-first resolution of an existing VI (G4, D6)

A single reusable resolution procedure, consumed by both `/update-vi` (its base VI) and
`/create-vi --from-vi` (its seed VI). Recommended home: a new reference
`references/vi-source-resolution.md` (or a section in `vi-format.md`), cross-referencing
`source-truth.md`.

Procedure for a given `<KEY>`:

1. **Look in the Jira import first:** `$VAULT_PATH/jira-products/<KEY>/…/<KEY>.md` (+ `<KEY>-comments.md`).
   Confirm `issue_type: ValueIncrement` in its frontmatter.
2. **Not imported →** stop and ask the user to import it (via the workitem-importer,
   `https://github.com/ivan-gudak/jira-workitem-import`), then re-run. Do not silently fall back to the
   specs draft.
3. **Imported but stale →** if the import file's mtime is older than **3 days**, show the import date and offer:
   `["Re-import now — I'll wait (Recommended)", "Proceed with the current import", "Cancel", "Other… (describe)"]`.
4. **Secondary grounding (read-only, never the base):** the frozen `$SPECS_PATH` specs draft (if any),
   any `*_ARD.md`, `specification.md`, and — for `/update-vi` — an optional user-supplied `@transcript`
   / notes path. These enrich the grill but do not override the Jira import as the authoritative VI text.

This rule is **product-level** — it reads markdown/comments only; no repos, no code scan.

### 4.2 New command — `/update-vi <KEY>` (G1, D1)

Purpose: PM refresh/re-do of an existing VI. Covers routine refreshes (new info, scope tweak, wording)
**and** the rare obstacle-driven re-do (a human read an ARD/spec finding, discussed it in Jira, and
decided the VI must change).

Phase outline (mirrors `/create-vi`'s structure; reuses its references and gate):

- **Phase 0 — Resolve input.** Parse `<KEY>` (validate `^[A-Z][A-Z0-9_]*-\d+$`). Resolve `$SPECS_PATH`
  and the feature folder (honor an existing `<KEY>-<slug>/`). Resolve the base VI via the §4.1
  Jira-import-first rule (import/freshness gate). Accept optional `@transcript` / notes path(s).
- **Phase 1 — Configure.** Confirm the feature folder + resolved base import (with its import date) +
  the secondary artifacts discovered (specs draft, ARD, spec, transcript). Choices per the plugin's
  `choices`-array convention (last entry `"Other… (describe)"`).
- **Phase 1.5 — Classify + model routing.** Invoke `dev-workflows:model-routing`; record the block
  (same shape as `/create-vi`). Grill + authoring inline on the Opus chain; `vi-reviewer` frontmatter-
  pinned.
- **Phase 2 — Read the base + grounding.** Read the Jira-import VI body + `-comments.md`; read the
  secondary artifacts. The comments and ARD/spec are the raw signal for *what to change*.
- **Phase 3 — Update via grill.** Relentless grill per `references/grilling-technique.md`, walking the
  `vi-format.md` spine, **diffing against the base** rather than authoring from a blank page: surface
  what changed and why, resolve open questions, apply the §4.4 self-contradiction check.
- **Phase 3.5 / 3.6 — Style check + structural pre-lint.** Same as `/create-vi` (dt-style-checker,
  `references/pre-lint.md`).
- **Phase 4 — Review gate.** `vi-reviewer` (Opus), same fix-cycle cap as `/create-vi`.
- **Phase 5 — Handoff (canonical + archive, see §4.3) + Jira round-trip reminder.** Re-paste the updated
  body into Jira and re-import — the same round-trip `/create-vi` documents, restated because an update
  otherwise silently diverges again.
- **Phase 6 — Next steps.** Guidance-only offers (e.g. re-run downstream `/create-ard` / `/specify` if
  they were already in flight). Per `references/next-phase-offer.md`.
- **Phase 7 — Session maintenance, feedback & cost.** Same terminal phase pattern as `/create-vi`
  (`impl-maintenance`, `feedback-emission`, `cost-emission`), with `command: /update-vi`.

`/update-vi` is **cwd-agnostic** and needs **no repos** (product-level), exactly like `/create-vi`.

### 4.3 Versioning — canonical + archive (G5, D3)

On a successful `/update-vi` handoff, before overwriting:

1. Snapshot the current canonical VI file to `<feature-folder>/revisions/<KEY>_<slug>_<YYYYMMDD>.md`
   (if two revisions land on the same day, suffix `-2`, `-3`, …).
2. Write the refreshed VI to the **canonical** path `<KEY>_<slug>.md` (where `<slug>` matches the
   `<KEY>-<slug>/` feature folder), so every downstream consumer keeps reading one stable path.
   Consumers locate it by globbing `<KEY>_*.md` and confirming frontmatter `issue_type: ValueIncrement`
   (robust to slug drift).
3. Record provenance in the refreshed VI's frontmatter: `revision_of` (the archived snapshot path) and
   the import date of the Jira base it was built from.

Git still records history; the in-tree `revisions/` snapshots give reviewers a diffable, human-visible
trail without a `git log` archaeology step.

### 4.4 `/create-vi` self-contradiction check (G3, D2)

A product-level internal-consistency check, shared by `/create-vi` and `/update-vi`:

- **`vi-reviewer` — new dimension "Internal consistency / non-contradiction."** Flags a VI that fights
  itself: an `[AC-N]` delivering `## Scope` **Out-of-scope** behaviour; a **Goal** asserting a different
  scope than `## Scope`; two `[US-N]` in direct conflict; an `[SM-N]` contradicting scope. Severity
  `MAJOR`, escalating to `BLOCKER` for a hard Goal-vs-Scope contradiction. This is **not** a feasibility
  or code check — purely "does the VI contradict itself".
- **Grill nudge** in `/create-vi` Phase 3 and `/update-vi` Phase 3: before writing each section, check it
  against already-settled sections; resolve inline, or record under `## Assumptions & open questions`.
- **`vi-format.md`** gains a one-line internal-consistency expectation so grill and reviewer share one
  authority.

### 4.5 `/create-vi --from-vi <VI>` cross-VI seeding (G2, D4)

- New flag **`--from-vi <KEY|path>`** on `/create-vi`. When present, the run authors a **new** VI
  (`<NEW-KEY>`, the positional) seeded read-only by `<VI>`.
- Resolve `<VI>` via the §4.1 Jira-import-first rule (a key → its Jira import; or an explicit path).
- The seed is **grounding, not content**: the grill *adapts* scope/personas/metrics/structure to the new
  VI's specifics; it never copies the source wholesale.
- Record the seed VI in a **dedicated `seeded_from_vi`** frontmatter field (the `<VI>` key or path);
  `derived_from` keeps its current meaning (the `idea.md` path). Backward-compatible with every
  existing VI.
- Composability: `--from-vi` may co-exist with `@idea.md`; both are seeds. `--from-vi` present ⇒ the
  new-from-seed path regardless of whether an existing VI exists for `<NEW-KEY>`.

### 4.6 `/create-vi` grammar + redirect (D4, D7)

- Positional = the authored VI's own key (unchanged).
- **Bare `/create-vi <KEY>` where a VI already exists** for `<KEY>` (detected by frontmatter
  `issue_type: ValueIncrement` in any `<KEY>_*.md`, or present in the Jira import) → **redirect**:
  recommend `/update-vi <KEY>` (guidance; offer to hand off). This keeps `/create-vi` = greenfield.
- **Bare `/create-vi <KEY>`, no VI yet** → new VI via the idea ladder (today's behaviour).
- **`/create-vi <KEY> --from-vi <VI>`** → new VI seeded by `<VI>` (§4.5).
- **Conflict case — `--from-vi` given but `<KEY>` already has a VI.** "Create new (seeded)" contradicts
  "a VI already exists here". Do not silently overwrite: surface the conflict and offer
  `["Update the existing <KEY> instead — /update-vi <KEY> (seed ignored) (Recommended)", "Overwrite <KEY> as a new seeded VI (archives the current one per §4.3)", "Cancel", "Other… (describe)"]`.
- Fix the prior-VI detection to be frontmatter-based (D7), replacing the filename-only check.

---

## 5. Files touched (blast radius)

**New**

- `commands/update-vi.md` — the `/update-vi` workflow (§4.2).
- `references/vi-source-resolution.md` — the Jira-import-first + freshness rule (§4.1). *(Or fold into
  `vi-format.md`; decide during design.)*
- `docs/specs/2026-07-17-update-vi-and-vi-seeding-design.md` — this document.

**Modified — feature edits**

- `commands/create-vi.md` — `--from-vi` + `seeded_from_vi` (§4.5), grammar + redirect (§4.6), grill
  self-contradiction nudge (§4.4), frontmatter-based prior-VI detection (D7).
- `agents/vi-reviewer.md` — the non-contradiction dimension (§4.4); invoked by both `/create-vi` and
  `/update-vi`.
- `references/vi-format.md` — internal-consistency expectation (§4.4); new `seeded_from_vi` field
  (§4.5); optionally the §4.1 rule if not a standalone reference.

**Modified — filename standardization ripple (`<KEY>_ValueIncrement.md` → `<KEY>_<slug>.md`, §6.1)**

- `commands/create-vi.md` (write + detect paths), `commands/create-ard.md` (Phase 2 VI read),
  `agents/vi-reviewer.md` (input-contract wording), `references/vi-format.md`, `references/pre-lint.md`
  (VI block), `references/ard-format.md` (the `derived_from` pointer to the VI), `README.md`. The
  historical `CHANGELOG.md` entry is **not** rewritten.

**Modified — manifests & docs (required, §6.5)**

- `.claude-plugin/plugin.json` — minor version bump (2.33.0 → 2.34.0); command count "Twenty" →
  "Twenty-one"; `/update-vi` added to the enumerated description + `keywords`.
- `.claude-plugin/marketplace.json` — update the enumerated command list/count (if it lists them).
- `README.md` — document `/update-vi` and `/create-vi --from-vi` (+ the filename note above).
- `CHANGELOG.md` — a new entry for the command + flags + reviewer dimension + filename standardization.

---

## 6. Open items to resolve during design/implementation

1. **Canonical VI filename — resolved: `<KEY>_<slug>.md`** (matches what's on disk; `<slug>` = the
   feature-folder slug). Prior-VI **detection is frontmatter-based** (`issue_type: ValueIncrement` in any
   `<KEY>_*.md`), robust to slug drift. This renames the currently-documented convention
   (`<KEY>_ValueIncrement.md`), so every reference is updated to `<KEY>_<slug>.md` — see §5's ripple
   list. The historical `CHANGELOG.md` entry is not rewritten; a new entry records the standardization.
2. **Freshness threshold** — **resolved: 3 days** (import mtime older than 3 days → show the import date
   and offer a re-import).
3. **`derived_from` shape — resolved:** add a dedicated **`seeded_from_vi`** field; `derived_from` is
   unchanged (the `idea.md` path). (§4.5)
4. **Reference placement** — standalone `references/vi-source-resolution.md` vs a section in
   `vi-format.md` (§4.1).
5. **Documentation currency (required, not optional).** The manifests and all documentation MUST be
   updated to match as part of this change: `plugin.json` (command count + enumerated list + `keywords`),
   `.claude-plugin/marketplace.json` (if it enumerates commands), `README.md`, `CHANGELOG.md`, and any
   other doc that lists commands or behaviour.
6. **Version bump — resolved: minor bump** (2.33.0 → 2.34.0), following the repo's release/CHANGELOG
   discipline.

---

## 7. Explicitly out of scope

- **Downstream feasibility-validation loop (former Scope B).** No named "VI infeasible/contradictory →
  push back to PM" escalation added to `/specify` or `/create-ard`; no reviewer changes there. Genuinely
  infeasible VIs are a corner case; when one is discovered, a human decides and runs `/update-vi` (which
  reads the ARD/spec that surfaced the obstacle). This keeps the pipeline forward-only and avoids
  agent-to-PM automation (N3).
- **Two-product-planes machinery.** No structured "operating context" element, no env-vs-cluster-specific
  detection. It was one example of a rare class, not a pattern worth dedicated tooling (N4).
- **Any code scanning in `/create-vi` / `/update-vi`.** Both stay product-level (N2).

---

## 8. Rollout / conventions

Implementation follows the repo's existing discipline: additive edits, the `choices`-array escalation
convention, the model-routing block, the terminal maintenance/feedback/cost phases, a version bump +
`CHANGELOG.md` entry + `README.md` + `plugin.json` (and `marketplace.json` if applicable) command-count
update, and the "commit only the intended files; branch + PR to `main`" flow (never `git add -A`; `main`
is protected). Commit trailer:
`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

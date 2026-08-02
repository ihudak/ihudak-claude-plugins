---
tags:
  - tasks-exclude
---
# Next-phase-offer-everywhere Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every pipeline command end with an adaptive, role-aware `### Next step` recommendation, backed by a single-source-of-truth reference (`references/next-phase-offer.md`), the same way `emit-block` is one SSOT wired into each command.

**Architecture:** One new reference file holds the routing graph + a 5-rule offer contract. The six pipeline commands that lack a forward handoff get a `### Next step` section in their Final Report (+ an invariant bullet where an `## Invariants` trailer exists). The three reference commands (`/idea`, `/create-vi`, `/create-ard`) are retrofitted to cite the SSOT; `/create-vi` also gains a content change (PE → `/epics` handoff). Manifests bump version only (no new command/subagent). Purely additive — direct/doc-edit modes omit the offer, so those runs stay byte-identical; `/vuln` + `/upgrade` are untouched.

**Tech Stack:** Markdown command/agent/reference files + JSON manifests. NO test framework, NO husky/prettier hook — verification is STRUCTURAL (grep anchors, `python3 -c json.load`, `git diff --stat`, byte-diff).

## Global Constraints

- Target repo: `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`.
- Version lock-step: `plugins/dev-workflows/.claude-plugin/plugin.json` **and** the `dev-workflows` entry in root `.claude-plugin/marketplace.json` both go `2.18.0` → `2.19.0`.
- Manifest descriptions stay **byte-identical except the version is not in them** — no new command/subagent, so the "Nineteen slash commands" / "Twenty-nine reusable subagents" text is unchanged (do NOT edit the description strings).
- Commit trailer, exactly: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Never `git add -A`** — stage only the named files in each commit.
- Commit / push only when the user asks. This plan commits locally per task; the finish-branch step presents merge/PR options. Do NOT push.
- Branch `ivgu/NOISSUE-next-phase-offer`; ff-merge to `main`; delete branch.
- No user name in any file.
- Sibling plugins `dt-style-guide` (0.2.2) + `obsidian-llm-wiki` (0.3.1) — untouched.
- `### Next step` is **guidance-only** (never auto-invokes) and **omitted in direct / doc-edit mode**.
- The offer routing (verbatim from the spec):
  - PM: `/idea` → `/create-vi`; `/create-vi` → `/release-notes` (recommended) + PA `/create-ard` (optional) + PE `/epics`.
  - PA: `/create-ard <VI>` → PE `/epics`|`/specify <VI>` (no `/design`); `/create-ard <VI> <Epic>` → `/specify <VI> <Epic>`|`/design`.
  - PE: `/specify <VI>` → `/epics`; `/epics` → `/specify <VI> <Epic>`; `/specify <VI> <Epic>` → `/design`.
  - Team: `/design` → `/implement`; `/implement` → finish Epics then `/document` → `/release-notes`; `/document` → `/release-notes`; `/release-notes` → leaf/closure.
  - Epic fan-out (depth + breadth) applies to per-Epic commands only (`/create-ard <VI> <Epic>`, `/specify <VI> <Epic>`, `/design`, `/implement`). `/document` + `/release-notes` are VI-level, run once after all Epics implemented.

---

### Task 1: Branch + the next-phase-offer SSOT reference

**Files:**
- Create: `plugins/dev-workflows/references/next-phase-offer.md`

**Interfaces:**
- Produces: the reference path `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`, cited verbatim by all later tasks.

- [ ] **Step 1: Confirm clean tree + create the branch**

```bash
cd /workspace/ihudak-claude-plugins
git status --porcelain   # expect empty
git checkout main && git checkout -b ivgu/NOISSUE-next-phase-offer
```
Expected: on a new branch `ivgu/NOISSUE-next-phase-offer`, clean tree.

- [ ] **Step 2: Create the SSOT reference file**

Create `plugins/dev-workflows/references/next-phase-offer.md` with EXACTLY:

```markdown
# Next-phase offer (embedded — shared reference)

The plugin-wide contract for the **next-phase offer**: the guidance every pipeline command
surfaces at the end of its run, naming the natural next command(s). Cited by all pipeline
commands so the routing graph and the offer rules live in ONE place (the same shape as
`emit-block` in `feedback-emission.md`).

## The offer contract (5 rules)

1. **Guidance-only** — the offer NAMES the next command(s); it NEVER auto-invokes anything.
2. **Role-labeled** — it names the concrete command(s) for the next step, tagged with the owning
   role (PM / PA / PE / Team), even on a handoff — one person may wear several hats and just keep
   going. Never a bare "hand off to PA".
3. **Adaptive to outcome** — a clean run points forward; a BLOCK / incomplete / cancelled run
   recommends resolving THAT first, not advancing.
4. **Mode-aware** — the forward recommendation is a PIPELINE handoff. In a command's direct /
   ad-hoc mode (no VI/Epic context — `/implement` direct, `/document` doc-edit) it is OMITTED,
   not invented.
5. **Epic fan-out** — a command operating at **Epic scope** offers TWO branches:
   - **Depth** — the next command for the SAME Epic (`/design <VI> E1` → `/implement <VI> E1`).
   - **Breadth** — the SAME command for the NEXT Epic under the VI (`/design <VI> E1` →
     `/design <VI> E2`).

   So a team can go `/design E1 → /design E2 → /implement E1 → /implement E2` OR
   `/design E1 → /implement E1 → /design E2 …` — their call. Applies to the per-Epic commands
   only: `/create-ard <VI> <Epic>`, `/specify <VI> <Epic>`, `/design <VI> <Epic>`,
   `/implement <VI> <Epic>`. `/document` and `/release-notes` are VI-level (whole-feature, run
   once after ALL Epics are implemented) and do NOT fan out.

## Surface

The universal minimum is an adaptive **`### Next step`** section at the END of the command's
Final Report (guidance-only prose). A command MAY additionally present a richer interactive
`choices:` offer (the reference commands `/idea`, `/create-vi`, `/create-ard` do) — compatible,
not required.

## The routing graph (role-aware)

**PM — ideation & framing**

- `/idea` — refined → `/create-vi <JIRA-KEY>` (PM); draft → `/idea @<path> --deep` (PM, refine)
  or `/create-vi <JIRA-KEY>` (PM, proceed on a draft — not recommended).
- `/create-vi <JIRA-KEY>` — after the paste-into-Jira + re-import round-trip:
  `/release-notes <VI>` (PM — draft the release note; recommended clear next step); hand to PA
  *(optional)* → `/create-ard <VI>`; or hand to PE → `/epics <VI>` (or `/specify <VI>`).

**PA — architecture (optional)**

- `/create-ard <VI>` (VI-level) → PE → `/epics <VI>` (recommended) or `/specify <VI>`.
  *(No `/design` — no Epics yet.)*
- `/create-ard <VI> <Epic>` (Epic-level) → `/specify <VI> <Epic>` (recommended) or Team →
  `/design <VI> <Epic>`.

**PE — breakdown & specification**

- `/specify <VI>` (VI-level spec) → `/epics <VI>`.
- `/epics <VI>` → `/specify <VI> <Epic>` (per Epic); optional PA → `/create-ard <VI> <Epic>`.
- `/specify <VI> <Epic>` (Epic-level spec) → Team → `/design <VI> <Epic>`.

**Team/Dev — build**

- `/design <VI> <Epic>` → `/implement <VI> <Epic>`.
- `/implement <VI> <Epic>` → finish remaining Epics (breadth); once ALL Epics implemented →
  `/document <VI>` → `/release-notes <VI>`. *(Direct mode → no forward offer.)*
- `/document <VI>` (VI-level, after all Epics) → `/release-notes <VI>`. *(Doc-edit mode → no
  forward offer.)*
- `/release-notes <VI>` (VI-level) → leaf/closure: release note drafted; continue any pending
  PA/PE phase, else the VI is fully processed.

## Not pipeline nodes

`/vuln`, `/upgrade`, `/feedback`, `/prompt*`, `/docs-profile`, `/statusline`, and the reviewer
commands are NOT part of the linear VI→docs pipeline and carry no next-phase offer.
```

- [ ] **Step 3: Verify the file structurally**

```bash
cd /workspace/ihudak-claude-plugins
grep -c "^## " plugins/dev-workflows/references/next-phase-offer.md   # expect 5 (contract, surface, graph, not-pipeline, + title is #)
grep -n "Epic fan-out\|Guidance-only\|Mode-aware\|routing graph" plugins/dev-workflows/references/next-phase-offer.md
```
Expected: the four `## ` sections present (`## The offer contract`, `## Surface`, `## The routing graph`, `## Not pipeline nodes`) → `grep -c "^## "` returns 4; the keyword grep prints matching lines.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/next-phase-offer.md
git commit -m "feat(dev-workflows): add next-phase-offer SSOT reference

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Wire the `### Next step` into the six pipeline targets

**Files:**
- Modify: `plugins/dev-workflows/commands/specify.md` (Final report, ~line 483)
- Modify: `plugins/dev-workflows/commands/design.md` (Final report, ~lines 378-381)
- Modify: `plugins/dev-workflows/commands/implement.md` (Phase 5 report block ~line 580; Invariants ~line 654)
- Modify: `plugins/dev-workflows/commands/document.md` (Jira report block ~line 940; Invariants ~line 1014 — Mode A only; leave Mode B doc-edit report ~1250-1286 untouched)
- Modify: `plugins/dev-workflows/commands/epics.md` (Phase 9 report block ~line 464; Invariants ~line 536)
- Modify: `plugins/dev-workflows/commands/release-notes.md` (Phase 8 report block ~line 205; Invariants ~line 307)

**Interfaces:**
- Consumes: the reference path from Task 1.
- Produces: a `### Next step` anchor in each of the six files, and a next-step invariant bullet in the four with an `## Invariants` trailer.

- [ ] **Step 1: Re-confirm the anchors are current before editing**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n 'run `/implement <VI> <Epic>` next' commands/design.md
grep -n "Published: yes\` is a human-only freeze step" commands/specify.md
grep -n "ALWAYS produce the Phase 5 report as the final output" commands/implement.md
grep -n "ALWAYS produce the Phase 9 report as the final output" commands/document.md commands/epics.md
grep -n "does not commit in non-git contexts" commands/document.md
grep -n "never commits — git management is your responsibility" commands/epics.md
grep -n "emits it into dynatrace-docs" commands/release-notes.md
grep -n "Light gate only — no Opus review" commands/release-notes.md
```
Expected: each anchor prints exactly one line. If any differs, STOP and re-capture — the file changed since this plan was written.

- [ ] **Step 2: `specify.md` — append `### Next step` to the Final report**

Replace:
```
Report: feature-folder path; stage/user-story/AC/TC counts; open-question count; unmounted-repo advisories; the `spec-reviewer` verdict; the PR URL (if opened); and a reminder of the round-trip described above + that `Published: yes` is a human-only freeze step.
```
With:
```
Report: feature-folder path; stage/user-story/AC/TC counts; open-question count; unmounted-repo advisories; the `spec-reviewer` verdict; the PR URL (if opened); and a reminder of the round-trip described above + that `Published: yes` is a human-only freeze step.

### Next step

End the report with a `### Next step` recommendation per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` (guidance only — never auto-invoked): **Epic-level spec** (`<VI> <Epic>`) → hand to the team → `/design <VI> <Epic>`, and the **Epic fan-out** `/specify <VI> <another-Epic>` for a sibling Epic (breadth); **VI-level spec** (`<VI>` only) → `/epics <VI>` (PE). If the run BLOCKED or left open `- [ ]` items, recommend resolving those first.
```

- [ ] **Step 3: `design.md` — swap the trailing clause for a `### Next step`**

Replace:
```
Report: feature-folder path; classification + model-gate outcome; `design.md` sections authored (and
those `_N/A_`); spec challenges recorded (count of `## Engineering review` notes / new spec `- [ ]`);
confirmed repo set (and any removed-from-scope); the `design-reviewer` verdict; the PR URL (if opened);
and "run `/implement <VI> <Epic>` next."
```
With:
```
Report: feature-folder path; classification + model-gate outcome; `design.md` sections authored (and
those `_N/A_`); spec challenges recorded (count of `## Engineering review` notes / new spec `- [ ]`);
confirmed repo set (and any removed-from-scope); the `design-reviewer` verdict; the PR URL (if opened);
and the `### Next step` recommendation (below).

### Next step

End the report with a `### Next step` recommendation per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` (guidance only — never auto-invoked): hand to the team → `/implement <VI> <Epic>` (depth); the **Epic fan-out** `/design <VI> <another-Epic>` designs a sibling Epic (breadth). If the run BLOCKED or `design.md` has open questions, recommend resolving those first.
```

- [ ] **Step 4: `implement.md` — `### Next step` in the Phase 5 report + invariant bullet**

Replace:
```
### Deferred items (from review or tests)
- [MINOR / NIT findings that were not applied] OR "none"
```
```
With:
```
### Deferred items (from review or tests)
- [MINOR / NIT findings that were not applied] OR "none"

### Next step
[Per `references/next-phase-offer.md` — guidance only, never auto-invoked. Jira mode: finish the remaining Epics under the VI (breadth) — `/implement <VI> <another-Epic>` — and, once **all** Epics are implemented, `/document <VI>` then `/release-notes <VI>` (both VI-level, run once). Depth vs breadth is the team's call. Direct mode: no forward pipeline step (omit). If review is still BLOCK, resolve that first.]
```
```
(The closing ``` ` in the block is preserved by both the old and new strings.)

Then replace:
```
- ALWAYS produce the Phase 5 report as the final output
```
With:
```
- ALWAYS produce the Phase 5 report as the final output
- ALWAYS end the Phase 5 report with a `### Next step` recommendation (per `references/next-phase-offer.md`) — guidance only, never auto-invoked; omitted in direct mode (no VI/Epic pipeline context)
```

- [ ] **Step 5: `document.md` — `### Next step` in the Jira report + invariant bullet (Mode A only)**

Replace:
```
### Git state
[When Phase 8.5 ran: "Branch <name> — squashed to N commit(s); pushed to origin: <yes/no>; PR draft: <pr-draft path>." When Phase 8.5 was skipped (no branch/commits): "Working tree has uncommitted changes. /document (Jira mode) writes but does not commit in non-git contexts."]
```
```
With:
```
### Git state
[When Phase 8.5 ran: "Branch <name> — squashed to N commit(s); pushed to origin: <yes/no>; PR draft: <pr-draft path>." When Phase 8.5 was skipped (no branch/commits): "Working tree has uncommitted changes. /document (Jira mode) writes but does not commit in non-git contexts."]

### Next step
[Per `references/next-phase-offer.md` — guidance only, never auto-invoked. Once **all** the VI's Epics are documented, draft/finalize the release note → `/release-notes <VI>` (VI-level; run once, not per Epic). If the review BLOCKED, resolve that first.]
```
```

Then replace (this exact line appears once in `document.md`, at ~1014 — the Mode A Invariants):
```
- ALWAYS produce the Phase 9 report as the final output
```
With:
```
- ALWAYS produce the Phase 9 report as the final output
- ALWAYS end the Phase 9 report with a `### Next step` recommendation (per `references/next-phase-offer.md`) — guidance only, never auto-invoked; omitted in direct doc-edit mode (Mode B)
```
Do NOT touch the Mode B doc-edit report (`## Doc-edit Report`, ~lines 1250-1286) — direct mode omits the offer.

- [ ] **Step 6: `epics.md` — `### Next step` in the Phase 9 report + invariant bullet**

Replace:
```
### Git state
The project root has uncommitted changes. `/epics` never commits — git management is your responsibility.
```
```
With:
```
### Git state
The project root has uncommitted changes. `/epics` never commits — git management is your responsibility.

### Next step
[Per `references/next-phase-offer.md` — guidance only, never auto-invoked. For each Epic just drafted, author its spec → `/specify <VI> <Epic>` (PE); the **Epic fan-out** (depth vs breadth) applies from the spec/design stage on. Optionally a Product Architect adds an Epic-level ARD first → `/create-ard <VI> <Epic>`. If the review BLOCKED, resolve that first.]
```
```

Then replace (this exact line appears once in `epics.md`, at ~536):
```
- ALWAYS produce the Phase 9 report as the final output
```
With:
```
- ALWAYS produce the Phase 9 report as the final output
- ALWAYS end the Phase 9 report with a `### Next step` recommendation (per `references/next-phase-offer.md`) — guidance only, never auto-invoked
```

- [ ] **Step 7: `release-notes.md` — `### Next step` in the Phase 8 report + invariant bullet**

Replace (note the 3-space indentation — the block sits under a numbered list item):
```
   - Reminder: paste this into the ticket's Jira release-notes field — the docs automation adds the {{#internal-note}} metadata and emits it into dynatrace-docs.
   ```
```
With:
```
   - Reminder: paste this into the ticket's Jira release-notes field — the docs automation adds the {{#internal-note}} metadata and emits it into dynatrace-docs.

   ### Next step
   [leaf/closure per `references/next-phase-offer.md` — guidance only, never auto-invoked: the release note is drafted. If earlier pipeline phases remain, continue — hand to PA → `/create-ard <VI>` or PE → `/epics <VI>`; if the change is already built and documented, the VI is fully processed.]
   ```
```

Then replace:
```
- Light gate only — no Opus review, no tests, no branch, no commit.
```
With:
```
- Light gate only — no Opus review, no tests, no branch, no commit.
- ALWAYS end the Phase 8 report with a `### Next step` recommendation (per `references/next-phase-offer.md`) — guidance only, never auto-invoked; the pipeline leaf (adaptive: continue any pending PA/PE phase, else the VI is fully processed).
```

- [ ] **Step 8: Verify all six structurally**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "=== ### Next step present in all 6 ==="
grep -c "^### Next step\|^   ### Next step" commands/specify.md commands/design.md commands/implement.md commands/document.md commands/epics.md commands/release-notes.md
echo "=== SSOT cited in all 6 ==="
grep -l "references/next-phase-offer.md" commands/specify.md commands/design.md commands/implement.md commands/document.md commands/epics.md commands/release-notes.md
echo "=== invariant bullet in the 4 with a trailer ==="
grep -c "end the Phase . report with a \`### Next step\`\|end the Phase 5 report with a\|end the Phase 8 report with a\|end the Phase 9 report with a" commands/implement.md commands/document.md commands/epics.md commands/release-notes.md
echo "=== Mode B doc-edit report NOT given a next step (should be 1 total in document.md: only the Mode A one) ==="
grep -c "### Next step" commands/document.md
```
Expected: `### Next step` count is 1 per file for the six; the SSOT `grep -l` lists all six filenames; the invariant bullet appears once each in implement/document/epics/release-notes; `document.md` has exactly **1** `### Next step` (Mode A only — Mode B untouched).

- [ ] **Step 9: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md plugins/dev-workflows/commands/implement.md plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/release-notes.md
git commit -m "feat(dev-workflows): wire ### Next step into the 6 pipeline targets

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Retrofit the three reference commands to the SSOT

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (Phase 5, ~lines 133-135)
- Modify: `plugins/dev-workflows/commands/create-vi.md` (Phase 6 heading ~134, intro ~136, choices ~139, bullets ~142-145; Final report ~165) — **content change**
- Modify: `plugins/dev-workflows/commands/create-ard.md` (Phase 7, ~lines 115-119)

**Interfaces:**
- Consumes: the reference path from Task 1.
- Produces: an SSOT citation in each of the three; `/create-vi` gains the PE → `/epics` handoff.

- [ ] **Step 1: `idea.md` — cite the SSOT, drop the stale "future sub-project" note**

Replace:
```
`/create-vi` is a separate command (future sub-project); this offer is guidance the user acts on — it
never auto-invokes another command. (`/idea` is the reference implementation of the plugin-wide
next-phase-offer pattern.)
```
With:
```
`/create-vi` is a separate command; this offer is guidance the user acts on — it never auto-invokes
another command. (Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — the plugin-wide
next-phase-offer contract; `/idea` is one reference implementation.)
```

- [ ] **Step 2: `create-vi.md` — heading**

Replace:
```
## Phase 6 — Next steps (two, parallel)
```
With:
```
## Phase 6 — Next steps
```

- [ ] **Step 3: `create-vi.md` — intro line**

Replace:
```
Offer **both** — clearly labeling the role handoff:
```
With:
```
Offer these — clearly labeling the role handoff:
```

- [ ] **Step 4: `create-vi.md` — the choices array (add PE → /epics; mark recommended/optional)**

Replace:
```
choices: ["Draft the initial release note now — /release-notes <KEY> (PM)", "Hand off to a Product Architect — /create-ard <KEY> (PA)", "Stop here", "Other… (describe)"]
```
With:
```
choices: ["Draft the release note now — /release-notes <KEY> (PM) (Recommended)", "Hand to a Product Architect — /create-ard <KEY> (PA, optional)", "Hand to a Product Engineer — /epics <KEY> (PE)", "Stop here", "Other… (describe)"]
```

- [ ] **Step 5: `create-vi.md` — the bullets + SSOT citation**

Replace:
```
- **`/release-notes <KEY>`** — the PM can draft the customer-facing release note now (the cost model's `pm`/`vi-creation` inferred case: no spec/design yet).
- **`/create-ard <KEY>`** — a **different role/session** (Product Architect) authors the grounded architecture document (`/create-ard` is sub-project 3).

Guidance only — this never auto-invokes another command.
```
With:
```
- **`/release-notes <KEY>`** (PM) — draft the customer-facing release note now (the cost model's `pm`/`vi-creation` inferred case: no spec/design yet).
- **`/create-ard <KEY>`** (PA, **optional**) — hand to a Product Architect to author the grounded architecture document.
- **`/epics <KEY>`** (PE) — hand to a Product Engineer to split the VI into Epics (or author a VI-level spec → `/specify <KEY>`).

Guidance only — never auto-invokes another command. Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.
```

- [ ] **Step 6: `create-vi.md` — Final report ("two" → "the")**

Replace:
```
Report: the VI path + profile; US/AC/SM counts + which adapt-in clusters were included; open-question count; the `vi-reviewer` verdict; the PR URL (if opened); the Jira round-trip reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; and the two next-step recommendations.
```
With:
```
Report: the VI path + profile; US/AC/SM counts + which adapt-in clusters were included; open-question count; the `vi-reviewer` verdict; the PR URL (if opened); the Jira round-trip reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; and the next-step recommendations.
```

- [ ] **Step 7: `create-ard.md` — role labels + Epic fan-out + SSOT citation**

Replace:
```
## Phase 7 — Next-step offer (adaptive)
- **VI-level ARD:** if the VI has 0 Epics → `choices: ["Split into Epics — /epics <VI> (then create them in Jira + re-import) (Recommended)", "Author a spec — /specify", "Stop here", "Other… (describe)"]`; else offer `/specify`.
- **Epic-level ARD:** `choices: ["Author the spec — /specify <VI> <Epic> (Recommended)", "Design it — /design <VI> <Epic>", "Stop here", "Other… (describe)"]`.

Guidance only — never auto-invokes another command.
```
With:
```
## Phase 7 — Next-step offer (adaptive)
- **VI-level ARD:** if the VI has 0 Epics → `choices: ["Hand to a Product Engineer — /epics <VI> (then create them in Jira + re-import) (PE) (Recommended)", "Author a VI-level spec — /specify <VI> (PE)", "Stop here", "Other… (describe)"]`; else offer `/specify <VI>` (PE). *(No `/design` — no Epics yet.)*
- **Epic-level ARD:** `choices: ["Author the spec — /specify <VI> <Epic> (PE) (Recommended)", "Hand to the team — /design <VI> <Epic> (Team)", "Stop here", "Other… (describe)"]`. **Epic fan-out** — repeat this ARD for a sibling Epic: `/create-ard <VI> <another-Epic>`.

Guidance only — never auto-invokes another command. Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.
```

- [ ] **Step 8: Verify the three structurally**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "=== SSOT cited in all 3 references ==="
grep -l "references/next-phase-offer.md" commands/idea.md commands/create-vi.md commands/create-ard.md
echo "=== create-vi has the PE /epics handoff + optional/recommended tags ==="
grep -n "Hand to a Product Engineer — /epics" commands/create-vi.md
grep -n "(PM) (Recommended)\|(PA, optional)" commands/create-vi.md
echo "=== create-vi no longer says 'two, parallel' or 'two next-step' ==="
grep -c "two, parallel\|the two next-step" commands/create-vi.md   # expect 0
echo "=== create-ard VI-level still omits /design ==="
grep -n "No \`/design\` — no Epics yet" commands/create-ard.md
```
Expected: `grep -l` lists all three; the PE handoff + tags print; the "two" grep returns 0; the create-ard no-`/design` note prints.

- [ ] **Step 9: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/create-ard.md
git commit -m "feat(dev-workflows): retrofit /idea, /create-vi, /create-ard to the next-phase-offer SSOT

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Version bump + CHANGELOG + README + final no-regression sweep

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json:3`
- Modify: `.claude-plugin/marketplace.json:12`
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend, before `## [2.18.0]`)
- Modify: `plugins/dev-workflows/README.md` (line 3 lead count NOT changed; `/create-vi` row ~16; new note after the table ~19)

**Interfaces:**
- Consumes: everything from Tasks 1-3 (the whole feature must be present for the final sweep).

- [ ] **Step 1: Bump `plugin.json` version**

Replace (in `plugins/dev-workflows/.claude-plugin/plugin.json`):
```
  "version": "2.18.0",
```
With:
```
  "version": "2.19.0",
```

- [ ] **Step 2: Bump the `dev-workflows` version in `marketplace.json`**

Replace (in root `.claude-plugin/marketplace.json` — this string is unique to the dev-workflows entry at line 12):
```
      "version": "2.18.0",
```
With:
```
      "version": "2.19.0",
```

- [ ] **Step 3: Prepend the CHANGELOG entry**

In `plugins/dev-workflows/CHANGELOG.md`, replace:
```
## [2.18.0] — 2026-07-10
```
With:
```
## [2.19.0] — 2026-07-10

### Added

- **Every pipeline command now ends with an adaptive `### Next step` recommendation.** The end-of-run next-phase offer — previously only in `/idea`, `/create-vi`, `/create-ard` — is now a plugin-wide invariant backed by a new single-source-of-truth reference, `references/next-phase-offer.md` (the role-aware routing graph + a 5-rule contract: guidance-only / role-labeled / adaptive-to-outcome / mode-aware / Epic fan-out). The six pipeline commands that lacked it — `/specify`, `/design`, `/implement`, `/document`, `/epics`, `/release-notes` — now close their Final Report with a `### Next step` section naming the next command(s) tagged with the owning role (PM / PA / PE / Team), so a multi-hat user just keeps going. **Epic fan-out:** the per-Epic commands (`/create-ard <VI> <Epic>`, `/specify <VI> <Epic>`, `/design`, `/implement`) offer both depth (next command, same Epic) and breadth (same command, next Epic); `/document` + `/release-notes` are VI-level and run once after all Epics are implemented. The three reference commands are retrofitted to cite the SSOT; `/create-vi` also gains the PE → `/epics` handoff (and marks `/release-notes` recommended, `/create-ard` optional). **Strictly no-regression / additive:** the `### Next step` only *adds* a report section, and it is omitted in a command's direct / doc-edit mode (no VI/Epic pipeline context), so those runs are byte-identical. `/vuln` and `/upgrade` are not pipeline nodes and are untouched. No new command or subagent (version-only manifest bump — Nineteen commands / Twenty-nine subagents unchanged). Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched. **Follow-up:** revisit the `.obsidian/` vault-check.

## [2.18.0] — 2026-07-10
```

- [ ] **Step 4: README — update the `/create-vi` next-steps sentence**

In `plugins/dev-workflows/README.md`, replace:
```
Offers `/release-notes` and `/create-ard` as next steps. |
```
With:
```
Offers `/release-notes`, `/create-ard`, and `/epics` as next steps (per `references/next-phase-offer.md`). |
```

- [ ] **Step 5: README — add the plugin-wide next-step note after the commands table**

In `plugins/dev-workflows/README.md`, replace:
```
**Which docs command?** `/document` (direct mode) is for one-shot manual doc edits (no Jira, no branch/commit). `/document` (Jira mode) is the Jira-driven feature-documentation workflow end to end (resolves repos/specs, writes into the docs repo, branches/commits, and — opt-in — squashes, pushes, and drafts a PR). `/docs-profile` is a one-time profiler that generates a repo's `.dev-workflows/docs-profile.yml` (consumed by `/document` Jira mode).
```
With:
```
**Next-step guidance.** Every pipeline command ends its report with an adaptive `### Next step` recommendation naming the next command(s) and the owning role (PM / PA / PE / Team) — guidance only, never auto-invoked; omitted in a command's direct / doc-edit mode. The role-aware routing graph lives in `references/next-phase-offer.md`.

**Which docs command?** `/document` (direct mode) is for one-shot manual doc edits (no Jira, no branch/commit). `/document` (Jira mode) is the Jira-driven feature-documentation workflow end to end (resolves repos/specs, writes into the docs repo, branches/commits, and — opt-in — squashes, pushes, and drafts a PR). `/docs-profile` is a one-time profiler that generates a repo's `.dev-workflows/docs-profile.yml` (consumed by `/document` Jira mode).
```

- [ ] **Step 6: Verify manifests parse + versions match + descriptions unchanged**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; d=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); assert d['version']=='2.19.0', d['version']; assert 'Nineteen slash commands' in d['description']; assert 'Twenty-nine reusable subagents' in d['description']; print('plugin.json OK', d['version'])"
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); e=[p for p in m['plugins'] if p['name']=='dev-workflows'][0]; assert e['version']=='2.19.0', e['version']; print('marketplace OK', e['version'])"
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); d=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); e=[p for p in m['plugins'] if p['name']=='dev-workflows'][0]; assert e['description']==d['description'], 'DESCRIPTIONS DIFFER'; print('descriptions byte-identical')"
```
Expected: three OK lines; no assertion errors.

- [ ] **Step 7: Final no-regression sweep**

```bash
cd /workspace/ihudak-claude-plugins
echo "=== /vuln + /upgrade untouched (expect empty) ==="
git diff --stat main -- plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md
echo "=== sibling plugins untouched (expect empty) ==="
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki
echo "=== command + subagent counts unchanged ==="
ls plugins/dev-workflows/commands/ | wc -l   # expect 19
ls plugins/dev-workflows/agents/ | wc -l     # expect 29
echo "=== full change surface ==="
git diff --stat main
```
Expected: the vuln/upgrade and sibling diffs are empty; counts 19 / 29; the `git diff --stat main` lists exactly the new reference, the 9 command files, plugin.json, marketplace.json, CHANGELOG.md, README.md (13 files).

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md
git commit -m "chore(dev-workflows): v2.19.0 — manifests, CHANGELOG, README for next-phase-offer

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## After all tasks

Announce and run **superpowers:finishing-a-development-branch**. There is no test suite — structural verification (grep anchors, `python3 json.load`, `git diff --stat`) stands in for tests and is green. Present the merge/PR options and let the user choose; do NOT push unless the user asks.

## Self-review (author checklist — completed)

- **Spec coverage:** SSOT reference (Task 1) ✓; 6 targets `### Next step` + invariant bullets (Task 2) ✓; 3 reference retrofits incl. `/create-vi` content change (Task 3) ✓; version lock-step + CHANGELOG + README (Task 4) ✓; no-regression (vuln/upgrade + sibling byte-diff, direct-mode omit) verified in Task 4 Step 7 + Task 2 Step 8 ✓; Epic fan-out encoded in the SSOT + the per-Epic command offers ✓.
- **Placeholders:** none — every edit shows exact old/new text; `[...]` inside report templates is the commands' own fill-in-at-runtime convention (matches existing `### Git state` / `### Deferred items` style), not a plan placeholder.
- **Consistency:** the SSOT path `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` (or repo-relative `references/next-phase-offer.md` in invariant bullets, matching the existing emit-block bullet style) is used identically across tasks; `### Next step` heading text is uniform; version `2.19.0` and counts (19 / 29) are consistent throughout.

---
tags:
  - tasks-exclude
---

# Next-phase-offer-everywhere — Design (dev-workflows v2.19.0)

**Status:** Shipped in dev-workflows v2.19.0 — pre-implementation design snapshot, kept as authored.
**Date:** 2026-07-10
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Version:** 2.18.0 → 2.19.0 (feature; no new command/subagent)

## Goal

Generalize the end-of-command "here's the next step" handoff — already present in
`/idea`, `/create-vi`, `/create-ard` — to every pipeline command that lacks it
(`/specify`, `/design`, `/implement`, `/document`, `/epics`, `/release-notes`), as a
**cross-cutting invariant** backed by a single-source-of-truth reference (the same
shape as the `emit-block` invariant: one SSOT + a short wired-in bullet per command).

## Motivation

The user loves the next-phase offer and asked for it "at the end of each command."
Today six pipeline commands end at their Final Report with **no forward handoff**, so
the user has to remember the pipeline graph themselves. The three reference commands
prove the pattern; this effort makes it universal and role-aware, and puts the routing
graph in one place instead of scattering it across command files.

## The routing graph (role-aware)

**Cross-cutting rule:** every offer **names the concrete command(s)** for the next
step, tagged with the **role** that owns it (PM / PA / PE / Team) — even when it's a
handoff — because one person may wear several hats and can just keep going. Never a
bare "hand off to PA."

**PM — ideation & framing**

- `/idea`
  - *refined* → **`/create-vi <JIRA-KEY>`** (PM) ✦
  - *draft* → **`/idea @<path> --deep`** (PM, refine) ✦ · or `/create-vi <JIRA-KEY>` (PM, proceed on a draft — not recommended)
- `/create-vi <JIRA-KEY>` — *(first: paste the VI into Jira + re-import)*, then:
  - **`/release-notes <VI>`** (PM — draft the release note) ✦ clear next step
  - hand to PA *(optional)* → **`/create-ard <VI>`** · or hand to PE → **`/epics <VI>`** (or `/specify <VI>`)

**PA — architecture (optional)**

- `/create-ard <VI>` (VI-level) → hand to PE → **`/epics <VI>`** ✦ · or `/specify <VI>` — *(no `/design`; no Epics yet)*
- `/create-ard <VI> <Epic>` (Epic-level) → **`/specify <VI> <Epic>`** ✦ · or hand to the team → `/design <VI> <Epic>`

**PE — breakdown & specification**

- `/specify <VI>` (VI-level spec) → **`/epics <VI>`** ✦
- `/epics <VI>` → **`/specify <VI> <Epic>`** ✦ (per Epic) — *(optional: PA → `/create-ard <VI> <Epic>`)*
- `/specify <VI> <Epic>` (Epic-level spec) → hand to the team → **`/design <VI> <Epic>`** ✦

**Team/Dev — build**

- `/design <VI> <Epic>` → **`/implement <VI> <Epic>`** ✦
- `/implement <VI> <Epic>` → finish the remaining Epics (breadth), **then, once *all* Epics are implemented**, `/document <VI>` → `/release-notes <VI>` — *(direct mode → no forward offer)*
- `/document <VI>` (VI-level, after all Epics) → **`/release-notes <VI>`** ✦ — *(doc-edit mode → no forward offer)*
- `/release-notes <VI>` (VI-level) → leaf/closure: "release note drafted; continue with any pending PA/PE phase, else the VI is fully processed"

## The offer contract (5 rules — lives in the SSOT)

Each `### Next step` is:

1. **Guidance-only** — names the command(s); NEVER auto-invokes anything.
2. **Role-labeled** — names concrete command(s) tagged with the owning role, so a
   multi-hat person keeps going.
3. **Adaptive to outcome** — a clean run points forward; a BLOCK / incomplete /
   cancelled run recommends resolving *that* instead of advancing.
4. **Mode-aware** — the forward recommendation is a *pipeline* handoff; in a command's
   direct / ad-hoc mode (no VI/Epic context) it is **omitted**, not invented.
5. **Epic fan-out** — when a command operates at **Epic scope**, the offer presents
   **two branches**:
   - **Depth** — the next command for the *same* Epic (`/design <VI> E1` → `/implement <VI> E1`) ✦
   - **Breadth** — the *same* command for the *next* Epic under the VI (`/design <VI> E1` → `/design <VI> E2`)

   …so a team can go `/design E1 → /design E2 → /implement E1 → /implement E2` **or**
   `/design E1 → /implement E1 → /design E2 …` — their call. Applies to the per-Epic
   commands only: `/create-ard <VI> <Epic>`, `/specify <VI> <Epic>`, `/design <VI> <Epic>`,
   `/implement <VI> <Epic>`. `/document` and `/release-notes` are **VI-level**
   (whole-feature, run once after all Epics are implemented) and do NOT fan out.

## Architecture — the SSOT

**New `references/next-phase-offer.md`** — the single source for:

- the routing graph (above), and
- the 5-rule offer contract (above).

Each pipeline command cites it (`${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`)
rather than restating the graph. This mirrors how `emit-block` lives once in
`references/feedback-emission.md` and is wired into each command by a short bullet.

## Surface — `### Next step` in the Final Report

The universal minimum is an adaptive `### Next step` section at the **end of each
command's Final Report** (guidance-only prose). This respects the four tail commands'
existing invariant ("ALWAYS produce the Final Report as the final output" /
"no closing confirmation") — the offer is *inside* the report, not a new closing
prompt. A command MAY additionally present a richer interactive `choices:` offer (the
three reference commands do); that is compatible, not required.

## Per-command wiring

**New file**

- `references/next-phase-offer.md` — the SSOT (graph + contract).

**Six targets** — add the `### Next step` section to the Final Report + cite the SSOT.

- `commands/specify.md` — Final report (no `Invariants` trailer) → `### Next step`
  adaptive on scope: VI-level → `/epics <VI>`; Epic-level → `/design <VI> <Epic>` +
  Epic fan-out. Cite SSOT inline.
- `commands/design.md` — Final report (no trailer) → `### Next step` → `/implement <VI> <Epic>`
  + Epic fan-out. Cite SSOT inline.
- `commands/implement.md` — Phase 5 Implementation Report → `### Next step`: finish
  remaining Epics (breadth); once all Epics implemented → `/document <VI>` →
  `/release-notes <VI>`. Direct mode → omit. Add one `## Invariants` bullet citing the SSOT.
- `commands/document.md` — Jira-mode report → `### Next step` → `/release-notes <VI>`;
  doc-edit mode → omit. Add one `## Invariants` bullet citing the SSOT.
- `commands/epics.md` — Phase 9 report → `### Next step` → `/specify <VI> <Epic>`
  (per Epic) + optional PA `/create-ard <VI> <Epic>`. Add one `## Invariants` bullet
  citing the SSOT.
- `commands/release-notes.md` — Phase 8 report → `### Next step` leaf/closure. Add one
  `## Invariants` bullet citing the SSOT.

**Three reference commands** (retrofit to the SSOT — "wire all 9")

- `commands/idea.md` — offer already matches; cite the SSOT (replace the "reference
  implementation of the plugin-wide pattern" note with a citation).
- `commands/create-vi.md` — **content change**: Phase 6 currently offers only
  `/release-notes` + `/create-ard`. Add the **PE → `/epics <VI>`** handoff, mark
  `/release-notes` **(Recommended)**, tag `/create-ard` **(PA, optional)**. Cite SSOT.
- `commands/create-ard.md` — VI-level already omits `/design`; add PE/Team **role
  labels** to the two existing offers. Cite SSOT.

**Manifests / docs**

- `plugins/dev-workflows/.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json`
  — version `2.18.0` → `2.19.0` (lock-step). Descriptions byte-identical **except**
  version — **no new command / subagent → counts unchanged** ("Nineteen slash commands",
  "Twenty-nine reusable subagents" stay verbatim). Recompute from the repo to confirm.
- `CHANGELOG.md` — prepend a `## [2.19.0] — 2026-07-10` entry.
- `README.md` — one line noting every pipeline command ends with a `### Next step`
  recommendation (the plugin-wide next-phase-offer invariant).

## No-regression / scope guarantees

- **Purely additive.** `### Next step` only *adds* a section to a report; no existing
  phase output changes. A run that produces its report today produces the same report
  plus a trailing `### Next step`.
- **Mode-aware = no-regression for ad-hoc use.** In a command's direct / doc-edit mode
  (no VI/Epic context) the section is **omitted** — those runs behave byte-identically.
- **`/vuln` + `/upgrade` are NOT pipeline nodes** — they are untouched. Verify:
  `git diff --stat main -- plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md`
  = empty.
- **Sibling plugins** `dt-style-guide 0.2.2` + `obsidian-llm-wiki 0.3.1` — untouched
  (byte-identical).

## Global constraints (verbatim)

- Version lock-step: `plugin.json` and the `dev-workflows` entry in root
  `marketplace.json` both go to `2.19.0`.
- Descriptions in both manifests stay **byte-identical except the version** — counts
  unchanged (Nineteen commands / Twenty-nine subagents).
- Commit trailer, exactly: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Never `git add -A`** — stage only named files.
- No test framework, no husky/prettier hook — verification is **structural** (grep
  anchors, `python3 -c json.load`, byte-diff, `git diff --stat`).
- Commit / push only when the user asks.
- Branch `ivgu/NOISSUE-next-phase-offer`; ff-merge to `main`; delete branch.
- No user name in any file.

## Out of scope

- `/vuln`, `/upgrade`, `/feedback`, `/prompt*`, `/docs-profile`, `/statusline`, and the
  reviewer commands — not part of the linear VI→docs pipeline.
- Auto-invoking the next command (the offer is guidance-only, forever).
- Enumerating sibling Epics from Jira for the breadth branch — the offer names the
  pattern (`/design <VI> <another Epic>`) without requiring live enumeration.

## Verification (structural)

- `python3 -c "import json; json.load(open(...))"` on `plugin.json` + `marketplace.json`;
  assert both `version == 2.19.0` and descriptions byte-identical except version.
- `grep` each of the 9 commands for a citation of `references/next-phase-offer.md`.
- `grep` the `### Next step` anchor in each of the 6 targets' report sections.
- `grep` the new `## Invariants` bullet in `implement`, `document`, `epics`,
  `release-notes`.
- Byte-diff: `git diff --stat main -- <vuln.md> <upgrade.md>` empty; sibling plugin
  dirs unchanged.

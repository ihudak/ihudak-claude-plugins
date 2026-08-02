---
tags:
  - tasks-exclude
---

# Session-Hygiene Suggestions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After big commands and long-run phase checkpoints, the dev-workflows pipeline flushes resume-critical state to disk, then suggests `/compact` (same-role continue) or `/clear` (cross-role handoff) plus a `/rename` session-name aid — guidance-only, never auto-run.

**Architecture:** One new SSOT reference (`references/session-hygiene.md`) holds the contract; the two co-firing references (`next-phase-offer.md`, `context-management.md`) cross-reference it; each affected command gains a short `### Context hygiene` block at its Final Report + one invariant. Mirrors the existing `next-phase-offer` / `emit-block` pattern exactly. No new command, no new agent, no new hook.

**Tech Stack:** Markdown command/agent/reference files + JSON manifests. NO test framework — verification is structural only (`grep`, `python3 -c json.load`, `git diff --stat`).

## Global Constraints

- **Version bump 2.28.0 → 2.29.0**, lock-step across `plugins/dev-workflows/.claude-plugin/plugin.json` (L3) and repo-root `.claude-plugin/marketplace.json` (dev-workflows entry, L12).
- **Manifest count-strings byte-identical** — `marketplace.json` L13 keeps "Twenty slash commands" and "Thirty reusable subagents" unchanged (no new command/agent/hook).
- **Sibling plugins byte-identical** — `dt-style-guide` 0.2.2 and `obsidian-llm-wiki` 0.3.1: zero-line diff.
- **Commit named files only** — never `git add -A`. Stage exactly the files each task names.
- **Commit trailer, exactly:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **ONE deliberate no-regression relaxation:** `/vuln` + `/upgrade` gain a `/compact` line this effort (they were 0-diff before). This is expected — flag it to the whole-branch review so it is not read as a regression. Everything else that omits the block (direct/doc-edit modes) stays byte-identical.
- **Canonical block heading:** `### Context hygiene` (a clarity refinement of the spec §4.8 "`### Context`" label — same intent, clearer word). Use it consistently in the reference and every command.
- **Guidance-only** — no command ever auto-invokes `/compact`, `/clear`, or `/rename`.
- All reference citations use `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` (match each file's existing citation style — some use the `${CLAUDE_PLUGIN_ROOT}` prefix, some bare `references/…`; follow the neighbor citation in the same file).
- **Do NOT hand-commit** the vault spec/plan (Obsidian Git auto-backup); only commit files under `/workspace/ihudak-claude-plugins`.

### Per-command behavior matrix (authoritative — every task references this)

| Command | resume.md? | /rename aid? | Suggestion | role tag |
|---|---|---|---|---|
| idea | no (pre-VI) | no (PM phase) | same-role → `/compact` | pm |
| create-vi | yes (seed-keyed dir) | no (no VI-Key yet) | span: PM→`/compact`, PA/PE→`/clear` | pm |
| create-ard | yes | yes | cross (PA→PE/Team) → `/clear` | pa |
| specify | yes | yes | span: VI-level→`/epics` PE `/compact`; Epic-level→`/design` Team `/clear` | pe |
| epics | yes | yes | same (`/specify <Epic>` PE) → `/compact`; optional PA → `/clear` | pe |
| design | yes | yes | same (Team) → `/compact` | team |
| ready | yes | yes | same (`/implement` Team) → `/compact` | team |
| implement | yes (non-direct) | yes (non-direct) | breadth+`/document` (same lane) → `/compact`; **direct mode → omit whole block** | team |
| document | yes (Mode A) | yes (Mode A) | cross (docs→PM `/release-notes`) → `/clear`; **Mode B doc-edit → omit whole block** | team |
| release-notes | yes | yes | leaf → suggest nothing (done); pending PA/PE phase → name it (`/clear`) | pm |
| vuln | no | no | plain `/compact` (big run) | — |
| upgrade | no | no | plain `/compact` (big run) | — |

**resume.md location** (mirror `references/followup-emission.md` §4): (1) `$SPECS_PATH` + VI dir exists → `<VI-dir>/dev-workflows/resume.md`; (2) `$SPECS_PATH` writable, no VI dir → skip file, rely on printed `### Next step`; (3) no `$SPECS_PATH`, `$VAULT_PATH` writable → `$VAULT_PATH/dev-workflows/resume/<KEY>-resume.md`; (4) neither → skip, print `⚠ could not persist a resume pointer — set $SPECS_PATH or $VAULT_PATH`.

---

### Task 1: Create `references/session-hygiene.md` + wire the two co-firing references

**Files:**
- Create: `plugins/dev-workflows/references/session-hygiene.md`
- Modify: `plugins/dev-workflows/references/next-phase-offer.md` (append after L77)
- Modify: `plugins/dev-workflows/references/context-management.md` (append after L15)

**Interfaces:**
- Produces: the SSOT every later task cites. Canonical block heading `### Context hygiene`; the prepare-checkpoint rule; the resume.md location tiers + format; the role-aware `/compact`|`/clear` rule; the `/rename` aid rule (VI-Key from `/release-notes` + PA/PE/Team onward; excluded for `/idea`+`/create-vi`); the 5-rule contract.

- [ ] **Step 1: Create `session-hygiene.md`** with exactly this content:

````markdown
# Session hygiene (embedded — shared reference)

The plugin-wide contract for **session-hygiene suggestions**: after a big command
finishes (or a long-run command reaches a mid-phase checkpoint), the pipeline first
**flushes resume-critical state to disk**, then **suggests the right context action**
(`/compact` or `/clear`) plus a session **`/rename`** aid. Cited by the pipeline commands
and by `next-phase-offer.md` / `context-management.md`, so the contract lives in ONE
place (the same shape as `next-phase-offer` and the `emit-block` invariant).

Everything here is **guidance-only** — the plugin NEVER auto-invokes `/compact`,
`/clear`, or `/rename`. The goal is to stop relying on a human to keep asking "prepare
for a compact/clear": the pipeline does the prep and prompts the choice itself.

## 1. Prepare-checkpoint (runs FIRST — unconditional for VI-scoped runs)

At command finalization — AFTER the deliverable artifact is saved/committed and AFTER
`emit-cost` / feedback / follow-up, and BEFORE the printed suggestion — a VI-scoped run
writes/overwrites a **resume pointer**. It runs regardless of which suggestion (or none)
fires: **prepare always, suggest adaptively.**

**Skipped** (no VI anchor to write against): `/idea` (pre-VI, keyless), `/implement`
**direct** mode, `/document` **doc-edit** mode (Mode B), `/vuln`, `/upgrade`. There the
durable state is the artifact / branch / PR already on disk; no resume pointer is written.

**Location** (mirror `followup-emission.md` §4 resolution):

1. `$SPECS_PATH` resolvable + writable + the VI dir exists → `<VI-dir>/dev-workflows/resume.md`. *[primary]*
2. `$SPECS_PATH` writable but no VI dir matched → skip the file; rely on the printed `### Next step`.
3. No `$SPECS_PATH`; `$VAULT_PATH` writable → `$VAULT_PATH/dev-workflows/resume/<KEY>-resume.md`.
4. Neither writable → skip the file; the suggestion still fires with a one-line
   `⚠ could not persist a resume pointer — set $SPECS_PATH or $VAULT_PATH`.

`resume.md` is a **"last known position" pointer, OVERWRITTEN each run** (NOT an append
log). It is intentionally tiny:

```markdown
# Resume — <KEY>[ / <EPIC-KEY>] (<role>)

- **Last completed:** <command> <args> — <phase or 'command complete'> (<ISO datetime>)
- **Artifact:** <relative path to the deliverable just written/committed, or 'none (read-only)'>
- **Next step:** <the exact next command from ### Next step, or 'VI fully processed'>
- **Suggested session name:** <VI-ID>-<slug>-<role>   (omit this line when no VI-Key exists yet — e.g. /create-vi)
- **Carry-forward decisions:** <0–N one-line decisions the next phase needs that are NOT already in the artifact; 'none' if none>
```

## 2. The suggestion — role-aware (reads next-phase-offer's role labels)

`next-phase-offer.md` already role-labels every next option (PM / PA / PE / Team). For
each next option the offer names, compare its role to the just-finished command's role:

- **Same role** (e.g. `/design E1 → /design E2`, Team→Team) → suggest **`/compact`** —
  context still relevant, keep the thread.
- **Different role** (e.g. `/epics` PE → `/design` Team) → suggest **`/clear`** as the
  better choice when one person keeps wearing both hats (the prior role's reasoning is
  now noise). `/compact` still works if continuing right away; a genuinely different
  person just starts fresh and re-reads disk.
- Next options **span both** (e.g. `/create-vi` → PM `/release-notes` OR hand to PA/PE) →
  present **both branches**: "continuing as PM → `/compact`; handing off (even to
  yourself) → `/clear`."
- **User is done / ending the session** → suggest nothing.

Do NOT hardcode a per-command compact/clear verdict — read the role labels the command's
own `next-phase-offer` output already carries. The role graph is owned by
`next-phase-offer.md`; it is not duplicated here.

## 3. Mid-phase checkpoints & non-pipeline big commands

- **`/implement` mid-phase checkpoint** (Scope-to-N / per-Epic, per `context-management.md`)
  → suggest **`/compact`** to free budget before continuing (mid-command → no role
  transition → never `/clear`).
- **`/vuln`, `/upgrade`** (big, non-pipeline, no role transition) → a plain end-of-run
  **`/compact`** suggestion only; no `resume.md` (durable state is the branch/PR).

## 4. Session-name aid

The VI-Key is first available at **`/release-notes`** and is present for every PA/PE/Team
command (`/create-ard`, `/epics`, `/specify`, `/design`, `/ready`, `/implement`,
`/document`, `/release-notes` — all take `<VI>`). For those, print a suggested
`/rename <VI-ID>-<slug>-<role>` line so the user can relocate the session in
`claude --resume` later (e.g. after going home). `<role>` is the just-finished command's
lane tag (pm / pa / pe / team). Guidance-only — a command cannot run `/rename` itself.

**`/idea` and `/create-vi` are excluded** from the rename aid: the PM ideation phase runs
*before* the paste-into-Jira + re-import round-trip that mints the VI (the key
`/create-vi` takes is the seed RFE, not the VI-ID). It is a short phase — no label is
auto-suggested there; the PM names the session manually if they want one.

## 5. Contract (5 rules)

1. **Guidance-only** — never auto-invokes `/compact`, `/clear`, or `/rename`.
2. **Prepare-first** — the disk flush (resume pointer) always precedes the printed
   suggestion, so acting on it is safe. Prepare is unconditional (VI-scoped); only the
   suggestion is adaptive.
3. **Role-aware via a single graph** — the compact/clear split reads
   `next-phase-offer.md`'s role labels; the role graph is not duplicated here.
4. **Mode-aware** — direct / doc-edit / non-pipeline / pre-VI runs (no VI anchor) → no
   `resume.md`, no `/rename`, and the suggestion degrades to a plain optional `/compact`
   note (or is omitted, consistent with `next-phase-offer`'s mode-aware omission).
5. **Never blocks** — a nudge appended to the Final Report, exactly like the next-phase offer.

## Surface

A short **`### Context hygiene`** block appended right after the `### Next step` section
at the END of the command's Final Report (guidance-only prose), plus one invariant citing
this reference. `/vuln` + `/upgrade` place the `/compact` line near their
`impl-maintenance` handoff. `/implement` places the mid-phase `/compact` at its Phase 3B
checkpoint.
````

- [ ] **Step 2: Append the cross-reference to `next-phase-offer.md`** after its last line (L77, end of `## Not pipeline nodes`):

```markdown

## Session hygiene co-fires here

The `### Next step` this contract produces is immediately followed by a
`### Context hygiene` block (`references/session-hygiene.md`): the compact-vs-clear
choice reads the SAME role labels computed here (same role → `/compact`; role handoff →
`/clear`). This reference owns the role graph; `session-hygiene.md` only reads it.
```

- [ ] **Step 3: Append the cross-reference to `context-management.md`** after its last line (L15):

```markdown

At each **checkpoint**, a long-run command may additionally suggest **`/compact`** to free
context before continuing the next scope/Epic — see `references/session-hygiene.md` §3
(mid-command → `/compact` only, never `/clear`; guidance-only).
```

- [ ] **Step 4: Verify structure**

Run: `cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && grep -c "^## " references/session-hygiene.md && grep -n "Context hygiene\|resume.md\|prepare-first\|Guidance-only\|VI-Key" references/session-hygiene.md | head && grep -n "session-hygiene" references/next-phase-offer.md references/context-management.md`
Expected: session-hygiene.md has ≥6 `## ` headings; the grep shows the block heading, resume.md tiers, contract terms; both refs now cite `session-hygiene`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/session-hygiene.md plugins/dev-workflows/references/next-phase-offer.md plugins/dev-workflows/references/context-management.md
git commit -m "feat(dev-workflows): add session-hygiene SSOT reference + cross-refs

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: PM lane — `idea.md` + `create-vi.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (Phase 5 next-phase guidance ~L125–135; invariant paragraph near Capture-at-block L143)
- Modify: `plugins/dev-workflows/commands/create-vi.md` (Phase 6 — Next steps, after L195; invariant paragraph near Capture-at-block L203)

**Interfaces:**
- Consumes: `references/session-hygiene.md` (Task 1). Behavior per the matrix: `idea` = no resume.md / no rename / same-role `/compact`; `create-vi` = resume.md yes (seed-keyed dir) / no rename / span PM `/compact` + PA-PE `/clear`.

- [ ] **Step 1: `idea.md` — add a minimal `### Context hygiene` note** in Phase 5, immediately after the next-phase-offer guidance block (the line at ~L134–135 that cites `next-phase-offer.md`). Add:

```markdown

### Context hygiene

Continuing to `/create-vi` (still the PM phase)? → run **`/compact`** to free context; your
`idea.md` is already on disk. (No resume pointer or `/rename` label here — the VI-Key is
minted later, and the ideation phase is short.) Guidance only — see
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

- [ ] **Step 2: `idea.md` — add the invariant paragraph** right after the `**Capture-at-block invariant.**` paragraph (L143):

```markdown

**Session-hygiene invariant.** End Phase 5 with a `### Context hygiene` note per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — a same-role `/compact` suggestion
(no `resume.md`, no `/rename`: pre-VI, short PM phase). Guidance only, never auto-run.
```

- [ ] **Step 3: `create-vi.md` — add the `### Context hygiene` block** at the end of `## Phase 6 — Next steps`, right after the `next-phase-offer.md` citation (L195):

```markdown

### Context hygiene

Write/overwrite the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per
`session-hygiene.md` §1; the VI-Key is minted by the Jira round-trip, so **omit the
session-name line** and name the session manually if useful). Then:

- **Continuing as PM (`/release-notes <VI>` after the round-trip)?** → run **`/compact`**.
- **Handing to PA (`/create-ard <VI>`) or PE (`/epics <VI>`), even yourself?** → run **`/clear`** for a clean slate.

Guidance only — nothing is auto-run. See `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

- [ ] **Step 4: `create-vi.md` — add the invariant paragraph** right after the `**Capture-at-block invariant.**` paragraph (L203):

```markdown

**Session-hygiene invariant.** End Phase 6 with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (write `resume.md`),
then a span suggestion (PM continue → `/compact`; PA/PE handoff → `/clear`). No `/rename`
label yet (no VI-Key). Guidance only, never auto-run.
```

- [ ] **Step 5: Verify**

Run: `cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && grep -n "Context hygiene\|Session-hygiene invariant\|session-hygiene" commands/idea.md commands/create-vi.md`
Expected: idea.md → 1 block heading + 1 invariant + citations; create-vi.md → 1 block heading + 1 invariant + citations; create-vi block names `/compact` and `/clear`; idea block names only `/compact`.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md plugins/dev-workflows/commands/create-vi.md
git commit -m "feat(dev-workflows): session-hygiene block in PM lane (idea, create-vi)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: PA/PE lane — `create-ard.md` + `specify.md` + `epics.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/create-ard.md` (after Phase 7 next-step citation L128; invariant paragraph near Capture-at-block L135)
- Modify: `plugins/dev-workflows/commands/specify.md` (after `### Next step` L495/L497; invariant paragraph near Capture-at-block L434)
- Modify: `plugins/dev-workflows/commands/epics.md` (after `### Next step` L605–606; append invariant bullet to `## Invariants (always enforced)` list, ~L691)

**Interfaces:**
- Consumes: `references/session-hygiene.md`. All three: resume.md yes + `/rename` yes. `create-ard` role=pa (cross → `/clear`); `specify` role=pe (span by level); `epics` role=pe (same → `/compact`, optional PA → `/clear`).

- [ ] **Step 1: `create-ard.md` — add block** after the `## Phase 7 — Next-step offer (adaptive)` citation (L128):

```markdown

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md`
§1). The next step hands off from PA to PE/Team, so:

- **Handing to PE (`/epics <VI>` / `/specify <VI> <Epic>`) or Team (`/design <VI> <Epic>`), even yourself?** → run **`/clear`** for a clean slate; the ARD is on disk.
- Continuing to draft more ARD areas yourself right now? → **`/compact`** is fine.
- Consider **`/rename <VI-ID>-<slug>-pa`** so you can find this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

- [ ] **Step 2: `create-ard.md` — add invariant paragraph** after the `**Capture-at-block invariant.**` paragraph (L135):

```markdown

**Session-hygiene invariant.** End Phase 7 with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (`resume.md`), then a
PA→PE/Team handoff suggestion (`/clear`) + `/rename <VI-ID>-<slug>-pa`. Guidance only, never auto-run.
```

- [ ] **Step 3: `specify.md` — add block** after the `### Next step` line (L495) / its `next-phase-offer.md` citation (L497):

```markdown

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:

- **VI-level spec → `/epics <VI>` (still PE)?** → run **`/compact`** — context still relevant.
- **Epic-level spec → Team `/design <VI> <Epic>` (even yourself)?** → run **`/clear`** for a clean slate.
- Consider **`/rename <VI-ID>-<slug>-pe`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

- [ ] **Step 4: `specify.md` — add invariant paragraph** after the `**Capture-at-block invariant.**` paragraph (L434):

```markdown

**Session-hygiene invariant.** End the report with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (`resume.md`), then a
span suggestion (VI-level→`/epics` `/compact`; Epic-level→`/design` `/clear`) +
`/rename <VI-ID>-<slug>-pe`. Guidance only, never auto-run.
```

- [ ] **Step 5: `epics.md` — add block** after the `### Next step` line (L605) / its citation (L606), inside the Phase 9 report body:

```markdown

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:

- **Continuing as PE (`/specify <VI> <Epic>`)?** → run **`/compact`** — context still relevant.
- **Handing to PA (`/create-ard <VI> <Epic>`), even yourself?** → run **`/clear`** for a clean slate.
- Consider **`/rename <VI-ID>-<slug>-pe`** to relocate this session later.

Guidance only — see `references/session-hygiene.md`.
```

- [ ] **Step 6: `epics.md` — append invariant bullet** at the end of the `## Invariants (always enforced)` list (~L691):

```markdown
- ALWAYS end the Phase 9 report with a `### Context hygiene` block per `references/session-hygiene.md` — prepare-first (`resume.md`), then a role-aware `/compact`|`/clear` suggestion + `/rename <VI-ID>-<slug>-pe`; guidance only, never auto-run.
```

- [ ] **Step 7: Verify**

Run: `cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && for f in create-ard specify epics; do echo "== $f =="; grep -c "Context hygiene" commands/$f.md; grep -c "session-hygiene" commands/$f.md; done`
Expected: each file → `Context hygiene` ≥1, `session-hygiene` ≥2 (block + invariant). Spot-check: `grep -n "/clear" commands/create-ard.md` present; `grep -n "/compact" commands/epics.md` present.

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/create-ard.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/epics.md
git commit -m "feat(dev-workflows): session-hygiene block in PA/PE lane (create-ard, specify, epics)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Team lane (simple) — `design.md` + `ready.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/design.md` (after `### Next step` L393/L395; invariant paragraph near Capture-at-block L329)
- Modify: `plugins/dev-workflows/commands/ready.md` (after `### Next step` L334/L335; append invariant bullet to `## Invariants (always enforced)` list ~L535)

**Interfaces:**
- Consumes: `references/session-hygiene.md`. Both role=team, all next options same-role → `/compact`; resume.md yes + `/rename <VI-ID>-<slug>-team`.

- [ ] **Step 1: `design.md` — add block** after the `### Next step` line (L393) / its citation (L395):

```markdown

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:

- **Continuing on this Epic (`/ready` / `/implement <VI> <Epic>`) or the next Epic (`/design <VI> <Epic2>`) — all still Team?** → run **`/compact`** — context stays relevant.
- Consider **`/rename <VI-ID>-<slug>-team`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

- [ ] **Step 2: `design.md` — add invariant paragraph** after the `**Capture-at-block invariant.**` paragraph (L329):

```markdown

**Session-hygiene invariant.** End the report with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (`resume.md`), then a
same-role `/compact` suggestion + `/rename <VI-ID>-<slug>-team`. Guidance only, never auto-run.
```

- [ ] **Step 3: `ready.md` — add block** after the `### Next step` line (L334) / its citation (L335), inside the Phase 5 report body:

```markdown

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1;
record the readiness verdict as a carry-forward line). Then:

- **SUPPORTED → `/implement <VI> [<Epic>]` (still Team)?** → run **`/compact`** — context stays relevant.
- **PARTIAL / NOT-SUPPORTED → resolving the gaps yourself now?** → **`/compact`**.
- Consider **`/rename <VI-ID>-<slug>-team`** to relocate this session later.

Guidance only — see `references/session-hygiene.md`.
```

- [ ] **Step 4: `ready.md` — append invariant bullet** at the end of the `## Invariants (always enforced)` list (~L535):

```markdown
- ALWAYS end with a `### Context hygiene` block per `references/session-hygiene.md` — prepare-first (`resume.md`, verdict as carry-forward), then a same-role `/compact` suggestion + `/rename <VI-ID>-<slug>-team`; guidance only, never auto-run.
```

- [ ] **Step 5: Verify**

Run: `cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && for f in design ready; do echo "== $f =="; grep -c "Context hygiene" commands/$f.md; grep -c "session-hygiene" commands/$f.md; grep -c "/clear" commands/$f.md; done`
Expected: each file → `Context hygiene` ≥1, `session-hygiene` ≥2; **`/clear` count = 0** (both are same-role, `/compact`-only — no `/clear` in these two).

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/design.md plugins/dev-workflows/commands/ready.md
git commit -m "feat(dev-workflows): session-hygiene block in Team lane (design, ready)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Team lane (mode-aware) — `implement.md` + `document.md`

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (mid-phase note at Phase 3B context-management citation L409; end-of-run block after `### Next step` L601/L602; append invariant bullet to `## Invariants (always enforced)` ~L687)
- Modify: `plugins/dev-workflows/commands/document.md` (Mode A block after `### Next step` L941/L942; append invariant bullet to Mode A `## Invariants (always enforced)` ~L1020; Mode B gets NOTHING — omission is the correct behavior)

**Interfaces:**
- Consumes: `references/session-hygiene.md`. `implement` role=team: end-of-run same-lane `/compact`, **direct mode omits the whole block + writes no resume.md**; mid-phase checkpoint suggests `/compact`. `document` role=team, Mode A: cross docs→PM (`/release-notes`) → `/clear`; **Mode B (doc-edit) omits the whole block** (byte-identical, no `### Next step` there).

- [ ] **Step 1: `implement.md` — add the mid-phase `/compact` note** at the Phase 3B context-management application (L409–410). After the existing sentence that cites `context-management.md`, add:

```markdown
  At each checkpoint, also consider suggesting **`/compact`** to free context before the next scope/Epic (per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3 — mid-command → `/compact` only, never `/clear`; guidance only).
```

- [ ] **Step 2: `implement.md` — add the end-of-run block** after the `### Next step` line (L601) / its citation (L602). Make the mode-conditionality explicit (matches how L602 already omits the forward step in direct mode):

```markdown

### Context hygiene

*(Jira mode only — omit this whole block in direct-prompt mode, like the `### Next step` above.)*
Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:

- **More Epics to build (`/implement <VI> <Epic2>`) or on to `/document <VI>` — same build lane?** → run **`/compact`** — context stays relevant.
- Consider **`/rename <VI-ID>-<slug>-team`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

- [ ] **Step 3: `implement.md` — append invariant bullet** at the end of the `## Invariants (always enforced)` list (~L687):

```markdown
- ALWAYS end the Phase 5 report with a `### Context hygiene` block per `references/session-hygiene.md` — prepare-first (`resume.md`), then a same-lane `/compact` suggestion + `/rename <VI-ID>-<slug>-team`; **omitted in direct mode** (no VI/Epic context, no `resume.md`); the Phase 3B checkpoint additionally suggests `/compact` mid-run. Guidance only, never auto-run.
```

- [ ] **Step 4: `document.md` — add the Mode A block** after the Mode A `### Next step` line (L941) / its citation (L942):

```markdown

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:

- **On to `/release-notes <VI>` (docs → PM handoff), even yourself?** → run **`/clear`** for a clean slate; the docs are on disk.
- Consider **`/rename <VI-ID>-<slug>-team`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

- [ ] **Step 5: `document.md` — append the Mode A invariant bullet** at the end of the Mode A `## Invariants (always enforced)` list (~L1020):

```markdown
- ALWAYS end the Phase 9 report with a `### Context hygiene` block per `references/session-hygiene.md` — prepare-first (`resume.md`), then a docs→PM handoff suggestion (`/clear`) + `/rename <VI-ID>-<slug>-team`; guidance only, never auto-run. **Mode B (direct doc-edit) omits this** — no VI context.
```

- [ ] **Step 6: Confirm Mode B is untouched**

Run: `cd /workspace/ihudak-claude-plugins && git diff plugins/dev-workflows/commands/document.md | grep -n "^@@" | tail -5`
Expected: all hunks are in the Mode A region (around L941 and L1020); NO hunk near Mode B's `## Phase 5 — Final Report` (L1250) or Mode B invariants (L1344). Mode B stays byte-identical.

- [ ] **Step 7: Verify**

Run: `cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && grep -c "Context hygiene" commands/implement.md commands/document.md && grep -n "omit this whole block\|omitted in direct mode\|Mode B (direct doc-edit) omits" commands/implement.md commands/document.md && grep -c "session-hygiene" commands/implement.md commands/document.md`
Expected: implement.md → `Context hygiene` = 1 (block) [+ mentions in invariant text]; document.md → `Context hygiene` = 1 (Mode A only); mode-omission notes present in both; `session-hygiene` ≥3 in implement.md (mid-phase + block + invariant), ≥2 in document.md.

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/implement.md plugins/dev-workflows/commands/document.md
git commit -m "feat(dev-workflows): mode-aware session-hygiene block (implement, document)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Closure commands — `vuln.md` + `upgrade.md` (compact nudge) + `release-notes.md` (leaf hygiene)

**Files:**
- Modify: `plugins/dev-workflows/commands/vuln.md` (add `/compact` line near the impl-maintenance handoff L166; append invariant bullet to `## Invariants (always enforced)` L231)
- Modify: `plugins/dev-workflows/commands/upgrade.md` (add `/compact` line near the impl-maintenance handoff L147 / Output summary; append invariant bullet to `## Invariants (always enforced)` L184)
- Modify: `plugins/dev-workflows/commands/release-notes.md` (block after `### Next step` L206/L207; append invariant bullet to `## Invariants (always enforced)` ~L311)

**Interfaces:**
- Consumes: `references/session-hygiene.md`. `vuln`/`upgrade`: plain `/compact`, no resume.md, no `/rename`, no `/clear` (§3). `release-notes` role=pm, leaf/closure: suggest nothing when done; name a pending PA/PE phase if any; resume.md yes + `/rename <VI-ID>-<slug>-pm`. (This is the ONE relaxation: `/vuln`+`/upgrade` change from 0-diff — expected.)

- [ ] **Step 1: `vuln.md` — add the `/compact` line** right after the impl-maintenance sentence (L166):

```markdown

**Context hygiene.** This was a large run — consider **`/compact`** to free context before your next task (per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3 — non-pipeline, so `/compact` only; guidance only).
```

- [ ] **Step 2: `vuln.md` — append invariant bullet** to the `## Invariants (always enforced)` list (L231):

```markdown
- After the run, suggest **`/compact`** (a big non-pipeline run) per `references/session-hygiene.md` §3 — compact-only, no clear/resume pointer; guidance only, never auto-run.
```

- [ ] **Step 3: `upgrade.md` — add the `/compact` line** right after the post-batch impl-maintenance sentence (L147):

```markdown

**Context hygiene.** This was a large run — consider **`/compact`** to free context before your next task (per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3 — non-pipeline, so `/compact` only; guidance only).
```

- [ ] **Step 4: `upgrade.md` — append invariant bullet** to the `## Invariants (always enforced)` list (L184):

```markdown
- After the run, suggest **`/compact`** (a big non-pipeline run) per `references/session-hygiene.md` §3 — compact-only, no clear/resume pointer; guidance only, never auto-run.
```

- [ ] **Step 5: `release-notes.md` — add block** after the `### Next step` line (L206) / its citation (L207), inside the Phase 8 report body:

```markdown

### Context hygiene

Write the resume pointer at `<VI-dir>/dev-workflows/resume.md` (per `session-hygiene.md` §1). Then:

- **Release note drafted and the VI fully processed?** → nothing to suggest — you're done.
- **A PA/PE phase still pending for this VI (e.g. `/create-ard`, `/epics`), even yourself?** → run **`/clear`** before switching roles.
- Consider **`/rename <VI-ID>-<slug>-pm`** to relocate this session later.

Guidance only — see `references/session-hygiene.md`.
```

- [ ] **Step 6: `release-notes.md` — append invariant bullet** to the `## Invariants (always enforced)` list (~L311):

```markdown
- ALWAYS end the Phase 8 report with a `### Context hygiene` block per `references/session-hygiene.md` — prepare-first (`resume.md`), then a leaf-aware suggestion (done → nothing; pending role → `/clear`) + `/rename <VI-ID>-<slug>-pm`; guidance only, never auto-run.
```

- [ ] **Step 7: Verify**

Run: `cd /workspace/ihudak-claude-plugins/plugins/dev-workflows && grep -c "Context hygiene\|session-hygiene" commands/vuln.md commands/upgrade.md commands/release-notes.md && grep -c "/clear" commands/vuln.md commands/upgrade.md`
Expected: vuln.md + upgrade.md each show `session-hygiene` ≥2 (line + invariant) and **`/clear` count = 0**; release-notes.md shows `Context hygiene` ≥1 + `session-hygiene` ≥2.

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/commands/release-notes.md
git commit -m "feat(dev-workflows): compact nudge for vuln/upgrade + leaf hygiene for release-notes

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Version bump (lock-step) + CHANGELOG

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (L3 version)
- Modify: `/workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json` (dev-workflows entry version, L12)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (new top entry above L7)

**Interfaces:**
- Consumes: nothing (final task). Version 2.28.0 → 2.29.0; count-strings unchanged; siblings untouched.

- [ ] **Step 1: Bump `plugin.json`** L3: `"version": "2.28.0",` → `"version": "2.29.0",`

- [ ] **Step 2: Bump `marketplace.json`** dev-workflows entry L12: `"version": "2.28.0",` → `"version": "2.29.0",`. Do NOT touch L13 (description with "Twenty"/"Thirty"), and do NOT touch the dt-style-guide / obsidian-llm-wiki entries.

- [ ] **Step 3: Add CHANGELOG entry** immediately above the existing `## [2.28.0] — 2026-07-13` (L7):

```markdown
## [2.29.0] — 2026-07-13

### Added

- `references/session-hygiene.md` — the plugin-wide SSOT for **session-hygiene suggestions**: a prepare-checkpoint that flushes resume-critical state to `<VI-dir>/dev-workflows/resume.md`, then a role-aware `/compact` (same role) vs `/clear` (cross-role handoff) suggestion, plus a `/rename <VI-ID>-<slug>-<role>` session-name aid. Guidance-only — never auto-run.
- A `### Context hygiene` block at the Final Report of every pipeline command (role-aware per `next-phase-offer.md`), and a mid-phase `/compact` suggestion at `/implement`'s checkpoint.

### Changed

- `/vuln` and `/upgrade` now end with a plain `/compact` suggestion (big non-pipeline runs).
- `next-phase-offer.md` and `context-management.md` cross-reference `session-hygiene.md`.

### Notes

- No new command, agent, or hook — counts unchanged (Twenty slash commands / Thirty reusable subagents).
- `/idea` and `/create-vi` (pre-VI-Key PM ideation) get the suggestion but no `resume.md`/`/rename`; direct/doc-edit modes omit the block.
```

- [ ] **Step 4: Verify manifests + counts**

Run:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); json.load(open('.claude-plugin/marketplace.json')); print('JSON OK')"
grep -n '"version": "2.29.0"' plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
grep -c "Twenty slash commands" .claude-plugin/marketplace.json
grep -c "Thirty reusable subagents" .claude-plugin/marketplace.json
git diff --stat -- .claude-plugin/marketplace.json | tail -1
```
Expected: `JSON OK`; version 2.29.0 in both; count-strings each = 1 (unchanged); marketplace.json diff = exactly 1 changed line (L12 version only).

- [ ] **Step 5: Verify siblings + counts untouched (no-regression)**

Run: `cd /workspace/ihudak-claude-plugins && git diff --stat HEAD~6 | grep -E "dt-style-guide|obsidian-llm-wiki" ; echo "exit=$?"`
Expected: no output (grep exit=1) — no sibling-plugin file changed across the whole branch.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(dev-workflows): bump to 2.29.0 + CHANGELOG (session-hygiene)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Whole-branch verification (after all tasks — for the final review)

- `python3 -c "import json; ..."` → both manifests parse at 2.29.0.
- `grep -rl "session-hygiene" plugins/dev-workflows/commands/ plugins/dev-workflows/references/` → the new reference + next-phase-offer.md + context-management.md + all 12 wired commands (idea, create-vi, create-ard, specify, epics, design, ready, implement, document, release-notes, vuln, upgrade).
- `git diff --stat main..HEAD` → sibling plugins 0-diff; the ONLY deliberately-relaxed 0-diff files are `commands/vuln.md` + `commands/upgrade.md` (expected — flag to review).
- Count-strings "Twenty"/"Thirty" unchanged in marketplace.json.
- `document.md` Mode B region unchanged (byte-identical); `implement.md` direct-mode path omits the block.

## Self-Review (against the spec)

**Spec coverage:** §4.1 mechanism → Task 1. §4.2 prepare-checkpoint (unconditional, skip list) → Task 1 reference + per-command matrix (idea/direct/doc-edit/vuln/upgrade skip). §4.3 resume.md format → Task 1. §4.4 role-aware suggestion → Tasks 2–6 per matrix. §4.5 mid-phase + vuln/upgrade → Task 5 (implement checkpoint) + Task 6. §4.6 rename aid (release-notes + PA/PE/Team; idea+create-vi excluded) → matrix + Tasks 2–6. §4.7 contract → Task 1. §4.8 surface (`### Context hygiene` + invariant) → all command tasks. §5 no-regression → Global Constraints + Task 5 Step 6 + Task 7 Steps 4–5. §6 versioning → Task 7. §7 out-of-scope (no dot-rename, no SessionStart hook) → not built. All spec sections map to a task.

**Placeholder scan:** no TBD/TODO; every edit shows verbatim text; `<VI-dir>`, `<VI-ID>`, `<slug>`, `<role>` are documented template tokens (not gaps).

**Consistency:** canonical heading `### Context hygiene` everywhere; role tags fixed in the matrix; resume.md/rename inclusion identical between the matrix, the reference (Task 1), and each command task; `/clear`-count=0 checks encode the same-role-only commands (design, ready, vuln, upgrade).

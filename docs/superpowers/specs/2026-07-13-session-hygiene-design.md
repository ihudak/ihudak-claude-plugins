# Session-Hygiene Suggestions (compact / clear + prepare-for-resume) — Design

**Effort:** AI-First.md task (line 87, priority `[2]`) — suggest `/compact` after big commands & phases, `/clear` on cross-role handoff, and prepare the agent for compact/clear by flushing resume state to disk
**Target repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Version:** 2.29.0 (minor; adds one reference + edits commands & two references; **no new command, no new agent, no new hook** → counts unchanged Twenty/Thirty)
**Date:** 2026-07-13
**Test framework:** none — structural verification only (grep, `python3 -c json.load`, `git diff --stat`)

---

## 1. Goal

After a big command finishes (or a long-run command reaches a mid-phase checkpoint), the plugin should:

1. **Prepare for context loss FIRST** — unconditionally flush the resume-critical state of a VI-scoped run to disk (`<VI-dir>/dev-workflows/resume.md`), so a `/compact`, a `/clear`, or a cold pick-up by a different person next work-day is seamless. This is the concrete, portable meaning of the task's "write the necessary things to memory."
2. **Then suggest the right context action, adaptively:**
   - continuing as the **same role** → suggest **`/compact`** (context still relevant);
   - crossing a **role boundary** (PM→PA→PE→Team) where one person may wear both hats → suggest **`/clear`** (the prior role's reasoning is now noise), noting `/compact` is fine if continuing immediately;
   - the user is **done / ending the session** → suggest nothing.
3. **Offer a session-name aid** — from the moment a VI-Key exists (i.e. `/release-notes` and the PA/PE/Team phases), suggest a `/rename <VI-ID>-<slug>-<role>` line so the user can find and resume the session in `claude --resume` later. The short PM ideation phase (`/idea`, `/create-vi`) runs before the VI is minted, so it carries no VI-Key and is left for the PM to name manually (§4.6).

Everything is **guidance-only** — the plugin never auto-invokes `/compact`, `/clear`, or `/rename`. The point (per the requester) is to stop relying on a human to keep asking "prepare for a compact / clear" — the pipeline does the prep and prompts the choice itself.

## 2. Current state (what exists today)

- **`references/next-phase-offer.md`** — the SSOT for the end-of-run "next command" offer, cited by all **10 pipeline commands** (`idea`, `create-vi`, `create-ard`, `specify`, `epics`, `design`, `ready`, `implement`, `document`, `release-notes`). It already **computes and role-labels the transition** (PM / PA / PE / Team) for each next option — the exact signal the compact-vs-clear choice needs.
- **`references/context-management.md`** — long-run strategies (Scope-to-N **checkpoint**, sub-agent-per-`[P]`, decompose). Cited only by `/implement`. Owns the "mid-command phase checkpoint" concept.
- **`<VI-dir>/dev-workflows/` under `$SPECS_PATH`** — the per-VI artifact home already used by `cost` / `feedback` / `followup` emission (`cost-emission.md`, `feedback-emission.md`, `followup-emission.md`), with graceful fallback tiers ($SPECS_PATH VI dir → $SPECS_PATH root subdir → $VAULT_PATH → report-only). Committing these artifacts is **expected/encouraged** (v2.27.0).
- **No `/compact` or `/clear` suggestion exists anywhere today.** (The only "compact" hits in the codebase are "compact session handoff" to `impl-maintenance` — unrelated to the harness `/compact` command.)
- `/vuln` and `/upgrade` — big, non-pipeline maintenance flows; each ends with an `impl-maintenance` handoff. They are deliberately excluded from `next-phase-offer` (not pipeline nodes).

## 3. Confirmed facts (session naming feasibility)

Verified via a Claude Code capabilities lookup:

- **`/rename <name>`** sets the session name shown in the `claude --resume` picker (and the prompt bar) — but it is **user-invoked**; a command/agent cannot call it programmatically.
- A **`SessionStart` hook** can set a `sessionTitle` via JSON output — but only at session start, when the VI-ID / role are **not yet known** (they are determined only once a command runs), and it would fire for *every* session in the repo. Wrong tool for a `<VI-ID>-<slug>-<role>` label.
- Terminal-title escape sequences exist but are not a reliable naming mechanism.

**Consequence:** auto-naming the session to `<VI-ID>-<slug>-<role>` is **not** buildable from within a command. The portable, in-character move is to **suggest** a `/rename <VI-ID>-<slug>-<role>` line (the command computes the label; the user runs it) — consistent with the guidance-only ethos of the whole feature. A `SessionStart` auto-name hook is **out of scope** (§7).

## 4. Design

### 4.1 Mechanism — one new SSOT reference + thin wiring

Mirror `next-phase-offer.md` / `emit-block` exactly: a single shared reference holds the contract; each affected command cites it and surfaces a short block plus one invariant bullet. **No new command, no new agent, no new hook.**

- **New: `references/session-hygiene.md`** — the SSOT for the prepare-checkpoint, the compact/clear suggestion, the `/rename` aid, and the contract rules.
- `next-phase-offer.md` gains a one-line cross-reference (they co-fire and share the role graph — which stays **owned by `next-phase-offer.md`**, not duplicated).
- `context-management.md` gains a one-line cross-reference (mid-phase checkpoints may suggest `/compact`).

### 4.2 The prepare-checkpoint (runs UNCONDITIONALLY, VI-scoped)

At command finalization, **after** the existing artifact-save + `emit-cost` / `feedback` / `followup` steps and **before** the printed suggestion, a VI-scoped run writes/overwrites `resume.md`. It runs **regardless of which suggestion (or none) fires** — "prepare always, suggest adaptively."

Skipped only when there is no VI/Epic context to anchor it: **`/idea`** (pre-VI, keyless — no `<VI-dir>` exists yet; its `idea.md` + the printed `### Next step` already carry the resume state), `/implement` **direct** mode, `/document` **doc-edit** mode, and `/vuln` / `/upgrade` (their durable state is the branch + PR they create). In those cases there is no `resume.md` and the suggestion (if any) still fires — degrading to a plain optional `/compact` note where there is no role transition.

Resolution & fallback mirror `followup-emission.md` §4:
1. `$SPECS_PATH` resolvable + writable + VI dir exists → `<VI-dir>/dev-workflows/resume.md`. *[primary]*
2. `$SPECS_PATH` writable but no VI dir matched → skip the file; rely on the printed `### Next step` (no orphan location invented).
3. No `$SPECS_PATH`; `$VAULT_PATH` writable → `$VAULT_PATH/dev-workflows/resume/<KEY>-resume.md`.
4. Neither writable → skip the file; the printed suggestion still fires with a one-line `⚠ could not persist a resume pointer — set $SPECS_PATH or $VAULT_PATH` note.

`resume.md` is a **"last known position" pointer, overwritten each run** (NOT an append log). It is intentionally tiny.

### 4.3 `resume.md` format

```markdown
# Resume — <VI-KEY>[ / <EPIC-KEY>] (<role>)

- **Last completed:** <command> <args> — <phase or 'command complete'> (<ISO datetime>)
- **Artifact:** <relative path to the deliverable just written/committed>
- **Next step:** <the exact next command from ### Next step, or 'VI fully processed'>
- **Suggested session name:** <VI-ID>-<slug>-<role>  *(present only when a VI-Key exists — omitted for the pre-round-trip `/create-vi`; §4.6)*
- **Carry-forward decisions:** <0–N one-line decisions the next phase needs that are NOT already captured in the artifact; 'none' if none>
```

Rationale for each field: `Last completed` + `Artifact` + `Next step` = where we are and what's next; `Suggested session name` = the `/rename` label (also printed live); `Carry-forward decisions` = the thin cross-phase state that lives outside the artifact (e.g. "chose `--full` profile", "descoped repo X") — the only thing genuinely at risk on a `/clear`.

### 4.4 The suggestion — role-aware (rides `next-phase-offer`'s transition)

The reference states a **rule**, not a brittle per-command table. Each command already emits **role-labeled** next options via `next-phase-offer`; the suggestion reads those labels:

- For each next option the offer names, compare its role label to the **just-finished command's role**:
  - **same role** → **`/compact`** (context still relevant; keep the thread);
  - **different role** → **`/clear`** *is the better choice when one person continues wearing both hats* (a truly different person just starts fresh and re-reads disk — also fine); `/compact` still works if continuing right away.
- When a command's next options **span both** (e.g. `/create-vi` → PM `/release-notes` **or** hand to PA `/create-ard` / PE `/epics`), the block presents **both branches** — "continuing as PM → `/compact`; handing off (even to yourself) → `/clear`."
- **User signalled done / end of session** → suggest nothing beyond the normal closure.

Because the role graph is owned by `next-phase-offer.md`, no command hardcodes a compact/clear verdict; illustrative examples in the reference: `/design E1 → /design E2` (Team→Team) = `/compact`; `/epics` (PE) → `/design` (Team) = `/clear`.

### 4.5 Mid-phase checkpoints & non-pipeline big commands

- **`/implement` mid-phase checkpoint** (Scope-to-N / per-Epic, per `context-management.md`) → suggest **`/compact`** to free budget before continuing. This is the "and phases" half of the task. `context-management.md` gains a one-line pointer to `session-hygiene.md`; the checkpoint suggestion is `/compact` only (mid-command → no role transition, no `/clear`).
- **`/vuln`, `/upgrade`** (big, non-pipeline, no role transition) → a plain end-of-run **`/compact`** suggestion only — never the `/clear`-handoff variant, and no `resume.md` (their durable state is the branch/PR). Delivered as a short line near their existing `impl-maintenance` handoff.

### 4.6 Session-name aid

The VI-Key is first available at **`/release-notes`** and is present for **every PA/PE/Team command** (`/create-ard`, `/epics`, `/specify`, `/design`, `/ready`, `/implement`, `/document`, `/release-notes` — all take `<VI>`). For those, print a suggested `/rename <VI-ID>-<slug>-<role>` line so the user can relocate the session in `claude --resume` later (e.g. after going home). `<role>` is the just-finished command's lane tag (PM / PA / PE / team). Guidance-only — a command cannot run `/rename` itself (it is user-invoked); it suggests the line.

**`/idea` and `/create-vi` are excluded** from the rename aid: the PM ideation phase runs *before* the paste-into-Jira + re-import round-trip that mints the VI (the key `/create-vi` takes is the seed RFE, not the VI-ID). It is a short phase, so no label is auto-suggested there — the PM names the session manually if they want one. The label is recorded in `resume.md` (§4.3) only when a VI-Key is present.

### 4.7 Contract rules (in `session-hygiene.md`)

Same shape as `next-phase-offer.md`'s rule list:

1. **Guidance-only** — never auto-invokes `/compact`, `/clear`, or `/rename`.
2. **Prepare-first** — the disk flush (`resume.md`) always precedes the printed suggestion, so acting on the suggestion is safe. The prepare step is **unconditional** (VI-scoped); only the suggestion is adaptive.
3. **Role-aware via a single graph** — the compact/clear split reads `next-phase-offer.md`'s role labels; the role graph is NOT duplicated here.
4. **Mode-aware** — direct / doc-edit / non-pipeline runs (no VI/Epic context) → no `resume.md`, no `/rename`, and the suggestion degrades to a plain optional `/compact` note (or is omitted, consistent with `next-phase-offer`'s mode-aware omission).
5. **Never blocks** — a nudge appended to the Final Report, exactly like the next-phase offer.

### 4.8 Surface / placement

The suggestion sits **with the `### Next step` section** at the end of the Final Report (the `next-phase-offer` surface), because it is a function of the same transition. Concretely each affected command gains:
- a short **`### Context`** (sub)block appended to / adjacent to `### Next step` in its Final Report, citing `session-hygiene.md`;
- one **invariant bullet** citing `session-hygiene.md` (mirroring how commands cite `next-phase-offer.md`).

Wiring targets: the **10 pipeline commands** (end-of-run) + **`/vuln`** + **`/upgrade`** (end-of-run, plain `/compact` line) + **`/implement`** checkpoint section (mid-phase `/compact`).

## 5. No-regression

- **Strictly additive** to Final Reports and one new reference file.
- **Sibling plugins byte-identical:** `dt-style-guide` 0.2.2 and `obsidian-llm-wiki` 0.3.1 untouched (0-line diff).
- **`/vuln` + `/upgrade` intentionally change** this effort (they gain a `/compact` line) — their prior "0-diff" status is deliberately relaxed per the approved scope. This is the ONE relaxation; call it out in the plan's Global Constraints and the whole-branch review so it is not mistaken for a regression.
- **Counts unchanged** — no new command/agent → manifest count-strings "Twenty" / "Thirty" byte-identical.
- **Direct / doc-edit mode paths** for `/implement` and `/document` remain byte-identical where they omit the block (mode-aware omission, rule 4).

## 6. Versioning

- Bump **2.28.0 → 2.29.0** in lock-step across `plugins/dev-workflows/.claude-plugin/plugin.json` (version line) and repo-root `.claude-plugin/marketplace.json` (dev-workflows entry).
- CHANGELOG: new `## [2.29.0] — 2026-07-13` entry (Added: `session-hygiene.md` + compact/clear/rename suggestions + `resume.md`; Changed: `/vuln` + `/upgrade` gain a `/compact` nudge; Notes: no new command/agent, counts 20/30, guidance-only).

## 7. Out of scope

- **Renaming `dev-workflows/` → `.dev-workflows/`** (hidden convention). Rejected here: our dir is a *visible, committed* part of the VI record (opposite of `.superpowers`, which is git-ignored scratch); hiding it fights the find-things goal, is a cross-cutting rename, and would orphan existing on-disk folders. If ever wanted, it is a dedicated migration effort.
- **A `SessionStart` auto-name hook** — cannot know the VI/role at session start and would fire for every session (§3). We suggest `/rename` instead.
- **Auto-invoking `/compact` or `/clear`** — the feature is suggest-only by design.
- **Persisting to the operator's `~/.claude/.../memory/` store** — non-portable; rejected in favor of the disk artifact layer (`resume.md`).

## 8. Assumptions

- `next-phase-offer.md` role labels are reliable and present for every pipeline command (verified: all 10 cite it).
- The VI-Key (VI-ID) is first available at `/release-notes` and is present for every PA/PE/Team command (all take `<VI>`). `/idea` and `/create-vi` run before the paste-into-Jira + re-import round-trip that mints the VI, so they carry no VI-Key — the `/rename` aid is omitted there (§4.6), and `/idea` additionally writes no `resume.md` (§4.2). `<slug>` and the command's `<role>` lane tag are always computable at finalization.
- Writing/overwriting one small `resume.md` per finalization is acceptable noise (single file, not a log) — accepted by the requester for determinism/safety.

## 9. Verification (structural — no test framework)

- `grep -rln "session-hygiene" commands/ references/` lists the new reference's citations (expected: the wired commands + `next-phase-offer.md` + `context-management.md`).
- `grep -c "Twenty\|Thirty" ...` / manifest reads: count-strings unchanged.
- `python3 -c "import json,sys; json.load(open(p))"` on both manifests → parse clean at 2.29.0.
- `git diff --stat` shows sibling-plugin files 0-diff; `/vuln` + `/upgrade` changed (expected, the one relaxation); `dt-style-guide` + `obsidian-llm-wiki` untouched.
- `grep -n "resume.md" references/session-hygiene.md` confirms the fallback tiers + format are specified.

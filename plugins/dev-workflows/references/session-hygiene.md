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

**Redact before writing.** The `Carry-forward decisions` line may summarize content pulled from a Jira
ticket or the session — redact any secret, credential, token, or PII. A resume pointer records *what to do
next*, never a sensitive value.

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

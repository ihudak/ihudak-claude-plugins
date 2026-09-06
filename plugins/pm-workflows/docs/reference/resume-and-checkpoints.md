# Resume and checkpoints

A long-running command ends by doing two separate things: it flushes a small pointer file to disk recording exactly where things stand, then it suggests — never performs — the right context action for what comes next, `/compact`, `/clear`, or a session `/rename`. Both are guidance only; the plugin never invokes any of those three itself. The point is to stop relying on you to remember to ask "am I ready to compact or clear" — the pipeline does the disk-flush itself and hands you the choice already framed. The mechanism itself is shared across the whole family; this page describes what `pm-workflows`'s own twelve commands do with it.

## What `resume.md` is for

`resume.md` exists so you can pick a run back up in a fresh session without re-deriving what the last one already established — what command ran last, what it produced, and what to run next — instead of scrolling back through a compacted or cleared transcript, or worse, re-reading every artifact from scratch to reconstruct where you left off. It is a **"last known position" pointer, overwritten every run, not an append log** — there is exactly one current answer to "where am I," not a history of every past one. It stays intentionally tiny:

```markdown
# Resume — <KEY>[ / <EPIC-KEY>] (<role>)

- **Last completed:** <command> <args> — <phase or 'command complete'> (<ISO datetime>)
- **Artifact:** <relative path to the deliverable just written/committed, or 'none (read-only)'>
- **Next step:** <the exact next command from ### Next step, or 'PRD fully processed'>
- **Suggested session name:** <PRD-ID>-<slug>-<role>   (omit this line when no PRD-Key exists yet — e.g. /idea)
- **Carry-forward decisions:** <0–N one-line decisions the next phase needs that are NOT already in the artifact; 'none' if none>
```

Any secret, credential, token, or other sensitive value that might otherwise land in the `Carry-forward decisions` line is redacted before writing — a resume pointer records what to do next, never a value worth protecting.

**When it's written.** The write is unconditional for any PRD-scoped run, and it happens first — before the terminal `commit-artifacts` step, but only after the deliverable artifact is already saved or committed, and after the feedback and cost phases have all run. The canonical terminal order is deliverable and handoff, then feedback, then cost, then `resume.md`, then `commit-artifacts`. Whether the suggestion (below) actually fires or not, the write itself always happens — **prepare always, suggest adaptively.**

**Where it lands.** Three tiers, walked in order: `$SPECS_PATH` writable with the PRD directory matched → `<PRD-dir>/dev-workflows/resume.md` — a fixed, family-wide folder name shared with the cost and feedback files described elsewhere in this reference section, not a `pm-workflows`-specific path — the primary case; `$SPECS_PATH` writable but **no PRD directory matched** → the file is skipped outright and the run relies on the printed `### Next step` instead; and `$SPECS_PATH` not writable → skipped, with a one-line warning that no resume pointer could be persisted and you should set it.

**Which runs skip it entirely.** `/idea` does resolve a PRD folder, but its brief is handed off in the same run rather than resumed later, so a pointer would only go stale.

## The suggestion: `/compact` or `/clear`

Every next-step option a command offers already carries a role label — see [Roles and phases](../roles-and-phases.md) for what PM, PA, and PE each own. The context-hygiene suggestion reads those same labels rather than hardcoding a per-command verdict:

- **Staying in the same role** for the next step (`/create-prd` → PM `/update-prd`, or `/brd-intake` → `/brd-split`, both PM) → **`/compact`** — the context is still relevant, so keep the thread going.
- **Moving to a different role** (`/epics` PE → `/create-ard` PA, or `/create-prd` PM → the companion plugin's `/dev-workflows:design` Dev) → **`/clear`** is the better default when one person is wearing both hats, since the prior role's reasoning becomes noise for the next one; `/compact` still works fine if you're continuing right away yourself.
- **The next step could go either way** (`/create-prd` → PM `/docs-workflows:release-notes`, or handing off to PA/PE) → both branches are named explicitly: continuing as the same role suggests `/compact`, handing off — even to yourself — suggests `/clear`.
- **You're done, or ending the session** → no suggestion at all.

`/brd-ground` is the one command on this route with a role transition inside its own name — PM-initiated, PA/Dev-executed — but the suggestion follows what the *next* command's role is, not this one's, exactly as every other transition does.

## The `/rename` aid

Within this rename-aid set, every PA/PE command that takes a `<PRD>` or `<EPIC>` argument (`/create-ard`, `/epics`, `/specify` here, and the companion plugins' `/dev-workflows:design`, `/dev-workflows:ready`, `/dev-workflows:implement`, `/docs-workflows:document`, and `/docs-workflows:release-notes`) prints a suggested `/rename <PRD-ID>-<slug>-<role>` line, so you can find this session again later in `claude --resume` by name instead of by scrolling. `<role>` is the lane tag of the command that just finished — pm, pa, or pe here. `/idea` and `/create-prd` are excluded from this aid: idea refinement is short, it usually runs before the handoff that lands the PRD key in the first place, so there is often no key yet to name the session after — and on the rarer runs that do carry one already, the phase is still short enough that naming the session isn't worth automatically suggesting. The same exclusion applies to every BRD-route command up through `/brd-package`: a BRD key exists from the first command, but the route's own short-phase reasoning still holds until a PRD-ladder command inherits it.

## Mid-phase checkpoints

None of `pm-workflows`'s twelve commands is long enough to carry its own mid-phase checkpoint the way the companion plugin's `/dev-workflows:implement` does — each authoring or grounding run finishes in one pass and reaches the end-of-run write described above.

## The contract

Five rules bound everything above: it is **guidance-only** — `/compact`, `/clear`, and `/rename` are always suggested, never invoked by the plugin itself; the disk flush is **prepare-first** — unconditional for a PRD-scoped run and always ahead of the suggestion it accompanies, so acting on the printed suggestion is always safe; the compact-versus-clear split is **role-aware through a single graph**, reading role labels from the next-step offer rather than duplicating that graph here; the whole mechanism is **mode-aware**, degrading to a plain optional `/compact` note (or nothing at all) on a run with no PRD anchor to write a pointer against; and it **never blocks** — the guidance is a nudge appended to the end of the Final Report, exactly like the next-phase offer it sits beside.

The full mechanics — the exact `resume.md` write procedure, the redaction rule, and the `### Context hygiene` block's own shape — live in `workflows-core:session-hygiene`, which this page describes from `pm-workflows`'s side rather than restates.

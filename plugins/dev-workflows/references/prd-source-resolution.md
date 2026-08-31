# Resolving an existing PRD (Jira-import-first — shared reference)

The authoritative text of an **existing** Product Requirements Document lives in **Jira**, not in the `$SPECS_PATH`
markdown. `/create-prd` writes the PRD to `$SPECS_PATH` as the *initial* draft; once it is pasted into
Jira it is edited by people (and gains comments) there, while the specs draft stays frozen. Any workflow
that consumes an existing PRD — `/update-prd` (its base) and `/create-prd --from-prd` (its seed) — MUST read
the re-imported Jira PRD first.

This is an **adjacent** policy to `references/source-truth.md` (which governs code-vs-docs verification):
this file governs *which artifact holds the current PRD text*, not code truth. Do not conflate them.

## Procedure — `resolve-existing-prd <KEY>`

1. **Validate** `<KEY>` against `^[A-Z][A-Z0-9_]*(-\d+)+$` — the grammar `references/addressing.md` §1
   fixes, a superset of the two-segment form, so every key that validated here before still does.
   The extra depth is needed by both callers: `/update-prd` is redirected to with the key
   `/create-prd` resolved, and a PRD authored inside a BRD slice by `/create-prd --from-brd` carries a
   three-segment one. Malformed → stop and report.
2. **Resolve the tracker key — `<KEY>` is an address, and an address is not a tracker identity.**
   Two keys, two uses, and they are never interchangeable. A **BRD key** (`EPIC-008-01`) names a
   folder in `$SPECS_PATH`; it is validated for shape only and **never looked up on a tracker**
   (`references/addressing.md` §1). A **tracker key** is the one the tracker minted, and it is
   the only key `jira-products/` resolves and the only key `jira-reader` accepts — that agent
   validates `^[A-Z][A-Z0-9_]*-\d+$` and refuses everything else, a three-segment slice key
   included. So locate the frozen specs draft **first** and read the tracker key off it:

   - Resolve the feature folder for `<KEY>` with `resolve-address` (`references/addressing.md` §3),
     which searches every level it bounds and carries §5's legacy fallback, so a PRD authored inside
     a BRD folder is found — then read that folder's **`prd.md`**, confirming frontmatter
     `issue_type: ValueIncrement`. That file is the **frozen specs draft**; step 6 reads its body as
     secondary grounding, and this step reads nothing from it but two frontmatter keys.

     The filename is the discriminator now that a PRD is `prd.md` rather than a keyed glob
     (`references/prd-format.md`); the `issue_type` check is kept alongside it because a specs repo
     written before the rename still holds `<KEY>_<slug>.md`, which §5's fallback resolves the folder
     for and which this check is what identifies inside it.
   - The draft carries a `jira_key` → **`<TRACKER-KEY>` is that value.** It is what `/create-prd`'s
     Jira round-trip recorded, and that round-trip is the only step that ever gives a BRD key a
     tracker identity.
   - The draft carries a `brd_key` and **no** `jira_key` → **no tracker identity exists yet.** Do not
     substitute `<KEY>`: `jira-products/<BRD-KEY>` is a path no importer can create, so there is
     nothing to look for. Go straight to step 4's paste-first branch.
   - No draft, or a draft carrying neither key → **`<TRACKER-KEY>` is `<KEY>` itself.** This is the
     flat, non-BRD case, where the caller was handed a key the user had already minted on the
     tracker, and it resolves exactly as it did before this step existed.

   Every `jira-products/` path below is built from `<TRACKER-KEY>` and never from `<KEY>`.
3. **Jira import first.** Look for `$VAULT_PATH/jira-products/<TRACKER-KEY>/**/<TRACKER-KEY>.md` and
   its sibling `<TRACKER-KEY>-comments.md`. Confirm the frontmatter is `issue_type: ValueIncrement`.
   This import (body + comments) is the **authoritative base**.
4. **Not imported →** STOP. Ask the user to import it, then re-run:
   `choices: ["Import <TRACKER-KEY> now with the workitem-importer, then I'll re-run (Recommended)", "Cancel", "Other… (describe)"]`.
   Cite the importer: `https://github.com/ivan-gudak/jira-workitem-import`. Never fall back to the frozen
   specs draft as the base.

   **Where step 2 read a `brd_key` off the frozen draft, the workitem may not exist yet, and the
   stop says which of the two states this run is in rather than offering an import that cannot be
   performed.** A BRD key is a folder name in `$SPECS_PATH`, validated for shape and never looked up
   on a tracker (`references/addressing.md` §1), so a PRD `/create-prd --from-brd` authored can
   be on disk while no workitem has ever been created — and "import it" then names a step nobody can
   take. The two states are distinguished by whether step 2 resolved a `<TRACKER-KEY>` at all:

   - **A `jira_key` was found, but no import exists under it.** The round-trip minted the key and the
     import half has not been run. Offer the import above, against `<TRACKER-KEY>`.
   - **No `jira_key` was found.** The round-trip has not happened. The first move is its **paste**
     half — create the workitem, paste the PRD body into it, and record the key the tracker mints as
     the PRD's `jira_key` (`commands/create-prd.md`'s Jira round-trip, step 1) — and the import
     follows. Offer that instead, and name no tracker key in either option, because none exists yet:
     `choices: ["Create the workitem for <KEY> and paste the PRD body in, record its minted key as jira_key, then import — I'll wait (Recommended)", "It already exists — give me its tracker key and I'll re-run", "Cancel", "Other… (describe)"]`.

   The rule that the import is the authoritative base is unchanged; only the instruction for reaching
   one is.
5. **Imported but stale →** if the import file's mtime is older than **3 days**
   (`find "$VAULT_PATH/jira-products/<TRACKER-KEY>" -name "<TRACKER-KEY>.md" -mtime +3`), show the
   import date and offer:
   `choices: ["Re-import <TRACKER-KEY> now — I'll wait (Recommended)", "Proceed with the current import", "Cancel", "Other… (describe)"]`.
6. **Secondary grounding (read-only; never the base):** the frozen `$SPECS_PATH` specs draft step 2
   already located (`prd.md`, `issue_type: ValueIncrement`), the folder's `ard.md` and any
   `ard-<area>.md`, `specification.md`, and — for `/update-prd` — a user-supplied `@transcript` /
   notes path. These enrich the grill; they never override the Jira import.

Product-level only — this reads markdown/comments; it mounts no repos and runs no code scan.

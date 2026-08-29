# Follow-ups

A follow-up is a task line written into your vault for something a command's run surfaced but could not finish itself — a manual publish step, a file owned by someone else, a Jira ticket that needs updating to match a spec. `/document`, `/release-notes`, `/epics`, `/implement`, and `/ready` each carry a terminal "Emit follow-up tasks" phase that applies the same rules described here. Nothing is ever written without you seeing it first — every qualifying follow-up is shown as a batch preview at the very end of the run, and only a single confirmation actually commits any of it to disk.

## The task line

A follow-up renders as one Obsidian-Tasks-style line:

    - [effort] Description #tag1 #tag2 priority ⏳ scheduled 📅 due ➕ <today>

`effort` is a Fibonacci checkbox — `[0]` tiny, `[1]` under an hour, up through `[13]` multi-week — or a bare `[ ]` when effort genuinely isn't known; when unsure between two sizes, the larger one is used. `Description` is one imperative line naming the out-of-scope action. Tags are **reuse-only**, pulled from your vault's own `tag-index.md` — a follow-up never invents a new tag, and if no tag index exists, tags are simply omitted with a one-time warning rather than guessed. Priority (`🔺⏫🔼🔽⏬`) is optional and placed after tags. The creation date (`➕ <today>`) is always added; scheduled (`⏳`) and due (`📅`) dates are added only when the signal itself implies a timeframe. When the follow-up is tied to a Jira key, the line renders it as a clickable link to `<base>/browse/<KEY>`, using whatever base URL your existing vault tasks already use, falling back to the bare key as plain text if no base URL can be found.

## Where it lands

Resolution is Jira-key-first and deterministic — there is no interactive "pick a location" prompt for a single task. With a writable vault and a resolved `jira_key`, the task is inserted into that Jira key's own project file (`P<NNNN> <slug>.md`, matched under `Projects/`), under its `## Work Items → ### Tasks` section, provided that file's frontmatter still marks it an active, non-archived task file. Without a project match — no `jira_key`, or the project file fails that verification — the task falls back to `$VAULT_PATH/Tasks.md`, under an `# Irregular` heading, creating that file from a bootstrap template if it doesn't already exist. A follow-up is never inserted into an archived section, a Daily note, or anywhere excluded from your dashboard queries. When a follow-up needs more than one line of context — a table, a paste-ready draft, multi-step detail — the same primary-then-fallback split applies to the note it links: a project-homed task gets its note appended to that file's own `### Notes` section, while a `Tasks.md`-homed task gets its note appended to `Journal.md` as a dated block instead; either way the task line links to the note rather than duplicating it inline.

## When there's no vault

Vault availability is checked first, and the write target degrades through a fallback ladder, most-durable option first:

1. **Vault writable** → the project-file/`Tasks.md` split above, as the primary case.
2. **No vault, but `$SPECS_PATH` resolves to the PRD's own spec directory** → `<PRD-dir>/dev-workflows/<KEY>-followups.md`, with any verbose note inlined as a section of that same file rather than a separate `Journal.md`, since there is no vault to hold one.
3. **No vault, no matching `$SPECS_PATH` PRD directory, but the run's source was an imported Jira directory** → written beside that imported directory, the same place `/epics` and `/release-notes` already drop their own no-vault output.
4. **Nothing resolvable** → report-only: the follow-ups stay in the run's Final Report and nothing is written anywhere. The plugin never writes into your current working directory on this path, since it may be a code repository.

Every non-vault tier also keeps the follow-ups visible in the Final Report, so a degraded write location never means lost information — only a less durable one, flagged with a notice naming the fallback path used.

## What qualifies as a follow-up

Only a signal whose action lands **outside the current change** or needs a **manual human step** becomes a follow-up: a file or page owned by someone else, a manual publish step (uploading a screenshot, pasting release notes into Jira, creating Epics in Jira by hand), a spec-versus-Jira mismatch that needs the ticket updated to match, or an unresolved PR on a host the plugin can't reach and so must be documented by hand. It deliberately does **not** fire for anything the run's own report or draft already tracks in scope — a deferred review BLOCKER, a skipped test, an in-draft `<!-- TODO -->` marker — since those belong to the current task and duplicating them as a separate vault task would just create two places tracking the same thing. If nothing in a run qualifies after this filter, the whole phase is a silent no-op: no preview, no prompt, nothing written, and the run looks exactly as if the phase didn't exist.

Before anything is inserted, the target section is checked for a follow-up with the same stable key — `jira_key` plus the file path, gap id, or signal type that identifies it — and a match is skipped and reported rather than re-inserted, so re-running a pipeline over the same ground never duplicates a task that's already there.

## Reviewing before anything is written

Follow-ups never interrupt a run mid-flight. Once the Final Report is composed, every qualifying follow-up is shown together as one batch preview, grouped by the file it would land in, each row naming the triggering signal, the target file and section, and the exact task line that would be written. You act on all of them with a single choice — approve every previewed row, select a subset by row number, or cancel and leave everything in the report only. Nothing reaches the vault, or any fallback location, without that one confirmation.

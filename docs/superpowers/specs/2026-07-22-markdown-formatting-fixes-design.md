# Markdown formatting fixes — no hard-wrap prose + VI ID round-trip corruption — design

- **Date:** 2026-07-22
- **Status:** Approved (brainstorming complete; ready for implementation plan)
- **Repo scope:** `plugins/dev-workflows/` (this repo) for Fix 1 only; the
  user's `obsidian-vault` repo — both
  `$VAULT_PATH/.obsidian/scripts/custom/jira-workitem-import/src/jira_markup_converter.py`
  and its sibling fork
  `$VAULT_PATH/.obsidian/scripts/custom/jira-bulk-import/src/jira_markup_converter.py` —
  for Fix 2 entirely. Two independent repos, two independent commits.
- **Target version:** dev-workflows 2.37.0

## Problem

Reported as one bug ("markdown formatting"), this is actually two independent
defects surfaced by reviewing authored VI/Epic/ARD/Spec content in Obsidian or
IntelliJ Idea and then pasting it into Jira.

**1. Hard-wrapped prose.** When Claude Code (or Copilot) authors a VI, Epic,
ARD, or Spec, prose sections get hard-wrapped at roughly 80–100 characters —
convenient for a raw terminal `cat`, but redundant in Obsidian/IntelliJ (both
soft-wrap to the pane width already) and actively harmful when the text is
pasted into Jira: every wrap point becomes a spurious line/paragraph break,
which the user then has to manually clean up, and which confuses Grammarly's
sentence-boundary detection in the meantime. Nothing in this repo mandates the
wrapping — `vi-format.md`, `ard-format.md`, `specification-format.md`,
`design-format.md`, `pre-lint.md`, and `CLAUDE.md` are silent on line width.
It is the model's own habitual prose formatting, not a repo convention, so the
fix is an explicit counter-instruction rather than a bug removal.

**2. VI ID markers get corrupted by the Jira paste/re-import round-trip.**
`/create-vi` and `/update-vi` author User Story / Acceptance Criteria /
Success Metric IDs as `[US-N]` / `[AC-N]` / `[SM-N]` (`vi-format.md`), then
paste the VI body into the Jira workitem and re-import it to
`$VAULT_PATH/jira-products/<KEY>` via `jira-workitem-import`
(`create-vi.md`/`update-vi.md`, "paste + re-import"). Confirmed against the
real `PRODUCT-18503` export: `[US-1]` comes back as `[[[US-1]]]`, and
`**[US-1]**` comes back as `*[[[US-1]]]*` (a separate bold→italic mangle from
the same round-trip, left as a known side-effect — see Out of scope).
In Obsidian, the leftover triple brackets partially parse as a broken
wikilink (`[[US-1]` + a stray trailing `]`), which is the "confuses Obsidian"
symptom as originally reported — but the actual corruption happens upstream,
in the importer, not in Obsidian's renderer.

The vault has **two** independently-forked copies of this converter — one in
`jira-workitem-import` (single-ticket import) and one in `jira-bulk-import`
(bulk import) — both with the identical bug (`_format_issue_link` differs
cosmetically: wikilink `[[key]]` in one, standard Markdown link `[key](url)`
in the other, but the unguarded regex and the resulting corruption class are
the same in both).

Root cause, found in `jira_markup_converter.py`'s `_convert_links`
(both copies, same line numbers):

```python
# line 325 — plain [text] that isn't URL-like is left untouched
text = re.sub(r'\[([^\]]+)\](?!\()', replace_plain_link, text)
...
# line 363 — blindly wikilink-ifies ANY KEY-shaped token, with no check
# for "is this already sitting inside a bracket pair left alone above"
text = re.sub(r'\b([A-Z]{2,10}-\d+)\b', replace_issue_key, text)
```

Only already-double-bracketed (`[[...]]`) and already-parenthesized
(`[...](...)`) spans are protected before the issue-key sweep runs (lines
338–360); an already-single-bracketed span like `[US-1]` is not, so its inner
`US-1` gets wikilink-ified into `[[US-1]]`, nesting inside the untouched outer
brackets to produce `[[[US-1]]]`.

This means a bracket-free VI ID convention (`US-1` with no brackets at all)
would **not** fix this — the same line-363 regex would still catch the bare
token and wikilink-ify it into `[[US-1]]`, a dead link to a nonexistent note,
trading one corruption for another. The VI ID syntax itself is not the bug;
the importer's unguarded regex is.

## Goal / success criteria

- Freshly authored VI/Epic/ARD/Spec/design/doc/release-notes prose contains no
  artificial mid-paragraph line breaks — each paragraph/prose block is one
  line in the source file.
- A VI pasted into Jira and re-imported comes back with `[US-N]`/`[AC-N]`/
  `[SM-N]` intact (no bracket multiplication).

## Scope

**In scope:**

| Fix | Where |
|---|---|
| No-hard-wrap prose convention | New shared reference in `dev-workflows`, cited by every authoring command/agent that writes prose |
| Importer regex guard | One-line fix in `jira_markup_converter.py`, applied to both `jira-workitem-import` and `jira-bulk-import` (`obsidian-vault` repo) |

**Out of scope:**

- Changing the VI's `[US-N]`/`[AC-N]`/`[SM-N]` bracket syntax. Not needed once
  the importer stops mangling it (see Problem §2); a syntax change would have
  touched 6 files for no benefit.
- ARD/spec/design ID markers (`[AD-N]`, `[Uxx]`, `[ACxx]`, `[TCxx]`) — these
  artifacts are never pasted into Jira (they land via branch+PR to the specs
  repo), so they're not exposed to this corruption vector at all.
- The `**bold**` → `*italic*` mangle observed on the same `**[US-1]**` line in
  the PRODUCT-18503 round-trip. Same failure family (Jira paste/export
  degrading markdown fidelity) but a distinct bug in a different code path;
  not blocking and not part of what the user reported. Flagged here for a
  future look, not fixed now.
- A pre-lint/reviewer check that flags hard-wrapped prose mechanically.
  Reliably distinguishing "hard-wrapped mid-sentence" from "legitimately
  short line" (tables, code blocks, frontmatter, a genuinely short paragraph)
  is fuzzy; this stays a writer-side instruction, not a review gate.
- Re-writing already-exported vault files (e.g. `PRODUCT-18503.md` under
  `$VAULT_PATH/jira-products/`) to strip existing corruption. Left as-is —
  cosmetic until that specific VI is worked again, at which point a fresh
  re-import (see below) produces a clean copy through the fixed importer.
- Defensive bracket-normalization in `jira-reader` for legacy corrupted
  imports. Considered and rejected: `/create-vi` and
  `/update-vi` already gate on a 3-day freshness check before treating a
  vault import as authoritative, and in practice the user always re-imports
  before working a VI with any command — so once Fix 2 ships, nothing
  `jira-reader` actually reads at the point of use stays corrupted. The other
  seven commands that call `jira-reader` (`/document`, `/epics`,
  `/release-notes`, `/specify`, `/ready`, `/create-ard`, `/implement`
  multi-source fan-out) have no automated freshness gate at all — they rely
  on the same manual-re-import habit — so this is a real (if narrow) reliance
  on user discipline rather than a mechanically enforced guarantee. Accepted
  as a reasonable trade-off given it's a single-user private plugin
  marketplace; revisit (re-add jira-reader normalization) if that discipline
  ever lapses or the plugin gains other users.
- Porting to `mgd-claude-plugins` / `ihudak-copilot-plugins`. Follow-up, same
  pattern as prior cross-repo ports (verbatim for mgd, adapted for Copilot).

## Fix 1 — No hard-wrap prose convention

**New file:** `plugins/dev-workflows/references/prose-formatting.md` — single
source of truth, following the repo's existing pattern (`docs-grounding.md`,
`source-truth.md`, `release-note-types.md`). Content: never hard-wrap prose;
write each paragraph/prose block as one unbroken line; the viewer (Obsidian,
IntelliJ) soft-wraps for reading, and this keeps a straight copy-paste into
Jira/Grammarly clean.

**Consumers — one citation line added at each writer's authoring step:**

*Commands with embedded writing* (cite `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`
directly, following the existing pattern already used a dozen times over in
`create-vi.md` for `vi-format.md`/`docs-grounding.md`/`grilling-technique.md`
etc.):
- `commands/idea.md`
- `commands/create-vi.md`
- `commands/update-vi.md`
- `commands/create-ard.md`
- `commands/specify.md`
- `commands/design.md`

*Commands with a dedicated writer agent* (cite it in the agent body instead,
since the agent is what actually produces the prose):
- `agents/epic-writer.md` (used by `commands/epics.md`)
- `agents/doc-writer.md` (used by `commands/document.md`)
- `agents/release-notes-writer.md` (used by `commands/release-notes.md`)

**CLAUDE.md:** one new bullet under "Source-truth reference" documenting
`prose-formatting.md` and its consumer list, matching the existing entries
for `docs-grounding.md` / `source-truth.md` / `release-note-types.md`.

## Fix 2 — VI ID round-trip corruption (`obsidian-vault` repo)

Applied to **both** `jira-workitem-import/src/jira_markup_converter.py` and
`jira-bulk-import/src/jira_markup_converter.py` — line 363/364 respectively,
guarding the issue-key sweep so it skips a token already sitting inside a
single bracket pair:

```diff
- text = re.sub(r'\b([A-Z]{2,10}-\d+)\b', replace_issue_key, text)
+ text = re.sub(r'(?<!\[)\b([A-Z]{2,10}-\d+)\b(?!\])', replace_issue_key, text)
```

`[US-1]` is left alone (already inside `[...]`, so no link wrapping); a bare
mention like `See PRODUCT-18503 for details` is unaffected and still gets
linkified, since it isn't bracketed. One line each, in `jira_markup_converter.py`
only — no other conversion path (table cells, `_convert_cell_content`) does
issue-key linkification in either tool, so no other call site needs the same
guard. Neither tool had existing test coverage for `_convert_links`
(`tests/test_additional_fields.py` doesn't touch it in either) — added
`tests/test_jira_markup_converter.py` to each, asserting `[US-1]` round-trips
unchanged and a bare `PRODUCT-18503` mention still gets linkified. Both
verified directly (no `pytest` available in either `.venv` in this sandbox —
no network access to install it — so verified via a standalone script
exercising the same assertions; the committed test files run normally
wherever the dev dependencies are installed).

The `jira-workitem-import` working tree has unrelated uncommitted changes
already sitting in it (`recent-files-obsidian/data.json`, `workspace.json`,
`Projects/AI-First/AI-First.md`). The fix touches only the two
`jira_markup_converter.py` files and their two new test files; nothing else
in that tree is staged or committed as part of this work.

No changes needed in `dev-workflows` for this fix — `vi-format.md`,
`pre-lint.md`, `vi-reviewer.md`, `create-vi.md`, `update-vi.md`, and
`jira-reader.md` are all untouched. The `[US-N]`/`[AC-N]`/`[SM-N]` syntax
stays exactly as it is today (see Out of scope for why a defensive
`jira-reader` normalization pass was considered and rejected too).

## Testing / verification

- **Fix 1:** author a fresh VI (or re-run `/create-vi` on a scratch ticket)
  and confirm the Problem/Goal/User Story prose has no mid-paragraph line
  breaks in the written file.
- **Fix 2:** regression tests added and passing (verified directly, per
  §Fix 2) for both `jira-workitem-import` and `jira-bulk-import`. Follow-up:
  re-import `PRODUCT-18503` for real and confirm the refreshed vault copy has
  clean single-bracket IDs end-to-end.

## Rollout

- Bump `dev-workflows` to 2.37.0 (`plugin.json`, `CHANGELOG.md`) for Fix 1
  (the only change in this repo).
- Land the `obsidian-vault` fix (Fix 2) as one commit covering both tools,
  scoped to the two `jira_markup_converter.py` files + their two new test
  files only — do not touch or commit the unrelated pending changes already
  in that working tree. Independent of the dev-workflows release; no version
  coupling between the two.
- Port Fix 1 to `mgd-claude-plugins` (verbatim) and `ihudak-copilot-plugins`
  (Copilot-adapted) as a follow-up, per the established porting pattern.

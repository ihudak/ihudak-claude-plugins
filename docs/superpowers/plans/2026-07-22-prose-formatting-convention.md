# No-hard-wrap prose convention Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop authoring commands/agents from hard-wrapping prose at a fixed column width, so VI/Epic/ARD/spec/design/doc/release-notes content soft-wraps cleanly in Obsidian/IntelliJ and pastes cleanly into Jira.

**Architecture:** One new shared reference file (`references/prose-formatting.md`) states the rule; every authoring command with embedded writing cites it directly in its own body (the established pattern already used a dozen times over for `vi-format.md`/`docs-grounding.md`/etc.); every command with a dedicated writer agent gets the citation added to that agent's body instead, since the agent is what actually produces the prose.

**Tech Stack:** Markdown instruction files only — no executable code, no runtime. "Tests" here are deterministic `grep` checks that a citation string landed in the right file, mirroring this repo's existing `references/pre-lint.md` structural-check pattern (there is no code to unit-test; the artifact IS the instruction text).

## Global Constraints

- Fix 2 (VI ID round-trip corruption) is already implemented and committed in a separate repo (`obsidian-vault`) — out of scope here.
- `${CLAUDE_PLUGIN_ROOT}/references/<file>.md` citations work directly inside slash-command bodies in this repo (confirmed: `create-vi.md` already does this a dozen times over for `vi-format.md`, `docs-grounding.md`, `grilling-technique.md`, `pre-lint.md`, etc.) — no new skill wrapper needed.
- Target version: dev-workflows **2.37.0** (bump `plugin.json` + add a `CHANGELOG.md` entry).
- Today's date for the changelog entry: **2026-07-22**.
- Every command/agent touched keeps its existing citations and structure — this change only *adds* one citation each; nothing is removed or restructured.
- No changes to `plugins/dev-workflows/.claude-plugin/plugin.json`'s `description` field — this is an internal writer-behavior convention, not a new command/flag, and the existing description doesn't enumerate internal references like `docs-grounding.md` either.

---

## Task 1: Create the shared reference `references/prose-formatting.md`

**Files:**
- Create: `plugins/dev-workflows/references/prose-formatting.md`

**Interfaces:**
- Produces: a file at `plugins/dev-workflows/references/prose-formatting.md` containing a `## Rule` section — every later task cites this exact path via `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`.

- [ ] **Step 1: Write the assertion (file must not exist yet)**

Run: `test -f /workspace/ihudak-claude-plugins/plugins/dev-workflows/references/prose-formatting.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create the file**

Write `plugins/dev-workflows/references/prose-formatting.md` with this exact content:

```markdown
# Prose formatting — no hard-wrap (embedded — shared reference)

Every authored artifact (VI, Epic, ARD, spec, design, product doc, release note, idea) is reviewed
in Obsidian or IntelliJ Idea — both soft-wrap markdown to the pane width — and is routinely
copy-pasted into Jira. Hard-wrapping prose at a fixed column width (the common ~80–100 char
convention for raw-terminal readability) is redundant in both viewers and actively harmful in
Jira: every wrap point becomes a spurious line/paragraph break that the user must manually clean
up, and it confuses tools like Grammarly that rely on sentence boundaries.

## Rule

Never hard-wrap prose. Write each paragraph, list-item body, or other prose block as **one
unbroken line** in the source file, however long. Let the viewer wrap it for reading.

This applies to free-form prose (Problem, Goal, narrative descriptions, Summary bodies, Business
value, etc.). It does not apply to:
- Markdown structure that requires line breaks (headings, list markers, table rows, code blocks).
- A genuinely short line (a heading, a one-clause bullet) — the rule is about not *introducing*
  artificial breaks inside a paragraph, not about padding short content out.
```

- [ ] **Step 3: Verify it exists and contains the rule**

Run: `grep -c "Never hard-wrap prose" /workspace/ihudak-claude-plugins/plugins/dev-workflows/references/prose-formatting.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/references/prose-formatting.md
git commit -m "docs(dev-workflows): add prose-formatting.md no-hard-wrap reference"
```

---

## Task 2: Cite `prose-formatting.md` in the 6 embedded-writing commands

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md:116`
- Modify: `plugins/dev-workflows/commands/create-vi.md:116`
- Modify: `plugins/dev-workflows/commands/update-vi.md:58`
- Modify: `plugins/dev-workflows/commands/create-ard.md:102`
- Modify: `plugins/dev-workflows/commands/specify.md:346`
- Modify: `plugins/dev-workflows/commands/design.md:232-233`

**Interfaces:**
- Consumes: `plugins/dev-workflows/references/prose-formatting.md` (Task 1).
- Produces: nothing consumed by later tasks — each edit is independent and self-contained.

Each step below is: edit the file (exact old → new text), then grep-verify the citation landed.

- [ ] **Step 1: `commands/idea.md`**

Edit `plugins/dev-workflows/commands/idea.md`, replacing:

```
Author `idea.md` per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` into the write root resolved in
Phase 0:
```

with:

```
Author `idea.md` per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` into the write root resolved in
Phase 0, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`:
```

- [ ] **Step 2: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/idea.md`
Expected: `1`

- [ ] **Step 3: `commands/create-vi.md`**

Edit `plugins/dev-workflows/commands/create-vi.md`, replacing:

```
Author `<KEY>_<slug>.md` live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md` for the selected profile. Walk the **spine** in dependency order:
```

with:

```
Author `<KEY>_<slug>.md` live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md` for the selected profile, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`. Walk the **spine** in dependency order:
```

- [ ] **Step 4: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/create-vi.md`
Expected: `1`

- [ ] **Step 5: `commands/update-vi.md`**

Edit `plugins/dev-workflows/commands/update-vi.md`, replacing:

```
Update the VI live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md`, **diffing against the base** rather than authoring from blank: surface what changed and why (drawing on comments / ARD / spec / transcript), resolve open questions, keep the VI product-level. Apply the **self-consistency check** — no `[AC-N]` delivering an Out-of-scope behaviour, no `## Goal` vs `## Scope` contradiction, no conflicting `[US-N]`; record a deliberately-kept tension under `## Assumptions & open questions`. Preserve the frontmatter provenance fields (`sources`, `derived_from`, `seeded_from_vi` if present).
```

with:

```
Update the VI live against `${CLAUDE_PLUGIN_ROOT}/references/vi-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, **diffing against the base** rather than authoring from blank: surface what changed and why (drawing on comments / ARD / spec / transcript), resolve open questions, keep the VI product-level. Apply the **self-consistency check** — no `[AC-N]` delivering an Out-of-scope behaviour, no `## Goal` vs `## Scope` contradiction, no conflicting `[US-N]`; record a deliberately-kept tension under `## Assumptions & open questions`. Preserve the frontmatter provenance fields (`sources`, `derived_from`, `seeded_from_vi` if present).
```

- [ ] **Step 6: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/update-vi.md`
Expected: `1`

- [ ] **Step 7: `commands/create-ard.md`**

Edit `plugins/dev-workflows/commands/create-ard.md`, replacing:

```
Author the ARD live against `${CLAUDE_PLUGIN_ROOT}/references/ard-format.md` at the resolved altitude: Context → Grounding findings (cite `file:line`) → Architecture decisions (`AD-N`: Binds/Prevents/Rule) → Cross-repo/component approach → Stack & invariants → Edge cases & risks → Open questions → Deferred. At Epic level, list inherited VI-level ADs read-only and never contradict them; VI level stays at invariants/frame (no per-repo detailed solutions).
```

with:

```
Author the ARD live against `${CLAUDE_PLUGIN_ROOT}/references/ard-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, at the resolved altitude: Context → Grounding findings (cite `file:line`) → Architecture decisions (`AD-N`: Binds/Prevents/Rule) → Cross-repo/component approach → Stack & invariants → Edge cases & risks → Open questions → Deferred. At Epic level, list inherited VI-level ADs read-only and never contradict them; VI level stays at invariants/frame (no per-repo detailed solutions).
```

- [ ] **Step 8: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/create-ard.md`
Expected: `1`

- [ ] **Step 9: `commands/specify.md`**

Edit `plugins/dev-workflows/commands/specify.md`, replacing:

```
Walk the stages in order, authoring `specification.md` live against `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`:
```

with:

```
Walk the stages in order, authoring `specification.md` live against `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`:
```

- [ ] **Step 10: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/specify.md`
Expected: `1`

- [ ] **Step 11: `commands/design.md`**

Edit `plugins/dev-workflows/commands/design.md`, replacing:

```
Run **two intertwined tracks**, authoring `design.md` live against
`${CLAUDE_PLUGIN_ROOT}/references/design-format.md`, sections scaled by the Phase 1.5 classification:
```

with:

```
Run **two intertwined tracks**, authoring `design.md` live against
`${CLAUDE_PLUGIN_ROOT}/references/design-format.md`, applying the no-hard-wrap prose convention in
`${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, sections scaled by the Phase 1.5 classification:
```

- [ ] **Step 12: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/design.md`
Expected: `1`

- [ ] **Step 13: Verify all 6 in one pass**

Run:
```bash
for f in idea create-vi update-vi create-ard specify design; do
  echo -n "$f: "; grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands/$f.md
done
```
Expected: `1` on every line.

- [ ] **Step 14: Commit**

```bash
git add plugins/dev-workflows/commands/idea.md plugins/dev-workflows/commands/create-vi.md \
        plugins/dev-workflows/commands/update-vi.md plugins/dev-workflows/commands/create-ard.md \
        plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md
git commit -m "docs(dev-workflows): cite prose-formatting.md in embedded-writing commands"
```

---

## Task 3: Cite `prose-formatting.md` in the 3 dedicated writer agents

**Files:**
- Modify: `plugins/dev-workflows/agents/epic-writer.md:40`
- Modify: `plugins/dev-workflows/agents/doc-writer.md:37-39`
- Modify: `plugins/dev-workflows/agents/release-notes-writer.md:111-112`

**Interfaces:**
- Consumes: `plugins/dev-workflows/references/prose-formatting.md` (Task 1).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: `agents/epic-writer.md`**

Edit `plugins/dev-workflows/agents/epic-writer.md`, replacing:

```
## Write mechanics

For each new Epic, emit a markdown file under the resolved output directory (default the handoff `output_dir`):
```

with:

```
## Write mechanics

Apply the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md` to every prose field (Goal, Business value, narrative bullets) below.

For each new Epic, emit a markdown file under the resolved output directory (default the handoff `output_dir`):
```

- [ ] **Step 2: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/epic-writer.md`
Expected: `1`

- [ ] **Step 3: `agents/doc-writer.md`**

Edit `plugins/dev-workflows/agents/doc-writer.md`, replacing:

```
## Write mechanics

Multi-space safety is governed by `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md`. Before writing, resolve **per-space routing** for each target:
```

with:

```
## Write mechanics

Apply the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md` to every prose block you write. Multi-space safety is governed by `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/multi-space-writing.md`. Before writing, resolve **per-space routing** for each target:
```

- [ ] **Step 4: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/doc-writer.md`
Expected: `1`

- [ ] **Step 5: `agents/release-notes-writer.md`**

Edit `plugins/dev-workflows/agents/release-notes-writer.md`, replacing:

```
     The rendered `prose` field carries this shaped body (prose and/or list/`> Note:`);
     it stays plain customer-facing content with no Jira IDs and no PR links.
```

with:

```
     The rendered `prose` field carries this shaped body (prose and/or list/`> Note:`);
     it stays plain customer-facing content with no Jira IDs and no PR links, and follows the
     no-hard-wrap convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md` — each
     paragraph is one unbroken line.
```

- [ ] **Step 6: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/release-notes-writer.md`
Expected: `1`

- [ ] **Step 7: Verify all 3 in one pass**

Run:
```bash
for f in epic-writer doc-writer release-notes-writer; do
  echo -n "$f: "; grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/plugins/dev-workflows/agents/$f.md
done
```
Expected: `1` on every line.

- [ ] **Step 8: Commit**

```bash
git add plugins/dev-workflows/agents/epic-writer.md plugins/dev-workflows/agents/doc-writer.md \
        plugins/dev-workflows/agents/release-notes-writer.md
git commit -m "docs(dev-workflows): cite prose-formatting.md in dedicated writer agents"
```

---

## Task 4: CLAUDE.md index entry + version bump

**Files:**
- Modify: `CLAUDE.md` (Source-truth reference section)
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json:3`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: nothing new (documents Tasks 1–3).
- Produces: nothing consumed elsewhere — this is the closing bookkeeping task.

- [ ] **Step 1: Add the CLAUDE.md bullet**

Edit `/workspace/ihudak-claude-plugins/CLAUDE.md`, replacing:

```
`plugins/dev-workflows/references/docs-grounding.md` is the **single source of truth** for `$DOCS_PATH` documentation grounding — the resolution gate (`${DOCS_PATH:-/workspace/docs}`, read-only, silent-skip), the `resolve-docs-grounding` procedure, and the grill-rank / writer-attach consumption modes; consumed by the seven authoring commands (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/epics`, `/release-notes`) — not `/document`.
```

with:

```
`plugins/dev-workflows/references/docs-grounding.md` is the **single source of truth** for `$DOCS_PATH` documentation grounding — the resolution gate (`${DOCS_PATH:-/workspace/docs}`, read-only, silent-skip), the `resolve-docs-grounding` procedure, and the grill-rank / writer-attach consumption modes; consumed by the seven authoring commands (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/epics`, `/release-notes`) — not `/document`.

`plugins/dev-workflows/references/prose-formatting.md` is the **single source of truth** for output line-wrapping — never hard-wrap prose; write each paragraph/prose block as one unbroken line, so Obsidian and IntelliJ Idea soft-wrap it for reading and a straight copy-paste into Jira/Grammarly needs no manual cleanup. Consumed by every authoring command/agent that writes prose (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `epic-writer`, `doc-writer`, `release-notes-writer`).
```

- [ ] **Step 2: Verify**

Run: `grep -c "prose-formatting.md" /workspace/ihudak-claude-plugins/CLAUDE.md`
Expected: `1`

- [ ] **Step 3: Bump the plugin version**

Edit `plugins/dev-workflows/.claude-plugin/plugin.json`, replacing:

```
  "version": "2.36.0",
```

with:

```
  "version": "2.37.0",
```

- [ ] **Step 4: Verify**

Run: `grep '"version"' /workspace/ihudak-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json`
Expected: `"version": "2.37.0",`

- [ ] **Step 5: Add the CHANGELOG.md entry**

Edit `plugins/dev-workflows/CHANGELOG.md`, replacing:

```
## [2.36.0] — 2026-07-21
```

with:

```
## [2.37.0] — 2026-07-22

### Changed

- **No-hard-wrap prose convention.** New `references/prose-formatting.md` — the single source of truth: never hard-wrap prose; write each paragraph/prose block as one unbroken line, since Obsidian and IntelliJ Idea both soft-wrap for reading, and a straight copy-paste into Jira/Grammarly needs no manual cleanup. Consumed by every authoring command/agent that writes prose: `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `epic-writer`, `doc-writer`, `release-notes-writer`.

## [2.36.0] — 2026-07-21
```

- [ ] **Step 6: Verify**

Run: `head -12 /workspace/ihudak-claude-plugins/plugins/dev-workflows/CHANGELOG.md | grep -c "2.37.0"`
Expected: `1`

- [ ] **Step 7: Full-repo verification pass (all 10 consumer files)**

`references/prose-formatting.md` itself does not contain the literal string
`prose-formatting.md` anywhere in its body (Task 1's content has no self-reference), so it's
correctly excluded from this list — only the 10 files that *cite* it are checked.

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -l "prose-formatting.md" \
  commands/idea.md commands/create-vi.md commands/update-vi.md commands/create-ard.md \
  commands/specify.md commands/design.md \
  agents/epic-writer.md agents/doc-writer.md agents/release-notes-writer.md \
  ../../CLAUDE.md | wc -l
```
Expected: `10` — every named file matches. If the count is lower, `grep -L` the same file list
(inverted) to identify which file is missing its citation, then re-run the corresponding step
from Task 2 or Task 3.

- [ ] **Step 8: Commit**

```bash
git add CLAUDE.md plugins/dev-workflows/.claude-plugin/plugin.json plugins/dev-workflows/CHANGELOG.md
git commit -m "docs(dev-workflows): index prose-formatting.md, bump to 2.37.0"
```

---

## Follow-up (not scripted — requires a live interactive command run)

Per the design doc's Testing section: after all four tasks land, run `/idea` or `/create-vi` on a
scratch ticket and confirm the Problem/Goal/User Story prose it writes has no mid-paragraph line
breaks. This can't be expressed as a deterministic step in this plan (it depends on interactive
grill dialogue), so it's a manual sanity check for after implementation, not a plan task.

Porting to `mgd-claude-plugins` (verbatim) and `ihudak-copilot-plugins` (Copilot-adapted) is a
separate follow-up per the established cross-repo porting pattern — not part of this plan.

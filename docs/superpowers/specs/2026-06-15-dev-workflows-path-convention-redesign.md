# dev-workflows Path-Convention Redesign (source repo)

**Date:** 2026-06-15
**Status:** Shipped — pre-implementation design snapshot, kept as authored.
**Repo:** `ihudak-claude-plugins` (source). Fixes here are a prerequisite for re-running the `mgd-claude-plugins` clone.

## Problem

Plugin content references bundled files with hardcoded absolute paths of the form
`~/.claude/plugins/data/<plugin>@ihudak-claude-plugins/<dir>/<file>`. These **do not
resolve at runtime**, confirmed empirically against this machine:

- Real plugin content installs at `~/.claude/plugins/cache/<marketplace-name>/<plugin>/<version>/…`
  (e.g. `cache/ihudak-plugins/dev-workflows/1.3.0/agents/risk-planner.md`).
- `~/.claude/plugins/data/<plugin>-<marketplace-name>/` exists but is an **empty** state dir
  (`${CLAUDE_PLUGIN_DATA}`), uses hyphens not `@`, and never holds content.
- **No `@` directory exists anywhere** under `~/.claude/plugins/`.

The current dispatch approach (`Agent(subagent_type:"general-purpose", model:"opus",
prompt:"Read and adopt <path>/agents/X.md, then …")`) was a deliberate workaround for an
older Claude Code that didn't reliably register plugin subagents in the installing session
(see dev-workflows CHANGELOG). That limitation no longer applies.

## Empirical findings (validated this session)

1. **Plugin subagents register and dispatch correctly.** Dispatching `dev-workflows:code-review`
   returned its role, exact verdicts (`PASS / PASS WITH RECOMMENDATIONS / BLOCK`), and Opus model —
   all from the agent `.md` body, with no path reference. Claude Code auto-loads the agent body as
   the system prompt **and** honors its `model:` frontmatter.
2. **`${CLAUDE_PLUGIN_ROOT}` expands in agent and skill content, hooks, monitors, MCP/LSP configs —
   but NOT in slash-command bodies.** This matches the official docs and this plugin's own usage:
   `agents/guideline-reviewer.md` and `agents/api-guideline-reviewer.md` already use
   `${CLAUDE_PLUGIN_ROOT}/references/…` correctly; no command body uses it.
3. No other installed plugin uses absolute `~/.claude/plugins/...` paths in markdown bodies.

## Design

### Decision 1 — Agent invocations → `subagent_type` dispatch
Replace every `Agent(subagent_type:"general-purpose", model:"…", prompt:"Read and adopt
`<path>`/agents/X.md, then `<brief>`")` with:

```
Agent(subagent_type: "dev-workflows:X", prompt: "<brief>")
```

- Drop the broken path and the "Read and adopt" instruction.
- Drop the `model:` override on the `Agent` call — the agent's own `model:` frontmatter is honored
  (Opus for `risk-planner`/`code-review`/`doc-reviewer`/`epic-reviewer`; inherited otherwise).
- The two standalone guideline commands (`guideline-reviewer`, `api-guideline-reviewer`) currently
  tell the **main session** to "Read the full review instructions from the agent file at `<path>`".
  Convert them to dispatch `dev-workflows:guideline-reviewer` / `dev-workflows:api-guideline-reviewer`
  by `subagent_type`. This also repairs those agents' internal `${CLAUDE_PLUGIN_ROOT}` reference
  reads, which only expand when the file runs as a real agent invocation (not read inline).
- Cross-plugin: dev-workflows commands that dispatch the style checker use
  `subagent_type: "dt-style-guide:dt-style-checker"`.

### Decision 2 — Reference reads inside agent/skill bodies → `${CLAUDE_PLUGIN_ROOT}`
Replace `~/.claude/plugins/data/<plugin>@ihudak-claude-plugins/(references|commands)/…` with
`${CLAUDE_PLUGIN_ROOT}/(references|commands)/…` in **agent bodies and skill bodies** (where the
variable expands). This covers handoff docs, upgrade/fix-vuln references, and the self-referential
paths inside `references/handoff/*.md`.

### Decision 3 — Command-level classification → new `model-routing` skill
Commands classify a task **before** dispatching agents, but command bodies can't expand
`${CLAUDE_PLUGIN_ROOT}`, and `classification.md` is the single source of truth (must not be
duplicated into 5 commands). Introduce a new skill:

- `plugins/dev-workflows/skills/model-routing/SKILL.md`
- It injects the authoritative rules via shell at invocation time:
  `` !`cat "${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md"` ``
  (skills support `!`command`` dynamic-context injection and expand `${CLAUDE_PLUGIN_ROOT}`).
- The 5 classifying commands (`vuln`, `upgrade`, `impl:code`, `impl:jira:docs`, `impl:jira:epics`)
  replace their broken "Read classification.md at `<path>`" step with "Invoke the `model-routing`
  skill and classify per the injected rules."
- `references/model-routing/classification.md` remains the single source of truth; agents that need
  the full rules continue to read it via `${CLAUDE_PLUGIN_ROOT}` (Decision 2).

### Decision 4 — Command-level handoff-path passing → removed
Commands currently pass "Handoff format: `<path>`" to agents. With `subagent_type` dispatch the agent
already loads its own handoff reference (via `${CLAUDE_PLUGIN_ROOT}` in its body), so these
command-level path lines are removed rather than rewritten.

### Decision 5 — Documentation
- Rewrite the repo `CLAUDE.md` "Internal path convention" section: it currently codifies the broken
  `~/.claude/plugins/data/<plugin>@…/` path as THE convention. Replace with the correct patterns
  (subagent dispatch by `<plugin>:<agent>`; `${CLAUDE_PLUGIN_ROOT}` in agent/skill/hook bodies;
  command-level rules via the `model-routing` skill). Update the workflow-relationship notes that
  reference the old dispatch mechanism.
- Add a dev-workflows CHANGELOG entry documenting the redesign and superseding the workaround note.

### Decision 5b — README files and the impl diagram
README content describes the dispatch mechanism and install paths and must be brought in line:

- **`plugins/dev-workflows/README.md` (dispatch paragraph, ~line 135):** currently reads "Opus gates …
  declare `model: opus` in their frontmatter **and** the caller passes `model: "opus"` on the `Agent`
  tool call — belt-and-braces … regardless of user-agent discovery." Rewrite to describe the new
  mechanism: agents are dispatched by `subagent_type: "dev-workflows:<name>"`; Claude Code loads each
  agent's body as its system prompt and honors its `model:` frontmatter — no caller-side `model`
  override or path reference needed.
- **`plugins/dev-workflows/README.md` impl flowchart (the `mermaid` diagram):** logically accurate, but
  update the "Phase 1.5: Classify task" node to route classification through the new `model-routing`
  skill, and verify no node/edge implies the deprecated `general-purpose` + override dispatch. (While
  editing, also refresh the stale "Seventeen reusable subagents" count and the agents table, which omit
  `upgrade-planner`, `upgrade-executor`, `vuln-research`, `vuln-fixer` — the marketplace lists 21.)
- **`plugins/dt-style-guide/README.md` (~line 96):** points users at
  `~/.claude/plugins/data/dt-style-guide@…/references/`. Correct to the proper location/guidance
  (`${CLAUDE_PLUGIN_ROOT}/references/` from within the plugin's own components).
- **`plugins/obsidian-llm-wiki/README.md` (~line 92):** states "Plugin installs to
  `~/.claude/plugins/data/obsidian-llm-wiki@…/`" — factually wrong (content installs under
  `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`). Correct the claim.

### Decision 6 — Model-reference refresh
- In `references/model-routing/classification.md` and command examples, update the fallback chain and
  IDs: `claude-opus-4.7` → `claude-opus-4-8`; correct dot→hyphen ID format throughout
  (`claude-sonnet-4.6` → `claude-sonnet-4-6`, etc.); update prose like "Opus 4.7 unavailable" to 4.8.
- Leave agent `model: opus` aliases unchanged (forward-compatible; always resolve to latest Opus).

### Decision 7 — Cosmetic
- `hooks/preload-context.sh:48` echoes a `data/@…` path in a user-facing message. Update to reference
  the `model-routing` skill (or generic text). Non-functional but corrected for consistency.
- `obsidian-llm-wiki` README/CHANGELOG contain doc-text `data/@…` references → correct for consistency
  (cosmetic; obsidian-llm-wiki defines no cross-plugin runtime dependency).

## Scope (per-file)

**dev-workflows commands (agent-dispatch conversions, Decision 1):** `impl/code.md` (8),
`impl/jira/docs.md` (10), `impl/jira/epics.md` (7), `upgrade.md` (4), `vuln.md` (3),
`impl/docs.md` (1), plus `guideline-reviewer.md` (1) and `api-guideline-reviewer.md` (1).

**dev-workflows agents (`${CLAUDE_PLUGIN_ROOT}` conversions, Decision 2):** `upgrade-planner.md`,
`vuln-fixer.md`, `upgrade-executor.md`, `vuln-research.md`, `impl-maintenance.md`, `code-review.md`,
`risk-planner.md`, and the self-referential paths in `references/handoff/*.md` (7 files) +
`references/model-routing/classification.md`.

**New skill (Decision 3):** `skills/model-routing/SKILL.md` + edits to the 5 classifying commands.

**dt-style-guide:** `agents/dt-style-checker.md` (2 → `${CLAUDE_PLUGIN_ROOT}`),
`commands/dt-style-refresh.md` (1), `skills/dt-style-rules/SKILL.md` (1 → `${CLAUDE_PLUGIN_ROOT}`),
`README.md` (1, doc — Decision 5b).

**READMEs / diagram (Decision 5b):** `plugins/dev-workflows/README.md` (dispatch paragraph + impl
flowchart + stale agent count/table), `plugins/dt-style-guide/README.md`,
`plugins/obsidian-llm-wiki/README.md`.

**Docs:** repo `CLAUDE.md`, `plugins/dev-workflows/CHANGELOG.md`, `obsidian-llm-wiki` CHANGELOG.

## Validation plan

- **Already validated:** `subagent_type` dispatch + body autoload + `model:` frontmatter.
- **Must validate during implementation (before relying on it):** the `model-routing` skill's
  `` !`cat "${CLAUDE_PLUGIN_ROOT}/…"` `` injection. Build the skill, reinstall dev-workflows, invoke
  it, and confirm the classification rules appear in context with the path expanded. If skill shell
  injection does **not** expand `${CLAUDE_PLUGIN_ROOT}`, fall back to Decision 3 alt: inline a compact
  4-level classifier in the commands and keep classification.md authoritative for agents only.
- **Static sweep after edits:** zero remaining `~/.claude/plugins/data/<plugin>@` references in any
  operational file, README, or diagram (historical CHANGELOG provenance entries excepted); every
  `subagent_type: "dev-workflows:X"` / `"dt-style-guide:X"` names an agent that exists; every
  `${CLAUDE_PLUGIN_ROOT}/…` target exists in the plugin.
- **Smoke test:** run one representative command end-to-end (e.g. `/impl:code` on a trivial change, or
  `/guideline-reviewer`) and confirm agents dispatch and references load.

## Out of scope
- Re-running the `mgd-claude-plugins` clone — handled by the existing clone plan once this lands;
  the rename map gains no new tokens (the `@ihudak-claude-plugins` token simply disappears, replaced by
  `subagent_type` names and `${CLAUDE_PLUGIN_ROOT}`).
- Any behavioral change to the workflows beyond invocation/reference mechanics.

## Risks
- **Skill injection uncertainty** (mitigated by the validation step + documented fallback).
- **Behavioral shift for the two guideline commands** (review now runs in a dispatched subagent rather
  than the main session). Intended improvement; call out in CHANGELOG.
- **Large surface** (~90 references across 2 plugins). Mitigated by category-batched edits + static
  sweep + smoke test.

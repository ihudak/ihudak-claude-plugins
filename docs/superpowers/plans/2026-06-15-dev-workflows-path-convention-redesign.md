# dev-workflows Path-Convention Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace dev-workflows' (and dt-style-guide's) broken `~/.claude/plugins/data/<plugin>@…/` absolute path references with the correct Claude Code mechanisms — `subagent_type` dispatch for agents, `${CLAUDE_PLUGIN_ROOT}` for in-agent/in-skill reference reads, and a thin `model-routing` skill for command-level classification — plus a model-version refresh and README/diagram/CLAUDE.md/CHANGELOG updates.

**Architecture:** This is a documentation/configuration refactor across markdown + one shell script. There is no code test suite; "tests" are (a) deterministic static-sweep greps with expected counts, (b) one empirical live-install validation of the `model-routing` skill, and (c) one end-to-end smoke test. Work happens on a feature branch in the SOURCE repo. Once merged + validated, the existing `mgd-claude-plugins` clone plan is re-run (out of scope here).

**Tech Stack:** Markdown, YAML frontmatter, bash, git, `grep`/`sed` (macOS BSD — `sed -i ''`), the Claude Code plugin CLI (`claude plugin …`).

**Conventions used below:**
- `SRC` = `/Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins` — all paths are relative to this unless absolute.
- `OLD_PREFIX` (dev-workflows) = `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/`
- `OLD_PREFIX` (dt-style-guide) = `~/.claude/plugins/data/dt-style-guide@ihudak-claude-plugins/`
- `NEW_PREFIX` = `${CLAUDE_PLUGIN_ROOT}/`
- "agent-name" is the basename of an `/agents/<name>.md` reference, e.g. `risk-planner`.

**Spec:** `docs/superpowers/specs/2026-06-15-dev-workflows-path-convention-redesign.md`

---

### Task 1: Create the feature branch

**Files:** none (git only)

- [ ] **Step 1: Confirm clean tree and current branch**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
git status --porcelain
git rev-parse --abbrev-ref HEAD
```
Expected: only the untracked `docs/superpowers/` plan+spec files appear; branch is `main`.

- [ ] **Step 2: Create and switch to the feature branch**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
git checkout -b feat/path-convention-redesign
git rev-parse --abbrev-ref HEAD
```
Expected: `feat/path-convention-redesign`.

---

### Task 2: Create and live-validate the `model-routing` skill

This is done first because every classifying command (Task 5) depends on it. The skill is a thin shim: commands can't expand `${CLAUDE_PLUGIN_ROOT}`, but skills can, so the skill resolves the path to the authoritative rules.

**Files:**
- Create: `plugins/dev-workflows/skills/model-routing/SKILL.md`

- [ ] **Step 1: Write the skill**

Create `plugins/dev-workflows/skills/model-routing/SKILL.md` with exactly:
```markdown
---
name: model-routing
description: Load the dev-workflows task-complexity classification rules and model fallback chain. Invoked by /impl:code, /vuln, /upgrade, /impl:jira:docs, and /impl:jira:epics at their classification step, because slash-command bodies cannot expand ${CLAUDE_PLUGIN_ROOT} themselves.
user-invocable: false
allowed-tools: Read
---

# Model routing

Read the authoritative classification rules and model fallback chain:

`${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md`

Then classify the current task as exactly one of `SIMPLE`, `MODERATE`,
`SIGNIFICANT`, or `HIGH-RISK` using the criteria in that file, and apply the
model fallback chain and `model_routing` handoff block it defines. That file is
the single source of truth — do not paraphrase or cache its contents here.
```

- [ ] **Step 2: Determine how the marketplace is sourced (local vs git)**

Run:
```bash
python3 -m json.tool ~/.claude/plugins/known_marketplaces.json
```
Expected: locate the `ihudak-plugins` entry. Note whether its source is a local path (filesystem) or a git URL — this decides the refresh method in Step 3.

- [ ] **Step 3: Reinstall the plugin so the new skill is registered**

If the marketplace source is the **local SRC path**:
```bash
claude plugin marketplace update ihudak-plugins
claude plugin reinstall dev-workflows@ihudak-plugins
```
If the marketplace source is a **git URL**, the cache only updates from pushed commits. In that case, commit Task 2 to the branch first, push the branch, point the marketplace at the branch (or temporarily at the local path), then reinstall. Record which path was taken.

Verify the skill landed in the cache:
```bash
ls ~/.claude/plugins/cache/ihudak-plugins/dev-workflows/*/skills/model-routing/SKILL.md
```
Expected: the file exists.

- [ ] **Step 4: Validate the skill resolves `${CLAUDE_PLUGIN_ROOT}` and loads the rules**

Invoke the skill (in this session, via the Skill tool: `skill: "dev-workflows:model-routing"`) and confirm it reads the real `classification.md` (i.e. `${CLAUDE_PLUGIN_ROOT}` expanded to the cache path and the four levels SIMPLE/MODERATE/SIGNIFICANT/HIGH-RISK appear).

Expected: the classification rules load. **If `${CLAUDE_PLUGIN_ROOT}` does NOT expand in the skill body** (path appears literal / Read fails), fall back to the spec's documented alternative: inline a compact four-level classifier directly into each of the 5 commands and keep `classification.md` authoritative for agents only. Record the outcome before proceeding.

- [ ] **Step 5: Commit**

```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
git add plugins/dev-workflows/skills/model-routing/SKILL.md
git commit -m "feat(dev-workflows): add model-routing skill for command-level classification"
```

---

### Task 3: Convert agent invocations to `subagent_type` dispatch (commands)

Apply **Transform T1** to every "Read and adopt the system prompt at …" block. The canonical before/after (from `commands/impl/code.md:109`):

**BEFORE:**
```
→ Agent (subagent_type: "general-purpose", model: "opus"):
  > "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/risk-planner.md`
  > (fall back to `~/.claude/agents/risk-planner.md` if installed at user level). Then produce the risk-weighted plan described in that prompt for
  > the following brief:
  >
  > Task description: [substitute full description]
  > ..."
```
**AFTER:**
```
→ Agent (subagent_type: "dev-workflows:risk-planner"):
  > "Produce the risk-weighted plan for the following brief:
  >
  > Task description: [substitute full description]
  > ..."
```
Rules for T1: (a) `subagent_type` becomes `dev-workflows:<agent-name>` (or `dt-style-guide:<agent-name>` for the style checker); (b) delete the `model:` argument — the agent's own frontmatter sets it; (c) delete the "Read and adopt the system prompt at `<path>` (fall back to …). Then" preamble, keeping the actual brief; (d) leave every other instruction/brief line intact.

**Files (occurrence counts of "Read and adopt"):** `commands/impl/code.md` (8), `commands/impl/jira/docs.md` (10, includes the `dt-style-guide:dt-style-checker` dispatch), `commands/impl/jira/epics.md` (7, includes `dt-style-guide:dt-style-checker`), `commands/upgrade.md` (4), `commands/vuln.md` (3), `commands/impl/docs.md` (1).

- [ ] **Step 1: Convert `commands/impl/code.md`**

Apply T1 to all 8 blocks. Agent names to expect (from the existing paths): `risk-planner`, `test-baseliner`, `test-writer`, `code-review`, `review-fixer`, `impl-maintenance`.

- [ ] **Step 2: Verify no broken agent paths or general-purpose Opus blocks remain in code.md**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -n 'Read and adopt\|plugins/data/.*@.*agents\|general-purpose", model' plugins/dev-workflows/commands/impl/code.md ; echo "exit:$?"
grep -n 'subagent_type: "dev-workflows:' plugins/dev-workflows/commands/impl/code.md | wc -l
```
Expected: first prints nothing (`exit:1`); second is non-zero.

- [ ] **Step 3: Convert the remaining five command files**

Apply T1 to `commands/impl/jira/docs.md`, `commands/impl/jira/epics.md`, `commands/upgrade.md`, `commands/vuln.md`, `commands/impl/docs.md`. In `jira/docs.md` and `jira/epics.md`, the style-checker block uses `subagent_type: "dt-style-guide:dt-style-checker"`.

- [ ] **Step 4: Verify across all six command files**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rn 'Read and adopt' plugins/dev-workflows/commands/ ; echo "exit:$?"
```
Expected: nothing, `exit:1`.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/
git commit -m "refactor(dev-workflows): dispatch agents by subagent_type, not file path"
```

---

### Task 4: Convert the two guideline commands to dispatch

**Files:** `commands/guideline-reviewer.md`, `commands/api-guideline-reviewer.md`

- [ ] **Step 1: Rewrite the agent-pointer in both commands**

Both currently contain (api example, lines 9-10):
```
Read the full review instructions from the agent file:
`~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/api-guideline-reviewer.md`

Follow those instructions exactly. ...
```
Replace the "Read the full review instructions from the agent file: `<path>` / Follow those instructions exactly." portion with a dispatch instruction:
```
Dispatch the review to the `api-guideline-reviewer` subagent:

→ Agent (subagent_type: "dev-workflows:api-guideline-reviewer"):
  > "Review the following OpenAPI spec file(s) against the guidelines: $ARGUMENTS"

Surface the subagent's verdict to the user.
```
Do the same for `guideline-reviewer.md` with `subagent_type: "dev-workflows:guideline-reviewer"` and its own brief (review app code/UI for Dynatrace Experience Standards, target = `$ARGUMENTS`). Keep each command's existing "if `$ARGUMENTS` is empty, ask the user" line.

- [ ] **Step 2: Verify**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -n 'plugins/data/.*@\|Read the full review instructions' plugins/dev-workflows/commands/guideline-reviewer.md plugins/dev-workflows/commands/api-guideline-reviewer.md ; echo "exit:$?"
grep -c 'subagent_type: "dev-workflows:' plugins/dev-workflows/commands/guideline-reviewer.md plugins/dev-workflows/commands/api-guideline-reviewer.md
```
Expected: first nothing (`exit:1`); second shows 1 each.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/commands/guideline-reviewer.md plugins/dev-workflows/commands/api-guideline-reviewer.md
git commit -m "refactor(dev-workflows): guideline commands dispatch their reviewer subagent"
```

---

### Task 5: Wire the classifying commands to the model-routing skill

Decision 3 + Decision 4. Affects the 5 commands that read `classification.md`: `vuln.md`, `upgrade.md`, `impl/code.md`, `impl/jira/docs.md`, `impl/jira/epics.md`.

- [ ] **Step 1: Replace the classify-step path read in each command**

Each has a line like (code.md:45):
```
Read `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md`. Classify the task as exactly one of:
```
Replace the "Read `<path>`" instruction with:
```
Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of:
```
Leave the four-level list and the rest of the classification prose unchanged.

- [ ] **Step 2: Remove command-level handoff-path passing (Decision 4)**

In `vuln.md` and `upgrade.md`, delete the lines that pass reference/handoff file paths to agents (e.g. "Research handoff: `<path>`", "Handoff format: `<path>`", "Model routing: `<path>`", the `references/handoff/*` and `references/fix-vuln/*` / `references/upgrade/*` bullet lists at the top). The dispatched agents load these themselves via `${CLAUDE_PLUGIN_ROOT}` (Task 6). Keep any non-path prose.

- [ ] **Step 3: Verify no reference/data paths remain in the 5 commands**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rn 'plugins/data/.*@\|model-routing/classification.md`' plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/commands/impl/code.md plugins/dev-workflows/commands/impl/jira/docs.md plugins/dev-workflows/commands/impl/jira/epics.md ; echo "exit:$?"
grep -rc 'dev-workflows:model-routing' plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/commands/impl/code.md plugins/dev-workflows/commands/impl/jira/docs.md plugins/dev-workflows/commands/impl/jira/epics.md
```
Expected: first nothing (`exit:1`); second shows 1 in each.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/commands/
git commit -m "refactor(dev-workflows): classify via model-routing skill; drop command-level handoff paths"
```

---

### Task 6: Convert reference reads in agent bodies to `${CLAUDE_PLUGIN_ROOT}`

**Transform T2** (pure, deterministic string replace within agent + handoff-reference bodies):
`~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/` → `${CLAUDE_PLUGIN_ROOT}/`

**Files:** `agents/upgrade-planner.md`, `agents/vuln-fixer.md`, `agents/upgrade-executor.md`, `agents/vuln-research.md`, `agents/impl-maintenance.md`, `agents/code-review.md`, `agents/risk-planner.md`, and the self-referential paths inside `references/handoff/*.md` (7 files) and `references/model-routing/classification.md`.

- [ ] **Step 1: Apply T2 to dev-workflows agent + reference files**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rIl '~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/' plugins/dev-workflows/agents plugins/dev-workflows/references \
  | xargs sed -i '' 's|~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/|${CLAUDE_PLUGIN_ROOT}/|g'
```

- [ ] **Step 2: Verify no dev-workflows data paths remain in agents/references; ${CLAUDE_PLUGIN_ROOT} targets exist**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rn 'plugins/data/.*@' plugins/dev-workflows/agents plugins/dev-workflows/references ; echo "exit:$?"
# spot-check a few referenced targets exist:
ls plugins/dev-workflows/references/model-routing/classification.md plugins/dev-workflows/references/handoff/test-baseliner.md plugins/dev-workflows/references/upgrade/ecosystems.md
```
Expected: first nothing (`exit:1`); the `ls` lists all three files.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/agents plugins/dev-workflows/references
git commit -m "refactor(dev-workflows): read bundled references via \${CLAUDE_PLUGIN_ROOT} in agents"
```

---

### Task 7: Fix dt-style-guide references

**Files:** `plugins/dt-style-guide/agents/dt-style-checker.md`, `plugins/dt-style-guide/skills/dt-style-rules/SKILL.md`, `plugins/dt-style-guide/commands/dt-style-refresh.md`

- [ ] **Step 1: Apply T2 to the dt-style-guide agent and skill bodies**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rIl '~/.claude/plugins/data/dt-style-guide@ihudak-claude-plugins/' plugins/dt-style-guide/agents plugins/dt-style-guide/skills \
  | xargs sed -i '' 's|~/.claude/plugins/data/dt-style-guide@ihudak-claude-plugins/|${CLAUDE_PLUGIN_ROOT}/|g'
```

- [ ] **Step 2: Fix the command reference**

`commands/dt-style-refresh.md` contains one `data/@` path. Commands can't expand `${CLAUDE_PLUGIN_ROOT}`; this command refreshes vendored rules. Open the file and rewrite the path reference so the command instructs reading/writing the vendored `references/` via its own agent (`dt-style-guide:dt-style-checker` or `dt-doc-fixer`) — i.e. move any file-path dependency into the dispatched agent (which can expand the variable), mirroring Task 4. If the path is only descriptive prose, replace it with a plain description of the `references/` directory without the broken absolute path.

- [ ] **Step 3: Verify**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rn 'plugins/data/.*@' plugins/dt-style-guide/agents plugins/dt-style-guide/skills plugins/dt-style-guide/commands ; echo "exit:$?"
```
Expected: nothing, `exit:1`.

- [ ] **Step 4: Commit**

```bash
git add plugins/dt-style-guide/agents plugins/dt-style-guide/skills plugins/dt-style-guide/commands
git commit -m "refactor(dt-style-guide): use \${CLAUDE_PLUGIN_ROOT} / dispatch instead of data paths"
```

---

### Task 8: Refresh stale model references (Decision 6)

**Files:** `plugins/dev-workflows/references/model-routing/classification.md`, `plugins/dev-workflows/commands/upgrade.md`, `plugins/dev-workflows/commands/vuln.md`

- [ ] **Step 1: Update model IDs and fallback chain**

Apply these replacements (note: real IDs use hyphens, not dots):
- `claude-opus-4.7` → `claude-opus-4-8`
- `claude-opus-4.6` → `claude-opus-4-7`
- `claude-opus-4.5` → `claude-opus-4-6`
- `claude-sonnet-4.6` → `claude-sonnet-4-6`
- `claude-sonnet-4.5` → `claude-sonnet-4-5`
- prose "Opus 4.7" → "Opus 4.8" (e.g. the `notes:` example "Opus 4.7 unavailable, fell back to 4.6" → "Opus 4.8 unavailable, fell back to 4.7")

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
for f in plugins/dev-workflows/references/model-routing/classification.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/commands/vuln.md; do
  sed -i '' \
    -e 's|claude-opus-4\.5|claude-opus-4-6|g' \
    -e 's|claude-opus-4\.6|claude-opus-4-7|g' \
    -e 's|claude-opus-4\.7|claude-opus-4-8|g' \
    -e 's|claude-sonnet-4\.5|claude-sonnet-4-5|g' \
    -e 's|claude-sonnet-4\.6|claude-sonnet-4-6|g' \
    -e 's|Opus 4\.7|Opus 4.8|g' "$f"
done
```
NOTE: run the opus replacements in ascending order (4.5→4.6 before 4.6→4.7 before 4.7→4.8) as written above so each shifts up exactly one version — the `-e` order in the command does this correctly because sed applies them left-to-right per line; verify Step 2 confirms no `4.5/4.6/4.7` dotted opus IDs survive.

- [ ] **Step 2: Verify no stale dotted IDs or 4.7-as-top remain**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rn 'claude-opus-4\.\|claude-sonnet-4\.\|Opus 4\.7' plugins/dev-workflows/references/model-routing/classification.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/commands/vuln.md ; echo "exit:$?"
grep -rn 'claude-opus-4-8' plugins/dev-workflows/references/model-routing/classification.md | head
```
Expected: first nothing (`exit:1`); second shows the new top-of-chain ID present.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/model-routing/classification.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/commands/vuln.md
git commit -m "docs(dev-workflows): refresh model fallback chain to Opus 4.8 and hyphenated IDs"
```

---

### Task 9: Update README files and the impl diagram (Decision 5b)

**Files:** `plugins/dev-workflows/README.md`, `plugins/dt-style-guide/README.md`, `plugins/obsidian-llm-wiki/README.md`

- [ ] **Step 1: Rewrite the dev-workflows dispatch paragraph (~line 135)**

Replace:
```
Opus gates (`risk-planner`, `code-review`, `doc-reviewer`, `epic-reviewer`) declare `model: opus` in their frontmatter **and** the caller passes `model: "opus"` on the `Agent` tool call — belt-and-braces so the override is in force regardless of user-agent discovery.
```
with:
```
Agents are dispatched by `subagent_type` (e.g. `dev-workflows:risk-planner`). Claude Code loads each agent's file body as its system prompt and honours its `model:` frontmatter — so the four Opus gates (`risk-planner`, `code-review`, `doc-reviewer`, `epic-reviewer`) run on Opus automatically, with no caller-side `model` override or file-path reference.
```

- [ ] **Step 2: Update the impl flowchart classify node + refresh the agent count/table**

In the `mermaid` flowchart, change the classify node `C` text from:
```
C["Phase 1.5: Classify task<br/>SIMPLE / MODERATE / SIGNIFICANT / HIGH-RISK"]
```
to:
```
C["Phase 1.5: Classify task via model-routing skill<br/>SIMPLE / MODERATE / SIGNIFICANT / HIGH-RISK"]
```
Then update the line "Seventeen reusable subagents (invoked internally by the commands)." to "Twenty-one reusable subagents (invoked internally by the commands)." and add the four missing rows to the agents table (all `inherits` model): `upgrade-planner` (Phase-1 compatibility planner), `upgrade-executor` (Phase-2 apply+build+test+fix), `vuln-research` (read-only NVD + library detection), `vuln-fixer` (apply minimal version bump, rebuild, verify, PR). Match the existing table's column format (`| Agent | Model | Description |`).

- [ ] **Step 3: Fix dt-style-guide and obsidian README path claims**

In `plugins/dt-style-guide/README.md` (~line 96) replace the line pointing at
`~/.claude/plugins/data/dt-style-guide@…/references/` with a correct statement, e.g.:
```
> Vendored rules live under the plugin's own `references/` directory (resolved at runtime via `${CLAUDE_PLUGIN_ROOT}/references/`).
```
In `plugins/obsidian-llm-wiki/README.md` (~line 92) replace:
```
Plugin installs to `~/.claude/plugins/data/obsidian-llm-wiki@ihudak-claude-plugins/`.
```
with:
```
Plugin content installs under `~/.claude/plugins/cache/<marketplace>/obsidian-llm-wiki/<version>/`; persistent plugin state (if any) lives under `~/.claude/plugins/data/obsidian-llm-wiki-<marketplace>/`.
```
(Leave the `obsidian-llm-wiki@ihudak-copilot-plugins` Copilot line at ~line 106 unchanged — external marketplace.)

- [ ] **Step 4: Verify**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rn 'user-agent discovery\|caller passes `model' plugins/dev-workflows/README.md ; echo "exit:$?"
grep -rn 'plugins/data/.*@ihudak-claude-plugins' plugins/dt-style-guide/README.md plugins/obsidian-llm-wiki/README.md ; echo "exit:$?"
grep -n 'Twenty-one reusable\|model-routing skill' plugins/dev-workflows/README.md
```
Expected: first two greps print nothing (`exit:1` each); third shows both new strings.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/README.md plugins/dt-style-guide/README.md plugins/obsidian-llm-wiki/README.md
git commit -m "docs: align READMEs + impl diagram with subagent dispatch and correct install paths"
```

---

### Task 10: Update repo CLAUDE.md, CHANGELOG, and the cosmetic hook

**Files:** `CLAUDE.md`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/obsidian-llm-wiki/CHANGELOG.md`, `plugins/dev-workflows/hooks/preload-context.sh`

- [ ] **Step 1: Rewrite the CLAUDE.md "Internal path convention" section**

The current section reads (around line 36-40):
```
**Internal path convention:** all paths inside command/agent/hook files use
`~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/` as the root prefix.
This is where Claude Code installs the plugin's content.
```
Replace with:
```
**Internal reference convention:**
- Agents are invoked by `subagent_type` (`<plugin>:<agent>`, e.g. `dev-workflows:risk-planner`) — never by reading the agent file. Claude Code loads the agent body as its system prompt and honours its `model:` frontmatter.
- Inside **agent** and **skill** bodies (and `hooks.json` / MCP / monitor configs), reference bundled files via `${CLAUDE_PLUGIN_ROOT}/...`. This variable does NOT expand in slash-command bodies.
- Slash **commands** that need bundled reference content (e.g. model-routing classification) invoke a skill that resolves `${CLAUDE_PLUGIN_ROOT}` on their behalf (see the `model-routing` skill).
Do NOT hardcode `~/.claude/plugins/data/...@.../` paths — that directory holds only empty per-plugin state; installed content lives under `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`.
```
Also update the line near line 57 ("All paths in plugin content use `~/.claude/plugins/data/<plugin>@ihudak-claude-plugins/`…") to point at the convention above, and review the "workflow relationships" notes for any mention of the old `general-purpose` + override dispatch, updating to `subagent_type` dispatch.

- [ ] **Step 2: Fix the cosmetic hook echo**

`plugins/dev-workflows/hooks/preload-context.sh:48` echoes:
```
echo "  Full rules: ~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md"
```
Replace with:
```
echo "  Full rules: invoke the model-routing skill (loads references/model-routing/classification.md)"
```

- [ ] **Step 3: Add a CHANGELOG entry**

Prepend a new entry to `plugins/dev-workflows/CHANGELOG.md` (above the latest version section) describing the redesign: agents now dispatched by `subagent_type`; bundled references read via `${CLAUDE_PLUGIN_ROOT}`; new `model-routing` skill for command-level classification; model fallback chain refreshed to Opus 4.8; supersedes the prior "general-purpose + Read-and-adopt" workaround (reference the old CHANGELOG note). Also fix the one cosmetic `data/@` reference in `plugins/obsidian-llm-wiki/CHANGELOG.md` (replace the `data/...@...` path text with the corrected `cache/<marketplace>/...` form, or drop the path if purely historical).

- [ ] **Step 4: Verify and commit**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rn 'plugins/data/dev-workflows@ihudak-claude-plugins\|plugins/data/.*@.*references' CLAUDE.md plugins/dev-workflows/hooks/preload-context.sh ; echo "exit:$?"
```
Expected: nothing, `exit:1`.
```bash
git add CLAUDE.md plugins/dev-workflows/CHANGELOG.md plugins/obsidian-llm-wiki/CHANGELOG.md plugins/dev-workflows/hooks/preload-context.sh
git commit -m "docs: document correct path conventions; fix cosmetic hook path; changelog"
```

---

### Task 11: Full static sweep + smoke test

**Files:** none (verification only)

- [ ] **Step 1: Global static sweep — no broken data paths anywhere operational**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
grep -rIn --exclude-dir=.git '~/.claude/plugins/data/[a-z-]*@ihudak-claude-plugins' plugins/ CLAUDE.md ; echo "exit:$?"
```
Expected: nothing, `exit:1`. (If any historical-only CHANGELOG provenance line remains intentionally, it must be explicitly justified; otherwise treat a hit as a failure.)

- [ ] **Step 2: Every dispatched subagent name exists**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
for n in $(grep -rhoE 'subagent_type: "(dev-workflows|dt-style-guide):[a-z-]+"' plugins/ | sed -E 's/.*:([a-z-]+)"/\1/' | sort -u); do
  test -f "plugins/dev-workflows/agents/$n.md" -o -f "plugins/dt-style-guide/agents/$n.md" && echo "OK  $n" || echo "MISSING $n"
done
```
Expected: `OK` for every name; no `MISSING`.

- [ ] **Step 3: Every `${CLAUDE_PLUGIN_ROOT}/...` reference target exists**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
for plug in dev-workflows dt-style-guide; do
  grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9/_.-]+' plugins/$plug \
    | sed -E 's/\$\{CLAUDE_PLUGIN_ROOT\}/plugins\/'"$plug"'/' | sort -u \
    | while read -r p; do test -e "$p" && echo "OK  $p" || echo "MISSING $p"; done
done
```
Expected: `OK` for every target; no `MISSING`.

- [ ] **Step 4: Reinstall and smoke-test one workflow end-to-end**

Reinstall the plugin (as in Task 2 Step 3) so all edits are live. Then run one representative command — e.g. `/guideline-reviewer` on a tiny sample file, or `/impl:code` on a trivial change in a throwaway repo — and confirm: the `model-routing` skill loads the classification rules, the correct subagent dispatches (visible as `dev-workflows:<name>`), and the agent loads its references without "file not found". Record the result.

- [ ] **Step 5: Final review and report**

Run:
```bash
cd /Users/ivan.gudak/dev/ai-tools/ihudak-claude-plugins
git log --oneline main..feat/path-convention-redesign
git status
```
Expected: the per-task commits listed; clean working tree. Report the smoke-test outcome. Do NOT merge or push unless the user asks. Once the user confirms this branch is good, the `mgd-claude-plugins` clone plan is re-run against the updated source.

---

## Self-Review

**Spec coverage:**
- Decision 1 (subagent dispatch) → Tasks 3 + 4 ✔
- Decision 2 (`${CLAUDE_PLUGIN_ROOT}` in agent/skill bodies) → Tasks 6 + 7 ✔
- Decision 3 (model-routing skill) → Tasks 2 + 5 ✔ (skill simplified to read-via-`${CLAUDE_PLUGIN_ROOT}`; shell-injection fallback + inline-classifier fallback both noted)
- Decision 4 (drop command-level handoff paths) → Task 5 Step 2 ✔
- Decision 5 (CLAUDE.md + CHANGELOG) → Task 10 ✔
- Decision 5b (READMEs + diagram) → Task 9 ✔
- Decision 6 (model refresh) → Task 8 ✔
- Decision 7 (cosmetic hook + obsidian docs) → Task 10 ✔
- Validation plan (skill live-test, static sweep, subagent-name + reference-target existence, smoke test) → Tasks 2 + 11 ✔
- Branch-before-edits invariant → Task 1 ✔

**Placeholder scan:** Bracketed tokens like `[substitute full description]` are intentional command-template literals copied verbatim from the source files (they are the existing content, not plan placeholders). No TBD/TODO/"handle appropriately". Transforms T1/T2 are shown with concrete before/after.

**Consistency:** Token forms (`subagent_type: "dev-workflows:<name>"`, `${CLAUDE_PLUGIN_ROOT}/`, `claude-opus-4-8`) are identical across tasks and verification greps. Subagent names used in dispatch all correspond to files verified in Task 11 Step 2.

**Note on the model-ID shift (Task 8):** the fallback chain is shifted up one version (old top 4.7 → new top 4.8, old entries cascade). If you intended only to *rename* 4.7→4.8 without cascading 4.6/4.5, adjust Task 8 Step 1 — but cascading keeps a 3-deep Opus chain, matching the original structure.

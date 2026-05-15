Implement the following doc edit: $ARGUMENTS

If the argument starts with `@`, treat it as a path to a markdown file. Resolve relative to the current working directory. Read its full content and use it as the description. Echo `📄 Reading prompt from \`<file>\`…` before proceeding. If the file cannot be read, stop and report the error immediately.

`/impl:docs` is the **one-shot doc-editing** workflow — minor edits, formatting, small updates to existing pages, and single-file additions where the content comes from the user's description alone. It is the right tool when:
- the change is small and the content is already in the user's head or the file, **not** scattered across Jira items and PR diffs
- no tests, no branch, no code review, and no commit are warranted

For net-new documentation assembled from a Jira hierarchy plus PR diffs, use `/impl:jira:docs`. For writing child Epic drafts from a Value Increment, use `/impl:jira:epics`.

No model-routing reminder is injected for this command — classification still happens but is always SIMPLE or MODERATE, and Opus is never invoked.

---

## Phase 0 — Load the description

If `@file` syntax: read the file, confirm `"Loaded prompt from <filename.md> (N lines)."`, note any embedded images as "referenced image: <path>". Otherwise use the inline text verbatim.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess. This rule is absolute.**

Before producing a plan, analyze the description for:
- Ambiguous scope or unclear boundaries (which file? which section? extend or replace?)
- Conflicting style guidance in the repo vs. the user's wording
- Multiple valid placements for new content
- Undefined target audience (end-user vs developer vs operator)
- Missing acceptance criteria (what makes this "done"?)

If **any** ambiguity exists, ask the user. Rules:
- Use `choices` arrays for every question — never plain text questions
- The **last choice** in every `choices` array MUST be `"Other… (describe)"` to allow free-text
- When a clearly superior default exists, make it the first choice and label it `"(Recommended)"`
- Group related decisions into a single question (minimize total questions)
- Do **not** proceed until all questions are answered

If **nothing** is ambiguous, skip directly to Phase 1.5.

---

## Phase 1.5 — Classify task complexity

Doc edits in this command are always either **SIMPLE** or **MODERATE**:

- **SIMPLE** — single file, small additions / fixes / rewording, no cross-file linking
- **MODERATE** — multi-file edit, non-trivial restructure, or content that needs internal cross-references

If your reading of the task lands closer to SIGNIFICANT or HIGH-RISK (multi-repo, net-new feature pages from a Jira hierarchy, published-documentation blast radius that needs a reviewer gate), **stop and redirect the user** to `/impl:jira:docs` or `/impl:jira:epics`:
```
choices: ["Re-run under /impl:jira:docs (for Jira-sourced feature documentation) (Recommended)", "Re-run under /impl:jira:epics (for Epic drafting)", "Proceed under /impl:docs anyway — I accept the simplified flow", "Cancel"]
```

State the classification and a one-line reason, then proceed to Phase 2A.

*(There is no Phase 2B, Phase 3B, Phase 3.5, or Opus review in this command. Phase numbering is kept aligned with `/impl:code` to make cross-referencing straightforward; the A-suffix on Phase 2A below is retained for symmetry, not because a Phase 2B exists for docs.)*

---

## Phase 2A — Plan

**Repo exploration** — Before writing the plan, spawn an exploration subagent to map the relevant docs and any sibling conventions:

→ Agent (subagent_type: "general-purpose", tools: Read/Glob/Grep/LS only — no Bash, no Edit):
  "Given this doc-edit description: [paste the full description from Phase 0 or Phase 1 here], find and return:
   - Target file(s) and their current structure (headings, frontmatter, approximate size)
   - Sibling / adjacent pages that may need matching updates (cross-references, navigation files, index pages)
   - Style / naming / frontmatter conventions visible in 2–3 neighbouring files (e.g. YAML frontmatter fields, heading depth, `[[wikilink]]` vs `[text](url)` preference)
   - Existing reference docs that govern this content (e.g. `CONTRIBUTION.md`, `DOCUMENTATION-GUIDELINES.md`, `STYLE.md`)
   Return a structured summary — no edits."

**Wait for the agent's response before proceeding.** If the agent returns no relevant files or fails, gather the context yourself via Read/Glob/Grep before drafting the plan.

Produce a written plan with these sections:

1. **Classification** — `SIMPLE` or `MODERATE` (with reason)
2. **Goal** — one-sentence summary of the desired end state
3. **Approach** — chosen edit strategy and why (extend existing page vs. create new vs. restructure)
4. **Steps** — numbered, concrete edits
5. **Files to create/modify** — list with brief rationale for each
6. **Validation** — spot-check steps to run after the edit. Replace the `/impl:code` "Tests" section with this. Typical checks:
   - Heading structure renders correctly (no orphan H3 under H1, no skipped levels)
   - All `[[wikilinks]]` resolve to existing files in the vault / docs tree
   - All `[text](relative-path)` links resolve on disk
   - YAML frontmatter parses (if the page has frontmatter)
   - `changelog:` or equivalent field updated if the repo's convention requires one
   - No broken inline image references
   - Spell-check / grammar only if the repo has a configured linter (e.g. Vale, markdownlint); do not run any linter that isn't already configured
7. **Assumptions** — decisions made without user input (must be minimal)
8. **Out of scope** — explicitly list what is NOT being done (e.g., "not renaming the file", "not updating sibling pages")

Then ask:
```
"Doc-edit plan ready. What would you like to do?"
choices: ["Approve & implement now (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → proceed to Phase 3
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarize what was planned

---

## Phase 3 — Implementation

**Implement immediately. Do NOT ask "Should I implement?" or any variation.**

1. Work through each edit in order
2. Make precise, surgical changes — do not rewrite sections wholesale when a targeted edit is enough
3. Follow the repo's detected style conventions from the Phase 2A exploration; LF line endings
4. If a **new ambiguity** emerges mid-edit: STOP, ask with choices (last: `"Other… (describe)"`), resume after answer
5. After all edits: run the Validation checks from the plan's step 6. Fix any failures caused by your changes (broken links, unparseable frontmatter, bad heading hierarchy).
6. **Do NOT run tests.** This command has no test phase — validation checks are all that's expected.
7. **Do NOT create a branch or commit.** The user manages git manually for doc edits.
8. Verify the outcome matches the approved plan.
9. Proceed to Phase 4.

---

## Phase 4 — Post-implementation maintenance

First gather the actual change context:

a. Run `git diff --stat` (or equivalent) and capture the list of changed files with line counts. Note: the user has not committed, so `git diff --stat` will reflect unstaged changes.
b. Compose a **change summary block**:

```
Implementation: [one-sentence description of what was edited]
Change type: docs
Classification: [SIMPLE | MODERATE]
Files changed (from git diff --stat):
<paste the git diff --stat output>
Notable additions/removals: [new pages, new sections, new cross-links, restructured navigation — one line each; or "none"]
Validation result: [PASS | PARTIAL — with note on what's still broken]
```

Then spawn all four Phase 4 agents. They are independent and can run in any order — spawn them all before waiting for any to complete:

**Agent 1 — Documentation** (general-purpose):
> "Post-doc-edit documentation review. Change summary:
> [paste change summary block]
>
> Scan for README.md, CHANGELOG.md, docs/, or any .md files in the project root or a docs/ directory that are adjacent to the edited files.
> Determine if *other* documentation needs updating as a consequence of this edit (e.g., an index page, a cross-referenced overview, a changelog entry in the repo root).
> - Skip if: purely a typo fix, reformat, or edit confined to a single page with no cross-references
> - Update if: new page, restructured content, renamed headings that break inbound links, new cross-references that need a mate added elsewhere
> If an update is warranted: apply minimal edits to the relevant section(s).
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose):
> "Post-doc-edit knowledge review. Change summary:
> [paste change summary block]
>
> Check ~/.claude/memory/ (global) and .claude/memory/ (project-level, preferred for repo-specific knowledge) for existing knowledge files.
> Determine if a new knowledge entry is warranted — look for: reusable insights about this repo's doc conventions, non-obvious style rules uncovered, tooling gotchas (Vale rule interactions, snippet conventions).
> If YES: append to the most appropriate existing file (never create a new file if an existing one fits) using this format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the doc-edit description]
> Return: file updated/created and summary of entry, OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-doc-edit instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any doc-editing rules, guidance, or guardrails are missing because of what this edit revealed (e.g., a repo-specific frontmatter field that must always be present, a cross-link pattern that's easy to miss, a style rule that caught you out).
> Skip if: the edit followed existing conventions with no surprises. Only update if a concrete, recurring rule would have prevented a decision point or misunderstanding during this edit.
> If YES: apply minimal, additive, scoped changes only — do not rewrite sections wholesale.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (general-purpose):
> "Read and adopt the system prompt at `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/agents/impl-maintenance.md`
> (fall back to `~/.claude/agents/impl-maintenance.md` if installed at user level).
> Then analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /impl:docs
> - What was done: [one-paragraph summary of the doc edit]
> - Key events: [ambiguities that required user clarification, style-rule surprises, broken links encountered and fixed, convention mismatches — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: N/A (no review gate in /impl:docs)
> - Test result: N/A (no tests in /impl:docs)
> - Project root: [absolute path]"

Collect all four summaries for the Phase 5 report.

---

## Phase 5 — Final Report

Output a structured report — do NOT ask any closing confirmation:

```
## Doc-edit Report

### Classification
[SIMPLE | MODERATE] — [reason]

### What was edited
[High-level summary]

### Files changed
- path/to/file.ext — [what changed]

### Validation
- [check name] → [result]
- ...

### Documentation (Agent 1)
- [file updated] — [what was added/changed] OR "no update required (reason)"

### Knowledge base (Agent 2)
- [file updated/created] — [summary of entry] OR "no update required"

### Instructions (Agent 3)
- [summary of change] OR "no update required"

### Session learnings (Agent 4)
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Assumptions & limitations
- [list any]

### Deferred items
- [anything the user asked to defer, OR validation failures the user accepted, OR "none"]

### Git state
The working tree has uncommitted changes. `/impl:docs` never commits — you manage git manually. Run `git status` to review, then commit when ready.
```

---

## Invariants (always enforced)

- NEVER create a git branch (the user manages git manually)
- NEVER run tests (this command has no test phase)
- NEVER invoke Opus (no planning agent, no review agent — docs edits are always SIMPLE or MODERATE)
- NEVER commit (the user manages git manually)
- NEVER make assumptions that could have been asked — ask instead
- NEVER end implementation with "Should I implement?" — if approved, implement
- NEVER rewrite sections wholesale when only a targeted edit is needed
- NEVER skip Phase 4 — documentation, knowledge, instructions, and session-maintenance are mandatory after every successful doc edit; always collect all four agent summaries for Phase 5
- ALWAYS run the Phase 2A exploration subagent before drafting the plan
- ALWAYS pass `Change type: docs` in the Phase 4 change summary block
- ALWAYS pass `Command run: /impl:docs` in the Phase 4 Agent 4 session handoff
- ALWAYS spawn Phase 4 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 5 report as the final output
- ALWAYS run the Validation checks from the plan — validation failures are surfaced in the Phase 5 report, not silently accepted
- IF the task reads as SIGNIFICANT / HIGH-RISK on inspection: redirect to `/impl:jira:docs` or `/impl:jira:epics` rather than proceeding under the simplified flow

# Discrepancy Escalation + Style-Check Robustness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the docs flow an *analyst not an arbiter* — verify user-visible doc claims against source, escalate Jira-vs-source discrepancies to the user (document-as-source / document-as-jira+bug-report / skip), and make style checks robust (Vale-missing → dt-style-checker fallback, mandatory).

**Architecture:** Port Copilot dev-workflows' v1.7.0→v1.8.1 end-state into the Claude marketplace. A new `references/source-truth.md` policy is consulted by `doc-planner`, `doc-reviewer`, and `release-notes-writer`; `/impl:jira:docs` gains a discrepancy-decision phase (5.8) and threads `code_repos`; `docs-style-checker` gains a `dt-style-checker` fallback; `risk-planner` gains guardrails. All content is markdown/agent prose — verification is `grep` + JSON validity, mirroring prior plans.

**Tech Stack:** Markdown plugin content, JSON manifests. No unit-test framework. The Copilot sources at `/workspace/ihudak-copilot-plugins/dev-workflows/` are the validated reference for verbatim-heavy pieces.

**Spec:** `docs/superpowers/specs/2026-06-16-source-truth-style-robustness-design.md`

---

## File Structure

| File | Change |
|---|---|
| `plugins/dev-workflows/references/source-truth.md` (new) | analyst-not-arbiter policy + escalation protocol |
| `plugins/dev-workflows/agents/docs-style-checker.md` | ERROR/NOT_CONFIGURED → dt-style-checker fallback |
| `plugins/dev-workflows/agents/risk-planner.md` | two hard rules |
| `plugins/dev-workflows/agents/doc-planner.md` | `code_repos`, `verification_warnings` v2, no auto-correct, v1.7.1 + v1.8.1 fixes |
| `plugins/dev-workflows/agents/doc-reviewer.md` | Source-code accuracy dimension + `code_repos`, marker-aware |
| `plugins/dev-workflows/agents/release-notes-writer.md` | `code_repos` + discrepancy gaps |
| `plugins/dev-workflows/commands/impl/jira/docs.md` | Phase 6.7 mandatory; new Phase 5.8; thread `code_repos`; writer markers + bug-report draft + branch/flag |
| `plugins/dev-workflows/commands/impl/docs.md` | new mandatory style phase 3.5 |
| `plugins/dev-workflows/commands/impl/jira/release-notes.md` | discrepancy escalation + bug-report draft |
| `CLAUDE.md`, `README.md`, `CHANGELOG.md`, `plugin.json`, `marketplace.json` | 1.7.0 bookkeeping |

**Copilot reference paths** (read-only sources to mirror):
- `/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/source-truth.md`
- `/workspace/ihudak-copilot-plugins/dev-workflows/agents/{doc-planner,doc-reviewer,docs-style-checker}.md`
- `/workspace/ihudak-copilot-plugins/dev-workflows/skills/impl-jira/SKILL.md` (Phase 5.8, 6, 6.7)

---

## Task 1: `references/source-truth.md` (the shared policy)

**Files:** Create `plugins/dev-workflows/references/source-truth.md`

- [ ] **Step 1: Copy the Copilot policy as the base**

```bash
cd /workspace/ihudak-claude-plugins
cp /workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/source-truth.md \
   plugins/dev-workflows/references/source-truth.md
```

- [ ] **Step 2: Apply Claude-marketplace transforms**

Edit `plugins/dev-workflows/references/source-truth.md`:
1. Replace every Copilot install-path reference (`~/.copilot/installed-plugins/ihudak-copilot-plugins/...`) with the Claude convention `${CLAUDE_PLUGIN_ROOT}/...`.
2. In §4 (sub-agent responsibilities), **delete §4.4** (`code-scanner` + `epic-reviewer`, use-case B) — epics are out of scope here.
3. In the opening line listing agents that must apply the principle, change `(doc-planner, doc-reviewer, epic-reviewer, code-scanner)` to `(doc-planner, doc-reviewer, release-notes-writer)`.
4. Add a one-line note under §4 that `release-notes-writer` applies the same verification to the specific claims its draft makes (when `code_repos` is provided), recording discrepancies in its `gaps[]` for the release-notes command to escalate.
5. Leave §7 (discrepancy escalation protocol), §7.1–§7.7, and the §6 PRODUCT-14902 example intact — they are the core of this port.

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/references/source-truth.md
grep -q "analyst" "$F" 2>/dev/null; grep -qi "Discrepancy escalation" "$F" && echo "PASS: §7 present"
grep -q "~/.copilot" "$F" && echo "FAIL: copilot path remains" || echo "PASS: no copilot paths"
grep -qi "epic-reviewer\|code-scanner" "$F" && echo "REVIEW: epic refs remain (expected only if in the example)" || echo "PASS: epic §4.4 removed"
grep -q "intentional-discrepancy" "$F" && echo "PASS: marker documented"
```

Expected: `§7 present`, `no copilot paths`, `marker documented`. The epic check may note the §6 example mentions nothing about epics; confirm §4.4 is gone.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/references/source-truth.md
git commit -m "feat(dev-workflows): add source-truth analyst-not-arbiter policy"
```

---

## Task 2: `docs-style-checker.md` — dt-style-checker fallback (Part A)

**Files:** Modify `plugins/dev-workflows/agents/docs-style-checker.md`

- [ ] **Step 1: Add the fallback hard rule near the top of "Detection order"**

Replace the heading line `## Detection order (first match wins)` with:

```
## Detection order (first match wins)

> **Hard rule before anything else:** if a detected primary linter (Vale / project lint script / markdownlint / remark) ERRORS at runtime (missing binary, non-zero exit with no parseable output, timeout), the agent MUST attempt the `dt-style-checker` fallback (step 5) before returning `status: ERROR`. "Some check is better than no check." Only return `ERROR` if the primary linter AND the `dt-style-checker` fallback both fail.
```

- [ ] **Step 2: Reword the "Nothing configured" step and add the fallback step**

Replace step 4:

```
4. **Nothing configured** — return `status: NOT_CONFIGURED`, `violations: []`. The main command treats this as a no-op and proceeds straight to Phase 7 (doc-reviewer is still the correctness gate).
```

with:

```
4. **No primary linter configured** — go to step 5 (dt-style-checker fallback). Return `status: NOT_CONFIGURED` ONLY when no primary linter is configured AND the `dt-style-guide` plugin is not installed.

5. **`dt-style-checker` fallback (always tried as a final attempt — on primary-linter ERROR or when nothing is configured).** Invoke the `dt-style-guide:dt-style-checker` agent on the input `files`. Map its return into this agent's schema:
   - violations → `status: VIOLATIONS_FOUND`, `linter: dt-style-checker`, `violations: <mapped>`.
   - zero violations → `status: OK`, `linter: dt-style-checker`.
   - the fallback itself errored → `status: ERROR`, `linter: dt-style-checker` (only NOW return ERROR).
   When the fallback ran because the primary linter failed, prefix `error:` accordingly: `"primary linter '<vale|...>' failed (<reason>); dt-style-checker fallback ran"` (OK/VIOLATIONS_FOUND) or `"...; dt-style-checker fallback also failed (<reason>)"` (ERROR). If the `dt-style-guide` plugin is not installed and no primary linter exists, return `status: NOT_CONFIGURED`.
```

- [ ] **Step 3: Update the status-codes list**

Replace the `status: NOT_CONFIGURED` and `status: ERROR` bullets:

```
- `status: NOT_CONFIGURED` — no linter detected.
```

with:

```
- `status: NOT_CONFIGURED` — no primary linter configured AND `dt-style-guide` not installed (the fallback was unavailable).
```

and

```
- `status: ERROR` — a detected linter failed to run (missing binary, non-zero exit with no parseable output, timeout). The main command will surface this to the user and may continue to Phase 7 without a style check.
```

with:

```
- `status: ERROR` — the primary linter failed AND the `dt-style-checker` fallback also failed. Only reached when no check of any kind could run.
```

- [ ] **Step 4: Update `linter:` enum and add the schema-warning note** — in the Output block, change `linter:     vale | yarn:<script> | npm:<script> | markdownlint | remark | none` to append `| dt-style-checker`. In the last hard-rule bullet ("If the linter emits warnings about its own configuration … return `status: ERROR`"), append: ` — but still attempt the dt-style-checker fallback first per the hard rule above.`

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/agents/docs-style-checker.md
grep -q "dt-style-checker fallback" "$F" && echo "PASS: fallback step"
grep -q "Some check is better than no check" "$F" && echo "PASS: hard rule"
grep -q "dt-style-checker$\|| dt-style-checker" "$F" && echo "PASS: linter enum"
```

Expected: three `PASS`.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/agents/docs-style-checker.md
git commit -m "fix(dev-workflows): docs-style-checker falls back to dt-style-checker instead of silent skip"
```

---

## Task 3: `risk-planner.md` — guardrail hard rules (Part A + B)

**Files:** Modify `plugins/dev-workflows/agents/risk-planner.md`

- [ ] **Step 1: Append two hard rules**

After the last bullet in the `## Hard rules` section (the `NEVER blur the classification` bullet and its continuation lines), add:

```
- NEVER recommend "skip the style check" as a valid disposition. Style checks are mandatory in the docs workflows; a missing linter falls back to `dt-style-checker`, never to nothing.
- NEVER recommend silently resolving a Jira-vs-source discrepancy — neither "trust the description over the code" nor "trust the code over the description". When source and description disagree, the discrepancy MUST be escalated to the user per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.
```

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -q 'NEVER recommend "skip the style check"' plugins/dev-workflows/agents/risk-planner.md && echo "PASS: skip-style rule"
grep -q "NEVER recommend silently resolving a Jira-vs-source discrepancy" plugins/dev-workflows/agents/risk-planner.md && echo "PASS: discrepancy rule"
```

Expected: two `PASS`.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/agents/risk-planner.md
git commit -m "fix(dev-workflows): risk-planner forbids skipping style checks and silent discrepancy resolution"
```

---

## Task 4: `doc-planner.md` — verification, no auto-correct, v1.7.1 + v1.8.1

**Files:** Modify `plugins/dev-workflows/agents/doc-planner.md`

- [ ] **Step 1: Add `code_repos` to Inputs**

In the Inputs YAML block, after the `screenshot_staging_dir:` line, add:

```
code_repos:             <array of {slug, path} for source-truth verification; the clones resolved for diff-summarizer; [] when unavailable>
```

- [ ] **Step 2: Add the verification step (new step after the gaps step, before "## Output")**

Insert a new numbered step (after the existing step 8 "Flag gaps…"):

```
9. **Source-truth verification (per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md`).** For every user-visible claim the checklist would put in a topic `notes:` (option lists, UI labels, menu paths, defaults, counts, mode names), verify it against `code_repos` using the techniques in source-truth.md §3. Record results in `verification_warnings[]` (schema below). **Do NOT rewrite the topic notes to match source** — preserve the original (Jira) phrasing; the orchestrator + user resolve discrepancies in `/impl:jira:docs` Phase 5.8. When `code_repos` is empty/omitted, emit one entry per user-visible claim with `finding: NOT_FOUND`, `technique: no-source-evidence`, `source_phrasing: "(not verifiable)"`.
```

- [ ] **Step 3: Add `verification_warnings` to the Output schema**

In the `## Output` YAML, after the `gaps:` block, add:

```
verification_warnings:        # source-truth findings; resolved by the orchestrator in Phase 5.8
  - number:          <stable index, 1-based>
    claim:           <short label, e.g. "Target version preset list">
    jira_phrasing:   <verbatim phrasing from the Jira/description source>
    source_phrasing: <verbatim phrasing from the code, or "(not verifiable)">
    source_location: <file:line checked, or null>
    technique:       <schema-json | datasource-class | constant | openapi | ui-source | test-fallback | menu-builder | no-source-evidence>
    finding:         VERIFIED | CONTRADICTED | NOT_FOUND | AMBIGUOUS
```

- [ ] **Step 4: v1.8.1 (Q2) — drop the Jira key from changelog entries**

Replace the step-3 changelog line:

```
   - `changelog:` — append a dated entry naming the Jira key and a 1-line change summary. Create the field if it doesn't exist on an extended page. This is mandatory on every target.
```

with:

```
   - `changelog:` — append a dated entry with a customer-readable 1-line change summary and NO Jira key. Create the field if it doesn't exist on an extended page. This is mandatory on every target. The Jira reference is carried by the commit message and the file diff, not by the reader-visible page (verified against the repo convention — fewer than 5 of dynatrace-docs's 5500+ entries cite an issue key).
```

And replace the Output-schema changelog example:

```
      changelog: {action: append, entry: "<YYYY-MM-DD> <1-line summary, ref <JIRA_KEY>>"}
```

with:

```
      changelog: {action: append, entry: "<YYYY-MM-DD> <customer-readable 1-line summary; NO Jira key>"}
```

- [ ] **Step 5: Add the v1.7.1 + v1.8.1(Q4) + Q2 hard rules**

In `## Hard rules`, add three bullets:

```
- NEVER include a Jira key inside `frontmatter_updates.changelog.entry`. The changelog is reader-visible "what changed on this page" prose; traceability is the commit message's job.
- NEVER propose a changelog-only frontmatter update on a page with no other planned change: if a target's `topics:` is empty AND `frontmatter_updates.other:` is empty AND the only change is `frontmatter_updates.changelog`, drop the target from the checklist entirely (a changelog entry with no corresponding content change is meaningless).
- NEVER let a cross-product "minimal touch" parity reference introduce content specific to the OTHER product's implementation. When extending product X's page about a feature shipped by product Y, plan `topics[].notes` as a one-line cross-link to Y's dedicated page — do NOT inline Y's implementation detail (throttling rules, enum values, precedence). Example: noting on `oneagent-update` that update windows are shared with ActiveGate is fine; copying the per-pool ActiveGate throttling rule onto the OneAgent page is not.
```

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/agents/doc-planner.md
grep -q "verification_warnings" "$F" && echo "PASS: warnings schema"
grep -q "Do NOT rewrite the topic notes to match source" "$F" && echo "PASS: no auto-correct"
grep -q "NEVER include a Jira key inside" "$F" && echo "PASS: Q2 rule"
grep -q "cross-product" "$F" && echo "PASS: Q4 rule"
grep -q "changelog-only frontmatter update" "$F" && echo "PASS: v1.7.1 rule"
grep -q "ref <JIRA_KEY>" "$F" && echo "FAIL: stale changelog template" || echo "PASS: changelog template updated"
```

Expected: five `PASS` + `changelog template updated`.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/agents/doc-planner.md
git commit -m "feat(dev-workflows): doc-planner source-truth verification (no auto-correct) + changelog/cross-product rules"
```

---

## Task 5: `doc-reviewer.md` — Source-code accuracy dimension

**Files:** Modify `plugins/dev-workflows/agents/doc-reviewer.md`

- [ ] **Step 1: Add `code_repos` to the input brief**

In `## Inputs`, after the `Style-check report` bullet, add:

```
- **Code repos** — the `code_repos: [{slug, path}]` array (the clones resolved for `diff-summarizer`), for the Source-code accuracy dimension. May be empty.
```

- [ ] **Step 2: Add the dimension to the review-dimensions table**

In the `## Review dimensions` table, add a row:

```
| Source-code accuracy | Spot-check 3–5 user-visible claims per file (option lists, labels, counts, defaults, menu paths) against `code_repos` using `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §3 techniques. **An unmarked claim contradicted by source — or absent from source when repos are available — is a BLOCKER** (customer-facing wrongness). A claim immediately preceded by a valid `<!-- intentional-discrepancy ... -->` marker is a recorded gap, NOT a BLOCKER. A claim that cannot be verified (no/partial `code_repos`) is a MAJOR with a "not verifiable" note — never a BLOCKER. |
```

- [ ] **Step 3: Add hard rules**

In `## Hard rules`, add:

```
- NEVER raise a BLOCKER on a claim that carries a valid `<!-- intentional-discrepancy ... -->` marker — it is a user-acknowledged gap (see source-truth.md §7.6). Note it as a recorded gap instead.
- NEVER raise a Source-code-accuracy BLOCKER when `code_repos` is empty/partial — downgrade to MAJOR "not verifiable".
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/agents/doc-reviewer.md
grep -q "Source-code accuracy" "$F" && echo "PASS: dimension"
grep -q "intentional-discrepancy" "$F" && echo "PASS: marker-aware"
grep -q "code_repos" "$F" && echo "PASS: input"
```

Expected: three `PASS`.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/doc-reviewer.md
git commit -m "feat(dev-workflows): doc-reviewer Source-code accuracy dimension (marker-aware)"
```

---

## Task 6: `commands/impl/jira/docs.md` — Phase 5.8, mandatory 6.7, threading, writer

**Files:** Modify `plugins/dev-workflows/commands/impl/jira/docs.md`

- [ ] **Step 1: Thread `code_repos` into the doc-planner invocation (Phase 5.7)**

In the `doc-planner` Agent invocation block, after the `repo_root:` line, add:

```
  > code_repos:           [the Phase-4 resolved {slug, path} map; [] if none resolved]
```

- [ ] **Step 2: Add Phase 5.8 (Discrepancy analysis & decision)**

Immediately after the Phase 5.7 section (the doc-planner invocation + its result handling) and before Phase 6, insert a new section. Mirror the structure of Copilot's `impl-jira` Phase 5.8 (read `/workspace/ihudak-copilot-plugins/dev-workflows/skills/impl-jira/SKILL.md` Phase 5.8 for exact wording) adapted to this command. It MUST contain:

```
## Phase 5.8 — Discrepancy analysis & user decision

Run this phase when the `doc-planner` handoff contains any `verification_warnings` with `finding: CONTRADICTED`, `NOT_FOUND`, or `AMBIGUOUS`. If there are none, skip to Phase 6.

1. **Present the analysis table** (informational, before asking):
   ```
   | # | Claim | Jira phrasing | Source phrasing | Source location | Verdict |
   ```
   One row per warning. Use `Source phrasing: "(not verifiable)"` for `no-source-evidence` entries.

2. **Batch decision:**
   ```
   choices: ["Decide per discrepancy (Recommended)", "Document ALL as source suggests", "Document ALL as Jira claims (drafts a bug report)", "Skip ALL and report (drafts a bug report)", "Cancel", "Other… (describe)"]
   ```

3. **Per-discrepancy** (if "Decide per discrepancy"): for each warning, show claim + Jira phrasing + source phrasing + location, then:
   ```
   choices: ["Document as source suggests", "Document as Jira claims (adds an intentional-discrepancy marker + bug-report draft)", "Skip this claim and report it", "Cancel", "Other… (describe)"]
   ```

4. **Record `discrepancy_decisions[]`** keyed by `number` (claim, jira_phrasing, source_phrasing, source_location, decision ∈ {document-as-source, document-as-jira, skip-and-report}, rationale). Set `bug_report_destination` to the ticket's vault project folder (resolved exactly like the release-notes destination in `/impl:jira:release-notes` — `find $VAULT_PATH/Projects -maxdepth 5 -type d -name "<JIRA_KEY>*"`; ask if none) when any decision is `document-as-jira` or `skip-and-report`.

Pass `discrepancy_decisions` to Phase 6.
```

- [ ] **Step 3: Add writer rules for decisions (Phase 6)**

In Phase 6 (the writer), add a step describing how to apply `discrepancy_decisions`:

```
- **Apply discrepancy decisions** (from Phase 5.8), per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §7.4–§7.6:
  - `document-as-source` → use the source phrasing verbatim.
  - `document-as-jira` → use the Jira phrasing AND insert immediately before the affected prose:
    `<!-- intentional-discrepancy: Jira <JIRA_KEY> describes "<jira_phrasing>" but the source at <source_location> currently has "<source_phrasing>". User decision: document Jira phrasing pending implementation. See <JIRA_KEY>-implementation-gaps.md gap #<n>. -->`
    Strongly recommend committing to a branch (Phase 6.5); the Phase 9 report MUST flag "do NOT merge this docs PR until the gaps are resolved". The plugin does NOT open a PR (zero-external-API invariant).
  - `skip-and-report` → omit the claim from the docs.
  - When any decision is `document-as-jira`/`skip-and-report`, write `<bug_report_destination>/<JIRA_KEY>-implementation-gaps.md` using the §7.5 format (vault project folder; never `/tmp`; never the docs repo).
```

- [ ] **Step 4: Make Phase 6.7 mandatory + thread code_repos into Phase 7**

In Phase 6.7, add at the top: `**Mandatory:** the orchestrator MUST dispatch \`docs-style-checker\` and act on its return — never skip on its own judgement of which linters are installed.` Remove any "proceed to review without style check" choice from the ERROR escalation, replacing it with "Proceed to doc-reviewer" (which still runs). In the Phase 7 `doc-reviewer` invocation, add a `code_repos:` line (same map as Phase 5.7) and pass the written-file paths so the Source-code accuracy dimension can run.

- [ ] **Step 5: Add the Phase 9 report section for gaps**

In the Phase 9 report template, add a section:

```
### Implementation gaps (Jira vs source)
[Populated when Phase 5.8 produced any document-as-jira / skip-and-report decision. List each gap (claim, decision) and: "Bug-report draft written to <path>. If docs were branched, DO NOT merge the PR until these gaps are resolved." Omit when there were no discrepancies.]
```

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/impl/jira/docs.md
grep -q "Phase 5.8 — Discrepancy analysis" "$F" && echo "PASS: phase 5.8"
grep -q "discrepancy_decisions" "$F" && echo "PASS: decisions record"
grep -q "implementation-gaps.md" "$F" && echo "PASS: bug-report draft"
grep -q "intentional-discrepancy" "$F" && echo "PASS: marker"
grep -q "code_repos:" "$F" && echo "PASS: code_repos threaded"
grep -qi "Mandatory" "$F" && echo "PASS: 6.7 mandatory"
```

Expected: six `PASS`.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/commands/impl/jira/docs.md
git commit -m "feat(dev-workflows): /impl:jira:docs discrepancy escalation (Phase 5.8) + mandatory style check"
```

---

## Task 7: `commands/impl/docs.md` — mandatory style phase

**Files:** Modify `plugins/dev-workflows/commands/impl/docs.md`

- [ ] **Step 1: Insert Phase 3.5 between Phase 3 and Phase 4**

After Phase 3's step 9 ("Proceed to Phase 4.") and before `## Phase 4`, insert:

```
## Phase 3.5 — Style check (mandatory)

After writing the edits and before Phase 4, dispatch `docs-style-checker` on the changed file(s):

→ Agent (subagent_type: "dev-workflows:docs-style-checker"):
  > repo_root: [cwd's git root]
  > files:     [the files edited in Phase 3]

- `VIOLATIONS_FOUND` → apply safe fixes via `doc-fixer` (one fix cycle), then re-run once.
- `OK` / `NOT_CONFIGURED` → proceed to Phase 4 (NOT_CONFIGURED means no primary linter AND no `dt-style-guide` fallback — recorded, not silently ignored).
- `ERROR` → surface the reason; proceed to Phase 4 (the edit is small and user-managed).

Never skip this phase on your own judgement of which linters are installed — `docs-style-checker` already falls back to `dt-style-checker` when Vale is absent.
```

Update Phase 3 step 9 from `Proceed to Phase 4.` to `Proceed to Phase 3.5.`

- [ ] **Step 2: Add an invariant**

In `## Invariants (always enforced)`, add:

```
- ALWAYS run Phase 3.5 (style check) after editing — `docs-style-checker` falls back to `dt-style-checker`; never skip style on tool-absence judgement
```

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins
F=plugins/dev-workflows/commands/impl/docs.md
grep -q "Phase 3.5 — Style check" "$F" && echo "PASS: phase 3.5"
grep -q "Proceed to Phase 3.5" "$F" && echo "PASS: phase 3 links to 3.5"
grep -q "ALWAYS run Phase 3.5" "$F" && echo "PASS: invariant"
```

Expected: three `PASS`.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/commands/impl/docs.md
git commit -m "fix(dev-workflows): /impl:docs gains a mandatory style-check phase"
```

---

## Task 8: Release-notes flow — discrepancy handling

**Files:** Modify `plugins/dev-workflows/agents/release-notes-writer.md` and `plugins/dev-workflows/commands/impl/jira/release-notes.md`

- [ ] **Step 1: Add `code_repos` + discrepancy gaps to the agent**

In `agents/release-notes-writer.md` Inputs, add `code_repos: <optional array of {slug, path}; provided when diff-grounding is on>`. Add a process step:

```
N. **Source-truth check (when `code_repos` is provided).** Verify the specific option/label/count claims the draft makes against the source (per `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md` §3). Do NOT auto-resolve: when a claim is contradicted, record a `gaps[]` entry with `field: prose`, `jira_phrasing`, `source_phrasing`, `source_location`, and `recommended_action: "ask user"`. Keep the draft prose in the Jira phrasing for now; the command resolves it.
```

Add a hard rule: `- When code_repos is provided, NEVER silently emit a claim the source contradicts; record it in gaps[] for the command to escalate.`

- [ ] **Step 2: Add discrepancy escalation to the command (Phase 6/7 area)**

In `commands/impl/jira/release-notes.md`, after the render phase, add handling: when `release-notes-writer` returns `gaps[]` with `jira_phrasing`/`source_phrasing`, present the same discrepancy table and per-claim prompt as `/impl:jira:docs` Phase 5.8 (choices: document-as-source / document-as-jira / skip-and-report). Apply the decision to the prose. For `document-as-jira` or `skip-and-report`, write/append `<vault-project-folder>/<JIRA_KEY>-implementation-gaps.md` (same destination resolution as the release-notes draft). Pass `code_repos` (the Phase-4 resolved map) to the writer when diff-grounding is on.

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -q "code_repos" plugins/dev-workflows/agents/release-notes-writer.md && echo "PASS: writer code_repos"
grep -q "source_phrasing" plugins/dev-workflows/agents/release-notes-writer.md && echo "PASS: writer gaps"
grep -q "implementation-gaps.md" plugins/dev-workflows/commands/impl/jira/release-notes.md && echo "PASS: command bug-report"
grep -q "code_repos" plugins/dev-workflows/commands/impl/jira/release-notes.md && echo "PASS: command threads repos"
```

Expected: four `PASS`.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/agents/release-notes-writer.md plugins/dev-workflows/commands/impl/jira/release-notes.md
git commit -m "feat(dev-workflows): release-notes flow escalates source discrepancies"
```

---

## Task 9: Bookkeeping — CLAUDE.md, README, CHANGELOG, 1.7.0

**Files:** Modify `CLAUDE.md`, `plugins/dev-workflows/README.md`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

- [ ] **Step 1: CLAUDE.md — add source-truth as a single-source policy + invariants**

After the `## Model routing reference` section, add a short `## Source-truth reference` paragraph naming `plugins/dev-workflows/references/source-truth.md` as the single source of truth for the Implementation-vs-Description discrepancy-escalation protocol (consulted by `doc-planner`, `doc-reviewer`, `release-notes-writer`). In the `/impl:jira:docs` invariants block, add bullets: style check is mandatory (falls back to dt-style-checker); discrepancies are escalated in Phase 5.8 (never auto-resolved); a bug-report draft (`<KEY>-implementation-gaps.md`) is written to the vault project folder for document-as-jira/skip decisions.

- [ ] **Step 2: CLAUDE.md — update the workflow map**

In the `dev-workflows` workflow-relationships fenced block, update the `/impl:jira:docs` line to insert `[discrepancy-escalation]` after `doc-planner`:

```
/impl:jira:docs      → /impl:jira:docs → jira-reader → [diff-summarizer×N (parallel)] → [doc-location-finder] → [doc-planner] → [discrepancy-escalation (Phase 5.8)] → writing → [docs-style-checker → dt-style-checker fallback] → [doc-fixer] → [doc-reviewer] → [doc-fixer] → impl-maintenance
```

- [ ] **Step 3: README — note style fallback + discrepancy escalation**

In `plugins/dev-workflows/README.md`, update the `/impl:jira:docs` row (and the external-tools section about Vale) to mention: style checks always run (Vale-missing falls back to `dt-style-checker`); Jira-vs-source discrepancies are escalated to the user with a bug-report draft.

- [ ] **Step 4: CHANGELOG — prepend 1.7.0**

Prepend after the header block:

```
## [1.7.0] — 2026-06-16

### Added
- **Source-truth discrepancy escalation (`references/source-truth.md`).** The docs flow now verifies user-visible claims against the shipped source and, when Jira and source disagree, escalates to the user (`/impl:jira:docs` Phase 5.8) instead of silently picking a side — document-as-source / document-as-jira (+ `<KEY>-implementation-gaps.md` bug-report draft + `intentional-discrepancy` marker) / skip-and-report. `doc-planner` records both `jira_phrasing` and `source_phrasing` (never auto-corrects); `doc-reviewer` gains a marker-aware Source-code accuracy dimension; the release-notes flow escalates the same way. Ports Copilot dev-workflows v1.7.0 + v1.8.0.

### Fixed
- **Style checks are robust and mandatory.** `docs-style-checker` falls back to the LLM-based `dt-style-checker` when the primary linter (Vale, etc.) errors or is missing — `NOT_CONFIGURED` only when nothing is available. `/impl:jira:docs` Phase 6.7 and a new `/impl:docs` Phase 3.5 are mandatory. `risk-planner` forbids recommending a skipped style check. (Copilot v1.7.0)
- **`doc-planner` accuracy rules.** No Jira key in changelog entries (commit carries traceability); no changelog-only frontmatter updates; cross-product parity touches are one-line pointers, never copied implementation detail. (Copilot v1.7.1 + v1.8.1)
```

- [ ] **Step 5: Bump versions**

`plugin.json`: replace `"version": "1.6.0",` with `"version": "1.7.0",`. `marketplace.json`: with the Edit tool, replace the dev-workflows entry's `"version": "1.6.0",` with `"version": "1.7.0",` (surgical — NEVER a JSON re-serializer; em-dashes must stay literal).

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json    # 1.7.0
grep -A1 '"name": "dev-workflows"' .claude-plugin/marketplace.json | grep version  # 1.7.0
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('JSON valid')"
echo "backslash-u (expect 0): $(grep -c '\\u' .claude-plugin/marketplace.json)"
grep -q "Source-truth" CLAUDE.md && echo "PASS: CLAUDE policy ref"
```

Expected: `1.7.0` twice, `JSON valid`, `0`, `PASS`.

- [ ] **Step 7: Commit**

```bash
git add CLAUDE.md plugins/dev-workflows/README.md plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "release: dev-workflows 1.7.0 (discrepancy escalation + style robustness)"
```

---

## Task 10: Final verification sweep

**Files:** none (verification only)

- [ ] **Step 1: Cross-file consistency checks**

```bash
cd /workspace/ihudak-claude-plugins
# source-truth.md is referenced by all three consuming agents
for a in doc-planner doc-reviewer release-notes-writer; do
  grep -q "source-truth.md" "plugins/dev-workflows/agents/$a.md" && echo "PASS: $a refs policy" || echo "FAIL: $a"
done
# no agent/command still says "code wins" / auto-correct to source
grep -rn "code wins\|rewrite the topic notes to match" plugins/dev-workflows/agents/doc-planner.md && echo "REVIEW" || echo "PASS: no code-wins language"
# changelog template no longer embeds the Jira key
grep -rn "ref <JIRA_KEY>" plugins/dev-workflows/agents/doc-planner.md && echo "FAIL: stale template" || echo "PASS"
# version coherent
grep -A1 '"name": "dev-workflows"' .claude-plugin/marketplace.json | grep -q '1.7.0' && echo "PASS: marketplace 1.7.0"
```

Expected: all `PASS`.

- [ ] **Step 2: Structural smoke (PRODUCT-14902 is the canonical discrepancy case)**

Confirm the policy file documents the PRODUCT-14902 UI-rename discrepancies as the worked example (it carried over from the Copilot source in Task 1):

```bash
grep -qi "PRODUCT-14902\|Older" plugins/dev-workflows/references/source-truth.md && echo "PASS: worked example present"
```

Expected: `PASS`.

---

## Post-implementation

- [ ] Offer to merge `feat/source-truth-style-robustness` → `main`, push, and update the installed plugin (`claude plugin marketplace update ihudak-plugins` + `claude plugin update dev-workflows@ihudak-plugins`). Do not push without the human's go-ahead.

---
tags:
  - tasks-exclude
---
# `/idea` command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `/idea` command (dev-workflows v2.15.0) — the front door of the VI-creation flow — which ingests one of four source types and, through a bounded/`--deep` grill, writes a well-refined `idea.md` seed for the future `/create-vi`.

**Architecture:** Additive to the dev-workflows plugin (markdown commands/agents/references + JSON manifests). A new orchestrator command (`commands/idea.md`) invokes a new read-only ingestion subagent (`agents/idea-reader.md`), grills inline on the Opus chain, and writes `idea.md` (shape defined by a new `references/idea-format.md`) to the vault. The new command wires into the existing cost / feedback / capture-at-block subsystems. A new `references/dependencies.md` documents companion plugins.

**Tech Stack:** Markdown command/agent/reference files; JSON plugin manifests; `python3` (stdlib) for JSON validation. NO test framework and NO husky/prettier hook — verification is **structural** (grep anchors, `python3 json.load`, byte-diff).

## Global Constraints

- **Additive only.** No existing command/agent/reference behavior changes except the count/enumeration reconciliations named in Tasks 5–7. `impl-maintenance`, `jira-reader`, reviewers, and `session-cost.py` are untouched.
- **Version lock-step 2.15.0** in BOTH `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of the repo-root `.claude-plugin/marketplace.json`. The two `description` strings MUST stay **byte-identical**.
- **Sibling plugins untouched & byte-identical:** `dt-style-guide` 0.2.2 and `obsidian-llm-wiki` 0.3.1 entries in `marketplace.json` are not modified.
- **Commit named files only — NEVER `git add -A`.** Branch `ivgu/NOISSUE-idea-command`. Commit trailer EXACTLY: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Grilling technique is embedded** (no hard runtime dependency), consistent with `/specify` and `/design`.
- **Never write into cwd** — `/idea` writes only to the validated vault (or a user-supplied dir).
- **Do NOT touch** the README "Six of the seven dev-workflows commands … classify tasks as SIMPLE / … / HIGH-RISK" sentence (~line 20). That sentence describes the *risk-classification* cohort (code/doc commands + `/docs-profile`); `/idea`'s routing is authoring-tier (embedded grill, no code-risk gate), so it is intentionally out of that set. Leaving it is correct, not a missed count.
- Watch for lima read-after-write git flakiness on commit: `git fsck --full` first, `git update-ref` the dangling commit if a ref-write fails, verify HEAD after each write.

---

## File Structure

**New files**
- `plugins/dev-workflows/references/idea-format.md` — the `idea.md` artifact contract (SSOT). Cited by the command and the reader.
- `plugins/dev-workflows/agents/idea-reader.md` — read-only source-ingestion subagent (Sonnet tier). Mirrors `jira-reader`.
- `plugins/dev-workflows/references/dependencies.md` — companion-plugins/deps SSOT.
- `plugins/dev-workflows/commands/idea.md` — the orchestrator command (Opus tier). Mirrors `specify.md`.

**Modified files**
- `plugins/dev-workflows/references/feedback-emission.md` — command count eight → nine (2 spots).
- `plugins/dev-workflows/references/cost-emission.md` — header VI-lifecycle enumeration + §7 attribution row.
- `plugins/dev-workflows/.claude-plugin/plugin.json` — version + description (counts + lists).
- `.claude-plugin/marketplace.json` (repo root) — dev-workflows entry version + description (byte-identical).
- `plugins/dev-workflows/CHANGELOG.md` — prepend `## [2.15.0]` entry.
- `plugins/dev-workflows/README.md` — lead count, command-table row, cost-phase count line, feedback list, new Dependencies section.

All paths below are relative to the repo root `/workspace/ihudak-claude-plugins`.

---

### Task 1: `references/idea-format.md` (idea.md contract)

**Files:**
- Create: `plugins/dev-workflows/references/idea-format.md`

**Interfaces:**
- Produces: the section headings + frontmatter keys that Task 2 (`candidate_*` fields) and Task 3 (Phase 4 authoring) rely on: frontmatter `title, slug, sources[].provenance, sources[].ref, created, status`; sections `## Problem`, `## Who`, `## Desired outcome & value`, `## Rough scope`, `## Signals & evidence`, `## Open questions & assumptions`, `## Candidate success signal`; the `status: refined IFF zero [NEEDS CLARIFICATION]` rule.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
# Idea format (embedded authority)

The canonical structure and per-section rules for a refined `idea.md`. `/idea` authors against this
file; `/create-vi` (future) consumes it. A lean one-page brief — the seed a Value Increment is built
from, NOT a mini-VI.

## Frontmatter

```yaml
---
title: <candidate human-readable title>
slug: <candidate-kebab-slug>
sources:
  - provenance: rfe | markdown | community-post | prompt
    ref: <path | JIRA-KEY | url>
created: <YYYY-MM-DD>
status: draft | refined        # refined IFF zero open [NEEDS CLARIFICATION] remain
---
```

Rules: `status` is `refined` only when the **Open questions & assumptions** section carries zero
`[NEEDS CLARIFICATION]` markers; otherwise `draft`. `sources` lists every ingested source with its
provenance (re-running `/idea` for the same `slug` refines the existing file and appends a source).

## Section 1 — Problem

`## Problem` — the pain today, solution-free. Who is affected and why the current situation is
insufficient. No proposed solution, no technology detail.

## Section 2 — Who

`## Who` — the target users / personas affected. Specific roles, not "everyone".

## Section 3 — Desired outcome & value

`## Desired outcome & value` — the value hypothesis: what "better" looks like and why it matters now.

## Section 4 — Rough scope

`## Rough scope` — **In:** initial in-scope bullets; **Out:** initial guardrails. *What*, not *how*.

## Section 5 — Signals & evidence

`## Signals & evidence` — demand evidence grounding the idea: RFE reference, community-post
requesters/upvotes, wikilinked docs, and image references. Cite sources; never fabricate.

## Section 6 — Open questions & assumptions

`## Open questions & assumptions` — unresolved decisions as `- [NEEDS CLARIFICATION: <question>]`
(**capped at 3** — the highest-impact only); reasonable defaults recorded as
`- **Assumption:** <text>`.

## Section 7 — Candidate success signal

`## Candidate success signal` — how we'd know it worked (rough, outcome-oriented, technology-agnostic).
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/references/idea-format.md
grep -q "^# Idea format (embedded authority)" "$f" \
  && grep -q "status: draft | refined" "$f" \
  && grep -q "refined IFF zero" "$f" \
  && for h in "## Problem" "## Who" "## Desired outcome & value" "## Rough scope" "## Signals & evidence" "## Open questions & assumptions" "## Candidate success signal"; do grep -qF "$h" "$f" || { echo "MISSING: $h"; exit 1; }; done \
  && echo "OK idea-format"
```
Expected: `OK idea-format`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/idea-format.md
git commit -m "feat(idea): add idea.md format reference

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `agents/idea-reader.md` (source-ingestion subagent)

**Files:**
- Create: `plugins/dev-workflows/agents/idea-reader.md`

**Interfaces:**
- Consumes: nothing at runtime from Task 1, but its `candidate_title`/`candidate_slug` outputs feed the `idea-format.md` frontmatter.
- Produces: the output-schema keys Task 3 (Phase 2) reads: `status`, `provenance`, `source_refs[]`, `raw_context`, `signals[]`, `images[]`, `wikilinks_followed[]`, `wikilinks_broken[]`, `candidate_title`, `candidate_slug`. Input contract: `argument`, `provenance_hint`, `vault_path`.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
---
name: idea-reader
description: Ingests one idea source (inline prompt, a markdown file with wikilinks/images, a community post, or an exported RFE Jira ticket) from the user's vault and returns a structured source digest for /idea. Follows wikilinks one level, enumerates linked images (paths only), and captures community-post demand signals. Read-only; never modifies files. Model tier assigned by the caller per the model-routing policy (no fixed pin).
tools: ["Read", "Glob", "Grep", "LS"]
---

Ingest one idea source and return a structured digest. Read-only — never modify any file.

Invoked from `/idea` (Phase 2). The caller has already classified the source type (Phase 1); this
agent reads the source, follows context links, and distills the raw material the orchestrator's
grilling loop refines into `idea.md`. This agent does NOT grill, decide gaps, or write `idea.md`.

## Inputs

```yaml
argument:        <the raw /idea argument: prompt text | file path / @wikilink | JIRA-KEY>
provenance_hint: prompt | markdown | community-post | rfe   # from the caller's Phase 1 classification
vault_path:      <absolute $VAULT_PATH>
```

Refuse to run without `argument` and `provenance_hint`.

## Process

**prompt** (`provenance_hint: prompt`) — treat `argument` as the raw idea text. No filesystem reads.
Distill it into `raw_context`; `source_refs: []`.

**markdown / community-post** (`provenance_hint: markdown | community-post`) — resolve `argument` to an
existing `.md` file (accept an absolute path, a vault-relative path, or an `@wikilink` resolved under
`vault_path`). Read it. Follow wikilinks (`[[...]]`) to other `.md` files **one level deep** (bounded)
and read them for context. Enumerate linked images (extensions `.png/.jpg/.jpeg/.gif/.svg/.webp`,
case-insensitive) — record **paths only, never read image content**. For a community post (a markdown
file under a `Projects/Products/` path, or with a thread/comment shape), additionally extract **demand
signals** — requester names/handles, upvote/vote counts, recurring asks — into `signals`.

**rfe** (`provenance_hint: rfe`) — validate `argument` against `^[A-Z][A-Z0-9_]*-\d+$`; on mismatch
return `status: NOT_FOUND` naming the invalid key. Locate the export dir at
`<vault_path>/jira-products/<KEY>/` and read `<KEY>/<KEY>.md` (the nested same-named file, per the
Jira→Obsidian export layout). Enumerate `attachments/`/`Attachments/` image filenames (paths only) and
read any wikilinked context. Distill the ticket summary/description into `raw_context`; put
requester / customer-demand info into `signals`.

Note unresolved wikilinks/images in `wikilinks_broken` and continue — a broken link is never fatal.

## Output

Return this exact YAML shape (no preamble, no chatter):

```yaml
status: OK | NOT_FOUND
provenance: prompt | markdown | community-post | rfe
source_refs:
  - <path | JIRA-KEY | url>
raw_context: |
  <distilled problem / users / value / scope hints from the source(s)>
signals:
  - <demand-evidence bullet: requester, upvotes, recurring ask, linked case>
images:
  - <absolute path to a linked image (not read)>
wikilinks_followed:
  - <path of a followed .md>
wikilinks_broken:
  - <unresolved wikilink target>
candidate_title: <human-readable title inferred from the source>
candidate_slug:  <kebab-case slug inferred from the source>
```

## Hard rules

- NEVER modify any file. This agent is read-only.
- NEVER read the **content** of image files — enumerating filenames/paths is permitted and required.
- NEVER reach out over HTTPS to Jira or any host — operate purely on the inline prompt and pre-exported / vault markdown.
- NEVER fabricate demand signals, requesters, or sources not present in the input.
- Follow wikilinks at most ONE level deep to bound the read.
- On an invalid RFE key or a missing file, return `status: NOT_FOUND` with a clear message; do not guess.
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/agents/idea-reader.md
grep -q "^name: idea-reader" "$f" \
  && grep -q '"Read", "Glob", "Grep", "LS"' "$f" \
  && for k in "provenance:" "source_refs:" "raw_context:" "signals:" "images:" "wikilinks_followed:" "wikilinks_broken:" "candidate_title:" "candidate_slug:"; do grep -qF "$k" "$f" || { echo "MISSING key: $k"; exit 1; }; done \
  && grep -q "NEVER modify any file" "$f" \
  && grep -q "NEVER reach out over HTTPS" "$f" \
  && echo "OK idea-reader"
```
Expected: `OK idea-reader`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/idea-reader.md
git commit -m "feat(idea): add idea-reader ingestion subagent

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `commands/idea.md` (orchestrator)

**Files:**
- Create: `plugins/dev-workflows/commands/idea.md`

**Interfaces:**
- Consumes: `references/idea-format.md` (Task 1) for authoring; `agents/idea-reader.md` (Task 2) via the Phase 2 Agent dispatch (input contract `argument`/`provenance_hint`/`vault_path`; reads the digest keys); `references/feedback-emission.md` `emit-auto`/`emit-block`; `references/cost-emission.md` `emit-cost`; the `dev-workflows:model-routing` skill; `references/dependencies.md` (Task 4, cross-link only).
- Produces: `idea.md` in the vault; cost/feedback side-effects.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
---
name: idea
description: Idea-refinement workflow (PM phase, front of the VI-creation flow). Takes one source — an inline prompt, a markdown file (with wikilinks/images), a community post, or an exported RFE Jira ticket — and, through a bounded one-question-at-a-time grill (--deep for relentless), authors a well-refined idea.md: a lean one-page brief that seeds the future /create-vi. Writes to the vault (keyless); no Jira, no code, no specs write.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Refine an idea into `idea.md`: $ARGUMENTS

`/idea` is the **front door of the VI-creation flow** (PM phase) — upstream of `/create-vi` (future) and
the existing pipeline. It ingests one source, refines it through a grill, and writes a lean one-page
`idea.md` (per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`) that seeds the Value Increment. It is
**not** a VI: no Jira write, no code change, no specs-repo write. Output lands keyless in the vault;
`/create-vi` relocates it under `$SPECS_PATH` once a Jira key exists.

Flag: `--deep` switches the grill from bounded (≤5 questions) to relentless (until convergence).

---

## Phase 0 — Validate environment + resolve model routing

1. **Validate `$VAULT_PATH`.** It must be **set**, an **existing directory**, look like the user's
   personal store (`$VAULT_PATH/.obsidian/` is a directory — the same marker the specs-first ladder
   uses), and be **writable**. If any check fails, STOP and offer:
   ```
   choices: ["Enter a directory to write idea.md into", "Cancel", "Other… (describe)"]
   ```
   On a user-supplied directory, validate it exists and is writable, then use it as the **write root**
   for this run. **NEVER** write into the current working directory (it may be a code repo). This is an
   environment halt, **not** a plugin-gap halt — do NOT `emit-block`.

2. **Resolve model routing.** Invoke the `model-routing` skill (Skill tool,
   `skill: "dev-workflows:model-routing"`), then record:
   ```yaml
   model_routing:
     classification: MODERATE          # idea refinement is typically MODERATE
     reason: <one-line>
     current_model: <the model this orchestrator/grill is running under>
     detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # idea-reader
     authoring_model: <= current_model>   # the interactive grill + idea.md authoring (session model, not a delegated subagent)
     opus_available: <true if a §2 Opus model resolved, else false>
     notes: <any §2/§2.1 fallback or degradation>
   ```
   The grill + authoring run inline on `current_model` (the §2 Opus chain — interactive judgment, not a
   delegated subagent). `idea-reader` runs on `detection_model`. If no Opus resolves, **degrade to the
   best available and record the degradation** in `notes` and the final report — do NOT hard-block (a PM
   must not be blocked from capturing an idea by a momentary Opus outage).

---

## Phase 1 — Classify the source

Classify `$ARGUMENTS` (minus the `--deep` flag) by precedence:

1. Matches the Jira-key regex `^[A-Z][A-Z0-9_]*-\d+$` → **rfe** (an exported Product-Enhancement ticket
   under `$VAULT_PATH/jira-products/<KEY>/`).
2. An existing `.md` path or an `@wikilink` → **markdown** (a community post is just a markdown file,
   typically under `Projects/Products/…` — the reader tags it `community-post`; an existing `idea.md`
   passed back for re-refinement is detected here too).
3. Otherwise → **prompt** (the argument text is the raw idea).

Surface a one-line confirmation before ingesting:
```
choices: ["Read this as <detected-type> (Recommended)", "It's actually a <other-type>", "Cancel", "Other… (describe)"]
```
(A dedicated `--as prompt|file|rfe` override is future work — the confirmation covers a mis-detection.)

---

## Phase 2 — Ingest the source (idea-reader)

Dispatch `idea-reader` to read the source and return a structured digest:

→ Agent (subagent_type: "dev-workflows:idea-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Ingest this idea source and return the structured digest:
  >
  > argument:        [the resolved argument]
  > provenance_hint: [prompt | markdown | community-post | rfe from Phase 1]
  > vault_path:      [resolved $VAULT_PATH]"

Wait for the digest. If `status: NOT_FOUND` (invalid RFE key / missing file), surface:
```
choices: ["Re-enter the source", "Cancel", "Other… (describe)"]
```
This is an environment/user halt — do NOT `emit-block`. On `OK`, carry forward `raw_context`,
`signals`, `images`, `candidate_title`, `candidate_slug`, and the followed/broken wikilinks.

---

## Phase 3 — Refine via grill

**Interview technique (grilling — embedded; no runtime plugin dependency).**

- Ask exactly ONE question at a time; wait for the answer before the next. Never batch — a firehose is bewildering.
- For every question, give your recommended answer, so the user reacts to a proposal, not a blank prompt.
- If a question can be answered from the `idea-reader` digest or the vault, explore and answer it yourself instead of asking (fact-vs-decision split — look up facts, only put decisions to the user).
- Walk the design tree in dependency order — resolve a parent decision before dependents.

(Technique adapted from mattpocock grill-me/grilling; embedded here so `/idea` has no runtime dependency. If `mattpocock-skills` `/grilling` is installed the user may invoke it directly — see `${CLAUDE_PLUGIN_ROOT}/references/dependencies.md`.)

Scan for gaps against an idea-stage **ambiguity taxonomy**: *problem clarity, target users, desired
outcome/value, scope boundaries, evidence/demand sufficiency, success signal, terminology.* Rank gaps
by **Impact × Uncertainty**.

- **Default (bounded):** ask **≤5** questions across the ranked gaps, then stop. Remaining high-impact
  gaps become `- [NEEDS CLARIFICATION: <question>]` in the `idea.md` **Open questions & assumptions**
  section, **capped at 3**; reasonable defaults are recorded as `- **Assumption:** <text>`.
- **`--deep`:** relentless — keep walking the design tree one question at a time until you and the user
  reach shared understanding; the cap does not apply.

---

## Phase 4 — Write idea.md

Author `idea.md` per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` into the write root resolved in
Phase 0:

- **Path:** `<write-root>/Projects/<area>/<candidate_slug>/idea.md`, where `<area>` = `Products` when
  the source already lives under `Projects/Products/…`, else `ideas`.
- **Existing file:** if `idea.md` already exists at that path, offer:
  ```
  choices: ["Refine the existing idea.md (Recommended)", "Create a new one (you'll be prompted for a slug)", "Cancel", "Other… (describe)"]
  ```
  On *refine*, re-open it, resolve its open `[NEEDS CLARIFICATION]` items, and append the new source to
  `sources`.
- **`status`:** set frontmatter `status: refined` IFF zero `[NEEDS CLARIFICATION]` markers remain;
  otherwise `status: draft`.

---

## Phase 5 — Handoff: adaptive next-phase offer

Report where `idea.md` was written and its `status`, then offer the next phase — **adapted to status**:

- **`refined`:** *"Idea refined. Next: create the VI — first create an empty Jira workitem, then run
  `/create-vi <JIRA-KEY> @<idea.md path>`."*
- **`draft`** (N open clarifications): *"This idea has N open clarification(s). You can (a) run
  `/idea @<idea.md path> --deep` to resolve them, or (b) proceed to `/create-vi <JIRA-KEY> @<idea.md
  path>`, which will grill you on the rest."*

`/create-vi` is a separate command (future sub-project); this offer is guidance the user acts on — it
never auto-invokes another command. (`/idea` is the reference implementation of the plugin-wide
next-phase-offer pattern.)

---

## Phase 6 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 5, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference
gap** (a capability the run needed but the plugin lacked), `emit-block` (per
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating — so a run
abandoned at the block still records the gap. NEVER `emit-block` for an environment / user halt (bad
`$VAULT_PATH`, source-not-found, cancellation).

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /idea
   > - What was done: [one-paragraph summary of the idea refined + source type]
   > - Key events: [source-detection corrections, unresolved clarifications, broken wikilinks — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: N/A (no reviewer in /idea)
   > - Test result: N/A (no tests in /idea)
   > - Project root: [the idea.md folder]"
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /idea`, `jira_key: null`, the run's `source`, and
   `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It renders only the
   plugin-facing slice (§4), dedupes by stable `id` (§3), resolves the target via the §2 specs-first
   ladder, and writes silently. Surface the persisted path (or "no plugin-facing signal — nothing
   persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its
   `emit-cost` entry point with `command: /idea`, `phase: vi-creation`, `role: pm`, `jira_key: null`,
   the run's `source`, and `plugin_version`. A keyless run writes to the pending ladder (§9) and
   **advances the chained checkpoint** (§3); surface the persisted path (or the report-only notice).

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into a code/docs repo or the
current working directory; no user name is ever written.

---

## Final report

Report: the `idea.md` path + `status` (refined / draft with N open clarifications); the source type and
`sources`; the count of `[NEEDS CLARIFICATION]` items and Assumptions; any source-detection correction
or broken wikilinks; the resolved model routing (+ any Opus degradation); the feedback path; the cost
path (or notice); and the adaptive next-phase recommendation.
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/commands/idea.md
grep -q "^name: idea" "$f" \
  && grep -q "allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS" "$f" \
  && for h in "## Phase 0 — Validate environment" "## Phase 1 — Classify the source" "## Phase 2 — Ingest the source" "## Phase 3 — Refine via grill" "## Phase 4 — Write idea.md" "## Phase 5 — Handoff" "## Phase 6 — Session maintenance, feedback & cost"; do grep -qF "$h" "$f" || { echo "MISSING: $h"; exit 1; }; done \
  && grep -q 'skill: "dev-workflows:model-routing"' "$f" \
  && grep -q "no runtime plugin dependency" "$f" \
  && grep -q -- "--deep" "$f" \
  && grep -qF '$VAULT_PATH/.obsidian/' "$f" \
  && grep -q "status: refined" "$f" \
  && grep -q "subagent_type: \"dev-workflows:idea-reader\"" "$f" \
  && grep -q "emit-cost" "$f" && grep -q "phase: vi-creation" "$f" && grep -q "role: pm" "$f" \
  && grep -q "emit-auto" "$f" && grep -q "Capture-at-block invariant" "$f" \
  && echo "OK idea command"
```
Expected: `OK idea command`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md
git commit -m "feat(idea): add /idea orchestrator command

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `references/dependencies.md` (companions SSOT)

**Files:**
- Create: `plugins/dev-workflows/references/dependencies.md`

**Interfaces:**
- Consumes: nothing. Produces: a doc cross-linked from `commands/idea.md` (Phase 3) and the README (Task 7).

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
# dev-workflows — companion plugins & dependencies

dev-workflows is **self-contained**: no command hard-requires another plugin. There is **no
dependency-manifest field** in `.claude-plugin/plugin.json` (Claude Code plugins don't express one), so
every cross-plugin relationship is **convention + runtime-resolve + graceful fallback** — a missing
companion degrades the feature, never breaks the run.

## Recommended companions

| Companion | Used by | Relationship | Fallback when absent |
|-----------|---------|--------------|----------------------|
| `mattpocock-skills` (skill `/grilling`) | `/prompt-grill-me`; the embedded grilling technique in `/idea`, `/specify`, `/design` | Recommended | `/prompt-grill-me` runtime-resolves `/grilling`, else falls back to `superpowers:brainstorming`. The grilling *technique* is embedded in `/idea` / `/specify` / `/design`, so those have no runtime dependency. |
| `superpowers` (skill `brainstorming`) | `/prompt-brainstorm`; grilling fallback | Recommended | Embedded technique; no hard dependency. |
| `dt-style-guide` (in this marketplace) | `docs-style-checker`; planning-doc style checks | Optional companion | `docs-style-checker` falls back to it when no repo-configured prose linter exists; `/epics` and `/release-notes` skip the style gate entirely if it is absent. |

## Related external tooling (not a plugin)

| Tool | Role |
|------|------|
| [`jira-workitem-import`](https://github.com/ivan-gudak/jira-workitem-import) | Jira WorkItem Reporter — imports Jira tickets to `$VAULT_PATH/jira-products/` in the exact structure `jira-reader` (and every Jira-driven command) expects. The upstream producer of the pre-exported markdown tree the plugin consumes. |

## Marketplace siblings (independent plugins, same marketplace)

`dt-style-guide` and `obsidian-llm-wiki` ship in the `ihudak-plugins` marketplace alongside
dev-workflows but are versioned independently.
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/references/dependencies.md
grep -q "no.*dependency-manifest field" "$f" \
  && grep -q "convention + runtime-resolve + graceful fallback" "$f" \
  && grep -q "mattpocock-skills" "$f" && grep -q "superpowers" "$f" \
  && grep -q "dt-style-guide" "$f" && grep -q "jira-workitem-import" "$f" \
  && echo "OK dependencies"
```
Expected: `OK dependencies`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/dependencies.md
git commit -m "docs(deps): document companion plugins and external tooling

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Wire `/idea` into the shared subsystems (count + attribution)

**Files:**
- Modify: `plugins/dev-workflows/references/feedback-emission.md`
- Modify: `plugins/dev-workflows/references/cost-emission.md`

**Interfaces:**
- Consumes: the `/idea` command name (Task 3). Produces: correct command counts / attribution the command's Phase 6 relies on.

- [ ] **Step 1: feedback-emission.md — eight → nine (both spots)**

Edit line ~4 — change `all eight workflow` to `all nine workflow`:
> Original: `capture surface — the automatic maintenance phase of all eight workflow`
> New: `capture surface — the automatic maintenance phase of all nine workflow`

Edit line ~185 — change `the eight commands'` to `the nine commands'`:
> Original: `### \`emit-auto\` — automatic callers (the eight commands' maintenance phases)`
> New: `### \`emit-auto\` — automatic callers (the nine commands' maintenance phases)`

- [ ] **Step 2: cost-emission.md — header enumeration (add `/idea`)**

Edit line ~4 — add `/idea` to the front of the VI-lifecycle list:
> Original: ``"Session cost" phase of every VI-lifecycle command (`/specify`, `/epics`,``
> New: ``"Session cost" phase of every VI-lifecycle command (`/idea`, `/specify`, `/epics`,``

- [ ] **Step 3: cost-emission.md — §7 attribution table (promote the reserved row)**

Replace the single reserved row:
> Original: `| future idea-refine / create-VI | vi-creation | pm |`
> New (two rows):
> ```
> | `/idea` | vi-creation | pm |
> | future `/create-vi` | vi-creation | pm |
> ```

- [ ] **Step 4: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
fe=plugins/dev-workflows/references/feedback-emission.md
ce=plugins/dev-workflows/references/cost-emission.md
grep -q "all nine workflow" "$fe" \
  && grep -q "the nine commands'" "$fe" \
  && ! grep -q "all eight workflow" "$fe" && ! grep -q "the eight commands'" "$fe" \
  && grep -qF 'every VI-lifecycle command (`/idea`, `/specify`' "$ce" \
  && grep -qF '| `/idea` | vi-creation | pm |' "$ce" \
  && ! grep -qF '| future idea-refine / create-VI | vi-creation | pm |' "$ce" \
  && echo "OK subsystem wiring"
```
Expected: `OK subsystem wiring`

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/feedback-emission.md plugins/dev-workflows/references/cost-emission.md
git commit -m "chore(idea): wire /idea into feedback + cost subsystems

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Version bump + manifests + CHANGELOG

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (repo root)
- Modify: `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: all prior tasks (so the CHANGELOG describes shipped content). Produces: released v2.15.0.

- [ ] **Step 1: plugin.json — version**

Change `"version": "2.14.0"` → `"version": "2.15.0"`.

- [ ] **Step 2: plugin.json — description counts + lists**

In the `description` string make these three edits:
- `Sixteen slash commands` → `Seventeen slash commands`
- `/guideline-reviewer, /specify, /design,` → `/guideline-reviewer, /idea, /specify, /design,`
- `Twenty-six reusable subagents (risk-planner,` → `Twenty-seven reusable subagents (risk-planner,`
- `doc-location-finder, jira-reader, release-notes-writer,` → `doc-location-finder, jira-reader, idea-reader, release-notes-writer,`

- [ ] **Step 3: marketplace.json — mirror version + description (byte-identical)**

In the `dev-workflows` entry ONLY (do NOT touch `dt-style-guide` 0.2.2 / `obsidian-llm-wiki` 0.3.1):
- Change that entry's `"version": "2.14.0"` → `"version": "2.15.0"`.
- Apply the exact same four description edits as Step 2 so the `dev-workflows` `description` is **byte-identical** to `plugin.json`'s.

- [ ] **Step 4: CHANGELOG.md — prepend the 2.15.0 entry**

Insert directly above the `## [2.14.0] — 2026-07-10` line:

```markdown
## [2.15.0] — 2026-07-10

### Added

- **New `/idea` command — the front door of the VI-creation flow (PM phase).** `/idea <prompt | @file | JIRA-KEY> [--deep]` ingests one of four sources — an inline prompt, a markdown file (wikilinks + images followed), a community post, or an exported RFE Jira ticket — via a new read-only `idea-reader` subagent (Sonnet tier; auto-detects the source type with provenance tags, follows wikilinks one level, enumerates linked images by path, captures community-post demand signals). The Opus orchestrator then refines it through the embedded grilling technique — bounded by default (≤5 Impact×Uncertainty questions, one at a time, recommended answers; leftover gaps become `[NEEDS CLARIFICATION]` capped at 3 + logged Assumptions) or relentless under `--deep` — and writes a lean one-page `idea.md` (new `references/idea-format.md` is the SSOT) to the vault under `$VAULT_PATH/Projects/<area>/<slug>/`, keyless, `status: refined` iff zero open clarifications remain. `$VAULT_PATH` is validated (falls back to a user-supplied directory, never cwd). The grill is the quality gate (no reviewer agent at the idea stage). On finish it makes an adaptive next-phase offer toward the future `/create-vi`. Wired into the standard terminal tail: `impl-maintenance` + `emit-auto` feedback, `emit-cost` (`phase: vi-creation`, `role: pm`, keyless → pending ladder), and the capture-at-block invariant. A new `references/dependencies.md` documents the recommended companions (`mattpocock-skills` `/grilling`, `superpowers`, `dt-style-guide`) and the external `jira-workitem-import` importer, all convention + runtime-resolve + graceful fallback (no manifest field). `references/feedback-emission.md` (eight → nine commands) and `references/cost-emission.md` (VI-lifecycle enumeration + the `/idea` attribution row) are reconciled. The sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.
```

- [ ] **Step 4: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print(json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])" | grep -qx 2.15.0
python3 -c "import json;m=json.load(open('.claude-plugin/marketplace.json'))['plugins'];d={p['name']:p for p in m};assert d['dev-workflows']['version']=='2.15.0';assert d['dt-style-guide']['version']=='0.2.2';assert d['obsidian-llm-wiki']['version']=='0.3.1';assert d['dev-workflows']['description']==json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['description'],'descriptions differ';print('json+lockstep OK')"
grep -q "Seventeen slash commands" plugins/dev-workflows/.claude-plugin/plugin.json
grep -q "Twenty-seven reusable subagents" plugins/dev-workflows/.claude-plugin/plugin.json
grep -q "/idea, /specify" plugins/dev-workflows/.claude-plugin/plugin.json
grep -q "jira-reader, idea-reader" plugins/dev-workflows/.claude-plugin/plugin.json
head -12 plugins/dev-workflows/CHANGELOG.md | grep -q "## \[2.15.0\] — 2026-07-10"
echo "OK manifests+changelog"
```
Expected: `json+lockstep OK` then `OK manifests+changelog` (no assertion errors).

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(release): dev-workflows 2.15.0 (/idea command)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: README updates

**Files:**
- Modify: `plugins/dev-workflows/README.md`

**Interfaces:**
- Consumes: `/idea` (Task 3), `references/dependencies.md` (Task 4). Produces: human docs.

- [ ] **Step 1: Read the current anchors** (their surrounding text is dense — capture exact strings before editing)

```bash
cd /workspace/ihudak-claude-plugins
grep -n "Nine workflow slash commands" plugins/dev-workflows/README.md
grep -n "six VI-lifecycle commands" plugins/dev-workflows/README.md
grep -n "projects the plugin-facing slice" plugins/dev-workflows/README.md
grep -n "| \`/specify <VI-KEY" plugins/dev-workflows/README.md
```

- [ ] **Step 2: Lead sentence — bump count + add purpose**

Change `Nine workflow slash commands for structured implementation,` → `Ten workflow slash commands for idea refinement, structured implementation,` (line ~3).

- [ ] **Step 3: Command table — insert an `/idea` row**

Immediately **before** the `| \`/specify <VI-KEY …` row (the row captured in Step 1), insert this table row (single line):

```
| `/idea <prompt \| @file \| JIRA-KEY> [--deep]` | Idea refinement (PM phase, front of the VI-creation flow). Ingests one source — an inline **prompt**, a **markdown file** (wikilinks + images followed), a **community post**, or an exported **RFE Jira ticket** (`$VAULT_PATH/jira-products/<KEY>`) — via the read-only `idea-reader` subagent (auto-detects type with provenance tags). Refines it through the embedded one-question-at-a-time grill — **bounded** (≤5 questions; leftover gaps → `[NEEDS CLARIFICATION]` capped at 3 + logged Assumptions) or **relentless** with `--deep` — and writes a lean one-page `idea.md` (per `references/idea-format.md`) to `$VAULT_PATH/Projects/<area>/<slug>/`, keyless, `status: refined` iff zero open clarifications remain. The grill is the quality gate (no reviewer at the idea stage). Adaptive next-phase offer toward `/create-vi`. Never writes to Jira, code, or the specs repo. |
```

- [ ] **Step 4: Cost-phase count line — six → seven, add `/idea`**

Change `Terminal cost phase on the six VI-lifecycle commands (\`/specify\`, \`/epics\`,` → `Terminal cost phase on the seven VI-lifecycle commands (\`/idea\`, \`/specify\`, \`/epics\`,` (line ~72).

- [ ] **Step 5: Feedback-phase command list — add `/idea`**

In the feedback-phase enumeration around the line matched by `projects the plugin-facing slice` (Step 1), add `/idea` to the list of commands whose maintenance phase emits feedback (it precedes `/specify` in the enumeration, matching the command table order).

- [ ] **Step 6: Add a Dependencies section**

Append this section at the end of the README:

```markdown
## Dependencies & companions

dev-workflows is self-contained — no command hard-requires another plugin. Recommended companions
(`mattpocock-skills` `/grilling`, `superpowers`, `dt-style-guide`) and the external
[`jira-workitem-import`](https://github.com/ivan-gudak/jira-workitem-import) importer are documented in
[`references/dependencies.md`](references/dependencies.md); every relationship is convention +
runtime-resolve + graceful fallback.
```

- [ ] **Step 7: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
r=plugins/dev-workflows/README.md
grep -q "Ten workflow slash commands for idea refinement" "$r" \
  && grep -q "| \`/idea <prompt" "$r" \
  && grep -q "seven VI-lifecycle commands (\`/idea\`" "$r" \
  && grep -q "## Dependencies & companions" "$r" \
  && ! grep -q "Nine workflow slash commands" "$r" \
  && echo "OK readme"
```
Expected: `OK readme`

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/README.md
git commit -m "docs(readme): document /idea command and dependencies

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Whole-branch verification (after all tasks)

```bash
cd /workspace/ihudak-claude-plugins
# Siblings byte-identical to origin/main (untouched):
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki   # expect: no output
# Version lock-step + description parity already asserted in Task 6 Step 4; re-run:
python3 -c "import json;a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));m={p['name']:p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']};assert a['version']=='2.15.0'==m['dev-workflows']['version'];assert a['description']==m['dev-workflows']['description'];print('lockstep OK')"
# Full change surface:
git diff --stat main
```
Expected: no sibling diff; `lockstep OK`; the stat shows exactly the 4 new + 6 modified files.

Then finish via **superpowers:finishing-a-development-branch** (there are no tests to run — structural verification above is the gate): present merge/PR/keep/discard options; on merge, ff to `main`, push origin, delete branch.

---

## Self-Review (against the spec)

**Spec coverage:** Phase flow (Task 3) ✓; `idea-reader` contract (Task 2) ✓; `idea.md` artifact incl. `status` rule (Task 1 + Task 3 Phase 4) ✓; `$VAULT_PATH` validation + user-dir fallback (Task 3 Phase 0) ✓; Opus-orchestrator/Sonnet-reader routing (Task 3 Phase 0/2) ✓; bounded/`--deep` grill (Task 3 Phase 3) ✓; adaptive next-phase offer (Task 3 Phase 5) ✓; cost `vi-creation`/`pm` + feedback `emit-auto` + `emit-block` invariant (Task 3 Phase 6, Task 5) ✓; `references/dependencies.md` incl. `jira-workitem-import` (Task 4) ✓; count reconciliations (Task 5) ✓; v2.15.0 lock-step + siblings untouched + CHANGELOG (Task 6) ✓; README (Task 7) ✓. **Carry-forwards to `/create-vi`** and the **v2.16.0 next-phase-offer** and **`.obsidian` revisit** follow-ups are recorded in the spec — not built here (correctly out of scope).

**Placeholder scan:** none — every new file's full content is inline; every edit gives exact old→new strings.

**Type consistency:** `idea-reader` output keys (Task 2) exactly match the keys `commands/idea.md` reads (Task 3 Phase 2); `idea-format.md` frontmatter/section names (Task 1) match the Phase 4 authoring references; `phase: vi-creation` / `role: pm` match `cost-emission.md` §7 (Task 5).

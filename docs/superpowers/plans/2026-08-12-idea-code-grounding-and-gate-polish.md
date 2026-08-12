# `/idea` code grounding + choice-gate polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `/idea` an opt-in `--ground-code` fan-out with a seeded second round and a home for its findings, and settle plugin-wide when a `choices:` list fires.

**Architecture:** Two independent strands sharing one command. Strand A adds a new `/idea` Phase 2.6 that dispatches the existing `code-scanner` agent (no new agent), a new `model-routing` §8.5 describing the broad-then-narrow shape, an optional `lines[]` field on `code-scanner`'s evidence, and a new optional Section 7 in `idea-format.md`. Strand B adds a third binding rule to `references/escalation-rules.md`, fixes one shared escalation list whose options never matched its trigger, and applies the rule at the two sites that need it.

**Tech Stack:** Prompt markdown only. **No build, no runtime, no test framework.** Verification is `grep`/`awk`/`diff`/reading. Every count below is whitespace-normalised.

**Spec:** `docs/superpowers/specs/2026-08-12-idea-code-grounding-and-gate-polish-design.md` (46 requirements, `R1`–`R39` plus `R9a`/`R9b`/`R9c`, `R15a`, `R20a`/`R20b`, `R26a`).

## Global Constraints

- **Three repos.** `/workspace/ihudak-claude-plugins` (canonical), `/workspace/mgd-claude-plugins` (content-verbatim except its identity files), `/workspace/ihudak-copilot-plugins` (adapted dialect, own version track). All three are already on branch `iv-gu/idea-code-grounding`, forked from `iv-gu/vault-prior-art` — **not** from `main`.
- **Versions:** dev-workflows **2.49.0** canonical + mgd; **2.19.0** copilot.
- **Never `cp` into copilot.** It carries genuinely different *content*, not just dialect (no `emit-cost` step, no `cost-emission.md`). Every copilot edit is written by hand, then diffed against canonical for intent — never for text.
- **Copilot dialect — all four rules:**
  1. `→ Agent (subagent_type: "dev-workflows:X"` → `→ task(agent_type: "X"`
  2. `${CLAUDE_PLUGIN_ROOT}/references/X.md` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/X.md`
  3. `§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5` → `§2.1 detection chain: claude-sonnet-4.6, fallback claude-sonnet-4.5/gpt-5.4`
  4. **Command names are colon-form** (`idea:`, `implement:`) — never slash-form (`/idea`).
- **Copilot layout:** commands live at `dev-workflows/skills/<name>/SKILL.md`; shared references at `dev-workflows/skills/_shared/<name>.md` with **`model-routing.md` flattened** (not `model-routing/classification.md`); handoffs at `dev-workflows/skills/_shared/handoff/`; agents at `dev-workflows/agents/`.
- **Line wrapping: match the immediate neighbourhood.** These files are mixed — older paragraphs wrap near 100 columns, newer ones are single unbroken lines. Copy the style of the paragraphs you are inserting beside. Do not reflow anything you were not asked to change.
- **Choice lists are presented verbatim** (`references/escalation-rules.md`) — options, order, and the `(Recommended)` marker are fixed text, never templated with per-run values.
- **Every option in a shown list must name something that exists.** A row that can be absent is the unreachable-guard defect this project has shipped five times. Enumerate the state space; do not reason case-by-case.
- **The residue question is the standing one:** not "did my rule land everywhere" but **"what did I make false?"** Every statement about `/idea`'s phase list, its grounding sources, `idea-format.md`'s section count, and `code-scanner`'s output contract, in all three repos.
- **A `# expect N` that does not match reality is the plan's bug, not yours.** These counts were computed against the tree when the plan was written and go stale as tasks land. If a check disagrees with what you actually see, **stop and report the mismatch** rather than editing files to satisfy the number. Implementers who flagged one were right 6 times out of 6.

---

## File structure

| File | Responsibility after this plan | Task |
|---|---|---|
| `references/escalation-rules.md` | owns three plugin-wide choice-list rules (verbatim, marker, **firing**) + the per-scenario catalogue, with a `Repo missing` list that fits its trigger | 1 |
| `references/idea-format.md` | 9 sections; Section 7 is the new optional `## Feasibility grounding`; Section 5 is demand-only by explicit rule | 2 |
| `references/model-routing/classification.md` | §8 gains §8.5, the opt-in broad-then-narrow procedure | 3 |
| `references/handoff/code-scanner.md`, `agents/code-scanner.md` | evidence entries may carry `lines[]` | 4 |
| `commands/idea.md` | Phase 0 classification note, Phase 1 conditional confirmation, **new Phase 2.6**, Phase 3/4/5 consumption | 5, 6, 7 |
| `commands/implement.md` | Phase 1.7 escalates every scanner status through a named list | 8 |
| other `commands/*.md` | whatever the R7 sweep finds | 9 |
| `README.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`, `/CLAUDE.md` | 2.49.0, `/idea` usage + code-grounding paragraph, workflow map | 10 |

---

### Task 1: `escalation-rules.md` — the firing rule and the mis-fitted list

**Files:**
- Modify: `plugins/dev-workflows/references/escalation-rules.md`

**Interfaces:**
- Produces: a section titled exactly `## When a choice list fires`, cited by later tasks as ``${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`` + the section name.
- Produces: the replaced `## Repo missing (after resolution)` list, consumed by Tasks 6 and 8.

- [ ] **Step 1: Insert the firing rule**

Insert **after** the section `## The `(Recommended)` marker is unconditional` (it ends with the line `This rule binds every command in the plugin, not only the ones documented below.`) and **before** `## Jira key dir not found`. Verbatim:

````markdown
## When a choice list fires

**A choice list blocks whenever it is shown.** Presenting one and continuing without an answer is never
correct — the list *is* the wait.

**A list is shown only when its firing condition holds.** A list with no written condition is shown
every time its phase runs. That is the default, and it is the right default for most phases.

**A list written for a question whose answer is already determined is a defect**, not a formality — it
spends a user turn on a prompt with one plausible answer. Where the answer is determined on some runs
and open on others, write the firing condition and keep the list for the runs where it is open.

**The inline-confirmation form.** When the answer is determined, state the resolution in one line that
names what was resolved and how to correct it, then proceed without waiting:

```
Reading this as a <type> — say so if it's actually a <other-type>.
```

An inline confirmation is **not** a choice list: it carries no `choices:` array, it never waits, and the
run continues on the stated resolution. It is the correct form wherever a phase would otherwise ask a
question with one plausible answer.

This rule governs only *whether* a list is presented. Option wording, option order, and the
`(Recommended)` marker are governed by the two rules above and are untouched by it.

This rule binds every command in the plugin, not only the ones documented below.
````

- [ ] **Step 2: Replace the `Repo missing (after resolution)` list**

Find the section `## Repo missing (after resolution)`. Its current body is:

```
`choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]`

Used when a diff-summarizer or code-scanner batch returns `REPO_MISSING` at
Phase 5, after Phase 4 already checked. Present this choice per affected repo.
```

That list is byte-identical to `## Dirty working tree` above it and cannot help its own trigger — there is nothing to stash and nothing to retry when a repo is absent. Replace the whole body with:

```
`choices: ["Skip this repo", "I'll clone it — wait", "Specify a different absolute path for this repo", "Cancel", "Other… (describe)"]`

Used when a diff-summarizer or code-scanner batch returns `REPO_MISSING` at
Phase 5 after Phase 4 already checked, and in `/idea` Phase 2.6, which has no
earlier check. `REPO_MISSING` means `repo_path` is not a directory **or** the
clone's `origin` slug does not match `repo_url_slug`; *Specify a different
absolute path for this repo* is the option that resolves the second case, which
the previous list had no answer for at all. Present this choice per affected
repo. No `(Recommended)` marker — which option is right depends entirely on why
the repo is absent.
```

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# expect 1
grep -c '^## When a choice list fires$' references/escalation-rules.md
# expect 3 — the three plugin-wide binding rules
grep -c 'This rule binds every command in the plugin' references/escalation-rules.md
# expect 0 — the Repo-missing list no longer duplicates the Dirty-tree list
grep -A1 '^## Repo missing (after resolution)$' references/escalation-rules.md | grep -c 'Stash changes'
# expect 5 — the commands citing the rule by name, all still resolving
# (/create-ard, /document, /epics, /release-notes, /specify; /implement joins them in Task 8)
grep -rl 'Repo missing (after resolution)' commands/ | wc -l
```

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/escalation-rules.md
git commit -m "feat(dev-workflows): when a choice list fires + a Repo-missing list that fits its trigger"
```

---

### Task 2: `idea-format.md` — Section 7 `## Feasibility grounding`

**Files:**
- Modify: `plugins/dev-workflows/references/idea-format.md`

**Interfaces:**
- Consumes: nothing.
- Produces: `## Feasibility grounding` as **Section 7**; `## Open questions & assumptions` becomes Section 8; `## Candidate success signal` becomes Section 9. Task 7 writes `/idea` Phase 4 against these numbers.

- [ ] **Step 1: Add the closing rule to Section 5**

`## Section 5 — Signals & evidence` currently ends with `Cite sources; never fabricate.` Append a new paragraph directly beneath it:

```markdown
**Code findings never go here.** This section is *demand* evidence only. Feasibility findings from a
`--ground-code` run — what the code already does, what is missing, and any reframing they force —
belong in **Feasibility grounding** (Section 7).
```

- [ ] **Step 2: Insert Section 7**

Insert between the end of `## Section 6 — Prior art (optional)` and the current `## Section 7 — Open questions & assumptions`:

```markdown
## Section 7 — Feasibility grounding (optional)

`## Feasibility grounding` — what the code says today about whether this idea is needed and how large it
is. **Write it when code grounding ran *and* returned at least one finding; omit it entirely
otherwise** — a grounded run that found nothing writes no empty section and no "nothing found" line.

The section opens with what its claims were true of: one line naming each grounded repo as
`<repo>@<scanned_ref>`, taken from `code-scanner`'s `prep.scanned_ref`. Code moves; a finding with no ref
is unfalsifiable a month later.

Then up to three slots, each optional and each omitted when empty:

- **What exists** — capability present in the code today.
- **What's missing** — the gap, characterised.
- **Reframing** — ONE line, written only when a finding contradicted the idea's premise: the framing the
  source implied, and the framing the code supports.

Every bullet carries a repo-qualified citation `<repo>/<path>:<line>` — the **first** entry of that
evidence's `lines` — or `<repo>/<path>` when the evidence entry has no `lines`. **A bullet with no
citation is not written**: a feasibility claim with no anchor is exactly what this section exists to
prevent.

Nothing speculative goes here. A theme the scan could not resolve is a `[NEEDS CLARIFICATION]` in
**Open questions & assumptions** (Section 8), never a hedged bullet here.
```

- [ ] **Step 3: Renumber the two sections below it**

- `## Section 7 — Open questions & assumptions` → `## Section 8 — Open questions & assumptions`
- `## Section 8 — Candidate success signal` → `## Section 9 — Candidate success signal`

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# expect exactly: 1 2 3 4 5 6 7 8 9
grep -o '^## Section [0-9]*' references/idea-format.md | awk '{printf "%s ", $3} END {print ""}'
# expect 0 — no duplicate section numbers
grep -o '^## Section [0-9]*' references/idea-format.md | sort | uniq -d | wc -l
# expect 0 — nothing anywhere in the plugin cites an idea-format section by the old number
grep -rn 'idea-format' --include=*.md . | grep -c 'Section [789]'
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/idea-format.md
git commit -m "feat(dev-workflows): idea.md gets a home for feasibility findings"
```

---

### Task 3: `model-routing` §8.5 — broad, then narrow

**Files:**
- Modify: `plugins/dev-workflows/references/model-routing/classification.md`

**Interfaces:**
- Produces: `### 8.5 Broad, then narrow (the seeded second round)`, cited by Task 6 as `§8.5`.

- [ ] **Step 1: Insert §8.5**

Insert after `### 8.4 Honesty` and its paragraph, immediately before the `---` that opens `## 9. Per-step routing for multi-phase authoring pipelines`:

```markdown
### 8.5 Broad, then narrow (the seeded second round)

A broad prompt lets each scanner defer to the layer it did not scan. Round 1
asks every repo the same wide question, and a capability spanning two layers can
come back attributed to the *other* layer by both scanners — a pair of confident
answers that together say nothing. Naming a verified anchor removes the escape.

**Round 1** is the §8.2 fan-out unchanged: one `code-scanner` per repository,
broad themes, single response, cap 4 concurrent.

**Inconclusive** describes a round-1 theme whose `classification` is `partial`,
`absent`, or `error`, **or** for which two scanners' `gap_summary` texts each
name the *other's* repo or layer as the likely location.

**Round 2** fires for an inconclusive theme when round 1 produced at least one
evidence anchor to seed from. It dispatches the **same** `code-scanner` agent
with a narrowed brief:

- `capability_themes` holds exactly **one** question — not the broad theme, but
  the single thing round 1 failed to settle;
- `search_hints.paths` / `.symbols` / `.keywords` are seeded from round 1's
  verified `evidence[].path`, `.symbols`, and `.lines`.

No new agent and no input-contract change: the narrowing lives entirely in what
the caller puts in the existing fields.

**Bounds.** Round 2 is capped at **4 dispatches** and is **one round only**.
There is no round 3. A theme still inconclusive after round 2 is reported
unresolved — never guessed at.

**Opt-in.** §8.5 is a shared procedure a caller adopts by saying so in its own
body. `/idea` (Phase 2.6) is its first and only current consumer. `/implement`,
`/epics`, `/create-ard`, `/specify`, and `/design` run §8.2 alone and are
unaffected by this section.
```

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# expect 1
grep -c '^### 8.5 Broad, then narrow' references/model-routing/classification.md
# expect 8.1 8.2 8.3 8.4 8.5 in order
grep -o '^### 8\.[0-9]' references/model-routing/classification.md | awk '{printf "%s ", $2} END {print ""}'
# expect §8.5 to sit before section 9
awk '/^### 8.5/{a=NR} /^## 9\./{b=NR} END {print (a<b && a>0) ? "OK" : "MISPLACED"}' references/model-routing/classification.md
```

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/model-routing/classification.md
git commit -m "feat(dev-workflows): model-routing 8.5 — the seeded second scan round"
```

---

### Task 4: `code-scanner` evidence gains `lines[]`

**Files:**
- Modify: `plugins/dev-workflows/references/handoff/code-scanner.md`
- Modify: `plugins/dev-workflows/agents/code-scanner.md`

**Interfaces:**
- Produces: an optional `lines: [<n>]` on each `capability_map[].evidence[]` entry. Task 2's citation format and Task 6's round-2 seeding both read it. The other four callers (`/epics`, `/implement`, `/create-ard`, `/specify`, `/design`) are **not** edited and ignore it.

- [ ] **Step 1: Extend the output contract**

In `references/handoff/code-scanner.md`, the `## Output` YAML block currently reads:

```yaml
    evidence:
      - path:    <file path relative to repo root>
        symbols: [<class/function names found>]
        note:    <one-line characterisation of what this file provides>
```

Replace with:

```yaml
    evidence:
      - path:    <file path relative to repo root>
        lines:   [<1-based line numbers>]   # optional — present when the match came from a grep hit
        symbols: [<class/function names found>]
        note:    <one-line characterisation of what this file provides>
```

- [ ] **Step 2: Extend the prose beneath the block**

The paragraph after the YAML block currently begins `prep.read_only`, `prep.scanned_ref`, … and ends `See ${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md.` Append one sentence to that paragraph:

```
`evidence.lines` is optional — present when the entry came from a grep hit, absent for a path glob or a whole-file read — and is meaningful only together with `scanned_ref`, because a line number moves with the ref it was read at.
```

- [ ] **Step 3: Teach the agent to populate it**

In `agents/code-scanner.md`, step 3 (**Scan**) has a bullet reading `Collect file paths and top-level symbols (class names, function names, exported identifiers) that match.` Add a bullet directly beneath it:

```
   - Record the 1-based line numbers of grep hits in that evidence entry's `lines` — both the `Grep`
     tool and `git grep -n <ref>` return them, so no extra command is needed. Leave `lines` **absent**
     for an entry found by a path glob or a whole-file read; never invent a line number.
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# expect 1 each
grep -c 'lines:   \[<1-based line numbers>\]' references/handoff/code-scanner.md
grep -c 'evidence.lines. is optional' references/handoff/code-scanner.md
grep -c 'Record the 1-based line numbers' agents/code-scanner.md
# expect 0 — no other caller was edited
cd /workspace/ihudak-claude-plugins && git diff --name-only HEAD -- plugins/dev-workflows/commands/ | wc -l
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/handoff/code-scanner.md plugins/dev-workflows/agents/code-scanner.md
git commit -m "feat(dev-workflows): code-scanner evidence may carry line numbers"
```

---

### Task 5: `/idea` Phase 0 + Phase 1 — the flag and the conditional confirmation

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (the `Flags:` paragraph, Phase 0, Phase 1)

**Interfaces:**
- Consumes: Task 1's `## When a choice list fires`.
- Produces: the stripped `--ground-code` value, read by Task 6's Phase 2.6.

- [ ] **Step 1: Add the flag to the `Flags:` paragraph**

It currently reads:

```
Flags: `--deep` switches the grill from bounded (≤5 questions) to relentless (until convergence).
`--no-docs` and `--no-prior-art` each turn off one grounding source (see Phase 1).
```

Append one sentence to that paragraph:

```
`--ground-code [<repo>[,<repo>…]]` grounds the idea against mounted code (see Phase 2.6) — bare it derives the repo set, with a value it scans exactly those repos.
```

- [ ] **Step 2: Add the classification note to Phase 0**

Phase 0 step 2's paragraph after the `model_routing` YAML block begins `The grill + authoring run inline on `current_model`…`. Append to that paragraph:

```
A `--ground-code` run does **not** floor the classification at `SIGNIFICANT`: §1.1's multi-source floor is written for `/implement`, and §8.3's purpose — the strongest available model on synthesis — is already met here, because the grill and authoring run inline on `current_model` while the scanners run on `detection_model`.
```

- [ ] **Step 3: Strip the new flag before classifying**

Phase 1's opening sentence currently reads:

```
Classify `$ARGUMENTS` **minus every recognised flag** (`--deep`, `--no-docs`, `--no-prior-art`, and `--docs <path>` with its value) by precedence.
```

Replace the parenthetical:

```
Classify `$ARGUMENTS` **minus every recognised flag** (`--deep`, `--no-docs`, `--no-prior-art`, `--docs <path>` with its value, and `--ground-code` with its optional comma-separated repo value) by precedence.
```

The sentence that follows — about an unstripped flag landing inside the `prompt` branch's raw idea text — stays as it is and now covers five flags.

- [ ] **Step 4: Replace the unconditional confirmation**

Phase 1 currently ends with:

```
Surface a one-line confirmation before ingesting:
```
choices: ["Read this as <detected-type> (Recommended)", "It's actually a <other-type>", "Cancel", "Other… (describe)"]
```
(A dedicated `--as prompt|markdown|rfe|vi` override is future work — the confirmation covers a mis-detection.)
```

Replace that whole block with:

````markdown
**Confirm the classification — conditionally.** Per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` ("When a choice list fires"), a list is shown only where the answer genuinely varies. Two cases here do; the rest do not.

**A — the key resolved but its `issue_type` is neither `ValueIncrement` nor `Product Need`.** Name the actual `issue_type` in prose beside the list, never inside an option:
```
choices: ["Read this as a vi — an existing Value Increment (Recommended)", "Read this as an rfe — product feedback", "Cancel", "Other… (describe)"]
```

**B — the argument is path-like (contains `/`, ends in `.md`, or starts with `@`) but resolved to no existing file.** Without this gate it falls through precedence rule 3 to **prompt** and the path string itself becomes the raw idea text — a mistyped path silently ingested as prose:
```
choices: ["Re-enter the path (Recommended)", "Read the argument as a prompt — the literal text is the idea", "Cancel", "Other… (describe)"]
```

**Everything else** — a `.md` path or `@wikilink` that resolves, a key typed `ValueIncrement` or `Product Need`, and plain prose — is unambiguous. State the resolution in one line that invites correction and **proceed without waiting**; the list would have one plausible answer. (A dedicated `--as prompt|markdown|rfe|vi` override is future work — this inline confirmation covers a mis-detection.)
````

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# expect 2 — the two conditional lists, no unconditional one
awk '/^## Phase 1/,/^## Phase 2 /' commands/idea.md | grep -c 'choices:'
# expect 3 — Flags paragraph, Phase 0 note, Phase 1 strip list (was 0 before this task).
# Rises in Tasks 6-7; the README site is Task 10.
grep -c 'ground-code' commands/idea.md
# expect 1 each
awk '/^Flags:/,/^---/' commands/idea.md | grep -c 'ground-code'
awk '/^## Phase 1/,/^## Phase 2 /' commands/idea.md | grep -c 'ground-code'
# expect 1 — the firing rule is cited where the gate became conditional
awk '/^## Phase 1/,/^## Phase 2 /' commands/idea.md | grep -c 'When a choice list fires'
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md
git commit -m "feat(dev-workflows): /idea Phase 1 asks only when the answer varies"
```

---

### Task 6: `/idea` Phase 2.6 — code grounding

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (insert a new phase between Phase 2.5 and Phase 3)

**Interfaces:**
- Consumes: Task 1's `Repo missing (after resolution)` list; Task 3's §8.5; Task 4's `evidence[].lines`; Task 5's stripped `--ground-code` value.
- Produces: the digest Task 7 consumes — per-repo `capability_map` entries with `prep.scanned_ref`, the list of grounded repos, the list of descoped/unmounted repos, and any theme still inconclusive after round 2.

**Do not touch Phase 2.5.** Its two-way parallel dispatch is deliberate and is left byte-identical.

- [ ] **Step 1: Insert the phase**

Insert after Phase 2.5's closing paragraph and its `---`, before `## Phase 3 — Refine via grill`:

````markdown
## Phase 2.6 — Code grounding (optional)

Runs only when `--ground-code` was given; otherwise take the OFF branch at the end of this phase. Kept separate from Phase 2.5 because the repo gate needs a user answer (which cannot happen inside a parallel dispatch) and because the scan is two-round and therefore sequential.

**1. Resolve the repo set.** With `--ground-code <repo>[,<repo>…]`, use exactly those repos and skip to step 2. Bare, derive them:

- **Cheap discovery.** List the top-level directories under each `${REPOS_PATH:-/workspace}` entry (may be colon-separated) with `ls`. Optionally attach each directory's one-line identity — `timeout 5 git -C <dir> remote get-url origin 2>/dev/null` (slug) or its README's first heading. Do **not** deep-scan to guess relevance.
- **Propose** a candidate set from the `idea-reader` digest's themes.
- **Gate** — this list's answer varies every run, so it fires unconditionally:
  ```
  choices: ["Ground the proposed set (Recommended)", "Ground a different set (you'll be prompted)", "Ground nothing — continue without a code scan", "Cancel", "Other… (describe)"]
  ```
- **Empty proposal — do not show that list.** When no theme matches any mounted repo its first option names a set that does not exist. Escalate instead per the `No repos derivable — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. Every option in a shown list must name something that exists.

Validate each resolved path is a directory; a repo that is not mounted is handled by the `Repo missing (after resolution)` rule in the same file — never invented, never silently dropped. A repo the user drops is carried to Phase 5 by name, with the themes it would have grounded left unverified.

**2. Round 1 — broad.** Spawn `code-scanner` on the confirmed set in **batches of up to 4 concurrent agents per Agent message**, on `detection_model` per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §8.3. For each repo in the batch:

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:        <resolved absolute path>
  > capability_themes: <the idea's themes from the idea-reader digest>
  > context:          <3–5 sentences: the idea's problem + desired outcome, and what a finding would change>
  > search_hints:     <symbols/paths/keywords derived from the idea, if any>"

Handle every returned status through the list `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` already carries for it — `REPO_MISSING` → *Repo missing (after resolution)*; `DIRTY_TREE` → *Dirty working tree*; `REFRESH_BLOCKED` → *Refresh blocked*. `prep.read_only: true` is **not** a failure: the scan ran at `prep.scanned_ref`; escalate per *Read-only mount — ref stale or diverged* **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`, and cite evidence at `prep.scanned_ref` either way.

**3. Round 2 — narrow.** Apply §8.5 of the model-routing reference: for each theme round 1 left **inconclusive** (`classification` `partial` / `absent` / `error`, or two scanners' `gap_summary` texts each naming the other's repo or layer), and for which round 1 produced at least one evidence anchor, dispatch `code-scanner` again with `capability_themes` holding exactly **one** question and `search_hints` seeded from that round's verified `evidence[].path`, `.symbols`, and `.lines`. Cap **4 dispatches, one round only** — there is no round 3, and a theme still inconclusive is carried to Phase 4 as a `[NEEDS CLARIFICATION]`, never guessed at.

**OFF branch** (no `--ground-code`). Run one detection and print at most one line. Tokenise the raw argument and the digest's `raw_context`; match tokens case-insensitively against the basenames of the **git repositories** (a `.git` entry present) directly under each `${REPOS_PATH:-/workspace}` entry, excluding `$DOCS_PATH`, `$SPECS_PATH`, and `$VAULT_PATH`. Exact token match only — no substring, no stemming. On ≥1 match print:

```
This idea names <repo>; re-run with --ground-code to verify it against the code.
```

and **proceed without waiting** — an inline confirmation per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` ("When a choice list fires"), not a gate. No match ⇒ silent. There is no auto-trigger: grounding is up to eight scanner dispatches and starts only on the user's explicit flag.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# expect 1
grep -c '^## Phase 2.6 — Code grounding (optional)$' commands/idea.md
# expect the phase to sit between 2.5 and 3
grep -n '^## Phase' commands/idea.md
# expect 1 — the repo gate and nothing else. The empty-proposal case and all four
# scanner statuses escalate on named rules in escalation-rules.md, so they contribute
# no inline array. (This value read "2" when the plan was written; it was wrong.)
awk '/^## Phase 2.6/,/^## Phase 3/' commands/idea.md | grep -c 'choices:'
# expect 4 — every scanner status named
for s in REPO_MISSING DIRTY_TREE REFRESH_BLOCKED read_only; do
  printf "%-18s %s\n" "$s" "$(awk '/^## Phase 2.6/,/^## Phase 3/' commands/idea.md | grep -c "$s")"
done
# expect 0 — Phase 2.5 untouched: no deleted line anywhere inside it
git -C /workspace/ihudak-claude-plugins diff HEAD -- plugins/dev-workflows/commands/idea.md \
  | grep '^-' | grep -c 'dispatch-docs-grounder\|dispatch-prior-art-finder\|single response'
```

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md
git commit -m "feat(dev-workflows): /idea Phase 2.6 — opt-in code grounding, broad then narrow"
```

---

### Task 7: `/idea` Phases 3–5 — consume the findings

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (Phase 3, Phase 4, Phase 5, Final report)

**Interfaces:**
- Consumes: Task 6's digest; Task 2's Section 7 rules.

- [ ] **Step 1: Phase 3 — facts, not questions**

Phase 3's paragraph beginning `Scan for gaps against an idea-stage **ambiguity taxonomy**…` ends with the sentence `Challenges **compete** for the slots below; they never add slots.` Append:

```
**Code findings are facts, not questions.** A Phase 2.6 finding answers a gap rather than raising one — look it up, cite it, and do not spend a question on it. The one exception is the finding that **contradicts the idea's premise** (the capability already exists, or the gap is far smaller than the idea assumes): that becomes a challenge ranked into the same Impact × Uncertainty list, competing for a slot exactly like a `docs_challenges` or `prior_art_challenges` entry and never adding one. At most **2** such challenges.
```

- [ ] **Step 2: Phase 4 — write Section 7**

Phase 4's bullet list currently ends with the `**status:**` bullet. Insert a new bullet directly **before** the `**Existing file:**` bullet:

```
- **`## Feasibility grounding`:** write the section per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` when Phase 2.6 ran **and** returned at least one finding; omit it entirely otherwise. Head it with each grounded repo as `<repo>@<scanned_ref>`; give every bullet a repo-qualified `<repo>/<path>:<line>` citation (the first entry of that evidence's `lines`, or `<repo>/<path>` when it has none); write a **Reframing** line only when a finding contradicted the idea's premise. A theme still inconclusive after round 2 becomes a `[NEEDS CLARIFICATION]` in **Open questions & assumptions**, never a hedged bullet.
```

- [ ] **Step 3: Phase 5 + Final report**

Phase 5's paragraph beginning `Also report any prior art found…` ends `…so the user can relocate before `/create-vi` makes the path sticky.` Append a new paragraph:

```
Also report the code grounding when Phase 2.6 ran: the grounded repos with their `scanned_ref`s, any repo descoped or unmounted with the themes left unverified, any theme still inconclusive after round 2, and — first, because it is the most consequential thing a run can produce — the **Reframing** line if one was written. A reframing that changed the idea's Problem section must not be reported only inside the file.
```

In the **Final report** list, insert after `the resolved `vi_disposition`;`:

```
the grounded repos with their `scanned_ref`s and any descoped or inconclusive ones (or "code grounding: off");
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# expect 1 each
awk '/^## Phase 3/,/^## Phase 4/' commands/idea.md | grep -c 'facts, not questions'
awk '/^## Phase 4/,/^## Phase 5/' commands/idea.md | grep -c 'Feasibility grounding'
awk '/^## Phase 5/,/^### Context hygiene/' commands/idea.md | grep -c 'scanned_ref'
awk '/^## Final report/,0' commands/idea.md | grep -c 'code grounding: off'
# expect 6 — Phase 4's write-path gate is unchanged (G's assembled gate, rows 1-6)
awk '/^## Phase 4/,/^## Phase 5/' commands/idea.md | grep -c '^  | [0-9] |'
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md
git commit -m "feat(dev-workflows): /idea consumes code findings as facts and writes them down"
```

---

### Task 8: `/implement` Phase 1.7 — escalate through named lists

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (Phase 1.7, step 3's closing paragraph)

**Interfaces:**
- Consumes: Task 1's fixed `Repo missing (after resolution)` list.
- Produces: nothing. **This is `/implement`'s only edit in this sub-project** — it does not adopt §8.5.

- [ ] **Step 1: Replace the surface-only sentence**

Phase 1.7 step 3 ends with a paragraph beginning `Wait for all scanners in the batch to return.` Its second sentence currently reads:

```
A scanner returning `DIRTY_TREE`/`REFRESH_BLOCKED` is surfaced, not hidden.
```

Replace that one sentence with:

```
A scanner returning `REPO_MISSING` — the path is not a directory, or the clone's `origin` slug does not match `repo_url_slug` — escalates per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`; `DIRTY_TREE` escalates per the `Dirty working tree` rule and `REFRESH_BLOCKED` per the `Refresh blocked` rule in the same file. None is ever hidden, and none is merely announced — each offers the user a way forward (§8.4).
```

The `prep.read_only` sentence that follows is already correct and is **not** touched.

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# expect 1 each
awk '/^## Phase 1.7/,/^## Phase 1.8/' commands/implement.md | grep -c 'REPO_MISSING'
awk '/^## Phase 1.7/,/^## Phase 1.8/' commands/implement.md | grep -c 'Repo missing (after resolution)'
# expect 0 — the surface-only promise is gone
grep -c 'is surfaced, not hidden' commands/implement.md
# expect 0 — /implement did NOT adopt 8.5
grep -c '8\.5' commands/implement.md
```

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/implement.md
git commit -m "fix(dev-workflows): /implement's scanner failures offer a way forward"
```

---

### Task 9: The targeted sweep (R7–R9)

**Files:**
- Modify: zero or more of `plugins/dev-workflows/commands/*.md` — whatever the sweep finds
- Create: `docs/superpowers/plans/2026-08-12-choice-gate-sweep.md` (the recorded finding list)

**Interfaces:**
- Consumes: Task 1's firing rule.

The goal is **not** to label 188 choice lists. Task 1's rule supplies the default for all of them. This sweep looks only for lists whose *written* default is wrong — the vacuous confirmation shape `/idea` Phase 1 had.

- [ ] **Step 1: Run the detector**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in commands/*.md; do
  grep -n -B4 'choices:' "$f" \
    | grep -iE 'confirm|confirmation' \
    | grep -viE '\bif\b|\bwhen\b|\bunless\b|\bon [A-Za-z_`]' \
    | sed "s|^|${f}: |"
done
```

- [ ] **Step 2: Read each hit and classify it**

For every hit, read the surrounding phase and answer one question: **across the runs that reach this list, does the answer ever vary?**

- **Varies** → leave it exactly as it is. Do **not** annotate it; Task 1's default already covers it, and annotating correct sites is the labelling job the spec rejected.
- **Determined** → fix it the way `/idea` Phase 1 was fixed: either name the firing condition above the list, or convert it to the inline-confirmation form (one line, invites correction, proceeds without waiting) and cite `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` ("When a choice list fires").

- [ ] **Step 3: Record the finding list**

Write `docs/superpowers/plans/2026-08-12-choice-gate-sweep.md` with one row per hit: file, line, phase, verdict (`varies` / `determined`), and — for `determined` — what was changed. **If the sweep finds nothing beyond `/idea`, write that down as the outcome.** That is an honest result, not a failure: the rule still has a consumer in `/idea` Phase 1, so it is not a dead gate.

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
# expect: the sweep record exists and names every hit the detector produced
test -f docs/superpowers/plans/2026-08-12-choice-gate-sweep.md && echo OK
# expect 191 by the time this task runs, minus any list it converts to an inline
# confirmation. 188 was the count at the branch base; the branch legitimately adds
# three matches before this task: Phase 1's one unconditional list became two
# conditional ones (+1), Phase 2.6's repo gate (+1), and the new firing rule's own
# prose — "it carries no `choices:` array" — which grep counts but is not a gate (+1).
# (This value read "188 minus…" when the plan was written; it ignored the branch's
# own additions.)
grep -rh 'choices:' plugins/dev-workflows/commands plugins/dev-workflows/references | wc -l
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add -A docs/superpowers/plans/2026-08-12-choice-gate-sweep.md plugins/dev-workflows/commands/
git commit -m "chore(dev-workflows): sweep for choice lists whose answer never varies"
```

---

### Task 10: Canonical docs + version 2.49.0

**Files:**
- Modify: `plugins/dev-workflows/README.md`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/.claude-plugin/plugin.json`, `CLAUDE.md` (repo root)

- [ ] **Step 1: README — the `/idea` row**

Its first cell currently reads `` `/idea <prompt \| @file \| JIRA-KEY> [--deep]` ``. Replace with:

```
`/idea <prompt \| @file \| JIRA-KEY> [--deep] [--ground-code [<repo>,…]] [--no-docs] [--no-prior-art]`
```

In the same row's description, after the sentence about vault prior art, add:

```
With `--ground-code` it also grounds against mounted code — a `code-scanner` fan-out (cap 4) followed by a seeded narrow round per `references/model-routing/classification.md` §8.5 — writing what it finds to an optional `## Feasibility grounding` section with `file:line` citations. Off by default; a run that names a mounted repo gets one line suggesting the flag, never a prompt.
```

- [ ] **Step 2: README — a third grounding paragraph**

After the **Vault prior-art grounding (`$VAULT_PATH`)** paragraph, add:

```
**Code grounding (`--ground-code`, `/idea` only).** Off by default and never auto-triggered. `--ground-code` bare derives a repo set from the idea's themes and the directories under `${REPOS_PATH:-/workspace}` (one confirm gate); `--ground-code <repo>,<repo>` scans exactly those. Round 1 is the standard `code-scanner` fan-out (cap 4); a theme it leaves inconclusive gets **one** narrow follow-up round seeded with round 1's verified `file:line` anchors, per `references/model-routing/classification.md` §8.5 — there is no round 3. Findings enter the grill as facts, not questions, except one that contradicts the idea's premise, which competes for a question slot like any other challenge. They land in `idea.md`'s optional `## Feasibility grounding` section, never in `Signals & evidence` (which is demand evidence only).
```

- [ ] **Step 3: Version + changelog**

Set `"version": "2.49.0"` in `plugins/dev-workflows/.claude-plugin/plugin.json`. Add a `## 2.49.0` entry at the top of `plugins/dev-workflows/CHANGELOG.md`, above `## 2.48.0`, covering: `--ground-code` with the §8.5 shape; `## Feasibility grounding`; `evidence[].lines`; the `When a choice list fires` rule; `/idea` Phase 1's two conditional lists (naming the path-like-argument defect); the `Repo missing (after resolution)` list fix and its six citers; `/implement`'s Phase 1.7 escalations.

**Write every changelog claim from the diff, not from memory.** Run `git diff main...HEAD --stat` and check each bullet against it. A previous sub-project shipped a changelog entry that invented a directory, overstated a section, and named an option that does not exist.

- [ ] **Step 4: Root `CLAUDE.md`**

- In the workflow map, the `/idea` line gains the scan: `→ [code-scanner×N (--ground-code, cap 4, broad-then-narrow)]` after the existing grounding bracket.
- In the model-routing paragraph, the §8 sentence gains `and §8.5's opt-in seeded second round (`/idea` only)`.
- In the agents list under the workflow map, `code-scanner` gains `/idea` to its caller list.

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
# expect 2.49.0
grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json
# expect OK — changelog entry exists and is above 2.48.0. The headings are
# Keep-a-Changelog bracketed (`## [2.49.0] — 2026-08-12`), so the pattern must
# include the brackets. (This check read `/^## 2\.49\.0/` when the plan was
# written and matched neither heading, always printing BAD ORDER.)
awk '/^## \[2\.49\.0\]/{a=NR} /^## \[2\.48\.0\]/{b=NR} END {print (a>0 && a<b) ? "OK" : "BAD ORDER"}' plugins/dev-workflows/CHANGELOG.md
# expect 3 — README usage cell, README row body, README grounding paragraph.
# Count OCCURRENCES, not lines: the usage cell and the row body live on the same
# one-line table row, so `grep -c` collapses them and reports 2.
grep -o 'ground-code' plugins/dev-workflows/README.md | wc -l   # expect 5 occurrences across the 3 sites
# expect 1 each
grep -c 'broad-then-narrow' CLAUDE.md
python3 -c "import json;json.load(open('.claude-plugin/marketplace.json'));print('marketplace OK')"
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/README.md plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/.claude-plugin/plugin.json CLAUDE.md
git commit -m "docs(dev-workflows): 2.49.0 — code grounding + the choice-list firing rule"
```

---

### Task 11: Port to `mgd-claude-plugins`

**Files:**
- Modify: every file Tasks 1–10 touched, under `/workspace/mgd-claude-plugins/`

mgd is **content-verbatim** except its identity files. The divergence set has been recorded as both five and six files at different times — **measure it, do not assume it.**

- [ ] **Step 1: Measure the current divergence set**

```bash
cd /workspace/mgd-claude-plugins
diff -rq --exclude=.git . /workspace/ihudak-claude-plugins | sed 's/^/  /'
```

Everything that differs is either an identity file (expected — `plugin.json`, `LICENSE`, `README.md`, `references/dependencies.md`, root `CLAUDE.md`, `.claude-plugin/marketplace.json`) or drift to investigate. **`references/dependencies.md` saying `mgd-plugins` where canonical says `ihudak-plugins` is CORRECT — mgd is a different marketplace.** Three reviewers have mislabelled it as drift. Record the measured set in the commit message.

- [ ] **Step 2: Copy the changed non-identity files**

```bash
cd /workspace/ihudak-claude-plugins
git diff --name-only main...HEAD -- plugins/dev-workflows/ \
  | grep -v -e 'plugin.json$' -e 'LICENSE$' -e 'README.md$' -e 'dependencies.md$' \
  | while read -r f; do cp "$f" "/workspace/mgd-claude-plugins/$f"; done
```

Then port `README.md` and `CLAUDE.md` **by hand** — apply the same content edits while preserving mgd's identity strings — and set `"version": "2.49.0"` in mgd's `plugins/dev-workflows/.claude-plugin/plugin.json`. Add the same `## 2.49.0` changelog entry.

- [ ] **Step 3: Verify**

```bash
diff -rq --exclude=.git /workspace/mgd-claude-plugins /workspace/ihudak-claude-plugins
```

Expect **only** the identity files measured in Step 1 — a seventh differing file is the signal that something went wrong. Then:

```bash
cd /workspace/mgd-claude-plugins
grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json     # expect 2.49.0
python3 -c "import json;json.load(open('.claude-plugin/marketplace.json'));print('OK')"
for f in plugins/dev-workflows/agents/*.md; do head -1 "$f" | grep -q '^---$' || echo "BAD FRONTMATTER: $f"; done
```

- [ ] **Step 4: Commit**

```bash
cd /workspace/mgd-claude-plugins
git add -A && git commit -m "feat(dev-workflows): 2.49.0 — port /idea code grounding + choice-list firing rule"
```

---

### Task 12: Port to `ihudak-copilot-plugins` (2.19.0)

**Files:**
- Modify: `dev-workflows/skills/idea/SKILL.md`, `dev-workflows/skills/implement/SKILL.md`, `dev-workflows/skills/_shared/{escalation-rules,idea-format,model-routing}.md`, `dev-workflows/skills/_shared/handoff/code-scanner.md`, `dev-workflows/agents/code-scanner.md`, `dev-workflows/README.md`, `dev-workflows/CHANGELOG.md`, `dev-workflows/.plugin/plugin.json`

**NEVER `cp` a canonical file into copilot.** It carries genuinely different content, not just dialect. Blind copies in an earlier sub-project wiped colon dialect in 30 places and imported a citation and a terminal-order step copilot does not implement. Every edit here is written by hand.

- [ ] **Step 1: Apply each task's content, by hand, in the copilot dialect**

Work task by task (1 → 10), reading copilot's existing text for each target file first, then applying the same *intent* with all four dialect rules:

1. `→ Agent (subagent_type: "dev-workflows:code-scanner", model: …)` → `→ task(agent_type: "code-scanner", model: …)`
2. `${CLAUDE_PLUGIN_ROOT}/references/X.md` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/X.md`
3. `§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5` → `§2.1 detection chain: claude-sonnet-4.6, fallback claude-sonnet-4.5/gpt-5.4`
4. **`/idea` → `idea:`, `/implement` → `implement:`, `/create-vi` → `create-vi:`**, and so on for every command name

Note `model-routing.md` is **flat** in copilot: §8.5 goes into `skills/_shared/model-routing.md`, not `model-routing/classification.md`, and every cross-reference to it uses the flat path.

- [ ] **Step 2: Version + changelog**

Set `"version": "2.19.0"` in `dev-workflows/.plugin/plugin.json` and add the matching `## 2.19.0` changelog entry — written from copilot's own diff, describing what copilot actually ships.

- [ ] **Step 3: Verify — dialect leak scan, tree-wide**

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows
echo "--- rule 1: Claude-style dispatch (expect 0) ---"
grep -rn 'subagent_type' . | wc -l
echo "--- rule 2: CLAUDE_PLUGIN_ROOT (expect 0) ---"
grep -rn 'CLAUDE_PLUGIN_ROOT' . | wc -l
echo "--- rule 3: Claude model chain wording (expect 0) ---"
grep -rn 'Sonnet chain' . | wc -l
echo "--- rule 4: slash-form command names (expect 0) ---"
grep -rnoE '/(idea|create-vi|update-vi|create-ard|specify|design|ready|implement|epics|document|docs-profile|vuln|upgrade|feedback|prompt|statusline)\b' . \
  | grep -v 'CHANGELOG.md' | wc -l
echo "--- Agent-tool language (expect 0) ---"
grep -rn 'Agent message' . | wc -l
echo "--- version ---"
grep '"version"' .plugin/plugin.json
```

Every count must be **0** except the version. If rule 4 reports hits inside a path (e.g. `<slug>/idea.md`), the converter over-matched — a path separator is not a command name. Fix by hand and re-run.

- [ ] **Step 4: Verify — intent parity against canonical**

For each of the seven changed files, read canonical's version and copilot's side by side and confirm the same *requirements* landed. Do **not** diff for text equality; they legitimately differ.

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows
grep -c 'When a choice list fires' skills/_shared/escalation-rules.md   # expect 1
grep -c 'Feasibility grounding' skills/_shared/idea-format.md            # expect >=1
grep -c '8.5 Broad, then narrow' skills/_shared/model-routing.md         # expect 1
grep -c 'lines:' skills/_shared/handoff/code-scanner.md                  # expect >=1
grep -c 'ground-code' skills/idea/SKILL.md                               # expect >=6
grep -c 'Repo missing (after resolution)' skills/implement/SKILL.md      # expect 1
grep -o '^## Section [0-9]*' skills/_shared/idea-format.md | awk '{printf "%s ", $3} END {print ""}'  # expect 1..9
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add -A && git commit -m "feat(dev-workflows): 2.19.0 — idea: code grounding + the choice-list firing rule"
```

---

### Task 13: Closeout — verification table + the §8.5 candidate entry

**Files:**
- Create: `docs/superpowers/plans/2026-08-12-idea-code-grounding-verification.md`
- Create: one entry appended to `$SPECS_PATH/dev-workflows-feedback/2026-08-12.md`

- [ ] **Step 1: Write the verification table**

One row per requirement `R1`–`R39` (plus `R9a`/`R9b`/`R9c`, `R15a`, `R20a`/`R20b`, `R26a`) — 46 rows. Each row: requirement, the exact command that checks it, expected result, actual result, PASS/FAIL. Reuse the per-task verify blocks above; add rows for the requirements they do not already cover.

Three checks belong only here, because they are cross-cutting:

```bash
# Residue — what did I make false?  Every statement about /idea's phase list.
cd /workspace/ihudak-claude-plugins
grep -rn 'Phase 2.5' plugins/dev-workflows/ | grep -v 'commands/idea.md'
grep -rn 'idea-format' plugins/dev-workflows/ | grep -c 'eight sections\|8 sections'   # expect 0

# No silent rebinding — the four commands that must be byte-identical
git diff --name-only main...HEAD -- plugins/dev-workflows/commands/ \
  | grep -E 'epics|create-ard|specify|design' | wc -l    # expect 0

# Three-repo manifest + frontmatter sanity
for r in /workspace/ihudak-claude-plugins /workspace/mgd-claude-plugins /workspace/ihudak-copilot-plugins; do
  find "$r" -name 'marketplace.json' -o -name 'plugin.json' | while read -r m; do
    python3 -c "import json,sys;json.load(open('$m'))" || echo "BAD JSON: $m"
  done
done
```

- [ ] **Step 2: Write the §8.5 candidate feedback entry**

Append to `$SPECS_PATH/dev-workflows-feedback/2026-08-12.md` (create the file with the standard frontmatter — `type: dev-workflows-feedback`, `vi: n/a`, `slug: 2026-08-12` — if it does not exist) an entry with `id: 2026-08-12-implement-broad-then-narrow-candidate`, `command: /implement`, `category: missing-capability`, `impact: polish`, recording: `/implement`'s Phase 1.7 fan-out feeds a planner that acts on the answer, which is the same failure mode `/idea` recorded and §8.5 now addresses; §8.5 is opt-in and `/implement` deliberately did not adopt it in 2.49.0 because no `/implement` run has hit the failure; the decision should be revisited with evidence from a real run.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add docs/superpowers/plans/2026-08-12-idea-code-grounding-verification.md
git commit -m "docs(superpowers): H verification table — 46 requirements checked"
cd "$SPECS_PATH" && git add dev-workflows-feedback/2026-08-12.md \
  && git commit -m "NOISSUE Record /implement as the candidate second consumer of model-routing 8.5"
```

---

## Self-review

**Spec coverage.** R1–R3 → Task 1 Step 1. R4–R6 → Task 5 Step 4. R7–R9 → Task 9. R9a–R9c → Task 1 Step 2. R10–R11 → Task 5 Steps 1, 3. R12–R14 → Task 6 OFF branch. R15, R15a → Task 6 Step 1. R16–R17 → Task 6 Step 1. R18–R19 → Task 6 (phase placement + two branches). R20 → Task 6 Step 1. R20a–R20b → Task 8. R21 → Task 5 Step 2. R22–R27 → Task 3. R26a → Task 13 Step 2. R28–R29 → Task 4. R30–R31 → Task 7 Step 1. R32–R38 → Task 2 (+ Task 7 Step 2 for the writing side). R39 → Task 7 Step 3. Three-repo port → Tasks 11–12. No gaps.

**Placeholder scan.** No "TBD", no "handle edge cases", no "similar to Task N". Every insertion carries its verbatim text. Task 9 is exploratory by design and states its decision procedure and its honest-null outcome rather than a placeholder.

**Name consistency.** `## Feasibility grounding` (Tasks 2, 7, 10, 12), `## When a choice list fires` (Tasks 1, 5, 6, 12), `### 8.5 Broad, then narrow` (Tasks 3, 6, 10, 12), `evidence[].lines` (Tasks 4, 2, 6, 7), `Phase 2.6` (Tasks 5, 6, 7, 10), `Repo missing (after resolution)` (Tasks 1, 6, 8, 12) — one spelling each, checked across every task that names them.

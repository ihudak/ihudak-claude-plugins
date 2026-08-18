# Jira-Safe Requirement IDs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the VI/ARD/Epic requirement-ID grammar `[AC-1]` with `[AC#1]` so pasting an artifact into Jira stops auto-linking unrelated tickets, and make the collision mechanically detectable rather than remembered.

**Architecture:** One grammar, `[PREFIX#N]`, describes the whole VI/ARD namespace, so a single regex checks it. A new repo script (`scripts/check-id-grammar.sh`) turns the convention into a red/green gate that every content task drives to green; a new `pre-lint.md` check applies the same rule at runtime to user-authored artifacts. The vault importers need no code change — verified empirically — only characterization tests locking their current behaviour. The spec/design namespace (`[U01]`/`[AC01]`/`[TC01]`) is deliberately untouched, which makes a global find-and-replace unsafe.

**Tech Stack:** Markdown (Claude Code plugin content), bash + grep for the repo gate, Python 3 + pytest for the vault importer tests.

**Spec:** `docs/superpowers/specs/2026-08-18-jira-safe-requirement-ids-design.md`

## Global Constraints

- **Grammar:** every ID minted into a VI, ARD, or Epic file matches `\[[A-Z]{2,4}#[0-9]+\]`. VI prefixes: `US`, `AC`, `SM`, `SMC`, `UC`, `FR`. ARD prefix: `AD`. Numbers unpadded, contiguous from 1.
- **Never change** `[U01]` / `[AC01]` / `[TC01]` (spec + design namespace) anywhere, including inside `agents/code-review.md`, `references/specification-format.md`, `references/design-format.md`.
- **Never change** `CHANGELOG.md` dash-form IDs in any edition — they are history.
- **Writers strict, readers tolerant:** only `jira-reader` accepts both `[US-1]` and `[US#1]`, and only inside requirement-bearing sections.
- **Three editions:** `/workspace/ihudak-claude-plugins` (canonical, 2.52.0 → 2.53.0), `/workspace/mgd-claude-plugins` (2.52.0 → 2.53.0), `/workspace/ihudak-copilot-plugins` (2.22.0 → 2.23.0). Never blind-`cp` into mgd; never `cp` into copilot at all.
- **Branch:** `iv-gu/jira-safe-requirement-ids` in all three repos.
- **Vault repo:** `/workspace/vault/.obsidian/scripts/custom/` — two trees, `jira-workitem-import` and `jira-bulk-import`.

---

## File Structure

**Canonical edition — `/workspace/ihudak-claude-plugins`**

| File | Responsibility | Change |
|---|---|---|
| `scripts/check-id-grammar.sh` | The repo gate: fails when any tracked plugin doc teaches the dash form | Create |
| `scripts/fixtures/vi-bad.md` | Known-bad fixture — dash-form IDs; the gate must flag it | Create |
| `scripts/spec-id-baseline.txt` | Committed census of frozen spec/design IDs; Risk 1's tripwire | Create |
| `scripts/fixtures/vi-good.md` | Known-good fixture — `#` IDs plus a real `[[PRODUCT-123]]`; the gate must pass it | Create |
| `plugins/dev-workflows/references/pre-lint.md` | Runtime collision check + revised ID series | Modify |
| `plugins/dev-workflows/references/vi-format.md` | VI grammar authority | Modify |
| `plugins/dev-workflows/references/ard-format.md` | ARD grammar authority | Modify |
| `plugins/dev-workflows/references/ard-resolution.md` | `AD-N` resolution protocol — prose + one YAML example + one output template | Modify |
| `plugins/dev-workflows/references/handoff/jira-reader.md` | Handoff contract for `requirements[].id` | Modify |
| `plugins/dev-workflows/commands/{create-vi,update-vi,create-ard,epics,ready,implement,design}.md` | Producers + cross-cutting citations | Modify |
| `plugins/dev-workflows/agents/{epic-writer,jira-reader}.md` | Producer + tolerant reader | Modify |
| `plugins/dev-workflows/agents/{vi,ard,epic,readiness,spec,design}-reviewer.md`, `agents/code-review.md` | Reviewers check the new grammar | Modify |
| `CLAUDE.md`, `plugins/dev-workflows/README.md` | Identity files — where cross-repo fixes die | Modify |
| `plugins/dev-workflows/CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Release | Modify |

**Vault repo — `/workspace/vault/.obsidian/scripts/custom`**

| File | Responsibility | Change |
|---|---|---|
| `jira-workitem-import/tests/test_jira_markup_converter.py` | Characterization + idempotency + drift guard | Modify |
| `jira-bulk-import/tests/test_jira_markup_converter.py` | Same, for the markdown-link variant | Modify |

---

### Task 1: Pre-flight Jira paste probe (GATE)

Spec Risk 0 / R23. **Nothing else in this plan may start until this passes.** Every other task assumes Jira leaves `#` alone; that assumption has never been executed, only reasoned about. If it is wrong, the grammar changes here — cheaply — instead of after 23 files are edited.

This task requires a human with Jira access. It is not automatable.

**Files:** none (produces a recorded result only)

**Interfaces:**
- Consumes: nothing
- Produces: a go/no-go on the `[PREFIX#N]` grammar for every downstream task

- [ ] **Step 1: Ask the user to run the probe**

Present exactly this, and wait:

> Before I touch any files, one thing needs checking in real Jira — it's the only assumption in the design I couldn't test from here.
>
> Please paste these five lines into the description of a **scratch** Jira ticket (any throwaway ticket, not a real VI):
>
> ```
> [US#1]: a user story
> [AC#1] an acceptance criterion
> [AD#1]: an architecture decision
> See PRODUCT-123 for the real ticket.
> Bare AC#2 outside brackets.
> ```
>
> Then tell me: (a) did any of `US#1`, `AC#1`, `AD#1`, `AC#2` turn into a link or a ticket card? (b) did `PRODUCT-123` become a working link?

- [ ] **Step 2: Evaluate the answer**

PASS requires both: no autolink on any `#` token, AND `PRODUCT-123` linked. Anything else is a FAIL.

- [ ] **Step 3: On FAIL, stop and re-open the design**

Do not work around it downstream. Report which token Jira mangled and stop; the grammar decision in spec §D1/§D3 has to be revisited. Candidate fallbacks already analysed and rejected only on secondary grounds: `[AC.1]` (dot separator) and `[AC01]` (padded, collides with the spec namespace).

- [ ] **Step 4: On PASS, export the scratch ticket and confirm the round trip**

```bash
cd /workspace/vault/.obsidian/scripts/custom/jira-workitem-import
./runme.sh <SCRATCH-KEY>
grep -nE '\[(US|AC|AD)#[0-9]+\]|PRODUCT-123' <export-dir>/<SCRATCH-KEY>/<SCRATCH-KEY>/<SCRATCH-KEY>.md
```

Expected: the three `#` tokens present and byte-identical to what was pasted; `PRODUCT-123` rendered as `[[PRODUCT-123]]`.

- [ ] **Step 5: Record the result in the spec**

Append to `docs/superpowers/specs/2026-08-18-jira-safe-requirement-ids-design.md` under §10 Risk 0 a single line: `**Probe result (YYYY-MM-DD):** PASS — Jira left [US#1]/[AC#1]/[AD#1]/AC#2 unlinked; PRODUCT-123 linked; round trip byte-identical.`

```bash
cd /workspace/ihudak-claude-plugins
git add docs/superpowers/specs/2026-08-18-jira-safe-requirement-ids-design.md
git commit -m "docs(superpowers): record the Jira paste probe result"
```

---

### Task 2: The repo gate — `scripts/check-id-grammar.sh`

Builds the harness every later task drives to green, and the mechanical cross-edition check that Risk 4 depends on. Written first so the content tasks have a real red/green cycle.

Spec: Risk 1, Risk 3, Risk 4.

**Files:**
- Create: `scripts/check-id-grammar.sh`
- Create: `scripts/fixtures/vi-bad.md`
- Create: `scripts/fixtures/vi-good.md`
- Create: `scripts/spec-id-baseline.txt`

**Interfaces:**
- Consumes: nothing
- Produces: `scripts/check-id-grammar.sh [--root <dir>]` — exit 0 when clean, exit 1 with a file:line list otherwise. Tasks 3–9 and 12–14 run it.

- [ ] **Step 1: Write the two fixtures**

`scripts/fixtures/vi-bad.md` — must be flagged:

```markdown
# Bad fixture — dash-form IDs (must be flagged)

## User Stories
### [US-1]: Export the thing
As a PM, I want an export, so that I can share it.

## Acceptance Criteria
- [AC-1] Export completes within 30s.
- [AC-2] Export is idempotent.

## Success Metrics
- [SM-1] 90% of exports finish under 30s.

## References
- [[PRODUCT-123]]
```

`scripts/fixtures/vi-good.md` — must pass clean:

```markdown
# Good fixture — hash-form IDs plus a real Jira key (must pass)

## User Stories
### [US#1]: Export the thing
As a PM, I want an export, so that I can share it.

## Acceptance Criteria
- [AC#1] Export completes within 30s.
- [AC#2] Export is idempotent.

## Success Metrics
- [SM#1] 90% of exports finish under 30s.
- [SMC#1] Error rate must not rise.

## References
- [[PRODUCT-123]]
- [[MGD-8605]]
```

- [ ] **Step 2: Write the gate script**

```bash
#!/usr/bin/env bash
# Fails when a tracked plugin doc teaches the dash-form requirement-ID grammar.
# Spec: docs/superpowers/specs/2026-08-18-jira-safe-requirement-ids-design.md
set -uo pipefail

ROOT="."
[ "${1:-}" = "--root" ] && ROOT="$2"

# Requirement-ID prefixes the plugin mints. NOT a general Jira-key check:
# a real key like PRODUCT-123 is legitimate and must never be flagged.
PATTERN='\[(US|AC|SM|SMC|UC|FR|AD)-[N0-9]+\]|(^|[^[:alnum:]_[])(US|AC|SM|SMC|UC|FR|AD)-[Nn0-9]+([^[:alnum:]_]|$)'

# CHANGELOG.md is history and keeps the dash form (spec Global Constraints).
# A line carrying the marker `id-grammar-ok:` is documenting the legacy form on
# purpose (jira-reader's reader tolerance). Task 8 is the only sanctioned user;
# Task 8 Step 6 audits the total count so it cannot become a general escape hatch.
hits=$(grep -rnE "$PATTERN" \
        --include='*.md' \
        --exclude='CHANGELOG.md' \
        --exclude-dir='.git' \
        --exclude-dir='docs' \
        --exclude-dir='fixtures' \
        "$ROOT" 2>/dev/null \
       | grep -v 'id-grammar-ok:' || true)

if [ -n "$hits" ]; then
  echo "FAIL: dash-form requirement IDs found (expected [PREFIX#N]):"
  echo "$hits"
  echo
  echo "Count: $(echo "$hits" | wc -l)"
  exit 1
fi

echo "PASS: no dash-form requirement IDs under $ROOT"
exit 0
```

```bash
chmod +x scripts/check-id-grammar.sh
```

- [ ] **Step 3: Prove the gate fails on the bad fixture and passes on the good one**

Both directions must be shown — a gate that only ever fires, or only ever passes, proves nothing (spec Risk 3).

Run:
```bash
./scripts/check-id-grammar.sh --root scripts/fixtures/vi-bad.md ; echo "exit=$?"
./scripts/check-id-grammar.sh --root scripts/fixtures/vi-good.md ; echo "exit=$?"
```
Expected: first prints `FAIL` with 4 hits (`[US-1]`, `[AC-1]`, `[AC-2]`, `[SM-1]`) and `exit=1`; second prints `PASS` and `exit=0`. The good fixture's `[[PRODUCT-123]]` and `[[MGD-8605]]` must NOT appear in any output — a real key is not a violation.

- [ ] **Step 4: Capture the spec-namespace baseline (Risk 1)**

A count is too weak — it stays equal if one site changes and another is added. Extract the actual lines:

```bash
grep -rhoE '\[U0[0-9]+\]|\[AC0[0-9]+\]|\[TC0[0-9]+\]|\[Uxx\]|\[ACxx\]|\[TCxx\]' \
  --include='*.md' plugins/ CLAUDE.md | sort | uniq -c > scripts/spec-id-baseline.txt
cat scripts/spec-id-baseline.txt
```
Expected: a non-empty token census (spec/design ID sites). This is **committed**, not a temp file — Tasks 7, 9 and 11 diff against it, and it stays checkable long after this change ships. It records tokens rather than `file:line` so that unrelated edits shifting line numbers do not produce false alarms.

- [ ] **Step 5: Run the gate against the real tree and confirm it is RED**

Run: `./scripts/check-id-grammar.sh --root plugins/`
Expected: `FAIL`, with hits across ~22 files. This is the red state Tasks 3–9 turn green.

- [ ] **Step 6: Commit**

```bash
git add scripts/check-id-grammar.sh scripts/fixtures/ scripts/spec-id-baseline.txt
git commit -m "test(scripts): gate for dash-form requirement IDs, red on the current tree"
```

---

### Task 3: `pre-lint.md` — runtime collision check + revised ID series

Spec R5–R9. Built before the content changes so later tasks can be checked with the rule they are meant to satisfy.

**Files:**
- Modify: `plugins/dev-workflows/references/pre-lint.md:29` (VI ID series), `:37-38` (ARD), `:58` (Epic `## Covers`), plus a new subsection

**Interfaces:**
- Consumes: nothing
- Produces: the `Jira-key collision` check name, cited by Tasks 7 (reviewers) and by `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `/epics` at runtime (already wired — they cite this file today)

- [ ] **Step 1: Add the collision check as a new section**

Insert after the `## Universal checks (every artifact)` block, before `## VI — …`:

```markdown
## Jira-key collision (VI, ARD, Epic files only)

An artifact whose body is pasted into Jira must contain no token Jira will auto-link. Run:

    grep -nE '\b[A-Z]{2,10}-[0-9]+\b' <file>

For the VI, run against the body **below the frontmatter** — `/create-vi` pastes only that, and the
frontmatter's `jira_key:` / `ref:` / `seeded_from_vi:` / `revision_of:` legitimately carry keys.

Discard a hit ONLY when it is a deliberate Jira reference: inside a wikilink (`[[KEY-123]]`), inside
a markdown link, or inside a fenced code block. Every surviving hit → **BLOCKER**, with the fix
named — convert to `[PREFIX#N]` if it is a requirement ID, wrap as `[[KEY-123]]` if it is a real
ticket. The conversion is mechanical, so inline-fix it under the standard pre-lint contract.

The ARD is not itself pasted into Jira, but `epic-writer` copies its `AD` references into Epic
drafts, which are. Catching it at the source is cheaper than catching it downstream.
```

- [ ] **Step 2: Replace the three ID-series lines**

`:29` — from:
```
- ID series: `[US-N]` (in `### [US-N]:` headings), `[AC-N]`, `[SM-N]` — each contiguous from 1.
```
to:
```
- ID series: `[US#N]` (in `### [US#N]:` headings), `[AC#N]`, `[SM#N]` — each contiguous from 1.
  Plus `[SMC#N]` (counter-metrics), `[UC#N]`, `[FR#N]` when those adapt-in clusters are present.
```

`:37-38` — from `[AD-N]` to `[AD#N]` in all three occurrences (`### [AD#N]:` headings, and the Binds/Prevents/Rule sub-field rule).

`:58` — from:
```
- `## Covers` references parent-VI IDs (`US-N`/`AC-N`/`SM-N`); Epics do not mint their own criterion IDs.
```
to:
```
- `## Covers` references parent-VI IDs in bracketed form (`[US#N]`/`[AC#N]`/`[SM#N]`); Epics do not
  mint their own criterion IDs.
```

- [ ] **Step 3: Run the gate on this file**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/references/pre-lint.md`
Expected: `PASS`.

- [ ] **Step 4: Confirm the check text itself does not trip the gate**

The new section contains the regex `[A-Z]{2,10}-[0-9]+` and the literal `[[KEY-123]]`. Neither matches the gate's prefix list, so Step 3 passing confirms it. If Step 3 fails here, the gate's pattern is over-broad — fix the gate, not the documentation.

- [ ] **Step 5: Confirm pre-lint stayed advisory (R9)**

The new check introduces a BLOCKER *severity*, not a new hard stop. Verify the file's opening contract is unchanged:

Run: `grep -n 'never hard-stops\|Advisory' plugins/dev-workflows/references/pre-lint.md`
Expected: the original `**Advisory:**` sentence and `Pre-lint **never hard-stops** on its own; the reviewer remains the gate.` both still present and unedited. If the new section reworded either, revert that — the reviewer stays the gate.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/references/pre-lint.md
git commit -m "feat(dev-workflows): pre-lint gains the Jira-key collision check"
```

---

### Task 4: VI grammar authority + VI producers

Spec R1–R3, R13.

**Files:**
- Modify: `plugins/dev-workflows/references/vi-format.md:50,51,53,59,68,79`
- Modify: `plugins/dev-workflows/commands/create-vi.md` (15 sites)
- Modify: `plugins/dev-workflows/commands/update-vi.md` (2 sites)

**Interfaces:**
- Consumes: Task 3's grammar statement in `pre-lint.md`
- Produces: the `[US#N]`/`[AC#N]`/`[SM#N]`/`[SMC#N]`/`[UC#N]`/`[FR#N]` vocabulary that Tasks 6, 7, 8 reference

- [ ] **Step 1: Confirm the gate is RED for these three files**

Run:
```bash
./scripts/check-id-grammar.sh --root plugins/dev-workflows/references/vi-format.md
./scripts/check-id-grammar.sh --root plugins/dev-workflows/commands/create-vi.md
./scripts/check-id-grammar.sh --root plugins/dev-workflows/commands/update-vi.md
```
Expected: three `FAIL`s, 6 / 15 / 2 hits respectively.

- [ ] **Step 2: Edit `vi-format.md`**

Six sites, exact replacements:

- `:50` — `` `### [US-N]: <title>` `` → `` `### [US#N]: <title>` ``
- `:51` — `` `[AC-N]` `` → `` `[AC#N]` ``
- `:53` — `` `[SM-N]` `` → `` `[SM#N]` ``; and `` (`[SM-C1]`, `[SM-C2]`…) `` → `` (`[SMC#1]`, `[SMC#2]`…) ``; the example `"throughput up, but `[SM-C1]` error-rate must not rise"` → `` `[SMC#1]` ``
- `:59` — `` (UC-N narrative) `` → `` (`[UC#N]` narrative) ``
- `:68` — `` (FR-N *Implements: UC-n / US-n*) `` → `` (`[FR#N]` *Implements: `[UC#n]` / `[US#n]`*) ``
- `:79` — three sites on one line: `` no `[AC-N]` delivering `` → `` no `[AC#N]` delivering ``; `` no conflicting `[US-N]` `` → `` no conflicting `[US#N]` ``

- [ ] **Step 3: Edit the two commands**

Enumerate and fix every site:
```bash
grep -nE '\[(US|AC|SM|AD|UC|FR|SM-C)-[N0-9x]+\]|\b(US|AC|SM|AD|UC|FR)-[Nn0-9]+\b' \
  plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/update-vi.md
```
Apply the same prefix mapping as Step 2 at each hit. Where a site is a worked example of a rendered VI (e.g. a sample `### [US-1]:` heading), the example changes too — a stale example teaches the old grammar as loudly as a rule does.

- [ ] **Step 4: Run the gate — expect GREEN for all three**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/references/vi-format.md && ./scripts/check-id-grammar.sh --root plugins/dev-workflows/commands/create-vi.md && ./scripts/check-id-grammar.sh --root plugins/dev-workflows/commands/update-vi.md`
Expected: three `PASS` lines.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/vi-format.md plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/update-vi.md
git commit -m "feat(dev-workflows): VI grammar moves to [PREFIX#N]"
```

---

### Task 5: ARD grammar authority, resolution protocol, and `/create-ard`

Spec R1, R13, R15. `ard-resolution.md` is the densest single file (15 sites) and is **not** a find-and-replace: `:33` is a YAML contract example carrying a real ID instance, `:60` is an output template consumers write into their own artifacts, and the rest are prose references to the concept.

**Files:**
- Modify: `plugins/dev-workflows/references/ard-format.md:12,36,46,47`
- Modify: `plugins/dev-workflows/references/ard-resolution.md:21,22,33,38,57,60,67-72,74`
- Modify: `plugins/dev-workflows/commands/create-ard.md` (6 sites)

**Interfaces:**
- Consumes: Task 3's grammar statement
- Produces: `[AD#N]` and the `- ARD deviation: [<AD#N id>] — …` template referenced by Tasks 6, 7, 9

- [ ] **Step 1: Confirm RED**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/references/ard-resolution.md`
Expected: `FAIL`, 15 hits.

- [ ] **Step 2: Edit `ard-format.md` — four prose sites**

`:12`, `:36`, `:46`, `:47`: every `AD-N` → `AD#N`; at `:36` the heading form `` `### [AD-N]: <title>` `` → `` `### [AD#N]: <title>` ``.

- [ ] **Step 3: Edit `ard-resolution.md` — three kinds of site, handled differently**

**Prose references** (`:21`, `:22`, `:38`, `:57`, `:67`–`:72`, `:74`): `AD-N` → `AD#N`.

**The YAML contract example** at `:33` — this is data a consumer parses, not prose:
```yaml
  - id: AD-1
```
becomes
```yaml
  - id: AD#1
```

**The deviation-record template** at `:60`:
```
- ARD deviation: [<AD-N id>] — <what deviates> — <why> — flag: architect
```
becomes
```
- ARD deviation: [<AD#N id>] — <what deviates> — <why> — flag: architect
```

- [ ] **Step 4: Verify the parse instruction at `:21-22` still reads correctly**

Line 21-22 tells a consumer to parse `## Architecture decisions` into `AD#N {id, binds, prevents, rule, source}`. Read the whole sentence after editing and confirm it still describes parsing a heading of the form `### [AD#N]: <title>` — if the sentence names the old heading shape anywhere, fix that too. This is why the file is a task and not a `sed`.

- [ ] **Step 5: Edit `create-ard.md` — 6 sites**

```bash
grep -nE '\bAD-[Nn0-9]+\b|\[AD-[N0-9]+\]' plugins/dev-workflows/commands/create-ard.md
```
Apply `AD-N` → `AD#N` at each.

- [ ] **Step 6: Run the gate — expect GREEN**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/references/ard-format.md && ./scripts/check-id-grammar.sh --root plugins/dev-workflows/references/ard-resolution.md && ./scripts/check-id-grammar.sh --root plugins/dev-workflows/commands/create-ard.md`
Expected: three `PASS` lines.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/references/ard-format.md plugins/dev-workflows/references/ard-resolution.md plugins/dev-workflows/commands/create-ard.md
git commit -m "feat(dev-workflows): ARD decisions move to [AD#N]"
```

---

### Task 6: Epic producer — `epic-writer` and `/epics`

Spec R3, R13. `epic-writer.md:79` is the worst site in the codebase: bare, unbracketed IDs pasted into Jira, mangled by both Jira and the importers. `:142-143` is a `_coverage.md` table with ID instances.

**Files:**
- Modify: `plugins/dev-workflows/agents/epic-writer.md:20,79,142,143,160,161,163`
- Modify: `plugins/dev-workflows/commands/epics.md:162`

**Interfaces:**
- Consumes: Task 4's VI vocabulary, Task 5's `AD#N` and deviation template
- Produces: the bracketed `## Covers` shape that `pre-lint.md:58` (Task 3) checks

- [ ] **Step 1: Confirm RED**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/agents/epic-writer.md`
Expected: `FAIL`, 7 hits.

- [ ] **Step 2: Fix the `## Covers` template at `:79`**

From:
```
- <VI requirement IDs this Epic satisfies, e.g. US-2, AC-4, AC-5, SM-1>
```
to:
```
- <VI requirement IDs this Epic satisfies, bracketed — e.g. [US#2], [AC#4], [AC#5], [SM#1]>
```

Bracketing is mandatory here, not cosmetic: it is the importers' protection mechanism and it makes the pre-lint grep exact.

- [ ] **Step 3: Fix the `_coverage.md` table at `:142-143`**

From:
```
| US-1 | story     | …            | Epic: <slug-a> (new); <KEY> (exist)  | ✅     |
| AC-3 | criterion | …            | —                                    | ❌ gap |
```
to:
```
| [US#1] | story     | …            | Epic: <slug-a> (new); <KEY> (exist)  | ✅     |
| [AC#3] | criterion | …            | —                                    | ❌ gap |
```

- [ ] **Step 4: Fix the ARD sites at `:20,160,161,163`**

`AD-N` → `AD#N` at each; at `:163` the deviation template becomes `- ARD deviation: [<AD#N id>] — <what deviates> — <why> — flag: architect`, matching Task 5 Step 3 exactly.

- [ ] **Step 5: Fix `epics.md:162`**

`AD-N` → `AD#N`.

- [ ] **Step 6: Run the gate — expect GREEN**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/agents/epic-writer.md && ./scripts/check-id-grammar.sh --root plugins/dev-workflows/commands/epics.md`
Expected: two `PASS` lines.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/agents/epic-writer.md plugins/dev-workflows/commands/epics.md
git commit -m "fix(dev-workflows): Epic ## Covers emits bracketed [PREFIX#N], never bare IDs"
```

---

### Task 7: Reviewers check the new grammar

Spec R14 — a dash-form ID is a **BLOCKER**, not a style nit: it produces false Jira links on paste.

**Files:**
- Modify: `plugins/dev-workflows/agents/vi-reviewer.md:31,32,34,39,40,47`
- Modify: `plugins/dev-workflows/agents/ard-reviewer.md:3,30,31,34,41`
- Modify: `plugins/dev-workflows/agents/epic-reviewer.md:24,37,57`
- Modify: `plugins/dev-workflows/agents/readiness-reviewer.md:28,56,58`
- Modify: `plugins/dev-workflows/agents/spec-reviewer.md:23,61`
- Modify: `plugins/dev-workflows/agents/design-reviewer.md:27,70`
- Modify: `plugins/dev-workflows/agents/code-review.md:35,109`

**Interfaces:**
- Consumes: Tasks 4–6 vocabulary
- Produces: nothing downstream

- [ ] **Step 1: Confirm RED**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/agents/`
Expected: `FAIL` across the seven reviewer files (plus `jira-reader.md`, which Task 8 owns).

- [ ] **Step 2: Apply the prefix mapping in all seven files**

```bash
grep -nE '\[(US|AC|SM|AD)-[N0-9]+\]|\b(US|AC|SM|AD)-[Nn0-9]+\b' plugins/dev-workflows/agents/*-reviewer.md plugins/dev-workflows/agents/code-review.md
```
`US-N`→`US#N`, `AC-N`→`AC#N`, `SM-N`→`SM#N`, `AD-N`→`AD#N` at each hit, preserving surrounding backticks and brackets.

**`readiness-reviewer.md:58` is mixed and must not be blanket-replaced.** It reads:
```
| Identifier integrity | IDs (VI/Epic keys, `Uxx`/`ACxx`, `AD-N`, etc.) are consistent and unique across the whole chain. |
```
Only `AD-N` changes. `Uxx`/`ACxx` are the **spec** namespace and are frozen (Global Constraints).

**`code-review.md`** carries `[Uxx]`/`[ACxx]`/`[TCxx]` in its converge check. Those are frozen too; only the two `AD-N` sites at `:35` and `:109` change.

- [ ] **Step 3: Add the BLOCKER rule to `vi-reviewer.md`**

Under `- **Identifier integrity:**` at `:39`, append:
```
  A dash-form ID (`[AC-1]`, `[US-1]`, …) is a **BLOCKER** — Jira auto-links it to an unrelated
  ticket on paste, and the vault importer rewrites it into `[[[AC-1]]]` on export.
```

Add the equivalent line to `ard-reviewer.md` under its `:34` identifier-integrity bullet, naming `[AD-1]`.

- [ ] **Step 4: Verify the spec namespace survived (Risk 1)**

Run:
```bash
grep -rhoE '\[U0[0-9]+\]|\[AC0[0-9]+\]|\[TC0[0-9]+\]|\[Uxx\]|\[ACxx\]|\[TCxx\]' \
  --include='*.md' plugins/ CLAUDE.md | sort | uniq -c | diff scripts/spec-id-baseline.txt - \
  && echo "SPEC NAMESPACE INTACT"
```
Expected: empty diff and `SPEC NAMESPACE INTACT`. A non-empty diff means a frozen ID was touched — revert that hunk before continuing.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/
git commit -m "feat(dev-workflows): reviewers BLOCK dash-form requirement IDs"
```

---

### Task 8: The tolerant reader — `jira-reader`

Spec R10–R12, D5. The one deliberate asymmetry: writers are strict, this reader accepts both. Its failure mode is silent — a dash-form VI parsing to zero requirements makes `/epics` and `/ready` proceed on an empty list instead of erroring.

**Files:**
- Modify: `plugins/dev-workflows/agents/jira-reader.md:60,61,62,63,64,130`
- Modify: `plugins/dev-workflows/references/handoff/jira-reader.md:47`

**Interfaces:**
- Consumes: Task 4's VI vocabulary
- Produces: `requirements[].id` in `#` form — consumed by `/epics`, `/document`, `/ready`, `/implement`

- [ ] **Step 1: Confirm RED**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/agents/jira-reader.md`
Expected: `FAIL`, 6 hits.

- [ ] **Step 2: Rewrite the five parse rules at `:60-64`**

```markdown
   Accept **both** the current `#` form and the legacy dash form, and ALWAYS emit the `#` form in
   `id`. Tolerance applies ONLY inside these five sections — elsewhere (notably
   `## References / linked issues`) a `KEY-123` token is a real Jira key and is read as one.

   - `## User Stories` → each `### [US#N]: <title>` (or legacy `### [US-N]:`) → `{id: US#N, type: story, text: <title + the As-a/I-want/so-that line>}`.
   - `## Acceptance Criteria` → each `[AC#N]` (or legacy `[AC-N]`) bullet → `{id: AC#N, type: criterion, text: <bullet>}`.
   - `## Success Metrics` → each `[SM#N]` (or legacy `[SM-N]`) bullet → `{id: SM#N, type: metric, text: <bullet>}`; counter-metrics `[SMC#N]` (legacy `[SM-CN]`) → `{id: SMC#N, type: metric, text: <bullet>}`.
   - `## Functional requirements` (full profile only, when present) → each `[FR#N]` (or legacy `FR-N`) → `{id: FR#N, type: functional, text: <text>}`.
   - `## Use cases & user journey` (hybrid/full, when present) → each `[UC#N]` (or legacy `UC-N`) → `{id: UC#N, type: usecase, text: <text>}`.
```

- [ ] **Step 3: Update the two contract lines**

`agents/jira-reader.md:130` and `references/handoff/jira-reader.md:47`, both currently:
```
  - id:   <US-N | AC-N | SM-N | FR-N | UC-N | R1..>   # native VI id, else synthetic
```
become:
```
  - id:   <US#N | AC#N | SM#N | SMC#N | FR#N | UC#N | R1..>   # native VI id (always emitted in
          # `#` form, even when the source VI used the legacy dash form), else synthetic
```

- [ ] **Step 4: Run the gate — expect RED, because this task legitimately writes the dash form**

Run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/agents/jira-reader.md`
Expected: `FAIL`, listing the `legacy \`### [US-N]:\`` mentions from Step 2.

This is the gate working correctly, not a defect. This is the **only** file in the plugin that must document the dash form, because it is the only component that reads it.

- [ ] **Step 5: Apply the sanctioned marker to exactly those lines**

Append ` <!-- id-grammar-ok: legacy reader tolerance -->` to each line in `agents/jira-reader.md` that names a legacy dash form — the five parse rules from Step 2 that carry a `(or legacy …)` clause. The gate (Task 2) already filters lines carrying `id-grammar-ok:`.

Then run: `./scripts/check-id-grammar.sh --root plugins/dev-workflows/agents/jira-reader.md && ./scripts/check-id-grammar.sh --root plugins/dev-workflows/references/handoff/jira-reader.md`
Expected: two `PASS` lines.

- [ ] **Step 6: Prove the marker cannot become a general escape hatch**

Run: `grep -rn 'id-grammar-ok' plugins/ | wc -l`
Expected: exactly `5` — the five parse rules in `agents/jira-reader.md`, and nothing else. Any other file carrying the marker is suppressing a real violation rather than documenting reader tolerance; review and remove it. Repeat this audit in Tasks 12 and 13 for the ported editions.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/references/handoff/jira-reader.md
git commit -m "feat(dev-workflows): jira-reader accepts both ID forms, emits [PREFIX#N]"
```

---

### Task 9: Cross-cutting citations and identity files

Spec R15, R19. Identity files are where cross-repo fixes die — excluded from copying, duplicating claims made elsewhere, and classified as expected-to-differ by parity checks.

**Files:**
- Modify: `plugins/dev-workflows/commands/ready.md:167,170`
- Modify: `plugins/dev-workflows/commands/implement.md:236`
- Modify: `plugins/dev-workflows/commands/design.md:153`
- Modify: `CLAUDE.md:256`
- Modify: `plugins/dev-workflows/README.md:19,241,314,364` (5 sites — `:364` has two)

**Interfaces:**
- Consumes: Task 5's `AD#N`
- Produces: nothing downstream

- [ ] **Step 1: Confirm RED**

Run: `./scripts/check-id-grammar.sh --root CLAUDE.md ; ./scripts/check-id-grammar.sh --root plugins/dev-workflows/README.md`
Expected: two `FAIL`s, 1 and 5 hits.

- [ ] **Step 2: Apply `AD-N` → `AD#N` in all five files**

```bash
grep -nE '\bAD-[Nn0-9]+\b|\[AD-[N0-9]+\]' plugins/dev-workflows/commands/{ready,implement,design}.md CLAUDE.md plugins/dev-workflows/README.md
```
Fix each hit.

- [ ] **Step 3: Run the gate on the WHOLE tree — the first full-green moment**

Run: `./scripts/check-id-grammar.sh --root .`
Expected: `PASS: no dash-form requirement IDs under .`

If it fails, the remaining hits are files Tasks 4–8 missed. Fix them here rather than deferring — this is the task that closes the canonical edition.

- [ ] **Step 4: Re-verify the spec namespace one final time**

```bash
grep -rhoE '\[U0[0-9]+\]|\[AC0[0-9]+\]|\[TC0[0-9]+\]|\[Uxx\]|\[ACxx\]|\[TCxx\]' \
  --include='*.md' plugins/ CLAUDE.md | sort | uniq -c | diff scripts/spec-id-baseline.txt - \
  && echo "SPEC NAMESPACE INTACT"
```
Expected: empty diff.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md plugins/dev-workflows/README.md plugins/dev-workflows/commands/
git commit -m "feat(dev-workflows): AD#N across cross-cutting docs and identity files"
```

---

### Task 10: Importer characterization, idempotency, and drift tests

Spec R16, R17, R21, R22. **No converter code changes** — §D6 established empirically that the `#` grammar already round-trips. These tests turn that accident into a contract. A single-pass test would not have caught the historical `[[[AC-1]]]` bug; the idempotency loop would.

**Files:**
- Modify: `/workspace/vault/.obsidian/scripts/custom/jira-workitem-import/tests/test_jira_markup_converter.py`
- Modify: `/workspace/vault/.obsidian/scripts/custom/jira-bulk-import/tests/test_jira_markup_converter.py`

**Interfaces:**
- Consumes: Task 1's confirmed grammar
- Produces: nothing downstream

- [ ] **Step 1: Write the failing tests in the workitem tree**

Append to `jira-workitem-import/tests/test_jira_markup_converter.py`:

```python
import re
import pathlib

HASH_IDS = "[US#1] [AC#1] [SM#1] [SMC#1] [UC#3] [FR#2] [AD#1]"


def test_hash_form_ids_pass_through_untouched():
    conv = make_converter()
    assert conv.convert(HASH_IDS) == HASH_IDS


def test_hash_form_id_in_heading_survives():
    conv = make_converter()
    assert conv.convert("h3. [US#1]: Export the thing") == "### [US#1]: Export the thing"


def test_hash_form_id_in_table_cell_survives():
    conv = make_converter()
    out = conv.convert("||h1||h2||\n|[AC#1]|[US#2]|\n")
    assert "[AC#1]" in out and "[US#2]" in out
    assert "[[AC#1]]" not in out


def test_unbracketed_hash_id_is_not_linkified():
    conv = make_converter()
    assert conv.convert("Bare AC#2 outside brackets") == "Bare AC#2 outside brackets"


def test_real_key_still_linkifies_alongside_hash_ids():
    conv = make_converter()
    out = conv.convert("[AC#1] traces PRODUCT-456")
    assert out == "[AC#1] traces [[PRODUCT-456]]"


def _hostile_jira(md):
    """Model Jira's paste: linkify every issue key, ignoring markdown brackets."""
    return re.sub(r"\b([A-Z]{2,10}-\d+)\b", r"[\1|smart-link]", md)


def test_hash_ids_never_accumulate_brackets_over_rounds():
    """The historical bug: markdown -> Jira -> markdown grew brackets each round.

    A single-pass test cannot see it. Five rounds under a hostile Jira model can.
    """
    conv = make_converter()
    text = "- [AC#1] and [US#2] and [AD#3]\n"
    for _ in range(5):
        text = conv.convert(_hostile_jira(text))
    assert text.count("[") == 3
    assert text.count("]") == 3
    for token in ("[AC#1]", "[US#2]", "[AD#3]"):
        assert token in text


def test_converters_differ_only_in_known_hunks():
    """Guard against the two vendored copies drifting apart (spec Risk 6)."""
    here = pathlib.Path(__file__).resolve().parents[2]
    a = (here / "jira-workitem-import/src/jira_markup_converter.py").read_text().splitlines()
    b = (here / "jira-bulk-import/src/jira_markup_converter.py").read_text().splitlines()
    differing = [i for i, (x, y) in enumerate(zip(a, b)) if x.rstrip("\r") != y.rstrip("\r")]
    # Known differences: _format_issue_link body, and one comment describing it.
    assert len(differing) <= 6, f"converters drifted at lines {differing}"
```

- [ ] **Step 2: Run them and confirm they pass against current behaviour**

```bash
cd /workspace/vault/.obsidian/scripts/custom/jira-workitem-import
python3 -m pytest tests/test_jira_markup_converter.py -v
```
Expected: all tests PASS, including the 4 pre-existing ones. These are *characterization* tests — they lock in behaviour that already works. If any fails, the empirical finding in spec §D6 is wrong for this tree and the design needs revisiting before proceeding.

- [ ] **Step 3: Prove the idempotency test can actually fail**

A test that cannot fail proves nothing (spec Risk 3). Temporarily change `text.count("[") == 3` to `== 99`, re-run, confirm FAIL with a count of 3, then change it back and re-run to confirm PASS.

Run: `python3 -m pytest tests/test_jira_markup_converter.py::test_hash_ids_never_accumulate_brackets_over_rounds -v`

- [ ] **Step 4: Mirror the tests into the bulk tree**

Copy the same block into `jira-bulk-import/tests/test_jira_markup_converter.py`, with **one change**: that converter emits markdown links rather than wikilinks, so `test_real_key_still_linkifies_alongside_hash_ids` asserts:

```python
def test_real_key_still_linkifies_alongside_hash_ids():
    conv = make_converter()
    out = conv.convert("[AC#1] traces PRODUCT-456")
    assert out.startswith("[AC#1] traces [PRODUCT-456](")
    assert "/browse/PRODUCT-456" in out
```

Do **not** copy `test_converters_differ_only_in_known_hunks` into the bulk tree — one copy of a symmetric check is enough, and two would need to stay in sync themselves.

- [ ] **Step 5: Run the bulk suite**

```bash
cd /workspace/vault/.obsidian/scripts/custom/jira-bulk-import
python3 -m pytest tests/test_jira_markup_converter.py -v
```
Expected: all PASS.

- [ ] **Step 6: Commit (vault repo)**

The vault repo sits on `main` with a live shared remote and carries 3 pre-existing dirty files
unrelated to this work. Branch first, and stage by explicit path only — never `-A`.

```bash
cd /workspace/vault
git checkout -b iv-gu/jira-safe-requirement-ids
git add .obsidian/scripts/custom/jira-workitem-import/tests/test_jira_markup_converter.py \
        .obsidian/scripts/custom/jira-bulk-import/tests/test_jira_markup_converter.py
git commit -m "test(jira-import): lock [PREFIX#N] round-trip and bracket-accumulation guards"
```

Leave the 3 unrelated dirty files exactly as they are; do not stash, stage, or revert them.

---

### Task 11: Canonical release — version bump, CHANGELOG, full verification

Spec R20, plus the Risk 2 positive/negative controls that were deferred until real content existed.

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: Tasks 2–9 complete and green
- Produces: version `2.53.0`, the reference point Tasks 12–13 port to

- [ ] **Step 1: Run the Risk 2 positive control**

The collision rule must fire on real dash-form content:
```bash
cd /workspace/specs
grep -rlE '\[(US|AC|SM|AD|UC|FR)-[0-9]+\]' specifications | wc -l
```
Expected: `19`. Record the per-file hit counts BEFORE inspecting them, then confirm each hit is a requirement ID and not a real Jira key.

- [ ] **Step 2: Run the Risk 2 negative control**

```bash
cd /workspace/ihudak-claude-plugins
./scripts/check-id-grammar.sh --root scripts/fixtures/vi-good.md
```
Expected: `PASS` — the fixture's `[[PRODUCT-123]]` and `[[MGD-8605]]` are real keys and must not be flagged. A rule that only ever fires has not been tested.

- [ ] **Step 3: Bump the version in both JSON files**

`plugins/dev-workflows/.claude-plugin/plugin.json`: `"version": "2.52.0"` → `"version": "2.53.0"`.
`.claude-plugin/marketplace.json`: same bump in the `dev-workflows` entry.

**Do not touch either `description` field.** The hard budget is 1024 characters and the check fails the whole catalog above it; this change adds no capability that belongs in a capability blurb.

- [ ] **Step 4: Validate the catalog**

Run: `python3 scripts/validate-catalog.py`
Expected: exit 0, no warnings.

- [ ] **Step 5: Add the CHANGELOG entry**

Prepend under a new `## 2.53.0` heading:
```markdown
### Changed
- VI, ARD, and Epic requirement IDs now use `[PREFIX#N]` (`[AC#1]`, `[US#1]`, `[AD#1]`) instead of
  `[AC-1]`. The dash form has the shape of a Jira issue key, so pasting an artifact into Jira
  auto-linked criteria to unrelated tickets in any project sharing the prefix, and the vault
  importer rewrote them into `[[[AC-1]]]` on export.
- `epic-writer`'s `## Covers` now emits bracketed IDs; it previously emitted bare `US-2, AC-4`,
  which both Jira and the importer mangled.
- `jira-reader` accepts both forms inside requirement-bearing sections and always emits `#`, so
  already-published VIs still parse.

### Added
- `pre-lint.md` gains a Jira-key collision check for VI / ARD / Epic files.
- `scripts/check-id-grammar.sh` gates the repo against reintroducing the dash form.
```

- [ ] **Step 6: Full-tree gate + spec-namespace diff**

Run:
```bash
./scripts/check-id-grammar.sh --root .
grep -rhoE '\[U0[0-9]+\]|\[AC0[0-9]+\]|\[TC0[0-9]+\]|\[Uxx\]|\[ACxx\]|\[TCxx\]' \
  --include='*.md' plugins/ CLAUDE.md | sort | uniq -c | diff scripts/spec-id-baseline.txt - \
  && echo "SPEC NAMESPACE INTACT"
```
Expected: `PASS` and an empty diff.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(dev-workflows): 2.53.0 — Jira-safe requirement IDs"
```

---

### Task 12: Port to the mgd edition

Spec R18–R20. Same layout as canonical, 23 files. **Never blind-`cp`** — five identity files carry mgd-specific claims that a copy would overwrite.

**Files:**
- Modify: `/workspace/mgd-claude-plugins/plugins/dev-workflows/**` (23 files)
- Create: `/workspace/mgd-claude-plugins/scripts/check-id-grammar.sh` + fixtures

**Interfaces:**
- Consumes: the canonical edit set from Tasks 3–9
- Produces: mgd 2.53.0

- [ ] **Step 1: Branch and confirm the starting state**

```bash
cd /workspace/mgd-claude-plugins
git checkout -b iv-gu/jira-safe-requirement-ids
grep -rlE '\[(US|AC|SM|AD|UC|FR)-[N0-9]+\]|\b(US|AC|SM|AD|UC|FR)-[Nn0-9]+\b' --include='*.md' plugins/dev-workflows | wc -l
```
Expected: `23`.

- [ ] **Step 2: Copy the gate script and fixtures (these are edition-neutral)**

```bash
mkdir -p scripts/fixtures
cp /workspace/ihudak-claude-plugins/scripts/check-id-grammar.sh scripts/
cp /workspace/ihudak-claude-plugins/scripts/fixtures/vi-*.md scripts/fixtures/
chmod +x scripts/check-id-grammar.sh
./scripts/check-id-grammar.sh --root plugins/
```
Expected: `FAIL` — the red state to drive green.

- [ ] **Step 3: Apply the content edits file by file**

For each of the 23 files, apply the same prefix mapping as Tasks 3–9. Re-derive each edit against **mgd's own text** — do not copy canonical file bodies. Where mgd's wording differs from canonical, keep mgd's wording and change only the ID tokens.

- [ ] **Step 4: Handle the identity files individually**

`README.md`, `CLAUDE.md` (if present), `plugin.json`, `marketplace.json`, `CHANGELOG.md` are excluded from any copy and must each be opened and edited on their own. This is where cross-repo fixes die. Check each explicitly:
```bash
./scripts/check-id-grammar.sh --root README.md
[ -f CLAUDE.md ] && ./scripts/check-id-grammar.sh --root CLAUDE.md
```

- [ ] **Step 5: Bump to 2.53.0 and add the CHANGELOG entry**

Same version bump and CHANGELOG text as Task 11 Steps 3 and 5, adjusted for any mgd-specific wording. Descriptions untouched.

- [ ] **Step 6: Full-tree gate**

Run: `./scripts/check-id-grammar.sh --root .`
Expected: `PASS`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(dev-workflows): Jira-safe requirement IDs — 2.53.0"
```

---

### Task 13: Port to the copilot edition

Spec R18–R20. **Different layout** — `commands/*.md` become `skills/<name>/SKILL.md`, `references/` becomes `skills/_shared/`. Never `cp` into copilot at all; four dialect rules apply, including colon-form command names.

**Files:**
- Modify: `/workspace/ihudak-copilot-plugins/dev-workflows/**` (23 files, listed below)
- Create: `/workspace/ihudak-copilot-plugins/scripts/check-id-grammar.sh` + fixtures

**Interfaces:**
- Consumes: the canonical edit set
- Produces: copilot 2.23.0

- [ ] **Step 1: Branch and confirm the starting state**

```bash
cd /workspace/ihudak-copilot-plugins
git checkout -b iv-gu/jira-safe-requirement-ids
grep -rlE '\[(US|AC|SM|AD|UC|FR)-[N0-9]+\]|\b(US|AC|SM|AD|UC|FR)-[Nn0-9]+\b' --include='*.md' dev-workflows | sort
```
Expected, exactly these 23:
```
dev-workflows/CHANGELOG.md            <- history, do NOT edit
dev-workflows/README.md
dev-workflows/agents/ard-reviewer.md
dev-workflows/agents/code-review.md
dev-workflows/agents/design-reviewer.md
dev-workflows/agents/epic-reviewer.md
dev-workflows/agents/epic-writer.md
dev-workflows/agents/jira-reader.md
dev-workflows/agents/readiness-reviewer.md
dev-workflows/agents/spec-reviewer.md
dev-workflows/agents/vi-reviewer.md
dev-workflows/skills/_shared/ard-format.md
dev-workflows/skills/_shared/ard-resolution.md
dev-workflows/skills/_shared/handoff/jira-reader.md
dev-workflows/skills/_shared/pre-lint.md
dev-workflows/skills/_shared/vi-format.md
dev-workflows/skills/create-ard/SKILL.md
dev-workflows/skills/create-vi/SKILL.md
dev-workflows/skills/design/SKILL.md
dev-workflows/skills/epics/SKILL.md
dev-workflows/skills/implement/SKILL.md
dev-workflows/skills/ready/SKILL.md
dev-workflows/skills/update-vi/SKILL.md
```

- [ ] **Step 2: Install the gate**

```bash
mkdir -p scripts/fixtures
cp /workspace/ihudak-claude-plugins/scripts/check-id-grammar.sh scripts/
cp /workspace/ihudak-claude-plugins/scripts/fixtures/vi-*.md scripts/fixtures/
chmod +x scripts/check-id-grammar.sh
./scripts/check-id-grammar.sh --root dev-workflows/
```
Expected: `FAIL`.

- [ ] **Step 3: Apply the content edits, re-deriving each against copilot's own text**

Map canonical → copilot paths: `references/X.md` → `skills/_shared/X.md`; `commands/<name>.md` → `skills/<name>/SKILL.md`. Content is authored fresh per copilot's dialect rules; only the ID tokens are being changed here, so preserve every other difference exactly as it stands.

- [ ] **Step 4: Handle `README.md` individually**

Copilot has no root `CLAUDE.md`; `README.md` carries the equivalent claims.
Run: `./scripts/check-id-grammar.sh --root dev-workflows/README.md`
Expected: `PASS` after editing.

- [ ] **Step 5: Bump to 2.23.0 and add the CHANGELOG entry**

Same content as Task 11 Step 5, in copilot's CHANGELOG voice. Descriptions untouched — the 1024-character budget is Copilot CLI's own limit and it rejects the whole catalog above it.

- [ ] **Step 6: Full-tree gate**

Run: `./scripts/check-id-grammar.sh --root .`
Expected: `PASS`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(dev-workflows): Jira-safe requirement IDs — 2.23.0"
```

---

### Task 14: Cross-edition verification

Spec Risk 4's mechanical check. Inspection can miss a fix that died in one edition's identity file; three identical empty result sets cannot.

**Files:** none (verification only)

**Interfaces:**
- Consumes: Tasks 11–13 complete
- Produces: the evidence that ships the change

- [ ] **Step 1: Run the gate in all three editions and diff the results**

```bash
for r in /workspace/ihudak-claude-plugins /workspace/mgd-claude-plugins /workspace/ihudak-copilot-plugins; do
  echo "===== $r"
  ( cd "$r" && ./scripts/check-id-grammar.sh --root . )
done
```
Expected: three `PASS` lines. Any `FAIL` names the edition and file where the fix died.

- [ ] **Step 2: Confirm the dash form is genuinely gone, CHANGELOGs excepted**

```bash
for r in /workspace/ihudak-claude-plugins /workspace/mgd-claude-plugins /workspace/ihudak-copilot-plugins; do
  echo -n "$r: "
  ( cd "$r" && grep -rlE '\[(US|AC|SM|AD|UC|FR)-[N0-9]+\]' --include='*.md' \
      --exclude='CHANGELOG.md' --exclude-dir=docs . | wc -l )
done
```
Expected: `0` for all three.

- [ ] **Step 3: Confirm the CHANGELOGs kept their history**

```bash
for r in /workspace/ihudak-claude-plugins /workspace/mgd-claude-plugins /workspace/ihudak-copilot-plugins; do
  echo -n "$r CHANGELOG dash-form sites: "
  ( cd "$r" && grep -rcE '\b(US|AC|SM|AD|UC|FR)-[0-9N]+\b' --include='CHANGELOG.md' . | paste -sd+ | bc )
done
```
Expected: non-zero for all three. A zero means history was rewritten — revert it.

- [ ] **Step 4: Re-run both importer suites**

```bash
for t in jira-workitem-import jira-bulk-import; do
  echo "===== $t"
  ( cd "/workspace/vault/.obsidian/scripts/custom/$t" && python3 -m pytest tests/ -q )
done
```
Expected: all green in both.

- [ ] **Step 5: Reinstall and smoke-test the plugin**

```bash
claude plugin reinstall dev-workflows@ihudak-plugins
```
Then confirm the installed copy carries the new grammar:
```bash
grep -rn 'AC#N' ~/.claude/plugins/cache/*/dev-workflows/2.53.0/references/vi-format.md
```
Expected: at least one hit.

- [ ] **Step 6: Report**

Summarise for the user: the three editions' gate results, the 19 unmigrated `$SPECS_PATH` files left to drain per spec §D7, and the residual 7 real-key bracket instances left out of scope per §11.

---

## Deferred (explicitly out of scope — spec §11)

- Migrating the 19 dash-form artifacts under `$SPECS_PATH` — they convert when `/update-vi` next touches them.
- Cleaning the 25 vault files carrying `[[[AC-1]]]` scars — imported snapshots, regenerated on next import.
- The 7 residual real-key `[[[PRODUCT-123]]]` instances — pre-existing converter issue, bounded at depth 4.
- De-duplicating the two vendored `jira_markup_converter.py` copies — Task 10's drift guard detects it; fixing it is separate work.

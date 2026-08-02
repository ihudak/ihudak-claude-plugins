---
tags:
  - tasks-exclude
---

# ARD-consumption wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/design`, `/implement`, `/specify` read and respect the applicable ARD's `AD-N` invariants (v2.18.0), gracefully no-op'ing when no ARD exists.

**Architecture:** A new shared `references/ard-resolution.md` resolves the applicable ARD(s) → a normalized context or `none`. Each consumer resolves early and passes the invariants to its reviewer as an optional `applicable_ard`; each reviewer gains one **conditional** ARD-conformance dimension (skipped when absent → byte-identical). Enforcement is binding + deviation-record.

**Tech Stack:** Markdown command/agent/reference files; JSON manifests; `python3` (stdlib). NO test framework — verification is **structural** (grep anchors, `python3 json.load`, byte-diff).

## Global Constraints

- **Strictly no-regression.** When `ard-resolution.md` returns `status: none`, every consumer behaves **byte-identically** to today. All ARD steps are additive and guarded on `status: found`.
- **`code-review` is SHARED** (`/implement` + `/vuln` + `/upgrade`). Its new dimension is **conditional on the caller passing `applicable_ard`**; `/vuln` + `/upgrade` never pass it and are **not modified** — verify `git diff --stat main -- commands/vuln.md commands/upgrade.md` is empty.
- **Version lock-step 2.18.0** in plugin.json + the marketplace.json dev-workflows entry; the two `description` strings stay **byte-identical** (description text is unchanged — only the version field moves; **no new command/subagent**, so counts + feedback/cost enums are untouched).
- **Siblings untouched:** `dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1.
- **Commit named files only — NEVER `git add -A`.** Branch `ivgu/NOISSUE-ard-consumption`. Trailer EXACTLY: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. **Push only when the user asks.**
- Watch for lima read-after-write git flakiness (fsck-first, `update-ref` the dangling commit if a ref-write fails; verify HEAD after each).

---

## File Structure

**New (1):** `references/ard-resolution.md` (resolver + deviation convention).
**Modified (10):** `agents/design-reviewer.md` + `agents/spec-reviewer.md` + `agents/code-review.md` (conditional dimension); `commands/design.md` + `commands/specify.md` + `commands/implement.md` (resolve ARD + pass `applicable_ard`); `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` (version only); `CHANGELOG.md`; `README.md`.

All paths relative to repo root `/workspace/ihudak-claude-plugins`.

---

### Task 1: `references/ard-resolution.md` (shared resolver SSOT)

**Files:** Create `plugins/dev-workflows/references/ard-resolution.md`
**Interfaces:** Produces the resolution contract (`status`/`invariants`/`guidance_summary`) + the deviation-record convention that Task 2 (reviewers) and Task 3 (consumers) rely on.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
# ARD resolution (embedded — shared reference)

Given a Jira item, resolve any applicable **Architecture Requirements/Decision Document(s)** produced by
`/create-ard` and return a normalized **ARD context** — or **`none`**. Cited by `/design`, `/implement`,
and `/specify` so the resolution logic, the **optional/no-regression** rule, and the deviation-record
convention live in ONE place.

## Inputs

`vi` (VI key), `epic` (or `null`), `area` (or `null`), `$SPECS_PATH`.

## Resolution (most-specific first)

1. Resolve the VI dir `$SPECS_PATH/specifications/<VI>-<vslug>/` — match by key-number, tolerating a
   stray `-`/`_` and a human-adjusted slug (the same rule the other commands use).
2. Collect candidate ARD files:
   - **Epic-level** (`epic` set): `<VI>-<vslug>/<EPIC>-<eslug>/<EPIC>_ARD.md` and any
     `<EPIC>-<area>_ARD.md` (the area-scoped file when `area` is given, else every per-area ARD) **plus**
     the VI-level `<VI>-<vslug>/<VI>_ARD.md` for inherited invariants.
   - **VI-level** (`epic` null): only `<VI>-<vslug>/<VI>_ARD.md`.
3. Parse each file's `## Architecture decisions` into `AD-N {id, binds, prevents, rule, source}` where
   `source` ∈ `vi | epic | area`. VI-level `AD-N` are the inherited base; Epic/area `AD-N` layer on top
   (Epic/area wins on any conflict — contradictions were already blocked by `ard-reviewer` at authoring).

## Output — the ARD context, or `none`

```yaml
status: found | none
ard_paths: [ <absolute paths of the ARD files used> ]
invariants:
  - id: AD-1
    source: vi | epic | area
    binds: <text>
    prevents: <text>
    rule: <testable statement>
guidance_summary: <short prose: the ARD's non-AD-N architecture guidance the consumer should heed>
```

`status: none` when no ARD file resolves (the common case — `/create-ard` is optional).

## No-regression rule (central)

A caller that gets `status: none` **MUST behave exactly as it did before this feature** — no prompt, no
extra phase output, no reviewer dimension. The ARD steps are strictly additive and guarded on
`status: found`.

## Deviation-record convention

When an artifact must NOT honor an `AD-N`, the consumer records — in its **own** artifact, NEVER in the
ARD (role separation: the ARD is the architect's) — a line:

`- ARD deviation: [<AD-N id>] — <what deviates> — <why> — flag: architect`

and surfaces it in the run's final report. A reviewer treats a violating artifact **with** a matching
deviation record as *allowed-but-flagged* (the architect adjudicates), **without** one as a **BLOCKER**.

## Consumers (informative)

- `/design` — Epic-level ARD = design guidance; VI-level `AD-N` = inherited invariants; deviations → a `## ARD deviations` section in `design.md` + an open question.
- `/implement` — Jira mode only; `AD-N` = implementation guardrails; deviations → the Phase 5 report. Direct mode → `none`.
- `/specify` — keep user stories + scope consistent with `AD-N` + scope; deviations → the spec's `### Open questions`.

Each passes `invariants` to its reviewer as `applicable_ard`; the reviewer's ARD-conformance dimension is
skipped entirely when it is absent.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/references/ard-resolution.md
grep -q "^# ARD resolution" "$f" && grep -q "status: found | none" "$f" \
  && grep -q "guidance_summary" "$f" && grep -q "most-specific first" "$f" \
  && grep -q "No-regression rule" "$f" && grep -q "ARD deviation: \[<AD-N id>\]" "$f" \
  && grep -q "NEVER in the" "$f" && echo "OK ard-resolution"
git add plugins/dev-workflows/references/ard-resolution.md
git commit -m "feat(ard): add shared ard-resolution reference (SSOT)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: `OK ard-resolution`

---

### Task 2: Conditional ARD-conformance dimension in the three reviewers

**Files:** Modify `agents/design-reviewer.md`, `agents/spec-reviewer.md`, `agents/code-review.md`
**Interfaces:** Consumes Task 1's `invariants` shape (passed by callers as `applicable_ard`). The dimension is conditional — skipped when `applicable_ard` is absent (no-regression; keeps `/vuln`+`/upgrade` untouched via `code-review`).

- [ ] **Step 1: `agents/design-reviewer.md`** — add the input, then the check.

Insert the `applicable_ard` input by replacing the `## Review method` header (first occurrence):
> Original: `## Review method`
> New:
> ```
> - **`applicable_ard`** (optional) — the resolved ARD `AD-N` invariants (`id`/`binds`/`prevents`/`rule`) when `/design` resolved an ARD (Phase 2.5); absent when no ARD exists. Enables the conditional ARD-conformance check below.
> 
> ## Review method
> ```

Add the check by replacing the `## Output contract` header (first occurrence):
> Original: `## Output contract`
> New:
> ```
> - **ARD conformance (conditional — only when `applicable_ard` is provided; otherwise skip silently):** the design must honor every `AD-N` `rule`. A violation with **no** matching recorded `## ARD deviations` entry → `BLOCKER`; **with** a recorded deviation → `MINOR` flagged note (the architect adjudicates).
> 
> ## Output contract
> ```

- [ ] **Step 2: `agents/spec-reviewer.md`** — same pattern.

Insert the input by replacing `## Review method` (first occurrence):
> New:
> ```
> - **`applicable_ard`** (optional) — the resolved ARD `AD-N` invariants when `/specify` resolved an ARD (Phase 2.5); absent when no ARD exists. Enables the conditional ARD-conformance check below.
> 
> ## Review method
> ```

Add the check by replacing `## Output contract` (first occurrence):
> New:
> ```
> - **ARD conformance (conditional — only when `applicable_ard` is provided; otherwise skip silently):** no user story / scope item / AC may contradict an `AD-N` `rule`. A contradiction with **no** recorded `### Open questions` ARD-deviation entry → `BLOCKER`; **with** one → `MINOR` flagged note.
> 
> ## Output contract
> ```

- [ ] **Step 3: `agents/code-review.md`** — SHARED agent; the dimension is gated on `applicable_ard`.

(a) Add the input — replace `Refuse to review without a diff - ask the caller to produce one.`:
> New:
> ```
> Refuse to review without a diff - ask the caller to produce one.
> 
> - **`applicable_ard`** (optional) — the resolved ARD `AD-N` invariants, passed only by `/implement` (Jira mode) when an ARD exists. Absent for `/vuln`, `/upgrade`, `/implement` direct mode, and when no ARD exists — in which case the conditional ARD-conformance dimension (below) does not apply and is not mentioned.
> ```

(b) Update the dimension-count wording — replace `3. Check each of the eight dimensions below. Skip dimensions that are clearly`:
> New: `3. Check each of the eight dimensions below (plus the conditional ninth, **only** when \`applicable_ard\` is provided). Skip dimensions that are clearly`

(c) Add dimension 9 — replace the dimension-8 block `8. **Rollback considerations** - how do we revert this? Reversible or not?\n   Any irreversible side effects (data deletion, external calls, cache\n   invalidation, schema drop)? If it fails in prod, what's the undo?`:
> New (append the ninth after it):
> ```
> 8. **Rollback considerations** - how do we revert this? Reversible or not?
>    Any irreversible side effects (data deletion, external calls, cache
>    invalidation, schema drop)? If it fails in prod, what's the undo?
> 9. **ARD conformance** (conditional — only when `applicable_ard` is provided;
>    otherwise this dimension does not apply — omit it silently) - does the diff
>    honor every `AD-N` `rule`? A violation with no recorded ARD-deviation (in the
>    caller's report) → `BLOCKER`; with a recorded deviation → `MAJOR` flagged note.
> ```

(d) Add the output section — replace `#### Rollback considerations\n- ...\n\n### Recommended next step`:
> New:
> ```
> #### Rollback considerations
> - ...
> 
> #### ARD conformance (only if applicable_ard provided)
> - ...
> 
> ### Recommended next step
> ```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
for a in design-reviewer spec-reviewer code-review; do grep -q "applicable_ard" plugins/dev-workflows/agents/$a.md || { echo "MISSING input: $a"; exit 1; }; done
grep -q "ARD conformance (conditional" plugins/dev-workflows/agents/design-reviewer.md \
  && grep -q "ARD conformance (conditional" plugins/dev-workflows/agents/spec-reviewer.md \
  && grep -q "9. \*\*ARD conformance\*\*" plugins/dev-workflows/agents/code-review.md \
  && grep -q "eight dimensions below (plus the conditional ninth" plugins/dev-workflows/agents/code-review.md \
  && grep -q "#### ARD conformance (only if applicable_ard provided)" plugins/dev-workflows/agents/code-review.md \
  && echo "OK reviewers"
git add plugins/dev-workflows/agents/design-reviewer.md plugins/dev-workflows/agents/spec-reviewer.md plugins/dev-workflows/agents/code-review.md
git commit -m "feat(ard): add conditional ARD-conformance dimension to design/spec/code reviewers

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: `OK reviewers`

---

### Task 3: Wire the three consumers to resolve + pass the ARD

**Files:** Modify `commands/design.md`, `commands/specify.md`, `commands/implement.md`
**Interfaces:** Consumes `references/ard-resolution.md` (T1) + the reviewers' `applicable_ard` input (T2).

- [ ] **Step 1: `commands/design.md`** — add Phase 2.5 (before Phase 3) by replacing `## Phase 3 — Derive repos + STRICT gate`:
> New:
> ```
> ## Phase 2.5 — Resolve applicable ARD (optional)
> 
> Resolve any ARD for this item by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `<VI>`, `<EPIC>` (`focus_key`), and `$SPECS_PATH`. On `status: none`, **skip the rest of this phase and proceed exactly as before** (no ARD in play). On `status: found`, carry the returned `invariants` (VI-level inherited + Epic-level `AD-N`) and `guidance_summary` into Phase 5 — the design is authored **within** them, and a necessary deviation is recorded in a `## ARD deviations` section of `design.md` + as a `- [ ]` open question (never edit the ARD). The `invariants` list is passed to `design-reviewer` in Phase 6 as `applicable_ard`.
> 
> ---
> 
> ## Phase 3 — Derive repos + STRICT gate
> ```

Then pass it to the reviewer — replace `  > Classification:     [the Phase 1.5 classification]"`:
> New: `  > Classification:     [the Phase 1.5 classification]\n  > applicable_ard:     [the ARD invariants resolved in Phase 2.5, or omit if none]"`

- [ ] **Step 2: `commands/specify.md`** — add Phase 2.5 (before Phase 3) by replacing `## Phase 3 — Derive repos + soft gate`:
> New:
> ```
> ## Phase 2.5 — Resolve applicable ARD (optional)
> 
> Resolve any ARD for this item by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `<VI>`, `<EPIC>` (`focus_key`), and `$SPECS_PATH`. On `status: none`, **skip and proceed exactly as before**. On `status: found`, keep the spec's user stories + scope consistent with the returned `invariants` + `guidance_summary` during the Phase 5 grill; record a necessary deviation under the spec's `### Open questions` (never edit the ARD). Pass the `invariants` to `spec-reviewer` in Phase 6 as `applicable_ard`.
> 
> ---
> 
> ## Phase 3 — Derive repos + soft gate
> ```

Then pass it to the reviewer — replace `  > Detected maturity: test"`:
> New: `  > Detected maturity: test\n  > applicable_ard: [the ARD invariants resolved in Phase 2.5, or omit if none]"`

- [ ] **Step 3: `commands/implement.md`** — add Phase 1.8 (before Phase 2A) by replacing `## Phase 2A — Standard Plan (SIMPLE / MODERATE only)`:
> New:
> ```
> ## Phase 1.8 — Resolve applicable ARD (Jira mode; optional)
> 
> Only when the run resolved a Jira key (VI/Epic) — i.e. NOT direct-prompt mode — resolve any ARD by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with the resolved `<VI>`, `<EPIC>`, and `$SPECS_PATH`. Direct mode (no Jira key) → treat as `status: none`. On `status: none`, **skip and proceed exactly as before**. On `status: found`, carry the `invariants` as **implementation guardrails** (the implementer honors each `AD-N` `rule`; a necessary deviation is logged as an `- ARD deviation:` line in the Phase 5 report), and — in the SIGNIFICANT / HIGH-RISK path — pass them to `code-review` (Phase 3B) as `applicable_ard`. In the SIMPLE / MODERATE path there is no `code-review` gate, so the guardrails act as guidance only.
> 
> ---
> 
> ## Phase 2A — Standard Plan (SIMPLE / MODERATE only)
> ```

Then pass it to the reviewer — replace `     > Diff: [paste git diff output]\n     > Project root: [absolute path]"`:
> New: `     > Diff: [paste git diff output]\n     > Project root: [absolute path]\n     > applicable_ard: [the ARD invariants from Phase 1.8, or omit if none / direct mode]"`

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
for c in design specify implement; do grep -q "references/ard-resolution.md" plugins/dev-workflows/commands/$c.md || { echo "MISSING cite: $c"; exit 1; }; done
grep -q "## Phase 2.5 — Resolve applicable ARD" plugins/dev-workflows/commands/design.md \
  && grep -q "## Phase 2.5 — Resolve applicable ARD" plugins/dev-workflows/commands/specify.md \
  && grep -q "## Phase 1.8 — Resolve applicable ARD" plugins/dev-workflows/commands/implement.md \
  && grep -c "applicable_ard" plugins/dev-workflows/commands/design.md | grep -qx 2 \
  && grep -q "applicable_ard:     \[the ARD invariants resolved in Phase 2.5" plugins/dev-workflows/commands/design.md \
  && grep -q "applicable_ard: \[the ARD invariants resolved in Phase 2.5" plugins/dev-workflows/commands/specify.md \
  && grep -q "applicable_ard: \[the ARD invariants from Phase 1.8" plugins/dev-workflows/commands/implement.md \
  && echo "OK consumers"
git add plugins/dev-workflows/commands/design.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/implement.md
git commit -m "feat(ard): /design + /specify + /implement resolve and respect the ARD

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: `OK consumers`

---

### Task 4: Version bump + manifests + CHANGELOG

**Files:** Modify `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/dev-workflows/CHANGELOG.md`

- [ ] **Step 1: plugin.json** — `"version": "2.17.0"` → `"version": "2.18.0"` (description unchanged).

- [ ] **Step 2: marketplace.json** — in the `dev-workflows` entry ONLY: `"version": "2.17.0"` → `"version": "2.18.0"` (description unchanged; siblings `dt-style-guide` 0.2.2 / `obsidian-llm-wiki` 0.3.1 untouched).

- [ ] **Step 3: CHANGELOG.md** — insert directly above `## [2.17.0] — 2026-07-10`:

```markdown
## [2.18.0] — 2026-07-10

### Added

- **`/design`, `/implement`, and `/specify` now respect the ARD produced by `/create-ard`.** A new shared `references/ard-resolution.md` resolves the applicable ARD(s) for a `<VI>` (+ optional `<Epic>`/area) — most-specific first (per-area → Epic-level → inherited VI-level `AD-N`) — and returns a normalized context or **`none`**. Each consumer resolves early and passes the `AD-N` invariants to its reviewer as an optional `applicable_ard`; `design-reviewer`, `spec-reviewer`, and the shared `code-review` gain a **conditional** "ARD conformance" dimension that checks the artifact honors every `AD-N` `Rule`. Enforcement is **binding + deviation-record**: a violation with no recorded "ARD deviation" (flagged to the architect, in the consumer's own artifact — never the ARD) is a reviewer **BLOCKER**; a recorded deviation is allowed-but-flagged. **Strictly no-regression:** when no ARD resolves (the common case — `/create-ard` is optional) every command behaves byte-identically to before, and the reviewer dimension is skipped. Because `code-review` is shared, its dimension is gated on the caller passing `applicable_ard` — **`/vuln` and `/upgrade` never do and are not modified**. No new command or subagent (version-only manifest bump). Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched. **Follow-ups:** next-phase-offer-everywhere; revisit the `.obsidian/` vault-check.
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print(json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])" | grep -qx 2.18.0
python3 -c "import json;m={p['name']:p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']};a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));assert m['dev-workflows']['version']=='2.18.0';assert m['dt-style-guide']['version']=='0.2.2';assert m['obsidian-llm-wiki']['version']=='0.3.1';assert m['dev-workflows']['description']==a['description'],'descriptions differ';print('json+lockstep OK')"
head -12 plugins/dev-workflows/CHANGELOG.md | grep -q "## \[2.18.0\] — 2026-07-10"
echo "OK manifests+changelog"
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(release): dev-workflows 2.18.0 (ARD consumption)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: `json+lockstep OK` then `OK manifests+changelog`.

---

### Task 5: README — ARD-consumption note

**Files:** Modify `plugins/dev-workflows/README.md`

- [ ] **Step 1: Insert a subsection** immediately **before** `## Dependencies & companions` (a stable anchor added in v2.15.0). Replace `## Dependencies & companions`:
> New:
> ```
> ## Architecture (ARD) consumption
> 
> `/design`, `/implement`, and `/specify` respect the applicable **ARD** (produced by `/create-ard`) when one exists — resolved via `references/ard-resolution.md` (most-specific first: per-area → Epic-level → inherited VI-level `AD-N`). A design / implementation / spec that violates an `AD-N` Rule without a recorded "ARD deviation" (flagged to the architect) is a reviewer **BLOCKER**. When no ARD exists these commands behave exactly as before — the check is skipped — and `/vuln` / `/upgrade` are unaffected.
> 
> ## Dependencies & companions
> ```

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
r=plugins/dev-workflows/README.md
grep -q "## Architecture (ARD) consumption" "$r" \
  && grep -q "respect the applicable \*\*ARD\*\*" "$r" \
  && grep -q "behave exactly as before" "$r" && echo "OK readme"
git add plugins/dev-workflows/README.md
git commit -m "docs(readme): note ARD consumption by design/implement/specify

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: `OK readme`

---

## Whole-branch verification (after all tasks)

```bash
cd /workspace/ihudak-claude-plugins
# THE critical no-regression check — /vuln + /upgrade + all untouched files:
git diff --stat main -- plugins/dev-workflows/commands/vuln.md plugins/dev-workflows/commands/upgrade.md plugins/dev-workflows/agents/ard-reviewer.md plugins/dev-workflows/references/ard-format.md   # expect: no output
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki   # expect: no output
python3 -c "import json;a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));m={p['name']:p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']};assert a['version']=='2.18.0'==m['dev-workflows']['version'];assert a['description']==m['dev-workflows']['description'];print('lockstep OK')"
git diff --stat main    # expect: 1 new + 10 modified = 11 files
```
Expected: no vuln/upgrade/ard-producer/sibling diff; `lockstep OK`; 11 files changed.

Then finish via **superpowers:finishing-a-development-branch** (no tests — structural verification above is the gate): present merge/PR/keep/discard; **push only when the user asks**.

---

## Self-Review (against the spec)

**Spec coverage:** shared `ard-resolution.md` incl. output keys + no-regression rule + deviation convention (T1) ✓; conditional reviewer dimension on all three reviewers incl. shared-code-review gating (T2) ✓; consumer wiring — resolve early + inject + pass `applicable_ard`, `/implement` Jira-only + direct→none (T3) ✓; binding + deviation-record enforcement (T1 convention + T2 severities + T3 deviation homes) ✓; version-only bump, counts/enums unchanged (T4) ✓; README note (T5) ✓; `/vuln`+`/upgrade`+`ard-format.md`+`/create-ard` untouched (whole-branch check) ✓.

**Placeholder scan:** none — full content for `ard-resolution.md`; exact old→new for every edit.

**Type consistency:** the resolver output keys (`status`/`invariants`{`id`/`binds`/`prevents`/`rule`/`source`}/`guidance_summary`) match what the consumers pass as `applicable_ard` and what the reviewers check; the deviation-record line format is identical across the resolver convention, the reviewer checks, and the consumer homes; `Phase 2.5` (design/specify) and `Phase 1.8` (implement) are the cited resolution phases referenced by their reviewer-dispatch edits.
```
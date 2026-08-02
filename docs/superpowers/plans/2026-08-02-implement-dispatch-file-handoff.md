# /implement dispatch file-handoff — Implementation Plan

> **For agentic workers:** Prose refactor to markdown command/agent files (no code test cycle).
> Execute inline (edits are exact `old → new` string replacements), then run the independent
> **Opus whole-branch review** as the gate, then merge/push per user. Steps use `- [ ]` tracking.

**Goal:** Extend the existing `/document` + `/epics` `mktemp` handoff pattern to `/implement`'s
in-loop dispatches so the four large blobs (codebase summary, plan, diff, code-review report) are
written to temp files and handed as **paths**, not pasted inline.

**Architecture:** Design A (surgical per-artifact). Only the big blobs move to `mktemp` files (in
`$TMPDIR`, outside every repo tree → no `git diff` pollution); small scalars stay inline. Each
consuming agent gets one additive `## Inputs` line: the field may be inline *or* an absolute path
to `Read`. Behavior-preserving — agents receive identical content, relocated.

**Tech Stack:** Markdown command/agent files; `mktemp` shell idiom (identical across Claude &
Copilot CLIs). Validation via `claude plugin validate` + grep proofs + byte-identity checks.

## Global Constraints

- **Behavior-preserving:** no change to any gate, branch, interrupt, classification, or model
  routing — only the four dispatch fields and the capture/write steps that feed them.
- **No diff pollution:** every handoff file is `mktemp` (never inside a repo working tree).
- **No cleanup step** (matches doc-writer/epic-writer precedent — ephemeral `$TMPDIR`).
- **Three-edition parity:** canonical → mgd verbatim copy (verify byte-identity pre-change);
  Copilot conversion (`${CLAUDE_PLUGIN_ROOT}`→`~/.copilot/…/skills/_shared/`, `/design`→`design:`,
  "Claude Opus"→"strong reasoning tier"). **Zero new `${CLAUDE_PLUGIN_ROOT}` in Copilot.**
- Do **NOT** edit `references/specification-format.md` (frozen).
- **Version:** PATCH — canonical/mgd 2.39.1→2.39.2, Copilot 2.9.1→2.9.2. CHANGELOG **Changed**.
- **Pushes held.** Trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Uniform added-note wording: **"Provided inline or as an absolute file path — `Read` the file
  first when given a path."**

## File Structure

- `plugins/dev-workflows/commands/implement.md` — 11 edits (C1–C11) across Phase 1.7/2A/2B/3B/3.5.
- `plugins/dev-workflows/agents/{risk-planner,test-writer,code-review,review-fixer}.md` — 1 note each.
- mgd `plugins/dev-workflows/{commands/implement.md,agents/*.md}` — verbatim copy of the 5 files.
- Copilot `dev-workflows/skills/implement/SKILL.md` + `dev-workflows/agents/*.md` — converted.
- Version manifests + CHANGELOGs in all 3.

---

### Task 1: Canonical `commands/implement.md` — the 11 dispatch/capture edits

**File:** `plugins/dev-workflows/commands/implement.md`. Apply as exact string replacements.

- [ ] **C1 — Phase 1.7 step 4 (Synthesize):** append to the bullet ending `…do **not** also run the
  single Explore subagent.`:
  `Write this summary to a temp file (\`mktemp -t dw-impl-summary-XXXX.md\` — **never inside a repo working tree**, so a captured \`git diff\` never picks it up) and record its absolute path as \`summary_file\`; Phase 2B receives this path, not the pasted summary.`

- [ ] **C2 — Phase 2B "Codebase exploration":** replace `use its **multi-source codebase summary** as the codebase context and skip the single Explore subagent. Otherwise, run the same exploration subagent call as Phase 2A (same prompt, same fallback rule).` with a version that (a) notes the fan_out summary is already at `summary_file`, and (b) for the non-fan_out branch, writes the Explore agent's output to `mktemp -t dw-impl-summary-XXXX.md` (never inside a repo tree) recorded as `summary_file`, so `summary_file` always holds an absolute path before the planner dispatch.

- [ ] **C3 — Phase 2B risk-planner dispatch:** replace
  `> Codebase summary: [paste the Phase 1.7 multi-source summary if fan_out, else the Explore agent's output]`
  with `> Codebase summary: read it from the file at [the \`summary_file\` absolute path]`.

- [ ] **C4 — Phase 2B re-classification fallback:** in the sentence `using the codebase context already captured above — the Phase 1.7 **multi-source codebase summary** when \`fan_out = true\`, otherwise the Explore summary — and do not re-run exploration.` add `(the \`summary_file\` path)` after "captured above". (Light polish; keeps the reference explicit.)

- [ ] **C5 — Phase 2B approval:** replace the line `- **Approve** → proceed to Phase 3B` with
  `- **Approve** → write the approved plan to a temp file (\`mktemp -t dw-impl-plan-XXXX.md\`, never inside a repo tree) and record its absolute path as \`plan_file\`; proceed to Phase 3B`.

- [ ] **C6 — Phase 3B 4a (before the test-writer dispatch):** insert a capture sentence before the
  `→ Agent (… test-writer …)` line: `First write the current diff to a temp file: \`git add -N . && git diff\` → \`mktemp -t dw-impl-diff-XXXX.patch\` (never inside a repo tree); record its path.`
  Then replace the two fields:
  `> Plan: [paste the risk-planner plan approved in Phase 2B]` → `> Plan: read it from the file at [the \`plan_file\` path]`
  `> Diff: [paste \`git add -N . && git diff\` output so new files are included]` → `> Diff: read it from the file at [the temp diff path just recorded]`

- [ ] **C7 — Phase 3B step 5 (diff capture):** after `it now also includes the test files from step 4a.` append `Write this diff to a temp file (\`mktemp -t dw-impl-diff-XXXX.patch\`, never inside a repo tree) and record its absolute path as \`review_diff_file\`; the code-review dispatch receives this path.` (The existing `Also capture \`git diff --stat\` for the summary.` stays — it is small, kept inline.)

- [ ] **C8 — Phase 3B step 6 code-review dispatch:** replace
  `> Plan: [paste the risk-planner plan approved in Phase 2B]` → `> Plan: read it from the file at [the \`plan_file\` path]`
  `> Diff: [paste git diff output]` → `> Diff: read it from the file at [the \`review_diff_file\` path from step 5]`

- [ ] **C9 — Phase 3B Review-fixer sub-step:** after the `**Review-fixer sub-step** (for BLOCK and PASS WITH RECOMMENDATIONS):` line, insert `Write the full code-review agent output to a temp file (\`mktemp -t dw-impl-review-XXXX.md\`, never inside a repo tree) and record its path as \`review_file\`, then dispatch:`. Replace `> Review output: [paste the full code-review agent output]` → `> Review output: read it from the file at [the \`review_file\` path]`.

- [ ] **C10 — Phase 2A approval (SIMPLE/MODERATE — sibling):** replace `- **Approve** → proceed to Phase 3A` with `- **Approve** → write the approved plan to a temp file (\`mktemp -t dw-impl-plan-XXXX.md\`, never inside a repo tree) and record its absolute path as \`plan_file\`; proceed to Phase 3A`.

- [ ] **C11 — Phase 3.5 test-writer dispatch (SIMPLE/MODERATE — sibling):** insert the same diff-capture sentence as C6 before the `→ Agent (… test-writer …)` line, then replace
  `> Plan: [paste the approved Phase 2A plan]` → `> Plan: read it from the file at [the \`plan_file\` path recorded at Phase 2A approval]`
  `> Diff: [paste \`git add -N . && git diff\` output so new files are included]` → `> Diff: read it from the file at [the temp diff path just recorded]`

- [ ] **Verify Task 1:** `grep -nE '\[paste .*(summary|plan|diff|code-review|risk-planner)' commands/implement.md` returns nothing for these blobs in the in-scope phases; `grep -c 'dw-impl-' commands/implement.md` ≥ 6. `claude plugin validate` passes.

> **Sibling note (C10/C11):** these fold in the Phase 2A/3.5 SIMPLE/MODERATE test-writer path so it
> matches Phase 3B (avoids the missing-adoption gap). If the user wants strict 2B/3B scope, drop
> C10 + C11 (and only C10's plan_file write) — the rest stands alone.

### Task 2: Canonical agent-body additive notes (4 files)

Append the uniform note to the relevant input field in each agent's `## Inputs`. Read each file's
Inputs section first to place it exactly.

- [ ] `agents/risk-planner.md` — on the **Codebase summary** input bullet.
- [ ] `agents/test-writer.md` — on the **Plan** / **Diff** inputs.
- [ ] `agents/code-review.md` — on the **Plan** / **Diff** inputs.
- [ ] `agents/review-fixer.md` — on the **Review output** input bullet.
- [ ] **Verify:** each file contains the note exactly once; `claude plugin validate` passes.

### Task 3: Port to mgd (verbatim copy)

- [ ] **Pre-check byte-identity** of the 5 files against mgd BEFORE editing anything:
  `for f in commands/implement.md agents/risk-planner.md agents/test-writer.md agents/code-review.md agents/review-fixer.md; do diff <canonical>/$f <mgd>/$f; done` — expect all clean at the pre-change tips (mgd is a verbatim port). If any differs, STOP and surface.
- [ ] Copy the 5 edited files canonical → mgd (`plugins/dev-workflows/…`).
- [ ] **Verify:** post-copy `diff` shows the 5 files byte-identical; `claude plugin validate` (mgd) passes.

### Task 4: Port to Copilot (conversion)

- [ ] Apply the same edits to `dev-workflows/skills/implement/SKILL.md` and
  `dev-workflows/agents/{risk-planner,test-writer,code-review,review-fixer}.md`, honoring the
  Copilot conversions. The `mktemp` mechanism is identical; the added agent notes carry no
  `${CLAUDE_PLUGIN_ROOT}`.
- [ ] **Verify:** `git diff` introduces **0** new `${CLAUDE_PLUGIN_ROOT}` refs in Copilot; the
  Copilot manifest + SKILL.md parse; the same grep proofs as Task 1 hold on the SKILL.md.

### Task 5: Version + CHANGELOG (all 3 editions)

- [ ] Canonical: `.claude-plugin/marketplace.json` + `plugins/dev-workflows/.claude-plugin/plugin.json` 2.39.1 → **2.39.2**.
- [ ] mgd: same two manifests 2.39.1 → **2.39.2**.
- [ ] Copilot: `.github/plugin/marketplace.json` + `dev-workflows/.plugin/plugin.json` 2.9.1 → **2.9.2**.
- [ ] CHANGELOG (all 3), **Changed** entry, `2026-08-02`: "`/implement` now hands its large dispatch
  artifacts (codebase summary, plan, diff, code-review report) to sub-agents as temp-file paths
  instead of pasting them inline — matching the `/document` + `/epics` handoff pattern; keeps the
  orchestrator context lean on long runs. No behavior change." (Copilot phrasing converted.)

### Final: Opus whole-branch review (the gate)

- [ ] `scripts/review-package` the branch diff; dispatch `dev-workflows:code-review` (Opus) on the
  whole branch with the design + this plan as the constraints lens. Fix CONFIRMED findings; adjudicate
  plan-conflicts with the user. Then merge --ff-only + push all 3 per user confirmation.

## Self-Review

- **Spec coverage:** every design edit-map item (1–8) + the four agent notes + parity + version →
  Tasks 1–5. ✔
- **Placeholder scan:** the `dw-impl-*-XXXX` / `[the … path]` are the house `mktemp` template +
  path-handle substitutions, not gaps. ✔
- **Consistency:** `summary_file` / `plan_file` / `review_diff_file` / `review_file` handles are
  named once and referenced consistently; C6/C11 share the diff-capture idiom; C5/C10 share the
  plan-write idiom. ✔
- **Behavior-preserving check:** no gate/branch/model-routing line is altered — confirmed by
  diffing only the four field lines + capture/write additions. ✔

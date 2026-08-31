# Specs-Native Pipeline — Increment D: delete `$VAULT_PATH`

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `$VAULT_PATH` from the plugin entirely, so that `$SPECS_PATH` is the only tree it reads or writes, and finish the residual vendor-vocabulary sweep §8.3 records.

**Architecture:** The vault survives in five places: four emitter fallback ladders that already prefer `$SPECS_PATH`, `/idea`'s keyless write path, `/epics`'s draft directory (already removed in C), vault prior-art discovery, and `/document`'s gaps draft. Four of those are a tier deletion. One — prior art — is a genuine capability loss, taken deliberately and recorded as such.

**Tech Stack:** Markdown only. No test framework. Failing grep assertion → edit → assertion passes → three repository gates.

**Spec:** `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` D15, §8, §8.1, §8.2, §8.3, and §11's increment D.

**Predecessors:** A (3.5.0), B (3.6.0), C (3.7.0), the code-handoff fix (3.8.0), and the review round — all merged.

## The one thing D removes that is not a redundancy

**Vault prior art is a real capability and it goes.** `vault-prior-art-finder` searched `Projects/Products/**` for prior initiatives and fed `/idea` and `/create-prd` a bounded digest — genuinely useful and *not* tracker-redundant. It goes because it is vault-dependent and there is no vault after this.

It was already advisory, already optional, and already a silent skip when absent, so **nothing gates on it and no run breaks.** That is what makes the deletion safe, not what makes it free. Recorded in the spec as a loss taken deliberately (§8.2), and it must be recorded in the changelog the same way — a capability that disappears without a line in the changelog is one a user discovers by missing it.

**Prior art over `specifications/**` is a plausible future replacement and is out of scope here** (spec §8.2, §10). Do not build half of it.

## Global Constraints

- **Every constraint from A, B and C still binds.**
- **`$VAULT_PATH` must be gone from the *plugin*, not from the world.** A user's vault still exists; the plugin simply stops reading it. Nothing in this increment deletes a user file.
- **A tier deletion is not a behaviour change for the tier that survives.** The emitters already prefer `$SPECS_PATH`; removing the vault tier must leave a specs-resolved run byte-identical.
- **Branch first**, `iv-gu/specs-native-increment-d`.

## Repository Gates — run after every task

```bash
cd /workspace/ihudak-claude-plugins
./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && python3 scripts/validate-catalog.py
```

**Check 5 and check 9 both move here.** Check 5 gates the environment-variable inventory in both directions; check 9 gates its count. Deleting a variable read across 35 files touches both, and `docs/reference/environment.md` must lose the `$VAULT_PATH` entry in the same commit that stops reading it. Check 3 moves too: two references and one agent leave.

## Assertion discipline

Carried from A, B and C — run every assertion before the edit and require it to fail; read which lines flipped; never `sed`-patch a shell string containing backticks or build a search string from context output where newlines became spaces; always run from the repository root; when an assertion fails on correct content, fix the assertion; **and read every changed line after a multi-file substitution**, because three of B's defects were grammatical wreckage no gate can see.

---

### Task D1: The four emitter ladders lose their vault tier

**Files:** `references/followup-emission.md`, `references/feedback-emission.md`, `references/cost-emission.md`, `references/session-hygiene.md`, and `docs/reference/{follow-ups,session-cost,session-feedback,resume-and-checkpoints}.md`.

**Interfaces:**
- Produces: four emitters that resolve `$SPECS_PATH` or report, with no vault tier between.

- [ ] **Step 1: Write the failing assertion** — no `VAULT_PATH` in any of the four references; each still names `$SPECS_PATH` as its primary; the report-only fallback survives.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: `followup-emission.md` is the real work.** Three of the four lose one branch of a ladder. This one loses its **primary** tier and everything shaped by it: the Obsidian-Tasks line format with Fibonacci effort checkboxes and date symbols, `#tags` reused from `.obsidian/copilot/tag-index.md`, `P<NNNN> <slug>.md` project files, the `Tasks.md` fallback, `Journal.md` for verbose notes, and the browse-URL discovered by grepping existing vault tasks.

**What survives is the out-of-scope finding**, which is not a chore: `/implement` naming work it deliberately did not do, `/ready` naming a coverage gap. Those outlive the session and land in `follow-ups.md` in the resolved folder — a plain markdown checklist. This is the existing tier 2 promoted to the only tier; tiers 1, 3 and 4, the availability preflight, the interactive escape and the notice ladder go with the vault.

**The three round-trip chores that used to dominate this emitter no longer exist** — paste the PRD into a tracker, paste the release note, re-import the increment. Say so, so a reader does not go looking for what happened to them.

- [ ] **Step 4: The other three** lose one branch each. Verify by reading that a `$SPECS_PATH`-resolved run is unchanged.

- [ ] **Step 5: Documentation** — the four `docs/reference/` pages.

- [ ] **Step 6: Assertion green, gates green, commit**

---

### Task D2: Vault prior art is deleted

**Files:** delete `agents/vault-prior-art-finder.md` and `references/vault-prior-art.md`; modify `commands/idea.md`, `commands/create-prd.md`, `docs/reference/{agents,references}.md` (entries **and** counts), the two command pages, `CLAUDE.md`.

- [ ] **Step 1: Write the failing assertion** — both files absent; no citation outside CHANGELOG; the agent count matches `ls agents/*.md | wc -l`; the reference count matches.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: Delete both, and remove the dispatch from both commands.** `resolve-prior-art` and `dispatch-prior-art-finder` go with them, as do `--no-prior-art` and the `prior_art: ON|OFF` reporting line.

**`/idea`'s `area_proposal` came from the prior-art digest.** Increment B already removed the write-path derivation that consumed it; confirm nothing else reads it before deleting, and say so in the commit if something does.

- [ ] **Step 4: Record the loss where a user will meet it** — the changelog, not only the spec. It is the one deletion in this whole design that removes a capability rather than a redundancy.

- [ ] **Step 5: Documentation and `CLAUDE.md`** — including the agent and reference-file counts, and the workflow-map lines.

- [ ] **Step 6: Assertion green, gates green, commit**

---

### Task D3: `$VAULT_PATH` leaves the remaining commands and the hook

**Files:** `commands/idea.md` (the keyless write path), `commands/document.md` (the gaps draft), `commands/epics.md`, `agents/idea-reader.md` (`vault_path` input), `hooks/preload-context.sh`, `references/docs-grounding.md`, and every remaining reader.

- [ ] **Step 1: Write the failing assertion** — `grep -rl VAULT_PATH` over `commands/ agents/ references/ hooks/ docs/` returns nothing; `docs/reference/environment.md` documents no such variable; the environment-variable count matches the tree.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: `/idea`'s write path.** Increment B gave `/idea` its key up front (D7), so the keyless vault write is already dead code in every path except the argument that names one. Remove the remaining resolution and its prompts.

- [ ] **Step 4: `/document`'s gaps draft** — `<KEY>-implementation-gaps.md` moves to `implementation-gaps.md` in the resolved PRD folder. Increment A's §4.3 table already names it there; this is where the command catches up.

- [ ] **Step 5: `idea-reader`'s `vault_path` input** and the wikilink resolution it rooted. A source is a path; wikilinks inside a source file are followed one level where they resolve relative to that file's own directory.

- [ ] **Step 6: The hook.** `preload-context.sh` prints `VAULT_PATH` and describes vault-based specs in a comment. Both go. **The hook must still exit 0** — it never blocks Claude.

- [ ] **Step 7: `docs/reference/environment.md`** loses the entry and its count sentence changes. This is what check 5 and check 9 gate.

- [ ] **Step 8: Assertion green, gates green, commit**

---

### Task D4: The residual vendor vocabulary, and the description

**Files:** `references/prose-formatting.md`, `references/docs-profile.md` or `references/docs-profiles/*`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.

- [ ] **Step 1: Write the failing assertion** — no `gen3` example token; the description mentions no retired concept; its length is under 900.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: `docs-profile`'s `gen3` example.** Detection is generic; only the example is vendor-shaped. Replace the example, not the detection.

- [ ] **Step 4: `prose-formatting.md`'s rationale** was already rewritten in increment B. Verify rather than assume, and say which in the commit.

- [ ] **Step 5: Rewrite the plugin description.** It sits at **883 of a 900-character warning threshold** and describes a pipeline that no longer exists.

**Rewrite it; never append.** `CLAUDE.md`'s standing rule records that this blurb reached 2788 characters by appending one sentence per release and had to be hand-trimmed three times in a sibling edition before a check existed. This increment frees words — the round-trip, the flag, the vault — so the rewrite should come out *shorter*, and a rewrite that grows it has misunderstood the instruction.

**Both copies must match**, `plugin.json` and the `marketplace.json` entry; `validate-catalog.py` fails the build above 1024 and warns above 900, and it rejects the whole catalog rather than one plugin.

- [ ] **Step 6: Assertion green, gates green, commit**

---

### Task D5: Final residue audit and the whole-design review

- [ ] **Step 1: Re-run all seventeen prior assertion suites plus D's four.**

- [ ] **Step 2: The four mechanical sweeps.**

- [ ] **Step 3: The residue audit** — *what did this increment make false?*

| Phrase | Why it may now be false |
|---|---|
| `VAULT_PATH`, `vault`, `Obsidian` | no vault is read |
| `prior art`, `prior-art`, `known_ref` | the finder is gone |
| `Tasks.md`, `Journal.md`, `tag-index` | the task machinery is gone |
| `jira-drafts`, `Projects/` | nothing writes there |
| `gen3` | example vocabulary |
| "twenty-three commands", counts generally | re-derive, never decrement |

**A user's vault is not deleted and no page should imply it was.** The plugin stops reading it; that is the whole change.

- [ ] **Step 4: Re-derive every count.** Agents, references, environment variables and the cost-emitting set all move.

- [ ] **Step 5: Read every changed command end to end.**

- [ ] **Step 6: Fix every defect found.**

- [ ] **Step 7: Version bump, changelog, gates, PR.** **Minor, not major** — `$VAULT_PATH` was already optional in every command that read it, so a user who never set it sees no change, and one who did loses prior art and a task format rather than a working pipeline. Say that in the changelog rather than leaving a user to infer it.

- [ ] **Step 8: The whole-design review.** With D merged, dispatch an **Opus 5 subagent** to review every change across all four increments and the two fix rounds, against the spec, looking across increment boundaries — where the per-increment reviews could not see. Fix every finding, then re-run the reviewer. **At most three re-review rounds**; anything still standing after the third is reported to the operator by name rather than absorbed.

---

## Self-Review

**Spec coverage:**

| Spec §11 increment D clause | Task |
|---|---|
| "Vault → follow-up tasks only (D15)" | **superseded** — review pass 1 changed D15 to *deleted*; D1 and D3 |
| "Delete `vault-prior-art-finder` and `vault-prior-art.md`" | D2 |
| "Sweep every residual vault reference" | D3, D5 |
| "the `dependencies.md` row" | **done in increment B** — verify, do not redo |
| "the residual vendor vocabulary in §8" | D4 |
| "Rewrite the plugin description" | D4 |
| §11 "Verification" + "Review protocol" | D5 |

**One clause is already done and one is superseded**, which is why this plan checks rather than repeats them: `dependencies.md`'s importer row went with the round-trip in B, and D15 changed meaning in the spec's first review pass.

**Placeholder scan:** none.

**What D deliberately does not do:** build prior-art discovery over `specifications/**` (spec §8.2, §10 — a separate design), or touch the 40 oversized `choices:` arrays (plugin-wide, predates this work).

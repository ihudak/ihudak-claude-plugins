# Specs-Native Pipeline — Increment B: cut the tracker

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every read of a tracker from the plugin. `jira-reader` and `jira-input-resolution.md` are deleted, every command resolves one address against the specs tree, the paste-and-re-import round-trip is dropped, and the tracker-shaped vocabulary (`issue_type`, the two-key grammar, `--from-brd`) is retired.

**Architecture:** `jira-input-resolution.md` is a shared front-end returning `mode: jira-driven | direct`; six commands call it. It is replaced by three lines in each command's own Phase 0 — parse one address, `resolve-address` it, branch on the kind — which is what increment A shipped the resolver for. `jira-reader`'s three outputs are re-sourced: the document body from the folder's own `prd.md`, the linked-item hierarchy from the Epic folders in the tree, capability themes from the PRD text. Its fourth output, PR URLs, has **no replacement until increment C**, and that gap is stated rather than papered over.

**Tech Stack:** Markdown only. No test framework. The test cycle is a **failing grep assertion**, then the edit, then the same assertion passing, then the three repository gates.

**Spec:** `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` §§5.4, 6, 7.4, 8, and §11's increment B.

**Predecessor:** increment A (PR #32, v3.5.0, merged). B depends on `resolve-address` existing.

## The B→C window, stated up front

**After B and before C, diff grounding is unavailable.** `jira-reader` returned PR URLs harvested from the export; `implementation.md` replaces them and is increment C's. Between the two, `/document` and `/release-notes` have no diff source.

This is acceptable and is **not** a reason to merge B into C, for one checked reason: diff grounding is **already optional in both consumers** — `/release-notes` calls it "opt-in and advisory here: a repo the user skips degrades the grounding, never the run", and `/document`'s `diff-summarizer` dispatch is conditional on PR URLs being present. B therefore reduces an optional input to absent, which both commands already handle.

**What B must do about it is say so.** Each consumer states, at the point it would have dispatched `diff-summarizer`, that no diff source exists yet and what that costs. A command that silently produces an ungrounded draft is the failure; one that names the degradation is the same command it was when a user declined the grounding.

## Global Constraints

- **Every constraint from increment A still binds** — key grammar `^[A-Z][A-Z0-9_]*(-\d+)+$`, `<KIND>-<KEY>-<slug>/` directories, a three-level resolution bound, additive legacy fallback, `git -C "$SPECS_PATH"`, bracketed `[PREFIX#N]` IDs, no marketplace or container repo named under `docs/`.
- **`$VAULT_PATH` is NOT deleted in B.** It is increment D. B removes the *tracker* reads; the vault survives as a location a few things still write to, and D empties it. A B that also deleted `$VAULT_PATH` would be untestable against its own gates.
- **`--from-prd` survives.** Only `--from-brd` retires (D18) — the two are not symmetric: `--from-prd` names a *different* PRD to seed from, which no folder can decide on the operator's behalf.
- **A stop message may quote a key shape.** That is the operator's instruction for what to type, not a validator restatement — the distinction increment A's A6 established after a blunt check nearly degraded nine error messages.
- **Branch first.** Every task commits to `iv-gu/specs-native-increment-b`, never to `main`.

## Repository Gates — run after every task

```bash
cd /workspace/ihudak-claude-plugins
./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && python3 scripts/validate-catalog.py
```

**Check 3 (inventory, both directions) is the one that will fire most in B**: deleting an agent or a reference without deleting its `docs/reference/` entry turns the build red, and so does the reverse. Check 9's agent and reference-file counts move when `jira-reader` and `jira-input-resolution.md` go — those prose sentences change in the same commit as the deletion.

## Assertion discipline — carried from increment A

Increment A's assertion suites misreported six times; the tree was right every time. Four rules, each earned:

1. **Run every assertion before the edit and require it to fail.** An assertion that already passes is either testing nothing or testing the wrong thing — find out which before editing.
2. **Read which lines flipped**, never the exit code alone. Two of A's failures were vacuous passes that an exit code hid.
3. **Never `sed`-patch a shell string containing backticks** — a backtick inside a double-quoted `eval` becomes a command substitution and the grep runs with an empty pattern. Rewrite the file.
4. **Always run from the repository root.** The Bash tool's working directory persists between calls; a stale `cd` turns path-based assertions into vacuous passes.

And one rule about the tree: **when an assertion fails on content that is correct, fix the assertion.** Twice in A that call prevented a real regression.

---

### Task B1: One address, no shared front-end

**Files:**
- Delete: `plugins/dev-workflows/references/jira-input-resolution.md`
- Modify: `commands/epics.md`, `commands/ready.md`, `commands/design.md`, `commands/release-notes.md`, `commands/implement.md`, `commands/document.md` — each Phase 0
- Modify: `commands/specify.md`, `commands/create-ard.md` — their `jira-input-resolution.md` citations
- Modify: `references/addressing.md` §7 (its third shared authority disappears), `references/followup-emission.md`, `references/vault-prior-art.md`, `agents/idea-reader.md`
- Modify: `docs/reference/references.md` (delete the entry), and each affected command page
- Modify: `CLAUDE.md` — the reference inventory and the `jira-input-resolution.md` claims

**Interfaces:**
- Consumes: `resolve-address` (increment A).
- Produces — the Phase 0 shape every later task assumes, replacing `mode: jira-driven | direct`:

```
1. Parse the single positional address (a <KEY>, or an @<path>).
2. resolve-address it. Branch on status: found → proceed; absent → the command's
   own missing-folder behaviour; ambiguous → stop naming every match; invalid → the
   command's own malformed-key stop.
3. Where the command supports more than one level, branch on the resolved kind.
```

- Produces — the **keyed / direct** distinction that replaces `jira-driven / direct`: a run is *keyed* when a positional address is present and *direct* when it is not. `/document` and `/implement` keep both modes; `/epics`, `/ready`, `/design` and `/release-notes` require an address and stop without one, exactly as they stopped on `mode: direct`.

- [ ] **Step 1: Branch, and write the failing assertion**

```bash
cd /workspace/ihudak-claude-plugins
git switch -c iv-gu/specs-native-increment-b   # already created if resuming
```

`scratchpad/assert-b1.sh`:

```bash
#!/usr/bin/env bash
set -u
P=plugins/dev-workflows
fail=0
a() { if eval "$2" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s\n' "$1"; fail=1; fi; }
a "jira-input-resolution.md deleted" "[ ! -f $P/references/jira-input-resolution.md ]"
a "no citation survives"             "! grep -rln --exclude=CHANGELOG.md jira-input-resolution $P"
a "no mode: jira-driven"             "! grep -rln --exclude=CHANGELOG.md 'jira-driven' $P"
for c in epics ready design release-notes implement document; do
  a "$c resolves an address"         "grep -q resolve-address $P/commands/$c.md"
done
a "references.md entry gone"         "! grep -q 'jira-input-resolution' $P/docs/reference/references.md"
exit $fail
```

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: Rewrite the six Phase 0 blocks**

Each currently executes the front-end and branches on `mode`. Replace with the three-step shape above. The four address-required commands keep their stop, re-worded: it fires on a **missing address**, not on `mode: direct`, and its stop code keeps its name so nothing downstream that quotes it breaks.

**`/document` and `/implement` keep two modes and must not lose the second.** Their direct mode is a real feature (document these files; implement this described change), not an artefact of the front-end. What changes is only how the keyed branch is entered.

- [ ] **Step 4: Re-point the four non-command citers**

`references/addressing.md` §7 lists `jira-input-resolution.md` as one of three shared authorities that adopt the fallback. Deleting it makes the count **two**, and §7's "twelve files, eleven commands" paragraph is arithmetic that must be re-derived rather than decremented — the paragraph itself says neither number follows from the other. `followup-emission.md` cites it for a fallback prompt's shape; `vault-prior-art.md` and `agents/idea-reader.md` cite `resolve-export-for-key`, which dies with the file.

**`resolve-export-for-key` has one non-Jira caller — `/idea`.** It typed a source from an export's `issue_type`. That whole source type goes in B4; here, only stop citing the deleted file.

- [ ] **Step 5: `CLAUDE.md`** — the reference inventory sentence, and every claim about `jira-input-resolution.md`'s Fallbacks A–E and two-key grammar.

- [ ] **Step 6: Documentation** — delete the `references.md` entry; update each command page and its mermaid where Phase 0 appears.

- [ ] **Step 7: Assertion green, gates green, commit**

---

### Task B2: Delete `jira-reader` and re-source what it supplied

**Files:**
- Delete: `agents/jira-reader.md`, `references/handoff/jira-reader.md`
- Modify: the commands that dispatched it — `document.md` (17 citations), `specify.md` (15), `epics.md` (15), `create-ard.md` (11), `implement.md` (10), `ready.md` (9), `release-notes.md` (7), `create-prd.md` (5)
- Modify: `agents/epic-reviewer.md` (5), `agents/release-notes-writer.md` (4), `agents/diff-summarizer.md` (3), `references/handoff/diff-summarizer.md` (3), `references/model-routing/classification.md` (5), `references/prd-format.md`, `references/phase-handoff.md`
- Modify: `docs/reference/agents.md` (the entry **and** the agent count), affected command pages
- Modify: `CLAUDE.md` — the agent inventory, the workflow map, the invariants naming `jira-reader`

**Interfaces:**
- Consumes: B1's Phase 0 shape.
- Produces — the four re-sourcings, which every later task and increment C assume:

| `jira-reader` supplied | Now comes from |
|---|---|
| the document body | the resolved folder's own `prd.md` |
| the linked-item hierarchy | the `EPIC-` folders under the PRD folder — a directory listing |
| capability themes | the PRD text, read directly |
| **PR URLs** | **nothing until increment C's `implementation.md`** |

- [ ] **Step 1: Write the failing assertion** (`scratchpad/assert-b2.sh`) — `jira-reader.md` and `references/handoff/jira-reader.md` absent; no citation outside CHANGELOG; `docs/reference/agents.md` carries no `jira-reader` entry; the agent-count sentence matches `ls agents/*.md | wc -l`.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: Re-source the body, the hierarchy and the themes**, per the table. Each dispatching command replaces its `jira-reader` dispatch with a direct read of the resolved folder. **Read each command's dispatch before rewriting it** — they pass different `depth:` values (`full`, `prd-plus-epics`) and consume different parts of the handoff, so there is no single substitution.

- [ ] **Step 4: State the PR-URL gap where it bites**

In `/document` and `/release-notes`, at the point that dispatched `diff-summarizer`: no diff source exists until `implementation.md` (increment C). Say what it costs — prose is grounded in the PRD and the specs, not in the shipped diff — and keep `diff-summarizer` itself, which increment C re-points at `implementation.md`. **Do not delete `diff-summarizer`**: it is a working agent losing an input, not a dead one.

- [ ] **Step 5: `references/model-routing/classification.md`** — §8's fan-out pattern names `jira-reader` in the `jira-reader → parallel code-scanner → Opus synthesis` chain. Re-derive the pattern against what the fan-out now dispatches; do not simply strike the name, because the chain's shape is what the section teaches.

- [ ] **Step 6: Documentation and `CLAUDE.md`** — including check 9's agent count and the workflow-map lines naming `jira-reader`.

- [ ] **Step 7: Assertion green, gates green, commit**

---

### Task B3: Drop the round-trip

**Files:** `commands/create-prd.md`, `commands/update-prd.md`, `references/prd-source-resolution.md`, `references/dependencies.md` (the `jira-workitem-import` row), the matching docs pages, `CLAUDE.md`.

**Interfaces:**
- Consumes: B2's re-sourcing.
- Produces: `resolve-existing-prd <KEY>` reduced to *resolve the folder, read its `prd.md`* — its output shape unchanged for both callers.

- [ ] **Step 1: Write the failing assertion** — `prd-source-resolution.md` names no `jira-products`, no importer URL, no staleness check; `create-prd.md` and `update-prd.md` describe no paste step.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: Rewrite `prd-source-resolution.md`.** Steps 3, 4 and 5 (import-first, the not-imported stop with its two branches, the 3-day staleness check) all go. What survives is step 1's validation, step 2's folder resolution reduced to reading `prd.md`, and step 6's secondary grounding. **The file's whole premise inverts** — its title and opening paragraph say the authoritative PRD text lives in Jira; it now lives in `$SPECS_PATH`. Rewrite the premise, do not patch around it; a file arguing for a policy it no longer implements is worse than a deleted one. Consider whether it still earns its own file at that size, and say which way you decided in the commit.

- [ ] **Step 4: `/create-prd`'s Jira round-trip phase** — the paste, the minted key, the re-import — is deleted, along with every next-step offer that withholds a command until both halves are done. Those offers become unconditional, because the thing they waited for no longer exists.

- [ ] **Step 5: `dependencies.md`** — the `jira-workitem-import` row goes. That table's whole *Related external tooling* section may be left empty; delete the section rather than leaving a header over nothing.

- [ ] **Step 6: Documentation and `CLAUDE.md`**, including the reference count if `prd-source-resolution.md` is deleted rather than rewritten.

- [ ] **Step 7: Assertion green, gates green, commit**

---

### Task B4: Retire the tracker vocabulary

**Files:** the 12 `issue_type` files, the 26 `--from-brd` files, `CLAUDE.md`'s two-keys rule, and the docs pages for each.

**Interfaces:**
- Produces: `kind:` as the only document-type discriminator (D12); one key grammar (§5.1); `--from-brd` inferred from the resolved folder (D18).

- [ ] **Step 1: Write the failing assertion** — no `issue_type` outside CHANGELOG; no `ValueIncrement`; no `--from-brd` flag parsed by any command; `CLAUDE.md` carries no two-grammar rule.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: `issue_type` → `kind:` (D12).** Increment A added `kind:` alongside `issue_type` deliberately; this is where the old field goes. **Every check that read `issue_type: ValueIncrement` to identify a PRD now reads the filename** — which is what A's keyless-filename change bought — **plus `kind: prd` where a check needs to survive a legacy tree.** Do not remove both discriminators from the same check.

- [ ] **Step 4: `--from-brd` → inferred (D18).** The BRD route is detected from `brd-link.md` in the resolved folder, and the run **prints which mode it entered** before doing anything. Three commands parse the flag today (`/create-prd`, `/create-ard`, `/specify`); all three lose it. `--from-prd` stays.

**The flag's two Phase 0 refusals do not go with it.** `CREATE_PRD_BRD_UNALLOCATED` and `CREATE_PRD_BRD_NOT_ELIGIBLE` are about the ledger, not the flag, and they fire on the inferred route exactly as they fired on the explicit one.

- [ ] **Step 5: The two-grammar rule.** `CLAUDE.md`'s longest rule polices a boundary that no longer exists — no tracker mints a key, so there is no narrower tracker-side grammar to protect. Delete the rule **and** the defect-family paragraph that exists only to explain it. Check every "widening this is a defect" claim: each was true of a tracker-side check, and each is now vacuous.

- [ ] **Step 6: Documentation and `CLAUDE.md`**

- [ ] **Step 7: Assertion green, gates green, commit**

---

### Task B5: The mirror fields, `workitem_key`, and unknown-key preservation

**Files:** `references/prd-format.md`, `references/release-note-types.md`, `commands/release-notes.md`, `commands/create-prd.md`, `commands/update-prd.md`, `references/ard-format.md`, `references/specification-format.md`, docs.

**Interfaces:**
- Produces: `workitem_key` (D11) — documented, preserved, displayed, never written or resolved by; the unknown-key preservation rule (D10); and the three mirror fields sourced by inference plus a grill question.

- [ ] **Step 1: Write the failing assertion** — `prd-format.md` documents `workitem_key` and says the plugin never writes it; `prd-format.md`, `ard-format.md` and `specification-format.md` each state the unknown-key rule; no format file calls `release_versions`/`change_type`/`release_notes_category` importer-supplied.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: The three mirror fields** (spec §7.4). None is retired:
  - `change_type` — inferred; `release-note-types.md` already has the inference half as a fallback, so the import half goes and inference becomes the only path. Confirmed **by shape and destination, never by enum label** — today's rule, unchanged.
  - `release_notes_category` — inferred from the subject area and confirmed in the same grill; rendered as a plain label.
  - `release_versions` — `/release-notes` gains `--version <v>`; absent, the grill asks. Never invented.

**One invariant inverts and must be rewritten, not left standing:** `/release-notes` currently forbids the release version in any title or prose. Increment C moves release notes into one `release-notes.md` where the version becomes the section heading; B is where the *field* stops being imported, so **state the inversion here and land the section heading in C**. Do not write a rule B's own tree contradicts.

- [ ] **Step 4: `workitem_key` (D11)** — reserved, documented, preserved across every frontmatter rewrite, displayed in reports; never minted, never validated, never used to resolve a folder. Name the one thing it *is* used for, so the field does not read as decorative: increment C's commit scan greps for it (spec §7.3.1).

- [ ] **Step 5: Unknown-key preservation (D10)** — stated in `prd-format.md`, `ard-format.md` and `specification-format.md`, and honoured by every command that rewrites frontmatter, `/update-prd` above all.

- [ ] **Step 6: Documentation**

- [ ] **Step 7: Assertion green, gates green, commit**

---

### Task B6: Residue audit and increment review

- [ ] **Step 1: Re-run every B assertion suite and increment A's seven**, from the repository root. A's suites are the regression check: B must not have reintroduced a keyed filename or a local folder-match rule.

- [ ] **Step 2: The four mechanical sweeps** — stop codes named in docs vs defined in commands; agents dispatched vs documented (compare **bare agent names**, not `dev-workflows:` types, and check the under-report direction); documented flags vs parsed flags (filter git flags — `--porcelain`, `--short`, `--stat`, `--ff-only` are noise); produced-artifact tables vs `deliverable_paths`.

- [ ] **Step 3: The residue audit** — *what did this increment make false?* Sweep **by phrase, never by line number**:

| Phrase | Why it may now be false |
|---|---|
| `jira-driven`, `mode: direct` | replaced by keyed / direct |
| `Fallback A`–`Fallback E` | died with the front-end |
| `re-import`, `paste`, `round-trip` | deleted in B3 |
| `jira_key`, `tracker key` | there is one key namespace now |
| `two-segment`, `three-segment` | one grammar |
| `issue_type`, `ValueIncrement` | retired in B4 |
| `--from-brd` | inferred in B4 |
| `jira-products` | nothing reads it |
| `the importer`, `workitem-importer` | no importer exists |
| `PR URL` in `/document`, `/release-notes` | no source until C |

For each hit, rewrite against **what the shipped thing now enforces**, read out of its own phase. A sentence that named an absence as its *reason* for an offer needs a new reason, not a deletion.

- [ ] **Step 4: Re-derive every count** — commands, agents, reference files, hooks, skills, environment variables, cost-emitting commands. Two agents and one or two references leave in B, so several **will** move. Re-derive each with a command; do not decrement by hand.

- [ ] **Step 5: Read every changed command end to end.** Not a diff read. Increment A left three orphaned sentence tails that only a read-through caught — a `resolve-address` call followed by the prose it replaced, contradicting itself mid-sentence. B is larger and edits longer passages.

- [ ] **Step 6: Fix every defect found**, including unrelated ones, in their own PR where that keeps this branch readable. Nothing carried forward.

- [ ] **Step 7: Version bump, changelog, gates, PR.** A minor bump: the round-trip is removed and `--from-brd` retires, but the legacy fallback means an existing specs repo keeps resolving. **Do not touch the plugin description** — 898 of a 900-character threshold, and rewriting it is increment D's.

---

## Self-Review

**Spec coverage — increment B's five clauses, mapped:**

| Spec §11 increment B clause | Task |
|---|---|
| "Delete `jira-reader` and `jira-input-resolution.md`" | B1 (the reference), B2 (the agent) |
| "Rewrite every Phase 0 to resolve one address against the tree" | B1 |
| "Drop the paste/re-import round-trip and `prd-source-resolution.md`'s import-first ladder" | B3 |
| "Retire the mirror fields (§7.4), `issue_type` (D12) and the two-grammar rule (§5.1)" | B4 (`issue_type`, grammar), B5 (mirror fields) |
| "Add `workitem_key` and the unknown-key preservation rule (D10, D11)" | B5 |
| §11 "Verification, every increment" + "Review protocol" | B6 |

**Two things this plan adds that the spec's five clauses do not name**, both forced by the deletions: `--from-brd`'s retirement (D18, decided after the spec's §11 was written) lands in B4 because it is tracker vocabulary; and the PR-URL gap needs an owner, which is B2 step 4.

**Placeholder scan:** no TBD, no "handle edge cases". Every step names the file and what the replacement must say.

**Name consistency:** `resolve-address` and the resolution record's fields match increment A's. The keyed/direct pair is defined once, in B1's Interfaces, and used in B2 and B6.

**What B deliberately does not do:** delete `$VAULT_PATH` (increment D), mint Epic keys or write `epic.md` (C), write `implementation.md` (C), move release notes into the PRD folder (C), delete `vault-prior-art-finder` (D). B leaving these undone is what keeps it revertible.
